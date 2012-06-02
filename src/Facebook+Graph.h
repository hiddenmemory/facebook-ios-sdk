//
//  Facebook+Graph.h
//  Hackbook
//
//  Created by Chris Ross on 01/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "Facebook.h"
#import <CoreLocation/CoreLocation.h>

@interface Facebook (Graph)

#pragma mark - me
- (void)fetchMe:(void(^)(NSDictionary *me))completionHandler
	 error:(void(^)(NSError *error))errorHandler;

- (void)deletePermissions:(void(^)(Facebook*))completionHandler;

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

#pragma mark - sharing content

- (void)setStatus:(NSString*)status
	   completion:(void(^)(NSString *status))completionHandler
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

#pragma mark - search
- (void)searchLocations:(NSString *)query
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
