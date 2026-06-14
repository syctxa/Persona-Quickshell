import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
  id: root
  property bool shouldShow: false
  property var targetScreen: null
  signal finished()
  signal peaked()

  LazyLoader {
    active: true
    PanelWindow {
      id: transitionWindow
      visible: root.shouldShow
      screen: root.targetScreen
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      anchors { left: true; right: true; top: true; bottom: true }

      onVisibleChanged: {
        if (visible) startDelay.start()
      }

      Timer {
        id: startDelay
        interval: 80
        repeat: false
        onTriggered: {
          bgBlock.startAnim()
          blockRepeater.restartAll()
        }
      }

      Rectangle {
        id: bgBlock
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width
        color: "#000000"
        x: -width
        z: 0

        function startAnim() { bgAnim.restart() }

        SequentialAnimation {
          id: bgAnim
          running: false
          NumberAnimation {
            target: bgBlock; property: "x"
            from: -bgBlock.width; to: 0
            duration: 350
            easing.type: Easing.OutExpo
          }
          PauseAnimation { duration: 120 }
          NumberAnimation {
            target: bgBlock; property: "x"
            from: 0; to: -bgBlock.width
            duration: 300
            easing.type: Easing.InExpo
          }
        }
      }

      Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        z: 1

        Repeater {
          id: blockRepeater
          model: [
            { color: "#0d1a3a", delay: 0   },
            { color: "#1a6aff", delay: 80  },
            { color: "#7dd4fc", delay: 160 },
          ]
          function restartAll() {
            for (var i = 0; i < count; i++)
              itemAt(i).startAnim()
          }

          Item {
            id: blockItem
            required property var modelData
            required property int index
            width: transitionWindow.width * 0.85
            height: transitionWindow.height * 0.3
            x: -width

            function startAnim() { blockAnim.restart() }

            Rectangle {
              anchors.fill: parent
              color: blockItem.modelData.color
              transform: Matrix4x4 {
                matrix: Qt.matrix4x4(
                  1, -0.05, 0, 0,
                  0,  1,    0, 0,
                  0,  0,    1, 0,
                  0,  0,    0, 1
                )
              }
            }

            SequentialAnimation {
              id: blockAnim
              running: false

              PauseAnimation { duration: blockItem.modelData.delay }

              NumberAnimation {
                target: blockItem; property: "x"
                from: -blockItem.width; to: 0
                duration: 350
                easing.type: Easing.OutExpo
              }

              ScriptAction {
                script: {
                  if (blockItem.index === 2) root.peaked()
                }
              }

              PauseAnimation { duration: 180 }

              NumberAnimation {
                target: blockItem; property: "x"
                from: 0; to: -blockItem.width
                duration: 300
                easing.type: Easing.InExpo
              }

              PauseAnimation { duration: 50 }

              ScriptAction {
                script: {
                  if (blockItem.index === 2) {
                    root.shouldShow = false
                    root.finished()
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
