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

    // -------------------------------------------------------------------------
    // MUST BE DEFINED BY IMPLEMENTATIONS

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
    // AUTOMATICALLY POPULATED THROUGH ForecastTileBase

    objectName: "SettingsDialogBase" // object name identifying the class of this tile, e.g. "weather_<provider>"
    property int tile_id: -1     // database identifier
    property var settings: ({})  // implementation specific settings passed from/to the database
    property bool debug: false   // bind to global debug toggle

    readonly property MetadataBase metadata: {
        var comp = Qt.createComponent(
            Qt.resolvedUrl("../%1/Metadata.qml".arg(objectName)))
        return comp.createObject(root)
    }

//    property var sendProviderCommand: function(){
//        console.error("bug: handler for sending provider commands is undefined")
//    }
//    property var connectProviderSignal: function(){
//        console.error("bug: handler for receiving provider signals is undefined")
//    }
//    property var disconnectProviderSignal: function() {
//        console.error("bug: handler for disconnecting from provider signals is undefined")
//    }

    // -------------------------------------------------------------------------
    // LOW-LEVEL ACCESS TO THE DIALOG

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
