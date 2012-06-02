//
//  Facebook+Graph.m
//  Hackbook
//
//  Created by Chris Ross on 01/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "Facebook+Graph.h"

@implementation Facebook (Graph)

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

// ID, Name, Picture URL
- (void)friends:(void(^)(NSArray *friends))completionHandler
		  error:(void(^)(NSError *error))errorHandler {
	
	[self requestWithGraphPath:@"me/friends"
					parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"name,picture", @"fields", nil]
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

- (void)friendsWithKeys:(NSArray*)keys 
			 completion:(void(^)(NSArray *friends))completionHandler
				  error:(void(^)(NSError *error))errorHandler {
	
}

- (void)friendsWithApp:(void(^)(NSArray *friends))completionHandler
				 error:(void(^)(NSError *error))errorHandler {
	
	[[Facebook shared] requestWithMethodName:@"friends.getAppUsers"
								  parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"name,picture", @"fields", nil]
								  completion:^(FBRequest *request, id result) {
									  NSLog(@"Result: %@", result);
								  }];
}

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

- (void)locationSearch:(NSString *)query
              location:(CLLocationCoordinate2D)location
                fields:(NSArray *)fields
				 range:(NSUInteger)range
			completion:(void(^)(NSArray *locations))completionHandler
				 error:(void(^)(NSError *error))errorHandler
{
    
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
@end
