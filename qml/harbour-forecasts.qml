/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
// import Nemo.Notifications 1.0
import io.thp.pyotherside 1.5

import "pages"

ApplicationWindow {
    id: app
    allowedOrientations: Orientation.All

    // We have to explicitly set the \c _defaultPageOrientations property
    // to \c Orientation.All so the page stack's default placeholder page
    // will be allowed to be in landscape mode. (The default value is
    // \c Orientation.Portrait.) Without this setting, pushing multiple pages
    // to the stack using \c animatorPush() while in landscape mode will cause
    // the view to rotate back and forth between orientations.
    // [as of 2021-02-17, SFOS 3.4.0.24, sailfishsilica-qt5 version 1.1.110.3-1.33.3.jolla]
    _defaultPageOrientations: Orientation.All

    initialPage: Component {
        MainPage {}
    }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    property ObjectModel _coverTilesModel: ObjectModel {}

    property string dateTimeFormat: qsTr("d MMM yyyy '('hh':'mm')'")
    property string timeFormat: qsTr("hh':'mm")
    property string fullDateFormat: qsTr("ddd d MMM yyyy")

    property string tempUnit: "°C"
    property string rainUnit: "mm/h"
    property string rainUnitShort: "mm"
    property string windUnit: "km/h"

    property bool fatalOccurred: false
    property bool haveWallClock: wallClock != null
    property QtObject wallClock

    // Track init status of the Python backend and the main page.
    // When both components are ready, we should start loading data.
    property int initReady: 0


    // -------------------------------------------------------------------------
    // NAVIGATION FUNCTIONS

    function showFatalError(message) {
        fatalOccurred = true
        pageStack.completeAnimation() // abort any running animation

        // We don't clear the stack to keep transition animations
        // clean. FatalErrorPage will block any further navigation.
        pageStack.push(Qt.resolvedUrl("pages/FatalErrorPage.qml"), {
                           errorMessage: message
                       })
    }

    function showMainPage(operationType) {
        if (fatalOccurred) return

        pageStack.replaceAbove(null, Qt.resolvedUrl("pages/MainPage.qml"), {},
                               operationType !== undefined ? operationType :
                                                             PageStackAction.Immediate)
    }


    // -------------------------------------------------------------------------
    // BACKEND/DATABASE STATUS SIGNALS

    signal tilesLoaded(var tiles)
    signal tileAdded(var tile_type, var size, var settings, var tile_id, var sequence)

    // -------------------------------------------------------------------------
    // BACKEND/DATABASE INTERACTION FUNCTIONS

    // ---------- SIGNAL HANDLING and PROVIDER INTERACTION
    // Functions in this section are most important for tile implementations.

    // Send a command that will be handled by a data provider.
    //
    // Register a callback using registerBackendSignal(...) to receive the results
    // of the command.
    //
    // 'tileId' and 'sequence' will be used to identify the caller. The results should
    // contain a 'sequence' field as well. This allows to discern the results of multiple
    // calls, e.g. when live-updating a model.
    //
    // Pass any data arguments that are required for the command as an object / dict in
    // the 'data' field.
    //
    // ARGUMENTS:
    // provider: str | command: str | tileId: int | sequence: int | data: object
    //
    function sendProviderCommand(provider, command, tileId, sequence, data) {
        py.call("meteo.send_provider_command", [command, provider, tileId, sequence, data], function(){
            console.log("backend called for provider '%1': '%2' (tile: %3, seq: %4) -- %5".arg(
                            provider).arg(command).arg(tileId).arg(sequence).arg(JSON.stringify(data)))
        })
    }


    // Register a Qt signal that will be emitted when the backend sends a notification.
    // The backend must identify the target in its first argument. The second argument
    // must be a Python dictionary / JS object that holds all additional data.
    //
    // The Qt signal will receive a list of [signal_name, tile_id, remaining_args...]. It will
    // only be emitted if the backend signal is directed at a tile with a matching identifier.
    //
    // Use this method to communicate with providers from inside Tile implementations.
    //
    // IMPORTANT NOTE: it is not possible to register additional handlers for which there
    //     is already a specific handler defined with setHandler(...).
    //
    // IMPORTANT NOTE: only one local signal can be connected to a specific remote signal
    //     for each tile.
    //
    // ARGUMENTS:
    // tileId: int | backendSignal: str | localSignal: function
    //
    property var _signalHandlerRegistry: ({})

    function registerBackendSignal(tileId, backendSignal, localSignal) {
        if (!_signalHandlerRegistry.hasOwnProperty(backendSignal)) {
            _signalHandlerRegistry[backendSignal] = {}
        }
        _signalHandlerRegistry[backendSignal][tileId] = localSignal
        console.log("registered backend signal handler for", backendSignal,
                    "at", tileId)
    }

    // Unregister a Qt signal that has previously been registered using registerBackendSignal(...).
    //
    // It is important to unsubscribe from any signals that are no longer needed.
    // This makes sure no functions are called in invalid contexts.
    //
    // ARGUMENTS:
    // tileId: int | backendSignal: str
    //
    function unregisterBackendSignal(tileId, backendSignal) {
        if (   _signalHandlerRegistry.hasOwnProperty(backendSignal)
            && _signalHandlerRegistry[backendSignal].hasOwnProperty(tileId)) {
                console.log("unregistered backend signal handler for", backendSignal, "at", tileId)
                delete _signalHandlerRegistry[backendSignal][tileId]
        } else {
            console.warn("cannot unregistered backend signal handler for", backendSignal,
                         "at", tileId, "because it is not registered")
        }
    }


    // ---------- DIRECT BACKEND COMMANDS

    function loadTiles() {
        py.call("meteo.get_tiles", [], function(tiles) {
            if (tiles.constructor === Array) {
                console.log("loaded", tiles.length, "tiles from the backend")
                tilesLoaded(tiles)
            } else {
                console.log("failed to load tiles, got:", tiles)
                tilesLoaded([])
            }
        })
    }

    function addTile(tile_type, size, settings) {
        py.call("meteo.add_tile", [tile_type, size, settings], function() {
            console.log("tile addded:", tile_type, ", size", size, JSON.stringify(settings))
        })
    }

    function removeTile(tile_id) {
        py.call("meteo.remove_tile", [tile_id], function() {
            console.log("tile removed:", tile_id)
        })
    }

    function updateTile(tile_id, settings) {
        py.call("meteo.update_tile", [tile_id, settings], function() {
            console.log("tile updated:", tile_id, JSON.stringify(settings))
        })
    }

    function resizeTile(tile_id, size) {
        py.call("meteo.resize_tile", [tile_id, size], function() {
            console.log("tile size changed:", tile_id, size)
        })
    }

    function moveTile(tile_id, from, to) {
        py.call("meteo.move_tile", [tile_id, from, to], function() {
            console.log("tile moved:", tile_id, from, to)
        })
    }

    function runDatabaseMaintenance(caller) {
        py.call("meteo.run_database_maintenance", [caller], function() {
            console.log("database maintenance started by", caller, "is done")
        })
    }


    // -------------------------------------------------------------------------
    // BACKEND MAINTENANCE

    ConfigurationGroup {
        id: config
        path: "/apps/harbour-forecasts"
        property string lastMaintenance: "2000-01-01"
        property int currentCoverIndex: 0
    }

    function _checkMaintenance() {
        if (config.lastMaintenance === "2000-01-01") {
            // Don't run maintenance the very first time the app is started.
            config.lastMaintenance = (new Date()).toISOString()
            return
        }

        var prev = new Date(config.lastMaintenance)
        var now = new Date()
        var monthInMilliseconds = 1000 * 60 * 60 * 24 * 30

        if (prev.getTime() + 3*monthInMilliseconds < now.getTime()) {
            console.log("last database maintenance:", prev.toISOString(), "- today:", now.toISOString())

            var maintenancePage = pageStack.push(Qt.resolvedUrl("pages/MaintenancePage.qml"))
            maintenancePage.finished.connect(function(){
                config.lastMaintenance = (new Date()).toISOString()
            })
        }
    }


    // -------------------------------------------------------------------------
    // BRIDGE TO THE BACKEND

    Python {
        id: py
        property bool ready: false

        onError: console.error(traceback)
        onReadyChanged: initReady += 1
        onReceived: {
            if (/^fatal\./.test(data[0])) {
                console.error("[FATAL] unexpected error:", JSON.stringify(data))
                showFatalError(qsTr("An unrecoverable error occurred."))
            } else if (/^warning./.test(data[0])) {
                console.warn("[WARNING] unexpected warning:", JSON.stringify(data))
            } else {
                console.log(JSON.stringify(data))
            }

            if (_signalHandlerRegistry.hasOwnProperty(data[0])) {
                if (_signalHandlerRegistry[data[0]].hasOwnProperty(data[1])) {
                    console.log("calling registered handler for", data[0], "at", data[1])
                    _signalHandlerRegistry[data[0]][data[1]](data)
                }
            }
        }

        Component.onCompleted: {
            // Define signal callbacks
            setHandler('info.main.add-tile.finished', function(tile_type, size, settings, tile_id, sequence){
                tileAdded(tile_type, size, settings, tile_id, sequence)
            })

            setHandler('fatal.local-data.inaccessible', function(kind, directory, error){
                console.error("[FATAL] backend location inaccessible:", kind, directory, error)
                showFatalError(qsTr("A backend database is inaccessible."))
            })

            // Add the directory of this .qml file to the search path
            addImportPath(Qt.resolvedUrl('./py'))
            importModule("meteo", function() {
                console.log("meteo.py loaded")
                py.call("meteo.initialize",
                        [StandardPaths.data, StandardPaths.cache, String(StandardPaths.cache).replace('.cache', '.config')],
                        function(success) {
                            if (success) {
                                console.log("backend successfully initialized")
                                console.log("paths:",
                                            StandardPaths.data,
                                            StandardPaths.cache,
                                            String(StandardPaths.cache).replace('.cache', '.config'))

                                ready = true
                                _checkMaintenance()
                            } else {
                                showFatalError(qsTr("Failed to initialize the backend."))
                            }
                        })
            })
        }
    }


    // -------------------------------------------------------------------------
    // MAIN APP SETUP

    Component.onCompleted: {
        // Avoid hard dependency on Nemo.Time and load it in a complicated
        // way to make Jolla's validator script happy.
        wallClock = Qt.createQmlObject("
            import QtQuick 2.0
            import %1 1.0
            WallClock {
                enabled: Qt.application.active
                updateFrequency: WallClock.Minute
            }".arg("Nemo.Time"), app, 'WallClock')
    }
}
