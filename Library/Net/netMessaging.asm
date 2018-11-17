COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		netMessaging.asm

AUTHOR:		In Sik Rhee, Oct 21, 1992

ROUTINES:
	Name			Description
	----			-----------

	*NetMsgOpenPort		Open port for send/receive (COM only)
	*NetMsgClosePort	Close port
	*NetMsgCreateSocket	Create socket for listening
	*NetMsgDestroySocket	Destroy socket
	*NetMsgSendBuffer	Send buffer to socket (broadcast?)
	*NetMsgSetTimeOut	Set timeout value for packets (COM only?)
	 NetMsgSetMainSocketStatus	Set messaging on/off
	 NetMsgGetMainSocketStatus	Get status of messaging
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92	Initial revision


DESCRIPTION:
	
	Net Library routines to handle Messaging between hosts

	$Id: netMessaging.asm,v 1.1 97/04/05 01:24:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetCommonCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetMsgOpenPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens a port (domain) for 2-way communication.  Creates a
		server thread for the port if no server exists.  

CALLED BY:	EXTERNAL
PASS:		ds:si - buffer with port information 
			(e.g. SerialPortInfo structure for serial ports)
		cx    - size of buffer
RETURN:		carry set if error, ax - error code
		bx - port token
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:	
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetMsgOpenPort	proc	far
	.enter
	mov	al, NMF_OPEN_PORT
	mov	di, DR_NET_MESSAGING
	call	NetCallDriver
	.leave
	ret
NetMsgOpenPort	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetMsgClosePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a 2-way communication port.  

CALLED BY:	EXTERNAL
PASS:		bx - port token
RETURN:		carry set if error, ax - error code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetMsgClosePort	proc	far
	.enter
	mov	al, NMF_CLOSE_PORT		
	mov	di, DR_NET_MESSAGING
	call	NetCallDriver
	.leave
	ret
NetMsgClosePort	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetMsgCreateSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a socket for the port.  Callback routine is called 
		when a packet is received for the socket.  if 0 is passed
		as offset of callback, then the incoming messages are put 
		into a message queue.  To fetch the handle of the message
		buffer, the app can P the returned semaphore
	In general, a single-threaded app will rely on the callback method
	(*important* the callback routine must be very fast and return 
	quickly, otherwise other packets coming into the port may be lost!)
	and multi-threaded apps are encouraged to use the message queue 
	(a dedicated dispatch thread should be routinely P'ing the semaphore
	and processing messages as they come in)  Also note: it is not a 
	good idea to let messages 'sit around' in the queue, as it's limited
	in size, and will overflow if too many messages are waiting in it.
	One queue exists for each socket that requests it.

	when the socket is being destroyed, the callback routine will be 
	called with cx = 0

CALLED BY:	EXTERNAL
PASS:		bx 	- port token
		cx 	- socket ID (unique # chosen by caller)
		bp	- dest ID (ID # of socket to connect with)
		ds:dx 	- callback routine (dx - 0 if using message queue)
			  ds shoud be a vseg for XIP'ed geodes.
		si 	- data to pass to callback 
RETURN:		carry set if error, ax - error code
		ax	- socket token
		bx 	- semaphore (if dx = 0)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

Callback routine:

	Pass:
		ds:si	- buffer
		cx	- size
			  cx = 0 when socket is being destroyed.
		di	- data passed from NetMsgCreateSocket (si)
	Return: nothing
	Destroy: ax,bx,cx,dx,di,si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetMsgCreateSocket	proc	far
	.enter
	mov	al, NMF_CREATE_SOCKET	
	mov	di, DR_NET_MESSAGING
	call	NetCallDriver
	.leave
	ret
NetMsgCreateSocket	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetMsgDestroySocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys specified socket.  also calls callback with carry set
		to notify destruction

CALLED BY:	EXTERNAL
PASS:		bx	- port token
		dx 	- socket token
RETURN:		carry set if error, ax - error code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetMsgDestroySocket	proc	far
	.enter
	mov	al, NMF_DESTROY_SOCKET
	mov	di, DR_NET_MESSAGING
	call	NetCallDriver
	.leave
	ret
NetMsgDestroySocket	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetMsgSendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send buffer across port/socket

CALLED BY:	EXTERNAL
PASS:		bx	- port token
		dx	- socket token
		cx	- size of buffer
		bp 	- AppID: app specific word of data passed to receiver
		ds:si	- buffer
RETURN:		carry set if error, ax - error code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetMsgSendBuffer	proc	far
	.enter
	mov	al, NMF_CALL_SERVICE	
	mov	di, DR_NET_MESSAGING
	call	NetCallDriver
	.leave
	ret
NetMsgSendBuffer	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetMsgSetTimeOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set Timeout value (1/60 seconds) for a socket
		[Timeout value = amount of time the socket should wait for
		 an acknowledgement after a packet is sent to the remote 
		 machine]

CALLED BY:	EXTERNAL
PASS:		bx	- port token
		dx	- socket token
		cx 	- timeout value
RETURN:		carry set if error, ax - error code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetMsgSetTimeOut	proc	far
	.enter
	mov	al, NMF_SET_TIMEOUT
	mov	di, DR_NET_MESSAGING
	call	NetCallDriver
	.leave
	ret
NetMsgSetTimeOut	endp


NetCommonCode	ends
