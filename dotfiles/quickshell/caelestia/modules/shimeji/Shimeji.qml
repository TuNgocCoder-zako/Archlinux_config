import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.services
import qs.utils

StyledWindow {
    id: root

    required property ShellScreen modelData
    property int shimejiCount: 1

    readonly property alias shimejiScreen: root.modelData

    readonly property bool shouldBeVisible: !(GameMode.enabled && GlobalConfig.utilities.gameMode.disableShimeji) && (!GlobalConfig.forScreen(modelData.name).shimeji.autoHide || (Hypr.monitorFor(modelData)?.activeWorkspace?.toplevels?.values.every(t => t.lastIpcObject?.floating) ?? true))

    property var extractedPaths: []

    property Process extractor: Process {
        running: false
        command: ["unzip", "-o"]
        workingDirectory: "/tmp"
    }

    readonly property real borderThickness: modelData ? contentItem.Config.border.thickness : 0

    readonly property real shimejiScale: contentItem.Config.shimeji.scale || 1.0

    readonly property var barWrapper: root.screen ? Visibilities.bars.get(root.screen.name) : undefined

    readonly property real barExclusiveZone: barWrapper?.exclusiveZone ?? (contentItem.Tokens.sizes.bar.innerWidth + Math.max(contentItem.Tokens.padding.small, contentItem.Config.border.thickness))

    readonly property real floorOffset: contentItem.Config.bar.position === "bottom" ? barExclusiveZone : 0
    readonly property real ceilingOffset: contentItem.Config.bar.position === "top" ? barExclusiveZone : 0
    readonly property real leftOffset: contentItem.Config.bar.position === "left" ? barExclusiveZone : 0
    readonly property real rightOffset: contentItem.Config.bar.position === "right" ? barExclusiveZone : 0

    property list<Region> spriteMasks: []

    function getImgPath(): string {
        if (!modelData)
            return "";
        let rawPath = String(contentItem.Config.shimeji.path || "");
        if (!rawPath || rawPath.length === 0)
            rawPath = "root:/assets/shimeji/pusheen";
        let path = Paths.absolutePath(rawPath);
        if (!path)
            return "";

        if (path.endsWith(".zip")) {
            const extractDir = path.replace(".zip", "/");
            if (!extractor.running && !extractedPaths.includes(path)) {
                extractedPaths.push(path);
                extractor.arguments = ["-o", "-d", extractDir, path];
                extractor.running = true;
            }
            return extractDir;
        }

        return path.replace(/\/?$/, "/");
    }

    function registerSpriteMask(region: Region): void {
        if (!root.spriteMasks.includes(region))
            root.spriteMasks = [...root.spriteMasks, region];
    }

    function unregisterSpriteMask(region: Region): void {
        root.spriteMasks = root.spriteMasks.filter(m => m !== region);
    }

    mask: Region {
        regions: root.spriteMasks
    }

    screen: modelData
    visible: shouldBeVisible

    name: "shimeji"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    surfaceFormat.opaque: false

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    Item {
        anchors.fill: parent

        Repeater {
            id: spriteRepeater

            model: Math.max(1, root.shimejiCount)

            ShimejiSprite {
                maskHost: root
                screenSize: Qt.size(shimejiScreen.width, shimejiScreen.height)
                borderThickness: root.borderThickness
                sizeScale: root.shimejiScale
                floorOffset: root.floorOffset
                ceilingOffset: root.ceilingOffset
                leftOffset: root.leftOffset
                rightOffset: root.rightOffset
                imgPath: root.getImgPath()
            }
        }
    }
}
