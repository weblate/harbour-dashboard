/*
 * This file is part of Forecasts for SailfishOS.
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2022  Mirian Margiani
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

import "private"
import "../base"
import "../../components" as C

SettingsDialogBase {
    id: root

    canAccept: true
    bakeSettings: function() {
        updatedSettings['time_format'] = clock.timeFormat

        if (clock.timeFormat == 'offset') {
            updatedSettings['utc_offset_seconds'] = clock.utcOffsetSeconds
        } else if (clock.timeFormat == 'timezone') {
            updatedSettings['timezone'] = clock.timezone
        }

        updatedSettings['label'] = labelField.text
        updatedSettings['clock_face'] = clock.clockFace
    }

    property string _initialTimeFormat: defaultFor(settings['time_format'], 'local')

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.paddingLarge

        AnalogClock {
            id: clock
            width: Math.max(timesColumn.height, Theme.itemSizeHuge)
            height: width
            clockFace: clockFaceCombo.currentItem.value
            utcOffsetSeconds: (timePicker.hour * 60 * 60 + timePicker.minute * 60) * (utcMinusSwitch.checked ? -1 : 1)
            timezone: defaultFor(settings['timezone'], '')
            timeFormat: {
                if (localTimeSwitch.checked) "local"
                else if (offsetSwitch.checked) "offset"
                else if (timezoneSwitch.checked) "timezone"
            }
        }

        Column {
            id: timesColumn
            spacing: Theme.paddingMedium

            C.DescriptionLabel {
                opacity: localTimeSwitch.checked ? Theme.opacityHigh : 1.0
                Behavior on opacity { FadeAnimator { } }
                description: qsTr("Clock time")
                label: clock.convertedTime.toLocaleString(Qt.locale(), app.timeFormat)
                inverted: true
                labelFont.pixelSize: Theme.fontSizeLarge
            }

            C.DescriptionLabel {
                opacity: !localTimeSwitch.checked ? Theme.opacityHigh : 1.0
                Behavior on opacity { FadeAnimator { } }
                label: clock.wallClock.time.toLocaleString(Qt.locale(), app.timeFormat)
                description: qsTr("Current time")
                inverted: true
                labelFont.pixelSize: Theme.fontSizeLarge
            }
        }
    }

    Item {
        width: parent.width
        height: Theme.paddingLarge
    }

    TextField {
        id: labelField
        property var cities: [qsTr("Tokyo, Japan"), qsTr("Nuuk, Greenland"),
            qsTr("Yangon, Myanmar"), qsTr("Lubumbashi, DR Congo"),
            qsTr("Belém, Brazil"), qsTr("Paris, France")]

        width: parent.width
        focus: !settings['label']  // only force focus for new clocks

        // We break the binding if the user changes the text manually.
        // Otherwise, the field will be set to the currently selected city/timezone automatically.
        text: !!settings['label'] ? settings['label'] : (timezoneSwitch.checked && clock.timezoneInfo ? clock.timezoneInfo.city : '')

        placeholderText: qsTr("e.g. %1").arg(cities[Math.floor(Math.random() * cities.length)])
        label: qsTr("Clock label (optional)")
        hideLabelOnEmptyField: false

        Connections {
            target: labelField._editor

            onEditingFinished: {  // intercept when the user actually edits the text field manually
                var text = labelField.text

                if (text === clock.timezoneInfo.city) {
                    return
                } else if (text === '' && !timezoneSwitch.checked) {
                    // restore the binding when the user manually clears the field
                    labelField.text = Qt.binding(function(){ return timezoneSwitch.checked && clock.timezoneInfo ? clock.timezoneInfo.city : '' })
                } else if (timezoneSwitch.checked && clock.timezoneInfo && text !== clock.timezoneInfo.city) {
                    labelField.text = labelField.text  // break the binding
                } else if (!timezoneSwitch.checked && text !== '') {
                    labelField.text = labelField.text  // break the binding
                }
            }
        }
    }

    ComboBox {
        id: clockFaceCombo
        label: qsTr("Clock face")
        currentIndex: 0

        menu: ContextMenu {
            MenuItem { property string value: "plain"; text: qsTr("without numbers") }
            MenuItem { property string value: "arabic"; text: qsTr("Arabic numbers (European)") }
            MenuItem { property string value: "roman"; text: qsTr("Roman numbers") }
        }

        Component.onCompleted: {
            if (defaultFor(settings['clock_face'], false)) {
                for (var i = 0; i < menu.children.length; i++) {
                    var child = menu.children[i]

                    if (child && child.visible && child.hasOwnProperty("value")
                            && child.value === settings['clock_face']) {
                        currentIndex = i
                        break
                    }
                }
            }
        }
    }

    TextSwitch {
        id: localTimeSwitch
        text: qsTr("Local time")
        description: qsTr("The clock will always show the current local time, " +
                          "using the same time zone as the system.")
        checked: _initialTimeFormat == "local"

        onCheckedChanged: {
            if (checked) {
                timezoneSwitch.checked = false
                offsetSwitch.checked = false
            } else if (!offsetSwitch.checked && !timezoneSwitch.checked) {
                checked = true  // prevent user from unchecking all
            }
        }
    }

    TextSwitch {
        id: timezoneSwitch
        text: qsTr("Time zone")
        description: qsTr("The clock will show the time in a specific time zone.")
        checked: _initialTimeFormat == "timezone"

        onCheckedChanged: {
            if (checked) {
                localTimeSwitch.checked = false
                offsetSwitch.checked = false
            } else if (!offsetSwitch.checked && !localTimeSwitch.checked) {
                checked = true  // prevent user from unchecking all
            }
        }
    }

    ValueButton {
        id: timezoneComboButton
        enabled: timezoneSwitch.checked
        label: qsTr("Time zone")
        value: clock.timezone === ""
               ? qsTr("Select a time zone")
               : qsTr("%1, %2 (%3)").arg(clock.timezoneInfo.city).arg(
                     clock.timezoneInfo.country).arg(clock.timezoneInfo.offsetWithDstOffset)

        onClicked: {
            // This uses the unstable/non-public API Sailfish.Timezone.
            // We cannot import the module directly due to Harbour restrictions
            // but we can simply push the page and hope for the best.
            // WARNING This might fail horribly some day.
            var page = pageStack.push("Sailfish.Timezone.TimezonePicker")
            page.timezoneClicked.connect(function(name){
                clock.timezone = name
                pageStack.pop()
            })
        }
    }

    TextSwitch {
        id: offsetSwitch
        text: qsTr("Custom time offset")
        description: qsTr("The clock will show the time shifted from UTC. " +
                          "This is independent of the local time zone.")
        checked: _initialTimeFormat == "offset"

        onCheckedChanged: {
            if (checked) {
                timezoneSwitch.checked = false
                localTimeSwitch.checked = false
            } else if (!timezoneSwitch.checked && !localTimeSwitch.checked) {
                checked = true  // prevent user from unchecking all
            }
        }
    }

    TextSwitch {
        id: utcPlusSwitch
        enabled: offsetSwitch.checked
        text: qsTr("UTC + %1").arg(timePicker.timeText)
        description: qsTr("Positive offsets show time zones east of UTC/GMT (Greenwich, UK).")
        checked: !settings['utc_offset_seconds'] || settings['utc_offset_seconds'] > 0

        onCheckedChanged: {
            if (checked) {
                utcMinusSwitch.checked = false
            } else if (!utcMinusSwitch.checked) {
                checked = true
            }
        }
    }

    TextSwitch {
        id: utcMinusSwitch
        enabled: offsetSwitch.checked
        text: qsTr("UTC - %1").arg(timePicker.timeText)
        description: qsTr("Negative offsets show time zones west of UTC/GMT (Greenwich, UK).")
        checked: !!settings['utc_offset_seconds'] && settings['utc_offset_seconds'] < 0

        onCheckedChanged: {
            if (checked) {
                utcPlusSwitch.checked = false
            } else if (!utcPlusSwitch.checked) {
                checked = true
            }
        }
    }

    Item {
        width: parent.width
        height: Theme.paddingLarge
    }

    TimePicker {
        id: timePicker
        enabled: offsetSwitch.checked
        opacity: enabled ? 1.0 : Theme.opacityLow
        anchors.horizontalCenter: parent.horizontalCenter

        hourMode: DateTime.TwentyFourHours
        hour: settings.hasOwnProperty('utc_offset_seconds') ? Math.abs(Math.floor(settings.utc_offset_seconds / 60 / 60)) : 0
        minute: settings.hasOwnProperty('utc_offset_seconds') ? Math.abs(Math.floor((settings.utc_offset_seconds / 60) % 60)) : 0

        C.DescriptionLabel {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            labelFont.pixelSize: Theme.fontSizeHuge
            descriptionFont.pixelSize: Theme.fontSizeLarge

            label: (utcMinusSwitch.checked ? qsTr("- %1") : qsTr("+ %1")).arg(timePicker.timeText)
            description: clock.convertedTime.toLocaleString(Qt.locale(), app.timeFormat)
        }
    }

    Item {
        width: parent.width
        height: Theme.horizontalPageMargin
    }
}
