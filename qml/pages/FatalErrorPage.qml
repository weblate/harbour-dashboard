/*
 * This file has been adapted from Whisperfish for use in harbour-dashboard.
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021, 2022  Mirian Margiani
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

BlockingInfoPageBase {
    id: root
    property string errorMessage

    mainTitle: qsTr("Error", "fatal error message page title")
    mainDescription: errorMessage

    detailedDescription: qsTr("Please restart the app. If the problem persists and appears " +
                              "to be a flaw in this app, please report the issue.",
                              "generic hint on what to do after a fatal error occurred" +
                              "(error message will be shown separately)")
    iconSource: "image://theme/icon-l-attention"
    pageTitle: ""

    Component.onCompleted: {
        console.error("[FATAL] error occurred: " + errorMessage)
    }
}
