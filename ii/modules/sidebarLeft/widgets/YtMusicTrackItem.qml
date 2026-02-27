import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Rectangle {
    id: root
    
    required property var track
    property int trackIndex: -1
    property bool showIndex: false
    property bool showRemoveButton: false
    property bool showAddToQueue: true
    property bool showAddToPlaylist: false
    
    signal playRequested()
    signal removeRequested()
    signal addToPlaylistRequested()
    
    readonly property bool isLiked: YtMusicService.isLiked(track)
    
    implicitHeight: 56
    radius: Appearance.rounding.small
    color: "transparent"
    
    RippleButton {
        anchors.fill: parent
        buttonRadius: root.radius
        colBackground: "transparent"
        colBackgroundHover: Appearance.colors.colLayer1Hover
        onClicked: root.playRequested()
        
        contentItem: RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10
            
            // Index or thumbnail
            Item {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                
                Rectangle {
                    anchors.fill: parent
                    radius: 4
                    color: Appearance.colors.colLayer2
                    visible: root.track.thumbnail
                    
                    Image {
                        anchors.fill: parent
                        source: root.track.thumbnail || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: parent.width
                                height: parent.height
                                radius: 4
                            }
                        }
                    }
                }
                
                StyledText {
                    anchors.centerIn: parent
                    visible: root.showIndex && !root.track.thumbnail
                    text: (root.trackIndex + 1).toString()
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                }
                
                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: !root.showIndex && !root.track.thumbnail
                    text: "music_note"
                    iconSize: 24
                    color: Appearance.colors.colSubtext
                }
            }
            
            // Track info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                
                StyledText {
                    Layout.fillWidth: true
                    text: root.track.title || "Unknown"
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colText
                    elide: Text.ElideRight
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    StyledText {
                        Layout.fillWidth: true
                        text: root.track.artist || "Unknown Artist"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                    
                    StyledText {
                        visible: root.track.duration > 0
                        text: formatDuration(root.track.duration)
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }
            }
            
            // Like button
            RippleButton {
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                onClicked: YtMusicService.toggleLike(root.track)
                
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.isLiked ? "favorite" : "favorite_border"
                    iconSize: 18
                    color: root.isLiked ? Appearance.colors.colError : Appearance.colors.colSubtext
                }
                
                StyledToolTip { text: root.isLiked ? Translation.tr("Unlike") : Translation.tr("Like") }
            }
            
            // Add to queue
            RippleButton {
                visible: root.showAddToQueue
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: YtMusicService.addToQueue(root.track)
                
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "queue_music"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }
                
                StyledToolTip { text: Translation.tr("Add to queue") }
            }
            
            // Add to playlist
            RippleButton {
                visible: root.showAddToPlaylist
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: Appearance.colors.colLayer2Hover
                onClicked: root.addToPlaylistRequested()
                
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "playlist_add"
                    iconSize: 18
                    color: Appearance.colors.colSubtext
                }
                
                StyledToolTip { text: Translation.tr("Add to playlist") }
            }
            
            // Remove button
            RippleButton {
                visible: root.showRemoveButton
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.9)
                onClicked: root.removeRequested()
                
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 18
                    color: Appearance.colors.colError
                }
                
                StyledToolTip { text: Translation.tr("Remove") }
            }
        }
    }
    
    function formatDuration(secs) {
        const mins = Math.floor(secs / 60)
        const remainingSecs = Math.floor(secs % 60)
        return `${mins}:${remainingSecs.toString().padStart(2, '0')}`
    }
}
