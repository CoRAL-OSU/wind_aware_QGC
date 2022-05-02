/**
 * @file
 *   @brief Displays wind velocity information to operator using gradient bars and compass.
 *   @author Max DeSantis <max.desantis@okstate.edu>
 */

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
    id: root
    property var  vehicle:              null
    property real _windSpeed:           vehicle ? vehicle.wind.speed.rawValue : 0
    property real _windHeading:         vehicle ? vehicle.wind.direction.rawValue: 0
    property real _windHeadingRad:      (Math.PI / 180.0) * _windHeading
    property real _windSpeedDown:       vehicle ? vehicle.wind.verticalSpeed.rawValue: 0
    property real _windSpeedNorth:      vehicle ? _windSpeed * Math.cos(_windHeadingRad) : 0
    property real _windSpeedEast:       vehicle ? _windSpeed * Math.sin(_windHeadingRad) : 0
    property real _windSpeedPlanar:     vehicle ? Math.sqrt(Math.pow(_windSpeedNorth, 2) + Math.pow(_windSpeedEast,2)) : 0 // Planar refers to NE wind, with no D component
    property real _verticalMaxSpeed:    5.0
    property color eastArrowColor:      Qt.rgba(1, 0, 0, 1)
    property color northArrowColor:     Qt.rgba(0, 1, 0, 1)
    property color verticalArrowColor:  Qt.rgba(0, 0, 1, 1)
    property real _planarMaxSpeed:      15.0
    property bool showAircraftHeading:  false
    property real _radius:              planarHeadingDial.radius
    on_WindSpeedChanged: { // Updates compass and gradients when new wind velocities arrive.
        eastHeadingArrow.draw()
        northHeadingArrow.draw()
        verticalWindSpeedIndicator.draw()
    }


    Rectangle {
        id:                 instrumentLabel
        anchors.top:        parent.top
        anchors.topMargin:  3
        anchors.left:       parent.left
        anchors.right:      parent.right
        height:             1/5 * parent.height
        color:              qgcPal.window

        RowLayout {
            id:             infoLayout
            anchors.fill:   parent
            spacing:        3

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: _root.width / 5
                color:              qgcPal.window
                border.color:       qgcPal.text
                radius:             10
                QGCLabel {
                    id:                     planarSpeedValue
                    anchors.centerIn:       parent
                    text:                   qsTr(_windSpeedPlanar.toFixed(1))
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: _root.width / 5
                color:              qgcPal.window
                border.color:       qgcPal.text
                radius:             10
                QGCLabel {
                    id:                     northSpeedValue
                    anchors.centerIn:       parent
                    text:                   "N: " + qsTr(_windSpeedNorth.toFixed(1))
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: _root.width / 5
                color:              qgcPal.window
                border.color:       qgcPal.text
                radius:             10
                QGCLabel {
                    id:                     eastSpeedValue
                    anchors.centerIn:       parent
                    horizontalAlignment:    Text.AlignHCenter
                    text:                   "E: " + qsTr(_windSpeedEast.toFixed(1))
                }
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: _root.width / 5
                color:              qgcPal.window
                border.color:       qgcPal.text
                radius:             10
                QGCLabel {
                    id:                     verticalSpeedValue
                    anchors.centerIn:       parent
                    horizontalAlignment:    Text.AlignHCenter
                    text:                   "D: " + qsTr(_windSpeedDown.toFixed(1))
                }
            }
        }


    }

    // Compass, heading arrow and magnitude, aircraft heading
    Item {
        id:             planarHeadingArea
        anchors.left:   parent.left
        anchors.top:    instrumentLabel.bottom
        width:          height
        height:         parent.height * (3/4)

        // Compass Enclosing
        Rectangle {
            id:                         planarHeadingDial
            anchors.top:                parent.top
            anchors.bottom:             parent.bottom
            anchors.left:               parent.left
            anchors.margins:            4
            width:                      height
            radius:                     width / 2
            color:                      qgcPal.window
            border.color:               qgcPal.text
            border.width:               1

            // Compass Image
            QGCColoredImage {
                id:                 planarHeadingDialImage
                source:             "/qmlimages/compassInstrumentDial.svg"
                mipmap:             true
                fillMode:           Image.PreserveAspectFit
                anchors.fill:       parent
                sourceSize.height:  parent.height
                color:              qgcPal.text

                transform: Rotation {
                    origin.x:       planarHeadingDialImage.width  / 2
                    origin.y:       planarHeadingDialImage.height / 2
                    angle:          0
                }
            }

            QGCWindDial {
                id:             eastHeadingArrow
                anchors.fill:   planarHeadingDial
                arrowLength:    Math.abs(_windSpeedEast * (width / (2*_planarMaxSpeed)))
                arrowAngle:     (_windSpeedEast >= 0) ? Math.PI  / 2 : (3 * Math.PI  / 2)
                arrowColor:     eastArrowColor
                arrowLineWidth: 5
            }

            QGCWindDial {
                id:             northHeadingArrow
                anchors.fill:   planarHeadingDial
                arrowLength:    Math.abs(_windSpeedNorth * (width / (2*_planarMaxSpeed)))
                arrowAngle:     (_windSpeedNorth >= 0) ? 0.0 : Math.PI
                arrowColor:     northArrowColor
                arrowLineWidth: 5
            }

            // Aircraft heading indicator
            Image {
                id:                 planarHeadingPointer
                width:              parent.width * 0.3
                source:             vehicle ? vehicle.vehicleImageCompass : ""
                mipmap:             true
                sourceSize.width:   width
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   parent
                visible:            showAircraftHeading
                transform: Rotation {
                    origin.x:       planarHeadingPointer.width  / 2
                    origin.y:       planarHeadingPointer.height / 2
                    angle:          vehicle ? vehicle.heading.rawValue : 0
                }
            }
        }

    } // Compass

    Item {
        id: verticalIndicator
        anchors.top: planarHeadingArea.top
        anchors.bottom: planarHeadingArea.bottom
        anchors.right: parent.right
        anchors.left: planarHeadingArea.right

        QGCVerticalWindIndicator {
            id:                     verticalWindSpeedIndicator
            anchors.fill:           parent
            verticalWindSpeed:      _windSpeedDown
            verticalWindSpeedMax:   _verticalMaxSpeed
            //verticalArrowColor: verticalArrowColor
        }


    }

}
