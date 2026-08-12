# AeroSpace and Codex Pet

ChatGPT exposes Codex Pet as native macOS popup windows. AeroSpace intentionally
leaves these popups outside its workspace tree, so neither
`move-node-to-workspace` nor `layout sticky` can attach Pet to a workspace.

The current ChatGPT build also does not render Pet at the position reported by
the popup Accessibility elements. The workspace-change callback therefore
deliberately does nothing for Pet: it avoids changing its internal popup layers
while preserving the normal ChatGPT and Claude placement rules and workspace 7
navigation.

The existing pinned AeroSpace fork may remain installed for its other features.
Pet will need a supported ChatGPT placement mechanism before it can reliably
follow a workspace or monitor.
