import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int hours: 0
    property string icon: "icons/steam-logo.svg"

    property Timer updateTimer: Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            steamProcess.running = true
        }
    }

    property Process steamProcess: Process {
        command: ["sh", "-c", "grep -w '\"Playtime2wks\"' ~/.steam/steam/userdata/1642239526/config/localconfig.vdf | tr -d '\"' | awk '{sum += $2} END {print sum/60}'"]
        stdout: SplitParser {
            onRead: data => {
                        let val = parseFloat(data.trim())
                        if (!isNaN(val)) {
                            root.hours = Math.round(val)
                        }
                    }
        }
    }
}
