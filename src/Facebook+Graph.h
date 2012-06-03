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
#import "Facebook.h"
#import <CoreLocation/CoreLocation.h>

@interface Facebook (Graph)

- (NSArray*)permissionsRequired;

#pragma mark - me
- (void)fetchMe:(void(^)(NSDictionary *me))completionHandler
	 error:(void(^)(NSError *error))errorHandler;

- (void)deletePermissions:(void(^)(Facebook*))completionHandler;

- (void)fetchProfilePictureWithID:(NSString *)ID
					   completion:(void (^)(UIImage *pic))completionHandler
							error:(void (^)(NSError *error))errorHandler;

#pragma mark - friends
// ID, Name, Picture URL
- (void)fetchFriends:(void(^)(NSArray *friends))completionHandler
		  error:(void(^)(NSError *error))errorHandler;

- (void)fetchFriendsWithKeys:(NSArray*)keys 
			 completion:(void(^)(NSArray *friends))completionHandler
				  error:(void(^)(NSError *error))errorHandler;

- (void)fetchFriendsWithApp:(void(^)(NSArray *friends))completionHandler
				 error:(void(^)(NSError *error))errorHandler;


#pragma mark - fetching content
- (void)fetchAlbums:(void(^)(NSArray *albums))completionHandler
		 error:(void(^)(NSError *error))errorHandler;

- (void)fetchPhotosInAlbum:(NSString*)album
		   completion:(void(^)(NSArray *photos))completionHandler
				error:(void(^)(NSError *error))errorHandler;

- (void)fetchVideos:(void(^)(NSArray *photos))completionHandler
		 error:(void(^)(NSError *error))errorHandler;

#pragma mark - post to wall

-(void)postWithParameters:(NSDictionary*)parameters
               completion:(void(^)(NSString *postID))completionHandler
                    error:(void(^)(NSError *error))errorHandler;

#pragma mark - sharing content

- (void)setStatus:(NSString*)status
	   completion:(void(^)(NSString *status))completionHandler
			error:(void(^)(NSError *error))errorHandler;

-(void)shareLink:(NSString*)link
     withMessage:(NSString*)message
      completion:(void(^)(NSString *linkID))completionHandler
           error:(void(^)(NSError *error))errorHandler;

- (void)sharePhoto:(UIImage*)image
			 title:(NSString*)title
		completion:(void(^)(NSString *photoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler;

- (void)sharePhoto:(UIImage*)image
			 album:(NSString*)album
			 title:(NSString*)title
		completion:(void(^)(NSString *photoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler;

- (void)shareVideo:(NSData*)video
			 title:(NSString*)title
		completion:(void(^)(NSString *videoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler;

#pragma mark - OpenGraph

-(void)shareOpenGraphActivityWithNamespace:(NSString*)namespace
                                    action:(NSString*)action
                                parameters:(NSDictionary*)parameters
                                completion:(void(^)(NSString *response))completionHandler
                                     error:(void(^)(NSError *error))errorHandler;

#pragma mark - search
- (void)searchLocation:(NSString *)query
            coordinate:(CLLocationCoordinate2D)coordinate
              distance:(int)distance
                fields:(NSArray *)fields
				 range:(NSUInteger)range
			completion:(void(^)(NSArray *locations))completionHandler
				 error:(void(^)(NSError *error))errorHandler;

- (void)searchPosts:(NSString *)query
             fields:(NSArray *)fields
              range:(NSUInteger)range
         completion:(void(^)(NSArray *locations))completionHandler
              error:(void(^)(NSError *error))errorHandler;

- (void)searchPeople:(NSString *)query
              fields:(NSArray *)fields
               range:(NSUInteger)range
          completion:(void(^)(NSArray *locations))completionHandler
               error:(void(^)(NSError *error))errorHandler;

- (void)searchPages:(NSString *)query
             fields:(NSArray *)fields
              range:(NSUInteger)range
         completion:(void(^)(NSArray *locations))completionHandler
              error:(void(^)(NSError *error))errorHandler;

- (void)searchEvents:(NSString *)query
              fields:(NSArray *)fields
               range:(NSUInteger)range
          completion:(void(^)(NSArray *locations))completionHandler
               error:(void(^)(NSError *error))errorHandler;

- (void)searchCheckins:(NSString *)query   
                fields:(NSArray *)fields
                 range:(NSUInteger)range
            completion:(void(^)(NSArray *locations))completionHandler
				 error:(void(^)(NSError *error))errorHandler;

#pragma mark - id query

- (void)fetchIDsQuery:(NSArray *)query   
		  fields:(NSArray *)fields
		   range:(NSUInteger)range
	  completion:(void(^)(NSDictionary *objectMap))completionHandler
		   error:(void(^)(NSError *error))errorHandler;




@end
