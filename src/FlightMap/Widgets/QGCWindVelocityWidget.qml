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

Item {
    id: root

    property var  vehicle:      null
    property var windVelocity:  vehicle ? vehicle.wind.speed.rawValue : 0
    //property var windVelocity: vehicle? vehicle.roll.rawValue : 0

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    Item {
        id:             instrument
        anchors.fill:   parent
        visible:        true

        // Added by Max. Display wind velocity as text underneath rest of instrument cluster.
        // Will want to somehow handle unit conversions, like how the rest of QGC does.

        QGCLabel {
            id: windVelocityNameLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Wind Velocity (m/s)"
            color: "white"
        }

        QGCLabel {
            id: windVelocityValueLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: windVelocityNameLabel.bottom
            text: windVelocity
            color: "white"
        }
    }
}
