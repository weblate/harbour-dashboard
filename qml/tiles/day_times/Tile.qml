/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../base"
import "../../components" as C
import "private"

import "../../modules/qchart/"
import "../../modules/qchart/QChart.js" as Charts


ForecastTileBase {
    id: root
    objectName: "day_times"

    settingsDialog: Qt.resolvedUrl("Settings.qml")
    // detailsPage: Qt.resolvedUrl("Details.qml")

    size: "small"
    allowResize: true
    allowConfig: true
    allowRefresh: false

    onSettingsChanged: {
        var data = {
            'latitude': settings['latitude'],
            'longitude': settings['longitude'],
            'timezone': settings['timezone']
        }

        sendProviderCommand('get-times', data, 0, function(_, __, data){
            _times = data
        })
    }

    property var _times: ({})

    function _time(key) {
        return defaultFor(_times[key], '~')
    }

    Item {
        id: layoutStates
        state: root.size
        states: [
            // default layout is 'small' and doesn't need a separate state
            State {
                name: "medium"
                PropertyChanges { target: timesColumn; visible: false }
                PropertyChanges { target: morningColumn; visible: true }
                PropertyChanges { target: eveningColumn; visible: true }
            },
            State {
                name: "large"
                PropertyChanges { target: timesColumn; visible: false }

                AnchorChanges {
                    target: morningColumn
                    anchors {
                        top: undefined
                        bottom: parent.bottom
                    }
                }

                PropertyChanges {
                    target: morningColumn
                    visible: true
                    anchors.bottomMargin: Theme.paddingMedium
                    height: childrenRect.height
                }

                AnchorChanges {
                    target: eveningColumn
                    anchors {
                        top: undefined
                        bottom: parent.bottom
                    }
                }

                PropertyChanges {
                    target: eveningColumn
                    visible: true
                    anchors.bottomMargin: Theme.paddingMedium
                    height: childrenRect.height
                }

                PropertyChanges {
                    target: weekPreviewGraph
                    visible: true
                }

                PropertyChanges {
                    target: weekChartLoader
                    sourceComponent: weekChartComp
                }
            }
        ]
    }

    Label {
        id: titleLabel
        truncationMode: TruncationMode.Fade
        color: Theme.highlightColor
        text: settings['name']
        font.pixelSize: Theme.fontSizeLarge * 0.9
        width: parent.width - 3*Theme.paddingMedium

        anchors {
            top: parent.top
            left: parent.left
            margins: 1.5 * Theme.paddingMedium
        }
    }

    Column {
        id: timesColumn

        anchors {
            top: titleLabel.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: Theme.paddingMedium
        }

        AlignedDetailItem {
            alignment: Qt.AlignCenter
            label: qsTr("dawn")
            value: _time("dawn")
        }

        AlignedDetailItem {
            alignment: Qt.AlignCenter
            label: qsTr("sunrise")
            value: _time("sunrise")
        }

        AlignedDetailItem {
            alignment: Qt.AlignCenter
            label: qsTr("sunset")
            value: _time("sunset")
        }

        AlignedDetailItem {
            alignment: Qt.AlignCenter
            label: qsTr("dusk")
            value: _time("dusk")
        }
    }

    TextMetrics {
        id: timeLabelMetrics
        font.pixelSize: Theme.fontSizeMedium
        text: "00:00"
    }

    Column {
        id: morningColumn
        visible: false

        anchors {
            top: titleLabel.bottom
            left: parent.left
            right: parent.horizontalCenter
            bottom: parent.bottom
            margins: Theme.paddingMedium
            rightMargin: 0
        }

        property int alignedLabelValueWidth: timeLabelMetrics.width

        AlignedDetailItem {
            alignment: Qt.AlignRight
            label: qsTr("dawn")
            value: _time("dawn")
        }

        AlignedDetailItem {
            alignment: Qt.AlignRight
            label: qsTr("sunrise")
            value: _time("sunrise")
        }

        AlignedDetailItem {
            alignment: Qt.AlignRight
            label: qsTr("noon")
            value: _time("noon")
        }

        AlignedDetailItem {
            alignment: Qt.AlignRight
            label: qsTr("golden")
            value: _time("golden_hour_morning")
        }
    }

    Column {
        id: eveningColumn
        visible: false

        anchors {
            top: titleLabel.bottom
            left: parent.horizontalCenter
            right: parent.right
            bottom: parent.bottom
            margins: Theme.paddingMedium
            leftMargin: 0
        }

        property int alignedLabelValueWidth: timeLabelMetrics.width

        AlignedDetailItem {
            alignment: Qt.AlignLeft
            label: qsTr("dusk")
            value: _time("dusk")
        }

        AlignedDetailItem {
            alignment: Qt.AlignLeft
            label: qsTr("sunset")
            value: _time("sunset")
        }

        AlignedDetailItem {
            alignment: Qt.AlignLeft
            label: qsTr("zenith")  // TODO check why there are negative values
            value: defaultFor(_times["zenith"], null) === null ?
                "~" : (Number(_times["zenith"]).toLocaleString(Qt.locale(), 'f', 1) + '°')
        }

        AlignedDetailItem {
            alignment: Qt.AlignLeft
            label: qsTr("hour")
            value: _time("golden_hour_evening")
        }
    }

    Item {
        id: weekPreviewGraph
        visible: false

        anchors {
            top: titleLabel.bottom
            bottom: morningColumn.top
            right: parent.right
            left: parent.left
            margins: Theme.paddingMedium
        }

        Component {
            id: weekChartComp
            WeekChart {
                width: weekPreviewGraph.width
                height: weekPreviewGraph.height
                dataGetter: function(callback){
                    var data = {
                        'latitude': settings['latitude'],
                        'longitude': settings['longitude'],
                        'timezone': settings['timezone']
                    }
                    sendProviderCommand('get-year-preview', data, 0, callback)
                }
            }
        }

        Loader {
            id: weekChartLoader
            anchors.fill: parent
            sourceComponent: null
            asynchronous: true

            property var appState: Qt.application.state
            onAppStateChanged: {
                if (weekPreviewGraph.visible &&
                        Qt.application.state === Qt.ApplicationActive) {
                    console.log("refreshing charts...")
                    active = false
                    active = true
                }
            }
        }
    }

    Component.onCompleted: {
//        var data = {
//            'latitude': settings['latitude'],
//            'longitude': settings['longitude'],
//            'timezone': settings['timezone']
//        }

//        sendProviderCommand('get-times', data, 0, function(_, __, data){
//            _times = data
//        })
    }
}
