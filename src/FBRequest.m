/*
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

static NSString* kUserAgent = @"FacebookConnect";
static NSString* kStringBoundary = @"3i2ndDfv2rTHiSisAbouNdArYfORhtTPEefj3q2f";
static const int kGeneralErrorCode = 10000;
static const int kRESTAPIAccessTokenErrorCode = 190;

static const NSTimeInterval kTimeoutInterval = 180.0;

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface FBRequest () {
	NSMutableArray *completionHandlers;
	NSMutableArray *errorHandlers;
	NSMutableArray *loadHandlers;
	NSMutableArray *rawHandlers;
	NSMutableArray *responseHandlers;
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
	[completionHandlers addObject:[completionHandler copy]];
}
- (void)addErrorHandler:(void(^)(FBRequest*,NSError *))errorHandler {
	[errorHandlers addObject:[errorHandler copy]];
}
- (void)addLoadHandler:(void(^)(FBRequest*))loadHandler {
	[loadHandlers addObject:[loadHandler copy]];
}
- (void)addRawHandler:(void(^)(FBRequest*,NSData*))rawHandler {
	[rawHandlers addObject:[rawHandler copy]];
}
- (void)addResponseHandler:(void(^)(FBRequest*,NSURLResponse*))responseHandler {
	[completionHandlers addObject:[responseHandler copy]];
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
							   data:[NSString stringWithString:@"Content-Type: image/png\r\n\r\n"]];
				[body appendData:imageData];
			} else {
				NSAssert([dataParam isKindOfClass:[NSData class]],
						 @"dataParam must be a UIImage or NSData");
				[self utfAppendBody:body
							   data:[NSString stringWithFormat:
									 @"Content-Disposition: form-data; filename=\"%@\"\r\n", key]];
				[self utfAppendBody:body
							   data:[NSString stringWithString:@"Content-Type: content/unknown\r\n\r\n"]];
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
	[[errorHandlers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		void (^handler)(FBRequest*,NSError *) = (void(^)(FBRequest*,NSError*))obj;
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
	[[rawHandlers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		void (^handler)(FBRequest*,NSData *) = (void(^)(FBRequest*, NSData*))obj;
		handler(self, data);
	}];
	
	NSError* error = nil;
	id result = [self parseJsonResponse:data error:&error];
	self.error = error;  
	
	if( error ) {
		[self _reportError:error];
	}
	else {
		[[completionHandlers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			void (^handler)(FBRequest*,id) = (void(^)(FBRequest*, id))obj;
			handler(self, result);
		}];
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
		[Facebook shared].requestStarted();
	}
	
	[[loadHandlers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		void (^handler)(FBRequest*) = (void(^)(FBRequest*))obj;
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

- (id)init {
	self = [super init];
	if( self ) {
		completionHandlers = [NSMutableArray array];
		errorHandlers = [NSMutableArray array];
		rawHandlers = [NSMutableArray array];
		responseHandlers = [NSMutableArray array];
		loadHandlers = [NSMutableArray array];
	}
	return self;
}

/**
 * Free internal structure
 */
- (void)dealloc {
	[_connection cancel];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// NSURLConnectionDelegate

#pragma mark - NSURLConnection Delegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	_responseText = [[NSMutableData alloc] init];
	
	NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
	
	[[responseHandlers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		void (^handler)(FBRequest*,NSURLResponse*) = (void(^)(FBRequest*,NSURLResponse*))obj;
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
		[Facebook shared].requestFinished();
	}

	[self handleResponseData:_responseText];
	
	self.responseText = nil;
	self.connection = nil;
	self.state = kFBRequestStateComplete;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	if( [Facebook shared].requestFinished ) {
		[Facebook shared].requestFinished();
	}
	
	[self failWithError:error];
	
	self.responseText = nil;
	self.connection = nil;
	self.state = kFBRequestStateComplete;
}

@end
