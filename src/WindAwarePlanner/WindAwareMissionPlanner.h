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

    Q_INVOKABLE void newTrajectoryResponse(bool response);
    Q_INVOKABLE void recalculateTrajectory(void);

    Q_PROPERTY(QmlObjectListModel* plannedItems READ plannedItems NOTIFY plannedItemsChanged)
    Q_PROPERTY(QmlObjectListModel* simplePlannedFlightPathSegments READ simplePlannedFlightPathSegments NOTIFY plannedFlightSegmentsChanged)

    QmlObjectListModel* plannedItems                        (void) {return _plannedVisualitems; }
    QmlObjectListModel* simplePlannedFlightPathSegments     (void) {return &_flightPathSegments; }

signals:
    void plannedItemsChanged                (void);
    void plannedFlightSegmentsChanged       (void);

public slots:
    void updateTrajectoryRecommendation();

private:
    PlanMasterController*   _masterController;
    QmlObjectListModel*     _plannedVisualitems;
    QmlObjectListModel      _flightPathSegments;
    FlightPathSegment* _createFlightPathSegment(VisualItemPair& itemPair, bool mavlinkTerrainFrame);


};

#endif // WINDAWAREMISSIONPLANNER_H
