#!/usr/bin/env python3
"""Register the shared agent-guard PreToolUse handlers in host-local Claude Code and Codex settings."""
import argparse
import json
from pathlib import Path
import shlex
import sys

from install_anti_slop_hooks import publish

RULES = {
    'login-scan': 'Bash',
    'identifiers': 'Bash|Agent|Task|spawn_agent|send_input|WebFetch|WebSearch|web_run|web_search',
}
CONFIG = Path.home() / '.config' / 'agent-guard'


def prepare(path, hook):
    before = path.read_bytes() if path.exists() else None
    config = json.loads(before) if before is not None else {}
    groups = config.setdefault('hooks', {}).setdefault('PreToolUse', [])
    for rule, matcher in RULES.items():
        command = shlex.join([sys.executable, '-I', str(hook), rule])
        present = any(handler.get('command') == command for group in groups
                      for handler in group.get('hooks', []))
        if not present:
            # Appending keeps the indexes, and so the Codex trust entries, of existing handlers.
            groups.append({'matcher': matcher, 'hooks': [{'type': 'command', 'command': command, 'timeout': 10}]})
    encoded = (json.dumps(config, ensure_ascii=False, indent=2) + '\n').encode()
    return before, encoded


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--codex-home', type=Path, default=Path.home() / '.codex')
    parser.add_argument('--claude-home', type=Path, default=Path.home() / '.claude')
    args = parser.parse_args()
    hook = Path(__file__).resolve().with_name('agent-guard')
    destinations = [args.codex_home / 'hooks.json', args.claude_home / 'settings.json']
    plans = [(path, *prepare(path, hook)) for path in destinations]
    for path, before, encoded in plans:
        publish(path, before, encoded, label='agent-guard')
    for name in ['login-hosts', 'identifiers']:
        if not (CONFIG / name).exists():
            print(f'{CONFIG / name} is missing; that rule stays inactive until it exists')
    print('Codex requires review and trust of new handlers through /hooks. Existing trust is preserved.')


if __name__ == '__main__':
    main()
