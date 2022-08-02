/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../base"

ForecastTileBase {
    id: root
    objectName: "BrokenTile"

    size: "small"
    allowResize: true
    allowRemove: true
    allowMove: true
    allowConfig: false

    editOnPressAndHold: false
    cancelEditOnClick: false

    HighlightImage {
        id: icon
        anchors {
            top: parent.top
            topMargin: Math.min(parent.width, parent.height) / 3 * 0.5
        }

        width: Math.min(parent.width, parent.height) / 3
        height: width
        anchors.horizontalCenter: parent.horizontalCenter
        source: "private/icon-l-warning.png"
    }

    Label {
        anchors {
            top: icon.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }

        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
        width: parent.width - 2*Theme.paddingMedium
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: qsTr("Invalid tile: %1 (%2)").arg(settings['tile_type']).arg(settings['tile_id'])
    }
}
