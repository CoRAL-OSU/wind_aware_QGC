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
 *   @brief QGC Wind Velocity Instrument
 *   @author Max DeSantis
 */

import QtQuick              2.3
import QtGraphicalEffects   1.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controllers   1.0

Item {
    id: root

    property var  vehicle:            null
    property real _windSpeed:         vehicle ? vehicle.wind.speed.rawValue : 0
    property real _windHeading:       vehicle ? vehicle.wind.direction.rawValue: 0
    property real _windHeadingRad:    (Math.PI / 180.0) * _windHeading
    property real _windSpeedDown:     vehicle ? vehicle.wind.verticalSpeed.rawValue: 0
    property real _windSpeedNorth:    vehicle ? _windSpeed * Math.cos(_windHeadingRad) : 0
    property real _windSpeedEast:     vehicle ? _windSpeed * Math.sin(_windHeadingRad) : 0
    property string _widgetChoice:    qsTr("Heading Compass")

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Item {
        id:             instrument
        anchors.fill:   parent
        visible:        true

        QGCComboBox {
            id:             displayCombo
            model:          [qsTr("Heading Compass"), qsTr("Component Compass"), qsTr("3D Component Compass")]
            width:          parent.width
            anchors.top:    parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            onActivated: {
                _widgetChoice = textAt(currentIndex)
            }
        }

        Item {
            id:             component_compass_3d
            anchors.top:    displayCombo.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            visible:        _widgetChoice === qsTr("3D Component Compass")

            QGC3dAxes {
                id: windAxes_3dc
                vehicle: root.vehicle
                height: root.height - displayCombo.height
                width: height // Square
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: parseInt(0.5*displayCombo.height)
                anchors.right: parent.right
            }

            Image {
                id:                 windPointer_north_3d
                width:              (windAxes_3dc.width / 10) * (1/10) * Math.abs(_windSpeedNorth)
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
                sourceSize.height:  windAxes_3dc.axes.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windAxes_3dc
                transform: Rotation {
                    origin.x:       windPointer_north_3d.width / 2
                    origin.y:       windPointer_north_3d.height / 2
                    angle:          (_windSpeedNorth >= 0) ? 45 : 225
                }
            }

            Image {
                id:                 windPointer_east_3d
                width:              (windAxes_3dc.width / 10) * (1/10) * Math.abs(_windSpeedEast)
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
                sourceSize.height:  windAxes_3dc.axes.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windAxes_3dc
                transform: Rotation {
                    origin.x:       windPointer_east_3d.width / 2
                    origin.y:       windPointer_east_3d.height / 2
                    angle:          (_windSpeedEast >= 0) ? 90 : 270
                }
            }

            Image {
                id:                 windPointer_down_3d
                width:              (windAxes_3dc.width / 10) * (1/10) * Math.abs(_windSpeedDown)
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
                sourceSize.height:  windAxes_3dc.axes.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windAxes_3dc
                transform: Rotation {
                    origin.x:       windPointer_down_3d.width / 2
                    origin.y:       windPointer_down_3d.height / 2
                    angle:          (_windSpeedDown >= 0) ? 180 : 0
                }
            }

        }


        Item {
            id:             component_compass
            anchors.top:    displayCombo.bottom
            anchors.left:   parent.left
            anchors.right: parent.right
            visible:        _widgetChoice === qsTr("Component Compass")

            QGCLabel {
                id: windVelocityNameLabel_cc
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: "Wind (m/s)"
                color: "white"
            }

            QGCLabel {
                id: windVelocityValueLabel_cc
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.top: windVelocityNameLabel_cc.bottom
                text: _windSpeedNorth.toFixed(1) + "N " + _windSpeedEast.toFixed(1) + "E " + _windSpeedDown.toFixed(1) + "D "
                color: "white"
            }
            QGCLabel {
                id: windDirValueLabel_cc
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.top: windVelocityValueLabel_cc.bottom
                text: _windSpeed.toFixed(2) + " m/s " + _windHeading.toFixed(2) + " deg"
                color: "white"
            }

            // Compass Image
            QGCWindCompassWidget {
                id: windCompass_cc
                vehicle: root.vehicle
                height: root.height - displayCombo.height
                width: height // Square
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: parseInt(0.5*displayCombo.height)
                anchors.right: parent.right
            }

            // North arrow
            Image {
                id:                 windPointer_north_cc
                width:              (windCompass_cc.width / 10) * (1/10) * Math.abs(_windSpeedNorth)
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windCompass_cc.compass.width //Unsure if need a better way to scale this
                sourceSize.height:  windCompass_cc.compass.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windCompass_cc
                transform: Rotation {
                    origin.x:       windPointer_north_cc.width / 2
                    origin.y:       windPointer_north_cc.height / 2
                    angle:          (_windSpeedNorth >= 0) ? 0 : 180
                }
            }

            // East Arrow
            Image {
                id:                 windPointer_east_cc
                width:              (windCompass_cc.width / 10) * (1/10) * Math.abs(_windSpeedEast)
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windCompass_cc.compass.width //Unsure if need a better way to scale this
                sourceSize.height:  windCompass_cc.compass.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windCompass_cc
                transform: Rotation {
                    origin.x:       windPointer_east_cc.width / 2
                    origin.y:       windPointer_east_cc.height / 2
                    angle:          (_windSpeedEast >= 0) ? 90 : 270
                }
            }

            ColorOverlay {
                anchors.fill: windPointer_east_cc
                source: windPointer_east_cc
                color: "green"
                cached: false
                transform: Rotation {
                    origin.x:       windPointer_east_cc.width / 2
                    origin.y:       windPointer_east_cc.height / 2
                    angle:          (_windSpeedEast >= 0) ? 90 : 270
                }
            }


        }


        // Wind compass instrument
        Item {
            id:             heading_compass
            anchors.top:    displayCombo.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            visible:        _widgetChoice === qsTr("Heading Compass")

            // Added by Max. Display wind velocity as text underneath rest of instrument cluster.
            // Will want to somehow handle unit conversions, like how the rest of QGC does.

            QGCLabel {
                id: windVelocityNameLabel_hc
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: "Wind (m/s)"
                color: "white"
            }

            QGCLabel {
                id: windVelocityValueLabel_hc
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.top: windVelocityNameLabel_hc.bottom
                text: _windSpeedNorth.toFixed(1) + "N " + _windSpeedEast.toFixed(1) + "E " + _windSpeedDown.toFixed(1) + "D "
                color: "white"
            }
            QGCLabel {
                id: windDirValueLabel_hc
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.top: windVelocityValueLabel_hc.bottom
                text: _windSpeed.toFixed(2) + " m/s " + _windHeading.toFixed(2) + " deg"
                color: "white"
            }

            // Compass Image
            QGCWindCompassWidget {
                id: windCompass_hc
                vehicle: root.vehicle
                height: root.height - displayCombo.height
                width: height // Square
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: parseInt(0.5*displayCombo.height)
                anchors.right: parent.right
            }

            // Add arrow
            Image {
                id:                 windPointer_hc
                width:              (windCompass_hc.width / 10) * (1/10) * _windSpeed
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windCompass_hc.compass.width //Unsure if need a better way to scale this
                sourceSize.height:  windCompass_hc.compass.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windCompass_hc
                transform: Rotation {
                    origin.x:       windPointer_hc.width / 2
                    origin.y:       windPointer_hc.height / 2
                    angle:          _windHeading
                }
            }

        }

    }
}
