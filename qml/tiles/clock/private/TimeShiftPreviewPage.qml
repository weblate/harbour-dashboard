/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../../base"

import "../../../components" as C

DetailsPageBase {
    id: root

    property Item pageHeaderItem
    property DetailsPageBase detailsItem

    property bool pickLocalCalculateRemote: true

    onPickLocalCalculateRemoteChanged: {
        if (pickLocalCalculateRemote) {
            picker.hour = localClock.wallClock.time.getHours()
            picker.minute = localClock.wallClock.time.getMinutes()
        } else {
            picker.hour = currentRemoteClock.convertedTime.getHours()
            picker.minute = currentRemoteClock.convertedTime.getMinutes()
        }
    }

    tile_id: detailsItem.tile_id
    settings: detailsItem.settings
    debug: detailsItem.debug
    allowRefresh: false
    allowConfig: false
    tile: detailsItem.tile

    SilicaFlickable {
        id: flick
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        contentHeight: Math.max(column.height, root.height)

        pullDownMenu: root.defaultPulleyMenu.createObject(flick)

        MenuItem {
            parent: flick.pullDownMenu._contentColumn
            text: qsTr("Reset to current time")
            onClicked: {
                if (pickLocalCalculateRemote) {
                    picker.hour = new Date().getHours()
                    picker.minute = new Date().getMinutes()
                } else {
                    picker.hour = currentRemoteClock.convertedTime.getHours()
                    picker.minute = currentRemoteClock.convertedTime.getMinutes()
                }
            }
        }

        pushUpMenu: PushUpMenu {
            flickable: flick
            MenuItem {
                TextSwitch {
                    checked: !pickLocalCalculateRemote
                    text: " "
                    highlighted: parent.highlighted
                    height: Theme.itemSizeSmall
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                }

                text: qsTr("Calculate local time")
                onClicked: pickLocalCalculateRemote = false
            }

            MenuItem {
                TextSwitch {
                    checked: pickLocalCalculateRemote
                    text: " "
                    highlighted: parent.highlighted
                    height: parent.height
                    width: height
                    anchors.verticalCenter: parent.verticalCenter
                }

                text: qsTr("Calculate remote time")
                onClicked: pickLocalCalculateRemote = true
            }
        }

        VerticalScrollDecorator { flickable: flick }

        Column {  // for proper positioning of the page header
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                id: proxiedHeader
                visible: true
                title: pageHeaderItem.title
                description: pageHeaderItem.description
            }

            Item {  // for freedom to use any anchoring inside
                id: contentItem
                height: childrenRect.height
                width: parent.width

                TimePicker {
                    id: picker
                    hour: new Date().getHours()
                    minute: new Date().getMinutes()
                    anchors.horizontalCenter: parent.horizontalCenter

                    width: Math.min(root.height, root.width) - 2 * Theme.horizontalPageMargin
                    height: width
                    _trackWidth: Theme.itemSizeExtraSmall

                    AnalogClock {
                        id: remoteClock
                        opacity: 1.0
                        width: picker.width
                               - 2 * (2 * picker._trackWidth) // outer track and inner track
                               - 2 * Theme.paddingMedium      // some padding around the clock face
                        height: width

                        manualBaseTime: picker.time
                        clockFace: defaultFor(settings['clock_face'], 'plain')
                        utcOffsetSeconds: defaultFor(settings['utc_offset_seconds'], 0)
                        timezone: defaultFor(settings['timezone'], '')
                        timeFormat: defaultFor(settings['time_format'], 'local')

                        anchors.centerIn: parent
                    }

                    AnalogClock {
                        id: currentRemoteClock
                        visible: false
                        utcOffsetSeconds: defaultFor(settings['utc_offset_seconds'], 0)
                        timezone: defaultFor(settings['timezone'], '')
                        timeFormat: defaultFor(settings['time_format'], 'local')
                    }

                    AnalogClock {
                        id: localClock
                        opacity: 0.0
                        anchors.fill: remoteClock

                        manualBaseTime: pickLocalCalculateRemote ? picker.time : remoteClock.reverseConvertedTime
                        clockFace: defaultFor(settings['clock_face'], 'plain')
                        utcOffsetSeconds: 0
                        timezone: ''
                        timeFormat: 'local'
                    }
                }

                Column {
                    id: detailsColumn
                    property int textAlignment: Text.AlignHCenter

                    anchors {
                        top: picker.bottom
                        topMargin: 2 * Theme.paddingLarge
                        left: parent.left
                        right: parent.right
                    }

                    spacing: Theme.paddingMedium

                    C.DescriptionLabel {
                        id: localDigital
                        topLabelColor: Theme.primaryColor
                        bottomLabelColor: Theme.secondaryColor

                        label: pickLocalCalculateRemote ?
                                   picker.time.toLocaleString(Qt.locale(), app.timeFormat) :
                                   remoteClock.reverseConvertedTime.toLocaleString(Qt.locale(), app.timeFormat)
                        labelFont.pixelSize: Theme.fontSizeHuge
                        description: pickLocalCalculateRemote ?
                                         qsTr("Local time", "as in 'here, versus over there'") :
                                         qsTr("Calculated local time", "as in 'here, versus over there'")

                        inverted: true
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: parent.textAlignment
                    }

                    C.DescriptionLabel {
                        id: remoteDigital
                        topLabelColor: Theme.highlightColor
                        bottomLabelColor: Theme.secondaryHighlightColor

                        label: pickLocalCalculateRemote ?
                                   remoteClock.convertedTime.toLocaleString(Qt.locale(), app.timeFormat) :
                                   picker.time.toLocaleString(Qt.locale(), app.timeFormat)
                        labelFont.pixelSize: Theme.fontSizeHuge
                        description: pickLocalCalculateRemote ?
                                         qsTr("Calculated remote time", "as in 'over there, versus here'") :
                                         qsTr("Remote time", "as in 'over there, versus here'")

                        inverted: false
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: parent.textAlignment
                    }

                    Item { width: 1; height: 1 }

                    C.DescriptionLabel {
                        id: landscapeHeader
                        visible: false
                        topLabelColor: Theme.highlightColor
                        bottomLabelColor: Theme.secondaryHighlightColor

                        label: pageHeaderItem.title
                        labelFont.pixelSize: Theme.fontSizeLarge
                        description: pageHeaderItem.description

                        inverted: false
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: parent.textAlignment
                    }
                }
            }
        }
    }

    Item {
        id: pickerStateContainer
        states: [
            // default is "pick local time, calculate remote time"

            State {
                name: "pick-remote"
                when: !pickLocalCalculateRemote

                PropertyChanges {
                    target: localDigital
                    topLabelColor: Theme.highlightColor
                    bottomLabelColor: Theme.secondaryHighlightColor
                }

                PropertyChanges {
                    target: remoteDigital
                    topLabelColor: Theme.primaryColor
                    bottomLabelColor: Theme.secondaryColor
                }

                PropertyChanges {
                    target: localClock
                    opacity: 1.0
                }

                PropertyChanges {
                    target: remoteClock
                    opacity: 0.0
                }
            }
        ]
    }

    states: [
        // default is portrait, no separate state needed

        State {
            name: "landscape"
            when: orientation & Orientation.LandscapeMask

            PropertyChanges {
                target: proxiedHeader
                visible: false
            }

            AnchorChanges {
                target: picker
                anchors {
                    left: parent.left
                    top: parent.top
                    horizontalCenter: undefined
                }
            }

            PropertyChanges {
                target: picker
                anchors {
                    leftMargin: Theme.horizontalPageMargin
                    topMargin: (Screen.width - picker.height) / 2
                }
            }

            AnchorChanges {
                target: detailsColumn
                anchors {
                    top: undefined
                    verticalCenter: picker.verticalCenter
                    left: picker.right
                    right: parent.right
                }
            }

            PropertyChanges {
                target: detailsColumn
                anchors {
                    topMargin: 0
                    leftMargin: 2 * Theme.paddingLarge
                }
                textAlignment: Text.AlignLeft
            }

            AnchorChanges {
                target: localDigital
                anchors {
                    horizontalCenter: undefined
                    left: parent.left
                }
            }

            AnchorChanges {
                target: remoteDigital
                anchors {
                    horizontalCenter: undefined
                    left: parent.left
                }
            }

            AnchorChanges {
                target: landscapeHeader
                anchors {
                    horizontalCenter: undefined
                    left: parent.left
                }
            }

            PropertyChanges {
                target: landscapeHeader
                visible: true
            }
        }
    ]
}
