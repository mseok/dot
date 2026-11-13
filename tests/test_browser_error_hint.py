"""The browser hint adds recovery steps for real browser-tool failures only, re-arms after ten minutes, never blocks."""
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
DENIED = 'Local browser access is unavailable for this chat'
NO_IAB = 'Browser is not available: iab'
CHAT = '00000000-0000-7000-8000-000000000001'
CHROME = {'family': 'chrome', 'id': '1', 'name': 'Chrome', 'type': 'extension', 'tabs': []}
IAB = {'id': '3', 'name': 'ChatGPT in-app browser', 'type': 'iab', 'metadata': {'codexSessionId': CHAT}, 'tabs': []}


def inventory(*browsers, errors=None):
    """The text cua.getState() prints after its documentation."""
    state = {'apps': [{'displayName': 'Finder', 'id': 'com.apple.finder'}], 'browsers': list(browsers)}
    if errors:
        state['errors'] = errors
    return [{'type': 'text', 'text': 'type BrowserInfo = { type?: "iab" | "extension" };'},
            {'type': 'text', 'text': json.dumps(state, separators=(',', ':'))}]


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

    def assert_hint(self, out, event='PostToolUse', kind='access'):
        self.assertIsNotNone(out)
        specific = out['hookSpecificOutput']
        self.assertEqual(specific['hookEventName'], event)
        text = specific['additionalContext']
        self.assertIn('navigate_to_codex_page', text)
        self.assertIn('codex-browser.md', text)
        self.assertIn('not a setting', text)
        self.assertEqual('js_reset' in text, kind == 'access', text)
        self.assertNotIn('{chat}', text)
        self.assertNotIn('decision', out)
        return text

    def test_claude_object_response(self):
        self.assert_hint(self.run_hook(self.claude({'content': [{'type': 'text', 'text': MESSAGE}], 'isError': True})))

    def test_claude_content_block_list(self):
        self.assert_hint(self.run_hook(self.claude([{'type': 'text', 'text': 'Error: ' + MESSAGE.lower()}])))

    def test_codex_string_response_with_turn_fields_names_the_chat(self):
        payload = self.claude(DENIED, session=CHAT, tool='mcp__cua_repl__js', model='gpt-6.1-sol',
                              permission_mode='default', turn_id='u1')
        payload['tool_input'] = {'code': 'await cua.listBrowsers();', 'title': 'check'}
        self.assertIn(f"this chat's id ({CHAT})", self.assert_hint(self.run_hook(payload)))

    def test_denied_inventory_from_the_2026_11_13_failure(self):
        """The recorded cua.getState() listed no browsers and carried the denial in its errors."""
        response = inventory(errors=[f'Browsers: Error: {DENIED}'])
        self.assert_hint(self.run_hook(self.claude(response, tool='mcp__cua_repl__js')))

    def test_missing_in_app_browser_message(self):
        payload = self.claude([{'type': 'text', 'text': NO_IAB}], tool='mcp__cua_repl__js')
        self.assert_hint(self.run_hook(payload), kind='missing')

    def test_inventory_without_in_app_browser(self):
        """A chat driven from another device lists only Chrome and reports no error (observed 2026-11-13)."""
        self.assert_hint(self.run_hook(self.claude(inventory(CHROME), tool='mcp__cua_repl__js')), kind='missing')
        escaped = json.dumps(inventory(CHROME))
        self.assert_hint(self.run_hook(self.claude(escaped, session='s2', tool='mcp__cua_repl__js')), kind='missing')

    def test_inventory_with_in_app_browser_prints_nothing(self):
        self.assertIsNone(self.run_hook(self.claude(inventory(CHROME, IAB), tool='mcp__cua_repl__js')))
        self.assertIsNone(self.run_hook(self.claude(json.dumps(inventory(IAB)), tool='mcp__cua_repl__js')))
        self.assertEqual(os.listdir(self.state.name), [])

    def test_each_kind_is_hinted_separately(self):
        self.assert_hint(self.run_hook(self.claude(NO_IAB)), kind='missing')
        self.assert_hint(self.run_hook(self.claude(DENIED)))
        self.assertIsNone(self.run_hook(self.claude(NO_IAB)))
        self.assertIsNone(self.run_hook(self.claude(DENIED)))

    def test_code_mode_wrapper_that_drives_the_browser(self):
        payload = self.claude(DENIED, tool='exec')
        payload['tool_input'] = 'text(await tools.mcp__cua_repl__js({code:"await cua.getState();"}));'
        self.assert_hint(self.run_hook(payload))

    def test_failure_event_with_error_string(self):
        out = self.run_hook(self.claude(None, event='PostToolUseFailure', error=MESSAGE))
        self.assert_hint(out, 'PostToolUseFailure')

    def test_once_per_ten_minutes_then_new_session(self):
        self.assert_hint(self.run_hook(self.claude(session='a')))
        self.assertIsNone(self.run_hook(self.claude(session='a')))
        self.assert_hint(self.run_hook(self.claude(session='b')))

    def test_hint_returns_after_ten_minutes(self):
        """A later turn that fails again gets the steps again; an earlier hint cannot use them up for good."""
        self.assert_hint(self.run_hook(self.claude(session='a')))
        earlier = time.time() - 11 * 60
        for marker in Path(self.state.name).iterdir():
            os.utime(marker, (earlier, earlier))
        self.assert_hint(self.run_hook(self.claude(session='a')))
        self.assertIsNone(self.run_hook(self.claude(session='a')))

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

    def test_file_and_shell_tools_quoting_the_messages_do_not_hint(self):
        """All four hints given between 2026-11-10 and 2026-11-13 were quotes printed by shell commands."""
        quoted = f'- `access-unresolved`: "{MESSAGE}" "{DENIED}" "{NO_IAB}" ' + json.dumps(inventory(CHROME))
        self.assertIsNone(self.run_hook(self.claude(quoted, tool='Read')))
        self.assertIsNone(self.run_hook(self.claude(quoted, tool='Grep')))
        for command in ('cat ~/dot/ai/codex/references/codex-browser.md', 'cd /tmp && grep -n disabled notes.md',
                        '/usr/bin/sed -n 1,20p file.md', 'cd refs && /bin/ls -la . && cat enforcement-ledger.md',
                        "python3 - <<'PY'\nprint(open('rollout.jsonl').read())\nPY", 'node run-browser.js'):
            payload = self.claude(quoted, tool='Bash')
            payload['tool_input'] = {'command': command}
            self.assertIsNone(self.run_hook(payload), command)
            payload = self.claude(quoted, tool='exec_command')
            payload['tool_input'] = {'cmd': command}
            self.assertIsNone(self.run_hook(payload), command)
        self.assertEqual(os.listdir(self.state.name), [])
        self.assert_hint(self.run_hook(self.claude(MESSAGE)))

    def test_other_tools_quoting_the_messages_do_not_hint(self):
        quoted = f'A note that quotes "{DENIED}" and "{NO_IAB}".'
        for tool, tool_input in (('mcp__obsidian_main__knowledge_read', {'path': 'Inbox/Agents/note.md'}),
                                 ('mcp__codex_app__read_thread', {'threadId': CHAT}),
                                 ('exec', 'text(await tools.exec_command({cmd:"cat notes.md"}));')):
            payload = self.claude(quoted, tool=tool)
            payload['tool_input'] = tool_input
            self.assertIsNone(self.run_hook(payload), tool)
        self.assertEqual(os.listdir(self.state.name), [])

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
