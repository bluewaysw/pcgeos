COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processGraphics.asm

AUTHOR:		Jim DeFrisco, 28 March 1990

ROUTINES:
	Name			Description
	----			-----------
	DoGraphicsPrinting	Handles printing in graphics modes

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/28/90		Initial revision


DESCRIPTION:
	This file contains routines to handle graphics printing
		

	$Id: processGraphics.asm,v 1.1 97/04/07 11:11:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintGraphics	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoGraphicsInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization to print a graphics page

CALLED BY:	INTERNAL
		PrintDocument 

PASS:		inherits lots of local variables from SpoolerLoop

RETURN:		ax	- error flag -  0	 = no error
					non-zero = unrecoverable error

DESTROYED:	just about everything

PSEUDO CODE/STRATEGY:
		Allocate a bitmap;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CREATE_BM_FLAGS equ <mask BMC_GSTATE or mask BMC_WINDOW or mask BMC_INIT_FILL or mask BMC_OD>

DoGraphicsInit proc	far
curJob		local	SpoolJobInfo
		.enter	inherit

		; printer is all initialized (in PrintFile) so create bitmap
		;  first, make sure our file is there...

		call	FilePushDir			; save dir state
		mov	ax, SP_SPOOL			; go to spool directory
		call	FileSetStandardPath
		call	CreateBitmapFile		; create unique file
		call	FilePopDir			; restore directory
		LONG jc	exit				; couldn't create
		
		mov	cx, curJob.SJI_bandW		; get width
		mov	dx, curJob.SJI_swathH		; get height
		mov     al, curJob.SJI_colorFormat	; get color mode
		call	GeodeGetProcessHandle
		mov	di, bx
		mov	bx, curJob.SJI_bmFileHan	; get vm file handle
		call    GrCreateBitmap                  ; 
		mov     curJob.SJI_bmHan, ax            ; save bm han for later

		mov	curJob.SJI_gstate, di		; save gstate han
		call	GrGetWinHandle			; ax = window handle
		mov	curJob.SJI_bmWinHan, ax		; save it

		mov	dx, curJob.SJI_colorCorrection
		mov	ax, mask BM_CLUSTERED_DITHER	; use clustered mode
		call	GrSetBitmapMode			; set clustered dither

		; We set the bitmap res to be that of the fax if tiramisu
		; and postscipt.
		
		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jz	beginUpdate

		; Check to see if postscript.
		
		push	ax	
		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS		; is it PostScript ?
		cmp	al, PS_PDL
		pop	ax
		jne	beginUpdate			; no, begin update

		
		push	ax, bx, di
		mov	ax, curJob.SJI_pXres
		mov	bx, curJob.SJI_pYres
		mov	di, curJob.SJI_gstate
		call	GrSetBitmapRes
		pop	ax, bx, di
		

		; at this point, the window is invalid, since WinOpen (via
		; GrCreateBitmap) creates it that way.  This is bad, since 
		; we're not going to get any MSG_META_EXPOSED for it (not being
		; a real process).  So lets fake an update now.
beginUpdate::
		call	GrBeginUpdate			; start it
		call	GrEndUpdate			; end it
		clr	ax				; signal no error

if _DUAL_THREADED_PRINTING
		mov	cx, curJob.SJI_bandW		; get width
		mov	dx, curJob.SJI_swathH		; get height
		mov     al, curJob.SJI_colorFormat	; get color mode
		call	GeodeGetProcessHandle
		mov	di, bx
		mov	bx, curJob.SJI_bmFileHan	; get vm file handle
		call    GrCreateBitmap                  ; 
		mov     curJob.SJI_bmHan2, ax		; save bm han for later
		mov	curJob.SJI_gstate2, di		; save gstate han
		call	GrGetWinHandle			; ax = window handle
		mov	curJob.SJI_bmWinHan2, ax	; save it

		mov	dx, curJob.SJI_colorCorrection
		mov	ax, mask BM_CLUSTERED_DITHER	; use clustered mode
		call	GrSetBitmapMode			; set clustered dither

		; at this point, the window is invalid, since WinOpen (via
		; GrCreateBitmap) creates it that way.  This is bad, since 
		; we're not going to get any MSG_META_EXPOSED for it (not being
		; a real process).  So lets fake an update now.

		call	GrBeginUpdate			; start it
		call	GrEndUpdate			; end it
		clr	ax				; signal no error
endif	; _DUAL_THREADED_PRINTING

exit:
		.leave
		ret

DoGraphicsInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateBitmapFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a unique file for the bitmap

CALLED BY:	INTERNAL
		DoGraphicsInit
PASS:		curJob	- inherited stack frame
RETURN:		carry	- clear (file was successfully created)
			- or -
		carry	- set (file was not created)
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/10/93		Initial version
	don	3/ 9/94		Added setting of VMAttributes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; VMA_SINGLE_THREAD_ACCESS will speed up VMLock, since no check for
; 	multiple locking threads will need to occur.
; VMA_SYNC_UPDATE essentially forces the bitmap data to never be written
;	to the disk, since VMUpdate is never called.

if	_DISK_SPACE_OPTS
SPOOL_FILE_VM_ATTRS	equ	mask VMA_SINGLE_THREAD_ACCESS or \
				mask VMA_SYNC_UPDATE
else
SPOOL_FILE_VM_ATTRS	equ	mask VMA_SINGLE_THREAD_ACCESS
endif

CreateBitmapFile proc	near
		uses	ds
curJob		local	SpoolJobInfo
		.enter	inherit

		; first copy over the template name

		mov	curJob.SJI_bmFileName[0], 0	; make it empty so
							;  VMOpen creates it
							;  in the current dir
		segmov	ds, ss
		lea	dx, curJob.SJI_bmFileName	; ds:dx -> filename
							;  buffer
 		mov	ax, (VMO_TEMP_FILE shl 8) or \
 			    mask VMAF_FORCE_READ_WRITE or \
			    mask VMAF_FORCE_DENY_WRITE or \
			    mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION
 		clr	cx				; default compression
		call	VMOpen
		jc	done

		; set the VM attributes, if the file was created

		mov	curJob.SJI_bmFileHan, bx	; save file handle
		mov	ax, SPOOL_FILE_VM_ATTRS
		call	VMSetAttributes			; new attrs -> al
EC <		cmp	al, SPOOL_FILE_VM_ATTRS		; verify attrs	>
EC <		ERROR_NE SPOOL_BAD_VM_FILE_ATTRS			>
		clc					; indicate success
done:
		.leave
		ret
CreateBitmapFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoGraphicsCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleanup from graphics printing

CALLED BY:	EXTERNAL
		PrintDocument

PASS:		stuff in curJob stack frame

RETURN:		nothing

DESTROYED:	di,al, dx

PSEUDO CODE/STRATEGY:
		free the bitmap/gstate/window we allocated

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoGraphicsCleanup proc	far
		uses	ds
curJob		local	SpoolJobInfo
		.enter	inherit

		;  check for smart device here.  don't destroy the bitmap,
		; since we didn't create one.  Perhaps call a driver cleanup
		; function...

		mov     di, curJob.SJI_gstate           ; setup to kill bitmap
		mov     al, BMD_LEAVE_DATA		; we're gonna kill the
		call    GrDestroyBitmap			;  file anyway

if _DUAL_THREADED_PRINTING
		mov	di, curJob.SJI_gstate2		; setup to kill bitmap
		mov	al, BMD_LEAVE_DATA		; we're gonna kill the
		call	GrDestroyBitmap			;  file anyway
endif	; _DUAL_THREADED_PRINTING

		mov	bx, curJob.SJI_bmFileHan	; fetch vm file handle
		mov	al, FILE_NO_ERRORS
 		call	VMClose				; close it, then...

		; nuke the file we created for the bitmap

		call	FilePushDir			; save dir state
		mov	ax, SP_SPOOL			; go to spool directory
		call	FileSetStandardPath
		segmov	ds, ss
		lea	dx, curJob.SJI_bmFileName	; ds:dx -> filename
		call	FileDelete			;  ..nuke it
		call	FilePopDir			; restore dir

		.leave
		ret
DoGraphicsCleanup endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintGraphicsPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print out a single page in graphics mode

CALLED BY:	INTERNAL
		DoGraphicsPrinting

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

PrintGraphicsPage proc	far
curJob		local	SpoolJobInfo
		.enter	inherit

if	_LABELS
		; if printing labels, use a different approach.

		test	curJob.SJI_info.JP_paperSizeInfo.PSR_layout, PT_LABEL
		jz	printPage

		call	PrintGraphicsLabels
		.leave
		ret
endif

printPage::

if (0)		; if 0'd for now because GrGetGStringBounds takes an eternity.
		; Figure out the bounds of the page so we can skip over
		; white space at the bottom of the page.

		mov	cx, GST_STREAM			; type of gstring it is
		mov	bx, curJob.SJI_fHan		; bx gets file handle
		call	GrLoadGString			; si = string handle

		clr	di				; no gstate
		mov	dx, mask GSC_NEW_PAGE		; stop at end of page
		call	GrGetGStringBounds
		jc	noBounds

		movdw	bxax, curJob.SJI_pYscale	; bx.ax = y scale
		clr	cx				; dx.cx = 72dpi yoffset
		call	GrMulWWFixed			; dx.cx = 300dpi yoffst
		inc	dx				; in case cx <> 0
		cmp	curJob.SJI_pageH.low, dx	; is it smaller?
		jb	noBounds
		mov	curJob.SJI_pageH.low, dx	; new page height
noBounds:
		mov	dl, GSKT_LEAVE_DATA		; don't kill the data
		call	GrDestroyGString		; si = string handle

		; set the file position back to start of page

		call	ResetFilePosition		; set to start o page
endif

		; starting with a fresh transformation matrix, so apply 
		; our stuff to fit output to the printer resolution

		mov     di, curJob.SJI_bmWinHan         ; get win handle in di

	; Don't scale the window if tiramisu, postscript, and the
	; first page.  That's because the window's scale gets set during
	; graphics init, but gets cleared out after every page.

		mov	al, curJob.SJI_printState	; check for PDL printer
		and	al, mask SPS_SMARTS		; is it PostScript ?
		cmp	al, PS_PDL
		jne	applyScale			; no, apply scale
		
		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jz	applyScale

		call	GetPageNumber		; cx <- zero-based page number
		jcxz   	setDefaultMatrix
		
applyScale:
		movwwf	dxcx, curJob.SJI_pXscale	; set up xscale factor
		movwwf	bxax, curJob.SJI_pYscale	; set up yscale factor
		mov     si, WIF_DONT_INVALIDATE         ; don't force a redraw
		call    WinApplyScale                   ; 

if _DUAL_THREADED_PRINTING
		push	di
		mov	di, curJob.SJI_bmWinHan2	; get win handle in di
		call	WinApplyScale			;
		pop	di
endif	; _DUAL_THREADED_PRINTING

		; set the default transformation matrix.  This was determined
		; by CalcDocOrientation, and handles the automatic rotation
		; of documents to fit on the paper better.
setDefaultMatrix:
		segmov	ds, ss, si
		lea	si, curJob.SJI_defMatrix	; set it from here
		mov     cx, WIF_DONT_INVALIDATE         ; don't force a redraw
		call	WinApplyTransform		; set the TMatrix

if _DUAL_THREADED_PRINTING
		mov	di, curJob.SJI_bmWinHan2	; get win handle in di
		call	WinApplyTransform		; set the TMatrix

		lea	si, curJob.SJI_oldMatrix	; ds:si->buffer space
		mov	di, curJob.SJI_bmWinHan2	; window handle
		call	WinGetTransform			; get old TMatrix
		mov	cx, WIF_DONT_INVALIDATE
		call	WinSetNullTransform		; set things back

		mov	bx, curJob.SJI_swathH		; translate this much
		clr	ax				; ax = x translation
		call	TranslateThePage		; DONT_INVAL still ok
		mov	cx, WIF_DONT_INVALIDATE
		lea	si, curJob.SJI_oldMatrix	; ds:si->buffer space
		call	WinApplyTransform		; apply old one
endif	; _DUAL_THREADED_PRINTING

		; the code from here on down is responsible for the printing
		; of a single DOCUMENT page (as opposed to just a PAPER page).
		; That means we have to deal with tiling the output if the
		; document is larger than will fit on a single piece of paper.
		; We print across, then down, so handle the y loop on the 
		; outside and the xloop on the inside.
		mov	cx, curJob.SJI_yPages		; init y loop variable
		mov	curJob.SJI_curyPage, cx
tileInY:
		lea	si, curJob.SJI_yloopTM		; ds:si->buffer space
		call	GetOurTransformation		; save current TMatrix

if _DUAL_THREADED_PRINTING
		; Save TMatrix for other bitmap window
		push	curJob.SJI_bmWinHan		; save SJI_bmWinHan
		mov	si, curJob.SJI_bmWinHan2	; si <- bmWinHan2
		mov	curJob.SJI_bmWinHan, si		; bmWinHan = bmWinHan2
		lea	si, curJob.SJI_yloopTM2		; ds:si->buffer space
		call	GetOurTransformation		; save current TMatrix
		pop	curJob.SJI_bmWinHan		; restore SJI_bmWinHan
endif	; _DUAL_THREADED_PRINTING

		mov	cx, curJob.SJI_xPages		; init #pages across
		mov	curJob.SJI_curxPage, cx

		; next we implement the loop to tile across.  Like the y loop
		; we need to keep track of the current TM
tileInX:
		call	BumpPhysPageNumber
		segmov	ds, ss, si			; ds -> stack
		lea	si, curJob.SJI_xloopTM		; ds:si->buffer space
		call	GetOurTransformation		; save current TMatrix

if _DUAL_THREADED_PRINTING
		; Save TMatrix for other bitmap window
		push	curJob.SJI_bmWinHan		; save SJI_bmWinHan
		mov	si, curJob.SJI_bmWinHan2	; si <- bmWinHan2
		mov	curJob.SJI_bmWinHan, si		; bmWinHan = bmWinHan2
		lea	si, curJob.SJI_xloopTM2		; ds:si->buffer space
		call	GetOurTransformation		; save current TMatrix
		pop	curJob.SJI_bmWinHan		; restore SJI_bmWinHan
endif	; _DUAL_THREADED_PRINTING

		; let the printer know we're starting a page

if _NONSPOOL	;--------------------------------------------------------------
		push	ds
		mov	bx, curJob.SJI_pstate
		call	MemLock
		mov	ds, ax
		test	ds:[PS_paperInput], mask PIO_MANUAL
		call	MemUnlock			; (preserves flags)
		pop	ds
		jz	startPage			; no, auto-fed paper
checkPaper::
		mov	di, DR_PRINT_ESC_WAIT_FOR_MECH	; wait for print engine
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver

		mov	di, DR_PRINT_ESC_GET_ERRORS	; set the code
		mov	al, PJLP_noupdate
		call	curJob.SJI_pDriver		; call the driver
		test	al, mask PER_MPE		; paper present?
		jnz	askForPaper
startPage:
		call	ProcessStartPage

		; This should load a sheet of paper, and now we will test for
		; errors on the load.

		call	GetPrinterReturnCode
		cmp	ax, PDR_PAPER_JAM_OR_EMPTY	; jammed or empty?
		jne	startSwathes			; if not, let er rip...
askForPaper:
		call	NonSpoolPaperFeedBox
		cmp	ax, IC_OK
		je	startPage			; start page
		jmp	shutdownHere			; else shutdown

else	; not _NONSPOOL -------------------------------------------------------

		call	ProcessStartPage
		jnc	startSwathes			;  check for errors
		mov	ax, GSRT_FAULT			; make like something
		jmp	doneDocPage			;  bad happened

endif		; _NONSPOOL ---------------------------------------------------

		; set whatever page-bound variables we need to
startSwathes:
		movdw	curJob.SJI_curScan, 0		; start at top of page

		; This loop draws the page over and over into each swath, 
		; and sends the swath off to be printed.  Start by re-initing
		; the bitmap.
swathLoop:
		mov	di, curJob.SJI_gstate		; get string handle
		call	GrClearBitmap			; di = bitmap gstate

		; the file is already open, associate it with a graphics
		; string handle

		mov	cx, GST_STREAM		; type of gstring it is
		mov	bx, curJob.SJI_fHan	; bx gets file handle
		call	GrLoadGString		; si = string handle
		mov	curJob.SJI_gstring, si	; store the handle

		; now draw the document

		mov	di, curJob.SJI_gstate		; get string handle

		test	curJob.SJI_printState, mask SPS_TIRAMISU_PRINTING
		jz	normal

		; Tiramisu printing: call swath library to fill bitmap.

		push	si
		mov	si, curJob.SJI_tiramisu.TP_jobToken
		movdw	bxax, curJob.SJI_tiramisu.TP_fetchSwath
		call	GetPageNumber			; cx = page number
		call	ProcCallFixedOrMovable		; call swath library
		pop	si
		jmp	postDraw

normal:		; Normal printing: call graphics system to fill bitmap.

		clr	ax				; no parameters
		clr	bx				;  draw at (0,0)
							; stop at end of page
		mov	dx, mask GSC_NEW_PAGE
		call	GrSaveState
		call	GrDrawGString			; draw the string
		call	GrRestoreState
postDraw:
		push	dx, cx				; save GSRetType & data

		; this swath is done, destroy the string so we can start it
		; up again.  

		mov	dl, GSKT_LEAVE_DATA		; don't kill the data
		call	GrDestroyGString		; si = string handle

if _NONSPOOL	;--------------------------------------------------------------

		call    SpoolLockPrintJob		; set the semaphore.

		; OK, it's built out, so send it on down to be printed

		mov	dx, curJob.SJI_bmFileHan	; pass huge arr handle
		mov	cx, curJob.SJI_bmHan		
		mov	bx, curJob.SJI_pstate		; pass the pstate
if _DUAL_THREADED_PRINTING
		call	PrintSwathNoBlocking		; print it
else
		mov	di, DR_PRINT_SWATH		; the big one
		call	curJob.SJI_pDriver		; print it
endif
		LONG jc	ejectPaper

		call	SpoolUnlockPrintJob		; reset the semaphore.

		; General check Error handling goes here.
		; Make sure things are still ok after printing a swath.

		call    SpoolProcessErrors
		LONG jc	exitErr				; catastophic error?
		cmp     ax,GSRT_FAULT			; fault?
		LONG je	ejectPaper			; yes - eject paper

else	; not _NONSPOOL -------------------------------------------------------

		; OK, it's built out, so send it on down to be printed

		mov	dx, curJob.SJI_bmFileHan	; pass huge arr handle
		mov	cx, curJob.SJI_bmHan		
		mov	bx, curJob.SJI_pstate		; pass the pstate
if _DUAL_THREADED_PRINTING
		call	PrintSwathNoBlocking		; print it
else
		mov	di, DR_PRINT_SWATH		; the big one
		call	curJob.SJI_pDriver		; print it
endif
		LONG jc	exitErr

endif		; _NONSPOOL ---------------------------------------------------


if _DUAL_THREADED_PRINTING

		; Now we need to switch the bitmaps so the printing thread
		; can use the last bitmap while we're drawing a new bitmap

		mov	ax, curJob.SJI_bmHan
		xchg	ax, curJob.SJI_bmHan2
		mov	curJob.SJI_bmHan, ax

		mov	ax, curJob.SJI_bmWinHan
		xchg	ax, curJob.SJI_bmWinHan2
		mov	curJob.SJI_bmWinHan, ax

		mov	ax, curJob.SJI_gstate
		xchg	ax, curJob.SJI_gstate2
		mov	curJob.SJI_gstate, ax

endif	; _DUAL_THREADED_PRINTING


		; see if we have more to print, update all the nice vars
		movdw	dxbx, curJob.SJI_curScan	; get current position
		add	bx, curJob.SJI_swathH		; calc new position
		adc	dx, 0
		movdw	curJob.SJI_curScan, dxbx	; update position
		cmpdw	dxbx, curJob.SJI_pageH		; done ?
		pop	ax, cx				; restore GSRetType,data
		LONG	jae	donePage		;  yes, time to reset
		push	ax, cx				; save GSRetType & data
		subdw	dxbx, curJob.SJI_pageH		; see if getting close
		negdw	dxbx
		tst	dx				; if still large
		jnz	applyTranslation
		cmp	bx, curJob.SJI_swathH		; < 1 swath left ?
		jae	applyTranslation		;  no, continue
		mov	di, curJob.SJI_gstate		; pass bitmap handle
		call	GrClearBitmap
 
 		; since we are on the last swath, make sure that the
 		; bitmap height field in the Huge bitmap reflects how
 		; much we are actually going to send to the print driver.
 
		mov	dx, bx				; save word of height
 		call	AdjustBitmapHeight

		; apply proper window translation to draw the next piece
applyTranslation:
		segmov	ds, ss, si			; ds -> stack
		lea	si, curJob.SJI_oldMatrix	; ds:si->buffer space
		mov	di, curJob.SJI_bmWinHan		; window handle
		call	WinGetTransform			; get old TMatrix
		mov	cx, WIF_DONT_INVALIDATE
		call	WinSetNullTransform		; set things back

		mov	bx, curJob.SJI_swathH		; translate this much
if _DUAL_THREADED_PRINTING
		shl	bx, 1
endif
		neg	bx				; bx = y translation
		clr	ax				; ax = x translation
		call	TranslateThePage		; DONT_INVAL still ok
		mov	cx, WIF_DONT_INVALIDATE
		lea	si, curJob.SJI_oldMatrix	; ds:si->buffer space
		call	WinApplyTransform		; apply old one

		; set the file position back to start of page

		call	ResetFilePosition		; set to start o page

		; check queue info to see if we need to quit

		call	CheckForErrors			; check flag in q info
		pop	ax, cx				; restore GSRetType,data
		jc	abortDoc			;  yes, abort the job
		cmp	ax, GSRT_FAULT			; something bad ?
		je	donePage			;  yes, die
		jmp	swathLoop			; else print next swath

		; printing interrupted
abortDoc:
		mov	ax, GSRT_FAULT			; fake completion

		; done with the current page, so tell the printer driver
donePage:

if _DUAL_THREADED_PRINTING
		call	PrintBlockOnPrintThread
endif

		mov	bx, cx
		call	ProcessEndPage

 		; since we are on the last swath, make sure that the
 		; bitmap height field in the Huge bitmap reflects how
 		; much we are actually going to send to the print driver.

		pushf					; save carry
		mov	dx, curJob.SJI_swathH		; get swath height
 		call	AdjustBitmapHeight
		popf					; restore carry status


if _DUAL_THREADED_PRINTING
		pushf					; save carry
		mov	di, curJob.SJI_bmHan2		;
		xchg	di, curJob.SJI_bmHan		; swap Bitmap handles 
		call	AdjustBitmapHeight		; adjust SJI_bmHan2
		mov	curJob.SJI_bmHan, di		; restore SJI_bmHan
		popf					; restore carry status
endif	; _DUAL_THREADED_PRINTING

if _NONSPOOL	;--------------------------------------------------------------
checkEndReturnCode:
		LONG jc	shutdownHere
		cmp	ax, GSRT_FAULT			; done ?
		LONG je	doneDocPage			;  yes, all done
		push	ax				; save GSRet code.
		call	GetPrinterReturnCode		; get returns.
		cmp	ax, PDR_NO_RETURN
		pop	ax                              ; get back GSRet code.
		je	printNextPage
		mov	cx, PERROR_PAPER_MISFEED	; set jammed error code
		clr	dx
		call	SpoolErrorBox			; he can only answer OK
		TestUserStandardDialogResponses\
		SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK			; if affirmative
		LONG 	jne shutdownHere		; if not OK, quit...
							; if OK, try again...
if _DUAL_THREADED_PRINTING
		call	PrintBlockOnPrintThread
endif
		mov	di, DR_PRINT_END_PAGE		; spit the paper out
		mov	bx, curJob.SJI_pstate		; pass the pstate
		call	curJob.SJI_pDriver
		mov	ax, GSRT_COMPLETE		; dumy GString ret code
		jmp	checkEndReturnCode

else	; not _NONSPOOL -------------------------------------------------------

		jnc	checkFault
		mov	ax, GSRT_FAULT			; there's a problem
		jmp	doneDocPage

		; see if we REALLY need to quit (some fault).  Otherwise 
		; handle the tiling stuff
checkFault:
		cmp	ax, GSRT_FAULT			; done ?
		jne	printNextPage			;  yes, all done
		jmp	doneDocPage			;  yes, all done

endif		; _NONSPOOL ---------------------------------------------------

		; handle printing the next page to the right for tiled output
		; the xloop is on the inside, so do that one first
printNextPage:
		sub	curJob.SJI_curxPage, 1		; one less page to do
		jle	nextPassAcross			; finished this swoosh

		; set the file position back to start of page

		call	ResetFilePosition		; set to start o page

		; still have more to do across a swoosh (this is a technical
		; term describing one pass of "pages" across the document ;)

		lea	si, curJob.SJI_xloopTM		; ds:si->buffer space
		call	SetOurTransformation			; apply old one

		; assume tiling upright, but check rotated case

		mov	ax, curJob.SJI_printWidth	; translate this much
		neg	ax
		clr	bx
		call	TranslateThePage		; DONT_INVAL still ok

if _DUAL_THREADED_PRINTING	; Now do the same thing for other bitmap window

		; still have more to do across a swoosh (this is a technical
		; term describing one pass of "pages" across the document ;)

		push	curJob.SJI_bmWinHan		; save SJI_bmWinHan
		mov	si, curJob.SJI_bmWinHan2	; si <- bmWinHan2
		mov	curJob.SJI_bmWinHan, si		; bmWinHan = bmWinHan2
		lea	si, curJob.SJI_xloopTM2		; ds:si->buffer space
		call	SetOurTransformation		; save current TMatrix
		pop	curJob.SJI_bmWinHan		; restore SJI_bmWinHan

		; assume tiling upright, but check rotated case

		mov	ax, curJob.SJI_printWidth	; translate this much
		neg	ax
		clr	bx
		call	TranslateThePage		; DONT_INVAL still ok

endif	; _DUAL_THREADED_PRINTING

if not _NONSPOOL ;-------------------------------------------------------------
		call	AskForNextPage
		cmp	ax, IC_DISMISS			; only happens if we're
		je	shutdownHere			;  shutting down...
endif		;--------------------------------------------------------------

		jmp	tileInX				; more of swoosh to do 

nextPassAcross:
		sub	curJob.SJI_curyPage, 1		; one less page to do
		LONG	jle	doneDocPage		; all done with doc pg

		; set the file position back to start of page

		call	ResetFilePosition		; set to start o page

		; still have more swooshes to do 

		lea	si, curJob.SJI_yloopTM		; ds:si->buffer space
		call	SetOurTransformation		; apply old one
		mov	bx, curJob.SJI_printHeight	; translate this much
		neg	bx
		clr	ax
		test	curJob.SJI_printState, mask SPS_ROTATED 
		jz	applyYTrans
		xchg	ax, bx				; swap amounts if so
applyYTrans:
		call	TranslateThePage		; DONT_INVAL still ok

if _DUAL_THREADED_PRINTING	; Now do the same thing for other bitmap window
		
		; still have more swooshes to do 

		push	curJob.SJI_bmWinHan		; save SJI_bmWinHan
		mov	si, curJob.SJI_bmWinHan2	; si <- bmWinHan2
		mov	curJob.SJI_bmWinHan, si		; bmWinHan = bmWinHan2
		lea	si, curJob.SJI_yloopTM2		; ds:si->buffer space
		call	SetOurTransformation		; apply old one
		pop	curJob.SJI_bmWinHan

		mov	bx, curJob.SJI_printHeight	; translate this much
		neg	bx
		clr	ax
		test	curJob.SJI_printState, mask SPS_ROTATED 
		jz	applyYTrans2
		xchg	ax, bx				; swap amounts if so
applyYTrans2:
		call	TranslateThePage		; DONT_INVAL still ok

endif	; _DUAL_THREADED_PRINTING

if not _NONSPOOL ;-------------------------------------------------------------
		call	AskForNextPage
		cmp	ax, IC_DISMISS			; only happens if we're
		je	shutdownHere			;  shutting down...
endif		;--------------------------------------------------------------

		jmp	tileInY				; do another swoosh

if _NONSPOOL	;--------------------------------------------------------------
ejectPaper:

if _DUAL_THREADED_PRINTING
		call	PrintBlockOnPrintThread
endif
		mov	di, DR_PRINT_END_PAGE		; spit the paper out
		mov	bx, curJob.SJI_pstate		; pass the pstate
		call	curJob.SJI_pDriver

		call	GetPrinterReturnCode		; get returns.
		cmp	ax, PDR_NO_RETURN
		je	exitErr

		mov	cx, PERROR_PAPER_MISFEED	; set jammed error code
		clr	dx
		call	SpoolErrorBox			; can only answer OK
		TestUserStandardDialogResponses \
		SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK			; if affirmative
		je	ejectPaper			; if OK, try again...
endif		; _NONSPOOL ---------------------------------------------------

		; there was an error in printing.  just exit
exitErr:
		pop	ax, ax				; restore stack
shutdownHere:
		mov	ax, GSRT_FAULT			; pretend a problem

doneDocPage:
		mov	di, curJob.SJI_bmWinHan		; get window handle
		mov	cx, WIF_DONT_INVALIDATE		; dont inval the window
		call	WinSetNullTransform		; set it back

if _DUAL_THREADED_PRINTING
		mov	di, curJob.SJI_bmWinHan2	; get window handle
		mov	cx, WIF_DONT_INVALIDATE		; dont inval the window
		call	WinSetNullTransform		; set it back
endif	; _DUAL_THREADED_PRINTING

		.leave
		ret

PrintGraphicsPage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AskForNextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask for the next piece of paper for manual feed, if needed

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		ax	- Dialog box results.

DESTROYED:	bx,cx,dx

PSEUDO CODE/STRATEGY:
		check manual feed flag and do the right thing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _NONSPOOL ;-------------------------------------------------------------

AskForNextPage	proc	near
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

		mov	cx, SERROR_MANUAL_PAPER_FEED	; ask for next piece
		clr	dx
		call	SpoolErrorBox			; he can only answer OK
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
done:
		.leave
		ret
AskForNextPage	endp

endif	; not _NONSPOOL -------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetFilePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the file position to read from the start of the page

CALLED BY:	PrintGraphicsPage, PrintGraphicsLabels

PASS:		nothing

RETURN:		

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetFilePosition	proc	far
curJob	local	SpoolJobInfo
	.enter	inherit
	mov	al, FILE_POS_START
	mov	bx, curJob.SJI_fHan		; fetch file handle
	mov	dx, {word} curJob.SJI_fPos	;  and postion
	mov	cx, {word} curJob.SJI_fPos+2
	call	FilePos				; set to start o page
	.leave
	ret
ResetFilePosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustBitmapHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the height of the bitmap to be the correct fraction
		of a normal bitmap height

CALLED BY:	PrintGraphicsPage, PrintGraphicsLabels

PASS:		dx	- height of the bitmap to set.		

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
 		since we are on the last swath, make sure that the
 		bitmap height field in the Huge bitmap reflects how
 		much we are actually going to send to the print driver.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustBitmapHeight	proc	far
	uses	ax,bx,di,ds
curJob	local	SpoolJobInfo
	.enter	inherit
 	mov	di, curJob.SJI_bmHan		; get HugeArray handle
 	mov	bx, curJob.SJI_bmFileHan	;
 	call	HugeArrayLockDir		; lock dir block
 	mov	ds, ax
 	mov	ds:[size HugeArrayDirectory].B_height, dx
	call	HugeArrayDirty
 	call	HugeArrayUnlockDir
	.leave
	ret
AdjustBitmapHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOurTransformation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the transformation matrix into curJob

CALLED BY:	PrintGraphicsPage, PrintGraphicsLabels

PASS:		si	- pointer to TransMatrix buffer (in stack frame)

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		call WinGetTransform to fill the buffer in the stack frame
		pointed at by si 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOurTransformation	proc	far
curJob	local	SpoolJobInfo
	.enter	inherit
	segmov	ds, ss, di			; ds -> stack
	mov	di, curJob.SJI_bmWinHan		; window handle
	call	WinGetTransform			; save current TMatrix
	.leave
	ret
GetOurTransformation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetOurTransformation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set our tmatrix into the W_TMatrix

CALLED BY:	PrintGraphicsPage

PASS:		si	- pointer to TransMatrix buffer (in stack frame)

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		call WinSetTransform to fill the Window tmatrix from the
		buffer in the stack frame pointed at by si 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetOurTransformation	proc	near
curJob	local	SpoolJobInfo
	.enter	inherit
	segmov	ds, ss, di
	mov	di, curJob.SJI_bmWinHan		; get window handle
	mov	cx, WIF_DONT_INVALIDATE
	call	WinSetTransform			; apply old one
	.leave
	ret
SetOurTransformation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateThePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask for the next piece of paper for manual feed, if needed

CALLED BY:	PrintGraphicsPage

PASS:		ax	- translation in X
		bx	- translation in Y
		cx	- invalidation flag

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		check manual feed flag and do the right thing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateThePage	proc	near
curJob	local	SpoolJobInfo
	.enter	inherit

	mov	si, cx				; si get INVAL flag
	test	curJob.SJI_printState, mask SPS_ROTATED 
	jz	applyTrans
	xchg	ax, bx				; swap amounts if so
applyTrans:
	mov	dx, ax				; x in dx.cx
	clr	cx
	clr	ax				; y in bx.ax
	call	WinApplyTranslation		; DONT_INVAL still ok

	.leave
	ret
TranslateThePage	endp

PrintGraphics	ends
