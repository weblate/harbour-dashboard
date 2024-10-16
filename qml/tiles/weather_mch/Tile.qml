/*
 * This file is part of harbour-dashboard
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

    // Sizes:
    // - all: location, current weather symbol,
    //        current temperature, min/max for the day,
    // - small: current precipication
    // - medium: small graph showing temperature and precipitation
    //           for the next 90 minutes
    // - large: graph for the whole day, overview of all available days,
    //          graphs for other days when selected

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
