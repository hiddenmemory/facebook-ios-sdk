//
//  FBLoginDialog+Delegate.h
//  Hackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "FBLoginDialog.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@protocol FBLoginDialogDelegate <NSObject>

- (void)kFBDialogDidLogin:(NSString*)token expirationDate:(NSDate*)expirationDate;

- (void)facebookbDialogDidNotLogin:(BOOL)cancelled;

@end

@interface FBLoginDialog (Delegate)
@property(nonatomic,weak) id<FBLoginDialogDelegate> delegate;
@end
