/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/


/**
 * @file
 *   @brief QGC Wind Compass Widget
 *   @author Max DeSantis <max.desantis@okstate.edu>
 */

import QtQuick              2.3
import QtGraphicalEffects   1.0

import QGroundControl              1.0
import QGroundControl.Controls     1.0
import QGroundControl.ScreenTools  1.0
import QGroundControl.Vehicle      1.0
import QGroundControl.Palette      1.0

Item {
    id:     root
    width:  size
    height: size

    property real size:     _defaultSize
    property var  vehicle:  null

    property var  _activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    property real _defaultSize:         ScreenTools.defaultFontPixelHeight * (10)
    property real _sizeRatio:           ScreenTools.isTinyScreen ? (size / _defaultSize) * 0.5 : size / _defaultSize
    property int  _fontSize:            ScreenTools.defaultFontPointSize * _sizeRatio
    property real _windSpeed:           vehicle ? vehicle.wind.speed.rawValue : 0
    property real _windHeading:         vehicle ? vehicle.wind.direction.rawValue: 0
    property alias axes: axes
    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Rectangle {
        id:             borderRect
        anchors.fill:   parent
        radius:         width / 2
        color:          qgcPal.window
        border.color:   qgcPal.text
        border.width:   1
    }

    Item {
        id:             instrument
        anchors.fill:   parent
        visible:        true


        QGCColoredImage {
            id:                 axes
            source:             "/qmlimages/3d_axes.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
            color:              "Gray"
            transform: Rotation {
                origin.x:       axes.width  / 2
                origin.y:       axes.height / 2
                angle:          0
            }
        }
    }

    Rectangle {
        id:             mask
        anchors.fill:   instrument
        radius:         width / 2
        color:          "black"
        visible:        false
    }

    OpacityMask {
        anchors.fill:   instrument
        source:         instrument
        maskSource:     mask
    }

}
