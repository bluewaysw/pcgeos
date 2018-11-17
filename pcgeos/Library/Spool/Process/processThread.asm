COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processThread.asm
AUTHOR:		Jim DeFrisco, 9 March 1990

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/13/90		Initial revision


DESCRIPTION:
	This file contains the code to build out the image for the printer
	driver

	$Id: processThread.asm,v 1.1 97/04/07 11:11:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintThread	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetJobInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy job info out of PrintQueue and into local vars

CALLED BY:	INTERNAL
		SpoolerLoop

PASS:		inherits SpoolerLoop local vars

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		QI_threadInfo is set to point at curJob before queue is
		released.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetJobInfo	proc	far
		uses	ds, es, di, si, ax, bx, cx
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; lock the PrintQueue in order to get at the job info

		call	LockQueue		; lock it down
		mov	ds, ax			; ds -> queue

		; get pointer to the info we need

		mov	si, curJob.SJI_qHan	; get chunk handle of queue
EC <		tst	si			; ensure it non-NULL	>
EC <		ERROR_Z	SPOOL_INVALID_QUEUE_INFO_CHUNK			>
		mov	si, ds:[si]		; deref chunk handle

		lea	ax, ss:[curJob]
		movdw	ds:[si].QI_threadInfo, ssax

		mov	si, ds:[si].QI_curJob	; get next job on list
EC <		tst	si			; ensure it non-NULL	>
EC <		ERROR_Z	SPOOL_INVALID_CUR_JOB_CHUNK			>
		mov	si, ds:[si]		; dereference the job chunk
		add	si, JIS_info		; get pointer to info
		push	si

		; copy all of the JobParameters onto the end of the PState
		; the reallocation shouldn't generally do anything, as we've
		; already allocated enough room for a standard JobParameters
		; - but a printer driver could make the structure larger

		mov	ax, ds:[si].JP_size	; ax -> total size of params
		add	ax, (size PState)
		mov	bx, curJob.SJI_pstate
		mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
		call	MemReAlloc
		mov	es, ax
		mov	di, offset PS_jobParams
		mov	cx, ds:[si].JP_size	; cx -> total size of params
		rep	movsb
		call	MemUnlock		; unlock the PState

		; copy the JobParameters into the SpoolJobInfo. We can
		; only copy the standard size, as the destination for
		; this data is a stack-based local variable, and hence
		; must be of a pre-determined size. Printer drivers wanting
		; to use an extended JobParameters will need to directly
		; access the JobParameters structure that is appended to
		; the end of the PState.
		;
		pop	si			; ds:si -> JobParameters
		segmov	es, ss, di		; es -> stack
		lea	di, curJob.SJI_info	; es:di-> local var block
		mov	cx, size JobParameters	; size of copy
		rep	movsb			; copy info over

		; all done copying, release the block

		call	UnlockQueue		; all done with queue

		.leave
		ret
GetJobInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the file, build out the image, or whatever is required
		and call the print driver

CALLED BY:	INTERNAL
		SpoolerLoop

PASS:		inherits local vars from SpoolerLoop

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Open the file
		Draw the file
		Close/Delete the file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintFile	proc	near
		uses	ax,bx,cx,dx,si,di,es,ds
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; now we have a spool file name.  Open the file and save 
		; the handle.  If there is no file, assume queue is empty

		cmp	curJob.SJI_info.JP_fname, 0 ; name start w/NULL ?
		jz	shortExit		; finished w/queue, exit

		; set the path to the spool directoy

		mov	ax, SP_SPOOL
		call	FileSetStandardPath

		; open the spool file

		segmov	ds, ss, dx
		lea	dx, curJob.SJI_info.JP_fname	; ds:dx -> filename
		mov	al, FILE_DENY_NONE or FILE_ACCESS_RW
		call	FileOpen
		jnc	fileOK			; some error
		mov	cx, SERROR_NO_SPOOL_FILE
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox		; put up an error
		call	StoppedByError		; record our exit
shortExit:
		jmp	exit			; and leave quickly

		; opened OK, store away valuable info
fileOK:
		mov	curJob.SJI_fHan, ax	; save away file handle
		mov	{word} curJob.SJI_fPos, 0 ; zero out current pos
		mov	{word} curJob.SJI_fPos+2, 0 

if _PRINTING_DIALOG
		; Put up modal dialog while printing, but only in the
		; CUI and only if we're not faxing, and only if we've
		; not already displayed it once (in which case the user
		; hit "Close" and started another job, and we certainly
		; do not want to bother him/her again).

                push    ax, cx, dx, bp, di

		; this was a remnant from a Brother or Canon project, so I'm
		; removing it because it could confuse our users. -Don 5/14/00
;;;		call    ClipboardFreeItemsNotInUse

		clr	bx			; assume no dialog box
		tst     curJob.SJI_prDialogAlready
		jnz	doneUpDialog

		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY	; if we are not in the CUI
		jne	doneUpDialog		; ...don't display DB

		call	GetPrintDBChoiceSetting
		cmp	ax, TRUE		; if not TRUE
		jne	doneUpDialog		; ...don't display DB

		lea	si, curJob.SJI_info.JP_printerName
		call	ReadPrinterDriverType
		cmp	al, PDT_FACSIMILE	; if we are faxing
		je	doneUpDialog		; ...don't display DB

		mov     bx, handle PrintingDialogBox
		mov     si, offset PrintingDialogBox
		call    UserCreateDialog
		dec     curJob.SJI_prDialogAlready	; mark TRUE

		mov     ax, MSG_GEN_INTERACTION_INITIATE
		mov     di, mask MF_CALL
		call    ObjMessage
doneUpDialog:
		pop     ax, cx, dx, bp, di
		mov     curJob.SJI_prDialogHan, bx
endif	; if _PRINTING_DIALOG

		; and initialize the printer driver
		; open and initialize the proper port to print to..
		; we only need to load these once per queue, so check first
		clr	curJob.SJI_printState	; start clean so we can or it
		call	InitPrinterPort		; get it ready
		jc	portError		; some port error...

		; do the right thing for tiramisu printing (fax printing)

		call	StartTiramisuPrintingIfNeeded		

		call	InitPrinterDriver	; do some initial calcs
		jc	exitDriver		; some problem, just quit

		call	CalcDocOrientation	; figure out if we have to 
						;  tile/rotate the output
		call	AdjustTileForTractor	; adjust for tractor fed paper
		call	AdjustForSupressFF	; adjust page height if no FF

		; compute the number of physical pages, for SpoolInfo
		
		call	SetNumPhysicalPages
		
		; print the darn thing already

		call	PrintDocument		; print out whole document

		; do the right thing for tiramisu printing (fax printing)
		; ...and then clean up the printer driver
exitDriver:
		call	EndTiramisuPrintingIfNeeded
		call	ExitPrinterDriver

		; close the port down.
closePort:
		call	ClosePrinterPort

done:
if _PRINTING_DIALOG
		; bring down the print dialog box we had earlier displayed

		tst	bx
		jz	doneDownDialog
		call	SetPrintDBChoiceSetting
                call    UserDestroyDialog       ; ^lbx:si = printing dialog box
		clr	curJob.SJI_prDialogHan	; clear handle for dialog box
doneDownDialog:	
endif
		; close the spool file opened earlier
		
		mov	al, FILE_NO_ERRORS	; set up to close file
		mov	bx, curJob.SJI_fHan	; file handle => BX
		call	FileClose		; else close the file
exit:
		.leave
		ret

		; some problem with port driver.  handle it.
		; if it was a problem with the port, then don't try to
		; close the port...
portError:
		call	StoppedByError
		cmp	ax, PE_PORT_NOT_OPENED	; if port not opened...
		jne	closePort		;  don't try to close it..
		jmp	done
PrintFile	endp

if _PRINTING_DIALOG
spoolPrintDBChoiceCat	char	"spool", 0
spoolPrintDBChoiceKey	char	"showPrintingDialog", 0

GetPrintDBChoiceSetting	proc	near
		uses	cx, dx, si, ds
		.enter
	;
	; Just query the .INI file. Default value is to show the dialog box
	;
		mov	ax, TRUE		; default to TRUE
		segmov	ds, cs, cx
		mov	si, offset spoolPrintDBChoiceCat
		mov	dx, offset spoolPrintDBChoiceKey
		call	InitFileReadBoolean		

		.leave
		ret
GetPrintDBChoiceSetting	endp

SetPrintDBChoiceSetting	proc	near
		uses	ax, cx, dx, bp, di, si, ds
		.enter
	;
	; Grab the setting from the dialog box
	;
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		mov	si, offset PDChoice
		mov	di, mask MF_CALL
		call	ObjMessage		; 0 /1 -> AX (1 = checked)
		tst	ax			; if not checked
		jz	done			; ...don't do anything
	;
	; The checkbox was checked, so we do't want to display the
	; dialog box any more. So, write FALSE to the .INI file
	;
		segmov	ds, cs, cx
		mov	si, offset spoolPrintDBChoiceCat
		mov	dx, offset spoolPrintDBChoiceKey
		mov	ax, FALSE
		call	InitFileWriteBoolean		
		call	InitFileCommit
done:		
		.leave
		ret
SetPrintDBChoiceSetting	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoppedByError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that we stopped because of an error, so proper
		notification gets sent to the GCN list

CALLED BY:	(INTERNAL)
PASS:		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	QI_error is set to SI_ERROR

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoppedByError	proc	near
curJob		local	SpoolJobInfo
		uses	ds, ax, bx
		.enter	inherit
		pushf
		call	LockQueue
		mov	ds, ax
		mov	bx, curJob.SJI_qHan
		mov	bx, ds:[bx]
		mov	ds:[bx].QI_error, SI_ERROR
		call	UnlockQueue
		popf
		.leave
		ret
StoppedByError	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNumPhysicalPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the number of physical pages that constitute this
		entire print job and store it in the queue for SpoolInfo
		to get.

CALLED BY:	(INTERNAL) PrintFile
PASS:		ss:bp	= inherited variables
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	QI_numPhysPgs set for the thread's queue

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNumPhysicalPages proc	near
		uses	ax, bx, dx, ds
curJob		local	SpoolJobInfo
		.enter	inherit
	;
	; The number of physical pages is the number of physical pages per
	; document page (xPages * yPages) times the number of copies per
	; document page (numCopies) times the number of pages in the document
	; (we're trusting JP_numPages). We don't check for overflow, because
	; we're realistic in our assumption of what this system might print
	; in the reasonable future, and 65,000 page documents don't enter into
	; the picture -- ardeb
	; 
		mov	ax, curJob.SJI_xPages
		mul	curJob.SJI_yPages		; dxax <- # phys/copy
		mul	curJob.SJI_info.JP_numCopies	; dxax <- # phys/doc
		mul	curJob.SJI_info.JP_numPages	; dxax <- # phys/file
		
		mov_tr	dx, ax				; preserve that

		call	LockQueue
		mov	ds, ax
		
		mov	bx, curJob.SJI_qHan
		mov	bx, ds:[bx]
		mov	ds:[bx].QI_numPhysPgs, dx
		
		call	UnlockQueue
		
		.leave
		ret
SetNumPhysicalPages endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do all the non-graphics/text related stuff and call the
		specific modules to do either text/graphics printing

CALLED BY:	PrintFile

PASS:		gets everything in stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		handle copies, collation, etc. etc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintDocument	proc	near
		uses	ax, bx, si
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; we need to do some mode-dependent initialization first.

if	_PDL_PRINTING
		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jnz	checkTextInit			; never PDL if tiramisu

		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS		; is it PostScript ?
		cmp	al, PS_PDL
		jne	checkTextInit			;  no check text mode
		call	DoPDLInit
		jmp	checkForErrors
checkTextInit:
endif	;_PDL_PRINTING

		cmp	curJob.SJI_info.JP_printMode, PM_FIRST_TEXT_MODE
		jae	textInit
		call	DoGraphicsInit
		jmp	checkForErrors			; start the printing
textInit:

if	_TEXT_PRINTING
		call	DoTextInit
else
		clr	ax				;crap out gracefully
		jmp	exit
endif	;_TEXT_PRINTING

	; see if the init process failed.  If it did, just abort 
	; this print job.
checkForErrors:
		tst	ax				; ax != 0 means error
		LONG jnz exit

	;
	; Also, call CheckForErrors, to see if user has aborted the
	; print job
	;
		
		call	CheckForErrors
		LONG jc	doneDoc
		
		; now just loop for each page
pageLoop:
		;init the number of times to print out this page. The print
		;driver may have been able to set the number of copies in its
		;PrintStartJob routine. if it has, then the JobParameters at
		;the end of the PState is loaded with 1, so that we only have
		;to print each page once.
		push	ds
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		mov	al,ds:[PS_jobParams].JP_numCopies
		mov	curJob.SJI_numCopies, al	; for uncollated cops
		call	MemUnlock			; (preserves flags)
		pop	ds

		; before we jump in, check to see if it is single-sheet fed
		; (manual) and tell the user to put in another piece
anotherPage:

if not _NONSPOOL
		push	ds
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		test	ds:[PS_paperInput], mask PIO_MANUAL
		call	MemUnlock			; (preserves flags)
		pop	ds
		jz	havePaper			;  no, auto-fed paper

		; we have a manual feed situation.  Ask the user to stick
		; another piece (but nicely)

		mov	cx, SERROR_MANUAL_PAPER_FEED	; ask for next piece
		clr	dx
		call	SpoolErrorBox			; he can only answer OK
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK			; if affirmative
		je	havePaper			; continue, else kill
		mov	ax, GSRT_FAULT			;   so kill job
		jmp	checkEndDoc
havePaper:
endif	; if (not _NONSPOOL)

		; OK, we have something to print on.  So print already!
		; Do it different for text/graphics modes

if	_PDL_PRINTING
		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jnz	checkForNextMode		; never PDL if tiramisu

		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS
		cmp	al, PS_PDL shl offset SPS_SMARTS
		jne	checkForNextMode
		call	PrintPDLPage
		jmp	checkNextPage
checkForNextMode:
endif	;_PDL_PRINTING


if	_TEXT_PRINTING
		cmp	curJob.SJI_info.JP_printMode, PM_FIRST_TEXT_MODE
		jae	textPrint
		call	PrintGraphicsPage
		jmp	checkNextPage			; on to the next one
textPrint:
		call	PrintTextPage
else
                call    PrintGraphicsPage
endif		;_TEXT_PRINTING

		; see if we are printing un-collated copies.  If so, then
		; handle that here. Before we go for the next page, see if
		; we're exiting.
checkNextPage::
		push	ax				; save exit code
		call	CheckForErrors			; check for aborts..
		pop	ax				; restore exit code
		jc	doneDoc				; if abort flag set..
if	_LABELS
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jnz	checkEndDoc
endif
		test	curJob.SJI_info.JP_spoolOpts, mask SO_COLLATE
		jnz	checkEndDoc			;  no copies
		dec	curJob.SJI_numCopies		; one less copy to do
		jg	printAnotherPageShort

		; done printing this page, including any uncollated copies
checkEndDoc:
		cmp	ax, GSRT_COMPLETE		; done with everything?
		je	checkCollated			; check to see if more
							;  copies to print
		cmp	ax, GSRT_FAULT			; some problem ?
		je	noteError			;  yes, done printing

		; find the file position of the next page. Do this by getting
		; the current file position, knowing that the file is already
		; positioned past the previous GrNewPage

		mov	al, FILE_POS_RELATIVE
		mov	bx, curJob.SJI_fHan		; fetch file handle
		clr	cx, dx				; skip over GR_NEW_PAGE
		call	FilePos				; dx:ax <- start of page
		movdw	curJob.SJI_fPos, dxax		; set new position

		; bump curPage variable in the PrintQueue
		; follow through with remainder of document, unless we
		; are printing labels, in which case we handle multiple
		; pages in PrintGraphicsLables

		call	BumpPageNumber			; doing next page...
if	_LABELS
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jnz	anotherPageShort
endif
		jmp	pageLoop

		; done with one set of pages, check to see if we need to do
		; another set
checkCollated:
if	_LABELS
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jnz	doneDoc
endif
		test	curJob.SJI_info.JP_spoolOpts, mask SO_COLLATE
		jz	doneDoc				;  nope, quit
		dec	curJob.SJI_info.JP_numCopies 	; one less to do
		jle	doneDoc				;  done with all copies

		; doing another copy.  Reset the file position back to the 
		; beginning of the file and go at it.

		mov	{word} curJob.SJI_fPos, 0	; reset to zero
		mov	{word} curJob.SJI_fPos+2, 0	; reset to zero
printAnotherPageShort:
		jmp	printAnotherPage

noteError:
		call	StoppedByError

		; done printing, do some cleanup
doneDoc:

if	_PDL_PRINTING
		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jnz	checkForNextCleanup		; never PDL if tiramisu

		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS
		cmp	al, PS_PDL
		jne	checkForNextCleanup
		call	DoPDLCleanup
		jmp	exit
checkForNextCleanup:
endif	;_PDL_PRINTING

if	_TEXT_PRINTING
		cmp	curJob.SJI_info.JP_printMode, PM_FIRST_TEXT_MODE
		jae	textCleanup
		call	DoGraphicsCleanup
		jmp	exit				; all done
textCleanup:
		call	DoTextCleanup
else
                call    DoGraphicsCleanup
endif	;_TEXT_PRINTING
exit:
		.leave	
		ret

		; we're printing uncollated copies, and we have more to do,
		; so reposition the file and start again.
printAnotherPage:
		mov	al, FILE_POS_START
		mov	bx, curJob.SJI_fHan		; fetch file handle
		mov	dx, {word} curJob.SJI_fPos	;  and postion
		mov	cx, {word} curJob.SJI_fPos+2
		call	FilePos				; set to start o page
anotherPageShort::
		jmp	anotherPage
PrintDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WillDocumentFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An external routine that is called from the PrintControl to
		determine if the document will fit on the selected paper.

CALLED BY:	EXTERNAL
		PrintControl
PASS:		ds:si	- pointer to PageSizeReport structure for document
		ds:di	- pointer to PageSizeReport structure for paper
RETURN:		ax	- zero (FALSE) if document will not fit
			  -1   (TRUE)  if document will fit without rotation
			   1           if document will fit with rotation
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Check document fit (accounting for margins) both upright 
		and if rotated.

		If we're printing to labels, we always return TRUE.  If the
		doc doesn't fit on the label, it will always be scaled to fit.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WillDocumentFit		proc	far
		uses	bx, cx
docX		local	dword
docY		local	dword
pageX		local	dword
pageY		local	dword
		.enter

if	_LABELS
		; if we're printing labels, return TRUE
 
 		test	ds:[di].PSR_layout, PT_LABEL
 		LONG_EC	jnz	returnTrue
endif

		; first calculate the printable areas of the document and the
		; page, and store the results
		; compare it to the printable width of the paper.  This is
		; the entire width less the margins, of course.

		movdw	bxax, ds:[si].PSR_width		; get doc width
		mov	cx, ds:[si].PSR_margins.PCMP_left
		add	cx, ds:[si].PSR_margins.PCMP_right ; cx = margin size
		sub	ax, cx
		sbb	bx, 0				; bxax = printable size
EC <		tst	bx				; if neg, something is>
EC <		ERROR_S SPOOL_BAD_DOCUMENT_SIZE				      >
		movdw	ss:docX, bxax
		movdw	bxax, ds:[si].PSR_height	; get doc height
		mov	cx, ds:[si].PSR_margins.PCMP_top
		add	cx, ds:[si].PSR_margins.PCMP_bottom ; cx = margin size
		sub	ax, cx
		sbb	bx, 0				; bxax = printable size
EC <		tst	bx				; if neg, something is>
EC <		ERROR_S SPOOL_BAD_DOCUMENT_SIZE				      >
		movdw	ss:docY, bxax

		; same calculation for paper.

		movdw	bxax, ds:[di].PSR_width
		mov	cx, ds:[di].PSR_margins.PCMP_left
		add	cx, ds:[di].PSR_margins.PCMP_right
		sbb	ax, cx
		sbb	bx, 0
EC <		tst	bx				; if neg, something is>
EC <		ERROR_S SPOOL_BAD_DOCUMENT_SIZE				      >
		movdw	ss:pageX, bxax
		movdw	bxax, ds:[di].PSR_height	; get doc height
		mov	cx, ds:[di].PSR_margins.PCMP_top
		add	cx, ds:[di].PSR_margins.PCMP_bottom ; cx = margin size
		sub	ax, cx
		sbb	bx, 0				; bxax = printable size
EC <		tst	bx				; if neg, something is>
EC <		ERROR_S SPOOL_BAD_DOCUMENT_SIZE				      >
		movdw	ss:pageY, bxax

		cmpdw	ss:docY, bxax			; if larger, problem
		ja	checkRotation
		cmpdw	ss:docX, ss:pageX, ax
		ja	checkRotation

		; we pass with flying colors, set TRUE return value and exit
returnTrue::
		mov	ax, TRUE
done:
		.leave
		ret

		; the document does not fit if printed upright.  Check rotated.
checkRotation:
		cmpdw	ss:docX, ss:pageY, ax
		ja	doesntFit
		cmpdw	ss:docY, ss:pageX, ax
		ja	doesntFit
		mov	ax, 1				; signal OK w/rotation
		jmp	done
doesntFit:
		mov	ax, FALSE			; doc doesn't fit
		jmp	done
WillDocumentFit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDocOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take a look at the document size and the paper size, and
		figure out how to best fit the document to the paper.

CALLED BY:	INTERNAL
		PrintFile

PASS:		inherits big stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		figure printable width and height;
		determine if we need to rotate the document (if it will fit
		  better rotated);
		if (rotated)
		    apply rotation transformation
		if (doc width < paper width)
		    apply centering translation
		else
		    apply left margin
		    do tiling calculation in x
		if (doc height < paper height)
		    apply centering translation
		else
		    apply top margin
		    do tiling calculation in y

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcDocOrientation proc	near
		uses	ds, es, bx, si, di
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; first init the tile variables and default window transform

		clr	bx				; we'll accumulate bits
							;  here to determine
							;  which routine to 
							;  call to set the 
							;  default TransMatrix
		mov	curJob.SJI_xPages, 1		; init tiling vars
		mov	curJob.SJI_yPages, 1
		clr	di				; current no GState
		call	GrCreateState			; GState => DI

if	_PDL_PRINTING
		; PDL printers have a slightly different outlook

		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS
		cmp	al, PS_PDL
		jne	checkFit
		or	bx, mask OB_PDL
checkFit:
endif	;_PDL_PRINTING
		
		; check to see if the document will fit, upright or rotated.
		; If it won't, then we have to either scale to fit (this
		; desire is indicated in JobParameters) or we tile.
		push	di				; save GState handle
		segmov	ds, ss, si
		lea	si, curJob.SJI_info.JP_docSizeInfo
		lea	di, curJob.SJI_info.JP_paperSizeInfo
		call	WillDocumentFit
		pop	di
		cmp	ax, FALSE			; if not, check tile...
		je	docTooBig

if	_LABELS
		; WillDocumentFit always returns TRUE for label printing, so
		; that the nasty scale box will not come up (this enables 
		; thumbnails to work great).  So check for labels here, and
		; make like we *always* have to scale.  Then all the cases
		; work.  (If we are really printing labels, the scale factor
		; will be 1.0).  Also for labels we have to fixup the 
		; SJI_printWidth and SJI_printHeight fields, which were
		; set to the whole page in InitPrinterDriver (needed there
		; to size the paper bitmap to draw to).  Yes, this is kind 
		; of a hack.
		
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jz	checkForceRotate
		mov	ax, curJob.SJI_info.JP_paperSizeInfo.PSR_width.low
		mov	curJob.SJI_printWidth, ax
		mov	ax, curJob.SJI_info.JP_paperSizeInfo.PSR_height.low
		mov	curJob.SJI_printHeight, ax
		movdw	curJob.SJI_docWidth, \
			curJob.SJI_info.JP_docSizeInfo.PSR_width, ax
		movdw	curJob.SJI_docHeight, \
			curJob.SJI_info.JP_docSizeInfo.PSR_height, ax
		jmp	docTooBig
endif

		; OK, we know the document will fit, now check if rotation was
		; desired (or needed)
checkForceRotate::
		test	curJob.SJI_info.JP_spoolOpts, mask SO_FORCE_ROT
		jnz	setRotated
		cmp	ax, TRUE			; see if OK w/o rotate
		je	setTransform			;  no, set rotated bit

		; Make sure we are not in text mode. If we are in text
		; mode, we need to just tile without rotating.

		cmp	curJob.SJI_info.JP_printMode,PM_FIRST_TEXT_MODE
		jge	tileIt
setRotated:
		or	bx, mask OB_ROTATE

		; we have all the bits accumulated in bx,. call the appropriate
		; matrix altering routine.
setTransform:
		mov	ss:[curJob].SJI_gstate, di
		call	cs:orientDoc[bx]
done:
		segmov	ds, ss, si
		lea	si, curJob.SJI_defMatrix	; record this trans
		call	GrGetTransform
		call	GrDestroyState			; don't need this
if	_LABELS
		call	GetLabelPageTranslation		; to xlate tween pages
endif
		.leave
		ret

		; the document is too big to fit on the page.  If the
		; scale-to-fit bit is set or if we are writing to labels,
		; scale the document, or else tile it.
docTooBig:
		test	curJob.SJI_info.JP_spoolOpts, mask SO_SCALE
if	_LABELS
		jnz	scaleIt
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
endif
		jz	tileIt
scaleIt::
		or	bx, mask OB_SCALE_TO_FIT

		; Make sure we are not in text mode. If we are in text
		; mode, we need to just print without rotating.

		cmp	curJob.SJI_info.JP_printMode,PM_FIRST_TEXT_MODE
		jge	setTransform
		
		; we might want to rotate the document as well as scale to fit,
		; to make better use of the paper.

		test	curJob.SJI_info.JP_spoolOpts, mask SO_FORCE_ROT
		jnz	rotateToFit

		mov	ax, curJob.SJI_printWidth	; see if landscape or
		cmp	ax, curJob.SJI_printHeight	;  or portrait
		movdw	dxax, curJob.SJI_docWidth	; check if doc is port
		ja	landscapeToFit			;  
		cmpdw	dxax, curJob.SJI_docHeight
		jbe	setTransform
rotateToFit:
		or	bx, mask OB_ROTATE
setTransformShort:
		jmp	setTransform

tileIt:

if	_PDL_PRINTING
		test	bx, mask OB_PDL			; PDL tiles differently
		jnz	tilePDLPage
endif	;_PDL_PRINTING

		; Make sure we are not in text mode. If we are in text
		; mode, we need narrow down the page width to take into account
		; the fact that most printers will wrap text that is too wide
		; for their printable width.

		cmp	curJob.SJI_info.JP_printMode,PM_FIRST_TEXT_MODE
		jl	widthCorrect			;if not in text mode
							;no modification
							;necessary.
                call    TilePDLDocument			;get # pages in x,y
		cmp	curJob.SJI_xPages, 1		;see if there are more
							;than 1 pages wide
		je	widthCorrect			;if not, just let it go
							;else......
		sub	curJob.SJI_printWidth,12	;leave 1/4" error band.

widthCorrect:
		call	TileDocument
		jmp	done

if	_PDL_PRINTING
tilePDLPage:
		call	TilePDLDocument
		jmp	done
endif	;_PDL_PRINTING

		; paper in landcape mode.  If doc is portrait, rotate it.
landscapeToFit:
		cmpdw	dxax, curJob.SJI_docHeight
		jae	setTransformShort
		jmp	rotateToFit
CalcDocOrientation endp

orientDoc	label	nptr
		word	offset	CenterUpright		; normal case
		word	offset	ScaleToFit		; SCALE_TO_FIT
		word	offset	RotateDoc		; ROTATE
		word	offset	RotateToFit		; SCALE_TO_FIT, ROTATE

if	_PDL_PRINTING
		word	offset 	CenterUprightPDL	; PDL
		word	offset	ScaleToFitPDL		; PDL, SCALE
		word	offset	RotateDocPDL		; PDL, ROTATE
		word	offset	RotateToFitPDL		; PDL, SCALE, ROTATE
endif	;_PDL_PRINTING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterUpright
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets transformation matrix for CalcDocOrientation

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJob	- inherited locals
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CenterUpright	proc	near
		uses	ax,bx,cx,dx
curJob		local	SpoolJobInfo
		.enter	inherit

		; we need to center the document in the page, accounting 
		; for the paper margins.

		movdw	dxcx, paperInfo.PSR_width
		subdw	dxcx, docInfo.PSR_width
		movdw	bxax, paperInfo.PSR_height
		subdw	bxax, docInfo.PSR_height
		movdw	dxbx, cxax			; get low parts up
		sar	dx, 1				; divide spare room
		sar	bx, 1
		sub	dx, paperInfo.PSR_margins.PCMP_left
		sub	bx, paperInfo.PSR_margins.PCMP_top
		clr	ax, cx
		call	GrApplyTranslation

		.leave
		ret
CenterUpright	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterUprightPDL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets transformation matrix for CalcDocOrientation

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJob	- inherited locals
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_PDL_PRINTING
CenterUprightPDL	proc	near
		uses	ax,bx,cx,dx
curJob		local	SpoolJobInfo
		.enter	inherit

		; we need to center the document in the page, accounting 
		; for the paper margins.

		movdw	dxcx, paperInfo.PSR_width
		subdw	dxcx, docInfo.PSR_width
		movdw	bxax, paperInfo.PSR_height
		subdw	bxax, docInfo.PSR_height
		movdw	dxbx, cxax			; get low parts up
		sar	dx, 1				; divide spare room
		sar	bx, 1
		clr	ax, cx
		call	GrApplyTranslation

		.leave
		ret
CenterUprightPDL	endp
endif	;_PDL_PRINTING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleToFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets transformation matrix for CalcDocOrientation

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJob	- inherited locals
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We want to align the printable area of the document
		with the printable area on the paper, so:

			1) translate for centering
			2) scale
			3) translate for the document margins (-left, -top)
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version
	don	2/24/94		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScaleToFit	proc	near
		uses	ax,bx,cx,dx,si
curJob		local	SpoolJobInfo
		.enter	inherit

		; calculate the various factors

		call	GetScaleToFitFactors
		pushwwf	dxcx			; save X factor
		pushwwf	bxax			; save Y factor
if	_LABELS
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jz	doCentering
		call	CalcLabelPageCenteringUpright
endif

		; account for any centering of the page
doCentering::
		mov	dx, di			; dx -> X centering offset
		clr	cx			; dx.cx -> X translation
		mov	bx, si			; si -> Y centering offset
		clr	ax			; bx.ax -> Y translation
		mov	di, ss:[curJob].SJI_gstate
		call	GrApplyTranslation	; apply margin translation

		; apply the scale factor

		popwwf	bxax			; bx.ax -> Y scale factor
		popwwf	dxcx			; dx.cx -> X scale factor
		call	GrApplyScale		; do the scaling thing

		; finally, translate to account for the fact that the
		; document includes margins, but we've scaled the document
		; so that the printable area of the document fits on the
		; printable area of the paper. This means that the
		; document margins will fall outside of the printable
		; area of the paper.
		;
		; For label printing, we actually draw the document
		; margins on the label, to avoid drawing to the absolute
		; edge of the label. So, we can just skip this code.
if	_LABELS
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jnz	done
endif
		mov	dx, docInfo.PSR_margins.PCMP_left
		neg	dx
		clr	cx			; dx.cx -> X translation
		mov	bx, docInfo.PSR_margins.PCMP_top
		neg	bx
		clr	ax			; bx.ax -> Y translation
		call	GrApplyTranslation
done::
		.leave
		ret
ScaleToFit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleToFitPDL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets transformation matrix for CalcDocOrientation

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJob	- inherited locals
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We want to align the printable area of the document
		with the printable area on the paper, so:

			1) translate for centering
			2) translate for the paper margins (+left, +top)
			3) scale
			4) translate for the document margins (-left, -top)
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version
	don	2/24/94		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_PDL_PRINTING
ScaleToFitPDL	proc	near
		uses	ax,bx,cx,dx,si
curJob		local	SpoolJobInfo
		.enter	inherit

		
		; calculate the various factors

		call	GetScaleToFitFactors
		pushwwf	dxcx			; save X factor
		pushwwf	bxax			; save Y factor

		; account for any centering of the page, and the
		; paper margins (because the scale factor is based
		; upon the printable area & actual document size)

		mov	dx, di			; dx -> X centering offset
		add	dx, paperInfo.PSR_margins.PCMP_left
		clr	cx			; dx.cx -> X translation
		mov	bx, si			; si -> Y centering offset
		add	bx, paperInfo.PSR_margins.PCMP_top
		clr	ax			; bx.ax -> Y translation
		mov	di, ss:[curJob].SJI_gstate
		call	GrApplyTranslation	; apply margin translation

		; apply the scale factor

		popwwf	bxax			; bx.ax -> Y scale factor
		popwwf	dxcx			; dx.cx -> X scale factor
		call	GrApplyScale		; do the scaling thing

		; finally, translate to account for the fact that the
		; document includes margins, but we've scaled the document
		; so that the printable area of the document fits on the
		; printable area of the paper. This means that the
		; document margins will fall outside of the printable
		; area of the paper.

		mov	dx, docInfo.PSR_margins.PCMP_left
		neg	dx
		clr	cx			; dx.cx -> X translation
		mov	bx, docInfo.PSR_margins.PCMP_top
		neg	bx
		clr	ax			; bx.ax -> Y translation
		call	GrApplyTranslation

		.leave
		ret
ScaleToFitPDL	endp
endif	;_PDL_PRINTING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure transform for rotate case

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJOb	- locals
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		1) rotate
		2) translate to bring image onto page
		3) translate for margins & centering
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateDoc	proc	near
		uses	ax,bx,cx,dx
curJob		local	SpoolJobInfo
		.enter	inherit

		; rotate it first

		mov	dx, -90		; rotate -90.0 degrees
		clr	cx
		call	GrApplyRotation

		; Now translate the document so that it's back in view.

		movdw	bxax, docInfo.PSR_height ; translate by height
		negdw	bxax
		clrdw	dxcx
		call	GrApplyTranslationDWord
		
		; Now we need to center it, like we did in CenterUpright.
		; we need to center the document in the page, accounting 
		; for the paper margins.

		movdw	bxax, paperInfo.PSR_width
		subdw	bxax, docInfo.PSR_height
		movdw	dxcx, paperInfo.PSR_height
		subdw	dxcx, docInfo.PSR_width
		movdw	dxbx, cxax			; get low parts up
		sar	dx, 1				; divide spare room
		sar	bx, 1
		neg	bx				; neg xlation in Y
		add	bx, paperInfo.PSR_margins.PCMP_left
		sub	dx, paperInfo.PSR_margins.PCMP_top
		clr	ax, cx
		call	GrApplyTranslation

		.leave
		ret
RotateDoc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateDocPDL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure transform for rotate case

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJOb	- locals
		di	- GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		1) rotate
		2) translate to bring image onto page
		3) translate for centering
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_PDL_PRINTING
RotateDocPDL	proc	near
		uses	ax,bx,cx,dx
curJob		local	SpoolJobInfo
		.enter	inherit

		; rotate it first

		mov	dx, -90		; rotate -90.0 degrees
		clr	cx
		call	GrApplyRotation

		; Now translate the document so that it's back in view.

		movdw	bxax, docInfo.PSR_height ; translate by height
		negdw	bxax
		clrdw	dxcx
		call	GrApplyTranslationDWord
		
		; Now we need to center it, like we did in CenterUprightPDL
		; we need to center the document in the page

		movdw	bxax, paperInfo.PSR_width
		subdw	bxax, docInfo.PSR_height
		movdw	dxcx, paperInfo.PSR_height
		subdw	dxcx, docInfo.PSR_width
		movdw	dxbx, cxax			; get low parts up
		sar	dx, 1				; divide spare room
		sar	bx, 1
		neg	bx				; neg xlation in Y
		clr	ax, cx
		call	GrApplyTranslation

		.leave
		ret
RotateDocPDL	endp
endif	;_PDL_PRINTING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateToFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure transform for CalcDocOrientation

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJob	- locals
		di	- GState
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We want to align the printable area of the document
		with the printable area on the paper, so:

			1) rotate
			2) translate to bring image onto page
			3) translate for centering
			4) scale
			5) translate for the document margins (-left, +bottom)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateToFit	proc	near
		uses	ax,bx,cx,dx,si
curJob		local	SpoolJobInfo
		.enter	inherit

		; rotate first (#1)

		mov	dx, -90
		clr	cx			; -90.0
		call	GrApplyRotation

		; calculate the various factors

		call	GetRotateToFitFactors
		pushwwf	dxcx			; save X factor
		pushwwf	bxax			; save Y factor
if	_LABELS
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jz	doCentering
		call	CalcLabelPageCenteringRotated
endif

		; convert centering offsets to DWord values (#3)
doCentering::
		mov	ax, di
		cwd
		movdw	bxcx, dxax		; bx:cx -> X centering offset
		mov	ax, si
		cwd
		xchg	bx, dx			; dx:cx -> X centering offset
						; bx:ax -> Y centering offset

		; push the image onto the page, and translate (#2)
		; we move by the paper width, not the document height,
		; because the document is scaled. We include the left
		; margin because the print driver expects the data to
		; start at the left margin.

		sub	ax, ss:[curJob].SJI_printWidth
		sbb	bx, 0
		mov	di, ss:[curJob].SJI_gstate
		call	GrApplyTranslationDWord

		; apply the scale factor (#4)

		popwwf	bxax			; bx.ax -> Y scale factor
		popwwf	dxcx			; dx.cx -> X scale factor
		call	GrApplyScale		; do the scaling thing

		; finally, translate to account for the fact that the
		; document includes margins, but we've scaled the document
		; so that the printable area of the document fits on the
		; printable area of the paper. This means that the
		; document margins will fall outside of the printable
		; area of the paper (#5)
		;
		; For label printing, we actually draw the document
		; margins on the label, to avoid drawing to the absolute
		; edge of the label. So, we can just skip this code.
if	_LABELS
		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jnz	done
endif
		mov	dx, docInfo.PSR_margins.PCMP_left
		neg	dx
		clr	cx			; dx.cx -> X translation
		mov	bx, docInfo.PSR_margins.PCMP_top
		neg	bx
		clr	ax			; bx.ax -> Y translation
		call	GrApplyTranslation
done::
		.leave
		ret
RotateToFit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateToFitPDL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure transform for CalcDocOrientation

CALLED BY:	INTERNAL
		CalcDocOrientation
PASS:		curJob	- locals
		di	- GState
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We want to align the printable area of the document
		with the printable area on the paper, so:

			1) rotate
			2) translate to bring image onto page
			3) translate for margins & centering
			4) scale
			5) translate for the document margins (-left, +bottom)
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version
	don	2/24/94		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_PDL_PRINTING
RotateToFitPDL	proc	near
		uses	ax,bx,cx,dx,si
curJob		local	SpoolJobInfo
		.enter	inherit

		; rotate first (#1)

		mov	dx, -90
		clr	cx			; -90.0
		call	GrApplyRotation

		; calculate the various factors

		call	GetRotateToFitFactors
		pushwwf	dxcx			; save X factor
		pushwwf	bxax			; save Y factor

		; account for any centering of the page, and the
		; paper margins (because the scale factor is based
		; upon the printable area & actual document size) (#3)

		mov	ax, di
		add	ax, paperInfo.PSR_margins.PCMP_top
		cwd
		movdw	bxcx, dxax		; bx:cx -> X centering offset
		mov	ax, si
		add	ax, paperInfo.PSR_margins.PCMP_left
		cwd
		xchg	bx, dx			; dx:cx -> X centering offset
						; bx:ax -> Y centering offset

		; push the image onto the page, and translate (#2)
		; we move by the paper width, not the document width,
		; because the document is scaled.

		subdw	bxax, paperInfo.PSR_width
		mov	di, ss:[curJob].SJI_gstate
		call	GrApplyTranslationDWord

		; apply the scale factor (#4)

		popwwf	bxax			; bx.ax -> Y scale factor
		popwwf	dxcx			; dx.cx -> X scale factor
		call	GrApplyScale		; do the scaling thing

		; finally, translate to account for the fact that the
		; document includes margins, but we've scaled the document
		; so that the printable area of the document fits on the
		; printable area of the paper. This means that the
		; document margins will fall outside of the printable
		; area of the paper (#5)

		mov	dx, docInfo.PSR_margins.PCMP_left
		neg	dx
		clr	cx			; dx.cx -> X translation
		mov	bx, docInfo.PSR_margins.PCMP_top
		neg	bx
		clr	ax			; bx.ax -> Y translation
		call	GrApplyTranslation

		.leave
		ret
RotateToFitPDL	endp
endif	;_PDL_PRINTING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetScaleToFitFactors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by both scale to fit routines

CALLED BY:	INTERNAL
		ScaleToFit, ScaleToFitPDL
PASS:		curJob	- inherited locals
RETURN:		dx.cx	- WWFixed X scale factor
		bx.ax	- WWFixed Y scale factor
		di	- X offset for centering
		si	- Y offset for centering
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Currently, the X & Y scale factors are the same, to
		avoid any document distortion.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version
	don	2/24/94		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetScaleToFitFactors	proc	near
curJob		local	SpoolJobInfo
		.enter	inherit

		; Calculate the Y scale factor first

		movdw	dxcx, curJob.SJI_docHeight
		mov	bx, curJob.SJI_printHeight
		call	CalcScaleFactor		; dx.cx -> Y scale factor 
		pushwwf	dxcx

		; Now calculate the X scale factor

		movdw	dxcx, curJob.SJI_docWidth
		mov	bx, curJob.SJI_printWidth
		call	CalcScaleFactor		; dx.cx -> X scale factor
		popwwf	bxax			; bx.ax -> Y scale factor
if	_LABELS
		movwwf	curJob.SJI_xScaleFactor, dxcx
		movwwf	curJob.SJI_yScaleFactor, bxax
endif

		; We don't want the document to be distorted, so
		; we'll make both scale factors the same. Given that,
		; we need to choose the smaller of the two scale factors

		jlewwf	dxcx, bxax, calcOffsets, di
		movwwf	dxcx, bxax

		; Finally, calculate the offset to center the
		; document on the page
		;	dx.cx = scale factor
calcOffsets:
if	_LABELS
		movwwf	curJob.SJI_finalScaleFactor, dxcx
endif
		movdw	sibx, curJob.SJI_docWidth
		mov	ax, curJob.SJI_printWidth
		call	CalcScaledDifference
		mov	di, si			; di -> X offset
		movdw	sibx, curJob.SJI_docHeight
		mov	ax, curJob.SJI_printHeight
		call	CalcScaledDifference	; si -> Y offset
		movwwf	bxax, dxcx		; dx.cx -> X scale factor

		.leave
		ret
GetScaleToFitFactors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRotateToFitFactors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by both scale to fit routines

CALLED BY:	INTERNAL
		RotateToFit, RotateToFitPDL
PASS:		curJob	- inherited locals
RETURN:		dx.cx	- WWFixed X scale factor
		bx.ax	- WWFixed Y scale factor
		di	- X offset for centering
		si	- Y offset for centering
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 8/93		Initial version
	don	2/24/94		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRotateToFitFactors	proc	near
curJob		local	SpoolJobInfo
		.enter	inherit

		; Calculate the Y scale factor first

		movdw	dxcx, curJob.SJI_docHeight
		mov	bx, curJob.SJI_printWidth
		call	CalcScaleFactor		; dx.cx -> Y scale factor 
		pushwwf	dxcx

		; Now calculate the X scale factor

		movdw	dxcx, curJob.SJI_docWidth
		mov	bx, curJob.SJI_printHeight
		call	CalcScaleFactor		; dx.cx -> X scale factor
		popwwf	bxax			; bx.ax -> Y scale factor
if	_LABELS
		movwwf	curJob.SJI_xScaleFactor, dxcx
		movwwf	curJob.SJI_yScaleFactor, bxax
endif

		; We don't want the document to be distorted, so
		; we'll make both scale factors the same. Given that,
		; we need to choose the smaller of the two scale factors

		jlewwf	dxcx, bxax, calcOffsets, di
		movwwf	dxcx, bxax

		; Finally, calculate the offset to center the
		; document on the page
		;	dx.cx = scale factor
calcOffsets:
if	_LABELS
		movwwf	curJob.SJI_finalScaleFactor, dxcx
endif
		movdw	sibx, curJob.SJI_docWidth
		mov	ax, curJob.SJI_printHeight
		call	CalcScaledDifference
		mov	di, si			; di -> X offset
		movdw	sibx, curJob.SJI_docHeight
		mov	ax, curJob.SJI_printWidth
		call	CalcScaledDifference	; si -> Y offset
		movwwf	bxax, dxcx		; dx.cx -> X scale factor

		.leave
		ret
GetRotateToFitFactors	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calclate the scale factor to make a document fit on a
		piece of paper (in one dimension, of course)

CALLED BY:	INTERNAL
		GetScaleToFitFactors, GetRotateToFitFactors
PASS:		dx:cx	- DWord document dimension
		bx	- paper dimension
RETURN:		dx.cx	- WWFixed scale factor
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	2/24/94		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcScaleFactor	proc	near
		uses	bp
		.enter

		; Calc (document / paper), for accuracy

		clr	ax, bp			; zero out the fractions
		call	GrSDivDWFbyWWF		; dxcxbp = quotient
EC <		tst	dx			; shouldn't happen	>
EC <		ERROR_NZ SPOOL_BAD_DOCUMENT_SIZE 			>

		; But we really want (paper / document)
		; 	Passed:	dx = 0

		movwwf	bxax, cxbp		; bx.ax = inverse scale
		mov	cx, dx
		inc	dx			; dx.cx = 1.0
		call	GrSDivWWFixed		; dx.cx = scale factor

		.leave
		ret
CalcScaleFactor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcScaledDifference
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calclate the difference between the paper dimensions and
		the scaled document dimension, and halve it

CALLED BY:	INTERNAL
		GetScaleToFitFactors, GetRotateToFitFactors
PASS:		dx.cx	- WWFixed scale factor
		si:bx	- DWord document dimension
		ax	- paper dimension
RETURN:		si	- difference (signed)
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	2/24/94		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcScaledDifference	proc	near
		uses	cx, dx, di
		.enter

		; Multiply the scale factor by the document dimension

		push	ax			; save paper dimension
		clr	di			; di:dx.cx -> scale factor
		clr	ax			; si:bx.ax -> doc dimension
		call	GrMulDWFixed	

		; Ensure we have not encountered overflow

EC <		ERROR_C	SPOOL_BAD_DOCUMENT_SIZE 			>
EC <		tst	dx			; must be zero ...	>
EC <		ERROR_NZ SPOOL_BAD_DOCUMENT_SIZE			>

		; Calculate the difference between the scaled value
		; and the paper dimension

		rndwwf	cxbx
		pop	si
		sub	si, cx
		sar	si, 1			; halve the difference

		; We don't allow a negative value to be returned, as
		; we've scaled the document to fit on the page. A
		; negative value at this point means we've introduced
		; some error when calculating the scale factor.

		tst	si
		jns	done
		clr	si
done:
		.leave
		ret
CalcScaledDifference	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TileDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure tiling and margin translation for dot-matrix type
		print out. (Either text or graphics mode)

CALLED BY:	INTERNAL
		CalcDocOrientation

PASS:		di	- handle to GState
		dxcx, bxax	- width,height of document
		curJob	- everything else

RETURN:		dxcx	- net x translation required
		bxax	- net y translation required

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For both graphics and text mode, the (0,0) coordinate 
		position for most printer drivers will be a the upper left
		corner of the printable area on the page.  This represents
		the "window" that we will be printing the document to.  That
		means that we'll have to account for the paper margins in
		our transformation matrix.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TileDocument	proc	near
		uses	ax,bx,cx,dx
curJob		local	SpoolJobInfo
		.enter	inherit

		; calc #pages across and down

		call	TilePDLDocument			; this part is the same

		; now we still need to translate the doc over, like in
		; CenterUpright (see routine above)

		mov	dx, paperInfo.PSR_margins.PCMP_left
		cmp	dx, docInfo.PSR_margins.PCMP_left
		jle	leftOK
		mov	dx, docInfo.PSR_margins.PCMP_left
leftOK: 
		mov	bx, paperInfo.PSR_margins.PCMP_top
                cmp     bx, docInfo.PSR_margins.PCMP_top
                jle     topOK
                mov     bx, docInfo.PSR_margins.PCMP_top
topOK:
		neg	dx
		neg	bx
		clr	ax, cx				; no fractions
		call	GrApplyTranslation

		.leave
		ret
TileDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TilePDLDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure tiling and centering translation for PDL-type printer.

CALLED BY:	INTERNAL
		CalcDocOrientation

PASS:		di	- handle to GState
		curJob	- everything else

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For PDL-printers, the (0,0) coordinate position for will 
		be at the upper left corner of the paper.  This means that 
		we only have to account for the centering of the document 
		on the paper if the document is smaller.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	02/93		Fixed signed-math problems

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TilePDLDocument	proc	near
		uses	ax,bx,cx,dx
curJob		local	SpoolJobInfo
		.enter	inherit

		; calculate the number of pages to tile over.

		movdw	dxax, curJob.SJI_docWidth	; figure width
		clr	bx
		mov	cx, docInfo.PSR_margins.PCMP_left ; add in left side
		sub	cx, paperInfo.PSR_margins.PCMP_left
		sbb	bx, 0
		adddw	dxax, bxcx
		mov	cx, curJob.SJI_printWidth	; 
		div	cx				; ax = #pages
		add	dx, 0xffff			; if any left over
		adc	ax, 0				; ax = #pages
		mov	curJob.SJI_xPages, ax

		movdw	dxax, curJob.SJI_docHeight	; figure height
		clr	bx
		mov	cx, docInfo.PSR_margins.PCMP_top ; add in top side
		sub	cx, paperInfo.PSR_margins.PCMP_top
		sbb	bx, 0
		adddw	dxax, bxcx
		mov	cx, curJob.SJI_printHeight	; 
		div	cx				; ax = #pages
		add	dx, 0xffff			; if any left over
		adc	ax, 0				; ax = #pages
		mov	curJob.SJI_yPages, ax

		or	curJob.SJI_printState, mask SPS_TILED

		.leave
		ret
TilePDLDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustTileForTractor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the tiling factors if the paper is tractor fed.
		In that case, we want to print across the perforations

CALLED BY:	INTERNAL
		PrintFile

PASS:		curJob frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function requires that START_JOB has already been
		invoked in the printer driver.

REVISION HISTORY:
	 	Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustTileForTractor	proc	near
		uses	ax, bx, cx, dx, si
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

if	_LABELS
		; check to see if we are in a Thumbnail mode, in which case
		; we let the code in processLabel.asm handle the orientation
		; stuff.  Same goes for labels, 'natch.

		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jnz	done
endif

		; the way we test for the tractor has changed for 2.0.
		; We need to check the PState, but after START_JOB has
		; been called. (which it has already).

		push	ds
		mov	bx, curJob.SJI_pstate	; grab pstate handle
		call	MemLock			; ax -> PState
		mov	ds, ax
		test	ds:[PS_paperInput], mask PIO_TRACTOR
		call	MemUnlock		; (flags preserved)
		pop	ds
		jz	done

		; OK, there is a tractor unit.  If we have more than one
		; page of tiling in y, then just make them TALL pages and
		; eliminate the y loop.

		cmp	curJob.SJI_yPages, 1	; more than 1 ?
		jle	done			;  no, nothing to do


if	_TEXT_PRINTING
		; this calculation goes differently for text mode

		cmp	curJob.SJI_info.JP_printMode, PM_FIRST_TEXT_MODE ; 
		jae	doTextAdjust
endif	;_TEXT_PRINTING

		; OK, we want to do something different.  If the document
		; has been rotated, then we want to make the SJI_pageH
		; variable equal to the document width and eliminate the
		; SJI_yPages variable.  If the document is not rotated then
		; we make SJI_pageH equal to the document height.  SJI_pageH
		; is in device units.

		movdw	sibx, docInfo.PSR_height
		mov	curJob.SJI_yPages, 0	; don't do more than one
		test	curJob.SJI_printState, mask SPS_ROTATED ; rotated ?
		jz	calcNewPageHeight
		movdw	sibx, docInfo.PSR_width

calcNewPageHeight:
		sub	bx, paperInfo.PSR_margins.PCMP_top
		sbb	si, 0
		clr	cx				; si.bx.cx = 1st arg
		mov	ax, curJob.SJI_pYscale.WWF_int ;
		cwd
		mov	di, dx	
		mov	dx, ax
		mov	ax, curJob.SJI_pYscale.WWF_frac ; di.dx.ax = 2nd arg
		xchg	ax, cx				; swap fractions
		call	GrMulDWFixed		; do multiply
		rcl	bx, 1			; round appropriately
		adc	cx, 0
		adc	dx, 0			; dx.cx = dword result

		; we need to make sure it's a multiple of the band height

		mov	ax, cx			; dxax = dividend
		mov	cx, curJob.SJI_bandH	; cx =  divisor (band height)
		dec	cx
		add	ax, cx			; round up to next band
		adc	dx, 0
		inc	cx
		div	cx			; ax = #bands / page
		mul	cx			; dx:ax = page height truncated
		movdw	curJob.SJI_pageH, dxax	; save entire page height
done:
		.leave
		ret

if	_TEXT_PRINTING
	; we have more than one page high of text to print and we're
	; printing in text mode.
doTextAdjust:
		mov	curJob.SJI_yPages, 0	; don't do more than one
		movdw	dxax, docInfo.PSR_height
		movdw	curJob.SJI_pageH, dxax	; fake a new bottom
		jmp	done
endif	;_TEXT_PRINTING

AdjustTileForTractor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForSupressFF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If form feed should be supressed, then adjust the page height

CALLED BY:	INTERNAL
		PrintFile

PASS:		curJob (inherited stack frame)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if we're in supress FF mode, then adjust the pageH for graphics
		printing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustForSupressFF proc	near
		uses	ax,bx,cx,dx,si,di
curJob		local	SpoolJobInfo
		.enter inherit

if	_LABELS
		; check to see if we are in a Label mode, in which case
		; we let the code in processLabel.asm handle the orientation
		; stuff.  

		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jnz	done
endif

		; only do this for SUPRESS_FF mode

		test	curJob.SJI_printState, mask SPS_FORM_FEED
		jnz	done

		; only need this for graphics mode

if	_TEXT_PRINTING
		cmp	curJob.SJI_info.JP_printMode, PM_FIRST_TEXT_MODE
		jae	done
endif	;_TEXT_PRINTING

		; if we're tiled and have more than a page, forget this

		test	curJob.SJI_printState, mask SPS_TILED
		jz	notTiled
		cmp	curJob.SJI_yPages, 1		; more than a page ?
		ja	done

		; if we need to supress form feed, then make the page 
		; height equal to the document height (or width if we're
		; rotated)
notTiled:
		movdw	bxcx, docInfo.PSR_height
		mov	curJob.SJI_yPages, 0	; don't do more than one
		test	curJob.SJI_printState, mask SPS_ROTATED ; rotated ?
		jz	havePageHeight
		movdw	bxcx, docInfo.PSR_width

havePageHeight:
		sub	cx, paperInfo.PSR_margins.PCMP_top
		sbb	bx, 0
		clr	si				; si.bx.cx = 1st arg
		mov	ax, curJob.SJI_pYscale.WWF_int ;
		cwd
		mov	di, dx	
		mov	dx, ax
		mov	ax, curJob.SJI_pYscale.WWF_frac ; di.dx.ax = 2nd arg
		xchg	ax, cx				; swap fractions
		call	GrMulDWFixed		; do multiply
		rcl	bx, 1			; round appropriately
		adc	cx, 0
		adc	dx, 0			; dx.cx = dword result
		movdw	curJob.SJI_pageH, dxcx		; have new page height
done:
		.leave
		ret
AdjustForSupressFF endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the job out of the queue.  Delete the spool file.  
		Commit suicide if that was the last one

CALLED BY:	INTERNAL
		SpoolerLoop

PASS:		inherits local vars from SpoolerLoop

RETURN:		if no jobs left in queue:
			carry set
			ds - locked PrintQueue block
			ds:si - points at current QueueInfo structure
		else
			PrintQueue unlocked

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Note: 	If this exits with the carry set, the queueSemaphore
		remains down.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemoveJob	proc	far
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; first, check for errors or pauses (error DB up)

		call	CheckForErrors		; SpoolInterruptions => AL
		cmp	al, SI_DETACH		; are we detaching ?
		jne	maybeDelete		; no, go check to delete
		
		test	curJob.SJI_info.JP_spoolOpts, mask SO_SHUTDOWN_ACTION
		jz	lockDownQueue		; => not canceling job, so
						;  DON'T delete the file
maybeDelete:
		; next delete the spool file if that is appropriate

		test	curJob.SJI_info.JP_spoolOpts, mask SO_DELETE
		jz	lockDownQueue		; don't delete the file
		segmov	ds, ss, dx		; point at filename
		lea	dx, curJob.SJI_info.JP_fname	; ds:dx -> filename
		call	FileDelete

		; first we need to grab control of the PrintQueue
lockDownQueue:
		call	LockQueue
		mov	ds, ax			; ds -> PrintQueue

		; set up pointer to queue info

		mov	bx, curJob.SJI_qHan	; get chunk handle of queue
		mov	si, ds:[bx]		; ds:si -> QueueInfo
		mov	bx, ds:[si].QI_curJob 	; *ds:bx -> finished job info

		cmp	ds:[si].QI_error, SI_DETACH
		je	notifyOtherCanceled

removeCurJob:
		call	SendJobRemovedNotification

		mov	ax, bx			; get copy of chunk handle
		mov	di, ds:[bx]		; ds:di -> job info
		mov	bx, ds:[di].JIS_next	; get handle of next job

		; whatever we do, we're going to nuke this job info..

		call	LMemFree		; free this job block
		dec	ds:[PQ_numJobs]		; one less job to do
		tst	bx			; any more jobs in this queue ?
		jz	fieryDeath		;   NO, AHHHHHHhhhh....

		; OK, so there are more jobs to do...

		mov	ds:[si].QI_curJob, bx	; make it the current one
		clr	ds:[si].QI_fileHan	; clear out rest of the info
		clrdw	ds:[si].QI_filePos
		clr	ds:[si].QI_curPage
		clr	ds:[si].QI_curPhysPg
		clr	ds:[si].QI_numPhysPgs
		mov	ds:[si].QI_error, SI_KEEP_GOING

		; still another job or queue, but leave it for next go-round

		call	UnlockQueue		;
		clc				; signal to keep going
exit:
		.leave
		ret

		; we finished all the jobs in the queue, so shut down
		; leaving the PrintQueue 
fieryDeath:
		stc
		jmp	exit

notifyOtherCanceled:
	;
	; When detaching, we need to let anyone interested know that we're
	; canceling all jobs marked with SO_SHUTDOWN_ACTION == SSJA_CANCEL_JOB
	;
		push	bx
		mov	di, ds:[bx]		; ds:di <- prev job (for the
						;  loop; current job will be
						;  nuked when we jump back into
						;  the fray)
notifyCancelLoop:
		mov	bx, ds:[di].JIS_next
		tst	bx
		jz	notifyCancelDone
	    ;
	    ; Is job marked for cancelation?
	    ; 
		mov	di, ds:[bx]
	CheckHack <SSJA_CANCEL_JOB eq 1 and width SO_SHUTDOWN_ACTION eq 1>

		test	ds:[di].JIS_info.JP_spoolOpts, mask SO_SHUTDOWN_ACTION
		jz	notifyCancelLoop		; no
	    ;
	    ; It is, please let the world know. This should be all we need to
	    ; do, as the job will be nuked from the state file on restart.
	    ; Must nuke the spool file if it was requested...
	    ;
		test	ds:[di].JIS_info.JP_spoolOpts, mask SO_DELETE
		jz	sendNotification
		
		push	dx
		lea	dx, ds:[di].JIS_info.JP_fname
		call	FileDelete
		pop	dx

sendNotification:
		call	SendJobRemovedNotification
		jmp	notifyCancelLoop

notifyCancelDone:
		pop	bx
	;
	; Truncate the job list so the thread knows to go away when we return.
	;
		mov	di, ds:[bx]
		mov	ds:[di].JIS_next, 0
		jmp	removeCurJob
RemoveJob	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if anyone killed this job or if there are any comm
		errors pending

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- set if job should be aborted
		AL	- Queue's current SpoolInterruptions value

DESTROYED:	AH

PSEUDO CODE/STRATEGY:
		Check the QI_error field for possible communications errors
		and user-initiated aborts.  Another option is SI_PAUSE, which
		means that a DB is up concerning this print thread.  The
		thread should then suspend operations until the condition
		is cleared (it will be cleared when the user has selected
		some option from the DB).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckForErrors	proc	far
		uses	bx,ds
curJob		local	SpoolJobInfo
		.enter	inherit

		; lock down the PrintQueue

		call	LockQueue
		mov	ds, ax

		; dereference our queue handle and check the variable

		mov	bx, curJob.SJI_qHan	; get handle 
		mov	bx, ds:[bx]		; dereference chunk handle
EC <		cmp	ds:[bx].QI_error, SpoolInterruptions	>
EC <		ERROR_GE SPOOL_INVALID_INTERRUPTION_TYPE	>
		cmp	ds:[bx].QI_error, SI_KEEP_GOING ; abort ?
		jne	someInterruption	;  maybe, else carry clear

		; all done, unlock and leave
done:
		pushf				; save carry status
		mov	al, ds:[bx].QI_error	; SpoolInterruptions => AL
		call	UnlockQueue		; destorys nothing!
		popf				; restore carry

		.leave
		ret

		; set the carry to abort printing
someInterruption:
		cmp	ds:[bx].QI_error, SI_PAUSE ; signal to pause ?
		je	pauseThread
		cmp	ds:[bx].QI_error, SI_ABORT ; signal to abort
		cmc				; invert the carry flag
		jmp	done			; SI_ABORT, SI_DETACH &
						;  SI_ERROR => CS
						; SI_KEEP_GOING => Carry Clear

		; pause until the user answers
pauseThread:
		call	UnlockQueue		; release the queue

if  _PRINTING_DIALOG
ife _NO_PAUSE_RESUME_UI
                mov     cx, offset PDPausedGlyph
                mov     dx, offset PDPrintingGlyph
                call    SetPauseOrResume

                mov     cx, offset PDResumeTrigger
                mov     dx, offset PDPauseTrigger
                call    SetPauseOrResume
endif ; !_NO_PAUSE_RESUME_UI
endif

pauseLoop::
		mov	ax, 60			; sleep a second
		call	TimerSleep		; take it easy

		call	LockQueue		; regain the queue
		mov	ds, ax			; ds -> queue
		mov	bx, curJob.SJI_qHan	; get queue handle
		mov	bx, ds:[bx]		; dereference handle

if _PRINTING_DIALOG
		cmp	ds:[bx].QI_error, SI_PAUSE
		jne	resume

		call	UnlockQueue
		jmp	pauseLoop
resume:
ife _NO_PAUSE_RESUME_UI
                mov     cx, offset PDPrintingGlyph
                mov     dx, offset PDPausedGlyph
                call    SetPauseOrResume

                mov     cx, offset PDPauseTrigger
                mov     dx, offset PDResumeTrigger
                call    SetPauseOrResume
endif ; !_NO_PAUSE_RESUME_UI
endif		
		jmp	someInterruption	; recheck condition
CheckForErrors	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:        SetPauseOrResume

SYNOPSIS:       Sets pause or resume trigger usable.

CALLED BY:      CheckForErrors

PASS:           cx -- chunk handle of trigger to set usable
                dx -- chunk handle of trigger to set not usable

RETURN:         nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Chris   12/ 1/93        Initial version

------------------------------------------------------------------------------@

if  _PRINTING_DIALOG
ife _NO_PAUSE_RESUME_UI
SetPauseOrResume	proc	near
	curJob	local	SpoolJobInfo
	uses	ax,bx,cx,dx,si,di,bp
	.enter  inherit

	push	dx
	mov	bx, curJob.SJI_prDialogHan
	mov	si, cx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_MAKE_FOCUS		;force the focus on this guy,
	call	ObjMessage			;  it probably had been on the
	pop	si				;  other guy.

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessage

	.leave
	ret
SetPauseOrResume        endp
endif  ; !_NO_PAUSE_RESUME_UI
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BumpPageNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bump curpage variable in PrintQueue, check for abort

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- set if job should be aborted

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Just bump the page number, store a new file offset.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BumpPageNumber	proc	far
		uses	ax,bx,ds
curJob		local	SpoolJobInfo
		.enter	inherit

		; lock down the PrintQueue

		call	LockQueue
		mov	ds, ax

		; dereference our queue handle and check the variable

		mov	bx, curJob.SJI_qHan	; get handle 
		mov	bx, ds:[bx]		; dereference chunk handle
		inc	ds:[bx].QI_curPage 	; see if abort signal set
		mov	ax, {word} curJob.SJI_fPos ; get and store file pos
		mov	{word} ds:[bx].QI_filePos, ax
		mov	ax, {word} curJob.SJI_fPos+2	
		mov	{word} ds:[bx].QI_filePos+2, ax 

		; all done, unlock and leave

		call	UnlockQueue
		clc				; signal no abort

		.leave
		ret

BumpPageNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BumpPhysPageNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bump the physical page number and send out notification to
		those that are interested.

CALLED BY:	(INTERNAL)
PASS:		ss:bp	= inherited variables
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	MSG_PRINT_STATUS_CHANGE is issued

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/30/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BumpPhysPageNumber proc	far
		uses	ax,bx,ds, si, cx, dx, di, bp
curJob		local	SpoolJobInfo
		.enter	inherit

		; lock down the PrintQueue

		call	LockQueue
		mov	ds, ax

		; dereference our queue handle and check the variable

		mov	bx, curJob.SJI_qHan	; get handle 
		mov	bx, ds:[bx]		; dereference chunk handle
		inc	ds:[bx].QI_curPhysPg
		mov	bp, ds:[bx].QI_curPhysPg
		
		mov	bx, ds:[bx].QI_curJob
		mov	bx, ds:[bx]
		GetJobID	ds, bx, dx

		mov	cx, PSCT_NEW_PAGE
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	si, GCNSLT_PRINT_JOB_STATUS
		mov	di, mask GCNLSF_FORCE_QUEUE
		mov	ax, MSG_PRINT_STATUS_CHANGE
		call	GCNListRecordAndSend
		
		call	UnlockQueue
		.leave
		ret
BumpPhysPageNumber endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current page number

CALLED BY:	(INTERNAL)
PASS:		ss:bp	= inherited variables
RETURN:		cx	= logical page number
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPageNumber	proc	far
curJob	local	SpoolJobInfo
	uses	ax,bx,ds
	.enter	inherit

	; lock down the PrintQueue

	call	LockQueue
	mov	ds, ax
	
	; dereference our queue handle and check the variable

	mov	bx, curJob.SJI_qHan	; get handle 
	mov	bx, ds:[bx]		; dereference chunk handle
	mov	cx, ds:[bx].QI_curPage

	call	UnlockQueue

	.leave
	ret
GetPageNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrinterDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the print driver to get/init all kinds of info

CALLED BY:	INTERNAL
		PrintFile

PASS:		inherits SpoolJobInfo block

RETURN:		carry set on error (StoppedByError already called)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	01/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPrinterDriver proc	near
		uses	ax, bx, cx,dx,si,di,ds
curJob		local	SpoolJobInfo
		.enter  inherit

		; first get the print device enum by matching strings and set
		; as current device

		mov	bx, curJob.SJI_pstate	; save handle
		lea	si, curJob.SJI_info.JP_deviceName
		mov	dx, ss			; dx:si -> string
		mov	di, DRE_SET_DEVICE
		call	curJob.SJI_pDriver

		; While we're using the DriverInfo block (above functions do
		; that), look there to find the resent value for the device

		mov	di, DR_PRINT_DRIVER_INFO
		call	curJob.SJI_pDriver	; get handle to driver info
		mov	bx, dx			; bx = handle to driver info
		call	MemLock	; lock it down
		mov	es, ax			; es:si -> driver info
		add	si, size DriverExtendedInfoTable
		mov	dx, es:[si].PDI_resendOrNot	; get resend flag
		call	MemUnlock		; done with resource
		call	LockQueue		; store timeout values 
		mov	ds, ax			; ds-> queue
		mov	bx, curJob.SJI_qHan	; get queue handle
		mov	bx, ds:[bx]		; dereference handle
		mov	ds:[bx].QI_resend, dx	; 
		mov	al, curJob.SJI_info.JP_retries
		mov	ah, al
		mov	{word} ds:[bx].QI_maxRetry, ax
		call	UnlockQueue		; release the print queue

		; we need to fetch the printer smarts for later on

		mov	bx, curJob.SJI_pstate	; pass pstate handle
		mov	di, DR_PRINT_DEVICE_INFO ; get printer device info
		call	curJob.SJI_pDriver	; call printer driver
		mov	bx, dx			; bx = handle to driver info
		call	MemLock			; lock it down
		mov	es, ax			; es:si -> driver info
		mov	cl, es:[si].PI_smarts	; get printer smarts bits
		and	cl, mask SPS_SMARTS	; isolate bits 
		or	cl, mask SPS_FORM_FEED	; assume initial form

		; The print state may alread have the tiramisu flag set,
		; so we do the or in a register.
		 	
		mov	ch, curJob.SJI_printState
		or	cl, ch
		mov	curJob.SJI_printState, cl
		call	MemUnlock		; done with resource

		; set the print mode and paper info
		; we have to set up the proper width and height in the Job
		; Parameters block so that we can pass it onto the printer
		; driver.  This was originally done in CalcDocOrientation, but
		; that is too late.
setmode::
		mov	ax, paperInfo.PSR_width.low
EC <		tst	paperInfo.PSR_width.high	>
EC <		ERROR_NZ SPOOL_PAPER_SIZE_TOO_LARGE			>
		mov	si, paperInfo.PSR_height.low
EC <		tst	paperInfo.PSR_height.high >
EC <		ERROR_NZ SPOOL_PAPER_SIZE_TOO_LARGE			>

if	_LABELS
		; check out labels, cause we have to fake the numCopies thang
		; to defeat using a numCopies deal in the printer

		mov	dx, curJob.SJI_info.JP_paperSizeInfo.PSR_layout
		test	dx, PT_LABEL
		jz	havePaperSize
		call	InitLabelVariables
		call	CalcLabelSheetSize	; ax = width, si = height

		; while we know we have labels, fake out the numCopies to 
		; show as 1 for START_JOB, so we have control over that.

		mov	cx, ax			; save paper width
		mov	bx, curJob.SJI_pstate	; save handle
		call	MemLock
		mov	ds, ax
		mov	al, ds:[PS_jobParams].JP_numCopies
		push	ax			; save orig #copies desired
		mov	ds:[PS_jobParams].JP_numCopies, 1
		call	MemUnlock		
		mov	ax, cx			; restore paper width
endif
havePaperSize::
		mov	bx, curJob.SJI_pstate	; save handle
		mov	di, DR_PRINT_SET_MODE	
		push	ax, si			; save width/height
		mov	cl, curJob.SJI_info.JP_printMode
		call	curJob.SJI_pDriver
		pop	ax, si			; restore width/height

		; calculate the page size info. No printer in the world
		; has zero or negative printable area, so if we end up
		; with a non-positive value, we can only assume the user
		; has chosen a paper size that doesn't really exist. Under
		; this extreme case, we force a 1/2" in each dimension.

		sub	ax, paperInfo.PSR_margins.PCMP_right
		sub	ax, paperInfo.PSR_margins.PCMP_left
		jg	storePrintWidth
		mov	ax, 36
storePrintWidth:
		mov	curJob.SJI_printWidth, ax
		sub	si, paperInfo.PSR_margins.PCMP_bottom
		sub	si, paperInfo.PSR_margins.PCMP_top
		jg	storePrintHeight
		mov	si, 36
storePrintHeight:
		mov	curJob.SJI_printHeight, si

		; calculate the doc size too

		movdw	dxcx, docInfo.PSR_width
		mov	ax, docInfo.PSR_margins.PCMP_left 
		add	ax, docInfo.PSR_margins.PCMP_right
		sub	cx, ax
		sbb	dx, 0
		movdw	curJob.SJI_docWidth, dxcx
		movdw	dxcx, docInfo.PSR_height
		mov	ax, docInfo.PSR_margins.PCMP_top
		add	ax, docInfo.PSR_margins.PCMP_bottom
		sub	cx, ax
		sbb	dx, 0
		movdw	curJob.SJI_docHeight, dxcx

		; At this point, we need to do extra things for the graphics 
		; modes.  For graphics, we need to determine the size of 
		; the bitmap buffer we'll be creating and the scale factor 
		; we will need to apply.  This will be determined from 
		; the band size info and device resolution info from the driver

		mov	curJob.SJI_pXscale.WWF_int, 1 ; init scale factor first
		mov	curJob.SJI_pYscale.WWF_int, 1 ; init scale factor first
		mov	curJob.SJI_pXscale.WWF_frac, 0 ; init scale factor first
		mov	curJob.SJI_pYscale.WWF_frac, 0 ; init scale factor first

		cmp	curJob.SJI_info.JP_printMode, PM_FIRST_TEXT_MODE ; 
if	_TEXT_PRINTING
		jae	handleTextMode
else
		jae	done			;crap out gracefully
endif	;_TEXT_PRINTING

		; OK, we have a graphics mode to take care of.  Get the info
doGraphicsInit::
		call	CalcPageSizeInfo	; do all the graphics calcs

		; finally, call start print to get things rolling
sendStartJob::
		mov	bx, curJob.SJI_pstate	; set up handle to PState
		mov	dx, ss			; set up ptr to JobParams
		lea	si, curJob.SJI_info	; dx:si -> JobParameters
		mov	di, DR_PRINT_START_JOB	; signal start of job
		call	curJob.SJI_pDriver

if	_LABELS
		jc	done
		; finally, we fudged the numCopies above for LABEL printing,
		; so set it back again.
		pushf
		pop	cx			; cx <- flags
		test	paperInfo.PSR_layout, PT_LABEL
		jz	doneLabels
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		pop	ax
		mov	ds:[PS_jobParams].JP_numCopies, al
		call	MemUnlock
doneLabels:
		push	cx			; returns flags
		popf
endif
done::
		jnc	exit
		call	StoppedByError
exit:
		.leave
		ret

if	_TEXT_PRINTING
		; just initialize the page bottom to the right value
handleTextMode:
		mov	ax, paperInfo.PSR_margins.PCMP_bottom
		clr	dx
		movdw	curJob.SJI_pageH, dxax
		jmp	sendStartJob
endif	;_TEXT_PRINTING

InitPrinterDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcPageSizeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do all the calculations needed to print a graphics page

CALLED BY:	INTERNAL
		InitPrinterDriver

PASS:		bx	- PState handle
		inherits curJob local space

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		Get info from print driver like resolution, band size, etc.
		Calculate the output bitmap size, swath size, etc.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcPageSizeInfo proc	near
curJob		local	SpoolJobInfo
		.enter	inherit

		push	bx			; save PState handle
		mov	di, DR_PRINT_DEVICE_INFO
		call	curJob.SJI_pDriver
		mov	bx, dx			; 
		push	bx			; save handle
		call	MemLock	; lock the resource
		mov	es, ax			; es -> info block
		mov	bl, curJob.SJI_info.JP_printMode ; index using mode
		clr	bh
		mov	si, es:PI_firstMode[si][bx] ; get pointer to mode info

		; save device resolution and calculate scale factors

		mov	dl, es:[si].GP_colorFormat ; get this while we're here
		mov	curJob.SJI_colorFormat, dl ; save color format
		mov	dx, es:[si].GP_colorCorrection ; get correction tab
		mov	curJob.SJI_colorCorrection, dx	

	;
	; We use the fax resolutions if tiramisu printing.
	;
		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jz	normal
	;
	; Unless this is not a postscript printer...
	;
		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS		; is it PostScript ?
		cmp	al, PS_PDL
		jne	normal				; nope

		call	TiramisuGetResolution	; dx <- x res, cx, y res
		push	cx
		jmp	gotRes
normal:
		mov	dx, es:[si].GP_xres	; get x resolution
		push	es:[si].GP_yres	; get y resolution
gotRes:
		mov	curJob.SJI_pXres, dx	; save x res
		clr	cx			; calculate x scale factor
		mov	bx, 72			; default is 72 dpi
		clr	ax
		call	GrUDivWWFixed		; calc scale factor
		movwwf	curJob.SJI_pXscale, dxcx ; save it
		pop	dx			; y res
		mov	curJob.SJI_pYres, dx	; and save it
		clr	cx			; calculate x scale factor
		call	GrUDivWWFixed		; calc scale factor
		movwwf	curJob.SJI_pYscale, dxcx ; save it
		
		mov	al, es:[si].GP_bandHeight ; height of each band
		clr	ah
		mov	curJob.SJI_bandH, ax	; and save it

		; done with device info block, so unlock it

		pop	bx			; restore handle
		call	MemUnlock		; unlock info block
		pop	bx			; restore PState handle

		; now we need to calculate how big a swath we'll do.  We want
		; it to be sizeable, so we don't have to do too many passes,
		; but not so big as to hog all of memory.  Also, we may (in
		; the spooler) implement the process as two threads, one of
		; which talks to the printer driver and the other that
		; builds out the page.  In this case, we may only need a
		; buffer that is one or two bands high....
		;
		; for now, the algorithm we use is this:  allocate a fixed
		; size block and figure out how many bands will fit, 
		; accounting for color info...

		mov	dx, curJob.SJI_printWidth
		clr	cx

		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS		; is it PostScript ?
		cmp	al, PS_PDL
		jne	scaleX

		; we add left margin for PDL because postscript printers start
		; printing from the left edge of the paper.  this is usually
		; not a problem, because we normally don't create bitmaps when
		; printing to postscript printers.  but now we may create a
		; bitmap even when printing to postscript if we are printing
		; faxes (Tiramisu). - Joon (1/23/96)

		add	dx, paperInfo.PSR_margins.PCMP_left
scaleX:
		movwwf	bxax, curJob.SJI_pXscale
		call	GrMulWWFixed		; do multiply
		shl	cx, 1			; carry gets high bit
		adc	dx, 0			; round appropriately
		mov	curJob.SJI_bandW, dx	; save width
		mov	cx, dx			; cx will = #bytes/scan line
		mov	al, curJob.SJI_colorFormat ; get bitmap color format
		and	al, mask BMT_FORMAT	; isolate color info
		cmp	al, BMF_4CMYK		; if CMY or CMYK
		ja	doMono
		cmp	al, BMF_MONO
		jne	doWierdColor		; do 4-, 8-, 24-bit color
doMono:
		add	cx, 7			; round up to nearest byte
		shr	cx, 1			; divide by 8 to get bytes
		shr	cx, 1
		shr	cx, 1
		cmp	al, BMF_MONO		; if mono, done
		je	haveScanSize
		shl	cx, 1			; else CMY, so *4
		shl	cx, 1
haveScanSize:
		mov	ax, curJob.SJI_bandH	; calc #bytes/band
		mul	cx			; ax = #bytes/band
		mov	cx, ax
		mov	bx, dx			; bx:dx = #bytes/band
		mov	ax, SPOOL_SWATH_DATA_SIZE_LOW
		mov	dx, SPOOL_SWATH_DATA_SIZE_HIGH
calcBandsPerSwath:
		tst	bx			; if size of band too large
		jnz	divisorTooBig
		div	cx			; ax = #bands to print
		inc	ax			; round up for good measure
		mov	cx, curJob.SJI_bandH	; calc height of swath
		mul	cx			; ax = swath height
		mov	curJob.SJI_swathH, ax

		; scale height to get entire page height

		mov	dx, curJob.SJI_printHeight ; calc page height (points)
		clr	cx

		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS		; is it PostScript ?
		cmp	al, PS_PDL
		jne	scaleY

		; we add top margin for PDL because postscript printers start
		; printing from the top edge of the paper.  this is usually
		; not a problem, because we normally don't create bitmaps when
		; printing to postscript printers.  but now we may create a
		; bitmap even when printing to postscript if we are printing
		; faxes (Tiramisu). - Joon (1/23/96) (7/16/96)

		add	dx, paperInfo.PSR_margins.PCMP_top
scaleY:
		movwwf	bxax, curJob.SJI_pYscale
		call	GrMulWWFixed		; do multiply
		shl	cx, 1			; round appropriately
		adc	dx, 0
		clr	cx
		movdw	curJob.SJI_pageH, cxdx	; save entire page height

		; if entire page fits in one swath, make it so. Else
		; ensure the swath height allows for an integral # of bands.

		cmp	dx, curJob.SJI_swathH	; see if the whole page fits
		jae	done
		mov	ax,dx			;page height in ax....
		mov	cx, curJob.SJI_bandH	; get the height of a band
		clr	dx			;see how many bands in a page
		div	cx
		tst	ax			;must be at least 1.
		jnz	numBandsOK
		inc	ax			;hand set to 1 band.
numBandsOK:
		mul	cx			;now multiply by the band
		mov	curJob.SJI_swathH, ax	;knock off a bandheight
done:
		.leave
		ret

		; the driver says it's 4-, 8- or 24-bit.  This will happen
		; very infrequently (there are no devices that fit this bill
		; yet)
doWierdColor:
		cmp	al, BMF_8BIT		; if 8-bit, then we're done
		je	haveScanSize
		cmp	al, BMF_24BIT		; if 24-bit, easy
		jne	calc4Bit		;  else do 4-bit
		mov	dx, cx
		shl	cx, 1
		add	cx, dx
		jmp	haveScanSize
calc4Bit:
		add	cx, 1
		shr	cx, 1
		jmp	haveScanSize

		; handle divisor "overflow" by halving both the divisor
		; and the quotient. Eventually this will work :)
divisorTooBig:
		shrdw	bxcx
		shrdw	dxax
		jmp	calcBandsPerSwath
CalcPageSizeInfo endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessStartPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a DR_PRINT_START_PAGE to the printer driver

CALLED BY:	UTILITY

PASS:		inherits SpoolJobInfo

RETURN:		Carry	= Set if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessStartPage	proc	far
		uses	bx, cx, di
curJob		local	SpoolJobInfo
		.enter	inherit
	
		; Pass on the form-feed flag, and start the page
		;
		mov	cl, C_FF		; assume a form-feed
		test	curJob.SJI_printState, mask SPS_FORM_FEED
		jnz	sendStartPage
		clr	cl
sendStartPage:
		mov	di, DR_PRINT_START_PAGE	; set the code
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver	; call the driver
		jnc	done
		call	StoppedByError
done:
		.leave
		ret
ProcessStartPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessEndPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a DR_PRINT_END_PAGE

CALLED BY:	UTILITY

PASS:		inherits SpoolJobInfo
		AX	= GSRetType
		BX	= Data corresponding to GSRetType

RETURN:		AX	= GSRetType for page
		Carry	= Set if error

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProcessEndPage	proc	far
		uses	bx, cx, dx, di
curJob		local	SpoolJobInfo
		.enter	inherit
	
		; We need to determine if a form feed should be issued or
		; not. As the page has been played, we've stopped on a
		; GSRT_NEW_PAGE, GSRT_FAULT, or GSRT_COMPLETE. If it's a
		; new page, issue the end of page with the corresponding
		; data stored with the GR_NEW_PAGE, passed into this routine.
		;
		or	curJob.SJI_printState, mask SPS_FORM_FEED
		mov	cl, C_FF		; assume form feed
		cmp	ax, GSRT_NEW_PAGE
		jne	sendEndPage

		; See what the next opcode is, so that we may know if
		; we are at the end of the GString. This is highly
		; inefficient, so we'll eventually want to change
		; things so a GString is created once and then destroyed.
		;
		push	bx, cx
		mov	al, FILE_POS_RELATIVE
		mov	bx, curJob.SJI_fHan	; bx <- gstring file handle
		clr	cx, dx
		call	FilePos			; dx:ax <- start of page
		pushdw	dxax

		mov	cx, GST_STREAM		; type of gstring it is
		call	GrLoadGString		; si = string handle
		mov	di, curJob.SJI_gstate
		mov	dx, mask GSC_ONE	; just play GR_NEW_PAGE
		call	GrDrawGStringAtCP
		mov_tr	ax, dx			; ax <- GSRetType
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString

		popdw	cxdx			; cx:dx <- start of page
		push	ax
		mov	al, FILE_POS_START
		call	FilePos			; restore the file position
		pop	ax			; ax <- GSRetType
		pop	bx, cx
		
		cmp	bl, PEC_FORM_FEED
		je	sendEndPage
		clr	cl			; set flag for no FF
		and	curJob.SJI_printState, not (mask SPS_FORM_FEED)
sendEndPage:
		push	ax			; save GSRetType
		mov	di, DR_PRINT_END_PAGE
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver
		pop	ax			; restore GSRetType
		jnc	done
		call	StoppedByError
done:
		.leave
		ret
ProcessEndPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitPrinterDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	All done, so let printer driver know

CALLED BY:	INTERNAL
		PrintFile

PASS:		inherits the SpoolJobInfo frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If the job is in SUPRESS_FF mode then send a real form feed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExitPrinterDriver proc	near
		uses	ax, bx, cx, di, si, ds, es
curJob		local	SpoolJobInfo
		.enter	inherit

		; call the document end function

		mov	bx, curJob.SJI_pstate	; set up handle to PState
		mov	di, DR_PRINT_END_JOB
		call	curJob.SJI_pDriver

		; write the printer-specific data stored in the JobParameters
		; tacked onto the end of the PState back to the queue, just
		; in case the printer driver changed the data

		call	LockQueue		; lock it down
		mov	es, ax			; ds -> queue
		mov	di, curJob.SJI_qHan	; get chunk handle of queue
		mov	di, es:[di]		; deref chunk handle
		mov	di, es:[di].QI_curJob	; get next job on list
		mov	di, es:[di]		; dereference the job chunk
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		mov	cx, ds:[PS_jobParams+(offset JP_size)]
EC <		cmp	cx, es:[di].JIS_info.JP_size			>
EC <		ERROR_NE SPOOL_JOB_PARAMETER_SIZES_MUST_MATCH		>
		sub	cx, (size JobParameters) - (size JP_printerData)
		mov	si, (offset PS_jobParams) + (offset JP_printerData)
		add	di, JIS_info.JP_printerData
		rep	movsb			; copy the data back
		call	MemUnlock		; unlock the PState
		call	UnlockQueue		; all done with queue

		.leave
		ret
ExitPrinterDriver endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartTiramisuPrintingIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tiramisu printing - Print faxes in a user-storage efficient
		manner.  If the first gstring element is a GR_ESCAPE, then
		we are doing tiramisu printing.  Setup variables for Tiramisu.

CALLED BY:	PrintFile
PASS:		curJob on stack
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartTiramisuPrintingIfNeeded	proc	near
curJob		local	SpoolJobInfo
		uses	ax,bx,cx,dx,si,di,ds
		.enter	inherit

	;
	; Check if first non-GR_COMMENT gstring element is a GR_ESCAPE.
	;
		call	FilePushDir		; save current directory

		mov	bx, curJob.SJI_fHan	; bx gets file handle
		mov	cx, GST_STREAM		; type of gstring it is
		call	GrLoadGString		; si = string handle
getElement:
		clr	cx, di			; no gstate
		call	GrGetGStringElement	; al = opcode, cx = size

		cmp	al, GR_COMMENT		; is it a GR_COMMENT
		jne	gotElement

		mov	al, GSSPT_SKIP_1
		call	GrSetGStringPos
		jmp	getElement
gotElement:
		sub	sp, cx			; cx = element size on stack
		mov	bx, sp
		segmov	ds, ss			; ds:bx = SpoolSwathEscapeData

		call	GrGetGStringElement

		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString	; destroy the gstring

		cmp	al, GR_ESCAPE		; is it a GR_ESCAPE
		clc				; not an error, not Tiramisu
		jne	fixupStack		; no, then just fixup stack

		cmp	ds:[bx].OE_escCode, GR_SPOOL_SWATH_LIBRARY_ESCAPE
		clc				; not an error, not Tiramisu
		jne	fixupStack		; no, then just fixup stack

		add	bx, size OpEscape	; ds:bx = SpoolSwathEscapeData
		mov	di, bx			; ds:di = SpoolSwathEscapeData
	;
	; Load the swath library.
	;
		mov	ax, ds:[di].SSE_libDisk	; ax = libDisk (StandardPath)
		call	FileSetStandardPath
		mov	ax, SERROR_NO_PRINT_DRIVER
		jc	fixupStack		; error, then just fixup stack

		lea	si, ds:[di].SSE_libPath	; ds:si = libPath
		clr	ax, bx			; don't care about protocol #'s
		call	GeodeUseLibrary
		mov	ax, SERROR_NO_PRINT_DRIVER
		jc	fixupStack		; error, then just fixup stack

		mov	curJob.SJI_tiramisu.TP_libHandle, bx
	;
	; Setup entry points for Tiramisu printing.
	;
		push	bx
		mov	ax, ds:[di].SSE_fetchSwath
		call	ProcGetLibraryEntry
		movdw	curJob.SJI_tiramisu.TP_fetchSwath, bxax
		pop	bx

		push	bx
		mov	ax, ds:[di].SSE_endJob
		call	ProcGetLibraryEntry
		movdw	curJob.SJI_tiramisu.TP_endJob, bxax
		pop	bx
		
		mov	ax, ds:[di].SSE_startJob
		call	ProcGetLibraryEntry
		movdw	curJob.SJI_tiramisu.TP_startJob, bxax
	;
	; Call the startJob entry point.  Already in bx:ax.
	;
		push	cx			; save GR_ESCAPE data size
		mov	cx, ds
		lea	dx, ds:[di].SSE_data	; cx:dx = data to pass
		call	ProcCallFixedOrMovable	; ax = SpoolError
		pop	cx			; restore GR_ESCAPE data size
		jnc	goTiramisu

		mov	bx, curJob.SJI_tiramisu.TP_libHandle
		call	GeodeFreeLibrary	; free the swath library
		stc				; note error
		jmp	fixupStack

goTiramisu:
		mov	curJob.SJI_tiramisu.TP_jobToken, si
		ornf	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING

fixupStack:
	;
	; Remove SpoolSwathEscapeData allocated on stack.
	;
		mov	di, ax			; di = SpoolError
		lahf
		add	sp, cx			; remove GR_ESCAPE data
		sahf
	;
	; Set the file position back to start of page and reset directory.
	;
		pushf
		call	ResetFilePosition	; set to start o page
		call	FilePopDir
		popf
		jnc	done			; done if no errors
	;
	; Something went wrong when we tried to start fax printing.
	;
		mov	cx, di			; cx = SpoolError
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox		; put up an error
		call	StoppedByError		; record our exit
done:
		.leave
		ret
StartTiramisuPrintingIfNeeded	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TiramisuGetResolution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the x and y res to be that of the fax.

CALLED BY:	CalcPageSizeInfo

PASS:		curJob on the stack
RETURN:		dx	= x res
		cx 	= y res
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	10/10/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TiramisuGetResolution	proc	near
		curJob		local	SpoolJobInfo
		uses	ax, bx, es
		.enter inherit	
	;
	; Get the resolutions for this print job.
	;
		mov	bx, curJob.SJI_tiramisu.TP_jobToken	; bx <-handle
		call	MemLock			; ax <- set of cbitmap
		mov	es, ax
		mov 	dx, es:[FCB_faxXres]	; dx <- xres
		mov	cx, es:[FCB_faxYres]	; cx <- yres		
		call	MemUnlock
		.leave
		ret
TiramisuGetResolution	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EndTiramisuPrintingIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we were doing Tiramisu printing, then unload the swath
		library.

CALLED BY:	PrintFile
PASS:		curJob on stack
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	12/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EndTiramisuPrintingIfNeeded	proc	near
curJob		local	SpoolJobInfo
		uses	ax, bx, si
		.enter	inherit

		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jz	done

		mov	si, curJob.SJI_tiramisu.TP_jobToken
		movdw	bxax, curJob.SJI_tiramisu.TP_endJob
		call	ProcCallFixedOrMovable

		mov	bx, curJob.SJI_tiramisu.TP_libHandle
		call	GeodeFreeLibrary
done:
		.leave
		ret
EndTiramisuPrintingIfNeeded	endp

PrintThread	ends
