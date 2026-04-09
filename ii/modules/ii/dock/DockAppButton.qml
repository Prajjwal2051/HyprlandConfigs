import qs.services
import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 35
    property real countDotWidth: 10
    property real countDotHeight: 4
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined
    property int previousToplevelCount: 0
    property real iconScale: 1.0

    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    readonly property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

    // Track window count changes for animations
    onAppToplevelChanged: {
        if (appToplevel) {
            previousToplevelCount = appToplevel.toplevels.length;
        }
    }

    Connections {
        target: appToplevel
        function onToplevelsChanged() {
            const currentCount = appToplevel.toplevels.length;

            // App opened (count increased from 0)
            if (previousToplevelCount === 0 && currentCount > 0) {
                openAnimation.restart();
            }
            // App closed (count decreased to 0)
            else if (previousToplevelCount > 0 && currentCount === 0) {
                closeAnimation.restart();
            }

            previousToplevelCount = currentCount;
        }
    }

    // Open animation - bounce scale up
    SequentialAnimation {
        id: openAnimation
        NumberAnimation {
            target: root
            property: "iconScale"
            to: 1.3
            duration: 200
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "iconScale"
            to: 1.0
            duration: 300
            easing.type: Easing.OutElastic
            easing.amplitude: 1.0
            easing.period: 0.5
        }
    }

    // Close animation - quick scale down
    SequentialAnimation {
        id: closeAnimation
        NumberAnimation {
            target: root
            property: "iconScale"
            to: 0.7
            duration: 150
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root
            property: "iconScale"
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
            bottomMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
        }
        sourceComponent: DockSeparator {}
    }

    Loader {
        anchors.fill: parent
        active: appToplevel.toplevels.length > 0
        sourceComponent: MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
            onExited: {
                if (appListRoot.lastHoveredButton === root) {
                    appListRoot.buttonHovered = false
                }
            }
        }
    }

    onClicked: {
        if (appToplevel.toplevels.length === 0) {
            root.desktopEntry?.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        appToplevel.toplevels[lastFocused].activate()
    }

    middleClickAction: () => {
        root.desktopEntry?.execute();
    }

    altAction: () => {
        TaskbarApps.togglePin(appToplevel.appId);
    }

    contentItem: Loader {
        active: !isSeparator
        sourceComponent: Item {
            anchors.centerIn: parent
            scale: root.iconScale
            transformOrigin: Item.Center

            Behavior on scale {
                enabled: false  // Disable behavior since we use custom animations
            }

            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                active: !root.isSeparator
                sourceComponent: IconImage {
                    source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "image-missing")
                    implicitSize: root.iconSize
                }
            }

            Loader {
                active: Config.options.dock.monochromeIcons
                anchors.fill: iconImageLoader
                sourceComponent: Item {
                    Desaturate {
                        id: desaturatedIcon
                        visible: false // There's already color overlay
                        anchors.fill: parent
                        source: iconImageLoader
                        desaturation: 0.8
                    }
                    ColorOverlay {
                        anchors.fill: desaturatedIcon
                        source: desaturatedIcon
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                    }
                }
            }

            RowLayout {
                spacing: 3
                anchors {
                    top: iconImageLoader.bottom
                    topMargin: 2
                    horizontalCenter: parent.horizontalCenter
                }
                Repeater {
                    model: Math.min(appToplevel.toplevels.length, 3)
                    delegate: Rectangle {
                        required property int index
                        radius: Appearance.rounding.full
                        implicitWidth: (appToplevel.toplevels.length <= 3) ? 
                            root.countDotWidth : root.countDotHeight // Circles when too many
                        implicitHeight: root.countDotHeight
                        color: appIsActive ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                    }
                }
            }
        }
    }
}
