/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: AGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2021-2022  Mirian Margiani
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import "../components"

Page {
    id: root
    objectName: "MaintenancePage"

    signal finished
    onFinished: state = "done"

    property alias _statusText: statusLabel.text

    // block any navigation
    backNavigation: false
    forwardNavigation: false
    showNavigationIndicator: false

    SilicaFlickable {
        id: flick
        anchors.fill: parent

        Column {
            id: column
            readonly property bool _portrait: root.isPortrait

            y: Math.round(_portrait ? Screen.height/4 : Screen.width/4)
            spacing: Theme.paddingLarge
            width: parent.width

            BusyIndicator {
                id: busyIndicator
                opacity: running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator { duration: 400 } }
                running: true
                size: BusyIndicatorSize.Large
                anchors.horizontalCenter: parent.horizontalCenter
            }

            InfoLabel {
                id: titleLabel
                text: qsTr("Maintenance")
            }
        }

        HighlightImage {
            id: checkmark
            anchors {
                top: column.top
                horizontalCenter: column.horizontalCenter
            }

            width: busyIndicator.width
            height: width
            source: "image://theme/icon-l-acknowledge"

            opacity: busyIndicator.running ? 0.0 : 1.0
            Behavior on opacity { FadeAnimator { duration: 400 } }
        }

        Text {
            id: statusLabel
            anchors.top: column.bottom

            x: 3 * Theme.horizontalPageMargin
            width: parent.width - 2*x
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: Theme.secondaryHighlightColor
            opacity: Theme.opacityHigh

            font {
                pixelSize: Theme.fontSizeLarge
                family: Theme.fontFamilyHeading
            }
        }

        Text {
            id: hintLabel
            anchors {
                top: statusLabel.bottom
                topMargin: Theme.paddingLarge
            }

            x: 2 * Theme.horizontalPageMargin
            width: parent.width - 2*x
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeMedium

            opacity: Theme.opacityHigh
            Behavior on opacity { FadeAnimator { duration: 400 } }

            text: qsTr("Please be patient and allow up to 30 seconds for this.")
        }

        PulleyAnimationHint {
            flickable: flick
            width: parent.width - 2 * Theme.paddingLarge
            height: flickable ? flickable.height - 2 * Theme.paddingLarge : 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: - (__silica_applicationwindow_instance._rotatingItem.height/3 - height/2) + Theme.paddingLarge
        }

        PullDownMenu {
            id: pulley
            enabled: false
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator { duration: 400 } }

            MenuItem {
                text: qsTr("Close")
                onClicked: pageStack.pop()
            }
        }
    }

    states: [
        State {
            name: "done"
            PropertyChanges {
                target: busyIndicator
                running: false
            }
            PropertyChanges {
                target: hintLabel
                text: qsTr("Pull down to close this overlay.")
            }
            PropertyChanges {
                target: pulley
                enabled: true
            }
        }
    ]

    Component.onCompleted: {
        console.log("running database maintenance")

        app.registerBackendSignal(objectName, "info.main.database-maintenance.started", function(){
            _statusText = qsTr("Connected to the backend")
        })
        app.registerBackendSignal(objectName, "info.main.database-maintenance.status", function(args){
            if (args[2] === "clean-cache") {
                _statusText = qsTr('Cleaning caches for “%1”...').arg(args[3])
            } else if (args[2] === "vacuum") {
                _statusText = qsTr('Compressing databases for “%1”...').arg(args[3])
            }
        })
        app.registerBackendSignal(objectName, "info.main.database-maintenance.finished", function(){
            _statusText = qsTr("Maintenance is complete")
            app.unregisterBackendSignal(objectName, "info.main.database-maintenance.started")
            app.unregisterBackendSignal(objectName, "info.main.database-maintenance.status")
            app.unregisterBackendSignal(objectName, "info.main.database-maintenance.finished")
            root.finished()
        })

        app.runDatabaseMaintenance(objectName)
    }
}
