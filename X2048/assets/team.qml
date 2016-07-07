import bb.cascades 1.0
Sheet {
    id: teams
    Page {
        titleBar: TitleBar {
            dismissAction: ActionItem {
                title: qsTr("Back")
                onTriggered: {
                    teams.close();
                }
            }

        }
        ScrollView {
            verticalAlignment: VerticalAlignment.Fill
            horizontalAlignment: HorizontalAlignment.Fill
            WebView {
                url: "http://anpho.github.io/cascades/"
                settings.defaultFontSizeFollowsSystemFontSize: true
                onMessageReceived: {
                    var d = message.data;
                    var index = d.indexOf(':');
                    var protocol = d.substr(0, index);
                    var target = d.substr(index + 1);
                    if (protocol === "url") {
                        Qt.openUrlExternally(target);
                    } else if (protocol === "twitter") {
                        Qt.openUrlExternally("twitter:connect:" + target)
                    }
                }
                verticalAlignment: VerticalAlignment.Fill
                horizontalAlignment: HorizontalAlignment.Fill
                settings.userStyleSheetLocation: "team.css"
            }
        }
    }

}