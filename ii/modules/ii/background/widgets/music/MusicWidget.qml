import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "music"
    visibleWhenLocked: false
    hoverEnabled: true

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing
    readonly property real trackPosition: Math.max(activePlayer?.position ?? 0, 0)
    readonly property string titleText: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    readonly property string artistText: activePlayer?.trackArtist || Translation.tr("Unknown artist")
    readonly property string albumText: activePlayer?.trackAlbum || Translation.tr("Unknown album")
    readonly property string trackSignature: `${titleText}|${artistText}|${albumText}`

    property bool dragLocked: false
    property real animationPhase: 0
    property int designOffset: 0
    property bool blockStyleClick: false
    property int waveBars: 52
    readonly property int animationInterval: root.containsMouse ? 42 : 66
    readonly property int designSeed: hashString(trackSignature)
    readonly property int designMode: (designSeed + designOffset) % 8

    draggable: root.placementStrategy === "free" && !root.dragLocked

    function hashString(str) {
        let hash = 0;
        for (let i = 0; i < str.length; i++) {
            hash = ((hash << 5) - hash) + str.charCodeAt(i);
            hash |= 0;
        }
        return Math.abs(hash);
    }

    onClicked: mouse => {
        if (mouse.button !== Qt.LeftButton)
            return;
        if (blockStyleClick) {
            blockStyleClick = false;
            return;
        }
        designOffset = (designOffset + 1) % 8;
    }

    implicitWidth: 430
    implicitHeight: 230

    Timer {
        running: root.visible && (root.isPlaying || root.containsMouse)
        interval: root.animationInterval
        repeat: true
        onTriggered: {
            root.animationPhase += 0.2;
            if (root.isPlaying && root.activePlayer)
                root.activePlayer.positionChanged();
        }
    }

    Item {
        id: stage
        anchors {
            fill: parent
            margins: 12
        }

        readonly property real normalizedPulse: {
            const p1 = Math.abs(Math.sin(root.animationPhase * 0.95 + root.trackPosition * 0.014));
            const p2 = Math.abs(Math.sin(root.animationPhase * 1.57));
            return root.isPlaying ? Math.min(1, p1 * 0.7 + p2 * 0.3) : 0.12;
        }
        readonly property real baseRadius: Math.min(width, height) * 0.22

        Row {
            id: waveRow
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: stage.height * 0.08
                leftMargin: 6
                rightMargin: 6
            }
            height: stage.height * 0.62
            spacing: 2

            // Perspective tilt: rotate around bottom edge so bars lean back into the screen
            transform: Rotation {
                origin.x: waveRow.width / 2
                origin.y: waveRow.height
                axis.x: 1; axis.y: 0; axis.z: 0
                angle: 16
            }

            Repeater {
                model: root.waveBars
                delegate: Item {
                    id: barItem
                    required property int index

                    readonly property real relativeX: index / Math.max(root.waveBars - 1, 1)
                    readonly property real centerDistance: Math.abs(relativeX - 0.5) * 2
                    readonly property real envelopeBase: Math.max(0, 1 - centerDistance)
                    readonly property real envelope: {
                        // 0: soft center bell
                        if (root.designMode === 0) return Math.pow(envelopeBase, 0.75)
                        // 1: sharp narrow center spike
                        if (root.designMode === 1) return Math.pow(envelopeBase, 2.2)
                        // 2: very wide flat top
                        if (root.designMode === 2) return Math.pow(envelopeBase, 0.35)
                        // 3: double-hump (two peaks)
                        if (root.designMode === 3) {
                            const d2 = Math.abs(relativeX - 0.25) < Math.abs(relativeX - 0.75) ? Math.abs(relativeX - 0.25) : Math.abs(relativeX - 0.75)
                            return Math.pow(Math.max(0, 1 - d2 * 4), 1.2)
                        }
                        // 4: rising slope left-to-right
                        if (root.designMode === 4) return 0.15 + relativeX * 0.85
                        // 5: falling slope right-to-left
                        if (root.designMode === 5) return 0.15 + (1 - relativeX) * 0.85
                        // 6: staircase steps
                        if (root.designMode === 6) return 0.2 + Math.floor(relativeX * 5) / 5 * 0.8
                        // 7: uniform full height
                        return 1.0
                    }
                    readonly property real beatA: Math.abs(Math.sin(relativeX * (8  + root.designMode * 3.1) + root.animationPhase * 1.0  + root.trackPosition * 0.013))
                    readonly property real beatB: Math.abs(Math.sin(relativeX * (19 + root.designMode * 2.4) + root.animationPhase * 1.45 + root.trackPosition * 0.009))
                    readonly property real beatC: Math.abs(Math.sin(relativeX * (37 + root.designMode * 1.7) + root.animationPhase * 0.7))
                    readonly property real level: root.isPlaying
                        ? Math.min(1, (beatA * 0.45 + beatB * 0.35 + beatC * 0.20) * (0.08 + envelope * 0.92))
                        : 0.04 + envelope * 0.07

                    readonly property real barH: Math.max(4, waveRow.height * level)
                    // 3-D face dimensions
                    readonly property int sideW: 3
                    readonly property int topH: Math.max(2, barItem.barH * 0.06 + 2)
                    readonly property color frontCol: {
                        if (root.designMode === 1 || root.designMode === 5) return Appearance.colors.colSecondary
                        if (root.designMode === 6 || root.designMode === 7) return ColorUtils.mix(Appearance.colors.colPrimary, Appearance.colors.colSecondary, relativeX)
                        return Appearance.colors.colPrimary
                    }
                    readonly property color topCol: Qt.lighter(frontCol, 1.55)
                    readonly property color sideCol: Qt.darker(frontCol, 1.65)
                    readonly property real faceOpacity: root.isPlaying ? (0.30 + level * 0.65) : 0.18

                    width: Math.max(2, Math.floor((waveRow.width - waveRow.spacing * (root.waveBars - 1)) / root.waveBars))
                    height: waveRow.height

                    // ── Front face ──────────────────────────────────────────
                    Rectangle {
                        id: frontFace
                        width: barItem.width - barItem.sideW
                        height: barItem.barH
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        radius: (root.designMode === 3 || root.designMode === 6) ? 2 : width / 2
                        color: barItem.frontCol
                        opacity: barItem.faceOpacity
                    }

                    // ── Top cap (lighter — catches "light from above") ────────
                    Rectangle {
                        width: barItem.width - barItem.sideW
                        height: barItem.topH
                        anchors.bottom: frontFace.top
                        anchors.left: parent.left
                        color: barItem.topCol
                        opacity: barItem.faceOpacity
                        radius: (root.designMode === 3 || root.designMode === 6) ? 1 : 0
                    }

                    // ── Right side face (darker — shadow) ─────────────────────
                    Rectangle {
                        width: barItem.sideW
                        height: barItem.barH + barItem.topH
                        anchors.bottom: parent.bottom
                        anchors.left: frontFace.right
                        color: barItem.sideCol
                        opacity: barItem.faceOpacity * 0.72
                    }
                }
            }
        }

        // Ground-plane glow line at base of bars
        Rectangle {
            anchors {
                left: parent.left; right: parent.right
                leftMargin: 6; rightMargin: 6
            }
            y: stage.height - stage.height * 0.08 - 1
            height: 2
            opacity: root.isPlaying ? 0.28 : 0.08
            Behavior on opacity { NumberAnimation { duration: 400 } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0;  color: "transparent" }
                GradientStop { position: 0.3;  color: Appearance.colors.colPrimary }
                GradientStop { position: 0.7;  color: Appearance.colors.colSecondary }
                GradientStop { position: 1.0;  color: "transparent" }
            }
        }
    }

    Item {
        id: hoverLayer
        anchors.fill: parent
        z: 4

        RowLayout {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 10
            }
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 260
                spacing: 2
                opacity: root.containsMouse ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Easing.OutCubic
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.titleText
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnLayer1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.artistText
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.8
                }
            }

            RowLayout {
                spacing: 6
                opacity: root.containsMouse ? 1 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.elementMoveFast.duration
                        easing.type: Easing.OutCubic
                    }
                }

                component HoverButton: RippleButton {
                    implicitWidth: 30
                    implicitHeight: 30
                    buttonRadius: height / 2
                    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.35)
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer3Hover, 0.28)
                    colRipple: Appearance.colors.colLayer3Active
                    onPressed: _mouse => root.blockStyleClick = true
                }

                HoverButton {
                    onClicked: if (root.activePlayer) root.activePlayer.previous();
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: 18
                        color: Appearance.colors.colOnLayer2
                    }
                }

                HoverButton {
                    onClicked: if (root.activePlayer) root.activePlayer.togglePlaying();
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.isPlaying ? "pause" : "play_arrow"
                        iconSize: 18
                        color: Appearance.colors.colOnLayer2
                    }
                }

                HoverButton {
                    onClicked: if (root.activePlayer) root.activePlayer.next();
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        iconSize: 18
                        color: Appearance.colors.colOnLayer2
                    }
                }

                HoverButton {
                    onClicked: root.dragLocked = !root.dragLocked
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.dragLocked ? "lock" : "lock_open"
                        iconSize: 17
                        color: Appearance.colors.colOnLayer2
                    }
                }
            }
        }

    }
}
