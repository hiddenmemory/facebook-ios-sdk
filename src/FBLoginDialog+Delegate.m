//
//  FBLoginDialog+Delegate.m
//  Hackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "FBLoginDialog+Delegate.h"
#import <objc/runtime.h>

@implementation FBLoginDialog (Delegate)

- (void)setDelegate:(id<FBLoginDialogDelegate>)delegate {
	__block FBDialog *weakSelf = self;
	
	id oldDelegate = objc_getAssociatedObject(self, _cmd);
	objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_ASSIGN);
	
	if (oldDelegate) return;
	
	[self addLoginHandler:^( FBDialogState state, NSString *token, NSDate *expirationDate ) {
		switch (state) {
			case kFBDialogSuccess:
				[((FBLoginDialog*)weakSelf).delegate kFBDialogDidLogin:token expirationDate:expirationDate];
				break;
				
			default:
				[((FBLoginDialog*)weakSelf).delegate facebookbDialogDidNotLogin:(state == kFBDialogCancelled)];
				break;
		}
	}];
}

- (id<FBLoginDialogDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(setDelegate:));
}

@end
