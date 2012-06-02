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

#import "FBLoginDialog.h"
#import "FBRequest.h"

#define FBMethodPost   @"POST"
#define FBMethodGet    @"GET"
#define FBMethodDelete @"DELETE"

typedef enum {
	FacebookLoginSuccess,
	FacebookLoginCancelled,
	FacebookLoginFailed
} FacebookLoginState;

@class FBFrictionlessRequestSettings;
@protocol FBSessionDelegate;

/**
 * Main Facebook interface for interacting with the Facebook developer API.
 * Provides methods to log in and log out a user, make requests using the REST
 * and Graph APIs, and start user interface interactions (such as
 * pop-ups promoting for credentials, permissions, stream posts, etc.)
 */
@interface Facebook : NSObject<FBLoginDialogDelegate>{
    NSMutableSet* _requests;
    FBDialog* _loginDialog;
    FBDialog* _fbDialog;
    NSString* _appId;
    NSDate* _lastAccessTokenUpdate;
    FBFrictionlessRequestSettings* _frictionlessRequestSettings;
}

@property (nonatomic, copy) NSString* accessToken;
@property (nonatomic, copy) NSDate* expirationDate;
@property (nonatomic, copy) NSString* urlSchemeSuffix;
@property (nonatomic, readonly, getter=isFrictionlessRequestsEnabled) BOOL isFrictionlessRequestsEnabled;
@property (nonatomic, assign) BOOL extendTokenOnApplicationActive;
@property (nonatomic, readonly) NSSet *permissions;

@property (copy) void (^requestStarted)();
@property (copy) void (^requestFinished)();

+ (Facebook*)shared:(NSString*)appID;
+ (Facebook*)shared;

- (void)authorize:(NSArray *)permissions;

- (void)authorize:(NSArray *)permissions 
		  granted:(void(^)(Facebook *))_grantedHandler 
		   denied:(void(^)(Facebook*))_deniedHandler;

- (void)usingPermissions:(NSArray*)permissions
				 request:(void(^)())_request;

- (void)usingPermission:(NSString*)permission
				request:(void(^)())_request;

- (void)extendAccessToken;

- (void)extendAccessTokenIfNeeded;

- (BOOL)shouldExtendAccessToken;

- (BOOL)handleOpenURL:(NSURL *)url;

- (void)logout;

- (FBRequest*)requestWithParameters:(NSDictionary *)params
						   finalize:(void(^)(FBRequest*request))finalize;

- (FBRequest*)requestWithMethodName:(NSString *)methodName
						 parameters:(NSDictionary *)params
					  requestMethod:(NSString *)httpMethod
						   finalize:(void(^)(FBRequest*request))finalize;


- (FBRequest*)requestWithMethodName:(NSString *)methodName 
						 parameters:(NSDictionary *)params 
						 completion:(void (^)(FBRequest *request,id result))completion;

- (FBRequest*)requestWithMethodName:(NSString *)methodName 
						 parameters:(NSDictionary *)params 
						 completion:(void (^)(FBRequest*request,id result))completion 
							  error:(void (^)(FBRequest*request,NSError *error))error;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						  finalize:(void(^)(FBRequest*request))finalize;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSDictionary *)params
						  finalize:(void(^)(FBRequest*request))finalize;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSDictionary *)params
					 requestMethod:(NSString *)httpMethod
						  finalize:(void(^)(FBRequest*request))finalize;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSDictionary *)params
						  completion:(void (^)(FBRequest*request,id result))completion;

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSDictionary *)params
						completion:(void (^)(FBRequest*request,id result))completion 
							 error:(void (^)(FBRequest*request,NSError *error))error;

- (void)dialog:(NSString *)action
	  delegate:(id<FBDialogDelegate>)delegate;

- (void)dialog:(NSString *)action
	parameters:(NSDictionary *)params
	  delegate:(id <FBDialogDelegate>)delegate;

- (BOOL)isSessionValid;

- (void)enableFrictionlessRequests;

- (void)reloadFrictionlessRecipientCache;

- (BOOL)isFrictionlessEnabledForRecipient:(id)fbid;

- (BOOL)isFrictionlessEnabledForRecipients:(NSArray*)fbids;

- (void)addLoginHandler:(void(^)(Facebook*, FacebookLoginState state))handler;
- (void)addExtendTokenHandler:(void(^)(Facebook *facebook, NSString *token, NSDate *expiresAt))handler;
- (void)addLogoutHandler:(void(^)(Facebook*))handler;
- (void)addSessionInvalidatedHandler:(void(^)(Facebook*))handler;

@end

////////////////////////////////////////////////////////////////////////////////

