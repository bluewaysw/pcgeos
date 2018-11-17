COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Tiramisu
MODULE:		Fax
FILE:		faxprintEndPage.asm

AUTHOR:		Jacob Gabrielson, Apr 16, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/16/93   	Initial revision
	AC	9/ 8/93		Changed for Group3
	jdashe	10/10/94	Modified for Tiramisu

DESCRIPTION:
	
		

	$Id: faxprintEndPage.asm,v 1.1 97/04/18 11:53:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does end-page routine for the printer driver.

CALLED BY:	
PASS:           bp      - PSTATE segment address.
                cl      - Suppress form feed flag, C_FF is FF non-suppressed

RETURN:         carry   -set if some communications error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintEndPage	proc	far
		uses	ax, bx, cx, dx, bp, es
		.enter
	;
	;  Get the dgroup segment and check our disk-space flag.
	;
		mov	bx, handle dgroup
		call	MemDerefES			; es <- dgroup
		tst_clc	es:[errorFlag]			; clears carry
		stc					; assume the worst
		jnz	done				; already ran out!
	;
	;  We haven't run out yet.  Chop of lines from the end of this page, if
	;  we're supposed to.
	;
		call	FPDiscardBlankLines
	;
	;  We haven't run out yet.  Check the available disk space.
	;
		mov	bx, es:[outputVMFileHan]
		call	VMUpdate			; flush blocks to disk
		jc	noSpace				; disk full!
		
		mov	bx, FAX_FILE_STANDARD_PATH
		call	DiskGetVolumeFreeSpace		; dx:ax - bytes free
		tst_clc	dx				; clears carry
		jnz	done				; no problemo
	;
	;  We've got less than 65K left.  Compare ax (the actual amount)
	;  against our low-water level warning.
	;
		cmp	ax, DISK_SPACE_FOR_WARNING	; above low-level?
		ja	done				; carry clear (really)
	;
	;  We're below our warning level.  Set the errorFlag appropriately.
	;
noSpace::
		mov	es:[errorFlag], PDEC_RAN_OUT_OF_DISK_SPACE
		stc
done:
	;
	; Exit cleanly
	;
		.leave
		ret
PrintEndPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FPDiscardBlankLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if we're supposed to make fax pages as short as
		possible by discarding blank scanlines at the bottom of the
		page.

		If we're to make the pages small as possible, we use the
		lowestNonBlankLine counter set in PrintSwath to determine what
		to discard, add an offset, and disard away.

CALLED BY:	PrintEndPage

PASS:		es	- dgroup

RETURN:		nothing

DESTROYED:	bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	9/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FPDiscardBlankLines	proc	near
		uses	ax, cx, dx, di, si
		.enter
EC <		call	ECCheckDGroupES					>
	;
	; Discard blank lines?
	;
		test	es:[faxoutFlags], mask FDF_SEND_UNIFORM_PAGES
		jnz	done		; jump if nothing to do
	;
	; We're supposed to chop blank lines.  If this is a header-style
	; coverpage, then the work's already been done.
	;
		test	es:[faxFileFlags], mask FFF_DONE_REPLACING
		jnz	done		; jump if work's all done
	;
	; Ok, we should really chop blank lines.  If we're rasterizing a page
	; that will have a header coverpage plunked on top of it, make sure we
	; leave enough space for it.
	;
		mov	bx, FAXPRINT_STANDARD_BLANK_LINE_MINIMUM
		test	es:[faxFileFlags], mask FFF_FINE_RESOLUTION
		jz	figureOutHowMany	; jump if standard mode
		shl	bx, 1			; bx <- fine mode scanlines

figureOutHowMany:
		mov	cx, es:[lowestNonBlankLine]

		test	es:[faxFileFlags], mask FFF_PRE_REPLACE_PAGE
		jz	doDiscard	; jump if not a page that'll be replaced
	;
	; Leave as much space as needed for the coverpage to be plunked later.
	;
		cmp	cx, es:[lastCPHeight]
		ja	doDiscard		; jump if enough already
		mov	cx, es:[lastCPHeight]
doDiscard:
	;
	; At this point:
	;	bx = the number of blank lines that must be left over if
	;	     chopping's done.
	;	cx = the scanline number of the lowest non-blank scanline.
	;
	; Ok, how many blank lines are there at the end of the page?
	;
		add	cx, bx			; cx <- the lowest allowable
						;  scanline
		mov	ax, es:[twoDCompressedLines]
		cmp	cx, ax			; lowest line, total lines
		ja	done			; jump if no choppin'.
	;
	; We should chop.  Remove all lines below the lowest non-blank + an
	; inch.
	;
		xchg	ax, cx			; dx:ax <- the line to start
						;  clearing. 
		clr	dx

		sub	cx, ax			; cx <- # lines to chop
		mov	bx, es:[outputVMFileHan]
		mov	di, es:[outputHugeArrayHan]
		call	HugeArrayDelete
done:
		.leave
		ret
FPDiscardBlankLines	endp
