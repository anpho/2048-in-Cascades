import bb.cascades 1.3

Container {
    background: ui.palette.background
    property bool smallcover: false
    property string currentscore: ""
    property string bestscore: ""
    layout: DockLayout {

    }
    ImageView {
        imageSource: "asset:///bg.png"
        scalingMethod: ScalingMethod.AspectFill
        verticalAlignment: VerticalAlignment.Fill
        horizontalAlignment: HorizontalAlignment.Fill
        opacity: 0.3

    }
    Container {
        verticalAlignment: VerticalAlignment.Center
        horizontalAlignment: HorizontalAlignment.Center
        layout: StackLayout {
            orientation: smallcover ? LayoutOrientation.LeftToRight : LayoutOrientation.TopToBottom
        }
        Container {
            horizontalAlignment: HorizontalAlignment.Center
            verticalAlignment: VerticalAlignment.Center
            topPadding: 10.0
            leftPadding: 10.0
            bottomPadding: 10.0
            rightPadding: 10.0
            clipContentToBounds: true
            Label {
                text: qsTr("Score")
                horizontalAlignment: HorizontalAlignment.Center
                textStyle.textAlign: TextAlign.Justify
                textFit.mode: LabelTextFitMode.FitToBounds
                textStyle.fontSize: FontSize.XSmall
                textStyle.fontWeight: FontWeight.W100
                visible: ! smallcover
            }
            Label {
                text: currentscore
                horizontalAlignment: HorizontalAlignment.Center
                textStyle.textAlign: TextAlign.Justify
                textFit.mode: LabelTextFitMode.FitToBounds
                textStyle.fontSize: smallcover ? FontSize.Small : FontSize.Large
            }
            Label {
                text: qsTr("Best")
                horizontalAlignment: HorizontalAlignment.Center
                textStyle.textAlign: TextAlign.Justify
                textFit.mode: LabelTextFitMode.FitToBounds
                textStyle.fontSize: FontSize.XSmall
                textStyle.fontWeight: FontWeight.W100
                visible: ! smallcover
            }
            Label {
                text: (bestscore)
                horizontalAlignment: HorizontalAlignment.Center
                textStyle.textAlign: TextAlign.Justify
                textFit.mode: LabelTextFitMode.FitToBounds
                textStyle.fontSize: smallcover ? FontSize.XXSmall : FontSize.Large
            }
        }
    }
}
