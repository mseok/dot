# AeroSpace and Codex Pet

ChatGPT exposes Codex Pet as a group of native macOS popup windows. AeroSpace
intentionally leaves these popups outside its workspace tree, so neither
`move-node-to-workspace` nor `layout sticky` can safely attach Pet to a
workspace. Applying either command to an individual composition layer risks
detaching the native overlay.

`follow-codex-pet.sh` therefore resolves the focused workspace's visible
monitor and invokes `move-codex-pet-to-monitor.js`. The helper moves the three
Accessibility-verified render owners exactly once: the composition surface,
activity stack, and mascot effect. ChatGPT moves the dependent backing surface
with the composition owner. It is a no-op when the Pet is absent or already on
that monitor, and it never moves a normal ChatGPT or Claude window.

The existing pinned AeroSpace fork may remain installed for its other features,
but Pet following no longer depends on its experimental `layout sticky` command.
If macOS asks, allow `/usr/bin/osascript` to control ChatGPT under
System Settings > Privacy & Security > Accessibility.
