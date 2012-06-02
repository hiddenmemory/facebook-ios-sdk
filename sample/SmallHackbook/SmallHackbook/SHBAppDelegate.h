//
//  SHBAppDelegate.h
//  SmallHackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"

@class SHBViewController;

@interface SHBAppDelegate : FBAppDelegate <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SHBViewController *viewController;

@end
