import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.0
import QtCharts 2.1
import Data1D 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 640
    height: 480

    Timer {
        property int count: 0
        running: true
        repeat: true
        interval: 16
        onTriggered: {
            var x = count*0.1
            var y = Math.sin(x)
            plot.dataSource.add(x,y)

            count += 1
        }
    }

    ZoomablePlot {
        id: plot
        color: root.color
        anchors.fill: parent
    }
}
