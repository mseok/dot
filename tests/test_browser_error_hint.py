"""The browser error hint adds context once per session, only for the real message, and never blocks."""
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1]/'bin/browser-error-hint'
MESSAGE = 'Local browser use is disabled in Work settings.'


class BrowserErrorHintTest(unittest.TestCase):
    def setUp(self):
        self.state = tempfile.TemporaryDirectory()
        self.addCleanup(self.state.cleanup)

    def run_hook(self, payload, raw=None):
        env = dict(os.environ, BROWSER_ERROR_HINT_STATE_DIR=self.state.name)
        data = raw if raw is not None else json.dumps(payload)
        result = subprocess.run([sys.executable, str(SCRIPT)], input=data, capture_output=True, text=True, env=env, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout) if result.stdout.strip() else None

    @staticmethod
    def claude(response=MESSAGE, session='s1', event='PostToolUse', tool='mcp__node_repl__js', **extra):
        payload = {'session_id': session, 'hook_event_name': event, 'tool_name': tool, 'tool_input': {'code': 'x'},
                   'tool_use_id': 't1', 'transcript_path': '/tmp/none.jsonl', 'cwd': '/tmp'}
        payload.update(extra)
        if response is not None:
            payload['tool_response'] = response
        return payload

    def assert_hint(self, out, event='PostToolUse'):
        self.assertIsNotNone(out)
        specific = out['hookSpecificOutput']
        self.assertEqual(specific['hookEventName'], event)
        self.assertIn('no browser executor is linked', specific['additionalContext'])
        self.assertIn('codex-browser.md', specific['additionalContext'])
        self.assertNotIn('decision', out)

    def test_claude_object_response(self):
        self.assert_hint(self.run_hook(self.claude({'content': [{'type': 'text', 'text': MESSAGE}], 'isError': True})))

    def test_claude_content_block_list(self):
        self.assert_hint(self.run_hook(self.claude([{'type': 'text', 'text': 'Error: ' + MESSAGE.lower()}])))

    def test_codex_string_response_with_turn_fields(self):
        payload = self.claude(MESSAGE, tool='exec_command', model='claude-sonnet-5-5', permission_mode='default', turn_id='u1')
        payload['tool_input'] = {'cmd': 'node run-browser.js'}
        self.assert_hint(self.run_hook(payload))

    def test_failure_event_with_error_string(self):
        out = self.run_hook(self.claude(None, event='PostToolUseFailure', error=MESSAGE))
        self.assert_hint(out, 'PostToolUseFailure')

    def test_once_per_session_then_new_session(self):
        self.assert_hint(self.run_hook(self.claude(session='a')))
        self.assertIsNone(self.run_hook(self.claude(session='a')))
        self.assert_hint(self.run_hook(self.claude(session='b')))

    def test_missing_session_id_still_hints_once(self):
        payload = self.claude()
        del payload['session_id']
        self.assert_hint(self.run_hook(payload))
        self.assertIsNone(self.run_hook(payload))

    def test_other_results_print_nothing_and_keep_the_hint_available(self):
        self.assertIsNone(self.run_hook(self.claude('all good')))
        self.assertIsNone(self.run_hook(self.claude(None)))
        self.assertEqual(os.listdir(self.state.name), [])
        self.assert_hint(self.run_hook(self.claude()))

    def test_file_reads_quoting_the_message_do_not_consume_the_hint(self):
        quoted = f'- `access-unresolved`: "{MESSAGE}"'
        self.assertIsNone(self.run_hook(self.claude(quoted, tool='Read')))
        self.assertIsNone(self.run_hook(self.claude(quoted, tool='Grep')))
        for command in ('cat ~/dot/ai/codex/references/codex-browser.md', 'cd /tmp && grep -n disabled notes.md',
                        '/usr/bin/sed -n 1,20p file.md'):
            payload = self.claude(quoted, tool='Bash')
            payload['tool_input'] = {'command': command}
            self.assertIsNone(self.run_hook(payload), command)
        self.assert_hint(self.run_hook(self.claude(MESSAGE)))

    def test_shell_command_that_is_not_a_reader_still_hints(self):
        payload = self.claude(MESSAGE, tool='Bash')
        payload['tool_input'] = {'command': 'cd /tmp && node browser-check.js'}
        self.assert_hint(self.run_hook(payload))

    def test_bad_or_empty_input_is_ignored(self):
        self.assertIsNone(self.run_hook(None, raw=''))
        self.assertIsNone(self.run_hook(None, raw='not json'))
        self.assertIsNone(self.run_hook(None, raw='["a list"]'))

    def test_stale_markers_are_pruned(self):
        stale = Path(self.state.name)/'stale'
        stale.write_text('')
        old = time.time() - 8 * 24 * 3600
        os.utime(stale, (old, old))
        self.assert_hint(self.run_hook(self.claude()))
        self.assertFalse(stale.exists())


if __name__ == '__main__':
    unittest.main()
