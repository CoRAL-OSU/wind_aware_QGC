#ifndef WINDAWAREMISSIONPLANNER_H
#define WINDAWAREMISSIONPLANNER_H

#include "QGCCorePlugin.h"
#include "MissionController.h"
#include "boost/geometry.hpp"
#include "boost/geometry/geometries/point_xy.hpp"
#include "boost/geometry/geometries/geometries.hpp"
#include "boost/geometry/algorithms/buffer.hpp"
#include <QGeoPolygon>

class PlanMasterController;

class PolygonObject : public QObject {
    Q_OBJECT

public:

    Q_PROPERTY(QGeoPolygon polygonGadget READ polygonGadget CONSTANT)

    QGeoPolygon polygonGadget (void) {return *_polygon;}
    QGeoPolygon* polygon (void) {return _polygon; }


    PolygonObject(QList<QGeoCoordinate> coordList);
    ~PolygonObject();
private:
    QGeoPolygon* _polygon;

};

class WindAwareMissionPlanner : public QObject
{
    Q_OBJECT


public:

    typedef double coordinate_type;
    typedef boost::geometry::model::d2::point_xy<coordinate_type> point;
    typedef boost::geometry::model::polygon<point> polygon;
    WindAwareMissionPlanner(PlanMasterController* masterController, QObject* parent = nullptr);

    // New trajectory generation and updating. Accessible from QML.
    Q_INVOKABLE void approveOptimalTrajectory(bool approve);
    Q_INVOKABLE void generateOptimalTrajectory(void);
    Q_INVOKABLE void generateWindBuffer(void);


    // Properties needed by QML
    Q_PROPERTY(QmlObjectListModel*  plannedItems                        READ plannedItems                       NOTIFY plannedItemsChanged)
    Q_PROPERTY(QmlObjectListModel*  simplePlannedFlightPathSegments     READ simplePlannedFlightPathSegments    NOTIFY plannedFlightSegmentsChanged)
    //Q_PROPERTY(QmlObjectListModel*  windBufferPolygons                  READ windBufferPolygons                 CONSTANT)
    Q_PROPERTY(QmlObjectListModel*     innerWindBufferPolygon              READ innerWindBufferPolygon             CONSTANT)
    Q_PROPERTY(QmlObjectListModel*     outerWindBufferPolygon              READ outerWindBufferPolygon             CONSTANT)
    Q_PROPERTY(QmlObjectListModel*     innerBufferInteriorPolygons              READ innerBufferInteriorPolygons             CONSTANT)
    Q_PROPERTY(QmlObjectListModel*     outerBufferInteriorPolygons              READ outerBufferInteriorPolygons             CONSTANT)
    Q_PROPERTY(QString              innerBufferColor                    MEMBER _innerBufferColor                NOTIFY bufferPropertiesChanged)
    Q_PROPERTY(QString              outerBufferColor                    MEMBER _outerBufferColor                NOTIFY bufferPropertiesChanged)
    Q_PROPERTY(double               innerBufferRadius                   MEMBER _innerBufferRadius               NOTIFY bufferPropertiesChanged)
    Q_PROPERTY(double               outerBufferRadius                   MEMBER _outerBufferRadius               NOTIFY bufferPropertiesChanged)

    //Q_PROPERTY(QGeoPolygon* outerBufferPolygon  READ  outerBufferPolygon CONSTANT)
    Q_PROPERTY(QmlObjectListModel*     bufferPolygons              READ polygonObjectList             CONSTANT)


    // Accessor for private variable
    QmlObjectListModel* plannedItems                        (void) {return _plannedVisualitems; }
    QmlObjectListModel* simplePlannedFlightPathSegments     (void) {return &_flightPathSegments; }
    //QmlObjectListModel* windBufferPolygons                  (void) {return &_windBufferPolygons; }
    QmlObjectListModel*    innerWindBufferPolygon              (void) {return &_innerWindBufferPolygon; }
    QmlObjectListModel*    outerWindBufferPolygon              (void) {return &_outerWindBufferPolygon; }
    QmlObjectListModel*    innerBufferInteriorPolygons              (void) {return &_innerBufferInteriorPolygons; }
    QmlObjectListModel*    outerBufferInteriorPolygons              (void) {return &_outerBufferInteriorPolygons; }
    QGeoPolygon*           outerBufferPolygon               (void){return &_outerBufferPolygon; }
    QmlObjectListModel*     polygonObjectList       (void) { return &_polygonObjectList; }

signals:
    void plannedItemsChanged                (void);
    void plannedFlightSegmentsChanged       (void);
    void riskManagementSettingsChanged      (void);
    void bufferPropertiesChanged            (void);
    void outerColorChanged                  (void);
    void innerRadiusChanged                 (void);
    void outerRadiusChanged                 (void);

public slots:
    void generateWindBuffer_slot(void);

private:

    QString                 _innerBufferColor = "orange";
    QString                 _outerBufferColor = "red";
    double                  _innerBufferRadius = 5.0;
    double                  _outerBufferRadius = 10.0; // Distance from trajectory to outer buffer

    PlanMasterController*   _masterController;
    QmlObjectListModel*     _plannedVisualitems;
    QmlObjectListModel      _flightPathSegments;
    //QmlObjectListModel      _windBufferPolygons;
    QmlObjectListModel        _innerWindBufferPolygon;
    QmlObjectListModel        _outerWindBufferPolygon;
    QmlObjectListModel      _innerBufferInteriorPolygons;
    QmlObjectListModel      _outerBufferInteriorPolygons;
    //QList<QGeoPolygon>      _outerBufferPolygon;

    QGeoPolygon             _outerBufferPolygon;

    // Wind risk buffer generation, display
    void                                        _computeWindBufferPolygons(void);
    WindAwareMissionPlanner::polygon            _generateInnerBufferPolygon(QList<WindAwareMissionPlanner::point> trajectoryCoords_Cartesian);
    WindAwareMissionPlanner::polygon            _generateOuterBufferPolygon(WindAwareMissionPlanner::polygon innerPolygon);
    void                                        _constructGeoFencePolygon(QGCFencePolygon* newPoly, QList<QGeoCoordinate> vertexList);

    // New trajectory insertion and preview generation
    void                _regenerateFlightSegments(void);
    void                _insertOptimalTrajectory(void);
    void                _printCurrentItems(void);
    FlightPathSegment*  _createFlightPathSegment(VisualItemPair& itemPair, bool mavlinkTerrainFrame);
    VisualMissionItem*  _insertSimplePlannedMissionItem(QGeoCoordinate coordinate, int visualItemIndex, bool makeCurrentItem);


    QmlObjectListModel      _polygonObjectList;
};

#endif // WINDAWAREMISSIONPLANNER_H
