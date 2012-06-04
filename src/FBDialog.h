/*
 * Copyright 2012 Chris Ross - hiddenMemory Ltd - chris@hiddenmemory.co.uk
 * Copyright 2012 Kieran Gutteridge - IntoHand Ltd - kieran.gutteridge@intohand.com
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBBlockHandler.h"

typedef enum { 
    kFBDialogSuccess,
    kFBDialogCancelled,
    kFBDialogFailed
} FBDialogState;

@protocol FBDialogDelegate;
@class FBFrictionlessRequestSettings;

/**
 * Do not use this interface directly, instead, use dialog in Facebook.h
 *
 * Facebook dialog interface for start the facebook webView UIServer Dialog.
 */

#define kFBCompletionURLBlockHandlerKey @"completion-url"

@interface FBDialog : UIView <UIWebViewDelegate, FBBlockProvider> {
    NSString * _serverURL;
    NSURL* _loadingURL;
    UIWebView* _webView;
    UIActivityIndicatorView* _spinner;
    UIButton* _closeButton;
    UIInterfaceOrientation _orientation;
    BOOL _showingKeyboard;
    BOOL _isViewInvisible;
    FBFrictionlessRequestSettings* _frictionlessSettings;
    // Ensures that UI elements behind the dialog are disabled.
    UIView* _modalBackgroundView;
}

/**
 * The parameters.
 */
@property(nonatomic, strong) NSMutableDictionary* params;

@property (nonatomic, copy) BOOL (^shouldOpenURLInExternalBrowser)( NSURL *url );

- (NSString *) getStringFromUrl: (NSString*) url needle:(NSString *) needle;

- (id)initWithURL: (NSString *) loadingURL
	   parameters: (NSDictionary *) params
  isViewInvisible: (BOOL) isViewInvisible
frictionlessSettings: (FBFrictionlessRequestSettings *) frictionlessSettings;

/**
 * Displays the view with an animation.
 *
 * The view will be added to the top of the current key window.
 */
- (void)show;

/**
 * Displays the first page of the dialog.
 *
 * Do not ever call this directly.  It is intended to be overriden by subclasses.
 */
- (void)load;

/**
 * Displays a URL in the dialog.
 */
- (void)loadURL:(NSString*)url
            get:(NSDictionary*)getParams;

/**
 * Hides the view and notifies delegates of success or cancellation.
 */
- (void)dismissWithSuccess:(BOOL)success animated:(BOOL)animated;

/**
 * Hides the view and notifies delegates of an error.
 */
- (void)dismissWithError:(NSError*)error animated:(BOOL)animated;

/**
 * Subclasses may override to perform actions just prior to showing the dialog.
 */
- (void)dialogWillAppear;

/**
 * Subclasses may override to perform actions just after the dialog is hidden.
 */
- (void)dialogWillDisappear;

/**
 * Subclasses should override to process data returned from the server in a 'fbconnect' url.
 *
 * Implementations must call dismissWithSuccess:YES at some point to hide the dialog.
 */
- (void)dialogDidSucceed:(NSURL *)url;

/**
 * Subclasses should override to process data returned from the server in a 'fbconnect' url.
 *
 * Implementations must call dismissWithSuccess:YES at some point to hide the dialog.
 */
- (void)dialogDidCancel:(NSURL *)url;


- (void)addCompletionHandler:(void(^)(FBDialog *dialog, FBDialogState state))completionHandler;
- (void)addCompletionURLHandler:(void(^)(FBDialog *dialog, NSURL *url, FBDialogState state))completionURLHandler;
- (void)addErrorHandler:(void (^)(FBDialog *dialog, NSError *error))errorHandler;


@end

///////////////////////////////////////////////////////////////////////////////////////////////////

