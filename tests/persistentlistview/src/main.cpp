#include <QGuiApplication>
#include <QtQuick>
#include "application.h"
#include "fileio.h"

World* World::_instance = nullptr;

int main(int argc, char *argv[])
{
    QML_REGISTER_TYPE(FileIO, File);

    QGuiApplication qapp(argc, argv);
    Application app("shopping-companion");

    return app.exec();
}
