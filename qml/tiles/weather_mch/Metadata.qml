/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024  Mirian Margiani
 */

import "../base"

MetadataBase {
    type: "weather_mch"
    name: qsTr("Weather forecast (MeteoSwiss)")
    description: qsTr("Weather forecast for Switzerland provided by the Swiss Meteorological Institute.")
    icon: "image://theme/icon-l-weather-d400"
    hasProvider: true
    requiresConfig: true
}
