//
//  ViewController.m
//  Permissions
//
//  Created by Villars Gimm on 06/02/14.
//  Copyright (c) 2014 Villars Gimm. All rights reserved.

@import AddressBook;
@import EventKit;
@import AVFoundation;
@import CoreBluetooth;
@import CoreMotion;
@import Accounts;
@import UIKit;
#import "RowDetails.h"

static NSString *const CalCellIdentifier = @"cell identifier";

typedef enum : NSInteger {
  kRowLocationServices = 0,
  kRowContacts,
  kRowCalendars,
  kRowReminders,
  kRowPhotos,
  kRowBlueTooth,
  kRowMicrophone,
  kRowMotionActivity,
  kRowCamera,
  kFacebook,
  kTwitter,
  kNumberOfRows
} CalTableRows;

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) EKEventStore *eventStore;
@property (strong, nonatomic) UIImagePickerController *picker;
@property (strong, nonatomic) CBCentralManager *cbManager;
@property (strong, nonatomic) CMMotionActivityManager *cmManger;
@property (strong, nonatomic) NSOperationQueue* motionActivityQueue;
@property (strong, nonatomic) ACAccountStore *accountStore;

- (ABAddressBookRef) addressBook;
- (void) setAddressBook:(ABAddressBookRef) newAddressBook;

@property (weak, nonatomic) IBOutlet UITableView *table;

- (RowDetails *) detailsForRowAtIndexPath:(NSIndexPath *) path;
- (void) rowTouchedLocationServices;
- (void) rowTouchedContacts;
- (void) rowTouchedCalendars;
- (void) rowTouchedReminders;
- (void) rowTouchedPhotos;
- (void) rowTouchedBluetooth;
- (void) rowTouchedMicrophone;
- (void) rowTouchedMotionActivity;
- (void) rowTouchedCamera;
- (void) rowTouchedFacebook;
- (void) rowTouchedTwitter;

@end

@implementation ViewController{
  ABAddressBookRef _addressBook;
}

#pragma mark - Memory Management

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}


#pragma mark - Row Touched: Location Services

- (void) rowTouchedLocationServices {
  NSLog(@"Location Services requested");

  self.locationManager = [[CLLocationManager alloc] init];
  self.locationManager.delegate = self;

  SEL authorizationSelector = @selector(requestWhenInUseAuthorization);
  if ([self.locationManager respondsToSelector:authorizationSelector]) {
    NSLog(@"Requesting when-in-use authorization");
    [self.locationManager requestWhenInUseAuthorization];
  } else {
    if ([CLLocationManager locationServicesEnabled]) {
      NSLog(@"Calling startUpdatingLocation");
      [self.locationManager startUpdatingLocation];
    }
  }
}

#pragma mark - Row Touched: Contacts

- (void) rowTouchedContacts {
  NSLog(@"Contacts requested");
  ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);

  if (addressBook) {
    self.addressBook = CFAutorelease(addressBook);

     // Register for a callback if the addressbook data changes this is
     // important to be notified of new data when the user grants access to the
     // contacts. the application should also be able to handle a nil object
     // being returned as well if the user denies access to the address book.
    ABAddressBookRegisterExternalChangeCallback(self.addressBook,
                                                handleAddressBookChange,
                                                (__bridge void *)(self));

    // When the application requests to receive address book data that is when
    // the user is presented with a consent dialog.
    ABAddressBookRequestAccessWithCompletion(self.addressBook,
                                             ^(bool granted, CFErrorRef error) {
    });
  }
}

#pragma mark - Row Touched: Calendars

- (void) rowTouchedCalendars {
  NSLog(@"Calendar requested");

  self.eventStore = [[EKEventStore alloc] init];

  [self.eventStore requestAccessToEntityType:EKEntityTypeEvent
                                  completion:^(BOOL granted, NSError *error) {

                                  }];
}

- (void) rowTouchedReminders {
  NSLog(@"Reminders requested");

  self.eventStore = [[EKEventStore alloc] init];

  [self.eventStore requestAccessToEntityType:EKEntityTypeReminder
                                  completion:^(BOOL granted, NSError *error) {

                                  }];
}

#pragma mark - Row Touched: Photos

- (void) rowTouchedPhotos {
  NSLog(@"Photos requested");
  UIImagePickerController *picker = [[UIImagePickerController alloc]init];
  [picker setDelegate:self];

  [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - Row Touched: Bluetooth

- (void) rowTouchedBluetooth {
  NSLog(@"Bluetooth Sharing is requested");

  if (!self.cbManager) {
    self.cbManager = [[CBCentralManager alloc]
                      initWithDelegate:self
                      queue:dispatch_get_main_queue()
                      options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];
  }

  [self.cbManager scanForPeripheralsWithServices:nil options:nil];
}

#pragma mark - Row Touched: Microphone

- (void) rowTouchedMicrophone {
  NSLog(@"Microphone requested");

  AVAudioSession *session = [[AVAudioSession alloc] init];
  [session requestRecordPermission:^(BOOL granted) {
    if (granted) {
      NSLog(@"Micro Permission Granted");
      NSError *error;

      [session setActive:YES error:&error];
      [session setCategory:@"AVAudioSessionCategoryPlayAndRecord" error:&error];
    } else {
      NSLog(@"Permission Denied");
    }
  }];
}

#pragma mark - Row Touched: Motion Activity

- (void) rowTouchedMotionActivity {
  NSLog(@"Motion Acitivty requested");
  self.cmManger = [[CMMotionActivityManager alloc]init];
  self.motionActivityQueue = [[NSOperationQueue alloc] init];

  [self.cmManger startActivityUpdatesToQueue:self.motionActivityQueue
                                 withHandler:^(CMMotionActivity *activity) {
  }];
}

#pragma mark - Row Touched: Camera

- (void) rowTouchedCamera {
  if ([AVCaptureDevice respondsToSelector:@selector(requestAccessForMediaType:completionHandler:)]) {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
      // Will get here on both iOS 7 & 8 even though camera permissions weren't required
      // until iOS 8. So for iOS 7 permission will always be granted.
      if (granted) {
        // Permission has been granted. Use dispatch_async for any UI updating
        // code because this block may be executed in a thread.
        dispatch_async(dispatch_get_main_queue(), ^{

        });
      } else {
        // Permission has been denied.
      }
    }];
  } else {
    // We are on iOS <= 6. Just do what we need to do.
  }
}

#pragma mark - Row Touched: Facebook

- (void) rowTouchedFacebook {
  // not yet
  // http://nsscreencast.com/episodes/57-facebook-integration

  NSString *title = NSLocalizedString(@"Not Implemented",
                                      @"Alert title: feature is not implemented yet");
  NSString *message = NSLocalizedString(@"Testing Facebook permissions has not been implemented.",
                                        @"Alert message");
  NSString *localizedDismiss = NSLocalizedString(@"Dismiss",
                                                 @"Alert button title: touching dismissing the alert with no consequences");
  UIAlertView *alert = [[UIAlertView alloc]
                        initWithTitle:title
                        message:message
                        delegate:self
                        cancelButtonTitle:localizedDismiss
                        otherButtonTitles:nil];
  [alert show];

/*
  NSLog(@"Facebook requested");
  if (!self.accountStore) {
    self.accountStore = [[ACAccountStore alloc] init];
  }
  ACAccountType *facebookAccount =
  [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];

  NSDictionary *options = @{
                            ACFacebookAppIdKey:@"697227803740028",
                            ACFacebookPermissionsKey:@[@"read_friendlists"],
                            ACFacebookAudienceKey: ACFacebookAudienceFriends,
                            };

  [self.accountStore
   requestAccessToAccountsWithType:facebookAccount
   options:options completion:^(BOOL granted,
                                NSError *error) {
     if (granted) {
       NSLog(@"Facebook granted!");
       ACAccount *fbAccount = [[self.accountStore
                                accountsWithAccountType:facebookAccount]
                               lastObject];
     } else {
       NSLog(@"Not granted: %@", error);
     }

  }];
  */
}


#pragma mark - Row Touched: Twitter

- (void) rowTouchedTwitter {

  NSLog(@"Twitter Requested");

  if (!self.accountStore) {
    self.accountStore = [[ACAccountStore alloc] init];
  }
  ACAccountType *twitterAccount = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

  [self.accountStore requestAccessToAccountsWithType:twitterAccount options:nil completion:^(BOOL granted, NSError *error) {
  }];
}

#pragma mark - <UITableViewDataSource>

- (RowDetails *) detailsForRowAtIndexPath:(NSIndexPath *) path {
  RowDetailsFactory *factory = [RowDetailsFactory shared];
  RowDetails *details = [factory detailsForRowAtIndexPath:path];
  if (details) { return details; }

  SEL selector = nil;
  NSString *title = nil;
  NSString *identifier = nil;

  CalTableRows row = (CalTableRows)path.row;
  switch (row) {
    case kRowLocationServices: {
      selector = @selector(rowTouchedLocationServices);
      title = @"Location Services";
      identifier = @"location";
      break;
    }

    case kRowContacts: {
      selector = @selector(rowTouchedContacts);
      title = @"Contacts";
      identifier = @"contacts";
      break;
    }

    case kRowCalendars: {
      selector = @selector(rowTouchedCalendars);
      title = @"Calendars";
      identifier = @"calendars";
      break;
    }

    case kRowReminders: {
      selector = @selector(rowTouchedReminders);
      title = @"Reminders";
      identifier = @"reminders";
      break;
    }

    case kRowPhotos: {
      selector = @selector(rowTouchedPhotos);
      title = @"Photos";
      identifier = @"photos";
      break;
    }

    case kRowBlueTooth: {
      selector = @selector(rowTouchedBluetooth);
      title = @"Bluetooth Sharing";
      identifier = @"bluetooth";
      break;
    }

    case kRowMicrophone: {
      selector = @selector(rowTouchedMicrophone);
      title = @"Microphone";
      identifier = @"microphone";
      break;
    }

    case kRowMotionActivity: {
      selector = @selector(rowTouchedMotionActivity);
      title = @"Motion Activity";
      identifier = @"motion";
      break;
    }

    case kRowCamera: {
      selector = @selector(rowTouchedCamera);
      title = @"Camera";
      identifier = @"camara";
      break;
    }

    case kFacebook: {
      selector = @selector(rowTouchedFacebook);
      title = @"Facebook";
      identifier = @"facebook";
      break;
    }

    case kTwitter: {
      selector = @selector(rowTouchedTwitter);
      title = @"Twitter";
      identifier = @"twitter";
      break;
    }

    default: {
      NSString *reason;
      reason = [NSString stringWithFormat:@"Could not create row details for row %@",
                @(row)];
      @throw [NSException exceptionWithName:@"Fell through switch"
                                     reason:reason
                                   userInfo:nil];

      break;
    }
  }

  details = [[RowDetails alloc]
             initWithSelector:selector
             title:title
             identifier:identifier];
  return details;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) aSection {
  return kNumberOfRows;
}

- (UITableViewCell *) tableView:(UITableView *) tableView
          cellForRowAtIndexPath:(NSIndexPath *) indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CalCellIdentifier];

  RowDetails *details = [self detailsForRowAtIndexPath:indexPath];
  cell.textLabel.text = details.title;
  cell.accessibilityIdentifier = details.identifier;

  return cell;
}

#pragma mark - <UITableViewDelegate>

- (CGFloat) tableView:(UITableView *) tableView heightForRowAtIndexPath:(NSIndexPath *) indexPath {
  return 44;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
  RowDetails *details = [self detailsForRowAtIndexPath:indexPath];
  SEL selector = details.selector;

  NSMethodSignature *signature;
  signature = [[self class] instanceMethodSignatureForSelector:selector];

  NSInvocation *invocation;
  invocation = [NSInvocation invocationWithMethodSignature:signature];

  invocation.target = self;
  invocation.selector = selector;

  [invocation invoke];

  double delayInSeconds = 0.4;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
  });
}

#pragma mark - Address Book

- (ABAddressBookRef) addressBook {
  return _addressBook;
}

- (void) setAddressBook:(ABAddressBookRef) newAddressBook {
  if (_addressBook != newAddressBook) {
    if (_addressBook != NULL) {
      CFRelease(_addressBook);
    }
    if (newAddressBook != NULL) {
      CFRetain(newAddressBook);
    }
    _addressBook = newAddressBook;
  }
}

void handleAddressBookChange(ABAddressBookRef addressBook,
                             CFDictionaryRef info,
                             void *context) {

}

#pragma mark - <CBCentralManagerDelegate>

- (void) centralManagerDidUpdateState:(CBCentralManager *)central{
  NSLog(@"Central Bluetooth manager did update state");
  if (central.state != CBCentralManagerStatePoweredOn) { return; }

  if (central.state == CBCentralManagerStatePoweredOn) {
    [self.cbManager scanForPeripheralsWithServices:nil options:nil];
  }
}

#pragma mark - <CLLocationManagerDelegate>

// This method is called whenever the application’s ability to use location
// services changes. Changes can occur because the user allowed or denied the
// use of location services for your application or for the system as a whole.
//
// If the authorization status is already known when you call the
// requestWhenInUseAuthorization or requestAlwaysAuthorization method, the
// location manager does not report the current authorization status to this
// method. The location manager only reports changes to the authorization
// status. For example, it calls this method when the status changes from
// kCLAuthorizationStatusNotDetermined to kCLAuthorizationStatusAuthorizedWhenInUse.
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
  NSLog(@"did change authorization status: %@", @(status));
  CLAuthorizationStatus notDetermined = kCLAuthorizationStatusNotDetermined;
  CLAuthorizationStatus denied = kCLAuthorizationStatusDenied;
  if (status != notDetermined && status != denied) {
    [manager startUpdatingLocation];
  } else {
    NSLog(@"Cannot update location because:");
    if (status == notDetermined) {
      NSLog(@"CoreLocation authorization is not determined");
    } else {
      NSLog(@"CoreLocation authorization is not denied");
    }
  }
}

#pragma mark - Orientation / Rotation

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 90000
- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}
#else
- (NSUInteger) supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAll;
}
#endif

- (BOOL) shouldAutorotate {
  return YES;
}

#pragma mark - View Lifecycle

- (void) setContentInsets:(UITableView *)tableView {
  CGFloat topHeight = 0;
  if (![[UIApplication sharedApplication] isStatusBarHidden]) {
    CGRect frame = [[UIApplication sharedApplication] statusBarFrame];
    topHeight = topHeight + frame.size.height;
  }
  tableView.contentInset = UIEdgeInsetsMake(topHeight, 0, 0, 0);
}

- (void) viewDidLoad {
  [super viewDidLoad];

  [self.table registerClass:[UITableViewCell class]
         forCellReuseIdentifier:CalCellIdentifier];
}

- (void) viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
}

- (void) viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
}

@end
