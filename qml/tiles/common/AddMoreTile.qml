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
        // TODO
        // - select which tile type to add
        // - configure the new tile
        // - save the new tile with custom settings
        // x ->>> important: get the new tile_id back from the database
        // x add the tile to the view

        // DEBUG
        var type = 'clock'
        var size = 'small'
        var settings = {
            'time_format': 'local',
            'utc_offset_minutes': 0,
            'timezone': '',
            'label': '',
            'clock_face': 'arabic'
        }

        // Save the tile and wait for confirmation.
        // The tile will be added to the view in the handler for app.tileAdded(...).
        app.addTile(type, size, settings)
    }
}
