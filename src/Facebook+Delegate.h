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

#import "Facebook.h"

/**
 * Your application should implement this delegate to receive session callbacks.
 */
@protocol FBSessionDelegate <NSObject>

/**
 * Called when the user successfully logged in.
 */
- (void)facebookDidLogin:(Facebook*)facebook;

/**
 * Called when the user dismissed the dialog without logging in.
 */
- (void)facebook:(Facebook*)facebook didNotLogin:(BOOL)cancelled;

/**
 * Called after the access token was extended. If your application has any
 * references to the previous access token (for example, if your application
 * stores the previous access token in persistent storage), your application
 * should overwrite the old access token with the new one in this method.
 * See extendAccessToken for more details.
 */
- (void)facebook:(Facebook*)facebook didExtendToken:(NSString*)accessToken expiresAt:(NSDate*)expiresAt;

/**
 * Called when the user logged out.
 */
- (void)facebookDidLogout:(Facebook*)facebook;

/**
 * Called when the current session has expired. This might happen when:
 *  - the access token expired
 *  - the app has been disabled
 *  - the user revoked the app's permissions
 *  - the user changed his or her password
 */
- (void)facebookSessionInvalidated:(Facebook*)facebook;

@end

@interface Facebook (Delegate)
@property (nonatomic, weak) id<FBSessionDelegate> delegate;
@end
