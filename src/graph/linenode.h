#pragma once

#include <QColor>
#include <QSGGeometryNode>
#include <QtQuick/QSGSimpleMaterial>

enum class LineStyle
{
    Simple,
    Pre,
    Post,
    Bars
};

/**
 * @brief The LineUniforms struct
 */
struct LineUniforms
{
    QColor color;
    QVector4D scaleOffset;
};

/**
 * @brief The LineShader class
 */
class LineShader: public QSGSimpleMaterialShader<LineUniforms>
{
    QSG_DECLARE_SIMPLE_SHADER(LineShader, LineUniforms)

public:
    LineShader()
    {
        setShaderSourceFile(QOpenGLShader::Vertex,   ":/qmlcomponents/shaders/line.vsh");
        setShaderSourceFile(QOpenGLShader::Fragment, ":/qmlcomponents/shaders/line.fsh");
    }

    QList<QByteArray> attributes() const
    {
        return QList<QByteArray>() << "pos";
    }

    void updateState(const LineUniforms *m, const LineUniforms *)
    {
        program()->setUniformValue(uColor, m->color);
        program()->setUniformValue(uScaleOffset, m->scaleOffset);
    }

    void resolveUniforms()
    {
        uColor = program()->uniformLocation("uColor");
        uScaleOffset = program()->uniformLocation("uScaleOffset");
    }

private:
    int uColor = -1;
    int uScaleOffset = -1;
};

/**
 * @brief The GraphNode class
 */
class BaseNode: public QSGGeometryNode
{
public:
    using uniforms_type = LineUniforms;
    using material_type = QSGSimpleMaterial<uniforms_type>;

    template <typename Proc> void
    setUniforms(Proc proc)
    {
        auto mat = static_cast<material_type*>(material());
        if (mat)
        {
            proc(*mat->state());
            markDirty(QSGNode::DirtyMaterial);
        }
    }

protected:
    qreal m_offset = 0.;
    qreal m_scale = 1.;
};

/**
 * @brief The LineNode class
 */
class LineNode: public BaseNode
{
public:
    LineNode(const QColor &color);

    void updateGeometry(const QRectF &bounds, const QList<QPointF> &samples, LineStyle);

private:
    QSGGeometry m_geometry;
};

/**
 * @brief The ShadowNode class
 */
class ShadowNode: public BaseNode
{
public:
    ShadowNode(const QColor &color);

    void updateGeometry(const QRectF &bounds, const QList<QPointF> &samples, LineStyle);

private:
    QSGGeometry m_geometry;
};
