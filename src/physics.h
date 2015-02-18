#pragma once

#include <QQuickItem>
#include "Box2D.h"
#include "convenience.h"

class RigidBodyBase: public QQuickItem
{
public:

    RigidBodyBase(QQuickItem *parent = nullptr)
        : QQuickItem(parent)
    {}

    virtual const QPointF& position() const = 0;
};

class World: public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY_DEF(qreal, screenWidth,  screenWidth,  setScreenWidth,  600)
    Q_PROPERTY_DEF(qreal, screenHeight, screenHeight, setScreenHeight, 800)

    Q_PROPERTY_DEF(qreal,   screenMetric, screenMetric, setScreenMetric, 1.)
    Q_PROPERTY_DEF(QPointF, screenAnchor, screenAnchor, setScreenAnchor, QPointF(0, 0))

    Q_PROPERTY_DEF(bool,  simulating,   simulating,   setSimulating,   true)
    Q_PROPERTY_DEF(qreal, timeStep,     timeStep,     setTimeStep,     1./60.)
    Q_PROPERTY_DEF(qreal, gravityDistance,  gravityDistance,  setGravityDistance,  0)
    Q_PROPERTY_DEF(qreal, gravityThreshold, gravityThreshold, setGravityThreshold, 0)
    Q_PROPERTY_DEF(int,   simulatedItems,   simulatedItems,   setSimulatedItems,   0)

    Q_PROPERTY_DEF_PTR(RigidBodyBase, anchorObject, anchorObject, setAnchorObject, nullptr)

public:

    static World* instance()
    {
        return _instance;
    }

    World(QQuickItem *parent = nullptr)
        : QQuickItem(parent)
    {
        if(_instance)
            throw "Only one instance of World allowed";

        _instance = this;
    }

    ~World()
    {
        _instance = nullptr;
    }

    QRectF viewport() const
    {
        auto width  = _screenWidth  * _screenMetric;
        auto height = _screenHeight * _screenMetric;

        auto anchor = _screenAnchor;

        if(_anchorObject) {
            anchor = _anchorObject->position();
        }

        return QRectF(QPointF(anchor.x() - width / 2, anchor.y() + height / 2),
                      QPointF(anchor.x() + width / 2, anchor.y() - height / 2));
    }

    Q_SLOT void simulate()
    {
        static int32_t iteration = 0;

        if (_simulating) {
            auto *bi = _world.GetBodyList();
            int32_t count = 0;
            while (bi) {
                const b2Vec2 &pi = bi->GetWorldCenter();
                float  mi = bi->GetMass();

                auto *bk = bi->GetNext();
                while (bk) {
                    const b2Vec2 &pk = bk->GetWorldCenter();
                    b2Vec2 delta = pk - pi;
                    float  mk = bk->GetMass();
                    float  r  = delta.Length();

                    if (r < _gravityDistance) {
                        float force = std::min(r > 0. ? -(9.81 * mi * mk / (r * r)) : 0, _gravityThreshold);
                        delta.Normalize();
                        bi->ApplyForce( force * delta, pi, true);
                        bk->ApplyForce(-force * delta, pk, true);
                    }

                    bk = bk->GetNext();
                }

                bi = bi->GetNext();
                ++count;
            }

            setSimulatedItems(count);
            _world.Step(_timeStep, 1, 1);
            emit newIteration();

            iteration = (iteration + 1) % _world.GetBodyCount();
        }
    }

    b2Body* createBody(const b2BodyDef *body_def)
    {
        return _world.CreateBody(body_def);
    }

    b2RevoluteJoint* createJoint(b2RevoluteJointDef *joint_def)
    {
        return static_cast<b2RevoluteJoint*>(_world.CreateJoint(joint_def));
    }

    b2DistanceJoint* createJoint(b2DistanceJointDef *joint_def)
    {
        return static_cast<b2DistanceJoint*>(_world.CreateJoint(joint_def));
    }

    void destroyBody(b2Body *body)
    {
        _world.DestroyBody(body);
    }

    void destroyJoint(b2Joint *joint)
    {
        _world.DestroyJoint(joint);
    }

    Q_SLOT QPointF toScreen(const QPointF &p) const
    {
        auto vp = viewport();

        qreal u = (p.x() - vp.left())   / std::abs(vp.width());
        qreal v = 1.0 - (p.y() - vp.bottom()) / std::abs(vp.height());

        return {_screenWidth * u, _screenHeight * v};
    }

    Q_SLOT QPointF toWorld(const QPointF &p) const
    {
        auto vp = viewport();

        qreal u = p.x() / _screenWidth;
        qreal v = 1. - p.y() / _screenHeight;

        return {vp.left()   + std::abs(vp.width())  * u,
                vp.bottom() + std::abs(vp.height()) * v};
    }

    Q_SLOT QPointF sizeToScreen(const QPointF &size) const
    {
        auto vp = viewport();
        return {size.x() * _screenWidth  / std::abs(vp.width()),
                size.y() * _screenHeight / std::abs(vp.height())};
    }

    Q_SLOT QPointF sizeToWorld(const QPointF &size) const
    {
        auto vp = viewport();
        return {size.x() * std::abs(vp.width())  / _screenWidth,
                size.y() * std::abs(vp.height()) / _screenHeight};
    }

    Q_SIGNAL void newIteration();

private:

    static World* _instance;

    b2Vec2  _gravity{0.f, 0.f};
    b2World _world{_gravity};
};

class RigidBody: public RigidBodyBase
{
    Q_OBJECT

public:

    enum Shape
    {
        Box,
        Wheel
    };

    enum Type
    {
        Static    = b2_staticBody,
        Dynamic   = b2_dynamicBody,
        Kinematic = b2_kinematicBody
    };

    Q_PROPERTY_DEF(QPointF, position, position, setPosition, QPointF(0, 0))
    Q_PROPERTY_DEF(QPointF, size,     size,     setSize,     QPointF(1, 1))
    Q_PROPERTY_DEF(qreal,   angle,    angle,    setAngle,    0.)
    Q_PROPERTY_DEF(qreal,   radius,   radius,   setRadius,   1.)
    Q_PROPERTY_DEF(bool,    active,   active,   setActive,   true)
    Q_PROPERTY_DEF(Shape,   shape,    shape,    setShape,    Box)
    Q_PROPERTY_DEF(Type,    type,     type,     setType,     Dynamic)
    Q_PROPERTY_DEF(int,     group,    group,    setGroup,    0)
    Q_PROPERTY_DEF(bool,    sensor,   sensor,   setSensor,   false)
    Q_PROPERTY_DEF(qreal,   density,  density,  setDensity,  1000.)
    Q_PROPERTY_DEF(qreal,   linearDamping, linearDamping, setLinearDamping, 50.)
    Q_PROPERTY_DEF(bool,    initialized,   initialized,   setInitialized,   false)

    Q_PROPERTY_DEF_PTR(QQuickItem, target, target, setTarget, nullptr)

    Q_ENUMS(Shape)
    Q_ENUMS(Type)

public:

    RigidBody(QQuickItem *parent = nullptr)
        : RigidBodyBase(parent)
    {
        connect(World::instance(), SIGNAL(newIteration()), this, SLOT(simulate()));
        connect(this, SIGNAL(positionChanged(QPointF)),
                this, SLOT(onPositionChanged(QPointF)));

        connect(this, SIGNAL(angleChanged(qreal)),
                this, SLOT(onAngleChanged(qreal)));

        connect(this, SIGNAL(activeChanged(bool)),  this, SLOT(onActiveChanged(bool)));
        connect(this, SIGNAL(sizeChanged(QPointF)), this, SLOT(onSizeChanged(QPointF)));
    }

    ~RigidBody()
    {
        if(_body && World::instance())
            World::instance()->destroyBody(_body);
    }

    Q_SLOT void simulate()
    {
        if(_body) {
            auto pos   = _body->GetPosition();
            auto angle = _body->GetAngle();

            if(_shape == Wheel) {
                _size = {_radius * 2, _radius * 2};
            }

            if(_type == Dynamic && (_body->GetType() == b2_staticBody)) {
                _body->SetType(b2_dynamicBody);
            } else if(_type != Dynamic && (_body->GetType() == b2_dynamicBody)) {
                _body->SetType(b2_staticBody);
            }

            updateTargetPosition(pos);
            updateTargetAngle(angle);
            updateTargetSize();

            if (!_initialized) {
                setInitialized(true);
            }
        }
    }

    Q_SLOT void onPositionChanged(QPointF pos)
    {
        if(_body)
            _body->SetTransform({static_cast<float>(pos.x()), static_cast<float>(pos.y())}, -to_rad(_angle));
    }

    Q_SLOT void onAngleChanged(qreal)
    {
        if(_body)
            _body->SetTransform({static_cast<float>(_position.x()), static_cast<float>(_position.y())}, -to_rad(_angle));
    }

    Q_SLOT void onActiveChanged(bool active)
    {
        if(_body)
            _body->SetActive(active);
    }

    Q_SLOT void onSizeChanged(QPointF)
    {
        updateFixture();
        simulate();
    }

    void updateTargetPosition(const b2Vec2 &pos)
    {
        if(pos.x != _position.x() || pos.y != _position.y()) {
            setPosition({pos.x, pos.y});
        }

        auto pos_final = _position;
        auto size_scr  = World::instance()->sizeToScreen(_size);
        auto pos_scr   = World::instance()->toScreen(pos_final);

        pos_scr.setX(pos_scr.x() - size_scr.x() / 2);
        pos_scr.setY(pos_scr.y() - size_scr.y() / 2);

        if (_target) {
            _target->setX(pos_scr.x());
            _target->setY(pos_scr.y());
        }

        setX(pos_scr.x());
        setY(pos_scr.y());
    }

    void updateTargetAngle(const double angle)
    {
        auto angle_deg = -to_deg(angle);
        if(_angle != angle_deg) {
            setAngle(angle_deg);
            _target->setRotation(_angle);
        }
    }

    void updateTargetSize()
    {
        auto size_scr = World::instance()->sizeToScreen(_size);
        if(_target->width() != size_scr.x() || _target->height() != size_scr.y()) {
            _target->setWidth (size_scr.x());
            _target->setHeight(size_scr.y());
        }
    }

    b2Body* body()
    {
        return _body;
    }

protected:

    virtual void componentComplete() override
    {
        QQuickItem::componentComplete();

        b2FixtureDef   fixture_def;
        b2BodyDef      body_def;

        body_def.type = static_cast<b2BodyType>(_type);
        body_def.position.x = static_cast<float>(_position.x());
        body_def.position.y = static_cast<float>(_position.y());
        body_def.angle = -to_rad(_angle);
        body_def.active = _active;
        body_def.linearDamping = _linearDamping;
        body_def.angularDamping = 5.;

        _body = World::instance()->createBody(&body_def);

        fixture_def.shape = createShape();
        fixture_def.density = _density;
        fixture_def.friction = 1.0f;
        fixture_def.isSensor = _sensor;
        fixture_def.filter.groupIndex = _group;

        _fixture = _body->CreateFixture(&fixture_def);

        delete fixture_def.shape;
    }

    b2Shape* createShape()
    {
        switch(_shape) {
            case Box: {
                auto new_shape = new b2PolygonShape;
                new_shape->SetAsBox(_size.x() / 2, _size.y() / 2);
                return new_shape;
            }
            case Wheel: {
                auto new_shape = new b2CircleShape;
                new_shape->m_radius = _radius;
                return new_shape;
            }
        }

        return nullptr;
    }

    void updateFixture()
    {
        if(!_fixture)
            return;

        switch(_shape) {
            case Box: {
                auto *shape = static_cast<b2PolygonShape*>(_fixture->GetShape());
                shape->SetAsBox(_size.x() / 2, _size.y() / 2);
                break;
            }
            case Wheel: {
                auto *shape = static_cast<b2CircleShape*>(_fixture->GetShape());
                shape->m_radius = _radius;
                break;
            }
        }

        _body->ResetMassData();;
    }

private:

    b2Body *_body = nullptr;
    b2Fixture* _fixture = nullptr;
};


class RevoluteJoint: public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY_DEF_PTR(RigidBody, bodyA, bodyA, setBodyA, nullptr)
    Q_PROPERTY_DEF_PTR(RigidBody, bodyB, bodyB, setBodyB, nullptr)

    Q_PROPERTY_DEF(QPointF, anchorA, anchorA, setAnchorA, QPointF(0, 0))
    Q_PROPERTY_DEF(QPointF, anchorB, anchorB, setAnchorB, QPointF(0, 0))
    Q_PROPERTY_DEF(qreal,   motorTorque,  motorTorque,  setMotorTorque,  0.)
    Q_PROPERTY_DEF(qreal,   motorSpeed,   motorSpeed,   setMotorSpeed,   0.)
    Q_PROPERTY_DEF(bool,    motorEnabled, motorEnabled, setMotorEnabled, false)

protected:

    RevoluteJoint()
    {
        connect(this, SIGNAL(motorSpeedChanged(qreal)),
                this, SLOT(onMotorSpeedChanged(qreal)));
    }

    virtual void componentComplete() override
    {
        if(_bodyA && _bodyB) {
            b2RevoluteJointDef jointDef;
            jointDef.bodyA = _bodyA->body();
            jointDef.bodyB = _bodyB->body();
            jointDef.localAnchorA = to_vec2(_anchorA);
            jointDef.localAnchorB = to_vec2(_anchorB);
            jointDef.motorSpeed = _motorSpeed;
            jointDef.maxMotorTorque = _motorTorque;
            jointDef.enableMotor = _motorEnabled;
            jointDef.collideConnected = false;

            _joint = World::instance()->createJoint(&jointDef);
        }
    }

    Q_SLOT void onMotorSpeedChanged(qreal speed)
    {
        if(_joint)
            _joint->SetMotorSpeed(speed);
    }

    b2RevoluteJoint *_joint = nullptr;
};

class DistanceJoint: public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY_DEF_PTR(RigidBody, bodyA, bodyA, setBodyA, nullptr)
    Q_PROPERTY_DEF_PTR(RigidBody, bodyB, bodyB, setBodyB, nullptr)

    Q_PROPERTY_DEF(QPointF, anchorA, anchorA, setAnchorA, QPointF(0, 0))
    Q_PROPERTY_DEF(QPointF, anchorB, anchorB, setAnchorB, QPointF(0, 0))
    Q_PROPERTY_DEF(qreal,   length,  length,  setLength,  10.)
    Q_PROPERTY_DEF(qreal,   damping, damping, setDamping, 100.)

    Q_PROPERTY_DEF_PTR(QQuickItem, target, target, setTarget, nullptr)

protected:

    DistanceJoint()
    {
        connect(this, SIGNAL(lengthChanged(qreal)), this, SLOT(onLengthChanged(qreal)));
        connect(this, SIGNAL(bodyAChanged(const RigidBody*)),  this, SLOT(componentComplete()));
        connect(this, SIGNAL(bodyBChanged(const RigidBody*)),  this, SLOT(componentComplete()));
    }

    ~DistanceJoint()
    {}

    Q_SLOT virtual void componentComplete() override
    {
        if (_joint) {
            World::instance()->destroyJoint(_joint);
        }

        if(_bodyA && _bodyB) {
            b2DistanceJointDef jointDef;
            jointDef.bodyA = _bodyA->body();
            jointDef.bodyB = _bodyB->body();
            jointDef.localAnchorA = to_vec2(_anchorA);
            jointDef.localAnchorB = to_vec2(_anchorB);
            jointDef.collideConnected = false;
            jointDef.frequencyHz = 4.0f;
            jointDef.dampingRatio = _damping;
            jointDef.length = _length;

            connect(_bodyA, SIGNAL(positionChanged(QPointF)), this, SLOT(updatePosition(QPointF)));

            updatePosition(_bodyA->position());

            _joint = World::instance()->createJoint(&jointDef);
        }
    }

    Q_SLOT void updatePosition(const QPointF &position)
    {
        if(_target) {
            auto angle_rad = to_rad(_bodyA->angle());
            QPointF anchor = {position.x() + _anchorA.x() * cos(angle_rad), position.y() - _anchorA.x() * sin(angle_rad)};
            anchor = World::instance()->toScreen(anchor);
            _target->setX(anchor.x() - _target->width() / 2);
            _target->setY(anchor.y() - _target->height() / 2);
        }
    }

    Q_SLOT void onLengthChanged(qreal length)
    {
        if(_joint) {
            _joint->SetLength(length);
        }
    }

    b2DistanceJoint *_joint = nullptr;
};

