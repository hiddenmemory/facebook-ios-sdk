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
	
	[self addLoginHandler:^( NSString *token, NSDate *expirationDate ) {
		[((FBLoginDialog*)weakSelf).delegate facebookDialogDidLogin:token expirationDate:expirationDate];
	}];
	[self addDidNotLoginHandler:^( BOOL cancelled ) {
		[((FBLoginDialog*)weakSelf).delegate facebookbDialogDidNotLogin:cancelled];
	}];
}

- (id<FBLoginDialogDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(setDelegate:));
}

@end
