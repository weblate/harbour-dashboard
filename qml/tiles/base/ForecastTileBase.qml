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

    function defaultFor(what, fallback) {
        return (what === '' || typeof what === 'undefined' || what === null) ? fallback : what
    }

    function defaultOrNullFor(what, fallback) {
        return (what === '' || typeof what === 'undefined') ? fallback : what
    }

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
    property string settingsDialog: "" // Qt.resolvedUrl("Settings.qml")
    property string detailsPage: "" // Qt.resolvedUrl("Details.qml")
    property bool showDetailsOnClick: detailsPage != ""

    // may have to be changed by the tile implementation
    size: "small"  // default size: small, medium, large
    allowRefresh: false // requires specific support by the tile implementation
    allowResize: false // requires specific support by the tile implementation
    allowConfig: false // requires specific support by the tile implementation

    // should be fine like this for most use cases
    allowMove: true
    allowRemove: true
    cancelEditOnClick: false

    property int _registeredUpdateSignalFor: -1

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
            text: qsTr("Arrange tiles")
            onDelayedClick: bindEditingTarget.edit()
        }
        MenuItem {
            visible: root.allowRemove
            text: qsTr("Remove")
            onDelayedClick: root.requestRemoval()
        }
    }

    onClicked: {
        if ((!editing || enabledWhileEditing) && showDetailsOnClick && detailsPage != "") {
            pageStack.push(detailsPage, {
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
        if (tile_id < 0 || tile_id == _registeredUpdateSignalFor) return
        console.log("got a new tile_id", tile_id)
        _registeredUpdateSignalFor = tile_id

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
        if (tile_id >= 0 && tile_id != _registeredUpdateSignalFor) {
            _registeredUpdateSignalFor = tile_id
            app.registerBackendSignal(tile_id, "info.main.update-tile.finished", function(args) {
                root.settings = args[2]  // 0=signal, 1=tile_id, 2+=args
            })
        }
    }
}
