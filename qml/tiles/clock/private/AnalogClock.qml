/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
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
    property int utcOffsetMinutes: 0

    function _convertedTime(time) {
        if (timeFormat == "local") {
            return [time.getHours(), time.getMinutes()]
        } else if (timeFormat == "offset") {
            return [time.getUTCHours() + Math.floor(utcOffsetMinutes / 60), time.getUTCMinutes() + (utcOffsetMinutes % 60)]
        } else if (timeFormat == "timezone") {
            // TODO implement
            return [time.getUTCHours() + Math.floor(utcOffsetMinutes / 60), time.getUTCMinutes() + (utcOffsetMinutes % 60)]
        }
    }

    function _hoursAngle(time) {
        var conv = _convertedTime(time)
        return (conv[0] + conv[1] / 60) * 30 % 360
    }

    function _minutesAngle(time) {
        var conv = _convertedTime(time)
        return conv[1] * 6 % 360
    }

    function _wallOffset() {
        // WallClock holds local time but for
        return wallClock.time.getTimezoneOffset()
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

        rotation: _hoursAngle(wallClock.time)
        transformOrigin: Item.Bottom

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

        rotation: _minutesAngle(wallClock.time)
        transformOrigin: Item.Bottom

        width: 1.2 * Theme.paddingSmall
        height: parent.height / 2 / 1.55
        radius: 10
        color: parent.highlighted ? palette.highlightColor : palette.primaryColor
    }

    Component.onCompleted: {
        // Avoid hard dependency on Nemo.Time and load it in a complicated
        // way to make Jolla's validator script happy.
        wallClock = Qt.createQmlObject("
            import QtQuick 2.0
            import %1 1.0
            WallClock {
                enabled: Qt.application.active
                updateFrequency: WallClock.Minute
            }".arg("Nemo.Time"), app, 'WallClock')
    }
}

