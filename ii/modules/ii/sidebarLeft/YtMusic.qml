pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Effects
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.common.models
import qs.services
import qs.modules.sidebarLeft.widgets

Item {
    id: root
    clip: true

    readonly property var ytMusic: YtMusicService
    readonly property bool isAvailable: ytMusic.available
    readonly property bool hasResults: ytMusic.searchResults.length > 0
    readonly property bool hasQueue: ytMusic.queue.length > 0
    readonly property bool isPlaying: ytMusic.isPlaying
    readonly property bool hasTrack: ytMusic.currentVideoId !== ""

    property string currentView: "search"

    function openAddToPlaylist(item) { 
        addToPlaylistPopup.targetItem = item
        addToPlaylistPopup.open() 
    }

    readonly property color colText: Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer0
    readonly property color colTextSecondary: Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
    readonly property color colPrimary: Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
    readonly property color colSurface: Appearance.inirEverywhere ? Appearance.inir.colLayer1 : Appearance.auroraEverywhere ? "transparent" : Appearance.colors.colLayer1
    readonly property color colSurfaceHover: Appearance.inirEverywhere ? Appearance.inir.colLayer1Hover : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer1Hover
    readonly property color colLayer2: Appearance.inirEverywhere ? Appearance.inir.colLayer2 : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface : Appearance.colors.colLayer2
    readonly property color colLayer2Hover: Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover : Appearance.colors.colLayer2Hover
    readonly property color colBorder: Appearance.inirEverywhere ? Appearance.inir.colBorder : "transparent"
    readonly property int borderWidth: Appearance.inirEverywhere ? 1 : 0
    readonly property real radiusSmall: Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
    readonly property real radiusNormal: Appearance.inirEverywhere ? Appearance.inir.roundingNormal : Appearance.rounding.normal

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: !root.isAvailable
            visible: active
            sourceComponent: ColumnLayout {
                spacing: 16
                Item { Layout.fillHeight: true }
                MaterialSymbol { 
                    Layout.alignment: Qt.AlignHCenter
                    text: "music_off"
                    iconSize: 56
                    color: root.colTextSecondary 
                }
                StyledText { 
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("yt-dlp not found")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: root.colText 
                }
                StyledText { 
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: 30
                    Layout.rightMargin: 30
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: Translation.tr("Install yt-dlp and mpv to use YT Music")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.colTextSecondary 
                }
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    
                    RippleButton {
                        implicitWidth: 120
                        implicitHeight: 40
                        buttonRadius: root.radiusNormal
                        colBackground: root.colLayer2
                        colBackgroundHover: root.colLayer2Hover
                        onClicked: ytMusic.checkAvailability()
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { 
                                text: "refresh"
                                iconSize: 18
                                color: root.colText 
                            }
                            StyledText { 
                                text: Translation.tr("Refresh")
                                color: root.colText
                                font.weight: Font.Medium 
                            }
                        }
                    }
                    
                    RippleButton {
                        implicitWidth: 140
                        implicitHeight: 40
                        buttonRadius: root.radiusNormal
                        colBackground: root.colPrimary
                        onClicked: Qt.openUrlExternally("https://github.com/yt-dlp/yt-dlp#installation")
                        contentItem: StyledText { 
                            anchors.centerIn: parent
                            text: Translation.tr("Install Guide")
                            color: Appearance.colors.colOnPrimary
                            font.weight: Font.Medium 
                        }
                    }
                }
                Item { Layout.fillHeight: true }
            }
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.isAvailable
            visible: active
            clip: true
            
            sourceComponent: ColumnLayout {
                spacing: 8
                clip: true

                YtMusicPlayerCard {
                    Layout.fillWidth: true
                    visible: root.hasTrack
                }

                Loader {
                    Layout.fillWidth: true
                    active: ytMusic.error !== ""
                    visible: active
                    sourceComponent: Rectangle {
                        implicitHeight: 36
                        radius: root.radiusSmall
                        color: Appearance.colors.colErrorContainer
                        RowLayout {
                            anchors.centerIn: parent
                            width: parent.width - 16
                            spacing: 8
                            MaterialSymbol { text: "error"; iconSize: 18; color: Appearance.colors.colOnErrorContainer }
                            StyledText { 
                                Layout.fillWidth: true
                                text: ytMusic.error
                                color: Appearance.colors.colOnErrorContainer
                                font.pixelSize: Appearance.font.pixelSize.small
                                elide: Text.ElideRight 
                            }
                            RippleButton { 
                                implicitWidth: 24
                                implicitHeight: 24
                                buttonRadius: 12
                                colBackground: "transparent"
                                onClicked: ytMusic.error = ""
                                contentItem: MaterialSymbol { 
                                    anchors.centerIn: parent
                                    text: "close"
                                    iconSize: 16
                                    color: Appearance.colors.colOnErrorContainer 
                                } 
                            }
                        }
                    }
                }

                // Connection Banner - shows when not connected
                ConnectionBanner {
                    Layout.fillWidth: true
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentHeight: mainLayout.height
                    flickableDirection: Flickable.VerticalFlick
                    ScrollBar.vertical: ScrollBar {}

                    ColumnLayout {
                        id: mainLayout
                        width: parent.width
                        spacing: 12

                        SearchView {}

                        StyledText {
                            text: Translation.tr("Library")
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Medium
                            color: root.colText
                            leftPadding: 8
                            visible: ytMusic.isLoggedIn
                        }
                        LibraryView {}

                        StyledText {
                            text: Translation.tr("Queue")
                            font.pixelSize: Appearance.font.pixelSize.large
                            font.weight: Font.Medium
                            color: root.colText
                            leftPadding: 8
                            visible: root.hasQueue
                        }
                        QueueView {}
                    }
                }
            }
        }
    }

    Popup {
        id: addToPlaylistPopup
        anchors.centerIn: parent
        width: 220
        height: Math.min(300, Math.max(120, ytMusic.playlists.length * 40 + 80))
        padding: 12
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        property var targetItem: null

        background: Rectangle { 
            color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                 : Appearance.auroraEverywhere ? Appearance.colors.colLayer1Base
                 : Appearance.colors.colLayer1
            radius: root.radiusNormal
            border.width: root.borderWidth
            border.color: root.colBorder 
        }
        
        contentItem: ColumnLayout {
            spacing: 8
            StyledText { 
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Add to Playlist")
                font.weight: Font.Medium
                color: root.colText 
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                reuseItems: true
                model: ytMusic.playlists
                spacing: 2
                delegate: RippleButton {
                    required property var modelData
                    required property int index
                    width: ListView.view.width
                    implicitHeight: 36
                    buttonRadius: root.radiusSmall
                    colBackground: "transparent"
                    colBackgroundHover: root.colLayer2Hover
                    onClicked: { 
                        if (addToPlaylistPopup.targetItem) { 
                            ytMusic.addToPlaylist(index, addToPlaylistPopup.targetItem)
                            addToPlaylistPopup.close() 
                        } 
                    }
                    contentItem: StyledText { 
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.name ?? ""
                        color: root.colText
                        elide: Text.ElideRight 
                    }
                }
            }
            
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 32
                buttonRadius: root.radiusSmall
                colBackground: root.colLayer2
                colBackgroundHover: root.colLayer2Hover
                onClicked: { 
                    addToPlaylistPopup.close()
                    createPlaylistPopup.open() 
                }
                contentItem: RowLayout { 
                    anchors.centerIn: parent
                    spacing: 4
                    MaterialSymbol { text: "add"; iconSize: 18; color: root.colPrimary }
                    StyledText { text: Translation.tr("New Playlist"); color: root.colPrimary } 
                }
            }
        }
    }

    Popup {
        id: createPlaylistPopup
        anchors.centerIn: parent
        width: 280
        height: 120
        modal: true
        dim: true
        background: Rectangle { 
            color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                 : Appearance.auroraEverywhere ? Appearance.colors.colLayer1Base
                 : Appearance.colors.colLayer1
            radius: root.radiusNormal
            border.width: root.borderWidth
            border.color: root.colBorder 
        }
        contentItem: ColumnLayout {
            spacing: 12
            StyledText { 
                text: Translation.tr("New Playlist")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: root.colText 
            }
            MaterialTextField {
                id: newPlaylistName
                Layout.fillWidth: true
                placeholderText: Translation.tr("Playlist name")
                onAccepted: createBtn.clicked()
            }
            RowLayout { 
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                RippleButton { 
                    id: createBtn
                    implicitWidth: 80
                    implicitHeight: 32
                    buttonRadius: root.radiusSmall
                    colBackground: root.colPrimary
                    onClicked: { 
                        if (newPlaylistName.text.trim()) { 
                            ytMusic.createPlaylist(newPlaylistName.text)
                            newPlaylistName.text = ""
                            createPlaylistPopup.close() 
                        } 
                    }
                    contentItem: StyledText { 
                        anchors.centerIn: parent
                        text: Translation.tr("Create")
                        color: Appearance.colors.colOnPrimary 
                    }
                }
            }
        }
    }

    // Save Queue as Playlist Popup
    Popup {
        id: saveQueuePopup
        anchors.centerIn: parent
        width: 280
        height: 120
        modal: true
        dim: true
        background: Rectangle {
            color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                 : Appearance.auroraEverywhere ? Appearance.colors.colLayer1Base
                 : Appearance.colors.colLayer1
            radius: root.radiusNormal
            border.width: root.borderWidth
            border.color: root.colBorder
        }
        contentItem: ColumnLayout {
            spacing: 12
            StyledText {
                text: Translation.tr("Save Queue as Playlist")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: root.colText
            }
            MaterialTextField {
                id: saveQueueName
                Layout.fillWidth: true
                placeholderText: Translation.tr("Playlist name")
                onAccepted: saveQueueBtn.clicked()
            }
            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                RippleButton {
                    id: saveQueueBtn
                    implicitWidth: 80
                    implicitHeight: 32
                    buttonRadius: root.radiusSmall
                    colBackground: root.colPrimary
                    onClicked: {
                        if (saveQueueName.text.trim() && ytMusic.queue.length > 0) {
                            ytMusic.createPlaylist(saveQueueName.text)
                            // Add all queue items to the new playlist
                            const newIdx = ytMusic.playlists.length - 1
                            for (let i = 0; i < ytMusic.queue.length; i++) {
                                ytMusic.addToPlaylist(newIdx, ytMusic.queue[i])
                            }
                            saveQueueName.text = ""
                            saveQueuePopup.close()
                        }
                    }
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Save")
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
        }
    }

    // Browser Selection Popup
    Popup {
        id: browserSelectPopup
        anchors.centerIn: parent
        width: 320
        height: Math.min(450, contentColumn.implicitHeight + 40)
        modal: true
        dim: true
        background: Rectangle {
            color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                 : Appearance.auroraEverywhere ? Appearance.colors.colLayer1Base
                 : Appearance.colors.colLayer1
            radius: root.radiusNormal
            border.width: root.borderWidth
            border.color: root.colBorder
        }
        contentItem: ColumnLayout {
            id: contentColumn
            spacing: 12
            
            StyledText {
                text: Translation.tr("Connect to YouTube Music")
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.Medium
                color: root.colText
            }
            
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("Choose a browser or use a custom cookies file:")
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.colTextSecondary
                wrapMode: Text.WordWrap
            }
            
            // Detected browsers
            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 200)
                clip: true
                spacing: 4
                model: ytMusic.detectedBrowsers
                visible: count > 0
                delegate: RippleButton {
                    required property string modelData
                    required property int index
                    width: ListView.view.width
                    implicitHeight: 44
                    buttonRadius: root.radiusSmall
                    colBackground: root.colLayer2
                    colBackgroundHover: root.colLayer2Hover
                    onClicked: {
                        browserSelectPopup.close()
                        ytMusic.connectGoogle(modelData)
                    }
                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10
                        StyledText {
                            text: ytMusic.browserInfo[modelData]?.icon ?? "🌐"
                            font.pixelSize: Appearance.font.pixelSize.larger
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: ytMusic.getBrowserDisplayName(modelData)
                            font.weight: Font.Medium
                            color: root.colText
                        }
                        MaterialSymbol {
                            text: "chevron_right"
                            iconSize: 20
                            color: root.colTextSecondary
                        }
                    }
                }
            }
            
            StyledText {
                Layout.fillWidth: true
                visible: ytMusic.detectedBrowsers.length === 0
                text: Translation.tr("No supported browsers detected")
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.colTextSecondary
                horizontalAlignment: Text.AlignHCenter
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.colBorder
                visible: Appearance.inirEverywhere ?? false
            }
            
            // Custom cookies file option
            StyledText {
                Layout.fillWidth: true
                text: Translation.tr("For Snap/Flatpak browsers:")
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.weight: Font.Medium
                color: root.colTextSecondary
            }
            
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 44
                buttonRadius: root.radiusSmall
                colBackground: root.colPrimary
                colBackgroundHover: root.colPrimary
                onClicked: {
                    browserSelectPopup.close()
                    cookiesFileDialog.open()
                }
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    MaterialSymbol {
                        text: "upload_file"
                        iconSize: 20
                        color: Appearance.colors.colOnPrimary
                    }
                    StyledText {
                        text: Translation.tr("Use Custom Cookies File")
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnPrimary
                    }
                }
            }
            
            RippleButton {
                Layout.fillWidth: true
                implicitHeight: 36
                buttonRadius: root.radiusSmall
                colBackground: root.colLayer2
                colBackgroundHover: root.colLayer2Hover
                onClicked: Qt.openUrlExternally("https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc")
                contentItem: RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    MaterialSymbol {
                        text: "extension"
                        iconSize: 18
                        color: root.colPrimary
                    }
                    StyledText {
                        text: Translation.tr("Get Cookies Extension")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: root.colText
                    }
                    MaterialSymbol {
                        text: "open_in_new"
                        iconSize: 14
                        color: root.colTextSecondary
                    }
                }
            }
        }
    }

    // File dialog for cookies file
    FileDialog {
        id: cookiesFileDialog
        title: "Select Cookies File"
        nameFilters: ["Text files (*.txt)", "All files (*)"]
        fileMode: FileDialog.OpenFile
        onAccepted: {
            // selectedFile is a URL, convert to path
            let path = selectedFile.toString().replace("file://", "")
            ytMusic.connectWithCookiesFile(path)
        }
    }


    component SearchView: ColumnLayout {
        spacing: 8
        Layout.fillWidth: true
        clip: true

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            radius: Appearance.inirEverywhere ? root.radiusSmall : Appearance.rounding.full
            color: root.colLayer2
            border.width: root.borderWidth
            border.color: root.colBorder
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 10
                spacing: 10
                
                MaterialSymbol { 
                    text: ytMusic.searching ? "hourglass_empty" : "search"
                    iconSize: 20
                    color: root.colTextSecondary
                    RotationAnimation on rotation { 
                        from: 0; to: 360; duration: 1000
                        loops: Animation.Infinite
                        running: ytMusic.searching 
                    }
                }
                
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Search YouTube Music...")
                    color: root.colText
                    placeholderTextColor: root.colTextSecondary
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.family: Appearance.font.family.main
                    background: Item {}
                    selectByMouse: true
                    onAccepted: { if (text.trim()) ytMusic.search(text) }
                    Keys.onEscapePressed: { text = ""; focus = false }
                }
                
                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    visible: searchField.text.length > 0
                    buttonRadius: 14
                    colBackground: "transparent"
                    colBackgroundHover: root.colLayer2Hover
                    onClicked: { searchField.text = ""; searchField.forceActiveFocus() }
                    contentItem: MaterialSymbol { 
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 18
                        color: root.colTextSecondary 
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            PagePlaceholder {
                anchors.fill: parent
                shown: !root.hasResults && !ytMusic.searching && ytMusic.recentSearches.length === 0
                icon: "library_music"
                title: Translation.tr("Search for music")
                description: Translation.tr("Find songs, artists, and albums")
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 6
                visible: !root.hasResults && !ytMusic.searching && ytMusic.recentSearches.length > 0
                
                RowLayout {
                    Layout.fillWidth: true
                    StyledText { 
                        text: Translation.tr("Recent")
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.Medium
                        color: root.colTextSecondary 
                    }
                    Item { Layout.fillWidth: true }
                    RippleButton { 
                        implicitWidth: 24
                        implicitHeight: 24
                        buttonRadius: 12
                        colBackground: "transparent"
                        colBackgroundHover: root.colLayer2Hover
                        onClicked: ytMusic.clearRecentSearches()
                        contentItem: MaterialSymbol { 
                            anchors.centerIn: parent
                            text: "delete_sweep"
                            iconSize: 16
                            color: root.colTextSecondary 
                        }
                        StyledToolTip { text: Translation.tr("Clear") }
                    }
                }
                
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    reuseItems: true
                    model: ytMusic.recentSearches
                    spacing: 2
                    delegate: RippleButton {
                        required property string modelData
                        width: ListView.view.width
                        implicitHeight: 36
                        buttonRadius: root.radiusSmall
                        colBackground: "transparent"
                        colBackgroundHover: root.colSurfaceHover
                        onClicked: { searchField.text = modelData; ytMusic.search(modelData) }
                        contentItem: RowLayout { 
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8
                            MaterialSymbol { text: "history"; iconSize: 18; color: root.colTextSecondary }
                            StyledText { Layout.fillWidth: true; text: modelData; color: root.colText; elide: Text.ElideRight }
                        }
                    }
                }
            }

            ListView {
                anchors.fill: parent
                visible: root.hasResults || ytMusic.searching
                clip: true
                reuseItems: true
                cacheBuffer: 200
                model: ytMusic.searchResults
                spacing: 4
                
                header: Column {
                    width: parent.width
                    spacing: 8
                    
                    // Artist header card - shows when artist info is available
                    Rectangle {
                        width: parent.width
                        height: ytMusic.currentArtistInfo ? 56 : 0
                        visible: ytMusic.currentArtistInfo !== null
                        radius: root.radiusSmall
                        color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                             : Appearance.auroraEverywhere ? Appearance.colors.colLayer1Base
                             : root.colLayer2
                        border.width: root.borderWidth
                        border.color: root.colBorder
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10
                            
                            // Artist avatar
                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                radius: 20
                                color: root.colSurfaceHover
                                
                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 1
                                    source: ytMusic.currentArtistInfo?.thumbnail ?? ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: source !== ""
                                    layer.enabled: true
                                    layer.effect: GE.OpacityMask {
                                        maskSource: Rectangle { width: 38; height: 38; radius: 19 }
                                    }
                                }
                                
                                MaterialSymbol {
                                    anchors.centerIn: parent
                                    visible: !ytMusic.currentArtistInfo?.thumbnail
                                    text: "person"
                                    iconSize: 24
                                    color: root.colTextSecondary
                                }
                            }
                            
                            // Artist name
                            StyledText {
                                Layout.fillWidth: true
                                text: ytMusic.currentArtistInfo?.name ?? ""
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: root.colText
                                elide: Text.ElideRight
                            }
                            
                            // Play all from this artist
                            RippleButton {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                buttonRadius: 16
                                colBackground: root.colPrimary
                                visible: root.hasResults
                                onClicked: {
                                    // Play first result
                                    if (ytMusic.searchResults.length > 0) {
                                        ytMusic.playFromSearch(0)
                                    }
                                }
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    text: "play_arrow"
                                    iconSize: 20
                                    fill: 1
                                    color: Appearance.colors.colOnPrimary
                                }
                                StyledToolTip { text: Translation.tr("Play") }
                            }
                        }
                    }
                    
                    // Searching indicator
                    Loader {
                        width: parent.width
                        active: ytMusic.searching
                        height: active ? 40 : 0
                        sourceComponent: RowLayout {
                            spacing: 8
                            Item { Layout.fillWidth: true }
                            MaterialLoadingIndicator { implicitSize: 24; loading: true }
                            StyledText { text: Translation.tr("Searching..."); color: root.colTextSecondary }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
                
                delegate: YtMusicTrackItem {
                    required property var modelData
                    required property int index
                    width: ListView.view?.width ?? 200
                    track: modelData
                    showAddToPlaylist: true
                    onPlayRequested: ytMusic.playFromSearch(index)
                    onAddToPlaylistRequested: root.openAddToPlaylist(modelData)
                }
            }
        }
    }

    component LibraryView: ColumnLayout {
        spacing: 8
        Layout.fillWidth: true
        visible: ytMusic.isLoggedIn
        clip: true

        property int expandedPlaylist: -1
        property bool showLiked: false

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            RippleButton {
                visible: expandedPlaylist >= 0 || showLiked
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: root.colLayer2Hover
                onClicked: { expandedPlaylist = -1; showLiked = false }
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "arrow_back"; iconSize: 20; color: root.colText }
            }
            
            StyledText { 
                text: showLiked ? Translation.tr("Liked Songs") 
                    : expandedPlaylist >= 0 ? (ytMusic.playlists[expandedPlaylist]?.name ?? "") 
                    : Translation.tr("Library")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: root.colText
            }
            
            Item { Layout.fillWidth: true }
            
            RippleButton {
                visible: (expandedPlaylist >= 0 && (ytMusic.playlists[expandedPlaylist]?.items?.length ?? 0) > 0) || (showLiked && ytMusic.likedSongs.length > 0)
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: root.colPrimary
                onClicked: showLiked ? _playLiked(false) : ytMusic.playPlaylist(expandedPlaylist, false)
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "play_arrow"; iconSize: 20; color: Appearance.colors.colOnPrimary }
                StyledToolTip { text: Translation.tr("Play all") }
            }
            
            RippleButton {
                visible: (expandedPlaylist >= 0 && (ytMusic.playlists[expandedPlaylist]?.items?.length ?? 0) > 1) || (showLiked && ytMusic.likedSongs.length > 1)
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: "transparent"
                colBackgroundHover: root.colLayer2Hover
                onClicked: showLiked ? _playLiked(true) : ytMusic.playPlaylist(expandedPlaylist, true)
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "shuffle"; iconSize: 20; color: root.colTextSecondary }
                StyledToolTip { text: Translation.tr("Shuffle") }
            }
            
            RippleButton {
                visible: expandedPlaylist < 0 && !showLiked
                implicitWidth: 32
                implicitHeight: 32
                buttonRadius: 16
                colBackground: root.colPrimary
                onClicked: createPlaylistPopup.open()
                contentItem: MaterialSymbol { anchors.centerIn: parent; text: "add"; iconSize: 20; color: Appearance.colors.colOnPrimary }
                StyledToolTip { text: Translation.tr("New playlist") }
            }
        }

        function _playLiked(shuffle) {
            let items = [...ytMusic.likedSongs]
            if (items.length === 0) return
            let startIndex = 0
            if (shuffle) { 
                for (let i = items.length - 1; i > 0; i--) { 
                    const j = Math.floor(Math.random() * (i + 1))
                    const temp = items[i]
                    items[i] = items[j]
                    items[j] = temp
                } 
            }
            ytMusic.playFromPlaylist(items, startIndex, "liked")
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: expandedPlaylist < 0 && !showLiked
            clip: true
            reuseItems: true
            spacing: 4
            model: ListModel {
                id: libraryModel
                Component.onCompleted: _rebuild()
                function _rebuild() {
                    clear()
                    // Liked Songs - heart icon
                    append({ type: "liked", name: Translation.tr("Liked Songs"), count: ytMusic.likedSongs.length, icon: "favorite", idx: -1, isCloud: false })
                    // Local playlists - playlist icon
                    for (let i = 0; i < ytMusic.playlists.length; i++) {
                        append({ type: "playlist", name: ytMusic.playlists[i].name, count: ytMusic.playlists[i].items?.length ?? 0, icon: "playlist_play", idx: i, isCloud: false })
                    }
                    // YouTube playlists (cloud) - with separator
                    if (ytMusic.googleConnected && ytMusic.ytMusicPlaylists.length > 0) {
                        append({ type: "separator", name: Translation.tr("YouTube Playlists"), count: 0, icon: "cloud_sync", idx: -1, isCloud: true })
                        for (let j = 0; j < ytMusic.ytMusicPlaylists.length; j++) {
                            const pl = ytMusic.ytMusicPlaylists[j]
                            append({ type: "cloud", name: pl.title, count: pl.count ?? 0, icon: "cloud_download", idx: j, isCloud: true, url: pl.url })
                        }
                    }
                }
            }
            Connections {
                target: YtMusic
                function onPlaylistsChanged() { libraryModel._rebuild() }
                function onLikedSongsChanged() { libraryModel._rebuild() }
                function onYtMusicPlaylistsChanged() { libraryModel._rebuild() }
                function onGoogleConnectedChanged() { libraryModel._rebuild() }
            }
            delegate: Item {
                required property var model
                required property int index
                width: ListView.view.width
                implicitHeight: model.type === "separator" ? 32 : 56

                // Separator for cloud playlists
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    visible: model.type === "separator"
                    spacing: 6

                    MaterialSymbol {
                        text: "cloud"
                        iconSize: 16
                        color: root.colTextSecondary
                    }
                    StyledText {
                        text: model.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: root.colTextSecondary
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: root.colBorder
                        visible: Appearance.inirEverywhere ?? false
                    }
                }

                // Regular playlist item
                RippleButton {
                    anchors.fill: parent
                    visible: model.type !== "separator"
                    buttonRadius: root.radiusSmall
                    colBackground: "transparent"
                    colBackgroundHover: root.colSurfaceHover
                    onClicked: {
                        if (model.type === "liked") {
                            showLiked = true
                        } else if (model.type === "cloud") {
                            // Import cloud playlist - get URL from ytMusicPlaylists array
                            const pl = ytMusic.ytMusicPlaylists[model.idx]
                            if (pl && pl.url) {
                                ytMusic.importYtMusicPlaylist(pl.url, pl.title)
                            }
                        } else {
                            expandedPlaylist = model.idx
                        }
                    }
                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: root.radiusSmall
                            color: root.colLayer2
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: model.icon
                                iconSize: 22
                                color: model.type === "liked" ? Appearance.colors.colError
                                     : model.isCloud ? root.colTextSecondary
                                     : root.colPrimary
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            StyledText {
                                Layout.fillWidth: true
                                text: model.name
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: Font.Medium
                                color: root.colText
                                elide: Text.ElideRight
                            }
                            StyledText {
                                text: model.isCloud ? Translation.tr("%1 tracks • Tap to import").arg(model.count)
                                    : Translation.tr("%1 songs").arg(model.count)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: root.colTextSecondary
                            }
                        }
                        MaterialSymbol {
                            text: model.isCloud ? "download" : "chevron_right"
                            iconSize: 20
                            color: root.colTextSecondary
                        }
                    }
                }
            }

            PagePlaceholder {
                anchors.fill: parent
                shown: ytMusic.playlists.length === 0 && ytMusic.likedSongs.length === 0
                icon: "playlist_add"
                title: Translation.tr("No playlists yet")
                description: Translation.tr("Create a playlist or sync your library")
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: expandedPlaylist >= 0
            clip: true
            reuseItems: true
            cacheBuffer: 200
            spacing: 4
            model: expandedPlaylist >= 0 ? (ytMusic.playlists[expandedPlaylist]?.items ?? []) : []
            delegate: YtMusicTrackItem {
                required property var modelData
                required property int index
                width: ListView.view?.width ?? 200
                track: modelData
                trackIndex: index
                showIndex: true
                showRemoveButton: true
                showAddToQueue: false
                onPlayRequested: ytMusic.playFromPlaylist(ytMusic.playlists[expandedPlaylist]?.items ?? [], index, "playlist:" + (ytMusic.playlists[expandedPlaylist]?.name ?? ""))
                onRemoveRequested: ytMusic.removeFromPlaylist(expandedPlaylist, index)
            }
            PagePlaceholder {
                anchors.fill: parent
                shown: expandedPlaylist >= 0 && (ytMusic.playlists[expandedPlaylist]?.items?.length ?? 0) === 0
                icon: "music_off"
                title: Translation.tr("Playlist is empty")
                description: Translation.tr("Add songs from search")
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: showLiked
            clip: true
            reuseItems: true
            cacheBuffer: 200
            spacing: 4
            model: ytMusic.likedSongs
            delegate: YtMusicTrackItem {
                required property var modelData
                required property int index
                width: ListView.view?.width ?? 200
                track: modelData
                showAddToPlaylist: true
                onPlayRequested: ytMusic.playFromLiked(index)
                onAddToPlaylistRequested: root.openAddToPlaylist(modelData)
            }
            PagePlaceholder {
                anchors.fill: parent
                shown: ytMusic.likedSongs.length === 0
                icon: "favorite"
                title: ytMusic.googleConnected ? Translation.tr("No liked songs") : Translation.tr("Sign in to see liked songs")
                description: ytMusic.googleConnected ? Translation.tr("Like songs on YouTube Music to see them here") : Translation.tr("Connect your account to sync your library")
            }
            RippleButton {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: parent.height * 0.25
                visible: ytMusic.googleConnected && ytMusic.likedSongs.length === 0
                implicitWidth: 120
                implicitHeight: 36
                buttonRadius: 18
                colBackground: root.colPrimary
                onClicked: ytMusic.fetchLikedSongs()
                contentItem: StyledText { anchors.centerIn: parent; text: Translation.tr("Sync Now"); color: Appearance.colors.colOnPrimary }
            }
        }

        RippleButton {
            Layout.fillWidth: true
            visible: expandedPlaylist >= 0
            implicitHeight: 36
            buttonRadius: root.radiusSmall
            colBackground: "transparent"
            colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.85)
            onClicked: { ytMusic.deletePlaylist(expandedPlaylist); expandedPlaylist = -1 }
            contentItem: RowLayout { 
                anchors.centerIn: parent
                spacing: 8
                MaterialSymbol { text: "delete"; iconSize: 18; color: Appearance.colors.colError }
                StyledText { text: Translation.tr("Delete playlist"); color: Appearance.colors.colError } 
            }
        }
    }


    component QueueView: ColumnLayout {
        spacing: 8
        Layout.fillWidth: true
        visible: root.hasQueue
        clip: true

        // Helper function to format duration
        function formatDuration(totalSecs) {
            const hours = Math.floor(totalSecs / 3600)
            const mins = Math.floor((totalSecs % 3600) / 60)
            const secs = Math.floor(totalSecs % 60)
            if (hours > 0) {
                return `${hours}:${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`
            }
            return `${mins}:${secs.toString().padStart(2, '0')}`
        }

        // Calculate total duration
        readonly property int totalDuration: {
            let total = 0
            for (let i = 0; i < ytMusic.queue.length; i++) {
                total += ytMusic.queue[i]?.duration || 0
            }
            return total
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                text: Translation.tr("Queue")
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: root.colText
            }
            StyledText {
                visible: root.hasQueue
                text: totalDuration > 0
                    ? `${ytMusic.queue.length} • ${formatDuration(totalDuration)}`
                    : `(${ytMusic.queue.length})`
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.colTextSecondary
            }
            Item { Layout.fillWidth: true }

            // Save as playlist button
            RippleButton {
                visible: ytMusic.queue.length > 0
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: 14
                colBackground: "transparent"
                colBackgroundHover: root.colLayer2Hover
                onClicked: saveQueuePopup.open()
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "playlist_add"
                    iconSize: 18
                    color: root.colTextSecondary
                }
                StyledToolTip { text: Translation.tr("Save as playlist") }
            }

            RippleButton { 
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: 14
                colBackground: ytMusic.shuffleMode ? root.colPrimary : "transparent"
                colBackgroundHover: ytMusic.shuffleMode ? root.colPrimary : root.colLayer2Hover
                onClicked: ytMusic.toggleShuffle()
                contentItem: MaterialSymbol { 
                    anchors.centerIn: parent
                    text: "shuffle"
                    iconSize: 18
                    color: ytMusic.shuffleMode ? Appearance.colors.colOnPrimary : root.colTextSecondary 
                }
                StyledToolTip { text: ytMusic.shuffleMode ? Translation.tr("Shuffle On") : Translation.tr("Shuffle Off") }
            }
            
            RippleButton { 
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: 14
                colBackground: ytMusic.repeatMode > 0 ? root.colPrimary : "transparent"
                colBackgroundHover: ytMusic.repeatMode > 0 ? root.colPrimary : root.colLayer2Hover
                onClicked: ytMusic.cycleRepeatMode()
                contentItem: MaterialSymbol { 
                    anchors.centerIn: parent
                    text: ytMusic.repeatMode === 1 ? "repeat_one" : "repeat"
                    iconSize: 18
                    color: ytMusic.repeatMode > 0 ? Appearance.colors.colOnPrimary : root.colTextSecondary 
                }
                StyledToolTip { 
                    text: ytMusic.repeatMode === 0 ? Translation.tr("Repeat Off") 
                        : ytMusic.repeatMode === 1 ? Translation.tr("Repeat One") 
                        : Translation.tr("Repeat All") 
                }
            }
            
            RippleButton { 
                visible: root.hasQueue
                implicitWidth: 80
                implicitHeight: 28
                buttonRadius: root.radiusSmall
                colBackground: root.colPrimary
                onClicked: ytMusic.playQueue()
                contentItem: StyledText { 
                    anchors.centerIn: parent
                    text: Translation.tr("Play")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnPrimary 
                }
            }
            
            RippleButton { 
                visible: root.hasQueue
                implicitWidth: 28
                implicitHeight: 28
                buttonRadius: 14
                colBackground: "transparent"
                colBackgroundHover: root.colLayer2Hover
                onClicked: ytMusic.clearQueue()
                contentItem: MaterialSymbol { 
                    anchors.centerIn: parent
                    text: "delete_sweep"
                    iconSize: 18
                    color: root.colTextSecondary 
                }
                StyledToolTip { text: Translation.tr("Clear") }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            reuseItems: true
            cacheBuffer: 200
            model: ytMusic.queue
            spacing: 4
            delegate: YtMusicTrackItem {
                required property var modelData
                required property int index
                width: ListView.view?.width ?? 200
                track: modelData
                trackIndex: index
                showIndex: true
                showRemoveButton: true
                showAddToQueue: false
                onPlayRequested: { 
                    ytMusic.queue = ytMusic.queue.slice(index)
                    ytMusic.playQueue() 
                }
                onRemoveRequested: ytMusic.removeFromQueue(index)
            }
            PagePlaceholder {
                anchors.fill: parent
                shown: !root.hasQueue
                icon: "queue_music"
                title: Translation.tr("Queue is empty")
                description: Translation.tr("Add songs from search or playlists")
            }
        }
    }

    // Connection Banner - compact inline banner for account sync
    component ConnectionBanner: Rectangle {
        id: banner
        clip: true

        readonly property bool dismissed: Config.options?.sidebar?.ytmusic?.hideSyncBanner ?? false
        readonly property bool shouldShow: !ytMusic.googleConnected && !dismissed
        readonly property bool hasError: ytMusic.googleError !== "" && !ytMusic.googleChecking

        visible: shouldShow || ytMusic.googleChecking
        implicitHeight: visible ? (hasError ? errorContent.implicitHeight + 24 : 52) : 0
        radius: root.radiusSmall
        color: hasError ? ColorUtils.transparentize(Appearance.colors.colError, 0.9)
             : ytMusic.googleChecking ? ColorUtils.transparentize(root.colPrimary, 0.9)
             : ColorUtils.transparentize(root.colPrimary, 0.92)
        border.width: root.borderWidth
        border.color: hasError ? ColorUtils.transparentize(Appearance.colors.colError, 0.7)
                    : ColorUtils.transparentize(root.colPrimary, 0.7)

        Behavior on implicitHeight {
            enabled: true
            NumberAnimation { duration: 150 }
        }

        // Normal state - not connected, not checking
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            visible: !banner.hasError && !ytMusic.googleChecking

            MaterialSymbol {
                text: "link"
                iconSize: 20
                color: root.colPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    text: Translation.tr("Sync your YouTube library")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: root.colText
                }
                StyledText {
                    text: Translation.tr("Access liked songs & playlists")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colTextSecondary
                }
            }

            RippleButton {
                implicitWidth: 80
                implicitHeight: 28
                buttonRadius: 14
                colBackground: root.colPrimary
                onClicked: browserSelectPopup.open()
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Connect")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnPrimary
                }
            }

            RippleButton {
                implicitWidth: 24
                implicitHeight: 24
                buttonRadius: 12
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.transparentize(root.colPrimary, 0.8)
                onClicked: Config.setNestedValue('sidebar.ytmusic.hideSyncBanner', true)
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 16
                    color: root.colTextSecondary
                }
                StyledToolTip { text: Translation.tr("Don't show again") }
            }
        }

        // Checking state
        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10
            visible: ytMusic.googleChecking

            MaterialLoadingIndicator {
                implicitSize: 20
                loading: visible
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText {
                    text: Translation.tr("Connecting...")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: root.colText
                }
                StyledText {
                    visible: ytMusic.googleBrowser
                    text: Translation.tr("Trying %1...").arg(ytMusic.getBrowserDisplayName(ytMusic.googleBrowser))
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colPrimary
                }
            }

            RippleButton {
                implicitWidth: 70
                implicitHeight: 28
                buttonRadius: 14
                colBackground: root.colLayer2
                onClicked: { ytMusic.googleChecking = false; ytMusic.googleError = "" }
                contentItem: StyledText {
                    anchors.centerIn: parent
                    text: Translation.tr("Cancel")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.colText
                }
            }
        }

        // Error state
        ColumnLayout {
            id: errorContent
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8
            visible: banner.hasError

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                MaterialSymbol { text: "error"; iconSize: 18; color: Appearance.colors.colError }
                StyledText {
                    Layout.fillWidth: true
                    text: ytMusic.googleError
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnErrorContainer
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                RippleButton {
                    implicitWidth: 70
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: Appearance.colors.colError
                    onClicked: browserSelectPopup.open()
                    contentItem: StyledText {
                        anchors.centerIn: parent
                        text: Translation.tr("Retry")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnError
                    }
                }

                RippleButton {
                    implicitWidth: 90
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: ColorUtils.transparentize(Appearance.colors.colError, 0.8)
                    onClicked: ytMusic.openYtMusicInBrowser()
                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol { text: "open_in_new"; iconSize: 14; color: Appearance.colors.colOnErrorContainer }
                        StyledText {
                            text: Translation.tr("Sign In")
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnErrorContainer
                        }
                    }
                }

                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.7)
                    onClicked: advancedOptionsPopup.open()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "settings"
                        iconSize: 16
                        color: Appearance.colors.colOnErrorContainer
                    }
                    StyledToolTip { text: Translation.tr("Advanced options") }
                }

                RippleButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: 14
                    colBackground: "transparent"
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.7)
                    onClicked: { ytMusic.googleError = "" }
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "close"
                        iconSize: 16
                        color: Appearance.colors.colOnErrorContainer
                    }
                }
            }
        }
    }

    // Advanced Options Popup
    Popup {
        id: advancedOptionsPopup
        anchors.centerIn: parent
        width: 300
        height: Math.min(400, advancedContent.implicitHeight + 40)
        padding: 16
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Appearance.inirEverywhere ? Appearance.inir.colLayer2
                 : Appearance.auroraEverywhere ? Appearance.colors.colLayer1Base
                 : Appearance.colors.colLayer1
            radius: root.radiusNormal
            border.width: root.borderWidth
            border.color: root.colBorder
        }

        contentItem: ColumnLayout {
            id: advancedContent
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                StyledText {
                    text: Translation.tr("Connection Options")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Bold
                    color: root.colText
                }
                Item { Layout.fillWidth: true }
                RippleButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    buttonRadius: 12
                    colBackground: "transparent"
                    colBackgroundHover: root.colLayer2Hover
                    onClicked: advancedOptionsPopup.close()
                    contentItem: MaterialSymbol { anchors.centerIn: parent; text: "close"; iconSize: 18; color: root.colTextSecondary }
                }
            }

            // Connected account section
            Rectangle {
                Layout.fillWidth: true
                visible: ytMusic.googleConnected
                implicitHeight: connectedContent.implicitHeight + 16
                radius: root.radiusSmall
                color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.92)
                border.width: root.borderWidth
                border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.7)

                ColumnLayout {
                    id: connectedContent
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: ColorUtils.transparentize(root.colPrimary, 0.85)

                            Image {
                                anchors.fill: parent
                                anchors.margins: 1
                                source: ytMusic.userAvatar || ""
                                visible: ytMusic.userAvatar !== ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                layer.enabled: true
                                layer.effect: GE.OpacityMask {
                                    maskSource: Rectangle { width: 30; height: 30; radius: 15 }
                                }
                            }

                            MaterialSymbol {
                                anchors.centerIn: parent
                                visible: !ytMusic.userAvatar
                                text: "account_circle"
                                iconSize: 20
                                color: root.colPrimary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                text: ytMusic.userName || Translation.tr("Connected")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.Medium
                                color: root.colText
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: ytMusic.googleBrowser
                                    ? Translation.tr("via %1").arg(ytMusic.getBrowserDisplayName(ytMusic.googleBrowser))
                                    : Translation.tr("Connected")
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: root.colTextSecondary
                            }
                        }
                    }

                    RippleButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        buttonRadius: root.radiusSmall
                        colBackground: ColorUtils.transparentize(Appearance.colors.colError, 0.9)
                        colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colError, 0.8)
                        onClicked: { ytMusic.disconnectGoogle(); advancedOptionsPopup.close() }
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { text: "logout"; iconSize: 16; color: Appearance.colors.colError }
                            StyledText { text: Translation.tr("Disconnect"); color: Appearance.colors.colError; font.pixelSize: Appearance.font.pixelSize.smaller }
                        }
                    }
                }
            }

            // Instructions (only when not connected)
            Rectangle {
                Layout.fillWidth: true
                visible: !ytMusic.googleConnected
                implicitHeight: infoColPopup.implicitHeight + 16
                radius: root.radiusSmall
                color: ColorUtils.transparentize(root.colPrimary, 0.95)
                border.width: root.borderWidth
                border.color: ColorUtils.transparentize(root.colPrimary, 0.8)

                ColumnLayout {
                    id: infoColPopup
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Log in to YouTube Music in your browser, then select it below.")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: root.colText
                        wrapMode: Text.WordWrap
                    }

                    RippleButton {
                        implicitWidth: 150
                        implicitHeight: 28
                        buttonRadius: 14
                        colBackground: root.colLayer2
                        onClicked: ytMusic.openYtMusicInBrowser()
                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol { text: "open_in_new"; iconSize: 14; color: root.colPrimary }
                            StyledText { text: Translation.tr("Open YouTube Music"); color: root.colPrimary; font.pixelSize: Appearance.font.pixelSize.smaller }
                        }
                    }
                }
            }

            StyledText {
                text: Translation.tr("Select Browser")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: root.colText
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 6
                columnSpacing: 6
                visible: ytMusic.detectedBrowsers.length > 0

                Repeater {
                    model: ytMusic.detectedBrowsers
                    delegate: RippleButton {
                        required property string modelData
                        readonly property bool isConnected: ytMusic.googleConnected && ytMusic.googleBrowser === modelData
                        Layout.fillWidth: true
                        implicitHeight: 36
                        buttonRadius: root.radiusSmall
                        colBackground: isConnected ? ColorUtils.transparentize(root.colPrimary, 0.85) : root.colLayer2
                        colBackgroundHover: isConnected ? ColorUtils.transparentize(root.colPrimary, 0.75) : root.colSurfaceHover
                        onClicked: { ytMusic.connectGoogle(modelData); advancedOptionsPopup.close() }
                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            StyledText { text: ytMusic.browserInfo[modelData]?.icon ?? "🌐"; font.pixelSize: 14 }
                            StyledText {
                                text: ytMusic.browserInfo[modelData]?.name ?? modelData
                                color: isConnected ? root.colPrimary : root.colText
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                font.weight: isConnected ? Font.Medium : Font.Normal
                                Layout.fillWidth: true
                            }
                            MaterialSymbol {
                                visible: isConnected
                                text: "check_circle"
                                iconSize: 16
                                color: root.colPrimary
                            }
                        }
                    }
                }
            }

            StyledText {
                text: Translation.tr("Custom Cookies File")
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: root.colText
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: root.radiusSmall
                color: root.colLayer2
                border.width: root.borderWidth
                border.color: cookiesFieldPopup.activeFocus ? root.colPrimary : root.colBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6
                    MaterialSymbol { text: "description"; iconSize: 16; color: root.colTextSecondary }
                    TextField {
                        id: cookiesFieldPopup
                        Layout.fillWidth: true
                        placeholderText: "/path/to/cookies.txt"
                        text: ytMusic.customCookiesPath
                        color: root.colText
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        placeholderTextColor: root.colTextSecondary
                        background: Item {}
                        onAccepted: if (text) { ytMusic.setCustomCookiesPath(text); advancedOptionsPopup.close() }
                    }
                }
            }
        }
    }
}