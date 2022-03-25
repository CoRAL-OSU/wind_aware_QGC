#ifndef WINDAWAREMISSIONPLANNER_H
#define WINDAWAREMISSIONPLANNER_H

#include "QGCCorePlugin.h"
#include "MissionController.h"
#include "boost/geometry.hpp"
#include "boost/geometry/geometries/point_xy.hpp"
#include "boost/geometry/geometries/geometries.hpp"
#include "boost/geometry/algorithms/buffer.hpp"

class PlanMasterController;

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
    Q_PROPERTY(QmlObjectListModel* plannedItems                     READ plannedItems                       NOTIFY plannedItemsChanged)
    Q_PROPERTY(QmlObjectListModel* simplePlannedFlightPathSegments  READ simplePlannedFlightPathSegments    NOTIFY plannedFlightSegmentsChanged)
    Q_PROPERTY(QmlObjectListModel* windBufferPolygons               READ windBufferPolygons                 CONSTANT)

    // Accessor for private variable
    QmlObjectListModel* plannedItems                        (void) {return _plannedVisualitems; }
    QmlObjectListModel* simplePlannedFlightPathSegments     (void) {return &_flightPathSegments; }
    QmlObjectListModel* windBufferPolygons                  (void) {return &_windBufferPolygons; }

signals:
    void plannedItemsChanged                (void);
    void plannedFlightSegmentsChanged       (void);
    void riskManagementSettingsChanged      (void);

public slots:
    void generateWindBuffer_slot(void);

private:


    PlanMasterController*   _masterController;
    QmlObjectListModel*     _plannedVisualitems;
    QmlObjectListModel      _flightPathSegments;
    QmlObjectListModel      _windBufferPolygons;

    // Wind risk buffer generation, display
    void                _computeWindBufferPolygons(void);
    WindAwareMissionPlanner::polygon             _generateInnerBufferPolygon(QList<WindAwareMissionPlanner::point> trajectoryCoords_Cartesian);
    WindAwareMissionPlanner::polygon             _generateOuterBufferPolygon(WindAwareMissionPlanner::polygon innerPolygon);
    void                _constructGeoFencePolygon(QGCFencePolygon* newPoly, QList<QGeoCoordinate> vertexList);

    // New trajectory insertion and preview generation
    void                _regenerateFlightSegments(void);
    void                _insertOptimalTrajectory(void);
    void                _printCurrentItems(void);
    FlightPathSegment*  _createFlightPathSegment(VisualItemPair& itemPair, bool mavlinkTerrainFrame);
    VisualMissionItem*  _insertSimplePlannedMissionItem(QGeoCoordinate coordinate, int visualItemIndex, bool makeCurrentItem);

};

#endif // WINDAWAREMISSIONPLANNER_H
