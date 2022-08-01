/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0
import "../components"

ListItem {
    id: root
    width: 0
    height: 0
    highlightedColor: "transparent"
    _backgroundColor: "transparent"
    contentHeight: 0
    opacity: hidden ? 0.0 : 1.0

    property int _dragStartIndex: -1
    property int _dragLastHoverIndex: -1
    property var dragProxyTarget

    Behavior on width { SmoothedAnimation { duration: 150 } }
    Behavior on height {
        enabled: !menuOpen
        SmoothedAnimation { duration: 150 }
    }
    Behavior on opacity { FadeAnimation { } }

    readonly property int wThird: Math.floor(((orientation & Orientation.PortraitMask) ? Screen.width : Screen.height)/3)
    readonly property int fullHeight: 2.3 * Theme.itemSizeHuge
    readonly property int reducedHeight: 1.5 * Theme.itemSizeHuge

    property bool debug: false

    property alias size: sizeState.state
    property bool editing: false
    property bool hidden: false

    property bool allowResize: true
    property bool allowRemove: true
    property bool allowMove: true // TODO add button
    property bool allowConfig: true // TODO add button

    property bool editOnPressAndHold: !showMenuOnPressAndHold
    showMenuOnPressAndHold: !!menu

    property bool cancelEditOnClick: true
    property string bindEditingProperty: "editing"
    property var bindEditingTarget: null

    property bool _showingRemorser: false

    signal removed(var index)
    signal requestConfig
    signal requestMove(var from, var to)

    function requestRemoval() {
        // We have to create the remorse timer manually. See
        // comment on remorseContainer.

        var remorseItem = remorseComponent.createObject(remorseContainer)

        if (remorseItem) {
            _showingRemorser = true
            remorseItem.execute(remorseContainer, "Removed", removeSelf, 4000)
        } else if (remorseComponent) {
            console.warn("Failed to create RemorseItem", remorseComponent.errorString())
        }
    }

    function removeSelf() {
        hidden = true
        removed(root.ObjectModel.index)
    }

    default property alias _contents: contentItem.children

    Item {
        id: sizeState
        state: "small"

        states: [
            State {
                name: "small"
                PropertyChanges {
                    target: root
                    width: wThird
                    height: reducedHeight + (menuOpen ? menu.height : 0)
                    contentHeight: reducedHeight
                }
            },
            State {
                name: "medium"
                PropertyChanges {
                    target: root
                    width: 2 * wThird
                    height: reducedHeight + (menuOpen ? menu.height : 0)
                    contentHeight: reducedHeight
                }
            },
            State {
                name: "large"
                PropertyChanges {
                    target: root
                    width: 3 * wThird
                    height: fullHeight + (menuOpen ? menu.height : 0)
                    contentHeight: fullHeight
                }
            }
        ]
    }

    Item {
        id: editState
        state: editing ? "edit" : "view"

        states: [
            State {
                name: "view"
                PropertyChanges { target: contentScale; xScale: 1.0; yScale: 1.0 }
                PropertyChanges { target: growButton; scale: 0.0 }
                PropertyChanges { target: shrinkButton; scale: 0.0 }
                PropertyChanges { target: removeButton; scale: 0.0 }
                PropertyChanges { target: moveButton; scale: 0.0 }
                PropertyChanges { target: configButton; scale: 0.0 }
            },
            State {
                name: "edit"
                PropertyChanges {
                    target: contentScale
                    xScale: (width - 2 * Theme.paddingMedium) / width
                    yScale: (height - 2 * Theme.paddingMedium) / height
                }
                PropertyChanges { target: growButton; scale: 1.0 }
                PropertyChanges { target: shrinkButton; scale: 1.0 }
                PropertyChanges { target: removeButton; scale: 1.0 }
                PropertyChanges { target: moveButton; scale: 1.0 }
                PropertyChanges { target: configButton; scale: 1.0 }
            }
        ]
    }

    SilicaItem {
        id: contentItem
        anchors.fill: parent

        transform: Scale {
            id: contentScale
            xScale: 1.0
            yScale: 1.0

            origin.x: width / 2
            origin.y: height / 2

            Behavior on xScale { SmoothedAnimation { velocity: 1.3 } }
            // Behavior on yScale { SmoothedAnimation { velocity: 1.3 } }
        }

        SilicaItem {
            id: background
            anchors.fill: parent

            SilicaItem {
                anchors.fill: parent
                clip: true

                Rectangle {
                    visible: debug
                    anchors.fill: parent
                    border.color: "orange"
                    color: "transparent"
                }

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
    }

    TileActionButton {
        id: removeButton
        visible: allowRemove && !_showingRemorser
        icon.source: "image://theme/icon-m-cancel"

        anchors {
            top: contentItem.top; topMargin: Theme.paddingMedium
            left: contentItem.left; leftMargin: Theme.paddingMedium
        }

        onClicked: requestRemoval()
    }

    TileActionButton {
        id: configButton
        visible: allowConfig && !_showingRemorser
        icon.source: "image://theme/icon-m-edit" + (highlighted ? '-selected' : '')

        anchors {
            top: contentItem.top; topMargin: Theme.paddingMedium
            right: contentItem.right; rightMargin: Theme.paddingMedium
        }

        onClicked: requestConfig()
    }

    TileActionButton {
        id: moveButton
        visible: allowMove && !_showingRemorser
        icon.source: "image://theme/icon-m-menu"

        anchors {
            bottom: parent.bottom; bottomMargin: Theme.paddingMedium
            left: parent.left; leftMargin: Theme.paddingMedium
        }

        drag.target: dragProxyTarget
        property bool dragActive: drag.active

        onHeldChanged: {
            if (held) {
                dragProxyTarget.sourceTile = root
                _dragStartIndex = root.ObjectModel.index
                dragProxyTarget.visible = false
                dragProxyTarget.dragHandle = moveButton
                dragProxyTarget.x = root.x + root.parent.x - dragProxyTarget.flickable.contentX
                dragProxyTarget.y = root.y + root.parent.y - dragProxyTarget.flickable.contentY
            }
        }

        onDragActiveChanged: {
            if (dragActive) {
                root.grabToImage(function(result){
                    dragProxyTarget.source = result.url
                    dragProxyTarget.visible = true
                    moveButton.parent = dragProxyTarget
                    root.visible = false
                })
            } else {
                requestMove(_dragStartIndex, _dragLastHoverIndex)
                moveButton.parent = root
                dragProxyTarget.visible = false
                root.visible = true
            }
        }
    }

    TileActionButton {
        id: growButton
        visible: allowResize && !_showingRemorser
        icon.source: "image://theme/icon-m-forward"
        opacity: size == "large" ? 0.0 : 1.0

        anchors {
            bottom: contentItem.bottom; bottomMargin: Theme.paddingMedium
            right: contentItem.right; rightMargin: Theme.paddingMedium
        }

        onClicked: {
            if (size == "small") size = "medium"
            else if (size == "medium") size = "large"
        }
    }

    TileActionButton {
        id: shrinkButton
        visible: allowResize && !_showingRemorser
        icon.source: "image://theme/icon-m-back"
        opacity: size == "small" ? 0.0 : 1.0

        anchors {
            bottom: growButton.bottom
            right: growButton.left; rightMargin: Theme.paddingMedium
        }

        onClicked: {
            if (size == "large") size = "medium"
            else if (size == "medium") size = "small"
        }

        states: State {
            when: growButton.opacity == 0.0
            AnchorChanges {
                target: shrinkButton
                anchors.right: contentItem.right
            }
            PropertyChanges {
                target: shrinkButton
                anchors.rightMargin: Theme.paddingMedium
            }
        }
    }

    SilicaItem {
        id: debugItem
        anchors.fill: parent
        visible: debug

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: palette.errorColor
        }

        Label {
            id: debugLabel
            text: root.objectName
            color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: Theme.paddingSmall
                topMargin: Theme.paddingSmall
            }
        }
    }

    Item {
        id: remorseContainer
        anchors.fill: parent

        // We have to include this manually in a *container* because
        // the Remorse.itemAction() helper breaks the Flow layouting.

        Component {
            id: remorseComponent
            RemorseItem  {
                onCanceled: _showingRemorser = false
                onTriggered: _showingRemorser = false
            }
        }
    }

    Binding {
        id: editBinding
        target: root
        property: "editing"
        value: bindEditingTarget[bindEditingProperty]
        when:    !!bindEditingTarget
              && !!bindEditingProperty
              && bindEditingTarget.hasOwnProperty(bindEditingProperty)
    }

    DropArea {
        enabled: allowMove

        anchors {
            left: parent.left
            top: parent.top; bottom: parent.bottom
        }
        onContainsDragChanged: console.log(containsDrag)
        width: parent.width / 2
        onEntered: drag.source._dragLastHoverIndex = root.ObjectModel.index

        Rectangle {
            id: leftDropHighlight
            anchors.fill: parent
            anchors.margins: Theme.paddingMedium
            radius: 6
            visible: parent.containsDrag && !moveButton.held
            color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
        }

        OpacityRampEffect{
            sourceItem: leftDropHighlight
            direction: OpacityRamp.LeftToRight
        }
    }

    DropArea {
        enabled: allowMove

        anchors {
            right: parent.right
            top: parent.top; bottom: parent.bottom
        }
        onContainsDragChanged: console.log(containsDrag)
        width: parent.width / 2
        onEntered: drag.source._dragLastHoverIndex = root.ObjectModel.index + 1

        Rectangle {
            id: rightDropHighlight
            anchors.fill: parent
            anchors.margins: Theme.paddingMedium
            radius: 6
            visible: parent.containsDrag && !moveButton.held
            color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
        }

        OpacityRampEffect{
            sourceItem: rightDropHighlight
            direction: OpacityRamp.RightToLeft
        }
    }

    Rectangle {
        id: dragHoverHighlight
        visible: false
        anchors.fill: parent
        color: Theme.rgba(Theme.highlightColor, Theme.opacityLow)
    }

    onClicked: {
        if (debug) {
            console.log("tile", root.objectName, "clicked")
        }

        if (cancelEditOnClick) {
            if (editBinding.when) {
                bindEditingTarget[bindEditingProperty] = false
            } else {
                editing = false
            }
        }
    }

    onPressAndHold: {
        if (debug) {
            console.log("tile", root.objectName, "pressed")
        }

        if (editOnPressAndHold) {
            if (editBinding.when) {
                bindEditingTarget[bindEditingProperty] = true
            } else {
                editing = true
            }
        }
    }
}
