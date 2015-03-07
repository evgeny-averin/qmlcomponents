TEMPLATE = app
prebuild.target = phony
prebuild.commands = /usr/bin/bash "$$PWD/prebuild.sh $(QTDIR) $$PWD"
prebuild.depends = FORCE

QMAKE_EXTRA_TARGETS += prebuild
PRE_TARGETDEPS += phony

QT += widgets quick sensors
CONFIG += ignore_no_exist

QMAKE_CXXFLAGS += -std=c++1y -DDEVELOPER_BUILD

INCLUDEPATH += \
    ../../src \
    ../../src/box2d/

SOURCES += src/main.cpp \

HEADERS += ../../src/application.h \
           ../../src/convenience.h \
           ../../src/fileio.h \

OTHER_FILES += resource/main.qml \
               ../../views/PersistentListView.qml \
               ../../views/PersistentListViewItem.qml \
               prebuild.sh \


