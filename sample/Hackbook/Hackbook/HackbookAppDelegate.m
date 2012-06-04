/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "HackbookAppDelegate.h"
#import "RootViewController.h"
#import "DataSet.h"

// Your Facebook APP Id must be set before running this example
// See http://www.facebook.com/developers/createapp.php
// Also, your application must bind to the fb[app_id]:// URL
// scheme (substitue [app_id] for your real Facebook app id).
static NSString* kAppId = @"210849718975311";

@implementation HackbookAppDelegate

@synthesize window=_window;

@synthesize navigationController=_navigationController;

@synthesize apiData;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Setup view controllers
    RootViewController *rootViewController = [[RootViewController alloc] init];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    [navController.navigationBar setTintColor:[UIColor colorWithRed:0/255.0
                                                              green:51.0/255.0
                                                               blue:102.0/255.0
                                                              alpha:1.0]];
    [navController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    self.navigationController = navController;

    // Initialize API data (for views, etc.)
    apiData = [[DataSet alloc] init];
    
    // Initialize user permissions
    userPermissions = [NSMutableDictionary dictionary];
    
    // Override point for customization after application launch.
    // Add the navigation controller's view to the window and display.
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    // Check App ID:
    // This is really a warning for the developer, this should not
    // happen in a completed app
    if (!kAppId) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Setup Error"
                                  message:@"Missing app ID. You cannot run the app until you provide this in the code."
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil,
                                  nil];
        [alertView show];
	}
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Although the SDK attempts to refresh its access tokens when it makes API calls,
    // it's a good practice to refresh the access token also when the app becomes active.
    // This gives apps that seldom make api calls a higher chance of having a non expired
    // access token.
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    // Quit the app
    exit(1);
}

@end
