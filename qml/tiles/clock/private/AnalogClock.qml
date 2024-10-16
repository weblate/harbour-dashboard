/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import "."

SilicaItem {
    id: root

    // WallClock (from Nemo.Time) is documented here:
    // https://github.com/sailfishos/nemo-qml-plugin-time/blob/master/src/nemowallclock.cpp

    readonly property bool haveWallClock: wallClock != null
    property var wallClock: null

    // Set this to a time object in your local time zone to calculate
    // an arbitrary time in the remote time zone.
    // Set this property to 'null' to use the current wallclock time.
    //
    // NOTE: You can set this to a time in the remote time zone and
    // use the 'reverseConvertedTime' property to convert a remote
    // time back to local time. However, the clock will then show
    // an invalid time, and all other calculated properties will
    // contain invalid values.
    property var manualBaseTime: null

    property string clockFace: "plain"
    property string timeFormat: "local"
    property string timezone: ""
    property int utcOffsetSeconds: 0

    readonly property var timezoneInfo: _timezoneInfo
    property var _timezoneInfo: null
    onTimezoneChanged: _timezoneInfo = (timezone !== "" ? TimezoneInfo.findTimezoneInfo(timezone) : null)

    readonly property int _timezoneOffsetSeconds: {
        if (timezoneInfo !== null) {
            var offset = String(timezoneInfo.currentOffset).replace('UTC', '')
            offset = offset.split(':')
            return (Number(offset[0]) * 60 + Number(offset[1])) * 60
        } else {
            return 0
        }
    }

    property date _currentLocalTime: (manualBaseTime !== null) ? manualBaseTime : wallClock.time
    readonly property string _conversionOffset: {
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

        return (conv[0] < 0 ? '+' : '-')  // signs must be switched because *hrmpf*
                + zeroPad(Math.abs(conv[0])) + ":"
                + zeroPad(Math.abs(conv[1]))
    }

    readonly property string formattedRelativeOffset: (numericRelativeOffset > 0 ? "+" : "-")
                                                        + "%1:%2".arg(Math.abs(Math.floor(numericRelativeOffset / 60))).arg(
                                                          zeroPad(Math.abs(numericRelativeOffset % 60)))  // offset relative to local time
    readonly property int numericRelativeOffset: (Number(_conversionOffset.split(':')[0]) >= 0 ? -1 : 1)
                                                    * (Math.abs(Number(_conversionOffset.split(':')[0])) * 60
                                                    + Number(_conversionOffset.split(':')[1]))  // in minutes
    readonly property string formattedRelativeOffsetNoSign: formattedRelativeOffset.slice(1)

    readonly property int numericUtcOffset: { // in minutes
        if (timeFormat == 'timezone') {
            Math.round(_timezoneOffsetSeconds / 60)
        } else if (timeFormat == 'offset') {
            Math.round(utcOffsetSeconds / 60)
        } else {
            (_currentLocalTime.getTimezoneOffset() * (-1))
        }
    }
    readonly property string formattedUtcOffset: {
        if (timeFormat == 'timezone') {
            (_timezoneOffsetSeconds > 0 ? "+" : "-")
                    + String(Math.abs(Math.floor(_timezoneOffsetSeconds / 60 / 60))) + ":"
                    + zeroPad(Math.abs(Math.floor(_timezoneOffsetSeconds / 60) % 60))
        } else if (timeFormat == 'offset') {
            (utcOffsetSeconds > 0 ? "+" : "-")
                    + String(Math.abs(Math.floor(utcOffsetSeconds / 60 / 60))) + ":"
                    + zeroPad(Math.abs(Math.floor(utcOffsetSeconds / 60) % 60))
        } else {
            ((_currentLocalTime.getTimezoneOffset() * (-1)) > 0 ? "+" : "-")
                    + String(Math.abs(Math.floor(_currentLocalTime.getTimezoneOffset() / 60 * (-1)))) + ":"
                    + zeroPad(Math.abs(Math.floor((_currentLocalTime.getTimezoneOffset() * (-1)) % 60)))
        }
    }
    readonly property string formattedUtcOffsetNoSign: formattedUtcOffset.slice(1)

    readonly property date convertedTime: new Date(
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

    readonly property date reverseConvertedTime: new Date(
        // Use this time object to convert a remote time back to local time.
        // The remote time must be set through 'manualBaseTime'.
        //
        // Use getHours() and related methods to extract details. The getUTC...() methods
        // will return skewed values.
        //
        // IMPORTANT: remember that all other properties will now contain
        // completely unusable values, and the visual clock will be wrong.
        // To use the clock normally, make sure 'manualBaseTime' always contains
        // time in your local time zone (or is set to 'null').
        zeroPad(_currentLocalTime.getUTCFullYear()) + "-" +
        zeroPad(_currentLocalTime.getUTCMonth()+1) + "-" +  // months are 0-11 in JS
        zeroPad(_currentLocalTime.getUTCDate()) + "T" +
        zeroPad(_currentLocalTime.getUTCHours()) + ":" +
        zeroPad(_currentLocalTime.getUTCMinutes()) + ":" +
        zeroPad(_currentLocalTime.getUTCSeconds()) +
        (_conversionOffset[0] === '+' ? '-' : '+') +
        _conversionOffset.slice(1)
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
        color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
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
        // color: parent.highlighted ? palette.highlightColor : palette.primaryColor
        color: parent.highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
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
        // color: parent.highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
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
    }
}
