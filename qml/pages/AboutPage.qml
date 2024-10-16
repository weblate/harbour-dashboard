/*
 * This file is part of harbour-dashboard.
 * SPDX-FileCopyrightText: 2018-2024 Mirian Margiani
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

/*
 * Translators:
 * Please add yourself to the list of translators in TRANSLATORS.json.
 * If your language is already in the list, add your name to the 'entries'
 * field. If you added a new translation, create a new section in the 'extra' list.
 *
 * Other contributors:
 * Please add yourself to the relevant list of contributors below.
 *
*/

import QtQuick 2.0
import Sailfish.Silica 1.0 as S
import Opal.About 1.0 as A

A.AboutPageBase {
    id: page

    appName: app.appName
    appIcon: Qt.resolvedUrl("../images/%1.png".arg(Qt.application.name))
    appVersion: APP_VERSION
    appRelease: APP_RELEASE

    allowDownloadingLicenses: true  // this app requires an internet connection anyway
    sourcesUrl: "https://github.com/ichthyosaurus/%1".arg(Qt.application.name)
    homepageUrl: "https://forum.sailfishos.org/t/apps-by-ichthyosaurus/15753"
    translationsUrl: "https://hosted.weblate.org/projects/%1".arg(Qt.application.name)
    changelogList: Qt.resolvedUrl("../Changelog.qml")
    licenses: A.License { spdxId: "GPL-3.0-or-later" }

    donations.text: donations.defaultTextCoffee
    donations.services: [
        A.DonationService {
            name: "Liberapay"
            url: "https://liberapay.com/ichthyosaurus"
        }
    ]

    description: qsTr("Everything at a glance.", "this app's motto")
    mainAttributions: ["2018-%1 Mirian Margiani".arg((new Date()).getFullYear())]
    autoAddOpalAttributions: true

    attributions: [
        A.Attribution {
            name: "python-dateutil (2.8.1)"
            entries: ["Gustavo Niemeyer", "Paul Ganssle"]
            homepage: "https://github.com/dateutil/dateutil"
            licenses: [
                A.License { spdxId: "Apache-2.0" },
                A.License { spdxId: "BSD-3-Clause" }
            ]
        },
        A.Attribution {
            name: "geopy (2.4.1)"
            entries: "Kostya Esmukov"
            homepage: "https://github.com/geopy/geopy"
            licenses: A.License { spdxId: "MIT" }
        },
        A.Attribution {
            name: "astral (1.2)"
            entries: "2009-2016 Simon Kennedy"
            homepage: "https://launchpad.net/astral"
            licenses: A.License { spdxId: "Apache-2.0" }
        },
        A.Attribution {
            name: "python-dateutil 2.8.1"
            entries: ["Gustavo Niemeyer", "Paul Ganssle"]
            homepage: "https://github.com/dateutil/dateutil"

            // TODO verify licenses
            licenses: [A.License { spdxId: "BSD" }, A.License { spdxId: "Apache" }]
        },
        A.Attribution {
            name: qsTr("Swiss meteorological data")
            entries: qsTr("MeteoSwiss")
            homepage: qsTr('https://www.meteoswiss.admin.ch/')
        },
        A.Attribution {
            name: qsTr("Norwegian meteorological data")
            entries: qsTr("MeteoSwiss")
            homepage: qsTr('https://yr.no/')
        },
        A.Attribution {
            name: qsTr("Weather icons")
            entries: "Zeix"
            homepage: "https://zeix.com/referenzen/meteoschweiz-redesign-wetterportal/"
        },
        A.Attribution {
            name: "QChart"
            entries: ["2014 Julien Wintz", qsTr("adapted by Mirian Margiani")]
            licenses: A.License { spdxId: "MIT" }
            // the original source code repository is no longer available
            homepage: "https://web.archive.org/web/20180611014447/https://github.com/jwintz/qchart.js"
        },
        A.Attribution {
            name: "SunCalc"
            entries: ["2011-2015  Vladimir Agafonkin", qsTr("adapted by Mirian Margiani")]
            licenses: A.License { spdxId: "BSD-2-Clause" }
            sources: "https://github.com/mourner/suncalc"
        },
        A.Attribution {
            name: qsTr("Coordinates calculator", "MeteoSwiss uses the Swiss local coordinate system that must be converted to global coordinates")
            entries: ["2013  Reto Hasler (ascii_ch)", qsTr("adapted by Mirian Margiani")]
            homepage: "https://asciich.ch/wordpress/koordinatenumrechner-schweiz-international/"
        },
        A.Attribution {
            name: "Whisperfish"
            entries: ["2016-2022 Ruben De Smet and contributors"]
            description: qsTr("Some modules have been adapted for use in this app.")
            licenses: A.License { spdxId: "AGPL-3.0-or-later" }
            sources: "https://gitlab.com/whisperfish/whisperfish"
            homepage: "https://forum.sailfishos.org/t/whisperfish-the-unofficial-sailfishos-signal-client/3337"
        },
        A.Attribution {
            name: "PyOtherSide"
            entries: ["2011, 2013-2020 Thomas Perl"]
            licenses: A.License { spdxId: "ISC" }
            sources: "https://github.com/thp/pyotherside"
            homepage: "https://thp.io/2011/pyotherside/"
        }
    ]

    contributionSections: [
        A.ContributionSection {
            title: qsTr("Development")
            groups: [
                A.ContributionGroup {
                    title: qsTr("Programming")
                    entries: ["Mirian Margiani"]
                },
                A.ContributionGroup {
                    title: qsTr("Weather icons")
                    entries: ["Zeix"]
                },
                A.ContributionGroup {
                    title: qsTr("Weather descriptions")
                    entries: ["MeteoSwiss"]
                }
            ]
        },
        //>>> GENERATED LIST OF TRANSLATION CREDITS
        A.ContributionSection {
            title: qsTr("Translations")
            groups: [
                A.ContributionGroup {
                    title: qsTr("Spanish")
                    entries: [
                        "gallegonovato"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("German")
                    entries: [
                        "Mirian Margiani"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("French")
                    entries: [
                        "Robin Grenet"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("English")
                    entries: [
                        "Mirian Margiani"
                    ]
                },
                A.ContributionGroup {
                    title: qsTr("Chinese")
                    entries: [
                        "dashinfantry"
                    ]
                }
            ]
        }
        //<<< GENERATED LIST OF TRANSLATION CREDITS
    ]
}
