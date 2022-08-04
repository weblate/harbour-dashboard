/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    id: root
    allowedOrientations: Orientation.All

    function defaultFor(what, fallback) {
        return (what === '' || typeof what === 'undefined' || what === null) ? fallback : what
    }

    function defaultOrNullFor(what, fallback) {
        return (what === '' || typeof what === 'undefined') ? fallback : what
    }

    // must be defined by the implementation
    property var bakeSettings: function() { // function to update the updatedSettings object
        // Note: this function should not save anything to the database yet.
        // Actually saving the data is handled by the Tile implementation that calls this dialog.
        // It is not necessary to copy the initial settings object. Only include changed fields here.
        console.error("bug: settings dialog must implement a save handler")
    }
    property var updatedSettings: ({}) // save updated settings here

    // must be bound to field validators, i.e. the dialog should
    // only be accepted when all required settings are set
    canAccept: false

    // automatically populated through ForecastTileBase
    property int tile_id: -1  // database identifier
    property var settings: ({})  // implementation specific settings passed from/to the database
    property bool debug: false  // bind to global debug toggle

    // low level access to the dialog
    readonly property Dialog dialogRoot: root
    readonly property Column contentItem: contentColumn
    default property alias _contents: contentColumn.data

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        contentHeight: contentColumn.height

        VerticalScrollDecorator {
            flickable: flick
        }

        Column {
            id: contentColumn
            width: parent.width

            DialogHeader {
                acceptText: qsTr("Save")
                cancelText: qsTr("Cancel")
            }

            // contents live here
        }
    }

    onDone: {
        if (result == DialogResult.Accepted) {
            console.log("saving settings for tile", tile_id, "with initial settings", JSON.stringify(settings))
            updatedSettings = {}
            bakeSettings()
        } else if (result == DialogResult.Rejected) {
            updatedSettings = {}
        }
    }
}
