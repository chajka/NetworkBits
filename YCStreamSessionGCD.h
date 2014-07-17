//
//  YCStreamSessionGCD.h
//  NicoLiveAlert
//
//  Created by Чайка on 7/14/14.
//  Copyright (c) 2014 Instrumentality of mankind. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <dispatch/dispatch.h>

extern const NSString *ReadStreamError;
extern const NSString *WriteStreamError;
extern const NSString *ReadStreamSetupError;
extern const NSString *WriteStreamSetupError;

extern NSString *keySelf;
extern NSString *keyDelegate;

typedef void(^ReachableHandler)(void);

@class YCStreamSessionGCD;
@protocol YCStreamSessionGCDDelegate <NSObject>
@required
	// process common event
- (void) streamReadyToConnect:(YCStreamSessionGCD *)session reachable:(BOOL)reachable;
	// process input stream
- (void) readStreamHasBytesAvailable:(NSInputStream *)stream;
- (void) readStreamEndEncounted:(NSInputStream *)stream;
	// process output stream
- (void) writeStreamCanAcceptBytes:(NSOutputStream *)stream;
- (void) writeStreamEndEncounted:(NSOutputStream *)stream;
@optional
	// process common event
- (void) streamIsDisconnected:(YCStreamSessionGCD *)session stream:(NSStream *)stream;
	// process for input stream
- (void) readStreamErrorOccured:(NSInputStream *)stream;
- (void) readStreamOpenCompleted:(NSInputStream *)stream;
- (void) readStreamCanAcceptBytes:(NSInputStream *)readStream;
- (void) readStreamNone:(NSStream *)readStream;
	// process for output stream
- (void) writeStreamErrorOccured:(NSOutputStream *)stream;
- (void) writeStreamOpenCompleted:(NSOutputStream *)stream;
- (void) writeStreamHasBytesAvailable:(NSOutputStream *)stream;
- (void) writeStreamNone:(NSOutputStream *)stream;
@end

typedef enum : NSUInteger {
	YCStreamDirectionReadable = 1 << 0,
	YCStreamDirectionWriteable = 1 << 1,
	YCStreamDirectionBoth = YCStreamDirectionReadable | YCStreamDirectionWriteable
} YCStreamDirection;


@interface YCStreamSessionGCD : NSObject <YCStreamSessionGCDDelegate> {
		// connection specific variables
	NSString									*hostName;
	int											portNumber;
	BOOL										canConnect;
	YCStreamDirection							direction;
		// process stream specific variables
	id <YCStreamSessionGCDDelegate>				delegate;
	NSDictionary								*delegateInfo;
		// stream specific variables
	CFReadStreamRef								readStream;
	CFOptionFlags								readStreamOptions;
	BOOL										readStreamIsSetuped;
	BOOL										readStreamIsScheduled;
	BOOL										mustHandleReadStreamError;
	CFWriteStreamRef							writeStream;
	CFOptionFlags								writeStreamOptions;
	BOOL										writeStreamIsSetuped;
	BOOL										writeStreamIsScheduled;
	BOOL										mustHandleWriteStreamError;
		// manage connection reachable
	BOOL										reachabilityValidating;
	SCNetworkReachabilityRef					reachabilityHostRef;
	NSTimeInterval								timeout;
		// threading
	dispatch_queue_t							sessionQueue;
}
@property (readonly) NSString					*hostName;
@property (readonly) int						portNumber;
@property (assign, readwrite) YCStreamDirection	direction;
@property (readonly) NSInputStream				*readStream;
@property (readonly) NSOutputStream				*writeStream;
#if __has_feature(objc_arc)
@property (strong, readwrite) id <YCStreamSessionGCDDelegate> delegate;
#else
@property (retain, readwrite) id <YCStreamSessionGCDDelegate> delegate;
#endif
@property (readonly) BOOL						reachabilityValidating;
@property (assign, readwrite) NSTimeInterval	timeout;

- (id) initWithHostName:(NSString *)host andPort:(int)port;

	// connection
- (void) checkReadyToConnect;
- (void) checkReadyToConnect:(ReachableHandler)handler;
- (BOOL) connect;
	// read stream control
- (BOOL) reconnectReadStream;
- (void) closeReadStream;
	// write stream control
- (BOOL) reconnectWriteStream;
- (void) closeWriteStream;
	// stop session
- (void) disconnect;
- (void) terminate;
@end
