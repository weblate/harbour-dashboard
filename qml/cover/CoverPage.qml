/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-FileCopyrightText: 2018-2022  Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

CoverBackground {
    id: coverPage

    ConfigurationGroup {
        id: config
        path: "/apps/harbour-forecasts"
        property int currentCoverIndex: 0
    }

    Label {
        id: label
        visible: app._coverTilesModel.count === 0
        anchors.centerIn: parent
        text: qsTr("Forecasts")
    }

    SlideshowView {
        id: slideshow
        visible: !label.visible
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom

            topMargin: -Theme.horizontalPageMargin
        }

        model: app._coverTilesModel
        currentIndex: config.currentCoverIndex
        itemWidth: parent.width
        itemHeight: parent.height //- Theme.horizontalPageMargin

        onCurrentIndexChanged: {
            config.currentCoverIndex = currentIndex
        }
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-previous"
            onTriggered: slideshow.decrementCurrentIndex()
        }
        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered: slideshow.incrementCurrentIndex()
        }
    }
}
