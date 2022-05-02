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
    //property var controller: globals.planMasterController.windAwareController

    headerComponent:    headerComponent
    pageComponent:      pageComponent
    allowPopout:        false

    property var _planMasterController: globals.planMasterControllerPlanView
    property var windPlanner:           _planMasterController.windAwarePlanner

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
                anchors.top: radius_label.bottom
                id:                 innerRadiusField
                placeholderText:    qsTr("Inner radius: " + windPlanner.innerBufferRadius) + " (m)"
                validator:          DoubleValidator {
                    bottom:         0.0;
                    top:            100.0;
                    decimals:       1;
                    notation:       DoubleValidator.StandardNotation
                }

                onEditingFinished:  acceptableInput ? windPlanner.innerBufferRadius = parseFloat(text) : console.log("error")
            }

            QGCTextField {
                anchors.top: innerRadiusField.bottom
                id:                 outerRadiusField
                placeholderText:    qsTr("Outer radius: " + windPlanner.outerBufferRadius) + " (m)"
                validator:          DoubleValidator {
                    bottom:         0.0;
                    top:            100.0;
                    decimals:       1;
                    notation:       DoubleValidator.StandardNotation
                }

                onEditingFinished:  acceptableInput ? windPlanner.outerBufferRadius = parseFloat(text) : console.log("error")
            }

            QGCLabel{
                id:         color_label
                text:       qsTr("Adjust Buffer Radius (meters)")
                anchors.top: outerRadiusField.bottom
            }

            QGCTextField {
                anchors.top: color_label.bottom
                id:                 innerColorField
                placeholderText:    qsTr("Inner color: " + windPlanner.innerBufferColor)

                onEditingFinished:  acceptableInput ? windPlanner.innerBufferColor = text : console.log("error")
            }

            QGCTextField {
                anchors.top: innerColorField.bottom
                id:                 outerColorField
                placeholderText:    qsTr("Outer color: " + windPlanner.outerBufferColor)

                onEditingFinished:  acceptableInput ? windPlanner.outerBufferColor = text : console.log("error")
            }

        }
    }

}
