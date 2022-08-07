/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQml.Models 2.2

import "../components" as C

Dialog {
    id: root
    allowedOrientations: Orientation.All

    property Page returnToPage: null

    canAccept: false

    ListModel {
        id: tileTypesModel

        // TODO move this list in a separate file
        // TODO maybe load tile definitions from JSON?
        // TODO remove or polish descriptions; they are mostly not necessary at all

        ListElement {
            title: qsTr("World clock")
            description: qsTr("Clock showing local time or the current time in any time zone.")
            icon: "image://theme/icon-l-clock"

            type: "clock"
            requiresProvider: false
            requiresConfig: true
            implemented: true
        }

        ListElement {
            title: qsTr("Weather forecast")
            description: qsTr("Weather forecast showing graphs for the next few days.")
            icon: "image://theme/icon-l-weather-d400"

            type: "weather"
            requiresProvider: true
            requiresConfig: true
            implemented: false
        }

        ListElement {
            title: qsTr("Pollen forecast")
            description: qsTr("Forecast showing the intensity of pollen and other allergens.")
            icon: "image://theme/icon-l-diagnostic"

            type: "pollen"
            requiresProvider: true
            requiresConfig: true
            implemented: false
        }

        ListElement {
            title: qsTr("Natural hazards")
            description: qsTr("List of current official warnings due to natural hazards.")
            icon: "image://theme/icon-l-attention"

            type: "hazards"
            requiresProvider: true
            requiresConfig: true
            implemented: false
        }

        ListElement {
            title: qsTr("Sun times")
            description: qsTr("Current times of sunrise and nightfall.")
            icon: "image://theme/icon-l-timer"

            type: "suntimes"
            requiresProvider: false
            requiresConfig: true
            implemented: false
        }

        ListElement {
            title: qsTr("Spacer")
            description: qsTr("Empty tile for spacing.")
            icon: "image://theme/icon-l-dismiss"

            type: "spacer"
            requiresProvider: false
            requiresConfig: false
            implemented: true
        }
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: tileTypesModel

        VerticalScrollDecorator { flickable: list }

        header: DialogHeader {
            acceptText: qsTr("Add")
            cancelText: qsTr("Cancel")
            title: qsTr("Select a tile type")
        }

        delegate: Component {
            ListItem {
                id: item
                contentHeight: Theme.itemSizeExtraLarge

                // hidden: !model.implemented
                enabled: model.implemented
                opacity: enabled ? 1.0 : Theme.opacityLow

                onClicked: {
                    canAccept = true

                    if (model.requiresProvider) {
                        // Open the provider selection page for a new tile of type <type>.
                        // Configuring and actually saving the new tile is handled there.

                        // TODO implement

                        if (model.type === 'weather') {
                            // DEBUG
                            app.addTile(model.type, 'small', {
                                'provider_id': 'mch',
                                'location_id': '400100'
                            })
                        } else {
                            app.showFatalError("Adding tiles with providers is not yet implemented.")
                            console.error("adding tiles that require a provider is not yet implemented")
                            root.accept()
                        }
                    } else if (model.requiresConfig) {
                        // Open the correct settings dialog to configure a new tile.
                        // This loads the "generic" settings dialog which is expected at
                        // qml/tiles/<type>/Settings.qml. Tiles that require a provider-specific
                        // settings dialog are handled above.

                        var settingsDialog = pageStack.push(Qt.resolvedUrl("../tiles/%1/Settings.qml".arg(model.type)), {
                            'settings': {},
                            'debug': false,
                            'tile_id': -1,
                            'acceptDestination': root.returnToPage,
                            'acceptDestinationAction': PageStackAction.Pop
                        })
                        settingsDialog.accepted.connect(function() {
                            console.log("adding new tile of type", model.type)
                            app.addTile(model.type, 'small', settingsDialog.updatedSettings)
                        })
                    } else {
                        // Simply save the tile and wait for confirmation.
                        // The tile will be added to the view in the handler for app.tileAdded(...).
                        app.addTile(model.type, 'small', {})
                        root.accept()
                    }
                }

                SilicaItem {
                    id: iconBackground
                    height: item.contentHeight
                    width: height

                    SilicaItem {
                        anchors.fill: parent
                        clip: true

                        Rectangle {
                            width: parent.width * 2
                            height: parent.height * 2

                            transform: Rotation {
                                angle: 30
                                origin.x: 0; origin.y: 0
                            }

                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: Theme.rgba(root.highlighted ? palette.secondaryHighlightColor : palette.secondaryColor, 0.01)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Theme.rgba(root.highlighted ? palette.secondaryHighlightColor : palette.secondaryColor, 0.15)
                                }
                            }
                        }
                    }
                }

                HighlightImage {
                    anchors.centerIn: iconBackground
                    source: model.icon
                    width: iconBackground.width - 2 * Theme.paddingLarge
                    height: width
                }

                Item {
                    id: measureItemForLazyPeople
                    anchors {
                        left: iconBackground.right; leftMargin: Theme.paddingMedium
                        right: parent.right; rightMargin: Theme.horizontalPageMargin
                    }
                }

                C.DescriptionLabel {
                    label: model.title
                    description: model.description

                    width: 1 // why is this necessary?!!
                    anchors {
                        left: iconBackground.right; leftMargin: Theme.paddingMedium
                        right: parent.right; rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }

                    labelFont.pixelSize: Theme.fontSizeMedium
                    descriptionFont.pixelSize: Theme.fontSizeSmall

                    topLabelItem.wrapMode: Text.Wrap
                    topLabelItem.maximumLineCount: 1
                    topLabelItem.truncationMode: TruncationMode.Fade
                    bottomLabelItem.wrapMode: Text.Wrap
                    bottomLabelItem.maximumLineCount: 2
                    bottomLabelItem.truncationMode: TruncationMode.Elide
                }
            }
        }
    }
}
