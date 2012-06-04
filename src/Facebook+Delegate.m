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
#import "Facebook+Delegate.h"
#import <objc/runtime.h>

@implementation Facebook (Delegate)

- (void)setDelegate:(id<FBSessionDelegate>)delegate {
	__weak Facebook *weakSelf = self;
	
	id oldDelegate = objc_getAssociatedObject(self, _cmd);
	objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_ASSIGN);
	
	if (oldDelegate) return;

	[self addLoginHandler:^(Facebook *facebook, FBLoginState state) {
		switch (state) {
			case kFBLoginSuccess:
				[weakSelf.delegate facebookDidLogin:facebook];
				break;
			case kFBLoginCancelled:
			case kFBLoginFailed:
			case kFBLoginRevoked:
				[weakSelf.delegate facebook:weakSelf didNotLogin:(state == kFBLoginCancelled)];
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
