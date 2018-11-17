COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netPrint.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/23/92   	Initial version.

DESCRIPTION:
	Functions for the printing module of the net library.	

	$Id: netPrint.asm,v 1.1 97/04/05 01:25:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintStartCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	begin a "capture" of a parallel port to the specified 
		queue

CALLED BY:	GLOBAL

PASS:		bx - ParallelPortNum
		cx:dx - name of queue

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintStartCapture	proc far
	mov	al, NPF_START_CAPTURE
	GOTO	NetCallPrintFunction
NetPrintStartCapture	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintCancelCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel capture of the specified LPT port

CALLED BY:	GLOBAL

PASS:		bx - ParallelPortNum

RETURN:		nothing 

DESTROYED:	ax 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintCancelCapture	proc far
	mov	al, NPF_CANCEL_CAPTURE
	GOTO	NetCallPrintFunction
NetPrintCancelCapture	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintFlushCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush capture of the LPT port, but keep the capture
		active. 

CALLED BY:	GLOBAL

PASS:		bx - ParallelPortNum

RETURN:		nothing 

DESTROYED:	ax 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintFlushCapture	proc far
	mov	al, NPF_FLUSH_CAPTURE
	GOTO	NetCallPrintFunction
NetPrintFlushCapture	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintEndCapture
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End capture to the specified port, and flush the data

CALLED BY:	GLOBAL

PASS:		bx - ParallelPortNum

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintEndCapture	proc far
	mov	al, NPF_END_CAPTURE
	GOTO	NetCallPrintFunction
NetPrintEndCapture	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintEnumPrintQueues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate all the print queues available over the
		network(s) to which this workstation is attached

CALLED BY:	GLOBAL

PASS:		ss:bp - NetEnumParams
		if chunk-array requested:
			ds- segment of lmem block in which to place array

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintEnumPrintQueues	proc far
	.enter
	mov	di, DR_NET_PRINT_FUNCTION
	mov	al, NPF_ENUM_PRINT_QUEUES
	call	NetEnum
	.leave
	ret
NetPrintEnumPrintQueues	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintGetCaptureQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the name of the queue to which the specified
		port is being captured

CALLED BY:	GLOBAL

PASS:		bx - ParallelPortNum
		ds:si - buffer for queue name (must be at LEAST
		NET_OBJECT_NAME_SIZE)

RETURN:		if error
			carry set
			ax - NetError
		else
			carry clear
			ds:si - filled in (null string if there's no
				capture on the specified port)


DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintGetCaptureQueue	proc far
	mov	al, NPF_GET_CAPTURE_QUEUE
	GOTO	NetCallPrintFunction
NetPrintGetCaptureQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetCallPrintFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	byte-saving utility routine

CALLED BY:	NetPrintGetCaptureQueue, NetPrintStartCapture,
		NetPrintFlushCapture, NetPrintEndCapture 

PASS:		al - NetPrintFunction

RETURN:		nothing 

DESTROYED:	if error
			carry set
			ax - NetError
		else
			carry clear


PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetCallPrintFunction	proc far
	uses	di
	.enter
	mov	di, DR_NET_PRINT_FUNCTION
	call	NetCallDriver
	.leave
	ret
NetCallPrintFunction	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintSetBanner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the banner text for all subsequent print jobs

CALLED BY:	GLOBAL

PASS:		ds:si - fptr to null-terminated banner text

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintSetBanner	proc far
		uses	ax
		.enter

		mov	al, NPF_SET_BANNER
		call	NetCallPrintFunction

		.leave
		ret
NetPrintSetBanner	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintGetBanner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the banner text

CALLED BY:	GLOBAL

PASS:		ds:si - buffer of at least NetBannerText size

RETURN:		buffer filled in

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintGetBanner	proc far
		uses	ax
		.enter

		mov	al, NPF_GET_BANNER
		call	NetCallPrintFunction

		.leave
		ret
NetPrintGetBanner	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintSetBannerStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default banner status

CALLED BY:	GLOBAL

PASS:		ax - TRUE/FALSE

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintSetBannerStatus	proc far
		uses	ax,bx
		.enter
		mov_tr	bx, ax
		mov	al, NPF_SET_BANNER_STATUS
		call	NetCallPrintFunction

		.leave
		ret
NetPrintSetBannerStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintGetBannerStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the default banner status (whether banner
		printing is ON or OFF)

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		ax - TRUE/FALSE

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintGetBannerStatus	proc far
		uses	bx
		.enter

		mov	al, NPF_GET_BANNER_STATUS
		call	NetCallPrintFunction
		mov_tr	ax, bx

		.leave
		ret
NetPrintGetBannerStatus	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintSetTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the capture timeout.  

CALLED BY:	GLOBAL

PASS:		ax - timeout

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/27/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintSetTimeout	proc far
		uses	ax,bx
		.enter
		mov_tr	bx, ax
		mov	al, NPF_SET_TIMEOUT
		call	NetCallPrintFunction

		.leave
		ret
NetPrintSetTimeout	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetPrintGetTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the capture timeout value

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		ax - timeout

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/27/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetPrintGetTimeout	proc far
		uses	bx
		.enter

		mov	al, NPF_GET_TIMEOUT
		call	NetCallPrintFunction
		mov_tr	ax, bx

		.leave
		ret
NetPrintGetTimeout	endp




NetCommonCode	ends
