import QtQuick              2.3
import QtQuick.Layouts      1.0
import QtGraphicalEffects   1.0

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controllers   1.0
// Inner canvas

Item {
    id: root
    property real arrowLength:      0
    property real arrowAngle:       0
    property color arrowColor:      Qt.rgba(1, 0, 0, 1)
    property real arrowHeadSize:    6
    property real arrowLineWidth:   3
    property real baseCircleWidth:  2

    function drawArrow(length, angle) {
        arrowLength = length;
        arrowAngle = angle;
        arrowCanvas.requestPaint();
    }

    function draw() {
        arrowCanvas.requestPaint();
    }

    Canvas {
        id:             arrowCanvas
        anchors.fill:   parent

        function _drawArrow(context, length, angle) {

            // Setup style
            context.lineWidth = arrowLineWidth;
            context.strokeStyle = arrowColor;
            context.lineCap = "square";
            context.fillStyle = arrowColor
            context.beginPath();

            // Draw arrow only if nonzero length. Otherwise, draw center dot
            if(length >= 0.5) {

                // Setup rotation around center
                context.translate(width/2, height/2);
                context.rotate(angle);
                context.translate(-width/2, -height/2);

                // Draw leg of arrow
                context.moveTo(width/2, height/2);  // Start in center of canvas
                context.lineTo(width/2, height/2 - length + 5); // Draw thick line from center to tip of "arrow". Account for line width
                context.stroke();

                // Draw head of arrow
                context.beginPath();
                context.moveTo(width/2, height/2 - length);
                context.lineTo(width/2 + arrowHeadSize, height/2 - length + arrowHeadSize);
                context.lineTo(width/2 - arrowHeadSize, height/2 - length + arrowHeadSize);
                context.lineTo(width/2, height/2 - length);
                context.fill();
            }

            else {
                context.arc(width/2, height/2, baseCircleWidth, 0, 2*Math.PI);
                context.fill();
            }
            // Clean up and exit
            context.closePath();
            context.setTransform(1, 0, 0, 1, 0, 0);

        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            _drawArrow(ctx, arrowLength, arrowAngle);
        }
    }

}
