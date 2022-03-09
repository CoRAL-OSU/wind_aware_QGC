import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtQuick.Layouts              1.11
import QtQuick.Dialogs              1.3
import QtQuick.Window               2.2
import QtCharts                     2.3

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.Controllers   1.0
import QGroundControl.ScreenTools   1.0

AnalyzePage {

    headerComponent:    headerComponent
    pageComponent:      pageComponent
    allowPopout:        false

    Component {
        id:             headerComponent

        QGCLabel {
            text:       qsTr("Risk margin information")
        }
    }

}
