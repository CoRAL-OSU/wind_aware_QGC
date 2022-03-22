
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
#include <vector>
#include "boost/geometry.hpp"
#include "boost/geometry/geometries/point_xy.hpp"
#include "boost/geometry/geometries/geometries.hpp"

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

    _plannedVisualitems->append(newItem);

    return newItem;
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
        int numWaypoints = currentItems->count() - 3; // Exclude settings (0) takeoff(1) and last waypoint (currentItems->count(0 - 1)
        int ratio = 2;

        int numIntermediatePoints = floor(numWaypoints / ratio);

        for(int i = 1; i <= numIntermediatePoints; i++) {
            VisualMissionItem* intermediatePoint = qobject_cast<VisualMissionItem*>(currentItems->get(i * ratio));
            insertSimplePlannedMissionItem(intermediatePoint->coordinate(), itemIndex++, false);
        }

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

    _regenerateBufferPolygons();
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

/**********************************************************
 *
 *  Wind Buffer, Risk Management
 *
 *********************************************************/

// Given starting coordinate and
//QGeoCoordinate GetOffsetLatitude(QGeoCoordinate startCoord, float offsetMeters) {

//}

//QGeoCoordinate GetOffsetLongitude(QGeoCoordinate startCoord, float offsetMeters) {

//}

void WindAwareMissionPlanner::_regenerateBufferPolygons() {


    _GeneratePolygonWindBuffer();
}

void ConstructGeoFencePolygon(QGCFencePolygon* newPoly, QList<QGeoCoordinate> vertexList) {
    for (auto c : vertexList) {
        newPoly->appendVertex(c);
    }
    newPoly->setInteractive(false);
    newPoly->setInclusion(false);
}

void WindAwareMissionPlanner::_GeneratePolygonWindBuffer() {





    // https://www.boost.org/doc/libs/1_65_0/libs/geometry/doc/html/geometry/reference/algorithms/buffer/buffer_7_with_strategies.html
    typedef double coordinate_type;
    typedef boost::geometry::model::d2::point_xy<coordinate_type> point;
    typedef boost::geometry::model::polygon<point> polygon;

    // Declare strategies
    const double buffer_distance = 10.0; // meters
    const int points_per_circle = 18;
    boost::geometry::strategy::buffer::distance_symmetric<coordinate_type> distance_strategy(buffer_distance);
    boost::geometry::strategy::buffer::join_round join_strategy(points_per_circle);
    boost::geometry::strategy::buffer::end_round end_strategy(points_per_circle);
    boost::geometry::strategy::buffer::point_circle circle_strategy(points_per_circle);
    boost::geometry::strategy::buffer::side_straight side_strategy;

    // Declare output
    boost::geometry::model::multi_polygon<polygon> result;

    // Declare/fill a linestring
    boost::geometry::model::linestring<point> ls;
    //boost::geometry::read_wkt("LINESTRING(0 0,4 5,7 4,10 6)", ls);

    // Get lat lon coords from visual items
    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
    QList<QGeoCoordinate> trajectoryCoords;
    QList<QGeoCoordinate> bufferCoords;

    for(int i = 1; i < currentItems->count(); i++) {
        VisualMissionItem* newItem = qobject_cast<VisualMissionItem*>(currentItems->get(i));
        trajectoryCoords.push_back(newItem->coordinate());
    }

    // Convert lat lon coords to LTP coords, store as boost::geometry points
    QGeoCoordinate ltpOrigin = trajectoryCoords.at(0); // starting point
    for(auto coord : trajectoryCoords) {
        double ltpX, ltpY, ltpZ;
        convertGeoToNed(coord, ltpOrigin, &ltpX, &ltpY, &ltpZ);
        point newP = point(ltpX, ltpY);
        ls.push_back(newP);
    }

    // Create the buffer of a linestring
    boost::geometry::buffer(ls, result,
                distance_strategy, side_strategy,
                join_strategy, end_strategy, circle_strategy);

    // Convert buffer points back to lat lon coordinates
    for(const auto& point : result.at(0).outer()) {
        QGeoCoordinate newCoord;
        convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
        bufferCoords.push_back(newCoord);
    }

    for(auto c : bufferCoords) {
        qDebug() << c;
    }
    QGCFencePolygon* newPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
    ConstructGeoFencePolygon(newPoly, bufferCoords);
    windBufferPolygons()->append(newPoly);
    _masterController->geoFenceController()->polygons()->append(newPoly);

//    // Declare/fill a multi point
//    boost::geometry::model::multi_point<point> mp;
//    boost::geometry::read_wkt("MULTIPOINT((3 3),(4 4),(6 2))", mp);

//    // Create the buffer of a multi point
//    boost::geometry::buffer(mp, result,
//                distance_strategy, side_strategy,
//                join_strategy, end_strategy, circle_strategy);


//    // Declare/fill a multi_polygon
//    boost::geometry::model::multi_polygon<polygon> mpol;
//    boost::geometry::read_wkt("MULTIPOLYGON(((0 1,2 5,5 3,0 1)),((1 1,5 2,5 0,1 1)))", mpol);

//    // Create the buffer of a multi polygon
//    boost::geometry::buffer(mpol, result,
//                distance_strategy, side_strategy,
//                join_strategy, end_strategy, circle_strategy);

    // https://stackoverflow.com/questions/41117346/how-can-we-get-all-the-points-stored-in-boost-polygon


}
