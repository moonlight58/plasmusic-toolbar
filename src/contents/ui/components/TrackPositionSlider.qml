import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3

Item {
    id: container

    property double songPosition: 0   // microseconds
    property double songLength:   0   // microseconds
    property bool   playing:      false
    property bool   enableChangePosition: true

    signal requireChangePosition(position: double)
    signal requireUpdatePosition()

    // Colours — override from parent if needed
    property color trackColor:    Qt.rgba(1, 1, 1, 0.25)   // dim white track
    property color fillColor:     "#D4AF37"                  // gold fill
    property color handleColor:   "#FFFFFF"                  // white dot handle
    property real  barHeight:     4
    property real  handleRadius:  6

    Layout.preferredHeight: barHeight + handleRadius * 2
    Layout.fillWidth: true

    // Internal progress, 0.0 – 1.0
    readonly property double _progress: container.songLength > 0
        ? Math.min(container.songPosition / container.songLength, 1.0)
        : 0.0

    // ── Auto-advance timer ─────────────────────────────────────────────────
    Timer {
        id: timer
        interval: 200
        running:  container.playing && !dragArea.pressed
        repeat:   true
        onTriggered: container.requireUpdatePosition()
    }

    // ── Track background ───────────────────────────────────────────────────
    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width:  parent.width
        height: container.barHeight
        radius: height / 2
        color:  container.trackColor
    }

    // ── Filled portion ─────────────────────────────────────────────────────
    Rectangle {
        id: fill
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: track.left
        width:  track.width * container._progress
        height: container.barHeight
        radius: height / 2
        color:  container.fillColor
    }

    // ── Handle dot ─────────────────────────────────────────────────────────
    Rectangle {
        id: handle
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(
               fill.width - container.handleRadius,
               track.width * container._progress - container.handleRadius))
        width:  container.handleRadius * 2
        height: container.handleRadius * 2
        radius: container.handleRadius
        color:  container.handleColor
        visible: container.songLength > 0
    }

    // ── Drag / seek ────────────────────────────────────────────────────────
    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: container.enableChangePosition && container.songLength > 0
        cursorShape: Qt.PointingHandCursor

        function seek(mouseX) {
            const ratio = Math.max(0, Math.min(mouseX / track.width, 1.0))
            container.requireChangePosition(ratio * container.songLength)
        }

        onPressed:      (mouse) => seek(mouse.x)
        onPositionChanged: (mouse) => { if (pressed) seek(mouse.x) }
    }
}
