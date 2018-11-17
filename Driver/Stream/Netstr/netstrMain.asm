COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Stream Drivers -- Output-only Parallel port
FILE:		netstrMain.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/27/92		Initial version 

DESCRIPTION:

	$Id: netstrMain.asm,v 1.1 97/04/18 11:46:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include		netstr.def

;------------------------------------------------------------------------------
;	Driver info table
;------------------------------------------------------------------------------

idata		segment

DriverTable	DriverInfoStruct	<
	NetstreamStrategy, mask DA_CHARACTER, DRIVER_TYPE_STREAM
>

idata		ends
 
Resident	segment	resource

;-----------------------------------------------------------------------------
;	Escape table		
;-----------------------------------------------------------------------------
 

DefEscapeTable	1

DefEscape	NetstreamLoadOptions, STREAM_ESC_LOAD_OPTIONS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	NetstreamStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for all parallel-driver functions

CALLED BY:	GLOBAL
PASS:		di	= routine number
		bx	= open port number (usually)
RETURN:		depends on function, but an ever-present possibility is
		carry set with AX = STREAM_CLOSING or STREAM_CLOSED
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb  10/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetstreamStrategy proc	far

		tst	di
		js	handleEscape
		cmp	di, DR_STREAM_CLOSE
		je	closeStream
		GOTO	ParallelStrategy		; <- EXIT

handleEscape:
		GOTO	NetstreamEscape			; <- EXIT

closeStream:
	;
	; Call the parallel driver first
	;
		call	ParallelStrategy
		
	;
	; End the capture
	;

		mov	bx, PARALLEL_LPT3
		call	NetPrintEndCapture
		ret					; <- EXIT

NetstreamStrategy endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetstreamEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute some escape function

CALLED BY:	GLOBAL

PASS:		di	- escape code (ORed with 8000h)

RETURN:		di	- set to 0 if escape not supported
			- return unchanged if handled

DESTROYED:	see individual functions

PSEUDO CODE/STRATEGY:
		scan through the table, find the code, call the handler.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb 9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NetstreamEscape	proc	far

		push	di, cx, ax, es		; save a few regs
		segmov	es, cs		; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset escCodes ; si -> esc code tab
		mov	cx, NUM_ESC_ENTRIES ; init rep count
		repne	scasw		; find the right one
		pop	ax, es
		jne	notFound	;  not in table, quit

		; function is supported, call through vector

		pop	cx
		call	{word} cs:[di+((offset escRoutines)-(offset escCodes)-2)]
		pop	di
		ret

		; function not supported, return di==0
notFound:
		pop	cx		; restore stack
		pop	di
		clr	di		; set return value
		ret
NetstreamEscape	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetstreamLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read in options from the .INI file, and initialize
		properly. 

CALLED BY:	NetstreamEscape

PASS:		ds:si - initfile category from which to read options.

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
queueKeyString	char	"queue",0

NetstreamLoadOptions	proc near
	uses	ax,bx,cx,dx,di,si,bp,es
	.enter

	mov	bp, size NetObjectName
	sub	sp, bp		
	mov	di, sp
	segmov	es, ss			; es:di - buffer for name

	;
	; Get queue name
	;

	mov	cx, cs
	mov	dx, offset queueKeyString
	call	InitFileReadString

	;
	; Use LPT3, as a physical port isn't likely to exist on most
	; machines, so we shouldn't get a conflict.  For those
	; machines that DO have an LPT3, too fucking bad...
	;

	mov	bx, PARALLEL_LPT3
	mov	cx, es
	mov	dx, di
	call	NetPrintStartCapture

	add	sp, size NetObjectName

	.leave
	ret
NetstreamLoadOptions	endp


Resident	ends
