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

@protocol FBRequestDelegate;

enum 
{
    kFBRequestStateReady,
    kFBRequestStateLoading,
    kFBRequestStateComplete,
    kFBRequestStateError
};
typedef NSUInteger FBRequestState;

#define kFBCompletionBlockHandlerKey @"completion"
#define kFBErrorBlockHandlerKey @"error"
#define kFBLoadBlockHandlerKey @"load"
#define kFBRawBlockHandlerKey @"raw"
#define kFBResponseBlockHandlerKey @"response"
#define kFBStateChangeBlockHandlerKey @"state"

/**
 * Do not use this interface directly, instead, use method in Facebook.h
 */
@interface FBRequest : FBBlockHandler 

/**
 * The URL which will be contacted to execute the request.
 */
@property(nonatomic,copy) NSString* url;

/**
 * The API method which will be called.
 */
@property(nonatomic,copy) NSString* httpMethod;

/**
 * The dictionary of parameters to pass to the method.
 *
 * These values in the dictionary will be converted to strings using the
 * standard Objective-C object-to-string conversion facilities.
 */
@property(weak, nonatomic) NSMutableDictionary* params;
@property(nonatomic) NSURLConnection*  connection;
@property(nonatomic) NSMutableData* responseText;
@property(nonatomic,readonly) FBRequestState state;
@property(nonatomic,readonly) BOOL sessionDidExpire;

/**
 * Error returned by the server in case of request's failure (or nil otherwise).
 */
@property(weak, nonatomic) NSError* error;

+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params;

+ (NSString*)serializeURL:(NSString *)baseUrl
                   params:(NSDictionary *)params
			requestMethod:(NSString *)httpMethod;

+ (FBRequest*)getRequestWithParameters:(NSMutableDictionary *) params
						 requestMethod:(NSString *) httpMethod
							requestURL:(NSString *) url;

- (BOOL) loading;
- (void) connect;

- (void)addCompletionHandler:(void(^)(FBRequest*request,id result))completionHandler;
- (void)addErrorHandler:(void(^)(FBRequest*request,NSError *error))errorHandler;
- (void)addLoadHandler:(void(^)(FBRequest*request))loadHandler;
- (void)addRawHandler:(void(^)(FBRequest*request,NSData*raw))rawHandler;
- (void)addResponseHandler:(void(^)(FBRequest*request,NSURLResponse*response))responseHandler;

- (void)addDebugOutputHandlers;

@end

////////////////////////////////////////////////////////////////////////////////
