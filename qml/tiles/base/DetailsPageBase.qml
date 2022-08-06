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

    property int tile_id: -1  // database identifier
    property var settings: ({})  // implementation specific settings passed from/to the database
    property bool debug: false  // bind to global debug toggle

    property bool allowRefresh: tile && tile.allowRefresh
    property bool allowConfig: tile && tile.allowConfig

    property ForecastTileBase tile: null  // bind to the tile instance that this details page belongs to

    function defaultFor(what, fallback) {
        return (what === '' || typeof what === 'undefined' || what === null) ? fallback : what
    }

    function defaultOrNullFor(what, fallback) {
        return (what === '' || typeof what === 'undefined') ? fallback : what
    }

    // Implementations must define their own page container,
    // as not all pages require a pulley menu or a flickable.
    //
    // Make sure not to forget the VerticalScrollDecorator{} when
    // adding a flickable to the page.
}
