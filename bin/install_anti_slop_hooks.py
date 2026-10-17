#!/usr/bin/env python3
"""Merge the shared anti-slop handlers into host-local client settings."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shlex
import shutil
import stat
import sys
import tempfile


def prepare(path, client, hook):
    before = path.read_bytes() if path.exists() else None
    config = json.loads(before) if before is not None else {}
    command = shlex.join([sys.executable, str(hook), client])
    hooks = config.setdefault('hooks', {})
    for event in ['SessionStart', 'UserPromptSubmit', 'Stop']:
        groups = hooks.setdefault(event, [])
        present = any(handler.get('command') == command for group in groups
                      for handler in group.get('hooks', []))
        if not present:
            groups.append({'hooks': [{'type': 'command', 'command': command, 'timeout': 30}]})
    encoded = (json.dumps(config, ensure_ascii=False, indent=2) + '\n').encode()
    return before, encoded


def publish(path, before, encoded):
    if before == encoded:
        print(str(path) + ': unchanged')
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    if (path.read_bytes() if path.exists() else None) != before:
        raise ValueError('Configuration changed while preparing: ' + str(path))
    mode = stat.S_IMODE(path.stat().st_mode) if before is not None else 0o600
    if before is not None:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
        backup = path.with_name(path.name + '.anti-slop-backup-' + stamp)
        with backup.open('xb') as stream:
            os.fchmod(stream.fileno(), 0o600)
            stream.write(before)
            stream.flush()
            os.fsync(stream.fileno())
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix='.anti-slop-', delete=False) as stream:
            temporary = Path(stream.name)
            os.fchmod(stream.fileno(), mode)
            stream.write(encoded)
            stream.flush()
            os.fsync(stream.fileno())
        if (path.read_bytes() if path.exists() else None) != before:
            raise ValueError('Configuration changed before publication: ' + str(path))
        os.replace(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
    print(str(path) + ': installed')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--codex-home', type=Path, default=Path.home() / '.codex')
    parser.add_argument('--claude-home', type=Path, default=Path.home() / '.claude')
    args = parser.parse_args()
    hook = Path(__file__).resolve().with_name('anti-slop-hook')
    if shutil.which('git') is None or shutil.which('ruff') is None:
        parser.error('Install host-shared Git and Ruff before enabling these hooks')
    destinations = [(args.codex_home / 'hooks.json', 'codex'),
                    (args.claude_home / 'settings.json', 'claude')]
    plans = [(path, *prepare(path, client, hook)) for path, client in destinations]
    for path, before, encoded in plans:
        publish(path, before, encoded)
    print('Codex requires review and trust of new handlers through /hooks. Existing trust is preserved.')


if __name__ == '__main__':
    main()
