/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

import "../js/storage.js" as Storage

BackgroundItem {
    property int hour
    property int day
    property var clickedCallback

    width: parent.width/8
    height: column.height + Theme.paddingSmall

    signal summaryClicked(int hour, int symbol)
    onClicked: summaryClicked(hour, forecastData[day].temperature.datasets[0].symbols[hour])

    Component.onCompleted: {
        summaryClicked.connect(clickedCallback);

        if (   (   day == 0
                && app.dataTimestamp != undefined
                && app.dataTimestamp.toDateString() == new Date().toDateString()
                && hour == Storage.getCurrentSymbolHour())
            || hour == app.noonHour
        ) {
            summaryClicked(hour, forecastData[day].temperature.datasets[0].symbols[hour]);
        }
    }

    Column {
        id: column
        width: parent.width

        property var textColor: ((app.dataTimestamp && app.dataTimestamp.toDateString() == new Date().toDateString() && day == 0) ?
            (hour >= Storage.getCurrentSymbolHour() ? Theme.secondaryColor : Theme.secondaryHighlightColor) : Theme.secondaryColor)

        ForecastSummaryItemLabel {
            value: hour
            font.pixelSize: Theme.fontSizeSmall
        }

        Image {
            width: 100
            height: Theme.itemSizeSmall
            fillMode: Image.PreserveAspectFit
            source: "../weather-icons/" + (
                forecastData[day].temperature.datasets[0].symbols[hour] != undefined ? forecastData[day].temperature.datasets[0].symbols[hour] : 0
            ) + ".svg"
            verticalAlignment: Image.AlignVCenter
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 1
        }

        ForecastSummaryItemLabel {
            value: forecastData[day].temperature.datasets[0].data[hour]
            unit: app.tempUnit
        }

        ForecastSummaryItemLabel {
            property var rain: forecastData[day].rainfall.haveData ? forecastData[day].rainfall.datasets[0].data[hour] : 0
            value: rain > 0 ? rain : ""
            unit: app.rainUnitShort
        }
    }
}
