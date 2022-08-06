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

    // -------------------------------------------------------------------------
    // MUST BE CONFIGURED BY TILE IMPLEMENTATIONS

    objectName: "ForecastTileBase"                          // object name identifying the class of this tile, e.g. "weather:<provider>"
    allowConfig: false                // requires specific support by the tile implementation: Settings.qml
    property bool allowDetails: false // requires specific support by the tile implementation: Details.qml
    allowRefresh: false               // requires specific support by the tile implementation
    allowResize: false                // requires specific support by the tile implementation

    // -------------------------------------------------------------------------
    // MAY HAVE TO BE CHANGED BY TILE IMPLEMENTATIONS

    size: "small"                     // default tile size: small, medium, large
    property string detailsPage: allowDetails   // effective url to the details page, if supported
                                 ? Qt.resolvedUrl("Details.qml") : ""
    property string settingsDialog: allowConfig             // effective url to the settings page, if supported
                                    ? Qt.resolvedUrl("Settings.qml") : ""

    // -------------------------------------------------------------------------
    // HELPER FUNCTIONS

    function defaultFor(what, fallback) {
        return (what === '' || typeof what === 'undefined' || what === null) ? fallback : what
    }

    function defaultOrNullFor(what, fallback) {
        return (what === '' || typeof what === 'undefined') ? fallback : what
    }

    // -------------------------------------------------------------------------
    // MUST BE CONFIGURED BY THE TILE CONTAINER (MAIN PAGE)
    // Implementations should not touch these settings.

    debug: false                                // bind to global debug toggle
    bindEditingTarget: null                     // item or QtObject containing bindEditingProperty
    bindEditingProperty: "editing"              // boolean property indicating edit mode
    dragProxyTarget: null                       // Image{} outside of the tile container used for showing preview while dragging
    objectIndex: -1                             // explicit binding to attached property <loader>.ObjectModel.index
    property ObjectModel tilesViewModel: null   // container holding tile instances

    property int tile_id: -1                    // database identifier
    property var settings: ({})                 // implementation specific settings passed from/to the database

    // -------------------------------------------------------------------------
    // SHOULD NOT HAVE TO BE CHANGED BY TILE IMPLEMENTATIONS

    allowMove: true
    allowRemove: true
    cancelEditOnClick: false
    property bool showDetailsOnClick: detailsPage != ""

    // -------------------------------------------------------------------------
    // INTERNAL IMPLEMENTATION

    property int _registeredUpdateSignalForTileId: -1

    // the default context menu should not be changed by tile implementations
    menu: ContextMenu {
        MenuItem {
            visible: root.allowRefresh
            text: qsTr("Refresh")
            onClicked: root.requestRefresh()
        }

        MenuItem {
            visible: root.allowConfig
            text: qsTr("Configure")
            onClicked: root.requestConfig()
        }
        MenuItem {
            text: qsTr("Manage tiles")
            onDelayedClick: bindEditingTarget.edit()
        }
    }

    onClicked: {
        if ((!editing || enabledWhileEditing) && showDetailsOnClick && detailsPage != "") {
            pageStack.push(detailsPage, {
                'tile': root,
                'settings': Qt.binding(function(){ return settings }),
                'debug': Qt.binding(function(){ return debug }),
                'tile_id': Qt.binding(function(){ return tile_id })
            })
        }
    }

    onRequestConfig: {
        if (settingsDialog !== "" && allowConfig) {
            var dialog = pageStack.push(settingsDialog, {
                'settings': Qt.binding(function(){ return settings }),
                'debug': Qt.binding(function(){ return debug }),
                'tile_id': Qt.binding(function(){ return tile_id })
            })
            dialog.accepted.connect(function() {
                app.updateTile(tile_id, dialog.updatedSettings)
            })
        }
    }

    onTile_idChanged: {
        if (tile_id < 0 || tile_id == _registeredUpdateSignalForTileId) return
        console.log("got a new tile_id", tile_id)
        _registeredUpdateSignalForTileId = tile_id

        app.registerBackendSignal(tile_id, "info.main.update-tile.finished", function(args) {
            root.settings = args[2]  // 0=signal, 1=tile_id, 2+=args
        })
    }

    onRequestMove: {
        tilesViewModel.move(from, to)
        app.moveTile(tile_id, from, to)
    }

    onRemoved: {
        tilesViewModel.remove(index)
        app.removeTile(tile_id)
    }

    onSizeChanged: {
        app.resizeTile(tile_id, size)
    }

    Component.onCompleted: {
        if (tile_id >= 0 && tile_id != _registeredUpdateSignalForTileId) {
            _registeredUpdateSignalForTileId = tile_id
            app.registerBackendSignal(tile_id, "info.main.update-tile.finished", function(args) {
                root.settings = args[2]  // 0=signal, 1=tile_id, 2+=args
            })
        }
    }
}
