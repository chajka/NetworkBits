//
//  HTTPConnection.m
//  Network bits
//
//  Created by Чайка on 3/23/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "HTTPConnection.h"

#define	Percent					CFSTR("%")
#define HeaderFieldAccept		@"Accept"
#define HeaderValueAccept		@"text/html, application/xml, text/xml, */*"
#define HeaderFieldContentType	@"Content-Type"
#define HeaderValueContentType	@"application/x-www-form-urlencoded; charset=UTF-8"
#define HeaderFieldReferer		@"Referer"

static const NSTimeInterval defaultTimeout = 30; // second
static const NSURLRequestCachePolicy defaultCachePolicy = NSURLCacheStorageAllowedInMemoryOnly;

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
		cachePolicy = defaultCachePolicy;
		request = [[NSMutableURLRequest alloc] init];
		[request setCachePolicy:cachePolicy];
		[request setTimeoutInterval:timeout];
		params = [[NSMutableDictionary alloc] init];
	}// end if self
	return self;
}// end - (id) init

- (id) initWithURL:(NSURL *)url andParams:(NSMutableDictionary *)param
{
	self = [super init];
	if (self)
	{
		URL = [url copy];
		path = nil;
		params = [param copy];
		response = nil;
		timeout = defaultTimeout;
		cachePolicy = defaultCachePolicy;
		request = [[NSMutableURLRequest alloc] initWithURL:URL cachePolicy:cachePolicy timeoutInterval:timeout];
	}// end if self
	return self;
}// end - (id) initWithURL:(NSURL *)url_ withParams:(NSDictionary *)param

- (void) dealloc
{
#if !__has_feature(objc_arc)
    if (URL != nil)			[URL release];
	if (path != nil)		[path release];
	if (params != nil)		[params release];
	if (response != nil)	[response release];
	if (request != nil)		[request release];
	[super dealloc];
#endif
}// end - (void) dealloc

- (void) addCustomHeaders:(NSString *)referer
{
	[request setValue:HeaderValueAccept forHTTPHeaderField:HeaderFieldAccept];
	[request setValue:HeaderValueContentType forHTTPHeaderField:HeaderFieldContentType];
	[request setValue:referer forHTTPHeaderField:HeaderFieldReferer];
}// end - (void) addCustomHeaders:(NSString *)referer

#pragma mark - URL’s accessor
- (NSURL *) URL	{ return URL; }// end - (NSURL *) URL
- (void) setURL:(NSURL *)url
{
	if ([URL isEqualTo:url] == YES)
		return;
#if !__has_feature(objc_arc)
	if (URL != nil)			[URL release];
#endif
	URL = [url copy];
	[params removeAllObjects];
	[request setURL:URL];
}// end - (void) setURL:(NSURL *)url

- (void) setURL:(NSURL *)url andParams:(NSDictionary *)param
{
#if !__has_feature(objc_arc)
	if (URL != nil)			[URL release];
#endif
	URL = [url copy];
	[request setURL:URL];
	[params removeAllObjects];
	[params addEntriesFromDictionary:param];
}// end - (void) setURL:(NSURL *)url andParams:(NSDictionary *)param

#pragma mark - Params’s accessor
- (NSDictionary *)params { return params; }// end - (NSDictionary *)params

- (void) setParams:(NSDictionary *)param
{
	[params removeAllObjects];
	[params addEntriesFromDictionary:param];
}// end if

#pragma mark - cache policy
- (NSURLRequestCachePolicy) cachePolicy { return cachePolicy; } // end
- (void) setCachePolicy:(NSURLRequestCachePolicy)newCachePolicy
{
	cachePolicy = newCachePolicy;
	[request setCachePolicy:cachePolicy];
}// end - (void) setCachePolicy:(NSURLRequestCachePolicy)newCachePolicy

#pragma mark - URLRequest

#pragma mark -
#pragma mark instance methods
- (void) clearResponse
{
#if !__has_feature(objc_arc)
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
	if (error != nil)
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

- (NSURLConnection *) connectionBy:(HTTPMethod)method delegate:(id<NSURLConnectionDelegate>)delegate
{
	if (delegate == nil)
		return nil;
	// end if target isn't there, because self cannot become delegator.

	switch (method) {
		case HTTPMethodPOST:
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
			}// end - (NSMutableURLRequest *)requestForGet
			break;
		case HTTPMethodGET:
		default:
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
		}// end - (NSMutableURLRequest *)requestForGet
			break;
	}// end case by HTTPMethod

	NSURLConnection *connection;
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:delegate];
#if !__has_feature(objc_arc)
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
	NSData *httpBody = [message dataUsingEncoding:NSISOLatin1StringEncoding];
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
	if ([params count] == 0)
		return @"";

	NSString *param = nil;
	NSMutableArray *messages = [NSMutableArray array];
	CFStringRef value = NULL;
	CFStringRef escValue = NULL;
	CFStringRef origKey = NULL;
	CFStringRef escKey = NULL;
	CFStringRef invalid = NULL;
	NSString *escapedKey = nil;
	NSString *escapedValue = nil;
	for (NSString *key in [params allKeys])
	{
#if __has_feature(objc_arc)
		value = (__bridge CFStringRef)[params valueForKey:key];
		origKey = (__bridge CFStringRef)key;
#else
		value = (CFStringRef)[params valueForKey:key];
		origKey = (CFStringRef)key;
#endif
		CFRange found;
		found = CFStringFind(origKey, Percent, kCFCompareCaseInsensitive);
		invalid = NULL;
		if (found.location != NSNotFound)
			invalid = Percent;
		escKey = CFURLCreateStringByAddingPercentEscapes(
					 kCFAllocatorDefault, origKey, invalid, NULL, kCFStringEncodingUTF8);
		found = CFStringFind(value, Percent, kCFCompareCaseInsensitive);
		invalid = NULL;
		if (found.location != NSNotFound)
			invalid = Percent;
		escValue = CFURLCreateStringByAddingPercentEscapes(
					 kCFAllocatorDefault, value, invalid, NULL, kCFStringEncodingUTF8);
#if __has_feature(objc_arc)
		escapedKey = (__bridge NSString *)escKey;
		escapedValue = (__bridge NSString *)escValue;
#else
		escapedKey = (NSString *)escKey;
		escapedValue = (NSString *)escValue;
#endif
		[messages addObject:[NSString stringWithFormat:ParamConcatFormat, escapedKey, escapedValue]];
		CFRelease(escKey);
		CFRelease(escValue);
	}// end for
	param = [messages componentsJoinedByString:ParamsConcatSymbol];

	return param;
}// end - (NSString *) buildParam
@end
