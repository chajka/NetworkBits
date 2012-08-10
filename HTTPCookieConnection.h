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
	NSMutableArray *cookies;
}
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

@end
