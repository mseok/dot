"""agent-guard git denies commands that discard uncommitted or untracked work and lets other commands through."""
import json
from pathlib import Path
import subprocess
import sys
import unittest

HOOK = Path(__file__).resolve().parents[1] / 'bin/agent-guard'
DENIED = [
    'git reset --hard',
    'git -C "$d" reset --hard -q',  # ran unblocked in a throwaway repository on 2026-11-13
    'git -C "$d" clean -fd',  # ran unblocked in a throwaway repository on 2026-11-13
    'git clean --force -x',
    'git stash',
    'git stash pop',
    'git checkout -- .',
    'git checkout -f main',
    'git restore .',
    'git restore -SW :/',
    'git switch --discard-changes main',
    'cd repo && GIT_PAGER=cat /usr/bin/git reset --hard HEAD~1',
    'if true; then sudo git clean -fdx; fi',
    "ssh server 'cd repo && git clean -fdx'",
    'ssh -o BatchMode=yes server git stash',
    'bash -lc "git checkout ."',
    'echo start\ngit reset --hard\necho done',
]
ALLOWED = [
    'git status --short',
    'git reset --soft HEAD~1',
    'git clean -n -fd',
    'git stash list',
    'git stash show -p',
    'git checkout -- src/tool.py',
    'git checkout -b fix',
    'git restore src/tool.py',
    'git restore --staged .',
    'git switch -c fix',
    'git commit -m "explain why git reset --hard is blocked; git clean -fd too"',
    'grep -n "git clean -fd" notes.md',
    'echo "git stash"',
    "ssh server 'git status'",
]


class GitRuleTest(unittest.TestCase):
    def decision(self, tool_name, tool_input):
        payload = {'hook_event_name': 'PreToolUse', 'tool_name': tool_name, 'tool_input': tool_input}
        result = subprocess.run([sys.executable, '-I', str(HOOK), 'git'], input=json.dumps(payload),
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout) if result.stdout.strip() else None

    def test_destructive_commands_are_denied(self):
        for command in DENIED:
            with self.subTest(command=command):
                decision = self.decision('Bash', {'command': command})
                self.assertEqual(decision['hookSpecificOutput']['permissionDecision'], 'deny')

    def test_other_commands_pass(self):
        for command in ALLOWED:
            with self.subTest(command=command):
                self.assertIsNone(self.decision('Bash', {'command': command}))

    def test_codex_tool_names_and_list_commands(self):
        self.assertIsNotNone(self.decision('mcp__app__exec_command', {'cmd': 'git stash'}))
        self.assertIsNotNone(self.decision('shell', {'command': ['bash', '-lc', 'git reset --hard']}))
        self.assertIsNone(self.decision('Read', {'command': 'git reset --hard'}))

    def test_unbalanced_quotes_fall_back_without_error(self):
        self.assertIsNone(self.decision('Bash', {'command': "echo user's note\ngit status"}))
        self.assertIsNotNone(self.decision('Bash', {'command': "echo user's note\ngit reset --hard"}))


if __name__ == '__main__':
    unittest.main()
