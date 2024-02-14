/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../base"

ForecastTileBase {
    id: root
    objectName: "weather_mch"

    settingsDialog: Qt.resolvedUrl("Settings.qml")
    // detailsPage: Qt.resolvedUrl("Details.qml")

    size: "small"
    allowResize: true
    allowConfig: true
    allowRefresh: false

    Item {
        id: layoutStates
        state: root.size
//        states: [
//            // default layout is 'small' and doesn't need a separate state
//            State {
//                name: "medium"

            // ...
    }

//    onRequestRefresh: {
//        ...
//    }
}
