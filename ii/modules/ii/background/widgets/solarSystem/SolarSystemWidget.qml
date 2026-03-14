import QtQuick
import QtQuick.Layouts
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "solarSystem"
    visibleWhenLocked: false
    hoverEnabled: true

    property bool dragLocked: false
    property bool paused: false
    property real time: 0.0     // running seconds

    draggable: root.placementStrategy === "free" && !root.dragLocked

    implicitWidth: 490
    implicitHeight: 490

    // Earth completes one orbit every 60 real seconds; all others scaled proportionally
    readonly property real earthPeriod: 60.0
    // Viewing tilt: orbital plane angle from face-on (degrees)
    readonly property real tiltDeg: 62.0
    readonly property real sinT: Math.sin(tiltDeg * Math.PI / 180.0)

    readonly property var planets: [
        {
            name: "Mercury", color: "#a8a8a8",
            size: 4,  orbitR: 46,
            period: earthPeriod * (88.0 / 365.25),
            startAngle: 0.5
        },
        {
            name: "Venus",   color: "#e8d5a3",
            size: 7,  orbitR: 68,
            period: earthPeriod * (224.7 / 365.25),
            startAngle: 2.1
        },
        {
            name: "Earth",   color: "#3d85c8",
            size: 7,  orbitR: 90,
            period: earthPeriod,
            startAngle: 1.2,
            hasMoon: true
        },
        {
            name: "Mars",    color: "#c1440e",
            size: 5,  orbitR: 114,
            period: earthPeriod * (686.9 / 365.25),
            startAngle: 4.0
        },
        {
            name: "Jupiter", color: "#c8a064",
            size: 16, orbitR: 154,
            period: earthPeriod * (4332.6 / 365.25),
            startAngle: 0.8
        },
        {
            name: "Saturn",  color: "#e4d18a",
            size: 13, orbitR: 192,
            period: earthPeriod * (10759.2 / 365.25),
            startAngle: 3.5,
            hasRings: true
        },
        {
            name: "Uranus",  color: "#7de8e8",
            size: 10, orbitR: 224,
            period: earthPeriod * (30688.5 / 365.25),
            startAngle: 1.9
        },
        {
            name: "Neptune", color: "#4b6fe4",
            size: 10, orbitR: 236,
            period: earthPeriod * (60195.0 / 365.25),
            startAngle: 2.8
        }
    ]

    Timer {
        running: root.visible && !root.paused
        interval: 33
        repeat: true
        onTriggered: root.time += 0.033
    }

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton)
            root.paused = !root.paused
    }

    // ── Solar system canvas ──────────────────────────────────────────────
    Item {
        id: canvas
        anchors.fill: parent

        readonly property real cx: width  / 2
        readonly property real cy: height / 2

        // ── Orbit rings — in a tilted layer so circles project as ellipses ──
        Item {
            id: orbitLayer
            anchors.fill: parent
            transform: Rotation {
                origin.x: canvas.cx
                origin.y: canvas.cy
                axis.x: 1; axis.y: 0; axis.z: 0
                angle: root.tiltDeg
            }
            Repeater {
                model: root.planets.length
                delegate: Rectangle {
                    required property int index
                    readonly property var p: root.planets[index]
                    x: canvas.cx - p.orbitR
                    y: canvas.cy - p.orbitR
                    width:  p.orbitR * 2
                    height: p.orbitR * 2
                    radius: p.orbitR
                    color: "transparent"
                    border.color: Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                }
            }
        }

        // ── Sun glow halos ───────────────────────────────────────────────
        Repeater {
            model: [68, 50, 34]
            delegate: Rectangle {
                required property int modelData
                anchors.centerIn: parent
                width: modelData; height: modelData
                radius: modelData / 2
                color: "transparent"
                border.color: Qt.rgba(1.0, 0.75, 0.1,
                    modelData === 68 ? 0.05 : modelData === 50 ? 0.11 : 0.0)
            }
        }

        // ── Sun ─────────────────────────────────────────────────────────
        Rectangle {
            anchors.centerIn: parent
            width: 24; height: 24; radius: 12
            color: "#ffc107"
            z: 1
            Rectangle {
                width: 9; height: 9; radius: 4.5
                color: "#fff9c4"
                x: 4; y: 4; opacity: 0.82
            }
            // soft bloom behind
            Rectangle {
                anchors.centerIn: parent
                width: 36; height: 36; radius: 18
                color: Qt.rgba(1.0, 0.8, 0.1, 0.07)
                z: -1
            }
        }

        // ── Planets: manual perspective projection with depth cues ───────
        Repeater {
            model: root.planets.length
            delegate: Item {
                id: planetDelegate
                required property int index
                anchors.fill: parent

                readonly property var p: root.planets[index]

                // Orbital angle
                readonly property real angle: p.startAngle + root.time * (2 * Math.PI / p.period)

                // Position in the orbital plane
                readonly property real rawX: Math.cos(angle) * p.orbitR
                readonly property real rawY: Math.sin(angle) * p.orbitR

                // Perspective projection:
                //   X is unchanged (horizontal across screen)
                //   Y is squished by sinT (the tilt squashes the vertical extent)
                //   Z = rawY (positive rawY = closer to viewer at bottom of tilt)
                readonly property real screenX: canvas.cx + rawX
                readonly property real screenY: canvas.cy + rawY * root.sinT

                // zNorm: -1 (far/behind) → +1 (near/front)
                readonly property real zNorm: rawY / Math.max(p.orbitR, 1)

                // Depth-based size and brightness
                readonly property real depthScale: 1.0 + zNorm * 0.28
                readonly property real depthOpacity: 0.60 + zNorm * 0.40

                // Planets behind the sun sit below it, in front sit above
                z: zNorm > 0 ? 3 : 0
                opacity: depthOpacity

                // ── Saturn rings (drawn behind planet body) ──────────────
                // Rings share the same orbital-plane tilt, so their width is
                // normal but height is squished by sinT
                Rectangle {
                    visible: p.hasRings === true
                    readonly property real rw: p.size * 3.5 * depthScale
                    readonly property real rh: p.size * 0.9 * depthScale * root.sinT
                    x: screenX - rw / 2
                    y: screenY - rh / 2
                    width:  rw
                    height: rh
                    radius: rh / 2
                    color: "transparent"
                    border.color: Qt.rgba(0.9, 0.85, 0.55, 0.55)
                    border.width: 2
                    z: -1
                }

                // ── Planet body ──────────────────────────────────────────
                Rectangle {
                    id: planetBody
                    readonly property real sz: p.size * depthScale
                    x: screenX - sz / 2
                    y: screenY - sz / 2
                    width:  sz
                    height: sz
                    radius: sz / 2
                    color: p.color

                    // Lit hemisphere highlight (upper-left)
                    Rectangle {
                        width:  Math.max(2, parent.sz * 0.38)
                        height: Math.max(2, parent.sz * 0.38)
                        radius: width / 2
                        color: Qt.lighter(p.color, 1.7)
                        opacity: 0.62
                        x: parent.sz * 0.16
                        y: parent.sz * 0.11
                    }

                    // Shadow hemisphere (right/bottom — dark crescent)
                    Item {
                        width:  parent.sz
                        height: parent.sz
                        clip: true
                        Rectangle {
                            x: parent.width * 0.42
                            y: 0
                            width:  parent.width * 0.58
                            height: parent.height
                            color: Qt.rgba(0, 0, 0, 0.32)
                            radius: parent.width * 0.58 / 2
                        }
                    }

                    property bool hovered: false
                    MouseArea {
                        anchors {
                            fill: parent
                            margins: -7
                        }
                        hoverEnabled: true
                        propagateComposedEvents: true
                        onEntered: parent.hovered = true
                        onExited:  parent.hovered = false
                        onClicked: mouse => mouse.accepted = false
                    }

                    // Planet name tooltip
                    Rectangle {
                        visible: parent.hovered
                        x: parent.sz + 5
                        y: -4
                        width:  nameLabel.implicitWidth + 10
                        height: nameLabel.implicitHeight + 6
                        radius: 4
                        color: Appearance.colors.colLayer2
                        border.color: Appearance.colors.colOutlineVariant
                        border.width: 1
                        opacity: 0.93
                        z: 10
                        Text {
                            id: nameLabel
                            anchors.centerIn: parent
                            text: p.name
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }

                // ── Earth's moon (also perspective-projected) ────────────
                Item {
                    visible: p.hasMoon === true
                    readonly property real moonAngle: root.time * (2 * Math.PI / (earthPeriod * 27.3 / 365.25))
                    readonly property real moonRawX: Math.cos(moonAngle) * 13
                    readonly property real moonRawY: Math.sin(moonAngle) * 13
                    readonly property real msx: screenX + moonRawX
                    readonly property real msy: screenY + moonRawY * root.sinT
                    readonly property real mzNorm: moonRawY / 13
                    z: mzNorm > 0 ? 4 : -2
                    Rectangle {
                        x: parent.msx - 2.5
                        y: parent.msy - 2.5
                        width: 5; height: 5; radius: 2.5
                        color: "#cccccc"
                        opacity: 0.85
                    }
                }
            }
        }

        // ── Hover UI (not tilted) ────────────────────────────────────────
        Item {
            anchors.fill: parent
            opacity: root.containsMouse ? 1 : 0
            z: 20
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.OutCubic
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: root.paused ? "play_arrow" : "pause"
                iconSize: 22
                color: Appearance.colors.colOnLayer1
                opacity: 0.45
            }

            Row {
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    margins: 10
                }
                spacing: 6
                RippleButton {
                    implicitWidth: 26; implicitHeight: 26
                    buttonRadius: height / 2
                    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.35)
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer3Hover, 0.28)
                    colRipple: Appearance.colors.colLayer3Active
                    onClicked: root.dragLocked = !root.dragLocked
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.dragLocked ? "lock" : "lock_open"
                        iconSize: 15
                        color: root.dragLocked ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer2
                    }
                    StyledToolTip { text: root.dragLocked ? "Unlock position" : "Lock position" }
                }
            }

            Row {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: 10
                }
                spacing: 6
                RippleButton {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 26; implicitHeight: 26
                    buttonRadius: height / 2
                    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer3, 0.35)
                    colBackgroundHover: ColorUtils.transparentize(Appearance.colors.colLayer3Hover, 0.28)
                    colRipple: Appearance.colors.colLayer3Active
                    onClicked: root.time = 0
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        text: "replay"
                        iconSize: 15
                        color: Appearance.colors.colOnLayer2
                    }
                    StyledToolTip { text: "Reset orbits" }
                }
                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.paused ? "Paused  ·  click to resume" : "Click to pause"
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.small
                }
            }
        }
    }
}

