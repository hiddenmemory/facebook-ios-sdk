/*
 * Copyright 2012 Chris Ross - hiddenMemory Ltd - chris@hiddenmemory.co.uk
 * Copyright 2012 Kieran Gutteridge - IntoHand Ltd - kieran.gutteridge@intohand.com
 * Copyright 2010 Facebook
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *    http://www.apache.org/licenses/LICENSE-2.0
 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "Facebook+Graph.h"

@interface Facebook (GraphPrivate)

- (void)search:(NSString *)query
                fields:(NSArray *)fields
				 range:(NSUInteger)range
			completion:(void(^)(NSArray *locations))completionHandler
				 error:(void(^)(NSError *error))errorHandler;


@end

@implementation Facebook (Graph)

static NSString *const kFBSearchTypePost = @"post";
static NSString *const kFBSearchTypeUser = @"user";
static NSString *const kFBSearchTypePage = @"page";
static NSString *const kFBSearchTypeEvent = @"event";
static NSString *const kFBSearchTypeGroup = @"group";
static NSString *const kFBSearchTypePlace = @"place";
static NSString *const kFBSearchTypeCheckIn = @"checkin";

static NSString *const kFBFieldName = @"name";
static NSString *const kFBFieldPicture = @"picture";

- (NSArray*)permissionsRequired {
	return [NSArray arrayWithObjects:
			@"user_about_me",
			@"friends_about_me",
			@"publish_stream",
			@"user_photos",
			@"user_videos",
			nil];
}

#pragma mark - me
- (void)fetchMe:(void(^)(NSDictionary *me))completionHandler
	 error:(void(^)(NSError *error))errorHandler {
	
	[self usingPermission:@"user_about_me" request:^{
		[self requestWithGraphPath:@"me"
						parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"name,picture", @"fields", nil]
						completion:^(FBRequest *request, id result) {	
							if( completionHandler ) {
								completionHandler(result);
							}
						}
							 error:^(FBRequest *request, NSError *error) {
								 if( errorHandler ) {
									 errorHandler(error);
								 }
							 }];
	}];
}

- (void)fetchProfilePictureWithID:(NSString *)ID
					   completion:(void (^)(UIImage *picture))completionHandler
							error:(void (^)(NSError *error))errorHandler {
    
	[self usingPermissions:[NSArray arrayWithObjects:@"user_about_me", @"friends_about_me", nil] request:^{
		[self requestWithGraphPath:[NSString stringWithFormat:@"%@/picture?type=square", ID]
						  finalize:^(FBRequest *request) {
							  [request addRawHandler:^(FBRequest *request, NSData *raw) {
								  if( completionHandler ) {
									  completionHandler([UIImage imageWithData:raw]);
								  }
							  }];
							  if (errorHandler) {
								  [request addErrorHandler:^(FBRequest *request, NSError *error) {
									  errorHandler(error);
								  }];
							  }
						  }];
		
	}];
}

- (void)deletePermissions:(void (^)(Facebook*))completionHandler {
	[[Facebook shared] addLogoutHandler:completionHandler];

	[[Facebook shared] requestWithGraphPath:@"me/permissions"
								 parameters:[NSDictionary dictionary]
							  requestMethod:@"DELETE"
								   finalize:^(FBRequest *request) {
									   [request addCompletionHandler:^(FBRequest *request, id result) {
										   [[Facebook shared] logout];
									   }];
								   }];
	
}

#pragma mark - friends

- (void)fetchFriends:(void(^)(NSArray *friends))completionHandler
		  error:(void(^)(NSError *error))errorHandler {
    
    NSArray *keys = [NSArray arrayWithObjects:kFBFieldName,kFBFieldPicture, nil];
    [self fetchFriendsWithKeys:keys completion:completionHandler error:errorHandler];
}

- (void)fetchFriendsWithKeys:(NSArray*)keys 
			 completion:(void(^)(NSArray *friends))completionHandler
				  error:(void(^)(NSError *error))errorHandler {
    NSString *keysString = [keys componentsJoinedByString:@","];
    NSDictionary *parameters = [NSDictionary dictionaryWithObject:keysString forKey:@"fields"];

    [self requestWithGraphPath:@"me/friends"
					parameters:parameters
					completion:^(FBRequest *request, id result) {
						NSArray *realResult = nil;
						
						if( [[result class] isSubclassOfClass:[NSArray class]] ) {
							realResult = result;
						}
						else if( [[result class] isSubclassOfClass:[NSDictionary class]] && [result objectForKey:@"data"] ) {
							realResult = [result objectForKey:@"data"];
						}
						
						if( completionHandler ) {
							completionHandler(realResult);
						}
					}
						 error:^(FBRequest *request, NSError *error) {
							 if( errorHandler ) {
								 errorHandler(error);
							 }
						 }];
}

- (void)fetchFriendsWithApp:(void(^)(NSArray *friends))completionHandler
				 error:(void(^)(NSError *error))errorHandler {

	[self requestWithMethodName:@"friends.getAppUsers"
								  parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"name,picture", @"fields", nil]
								  completion:^(FBRequest *request, id result) {
									  NSLog(@"Result: %@", result);
									  [self fetchIDsQuery:result
                                              fields:[NSArray arrayWithObjects:kFBFieldName, kFBFieldPicture, nil]
                                               range:0
                                          completion:^(NSDictionary *people) {
                                              if( completionHandler ) {
                                                  completionHandler([people allValues]);
                                              }
                                          } 
                                               error:^(NSError *error) {
                                                   if( errorHandler ) {
                                                       errorHandler(error);
                                                   }
                                               }];
								  }];
}

#pragma mark - fetching content
- (void)fetchAlbums:(void(^)(NSArray *albums))completionHandler
		 error:(void(^)(NSError *error))errorHandler {

	[self usingPermission:@"user_photos" request:^{
		[self requestWithGraphPath:@"me/albums"
						  finalize:^(FBRequest *request) {
							  [request addCompletionHandler:^(FBRequest *request, id result) {
								  if( completionHandler ) {
									  if( [[result class] isSubclassOfClass:[NSDictionary class]] ) {
										  result = [result objectForKey:@"data"];
									  }
									  completionHandler(result);
								  }
							  }];
							  [request addErrorHandler:^(FBRequest *request, NSError *error) {
								  if( errorHandler ) {
									  errorHandler(error);
								  }
							  }];
						  }];	
	}];
}

- (void)fetchPhotosInAlbum:(NSString*)album
		   completion:(void(^)(NSArray *photos))completionHandler
				error:(void(^)(NSError *error))errorHandler {

}

- (void)fetchVideos:(void(^)(NSArray *photos))completionHandler
		 error:(void(^)(NSError *error))errorHandler {
	
	[self usingPermission:@"user_videos" request:^{
		[self requestWithGraphPath:@"me/videos/uploaded"
						  finalize:^(FBRequest *request) {
							  [request addCompletionHandler:^(FBRequest *request, id result) {
								  if( completionHandler ) {
									  if( [[result class] isSubclassOfClass:[NSDictionary class]] ) {
										  result = [result objectForKey:@"data"];
									  }
									  completionHandler(result);
								  }
							  }];
							  [request addErrorHandler:^(FBRequest *request, NSError *error) {
								  if( errorHandler ) {
									  errorHandler(error);
								  }
							  }];
						  }];
	}];
}

#pragma mark - post to wall

//parameters
//message, picture, link, name, caption, description...
//note: picture is a URL to an already existing picture online
-(void)postWithParameters:(NSDictionary *)parameters 
               completion:(void (^)(NSString *))completionHandler 
                    error:(void (^)(NSError *))errorHandler {
    
	[self usingPermission:@"publish_stream" request:^{
		[[Facebook shared] requestWithGraphPath:@"me/feed"
									 parameters:parameters
								  requestMethod:FBMethodPost
									   finalize:^(FBRequest *request) {
										   if( completionHandler ) {
											   [request addCompletionHandler:^(FBRequest *request, id result) {
												   NSLog(@"Result: %@", request);
												   completionHandler([result objectForKey:@"id"]);
											   }];
										   }
										   if( errorHandler ) {
											   [request addErrorHandler:^(FBRequest *request, NSError *error) {
												   NSLog(@"Error: %@", error);
												   errorHandler(error);
											   }];
										   }
									   }];
	}];
}

#pragma mark - sharing content

/**
 * Helper method to parse URL query parameters
 */
- (NSDictionary *)parseURLParams:(NSString *)query {
	NSArray *pairs = [query componentsSeparatedByString:@"&"];
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	for (NSString *pair in pairs) {
		NSArray *kv = [pair componentsSeparatedByString:@"="];
		NSString *val = [[kv objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[params setObject:val forKey:[kv objectAtIndex:0]];
	}
    return params;
}

/**
 * Moved the main workings of this to the generic method postWithParameters...
 */
- (void)setStatus:(NSString*)status
	   completion:(void(^)(NSString *status))completionHandler
			error:(void(^)(NSError *error))errorHandler {
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   status, @"message",
                                   nil];
    
    [self postWithParameters:params
                  completion:^(NSString *postID) {
                      completionHandler(status);
                  }
                       error:^(NSError *error) {
                           errorHandler(error);
                       }];
}

-(void)shareLink:(NSString*)link
     withMessage:(NSString*)message
      completion:(void(^)(NSString *linkID))completionHandler
           error:(void(^)(NSError *error))errorHandler {
    
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    [requestParams setObject:link forKey:@"link"];
    if (message) {
        [requestParams setObject:message forKey:@"message"];
    }
    
    [self usingPermission:@"publish_stream" request:^{
        [self requestWithGraphPath:@"me/links"
                        parameters:requestParams
                        requestMethod:FBMethodPost
                            finalize:^(FBRequest *request) {
                                if( completionHandler ) {
                                    [request addCompletionHandler:^(FBRequest *request, id result) {
                                        NSLog(@"Result: %@", result);
                                        completionHandler([result objectForKey:@"id"]);
                                    }];
                                }
                                if( errorHandler ) {
                                    [request addErrorHandler:^(FBRequest *request, NSError *error) {
                                        NSLog(@"Error: %@", error);
                                        errorHandler(error);
                                    }];
                                }
                            }];
    }];
}

- (void)sharePhoto:(UIImage*)image
			 title:(NSString*)title
		completion:(void(^)(NSString *photoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler {
    
    [self sharePhoto:image 
               album:@"me"
               title:title
          completion:^(NSString *photoID) {
              NSLog(@"%@", photoID);
          }
               error:^(NSError *error) {
                   NSLog(@"%@", error.description);
               }];
}

- (void)sharePhoto:(UIImage*)image
			 album:(NSString*)album
			 title:(NSString*)title
		completion:(void(^)(NSString *photoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler {
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:image, @"picture", title, @"name", nil];
    
    [self usingPermission:@"publish_stream" request:^{
        [self requestWithGraphPath:[NSString stringWithFormat:@"%@/photos", album]
                        parameters:params
                     requestMethod:FBMethodPost
                          finalize:^(FBRequest *request) {
                              if( completionHandler ) {
                                  [request addCompletionHandler:^(FBRequest *request, id result) {
                                      NSLog(@"Result: %@", result);
                                      completionHandler([result objectForKey:@"id"]);
                                  }];
                              }
                              if( errorHandler ) {
                                  [request addErrorHandler:^(FBRequest *request, NSError *error) {
                                      NSLog(@"Error: %@", error);
                                      errorHandler(error);
                                  }];
                              }
                          }];
    }];
    
}

- (void)shareVideo:(NSData*)video
			 title:(NSString*)title
		completion:(void(^)(NSString *videoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler {

}

#pragma mark - OpenGraph

-(void)shareOpenGraphActivityWithNamespace:(NSString*)namespace
                                    action:(NSString*)action
                                parameters:(NSDictionary*)parameters
                                completion:(void(^)(NSString *response))completionHandler
                                     error:(void(^)(NSError *error))errorHandler {
    NSString *path = [NSString stringWithFormat:@"me/%@:%@", namespace, action];
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    [self usingPermission:@"publish_stream" request:^{
        [self requestWithGraphPath:path
                        parameters:requestParams
                     requestMethod:FBMethodPost
                          finalize:^(FBRequest *request) {
                              if( completionHandler ) {
                                  [request addCompletionHandler:^(FBRequest *request, id result) {
                                      NSLog(@"Result: %@", result);
                                      completionHandler([result objectForKey:@"id"]);
                                  }];
                              }
                              if( errorHandler ) {
                                  [request addErrorHandler:^(FBRequest *request, NSError *error) {
                                      NSLog(@"Error: %@", error);
                                      errorHandler(error);
                                  }];
                              }
                          }];
    }];
}

#pragma mark - search
- (void)searchLocation:(NSString *)query
              coordinate:(CLLocationCoordinate2D)coordinate
              distance:(int)distance
                fields:(NSArray *)fields
				 range:(NSUInteger)range
			completion:(void(^)(NSArray *locations))completionHandler
				 error:(void(^)(NSError *error))errorHandler
{    
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSString *centerLocation = [[NSString alloc] initWithFormat:@"%f,%f",
                                coordinate.latitude,
                                coordinate.longitude];
    
    NSString *distanceString = [NSString stringWithFormat:@"%i",distance];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                   kFBSearchTypePlace,  @"type",
                                   centerLocation, @"center",
                                   distanceString, @"distance",
                                     fieldString, @"fields", 
                                nil];
    
    [self search:query parameters:parameters range:range completion:completionHandler error:errorHandler];

}


- (void)searchPosts:(NSString *)query
             fields:(NSArray *)fields
              range:(NSUInteger)range
         completion:(void(^)(NSArray *locations))completionHandler
              error:(void(^)(NSError *error))errorHandler
{
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                kFBSearchTypePost, @"type",
                                fieldString, @"fields", 
                                nil];
    
    [self search:query parameters:parameters range:range completion:completionHandler error:errorHandler];
}

- (void)searchPeople:(NSString *)query
              fields:(NSArray *)fields
               range:(NSUInteger)range
          completion:(void(^)(NSArray *locations))completionHandler
               error:(void(^)(NSError *error))errorHandler
{
    
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    kFBSearchTypeUser, @"type",
                                          fieldString, @"fields", 
                                       nil];
    
    [self search:query parameters:parameters range:range completion:completionHandler error:errorHandler];

}

- (void)searchPages:(NSString *)query
             fields:(NSArray *)fields
              range:(NSUInteger)range
         completion:(void(^)(NSArray *locations))completionHandler
              error:(void(^)(NSError *error))errorHandler
{
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                kFBSearchTypePage, @"type",
                                fieldString, @"fields", 
                                nil];
    
    [self search:query parameters:parameters range:range completion:completionHandler error:errorHandler];
}

- (void)searchEvents:(NSString *)query
              fields:(NSArray *)fields
               range:(NSUInteger)range
          completion:(void(^)(NSArray *locations))completionHandler
               error:(void(^)(NSError *error))errorHandler
{
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                kFBSearchTypeEvent, @"type",
                                fieldString, @"fields", 
                                nil];
    
    [self search:query parameters:parameters range:range completion:completionHandler error:errorHandler];
}

- (void)searchCheckins:(NSString *)query   
                fields:(NSArray *)fields
                 range:(NSUInteger)range
            completion:(void(^)(NSArray *locations))completionHandler
                 error:(void(^)(NSError *error))errorHandler
{
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                kFBSearchTypeCheckIn, @"type",
                                fieldString, @"fields", 
                                nil];
    
    [self search:query parameters:parameters range:range completion:completionHandler error:errorHandler];
}

#pragma mark - id query

- (void)fetchIDsQuery:(NSArray *)query   
           fields:(NSArray *)fields
            range:(NSUInteger)range
       completion:(void(^)(NSDictionary *objectMap))completionHandler
            error:(void(^)(NSError *error))errorHandler
{
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [query componentsJoinedByString:@","], @"ids",
                                fieldString, @"fields", 
                                nil];
    
    [self requestWithGraphPath:@""
					parameters:parameters
					completion:^(FBRequest *request, id result) {	
						if( completionHandler ) {
							completionHandler(result);
						}
					}
						 error:^(FBRequest *request, NSError *error) {
							 if( errorHandler ) {
								 errorHandler(error);
							 }
						 }];
}

#pragma mark - search (private)

- (void)search:(NSString *)query
    parameters:(NSDictionary *)parameters
         range:(int)range
    completion:(void(^)(NSArray *locations))completionHandler
         error:(void(^)(NSError *error))errorHandler
{
    NSMutableDictionary *p = [NSDictionary dictionaryWithDictionary:parameters];
    [p setObject:query forKey:@"q"];
    
    [self requestWithGraphPath:@"search"
					parameters:parameters
					completion:^(FBRequest *request, id result) {	
						if( completionHandler ) {
							completionHandler(result);
						}
					}
						 error:^(FBRequest *request, NSError *error) {
							 if( errorHandler ) {
								 errorHandler(error);
							 }
						 }];
}
@end
