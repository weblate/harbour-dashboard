/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

IconButton {
    id: root

    width: Theme.itemSizeExtraSmall
    height: width

    icon.width: width * 0.8
    icon.height: height * 0.8

    Behavior on opacity { FadeAnimation { } }
    Behavior on scale { SmoothedAnimation { velocity: 10 } }

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: Theme.rgba(parent.highlighted ? palette.highlightColor : palette.primaryColor, Theme.opacityFaint)
    }
}
