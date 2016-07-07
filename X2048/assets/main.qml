
import bb.cascades 1.3
import bb.system 1.2
import bb.multimedia 1.2
Page {
    property bool undo: _app.getValue("unlocked", "false") === "true"
    property bool sound: _app.getValue("sound", "false") === "true"
    property double vol: parseFloat(_app.getValue("vol", "1.0"))

    property variant importsheet: null
    id: gamepage
    Menu.definition: MenuDefinition {
        helpAction: HelpActionItem {
            title: qsTr("Tutorial") + Retranslate.onLocaleOrLanguageChanged
            onTriggered: {
                var tut = Qt.createComponent("tutorial.qml").createObject(gamepage);
                tut.open();
            }
        }
        settingsAction: SettingsActionItem {
            title: qsTr("Settings") + Retranslate.onLocaleOrLanguageChanged
            onTriggered: {
                var setsheet = Qt.createComponent("settings.qml").createObject(gamepage);
                setsheet.updated.connect(reloadSettings);
                setsheet.closed.connect(sheetclose);
                setsheet.requestRESET.connect(requestRESET);
                setsheet.controllerchanged.connect(controller);
                setsheet.open();
            }
        }
        actions: [
            ActionItem {
                title: qsTr("Review") + Retranslate.onLocaleOrLanguageChanged
                onTriggered: {
                    Qt.openUrlExternally("http://appworld.blackberry.com/webstore/content/50976889")
                }
                imageSource: "asset:///2048/img/ic_browser.png"
            },
            ActionItem {
                title: qsTr("New Game") + Retranslate.onLocaleOrLanguageChanged
                onTriggered: {
                    game.post({
                            "type": "newgame"
                        })
                }
                imageSource: "asset:///2048/img/ic_newgame.png"
            },
            ActionItem {
                title: qsTr("Screenshot") + Retranslate.onLocaleOrLanguageChanged
                imageSource: "asset:///2048/img/ic_camera.png"
                onTriggered: {
                    _app.requestScreenshot()
                }
            }
        ]
    }
    onCreationCompleted: {
        _app.setValue("unlocked", "true");
        Application.setCover(multicover);
        Application.thumbnail.connect(savestate) //保存进度
        _app.timeout.connect(take_a_shot);
        if (_app.readTextFile("data/2048game.txt").length > 0) {
            importsheet = Qt.createComponent("import.qml").createObject(gamepage);
            importsheet.beginimport.connect(importRecords);
            importsheet.open();
        } else if (_app.getValue("firstrun", "true") === "true") {
            var tut = Qt.createComponent("tutorial.qml").createObject(gamepage);
            tut.open();
        }
    }
    function take_a_shot() {
        var filename = screenshot.captureWindow("file:data/screenshot.png", Application.mainWindow.handle);
        _app.shareFile(filename)
    }
    function savestate() {

        multicover.update();
        game.post({
                "type": "save"
            })
    }
    function importRecords() {
        if (importsheet) {
            importsheet.close();
        }
        var data = _app.readTextFile("data/2048game.txt");
        _app.deleteFile("data/2048game.txt");
        console.log("Read Former Record: " + data);
        game.post({
                "type": "update",
                "data": data
            })
    }
    function sheetclose() {
        game.requestFocus()
        gamepage.vol = parseFloat(_app.getValue("vol", "1.0"));
        gamepage.sound = _app.getValue("sound", "false") === "true";
    }
    function requestRESET() {
        game.post({
                "type": "reset"
            })
        game.post({
                "type": "newgame"
        })
        sst_reseted.show();
    }
    function controller() {

    }
    function reloadSettings() {
        game.post({
                "type": "init",
                "content": {
                    "lang": _app.getLang(),
                    "undo": _app.getValue("unlocked", "false"),
                    "theme": _app.getValue("theme", "bright"),
                    "speed": _app.getValue("speed", "normal")
                }
            });
        gamepage.undo = _app.getValue("unlocked", "false") === "true";

    }
    attachedObjects: [
        Screenshot {
            id: screenshot
        },
        MultiCover {
            onCreationCompleted: {
                update()
            }
            id: multicover
            SceneCover {
                id: bigCover
                // Use this cover when a large cover is required
                MultiCover.level: CoverDetailLevel.High
                content: Cover {
                    id: bigc
                }
                function update(c, b) {
                    bigc.bestscore = b
                    bigc.currentscore = c
                }
            }

            SceneCover {
                id: smallCover
                // Use this cover when a small cover is required
                MultiCover.level: CoverDetailLevel.Medium
                content: Cover {
                    id: smallc
                    smallcover: true
                }
                function update(c, b) {
                    smallc.bestscore = b
                    smallc.currentscore = c
                }
            }

            function update() {
                console.log("cover update")
                bigCover.update(game.currentscore, game.bestscore)
                smallCover.update(game.currentscore, game.bestscore)
            }
        },
        SystemToast {
            id: sst_reseted
            body: "RESET COMPLETE"
        }

    ]
    function play(audiotype) {
        if (sound) {
            _app.play(audiotype);
        }
    }
    Container {
        animations: [
            FadeTransition {
                id: fadeoplayer
                target: oplayer
                fromOpacity: 1.0
                toOpacity: 0
                delay: 100
                duration: 300
            },
            FadeTransition {
                id: gameover
                target: gameoverpane
                fromOpacity: 0
                toOpacity: 0.8
                duration: 500
                onEnded: {
                    btncontinue.requestFocus();
                }
            },
            FadeTransition {
                id: take_shot
                target: gameoverpane
                toOpacity: 0
                onEnded: {
                    var filename = screenshot.captureWindow("file:data/screenshot.png", Application.mainWindow.handle);
                    _app.shareFile(filename);
                    after_shot.play()
                }
                duration: 300
            },
            FadeTransition {
                id: after_shot
                target: gameoverpane
                toOpacity: 0.8
                duration: 300
            }
        ]
        preferredHeight: DisplayInfo.height
        preferredWidth: DisplayInfo.width
        layout: DockLayout {
        }
        implicitLayoutAnimationsEnabled: false
        Game {
            id: game

            onReady: {
                fadeoplayer.play()
                requestFocus()
            }
            onPlayaudio: {
                play(t);
            }
            onGameover: {
                gameoverpane.win = a;
                gameoverpane.score = b;
                gameoverpane.best = c;
                gameover.play()
            }
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Fill
            preferredHeight: DisplayInfo.height
        }
        Container {
            id: oplayer
            preferredHeight: DisplayInfo.height
            preferredWidth: DisplayInfo.width
            background: Color.Black
            opacity: 1.0
            visible: opacity > 0
        }
        Container {
            id: gameoverpane
            property bool win: false
            property int score: 0
            property int best: 0
            preferredHeight: DisplayInfo.height
            preferredWidth: DisplayInfo.width
            background: Color.Black
            opacity: 0
            visible: opacity > 0
            layout: DockLayout {

            }
            topPadding: 20.0
            leftPadding: 20.0
            rightPadding: 20.0
            bottomPadding: 20.0
            Container {
                verticalAlignment: VerticalAlignment.Center
                horizontalAlignment: HorizontalAlignment.Center
                Label {
                    textStyle.fontSize: FontSize.XXLarge
                    textStyle.fontWeight: FontWeight.Bold
                    text: gameoverpane.win ? qsTr("You Win") + Retranslate.onLocaleOrLanguageChanged : qsTr("Game Over") + Retranslate.onLocaleOrLanguageChanged
                    verticalAlignment: VerticalAlignment.Center
                    horizontalAlignment: HorizontalAlignment.Center
                    textStyle.color: Color.White
                }
                Label {
                    text: "Score: " + gameoverpane.score
                    textStyle.color: Color.LightGray
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                }
                Label {
                    text: "Best: " + gameoverpane.best
                    textStyle.color: Color.LightGray
                    verticalAlignment: VerticalAlignment.Center
                    horizontalAlignment: HorizontalAlignment.Center
                }
                Button {
                    id: btncontinue
                    text: qsTr("Continue") + Retranslate.onLocaleOrLanguageChanged
                    visible: gameoverpane.win
                    verticalAlignment: VerticalAlignment.Center
                    horizontalAlignment: HorizontalAlignment.Fill
                    onClicked: {
                        gameoverpane.opacity = 0;
                        game.post({
                                "type": "continue"
                            })
                    }
                }
                Button {
                    text: qsTr("Restart") + Retranslate.onLocaleOrLanguageChanged
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center
                    visible: ! gameoverpane.win
                    onClicked: {
                        gameoverpane.opacity = 0;
                        game.post({
                                "type": "newgame"
                            })
                    }
                }
                Button {
                    text: qsTr("Undo") + Retranslate.onLocaleOrLanguageChanged
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center
                    visible: (! gameoverpane.win) && gamepage.undo
                    onClicked: {
                        gameoverpane.opacity = 0;
                        game.post({
                                "type": "undo"
                            })
                    }
                }
                Button {
                    text: qsTr("Share Screenshot") + Retranslate.onLocaleOrLanguageChanged
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Center
                    onClicked: {
                        take_shot.play()
                    }
                }
            }
        }
    }
}
