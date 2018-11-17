COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentMisc.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for WriteDocumentClass

	$Id: documentPrint.asm,v 1.2 98/01/27 21:40:48 gene Exp $

------------------------------------------------------------------------------@

DocPrint segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print the document

CALLED BY:	via MSG_PRINT_START_PRINTING
PASS:		*ds:si	= WriteDocument instance
		es	= segment of WriteDocumentClass
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
WriteDocumentStartPrinting	method dynamic	WriteDocumentClass,
						MSG_PRINT_START_PRINTING

if	_SINGLE_PAGE_SPOOLING
	;
	; If the print job was aborted from the control panel, skip this
	; pass without printing.
	;

	test	ds:[di].WDI_state, mask WDS_PRINT_JOB_ABORTED
	jnz	quitNoErrorBox
endif

	;
	; Queue up the message to continue printing, passing the same
	; parameters that we received.
	;
	mov	ax, MSG_WRITE_DOCUMENT_CONTINUE_PRINTING
	mov	bx, ds:LMBH_handle		; ^lbx:si <- our OD
	mov	di, mask MF_FORCE_QUEUE		; Queue it behind the detach
	GOTO	ObjMessage			; Finish printing


;-----------------------------------------------------------------------------

if	_SINGLE_PAGE_SPOOLING
quitNoErrorBox:
	;
	; Abort printing.
	;
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	movdw	bxsi, cxdx
	mov	di, mask MF_CALL
	GOTO	ObjMessage
endif
WriteDocumentStartPrinting	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentContinuePrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue printing a document.

CALLED BY:	via MSG_WRITE_DOCUMENT_CONTINUE_PRINTING
PASS:		*ds:si	= Instance
		^lcx:dx	= PrintControl object
		bp	= GState
		es	= segment of WriteDocumentClass
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
WriteDocumentContinuePrinting	method	dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_CONTINUE_PRINTING

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

if DBCS_PCGEOS
mergeFeedbackBuffer	local	MAX_MERGE_FEEDBACK_STRING_SIZE/2 dup (wchar)
else
mergeFeedbackBuffer	local	MAX_MERGE_FEEDBACK_STRING_SIZE dup (char)
endif
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

wasDirty	local	word
	;
	; The dirty state of the document before we got started
	;
if	_SINGLE_PAGE_SPOOLING
recursing		local	BooleanByte
recurseToPrint		local	BooleanByte
documentObj		local	optr
endif

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

		
if	_SINGLE_PAGE_SPOOLING

	; Check to see if this is a recursive call to print a single page
	; if so then we are not merging, just printing

	mov	bx, ds:[LMBH_handle]
	movdw	documentObj, bxsi

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_ATTRS
	call	CallPrintControl		; cx = PrintControlAttrs
	pop	bp
	test	cx, mask PCA_USES_DIALOG_BOX
	jnz	notRecursing

	; we are recursing (meaning that another START_PRINTING call has
	; called us to print a single page)

	mov	recursing, BB_TRUE
	mov	recurseToPrint, BB_FALSE
	clr	ax
	jmp	haveMergeStatus


	; we are not recursing (meaning that this is the top level
	; START_PRINTING call).  Test to see if we should recurse to do
	; our printing

notRecursing:
	mov	recurseToPrint, BB_FALSE	;assume no recursion used
	mov	recursing, BB_FALSE
	call	LockMapBlockES
	mov	ax, es:MBH_pageInfo
	call	VMUnlockES
	and	ax, mask PLP_TYPE		; if not paper (envelope
	cmp	ax, PT_PAPER			; or label) then don't
	jnz	dontRecurse			; use recursion

	call	CheckIfFaxing			; if we are faxing
	jc	dontRecurse			; ...we can't recurse

	call	CheckForMerge			; See if we're merging
	cmp	ax, MT_NONE
	jnz	doRecurse

	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE
	call	CallPrintControl		; cx = first, dx = last
	pop	bp
	cmp	cx, dx
	jz	dontRecurse

	; we want to recurse -- set the print control appropriately

doRecurse:
	mov	recurseToPrint, BB_TRUE
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_ATTRS
	call	CallPrintControl		; cx = attrs
	pop	bp
	andnf	cx, not mask PCA_USES_DIALOG_BOX
	push	bp
	mov	ax, MSG_PRINT_CONTROL_SET_ATTRS
	call	CallPrintControl
	pop	bp
	push	bp
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	call	CallPrintControl
	pop	bp

dontRecurse:
endif
	;
	; Check if dirty document, if not then we'll revert when done to
	; avoid the side effect of marking the document dirty.
	;
	clr	wasDirty
	mov	ax, MSG_GEN_DOCUMENT_GET_ATTRS
	call	ObjCallInstanceNoLock
	test	ax, mask GDA_DIRTY
	jnz	dirtyDocument
	dec	wasDirty
dirtyDocument:

	call	CheckForMerge			; See if we're merging
haveMergeStatus::
	mov	merging, ax
	;
	; Do merge setup if it's required.
	;
	cmp	ax, MT_NONE			; Check for none
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
	LONG jc	endLoop				; Branch if no more to do

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

if	_SINGLE_PAGE_SPOOLING

	; check for using recursion to print

	tst	recurseToPrint
	jz	noPRecurse
	push	bp
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	mov	cx, pageNumber
	mov	dx, cx
	call	CallPrintControl
	pop	bp
	push	bp
	mov	ax, MSG_PRINT_CONTROL_PRINT
	call	CallPrintControl
	pop	bp
	call	DispatchEventsUntilPagePrinted
	LONG jc	userAbortedPrinting
	jmp	endPrintLoop
noPRecurse:
endif
	;
	; Tell the print control that we are printing this page
	;
	call	ReportPagePrintingProgress
	
	;
	; Check for the user cancelling the operation.
	;
	cmp	ax, FALSE
	LONG je	userAbortedPrinting		; Branch if user aborted

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
endPrintLoop::
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

if	_SINGLE_PAGE_SPOOLING

	; check for using recursion to print, if so then report cancelled,
	; so that this empty spool file is not printed

	tst	recurseToPrint
	jz	noSpecialEnd
	push	bp
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	mov	cx, firstPage			;reset the range to print
	mov	dx, lastPage
	call	CallPrintControl
	pop	bp
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_ATTRS
	call	CallPrintControl		; cx = attrs
	pop	bp
	ornf	cx, mask PCA_USES_DIALOG_BOX
	push	bp
	mov	ax, MSG_PRINT_CONTROL_SET_ATTRS
	call	CallPrintControl
	pop	bp
	jmp	afterQueue
noSpecialEnd:

endif

	;
	; ax	= Message to pass to print-control now that we're done.
	;
	; We used to need to attach the UI first...
	;
	call	QueueForFinishPrinting		; Queue print-control message
afterQueue::

	;
	; Cleanup after merging.
	;
	cmp	merging, MT_NONE		; Check for none
	je	afterMergeCleanup
	call	CleanupAfterMerge
afterMergeCleanup:
	;
	; If document was not dirty before merge, then we should revert.
	;
	tst	wasDirty
	jz	docWasDirty
	
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_REVERT_NO_PROMPT
	call	ObjCallInstanceNoLock
	pop	bp
docWasDirty:

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

	cmp	merging, MT_NONE		; Check for merging
	jz	userAbortedBetweenDocs
	call	RevertToOriginalDocument

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
if	_SINGLE_PAGE_SPOOLING
	mov	ax, MSG_WRITE_DOCUMENT_PRINTING_CANCELLED
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
endif

	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	jmp	quit				; And quit...

WriteDocumentContinuePrinting	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentNotifyPrintJobCreated --
		MSG_PRINT_NOTIFY_PRINT_JOB_CREATED for WriteDocumentClass

DESCRIPTION:	(_SINGLE_PAGE_SPOOLING only)
		wait for a created print job to complete

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	dx - print job ID (NOT CORRECT!)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/12/94		Initial version

------------------------------------------------------------------------------@
if	_SINGLE_PAGE_SPOOLING
include timer.def
WriteDocumentNotifyPrintJobCreated	method dynamic	WriteDocumentClass,
					MSG_PRINT_NOTIFY_PRINT_JOB_CREATED

waitLoop:
	mov	ax, 60 / 2
	call	TimerSleep
	mov	cx, SIT_QUEUE_INFO
	mov	dx, -1
	call	SpoolInfo
	cmp	ax, SPOOL_QUEUE_EMPTY
	jnz	waitLoop

	ret

WriteDocumentNotifyPrintJobCreated	endm
endif


COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGenDocumentOpen --
		MSG_VIS_OPEN for WriteDocumentClass

DESCRIPTION:	(_SINGLE_PAGE_SPOOLING only)	
		open a document

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass
	ax - The message
		
	cx, dx, bp -- see the message header

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Only works on one-print-job-at-a-time systems.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	5/26/94		Initial version

------------------------------------------------------------------------------@
if	_SINGLE_PAGE_SPOOLING
WriteDocumentGenDocumentOpen	method dynamic	WriteDocumentClass,
					MSG_VIS_OPEN

	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock

	; Add ourselves to a GCN list to receive spooler cancels that can't
	; otherwise be handled.

	mov	cx, ds:[LMBH_handle]
	mov	dx, si			; ^lcx:dx = WriteDocument
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PRINT_JOB_STATUS
	call	GCNListAdd
	ret

WriteDocumentGenDocumentOpen	endm
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGenDocumentClose --
		MSG_VIS_CLOSE for WriteDocumentClass

DESCRIPTION:	(_SINGLE_PAGE_SPOOLING only)	
		close a document

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass
	ax - The message
		
	cx, dx, bp -- see the message header

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Only works on one-print-job-at-a-time systems.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	5/26/94		Initial version

------------------------------------------------------------------------------@
if	_SINGLE_PAGE_SPOOLING
WriteDocumentGenDocumentClose	method dynamic	WriteDocumentClass,
					MSG_VIS_CLOSE

	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; ^lcx:dx = WriteDocument
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_PRINT_JOB_STATUS
	call	GCNListRemove
	ret

WriteDocumentGenDocumentClose	endm
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentPrintJobCancelled --
		MSG_PRINT_JOB_CANCELLED for WriteDocumentClass

DESCRIPTION:	(_SINGLE_PAGE_SPOOLING only)
		mark the print job as cancelledn

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass
	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Only works on one-print-job-at-a-time systems.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/12/94		Initial version

------------------------------------------------------------------------------@
if	_SINGLE_PAGE_SPOOLING
WriteDocumentPrintJobCancelled	method dynamic	WriteDocumentClass,
					MSG_PRINT_JOB_CANCELLED

	or	ds:[di].WDI_state, mask WDS_PRINT_JOB_ABORTED
	ret

WriteDocumentPrintJobCancelled	endm
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentPrintDialogInitialized --
		MSG_PRINT_DIALOG_INITIALIZED for WriteDocumentClass

DESCRIPTION:	(_SINGLE_PAGE_SPOOLING only)
		clear the job cancelled status

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass
	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Only works on one-print-job-at-a-time systems.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/12/94		Initial version

------------------------------------------------------------------------------@
if	_SINGLE_PAGE_SPOOLING
WriteDocumentPrintDialogInitialized	method dynamic	WriteDocumentClass,
					MSG_PRINT_DIALOG_INITIALIZED

	and	ds:[di].WDI_state, not mask WDS_PRINT_JOB_ABORTED
	ret

WriteDocumentPrintDialogInitialized	endm
endif



COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGetState --
		MSG_WRITE_DOCUMENT_GET_STATE for WriteDocumentClass

DESCRIPTION:	(_SINGLE_PAGE_SPOOLING only)
		mark the print job as cancelledn

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass
	ax - The message

RETURN:	ax - WriteDocumentState

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/12/94		Initial version

------------------------------------------------------------------------------@
if	_SINGLE_PAGE_SPOOLING
WriteDocumentGetState	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_GET_STATE

	mov	ax, ds:[di].WDI_state
	ret

WriteDocumentGetState	endm
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	DispatchEventsUntilPagePrinted

DESCRIPTION:	Dispatch events until the crucial START_PRINTING event
		goes through

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	carry - set if printing aborted

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/12/94		Initial version

------------------------------------------------------------------------------@
if	_SINGLE_PAGE_SPOOLING
DispatchEventsUntilPagePrinted	proc	near	uses si, di
	.enter	inherit WriteDocumentContinuePrinting
	push	ds:[LMBH_handle]

	clr	bx
	call	GeodeInfoQueue		;bx = queue for current thread

	; loop to dispatch events

dispatchLoop:

	; check to see if printing has been canceled in the interim;
	; if so, exit with carry set.  5/26/94 cbh

	push	bx, si
	movdw	bxsi, documentObj
	mov	ax, MSG_WRITE_DOCUMENT_GET_STATE

	; Don't fixup DS, because MessageProcess may cause it to move anyway!

	mov	di, mask MF_CALL
	call	ObjMessage
	test	ax, mask WDS_PRINT_JOB_ABORTED
	stc
	pop	bx, si
	jnz	exit

	push	bx, bp
	call	QueueGetMessage		;ax = message handle

	mov	di, bp			;ss:di = inherited variables
	mov_tr	bx, ax			;bx = message
	clr	si			;don't preserve the event
FXIP <	mov	ax, SEGMENT_CS						>
FXIP <	push	ax							>
NOFXIP<	push	cs							>
	mov	ax, offset DispatchIt
	push	ax
	call	MessageProcess
	pop	bx, bp
	jnz	dispatchLoop

exit:
	pop	bx
	pushf
	call	MemDerefDS
	popf
	.leave
	ret

DispatchEventsUntilPagePrinted	endp

;---


	; passed ObjMessage data, carry set if stack data
	; return Z flag set if START_PRINTING, indicating
	; that we should go print the next page.

DispatchIt	proc	far
	.enter	inherit WriteDocumentContinuePrinting

	push	ax, bx, cx, si, bp
	mov	bp, di			;ss:bp = inherited variables

	mov	di, 0
	jnc	noStack
	mov	di, mask MF_STACK
noStack:
	cmp	ax, MSG_META_SEND_CLASSED_EVENT
	jnz	notSendClassed
	mov	bx, cx
	call	ObjGetMessageInfo	;ax = message, cx:si = dest
	cmp	ax, MSG_PRINT_NOTIFY_PRINT_JOB_CREATED
	jnz	sendMessageWithZFlag
	cmp	si, offset WriteDocumentClass
	jnz	sendMessageWithZFlag
	cmp	cx, segment WriteDocumentClass
	clc				;clear abort flag
	jmp	sendMessageWithZFlag

notSendClassed:
	cmp	ax, MSG_WRITE_DOCUMENT_PRINTING_CANCELLED
	jnz	sendMessageWithZFlag
	cmpdw	bxsi, documentObj
	stc				;set abort flag

sendMessageWithZFlag:
	pop	ax, bx, cx, si, bp
	pushf				;Z flag set if START_PRINTING
	call	ObjMessage
	popf

	.leave
	ret
DispatchIt	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportPagePrintingProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Report progress in printing.

CALLED BY:	WriteDocumentContinuePrinting
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
	.enter	inherit WriteDocumentContinuePrinting

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

CALLED BY:	WriteDocumentContinuePrinting
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
	.enter	inherit WriteDocumentContinuePrinting
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
	
	call	UtilHex32ToAscii		; Write the number and NULL

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

CALLED BY:	WriteDocumentContinuePrinting
PASS:		*ds:si	= WriteDocument instance
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
	.enter	inherit WriteDocumentContinuePrinting

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

CALLED BY:	WriteDocumentStartPrinting
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
	.enter	inherit	WriteDocumentContinuePrinting
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
	;
	; Get the page range to print (the range that the user set)
	;
	push	bp
	mov	ax, MSG_PRINT_CONTROL_GET_SELECTED_PAGE_RANGE
	call	CallPrintControl		; cx = first, dx = last
	pop	bp
	mov	firstPage, cx
	mov	lastPage, dx

	;
	; Get the starting page number
	;
	clr	ax
	call	SectionArrayEToP_ES
	mov	cx, es:[di].SAE_startingPageNum
	mov	firstDocPage, cx

if _ENABLE_CALC_MARGINS_KEY
	push	ds, si, cx, dx
	segmov	ds, cs, cx
	mov	si, offset calcMarginsCat	;ds:si = category: [configure]
	mov	dx, offset calcMarginsKey	;cx:dx = key: ndOptions
	clr	ax				;ax <- assume no key
	call	InitFileReadInteger
	pop	ds, si, cx, dx
	test	ax, mask NDF_CALC_WRITE_MARGINS
	jz	useMinimumMargins		;branch if FALSE
endif

	;
	; Get the document's margins (we use the minimum of all sections
	; that are being printed)
	;
	call	CalcMinimumMargins		; pageMargins filled

	;
	; If there is a non-empty header or footer then use the minimum
	; margin values all the way around
	;
	call	DoesHeaderFooterContainText
	jnc	afterHeaderFooter

	;
	; 1/28/97: Just use the minimum margins.  ForcesSee ND-000224.
	;
useMinimumMargins::
if _DWP
	;
	; Deal with the realities of different printer margins.
	;
	mov	pageMargins.R_left, MINIMUM_LEFT_MARGIN_SIZE/8
	mov	pageMargins.R_top, MINIMUM_TOP_MARGIN_SIZE/8
	mov	pageMargins.R_right, MINIMUM_RIGHT_MARGIN_SIZE/8
	mov	pageMargins.R_bottom, MINIMUM_BOTTOM_MARGIN_SIZE/8
else
	mov	ax, PIXELS_PER_INCH / 4
	mov	pageMargins.R_left, ax
	mov	pageMargins.R_top, ax
	mov	pageMargins.R_right, ax
	mov	pageMargins.R_bottom, ax
endif

afterHeaderFooter:
	;
	; Set the actual margins
	;
	push	bp, si
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_MARGINS
	movdw	bxsi, printControl
	mov	dx, ss
	lea	bp, pageMargins
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp, si

	;
	; Get the page size from the document and store it in a local
	; variable
	;
	mov	ax, es:MBH_pageSize.XYS_width
	mov	bx, es:MBH_pageSize.XYS_height
	call	VMUnlockES
	mov	pageSize.XYS_width, ax
	mov	pageSize.XYS_height, bx
	
	pop	ax				; ax <- old display mode
	.leave
	ret
SetDisplayModeMarginsSizeAndPages	endp

if _ENABLE_CALC_MARGINS_KEY
calcMarginsCat	char	"configure", 0
calcMarginsKey	char	"ndOptions", 0
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoesHeaderFooterContainText

DESCRIPTION:	Determine if any header or footer contains text

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block (locked)
	cx    - starting page number for this section

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
	uses	ax, bx, cx, di, si, ds
	.enter	inherit WriteDocumentContinuePrinting

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

CALLED BY:	WriteDocumentReportPageSize (via ChunkArrayEnum)

PASS:
	ds:di - SectionArrayElement
	ss:bp - inherited stack frame
	cx    - starting page number for this section

RETURN:
	cx    - starting page number for next section
	carry - set if header of footer contains text

DESTROYED:
	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
ContainsTextCallback	proc	far
	.enter	inherit WriteDocumentContinuePrinting

	; don't include sections that are not being printed

	call	SectionInPageRange
	push	cx
	jc	skip

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
skip:
	clc
done:
	pop	cx

	.leave
	ret

;---

	; return carry set if object contains text

containsText:
	tst_clc	bx
	jz	containsDone
	call	VMBlockToMemBlockRefDS
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;cxdx = ward
	movdw	bxsi, cxdx

	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;dxax = size
	tstdw	dxax
	stc
	jnz	containsDone
	clc
containsDone:
	retn

ContainsTextCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcMinimumMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the minimum margins required to print all
		of the selected pages in this document

CALLED BY:	SetDisplayModeMarginsSizeAndPages

PASS:		*ds:si	= document object
		ss:bp	= inherited stack frame
			  (firstPage & lastPage must be valid)

RETURN:		pageMargins initialized

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcMinimumMargins	proc	near
	uses	ax, bx, cx, dx, di, si, ds
	.enter	inherit WriteDocumentContinuePrinting
	
	; enumerate all sections

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset CalcMinimumMarginsCallback
	clr	ax				; initialize margins to
	dec	ax				; ...very large values
	mov	ss:[pageMargins].R_left, ax
	mov	ss:[pageMargins].R_top, ax
	mov	ss:[pageMargins].R_right, ax
	mov	ss:[pageMargins].R_bottom, ax
	call	ChunkArrayEnum

	; turn values into points, and store in stack frame

	mov	si, offset R_left
	call	convertToPoints
	mov	si, offset R_top
	call	convertToPoints
	mov	si, offset R_right
	call	convertToPoints
	mov	si, offset R_bottom
	call	convertToPoints

	.leave
	ret

convertToPoints:
	mov	ax, {word} ss:[pageMargins][si]
	shr	ax, 1
	shr	ax, 1
	inc	ax
	shr	ax, 1
	mov	{word} ss:[pageMargins][si], ax
	retn
CalcMinimumMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcMinimumMarginsCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to determine if this section contains smaller
		margins than what has been seen so far.

CALLED BY:	CalcMinimumMargins(), via ChunkArrayEnum

PASS:		ds:di	- SectionArrayElement
		cx	- starting page number for section
		ss:bp	- inherited stack frame
				firstPage
				lastPage
				pageMargins w/ smallest margins seen so far

RETURN:		carry	- clear (continue enumeration)
		cx	- starting page number for next section
		ss:bp	- inherited stack frame
				pageMargins w/ updated margins

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcMinimumMarginsCallback	proc	far
	.enter	inherit WriteDocumentContinuePrinting
	
	; don't include sections that are not being printed

	call	SectionInPageRange
	jc	done

	; compare our margins against what we've seen already

	mov	ax, ss:[pageMargins].R_left
	cmp	ax, ds:[di].SAE_leftMargin
	jbe	checkTop
	mov	ax, ds:[di].SAE_leftMargin
	mov	ss:[pageMargins].R_left, ax
checkTop:
	mov	ax, ss:[pageMargins].R_top
	cmp	ax, ds:[di].SAE_topMargin
	jbe	checkRight
	mov	ax, ds:[di].SAE_topMargin
	mov	ss:[pageMargins].R_top, ax
checkRight:
	mov	ax, ss:[pageMargins].R_right
	cmp	ax, ds:[di].SAE_rightMargin
	jbe	checkBottom
	mov	ax, ds:[di].SAE_rightMargin
	mov	ss:[pageMargins].R_right, ax
checkBottom:
	mov	ax, ss:[pageMargins].R_bottom
	cmp	ax, ds:[di].SAE_bottomMargin
	jbe	done
	mov	ax, ds:[di].SAE_bottomMargin
	mov	ss:[pageMargins].R_bottom, ax
done:
	clc

	.leave
	ret
CalcMinimumMarginsCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SectionInPageRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if any pages in this section fall within the
		passed page range

CALLED BY:	UTILITY

PASS:		ds:di	- SectionArrayElement
		cx	- starting page number for section
		ss:bp	- inherited stack frame
				firstPage
				lastPage

RETURN:		carry	- clear (continue enumeration)
		cx	- starting page number for next section

DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/29/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SectionInPageRange	proc	near
	.enter	inherit WriteDocumentContinuePrinting
	
	mov	dx, cx				; first page of section -> dx
	add	cx, ds:[di].SAE_numPages	; starting page for next section
	cmp	dx, ss:[lastPage]
	ja	notInRange
	mov	dx, cx
	dec	dx				; last page of section -> dx
	cmp	dx, ss:[firstPage]
	jb	notInRange
	clc					; this section is in range
	jmp	exit
notInRange:
	stc
exit:	
	.leave
	ret
SectionInPageRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallPrintControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the Print-Control object.

CALLED BY:	WriteDocumentStartPrinting
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
	.enter	inherit	WriteDocumentContinuePrinting
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
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
		SetDisplayMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the display mode for the document

CALLED BY:	WriteDocumentStartPrinting
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
	mov	ax, MSG_WRITE_DOCUMENT_SET_DISPLAY_MODE_LOW
	call	ObjCallInstanceNoLock
	pop	bp
	ret
SetDisplayMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfFaxing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we are faxing

CALLED BY:	WriteDocumentStartPrinting
PASS:		*ds:si	= Instance ptr
		ss:bp	= Inheritable stack frame
RETURN:		carry	= set if faxing, clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We take advantage of the fact that we set the
		InnerPrintGroup not usable when we are faxing, as
		one cannot perform a fax-merge.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	5/2/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_SINGLE_PAGE_SPOOLING
CheckIfFaxing	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter	inherit	WriteDocumentContinuePrinting

	;
	; Get the merge-selection from the list
	;
	mov	ax, MSG_GEN_GET_USABLE
	GetResourceHandleNS	InnerPrintGroup, bx
	mov	si, offset InnerPrintGroup
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; carry set if usable
	cmc					; want carry set if not usable

	.leave
	ret
CheckIfFaxing	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForMerge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we are merging.

CALLED BY:	WriteDocumentStartPrinting
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
	.enter	inherit	WriteDocumentContinuePrinting

	;
	; Get the merge-selection from the list
	;
	push	bp				; Save frame ptr

	GetResourceHandleNS	MergeList, bx
	mov	si, offset MergeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
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

CALLED BY:	WriteDocumentStartPrinting
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
	.enter	inherit	WriteDocumentContinuePrinting

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

CALLED BY:	WriteDocumentStartPrinting
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
	.enter	inherit	WriteDocumentContinuePrinting
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
	.enter	inherit	WriteDocumentContinuePrinting
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
