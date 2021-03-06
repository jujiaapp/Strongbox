//
//  DocumentController.m
//  MacBox
//
//  Created by Mark on 21/08/2017.
//  Copyright © 2017 Mark McGuill. All rights reserved.
//

#import "DocumentController.h"
#import "Document.h"
#import "AbstractDatabaseFormatAdaptor.h"
#import "CreateFormatAndSetCredentialsWizard.h"
#import "DatabaseModel.h"
#import "Settings.h"
#import "DatabasesManagerView.h"
#import "DatabasesManager.h"
#import "Alerts.h"
#import "Utils.h"
#import "NSArray+Extensions.h"
#import "BookmarksHelper.h"

static NSString* const kStrongboxPasswordDatabaseDocumentType = @"Strongbox Password Database";

@implementation DocumentController

// Allow open any file type/extension...

- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(nullable NSArray<NSString *> *)types {
    return [super runModalOpenPanel:openPanel forTypes:nil];
}

- (void)newDocument:(id)sender {
    CreateFormatAndSetCredentialsWizard* wizard = [[CreateFormatAndSetCredentialsWizard alloc] initWithWindowNibName:@"ChangeMasterPasswordWindowController"];
    
    NSString* loc = NSLocalizedString(@"mac_please_enter_master_credentials_for_this_database", @"Please Enter the Master Credentials for this Database");
    wizard.titleText = loc;
    wizard.initialDatabaseFormat = kKeePass4;
    wizard.createSafeWizardMode = YES;
    
    NSModalResponse returnCode = [NSApp runModalForWindow:wizard.window];

    if(returnCode != NSModalResponseOK) {
        return;
    }
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    
    NSString* loc2 = NSLocalizedString(@"mac_save_new_database",  @"Save New Password Database...");
    panel.title = loc2;

    NSString* loc3 = NSLocalizedString(@"mac_save_action",  @"Save");
    panel.prompt = loc3;
    
    NSString* loc4 = NSLocalizedString(@"mac_save_new_db_message",  @"You must save this new database before you can use it");
    panel.message = loc4;
    
    id<AbstractDatabaseFormatAdaptor> adaptor = [DatabaseModel getAdaptor:wizard.selectedDatabaseFormat];
    
    NSString* loc5 = NSLocalizedString(@"mac_untitled_database_filename_fmt", @"Untitled.%@");
    panel.nameFieldStringValue = [NSString stringWithFormat:loc5, adaptor.fileExtension ];
    
    NSInteger modalCode = [panel runModal];

    if (modalCode == NSModalResponseOK) {
        NSURL *URL = [panel URL];

        CompositeKeyFactors* ckf = [wizard generateCkfFromSelected:nil];
        
        Document *document = [[Document alloc] initWithCredentials:wizard.selectedDatabaseFormat
                                               compositeKeyFactors:ckf];

        [document saveToURL:URL
                     ofType:kStrongboxPasswordDatabaseDocumentType
           forSaveOperation:NSSaveOperation
          completionHandler:^(NSError * _Nullable errorOrNil) {
            if(errorOrNil) {
                return;
            }

            DatabaseMetadata* database = [DatabasesManager.sharedInstance addOrGet:URL];
            
            database.keyFileBookmark = wizard.selectedKeyFileBookmark;
            database.yubiKeyConfiguration = wizard.selectedYubiKeyConfiguration;
            
            [DatabasesManager.sharedInstance update:database];
        
            [self addDocument:document];
            [document setDatabaseMetadata:database];
            [document makeWindowControllers];
            [document showWindows];
        }];
    }
}

- (void)openDocument:(id)sender {
//    NSLog(@"openDocument: document count = [%ld]", self.documents.count);
    if(self.documents.count == 0) { // Empty Launch...
        [self performEmptyLaunchTasksIfNecessary];
    }
    else {
        [self originalOpenDocument:sender];
    }
}

- (void)originalOpenDocument:(id)sender {
    return [super openDocument:sender];
}

- (void)openDatabase:(DatabaseMetadata *)database {
    [self openDatabase:database completion:^(NSError *error) {
        if(error) {
            [DatabasesManagerView show:NO];
        }
    }];
}

- (void)openDatabase:(DatabaseMetadata*)database completion:(void (^)(NSError* error))completion {
    if(database.storageProvider == kLocalDevice) {
        NSError *error = nil;
        NSString* updatedBookmark;
        NSURL* url = [BookmarksHelper getUrlFromBookmark:database.storageInfo readOnly:NO updatedBookmark:&updatedBookmark error:&error];
        
        if(url == nil) {
            completion(error);
            return;
        }
        
        // URL / Bookmark may have changed...
        
        if (updatedBookmark) {
            database.storageInfo = updatedBookmark;
        }
        database.fileUrl = url;
        [DatabasesManager.sharedInstance update:database];
        
        BOOL access = [url startAccessingSecurityScopedResource];
        
        if(access) {
            [self openDocumentWithContentsOfURL:url
                                        display:YES
                              completionHandler:^(NSDocument * _Nullable document,
                                                 BOOL documentWasAlreadyOpen,
                                                 NSError * _Nullable error) {
                if(error) {
                    NSLog(@"openDocumentWithContentsOfURL Error = [%@]", error);
                }
                
                completion(error);
            }];
        }
        else {
            completion([Utils createNSError:@"Could not access security scope URL" errorCode:-1]);
        }
    }
}

- (void)onAppStartup {
//    NSLog(@"onAppStartup: document count = [%ld]", self.documents.count);
    
    if(DatabasesManager.sharedInstance.snapshot.count > 0 &&
       Settings.sharedInstance.autoOpenFirstDatabaseOnEmptyLaunch) {
        [self openPrimaryDatabase];
    }
    else if(self.documents.count == 0) {
        [DatabasesManagerView show:NO];
    }
}

- (void)performEmptyLaunchTasksIfNecessary {
//    NSLog(@"performEmptyLaunchTasks...");
    
    if(self.documents.count == 0) { // Empty Launch...
//        NSLog(@"performEmptyLaunchTasks: document count = [%ld]", self.documents.count);
        
        if(DatabasesManager.sharedInstance.snapshot.count > 0 &&
           Settings.sharedInstance.autoOpenFirstDatabaseOnEmptyLaunch) {
            [self openPrimaryDatabase];
        }
        else {
            [DatabasesManagerView show:NO];
        }
    }
}

- (void)openPrimaryDatabase {
    if(DatabasesManager.sharedInstance.snapshot.count > 0 &&
       Settings.sharedInstance.autoOpenFirstDatabaseOnEmptyLaunch) {
        [self openDatabase:DatabasesManager.sharedInstance.snapshot.firstObject completion:^(NSError *error) { }];
    }
}

@end
