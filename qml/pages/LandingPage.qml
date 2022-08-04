/*
 * This file has been adapted from Whisperfish for use in Forecasts for SailfishOS.
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021, 2022  Mirian Margiani
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: root
    property bool readyToGo: false
    property string nextAction: "none"

    function handleNextStep() {
        if (!readyToGo || nextAction == "none") {
            return
        }

        var action = nextAction
        readyToGo = false
        nextAction = "none"
        var stackAction = PageStackAction.Animated

        if (welcomeDelayTimer.running) stackAction = PageStackAction.Immediate

        if (action === "showMain") {
            showMainPage(stackAction)
        }
    }

    onNextActionChanged: handleNextStep()
    onStatusChanged: {
        if (status === PageStatus.Active) {
            pageStack.completeAnimation() // abort any running animation

            // we have to wait until this page is ready because
            // we can't push another page on the stack while the current
            // page is being built
            readyToGo = true
            handleNextStep()
        } else {
            readyToGo = false
        }
    }

    Connections {
        target: app
        onInitReadyChanged: if (app.initReady >= 1) nextAction = "showMain"
    }

    BusyLabel {
        id: waitingPlaceholder

        text: qsTr("Welcome", "welcome text shown when starting the app takes a long time")
        running: false
        opacity: running ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { } }
    }

    Timer {
        id: welcomeDelayTimer

        // Delay showing "Welcome". We should
        // already be on the next page when this is triggered -
        // but if not, we'll let the user see something.
        running: true
        interval: 500
        onTriggered: waitingPlaceholder.running = true
    }

    Component.onCompleted: {
        if (app.initReady >= 1) {
            nextAction = "showMain"
        }
    }
}
