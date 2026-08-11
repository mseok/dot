# AeroSpace and Codex Pet

The Codex Pet overlay configuration requires the pinned AeroSpace fork
`0.20.3-Beta-fork.8`. The stable Homebrew build does not provide the
`layout ... sticky` command used to keep the Pet's native popup layers visible
across workspace changes.

Install the pinned app and CLI with:

```bash
bash "$HOME/dot/bin/install_aerospace_pet_fork.sh"
```

The installer downloads the release from
`vitorebatista/AeroSpace`, verifies its SHA-256, preserves existing app/CLI
paths with timestamped backups, installs the fork at `/Applications/AeroSpace.app`
and links its CLI as `$(brew --prefix)/bin/aerospace`.

After replacing the app, macOS may require AeroSpace to be enabled again in
System Settings > Privacy & Security > Accessibility.
