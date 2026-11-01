pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.components.effects
import qs.components.filedialog
import qs.services
import qs.utils
import Quickshell
import Quickshell.Io
import M3Shapes
import Caelestia.Blobs

Item {
    id: root

    ListModel { id: chatHistory }
    ListModel { id: historySessionsModel }

    property bool isHistoryTab: false
    property string currentChatId: ""
    property var currentRequest: null
    property bool isStreaming: false
    property var screenState: null
    property string attachedFilePath: ""
    property string attachedFileName: ""
    property bool enableDeepThink: false

    function attachFile(path) {
        if (!path) return;
        path = String(path).trim();
        if (path.startsWith("file://")) {
            path = decodeURIComponent(path.substring(7));
        }
        attachedFilePath = path;
        var parts = path.split("/");
        attachedFileName = parts[parts.length - 1];
        Toaster.toast(qsTr("Đã đính kèm tập tin"), attachedFileName, "attach_file");
    }

    function clearAttachedFile() {
        attachedFilePath = "";
        attachedFileName = "";
    }
    

    Timer {
        id: typingTimer
        interval: 16
        repeat: true
        property string fullText: ""
        property string currentText: ""
        property int charIndex: 0
        property int targetIdx: -1
        
        onTriggered: {
            if (targetIdx < 0 || targetIdx >= chatHistory.count) {
                stop();
                isTyping = false;
                isThinking = false;
                inAgentLoop = false;
                return;
            }
            if (charIndex >= fullText.length) {
                stop();
                chatHistory.setProperty(targetIdx, "text", fullText);
                chatHistory.setProperty(targetIdx, "isFinished", true);
                saveHistory();
                isTyping = false;
                isThinking = false;
                inAgentLoop = false;
                return;
            }
            var chunkSize = Math.max(1, Math.ceil(fullText.length / 30));
            currentText += fullText.substr(charIndex, chunkSize);
            charIndex += chunkSize;
            chatHistory.setProperty(targetIdx, "text", currentText);
            listView.positionViewAtEnd();
        }
    }
    
    onVisibleChanged: {
        if (visible) {
            fetchOllamaModels();
            inputArea.forceActiveFocus();
        }
    }

    function startTypingAnimation(text) {
        isThinking = false;
        typingTimer.targetIdx = chatHistory.count - 1;
        typingTimer.fullText = text;
        typingTimer.currentText = "";
        typingTimer.charIndex = 0;
        typingTimer.start();
        listView.positionViewAtEnd();
    }

    Component.onCompleted: {
        fetchOllamaModels();
        loadHistory();
    }

    property var ollamaModelsList: []
    property var ollamaModelsCaps: ({})
    property bool isTyping: false
    property bool isThinking: false
    property string currentThoughtText: ""
    property bool isThoughtExpanded: false
    onIsTypingChanged: {
        if (isTyping) listView.positionViewAtEnd();
    }
    property bool inAgentLoop: false

    function runAgentCommand(cmd, type) {
        var processQml = "import QtQuick\n" +
                         "import Quickshell.Io\n" +
                         "Process {\n" +
                         "    id: proc\n" +
                         "    command: [\"sh\", \"-c\", " + JSON.stringify(cmd) + "]\n" +
                         "    property string outStr: \"\"\n" +
                         "    property string errStr: \"\"\n" +
                         "    property bool hasExited: false\n" +
                         "    property bool outFinished: false\n" +
                         "    property bool errFinished: false\n" +
                         "    function checkDone() {\n" +
                         "        if (hasExited && outFinished && errFinished) {\n" +
                         "            root.handleAgentProcessResult(" + JSON.stringify(type) + ", proc.outStr, proc.errStr, " + JSON.stringify(cmd) + ");\n" +
                         "            proc.destroy();\n" +
                         "        }\n" +
                         "    }\n" +
                         "    stdout: StdioCollector { onStreamFinished: { proc.outStr = text || \"\"; proc.outFinished = true; proc.checkDone(); } }\n" +
                         "    stderr: StdioCollector { onStreamFinished: { proc.errStr = text || \"\"; proc.errFinished = true; proc.checkDone(); } }\n" +
                         "    onExited: code => { proc.hasExited = true; proc.checkDone(); }\n" +
                         "}";
        var obj = Qt.createQmlObject(processQml, root, "agentProcess");
        obj.running = true;
    }

    property int runningToolsCount: 0
    property string accumulatedToolResults: ""
    property string accumulatedToolImage: ""

    function handleAgentProcessResult(type, stdout, stderr, cmd) {
        if (type.startsWith("direct_image_stream:")) {
            var userPrompt = "";
            try {
                userPrompt = JSON.parse(type.substring(20));
            } catch (e) {
                userPrompt = "Phân tích và giải quyết nội dung trong hình ảnh này.";
            }
            var b64Data = stdout.trim();
            sendPrompt(userPrompt, false, b64Data, "", false, true);
            return;
        } else if (type === "region_snip_capture") {
            var lines = stdout.trim().split("\n");
            var targetPath = lines[lines.length - 1].trim();
            if (!targetPath || targetPath === "CANCELLED" || targetPath.startsWith("ERROR")) {
                Toaster.toast(qsTr("Chụp vùng màn hình"), qsTr("Đã hủy chọn vùng"), "close");
                return;
            }
            root.attachFile(targetPath);
            var currentQuery = inputArea.text.trim();
            if (currentQuery.length > 0) {
                root.sendPrompt(currentQuery);
                inputArea.clear();
            } else {
                Toaster.toast(qsTr("Đã chụp vùng màn hình"), qsTr("Nhập câu hỏi hoặc nhấn Gửi để AI phân tích"), "crop");
            }
            return;
        } else if (type === "screenshot_take") {
            var convertCmd = "magick /tmp/orion_screenshot.png -resize '1024x1024>' -quality 85 /tmp/orion_screenshot.jpg && base64 /tmp/orion_screenshot.jpg";
            runAgentCommand(convertCmd, "screenshot_encode");
        } else if (type === "screenshot_encode") {
            var b64 = stdout.replace(/\n/g, "").trim();
            accumulatedToolImage = b64;
            accumulatedToolResults += "Tool: take_screenshot\nResult: Screenshot taken. Analyze the attached image.\n\n";
            runningToolsCount--;
            checkToolsFinished();
        } else if (type.startsWith("exec_")) {
            var toolName = type.substring(5);
            var outText = stdout.trim();
            var errText = stderr.trim();
            if (!outText && !errText) {
                outText = "(Command completed with no output. If it was a background task, it has been launched successfully.)";
            }
            accumulatedToolResults += "Tool: " + toolName + "\nCommand executed: " + cmd + "\nOutput: " + outText + "\nError: " + errText + "\n\n";
            runningToolsCount--;
            checkToolsFinished();
        }
    }

    function startRegionSnip() {
        Toaster.toast(qsTr("Chụp vùng màn hình"), qsTr("Kéo chuột để chọn vùng cần chụp (nhấn Esc để hủy)..."), "screenshot_region");
        var snipCmd = 'bash "' + Quickshell.shellDir + '/assets/scripts/orion_snip.sh"';
        runAgentCommand(snipCmd, "region_snip_capture");
    }

    function checkToolsFinished() {
        if (runningToolsCount <= 0) {
            var b64 = accumulatedToolImage ? accumulatedToolImage : null;
            sendPrompt(accumulatedToolResults.trim(), true, b64, "multi_tool");
        }
    }

    property string currentActionText: "Thinking..."

    property bool isOllamaOnline: true
    property bool isCheckingOllama: false

    Process {
        id: startOllamaProc
        command: ["sh", "-c", "docker --context default restart ollama 2>/dev/null || docker --context default start ollama 2>/dev/null || ollama serve >/dev/null 2>&1 &"]
        onExited: {
            retryOllamaTimer.restart();
        }
    }

    Timer {
        id: retryOllamaTimer
        interval: 1500
        onTriggered: root.fetchOllamaModels()
    }

    function startOllama() {
        isCheckingOllama = true;
        Toaster.toast(qsTr("Ollama"), qsTr("Starting Ollama service..."), "smart_toy");
        startOllamaProc.running = true;
    }

    function fetchOllamaModels() {
        var ollamaUrl = GlobalConfig.ai.ollamaUrl || "http://localhost:11434";
        var xhr = new XMLHttpRequest();
        root.isCheckingOllama = true;
        xhr.timeout = 4000;
        xhr.open("GET", ollamaUrl + "/api/tags", true);
        xhr.ontimeout = () => {
            root.isOllamaOnline = false;
            root.isCheckingOllama = false;
        };
        xhr.onerror = () => {
            root.isOllamaOnline = false;
            root.isCheckingOllama = false;
        };
        xhr.onreadystatechange = () => {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                root.isCheckingOllama = false;
                if (xhr.status === 200) {
                    root.isOllamaOnline = true;
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var list = [];
                        var capsMap = {};
                        if (response.models) {
                            for (var i = 0; i < response.models.length; i++) {
                                var m = response.models[i];
                                list.push(m.name);
                                capsMap[m.name] = m.capabilities || [];
                            }
                        }
                        ollamaModelsCaps = capsMap;
                        if (list.length > 0) {
                            ollamaModelsList = list;
                            if (list.indexOf(GlobalConfig.ai.defaultOllamaModel) === -1 || GlobalConfig.ai.defaultOllamaModel.indexOf("moondream") !== -1) {
                                var preferred = list.find(n => n.indexOf("qwen") !== -1) || list.find(n => n.indexOf("llama") !== -1) || list[0];
                                GlobalConfig.ai.defaultOllamaModel = preferred;
                            }
                        } else {
                            ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                        }
                    } catch (e) {
                        console.log("Error parsing Ollama models: " + e.message);
                        ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                    }
                } else {
                    root.isOllamaOnline = false;
                    console.log("Ollama tags request failed (status " + xhr.status + ")");
                    ollamaModelsList = ["llama3", "mistral", "phi3", "gemma"];
                }
            }
        };
        xhr.send();
    }

    property var allChatSessions: []

    function createNewChat() {
        typingTimer.stop();
        isTyping = false;
        isThinking = false;
        inAgentLoop = false;
        isStreaming = false;
        currentChatId = "chat_" + Date.now();
        chatHistory.clear();
        isHistoryTab = false;
    }

    function loadChat(id) {
        typingTimer.stop();
        isTyping = false;
        isThinking = false;
        inAgentLoop = false;
        isStreaming = false;
        currentChatId = id;
        chatHistory.clear();
        var found = false;
        for (var i = 0; i < allChatSessions.length; i++) {
            if (allChatSessions[i].id === id) {
                var msgs = allChatSessions[i].messages;
                for (var j = 0; j < msgs.length; j++) {
                    // Strictly sanitize incoming JSON data before ListModel append
                    chatHistory.append({
                        "isUser": msgs[j].isUser === true,
                        "text": msgs[j].text || "",
                        "isFinished": msgs[j].isFinished !== false,
                        "thoughtText": msgs[j].thoughtText || ""
                    });
                }
                found = true;
                break;
            }
        }
        if (!found) createNewChat();
        isHistoryTab = false;
    }

    function loadHistory() {
        allChatSessions = [];
        var jsonStr = GlobalConfig.ai.ollamaHistoryJson;
        if (jsonStr) {
            try {
                var parsed = JSON.parse(jsonStr);
                // Protect against corrupted saves
                if (Array.isArray(parsed)) {
                    allChatSessions = parsed.filter(s => s !== null && s.id);
                }
            } catch (e) {}
        }

        historySessionsModel.clear();
        for (var i = 0; i < allChatSessions.length; i++) {
            // Strictly enforce string values
            historySessionsModel.append({
                "id": allChatSessions[i].id || ("chat_" + Date.now()),
                "title": allChatSessions[i].title || "Chat"
            });
        }

        if (allChatSessions.length > 0) {
            loadChat(allChatSessions[0].id);
        } else {
            createNewChat();
        }
    }

    function saveHistory() {
        var msgs = [];
        for (var i = 0; i < chatHistory.count; i++) {
            var msg = chatHistory.get(i);
            msgs.push({
                "isUser": msg.isUser === true,
                "text": msg.text || "",
                "isFinished": msg.isFinished !== false,
                "thoughtText": msg.thoughtText || ""
            });
        }
        
        if (msgs.length === 0) return;
        
        var found = false;
        for (var j = 0; j < allChatSessions.length; j++) {
            if (allChatSessions[j].id === currentChatId) {
                allChatSessions[j].messages = msgs;
                
                var firstUser = null;
                for (var k = 0; k < msgs.length; k++) {
                    if (msgs[k].isUser) { firstUser = msgs[k]; break; }
                }
                if (msgs.length > 1 && (allChatSessions[j].title === "Legacy Chat" || allChatSessions[j].title === "New Chat" || allChatSessions[j].title.indexOf("New Chat") === 0 || !allChatSessions[j].title)) {
                    if (firstUser) {
                        generateChatTitleAsync(currentChatId, firstUser.text);
                    }
                }
                found = true;
                break;
            }
        }
        
        if (!found) {
            var firstUserMsg = null;
            for (var m = 0; m < msgs.length; m++) {
                if (msgs[m].isUser) { firstUserMsg = msgs[m]; break; }
            }
            
            var initialTitle = "New Chat";
            
            allChatSessions.unshift({
                "id": currentChatId || ("chat_" + Date.now()),
                "title": initialTitle,
                "messages": msgs
            });
            
            historySessionsModel.insert(0, {
                "id": currentChatId || ("chat_" + Date.now()),
                "title": initialTitle
            });
            
            if (firstUserMsg) {
                generateChatTitleAsync(currentChatId, firstUserMsg.text);
            }
        }
        
        GlobalConfig.ai.ollamaHistoryJson = JSON.stringify(allChatSessions);
    }

    function deleteChat(id) {
        var idx = -1;
        for (var i = 0; i < allChatSessions.length; i++) {
            if (allChatSessions[i].id === id) {
                idx = i;
                break;
            }
        }
        if (idx !== -1) {
            allChatSessions.splice(idx, 1);
            for (var j = 0; j < historySessionsModel.count; j++) {
                if (historySessionsModel.get(j).id === id) {
                    historySessionsModel.remove(j);
                    break;
                }
            }
            
            GlobalConfig.ai.ollamaHistoryJson = JSON.stringify(allChatSessions);

            if (currentChatId === id) {
                chatHistory.clear();
                if (allChatSessions.length > 0) {
                    loadChat(allChatSessions[0].id);
                } else {
                    createNewChat();
                }
            }
        }
    }

    function clearAllHistory() {
        allChatSessions = [];
        historySessionsModel.clear();
        GlobalConfig.ai.ollamaHistoryJson = "[]";
        createNewChat();
    }

    function generateChatTitleAsync(chatId, firstMessage) {
        if (!firstMessage || !chatId) return;
        var clean = firstMessage.trim().replace(/\n/g, ' ');
        if (clean.startsWith("📎 ")) {
            var parts = clean.split("\n");
            clean = parts[0].substring(2).trim();
        }
        if (clean.length > 28) {
            clean = clean.substring(0, 25) + "...";
        }
        if (clean.length > 0) {
            updateChatTitle(chatId, clean);
        }
    }

    function updateChatTitle(chatId, title) {
        if (!title || !chatId) return;
        
        for (var i = 0; i < allChatSessions.length; i++) {
            if (allChatSessions[i].id === chatId) {
                allChatSessions[i].title = title;
                
                var inModel = false;
                for (var j = 0; j < historySessionsModel.count; j++) {
                    if (historySessionsModel.get(j).id === chatId) {
                        historySessionsModel.setProperty(j, "title", title);
                        inModel = true;
                        break;
                    }
                }
                
                if (!inModel) {
                    historySessionsModel.insert(0, {
                        "id": chatId || "",
                        "title": title || "New Chat"
                    });
                }
                
                GlobalConfig.ai.ollamaHistoryJson = JSON.stringify(allChatSessions);
                break;
            }
        }
    }

    function addAiMessage(message) {
        chatHistory.append({
            "isUser": false,
            "text": message || "",
            "isFinished": true,
            "thoughtText": ""
        });
        listView.positionViewAtEnd();
        saveHistory();
    }

    function extractJsonToolCalls(text) {
        if (!text) return [];
        var results = [];
        var depth = 0;
        var inString = false;
        var escape = false;
        var startIdx = -1;
        for (var i = 0; i < text.length; i++) {
            var ch = text[i];
            if (escape) { escape = false; continue; }
            if (ch === '\\') { escape = true; continue; }
            if (ch === '"') { inString = !inString; continue; }
            if (!inString) {
                if (ch === '{') {
                    if (depth === 0) startIdx = i;
                    depth++;
                } else if (ch === '}') {
                    depth--;
                    if (depth === 0 && startIdx !== -1) {
                        var jsonStr = text.substring(startIdx, i + 1);
                        startIdx = -1;
                        try {
                            var obj = JSON.parse(jsonStr);
                            if (obj) {
                                var name = obj.name || obj.tool || (obj.function && obj.function.name);
                                if (name) {
                                    var args = obj.arguments || obj.parameters || (obj.function && (obj.function.arguments || obj.function.parameters)) || {};
                                    if (typeof args === "string") {
                                        try { args = JSON.parse(args); } catch (e) {}
                                    }
                                    results.push({ "name": name, "arguments": args });
                                }
                            }
                        } catch (e) {}
                    }
                }
            }
        }
        return results;
    }

    function cleanToolCallsFromText(text) {
        if (!text) return "";
        var res = text;
        res = res.replace(/<tool_call>[\s\S]*?(?:<\/tool_call>|$)/gi, "");
        res = res.replace(/<\/?tool_call>/gi, "");

        var depth = 0;
        var inString = false;
        var escape = false;
        var startIdx = -1;
        var rangesToRemove = [];

        for (var i = 0; i < res.length; i++) {
            var ch = res[i];
            if (escape) { escape = false; continue; }
            if (ch === '\\') { escape = true; continue; }
            if (ch === '"') { inString = !inString; continue; }
            if (!inString) {
                if (ch === '{') {
                    if (depth === 0) startIdx = i;
                    depth++;
                } else if (ch === '}') {
                    depth--;
                    if (depth === 0 && startIdx !== -1) {
                        var jsonStr = res.substring(startIdx, i + 1);
                        try {
                            var obj = JSON.parse(jsonStr);
                            if (obj && (obj.name || obj.tool || obj.function)) {
                                var end = i + 1;
                                var after = res.substring(end);
                                var trailingTag = after.match(/^\s*<\/tool_call>/i);
                                if (trailingTag) {
                                    end += trailingTag[0].length;
                                }
                                rangesToRemove.push({ "start": startIdx, "end": end });
                            }
                        } catch (e) {}
                        startIdx = -1;
                    }
                }
            }
        }

        if (depth > 0 && startIdx !== -1) {
            var uncompleted = res.substring(startIdx);
            if (/^\{\s*(?:"(?:name|tool|function|parameters|arguments)?|"|\n|\s|$)/i.test(uncompleted)) {
                rangesToRemove.push({ "start": startIdx, "end": res.length });
            }
        }

        for (var r = rangesToRemove.length - 1; r >= 0; r--) {
            res = res.substring(0, rangesToRemove[r].start) + res.substring(rangesToRemove[r].end);
        }

        return res.trim();
    }

    function formatMathAndLogic(raw) {
        if (!raw) return "";

        // Separate code blocks (fenced ``` and inline `) so code is preserved verbatim
        var parts = raw.split(/(```[\s\S]*?```|`[^`\n]+`)/g);

        function replaceBalanced(text, prefix, transform) {
            var idx = text.indexOf(prefix);
            var count = 0;
            while (idx !== -1 && count++ < 50) {
                var start = idx + prefix.length;
                while (start < text.length && /\s/.test(text[start])) start++;
                if (text[start] !== "{") {
                    idx = text.indexOf(prefix, start + 1);
                    continue;
                }
                var depth = 1;
                var end = start + 1;
                while (end < text.length && depth > 0) {
                    if (text[end] === "{") depth++;
                    else if (text[end] === "}") depth--;
                    end++;
                }
                if (depth === 0) {
                    var inner = text.substring(start + 1, end - 1);
                    var repl = transform(inner);
                    text = text.substring(0, idx) + repl + text.substring(end);
                    idx = text.indexOf(prefix, idx + repl.length);
                } else {
                    break;
                }
            }
            return text;
        }

        function replaceFrac(text) {
            var prefix = "\\frac";
            var idx = text.indexOf(prefix);
            var count = 0;
            while (idx !== -1 && count++ < 50) {
                var p1 = idx + prefix.length;
                while (p1 < text.length && /\s/.test(text[p1])) p1++;
                if (text[p1] !== "{") {
                    idx = text.indexOf(prefix, p1 + 1);
                    continue;
                }
                var depth = 1, end1 = p1 + 1;
                while (end1 < text.length && depth > 0) {
                    if (text[end1] === "{") depth++;
                    else if (text[end1] === "}") depth--;
                    end1++;
                }
                if (depth !== 0) break;
                var num = text.substring(p1 + 1, end1 - 1);

                var p2 = end1;
                while (p2 < text.length && /\s/.test(text[p2])) p2++;
                if (text[p2] !== "{") {
                    idx = text.indexOf(prefix, p2 + 1);
                    continue;
                }
                depth = 1;
                var end2 = p2 + 1;
                while (end2 < text.length && depth > 0) {
                    if (text[end2] === "{") depth++;
                    else if (text[end2] === "}") depth--;
                    end2++;
                }
                if (depth !== 0) break;
                var den = text.substring(p2 + 1, end2 - 1);

                var repl = "(" + num.trim() + " / " + den.trim() + ")";
                text = text.substring(0, idx) + repl + text.substring(end2);
                idx = text.indexOf(prefix, idx + repl.length);
            }
            return text;
        }

        var supMap = {"0":"⁰","1":"¹","2":"²","3":"³","4":"⁴","5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹","+":"⁺","-":"⁻","=":"⁼","(":"⁽",")":"⁾","n":"ⁿ","i":"ⁱ"};
        var subMap = {"0":"₀","1":"₁","2":"₂","3":"₃","4":"₄","5":"₅","6":"₆","7":"₇","8":"₈","9":"₉","+":"₊","-":"₋","=":"₌","(":"₍",")":"₎","a":"ₐ","e":"ₑ","h":"ₕ","i":"ᵢ","j":"ⱼ","k":"ₖ","l":"ₗ","m":"ₘ","n":"ₙ","o":"ₒ","p":"ₚ","r":"ᵣ","s":"ₛ","t":"ₜ","u":"ᵤ","v":"ᵥ","x":"ₓ"};

        for (var i = 0; i < parts.length; i++) {
            if (i % 2 === 0) {
                var text = parts[i];

                text = replaceBalanced(text, "\\boxed", function(inner) { return "**【 " + inner.trim() + " 】**"; });
                text = replaceFrac(text);
                text = replaceBalanced(text, "\\sqrt", function(inner) { return "√(" + inner.trim() + ")"; });
                text = replaceBalanced(text, "\\text", function(inner) { return inner; });
                text = replaceBalanced(text, "\\mathrm", function(inner) { return inner; });
                text = replaceBalanced(text, "\\mathbf", function(inner) { return inner; });
                text = replaceBalanced(text, "\\mathit", function(inner) { return inner; });

                // Propositional Logic
                text = text.replace(/\\(?:iff|Leftrightarrow|longleftrightarrow)\b/g, "⇔");
                text = text.replace(/\\(?:leftrightarrow)\b/g, "↔");
                text = text.replace(/\\(?:implies|Rightarrow)\b/g, "⇒");
                text = text.replace(/\\(?:to|rightarrow|longrightarrow)\b/g, "→");
                text = text.replace(/\\(?:leftarrow|longleftarrow)\b/g, "←");
                text = text.replace(/\\equiv\b/g, "≡");
                text = text.replace(/\\(?:land|wedge)\b/g, "∧");
                text = text.replace(/\\(?:lor|vee)\b/g, "∨");
                text = text.replace(/\\(?:neg|sim)\b/g, "¬");
                text = text.replace(/\\(?:oplus|veebar)\b/g, "⊕");
                text = text.replace(/\\top\b/g, "⊤");
                text = text.replace(/\\bot\b/g, "⊥");
                text = text.replace(/\\forall\b/g, "∀");
                text = text.replace(/\\exists\b/g, "∃");
                text = text.replace(/\\nexists\b/g, "∄");
                text = text.replace(/\\therefore\b/g, "∴");
                text = text.replace(/\\because\b/g, "∵");
                text = text.replace(/\\vdash\b/g, "⊢");
                text = text.replace(/\\models\b/g, "⊨");

                // Set Theory & Relations
                text = text.replace(/\\in\b/g, "∈");
                text = text.replace(/\\notin\b/g, "∉");
                text = text.replace(/\\subseteq\b/g, "⊆");
                text = text.replace(/\\subset\b/g, "⊂");
                text = text.replace(/\\supseteq\b/g, "⊇");
                text = text.replace(/\\supset\b/g, "⊃");
                text = text.replace(/\\cup\b/g, "∪");
                text = text.replace(/\\cap\b/g, "∩");
                text = text.replace(/\\(?:emptyset|varnothing)\b/g, "∅");
                text = text.replace(/\\setminus\b/g, "\\");

                // Comparisons & Math
                text = text.replace(/\\(?:le|leq|leqslant)\b/g, "≤");
                text = text.replace(/\\(?:ge|geq|geqslant)\b/g, "≥");
                text = text.replace(/\\(?:ne|neq)\b/g, "≠");
                text = text.replace(/\\approx\b/g, "≈");
                text = text.replace(/\\cong\b/g, "≅");
                text = text.replace(/\\times\b/g, "×");
                text = text.replace(/\\div\b/g, "÷");
                text = text.replace(/\\pm\b/g, "±");
                text = text.replace(/\\mp\b/g, "∓");
                text = text.replace(/\\cdot\b/g, "·");
                text = text.replace(/\\circ\b/g, "∘");
                text = text.replace(/\\infty\b/g, "∞");
                text = text.replace(/\\sum\b/g, "∑");
                text = text.replace(/\\prod\b/g, "∏");
                text = text.replace(/\\int\b/g, "∫");
                text = text.replace(/\\partial\b/g, "∂");

                // Greek Letters
                text = text.replace(/\\alpha\b/g, "α");
                text = text.replace(/\\beta\b/g, "β");
                text = text.replace(/\\gamma\b/g, "γ");
                text = text.replace(/\\Gamma\b/g, "Γ");
                text = text.replace(/\\delta\b/g, "δ");
                text = text.replace(/\\Delta\b/g, "Δ");
                text = text.replace(/\\epsilon\b/g, "ε");
                text = text.replace(/\\theta\b/g, "θ");
                text = text.replace(/\\lambda\b/g, "λ");
                text = text.replace(/\\mu\b/g, "μ");
                text = text.replace(/\\pi\b/g, "π");
                text = text.replace(/\\sigma\b/g, "σ");
                text = text.replace(/\\Sigma\b/g, "Σ");
                text = text.replace(/\\omega\b/g, "ω");
                text = text.replace(/\\Omega\b/g, "Ω");

                // Superscripts and Subscripts
                text = text.replace(/\^\{([0-9\+\-n]+)\}/g, function(_, m) {
                    return m.split("").map(function(c) { return supMap[c] || c; }).join("");
                });
                text = text.replace(/\^([0-9ni])/g, function(_, m) {
                    return supMap[m] || ("^" + m);
                });
                text = text.replace(/_\{([0-9a-z\+\-]+)\}/g, function(_, m) {
                    return m.split("").map(function(c) { return subMap[c] || c; }).join("");
                });
                text = text.replace(/_([0-9aijknm])/g, function(_, m) {
                    return subMap[m] || ("_" + m);
                });

                // Strip outer $$ ... $$ and $ ... $
                text = text.replace(/\$\$([\s\S]*?)\$\$/g, "\n$1\n");
                text = text.replace(/\$([^\$\n]+?)\$/g, function(match, inner) {
                    if (/^\s*\d+(?:\.\d+)?\s*$/.test(inner)) return match;
                    return inner.trim();
                });

                parts[i] = text;
            }
        }
        return parts.join("");
    }

    function sendPrompt(promptText, isSystemToolResult = false, base64Image = null, toolName = "", isRegion = false, skipHistoryAppend = false) {
        if (!promptText.trim() && !base64Image && root.attachedFilePath === "") return;

        if (!isSystemToolResult && !skipHistoryAppend) {
            var userText = promptText || "";
            var hasAttachedFile = root.attachedFilePath !== "";
            var targetFile = root.attachedFilePath;
            if (hasAttachedFile) {
                userText = "📎 " + root.attachedFileName + (userText.trim() ? ("\n" + userText) : "\nXem qua tài liệu này giúp tôi.");
                root.clearAttachedFile();
            }

            chatHistory.append({
                "isUser": true,
                "text": userText,
                "isFinished": true,
                "thoughtText": ""
            });
            listView.positionViewAtEnd();
            saveHistory();

            if (hasAttachedFile) {
                for (var i = chatHistory.count - 1; i >= 0; i--) {
                    var m = chatHistory.get(i);
                    if (!m.isUser && !m.isFinished && m.text === "") {
                        chatHistory.remove(i);
                    }
                }
                chatHistory.append({
                    "isUser": false,
                    "text": "",
                    "isFinished": false,
                    "thoughtText": ""
                });
                listView.positionViewAtEnd();

                isTyping = true;
                isThinking = true;
                inAgentLoop = true;
                currentThoughtText = "";
                accumulatedToolResults = "";
                accumulatedToolImage = "";
                runningToolsCount = 1;

                var isImage = /\.(?:png|jpe?g|webp|bmp)$/i.test(targetFile);
                if (isImage) {
                    currentActionText = "Reading image...";
                    var encodeCmd = 'magick "' + targetFile + '" -resize "1600x1600>" -quality 90 /tmp/orion_direct_opt.jpg 2>/dev/null && base64 -w 0 /tmp/orion_direct_opt.jpg || base64 -w 0 "' + targetFile + '"';
                    runAgentCommand(encodeCmd, "direct_image_stream:" + JSON.stringify(promptText || "Phân tích và giải quyết nội dung trong hình ảnh này."));
                    return;
                }

                currentActionText = "Reading document...";
                var fileCmd = 'PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_file.py" --path ' + JSON.stringify(targetFile);
                runAgentCommand(fileCmd, "exec_read_file");
                return;
            }

            var enableTools = GlobalConfig.ai.enableCelestialMode;
            var lower = (promptText || "").toLowerCase();

            var fileRegex = /((?:\/|~\/|file:\/\/)[^\n\r"'\`]+?\.(?:pdf|txt|md|json|py|js|ts|c|cpp|rs|html|csv|log|conf|sh|ya?ml|ini|xml))/i;
            var fileMatch = promptText.match(fileRegex);
            var isFileReq = enableTools && fileMatch && (
                promptText.trim() === fileMatch[1].trim() ||
                /(?:đọc|xem|kiểm tra|tóm tắt|phân tích|nội dung|dịch|xử lý|read|check|summary|explain)/i.test(lower)
            );

            if (isFileReq) {
                for (var i = chatHistory.count - 1; i >= 0; i--) {
                    var m = chatHistory.get(i);
                    if (!m.isUser && !m.isFinished && m.text === "") {
                        chatHistory.remove(i);
                    }
                }
                chatHistory.append({
                    "isUser": false,
                    "text": "",
                    "isFinished": false,
                    "thoughtText": ""
                });
                listView.positionViewAtEnd();

                isTyping = true;
                isThinking = true;
                inAgentLoop = true;
                currentActionText = "Reading document...";
                currentThoughtText = "";
                accumulatedToolResults = "";
                accumulatedToolImage = "";
                runningToolsCount = 1;

                var fileCmd = 'PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_file.py" --path ' + JSON.stringify(fileMatch[1].trim());
                runAgentCommand(fileCmd, "exec_read_file");
                return;
            }

            var regionPhrases = /(?:chụp\s*vùng|chọn\s*vùng|khoanh\s*vùng|vùng\s*màn|cắt\s*vùng|snip|crop|khu\s*vực|bài\s*ở\s*đây)/i;
            var isRegionReq = enableTools && (isRegion || regionPhrases.test(lower));

            var screenWords = /(?:màn\s*hình|man\s*hinh|màn\s*này|desktop|screen|screenshot)/i;
            var actionWords = /(?:xem|đọc|dọc|nhìn|coi|chụp|kiểm\s*tra|quét|check|look|read|view|inspect|capture|thấy|giúp|bài)/i;
            var directPhrases = /(?:xem\s*màn|đọc\s*màn|dọc\s*màn|nhìn\s*màn|chụp\s*màn|coi\s*màn|màn\s*hình\s*đi|màn\s*hình\s*có|trên\s*màn|xem\s*ảnh|đọc\s*ảnh)/i;
            var isScreenReq = enableTools && (directPhrases.test(lower) || (screenWords.test(lower) && actionWords.test(lower)));

            if (isRegionReq || isScreenReq) {
                for (var i = chatHistory.count - 1; i >= 0; i--) {
                    var m = chatHistory.get(i);
                    if (!m.isUser && !m.isFinished && m.text === "") {
                        chatHistory.remove(i);
                    }
                }
                chatHistory.append({
                    "isUser": false,
                    "text": "",
                    "isFinished": false,
                    "thoughtText": ""
                });
                listView.positionViewAtEnd();

                isTyping = true;
                isThinking = true;
                inAgentLoop = true;
                currentActionText = isRegionReq ? "Selecting region (Kéo chuột chọn vùng)..." : "Analyzing screen...";
                currentThoughtText = "";
                accumulatedToolResults = "";
                accumulatedToolImage = "";
                runningToolsCount = 1;

                var screenCmd = 'PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_screen.py"';
                if (isRegionReq) screenCmd += ' --region';
                screenCmd += ' --query ' + JSON.stringify(promptText);
                runAgentCommand(screenCmd, "exec_take_screenshot");
                return;
            }
        }

        isTyping = true;
        isThinking = root.enableDeepThink;
        inAgentLoop = true;
        currentThoughtText = "";
        isThoughtExpanded = false;
        
        if (base64Image) {
            currentActionText = "Analyzing image...";
        } else if (isSystemToolResult) {
            if (toolName === "web_search" || toolName === "read_webpage" || toolName === "read_file") {
                currentActionText = "Reading document / results...";
            } else if (toolName === "take_screenshot") {
                currentActionText = "Analyzing screen...";
            } else if (toolName === "get_weather") {
                currentActionText = "Analyzing weather...";
            } else {
                currentActionText = root.enableDeepThink ? "Thinking..." : "Replying...";
            }
        } else {
            currentActionText = root.enableDeepThink ? "Thinking..." : "Replying...";
        }
        var xhr = new XMLHttpRequest();
        root.currentRequest = xhr;

        var ollamaModel = GlobalConfig.ai.defaultOllamaModel || "llama3";
        var ollamaUrl = GlobalConfig.ai.ollamaUrl || "http://localhost:11434";
        var url = ollamaUrl + "/api/chat";
        xhr.open("POST", url, true);
        xhr.setRequestHeader("Content-Type", "application/json");
        
        var processedTextLength = 0;
        var accumulatedThoughtText = "";
        var accumulatedContentText = "";
        var rawAccumulatedContentText = "";
        var finalToolCalls = null;
        
        for (var i = chatHistory.count - 1; i >= 0; i--) {
            var m = chatHistory.get(i);
            if (!m.isUser && !m.isFinished && m.text === "") {
                chatHistory.remove(i);
            }
        }
        
        chatHistory.append({
            "isUser": false,
            "text": "",
            "isFinished": false,
            "thoughtText": ""
        });
        
        listView.positionViewAtEnd();
        
        xhr.onreadystatechange = () => {
            if (xhr.readyState === 3 || xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    var currentText = xhr.responseText;
                    var unparsed = currentText.substring(processedTextLength);
                    var lines = unparsed.split('\n');
                    
                    var linesToProcess = (xhr.readyState === XMLHttpRequest.DONE) ? lines.length : lines.length - 1;
                    
                    for (var i = 0; i < linesToProcess; i++) {
                        var line = lines[i].trim();
                        if (line === "") {
                            processedTextLength += lines[i].length + 1;
                            continue;
                        }
                        
                        try {
                            var parsed = JSON.parse(line);
                            processedTextLength += lines[i].length + 1;
                            
                            if (parsed.message) {
                                var chunkReasoning = parsed.message.thinking || parsed.message.reasoning || parsed.message.reasoning_content || "";
                                if (chunkReasoning) {
                                    accumulatedThoughtText += chunkReasoning;
                                }
                                
                                var chunkContent = parsed.message.content || "";
                                if (chunkContent) {
                                    rawAccumulatedContentText += chunkContent;
                                }
                                
                                var displayContent = rawAccumulatedContentText;
                                var displayThought = accumulatedThoughtText;
                                
                                if (accumulatedThoughtText === "") {
                                    var openThinkIdx = displayContent.indexOf("<think>");
                                    var closeThinkIdx = displayContent.indexOf("</think>");
                                    
                                    if (openThinkIdx !== -1) {
                                        if (closeThinkIdx !== -1) {
                                            displayThought = displayContent.substring(openThinkIdx + 7, closeThinkIdx).trim();
                                            displayContent = displayContent.substring(0, openThinkIdx) + displayContent.substring(closeThinkIdx + 8);
                                        } else {
                                            displayThought = displayContent.substring(openThinkIdx + 7).trim();
                                            displayContent = displayContent.substring(0, openThinkIdx);
                                        }
                                    }
                                }
                                
                                var cleanDisplay = displayContent;
                                if (GlobalConfig.ai.enableCelestialMode) {
                                    cleanDisplay = cleanToolCallsFromText(displayContent);
                                }
                                
                                root.currentThoughtText = displayThought.trim();
                                
                                if (cleanDisplay.trim() !== "") {
                                    if (isThinking) isThinking = false;
                                } else if (rawAccumulatedContentText.indexOf("\"name\":") !== -1 || rawAccumulatedContentText.indexOf("<tool_call>") !== -1 || rawAccumulatedContentText.trim().startsWith("{")) {
                                    currentActionText = "Calling tools...";
                                }
                                
                                chatHistory.setProperty(chatHistory.count - 1, "thoughtText", displayThought.trim());
                                chatHistory.setProperty(chatHistory.count - 1, "text", cleanDisplay.trim());
                                listView.positionViewAtEnd();
                                
                                if (parsed.message.tool_calls) {
                                    finalToolCalls = parsed.message.tool_calls;
                                }
                            }
                        } catch (e) {
                            break;
                        }
                    }
                }
                
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        var enableTools = GlobalConfig.ai.enableCelestialMode;
                        var finalResponseText = chatHistory.get(chatHistory.count - 1).text;
                        var refusalRegex = /(?:không thể xem|không có khả năng xem|không xem được|không thể nhìn|không có mắt|cannot see (?:your )?screen|unable to (?:view|see) (?:your )?screen)/i;
                        var screenKeywords = /(?:màn\s*hình|man\s*hinh|screen|screenshot|desktop)/i;
                        
                        var lastUserMsg = "";
                        for (var u = chatHistory.count - 2; u >= 0; u--) {
                            if (chatHistory.get(u).isUser) {
                                lastUserMsg = chatHistory.get(u).text;
                                break;
                            }
                        }
                        
                        if (enableTools && !isSystemToolResult && refusalRegex.test(finalResponseText) && screenKeywords.test(lastUserMsg)) {
                            console.log("Refusal intercepted! Triggering screen analysis fallback...");
                            chatHistory.setProperty(chatHistory.count - 1, "text", "");
                            currentActionText = "Analyzing screen...";
                            isTyping = true;
                            isThinking = true;
                            inAgentLoop = true;
                            accumulatedToolResults = "";
                            accumulatedToolImage = "";
                            runningToolsCount = 1;
                            var fallbackCmd = 'PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_screen.py" --query ' + JSON.stringify(lastUserMsg);
                            runAgentCommand(fallbackCmd, "exec_take_screenshot");
                            return;
                        }

                        if (enableTools && (!finalToolCalls || finalToolCalls.length === 0)) {
                            var extracted = extractJsonToolCalls(rawAccumulatedContentText);
                            if (extracted && extracted.length > 0) {
                                finalToolCalls = [];
                                for (var k = 0; k < extracted.length; k++) {
                                    var candArgs = extracted[k].arguments || {};
                                    finalToolCalls.push({
                                        "function": {
                                            "name": extracted[k].name,
                                            "arguments": candArgs
                                        }
                                    });
                                }
                            }
                        }

                        if (finalToolCalls && finalToolCalls.length > 0) {
                            if (enableTools) {
                                var remainingClean = cleanToolCallsFromText(rawAccumulatedContentText);
                                if (remainingClean !== "") {
                                    chatHistory.setProperty(chatHistory.count - 1, "text", remainingClean);
                                    chatHistory.setProperty(chatHistory.count - 1, "isFinished", true);
                                } else {
                                    chatHistory.setProperty(chatHistory.count - 1, "text", "");
                                }
                                saveHistory();

                                currentActionText = "Using tools...";
                                accumulatedToolResults = "";
                                accumulatedToolImage = "";
                                runningToolsCount = 0;
                                
                                for (var t = 0; t < finalToolCalls.length; t++) {
                                    var tool = finalToolCalls[t].function;
                                    var toolName = tool.name;
                                    var args = tool.arguments || {};
                                    if (typeof args === "string") {
                                        try { args = JSON.parse(args); } catch (e) {}
                                    }
                                    
                                    if (toolName === "take_screenshot" || toolName === "web_search" || toolName === "read_webpage" || toolName === "read_file" || toolName === "open_app" || toolName === "get_weather" || toolName === "caelestia_command") {
                                        runningToolsCount++;
                                    }
                                    
                                    if (toolName === "take_screenshot") {
                                        var query = args.query || args.focus || "";
                                        if (typeof query === "object" && query !== null) {
                                            query = query.value || query.description || query.query || "";
                                        }
                                        query = String(query || "").trim();
                                        var isReg = args.region === true;
                                        currentActionText = isReg ? "Selecting region (Kéo chuột chọn vùng)..." : "Analyzing screen...";
                                        var screenCmd = 'PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_screen.py"';
                                        if (isReg) {
                                            screenCmd += ' --region';
                                        }
                                        if (query) {
                                            screenCmd += ' --query ' + JSON.stringify(query);
                                        }
                                        runAgentCommand(screenCmd, "exec_" + toolName);
                                    } else if (toolName === "web_search") {
                                        currentActionText = "Searching the web...";
                                        var query = args.query || args.keyword || args.q || args.search || "";
                                        if (typeof query === "object" && query !== null) {
                                            query = query.value || query.description || query.query || "";
                                        }
                                        if (!query && typeof args === "string") query = args;
                                        query = String(query || "").trim();
                                        var page = args.page || 1;
                                        runAgentCommand('PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_search.py" --mode search --query ' + JSON.stringify(query) + ' --page ' + page, "exec_" + toolName);
                                    } else if (toolName === "read_webpage") {
                                        currentActionText = "Reading webpage...";
                                        var url = args.url;
                                        if (typeof url === "object" && url !== null) {
                                            url = url.value || url.description || url.url || "";
                                        }
                                        url = String(url || "").trim();
                                        runAgentCommand('PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_search.py" --mode read --url ' + JSON.stringify(url), "exec_" + toolName);
                                    } else if (toolName === "read_file") {
                                        currentActionText = "Reading file...";
                                        var path = args.path || args.file_path || args.filepath || args.file || "";
                                        if (typeof path === "object" && path !== null) {
                                            path = path.value || path.description || path.path || "";
                                        }
                                        path = String(path || "").trim();
                                        runAgentCommand('PYTHONIOENCODING=utf8 python3 "' + Quickshell.shellDir + '/assets/scripts/orion_file.py" --path ' + JSON.stringify(path), "exec_" + toolName);
                                    } else if (toolName === "open_app") {
                                        currentActionText = "Opening app...";
                                        var app = args.app_name || args.app;
                                        if (typeof app === "object" && app !== null) {
                                            app = app.value || app.description || app.app_name || "";
                                        }
                                        app = String(app || "").trim();
                                        runAgentCommand('grep -i -m 1 "^Exec=" $(find /usr/share/applications ~/.local/share/applications -name "*.desktop" -exec grep -il "Name=.*' + app.replace(new RegExp("\"", "g"), '\\"') + '" {} \\;) | cut -d "=" -f 2- | sed "s/ %[a-zA-Z]//g" | xargs -I {} sh -c "{} & disown"', "exec_" + toolName);
                                    } else if (toolName === "set_timer") {
                                        currentActionText = "Setting timer...";
                                        var secs = args.seconds || 5;
                                        var msg = args.message || "Timer finished";
                                        var safeMsg = String(msg).replace(new RegExp("\"", "g"), '\\"');
                                        var timerQml = "import QtQuick; Timer { interval: " + (secs * 1000) + "; running: true; onTriggered: { root.runAgentCommand('notify-send \"Orion Timer\" \"" + safeMsg + "\"', \"timer_trigger\"); destroy(); } }";
                                        Qt.createQmlObject(timerQml, root, "timer_" + Date.now());
                                        accumulatedToolResults += "Tool: set_timer\nResult: Timer successfully set for " + secs + " seconds in the background.\n\n";
                                    } else if (toolName === "get_weather") {
                                        currentActionText = "Checking weather...";
                                        var loc = args.location || args.city || "";
                                        if (typeof loc === "object" && loc !== null) {
                                            loc = loc.value || loc.description || loc.location || "";
                                        }
                                        loc = String(loc || "").trim();
                                        runAgentCommand('curl -s "wttr.in/' + loc.replace(new RegExp("\"", "g"), '\\"') + '?0T"', "exec_" + toolName);
                                    } else if (toolName === "caelestia_command") {
                                        currentActionText = "Running caelestia...";
                                        var subcmd = args.subcommand || "";
                                        var subargs = args.args || "";
                                        var cmd = "caelestia " + subcmd;
                                        if (subargs) cmd += " " + subargs;
                                        runAgentCommand(cmd, "exec_" + toolName);
                                    }
                                }
                                
                                if (runningToolsCount === 0) {
                                    if (accumulatedToolResults !== "") {
                                        checkToolsFinished();
                                    } else {
                                        currentActionText = "Thinking...";
                                        isTyping = false;
                                        isThinking = false;
                                        inAgentLoop = false;
                                        isStreaming = false;
                                    }
                                }
                            } else {
                                currentActionText = "Thinking...";
                                isTyping = false;
                                isThinking = false;
                                inAgentLoop = false;
                                isStreaming = false;
                            }
                        } else {
                            currentActionText = "Thinking...";
                            isTyping = false;
                            isThinking = false;
                            inAgentLoop = false;
                            isStreaming = false;
                        }
                    } else {
                        var errMsg = (xhr.status === 0) ? "Generation cancelled" : ("Ollama request failed (status " + xhr.status + ").");
                        try {
                            if (xhr.responseText) {
                                var errObj = JSON.parse(xhr.responseText);
                                if (errObj && errObj.error) {
                                    var errStr = errObj.error;
                                    try {
                                        var nested = JSON.parse(errStr);
                                        if (nested && nested.error && nested.error.message) errStr = nested.error.message;
                                    } catch (e2) {}
                                    errMsg = "Ollama: " + errStr;
                                }
                            }
                        } catch (e) {}
                        var currentText = chatHistory.get(chatHistory.count - 1).text;
                        if (currentText.trim() === "") {
                            chatHistory.setProperty(chatHistory.count - 1, "text", errMsg);
                        } else {
                            chatHistory.setProperty(chatHistory.count - 1, "text", currentText + "\n\n*[" + errMsg + "]*");
                        }
                        chatHistory.setProperty(chatHistory.count - 1, "isFinished", true);
                        isTyping = false;
                        isThinking = false;
                        inAgentLoop = false;
                        isStreaming = false;
                        saveHistory();
                    }
                }
            }
        };

        var messages = [];
        var enableTools = GlobalConfig.ai.enableCelestialMode;
        var sysPrompt = "You are Orion, an intelligent and helpful AI desktop assistant integrated into Arch Linux with Hyprland and Caelestia shell. You assist the user with programming, homework, desktop questions, and screen inspection. Answer accurately and directly in Vietnamese if asked in Vietnamese.";
        if (enableTools) {
            sysPrompt += "\n\nCRITICAL INSTRUCTIONS FOR TOOL USAGE:" +
                "\n1. WHEN NOT TO USE TOOLS (VERY IMPORTANT): For general knowledge questions, definitions, formulas (such as 'Công thức định lý Pytago', 'Công thức tính tích phân', 'Diện tích hình thang'), math/logic explanations, coding assistance, or casual conversation, DO NOT CALL ANY TOOLS! Answer directly using your own internal knowledge." +
                "\n2. SCREEN ACCESS: ONLY call the take_screenshot tool when the user EXPLICITLY asks to view, check, look at, or solve a problem on their screen (e.g. 'xem màn hình', 'đọc màn hình', 'giúp giải bài trên màn hình', 'chụp vùng này'). NEVER say 'Tôi không thể xem màn hình' when asked about the screen — call take_screenshot instead." +
                "\n3. LOCAL FILES: ONLY call read_file when the user mentions a specific file path, document, or asks to read/inspect a file." +
                "\n4. WEB SEARCH: ONLY call web_search or read_webpage when the user asks for real-time information, current events, recent news, or queries outside your training data." +
                "\n5. DESKTOP SYSTEM CONTROL: ONLY call caelestia_command when the user wants to adjust Caelestia system settings (like wallpaper, color scheme, reload shell). NEVER use caelestia_command for search." +
                "\n6. Be concise, direct, and never execute tools unless the user's prompt actually requires them.";
        }
        
        messages.push({
            "role": "system",
            "content": sysPrompt
        });

        // Sliding context window: send only the last 10 messages before the currently empty message
        var maxHistory = 10;
        var endIdx = chatHistory.count - 1;
        var startIdx = Math.max(0, endIdx - maxHistory);
        for (var i = startIdx; i < endIdx; i++) {
            var msg = chatHistory.get(i);
            if (msg && msg.text && msg.text.trim().length > 0) {
                if (msg.text === "Generation cancelled" || msg.text.indexOf("Ollama request failed") !== -1) {
                    continue;
                }
                var cleanHistoryText = msg.isUser ? msg.text : cleanToolCallsFromText(msg.text);
                if (cleanHistoryText.length > 0) {
                    var msgObj = {
                        "role": msg.isUser ? "user" : "assistant",
                        "content": cleanHistoryText
                    };
                    if (msg.isUser && i === (endIdx - 1) && base64Image) {
                        msgObj["images"] = [base64Image];
                    }
                    messages.push(msgObj);
                }
            }
        }

        if (isSystemToolResult) {
            var toolPrompt = "Dưới đây là kết quả tra cứu/thực thi công cụ cho yêu cầu của người dùng:\n\n" + promptText + "\n\nHãy tổng hợp các thông tin trên và trả lời người dùng một cách rõ ràng, đầy đủ và tự nhiên bằng tiếng Việt. KHÔNG xuất mã JSON hay cú pháp công cụ.";
            var toolMsg = {
                "role": "user",
                "content": toolPrompt
            };
            if (base64Image) {
                toolMsg["images"] = [base64Image];
            }
            messages.push(toolMsg);
        }

        var isVision = (base64Image !== null && base64Image !== "");
        var targetModel = ollamaModel;
        if (isVision) {
            var lowerM = targetModel.toLowerCase();
            if (lowerM.indexOf("vl") === -1 && lowerM.indexOf("vision") === -1 && lowerM.indexOf("moondream") === -1 && lowerM.indexOf("llava") === -1) {
                var foundVision = (root.ollamaModelsList || []).find(n => {
                    var ln = n.toLowerCase();
                    return ln.indexOf("vl") !== -1 || ln.indexOf("vision") !== -1 || ln.indexOf("moondream") !== -1 || ln.indexOf("llava") !== -1;
                });
                if (foundVision) targetModel = foundVision;
            }
        }

        var isThinkingModel = targetModel.indexOf("thinking") !== -1 || targetModel.indexOf("qwen3") !== -1 || targetModel.indexOf("r1") !== -1;
        if (!root.enableDeepThink && isThinkingModel) {
            messages.push({
                "role": "assistant",
                "content": "<think>\n</think>"
            });
        }

        var requestBody = {
            "model": targetModel,
            "messages": messages,
            "stream": true,
            "think": root.enableDeepThink === true,
            "options": {
                "num_ctx": 2048,
                "num_gpu": 24
            }
        };
        
        var isKnownNonTool = targetModel.indexOf("moondream") !== -1 || targetModel.indexOf("llava") !== -1 || targetModel.indexOf("bakllava") !== -1;
        var caps = root.ollamaModelsCaps[targetModel] || [];
        var modelSupportsTools = !isKnownNonTool && ((caps.length === 0) || (caps.indexOf("tools") !== -1));
        
        if (enableTools && modelSupportsTools && !isSystemToolResult && !isVision) {
            requestBody["tools"] = [
                {
                    "type": "function",
                    "function": {
                        "name": "take_screenshot",
                        "description": "Takes a screenshot of the user's active desktop or selected region and performs visual analysis. ONLY call this when the user specifically asks you to inspect, view, check, or solve something currently displayed on their screen.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "query": {
                                    "type": "string",
                                    "description": "Optional specific question or detail to look for on the screen"
                                },
                                "region": {
                                    "type": "boolean",
                                    "description": "Set to true if user asked to snip, crop, select, or khoanh vùng a rectangular area on screen"
                                }
                            }
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "web_search",
                        "description": "Searches the web using DuckDuckGo. Returns the top results with snippets and URLs.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "query": { "type": "string", "description": "The search query" },
                                "page": { "type": "number", "description": "The page number to fetch (1-indexed, default is 1)" }
                            },
                            "required": ["query"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "read_webpage",
                        "description": "Navigates to a specific URL and returns the main text content of the page.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "url": { "type": "string", "description": "The absolute URL to read" }
                            },
                            "required": ["url"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "read_file",
                        "description": "Reads and extracts the content of a local file on the user's system. Supports PDF documents, source code, text files, Markdown, JSON, configs, scripts. Provide the path to the file.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "path": { "type": "string", "description": "The path to the local file to read (e.g. /home/tu/Documents/report.pdf)" }
                            },
                            "required": ["path"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "open_app",
                        "description": "Searches for and launches an application installed on the user's system via its .desktop file.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "app_name": { "type": "string", "description": "The name of the app to launch (e.g. firefox, kitty)" }
                            },
                            "required": ["app_name"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "set_timer",
                        "description": "Sets a timer that will trigger a desktop notification when finished.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "seconds": { "type": "number", "description": "Duration in seconds" },
                                "message": { "type": "string", "description": "Notification message" }
                            },
                            "required": ["seconds", "message"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "get_weather",
                        "description": "Gets the current weather for a specific location.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "location": { "type": "string", "description": "City name" }
                            },
                            "required": ["location"]
                        }
                    }
                },
                {
                    "type": "function",
                    "function": {
                        "name": "caelestia_command",
                        "description": "Execute a Caelestia desktop shell management command (e.g. change color scheme, reload shell, set wallpaper). DO NOT use this for searching the web; use web_search instead.",
                        "parameters": {
                            "type": "object",
                            "properties": {
                                "subcommand": {
                                    "type": "string",
                                    "description": "The subcommand to run",
                                    "enum": ["shell", "toggle", "scheme", "wallpaper", "record", "clipboard", "emoji", "resizer"]
                                },
                                "args": { "type": "string", "description": "Additional arguments to pass to the subcommand" }
                            },
                            "required": ["subcommand"]
                        }
                    }
                }
            ];
        }
        
        isStreaming = true;
        xhr.send(JSON.stringify(requestBody));
    }

    Item {
        id: mainWrapper
        anchors.fill: parent
        anchors.margins: Tokens.padding.medium

        DropArea {
            anchors.fill: parent
            z: 99
            onDropped: drop => {
                if (drop.hasUrls && drop.urls.length > 0) {
                    for (var i = 0; i < drop.urls.length; i++) {
                        var u = drop.urls[i].toString();
                        root.attachFile(u);
                        break;
                    }
                } else if (drop.hasText && drop.text.length > 0) {
                    root.attachFile(drop.text.trim());
                }
            }
        }

        FileDialog {
            id: attachFileDialog
            title: qsTr("Chọn tài liệu để đọc")
            onAccepted: path => {
                root.attachFile(path);
            }
        }

         // Close Button (Đóng Sidebar - Cố định ở góc trên bên phải không bao giờ bị khuất)
         StyledRect {
             id: closeBtn
             anchors.top: parent.top
             anchors.right: parent.right
             width: 32
             height: 32
             z: 12
             radius: Tokens.rounding.full
             color: closeStateLayer.containsMouse ? Colours.palette.m3errorContainer : Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 1)
             border.color: closeStateLayer.containsMouse ? Colours.palette.m3error : Colours.palette.m3outlineVariant
             border.width: 1

             Behavior on color { CAnim {} }
             Behavior on border.color { CAnim {} }

             StateLayer {
                 id: closeStateLayer
                 anchors.fill: parent
                 radius: parent.radius
                 cursorShape: Qt.PointingHandCursor
                 onClicked: {
                     if (root.screenState) {
                         root.screenState.sidebar = false;
                     }
                 }
             }

             MaterialIcon {
                 anchors.centerIn: parent
                 text: "close"
                 font: Tokens.font.icon.small
                 color: closeStateLayer.containsMouse ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSurfaceVariant
             }
         }

         // Mode Switcher Row (Chat / History / Model Selector / Toggles)
         RowLayout {
             id: modeSwitcherRow
             anchors.top: parent.top
             anchors.left: parent.left
             anchors.right: closeBtn.left
             anchors.rightMargin: Tokens.spacing.small
             height: 32
             z: 10
             spacing: Tokens.spacing.extraSmall

             StyledRect {
                 id: modeSwitcherBg
                 implicitWidth: modeRow.width
                 implicitHeight: 32
                 radius: Tokens.rounding.full
                 color: Colours.tPalette.m3surfaceContainer

                 StyledClippingRect {
                     z: -1
                     anchors.fill: parent
                     radius: Tokens.rounding.full
                     ShaderEffectSource {
                         id: switcherBlurSource
                         sourceItem: contentStack
                         sourceRect: {
                             var p = parent.mapToItem(contentStack, 0, 0);
                             return Qt.rect(p.x, p.y, parent.width, parent.height);
                         }
                     }
                     MultiEffect {
                         anchors.fill: parent
                         source: switcherBlurSource
                         blurEnabled: true
                         blurMax: 32
                     }
                 }

                 StyledRect {
                     width: isHistoryTab ? historyTab.width : chatTab.width
                     height: parent.height
                     radius: Tokens.rounding.full
                     color: Colours.palette.m3primary
                     x: isHistoryTab ? historyTab.x : chatTab.x
                     
                     Behavior on x { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                     Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                 }

                 Row {
                     id: modeRow
                     height: parent.height

                     Item {
                         id: chatTab
                         height: parent.height
                         width: !isHistoryTab ? chatContent.implicitWidth + Tokens.padding.small * 2 + 8 : 32

                         Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                         StateLayer {
                             radius: Tokens.rounding.full
                             onClicked: isHistoryTab = false
                         }

                         Row {
                             id: chatContent
                             anchors.centerIn: parent
                             spacing: Tokens.spacing.small
                             MaterialIcon {
                                 anchors.verticalCenter: parent.verticalCenter
                                 text: "chat"
                                 color: !isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                 font: Tokens.font.icon.small
                             }
                             Text {
                                 anchors.verticalCenter: parent.verticalCenter
                                 text: "Chat"
                                 color: !isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                 font: Tokens.font.body.small
                                 visible: !isHistoryTab
                             }
                         }
                     }

                     Item {
                         id: historyTab
                         height: parent.height
                         width: isHistoryTab ? historyContent.implicitWidth + Tokens.padding.small * 2 + 8 : 32

                         Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                         StateLayer {
                             radius: Tokens.rounding.full
                             onClicked: isHistoryTab = true
                         }

                         Row {
                             id: historyContent
                             anchors.centerIn: parent
                             spacing: Tokens.spacing.small
                             MaterialIcon {
                                 anchors.verticalCenter: parent.verticalCenter
                                 text: "history"
                                 color: isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                 font: Tokens.font.icon.small
                             }
                             Text {
                                 anchors.verticalCenter: parent.verticalCenter
                                 text: "History"
                                 color: isHistoryTab ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                                 font: Tokens.font.body.small
                                 visible: isHistoryTab
                             }
                         }
                     }
                 }
             }

             Item { Layout.fillWidth: true } // Spacer pushes Model Selector to the right

             // Model Selector Split Button
             SplitButton {
                 id: modelSelector
                 type: SplitButton.Tonal
                 verticalPadding: 2
                 horizontalPadding: Tokens.padding.extraSmall
                 Layout.preferredWidth: implicitWidth

                 active: menuItems.find(m => m.modelData === GlobalConfig.ai.defaultOllamaModel) ?? menuItems[0] ?? null
                 menu.onItemSelected: item => {
                     GlobalConfig.ai.defaultOllamaModel = item.modelData;
                 }

                 menuItems: modelVariants.instances

                 fallbackIcon: "smart_toy"
                 fallbackText: qsTr("Select Model")
                 stateLayer.disabled: false
                 stateLayer.onClicked: modelSelector.expanded = !modelSelector.expanded

                 Variants {
                     id: modelVariants
                     model: {
                         return root.ollamaModelsList && root.ollamaModelsList.length > 0 ? root.ollamaModelsList : ["llama3", "mistral", "phi3", "gemma"];
                     }

                     delegate: MenuItem {
                         required property string modelData
                         text: modelData
                         activeText: {
                             var name = modelData;
                             if (name.endsWith(":latest")) name = name.slice(0, -7);
                             if (name.length > 8) {
                                 return name.slice(0, 7) + "…";
                             }
                             return name;
                         }
                     }
                 }
             }

             // DeepThink Toggle Button (Tắt / Bật suy nghĩ sâu: Sáng khi BẬT, Tối khi TẮT)
             StyledRect {
                 id: deepThinkToggleBtn
                 Layout.preferredWidth: 32
                 Layout.preferredHeight: 32
                 Layout.alignment: Qt.AlignVCenter
                 radius: Tokens.rounding.full
                 color: root.enableDeepThink ? Colours.palette.m3primary : Colours.layer(Colours.tPalette.m3surfaceContainerLow, 1)
                 border.color: root.enableDeepThink ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                 border.width: root.enableDeepThink ? 1.5 : 1

                 Behavior on color { CAnim {} }
                 Behavior on border.color { CAnim {} }

                 StateLayer {
                     anchors.fill: parent
                     radius: parent.radius
                     cursorShape: Qt.PointingHandCursor
                     onClicked: {
                         root.enableDeepThink = !root.enableDeepThink;
                         Toaster.toast(
                             root.enableDeepThink ? qsTr("DeepThink BẬT (Suy nghĩ sâu)") : qsTr("DeepThink TẮT (Trả lời nhanh)"),
                             root.enableDeepThink ? qsTr("Mô hình sẽ suy luận chi tiết trước khi trả lời") : qsTr("Mô hình sẽ trả lời tức thì sau 1-2 giây"),
                             "psychology"
                         );
                     }
                 }

                 MaterialIcon {
                     anchors.centerIn: parent
                     text: "psychology"
                     font: Tokens.font.icon.small
                     color: root.enableDeepThink ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                     opacity: root.enableDeepThink ? 1.0 : 0.6
                     Behavior on color { CAnim {} }
                     Behavior on opacity { CAnim {} }
                 }
             }

             // Web Search & Tools (Celestial Mode) Toggle Button (Sáng khi BẬT, Tối khi TẮT)
             StyledRect {
                 id: toolsToggleBtn
                 Layout.preferredWidth: 32
                 Layout.preferredHeight: 32
                 Layout.alignment: Qt.AlignVCenter
                 radius: Tokens.rounding.full
                 color: GlobalConfig.ai.enableCelestialMode ? Colours.palette.m3primary : Colours.layer(Colours.tPalette.m3surfaceContainerLow, 1)
                 border.color: GlobalConfig.ai.enableCelestialMode ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
                 border.width: GlobalConfig.ai.enableCelestialMode ? 1.5 : 1
                 
                 Behavior on color { CAnim {} }
                 Behavior on border.color { CAnim {} }

                 StateLayer {
                     anchors.fill: parent
                     radius: parent.radius
                     cursorShape: Qt.PointingHandCursor
                     onClicked: {
                         GlobalConfig.ai.enableCelestialMode = !GlobalConfig.ai.enableCelestialMode;
                         Toaster.toast(
                             GlobalConfig.ai.enableCelestialMode ? qsTr("Celestial Mode BẬT (Web & Tools)") : qsTr("Celestial Mode TẮT"),
                             "",
                             "travel_explore"
                         );
                     }
                 }

                 MaterialIcon {
                     anchors.centerIn: parent
                     text: "travel_explore"
                     font: Tokens.font.icon.small
                     color: GlobalConfig.ai.enableCelestialMode ? Colours.palette.m3onPrimary : Colours.palette.m3outline
                     opacity: GlobalConfig.ai.enableCelestialMode ? 1.0 : 0.6
                     Behavior on color { CAnim {} }
                     Behavior on opacity { CAnim {} }
                 }
             }
         }
         
         Item {
             id: contentStack
             anchors.top: modeSwitcherRow.bottom
             anchors.bottom: parent.bottom
             anchors.left: parent.left
             anchors.right: parent.right
             anchors.topMargin: Tokens.spacing.medium

             // Chat View
             Item {
                 anchors.fill: parent
                 opacity: !isHistoryTab ? 1 : 0
                 visible: opacity > 0
                 Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                 StyledRect {
                     id: ollamaOfflineBanner
                     anchors.top: parent.top
                     anchors.left: parent.left
                     anchors.right: parent.right
                     visible: !root.isOllamaOnline
                     height: visible ? implicitHeight : 0
                     clip: true
                     color: Colours.palette.m3errorContainer
                     radius: Tokens.rounding.medium
                     implicitHeight: offlineRow.implicitHeight + Tokens.padding.small * 2

                     RowLayout {
                         id: offlineRow
                         anchors.fill: parent
                         anchors.margins: Tokens.padding.small
                         spacing: Tokens.spacing.small

                         MaterialIcon {
                             text: "cloud_off"
                             color: Colours.palette.m3onErrorContainer
                             font: Tokens.font.icon.small
                         }

                         StyledText {
                             Layout.fillWidth: true
                             text: qsTr("Ollama is offline")
                             color: Colours.palette.m3onErrorContainer
                             font: Tokens.font.label.medium
                         }

                         TextButton {
                             text: root.isCheckingOllama ? qsTr("Checking...") : qsTr("Start")
                             type: TextButton.Tonal
                             onClicked: root.startOllama()
                         }

                         IconButton {
                             icon: "refresh"
                             type: IconButton.Text
                             onClicked: root.fetchOllamaModels()
                         }
                     }
                 }

                 VerticalFadeListView {
                     id: listView
                     anchors.top: ollamaOfflineBanner.bottom
                     anchors.topMargin: root.isOllamaOnline ? 0 : Tokens.spacing.small
                     anchors.bottom: inputBoxRow.top
                     anchors.left: parent.left
                     anchors.right: parent.right
                     anchors.bottomMargin: Tokens.spacing.medium
                     spacing: Tokens.spacing.medium
                     model: chatHistory
                     boundsBehavior: Flickable.StopAtBounds
                     
                     ColumnLayout {
                         anchors.centerIn: parent
                         opacity: chatHistory.count === 0 && !isTyping && !isThinking ? 1.0 : 0.0
                         visible: opacity > 0
                         Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
                         spacing: Tokens.spacing.large

                         Item {
                             Layout.alignment: Qt.AlignHCenter
                             implicitWidth: 72
                             implicitHeight: 72

                             Logo {
                                 id: emptyStateLogo
                                 anchors.fill: parent
                                 visible: false // hide original for MultiEffect to take over
                             }

                             MultiEffect {
                                 anchors.fill: parent
                                 source: emptyStateLogo
                                 colorization: 1.0
                                 colorizationColor: Colours.palette.m3primary
                             }
                         }

                         StyledText {
                             id: greetingText
                             Layout.alignment: Qt.AlignHCenter
                             Layout.maximumWidth: listView.width - (Tokens.padding.large * 2)
                             horizontalAlignment: Text.AlignHCenter
                             wrapMode: Text.Wrap
                             font: Tokens.font.title.medium
                             color: Colours.palette.m3onSurfaceVariant

                             property var phrases: [
                                 "Ask away, %1!",
                                 "How can I help you today, %1?",
                                 "What's on your mind, %1?",
                                 "Ready when you are, %1!",
                                 "Let's get started, %1.",
                                 "What shall we explore today, %1?",
                                 "I'm all ears, %1!"
                             ]

                             Component.onCompleted: {
                                 var user = Quickshell.env("USER") || "user";
                                 var userCapitalized = user.charAt(0).toUpperCase() + user.slice(1);
                                 var phrase = phrases[Math.floor(Math.random() * phrases.length)];
                                 text = phrase.replace("%1", userCapitalized);
                             }
                         }
                     }

                     ScrollBar.vertical: StyledScrollBar {
                         flickable: listView
                     }

                     footer: Item {
                         width: listView.width
                         readonly property bool isPendingFirstToken: isStreaming && (chatHistory.count === 0 || !(chatHistory.get(chatHistory.count - 1)?.text || "").trim())
                         readonly property bool shouldShowFooter: isThinking || isPendingFirstToken
                         height: shouldShowFooter ? bubbleBg.height + Tokens.spacing.medium : 0
                         visible: opacity > 0
                         opacity: shouldShowFooter ? 1 : 0
                         
                         Behavior on height { Anim { type: Anim.DefaultSpatial } }
                         Behavior on opacity { Anim { type: Anim.DefaultSpatial } }

                         StyledRect {
                             id: bubbleBg
                             y: Tokens.spacing.medium / 2
                             width: Math.min(listView.width * 0.85, footerCol.implicitWidth + Tokens.padding.medium * 2 + 8)
                             height: footerCol.implicitHeight + Tokens.padding.medium * 2
                             radius: Tokens.rounding.large
                             color: Colours.tPalette.m3surfaceContainer

                             // Asymmetric corners
                             topLeftRadius: Tokens.rounding.large
                             topRightRadius: Tokens.rounding.large
                             bottomLeftRadius: 4
                             bottomRightRadius: Tokens.rounding.large

                             Column {
                                 id: footerCol
                                 anchors.fill: parent
                                 anchors.margins: Tokens.padding.medium
                                 spacing: Tokens.spacing.small
                                 
                                 Row {
                                     spacing: Tokens.spacing.small
                                     
                                     LoadingIndicator {
                                         width: 20
                                         height: 20
                                         color: Colours.palette.m3primary
                                     }
                                     
                                     // M3 Expressive Animated Text Wrapper
                                     Item {
                                         width: mainText.implicitWidth
                                         height: mainText.implicitHeight
                                         // The bubble smoothly expands/shrinks as the text width changes
                                         Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                                         
                                         StyledText {
                                             id: mainText
                                             text: displayedText
                                             color: Colours.palette.m3onSurfaceVariant
                                             font: Tokens.font.body.small
                                             
                                             property string displayedText: root.currentActionText
                                             property string nextText: ""

                                             transform: Translate { id: textTrans; y: 0 }
                                             opacity: 1.0

                                             Connections {
                                                 target: root
                                                 function onCurrentActionTextChanged() {
                                                     if (root.currentActionText !== mainText.displayedText) {
                                                         mainText.nextText = root.currentActionText;
                                                         switchAnim.restart();
                                                     }
                                                 }
                                             }

                                             SequentialAnimation {
                                                 id: switchAnim
                                                 ParallelAnimation {
                                                     NumberAnimation { target: textTrans; property: "y"; to: -8; duration: 150; easing.type: Easing.InCubic }
                                                     NumberAnimation { target: mainText; property: "opacity"; to: 0.0; duration: 150; easing.type: Easing.InCubic }
                                                 }
                                                 PropertyAction { target: mainText; property: "displayedText"; value: mainText.nextText }
                                                 PropertyAction { target: textTrans; property: "y"; value: 8 }
                                                 ParallelAnimation {
                                                     NumberAnimation { target: textTrans; property: "y"; to: 0; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
                                                     NumberAnimation { target: mainText; property: "opacity"; to: 1.0; duration: 250; easing.type: Easing.OutQuad }
                                                 }
                                             }

                                             SequentialAnimation {
                                                 running: isThinking && !switchAnim.running
                                                 loops: Animation.Infinite
                                                 NumberAnimation { target: mainText; property: "opacity"; from: 1.0; to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                                                 NumberAnimation { target: mainText; property: "opacity"; from: 0.4; to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                                             }
                                         }
                                     }
                                     
                                     Item {
                                         visible: root.currentThoughtText !== ""
                                         width: Tokens.spacing.medium
                                         height: 1
                                     }
                                     
                                     Item {
                                         visible: root.currentThoughtText !== ""
                                         width: thoughtRowFooter.implicitWidth
                                         height: thoughtRowFooter.implicitHeight
                                         Row {
                                             id: thoughtRowFooter
                                             spacing: Tokens.spacing.small
                                             MaterialIcon {
                                                 text: "expand_more"
                                                 color: Colours.palette.m3onSurfaceVariant
                                                 font: Tokens.font.icon.small
                                                 rotation: root.isThoughtExpanded ? 180 : 0
                                                 Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                             }
                                         }
                                         MouseArea {
                                             anchors.fill: parent
                                             anchors.margins: -10
                                             cursorShape: Qt.PointingHandCursor
                                             onClicked: root.isThoughtExpanded = !root.isThoughtExpanded
                                         }
                                     }
                                 }
                                 Item {
                                     id: footerThoughtContentWrapper
                                     width: footerThoughtContent.width
                                     height: root.isThoughtExpanded ? footerThoughtContent.implicitHeight : 0
                                     clip: true
                                     
                                     Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                                     TextEdit {
                                         id: footerThoughtContent
                                         width: Math.min(implicitWidth, listView.width * 0.85 - Tokens.padding.medium * 2)
                                         textFormat: Text.MarkdownText
                                         text: root.formatMathAndLogic(root.currentThoughtText)
                                         color: Colours.palette.m3onSurfaceVariant
                                         font: Tokens.font.body.small
                                         wrapMode: Text.Wrap
                                         readOnly: true
                                         selectByMouse: true
                                         selectionColor: Colours.palette.m3primary
                                         selectedTextColor: Colours.palette.m3onPrimary
                                         opacity: root.isThoughtExpanded ? 1.0 : 0.0
                                         
                                         Behavior on opacity {
                                             SequentialAnimation {
                                                 PauseAnimation { duration: root.isThoughtExpanded ? 100 : 0 }
                                                 NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                                             }
                                         }
                                     }
                                 }
                             }
                         }
                     }

                     delegate: Item {
                         id: delegateItem

                         required property string text
                         required property bool isUser
                         required property bool isFinished
                         required property string thoughtText

                         width: listView.width - Tokens.padding.large
                         visible: (!delegateItem.isFinished && isThinking) ? false : (delegateItem.text !== "" || delegateItem.thoughtText !== "")
                         height: visible ? bubbleRect.height : 0
                         
                         scale: 0.0
                         opacity: 0.0
                         
                         Component.onCompleted: {
                             popInAnim.start();
                         }
                         
                         ParallelAnimation {
                             id: popInAnim
                             NumberAnimation { target: delegateItem; property: "scale"; from: 0.8; to: 1.0; duration: 300; easing.type: Easing.OutBack }
                             NumberAnimation { target: delegateItem; property: "opacity"; from: 0.0; to: 1.0; duration: 200; easing.type: Easing.OutQuad }
                         }
                         
                         SequentialAnimation {
                             id: popDoneAnim
                             NumberAnimation { target: delegateItem; property: "scale"; from: 1.0; to: 1.02; duration: 100; easing.type: Easing.OutQuad }
                             NumberAnimation { target: delegateItem; property: "scale"; from: 1.02; to: 1.0; duration: 150; easing.type: Easing.OutSine }
                         }
                         
                         onIsFinishedChanged: {
                             if (isFinished) popDoneAnim.start();
                         }

                         StyledRect {
                             id: bubbleRect
                             readonly property real maxBubbleWidth: delegateItem.width * 0.85
                             anchors.right: delegateItem.isUser ? parent.right : undefined
                             anchors.left: delegateItem.isUser ? undefined : parent.left
                             
                             // Let implicitWidth dictate width (with +8 buffer for layout engine) to stop short words from splitting line breaks
                             width: Math.min(maxBubbleWidth, bubbleLayout.implicitWidth + Tokens.padding.medium * 2 + 8)
                             height: bubbleLayout.implicitHeight + Tokens.padding.medium * 2
                             radius: Tokens.rounding.large
                             color: delegateItem.isUser ? Colours.palette.m3primary : Colours.tPalette.m3surfaceContainer

                             // Asymmetric corners
                             topLeftRadius: Tokens.rounding.large
                             topRightRadius: Tokens.rounding.large
                             bottomLeftRadius: delegateItem.isUser ? Tokens.rounding.large : 4
                             bottomRightRadius: delegateItem.isUser ? 4 : Tokens.rounding.large
                             
                             Column {
                                 id: bubbleLayout
                                 anchors.top: parent.top
                                 anchors.left: parent.left
                                 anchors.margins: Tokens.padding.medium
                                 spacing: Tokens.spacing.small

                                 property string delegateThought: delegateItem.thoughtText
                                 property bool isExpanded: false

                                 Item {
                                     visible: bubbleLayout.delegateThought !== ""
                                     implicitWidth: thoughtRow.implicitWidth
                                     implicitHeight: thoughtRow.implicitHeight
                                     height: visible ? implicitHeight : 0

                                     Row {
                                         id: thoughtRow
                                         spacing: Tokens.spacing.small
                                         Text {
                                             text: "Thought Process"
                                             color: Colours.palette.m3onSurfaceVariant
                                             font: Tokens.font.body.small
                                         }
                                         MaterialIcon {
                                             id: thoughtArrow
                                             text: "expand_more"
                                             color: Colours.palette.m3onSurfaceVariant
                                             font: Tokens.font.icon.small
                                             rotation: bubbleLayout.isExpanded ? 180 : 0
                                             Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                                         }
                                     }
                                     MouseArea {
                                         anchors.fill: parent
                                         cursorShape: Qt.PointingHandCursor
                                         onClicked: bubbleLayout.isExpanded = !bubbleLayout.isExpanded
                                     }
                                 }

                                 Item {
                                     id: thoughtContentWrapper
                                     width: thoughtContent.width
                                     height: bubbleLayout.isExpanded ? thoughtContent.implicitHeight : 0
                                     clip: true
                                     
                                     Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                                     TextEdit {
                                         id: thoughtContent
                                         width: Math.min(implicitWidth, bubbleRect.maxBubbleWidth - Tokens.padding.medium * 2)
                                         textFormat: Text.MarkdownText
                                         
                                         property string fullThought: root.formatMathAndLogic(bubbleLayout.delegateThought)
                                         
                                         property bool cursorVisible: true
                                         Timer {
                                             running: !delegateItem.isFinished
                                             repeat: true
                                             interval: 400
                                             onTriggered: thoughtContent.cursorVisible = !thoughtContent.cursorVisible
                                         }
                                         
                                         text: delegateItem.isFinished ? fullThought : fullThought + (cursorVisible ? "▌" : "")
                                         
                                         color: Colours.palette.m3onSurfaceVariant
                                         font: Tokens.font.body.small
                                         wrapMode: Text.Wrap
                                         readOnly: true
                                         selectByMouse: true
                                         selectionColor: Colours.palette.m3primary
                                         selectedTextColor: Colours.palette.m3onPrimary
                                         opacity: bubbleLayout.isExpanded ? 1.0 : 0.0
                                         
                                         Behavior on opacity {
                                             SequentialAnimation {
                                                 PauseAnimation { duration: bubbleLayout.isExpanded ? 100 : 0 }
                                                 NumberAnimation { duration: 150; easing.type: Easing.InOutQuad }
                                             }
                                         }
                                     }
                                 }

                                 TextEdit {
                                     id: messageText
                                     textFormat: Text.MarkdownText
                                     width: Math.min(implicitWidth, bubbleRect.maxBubbleWidth - Tokens.padding.medium * 2)
                                     
                                     property string fullText: {
                                         var raw = delegateItem.text !== undefined ? delegateItem.text : "";
                                         // Convert reference-style links [Label]: https://... to inline [Label](https://...)
                                         // In CommonMark / Qt MarkdownText, [Label]: url is treated as an invisible reference definition, causing links to disappear.
                                         var fixedLinks = raw.replace(/\[([^\]]+)\]:\s*(https?:\/\/[^\s\)\<\>]+)/g, "[$1]($2)");
                                         return root.formatMathAndLogic(fixedLinks);
                                     }
                                     
                                     property bool cursorVisible: true
                                     Timer {
                                         running: !delegateItem.isFinished
                                         repeat: true
                                         interval: 400
                                         onTriggered: messageText.cursorVisible = !messageText.cursorVisible
                                     }
                                     
                                     text: delegateItem.isFinished ? fullText : fullText + (cursorVisible ? "▌" : "")
                                     
                                     color: delegateItem.isUser ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                     font: Tokens.font.body.small
                                     wrapMode: Text.Wrap
                                     readOnly: true
                                     selectByMouse: true
                                     selectionColor: Colours.palette.m3primary
                                     selectedTextColor: Colours.palette.m3onPrimary
                                     onLinkActivated: link => Qt.openUrlExternally(link)

                                     MouseArea {
                                         anchors.fill: parent
                                         hoverEnabled: true
                                         cursorShape: messageText.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                                         propagateComposedEvents: true
                                         onClicked: mouse => {
                                             if (messageText.hoveredLink) {
                                                 Qt.openUrlExternally(messageText.hoveredLink);
                                                 mouse.accepted = true;
                                             } else {
                                                 mouse.accepted = false;
                                             }
                                         }
                                         onPressed: mouse => {
                                             if (messageText.hoveredLink) {
                                                 mouse.accepted = true;
                                             } else {
                                                 mouse.accepted = false;
                                             }
                                         }
                                     }
                                 }

                                 Item {
                                     id: bubbleActionContainer
                                     visible: !delegateItem.isUser && delegateItem.isFinished && delegateItem.text.length > 0
                                     width: Math.max(messageText.width, 100)
                                     height: visible ? 24 : 0

                                     Row {
                                         id: bubbleActionRow
                                         anchors.right: parent.right
                                         anchors.verticalCenter: parent.verticalCenter
                                         spacing: Tokens.spacing.small

                                         property bool copied: false
                                         Timer {
                                             id: copyResetTimer
                                             interval: 1500
                                             onTriggered: bubbleActionRow.copied = false
                                         }

                                         Item {
                                             width: 24
                                             height: 24

                                             MaterialIcon {
                                                 anchors.centerIn: parent
                                                 text: bubbleActionRow.copied ? "check" : "content_copy"
                                                 color: bubbleActionRow.copied ? Colours.palette.m3primary : (copyMouse.containsMouse ? Colours.palette.m3onSurface : Colours.palette.m3outline)
                                                 font: Tokens.font.icon.small
                                             }

                                             MouseArea {
                                                 id: copyMouse
                                                 anchors.fill: parent
                                                 cursorShape: Qt.PointingHandCursor
                                                 hoverEnabled: true
                                                 onClicked: {
                                                     Quickshell.clipboardText = root.formatMathAndLogic(delegateItem.text);
                                                     bubbleActionRow.copied = true;
                                                     copyResetTimer.restart();
                                                     Toaster.toast(qsTr("Copied to clipboard"), delegateItem.text.slice(0, 40).replace(/\n/g, " ") + (delegateItem.text.length > 40 ? "..." : ""), "content_copy");
                                                 }
                                             }
                                         }
                                     }
                                 }
                             }
                         }
                     }
                 }

                 // Attached File Chip
                 StyledRect {
                     id: attachedFileChip
                     visible: root.attachedFilePath !== ""
                     anchors.bottom: inputBoxRow.top
                     anchors.left: parent.left
                     anchors.bottomMargin: Tokens.spacing.small
                     z: 11
                     implicitHeight: 32
                     implicitWidth: fileChipRow.implicitWidth + Tokens.padding.medium * 2
                     radius: Tokens.rounding.full
                     color: Colours.palette.m3secondaryContainer

                     RowLayout {
                         id: fileChipRow
                         anchors.centerIn: parent
                         spacing: Tokens.spacing.small

                         MaterialIcon {
                             text: "description"
                             font: Tokens.font.icon.small
                             color: Colours.palette.m3onSecondaryContainer
                         }

                         StyledText {
                             text: root.attachedFileName
                             font: Tokens.font.body.small
                             color: Colours.palette.m3onSecondaryContainer
                             elide: Text.ElideMiddle
                             Layout.maximumWidth: 220
                         }

                         MaterialIcon {
                             text: "close"
                             font: Tokens.font.icon.small
                             color: Colours.palette.m3onSecondaryContainer
                             MouseArea {
                                 anchors.fill: parent
                                 cursorShape: Qt.PointingHandCursor
                                 onClicked: root.clearAttachedFile()
                             }
                         }
                     }
                 }

                 // Input Box Row
                 StyledRect {
                     id: inputBoxRow
                     anchors.bottom: parent.bottom
                     anchors.left: parent.left
                     anchors.right: parent.right
                     z: 10
                     implicitHeight: Math.max(48, inputArea.implicitHeight + Tokens.padding.medium * 2)
                     color: Colours.tPalette.m3surfaceContainer
                     radius: 24

                     StyledClippingRect {
                         z: -1
                         anchors.fill: parent
                         radius: 24
                         ShaderEffectSource {
                             id: inputBlurSource
                             sourceItem: contentStack
                             sourceRect: {
                                 var p = parent.mapToItem(contentStack, 0, 0);
                                 return Qt.rect(p.x, p.y, parent.width, parent.height);
                             }
                         }
                         MultiEffect {
                             anchors.fill: parent
                             source: inputBlurSource
                             blurEnabled: true
                             blurMax: 32
                         }
                     }

                     TapHandler {
                         onTapped: inputArea.forceActiveFocus()
                     }

                     RowLayout {
                         anchors.fill: parent
                         anchors.leftMargin: Tokens.padding.large
                         anchors.rightMargin: Tokens.padding.small
                         spacing: Tokens.spacing.small

                         ScrollView {
                             id: inputScroll
                             Layout.fillWidth: true
                             Layout.fillHeight: true
                             
                             TextArea {
                                 id: inputArea
                                 focus: true
                                 activeFocusOnTab: true
                                 verticalAlignment: TextInput.AlignVCenter
                                 placeholderText: qsTr("Ask assistant...")
                                 color: Colours.palette.m3onSurface
                                 placeholderTextColor: Colours.palette.m3outline
                                 font: Tokens.font.body.small
                                 wrapMode: Text.Wrap
                                 selectByMouse: true
                                 background: null

                                 Keys.onPressed: event => {
                                     if (event.key === Qt.Key_Return && !(event.modifiers & Qt.ShiftModifier)) {
                                         if (inputArea.inputMethodComposing) return;
                                         if (inputArea.text.trim().length > 0 || root.attachedFilePath !== "") {
                                             event.accepted = true;
                                             root.sendPrompt(inputArea.text);
                                             inputArea.clear();
                                         }
                                     }
                                 }
                             }
                         }

                         // Attach File Button
                         Item {
                             Layout.preferredWidth: 36
                             Layout.preferredHeight: 36
                             visible: !root.isTyping

                             MaterialShape {
                                 anchors.fill: parent
                                 color: attachBtnMouse.containsMouse ? Colours.layer(Colours.tPalette.m3surfaceContainerHighest, 2) : Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 1)
                                 shape: MaterialShape.Circle
                                 scale: attachBtnMouse.pressed ? 0.6 : attachBtnMouse.containsMouse ? 0.85 : 0.75

                                 Behavior on scale { Anim { type: Anim.FastSpatial } }
                                 Behavior on color { CAnim {} }

                                 MouseArea {
                                     id: attachBtnMouse
                                     anchors.fill: parent
                                     hoverEnabled: true
                                     cursorShape: Qt.PointingHandCursor
                                     onClicked: attachFileDialog.open()
                                 }
                             }

                             MaterialIcon {
                                 anchors.centerIn: parent
                                 text: "attach_file"
                                 color: attachBtnMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                 font: Tokens.font.icon.small
                             }
                         }

                         Item {
                             Layout.preferredWidth: 36
                             Layout.preferredHeight: 36
                             visible: !root.isTyping && GlobalConfig.ai.enableCelestialMode

                             MaterialShape {
                                 anchors.fill: parent
                                 color: regionBtnMouse.containsMouse ? Colours.layer(Colours.tPalette.m3surfaceContainerHighest, 2) : Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 1)
                                 shape: MaterialShape.Circle
                                 scale: regionBtnMouse.pressed ? 0.6 : regionBtnMouse.containsMouse ? 0.85 : 0.75

                                 Behavior on scale { Anim { type: Anim.FastSpatial } }
                                 Behavior on color { CAnim {} }

                                 MouseArea {
                                     id: regionBtnMouse
                                     anchors.fill: parent
                                     hoverEnabled: true
                                     cursorShape: Qt.PointingHandCursor
                                     onClicked: {
                                         root.startRegionSnip();
                                     }
                                 }
                             }

                             MaterialIcon {
                                 anchors.centerIn: parent
                                 text: "screenshot_region"
                                 color: regionBtnMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                 font: Tokens.font.icon.small
                             }
                         }

                         Item {
                             Layout.preferredWidth: 36
                             Layout.preferredHeight: 36
                             visible: !root.isTyping && GlobalConfig.ai.enableCelestialMode

                             MaterialShape {
                                 anchors.fill: parent
                                 color: screenBtnMouse.containsMouse ? Colours.layer(Colours.tPalette.m3surfaceContainerHighest, 2) : Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 1)
                                 shape: MaterialShape.Circle
                                 scale: screenBtnMouse.pressed ? 0.6 : screenBtnMouse.containsMouse ? 0.85 : 0.75

                                 Behavior on scale { Anim { type: Anim.FastSpatial } }
                                 Behavior on color { CAnim {} }

                                 MouseArea {
                                     id: screenBtnMouse
                                     anchors.fill: parent
                                     hoverEnabled: true
                                     cursorShape: Qt.PointingHandCursor
                                     onClicked: {
                                         var query = inputArea.text.trim();
                                         var prompt = query.length > 0 ? query : "Hãy xem và phân tích màn hình hiện tại của tôi";
                                         inputArea.clear();
                                         root.sendPrompt(prompt);
                                     }
                                 }
                             }

                             MaterialIcon {
                                 anchors.centerIn: parent
                                 text: "screenshot_monitor"
                                 color: screenBtnMouse.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                                 font: Tokens.font.icon.small
                             }
                         }

                         Item {
                             Layout.preferredWidth: 36
                             Layout.preferredHeight: 36

                             MaterialShape {
                                 anchors.fill: parent
                                 color: root.isTyping ? Colours.palette.m3error : ((inputArea.text.length > 0 || root.attachedFilePath !== "") ? Colours.palette.m3primary : Colours.layer(Colours.tPalette.m3surfaceContainerHigh, 2))
                                 shape: root.isTyping ? MaterialShape.Cookie4Sided : MaterialShape.Circle
                                 scale: (inputArea.text.length === 0 && root.attachedFilePath === "" && !root.isTyping) ? 1 : sendMouse.pressed ? 0.6 : sendMouse.containsMouse ? 0.8 : 0.7
                                 rotation: 0
                                 
                                 Behavior on scale { Anim { type: Anim.FastSpatial } }
                                 Behavior on color { CAnim {} }

                                 MouseArea {
                                     id: sendMouse
                                     anchors.fill: parent
                                     hoverEnabled: true
                                     cursorShape: (inputArea.text.length > 0 || root.attachedFilePath !== "" || root.isTyping) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                     onClicked: {
                                         if (root.isTyping) {
                                             if (root.currentRequest) {
                                                 root.currentRequest.abort();
                                             }
                                             root.isTyping = false;
                                             root.isThinking = false;
                                             root.inAgentLoop = false;
                                             typingTimer.stop();
                                             chatHistory.setProperty(chatHistory.count - 1, "isFinished", true);
                                             saveHistory();
                                         } else if (inputArea.text.trim().length > 0 || root.attachedFilePath !== "") {
                                             root.sendPrompt(inputArea.text);
                                             inputArea.clear();
                                         }
                                     }
                                 }
                             }

                             MaterialIcon {
                                 anchors.centerIn: parent
                                 text: root.isTyping ? "stop" : "arrow_upward"
                                 color: root.isTyping ? Colours.palette.m3onError : ((inputArea.text.length > 0 || root.attachedFilePath !== "") ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant)
                                 font: Tokens.font.icon.small
                                 opacity: (inputArea.text.length > 0 || root.attachedFilePath !== "" || root.isTyping) ? 1.0 : 0.4
                                 Behavior on opacity { Anim { type: Anim.DefaultEffects } }
                                 Behavior on color { CAnim {} }
                             }
                         }
                     }
                 }
             }

             // History Grid View
             Item {
                 anchors.fill: parent
                 opacity: isHistoryTab ? 1 : 0
                 visible: opacity > 0
                 Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

                 GridView {
                     anchors.top: parent.top
                     anchors.left: parent.left
                     anchors.right: parent.right
                     anchors.bottom: newChatButton.top
                     anchors.bottomMargin: Tokens.spacing.medium
                     
                     cellWidth: width / 2
                     cellHeight: 90
                     model: historySessionsModel

                     delegate: Item {
                         required property var model
                         property string chatId: model && model.id ? String(model.id) : ""
                         property string chatTitle: model && model.title ? String(model.title) : ""

                         width: GridView.view.cellWidth
                         height: GridView.view.cellHeight

                         StyledRect {
                             anchors.fill: parent
                             anchors.margins: Tokens.spacing.small
                             radius: Tokens.rounding.medium
                             color: Colours.tPalette.m3surfaceContainerHigh

                             StateLayer {
                                 radius: Tokens.rounding.medium
                                 onClicked: loadChat(chatId)
                             }

                             RowLayout {
                                 anchors.fill: parent
                                 anchors.margins: Tokens.padding.small
                                 spacing: Tokens.spacing.medium

                                 StyledRect {
                                     Layout.preferredWidth: 32
                                     Layout.preferredHeight: 32
                                     radius: 16
                                     color: Colours.tPalette.m3surfaceContainerHighest

                                     MaterialIcon {
                                         anchors.centerIn: parent
                                         text: "chat"
                                         color: Colours.palette.m3onSurfaceVariant
                                         font: Tokens.font.icon.small
                                     }
                                 }

                                 ColumnLayout {
                                     Layout.fillWidth: true
                                     spacing: 0

                                     Text {
                                         Layout.fillWidth: true
                                         Layout.alignment: Qt.AlignVCenter
                                         text: chatTitle ? chatTitle : "New Chat"
                                         color: Colours.palette.m3onSurface
                                         font: Tokens.font.label.small
                                         elide: Text.ElideRight
                                          wrapMode: Text.Wrap
                                          maximumLineCount: 3
                                     }
                                 }

                                 Item {
                                     Layout.alignment: Qt.AlignTop | Qt.AlignRight
                                     Layout.preferredWidth: 24
                                     Layout.preferredHeight: 24
                                     
                                     StyledRect {
                                         anchors.fill: parent
                                         radius: 12
                                         color: Colours.palette.m3onSurfaceVariant
                                         opacity: deleteMouseArea.containsMouse ? 0.12 : 0.0
                                         Behavior on opacity { NumberAnimation { duration: 150 } }
                                     }

                                     MaterialIcon {
                                         anchors.centerIn: parent
                                         text: "close"
                                         font: Tokens.font.icon.small
                                         color: Colours.palette.m3onSurfaceVariant
                                     }

                                     MouseArea {
                                         id: deleteMouseArea
                                         anchors.fill: parent
                                         hoverEnabled: true
                                         cursorShape: Qt.PointingHandCursor
                                         onClicked: deleteChat(chatId)
                                     }
                                 }
                             }
                         }
                     }
                 }

                 // "Clear All" button
                 StyledRect {
                     id: clearAllButton
                     anchors.bottom: parent.bottom
                     anchors.left: parent.left
                     width: clearAllLayout.implicitWidth + Tokens.padding.large * 2
                     height: 32
                     radius: 16
                     color: Colours.palette.m3errorContainer

                     StateLayer {
                         radius: 16
                         onClicked: clearAllHistory()
                     }

                     RowLayout {
                         id: clearAllLayout
                         anchors.centerIn: parent
                         spacing: Tokens.spacing.small
                         MaterialIcon {
                             text: "delete"
                             color: Colours.palette.m3onErrorContainer
                             font: Tokens.font.icon.small
                         }
                         Text {
                             text: "Clear All"
                             color: Colours.palette.m3onErrorContainer
                             font: Tokens.font.body.small
                         }
                     }
                 }

                 // "New Chat" button
                 StyledRect {
                     id: newChatButton
                     anchors.bottom: parent.bottom
                     anchors.right: parent.right
                     width: newChatLayout.implicitWidth + Tokens.padding.large * 2
                     height: 32
                     radius: 16
                     color: Colours.palette.m3primaryContainer

                     StateLayer {
                         radius: 16
                         onClicked: createNewChat()
                     }

                     RowLayout {
                         id: newChatLayout
                         anchors.centerIn: parent
                         spacing: Tokens.spacing.small
                         MaterialIcon {
                             text: "add"
                             color: Colours.palette.m3onPrimaryContainer
                             font: Tokens.font.icon.small
                         }
                         Text {
                             text: "New Chat"
                             color: Colours.palette.m3onPrimaryContainer
                             font: Tokens.font.body.small
                         }
                     }
                 }
             }
         }
    }
}