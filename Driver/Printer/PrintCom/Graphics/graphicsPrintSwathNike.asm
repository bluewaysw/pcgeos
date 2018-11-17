COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Dedicated WPs
FILE:		graphicsPrintSwathNike.asm

AUTHOR:		Dave Durran 

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/16/94	Initial revision


DESCRIPTION:

	$Id: graphicsPrintSwathNike.asm,v 1.1 97/04/18 11:51:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSwath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a page-wide bitmap

CALLED BY:	GLOBAL

PASS:		bp	- PState segment
		dx.cx	- VM file and block handle for Huge bitmap

RETURN:		carry	- set if some transmission error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintSwath	proc	far
	uses	ax,bx,cx,dx,si,di,ds,es
	.enter

	mov	es, bp				; es -> PState

		; load the bitmap header into the PState
	call	LoadSwathHeader			; bitmap header into PS_swath

		; load up the band width and height
        call    PrLoadPstateVars		; set up the pstate band Vars.

		; get pointer to data
	mov	es:[PS_curColorNumber],0	; init offset into scanline.
	call	DerefFirstScanline		; ds:si -> scan line zero
	jcxz	printLastBand
bandLoop:
	push	dx				; save band count
	mov	dx,es:[PS_bandHeight]		; print a full height band.
	call	PrPrintHighBand			; print a band from this swath.
	pop	dx
	jc	printError			; jmp with carry set

	loop	bandLoop

		; if any remainder, then we need to send it, plus a shorter
		; line feed
printLastBand:
	tst	dx				; any remainder ?
	jz	unlockVM			; jmp with carry clear

	call	PrPrintHighBand			; print last band
	jnc	unlockVM

printError:
	mov	es:[PS_dWP_Specific].DWPS_returnCode, PDR_PRINT_ERROR

		; all done, unlock vmfile and leave
unlockVM:
	call	HugeArrayUnlock			; preserves flags

	.leave
	ret
PrintSwath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintFinishPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish printing current page

CALLED BY:	PrintEndPage
PASS:		es = PState
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintFinishPage	proc	near
	uses	ax,bx,cx,ds,es
	.enter

	tst	es:[PS_dWP_Specific].DWPS_returnCode
	jnz	done

	mov	al, es:[PS_printerType]
	and	al, mask PT_COLOR
	cmp	al, BMF_MONO
	je	done

EC <	cmp	al, BMF_3CMY						>
EC <	ERROR_NE -1				;must be mono or cmy	>

	; Finish off color printing by finishing off cyan and magenta scanlines

	tst	es:[PS_bandHeight]
	jz	done				; abort if no bandHeight

	mov	es:[PS_dWP_Specific].DWPS_finishColor, TRUE
	mov	es:[PS_newScanNumber], 0

	clr	dx
	mov	ax, PRINT_HEAD_OFFSET_TO_CYAN
	div	es:[PS_bandHeight]
	mov_tr	cx, ax
	jcxz	lastBand

bandLoop:
	push	dx
	mov	dx,es:[PS_bandHeight]		; print a full height band.
	call	PrPrintHighBand			; print a band from this swath.
	pop	dx
	jc	done
	loop	bandLoop

lastBand:
	tst	dx
	jz	done

	call	PrPrintHighBand			; print last band
done:
	.leave
	ret
PrintFinishPage	endp
