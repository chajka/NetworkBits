//
//  CFSocketConnection.m
//  Network bits
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "CFSocketConnection.h"
#import <CoreFoundation/CoreFoundation.h>

@interface CFSocketConnection (private)
static CFStreamError do_connect(void);
static void disconnectReadStream(CFReadStreamRef iStream);
static void disconnectWriteStream(CFWriteStreamRef oStream);
static CFStreamError setup_read_stream(CFReadStreamRef readStream);
static CFStreamError run_read_stream(CFReadStreamRef readStream);
static CFStreamError setup_write_stream(CFWriteStreamRef writeStream);
static CFStreamError run_write_stream(CFWriteStreamRef writeStream);
static void read_stream_callback(CFReadStreamRef iStream, CFStreamEventType eventType, void* info);
static void write_stream_callback(CFWriteStreamRef oStream, CFStreamEventType eventType, void *info);
@end

@implementation CFSocketConnection
@synthesize serverName;
@synthesize portNumber;
	//
static id iDelegator = nil;
static id oDelegator = nil;
	//
CFReadStreamRef readStream = NULL;
CFWriteStreamRef writeStream = NULL;
static BOOL readStreamIsSetuped = NO;
static BOOL writeStreamIsSetuped = NO;
	// input stream delegate flags
static BOOL haveIStreamEventOpenCompleted = NO;
static BOOL haveIStreamEventHasBytesAvailable = NO;
static BOOL haveIStreamEventCanAcceptBytes = NO;
static BOOL haveIStreamEventErrorOccurred = NO;
static BOOL haveIStreamEventEndEncountered = NO;
static BOOL haveIStreamEventNone = NO;
	// output stream delegate flags
static BOOL haveOStreamEventOpenCompleted = NO;
static BOOL haveOStreamEventHasBytesAvailable = NO;
static BOOL haveOStreamEventCanAcceptBytes = NO;
static BOOL haveOStreamEventErrorOccurred = NO;
static BOOL haveOStreamEventEndEncountered = NO;
static BOOL haveOStreamEventNone = NO;
#pragma mark construct / destruct
- (id) initWithServerName:(NSString *)server andPort:(int)port
{
	self = [super init];
	if (self)
	{
		canConnect = NO;
		serverName = [server copy];
		portNumber = port;
		inputDelegator = self;
		outputDelegator = self;
			// create CFHostRef from server and port
#if __has_feature(objc_arc)
		CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)serverName);
#else
		CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)serverName);
#endif
			// allocate target host/port’s read & write stream
		CFStreamCreatePairWithSocketToCFHost(
			kCFAllocatorDefault, host, portNumber, &readStream, &writeStream);
		CFRelease(host);
		if ((readStream == NULL) || (writeStream == NULL))
		{
			if (readStream != NULL)		CFRelease(readStream);
			if (writeStream != NULL)	CFRelease(writeStream);
#if !__has_feature(objc_arc)
			[serverName release];
#endif
			return nil;
		}// end if create stream was failed
	}// end if self can allocate

	return self;
}// end - (id) initWithServerName:(NSString *)server andPort:(NSUInteger)port

- (void) dealloc
{
	if (readStream != NULL)
		[self closeReadStream];
	if (writeStream != NULL)
		[self closeWriteStream];
#if !__has_feature(objc_arc)
	if ((inputDelegator != self) || (inputDelegator != nil))
		[inputDelegator release];
	if ((outputDelegator != self) || (inputDelegator != nil))
		[outputDelegator release];
#endif
	inputDelegator = nil;
	outputDelegator = nil;
#if !__has_feature(objc_arc)
	[super dealloc];
#endif
}

#if __OBJC_GC__
- (void) finalize
{
	if (readStream != NULL)
		[self closeReadStream];
	if (writeStream != NULL)
		[self closeWriteStream];
	[super finalize];
}
#endif

#pragma mark -
#pragma mark action
- (BOOL) checkReadyToConnect
{
	CFStreamError readErr;
	CFStreamError writeErr;
	readErr = setup_read_stream(readStream);
	writeErr = setup_write_stream(writeStream);
	if ((readErr.error != 0) || (writeErr.error != 0))
	{
		readStreamIsSetuped = NO;
		writeStreamIsSetuped = NO;
		CFRelease(readStream);		readStream = NULL;
		CFRelease(writeStream);		writeStream = NULL;
	}
	else
	{
		readStreamIsSetuped = YES;
		writeStreamIsSetuped = YES;
	}// end if readstream setup error
	canConnect = ((readStreamIsSetuped && writeStreamIsSetuped) == YES) ? YES : NO;

	return canConnect;
}// end - (BOOL) readyToConnect

- (BOOL) connect
{
	if (canConnect == NO)
		if ([self checkReadyToConnect] == NO)
			return NO;
		// end if check i/o stream
	// end check ready to connect
	CFStreamError err;
	err = do_connect();

	return (err.error == 0) ? YES : NO;
}// end - (void) connect

- (void) disconnect
{
	if (readStream != NULL)
	{
		disconnectReadStream(readStream);
		readStream = NULL;
#if !__has_feature(objc_arc)
		if (inputDelegator != self)		[inputDelegator release];
#endif
		inputDelegator = nil;
		
	}// end close read stream

	if (writeStream != NULL)
	{
		disconnectWriteStream(writeStream);
		writeStream = NULL;
#if !__has_feature(objc_arc)
		if (outputDelegator != self)	[outputDelegator release];
#endif
		outputDelegator = nil;
	}// end close write stream
}// end - (void) disconnect

- (void) closeReadStream
{
	if (readStream != NULL)
	{
		disconnectReadStream(readStream);
		readStream = NULL;
#if !__has_feature(objc_arc)
		if (inputDelegator != self)		[inputDelegator release];
#endif
		inputDelegator = nil;
	}// end close read stream
}// end - (void) closeReadStream

- (void) closeWriteStream
{
	if (writeStream != NULL)
	{
		disconnectWriteStream(writeStream);
		writeStream = NULL;
#if !__has_feature(objc_arc)
		if (outputDelegator != self)	[outputDelegator release];
#endif
		outputDelegator = nil;
	}// end close write stream
}// end - (void) closeWriteStream

#pragma mark -
#pragma mark accessor
- (NSInputStream *) inputStream
{
#if __has_feature(objc_arc)
	return (__bridge NSInputStream *)readStream;
#else
	return (NSInputStream *)readStream;
#endif
}// end - (NSInputStream *) inputStream

- (NSOutputStream *) outputStream
{
#if __has_feature(objc_arc)
	return (__bridge NSOutputStream *)writeStream;
#else
	return (NSOutputStream *)writeStream;
#endif
}// end - (NSInputStream *) inputStream

#pragma mark -
#pragma mark delegator process methods
#pragma mark accessor of inputStreamDelegate
- (id <InputStreamConnectionDelegate>) inputStreamDelegate
{
	return inputDelegator;
}// end nputStreamDelegate

- (void) setInputStreamDelegate:(id <InputStreamConnectionDelegate>)delegate
{		// set delegate
	inputDelegator = delegate;
	iDelegator = delegate;
#if !__has_feature(objc_arc)
	[inputDelegator retain];
#endif
		// check have methods
			// required methods
	if ([inputDelegator respondsToSelector:@selector(iStreamHasBytesAvailable:)] == YES)
		haveIStreamEventHasBytesAvailable = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamEndEncounted:)] == YES)
		haveIStreamEventEndEncountered = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamErrorOccured:)] == YES)
		haveIStreamEventErrorOccurred = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamOpenCompleted:)] == YES)
		haveIStreamEventOpenCompleted = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamCanAcceptBytes:)] == YES)
		haveIStreamEventCanAcceptBytes = YES;
	if ([inputDelegator respondsToSelector:@selector(iStreamNone:)] == YES)
		haveIStreamEventNone = YES;
}// end - (void) setInputStreamDelegate:(id <InputStreamConnectionDelegate>)delegate

#pragma mark accessor of outputStreamDelegate
- (id <OutputStreamConnectionDelegate>) outputStreamDelegate
{
	return outputDelegator;
}// end nputStreamDelegate

- (void) setOutputStreamDelegate:(id <OutputStreamConnectionDelegate>)delegate
{		// set delegate
	outputDelegator = delegate;
	oDelegator = outputDelegator;
#if !__has_feature(objc_arc)
	[outputDelegator retain];
#endif
		// check have methods
			// required methods
	if ([outputDelegator respondsToSelector:@selector(oStreamCanAcceptBytes:)] == YES)
		haveOStreamEventCanAcceptBytes = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamEndEncounted:)] == YES)
		haveOStreamEventEndEncountered = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamErrorOccured:)] == YES)
		haveOStreamEventErrorOccurred = YES;
			// optional methods
	if ([outputDelegator respondsToSelector:@selector(oStreamHasBytesAvailable:)] == YES)
		haveOStreamEventHasBytesAvailable = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamOpenCompleted:)] == YES)
		haveOStreamEventOpenCompleted = YES;
	if ([outputDelegator respondsToSelector:@selector(oStreamNone:)] == YES)
		haveOStreamEventNone = YES;
	
}// end - (void) setOutputStreamDelegate:(id <OutputStreamConnectionDelegate>)delegate

#pragma mark -
#pragma mark delegator methods
#pragma mark InputStreamConnectionDelegate methods
- (void) iStreamHasBytesAvailable:(NSInputStream *)iStream
{
}// end - (void) iStreamHasBytesAvailable:(NSInputStream *)iStream

- (void) iStreamEndEncounted:(NSInputStream *)iStream
{
}// end - (void) iStreamEndEncounted:(NSStream *)iStream

- (void) iStreamErrorOccured:(NSInputStream *)iStream
{
}// end - (void) iStreamErrorOccured:(NSInputStream *)iStream

- (void) iStreamOpenCompleted:(NSInputStream *)iStream
{
}// end - (void) iStreamOpenCompleted:(NSInputStream *)iStream

- (void) iStreamCanAcceptBytes:(NSInputStream *)iStream
{
}// end - (void) iStreamCanAcceptBytes:(NSInputStream *)iStream

- (void) iStreamNone:(NSInputStream *)iStream
{
}// end - (void) iStreamNone:(NSStream *)iStream

#pragma mark OutputStreamConnectionDelegate methods
- (void) oStreamCanAcceptBytes:(NSOutputStream *)oStream
{
}// end - (void) oStreamCanAcceptBytes:(NSInputStream *)oStream

- (void) oStreamEndEncounted:(NSOutputStream *)oStream
{
}// end - (void) oStreamEndEncounted:(NSStream *)oStream

- (void) oStreamErrorOccured:(NSOutputStream *)oStream
{
}// end - (void) oStreamErrorOccured:(NSInputStream *)oStream

- (void) oStreamOpenCompleted:(NSOutputStream *)oStream
{
}// end - (void) oStreamOpenCompleted:(NSInputStream *)oStream

- (void) oStreamHasBytesAvailable:(NSOutputStream *)oStream
{
}// end - (void) oStreamHasBytesAvailable:(NSInputStream *)oStream

- (void) oStreamNone:(NSOutputStream *)oStream
{
}// end - (void) oStreamNone:(NSStream *)oStream

#pragma mark - Core Foundation part
#pragma mark callback for input stream

static CFStreamError
do_connect(void)
{
	CFStreamError err;
    err = run_read_stream(readStream);
    if (err.error != 0)
	{
		CFRelease(readStream);		readStream = NULL;
		CFRelease(writeStream);		writeStream = NULL;
        return err;
    }// end if read stream run error
		// setup write stream
	err = run_write_stream(writeStream);
    if (err.error != 0) {
		CFRelease(readStream);		readStream = NULL;
		CFRelease(writeStream);		writeStream = NULL;
        return err;
    }// end if write stream run error

	return err;
}// end static void do_connect(CFHostRef host)

static void
disconnectReadStream(CFReadStreamRef iStream)
{
	CFReadStreamUnscheduleFromRunLoop(iStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	CFReadStreamClose(iStream);
	CFRelease(iStream);
}// end disconnectReadStream

static void
disconnectWriteStream(CFWriteStreamRef oStream)
{
	CFWriteStreamUnscheduleFromRunLoop(oStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	CFWriteStreamClose(oStream);
	CFRelease(oStream);
}// end disconnectReadStream

static CFStreamError
setup_read_stream(CFReadStreamRef readStream)
{
	CFStreamError err;
	err.domain = kCFStreamErrorDomainMacOSStatus;
	err.error = noErr;

		// setup acceptable evnents
	CFOptionFlags streamEvents = 0;
	if (haveIStreamEventOpenCompleted)
		streamEvents |= kCFStreamEventOpenCompleted;
	if (haveIStreamEventHasBytesAvailable)
		streamEvents |= kCFStreamEventHasBytesAvailable;
	if (haveIStreamEventCanAcceptBytes)
		streamEvents |= kCFStreamEventCanAcceptBytes;
	if (haveIStreamEventErrorOccurred)
		streamEvents |= kCFStreamEventErrorOccurred;
	if (haveIStreamEventEndEncountered)
		streamEvents |= kCFStreamEventEndEncountered;
	if (haveIStreamEventNone)
		streamEvents |= kCFStreamEventNone;

		// set property of read stream
		//	CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		// create StreamClient context
    CFStreamClientContext context = { 0, NULL, NULL, NULL, NULL };
    if (!CFReadStreamSetClient(readStream, streamEvents, read_stream_callback, &context))
	{		// check error
        err = CFReadStreamGetError(readStream);
        return err;
    }// end if set callback and context failed

	return err;
}// end static CFStreamError setup_read_stream(CFReadStreamRef readStream)

static CFStreamError
run_read_stream(CFReadStreamRef readStream)
{
	CFStreamError err;
	err.domain = kCFStreamErrorDomainMacOSStatus;
	err.error = noErr;
	
		// hook read stream to runloop
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		// check can open read stream
    if (!CFReadStreamOpen(readStream))
	{		// open failed cleanup read stream
        err = CFReadStreamGetError(readStream);
        
        CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        return err;
    }// end cleanup read stream if failed
    
    return err;
}// end static bool setup_read_stream(CFReadStreamRef readStream)

static CFStreamError
setup_write_stream(CFWriteStreamRef writeStream)
{
	CFStreamError err;
	err.domain = kCFStreamErrorDomainMacOSStatus;
	err.error = noErr;

		// setup acceptable evnents
	CFOptionFlags streamEvents = 0;
	if (haveOStreamEventOpenCompleted)
		streamEvents |= kCFStreamEventOpenCompleted;
	if (haveOStreamEventHasBytesAvailable)
		streamEvents |= kCFStreamEventHasBytesAvailable;
	if (haveOStreamEventCanAcceptBytes)
		streamEvents |= kCFStreamEventCanAcceptBytes;
	if (haveOStreamEventErrorOccurred)
		streamEvents |= kCFStreamEventErrorOccurred;
	if (haveOStreamEventEndEncountered)
		streamEvents |= kCFStreamEventEndEncountered;
	if (haveOStreamEventNone)
		streamEvents |= kCFStreamEventNone;

		// set property of write stream
		//	CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		// create StreamClient context
	CFStreamClientContext context = { 0, NULL, NULL, NULL, NULL };
    if (!CFWriteStreamSetClient(writeStream, streamEvents, write_stream_callback, &context))
	{
        err = CFWriteStreamGetError(writeStream);
        return err;
    }// end if set callback and context failed

	return err;
}// end static CFStreamError setup_read_stream(CFReadStreamRef readStream)

static CFStreamError
run_write_stream(CFWriteStreamRef writeStream)
{
	CFStreamError err;
	err.domain = kCFStreamErrorDomainMacOSStatus;
	err.error = noErr;

		// hook write stream to runloop
    CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		// check can open read stream
    if (!CFWriteStreamOpen(writeStream))
	{		// open failed cleanup write stream
        err = CFWriteStreamGetError(writeStream);
        
        CFWriteStreamSetClient(writeStream, kCFStreamEventNone, NULL, NULL);
        CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        return err;
    }// end cleanup write stream if failed
    
    return err;
}// end static bool setup_write_stream(CFWriteStreamRef writeStream)

static void
read_stream_callback(CFReadStreamRef iStream, CFStreamEventType eventType, void* info)
{
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
#if __has_feature(objc_arc)
			[iDelegator iStreamOpenCompleted:(__bridge NSInputStream *)iStream];
#else
			[iDelegator iStreamOpenCompleted:(NSInputStream *)iStream];
#endif
            break;
        case kCFStreamEventHasBytesAvailable:
#if __has_feature(objc_arc)
			[iDelegator iStreamHasBytesAvailable:(__bridge NSInputStream *)iStream];
#else
			[iDelegator iStreamHasBytesAvailable:(NSInputStream *)iStream];
#endif
            break;
        case kCFStreamEventEndEncountered:
#if __has_feature(objc_arc)
			[iDelegator iStreamEndEncounted:(__bridge NSInputStream *)iStream];
#else
			[iDelegator iStreamEndEncounted:(NSInputStream *)iStream];
#endif
            break;
        case kCFStreamEventErrorOccurred:
#if __has_feature(objc_arc)
			[iDelegator iStreamErrorOccured:(__bridge NSInputStream *)iStream];
#else
			[iDelegator iStreamErrorOccured:(NSInputStream *)iStream];
#endif
            break;
		case kCFStreamEventCanAcceptBytes:
#if __has_feature(objc_arc)
			[iDelegator iStreamCanAcceptBytes:(__bridge NSInputStream *)iStream];
#else
			[iDelegator iStreamCanAcceptBytes:(NSInputStream *)iStream];
#endif
			break;
		case kCFStreamEventNone:
#if __has_feature(objc_arc)
			[iDelegator iStreamHasBytesAvailable:(__bridge NSInputStream *)iStream];
#else
			[iDelegator iStreamHasBytesAvailable:(NSInputStream *)iStream];
#endif
		default:
			break;
    }// end swith read stream event
}// end read_stream_callback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info)

static void
write_stream_callback(CFWriteStreamRef oStream, CFStreamEventType eventType, void* info)
{
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
#if __has_feature(objc_arc)
			[oDelegator oStreamOpenCompleted:(__bridge NSOutputStream *)oStream];
#else
			[oDelegator oStreamOpenCompleted:(NSOutputStream *)oStream];
#endif
            break;
		case kCFStreamEventCanAcceptBytes:
#if __has_feature(objc_arc)
			[oDelegator oStreamCanAcceptBytes:(__bridge NSOutputStream *)oStream];
#else
			[oDelegator oStreamCanAcceptBytes:(NSOutputStream *)oStream];
#endif
			break;
        case kCFStreamEventEndEncountered:
#if __has_feature(objc_arc)
			[oDelegator oStreamEndEncounted:(__bridge NSOutputStream *)oStream];
#else
			[oDelegator oStreamEndEncounted:(NSOutputStream *)oStream];
#endif
            break;
        case kCFStreamEventErrorOccurred:
#if __has_feature(objc_arc)
			[oDelegator oStreamErrorOccured:(__bridge NSOutputStream *)oStream];
#else
			[oDelegator oStreamErrorOccured:(NSOutputStream *)oStream];
#endif
            break;
        case kCFStreamEventHasBytesAvailable:
#if __has_feature(objc_arc)
			[oDelegator oStreamHasBytesAvailable:(__bridge NSOutputStream *)oStream];
#else
			[oDelegator oStreamHasBytesAvailable:(NSOutputStream *)oStream];
#endif
            break;
		case kCFStreamEventNone:
#if __has_feature(objc_arc)
			[oDelegator oStreamHasBytesAvailable:(__bridge NSOutputStream *)oStream];
#else
			[oDelegator oStreamHasBytesAvailable:(NSOutputStream *)oStream];
#endif
		default:
			break;
    }// end switch write stream event
}// end read_stream_callback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info)

@end
