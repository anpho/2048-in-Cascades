import bb.cascades 1.2
import bb.platform 1.2
import bb.system 1.2
import bb.multimedia 1.2
Sheet {
    id: settingsheet
    signal updated
    signal controllerchanged
    signal requestRESET
    Page {
        actions: [
            ActionItem {
                title: qsTr("Bug Report") + Retranslate.onLocaleOrLanguageChanged
                imageSource: "asset:///2048/img/ic_feedback.png"
                ActionBar.placement: ActionBarPlacement.OnBar
                onTriggered: {
                    var issue = Qt.createComponent("webviewer.qml").createObject(settingsheet);
                    issue.uri = "https://github.com/anpho/2048-in-Cascades/issues"
                    issue.open()
                }
            },
            ActionItem {
                imageSource: "asset:///2048/img/ic_map.png"
                title: qsTr("Submit Translation") + Retranslate.onLocaleOrLanguageChanged
                ActionBar.placement: ActionBarPlacement.Default
                onTriggered: {
                    Qt.openUrlExternally("https://github.com/anpho/2048-in-Cascades")
                }
            },
            ActionItem {
                imageSource: "asset:///2048/img/ic_clear.png"
                title: qsTr("RESET GAME DATA") + Retranslate.onLocaleOrLanguageChanged
                ActionBar.placement: ActionBarPlacement.InOverflow
                onTriggered: {
                    resetGameDialog.show()
                }
                attachedObjects: [
                    SystemDialog {
                        id: resetGameDialog
                        title: qsTr("RESET GAME DATA") + Retranslate.onLocaleOrLanguageChanged
                        body: qsTr("Are you sure you want to reset your game data? This will erease your current game status and best score record, which is not recoverable.") + Retranslate.onLocaleOrLanguageChanged
                        includeRememberMe: false
                        customButton.enabled: false
                        confirmButton.enabled: true
                        cancelButton.enabled: true
                        defaultButton: resetGameDialog.cancelButton
                        onFinished: {
                            if (value == SystemUiResult.ConfirmButtonSelection) {
                                requestRESET();
                                settingsheet.close();
                            }
                        }
                    }
                ]
            }
        ]
        attachedObjects: [
            TextStyleDefinition {
                id: tip
                fontSize: FontSize.Small
                fontStyle: FontStyle.Normal
                textAlign: TextAlign.Left
            }
        ]
        titleBar: TitleBar {
            title: qsTr("Settings") + Retranslate.onLocaleOrLanguageChanged
            dismissAction: ActionItem {
                onTriggered: {
                    settingsheet.close()
                }
                title: qsTr("Back") + Retranslate.onLocaleOrLanguageChanged
            }
        }

        ScrollView {
            Container {
                leftPadding: 20
                rightPadding: leftPadding
                Header {
                    title: qsTr("Language") + Retranslate.onLocaleOrLanguageChanged
                    subtitle: ""
                }
                Label {
                    text: qsTr("You may specify a different language here, unsupported language would be displayed as English.") + Retranslate.onLocaleOrLanguageChanged
                    textStyle.base: tip.style
                    multiline: true
                    textFit.mode: LabelTextFitMode.Default
                    textStyle.textAlign: TextAlign.Left
                }
                DropDown {
                    onCreationCompleted: {
                        var l = _app.getValue("lang", _app.getLang());
                        switch (l) {
                            case "zh_CN":
                                setSelectedOption(zh_CN)
                                break;
                            case "zh_TW":
                                setSelectedOption(zh_TW)
                                break;
                            case "id_ID":
                                setSelectedOption(id_ID)
                                break;
                            case "fr_FR":
                                setSelectedOption(fr_FR)
                                break;
                            case "es_ES":
                                setSelectedOption(es_ES)
                                break;
                            case "it_IT":
                                setSelectedOption(it_IT)
                                break;
                            case "de_DE":
                                setSelectedOption(de_DE)
                                break;
                            case "cs_CZ":
                                setSelectedOption(cs_CZ)
                                break;
                            case "ru_RU":
                                setSelectedOption(ru_RU)
                                break;
                            default:
                                setSelectedOption(en_US)
                        }
                    }
                    onSelectedOptionChanged: {

                        _app.setValue("lang", selectedOption.value)
                        updated();
                    }
                    options: [
                        Option {
                            text: qsTr("Simplified Chinese") + Retranslate.onLocaleOrLanguageChanged
                            id: zh_CN
                            value: "zh_CN"
                            imageSource: "asset:///flag/CN.png"
                        },
                        Option {
                            text: qsTr("Traditional Chinese") + Retranslate.onLocaleOrLanguageChanged
                            id: zh_TW
                            value: "zh_TW"
                            imageSource: "asset:///flag/TW.png"
                        },
                        Option {
                            text: qsTr("English") + Retranslate.onLocaleOrLanguageChanged
                            id: en_US
                            value: "en_US"
                            imageSource: "asset:///flag/EN.png"
                        },
                        Option {
                            text: qsTr("Indonesian") + Retranslate.onLocaleOrLanguageChanged
                            id: id_ID
                            value: "id_ID"
                            imageSource: "asset:///flag/ID.png"
                        },
                        Option {
                            text: qsTr("Français") + Retranslate.onLocaleOrLanguageChanged
                            id: fr_FR
                            value: "fr_FR"
                            imageSource: "asset:///flag/FR.png"
                        },
                        Option {
                            text: qsTr("Spanish") + Retranslate.onLocaleOrLanguageChanged
                            id: es_ES
                            value: "es_ES"
                            imageSource: "asset:///flag/ES.png"
                        },
                        Option {
                            text: qsTr("Italiano") + Retranslate.onLocaleOrLanguageChanged
                            id: it_IT
                            value: "it_IT"
                            imageSource: "asset:///flag/IT.png"
                        },
                        Option {
                            text: qsTr("Deutsch") + Retranslate.onLocaleOrLanguageChanged
                            id: de_DE
                            value: "de_DE"
                            imageSource: "asset:///flag/DE.png"
                        },
                        Option {
                            text: qsTr("Czech") + Retranslate.onLocaleOrLanguageChanged
                            id: cs_CZ
                            value: "cs_CZ"
                            imageSource: "asset:///flag/CZ.png"
                        },
                        Option {
                            text: qsTr("Russian") + Retranslate.onLocaleOrLanguageChanged
                            id: ru_RU
                            value: "ru_RU"
                            imageSource: "asset:///flag/RU.png"
                        }
                    ]
                    selectedIndex: -1
                }

                Header {
                    title: qsTr("Animation Speed") + Retranslate.onLocaleOrLanguageChanged
                }
                Label {
                    textStyle.base: tip.style
                    text: qsTr("Choose the animation speed.") + Retranslate.onLocaleOrLanguageChanged
                    multiline: true
                }
                DropDown {
                    options: [
                        Option {
                            text: qsTr("Slow") + Retranslate.onLocaleOrLanguageChanged
                            value: "slow"
                            id: slow
                        },
                        Option {
                            text: qsTr("Normal") + Retranslate.onLocaleOrLanguageChanged
                            value: "normal"
                            id: normal
                        },
                        Option {
                            text: qsTr("Fast") + Retranslate.onLocaleOrLanguageChanged
                            value: "fast"
                            id: fast
                        }
                    ]
                    onCreationCompleted: {
                        var l = _app.getValue("speed", "normal");
                        switch (l) {
                            case "fast":
                                setSelectedOption(fast)
                                break;
                            case "slow":
                                setSelectedOption(slow)
                                break;
                            default:
                                setSelectedOption(normal)
                        }
                    }
                    onSelectedOptionChanged: {
                        _app.setValue("speed", selectedOption.value)
                        updated();
                    }
                }
                Header {
                    title: qsTr("Sound") + Retranslate.onLocaleOrLanguageChanged
                    subtitle: qsTr("Experimental") + Retranslate.onLocaleOrLanguageChanged
                }
                Container {
                    layout: StackLayout {
                        orientation: LayoutOrientation.LeftToRight
                    }
                    topPadding: 20.0
                    bottomPadding: 20.0
                    Label {
                        text: qsTr("Enable sound in game") + Retranslate.onLocaleOrLanguageChanged
                        verticalAlignment: VerticalAlignment.Center
                        layoutProperties: StackLayoutProperties {
                            spaceQuota: 1.0

                        }
                    }
                    ToggleButton {
                        verticalAlignment: VerticalAlignment.Center
                        checked: _app.getValue("sound", "false") === "true"

                        onCheckedChanged: {
                            if (checked) {
                                _app.setValue("sound", "true")
                            } else {
                                _app.setValue("sound", "false")
                            }
                        }
                        id: soundtoggle
                    }
                }
                Header {
                    title: qsTr("Theme") + Retranslate.onLocaleOrLanguageChanged
                }
                Label {
                    textStyle.base: tip.style
                    text: qsTr("You can choose the theme here, no restart required.") + Retranslate.onLocaleOrLanguageChanged
                    multiline: true
                }
                DropDown {
                    options: [
                        Option {
                            text: qsTr("Dark") + Retranslate.onLocaleOrLanguageChanged
                            id: dark
                            value: "dark"
                        },
                        Option {
                            text: qsTr("Bright") + Retranslate.onLocaleOrLanguageChanged
                            id: bright
                            value: "bright"
                        },
                        Option {
                            text: qsTr("Vivid") + Retranslate.onLocaleOrLanguageChanged
                            id: vivid
                            value: "vivid"
                        },
                        Option {
                            text: qsTr("Blue") + Retranslate.onLocaleOrLanguageChanged
                            id: blu
                            value: 'blu'
                        },
                        Option {
                            text: qsTr("Flat Dots") + Retranslate.onLocaleOrLanguageChanged
                            id: flat
                            value: "flat"
                        }
                    ]
                    onCreationCompleted: {
                        var l = _app.getValue("theme", "");
                        switch (l) {
                            case "dark":
                                setSelectedOption(dark)
                                break;
                            case "vivid":
                                setSelectedOption(vivid)
                                break;
                            case "blu":
                                setSelectedOption(blu)
                                break;
                            case "flat":
                                setSelectedOption(flat)
                                break;
                            default:
                                setSelectedOption(bright)
                        }
                    }
                    onSelectedOptionChanged: {
                        _app.setValue("theme", selectedOption.value)
                        updated()
                    }
                }

                Header {
                    title: qsTr("Undo") + Retranslate.onLocaleOrLanguageChanged
                }
                Container {

                    layout: DockLayout {

                    }
                    horizontalAlignment: HorizontalAlignment.Fill
                    topPadding: 20.0
                    bottomPadding: 20.0
                    Label {
                        text: qsTr("Undo Feature Status:") + Retranslate.onLocaleOrLanguageChanged
                        verticalAlignment: VerticalAlignment.Center
                        horizontalAlignment: HorizontalAlignment.Left
                    }
                    Label {
                        text: locked.visible ? qsTr("Locked") + Retranslate.onLocaleOrLanguageChanged : qsTr("Unlocked") + Retranslate.onLocaleOrLanguageChanged
                        verticalAlignment: VerticalAlignment.Center
                        horizontalAlignment: HorizontalAlignment.Right
                        textStyle.color: Color.Green
                    }
                }
                Container {
                    id: locked
                    visible: _app.getValue("unlocked", "false") != "true"
                    horizontalAlignment: HorizontalAlignment.Fill
                    Label {
                        textStyle.base: tip.style
                        text: qsTr("Undo feature lets you undo your last 50 movements, till the very beginning of the game,or the last saved state.") + Retranslate.onLocaleOrLanguageChanged
                        multiline: true
                    }
                    Button {
                        id: btnundo
                        horizontalAlignment: HorizontalAlignment.Fill
                        text: qsTr("Unlock UNDO Feature") + Retranslate.onLocaleOrLanguageChanged
                        onClicked: {
                            indundo.visible = true;
                            pm.purchaseNow()
                        }
                        enabled: ! indundo.visible
                    }
                    Container {
                        id: indundo

                        horizontalAlignment: HorizontalAlignment.Fill
                        layout: StackLayout {
                            orientation: LayoutOrientation.LeftToRight

                        }
                        visible: false
                        ActivityIndicator {
                            running: true
                        }
                        Label {
                            text: qsTr("Waiting for Payment Service...") + Retranslate.onLocaleOrLanguageChanged
                        }
                    }
                    Label {
                        textStyle.base: tip.style
                        text: qsTr("If you already purchased the UNDO feature via BlackBerry World, press the button below :") + Retranslate.onLocaleOrLanguageChanged
                        multiline: true
                    }
                    Container {
                        id: indref

                        horizontalAlignment: HorizontalAlignment.Fill
                        layout: StackLayout {
                            orientation: LayoutOrientation.LeftToRight

                        }
                        visible: false
                        ActivityIndicator {
                            running: true
                        }
                        Label {
                            text: qsTr("Waiting for Payment Service...") + Retranslate.onLocaleOrLanguageChanged
                        }
                    }
                    Button {
                        id: btnref
                        horizontalAlignment: HorizontalAlignment.Fill
                        text: qsTr("Refresh Payment Status") + Retranslate.onLocaleOrLanguageChanged
                        onClicked: {
                            enabled = false;
                            indref.visible = true;
                            var existed = pm.requestExistingPurchases();
                        }
                        enabled: ! indref.visible
                    }

                    //                    Label {
                    //                        textStyle.base: tip.style
                    //                        text: qsTr("If you've got the unlock code already, press the button below :") + Retranslate.onLocaleOrLanguageChanged
                    //                        multiline: true
                    //                    }
                    //                    Button {
                    //                        id: btnUnlockwithcode
                    //                        horizontalAlignment: HorizontalAlignment.Fill
                    //                        text: qsTr("Unlock with Code") + Retranslate.onLocaleOrLanguageChanged
                    //                        onClicked: {
                    //                            enabled = false;
                    //                            _app.registerBBM();
                    //                        }
                    //                    }
                }
                Container {
                    id: unlocked
                    visible: ! locked.visible
                    horizontalAlignment: HorizontalAlignment.Fill
                    Label {
                        textStyle.base: tip.style
                        text: qsTr("Thank you for your support.") + Retranslate.onLocaleOrLanguageChanged
                        multiline: true
                        textStyle.textAlign: TextAlign.Center
                    }
                }
                Divider {

                }
            }
        }
    }
    attachedObjects: [
        PaymentManager {
            id: pm
            windowGroupId: Application.mainWindow.groupId
            onPurchaseFinished: {
                indundo.visible = false;
                if (reply.errorCode == 0) {
                    _app.setValue("unlocked", "true");
                    updated()
                } else {
                    notfound.body = reply.errorText
                    notfound.show()
                }
            }
            function purchaseNow() {
                requestPurchase("54265889", "2048_undo", "Undo");
            }
            onExistingPurchasesFinished: {
                indref.visible = false;
                btnref.enabled = true;
                if (reply.purchases.length > 0) {
                    _app.setValue("unlocked", "true");
                    updated()
                } else {
                    notfound.show()
                }
            }
        },
        SystemToast {
            id: notfound
            body: qsTr("No Record.") + Retranslate.onLocaleOrLanguageChanged
        }
    ]
    onCreationCompleted: {
    }
    onUpdated: {
        locked.visible = _app.getValue("unlocked", "false") != "true"
    }
}