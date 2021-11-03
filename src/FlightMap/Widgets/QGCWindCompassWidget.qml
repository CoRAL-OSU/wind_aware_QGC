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
    property real _windSpeedDown
    property real _windSpeedNorth
    property real _windSpeedEast

    property alias compass: compassDial

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

        // Broken somewhere in here.

//        Rectangle {
//            id:                         northLabel
//            anchors.top:                parent.top
//            anchors.horizontalCenter:   parent.horizontalCenter

//            width:              size * 0.2
//            height:             size * 0.1
//            border.color:       qgcPal.text
//            color:              qgcPal.window
//            opacity:            1
//            visible:            true

//            QGCLabel {
//                text: _windSpeedNorth.toFixed(1)
//                color: qgcPal.text
//                anchors.centerIn: parent
//            }
//        }

        QGCColoredImage {
            id:                 compassDial
            source:             "/qmlimages/compassInstrumentDial.svg"
            mipmap:             true
            fillMode:           Image.PreserveAspectFit
            anchors.fill:       parent
            sourceSize.height:  parent.height
            color:              qgcPal.text
            transform: Rotation {
                origin.x:       compassDial.width  / 2
                origin.y:       compassDial.height / 2
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
