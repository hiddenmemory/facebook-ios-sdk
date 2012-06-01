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

#pragma me
- (void)me:(void(^)(NSDictionary *me))completionHandler
	 error:(void(^)(NSError *error))errorHandler {
	
}

// ID, Name, Picture URL

#pragma friends

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

#pragma fetching content
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

#pragma sharing content
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

#pragma search
- (void)locationSearch:(NSString *)query
              location:(CLLocationCoordinate2D)location
              distance:(int)distance
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

#pragma search (private)

- (void)search:(NSString *)query
        fields:(NSArray *)fields
         range:(NSUInteger)range
    completion:(void(^)(NSArray *locations))completionHandler
         error:(void(^)(NSError *error))errorHandler
{
    
}
@end
