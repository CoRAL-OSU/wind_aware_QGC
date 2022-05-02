import QtQuick              2.3
import QtQuick.Layouts      1.0
import QtGraphicalEffects   1.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Vehicle      1.0

Item {
    id: _root

    property real verticalWindSpeed: 0
    property real verticalWindSpeedMax: 5

    property color verticalArrowColor: Qt.rgba(1, 1, 0, 1)

    function draw() {
        verticalCompassArrow.draw()
    }


    QGCColoredImage {
        id:                 verticalCompassImage
        source:             "/qmlimages/wind_1d_axis.svg"
        mipmap:             true
        fillMode:           Image.PreserveAspectFit
        anchors.fill:       parent
        sourceSize.height:  parent.height
        color:              qgcPal.text

        transform:Rotation {
            origin.x:       verticalCompassImage.width / 2
            origin.y:       verticalCompassImage.height /2
            angle:          0
        }
    }

    QGCWindDial {
        id:             verticalCompassArrow
        anchors.fill:   verticalCompassImage
        arrowLength:    verticalWindSpeed * (parent.height / (2*verticalWindSpeedMax))
        arrowAngle:     (verticalWindSpeed > 0) ? Math.PI : 0
        arrowColor:     verticalArrowColor
        arrowLineWidth: 4
        visible:        true
        arrowHeadSize: 4

    }
}
