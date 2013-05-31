//
//  YCStreamSession.h
//  Network bits
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define ReadStreamError				@"ReadStreamError"
#define WriteStreamError			@"WriteStreamError"
#define ReadStreamSetupError		@"ReadStreamSetupError"
#define WriteStreamSetupError		@"WriteStreamSetupError"

@protocol YCStreamSessionDelegate <NSObject>
@required

- (void) iStreamHasBytesAvailable:(NSInputStream *)iStream;
- (void) iStreamEndEncounted:(NSInputStream *)iStream;

- (void) oStreamCanAcceptBytes:(NSOutputStream *)oStream;
- (void) oStreamEndEncounted:(NSOutputStream *)oStream;
@optional
- (void) iStreamErrorOccured:(NSInputStream *)iStream;
- (void) iStreamOpenCompleted:(NSInputStream *)iStream;
- (void) iStreamCanAcceptBytes:(NSInputStream *)iStream;
- (void) iStreamNone:(NSStream *)iStream;

- (void) oStreamErrorOccured:(NSOutputStream *)oStream;
- (void) oStreamOpenCompleted:(NSOutputStream *)oStream;
- (void) oStreamHasBytesAvailable:(NSOutputStream *)oStream;
- (void) oStreamNone:(NSOutputStream *)oStream;
@end

@interface YCStreamSession : NSObject <YCStreamSessionDelegate> {
		// connection specific variables
	NSString			*serverName;
	int					portNumber;
	BOOL				canConnect;
		// process stream specific variables
	id <YCStreamSessionDelegate> delegate;
		// stream specific variables
	CFReadStreamRef		readStream;
	CFWriteStreamRef	writeStream;
	CFOptionFlags		readStreamOptions;
	CFOptionFlags		writeStreamOptions;
	BOOL				readStreamIsSetuped;
	BOOL				writeStreamIsSetuped;
}
@property (readonly) NSString *serverName;
@property (readonly) int portNumber;
@property (readonly) NSInputStream	*readStream;
@property (readonly) NSOutputStream	*writeStream;
#if __has_feature(objc_arc)
@property (strong, readwrite) id <YCStreamSessionDelegate> delegate;
#else
@property (retain, readwrite) id <YCStreamSessionDelegate> delegate;
#endif
- (id) initWithServerName:(NSString *)server andPort:(int)port;

- (BOOL) checkReadyToConnect;
- (BOOL) connect;
- (void) disconnect;
- (BOOL) reconnectReadStream;
- (void) closeReadStream;
- (BOOL) reconnectWriteStream;
- (void) closeWriteStream;

@end
