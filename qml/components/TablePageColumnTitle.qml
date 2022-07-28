/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Column {
    property alias text: titleLabel.text
    property string unit: ''

    Label {
        id: titleLabel
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
        truncationMode: TruncationMode.Fade
    }

    Label {
        text: (unit == '') ? ' ' : String("(%1)").arg(unit)
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeSmall
    }
}
