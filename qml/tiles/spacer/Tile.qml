/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../base"

ForecastTileBase {
    id: root
    objectName: "spacer"

    size: "small"
    allowResize: true
    allowRemove: true
    allowMove: true
    allowConfig: false

    editOnPressAndHold: true
    cancelEditOnClick: false

    showBackground: true
    menu: null

    Label {
        visible: editing
        anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }
        width: parent.width - 2 * Theme.paddingMedium
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
        text: qsTr("Placeholder")
    }
}
