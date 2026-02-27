import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    
    // Safe color properties with fallbacks
    readonly property color colText: Appearance.colors?.colText ?? "#ffffff"
    readonly property color colSubtext: Appearance.colors?.colSubtext ?? "#aaaaaa"
    readonly property color colLayer1: Appearance.colors?.colLayer1 ?? "#333333"
    readonly property color colLayer1Hover: Appearance.colors?.colLayer1Hover ?? "#444444"
    readonly property color colLayer2: Appearance.colors?.colLayer2 ?? "#222222"
    readonly property color colPrimary: Appearance.colors?.colPrimary ?? "#6750a4"
    readonly property color colOnPrimary: Appearance.colors?.colOnPrimary ?? "#ffffff"
    
    implicitHeight: 80
    radius: Appearance.rounding?.normal ?? 12
    color: root.colLayer2
    
    RowLayout{
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10
        
        // Thumbnail
        Rectangle {
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            radius: 6
            color: root.colLayer1
            
            Image {
                anchors.fill: parent
                source: YtMusicService.currentTrack?.thumbnail || ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: 60
                        height: 60
                        radius: 6
                    }
                }
            }
            
            MaterialSymbol {
                anchors.centerIn: parent
                visible: !YtMusicService.currentTrack?.thumbnail
                text: "music_note"
                iconSize: 32
                color: root.colSubtext
            }
        }
        
        // Track info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            StyledText {
                Layout.fillWidth: true
                text: YtMusicService.currentTrack?.title || "No track playing"
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: root.colText
                elide: Text.ElideRight
            }
            
            StyledText {
                Layout.fillWidth: true
                text: YtMusicService.currentTrack?.artist || ""
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.colSubtext
                elide: Text.ElideRight
            }
            
            // Playback controls
            RowLayout {
                Layout.fillWidth: true
                spacing: 4
                
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: "transparent"
                    colBackgroundHover: root.colLayer1Hover
                    onClicked: YtMusicService.previousTrack()
                    
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_previous"
                        iconSize: 20
                        color: root.colText
                    }
                }
                
                RippleButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: 16
                    colBackground: root.colPrimary
                    onClicked: {
                        if (YtMusicService.isPlaying) {
                            YtMusicService.isPlaying = false
                        } else {
                            YtMusicService.playQueue()
                        }
                    }
                    
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: YtMusicService.isPlaying ? "pause" : "play_arrow"
                        iconSize: 22
                        color: root.colOnPrimary
                    }
                }
                
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: "transparent"
                    colBackgroundHover: root.colLayer1Hover
                    onClicked: YtMusicService.nextTrack()
                    
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "skip_next"
                        iconSize: 20
                        color: root.colText
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: YtMusicService.shuffleMode ? root.colPrimary : "transparent"
                    colBackgroundHover: YtMusicService.shuffleMode ? root.colPrimary : root.colLayer1Hover
                    onClicked: YtMusicService.toggleShuffle()
                    
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "shuffle"
                        iconSize: 18
                        color: YtMusicService.shuffleMode ? root.colOnPrimary : root.colSubtext
                    }
                    
                    StyledToolTip { text: YtMusicService.shuffleMode ? Translation.tr("Shuffle On") : Translation.tr("Shuffle Off") }
                }
                
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: YtMusicService.repeatMode > 0 ? root.colPrimary : "transparent"
                    colBackgroundHover: YtMusicService.repeatMode > 0 ? root.colPrimary : root.colLayer1Hover
                    onClicked: YtMusicService.cycleRepeatMode()
                    
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: YtMusicService.repeatMode === 1 ? "repeat_one" : "repeat"
                        iconSize: 18
                        color: YtMusicService.repeatMode > 0 ? root.colOnPrimary : root.colSubtext
                    }
                    
                    StyledToolTip {
                        text: YtMusicService.repeatMode === 0 ? Translation.tr("Repeat Off")
                            : YtMusicService.repeatMode === 1 ? Translation.tr("Repeat One")
                            : Translation.tr("Repeat All")
                    }
                }
            }
        }
    }
}
