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
    qml/harbour-forecasts.qml \
    qml/pages/MainPage.qml \
    qml/pages/FatalErrorPage.qml \
    qml/pages/MaintenancePage.qml \
    qml/pages/LandingPage.qml \
    qml/pages/AboutPage.qml \
    qml/pages/NewTileDialog.qml \
    qml/components/DescriptionLabel.qml \
    qml/components/BlockingInfoPageBase.qml \
    \
    qml/tiles/base/ForecastTileBase.qml \
    qml/tiles/base/DetailsPageBase.qml \
    qml/tiles/base/SettingsDialogBase.qml \
    qml/tiles/base/private/TileBase.qml \
    qml/tiles/base/private/TileActionButton.qml \
    qml/tiles/common/AddMoreTile.qml \
    qml/tiles/common/BrokenTile.qml \
    qml/tiles/common/private/icon-l-warning.png \
    qml/tiles/spacer/Tile.qml \
    qml/tiles/clock/Tile.qml \
    qml/tiles/clock/Details.qml \
    qml/tiles/clock/Settings.qml \
    qml/tiles/clock/private/AnalogClock.qml \
    qml/tiles/clock/private/clock-face-num-arabic.png \
    qml/tiles/clock/private/clock-face-num-roman.png \
    qml/tiles/clock/private/clock-face-plain.png \
    \
    qml/py/meteo.py \
    qml/py/meteopy/util.py \
    qml/py/meteopy/providers/provider_base.py \
    qml/py/meteopy/providers/meteoswiss.py \
    qml/py/meteopy/providers/yrno.py \
    \
    images/harbour-forecasts.png \
    \
    harbour-forecasts.desktop \
    rpm/harbour-forecasts.changes.in \
    rpm/harbour-forecasts.changes.run.in \
    rpm/harbour-forecasts.spec \
    rpm/harbour-forecasts.yaml \
    translations/*.ts \
    \
    qml/qchart/LICENSE.md \
    qml/qchart/QChart.js \
    qml/qchart/QChart.qml \
    \
    qml/js/*.js \
    \
    qml/cover/CoverPage.qml \
    qml/cover/cover.png \
    qml/pages/ForecastPage.qml \
    qml/pages/OverviewPage.qml \
    qml/pages/TablePage.qml \
    qml/pages/components/*.qml \
    weather-icons/*.svg \


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
    qml/tiles/*.qml \
    qml/tiles/base/*.qml \
    qml/tiles/base/private/*.qml \
    qml/tiles/clock/*.qml \
    qml/tiles/clock/private/*.qml \
    qml/tiles/weather/*.qml \
    qml/tiles/weather/mch/*.qml \
    qml/tiles/weather/mch/private/*.qml \
    qml/pages/components/*.qml \
    qml/js/*.js
}

QML_IMPORT_PATH += qml/modules

# Note: version number is configured in yaml
DEFINES += APP_VERSION=\\\"$$VERSION\\\"
DEFINES += APP_RELEASE=\\\"$$RELEASE\\\"
include(libs/opal-cached-defines.pri)
