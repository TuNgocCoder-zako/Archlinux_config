pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.modules.bar as Bar

Scope {
    id: root

    required property ShellScreen screen
    required property Bar.BarWrapper bar
    property var contentWindow: null

    Config.screen: screen.name

    readonly property ScreenState screenState: contentWindow ? contentWindow.screenState : ShellState.forScreen(root.screen)
    readonly property bool isSidebarOpen: (screenState && screenState.sidebar && Config.sidebar.enabled) || (contentWindow?.panels?.sidebar?.shouldBeActive ?? false)
    readonly property bool hasNotifs: (contentWindow?.panels?.notifications?.visible ?? false) && (contentWindow?.panels?.notifications?.height ?? 0) > 0

    readonly property int sidebarExclusiveWidth: Tokens.sizes.sidebar.width + Config.border.thickness + (GlobalConfig.appearance.islands ? Tokens.spacing.extraLarge : 0)

    ExclusionZone {
        anchors.left: true
        exclusiveZone: Config.bar.position === "left" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
        Config.screen: root.screen.name
    }

    ExclusionZone {
        anchors.top: true
        exclusiveZone: Config.bar.position === "top" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
        Config.screen: root.screen.name
    }

    ExclusionZone {
        anchors.right: true
        exclusiveZone: {
            if (Config.bar.position === "right") {
                return root.bar.exclusiveZone + (root.isSidebarOpen || root.hasNotifs ? root.sidebarExclusiveWidth : 0);
            }
            if (root.isSidebarOpen || root.hasNotifs) {
                return root.sidebarExclusiveWidth;
            }
            return contentItem.Config.border.thickness;
        }
        Config.screen: root.screen.name
    }

    ExclusionZone {
        anchors.bottom: true
        exclusiveZone: Config.bar.position === "bottom" ? root.bar.exclusiveZone : contentItem.Config.border.thickness
        Config.screen: root.screen.name
    }

    component ExclusionZone: StyledWindow {
        screen: root.screen
        name: "border-exclusion"
        exclusiveZone: contentItem.Config.border.thickness
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
        Config.screen: root.screen.name
    }
}
