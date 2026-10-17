"""Exercise scope, continuation bounds and failures with disposable Git fixtures."""
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import time
import unittest

HOOK = Path(__file__).resolve().parents[1] / 'bin/anti-slop-hook'
INSTALLER = HOOK.with_name('install_anti_slop_hooks.py')
TOTAL = '''def {name}(rows):
    result = {{}}
    for row in rows:
        key = row['group']
        if key not in result:
            result[key] = 0
        result[key] += row['value'] * row['weight']
    return sorted(result.items())
'''


class HookTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name)
        self.root = self.base / 'repo'
        self.root.mkdir()
        self.env = {**os.environ, 'TMPDIR': str(self.base)}
        self.git('init', '-q')
        self.write('VALUE = 1\n')
        self.commit()

    def git(self, *args):
        return subprocess.run(['git', *args], cwd=self.root, check=True,
                              capture_output=True, text=True)

    def write(self, content, name='app.py'):
        (self.root / name).write_text(content)

    def commit(self):
        self.git('add', '.')
        self.git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                 'commit', '-qm', 'fixture')

    def hook(self, event, active=False, client='codex', cwd=None):
        payload = {'hook_event_name': event, 'cwd': str(cwd or self.root),
                   'session_id': 'fixture-session', 'stop_hook_active': active}
        result = subprocess.run([sys.executable, str(HOOK), client], input=json.dumps(payload),
                                capture_output=True, text=True, env=self.env, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, '')
        return json.loads(result.stdout) if result.stdout.strip() else None

    def begin(self, client='codex'):
        self.assertIsNone(self.hook('SessionStart', client=client))
        self.assertIsNone(self.hook('UserPromptSubmit', client=client))

    def test_read_only_turn_does_not_gate_existing_dirty_code(self):
        self.write('import os\nVALUE = 1\n')
        self.begin()
        self.assertIsNone(self.hook('Stop'))

    def test_old_violation_in_edited_file_remains_out_of_scope(self):
        self.write('import os\nVALUE = 1\n')
        self.begin()
        self.write('import os\nVALUE = 2\n')
        self.assertIsNone(self.hook('Stop'))

    def test_new_violation_in_preexisting_dirty_file_is_gated(self):
        self.write('import os\nVALUE = 1\n')
        self.begin()
        self.write('import os\nVALUE = 1\nimport sys\n')
        result = self.hook('Stop')
        self.assertEqual(result['decision'], 'block')
        self.assertIn('app.py:3:', result['reason'])
        self.assertNotIn('app.py:1:', result['reason'])

    def test_rewritten_stub_body_that_leaves_an_argument_unused_is_gated(self):
        self.write('def area(width, height):\n    raise NotImplementedError\n')
        self.commit()
        self.begin()
        self.write('def area(width, height):\n    return width * width\n')
        self.assertIn('app.py:1:17: ARG001', self.hook('Stop')['reason'])

    def test_existing_unused_argument_is_not_gated_by_a_body_edit(self):
        self.write('def area(width, height):\n    return width * 2\n')
        self.commit()
        self.begin()
        self.write('def area(width, height):\n    return width * 3\n')
        self.assertIsNone(self.hook('Stop'))

    def test_new_uncalled_function_is_gated(self):
        self.begin()
        self.write('VALUE = 1\n\n\ndef helper():\n    return 1\n')
        self.assertIn('app.py:4:1: AS100 `helper`', self.hook('Stop')['reason'])

    def test_function_called_only_from_tests_is_gated(self):
        (self.root / 'tests').mkdir()
        self.begin()
        self.write('def helper():\n    return 1\n', 'lib.py')
        self.write('from lib import helper\n\nassert helper() == 1\n', 'tests/test_lib.py')
        self.assertIn('AS100 `helper`', self.hook('Stop')['reason'])

    def test_removing_the_last_caller_gates_the_leftover(self):
        self.write('def old():\n    return 1\n\n\nVALUE = old()\n')
        self.commit()
        self.begin()
        self.write('def old():\n    return 1\n\n\nVALUE = 2\n')
        self.assertIn('AS100 `old`', self.hook('Stop')['reason'])

    def test_function_that_was_already_uncalled_is_not_gated(self):
        self.write('def old():\n    return 1\n\n\nVALUE = 1\n')
        self.commit()
        self.begin()
        self.write('def old():\n    return 1\n\n\nVALUE = 2\n')
        self.assertIsNone(self.hook('Stop'))

    def test_renamed_copy_of_an_existing_function_is_gated(self):
        self.write(TOTAL.format(name='total') + '\n\nVALUE = total([])\n', 'stats.py')
        self.commit()
        self.begin()
        self.write(TOTAL.format(name='summed').replace('result', 'acc') + '\n\nprint(summed([]))\n', 'report.py')
        self.assertIn('report.py:1:1: AS101 `summed` repeats `total` at stats.py:1', self.hook('Stop')['reason'])

    def test_definition_after_main_guard_is_gated(self):
        (self.root / 'tests').mkdir()
        self.begin()
        self.write('import unittest\n\nif __name__ == "__main__":\n    unittest.main()\n\n\n'
                   'class Late(unittest.TestCase):\n    def test_one(self):\n        self.assertTrue(1)\n',
                   'tests/test_late.py')
        self.assertIn('tests/test_late.py:7:1: AS102 `Late`', self.hook('Stop')['reason'])

    def test_new_violation_has_only_one_forced_continuation(self):
        self.begin()
        self.write('import os\nVALUE = 1\n')
        self.assertEqual(self.hook('Stop')['decision'], 'block')
        second = self.hook('Stop', active=True)
        self.assertNotIn('decision', second)
        self.assertIn('unresolved', second['systemMessage'])
        third = self.hook('Stop')
        self.assertNotIn('decision', third)

    def test_corrective_edit_is_verified(self):
        self.begin()
        self.write('import os\nVALUE = 1\n')
        self.assertEqual(self.hook('Stop')['decision'], 'block')
        self.write('VALUE = 2\n')
        self.assertIsNone(self.hook('Stop', active=True))

    def test_generated_prompt_preserves_pending_baseline(self):
        self.begin()
        self.write('import os\nVALUE = 1\n')
        self.assertEqual(self.hook('Stop')['decision'], 'block')
        self.assertIsNone(self.hook('UserPromptSubmit'))
        result = self.hook('Stop', active=True)
        self.assertIn('F401', result['systemMessage'])

    def test_new_user_turn_gets_a_fresh_baseline_and_bound(self):
        self.begin()
        self.write('import os\nVALUE = 1\n')
        self.hook('Stop')
        self.hook('Stop', active=True)
        self.assertIsNone(self.hook('UserPromptSubmit'))
        self.write('import os\nVALUE = 1\nimport sys\n')
        result = self.hook('Stop')
        self.assertEqual(result['decision'], 'block')
        self.assertIn('app.py:3:', result['reason'])
        self.assertNotIn('app.py:1:', result['reason'])

    def test_other_stop_hook_continuation_is_not_blocked_again(self):
        self.begin()
        self.write('import os\nVALUE = 1\n')
        result = self.hook('Stop', active=True)
        self.assertNotIn('decision', result)
        self.assertIn('Verification has not passed', result['systemMessage'])

    def test_staged_and_committed_changes_are_checked(self):
        for committed in [False, True]:
            with self.subTest(committed=committed):
                self.write('VALUE = 1\n')
                self.hook('UserPromptSubmit')
                self.write('import os\nVALUE = 1\n')
                self.git('add', 'app.py')
                if committed:
                    self.commit()
                self.assertEqual(self.hook('Stop')['decision'], 'block')
                self.hook('Stop', active=True)

    def test_new_and_preexisting_untracked_files(self):
        self.write('import os\n', 'old.py')
        self.begin()
        self.assertIsNone(self.hook('Stop'))
        self.write('import sys\n', 'new.py')
        result = self.hook('Stop')
        self.assertEqual(result['decision'], 'block')
        self.assertIn('new.py:', result['reason'])
        self.assertNotIn('old.py:', result['reason'])

    def test_clients_have_separate_baselines(self):
        self.begin('codex')
        self.write('import os\nVALUE = 1\n')
        self.begin('claude')
        self.assertEqual(self.hook('Stop', client='codex')['decision'], 'block')
        self.assertIsNone(self.hook('Stop', client='claude'))

    def test_missing_baseline_is_not_reported_as_success(self):
        result = self.hook('Stop')
        self.assertIn('not performed', result['systemMessage'])
        self.assertNotIn('decision', result)

    def test_non_git_directory_is_quiet(self):
        self.assertIsNone(self.hook('SessionStart', cwd=self.base))
        self.assertIsNone(self.hook('Stop', cwd=self.base))

    def test_broken_linter_does_not_trigger_code_repair(self):
        fake_bin = self.base / 'tools'
        fake_bin.mkdir()
        ruff = fake_bin / 'ruff'
        ruff.write_text('#!/bin/sh\necho broken-ruff >&2\nexit 2\n')
        ruff.chmod(0o700)
        self.env['PATH'] = str(fake_bin) + os.pathsep + os.environ['PATH']
        self.begin()
        self.write('VALUE = 2\n')
        result = self.hook('Stop')
        self.assertNotIn('decision', result)
        self.assertIn('tool_error', result['systemMessage'])
        self.assertIn('broken-ruff', result['systemMessage'])

    def test_manual_head_check_keeps_existing_behavior(self):
        self.write('import os\nVALUE = 1\n')
        result = subprocess.run([sys.executable, str(HOOK.with_name('anti-slop-py'))],
                                cwd=self.root, capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 1)
        self.assertIn('F401', result.stdout)

    def test_initial_repository_without_commits(self):
        fresh = self.base / 'fresh'
        fresh.mkdir()
        subprocess.run(['git', 'init', '-q', str(fresh)], check=True, capture_output=True)
        self.assertIsNone(self.hook('UserPromptSubmit', cwd=fresh))
        (fresh / 'app.py').write_text('import os\n')
        self.assertEqual(self.hook('Stop', cwd=fresh)['decision'], 'block')

    def test_large_baseline_reports_unverified_without_repair_loop(self):
        self.write('#' + 'x' * (2 * 1024 * 1024), 'large.py')
        result = self.hook('UserPromptSubmit')
        self.assertIn('2 MiB', result['systemMessage'])
        self.assertNotIn('decision', result)


class TimeoutTest(unittest.TestCase):
    def test_timeout_terminates_owned_checker_and_child(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            hook = root / 'anti-slop-hook'
            hook.write_bytes(HOOK.read_bytes())
            checker = root / 'anti-slop-py'
            checker.write_text('import subprocess, sys, time\n'
                               'from pathlib import Path\n'
                               'child = subprocess.Popen([sys.executable, "-c", '
                               '"import time; time.sleep(60)"])\n'
                               'Path("child.pid").write_text(str(child.pid))\n'
                               'time.sleep(60)\n')
            run_check = runpy.run_path(str(hook))['run_check']
            started = time.monotonic()
            with self.assertRaises(subprocess.TimeoutExpired):
                run_check(root, root / 'baseline.json', timeout=0.5)
            self.assertLess(time.monotonic() - started, 3)
            child = (root / 'child.pid').read_text()
            state = subprocess.run(['ps', '-p', child, '-o', 'stat='],
                                   capture_output=True, text=True, check=False).stdout.strip()
            self.assertTrue(not state or state.startswith('Z'), state)


class InstallerTest(unittest.TestCase):
    def test_merge_and_repeat_preserve_existing_host_configuration(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            codex = root / 'codex'
            claude = root / 'claude'
            codex.mkdir()
            claude.mkdir()
            original = {'hooks': {'Stop': [{'hooks': [{'type': 'command',
                        'command': 'existing-research-hook', 'timeout': 5}]}]},
                        'permissions': {'defaultMode': 'default'}}
            paths = [codex / 'hooks.json', claude / 'settings.json']
            for path in paths:
                path.write_text(json.dumps(original))
            command = [sys.executable, str(INSTALLER), '--codex-home', str(codex),
                       '--claude-home', str(claude)]
            first = subprocess.run(command, check=True, capture_output=True, text=True)
            self.assertIn('installed', first.stdout)
            contents = [path.read_bytes() for path in paths]
            for path in paths:
                data = json.loads(path.read_text())
                self.assertEqual(data['permissions'], original['permissions'])
                self.assertEqual(data['hooks']['Stop'][0], original['hooks']['Stop'][0])
                self.assertEqual(len(data['hooks']['Stop']), 2)
                self.assertEqual(len(data['hooks']['SessionStart']), 1)
                self.assertEqual(len(data['hooks']['UserPromptSubmit']), 1)
                backups = list(path.parent.glob(path.name + '.anti-slop-backup-*'))
                self.assertEqual(len(backups), 1)
                self.assertEqual(json.loads(backups[0].read_text()), original)
                self.assertEqual(backups[0].stat().st_mode & 0o777, 0o600)
            second = subprocess.run(command, check=True, capture_output=True, text=True)
            self.assertEqual(second.stdout.count('unchanged'), 2)
            self.assertEqual([path.read_bytes() for path in paths], contents)


if __name__ == '__main__':
    unittest.main()
