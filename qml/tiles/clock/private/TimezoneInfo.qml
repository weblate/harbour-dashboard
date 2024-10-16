/*
 * This file is part of harbour-dashboard
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

pragma Singleton
import QtQuick 2.6
import QtQml.Models 2.2
import Sailfish.Silica 1.0

// The *TimezoneModel* (from Sailfish.Timezone) is not documented and the API
// is not public. It is possible to take a look at the model's methods:
//
// for(var it in timezoneProxyModel.model) {
//     console.log(it + " = " + timezoneProxyModel.model[it])
// }
//
// However, it is not possible to access items directly.
// This is why we need the DelegateModel as a proxy (see findTimezoneInfo()
// for how to access items).
//
// From the code at </usr/lib>/qt5/qml/Sailfish/Timezone/ and from strings
// in libsailfishtimezoneplugin.so, we can glean the following properties:
//
// model.name                 -- "Pacific/Pago_Pago"
//       area                 -- "Pacific"
//       city                 -- "Rarotonga"
//       country              -- "Cook Islands"
//       offset               -- "UTC+1:00"
//       offsetWithDstOffset  -- "UTC+1:00 (+2:00)"
//       currentOffset        -- "UTC+2:00"
//       sectionOffset        -- "UTC+1:00"
//       filter               -- ?

QtObject {
    property DelegateModel _proxyModel: DelegateModel {
        id: timezoneProxyModel
        delegate: Item { visible: false }

        // Avoid hard dependencies on unstable/non-public APIs and load
        // them in a convoluted way to make Jolla's validator script happy.
        //
        // WARNING This might fail horribly some day.
        model: Qt.createQmlObject("
                import QtQuick 2.0
                import %1 1.0
                TimezoneModel { }
            ".arg("Sailfish.Timezone"), timezoneProxyModel, 'TimezoneInfo')
    }

    function findTimezoneInfo(queryName) {
        if (timezoneProxyModel.model === null) {
            console.log("cannot lookup timezone info for %1: model is not yet ready".arg(queryName))
            return null
        }

        var count = timezoneProxyModel.model.count
        var items = timezoneProxyModel.items

        for (var i = 0; i < count; i++) {
            var item = items.get(i).model

            if (String(item.name) == String(queryName)) {
                console.log("found timezone info for", queryName, "->", item.city, item.offsetWithDstOffset)
                return item
            }
        }

        console.log("could not find timezone info for", queryName)
        return null
    }
}
