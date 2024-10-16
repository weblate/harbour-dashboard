/*
 * This file is part of harbour-dashboard
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

    Component.onCompleted: {
        var xmlHttp = new XMLHttpRequest()

        // 'false' for synchronous request
        xmlHttp.open("GET", Qt.resolvedUrl("../tiles/tiles.json"), false);
        xmlHttp.send(null)

        var tiles = JSON.parse(xmlHttp.responseText)

        console.log(tiles)

        for (var i in tiles) {
            var comp = Qt.createComponent(
                Qt.resolvedUrl("../tiles/%1/Metadata.qml".arg(tiles[i])))
            tileTypesModel.append(comp.createObject(null))
        }
    }

    ListModel {
        id: tileTypesModel

//        ListElement {
//            title: qsTr("Pollen forecast")
//            description: qsTr("Forecast showing the intensity of pollen and other allergens.")
//            icon: "image://theme/icon-l-diagnostic"

//            type: "pollen"
//            requiresProvider: true
//            requiresConfig: true
//            implemented: false
//        }

//        ListElement {
//            title: qsTr("Natural hazards")
//            description: qsTr("List of current official warnings due to natural hazards.")
//            icon: "image://theme/icon-l-attention"

//            type: "hazards"
//            requiresProvider: true
//            requiresConfig: true
//            implemented: false
//        }
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

                opacity: enabled ? 1.0 : Theme.opacityLow

                onClicked: {
                    canAccept = true

                    if (model.requiresConfig) {
                        // Open the correct settings dialog to configure a new tile.
                        // This loads the "generic" settings dialog which is expected at
                        // qml/tiles/<type>/Settings.qml. Tiles that require a provider-specific
                        // settings dialog are handled above.

                        var settingsDialog = pageStack.push(Qt.resolvedUrl("../tiles/%1/Settings.qml".arg(model.type)), {
                            'objectName': model.type,
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
                    label: model.name
                    description: model.description

                    width: 1 // why is this necessary?!!
                    anchors {
                        left: iconBackground.right; leftMargin: Theme.paddingMedium
                        right: parent.right; rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }

                    labelFont.pixelSize: Theme.fontSizeMedium
                    descriptionFont.pixelSize: Theme.fontSizeExtraSmall

                    topLabelItem.wrapMode: Text.Wrap
                    topLabelItem.maximumLineCount: 1
                    topLabelItem.truncationMode: TruncationMode.Fade
                    bottomLabelItem.wrapMode: Text.Wrap
                    bottomLabelItem.maximumLineCount: 3
                    bottomLabelItem.truncationMode: TruncationMode.Elide
                }
            }
        }
    }
}
