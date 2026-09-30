import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

// Name + icon editor for one workspace, opened by double-clicking it in the
// bar. Icons come from icons.tsv (Nerd Fonts glyph names) so they can be
// found by searching "terminal", "firefox", ... instead of pasting glyphs.
KeyboardPanel {
  id: panel

  property int workspaceId: 0
  property string initialName: ""
  property string initialIcon: ""
  property string selectedIcon: ""
  property string hoveredName: ""

  signal saveRequested(int workspaceId, string name, string icon)
  signal cancelRequested()

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property int columns: 10
  readonly property real cell: Style.space(34)
  readonly property int maxResults: 300

  // Shown before anything is typed: a starter set covering typical
  // workspace roles.
  readonly property var favorites: [
    "md-web", "md-firefox", "md-google_chrome", "md-code_braces", "md-console",
    "md-git", "md-github", "md-docker", "md-database", "md-api",
    "md-chat", "md-forum", "md-slack", "md-microsoft_teams", "md-email",
    "md-calendar", "md-video", "md-phone", "md-account_group", "md-briefcase",
    "md-folder", "md-file_document", "md-notebook", "md-note_text", "md-pencil",
    "md-music", "md-spotify", "md-play_circle", "md-youtube", "md-camera",
    "md-image", "md-palette", "md-draw", "md-gamepad_variant", "md-controller_classic",
    "md-book_open_variant", "md-school", "md-church", "md-earth", "md-map",
    "md-chart_line", "md-finance", "md-cart", "md-cog", "md-tools",
    "md-server", "md-cloud", "md-lock", "md-home", "md-star",
    "md-heart", "md-rocket_launch", "md-lightbulb", "md-coffee", "md-robot",
    "md-flask", "md-monitor", "md-laptop", "md-apps", "md-dots_horizontal"
  ]

  property var iconNames: []
  property var iconChars: ({})
  property var results: []

  function edit(id, name, icon) {
    workspaceId = id
    initialName = name
    initialIcon = icon
    selectedIcon = icon
    hoveredName = ""
    nameField.text = name
    searchField.text = ""
    refreshResults()
    Qt.callLater(function() { nameField.selectAll() })
  }

  function save() {
    panel.saveRequested(workspaceId, nameField.text.trim(), selectedIcon)
  }

  function parseIcons(text) {
    var names = []
    var chars = ({})
    var lines = text.split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i]
      if (line === "" || line.charAt(0) === "#") continue
      var tab = line.indexOf("\t")
      if (tab < 0) continue
      var name = line.substring(0, tab)
      names.push(name)
      chars[name] = String.fromCodePoint(parseInt(line.substring(tab + 1), 16))
    }
    iconNames = names
    iconChars = chars
    refreshResults()
  }

  function refreshResults() {
    var query = searchField.text.toLowerCase().trim()
    if (query === "") {
      results = favorites.filter(function(name) { return iconChars[name] !== undefined })
      return
    }

    var terms = query.split(/\s+/)
    var matches = []
    for (var i = 0; i < iconNames.length && matches.length < maxResults; i++) {
      var haystack = iconNames[i].replace(/[-_]/g, " ")
      var hit = true
      for (var t = 0; t < terms.length; t++) {
        if (haystack.indexOf(terms[t]) < 0) { hit = false; break }
      }
      if (hit) matches.push(iconNames[i])
    }
    // Material Design first: it is the most complete, consistent set.
    matches.sort(function(a, b) {
      var am = a.indexOf("md-") === 0 ? 0 : 1
      var bm = b.indexOf("md-") === 0 ? 0 : 1
      return am - bm
    })
    results = matches
  }

  focusTarget: nameField
  contentWidth: panel.fittedContentWidth(columns * cell + Style.space(4))
  contentHeight: panel.fittedContentHeight(column.implicitHeight)

  // Held in a property: the window's default property only takes Items.
  property FileView iconFile: FileView {
    path: Qt.resolvedUrl("icons.tsv").toString().replace("file://", "")
    onLoaded: panel.parseIcons(text())
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(10)

    Row {
      spacing: Style.space(10)

      Text {
        textFormat: Text.PlainText
        text: panel.selectedIcon !== "" ? panel.selectedIcon : String(panel.workspaceId === 10 ? 0 : panel.workspaceId)
        color: Color.accent
        font.family: panel.fontFamily
        font.pixelSize: Style.font.displayLarge
        anchors.verticalCenter: parent.verticalCenter
      }

      Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(2)

        Text {
          textFormat: Text.PlainText
          text: "Workspace " + (panel.workspaceId === 10 ? 0 : panel.workspaceId)
          color: panel.fg
          font.family: panel.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        Text {
          textFormat: Text.PlainText
          text: "Enter saves · Esc cancels"
          color: Qt.darker(panel.fg, 1.5)
          font.family: panel.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }

    TextField {
      id: nameField
      width: parent.width
      placeholderText: "Name (leave empty for number only)"
      foreground: panel.fg
      font.family: panel.fontFamily
      KeyNavigation.tab: searchField

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) { panel.cancelRequested(); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { panel.save(); event.accepted = true }
      }
    }

    TextField {
      id: searchField
      width: parent.width
      placeholderText: "Search icons: terminal, firefox, music…"
      foreground: panel.fg
      font.family: panel.fontFamily
      KeyNavigation.tab: nameField
      onTextChanged: searchDebounce.restart()

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) { panel.cancelRequested(); event.accepted = true }
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (panel.results.length > 0 && searchField.text !== "") panel.selectedIcon = panel.iconChars[panel.results[0]]
          panel.save()
          event.accepted = true
        }
      }
    }

    Timer {
      id: searchDebounce
      interval: 120
      onTriggered: panel.refreshResults()
    }

    GridView {
      id: grid
      width: parent.width
      height: panel.cell * 6
      cellWidth: panel.cell
      cellHeight: panel.cell
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      model: panel.results

      delegate: Rectangle {
        required property string modelData
        readonly property string glyph: panel.iconChars[modelData] || ""
        readonly property bool chosen: glyph !== "" && glyph === panel.selectedIcon

        width: panel.cell - Style.space(2)
        height: panel.cell - Style.space(2)
        radius: Style.cornerRadius
        color: chosen ? Style.selectedFillFor(panel.fg, Color.accent)
          : (cellMouse.containsMouse ? Style.hoverFillFor(panel.fg, Color.accent) : "transparent")
        border.width: chosen ? 1 : 0
        border.color: Color.accent

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: parent.glyph
          color: parent.chosen ? Color.accent : panel.fg
          font.family: panel.fontFamily
          font.pixelSize: Style.font.iconLarge
        }

        MouseArea {
          id: cellMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onEntered: panel.hoveredName = parent.modelData
          onExited: if (panel.hoveredName === parent.modelData) panel.hoveredName = ""
          onClicked: panel.selectedIcon = parent.glyph
          onDoubleClicked: { panel.selectedIcon = parent.glyph; panel.save() }
        }
      }

      Text {
        anchors.centerIn: parent
        visible: panel.results.length === 0
        textFormat: Text.PlainText
        text: panel.iconNames.length === 0 ? "Loading icons…" : "No icons match"
        color: Qt.darker(panel.fg, 1.5)
        font.family: panel.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
    }

    Text {
      width: parent.width
      textFormat: Text.PlainText
      elide: Text.ElideRight
      text: panel.hoveredName !== "" ? panel.hoveredName
        : (panel.results.length >= panel.maxResults ? "Showing first " + panel.maxResults + " matches — refine the search" : panel.results.length + " icons")
      color: Qt.darker(panel.fg, 1.5)
      font.family: panel.fontFamily
      font.pixelSize: Style.font.caption
    }

    Row {
      anchors.right: parent.right
      spacing: Style.space(6)

      Button {
        text: "No icon"
        foreground: panel.fg
        bordered: true
        onClicked: panel.selectedIcon = ""
      }

      Button {
        text: "Cancel"
        foreground: panel.fg
        bordered: true
        onClicked: panel.cancelRequested()
      }

      Button {
        text: "Save"
        foreground: panel.fg
        bordered: true
        active: true
        onClicked: panel.save()
      }
    }
  }
}
