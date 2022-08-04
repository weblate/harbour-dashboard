/*
 * This file has been adapted from Whisperfish for use in Forecasts for SailfishOS.
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021, 2022  Mirian Margiani
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

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
        readyToGo = true
        var stackAction = PageStackAction.Animated

        if (welcomeDelayTimer.running) stackAction = PageStackAction.Immediate

        if (action === "checkMaintenance") {
            checkMaintenance(stackAction)
        } else if (action === "showMain") {
            showMainPage(stackAction)
        }
    }

    function checkMaintenance(stackAction) {
        if (config.lastMaintenance === "2000-01-01") {
            // Don't run maintenance the very first time the app is started.
            config.lastMaintenance = (new Date()).toISOString()
            nextAction = "showMain"
            return
        }

        var prev = new Date(config.lastMaintenance)
        var now = new Date()
        var monthInMilliseconds = 1000 * 60 * 60 * 24 * 30

        if (prev.getTime() + 3*monthInMilliseconds < now.getTime()) {
            console.log("last database maintenance:", prev.toISOString(), "- today:", now.toISOString())

            var maintenancePage = pageStack.push(Qt.resolvedUrl("MaintenancePage.qml"), {}, stackAction)
            maintenancePage.finished.connect(function(){
                pageStack.pop()
                config.lastMaintenance = (new Date()).toISOString()
                root.nextAction = "showMain"
            })
        } else {
            nextAction = "showMain"
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

    ConfigurationGroup {
        id: config
        path: "/apps/harbour-forecasts"
        property string lastMaintenance: "2000-01-01"
    }

    Connections {
        target: app
        onInitReadyChanged: if (app.initReady >= 1) nextAction = "checkMaintenance"
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
            nextAction = "checkMaintenance"
        }
    }
}
