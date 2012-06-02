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

#import "FBRequest+Delegate.h"
#import <objc/runtime.h>

@implementation FBRequest (Delegate)

- (void)setDelegate:(id<FBRequestDelegate>)delegate 
{
	__block FBRequest *weakSelf = self;
	
	id oldDelegate = objc_getAssociatedObject(self, _cmd);
	objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_ASSIGN);
	
	if (oldDelegate) return;
	
	if( [weakSelf.delegate respondsToSelector:@selector(request:didLoad:)] ) {
		[self addCompletionHandler:^(FBRequest *request,id object) {
			[weakSelf.delegate request:request didLoad:object];
		}];
	}
	
	if( [weakSelf.delegate respondsToSelector:@selector(request:didFailWithError:)] ) {
		[self addErrorHandler:^(FBRequest *request, NSError *error) {
			[weakSelf.delegate request:weakSelf didFailWithError:error];
		}];
	}
	
	if( [weakSelf.delegate respondsToSelector:@selector(request:didLoadRawResponse:)] ) {
		[self addRawHandler:^(FBRequest *request, NSData *data) {
			[weakSelf.delegate request:weakSelf didLoadRawResponse:data];
		}];
	}
	
	if( [weakSelf.delegate respondsToSelector:@selector(request:didReceiveResponse:)] ) {
		[self addResponseHandler:^(FBRequest *request, NSURLResponse *response) {
			[weakSelf.delegate request:weakSelf didReceiveResponse:response];
		}];
	}
	
	if( [weakSelf.delegate respondsToSelector:@selector(requestLoading:)] ) {
		[self addLoadHandler:^(FBRequest *request) {
			[weakSelf.delegate requestLoading:weakSelf];
		}];
	}
}

- (id<FBRequestDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(setDelegate:));
}

@end
