import QtQuick                          2.11
import QtQuick.Controls                 2.4
import QtLocation                       5.3
import QtPositioning                    5.3
import QtQuick.Dialogs                  1.2
import QtQuick.Layouts                  1.11

import QGroundControl                   1.0
import QGroundControl.ScreenTools       1.0
import QGroundControl.Palette           1.0
import QGroundControl.Controls          1.0
import QGroundControl.FlightMap         1.0
import QGroundControl.ShapeFileHelper   1.0
import QtGraphicalEffects 1.12


Item {
    id: _root
    property var map_control
    property var map_polygon
    property var border_width
    property var border_color
    property var interior_color
    property var interior_opacity
    property var interactive


    QGCDynamicObjectManager { id: _objMgrCommonVisuals }

    function addCommonVisuals() {
        if (_objMgrCommonVisuals.empty) {

            _objMgrCommonVisuals.createObject(polygonComponent, map_control, true)
        }
    }

    function removeCommonVisuals() {
        _objMgrCommonVisuals.destroyObjects()
    }

    Component {
        id:                     polygonComponent
        MapPolygon {
            color:          interior_color
            opacity:        interior_opacity
            border.color:   border_color
            border.width:   border_width
            path:           map_polygon.path
        }
    }

    Component.onCompleted: {
        addCommonVisuals();
    }

    Component.onDestruction: {
        removeCommonVisuals();
    }
}
