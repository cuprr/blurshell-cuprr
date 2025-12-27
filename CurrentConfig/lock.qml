import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick.Effects

PanelWindow {
    id: window
    color: "#003EB0"
    HyprlandWindow.opacity: 0.4
    Component.onCompleted: {
      if (this.WlrLayershell != null) {
        this.WlrLayershell.layer = WlrLayer.Overlay;}}
    
    anchors {
        left: true
        bottom: true
        right: true
        top: true
    }
    Item{
    id: textureItem
    	focus: false
    	anchors.top: window.top
    	anchors.bottom: window.bottom
    	anchors.left: window.left
    	anchors.right: window.right
    }
    // Background blur layer (behind your content)
    ShaderEffectSource {
        id: backgroundSource
        anchors.fill: parent
        sourceItem: textureItem  // Captures window background
        hideSource: false
        live: true
        recursive: false
    }
    
    MultiEffect {
        id: blurEffect
        anchors.fill: backgroundSource
        source: backgroundSource
        
        blurEnabled: true
        blur: 1.0
        blurMax: 32
        autoPaddingEnabled: false  // Prevents window growth
    }
    
    // Your sharp content on top
    Text {
        text: "allWindows"
        font.pointSize: 50
        color: "#0db9d7"
        anchors.centerIn: parent
        z: 1  // Ensure text stays above blur
    }
}
