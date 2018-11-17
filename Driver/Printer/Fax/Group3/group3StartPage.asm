COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Pasta
MODULE:		Fax
FILE:		group3StartPage.asm

AUTHOR:		Jacob Gabrielson, Apr  7, 1993

ROUTINES:
	Name			Description
	----			-----------
    INT PrintStartPage		do stuff appropriate at the start of a page

    INT Group3CreateNewPage	Makes a new page in the fax file

    INT	Group3AddHeader		Makes a swath using the Bitmap routines and
				appends that to the fax file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jag	4/ 7/93   	Initial revision
	AC	9/ 8/93		Changed for Group3


DESCRIPTION:
	
		

	$Id: group3StartPage.asm,v 1.1 97/04/18 11:52:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	
faxHeaderPageString		char	"PAGE:       ",0
faxHeaderPageStringIndex	word	7

idata	ends


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
		uses	bx, di, es
		.enter
	;
	; Start cursor out at top, left position (in PState)
	;
		call	PrintHomeCursor
	;
	; For Nike, we don't want to deal with printer error messages
	; when spooling a fax.
	;
	;
	; Allocate a page to the fax file
	;
		call	Group3CreateNewPage	; bx.di = HugeArray handle
						; es = dgroup
	;
	; Put the header information on the top of the page.  If the page
	; count is one we do not have to add the header sice the FaxSpooler
	; will take care of it.
	;
		cmp	es:[faxPageCount], 1
		jle	exit
		call	Group3AddHeader
exit:
	;
	; exit cleanly
	;
		inc	es:[faxPageCount]	; inc the page count
		clc				; "signify happiness"

		.leave
		ret
PrintStartPage	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3CreateNewPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a new page in the fax file

CALLED BY:	PrintStartPage

PASS:		nothing

RETURN:		bx	= VM file handle of the fax
		di	= VM block handle of HugeArray bitmap
		es	= dgroup

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	9/13/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3CreateNewPage	proc	near
		uses	 ax, cx, dx
		.enter
	;
	;  Use the faxfile library to create a new page in the fax file.
	;
		mov	ax, segment dgroup
		mov	es, ax
		mov	bx, es:[outputVMFileHan]
		mov	ax, FAP_ADD_CREATE
		mov	cx, FAX_PAGE_LAST		; append page
		call	FaxFileInsertPage
	;
	;  Save the handle so we can manipulate it later.
	;
		mov	es:[outputHugeArrayHan], dx
		mov	di, dx

		.leave
		ret
Group3CreateNewPage	endp
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Group3AddHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a swath using the Bitmap routines and appends that 
		to the fax file

CALLED BY:	PrintStartPage

PASS:		bx	= Fax file handle
		di	= VM block handle of the new page
		bp	= PState
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	10/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Group3AddHeader	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds
		.enter

EC <		call	ECCheckDGroupES				>

		push	bx
	;
	;  Create a bitmap to make the swath that we'll prepend.
	;
		mov	al, BMType <0, 1, 0, 1, BMF_MONO>
		mov	cx, FAXFILE_HORIZONTAL_WIDTH	; ...in pixels
		mov	ds, bp				; ds = PState
		mov	bp, bx				; bp = faxfile handle
		clr	bh
		mov	bl, ds:[PS_mode]
		xchg	bp, bx				; bx = file handle
		mov	dx, cs:BandLengthTable[bp]
		clr	di, si				; exposure OD
		call	GrCreateBitmap			; ^vbx:ax = HugeArray
							; di = gstate
		push	ax 				; save VM block handle
	;
	;  Set the font & text style for the status line.
	;
		mov	cx, FAXFILE_TTL_FONT		; font to use
		mov	dx, FAXFILE_TTL_FONT_SIZE
		clr	ah				; dx:ah = font size
		call	GrSetFont

		mov	ax, FAXFILE_TTL_TEXT_STYLE
		call	GrSetTextStyle
	;
	;  Set the bitmap resolution.
	;
		mov	ax, FAX_X_RES
		mov	bx, cs:FaxVerticalResolution[bp]		
		call	GrSetBitmapRes
	;
	;  Draw the fax ID into the header.  This ID is picked out of 
	;  the job paramters block.
	;
		mov	ax, FAXFILE_TTL_FAX_ID_POS	; ax = x coord of text
		clr	bx				; bx = y coord of text

		clr	cx				; string is null term.
							; ds:si = string to copy
		.warn	-field
		lea	si, ds:[PS_jobParams].JP_printerData.FFH_faxID
		call	GrDrawText
	;
	;  Draw the phone number into the header.  Use the sender's 
	;  fax # if any.  Otherwise, use the voice # if any.
	;
		lea	si, ds:[PS_jobParams].JP_printerData.FFH_senderFax
		
		tst	{byte}ds:[si]			; any fax #?
		jnz	gotNumber
		
		lea	si, ds:[PS_jobParams].JP_printerData.FFH_senderVoice
gotNumber:
		mov	ax, FAXFILE_TTL_FAX_PHONE_POS
		call	GrDrawText
		.warn	@field
		
		push	di				; save gstate
	;
	;  Make the page value.
	;
		mov	di, offset faxHeaderPageString
		mov	si, di				; si needs this later
		add	di, es:[faxHeaderPageStringIndex]
		mov	cx, mask UHTAF_NULL_TERMINATE
		clr	dx
		mov	ax, es:[faxPageCount]		; dx:cx = # to convert
		call	UtilHex32ToAscii		; cx = length
	;
	;  Make sure the name doesn't exceed 3 digits.
	;
EC <		cmp	cx, MAX_PAGE_NUMBER_ASCII_LENGTH		>
EC <		ERROR_A GROUP3_TOO_MANY_PAGES_IN_FAX			>

		mov	ax, FAXFILE_TTL_PAGE_COUNT_POS	; where to draw string
		clr	bx

		pop	di				; di = gstate
		segmov	ds, es, cx			; ds:si = string
		clr	cx				; null-terminated
		call	GrDrawText
	;
	;  Now we compress the scanlines and add them to the page.  We 
	;  do this by pretending we are a swath and call the PrintSwath 
	;  routine.
	;
		pop	cx			; cx = vm block handle
		pop	dx			; dx = file handle
		call	PrintSwath
	;
	;  Kill the window, gstate, & bitmap data, as they are no
	;  longer needed.
	;
		clr	ah
		mov	al, BMD_KILL_DATA
		call	GrDestroyBitmap

		.leave
		ret
Group3AddHeader	endp

























