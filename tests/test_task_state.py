"""Behavior tests for codex-task-state: history archive, size budget, copy detection, completion_criterion."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

BIN = Path(__file__).resolve().parents[1]/'bin'
TOOL = os.environ.get('TASK_STATE', str(BIN/'codex-task-state'))
GUIDANCE = os.environ.get('GUIDANCE_CHECK', str(BIN/'guidance-check'))
PY = sys.executable


def run(*args, stdin=None):
    return subprocess.run([PY, '-I', TOOL, *args], input=stdin, capture_output=True, text=True, cwd='/tmp')


def bare(items):
    return [re.sub(r'^\[k\d+\] ', '', item, count=1) for item in items]


class TaskState(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp(dir=os.path.realpath(tempfile.gettempdir())))
        self.path = self.dir / 'task-state.json'
        self.history = self.dir / 'task-state.history.jsonl'

    def tearDown(self):
        shutil.rmtree(self.dir)

    def write(self, state, sha=None):
        args = ['write', str(self.path)] + (['--expected-sha', sha] if sha else [])
        return run(*args, stdin=json.dumps(state, ensure_ascii=False))

    def read(self, path=None):
        result = run('read', str(path or self.path))
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def history_rows(self):
        return [json.loads(line) for line in self.history.read_text().splitlines()] if self.history.exists() else []

    def test_reversed_decision_moves_to_history_verbatim(self):
        old = '2026-10-27 user: "임계값은 0.7로 고정"'
        first = self.write({'goal': 'g', 'next_action': 'n', 'decisions': [old, 'keep']})
        self.assertEqual(first.returncode, 0, first.stderr)
        second = self.write({'goal': 'g', 'next_action': 'n', 'decisions': ['keep', '2026-10-28 user: "0.8로 변경"']},
                            json.loads(first.stdout)['sha256'])
        self.assertEqual(second.returncode, 0, second.stderr)
        self.assertNotIn(old, self.read()['state']['decisions'])
        rows = self.history_rows()
        self.assertEqual(rows[0]['field'], 'decisions')
        self.assertEqual(rows[0]['removed'], [old])
        self.assertEqual(self.read()['history']['entries'], 1)

    def test_replaced_goal_is_archived_and_status_is_not(self):
        first = self.write({'goal': 'first goal', 'next_action': 'n', 'status': 'a'})
        self.write({'goal': 'second goal', 'next_action': 'n2', 'status': 'b'}, json.loads(first.stdout)['sha256'])
        self.assertEqual([(r['field'], r['replaced']) for r in self.history_rows()], [('goal', 'first goal')])

    def test_over_budget_moves_oldest_checks_first(self):
        checks = [f'check {i:03d} ' + 'x' * 300 for i in range(60)]
        result = self.write({'goal': 'g', 'next_action': 'n', 'completed_checks': checks})
        self.assertEqual(result.returncode, 0, result.stderr)
        kept = self.read()['state']['completed_checks']
        self.assertLessEqual(self.path.stat().st_size, 12000)
        self.assertEqual(bare(kept), checks[-len(kept):])
        self.assertGreaterEqual(len(kept), 10)
        moved = self.history_rows()[0]
        self.assertTrue(moved['reason'].startswith('size budget'))
        self.assertEqual(bare(moved['removed'] + kept), checks)

    def test_checks_get_ids_and_version_1_upgrade_archives_nothing(self):
        self.path.write_text(json.dumps({'version': 1, 'updated_at': 'x', 'goal': 'g', 'next_action': 'n',
                                         'completed_checks': ['a', 'b']}))
        state = self.read()
        self.write(state['state'], state['sha256'])
        state = self.read()
        self.assertEqual(state['state']['completed_checks'], ['[k1] a', '[k2] b'])
        self.write(state['state'], state['sha256'])
        self.assertEqual(self.read()['state']['completed_checks'], ['[k1] a', '[k2] b'])
        self.assertFalse(self.history.exists())

    def test_leading_citation_in_a_new_check_gets_its_own_id(self):
        first = self.write({'goal': 'g', 'next_action': 'n', 'completed_checks': ['a']})
        self.write({'goal': 'g', 'next_action': 'n', 'completed_checks': ['[k1] a', '[k1] reran, still holds']},
                   json.loads(first.stdout)['sha256'])
        state = self.read()['state']
        self.assertEqual(state['completed_checks'], ['[k1] a', '[k2] [k1] reran, still holds'])

    def test_checks_cited_by_other_fields_survive_the_budget(self):
        first = self.write({'goal': 'g', 'next_action': 'n', 'completed_checks': [f'old {i}' for i in range(20)]})
        checks = self.read()['state']['completed_checks']
        # A check cited only by another check (here k5) is not protected; that would freeze rerun chains.
        grown = {'goal': 'g', 'next_action': 'verify [k1] again', 'decisions': ['A per [k2]', 'B per [k3]'],
                 'completed_checks': checks + ['rerun of [k5] still holds']
                 + [f'new {i:02d} ' + 'x' * 300 for i in range(40)]}
        result = self.write(grown, json.loads(first.stdout)['sha256'])
        self.assertEqual(result.returncode, 0, result.stderr)
        kept = self.read()['state']['completed_checks']
        self.assertIn('[k1] old 0', kept)
        self.assertIn('[k2] old 1', kept)
        self.assertIn('[k3] old 2', kept)
        moved = self.history_rows()[-1]
        self.assertEqual(moved['removed'][:17], [f'[k{i}] old {i - 1}' for i in range(4, 21)])
        self.assertLessEqual(self.path.stat().st_size, 12000)

    def test_over_budget_decisions_are_written_with_a_warning(self):
        decisions = [f'decision {i}: ' + '결정' * 200 for i in range(20)]
        result = self.write({'goal': 'g', 'next_action': 'n', 'decisions': decisions})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('over the 12000-byte budget', result.stderr)
        self.assertIn('decisions', json.loads(result.stdout)['over_budget']['largest_fields'])
        self.assertEqual(self.read()['state']['decisions'], decisions)
        self.assertIn('over_budget', self.read())
        self.assertFalse(self.history.exists())

    def test_read_always_reports_the_history(self):
        self.write({'goal': 'g', 'next_action': 'n'})
        history = self.read()['history']
        self.assertEqual(history['entries'], 0)
        self.assertEqual(history['path'], str(self.history))

    def test_copy_is_reported(self):
        self.write({'goal': 'g', 'next_action': 'n'})
        copy_dir = self.dir / 'copied-folder'
        copy_dir.mkdir()
        shutil.copy2(self.path, copy_dir / 'task-state.json')
        self.assertNotIn('copy_of', self.read())
        self.assertIn(str(self.path), self.read(copy_dir / 'task-state.json')['copy_of'])
        hook = subprocess.run([PY, '-I', GUIDANCE], input=json.dumps({'cwd': str(copy_dir)}),
                              capture_output=True, text=True, cwd='/tmp')
        self.assertIn('was copied from', hook.stdout)
        hook = subprocess.run([PY, '-I', GUIDANCE], input=json.dumps({'cwd': str(self.dir)}),
                              capture_output=True, text=True, cwd='/tmp')
        self.assertNotIn('was copied from', hook.stdout)
        self.path.unlink()  # the original is gone: the folder was moved, not copied
        self.assertNotIn('copy_of', self.read(copy_dir / 'task-state.json'))

    def test_version_1_file_round_trips(self):
        self.path.write_text(json.dumps({'version': 1, 'updated_at': 'x', 'goal': 'g', 'next_action': 'n',
                                         'decisions': ['d']}))
        state = self.read()
        result = self.write(state['state'], state['sha256'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.read()['state']['version'], 2)
        self.assertFalse(self.history.exists())

    def test_stale_sha_is_still_refused(self):
        self.write({'goal': 'g', 'next_action': 'n'})
        result = self.write({'goal': 'g2', 'next_action': 'n'}, '0' * 64)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.read()['state']['goal'], 'g')


    def test_completion_criterion_round_trips_and_is_optional(self):
        said = '사용자 기준: "표 3개가 모두 재계산되면 끝"'
        first = self.write({'goal': 'g', 'next_action': 'n', 'completion_criterion': said})
        self.assertEqual(first.returncode, 0, first.stderr)
        state = self.read()
        self.assertEqual(state['state']['completion_criterion'], said)
        again = self.write(state['state'], state['sha256'])
        self.assertEqual(again.returncode, 0, again.stderr)
        self.assertEqual(self.read()['state']['completion_criterion'], said)
        self.assertFalse(self.history.exists())

    def test_handoff_without_criterion_is_unchanged_by_a_rewrite(self):
        first = self.write({'goal': 'g', 'next_action': 'n', 'decisions': ['d']})
        before = self.read()['state']
        self.write({**before, 'status': 's'}, json.loads(first.stdout)['sha256'])
        after = self.read()['state']
        self.assertNotIn('completion_criterion', after)
        self.assertEqual({k: v for k, v in after.items() if k not in ('updated_at', 'status')},
                         {k: v for k, v in before.items() if k != 'updated_at'})
        self.assertFalse(self.history.exists())

    def test_adding_a_criterion_to_an_old_handoff_archives_nothing(self):
        self.path.write_text(json.dumps({'version': 1, 'updated_at': 'x', 'goal': 'g', 'next_action': 'n'}))
        state = self.read()
        result = self.write({**state['state'], 'completion_criterion': 'first words'}, state['sha256'])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.history.exists())

    def test_replaced_criterion_is_archived_verbatim(self):
        first = self.write({'goal': 'g', 'next_action': 'n', 'completion_criterion': 'old words'})
        self.write({'goal': 'g', 'next_action': 'n', 'completion_criterion': 'new words'},
                   json.loads(first.stdout)['sha256'])
        self.assertEqual([(r['field'], r['replaced']) for r in self.history_rows()],
                         [('completion_criterion', 'old words')])

    def test_blank_or_non_text_criterion_is_refused(self):
        for bad in ('', '   ', ['a'], 3, None):
            result = self.write({'goal': 'g', 'next_action': 'n', 'completion_criterion': bad})
            self.assertNotEqual(result.returncode, 0, bad)
            self.assertIn('completion_criterion', result.stderr)
        self.assertFalse(self.path.exists())

    def test_help_documents_the_field(self):
        result = run('--help')
        self.assertEqual(result.returncode, 0, result.stderr)
        for part in ('completion_criterion', 'met', 'blocked'):
            self.assertIn(part, result.stdout)

    def test_guidance_check_shows_the_criterion_only_when_set(self):
        self.write({'goal': 'g', 'next_action': 'n', 'completion_criterion': 'stop when X'})
        shown = subprocess.run([PY, '-I', GUIDANCE], input=json.dumps({'cwd': str(self.dir)}),
                               capture_output=True, text=True, cwd='/tmp')
        self.assertIn("completion_criterion='stop when X'", shown.stdout)
        self.path.unlink()
        self.write({'goal': 'g', 'next_action': 'n'})
        plain = subprocess.run([PY, '-I', GUIDANCE], input=json.dumps({'cwd': str(self.dir)}),
                               capture_output=True, text=True, cwd='/tmp')
        self.assertIn("goal='g'", plain.stdout)
        self.assertNotIn('completion_criterion', plain.stdout)


if __name__ == '__main__':
    unittest.main()
