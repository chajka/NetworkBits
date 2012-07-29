//
//  CFSocketConnection.h
//  
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InputStreamConnectionDelegate <NSObject>
@required
- (void) iStreamHasBytesAvailable:(NSInputStream *)iStream;
- (void) iStreamEndEncounted:(NSInputStream *)iStream;
- (void) iStreamErrorOccured:(NSInputStream *)iStream;
@optional
- (void) iStreamOpenCompleted:(NSInputStream *)iStream;
- (void) iStreamCanAcceptBytes:(NSInputStream *)iStream;
- (void) iStreamNone:(NSStream *)iStream;
@end

@protocol OutputStreamConnectionDelegate <NSObject>
@required
- (void) oStreamCanAcceptBytes:(NSOutputStream *)oStream;
- (void) oStreamEndEncounted:(NSOutputStream *)oStream;
- (void) oStreamErrorOccured:(NSOutputStream *)oStream;
@optional
- (void) oStreamOpenCompleted:(NSOutputStream *)oStream;
- (void) oStreamHasBytesAvailable:(NSOutputStream *)oStream;
- (void) oStreamNone:(NSOutputStream *)oStream;
@end

@interface CFSocketConnection : NSObject <InputStreamConnectionDelegate, OutputStreamConnectionDelegate> {
		// connection specific variables
	NSString *serverName;
	int portNumber;
		// process stream specific variables
	__strong id <InputStreamConnectionDelegate> inputDelegator;
	__strong id <OutputStreamConnectionDelegate> outputDelegator;
}
@property (readonly) NSString *serverName;
@property (readonly) int portNumber;
@property (retain, readwrite) id <InputStreamConnectionDelegate> inputStreamDelegate;
@property (retain, readwrite) id <OutputStreamConnectionDelegate> outputStreamDelegate;

- (id) initWithServerName:(NSString *)server andPort:(int)port;

- (BOOL) connect;
- (void) disconnect;
- (BOOL) readyToConnect;
- (void) closeReadStream;
- (void) closeWriteStream;

@end
