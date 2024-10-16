/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022-2024  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "private"
import "../base"
import "../../components" as C

SettingsDialogBase {
    id: root

    canAccept: {
        if (!!locName.text && !!locLatitude.text
                && !!locLongitude.text && !!locTimezone.text) true
        else false
    }

    bakeSettings: function() {
        updatedSettings['name'] = locName.text
        updatedSettings['description'] = locDescription.text
        updatedSettings['latitude'] = parseNumber(locLatitude.text)
        updatedSettings['longitude'] = parseNumber(locLongitude.text)
        updatedSettings['timezone'] = locTimezone.text
    }

    Component.onCompleted: {
        if (!!settings['name'] || !!settings['latitude'] || !!settings['longitude']) {
            root.state = 'edit'
        } else {
            root.state = 'search'
            searchField.forceActiveFocus()
        }
    }

    function formatNumber(num) {
        return Number(num).toLocaleString(Qt.locale(), 'f', 5)
    }

    function parseNumber(str) {
        return Number.fromLocaleString(Qt.locale(), str)
    }

    function isValidCoordInput(str) {
        try {
            parseNumber(str)
            return true
        } catch(err) {
            return false
        }
    }

    function updateTimezone(latitude, longitude) {
        var data = {
            'latitude': latitude,
            'longitude': longitude
        }

        _seq_timezone += 1
        var seq = _seq_timezone
        sendProviderCommand('lookup-timezone', data, seq, function(e, rseq, data){
            if (rseq !== seq) return
            locTimezone.text = data['timezone']
        })
    }

    // -------------------------------------------------------------------------
    // PROVIDER HANDLING

    property int _seq_search_suggestions: -1
    property int _seq_timezone: -1

    function searchSuggestionsReceived(event, sequence, data) {
        if (sequence < _seq_search_suggestions) {
            return
        }

        suggestionsModel.clear()

        for (var i = 0; i < Math.min(100, data['count']); i++) {
            suggestionsModel.append(data['items'][i])
        }

        // cleanup: make sure the handler is not connected when the dialog closes
        // disconnectProviderSignal("result:get-search-suggestions")
    }

    // -------------------------------------------------------------------------
    // LOCATION SELECTION

    SearchField {
        id: searchField
        canHide: false
        placeholderText: qsTr("Find a location")

        EnterKey.onClicked: {
            _seq_search_suggestions += 1
            var data = {'query': searchField.text}
            sendProviderCommand('get-search-suggestions', data, _seq_search_suggestions, searchSuggestionsReceived)
            focus = false
        }
    }

    BackgroundItem {
        id: skipButton
        height: buttonStandIn.height
        width: parent.width

        onClicked: {
            if (root.state == 'edit') {
                root.state = 'search'
            } else {
                root.state = 'edit'
            }
        }

        SearchField {
            id: buttonStandIn
            enabled: false
            canHide: false
            placeholderText: searchField.active ?
                qsTr("Enter details manually") :
                qsTr("Find a location")
            placeholderColor: skipButton.down ? Theme.highlightColor : Theme.primaryColor
            opacity: 1.0

            leftItem: Icon {
                source: "image://theme/icon-m-right"
                highlighted: skipButton.down
            }
        }
    }

    ColumnView {
        id: suggestionsView
        width: parent.width
        itemHeight: Theme.itemSizeMedium
        maximumVisibleHeight: Screen.height
        visible: true

        model: ListModel {
            id: suggestionsModel
        }

        TextMetrics {
            id: metrics
            font.pixelSize: Theme.fontSizeSmall
            text: "999.9999 °Mm"
        }

        delegate: ListItem {
            id: item
            width: root.width
            contentHeight: Math.max(contentColumn.height + 2*Theme.paddingMedium,
                                    Theme.itemSizeSmall)

            onClicked: {
                updateTimezone(lat, lon)
                locName.text = model.address.split(',')[0]
                locDescription.text = model.address
                locLatitude.text = formatNumber(lat)
                locLongitude.text = formatNumber(lon)
                root.state = 'edit'
            }

            property double lat: model.latitude
            property double lon: model.longitude

            property string latS: (lat > 0 ? qsTr("%1 °N") : qsTr("%1 °S")).
                arg(formatNumber(Math.abs(lat)))
            property string lonS: (lon > 0 ? qsTr("%1 °E") : qsTr("%1 °W")).
                arg(formatNumber(Math.abs(lon)))

            Column {
                id: contentColumn
                anchors.centerIn: parent
                width: parent.width - 2*Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: model.address
                }

                Flow {
                    width: parent.width
                    spacing: Theme.paddingSmall

                    Label {
                        width: metrics.width
                        text: item.latS
                        palette.primaryColor: Theme.secondaryColor
                        palette.highlightColor: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignLeft
                    }

                    Label {
                        width: metrics.width
                        text: item.lonS
                        palette.primaryColor: Theme.secondaryColor
                        palette.highlightColor: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    Column {
        id: detailsColumn
        visible: false
        width: parent.width
        height: childrenRect.height

        SectionHeader {
            text: qsTr("Location details")
        }

        TextField {
            id: locName
            text: defaultFor(settings['name'], '')

            width: parent.width
            label: qsTr("Name")
            description: qsTr("A short nickname for this location")
        }

        TextArea {
            id: locDescription
            text: defaultFor(settings['description'], '')

            width: parent.width
            label: qsTr("Description")
            description: qsTr("The full address or other details about the location")
        }

        Row {
            spacing: Theme.paddingMedium
            width: parent.width

            TextField {
                id: locLatitude
                text: {
                    var s = settings['latitude']
                    if (defaultFor(s, null) === null) ''
                    else formatNumber(s)
                }

                width: parent.width / 2
                label: qsTr("Latitude")
                description: qsTr("> 0 is North, < 0 is South")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                acceptableInput: isValidCoordInput(text)
            }

            TextField {
                id: locLongitude
                text: {
                    var s = settings['longitude']
                    if (defaultFor(s, null) === null) ''
                    else formatNumber(s)
                }

                width: parent.width / 2
                label: qsTr("Longitude")
                description: qsTr("> 0 is East, < 0 is West")
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                acceptableInput: isValidCoordInput(text)
            }
        }

        TextField {
            id: locTimezone
            text: defaultFor(settings['timezone'], '')

            enabled: false
            width: parent.width
            label: qsTr("Timezone")
            description: qsTr("Local timezone for this location")
        }

        C.VerticalSpacing { height: Theme.paddingMedium }

        Button {
            text: qsTr("Lookup timezone")
            enabled: !!locLatitude.text && !!locLongitude.text
            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: updateTimezone(parseNumber(locLatitude.text),
                                      parseNumber(locLongitude.text))
        }
    }

    C.VerticalSpacing {
        height: Theme.horizontalPageMargin
    }

    state: "search"

    states: [
        State {
            name: "search"
            PropertyChanges { target: detailsColumn; height: 0; opacity: 0; clip: true }
        },
        State {
            name: "edit"
            PropertyChanges { target: suggestionsView; maximumVisibleHeight: 0; opacity: 0; clip: true }
            PropertyChanges { target: searchField; active: false; focus: false }
        }
    ]

    transitions: [
        Transition {
            from: "search"; to: "edit"

            SequentialAnimation {
                PropertyAction { target: detailsColumn; property: "visible"; value: true }
                NumberAnimation { target: detailsColumn; duration: 200; easing.type: Easing.InOutQuad; properties: "opacity,height" }

                NumberAnimation { target: suggestionsView; duration: 200; easing.type: Easing.InOutQuad; properties: "opacity,height" }
                PropertyAction { target: suggestionsView; property: "visible"; value: false }
            }
        },

        Transition {
            from: "edit"; to: "search"

            SequentialAnimation {
                NumberAnimation { target: detailsColumn; duration: 200; easing.type: Easing.InOutQuad; properties: "opacity,height" }
                PropertyAction { target: detailsColumn; property: "visible"; value: false }

                PropertyAction { target: suggestionsView; property: "visible"; value: true }
                NumberAnimation { target: suggestionsView; duration: 200; easing.type: Easing.InOutQuad; properties: "opacity,height" }

                ScriptAction { script: searchField.forceActiveFocus() }
            }
        }
    ]
}
