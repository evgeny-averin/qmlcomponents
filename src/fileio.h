#pragma once

#include <QFile>
#include <QDebug>
#include <QDir>
#include "convenience.h"

class File: public QFile
{
    Q_OBJECT

    Q_PROPERTY_DEF(QString, dir, dir, setDir, "")

public:

    File()
    {}

    Q_SLOT bool write(const QString &file_name, const QString &text)
    {
        setFileName(_dir + file_name);

        if(QFile::open(QFile::WriteOnly)) {
            auto size_written = QFile::write(text.toLocal8Bit());
            QFile::close();
            return size_written == text.length();
        } else {
            qDebug() << "Error opening file" << _dir + file_name << errorString();
            return false;
        }
    }

    Q_SLOT QString readAll(const QString &file_name)
    {
        setFileName(_dir + file_name);

        if(QFile::open(QFile::ReadOnly)) {
            auto bytes = QFile::readAll();
            QFile::close();
            return QString::fromLocal8Bit(bytes);
        } else {
            qDebug() << "Error opening file" << _dir + file_name << errorString();
        }

        return "";
    }

    Q_SLOT void rm(const QString &file_name)
    {
        QDir dir(_dir);
        if(!dir.remove(_dir + file_name)) {
            qDebug() << "Failed to remove file" << _dir + file_name;
        }
    }

    Q_SLOT bool exists(const QString &file_name)
    {
        return QFile(_dir + file_name).exists();
    }
};
