//
//  CFStreamConnection.h
//  
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol InputStreamConnectionDelegate <NSObject>
@required
- (void) iStreamHasBytesAvailable:(NSInputStream *)iStream;
- (void) iStreamEndEncounted:(NSStream *)iStream;
- (void) iStreamErrorOccured:(NSInputStream *)iStream;
@optional
- (void) iStreamOpenCompleted:(NSInputStream *)iStream;
- (void) iStreamCanAcceptBytes:(NSInputStream *)iStream;
- (void) iStreamNone:(NSStream *)iStream;
@end

@protocol OutputStreamConnectionDelegate <NSObject>
- (void) oStreamCanAcceptBytes:(NSInputStream *)oStream;
- (void) oStreamEndEncounted:(NSStream *)oStream;
- (void) oStreamErrorOccured:(NSInputStream *)oStream;
@optional
- (void) oStreamOpenCompleted:(NSInputStream *)oStream;
- (void) oStreamHasBytesAvailable:(NSInputStream *)oStream;
- (void) oStreamNone:(NSStream *)oStream;
@end

@interface CFStreamConnection : NSObject <InputStreamConnectionDelegate, OutputStreamConnectionDelegate> {
		// connection specific variables
	NSString *serverName;
	NSUInteger portNumber;
		// process stream specific variables
	__strong id <InputStreamConnectionDelegate> inputDelegator;
	__strong id <OutputStreamConnectionDelegate> outputDelegator;
		// input stream delegate flags
	BOOL haveIStreamEventOpenCompleted;
	BOOL haveIStreamEventHasBytesAvailable;
	BOOL haveIStreamEventCanAcceptBytes;
	BOOL haveIStreamEventErrorOccurred;
	BOOL haveIStreamEventEndEncountered;
	BOOL haveIStreamEventNone;
		// output stream delegate flags
	BOOL haveOStreamEventOpenCompleted;
	BOOL haveOStreamEventHasBytesAvailable;
	BOOL haveOStreamEventCanAcceptBytes;
	BOOL haveOStreamEventErrorOccurred;
	BOOL haveOStreamEventEndEncountered;
	BOOL haveOStreamEventNone;
}
@property (readonly) NSString *serverName;
@property (readonly) NSUInteger portNumber;
@property (retain, readwrite) id <InputStreamConnectionDelegate> inputStreamDelegate;
@property (retain, readwrite) id <OutputStreamConnectionDelegate> outputStreamDelegate;

@end
