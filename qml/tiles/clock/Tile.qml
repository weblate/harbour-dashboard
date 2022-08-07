/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "private"
import "../base"
import "../../components" as C

ForecastTileBase {
    id: root
    objectName: "ClockTile"

    settingsDialog: Qt.resolvedUrl("Settings.qml")
    detailsPage: Qt.resolvedUrl("Details.qml")

    size: "small"
    allowResize: true
    allowConfig: true

    // Information items:
    // - primary:
    //   - analog clock
    //   - label
    //   - digital time
    //
    // - secondary:
    //   - offset from UTC
    //   - offset from local time
    //   - textual description

    AnalogClock {
        id: clock
        property string convertedTimeString: convertedTime.toLocaleString(Qt.locale(), app.timeFormat)

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Theme.paddingLarge
        }
        height: parent.height - Theme.paddingMedium - Theme.paddingMedium - clockLabel.height
        width: height

        timeFormat: defaultFor(settings['time_format'], 'local')
        timezone: defaultFor(settings['timezone'], '')
        utcOffsetSeconds: defaultFor(settings['utc_offset_seconds'], 0)
        clockFace: defaultFor(settings['clock_face'], 'plain')
    }

    C.DescriptionLabel {
        id: clockLabel
        inverted: true
        maximumLineCount: 1

        label: clock.convertedTimeString
        description: {
            if (size == 'large') {
                if (settings['label'] || clock.timeFormat == 'local') {
                    qsTr("UTC %1", "time offset like 'UTC -11:00'").arg(clock.formattedUtcOffset)
                } else {
                    ""
                }
            } else {
                if (settings['label']) {
                    settings.label
                } else {
                    if (clock.timeFormat == 'local') {
                        if (size == "small") {
                            ""
                        } else {
                            qsTr("local time")
                        }
                    } else {
                        qsTr("UTC %1", "time offset like 'UTC -11:00'").arg(clock.formattedUtcOffset)
                    }
                }
            }
        }

        horizontalAlignment: Text.AlignHCenter
        labelFont.pixelSize: Theme.fontSizeLarge
        width: parent.width

        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
    }

    C.DescriptionLabel {
        id: extraInfoLabel
        visible: false
        inverted: false
        maximumLineCount: 2

        label: {
            if (size == 'large') {
                if (settings['label']) {
                    settings['label']
                } else if (clock.timeFormat == 'local') {
                    qsTr("local time")
                } else {
                    qsTr("UTC %1", "time offset like 'UTC -11:00'").arg(clock.formattedUtcOffset)
                }
            } else {
                ""
            }
        }
        description: {
            if (size == 'large') {
                if (clock.numericRelativeOffset < 0) {
                    qsTr("%1 hour(s) behind local time", "",
                         Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                    + "\x9C"
                    + qsTr("%1h behind", "shortened form of '%1 hour(s) behind local time'",
                           Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                } else if (clock.numericRelativeOffset > 0) {
                    qsTr("%1 hour(s) ahead of local time", "",
                         Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                    + "\x9C"
                    + qsTr("%1h ahead", "shortened form of '%1 hour(s) ahead of local time'",
                           Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                } else {
                    ""
                }
            } else {
                if (clock.numericRelativeOffset < 0) {
                    qsTr("%1h behind", "shortened form of '%1 hour(s) behind local time'",
                         Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                } else if (clock.numericRelativeOffset > 0) {
                    qsTr("%1h ahead", "shortened form of '%1 hour(s) ahead of local time'",
                         Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                } else {
                    ""
                }
            }
        }

        anchors {
            right: parent.right
            rightMargin: Theme.paddingLarge
            top: clockLabel.bottom
        }

        horizontalAlignment: Text.AlignLeft
        width: parent.width / 2 - Theme.paddingMedium - Theme.paddingLarge
    }

    Item {
        id: layoutStates
        state: root.size
        states: [
            // default layout is 'small' and doesn't need a separate state
            State {
                name: "medium"

                AnchorChanges {
                    target: clock
                    anchors {
                        horizontalCenter: undefined
                        left: parent.left
                        top: undefined
                        verticalCenter: parent.verticalCenter
                    }
                }
                PropertyChanges {
                    target: clock
                    anchors {
                        leftMargin: Theme.paddingLarge
                    }
                    width: Math.min(parent.width / 2, parent.height) - Theme.paddingMedium - Theme.paddingLarge
                    height: width
                }

                AnchorChanges {
                    target: clockLabel
                    anchors {
                        horizontalCenter: undefined
                        bottom: undefined
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                    }
                }
                PropertyChanges {
                    target: clockLabel
                    anchors {
                        rightMargin: Theme.paddingLarge
                        // can't use parent.height because it changes when the context menu is openend
                        verticalCenterOffset: - ((clock.height + extraInfoLabel.height) / 2 - clock.height / 2)
                    }
                    horizontalAlignment: Text.AlignLeft
                    width: parent.width / 2 - Theme.paddingMedium - Theme.paddingLarge
                }

                PropertyChanges {
                    target: extraInfoLabel
                    visible: true
                    inverted: true
                }
            },
            State {
                name: "large"

                AnchorChanges {
                    target: clock
                    anchors {
                        horizontalCenter: undefined
                        left: parent.left
                        top: undefined
                        verticalCenter: parent.verticalCenter
                    }
                }
                PropertyChanges {
                    target: clock
                    anchors {
                        leftMargin: Theme.paddingLarge
                    }
                    width: Math.min(parent.width / 2, parent.height) - Theme.paddingMedium - Theme.paddingLarge
                    height: width
                }

                AnchorChanges {
                    target: clockLabel
                    anchors {
                        horizontalCenter: undefined
                        bottom: undefined
                        verticalCenter: parent.verticalCenter
                        right: parent.right
                    }
                }
                PropertyChanges {
                    target: clockLabel
                    anchors {
                        rightMargin: Theme.paddingLarge
                        // can't use parent.height because it changes when the context menu is openend
                        verticalCenterOffset: - ((clock.height + extraInfoLabel.height) / 2 - clock.height / 2)
                    }
                    horizontalAlignment: Text.AlignLeft
                    width: parent.width / 2 - Theme.paddingMedium - Theme.paddingLarge
                }

                PropertyChanges {
                    target: extraInfoLabel
                    visible: true
                }
            }
        ]
    }
}
