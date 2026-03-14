pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    title: Translation.tr("Music")
    minimumWidth: 380
    minimumHeight: 180

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool hasTrack: (activePlayer?.trackTitle ?? "").length > 0
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media")
    readonly property string artistText: activePlayer?.trackArtist || Translation.tr("Unknown artist")
    readonly property string albumText: activePlayer?.trackAlbum || Translation.tr("Unknown album")
    readonly property real trackLength: Math.max(activePlayer?.length ?? 0, 0)
    readonly property real trackPosition: Math.max(activePlayer?.position ?? 0, 0)
    readonly property real progressValue: trackLength > 0 ? Math.min(1, trackPosition / trackLength) : 0
    readonly property real remainingTime: Math.max(trackLength - trackPosition, 0)
    readonly property string elapsedText: StringUtils.friendlyTimeForSeconds(trackPosition)
    readonly property string totalText: StringUtils.friendlyTimeForSeconds(trackLength)
    readonly property string remainingText: `-${StringUtils.friendlyTimeForSeconds(remainingTime)}`

    property int barCount: 44
    property real animationPhase: 0

    Timer {
        running: root.isPlaying || interactionArea.containsMouse
        interval: 42
        repeat: true
        onTriggered: {
            root.animationPhase += 0.22;
            if (root.isPlaying && root.activePlayer)
                root.activePlayer.positionChanged();
        }
    }

    contentItem: OverlayBackground {
        id: contentItem
        radius: root.contentRadius

        MouseArea {
            id: interactionArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
            onPressed: event => {
                if (!root.activePlayer)
                    return;
                if (event.button === Qt.MiddleButton) {
                    root.activePlayer.togglePlaying();
                } else if (event.button === Qt.BackButton) {
                    root.activePlayer.previous();
                } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                    root.activePlayer.next();
                } else if (event.button === Qt.LeftButton) {
                    GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
                }
            }
        }

        Rectangle {
            anchors {
                fill: parent
                margins: 10
            }
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2
            border.width: 1
            border.color: Appearance.colors.colOutlineVariant

            Item {
                id: visualizerCanvas
                anchors {
                    fill: parent
                    margins: 8
                }

                Row {
                    id: barsRow
                    anchors.fill: parent
                    spacing: 3

                    Repeater {
                        model: root.barCount

                        Rectangle {
                            required property int index

                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(2, Math.floor((barsRow.width - barsRow.spacing * (root.barCount - 1)) / root.barCount))
                            radius: width / 2

                            readonly property real relativeX: index / Math.max(root.barCount - 1, 1)
                            readonly property real baseWave: Math.abs(Math.sin((relativeX * 10.3) + root.animationPhase + root.trackPosition * 0.012))
                            readonly property real extraWave: Math.abs(Math.sin((relativeX * 23.8) + (root.animationPhase * 1.7)))
                            readonly property real centerBoost: 1 - Math.min(1, Math.abs(relativeX - 0.5) * 1.9)
                            readonly property real level: root.isPlaying
                                ? Math.min(1, ((baseWave * 0.65 + extraWave * 0.35) * (0.42 + centerBoost * 0.58)))
                                : 0.06

                            height: Math.max(8, visualizerCanvas.height * level)
                            color: root.isPlaying
                                ? Appearance.colors.colPrimary
                                : Appearance.colors.colSurfaceVariant
                            opacity: root.isPlaying ? (0.45 + level * 0.55) : 0.35
                        }
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 8
                }
                height: 4
                radius: 2
                color: Appearance.colors.colLayer3

                Rectangle {
                    width: parent.width * root.progressValue
                    height: parent.height
                    radius: parent.radius
                    color: Appearance.colors.colPrimary
                }
            }
        }

        Rectangle {
            anchors {
                fill: parent
                margins: 10
            }
            radius: Appearance.rounding.normal
            color: Appearance.colors.colLayer2Hover
            border.width: 1
            border.color: Appearance.colors.colPrimary
            opacity: interactionArea.containsMouse ? 0.95 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 12
                }
                spacing: 6

                StyledText {
                    Layout.fillWidth: true
                    text: root.cleanedTitle
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.artistText
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnSurfaceVariant
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.albumText
                    elide: Text.ElideRight
                    color: Appearance.colors.colSubtext
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: root.elapsedText
                        color: Appearance.colors.colOnLayer2
                        font.family: Appearance.font.family.numbers
                        font.variableAxes: Appearance.font.variableAxes.numbers
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        text: root.remainingText
                        color: Appearance.colors.colOnPrimaryContainer
                        font.family: Appearance.font.family.numbers
                        font.variableAxes: Appearance.font.variableAxes.numbers
                    }

                    StyledText {
                        text: `/ ${root.totalText}`
                        color: Appearance.colors.colSubtext
                        font.family: Appearance.font.family.numbers
                        font.variableAxes: Appearance.font.variableAxes.numbers
                    }
                }
            }
        }
    }
}