import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Wayland

Scope {
  id: root
  property bool shouldShow: false
  property var targetScreen: null

  LazyLoader {
    active: true
    PanelWindow {
      id: optionsWindow
      visible: root.shouldShow
      screen: root.targetScreen
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.exclusionMode: ExclusionMode.Ignore
      WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
      anchors { left: true; right: true; top: true; bottom: true }

      onVisibleChanged: {
        if (visible) bgVideo.play()
        else bgVideo.stop()
      }

      Video {
        id: bgVideo
        anchors.fill: parent
        source: Qt.resolvedUrl("../Assets/videos/Options.mp4")
        fillMode: VideoOutput.PreserveAspectCrop
        loops: MediaPlayer.Infinite
        volume: 0
        z: 0
      }

      Item {
        id: contentRoot
        anchors.fill: parent
        z: 3
        focus: true

        MouseArea {
          anchors.fill: parent
          z: -1
          onClicked: root.shouldShow = false
        }

        Keys.onPressed: (event) => {
          if (event.key === Qt.Key_Escape) {
            root.shouldShow = false
            event.accepted = true
          }
        }
      }
    }
  }
}
