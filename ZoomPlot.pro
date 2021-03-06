QT += qml quick charts

CONFIG += c++11

SOURCES += main.cpp \
    data1d.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    data1d.h

DISTFILES += qml/qtquickcontrols2.conf
