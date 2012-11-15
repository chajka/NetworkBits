//
//  HTTPCookieConnection.h
//  Network bits
//
//  Created by Чайка on 8/10/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "HTTPConnection.h"

@interface HTTPCookieConnection : HTTPConnection {
@protected
	NSMutableArray	*cookies;
	NSString		*query;
}
@property (copy, readwrite) NSMutableArray	*cookies;
@property (copy, readwrite) NSString		*query;
	// class method
/*!
	@method HTTPData:response:
	@abstract Return contents of requested URL by NSData.
	@param URL of request.
	@param resoponse from server.
	@param cookie for server
	@result html data by binary format.
*/
#if __has_feature(objc_arc)
+ (NSString *) HTTPSource:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse * __autoreleasing *)resp;
#else
+ (NSString *) HTTPSource:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse **)resp;
#endif

/*!
	@method HTTPData:response:
	@abstract Return contents of requested URL by NSData.
	@param URL of request.
	@param cookie for server
	@param resoponse from server.
	@result html data by binary format.
*/
#if __has_feature(objc_arc)
+ (NSData *) HTTPData:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse * __autoreleasing *)resp;
#else
+ (NSData *) HTTPData:(NSURL *)url cookie:(NSMutableArray *)cookies response:(NSURLResponse **)resp;
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

/*!
	@method initWithURL:withParams:
	@abstract create HTTPConnection object with URL and query paramerters.
	@param URL of access this object.
	@param query parameters by key-value pair dictionary or nil.
	@param cookies for this connection.
	@result new HTTPConnection object with URL.
*/
- (id) initWithURL:(NSURL *)url andParams:(NSDictionary *)param andCookies:(NSMutableArray *)cookie;

/*
	@method initWithDomain:
	@abstract create HTTPConnection object for domain.
	@param domain path of cookie.
	@result new HTTPConnection object with cookie.
*/
- (id) initWithDomain:(NSString *)domain;
@end
