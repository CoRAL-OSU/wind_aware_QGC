#ifndef WINDAWAREMISSIONPLANNER_H
#define WINDAWAREMISSIONPLANNER_H

#include "QGCCorePlugin.h"
#include "MissionController.h"

class PlanMasterController;

class WindAwareMissionPlanner : public QObject
{
    Q_OBJECT




public:
    WindAwareMissionPlanner(PlanMasterController* masterController, QObject* parent = nullptr);

    // Replace existing mission with new items
    void replaceMissionItems();

    QmlObjectListModel* plannedVisualItems (void) {return _plannedVisualitems; }
    VisualMissionItem* insertSimplePlannedMissionItem(QGeoCoordinate coordinate, int visualItemIndex, bool makeCurrentItem);
    VisualMissionItem* _insertSimplePlannedMissionItemWorker(QGeoCoordinate coordinate, MAV_CMD command, int visualItemIndex, bool makeCurrentItem);
    void               insertMissionItem(MissionItem item);
    void updateTrajectory(void);
    void printCurrentItems();
    void recalculateFlightSegments();

    void _initPlannedVisualItem(VisualMissionItem* visualItem);
    int count = 0;
    int itemIndex = 0;

    // Makes function accessible inside QML
    Q_INVOKABLE void newTrajectoryResponse(bool response);
    Q_INVOKABLE void recalculateTrajectory(void);

    // Makes variable accessible inside QML as a property
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
    void updateTrajectoryRecommendation();

private:
    PlanMasterController*   _masterController;
    QmlObjectListModel*     _plannedVisualitems;
    QmlObjectListModel      _flightPathSegments;
    QmlObjectListModel      _windBufferPolygons;

    FlightPathSegment* _createFlightPathSegment(VisualItemPair& itemPair, bool mavlinkTerrainFrame);
    void                    _regenerateBufferPolygons();
    void                    _GeneratePolygonWindBuffer();

};

#endif // WINDAWAREMISSIONPLANNER_H
