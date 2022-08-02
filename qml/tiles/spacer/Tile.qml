/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "../base"

ForecastTileBase {
    id: root
    objectName: "BrokenTile"

    size: "small"
    allowResize: true
    allowRemove: true
    allowMove: true
    allowConfig: false

    editOnPressAndHold: false
    cancelEditOnClick: false

    showBackground: true

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
