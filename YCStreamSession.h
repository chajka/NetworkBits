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

@protocol YCStreamSessionDelegate <NSObject>
@required
	// process input stream
- (void) iStreamHasBytesAvailable:(NSInputStream *)iStream;
- (void) iStreamEndEncounted:(NSInputStream *)iStream;
	// process output stream
- (void) oStreamCanAcceptBytes:(NSOutputStream *)oStream;
- (void) oStreamEndEncounted:(NSOutputStream *)oStream;
@optional
	// process common event
	// process for input stream
- (void) iStreamErrorOccured:(NSInputStream *)iStream;
- (void) iStreamOpenCompleted:(NSInputStream *)iStream;
- (void) iStreamCanAcceptBytes:(NSInputStream *)iStream;
- (void) iStreamNone:(NSStream *)iStream;
	// process for output stream
- (void) oStreamErrorOccured:(NSOutputStream *)oStream;
- (void) oStreamOpenCompleted:(NSOutputStream *)oStream;
- (void) oStreamHasBytesAvailable:(NSOutputStream *)oStream;
- (void) oStreamNone:(NSOutputStream *)oStream;
@end

@interface YCStreamSession : NSObject <YCStreamSessionDelegate> {
		// connection specific variables
	NSString						*hostName;
	int								portNumber;
	BOOL							canConnect;
		// process stream specific variables
	id <YCStreamSessionDelegate>	delegate;
		// stream specific variables
	CFReadStreamRef					readStream;
	CFWriteStreamRef				writeStream;
	CFOptionFlags					readStreamOptions;
	CFOptionFlags					writeStreamOptions;
	BOOL							readStreamIsSetuped;
	BOOL							writeStreamIsSetuped;
		// manage connection reachable
	SCNetworkReachabilityRef		hostRef;
		// threading
	NSThread						*targetThread;
}
@property (readonly) NSString		*hostName;
@property (readonly) int			portNumber;
@property (readonly) NSInputStream	*readStream;
@property (readonly) NSOutputStream	*writeStream;
#if __has_feature(objc_arc)
@property (strong, readwrite) id <YCStreamSessionDelegate> delegate;
#else
@property (retain, readwrite) id <YCStreamSessionDelegate> delegate;
#endif

- (id) initWithHostName:(NSString *)host andPort:(int)port;
- (id) initWithHostName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread;

- (BOOL) checkReadyToConnect;
- (BOOL) connect;
- (void) disconnect;
- (BOOL) reconnectReadStream;
- (void) closeReadStream;
- (BOOL) reconnectWriteStream;
- (void) closeWriteStream;

@end
