/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.14
import QtQuick.Layouts  1.14

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.FactSystem    1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.Palette       1.0

ColumnLayout {
    id:         root
    spacing:    ScreenTools.defaultFontPixelHeight / 4

    property real   _innerRadius:           (width - (_topBottomMargin * 3)) / 4
    property real   _outerRadius:           _innerRadius + _topBottomMargin
    property real   _spacing:               ScreenTools.defaultFontPixelHeight * 0.33
    property real   _topBottomMargin:       (width * 0.05) / 2

    QGCPalette { id: qgcPal }

    Rectangle {
        id:                 visualInstrument
        height:             _outerRadius * 2
        Layout.fillWidth:   true
        radius:             _outerRadius
        color:              qgcPal.window

        DeadMouseArea { anchors.fill: parent }

        QGCAttitudeWidget {
            id:                     attitude
            anchors.leftMargin:     _topBottomMargin
            anchors.left:           parent.left
            size:                   _innerRadius * 2
            vehicle:                globals.activeVehicle
            anchors.verticalCenter: parent.verticalCenter
        }

        QGCCompassWidget {
            id:                     compass
            anchors.leftMargin:     _spacing
            anchors.left:           attitude.right
            size:                   _innerRadius * 2
            vehicle:                globals.activeVehicle
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Adds separate wind velocity display information to Flight Map
    Rectangle {
        id:                 windInstrument
        height:             4*_outerRadius
        Layout.fillWidth:   true
        color:              qgcPal.window
        //border.color:       qgcPal.text
        radius:             windWidget._radius / 4

        DeadMouseArea { anchors.fill: parent }

        property Item selectedDisplayType: windWidget

        QGCLabel {
            id:                     windDisplayLabel
            text:                   "Wind Conditions"
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.top:            parent.top
            height:                 _outerRadius / 2
            horizontalAlignment:   Text.AlignHCenter
            verticalAlignment:     Text.AlignVCenter
        }

        QGCComboBox {
            id:                 windDisplayComboBox
            anchors.top:        windDisplayLabel.bottom
            anchors.left:       parent.left
            anchors.right:      parent.right
            height:             _outerRadius / 2


            textRole:           "text"
            valueRole:          "value"

            onActivated:        parent.selectedDisplayType = currentValue
            Component.onCompleted: currentIndex = indexOfValue(parent.selectedDisplayType)

            model: [
                {value: windWidget, text: qsTr("Gradient") },
                {value: compass_2d, text: qsTr("2D Compass") }
            ]
        }

        Item {
            id: windWidgetDisplaySpace
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            anchors.top:    windDisplayComboBox.bottom

            QGCPlanarWindDisplay {
                id:                     compass_2d
                anchors.fill:           parent
                visible:                windInstrument.selectedDisplayType === this
            }
            QGCWindWidget {
                id:                     compass_3d
                anchors.fill:           parent
                visible:                windInstrument.selectedDisplayType === this
            }

            QGCWindWidget {
                id:                     windWidget
                vehicle:                globals.activeVehicle
                anchors.fill:           parent
                visible:                windInstrument.selectedDisplayType === this
            }

            Rectangle {
                id:                     testRect
                anchors.fill:           parent
                visible:                windInstrument.selectedDisplayType === this
                color:                  qgcPal.brandingBlue
            }
        }



    }



    TerrainProgress {
        Layout.fillWidth: true
    }
}
