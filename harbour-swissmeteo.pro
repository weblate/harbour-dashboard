# This file is part of Swiss Meteo.
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
TARGET = harbour-swissmeteo

CONFIG += sailfishapp_qml

DISTFILES += \
    qml/qchart/LICENSE.md \
    qml/qchart/QChart.js \
    qml/qchart/QChart.qml \
    qml/js/*.js \
    qml/harbour-swissmeteo.qml \
    qml/cover/CoverPage.qml \
    qml/cover/cover.png \
    qml/pages/ForecastPage.qml \
    qml/pages/OverviewPage.qml \
    qml/pages/TablePage.qml \
    qml/pages/components/*.qml \
    rpm/harbour-swissmeteo.changes.in \
    rpm/harbour-swissmeteo.changes.run.in \
    rpm/harbour-swissmeteo.spec \
    rpm/harbour-swissmeteo.yaml \
    translations/*.ts \
    weather-icons/*.svg \
    harbour-swissmeteo.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

TRANSLATIONS += \
    translations/harbour-swissmeteo-en.ts \
    translations/harbour-swissmeteo-de.ts \
    translations/harbour-swissmeteo-fr.ts \
    translations/harbour-swissmeteo-it.ts \
    translations/harbour-swissmeteo-zh_CN.ts

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
