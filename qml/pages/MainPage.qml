/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: root
    allowedOrientations: Orientation.All

    property bool debug: false

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height
        flickableDirection: Flickable.VerticalFlick

        pullDownMenu: PullDownMenu {
            flickable: flickable
            enabled: opacity > 0.0
            opacity: flow.editing ? 0.0 : 1.0

            Behavior on opacity { FadeAnimation { } }

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }

            MenuItem {
                text: qsTr("Manage tiles")
                // onClicked: flow.edit()
                onDelayedClick: flow.edit()
            }

            MenuItem {
                visible: tilesModel.count > 0
                text: qsTr("Refresh")
                onClicked: {
                    // meteoApp.refreshData(undefined, false);
                }
            }
        }

        VerticalScrollDecorator { flickable: flickable }

        MouseArea {
            id: cancelEditArea
            anchors.fill: parent
            enabled: flow.editing
            onClicked: flow.cancelEdit()

            Rectangle {
                visible: debug
                anchors.fill: parent
                color: Theme.rgba("red", 0.3)
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: qsTr("Forecasts")
                description: app.haveWallClock ? app.wallClock.time.toLocaleString(Qt.locale(), app.dateTimeFormat) : ''
            }

            Flow {
                id: flow
                width: Math.ceil(parent.width - (parent.width%3 / 2))
                x: (parent.width%3 / 2)

                // Problem: when the Flow is created, there is an initial
                // "jumping" animation as if the contents move to their initial place.
                // This is ugly and should not happen as there is no "populate" transition.
                //
                 add: Transition {
                     NumberAnimation {
                         properties: "x,y"; easing.type: Easing.InOutQuad
                         duration: 75
                     }
                 }
                 move: add

                // ARCHITECTURE:
                //
                // Tiles can be 1/3, 2/3 or 3/3 wide. They are placed in a Flow element.
                // When editing, they can be moved around and new tiles can be added at any position.
                // There are different types of tiles: weather forecast, pollen forecast, dangers, etc.
                // Providers can provide specialised versions of a certain type of tiles.
                //

                property bool editing: true

                function edit() { flow.editing = true }
                function cancelEdit() { flow.editing = false }

                Repeater { model: tilesModel }
            }

            VerticalSpacing { }
        }
    }

    Component {
        id: tileComponent

        Tile {
            id: newTile
            debug: root.debug
            objectName: "new-tile"
            bindEditingTarget: flow
            dragProxyTarget: floatingTile
            cancelEditOnClick: false
            size: "small"

            menu: ContextMenu {
                MenuItem {
                    visible: newTile.allowConfig
                    text: qsTr("Configure")
                }
                MenuItem {
                    text: qsTr("Arrange tiles")
                    onDelayedClick: flow.edit()
                }
                MenuItem {
                    visible: newTile.allowRemove
                    text: qsTr("Remove")
                    onDelayedClick: newTile.requestRemoval()
                }
            }

            onRequestMove: {
                tilesModel.move(from, to)
            }
        }
    }

    Image {
        id: floatingTile
        property Tile sourceTile
        property TileActionButton dragHandle
        property SilicaFlickable flickable: flickable

        // hotspot bottom left, where the drag handle sits
        Drag.hotSpot.x: 0
        Drag.hotSpot.y: height
        Drag.active: dragHandle ? dragHandle.held : false
        Drag.source: sourceTile
    }

    ObjectModel {
        id: tilesModel

        function addDebugTile(name, size) {
            tilesModel.insert(tilesModel.count-1, tileComponent.createObject(tilesModel, {'objectName': name, 'size': size}))
        }

        Component.onCompleted: {
            addDebugTile('1', 'medium')
            addDebugTile('2', 'small')
            addDebugTile('3', 'small')
            addDebugTile('4', 'medium')
            addDebugTile('5', 'large')
        }

        Tile {
            debug: root.debug
            objectName: "addTile"
            size: "small"
            bindEditingTarget: flow
            editOnPressAndHold: false
            cancelEditOnClick: false

            allowResize: false
            allowRemove: false
            allowMove: false
            allowConfig: false

            HighlightImage {
                anchors.centerIn: parent
                source: "image://theme/icon-l-add"
            }

            onClicked: {
                tilesModel.addDebugTile(String(tilesModel.count), 'small')
                flickable.scrollToBottom()
            }
        }
    }

    MouseArea {
        id: cancelEditAreaBelow
        y: cancelEditArea.height
        height: root.height - cancelEditArea.height
        width: parent.width
        enabled: flow.editing
        onClicked: flow.cancelEdit()

        Rectangle {
            visible: debug
            anchors.fill: parent
            color: Theme.rgba("green", 0.3)
        }
    }
}
