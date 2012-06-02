//
//  SHBViewController.h
//  SmallHackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHBViewController : UIViewController
@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)postStatus:(id)sender;
- (IBAction)albumList:(id)sender;

@end
