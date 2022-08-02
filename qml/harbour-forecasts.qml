/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.Notifications 1.0
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

    property string dateTimeFormat: qsTr("d MMM yyyy '('hh':'mm')'")
    property string timeFormat: qsTr("hh':'mm")
    property string fullDateFormat: qsTr("ddd d MMM yyyy")

    property string tempUnit: "°C"
    property string rainUnit: "mm/h"
    property string rainUnitShort: "mm"
    property string windUnit: "km/h"

    property bool haveWallClock: wallClock != null
    property QtObject wallClock

    // Track init status of the Python backend and the main page.
    // When both components are ready, we should start loading data.
    property int initReady: 0

    // MaintenanceOverlay {
    //     id: maintenanceOverlay
    //     text: qsTr("Database Maintenance")
    //     hintText: qsTr("Please be patient and allow up to 30 seconds for this.")
    // }
    //
    // MaintenanceOverlay {
    //     id: disableAppOverlay
    //     text: qsTr("Currently unusable")
    //     hintText: qsTr("This app is currently unusable, due to a change at the data provider's side.")
    // }

    signal tilesLoaded(var tiles)
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

    Python {
        id: py
        property bool ready: false

        onReceived: console.log(JSON.stringify(data))
        onError: console.error(traceback)
        onReadyChanged: initReady += 1

        Component.onCompleted: {
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
                            } else {
                                // TODO improve error reporting
                                console.log('[FATAL] failed to initialize backend')
                            }
                        })
            })
        }
    }

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

        // TODO implement a way to detect API breakage and enable the overlay automatically
        // disableAppOverlay.state = "visible";

        // if (Storage.dbNeedsMaintenance()) {
        //     maintenanceOverlay.state = "visible";
        //     Storage.doDatabaseMaintenance();
        //     maintenanceOverlay.state = "invisible";
        // }
    }
}
