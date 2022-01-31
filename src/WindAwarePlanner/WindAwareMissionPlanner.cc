
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

WindAwareMissionPlanner::WindAwareMissionPlanner(QObject* parent) : QObject(parent)
{
    // Store mission controller
    qDebug("wind aware planner live");
    this->count = 10;
}

void WindAwareMissionPlanner::updateTrajectoryRecommendation() {

    qDebug() << "Wind: " << this->count++;

}
