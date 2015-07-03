#include "graph.h"

#include "noisynode.h"
#include "gridnode.h"
#include "linenode.h"

LineStyle toLineStyle(Graph::Step step)
{
    switch (step)
    {
    case Graph::StepSimple:
        return LineStyle::Simple;
    case Graph::StepPre:
        return LineStyle::Pre;
    case Graph::StepPost:
        return LineStyle::Post;
    case Graph::Bars:
        return LineStyle::Bars;
    default:
        throw std::logic_error("toLineStyle(): Invalid step occurred");
    }
}

Graph::Graph()
{
    setFlag(ItemHasContents, true);
    setAntialiasing(true);

    connect(this, &Graph::leftChanged,   this, &Graph::update);
    connect(this, &Graph::rightChanged,  this, &Graph::update);
    connect(this, &Graph::bottomChanged, this, &Graph::update);
    connect(this, &Graph::topChanged,    this, &Graph::update);
}

Graph::~Graph()
{}

void
Graph::push_back(qreal x, qreal y)
{
    m_samples.push_back({x, y});
    m_samplesChanged = true;
    setCount(m_samples.size());
    update();
}


void
Graph::pop_front()
{
    m_samples.removeFirst();
    m_samplesChanged = true;
    setCount(m_samples.size());
    update();
}

void
Graph::clear()
{
    m_samples.clear();
    m_samplesChanged = true;
    setCount(m_samples.size());
    update();
}

void
Graph::geometryChanged(const QRectF &newGeometry, const QRectF &oldGeometry)
{
    m_geometryChanged = true;
    update();
    QQuickItem::geometryChanged(newGeometry, oldGeometry);
}

QSGNode*
Graph::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *)
{
    auto node = static_cast<GraphNode*>(oldNode);

    QRectF rect = boundingRect();

    if (rect.isEmpty())
    {
        if (node)
        {
            delete node;
        }
        return nullptr;
    }

    if (!node)
    {
        node = new GraphNode();

        auto c = color();
        c.setAlphaF(_shadowOpacity);

        node->line = new LineNode(color());
        node->shadow = new ShadowNode(c);

        node->appendChildNode(node->shadow);
        node->appendChildNode(node->line);
    }

    if (m_geometryChanged || m_samplesChanged)
    {
        auto style = toLineStyle(_step);
        node->line->updateGeometry(rect, m_samples, style);
        node->shadow->updateGeometry(rect, m_samples, style);
    }

    QVector4D scaleOffset;
    scaleOffset.setX(1. / (_right - _left));
    scaleOffset.setY(1.);
    scaleOffset.setZ(-_left * _screenWidth);
    scaleOffset.setW(0.);

    node->line->setUniforms(
        [this, &scaleOffset](BaseNode::uniforms_type &mat)
    {
        mat.scaleOffset = scaleOffset;
    });

    node->shadow->setUniforms(
        [this, &scaleOffset](BaseNode::uniforms_type &mat)
    {
        mat.scaleOffset = scaleOffset;
    });

    m_geometryChanged = false;
    m_samplesChanged = false;

    return node;
}
