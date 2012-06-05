#Facebook iOS SDK [OverTheAir2012 REMIX]

Product of the OverTheAir 2012 Hack. The task was to rewrite the Facebook iOS client SDK into something that helped more than it hindered.

Since the initial hack, there has been a number of cleanups and sanity checks to ensure it is doing the right thing.

If you have any questions, feedback or issues - please use the issue tracker.

If you want to issue a pull request to fix/clean/add that would be great.

###PLEASE NOTE, this is not an official SDK so don't bug Facebook for support. If you've issues then please use the github issue tracker - thanks!

##OverTheAir: Changes:

 - Runs on iOS5 only with ARC support for better memory management
 - Massive cleanup of API naming convention to be a better iOS citizen and be more consistent to the developer e.g.:

    	- (FBRequest*)requestWithMethodName:(NSString *)methodName
                             parameters:(NSDictionary *)params
                          requestMethod:(NSString *)httpMethod
                               finalize:(void(^)(FBRequest*request))finalize;
                               
 - Removed SBJSON to use the iOS native NSJSONSerialization methods
 - Swapped the delegate patterns to be a flexible block based API system resulting in less verbosity and better code locality (removes a big requirement on object globals to track requests in user code).

    	[[Facebook shared] requestWithGraphPath:@"me/permissions"
                      finalize:^(FBRequest *request) {
                          [request addCompletionHandler:^(FBRequest *request, id result) {
                              _permissions = [NSSet setWithArray:[[[result objectForKey:@"data"] objectAtIndex:0] allKeys]];
                              NSLog(@"Permissions: %@", self.permissions);
                          }];
                      }];

 - Automatic storage of the session tokens and expiration date to NSUserDefaults to a key that will not collide
 - Flag to automatically refresh the token, if needed, on application launch without user code (turned on by default)
 - Removed various class instance variables where property exists to remove duplication
 - Made the Facebook object a singleton object to reduce complexity:

		[Facebook shared]
		[Facebook bind]
    
 - Added quality of life change requestStarted and requestFinished block that will fire once for each request start and finish (whether error or not). Useful for UI setup and teardown like progress or wait views, or enabling request debug handlers.
 - Added validation of URL schemes to the backend as it is required for successful authentication
 - Added persistent tracking of the permissions the client and helpers to make requesting new permission access and then running operations against it trivial:

		[[Facebook shared] usingPermissions:[NSArray arrayWithObject:@"user_photos"] 
                                request:^{
                                    [[Facebook shared] albums:^(NSArray *albums) {
                                        ...
                                    } error:nil]];
                                }];
                                
   This is probably the most insanely great feature of the dub remix. We keep the permissions and the code that uses it together. If we don't need to authenticate the permissions, we wont. If we do, we will. Either way we end up with much cleaner code.
 - API to make common tasks easier and less error prone - `Facebook+Graph.h`
 - Intelligent automatic binding to a Facebook AppID based upon the URL scheme within the application

##OverTheAir: Getting Started:

 - Setup your application in facebook as per normal with single sign on
 - Make sure you have setup your URL handler with the scheme `fb`APPID as this is used not only on sign on but also to automatically bind the Facebook singleton object to your APPID
 - If you do not wish to implement the URL handlers in the app delegate, then include `FBConnect.h` in your app delegate's header file and change the parent class from `UIResponder` to `FBAppDelegate`
 - Now you just need to access facebook how you want to using the `[Facebook shared]` accessor.
 
If you want examples on how to use the new API, take a look at the `Facebook+Graph.m` code. There you will find how:

 - to use the finalize block to setup blocks on `FBRequest`
 - to configure permissions using the `usingPermission:request:` call on `Facebook` to easily elevate permissions
 - many examples on how to use the `request...` calls
 
If you have a look in the Hackbook and SmallHackbook example apps you will also find many examples on how the API is used.

##OverTheAir: Plans

This is currently our best estimate on how we want the Facebook client SDK to work and think it is pretty great. 

The aim is to polish and refine the core API code but we think the API interface is pretty much solid so you can start using it. There are also plans to expand more of `Facebook+Graph.m` to abstract out the need to ask for permissions and write requests for common Facebook tasks (along with some stubs to group a list of permissions together to allow the app to request a group of them).

We chatted a lot with Facebook at OverTheAir and they liked what we did and we are hoping that as many of the changes make their way in the official SDK.

Stay tuned.

##OverTheAir: Authors:

 - Chris Ross @darkrock (@hiddenmemory, hiddenmemory on github)
 - Kieran Gutteridge @kgutteridge 

Special mention to Daniel Tull @danielctull and @chrisbanes

#About:

This open source iOS library allows you to integrate Facebook into your iOS application include iPhone, iPad and iPod touch.

Except as otherwise noted, the Facebook iOS SDK is licensed under the Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0.html)

#Getting Started

See our [iOS Tutorial](https://developers.facebook.com/docs/guides/mobile/ios/) for a tutorial to get you up and running.

See our [iOS SDK Reference](https://developers.facebook.com/docs/reference/iossdk/) for more information on the SDK methods and protocols.

Please note: with the large OverTheAir changes made to the codebase, a lot of the instruction has been made redundant, for quick guidelines please refer to the `OverTheAir: Getting Started:` above.

#Sample Applications

This SDK comes with a couple of applications that demonstrates authorization, making API calls, and invoking a dialog, to guide you in development.

 - Hackbook is the large application that does most of the magic. Take a look in `APICallsViewController.m` and specifically the methods prefixed with `api` for the magic.
 - SmallHackbook is an example of the smallest application you could write and demonstrates how little code you need to write to get going.

To build and run the sample application with Xcode:

* Open the included Xcode Project File by selecting _File_->_Open..._ and selecting sample/Hackbook/Hackbook.xcodeproj.

* Verify your compiler settings by checking the menu items under _Project_->_Set Active SDK_ and _Project_->_Set Active Executable_. For most developers, the defaults should be OK. Note that if you compile against a version of the iOS SDK that does not support multitasking, not all features of the Facebook SDK may be available. See the "Debugging" section below for more information.

* Finally, select _Build_->_Build and Run_. This should compile the application and launch it.

#Debugging

Common problems and solutions:

* What version of the iOS SDK must I compile my application against to use single sign-on?

This SDK now works on iOS 5.0 or above.

* What version of the Facebook Application must a user have installed to use single sign-on?

The Facebook Application version 3.2.3 or higher will support single sign-on. Users with older versions will gracefully fall back to inline dialog-based authorization.

* During single sign-on, the Facebook application isn't redirecting back to my application after a user authorizes it. What's wrong?

Make sure you've edited your application's .plist file properly, so that your applicaition binds to the fb\[appId\]:// URL scheme (where "\[appId\]" is your Facebook application ID).

* After upgrading to Xcode 4 the sample app will not build and I get the following error: [BEROR]No architectures to compile for (ARCHS=i386, VALID_ARCHS=armv7 armv6). What should I do?

Edit your build settings and add i386 to the list of valid architectures for the app. Click the project icon in the project navigator, select the Hackbook project, Build Settings tab, Architecture section, Valid Architectures option. Then click the grey arrow to expand, and double-click on right of Debug. After "armv6 armv7" add "i386".

Report Issues/Bugs
===============
[Bugs](https://github.com/hiddenmemory/facebook-ios-sdk/issues)

[Questions](https://github.com/hiddenmemory/facebook-ios-sdk/issue)

#Usage

If you use this SDK in one of your apps - please let us know - we are planning on compiling a list and adding it here.