"""shared-doc-apply plans targeted edits and verifies a fresh export; it reads only and never uploads."""
import json
import re
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1]/'bin/shared-doc-apply'

RESULTS = 'Intro line.\nThe method improves the score from 0.41 to 0.52 on the sample set.\nEnd line.\n'
METHODS = 'Setup text.\nThe sample set has 120 items.\n'
BIB = '@article{key1,\n  title = {Old title},\n}\n'
FILES = {'main.tex': '\\input{sections/results}\n', 'sections/results.tex': RESULTS, 'sections/methods.tex': METHODS,
         'refs.bib': BIB, 'figs/plot.bin': b'\x89PNG\xff\x00'}
CHANGE = {'file': 'sections/results.tex', 'before': 'from 0.41 to 0.52', 'after': 'from 0.41 to 0.55', 'reason': 'updated number'}
GOOD = RESULTS.replace('0.52', '0.55')


def as_bytes(value):
    return value if isinstance(value, bytes) else value.encode()


class SharedDocApplyTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.base = Path(tmp.name).resolve()

    def make_zip(self, name, files, prefix='', stamp=(2026, 1, 1, 0, 0, 0)):
        path = self.base/name
        with zipfile.ZipFile(path, 'w') as archive:
            for member, text in files.items():
                archive.writestr(zipfile.ZipInfo(prefix + member, stamp), as_bytes(text))
        return path

    def make_dir(self, name, files):
        root = self.base/name
        for member, text in files.items():
            (root/member).parent.mkdir(parents=True, exist_ok=True)
            (root/member).write_bytes(as_bytes(text))
        return root

    def changes(self, *items, name='changes.json'):
        path = self.base/name
        path.write_text(json.dumps(list(items)))
        return path

    def run_tool(self, *args):
        return subprocess.run([sys.executable, '-I', str(SCRIPT), *map(str, args)], capture_output=True, text=True, check=False)

    def tree_hash(self, export):
        return re.search(r'tree_sha256=(\w+)', self.run_tool('hash', export).stdout).group(1)

    def test_zip_and_folder_with_same_content_share_the_tree_hash(self):
        archive = self.make_zip('a.zip', FILES)
        again = self.make_zip('b.zip', dict(reversed(FILES.items())), stamp=(2026, 6, 6, 1, 2, 4))
        folder = self.make_dir('tree', FILES)
        out = self.run_tool('hash', archive).stdout
        self.assertIn('archive_sha256=', out)
        self.assertIn('files=5', out)
        self.assertEqual(self.tree_hash(archive), self.tree_hash(again))
        self.assertEqual(self.tree_hash(archive), self.tree_hash(folder))
        self.assertNotIn('archive_sha256', self.run_tool('hash', folder).stdout)

    def test_plan_emits_targeted_replacement_with_line_and_expected_hash(self):
        export = self.make_zip('a.zip', FILES)
        result = self.run_tool('plan', export, self.changes(CHANGE))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for part in ('file: sections/results.tex  line: 2', 'reason: updated number', 'from 0.41 to 0.52', 'from 0.41 to 0.55', 'OK: 1 edit(s)'):
            self.assertIn(part, result.stdout)
        expected = re.search(r'expected_tree_sha256=(\w+)', result.stdout).group(1)
        want = self.make_zip('want.zip', {**FILES, 'sections/results.tex': GOOD})
        self.assertEqual(expected, self.tree_hash(want))

    def test_plan_json_mode(self):
        result = self.run_tool('plan', self.make_zip('a.zip', FILES), self.changes(CHANGE), '--json')
        payload = json.loads(result.stdout[result.stdout.index('{'):])
        self.assertEqual(payload['edits'][0]['line'], 2)
        self.assertEqual(payload['edits'][0]['after'], 'from 0.41 to 0.55')

    def test_change_list_accepts_object_form_and_nested_top_folder(self):
        export = self.make_zip('a.zip', FILES, prefix='project/')
        path = self.base/'obj.json'
        path.write_text(json.dumps({'changes': [CHANGE]}))
        result = self.run_tool('plan', export, path)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('file: project/sections/results.tex', result.stdout)

    def test_plan_rejects_bad_changes_without_emitting_edits(self):
        export = self.make_zip('a.zip', {**FILES, 'sections/dup.tex': 'aaa and the sample set. the sample set.'})
        cases = {
            'absent': {'file': 'refs.bib', 'before': 'No such span', 'after': 'x'},
            'twice': {'file': 'sections/dup.tex', 'before': 'the sample set', 'after': 'x'},
            'overlapping occurrences': {'file': 'sections/dup.tex', 'before': 'aa', 'after': 'b'},
            'missing file': {'file': 'nope.tex', 'before': 'a', 'after': 'b'},
            'noop': {'file': 'refs.bib', 'before': 'Old title', 'after': 'Old title'},
            'overlapping changes': {'file': CHANGE['file'], 'before': 'score from 0.41', 'after': 'x'},
        }
        for label, change in cases.items():
            with self.subTest(label):
                result = self.run_tool('plan', export, self.changes(CHANGE, change))
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn('FAILED', result.stdout)
                self.assertNotIn('SELECT', result.stdout)
        self.assertIn('overlap', result.stdout)

    def test_crlf_export_matches_lf_change_list(self):
        export = self.make_zip('a.zip', {**FILES, 'sections/results.tex': RESULTS.replace('\n', '\r\n')})
        result = self.run_tool('plan', export, self.changes({**CHANGE, 'before': 'sample set.\nEnd', 'after': 'sample set.\nFinal'}))
        self.assertEqual(result.returncode, 0, result.stdout)

    def test_verify_passes_for_exactly_the_approved_changes(self):
        before = self.make_zip('before.zip', FILES)
        fresh = self.make_zip('fresh.zip', {**FILES, 'sections/results.tex': GOOD}, stamp=(2026, 9, 9, 9, 9, 8))
        result = self.run_tool('verify', before, self.changes(CHANGE), fresh)
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('VERIFY OK', result.stdout)

    def test_verify_reports_every_difference_beyond_the_approved_changes(self):
        before = self.make_zip('before.zip', FILES)
        approved = {**FILES, 'sections/results.tex': GOOD}
        scenarios = {
            'APPROVED EDIT NOT PRESENT': (dict(FILES), 'sections/results.tex'),
            'DIFFERS beyond the approved edits': ({**approved, 'sections/results.tex': GOOD.replace('End line.', 'End line!')}, 'End line!'),
            'CHANGED outside the approved files': ({**approved, 'refs.bib': BIB.replace('Old', 'Newer')}, 'Newer'),
            'MISSING in fresh export': ({k: v for k, v in approved.items() if k != 'sections/methods.tex'}, 'sections/methods.tex'),
            'EXTRA in fresh export': ({**approved, 'new.tex': 'added'}, 'new.tex'),
            'binary content differs': ({**approved, 'figs/plot.bin': b'\x89PNG\xff\x01'}, 'figs/plot.bin'),
        }
        for label, (files, mention) in scenarios.items():
            with self.subTest(label):
                result = self.run_tool('verify', before, self.changes(CHANGE), self.make_zip('fresh.zip', files))
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertIn('VERIFY FAILED', result.stdout)
                self.assertIn(label, result.stdout)
                self.assertIn(mention, result.stdout)

    def test_verify_ignore_pattern_and_stale_change_list(self):
        before = self.make_zip('before.zip', FILES)
        fresh = self.make_zip('fresh.zip', {**FILES, 'sections/results.tex': GOOD, 'figs/plot.bin': b'\x89PNG\xff\x01'})
        self.assertEqual(self.run_tool('verify', before, self.changes(CHANGE), fresh).returncode, 1)
        self.assertEqual(self.run_tool('verify', before, self.changes(CHANGE), fresh, '--ignore', 'figs/*').returncode, 0)
        stale = self.run_tool('verify', before, self.changes({**CHANGE, 'before': 'gone'}), fresh)
        self.assertEqual(stale.returncode, 1)
        self.assertIn('FAILED', stale.stdout)

    def test_unreadable_inputs_exit_two(self):
        export = self.make_zip('a.zip', FILES)
        bad = self.base/'bad.zip'
        bad.write_text('not a zip')
        evil = self.make_zip('evil.zip', {'../escape.tex': 'x'})
        broken = self.base/'broken.json'
        broken.write_text('{')
        for args in (('hash', bad), ('hash', self.base/'missing'), ('hash', evil), ('plan', export, broken)):
            with self.subTest(args=args):
                self.assertEqual(self.run_tool(*args).returncode, 2)

    def test_tool_has_no_network_or_upload_code_and_changes_nothing(self):
        source = SCRIPT.read_text()
        for word in ('socket', 'urllib', 'http', 'requests', 'ftplib', 'smtplib', 'subprocess', 'webbrowser', 'write_bytes',
                     'write_text', 'open(', 'shutil', 'extract'):
            self.assertNotIn(word, source, word)
        export = self.make_dir('tree', FILES)
        changes = self.changes(CHANGE)
        snapshot = {str(p): p.read_bytes() for p in self.base.rglob('*') if p.is_file()}
        self.run_tool('plan', export, changes)
        self.run_tool('verify', export, changes, export)
        self.assertEqual(snapshot, {str(p): p.read_bytes() for p in self.base.rglob('*') if p.is_file()})


if __name__ == '__main__':
    unittest.main()
