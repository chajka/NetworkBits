//
//  HTTPCookieConnection.m
//  Network bits
//
//  Created by Чайка on 8/10/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "HTTPCookieConnection.h"

@implementation HTTPCookieConnection
@synthesize cookies;

#pragma mark class methods
#if __has_feature(objc_arc)
+ (NSString *) HTTPSource:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse * __autoreleasing *)resp
#else
+ (NSString *) HTTPSource:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse **)resp
#endif
{		// create detamine encoding constant array
	NSArray *encodings = [NSArray arrayWithObjects:
						  [NSNumber numberWithUnsignedInt:NSUTF8StringEncoding],
						  [NSNumber numberWithUnsignedInt:NSShiftJISStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSJapaneseEUCStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSISO2022JPStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSUnicodeStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSASCIIStringEncoding], nil];
	
		// check have data
	NSData *receivedData = [self HTTPData:url cookie:cookies response:resp];
	if (receivedData == nil)
		return nil;
	
		// datamine encoding
	NSString *data_str = nil;
	for (NSNumber *enc in encodings)
	{
		data_str = [[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]];
#if ! __has_feature(objc_arc)
		[data_str autorelease];
#endif
		if (data_str!=nil)
			break;
	}// end for each encodings
	return data_str;
}// end + (NSString *) HTTPSource:(NSURL *)url

#if __has_feature(objc_arc)
+ (NSData *) HTTPData:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse * __autoreleasing *)resp
#else
+ (NSData *) HTTPData:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse **)resp
#endif
{
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
	[request setHTTPShouldHandleCookies:NO];
	NSDictionary *dict = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
	[request setAllHTTPHeaderFields:dict];
	NSHTTPURLResponse *response = nil;
	NSError *error = nil;
	
		// check have data
	NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
												 returningResponse:&response error:&error];
	
		// error check
	if ([error code] != noErr)
		return nil;
	else
		return receivedData;
}// end + (NSData *) HTTPData:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse * __autoreleasing *)resp

#pragma mark -
#pragma mark construct/destruct
- (id) init
{
	self = [super init];
	if (self)
	{
		cookies = nil;
	}// end if
	return self;
}// end - (id) init

- (id) initWithURL:(NSURL *)url withParams:(NSDictionary *)param
{
	self = [super initWithURL:url withParams:param];
	if (self)
	{
		cookies = nil;
	}// end if
	return self;
}// end - (id) initWithURL:(NSURL *)url withParams:(NSDictionary *)param

- (id) initWithURL:(NSURL *)url withParams:(NSDictionary *)param andCookies:(NSArray *)cookie
{
	self = [super initWithURL:url withParams:param];
	if (self)
	{
		cookies = [[NSMutableArray alloc] initWithArray:cookie];
		NSDictionary *header = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
		[request setAllHTTPHeaderFields:header];
	}// end if
	return self;
}// end - (id) initWithURL:(NSURL *)url withParams:(NSDictionary *)param andCookies:(NSMutableArray *)cookie

- (void) dealloc
{
#if ! __has_feature(objc_arc)
	if (cookies != nil)		[cookies release];

	[super dealloc];
#endif
}// end - (void) dealloc

#pragma mark -
#pragma mark accessor
- (NSArray *) cookies
{
	return cookies;
}// end - (NSDictionary *) cookies

- (void) setCookies:(NSMutableArray *) cookie
{
#if ! __has_feature(objc_arc)
	if (cookies != nil)		[cookies release];
#endif
	cookies = [[NSMutableArray alloc] initWithArray:cookie];
	NSDictionary *header = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
	[request setAllHTTPHeaderFields:header];
}// end - (void) setCookies:(NSMutableDictionary *) cookie

@end