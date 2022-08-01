/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
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

    Behavior on width { SmoothedAnimation { duration: 200 } }
    Behavior on height {
        enabled: !menuOpen
        SmoothedAnimation { duration: 200 }
    }
    Behavior on opacity { FadeAnimation { } }

    property bool debug: false

    property alias size: sizeState.state
    property bool editing: false
    property bool hidden: false

    property bool allowResize: true
    property bool allowClose: true
    property bool allowMove: true // TODO add button
    property bool allowConfig: true // TODO add button

    property bool editOnPressAndHold: !showMenuOnPressAndHold
    showMenuOnPressAndHold: !!menu

    property bool cancelEditOnClick: true
    property string bindEditingProperty: "editing"
    property var bindEditingTarget: null

    property bool _showingRemorser: false

    signal removed
    signal requestConfig

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
        removed()
        destroy()
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
                PropertyChanges { target: contentItem; scale: 1.0 }
                PropertyChanges { target: growButton; scale: 0.0 }
                PropertyChanges { target: shrinkButton; scale: 0.0 }
                PropertyChanges { target: closeButton; scale: 0.0 }
                PropertyChanges { target: moveButton; scale: 0.0 }
                PropertyChanges { target: configButton; scale: 0.0 }
            },
            State {
                name: "edit"
                PropertyChanges { target: contentItem; scale: 0.8 }
                PropertyChanges { target: growButton; scale: 1.0 }
                PropertyChanges { target: shrinkButton; scale: 1.0 }
                PropertyChanges { target: closeButton; scale: 1.0 }
                PropertyChanges { target: moveButton; scale: 1.0 }
                PropertyChanges { target: configButton; scale: 1.0 }
            }
        ]
    }

    SilicaItem {
        id: contentItem
        anchors {
            left: parent.left; right: parent.right
            top: parent.top; bottom: parent.bottom
        }

        property real scaledWidth: width * scale
        property real scaledHeight: height * scale
        property real horizontalMargin: (width - scaledWidth) / 2
        property real verticalMargin: (height - scaledHeight) / 2

        Behavior on scale { SmoothedAnimation { velocity: 1.3 } }

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
        id: closeButton
        visible: allowClose && !_showingRemorser
        referenceItem: contentItem
        icon.source: "image://theme/icon-m-cancel"

        anchors {
            top: contentItem.top; topMargin: contentItem.verticalMargin
            left: contentItem.left; leftMargin: contentItem.horizontalMargin
        }

        onClicked: requestRemoval()
    }

    TileActionButton {
        id: configButton
        visible: allowConfig && !_showingRemorser
        referenceItem: contentItem
        icon.source: "image://theme/icon-m-edit" + (highlighted ? '-selected' : '')

        anchors {
            top: contentItem.top; topMargin: contentItem.verticalMargin
            right: contentItem.right; rightMargin: contentItem.horizontalMargin
        }

        onClicked: requestConfig()
    }

    TileActionButton {
        id: moveButton
        visible: allowMove && !_showingRemorser
        referenceItem: contentItem
        icon.source: "image://theme/icon-m-menu"

        anchors {
            bottom: contentItem.bottom; bottomMargin: contentItem.verticalMargin
            left: contentItem.left; leftMargin: contentItem.horizontalMargin
        }

        // onPressed:
    }

    TileActionButton {
        id: growButton
        visible: allowResize && !_showingRemorser
        referenceItem: contentItem
        icon.source: "image://theme/icon-m-forward"
        opacity: size == "large" ? 0.0 : 1.0

        anchors {
            bottom: contentItem.bottom; bottomMargin: contentItem.verticalMargin
            right: contentItem.right; rightMargin: contentItem.horizontalMargin
        }

        onClicked: {
            if (size == "small") size = "medium"
            else if (size == "medium") size = "large"
        }
    }

    TileActionButton {
        id: shrinkButton
        visible: allowResize && !_showingRemorser
        referenceItem: contentItem
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
                anchors.rightMargin: contentItem.horizontalMargin
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
        value: parent.editing
        when:    !!bindEditingTarget
              && !!bindEditingProperty
              && bindEditingTarget.hasOwnProperty(bindEditingProperty)
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
