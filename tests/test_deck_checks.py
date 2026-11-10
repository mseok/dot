"""Checks for the html-research-deck regression runner, banned-copy lint and PDF comparison.

Run: python3 test_deck_checks.py   (HTML_DECK_SKILL overrides the skill folder; default ~/agent-skills/skills/codex/html-research-deck)
Cases that need headless Chrome, pdftoppm or gs are skipped when the tool is missing.
"""
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SKILL = Path(os.environ.get('HTML_DECK_SKILL', Path.home() / 'agent-skills/skills/codex/html-research-deck'))
SCRIPTS = SKILL / 'scripts'
CHROME = os.environ.get('CHROME', '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome')


def run(script, *args):
    return subprocess.run([sys.executable, str(SCRIPTS / script), *args], capture_output=True, text=True, check=False)


def slide(n, **fields):
    base = {'n': n, 'cls': 'slide', 'kicker': '', 'h1': '', 'h2': '', 'lanes': [], 'visible': [], 'closing': '', 'cite': '', 'notes': ''}
    return {**base, **fields}


def lint(*slides, tmp):
    path = Path(tmp) / 'copy.json'
    path.write_text(json.dumps({'slides': list(slides)}, ensure_ascii=False), encoding='utf-8')
    result = run('banned_copy_lint.py', '--copy-json', str(path), '--json', str(Path(tmp) / 'out.json'))
    found = json.loads((Path(tmp) / 'out.json').read_text(encoding='utf-8'))['findings']
    return result.returncode, {(f['rule'], f['severity']) for f in found}


class BannedCopyLintTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp)
        self.cover = slide(1, cls='slide title-slide', h1='발표자: 이름', visible=['저자 소개: 예시'])

    def test_each_rule_fires(self):
        cases = {
            ('author-token', 'error'): slide(2, lanes=['발표자 생각']),
            ('colon-label', 'error'): slide(2, h2='결과 1: 요점'),
            ('locator', 'error'): slide(2, h2='Fig. 3 요점'),
            ('locator', 'warn'): slide(2, visible=['값은 Fig. 10']),
            ('closing-banned', 'error'): slide(2, closing='하나뿐인 경우'),
            ('closing-banned', 'warn'): slide(2, closing='모델 때문에 생긴 차이'),
            ('gloss-paren', 'warn'): slide(2, visible=['세션(게임 한 판)']),
            ('dash-prefix', 'warn'): slide(2, h2='라벨 — 내용'),
        }
        for expected, content in cases.items():
            with self.subTest(expected=expected):
                self.assertIn(expected, lint(self.cover, content, tmp=self.tmp)[1])

    def test_clean_copy_exits_zero_and_warnings_do_not_fail(self):
        clean = slide(2, h2='높은 생존율을 보인 조건', lanes=['열린 질문'], closing='같은 예산에서 14점 높음', cite='저자 2026: 발표자 해석', notes='번역: 예시')
        self.assertEqual(lint(self.cover, clean, tmp=self.tmp), (0, set()))
        self.assertEqual(lint(self.cover, slide(2, visible=['세션(게임 한 판)']), tmp=self.tmp)[0], 0)

    def test_scope_exemptions(self):
        exempt = slide(2, h2='시각 10:30 이후 $a:b$ 비교', cite='[1] 저자 · Fig. 2', notes='발표자 번역')
        self.assertEqual(lint(self.cover, exempt, tmp=self.tmp), (0, set()))

    def test_error_exit_code(self):
        self.assertEqual(lint(self.cover, slide(2, h2='결과 1: 요점'), tmp=self.tmp)[0], 1)


class RegressionRunnerTest(unittest.TestCase):
    def test_manifest_without_rendering_has_no_failure(self):
        result = run('regression_run.py', '--no-render')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn(' 0 FAIL', result.stdout)
        self.assertIn('MANUAL', result.stdout)

    @unittest.skipUnless(os.access(CHROME, os.X_OK), 'headless Chrome not installed')
    def test_every_measured_case_passes_with_rendering(self):
        result = run('regression_run.py')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertNotIn(' 0 PASS', result.stdout)
        self.assertIn(' 0 SKIP', result.stdout)

    def altered(self, **changes):
        tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, tmp)
        doc = json.loads((SKILL / 'regression/manifest.json').read_text(encoding='utf-8'))
        case = next(c for c in doc['cases'] if c['id'] == 'colon-title')
        case.update(changes)
        doc['cases'] = [case]
        (Path(tmp) / 'fixtures').symlink_to(SKILL / 'regression/fixtures')
        (Path(tmp) / 'manifest.json').write_text(json.dumps(doc, ensure_ascii=False), encoding='utf-8')
        return run('regression_run.py', '--manifest', str(Path(tmp) / 'manifest.json'))

    def test_unrecorded_quote_fails(self):
        result = self.altered(quote='a defect nobody recorded')
        self.assertEqual(result.returncode, 1)
        self.assertIn('quote not found', result.stdout)

    def test_missed_defect_fails(self):
        result = self.altered(expect='author-token')
        self.assertEqual(result.returncode, 1)
        self.assertIn('did not report author-token', result.stdout)

    def test_fixed_fixture_that_still_triggers_fails(self):
        result = self.altered(fixed='fixtures/colon-title.bad.html')
        self.assertEqual(result.returncode, 1)
        self.assertIn('still reports colon-label', result.stdout)


def make_pdf(path, content):
    stream = b'<< /Length %d >>\nstream\n' % len(content) + content + b'\nendstream'
    objects = [b'<< /Type /Catalog /Pages 2 0 R >>', b'<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
               b'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 144 81] /Contents 4 0 R /Resources << >> >>', stream]
    out, offsets = b'%PDF-1.4\n', []
    for i, body in enumerate(objects, 1):
        offsets.append(len(out))
        out += b'%d 0 obj\n' % i + body + b'\nendobj\n'
    xref = len(out)
    out += b'xref\n0 %d\n0000000000 65535 f \n' % (len(objects) + 1)
    out += b''.join(b'%010d 00000 n \n' % o for o in offsets)
    out += b'trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n' % (len(objects) + 1, xref)
    Path(path).write_bytes(out)


class PdfCompareTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp)
        spec = importlib.util.spec_from_file_location('pdf_compare', SCRIPTS / 'pdf_compare.py')
        self.mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(self.mod)

    def pdf(self, name, content):
        path = Path(self.tmp) / name
        make_pdf(path, content)
        return str(path)

    def test_diff_stats_and_pgm_header_with_comment(self):
        flat_page = (4, 4, bytes([200] * 16))
        inverted = (4, 4, bytes([20] * 16))
        self.assertEqual(self.mod.diff_stats(flat_page, flat_page), (0.0, 0.0))
        self.assertEqual(self.mod.diff_stats(flat_page, inverted), (180.0, 1.0))
        self.assertTrue(self.mod.flat(flat_page))
        pgm = Path(self.tmp) / 'a.pgm'
        pgm.write_bytes(b'P5\n# comment\n2 2\n255\n' + bytes([1, 2, 3, 4]))
        self.assertEqual(self.mod.read_pgm(pgm), (2, 2, bytes([1, 2, 3, 4])))

    @unittest.skipUnless(shutil.which('pdftoppm') and shutil.which('gs'), 'needs both pdftoppm and gs')
    def test_two_renderers_agree_on_a_drawn_page_and_flag_a_blank_one(self):
        drawn = run('pdf_compare.py', self.pdf('drawn.pdf', b'0.2 g 20 15 90 40 re f'))
        self.assertEqual(drawn.returncode, 0, drawn.stdout)
        self.assertIn('renderers: pdftoppm, gs', drawn.stdout)
        blank = run('pdf_compare.py', self.pdf('blank.pdf', b''))
        self.assertEqual(blank.returncode, 1)
        self.assertIn('uniform', blank.stdout)

    @unittest.skipUnless(shutil.which('pdftoppm'), 'needs pdftoppm')
    def test_single_renderer_skips_the_cross_check(self):
        result = run('pdf_compare.py', self.pdf('drawn.pdf', b'0.2 g 20 15 90 40 re f'), '--renderers', 'pdftoppm')
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn('cross-renderer comparison skipped', result.stdout)

    def test_no_installed_renderer_is_exit_two(self):
        result = run('pdf_compare.py', self.pdf('drawn.pdf', b'0.2 g 20 15 90 40 re f'), '--renderers', 'nonexistent')
        self.assertEqual(result.returncode, 2)


if __name__ == '__main__':
    unittest.main()
