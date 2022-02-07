
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

// Prototype by printing message when we decide to calculate new trajectory

#include "WindAwareMissionPlanner.h"
#include "PlanMasterController.h"
#include "QGCCorePlugin.h"
#include "QGCApplication.h"
#include "string.h"
#include "MissionController.h"

WindAwareMissionPlanner::WindAwareMissionPlanner(PlanMasterController* masterController, QObject* parent)
    : QObject(parent),
      _masterController(masterController)

{
    // Store mission controller
    qDebug("wind aware planner live");
    this->count = 10;
    connect(masterController->missionController(), &MissionController::testSignal, this, &WindAwareMissionPlanner::updateTrajectoryRecommendation);
}

void WindAwareMissionPlanner::newTrajectoryResponse(bool response) {

    if(response) {
        qDebug() << "TRUE!";
        QmlObjectListModel* itemList = _masterController->missionController()->visualItems(); // Can use this to extract mission item list

        for(int i = 0; i < itemList->count(); i++) {
            qDebug() << itemList->objectList()->at(i);
        }
    }
    else {
        qDebug() << "FALSE!";
        _masterController->missionController()->removeAll(); // Can use this to erase mission items.
    }

}

void WindAwareMissionPlanner::updateTrajectoryRecommendation() {

    qDebug() << "Wind: " << this->count++;
    if (this->count % 5 == 0) {
        _masterController->missionController()->insertSimpleMissionItem(QGeoCoordinate(37.803784, -122.462276), 2, true);
    }

}
