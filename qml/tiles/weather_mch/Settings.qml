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

    property var selectedEntryDetails: settings

    canAccept: {
        if (locDescription.text) {
            /* no-op to make sure canAccept is updated
               when the description changes */
        }

        if (!!locName.text && (!!settings['key'] || !!selectedEntryDetails['key'])) {
            return true
        } else {
            return false
        }
    }

    bakeSettings: function() {
        updatedSettings['name'] = locName.text
        updatedSettings['alt_name'] = locDescription.text
        updatedSettings['key'] = selectedEntryDetails['key']
        updatedSettings['zip'] = selectedEntryDetails['zip']
        updatedSettings['kind'] = selectedEntryDetails['kind']
        updatedSettings['altitude'] = selectedEntryDetails['altitude']
        updatedSettings['latitude'] = formatNumber(selectedEntryDetails['latitude'])
        updatedSettings['longitude'] = formatNumber(selectedEntryDetails['longitude'])
    }

    Component.onCompleted: {
        if (!!settings['key'] || !!settings['name'] || !!settings['alt_name']) {
            root.state = 'edit'
        } else {
            root.state = 'search'
            searchField.forceActiveFocus()
        }
    }

    function formatNumber(num) {
        return Number(num).toLocaleString(Qt.locale("C"), 'f', 5)
    }

    function parseNumber(str) {
        return Number.fromLocaleString(Qt.locale("C"), str)
    }

    // -------------------------------------------------------------------------
    // PROVIDER HANDLING

    property int _seq_search_suggestions: -1

    function searchSuggestionsReceived(event, sequence, data) {
        if (sequence < _seq_search_suggestions) {
            return
        }

        suggestionsModel.clear()

        for (var i = 0; i < Math.min(100, data['count']); i++) {
            suggestionsModel.append(data['items'][i])
        }
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
        visible: buttonStandIn.active

        onClicked: {
            root.state = 'search'
        }

        SearchField {
            id: buttonStandIn
            enabled: false
            canHide: false
            active: false

            placeholderText: qsTr("Find a location")
            placeholderColor: skipButton.down ? Theme.highlightColor : Theme.primaryColor
            opacity: 1.0

            leftItem: Icon {
                source: "image://theme/icon-m-right"
                highlighted: skipButton.down
            }
        }
    }

    TextMetrics {
        id: zipMetrics
        font.pixelSize: Theme.fontSizeLarge
        text: "9999"
    }

    Repeater {
        id: suggestionsView
        visible: true
        width: parent.width

        model: ListModel {
            id: suggestionsModel
        }

        delegate: ListItem {
            id: item
            width: root.width
            contentHeight: Math.max(contentColumn.height + 2*Theme.paddingMedium,
                                    Theme.itemSizeSmall)
            visible: suggestionsView.visible

            onClicked: {
                locName.text = model.name
                locDescription.text = model.alt_name
                locZip.text = model.zip

                selectedEntryDetails = {
                    key: model.key,
                    zip: model.zip,
                    kind: model.kind,
                    altitude: model.altitude,
                    latitude: model.latitude,
                    longitude: model.longitude
                }

                root.state = 'edit'
            }

            Column {
                id: contentColumn
                anchors.centerIn: parent
                width: parent.width - 2*Theme.horizontalPageMargin
                spacing: Theme.paddingSmall

                Row {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Label {
                        width: zipMetrics.width
                        text: defaultFor(model.zip, '')
                        font.pixelSize: Theme.fontSizeLarge
                        palette.primaryColor: Theme.secondaryColor
                        palette.highlightColor: Theme.secondaryHighlightColor
                    }

                    Label {
                        width: parent.width - zipMetrics.width - parent.spacing
                        wrapMode: Text.Wrap
                        text: model.name
                        font.pixelSize: Theme.fontSizeLarge
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.paddingMedium

                    Item {
                        width: zipMetrics.width
                        height: 1
                    }

                    Flow {
                        width: parent.width - zipMetrics.width - parent.spacing
                        spacing: Theme.paddingSmall

                        Label {
                            text: model.kind + " ·"
                            font.pixelSize: Theme.fontSizeSmall
                            palette.primaryColor: Theme.secondaryColor
                            palette.highlightColor: Theme.secondaryHighlightColor
                        }

                        Label {
                            text: model.alt_name !== model.name ?
                                      model.alt_name.replace(model.name, '').
                                          replace(/(, ,)|(, $)|(^, )/, '') + " ·" :
                                      qsTr("%1 m").arg(model.altitude)
                            font.pixelSize: Theme.fontSizeSmall
                            palette.primaryColor: Theme.secondaryColor
                            palette.highlightColor: Theme.secondaryHighlightColor
                        }

                        Label {
                            visible: model.alt_name !== model.name
                            text: qsTr("%1 m").arg(model.altitude)
                            font.pixelSize: Theme.fontSizeSmall
                            palette.primaryColor: Theme.secondaryColor
                            palette.highlightColor: Theme.secondaryHighlightColor
                        }
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
            text: defaultFor(settings['alt_name'], '')

            width: parent.width
            label: qsTr("Description")
            description: qsTr("The full name or other details about the location")
        }

        TextField {
            id: locZip
            text: defaultFor(settings['zip'], '')
            width: parent.width
            label: qsTr("Zip code")
            enabled: false
            visible: text !== ''
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
            PropertyChanges { target: suggestionsView;
                /*maximumVisibleHeight*/ height: 0; opacity: 0; clip: true }
            PropertyChanges { target: buttonStandIn; active: true; focus: false }
            PropertyChanges { target: searchField; active: false; focus: false }
        }
    ]

    transitions: [
        Transition {
            from: "search"; to: "edit"

            SequentialAnimation {
                PropertyAction { target: detailsColumn; property: "visible"; value: true }
                NumberAnimation {
                    target: detailsColumn; duration: 200;
                    easing.type: Easing.InOutQuad; properties: "opacity,height" }

                NumberAnimation { target: suggestionsView; duration: 200;
                    easing.type: Easing.InOutQuad; properties: "opacity,height" }
                PropertyAction { target: suggestionsView; property: "visible"; value: false }
            }
        },

        Transition {
            from: "edit"; to: "search"

            SequentialAnimation {
                NumberAnimation { target: detailsColumn; duration: 200;
                    easing.type: Easing.InOutQuad; properties: "opacity,height" }
                PropertyAction { target: detailsColumn; property: "visible"; value: false }

                PropertyAction { target: suggestionsView; property: "visible"; value: true }
                NumberAnimation { target: suggestionsView; duration: 200;
                    easing.type: Easing.InOutQuad; properties: "opacity,height" }

                ScriptAction { script: searchField.forceActiveFocus() }
            }
        }
    ]
}
