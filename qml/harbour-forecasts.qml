/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2018-2020, 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import Nemo.Notifications 1.0
import io.thp.pyotherside 1.5

import "pages"

ApplicationWindow {
    id: app
    allowedOrientations: Orientation.All

    // We have to explicitly set the \c _defaultPageOrientations property
    // to \c Orientation.All so the page stack's default placeholder page
    // will be allowed to be in landscape mode. (The default value is
    // \c Orientation.Portrait.) Without this setting, pushing multiple pages
    // to the stack using \c animatorPush() while in landscape mode will cause
    // the view to rotate back and forth between orientations.
    // [as of 2021-02-17, SFOS 3.4.0.24, sailfishsilica-qt5 version 1.1.110.3-1.33.3.jolla]
    _defaultPageOrientations: Orientation.All

    initialPage: Component {
        MainPage {}
    }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    property string dateTimeFormat: qsTr("d MMM yyyy '('hh':'mm')'")
    property string timeFormat: qsTr("hh':'mm")
    property string fullDateFormat: qsTr("ddd d MMM yyyy")

    property string tempUnit: "°C"
    property string rainUnit: "mm/h"
    property string rainUnitShort: "mm"
    property string windUnit: "km/h"

    // MaintenanceOverlay {
    //     id: maintenanceOverlay
    //     text: qsTr("Database Maintenance")
    //     hintText: qsTr("Please be patient and allow up to 30 seconds for this.")
    // }
    //
    // MaintenanceOverlay {
    //     id: disableAppOverlay
    //     text: qsTr("Currently unusable")
    //     hintText: qsTr("This app is currently unusable, due to a change at the data provider's side.")
    // }

    Component.onCompleted: {
        // TODO implement a way to detect API breakage and enable the overlay automatically
        // disableAppOverlay.state = "visible";

        // if (Storage.dbNeedsMaintenance()) {
        //     maintenanceOverlay.state = "visible";
        //     Storage.doDatabaseMaintenance();
        //     maintenanceOverlay.state = "invisible";
        // }
    }
}
