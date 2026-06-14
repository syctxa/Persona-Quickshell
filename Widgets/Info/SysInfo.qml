pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  // ── Consumer gate ─────────────────────────────────────────────
  // Set to true by UI when visible, false when hidden to pause polling
  property bool active: false

  // ── CPU ───────────────────────────────────────────────────────
  readonly property real cpuUsage: _cpuUsage
  property real _cpuUsage: 0
  property real _lastCpuIdle: 0
  property real _lastCpuTotal: 0

  // ── Memory ────────────────────────────────────────────────────
  property real _memUsed: 0
  property real _memTotal: 1
  readonly property real memUsage: _memTotal > 0 ? _memUsed / _memTotal : 0
  readonly property string memText:
    (_memUsed  / 1073741824).toFixed(1) + " / " +
    (_memTotal / 1073741824).toFixed(1) + " GB"

  // ── Disk ──────────────────────────────────────────────────────
  property real _diskUsed: 0
  property real _diskTotal: 1
  readonly property real diskUsage: _diskTotal > 0 ? _diskUsed / _diskTotal : 0
  readonly property string diskText:
    (_diskUsed  / 1073741824).toFixed(1) + " / " +
    (_diskTotal / 1073741824).toFixed(1) + " GB"

  // ── Static info (fetched once) ────────────────────────────────
  property string osName: ""
  property string loggedInUsers: ""

  // ── CPU (/proc/stat via FileView — no fork overhead) ─────────
  FileView {
    id: cpuFile
    path: "/proc/stat"
    onLoaded: {
      const line = text().match(/^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/)
      if (!line) return
      const s       = line.slice(1).map(Number)
      const idle    = s[3] + s[4]                          // idle + iowait
      const total   = s[0]+s[1]+s[2]+s[3]+s[4]+s[5]+s[6] // all fields
      if (root._lastCpuTotal > 0) {
        const dt = total - root._lastCpuTotal
        const di = idle  - root._lastCpuIdle
        if (dt > 0) root._cpuUsage = 1 - di / dt
      }
      root._lastCpuIdle  = idle
      root._lastCpuTotal = total
    }
  }

  // ── Memory (/proc/meminfo via FileView — no fork overhead) ────
  FileView {
    id: memFile
    path: "/proc/meminfo"
    onLoaded: {
      const t = text()
      const total = parseInt(t.match(/MemTotal:\s+(\d+)/)?.[1]     ?? 0)
      const avail = parseInt(t.match(/MemAvailable:\s+(\d+)/)?.[1] ?? 0)
      if (total > 0) {
        root._memTotal = total * 1024
        root._memUsed  = (total - avail) * 1024
      }
    }
  }

  // ── Disk (persistent shell — no fork on every poll) ───────────
  Process {
    id: dfShell
    command: ["sh"]
    stdinEnabled: true
    running: root.active

    onRunningChanged: {
      if (running) diskTimer.triggered()  // immediate first read
    }

    stdout: SplitParser {
      splitMarker: "@@END@@"
      onRead: data => {
        const parts = data.trim().split(/\s+/)
        if (parts.length >= 3) {
          root._diskTotal = parseInt(parts[1])
          root._diskUsed  = parseInt(parts[2])
        }
      }
    }
  }

  // ── Static info processes (run once on init) ──────────────────
  Process {
    id: osProc
    command: ["sh", "-c", ". /etc/os-release && echo $PRETTY_NAME"]
    running: true
    stdout: SplitParser { onRead: data => root.osName = data.trim() }
  }

  Process {
    id: usersProc
    command: ["sh", "-c", "who | wc -l"]
    running: true
    stdout: SplitParser { onRead: data => root.loggedInUsers = data.trim() }
  }

  // ── Timers ────────────────────────────────────────────────────
  // CPU + mem: every 2s via FileView.reload() — cheapest possible read
  Timer {
    interval: 2000
    repeat: true
    running: root.active
    triggeredOnStart: true
    onTriggered: {
      cpuFile.reload()
      memFile.reload()
    }
  }

  // Disk: every 30s via persistent shell stdin write
  Timer {
    id: diskTimer
    interval: 30000
    repeat: true
    running: root.active
    onTriggered: {
      if (dfShell.running)
        dfShell.write("df -B1 / | awk 'NR==2{print $1\" \"$2\" \"$3}'; echo '@@END@@'\n")
    }
  }

  Component.onCompleted: {
    // loggedInUsers is dynamic enough to refresh occasionally
    usersTimer.start()
  }

  // Refresh logged-in users every 60s (cheap, but can change)
  Timer {
    id: usersTimer
    interval: 60000
    repeat: true
    running: root.active
    onTriggered: usersProc.running = true
  }
}
