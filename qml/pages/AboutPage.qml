/*
 * This file is part of Swiss Meteo.
 * SPDX-FileCopyrightText: 2022 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/*
 * Translators:
 * Please add yourself to the list of contributors below. If your language is already
 * in the list, add your name to the 'entries' field. If you added a new translation,
 * create a new section at the top of the list.
 *
 * Other contributors:
 * Please add yourself to the relevant list of contributors.
 *
 * <...>
 *  ContributionGroup {
 *      title: qsTr("Your language")
 *      entries: ["Existing contributor", "YOUR NAME HERE"]
 *  },
 * <...>
 *
 */

import QtQuick 2.0
import Opal.About 1.0

AboutPageBase {
    id: page
    appName: qsTr("Swiss Meteo", "the app's name")
    appIcon: Qt.resolvedUrl("../images/harbour-swissmeteo.png")
    appVersion: APP_VERSION
    appRelease: APP_RELEASE
    description: qsTr("An non-official client to the weather forecast services provided by the Federal Office of Meteorology and Climatology (MeteoSwiss).")
    mainAttributions: ["2018-2022 Mirian Margiani"]
    sourcesUrl: "https://github.com/ichthyosaurus/harbour-swissmeteo"
    homepageUrl: "https://openrepos.net/content/ichthyosaurus/swiss-meteo"
    allowDownloadingLicenses: true

    licenses: License { spdxId: "GPL-3.0-or-later" }
    attributions: [
        Attribution {
            name: qsTr("Meteorological data")
            entries: qsTr("MeteoSwiss")
            homepage: qsTr('https://www.meteoswiss.admin.ch/')
        },
        Attribution {
            name: qsTr("Weather icons")
            entries: "Zeix"
            homepage: "https://zeix.com/referenzen/meteoschweiz-redesign-wetterportal/"
        },
        Attribution {
            name: "QChart"
            entries: ["2014 Julien Wintz", qsTr("adapted by Mirian Margiani")]
            licenses: License { spdxId: "MIT" }
            // the original source code repository is no longer available
            homepage: "https://web.archive.org/web/20180611014447/https://github.com/jwintz/qchart.js"
        },
        Attribution {
            name: "SunCalc"
            entries: ["2011-2015  Vladimir Agafonkin", qsTr("adapted by Mirian Margiani")]
            licenses: License { spdxId: "BSD-2-Clause" }
            sources: "https://github.com/mourner/suncalc"
        },
        Attribution {
            name: qsTr("Coordinates calculator", "MeteoSwiss uses the Swiss local coordinate system that must be converted to global coordinates")
            entries: ["2013  Reto Hasler (ascii_ch)", qsTr("adapted by Mirian Margiani")]
            homepage: "https://asciich.ch/wordpress/koordinatenumrechner-schweiz-international/"
        },
        Attribution {
            name: "PyOtherSide"
            entries: ["2011, 2013-2020 Thomas Perl"]
            licenses: License { spdxId: "ISC" }
            sources: "https://github.com/thp/pyotherside"
            homepage: "https://thp.io/2011/pyotherside/"
        },
        OpalAboutAttribution { }
    ]

    contributionSections: [
        ContributionSection {
            title: qsTr("Development")
            groups: [
                ContributionGroup {
                    title: qsTr("Programming")
                    entries: ["Mirian Margiani"]
                }
            ]
        },
        ContributionSection {
            title: qsTr("Translations")
            groups: [
                ContributionGroup { title: qsTr("German"); entries: ["Mirian Margiani"]},
                ContributionGroup { title: qsTr("Chinese"); entries: ["dashinfantry"]}
            ]
        }
    ]

    extraSections: [
        InfoSection {
            title: qsTr("Data")
            text: qsTr("Copyright, Federal Office of Meteorology and Climatology MeteoSwiss.") + "\n" +
                  qsTr("Weather icons by Zeix.")
            buttons: InfoButton {
                text: qsTr("Website")
                onClicked: openOrCopyUrl(qsTr('https://www.meteoswiss.admin.ch/'))
            }
        }
    ]
}
