import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    property bool shouldShow: false
    property var targetScreen: null
    signal finished
    signal peaked

    LazyLoader {
        active: true
        PanelWindow {
            id: transitionWindow
            visible: root.shouldShow
            screen: root.targetScreen
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            anchors {
                left: true
                top: true
                bottom: true
            }
            implicitWidth: transitionWindow.screen ? transitionWindow.screen.width * 0.33 : 640

            onVisibleChanged: {
                if (visible)
                    startDelay.start();
            }

            Timer {
                id: startDelay
                interval: 80
                repeat: false
                onTriggered: blockRepeater.restartAll()
            }

            Repeater {
                id: blockRepeater
                model: [
                    {
                        color: "#0d1a3a",
                        delay: 0
                    },
                    {
                        color: "#1a6aff",
                        delay: 100
                    },
                    {
                        color: "#7dd4fc",
                        delay: 200
                    }
                ]

                function restartAll() {
                    for (var i = 0; i < count; i++)
                        itemAt(i).startAnim();
                }

                Item {
                    id: blockItem
                    required property var modelData
                    required property int index
                    anchors.fill: parent
                    z: 999 - index

                    function startAnim() {
                        blockAnim.restart();
                    }

                    Rectangle {
                        id: block
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width
                        color: blockItem.modelData.color
                        transformOrigin: Item.Left
                        transform: Scale {
                            id: blockScale
                            xScale: 0
                        }
                    }

                    SequentialAnimation {
                        id: blockAnim
                        running: false
                        PauseAnimation {
                            duration: blockItem.modelData.delay
                        }
                        NumberAnimation {
                            target: blockScale
                            property: "xScale"
                            from: 0
                            to: 1
                            duration: 350
                            easing.type: Easing.InOutQuart
                        }
                        ScriptAction {
                            script: {
                                if (blockItem.index === 2)
                                    root.peaked();
                            }
                        }
                        PauseAnimation {
                            duration: 200
                        }
                        NumberAnimation {
                            target: blockScale
                            property: "xScale"
                            from: 1
                            to: 0
                            duration: 350
                            easing.type: Easing.InOutQuart
                        }
                        ScriptAction {
                            script: {
                                if (blockItem.index === 2) {
                                    root.shouldShow = false;
                                    root.finished();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
