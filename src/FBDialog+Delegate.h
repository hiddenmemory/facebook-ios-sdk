//
//  FBDialog+Delegate.h
//  facebook-ios-sdk
//
//  Created by Kieran Gutteridge on 02/06/2012.
//  Copyright (c) 2012 Intohand Ltd. All rights reserved.
//

#import "FBDialog.h"



/*
 *Your application should implement this delegate
 */
@protocol FBDialogDelegate <NSObject>

@optional

/**
 * Called when the dialog succeeds and is about to be dismissed.
 */
- (void)dialogDidComplete:(FBDialog *)dialog;

/**
 * Called when the dialog succeeds with a returning url.
 */
- (void)dialog:(FBDialog*)dialog didCompleteWithURL:(NSURL *)url;

/**
 * Called when the dialog get canceled by the user.
 */
- (void)dialog:(FBDialog*)dialog didNotCompleteWithURL:(NSURL *)url;

/**
 * Called when the dialog is cancelled and is about to be dismissed.
 */
- (void)dialogWasCancelled:(FBDialog *)dialog;

/**
 * Called when dialog failed to load due to an error.
 */
- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error;

/**
 * Asks if a link touched by a user should be opened in an external browser.
 *
 * If a user touches a link, the default behavior is to open the link in the Safari browser,
 * which will cause your app to quit.  You may want to prevent this from happening, open the link
 * in your own internal browser, or perhaps warn the user that they are about to leave your app.
 * If so, implement this method on your delegate and return NO.  If you warn the user, you
 * should hold onto the URL and once you have received their acknowledgement open the URL yourself
 * using [[UIApplication sharedApplication] openURL:].
 */
- (BOOL)dialog:(FBDialog*)dialog shouldOpenURLInExternalBrowser:(NSURL *)url;

@end

@interface FBDialog (Delegate)
@property(nonatomic,weak) id<FBDialogDelegate> delegate;
@end

