import QtQuick
import Quickshell.Io

QtObject {
  id: root
  
  property int capacity: 0
  property string status: ""
  property string icon: "󰁺"
  
  property string batteryDevice: ""
  
  Process {
    id: findBattery
    command: ["sh", "-c", "ls /sys/class/power_supply | grep ^BAT | head -n 1"]
    running: true
    stdout: SplitParser {
      onRead: data => {
        let device = data.trim();
        if (device) {
          root.batteryDevice = device;
        }
      }
    }
  }

  property Timer updateTimer: Timer {
    interval: 5000
    running: root.batteryDevice !== ""
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      capacityFile.reload()
      statusFile.reload()
    }
  }
  
  property FileView capacityFile: FileView {
    path: root.batteryDevice ? "/sys/class/power_supply/" + root.batteryDevice + "/capacity" : ""
    onLoaded: {
      root.capacity = parseInt(text().trim())
      root.updateIcon()
    }
  }
  
  property FileView statusFile: FileView {
    path: root.batteryDevice ? "/sys/class/power_supply/" + root.batteryDevice + "/status" : ""
    onLoaded: {
      root.status = text().trim()
      root.updateIcon()
    }
  }
  
  function updateIcon() {
    var icons = ["󰁺","󰁻","󰁼","󰁽","󰁾","󰁿","󰂀","󰂁","󰂂","󰁹"]
    var index = Math.floor(capacity / 10)
    if (index > 9) index = 9
    
    if (status.includes("Charging")) {
      icon = "󰂄"
    } else if (status.includes("Full") || status.includes("Not charging")) {
      icon = "󰂄"
    } else {
      icon = icons[index]
    }
  }
}
