import QtQuick
import Quickshell
import Quickshell.Services.Notifications

NotificationServer {
    id: notificationServer
    
    
    property PanelWindow panel: PanelWindow {
        id: panel
        anchors.right: true
        anchors.bottom: true
        margins.top: 20
        margins.bottom: 20
        margins.right: 20
        margins.left: 20
        implicitWidth: 350
        
        // Debug count using Repeater count
        Text {
            text: "Notifications: " + repeater.count
            color: "black"
            anchors.top: parent.top
            anchors.left: parent.left
            z: 100
        }
        
        Column {
            id: notificationColumn
            spacing: 10
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 350
            
            Repeater {
                id: repeater
                model: notificationServer.notifications
                
                Rectangle {
                    id: notification
                    
                    width: 350
                    height: 100
                    color: "red"
                    border.color: "blue"
                    border.width: 2
                    radius: 8
                    
                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 5
                        
                        Text {
                            text: notification.summary || "No summary"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }
                        
                        Text {
                            text: notification.body || ""
                            color: "white"
                            font.pixelSize: 12
                            width: parent.width
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: notification.close()  // <-- notification.close()
                    }
                    
                    Timer {
                        interval: 5000
                        running: true
                        repeat: false
                        onTriggered: notification.close()
                    }
                }
            }
        }
    }
}
/*
Notification{
	Text{
		text: noti
	}
}*/
