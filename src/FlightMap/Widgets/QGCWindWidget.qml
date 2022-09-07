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
    property real _windSpeed:           6.0 //vehicle ? vehicle.wind.speed.rawValue : 0
    property real _windHeading:         160 //vehicle ? vehicle.wind.direction.rawValue: 0
    property real _windHeadingRad:      (Math.PI / 180.0) * _windHeading
    property real _windSpeedDown:       2.0 //vehicle ? vehicle.wind.verticalSpeed.rawValue: 0
    property real _windSpeedNorth:      _windSpeed * Math.cos(_windHeadingRad) //vehicle ? _windSpeed * Math.cos(_windHeadingRad) : 0
    property real _windSpeedEast:       _windSpeed * Math.sin(_windHeadingRad) //vehicle ? _windSpeed * Math.sin(_windHeadingRad) : 0
    property real _windSpeedPlanar:     Math.sqrt(Math.pow(_windSpeedNorth, 2) + Math.pow(_windSpeedEast,2)) //vehicle ? Math.sqrt(Math.pow(_windSpeedNorth, 2) + Math.pow(_windSpeedEast,2)) : 0 // Planar refers to NE wind, with no D component
    property real _verticalMaxSpeed:    5.0
    property real _planarMaxSpeed:      15.0
    property color  _windPointerColor:  Qt.rgba(1, 0, 0, 1)
    property color  _gradientBarColor:  Qt.rgba(0, 0, 1, 1)
    property color _gradientBarOutlineColor: Qt.rgba(1, 1, 1, 1)
    property real _radius:              planarHeadingDial.radius
    property int dialArrowStyle:        QGCWindDial.ArrowStyle.Inner

    on_WindSpeedChanged: { // Updates compass and gradients when new wind velocities arrive.
        planarHeadingArrow.draw();
        planarGradientCanvas.requestPaint();
        verticalGradientCanvas.requestPaint();
    }

    function getArrowLength() {
        if(_windSpeedPlanar < 0.5) return 0;

        if(dialArrowStyle === QGCWindDial.ArrowStyle.Inner) {
            return planarHeadingDial.width / 3
        }
        else {
            return planarHeadingDial.width / 5
        }
    }

    function getArrowHeading() {
        if(dialArrowStyle === QGCWindDial.ArrowStyle.Inner) {
            return _windHeadingRad;
        }
        else {
            return (_windHeadingRad + Math.PI) % (2*Math.PI)
        }
    }

    // Compass, heading arrow and magnitude, aircraft heading
    Item {
        id:             planarHeadingArea
        anchors.right:  verticalMagnitudeArea.left

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
                style:          dialArrowStyle
                arrowLength:    root.getArrowLength()
                arrowAngle:     root.getArrowHeading() //(dialArrowStyle === QGCWindDial.ArrowStyle.Inner) ? _windHeadingRad : (_windHeadingRad + Math.PI) % (2*Math.PI)

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
                text:               (root.getArrowHeading() * 180 / Math.PI).toFixed(0).padStart(3, '0')
                color:              qgcPal.text
                anchors.centerIn:   parent
                anchors.margins:    1
            }
        }

    }

    // Gradient with wind magnitude North and East
    Rectangle {
        id: planarMagnitudeArea
        anchors.left:   parent.left
        anchors.right:  verticalMagnitudeArea.left
        anchors.top:    planarHeadingArea.bottom
        anchors.bottom: parent.bottom
        anchors.margins: 5
        color:          qgcPal.window
        border.color:   qgcPal.text
        radius:                     height / 8
        // Gradient box

        Canvas {
            id:                 planarGradientCanvas
            anchors.left:       parent.left
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            anchors.right:      planarMagBox.left
            anchors.margins:    3

            function updateSlider(context, sliderPosition) {
                context.lineWidth = 5;
                context.strokeStyle = _gradientBarColor
                context.lineCap = "square"
                context.fillStyle = _gradientBarOutlineColor
                context.beginPath();
                context.moveTo(sliderPosition, 0);
                context.lineTo(sliderPosition, height);
                context.stroke();
            }

            onPaint: {
                var ctx = getContext("2d");
                var grad = ctx.createLinearGradient(0, 0, width, 0);
                grad.addColorStop(0, "green");
                grad.addColorStop(.5, "orange");
                grad.addColorStop(1, "red");
                ctx.fillStyle = grad;
                ctx.clearRect(0, 0, width, height);
                ctx.fillRect(0, 0, width, height);
                let sliderLocation =  _windSpeedPlanar / _planarMaxSpeed * width

                let pxData = ctx.getImageData(sliderLocation, 0, 1, 1).data;
                planarHeadingArrow.arrowColor = Qt.rgba(pxData[0] / 255, pxData[1] / 255, pxData[2] / 255, pxData[3] / 255);
                updateSlider(ctx, sliderLocation);
            }

        }

        // Mag box
        Rectangle {
            id:                         planarMagBox
            anchors.top:                parent.top
            anchors.right:              parent.right
            anchors.bottom:             parent.bottom
            border.color:               qgcPal.text
            color:                      qgcPal.window
            anchors.leftMargin:         3
            width:                      parent.width * 1/4
            radius:                     parent.radius
            QGCLabel {
                id:                 planarMagLabel
                text:               _windSpeedPlanar.toFixed(1).padStart(4, '0')
                color:              qgcPal.text
                anchors.centerIn:   parent
                horizontalAlignment:    Text.AlignHCenter
                padding:            6
            }
        }

        // Labels
    }

    // Gradient with wind magnitude up and down
    Item {
        id:                     verticalMagnitudeArea
        anchors.right:          parent.right
        anchors.top:            parent.top
        anchors.bottom:         planarMagnitudeArea.bottom
        anchors.rightMargin:    5
        width:                  planarMagnitudeArea.height + 2* verticalGradientArea.anchors.margins
        // Gradient box
        Rectangle {
            id:                         verticalGradientArea
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.top:                upLabelBox.bottom
            anchors.bottom:             downLabelBox.top
            width:                      planarMagnitudeArea.height  + verticalGradientArea.anchors.margins
            anchors.margins:            5
            color:                      qgcPal.window
            border.color:               qgcPal.text

            Canvas {
                id:                 verticalGradientCanvas
                anchors.top:        parent.top
                anchors.left:       parent.left
                anchors.right:      parent.right
                anchors.bottom:     verticalMagBox.top
                anchors.margins:    3

                function updateSlider(context, sliderPosition) {
                    context.lineWidth = 5;
                    context.strokeStyle = _gradientBarColor
                    context.lineCap = "square"
                    context.fillStyle = _gradientBarOutlineColor
                    context.beginPath();
                    context.moveTo(0, height /2 - sliderPosition);
                    context.lineTo(width, height/2 - sliderPosition);
                    context.stroke();
                }

                onPaint: {
                    var ctx = getContext("2d");
                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                    grad.addColorStop(0, "red");
                    grad.addColorStop(.25, "orange");
                    grad.addColorStop(.5, "green");
                    grad.addColorStop(.75, "orange")
                    grad.addColorStop(1, "red");
                    ctx.fillStyle = grad;
                    ctx.fillRect(0, 0, width, height);
                    updateSlider(ctx, -(_windSpeedDown / _verticalMaxSpeed * height / 2));
                }
            }

            // Mag box
            Rectangle {
                id:                     verticalMagBox
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.bottom:         parent.bottom
                anchors.topMargin:      3
                height:                 parent.height / 4.2
                border.color:           qgcPal.text
                color:                  qgcPal.window
                QGCLabel {
                    id:                     verticalMagLabel
                    text:                   _windSpeedDown.toFixed(1).padStart(4, '0')
                    color:                  qgcPal.text
                    anchors.centerIn:       parent
                    horizontalAlignment:    Text.AlignHCenter
                    padding:                6
                }
            }
        }



        Rectangle {
            id:                         upLabelBox
            anchors.top:                parent.top
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.bottomMargin:       5
            anchors.topMargin:          5
            border.color:               qgcPal.text
            color:                      qgcPal.window
            width:                      verticalGradientArea.width
            height:                     width * 0.6
            radius:                     4
            QGCLabel {
                id:                     upLabel
                text:                   "U"
                color:                  qgcPal.text
                anchors.centerIn:       parent
                horizontalAlignment:    Text.AlignHCenter
            }
        }

        Rectangle {
            id:                         downLabelBox
            anchors.bottom:             parent.bottom
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.topMargin:          5
            border.color:               qgcPal.text
            color:                      qgcPal.window
            width:                      verticalGradientArea.width
            height:                     width * 0.6
            radius:                     4
            QGCLabel {
                id:                     downLabel
                text:                   "D"
                color:                  qgcPal.text
                anchors.centerIn:       parent
                horizontalAlignment:    Text.AlignHCenter
            }
        }
    }

}
