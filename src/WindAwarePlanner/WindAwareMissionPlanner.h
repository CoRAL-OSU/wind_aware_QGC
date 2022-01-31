#ifndef WINDAWAREMISSIONPLANNER_H
#define WINDAWAREMISSIONPLANNER_H

#include "QGCCorePlugin.h"

class WindAwareMissionPlanner : public QObject
{
    Q_OBJECT




public:
    WindAwareMissionPlanner(QObject* parent = nullptr);
    int count;

public slots:
    void updateTrajectoryRecommendation();

};

#endif // WINDAWAREMISSIONPLANNER_H
