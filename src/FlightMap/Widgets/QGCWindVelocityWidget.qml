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
import QtQuick.Layouts      1.0
import QtGraphicalEffects   1.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controllers   1.0

Item {
    id: root
    property real _width
    property real _height:            instrument.height
    property alias comboHeight:       displayCombo.height
    property var  vehicle:            null
    property real _windSpeed:         vehicle ? vehicle.wind.speed.rawValue : 0
    property real _windHeading:       vehicle ? vehicle.wind.direction.rawValue: 0
    property real _windHeadingRad:    (Math.PI / 180.0) * _windHeading
    property real _windSpeedDown:     vehicle ? vehicle.wind.verticalSpeed.rawValue: 0
    property real _windSpeedNorth:    vehicle ? _windSpeed * Math.cos(_windHeadingRad) : 0
    property real _windSpeedEast:     vehicle ? _windSpeed * Math.sin(_windHeadingRad) : 0
    property string _widgetChoice:    qsTr("Heading Compass")

    property real windRange:          12
    width:      _width

    QGCPalette { id: qgcPal; colorGroupEnabled: enabled }

    function map(input, inLow, inHigh, outLow, outHigh) {
            return outLow + ((outHigh - outLow) / (inHigh - inLow)) * (input - inLow);
    }

    on_WindSpeedNorthChanged: nePointer_hd.requestPaint()
    Item {
        id:             instrument
        anchors.fill:   parent
        visible:        true


        QGCComboBox {
            id:             displayCombo
            model:          [qsTr("Heading Compass"), qsTr("Component Compass"), qsTr("3D Component Compass"), qsTr("Heading and Down")]
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            onActivated: {
                _widgetChoice = textAt(currentIndex)
            }

        }

        Item {
            id:             heading_down
            anchors.top:    displayCombo.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            visible:        _widgetChoice === qsTr("Heading and Down")

            RowLayout {
                id: magDirRow_hd
                anchors.left:           parent.left
                anchors.top:            parent.top
                anchors.topMargin:      5
                width:                  parent.width * (2/3)
                height:                 parent.height / 7
                spacing:                5
                anchors.bottomMargin:   10
                anchors.leftMargin:     5
                anchors.rightMargin:    15
                // mag rect and label
                Rectangle {
                    id:                 magRect_hd
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius:             width / 4
                    QGCLabel {
                        id:                 magLabel_hd
                        text:               _windSpeed.toFixed() + " m/s"
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }

                // Dir rect and label
                Rectangle {
                    id:                 dirRect_hd
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius:             width /4
                    QGCLabel {
                        id:                 dirLabel_hd
                        text:               _windHeading.toFixed() + " deg"
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }
            }


            // Compass
            // Compass Image
            QGCWindCompassWidget {
                id:                 compass_hd
                vehicle:            root.vehicle
                width:              parent.width  / 2
                height:             width
                opacity:            1
                //anchors.left:       parent.left
                anchors.top:        magDirRow_hd.bottom
                anchors.topMargin:  5
                anchors.horizontalCenter: magDirRow_hd.horizontalCenter//  + Math.(dirRect_hd.left - magRect_hd.right) / 2
            }

            // Add compass arrow
//            Image {
//                id:                 pointer_hd
//                width:              (compass_hd.width / 10) * (1/10) * _windSpeed
//                source:             "/qmlimages/windInstrumentArrow.svg"
//                mipmap:             true
//                sourceSize.width:   compass_hd.compass.width
//                sourceSize.height:  compass_hd.compass.height
//                fillMode:           Image.PreserveAspectFit
//                anchors.centerIn:   compass_hd
//                rotation:           _windHeading
//            }

            Canvas {
                id: nePointer_hd
                anchors.fill:   compass_hd

                function drawCenterArrow(context, length, angle) {
                    var headLength = 10;
                    var startP = width / 2;
                    var endP = length + width / 2;


                    // Draw leg
                    context.lineWidth = 5;
                    context.strokeStyle = Qt.rgba(1, 0, 0, 1);
                    context.lineCap = "square";
                    context.clearRect(0, 0, width, height);
                    if(length > 0) {
                        context.beginPath();
                        context.translate(width/2, height/2);
                        context.rotate(angle);
                        context.translate(-width/2, -height/2);

                        context.moveTo(width/2, height/2);  // Start in center of canvas
                        context.lineTo(width/2, height/2 - length + 5); // Draw thick line from center to tip of "arrow". Account for line width
                        context.stroke();
                        context.beginPath();
                        context.moveTo(width/2, height/2 - length);
                        context.lineTo(width/2 + headLength, height/2 - length + headLength);
                        context.lineTo(width/2 - headLength, height/2 - length + headLength);
                        context.lineTo(width/2, height/2 - length);
                        context.fillStyle = Qt.rgba(1, 0, 0, 1);
                        context.fill();
                        context.closePath();
                        context.setTransform(1, 0, 0, 1, 0, 0);
                    }
                    else {
                        context.arc(width/2, height/2, 5, 0, 2*Math.PI);
                        context.fillStyle = Qt.rgba(1, 0, 0, 1);
                        context.fill();
                    }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.fillStyle = Qt.rgba(0, 0, 0, 1);
                    drawCenterArrow(ctx, Math.sqrt(Math.pow(_windSpeedEast, 2) + Math.pow(_windSpeedNorth, 2)) * (width / 2) / 14, _windHeadingRad);
                }

            }

            Image {
                id:                 verticalBar_hd
                //width:              parent.width
                source:             "/qmlimages/1d_axis.svg"
                mipmap:             true
                sourceSize.width:   parent.width / 3 - 10
                sourceSize.height:  compass_hd.height
                fillMode:           Image.PreserveAspectFit
                anchors.right:      parent.right
                anchors.rightMargin: 5
                width:              parent.width / 3 - 10
                anchors.top:        compass_hd.top
                anchors.bottom:     compass_hd.bottom
            }

            ColorOverlay {
                anchors.fill:   verticalBar_hd
                source:         verticalBar_hd
                color:          qgcPal.text
                cached:         false
            }

            Image {
                id:                 downPointer_hd
                width:              map(Math.abs(_windSpeedDown), 0, 5, 0, verticalBar_hd.height / 2) / 2
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   compass_hd.compass.width
                sourceSize.height:  compass_hd.compass.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   verticalBar_hd
                rotation:           (_windSpeedDown >= 0) ? 180 : 0
            }


            RowLayout {
                id: nedRow_hd
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top:    compass_hd.bottom
                anchors.topMargin: 10
                anchors.bottom: parent.bottom
                spacing: 5
                anchors.bottomMargin: 5
                anchors.leftMargin: 5
                anchors.rightMargin: 5
                // N rect and label
                Rectangle {
                    id:                 northRect_hd
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    radius:             width / 4
                    QGCLabel {
                        id:                 northLabel_hd
                        text:               "N: " + _windSpeedNorth.toFixed()
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }
                // E rect and Label
                Rectangle {
                    id:                 eastRect_hd
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    radius:             width / 4
                    QGCLabel {
                        id:                 eastLabel_hd
                        text:               "E: " + _windSpeedEast.toFixed()
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }
                // D rect and label
                Rectangle {
                    id:                 downRect_hd
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    radius:             width / 4
                    QGCLabel {
                        id:                 downLabel_hd
                        text:               "D: " + _windSpeedDown.toFixed()
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }
            }


        }

        Item {
            id: infoCluster1
            anchors.left: parent.left
            anchors.right: parent.horizontalCenter
            anchors.top: displayCombo.bottom
            visible: _widgetChoice !== qsTr("Heading and Down")

            QGCLabel {
                id: windVelocityLabel
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.right: parent.horizontalCenter
                anchors.top: parent.top
                text: "Wind NED (m/s)"
                color: "white"
            }

            QGCLabel {
                id: northVelocityLabel
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.right: parent.horizontalCenter
                anchors.top: windVelocityLabel.bottom
                text: "N: " + _windSpeedNorth.toFixed(1)
                color: "white"
            }
            QGCLabel {
                id: eastVelocityLabel
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.right: parent.horizontalCenter
                anchors.top: northVelocityLabel.bottom
                text: "E: " + _windSpeedEast.toFixed(1)
                color: "white"
            }
            QGCLabel {
                id: downVelocityLabel
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.right: parent.horizontalCenter
                anchors.top: eastVelocityLabel.bottom
                text: "D: " + _windSpeedDown.toFixed(1)
                color: "white"
            }
        }



        Item {
            id:             component_compass_3d
            anchors.left:   parent.horizontalCenter
            anchors.right:  parent.right
            anchors.top:    displayCombo.bottom
            visible:        _widgetChoice === qsTr("3D Component Compass")

            QGC3dAxes {
                id: windAxes_3dc
                vehicle: root.vehicle
                width: parent.width // Square
                opacity: .5
                height: width
                anchors.top: parent.top
                anchors.right: parent.right

            }

            Image {
                id:                 windPointer_north_3d
                //width:              (windAxes_3dc.width / windRange) / 4 * Math.abs(_windSpeedNorth)
                width:              map(Math.abs(_windSpeedNorth), 0, windRange, 0, windAxes_3dc.width / 2) / (2*Math.sqrt(2))
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
                sourceSize.height:  windAxes_3dc.axes.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windAxes_3dc
                rotation:           (_windSpeedNorth >= 0) ? 45 : 225
            }

            Image {
                id:                 windPointer_east_3d
                width:              map(Math.abs(_windSpeedEast), 0, windRange, 0, windAxes_3dc.width / 2) / (2*Math.sqrt(2))
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
                sourceSize.height:  windAxes_3dc.axes.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windAxes_3dc
                rotation:           (_windSpeedEast >= 0) ? 90 : 270
            }
            ColorOverlay {
                anchors.fill: windPointer_east_3d
                source: windPointer_east_3d
                color: "#6EFF7C"
                cached: false
                transform: Rotation {
                    origin.x:       windPointer_east_3d.width / 2
                    origin.y:       windPointer_east_3d.height / 2
                    angle:          (_windSpeedEast >= 0) ? 90 : 270
                }
            }

            Image {
                id:                 windPointer_down_3d
                width:              map(Math.abs(_windSpeedDown), 0, windRange, 0, windAxes_3dc.width / 2) / (2)
                source:             "/qmlimages/windInstrumentArrow.svg"
                mipmap:             true
                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
                sourceSize.height:  windAxes_3dc.axes.height
                fillMode:           Image.PreserveAspectFit
                anchors.centerIn:   windAxes_3dc
                rotation:           (_windSpeedDown >= 0) ? 180 : 0

            }
            ColorOverlay {
                anchors.fill: windPointer_down_3d
                source: windPointer_down_3d
                color: "#FF7C6E"
                cached: false
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
            anchors.left:   parent.horizontalCenter
            anchors.right: parent.right
            visible:        _widgetChoice === qsTr("Component Compass")

            // Compass Image
            QGCWindCompassWidget {
                id: windCompass_cc
                vehicle: root.vehicle
                width: parent.width // Square
                height: width
                opacity: .5
                anchors.top: parent.top
                anchors.right: parent.right
                _windSpeedNorth: root._windSpeedNorth
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
            anchors.left:   parent.horizontalCenter
            anchors.right:  parent.right
            visible:        _widgetChoice === qsTr("Heading Compass")

            // Compass Image
            QGCWindCompassWidget {
                id: windCompass_hc
                vehicle: root.vehicle
                //height: root.height - displayCombo.height
                width: parent.width // Square
                height: width
                opacity: .5
                anchors.top: parent.top
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
