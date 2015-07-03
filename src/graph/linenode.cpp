/****************************************************************************
**
** Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies).
** Contact: http://www.qt-project.org/legal
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of Digia Plc and its Subsidiary(-ies) nor the names
**     of its contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

#include "linenode.h"

#include <QtGui/QColor>

#include <QtQuick/QSGSimpleMaterial>

struct Vertex2D
{
    float x;
    float y;
    inline void set(float xx, float yy) { x = xx; y = yy; }
};

static const QSGGeometry::AttributeSet &
attributes()
{
    static QSGGeometry::Attribute attr[] = {
        QSGGeometry::Attribute::create(0, 2, GL_FLOAT, true),
    };
    static QSGGeometry::AttributeSet set = {
        1, 2 * sizeof(float), attr
    };
    return set;
}

template <typename Proc>
void foreachVertexIn(const QList<QPointF> &samples, LineStyle style, Proc proc)
{
    switch(style)
    {
    case LineStyle::Simple:
    {
        for (int i = 0; i < samples.size(); ++i)
        {
            auto &s = samples.at(i);
            proc(s.x(), s.y());
        }
        break;
    }
    case LineStyle::Pre:
    case LineStyle::Post:
    {
        for (int i = 0; i < samples.size(); ++i)
        {
            auto &s0 = samples.at(i);

            proc(s0.x(), s0.y());

            if (i < samples.size() - 1)
            {
                auto &s1 = samples.at(i + 1);

                if (style == LineStyle::Pre)
                {
                    proc(s0.x(), s1.y());
                }
                else if (style == LineStyle::Post)
                {
                    proc(s1.x(), s0.y());
                }
            }
        }
        break;
    }

    case LineStyle::Bars:
    {
        for (int i = 0; i < samples.size(); ++i)
        {
            auto &s0 = samples[i];

            qreal x0 = s0.x();
            qreal x1 = s0.x();

            if (i > 0)
            {
                auto &s1 = samples[i - 1];
                x0 = s0.x() * .75 + s1.x() * .25;
            }

            if (i < samples.size() - 1)
            {
                auto &s1 = samples[i + 1];
                x1 = s0.x() * .75 + s1.x() * .25;
            }

            proc(x0, 1.);
            proc(x0, s0.y());
            proc(x1, s0.y());
            proc(x1, 1.);
        }
        break;
    }
    }
}

/**
 * @brief LineNode class
 *
 */
LineNode::LineNode(const QColor &color)
    : m_geometry(attributes(), 0)
{
    setGeometry(&m_geometry);
    m_geometry.setDrawingMode(GL_LINE_STRIP);

    auto material = LineShader::createMaterial();
    material->state()->color = color;
    material->setFlag(QSGMaterial::Blending);

    setMaterial(material);
    setFlag(OwnsMaterial);
}

void LineNode::updateGeometry(const QRectF &bounds,
                              const QList<QPointF> &samples, LineStyle style)
{
    if (samples.size() == 0)
    {
        return;
    }

    switch(style)
    {
    case LineStyle::Simple:
        m_geometry.allocate(samples.size());
        break;

    case LineStyle::Pre:
    case LineStyle::Post:
        m_geometry.allocate(samples.size() * 2 - 1);
        break;
    case LineStyle::Bars:
        m_geometry.allocate(samples.size() * 4);
        break;
    }

    auto v = reinterpret_cast<Vertex2D*>(m_geometry.vertexData());
    foreachVertexIn(samples, style,
        [&](qreal x, qreal y)
    {
        (v++)->set(bounds.x() + x * bounds.width(),
                   bounds.y() + y * bounds.height());
    });


    markDirty(QSGNode::DirtyGeometry);
}

/**
 * @brief ShadowNode class
 *
 */
ShadowNode::ShadowNode(const QColor &color)
    : m_geometry(attributes(), 0)
{
    setGeometry(&m_geometry);

    auto material = LineShader::createMaterial();
    material->state()->color = color;
    material->setFlag(QSGMaterial::Blending);

    setMaterial(material);
    setFlag(OwnsMaterial);
}

void
ShadowNode::updateGeometry(const QRectF &bounds,
                           const QList<QPointF> &samples, LineStyle style)
{
    if (samples.size() == 0)
    {
        return;
    }

    m_geometry.setDrawingMode(style == LineStyle::Bars ?
                                  GL_TRIANGLES : GL_TRIANGLE_STRIP);

    switch(style)
    {
    case LineStyle::Simple:
        m_geometry.allocate(samples.size() * 2);
        break;

    case LineStyle::Pre:
    case LineStyle::Post:
        m_geometry.allocate((samples.size() * 2 - 1) * 2);
        break;
    case LineStyle::Bars:
        m_geometry.allocate(samples.size() * 6);
        break;
    }

    auto v = reinterpret_cast<Vertex2D*>(m_geometry.vertexData());
    if (style != LineStyle::Bars)
    {
        foreachVertexIn(samples, style,
            [&](qreal x, qreal y)
        {
            (v++)->set(bounds.x() + x * bounds.width(),
                       bounds.y() + y * bounds.height());

            (v++)->set(bounds.x() + x * bounds.width(),
                       bounds.y() + bounds.height());
        });
    }
    else
    {
        QVector<QPointF> points;

        foreachVertexIn(samples, style,
            [&](qreal x, qreal y)
        {
            points.push_back({x, y});

            if (points.size() == 4)
            {
                (v++)->set(bounds.x() + points[0].x() * bounds.width(),
                           bounds.y() + points[0].y() * bounds.height());

                (v++)->set(bounds.x() + points[1].x() * bounds.width(),
                           bounds.y() + points[1].y() * bounds.height());

                (v++)->set(bounds.x() + points[2].x() * bounds.width(),
                           bounds.y() + points[2].y() * bounds.height());

                (v++)->set(bounds.x() + points[0].x() * bounds.width(),
                           bounds.y() + points[0].y() * bounds.height());

                (v++)->set(bounds.x() + points[3].x() * bounds.width(),
                           bounds.y() + points[3].y() * bounds.height());

                (v++)->set(bounds.x() + points[2].x() * bounds.width(),
                           bounds.y() + points[2].y() * bounds.height());

                points.clear();
            }
        });
    }

    markDirty(QSGNode::DirtyGeometry);
}
