//
//  FBAppDelegate.m
//  SmallHackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "FBAppDelegate.h"
#import "Facebook.h"

@implementation FBAppDelegate

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[NSURLConnection connectionWithRequest:request delegate:nil];
	return NO;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	[NSURLConnection connectionWithRequest:request delegate:nil];
	return NO;
}

@end
