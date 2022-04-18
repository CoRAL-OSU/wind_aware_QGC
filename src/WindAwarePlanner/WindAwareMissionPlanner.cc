
/* Author: Max DeSantis
 * Purpose: Generate and recommend wind-optimal trajectories to users.
 */

/* WindAwareMissionPlanner
 * - Generates trajectory recommendations and displays then on PlanView
 * - Generates buffer zone around trajectory
 */


/*
 * PlanView
 * - Trajectory Recommend Popup
 * - - Accept new trajectory: "ApproveNewTrajectory(true)", replace current trajectory with new trajectory
 * - - Deny:                  "ApproveNewTrajectory(false)", remove computed trajectory from memory
 *
 * RiskManagement
 * - WindBuffer settings
 * - - Color, radius of buffers
 *
 * - Trajectory recommend settings
 * - - Manual generation request
 *
 * - WindDisplayWidget
 * - - Enable widget display
 *
 * WindAwareMissionPlanner
 * - ApproveNewTrajectory: replace current traj. with new trajectory. Problem is maintaining all mission items accurately.
 * - GenerateWindBuffer:   done whenever trajectory changes (ie listen to missioncontroller
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
#include <QGeoPolygon>
#include "boost/geometry.hpp"
#include "boost/geometry/geometries/point_xy.hpp"
#include "boost/geometry/geometries/geometries.hpp"
#include "boost/geometry/algorithms/buffer.hpp"

// Construct planner with necessary references
WindAwareMissionPlanner::WindAwareMissionPlanner(PlanMasterController* masterController, QObject* parent)
    : QObject(parent),
      _masterController(masterController),
      _plannedVisualitems(new QmlObjectListModel(this))
{
    // Connect WindBuffer generation to misioncontroller's update
    connect(this->_masterController->missionController()->visualItems(), &QmlObjectListModel::dirtyChanged, this, &WindAwareMissionPlanner::generateWindBuffer_slot);
    connect(this->_masterController->missionController()->visualItems(), &QmlObjectListModel::countChanged, this, &WindAwareMissionPlanner::generateWindBuffer_slot);
    connect(this, &WindAwareMissionPlanner::bufferPropertiesChanged, this, &WindAwareMissionPlanner::generateWindBuffer_slot);
}


/*********************************************************************************************
 *
 *  New trajectory generation and updating
 *
 ********************************************************************************************/

// Generates new trajectory
void WindAwareMissionPlanner::generateOptimalTrajectory() {
    _plannedVisualitems->clear();

    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();

    VisualMissionItem* newEndPoint = qobject_cast<VisualMissionItem*>(currentItems->get(currentItems->count()-1));
    VisualMissionItem* oldTakeoff = qobject_cast<VisualMissionItem*>(currentItems->get(1));

    int itemIndex = 1;

    _insertSimplePlannedMissionItem(oldTakeoff->coordinate(), itemIndex++, false);

    if(currentItems->count() > 4) {
        int numWaypoints = currentItems->count() - 3; // Exclude settings (0) takeoff(1) and last waypoint (currentItems->count(0 - 1)
        int ratio = 2;

        int numIntermediatePoints = floor(numWaypoints / ratio);

        for(int i = 1; i <= numIntermediatePoints; i++) {
            VisualMissionItem* intermediatePoint = qobject_cast<VisualMissionItem*>(currentItems->get(i * ratio));
            _insertSimplePlannedMissionItem(intermediatePoint->coordinate(), itemIndex++, false);
        }

    }


    _insertSimplePlannedMissionItem(newEndPoint->coordinate(), itemIndex++, false);
    emit plannedItemsChanged();

    _regenerateFlightSegments();
}

// If user approves new trajectory, replace it. Otherwise, delete it.
void WindAwareMissionPlanner::approveOptimalTrajectory(bool approve) {

    if(approve) {
       if(plannedItems()->count()) {
           _insertOptimalTrajectory();
       } else {
           qDebug() << "Cannot update trajectory - no optimal trajectory found.";
       }
    }
    else {
        plannedItems()->clearAndDeleteContents();
    }
    emit plannedItemsChanged();
    _regenerateFlightSegments();
}

// Replacing old trajectory with optimally generated trajectory
void WindAwareMissionPlanner::_insertOptimalTrajectory() {
    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
    qDebug() << "in update, count= "<< currentItems->count();

    // Remove 2nd waypoint j-2 times. ie preserve waypoints 0 and 1, the mission settings and takeoff.
    int j = currentItems->count();
    for(int i = 1; i < j; i++) {
        qDebug() << "REMOVING: " << i;
        _printCurrentItems();
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

    //GenerateWindBuffer();
}

// Builds new mission item and inserts to the list of planned items
VisualMissionItem* WindAwareMissionPlanner::_insertSimplePlannedMissionItem(QGeoCoordinate coordinate, int visualItemIndex, bool makeCurrentItem) {
    SimpleMissionItem* newItem = new SimpleMissionItem(_masterController, false, false);
    newItem->setCoordinate(coordinate);
    newItem->setCommand(MAV_CMD_NAV_WAYPOINT);
    newItem->setSequenceNumber(visualItemIndex);

    _plannedVisualitems->append(newItem);

    return newItem;
}

// Generates new flight segments that connect planned visual items, for preview on PlanView
void WindAwareMissionPlanner::_regenerateFlightSegments() {
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

// Creates a flight segment between a pair of visual items
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



// Prints visual items currently being used by master controller
void WindAwareMissionPlanner::_printCurrentItems() {
    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
    for(int i = 0; i < currentItems->count(); i++) {
        qDebug() << "item: " << i << " " << currentItems->objectList()->at(i) << " sequence: " << qobject_cast<VisualMissionItem*>(currentItems->objectList()->at(i))->sequenceNumber();
    }
}




/*********************************************************************************************
 *
 *  Wind Buffer, Risk Management
 *
 ********************************************************************************************/

// User input or master update, generate new buffer around trajectory.
void WindAwareMissionPlanner::generateWindBuffer() {
    if(_masterController->missionController()->visualItems()->count() > 2 )
        _computeWindBufferPolygons();
}

void WindAwareMissionPlanner::generateWindBuffer_slot() {
    //_printCurrentItems();
    generateWindBuffer();
}

void WindAwareMissionPlanner::_constructGeoFencePolygon(QGCFencePolygon* newPoly, QList<QGeoCoordinate> vertexList) {
    for (const auto& c : vertexList) {
        newPoly->appendVertex(c);
    }
    newPoly->setInteractive(false);
    newPoly->setInclusion(false);
}

WindAwareMissionPlanner::polygon WindAwareMissionPlanner::_generateInnerBufferPolygon(QList<point> trajectoryCoords_Cartesian) {
    const double buffer_distance = _innerBufferRadius; // meters
    const int points_per_circle = 10;
    boost::geometry::strategy::buffer::distance_symmetric<coordinate_type> inner_dist_strategy(buffer_distance);
    boost::geometry::strategy::buffer::distance_symmetric<coordinate_type> outer_dist_strategy(buffer_distance + 5);

    boost::geometry::strategy::buffer::join_round join_strategy(points_per_circle);
    boost::geometry::strategy::buffer::end_round end_strategy(points_per_circle);
    boost::geometry::strategy::buffer::point_circle circle_strategy(points_per_circle);
    boost::geometry::strategy::buffer::side_straight side_strategy;

    boost::geometry::model::multi_polygon<polygon> innerMultiPoly;
    boost::geometry::model::linestring<point> ls;

    for( auto& c : trajectoryCoords_Cartesian) {
        ls.push_back(c);
    }

    boost::geometry::buffer(ls, innerMultiPoly,
                inner_dist_strategy, side_strategy,
                join_strategy, end_strategy, circle_strategy);

    return innerMultiPoly.at(0);
}

WindAwareMissionPlanner::polygon WindAwareMissionPlanner::_generateOuterBufferPolygon(WindAwareMissionPlanner::polygon innerPolygon) {
    const double buffer_distance = _outerBufferRadius - _innerBufferRadius; // meters
    const int points_per_circle = 10;
    boost::geometry::strategy::buffer::distance_symmetric<WindAwareMissionPlanner::coordinate_type> outer_dist_strategy(buffer_distance);

    boost::geometry::strategy::buffer::join_round join_strategy(points_per_circle);
    boost::geometry::strategy::buffer::end_round end_strategy(points_per_circle);
    boost::geometry::strategy::buffer::point_circle circle_strategy(points_per_circle);
    boost::geometry::strategy::buffer::side_straight side_strategy;

    boost::geometry::model::multi_polygon<polygon> outerMultiPoly;

    boost::geometry::buffer(innerPolygon, outerMultiPoly,
                    outer_dist_strategy, side_strategy,
                    join_strategy, end_strategy, circle_strategy);

    return outerMultiPoly.at(0);
}

PolygonObject::PolygonObject(QList<QGeoCoordinate> coordList) {
    //polygon().setPath(coordList);
    _polygon = new QGeoPolygon(coordList);
    qDebug() << polygon();
    qDebug() << polygon()->size();
}
PolygonObject::~PolygonObject() {
    delete _polygon;
}

void WindAwareMissionPlanner::_computeWindBufferPolygons() {

    innerBufferInteriorPolygons()->clearAndDeleteContents();
    outerBufferInteriorPolygons()->clearAndDeleteContents();
    qDebug() << "Inner rad: " << _innerBufferRadius;
    qDebug() << "Outer rad: " << _outerBufferRadius;

    // Get lat lon coords from visual items
    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
    QList<QGeoCoordinate> trajectoryCoords;
    QList<QGeoCoordinate> innerBufferCoords;
    QList<QGeoCoordinate> innerInteriorBufferCoords;
    QList<point> trajectoryCartesian;

    WindAwareMissionPlanner::polygon innerPolygon;

    // LatLon coords of trajectory
    for(int i = 1; i < currentItems->count(); i++) {
        VisualMissionItem* newItem = qobject_cast<VisualMissionItem*>(currentItems->get(i));
        trajectoryCoords.push_back(newItem->coordinate());
    }

    // Convert lat lon coords to LTP coords, store as boost::geometry points
    QGeoCoordinate ltpOrigin = trajectoryCoords.at(0); // starting point
    for(const auto& coord : trajectoryCoords) {
        double ltpX, ltpY, ltpZ;
        convertGeoToNed(coord, ltpOrigin, &ltpX, &ltpY, &ltpZ);
        point newP = point(ltpX, ltpY);
        trajectoryCartesian.push_back(newP);
    }

    innerPolygon = _generateInnerBufferPolygon(trajectoryCartesian);


    // Convert buffer points back to lat lon coordinates
    for(const auto& point : innerPolygon.outer()) {
        QGeoCoordinate newCoord;
        convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
        innerBufferCoords.push_back(newCoord);
    }

    if(innerPolygon.inners().size() > 0) {
        boost::geometry::correct(innerPolygon);
        for(const auto& interiorRing : innerPolygon.inners()) {
            //boost::geometry::correct(interiorRing);
            boost::geometry::model::ring<WindAwareMissionPlanner::point> ring = interiorRing;
            boost::geometry::correct(ring);

            for(const auto& point : ring) {
                QGeoCoordinate newCoord;
                convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
                innerInteriorBufferCoords.push_back(newCoord);
            }
            QGCFencePolygon* newInnerInnerBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
            _constructGeoFencePolygon(newInnerInnerBufferPoly, innerInteriorBufferCoords);
            innerBufferInteriorPolygons()->append(newInnerInnerBufferPoly);
            innerInteriorBufferCoords.clear();
        }
    }


    QGCFencePolygon* newInnerBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
    _constructGeoFencePolygon(newInnerBufferPoly, innerBufferCoords);



    // Draw outer buffer around inner buffer
    QList<QGeoCoordinate> outerBufferCoords;
    QList<QGeoCoordinate> outerInteriorBufferCoords;

    WindAwareMissionPlanner::polygon outerPoly = _generateOuterBufferPolygon(innerPolygon);

    // Convert buffer points back to lat lon coordinates
    for(const auto& point : outerPoly.outer()) {
        QGeoCoordinate newCoord;
        convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
        outerBufferCoords.push_back(newCoord);
    }

    if (outerPoly.inners().size() > 0) {
        boost::geometry::correct(outerPoly);
        for (const auto& interiorRing : outerPoly.inners()) {

            for (const auto& point : interiorRing) {
                QGeoCoordinate newCoord;
                convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
                outerInteriorBufferCoords.push_back(newCoord);
            }

            QGCFencePolygon* newOuterInnerBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
            _constructGeoFencePolygon(newOuterInnerBufferPoly, outerInteriorBufferCoords);
            outerBufferInteriorPolygons()->append(newOuterInnerBufferPoly);
            outerInteriorBufferCoords.clear();
        }
    }


    QGCFencePolygon* newOuterBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
    _constructGeoFencePolygon(newOuterBufferPoly, outerBufferCoords);

    innerWindBufferPolygon()->clearAndDeleteContents();
    outerWindBufferPolygon()->clearAndDeleteContents();

    innerWindBufferPolygon()->append(newInnerBufferPoly);
    outerWindBufferPolygon()->append(newOuterBufferPoly);


    //qDebug() << "OUTERINTERIOR Len: " << outerBufferInteriorPolygons()->count() << " | INNERINTERIOR LEN: " << innerBufferInteriorPolygons()->count();

}
