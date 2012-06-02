//
//  SHBAppDelegate.m
//  SmallHackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "SHBAppDelegate.h"
#import "SHBViewController.h"

@implementation SHBAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.viewController = [[SHBViewController alloc] initWithNibName:@"SHBViewController" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
