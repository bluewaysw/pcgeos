
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		escp2Setup.asm

AUTHOR:		

ROUTINES:
	Name			Description
	----			-----------
	PrintStartJob		Setup done at start of print job
	PrintEndJob		Cleanup done at end of print job

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/91		Initial revision


DESCRIPTION:
	This file contains various setup routines needed by Esc P2 printer 
	driver.
		

	$Id: escp2Setup.asm,v 1.1 97/04/18 11:54:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do pre-job initialization

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		carry	- set if some communication problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStartJob	proc	far
		uses	ax,bx,cx,dx,si,di,es,ds
		.enter

		; Make sure the port is really empty enough to accomidate the reset code
		; bytes.  We dont want it to block!

		mov	ds, bp			;point at PState.
		clr	ch
		mov	cl,pr_codes_ResetPrinter ;load the byte count.
checkagain:
		mov	di,DR_STREAM_QUERY
		mov	ax,STREAM_WRITE
		mov	bx,ds:[PS_streamToken]
		call	ds:[PS_streamStrategy]
		cmp	ax,cx			;see if the byte length of code is less
						;than available space.
		jle	checkagain		;check till the stream empties a little.

		; initialize the printer

		mov	si,offset pr_codes_ResetPrinter
		call	SendCodeOut
		

	; stop looking at the port for 1 sec.
	; this prevents silly pulses coming back on the SLCT' line and 
	; screwing up the port error detection.  If the printer is really off
	; line or in an error condition, the InitPrinter below will catch it.

		mov	ax,1*60
		call	TimerSleep

		; initialize some info in the PState

		clr	ax
		mov	ds:[PS_asciiSpacing], 12	; set to 1/6th inch
		mov	ds:[PS_asciiStyle], ax		; set to plain text
		mov	ds:[PS_xtraStyleInfo], al	; set to plain text
		mov	ds:[PS_cursorPos].P_x, ax	; set to 0,0 text
		mov	ds:[PS_cursorPos].P_y, ax

		; initialize the font

		call	PrInitFont

		; set no perforation skipping.

		mov	si,offset pr_codes_SetNoPerfSkip
		call	SendCodeOut

;setup the raster graphics mode for the medium and hi res modes.
		cmp	ds:PS_mode, PM_GRAPHICS_MED_RES
		je	setGraphicsMode
		cmp	ds:PS_mode, PM_GRAPHICS_HI_RES
		jne	exit
setGraphicsMode:
		mov	si,offset cs:pr_codes_SetRasterGraphics
		call	SendCodeOut

exit:
		.leave
		ret
PrintStartJob	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do post-job cleanup

CALLED BY:	GLOBAL

PASS:		bp	- segment of locked PState
		
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	07/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEndJob	proc	far
		uses	dx
		.enter
		
		; clear out any styles left over

		clr	dx		; no styles 
		call	PrintSetStylesInt
		clc			; no problems
		.leave
		ret
PrintEndJob	endp
