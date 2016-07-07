import bb.cascades 1.2

Sheet {
    id: tut
    Page {
        titleBar: TitleBar {
            dismissAction: ActionItem {
                title: qsTr("Close") + Retranslate.onLocaleOrLanguageChanged
                onTriggered: {
                    tut.close();
                    _app.setValue("firstrun", "false")
                }
            }
            title: qsTr("Tutorial") + Retranslate.onLocaleOrLanguageChanged

        }
        ScrollView {

            Container {
                id: slide
                preferredWidth: DisplayInfo.width
                leftPadding: 20.0
                rightPadding: 20.0
                Header {
                    title: qsTr("HOW TO PLAY") + Retranslate.onLocaleOrLanguageChanged
                }
                Label {
                    text: qsTr("Swipe your <strong>finger</strong> to move the tiles. When two tiles with the same number touch, they <strong>merge into one!</strong>") + Retranslate.onLocaleOrLanguageChanged
                    multiline: true
                    textFormat: TextFormat.Html
                    horizontalAlignment: HorizontalAlignment.Center
                }
                ImageView {
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    imageSource: "asset:///tutorial/1.png"
                    preferredHeight: DisplayInfo.width / 2
                    preferredWidth: DisplayInfo.width / 2
                }
                Label {
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    text: "+"
                    textStyle.fontSize: FontSize.XXLarge
                }
                ImageView {
                    imageSource: "asset:///tutorial/Swipe-Down.png"
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    scalingMethod: ScalingMethod.AspectFill
                }
                Label {
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    text: "="
                    textStyle.fontSize: FontSize.XXLarge
                }
                ImageView {
                    imageSource: "asset:///tutorial/2.gif"
                    horizontalAlignment: HorizontalAlignment.Center
                    verticalAlignment: VerticalAlignment.Center
                    preferredHeight: DisplayInfo.width / 2
                    preferredWidth: DisplayInfo.width / 2
                }

                Label {
                    text: qsTr("When you created a 2048 tile, you win.") + Retranslate.onLocaleOrLanguageChanged
                    multiline: true
                    textFormat: TextFormat.Html
                    horizontalAlignment: HorizontalAlignment.Center
                }

                Divider {

                }
                Header {
                    title: qsTr("ACCESS SETTINGS") + Retranslate.onLocaleOrLanguageChanged
                }
                Label {
                    text: qsTr("Swipe down from the top of screen, you'll see the actions available.") + Retranslate.onLocaleOrLanguageChanged
                    multiline: true
                    textFormat: TextFormat.Html
                    horizontalAlignment: HorizontalAlignment.Center
                }

                Divider {
                    opacity: 0.0
                    bottomMargin: 60.0

                }
                Button {
                    horizontalAlignment: HorizontalAlignment.Center
                    text: qsTr("PLAY") + Retranslate.onLocaleOrLanguageChanged
                    onClicked: {
                        tut.close()
                        _app.setValue("firstrun", "false")
                    }
                }
                Divider {
                    visible: true
                    opacity: 0.0
                    topMargin: 60.0

                }
            }
        }
    }
}