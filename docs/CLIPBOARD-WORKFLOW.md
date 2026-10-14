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

Drag a card onto a group chip to add it; repeating a drop keeps it in the
group. The panel remains visible for internal drops. Cards still support
dragging their contents to other applications outside the panel.

New groups cycle through six colors. The group chip and a small card-header dot show
the color; when several memberships exist, the active group takes priority,
otherwise the first membership supplies the header color. Right-click a
group → **Group Color** to change it. Existing groups default to blue.
Click a group, then press Return to rename it; Return saves and Escape cancels.
Group filters use the same card rail, sizes and previews as other filters.
Command hints reserve their layout space even when hidden.

Group creation and renaming now edit the chip directly in the filter row;
the card rail stays visible. Return saves and Escape cancels. Invalid names
keep the editor open with a red outline and explanatory tooltip. All cards retain their original frosted surfaces. Group membership is shown
only by a colored dot, with identical header and body spacing across cards.
Internal drags preserve the panel through key-window changes and mouse-up.

Focus changes never dismiss the panel. A new outside click, Escape or an
explicit card activation dismisses it. Drag completion cannot activate a
card as a click; the next mouse-down starts a fresh interaction. No timers
or mouse-release polling participate in drag dismissal.

Group filtering is single-select: choosing a group replaces the previous one;
choosing it again clears the group filter. Membership in multiple groups remains
possible. Card text and code previews use a 14-point font.

While the panel is open, transparent input shields cover connected screens.
Outside scrolling routes to the card rail, and navigation swipes are consumed
instead of reaching underlying applications. An outside click closes the panel
and removes the shields without activating the underlying control. This is
independent of the glass setting.
