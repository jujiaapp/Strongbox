//
//  SelectStorageProviderController.m
//  StrongBox
//
//  Created by Mark on 08/09/2017.
//  Copyright © 2017 Mark McGuill. All rights reserved.
//

#import "SelectStorageProviderController.h"
#import "SafeStorageProvider.h"
#import "LocalDeviceStorageProvider.h"
#import "GoogleDriveStorageProvider.h"
#import "DropboxV2StorageProvider.h"
#import "CustomStorageProviderTableViewCell.h"
#import "AddSafeAlertController.h"
#import "DatabaseModel.h"
#import "Alerts.h"
#import "StorageBrowserTableViewController.h"
#import "AppleICloudProvider.h"
#import "Settings.h"
#import "SafesList.h"
#import "OneDriveStorageProvider.h"

@interface SelectStorageProviderController ()

@property (nonatomic, copy, nonnull) NSArray<id<SafeStorageProvider>> *providers;

@end

@implementation SelectStorageProviderController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(self.existing) {
        [self.navigationItem setPrompt:@"Select where your existing safe is stored"];
    }
    else {
        [self.navigationItem setPrompt:@"Select where you would like to store your new safe"];
    }

    self.navigationController.toolbar.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(self.existing) {
        self.providers = @[[GoogleDriveStorageProvider sharedInstance],
                           [DropboxV2StorageProvider sharedInstance],
                           [OneDriveStorageProvider sharedInstance],
                           [LocalDeviceStorageProvider sharedInstance]];
    }
    else {
        if ([Settings sharedInstance].iCloudOn) {
            self.providers = @[[AppleICloudProvider sharedInstance],
                               [GoogleDriveStorageProvider sharedInstance],
                               [DropboxV2StorageProvider sharedInstance],
                               [OneDriveStorageProvider sharedInstance],
                               [LocalDeviceStorageProvider sharedInstance]];
        }
        else {
            self.providers = @[[GoogleDriveStorageProvider sharedInstance],
                               [DropboxV2StorageProvider sharedInstance],
                               [OneDriveStorageProvider sharedInstance],
                               [LocalDeviceStorageProvider sharedInstance]];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.providers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomStorageProviderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"storageProviderReuseIdentifier" forIndexPath:indexPath];
    
    id<SafeStorageProvider> provider = [self.providers objectAtIndex:indexPath.row];

    cell.text.text = provider.displayName;
    cell.image.image = [UIImage imageNamed:provider.icon];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<SafeStorageProvider> provider = [_providers objectAtIndex:indexPath.row];
    if (provider.storageId == kLocalDevice && !self.existing) {
        [Alerts yesNo:self
                title:@"Local Device Safe Caveat"
              message:@"Since a local safe is only stored on this device, any loss of this device will lead to the loss of "
         "all passwords stored within this safe. You may want to consider using a cloud storage provider, such as the ones "
         "supported by Strongbox to avoid catastrophic data loss.\n\nWould you still like to proceed with creating "
         "a local device safe?"
               action:^(BOOL response) {
                   if (response) {
                       [self segueToBrowserOrAdd:provider];
                   }
                   else {
                       [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                   }
               }];
    }
    else {
        [self segueToBrowserOrAdd:provider];
    }
}

- (void)segueToBrowserOrAdd:(id<SafeStorageProvider>)provider {
    if ((self.existing && provider.browsableExisting) || (!self.existing && provider.browsableNew)) {
        [self performSegueWithIdentifier:@"SegueToBrowser" sender:provider];
    }
    else {
        AddSafeAlertController *controller = [[AddSafeAlertController alloc] init];
        
        [controller addNew:self
                validation:^BOOL (NSString *name, NSString *password) {
                    return [[SafesList sharedInstance] isValidNickName:name] && password.length;
                }
                completion:^(NSString *name, NSString *password, BOOL response) {
                    if (response) {
                        NSString *nickName = [SafesList sanitizeSafeNickName:name];
                        
                        [self addNewSafeAndPopToRoot:nickName
                                            password:password
                                            provider:provider];
                    }
                }];
    }
}

- (void)addNewSafeAndPopToRoot:(NSString *)name password:(NSString *)password provider:(id<SafeStorageProvider>)provider {
    DatabaseModel *newSafe = [[DatabaseModel alloc] initNewWithPassword:password format:self.format];

    NSError *error;
    NSData *data = [newSafe getAsData:&error];
    
    if (data == nil) {
        [Alerts error:self title:@"Error Saving Safe" error:error];
        return;
    }
    
    [provider create:name
           extension:newSafe.fileExtension
                data:data
        parentFolder:nil
      viewController:self
          completion:^(SafeMetaData *metadata, NSError *error)
     {
         if (error == nil) {
             if(metadata.storageProvider == kiCloud) {
                 NSUInteger existing = [SafesList.sharedInstance.snapshot indexOfObjectPassingTest:^BOOL(SafeMetaData * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     return obj.storageProvider == kiCloud && [obj.fileName isEqualToString:metadata.fileName];
                 }];

                 if(existing == NSNotFound) { // May have already been added by our iCloud watch thread.
                     NSLog(@"Adding as this iCloud filename is not already present.");
                     [[SafesList sharedInstance] add:metadata];
                 }
                 else {
                     NSLog(@"Not Adding as this iCloud filename is already present. Probably picked up by Watch Thread.");
                 }
             }
             else {
                 [[SafesList sharedInstance] add:metadata];
             }
         }
         else {
             NSLog(@"An error occurred: %@", error);
             
             [Alerts error:self
                     title:@"Error Saving Safe"
                     error:error];
         }
         
         [self.navigationController popToRootViewControllerAnimated:YES];
     }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueToBrowser"]) {
        StorageBrowserTableViewController *vc = segue.destinationViewController;
        
        vc.existing = self.existing;
        vc.format = self.format;
        vc.safeStorageProvider = sender;
        vc.parentFolder = nil;
    }
}

@end
