#YCStreamSession
		This class handle a stream session to specified host and port.
	using NSInputStream and NSOutputStream.
	You can choose socket connection under main thread or specified thread.
		Do not warry network is down, when yor program is running.
	If happend it, YCStreamSession handle network is down and rise. 
* but now complete yet, now usable tag is Charleston0.3


## useage
	Following contents describes how to use YSCStreamSession.

### Initialize
	Initialize for run under main thread.
	- (id) initWithHostName:(NSString *)host andPort:(int)port
	or initialize for run under specified thread.
	- (id) initWithHostName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread;

### Set direction
	You can specify stream direction. (default both)
	- (void) setDirection:(YCStreamDirection)direction;
	- (YCStreamDirection)direction;
	Direction constants are
		YCStreamDirectionReadOnly
		YCStreamDirectionWriteOnly
		YCStreamDirectionBoth

### Set delegate (and timeout, if needed)
	You may call (optional), default timeout is infinit.
	- (void) setTimeOut:
	and you must call
	- (void) setDelegate:

### When setup compleated and can reach to the host
	Call your delegate method
	- (void) streamReadyToConnect:(YCStreamSession *)session;
	from YCStreamSession.

###	Now you can call connect by
	- (void) connect;

### Connection control methods
	In any timming, you can disconnect / reconnect stream by described methods.
	- (void) disconnect;
	- (void) closeReadStream;
	- (BOOL) reconnectReadStream;
	- (void) closeWriteStream;
	- (BOOL) reconnectWriteStream;

### Delegate Methods
		After connection, call your delegate methods defined by
	protocol YCStreamSessionDelegate.

#### Required delegate methods for read from stream
	- (void) readStreamHasBytesAvailable:(NSInputStream *)readStream;
	- (void) readStreamEndEncounted:(NSInputStream *)readStream;

#### Required delegate methods for write to stream
	- (void) writeStreamCanAcceptBytes:(NSOutputStream *)writeStream;
	- (void) writeStreamEndEncounted:(NSOutputStream *)writeStream;

#### Optional delegate method for connection staus
	- (void) streamIsDisconnected(YCStreamSession *)stream;
	or you can handle this manually by i/writeStreamErrorOccured:

#### Optional delegate methods for read from stream
	- (void) readStreamErrorOccured:(NSInputStream *)readStream;
	- (void) readStreamOpenCompleted:(NSInputStream *)readStream;
	- (void) readStreamCanAcceptBytes:(NSInputStream *)readStream;
	- (void) readStreamNone:(NSStream *)readStream;

#### Optional delegate methods for write to stream
	- (void) writeStreamErrorOccured:(NSOutputStream *)writeStream;
	- (void) writeStreamOpenCompleted:(NSOutputStream *)writeStream;
	- (void) writeStreamHasBytesAvailable:(NSOutputStream *)writeStream;
	- (void) writeStreamNone:(NSOutputStream *)writeStream;
