"""read-guard denies raw non-code reads for Claude Fable and Opus 5.5 under registered roots and nothing else."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

HOOK = Path(__file__).resolve().parents[1] / 'bin/read-guard'
ALLOW = ['AGENTS.md', 'task-state.json', '*.py']
FABLE, SONNET = 'claude-fable-5-2', 'claude-sonnet-5-5'


class ReadGuardTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        base = Path(os.path.realpath(tmp.name))
        self.root = base / 'project'
        self.config = base / 'config'
        for name in ('notes.md', 'data.csv', 'src/tool.py', 'AGENTS.md', 'task-state.json', 'docs/My Notes.md', 'docs/plan.txt'):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('neutral fixture text\n')
        self.outside = base / 'elsewhere.md'
        self.outside.write_text('neutral fixture text\n')
        self.config.mkdir()
        self.set_config(roots=[str(self.root)], allow=ALLOW)
        self.base = base

    def set_config(self, roots=None, allow=None):
        for name, rows in (('restricted-roots', roots), ('restricted-read-allow', allow)):
            if rows is not None:
                (self.config / name).write_text('# fixture\n' + '\n'.join(rows) + '\n')

    def run_hook(self, payload, raw=None):
        env = dict(os.environ, READ_GUARD_CONFIG=str(self.config))
        text = raw if raw is not None else json.dumps(payload)
        result = subprocess.run([sys.executable, '-I', str(HOOK)], input=text, capture_output=True, text=True, env=env, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout) if result.stdout.strip() else None

    def bash(self, command, model=FABLE, cwd=None, **extra):
        payload = {'hook_event_name': 'PreToolUse', 'tool_name': 'Bash', 'tool_input': {'command': command},
                   'cwd': str(cwd or self.base), 'model': model, **extra}
        return self.run_hook(payload)

    def assertDenied(self, result):
        self.assertIsNotNone(result)
        decision = result['hookSpecificOutput']
        self.assertEqual(decision['permissionDecision'], 'deny')
        self.assertEqual(decision['hookEventName'], 'PreToolUse')
        self.assertIn('Claude Sonnet 5.5', decision['permissionDecisionReason'])
        self.assertIn('effort high', decision['permissionDecisionReason'])

    def test_claude_code_read_and_grep(self):
        read = lambda name, **kw: self.run_hook({'tool_name': 'Read', 'tool_input': {'file_path': str(name)}, 'model': FABLE, **kw})
        self.assertDenied(read(self.root / 'notes.md'))
        self.assertIsNone(read(self.root / 'src/tool.py'))
        self.assertIsNone(read(self.root / 'AGENTS.md'))
        self.assertIsNone(read(self.outside))
        grep = lambda **kw: self.run_hook({'tool_name': 'Grep', 'tool_input': {'pattern': 'x', 'path': str(self.root), **kw}, 'model': FABLE})
        self.assertDenied(grep(output_mode='content'))
        self.assertIsNone(grep())
        self.assertIsNone(grep(output_mode='files_with_matches'))
        self.assertIsNone(grep(output_mode='content', glob='*.py'))

    def test_model_from_payload_or_transcript(self):
        for name in (SONNET, 'claude-opus-5', 'gpt-5.5-codex', ''):
            self.assertIsNone(self.bash(f'cat {self.root}/notes.md', model=name), name)
        for name in ('claude-opus-5-5', 'claude-opus-5.5', 'Claude-Fable-5-2'):
            self.assertDenied(self.bash(f'cat {self.root}/notes.md', model=name))
        self.assertDenied(self.run_hook({'tool_name': 'Bash', 'tool_input': {'command': f'cat {self.root}/notes.md'},
                                         'model': {'id': FABLE}}))
        self.assertIsNone(self.run_hook({'tool_name': 'Bash', 'tool_input': {'command': f'cat {self.root}/notes.md'}}))
        claude = self.base / 'claude.jsonl'
        claude.write_text('\n'.join(json.dumps(row) for row in (
            {'type': 'assistant', 'message': {'model': SONNET}},
            {'type': 'user', 'message': {'content': 'a "model": "claude-fable-5-2" mention'}},
            {'type': 'assistant', 'message': {'model': FABLE}},
            {'type': 'assistant', 'message': {'model': '<synthetic>'}})) + '\n')
        payload = {'tool_name': 'Bash', 'tool_input': {'command': f'cat {self.root}/notes.md'}, 'transcript_path': str(claude)}
        self.assertDenied(self.run_hook(payload))
        codex = self.base / 'rollout.jsonl'
        codex.write_text('\n'.join(json.dumps(row) for row in (
            {'type': 'turn_context', 'payload': {'model': FABLE}},
            {'type': 'turn_context', 'payload': {'model': 'gpt-5.5-codex', 'model_provider': 'x'}})) + '\n')
        self.assertIsNone(self.run_hook({**payload, 'transcript_path': str(codex)}))
        self.assertIsNone(self.run_hook({**payload, 'transcript_path': str(self.base / 'missing.jsonl')}))

    def test_codex_payload_shape(self):
        payload = {'session_id': 's', 'turn_id': 't', 'transcript_path': None, 'cwd': str(self.root), 'hook_event_name': 'PreToolUse',
                   'model': FABLE, 'permission_mode': 'default', 'tool_name': 'Bash',
                   'tool_input': {'command': 'cat notes.md'}, 'tool_use_id': 'u'}
        self.assertDenied(self.run_hook(payload))
        self.assertDenied(self.run_hook({**payload, 'tool_name': 'exec_command', 'tool_input': {'cmd': 'head -n 3 data.csv'}}))

    def test_shell_readers_denied(self):
        root = self.root
        for command in (f'cat {root}/notes.md', f'head -n 5 {root}/data.csv', f'tail -5 {root}/data.csv', f'less {root}/notes.md',
                        f"sed -n '1,5p' {root}/notes.md", f"sed 's/a/b/' {root}/notes.md", f"awk '{{print $1}}' {root}/data.csv",
                        f'awk -F, -v k=1 "{{print}}" {root}/data.csv', f'grep -n fixture {root}/notes.md', f'grep -e x -h {root}/notes.md',
                        f'rg fixture {root}/notes.md', f'cat < {root}/notes.md', f'cat {root}/notes.md | head -3', f'echo hi; cat {root}/notes.md',
                        f'cat "{root}/docs/My Notes.md"', f'cat {root}/*.csv', f'cat {root}/src/tool.py {root}/notes.md',
                        f'cat {root}/notes.md 2>/dev/null', f'FOO=1 env cat {root}/notes.md', f'(cat {root}/notes.md)',
                        f'echo $(cat {root}/notes.md)', f'grep -rn fixture {root}', f'grep -R fixture {root}/docs', f'rg fixture {root}'):
            with self.subTest(command=command):
                self.assertDenied(self.bash(command))

    def test_shell_after_cd(self):
        root = self.root
        for command in (f'cd {root} && cat notes.md', f'cd {root} && head -n 5 data.csv', f'cd {root}; sed -n 1p docs/plan.txt',
                        f'cd {root}/docs && grep -n x plan.txt', f'cd "{root}" && cat docs/"My Notes.md"', f'cd {root} && rg fixture',
                        f'cd {root} && grep -rn fixture .'):
            with self.subTest(command=command):
                self.assertDenied(self.bash(command))
        self.assertIsNone(self.bash(f'cd {root} && cat src/tool.py'))
        self.assertIsNone(self.bash(f'cd {self.base} && cat elsewhere.md'))
        self.assertDenied(self.bash('cat notes.md', cwd=self.root))
        self.assertIsNone(self.bash('cat src/tool.py', cwd=self.root))

    def test_named_cases(self):
        """Command shapes of stage2-03-C1, 04-C16 and 17-C21 rebuilt from the item text with placeholder paths."""
        root = self.root
        shapes = {'stage2-03-C1': f'cat {root}/notes.md',
                  'stage2-04-C16': f'head -n 40 {root}/data.csv',
                  'stage2-17-C21': f"cd {root} && sed -n '1,80p' docs/plan.txt && grep -n term docs/plan.txt"}
        for case, command in shapes.items():
            with self.subTest(case=case):
                self.assertDenied(self.bash(command))
                self.assertIsNone(self.bash(command, model=SONNET))

    def test_shell_allowed(self):
        root = self.root
        for command in (f'cat {root}/src/tool.py', f'cat {root}/AGENTS.md {root}/task-state.json', f'cat {self.outside}',
                        f'grep -c fixture {root}/notes.md', f'grep -l fixture {root}/notes.md', f'grep -rl fixture {root}',
                        f'grep -rc fixture {root}', f'grep -q fixture {root}/notes.md', f'rg -l fixture {root}', f'rg --count fixture {root}',
                        f'grep -rn fixture {root} --include=*.py', f'rg fixture {root} -g "*.py"', f'ls {root}', f'cat {root}/missing.md',
                        f'cat {root}/docs', f"sed -i '' 's/a/b/' {root}/notes.md", f'echo fixture | grep fixture', f'cat | head -2',
                        f'cat $UNSET_VARIABLE/notes.md', f"head -n 5 {root}/src/tool.py", f'cat {root}/notes.md.missing',
                        f'python3 {root}/src/tool.py', f'wc -l {root}/notes.md', 'echo "unbalanced'):
            with self.subTest(command=command):
                self.assertIsNone(self.bash(command))

    def test_disabled_without_roots_and_bad_input(self):
        command = f'cat {self.root}/notes.md'
        (self.config / 'restricted-roots').write_text('# only a comment\n\n')
        self.assertIsNone(self.bash(command))
        (self.config / 'restricted-roots').unlink()
        self.assertIsNone(self.bash(command))
        self.set_config(roots=[str(self.root)])
        (self.config / 'restricted-read-allow').unlink()
        self.assertDenied(self.bash(f'cat {self.root}/src/tool.py'))
        self.assertIsNone(self.run_hook(None, raw='not json'))
        self.assertIsNone(self.run_hook(None, raw='[]'))
        self.assertIsNone(self.run_hook({'tool_name': 'WebFetch', 'tool_input': {'url': 'https://example.org'}, 'model': FABLE}))

    def test_symlink_resolution(self):
        link_in = self.root / 'link.md'
        link_in.symlink_to(self.outside)
        self.assertIsNone(self.bash(f'cat {link_in}'))
        link_out = self.base / 'alias.md'
        link_out.symlink_to(self.root / 'notes.md')
        self.assertDenied(self.bash(f'cat {link_out}'))


if __name__ == '__main__':
    unittest.main()
