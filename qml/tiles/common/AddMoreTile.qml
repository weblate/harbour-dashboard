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
    objectName: "AddMoreTile"

    size: "small"
    allowResize: false
    allowRemove: false
    allowMove: false
    allowConfig: false

    editOnPressAndHold: false
    cancelEditOnClick: false
    enabledWhileEditing: true

    HighlightImage {
        anchors.centerIn: parent
        source: "image://theme/icon-l-add"
    }

    onClicked: {
        // TODO show tile selection page

        // tilesModel.addDebugTile(String(tilesModel.count), 'small')
        // flickable.scrollToBottom()

        // app.addTile('clock', {
        //     'utcOffsetMinutes': 0,
        //     'showLocalTime': 1,
        //     'label': '',
        //     'showNumbers': 1
        // })
    }
}
