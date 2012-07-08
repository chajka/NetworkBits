//
//  CFSocketConnection.m
//  
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "CFSocketConnection.h"

@interface CFStreamConnection (private)

@end

@implementation CFStreamConnection
@synthesize serverName;
@synthesize portNumber;
#pragma mark construct / destruct
- (id) initWithServerName:(NSString *)server andPort:(NSUInteger)port
{
	self = [super init];
	if (self)
	{
		serverName = [server copy];
		portNumber = port;
		inputDelegator = self;
		outputDelegator = self;
			// input stream delegate flags
		haveIStreamEventOpenCompleted = NO;
		haveIStreamEventHasBytesAvailable = NO;
		haveIStreamEventCanAcceptBytes = NO;
		haveIStreamEventErrorOccurred = NO;
		haveIStreamEventEndEncountered = NO;
		haveIStreamEventNone = NO;
			// output stream delegate flags
		haveOStreamEventOpenCompleted = NO;
		haveOStreamEventHasBytesAvailable = NO;
		haveOStreamEventCanAcceptBytes = NO;
		haveOStreamEventErrorOccurred = NO;
		haveOStreamEventEndEncountered = NO;
		haveOStreamEventNone = NO;
	}// end if self can allocate

	return self;
}// end - (id) initWithServerName:(NSString *)server andPort:(NSUInteger)port

- (void) dealloc
{
#if __has_feature(objc_arc) == 0
	if ((inputDelegator != self) || (inputDelegator != nil))
		[inputDelegator release];
	if ((outputDelegator != self) || (inputDelegator != nil))
		[outputDelegator release];
#endif
	inputDelegator = nil;
	outputDelegator = nil;
#if __has_feature(objc_arc) == 0
	[super dealloc];
#endif
}

#pragma mark -
#pragma mark delegator process methods
- (id <InputStreamConnectionDelegate>) inputStreamDelegate
{
	return inputDelegator;
}// end nputStreamDelegate

- (void) setInputStreamDelegate:(id <InputStreamConnectionDelegate>)delegate
{		// set delegate
	inputDelegator = delegate;
#if __has_feature(objc_arc) == 0
	[inputDelegator retain];
#endif
		// check have method
	if ([inputDelegator respondsToSelector:@selector(iStreamEventOpenCompleted:)] == YES)
		haveIStreamEventOpenCompleted = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamHasBytesAvailable:)] == YES)
		haveIStreamEventHasBytesAvailable = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamCanAcceptBytes:)] == YES)
		haveIStreamEventCanAcceptBytes = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamErrorOccured:)] == YES)
		haveIStreamEventErrorOccurred = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamEndEncounted:)] == YES)
		haveIStreamEventEndEncountered = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamNone:)] == YES)
		haveIStreamEventNone = YES;
}// end - (void) setInputStreamDelegate:(id <InputStreamConnectionDelegate>)delegate

- (id <OutputStreamConnectionDelegate>) outputStreamDelegate
{
	return outputDelegator;
}// end nputStreamDelegate

- (void) setOutputStreamDelegate:(id <OutputStreamConnectionDelegate>)delegate
{		// set delegate
	outputDelegator = delegate;
#if __has_feature(objc_arc) == 0
	[outputDelegator retain];
#endif
		// check have method
	if ([outputDelegator respondsToSelector:@selector(oStreamEventOpenCompleted:)] == YES)
		haveOStreamEventOpenCompleted = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamHasBytesAvailable:)] == YES)
		haveOStreamEventHasBytesAvailable = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamCanAcceptBytes:)] == YES)
		haveOStreamEventCanAcceptBytes = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamErrorOccured:)] == YES)
		haveOStreamEventErrorOccurred = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamEndEncounted:)] == YES)
		haveOStreamEventEndEncountered = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamNone:)] == YES)
		haveOStreamEventNone = YES;
	
}// end - (void) setOutputStreamDelegate:(id <OutputStreamConnectionDelegate>)delegate

#pragma mark inputStream delegators
- (void) iStreamOpenCompleted:(NSInputStream *)iStream
{
}// end - (void) iStreamOpenCompleted:(NSInputStream *)iStream

- (void) iStreamHasBytesAvailable:(NSInputStream *)iStream
{
}// end - (void) iStreamHasBytesAvailable:(NSInputStream *)iStream

- (void) iStreamEndEncounted:(NSInputStream *)iStream
{
}// end - (void) iStreamEndEncounted:(NSStream *)iStream

- (void) iStreamErrorOccured:(NSInputStream *)iStream
{
}// end - (void) iStreamErrorOccured:(NSInputStream *)iStream

- (void) iStreamCanAcceptBytes:(NSInputStream *)iStream
{
}// end - (void) iStreamCanAcceptBytes:(NSInputStream *)iStream

- (void) iStreamNone:(NSInputStream *)iStream
{
}// end - (void) iStreamNone:(NSStream *)iStream

#pragma mark outputputStream delegators
- (void) oStreamOpenCompleted:(NSOutputStream *)oStream
{
}// end - (void) oStreamOpenCompleted:(NSInputStream *)oStream

- (void) oStreamCanAcceptBytes:(NSOutputStream *)oStream
{
}// end - (void) oStreamCanAcceptBytes:(NSInputStream *)oStream

- (void) oStreamEndEncounted:(NSOutputStream *)oStream
{
}// end - (void) oStreamEndEncounted:(NSStream *)oStream

- (void) oStreamErrorOccured:(NSOutputStream *)oStream
{
}// end - (void) oStreamErrorOccured:(NSInputStream *)oStream

- (void) oStreamHasBytesAvailable:(NSOutputStream *)oStream
{
}// end - (void) oStreamHasBytesAvailable:(NSInputStream *)oStream

- (void) oStreamNone:(NSOutputStream *)oStream
{
}// end - (void) oStreamNone:(NSStream *)oStream

@end
