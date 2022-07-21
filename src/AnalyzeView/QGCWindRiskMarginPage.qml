import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtQuick.Layouts              1.11
import QtQuick.Dialogs              1.3
import QtQuick.Window               2.2
import QtCharts                     2.3

import QGroundControl                   1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Controls          1.0
import QGroundControl.FactSystem        1.0
import QGroundControl.FactControls      1.0
import QGroundControl.Palette           1.0
import QGroundControl.Controllers       1.0
import QGroundControl.ShapeFileHelper   1.0
import QGroundControl.Airspace          1.0
import QGroundControl.Airmap            1.0

AnalyzePage {
    id:                 root

    headerComponent:    headerComponent
    pageComponent:      pageComponent
    allowPopout:        false
    property var windPlanner:               globals.windAwareMissionPlanner
    property bool enableFlightViewBuffer:   true

    property string innerColor: windPlanner.innerPlanBuffer.settings.color
    property double innerRadius: windPlanner.innerPlanBuffer.settings.radius

    property string outerColor: windPlanner.outerPlanBuffer.settings.color
    property double outerRadius: windPlanner.outerPlanBuffer.settings.radius


    Component {
        id:             headerComponent

        QGCLabel {
            id:         pageLabel
            text:       qsTr("Risk margin information")

        }

        // Set buffer radius
        // Set buffer colors
        // Enable display of buffer
    }

    Component {
        id:         pageComponent
        Item {

            QGCLabel{
                id:         radius_label
                text:       qsTr("Adjust Buffer Radius (meters)")
            }

            QGCTextField {
                id:                 innerRadiusField
                anchors.top:        radius_label.bottom
                placeholderText:    qsTr("Inner radius: " + windPlanner.innerFlyBuffer.settings.radius) + " (m)"
                validator:          DoubleValidator {
                    bottom:         0.0;
                    top:            100.0;
                    decimals:       1;
                    notation:       DoubleValidator.StandardNotation
                }

                onEditingFinished: acceptableInput ? windPlanner.innerFlyBuffer.settings.radius = parseFloat(text) : console.log("error")
            }

            QGCTextField {
                id:                 outerRadiusField
                anchors.top:        innerRadiusField.bottom
                placeholderText:    qsTr("Outer radius: " + windPlanner.outerFlyBuffer.settings.radius) + " (m)"
                validator:          DoubleValidator {
                    bottom:         0.0;
                    top:            100.0;
                    decimals:       1;
                    notation:       DoubleValidator.StandardNotation
                }

                onEditingFinished: acceptableInput ? windPlanner.outerFlyBuffer.settings.radius = parseFloat(text) : console.log("error")
            }

            QGCLabel{
                id:         color_label
                text:       qsTr("Adjust Buffer Color")
                anchors.top: outerRadiusField.bottom
            }

            QGCTextField {
                id:                 innerColorField
                anchors.top:        color_label.bottom
                placeholderText:    qsTr("Inner color: " + windPlanner.innerFlyBuffer.settings.color)

                onEditingFinished:  acceptableInput ? windPlanner.innerFlyBuffer.settings.color = text : console.log("error")
            }

            QGCTextField {
                id:                 outerColorField
                anchors.top:        innerColorField.bottom

                placeholderText:    qsTr("Outer color: " + windPlanner.outerFlyBuffer.settings.color)

                onEditingFinished:  acceptableInput ? windPlanner.outerFlyBuffer.settings.color = text : console.log("error")
            }

//            QGCCheckBox {
//                id:         flightViewBufferEnableCheckbox
//                text:       "Enable flight view circular buffer"
//                anchors.top: outerColorField.bottom
//                onClicked: {
//                    enableFlightViewBuffer = !enableFlightViewBuffer
//                    checked = enableFlightViewBuffer
//                    windPlanner.flightViewBufferVisible = enableFlightViewBuffer
//                }

//                Component.onCompleted: {
//                    checked = enableFlightViewBuffer
//                }
//            }
        }
    }

}
