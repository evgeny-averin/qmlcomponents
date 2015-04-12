TEMPLATE = app
# Define how to create version.h
prebuild.target = phony
prebuild.commands = /usr/bin/bash "$$PWD/prebuild.sh $(QTDIR) $$PWD"
prebuild.depends = FORCE

QMAKE_EXTRA_TARGETS += prebuild
PRE_TARGETDEPS += phony

QT += quick sensors widgets sql
CONFIG += ignore_no_exist

android {
    QT += androidextras
}

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

QMAKE_CXXFLAGS += -std=c++1y

CONFIG(debug, debug|release) {
    QMAKE_CXXFLAGS += -DDEVELOPER_BUILD
    RCC_DIR = resource-fake
} else {
    RCC_DIR = resource
}

INCLUDEPATH += ../../src \
               ../../src/box2d

SOURCES += src/main.cpp \

HEADERS += ../../src/application.h \
           ../../src/convenience.h \
           ../../src/fileio.h \
           ../../src/runnable.h

RESOURCES += $$RCC_DIR/main.qrc

OTHER_FILES += resource/main.qml \
               resource/texturedcube.js \
               ../../qmlcomponents/views/PersistentGraphView.qml \
               prebuild.sh

