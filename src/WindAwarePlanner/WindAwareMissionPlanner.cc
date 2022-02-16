
/* Author: Max DeSantis
 * Purpose: Generate and recommend wind-optimal trajectories to users.
 */


/* 1. When should the new trajectory be recommended?
 * - When user "completes" a mission plan?
 * 2. How should the new trajectory be recommended?
 * - Place "dummy" waypoints on FlightMap to show new path. Popup notification "An optimal trajectory
 * - has been determined. Would you like to use it?" Accept/Reject.
 * 3. How should the old mission be replaced with new mission?
 * - Just replace all items in the mission?
 */

/*
 * 1. Store our own "visual" items that we can display
 * 2. When trajectory recommendation accepted, translate those to legitimate visual items
 *
 *
 *
 */

#include "WindAwareMissionPlanner.h"
#include "PlanMasterController.h"
#include "QGCCorePlugin.h"
#include "QGCApplication.h"
#include "string.h"
#include "SimpleMissionItem.h"
#include "MissionController.h"
#include "TakeoffMissionItem.h"

WindAwareMissionPlanner::WindAwareMissionPlanner(PlanMasterController* masterController, QObject* parent)
    : QObject(parent),
      _masterController(masterController),
      _plannedVisualitems(new QmlObjectListModel(this))
{
    // Store mission controller
    qDebug("wind aware planner live");
    //connect(masterController->missionController(), &MissionController::testSignal, this, &WindAwareMissionPlanner::updateTrajectoryRecommendation);
}



VisualMissionItem* WindAwareMissionPlanner::insertSimplePlannedMissionItem(QGeoCoordinate coordinate, int visualItemIndex, bool makeCurrentItem) {
    SimpleMissionItem* newItem = new SimpleMissionItem(_masterController, false, false);
    newItem->setCoordinate(coordinate);
    newItem->setCommand(MAV_CMD_NAV_WAYPOINT);
    newItem->setSequenceNumber(visualItemIndex);
//    if(visualItemIndex == 0) {
//        _plannedVisualitems->append(newItem);
//    } else {
//        _plannedVisualitems->insert(visualItemIndex, newItem);
//    }

    _plannedVisualitems->append(newItem);

    return newItem;
}

void WindAwareMissionPlanner::insertMissionItem(MissionItem item) {


}

FlightPathSegment* WindAwareMissionPlanner::_createFlightPathSegment(VisualItemPair& itemPair, bool mavlinkTerrainFrame) {
    bool takeoffStraightUp = itemPair.second->isTakeoffItem() && !_masterController->controllerVehicle()->fixedWing();
    QGeoCoordinate coord1 = itemPair.first->exitCoordinate();
    QGeoCoordinate coord2 = itemPair.second->coordinate();
    double              coord2AMSLAlt       = itemPair.second->amslEntryAlt();
    double              coord1AMSLAlt       = takeoffStraightUp ? coord2AMSLAlt : itemPair.first->amslExitAlt();

    FlightPathSegment::SegmentType segType = mavlinkTerrainFrame ? FlightPathSegment::SegmentTypeTerrainFrame : FlightPathSegment::SegmentTypeGeneric;
    if(itemPair.second->isTakeoffItem()) {
        segType = FlightPathSegment::SegmentTypeTakeoff;
    } else if (itemPair.second->isLandCommand()) {
        segType = FlightPathSegment::SegmentTypeLand;
    }

    FlightPathSegment* segment = new FlightPathSegment(segType, coord1, coord1AMSLAlt, coord2, coord2AMSLAlt, false, this);

    return segment;
}

void WindAwareMissionPlanner::recalculateFlightSegments() {
    qDebug() << "recalculating flight segments";
    simplePlannedFlightPathSegments()->clear();
    VisualItemPair itemPair;
    VisualMissionItem* lastItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(0));
    VisualMissionItem* newItem;
    for(int i = 0; i < plannedItems()->count() - 1; i++) {

        newItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(i+1));
        itemPair = VisualItemPair(lastItem, newItem);
        lastItem = newItem;

        FlightPathSegment* segment = _createFlightPathSegment(itemPair, true);
        simplePlannedFlightPathSegments()->append(segment);
    }
    emit plannedFlightSegmentsChanged();
}

void WindAwareMissionPlanner::recalculateTrajectory() {
    _plannedVisualitems->clear();

    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();

    qDebug() << "in recalc";
    printCurrentItems();
    VisualMissionItem* newEndPoint = qobject_cast<VisualMissionItem*>(currentItems->get(currentItems->count()-1));
    VisualMissionItem* oldTakeoff = qobject_cast<VisualMissionItem*>(currentItems->get(1));

    itemIndex = 1;

    insertSimplePlannedMissionItem(oldTakeoff->coordinate(), itemIndex++, false);

    if(currentItems->count() > 4) {
        VisualMissionItem* midPoint = qobject_cast<VisualMissionItem*>(currentItems->get(currentItems->count()/2));
        insertSimplePlannedMissionItem(midPoint->coordinate(), itemIndex++, false);
    }

    insertSimplePlannedMissionItem(newEndPoint->coordinate(), itemIndex++, false);
    emit plannedItemsChanged();

    recalculateFlightSegments();
}

void WindAwareMissionPlanner::printCurrentItems() {
    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
    for(int i = 0; i < currentItems->count(); i++) {
        qDebug() << "item: " << i << " " << currentItems->objectList()->at(i) << " sequence: " << qobject_cast<VisualMissionItem*>(currentItems->objectList()->at(i))->sequenceNumber();
    }
}

void WindAwareMissionPlanner::updateTrajectory() {
    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
    qDebug() << "in update, count= "<< currentItems->count();

    // Remove 2nd waypoint j-2 times. ie preserve waypoints 0 and 1, the mission settings and takeoff.
    int j = currentItems->count();
    for(int i = 1; i < j; i++) {
        qDebug() << "REMOVING: " << i;
        printCurrentItems();
        _masterController->missionController()->removeVisualItem(1);
    }
    VisualMissionItem* takeoffItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(0));
    _masterController->missionController()->insertTakeoffItem(takeoffItem->coordinate(), 1, true);

    for(int i = 1; i < plannedItems()->count(); i++) {
        VisualMissionItem* newItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(i));
        _masterController->missionController()->insertSimpleMissionItem(newItem->coordinate(), newItem->sequenceNumber(), true);
    }

    for(int i = 0; i < currentItems->count(); i++) {
        qDebug() << "item: " << i << " " << currentItems->objectList()->at(i);
    }

    _plannedVisualitems->clear();
}

void WindAwareMissionPlanner::newTrajectoryResponse(bool response) {

    if(response) {
       if(plannedItems()->count()) {
           updateTrajectory();
       } else {
           qDebug() << "Cannot update trajectory - no optimal trajectory found.";
       }
    }
    else {
        plannedItems()->clearAndDeleteContents();
    }
    emit plannedItemsChanged();
    recalculateFlightSegments();
}

void WindAwareMissionPlanner::updateTrajectoryRecommendation() {

}
