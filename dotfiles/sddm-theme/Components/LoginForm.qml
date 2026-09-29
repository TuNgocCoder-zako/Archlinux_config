// Config created by Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme
// Copyright (C) 2022-2025 Keyitdev
// Based on https://github.com/MarianArlt/sddm-sugar-dark
// Distributed under the GPLv3+ License https://www.gnu.org/licenses/gpl-3.0.html

import QtQuick 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0 as SDDM

ColumnLayout {
    id: formContainer
    SDDM.TextConstants { id: textConstants }

    property int p: config.ScreenPadding == "" ? 0 : config.ScreenPadding
    property string a: config.FormPosition
    property bool isBottom: a === "bottom" || a === "bottom-center"

    spacing: isBottom ? 10 : 0

    Clock {
        id: clock

        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.preferredHeight: isBottom ? implicitHeight : root.height / 3
        Layout.leftMargin: (!isBottom && p != "0") ? a == "left" ? -p : a == "right" ? p : 0 : 0
    }

    Input {
        id: input

        Layout.alignment: Qt.AlignHCenter | (isBottom ? Qt.AlignTop : Qt.AlignVCenter)
        Layout.preferredHeight: isBottom ? implicitHeight : root.height / 10
        Layout.leftMargin: (!isBottom && p != "0") ? a == "left" ? -p : a == "right" ? p : 0 : 0
        Layout.topMargin: 0
    }

    SystemButtons {
        id: systemButtons

        visible: config.HideSystemButtons != "true"
        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.preferredHeight: (!visible || isBottom) ? (visible ? implicitHeight : 0) : root.height / 5
        Layout.maximumHeight: (!visible || isBottom) ? (visible ? implicitHeight : 0) : root.height / 5
        Layout.leftMargin: (!isBottom && p != "0") ? a == "left" ? -p : a == "right" ? p : 0 : 0

        exposedSession: input.exposeSession
    }

    SessionButton {
        id: sessionSelect

        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
        Layout.preferredHeight: isBottom ? implicitHeight : root.height / 54
        Layout.maximumHeight: isBottom ? implicitHeight : root.height / 54
        Layout.leftMargin: (!isBottom && p != "0") ? a == "left" ? -p : a == "right" ? p : 0 : 0
    }

    VirtualKeyboardButton {
        id: virtualKeyboardButton

        visible: config.HideVirtualKeyboard != "true"
        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: (!visible || isBottom) ? (visible ? implicitHeight : 0) : root.height / 27
        Layout.maximumHeight: (!visible || isBottom) ? (visible ? implicitHeight : 0) : root.height / 27
        Layout.leftMargin: (!isBottom && p != "0") ? a == "left" ? -p : a == "right" ? p : 0 : 0
    }
}
