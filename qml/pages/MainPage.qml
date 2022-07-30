/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

Page {
    id: root
    allowedOrientations: Orientation.All

    readonly property int wThird: Math.floor(root.width/3)
    readonly property int fullHeight: 2.3 * Theme.itemSizeHuge
    readonly property int reducedHeight: 1.5 * Theme.itemSizeHuge

    property bool debug: false

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        flickableDirection: Flickable.VerticalFlick

        pullDownMenu: PullDownMenu {
            flickable: flickable

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }

            MenuItem {
                text: qsTr("Edit tiles")
                onClicked: flow.editing = true
                // onDelayedClick: flow.editing = true
            }

            MenuItem {
                text: qsTr("Refresh")
                // visible: locationsModel.count > 0
                onClicked: {
                    // meteoApp.refreshData(undefined, false);
                }
            }

            // Label {
            //     id: clockLabel
            //     text: new Date().toLocaleString(Qt.locale(), meteoApp.dateTimeFormat)
            //     color: Theme.highlightColor
            //     anchors.horizontalCenter: parent.horizontalCenter
            // }
        }

        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader { title: qsTr("Forecasts") }

            Flow {
                id: flow
                width: parent.width - (parent.width%3 / 2)
                x: (parent.width%3 / 2)

                // Problem: when the Flow is created, there is an initial
                // "jumping" animation as if the contents move to their initial place.
                // This is ugly and should not happen as there is no "populate" transition.
                //
                // add: Transition {
                //     NumberAnimation {
                //         properties: "x,y"; easing.type: Easing.OutBack
                //     }
                // }
                // move: add

                // ARCHITECTURE:
                //
                // Tiles can be 1/3, 2/3 or 3/3 wide. They are placed in a Flow element.
                // When editing, they can be moved around and new tiles can be added at any position.
                // There are different types of tiles: weather forecast, pollen forecast, dangers, etc.
                // Providers can provide specialised versions of a certain type of tiles.
                //

                property bool editing: false

                function edit() { flow.editing = true }
                function cancelEdit() { flow.editing = false }

                Tile {
                    debug: root.debug; objectName: "1"
                    bindEditingTarget: flow
                    size: "small"
                }

                Tile {
                    debug: root.debug; objectName: "2"
                    bindEditingTarget: flow
                    size: "small"
                }

                Tile {
                    debug: root.debug; objectName: "3"
                    bindEditingTarget: flow
                    size: "small"
                }

                Tile {
                    debug: root.debug; objectName: "4"
                    bindEditingTarget: flow
                    size: "small"
                }

                Tile {
                    debug: root.debug; objectName: "5"
                    bindEditingTarget: flow
                    size: "small"
                }

                Tile {
                    debug: root.debug; objectName: "addTile"
                    size: "small"
                    bindEditingTarget: flow

                    allowResize: false
                    allowClose: false
                    allowMove: false
                    allowConfig: false

                    HighlightImage {
                        anchors.centerIn: parent
                        source: "image://theme/icon-l-add"
                    }
                }

//                ViewPlaceholder {
//                    id: placeholder
//                    enabled: (locationsModel.count === 0 && Storage.getLocationsCount() === 0)
//                    text: qsTr("Add a location first")
//                    hintText: qsTr("Pull down to add items")
//                }
            }

            VerticalSpacing { }
        }
    }

    // TODO: find a way to intercept clicks outside of the Flow element and set flow.editing=false.
    // Problem: the MouseArea grabs all mouse input and breaks scrolling while editing
    //
    // MouseArea {
    //     width: flow.editing ? parent.width : 0
    //     height: flow.editing ? parent.height : 0
    //     propagateComposedEvents: true
    //     scrollGestureEnabled: false
    //     enabled: flow.editing
    //     onClicked: {
    //         if (mouse.y < flow.y || mouse.y > flow.y+flow.height || !flow.childAt(mouse.x, mouse.y)) {
    //
    //             console.log("=>", mouse.x, mouse.y, flow.childAt(mouse.x, mouse.y))
    //             flow.editing = false
    //         } else {
    //             mouse.accepted = false
    //         }
    //     }
    // }
}
