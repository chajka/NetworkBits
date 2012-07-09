//
//  SocketConnection.h
//  NicoLiveAlert
//
//  Created by Чайка on 3/31/12.
//  Copyright (c) 2012 iom. All rights reserved.
//

#import <Foundation/Foundation.h>
/*!
	@header Socket connection creator
	SocketConnection class is easy-to-use create and handle socket
	connection and event
	@copyright Чайка
	@updated 2012-04-03
*/

#define SocketConnectionNotificatonName		@"SocketConnectionNotificatonName"
#define SocketConnectionErrorNoficationName	@"SocketConnectionErrorNoficationName"

enum {
	SCDirectionNothing = 0U,
	SCDirectionListen = 1UL << 0,
	SCDirectionBroadcast = 1UL << 1,
	SCDirectionBoth = SCDirectionListen | SCDirectionBroadcast
};
typedef NSInteger SCDirection;

/*!
	@protocol SocketConnectionDelegate
	@discussion describes methods are called by stream event handler
	if you want call from event handler, you must set delegate object
	by @link setStreamEventDelegate: @/link
	this protocol is easy to use for stream event handling.
	If you want more tune up for time and so on, you must use
	@link setStreamDelegate @/link and implement stream event
	handling routine in your delegated class.
*/
@protocol StreamEventDelegate <NSObject>
@required
/*!
	@method streamEventErrorOccurred:
	@abstract The delegate receives this message when a given 
	NSStreamEventErrorOccurred has occurred on a given stream event.
	@param error occured stream.
*/
- (void) streamEventErrorOccurred:(NSStream *)stream;

/*!
	@method streamEventOpenCompleted:
	@abstract The delegate receives this message when a given 
	NSStreamEventOpenCompleted has occurred on a given stream event.
	@param open completed stream.
*/
- (void) streamEventOpenCompleted:(NSStream *)stream;
@optional
/*!
	@method streamEventHasBytesAvailable:
	@abstract The delegate receives this message when a given 
	NSStreamEventHasBytesAvailable has occurred on a given stream event.
	@param readble data readyed stream (maybe NSInputStream).
*/
- (void) streamEventHasBytesAvailable:(NSStream *)stream;

/*!
	@method streamEventHasSpaceAvailable:
	@abstract The delegate receives this message when a given 
	NSStreamEventHasSpaceAvailable has occurred on a given stream event.
	@param write data readyed stream (maybe NSOutputStream).
*/
- (void) streamEventHasSpaceAvailable:(NSStream *)stream;

/*!
	@method streamEventErrorOccurred:
	@abstract The delegate receives this message when a given 
	NSStreamEventErrorOccurred has occurred on a given stream event.
	@param end message recieved stream.
*/
- (void) streamEventEndEncountered:(NSStream *)stream;

/*!
	@method streamEventNone:
	@abstract The delegate receives this message when a given 
	NSStreamEventNone has occurred on a given stream event.
	@param no evented stream
*/
- (void) streamEventNone:(NSStream *)stream;
@end

/*!
	@class SocketConnection
*/
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
@interface SocketConnection : NSObject <NSStreamDelegate, StreamEventDelegate> {
	id <NSStreamDelegate>		streamDelegate;
#else
@interface SocketConnection : NSObject <StreamEventDelegate> {
	id							streamDelegate;
#endif
	id <StreamEventDelegate>	streamEventDelegate;
		// data stream
	__strong NSInputStream		*iStream;
	__strong NSOutputStream		*oStream;
	SCDirection					direction;
		// hold server information
	NSString					*server;
	NSInteger					port;
}
#if MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_5
@property (retain, readwrite)	id <NSStreamDelegate>		streamDelegate;
#else
@property (retain, readwrite)	id							streamDelegate;
#endif
@property (retain, readwrite)	id <StreamEventDelegate>	streamEventDelegate;
@property (assign, readwrite)	SCDirection					direction;
@property (copy, readwrite)		NSString					*server;
@property (assign, readwrite)	NSInteger					port;

/*!
	@method initWithServer:andPort:direction:
	@abstract return initialize completed with set server, port and direction
	SocketConnection object.
	@param server's name to whish connect.
	@param server's port no to whish connect.
	@param connnection direction by SCDirection.
	@result SocketConnection object
*/
- (id) initWithServer:(NSString *)server andPort:(NSInteger)port direction:(SCDirection)direction;

/*!
	@method connect
	@abstract connect to server by pointed member variables
	@result if connection succeed then YES, other NO.
*/
- (BOOL) connect;

/*!
	@method disconnect
	@abstract force disconnect from server
*/
- (void) disconnect;

/*!
 @method isInputStream:
 @abstract compare reciever and message object
 @param a stream want to be compare
 @result if same object then YES, other NO.
 */
- (BOOL) isInputStream:(NSStream *)stream;

/*!
 @method isOutputStream:
 @abstract compare reciever and message object
 @param a stream want to be compare
 @result if same object then YES, other NO.
 */
- (BOOL) isOutputStream:(NSStream *)stream;
@end

