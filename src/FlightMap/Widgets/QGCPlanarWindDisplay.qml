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
    property real _planarMaxSpeed:      15.0
    property color  _windPointerColor:  Qt.rgba(1, 0, 0, 1)
    property real _radius:              planarHeadingDial.radius
    on_WindSpeedChanged: { // Updates compass and gradients when new wind velocities arrive.
        planarHeadingArrow.draw();
        planarGradientCanvas.requestPaint();
        //verticalGradientCanvas.requestPaint();
    }
    Item {
        id:                 instrumentLabel
        anchors.right:      planarHeadingArea.left
        anchors.left:       parent.left
        anchors.top:        parent.top
        anchors.leftMargin: 3
        height:             parent.height

        QGCLabel {
            id:                     windLabel
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.top:            parent.top
            text:                   "Wind m/s"
            wrapMode:               Text.WrapAnywhere
            horizontalAlignment:    Text.AlignHCenter
        }

        QGCLabel {
            id:                     northSpeedLabel
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.top:            windLabel.bottom
            horizontalAlignment:    Text.AlignHCenter
            text:                   "NORTH"
        }
        QGCLabel {
            id:                     northSpeedValue
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.top:            northSpeedLabel.bottom
            horizontalAlignment:    Text.AlignHCenter
            text:                   _windSpeedNorth
        }
        QGCLabel {
            id:                     eastSpeedLabel
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.top:            northSpeedValue.bottom
            horizontalAlignment:    Text.AlignHCenter
            text:                   "EAST"
        }
        QGCLabel {
            id:                     eastSpeedValue
            anchors.left:           parent.left
            anchors.right:          parent.right
            anchors.top:            eastSpeedLabel.bottom
            horizontalAlignment:    Text.AlignHCenter
            text:                   _windSpeedEast
        }
    }

    // Compass, heading arrow and magnitude, aircraft heading
    Item {
        id:             planarHeadingArea
        anchors.right:  parent.right
        anchors.top:    parent.top
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
                id:             planarHeadingArrow
                anchors.fill:   planarHeadingDial
                arrowLength:    _windSpeedPlanar * (width / (2*_planarMaxSpeed))
                arrowAngle:     _windHeadingRad
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
                transform: Rotation {
                    origin.x:       planarHeadingPointer.width  / 2
                    origin.y:       planarHeadingPointer.height / 2
                    angle:          vehicle ? vehicle.heading.rawValue : 0
                }
            }
        }

        // Heading mag box
        Rectangle {
            id:                 planarHeadingBox
            anchors.left:       parent.left
            anchors.bottom:     parent.bottom
            anchors.margins:    5
            border.color:       qgcPal.text
            radius:             4
            color:              qgcPal.window
            width:              parent.width / 4.5
            height:             width * .65
            QGCLabel {
                id:                 planarHeadingLabel
                text:               _windHeading.toFixed(0).padStart(3, '0')
                color:              qgcPal.text
                anchors.centerIn:   parent
                anchors.margins:    1
            }
        }

    }

}
