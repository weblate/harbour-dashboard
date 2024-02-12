/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: root
    allowedOrientations: Orientation.All

    // -------------------------------------------------------------------------
    // MUST BE CONFIGURED BY IMPLEMENTATIONS

    objectName: "DetailsPageBase" // object name identifying the class of this tile, e.g. "weather_<provider>"
    property int tile_id: -1        // database identifier
    property var settings: ({})     // implementation specific settings passed from/to the database
    property bool debug: false      // bind to global debug toggle

    property bool allowRefresh: tile && tile.allowRefresh   // whether the tile supports refreshing
    property bool allowConfig: tile && tile.allowConfig     // whether the tile supports configuration

    property ForecastTileBase tile: null  // bind to the tile instance that this details page belongs to

    readonly property MetadataBase metadata: {
        var comp = Qt.createComponent(
            Qt.resolvedUrl("../%1/Metadata.qml".arg(objectName)))
        return comp.createObject(root)
    }

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

    // handler signature: function(event: str, sequence: int, data: dict)
    function connectProviderSignal(event, handler, sequence_or_oneshot) {
        metadata.connectProviderSignal(tile_id, event, handler, sequence_or_oneshot)
    }

    // -------------------------------------------------------------------------
    // DEFAULT PULL DOWN MENU
    //
    // The menu allows to configure and refresh the tile if either of
    // these actions is enabled (cf. allowRefresh and allowConfig).
    // If neither is allowed, the pulley menu will be hidden.
    //
    // Enable the menu by adding it to a custom flickable, e.g. a SilicaFlickable:
    //    pullDownMenu: root.defaultPulleyMenu.createObject(flickable)
    //
    // To add custom entries to the pulley menu, simply parent them to the
    // actual pulley menu object. The MenuItem{} can be declared anywhere in the file.
    // Here, "flickable" refers to the ID of the main flickable that holds the pulley menu.
    //     MenuItem {
    //         parent: flickable.pullDownMenu._contentColumn
    //         text: "Menu item"
    //     }
    property alias defaultPulleyMenu: defaultPulleyMenuComponent

    Component {
        id: defaultPulleyMenuComponent

        PullDownMenu {
            visible: allowRefresh || allowConfig || _content.length > 2

            MenuItem {
                visible: root.allowConfig
                text: qsTr("Configure")
                onClicked: root.tile.requestConfig()
            }

            MenuItem {
                visible: root.allowRefresh
                text: qsTr("Refresh")
                onClicked: root.tile.requestRefresh()
            }
        }
    }

    // -------------------------------------------------------------------------
    // IMPLEMENTATION

    // Implementations must define their own page container,
    // as not all pages require a pulley menu or a flickable.
    //
    // Make sure not to forget the VerticalScrollDecorator{} when
    // adding a flickable to the page.
}
