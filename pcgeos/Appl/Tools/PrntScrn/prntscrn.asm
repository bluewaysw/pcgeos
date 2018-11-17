COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Appl/Tools/PrntScrn
FILE:		prntscrn.asm

AUTHOR:		Don Reeves, Aug 11, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/11/94		Initial revision

DESCRIPTION:
	Contains the code to implement the "Print to Screen" application

	$Id: prntscrn.asm,v 1.1 97/04/04 17:15:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	Common include files
;------------------------------------------------------------------------------

include geos.def
include geode.def
include resource.def
include ec.def
include object.def
include timer.def
include system.def
include heap.def
include gstring.def
include initfile.def

;------------------------------------------------------------------------------
;	Common libraries
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	spool.def
include	Internal/spoolInt.def

;------------------------------------------------------------------------------
;	Include common object definitions
;------------------------------------------------------------------------------

include Objects/inputC.def
include Objects/vTextC.def
include Objects/winC.def

;------------------------------------------------------------------------------
;	Include common definitions
;------------------------------------------------------------------------------

PrntScrnProcessClass	class	GenProcessClass

MSG_PRNT_SCRN_SELECT_SPOOL_FILE					message
MSG_PRNT_SCRN_OPEN_SPOOL_FILE					message
MSG_PRNT_SCRN_CLOSE_SPOOL_FILE					message
MSG_PRNT_SCRN_INVALIDATE_VIEW					message

MSG_PRNT_SCRN_SELECT_PRINT_FILE					message
MSG_PRNT_SCRN_OPEN_PRINT_FILE					message

PrntScrnProcessClass	endc

DrawOptions	record
    :14
    DO_MARGIN_BOUNDS:1				; draw margin bounds
    DO_PAGE_BOUNDS:1				; draw page bounds
DrawOptions	end

;------------------------------------------------------------------------------
;	Code
;------------------------------------------------------------------------------

include	prntscrn.rdef

idata		segment
	PrntScrnProcessClass
idata		ends

udata		segment
	windowHandle	hptr			; handle of Window for view

	diskHandle	StandardPath
	filePath	TCHAR PATH_BUFFER_SIZE dup (?)
	fileName	TCHAR FILE_LONGNAME_BUFFER_SIZE dup (?)
	fileHandle	hptr
	pageFilePos	dword 100 dup (?)	; array of page file positions
	pageRect	Rectangle		; bounds of page
	marginRect	Rectangle		; bounds of margins
udata		ends

PrntScrnCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the application

CALLED BY:	GLOBAL (MSG_GEN_PROCESS_OPEN_APPLICATION)

PASS:		DS, ES	= DGroup
		CX	= AppAttachFlags
		DX	= AppLaunchBlock handle (may be 0)
		BP	= Extra state block handle (may be 0)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnOpenApplication	method dynamic	PrntScrnProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION
		.enter
	;
	; Call our superclass first
	;
		mov	di, offset PrntScrnProcessClass
		call	ObjCallSuperNoLock

		.leave
		ret
PrntScrnOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the application

CALLED BY:	GLOBAL (MSG_GEN_PROCESS_CLOSE_APPLICATION)

PASS:		DS, ES	= DGroup

RETURN:		CX	= Extra state block (0 for none)

DESTROYED:	AX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/11/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnCloseApplication	method dynamic	PrntScrnProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION
		.enter
	;
	; Close the current file; commit print on/off setting
	;
		call	CloseCurrentFile
		call	InitFileCommit
		clr	cx			; no extra block

		.leave
		ret
PrntScrnCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnViewWinOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a view's Window has been opened

CALLED BY:	GLOBAL (MSG_META_CONTENT_VIEW_WIN_OPENED)

PASS:		DS, ES	= DGroup
		CX	= Width of view (ignored)
		DX	= Height of view (ignored)
		BP	= Handle to Window that was opened

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnViewWinOpened	method dynamic	PrntScrnProcessClass,
					MSG_META_CONTENT_VIEW_WIN_OPENED
		.enter

		mov	ds:[windowHandle], bp

		.leave
		ret
PrntScrnViewWinOpened	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnViewWinClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a view's Window has been opened

CALLED BY:	GLOBAL (MSG_META_CONTENT_VIEW_WIN_CLOSED)

PASS:		DS, ES	= DGroup
		BP	= Handle to Window that was closed

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnViewWinClosed	method dynamic	PrntScrnProcessClass,
					MSG_META_CONTENT_VIEW_WIN_CLOSED
		.enter

		cmp	ds:[windowHandle], bp
		jne	done
		clr	ds:[windowHandle]
done:
		.leave
		ret
PrntScrnViewWinClosed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to an exposure of the View's window

CALLED BY:	GLOBAL (MSG_META_EXPOSED)

PASS:		*DS:SI	= PrntScrnProcessClass object
		DS:DI	= PrntScrnProcessInstance
		CX	= Window handle

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnExposed	method dynamic	PrntScrnProcessClass, MSG_META_EXPOSED
		.enter
	;
	; Start the update process
	;
		mov	di, cx
		call	GrCreateState		; GState => DI
		call	GrBeginUpdate
		tst	ds:[fileHandle]		; if no file
		LONG jz	doneUpdate		; ...do nothing
	;
	; Position the GString file to the correct location
	;
		push	di
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	bx, handle PageCurrent
		mov	si, offset PageCurrent
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	bp, dx
		dec	bp			; make page # zero-based
		shl	bp, 1
		shl	bp, 1			; offset into dword table
		mov	al, FILE_POS_START
		mov	bx, ds:[fileHandle]
		movdw	cxdx, ds:[pageFilePos][bp]
		call	FilePos
	;
	; Load the GString
	;
		mov	cl, GST_STREAM
		call	GrLoadGString		; GString handle => SI
	;
	; Now draw the page
	;
		pop	di			; GState handle = DI
		clr	ax, bx
		mov	dx, mask GSC_NEW_PAGE
		call	GrDrawGString
	;
	; Destroy the GString, and possibly draw some bounds
	;
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
		push	di			; save GState
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		mov	bx, handle Interface
		mov	si, offset Interface:DrawOptionsBoolean
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	di			; restore GState
		mov	si, PCT_NULL
		call	GrSetClipRect		; clear any clip rectangle
		mov_tr	bp, ax			; DrawOptions => BP
		mov	ax, C_RED or (CF_INDEX shl 8)
		call	GrSetLineColor
		mov	dx, 1
		clr	ax
		call	GrSetLineWidth
		test	bp, mask DO_PAGE_BOUNDS
		jz	checkMargins
		mov	si, offset pageRect
		call	drawRect
checkMargins:
		test	bp, mask DO_MARGIN_BOUNDS
		jz	doneUpdate
		mov	al, LS_DASHED
		clr	bl
		call	GrSetLineStyle
		mov	si, offset marginRect
		call	drawRect
	;
	; Now we're done. End the update & free the GState
	;
doneUpdate:
		call	GrEndUpdate
		call	GrDestroyState

		.leave
		ret
	;
	; Draw a rectangle
	;	Pass:	DS:SI	= Rectangle
	;		DI	= GState handle
	;
drawRect:
		mov	ax, ds:[si].R_left
		mov	bx, ds:[si].R_top
		mov	cx, ds:[si].R_right
		mov	dx, ds:[si].R_bottom
		call	GrDrawRect
		retn
PrntScrnExposed	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnInvalidateView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate wht is currently displayed in the view

CALLED BY:	GLOBAL (MSG_PRNT_SCRN_INVALIDATE_VIEW)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnInvalidateView	method dynamic	PrntScrnProcessClass,
					MSG_PRNT_SCRN_INVALIDATE_VIEW
		.enter

		call	InvalidateWindow

		.leave
		ret
PrntScrnInvalidateView	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnSelectSpoolFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a spool file so that it can be displayed

CALLED BY:	GLOBAL (MSG_PRNT_SCRN_SELECT_SPOOL_FILE)

PASS:		DS, ES	= DGroup
		CX	= Entry # of selection (not used)
		BP	= GenFileSelectorEntryFlags

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnSelectSpoolFile	method dynamic	PrntScrnProcessClass,
					MSG_PRNT_SCRN_SELECT_SPOOL_FILE
		.enter
	;
	; Disable the "Open" trigger if a file is not selected
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	cx, bp
		and	cx, mask GFSEF_TYPE
		cmp	cx, GFSET_FILE shl offset GFSEF_TYPE
		jne	setStatus
		mov	ax, MSG_GEN_SET_ENABLED
setStatus:
		push	cx, bp
		mov	dl, VUM_NOW
		mov	bx, handle OpenSpoolFileTrigger
		mov	si, offset OpenSpoolFileTrigger
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	cx, bp
	;
	; Now check to see if the user attempted to open a file
	;
		cmp	cx, GFSET_FILE shl offset GFSEF_TYPE
		jne	done
		test	bp, mask GFSEF_OPEN
		jz	done
		mov	ax, MSG_GEN_TRIGGER_SEND_ACTION
		clr	cl
		mov	bx, handle OpenSpoolFileTrigger
		mov	si, offset OpenSpoolFileTrigger
		clr	di
		call	ObjMessage		
done:
		.leave
		ret
PrntScrnSelectSpoolFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnOpenSpoolFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a spool file so that it can be displayed

CALLED BY:	GLOBAL (MSG_PRNT_SCRN_OPEN_SPOOL_FILE)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnOpenSpoolFile	method dynamic	PrntScrnProcessClass,
					MSG_PRNT_SCRN_OPEN_SPOOL_FILE
		.enter
	;
	; Clean up the previous file
	;
		call	CloseCurrentFile
	;
	; Obtain the path to the file
	;
		mov	ax, MSG_GEN_PATH_GET
		mov	cx, (size filePath)
		mov	dx, ds
		mov	bp, offset filePath
		mov	bx, handle OpenSpoolFileSelector
		mov	si, offset OpenSpoolFileSelector
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	ds:[diskHandle], cx
	;
	; Obtain the selection itself
	;
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		mov	cx, ds
		mov	dx, offset fileName
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Verify we can do something with this file
	;
		test	bp, mask GFSEF_NO_ENTRIES or mask GFSEF_PARENT_DIR
		jnz	errorNotFile
		and	bp, mask GFSEF_TYPE
		cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
		jne	errorNotFile
	;
	; OK, we're set. Open the GString file
	;
		mov	bx, ds:[diskHandle]
		mov	dx, offset filePath
		call	FileSetCurrentPath
		jc	errorBadPath
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		mov	dx, offset fileName
		call	FileOpen
		jc	errorFileOpen
		mov	ds:[fileHandle], ax
	;
	; Initialize our state, and display the first page
	;
		call	LearnPrintJobDetails
		call	LearnGStringDetails
		jc	errorBadFile		; illegal GString
	;
	; Enable the JobInfo DB & Close trigger
	;
		mov	ax, MSG_GEN_SET_ENABLED
		call	SetStatusOfFileProperties
done:
		call	InvalidateWindow

		.leave
		ret

errorNotFile:
		mov	si, offset NotFileErrorMsg
		jmp	errorCommon
errorBadPath:
		mov	si, offset BadPathErrorMsg
		jmp	errorCommon
errorFileOpen:
		mov	si, offset FileOpenErrorMsg
		jmp	errorCommon
errorBadFile:
		mov	si, offset BadFileErrorMsg
errorCommon:
		call	DisplayErrorToUser
		call	CloseCurrentFile
		jmp	done
PrntScrnOpenSpoolFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrntScrnCloseSpoolFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the spool file that is currently open

CALLED BY:	GLOBAL (MSG_PRNT_SCRN_CLOSE_SPOOL_FILE)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrntScrnCloseSpoolFile	method dynamic	PrntScrnProcessClass,
					MSG_PRNT_SCRN_CLOSE_SPOOL_FILE
		.enter

		call	CloseCurrentFile
		call	InvalidateWindow

		.leave
		ret
PrntScrnCloseSpoolFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LearnPrintJobDetails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Learn details about the print job whose spool file we are
		viewing

CALLED BY:	PrntScrenOpenSpoolFile

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* Creator
		* Name of document
		* Get number of reported pages
		* Get document dimensions
		* Get margin values

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LearnPrintJobDetails	proc	near
		.enter
	;
	; First, go find the JobParameters for the spool file
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	ds:[diskHandle], SP_SPOOL
		LONG jne	setUIStatus
		cmp	{byte} ds:[filePath], 0
		LONG jne	setUIStatus
		call	FindJobParameters
		jc	setUIStatus
		call	MemLock
		mov	es, ax			; JobParameters => ES:0
	;
	; Store the creator & document name
	;
		mov	bp, offset JP_documentName
		mov	bx, handle Interface
		mov	si, offset Interface:SpoolFileDocumentName
		call	setText
		mov	bp, offset JP_parent
		mov	si, offset Interface:SpoolFileCreatorName
		call	setText
	;
	; Store the number of reported pages
	;
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		mov	cx, es:[JP_numPages]
		clr	bp			; determinate
		mov	si, offset Interface:SpoolFileNumPages
		clr	di
		call	ObjMessage
	;
	; Store the reported dimensions (including margins)
	;
		mov	ax, MSG_PZC_SET_PAGE_SIZE
		mov	dx, es
		mov	bp, offset JP_docSizeInfo
		mov	si, offset Interface:SpoolFileDocSize
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Store the bounds of the page & printable area
	;
		clr	ax, bx
		mov	cx, es:[JP_docSizeInfo].PSR_width.low
		mov	dx, es:[JP_docSizeInfo].PSR_height.low
		mov	ds:[pageRect].R_right, cx
		mov	ds:[pageRect].R_bottom, dx
		add	ax, es:[JP_docSizeInfo].PSR_margins.PCMP_left
		add	bx, es:[JP_docSizeInfo].PSR_margins.PCMP_top
		sub	cx, es:[JP_docSizeInfo].PSR_margins.PCMP_right
		sub	dx, es:[JP_docSizeInfo].PSR_margins.PCMP_bottom
		mov	ds:[marginRect].R_left, ax
		mov	ds:[marginRect].R_top, bx
		mov	ds:[marginRect].R_right, cx
		mov	ds:[marginRect].R_bottom, dx
		mov	ax, MSG_GEN_SET_ENABLED
	;
	; Enable or disable the UI
	;
setUIStatus:
		mov	bx, handle Interface
		mov	si, offset Interface:DrawOptionsBoolean
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		mov	si, offset Interface:JobInfoDialog
		clr	di
		call	ObjMessage
	;
	; If we are disabling the UI, turn off the two rectangles
	;
		cmp	ax, MSG_GEN_SET_ENABLED
		je	displayInfo
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		clr	cx, dx			; nothing set
		mov	si, offset Interface:DrawOptionsBoolean
		clr	di
		call	ObjMessage
		mov	cx, 17 * 36
		mov	dx, 11 * 72		; assume page is 8.5 * 72
		jmp	done
	;
	; Bring up the Info dialog box
	;
displayInfo:
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
		mov	cx, ds:[pageRect].R_right
		mov	dx, ds:[pageRect].R_bottom
	;
	; Finally, set the page dimensions for the view
	;
done:
		mov	si, offset Interface:PrntScrnView
		clr	di
		call	GenViewSetSimpleBounds		

		.leave
		ret
	;
	; Store some text in a text object.
	;	Pass:	ES:BP	= Text
	;		BX:SI	= Text object
	;
setText:
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		clr	cx
		mov	dx, es
		mov	di, mask MF_CALL
		call	ObjMessage
		retn
LearnPrintJobDetails	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindJobParameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the JobParameters corresponding to the spool file

CALLED BY:	LearnPrintJobDetails

PASS:		DS	= DGroup

RETURN:		BX	= Handle of block holding JobParameters
		Carry	= Clear
			- or -
		BX	= garbage
		Carry	= Set

DESTROYED:	CX, DX, BP, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindJobParameters	proc	near
		uses	ax
portParams	local	PrintPortInfo
		.enter
	;
	; Loop through all of the serial ports
	;
		mov	dx, ss
		lea	si, ss:[portParams]
		mov	cx, SerialPortNum / 2
		mov	ss:[portParams].PPI_type, PPT_SERIAL
		clr	ss:[portParams].PPI_params.PP_serial.SPP_portNum
serialPortLoop:
		push	cx
		mov	cx, SIT_QUEUE_INFO
		call	SpoolInfo
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	serialPortNext
		call	FindJobInList
		jnc	done
serialPortNext:
		pop	cx
		add	ss:[portParams].PPI_params.PP_serial.SPP_portNum, 2
		loop	serialPortLoop
	;
	; Loop through all of the parallel ports
	;
		mov	cx, ParallelPortNum / 2
		mov	ss:[portParams].PPI_type, PPT_PARALLEL
		clr	ss:[portParams].PPI_params.PP_parallel.PPP_portNum
parallelPortLoop:
                push    cx
                mov     cx, SIT_QUEUE_INFO
		call	SpoolInfo
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	parallelPortNext
		call	FindJobInList
		jnc	done
parallelPortNext:
		pop	cx
		add	ss:[portParams].PPI_params.PP_parallel.PPP_portNum, 2
		loop	parallelPortLoop
	;
	; Finally, look for jobs being printed to a file
	;
		push	cx
		mov	ss:[portParams].PPI_type, PPT_FILE
		mov	cx, SIT_QUEUE_INFO
		call	SpoolInfo
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
                stc                             ; if this fails, return error
		jne	done
		call	FindJobInList
done:
		pop	cx			; clean up stack

		.leave
		ret
FindJobParameters	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindJobInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if any of the passed jobs match the one we want

CALLED BY:	FindJobParameters

PASS:		DS	= DGroup
		BX	= Handle of block with JobID's
		CX	= Number of ID's in block

RETURN:		BX	= Handle of block hilding JobParameters
		Carry	= Clear
			- or -
		BX	= garbage
		Carry	= Set

DESTROYED:	AX, CX, DX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/18/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindJobInList	proc	near
		.enter
	;
	; Loop throught all of the jobs, comparing the spool file names
	;
		push	bx
		call	MemLock
		mov	es, ax
		clr	di			; offset to JobID => ES:DI
jobLoop:
		push	cx, di, es
		mov	cx, SIT_JOB_PARAMETERS
		mov	dx, es:[di]
		call	SpoolInfo
		cmp	ax, SPOOL_OPERATION_SUCCESSFUL
		jne	jobNext
	;
	; We found the job - compare the spool file names
	;
		call	MemLock
		mov	es, ax
		mov	di, offset JP_fname
		mov	si, offset fileName
		call	LocalCmpStrings		; spool filename match?
		jne	freeParams		; nope, so keep looking
		call	MemUnlock
		add	sp, 6			; clean up stack
		clc
		jmp	done
freeParams:
		call	MemFree
jobNext:
		pop	cx, di, es
		add	di, 2
		loop	jobLoop
		stc
done:
		lahf
		mov	cx, bx
		pop	bx
		call	MemFree
		mov	bx, cx
		sahf
	
		.leave
		ret
FindJobInList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LearnGStringDetails
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Learn the details of the GString (bounds, # of pages)

CALLED BY:	PrntScrnOpenSpoolFile

PASS:		DS	= DGroup

RETURN:		Carry	= Set if error (invalid GString)

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LearnGStringDetails	proc	near
		.enter
	;
	; Stuff the name of the file into the text object
	;
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	dx, ds
		mov	bp, offset fileName
		clr	cx			; NULL-terminated
		mov	bx, handle FileName
		mov	si, offset FileName
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Scan for the number of pages in the spool file. We only
	; scan for GR_NEW_PAGE opcodes, which is what an application
	; should produce. Also keep track of the offset for the start
	; of each page
	;
		clr	di
		call	GrCreateState		; dummy GState => DI
		mov	cl, GST_STREAM
		mov	bx, ds:[fileHandle]
		call	GrLoadGString
		clr	bp			; initialize page count
pageLoop:
		mov	al, FILE_POS_RELATIVE
		mov	bx, ds:[fileHandle]
		clr	cx, dx			; don't move at all
		call	FilePos
		shl	bp, 1
		shl	bp, 1
		movdw	ds:[pageFilePos][bp], dxax
		shr	bp, 1
		shr	bp, 1
		clr	ax, bx
		mov	dx, mask GSC_NEW_PAGE
		call	GrDrawGString
		cmp	dx, GSRT_FAULT		; if we hit a fault
		stc				; ...bogus GString!
		je	done
		cmp	dx, GSRT_COMPLETE
		je	donePageLoop
		inc	bp			; else increment page count
		jmp	pageLoop
donePageLoop:
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString
		call	GrDestroyState
	;
	; Set the number of pages available
	;
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		mov	dx, bp			; # of pages => DX
		clr	cx, bp			; determinate, no fraction
		mov	bx, handle Interface
		mov	si, offset Interface:PageTotal
		clr	di
		call	ObjMessage
	
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		mov	si, offset Interface:PageTotalReported
		clr	di
		call	ObjMessage
	
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		mov	si, offset Interface:PageCurrent
		clr	di
		call	ObjMessage
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		mov	dx, 1
		clr	di
		call	ObjMessage
		clc
done:		
		.leave
		ret
LearnGStringDetails	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseCurrentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the current open file (if any)

CALLED BY:	UTILITY

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CloseCurrentFile	proc	near
		.enter
	;
	; Pretty simple, actually
	;
		clr	bx
		xchg	bx, ds:[fileHandle]
		tst	bx
		jz	done
		clr	al			; accept errors
		call	FileClose		; ...but ignore them
	;
	; Disable the JobInfo DB & Close trigger
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	SetStatusOfFileProperties
done:
		.leave
		ret
CloseCurrentFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStatusOfFileProperties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the status (enabled or disabled) or the various
		property boxes & other UI assocated with a spool file

CALLED BY:	UTILITY

PASS:		AX	= MSG_GEN_SET_[NOT_]ENABLED

RETURN:		Nothing

DESTROYED:	BX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetStatusOfFileProperties	proc	near
		.enter

		mov	bx, handle Interface
		mov	dl, VUM_NOW
		clr	di
		mov	si, offset Interface:CloseSpoolFile
		call	ObjMessage
		mov	si, offset Interface:JobInfoDialog
		call	ObjMessage
	
		.leave
		ret
SetStatusOfFileProperties	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalidateWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the currently displayed window

CALLED BY:	UTILITY

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvalidateWindow	proc	near
		uses	di, si, bp
		.enter
	;
	; Invalidate the whole thing
	;
		mov	ax, 0c000h
		mov	bx, 0c000h		; largest negative values
		mov	cx,  3fffh
		mov	dx,  3fffh		; largest positive values	
		clr	bp, si			; we have a rectangle
		mov	di, ds:[windowHandle]
		tst	di			; no Window?
		jz	done			; if so, abort gracefully
		call	WinInvalReg
done:
		.leave
		ret
InvalidateWindow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorToUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display an error to the user

CALLED BY:	UTILITY

PASS:		SI	= Chunk handle of error message

RETURN:		Nothing

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayErrorToUser	proc	near
		.enter
	
		clr	ax
		mov	bx, handle Strings
		pushdw	axax			; SDOP_helpContext
		pushdw	axax			; SDOP_customTriggers
		pushdw	axax			; SDOP_stringArg2
		pushdw	axax			; SDOP_stringArg1
		pushdw	bxsi			; SDOP_customString
		mov	ax, CDT_ERROR shl offset CDBF_DIALOG_TYPE or \
			    GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
		push	ax			; SDOP_customFlags
		call	UserStandardDialogOptr

		.leave
		ret
DisplayErrorToUser	endp

PrntScrnCode	ends

