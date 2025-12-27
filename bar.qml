import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: root

    // Theme
    property color colBg: "#1a1b26"
    property color colFg: "#a9b1d6"
    property color colMuted: "#444b6a"
    property color colCyan: "#0db9d7"
    property color colBlue: "#7aa2f7"
    property color colYellow: "#e0af68"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 14

    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    color: root.colBg

    // System data
    property int cpuUsage: 0
    property int memUsage: 0
    property int dgpuUsage: 0
    property int igpuUsage: 0
    property var lastCpuIdle: 0
    property var lastCpuTotal: 0
    property var lastDgpuUtil: 0
    property var lastDgpuTime: 0
    property var lastIgpuUtil: 0
    property var lastIgpuTime: 0
    property var netDown: 100
    property var netUp: 100
    property int batteryLevel: 0
    property bool isCharging: false
    property string batteryTime: "--:--"
    property string dateTime: "Null"
    

    Process {
        id: memProc
        command: ["sh", "-c", "free | grep Mem"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var parts = data.trim().split(/\s+/)
                var total = parseInt(parts[1]) || 1
                var used = parseInt(parts[2]) || 0
                memUsage = Math.round(100 * used / total)
            }
        }
        Component.onCompleted: running = false
    }
    
    Process {
        id: cpuProc
        command: ["sh", "-c", "head -1 /proc/stat"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                var p = data.trim().split(/\s+/)
                var idle = parseInt(p[4]) + parseInt(p[5])
                var total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)
                if (lastCpuTotal > 0) {
                    cpuUsage = Math.round(100 * (1 - (idle - lastCpuIdle) / (total - lastCpuTotal)))
                }
                lastCpuTotal = total
                lastCpuIdle = idle
            }
        }
        Component.onCompleted: running = false
    }

    // DGPU Usage (NVIDIA) - Direct stdout binding
    Process {
        id: dgpuProc
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1"]
        
        stdout: SplitParser{
        	onRead: data => {
        		if (!data) return
        		var util = parseInt(data.trim())
            dgpuUsage = util
        }
        }
        Component.onCompleted: running = false
    }
    
    
    

   Process {
            id: igpuBackgroundProc
            command: ["intel_gpu_top", "-l", "-s 10000"]
            running: false  // Started explicitly below
            
           stdout: SplitParser {
                onRead: data => {
                    if (!data) return
                    var line = data.trim()
                    
                    // Skip headers only
                    if (line.includes("Freq MHz") || line.includes("req  act")) return
                    
                    var parts = line.split(/\s+/)
                    if (parts.length >= 12) {
                        // RCS % is 7th number = index 6: "989","989","4204","0","6.23","32.65","97.59" <- 97.59
                        var rcsPercent = parseFloat(parts[6])
                        if (!isNaN(rcsPercent)) {
                            igpuUsage = Math.round(rcsPercent)
                            console.log("IGPU FIXED:", igpuUsage, "from", parts[6])
                        }
                    }
                }
            }
            }

            
Process {
    id: netProc
    command: ["sh", "-c", "fast -u &> /tmp/fastTest.tmp && mv /tmp/fastTest.tmp /tmp/fastTest.txt"]
    
    stdout: SplitParser { onRead: {} }
    Component.onCompleted: running = false
}

Process {
    id: batteryProc
    command: ["sh", "-c", "
        bat=/sys/class/power_supply/BAT0
        if [ -d \"$bat\" ] && [ -f \"$bat/capacity\" ]; then
            level=$(cat \"$bat/capacity\")
            status=$(cat \"$bat/status\")
            energy_now=$(cat \"$bat/energy_now\" 2>/dev/null || echo 0)
            power_now=$(cat \"$bat/power_now\" 2>/dev/null || echo 0)
            
            # Charging if not Discharging
            is_charging=false
            [ \"$status\" != \"Discharging\" ] && is_charging=true
            
            if [ \"$is_charging\" = false ] && [ \"$energy_now\" -gt 0 ] && [ \"$power_now\" -gt 0 ]; then
                # Real calculation: energy_now (µWh) / power_now (µW) = seconds
                time_seconds=$((energy_now * 1000000 / power_now))
                hours=$((time_seconds / 3600))
                mins=$(((time_seconds % 3600) / 60))
                [ $mins -lt 10 ] && mins=\"0$mins\"
                time_str=\"$hours:$mins\"
            else
                time_str=\"--:--\"
            fi
            
            echo \"$level $is_charging $time_str\"
        else
            echo \"0 false --:--\"
        fi"]
    
    stdout: SplitParser {
        onRead: data => {
            if (!data) return
            var parts = data.trim().split(/\s+/)
            if (parts.length >= 3) {
                batteryLevel = parseInt(parts[0]) || 0
                isCharging = parts[1] === 'true'
                batteryTime = parts[2]
            }
        }
    }
    Component.onCompleted: running = false
}







            
            
            
            // Clean shutdown when panel destroyed
            Component.onDestruction: {
                quit()
            }
        

    Component.onCompleted: {
            igpuBackgroundProc.running = true
        }
    
    // Update timer for all processes
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            cpuProc.running = true
            memProc.running = true
            dgpuProc.running = true
            batteryProc.running = true
        }
    }
    Timer {
        id: netTimer
        interval: 300000
        running: true
        repeat: true
       	triggeredOnStart : true
        onTriggered:  netProc.running = true
    }
   // Timer {
    //    interval: 300000
     //   running: true
       // repeat: true
       // triggeredOnStart: true
       // onTriggered: {
        //    try {
          //      var content = Io.readFile("/tmp/fastTest.txt").trim()
            //    if (content) {
              //      var lines = content.split("\n")
                //    if (lines.length >= 2) {
                  //      // Extract number before " Mbps" from each line
                    //    netUp = parseFloat(lines[0].match(/(\d+(?:\.\d+)?)/)?.[1]) || 0
                      //  netDown = parseFloat(lines[1].match(/(\d+(?:\.\d+)?)/)?.[1]) || 0
                    //}
               // }
           // } catch (e) {}
       // }
   // }
   
    FileView {
        id: fastTest
        path: "/tmp/fastTest.txt"  // Absolute path, no Qt.resolvedUrl for local files
        blockLoading: false
        blockWrites: false  
        watchChanges: true
        
        onFileChanged: {
            reload()
        }
        
        // Parse content whenever it changes
        readonly property var speeds: {
            try {
                var content = text().trim()
                var lines = content.split("\n")
                if (lines.length >= 2) {
                    var up = parseFloat(lines[0].match(/(\d+(?:\.\d+)?)/)?.[1]) || 0
                    var down = parseFloat(lines[1].match(/(\d+(?:\.\d+)?)/)?.[1]) || 0
                    return { up: up, down: down }
                }
            } catch (e) {}
            return { up: 0, down: 0 }
        }
    }
    
    // Update properties from FileView
    Connections {
        target: fastTest
        function onSpeedsChanged() {
            netUp = fastTest.speeds.up
            netDown = fastTest.speeds.down
        }
    }
    

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Workspaces
        Repeater {
            model: 9
            Text {
                property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                text: index + 1
                color: isActive ? root.colCyan : (ws ? root.colBlue : root.colMuted)
                font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
                MouseArea {
                    anchors.fill: parent
                    onClicked: Hyprland.dispatch("workspace " + (index + 1))
                }
            }
        }

        Item { Layout.fillWidth: true }

        Rectangle { width: 1; height: 16; color: root.colMuted }
        
        Text {
            text: "↓" + netDown.toFixed(0) + "↑" + netUp.toFixed(0) + "M"
            color: root.colCyan
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }
        
        Rectangle { width: 1; height: 16; color: root.colMuted }
        
        // CPU
        Text {
            text: "CPU: " + cpuUsage + "%"
            color: root.colYellow
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 16; color: root.colMuted }

        // Memory
        Text {
            text: "Mem: " + memUsage + "%"
            color: root.colCyan
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 16; color: root.colMuted }

        // DGPU
        Text {
            text: "DGPU: " + dgpuUsage + "%"
            color: root.colYellow
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }

        Rectangle { width: 1; height: 16; color: root.colMuted }

        // IGPU
        Text {
            text: "IGPU: " + igpuUsage + "%"
            color: root.colCyan
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
        }
        
		Rectangle { width: 1; height: 16; color: root.colMuted }
		        
		//battery
		Text {
		    text: isCharging? "Battery: " + batteryLevel + "% " : "Battery: " + batteryLevel + "% " + batteryTime
		    color: isCharging ? root.colYellow : root.colBlue
		    font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
		}
		        
		Rectangle { width: 1; height: 16; color: root.colMuted }
		                
    }
    Item {
        anchors.fill: parent
    
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8
    
            // Workspaces, separators, system info, etc.
            // Just remove the old clock Text from here.
        }
    
        // Centered clock overlayed above layout
        Text {
            id: clock2
            anchors.centerIn: parent
            color: root.colBlue
            font { family: root.fontFamily; pixelSize: root.fontSize; bold: true }
            text: dateTime
            Process {
                    id: clockProc
                    command: ["date", "+%a, %b %d - %H:%M"]
                    stdout: SplitParser { onRead: clock2.text = data.trim() }
                    Component.onCompleted: running = false
                }
            Timer {
                interval: 30000
                running: true
                repeat: true
                onTriggered: clockProc.running = true
            }
        }
    }
}
