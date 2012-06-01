//
//  Facebook+Facebook_Delegate_h.h
//  Hackbook
//
//  Created by Chris Ross on 01/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

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
