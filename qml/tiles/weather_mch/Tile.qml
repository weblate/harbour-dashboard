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
    hasProvider: true

//    settingsDialog: Qt.resolvedUrl("Settings.qml")
//    detailsPage: Qt.resolvedUrl("Details.qml")

    size: "small"
    allowResize: true
    allowConfig: false
    allowRefresh: true





    Item {
        id: layoutStates
        state: root.size
//        states: [
//            // default layout is 'small' and doesn't need a separate state
//            State {
//                name: "medium"

//                AnchorChanges {
//                    target: clock
//                    anchors {
//                        horizontalCenter: undefined
//                        left: parent.left
//                        top: undefined
//                        verticalCenter: parent.verticalCenter
//                    }
//                }
//                PropertyChanges {
//                    target: clock
//                    anchors {
//                        leftMargin: Theme.paddingLarge
//                    }
//                    width: Math.min(parent.width / 2, parent.height) - Theme.paddingMedium - Theme.paddingLarge
//                    height: width
//                }

//                AnchorChanges {
//                    target: clockLabel
//                    anchors {
//                        horizontalCenter: undefined
//                        bottom: undefined
//                        verticalCenter: parent.verticalCenter
//                        right: parent.right
//                    }
//                }
//                PropertyChanges {
//                    target: clockLabel
//                    anchors {
//                        rightMargin: Theme.paddingLarge
//                        // can't use parent.height because it changes when the context menu is openend
//                        verticalCenterOffset: - ((clock.height + extraInfoLabel.height) / 2 - clock.height / 2)
//                    }
//                    horizontalAlignment: Text.AlignLeft
//                    width: parent.width / 2 - Theme.paddingMedium - Theme.paddingLarge
//                }

//                PropertyChanges {
//                    target: extraInfoLabel
//                    visible: true
//                    inverted: true
//                }
//            },
//            State {
//                name: "large"

//                AnchorChanges {
//                    target: clock
//                    anchors {
//                        horizontalCenter: undefined
//                        left: parent.left
//                        top: undefined
//                        verticalCenter: parent.verticalCenter
//                    }
//                }
//                PropertyChanges {
//                    target: clock
//                    anchors {
//                        leftMargin: Theme.paddingLarge
//                    }
//                    width: Math.min(parent.width / 2, parent.height) - Theme.paddingMedium - Theme.paddingLarge
//                    height: width
//                }

//                AnchorChanges {
//                    target: clockLabel
//                    anchors {
//                        horizontalCenter: undefined
//                        bottom: undefined
//                        verticalCenter: parent.verticalCenter
//                        right: parent.right
//                    }
//                }
//                PropertyChanges {
//                    target: clockLabel
//                    anchors {
//                        rightMargin: Theme.paddingLarge
//                        // can't use parent.height because it changes when the context menu is openend
//                        verticalCenterOffset: - ((clock.height + extraInfoLabel.height) / 2 - clock.height / 2)
//                    }
//                    horizontalAlignment: Text.AlignLeft
//                    width: parent.width / 2 - Theme.paddingMedium - Theme.paddingLarge
//                }

//                PropertyChanges {
//                    target: extraInfoLabel
//                    visible: true
//                }
//            }
//        ]
    }

//    onRequestRefresh: {
//        // _modelUpdateSequence += 1
//        var data = {'data-field': 42}
//        sendProviderCommand('test-command', data, _modelUpdateSequence + 1)
//        sendProviderCommand('test-command', data, _modelUpdateSequence + 2)
//        sendProviderCommand('test-command', data, _modelUpdateSequence + 3)
//        _modelUpdateSequence += 3
//    }

//    property int _modelUpdateSequence: -1
//    function testDataReceived(event, sequence, data) {
//        if (sequence < _modelUpdateSequence) {
//            console.log("OUTDATED PROVIDER RESULT DROPPED",
//                        event, sequence, JSON.stringify(data))
//        } else {
//            console.log("PROVIDER RESULT SIGNAL RECEIVED",
//                        event, sequence, JSON.stringify(data))
//        }
//    }

//    Label {
//        visible: editing
//        anchors {
//            verticalCenter: parent.verticalCenter
//            horizontalCenter: parent.horizontalCenter
//        }
//        width: parent.width - 2 * Theme.paddingMedium
//        horizontalAlignment: Text.AlignHCenter
//        wrapMode: Text.Wrap
//        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
//        text: qsTr("Weather (MeteoSwiss)")
//    }

//    Component.onCompleted: {
//        connectProviderSignal("test", testDataReceived)
//    }
}
