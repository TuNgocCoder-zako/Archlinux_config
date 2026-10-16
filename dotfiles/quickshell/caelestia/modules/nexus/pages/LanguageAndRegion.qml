import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    // Temperature units (index 0 = Celsius, 1 = Fahrenheit — matches Weather.formatTemp)
    readonly property list<MenuItem> tempItems: [
        MenuItem {
            text: "°C"
        },
        MenuItem {
            text: "°F"
        }
    ]

    // Clock format (index 0 = 24-hour, 1 = 12-hour — matches Time.useTwelveHourClock)
    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: qsTr("24-hour")
        },
        MenuItem {
            text: qsTr("12-hour")
        }
    ]

    // City preset items for weather
    readonly property list<MenuItem> cityPresetItems: [
        MenuItem {
            text: qsTr("Auto (IP Location)")
        },
        MenuItem {
            text: "Nha Trang"
        },
        MenuItem {
            text: "Ho Chi Minh City"
        },
        MenuItem {
            text: "Hanoi"
        },
        MenuItem {
            text: "Da Nang"
        },
        MenuItem {
            text: "Hai Phong"
        },
        MenuItem {
            text: "Can Tho"
        }
    ]

    function getCityActiveItem(): var {
        const cur = root.targetConfig.services.weatherLocation;
        if (!cur)
            return cityPresetItems[0];
        for (let i = 1; i < cityPresetItems.length; i++) {
            if (cityPresetItems[i].text.toLowerCase() === cur.toLowerCase())
                return cityPresetItems[i];
        }
        return null;
    }

    title: qsTr("Language & region")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Language
        SectionHeader {
            first: true
            text: qsTr("Language")
        }

        // Read-only: the shell follows the system locale (no in-shell translations yet)
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: localeLayout.implicitHeight + localeLayout.anchors.margins * 2

            RowLayout {
                id: localeLayout

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("System language")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Follows your system locale (%1)").arg(Qt.locale().name)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                StyledText {
                    text: Qt.locale().nativeLanguageName || Qt.locale().name
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }

        // Weather
        SectionHeader {
            text: qsTr("Weather")
        }

        InfoRow {
            first: true
            last: false
            icon: Weather.icon
            label: qsTr("Current weather")
            subtext: Weather.city ? Weather.city : qsTr("Detecting location...")
            value: Weather.cc ? `${Weather.temp} • ${Weather.description}` : qsTr("Loading...")
        }

        TextFieldRow {
            first: false
            last: false
            label: qsTr("Weather location")
            subtext: qsTr("Type city (e.g. Hanoi, Ho Chi Minh City, Da Nang) or leave empty for Auto")
            placeholderText: qsTr("Auto (IP location) or type city")
            configNode: root.targetConfig.services
            propertyName: "weatherLocation"
            value: root.targetConfig.services.weatherLocation ?? ""
            onEditingFinished: v => {
                const trimmed = v.trim();
                root.targetConfig.services.weatherLocation = trimmed;
                root.targetConfig.save();
                Weather.reload();
            }
        }

        SelectRow {
            first: false
            last: true
            label: qsTr("City presets")
            subtext: qsTr("Quickly switch between common cities")
            menuItems: root.cityPresetItems
            active: root.getCityActiveItem()
            onSelected: item => {
                if (root.cityPresetItems.indexOf(item) === 0) {
                    root.targetConfig.services.weatherLocation = "";
                } else {
                    root.targetConfig.services.weatherLocation = item.text;
                }
                root.targetConfig.save();
                Weather.reload();
            }
        }

        // Units
        SectionHeader {
            text: qsTr("Units")
        }

        SelectRow {
            first: true
            label: qsTr("Temperature")
            subtext: qsTr("Units for weather temperatures")
            configNode: root.targetConfig.services
            propertyName: "useFahrenheit"
            menuItems: root.tempItems
            active: root.tempItems[root.targetConfig.services.useFahrenheit ? 1 : 0]
            onSelected: item => {
                root.targetConfig.services.useFahrenheit = root.tempItems.indexOf(item) === 1;
                root.targetConfig.save();
            }
        }

        SelectRow {
            last: true
            label: qsTr("System temperatures")
            subtext: qsTr("Units for CPU and GPU temperatures")
            configNode: root.targetConfig.services
            propertyName: "useFahrenheitPerformance"
            menuItems: root.tempItems
            active: root.tempItems[root.targetConfig.services.useFahrenheitPerformance ? 1 : 0]
            onSelected: item => {
                root.targetConfig.services.useFahrenheitPerformance = root.tempItems.indexOf(item) === 1;
                root.targetConfig.save();
            }
        }

        // Time & date
        SectionHeader {
            text: qsTr("Time & date")
        }

        SelectRow {
            first: true
            last: true
            label: qsTr("Clock format")
            subtext: qsTr("How times are shown across the shell")
            configNode: root.targetConfig.services
            propertyName: "useTwelveHourClock"
            menuItems: root.clockItems
            active: root.clockItems[root.targetConfig.services.useTwelveHourClock ? 1 : 0]
            onSelected: item => {
                root.targetConfig.services.useTwelveHourClock = root.clockItems.indexOf(item) === 1;
                root.targetConfig.save();
            }
        }
    }
}
