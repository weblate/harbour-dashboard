/*
 * This file is part of harbour-dashboard
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

    objectName: defaultFor(metadata.type, "ForecastTileBase") // object name identifying the class of this tile, e.g. "weather_<provider>"
    allowConfig: false                // requires specific support by the tile implementation: Settings.qml
    allowDetails: false               // requires specific support by the tile implementation: Details.qml
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

    function sendProviderCommand(command, data, sequence, callback) {
        metadata.sendProviderCommand(tile_id, command, data, sequence, callback)
    }

//        if (!metadata.hasProvider) {
//            console.error("bug: cannot send provider commands without a provider")
//            return
//        }

//        app.registerProvider(objectName)
//        app.sendProviderCommand(objectName, command, tile_id, defaultFor(sequence, 0), data, callback)
//    }

    // handler signature: function(event: str, sequence: int, data: dict)
    function connectProviderSignal(event, handler, sequence_or_oneshot) {
        metadata.connectProviderSignal(tile_id, event, handler, sequence_or_oneshot)
    }

//        var parent = root  // TODO this function is passed to the Settings.qml and should then use its root as parent
//        var sequence = 0

//        if (sequence_or_oneshot == 'once') {
//            parent = 'once'
//            sequence = 0
//        } else {
//            parent = root
//            sequence = defaultFor(sequence_or_oneshot, 0)
//        }

//        app.registerBackendSignal(
//                tile_id, "provider.%1.%2".arg(objectName).arg(event), function(args) {
//            // args: 0=signal, 1=tile_id, 2=sequence, 3=command, 4=data
//            handler(args[0], args[2], args[4])
//        }, parent, sequence)
//    }

//    function disconnectProviderSignal(event) {
//        // TODO fix or remove this function
//        app.unregisterBackendSignal(tile_id, event)
//    }

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
    showDetailsOnClick: detailsPage != ""

    readonly property MetadataBase metadata: {
        var comp = Qt.createComponent(
            Qt.resolvedUrl("../%1/Metadata.qml".arg(objectName)))
        return comp.createObject(root)
    }

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
                'objectName': objectName,
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
                'objectName': objectName,
                'settings': Qt.binding(function(){ return settings }),
                'debug': Qt.binding(function(){ return debug }),
                'tile_id': Qt.binding(function(){ return tile_id }),
//                'sendProviderCommand': Qt.binding(function(){ return sendProviderCommand }),
//                'connectProviderSignal': Qt.binding(function(){ return connectProviderSignal }),
//                'disconnectProviderSignal': Qt.binding(function(){ return disconnectProviderSignal }),
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

    Connections {
        id: resizeConnection
        target: null
        onSizeChanged: app.resizeTile(tile_id, size)
    }

    Component.onCompleted: {
        if (tile_id >= 0 && tile_id != _registeredUpdateSignalForTileId) {
            _registeredUpdateSignalForTileId = tile_id
            app.registerBackendSignal(tile_id, "info.main.update-tile.finished", function(args) {
                root.settings = args[2]  // 0=signal, 1=tile_id, 2+=args
            })
        }

        if (tile_id >= 0 && metadata.hasProvider) {
            app.registerProvider(objectName)
        }

        // avoid saving the default size while the tile is still loading
        resizeConnection.target = root
    }
}
