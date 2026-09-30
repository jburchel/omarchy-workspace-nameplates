import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// Drop-in replacement for omarchy.workspaces. Same slot, same click
// behaviour, but every workspace renders as "<number> <name> <icon>".
//
// Configure it in the widget's shell.json layout entry:
//
//   { "id": "io.github.jburchel.workspace-nameplates",
//     "format": "{number} {name} {icon}",
//     "workspaces": {
//       "1": { "name": "Web",  "icon": "󰈹" },
//       "2": { "name": "Code", "icon": "" }
//     } }
//
// Workspaces with a name or icon are always shown; otherwise 1-5 plus any
// occupied workspace appear, like the stock widget.
//
// Double-click (or right-click) a workspace to rename it and pick an icon;
// the editor writes the result back into this same shell.json entry.
BarWidget {
  id: root
  moduleName: "io.github.jburchel.workspace-nameplates"

  readonly property var names: setting("workspaces", ({}))
  readonly property string format: setting("format", "{number} {name} {icon}")
  readonly property string verticalFormat: setting("verticalFormat", "{icon}")
  readonly property var persistent: setting("persistent", null)

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function entryFor(id) {
    var entry = root.names ? root.names[String(id)] : null
    return entry && typeof entry === "object" ? entry : ({})
  }

  function workspaceIds() {
    var ids = []
    if (Array.isArray(root.persistent)) {
      for (var p = 0; p < root.persistent.length; p++) ids.push(Number(root.persistent[p]))
    } else {
      ids = [1, 2, 3, 4, 5]
      for (var key in root.names) {
        var configured = Number(key)
        if (configured > 0 && ids.indexOf(configured) === -1) ids.push(configured)
      }
    }

    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function label(id) {
    var entry = entryFor(id)
    var number = id === 10 ? "0" : String(id)
    var template = root.vertical ? root.verticalFormat : root.format
    var text = template
      .replace("{number}", number)
      .replace("{name}", entry.name ? String(entry.name) : "")
      .replace("{icon}", entry.icon ? String(entry.icon) : "")
      .replace(/\s+/g, " ")
      .trim()
    return text !== "" ? text : number
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  // ---- Editor. Double-click is detected here rather than with a
  //      MouseArea doubleClicked handler because WidgetButton owns the
  //      MouseArea; the first click still switches workspace as usual.
  property int lastClickId: 0
  property double lastClickAt: 0
  property Item editAnchor: null
  property bool editorOpen: false

  function handlePress(id, button, item) {
    if (button === Qt.RightButton) { openEditor(id, item); return }
    if (button !== Qt.LeftButton) return

    var now = Date.now()
    var isDouble = id === lastClickId && now - lastClickAt < Qt.styleHints.mouseDoubleClickInterval
    lastClickId = isDouble ? 0 : id
    lastClickAt = isDouble ? 0 : now
    if (isDouble) openEditor(id, item)
    else root.focusWorkspace(id)
  }

  function openEditor(id, item) {
    var entry = entryFor(id)
    editAnchor = item
    editorLoader.active = true
    editorOpen = true
    editorLoader.item.edit(id, entry.name ? String(entry.name) : "", entry.icon ? String(entry.icon) : "")
  }

  function close() {
    editorOpen = false
  }

  function saveWorkspace(id, name, icon) {
    var entry = { id: root.moduleName }
    for (var key in root.settings) if (key !== "id") entry[key] = root.settings[key]

    var workspaces = ({})
    var current = root.names || ({})
    for (var ws in current) workspaces[ws] = current[ws]
    if (name === "" && icon === "") delete workspaces[String(id)]
    else workspaces[String(id)] = { name: name, icon: icon }
    entry.workspaces = workspaces

    // Applied locally first so the bar updates on Save; the shell.json
    // write comes back through the host as the same value.
    root.settings = entry
    if (root.bar && root.bar.shell && typeof root.bar.shell.updateEntryInline === "function")
      root.bar.shell.updateEntryInline(root.moduleName, entry)
    close()
  }

  // IPC: `omarchy-shell io.github.jburchel.workspace-nameplates edit [id]`
  // opens the editor on the focused monitor (id 0 = current workspace), so
  // it can also be bound to a key.
  function screenName() {
    var window = root.QsWindow.window
    return window && window.screen ? window.screen.name : ""
  }

  function buttonFor(id) {
    for (var i = 0; i < repeater.count; i++) {
      var item = repeater.itemAt(i)
      if (item && item.modelData === id) return item
    }
    return root
  }

  function editFromIpc(id) {
    var target = id > 0 ? id : (Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1)
    var monitor = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    var items = root.bar && typeof root.bar.moduleWidgets === "function" ? root.bar.moduleWidgets(root.moduleName) : [root]
    var chosen = root
    for (var i = 0; i < items.length; i++) {
      if (items[i] && items[i].screenName && items[i].screenName() === monitor) chosen = items[i]
    }
    chosen.openEditor(target, chosen.buttonFor(target))
  }

  IpcHandler {
    target: "io.github.jburchel.workspace-nameplates"

    function edit(id: int): void { root.editFromIpc(id) }
    function close(): void { root.broadcast("close") }
  }

  // Popout owner. Deliberately not `root`: the bar paints its open-panel
  // mark under whichever slot owns the popout, centred on the whole widget,
  // which lands between workspaces rather than under the one being edited.
  QtObject {
    id: editorOwner
    function close() { root.close() }
  }

  Loader {
    id: editorLoader
    active: false
    sourceComponent: Editor {
      anchorItem: root.editAnchor || root
      bar: root.bar
      owner: editorOwner
      open: root.editorOpen
      onSaveRequested: function(id, name, icon) { root.saveWorkspace(id, name, icon) }
      onCancelRequested: root.close()
    }
  }

  function cycle(delta) {
    var ids = root.workspaceIds()
    var current = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : ids[0]
    var index = ids.indexOf(current)
    var next = ids[(index + (delta < 0 ? 1 : -1) + ids.length) % ids.length]
    if (next !== undefined) root.focusWorkspace(next)
  }

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      id: repeater
      model: root.workspaceIds()

      WidgetButton {
        id: button
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        bar: root.bar
        text: root.label(modelData)
        tooltipText: root.entryFor(modelData).name ? "Workspace " + modelData + " — " + root.entryFor(modelData).name : ""
        foreground: focused ? Color.accent : (root.bar ? root.bar.barForeground : Color.foreground)
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : -1
        fixedHeight: root.barSize
        onPressed: function(b) { root.handlePress(modelData, b, button) }
        onWheelMoved: function(delta) { root.cycle(delta) }

        // Focus marker: a short accent bar under the active workspace,
        // since the number stays visible instead of turning into a glyph.
        Rectangle {
          visible: button.focused && !root.vertical
          anchors.bottom: parent.bottom
          anchors.bottomMargin: Style.space(3)
          anchors.horizontalCenter: parent.horizontalCenter
          width: button.labelWidth
          height: Math.max(2, Style.space(2))
          radius: height / 2
          color: Color.accent
        }
      }
    }
  }
}
