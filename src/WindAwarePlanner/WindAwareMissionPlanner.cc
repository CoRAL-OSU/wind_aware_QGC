
/* Author: Max DeSantis
 * Purpose: Generate and recommend wind-optimal trajectories to users.
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

//WindAwareMissionPlanner::WindAwareMissionPlanner(QObject* parent) : QObject (parent) {
//    qDebug() << "creating wamp.";
//}

//WindAwareMissionPlanner::WindAwareMissionPlanner(PlanMasterController* masterController, QObject* parent)
//    : QObject(parent),
//      _masterController(masterController),
//      _plannedVisualitems(new QmlObjectListModel(this))
//{
//    // Connect WindBuffer generation to misioncontroller's update

//    if(masterController->flyView()) {
//        //connect(this, &WindAwareMissionPlanner::bufferPropertiesChanged, this, &WindAwareMissionPlanner::generateWindBuffer_slot);
//        _flyviewUpdateTimer = new QTimer(this);
//        connect(_flyviewUpdateTimer, &QTimer::timeout, this, &WindAwareMissionPlanner::bufferPropertiesChanged_slot);
//        _flyviewUpdateTimer->start(500);
//        //connect(this, &WindAwareMissionPlanner::bufferPropertiesChanged, this, &WindAwareMissionPlanner::bufferPropertiesChanged_slot);
//    }
//    else {
//        connect(this->_masterController->missionController()->visualItems(), &QmlObjectListModel::dirtyChanged, this, &WindAwareMissionPlanner::generateWindBuffer_slot);
//        connect(this->_masterController->missionController()->visualItems(), &QmlObjectListModel::countChanged, this, &WindAwareMissionPlanner::generateWindBuffer_slot);
//    }
//}

////void WindAwareMissionPlanner::start(void) {
////    qDebug() << "starting WAMP!";
////}


///*********************************************************************************************
// *
// *  New trajectory generation and updating
// *
// ********************************************************************************************/

//// Generates new trajectory
//void WindAwareMissionPlanner::generateOptimalTrajectory() {
//    _plannedVisualitems->clear();

//    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();

//    VisualMissionItem* newEndPoint = qobject_cast<VisualMissionItem*>(currentItems->get(currentItems->count()-1));
//    VisualMissionItem* oldTakeoff = qobject_cast<VisualMissionItem*>(currentItems->get(1));

//    int itemIndex = 1;

//    _insertSimplePlannedMissionItem(oldTakeoff->coordinate(), itemIndex++, false);

//    if(currentItems->count() > 4) {
//        int numWaypoints = currentItems->count() - 3; // Exclude settings (0) takeoff(1) and last waypoint (currentItems->count(0 - 1)
//        int ratio = 2;

//        int numIntermediatePoints = floor(numWaypoints / ratio);

//        for(int i = 1; i <= numIntermediatePoints; i++) {
//            VisualMissionItem* intermediatePoint = qobject_cast<VisualMissionItem*>(currentItems->get(i * ratio));
//            _insertSimplePlannedMissionItem(intermediatePoint->coordinate(), itemIndex++, false);
//        }

//    }

//    _insertSimplePlannedMissionItem(newEndPoint->coordinate(), itemIndex++, false);
//    emit plannedItemsChanged();

//    _regenerateFlightSegments();
//}

//// If user approves new trajectory, replace it. Otherwise, delete it.
//void WindAwareMissionPlanner::approveOptimalTrajectory(bool approve) {

//    if(approve) {
//       if(plannedItems()->count()) {
//           _insertOptimalTrajectory();
//       } else {
//           qDebug() << "Cannot update trajectory - no optimal trajectory found.";
//       }
//    }
//    else {
//        plannedItems()->clearAndDeleteContents();
//    }
//    emit plannedItemsChanged();
//    _regenerateFlightSegments();
//}

//// Replacing old trajectory with optimally generated trajectory
//void WindAwareMissionPlanner::_insertOptimalTrajectory() {
//    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
//    qDebug() << "in update, count= "<< currentItems->count();

//    // Remove 2nd waypoint j-2 times. ie preserve waypoints 0 and 1, the mission settings and takeoff.
//    int j = currentItems->count();
//    for(int i = 1; i < j; i++) {
//        _masterController->missionController()->removeVisualItem(1);
//    }
//    VisualMissionItem* takeoffItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(0));
//    _masterController->missionController()->insertTakeoffItem(takeoffItem->coordinate(), 1, true);

//    for(int i = 1; i < plannedItems()->count(); i++) {
//        VisualMissionItem* newItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(i));
//        _masterController->missionController()->insertSimpleMissionItem(newItem->coordinate(), newItem->sequenceNumber(), true);
//    }

//    for(int i = 0; i < currentItems->count(); i++) {
//        qDebug() << "item: " << i << " " << currentItems->objectList()->at(i);
//    }

//    _plannedVisualitems->clear();
//}

//// Builds new mission item and inserts to the list of planned items
//VisualMissionItem* WindAwareMissionPlanner::_insertSimplePlannedMissionItem(QGeoCoordinate coordinate, int visualItemIndex, bool makeCurrentItem) {
//    SimpleMissionItem* newItem = new SimpleMissionItem(_masterController, false, false);
//    newItem->setCoordinate(coordinate);
//    newItem->setCommand(MAV_CMD_NAV_WAYPOINT);
//    newItem->setSequenceNumber(visualItemIndex);

//    _plannedVisualitems->append(newItem);

//    return newItem;
//}

//// Generates new flight segments that connect planned visual items, for preview on PlanView
//void WindAwareMissionPlanner::_regenerateFlightSegments() {

//    simplePlannedFlightPathSegments()->clear();
//    VisualItemPair itemPair;
//    VisualMissionItem* lastItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(0));
//    VisualMissionItem* newItem;
//    for(int i = 0; i < plannedItems()->count() - 1; i++) {

//        newItem = qobject_cast<VisualMissionItem*>(plannedItems()->get(i+1));
//        itemPair = VisualItemPair(lastItem, newItem);
//        lastItem = newItem;

//        FlightPathSegment* segment = _createFlightPathSegment(itemPair, true);
//        simplePlannedFlightPathSegments()->append(segment);
//    }
//    emit plannedFlightSegmentsChanged();
//}

//// Creates a flight segment between a pair of visual items
//FlightPathSegment* WindAwareMissionPlanner::_createFlightPathSegment(VisualItemPair& itemPair, bool mavlinkTerrainFrame) {
//    bool takeoffStraightUp = itemPair.second->isTakeoffItem() && !_masterController->controllerVehicle()->fixedWing();
//    QGeoCoordinate coord1 = itemPair.first->exitCoordinate();
//    QGeoCoordinate coord2 = itemPair.second->coordinate();
//    double              coord2AMSLAlt       = itemPair.second->amslEntryAlt();
//    double              coord1AMSLAlt       = takeoffStraightUp ? coord2AMSLAlt : itemPair.first->amslExitAlt();

//    FlightPathSegment::SegmentType segType = mavlinkTerrainFrame ? FlightPathSegment::SegmentTypeTerrainFrame : FlightPathSegment::SegmentTypeGeneric;
//    if(itemPair.second->isTakeoffItem()) {
//        segType = FlightPathSegment::SegmentTypeTakeoff;
//    } else if (itemPair.second->isLandCommand()) {
//        segType = FlightPathSegment::SegmentTypeLand;
//    }

//    FlightPathSegment* segment = new FlightPathSegment(segType, coord1, coord1AMSLAlt, coord2, coord2AMSLAlt, false, this);

//    return segment;
//}

//// Prints visual items currently being used by master controller
//void WindAwareMissionPlanner::_printCurrentItems() {
//    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
//    for(int i = 0; i < currentItems->count(); i++) {
//        qDebug() << "item: " << i << " " << currentItems->objectList()->at(i) << " sequence: " << qobject_cast<VisualMissionItem*>(currentItems->objectList()->at(i))->sequenceNumber();
//    }
//}




///*********************************************************************************************
// *
// *  Wind Buffer, Risk Management
// *
// ********************************************************************************************/

//// User input or master update, generate new buffer around trajectory.
//void WindAwareMissionPlanner::generateWindBuffer() {
//    if(_masterController->missionController()->visualItems()->count() > 2)
//        _computeWindBufferPolygons();
//}

//void WindAwareMissionPlanner::generateWindBuffer_slot() {
//    generateWindBuffer();
//    bufferPropertiesChanged_slot();
//}

//void WindAwareMissionPlanner::_constructGeoFencePolygon(QGCFencePolygon* newPoly, QList<QGeoCoordinate> vertexList) {
//    for (const auto& c : vertexList) {
//        newPoly->appendVertex(c);
//    }
//    newPoly->setInteractive(false);
//    newPoly->setInclusion(false);
//}

//WindAwareMissionPlanner::polygon WindAwareMissionPlanner::_generateBufferPolygon(QList<point> trajectoryCoords_Cartesian, double radius, int pointsInRadius) {

//    boost::geometry::strategy::buffer::distance_symmetric<coordinate_type> dist_strategy(radius);
//    boost::geometry::strategy::buffer::join_round join_strategy(pointsInRadius);
//    boost::geometry::strategy::buffer::end_round end_strategy(pointsInRadius);
//    boost::geometry::strategy::buffer::point_circle circle_strategy(pointsInRadius);
//    boost::geometry::strategy::buffer::side_straight side_strategy;

//    boost::geometry::model::multi_polygon<polygon> multiPoly;
//    boost::geometry::model::linestring<point> ls;

//    for( auto& c : trajectoryCoords_Cartesian) {
//        ls.push_back(c);
//    }

//    boost::geometry::buffer(ls, multiPoly,
//                dist_strategy, side_strategy,
//                join_strategy, end_strategy, circle_strategy);

//    return multiPoly.at(0);
//}

//void WindAwareMissionPlanner::_computeWindBufferPolygons() {

//    innerBufferInteriorPolygons()->clearAndDeleteContents();
//    outerBufferInteriorPolygons()->clearAndDeleteContents();
//    qDebug() << "Inner rad: " << _innerBufferRadius;
//    qDebug() << "Outer rad: " << _outerBufferRadius;

//    // Get lat lon coords from visual items
//    QmlObjectListModel* currentItems = _masterController->missionController()->visualItems();
//    QList<QGeoCoordinate> trajectoryCoords;
//    QList<QGeoCoordinate> innerBufferCoords;
//    QList<QGeoCoordinate> innerInteriorBufferCoords;
//    QList<point> trajectoryCartesian;

//    WindAwareMissionPlanner::polygon innerPolygon;

//    // LatLon coords of trajectory
//    for(int i = 1; i < currentItems->count(); i++) {
//        VisualMissionItem* newItem = qobject_cast<VisualMissionItem*>(currentItems->get(i));
//        trajectoryCoords.push_back(newItem->coordinate());
//    }

//    // Convert lat lon coords to LTP coords, store as boost::geometry points
//    QGeoCoordinate ltpOrigin = trajectoryCoords.at(0); // starting point
//    for(const auto& coord : trajectoryCoords) {
//        double ltpX, ltpY, ltpZ;
//        convertGeoToNed(coord, ltpOrigin, &ltpX, &ltpY, &ltpZ);
//        point newP = point(ltpX, ltpY);
//        trajectoryCartesian.push_back(newP);
//    }

//    // Generate inner buffer --------------------------------------------
//    if(this->innerBufferRadius() > 0) {
//        innerPolygon = _generateBufferPolygon(trajectoryCartesian, this->innerBufferRadius());

//        // Convert buffer points back to lat lon coordinates
//        for(const auto& point : innerPolygon.outer()) {
//            QGeoCoordinate newCoord;
//            convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
//            innerBufferCoords.push_back(newCoord);
//        }

//        if(innerPolygon.inners().size() > 0) {
//            boost::geometry::correct(innerPolygon);
//            for(const auto& interiorRing : innerPolygon.inners()) {
//                boost::geometry::model::ring<WindAwareMissionPlanner::point> ring = interiorRing;
//                boost::geometry::correct(ring);

//                for(const auto& point : ring) {
//                    QGeoCoordinate newCoord;
//                    convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
//                    innerInteriorBufferCoords.push_back(newCoord);
//                }
//                QGCFencePolygon* newInnerInnerBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
//                _constructGeoFencePolygon(newInnerInnerBufferPoly, innerInteriorBufferCoords);
//                innerBufferInteriorPolygons()->append(newInnerInnerBufferPoly);
//                innerInteriorBufferCoords.clear();
//            }
//        }
//        QGCFencePolygon* newInnerBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
//        _constructGeoFencePolygon(newInnerBufferPoly, innerBufferCoords);

//        innerWindBufferPolygon()->clearAndDeleteContents();
//        innerWindBufferPolygon()->append(newInnerBufferPoly);
//    }
//    else {
//        innerWindBufferPolygon()->clearAndDeleteContents();
//    }

//    // Generate outer buffer --------------------------------------------
//    if(this->outerBufferRadius() > 0) {
//        // Draw outer buffer around inner buffer
//        QList<QGeoCoordinate> outerBufferCoords;
//        QList<QGeoCoordinate> outerInteriorBufferCoords;

//        WindAwareMissionPlanner::polygon outerPoly = _generateBufferPolygon(trajectoryCartesian, this->outerBufferRadius());
//        // Convert buffer points back to lat lon coordinates
//        for(const auto& point : outerPoly.outer()) {
//            QGeoCoordinate newCoord;
//            convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
//            outerBufferCoords.push_back(newCoord);
//        }

//        if (outerPoly.inners().size() > 0) {
//            boost::geometry::correct(outerPoly);
//            for (const auto& interiorRing : outerPoly.inners()) {

//                for (const auto& point : interiorRing) {
//                    QGeoCoordinate newCoord;
//                    convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
//                    outerInteriorBufferCoords.push_back(newCoord);
//                }

//                QGCFencePolygon* newOuterInnerBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
//                _constructGeoFencePolygon(newOuterInnerBufferPoly, outerInteriorBufferCoords);
//                outerBufferInteriorPolygons()->append(newOuterInnerBufferPoly);
//                outerInteriorBufferCoords.clear();
//            }
//        }

//        QGCFencePolygon* newOuterBufferPoly = new QGCFencePolygon(true, _masterController->geoFenceController());
//        _constructGeoFencePolygon(newOuterBufferPoly, outerBufferCoords);

//        outerWindBufferPolygon()->clearAndDeleteContents();
//        outerWindBufferPolygon()->append(newOuterBufferPoly);
//    }
//    else {
//        outerWindBufferPolygon()->clearAndDeleteContents();
//    }

//}

//// Generates circular buffer around point with given radius.
//// --- centerPoint in lat/lon. Converts and calls overloaded function.
//WindAwareMissionPlanner::polygon WindAwareMissionPlanner::_GenerateSurroundingCircle(QGeoCoordinate centerPoint, QGeoCoordinate ltpOrigin, double radius, int pointsInRadius) {
//    qDebug() << "Generating circle";
//    // Convert center to LTP localized cartesian point
//    double ltpX, ltpY, ltpZ;
//    convertGeoToNed(centerPoint, ltpOrigin, &ltpX, &ltpY, &ltpZ);
//    WindAwareMissionPlanner::point centerPoint_cartesian(ltpX, ltpY);

//    // Ensure valid inputs
//    if (radius <= 0) radius = 1.0;
//    if (pointsInRadius <= 4) pointsInRadius = 5;

//    using namespace boost::geometry::strategy::buffer;
//    distance_symmetric<coordinate_type> dist_strategy(radius);
//    join_round join_strategy(pointsInRadius);
//    end_round end_strategy(pointsInRadius);
//    point_circle circle_strategy(pointsInRadius);
//    side_straight side_strategy;

//    boost::geometry::model::multi_polygon<polygon> resultingMultiPolygon;

//    boost::geometry::buffer(centerPoint_cartesian, resultingMultiPolygon,
//                            dist_strategy, side_strategy,
//                            join_strategy, end_strategy, circle_strategy);

//    if (resultingMultiPolygon.size() > 0) {
//        qDebug() << "returning valid polygon";
//        for(const auto& point : resultingMultiPolygon.at(0).outer()) {
//            qDebug() << point.x() << ", " << point.y();
//        }
//        return resultingMultiPolygon.at(0);
//    }
//    else {
//        qDebug() << "no valid polygon generated";
//        return WindAwareMissionPlanner::polygon();
//    }
//}

//// Generates circular buffer around point with given radius.
//// --- centerPoint in localized cartesian coordinates.
//QGCFencePolygon* WindAwareMissionPlanner::_PolygonToQGCFencePolygon(WindAwareMissionPlanner::polygon originalPolygon, QGeoCoordinate ltpOrigin) {

//    QList<QGeoCoordinate> bufferCoords_geo;
//    qDebug() << "ltp origin: " << ltpOrigin;
//    // Convert buffer points back to lat lon coordinates
//    for(const auto& point : originalPolygon.outer()) {
//        QGeoCoordinate newCoord;
//        convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);

//        qDebug() << "Old coord: " << point.x() << "," << point.y() << "| Newcoord: " << newCoord;
//        bufferCoords_geo.push_back(newCoord);
//    }

//    // Build fence polygon out of coordinate list
//    QGCFencePolygon* newFencePolygon = new QGCFencePolygon(true, _masterController->geoFenceController());
//    _constructGeoFencePolygon(newFencePolygon, bufferCoords_geo);

//    return newFencePolygon;
//}

//// Main entry point when Risk Margin settings are changed
//void WindAwareMissionPlanner::bufferPropertiesChanged_slot() {

//    // 1. Return if on plan view
//    if(!this->_masterController->flyView()){
//        qDebug() << "not fly view";
//        return;
//    }

//    // 2. Return if no vehicle to display for
//    if(!qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()) {
//        qDebug() << "No active vehicle";
//        return;
//    }

//    // 3. Clear previously generated buffer
//    qDebug() << "Buffer properties changed";
//    this->activeInnerBufferPolygon()->clearAndDeleteContents();
//    this->activeOuterBufferPolygon()->clearAndDeleteContents();

//    // 4. Get vehicle coordinates
//    QGeoCoordinate vehicleCoords = this->_masterController->managerVehicle()->coordinate();
//    qDebug() << "vehicle coords: " << vehicleCoords;

//    // 5. Generate circular (polygon representation) buffer around vehicle
//    WindAwareMissionPlanner::polygon innerBufferCircle = _GenerateSurroundingCircle(vehicleCoords, vehicleCoords, this->innerBufferRadius());
//    WindAwareMissionPlanner::polygon outerBufferCircle = _GenerateSurroundingCircle(vehicleCoords, vehicleCoords, this->outerBufferRadius());

//    // 6. Convert standard polygon into QGC's supported GeoFencePolygon type
//    QGCFencePolygon* innerBufferFencePolygon = _PolygonToQGCFencePolygon(innerBufferCircle, vehicleCoords);
//    QGCFencePolygon* outerBufferFencePolygon = _PolygonToQGCFencePolygon(outerBufferCircle, vehicleCoords);

//    // 7. Ensure nothing went wrong - don't add polygon with too few points
//    if(innerBufferFencePolygon->coordinateList().length() > 3) {
//        qDebug() << "appending polygon";
//        qDebug() << "path: " << innerBufferFencePolygon->path();
//        // 8. Add polygon to view.
//        // --- It is then displayed as a QGCMapPolygonVisual within the FlyView.qml file
//        this->activeInnerBufferPolygon()->append(innerBufferFencePolygon);
//    }

//    // 9. Repeat for outer buffer
//    if(outerBufferFencePolygon->coordinateList().length() > 3) {
//        qDebug() << "appending polygon";
//        qDebug() << "path: " << outerBufferFencePolygon->path();
//        // 810. Add polygon to view.
//        // --- It is then displayed as a QGCMapPolygonVisual within the FlyView.qml file
//        this->activeOuterBufferPolygon()->append(outerBufferFencePolygon);
//    }
//}

// ====================================
// WindAwareMissionPlanner IMPL
// ====================================

WindAwareMissionPlanner::WindAwareMissionPlanner(QObject* parent)
    : QObject (parent),
      outerFlyBuffer(this),
      innerFlyBuffer(this),
      outerPlanBuffer(this),
      innerPlanBuffer(this)
{
    qDebug() << "creating wamp.";
}

void WindAwareMissionPlanner::start(void)
{
    qDebug() << "starting wamp.";

    // Update every set seconds for fly view

    updateTimer = new QTimer(this);
    connect(updateTimer, &QTimer::timeout, this, &WindAwareMissionPlanner::UpdateBuffers);
    updateTimer->start(updateIntervalMilliseconds);

}

void WindAwareMissionPlanner::setInnerBufferSettings(QString color, double radius, bool isVisible)
{
    this->innerFlyBuffer.GetSettings()->SetStyle(color, radius, isVisible);
    this->innerPlanBuffer.GetSettings()->SetStyle(color, radius, isVisible);
}

void WindAwareMissionPlanner::setOuterBufferSettings(QString color, double radius, bool isVisible)
{
    this->outerFlyBuffer.GetSettings()->SetStyle(color, radius, isVisible);
    this->outerPlanBuffer.GetSettings()->SetStyle(color, radius, isVisible);
}

//void WindAwareMissionPlanner::setInnerBufferColor(QString color)
//{
//    this->innerFlyBuffer.GetSettings().
//}

void WindAwareMissionPlanner::UpdateBuffers()
{

    // 1. Ensure we have a reference to the controller
    if(!flyViewMasterController) {
        qDebug() << "Fly view master controller empty";
        return;
    }

    // 2. Ensure controller has a vehicle connected
    if(!qgcApp()->toolbox()->multiVehicleManager()->activeVehicle()) {
        qDebug() << "No active vehicle";
        return;
    }

    // Get vehicle coordinates to center circular buffer
    QGeoCoordinate vehicleCoords = flyViewMasterController->managerVehicle()->coordinate();

    QGCFencePolygon* circularFence = BufferGenerator::GenerateCircularBuffer(vehicleCoords,
                                                                             outerFlyBuffer.GetSettings()->GetRadius(),
                                                                             outerFlyBuffer.GetSettings()->GetPointsInRadius(),
                                                                             flyViewMasterController);
    outerFlyBuffer.SetPolygon(circularFence);

    circularFence = BufferGenerator::GenerateCircularBuffer(vehicleCoords,
                                                            innerFlyBuffer.GetSettings()->GetRadius(),
                                                            innerFlyBuffer.GetSettings()->GetPointsInRadius(),
                                                            flyViewMasterController);

    innerFlyBuffer.SetPolygon(circularFence);
}


// ====================================
// WIND BUFFER IMPL
// ====================================

WindBuffer::WindBuffer(QObject* parent)
    : QObject(parent),
      settings(this)
{

}

void WindBuffer::SetPolygon(QGCFencePolygon* newPolygon)
{
    this->polygon.clearAndDeleteContents();
    this->polygon.append(newPolygon);
}

// ====================================
// BUFFER SETTINGS IMPL
// ====================================

BufferSettings::BufferSettings(QObject* parent) : QObject(parent)
{
    this->SetStyle("orange", 5.0, true);
}

BufferSettings::BufferSettings(QString color, double radius)
{
    this->SetStyle(color, radius, true);
}

void BufferSettings::SetStyle(QString color, double radius, bool isVisible)
{
    this->color = color;
    this->radius = radius;
    this->isVisible = isVisible;
}


// ====================================
// BUFFER GENERATOR IMPL
// ====================================

WindAwareMissionPlanner::point BufferGenerator::ConvertGeoPointToLTP(QGeoCoordinate coord, QGeoCoordinate ltpOrigin)
{
    double ltpX, ltpY, ltpZ;
    convertGeoToNed(coord, ltpOrigin, &ltpX, &ltpY, &ltpZ);
    return WindAwareMissionPlanner::point(ltpX, ltpY);
}

QList<WindAwareMissionPlanner::point> BufferGenerator::ConvertGeoPointToLTP(QList<QGeoCoordinate> coords, QGeoCoordinate ltpOrigin)
{
    QList<WindAwareMissionPlanner::point> newPointList;

    for(const auto& coord : coords) {
        newPointList.push_back(BufferGenerator::ConvertGeoPointToLTP(coord, ltpOrigin));
    }

    return newPointList;
}

QGeoCoordinate BufferGenerator::ConvertLTPToGeoPoint(WindAwareMissionPlanner::point point, QGeoCoordinate ltpOrigin)
{
    QGeoCoordinate newCoord;
    convertNedToGeo(point.x(), point.y(), 0.0, ltpOrigin, &newCoord);
    return newCoord;
}

QList<QGeoCoordinate> BufferGenerator::ConvertLTPToGeoPoint(QList<WindAwareMissionPlanner::point> points, QGeoCoordinate ltpOrigin)
{
    QList<QGeoCoordinate> newCoordList;

    for(const auto& point : points) {
        newCoordList.push_back(BufferGenerator::ConvertLTPToGeoPoint(point, ltpOrigin));
    }

    return newCoordList;
}

WindAwareMissionPlanner::polygon BufferGenerator::GeneratePolygon(QList<WindAwareMissionPlanner::point> pointList_cartesian, double radius, int pointsInRadius)
{
    using namespace boost::geometry::strategy::buffer;
    distance_symmetric<WindAwareMissionPlanner::coordinate_type> dist_strategy(radius);
    join_round join_strategy(pointsInRadius);
    end_round end_strategy(pointsInRadius);
    point_circle circle_strategy(pointsInRadius);
    side_straight side_strategy;

    boost::geometry::model::multi_polygon<WindAwareMissionPlanner::polygon> resultingMultiPolygon;
    boost::geometry::model::linestring<WindAwareMissionPlanner::point> points;

    for(const auto& p : pointList_cartesian) {
        points.push_back(p);
    }

    boost::geometry::buffer(points, resultingMultiPolygon,
                            dist_strategy, side_strategy,
                            join_strategy, end_strategy,
                            circle_strategy);

    if (resultingMultiPolygon.size() > 0) {
        qDebug() << "returning valid polygon";
        return resultingMultiPolygon.at(0);
    }
    else {
        qDebug() << "no valid polygon generated";
        return WindAwareMissionPlanner::polygon();
    }
}

void BufferGenerator::BuildGeoFence(QList<QGeoCoordinate> coordList, QGCFencePolygon *geoFencePolygon)
{
    for(const auto& c : coordList) {
        geoFencePolygon->appendVertex(c);
    }
    geoFencePolygon->setInclusion(false);
    geoFencePolygon->setInteractive(false);
}

QList<WindAwareMissionPlanner::point> BufferGenerator::ConvertPolygonToPointList(WindAwareMissionPlanner::polygon poly)
{
    QList<WindAwareMissionPlanner::point> pointList;
    for(const auto& point : poly.outer()) {
        pointList.push_back(point);
    }

    return pointList;
}

QGCFencePolygon* BufferGenerator::GenerateCircularBuffer(QGeoCoordinate centerCoordinate, double circleRadius, int numPoints, PlanMasterController* masterController)
{
    if(circleRadius <= 0)   circleRadius = 1.0;
    if(numPoints <= 4)      numPoints = 5;

    QGCFencePolygon* circularBufferFencePolygon = new QGCFencePolygon(true, masterController->geoFenceController());
    WindAwareMissionPlanner::point centerPoint_cartesian = BufferGenerator::ConvertGeoPointToLTP(centerCoordinate, centerCoordinate);
    WindAwareMissionPlanner::polygon intermediatePolygon = BufferGenerator::GeneratePolygon(QList<WindAwareMissionPlanner::point>({centerPoint_cartesian}), circleRadius, numPoints);
    QList<QGeoCoordinate> bufferCoords_geo = BufferGenerator::ConvertLTPToGeoPoint(BufferGenerator::ConvertPolygonToPointList(intermediatePolygon), centerCoordinate);
    BufferGenerator::BuildGeoFence(bufferCoords_geo, circularBufferFencePolygon);

    return circularBufferFencePolygon;
}
