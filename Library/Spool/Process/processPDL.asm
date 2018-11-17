COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processPDL.asm

AUTHOR:		Jim DeFrisco, 13 Feb 1991

ROUTINES:
	Name			Description
	----			-----------
	DoPDLInit		Do any init required of PDL printers
	PrintPDLPage		Print a page
	DoPDLCleanup		Do any cleanup required of PDL printers

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/91		Initial revision


DESCRIPTION:
	This file contains routines to handle page description language printing
		

	$Id: processPDL.asm,v 1.1 97/04/07 11:11:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintPDL	segment	resource

if	_PDL_PRINTING


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPDLInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization to print a PDL page

CALLED BY:	INTERNAL
		PrintDocument 

PASS:		inherits lots of local variables from SpoolerLoop

RETURN:		ax	- error flag -  0	 = no error
					non-zero = unrecoverable error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoPDLInit proc	far
		uses	di
curJob		local	SpoolJobInfo
		.enter	inherit

		clr	di			; no associated window
		call	GrCreateState		; create a bogus gstate that
						; we can use to keep track of
						; the current transformation
		mov	curJob.SJI_gstate, di	; save the GState handle

		; another thing we need to do is to communicate the various
		; parameters about the job to the printer driver.  This is 
		; done via the DR_PRINT_SET_JOB_INFO call

		clr	ax			; no error


		.leave
		ret
DoPDLInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPDLCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup from PDL printing

CALLED BY:	EXTERNAL
		PrintDocument

PASS:		stuff in curJob stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoPDLCleanup proc	far
		uses	di
curJob		local	SpoolJobInfo
		.enter	inherit

		mov	di, curJob.SJI_gstate	; save the GState handle
		call	GrDestroyState		; don't need it anymore

		.leave
		ret
DoPDLCleanup endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintPDLPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print out a single page in graphics mode

CALLED BY:	INTERNAL
		DoPDLPrinting

PASS:		inherits stack frame

RETURN:		ax	- code returned from DrawString

DESTROYED:	just about everything

PSEUDO CODE/STRATEGY:
		handle the printing of a single page (of paper, not a page
		of the document)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintPDLPage proc	far
curJob		local	SpoolJobInfo
		.enter	inherit

		; set the default transformation matrix.  This was determined
		; by CalcDocOrientation, and handles the automatic rotation
		; of documents to fit on the paper better.

		mov     di, curJob.SJI_gstate	; get bogus gstate handle
		segmov	ds, ss, si
		lea	si, curJob.SJI_defMatrix	; set it from here
		call	GrApplyTransform		; set the TMatrix

		; the code from here on down is responsible for the printing
		; of a single DOCUMENT page (as opposed to just a PAPER page).
		; That means we have to deal with tiling the output if the
		; document is larger than will fit on a single piece of paper.
		; We print across, then down, so handle the y loop on the 
		; outside and the xloop on the inside.

		mov	cx, curJob.SJI_yPages		; init y loop variable
		mov	curJob.SJI_curyPage, cx
tileInY:
		segmov	ds, ss, si			; ds -> stack
		lea	si, curJob.SJI_yloopTM		; ds:si->buffer space
		mov	di, curJob.SJI_gstate		; window handle
		call	GrGetTransform			; save current TMatrix
		mov	cx, curJob.SJI_xPages		; init #pages across
		mov	curJob.SJI_curxPage, cx

		; next we implement the loop to tile across.  Like the y loop
		; we need to keep track of the current TM
tileInX:
		call	BumpPhysPageNumber
		segmov	ds, ss, si			; ds -> stack
		lea	si, curJob.SJI_xloopTM		; ds:si->buffer space
		mov	di, curJob.SJI_gstate		; window handle
		call	GrGetTransform			; save current TMatrix

		; let the printer know we're starting a page

		call	ProcessStartPage		; send START_PAGE
		jnc	setTransform
		mov	ax, GSRT_FAULT			; make like something
		jmp	doneDocPage			;  bad happened

		; set up the transformation for this page
setTransform:
		mov	di, curJob.SJI_gstate		; grab the current
		segmov	ds, ss, si			;  tmatrix
		lea	si, curJob.SJI_oldMatrix
		call	GrGetTransform

		mov	di, DR_PRINT_ESC_SET_PAGE_TRANSFORM	; set the xform
		mov	dx, ds				; dx:si -> transform
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver		; call the driver
		jnc	loadGString
exitErr:
		mov	ax, GSRT_FAULT			; make like something
		jmp	doneDocPage			;  bad happened

		; the file is already open, associate it with a graphics
		; string handle
loadGString:
		mov	cx, GST_STREAM		; type of gstring it is
		mov	bx, curJob.SJI_fHan	; bx gets file handle
		call	GrLoadGString		; si = string handle
		mov	curJob.SJI_gstring, si	; store the handle

		; now draw the document

		mov	di, DR_PRINT_ESC_PRINT_GSTRING	; the big one
		mov	bx, curJob.SJI_pstate		; pass the pstate
		mov	cx, mask GSC_NEW_PAGE
		call	curJob.SJI_pDriver		; print it
		jc	exitErr

		; this swath is done, destroy the string so we can start it
		; up again.  Eventually, we should be able to do a 
		; GrSetGStringPos to re-init the gstring code, but until release
		; two...

		clr	di
		mov	dl, GSKT_LEAVE_DATA	; don't try to kill the data
		call	GrDestroyGString	; si = string handle

		; check queue info to see if we need to quit
		
		push	ax			; save GSRetType
		call	CheckForErrors		; check flag in q info
		pop	ax			; restore GSRetType
		jnc	donePage		;  yes, abort the job
		mov	ax, GSRT_FAULT

		; done with a page
donePage:
		call	ProcessEndPage
		jnc	checkFault		; if no problem, continue
		mov	ax, GSRT_FAULT		; else there's a problem

		; see if we REALLY need to quit (some fault).  Otherwise 
		; handle the tiling stuff
checkFault:
		cmp	ax, GSRT_FAULT			; done ?
		LONG je	doneDocPage			;  yes, all done

		; handle printing the next page to the right for tiled output
		; the xloop is on the inside, so do that one first

		sub	curJob.SJI_curxPage, 1		; one less page to do
		jle	nextPassAcross			; finished this swoosh

		; set the file position back to start of page

		mov	al, FILE_POS_START
		mov	bx, curJob.SJI_fHan		; fetch file handle
		mov	dx, {word} curJob.SJI_fPos	;  and postion
		mov	cx, {word} curJob.SJI_fPos+2
		call	FilePos				; set to start o page

		; still have more to do across a swoosh (this is a technical
		; term describing one pass of "pages" across the document ;)
		; if we're at the left edge and going to the first page to the
		; right, then translate by the right margin, since that is 
		; actually where the right edge of the doucment ended up 
		; but on any other page, we want to translate by just the 
		; width of the printable area with is (right-left)

		mov	di, curJob.SJI_gstate		; reset old TMatrix
		segmov	ds, ss, si			;  tmatrix
		lea	si, curJob.SJI_xloopTM
		call	GrSetTransform

		; assume tiling upright, but check rotated case

		mov	dx, curJob.SJI_printWidth	; translate this much
		neg	dx
		clr	cx
		clr	bx
		clr	ax
		test	curJob.SJI_printState, mask SPS_ROTATED 
		jz	applyXTrans
		xchg	dx, bx				; swap amounts if so
applyXTrans:
		call	GrApplyTranslation		; DONT_INVAL still ok
		call	AskForNextPDLPage
		cmp	ax, IC_DISMISS			; only happens if we're
		je	exitErr2			;  shutting down...
		jmp	tileInX				; more of swoosh to do 

nextPassAcross:
		sub	curJob.SJI_curyPage, 1		; one less page to do
		jle	doneDocPage			; all done with doc pg

		; set the file position back to start of page

		mov	al, FILE_POS_START
		mov	bx, curJob.SJI_fHan		; fetch file handle
		mov	dx, {word} curJob.SJI_fPos	;  and postion
		mov	cx, {word} curJob.SJI_fPos+2
		call	FilePos				; set to start o page

		; still have more swooshes to do 

		mov	di, curJob.SJI_gstate		; reset old TMatrix
		segmov	ds, ss, si			;  tmatrix
		lea	si, curJob.SJI_yloopTM
		call	GrSetTransform

		mov	bx, curJob.SJI_printHeight	; translate this much
		neg	bx
		clr	ax
		clr	dx
		clr	cx
		test	curJob.SJI_printState, mask SPS_ROTATED 
		jz	applyYTrans
		xchg	dx, bx				; swap amounts if so
applyYTrans:
		call	GrApplyTranslation		; DONT_INVAL still ok
		call	AskForNextPDLPage
		cmp	ax, IC_DISMISS			; only happens if we're
		je	exitErr2			;  shutting down...
		jmp	tileInY				; do another swoosh

doneDocPage:
		cmp	ax, GSRT_FAULT
		jne	exitNoNotify
		
		; don't put up error box if this GSRT_FAULT is due to either
		; user abort or system shutdown.
		call	CheckForErrors			; al=SpoolInterruptions
		cmp	al, SI_ABORT
		je	exitNoNotifyFault
		cmp	al, SI_DETACH
		je	exitNoNotifyFault

		; let user know we encountered an error, rather than just
		; silently swallowing the job.

		mov	cx, SERROR_CANNOT_CONVERT_PAGE
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox
		
exitNoNotifyFault:		
		mov	ax, GSRT_FAULT

exitNoNotify:
		mov	di, curJob.SJI_gstate		; get gstate handle
		call	GrSetNullTransform		; set it back
		.leave
		ret
exitErr2:
		mov	ax, GSRT_FAULT			; make like something
		jmp	exitNoNotify
PrintPDLPage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AskForNextPDLPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask for the next piece of paper for manual feed, if needed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check manual feed flag and do the right thing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AskForNextPDLPage	proc	near
curJob		local	SpoolJobInfo
		.enter	inherit

		push	ds
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		test	ds:[PS_paperInput], mask PIO_MANUAL
		call	MemUnlock			; (preserves flags)
		pop	ds
		jz	done				;  no, auto-fed paper

		; we have a manual feed situation.  Ask the user to stick
		; another piece (but nicely)

		mov	cx, SERROR_MANUAL_PAPER_FEED	; ask him for next piece
		clr	dx
		call	SpoolErrorBox			; he can only answer OK
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
done:
		.leave
		ret
AskForNextPDLPage	endp

endif	;_PDL_PRINTING

PrintPDL	ends

