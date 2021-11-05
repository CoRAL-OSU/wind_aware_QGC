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
import QGroundControl.Vehicle      1.0

Item {
    id: root
    property Item rt: root
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

    on_WindSpeedChanged: {
        headingCompassArrow.draw();
        verticalCompassArrow.draw();
        northComponentArrow.draw();
        eastComponentArrow.draw();
        north3dComponentArrow.draw();
        east3dComponentArrow.draw();
        down3dComponentArrow.draw();
    }


    Item {
        id:             instrument
        anchors.fill:   parent
        visible:        true


        // Selection box for display type
        QGCComboBox {
            id:             displayCombo
            model:          [qsTr("Heading Compass"), qsTr("Component Compass"), qsTr("3D Component Compass")]
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            onActivated: {
                _widgetChoice = textAt(currentIndex)
            }
        }

        // Shows MAG DIR info on top
        Item {
            id:             magDirCluster
            anchors.top:    displayCombo.bottom
            anchors.left:   parent.left
            width:          parent.width * (2/3)
            height:         parent.height / 5

            // MAG DIR layout on top
            RowLayout {
                id: magDirRow
                anchors.fill:   parent
                anchors.topMargin:      5
                spacing:                5
                anchors.bottomMargin:   10
                anchors.leftMargin:     5
                anchors.rightMargin:    15
                // mag rect and label
                Rectangle {
                    id:                 magRect
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius:             width / 4
                    QGCLabel {
                        id:                 magLabel
                        text:               _windSpeed.toFixed(1) + " m/s"
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }

                Rectangle {
                    id:                 dirRect
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    radius:             width /4
                    QGCLabel {
                        id:                 dirLabel
                        text:               _windHeading.toFixed() + " deg"
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }
            }
        }

        Rectangle {
            id:                         dial
            anchors.top:                magDirCluster.bottom
            anchors.bottom:             nedCluster.top
            anchors.horizontalCenter:   magDirCluster.horizontalCenter
            width:                      height
            radius:                     width / 2
            color:                      qgcPal.window
            border.color:               qgcPal.text
            border.width:               1

            QGCColoredImage {
                id:                 dialImage
                source:             (_widgetChoice !== qsTr("3D Component Compass")) ? "/qmlimages/compassInstrumentDial.svg" : "/qmlimages/3d_axes.svg"
                mipmap:             true
                fillMode:           Image.PreserveAspectFit
                anchors.fill:       parent
                sourceSize.height:  parent.height
                color:              qgcPal.text

                transform: Rotation {
                    origin.x:       dialImage.width  / 2
                    origin.y:       dialImage.height / 2
                    angle:          0
                }
            }
        }

        Rectangle {
            id: verticalCompass
            anchors.top:        magDirCluster.bottom
            anchors.bottom:     nedCluster.top
            anchors.right:      parent.right
            width:              parent.width / 3
            color:              qgcPal.window
            anchors.rightMargin: 5
            visible: _widgetChoice !== qsTr("3D Component Compass")

            QGCColoredImage {
                id:                 verticalCompassImage
                source:             "/qmlimages/1d_axis.svg"
                mipmap:             true
                fillMode:           Image.PreserveAspectFit
                anchors.fill:       parent
                sourceSize.height:  parent.height
                color:              qgcPal.text
                anchors.rightMargin: 3

                transform: Rotation {
                    origin.x:       verticalCompassImage.width  / 2
                    origin.y:       verticalCompassImage.height / 2
                    angle:          0
                }
            }
        }




        Item {
            id: nedCluster

            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height:         parent.height / 5

            // N E D layout on bottom
            RowLayout {
                id: nedRow
                anchors.fill:   parent
                anchors.topMargin: 10
                spacing: 5
                anchors.bottomMargin: 5
                anchors.leftMargin: 5
                anchors.rightMargin: 5

                Rectangle {
                    id:                 northRect
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    radius:             width / 4
                    QGCLabel {
                        id:                 northLabel
                        text:               "N: " + _windSpeedNorth.toFixed(1)
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }

                Rectangle {
                    id:                 eastRect
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    radius:             width / 4
                    QGCLabel {
                        id:                 eastLabel
                        text:               "E: " + _windSpeedEast.toFixed(1)
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }

                Rectangle {
                    id:                 downRect
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    border.color:       qgcPal.text
                    color:              qgcPal.window
                    radius:             width / 4
                    QGCLabel {
                        id:                 downLabel
                        text:               "D: " + _windSpeedDown.toFixed(1)
                        color:              qgcPal.text
                        anchors.centerIn:   parent
                    }
                }
            }

        }

        //on_WindSpeedChanged: verticalArrow.drawArrow( Math.abs(_windSpeedDown) * (verticalBar_hd.height / 2) / 4, (_windSpeedDown >= 0) ? Math.PI : 0)
        QGCWindDial {
            id: headingCompassArrow
            anchors.fill:   dial
            visible:        (_widgetChoice !== qsTr("Component Compass") && _widgetChoice !== qsTr("3D Component Compass"))
            arrowLength: Math.sqrt(Math.pow(_windSpeedEast, 2) + Math.pow(_windSpeedNorth, 2)) * (dial.width / 2) / 14
            arrowAngle: _windHeadingRad
        }

        QGCWindDial {
            id: verticalCompassArrow
            anchors.fill: verticalCompass
            visible: _widgetChoice !== qsTr("3D Component Compass")
            arrowLength: Math.abs(_windSpeedDown) * verticalCompass.width / 2 / 4
            arrowAngle: (_windSpeedDown >= 0) ? Math.PI : 0
        }

        QGCWindDial {
            id: northComponentArrow
            anchors.fill:   dial
            visible:        _widgetChoice === qsTr("Component Compass")
            arrowLength: Math.abs(_windSpeedNorth) * (dial.width / 2) / 14
            arrowAngle: (_windSpeedNorth > 0) ? 0 : Math.PI
            arrowColor: Qt.rgba(0, 0, 1, 1)
        }

        QGCWindDial {
            id: eastComponentArrow
            anchors.fill:   dial
            visible:        _widgetChoice === qsTr("Component Compass")
            arrowLength: Math.abs(_windSpeedEast) * (dial.width / 2) / 14
            arrowAngle: (_windSpeedEast > 0) ? (Math.PI / 2) : (3*Math.PI / 2)
            arrowColor: Qt.rgba(0, 1, 0, 1)
        }

        QGCWindDial {
            id: north3dComponentArrow
            anchors.fill:   dial
            visible:        _widgetChoice === qsTr("3D Component Compass")
            arrowLength:    Math.abs(_windSpeedNorth) * (dial.width / 2) / 14
            arrowAngle:     (_windSpeedNorth > 0) ? (Math.PI / 4) : (5*Math.PI / 4)
            arrowColor:     Qt.rgba(0, 0, 1, 1)
        }

        QGCWindDial {
            id: east3dComponentArrow
            anchors.fill:   dial
            visible:        _widgetChoice === qsTr("3D Component Compass")
            arrowLength: Math.abs(_windSpeedEast) * (dial.width / 2) / 14
            arrowAngle: (_windSpeedEast > 0) ? (Math.PI / 2) : (3*Math.PI / 2)
            arrowColor: Qt.rgba(0, 1, 0, 1)
        }

        QGCWindDial {
            id: down3dComponentArrow
            anchors.fill:   dial
            visible:        _widgetChoice === qsTr("3D Component Compass")
            arrowLength: Math.abs(_windSpeedDown) * (dial.width / 2) / 14
            arrowAngle: (_windSpeedDown > 0) ? (Math.PI) : 0
            arrowColor: Qt.rgba(1, 0, 0, 1)
        }


//        Item {
//            id:             component_compass_3d
//            anchors.left:   parent.horizontalCenter
//            anchors.right:  parent.right
//            anchors.top:    displayCombo.bottom
//            visible:        _widgetChoice === qsTr("3D Component Compass")

//            QGC3dAxes {
//                id: windAxes_3dc
//                vehicle: root.vehicle
//                width: parent.width // Square
//                opacity: .5
//                height: width
//                anchors.top: parent.top
//                anchors.right: parent.right

//            }

//            Image {
//                id:                 windPointer_north_3d
//                //width:              (windAxes_3dc.width / windRange) / 4 * Math.abs(_windSpeedNorth)
//                width:              map(Math.abs(_windSpeedNorth), 0, windRange, 0, windAxes_3dc.width / 2) / (2*Math.sqrt(2))
//                source:             "/qmlimages/windInstrumentArrow.svg"
//                mipmap:             true
//                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
//                sourceSize.height:  windAxes_3dc.axes.height
//                fillMode:           Image.PreserveAspectFit
//                anchors.centerIn:   windAxes_3dc
//                rotation:           (_windSpeedNorth >= 0) ? 45 : 225
//            }

//            Image {
//                id:                 windPointer_east_3d
//                width:              map(Math.abs(_windSpeedEast), 0, windRange, 0, windAxes_3dc.width / 2) / (2*Math.sqrt(2))
//                source:             "/qmlimages/windInstrumentArrow.svg"
//                mipmap:             true
//                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
//                sourceSize.height:  windAxes_3dc.axes.height
//                fillMode:           Image.PreserveAspectFit
//                anchors.centerIn:   windAxes_3dc
//                rotation:           (_windSpeedEast >= 0) ? 90 : 270
//            }
//            ColorOverlay {
//                anchors.fill: windPointer_east_3d
//                source: windPointer_east_3d
//                color: "#6EFF7C"
//                cached: false
//                transform: Rotation {
//                    origin.x:       windPointer_east_3d.width / 2
//                    origin.y:       windPointer_east_3d.height / 2
//                    angle:          (_windSpeedEast >= 0) ? 90 : 270
//                }
//            }

//            Image {
//                id:                 windPointer_down_3d
//                width:              map(Math.abs(_windSpeedDown), 0, windRange, 0, windAxes_3dc.width / 2) / (2)
//                source:             "/qmlimages/windInstrumentArrow.svg"
//                mipmap:             true
//                sourceSize.width:   windAxes_3dc.axes.width //Unsure if need a better way to scale this
//                sourceSize.height:  windAxes_3dc.axes.height
//                fillMode:           Image.PreserveAspectFit
//                anchors.centerIn:   windAxes_3dc
//                rotation:           (_windSpeedDown >= 0) ? 180 : 0

//            }
//            ColorOverlay {
//                anchors.fill: windPointer_down_3d
//                source: windPointer_down_3d
//                color: "#FF7C6E"
//                cached: false
//                transform: Rotation {
//                    origin.x:       windPointer_down_3d.width / 2
//                    origin.y:       windPointer_down_3d.height / 2
//                    angle:          (_windSpeedDown >= 0) ? 180 : 0
//                }
//            }

//        }

    }
}
