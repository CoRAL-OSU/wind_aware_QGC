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
    int count;

//    Q_PROPERTY(WindAwareMissionPlanner*    windAwarePlanner    READ windAwarePlanner               CONSTANT)
    Q_INVOKABLE void newTrajectoryResponse(bool response);

public slots:
    void updateTrajectoryRecommendation();

protected:
    PlanMasterController* _masterController;

};

#endif // WINDAWAREMISSIONPLANNER_H
