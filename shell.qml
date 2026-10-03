//@ pragma UseQApplication
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import QtQuick

// spritepet — image-based desktop pets for wlr-layer-shell compositors.
// Any PNG or WebP in $XDG_CONFIG_HOME/spritepet/images/ becomes a mood.
// Optional config.json in $XDG_CONFIG_HOME/spritepet/ tunes size, position,
// breathing, sway, hops, and idle temperament. See config.json.example.

PanelWindow {
    id: root
    visible: true
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "spritepet"
    mask: Region { item: pet }

    property string imagesDir: ""
    property var moodFiles: []
    property int moodIndex: 0
    property var cfg: ({})

    function c(key, fallback) {
        return root.cfg && root.cfg[key] !== undefined ? root.cfg[key] : fallback
    }

    property var cfgX: root.cfg ? root.cfg.x : undefined
    property var cfgY: root.cfg ? root.cfg.y : undefined
    property real cfgScale: c("scale", 0.75)
    property real cfgMargin: c("margin", 110)
    property real cfgBobAmp: c("bobAmplitude", 12)
    property int cfgBobDur: c("bobDurationMs", 1800)
    property real cfgSwayAngle: c("swayAngleDeg", 1.2)
    property int cfgSwayDur: c("swayDurationMs", 2600)
    property real cfgHopHeight: c("hopHeight", 70)
    property int cfgIdleMin: c("idleHopMinMs", 20000)
    property int cfgIdleMax: c("idleHopMaxMs", 34000)

    // Bootstrap: resolve the spritepet config directory, list mood images,
    // and read config.json in one shell round-trip, so the QML side never
    // hardcodes a path or a username.
    Process {
        id: bootstrap
        command: ["bash", "-c",
            'D="${XDG_CONFIG_HOME:-$HOME/.config}/spritepet"; ' +
            'echo "$D/images"; ' +
            'ls -1 "$D/images" 2>/dev/null; ' +
            'echo "---CONFIG---"; ' +
            'cat "$D/config.json" 2>/dev/null']
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.split("---CONFIG---")
                var head = (parts[0] || "").trim().split("\n")
                var dir = head[0].trim()
                if (dir.length > 0) root.imagesDir = dir
                root.moodFiles = head.slice(1)
                    .map(s => s.trim())
                    .filter(f => f.length > 0)
                if (root.moodFiles.length === 0)
                    console.warn("spritepet: no images found in " + (dir || "the images directory"))
                if (parts.length > 1 && parts[1].trim().length > 0) {
                    try {
                        root.cfg = JSON.parse(parts[1].trim())
                    } catch (e) {
                        console.warn("spritepet: config.json could not be parsed; using defaults")
                    }
                }
            }
        }
    }
    Component.onCompleted: bootstrap.running = true

    Item {
        id: pet
        property real zoom: root.cfgScale
        property string src: root.moodFiles.length > 0 ? root.moodFiles[root.moodIndex] : ""
        width: root.moodFiles.length > 0 ? sprite.implicitWidth * zoom : 1
        height: root.moodFiles.length > 0 ? sprite.implicitHeight * zoom : 1
        x: root.cfgX !== undefined ? root.cfgX : root.width - width - root.cfgMargin
        y: root.cfgY !== undefined ? root.cfgY : root.height - height - root.cfgMargin

        Image {
            id: sprite
            anchors.fill: parent
            source: pet.src ? (root.imagesDir + "/" + pet.src) : ""
            fillMode: Image.PreserveAspectFit
            smooth: true
            transform: [
                Translate { id: bob; y: 0 },
                Translate { id: hop; y: 0 },
                Rotation { id: sway; angle: 0; origin.x: sprite.width / 2; origin.y: sprite.height }
            ]
        }
    }

    // first-run hint when no images exist yet
    Text {
        visible: root.moodFiles.length === 0
        anchors.centerIn: parent
        text: "spritepet: put images in\n" + (root.imagesDir.length > 0 ? root.imagesDir : "$XDG_CONFIG_HOME/spritepet/images")
        color: "#e0e0e0"
        opacity: 0.7
        font.pixelSize: 18
        horizontalAlignment: Text.AlignHCenter
    }

    // idle breathing
    SequentialAnimation {
        running: sprite.status === Image.Ready
        loops: Animation.Infinite
        NumberAnimation { target: bob; property: "y"; from: 0; to: -root.cfgBobAmp; duration: root.cfgBobDur; easing.type: Easing.InOutSine }
        NumberAnimation { target: bob; property: "y"; from: -root.cfgBobAmp; to: 0; duration: root.cfgBobDur; easing.type: Easing.InOutSine }
    }

    // gentle sway around her feet
    SequentialAnimation {
        running: sprite.status === Image.Ready
        loops: Animation.Infinite
        PauseAnimation { duration: 450 }
        NumberAnimation { target: sway; property: "angle"; from: -root.cfgSwayAngle; to: root.cfgSwayAngle; duration: root.cfgSwayDur; easing.type: Easing.InOutSine }
        NumberAnimation { target: sway; property: "angle"; from: root.cfgSwayAngle; to: -root.cfgSwayAngle; duration: root.cfgSwayDur; easing.type: Easing.InOutSine }
    }

    // hop on click
    SequentialAnimation {
        id: hopAnim
        NumberAnimation { target: hop; property: "y"; from: 0; to: -root.cfgHopHeight; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: hop; property: "y"; from: -root.cfgHopHeight; to: 0; duration: 420; easing.type: Easing.OutBounce }
    }

    // occasional idle hop so she feels alive
    Timer {
        interval: root.cfgIdleMin + Math.random() * Math.max(1, root.cfgIdleMax - root.cfgIdleMin)
        running: sprite.status === Image.Ready
        repeat: true
        onTriggered: hopAnim.restart()
    }

    MouseArea {
        anchors.fill: pet
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.OpenHandCursor
        drag.target: pet
        drag.axis: Drag.XAndYAxis
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) pet.zoom = Math.min(6, pet.zoom * 1.1)
            else pet.zoom = Math.max(0.05, pet.zoom * 0.9)
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                if (root.moodFiles.length > 1) {
                    root.moodIndex = (root.moodIndex + 1) % root.moodFiles.length
                    hopAnim.restart()
                }
            } else {
                hopAnim.restart()
            }
        }
    }
}
