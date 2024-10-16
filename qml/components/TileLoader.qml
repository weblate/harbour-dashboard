/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2020-2024  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0

import "../components"
import "../tiles/common"

// Note: elements must live inside of tilesViewModel and
// have an ObjectModel attached property.

Loader {
    id: root

    property ObjectModel tilesViewModel
    property bool debug: true

    asynchronous: false
    source: ""

    onStatusChanged: {
        if (status == Loader.Error) {
            setSource('../tiles/common/BrokenTile.qml', defaultProperties)
            // console.error("failed to show tile:", JSON.stringify(defaultProperties))
        }
    }

    property var defaultProperties: ({
        'debug': Qt.binding(function(){ return root.debug }),
        'bindEditingTarget': flow,
        'bindEditingProperty': 'editing',
        'dragProxyTarget': floatingTile,
        'objectIndex': Qt.binding(function(){ return root.ObjectModel.index }),
        'tilesViewModel': tilesViewModel
    })

    function load(tile_type, size, settings, hideBackground) {
        settings['tile_type'] = tile_type
        defaultProperties['tile_id'] = settings['tile_id']
        defaultProperties['size'] = size
        defaultProperties['settings'] = settings
        defaultProperties['showBackground'] = (!!hideBackground ? false : true)

        var source = "../tiles/%1/Tile.qml"

        if (settings.hasOwnProperty('provider_id')) {
            source = source.arg(tile_type + '/' + settings.provider_id)
        } else {
            source = source.arg(tile_type)
        }

        root.setSource(source, defaultProperties)
        console.log("loading tile id", defaultProperties['tile_id'], "(", tile_type, ") using", source, JSON.stringify(settings))
    }
}
