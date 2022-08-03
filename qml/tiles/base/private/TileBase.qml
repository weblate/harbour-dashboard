/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0

ListItem {
    id: root
    width: 0
    height: 0
    highlightedColor: "transparent"
    _backgroundColor: "transparent"
    contentHeight: 0
    opacity: hidden ? 0.0 : 1.0
    highlighted: (down || menuOpen) && !editing

    property int objectIndex: -1
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
    property bool allowMove: true
    property bool allowConfig: true
    property bool showBackground: true

    property bool editOnPressAndHold: !openMenuOnPressAndHold
    openMenuOnPressAndHold: !!menu && !editing

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
        removed(objectIndex)
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
        enabled: !editing
        opacity: (!editing || (editing && (moveButton.held || root.down))) ? 1.0 : Theme.opacityFaint
        Behavior on opacity { FadeAnimator {} }

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
            visible: showBackground

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
                _dragStartIndex = objectIndex
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
                console.log("requesting to move tile", root, "from", _dragStartIndex, "to", _dragLastHoverIndex)
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

    Item {
        id: dropHint
        visible: false
        anchors {
            rightMargin: -Theme.paddingSmall
            right: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: Theme.paddingSmall

        Rectangle {
            anchors {
                top: parent.top
                bottom: dropIcon.top
                bottomMargin: Theme.paddingSmall
                horizontalCenter: parent.horizontalCenter
            }
            height: parent.height / 2 - dropIcon.height
            radius: 6
            width: Theme.paddingSmall * 0.5
            color: palette.primaryColor
        }

        Icon {
            id: dropIcon
            anchors {
                verticalCenter: parent.verticalCenter
                horizontalCenter: parent.horizontalCenter
            }
            source: "icon-s-drop.png"
        }

        Rectangle {
            anchors {
                top: dropIcon.bottom
                topMargin: Theme.paddingSmall
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
            height: parent.height / 2 - dropIcon.height
            radius: 6
            width: Theme.paddingSmall * 0.5
            color: palette.primaryColor
        }

        states: [
            State {
                name: "showLeft"
                when: leftDropArea.containsDrag && !moveButton.held
                PropertyChanges {
                    target: dropHint
                    visible: true
                }
            },
            State {
                name: "showRight"
                when: rightDropArea.containsDrag && !moveButton.held
                PropertyChanges {
                    target: dropHint
                    visible: true
                    anchors {
                        rightMargin: 0
                        leftMargin: -Theme.paddingSmall
                    }
                }
                AnchorChanges {
                    target: dropHint
                    anchors {
                        right: undefined
                        left: parent.right
                    }
                }
            }

        ]
    }

    DropArea {
        id: leftDropArea
        enabled: allowMove

        anchors {
            left: parent.left
            top: parent.top; bottom: parent.bottom
        }

        width: parent.width / 2
        onEntered: drag.source._dragLastHoverIndex = objectIndex
    }

    DropArea {
        id: rightDropArea
        enabled: allowMove

        anchors {
            right: parent.right
            top: parent.top; bottom: parent.bottom
        }

        width: parent.width / 2
        onEntered: drag.source._dragLastHoverIndex = objectIndex + 1
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
