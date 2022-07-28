# This file is part of Forecasts for SailfishOS.
# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2019-2022 Mirian Margiani

# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-forecasts

CONFIG += sailfishapp

SOURCES += src/harbour-forecasts.cpp

DISTFILES += \
    qml/qchart/LICENSE.md \
    qml/qchart/QChart.js \
    qml/qchart/QChart.qml \
    qml/js/*.js \
    qml/harbour-forecasts.qml \
    qml/cover/CoverPage.qml \
    qml/cover/cover.png \
    qml/pages/ForecastPage.qml \
    qml/pages/OverviewPage.qml \
    qml/pages/TablePage.qml \
    qml/pages/components/*.qml \
    rpm/harbour-forecasts.changes.in \
    rpm/harbour-forecasts.changes.run.in \
    rpm/harbour-forecasts.spec \
    rpm/harbour-forecasts.yaml \
    translations/*.ts \
    weather-icons/*.svg \
    harbour-forecasts.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

TRANSLATIONS += \
    translations/harbour-forecasts-en.ts \
    translations/harbour-forecasts-de.ts \
    translations/harbour-forecasts-fr.ts \
    translations/harbour-forecasts-it.ts \
    translations/harbour-forecasts-zh_CN.ts

lupdate_only {
SOURCES += \
    qml/*.qml \
    qml/cover/*.qml \
    qml/pages/*.qml \
    qml/pages/components/*.qml \
    qml/js/*.js
}

QML_IMPORT_PATH += qml/modules

# Note: version number is configured in yaml
DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)
