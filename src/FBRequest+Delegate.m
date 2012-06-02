//
//  FBRequest+Delegate.m
//  Hackbook
//
//  Created by Chris Ross on 01/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

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
