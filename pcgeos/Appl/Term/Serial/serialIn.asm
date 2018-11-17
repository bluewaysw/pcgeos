COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GeoComm
MODULE:		Serial
FILE:		serialIn.asm (serial thread initialization code)

AUTHOR:		Dennis Chow, September 6, 1989

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dc      9/6/89		Initial revision.
	eric	9/90		documentation update

DESCRIPTION:
	This file contains routines which are used in initializing the
	Serial thread (thread #1 of GeoComm). This thread's role
	is to run the SerialReaderClass object, which receives incoming
	characters from the Stream driver.

	$Id: serialIn.asm,v 1.1 97/04/04 16:55:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitThreads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a thread which will run a SerialReaderClass object,
		which will grab serial input from the stream driver,
		and forward the input on to either:

			script code
			FSM code
			file transfer code

CALLED BY:	InitComUse in Serial/serialMain.asm

PASS:		ds	- dgroup

RETURN:		carry set - error: couldn't allocate memory error or use port

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	10/25/89	Initial version
	eric	9/90		doc update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitThreads	proc	near

EC <	call	ECCheckDS_dgroup					>

						;Start up input thread
	mov	al, PRIORITY_FOCUS		;set priority > STANDARD
	mov	bp, ds:[termProcHandle]		;pass handle for parent process.
	clr	bx				;no value to pass

	mov	cx, segment SerialInThread	;pass cx:dx = init routine
	mov	dx, offset SerialInThread	;(see below)
	clr	si	
	mov	di, 2000			;allocate a smaller stack
	call	ThreadCreate			;start thread
	jc	exit				;skip if error...

	;wait for serial thread to come fully to life (this semaphore is
	;V-ed by SerialAttach, the handler for MSG_META_ATTACH in
	;SerialReaderClass.)

EC <	call	ECCheckDS_dgroup					>

	PSem	ds, startSem

	mov	ds:[threadHandle], bx		;store thread handle
						; now the thread is fully there
	clc					; ...and indicate success
exit:
	ret
InitThreads	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConnectPortToThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the port so it sends methods to the input thread

CALLED BY:	OpenComPort (Serial/serialMain.asm)

PASS:		ds = dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	08/03/90	Initial version
	eric	9/90		doc update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConnectPortToThread	proc	near

EC <	call	ECCheckDS_dgroup					>

	;call the STREAM_SET_NOTIFY strategy routine in the Stream driver,
	;indicating that this thread should be notified with a
	;MSG_READ_DATA when the Stream driver has a buffer of incoming
	;characters which must be unloaded.

	mov	cx, ds:[threadHandle]		;cx:dx - address of handling
	clr     dx				;	routine
	mov     ax, StreamNotifyType <1,SNE_DATA,SNM_MESSAGE>
	mov     bp, MSG_READ_DATA
	mov     bx, ds:[serialPort]
	CallSer DR_STREAM_SET_NOTIFY

	;set the threshold for such notification: even if there is only
	;one byte of input data, we want to know about it.

	mov     ax, STREAM_READ
	mov     cx, byte
	CallSer DR_STREAM_SET_THRESHOLD
	ret
ConnectPortToThread	endp

Fixed segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialInThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This initialization routine is called by ThreadCreate
		as it creates a new thread (see InitThreads).

CALLED BY:	ThreadCreate (kernal function)

PASS:		ds	- dgroup		

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	 8/24/89	Initial version
	eric	9/90		doc update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialInThread	proc	far

EC <	call	ECCheckDS_dgroup					>

	;allocate a queue for object which will be run by this thread

	mov	cx, ds
	mov     dx, offset SerialReaderClass
	call    GeodeAllocQueue

	;send a MSG_META_ATTACH to this object, so it can initialize itself.

	mov	ax, MSG_META_ATTACH
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;attach this new thread to the queue we just created. Further
	;execution will be in response to methods placed on the queue.

	call    ThreadAttachToQueue

	;NOT REACHED
	ret
SerialInThread	endp

Fixed ends
