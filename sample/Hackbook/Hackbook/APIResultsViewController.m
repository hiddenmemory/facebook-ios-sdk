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

#import "APIResultsViewController.h"
#import "HackbookAppDelegate.h"

@interface APIResultsViewController () {
	NSCache *thumbnailCache;
	NSMutableData *incomingImage;
	NSMutableArray *incomingImageQueue;
	NSURLConnection *incomingImageConnection;
	
	UITableView *tableView;
}

@end

@implementation APIResultsViewController

@synthesize myData;
@synthesize myAction;
@synthesize messageLabel;
@synthesize messageView;

- (id)initWithTitle:(NSString *)title data:(NSArray *)data action:(NSString *)action {
    self = [super init];
    if (self) {
		myData = data;
		
		thumbnailCache = [[NSCache alloc] init];
		incomingImageQueue = [NSMutableArray array];
		incomingImage = [NSMutableData data];
		
        self.navigationItem.title = title;
        self.myAction = action;
    }
    return self;
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

    // Main Menu Table
    tableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                            style:UITableViewStylePlain];
    [tableView setBackgroundColor:[UIColor whiteColor]];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if ([self.myAction isEqualToString:@"places"]) {
        UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 30)];
        headerLabel.text = @"  Tap selection to check in";
        headerLabel.font = [UIFont fontWithName:@"Helvetica" size:14.0];
        headerLabel.backgroundColor = [UIColor colorWithRed:255.0/255.0
                                                      green:248.0/255.0
                                                       blue:228.0/255.0
                                                      alpha:1];
        tableView.tableHeaderView = headerLabel;
    }
    [self.view addSubview:tableView];

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

#pragma mark - Facebook API Calls
/*
 * Graph API: Check in a user to the location selected in the previous view.
 */
- (void)apiGraphUserCheckins:(NSUInteger)index {
    NSDictionary *coordinates = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [[[myData objectAtIndex:index] objectForKey:@"location"] objectForKey:@"latitude"],@"latitude",
                                  [[[myData objectAtIndex:index] objectForKey:@"location"] objectForKey:@"longitude"],@"longitude",
                                  nil];

    NSString *coordinatesStr = [self stringWithObject:coordinates];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   [[myData objectAtIndex:index] objectForKey:@"id"], @"place",
                                   coordinatesStr, @"coordinates",
                                   @"", @"message",
                                   nil];
	
	[[Facebook shared] requestWithGraphPath:@"me/checkins"
								 parameters:params
							  requestMethod:@"POST"
								   finalize:^(FBRequest *request) {
									   [request addCompletionHandler:^(FBRequest *request, id result) {
										   [self showMessage:@"Checked in successfully"];
									   }];
									   
									   [request addErrorHandler:^(FBRequest *request, NSError *error) {
										   [self showMessage:@"Oops, something went haywire."];
									   }];
								   }];
}

#pragma mark -
#pragma mark NSURLConnection Callbacks

- (void)downloadNextImage {
	if( [incomingImageQueue count] ) {
		NSDictionary *object = [incomingImageQueue objectAtIndex:0];
		
		NSString *objectID = [object objectForKey:@"id"];
		
		NSString *url = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture",objectID];

		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
		
		incomingImageConnection = [[NSURLConnection alloc] initWithRequest:request
																  delegate:self
														  startImmediately:NO];
								   
		[incomingImageConnection scheduleInRunLoop:[NSRunLoop mainRunLoop] 
										   forMode:NSRunLoopCommonModes];
		
		[incomingImageConnection start];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    [incomingImage setLength:0];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
    [incomingImage appendData:data];
}
- (void)connection:(NSURLConnection *)_connection didFailWithError:(NSError *)error 
{
	[incomingImageQueue removeObjectAtIndex:0];
	[self downloadNextImage];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)_connection 
{
    UIImage *image = [UIImage imageWithData:incomingImage];
	NSDictionary *row = [incomingImageQueue objectAtIndex:0];
	
	[thumbnailCache setObject:image forKey:[row objectForKey:@"id"]];
		
	[tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:[[row objectForKey:@"row"] unsignedIntegerValue]
																				  inSection:-0]]
					 withRowAnimation:UITableViewRowAnimationFade];
	
	[incomingImageQueue removeObjectAtIndex:0];
	
	[self downloadNextImage];
}

#pragma mark - Private Methods
/*
 * Helper method to return the picture endpoint for a given Facebook
 * object. Useful for displaying user, friend, or location pictures.
 */

- (UIImage *)imageForObject:(NSString *)objectID row:(NSUInteger)row {	
	if( [thumbnailCache objectForKey:objectID] ) {
		return [thumbnailCache objectForKey:objectID];
	}
	else {
		BOOL requestDownload = ([incomingImageQueue count] == 0);
		
		[incomingImageQueue addObject:[NSDictionary dictionaryWithObjectsAndKeys:
									   objectID, @"id",
									   [NSNumber numberWithUnsignedInteger:row], @"row", 
									   nil]];
		
		if( requestDownload ) {
			[self downloadNextImage];
		}
	}
	
    return nil;
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

/*
 * This method handles any clean up needed if the view
 * is about to disappear.
 */
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self hideMessage];
}

#pragma mark - UITableView Datasource and Delegate Methods
- (CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80.0;
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)_tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)_tableView numberOfRowsInSection:(NSInteger)section {
    return [myData count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        // Show disclosure only if this view is related to showing nearby places, thus allowing
        // the user to check-in.
        if ([self.myAction isEqualToString:@"places"]) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

	NSDictionary *row = [myData objectAtIndex:indexPath.row];
	
    cell.textLabel.text = [row objectForKey:@"name"];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 2;
    // If extra information available then display this.
    if ([row objectForKey:@"details"]) {
        cell.detailTextLabel.text = [row objectForKey:@"details"];
        cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0];
        cell.detailTextLabel.lineBreakMode = UILineBreakModeCharacterWrap;
        cell.detailTextLabel.numberOfLines = 2;
    }
    // The object's image
    cell.imageView.image = [self imageForObject:[row objectForKey:@"id"]
											row:indexPath.row];
    // Configure the cell.
    return cell;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Only handle taps if the view is related to showing nearby places that
    // the user can check-in to.
    if ([self.myAction isEqualToString:@"places"]) {
        [self apiGraphUserCheckins:indexPath.row];
    }
    [_tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end
