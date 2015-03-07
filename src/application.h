#pragma once

#include <QApplication>
#include <QtQuick>
#include <QFileSystemWatcher>
#include <QDesktopWidget>
#include <QResource>
#include <QQuickView>
#include <QQmlEngine>
#include <QQmlContext>
#include <QDebug>
#include <QEventLoop>
#include <QTimer>
#include <QOrientationSensor>
#include <QOrientationFilter>
#include <chrono>
#include "convenience.h"
#include "physics.h"

#ifdef Q_OS_ANDROID
#include <QtAndroid>
#include <QAndroidJniObject>
#include <QAndroidJniEnvironment>
#include "runnable.h"
#endif

class Application: public QObject
{
    Q_OBJECT

    Q_PROPERTY_DEF(qreal,   screenWidth,  screenWidth,  setScreenWidth,  600)
    Q_PROPERTY_DEF(qreal,   screenHeight, screenHeight, setScreenHeight, 800)
    Q_PROPERTY_DEF(qreal,   scaleX,       scaleX,       setScaleX,       1.)
    Q_PROPERTY_DEF(qreal,   scaleY,       scaleY,       setScaleY,       1.)
    Q_PROPERTY_DEF(qreal,   scale,        scale,        setScale,        1.)
    Q_PROPERTY_DEF(QString, path,         path,         setPath,         QGuiApplication::applicationFilePath())
    Q_PROPERTY_DEF(QString, dir,          dir,          setDir,          QGuiApplication::applicationDirPath() + QDir::separator())
    Q_PROPERTY_DEF(QString, speechResult, speechResult, setSpeechResult, "")
    Q_PROPERTY_DEF(QString, name,         name,         setName,         "")

    Q_PROPERTY(QString mediaPath READ mediaPath NOTIFY mediaPathChanged)

public:

    Application(const QString &name, QObject *parent = nullptr)
        : QObject(parent)
        , _name(name)
    {
#ifdef DEVELOPER_BUILD
        _watcher.addPath("/sdcard/Develop/flag/resource.lck");
        _watcher.addPath("/sdcard/Develop/flag/");

        connect(&_watcher, SIGNAL(fileChanged(const QString &)),      this, SLOT(reloadResources()));
        connect(&_watcher, SIGNAL(directoryChanged(const QString &)), this, SLOT(reloadResources()));

        if(!QResource::registerResource("/sdcard/Develop/main.rcc")) {
            qDebug() << "Failed to load main.rcc";
        }
#endif
        _view.setSurfaceType(QSurface::OpenGLSurface);

        QSurfaceFormat format;
        format.setAlphaBufferSize(8);
        format.setRenderableType(QSurfaceFormat::OpenGLES);

        _view.setFormat(format);
        _view.setColor(QColor(Qt::transparent));
        _view.setClearBeforeRendering(true);

        _view.engine()->rootContext()->setContextProperty("application", this);
        _view.engine()->rootContext()->setContextProperty("world", World::instance());
        _view.engine()->setOfflineStoragePath(mediaPath() + "dictionaries.db");
        _view.setResizeMode(QQuickView::SizeRootObjectToView);
        _view.setSource(QUrl(QStringLiteral("qrc:////main.qml")));
        _view.show();

        _speech_pull_timer.setInterval(500);

        connect(this, SIGNAL(screenWidthChanged (qreal)), this, SLOT(onScreenWidthChanged (qreal)));
        connect(this, SIGNAL(screenHeightChanged(qreal)), this, SLOT(onScreenHeightChanged(qreal)));


#ifdef Q_OS_ANDROID
        connect(&_speech_pull_timer,  SIGNAL(timeout()),  this, SLOT(pullRecognitionResult()));
#endif
    }

    int exec()
    {
        while(_view.isVisible()) {
            _event_loop.processEvents(QEventLoop::WaitForMoreEvents);
        }

        return 0;
    }

    Q_SLOT void reloadResources()
    {
        QResource::unregisterResource("/sdcard/Develop/main.rcc");
        QResource::registerResource("/sdcard/Develop/main.rcc");
        _view.engine()->clearComponentCache();
        _view.setSource(QUrl(QStringLiteral("qrc:////main.qml")));
        qDebug() << "Resources reloaded sucessfully";
    }

    Q_SLOT void onScreenWidthChanged(qreal width)
    {
        setScaleX(width / 600);
        setScale(_scaleX);
    }

    Q_SLOT void onScreenHeightChanged(qreal height)
    {
        setScaleY(height / 800);
        setScale(_scaleX);
    }

    Q_SLOT QString mediaPath()
    {
    #ifdef Q_OS_ANDROID
        QAndroidJniObject mediaDir = QAndroidJniObject::callStaticObjectMethod("android/os/Environment", "getExternalStorageDirectory", "()Ljava/io/File;");
        QAndroidJniObject mediaPath = mediaDir.callObjectMethod( "getAbsolutePath", "()Ljava/lang/String;" );
        QString dataAbsPath = mediaPath.toString() + "/" + _name + "/";

        QDir dir(dataAbsPath);

        if(!dir.exists()) {
            dir.cdUp();
            dir.mkdir("pretty-dictionary");
        }

        return dataAbsPath;
    #else
        return dir();
    #endif
    }

    Q_SLOT void clearComponentCache()
    {
        _view.engine()->clearComponentCache();
    }

    Q_SLOT void trimComponentCache()
    {
        _view.engine()->trimComponentCache();
    }

#ifdef Q_OS_ANDROID
    Q_SLOT void showAdvertizing()
    {
        QAndroidJniObject::callStaticMethod<void>("org/qtproject/example/admobqt/AdMobQtActivity", "showAd");
    }

    Q_SLOT void hideAdvertizing()
    {
        QAndroidJniObject::callStaticMethod<void>("org/qtproject/example/admobqt/AdMobQtActivity", "hideAd");
    }

    Q_SLOT void recognizeSpeech()
    {
        setSpeechResult("");

        QtAndroidRunner *runner = QtAndroidRunner::instance();
        runner->start(new SpeechInitializer());

        _speech_pull_timer.start(500);
    }

    Q_SLOT void pullRecognitionResult()
    {
        QtAndroidRunner *runner = QtAndroidRunner::instance();
        auto *speech_feedback = new SpeechFeedback();
        connect(speech_feedback, SIGNAL(resultPulled(QString)), this, SLOT(setSpeechResult(QString)));
        runner->start(speech_feedback);
    }
#endif

    Q_SLOT QString formatDate(const QDateTime &dt, const QString &fmt)
    {
        return dt.toString(fmt);
    }

    Q_SIGNAL void worldChanged();
    Q_SIGNAL void mediaPathChanged();

private:

    QEventLoop _event_loop;
    QQuickView _view;
    QFileSystemWatcher _watcher;
    QTimer _speech_pull_timer;
};
