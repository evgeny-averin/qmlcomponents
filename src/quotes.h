#ifndef QUOTES_H
#define QUOTES_H

#include <QObject>

class Quotes: public QObject
{
    Q_OBJECT

public:
    Quotes(QObject *parent = nullptr)
        : QObject(parent)
    {}

    enum Period
    {
        UnknownPeriod,
        Realtime,
        Day,
        Week,
        Month,
        Year,
        Full
    };

    Q_ENUMS(Period)
};

#endif // QUOTES_H

