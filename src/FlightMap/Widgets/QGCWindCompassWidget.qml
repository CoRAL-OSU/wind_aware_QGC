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


        Image {
            id:                 windPointer
            width:              parent.width / 10
            source:             "/qmlimages/windInstrumentArrow.svg"
            mipmap:             true
            sourceSize.width:   width //Unsure if need a better way to scale this
            sourceSize.height:  height
            fillMode:           Image.PreserveAspectFit
            anchors.centerIn:   parent
            transform: Rotation {
                origin.x:       windPointer.width / 2
                origin.y:       windPointer.height / 2
                angle:          _windHeading
            }
        }


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
                angle:          isNoseUpLocked()?-_heading:0
            }
        }


        Rectangle {
            anchors.centerIn:   parent
            width:              size * 0.2
            height:             size * 0.1
            border.color:       qgcPal.text
            color:              qgcPal.window
            opacity:            0.2

            QGCLabel {
                text:               _headingString3
                font.family:        vehicle ? ScreenTools.demiboldFontFamily : ScreenTools.normalFontFamily
                font.pointSize:     _fontSize < 8 ? 8 : _fontSize;
                color:              qgcPal.text
                anchors.centerIn:   parent

                property string _headingString: vehicle ? _windHeading.toFixed(0) : "OFF"
                property string _headingString2: _headingString.length === 1 ? "0" + _headingString : _headingString
                property string _headingString3: _headingString2.length === 2 ? "0" + _headingString2 : _headingString2
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
