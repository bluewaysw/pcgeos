COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Talk (Sample PC GEOS application)
FILE:		talk.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Insik	 8/92		Initial Version

DESCRIPTION:

	a crude "chat" application to demonstrate the Net Library and Comm
	Driver.
	to use the app, one must select the port and baud rate and open
	a connection before typing and sending messages

RCS STAMP:
	$Id: talk.asm,v 1.1 97/04/04 16:34:48 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def

include object.def
include graphics.def

include Objects/winC.def

; must include serialDr.def

UseDriver Internal/serialDr.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------
UseLib net.def
UseLib ui.def
UseLib Objects/vTextC.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

TalkProcessClass	class	GenProcessClass

MSG_TALK_SET_PORT		message
MSG_TALK_SET_RATE		message
MSG_TALK_OPEN_CONNECTION	message
MSG_TALK_CLOSE_CONNECTION	message
MSG_TALK_SEND_TEXT		message

TalkProcessClass	endc	;end of class definition

UNINITIALIZED			equ	8

idata	segment
	TalkProcessClass	mask CLASSF_NEVER_SAVED
				;this flag necessary because ProcessClass
				;objects are hybrid objects.

; * SerialPortInfo contains the baud rate and com port info necessary to 
; * open thee port 
	portInfo	SerialPortInfo <SERIAL_COM1, SB_19200>
	port		word		UNINITIALIZED
	socket		word		UNINITIALIZED
idata	ends

udata	segment
	textBuf		db 82 dup	(?)
udata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		talk.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for TalkProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	= TalkProcessClass object
		ds:di	= TalkProcessClass instance data
		ds:bx	= TalkProcessClass object (same as *ds:si)
		es 	= segment of TalkProcessClass
		ax	= message #
		cx 	= SerialPortNum
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPort	method dynamic TalkProcessClass, 
					MSG_TALK_SET_PORT
	uses	ax, cx, dx, bp
	.enter
	segmov	es,dgroup,ax
	mov	es:[portInfo].SPI_portNumber,cx
	.leave
	ret
SetPort	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBaud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		*ds:si	= TalkProcessClass object
		ds:di	= TalkProcessClass instance data
		ds:bx	= TalkProcessClass object (same as *ds:si)
		es 	= segment of TalkProcessClass
		ax	= message #
		cx	= SerialBaud
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBaud	method dynamic TalkProcessClass, 
					MSG_TALK_SET_RATE
	uses	ax, cx, dx, bp
	.enter
	segmov	es,dgroup,ax
	mov	es:[portInfo].SPI_baudRate,cx
	.leave
	ret
SetBaud	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open port/socket, etc

CALLED BY:	
PASS:		*ds:si	= TalkProcessClass object
		ds:di	= TalkProcessClass instance data
		ds:bx	= TalkProcessClass object (same as *ds:si)
		es 	= segment of TalkProcessClass
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OpenConnection	method dynamic TalkProcessClass, 
					MSG_TALK_OPEN_CONNECTION
	uses	ax, cx, dx, bp
	.enter
	call	CloseCurrentConnection
; call init procedures, first open the port
	segmov	ds, es, si
	mov	si, offset portInfo
	mov	cx, size SerialPortInfo
	call	NetMsgOpenPort			; bx - port token
	jc	exit
	mov	es:[port], bx
	GetResourceHandleNS	ReceiveTextDisplay, bx
	mov	si, bx
	mov	bx, es:[port]
; when we supply the callback address, we use a virtual segment so that
; the code doesn't have to reside in fixed memory
	push	ds
	mov	dx, vseg ReceiveTextCallback
	mov	ds, dx
	mov	dx, offset cs:ReceiveTextCallback
	mov	cx, SID_TALK			;Our ID and the dest ID
	mov	bp, cx				; are the same
	call	NetMsgCreateSocket		; ax - socket token
	mov	es:[socket], ax
	pop	ds
exit:	.leave
	ret
OpenConnection	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_TALK_CLOSE_CONNECTION
PASS:		*ds:si	= TalkProcessClass object
		ds:di	= TalkProcessClass instance data
		ds:bx	= TalkProcessClass object (same as *ds:si)
		es 	= segment of TalkProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseConnection	method dynamic TalkProcessClass, 
					MSG_TALK_CLOSE_CONNECTION
	uses	ax, cx, dx, bp
	.enter
	call	CloseCurrentConnection
	.leave
	ret
CloseConnection	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseCurrentConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close current connection

CALLED BY:	OpenConnection, CloseConnection
PASS:		es - dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	1/29/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseCurrentConnection	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	cmp	es:[port], UNINITIALIZED
	je	exit			; already closed
	mov	bx, es:[port]
	mov	dx, es:[socket]
	call	NetMsgDestroySocket
	call	NetMsgClosePort	
	mov	es:[port], UNINITIALIZED
	mov	es:[socket], UNINITIALIZED
exit:	.leave
	ret
CloseCurrentConnection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send text

CALLED BY:	UI
PASS:		*ds:si	= TalkProcessClass object
		ds:di	= TalkProcessClass instance data
		ds:bx	= TalkProcessClass object (same as *ds:si)
		es 	= segment of TalkProcessClass
		ax	= message #
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendText	method TalkProcessClass, MSG_TALK_SEND_TEXT
	uses	ax, cx, dx, bp
	.enter
	segmov	ds,dgroup,ax
; get the string.
	GetResourceHandleNS	EntryDisplay, bx
	mov	si, offset EntryDisplay
	mov	ax,MSG_VIS_TEXT_GET_ALL_PTR
	mov	dx,ds
	mov	bp,offset textBuf		;dx:bp - string
	mov	di, mask MF_CALL
	call	ObjMessage			; cx - str length
	push	ds,bp
	add	bp, cx
	mov	ds,dx
	mov	{byte} ds:[bp], 13
	pop	ds,bp
	inc 	cx
; display it in our Send Window
	GetResourceHandleNS	SendTextDisplay, bx
	mov	si, offset SendTextDisplay
	mov	ax,MSG_VIS_TEXT_APPEND_PTR
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
; now send it across the port
	mov	bx, ds:[port]
	mov	dx, ds:[socket]
	mov	si, offset textBuf		; ds:si - string
	call	NetMsgSendBuffer
; erase the Entry Display
	GetResourceHandleNS	EntryDisplay, bx
	mov	si, offset EntryDisplay
	mov	ax,MSG_VIS_TEXT_DELETE_ALL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	.leave
	ret
SendText	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReceiveTextCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take buffer and append it

CALLED BY:	Server
PASS:		ds:si - buffer
		cx - size
		dx - data passed from remote side
		di - resource handle for ReceiveTextDisplay		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

This code is called by the COMM driver's server thread, so whatever it does,
it should be quick about it.  Most programs will have its own "dispatch 
thread" which will get called with the buffer.  Also, the buffer will be
erased once execution returns to the server thread.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReceiveTextCallback	proc	far
	uses	bp,ds,es
	.enter
	jcxz	exit
	cmp	cx, SOCKET_HEARTBEAT
	jz	exit
	mov	bx,di
	mov	dx,ds
	mov	bp,si				;dx:bp - string
	mov	si, offset ReceiveTextDisplay
	mov	ax,MSG_VIS_TEXT_APPEND_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
exit:	.leave
	ret
ReceiveTextCallback	endp


CommonCode	ends		;end of CommonCode resource



