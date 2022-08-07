/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

// import "private"
import "../../base"

ForecastTileBase {
    objectName: "weather:mch"

    allowConfig: false
    allowDetails: false
    allowRefresh: false
    allowResize: false

    property int _modelUpdateSequence: -1

    Component.onCompleted: {
        app.registerBackendSignal(tile_id, "provider.mch.test", function(args){
            // args: 0=signal, 1=tile_id, 2=sequence, 3=command, 4=data

            if (args[2] < _modelUpdateSequence) {
                console.log("OUTDATED PROVIDER RESULT DROPPED", args[0], args[1], args[2], args[3], JSON.stringify(args[4]))
            } else {
                console.log("PROVIDER RESULT SIGNAL RECEIVED", args[0], args[1], args[2], args[3], JSON.stringify(args[4]))
            }
        })

        _modelUpdateSequence += 1
        var data = {'data-field': 42}
        app.sendProviderCommand('mch', 'test-command', tile_id, _modelUpdateSequence, data)

        _modelUpdateSequence += 1
        data = {'data-field': 'blah blah'}
        app.sendProviderCommand('mch', 'test-command', tile_id, _modelUpdateSequence, data)
    }
}
