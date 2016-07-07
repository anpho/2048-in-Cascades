import bb.cascades 1.2
import bb.system 1.0
import bb.device 1.2
WebView {
    property string currentscore: ""
    property string bestscore: ""
    onCreationCompleted: {

    }
    signal ready
    signal gameover(bool a, string b, string c)
    signal playaudio(string t)
    function post(obj) {
        postMessage(JSON.stringify(obj));
        requestFocus()
    }
    url: hi.isPhysicalKeyboardDevice ? "local:///assets/2048/index.html" : "local:///assets/2048/z10.html"
    settings.webInspectorEnabled: true
    onMessageReceived: {
        var msg = message.data;
        console.log(msg);
        msg = JSON.parse(msg);
        if (msg.type === 'event') {
            if (msg.content === 'ready') {
                post({
                        "type": "init",
                        "content": {
                            "lang": _app.getLang(),
                            "undo": _app.getValue("unlocked", "false")
                        }
                    });
                ready();
                requestFocus()
            } else if (msg.content === 'init_done') {

            }
        } else if (msg.type === 'req') {
            //app.send("req", "undo")
            if (msg.content === 'undo') {
                sst.show()
            } else if (msg.content == 'restart') {
                post({
                        "type": "newgame"
                    })
            }
        } else if (msg.type === 'gameover') {
            playaudio("win");
            gameover(msg.content.win, msg.content.score, msg.content.best)
        } else if (msg.type === 'audio') {
            playaudio(msg.content);
        } else if (msg.type === 'updatescore') {
            currentscore = msg.content.cur;
            bestscore = msg.content.best;
        }
    }
    implicitLayoutAnimationsEnabled: false
    focusPolicy: FocusPolicy.KeyAndTouch
    attachedObjects: [
        SystemToast {
            id: sst
            body: qsTr("Please go to Settings page to unlock this feature.") + Retranslate.onLocaleOrLanguageChanged
        },
        HardwareInfo {
            id: hi
        }
    ]
    verticalAlignment: VerticalAlignment.Fill
    horizontalAlignment: HorizontalAlignment.Fill
    settings.userStyleSheetLocation: "asset:///tune.css"
    settings.defaultFontSize: 28
    settings.textAutosizingEnabled: false
    settings.zoomToFitEnabled: true
}
