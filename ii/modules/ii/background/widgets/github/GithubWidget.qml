import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "github"
    visibleWhenLocked: false
    hoverEnabled: true

    property string username: Config.options.background.widgets.github.username || "Prajjwal2051"
    property bool dragLocked: false

    // Color themes: low/high color for interpolation
    readonly property var colorThemes: [
        { name: "Green",  low: Qt.rgba(0.08, 0.35, 0.12, 0.7), high: Qt.rgba(0.06, 0.80, 0.18, 1.0) },
        { name: "Blue",   low: Qt.rgba(0.08, 0.20, 0.55, 0.7), high: Qt.rgba(0.10, 0.55, 1.00, 1.0) },
        { name: "Purple", low: Qt.rgba(0.35, 0.12, 0.60, 0.7), high: Qt.rgba(0.75, 0.22, 1.00, 1.0) },
        { name: "Orange", low: Qt.rgba(0.55, 0.25, 0.05, 0.7), high: Qt.rgba(1.00, 0.60, 0.10, 1.0) },
        { name: "Pink",   low: Qt.rgba(0.55, 0.10, 0.30, 0.7), high: Qt.rgba(1.00, 0.28, 0.65, 1.0) },
    ]
    property int colorThemeIndex: 0
    readonly property var currentTheme: colorThemes[colorThemeIndex]

    draggable: root.placementStrategy === "free" && !root.dragLocked

    property var contributions: []
    property int totalCount: 0
    property bool loading: true
    property bool hasError: false
    property real cellSize: configEntry.cellSize ?? 11
    property real cellGap: 2.5
    readonly property int weeksToShow: 53
    readonly property int daysPerWeek: 7
    property real animPhase: 0

    implicitWidth: weeksToShow * (cellSize + cellGap) + cellGap + 18
    implicitHeight: daysPerWeek * (cellSize + cellGap) + cellGap + 58

    Timer {
        id: loadingAnim
        running: root.visible && root.loading
        interval: 90
        repeat: true
        onTriggered: root.animPhase += 0.14
    }

    function fetchContributions() {
        loading = true
        hasError = false
        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText)
                    var list = data.contributions || []
                    var map = {}
                    var sum = 0
                    for (var i = 0; i < list.length; i++) {
                        map[list[i].date] = list[i].count
                        sum += list[i].count
                    }
                    root.contributionMap = map
                    root.contributions = list
                    root.totalCount = sum
                    root.loading = false
                } catch (e) {
                    root.hasError = true
                    root.loading = false
                }
            } else {
                root.hasError = true
                root.loading = false
            }
        }
        xhr.open("GET", `https://github-contributions-api.jogruber.de/v4/${username}?y=last`)
        xhr.send()
    }

    property var contributionMap: ({})
    Component.onCompleted: fetchContributions()
    onUsernameChanged: fetchContributions()

    Timer {
        interval: 900000 // 15 minutes
        running: root.visible
        repeat: true
        onTriggered: root.fetchContributions()
    }

    property var gridCells: {
        var cells = []
        var today = new Date()
        var startDate = new Date(today)
        var dow = today.getDay()
        startDate.setDate(today.getDate() - dow - (weeksToShow - 1) * 7)

        for (var w = 0; w < weeksToShow; w++) {
            for (var d = 0; d < daysPerWeek; d++) {
                var cellDate = new Date(startDate)
                cellDate.setDate(startDate.getDate() + w * 7 + d)
                var dateStr = cellDate.toISOString().split('T')[0]
                var isFuture = cellDate > today
                cells.push({
                    week: w,
                    day: d,
                    count: isFuture ? -1 : (contributionMap[dateStr] ?? 0),
                    date: dateStr,
                    isFuture: isFuture
                })
            }
        }
        return cells
    }

    function levelColor(count, isFuture) {
        if (isFuture || count < 0)
            return "transparent"
        if (count === 0)
            return Qt.rgba(
                Appearance.colors.colLayer2.r,
                Appearance.colors.colLayer2.g,
                Appearance.colors.colLayer2.b, 0.55)
        const intensity = Math.min(1.0, count / 12)
        const lo = currentTheme.low
        const hi = currentTheme.high
        return Qt.rgba(
            lo.r + (hi.r - lo.r) * intensity,
            lo.g + (hi.g - lo.g) * intensity,
            lo.b + (hi.b - lo.b) * intensity,
            lo.a + (hi.a - lo.a) * intensity
        )
    }

    component IconBtn: RippleButton {
        implicitWidth: 24
        implicitHeight: 24
        buttonRadius: height / 2
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.4)
        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer3Hover, 0.3)
        colRipple: Appearance.colors.colLayer3Active
    }

    Column {
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 5

        // ── Header ──────────────────────────────────────────────────────
        Item {
            width: parent.width
            height: 24

            // Left: code icon + @username + lock button
            Row {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                spacing: 4

                MaterialSymbol {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "code"
                    iconSize: 15
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.8
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: `@${root.username}`
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                }

                IconBtn {
                    visible: root.containsMouse
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.fetchContributions()
                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 14
                            color: Appearance.colors.colOnLayer2
                            RotationAnimation on rotation {
                                running: root.loading
                                loops: Animation.Infinite
                                from: 0; to: 360
                                duration: 900
                            }
                        }
                    }
                    StyledToolTip { text: "Refresh contributions" }
                }

                IconBtn {
                    visible: root.containsMouse
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.dragLocked = !root.dragLocked
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.dragLocked ? "lock" : "lock_open"
                        iconSize: 14
                        color: root.dragLocked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                    }
                    StyledToolTip { text: root.dragLocked ? "Unlock position" : "Lock position" }
                }
            }

            // Right: color swatches (on hover) + contribution count
            Row {
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                spacing: 5

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    visible: root.containsMouse

                    Repeater {
                        model: root.colorThemes.length
                        delegate: Rectangle {
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: 11
                            height: 11
                            radius: 3
                            color: root.colorThemes[index].high
                            border.color: root.colorThemeIndex === index
                                ? Appearance.colors.colOnLayer1
                                : "transparent"
                            border.width: 1.5
                            scale: root.colorThemeIndex === index ? 1.3 : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: 120 }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.colorThemeIndex = index
                            }
                        }
                    }
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.loading && !root.hasError
                    text: `${root.totalCount} contributions`
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.hasError
                    text: "Failed to fetch"
                    color: Appearance.colors.colError
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }

        // ── Heatmap grid ────────────────────────────────────────────────
        Grid {
            id: heatmap
            rows: root.daysPerWeek
            columns: root.weeksToShow
            rowSpacing: root.cellGap
            columnSpacing: root.cellGap
            flow: Grid.TopToBottom

            Repeater {
                model: root.gridCells.length
                delegate: Rectangle {
                    required property int index
                    property var cell: root.gridCells[index]
                    width: root.cellSize
                    height: root.cellSize
                    radius: 2

                    color: root.loading
                        ? Qt.rgba(
                            Appearance.colors.colLayer2.r,
                            Appearance.colors.colLayer2.g,
                            Appearance.colors.colLayer2.b,
                            0.12 + 0.22 * Math.abs(Math.sin(root.animPhase + index * 0.07)))
                        : root.levelColor(cell.count, cell.isFuture)

                    Behavior on color {
                        ColorAnimation { duration: 350 }
                    }

                    property bool hovered: false
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: parent.hovered = true
                        onExited: parent.hovered = false
                        onClicked: mouse => mouse.accepted = false
                    }

                    StyledToolTip {
                        visible: parent.hovered && !root.loading && cell.count >= 0
                        text: `${cell.date}  ·  ${cell.count} contribution${cell.count !== 1 ? "s" : ""}`
                    }
                }
            }
        }
    }

    // ── Resize handle (bottom-right corner) ─────────────────────────────
    Item {
        id: resizeHandle
        width: 18; height: 18
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        opacity: root.containsMouse ? 1 : 0
        z: 100
        Behavior on opacity {
            NumberAnimation {
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Easing.OutCubic
            }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "drag_handle"
            iconSize: 14
            color: Appearance.colors.colSubtext
            rotation: -45
        }

        property real dragStartX: 0
        property real dragStartCellSize: root.cellSize

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: mouse => {
                resizeHandle.dragStartX = mouse.x
                resizeHandle.dragStartCellSize = root.cellSize
            }
            onPositionChanged: mouse => {
                if (!pressed) return
                const delta = (mouse.x - resizeHandle.dragStartX) * 0.05
                const newSize = Math.max(6, Math.min(22, resizeHandle.dragStartCellSize + delta))
                root.cellSize = newSize
                root.configEntry.cellSize = newSize
            }
        }
    }
}
