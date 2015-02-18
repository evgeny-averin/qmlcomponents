#pragma once

#include <QRunnable>
#include <QAndroidJniEnvironment>
#include <QAndroidJniObject>
#include <QCoreApplication>
#include <QtAndroid>
#include <QDebug>
#include <QThread>
#include <time.h>

class SpeechInitializer : public QRunnable
{
public:

    void run()
    {
        QAndroidJniObject activity = QtAndroid::androidActivity();
        activity.callMethod<void>("recognizeSpeech");
    }
};

class SpeechFeedback : public QObject, public QRunnable
{
    Q_OBJECT

    void run()
    {
        QAndroidJniObject activity = QtAndroid::androidActivity();
        QAndroidJniObject result = activity.callObjectMethod<jstring>("getRecognitionResult");
        QString str = result.toString();

        emit resultPulled(str);
    }

    Q_SIGNAL void resultPulled(QString result);
};

#include <QObject>
#include <QMutex>
#include <QRunnable>
#include <QQueue>
#include <QDebug>

class QtAndroidRunnerPriv;

class QtAndroidRunner : public QObject
{
    Q_OBJECT

public:

    static QtAndroidRunner *m_instance;

    ~QtAndroidRunner();

    static void init()
    {
        QtAndroidRunner::instance();
    }

    static QtAndroidRunner* instance()
    {
        if(m_instance == 0) {
            QCoreApplication* app = QCoreApplication::instance();
            m_instance = new QtAndroidRunner(app);
        }

        return m_instance;
    }

public slots:

    void start(QRunnable * runnable);

private:

    explicit QtAndroidRunner(QObject *parent = 0);

    QtAndroidRunnerPriv* d;
    friend class QtAndroidRunnerPriv;
};

class QtAndroidRunnerPriv {
public:
    QMutex mutex;
    QQueue<QRunnable*> queue;
    jclass clazz;
    jmethodID tick;

    QtAndroidRunnerPriv() {
        QAndroidJniEnvironment env;

        qDebug() << "QtAndroidRunnerPriv";

        clazz = env->FindClass("org/qtproject/eaverin/pretty/dictionary/AdMobQtActivity");

        /* QAndroidJniObject only works for
         * core library and cached classes like
         * QtActivity / QtApplication.
         *
         * Therefore, it need to use the raw API
         * and must be executed within the JNI_onLoad()
         * call.
         *
         */

        if (!clazz)
        {
            qCritical() << "Can't find class : " << "org/qtproject/eaverin/pretty/dictionary/AdMobQtActivity" << ". Did init() be called within JNI_onLoad?";
        } else {

            tick = env->GetStaticMethodID(clazz,"post","()V");
            if (tick ==0) {
                qCritical() << "Failed to obtain the method : tick";
            }

            JNINativeMethod methods[] =
            {
                {"invoke", "()V", (void *)&QtAndroidRunnerPriv::invoke},
            };

            qDebug() << "Register the native methods.";

            // Register the native methods.
            int numMethods = sizeof(methods) / sizeof(methods[0]);
            if (env->RegisterNatives(clazz, methods, numMethods) < 0) {
                if (env->ExceptionOccurred()) {
                    env->ExceptionDescribe();
                    env->ExceptionClear();
                    qCritical() << "Exception in native method registration";
                }
            }

        }
    }


    static void invoke()
    {
        QRunnable *runnable = 0;

        QtAndroidRunner::m_instance->d->mutex.lock();
        if (QtAndroidRunner::m_instance->d->queue.size() > 0 ) {
            runnable = QtAndroidRunner::m_instance->d->queue.dequeue();
        }
        QtAndroidRunner::m_instance->d->mutex.unlock();

        if (runnable) {
            runnable->run();
            if (runnable->autoDelete()) {
                delete runnable;
            }
        }

    }
};

inline QtAndroidRunner::QtAndroidRunner(QObject *parent)
    : QObject(parent)
{
    d = new QtAndroidRunnerPriv;
}

inline QtAndroidRunner::~QtAndroidRunner()
{
    delete d;
}

inline void QtAndroidRunner::start(QRunnable * runnable)
{
    d->mutex.lock();
    d->queue.append(runnable);
    d->mutex.unlock();

    QAndroidJniEnvironment env;
    env->CallStaticVoidMethod(d->clazz,d->tick);
}
