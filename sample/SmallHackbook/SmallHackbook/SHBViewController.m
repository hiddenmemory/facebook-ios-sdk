//
//  SHBViewController.m
//  SmallHackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "SHBViewController.h"
#import "FBConnect.h"

@implementation SHBViewController
@synthesize textView;
@synthesize imageView;

- (void)viewDidLoad {
	[super viewDidLoad];
	[Facebook bind];
}
- (void)viewDidUnload {
	[self setTextView:nil];
	[self setImageView:nil];
    [super viewDidUnload];
}
- (void)_displayAlert:(NSString*)message {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SmallHackbook!"
													message:message
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void)viewDidAppear:(BOOL)animated {
	[[Facebook shared] fetchMe:^(NSDictionary *me) {
		[[Facebook shared] fetchProfilePictureWithID:[me objectForKey:@"id"]
										  completion:^(UIImage *pic) {
											  self.imageView.image = pic;
										  } error:nil];
	} error:nil];
}

- (IBAction)postStatus:(id)sender {
	[[Facebook shared] setStatus:textView.text
					  completion:^(NSString *status) {
						  [self _displayAlert:@"Your status has been updated. Your friends have been informed. Life is great."];
					  } 
						   error:^(NSError *error) {
							   [self _displayAlert:[NSString stringWithFormat:@"Unable to update your status - %@.", error]];
						   }];
}

- (IBAction)albumList:(id)sender {
	[[Facebook shared] fetchAlbums:^(NSArray *albums) {
		[albums enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSLog(@"%u: %@ (%@)", idx, [obj objectForKey:@"name"], [obj objectForKey:@"id"]);
		}];
	} error:nil];
}

@end
