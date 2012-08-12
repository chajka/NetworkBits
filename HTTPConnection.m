//
//  HTTPConnection.m
//  Network bits
//
//  Created by Чайка on 3/23/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "HTTPConnection.h"

const NSTimeInterval defaultTimeout = 30; // second

#pragma mark private methods
@interface HTTPConnection ()
/*!
	@method buildParam
	@abstract clear readonly response object.
	@discussion this method might be call after post/get method.
	because response store last value.
	@result new HTTPConnection object with URL.
*/
- (NSString *) buildParam;

/*!
	@method stringByPost:
	@abstract get contents of URL by string format with posted own parameters.
	@param error result.
	@result new HTTPConnection object with URL.
*/
- (NSData *) post:(NSError **)err;
@end

@implementation HTTPConnection
@synthesize path;
@synthesize params;
@synthesize response;
@synthesize timeout;

#pragma mark class methods
#if __has_feature(objc_arc)
+ (NSString *) HTTPSource:(NSURL *)url response:(NSURLResponse * __autoreleasing *)resp
#else
+ (NSString *) HTTPSource:(NSURL *)url response:(NSURLResponse **)resp
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
	NSData *receivedData = [self HTTPData:url response:resp];
	if (receivedData == nil)
		return nil;

		// datamine encoding
	NSString *data_str = nil;
	for (NSNumber *enc in encodings)
	{
#if __has_feature(objc_arc)
		data_str = [[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]];
#else
		data_str = [[[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]] autorelease];
#endif
		if (data_str!=nil)
			break;
	}// end for each encodings
	return data_str;
}// end + (NSString *) HTTPSource:(NSURL *)url

#if __has_feature(objc_arc)
+ (NSData *) HTTPData:(NSURL *)url response:(NSURLResponse * __autoreleasing *)resp
#else
+ (NSData *) HTTPData:(NSURL *)url response:(NSURLResponse **)resp
#endif
{
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSError *error = nil;
	NSURLResponse *re;
	NSData *receivedData = [NSURLConnection sendSynchronousRequest:request
												 returningResponse:&re
															 error:&error];
	if (resp != nil)
		*resp = re;
	// endif 
	
		// error check
	if ([error code] != noErr)
		return nil;
	else
		return receivedData;
}// end + (NSString *) HTTPSource:(NSURL *)url

#if __has_feature(objc_arc)
+ (NSString *) HTTPStringWithRequest:(NSURLRequest *)req response:(NSURLResponse * __autoreleasing *)resp
#else
+ (NSString *) HTTPStringWithRequest:(NSURLRequest *)req response:(NSURLResponse **)resp
#endif
{
	NSArray *encodings = [NSArray arrayWithObjects:
						  [NSNumber numberWithUnsignedInt:NSUTF8StringEncoding],
						  [NSNumber numberWithUnsignedInt:NSShiftJISStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSJapaneseEUCStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSISO2022JPStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSUnicodeStringEncoding],
						  [NSNumber numberWithUnsignedInt:NSASCIIStringEncoding], nil];
	
		// check have data
	NSData *receivedData = [self HTTPDataWithRequest:req response:resp];
	if (receivedData == nil)
		return nil;
	
		// datamine encoding
	NSString *dataStr = nil;
	for (NSNumber *enc in encodings)
	{
#if __has_feature(objc_arc)
		dataStr = [[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]];
#else
		dataStr = [[[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]] autorelease];
#endif
		if (dataStr!=nil)
			break;
	}// end for each encodings
	return dataStr;
}// end + (NSData *) HTTPDataWithRequest:(NSURLRequest *)req response:(NSURLResponse * __autoreleasing *)resp

#if __has_feature(objc_arc)
+ (NSData *) HTTPDataWithRequest:(NSURLRequest *)req response:(NSURLResponse * __autoreleasing *)resp
#else
+ (NSData *) HTTPDataWithRequest:(NSURLRequest *)req response:(NSURLResponse **)resp
#endif
{
	NSError *error = nil;
	NSURLResponse *re;
	NSData *receivedData = [NSURLConnection sendSynchronousRequest:req
												 returningResponse:&re
															 error:&error];
	if (resp != nil)
		*resp = re;
		// endif 
	
		// error check
	if ([error code] != noErr)
		return nil;
	else
		return receivedData;
}// end + (NSData *) HTTPDataWithRequest:(NSURLRequest *)req response:(NSURLResponse * __autoreleasing *)resp

#pragma mark -
#pragma mark construct/destruct
- (id) init
{
	self = [super init];
	if (self)
	{
		URL = nil;
		path = nil;
		params = nil;
		response = nil;
		timeout = defaultTimeout;
		request = [[NSMutableURLRequest alloc] init];
		[request setCachePolicy:NSURLCacheStorageAllowedInMemoryOnly];
		[request setTimeoutInterval:timeout];
	}// end if self
	return self;
}// end - (id) init

- (id) initWithURL:(NSURL *)url withParams:(NSDictionary *)param
{
	self = [super init];
	if (self)
	{
		URL = [url copy];
		path = nil;
		params = [param copy];
		response = nil;
		timeout = defaultTimeout;
		request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:NSURLCacheStorageAllowedInMemoryOnly timeoutInterval:timeout];
	}// end if self
	return self;
}// end - (id) initWithURL:(NSURL *)url_ withParams:(NSDictionary *)param

- (void) dealloc
{
#if ! __has_feature(objc_arc)
    if (URL != nil)			[URL release];
	if (path != nil)		[path release];
	if (params != nil)		[params release];
	if (response != nil)	[response release];
	if (request != nil)		[request release];
	[super dealloc];
#endif
}// end - (void) dealloc

#pragma mark -
#pragma mark URL’s accessor
- (NSURL *) URL
{
	return URL;
}// end - (NSURL *) URL

- (void) setURL:(NSURL *)url
{
#if ! __has_feature(objc_arc)
	if (URL != nil)			[URL release];
#endif
	URL = [url copy];
	[request setURL:URL];
}// end - (void) setURL:(NSURL *)url

#pragma mark -
#pragma mark instance methods
- (void) clearResponse
{
#if ! __has_feature(objc_arc)
	[response autorelease];
#endif
	response = nil;
}// end - (void) clearResponse

- (NSString *) stringByGet
{
	NSURL *queryURL = nil;
	NSString *queryURLString = [NSString stringWithString:[URL absoluteString]];
	if (params != nil)
		queryURLString = [[URL absoluteString] stringByAppendingString:
						  [QueryConcatSymbol stringByAppendingString:[self buildParam]]];
	// end if have param
	queryURL = [NSURL URLWithString:queryURLString];
	[request setURL:queryURL];
	[request setHTTPMethod:RequestMethodGet];
	NSURLResponse *resp = nil;
	NSString *dataStr = [HTTPConnection HTTPStringWithRequest:request response:&resp];
	response = [resp copy];
	[request setURL:URL];
	return dataStr;
}// end - (NSString *) stringByGet

- (NSData *) dataByGet
{
	NSURL *queryURL = nil;
	NSString *queryURLString = [NSString stringWithString:[URL absoluteString]];
	if (params != nil)
		queryURLString = [[URL absoluteString] stringByAppendingString:
						  [QueryConcatSymbol stringByAppendingString:[self buildParam]]];
	// end if have param
	queryURL = [NSURL URLWithString:queryURLString];
	[request setURL:queryURL];
	[request setHTTPMethod:RequestMethodGet];
	NSURLResponse *resp = nil;
	NSData *data = [HTTPConnection HTTPDataWithRequest:request response:&resp];
	response = [resp copy];
	[request setURL:URL];
	return data;
}// end - (NSData *) dataByGet

#if __has_feature(objc_arc)
- (NSString *) stringByPost:(NSError * __autoreleasing *)error
#else
- (NSString *) stringByPost:(NSError **)error
#endif
{
	NSData *receivedData = [self post:error];
	if ([*error code] != noErr)
		return nil;
		// create detamine encoding constant array 
	NSArray *encodings = [NSArray arrayWithObjects:
						  [NSNumber numberWithUnsignedInt:NSUTF8StringEncoding],
						  [NSNumber numberWithUnsignedInt:NSShiftJISStringEncoding], 
						  [NSNumber numberWithUnsignedInt:NSJapaneseEUCStringEncoding], 
						  [NSNumber numberWithUnsignedInt:NSISO2022JPStringEncoding], 
						  [NSNumber numberWithUnsignedInt:NSUnicodeStringEncoding], 
						  [NSNumber numberWithUnsignedInt:NSASCIIStringEncoding], nil];

	// datamine encoding
	NSString *data_str = nil;
	for (NSNumber *enc in encodings)
	{
#if __has_feature(objc_arc)
		data_str = [[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]];
#else
		data_str = [[[NSString alloc] initWithData:receivedData encoding:[enc unsignedIntValue]] autorelease];
#endif
		if (data_str!=nil)
			break;
	}// end for each encodings

	return data_str;
}// end - (NSString *) stringByPost:(NSError **)error

#if __has_feature(objc_arc)
- (NSData *) dataByPost:(NSError * __autoreleasing *)error
#else
- (NSData *) dataByPost:(NSError **)error
#endif
{
	NSData *data = nil;
	NSError *err = nil;
	data = [self post:&err];
	if (error != nil)
		*error = err;

	return data;
}// end - (NSData *) dataByPost:(NSError **)error

- (NSURLConnection *) httpDataAsyncByDelegate:(id)target
{
	if (target == nil)
		return nil;
	// end if target isn't there, because self cannot become delegator.

	NSURLConnection *connection;
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:target];
#if ! __has_feature(objc_arc)
	[connection autorelease];
#endif
	
	return connection;
}// end - (NSURLConnection *) httpDataAsync:(NSURL *)url delegate:(id)target

#pragma mark private methods
#if __has_feature(objc_arc)
- (NSData*) post:(NSError * __autoreleasing *)err;
#else
- (NSData*) post:(NSError **)err;
#endif
{
		// create psot body
	NSString *message = [self buildParam];
	NSURLResponse *resp = nil;
	NSData *httpBody = [message dataUsingEncoding:NSUTF8StringEncoding];
	[request setHTTPMethod:RequestMethodPost];
	[request setHTTPBody:httpBody];
	NSError *error = nil;
	NSData* result = [NSURLConnection sendSynchronousRequest:request
										   returningResponse:&resp
													   error:&error];
	response = [resp copy];
	[request setHTTPBody:nil];
	if (err != nil)
		*err = error;
	if ([error code] != noErr)
		return nil;
	else
		return result;
}// end - (NSData*) post

- (NSString *) buildParam
{
	NSString *param = nil;
	NSMutableArray *messages = [NSMutableArray array];
	for (NSString *key in [params allKeys])
	{
		[messages addObject:[NSString stringWithFormat:ParamConcatFormat, key, [params objectForKey:key]]];
	}// end for
	param = [[messages componentsJoinedByString:ParamsConcatSymbol]
			  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

	return param;
}// end - (NSString *) buildParam
@end
