//
//  HTTPConnection.h
//  Network bits
//
//  Created by Чайка on 3/23/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import <Foundation/Foundation.h>
#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_5
@protocol NSURLConnectionDelegate <NSObject>
@end
#endif

typedef NSUInteger HTTPMethod;
enum HTTPMethod {
	HTTPMethodGET,
	HTTPMethodPOST
};

@interface HTTPConnection : NSObject {
@protected
	NSURL						*URL;
	NSString					*path;
	NSMutableDictionary			*params;
	NSURLResponse				*response;
	NSURLRequestCachePolicy		cachePolicy;
	NSTimeInterval				timeout;
	NSMutableURLRequest			*request;
}
@property (copy, readwrite) NSURL						*URL;
@property (copy, readwrite) NSString					*path;
@property (copy, readwrite) NSMutableDictionary			*params;
@property (readonly) NSURLResponse						*response;
@property (assign, readwrite) NSURLRequestCachePolicy	cachePolicy;
@property (assign, readwrite) NSTimeInterval			timeout;
	// class method
/*!
	@method HTTPSource:
	@abstract Return contents of requested URL by NSString.
	@param URL of request.
	@param resoponse from server.
	@result html data by string format.
*/
#if __has_feature(objc_arc)
+ (NSString *) HTTPSource:(NSURL *)url response:(NSURLResponse * __autoreleasing *)resp;
#else
+ (NSString *) HTTPSource:(NSURL *)url response:(NSURLResponse **)resp;
#endif

/*!
	@method HTTPData:response:
	@abstract Return contents of requested URL by NSData.
	@param URL of request.
	@param resoponse from server.
	@result html data by binary format.
 */
#if __has_feature(objc_arc)
+ (NSData *) HTTPData:(NSURL *)url response:(NSURLResponse * __autoreleasing *)resp;
#else
+ (NSData *) HTTPData:(NSURL *)url response:(NSURLResponse **)resp;
#endif

/*!
	@method HTTPDataWithRequest:response:
	@abstract Return contents of requested URL by NSData.
	@param NSURLRequest object.
	@param resoponse from server.
	@result html data by binary format.
*/
#if __has_feature(objc_arc)
+ (NSString *) HTTPStringWithRequest:(NSURLRequest *)req response:(NSURLResponse * __autoreleasing *)resp;
#else
+ (NSString *) HTTPStringWithRequest:(NSURLRequest *)req response:(NSURLResponse **)resp;
#endif

/*!
	@method HTTPDataWithRequest:response:
	@abstract Return contents of requested URL by NSData.
	@param NSURLRequest object.
	@param resoponse from server.
	@result html data by binary format.
*/
#if __has_feature(objc_arc)
+ (NSData *) HTTPDataWithRequest:(NSURLRequest *)req response:(NSURLResponse * __autoreleasing *)resp;
#else
+ (NSData *) HTTPDataWithRequest:(NSURLRequest *)req response:(NSURLResponse **)resp;
#endif

	// constructor
/*!
	@method init
	@abstract create HTTPConnection object and clear all member variable.
	@result new clean HTTPConnection object.
*/
- (id) init;

/*!
	@method initWithURL:withParams:
	@abstract create HTTPConnection object with URL and query paramerters.
	@param URL of access this object.
	@param query parameters by key-value pair dictionary or nil.
	@result new HTTPConnection object with URL. 
*/
- (id) initWithURL:(NSURL *)url andParams:(NSDictionary *)param;
	// instance methods
/*!
*/
- (void) addCustomHeaders:(NSString *)referer;
/*!
	@method clearResponse
	@abstract clear readonly response object.
	@discussion this method might be call after post/get method.
	because response store last value.
*/
- (void) clearResponse;

/*!
	@method setURL:andParams
	@abstract set URL and it’s paramater at single method
	@param request URL to access
	@param key-value pair of params to requested URL
*/
- (void) setURL:(NSURL *)URL andParams:(NSDictionary *)params;

/*!
	@method stringByGet
	@abstract get contents of URL by string format with own parameters.
*/
- (NSString *) stringByGet;

/*!
	@method dataByGet
	@abstract get contents of URL by binary format with own parameters.
 */
- (NSData *) dataByGet;

/*!
	@method stringByPost:
	@abstract get contents of URL by string format with posted own parameters.
	@param error result.
 */
#if __has_feature(objc_arc)
- (NSString *) stringByPost:(NSError * __autoreleasing *)error;
#else
- (NSString *) stringByPost:(NSError **)error;
#endif

/*!
	@method dataByPost:
	@abstract get contents of URL by binary format with posted own parameters.
	@param error result.
*/
#if __has_feature(objc_arc)
- (NSData *) dataByPost:(NSError * __autoreleasing *)error;
#else
- (NSData *) dataByPost:(NSError **)error;
#endif

/*!
	@method connectionForDelegate:
	@abstract return NSURLConnection object for async data transfer.
	@param HTTPMethod HTTPMethodGET is GET, HTTPMethodPOST is POST
	@param delegate object for data recieve. if nil, it dosen’t work.
	@result NSURLConnection object of this connection;
*/
- (NSURLConnection *) connectionBy:(HTTPMethod)method delegate:(id<NSURLConnectionDelegate>)delegate;

	// for HTTP connection method literal
#define RequestMethodPost	@"POST"
#define RequestMethodGet	@"GET"
	//	for creating query literal
#define ParamConcatFormat	@"%@=%@"
#define ParamsConcatSymbol	@"&"
#define QueryConcatSymbol	@"?"

@end
