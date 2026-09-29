import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Effects
import SddmComponents 2.0 as SDDM

Item {
    id: rootMinimal

    implicitWidth: mainColumn.implicitWidth
    implicitHeight: mainColumn.implicitHeight

    SDDM.TextConstants { id: textConstants }

    property bool loginFailed: false
    property string targetUser: (userModel && userModel.lastUser) ? userModel.lastUser : "tu"

    Column {
        id: mainColumn
        spacing: 12
        anchors.right: parent.right

        // 1. Clock (Ultra-clean, minimalist, right-aligned)
        Column {
            anchors.right: parent.right
            spacing: 2

            Text {
                id: timeLabel
                anchors.right: parent.right
                font.family: config.Font || "JetBrains Mono"
                font.pointSize: 26
                font.bold: true
                color: config.TimeTextColor || "#f0f4fc"
                renderType: Text.QtRendering
                text: new Date().toLocaleTimeString(Qt.locale(config.Locale), config.HourFormat == "long" ? Locale.LongFormat : config.HourFormat !== "" ? config.HourFormat : "HH:mm")
            }

            Text {
                id: dateLabel
                anchors.right: parent.right
                font.family: config.Font || "JetBrains Mono"
                font.pointSize: 11
                color: config.DateTextColor || "#a6b8db"
                opacity: 0.9
                renderType: Text.QtRendering
                text: new Date().toLocaleDateString(Qt.locale(config.Locale), config.DateFormat == "short" ? Locale.ShortFormat : config.DateFormat !== "" ? config.DateFormat : "dddd, d MMMM")
            }

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: {
                    timeLabel.text = new Date().toLocaleTimeString(Qt.locale(config.Locale), config.HourFormat == "long" ? Locale.LongFormat : config.HourFormat !== "" ? config.HourFormat : "HH:mm")
                    dateLabel.text = new Date().toLocaleDateString(Qt.locale(config.Locale), config.DateFormat == "short" ? Locale.ShortFormat : config.DateFormat !== "" ? config.DateFormat : "dddd, d MMMM")
                }
            }
        }

        // 2. User info + Password Pill + Avatar
        Row {
            anchors.right: parent.right
            spacing: 14
            layoutDirection: Qt.LeftToRight

            // Left side: User name badge + Translucent Password Pill + Error text
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                width: 230

                // Username translucent badge (right-aligned)
                Row {
                    anchors.right: parent.right
                    spacing: 6

                    Rectangle {
                        height: 24
                        width: userText.implicitWidth + 18
                        radius: 12
                        color: Qt.rgba(15/255, 18/30/255, 0.35)
                        border.width: 1
                        border.color: Qt.rgba(255/255, 255/255, 255/255, 0.18)

                        Text {
                            id: userText
                            anchors.centerIn: parent
                            text: targetUser
                            font.family: config.Font || "JetBrains Mono"
                            font.bold: true
                            font.pointSize: 11
                            color: "#f0f4fc"
                            renderType: Text.QtRendering
                        }
                    }
                }

                // Translucent Password pill input (Frosted Glass)
                Rectangle {
                    id: passwordPill
                    width: parent.width
                    height: 38
                    radius: 19
                    color: Qt.rgba(15/255, 18/30/255, 0.35)
                    border.width: 1
                    border.color: passwordInput.activeFocus ? "#89b4fa" : Qt.rgba(255/255, 255/255, 255/255, 0.22)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 4
                        spacing: 6

                        // Password icon (tinted light)
                        Button {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignVCenter
                            icon.source: Qt.resolvedUrl("../Assets/Password2.svg")
                            icon.color: Qt.rgba(205/255, 214/255, 244/255, 0.75)
                            icon.width: 16; icon.height: 16
                            background: Rectangle { color: "transparent" }
                            enabled: false
                        }

                        // Password input (white/light text)
                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            echoMode: TextInput.Password
                            font.pointSize: 12
                            font.bold: true
                            color: "#f0f4fc"
                            focus: true
                            selectByMouse: true
                            renderType: Text.QtRendering
                            onAccepted: doLogin()

                            Text {
                                text: config.TranslatePlaceholderPassword || "Password"
                                color: Qt.rgba(205/255, 214/255, 244/255, 0.5)
                                font.italic: true
                                font.pointSize: 11
                                visible: !passwordInput.text && !passwordInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Submit arrow button (translucent glass circle)
                        Rectangle {
                            id: submitBtn
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            Layout.alignment: Qt.AlignVCenter
                            radius: 15
                            color: submitMouse.containsMouse ? Qt.rgba(137/255, 180/255, 250/255, 0.6) : Qt.rgba(255/255, 255/255, 255/255, 0.15)
                            border.width: 1
                            border.color: submitMouse.containsMouse ? "#89b4fa" : Qt.rgba(255/255, 255/255, 255/255, 0.22)

                            Text {
                                anchors.centerIn: parent
                                text: "➔"
                                font.bold: true
                                font.pointSize: 13
                                color: submitMouse.containsMouse ? "#ffffff" : "#cdd6f4"
                            }

                            MouseArea {
                                id: submitMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: doLogin()
                            }
                        }
                    }
                }

                // Error text (if login failed)
                Text {
                    anchors.right: parent.right
                    font.pointSize: 10
                    font.italic: true
                    color: "#ff5555"
                    text: loginFailed ? (config.TranslateLoginFailedWarning || textConstants.loginFailed + "!") : ""
                    visible: loginFailed
                }
            }

            // Right side: Circular Avatar with glowing border
            Item {
                id: avatarItem
                width: 64
                height: 64
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: avatarMask
                    width: 58
                    height: 58
                    radius: 29
                    color: "black"
                    visible: false
                    layer.enabled: true
                }

                Image {
                    id: avatarImg
                    width: 58
                    height: 58
                    anchors.centerIn: parent
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    visible: false
                    source: "/usr/share/sddm/faces/" + targetUser + ".face.icon"
                    onStatusChanged: {
                        if (status == Image.Error) {
                            source = Qt.resolvedUrl("../Assets/User.svg")
                        }
                    }
                }

                MultiEffect {
                    anchors.centerIn: parent
                    width: 58
                    height: 58
                    source: avatarImg
                    maskEnabled: true
                    maskSource: avatarMask
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 62
                    height: 62
                    radius: 31
                    color: "transparent"
                    border.width: 2.5
                    border.color: Qt.rgba(137/255, 180/255, 250/255, 0.9)
                }
            }
        }

        // 3. Power and session buttons row (reboot, shutdown, suspend, session)
        Row {
            anchors.right: parent.right
            spacing: 8

            // Session selector
            ComboBox {
                id: sessionCombo
                height: 32
                width: 120
                model: sessionModel
                currentIndex: (sessionModel && sessionModel.lastIndex !== undefined) ? sessionModel.lastIndex : 0
                textRole: "name"

                delegate: ItemDelegate {
                    width: sessionCombo.width
                    contentItem: Text {
                        text: model.name
                        font.family: config.Font || "JetBrains Mono"
                        font.pointSize: 10
                        color: "#cdd6f4"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: highlighted ? "#313244" : "#181926"
                    }
                }

                contentItem: Text {
                    text: sessionCombo.displayText
                    font.family: config.Font || "JetBrains Mono"
                    font.pointSize: 10
                    color: "#cdd6f4"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: sessionCombo.hovered ? Qt.rgba(30/255, 34/50/255, 0.7) : Qt.rgba(15/255, 18/30/255, 0.45)
                    border.width: 1
                    border.color: sessionCombo.hovered ? "#89b4fa" : Qt.rgba(255/255, 255/255, 255/255, 0.18)
                    radius: 16
                }

                popup: Popup {
                    y: sessionCombo.height + 4
                    width: sessionCombo.width
                    implicitHeight: contentItem.implicitHeight
                    padding: 4

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: sessionCombo.popup.visible ? sessionCombo.delegateModel : null
                        currentIndex: sessionCombo.highlightedIndex
                    }

                    background: Rectangle {
                        color: "#181926"
                        radius: 10
                        border.color: Qt.rgba(180/255, 216/255, 1, 0.25)
                        border.width: 1
                    }
                }
            }

            // Suspend Button
            Button {
                id: suspBtn
                width: 32; height: 32
                hoverEnabled: true
                icon.source: Qt.resolvedUrl("../Assets/Suspend.svg")
                icon.color: hovered ? "#89b4fa" : "#cdd6f4"
                icon.width: 16; icon.height: 16
                display: AbstractButton.IconOnly

                background: Rectangle {
                    radius: 16
                    color: suspBtn.hovered ? Qt.rgba(30/255, 34/50/255, 0.7) : Qt.rgba(15/255, 18/30/255, 0.45)
                    border.width: 1
                    border.color: suspBtn.hovered ? "#89b4fa" : Qt.rgba(255/255, 255/255, 255/255, 0.18)
                }

                onClicked: sddm.suspend()

                ToolTip.visible: hovered
                ToolTip.text: config.TranslateSuspend || "Suspend"
                ToolTip.delay: 200
            }

            // Reboot Button
            Button {
                id: rebBtn
                width: 32; height: 32
                hoverEnabled: true
                icon.source: Qt.resolvedUrl("../Assets/Reboot.svg")
                icon.color: hovered ? "#a6e3a1" : "#cdd6f4"
                icon.width: 16; icon.height: 16
                display: AbstractButton.IconOnly

                background: Rectangle {
                    radius: 16
                    color: rebBtn.hovered ? Qt.rgba(30/255, 34/50/255, 0.7) : Qt.rgba(15/255, 18/30/255, 0.45)
                    border.width: 1
                    border.color: rebBtn.hovered ? "#a6e3a1" : Qt.rgba(255/255, 255/255, 255/255, 0.18)
                }

                onClicked: sddm.reboot()

                ToolTip.visible: hovered
                ToolTip.text: config.TranslateReboot || "Reboot"
                ToolTip.delay: 200
            }

            // Shutdown Button
            Button {
                id: shutBtn
                width: 32; height: 32
                hoverEnabled: true
                icon.source: Qt.resolvedUrl("../Assets/Shutdown.svg")
                icon.color: hovered ? "#f38ba8" : "#cdd6f4"
                icon.width: 16; icon.height: 16
                display: AbstractButton.IconOnly

                background: Rectangle {
                    radius: 16
                    color: shutBtn.hovered ? Qt.rgba(70/255, 30/255, 40/255, 0.75) : Qt.rgba(15/255, 18/30/255, 0.45)
                    border.width: 1
                    border.color: shutBtn.hovered ? "#f38ba8" : Qt.rgba(255/255, 255/255, 255/255, 0.18)
                }

                onClicked: sddm.powerOff()

                ToolTip.visible: hovered
                ToolTip.text: config.TranslateShutdown || "Shutdown"
                ToolTip.delay: 200
            }
        }
    }

    function doLogin() {
        sddm.login(targetUser, passwordInput.text, sessionCombo.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {}
        function onLoginFailed() {
            loginFailed = true
            passwordInput.selectAll()
            resetTimer.start()
        }
    }

    Timer {
        id: resetTimer
        interval: 2500
        onTriggered: loginFailed = false
        running: false
    }
}
