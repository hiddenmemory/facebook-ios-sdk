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

#import "FBRequest.h"
#import "Facebook.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static NSString* kUserAgent = @"FacebookConnectRemix";
static NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
static const int kGeneralErrorCode = 10000;
static const int kRESTAPIAccessTokenErrorCode = 190;

static const NSTimeInterval kTimeoutInterval = 180.0;

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface FBRequest () {
}
@property (nonatomic,readwrite) FBRequestState state;
@property (nonatomic,readwrite) BOOL sessionDidExpire;
@end

@implementation FBRequest

@synthesize url = _url,
httpMethod = _httpMethod,
params = _params,
connection = _connection,
responseText = _responseText,
state = _state,
sessionDidExpire = _sessionDidExpire,
error = _error;

//////////////////////////////////////////////////////////////////////////////////////////////////
// class public

+ (FBRequest *)getRequestWithParameters:(NSMutableDictionary *) params
						  requestMethod:(NSString *) httpMethod
							 requestURL:(NSString *) url {
	
	FBRequest* request = [[FBRequest alloc] init];
	request.url = url;
	request.httpMethod = httpMethod;
	request.params = params;
	request.connection = nil;
	request.responseText = nil;
	
	return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// private

+ (NSString *)serializeURL:(NSString *)baseUrl
					params:(NSDictionary *)params {
	return [self serializeURL:baseUrl params:params requestMethod:@"GET"];
}

/**
 * Generate get URL
 */
+ (NSString*)serializeURL:(NSString *)baseUrl
				   params:(NSDictionary *)params
			requestMethod:(NSString *)httpMethod {
	
	NSURL* parsedURL = [NSURL URLWithString:baseUrl];
	NSString* queryPrefix = parsedURL.query ? @"&" : @"?";
	
	NSMutableArray* pairs = [NSMutableArray array];
	for (NSString* key in [params keyEnumerator]) {
		if (([[params objectForKey:key] isKindOfClass:[UIImage class]])
			||([[params objectForKey:key] isKindOfClass:[NSData class]])) {
			if ([httpMethod isEqualToString:@"GET"]) {
				NSLog(@"can not use GET to upload a file");
			}
			continue;
		}
		
		NSString* escaped_value = (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
																										NULL, /* allocator */
																										(__bridge CFStringRef)[params objectForKey:key],
																										NULL, /* charactersToLeaveUnescaped */
																										(CFStringRef)@"!*'();:@&=+$,/?%#[]",
																										kCFStringEncodingUTF8);
		
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
	}
	NSString* query = [pairs componentsJoinedByString:@"&"];
	
	return [NSString stringWithFormat:@"%@%@%@", baseUrl, queryPrefix, query];
}

- (void)addCompletionHandler:(void(^)(FBRequest*,id))completionHandler {
	[self registerEventHandler:kFBCompletionBlockHandlerKey handler:completionHandler];
}
- (void)addErrorHandler:(void(^)(FBRequest*,NSError *))errorHandler {
	[self registerEventHandler:kFBErrorBlockHandlerKey handler:errorHandler];
}
- (void)addLoadHandler:(void(^)(FBRequest*))loadHandler {
	[self registerEventHandler:kFBLoadBlockHandlerKey handler:loadHandler];
}
- (void)addRawHandler:(void(^)(FBRequest*,NSData*))rawHandler {
	[self registerEventHandler:kFBRawBlockHandlerKey handler:rawHandler];
}
- (void)addResponseHandler:(void(^)(FBRequest*,NSURLResponse*))responseHandler{
	[self registerEventHandler:kFBResponseBlockHandlerKey handler:responseHandler];
}

- (void)addDebugOutputHandlers {
	[self addResponseHandler:^(FBRequest *request, NSURLResponse *response) {
		NSLog(@"FBRequest: Response: %@: %@", request.url, response);
	}];
	[self addCompletionHandler:^(FBRequest *request, id result) {
		NSLog(@"FBRequest: Success: %@: %@", request.url, result);
	}];
	[self addErrorHandler:^(FBRequest *request, NSError *error) {
		NSLog(@"FBRequest: Error: %@: %@", request.url, error);
	}];
}

/**
 * Body append for POST method
 */
- (void)utfAppendBody:(NSMutableData *)body data:(NSString *)data {
	[body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
}

/**
 * Generate body for POST method
 */
- (NSMutableData *)generatePostBody {
	NSMutableData *body = [NSMutableData data];
	NSString *endLine = [NSString stringWithFormat:@"\r\n--%@\r\n", kStringBoundary];
	NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
	
	[self utfAppendBody:body data:[NSString stringWithFormat:@"--%@\r\n", kStringBoundary]];
	
	for (id key in [_params keyEnumerator]) {
		
		if (([[_params objectForKey:key] isKindOfClass:[UIImage class]])
			||([[_params objectForKey:key] isKindOfClass:[NSData class]])) {
			
			[dataDictionary setObject:[_params objectForKey:key] forKey:key];
			continue;
			
		}
		
		[self utfAppendBody:body
					   data:[NSString
							 stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
							 key]];
		[self utfAppendBody:body data:[_params objectForKey:key]];
		
		[self utfAppendBody:body data:endLine];
	}
	
	if ([dataDictionary count] > 0) {
		for (id key in dataDictionary) {
			NSObject *dataParam = [dataDictionary objectForKey:key];
			if ([dataParam isKindOfClass:[UIImage class]]) {
				NSData* imageData = UIImagePNGRepresentation((UIImage*)dataParam);
				[self utfAppendBody:body
							   data:[NSString stringWithFormat:
									 @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
				[self utfAppendBody:body
							   data:@"Content-Type: image/png\r\n\r\n"];
				[body appendData:imageData];
			} else {
				NSAssert([dataParam isKindOfClass:[NSData class]],
						 @"dataParam must be a UIImage or NSData");
				[self utfAppendBody:body
							   data:[NSString stringWithFormat:
									 @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
				[self utfAppendBody:body
							   data:@"Content-Type: content/unknown\r\n\r\n"];
				[body appendData:(NSData*)dataParam];
			}
			[self utfAppendBody:body data:endLine];
			
		}
	}
	
	return body;
}

/**
 * Formulate the NSError
 */
- (id)formError:(NSInteger)code userInfo:(NSDictionary *) errorData {
	return [NSError errorWithDomain:@"facebookErrDomain" code:code userInfo:errorData];
	
}

/**
 * parse the response data
 */
- (id)parseJsonResponse:(NSData *)data error:(NSError **)error {
	
	NSString* responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if ([responseString isEqualToString:@"true"]) {
		return [NSDictionary dictionaryWithObject:@"true" forKey:@"result"];
	} else if ([responseString isEqualToString:@"false"]) {
		if (error != nil) {
			*error = [self formError:kGeneralErrorCode
							userInfo:[NSDictionary
									  dictionaryWithObject:@"This operation can not be completed"
									  forKey:@"error_msg"]];
		}
		return nil;
	}
	
	NSError *inplaceError = nil;
	
	id result = [NSJSONSerialization JSONObjectWithData:[responseString dataUsingEncoding:NSUTF8StringEncoding]
												options:0
												  error:&inplaceError];
	
	if( inplaceError ) {
		NSLog(@"%s: %d: Unable to decode JSON: %@", __FILE__, __LINE__, responseString);
		result = nil;
	}
	
	if (result == nil) {
		return responseString;
	}
	
	if ([result isKindOfClass:[NSDictionary class]]) {
		if ([result objectForKey:@"error"] != nil) {
			if (error != nil) {
				*error = [self formError:kGeneralErrorCode
								userInfo:result];
			}
			return nil;
		}
		
		if ([result objectForKey:@"error_code"] != nil) {
			if (error != nil) {
				*error = [self formError:[[result objectForKey:@"error_code"] intValue] userInfo:result];
			}
			return nil;
		}
		
		if ([result objectForKey:@"error_msg"] != nil) {
			if (error != nil) {
				*error = [self formError:kGeneralErrorCode userInfo:result];
			}
		}
		
		if ([result objectForKey:@"error_reason"] != nil) {
			if (error != nil) {
				*error = [self formError:kGeneralErrorCode userInfo:result];
			}
		}
	}
	
	return result;
	
}

/*
 * private helper function: call the delegate function when the request
 *                          fails with error
 */

- (void)_reportError:(NSError*)error {
	[self enumerateEventHandlers:kFBErrorBlockHandlerKey block:^(id _handler) {
		void (^handler)(FBRequest*,NSError *) = _handler;
		handler(self, error);
	}];
}

- (void)failWithError:(NSError *)error {
	if ([error code] == kRESTAPIAccessTokenErrorCode) {
		self.sessionDidExpire = YES;
	}
	[self _reportError:error];
}

/*
 * private helper function: handle the response data
 */
- (void)handleResponseData:(NSData *)data {
	if( [self eventHandlerCount:kFBRawBlockHandlerKey] > 0 ) {
		[self enumerateEventHandlers:kFBRawBlockHandlerKey block:^(id _handler) {
			void (^handler)(FBRequest*,NSData *) = _handler;
			handler(self, data);
		}];
	}
	else {
		NSError* error = nil;
		id result = [self parseJsonResponse:data error:&error];
		self.error = error;  
		
		if( error ) {
			[self _reportError:error];
		}
		else {
			[self enumerateEventHandlers:kFBCompletionBlockHandlerKey block:^(id _handler) {
				void (^handler)(FBRequest*,id) = _handler;
				handler(self, result);
			}];
		}
	}
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// public

/**
 * @return boolean - whether this request is processing
 */
- (BOOL)loading {
	return !!_connection;
}

/**
 * make the Facebook request
 */
- (void)connect {
	if( [Facebook shared].requestStarted ) {
		[Facebook shared].requestStarted(self);
	}
	
	[self enumerateEventHandlers:kFBLoadBlockHandlerKey block:^(id _handler) {
		void (^handler)(FBRequest*) = _handler;
		handler(self);
	}];
	
	NSString* url = [[self class] serializeURL:_url params:_params requestMethod:_httpMethod];
	NSMutableURLRequest* request =
	[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
							cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
						timeoutInterval:kTimeoutInterval];
	
	[request setValue:kUserAgent forHTTPHeaderField:@"User-Agent"];
	[request setHTTPMethod:self.httpMethod];
	
	if ([self.httpMethod isEqualToString: @"POST"]) {
		NSString* contentType = [NSString
								 stringWithFormat:@"multipart/form-data; boundary=%@", kStringBoundary];
		[request setValue:contentType forHTTPHeaderField:@"Content-Type"];
		
		[request setHTTPBody:[self generatePostBody]];
	}
	
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	self.state = kFBRequestStateLoading;
	self.sessionDidExpire = NO;
}


/**
 * Free internal structure
 */
- (void)dealloc {
	[_connection cancel];
}

- (void)setState:(FBRequestState)_ {
	_state = _;
	
	[self enumerateEventHandlers:kFBStateChangeBlockHandlerKey block:^(id _handler) {
		void (^handler)(FBRequest *, FBRequestState) = _handler;
		handler(self, _);
	}];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// NSURLConnectionDelegate

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	_responseText = [NSMutableData data];
	
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	
	[self enumerateEventHandlers:kFBResponseBlockHandlerKey block:^(id _handler) {
		void (^handler)(FBRequest*,NSURLResponse*) = _handler;
		handler(self, httpResponse);
	}];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_responseText appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
				  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
	return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	if( [Facebook shared].requestFinished ) {
		[Facebook shared].requestFinished(self);
	}

	[self handleResponseData:_responseText];
	
	self.responseText = nil;
	self.connection = nil;
	self.state = kFBRequestStateComplete;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if( [Facebook shared].requestFinished ) {
		[Facebook shared].requestFinished(self);
	}
	
	[self failWithError:error];
	
	self.responseText = nil;
	self.connection = nil;
	self.state = kFBRequestStateComplete;
}

@end
