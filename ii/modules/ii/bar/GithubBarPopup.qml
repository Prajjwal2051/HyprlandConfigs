import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // ── Data props (set by GithubBarButton) ─────────────────────────────
    // active is bound directly from GithubBarButton: active: root.popupOpen

    property string username: "Prajjwal2051"
    property var contributionMap: ({})
    property int totalCount: 0
    property bool loading: true
    property bool hasError: false
    property real animPhase: 0

    signal refreshRequested()

    // ── Visual config ────────────────────────────────────────────────────
    readonly property real cellSize: 9
    readonly property real cellGap: 2
    readonly property int weeksToShow: 26
    readonly property int daysPerWeek: 7

    readonly property color colorLow:  Qt.rgba(0.08, 0.35, 0.12, 0.7)
    readonly property color colorHigh: Qt.rgba(0.06, 0.80, 0.18, 1.0)

    // ── Grid computation ─────────────────────────────────────────────────
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
                Appearance.colors.colLayer2.b, 0.5)
        const intensity = Math.min(1.0, count / 12)
        return Qt.rgba(
            colorLow.r + (colorHigh.r - colorLow.r) * intensity,
            colorLow.g + (colorHigh.g - colorLow.g) * intensity,
            colorLow.b + (colorHigh.b - colorLow.b) * intensity,
            colorLow.a + (colorHigh.a - colorLow.a) * intensity
        )
    }

    // ── Popup content (default contentItem) ─────────────────────────────
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            CustomIcon {
                implicitWidth: Appearance.font.pixelSize.normal
                implicitHeight: Appearance.font.pixelSize.normal
                source: "github-symbolic"
                colorize: true
                color: Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                text: `@${root.username}`
                font {
                    weight: Font.Medium
                    pixelSize: Appearance.font.pixelSize.small
                }
                color: Appearance.colors.colOnSurfaceVariant
            }

            Item { Layout.fillWidth: true }

            StyledText {
                visible: !root.loading && !root.hasError
                text: `${root.totalCount} contributions`
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            StyledText {
                visible: root.loading
                text: "Loading…"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }

            StyledText {
                visible: root.hasError
                text: "Failed to fetch"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.m3colors.m3error
            }

            // Refresh button
            RippleButton {
                implicitWidth: 20
                implicitHeight: 20
                buttonRadius: height / 2
                colBackground: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.5)
                colBackgroundHover: Appearance.colors.colLayer2Hover
                colRipple: Appearance.colors.colLayer2Active
                onClicked: root.refreshRequested()

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "refresh"
                    iconSize: 12
                    color: Appearance.colors.colOnLayer2
                    RotationAnimation on rotation {
                        running: root.loading
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 900
                    }
                }

                StyledToolTip { text: "Refresh contributions" }
            }
        }

        // Contribution heatmap grid
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
                        ColorAnimation { duration: 300 }
                    }

                    property bool cellHovered: false
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.cellHovered = true
                        onExited: parent.cellHovered = false
                    }

                    StyledToolTip {
                        visible: parent.cellHovered && !root.loading && cell.count >= 0
                        text: `${cell.date}  ·  ${cell.count} contribution${cell.count !== 1 ? "s" : ""}`
                    }
                }
            }
        }
    }
}
