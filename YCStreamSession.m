//
//  YCStreamSession.m
//  Network bits
//
//  Created by Чайка on 7/7/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import "YCStreamSession.h"
#import <CoreFoundation/CoreFoundation.h>

#if MAC_OS_X_VERSION_MIN_REQUIRED == MAC_OS_X_VERSION_10_5
typedef	uint32_t	SCNetworkReachabilityFlags;
#endif

@interface YCStreamSession ()
- (void) initializeMembers:(NSString *)host port:(int)port;
- (BOOL) initializeHost;

- (void) validateReachabilityAsync;

- (void) setupReadStream;
- (void) runReadStream;
- (void) cleanupReadStream;
- (void) setupWriteStream;
- (void) runWriteStream;
- (void) cleanupWriteStream;

static void ReadStreamCallback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info);
static void WriteStreamCallback(CFWriteStreamRef writeStream, CFStreamEventType eventType, void *info);
static void NetworkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);
@end

@implementation YCStreamSession
@synthesize	hostName;
@synthesize	portNumber;
@synthesize	direction;
	//
#pragma mark construct / destruct
- (id) initWithHostName:(NSString *)host andPort:(int)port
{
	self = [super init];
	if (self)
	{
		[self initializeMembers:host port:port];
		if ([self initializeHost] == NO)
			return nil;
		// end if initialize host is fail

		targetThread = [NSThread mainThread];
#if !__has_feature(objc_arc)
		[targetThread retain];
#endif
	}// end if self can allocate

	return self;
}// end - (id) initWithhostName:(NSString *)server andPort:(NSUInteger)port

- (id) initWithHostName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread
{
	self = [super init];
	if (self)
	{
		[self initializeMembers:host port:port];
		if ([self initializeHost] == NO)
			return nil;
		// end if initialize host is fail

		targetThread = thread;
#if !__has_feature(objc_arc)
		[targetThread retain];
#endif
	}// end if self can allocate
	
	return self;
}// end - (id) initWithServerName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread

- (void) dealloc
{
	if (readStream != NULL)		[self closeReadStream];
	if (writeStream != NULL)	[self closeWriteStream];
	if (hostRef != NULL)		CFRelease(hostRef);
	hostRef = NULL;
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
	if (readStream != NULL)		[self closeReadStream];
	if (writeStream != NULL)	[self closeWriteStream];
	if (hostRef != NULL)		CFRelease(hostRef);
	hostRef = NULL;

	[super finalize];
}
#endif

#pragma mark -
#pragma mark accessor
- (NSTimeInterval) timeout {	return timeout;	}
- (void) setTimeout:(NSTimeInterval)newTimeout
{
	timeout = newTimeout;
}// end - (void) setTimeout:(NSTimeInterval)newTimeout

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
- (void) checkReadyToConnect
{
	[self validateReachabilityAsync];
}// end - (void) checkReadyToConnect

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

	reachabilityValidating = NO;
		// create SCNetworkReachabilityRef
	hostRef = NULL;
	timeout = 0;

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
	CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault, host, portNumber, &readStream, &writeStream);
	CFRelease(host);
	hostRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String]);
	if ((readStream == NULL) || (writeStream == NULL) || (hostRef == NULL))
	{
		if (readStream != NULL)		CFRelease(readStream);
		readStream = NULL;
		if (writeStream != NULL)	CFRelease(writeStream);
		writeStream = NULL;
		if (hostRef != NULL)		CFRelease(hostRef);
		hostRef = NULL;
#if !__has_feature(objc_arc)
		[hostName release];
#endif
		return NO;
	}// end if create stream was failed

	return YES;
}// end - (BOOL) initializeHost

#pragma mark - Reachablity
- (void) validateReachabilityAsync
{
#if __has_feature(objc_arc)
	SCNetworkReachabilityContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };
#else
	SCNetworkReachabilityContext context = { 0, (void *)self, NULL, NULL, NULL };
#endif
	if (SCNetworkReachabilitySetCallback(hostRef, NetworkReachabilityCallBack, &context) == true)
	{		//
		if (targetThread == nil)
			[self scheduleReachability];
		else
			[self performSelector:@selector(scheduleReachability) onThread:targetThread withObject:nil waitUntilDone:YES];
			// start timer if timeout is limited
		if (timeout != 0)
			[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(timeoutReachability:) userInfo:nil repeats:NO];
	}// end if run reachability
}// end - (void) validateReachabilityAsync

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
    if (!CFReadStreamSetClient(readStream, readStreamOptions, ReadStreamCallback, &context))
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
    if (!CFWriteStreamSetClient(writeStream, writeStreamOptions, WriteStreamCallback, &context))
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

#pragma mark - handle reachability
- (void) timeoutReachability:(NSTimer *)timer
{
	if (targetThread == nil)
		[self unscheduleReachability];
	else
		[self performSelector:@selector(unscheduleReachability) onThread:targetThread withObject:nil waitUntilDone:YES];

	[self streamReadyToConnect:self reachable:NO];
}// end - (void) timeoutReachability:(NSTimer *)timer

- (void) scheduleReachability
{
	reachabilityValidating = YES;
	SCNetworkReachabilityScheduleWithRunLoop(hostRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}// end - (void) scheduleReachability

- (void) unscheduleReachability
{
	SCNetworkReachabilityUnscheduleFromRunLoop(hostRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	reachabilityValidating = NO;
}// end - (void) unscheduleReachability

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
	if ([delegate respondsToSelector:@selector(readStreamHasBytesAvailable:)] == YES)
		readStreamOptions |= kCFStreamEventHasBytesAvailable;
	if ([delegate respondsToSelector:@selector(readStreamEndEncounted:)] == YES)
		readStreamOptions |= kCFStreamEventEndEncountered;
			// optional input stream methods
	readStreamOptions |= kCFStreamEventErrorOccurred;
	if ([delegate respondsToSelector:@selector(readStreamErrorOccured:)] == YES)
		mustHandleReadStreamError = NO;
	if ([delegate respondsToSelector:@selector(readStreamOpenCompleted:)] == YES)
		readStreamOptions |= kCFStreamEventOpenCompleted;
	if ([delegate respondsToSelector:@selector(readStreamCanAcceptBytes:)] == YES)
		readStreamOptions |= kCFStreamEventCanAcceptBytes;
	if ([delegate respondsToSelector:@selector(readStreamNone:)] == YES)
		readStreamOptions |= kCFStreamEventNone;
			// required output stream methods
	if ([delegate respondsToSelector:@selector(writeStreamCanAcceptBytes:)] == YES)
		writeStreamOptions |= kCFStreamEventCanAcceptBytes;
	if ([delegate respondsToSelector:@selector(writeStreamEndEncounted:)] == YES)
		writeStreamOptions |= kCFStreamEventEndEncountered;
			// optional output stream methods
	writeStreamOptions |= kCFStreamEventErrorOccurred;
	if ([delegate respondsToSelector:@selector(writeStreamErrorOccured:)] == YES)
		mustHandleReadStreamError = NO;
	if ([delegate respondsToSelector:@selector(writeStreamOpenCompleted:)] == YES)
		writeStreamOptions |= kCFStreamEventOpenCompleted;
	if ([delegate respondsToSelector:@selector(writeStreamHasBytesAvailable:)] == YES)
		writeStreamOptions |= kCFStreamEventHasBytesAvailable;
	if ([delegate respondsToSelector:@selector(writeStreamNone:)] == YES)
		writeStreamOptions |= kCFStreamEventNone;

}// end - (void) setInputStreamDelegate:(id <InputStreamConnectionDelegate>)delegate

#pragma mark -
#pragma mark delegator methods
- (void) streamReadyToConnect:(YCStreamSession *)session reachable:(BOOL)reachable
{
	if (targetThread == nil)
		[self unscheduleReachability];
	else
		[self performSelector:@selector(unscheduleReachability) onThread:targetThread withObject:nil waitUntilDone:YES];

	[delegate streamReadyToConnect:self reachable:reachable];
}// end - (void) streamReadyToConnect:(YCStreamSession *)session

#pragma mark InputStreamSessionDelegate methods
- (void) readStreamHasBytesAvailable:(NSInputStream *)readStream
{
}// end - (void) readStreamHasBytesAvailable:(NSInputStream *)readStream

- (void) readStreamEndEncounted:(NSInputStream *)readStream
{
}// end - (void) readStreamEndEncounted:(NSStream *)readStream

- (void) readStreamErrorOccured:(NSInputStream *)readStream
{
}// end - (void) readStreamErrorOccured:(NSInputStream *)readStream

- (void) readStreamOpenCompleted:(NSInputStream *)readStream
{
}// end - (void) readStreamOpenCompleted:(NSInputStream *)readStream

- (void) readStreamCanAcceptBytes:(NSInputStream *)readStream
{
}// end - (void) readStreamCanAcceptBytes:(NSInputStream *)readStream

- (void) readStreamNone:(NSInputStream *)readStream
{
}// end - (void) readStreamNone:(NSStream *)readStream

#pragma mark OutputStreamSessionDelegate methods
- (void) writeStreamCanAcceptBytes:(NSOutputStream *)writeStream
{
}// end - (void) writeStreamCanAcceptBytes:(NSInputStream *)writeStream

- (void) writeStreamEndEncounted:(NSOutputStream *)writeStream
{
}// end - (void) writeStreamEndEncounted:(NSStream *)writeStream

- (void) writeStreamErrorOccured:(NSOutputStream *)writeStream
{
}// end - (void) writeStreamErrorOccured:(NSInputStream *)writeStream

- (void) writeStreamOpenCompleted:(NSOutputStream *)writeStream
{
}// end - (void) writeStreamOpenCompleted:(NSInputStream *)writeStream

- (void) writeStreamHasBytesAvailable:(NSOutputStream *)writeStream
{
}// end - (void) writeStreamHasBytesAvailable:(NSInputStream *)writeStream

- (void) writeStreamNone:(NSOutputStream *)writeStream
{
}// end - (void) writeStreamNone:(NSStream *)writeStream

#pragma mark - Core Foundation part
#pragma mark callback for read stream
static void
ReadStreamCallback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info)
{
#if __has_feature(objc_arc)
	id iDelegator = (__bridge id)info;
	NSInputStream *rStream = (__bridge NSInputStream *)readStream;
#else
	id iDelegator = (id)info;
	NSInputStream *rStream = (NSInputStream *)readStream;
#endif
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
			[iDelegator readStreamOpenCompleted:rStream];
            break;
        case kCFStreamEventHasBytesAvailable:
			[iDelegator readStreamHasBytesAvailable:rStream];
            break;
        case kCFStreamEventEndEncountered:
			[iDelegator readStreamEndEncounted:rStream];
            break;
        case kCFStreamEventErrorOccurred:
			[iDelegator readStreamErrorOccured:rStream];
            break;
		case kCFStreamEventCanAcceptBytes:
			[iDelegator readStreamCanAcceptBytes:rStream];
			break;
		case kCFStreamEventNone:
			[iDelegator readStreamHasBytesAvailable:rStream];
		default:
			break;
    }// end swith read stream event
}// end ReadStreamCallback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info)

#pragma mark callback for write stream
static void
WriteStreamCallback(CFWriteStreamRef writeStream, CFStreamEventType eventType, void *info)
{
#if __has_feature(objc_arc)
	id oDelegator = (__bridge id)info;
	NSOutputStream *wStream = (__bridge NSOutputStream *)writeStream;
#else
	id oDelegator = (id)info;
	NSOutputStream *wStream = (NSOutputStream *)writeStream;
#endif
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
			[oDelegator writeStreamOpenCompleted:wStream];
            break;
		case kCFStreamEventCanAcceptBytes:
			[oDelegator writeStreamCanAcceptBytes:wStream];
			break;
        case kCFStreamEventEndEncountered:
			[oDelegator writeStreamEndEncounted:wStream];
            break;
        case kCFStreamEventErrorOccurred:
			[oDelegator writeStreamErrorOccured:wStream];
            break;
        case kCFStreamEventHasBytesAvailable:
			[oDelegator writeStreamHasBytesAvailable:wStream];
            break;
		case kCFStreamEventNone:
			[oDelegator writeStreamHasBytesAvailable:wStream];
		default:
			break;
    }// end switch write stream event
}// end WriteStreamCallback(CFWriteStreamRef writeStream, CFStreamEventType eventType, void *info)

#pragma mark - callback for network reachability
static void
NetworkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
#if __has_feature(objc_arc)
	YCStreamSession *mySelf = (__bridge YCStreamSession *)info;
#else
	YCStreamSession *mySelf = (YCStreamSession *)info;
#endif
	if (flags != 0)
		[mySelf streamReadyToConnect:mySelf reachable:YES];
	else
		[mySelf streamReadyToConnect:mySelf reachable:NO];
}// end NetworkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);

@end
