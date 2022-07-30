/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import "../components"

SilicaControl {
    id: root
    highlighted: area.containsPress
    width: 0
    height: 0
    opacity: hidden ? 0.0 : 1.0

    Behavior on width { SmoothedAnimation { duration: 500 } }
    Behavior on height { SmoothedAnimation { duration: 500 } }
    Behavior on opacity { FadeAnimation { } }

    property bool debug: false

    property alias size: sizeState.state
    property bool editing: false
    property bool hidden: false

    property bool allowResize: true
    property bool allowClose: true
    property bool allowMove: true // TODO add button
    property bool allowConfig: true // TODO add button

    property bool editOnPressAndHold: true
    property bool cancelEditOnClick: true
    property string bindEditingProperty: "editing"
    property var bindEditingTarget: null

    property bool _showingRemorser: false

    signal clicked(var mouse)
    signal pressAndHold(var mouse)
    signal removed

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
                    height: reducedHeight
                }
            },
            State {
                name: "medium"
                PropertyChanges {
                    target: root
                    width: 2 * wThird
                    height: reducedHeight
                }
            },
            State {
                name: "large"
                PropertyChanges {
                    target: root
                    width: 3 * wThird
                    height: fullHeight
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
            },
            State {
                name: "edit"
                PropertyChanges { target: contentItem; scale: 0.8 }
                PropertyChanges { target: growButton; scale: 1.0 }
                PropertyChanges { target: shrinkButton; scale: 1.0 }
                PropertyChanges { target: closeButton; scale: 1.0 }
            }
        ]
    }

    SilicaItem {
        id: contentItem
        anchors {
            left: parent.left; right: parent.right
            top: parent.top; bottom: parent.bottom
        }

        Behavior on scale { SmoothedAnimation { velocity: 1.3 } }

        SilicaItem {
            id: background
            anchors.fill: parent

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
    }

    MouseArea {
        id: area
        anchors.fill: parent
        onClicked: root.clicked(mouse)
        onPressAndHold: root.pressAndHold(mouse)
    }

    IconButton {
        id: growButton
        visible: allowResize && !_showingRemorser
        icon.source: "image://theme/icon-m-next"
        anchors {
            horizontalCenter: contentItem.right
            verticalCenter: contentItem.bottom
            verticalCenterOffset: ((contentItem.height * contentItem.scale) - contentItem.height) / 2
            horizontalCenterOffset: -Theme.paddingMedium + ((contentItem.width * contentItem.scale) - contentItem.width) / 2
        }

        opacity: size == "large" ? 0.0 : 1.0

        Behavior on opacity { FadeAnimation { } }
        Behavior on scale { SmoothedAnimation { velocity: 10 } }

        onClicked: {
            if (size == "small") size = "medium"
            else if (size == "medium") size = "large"
        }
    }

    IconButton {
        id: shrinkButton
        visible: allowResize && !_showingRemorser
        icon.source: "image://theme/icon-m-previous"
        anchors {
            right: growButton.left
            rightMargin: Theme.paddingSmall
            verticalCenter: growButton.verticalCenter
        }

        opacity: size == "small" ? 0.0 : 1.0

        Behavior on opacity { FadeAnimation { } }
        Behavior on scale { SmoothedAnimation { velocity: 10 } }

        onClicked: {
            if (size == "large") size = "medium"
            else if (size == "medium") size = "small"
        }
    }

    IconButton {
        id: closeButton
        visible: allowClose && !_showingRemorser
        icon.source: "image://theme/icon-m-clear"
        anchors {
            horizontalCenter: contentItem.left
            verticalCenter: contentItem.top
            verticalCenterOffset: - ((contentItem.height * contentItem.scale) - contentItem.height) / 2
            horizontalCenterOffset: Theme.paddingMedium + (contentItem.width - (contentItem.width * contentItem.scale)) / 2
        }
        icon.scale: 1.2

        Behavior on opacity { FadeAnimation { } }
        Behavior on scale { SmoothedAnimation { velocity: 10 } }

        onClicked: {
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
