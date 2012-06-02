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
    
    NSArray *keys = [NSArray arrayWithObjects:kFBFieldName,kFBFieldPicture, nil];
    [self friendsWithKeys:keys completion:completionHandler error:errorHandler];
}

- (void)friendsWithKeys:(NSArray*)keys 
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

- (void)friendsWithApp:(void(^)(NSArray *friends))completionHandler
				 error:(void(^)(NSError *error))errorHandler {
	
	[self requestWithMethodName:@"friends.getAppUsers"
								  parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"name,picture", @"fields", nil]
								  completion:^(FBRequest *request, id result) {
									  NSLog(@"Result: %@", result);
									  [self idsQuery:[NSString stringWithFormat:@"%@",[result componentsJoinedByString:@","]]
                                              fields:[NSArray arrayWithObjects:kFBFieldName, kFBFieldPicture, nil]
                                               range:0
                                          completion:^(NSArray *people) {
                                              if( completionHandler ) {
                                                  completionHandler(people);
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


- (void)postsSearch:(NSString *)query
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
    
    [self search:query parameters:parameters range:range completion:completionHandler error:errorHandler];

}

- (void)pagesSearch:(NSString *)query
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

- (void)eventsSearch:(NSString *)query
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

- (void)checkinsSearch:(NSString *)query   
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

- (void)idsQuery:(NSString *)query   
           fields:(NSArray *)fields
            range:(NSUInteger)range
       completion:(void(^)(NSArray *locations))completionHandler
            error:(void(^)(NSError *error))errorHandler
{
    
    
    NSString *fieldString = [fields componentsJoinedByString:@","];
    
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                query, @"ids",
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
