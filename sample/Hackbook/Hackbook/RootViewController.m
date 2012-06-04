/*
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "RootViewController.h"
#import "HackbookAppDelegate.h"
#import "FBConnect.h"
#import "APICallsViewController.h"

@implementation RootViewController

@synthesize permissions;
@synthesize backgroundImageView;
@synthesize menuTableView;
@synthesize mainMenuItems;
@synthesize headerView;
@synthesize nameLabel;
@synthesize profilePhotoImageView;

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)updateLoggedIn {
	[self.navigationController setNavigationBarHidden:NO animated:NO];
	
	self.backgroundImageView.hidden = YES;
	loginButton.hidden = YES;
	self.menuTableView.hidden = NO;
	
	[[Facebook shared] fetchMe:^(NSDictionary *me) {
		nameLabel.text = [me objectForKey:@"name"];
		[[Facebook shared] fetchProfilePictureWithID:[me objectForKey:@"id"]
										  completion:^(UIImage *pic) {
											  profilePhotoImageView.image = pic;
										  } error:nil];
	} error:nil];
}
- (void)updateLoggedOut {
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	
	self.menuTableView.hidden = YES;
	self.backgroundImageView.hidden = NO;
	loginButton.hidden = NO;
	
	// Clear personal info
	nameLabel.text = @"";
	// Get the profile image
	[profilePhotoImageView setImage:nil];
	
	[[self navigationController] popToRootViewControllerAnimated:YES];
}
- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[Facebook shared] addLoginHandler:^(Facebook *facebook, FBLoginState state) {
		if( state == kFBLoginSuccess ) {
			[self updateLoggedIn];
		}
		else {
			[self updateLoggedOut];
		}
	}];
	
	[[Facebook shared] addSessionInvalidatedHandler:^(Facebook *facebook) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Auth Exception"
															message:@"Your session has expired."
														   delegate:nil
												  cancelButtonTitle:@"OK"
												  otherButtonTitles:nil];
		[alertView show];
		[self updateLoggedOut];
	}];
}

#pragma mark - Facebook API Calls


/**
 * Show the authorization dialog.
 */
- (void)login {
	if( [[Facebook shared] isSessionValid] ) {
		[self updateLoggedIn];
	}
	else {
		[[Facebook shared] authorize:[NSArray arrayWithObject:@"user_about_me"]];
	}
}

/**
 * Invalidate the access token and clear the cookie.
 */
- (void)logout {
	[[Facebook shared] logout];
}

/**
 * Helper method called when a menu button is clicked
 */
- (void)menuButtonClicked:(id)sender {
    // Each menu button in the UITableViewController is initialized
    // with a tag representing the table cell row. When the button
    // is clicked the button is passed along in the sender object.
    // From this object we can then read the tag property to determine
    // which menu button was clicked.
    APICallsViewController *controller = [[APICallsViewController alloc] initWithIndex:[sender tag]];
    pendingApiCallsController = controller;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - View lifecycle
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;
    
    // Main menu items
    mainMenuItems = [[NSMutableArray alloc] initWithCapacity:1];
    HackbookAppDelegate *delegate = (HackbookAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSArray *apiInfo = [[delegate apiData] apiConfigData];
    for (NSUInteger i=0; i < [apiInfo count]; i++) {
        [mainMenuItems addObject:[[apiInfo objectAtIndex:i] objectForKey:@"title"]];
    }
    
    // Set up the view programmatically
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"Hackbook for iOS";
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
									 style:UIBarButtonItemStyleBordered
									target:nil
									action:nil];
    
    // Background Image
    backgroundImageView = [[UIImageView alloc]
                           initWithFrame:CGRectMake(0,0,
                                                    self.view.bounds.size.width,
                                                    self.view.bounds.size.height)];
    [backgroundImageView setImage:[UIImage imageNamed:@"Default.png"]];
    //[backgroundImageView setAlpha:0.25];
    [self.view addSubview:backgroundImageView];
    
    // Login Button
    loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat xLoginButtonOffset = self.view.center.x - (159/2);
    CGFloat yLoginButtonOffset = self.view.bounds.size.height - (29 + 13);
    loginButton.frame = CGRectMake(xLoginButtonOffset,yLoginButtonOffset,159,29);
    [loginButton addTarget:self
                    action:@selector(login)
          forControlEvents:UIControlEventTouchUpInside];
    [loginButton setImage:
     [UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookNormal"]
                 forState:UIControlStateNormal];
    [loginButton setImage:
     [UIImage imageNamed:@"FBConnect.bundle/images/LoginWithFacebookPressed"]
                 forState:UIControlStateHighlighted];
    [loginButton sizeToFit];
    [self.view addSubview:loginButton];
    
    // Main Menu Table
    menuTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                 style:UITableViewStylePlain];
    [menuTableView setBackgroundColor:[UIColor whiteColor]];
    menuTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    menuTableView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    menuTableView.dataSource = self;
    menuTableView.delegate = self;
    menuTableView.hidden = YES;
    //[self.view addSubview:menuTableView];
    
    // Table header
    headerView = [[UIView alloc]
                  initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 100)];
    headerView.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    headerView.backgroundColor = [UIColor whiteColor];
    CGFloat xProfilePhotoOffset = self.view.center.x - 25.0;
    profilePhotoImageView = [[UIImageView alloc]
                             initWithFrame:CGRectMake(xProfilePhotoOffset, 20, 50, 50)];
    profilePhotoImageView.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [headerView addSubview:profilePhotoImageView];
    nameLabel = [[UILabel alloc]
                 initWithFrame:CGRectMake(0, 75, self.view.bounds.size.width, 20.0)];
    nameLabel.autoresizingMask =  UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    nameLabel.textAlignment = UITextAlignmentCenter;
    nameLabel.text = @"";
    [headerView addSubview:nameLabel];
    menuTableView.tableHeaderView = headerView;
    
    [self.view addSubview:menuTableView];
    
    pendingApiCallsController = nil;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    //[self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
    
    if( [[Facebook shared] isSessionValid] ) {
        [self updateLoggedIn];
    } else {
        [self updateLoggedOut];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - UITableViewDatasource and UITableViewDelegate Methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0;
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [mainMenuItems count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    //create the button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(20, 20, (cell.contentView.frame.size.width-40), 44);
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    [button setBackgroundImage:[[UIImage imageNamed:@"MenuButton.png"]
                                stretchableImageWithLeftCapWidth:9 topCapHeight:9]
                      forState:UIControlStateNormal];
    [button setTitle:[mainMenuItems objectAtIndex:indexPath.row]
            forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(menuButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    button.tag = indexPath.row;
    [cell.contentView addSubview:button];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

@end
