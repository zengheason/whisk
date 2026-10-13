# Clipboard workflow

Hold Command while the panel is open to see ⌘1 through ⌘9 on the first
nine cards in the current filtered order. Releasing Command hides the
labels. The shortcuts use that same order.

Selecting a card copies it to the current clipboard and closes the panel.
Press ⌘V when ready to paste. Settings → **Paste automatically after
selecting** restores automatic pasting if desired. The default is off.
Explicit plain text and text transformation actions discard formatting;
ordinary selection and the paste stack restore the original representations.

Use **New Group…** at the end of the category row to create a custom group.
Right-click a card → **Groups** to toggle its membership. Multiple groups
are allowed. Click group chips to filter; they combine with the existing
source, category and search filters. Right-click a group to rename or
delete it. Grouped entries are protected from Clear, capacity eviction and
age-based expiration. Removing the last group makes an unpinned entry
subject to the history policy again.

Settings → **Frosted glass effect** controls cards, search, chips, editor,
preview and the separate background blur. Off uses opaque surfaces;
macOS Reduce Transparency remains respected even when the switch is on.

Original HTML, RTF, app-specific representations and item boundaries are
stored locally with newly captured history. Ordinary copy restores their
bytes without converting them. Two copies with identical text but different
representations remain distinct. Receiving applications still choose the
format they support. Formats discarded by older Whisk versions cannot be
reconstructed; copy those entries again from their source.

Groups are stored in `groups.json` alongside `history.sqlite`. Memberships
and original formats use additional SQLite tables; existing entries remain
readable. Use the complete data directory when backing up history.
