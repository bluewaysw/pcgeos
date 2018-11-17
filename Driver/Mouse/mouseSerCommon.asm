COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Mouse Driver Common Code
FILE:		mouseSerCommon.asm

AUTHOR:		Adam de Boor, Sep 25, 1989

ROUTINES:
	Name			Description
	----			-----------
	MouseOpenPort		Opens the desired port and returns its unit
				number.
	CallSer			Macro to contact the serial driver
	MouseClosePort		Close the port opened by MouseOpenPort
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/25/89		Initial revision


DESCRIPTION:
	Common definitions for mice that communicate via a serial port.
	
	This file should be included within the proper segment. E.g.
	if a driver has an init segment, this should be included in the
	init segment.

REQUIRED DEFINITIONS BEFORE INCLUSION:
	DEF_PORT		default port to open
	MOUSE_INBUF_SIZE	size of serial input buffer for mouse
	MOUSE_OUTBUF_SIZE	size of serial output buffer for mouse

	$Id: mouseSerCommon.asm,v 1.1 97/04/18 11:47:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UseDriver Internal/serialDr.def

include	initfile.def

;------------------------------------------------------------------------------
; 
;		VARIABLES REQUIRED BY ALL SERIAL MICE
;
;------------------------------------------------------------------------------
idata		segment
;
; Unit number of serial line we're using
;
mouseUnit	word	-1		; Unit we're employing

idata		ends

udata		segment
;
; Driver strategy routine for the serial driver
;
driver		fptr.far	; Strategy routine to call


;
; Macro to call the serial driver once  driver  has been loaded with the
; right value.
;
CallSer		macro	func, seg
		mov	di, func
ifnb <seg>
		call	seg:[driver]
else
		call	ds:[driver]
endif
		endm

udata		ends

Init		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseOpenPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the proper port for a mouse. DEF_PORT should be the
		default port to use if no -p flag given.

CALLED BY:	MouseDevInit (usually) or MousePortInit
PASS:		DS	= dgroup
RETURN:		BX	= open unit number or
		Carry set if couldn't open desired port.
		If carry clear:
		    driver	set to strategy routine for serial driver
		    mouseUnit	set to unit opened
DESTROYED:	AX, CX, DX, SI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
portCategory	char	MOUSE_CATEGORY, 0
portKey		char	MOUSE_PORT, 0
MouseOpenPort	proc	near
		;
		; Figure the driver strategy routine.
		;
		push	ds
		mov	bx, handle serial
		call	GeodeInfoDriver
		mov	ax, ds:[si].DIS_strategy.offset
		mov	bx, ds:[si].DIS_strategy.segment
		pop	ds

		mov	ds:driver.offset, ax
		mov	ds:driver.segment, bx

		;
		; See if user has specified an alternate port for the mouse.
		; The port is specified with the "mouse port" key in the
		; "system" category. The value should be an integer from
		; 1 to 4.
		; 
		push	ds, si
		mov	ax, DEF_PORT		; Assume default port
		push	ax			; Save it...
		segmov	ds, cs, cx		; ds & cx get segment of
						;  key strings
		mov	si, offset portCategory	; ds:si is category
		mov	dx, offset portKey	; cx:dx is key
		call	InitFileReadInteger	; Fetch integer -- alters AX if
						;  integer there, else returns
						;  it untouched?
		jc	useDefault
		inc	sp			; Discard saved default port
		inc	sp
		dec	ax			; Adjust to range 0-3
		cmp	ax, 4
		jae	useDefault		; Too big or too small -- ignore
		shl	ax			; Ports step by two...
		push	ax			; Save actual port
useDefault:
useDefaultNoClose:
		pop	bx			; Recover port to use
		pop	ds, si
		;
		; Open the port given in BX without blocking or timing out.
		; The buffer sizes used are specified by the includer of
		; this file.
		; 
		clr	ax		; block, no timeout
		mov	cx, MOUSE_INBUF_SIZE
		mov	dx, MOUSE_OUTBUF_SIZE
		mov	ds:mouseUnit, bx
		mov	si, handle 0	; We own this thing...
		CallSer	DR_SERIAL_OPEN_FOR_DRIVER
done:
		ret
MouseOpenPort	endp


Init		ends

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseClosePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down the port we opened

CALLED BY:	MousePortExit
PASS:		DS	= dgroup
RETURN:		Carry set if couldn't close the port (someone else was
			closing it (!)).
DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MouseClosePort	proc	far
	;
	; Close down the port...if it was ever opened, that is.
	;
		mov	bx, -1
		xchg	bx, ds:[mouseUnit]
		tst	bx
		js	done
		mov	ax, STREAM_DISCARD	; Just nuke output buffer
		CallSer	DR_STREAM_CLOSE
done:
		ret
MouseClosePort	endp

Resident	ends
