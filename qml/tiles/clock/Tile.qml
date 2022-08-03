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

    // TODO improve the layout...
    // TODO define different layouts for different sizes
    // TODO show converted time in labels

    size: "small"
    allowResize: true  // not yet implemented
    allowConfig: false  // not yet implemented

    AnalogClock {
        id: clock

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Theme.paddingLarge
        }
        height: parent.height - Theme.paddingLarge - Theme.paddingLarge - label.height
        width: height

        timeFormat: settings['time_format']
        timezone: settings['timezone']
        utcOffsetMinutes: settings['utc_offset_minutes']
        clockFace: settings['clock_face']
    }

    Label {
        id: label
        width: parent.width
        wrapMode: Text.Wrap
        // TODO show converted time
        text: !!settings['label'] ? settings.label : clock.wallClock.time.toLocaleString(Qt.locale(), app.timeFormat)
        font.pixelSize: Theme.fontSizeExtraLarge
        horizontalAlignment: Text.AlignHCenter

        anchors {
            bottom: subLabel.top
            bottomMargin: subLabel.visible ? -Theme.paddingMedium : -subLabel.height+Theme.paddingMedium
        }
    }

    Label {
        id: subLabel
        visible: !!settings['label'] && settings['label'] !== ''
        width: parent.width
        wrapMode: Text.Wrap
        // TODO show converted time
        text: visible ? clock.wallClock.time.toLocaleString(Qt.locale(), app.timeFormat) : ''
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor

        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingSmall
        }
    }
}
