COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentMisc.asm

ROUTINES:
	Name				Description
	----				-----------
    INT ReportPagePrintingProgress 
				Report progress in printing.

    INT ReportMergePrintingProgress 
				Report how many items we have left to
				merge.

    INT QueueForFinishPrinting	Pass a message along to the finish-printing
				handler. The message is sent to the
				print-control when finish-printing happens.

    INT SetDisplayModeMarginsSizeAndPages 
				Set the display mode, and some local
				variables.

    INT DoesHeaderFooterContainText 
				Determine if any header or footer contains
				text

    INT ContainsTextCallback	Send a message to all text objects

    INT CallPrintControl	Call the Print-Control object.

    INT SetDisplayMode		Set the display mode for the document

    INT CheckForMerge		Check to see if we are merging.

    INT SetPageClipRect		Clip all drawing to the current page.

    INT TranslateToPage		Translate all drawing operations to be in
				the right place

    INT ComputePositiveTranslation 
				Compute the position of the top of the
				current page.

METHODS:
	Name			Description
	----			-----------
    StudioDocumentStartPrinting	Print the document

				MSG_PRINT_START_PRINTING
				StudioDocumentClass

    StudioDocumentContinuePrinting  
				Continue printing a document.

				MSG_STUDIO_DOCUMENT_CONTINUE_PRINTING
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for StudioDocumentClass

	$Id: documentPrint.asm,v 1.1 97/04/04 14:39:01 newdeal Exp $

------------------------------------------------------------------------------@

DocPrint segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the document

CALLED BY:	via MSG_PRINT_START_PRINTING
PASS:		*ds:si	= StudioDocument instance
		es	= segment of StudioDocumentClass
		^lcx:dx	= PrintControl object
		bp	= GState
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:
	So you may be asking... Why do we start printing, then continue
	printing? Good question... 
	
	It is a remnant from when we thought that mail-merge would require 
	a detach-ui being sent to the document. Since any message which
	relies on the detach-ui must come in on the queue to allow other
	events to be flushed, we needed to continue printing after the
	detach-ui had cleared.

	Of course now we don't do it that way, but it would be a pain
	to change it back, and it doesn't hurt anything really.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentStartPrinting	method dynamic	StudioDocumentClass,
						MSG_PRINT_START_PRINTING
	;
	; If we're merging, we need detach the ui.
	;
	call	CheckForMerge			; ax <- merge type
	
	cmp	ax, MT_NONE			; Check for none
	je	afterDetach			; Branch if none

	;
	; We're merging... We used to update the file and detach the ui here.
	;
	push	cx, dx, bp			; Save everything

	clc					; Signal: no error

checkError::
	;
	; Carry set if there was an error.
	;
	pop	cx, dx, bp			; Restore everything
	jc	tellUserAboutError		; Branch on error

afterDetach:
	;
	; Queue up the message to continue printing, passing the same
	; parameters that we received.
	;
	mov	ax, MSG_STUDIO_DOCUMENT_CONTINUE_PRINTING
	mov	bx, ds:LMBH_handle		; ^lbx:si <- our OD
	mov	di, mask MF_FORCE_QUEUE		; Queue it behind the detach
	call	ObjMessage			; Finish printing
quit:
	ret


;-----------------------------------------------------------------------------

tellUserAboutError:
	;
	; Notify the user of the problem.
	;
	mov	si, offset GeneralMergeError
	call	DisplayError

	;
	; Abort printing.
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	movdw	bxsi, cxdx
	mov	di, mask MF_CALL
	call	ObjMessage

	jmp	quit
StudioDocumentStartPrinting	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentContinuePrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue printing a document.

CALLED BY:	via MSG_STUDIO_DOCUMENT_CONTINUE_PRINTING
PASS:		*ds:si	= Instance
		^lcx:dx	= PrintControl object
		bp	= GState
		es	= dgroup
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:
	We no longer attempt to use revert in order to make mail-merge
	work. We now use the undo mechanism. Hahahahahahaha.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentContinuePrinting	method	dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_CONTINUE_PRINTING

	mov	di, bp
printControl	local	optr	push	cx, dx
	;
	; Print control object to send messages to.
	;

pageSize	local	XYSize
	;
	; Size of the page we're printing. Taken from the document.
	;

pageNumber	local	word
	;
	; The current page number.
	;

pageMargins	local	Rectangle
	;
	; Margins, taken from the print-control
	;

firstDocPage	local	word
	;
	; The first page in the document
	;

firstPage	local	word
	;
	; The first page the user wants printed.
	;

lastPage	local	word
	;
	; The last page the user wants printed.
	;

mergeCount	local	word
	;
	; The number of entries that need merging.
	;

merging		local	MergeType
	;
	; What sort of merge we're doing.
	;

ssmetaData	local	SSMetaStruc
	;
	; The data for merging with
	;

fieldNameList	local	optr
	;
	; The block containing the list of field-names to use when replacing.
	;

oldUndoContext	local	dword
	;
	; The undo context before we got started...
	;

dataBlock	local	word
	;
	; If the data required formatting (eg: constant or formula) then
	; we may need to allocate a block to hold it. This contains the
	; handle of the block.
	;
	; This value is zeroed before the "lock data/field" routines
	; are called and is checked and free'd when the "unlock data/field"
	; routines are called.
	;

mergeFeedbackBuffer	local	MAX_MERGE_FEEDBACK_STRING_SIZE dup (char)
	;
	; This buffer holds the string we are using for feedback while
	; merging.
	;

mergeFeedbackNumberBase	local	word
	;
	; The offset into the above buffer where we want to write the
	; number. This really should be at the end of the string, otherwise
	; it won't work.
	;

scrapLibraryHandle	local	hptr
	;
	; Handle to the scrap library.
	;

ForceRef	printControl
ForceRef	pageSize
ForceRef	pageMargins
ForceRef	mergeCount
ForceRef	ssmetaData
ForceRef	fieldNameList
ForceRef	oldUndoContext
ForceRef	dataBlock
ForceRef	mergeFeedbackBuffer
ForceRef	mergeFeedbackNumberBase
ForceRef	scrapLibraryHandle
ForceRef	firstDocPage
	.enter

	call	CheckForMerge			; See if we're merging
	mov	merging, ax
	;
	; Do merge setup if it's required.
	;
	cmp	merging, MT_NONE			; Check for none
	je	afterMergeSetup
	call	SetupForMerge
	LONG jc	abortPrintingAfterMergeSetup

	;
	; Invalidate the articles so they don't redraw each time we merge
	; the data in.
	;
	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp

afterMergeSetup:

	;
	; Change to PAGE mode for printing, and fill in the pageSize and
	; pageMargins local variables.
	;
	call	SetDisplayModeMarginsSizeAndPages ; ax <- old display mode
	push	ax				; Save old display mode

;-----------------------------------------------------------------------------
;			      Merge Loop
;-----------------------------------------------------------------------------
mergeLoop:
	;
	; Merge the next record.
	;
	cmp	merging, MT_NONE
	je	afterMergeNext
	call	MergeNextEntry
	jc	endLoop				; Branch if no more to do

	call	ReportMergePrintingProgress
	
	;
	; Check for the user cancelling the operation.
	;
	cmp	ax, FALSE
	jne	afterMergeNext

	; Undo the changes we just made
	;
	call	RevertToOriginalDocument
	jmp	userAbortedBetweenDocs


afterMergeNext:

	mov	cx, firstPage			; cx <- first page
	mov	dx, lastPage			; dx <- last page

	mov	pageNumber, cx			; Set first page
	sub	dx, cx				; dx <- # of pages to do
	inc	dx				; Make it 1 based
	mov_tr	ax, cx				; ax <- first
	mov	cx, dx				; cx <- count
	
;-----------------------------------------------------------------------------
;			      Print Loop
;-----------------------------------------------------------------------------
	;
	; cx	= Number of pages to print
	; di	= GState to print with
	;
	; The following local variables set:
	;	pageNumber	- Current page number
	;	firstPage	- First page we printed
	;	pageMargins	- Offset to page in drawing area
	;	pageSize	- Size of the page we are printing
	;
printLoop:
	push	cx				; Save number of pages

	;
	; Tell the print control that we are printing this page
	;
	call	ReportPagePrintingProgress
	
	;
	; Check for the user cancelling the operation.
	;
	cmp	ax, FALSE
	je	userAbortedPrinting		; Branch if user aborted

	;
	; Want to make the page self-describing.  This should force that
	; notion...
	;
	call	GrSaveState

	;
	; Set the clip rectangle so that we only draw this page
	;
	call	SetPageClipRect			; Clip to page only

	;
	; Compute the position of the current page and translate there.
	; Account for margins too.
	;
	call	TranslateToPage			; Put drawing in right place
	
	;
	; Make this the default transformation so that when the text object
	; translates for the various regions it translates relative to this
	;
	call	GrInitDefaultTransform

	;
	; Draw the document.
	;
	push	bp
	mov	bp, di				; bp <- gstate
	mov	cl, mask DF_PRINT		; cl <- DrawFlags
	mov	ax, MSG_VIS_DRAW
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; Before finishing, restore the state of things
	;
	call	GrRestoreState

	;
	; Move down a page
	;
	mov	al, PEC_FORM_FEED
	call	GrNewPage

	;
	; Move to do next page
	;
	pop	cx				; cx <- # of pages left
	inc	pageNumber			; Advance to next page
	loop	printLoop			; Loop to do it
	
	cmp	merging, MT_NONE		; Check for none
	je	endLoop				; Loop if there is
	
	;
	; Revert to the previous document.
	;
	call	RevertToOriginalDocument
	jmp	mergeLoop			; Loop to merge next record
	

endLoop:
;-----------------------------------------------------------------------------
;		       Clean Up After Document
;-----------------------------------------------------------------------------
	;
	; change into old display mode
	;
	pop	cx
	cmp	cx, VLTDM_PAGE
	jz	afterRestoreMode

	call	SetDisplayMode

afterRestoreMode:
	;
	; Pass the message to send to the print-control to ourselves via
	; the queue.
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED

quit:
	;
	; ax	= Message to pass to print-control now that we're done.
	;
	; We used to need to attach the UI first...
	;
	call	QueueForFinishPrinting		; Queue print-control message

	;
	; Cleanup after merging.
	;
	cmp	merging, MT_NONE		; Check for none
	je	afterMergeCleanup
	call	CleanupAfterMerge
afterMergeCleanup:

	.leave
	ret

;-----------------------------------------------------------------------------
;			    Abort Printing
;-----------------------------------------------------------------------------
abortPrintingAfterMergeSetup:
	mov	merging, MT_NONE		; 
	jmp	cancelPrinting

;-------------

userAbortedPrinting:
	pop	cx				; Restore stack (# of pages)


userAbortedBetweenDocs:
	;
	; change into old display mode
	;
	pop	cx
	cmp	cx, VLTDM_PAGE
	jz	cancelPrinting

	call	SetDisplayMode

cancelPrinting:
	;
	; Abort the printing by notifying the print-control object, restoring
	; the mode, and quitting.
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	jmp	quit				; And quit...

StudioDocumentContinuePrinting	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportPagePrintingProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report progress in printing.

CALLED BY:	StudioDocumentContinuePrinting
PASS:		ss:bp	= Inheritable stack frame
RETURN:		ax	= FALSE to cancel printing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReportPagePrintingProgress	proc	near
	uses	cx, dx, bp
	.enter	inherit StudioDocumentContinuePrinting

	mov	dx, pageNumber
	mov	cx, PCPT_PAGE
	mov	ax, MSG_PRINT_CONTROL_REPORT_PROGRESS
	call	CallPrintControl

	.leave
	ret
ReportPagePrintingProgress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportMergePrintingProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report how many items we have left to merge.

CALLED BY:	StudioDocumentContinuePrinting
PASS:		ss:bp	= Inheritable stack frame
RETURN:		ax	= FALSE to cancel printing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReportMergePrintingProgress	proc	near
	uses	bx, cx, dx, bp, di, si, es
	.enter	inherit StudioDocumentContinuePrinting
	;
	; Fill in the number at the end of the string.
	;
	segmov	es, ss, di			; es:di <- string pointer
	lea	di, mergeFeedbackBuffer
	add	di, mergeFeedbackNumberBase	; es:di <- place for number
	
	mov	cx, mask UHTAF_NULL_TERMINATE

	mov	ax, mergeCount			; dx.ax <- Number to display
	inc	ax
	clr	dx
	
	call	UtilHex32ToAscii		; Studio the number and NULL

	;
	; Notify the print control. We can't use CallPrintControl because
	; we won't have bp pointing at the stack frame.
	;
	movdw	bxsi, printControl		; ^lbx:si <- printControl

	mov	dx, ss				; dx:bp <- ptr to string
	lea	bp, mergeFeedbackBuffer

	mov	cx, PCPT_TEXT			; Display text

	mov	ax, MSG_PRINT_CONTROL_REPORT_PROGRESS
	mov	di, mask MF_CALL
	call	ObjMessage
	.leave
	ret
ReportMergePrintingProgress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueForFinishPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass a message along to the finish-printing handler. The
		message is sent to the print-control when finish-printing
		happens.

CALLED BY:	StudioDocumentContinuePrinting
PASS:		*ds:si	= StudioDocument instance
		ax	= Message to send
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QueueForFinishPrinting	proc	near
	uses	ax, bx, di, si
	.enter	inherit StudioDocumentContinuePrinting

	movdw	bxsi, printControl		; ^lbx:si <- print-control
	mov	di, mask MF_FORCE_QUEUE		; Queue it behind the detach
	call	ObjMessage			; Finish printing
	.leave
	ret
QueueForFinishPrinting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDisplayModeMarginsSizeAndPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the display mode, and some local variables.

CALLED BY:	StudioDocumentStartPrinting
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable stack frame
RETURN:		ax	= Old page mode
		Set:
			pageMargins
			pageSize
			firstPage
			lastPage
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDisplayModeMarginsSizeAndPages	proc	near
	uses	bx, cx, dx, di, es
	.enter	inherit	StudioDocumentContinuePrinting
	;
	; If not in page mode then change to PAGE mode for printing.
	;
	call	LockMapBlockES
	mov	ax, es:MBH_displayMode
	push	ax
	cmp	ax, VLTDM_PAGE
	jz	afterSetMode

	mov	cx, VLTDM_PAGE
	call	SetDisplayMode

afterSetMode:

	; Get the starting page number

	clr	ax
	call	SectionArrayEToP_ES
	mov	ax, es:[di].SAE_startingPageNum
	mov	firstDocPage, ax

	; Get the printer margins

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_PRINTER_MARGINS
	mov	dx, FALSE			; do not set the margins too
	call	CallPrintControl		; margins => AX, CX, DX, BP
	mov	di, bp
	pop	bp

	; if this is a landscape document then swap the top/left and
	; right/bottom

	test	es:MBH_pageInfo, mask PLP_ORIENTATION
	jz	notLandscape
	xchg	ax, cx
	xchg	dx, di
notLandscape:

	mov	pageMargins.R_left, ax
	mov	pageMargins.R_top, cx
	mov	pageMargins.R_right, dx
	mov	pageMargins.R_bottom, di

	; if there is a non-empty header of footer then pass 1/4" for the
	; margins

	call	DoesHeaderFooterContainText
	jnc	afterHeaderFooter
	mov	ax, PIXELS_PER_INCH / 4
	mov	pageMargins.R_left, ax
	mov	pageMargins.R_top, ax
	mov	pageMargins.R_right, ax
	mov	pageMargins.R_bottom, ax
afterHeaderFooter:

	; Set the printer marginsmso that the print control knows that we
	; are using the correct margins

	push	si, bp
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_MARGINS
	mov	dx, ss
	mov	di, mask MF_CALL
	movdw	bxsi, printControl
	lea	bp, pageMargins
	call	ObjMessage
	pop	si, bp

	;
	; Get the page size from the document and store it in a local
	; variable
	;
	mov	ax, es:MBH_pageSize.XYS_width
	mov	bx, es:MBH_pageSize.XYS_height
	call	VMUnlockES
	mov	pageSize.XYS_width, ax
	mov	pageSize.XYS_height, bx

	;
	; Get the page range to print (the range that the user set)
	;
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE
	call	CallPrintControl		; cx = first, dx = last
	pop	bp

	mov	firstPage, cx
	mov	lastPage, dx
	
	pop	ax				; ax <- old display mode
	.leave
	ret
SetDisplayModeMarginsSizeAndPages	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoesHeaderFooterContainText

DESCRIPTION:	Determine if any header or footer contains text

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block (locked)

RETURN:
	carry - set if any header or footer contains text

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/93		Initial version

------------------------------------------------------------------------------@
DoesHeaderFooterContainText	proc	near
				uses ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	; enumerate all sections

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset ContainsTextCallback
	call	ChunkArrayEnum

	.leave
	ret

DoesHeaderFooterContainText	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ContainsTextCallback

DESCRIPTION:	Send a message to all text objects

CALLED BY:	StudioDocumentReportPageSize (via ChunkArrayEnum)

PASS:
	ds:di - SectionArrayElement
	bp - message

RETURN:
	carry - set if header of footer contains text

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
ContainsTextCallback	proc	far

	; loop through each master page

	mov	cx, ds:[di].SAE_numMasterPages
	clr	bx
checkLoop:
	push	bx, cx, dx, di, bp

	mov	bx, ds:[di][bx].SAE_masterPages
	call	VMBlockToMemBlockRefDS			;bx = MP block

	push	bx, ds
	call	ObjLockObjBlock
	mov	ds, ax
	movdw	bxsi, ds:[MPBH_header]
	call	containsText
	jc	10$
	movdw	bxsi, ds:[MPBH_footer]
	call	containsText
10$:
	pop	bx, ds
	call	MemUnlock

	pop	bx, cx, dx, di, bp
	jc	done

	add	bx, size hptr
	loop	checkLoop

	clc
done:
	.leave
	ret

;---

	; return carry set if object contains text

containsText:
	tst_clc	bx
	jz	containsDone
	call	VMBlockToMemBlockRefDS
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL
	call	ObjMessage			;cxdx = ward
	movdw	bxsi, cxdx

	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	di, mask MF_CALL
	call	ObjMessage			;dxax = size
	tstdw	dxax
	stc
	jnz	containsDone
	clc
containsDone:
	retn

ContainsTextCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the Print-Control object.

CALLED BY:	StudioDocumentStartPrinting
PASS:		ss:bp	= Inheritable stack frame
		<arguments for the message>
RETURN:		<return values from message>
DESTROYED:	<destroyed values from message>

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallPrintControl	proc	near
	.enter	inherit	StudioDocumentContinuePrinting
	push	di
	mov	di, mask MF_CALL
;;; callSendCommon	label	near
	push	bx, si
	movdw	bxsi, printControl
	call	ObjMessage
	pop	bx, si
	pop	di
	.leave
	ret
CallPrintControl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the PrintControl object

CALLED BY:	StudioDocumentStartPrinting
PASS:		ss:bp	= Inheritable stack frame
		<other arguments for message>
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;;; SendToPrintControl	proc	near
;;;	push	di
;;;	clr	di
;;;	jmp	callSendCommon
;;; SendToPrintControl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDisplayMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the display mode for the document

CALLED BY:	StudioDocumentStartPrinting
PASS:		*ds:si	= Instance
		cx	= Display mode
RETURN:		dx	= Old display mode
		bp preserved
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDisplayMode	proc	far
	push	bp
	mov	ax, MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE_LOW
	call	ObjCallInstanceNoLock
	pop	bp
	ret
SetDisplayMode	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForMerge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we are merging.

CALLED BY:	StudioDocumentStartPrinting
PASS:		*ds:si	= Instance ptr
		ss:bp	= Inheritable stack frame
RETURN:		ax	= MergeType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Checks to see what merge option the user selected (if any) and
	sets appropriate boolean values.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine is here so that if we aren't merging we can avoid
	loading in the DocMerge resource.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForMerge	proc	near
	uses	bx, cx, dx, di, si
	.enter	inherit	StudioDocumentContinuePrinting

	;
	; Get the merge-selection from the list
	;
	push	bp				; Save frame ptr

	GetResourceHandleNS	MergeList, bx
	mov	si, offset MergeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			; carry set if none selected
	pop	bp				; Restore frame ptr
	jc	nothingSelected			; Branch if nothing selected
	
quit:
	.leave
	ret

nothingSelected:
	mov	ax, MT_NONE			; We're not merging
	jmp	quit

CheckForMerge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPageClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clip all drawing to the current page.

CALLED BY:	StudioDocumentStartPrinting
PASS:		di	= GState to clip in
		ss:bp	= Inheritable stack frame
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		NOTE: We set the clip rectangle *before* any translations
		      are applied, so the clip area is always on the part
		      of the page that is being printed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPageClipRect	proc	near
	uses	si
	.enter	inherit	StudioDocumentContinuePrinting

	;
	; Set the clip-rectangle
	;
	clr	ax				; ax...dx <- page bounds
	clr	bx
	mov	cx, pageSize.XYS_width
	mov	dx, pageSize.XYS_height
	mov	si, PCT_REPLACE			; Replace old clip-rect
	call	GrSetClipRect		; Clip to page
	
	.leave
	ret
SetPageClipRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateToPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate all drawing operations to be in the right place

CALLED BY:	StudioDocumentStartPrinting
PASS:		ss:bp	= Inheritable stack frame
		di	= GState to translate in
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateToPage	proc	near
	.enter	inherit	StudioDocumentContinuePrinting
	;
	; The Y translation is the page-number (in the document) multiplied
	; by the height of each page.
	;
	call	ComputePositiveTranslation	; bx.ax <- y translation
						; cx.dx <- x translation

	negdw	bxax				; bx.ax = Y translation
	call	GrApplyTranslationDWord		; Translate to the right spot
	.leave
	ret
TranslateToPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputePositiveTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the position of the top of the current page.

CALLED BY:	TranslateToPage, SetPageClipRect
PASS:		ss:bp	= Inheritable stack frame
RETURN:		bx.ax	= Y position on page
		dx.cx	= X position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputePositiveTranslation	proc	near
	.enter	inherit	StudioDocumentContinuePrinting
	mov	ax, pageNumber			; ax = first page (zero based)
	sub	ax, firstDocPage

	mov	bx, pageSize.XYS_height		; Figure the top of the page
	mul	bx				; dx.ax <- Y position

	mov	bx, dx				; bx.ax = y pos
	clrdw	dxcx				; cx.dx <- X translation
	.leave
	ret
ComputePositiveTranslation	endp

DocPrint ends
