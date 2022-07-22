#ifndef WINDAWAREMISSIONPLANNER_H
#define WINDAWAREMISSIONPLANNER_H

#include "QGCCorePlugin.h"
#include "MissionController.h"
#include <QGeoPolygon>

#include "boost/geometry.hpp"
#include "boost/geometry/geometries/point_xy.hpp"
#include "boost/geometry/geometries/geometries.hpp"
#include "boost/geometry/algorithms/buffer.hpp"

// ====================================
// BUFFER SETTINGS DEF
// ====================================

class BufferSettings : public QObject {
    Q_OBJECT
public:
    // Initialization
    BufferSettings(QObject* parent = nullptr);
    BufferSettings(QString color, double radius);

    // Setters
    void SetStyle(QString color, double radius, bool isVisible = true);
    void SetColor(QString color) {this->color = color; }
    void SetRadius(double radius) {this->radius = radius; }
    void SetVisible(bool visible) {this->isVisible = visible;}

    // C++ Accessors
    QString GetColor(void) {return color; }
    double GetRadius(void) { return radius; }
    bool GetVisible(void) {return isVisible; }
    int GetPointsInRadius(void) {return pointsInRadius; }

    // QML Accessors
    Q_PROPERTY(QString color READ GetColor WRITE SetColor NOTIFY BufferSettingsChanged)
    Q_PROPERTY(double radius READ GetRadius WRITE SetRadius NOTIFY BufferSettingsChanged)
    Q_PROPERTY(bool visible READ GetVisible WRITE SetVisible NOTIFY BufferSettingsChanged)

signals:
    void BufferSettingsChanged(void);

private:
    QString     color;
    double      radius;
    int         pointsInRadius = 20;
    bool        isVisible;
};


// ====================================
// WIND BUFFER DEF
// ====================================

class WindBuffer : public QObject {
    Q_OBJECT
public:
    // Initialization
    WindBuffer(QObject* parent = nullptr);

    // Setters
    void SetPolygon(QGCFencePolygon* newPolygon);

    // C++ Accessors
    BufferSettings* GetSettings(void) { return &settings; }
    QmlObjectListModel* GetPolygon(void) { return &polygon; }

    // QML Accessors
    Q_PROPERTY(QmlObjectListModel* polygon READ GetPolygon CONSTANT)
    Q_PROPERTY(BufferSettings* settings READ GetSettings CONSTANT)


private:
    BufferSettings settings;
    QmlObjectListModel polygon;
};


// ====================================
// WindAwareMissionPlanner DEF
// ====================================

class WindAwareMissionPlanner : public QObject {
    Q_OBJECT

public:

    WindAwareMissionPlanner(QObject* parent = nullptr);

    // Accessed by MainRootWindow to initialize planner
    Q_INVOKABLE void start(void);

    // Accessed by Risk Margin page to configure appearance
    Q_INVOKABLE void setInnerBufferSettings(QString color, double radius, bool isVisible = true);
    Q_INVOKABLE void setOuterBufferSettings(QString color, double radius, bool isVisible = true);

//    Q_INVOKABLE void setInnerBufferColor(QString color);
//    Q_INVOKABLE void setInnerBufferRadius(double radius);
//    Q_INVOKABLE void setInnerBufferVisible(bool visible);
//    Q_INVOKABLE void setOuterBufferColor(QString color);
//    Q_INVOKABLE void setOuterBufferRadius(double radius);
//    Q_INVOKABLE void setOuterBufferVisible(bool visible);

    // Accessed by FlyView and PlanView to draw buffers
    Q_PROPERTY(WindBuffer* outerFlyBuffer READ getOuterFlyBuffer CONSTANT)
    Q_PROPERTY(WindBuffer* innerFlyBuffer READ getInnerFlyBuffer CONSTANT)
    Q_PROPERTY(WindBuffer* outerPlanBuffer READ getOuterPlanBuffer CONSTANT)
    Q_PROPERTY(WindBuffer* innerPlanBuffer READ getInnerPlanBuffer CONSTANT)
    Q_PROPERTY(PlanMasterController* flyViewMasterController MEMBER flyViewMasterController NOTIFY flyViewMasterControllerChanged)
    Q_PROPERTY(PlanMasterController* planViewMasterController MEMBER planViewMasterController NOTIFY planViewMasterControllerChanged)


    WindBuffer* getOuterFlyBuffer() { return &outerFlyBuffer; }
    WindBuffer* getInnerFlyBuffer() { return &innerFlyBuffer; }
    WindBuffer* getOuterPlanBuffer() { return &outerPlanBuffer; }
    WindBuffer* getInnerPlanBuffer() { return &innerPlanBuffer; }

    // Polygon data types
    typedef double coordinate_type;
    typedef boost::geometry::model::d2::point_xy<coordinate_type> point;
    typedef boost::geometry::model::polygon<point> polygon;


public slots:

    void UpdateFlyBuffer(void);
    void UpdatePlanBuffer(void);
    void flyViewMasterControllerChanged(void);
    void planViewMasterControllerChanged(void);


private:

    WindBuffer  outerFlyBuffer;
    WindBuffer  innerFlyBuffer;

    WindBuffer  outerPlanBuffer;
    WindBuffer  innerPlanBuffer;

    QTimer*     updateTimer;
    int         updateIntervalMilliseconds = 250;

    PlanMasterController* flyViewMasterController = nullptr;
    PlanMasterController* planViewMasterController = nullptr;



};


// ====================================
// BUFFER GENERATOR DEF
// ====================================

class BufferGenerator {
public:
    // Builds circular polygon around given point
    static QGCFencePolygon* GenerateCircularBuffer(QGeoCoordinate centerCoordinate,
                                                   double circleRadius,
                                                   int numPoints,
                                                   PlanMasterController* masterController);
    // More general polygon generation
    static WindAwareMissionPlanner::polygon GeneratePolygon(QList<WindAwareMissionPlanner::point> pointList_cartesian, double radius, int pointsInRadius);


    // Converts geographic coord (lat/lon) into local-tangent-plane coordinate (x/y/z)
    static WindAwareMissionPlanner::point ConvertGeoPointToLTP(QGeoCoordinate point, QGeoCoordinate ltpOrigin);
    static QList<WindAwareMissionPlanner::point> ConvertGeoPointToLTP(QList<QGeoCoordinate> points, QGeoCoordinate ltpOrigin);

    // Converts local-tangent-plane coordinate (x/y/z) into geographic coord (lat/lon)
    static QGeoCoordinate ConvertLTPToGeoPoint(WindAwareMissionPlanner::point point, QGeoCoordinate ltpOrigin);
    static QList<QGeoCoordinate> ConvertLTPToGeoPoint(QList<WindAwareMissionPlanner::point> points, QGeoCoordinate ltpOrigin);

    static void BuildGeoFence(QList<QGeoCoordinate> coordList, QGCFencePolygon* geoFencePolygon);
    static QList<WindAwareMissionPlanner::point> ConvertPolygonToPointList(WindAwareMissionPlanner::polygon poly);
};

// ====================================
// TRAJECTORY GENERATOR DEF
// ====================================

class TrajectoryGenerator {
public:
private:
};



//class WindAwareMissionPlanner : public QObject
//{
//    Q_OBJECT


//public:

//    typedef double coordinate_type;
//    typedef boost::geometry::model::d2::point_xy<coordinate_type> point;
//    typedef boost::geometry::model::polygon<point> polygon;
//    WindAwareMissionPlanner(QObject* parent = nullptr);
//    WindAwareMissionPlanner(PlanMasterController* masterController, QObject* parent = nullptr);

//    // New trajectory generation and updating. Accessible from QML.
//    Q_INVOKABLE void approveOptimalTrajectory(bool approve);
//    Q_INVOKABLE void generateOptimalTrajectory(void);
//    Q_INVOKABLE void generateWindBuffer(void);


//    // Properties needed by QML
//    Q_PROPERTY(QmlObjectListModel*  plannedItems                        READ    plannedItems                        NOTIFY plannedItemsChanged)
//    Q_PROPERTY(QmlObjectListModel*  simplePlannedFlightPathSegments     READ    simplePlannedFlightPathSegments     NOTIFY plannedFlightSegmentsChanged)
//    Q_PROPERTY(QmlObjectListModel*  innerWindBufferPolygon              READ    innerWindBufferPolygon              CONSTANT)
//    Q_PROPERTY(QmlObjectListModel*  outerWindBufferPolygon              READ    outerWindBufferPolygon              CONSTANT)
//    Q_PROPERTY(QmlObjectListModel*  innerBufferInteriorPolygons         READ    innerBufferInteriorPolygons         CONSTANT)
//    Q_PROPERTY(QmlObjectListModel*  outerBufferInteriorPolygons         READ    outerBufferInteriorPolygons         CONSTANT)
//    Q_PROPERTY(QString              innerBufferColor                    MEMBER  _innerBufferColor                   NOTIFY bufferPropertiesChanged)
//    Q_PROPERTY(QString              outerBufferColor                    MEMBER  _outerBufferColor                   NOTIFY bufferPropertiesChanged)
//    Q_PROPERTY(double               innerBufferRadius                   MEMBER  _innerBufferRadius                  NOTIFY bufferPropertiesChanged)
//    Q_PROPERTY(double               outerBufferRadius                   MEMBER  _outerBufferRadius                  NOTIFY bufferPropertiesChanged)
//    Q_PROPERTY(QmlObjectListModel*  bufferPolygons                      READ    polygonObjectList                   CONSTANT)
//    Q_PROPERTY(bool                 flightViewBufferVisible             MEMBER  _flightViewBufferVisible            NOTIFY bufferPropertiesChanged)

//    Q_INVOKABLE void start(void);

//    // Accessor for private variable
//    QmlObjectListModel*     plannedItems                        (void) {return _plannedVisualitems; }
//    QmlObjectListModel*     simplePlannedFlightPathSegments     (void) {return &_flightPathSegments; }
//    QmlObjectListModel*     innerWindBufferPolygon              (void) {return &_innerWindBufferPolygon; }
//    QmlObjectListModel*     outerWindBufferPolygon              (void) {return &_outerWindBufferPolygon; }
//    QmlObjectListModel*     innerBufferInteriorPolygons         (void) {return &_innerBufferInteriorPolygons; }
//    QmlObjectListModel*     outerBufferInteriorPolygons         (void) {return &_outerBufferInteriorPolygons; }
//    QGeoPolygon*            outerBufferPolygon                  (void) {return &_outerBufferPolygon; }
//    QmlObjectListModel*     polygonObjectList                   (void) { return &_polygonObjectList; }
//    double                  innerBufferRadius                   (void) {return _innerBufferRadius; }
//    double                  outerBufferRadius                   (void) {return _outerBufferRadius; }



//// WIND BUFFER =============================================================================================
//public:
//    // C++ Accessors
//    QmlObjectListModel*     plannedBufferPolygon                (void) { return &_plannedBufferPolygon; }
//    QmlObjectListModel*     activeInnerBufferPolygon            (void) { return &_activeInnerBufferPolygon; }
//    QmlObjectListModel*     activeOuterBufferPolygon            (void) { return &_activeOuterBufferPolygon; }

//    // QML Accessors
//    Q_PROPERTY(QmlObjectListModel*  plannedBufferPolygon    READ    plannedBufferPolygon    CONSTANT)
//    Q_PROPERTY(QmlObjectListModel*  activeInnerBufferPolygon     READ    activeInnerBufferPolygon     CONSTANT)
//    Q_PROPERTY(QmlObjectListModel*  activeOuterBufferPolygon     READ    activeOuterBufferPolygon     CONSTANT)

//private:
//    // Objects
//    QmlObjectListModel          _plannedBufferPolygon;
//    QmlObjectListModel          _activeInnerBufferPolygon;
//    QmlObjectListModel          _activeOuterBufferPolygon;
//    QTimer*                     _flyviewUpdateTimer;

//    // Functions
//    WindAwareMissionPlanner::polygon _GenerateSurroundingCircle(QGeoCoordinate centerPoint, QGeoCoordinate ltpOrigin, double radius, int pointsInRadius = 15);
//    QList<QGeoCoordinate> _GenerateSurroundingCircle(WindAwareMissionPlanner::point centerPoint, double radius, int pointsInRadius = 15);
//    QGCFencePolygon* _PolygonToQGCFencePolygon(WindAwareMissionPlanner::polygon originalPolygon, QGeoCoordinate ltpOrigin);
//    void _constructGeoFencePolygon(QGCFencePolygon* newPoly, QList<QGeoCoordinate> vertexList);

//// =========================================================================================================

//signals:
//    void plannedItemsChanged                (void);
//    void plannedFlightSegmentsChanged       (void);
//    //void riskManagementSettingsChanged      (void);
//    void bufferPropertiesChanged            (void);
//    //void outerColorChanged                  (void);
//    //void innerRadiusChanged                 (void);
//    //void outerRadiusChanged                 (void);

//public slots:
//    void generateWindBuffer_slot (void);
//    void bufferPropertiesChanged_slot (void);

//private:
//    // Risk margin parameters
//    QString                 _innerBufferColor = "orange";
//    QString                 _outerBufferColor = "red";
//    double                  _innerBufferRadius = 5.0;
//    double                  _outerBufferRadius = 10.0; // Distance from trajectory to outer buffer
//    bool                    _flightViewBufferVisible = false;

//    // Used to generate, store, display polygons
//    PlanMasterController*       _masterController;
//    QmlObjectListModel*         _plannedVisualitems;
//    QmlObjectListModel          _flightPathSegments;
//    QmlObjectListModel          _innerWindBufferPolygon;
//    QmlObjectListModel          _outerWindBufferPolygon;
//    QmlObjectListModel          _innerBufferInteriorPolygons;
//    QmlObjectListModel          _outerBufferInteriorPolygons;
//    QGeoPolygon                 _outerBufferPolygon;



//    // Wind risk buffer generation, display
//    void                                        _computeWindBufferPolygons(void);
//    WindAwareMissionPlanner::polygon            _generateBufferPolygon(QList<WindAwareMissionPlanner::point> trajectoryCoords_Cartesian, double radius, int pointsInRadius = 10);

//    // New trajectory insertion and preview generation
//    void                _regenerateFlightSegments(void);
//    void                _insertOptimalTrajectory(void);
//    void                _printCurrentItems(void);
//    FlightPathSegment*  _createFlightPathSegment(VisualItemPair& itemPair, bool mavlinkTerrainFrame);
//    VisualMissionItem*  _insertSimplePlannedMissionItem(QGeoCoordinate coordinate, int visualItemIndex, bool makeCurrentItem);


//    QmlObjectListModel      _polygonObjectList;
//};

#endif // WINDAWAREMISSIONPLANNER_H
