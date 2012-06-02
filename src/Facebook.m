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
#import "FBFrictionlessRequestSettings.h"
#import "FBLoginDialog.h"
#import "FBRequest.h"

static NSString* kDialogBaseURL = @"https://m.facebook.com/dialog/";
static NSString* kGraphBaseURL = @"https://graph.facebook.com/";
static NSString* kRestserverBaseURL = @"https://api.facebook.com/method/";

static NSString* kFBAppAuthURLScheme = @"fbauth";
static NSString* kFBAppAuthURLPath = @"authorize";
static NSString* kRedirectURL = @"fbconnect://success";

static NSString* kLogin = @"oauth";
static NSString* kApprequests = @"apprequests";
static NSString* kSDK = @"ios";
static NSString* kSDKVersion = @"2";

// If the last time we extended the access token was more than 24 hours ago
// we try to refresh the access token again.
static const int kTokenExtendThreshold = 24;

static NSString *requestFinishedKeyPath = @"state";
static void *finishedContext = @"finishedContext";

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface Facebook () {
	NSMutableArray *loginHandlers;
	NSMutableArray *extendedTokenHandlers;
	NSMutableArray *logoutHandlers;
	NSMutableArray *sessionInvalidHandlers;
	BOOL _isExtendingAccessToken;
}

// private properties
@property (strong) NSArray *lastRequestedPermissions;
@property (nonatomic, copy) NSString* appId;

- (id)initWithAppID:(NSString*)appID;
- (void)fetchActiveUserPermissions;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

static Facebook *facebookSharedObject = nil;

@implementation Facebook

@synthesize    accessToken = _accessToken,
expirationDate = _expirationDate,
permissions = _permissions,
urlSchemeSuffix = _urlSchemeSuffix,
appId = _appId,
extendTokenOnApplicationActive = _extendTokenOnApplicationActive,
lastRequestedPermissions = _lastRequestedPermissions;

@synthesize requestStarted, requestFinished;

+ (Facebook*)bind:(NSString *)appID {
	static dispatch_once_t pred = 0; \
	dispatch_once(&pred, ^{
		NSLog(@"Binding to %@", appID);
		facebookSharedObject = [[Facebook alloc] initWithAppID:appID];
		if( facebookSharedObject.isSessionValid ) {
			[facebookSharedObject fetchActiveUserPermissions];
		}
	});
	return facebookSharedObject;
}
+ (void)autobind:(NSNotification*)notification {
	NSArray* aBundleURLTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
	if ([aBundleURLTypes isKindOfClass:[NSArray class]] && ([aBundleURLTypes count] > 0)) {
		NSDictionary* aBundleURLTypes0 = [aBundleURLTypes objectAtIndex:0];
		if ([aBundleURLTypes0 isKindOfClass:[NSDictionary class]]) {
			NSArray* aBundleURLSchemes = [aBundleURLTypes0 objectForKey:@"CFBundleURLSchemes"];
			if ([aBundleURLSchemes isKindOfClass:[NSArray class]] && ([aBundleURLSchemes count] > 0)) {
				NSString *scheme = [aBundleURLSchemes objectAtIndex:0];
				if ([scheme isKindOfClass:[NSString class]] && [scheme hasPrefix:@"fb"]) {
					[self bind:[scheme substringFromIndex:2]];
				}
			}
		}
	}
}
+ (Facebook*)shared {
	if( !facebookSharedObject ) {
		@throw [NSError errorWithDomain:@"com.facebook.iOS.RequiresAppIDError" code:42 userInfo:nil];
	}
	return facebookSharedObject;
}
+ (void)load {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(autobind:)
												 name:UIApplicationDidFinishLaunchingNotification
											   object:nil];
}

- (void)applicationDidBecomeActive:(NSNotification*)notification {
	[self extendAccessTokenIfNeeded];
}

- (void)setExtendTokenOnApplicationActive:(BOOL)_ {
	if( _ ) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationDidBecomeActive:)
													 name:UIApplicationDidBecomeActiveNotification
												   object:nil];
	}
	else {
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:UIApplicationDidBecomeActiveNotification
													  object:nil];		
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

#define FBAccessTokenKey [NSString stringWithFormat:@"com.facebook.ios.token:%@", \
							[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]]
#define FBExpirationDateKey [NSString stringWithFormat:@"com.facebook.ios.expiration:%@", \
								[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]]

- (void)storeAccessToken {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.accessToken forKey:FBAccessTokenKey];
    [defaults setObject:self.expirationDate forKey:FBExpirationDateKey];
    [defaults synchronize];
}

- (void)loadAccessToken {
	// Check and retrieve authorization information
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:FBAccessTokenKey] && [defaults objectForKey:FBExpirationDateKey]) {
        self.accessToken = [defaults objectForKey:FBAccessTokenKey];
        self.expirationDate = [defaults objectForKey:FBExpirationDateKey];
    }
}

- (void)validateApplicationURLScheme {
	// Now check that the URL scheme fb[app_id]://authorize is in the .plist and can
	// be opened, doing a simple check without local app id factored in here
	NSString *url = [NSString stringWithFormat:@"fb%@://authorize", self.appId];
	BOOL bSchemeInPlist = NO; // find out if the sceme is in the plist file.
	NSArray* aBundleURLTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
	if ([aBundleURLTypes isKindOfClass:[NSArray class]] && ([aBundleURLTypes count] > 0)) {
		NSDictionary* aBundleURLTypes0 = [aBundleURLTypes objectAtIndex:0];
		if ([aBundleURLTypes0 isKindOfClass:[NSDictionary class]]) {
			NSArray* aBundleURLSchemes = [aBundleURLTypes0 objectForKey:@"CFBundleURLSchemes"];
			if ([aBundleURLSchemes isKindOfClass:[NSArray class]] && ([aBundleURLSchemes count] > 0)) {
				NSString *scheme = [aBundleURLSchemes objectAtIndex:0];
				if ([scheme isKindOfClass:[NSString class]] && [url hasPrefix:scheme]) {
					bSchemeInPlist = YES;
				}
			}
		}
	}

	// Check if the authorization callback will work
	BOOL bCanOpenUrl = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString: url]];
	if (!bSchemeInPlist || !bCanOpenUrl) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Setup Error", @"")
															message:NSLocalizedString(@"Invalid or missing URL scheme. You cannot run the app until you set up a valid URL scheme in your .plist.", @"")
														   delegate:self
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil,
								  nil];
		[alertView show];
	}
}

- (void)fetchActiveUserPermissions {
	[self requestWithGraphPath:@"me/permissions"
					  finalize:^(FBRequest *request) {
						  [request addCompletionHandler:^(FBRequest *request, id result) {
							  _permissions = [NSSet setWithArray:[[[result objectForKey:@"data"] objectAtIndex:0] allKeys]];
							  NSLog(@"Permissions: %@", self.permissions);
						  }];
					  }];
}

/**
 * Initialize the Facebook object with application ID.
 *
 * @param appId the facebook app id
 * @param urlSchemeSuffix
 *   urlSchemeSuffix is a string of lowercase letters that is
 *   appended to the base URL scheme used for SSO. For example,
 *   if your facebook ID is "350685531728" and you set urlSchemeSuffix to
 *   "abcd", the Facebook app will expect your application to bind to
 *   the following URL scheme: "fb350685531728abcd".
 *   This is useful if your have multiple iOS applications that
 *   share a single Facebook application id (for example, if you
 *   have a free and a paid version on the same app) and you want
 *   to use SSO with both apps. Giving both apps different
 *   urlSchemeSuffix values will allow the Facebook app to disambiguate
 *   their URL schemes and always redirect the user back to the
 *   correct app, even if both the free and the app is installed
 *   on the device.
 *   urlSchemeSuffix is supported on version 3.4.1 and above of the Facebook
 *   app. If the user has an older version of the Facebook app
 *   installed and your app uses urlSchemeSuffix parameter, the SDK will
 *   proceed as if the Facebook app isn't installed on the device
 *   and redirect the user to Safari.
 * @param delegate the FBSessionDelegate
 */
- (id)initWithAppID:(NSString *)appId {
    self = [super init];
    if (self) {
        _requests = [NSMutableSet set];
        _lastAccessTokenUpdate = [NSDate distantPast];
        _frictionlessRequestSettings = [[FBFrictionlessRequestSettings alloc] init];
        self.appId = appId;
        self.urlSchemeSuffix = nil;
		self.extendTokenOnApplicationActive = YES;
		
		loginHandlers = [NSMutableArray array];
		extendedTokenHandlers = [NSMutableArray array];
		logoutHandlers = [NSMutableArray array];
		sessionInvalidHandlers = [NSMutableArray array];
		
		self.requestStarted = ^{};
		self.requestFinished = ^{};
		
		[self loadAccessToken];
		[self validateApplicationURLScheme];
	}
    return self;
}

/**
 * Override NSObject : free the space
 */
- (void)dealloc {
    for (FBRequest* _request in _requests) {
        [_request removeObserver:self forKeyPath:requestFinishedKeyPath];
    }
}

- (void)invalidateSession {
	_permissions = [NSSet set];
	
    self.accessToken = nil;
    self.expirationDate = nil;
	
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:FBAccessTokenKey];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:FBExpirationDateKey];
    
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray* facebookCookies = [cookies cookiesForURL:
                                [NSURL URLWithString:@"http://login.facebook.com"]];
    
    for (NSHTTPCookie* cookie in facebookCookies) {
        [cookies deleteCookie:cookie];
    }
    
    // setting to nil also terminates any active request for whitelist
    [_frictionlessRequestSettings updateRecipientCacheWithRecipients:nil]; 
}

/**
 * A private helper function for sending HTTP requests.
 *
 * @param url
 *            url to send http request
 * @param params
 *            parameters to append to the url
 * @param httpMethod
 *            http method @"GET" or @"POST"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 */
- (FBRequest*)openUrl:(NSString *)url
               params:(NSDictionary *)_params
		requestMethod:(NSString *)httpMethod
			 finalize:(void(^)(FBRequest*))finalize {
    
	NSMutableDictionary *params = (_params 
								   ? [NSMutableDictionary dictionaryWithDictionary:_params]
								   : [NSMutableDictionary dictionary]);
	
    [params setValue:@"json" forKey:@"format"];
    [params setValue:kSDK forKey:@"sdk"];
    [params setValue:kSDKVersion forKey:@"sdk_version"];
    if ([self isSessionValid]) {
        [params setValue:self.accessToken forKey:@"access_token"];
    }
    
    [self extendAccessTokenIfNeeded];
    
    FBRequest* _request = [FBRequest getRequestWithParameters:params
												requestMethod:httpMethod
												   requestURL:url];
    [_requests addObject:_request];
    [_request addObserver:self forKeyPath:requestFinishedKeyPath options:0 context:finishedContext];
	
	if( finalize ) {
		finalize(_request);
	}
	
    [_request connect];
    return _request;
}

- (void)_applyCoreHandlers:(NSArray*)list {
	[[list copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		void (^handler)(Facebook*) = (void(^)(Facebook*))obj;
		handler(self);
	}];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == finishedContext) {
        FBRequest* _request = (FBRequest*)object;
        FBRequestState requestState = [_request state];
        if (requestState == kFBRequestStateComplete) {
            if ([_request sessionDidExpire]) {
                [self invalidateSession];
				[self _applyCoreHandlers:sessionInvalidHandlers];
            }
            [_request removeObserver:self forKeyPath:requestFinishedKeyPath];
            [_requests removeObject:_request];
        }
    }
}

/**
 * A private function for getting the app's base url.
 */
- (NSString *)getOwnBaseUrl {
    return [NSString stringWithFormat:@"fb%@%@://authorize",
            _appId,
            _urlSchemeSuffix ? _urlSchemeSuffix : @""];
}

/**
 * A private function for opening the authorization dialog.
 */
- (void)authorizeWithFBAppAuth:(BOOL)tryFBAppAuth
                    safariAuth:(BOOL)trySafariAuth 
				   permissions:(NSArray*)permissions {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   _appId, @"client_id",
                                   @"user_agent", @"type",
                                   kRedirectURL, @"redirect_uri",
                                   @"touch", @"display",
                                   kSDK, @"sdk",
                                   nil];
    
    NSString *loginDialogURL = [kDialogBaseURL stringByAppendingString:kLogin];
    
    if (permissions != nil) {
        NSString* scope = [permissions componentsJoinedByString:@","];
        [params setValue:scope forKey:@"scope"];
		self.lastRequestedPermissions = permissions;
    }
    
    if (_urlSchemeSuffix) {
        [params setValue:_urlSchemeSuffix forKey:@"local_client_id"];
    }
    
    // If the device is running a version of iOS that supports multitasking,
    // try to obtain the access token from the Facebook app installed
    // on the device.
    // If the Facebook app isn't installed or it doesn't support
    // the fbauth:// URL scheme, fall back on Safari for obtaining the access token.
    // This minimizes the chance that the user will have to enter his or
    // her credentials in order to authorize the application.
    BOOL didOpenOtherApp = NO;
    UIDevice *device = [UIDevice currentDevice];
    if ([device respondsToSelector:@selector(isMultitaskingSupported)] && [device isMultitaskingSupported]) {
        if (tryFBAppAuth) {
            NSString *scheme = kFBAppAuthURLScheme;
            if (_urlSchemeSuffix) {
                scheme = [scheme stringByAppendingString:@"2"];
            }
            NSString *urlPrefix = [NSString stringWithFormat:@"%@://%@", scheme, kFBAppAuthURLPath];
            NSString *fbAppUrl = [FBRequest serializeURL:urlPrefix params:params];
            didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }
        
        if (trySafariAuth && !didOpenOtherApp) {
            NSString *nextUrl = [self getOwnBaseUrl];
            [params setValue:nextUrl forKey:@"redirect_uri"];
            
            NSString *fbAppUrl = [FBRequest serializeURL:loginDialogURL params:params];
            didOpenOtherApp = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:fbAppUrl]];
        }
    }
    
    // If single sign-on failed, open an inline login dialog. This will require the user to
    // enter his or her credentials.
    if (!didOpenOtherApp) {
        _loginDialog = [[FBLoginDialog alloc] initWithURL:loginDialogURL
                                              loginParams:params
                                                 delegate:self];
        [_loginDialog show];
    }
}

/**
 * A function for parsing URL parameters.
 */

- (NSDictionary*)parseURLParams:(NSString *)query 
{
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
		[[kv objectAtIndex:1]
		 stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
	return params;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
//public

/**
 * Starts a dialog which prompts the user to log in to Facebook and grant
 * the requested permissions to the application.
 *
 * If the device supports multitasking, we use fast app switching to show
 * the dialog in the Facebook app or, if the Facebook app isn't installed,
 * in Safari (this enables single sign-on by allowing multiple apps on
 * the device to share the same user session).
 * When the user grants or denies the permissions, the app that
 * showed the dialog (the Facebook app or Safari) redirects back to
 * the calling application, passing in the URL the access token
 * and/or any other parameters the Facebook backend includes in
 * the result (such as an error code if an error occurs).
 *
 * See http://developers.facebook.com/docs/authentication/ for more details.
 *
 * Also note that requests may be made to the API without calling
 * authorize() first, in which case only public information is returned.
 *
 * @param permissions
 *            A list of permission required for this application: e.g.
 *            "read_stream", "publish_stream", or "offline_access". see
 *            http://developers.facebook.com/docs/authentication/permissions
 *            This parameter should not be null -- if you do not require any
 *            permissions, then pass in an empty String array.
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the user has logged in.
 */


- (void)authorize:(NSArray *)permissions 
		  granted:(void(^)(Facebook *))_grantedHandler 
		   denied:(void(^)(Facebook*))_deniedHandler {
	
	void (^grantedHandler)(Facebook*) = [_grantedHandler copy];
	void (^deniedHandler)(Facebook*) = [_deniedHandler copy];
	id danglingPointerHolder = nil;
	
	void (^temporaryLoginHandler)(Facebook*,FacebookLoginState) = ^(Facebook *facebook, FacebookLoginState state) {
		if( state == FacebookLoginSuccess && grantedHandler ) {
			NSMutableSet *new_permissions = [NSMutableSet setWithSet:_permissions];
			[new_permissions addObjectsFromArray:permissions];
			_permissions = new_permissions;
			
			NSLog(@"Permissions: %@", _permissions);
			
			grantedHandler(facebook);
		}
		else if( deniedHandler ) {
			deniedHandler(facebook);
		}
	
		[loginHandlers removeObject:danglingPointerHolder];
	};
	
	[loginHandlers addObject:(danglingPointerHolder = [temporaryLoginHandler copy])];
	
	[self authorizeWithFBAppAuth:YES safariAuth:YES permissions:permissions];
}

- (void)authorize:(NSArray *)permissions {
	[self authorize:permissions 
			granted:^(Facebook *facebook) {}
			 denied:^(Facebook *facebook) {}];
}

- (void)usingPermissions:(NSArray*)permissions
				 request:(void(^)())_request
{
	
	BOOL mustAuthorise = NO;
	
	for( NSString *permission in permissions ) {
		if( ![_permissions containsObject:permission] ) {
			mustAuthorise = YES;
			break;
		}
	}
	
	if( mustAuthorise ) {
		void (^request)() = [_request copy];
		
		[[Facebook shared] authorize:permissions
							 granted:^(Facebook *facebook) {
								 request();
							 }
							  denied:nil];
	}
	else {
		_request();
	}
}

- (void)usingPermission:(NSString*)permission
				request:(void(^)())_request {	
	[self usingPermissions:[NSArray arrayWithObject:permission] request:_request];
}

/**
 * Attempt to extend the access token.
 *
 * Access tokens typically expire within 30-60 days. When the user uses the
 * app, the app should periodically try to obtain a new access token. Once an
 * access token has expired, the app can no longer renew it. The app then has
 * to ask the user to re-authorize it to obtain a new access token.
 *
 * To ensure your app always has a fresh access token for active users, it's
 * recommended that you call extendAccessTokenIfNeeded in your application's
 * applicationDidBecomeActive: UIApplicationDelegate method.
 */
- (void)extendAccessToken {
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"auth.extendSSOAccessToken", @"method",
                                   nil];
	
	_isExtendingAccessToken = YES;
	[self requestWithParameters:params
					   finalize:^(FBRequest *request) {
						   [request addCompletionHandler:^(FBRequest *request, id result) {
							   NSString* accessToken = [result objectForKey:@"access_token"];
							   NSString* expTime = [result objectForKey:@"expires_at"];
							   
							   if (accessToken == nil || expTime == nil) {
								   return;
							   }
							   
							   self.accessToken = accessToken;
							   
							   NSTimeInterval timeInterval = [expTime doubleValue];
							   NSDate *expirationDate = [NSDate distantFuture];
							   if (timeInterval != 0) {
								   expirationDate = [NSDate dateWithTimeIntervalSince1970:timeInterval];
							   }
							   self.expirationDate = expirationDate;
							   _lastAccessTokenUpdate = [NSDate date];
							   
							   [self storeAccessToken];
							   
							   [extendedTokenHandlers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
								   void (^handler)(Facebook*,NSString*,NSDate*) = (void(^)(Facebook*,NSString*,NSDate*))obj;
								   handler(self, accessToken, expirationDate);
							   }];
							   
							   _isExtendingAccessToken = NO;
						   }];
					   }];
}

/**
 * Calls extendAccessToken if shouldExtendAccessToken returns YES.
 */
- (void)extendAccessTokenIfNeeded {
    if ([self shouldExtendAccessToken]) {
        [self extendAccessToken];
    }
}

/**
 * Returns YES if the last time a new token was obtained was over 24 hours ago.
 */
- (BOOL)shouldExtendAccessToken {
    if ([self isSessionValid] && !_isExtendingAccessToken){
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *components = [calendar components:NSHourCalendarUnit
                                                   fromDate:_lastAccessTokenUpdate
                                                     toDate:[NSDate date]
                                                    options:0];
        
        if (components.hour >= kTokenExtendThreshold) {
            return YES;
        }
    }
    return NO;
}

/**
 * This function processes the URL the Facebook application or Safari used to
 * open your application during a single sign-on flow.
 *
 * You MUST call this function in your UIApplicationDelegate's handleOpenURL
 * method (see
 * http://developer.apple.com/library/ios/#documentation/uikit/reference/UIApplicationDelegate_Protocol/Reference/Reference.html
 * for more info).
 *
 * This will ensure that the authorization process will proceed smoothly once the
 * Facebook application or Safari redirects back to your application.
 *
 * @param URL the URL that was passed to the application delegate's handleOpenURL method.
 *
 * @return YES if the URL starts with 'fb[app_id]://authorize and hence was handled
 *   by SDK, NO otherwise.
 */
- (BOOL)handleOpenURL:(NSURL *)url {
    // If the URL's structure doesn't match the structure used for Facebook authorization, abort.
    if (![[url absoluteString] hasPrefix:[self getOwnBaseUrl]]) {
        return NO;
    }
    
    NSString *query = [url fragment];
    
    // Version 3.2.3 of the Facebook app encodes the parameters in the query but
    // version 3.3 and above encode the parameters in the fragment. To support
    // both versions of the Facebook app, we try to parse the query if
    // the fragment is missing.
    if (!query) {
        query = [url query];
    }
    
    NSDictionary *params = [self parseURLParams:query];
    NSString *accessToken = [params objectForKey:@"access_token"];
    
    // If the URL doesn't contain the access token, an error has occurred.
    if (!accessToken) {
        NSString *errorReason = [params objectForKey:@"error"];
        
        // If the error response indicates that we should try again using Safari, open
        // the authorization dialog in Safari.
        if (errorReason && [errorReason isEqualToString:@"service_disabled_use_browser"]) {
            [self authorizeWithFBAppAuth:NO safariAuth:YES permissions:self.lastRequestedPermissions];
            return YES;
        }
        
        // If the error response indicates that we should try the authorization flow
        // in an inline dialog, do that.
        if (errorReason && [errorReason isEqualToString:@"service_disabled"]) {
            [self authorizeWithFBAppAuth:NO safariAuth:NO permissions:self.lastRequestedPermissions];
            return YES;
        }
        
        // The facebook app may return an error_code parameter in case it
        // encounters a UIWebViewDelegate error. This should not be treated
        // as a cancel.
        NSString *errorCode = [params objectForKey:@"error_code"];
        
        BOOL userDidCancel = !errorCode && (!errorReason || [errorReason isEqualToString:@"access_denied"]);
        [self facebookbDialogDidNotLogin:userDidCancel];
        return YES;
    }
    
    // We have an access token, so parse the expiration date.
    NSString *expTime = [params objectForKey:@"expires_in"];
    NSDate *expirationDate = [NSDate distantFuture];
    if (expTime != nil) {
        int expVal = [expTime intValue];
        if (expVal != 0) {
            expirationDate = [NSDate dateWithTimeIntervalSinceNow:expVal];
        }
    }
    
    [self facebookDialogDidLogin:accessToken expirationDate:expirationDate];
    return YES;
}

/**
 * Invalidate the current user session by removing the access token in
 * memory and clearing the browser cookie.
 *
 * Note that this method dosen't unauthorize the application --
 * it just removes the access token. To unauthorize the application,
 * the user must remove the app in the app settings page under the privacy
 * settings screen on facebook.com.
 */
- (void)logout {
    [self invalidateSession];
	[self _applyCoreHandlers:logoutHandlers];
}

#pragma mark - Requests

/**
 * Make a request to Facebook's REST API with the given
 * parameters. One of the parameter keys must be "method" and its value
 * should be a valid REST server API method.
 *
 * See http://developers.facebook.com/docs/reference/rest/
 *
 * @param parameters
 *            Key-value pairs of parameters to the request. Refer to the
 *            documentation: one of the parameters must be "method".
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithParameters:(NSDictionary *)_params
						   finalize:(void(^)(FBRequest*))finalize {
	NSMutableDictionary *params = (_params ? [NSMutableDictionary dictionaryWithDictionary:_params] : [NSMutableDictionary dictionary]);
	
    if ([params objectForKey:@"method"] == nil) {
        NSLog(@"API Method must be specified");
        return nil;
    }
    
    NSString * methodName = [params objectForKey:@"method"];
    [params removeObjectForKey:@"method"];
    
    return [self requestWithMethodName:methodName
							parameters:params
                         requestMethod:@"GET"
							  finalize:finalize];
}

/**
 * Make a request to Facebook's REST API with the given method name and
 * parameters.
 *
 * See http://developers.facebook.com/docs/reference/rest/
 *
 *
 * @param methodName
 *             a valid REST server API method.
 * @param parameters
 *            Key-value pairs of parameters to the request. Refer to the
 *            documentation: one of the parameters must be "method". To upload
 *            a file, you should specify the httpMethod to be "POST" and the
 *            “params” you passed in should contain a value of the type
 *            (UIImage *) or (NSData *) which contains the content that you
 *            want to upload
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithMethodName:(NSString *)methodName
						 parameters:(NSDictionary *)params
                      requestMethod:(NSString *)httpMethod
						   finalize:(void(^)(FBRequest*))finalize {
    NSString * fullURL = [kRestserverBaseURL stringByAppendingString:methodName];
    return [self openUrl:fullURL
                  params:params
		   requestMethod:httpMethod
                finalize:finalize];
}

- (FBRequest*)requestWithMethodName:(NSString *)methodName 
						 parameters:(NSDictionary *)params 
						 completion:(void (^)(FBRequest*,id))completion {
	return [self requestWithMethodName:methodName
							parameters:params
							completion:completion
								 error:^(FBRequest *request, NSError *error) {
									 NSLog(@"Error %@: message: %@", request, [[error userInfo] objectForKey:@"error_msg"]);
									 NSLog(@"Errpr %@: code: %d", request, [error code]);
									 NSLog(@"Error %@: complete error: %@", request, error);								
								 }];
}
- (FBRequest*)requestWithMethodName:(NSString *)methodName 
						 parameters:(NSDictionary *)params 
						 completion:(void (^)(FBRequest*,id))completion 
							  error:(void (^)(FBRequest*,NSError *))error {

	return [self requestWithMethodName:methodName
							parameters:params
						 requestMethod:@"GET"
							  finalize:^(FBRequest *request) {
								  if( completion ) {
									  [request addCompletionHandler:completion];
								  }
								  if( error ) {
									  [request addErrorHandler:error];
								  }
							  }]; 
}
/**
 * Make a request to the Facebook Graph API without any parameters.
 *
 * See http://developers.facebook.com/docs/api
 *
 * @param graphPath
 *            Path to resource in the Facebook graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://graph.facebook.com/me
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						  finalize:(void(^)(FBRequest*))finalize {
    
    return [self requestWithGraphPath:graphPath
						   parameters:[NSMutableDictionary dictionary]
                        requestMethod:@"GET"
							 finalize:finalize];
}

/**
 * Make a request to the Facebook Graph API with the given string
 * parameters using an HTTP GET (default method).
 *
 * See http://developers.facebook.com/docs/api
 *
 *
 * @param graphPath
 *            Path to resource in the Facebook graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://graph.facebook.com/me
 * @param parameters
 *            key-value string parameters, e.g. the path "search" with
 *            parameters "q" : "facebook" would produce a query for the
 *            following graph resource:
 *            https://graph.facebook.com/search?q=facebook
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSDictionary *)params
						  finalize:(void(^)(FBRequest*))finalize {
    
    return [self requestWithGraphPath:graphPath
						   parameters:params
                        requestMethod:@"GET"
							 finalize:finalize];
}

/**
 * Make a request to the Facebook Graph API with the given
 * HTTP method and string parameters. Note that binary data parameters
 * (e.g. pictures) are not yet supported by this helper function.
 *
 * See http://developers.facebook.com/docs/api
 *
 *
 * @param graphPath
 *            Path to resource in the Facebook graph, e.g., to fetch data
 *            about the currently logged authenticated user, provide "me",
 *            which will fetch http://graph.facebook.com/me
 * @param parameters
 *            key-value string parameters, e.g. the path "search" with
 *            parameters {"q" : "facebook"} would produce a query for the
 *            following graph resource:
 *            https://graph.facebook.com/search?q=facebook
 *            To upload a file, you should specify the httpMethod to be
 *            "POST" and the “params” you passed in should contain a value
 *            of the type (UIImage *) or (NSData *) which contains the
 *            content that you want to upload
 * @param httpMethod
 *            http verb, e.g. "GET", "POST", "DELETE"
 * @param delegate
 *            Callback interface for notifying the calling application when
 *            the request has received response
 * @return FBRequest*
 *            Returns a pointer to the FBRequest object.
 */
- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSDictionary *)params
                     requestMethod:(NSString *)httpMethod
						  finalize:(void(^)(FBRequest*))finalize {
    
    NSString * fullURL = [kGraphBaseURL stringByAppendingString:graphPath];
    return [self openUrl:fullURL
                  params:params
		   requestMethod:httpMethod
                finalize:finalize];
}

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSDictionary *)params
						completion:(void (^)(FBRequest*,id))completion {
	
	return [self requestWithGraphPath:graphPath
						   parameters:params
						   completion:completion
								error:^(FBRequest *request, NSError *error) {
									NSLog(@"Error %@: message: %@", request, [[error userInfo] objectForKey:@"error_msg"]);
									NSLog(@"Errpr %@: code: %d", request, [error code]);
									NSLog(@"Error %@: complete error: %@", request, error);								
								}];
}

- (FBRequest*)requestWithGraphPath:(NSString *)graphPath
						parameters:(NSMutableDictionary *)params
						completion:(void (^)(FBRequest*,id))completion 
							 error:(void (^)(FBRequest*,NSError *))error {
	return [self requestWithGraphPath:graphPath
						   parameters:params
						requestMethod:@"GET"
							 finalize:^(FBRequest *request) {
								 if( completion ) {
									 [request addCompletionHandler:completion];
								 }
								 if( error ) {
									 [request addErrorHandler:error];
								 }
							 }];
}

#pragma mark - Dialog handlers

/**
 * Generate a UI dialog for the request action.
 *
 * @param action
 *            String representation of the desired method: e.g. "login",
 *            "feed", ...
 * @param delegate
 *            Callback interface to notify the calling application when the
 *            dialog has completed.
 */
- (void)dialog:(NSString *)action
	  delegate:(id<FBDialogDelegate>)delegate {
    NSMutableDictionary * params = [NSMutableDictionary dictionary];
    [self dialog:action parameters:params delegate:delegate];
}

/**
 * Generate a UI dialog for the request action with the provided parameters.
 *
 * @param action
 *            String representation of the desired method: e.g. "login",
 *            "feed", ...
 * @param parameters
 *            key-value string parameters
 * @param delegate
 *            Callback interface to notify the calling application when the
 *            dialog has completed.
 */
- (void)dialog:(NSString *)action
	parameters:(NSDictionary *)_params
	  delegate:(id <FBDialogDelegate>)delegate {
	NSMutableDictionary *params = (_params ? [NSMutableDictionary dictionaryWithDictionary:_params] : [NSMutableDictionary dictionary]);

    NSString *dialogURL = [kDialogBaseURL stringByAppendingString:action];
    [params setObject:@"touch" forKey:@"display"];
    [params setObject:kSDKVersion forKey:@"sdk"];
    [params setObject:kRedirectURL forKey:@"redirect_uri"];
    
    if ([action isEqualToString:kLogin]) {
        [params setObject:@"user_agent" forKey:@"type"];
        _fbDialog = [[FBLoginDialog alloc] initWithURL:dialogURL loginParams:params delegate:self];
    } else {
        [params setObject:_appId forKey:@"app_id"];
        if ([self isSessionValid]) {
            [params setValue:[self.accessToken stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                      forKey:@"access_token"];
            [self extendAccessTokenIfNeeded];
        }
        
        // by default we show dialogs, frictionless cases may have a hidden view
        BOOL invisible = NO;
        
        // frictionless handling for application requests
        if ([action isEqualToString:kApprequests]) {        
            // if frictionless requests are enabled
            if (self.isFrictionlessRequestsEnabled) {
                //  1. show the "Don't show this again for these friends" checkbox
                //  2. if the developer is sending a targeted request, then skip the loading screen
                [params setValue:@"1" forKey:@"frictionless"];	
                //  3. request the frictionless recipient list encoded in the success url
                [params setValue:@"1" forKey:@"get_frictionless_recipients"];
            }
			
            // set invisible if all recipients are enabled for frictionless requests
            id fbid = [params objectForKey:@"to"];
            if (fbid != nil) {
                // if value parses as a json array expression get the list that way
				NSError *error = nil;
				
				id fbids = [NSJSONSerialization JSONObjectWithData:[fbid dataUsingEncoding:NSUTF8StringEncoding]
														   options:NSJSONReadingAllowFragments
															 error:&error];
				
				if( error ) {
					NSLog(@"%s: %d: Unable to decode JSON: %@", __FILE__, __LINE__, fbid);
					fbids = [NSArray array];
				}
				
                if (![fbids isKindOfClass:[NSArray class]]) {
                    // otherwise seperate by commas (handles the singleton case too)
                    fbids = [fbid componentsSeparatedByString:@","];
                }                
                invisible = [self isFrictionlessEnabledForRecipients:fbids];             
            }
        }
        
        _fbDialog = [[FBDialog alloc] initWithURL:dialogURL
									   parameters:params
                                  isViewInvisible:invisible
                             frictionlessSettings:_frictionlessRequestSettings 
                                         delegate:delegate];
    }
    
    [_fbDialog show];
}

/**
 * @return boolean - whether this object has an non-expired session token
 */
- (BOOL)isSessionValid {
    return (self.accessToken != nil && self.expirationDate != nil
            && NSOrderedDescending == [self.expirationDate compare:[NSDate date]]);
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////
//FBLoginDialogDelegate

/**
 * Set the authToken and expirationDate after login succeed
 */
- (void)_applyLoginHandlers:(FacebookLoginState)state {
	[[loginHandlers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		void (^handler)(Facebook*,FacebookLoginState) = (void(^)(Facebook*,FacebookLoginState))obj;
		handler(self, state);
	}];
}
- (void)facebookDialogDidLogin:(NSString *)token expirationDate:(NSDate *)expirationDate {
    self.accessToken = token;
    self.expirationDate = expirationDate;
    _lastAccessTokenUpdate = [NSDate date];
	
    [self reloadFrictionlessRecipientCache];
	
	[self storeAccessToken];
	
	[self fetchActiveUserPermissions];
	
	[self _applyLoginHandlers:FacebookLoginSuccess];
}

/**
 * Did not login call the not login delegate
 */
- (void)facebookbDialogDidNotLogin:(BOOL)cancelled {
	[self _applyLoginHandlers:(cancelled ? FacebookLoginCancelled : FacebookLoginFailed)];
}

#pragma mark - Friction


- (BOOL)isFrictionlessRequestsEnabled {
    return _frictionlessRequestSettings.enabled;
}

- (void)enableFrictionlessRequests {
    [_frictionlessRequestSettings enableWithFacebook:self];
}

- (void)reloadFrictionlessRecipientCache {
    [_frictionlessRequestSettings reloadRecipientCacheWithFacebook:self];
}

- (BOOL)isFrictionlessEnabledForRecipient:(NSString*)fbid {
    return [_frictionlessRequestSettings isFrictionlessEnabledForRecipient:fbid];
}

- (BOOL)isFrictionlessEnabledForRecipients:(NSArray*)fbids {
    return [_frictionlessRequestSettings isFrictionlessEnabledForRecipients:fbids];
}


#pragma mark - Handlers

- (void)addLoginHandler:(void(^)(Facebook*, FacebookLoginState))handler {
	[loginHandlers addObject:[handler copy]];
}
- (void)addExtendTokenHandler:(void(^)(Facebook *facebook, NSString *token, NSDate *expiresAt))handler {
	[extendedTokenHandlers addObject:[handler copy]];
}
- (void)addLogoutHandler:(void(^)(Facebook*))handler {
	[logoutHandlers addObject:[handler copy]];
}
- (void)addSessionInvalidatedHandler:(void(^)(Facebook*))handler {
	[sessionInvalidHandlers addObject:[handler copy]];
}

@end

#pragma mark - FacebookURLProtocol

/* This protocol handles the URLs in the plist for the application.

 When the application delegate is called with a URL, it should create a 
 request and a connection; This will then call to this protocol to handle
 the URL. This is described in the URL Loading System Programming Guide at 
 https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/URLLoadingSystem/Concepts/URLOverview.html#//apple_ref/doc/uid/20001834-155857
 
 This has the benefit of allowing multiple libraries to have the chance to
 handle the URL called to the app.
*/

@interface FacebookURLProtocol : NSURLProtocol
@end

@implementation FacebookURLProtocol

+ (void)load {
	[self registerClass:[FacebookURLProtocol class]];
}
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	if ([[request.URL scheme] hasPrefix:@"fb"])
		return YES;
	
	return NO;
}
- (void)startLoading {
	[[Facebook shared] handleOpenURL:self.request.URL];
}
- (void)stopLoading {}
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

@end
