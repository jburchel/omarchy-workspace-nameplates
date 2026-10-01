# Workspace Nameplates

An Omarchy bar widget that replaces the stock workspace numbers **in place**.
Each workspace keeps its number and gains a name and an icon:

![Workspace Nameplates in the bar](docs/bar.png)

Other workspace plugins add a second widget somewhere else on the bar, or
swap the number for a name. This one takes over the left-hand slot of
`omarchy.workspaces` and keeps the number, so `SUPER+3` still goes to the
workspace labeled 3.

## Features

- **Number + name + icon** for every workspace, in the stock widget's spot.
- **Double-click to edit.** Double-click a workspace (or right-click it) to
  rename it and choose an icon. Changes save to `shell.json` and appear
  immediately.
- **Searchable icon picker.** Search about 10,000 Nerd Font glyphs by name,
  e.g. "terminal", "firefox" or "church"; no copy-pasting of glyphs.
- **Behaves like the stock widget.** Click to switch, scroll to cycle. Empty
  workspaces are dimmed. The focused workspace is shown in your theme's
  accent color with an underline.
- **Theme aware.** Colors, font and spacing come from your Omarchy theme.
  Vertical bars show just the icon.

![The editor](docs/editor.png)

In the editor, **Enter** saves, **Esc** cancels and **Tab** moves between the
name and icon search fields. Pressing Enter in the search field picks the
first match. Double-click an icon to pick it and save in one step.

## Install

```bash
git clone https://github.com/jburchel/omarchy-workspace-nameplates \
  ~/.config/omarchy/plugins/io.github.jburchel.workspace-nameplates
```

Then, in `~/.config/omarchy/shell.json`, replace the stock widget in
`bar.layout.left`:

```json
{ "id": "omarchy.workspaces" }
```

with

```json
{ "id": "io.github.jburchel.workspace-nameplates" }
```

The bar reloads on save. If the widget does not show up, run
`omarchy restart shell`.

## Remove

1. In `~/.config/omarchy/shell.json`, change the entry's id back to
   `omarchy.workspaces`. You can also delete its `format` and `workspaces`
   keys, which the stock widget ignores.
2. Delete the plugin folder:

   ```bash
   rm -rf ~/.config/omarchy/plugins/io.github.jburchel.workspace-nameplates
   ```

3. If you added the optional keybinding, remove it from `bindings.lua`.

## Requirements

- Omarchy 4 (Quattro shell). Tested on Omarchy 4.0.4 with Hyprland 0.56.
- A Nerd Font for the bar. Omarchy's default, JetBrainsMono Nerd Font, works.

There are no other dependencies. The plugin makes no network requests, needs
no sudo and has no install hooks. It writes only its own entry in
`~/.config/omarchy/shell.json`, and only when you press Save in the editor.

## Configuration

The editor writes everything for you. If you prefer, you can edit the same
entry by hand:

```json
{
  "id": "io.github.jburchel.workspace-nameplates",
  "format": "{number} {name} {icon}",
  "verticalFormat": "{icon}",
  "workspaces": {
    "1": { "name": "Web",  "icon": "󰈹" },
    "2": { "name": "Code", "icon": "󰨞" }
  }
}
```

| Key | Default | Meaning |
| --- | --- | --- |
| `format` | `"{number} {name} {icon}"` | Label layout on horizontal bars. Try `"{number}:{name}"` or `"{icon} {number}"`. |
| `verticalFormat` | `"{icon}"` | Label layout on left/right bars. Falls back to the number when the result is empty. |
| `workspaces` | `{}` | Per-workspace `name` and `icon`, keyed by workspace number (`"10"` is shown as 0). |
| `persistent` | 1–5 plus every named workspace | Array of workspace numbers that are always shown, even when empty. Occupied workspaces are always shown. |

## Keybinding

To open the editor for the current workspace from the keyboard, add this to
`~/.config/hypr/bindings.lua` (pick any free key):

```lua
o.bind("SUPER + CTRL + N", "Rename workspace", "omarchy-shell io.github.jburchel.workspace-nameplates edit 0")
```

`edit <n>` opens the editor for workspace *n* on the focused monitor, and
`edit 0` opens it for the current workspace.

## Tests

```bash
node tests/qml-text.test.js   # every Text item renders plain text
```

## Credits

Icon names come from the [Nerd Fonts](https://www.nerdfonts.com) glyph index
(MIT). The widget is adapted from Omarchy's stock `omarchy.workspaces`.

## License

MIT
