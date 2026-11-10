"""agent-detach starts a job that survives its launcher, and status tells alive from exited."""
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

SCRIPT = Path(os.environ.get('AGENT_DETACH_SCRIPT') or Path(__file__).resolve().parents[1]/'bin/agent-detach')


class AgentDetachTest(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.env = dict(os.environ, AGENT_DETACH_DIR=tmp.name)
        self.pids = []
        self.addCleanup(self.kill_all)

    def kill_all(self):
        for pid in self.pids:
            try:
                os.killpg(pid, signal.SIGKILL)
            except ProcessLookupError:
                pass

    def detach(self, *args):
        return subprocess.run([sys.executable, str(SCRIPT), *args], capture_output=True, text=True, env=self.env, check=False)

    def start(self, name, *command):
        result = self.detach('run', '--name', name, '--', *command)
        self.assertTrue(result.stdout.startswith('alive pid='), result.stdout + result.stderr)
        pid = int(result.stdout.split('pid=')[1].split()[0])
        self.pids.append(pid)
        return pid, result.stdout

    def test_long_job_is_alive_in_its_own_session(self):
        pid, out = self.start('sleeper', 'sleep', '30')
        self.assertIn('log=', out)
        self.assertIn('receipt=', out)
        self.assertEqual(os.getsid(pid), pid)
        self.assertNotEqual(os.getsid(pid), os.getsid(0))
        self.assertTrue(self.detach('status', 'sleeper').stdout.startswith('alive '))

    def test_killed_job_reports_exited_with_unknown_code(self):
        pid, _ = self.start('killme', 'sleep', '30')
        os.killpg(pid, signal.SIGKILL)
        deadline = time.time() + 5
        while time.time() < deadline and self.detach('status', 'killme').stdout.startswith('alive'):
            time.sleep(0.2)
        self.assertIn('exited code=unknown', self.detach('status', 'killme').stdout)

    def test_quick_exit_prints_code_and_log_tail(self):
        result = self.detach('run', '--name', 'quick', '--', 'sh', '-c', 'echo first; echo last; exit 3')
        self.assertEqual(result.returncode, 3, result.stderr)
        self.assertTrue(result.stdout.startswith('exited code=3 '), result.stdout)
        self.assertIn('first\nlast', result.stdout)

    def test_stdin_is_closed(self):
        result = self.detach('run', '--name', 'stdin', '--', sys.executable, '-c', 'import sys; print(repr(sys.stdin.read()))')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("''", result.stdout)

    def test_missing_command_exits_127_with_reason(self):
        result = self.detach('run', '--name', 'missing', '--', 'no-such-command-for-agent-detach')
        self.assertEqual(result.returncode, 127, result.stdout)
        self.assertIn('cannot start', result.stdout)

    def test_finished_job_status_has_exit_code(self):
        self.start('finishes', 'sleep', '3')
        deadline = time.time() + 8
        while time.time() < deadline and self.detach('status', 'finishes').stdout.startswith('alive'):
            time.sleep(0.3)
        self.assertTrue(self.detach('status', 'finishes').stdout.startswith('exited code=0 '))

    def test_reused_pid_is_not_reported_alive(self):
        receipt = Path(self.env['AGENT_DETACH_DIR'])/'forged-20261110-000000-0000.json'
        receipt.write_text(json.dumps({'name': 'forged', 'pid': os.getpid(), 'started': 'Mon Jan  1 00:00:00 2001', 'log': 'x'}))
        out = self.detach('status', str(receipt)).stdout
        self.assertIn('exited', out)
        self.assertIn('reused', out)

    def test_status_without_receipt_fails_and_lists_jobs(self):
        self.assertEqual(self.detach('status', 'nothing-here').returncode, 2)
        self.start('listed', 'sleep', '30')
        self.assertIn('name=listed', self.detach('status').stdout)

    def test_dotted_name_and_bad_name(self):
        self.start('a.b', 'sleep', '30')
        self.assertIn('name=a.b', self.detach('status', 'a.b').stdout)
        self.assertNotEqual(self.detach('run', '--name', 'bad name', '--', 'true').returncode, 0)


if __name__ == '__main__':
    unittest.main()
