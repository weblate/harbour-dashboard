/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024  Mirian Margiani
 */

import "../base"

MetadataBase {
    type: "day_times"
    name: qsTr("Day times")
    description: qsTr("Current times of sunrise and sunset.")
    icon: "image://theme/icon-l-timer"
    hasProvider: true
    requiresConfig: true
}
