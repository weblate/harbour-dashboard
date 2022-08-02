/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "private"
import "../base"

ForecastTileBase {
    id: root
    objectName: "ClockTile"

    size: "small"
    allowResize: false  // not yet implemented
    allowConfig: false  // not yet implemented

    AnalogClock {
        id: clock

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Theme.paddingLarge
        }
        height: width
        width: Math.min(parent.height, parent.width) - 2 * Theme.paddingLarge

        showLocalTime: true
        showNumbers: true
    }

    Label {
        width: parent.width
        wrapMode: Text.Wrap
        text: clock.wallClock.time.toLocaleString(Qt.locale(), app.timeFormat)
        font.pixelSize: Theme.fontSizeExtraLarge
        horizontalAlignment: Text.AlignHCenter

        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
    }
}
