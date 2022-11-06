/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0

import "../components"
import "../tiles/common"

Page {
    id: root
    allowedOrientations: Orientation.All

    property bool debug: false

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick

        // This makes sure that the flickable fills the whole page.
        // That in turn ensures that a single MouseArea is enough to
        // catch all click/press-and-hold events to cancel/start editing.
        contentHeight: Math.max(column.height, root.height)

        pullDownMenu: PullDownMenu {
            flickable: flickable

            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
                visible: !flow.editing
            }

            MenuItem {
                text: qsTr("Manage tiles")
                onDelayedClick: flow.edit()
                visible: !flow.editing
            }

            MenuItem {
                // TODO enable only if there are tiles that support refreshing
                visible: tilesModel.count > 1 && !flow.editing
                text: qsTr("Refresh")
                onClicked: {
                    // meteoApp.refreshData(undefined, false);
                }
            }

            MenuItem {
                text: qsTr("Add a tile")
                visible: flow.editing
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("NewTileDialog.qml"),
                                   {'returnToPage': pageStack.currentPage})
                }
            }
        }

        VerticalScrollDecorator { flickable: flickable }

        MouseArea {
            id: cancelEditArea
            anchors.fill: parent
            onClicked: if (flow.editing) flow.cancelEdit()
            onPressAndHold: if (!flow.editing) flow.edit()

            Rectangle {
                visible: debug
                anchors.fill: parent
                color: Theme.rgba("red", 0.3)
            }
        }

        ViewPlaceholder {
            enabled: tilesModel.count <= 1 && !flow.editing && app.initReady >= 3
            text: qsTr("Add a tile")
            hintText: qsTr("Pull down to manage tiles")
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

                move: Transition {
                    enabled: flow.editing
                    NumberAnimation {
                        properties: "x,y"; easing.type: Easing.InOutQuad
                        duration: 75
                    }
                }

                // ARCHITECTURE:
                //
                // Tiles can be 1/3, 2/3 or 3/3 wide. They are placed in a Flow element.
                // When editing, they can be moved around and new tiles can be added at any position.
                // There are different types of tiles: weather forecast, pollen forecast, dangers, etc.
                // Providers can provide specialised versions of a certain type of tiles.
                //
                // Tile implementations are stored in the "tiles" directory:
                //      qml/
                //          tiles/
                //              base/
                //                  ForecastTileBase.qml        -- all tiles should derive from this component
                //                  private/
                //
                //              <tile-type>/                    -- all tiles of type <tile-type>, e.g. "weather"
                //                  private/
                //                  optional: Tile.qml          -- provider-independent implementation of the tile
                //                  optional: Settings.qml      -- provider-independent settings page for this tile
                //
                //                  <provider>/                 -- specific implementation of the tile for <provider>, e.g. "mch"
                //                      private/
                //                      Tile.qml                -- provider-dependent implementation of the tile,
                //                                                 could be based on <tile-type>/Tile.qml
                //                      Settings.qml            -- provider-specific settings page,
                //                                                 could be based on <tile-type>/Settings.qml

                property bool editing: false

                function edit() { flow.editing = true }
                function cancelEdit() { flow.editing = false }

                Repeater { model: tilesModel }
            }

            VerticalSpacing { }
        }
    }

    Component {
        id: tileComponent
        TileLoader {
            tilesViewModel: null
            debug: root.debug
        }
    }

    Image {
        id: floatingTile
        property var sourceTile
        property var dragHandle
        property SilicaFlickable flickable: flickable

        // hotspot bottom left, where the drag handle sits
        Drag.hotSpot.x: 0
        Drag.hotSpot.y: height
        Drag.active: dragHandle ? dragHandle.held : false
        Drag.source: sourceTile
    }

    ObjectModel {
        id: tilesModel

        function loadTile(parentModel, tile_type, size, settings, hideBackground) {
            var item = tileComponent.createObject(parentModel, { 'tilesViewModel': parentModel })
            parentModel.insert(Math.max(0, parentModel.count-1), item)
            item.load(tile_type, size, settings, hideBackground)
        }

        function insertTile(parentModel, tile_type, size, settings, index, hideBackground) {
            var item = tileComponent.createObject(parentModel, { 'tilesViewModel': parentModel })
            parentModel.insert(Math.max(0, index), item)
            item.load(tile_type, size, settings, hideBackground)
        }

        AddMoreTile {
            id: addMoreTile
            visible: editing
            debug: root.debug
            bindEditingTarget: flow
            dragProxyTarget: null
            tilesViewModel: tilesModel
        }

        Component.onCompleted: {
            app.initReady += 1
        }
    }

    Connections {
        target: app

        onInitReadyChanged: {
            if (app.initReady === 2) {
                // both the backend and the main page are ready
                app.loadTiles()
            }
        }

        onTilesLoaded: {
            for (var i in tiles) {
                console.log("- tile:", tiles[i].tile_id, tiles[i].tile_type, JSON.stringify(tiles[i].settings))
                tilesModel.loadTile(tilesModel, tiles[i].tile_type, tiles[i].size, tiles[i].settings)
                tilesModel.loadTile(_coverTilesModel, tiles[i].tile_type, 'small', tiles[i].settings, true)
            }

            console.log("all tiles loaded")
            initReady += 1

            // DEBUG
            // tilesModel.get(0).item.requestConfig()
            // addMoreTile.clicked(null)
            // tilesModel.get(0).item.clicked(null)
        }

        onTileAdded: {
            // arguments: tile_type, size, settings, tile_id, sequence
            console.log("new tile notification received:", tile_id, tile_type, size, sequence, JSON.stringify(settings))

            // insert the new tile at the end but right before the addMoreTile
            tilesModel.insertTile(tilesModel, tile_type, size, settings, tilesModel.count - 1)
            tilesModel.insertTile(_coverTilesModel, tile_type, 'small', settings, _coverTilesModel.count - 1, true)
        }
    }
}
