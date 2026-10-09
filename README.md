# Workspace Names & Icons

**Know what's on every workspace before you switch to it.**

An Omarchy bar widget that replaces the stock workspace numbers **in place**. Each workspace
keeps its number and gains a name and an icon. Double-click one to change it: no config files.

![Workspace Names & Icons: the stock numbers, then the same bar with names and icons](preview.png)

Other workspace plugins add a second widget somewhere else on the bar, swap the number for a
name, or show app icons that change every time you open a window. This one takes over the
stock widget's spot, keeps the number so `SUPER+3` still goes to the workspace labeled 3, and
shows the names *you* chose, so workspace 2 is always "Code" whatever is open on it.

*(Formerly "Workspace Nameplates". Same plugin, same ID; existing installs keep working.)*

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

Review the source first. Like every Omarchy plugin, it runs unsandboxed
inside `omarchy-shell`. Then:

```bash
omarchy plugin add https://github.com/jburchel/omarchy-workspace-nameplates.git
```

When asked, accept the prompt to enable the plugin and choose the **left**
section, which is preselected. Then put it first in that section and turn off
the stock numbers, so it sits in the stock widget's place:

```bash
omarchy plugin enable io.github.jburchel.workspace-nameplates --section left --index 0
omarchy plugin disable omarchy.workspaces
```

Then double-click any workspace to give it a name and an icon.

## Update

```bash
omarchy plugin update io.github.jburchel.workspace-nameplates
```

## Remove

Put the stock widget back, then remove the plugin:

```bash
omarchy plugin enable omarchy.workspaces --section left --index 0
omarchy plugin remove io.github.jburchel.workspace-nameplates
```

If you added the optional keybinding, remove it from `bindings.lua`.

> **Note:** Disabling or removing the widget deletes its entry in
> `shell.json`, including the names and icons you set. Copy the entry first
> if you want to keep them.

## Requirements

- Omarchy 4 (Quattro shell). Tested on Omarchy 4.0.4 with Hyprland 0.56.
- A Nerd Font for the bar. Omarchy's default, JetBrainsMono Nerd Font, works.

There are no other dependencies. The plugin makes no network requests, needs
no administrator rights and has no install hooks. It writes only its own entry in
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
`edit 0` opens it for the current workspace. The shell registers this IPC
command only at startup, so run `omarchy restart shell` once after installing
if you want to use it. Double-click editing works without a restart.

## Tests

```bash
node tests/qml-text.test.js   # every Text item renders plain text
```

## More Omarchy plugins by Jim Burchel

- **[Meeting Mode](https://github.com/jburchel/omarchy-meeting-mode)**: join any call and your
  desktop goes quiet by itself (Do Not Disturb, no idle lock, night light off); hang up and it
  all comes back.
- **[Jarvis](https://github.com/jburchel/omarchy-jarvis)**: a voice for the AI agent in your
  terminal. Claude Code, Codex or Gemini CLI read their replies aloud, and "Hey Jarvis" starts
  hands-free dictation.
- **[Omarchy Alt-Tab](https://github.com/jburchel/omarchy-alt-tab)**: hold Alt and tap Tab
  through live previews of your windows, like Windows and macOS.

If your workspaces finally make sense at a glance, a ⭐ on GitHub helps other people find this.

## Credits

Icon names come from the [Nerd Fonts](https://www.nerdfonts.com) glyph index
(MIT). The widget is adapted from Omarchy's stock `omarchy.workspaces`.

## License

MIT
