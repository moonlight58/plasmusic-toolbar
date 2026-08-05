import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: container
    property alias size: icon.width
    property bool active: false
    property alias source: icon.source
    property color bgColor: "transparent"
    property real extraWidth: 0
    property real padding: Kirigami.Units.smallSpacing * 1.5
    property string iconColorOverride: ""
    signal clicked()

    readonly property real boxHeight: size + padding * 2
    readonly property real boxWidth: size + padding * 2 + extraWidth

    Component.onCompleted: {
        console.log("CommandIcon source:", source, "size:", size, "padding:", padding, "boxHeight:", boxHeight)  
    }

    Layout.preferredWidth: bgColor === "transparent" ? size : boxWidth
    Layout.preferredHeight: bgColor === "transparent" ? size : boxHeight

    

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: bgColor
    }

    Kirigami.Icon {
        id: icon
        anchors.centerIn: parent
        width: Kirigami.Units.iconSizes.small
        height: width
        color: iconColorOverride !== "" ? iconColorOverride : (container.active ? "#D4AF37" : "#F5F5F5")

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: container.clicked()
        }
    }
}
