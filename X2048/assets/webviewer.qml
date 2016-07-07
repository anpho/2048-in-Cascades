import bb.cascades 1.2
Sheet {
    id: sheet
    property alias uri: webv.url
    Page {
        titleBar: TitleBar {
            title: qsTr("Issues")
            scrollBehavior: TitleBarScrollBehavior.NonSticky
            dismissAction: ActionItem {
                title: qsTr("Close")
                onTriggered: {
                    sheet.close()
                }
            }
        }
        ScrollView {
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill
            scrollRole: ScrollRole.Main
            WebView {
                id: webv
                horizontalAlignment: HorizontalAlignment.Fill
                preferredHeight: Infinity
                settings.userAgent: "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Nexus One Build/FRF91) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"
                settings.defaultFontSizeFollowsSystemFontSize: true
                settings.zoomToFitEnabled: true
                settings.activeTextEnabled: false
            }
        }
    }
}