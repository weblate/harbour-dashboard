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

    settingsDialog: Qt.resolvedUrl("Settings.qml")
    detailsPage: Qt.resolvedUrl("Details.qml")

    size: "small"
    allowResize: true  // not yet implemented
    allowConfig: true

    AnalogClock {
        id: clock

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Theme.paddingLarge
        }
        height: parent.height - Theme.paddingLarge - Theme.paddingLarge - label.height
        width: height

        timeFormat: defaultFor(settings['time_format'], 'local')
        timezone: defaultFor(settings['timezone'], '')
        utcOffsetSeconds: defaultFor(settings['utc_offset_seconds'], 0)
        clockFace: defaultFor(settings['clock_face'], 'plain')
    }

    Label {
        id: label
        width: parent.width
        wrapMode: Text.Wrap
        text: !!settings['label'] ? settings.label : clock.convertedTime.toLocaleString(Qt.locale(), app.timeFormat)
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
        text: visible ? clock.convertedTime.toLocaleString(Qt.locale(), app.timeFormat) : ''
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor

        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingSmall
        }
    }
}
