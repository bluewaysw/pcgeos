
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Canon 64-pin print drivers
FILE:		graphicsHiRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/92		Initial revision


DESCRIPTION:

	$Id: graphicsHiRedwood.asm,v 1.1 97/04/18 11:51:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrPrintHighBand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Used to print a 64 pin High resolution band. (non-interleaved)
	Usually used to print a 360dpi resolution band.
	Loads a HI_RES_BUFF_HEIGHT buffer of the desired width from the input
	bitmap data.  
	Bit 7 is the top bit of the rotated data.
	leaves newScanNumber pointing at the second to last line so that the 
	Canon overlapping method happens.

CALLED BY:
	PrPrintABand

PASS:
	PS_newScanNumber pointing at top of this band
	es	=	segment of PState
	dx	=	number of scanlines hi to load and print.

RETURN:
	PS_newScanNumber pointing at top of next band

DESTROYED:
	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrPrintHighBand	proc	near
	uses	ax,bx,cx,dx,di
curBand	local	BandVariables
	.enter

		;Move the printhead down to the next band on the page.
	push	dx
	mov	dx,es:[PS_redwoodSpecific].RS_yOffset
	or	dx,dx			;see if no offset.
	clc
	jz	weArePositioned		;if no different, skip move.
	push	bp
	mov	bp,es
	call	PrintWaitForMechanism	;wait for the printer to stop.
	pop	bp
	jc	weArePositioned		;adjust stack, exit error.
testAgain:
        mov     si,offset pr_codes_GetPaperRemaining
        call    SendCodeOut
	jc	weArePositioned		;adjust stack, exit error.
        mov     ax,1
        call    TimerSleep              ;wait for things to get loaded.
	call	StatusPacketIn
	jc	weArePositioned		;adjust stack, exit error.
        cmp     es:[PS_redwoodSpecific].RS_status.RSB_length,3
        jne     testAgain
        cmp     es:[PS_redwoodSpecific].RS_status.RSB_ID,21h
        jne     testAgain
        mov     al,es:[PS_redwoodSpecific].RS_status.RSB_parameters
        mov     ah,es:[PS_redwoodSpecific].RS_status.RSB_parameters+1
	cmp	ax,720			;do nothing to stop feed if we are
	ja	linefeedHere		;farther away than 2"
	cmp	ax,dx			;do no printing, if closer than the 
	ja	linefeedHere		;linefeed amount.
	pop	dx			;adjust stack
	jmp	exitOK
linefeedHere:
	call	PrLineFeed		;start in the right place.
weArePositioned:
	pop	dx
	jc	exit

bandService:
	mov	curBand.BV_scanlines,dl
	mov	ax,es:[PS_newScanNumber] ;set the band start for this band.
	mov	curBand.BV_bandStart,ax

	call	PrClearBandBuffer	;zero the buffer.
	call	PrLoadBandBuffer	;fill the bandBuffer
	call	PrScanBandBuffer	;determine live print width.
	mov	cx,dx			;cl = lo byte count value.
	jcxz	adjustScanNumber	;if no data, just exit.
	call	PrintWaitTillReady	;wait for the previous buffer to go.
	jc	exit			;propogate errors out.
	cmp	es:PS_mode,PM_GRAPHICS_LOW_RES ;see if hi res mode...
	je	itsLowRes
	call	PrRotate64Lines		;send this band.
	jc	exit			;propogate errors out.
	jmp	adjustScanNumber
itsLowRes:
	call	PrRotate64LinesMulX	;send this band.
	jc	exit			;propogate errors out.

adjustScanNumber:
	sub	es:[PS_newScanNumber],BAND_OVERLAP_AMOUNT
					;set back the overlapp amount
exitOK:
	clc
exit:
	.leave
	ret
PrPrintHighBand	endp
