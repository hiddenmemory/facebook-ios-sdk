//
//  Facebook+Delegate.m
//  Hackbook
//
//  Created by Chris Ross on 01/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "Facebook+Delegate.h"
#import <objc/runtime.h>

@implementation Facebook (Delegate)

- (void)setDelegate:(id<FBSessionDelegate>)delegate {
	__weak Facebook *weakSelf = self;
	
	id oldDelegate = objc_getAssociatedObject(self, _cmd);
	objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_ASSIGN);
	
	if (oldDelegate) return;

	[self addLoginHandler:^(Facebook *facebook, FacebookLoginState state) {
		switch (state) {
			case FacebookLoginSuccess:
				[weakSelf.delegate facebookDidLogin:facebook];
				break;
			case FacebookLoginCancelled:
			case FacebookLoginFailed:
				[weakSelf.delegate facebook:weakSelf didNotLogin:(state == FacebookLoginCancelled)];
				break;
		}
	}];
	
	[self addExtendTokenHandler:^(Facebook *facebook, NSString *token, NSDate *expiresAt) {
		[weakSelf.delegate facebook:facebook
					 didExtendToken:token
						  expiresAt:expiresAt];
	}];
	
	[self addLogoutHandler:^(Facebook *facebook) {
		[weakSelf.delegate facebookDidLogout:facebook];
	}];
	
	[self addSessionInvalidatedHandler:^(Facebook *facebook) {
		[weakSelf.delegate facebookSessionInvalidated:facebook];
	}];
}

- (id<FBSessionDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(setDelegate:));
}


@end
