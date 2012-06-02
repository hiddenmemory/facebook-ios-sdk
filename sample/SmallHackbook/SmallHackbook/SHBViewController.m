//
//  SHBViewController.m
//  SmallHackbook
//
//  Created by Chris Ross on 02/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "SHBViewController.h"
#import "FBConnect.h"

@interface SHBViewController ()

@end

@implementation SHBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (IBAction)go:(id)sender {
	[[Facebook shared] fetchAlbums:^(NSArray *albums) {
		NSLog(@"Albums: %@", albums);
	} error:nil];
}

@end
