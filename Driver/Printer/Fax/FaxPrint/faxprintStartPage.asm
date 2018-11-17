COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		faxprintStartPage.asm

AUTHOR:		Jacob Gabrielson, Apr  7, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT PrintStartPage		do stuff appropriate at the start of a page

    INT FaxprintCreateNewPage	Makes a new page in the fax file

    INT	FaxprintAddHeader	Makes a swath using the Bitmap routines and
				appends that to the fax file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/ 7/93   	Initial revision
	AC	9/ 8/93		Changed for Faxprint
	jimw	4/12/95		Updated for multi-page cover pages

DESCRIPTION:
	
		

	$Id: faxprintStartPage.asm,v 1.1 97/04/18 11:53:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	do stuff appropriate at the start of a page

CALLED BY:	DriverStrategy

PASS:		bp	= PState segment

RETURN:		carry set on error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintStartPage	proc	far
		uses	ax, bx, cx, di
		.enter		
	;
	; Make sure there's enough disk space available.
	;
		call	FaxprintResetDiskSpace
		jc	done			; jump if not enough space
	;
	; Start cursor out at top, left position (in PState)
	;
		call	PrintHomeCursor		
	;
	; Allocate a page to the fax file.  NOTE!  If this is the cover page,
	; then the new page will be prepended to the list of existing pages!
	;
		call	FaxprintCreateNewPage	; bx.di = HugeArray handle
						; es = dgroup
	;
	; Add the TTL to the top of the page.
	;
EC <		call	ECCheckDGroupES					>
						; reset number of lines so far
		clr	ax, \
			es:[twoDCompressedLines], \
			es:[lowestNonBlankLine]

		call	FaxprintAddHeader	; carry set accordingly
EC <		call	ECCheckDGroupES					>

done:
		.leave
		ret

		
PrintStartPage	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintCreateNewPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a new page in the fax file.  If the cover page is
		currently being printed, the new page will be prepended before
		any existing pages.  Unless of course, if the cover page is
		a header.  Then, by gosh, we need to replace some of an
		exisiting page.

		Or if this is the page that will BE replaced,
		then we need to say so, so that PrintSwath can ensure
		that the lines that will be replaced are encoded 1-d
		and NOT 2-d.  2-d and replacement just don't work well
		together because decompression of one scanline is
		dependent on the previous one (which could have been
		replaced with something different).

CALLED BY:	PrintStartPage

PASS:		nothing

RETURN:		bx	= VM file handle of the fax
		di	= VM block handle of HugeArray bitmap
		bp	= Pstate segment
		es	= dgroup
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/13/93    	Initial version
	jimw	4/12/95		Added multiple-page cover page support
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FaxprintCreateNewPage	proc	near
		uses	 ax, cx, dx, ds
		.enter
	;
	; Clear out significant bit flags and other set up.
	;
		mov	bx, handle dgroup
		call	MemDerefES			; es <- dgroup
		inc	es:[faxPageCount]		;1s based
		andnf	es:[faxFileFlags], not (mask FFF_DONE_REPLACING or \
					       mask FFF_PRE_REPLACE_PAGE or \
				               mask FFF_REPLACE_WITH_COVER_PAGE)
		mov	ax, FAP_ADD_CREATE
	;
	; Assume we'll prepend.  Later code decrements the page to
	; insert/append (cx).  That's why we add one here.
	;
		mov	cx, FAX_PAGE_LAST +1	
		mov	bx, es:[outputVMFileHan]
	;
	; If we're NOT printing the cover page, then we need to check for
	; pre-replacement status.
	;
		mov	ds, bp				; ds <- PState segment
		test	({FaxFileHeader}ds:[PS_jobParams].JP_printerData).\
					FFH_flags, mask FFF_PRINTING_COVER_PAGE
	LONG	jz	replacementCheck	
	;
	; Get the 1s based page number.
	;
		mov	cx, es:[faxPageCount]
		Assert  ae, cx, 1
	;
	; If we're not doing the header thing, then just insert the page.
	; cx has the 1-based position to insert.  
	;
		test	({FaxFileHeader}ds:[PS_jobParams].JP_printerData).\
				FFH_flags, mask FFF_COVER_PAGE_IS_HEADER
		jz	insertPage
	;
	; Ok, so we are doing the header thing.  If this page =  cpPageCount
	; then we have to do the replacement biz.  Otherwise, just insert
	; as usual.
	;
		Assert  le, cx, ({FaxFileHeader}ds:[PS_jobParams].JP_printerData).FFH_cpPageCount
		cmp	cx, ({FaxFileHeader}ds:[PS_jobParams].JP_printerData).\
							FFH_cpPageCount
		jne	insertPage
	;
	; This cover page page will be put on top of an existing page.
	; Say so with a flag, and get the page in question. 
	;
		BitSet	es:[faxFileFlags],  FFF_REPLACE_WITH_COVER_PAGE
		dec	cx			;zero-based, you know
		call	FaxFileGetPage		;ax <- page handle
		mov	dx, ax			;dx <- page handle
		jmp	saveInfo
		
replacementCheck:
	;
	; We need to know whether this body page will be partially replaced
	; by the cover page.  We know this is true if: 1) we're here in the
	; code  2) the page number is the same as the last cp page number,
	; and 3) the cover page is a header.
	;
		mov	dx, es:[faxPageCount]
		cmp	dx, ({FaxFileHeader}ds:[PS_jobParams].JP_printerData).\
							FFH_cpPageCount	
		jne	insertPage

		test	{word} es:[faxFileFlags], mask FFF_COVER_PAGE_IS_HEADER
		jz	insertPage

		BitSet	es:[faxFileFlags], FFF_PRE_REPLACE_PAGE
insertPage:
		dec	cx		;page count - 1 = insertion point
		call	FaxFileInsertPage
saveInfo:
	;
	;  Save the handle so we can manipulate it later.
	;  Zero out the absoluteCurrentLine here, too.
	;
		clr	es:[absoluteCurrentLine]
		mov	es:[outputHugeArrayHan], dx
		mov	di, dx

		.leave
		ret
FaxprintCreateNewPage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FaxprintAddHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a swath using the Bitmap routines and appends that 
		to the fax file

CALLED BY:	PrintStartPage

PASS:		bx	= Fax file handle
		di	= VM block handle of the new page
		bp	= PState
		es	= dgroup

RETURN:		carry set if error
 		clear if all's well

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/15/93    	Initial version
	jdashe	11/17/94	Tiramisu-ized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FaxprintAddHeader	proc	near
		uses	bx, cx, dx, si, di, bp, es, ds
		.enter

EC <		call	ECCheckDGroupES				>
	;
	;  Create a bitmap to make the swath that we'll prepend.
	;
		mov	ds, bp				; ds:0 <- PState
		mov	si, offset PS_jobParams		; ds:si <- JobParams
		clr	dh
		mov	dl, ds:[PS_mode]		; dx <- vertical rez.
		mov	ax, es:[faxPageCount]		; ax <- current pge
		call	FaxfileCreateTTL		; ax <- VM block
							; di <- gstate handle
		mov	cx, ax				; cx <- vm block handle
		mov	dx, bx				; dx <- file handle

		call	PrintSwath			; error ? (carry)
	;
	;  Kill the window, gstate, & bitmap data, as they are no
	;  longer needed.
	;
		pushf				; save carry
		mov	ax, BMD_KILL_DATA
		call	GrDestroyBitmap
		popf				; restore carry

		.leave
		ret
FaxprintAddHeader	endp
