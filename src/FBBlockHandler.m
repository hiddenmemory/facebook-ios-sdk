//
//  FBBlockHandler.m
//  facebook-ios-sdk
//
//  Created by Chris Ross on 03/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import "FBBlockHandler.h"

@interface FBBlockHandler () {
	NSMutableDictionary *eventHandlers;
}
@end

@implementation FBBlockHandler

- (id)init {
	self = [super init];
	if( self ) {
		eventHandlers = [NSMutableDictionary dictionary];
	}
	return self;
}

- (void)registerEventHandler:(NSString*)event handler:(id)block {
	[self registerEventHandler:event discard:NO handler:block];
}
- (void)registerEventHandler:(NSString*)event discard:(BOOL)discard handler:(id)block {
	if( block ) {
		NSMutableArray *handlers = [eventHandlers objectForKey:event];
		
		if( !handlers ) {
			handlers = [NSMutableArray array];
			[eventHandlers setObject:handlers forKey:event];
		}
		
		@synchronized(handlers) {
			[handlers addObject:[NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithBool:discard], @"discard",
								 [block copy], @"block",
								 nil]];
		}
	}
}
- (void)enumerateEventHandlers:(NSString*)event block:(void(^)(id handler))block {
	NSMutableArray *masterHandlers = [eventHandlers objectForKey:event];
	
	if( masterHandlers ) {
		FBBlockHandler *strongSelf = self; // This is done to ensure we dont get released mid-enumeration
		NSArray *handlers = [masterHandlers copy];
		NSMutableArray *discardHandlers = [NSMutableArray array];
		
		[handlers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSDictionary *handler = (NSDictionary*)obj;
			
			block([handler objectForKey:@"block"]);
			
			if( [[handler objectForKey:@"discard"] boolValue] ) {
				[discardHandlers addObject:handler];
			}
		}];
		
		@synchronized(masterHandlers) {
			[discardHandlers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
				[masterHandlers removeObject:obj];
			}];
		}
		
		strongSelf = nil;
	}
}
- (void)clearEventHandlers:(NSString*)event {
	if( [eventHandlers objectForKey:event] ) {
		[eventHandlers removeObjectForKey:event];
	}
}
- (NSUInteger)eventHandlerCount:(NSString*)event {
	if( [eventHandlers objectForKey:event] ) {
		return [[eventHandlers objectForKey:event] count];
	}
	return 0;
}
- (FBBlockHandler*)blockHandler {
	return self;
}

@end
