#!/usr/bin/env python3
"""Move personal skills out of dot; preserve originals and link per skill."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from datetime import datetime, timezone


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args])


def inventory(root):
    result = {}
    for p in sorted(root.rglob('*')):
        rel = p.relative_to(root)
        if '__pycache__' in rel.parts or p.name == '.DS_Store':
            continue
        if p.is_symlink():
            result[str(rel)] = ('link', os.readlink(p))
        elif p.is_file():
            result[str(rel)] = ('file', hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mode & 0o111)
    return result


def skills(root):
    if not root.is_dir():
        return []
    return sorted(p for p in root.iterdir() if not p.name.startswith('.') and (p/'SKILL.md').is_file())


def recover(dot, scope, scratch):
    """Recover a deleted source tree from the most recent containing commit."""
    prefix = f'ai/{scope}/skills/'
    for ref in git(dot, 'log', '--format=%H', '--', prefix).decode().splitlines():
        files = git(dot, 'ls-tree', '-r', '--name-only', ref, '--', prefix).decode().splitlines()
        files = [f for f in files if '/.system/' not in f]
        if not any(f.endswith('/SKILL.md') for f in files):
            continue
        for name in files:
            target = scratch/name[len(prefix):]
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(git(dot, 'show', f'{ref}:{name}'))
            mode = git(dot, 'ls-tree', ref, '--', name).decode().split()[0]
            if mode == '100755':
                target.chmod(0o755)
            elif mode == '120000':
                link = target.read_text()
                target.unlink()
                target.symlink_to(link)
        print(f'Recovery source: {scope} from dot commit {ref}')
        return skills(scratch)
    return []


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--dot-root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--destination', type=Path, default=Path(os.environ.get('AGENT_SKILLS_HOME', str(Path.home()/'agent-skills'))))
    parser.add_argument('--codex-home', type=Path, default=Path(os.environ.get('CODEX_HOME', str(Path.home()/'.codex'))))
    parser.add_argument('--claude-home', type=Path, default=Path.home()/'.claude')
    parser.add_argument('--backup-dir', type=Path, default=Path.home()/'.local/state/agent-skills-migration')
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    dot, dest = args.dot_root.resolve(), args.destination.resolve()
    homes = {'codex':args.codex_home.absolute(), 'claude':args.claude_home.absolute()}
    if dest == dot or dot in dest.parents:
        parser.error('Destination must be outside dot.')
    if dest.exists() and not (dest/'.git').exists():
        parser.error('Existing destination is not a Git repository; refusing to adopt unrelated files.')
    plans = []
    with tempfile.TemporaryDirectory(prefix='agent-skills-recovery-') as tmp:
        for scope in homes:
            legacy = dot/'ai'/scope/'skills'
            target_root = dest/'skills'/scope
            live = [p for p in skills(legacy) if p.resolve() != (target_root/p.name).resolve()]
            # An existing extracted scope is authoritative; never overwrite it
            # with historical dot content on subsequent installs.
            if not live and not skills(target_root):
                live = recover(dot, scope, Path(tmp)/scope)
            for src in live:
                target = target_root/src.name
                if target.exists() and inventory(src) != inventory(target):
                    parser.error(f'Conflicting skill: {target}. Original remains at {src}; reconcile before retrying.')
                plans.append((src,target))
            install_root = homes[scope]/'skills'
            if install_root.is_symlink() and install_root.resolve() != legacy.resolve():
                parser.error(f'Unrelated skill-root link: {install_root}; leaving it untouched.')
            if install_root.exists() and not install_root.is_dir():
                parser.error(f'Not a skill directory: {install_root}')
            for target in [t for _,t in plans if t.parent==target_root]+skills(target_root):
                installed = install_root/target.name
                allowed = {target.resolve(), (legacy/target.name).resolve()}
                if installed.is_symlink() and installed.resolve() not in allowed:
                    parser.error(f'Unrelated skill link conflicts: {installed}')
                if installed.exists() and not installed.is_symlink() and not install_root.is_symlink():
                    parser.error(f'Existing host skill conflicts: {installed}; preserve and reconcile it first.')
            system = legacy/'.system'
            installed_system = install_root/'.system'
            if system.exists() and installed_system.exists() and system.resolve()!=installed_system.resolve():
                if inventory(system)!=inventory(installed_system):
                    parser.error('Conflicting host .system skills; originals preserved.')
        print(f'Destination: {dest}; {len(plans)} source skills to copy/verify')
        if args.dry_run:
            for src,target in plans:
                print(f'  {src} -> {target}')
            return
        if not dest.exists():
            dest.mkdir(parents=True)
            subprocess.run(['git','init','-b','main',str(dest)],check=True)
        for src,target in plans:
            if not target.exists():
                shutil.copytree(src,target,symlinks=True,ignore=shutil.ignore_patterns('__pycache__','.DS_Store'))
            if inventory(src)!=inventory(target):
                raise RuntimeError(f'Copy verification failed: {target}; originals have not been moved.')
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        backup = args.backup_dir.absolute()/stamp
        for scope, home in homes.items():
            legacy = dot/'ai'/scope/'skills'
            install_root = home/'skills'
            target_root = dest/'skills'/scope
            if install_root.is_symlink():
                install_root.unlink()
            install_root.mkdir(parents=True,exist_ok=True)
            system = legacy/'.system'
            if system.exists() and not (install_root/'.system').exists():
                shutil.copytree(system,install_root/'.system',symlinks=True)
                if inventory(system)!=inventory(install_root/'.system'):
                    raise RuntimeError('System skill copy failed; original is still present.')
            for target in skills(target_root):
                old = legacy/target.name
                if old.exists() and not old.is_symlink():
                    saved = backup/scope/target.name
                    saved.parent.mkdir(parents=True,exist_ok=True)
                    shutil.move(str(old),str(saved))
                legacy.mkdir(parents=True,exist_ok=True)
                if not old.is_symlink():
                    old.symlink_to(target,target_is_directory=True)
                installed = install_root/target.name
                if installed.is_symlink():
                    installed.unlink()
                installed.symlink_to(target,target_is_directory=True)
            # Keep old in-flight skill references usable, but keep app-owned
            # system files out of both source repositories.
            if system.exists() and not system.is_symlink():
                saved=backup/scope/'.system'
                saved.parent.mkdir(parents=True,exist_ok=True)
                shutil.move(str(system),str(saved))
                system.symlink_to(install_root/'.system',target_is_directory=True)
        print(f'Installed Codex and Claude skills from {dest}')
        if backup.exists():
            print(f'Originals preserved: {backup}')
        print('No remote repository was created or pushed. Commit/publish the new repository separately.')


if __name__ == '__main__':
    main()
