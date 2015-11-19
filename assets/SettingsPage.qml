import bb.cascades 1.0
import bb.cascades.pickers 1.0
import bb.system 1.2
import com.canadainc.data 1.0

Page
{
    id: dashPage
    actionBarAutoHideBehavior: ActionBarAutoHideBehavior.HideOnScroll
    titleBar: SafeTitleBar {}
    
    onCreationCompleted: {
        if (!security.authenticated) {
            loginPrompt.show();
        } else {
            guardianContainer.opacity = 1;
        }
    }
    
    actions: [
        ActionItem
        {
            id: addAction
            imageSource: "images/menu/ic_add.png"
            title: qsTr("Add") + Retranslate.onLanguageChanged
            ActionBar.placement: 'Signature' in ActionBarPlacement ? ActionBarPlacement["Signature"] : ActionBarPlacement.OnBar
            
            shortcuts: [
                SystemShortcut {
                    type: SystemShortcuts.CreateNew
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: AddSite");
                reporter.record("AddSite");
                addPrompt.show();
            }
            
            attachedObjects: [
                SystemPrompt
                {
                    id: addPrompt
                    title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                    body: qsTr("Enter the host address (ie: youtube.com). Don't append any http:// or www.") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                    inputField.emptyText: "youtube.com"
                    inputOptions: SystemUiInputOption.None
                    
                    onFinished: {
                        console.log( "UserEvent: NewAddressToBlockEntered", value, inputFieldTextEntry() );

                        if (value == SystemUiResult.ConfirmButtonSelection)
                        {
                            reporter.record("BlockedHostEntered");
                            
                            var request = inputFieldTextEntry().trim();
                            helper.blockSite(listView, modeDropDown.selectedValue, request);
                        }
                    }
                }
            ]
        },
        
        ActionItem
        {
            imageSource: "images/ic_home.png"
            title: qsTr("Set Home") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            onTriggered: {
                console.log("UserEvent: SetHome");
                reporter.record("SetHome");
                homePrompt.showPrompt();
            }
            
            attachedObjects: [
                SystemPrompt
                {
                    id: homePrompt
                    title: qsTr("Enter URL") + Retranslate.onLanguageChanged
                    body: qsTr("Enter the homepage address (ie: http://dar-as-sahaba.com)") + Retranslate.onLanguageChanged
                    confirmButton.label: qsTr("OK") + Retranslate.onLanguageChanged
                    cancelButton.label: qsTr("Cancel") + Retranslate.onLanguageChanged
                    inputField.emptyText: "http://canadainc.org"
                    inputOptions: SystemUiInputOption.None
                    
                    function showPrompt()
                    {
                        inputField.defaultText = persist.getValueFor("home");
                        show();
                    }
                    
                    onFinished: {
                        console.log( "UserEvent: HomepageAddressEntered", value, inputFieldTextEntry() );
                        
                        if (value == SystemUiResult.ConfirmButtonSelection)
                        {
                            var request = inputFieldTextEntry().trim();
                            reporter.record("HomepageAddressEntered", request);

                            persist.saveValueFor("home", request, false);
                            persist.showToast( qsTr("Successfully set homepage to %1").arg(request), "images/ic_home.png" );
                            
                            helper.blockSite(listView, "controlled", request);
                        }
                    }
                }
            ]
        },
        
        ActionItem
        {
            id: safeRun
            imageSource: "images/menu/ic_safe_run.png"
            title: qsTr("Safe Run") + Retranslate.onLanguageChanged
            ActionBar.placement: ActionBarPlacement.OnBar
            
            function onPopTransitionEnded(page)
            {
                if (dashPage.parent.top == dashPage) {
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                }
            }
            
            function onFinished(ok)
            {
                if (ok)
                {
                    definition.source = "SafeRunPage.qml";
                    var safeRun = definition.createObject();
                    dashPage.parent.push(safeRun);
                    
                    safeRun.targetPrompt.show();
                    dashPage.parent.popTransitionEnded.connect(onPopTransitionEnded);
                }
            }
            
            onTriggered: {
                console.log("UserEvent: SafeRun");
                reporter.record("SafeRun");
                var message;
                
                if (helper.mode == "passive") {
                    message = qsTr("Go through and browse all the pages that you want to block. They will be added one by one automatically. When you finish simply close the page.");
                } else {
                    message = qsTr("Go through and browse all the pages that you want to allow. They will be added one by one automatically. When you finish simply close the page.");
                }
                
                persist.showDialog( safeRun, title, message, qsTr("OK"), "" );
            }
        },
        
        ActionItem
        {
            imageSource: "images/ic_password.png"
            title: qsTr("Change Password") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: ChangePassword");
                reporter.record("ChangePassword");
                definition.source = "SignupSheet.qml";
                var sheet = definition.createObject();
                sheet.open();
            }
        },
        
        ActionItem
        {
            imageSource: "images/menu/ic_keywords.png"
            title: qsTr("Blocked Keywords") + Retranslate.onLanguageChanged
            
            onTriggered: {
                console.log("UserEvent: BlockedKeywords");
                reporter.record("BlockedKeywords");
                definition.source = "BlockedKeywordPage.qml";
                var keywords = definition.createObject();
                dashPage.parent.push(keywords);
            }
        },
        
        ActionItem
        {
            imageSource: "images/menu/ic_logs.png"
            title: qsTr("View Logs") + Retranslate.onLanguageChanged
            
            shortcuts: [
                Shortcut {
                    key: qsTr("V") + Retranslate.onLanguageChanged
                    
                    onTriggered: {
                        reporter.record("ViewLogsShortcut");
                    }
                }
            ]
            
            onTriggered: {
                console.log("UserEvent: ViewLogs");
                reporter.record("ViewLogs");
                definition.source = "ViewLogsPage.qml";
                var page = definition.createObject();
                dashPage.parent.push(page);
            }
        },
        
        ActionItem
        {
            id: backup
            title: qsTr("Backup") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_backup.png"
            
            onTriggered: {
                console.log("UserEvent: Backup");
                filePicker.title = qsTr("Select Destination");
                filePicker.mode = FilePickerMode.Saver
                filePicker.defaultSaveFileNames = ["safe_browse_backup.sb"]
                filePicker.allowOverwrite = true;
                filePicker.open();
                
                reporter.record("Backup");
            }
            
            function onSaved(result)
            {
                if (result.length > 0) {
                    persist.showToast( qsTr("Successfully backed up to %1").arg(result), imageSource.toString() );
                } else {
                    persist.showToast( qsTr("The database could not be backed up. Please file a bug report."), "images/toast/error.png" );
                }
                
                reporter.record("BackupResult", result);
            }
        },
        
        ActionItem
        {
            id: restore
            title: qsTr("Restore") + Retranslate.onLanguageChanged
            imageSource: "images/menu/ic_restore.png"
            
            onTriggered: {
                console.log("UserEvent: Restore");
                filePicker.title = qsTr("Select File");
                filePicker.mode = FilePickerMode.Picker
                filePicker.open();
                
                reporter.record("Restore");
            }
            
            function onFinished(ok)
            {
                if (ok) {
                    Application.requestExit();
                }
            }
            
            function onRestored(result)
            {
                if (result.length > 0) {
                    persist.showDialog( restore, qsTr("Restore Complete"), qsTr("The database was successfully restored. The app will close now so it can restart with the changes applied."), qsTr("OK"), "" );
                } else {
                    persist.showToast( qsTr("The database could not be restored. Please re-check the backup file to ensure it is valid, and if the problem persists please file a bug report. Make sure to attach the backup file with your report!"), "images/toast/error.png" );
                }
                
                reporter.record("RestoreResult", result.toString());
            }
        }
    ]
    
    function cleanUp() {
        dashPage.parent.popTransitionEnded.disconnect(safeRun.onPopTransitionEnded);
    }
    
    Container
    {
        id: guardianContainer
        opacity: 0
        
        attachedObjects: [
            ImagePaintDefinition {
                id: back
                imageSource: "images/background.png"
            }
        ]
        
        onOpacityChanged: {
            if (opacity == 1)
            {
                /*
                if ( persist.tutorialVideo("http://youtu.be/Lt1SMGO2iOw") ) {}
                else if ( persist.tutorial( "tutorialVideo", qsTr("To watch a video tutorial on how to use the app, swipe-down from the top-bezel, choose 'Help' and use the 'Video Tutorial' action from the bottom bar."), "asset:///images/menu/ic_help.png" ) ) {}
                else if ( persist.tutorial( "tutorialParental", qsTr("To disable the native Browser, Swipe-down from the BlackBerry 10 home screen and choose Settings.\nThen scroll down in the list and go to 'Security & Privacy.\nSelect 'Parental Controls'.\nEnable the parental controls toggle button.\nChoose a password.\nDisallow the browser toggle button.\n\nYou can also access this Parental Controls screen by tapping on the Help from the top-menu in Safe Browse."), "asset:///images/toast/ic_instructions.png" ) ) {}
                else if ( persist.tutorial( "tutorialInstallApp", qsTr("For added security you might also want to disable the 'Install Application' toggle button from the Parental Controls so that no one can download additional web browsing apps."), "asset:///images/toast/ic_instructions.png" ) ) {}
                else if ( persist.tutorial( "tutorialRemoveApp", qsTr("For added security you might also want to disable the 'Remove Application' toggle button from the Parental Controls so that no one can delete this app and get rid of all your blocking settings."), "asset:///images/toast/ic_instructions.png" ) ) {}
                else if ( persist.tutorial( "tutorialPassive", qsTr("If you want to allow all websites except certain ones, choose 'Passive' from the Browsing Mode dropdown."), "asset:///images/dropdown/ic_passive.png" ) ) {}
                else if ( persist.tutorial( "tutorialControlled", qsTr("If you want to block all websites except certain ones, choose 'Controlled' from the Browsing Mode dropdown."), "asset:///images/dropdown/ic_controlled.png" ) ) {}
                else if ( persist.tutorial( "tutorialViewLogs", qsTr("You can use the 'View Logs' from the menu to see all the list of websites that were accessed, blocked, and the failed login attempts to have occurred."), "asset:///images/menu/ic_logs.png" ) ) {}
                else if ( persist.tutorial( "tutorialChangePassword", qsTr("If you want to change your password, you can choose the 'Change Password' item from the menu."), "asset:///images/ic_password.png" ) ) {}
                else if ( persist.tutorial( "tutorialClearCache", qsTr("If you notice the app taking up a lot of space, you should choose 'Clear Cache' from the menu."), "asset:///images/menu/ic_clear_cache.png" ) ) {}
                */
                deviceUtils.attachTopBottomKeys(dashPage, listView);
            }
        }
        
        background: back.imagePaint
        verticalAlignment: VerticalAlignment.Fill
        horizontalAlignment: HorizontalAlignment.Fill
        
        SegmentedControl
        {
            id: modeDropDown
            horizontalAlignment: HorizontalAlignment.Fill
            bottomMargin: 0
            
            onCreationCompleted: {
                var primary = persist.getValueFor("mode");
                
                for (var i = count()-1; i >= 0; i--)
                {
                    if ( at(i).value == primary )
                    {
                        selectedIndex = i;
                        break;
                    }
                }
            }
            
            Option {
                id: passive
                text: qsTr("Passive") + Retranslate.onLanguageChanged
                description: qsTr("Allow all sites except certain ones") + Retranslate.onLanguageChanged
                value: "passive"
                imageSource: "images/dropdown/ic_passive.png"
            }
            
            Option {
                id: controlled
                text: qsTr("Controlled") + Retranslate.onLanguageChanged
                description: qsTr("Block all sites except certain ones") + Retranslate.onLanguageChanged
                value: "controlled"
                imageSource: "images/dropdown/ic_controlled.png"
            }
            
            onSelectedValueChanged: {
                var diff = persist.saveValueFor("mode", selectedValue);
                
                if (diff)
                {
                    if (selectedValue == "passive") {
                        persist.showToast( qsTr("All websites will be allowed except the ones you choose to block."), "images/dropdown/ic_passive.png" );
                    } else if (selectedValue == "controlled") {
                        if ( persist.tutorial( "tutorialSafeRun", qsTr("To quickly add a bunch of allowed websites tap on the Safe Run icon from the menu."), "asset:///images/menu/ic_safe_run.png" ) ) {}
                        persist.showToast( qsTr("All websites will be blocked except the ones you choose to allow."), "images/dropdown/ic_controlled.png" );
                    }
                    
                    reporter.record("BrowsingMode", selectedValue);
                }
                
                helper.fetchAllBlocked(listView, selectedValue);
            }
        }
        
        Divider {
            topMargin: 0; bottomMargin: 0
        }
        
        EmptyDelegate
        {
            id: noElements
            graphic: "images/placeholder/blocked_empty.png"
            labelText: modeDropDown.selectedOption == passive ? qsTr("There are no websites currently blocked. Tap here to add one.") + Retranslate.onLanguageChanged : qsTr("There are no websites currently allowed. Tap here to add one.") + Retranslate.onLanguageChanged
            
            onImageTapped: {
                console.log("UserEvent: AddExceptionUrlTapped")
                reporter.record("AddExceptionUrlTapped");
                addAction.triggered();
            }
        }
        
        ListView
        {
            id: listView
            scrollRole: ScrollRole.Main
            
            dataModel: ArrayDataModel {
                id: adm
            }
            
            onTriggered: {
                console.log("UserEvent: BlockedListItem Tapped", indexPath);
                reporter.record("ExceptionUrlTriggered");
                multiSelectHandler.active = true;
                toggleSelection(indexPath);
            }
            
            multiSelectHandler
            {
                actions: [
                    DeleteActionItem 
                    {
                        id: unblockAction
                        title: qsTr("Unblock") + Retranslate.onLanguageChanged
                        imageSource: "images/menu/ic_unblock.png"
                        enabled: false
                        
                        onTriggered: {
                            console.log("UserEvent: UnblockMultiExceptions");
                            reporter.record("UnblockMultiExceptions");
                            var selected = listView.selectionList();
                            var blocked = [];
                            
                            for (var i = selected.length-1; i >= 0; i--) {
                                blocked.push( adm.data(selected[i]) );
                            }
                            
                            helper.unblockSite(listView, modeDropDown.selectedValue, blocked);
                        }
                    }
                ]
                
                status: qsTr("None selected") + Retranslate.onLanguageChanged
            }
            
            onSelectionChanged: {
                var n = selectionList().length;
                unblockAction.enabled = n > 0;
                multiSelectHandler.status = qsTr("%n addresses to remove", "", n);
            }
            
            listItemComponents:
            [
                ListItemComponent
                {
                    StandardListItem
                    {
                        id: rootItem
                        imageSource: "images/ic_browse.png";
                        description: ListItemData.uri
                        
                        ListItem.onInitializedChanged: {
                            if (initialized) {
                                showAnim.play();
                            }
                        }
                        
                        animations: [
                            ParallelAnimation
                            {
                                id: showAnim
                                ScaleTransition
                                {
                                    fromX: 0.8
                                    toX: 1
                                    fromY: 0.8
                                    toY: 1
                                    duration: 600
                                    easingCurve: StockCurve.ElasticOut
                                }
                                
                                FadeTransition {
                                    fromOpacity: 0
                                    toOpacity: 1
                                    duration: 200
                                }
                                
                                delay: Math.min(rootItem.ListItem.indexInSection*100, 1000)
                            }
                        ]
                    }
                }
            ]

            function onDataLoaded(id, data)
            {
                if (id == QueryId.GetAll)
                {
                    adm.clear()
                    adm.append(data);
                    
                    listView.visible = !adm.isEmpty();
                    noElements.delegateActive = !listView.visible;
                    if ( !adm.isEmpty() && persist.tutorial( "tutorialRemoveBlocked", qsTr("To remove a blocked site from the list, tap on it and choose 'Delete' from the menu."), "asset:///images/menu/ic_unblock.png" ) ) {}
                } else if (id == QueryId.InsertEntry) {
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                } else if (id == QueryId.DeleteEntry) {
                    helper.fetchAllBlocked(listView, modeDropDown.selectedValue);
                }
            }
        }
    }
    
    attachedObjects: [
        SystemPrompt
        {
            id: loginPrompt
            body: qsTr("Please enter your password:") + Retranslate.onLanguageChanged
            title: qsTr("Login") + Retranslate.onLanguageChanged
            inputOptions: SystemUiInputOption.None
            inputField.emptyText: qsTr("Password cannot be empty...") + Retranslate.onLanguageChanged
            inputField.maximumLength: 20
            inputField.inputMode: SystemUiInputMode.Password
            
            onFinished: {
                console.log( "UserEvent: PasswordEntered", value, inputFieldTextEntry() );

                if (value == SystemUiResult.ConfirmButtonSelection)
                {
                    var password = inputFieldTextEntry().trim();
                    var loggedIn = security.login(password);

                    if (!loggedIn)
                    {
                        helper.logFailedLogin(listView, password);
                        reporter.record("FailedAuthentication");
                        persist.showToast( qsTr("Wrong password entered. Please try again."), "images/dropdown/set_password.png" );
                        dashPage.parent.pop();
                    } else {
                        guardianContainer.opacity = 1;
                        reporter.record("AuthenticationSuccess");
                    }
                } else {
                    reporter.record("CanceledAuthentication");
                    
                    dashPage.removeAllActions();
                    dashPage.parent.pop();
                }
            }
        },
        
        FilePicker {
            id: filePicker
            defaultType: FileType.Other
            filter: ["*.sb"]
            
            directories :  {
                return ["/accounts/1000/removable/sdcard", "/accounts/1000/shared/misc"]
            }
            
            onFileSelected : {
                console.log("UserEvent: FileSelected", selectedFiles[0]);
                
                if (mode == FilePickerMode.Picker) {
                    app.backup(restore, "onRestored", selectedFiles[0], true);
                } else {
                    app.backup(backup, "onSaved", selectedFiles[0], false);
                }
            }
        }
    ]
}