/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "private"
import "../base"

DetailsPageBase {
    id: root

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: 20

            PageHeader { title: !!settings['label'] ? settings['label'] : "Details for clock #" + root.tile_id }

            Label { text: "Item 1" }
            Label { text: "Item 2" }
            Label { text: "Item 3" }
        }
    }
}
