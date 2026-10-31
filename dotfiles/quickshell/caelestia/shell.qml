pragma ComponentBehavior: Bound

//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQml
import Quickshell
import Caelestia.Config
import qs.components.containers
import qs.utils
import qs.services
import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import QtQuick
import "modules/polkit"
import Quickshell.Services.SystemTray

ShellRoot {
    id: root

    settings.watchFiles: false

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    GSFLoader {}
    ServiceLoader {}

    Background {}
    DesktopLyricsOverlay {}

    Drawers {}
    AreaPicker {}
    Lock {
        id: lock
    }
    PolkitModule {}

    ConfigToasts {}
    Shortcuts {}

    Component.onCompleted: {
        Qt.callLater(() => {
            Weather.reload();
            PastafarianCalendar.reload();
        });
    }
    BatteryMonitor {}
    IdleMonitors {
        lock: lock
    }

    // Force service initialization
    property var _arpcInit: DiscordRPC
    property var _pipInit: PipManager
    property var _systemTrayInit: SystemTray
}
