pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

Item {
    id: root

    required property PopoutState popouts
    property var model: popouts.dockModel

    property MprisPlayer player: {
        if (!model) return null;
        return Players.list.find(p => p.identity.toLowerCase().includes(model.appClass.toLowerCase()) || (model.id && p.identity.toLowerCase().includes(model.id.toLowerCase().replace(".desktop", "")))) || null;
    }

    implicitWidth: mainCard.implicitWidth
    implicitHeight: mainCard.implicitHeight

    StyledRect {
        id: mainCard

        anchors.centerIn: parent
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainer
        clip: true
        implicitWidth: cardContent.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: cardContent.implicitHeight + Tokens.padding.medium * 2

        ColumnLayout {
            id: cardContent

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            // App Name & Icon Row (macOS style tooltip)
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: Tokens.spacing.medium

                IconImage {
                    asynchronous: true
                    Layout.alignment: Qt.AlignVCenter
                    implicitSize: appTitle.implicitHeight
                    source: root.model ? Icons.getAppIcon(root.model.iconName, "image-missing") : ""
                }

                StyledText {
                    id: appTitle

                    Layout.alignment: Qt.AlignVCenter
                    text: {
                        if (!root.model) return "";
                        if (root.model.entry && root.model.entry.name) return root.model.entry.name;
                        return root.model.appClass || root.model.id || "";
                    }
                    font.pointSize: Tokens.font.body.medium.pointSize
                    font.bold: true
                    color: Colours.palette.m3onSurface
                }

                // Window count badge
                StyledRect {
                    visible: !!(root.model && root.model.toplevels && root.model.toplevels.length > 0)
                    radius: Tokens.rounding.full
                    color: Colours.palette.m3primary
                    implicitWidth: countText.implicitWidth + Tokens.padding.small
                    implicitHeight: countText.implicitHeight + 2

                    StyledText {
                        id: countText
                        anchors.centerIn: parent
                        text: (root.model && root.model.toplevels) ? root.model.toplevels.length.toString() : "0"
                        font.pointSize: Tokens.font.body.small.pointSize
                        color: Colours.palette.m3onPrimary
                    }
                }
            }

            // Media Controls (if Spotify or media player active)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small
                visible: !!root.player && !!(root.player.trackTitle || root.player.trackArtist)

                StyledText {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 220
                    text: root.player ? `${root.player.trackTitle || ""} - ${root.player.trackArtist || ""}` : ""
                    font.pointSize: Tokens.font.body.small.pointSize
                    color: Colours.palette.m3onSurfaceVariant
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Tokens.spacing.medium

                    Item {
                        implicitWidth: prevIcon.implicitHeight + Tokens.padding.small * 2
                        implicitHeight: prevIcon.implicitHeight + Tokens.padding.small * 2
                        visible: root.player ? root.player.canGoPrevious : false

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.small
                            onClicked: root.player.previous()
                        }

                        MaterialIcon {
                            id: prevIcon
                            anchors.centerIn: parent
                            text: "skip_previous"
                            fontStyle.pointSize: Tokens.font.body.medium.pointSize
                        }
                    }

                    Item {
                        implicitWidth: playIcon.implicitHeight + Tokens.padding.small * 2
                        implicitHeight: playIcon.implicitHeight + Tokens.padding.small * 2
                        visible: root.player ? root.player.canTogglePlaying : false

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.small
                            onClicked: root.player.togglePlaying()
                        }

                        MaterialIcon {
                            id: playIcon
                            anchors.centerIn: parent
                            text: (root.player && root.player.isPlaying) ? "pause" : "play_arrow"
                            fontStyle.pointSize: Tokens.font.body.large.pointSize
                        }
                    }

                    Item {
                        implicitWidth: nextIcon.implicitHeight + Tokens.padding.small * 2
                        implicitHeight: nextIcon.implicitHeight + Tokens.padding.small * 2
                        visible: root.player ? root.player.canGoNext : false

                        StateLayer {
                            anchors.fill: parent
                            radius: Tokens.rounding.small
                            onClicked: root.player.next()
                        }

                        MaterialIcon {
                            id: nextIcon
                            anchors.centerIn: parent
                            text: "skip_next"
                            fontStyle.pointSize: Tokens.font.body.medium.pointSize
                        }
                    }
                }
            }
        }
    }
}
