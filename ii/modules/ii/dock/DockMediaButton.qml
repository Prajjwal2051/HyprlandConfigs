import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland

Item {
    id: root

    // Layout props so it fits naturally in the dock RowLayout
    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut

    // ── Media state ────────────────────────────────────────────────────────────
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasMedia: activePlayer !== null

    property string artUrl: activePlayer?.trackArtUrl ?? ""
    property string artFileName: artUrl.length > 0 ? Qt.md5(artUrl) : ""
    property string artFilePath: artFileName.length > 0
        ? `${Directories.coverArt}/${artFileName}` : ""
    property bool artDownloaded: false
    property string displayedArtFilePath: artDownloaded && artFilePath.length > 0
        ? Qt.resolvedUrl(artFilePath) : ""

    property bool popupOpen: false
    property color artDominantColor: ColorUtils.mix(
        colorQuantizer.colors[0] ?? Appearance.colors.colPrimary,
        Appearance.colors.colPrimaryContainer, 0.8)

    property QtObject blendedColors: AdaptedMaterialScheme {
        color: root.artDominantColor
    }

    readonly property real _topInset:    Appearance.sizes.hyprlandGapsOut + 5
    readonly property real _bottomInset: Appearance.sizes.hyprlandGapsOut + 5
    // Expands to pill on hover to show track info, collapses to square otherwise
    implicitWidth: hasMedia ? 210 : 0
    visible: hasMedia

    Behavior on implicitWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    // ── Art download ───────────────────────────────────────────────────────────
    onArtFilePathChanged: {
        if (artUrl.length === 0) {
            artDownloaded = false
            return
        }
        artDownloaded = false
        artDownloader.running = true
    }

    Process {
        id: artDownloader
        command: ["bash", "-c",
            `[ -f ${root.artFilePath} ] || curl -sSL '${root.artUrl}' -o '${root.artFilePath}'`]
        onExited: root.artDownloaded = true
    }

    ColorQuantizer {
        id: colorQuantizer
        source: root.displayedArtFilePath
        depth: 0
        rescaleSize: 1
    }

    // Keep position updated while playing
    Timer {
        running: root.activePlayer?.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: root.activePlayer?.positionChanged()
    }

    // ── Dock button (expands to pill on hover) ────────────────────────────────
    RippleButton {
        id: dockBtn
        anchors.fill: parent
        topInset:    root._topInset
        bottomInset: root._bottomInset
        background.implicitHeight: 50
        buttonRadius: Appearance.rounding.normal
        onClicked: root.popupOpen = !root.popupOpen

        colBackground:      "#e0111116"
        colBackgroundHover: "#f0111116"
        colRipple:          "#44ffffff"

        contentItem: RowLayout {
            anchors {
                fill: parent
                leftMargin:  7
                rightMargin: 7
            }
            spacing: 7

            // Album art thumbnail
            Rectangle {
                id: artThumb
                Layout.alignment: Qt.AlignVCenter
                width:  36
                height: 36
                radius: Appearance.rounding.small
                color:  "#44ffffff"
                clip:   true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width:  artThumb.width
                        height: artThumb.height
                        radius: artThumb.radius
                    }
                }

                Image {
                    anchors.fill: parent
                    source: root.displayedArtFilePath
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: root.displayedArtFilePath.length > 0
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: root.displayedArtFilePath.length === 0
                    text: "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: "white"
                }
            }

            // Track info
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1
                clip: true

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight:    Font.DemiBold
                    color:  "white"
                    elide:  Text.ElideRight
                    text:   StringUtils.cleanMusicTitle(root.activePlayer?.trackTitle) ?? ""
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    color:  "#ccffffff"
                    elide:  Text.ElideRight
                    text:   root.activePlayer?.trackArtist ?? ""
                }
            }

            // Now-playing indicator
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: root.activePlayer?.isPlaying ? "graphic_eq" : "music_note"
                iconSize: Appearance.font.pixelSize.normal
                color: "white"
            }
        }
    }

    // ── Popup ──────────────────────────────────────────────────────────────────
    PopupWindow {
        id: mediaPopup
        visible: cardBg.visible
        color: "transparent"

        implicitWidth:  root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + Appearance.sizes.elevationMargin * 2

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges:   Edges.Top | Edges.Left
        }

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth:  cardBg.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: cardBg.implicitHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: root.popupOpen = false

            x: {
                const w = root.QsWindow.window?.width ?? 1
                const itemCenter = root.QsWindow?.mapFromItem(root, root.width / 2, 0)
                const cx = itemCenter?.x ?? (w / 2)
                return Math.max(0, Math.min(cx - width / 2, w - width))
            }

            StyledRectangularShadow {
                target: cardBg
                opacity: cardBg.opacity
                visible: opacity > 0
            }

            Item {
                id: popupCard
                anchors.fill: parent

                Rectangle {
                    id: cardBg
                    anchors {
                        fill: parent
                        margins: Appearance.sizes.elevationMargin
                    }
                    opacity: root.popupOpen && root.hasMedia ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    radius: Appearance.rounding.large
                    color: "#e0111116"
                    implicitWidth: 420
                    implicitHeight: cardContent.implicitHeight + 20 * 2
                    clip: true

                    // Blurred art background
                    Image {
                        anchors.fill: parent
                        source: root.displayedArtFilePath
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        asynchronous: true
                        opacity: 0.25

                        layer.enabled: true
                        layer.effect: StyledBlurEffect {
                            source: parent
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "#55000000"
                        radius: cardBg.radius
                    }

                    ColumnLayout {
                        id: cardContent
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 20
                        }
                        spacing: 12

                        // ── Art + track info row ───────────────────────────────
                        RowLayout {
                            spacing: 14
                            Layout.fillWidth: true

                            Rectangle {
                                id: artBig
                                implicitWidth: 90
                                implicitHeight: 90
                                radius: Appearance.rounding.verysmall
                                color: "#44ffffff"
                                clip: true

                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Rectangle {
                                        width: artBig.width
                                        height: artBig.height
                                        radius: artBig.radius
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    source: root.displayedArtFilePath
                                    fillMode: Image.PreserveAspectCrop
                                    cache: false
                                    asynchronous: true
                                }

                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: root.displayedArtFilePath.length === 0
                                    text: "music_note"
                                    iconSize: Appearance.font.pixelSize.huge
                                    color: "white"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 4

                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    font.weight: Font.Bold
                                    color: "white"
                                    elide: Text.ElideRight
                                    text: StringUtils.cleanMusicTitle(root.activePlayer?.trackTitle) ?? "Untitled"
                                    animateChange: true
                                    animationDistanceX: 6
                                    animationDistanceY: 0
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: "#ccffffff"
                                    elide: Text.ElideRight
                                    text: root.activePlayer?.trackArtist ?? ""
                                    animateChange: true
                                    animationDistanceX: 6
                                    animationDistanceY: 0
                                }
                            }
                        }

                        // ── Progress row ───────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true

                                StyledText {
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: "#99ffffff"
                                    text: StringUtils.friendlyTimeForSeconds(root.activePlayer?.position ?? 0)
                                }
                                Item { Layout.fillWidth: true }
                                StyledText {
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: "#99ffffff"
                                    text: StringUtils.friendlyTimeForSeconds(root.activePlayer?.length ?? 0)
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: root.activePlayer?.canSeek ?? false
                                sourceComponent: StyledSlider {
                                    configuration: StyledSlider.Configuration.Wavy
                                    highlightColor: "white"
                                    trackColor: "#44ffffff"
                                    handleColor: "white"
                                    value: (root.activePlayer?.position ?? 0) / Math.max(root.activePlayer?.length ?? 1, 1)
                                    onMoved: {
                                        if (root.activePlayer)
                                            root.activePlayer.position = value * root.activePlayer.length
                                    }
                                }
                            }

                            Loader {
                                Layout.fillWidth: true
                                active: !(root.activePlayer?.canSeek ?? false)
                                sourceComponent: StyledProgressBar {
                                    wavy: root.activePlayer?.isPlaying
                                    highlightColor: "white"
                                    trackColor: "#44ffffff"
                                    value: (root.activePlayer?.position ?? 0) / Math.max(root.activePlayer?.length ?? 1, 1)
                                }
                            }
                        }

                        // ── Controls row ───────────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            // Shuffle
                            RippleButton {
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: 18
                                colBackground: "transparent"
                                colBackgroundHover: "#44ffffff"
                                colRipple: "#66ffffff"
                                onClicked: {
                                    if (root.activePlayer)
                                        root.activePlayer.shuffle = !(root.activePlayer.shuffle)
                                }
                                contentItem: MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.large
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: (root.activePlayer?.shuffle ?? false)
                                        ? root.blendedColors.colPrimary
                                        : "white"
                                    text: "shuffle"
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Previous
                            RippleButton {
                                implicitWidth: 40
                                implicitHeight: 40
                                buttonRadius: 20
                                colBackground: "#33ffffff"
                                colBackgroundHover: "#44ffffff"
                                colRipple: "#66ffffff"
                                onClicked: root.activePlayer?.previous()
                                contentItem: MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.huge
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "white"
                                    text: "skip_previous"
                                }
                            }

                            Item { implicitWidth: 8 }

                            // Play / Pause
                            RippleButton {
                                id: playPauseBtn
                                property real btnSize: 50
                                implicitWidth: btnSize
                                implicitHeight: btnSize
                                buttonRadius: root.activePlayer?.isPlaying
                                    ? Appearance.rounding.normal : btnSize / 2
                                colBackground: root.activePlayer?.isPlaying
                                    ? root.blendedColors.colPrimary
                                    : "#33ffffff"
                                colBackgroundHover: root.activePlayer?.isPlaying
                                    ? root.blendedColors.colPrimaryHover
                                    : "#44ffffff"
                                colRipple: root.activePlayer?.isPlaying
                                    ? root.blendedColors.colPrimaryActive
                                    : "#66ffffff"
                                onClicked: root.activePlayer?.togglePlaying()

                                contentItem: MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.huge
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: root.activePlayer?.isPlaying
                                        ? root.blendedColors.colOnPrimary
                                        : "white"
                                    text: root.activePlayer?.isPlaying ? "pause" : "play_arrow"

                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }
                                }
                            }

                            Item { implicitWidth: 8 }

                            // Next
                            RippleButton {
                                implicitWidth: 40
                                implicitHeight: 40
                                buttonRadius: 20
                                colBackground: "#33ffffff"
                                colBackgroundHover: "#44ffffff"
                                colRipple: "#66ffffff"
                                onClicked: root.activePlayer?.next()
                                contentItem: MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.huge
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "white"
                                    text: "skip_next"
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Loop / Repeat
                            RippleButton {
                                implicitWidth: 36
                                implicitHeight: 36
                                buttonRadius: 18
                                colBackground: "transparent"
                                colBackgroundHover: "#44ffffff"
                                colRipple: "#66ffffff"
                                onClicked: {
                                    if (!root.activePlayer) return
                                    root.activePlayer.loopState =
                                        root.activePlayer.loopState === MprisLoopState.None
                                            ? MprisLoopState.Track
                                            : MprisLoopState.None
                                }
                                contentItem: MaterialSymbol {
                                    iconSize: Appearance.font.pixelSize.large
                                    fill: 1
                                    horizontalAlignment: Text.AlignHCenter
                                    color: (root.activePlayer?.loopState !== MprisLoopState.None)
                                        ? root.blendedColors.colPrimary
                                        : "white"
                                    text: root.activePlayer?.loopState === MprisLoopState.Track
                                        ? "repeat_one" : "repeat"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
