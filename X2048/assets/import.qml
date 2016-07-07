import bb.cascades 1.2
Sheet {
    id: imp
    signal beginimport

    Page {
        actions: [
            ActionItem {
                title: qsTr("Go")
                ActionBar.placement: ActionBarPlacement.OnBar
                imageSource: "asset:///ic_done.png"
                onTriggered: {
                    switch (opt.selectedValue) {
                        case 0:
                            // import file
                            beginimport()
                            break;
                        case 1:
                            // delete file
                            _app.deleteFile("data/2048game.txt");
                            break;
                        case 2:
                            imp.close();
                            break;
                    }
                }
            }
        ]
        titleBar: TitleBar {
            title: qsTr("Import Former Game Data")
            scrollBehavior: TitleBarScrollBehavior.Sticky
            appearance: TitleBarAppearance.Branded
            visibility: ChromeVisibility.Visible

        }
        Container {
            horizontalAlignment: HorizontalAlignment.Fill

            leftPadding: 20.0
            rightPadding: 20.0
            Header {

            }
            Label {
                text: qsTr("Former Game Data Detected.")
                textFormat: TextFormat.Plain
                textStyle.fontSize: FontSize.Large
                textStyle.fontStyle: FontStyle.Normal
                textStyle.fontWeight: FontWeight.Bold
                textStyle.textAlign: TextAlign.Center
                horizontalAlignment: HorizontalAlignment.Center
                topMargin: 50.0
            }
            Header {

            }
            Label {
                text: qsTr("Please choose which data you'd like to keep.")
                multiline: true
            }
            RadioGroup {
                id: opt
                options: [
                    Option {
                        text: qsTr("Former record")
                        description: JSON.parse(_app.readTextFile("data/2048game.txt")).bestScore
                        value: 0
                        selected: true
                    },
                    Option {
                        value: 1
                        text: qsTr("Current record")
                    },
                    Option {
                        value: 2
                        text: qsTr("I'll decide later")
                        selected: false
                    }
                ]
            }
        }
    }

}