/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024  Mirian Margiani
 */

import "../base"

MetadataBase {
    type: "clock"
    name: qsTr("World clock")
    description: qsTr("Clock showing local time or the current time in any time zone.")
    icon: "image://theme/icon-l-clock"
    requiresConfig: true
}
