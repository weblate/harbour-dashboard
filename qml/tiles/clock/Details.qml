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

DetailsPageBase {
    id: root

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        contentHeight: Math.max(column.height, root.height)
        pullDownMenu: root.defaultPulleyMenu.createObject(flickable)

        VerticalScrollDecorator { flickable: flick }

        Column {  // for proper positioning of the page header
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                property string _primary: defaultFor(settings['label'], "")
                property string _secondary: {
                    if (clock.numericRelativeOffset < 0) {
                        qsTr("%1h behind", "shortened form of '%1 hour(s) behind local time'",
                             Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                    } else if (clock.numericRelativeOffset > 0) {
                        qsTr("%1h ahead", "shortened form of '%1 hour(s) ahead of local time'",
                             Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                    } else if (clock.numericRelativeOffset == 0) {
                        if (settings['label']) {
                            qsTr("local time zone")
                        } else {
                            qsTr("time")
                        }
                    } else {
                        ""
                    }
                }

                title: _primary ? _primary : _secondary
                description: _primary ? _secondary : qsTr("local time zone")
            }

            Item {  // for freedom to use any anchoring inside
                id: contentItem
                height: childrenRect.height
                width: parent.width

                AnalogClock {
                    id: clock
                    width: Math.min(root.height, root.width) * 0.75
                    height: width
                    clockFace: defaultFor(settings['clock_face'], 'plain')
                    utcOffsetSeconds: defaultFor(settings['utc_offset_seconds'], 0)
                    timezone: defaultFor(settings['timezone'], '')
                    timeFormat: defaultFor(settings['time_format'], 'local')

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: parent.top
                    }
                }

                C.DescriptionLabel {
                    id: digitalClock
                    label: clock.convertedTime.toLocaleString(Qt.locale(), app.timeFormat)
                    labelFont.pixelSize: Theme.fontSizeHuge

                    anchors {
                        top: clock.bottom
                        topMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                }

                Column {
                    anchors {
                        top: digitalClock.bottom
                        topMargin: Theme.paddingLarge
                        left: parent.left
                        right: parent.right
                    }

                    spacing: Theme.paddingMedium

                    DetailItem {
                        visible: clock.timeFormat == 'timezone'
                        label: qsTr("time zone")
                        value: {
                            "%1 / %2, %3".arg(
                                clock.timezoneInfo.area).arg(
                                clock.timezoneInfo.city).arg(
                                clock.timezoneInfo.country)
                        }
                    }

                    DetailItem {
                        visible: clock.numericRelativeOffset != 0
                        label: qsTr("local time")
                        value: clock.wallClock.time.toLocaleString(Qt.locale(), app.timeFormat)
                    }

                    DetailItem {
                        visible: clock.utcOffsetSeconds != 0
                        label: qsTr("offset from UTC")
                        value: qsTr("%1 hour(s)", "", Math.ceil((clock.utcOffsetSeconds / 60) % 60)).arg(clock.formattedUtcOffset)
                    }

                    DetailItem {
                        visible: clock.numericRelativeOffset != 0
                        label: qsTr("offset from local time")
                        value: {
                            if (clock.numericRelativeOffset < 0) {
                                qsTr("%1 hour(s) behind local time", "",
                                     Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                            } else if (clock.numericRelativeOffset > 0) {
                                qsTr("%1 hour(s) ahead of local time", "",
                                     Math.ceil(clock.numericRelativeOffset / 60)).arg(clock.formattedRelativeOffsetNoSign)
                            } else {
                                ""
                            }
                        }
                    }
                }
            }
        }
    }

    states: [
        // default is portrait, no separate state needed

        State {
            name: "landscape"
            when: orientation & Orientation.LandscapeMask

            AnchorChanges {
                target: clock
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    top: parent.top
                }
            }

            PropertyChanges {
                target: clock
                anchors.topMargin: 10//(Screen.width - clock.height) / 2
            }
        }
    ]
}
