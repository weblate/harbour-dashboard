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
                // TODO enable only if there are tiles that support refreshing
                visible: tilesModel.count > 1
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

        Loader {
            id: loader
            asynchronous: false
            source: ""

            onStatusChanged: {
                if (status == Loader.Error) {
                    setSource('../tiles/common/BrokenTile.qml', defaultProperties)
                    // console.error("failed to show tile:", JSON.stringify(defaultProperties))
                }
            }

            property var defaultProperties: ({
                'debug': Qt.binding(function(){ return root.debug }),
                'bindEditingTarget': flow,
                'bindEditingProperty': 'editing',
                'dragProxyTarget': floatingTile,
                'objectIndex': Qt.binding(function(){ return loader.ObjectModel.index }),
                'tilesViewModel': tilesModel
            })

            function load(tile_type, size, settings) {
                settings['tile_type'] = tile_type
                defaultProperties['tile_id'] = settings['tile_id']
                defaultProperties['size'] = size
                defaultProperties['settings'] = settings

                var source = "../tiles/%1/Tile.qml"

                if (settings.hasOwnProperty('provider_id')) {
                    source = source.arg(tile_type + '/' + settings.provider_id)
                } else {
                    source = source.arg(tile_type)
                }

                loader.setSource(source, defaultProperties)
                console.log("loading tile id", defaultProperties['tile_id'], "(", tile_type, ") using", source, JSON.stringify(settings))
            }
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

        function loadTile(tile_type, size, settings) {
            var item = tileComponent.createObject(tilesModel)
            tilesModel.insert(tilesModel.count-1, item)
            item.load(tile_type, size, settings)
        }

        function insertTile(tile_type, size, settings, index) {
            var item = tileComponent.createObject(tilesModel)
            tilesModel.insert(index, item)
            item.load(tile_type, size, settings)
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
                tilesModel.loadTile(tiles[i].tile_type, tiles[i].size, tiles[i].settings)
            }

            console.log("all tiles loaded")
            initReady += 1

            // DEBUG
            // tilesModel.get(0).item.requestConfig()
        }

        onTileAdded: {
            // arguments: tile_type, size, settings, tile_id, sequence
            console.log("new tile notification received:", tile_id, tile_type, size, sequence, JSON.stringify(settings))

            // insert the new tile at the end but right before the addMoreTile
            tilesModel.insertTile(tile_type, size, settings, tilesModel.count - 1)
        }
    }
}
