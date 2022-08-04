/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0

SilicaItem {
    id: root

    // WallClock (from Nemo.Time) is documented here:
    // https://github.com/sailfishos/nemo-qml-plugin-time/blob/master/src/nemowallclock.cpp

    readonly property bool haveWallClock: wallClock != null
    property var wallClock: null

    property string clockFace: "plain"
    property string timeFormat: "local"
    property string timezone: ""
    property int utcOffsetSeconds: 0

    readonly property var timezoneInfo: _timezoneInfo
    property var _timezoneInfo: null
    onTimezoneChanged: _timezoneInfo = (timezone !== "" ? findTimezoneInfo(timezone) : null)

    property int _timezoneOffsetSeconds: {
        if (timezoneInfo !== null) {
            var offset = String(timezoneInfo.currentOffset).replace('UTC', '')
            offset = offset.split(':')
            return (Number(offset[0]) * 60 + Number(offset[1])) * 60
        } else {
            return 0
        }
    }
    property date _currentLocalTime: wallClock.time
    property string _conversionOffset: {
        // This abomination creates an offset relative to the local time,
        // so that when JS converts the UTC date back to the local timezone,
        // we actually get the desired remote time.
        //
        // For example:
        // A. Prerequisites:
        // 1. UTC is at offset 0 relative to UTC.
        // 2. Your local timezone is two hours east of UTC, i.e. plus 2 hours, which JS
        //    interprets as minus 120 minutes in Date.getTimezoneOffset().
        // 3. You want to know the current time at a place five hours east of UTC, i.e. plus 5 hours.
        //
        // B. Conversion:
        // 1. Take the current local time (e.g. 14:00 local = UTC+2)
        // 2. Expect the remote time to be +3 hours from your time (e.g. 17:00 remote = UTC+5)
        // 3. Expect UTC time to be -2 hours from your local time (e.g. 12:00 UTC)
        // 4. *anguish in an abyss of despair*
        // 5. Take the remote offset (+5), subtract the local offset (+2), create a JS Date
        //    object in UTC plus the new offset (+3), then print it as if it were a local
        //    time. This means JS adds the local offset back on (+2), leading to the desired offset (+5).
        // 6. *don't think of weird offsets, leap seconds, slow processing...*

        var localOffset = _currentLocalTime.getTimezoneOffset() * 60 * (-1)
        var remoteOffset = localOffset

        if (timeFormat == "offset") remoteOffset = utcOffsetSeconds
        else if (timeFormat == "timezone") remoteOffset = _timezoneOffsetSeconds

        var conv = [
            Math.floor((remoteOffset - localOffset) / 60 / 60),
            Math.floor(((remoteOffset - localOffset) / 60) % 60)
        ]

        return (conv[0] < 0 ? '+' : '-')
                + zeroPad(Math.abs(conv[0])) + ":"
                + zeroPad(Math.abs(conv[1]))
    }

    property date convertedTime: new Date(
        // Use this time object as if it were in local time. For example, print it
        // with convertedTime.toLocaleString(Qt.locale(), app.timeFormat).
        // Use getHours() and related methods to extract details. The getUTC...() methods
        // will return skewed values.
        zeroPad(_currentLocalTime.getUTCFullYear()) + "-" +
        zeroPad(_currentLocalTime.getUTCMonth()+1) + "-" +  // months are 0-11 in JS
        zeroPad(_currentLocalTime.getUTCDate()) + "T" +
        zeroPad(_currentLocalTime.getUTCHours()) + ":" +
        zeroPad(_currentLocalTime.getUTCMinutes()) + ":" +
        zeroPad(_currentLocalTime.getUTCSeconds()) + _conversionOffset
    )

    property real _hoursAngle: (convertedTime.getHours() + convertedTime.getMinutes() / 60) * 30 % 360
    property real _minutesAngle: convertedTime.getMinutes() * 6 % 360

    function zeroPad(value) {
        if (value < 10) {
            return "0" + String(value)
        } else {
            return String(value)
        }
    }

    HighlightImage {
        id: background
        anchors.fill: parent
        source: "clock-face-" + clockFace + ".png"
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        fillMode: Image.PreserveAspectFit

        onStatusChanged: {
            if (status == Image.Error && source != "clock-face-plain.png") {
                source = "clock-face-plain.png"
            }
        }
    }

    Rectangle {
        anchors {
            bottom: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }

        rotation: _hoursAngle
        transformOrigin: Item.Bottom

        Behavior on rotation { NumberAnimation { } }

        width: 1.5 * Theme.paddingSmall
        height: parent.height / 2 / 2.2
        radius: 10
        color: parent.highlighted ? palette.highlightColor : palette.primaryColor
    }

    Rectangle {
        radius: 90
        width: 2.2 * Theme.paddingSmall
        height: width
        anchors.centerIn: parent
        color: parent.highlighted ? palette.highlightColor : palette.primaryColor
    }

    Rectangle {
        anchors {
            bottom: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }

        rotation: _minutesAngle
        transformOrigin: Item.Bottom

        Behavior on rotation { NumberAnimation { } }

        width: 1.2 * Theme.paddingSmall
        height: parent.height / 2 / 1.55
        radius: 10
        color: parent.highlighted ? palette.highlightColor : palette.primaryColor
    }

    DelegateModel {
        id: timezoneProxyModel
        delegate: Item { visible: false }

        // The time zone model is not documented and the API is not public.
        // It is possible to take a look at the model's methods:
        //
        // for(var it in timezoneProxyModel.model) {
        //     console.log(it + " = " + timezoneProxyModel.model[it])
        // }
        //
        // However, it is not possible to access items directly.
        // This is why we need the DelegateModel as a proxy (see findTimezoneInfo()
        // for how to access items).
        //
        // From the code at </usr/lib>/qt5/qml/Sailfish/Timezone/ and from strings
        // in libsailfishtimezoneplugin.so, we can glean the following properties:
        //
        // model.name                 -- "Pacific/Pago_Pago"
        //       area                 -- "Pacific"
        //       city                 -- "Rarotonga"
        //       country              -- "Cook Islands"
        //       offset               -- "UTC+1:00"
        //       offsetWithDstOffset  -- "UTC+1:00 (+2:00)"
        //       currentOffset        -- "UTC+2:00"
        //       sectionOffset        -- "UTC+1:00"
        //       filter               -- ?
        model: null  // set to Sailfish.Timezone.TimezoneModel in Component.onCompleted()
    }

    function findTimezoneInfo(queryName) {
        if (timezoneProxyModel.model === null) {
            console.log("cannot lookup timezone info for %1: model is not yet ready".arg(queryName))
            return null
        }

        var count = timezoneProxyModel.model.count
        var items = timezoneProxyModel.items

        for (var i = 0; i < count; i++) {
            var item = items.get(i).model

            if (String(item.name) == String(queryName)) {
                console.log("found timezone info for", queryName, "->", item.city, item.offsetWithDstOffset)
                return item
            }
        }

        console.log("could not find timezone info for", queryName)
        return null
    }

    Component.onCompleted: {
        // Avoid hard dependencies on unstable/non-public APIs and load
        // them in a convoluted way to make Jolla's validator script happy.
        //
        // WARNING This might fail horribly some day.

        wallClock = Qt.createQmlObject("
            import QtQuick 2.0
            import %1 1.0
            WallClock {
                enabled: Qt.application.active
                updateFrequency: WallClock.Minute
            }".arg("Nemo.Time"), app, 'WallClock')

        timezoneProxyModel.model = Qt.createQmlObject("
            import QtQuick 2.0
            import %1 1.0
            TimezoneModel { }
        ".arg("Sailfish.Timezone"), app, 'TimezoneInfo')
        timezoneChanged() // force refresh all related properties
    }
}
