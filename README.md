#YCStreamSession
		This class handle a stream session to specified host and port by using NSInputStream and NSOutputStream.
	You can choose socket connection under main thread or specified thread.
		Easy care for network is rise and down, when your program is running.
	If happend it, YCStreamSession tell network is down and rise to you. 
* but now complete yet, now usable tag is Charleston0.3



## Useage
	Following contents describes how to use YSCStreamSession.

### Initialize
	Initialize for run under main thread.
	- (id) initWithHostName:(NSString *)host andPort:(int)port;
	or initialize for run under specified thread.
	- (id) initWithHostName:(NSString *)host andPort:(int)port onThread:(NSThread *)thread;

### Set timeout and direction
	You can set timeout for wait rise connection (optional).
	default timeout is infinit.
	- (void) setTimeOut:(NSTimeInterval)timeout;

	You can specify stream direction. (default both)
	- (void) setDirection:(YCStreamDirection)direction;
	- (YCStreamDirection)direction;
	But now direction only effective before set delegate object.

####Direction constants are
* YCStreamDirectionReadOnly
* YCStreamDirectionWriteOnly
* YCStreamDirectionBoth

### Set delegate object
	You must set delegate object supporting protocol YCStreamSessionDelegate
	- (void) setDelegate:
	When you send setDelegate: message, automatically validate specified host can reachable.
	You don’t need send checkReadyToConnect message in this phase.

### When setup compleated and can reach to the host or not
	Call your delegate method
	- (void) streamReadyToConnect:(YCStreamSession *)session reachable:(BOOL)reachable;
	reach’s value is YES means you can connect it, NO means can not reach to host because timeout.

	Timeout is no effect member of YCStream session.
	You can retry to check reachability by
	- (void) checkReadyToConnect;
	
###	Now you can call connect by
	- (BOOL) connect;
	If return NO, connection fail to run under specified thread.

### Connection control messages
	In any timming, you can disconnect / reconnect stream by described messages.
	But only effective are choosen direction only.
	- (void) closeReadStream;
	- (BOOL) reconnectReadStream;
	- (void) closeWriteStream;
	- (BOOL) reconnectWriteStream;

	Terminate connection is send message disconnect, it disconnect and cleanup socket.
	- (void) disconnect;
	If you want a reconnect after disconnect, you must create new YCStreamSession object.


### Delegate Methods
		After connection, call your delegate methods defined by
	protocol YCStreamSessionDelegate.

#### Required delegate methods for read stream
	- (void) readStreamHasBytesAvailable:(NSInputStream *)readStream;
	- (void) readStreamEndEncounted:(NSInputStream *)readStream;

#### Required delegate methods for write stream
	- (void) writeStreamCanAcceptBytes:(NSOutputStream *)writeStream;
	- (void) writeStreamEndEncounted:(NSOutputStream *)writeStream;

#### Optional delegate method for connection staus
	- (void) streamIsDisconnected(YCStreamSession *)stream;
	or you can handle this manually by i/writeStreamErrorOccured:

#### Optional delegate methods for read stream
	- (void) readStreamErrorOccured:(NSInputStream *)readStream;
	- (void) readStreamOpenCompleted:(NSInputStream *)readStream;
	- (void) readStreamCanAcceptBytes:(NSInputStream *)readStream;
	- (void) readStreamNone:(NSStream *)readStream;

#### Optional delegate methods for write stream
	- (void) writeStreamErrorOccured:(NSOutputStream *)writeStream;
	- (void) writeStreamOpenCompleted:(NSOutputStream *)writeStream;
	- (void) writeStreamHasBytesAvailable:(NSOutputStream *)writeStream;
	- (void) writeStreamNone:(NSOutputStream *)writeStream;

## License
	YCStreamSession is release under BSD clause 3 License

	Copyright (c) 2012-2013, Чайка
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
	
	Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
	Neither the name of the <ORGANIZATION> nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.