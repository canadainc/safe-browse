import bb.cascades 1.0

Page {
    property alias contentContainer: contentContainer.controls

    Container {
        attachedObjects: [
            ImagePaintDefinition {
                id: back
                imageSource: "images/background.png"
            }
        ]
        
		background: back.imagePaint
		horizontalAlignment: HorizontalAlignment.Fill
		verticalAlignment: VerticalAlignment.Fill
        
		Container
		{
		    id: titleBar
		
		    horizontalAlignment: HorizontalAlignment.Fill
		    verticalAlignment: VerticalAlignment.Fill
		    layout: DockLayout {}

            ImageView {
		        imageSource: "images/title_bg.png"
		        topMargin: 0
		        leftMargin: 0
		        rightMargin: 0
		        bottomMargin: 0
		
		        horizontalAlignment: HorizontalAlignment.Fill
		        verticalAlignment: VerticalAlignment.Top
		    }

            ImageView {
                imageSource: "images/logo.png"
                topMargin: 0
                leftMargin: 0
                rightMargin: 0
                bottomMargin: 0
                loadEffect: ImageViewLoadEffect.FadeZoom

                horizontalAlignment: HorizontalAlignment.Center
                verticalAlignment: VerticalAlignment.Center
            }
        }
		
		Container {
		    background: Color.White
		    preferredHeight: 2; minHeight: 2; maxHeight: 2
		}

        Container // This container is replaced
        {
            layout: DockLayout {
                
            }
            
            id: contentContainer
            objectName: "contentContainer"
            
            horizontalAlignment: HorizontalAlignment.Fill
            verticalAlignment: VerticalAlignment.Fill

            layoutProperties: StackLayoutProperties {
                spaceQuota: 1
            }
            
            ImageView {
                imageSource: "images/bottomDropShadow.png"
                topMargin: 0
                leftMargin: 0
                rightMargin: 0
                bottomMargin: 0

                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Top
                
                animations: [
                    TranslateTransition {
                        id: translateShadow
                        toY: 0
                        fromY: -100
                        duration: 1000
                    }
                ]
                
		        onCreationCompleted: {
                    translateShadow.play()
		        }
            }
        }
    }
}