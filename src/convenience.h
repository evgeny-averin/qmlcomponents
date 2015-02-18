#pragma once

#include <QPoint>
#include "Box2D.h"

#define Q_PROPERTY_DEF(Type, name, getter, setter, initializer) \
private:\
    Q_PROPERTY(Type name READ getter WRITE setter NOTIFY name##Changed) \
public:\
    const Type& getter() const\
    {\
        return _##name;\
    }\
    Q_SLOT void setter(const Type &val)\
    {\
        _##name = val;\
        emit name##Changed(_##name);\
    }\
    Q_SIGNAL void name##Changed(const Type &val);\
private:\
    Type _##name = initializer;\

#define Q_PROPERTY_DEF_PTR(Type, name, getter, setter, initializer) \
private:\
    Q_PROPERTY(Type* name READ getter WRITE setter NOTIFY name##Changed) \
public:\
    Type* getter() const\
    {\
        return _##name;\
    }\
    Q_SLOT void setter(Type *val)\
    {\
        _##name = val;\
        emit name##Changed(_##name);\
    }\
    Q_SIGNAL void name##Changed(const Type *val);\
private:\
    Type *_##name = initializer;\

#define QML_REGISTER_TYPE(Module, Type) qmlRegisterType<Type>(#Module, 1, 0, #Type)

template <class T>
T to_rad(T val)
{
    return val / 180. * 3.1415;
}

template <class T>
T to_deg(T val)
{
    return val / 3.1415 * 180.;
}

template <class T>
float float_cast(T a)
{
    return static_cast<float>(a);
}

inline b2Vec2 to_vec2(const QPointF &p)
{
    return {float_cast(p.x()), float_cast(p.y())};
}
