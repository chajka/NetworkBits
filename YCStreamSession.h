//
//  YCStreamSession.h
//  Network bits
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SystemConfiguration/SystemConfiguration.h>

#define ReadStreamError				@"ReadStreamError"
#define WriteStreamError			@"WriteStreamError"
#define ReadStreamSetupError		@"ReadStreamSetupError"
#define WriteStreamSetupError		@"WriteStreamSetupError"

@class YCStreamSession;
@protocol YCStreamSessionDelegate <NSObject>
@required
	// process common event
- (void) streamReadyToConnect:(YCStreamSession *)session reachable:(BOOL)reachable;
	// process input stream
- (void) readStreamHasBytesAvailable:(NSInputStream *)stream;
- (void) readStreamEndEncounted:(NSInputStream *)stream;
	// process output stream
- (void) writeStreamCanAcceptBytes:(NSOutputStream *)stream;
- (void) writeStreamEndEncounted:(NSOutputStream *)stream;
@optional
	// process common event
- (void) streamIsDisconnected:(YCStreamSession *)session stream:(NSStream *)stream;
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

typedef NSUInteger YCStreamDirection;
enum YCStreamDirection {
	YCStreamDirectionReadable = 1 << 0,
	YCStreamDirectionWriteable = 1 << 1,
	YCStreamDirectionBoth = YCStreamDirectionReadable | YCStreamDirectionWriteable
};

@interface YCStreamSession : NSObject <YCStreamSessionDelegate> {
		// connection specific variables
	NSString						*hostName;
	int								portNumber;
	BOOL							canConnect;
	YCStreamDirection				direction;
		// process stream specific variables
	id <YCStreamSessionDelegate>	delegate;
		// stream specific variables
	CFReadStreamRef					readStream;
	CFOptionFlags					readStreamOptions;
	BOOL							readStreamIsSetuped;
	BOOL							readStreamIsScheduled;
	BOOL							mustHandleReadStreamError;
	CFWriteStreamRef				writeStream;
	CFOptionFlags					writeStreamOptions;
	BOOL							writeStreamIsSetuped;
	BOOL							writeStreamIsScheduled;
	BOOL							mustHandleWriteStreamError;
		// manage connection reachable
	BOOL							reachabilityValidating;
	SCNetworkReachabilityRef		reachabilityHostRef;
	NSTimeInterval					timeout;
		// threading
	NSThread						*targetThread;
}
@property (readonly) NSString		*hostName;
@property (readonly) int			portNumber;
@property (assign, readwrite) YCStreamDirection direction;
@property (readonly) NSInputStream	*readStream;
@property (readonly) NSOutputStream	*writeStream;
#if __has_feature(objc_arc)
@property (strong, readwrite) id <YCStreamSessionDelegate> delegate;
#else
@property (retain, readwrite) id <YCStreamSessionDelegate> delegate;
#endif
@property (assign, readwrite) NSTimeInterval timeout;

- (id) initWithHostName:(NSString *)host andPort:(int)port;
- (id) initWithHostName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread;

	// connection
- (void) checkReadyToConnect;
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
