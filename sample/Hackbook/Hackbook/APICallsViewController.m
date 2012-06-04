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

#import "APICallsViewController.h"
#import "HackbookAppDelegate.h"
#import "FBConnect.h"
#import "DataSet.h"
#import "APIResultsViewController.h"
#import "RootViewController.h"
#import "Facebook+Graph.h"

// For re-using table cells
#define TITLE_TAG 1001
#define DESCRIPTION_TAG 1002

@implementation APICallsViewController

@synthesize apiTableView;
@synthesize apiMenuItems;
@synthesize apiHeader;
@synthesize savedAPIResult;
@synthesize locationManager;
@synthesize mostRecentLocation;
@synthesize activityIndicator;
@synthesize messageLabel;
@synthesize messageView;

- (id)initWithIndex:(NSUInteger)index {
    self = [super init];
    if (self) {
        childIndex = index;
        savedAPIResult = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return self;
}

- (void)dealloc {
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (NSString*)stringWithObject:(id)source {
	NSError *error = nil;
	NSString *result = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:source 
																					  options:0
																						error:&error]
											 encoding:NSUTF8StringEncoding];
	if( error ) {
		NSLog(@"Error serializing object: %@", source);
		return nil;
	}
	
	return result;
}

#pragma mark - View lifecycle

- (void)loadView {
    UIView *view = [[UIView alloc] initWithFrame:[UIScreen
                                                  mainScreen].applicationFrame];
    [view setBackgroundColor:[UIColor whiteColor]];
    self.view = view;

    HackbookAppDelegate *delegate = (HackbookAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *apiData = [[[delegate apiData] apiConfigData] objectAtIndex:childIndex];
    self.navigationItem.title = [apiData objectForKey:@"title"];
    apiMenuItems = [NSArray arrayWithArray:[apiData objectForKey:@"menu"]];
    apiHeader = [apiData objectForKey:@"description"];

    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                      style:UIBarButtonItemStyleBordered
                                     target:nil
                                     action:nil];

    // Main Menu Table
    apiTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                            style:UITableViewStylePlain];
    [apiTableView setBackgroundColor:[UIColor whiteColor]];
    apiTableView.dataSource = self;
    apiTableView.delegate = self;
    apiTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:apiTableView];

    // Activity Indicator
    int xPosition = (self.view.bounds.size.width / 2.0) - 15.0;
    int yPosition = (self.view.bounds.size.height / 2.0) - 15.0;
    activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(xPosition, yPosition, 30, 30)];
    activityIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [self.view addSubview:activityIndicator];

    // Message Label for showing confirmation and status messages
    CGFloat yLabelViewOffset = self.view.bounds.size.height-self.navigationController.navigationBar.frame.size.height-30;
    messageView = [[UIView alloc]
                    initWithFrame:CGRectMake(0, yLabelViewOffset, self.view.bounds.size.width, 30)];
    messageView.backgroundColor = [UIColor lightGrayColor];

    UIView *messageInsetView = [[UIView alloc] initWithFrame:CGRectMake(1, 1, self.view.bounds.size.width-1, 28)];
    messageInsetView.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                   green:248.0/255.0
                                                    blue:228.0/255.0
                                                   alpha:1];
    messageLabel = [[UILabel alloc]
                             initWithFrame:CGRectMake(4, 1, self.view.bounds.size.width-10, 26)];
    messageLabel.text = @"";
    messageLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
    messageLabel.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                  green:248.0/255.0
                                                   blue:228.0/255.0
                                                  alpha:0.6];
    [messageInsetView addSubview:messageLabel];
    [messageView addSubview:messageInsetView];
    messageView.hidden = YES;
    [self.view addSubview:messageView];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

#pragma mark - Private Helper Methods

/*
 * This method shows the activity indicator and
 * deactivates the table to avoid user input.
 */
- (void)showActivityIndicator {
    if (![activityIndicator isAnimating]) {
        apiTableView.userInteractionEnabled = NO;
        [activityIndicator startAnimating];
    }
}

/*
 * This method hides the activity indicator
 * and enables user interaction once more.
 */
- (void)hideActivityIndicator {
    if ([activityIndicator isAnimating]) {
        [activityIndicator stopAnimating];
        apiTableView.userInteractionEnabled = YES;
    }
}

/*
 * This method is used to display API confirmation and
 * error messages to the user.
 */
- (void)showMessage:(NSString *)message {
    CGRect labelFrame = messageView.frame;
    labelFrame.origin.y = [UIScreen mainScreen].bounds.size.height - self.navigationController.navigationBar.frame.size.height - 20;
    messageView.frame = labelFrame;
    messageLabel.text = message;
    messageView.hidden = NO;

    // Use animation to show the message from the bottom then
    // hide it.
    [UIView animateWithDuration:0.5
                          delay:1.0
                        options: UIViewAnimationCurveEaseOut
                     animations:^{
                         CGRect labelFrame = messageView.frame;
                         labelFrame.origin.y -= labelFrame.size.height;
                         messageView.frame = labelFrame;
                     }
                     completion:^(BOOL finished){
                         if (finished) {
                             [UIView animateWithDuration:0.5
                                                   delay:3.0
                                                 options: UIViewAnimationCurveEaseOut
                                              animations:^{
                                                  CGRect labelFrame = messageView.frame;
                                                  labelFrame.origin.y += messageView.frame.size.height;
                                                  messageView.frame = labelFrame;
                                              }
                                              completion:^(BOOL finished){
                                                  if (finished) {
                                                      messageView.hidden = YES;
                                                      messageLabel.text = @"";
                                                  }
                                              }];
                         }
                     }];
}

/*
 * This method hides the message, only needed if view closed
 * and animation still going on.
 */
- (void)hideMessage {
    messageView.hidden = YES;
    messageLabel.text = @"";
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[Facebook shared].requestStarted = ^(FBRequest *_){ [self showActivityIndicator]; };
	[Facebook shared].requestFinished = ^(FBRequest *_){ [self hideActivityIndicator]; };
}

/*
 * This method handles any clean up needed if the view
 * is about to disappear.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
	
	[Facebook shared].requestStarted = ^(FBRequest *_){};
	[Facebook shared].requestFinished = ^(FBRequest *_){};
	
    // Hide the activitiy indicator
    [self hideActivityIndicator];
    // Hide the message.
    [self hideMessage];
}

/**
 * Helper method called when a button is clicked
 */
- (void)apiButtonClicked:(id)sender {
    // Each menu button in the UITableViewController is initialized
    // with a tag representing the table cell row. When the button
    // is clicked the button is passed along in the sender object.
    // From this object we can then read the tag property to determine
    // which menu button was clicked.
    SEL selector = NSSelectorFromString([[apiMenuItems objectAtIndex:[sender tag]] objectForKey:@"method"]);
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector];
#pragma clang diagnostic pop
    }
}

/**
 * Helper method to parse URL query parameters
 */
- (NSDictionary *)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val =
        [[kv objectAtIndex:1]
         stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}

#pragma mark - Facebook API Calls
/*
 * Graph API: Method to get the user's friends.
 */
- (void)apiGraphFriends {
	[[Facebook shared] fetchFriends:^(NSArray *friends) {
		if( [friends count] ) {
			NSMutableArray *list = [NSMutableArray array];
			
			[friends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSMutableDictionary *friend = [NSMutableDictionary dictionaryWithDictionary:obj];
				[friend setObject:[friend objectForKey:@"picture"] forKey:@"details"];
				[list addObject:friend];
			}];
			
			APIResultsViewController *controller = [[APIResultsViewController alloc] initWithTitle:@"Friends"
																							  data:list
																							action:@""];

			[self.navigationController pushViewController:controller animated:YES];
		}
		else {
			[self showMessage:NSLocalizedString(@"You have no friends.", @"")];
		}
	} error:^(NSError *error) {
		[self showMessage:NSLocalizedString(@"Unable to fetch friends list", @"")];
	}];
}

/*
 * Dialog: Authorization to grant the app check-in permissions.
 */
- (void)apiPromptCheckinPermissions {
    NSArray *checkinPermissions = [[NSArray alloc] initWithObjects:@"user_checkins", @"publish_checkins", nil];
    [[Facebook shared] authorize:checkinPermissions];
}

/*
 * --------------------------------------------------------------------------
 * Login and Permissions
 * --------------------------------------------------------------------------
 */

/*
 * iOS SDK method that handles the logout API call and flow.
 */
- (void)apiLogout {
    currentAPICall = kAPILogout;
    [[Facebook shared] logout];
}

/*
 * Graph API: App unauthorize
 */
- (void)apiGraphUserPermissionsDelete {
	[[Facebook shared] requestWithGraphPath:@"me/permissions"
								 parameters:[NSDictionary dictionary]
							  requestMethod:@"DELETE"
								   finalize:^(FBRequest *request) {
									   [request addCompletionHandler:^(FBRequest *request, id result) {
										   [[Facebook shared] logout];
									   }];
								   }];
}

/*
 * Dialog: Authorization to grant the app user_likes permission.
 */
- (void)apiPromptExtendedPermissions {
    currentAPICall = kDialogPermissionsExtended;
    NSArray *extendedPermissions = [[NSArray alloc] initWithObjects:@"user_likes", nil];
    [[Facebook shared] authorize:extendedPermissions];
}

/**
 * --------------------------------------------------------------------------
 * News Feed
 * --------------------------------------------------------------------------
 */

/*
 * Dialog: Feed for the user
 */
- (void)apiDialogFeedUser {
    // The action links to be shown with the post in the feed
    NSArray* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           @"Get Started",@"name",@"http://m.facebook.com/apps/hackbookios/",@"link", nil], nil];
    NSString *actionLinksStr = [self stringWithObject:actionLinks];
    // Dialog parameters
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"I'm using the Hackbook for iOS app", @"name",
                                   @"Hackbook for iOS.", @"caption",
                                   @"Check out Hackbook for iOS to learn how you can make your iOS apps social using Facebook Platform.", @"description",
                                   @"http://m.facebook.com/apps/hackbookios/", @"link",
                                   @"http://www.facebookmobileweb.com/hackbook/img/facebook_icon_large.png", @"picture",
                                   actionLinksStr, @"actions",
                                   nil];

	[[Facebook shared] dialog:@"feed" 
				   parameters:params 
					 finalize:^(FBDialog *dialog) {
						 [dialog addCompletionURLHandler:^(FBDialog *dialog, NSURL *url, FBDialogState state) {
							 if (![url query]) {
								 NSLog(@"User canceled dialog or there was an error");
								 return;
							 }
							 
							 NSDictionary *params = [self parseURLParams:[url query]];
							 
							 if ([params valueForKey:@"post_id"]) {
								 [self showMessage:@"Published feed successfully."];
								 NSLog(@"Feed post ID: %@", [params valueForKey:@"post_id"]);
							 }
						 }];
					 }];
}

/*
 * Helper method to first get the user's friends then
 * pick one friend and post on their wall.
 */
- (void)getFriendsCallAPIDialogFeed {
    // Call the friends API first, then set up for targeted Feed Dialog
	[[Facebook shared] requestWithGraphPath:@"me/friends"
								 parameters:[NSDictionary dictionary]
								 completion:^(FBRequest *request, id result) {
									 if ([result isKindOfClass:[NSArray class]] && ([result count] > 0)) {
										 result = [result objectAtIndex:0];
									 }
									 
									 NSArray *resultData = [result objectForKey: @"data"];
									 // Check that the user has friends
									 if ([resultData count] > 0) {
										 // Pick a random friend to post the feed to
										 int randomNumber = arc4random() % [resultData count];
										 [self apiDialogFeedFriend: 
										  [[resultData objectAtIndex: randomNumber] objectForKey: @"id"]];
									 } else {
										 [self showMessage:@"You do not have any friends to post to."];
									 }
								 }];
}

/*
 * Dialog: Feed for friend
 */
- (void)apiDialogFeedFriend:(NSString *)friendID {
    currentAPICall = kDialogFeedFriend;

    NSArray* actionLinks = [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           @"Get Started",@"name",@"http://m.facebook.com/apps/hackbookios/",@"link", nil], nil];
    NSString *actionLinksStr = [self stringWithObject:actionLinks];
    // The "to" parameter targets the post to a friend
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   friendID, @"to",
                                   @"I'm using the Hackbook for iOS app", @"name",
                                   @"Hackbook for iOS.", @"caption",
                                   @"Check out Hackbook for iOS to learn how you can make your iOS apps social using Facebook Platform.", @"description",
                                   @"http://m.facebook.com/apps/hackbookios/", @"link",
                                   @"http://www.facebookmobileweb.com/hackbook/img/facebook_icon_large.png", @"picture",
                                   actionLinksStr, @"actions",
                                   nil];

	[[Facebook shared] dialog:@"feed" 
				   parameters:params
					 finalize:^(FBDialog *dialog) {
						 [dialog addCompletionURLHandler:^(FBDialog *dialog, NSURL *url, FBDialogState state) {
							 if (![url query]) {
								 NSLog(@"User canceled dialog or there was an error");
								 return;
							 }
							 
							 NSDictionary *params = [self parseURLParams:[url query]];
							
							 // Successful posts return a post_id
							 if ([params valueForKey:@"post_id"]) {
								 [self showMessage:@"Published feed successfully."];
								 NSLog(@"Feed post ID: %@", [params valueForKey:@"post_id"]);
							 }
						 }];
					 }];
}

/*
 * --------------------------------------------------------------------------
 * Requests
 * --------------------------------------------------------------------------
 */

/*
 * Dialog: Requests - send to all.
 */
- (void)apiDialogRequestsSendToMany {
    currentAPICall = kDialogRequestsSendToMany;
    NSDictionary *gift = [NSDictionary dictionaryWithObjectsAndKeys:
                                 @"5", @"social_karma",
                                 @"1", @"badge_of_awesomeness",
                                 nil];

    NSString *giftStr = [self stringWithObject:gift];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Learn how to make your iOS apps social.",  @"message",
                                   @"Check this out", @"notification_text",
                                   giftStr, @"data",
                                   nil];

	[[Facebook shared] dialog:@"apprequests" 
				   parameters:params 
					 finalize:^(FBDialog *dialog) {
						 [dialog addCompletionURLHandler:^(FBDialog *dialog, NSURL *url, FBDialogState state) {
							 if (![url query]) {
								 NSLog(@"User canceled dialog or there was an error");
								 return;
							 }
							 
							 NSDictionary *params = [self parseURLParams:[url query]];
							 
							 NSMutableArray *requestIDs = [[NSMutableArray alloc] init];
							 for (NSString *paramKey in params) {
								 if ([paramKey hasPrefix:@"request_ids"]) {
									 [requestIDs addObject:[params objectForKey:paramKey]];
								 }
							 }
							 if ([requestIDs count] > 0) {
								 [self showMessage:@"Sent request successfully."];
								 NSLog(@"Request ID(s): %@", requestIDs);
							 } 
						 }];
					 }];
}

/*
 * API: Legacy REST for getting the friends using the app. This is a helper method
 * being used to target app requests in follow-on examples.
 */

/*
 * Dialog: Requests - send to friends not currently using the app.
 */
- (void)apiDialogRequestsSendToNonUsers:(NSArray *)selectIDs {
    NSString *selectIDsStr = [selectIDs componentsJoinedByString:@","];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Learn how to make your iOS apps social.",  @"message",
                                   @"Check this out", @"notification_text",
                                   selectIDsStr, @"suggestions",
                                   nil];

    [[Facebook shared] dialog:@"apprequests"
                      parameters:params
                    finalize:^(FBDialog *dialog) {
						[dialog addCompletionURLHandler:^(FBDialog *dialog, NSURL *url, FBDialogState state) {
							if (![url query]) {
								NSLog(@"User canceled dialog or there was an error");
								return;
							}
							
							NSDictionary *params = [self parseURLParams:[url query]];
							
							// Successful requests return one or more request_ids.
							// Get any request IDs, will be in the URL in the form
							// request_ids[0]=1001316103543&request_ids[1]=10100303657380180
							NSMutableArray *requestIDs = [[NSMutableArray alloc] init];
							for (NSString *paramKey in params) {
								if ([paramKey hasPrefix:@"request_ids"]) {
									[requestIDs addObject:[params objectForKey:paramKey]];
								}
							}
							if ([requestIDs count] > 0) {
								[self showMessage:@"Sent request successfully."];
								NSLog(@"Request ID(s): %@", requestIDs);
							}
						}];
					}];
}

/*
 * Dialog: Requests - send to select users, in this case friends
 * that are currently using the app.
 */
- (void)apiDialogRequestsSendToUsers:(NSArray *)selectIDs {
    currentAPICall = kDialogRequestsSendToSelect;
    NSString *selectIDsStr = [selectIDs componentsJoinedByString:@","];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"It's your turn to visit the Hackbook for iOS app.",  @"message",
                                   selectIDsStr, @"suggestions",
                                   nil];

    [[Facebook shared] dialog:@"apprequests"
					 parameters:params
					   finalize:^(FBDialog *dialog) {
						   [dialog addCompletionURLHandler:^(FBDialog *dialog, NSURL *url, FBDialogState state) {
							   if (![url query]) {
								   NSLog(@"User canceled dialog or there was an error");
								   return;
							   }
							   
							   NSDictionary *params = [self parseURLParams:[url query]];
							   
							   // Successful requests return one or more request_ids.
							   // Get any request IDs, will be in the URL in the form
							   // request_ids[0]=1001316103543&request_ids[1]=10100303657380180
							   NSMutableArray *requestIDs = [[NSMutableArray alloc] init];
							   for (NSString *paramKey in params) {
								   if ([paramKey hasPrefix:@"request_ids"]) {
									   [requestIDs addObject:[params objectForKey:paramKey]];
								   }
							   }
							   if ([requestIDs count] > 0) {
								   [self showMessage:@"Sent request successfully."];
								   NSLog(@"Request ID(s): %@", requestIDs);
							   }
						   }];
					   }];
}

/*
 * Dialog: Request - send to a targeted friend.
 */
- (void)apiDialogRequestsSendTarget:(NSString *)friend {
    currentAPICall = kDialogRequestsSendToTarget;
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"Learn how to make your iOS apps social.",  @"message",
                                   friend, @"to",
                                   nil];

    [[Facebook shared] dialog:@"apprequests"
					 parameters:params
					   finalize:^(FBDialog *dialog) {
						   [dialog addCompletionURLHandler:^(FBDialog *dialog, NSURL *url, FBDialogState state) {
							   if (![url query]) {
								   NSLog(@"User canceled dialog or there was an error");
								   return;
							   }
							   
							   NSDictionary *params = [self parseURLParams:[url query]];
							   
							   // Successful requests return one or more request_ids.
							   // Get any request IDs, will be in the URL in the form
							   // request_ids[0]=1001316103543&request_ids[1]=10100303657380180
							   NSMutableArray *requestIDs = [[NSMutableArray alloc] init];
							   for (NSString *paramKey in params) {
								   if ([paramKey hasPrefix:@"request_ids"]) {
									   [requestIDs addObject:[params objectForKey:paramKey]];
								   }
							   }
							   if ([requestIDs count] > 0) {
								   [self showMessage:@"Sent request successfully."];
								   NSLog(@"Request ID(s): %@", requestIDs);
							   }
						   }];
					   }];
}

/*
 * Helper method to get friends using the app which will in turn
 * send a request to NON users.
 */

- (void(^)(NSError*))errorHandler:(NSString*)message {
	return ^(NSError *error) {
		NSLog(@"Error: %@: %@", message, error);
		[self showMessage:message];
	};
}

- (void)getAppUsersFriendsNotUsing {
	[[Facebook shared] fetchFriendsWithApp:^(NSArray *friendsWithApp) {
		NSMutableSet *friendsWithAppSet = [NSMutableSet set];
		
		[friendsWithApp enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *friend = (NSDictionary*)obj;
			[friendsWithAppSet addObject:[friend objectForKey:@"id"]];
		}];
		
		
		[[Facebook shared] fetchFriends:^(NSArray *friends) {
			NSMutableArray *list = [NSMutableArray array];
			
			[friends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSDictionary *friend = (NSDictionary*)obj;
				
				if( ![friendsWithAppSet containsObject:[friend objectForKey:@"id"]] ) {
					[list addObject:[friend objectForKey:@"id"]];
				}
			}];
			
			if ([list count] > 0) {
				[self apiDialogRequestsSendToNonUsers:list];
			} else {
				[self showMessage:@"All your friends are using the app."];
			}
		} error:[self errorHandler:NSLocalizedString(@"Unable to fetch friends", @"")]];
	} error:[self errorHandler:NSLocalizedString(@"Unable to fetch friends with app", @"")]];
}

/*
 * Helper method to get friends using the app which will in turn
 * send a request to current app users.
 */
- (void)getAppUsersFriendsUsing {
	[[Facebook shared] fetchFriendsWithApp:^(NSArray *friends) {
		if( [friends count] ) {
			NSMutableArray *list = [NSMutableArray array];
			[friends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				NSDictionary *friend = (NSDictionary*)obj;
				[list addObject:[friend objectForKey:@"id"]];
			}];
			[self apiDialogRequestsSendToUsers:list];
		}
		else {
			[self showMessage:NSLocalizedString(@"None of your friends are using the app.", @"")];
		}
	} error:[self errorHandler:NSLocalizedString(@"Unable to fetch friends with app", @"")]];
}

/*
 * Helper method to get the users friends which will in turn
 * pick one to send a request.
 */
- (void)getUserFriendTargetDialogRequest {
	[[Facebook shared] fetchFriends:^(NSArray *friends) {
		if( [friends count] ) {
			int randomIndex = arc4random() % [friends count];	
			NSString* randomFriend =  [[friends objectAtIndex:randomIndex] objectForKey:@"id"];
			[self apiDialogRequestsSendTarget:randomFriend];
		}
		else {
			[self showMessage: @"You have no friends to select."];
		}
	} error:[self errorHandler:NSLocalizedString(@"Unable to fetch friends list", @"")]];
}

/*
 * API: Enable frictionless in the SDK, retrieve friends enabled for frictionless send
 */
- (void)enableFrictionlessAppRequests {
    // Enable frictionless app requests
    [[Facebook shared] enableFrictionlessRequests];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Enabled Frictionless Requests"
                              message:@"Request actions such as\n"
                                      @"Send Request and Send Invite\n"
                                      @"now support frictionless behavior."
                              delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil,
                              nil];
    [alertView show];
}

/*
 * --------------------------------------------------------------------------
 * Graph API
 * --------------------------------------------------------------------------
 */

/*
 * Graph API: Get the user's basic information, picking the name and picture fields.
 */
- (void)apiGraphMe {
	[[Facebook shared] fetchMe:^(NSDictionary *me) {
		NSString *ID = [me objectForKey:@"id"];
		NSString *name = [me objectForKey:@"name"];
		NSString *pictureURL = [me objectForKey:@"picture"];

		NSArray *list = [NSArray arrayWithObject:[NSDictionary dictionaryWithObjectsAndKeys:
												  ID, @"id",
												  [NSString stringWithFormat:@"%@ (%@)", name, ID], @"name",
												  pictureURL, @"details",
												  nil]];
		
		APIResultsViewController *controller = [[APIResultsViewController alloc] initWithTitle:@"Your Information"
																						  data:list
																						action:@""];
		[self.navigationController pushViewController:controller animated:YES];
	} error:[self errorHandler:NSLocalizedString(@"Unable to fetch your details", @"")]];
}

/*
 * Graph API: Get the user's friends
 */
- (void)getUserFriends {
    currentAPICall = kAPIGraphUserFriends;
    [self apiGraphFriends];
}

/*
 * Graph API: Get the user's check-ins
 */
- (void)apiGraphUserCheckins {
    currentAPICall = kAPIGraphUserCheckins;
	
	[[Facebook shared] usingPermissions:[NSArray arrayWithObjects:@"user_checkins", @"publish_checkins", nil] request:^(BOOL success) {
		[[Facebook shared] requestWithGraphPath:@"me/checkins"
									 parameters:nil
									 completion:^(FBRequest *request, id result) {
										 if ([result isKindOfClass:[NSArray class]] && ([result count] > 0)) {
											 result = [result objectAtIndex:0];
										 }
										 
										 NSMutableArray *places = [[NSMutableArray alloc] initWithCapacity:1];
										 NSArray *resultData = [result objectForKey:@"data"];
										 for (NSUInteger i=0; i<[resultData count] && i < 5; i++) {
											 NSString *placeID = [[[resultData objectAtIndex:i] objectForKey:@"place"] objectForKey:@"id"];
											 NSString *placeName = [[[resultData objectAtIndex:i] objectForKey:@"place"] objectForKey:@"name"];
											 NSString *checkinMessage = [[resultData objectAtIndex:i] objectForKey:@"message"] ?
											 [[resultData objectAtIndex:i] objectForKey:@"message"] : @"";
											 [places addObject:[NSDictionary dictionaryWithObjectsAndKeys:
																placeID,@"id",
																placeName,@"name",
																checkinMessage,@"details",
																nil]];
										 }
										 // Show the user's recent check-ins a new view controller
										 APIResultsViewController *controller = [[APIResultsViewController alloc]
																				 initWithTitle:@"Recent Check-ins"
																				 data:places
																				 action:@"recentcheckins"];
										 [self.navigationController pushViewController:controller animated:YES];
									 }];
	}];
}

/*
 * Helper method to check the user permissions which were stored in the app session
 * when the app was started. After the check decide on whether to prompt for user
 * check-in permissions first or get the check-in information.
 */
- (void)getPermissionsCallUserCheckins {
	[self apiGraphUserCheckins];
}

/*
 * Graph API: Search query to get nearby location.
 */
- (void)apiGraphSearchPlace:(CLLocation *)location {
    currentAPICall = kAPIGraphSearchPlace;
    NSString *centerLocation = [[NSString alloc] initWithFormat:@"%f,%f",
                                location.coordinate.latitude,
                                location.coordinate.longitude];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"place",  @"type",
                                   centerLocation, @"center",
                                   @"1000",  @"distance",
                                   nil];

	[[Facebook shared] requestWithGraphPath:@"search"
								 parameters:params
								 completion:^(FBRequest *request, id result) {
									 if ([result isKindOfClass:[NSArray class]] && ([result count] > 0)) {
										 result = [result objectAtIndex:0];
									 }
									 
									 NSMutableArray *places = [[NSMutableArray alloc] initWithCapacity:1];
									 NSArray *resultData = [result objectForKey:@"data"];
									 for (NSUInteger i=0; i<[resultData count] && i < 5; i++) {
										 [places addObject:[resultData objectAtIndex:i]];
									 }
									 // Show the places nearby in a new view controller
									 APIResultsViewController *controller = [[APIResultsViewController alloc]
																			 initWithTitle:@"Nearby"
																			 data:places
																			 action:@"places"];
									 [self.navigationController pushViewController:controller animated:YES];
								 }];
}

/*
 * Method called when user location found. Calls the search API with the most
 * recent location reading.
 */
- (void)processLocationData {
    // Stop updating location information
    [locationManager stopUpdatingLocation];
    locationManager.delegate = nil;

    // Call the API to get nearby search results
    [self apiGraphSearchPlace:mostRecentLocation];
}

/*
 * Helper method to check the user permissions which were stored in the app session
 * when the app was started. After the check decide on whether to prompt for user
 * check-in permissions first or get the user's location which will in turn search
 * for nearby places the user can then check-in to.
 */
- (void)getPermissionsCallNearby {
	[[Facebook shared] usingPermission:@"publish_checkin" request:^( BOOL success ) {
		if( success ) {
			if (![CLLocationManager locationServicesEnabled]) {
				UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
				[servicesDisabledAlert show];
			}
			// Start the location manager
			self.locationManager = [[CLLocationManager alloc] init];
			locationManager.delegate = self;
			locationManager.desiredAccuracy = kCLLocationAccuracyBest;
			[locationManager startUpdatingLocation];
			// Time out if it takes too long to get a reading.
			[self performSelector:@selector(processLocationData) withObject:nil afterDelay:15.0];
		}
		else {
			[self showMessage:NSLocalizedString(@"The publish checkin permission is required for location based Facebook fun", @"")];
		}
	}];
}

- (void)apiGraphUserAlbums {
	[[Facebook shared] fetchAlbums:^(NSArray *albums) {
		APIResultsViewController *controller = [[APIResultsViewController alloc] initWithTitle:@"Photo Albums"
																						  data:albums
																						action:nil];
		[self.navigationController pushViewController:controller animated:YES];
	} error:[self errorHandler:NSLocalizedString(@"Unable to fetch album list", @"")]];
}

/*
 * Graph API: Upload a photo. By default, when using me/photos the photo is uploaded
 * to the application album which is automatically created if it does not exist.
 */
- (void)apiGraphUserPhotosPost {
    // Download a sample photo
    NSURL *url = [NSURL URLWithString:@"http://www.facebook.com/images/devsite/iphone_connect_btn.jpg"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *img  = [[UIImage alloc] initWithData:data];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   img, @"picture",
                                   nil];
	
	[[Facebook shared] requestWithGraphPath:@"me/photos"
								 parameters:params
							  requestMethod:@"POST"
								   finalize:^(FBRequest *request) {
									  [request addCompletionHandler:^(FBRequest *request, id result) {
										  [self showMessage:@"Photo uploaded successfully."];
									  }];
								   }];
}

- (void)apiGraphUserVideos {
	[[Facebook shared] fetchVideos:^(NSArray *videos) {
		NSMutableArray *list = [NSMutableArray array];
		
		[videos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *video = (NSDictionary*)obj;
			
			[list addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							 [video objectForKey:@"id"], @"id",
							 [video objectForKey:@"name"], @"name",
							 [video objectForKey:@"picture"], @"picture",
							 [video objectForKey:@"description"], @"details",
							 nil]];
		}];
		
		APIResultsViewController *controller = [[APIResultsViewController alloc] initWithTitle:@"Videos"
																						  data:list
																						action:nil];
		[self.navigationController pushViewController:controller animated:YES];
	} error:[self errorHandler:NSLocalizedString(@"Unable to fetch album list", @"")]];
}

/*
 * Graph API: Post a video to the user's wall.
 */
- (void)apiGraphUserVideosPost {
    currentAPICall = kAPIGraphUserVideosPost;

    // Download a sample video
    NSURL *url = [NSURL URLWithString:@"https://developers.facebook.com/attachment/sample.mov"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   data, @"video.mov",
                                   @"video/quicktime", @"contentType",
                                   @"Video Test Title", @"title",
                                   @"Video Test Description", @"description",
								   nil];
	
	[[Facebook shared] requestWithGraphPath:@"me/videos"
								 parameters:params
							  requestMethod:@"POST"
								   finalize:^(FBRequest *request) {
									   [request addCompletionHandler:^(FBRequest *request, id result) {
										   [self showMessage:@"Video uploaded successfully."];
									   }];
								   }];
}

#pragma mark - UITableViewDatasource and UITableViewDelegate Methods
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        UITextView *headerTextView = [[UITextView alloc] initWithFrame:CGRectMake(10, 10, tableView.bounds.size.width, 60.0)];
        headerTextView.textAlignment = UITextAlignmentLeft;
        headerTextView.backgroundColor = [UIColor colorWithRed:0.9
                                                         green:0.9
                                                          blue:0.9 alpha:1];
        headerTextView.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        headerTextView.text = self.apiHeader;
        return headerTextView;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == 0) {
        // Automatically size the header for this API section
        CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);

        UIFont *titleFont = [UIFont fontWithName:@"Helvetica" size:14.0];
        CGSize labelSize = [self.apiHeader sizeWithFont:titleFont
                                constrainedToSize:constraintSize
                                    lineBreakMode:UILineBreakModeWordWrap];
        return labelSize.height + 20;
    } else {
        return 0.0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return  0.0;
    } else {
        // Automatically size the table row based on the content
        CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);

        NSString *cellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"title"];
        UIFont *cellFont = [UIFont boldSystemFontOfSize:14.0];
        CGSize labelSize = [cellText sizeWithFont:cellFont
                                constrainedToSize:constraintSize
                                    lineBreakMode:UILineBreakModeWordWrap];

        NSString *detailCellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"description"];
        UIFont *detailCellFont = [UIFont fontWithName:@"Helvetica" size:12.0];;
        CGSize detailLabelSize = [detailCellText sizeWithFont:detailCellFont
                                constrainedToSize:constraintSize
                                    lineBreakMode:UILineBreakModeWordWrap];

        return labelSize.height + detailLabelSize.height + 74;
    }
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 0;
    } else {
        return [apiMenuItems count];
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UILabel *textLabel;
    UILabel *detailTextLabel;
    UIButton *button;

    UIFont *cellFont = [UIFont boldSystemFontOfSize:14.0];
    UIFont *detailCellFont = [UIFont fontWithName:@"Helvetica" size:12.0];

    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        // Initialize API title UILabel
        textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        textLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        textLabel.tag = TITLE_TAG;
        textLabel.font = cellFont;
        [cell.contentView addSubview:textLabel];

        // Initialize API description UILabel
        detailTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        detailTextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        detailTextLabel.tag = DESCRIPTION_TAG;
        detailTextLabel.font = detailCellFont;
        detailTextLabel.textColor = [UIColor darkGrayColor];
        detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        detailTextLabel.numberOfLines = 0;
        [cell.contentView addSubview:detailTextLabel];

        // Initialize API button UIButton
        button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
        [button setBackgroundImage:[[UIImage imageNamed:@"MenuButton.png"]
                                    stretchableImageWithLeftCapWidth:9 topCapHeight:9]
                          forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(apiButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [cell.contentView addSubview:button];
    } else {
        textLabel = (UILabel *)[cell.contentView viewWithTag:TITLE_TAG];
        detailTextLabel = (UILabel *)[cell.contentView viewWithTag:DESCRIPTION_TAG];
        // For the button cannot search by tag since it is not constant
        // and is dynamically used figure out which button is clicked.
        // So instead we loop through subviews of the cell to find the button.
        for (UIView *subview in cell.contentView.subviews) {
            if([subview isKindOfClass:[UIButton class]]) {
                button = (UIButton *)subview;
            }
        }
    }

    CGSize constraintSize = CGSizeMake(280.0f, MAXFLOAT);

    // The API title
    NSString *cellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"title"];
    CGSize labelSize = [cellText sizeWithFont:cellFont
                            constrainedToSize:constraintSize
                                lineBreakMode:UILineBreakModeWordWrap];
    textLabel.frame = CGRectMake(20, 2,
                                  (cell.contentView.frame.size.width-40),
                                  labelSize.height);
    textLabel.text = cellText;

    // The API description
    NSString *detailCellText = [[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"description"];
    CGSize detailLabelSize = [detailCellText sizeWithFont:detailCellFont
                                        constrainedToSize:constraintSize
                                            lineBreakMode:UILineBreakModeWordWrap];
    detailTextLabel.frame = CGRectMake(20, (labelSize.height + 4),
                                       (cell.contentView.frame.size.width-40),
                                       detailLabelSize.height);
    detailTextLabel.text = detailCellText;


    // The API button
    CGFloat yButtonOffset = labelSize.height + detailLabelSize.height + 15;
    button.frame = CGRectMake(20, yButtonOffset, (cell.contentView.frame.size.width-40), 44);
    [button setTitle:[[apiMenuItems objectAtIndex:indexPath.row] objectForKey:@"button"]
            forState:UIControlStateNormal];
    // Set the tag that will later identify the button that is clicked.
    button.tag = indexPath.row;


    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

}

#pragma mark - CLLocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    // We will care about horizontal accuracy for this example

    // Try and avoid cached measurements
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) return;
    // test the measurement to see if it is more accurate than the previous measurement
    if (mostRecentLocation == nil || mostRecentLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // Store current location
        self.mostRecentLocation = newLocation;
        if (newLocation.horizontalAccuracy <= locationManager.desiredAccuracy) {
            // Measurement is good
            [self processLocationData];
            // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
            [NSObject cancelPreviousPerformRequestsWithTarget:self
                                                     selector:@selector(processLocationData)
                                                       object:nil];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if ([error code] != kCLErrorLocationUnknown) {
        [locationManager stopUpdatingLocation];
        locationManager.delegate = nil;
    }
    [self hideActivityIndicator];
}

#pragma mark - FBDialogDelegate Methods

/**
 * Called when a UIServer Dialog successfully return. Using this callback
 * instead of dialogDidComplete: to properly handle successful shares/sends
 * that return ID data back.
 */
- (void)dialog:(FBDialog*)dialog didCompleteWithURL:(NSURL *)url {
    if (![url query]) {
        NSLog(@"User canceled dialog or there was an error");
        return;
    }

    NSDictionary *params = [self parseURLParams:[url query]];
    switch (currentAPICall) {
        case kDialogFeedUser:
        case kDialogFeedFriend:
        {
            // Successful posts return a post_id
            if ([params valueForKey:@"post_id"]) {
                [self showMessage:@"Published feed successfully."];
                NSLog(@"Feed post ID: %@", [params valueForKey:@"post_id"]);
            }
            break;
        }
        case kDialogRequestsSendToMany:
        case kDialogRequestsSendToSelect:
        case kDialogRequestsSendToTarget:
        {
            // Successful requests return one or more request_ids.
            // Get any request IDs, will be in the URL in the form
            // request_ids[0]=1001316103543&request_ids[1]=10100303657380180
            NSMutableArray *requestIDs = [[NSMutableArray alloc] init];
            for (NSString *paramKey in params) {
                if ([paramKey hasPrefix:@"request_ids"]) {
                    [requestIDs addObject:[params objectForKey:paramKey]];
                }
            }
            if ([requestIDs count] > 0) {
                [self showMessage:@"Sent request successfully."];
                NSLog(@"Request ID(s): %@", requestIDs);
            }
            break;
        }
        default:
            break;
    }
}

- (void)dialogWasCancelled:(FBDialog *)dialog {
    NSLog(@"Dialog dismissed.");
}

- (void)dialog:(FBDialog*)dialog didFailWithError:(NSError *)error {
    NSLog(@"Error message: %@", [[error userInfo] objectForKey:@"error_msg"]);
    [self showMessage:@"Oops, something went haywire."];
}

/**
 * Called when the user granted additional permissions.
 */
- (void)userDidGrantPermission {
    // After permissions granted follow up with next API call
    switch (currentAPICall) {
        case kDialogPermissionsCheckinForRecent:
        {
            // After the check-in permissions have been
            // granted, save them in app session then
            // retrieve recent check-ins
            [self apiGraphUserCheckins];
            break;
        }
        case kDialogPermissionsExtended:
        {
            // In the sample test for getting user_likes
            // permssions, echo that success.
            [self showMessage:@"Permissions granted."];
            break;
        }
        default:
            break;
    }
}

/**
 * Called when the user canceled the authorization dialog.
 */
- (void)userDidNotGrantPermission {
    [self showMessage:@"Extended permissions not granted."];
}

@end
