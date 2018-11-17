COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		documentManip.asm

AUTHOR:		Gene Anderson, Feb 12, 1991

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/12/91		Initial revision

DESCRIPTION:
	This file contains routines to implement 

	$Id: documentManip.asm,v 1.1 97/04/04 15:47:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentPrint	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentVerifyPrintRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify we can print with the current parameters

CALLED BY:	MSG_PRINT_VERIFY_PRINT_REQUEST
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the message

		cx:dx - OD of PrintControlClass object to reply to

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentVerifyPrintRequest 	method dynamic GeoCalcDocumentClass,
						MSG_PRINT_VERIFY_PRINT_REQUEST
	pushdw	cxdx
	;	
	; Make sure the print range is valid
	;
	push	si
	mov	bx, ds:[di].GCDI_spreadsheet
	mov	si, offset ContentSpreadsheet	;^lbx:si <- OD of our ssheet
	call	GetPrintRangeCommon
	pop	si
	jc	returnError
	;
	; Make sure the options are OK
	;
	call	GetPrintOptionsCommon		;ax <- SpreadsheetPrintFlags
	tst	ax				;any flags specified?
	jz	nothingToPrint
	;
	; Success!
	;
	mov	cx, TRUE			;cx <- continue print job
returnFlag:
	;
	; Tell the PrintControl if it was OK or not
	;
	popdw	bxsi				;^lbx:si <- OD of print control
	mov	ax, MSG_PRINT_CONTROL_VERIFY_COMPLETED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret

	;
	; The user specified nothing to print -- bitch and moan
	;
nothingToPrint:
	call	GetSpreadsheetFile		;bx <- file handle
	mov	si, offset nothingToPrintMessage
	jmp	short moan
	;
	; The user specified an invalid print range.  Put up an error
	; message so the user will know that printing will not commence.
	;
returnError:
	call	GetSpreadsheetFile
 	mov	si, offset invalidPrintRangeMessage
moan::
	call	DocumentMessage
	
	clr	cx				;cx <- don't print -- error
	jmp	returnFlag

GeoCalcDocumentVerifyPrintRequest		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the document
CALLED BY:	MSG_PRINT_START_PRINTING

PASS:		*ds:si - instance data
		es - seg addr of GeoCalcDocumentClass
		ax - the method

		cx:dx - OD to sent MSG_PRINTING_COMPLETED to
		bp - handle of GString

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	A document is a collection of pages which have the following
	characteristics:
		Header		<- one call to spreadsheet
		Body		<- one call to spreadsheet
		    Column Titles
		    Row Titles
		    Spreadsheet
		Footer		<- one call to spreadsheet

	DrawGrid	- Draw the grid around the cells
	DrawHeader	- Draw the header at the top of every page
	DrawFooter	- Draw the footer at the bottom of every page
	DrawColumnTitles- Draw titles at the top of each column
			  on every page.
	DrawRowTitles	- Draw titles to the left of each row on
			  every page.

	Sideways	- Rotate the output 90 degrees
	ScaleToFit	- Scale the entire document to fit on a single
			  page.
	CenterVertically- Center output vertically on the page
	CenterHorizontally- Center output vertically on the page

    Continuous Printing:
	Continuous printing turns the spreadsheet into one enormous document.
	The idea is that the spooler will parcel the document into the most
	appropriate form for the printer. 
	
	If we are printing in portrait mode that means that the document will
	be printed as a set of vertical bands where the bottom of one printed
	page runs into the top of the next. This happens to be just what we
	want.
	
	If we are printing in landscape mode it means that the document will
	be printed as a set of horizontal bands where the right edge of one
	printed page runs into the left edge of the next. This is exactly
	what we want.
	
	Since the range is considered one large document there is a single
	header and a single footer.

    Scale To Fit:
	Scale to fit implies that the entire body of the document will fit
	on a single page. To do this we assume "continuous" printing in order
	to generate the giant document. We then apply appropriate scaling when
	we go to draw the body.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/12/91		Initial version
	jcw	 4/29/91	Actually made it print :-)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcPrintParams	struct
	;
	; SpreadsheetDrawParams structure that we set up and then use for
	; drawing the body.
	;
    GCPP_sdp		SpreadsheetDrawParams
	;
	; The next few entries are initialized and then are only referenced.
	; The pairs (Area/Range) must be kept in order.
	;
    GCPP_headerArea	RectDWord		; Area reserved for header
    GCPP_headerRange	CellRange		; Limit for the header

    GCPP_footerArea	RectDWord		; Area reserved for footer
    GCPP_footerRange	CellRange		; Limit for the footer

    GCPP_bodyArea	RectDWord		; Area reserved for body
    GCPP_bodyRange	CellRange		; Limit for the body

    GCPP_topLeft	CellReference		; The current top-left area
						;   used by the body.
	;
	; These represent the total page area and the area spanned by the
	; entire spreadsheet range.
	;
    GCPP_pageRect	RectDWord		; Area of the printed page
    GCPP_rangeRect	RectDWord		; Area of the spreadsheet range
	;
	; This is the PrintControl object.
	;
    GCPP_pc		optr			; OD of the PrintControl
	;
	; Handle of associated document file
	;
    GCPP_file		hptr
	;
	; The current page which we pass to the PrintControl as we print.
	;
    GCPP_page		word			; Current page
	;
	; This is the position for the next note on the current page.
	;
    GCPP_notePos	word			; Y-position on the page
	;
	; OD of the GrObj for this document
	;
    GCPP_grobj		optr			;OD of the GrObj
	align	word
GeoCalcPrintParams	ends

CheckHack <offset GCPP_sdp eq 0>

GeoCalcDocumentStartPrinting	method dynamic GeoCalcDocumentClass,
						MSG_PRINT_START_PRINTING
	;
	; Now the document size is set up correctly.
	; We can now start printing...
	;
	mov	di, bp				;di <- handle of GState
	sub	sp, size GeoCalcPrintParams
	mov	bp, sp				;ss:bp <- frame ptr
	;
	; Save the OD of the PrintControl object
	;
	movdw	ss:[bp].GCPP_pc, cxdx
	;
	; Get the OD of the GrObj for later
	;
if _CHARTS
	push	si
	call	GetGrObjBodyOD
	movdw	ss:[bp].GCPP_grobj, bxsi
	pop	si
endif	
	;
	; Get other fun stuff
	;
	call	GetSpreadsheetFile
	mov	ss:[bp].GCPP_file, bx
	;
	; Get the Spreadsheet OD for this document.
	;
	call	GetDocSpreadsheet
	;
	; At this point:
	;	^lbx:si - OD of spreadsheet object
	;	ss:bp - ptr to GeoCalcPrintParams
	;	di - handle of GState to draw with
	;
	call	InitPrintParameters	; Initialize the stack frame
	jc	afterPrint		; Branch if error
	
	call	CalcNumberOfPages	; ax <- # of pages

	push	es
	GetResourceSegmentNS dgroup, es	; es = dgroup
	mov	es:totalPageCount, ax	; Set the # of pages

	call	InitPrintParameters	; Reinitialize stuff.

	mov	ax, ss:[bp].GCPP_page	; Save the current page number

EC <	call	ECCheckESDGroup						>
	mov	es:currentPage, ax	; Set the current page here too
	pop	es

	call	PrintPagesAndNotes	; Print the spreadsheet and notes
					; ax <- # of pages printed
	clc				; Signal: no error

afterPrint:
	mov	bx, cx			; ^lbx:si <- PrintControl object
	mov	si, dx
	;
	; Carry set here on error.
	;
	mov	cx, ss:[bp].GCPP_file	; cx <- file handle
	;
	; Clean up stack while preserving carry
	;
	lea	sp, ss:[bp][(size GeoCalcPrintParams)]

	jc	errorPrinting		; Branch on error
	;
	; All done... Signal the SPC that we're finished.
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	mov	di, mask MF_CALL
	call	ObjMessage		; Tell PrintControl that we're done
quit:
	push	es
	mov	di, bx			; save bx value	
	GetResourceSegmentNS dgroup, es, TRASH_BX
	mov	bx, di			; restore bx value
EC <	call	ECCheckESDGroup						>
	mov	es:currentPage, 0	; Reset the current page
	mov	es:totalPageCount, DEFAULT_TOTAL_PAGE_COUNT
	pop	es
	ret

errorPrinting:
	;
	; There was some sort of error. We need to cancel the job.
	; cx = File handle
	;
	push	cx			; Save file handle
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	mov	di, mask MF_CALL
	call	ObjMessage		; Tell PrintControl that we're done
	pop	bx			; bx <- file handle
	;
	; Tell the user that some error was encountered and that the print
	; job was aborted.
	;
	; bx = File handle
	;
	mov	si, offset PrintHdrFtrTooLargeMessage
	call	DocumentMessage			; Display the message
	jmp	quit

GeoCalcDocumentStartPrinting	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintPagesAndNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the pages and the notes

CALLED BY:	GeoCalcDocumentStartPrinting()
PASS:		di	= GState to draw with
		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= OD of the spreadsheet
		^lcx:dx	= OD of the spool print control

RETURN:		ax	= # of pages printed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintPagesAndNotes	proc	near
	uses	es
	.enter
	;
	; set es = dgroup
	;
	GetResourceSegmentNS dgroup, es		; es = dgroup

	; di	  = gstate to draw with
	; ^lbx:si = OD of spreadsheet
	; ^lcx:dx = OD of spool print control
	; ss:bp	  = pointer to GeoCalcPrintParams
	;

	;
	; See if we're printing cell notes only.  If so, don't bother
	; looping through the pages, because we'll loop forever since
	; nothing is being printed each time we call PrintNextPage so
	; SPF_DONE will never be set.
	;
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_DOCUMENT or \
						mask SPF_PRINT_GRAPHICS
	jz	printingDone
	;
	; Loop and print each page
	;
printLoop:
	call	PrintNextPage		; Print another page...
	
	inc	ss:[bp].GCPP_page	; Update page number

EC <	call	ECCheckESDGroup					>
	inc	es:currentPage		; Update page number here too

	mov	al, PEC_FORM_FEED
	call	GrNewPage		; Move to next page

	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_DONE
	jz	printLoop		; Loop to print another page

	;
	; We've printed the spreadsheet -- add in cell notes if requested
	;
printingDone:
	call	PrintNotes		; Print the notes now
	
	mov	ax, ss:[bp].GCPP_page	; ax <- next page to print
	dec	ax			; Return # of pages printed
	.leave
	ret
PrintPagesAndNotes	endp

if ERROR_CHECK

ECCheckESDGroup	proc	near
	uses	ax, bx, es
	.enter
	pushf
	mov	ax, es
	GetResourceSegmentNS	dgroup, es, TRASH_BX
	mov	bx, es
	cmp	ax, bx
	ERROR_NE -1
	popf
	.leave
	ret
ECCheckESDGroup	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNumberOfPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the number of pages

CALLED BY:	GeoCalcDocumentStartPrinting()
PASS:		
		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= Pointer to Spreadsheet instance
		^lcx:dx	= PrintControl object
		di	= GState
RETURN:		ax	= # of pages
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 6/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcNumberOfPages	proc	near
	uses	bx, cx, dx, si, di
	.enter
	;
	; Set print flags so that we'll skip the drawing.
	;
	push	ss:[bp].GCPP_sdp.SDP_gstate	; Save old gstate
	push	ss:[bp].GCPP_sdp.SDP_printFlags	; Save old flags

	ornf	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_SKIP_DRAW
	;
	; Now create a gstate with no window.
	;
	clr	di			; di <- Window handle (none)
	call	GrCreateState		; di <- gstate with no window
	mov	ss:[bp].GCPP_sdp.SDP_gstate, di	; Save new gstate

	mov	ss:[bp].GCPP_page, 1	; Initialize # of pages

	call	PrintPagesAndNotes	; ax <- # of pages printed
	pop	ss:[bp].GCPP_sdp.SDP_printFlags	; Restore old flags
	pop	ss:[bp].GCPP_sdp.SDP_gstate	; Restore old gstate
	;
	; Now tell the PrintControl about it
	;
	push	ax, bp
	movdw	bxsi, cxdx			;^lbx:si <- OD of PrintControl
	mov	dx, ax				;dx <- # of pages
	mov	cx, 1				;cx <- start page
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	mov	di, mask MF_CALL		;di <- MessageFlags
	call	ObjMessage
	pop	ax, bp

	.leave
	ret
CalcNumberOfPages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrintParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the SpreadsheetDrawParams.

CALLED BY:	GeoCalcDocumentStartPrinting()
PASS:		^lcx:dx	= OD of PrintControl object
		^lbx:si	= OD of Spreadsheet
		di	= GState to draw with
		ss:bp	= Pointer to the GeoCalcPrintParams
		ds	= Block owned by the process
RETURN:		carry set on error
		ss:bp - GeoCalcPrintParams
			GCPP_sdp.SDP_printFlags
			GCPP_topLeft - start of range to print
			GCPP_bodyRange - range to print
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Get the range from PrintRange

	Save the gstate
	Initialize the flags
	Get the user options
	
	Figure the different areas...
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPrintParameters	proc	near
	uses	ax, cx, es, di
	.enter

	;
	; For some error-checking, we wipe out the the stack frame in
	; case something valid looking was there.
	;
EC <	push	ax, cx, es, di		;>
EC <	mov	al, 0xcc		;al <- byte to store >
EC <	lea	di, ss:[bp].GCPP_sdp	;>
EC <	segmov	es, ss			;es:di <- ptr to area>
EC <	mov	cx, (size SpreadsheetDrawParams) >
EC <	rep	stosb			;biff me jesus>
EC <	pop	ax, cx, es, di		;>

	call	GetPrintOptions
	call	GetPrintRange		; Get the range to print
	mov	ss:[bp].GCPP_sdp.SDP_gstate, di	; Save the gstate
	;
	; We check for sideways printing specially because we actually
	; need to communicate the users desire for sideways printing to
	; the SPC directly.
	;
	call	CheckSideways		; Check for sideways printing

	call	GetHeaderRange		; Get the range for the header
	call	GetFooterRange		; Get the range for the footer

	call	FigureAreas		; Figure the assorted areas
	jc	quit			; Quit if no space for data
	;
	; Copy the top-left point of the range into the top-left of the
	; next area to draw.
	;
	mov	ax, ss:[bp].GCPP_bodyRange.CR_start.CR_row
	mov	ss:[bp].GCPP_topLeft.CR_row, ax
	mov	ax, ss:[bp].GCPP_bodyRange.CR_start.CR_column
	mov	ss:[bp].GCPP_topLeft.CR_column, ax

	; carry already clear
quit:
	.leave
	ret
InitPrintParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrintOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the options for printing

CALLED BY:	InitPrintParameters()
PASS:		ss:bp - ptr to GeoCalcPrintParams
			GCPP_file - handle of file
RETURN:		GCPP_sdp.SDP_printFlags - SpreadsheetPrintFlags
		GCPP_page - starting page #
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPrintOptions		proc	near
	uses	ax, bx, cx, dx, es, di, si
	.enter

	;
	; Get the print options saved with the document
	;
	mov	bx, ss:[bp].GCPP_file
	call	DBLockMap
	mov	di, es:[di]			;es:di <- ptr to map
	mov	ax, es:[di].CMB_pageSetup.CPSD_flags
	mov	ss:[bp].GCPP_sdp.SDP_printFlags, ax
	mov	ax, es:[di].CMB_pageSetup.CPSD_startPage
	mov	ss:[bp].GCPP_page, ax
	call	DBUnlock
	;
	; Also get the users options for what they want printed
	;
	call	GetPrintOptionsCommon
	ornf	ss:[bp].GCPP_sdp.SDP_printFlags, ax

	.leave
	ret
GetPrintOptions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrintOptionsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the users print options for what should be printed

CALLED BY:	GetPrintOptions(), GeoCalcDocumentVerifyPrintRequest()
PASS:		ds - fixupable segment
RETURN:		ax - SpreadsheetPrintFlags:
			SPF_PRINT_DOCUMENT
			SPF_PRINT_GRAPHICS
			SPF_PRINT_NOTES
DESTROYED:	cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPrintOptionsCommon		proc	near
	uses	bx, bp, si
	.enter
	GetResourceHandleNS GCPrintOptionsGroup, bx
	mov	si, offset GCPrintOptionsGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
GetPrintOptionsCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrintRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range to print

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= OD of Spreadsheet
RETURN:		ss:bp.GCPP_bodyRange - set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPrintRange	proc	near
	uses	ax, cx, dx, di
	.enter

	call	GetPrintRangeCommon
	;
	; This should never fail, since we verified it earlier
	;
EC <	ERROR_C	FAILED_ASSERTION_IN_PRINTING	;>
	mov	ss:[bp].GCPP_bodyRange.CR_start.CR_row, ax
	mov	ss:[bp].GCPP_bodyRange.CR_start.CR_column, cx
	mov	ss:[bp].GCPP_bodyRange.CR_end.CR_row, dx
	mov	ss:[bp].GCPP_bodyRange.CR_end.CR_column, di

	.leave
	ret
GetPrintRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPrintRangeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get print range from Print DB.

CALLED BY:	GetPrintRange(), GeoCalcDocumentVerifyPrintRequest()
PASS:		^lbx:si - OD of spreadsheet
RETURN:		carry - set if error
		else:
		    (ax,cx),
		    (dx,di) - CellRange
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	* Find out what the user wants to print (i.e. entire spreadsheet,
		displayed cells, or selected cells)
	* Get the range based on the above option

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/18/92		Initial version
	clee	10/6/94		Jedi version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPrintRangeCommon		proc	near
	uses	bp
	.enter

	sub	sp, (size SpreadsheetFormatParseRangeParams)
	mov	bp, sp
	;
	; Get the text for the print range
	;
	push	bx, si
	GetResourceHandleNS GCPrintRange, bx
	mov	si, offset GCPrintRange
CheckHack <(offset SFPRP_text) eq 0>
	mov	dx, ss				;dx:bp <- ptr to buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bx, si
	;
	; Ask our spreadsheet if it is OK
	;
	mov	ax, MSG_SPREADSHEET_PARSE_RANGE_REFERENCE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	;
	; Load registers as if it were OK...
	;
	mov	ax, ss:[bp].SFPRP_range.CR_start.CR_row
	mov	cx, ss:[bp].SFPRP_range.CR_start.CR_column
	mov	dx, ss:[bp].SFPRP_range.CR_end.CR_row
	mov	di, ss:[bp].SFPRP_range.CR_end.CR_column
	;
	; Clean up stack, and preserve carry
	;
	lea	sp, ss:[bp][(size SpreadsheetFormatParseRangeParams)]

	.leave
	ret
GetPrintRangeCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSideways
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the user wants stuff printed sideways

CALLED BY:	InitPrintParameters
PASS:		^lcx:dx	= OD of PrintControl object
		ss:bp	= Pointer to GeoCalcPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSideways	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter
	mov	ax, mask PCA_FORCE_ROTATION	; Assume sideways printing

	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_SIDEWAYS
	jnz	gotBits				; Branch if sideways
	
	clr	ax				; Portrait printing
gotBits:

	mov	bx, cx				; ^lbx:si <- OD of SPC
	mov	si, dx

	push	ax				; Save bits...
	mov	ax, MSG_PRINT_CONTROL_GET_ATTRS
	mov	di, mask MF_CALL
	call	ObjMessage			; cx <- PrintControlAttrs
	pop	ax				; Restore bits
	
	andnf	cx, not mask PCA_FORCE_ROTATION
	ornf	cx, ax				; Set bit if appropriate

	mov	ax, MSG_PRINT_CONTROL_SET_ATTRS
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
CheckSideways	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHeaderRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range that the header occupies

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= Spreadsheet instance
RETURN:		GCPP_headerRange
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHeaderRange	proc	near
	uses	ax, di
	.enter
	;
	; Assume no header
	;
	mov	ss:[bp].GCPP_headerRange.CR_start.CR_row, -1
	
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_HEADER
	jz	quit

	mov	ax, MSG_SPREADSHEET_GET_HEADER_RANGE
	lea	di, ss:[bp].GCPP_headerRange
	call	GetHeaderFooterRange
quit:
	.leave
	ret
GetHeaderRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHeaderFooterRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a range from the spreadsheet

CALLED BY:	GetHeaderRange, GetFooterRange
PASS:		^lbx:si	= Spreadsheet instance
		ss:di	= Pointer to CellRange to fill in
		ax	= Method to send to the spreadsheet
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHeaderFooterRange	proc	near
	uses	ax, cx, dx, bp
	.enter
	push	di			; Save pointer to rectangle
	mov	di, mask MF_CALL	; Call the spreadsheet
	call	ObjMessage		; ax/cx = top/left
					; dx/bp = bottom/right
	pop	di			; Restore pointer to rectangle
	
	mov	ss:[di].R_top, ax	; Save the rectangle
	mov	ss:[di].R_left, cx
	mov	ss:[di].R_bottom, dx
	mov	ss:[di].R_right, bp
	.leave
	ret
GetHeaderFooterRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFooterRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the range that the footer occupies

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= Spreadsheet instance
RETURN:		GCPP_footerRange
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFooterRange	proc	near
	uses	ax, di
	.enter
	;
	; Assume no footer
	;
	mov	ss:[bp].GCPP_footerRange.CR_start.CR_row, -1
	
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_FOOTER
	jz	quit

	mov	ax, MSG_SPREADSHEET_GET_FOOTER_RANGE
	lea	di, ss:[bp].GCPP_footerRange
	call	GetHeaderFooterRange
quit:
	.leave
	ret
GetFooterRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureAreas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out all the different areas we are going to fill.

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= OD of Spreadsheet
		^lcx:dx	= OD of SpoolPrintControl
RETURN:		The areas filled in.
		carry set if there is no room for the body because the header
		  and footer are too large.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	These can just be gotten.
		pageRect
		rangeRect
	These need to be calculated.
		headerArea
		footerArea
		bodyArea

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureAreas	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	push	bx, si				; Save OD of spreadsheet
	;
	; Get the dimensions and the margins for the current document.
	;
	call	GetDocDimensionsAndMargins
	
	;
	; ax	= Left margin
	; di	= Top margin
	; cx	= Width of printable area
	; dx	= Height of printable area
	;
	; ^lbx:si = Spool print control
	;
	;

	call	SetPageRectAndMargin		; Save the page-rectangle

	pop	bx, si				; Restore OD of spreadsheet

	;
	; Now that we've gotten the page rectangle, we compute the the size
	; of the range rectangle.
	; ^lbx:si = OD of Spreadsheet
	;
	push	bp				; Save frame ptr
	mov	dx, ss				; dx:cx <- ptr to RectDWord
	lea	cx, ss:[bp].GCPP_rangeRect
	lea	bp, ss:[bp].GCPP_bodyRange	; dx:bp <- ptr to range
	mov	ax, MSG_SPREADSHEET_GET_RANGE_BOUNDS
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp				; Restore frame ptr
	
	;
	; In some cases it is convenient to make the page-rectangle be the
	; same as the range-rectangle (plus header/footer space).
	; We do this if we are NOT doing scale-to-fit, and if we are doing
	; continuous printing.
	;
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_SCALE_TO_FIT
	jnz	pageNotRange
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_CONTINUOUS
	jz	pageNotRange
	;
	; We are not doing scale-to-fit and we are continuous printing.
	; We want to consider the page rectangle to be as large as it needs
	; to be to hold the entire range.
	;
	call	SetPageToRange
pageNotRange:
	;
	; Now we compute the other values.
	;
	call	FigureHeaderArea
	call	FigureFooterArea
	call	FigureBodyArea
	.leave
	ret
FigureAreas	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDocDimensionsAndMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the dimensions and margins for the document.

CALLED BY:	FigureAreas
PASS:		^lcx:dx	= SpoolPrintControl object
		ss:bp	= GeoCalcPrintParams
RETURN:		^lbx:si	= SpoolPrintControl object
		ax	= Left margin
		di	= Top margin
		cx	= Width of the printable area
		dx	= Height of the printable area
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDocDimensionsAndMargins	proc	near
	uses	bp
	.enter

	mov	bx, cx
	mov	si, dx

	sub	sp, (size PageSizeReport)
	mov	dx, ss
	mov	bp, sp				; dx:bp = PageSizeReport
	mov	ax, MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS
	mov	di, mask MF_CALL
	call	ObjMessage			; dx:bp = filled PageSizeReport
	mov	ax, ss:[bp].PSR_margins.PCMP_left
	mov	di, ss:[bp].PSR_margins.PCMP_top
	mov	cx, ss:[bp].PSR_width.low
	mov	dx, ss:[bp].PSR_height.low
	add	sp, (size PageSizeReport)

	.leave
	ret
GetDocDimensionsAndMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPageRectAndMargin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the GCPP_pageRect field of the GeoCalcPrintParams

CALLED BY:	FigureAreas
PASS:		ss:bp	= GeoCalcPrintParams
		cx	= Page width
		dx	= Page height
		ax	= Left margin
		di	= Top margin
RETURN:		nothing
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/28/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPageRectAndMargin	proc	near
	mov	ss:[bp].GCPP_pageRect.RD_bottom.low, dx
	mov	ss:[bp].GCPP_pageRect.RD_right.low, cx

	;
	; Zero out all the high words, etc
	;
	clr	cx
	mov	ss:[bp].GCPP_pageRect.RD_top.low, cx
	mov	ss:[bp].GCPP_pageRect.RD_left.low, cx

	mov	ss:[bp].GCPP_pageRect.RD_top.high, cx
	mov	ss:[bp].GCPP_pageRect.RD_left.high, cx
	mov	ss:[bp].GCPP_pageRect.RD_bottom.high, cx
	mov	ss:[bp].GCPP_pageRect.RD_right.high, cx
	
	;
	; Save the enforced printer margins. (x = ax, y = di)
	;
	mov	ss:[bp].GCPP_sdp.SDP_margins.P_x, ax
	mov	ss:[bp].GCPP_sdp.SDP_margins.P_y, di
	ret
SetPageRectAndMargin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPageToRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the page rectangle to be the range rectangle plus some
		space for header and footer and the row/column headers

CALLED BY:	FigureAreas
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= Spreadsheet instance
RETURN:		GCPP_pageRect set, doc-size set in the SpoolPrintControl
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Adjust rangeHeight to include the header and footer height

	We want to set the pageRect to:
		top/left = 0,0
		bottom = max( pageHeight, rangeHeight )
		right  = max( pageRight, rangeRight )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPageToRange	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	;
	; Add the header and footer in to the rangeHeight.
	;
	call	GetHeaderHeight			; dx:ax <- header height
	movdw	dicx, dxax			; di:cx <- header height
	call	GetFooterHeight			; dx:ax <- footer height
	adddw	dxax, dicx			; dx:ax <- total height
	adddw	ss:[bp].GCPP_rangeRect.RD_bottom, dxax

	;
	; Add space for row/column headers if we're printing them
	;
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_ROW_COLUMN_TITLES
	jz	skipTitles
	adddw	ss:[bp].GCPP_rangeRect.RD_right, SPREADSHEET_RULER_WIDTH
	adddw	ss:[bp].GCPP_rangeRect.RD_bottom, SPREADSHEET_RULER_HEIGHT
skipTitles:

	;
	; Load up:
	;	ax.bx = rangeHeight
	;	cx.dx = pageHeight
	;
	movdw	axbx, ss:[bp].GCPP_rangeRect.RD_bottom
	subdw	axbx, ss:[bp].GCPP_rangeRect.RD_top

	movdw	cxdx, ss:[bp].GCPP_pageRect.RD_bottom
	subdw	cxdx, ss:[bp].GCPP_pageRect.RD_top
	;
	; Get ax.bx = max( rangeHeight, pageHeight )
	;
	cmpdw	axbx, cxdx
	jae	gotMaxHeight
	movdw	axbx, cxdx
gotMaxHeight:
	;
	; ax.bx = max( rangeHeight, pageHeight )
	;
	movdw	ss:[bp].GCPP_pageRect.RD_bottom,  axbx
	;
	; Now do the same thing for the width
	; Load up:
	;	ax.bx = rangeWidth
	;	cx.dx = pageWidth
	;
	movdw	axbx, ss:[bp].GCPP_rangeRect.RD_right
	subdw	axbx, ss:[bp].GCPP_rangeRect.RD_left

	movdw	cxdx, ss:[bp].GCPP_pageRect.RD_right
	subdw	cxdx, ss:[bp].GCPP_pageRect.RD_left
	;
	; Get ax.bx = max( rangeWidth, pageWidth )
	;
	cmpdw	axbx, cxdx
	jae	gotMaxWidth
	movdw	axbx, cxdx
gotMaxWidth:
	;
	; ax.bx = max( rangeWidth, pageWidth )
	;
	movdw	ss:[bp].GCPP_pageRect.RD_right,  axbx
	;
	; Zero the top/left.
	;
	clr	ax
	mov	ss:[bp].GCPP_pageRect.RD_top.low, ax
	mov	ss:[bp].GCPP_pageRect.RD_top.high, ax
	mov	ss:[bp].GCPP_pageRect.RD_left.low, ax
	mov	ss:[bp].GCPP_pageRect.RD_left.high, ax
	;
	; We need to inform the SPC that the document size is different now.
	;
	push	bp
	clr	ax
	mov	dx, ss:[bp].GCPP_sdp.SDP_margins.P_y
	shl	dx, 1				; Margins on both sides
	adddw	axdx, ss:[bp].GCPP_pageRect.RD_bottom
	pushdw	axdx

	clr	ax
	mov	cx, ss:[bp].GCPP_sdp.SDP_margins.P_x
	shl	cx, 1				; Margins on both sides
	adddw	axcx, ss:[bp].GCPP_pageRect.RD_right
	pushdw	axcx

CheckHack <(size PCDocSizeParams) eq 8>
	mov	bx, ss:[bp].GCPP_pc.handle
	mov	si, ss:[bp].GCPP_pc.offset
	mov	ax, MSG_PRINT_CONTROL_SET_EXTENDED_DOC_SIZE
	mov	dx, ss
	mov	bp, sp				;ss:bp <- ptr to params
	mov	di, mask MF_CALL
	call	ObjMessage
	add	sp, (size PCDocSizeParams)	; clean up stack
	pop	bp

	.leave
	ret
SetPageToRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureHeaderArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the area we'll need for the header.

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= Instance ptr
RETURN:		GCPP_headerArea set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureHeaderArea	proc	near
	uses	ax, dx, di
	.enter
	;
	; Assume there is no header. Create an empty area.
	;
	; Header occupies the top of the paper rectangle.
	;
	push	si				; Save instance chunk
	lea	si, ss:[bp].GCPP_pageRect
	lea	di, ss:[bp].GCPP_headerArea
	call	CopyDocRect
	pop	si				; Restore instance chunk
	
	call	GetHeaderHeight			; dx:ax <- header height
	;
	; dx:ax - height of the header.
	; bottom = top + height
	;
	adddw	dxax, ss:[bp].GCPP_headerArea.RD_top
	movdw	ss:[bp].GCPP_headerArea.RD_bottom,  dxax

	.leave
	ret
FigureHeaderArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureFooterArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the area needed by the footer.

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		^lbx:si	= Instance ptr
RETURN:		GCPP_footerArea set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureFooterArea	proc	near
	uses	ax, bx, cx, dx
	.enter
	;
	; Assume there is no footer. Create an empty area.
	;
	; Footer occupies the bottom of the paper rectangle.
	;
	push	si				; Save instance chunk
	lea	si, ss:[bp].GCPP_pageRect
	lea	di, ss:[bp].GCPP_footerArea
	call	CopyDocRect
	pop	si				; Restore instance chunk
	
	call	GetFooterHeight			; dx:ax <- footer height
	;
	; dx:ax - height of the footer.
	; top = bottom - height
	;
	movdw	cxbx, ss:[bp].GCPP_footerArea.RD_bottom
	subdw	cxbx, dxax			;cx:bx <- new top for header
	movdw	ss:[bp].GCPP_footerArea.RD_top, cxbx

	.leave
	ret
FigureFooterArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureBodyArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the area left for the body.

CALLED BY:	InitPrintParameters
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
RETURN:		carry set if there's no room for the body
		GCPP_bodyArea set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The body area is *always*:
	    body.left  = page.left
	    body.right = page.right
	    body.top   = header.bottom
	    body.bottom= footer.top

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureBodyArea	proc	near
	uses	ax, di, si
	.enter
	;
	; First copy the left/right edges
	;
	lea	si, ss:[bp].GCPP_pageRect
	lea	di, ss:[bp].GCPP_bodyArea
	call	CopyDocRect
	;
	; Now copy the top/bottom edges
	;
	mov	ax, ss:[bp].GCPP_headerArea.RD_bottom.low
	mov	ss:[bp].GCPP_bodyArea.RD_top.low, ax
	mov	ax, ss:[bp].GCPP_headerArea.RD_bottom.high
	mov	ss:[bp].GCPP_bodyArea.RD_top.high, ax

	mov	ax, ss:[bp].GCPP_footerArea.RD_top.low
	mov	ss:[bp].GCPP_bodyArea.RD_bottom.low, ax
	mov	ax, ss:[bp].GCPP_footerArea.RD_top.high
	mov	ss:[bp].GCPP_bodyArea.RD_bottom.high, ax
	
	;
	; Check for header bottom below footer top.
	;
	mov	ax, ss:[bp].GCPP_headerArea.RD_bottom.high
	cmp	ax, ss:[bp].GCPP_footerArea.RD_top.high
	ja	errorNoBody
	jb	quitNoError

	mov	ax, ss:[bp].GCPP_headerArea.RD_bottom.low
	cmp	ax, ss:[bp].GCPP_footerArea.RD_top.low
	jae	errorNoBody

quitNoError:
	clc				; signal: no error
quit:
	.leave
	ret

errorNoBody:
	stc				; signal: no space for the body
	jmp	quit
FigureBodyArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintNextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print another page of the spreadsheet

CALLED BY:	GeoCalcDocumentStartPrinting()
PASS:		^lcx:dx	= OD of SpoolPrintControl object
		^lbx:si	= OD of Spreadsheet
		ss:bp	= GeoCalcPrintParams
RETURN:		SDP_printFlags with the SPF_DONE bit set if we should stop printing.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintNextPage	proc	near
	uses	ax, cx, dx, di
	.enter
	;
	; Signal SPC that we're printing a page.
	;
	call	SignalPrintingPage	; Signal SPC that we're printing
	;
	; ss:bp	  = GeoCalcPrintParams
	; ^lbx:si = Spreadsheet instance
	;
	call	DrawHeader		; Draw whatever header we have.
	call	DrawFooter		; Draw whatever footer we have.
	;
	; NOTE: we clear the SPF_DONE flag because the header/footer
	; printing may have set it.  If this routine is being called,
	; we quite obviously aren't be done yet.
	;
	andnf	ss:[bp].GCPP_sdp.SDP_printFlags, not (mask SPF_DONE)
	call	DrawBody		; Draw the body

	.leave
	ret
PrintNextPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SignalPrintingPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signal the SpoolPrintControl that we're printing a page.

CALLED BY:	PrintNextPage, PrintNotes
PASS:		ss:bp.GCPP_spc set
		ss:bp.GCPP_page = Page number
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SignalPrintingPage	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_SKIP_DRAW
	jnz	quit

	mov	bx, ss:[bp].GCPP_pc.handle
	mov	si, ss:[bp].GCPP_pc.chunk
	mov	cx, PCPT_PAGE		; PCProgressType => CX
	mov	dx, ss:[bp].GCPP_page	; page number => DX
	mov	ax, MSG_PRINT_CONTROL_REPORT_PROGRESS
	mov	di, mask MF_CALL
	call	ObjMessage		; Tell user we're printing a page

quit:
	.leave
	ret
SignalPrintingPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the header...

CALLED BY:	PrintNextPage
PASS:		^lbx:si = Spreadsheet object
		ss:bp	= GeoCalcPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HDR_FTR_FLAGS_TO_CLEAR	= not (mask SPF_PRINT_GRID or \
			       mask SPF_SCALE_TO_FIT or \
			       mask SPF_PRINT_ROW_COLUMN_TITLES or \
			       mask SPF_CENTER_VERTICALLY or \
			       mask SPF_CENTER_HORIZONTALLY)

DrawHeader	proc	near
	uses	ax, cx, dx, di
	.enter
	mov	ax, mask SPF_PRINT_HEADER	; Check for header OK
	mov	cx, HDR_FTR_FLAGS_TO_CLEAR	; Flags to clear before draw
	lea	dx, ss:[bp].GCPP_headerArea	; Area/Range to draw
	lea	di, ss:[bp].GCPP_headerRange	; Top/left
	call	DrawSpreadsheetRange		; Draw it
	.leave
	ret
DrawHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFooter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the footer...

CALLED BY:	PrintNextPage
PASS:		^lbx:si	= Spreadsheet object
		ss:bp	= GeoCalcPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFooter	proc	near
	uses	ax, cx, dx, di
	.enter
	mov	ax, mask SPF_PRINT_FOOTER	; Check for footer OK
	mov	cx, HDR_FTR_FLAGS_TO_CLEAR	; Flags to clear before draw
	lea	dx, ss:[bp].GCPP_footerArea	; Area/Range to draw
	lea	di, ss:[bp].GCPP_footerRange	; Top/left
	call	DrawSpreadsheetRange		; Draw it
	.leave
	ret
DrawFooter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the body...

CALLED BY:	PrintNextPage
PASS:		^lbx:si	= Spreadsheet instance
		ss:bp	= GeoCalcPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BODY_FLAGS_TO_CLEAR	= not (mask SPF_PRINT_HEADER or \
			       mask SPF_PRINT_FOOTER)
DrawBody	proc	near
	uses	ax, cx, dx, di
	.enter
	;
	; Setup and draw the area.
	;
	mov	ax, -1				; Always draw
	mov	cx, BODY_FLAGS_TO_CLEAR
	lea	dx, ss:[bp].GCPP_bodyArea	; Area/Range to draw
	lea	di, ss:[bp].GCPP_topLeft	; Top/left
	call	DrawSpreadsheetRange		; Draw it
	;
	; Save the top-left that was returned.
	;
	mov	ax, ss:[bp].GCPP_sdp.SDP_topLeft.CR_column
	mov	ss:[bp].GCPP_topLeft.CR_column, ax
	mov	ax, ss:[bp].GCPP_sdp.SDP_topLeft.CR_row
	mov	ss:[bp].GCPP_topLeft.CR_row, ax

	.leave
	ret
DrawBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpreadsheetRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a range of the spreadsheet

CALLED BY:	DrawHeader, DrawFooter
PASS:		^lbx:si	= Spreadsheet instance
		ss:bp	= GeoCalcPrintParams
		ax	= Flag to check to decide if we want to draw
			= -1 to ALWAYS draw
		cx	= Flags to preserve before drawing (ie. !cleared)
		ss:dx	= Pointer to combination of stuff to draw:
				Area (RectDWord)
				Range (CellRange)
		ss:di	= Pointer to top/left top copy
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if ax != -1 then
	    if flags & ax == 0 then
		quit
	    endif
	endif
	
	Copy area and rectangle
	Copy top-left

	Save flags
	Clear flags

	Draw the range

	Restore flags

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpreadsheetRange	proc	near
	uses	ax, cx, dx, di, es
	.enter
	;
	; Check the flags to see if we want to draw anything at all.
	;
	cmp	ax, -1				; Check for always draw
	je	drawRange
	test	ss:[bp].GCPP_sdp.SDP_printFlags, ax
	LONG jz	quit				; Branch if we don't want to

drawRange:
	;
	; We want to draw.
	;	^lbx:si	= Instance ptr
	;	ss:bp	= GeoCalcPrintParams
	;	cx	= Flags to clear (zero if none)
	;	ss:dx	= Pointer to Area/CellRange to copy
	;	ss:di	= Pointer to top/left CellReference
	;
	push	cx, ds, si			; Save flags and instance ptr
	;
	; Copy the area to draw to and the range to draw.
	;
	push	di				; Save pointer to top/left
	segmov	ds, ss, si			; ds:si <- ptr to source
	mov	si, dx

	segmov	es, ss, di			; es:di <- ptr to dest
	lea	di, ss:[bp].GCPP_sdp.SDP_drawArea

	mov	cx, (size RectDWord + size CellRange)/(size word)
	rep	movsw				; Copy the area and limit
	pop	si				; ds:si <- source of top/left

	;
	; Copy the top/left point to use.
	;
	lea	di, ss:[bp].GCPP_sdp.SDP_topLeft ; es:di <- ptr to top/left
	mov	cx, (size CellReference)/(size word)
	rep	movsw				; Copy me jesus

	pop	cx, ds, si			; Restore flags and instance ptr
	;
	; Make sure there's something to draw...
	;
	cmp	ss:[bp].GCPP_sdp.SDP_topLeft.CR_row, -1
	je	quit
	
	;
	; Clear flags, saving any if need be.
	;
	push	ss:[bp].GCPP_sdp.SDP_printFlags		; Save the old flags
	andnf	ss:[bp].GCPP_sdp.SDP_printFlags, cx	; Clear the flags
	;
	; If we're printing graphics but not printing the spreadsheet,
	; tell spreadsheet to skip the draw but still return stuff
	;
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_DOCUMENT
	jnz	doPrint				;branch if printing normally
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_GRAPHICS
	jz	skipPrint			;branch if no graphics or ssheet
	ornf	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_SKIP_DRAW
doPrint:
	;
	; Draw the area:
	;	Area, Range, flags are all set
	; On stack:
	;	Old flags, if we cleared any bits
	; ^lbx:si= Spreadsheet instance
	; ss:bp	 = GeoCalcPrintParams
	;
CheckHack <(offset GCPP_sdp) eq 0>
	push	cx, bp				; Save flags to clear, frame
	mov	ax, MSG_SPREADSHEET_DRAW_RANGE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	cx, bp				; Restore flags to clear, frame

	;
	; We can't just restore the flags, we need to preserve the "done" flag
	;
skipPrint:
	mov	ax, ss:[bp].GCPP_sdp.SDP_printFlags	; ax <- current flag

	pop	ss:[bp].GCPP_sdp.SDP_printFlags		; Pop flags

	andnf	ax, mask SPF_DONE		; ax <- done flag
	ornf	ss:[bp].GCPP_sdp.SDP_printFlags, ax
	;
	; If we're drawing graphics, tell the GrObj to draw something, too
	;
	call	DrawGraphicsLayer					
quit:
	.leave
	ret
DrawSpreadsheetRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDocRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one document rectangle to another

CALLED BY:	Utility
PASS:		ss:si	= Source RectDWord
		ss:di	= Dest RectDWord
RETURN:		Dest <- Source
DESTROYED:	di, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDocRect	proc	near
	uses	cx, ds, es
	.enter
	segmov	es, ss, cx			; es:di <- dest
	mov	ds, cx				; ds:si <- source
	mov	cx, size RectDWord		; cx <- size
	rep	movsb				; Copy the rectangle
	.leave
	ret
CopyDocRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetHeaderHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the header

CALLED BY:	SetPageToRange
PASS:		^lbx:si	= OD of spreadsheet object
		ss:bp	= GeoCalcPrintParams
RETURN:		dx:ax	= Height of the header
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetHeaderHeight	proc	near
	uses	cx, bp
	.enter
	mov	ax, ss:[bp].GCPP_headerRange.CR_start.CR_row
	mov	cx, ss:[bp].GCPP_headerRange.CR_start.CR_column
	mov	dx, ss:[bp].GCPP_headerRange.CR_end.CR_row
	mov	bp, ss:[bp].GCPP_headerRange.CR_end.CR_column
	call	GetRangeHeight		; ax <- height of the range
	.leave
	ret
GetHeaderHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of a range

CALLED BY:	GetHeaderHeight, GetFooterHeight
PASS:		ax/cx	= Row/Column of top-left of the range
		dx/bp	= Row/Column of bottom-right of the range
		^lbx:si = OD of spreadsheet object
RETURN:		dx:ax	= Height of the range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRangeHeight	proc	near
	uses	cx, bp, di
	.enter
	;
	; ax/cx	= Row/Column of top-left of spreadsheet
	; dx/bp	= Row/Column of bottom-right of spreadsheet
	;
	cmp	ax, -1			; Check for no header
	je	noHeader		; Branch if none
	
	;
	; The header exists. We need to get the extent...
	;
	push	bp, dx, cx, ax		; Push CellRange
	mov	dx, ss
	mov	bp, sp			; dx:bp <- ptr to the CellRange

	sub	sp, size RectDWord	; Make space for result
	mov	cx, sp			; dx:cx <- ptr to RectDWord

	push	cx			; Save ptr to the result
	mov	ax, MSG_SPREADSHEET_GET_RANGE_BOUNDS
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp			; ss:bp <- ptr to the result
	
	mov	ax, ss:[bp].RD_bottom.low
	sub	ax, ss:[bp].RD_top.low
	mov	dx, ss:[bp].RD_bottom.high
	sbb	dx, ss:[bp].RD_top.high
	
	;
	; Fixup the stack before leaving.
	;
	add	sp, size RectDWord + size CellRange
quit:
	.leave
	ret

noHeader:
	clr	ax, dx			; No header height
	jmp	quit
GetRangeHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFooterHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the height of the footer

CALLED BY:	SetPageToRange
PASS:		^lbx:si = OD of spreadsheet object
		ss:bp	= GeoCalcPrintParams
RETURN:		dx:ax	= Height of the footer
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFooterHeight	proc	near
	uses	cx, bp
	.enter
	mov	ax, ss:[bp].GCPP_footerRange.CR_start.CR_row
	mov	cx, ss:[bp].GCPP_footerRange.CR_start.CR_column
	mov	dx, ss:[bp].GCPP_footerRange.CR_end.CR_row
	mov	bp, ss:[bp].GCPP_footerRange.CR_end.CR_column
	call	GetRangeHeight		; ax <- height of the range
	.leave
	ret
GetFooterHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the notes associated with a document

CALLED BY:	GeoCalcDocumentStartPrinting()
PASS:		^lcx:dx	= OD of SpoolPrintControl object
		^lbx:si	= OD of Spreadsheet
		ss:bp	= GeoCalcPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	nOnThisPage = 0
	SpreadsheetRangeEnum():
	    if (row/column is in bodyRange) then
		if (nOnThisPage == 0) then
		    SignalPrintingPage()
		    DrawHeader()
		endif

		if (nOnThisPage == 0 or note fits) then
		    DrawNote()
		    nOnThisPage++
		else
		    DrawFooter()
		    GrNewPage()
		    nOnThisPage = 0
		endif
	    endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintNotes	proc	near
	uses	ax, cx, dx, di
	.enter
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_NOTES
	jz	quit				; Quit if not printing notes
	;
	; Set the page size to be the paper size. Set the document size
	; to the the paper size minus margins. Refigure the header, footer,
	; and body areas.
	;
	call	SetNotePageAndDocSize		; Set the page/doc size

	;
	; Initialize GCPP_notePos for the first note.
	;
	mov	ax, ss:[bp].GCPP_bodyArea.RD_top.low
	mov	ss:[bp].GCPP_notePos, ax
	
	;
	; Set up the parameters for MSG_SPREADSHEET_RANGE_ENUM_DATA.
	;
	push	bp				; Save frame ptr
	mov	cx, SEGMENT_CS			; cx:dx <- callback routine
	mov	dx, offset cs:PrintNotesCallback
	
	mov	ax, MSG_SPREADSHEET_NOTES_ENUM
	mov	di, mask MF_CALL		; Call spreadsheet to do enum
	call	ObjMessage
	pop	bp				; Restore frame ptr

	;
	; See if we ended right on the end of a page.
	;
	mov	ax, ss:[bp].GCPP_notePos
	cmp	ax, ss:[bp].GCPP_bodyArea.RD_top.low
	je	quit				; Branch if we finished a page
	
	;
	; We didn't stop right at the end of a page. Draw the missing footer.
	;
	call	DrawFooter			; Otherwise draw the footer
	inc	ss:[bp].GCPP_page		; Next page to draw
	inc	ss:currentPage

	; Do a new page at the end of every notes page.

	mov	di, ss:[bp].GCPP_sdp.SDP_gstate	; di <- gstate handle
	mov	al, PEC_FORM_FEED
	call	GrNewPage			; Draw a new page
quit:
	.leave
	ret
PrintNotes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNotePageAndDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the page and document size for printing notes.

CALLED BY:	PrintNotes
PASS:		^lcx:dx	= SpoolPrintControl object
		^lbx:si	= Spreadsheet object
		ss:bp	= GeoCalcPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Set the page size to the paper size
	Set the document size
	Recalc the header/footer area
	Recalc the body area

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNotePageAndDocSize	proc	near
	;
	; Clear the scale-to-fit and continuous printing flags.
	;
	andnf	ss:[bp].GCPP_sdp.SDP_printFlags, not (mask SPF_SCALE_TO_FIT or \
					mask SPF_CONTINUOUS)
	
	call	FigureAreas			; Compute the areas...
	ret
SetNotePageAndDocSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintNotesCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for printing notes.

CALLED BY:	PrintNotes via MSG_SPREADSHEET_NOTES_ENUM
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
		ax	= Row of cell
		cx	= Column of cell
		*es:di	= Pointer to notes text
		^ldx:si	= Spreadsheet object
RETURN:		carry set to abort enum
DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; Number of points of padding to place between each note.
;
NOTE_PADDING	=	4

PrintNotesCallback	proc	far
	uses	ax, bx, di, bp
	.enter
	mov	bx, dx				; ^lbx:si <- Spreadsheet OD
	
	;
	; Copy the text into the text object.
	;
	call	CopyNoteIntoTextObject
	
	;
	; Position the note on the page.
	;
	call	PositionNote

	;
	; Check for first note on the page (y pos = body-area top)
	;
	mov	dx, ss:[bp].GCPP_bodyArea.RD_top.low
	cmp	dx, ss:[bp].GCPP_notePos
	jne	notFirstNote			; Branch if not at top

	;
	; We're at the start of a new page...
	;
	call	SignalPrintingPage		; Signal we're drawing another

if (0)	; We now do new page at the end of the page.  We did a new page at the
	; end of the last document page.  So we don't need to do it before the
	; first note page. - Joon (6/21/95)

	;
	; There's a little work to do here. There are several ways we can get
	; here and we need to distinguish between them:
	;	1) We have finished drawing the document and are drawing notes
	;	2) We didn't draw a document and this is the first note page
	;	3) We didn't draw a document and this is not the first note page
	;
	; In (1) and (3) we want to generate a form-feed with GrNewPage().
	; In (2) we don't want to generate the form-feed.
	;
	; We actually only need to check the page number. Anything other than
	; "1" and we want to generate the form-feed.
	;
	cmp	ss:[bp].GCPP_page, 1		; Check for first page
	je	skipNewPage			; Branch if first page

	push	ax, di				; Save cell ptr
	mov	di, ss:[bp].GCPP_sdp.SDP_gstate	; di <- gstate handle
	mov	al, PEC_FORM_FEED
	call	GrNewPage			; Draw a new page
	pop	ax, di				; Restore cell ptr

skipNewPage:
endif	; if (0)

	call	DrawHeader			; Draw the header

	call	CheckNoteFits			; Force calculation of height
	jmp	drawANote			; Branch to draw first note

notFirstNote:
	;
	; Not the first note, make sure it fits.
	;
	call	CheckNoteFits			; Check for note fitting
	jc	endOfPage			; Branch if it doesn't

drawANote:
	;
	; The note fits or is the first note on the page.
	;
	; dx = position for next note.
	;
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_SKIP_DRAW
	jnz	skipDraw			; branch if calculating
	call	DrawOneNote			; Draw the note
skipDraw:

	add	dx, NOTE_PADDING
	mov	ss:[bp].GCPP_notePos, dx	; Set position for next object
quit:
	clc					; Process next cell...
	.leave
	ret

endOfPage:
	;
	; We've reached the last note that can fit on the page.
	;
	call	DrawFooter			; Draw the footer
	mov	ax, ss:[bp].GCPP_bodyArea.RD_top.low
	mov	ss:[bp].GCPP_notePos, ax	; Initialize the next note pos
	
	inc	ss:[bp].GCPP_page		; Change page number
	inc	ss:currentPage			; Change page number here too

	; Do a new page at the end of every notes page.

	mov	di, ss:[bp].GCPP_sdp.SDP_gstate	; di <- gstate handle
	mov	al, PEC_FORM_FEED
	call	GrNewPage			; Draw a new page

	jmp	quit				; Branch, we're done
PrintNotesCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyNoteIntoTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the text of the note into the text object.

CALLED BY:	PrintNotesCallback
PASS:		^lbx:si	= Spreadsheet object
		*es:di	= Text of the note
		ax	= Row
		cx	= Column
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Format the string "Cell RR:CC\t" into the text object.
	Append the text of the note.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyNoteIntoTextObject	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	mov	dx, es				; dx:bp <- ptr to the text
	mov	bp, es:[di]
	clr	cx				; It's null terminated

	GetResourceHandleNS	PrintTextObject, bx
	mov	si, offset PrintTextObject
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
CopyNoteIntoTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the note on the page.

CALLED BY:	PrintNotesCallback
PASS:		ss:bp	= Pointer to GeoCalcPrintParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; The notes are inset on the page to allow room for a string of the form
; "XX:#####" which is the cell whose note we are printing.
;
; A bit of testing has shown that 1 inch is enough space for this given
; the font and pointsize we're using.
;
NOTES_TEXT_MARGIN	= 54

PositionNote	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	;
	; Now move the object to the right spot.
	;
	GetResourceHandleNS	PrintTextObject, bx
	mov	si, offset PrintTextObject

	mov	cx, ss:[bp].GCPP_bodyArea.RD_left.low
	add	cx, ss:[bp].GCPP_sdp.SDP_margins.P_x
	add	cx, NOTES_TEXT_MARGIN
	
	mov	dx, ss:[bp].GCPP_notePos
	add	dx, ss:[bp].GCPP_sdp.SDP_margins.P_y

	mov	ax, MSG_VIS_SET_POSITION
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
PositionNote	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckNoteFits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a note will fit between the notePos and
		the bottom of the body area.

CALLED BY:	PrintNotesCallback
PASS:		*es:di	= Pointer to the cell data
		ss:bp	= GeoCalcPrintParams
		ds:si	= Spreadsheet instance
RETURN:		carry set if the note doesn't fit
		dx	= Position for next note
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckNoteFits	proc	near
	uses	ax, bx, cx, di, si
	.enter
	;
	; cx <- width of object
	; dx <- Flag to say "force calculation"
	;
	mov	cx, ss:[bp].GCPP_bodyArea.RD_right.low
	sub	cx, ss:[bp].GCPP_bodyArea.RD_left.low
	sub	cx, NOTES_TEXT_MARGIN


	GetResourceHandleNS	PrintTextObject, bx
	mov	si, offset PrintTextObject	; ^lbx:si <- text object

	push	bp				; Save frame ptr

	push	cx				; Save width
	clr	dx
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	mov	di, mask MF_CALL
	call	ObjMessage			; dx <- height of text
	pop	cx				; Restore width
	
	;
	; cx = Width for text object
	; dx = Height for text object
	;
	push	dx				; Save height
	mov	ax, MSG_VIS_SET_SIZE
	mov	di, mask MF_CALL
	call	ObjMessage			; Resize the text object
	
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	mov	di, mask MF_CALL
	call	ObjMessage			; Geometry has changed...
	pop	dx				; Restore height

	pop	bp				; Restore frame ptr
	
	add	dx, ss:[bp].GCPP_notePos	; dx <- bottom of note
	
	cmp	dx, ss:[bp].GCPP_bodyArea.RD_bottom.low
	ja	doesNotFit
	clc					; Signal: note fits
quit:
	.leave
	ret

doesNotFit:
	stc					; Signal: doesn't fit
	jmp	quit
CheckNoteFits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOneNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single note

CALLED BY:	PrintNotesCallback
PASS:		ss:bp	= GeoCalcPrintParams
		^lbx:si	= Spreadsheet instance
		ax	= Row of the cell
		cx	= Column of the cell
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOneNote	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx, di, si, bp, ds, es

	.enter
	;
	; Allocate a stack frame and call the spreadsheet object to format
	; the cell.
	;
	sub	sp, MAX_RANGE_REF_SIZE
	mov	di, sp
	segmov	es, ss				;es:di <- ptr to buffer
	call	ParserFormatCellReference
	mov	bx, di
	;
	; ss:bx = formatted text
	; ss:bp = GeoCalcPrintParams
	;
	mov	di, ss:[bp].GCPP_sdp.SDP_gstate	; di <- gstate handle
	mov	cx, NOTES_FONT			; cx <- font
	mov	dx, NOTES_PTSIZE		; dx.ah <- size
	clr	ah
	call	GrSetFont

	mov	al, mask TS_UNDERLINE		; Set underline
	mov	ah, TextStyle			; Clear everything else
	call	GrSetTextStyle
	;
	; Now draw the text for the cell reference
	;
	; ss:bx	= formatted text
	; ss:bp	= GeoCalcPrintParams
	; di	= GState handle (gstate is already set up)
	;
	segmov	ds, ss, si			; ds <- segment addr of the text
	lea	si, ss:[bx].SFPRP_text		; si <- offset of the text

	mov	ax, ss:[bp].GCPP_bodyArea.RD_left.low
	add	ax, ss:[bp].GCPP_sdp.SDP_margins.P_x
	mov	bx, ss:[bp].GCPP_notePos	; ax/bx <- position for draw
	add	bx, ss:[bp].GCPP_sdp.SDP_margins.P_y

	clr	cx				; cx <- NULL terminated text
	call	GrDrawText
	;
	; Now draw the text object which contains the note.
	;
	mov	bp, di				; bp <- gstate for drawing
	GetResourceHandleNS	PrintTextObject, bx
	mov	si, offset PrintTextObject

	mov	cl, mask DF_EXPOSED or mask DF_PRINT
	mov	ax, MSG_VIS_DRAW
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; Restore stack frame before leaving.
	;
	add	sp, MAX_RANGE_REF_SIZE
	.leave

	ret
DrawOneNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawGraphicsLayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the graphics layer for GeoCalc, if requested

CALLED BY:	DrawSpreadsheetRange()
PASS:		ss:bp - GeoCalcPrintParams
RETURN:		none
DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawGraphicsLayer		proc	near
	uses	bx, si
	.enter

CheckHack <(offset GCPP_sdp) eq 0>
	;
	; Should we bother?  If we aren't printing graphics, or if we
	; aren't actually drawing (ie. just calculating the number of
	; pages), then exit
	;
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_PRINT_GRAPHICS
	LONG jz	quit				;branch if not drawing graphics
	test	ss:[bp].GCPP_sdp.SDP_printFlags, mask SPF_SKIP_DRAW
	LONG jnz	quit			;branch if not printing
	;
	; Translate and scale to match what the spreadsheet did
	; for centering and scale-to-fit.
	;
	mov	di, ss:[bp].SDP_gstate		;di <- handle of GState
	call	GrSaveState
	movdw	dxcx, ss:[bp].SDP_translation.PD_x
	movdw	bxax, ss:[bp].SDP_translation.PD_y
	call	GrApplyTranslationDWord
	movwwf	dxcx, ss:[bp].SDP_scale
	movwwf	bxax, dxcx
	call	GrApplyScale
	;
	; Translate for any titles
	;
	movdw	dxcx, ss:[bp].SDP_titleTrans.PD_x
	movdw	bxax, ss:[bp].SDP_titleTrans.PD_y
	call	GrApplyTranslationDWord
	;
	; Since we're translating to the area printed, our clip
	; rectangle goes from (0,0) now.
	;
	movdw	bxcx, ss:[bp].SDP_rangeArea.RD_right
	subdw	bxcx, ss:[bp].SDP_rangeArea.RD_left
	jnz	noClip				;branch if too large
	movdw	axdx, ss:[bp].SDP_rangeArea.RD_bottom
	subdw	axdx, ss:[bp].SDP_rangeArea.RD_top
	jnz	noClip				;branch if too large
	;
	; If we're going scale-to-fit or continous printing, there's
	; a decent chance that the area to clip to will be larger
	; than the graphics system can handle.  If this is the case,
	; we simply punt on clipping.
	;
	cmp	cx, MAX_COORD/5			;x too large?
	jae	noClip				;branch if too large
	cmp	dx, MAX_COORD/5			;y too large?
	jae	noClip				;branch if too large
	clr	ax, bx				;(ax,bx,cx,dx) <- Rectangle
	mov	si, PCT_REPLACE
	call	GrSetClipRect
noClip:
	;
	; Translate to the actual area that was printed
	;
	movdw	dxcx, ss:[bp].SDP_rangeArea.RD_left
	movdw	bxax, ss:[bp].SDP_rangeArea.RD_top
	negdw	dxcx
	negdw	bxax
	call	GrApplyTranslationDWord
	;
	; Tell yon grobj to draw itself
	;
	push	bp, di
	mov	ax, MSG_VIS_DRAW
	movdw	bxsi, ss:[bp].GCPP_grobj	;^lbx:si <- OD of grobj
	mov	bp, di				;bp <- handle of GState
	mov	cl, mask DF_PRINT		;cl <- DrawFlags
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp, di
	;
	; Clean up
	;
	call	GrRestoreState
quit:

	.leave
	ret
DrawGraphicsLayer		endp

DocumentPrint	ends
