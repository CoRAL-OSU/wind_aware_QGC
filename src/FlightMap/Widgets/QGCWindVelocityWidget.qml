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

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Item {
        id:             instrument
        anchors.fill:   parent
        visible:        true

        // Added by Max. Display wind velocity as text underneath rest of instrument cluster.
        // Will want to somehow handle unit conversions, like how the rest of QGC does.

        QGCLabel {
            id: windVelocityNameLabel
            anchors.left: parent.left
            anchors.leftMargin: 20
            text: "Wind Velocity"
            color: "white"
        }

        QGCLabel {
            id: windVelocityValueLabel
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.top: windVelocityNameLabel.bottom
            text: _windSpeedNorth.toFixed(2) + " N " + _windSpeedEast.toFixed(2) + " E " + _windSpeedDown.toFixed(2) + " D "
            color: "white"
        }
        QGCLabel {
            id: windDirValueLabel
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.top: windVelocityValueLabel.bottom
            text: _windSpeed.toFixed(2) + " m/s " + _windHeading.toFixed(2) + " deg"
            color: "white"
        }
//        QGCLabel {
//            id: windVertSpeedValueLabel
//            anchors.left: parent.left
//            anchors.leftMargin: 20
//            anchors.top: windDirValueLabel.bottom
//            text: _windHeadingRad + " (rad) "
//            color: "white"
//        }

        QGCWindCompassWidget {
            id: windCompass
            vehicle: root.vehicle
            height: root.height
            width: windCompass.height
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }
}
