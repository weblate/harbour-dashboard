/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import "private"

TileBase {
    id: root

    // must be provided by the container (main page)
    debug: false  // bind to global debug toggle
    bindEditingTarget: null  // item or QtObject containing bindEditingProperty
    bindEditingProperty: "editing"  // boolean property indicating edit mode
    dragProxyTarget: null  // Image{} outside of the tile container used for showing preview while dragging
    objectIndex: -1 // explicit binding to attached property <loader>.ObjectModel.index
    property ObjectModel tilesViewModel: null  // container holding tile instances
    property var settings: ({})  // implementation specific settings passed from/to the database

    property int tile_id: -1  // database identifier

    // must be redefined by the tile implementation
    objectName: "ForecastTileBase"

    // may have to be changed by the tile implementation
    size: "small"  // default size: small, medium, large
    allowResize: false // requires specific support by the tile implementation
    allowConfig: false // requires specific support by the tile implementation

    // should be fine like this for most use cases
    allowMove: true
    allowRemove: true
    cancelEditOnClick: false

    // the default context menu should not be changed by tile implementations
    menu: ContextMenu {
        MenuItem {
            visible: root.allowConfig
            text: qsTr("Configure")
            onClicked: root.requestConfig()
        }
        MenuItem {
            text: qsTr("Arrange tiles")
            onDelayedClick: bindEditingTarget.edit()
        }
        MenuItem {
            visible: root.allowRemove
            text: qsTr("Remove")
            onDelayedClick: root.requestRemoval()
        }
    }

    onRequestMove: {
        tilesViewModel.move(from, to)

        // TODO actually save the new sequence to the database
    }

    onRemoved: {
        tilesViewModel.remove(index)
        app.removeTile(tile_id)
    }

    onSizeChanged: {
        app.resizeTile(tile_id, size)
    }
}
