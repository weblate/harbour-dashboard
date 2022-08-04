/*
 * This file has been adapted from Whisperfish for use in Forecasts for SailfishOS.
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021, 2022  Mirian Margiani
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

BlockingInfoPageBase {
    id: root
    objectName: "MaintenancePage"

    signal finished

    busy: true
    mainTitle: qsTr("Database maintenance", "maintenance page title")
    mainDescription: qsTr("Connecting to the backend...")

    detailedDescription: qsTr("Please be patient and allow up to 30 seconds for this.")
    iconSource: ""  // "image://theme/icon-l-date"
    pageTitle: ""

    Timer {
        id: minimumRunTimer
        running: true

        // Database maintenance is only performed once every few months.
        // It should be fine to let the user wait a few seconds to let
        // them see what's going on, and to prevent the page from flickering.
        interval: 5000
    }

    Component.onCompleted: {
        console.log("running database maintenance")

        app.registerBackendSignal(objectName, "info.main.database-maintenance.started", function(){
            mainDescription = qsTr("Connected to the backend")
        })
        app.registerBackendSignal(objectName, "info.main.database-maintenance.status", function(args){
            if (args[2] === "clean-cache") {
                mainDescription = qsTr('Cleaning caches for "%1"...').arg(args[3])
            } else if (args[2] === "vacuum") {
                mainDescription = qsTr('Compressing databases for "%1"...').arg(args[3])
            }
        })
        app.registerBackendSignal(objectName, "info.main.database-maintenance.finished", function(){
            mainDescription = qsTr("Maintenance is complete")
            app.unregisterBackendSignal(objectName, "info.main.database-maintenance.started")
            app.unregisterBackendSignal(objectName, "info.main.database-maintenance.status")
            app.unregisterBackendSignal(objectName, "info.main.database-maintenance.finished")

            if (minimumRunTimer.running) {
                minimumRunTimer.triggered.connect(function(){ root.finished() })
            }
        })

        app.runDatabaseMaintenance(objectName)
    }
}
