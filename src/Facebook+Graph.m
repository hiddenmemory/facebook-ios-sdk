//
//  Facebook+Graph.m
//  Hackbook
//
//  Created by Chris Ross on 01/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

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
static NSString *const kFBSearchTypeIds = @"ids";

static NSString *const kFBFieldName = @"name";
static NSString *const kFBFieldPicture = @"picture";

#pragma mark - me
- (void)me:(void(^)(NSDictionary *me))completionHandler
	 error:(void(^)(NSError *error))errorHandler {

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
}

#pragma mark - friends

- (void)friends:(void(^)(NSArray *friends))completionHandler
		  error:(void(^)(NSError *error))errorHandler {
	

}

- (void)friendsWithKeys:(NSArray*)keys 
			 completion:(void(^)(NSArray *friends))completionHandler
				  error:(void(^)(NSError *error))errorHandler {
	
}

- (void)friendsWithApp:(void(^)(NSArray *friends))completionHandler
				 error:(void(^)(NSError *error))errorHandler {
	
}

#pragma mark - fetching content
- (void)albums:(void(^)(NSArray *albums))completionHandler
		 error:(void(^)(NSError *error))errorHandler {
	
}

- (void)photosInAlbum:(NSString*)album
		   completion:(void(^)(NSArray *photos))completionHandler
				error:(void(^)(NSError *error))errorHandler {
	
}

- (void)videos:(void(^)(NSArray *photos))completionHandler
		 error:(void(^)(NSError *error))errorHandler {
	
}

#pragma mark - sharing content
- (void)setStatus:(NSString*)status
	   completion:(void(^)(NSString *status))completionHandler
			error:(void(^)(NSError *error))errorHandler {
	
}

- (void)sharePhoto:(UIImage*)image
			 title:(NSString*)title
		completion:(void(^)(NSString *photoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler {
	
}

- (void)sharePhoto:(UIImage*)image
			 album:(NSString*)album
			 title:(NSString*)title
		completion:(void(^)(NSString *photoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler {
	
}

- (void)shareVideo:(NSData*)video
			 title:(NSString*)title
		completion:(void(^)(NSString *videoID))completionHandler
			 error:(void(^)(NSError *error))errorHandler {
	
}

#pragma mark - search
- (void)locationSearch:(NSString *)query
              coordinate:(CLLocationCoordinate2D)coordinate
              distance:(int)distance
                fields:(NSArray *)fields
				 range:(NSUInteger)range
			completion:(void(^)(NSArray *locations))completionHandler
				 error:(void(^)(NSError *error))errorHandler
{
    NSString *centerLocation = [[NSString alloc] initWithFormat:@"%f,%f",
                                coordinate.latitude,
                                coordinate.longitude];
    
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSString *distanceString = [NSString stringWithFormat:@"%i",distance];
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   kFBSearchTypePlace,  @"type",
                                   centerLocation, @"center",
                                   distanceString, @"distance",
                                     fieldString, @"fields", 
                                    nil];
    
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


- (void)postsSearch:(NSString *)query
             fields:(NSArray *)fields
              range:(NSUInteger)range
         completion:(void(^)(NSArray *locations))completionHandler
              error:(void(^)(NSError *error))errorHandler
{
    
}

- (void)peopleSearch:(NSString *)query
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
    
    [self search:query parameters:parameters completion:completionHandler error:errorHandler];

}

- (void)pagesSearch:(NSString *)query
             fields:(NSArray *)fields
              range:(NSUInteger)range
         completion:(void(^)(NSArray *locations))completionHandler
              error:(void(^)(NSError *error))errorHandler
{
    
}

- (void)eventsSearch:(NSString *)query
              fields:(NSArray *)fields
               range:(NSUInteger)range
          completion:(void(^)(NSArray *locations))completionHandler
               error:(void(^)(NSError *error))errorHandler
{
    
}

- (void)checkinsSearch:(NSString *)query   
                fields:(NSArray *)fields
                 range:(NSUInteger)range
            completion:(void(^)(NSArray *locations))completionHandler
                 error:(void(^)(NSError *error))errorHandler
{
    
}

#pragma mark - search (private)

- (void)search:(NSString *)query
    parameters:(NSDictionary *)parameters
    completion:(void(^)(NSArray *locations))completionHandler
         error:(void(^)(NSError *error))errorHandler
{
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
