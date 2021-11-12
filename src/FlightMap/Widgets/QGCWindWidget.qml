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
    on_WindSpeedChanged: {
        planarHeadingArrow.draw();
        planarGradientCanvas.requestPaint();
        verticalGradientCanvas.requestPaint();
    }


    // Compass, heading arrow and magnitude, aircraft heading
    Item {
        id:             planarHeadingArea
        anchors.left:   parent.left
        anchors.right:  verticalMagnitudeArea.left
        anchors.top:    parent.top
        anchors.bottom: planarMagnitudeArea.top

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

            QGCWindDial {
                id:             planarHeadingArrow
                anchors.fill:   planarHeadingDial
                arrowLength:    (_windSpeedPlanar >= 0.5) ? planarHeadingDial.width / 3 : 0
                arrowAngle:     _windHeadingRad
                arrowLineWidth: 5
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
            width:              parent.width / 5
            height:             width * .65
            QGCLabel {
                id:                 planarHeadingLabel
                text:               _windHeading.toFixed(0)
                color:              qgcPal.text
                anchors.centerIn:   parent
                anchors.margins:    1
            }
        }

    }

    // Gradient with wind magnitude North and East
    Item {
        id: planarMagnitudeArea
        anchors.left:   parent.left
        anchors.right:  verticalMagnitudeArea.left
        anchors.bottom: parent.bottom
        height:         parent.height / 3
        anchors.margins: 5
        // Gradient box
        Canvas {
            id:                 planarGradientCanvas
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.bottom:     parent.bottom
            height:             parent.height / 3


            function updateSlider(context, sliderPosition) {
                context.lineWidth = 5;
                context.strokeStyle = "black"
                context.lineCap = "square"
                context.fillStyle = "black"
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

        // Slider

        // Mag box
        Rectangle {
            id:                         planarMagBox
            anchors.bottom:             planarGradientCanvas.top
            anchors.horizontalCenter:   parent.horizontalCenter
            anchors.margins:            5
            border.color:               qgcPal.text
            color:                      qgcPal.window
            height:                     planarGradientCanvas.height
            width:                      height * 1.6
            radius:                     4
            QGCLabel {
                id:                 planarMagLabel
                text:               _windSpeedPlanar.toFixed(1)
                color:              qgcPal.text
                anchors.centerIn:   parent
            }
        }

        // Labels
    }

    // Gradient with wind magnitude up and down
    Item {
        id: verticalMagnitudeArea
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom
        width:          parent.width / 3

        anchors.margins:    5
        // Gradient box

        Canvas {
            id:                 verticalGradientCanvas
            anchors.right:      parent.right
            anchors.top:        parent.top
            anchors.bottom:     parent.bottom
            width:              planarGradientCanvas.height

            function updateSlider(context, sliderPosition) {
                context.lineWidth = 5;
                context.strokeStyle = "black"
                context.lineCap = "square"
                context.fillStyle = "black"
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

        // Slider

        // Mag box
        Rectangle {
            id:                     verticalMagBox
            anchors.right:          verticalGradientCanvas.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins:        5
            border.color:           qgcPal.text
            color:                  qgcPal.window
            height:                 verticalGradientCanvas.width
            width:                  height * 1.6
            radius:                 4
            QGCLabel {
                id:                 verticalMagLabel
                text:               _windSpeedDown.toFixed(1)
                color:              qgcPal.text
                anchors.centerIn:   parent
            }
        }

        // Labels
    }

}
