//
//  FBBlockHandler.h
//  facebook-ios-sdk
//
//  Created by Chris Ross on 03/06/2012.
//  Copyright (c) 2012 hiddenMemory Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FBBlockHandler;

@protocol FBBlockProvider <NSObject>

- (FBBlockHandler*)blockHandler;

@end

@interface FBBlockHandler : NSObject <FBBlockProvider>

- (void)registerEventHandler:(NSString*)event handler:(id)block;
- (void)registerEventHandler:(NSString*)event discard:(BOOL)discard handler:(id)block;
- (void)enumerateEventHandlers:(NSString*)event block:(void(^)(id _handler))block;
- (NSUInteger)eventHandlerCount:(NSString*)event;
- (void)clearEventHandlers:(NSString*)event;

@end
