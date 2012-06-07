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

#define kFBFieldName @"name"
#define kFBFieldFirstName @"first_name"
#define kFBFieldMiddleName @"middle_name"
#define kFBFieldLastName @"last_name"
#define kFBFieldGender @"gender"
#define kFBFieldLocale @"locale"
#define kFBFieldLanguages @"languages"
#define kFBFieldLink @"link"
#define kFBFieldUsername @"username"
#define kFBFieldThirdPartyID @"third_party_id"
#define kFBFieldnstalled @"installed"
#define kFBFieldTimeZone @"timezone"
#define kFBFieldUpdatedTime @"updated_time"
#define kFBFieldVerified @"verified"
#define kFBFieldBio @"bio"
#define kFBFieldBirthday @"birthday"
#define kFBFieldCover @"cover"
#define kFBFieldEducation @"education"
#define kFBFieldEmail @"email"
#define kFBFieldHomeTown @"hometown"
#define kFBFieldInterestedIn @"interested_in"
#define kFBFieldLocation @"location"
#define kFBFieldPolitical @"political"
#define kFBFieldFavoriteAthletes @"favorite_athletes"
#define kFBFieldFavoriteTeams @"favorite_teams"
#define kFBFieldPicture @"picture"
#define kFBFieldQuotes @"quotes"
#define kFBFieldRelationshipStatus @"relationship_status"
#define kFBFieldReligion @"religion"
#define kFBFieldSignificantOther @"significant_other"
#define kFBFieldVideoUploadLimits @"video_upload_limits"
#define kFBFieldWebsite @"website"
#define kFBFieldWork @"work"

#pragma mark - me
- (void)fetchMeWithParameters:(NSDictionary*)parameters
                   completion:(void(^)(NSDictionary *me))completionHandler
                        error:(void(^)(NSError *error))errorHandler;

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

#define kFBPostMessageKey @"message"
#define kFBPostLinkKey @"link"
#define kFBPostNameKey @"name"
#define kFBPostPictureKey @"picture"

- (void)postWithParameters:(NSDictionary*)parameters
				completion:(void(^)(NSString *postID))completionHandler
					 error:(void(^)(NSError *error))errorHandler;

#pragma mark - sharing content

- (void)setStatus:(NSString*)status
	   completion:(void(^)(NSString *status))completionHandler
			error:(void(^)(NSError *error))errorHandler;

- (void)shareLink:(NSString*)link
		  message:(NSString*)message
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
