"""The fan-out preflight prints one line and never blocks a launch."""
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1]/'bin/fanout-preflight'


class PreflightTest(unittest.TestCase):
    def run_script(self, quota_cmd, *extra):
        env = dict(os.environ, FANOUT_PREFLIGHT_QUOTA_CMD=quota_cmd)
        return subprocess.run([sys.executable, str(SCRIPT), '--agents', '8', '--model', 'claude-sonnet-5-5', '--effort', 'high', *extra],
                              capture_output=True, text=True, env=env, check=False)

    def fake_quota(self, used):
        with tempfile.NamedTemporaryFile('w', suffix='.py', delete=False) as tmp:
            tmp.write('import json\nprint(json.dumps({"providers": [{"windows": [{"scope": "account", "windowMinutes": 10080, '
                      f'"usedPercent": {used}, "resetsAt": "2026-11-11T14:00:00.000Z"}}]}}]}}))\n')
        self.addCleanup(os.unlink, tmp.name)
        return f'{sys.executable} {tmp.name}'

    def test_one_line_with_quota_and_estimate(self):
        result = self.run_script(self.fake_quota(40), '--chars', '2000000')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len(result.stdout.strip().splitlines()), 1)
        for part in ('8 agents', 'claude-sonnet-5-5', 'effort high', '40% used', '+1.0 to +3.4 weekly points'):
            self.assertIn(part, result.stdout)

    def test_nearly_exhausted_quota_still_exits_zero(self):
        result = self.run_script(self.fake_quota(99))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('99% used', result.stdout)

    def test_unreadable_quota_is_reported_not_fatal(self):
        result = self.run_script('false')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('claude quota unavailable', result.stdout)


if __name__ == '__main__':
    unittest.main()
