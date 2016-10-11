#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include "data1d.h"
int main(int argc, char *argv[])
{
    qmlRegisterType<Data1D>("Data1D", 1, 0, "Data1D");

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;
    engine.load(QUrl(QLatin1String("qrc:/main.qml")));

    return app.exec();
}
