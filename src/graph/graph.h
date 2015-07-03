#pragma once

#include <QQuickItem>
#include <QSGNode>
#include "../convenience.h"

/**
 *      Scene graph nodes
 *
 */
class LineNode;
class ShadowNode;

struct GraphNode: public QSGNode
{
    LineNode *line = nullptr;
    ShadowNode *shadow = nullptr;
};

/**
 *      The Graph class
 *
 */
class Graph: public QQuickItem
{
    Q_OBJECT

/**
 *      Enums
 *
 */
public:
    enum NavigationType
    {
        Idle,
        Pan,
        ReadyToPan,
        Zoom,
        ZoomFinished
    };

    enum Step
    {
        StepSimple,
        StepPre,
        StepPost,
        Bars
    };

    Q_ENUMS(NavigationType)
    Q_ENUMS(Step)

/**
 *      Properties
 *
 */
    Q_PROPERTY_DEF(QString, name, name, setName, "")
    Q_PROPERTY_DEF(QString, role, role, setRole, "")
    Q_PROPERTY_DEF(QColor, color, color, setColor, Qt::black)
    Q_PROPERTY_DEF(bool, isPersistentGraph, isPersistentGraph, setIsPersistentGraph, true)

    Q_PROPERTY_DEF(qreal, left,   left,   setLeft,   0.)
    Q_PROPERTY_DEF(qreal, right,  right,  setRight,  0.)
    Q_PROPERTY_DEF(qreal, bottom, bottom, setBottom, 0.)
    Q_PROPERTY_DEF(qreal, top,    top,    setTop,    0.)

    Q_PROPERTY_DEF(int, count, count, setCount, 0)

    Q_PROPERTY_DEF(Step,  step,  step,  setStep,  Step::StepSimple)
    Q_PROPERTY_DEF(qreal, shadowOpacity, shadowOpacity, setShadowOpacity, 0.1)

    Q_PROPERTY_DEF(qreal, screenWidth,  screenWidth,  setScreenWidth,  640.)
    Q_PROPERTY_DEF(qreal, screenHeight, screenHeight, setScreenHeight, 480.)

public:
    Graph();
    ~Graph();

protected:
    QSGNode* updatePaintNode(QSGNode*, UpdatePaintNodeData*) override;
    void geometryChanged(const QRectF &, const QRectF &) override;

public slots:
    void push_back(qreal x, qreal y);
    void pop_front();
    void clear();

private:
    QList<QPointF> m_samples;

    bool m_samplesChanged = false;
    bool m_geometryChanged = false;
};
