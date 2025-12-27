import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications


ShellRoot {
    id: root
    
    // Import modules
    Loader {
        source: "bar.qml"
        active: true
    }
   /* Loader{
    	source: "notif.qml"
    	active: true
    }*/
}
