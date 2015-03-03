TEMPLATE = app

QT += quick sensors widgets sql
CONFIG += ignore_no_exist warn_on qmltestcase

android {
    QT += androidextras
}

QMAKE_CXXFLAGS += -std=c++1y

INCLUDEPATH += ../../src \
               ../../src/box2d

SOURCES += src/main.cpp \

HEADERS += ../../src/application.h \
           ../../src/convenience.h \
           ../../src/fileio.h

RESOURCES += ./resource/main.qrc

OTHER_FILES +=  ./resource/tst_main.qml \
                ./resource/tst_sqltablemodel.qml \
                ../../../qmlcomponents/storage/SqlTableModel.qml \
                ../../../qmlcomponents/storage/Storage.qml \
