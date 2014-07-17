//
//  YCStreamSessionGCD.m
//  NicoLiveAlert
//
//  Created by Чайка on 7/14/14.
//  Copyright (c) 2014 Instrumentality of mankind. All rights reserved.
//

#import "YCStreamSessionGCD.h"

const NSString *ReadStreamError =			@"ReadStreamError";
const NSString *WriteStreamError =			@"WriteStreamError";
const NSString *ReadStreamSetupError =		@"ReadStreamSetupError";
const NSString *WriteStreamSetupError =		@"WriteStreamSetupError";

const NSString *keySelf =					@"keySelf";
const NSString *keyDelegate =				@"keyDelegate";

const char *dispatchLabelName =				"YCStreamSession";

@interface YCStreamSessionGCD ()
- (void) initializeMembers:(NSString *)host port:(int)port;
- (BOOL) initializeHost;

- (void) validateReachabilityAsync;

- (void) setupReadStream;
- (void) runReadStream;
- (void) suspendReadStream;
- (void) cleanupReadStream;
- (void) setupWriteStream;
- (void) runWriteStream;
- (void) suspendWriteStream;
- (void) cleanupWriteStream;

- (void) timeoutReachability:(NSTimer *)timer;
- (void) scheduleReachability;
- (void) unscheduleReachability;

- (void) streamIsDisconnected:(YCStreamSessionGCD *)session;
#ifdef __cplusplus
extern "C" {
#endif
static void ReadStreamCallback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info);
static void WriteStreamCallback(CFWriteStreamRef writeStream, CFStreamEventType eventType, void *info);
static void NetworkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);
#ifdef __cplusplus
}// end extern "C"
#endif
@end

@implementation YCStreamSessionGCD
#pragma mark - synthesize properties
@synthesize	hostName;
@synthesize	portNumber;
@synthesize reachabilityValidating;
#pragma mark - class method
#pragma mark - constructor / destructor
- (id) initWithHostName:(NSString *)host andPort:(int)port
{
	self = [super init];
	if (self) {
		[self initializeMembers:host port:port];
		if ([self initializeHost] == NO)
			return nil;
		// end if initialize host is fail
	}// end if self can allocate
	
	return self;
}// end - (id) initWithhostName:(NSString *)server andPort:(NSUInteger)port

- (void) dealloc
{
	dispatch_release(sessionQueue);
	if (readStream != NULL)		[self closeReadStream];
	if (writeStream != NULL)	[self closeWriteStream];
	if (reachabilityHostRef != NULL)		CFRelease(reachabilityHostRef);
	reachabilityHostRef = NULL;
#if __has_feature(objc_arc)
	delegate = nil;
#else
	if (delegate != nil)		[delegate release];
	delegate = nil;
	if (delegateInfo != nil)	[delegateInfo release];
	
	[super dealloc];
#endif
}
#pragma mark - override
#pragma mark - delegate
#pragma mark - instance method
#pragma mark - properties
- (NSTimeInterval) timeout {	return timeout;	}
- (void) setTimeout:(NSTimeInterval)newTimeout
{
	timeout = newTimeout;
}// end - (void) setTimeout:(NSTimeInterval)newTimeout

- (id <YCStreamSessionGCDDelegate>) delegate	{	return delegate;	}
- (void) setDelegate:(id <YCStreamSessionGCDDelegate>)newDelegate
{
# if !__has_feature(objc_arc)
		// check and release current delegate
	if (delegate != self)
		[delegate autorelease];
		// end if
#endif
		// set delegate
	delegate = newDelegate;
#if !__has_feature(objc_arc)
	[delegate retain];
#endif
	delegateInfo = [[NSDictionary alloc] initWithObjectsAndKeys:self, keySelf, delegate, keyDelegate, nil];
	
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
	
	[self validateReachabilityAsync];
}// end - (void) setInputStreamDelegate:(id <InputStreamConnectionDelegate>)delegate

- (YCStreamDirection) direction {	return direction;	};
- (void) setDirection:(YCStreamDirection)newDirection
{		// split read stream and writes tream flag
	BOOL runReadStream = ((newDirection & YCStreamDirectionReadable) != 0) ? YES : NO;
	BOOL runWriteStream = ((newDirection & YCStreamDirectionWriteable) != 0) ? YES : NO;
	direction = newDirection;
	
		// reschedule read stream
	if (readStreamIsScheduled != runReadStream) {
		dispatch_async(sessionQueue, ^{
			if (runReadStream == YES)
				[self runReadStream];
			else
				[self suspendReadStream];
		});
	}// end if change read stream schedule status
		// reschedule write stream
	if (writeStreamIsScheduled != runWriteStream) {
		dispatch_async(sessionQueue, ^{
			if (runWriteStream == YES)
				[self runWriteStream];
			else
				[self suspendWriteStream];
		});
	}// end if change write stream schedule status
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

#pragma mark - actions
#pragma mark - messages
- (void) checkReadyToConnect
{
	[self validateReachabilityAsync];
}// end - (void) checkReadyToConnect

- (void) checkReadyToConnect:(ReachableHandler)handler
{
	
}// end - (void) checkReadyToConnect:(ReachableHandler)handler

- (BOOL) connect
{
	if (canConnect == NO)
		return NO;
		// end check ready to connect
	
	BOOL success = YES;
	@try {
		if ((direction & YCStreamDirectionReadable) != 0) {
			dispatch_async(sessionQueue, ^{
				[self runReadStream];
			});
		}
		if ((direction & YCStreamDirectionWriteable) != 0) {
			dispatch_async(sessionQueue, ^{
				[self runWriteStream];
			});
		}
	}
	@catch (NSError *error) {
		success = NO;
	}// end try - catch run read and write streams
	
	return success;
}// end - (void) connect

- (BOOL) reconnectReadStream
{
	if ((readStreamIsScheduled == YES) || ((direction & YCStreamDirectionReadable) == 0))
		return NO;
	
	BOOL success = YES;
	@try {
		dispatch_sync(sessionQueue, ^{
			[self runReadStream];
		});
	}
	@catch (NSError *err) {
		success = NO;
	}// end try - catch run read stream
	
	return success;
}// end - (BOOL) reconnectReadStream

- (void) closeReadStream
{
	if (readStreamIsScheduled == YES)
		dispatch_async(sessionQueue, ^{
			[self suspendReadStream];
		});
	// end close read stream
}// end - (void) closeReadStream

- (BOOL) reconnectWriteStream
{
	if ((writeStreamIsScheduled == YES) || ((direction & YCStreamDirectionWriteable) == 0))
		return NO;
	
	BOOL success = YES;
	@try {
		dispatch_async(sessionQueue, ^{
			[self runWriteStream];
		});
	}
	@catch (NSError *err) {
		success = NO;
	}// end try - catch run read stream
	
	return success;
}// end - (BOOL) reconnectReadStream

- (void) closeWriteStream
{
	if (writeStreamIsScheduled == YES)
		dispatch_sync(sessionQueue, ^{
			[self suspendWriteStream];
		});
	// end close write stream
}// end - (void) closeWriteStream

- (void) disconnect
{
	if (readStreamIsScheduled == YES) {
		dispatch_sync(sessionQueue, ^{
			[self suspendReadStream];
		});
	}// end close read stream
	
	if (writeStream != NULL) {
		dispatch_sync(sessionQueue, ^{
			[self suspendWriteStream];
		});
	}// end close write stream
}// end - (void) disconnect

- (void) terminate
{
	[self closeReadStream];
	[self cleanupReadStream];
	
	[self closeWriteStream];
	[self cleanupWriteStream];
}// end - (void) terminate

#pragma mark - private
- (void) initializeMembers:(NSString *)host port:(int)port
{
	hostName = [[NSString alloc] initWithString:host];
	portNumber = port;
	direction = YCStreamDirectionBoth;
	
	delegate = self;

	mustHandleReadStreamError = YES;
	mustHandleWriteStreamError = YES;
		
	sessionQueue = dispatch_queue_create(dispatchLabelName, DISPATCH_QUEUE_CONCURRENT);
}// end - (void) initializeMembers

- (BOOL) initializeHost
{
	BOOL success = YES;
		// create CFHostRef from server and port
#if __has_feature(objc_arc)
	CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef)hostName);
#else
	CFHostRef host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)hostName);
#endif
		// allocate target host/port’s read & write stream
	CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault, host, portNumber, &readStream, &writeStream);
	CFRelease(host);
	if ((readStream == NULL) || (writeStream == NULL))
		success = NO;
		// end if create read / write stream
	
	if (success == YES)
	{
#if __has_feature(objc_arc)
		SCNetworkReachabilityContext context = { 0, (__bridge void *)self, NULL, NULL, NULL };
#else
		SCNetworkReachabilityContext context = { 0, (void *)self, NULL, NULL, NULL };
#endif
		reachabilityHostRef = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [hostName UTF8String]);
		if (reachabilityHostRef != NULL)
			if (!SCNetworkReachabilitySetCallback(reachabilityHostRef, NetworkReachabilityCallBack, &context))
				success = NO;
			// end if set callback for reachability
			// end if hostref
	}// end if can create reachability ref
	
	if ((reachabilityHostRef == NULL) || (success == NO))
	{
		if (readStream != NULL)		CFRelease(readStream);
		if (writeStream != NULL)	CFRelease(writeStream);
		if (reachabilityHostRef != NULL)		CFRelease(reachabilityHostRef);
		reachabilityHostRef = NULL;
#if !__has_feature(objc_arc)
		[hostName release];
#endif
		hostName = nil;
		
		return NO;
	}// end if create stream was failed
	
	return YES;
}// end - (BOOL) initializeHost

#pragma mark - reachablity
- (void) validateReachabilityAsync
{		//
	canConnect = NO;
	dispatch_async(sessionQueue, ^{
		[self scheduleReachability];
	});
		// start timer if timeout is limited
	if (timeout != 0)
		[NSTimer scheduledTimerWithTimeInterval:timeout target:self selector:@selector(timeoutReachability:) userInfo:nil repeats:NO];
		// end if timeout timer need run
}// end - (void) validateReachabilityAsync

#pragma mark - read Stream
- (void) setupReadStream
{		// set property of read stream
	CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		// create StreamClient context
	CFStreamClientContext context =
#if __has_feature(objc_arc)
	{ 0, (__bridge void *)delegateInfo, NULL, NULL, NULL };
#else
	{ 0, (void *)delegateInfo, NULL, NULL, NULL };
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
	readStreamIsScheduled = YES;
    
    return;
}// end - (CFStreamError) runReadStream

- (void) suspendReadStream
{
	if ((readStreamIsScheduled == YES) && ((direction & YCStreamDirectionReadable) != 0))
		CFReadStreamUnscheduleFromRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		// end if
	readStreamIsScheduled = NO;
}// end - (void) suspendReadStream

- (void) cleanupReadStream
{
	CFReadStreamClose(readStream);
	CFRelease(readStream);
	readStream = NULL;
}// end - (void) releaeReadStream

#pragma mark - write Stream
- (void) setupWriteStream
{		// set property of write stream
	CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
		// create StreamClient context
	CFStreamClientContext context =
#if __has_feature(objc_arc)
	{ 0, (__bridge void *)delegateInfo, NULL, NULL, NULL };
#else
	{ 0, (void *)delegateInfo, NULL, NULL, NULL };
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
	writeStreamIsScheduled = YES;
    
    return;
}// end - (CFStreamError) runWriteStream

- (void) suspendWriteStream
{
	if ((writeStreamIsScheduled == YES) && ((direction & YCStreamDirectionWriteable) != 0))
		CFWriteStreamUnscheduleFromRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		// end if
	writeStreamIsScheduled = NO;
}// end - (void) suspendReadStream

- (void) cleanupWriteStream
{
	CFWriteStreamClose(writeStream);
	CFRelease(writeStream);
	writeStream = NULL;
}// end - (void) releaeReadStream

#pragma mark - handle reachability
- (void) timeoutReachability:(NSTimer *)timer
{
	dispatch_async(sessionQueue, ^{
		[self unscheduleReachability];
		canConnect = NO;
		[self streamReadyToConnect:self reachable:NO];
	});
}// end - (void) timeoutReachability:(NSTimer *)timer

- (void) scheduleReachability
{
	reachabilityValidating = YES;
	canConnect = NO;
	SCNetworkReachabilityScheduleWithRunLoop(reachabilityHostRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}// end - (void) scheduleReachability

- (void) unscheduleReachability
{
	SCNetworkReachabilityUnscheduleFromRunLoop(reachabilityHostRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	reachabilityValidating = NO;
}// end - (void) unscheduleReachability

#pragma mark - delegator methods
- (void) streamReadyToConnect:(YCStreamSessionGCD *)session reachable:(BOOL)reachable
{
	@try {
		[self setupReadStream];
		[self setupWriteStream];
	}
	@catch (NSException *exception) {
		@throw exception;
	}// end try-catch

	dispatch_sync(sessionQueue, ^{
		[self unscheduleReachability];
		canConnect = YES;
		
		[delegate streamReadyToConnect:self reachable:reachable];
	});
}// end - (void) streamReadyToConnect:(YCStreamSession *)session

#pragma mark - delegator process methods
- (void) streamIsDisconnected:(YCStreamSessionGCD *)session
{
	if ((delegate != self) && ([delegate respondsToSelector:@selector(streamIsDisconnected:stream:)] == YES))
		[delegate streamIsDisconnected:self stream:nil];
	else
		if (reachabilityValidating == NO)
			[self validateReachabilityAsync];
		// end if
		// end if
}// end - (void) streamIsDisconnected:(YCStreamSession *)session

#pragma mark - C functions

#pragma mark - delegate methods for input stream
- (void) readStreamHasBytesAvailable:(NSInputStream *)stream
{
}// end - (void) readStreamHasBytesAvailable:(NSInputStream *)stream

- (void) readStreamEndEncounted:(NSInputStream *)stream
{
	canConnect = NO;
	dispatch_async(sessionQueue, ^{
		[self closeReadStream];
	});
}// end - (void) readStreamEndEncounted:(NSStream *)readStream

- (void) readStreamErrorOccured:(NSInputStream *)stream
{
	canConnect = NO;
	dispatch_async(sessionQueue, ^{
		[self closeReadStream];
		if ([delegate respondsToSelector:@selector(streamIsDisconnected:stream:)] == YES)
			[delegate streamIsDisconnected:self stream:stream];
		else
			[self streamIsDisconnected:self];
		// end if check reachability
	});
}// end - (void) readStreamErrorOccured:(NSInputStream *)stream

- (void) readStreamOpenCompleted:(NSInputStream *)stream
{
}// end - (void) readStreamOpenCompleted:(NSInputStream *)stream

- (void) readStreamCanAcceptBytes:(NSInputStream *)stream
{
}// end - (void) readStreamCanAcceptBytes:(NSInputStream *)stream

- (void) readStreamNone:(NSInputStream *)stream
{
}// end - (void) readStreamNone:(NSStream *)readStream

#pragma mark - delegate methods for output stream
- (void) writeStreamCanAcceptBytes:(NSOutputStream *)stream
{
}// end - (void) writeStreamCanAcceptBytes:(NSInputStream *)stream

- (void) writeStreamEndEncounted:(NSOutputStream *)stream
{
	canConnect = NO;
	dispatch_async(sessionQueue, ^{
		[self closeWriteStream];
	});
}// end - (void) writeStreamEndEncounted:(NSStream *)stream

- (void) writeStreamErrorOccured:(NSOutputStream *)stream
{
	canConnect = NO;
	dispatch_async(sessionQueue, ^{
		[self closeWriteStream];
		if ([delegate respondsToSelector:@selector(writeStreamErrorOccured:)] == YES)
			[delegate writeStreamErrorOccured:stream];
		else
			[self streamIsDisconnected:self];
		// end if check reachability
	});
}// end - (void) writeStreamErrorOccured:(NSInputStream *)stream

- (void) writeStreamOpenCompleted:(NSOutputStream *)stream
{
}// end - (void) writeStreamOpenCompleted:(NSInputStream *)stream

- (void) writeStreamHasBytesAvailable:(NSOutputStream *)stream
{
}// end - (void) writeStreamHasBytesAvailable:(NSInputStream *)stream

- (void) writeStreamNone:(NSOutputStream *)stream
{
}// end - (void) writeStreamNone:(NSStream *)stream

#pragma mark - Core Foundation part
#pragma mark callback for read stream
static void
ReadStreamCallback(CFReadStreamRef readStream, CFStreamEventType eventType, void* info)
{
#if __has_feature(objc_arc)
	id iDelegator = [((__bridge NSDictionary *)info) objectForKey:keyDelegate];
	NSInputStream *rStream = (__bridge NSInputStream *)readStream;
#else
	id iDelegator = [((NSDictionary *)info) objectForKey:keyDelegate];
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
#if __has_feature(objc_arc)
			[[((__bridge NSDictionary *)info) objectForKey:keySelf] readStreamErrorOccured:rStream];
#else
			[[((NSDictionary *)info) objectForKey:keySelf] readStreamErrorOccured:rStream];
#endif
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

#pragma mark - callback for write stream
static void
WriteStreamCallback(CFWriteStreamRef writeStream, CFStreamEventType eventType, void *info)
{
#if __has_feature(objc_arc)
	id oDelegator = [((__bridge NSDictionary *)info) objectForKey:keyDelegate];
	NSOutputStream *wStream = (__bridge NSOutputStream *)writeStream;
#else
	id oDelegator = [((NSDictionary *)info) objectForKey:keyDelegate];
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
#if __has_feature(objc_arc)
			[[((__bridge NSDictionary *)info) objectForKey:keySelf] writeStreamErrorOccured:wStream];
#else
			[[((NSDictionary *)info) objectForKey:keySelf] writeStreamErrorOccured:wStream];
#endif
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
	YCStreamSessionGCD *mySelf = (__bridge YCStreamSessionGCD *)info;
#else
	YCStreamSessionGCD *mySelf = (YCStreamSessionGCD *)info;
#endif
	BOOL reachable = (flags != 0) ? YES : NO;
	[mySelf streamReadyToConnect:mySelf reachable:reachable];
}// end NetworkReachabilityCallBack(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info);
@end
