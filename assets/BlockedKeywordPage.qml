import bb.cascades 1.0
import bb.system 1.2
import com.canadainc.data 1.0

Page
{
    id: root
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    
    function cleanUp() {}
    
    onActionMenuVisualStateChanged: {
        if (actionMenuVisualState == ActionMenuVisualState.VisibleFull) {
            tutorial.execOverFlow( "clearAllKeywords", qsTr("Tap on the '%1' action to clear all the the keywords."), unblockAllAction );
        }
    }
    
    function onDataLoaded(id, data)
    {
        if (id == QueryId.GetKeywords)
        {
            adm.clear();
            adm.insertList(data);
            
            listView.visible = data.length > 0;
            emptyDelegate.delegateActive = data.length == 0;
            
            tutorial.execActionBar("addKeyword", qsTr("Use the '%1' action from the menu to add a specific keyword you want to block.").arg(addAction.title) );
            tutorial.execBelowTitleBar("threshold", qsTr("This threshold slider controls the minimum number of keyword hits that must be matched on a website title before it is blocked.\n\nTo implement more aggressive blocking, decrease this threshold, to be more lenient and only block when multiple keywords are matched, increase the threshold"), 0, "l", "r");
            
            if ( !adm.isEmpty() )
            {
                tutorial.execActionBar("clearKeywordsMenu", qsTr("You can clear this blocked list by selecting '%1' from the menu.").arg(unblockAllAction.title), "x" );
            }
        } else if (id == QueryId.InsertKeyword || id == QueryId.DeleteKeyword) {
            helper.fetchAllBlockedKeywords(root);
        }
    }
    
    titleBar: TitleBar
    {
        id: titleControl
        kind: TitleBarKind.FreeForm
        scrollBehavior: TitleBarScrollBehavior.NonSticky
        kindProperties: FreeFormTitleBarKindProperties
        {
            Container
            {
                horizontalAlignment: HorizontalAlignment.Fill
                verticalAlignment: VerticalAlignment.Fill
                topPadding: 10; bottomPadding: 20; leftPadding: 10
                
                Label {
                    id: thresholdLabel
                    verticalAlignment: VerticalAlignment.Center
                    textStyle.base: SystemDefaults.TextStyles.BigText
                    textStyle.color: 'Signature' in ActionBarPlacement ? Color.Black : Color.White
                }
            }
            
            expandableArea
            {
                expanded: true
                
                content: Container
                {
                    horizontalAlignment: HorizontalAlignment.Fill
                    verticalAlignment: VerticalAlignment.Fill
                    leftPadding: 10; rightPadding: 10; topPadding: 5; bottomPadding: 10
                    
                    Slider
                    {
                        value: persist.getValueFor("keywordThreshold")
                        horizontalAlignment: HorizontalAlignment.Fill
                        fromValue: 1
                        toValue: 5
                        
                        onValueChanged: {
                            var actualValue = Math.floor(value);
                            var changed = persist.saveValueFor("keywordThreshold", actualValue);
                            thresholdLabel.text = qsTr("Threshold: %1").arg(actualValue);
                            
                            if (changed) {
                                reporter.record("KeywordThreshold", actualValue);
                            }
                        }
                    }
                    
                    Divider {
                        topMargin: 0; bottomMargin: 0
                    }
                }
            }
        }
    }
    
    actions: [
        ActionItem
        {
            id: addAction
            title: qsTr("Add") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_add.png"
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.CreateNew
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: AddBlockedKeyword");
                reporter.record("AddBlockedKeyword");
                addPrompt.show();
            }
            
            attachedObjects: [
                SystemPrompt
                {
                    id: addPrompt
                    title: qsTr("Add Keyword") + Retranslate.onLanguageChanged
                    body: qsTr("Enter the keyword you wish to add (no spaces):") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                    inputOptions: SystemUiInputOption.None
                    
                    onFinished: {
                        console.log("UserEvent: AddKeywordPrompt", result);
                        
                        if (result == SystemUiResult.ConfirmButtonSelection)
                        {
                            var value = addPrompt.inputFieldTextEntry().trim().toLowerCase();
                            
                            if ( value.indexOf(" ") >= 0 ) {
                                persist.showToast( qsTr("The keyword cannot contain any spaces!"), "images/ic_block.png" );
                                reporter.record("SpacedKeywordError");
                                return;
                            } else if (value.length < 3 || value.length > 20) {
                                reporter.record("OutOfBoundsKeywordError");
                                persist.showToast( qsTr("The keyword must be between 3 to 20 characters in length (inclusive)!"), "images/ic_block.png" );
                                return;
                            }
                            
                            var keywordsList = helper.blockKeywords(root, [value]);
                            
                            if (keywordsList.length > 0) {
                                reporter.record("KeywordAdded");
                                persist.showToast( qsTr("The following keywords were added: %1").arg( keywordsList.join(", ") ), "images/menu/ic_keywords.png" );
                            } else {
                                reporter.record("KeywordAddFailed", value);
                                persist.showToast( qsTr("The keyword could not be blocked: %1").arg(value), "images/ic_block.png" );
                            }
                        }
                    }
                }
            ]
        },
        
        DeleteActionItem
        {
            id: unblockAllAction
            enabled: listView.visible
            title: qsTr("Clear All") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_unblock.png"
            
            function onFinished(ok)
            {
                if (ok)
                {
                    reporter.record("ClearAllKeywordsAccept");
                    helper.clearBlockedKeywords(root);
                    adm.clear();
                    emptyDelegate.delegateActive = true;
                }
            }
            
            onTriggered: {
                console.log("UserEvent: ClearAllBlockedKeywords");
                reporter.record("ClearAllBlockedKeywords");
                persist.showDialog( unblockAllAction, qsTr("Confirmation"), qsTr("Are you sure you want to clear all the keywords?") );
            }
        }
    ]
    
    onCreationCompleted: {
        helper.fetchAllBlockedKeywords(root);
        deviceUtils.attachTopBottomKeys(root, listView);
    }
    
    Container
    {
        horizontalAlignment: HorizontalAlignment.Fill
        verticalAlignment: VerticalAlignment.Fill
        background: ipd.imagePaint
        
        layout: DockLayout {}
        
        EmptyDelegate
        {
            id: emptyDelegate
            graphic: "images/placeholder/keywords_empty.png"
            labelText: qsTr("You have no blocked keywords. Tap here to add one.")
            
            onImageTapped: {
                console.log("UserEvent: BlockedKeywordEmptyTapped");
                reporter.record("BlockedKeywordEmptyTapped");
                addPrompt.show();
            }
        }
        
        ListView
        {
            id: listView
            scrollRole: ScrollRole.Main
            
            dataModel: GroupDataModel
            {
                id: adm
                grouping: ItemGrouping.ByFirstChar
                sortingKeys: ["term"]
            }
            
            function unblock(blocked)
            {
                var keywordsList = helper.unblockKeywords(root, blocked);
                
                if (keywordsList.length > 0) {
                    persist.showToast( qsTr("The following keywords were unblocked: %1").arg( keywordsList.join(", ") ), "images/menu/ic_unblock.png" );
                } else {
                    persist.showToast( qsTr("The following keywords could not be unblocked: %1").arg( blocked.join(", ") ), "images/tabs/ic_blocked.png" );
                }
            }
            
            onTriggered: {
                console.log("UserEvent: BlockedKeywordTapped", indexPath);
                reporter.record("BlockedKeywordTapped");
                multiSelectHandler.active = true;
                toggleSelection(indexPath);
            }
            
            listItemComponents: [
                ListItemComponent {
                    type: "header"
                    
                    Header {
                        title: ListItemData
                        subtitle: ListItem.view.dataModel.childCount(ListItem.indexPath)
                    }
                },
                
                ListItemComponent
                {
                    type: "item"
                    
                    StandardListItem {
                        id: sli
                        title: ListItemData.term
                        status: ListItemData.count
                        imageSource: "images/ic_block.png"
                        opacity: 0
                        
                        animations: [
                            FadeTransition {
                                id: slider
                                fromOpacity: 0
                                toOpacity: 1
                                easingCurve: StockCurve.SineOut
                                duration: 750
                                delay: Math.min(sli.ListItem.indexInSection * 100, 750)
                            }
                        ]
                        
                        ListItem.onInitializedChanged: {
                            if (initialized) {
                                slider.play();
                            }
                        }
                    }
                }
            ]
            
            multiSelectHandler
            {
                onActiveChanged: {
                    if (active) {
                        tutorial.execActionBar( "unblockKeywords", qsTr("Tap here to remove these keywords from the list."), "x" );
                    }
                }
                
                actions: [
                    DeleteActionItem 
                    {
                        id: unBlockAction
                        title: qsTr("Unblock") + Retranslate.onLanguageChanged
                        imageSource: "images/menu/ic_unblock.png"
                        enabled: false
                        
                        onTriggered: {
                            console.log("UserEvent: MultiUnblock");
                            reporter.record("MultiUnblock");
                            var selected = listView.selectionList();
                            var blocked = [];
                            
                            for (var i = selected.length-1; i >= 0; i--) {
                                blocked.push( adm.data(selected[i]) );
                            }
                            
                            listView.unblock(blocked);
                        }
                    }
                ]
                
                status: qsTr("None selected") + Retranslate.onLanguageChanged
            }
            
            onSelectionChanged: {
                var n = selectionList().length;
                unBlockAction.enabled = n > 0;
                multiSelectHandler.status = qsTr("%n keywords to unblock", "", n);
            }
        }
    }
}