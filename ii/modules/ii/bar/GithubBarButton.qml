import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root

    implicitWidth: ghRow.implicitWidth + 8 * 2
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: true
    property bool popupOpen: false

    onClicked: popupOpen = !popupOpen

    // ── Contribution data ─────────────────────────────────────────────
    property string username: Config.options.bar.github.username || "Prajjwal2051"
    property var contributionMap: ({})
    property var contributions: []
    property int totalCount: 0
    property bool loading: true
    property bool hasError: false
    property real animPhase: 0

    function fetchContributions() {
        root.loading = true
        root.hasError = false
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
        xhr.open("GET", `https://github-contributions-api.jogruber.de/v4/${root.username}?y=last`)
        xhr.send()
    }

    Component.onCompleted: fetchContributions()

    Timer {
        id: loadingAnim
        running: root.loading
        interval: 90
        repeat: true
        onTriggered: root.animPhase += 0.14
    }

    Timer {
        interval: (Config.options.bar.github.fetchInterval ?? 15) * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.fetchContributions()
    }

    // ── Visual ────────────────────────────────────────────────────────
    property color iconColor: popupOpen
        ? Appearance.m3colors.m3onSecondaryContainer
        : Appearance.colors.colOnLayer1

    Behavior on iconColor {
        ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
    }

    Rectangle {
        anchors.centerIn: parent
        width: height
        height: parent.height - 4
        radius: height / 2
        color: popupOpen
            ? Appearance.colors.colSecondaryContainer
            : (parent.containsMouse ? Appearance.colors.colLayer1Hover : "transparent")
        Behavior on color {
            ColorAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }
    }

    RowLayout {
        id: ghRow
        anchors.centerIn: parent
        spacing: 4

        CustomIcon {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: Appearance.font.pixelSize.larger
            implicitHeight: Appearance.font.pixelSize.larger
            source: "github-symbolic"
            colorize: true
            color: root.iconColor
        }
    }

    GithubBarPopup {
        id: githubPopup
        hoverTarget: root
        active: root.popupOpen
        username: root.username
        contributionMap: root.contributionMap
        totalCount: root.totalCount
        loading: root.loading
        hasError: root.hasError
        animPhase: root.animPhase
        onRefreshRequested: root.fetchContributions()
    }
}
