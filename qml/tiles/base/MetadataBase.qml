/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2024  Mirian Margiani
 */

import QtQuick 2.6

QtObject {
    id: root

    property string type: "invalid"
    property string name: qsTr("Unimplemented tile")
    property string description: qsTr("This tile has no description.")
    property string icon: "image://theme/icon-l-clock"
    property bool requiresConfig: false

    // if true, the provider implementation in <tile>/private/<tile>.py will be loaded
    property bool hasProvider: false

    function sendProviderCommand(tile_id, command, data, sequence, callback) {
        if (!hasProvider) {
            console.error("bug: cannot send provider commands without a provider")
            return
        }

        app.registerProvider(type)
        app.sendProviderCommand(type, command, tile_id, defaultFor(sequence, 0), data, callback)
    }

    // handler signature: function(event: str, sequence: int, data: dict)
    function connectProviderSignal(tile_id, event, handler, sequence_or_oneshot) {
        var parent = root
        var sequence = 0

        if (sequence_or_oneshot === 'once') {
            parent = 'once'
            sequence = 0
        } else {
            parent = root
            sequence = defaultFor(sequence_or_oneshot, 0)
        }

        app.registerBackendSignal(
                tile_id, "provider.%1.%2".arg(type).arg(event), function(args) {
            // args: 0=signal, 1=tile_id, 2=sequence, 3=command, 4=data
            handler(args[0], args[2], args[4])
        }, parent, sequence)
    }

//    function disconnectProviderSignal(event) {
//        // TODO fix or remove this function
//        app.unregisterBackendSignal(tile_id, event)
//    }
}
