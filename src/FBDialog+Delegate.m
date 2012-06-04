//
//  FBDialog+Delegate.m
//  facebook-ios-sdk
//
//  Created by Kieran Gutteridge on 02/06/2012.
//  Copyright (c) 2012 Intohand Ltd. All rights reserved.
//

#import "FBDialog+Delegate.h"
#import <objc/runtime.h>

@implementation FBDialog (Delegate)

- (void)setDelegate:(id<FBDialogDelegate>)delegate {
	__block FBDialog *weakSelf = self;
	
	id oldDelegate = objc_getAssociatedObject(self, _cmd);
	objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_ASSIGN);
	
	if (oldDelegate) return;
    
 
    if( [weakSelf.delegate respondsToSelector:@selector(dialogDidComplete:)] || 
	    [weakSelf.delegate respondsToSelector:@selector(dialogWasCancelled:)]  ) 
    {
        [self addCompletionHandler:^(FBDialog *dialog, FBDialogState state) {
            switch (state) {
                case kFBDialogSuccess:
                {
                    if( [weakSelf.delegate respondsToSelector:@selector(dialogDidComplete:)] ) 
                    {
                        [weakSelf.delegate dialogDidComplete:dialog];
                    }
                }
                    break;
                case kFBDialogCancelled:
                {
                    if( [weakSelf.delegate respondsToSelector:@selector(dialogWasCancelled:)] ) 
                    {
                        [weakSelf.delegate dialogWasCancelled:dialog];
                    }
                }
                default:
                    break;
            }
        }];
    }
	
    
    if( [weakSelf.delegate respondsToSelector:@selector(dialog:didCompleteWithURL:)] || 
	    [weakSelf.delegate respondsToSelector:@selector(dialog:didNotCompleteWithURL:)] )
    {
        
        [self addCompletionURLHandler:^(FBDialog *dialog, NSURL *url, FBDialogState state) {

            switch (state) {
                case kFBDialogSuccess:
                {
                    if( [weakSelf.delegate respondsToSelector:@selector(dialog:didCompleteWithURL:)]  )
                    {
                        [weakSelf.delegate dialog:dialog didCompleteWithURL:url];
                    }
                }
                    break;
                case kFBDialogCancelled:
                case kFBDialogFailed:
                {
                    if( [weakSelf.delegate respondsToSelector:@selector(dialog:didNotCompleteWithURL:)] )
                    {
                        [weakSelf.delegate dialog:dialog didNotCompleteWithURL:url];
                    }
                }
                    break;
                default:
                    break;
            }
        }];
    }
    
    if( [weakSelf.delegate respondsToSelector:@selector(dialog:didFailWithError:)] )
    {

        [self addErrorHandler:^(FBDialog *dialog, NSError *error) {
                       [weakSelf.delegate dialog:dialog didFailWithError:error];

        }];
    }
	
	if( [weakSelf.delegate respondsToSelector:@selector(dialog:shouldOpenURLInExternalBrowser:)] ){
		self.shouldOpenURLInExternalBrowser = ^BOOL(NSURL *url) {
			return [weakSelf.delegate dialog:weakSelf shouldOpenURLInExternalBrowser:url];
		};
	}
}

- (id<FBDialogDelegate>)delegate {
	return objc_getAssociatedObject(self, @selector(setDelegate:));
}

@end
