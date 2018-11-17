COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		NIKE print drivers
FILE:		cursorPrLineFeedNike.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	10/94		Initial revision


DESCRIPTION:

	$Id: cursorPrLineFeedNike.asm,v 1.1 97/04/18 11:49:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check paper status while doing vertical line feed

CALLED BY:	Jump Table
PASS:		es = segment of PState
		dx = length, in <printer units>" to line feed.
RETURN:		carry - set if some transmission error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	6/ 1/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrLineFeed      proc    near
	uses    ax,cx,dx
	.enter

	; Check to see if we need to look at paper out sensor.

	push	dx
	mov	dx, es:[PS_customHeight]
	clr	ax
	call	PrConvertToDriverCoordinates
	mov	cx, dx
	pop	dx

	sub	cx, PAPER_DETECT_MARGIN + PAPER_DETECT_TOP_MARGIN
	sub	cx, es:PS_cursorPos.P_y
	jl	afterPaperCheck			;already past paper out point

	; Check paper here.

	call	PrWaitForMechanismLow
	jc	exit

	mov	al, PJLP_noupdate
	call	PrintGetErrorsLow
	test	ax, mask PER_PES		;do we still have paper?
	jnz	paperError			;error if no paper

	; Is this linefeed is going to move us past the paper out point.

	cmp	cx, dx
	jge	afterPaperCheck			;skip if not

	; This linefeed is going to move us past the paper out point.
	; We're going to do the linefeed in 2 steps.  Linefeed down to paper
	; out point, check paper, then linefeed the rest.  But we have to
	; avoid doing linefeeds of < NIKE_MINIMUM_LINE_FEED.

	cmp	cx, NIKE_MINIMUM_LINE_FEED * 2
	jl	afterPaperCheck			;skip if we're close to point

	cmp	dx, NIKE_MINIMUM_LINE_FEED * 2
	jl	afterPaperCheck			;skip if linefeed is small

	push	dx
	sub	dx, cx				;make sure the second linefeed
	cmp	dx, NIKE_MINIMUM_LINE_FEED	; is large enough
	pop	dx
	jge	doLF

	; adjust distance to paper out point so second linefeed is at least
	; NIKE_MINIMUM_LINE_FEED.

	sub	cx, NIKE_MINIMUM_LINE_FEED
doLF:
	sub	dx, cx
	xchg	dx, cx
	call	PrDoLineFeed			;linefeed down to point
	mov	dx, cx
	jc	exit

	; Check paper here.

	call	PrWaitForMechanismLow
	jc	exit

	mov	al, PJLP_noupdate
	call	PrintGetErrorsLow
	test	ax, mask PER_PES		;do we still have paper?
	jnz	paperError			;error if no paper

afterPaperCheck:
	; Finish linefeed

	call	PrDoLineFeed
	jc	exit

	; Check paper again after doing linefeed

	mov	dx, es:[PS_customHeight]
	clr	ax
	call	PrConvertToDriverCoordinates
	mov	cx, dx

	sub	cx, PAPER_DETECT_MARGIN + PAPER_DETECT_TOP_MARGIN
	sub	cx, es:PS_cursorPos.P_y
	jl	paperOK				;already past paper out point

	call	PrWaitForMechanismLow	
	jc	exit

	mov	al, PJLP_noupdate
	call	PrintGetErrorsLow
	test	ax, mask PER_PES		;do we still have paper?
	jnz	paperError			;error if no paper

paperOK:
	clc					;paper is ok
exit:
	.leave
	ret

paperError:
	mov	cx, CPMSG_PAPER_RUN_OUT
	call	PrintErrorBox
	stc					;error
	jmp	exit

PrLineFeed      endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrLineFeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:
        Executes a vertical line feed of dx <printer units>, and updates
	the cursor position accordingly.

CALLED BY:
        Jump Table

PASS:
        es      =       segment of PState
        dx      =       length, in <printer units>" to line feed.

RETURN:
        carry   - set if some transmission error

DESTROYED:
        nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrDoLineFeed      proc    near
	uses    ax,cx
	.enter

	tst	dx				;see it no offset
	jz	exit				;if none, skip move

	call	PrWaitForMechanismLow
	jc	exit

	clr	es:PS_dWP_Specific.DWPS_yOffset
	add     es:PS_cursorPos.P_y,dx		;update the new PState position

	mov	ax, PB_ADVANCE_PAPER shl 8	;al <- 0 = forward direction
	mov	cx, dx
	tst	cx
	jns	lineFeed
	neg	cx				;cx <- abs(cx)
	inc	ax				;al <- 1 = reverse direction
lineFeed:
	cmp	cx, NIKE_MAXIMUM_LINE_FEED
	jbe	callBIOS

	push	ax, cx
	mov	cx, NIKE_MAXIMUM_LINE_FEED
	call	PrinterBIOS
	pop	ax, cx

	call	PrWaitForMechanismLow
	jc	exit

	sub	cx, NIKE_MAXIMUM_LINE_FEED
	jmp	lineFeed

callBIOS:
	call	PrinterBIOS
exit:	
	.leave
	ret
PrDoLineFeed      endp
