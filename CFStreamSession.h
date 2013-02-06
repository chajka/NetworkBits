//
//  CFStreamSession.h
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

@protocol InputStreamSessionDelegate <NSObject>
@required
- (void) iStreamHasBytesAvailable:(NSInputStream *)iStream;
- (void) iStreamEndEncounted:(NSInputStream *)iStream;
- (void) iStreamErrorOccured:(NSInputStream *)iStream;
@optional
- (void) iStreamOpenCompleted:(NSInputStream *)iStream;
- (void) iStreamCanAcceptBytes:(NSInputStream *)iStream;
- (void) iStreamNone:(NSStream *)iStream;
@end

@protocol OutputStreamSessionDelegate <NSObject>
@required
- (void) oStreamCanAcceptBytes:(NSOutputStream *)oStream;
- (void) oStreamEndEncounted:(NSOutputStream *)oStream;
- (void) oStreamErrorOccured:(NSOutputStream *)oStream;
@optional
- (void) oStreamOpenCompleted:(NSOutputStream *)oStream;
- (void) oStreamHasBytesAvailable:(NSOutputStream *)oStream;
- (void) oStreamNone:(NSOutputStream *)oStream;
@end

@interface CFStreamSession : NSObject <InputStreamSessionDelegate, OutputStreamSessionDelegate> {
		// connection specific variables
	NSString			*serverName;
	int					portNumber;
	BOOL				canConnect;
		// process stream specific variables
	__strong id <InputStreamSessionDelegate> inputDelegator;
	__strong id <OutputStreamSessionDelegate> outputDelegator;
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
@property (retain, readwrite) id <InputStreamSessionDelegate> inputStreamDelegate;
@property (retain, readwrite) id <OutputStreamSessionDelegate> outputStreamDelegate;

- (id) initWithServerName:(NSString *)server andPort:(int)port;

- (BOOL) checkReadyToConnect;
- (BOOL) connect;
- (void) disconnect;
- (BOOL) reconnectReadStream;
- (void) closeReadStream;
- (BOOL) reconnectWriteStream;
- (void) closeWriteStream;

@end
