//
//  YCStreamSession.m
//  Network bits
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "YCStreamSession.h"
#import <CoreFoundation/CoreFoundation.h>

@interface YCStreamSession ()
- (void) initializeMembers:(NSString *)host port:(int)port;
- (BOOL) initializeHost;

- (void) setupReadStream;
- (void) runReadStream;
- (void) cleanupReadStream;
- (void) setupWriteStream;
- (void) runWriteStream;
- (void) cleanupWriteStream;

static void read_stream_callback(CFReadStreamRef iStream, CFStreamEventType eventType, void* info);
static void write_stream_callback(CFWriteStreamRef oStream, CFStreamEventType eventType, void *info);
@end

@implementation YCStreamSession
@synthesize hostName;
@synthesize portNumber;
	//
#pragma mark construct / destruct
- (id) initWithHostName:(NSString *)host andPort:(int)port
{
	self = [super init];
	if (self)
	{
		[self initializeMembers:host port:port];
	}// end if self can allocate

	return self;
}// end - (id) initWithhostName:(NSString *)server andPort:(NSUInteger)port

- (id) initWithHostName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread
{
	self = [super init];
	if (self)
	{
		[self initializeMembers:host port:port];
		
	}// end if self can allocate
	
	return self;
}// - (id) initWithServerName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread

- (void) dealloc
{
	if (readStream != NULL)
		[self closeReadStream];
	if (writeStream != NULL)
		[self closeWriteStream];
#if !__has_feature(objc_arc)
	if (delegate != nil)		[delegate release];
#endif
	delegate = nil;
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
#pragma mark accessor
- (YCStreamDirection) direction	{	return direction;	}
- (void) setDirection:(YCStreamDirection)newDirection
{
	
}// end - (void) setDirection:(YCStreamDirection)newDirection
- (NSInputStream *) readStream
{
#if __has_feature(objc_arc)
	return (__bridge NSInputStream *)readStream;
#else
	return (NSInputStream *)readStream;
#endif
}// end - (NSInputStream *) readStream

- (NSOutputStream *) writeStream
{
#if __has_feature(objc_arc)
	return (__bridge NSOutputStream *)writeStream;
#else
	return (NSOutputStream *)writeStream;
#endif
}// end - (NSInputStream *) inputStream

#pragma mark -
#pragma mark action
- (BOOL) checkReadyToConnect
{
	@try {
		[self setupReadStream];
		readStreamIsSetuped = YES;
		[self setupWriteStream];
		writeStreamIsSetuped = YES;
		canConnect = YES;
	}
	@catch (NSError *err) {
		readStreamIsSetuped = NO;
		CFRelease(readStream);		readStream = NULL;
		writeStreamIsSetuped = NO;
		CFRelease(writeStream);		writeStream = NULL;
		canConnect = NO;
	}// end try - catch setup read and write streams

	return canConnect;
}// end - (BOOL) readyToConnect

- (BOOL) connect
{
	if (canConnect == NO)
		if ([self checkReadyToConnect] == NO)
			return NO;
		// end if check i/o stream
	// end check ready to connect

	BOOL success = YES;
	@try {
		[self runReadStream];
		[self runWriteStream];
	}
	@catch (NSError *error) {
		CFRelease(readStream);		readStream = NULL;
		CFRelease(writeStream);		writeStream = NULL;
		success = NO;
	}// end try - catch run read and write streams

	return success;
}// end - (void) connect

- (void) disconnect
{
	if (readStream != NULL)
	{
		[self closeReadStream];
		[self cleanupReadStream];
	}// end close read stream

	if (writeStream != NULL)
	{
		[self closeWriteStream];
		[self cleanupWriteStream];
	}// end close write stream
}// end - (void) disconnect

- (BOOL) reconnectReadStream
{
	if (readStream == NULL)
		return NO;

	BOOL success = YES;
	@try {
		[self runReadStream];
	}
	@catch (NSError *err) {
		success = NO;
	}// end try - catch run read stream

	return success;
}// end - (BOOL) reconnectReadStream

- (void) closeReadStream
{
	if (readStream != NULL)
		CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	// end close read stream
}// end - (void) closeReadStream

- (BOOL) reconnectWriteStream
{
	if (writeStream == NULL)
		return NO;
	
	BOOL success = YES;
	@try {
		[self runWriteStream];
	}
	@catch (NSError *err) {
		success = NO;
	}// end try - catch run read stream
	
	return success;
}// end - (BOOL) reconnectReadStream

- (void) closeWriteStream
{
	if (writeStream != NULL)
		CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	// end close write stream
}// end - (void) closeWriteStream

#pragma mark - internal
- (void) initializeMembers:(NSString *)host port:(int)port
{
	hostName = [host copy];
	portNumber = port;
	canConnect = NO;

	delegate = self;

	readStream = NULL;
	writeStream = NULL;
	readStreamOptions = 0;
	writeStreamOptions = 0;
	readStreamIsSetuped = NO;
	writeStreamIsSetuped = NO;

	hostRef = NULL;

	targetThread = nil;
}// end - (void) initializeMembers

- (BOOL) initializeHost
{
		// create CFHostRef from server and port
#if __has_feature(objc_arc)
	CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostName);
#else
	CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)hostName);
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
		[hostName release];
#endif
		return NO;
	}// end if create stream was failed

	return YES;
}// end - (BOOL) initializeHost

#pragma mark Read Stream
- (void) setupReadStream
{		// set property of read stream
	CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		// create StreamClient context
	CFStreamClientContext context =
#if __has_feature(objc_arc)
		{ 0, (__bridge void *)delegate, NULL, NULL, NULL };
#else
		{ 0, (void *)delegate, NULL, NULL, NULL };
#endif
    if (!CFReadStreamSetClient(readStream, readStreamOptions, read_stream_callback, &context))
	{		// check error
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
		__autoreleasing
#endif
		NSError *err =
#if __has_feature(objc_arc)
			(__bridge_transfer NSError *)CFReadStreamCopyError(readStream);
#else
			(NSError *)CFReadStreamCopyError(readStream);
		[err autorelease];
#endif
        @throw err;
    }// end if set callback and context failed
	
	return;
}// end - (CFErrorRef) setupReadStream

- (void) runReadStream
{		// hook read stream to runloop
    CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		// check can open read stream
    if (!CFReadStreamOpen(readStream))
	{		// open failed cleanup read stream
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
        __autoreleasing
#endif
		NSError *err =
#if __has_feature(objc_arc)
			(__bridge_transfer NSError *)CFReadStreamCopyError(readStream);
#else
			(NSError *)CFReadStreamCopyError(readStream);
		[err autorelease];
#endif
        CFReadStreamSetClient(readStream, kCFStreamEventNone, NULL, NULL);
        CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        @throw err;
    }// end cleanup read stream if failed
    
    return;
}// end - (CFStreamError) runReadStream

- (void) cleanupReadStream
{
	CFReadStreamClose(readStream);
	CFRelease(readStream);
	readStream = NULL;
}// end - (void) releaeReadStream

#pragma mark Write Stream
- (void) setupWriteStream
{		// set property of write stream
	CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		// create StreamClient context
	CFStreamClientContext context =
#if __has_feature(objc_arc)
		{ 0, (__bridge void *)delegate, NULL, NULL, NULL };
#else
		{ 0, (void *)delegate, NULL, NULL, NULL };
#endif
    if (!CFWriteStreamSetClient(writeStream, writeStreamOptions, write_stream_callback, &context))
	{
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
		__autoreleasing
#endif
		NSError *err =
#if __has_feature(objc_arc)
			(__bridge_transfer NSError *)CFWriteStreamCopyError(writeStream);
#else
			(NSError *)CFWriteStreamCopyError(writeStream);
		[err autorelease];
#endif
        @throw err;
    }// end if set callback and context failed
	
	return;
}// end - (CFErrorRef) setupWriteStream

- (void) runWriteStream
{		// hook write stream to runloop
    CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		// check can open read stream
    if (!CFWriteStreamOpen(writeStream))
	{		// open failed cleanup write stream
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
		__autoreleasing
#endif
		NSError *err =
#if __has_feature(objc_arc)
			(__bridge_transfer NSError *)CFWriteStreamCopyError(writeStream);
#else
			(NSError *)CFWriteStreamCopyError(writeStream);
		[err autorelease];
#endif
        
        CFWriteStreamSetClient(writeStream, kCFStreamEventNone, NULL, NULL);
        CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        @throw err;
    }// end cleanup write stream if failed
    
    return;
}// end - (CFStreamError) runWriteStream

- (void) cleanupWriteStream
{
	CFWriteStreamClose(writeStream);
	CFRelease(writeStream);
	writeStream = NULL;
}// end - (void) releaeReadStream

#pragma mark -
#pragma mark delegator process methods
#pragma mark accessor of StreamSessionDelegate
- (id <YCStreamSessionDelegate>) delegate
{
	return delegate;
}// end nputStreamDelegate

- (void) setDelegate:(id <YCStreamSessionDelegate>)delegator
{
# if !__has_feature(objc_arc)
		// check and release current delegate
	if (delegate != self)
		[delegate autorelease];
	// end if
#endif
		// set delegate
	delegate = delegator;
#if !__has_feature(objc_arc)
	[delegate retain];
#endif
		// check have methods
			// required input stream methods
	if ([delegate respondsToSelector:@selector(iStreamHasBytesAvailable:)] == YES)
		readStreamOptions |= kCFStreamEventHasBytesAvailable;
	if ([delegate respondsToSelector:@selector(iStreamEndEncounted:)] == YES)
		readStreamOptions |= kCFStreamEventEndEncountered;
			// optional input stream methods
			// !!!:FixIt
	if ([delegate respondsToSelector:@selector(iStreamErrorOccured:)] == YES)
		readStreamOptions |= kCFStreamEventErrorOccurred;
	if ([delegate respondsToSelector:@selector(iStreamOpenCompleted:)] == YES)
		readStreamOptions |= kCFStreamEventOpenCompleted;
	if ([delegate respondsToSelector:@selector(iStreamCanAcceptBytes:)] == YES)
		readStreamOptions |= kCFStreamEventCanAcceptBytes;
	if ([delegate respondsToSelector:@selector(iStreamNone:)] == YES)
		readStreamOptions |= kCFStreamEventNone;
			// required output stream methods
	if ([delegate respondsToSelector:@selector(oStreamCanAcceptBytes:)] == YES)
		writeStreamOptions |= kCFStreamEventCanAcceptBytes;
	if ([delegate respondsToSelector:@selector(oStreamEndEncounted:)] == YES)
		writeStreamOptions |= kCFStreamEventEndEncountered;
			// optional output stream methods
			// !!!:FixIt
	if ([delegate respondsToSelector:@selector(oStreamErrorOccured:)] == YES)
		writeStreamOptions |= kCFStreamEventErrorOccurred;
	if ([delegate respondsToSelector:@selector(oStreamOpenCompleted:)] == YES)
		writeStreamOptions |= kCFStreamEventOpenCompleted;
	if ([delegate respondsToSelector:@selector(oStreamHasBytesAvailable:)] == YES)
		writeStreamOptions |= kCFStreamEventHasBytesAvailable;
	if ([delegate respondsToSelector:@selector(oStreamNone:)] == YES)
		writeStreamOptions |= kCFStreamEventNone;
}// end - (void) setInputStreamDelegate:(id <InputStreamConnectionDelegate>)delegate

#pragma mark -
#pragma mark delegator methods
#pragma mark InputStreamSessionDelegate methods
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

#pragma mark OutputStreamSessionDelegate methods
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
#pragma mark callback for read stream
static void
read_stream_callback(CFReadStreamRef iStream, CFStreamEventType eventType, void* info)
{
#if __has_feature(objc_arc)
	id iDelegator = (__bridge id)info;
	NSInputStream *rStream = (__bridge NSInputStream *)iStream;
#else
	id iDelegator = (id)info;
	NSInputStream *rStream = (NSInputStream *)iStream;
#endif
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
			[iDelegator iStreamOpenCompleted:rStream];
            break;
        case kCFStreamEventHasBytesAvailable:
			[iDelegator iStreamHasBytesAvailable:rStream];
            break;
        case kCFStreamEventEndEncountered:
			[iDelegator iStreamEndEncounted:rStream];
            break;
        case kCFStreamEventErrorOccurred:
			[iDelegator iStreamErrorOccured:rStream];
            break;
		case kCFStreamEventCanAcceptBytes:
			[iDelegator iStreamCanAcceptBytes:rStream];
			break;
		case kCFStreamEventNone:
			[iDelegator iStreamHasBytesAvailable:rStream];
		default:
			break;
    }// end swith read stream event
}// end read_stream_callback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info)

#pragma mark callback for write stream
static void
write_stream_callback(CFWriteStreamRef oStream, CFStreamEventType eventType, void* info)
{
#if __has_feature(objc_arc)
	id oDelegator = (__bridge id)info;
	NSOutputStream *wStream = (__bridge NSOutputStream *)oStream;
#else
	id oDelegator = (id)info;
	NSOutputStream *wStream = (NSOutputStream *)oStream;
#endif
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
			[oDelegator oStreamOpenCompleted:wStream];
            break;
		case kCFStreamEventCanAcceptBytes:
			[oDelegator oStreamCanAcceptBytes:wStream];
			break;
        case kCFStreamEventEndEncountered:
			[oDelegator oStreamEndEncounted:wStream];
            break;
        case kCFStreamEventErrorOccurred:
			[oDelegator oStreamErrorOccured:wStream];
            break;
        case kCFStreamEventHasBytesAvailable:
			[oDelegator oStreamHasBytesAvailable:wStream];
            break;
		case kCFStreamEventNone:
			[oDelegator oStreamHasBytesAvailable:wStream];
		default:
			break;
    }// end switch write stream event
}// end read_stream_callback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info)

@end
