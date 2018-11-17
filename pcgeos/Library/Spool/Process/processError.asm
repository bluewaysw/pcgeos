COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		System Spooler
FILE:		processError.asm

AUTHOR:		Jim DeFrisco, 15 March 1990

ROUTINES:
	Name			Description
	----			-----------
    GBL	SpoolErrorBox		Put up a standard error box from the spooler

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/13/90		Initial revision


DESCRIPTION:
	This file contains the code to handle all kinds of spooler/printer
	related errors

	$Id: processError.asm,v 1.1 97/04/07 11:11:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintError	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GetPrinterReturnCode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Pick the PrintDriverReturn code out of the PState

CALLED BY:      PrintGraphicsPage, PrintGraphicsLabels

PASS:           nothing

RETURN:         ax = return code (PDR_.... enum)

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
                Name    Date            Description
                ----    ----            -----------
                Dave    1/94            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_NONSPOOL
GetPrinterReturnCode    proc    far
curJob  local   SpoolJobInfo
        .enter  inherit
        push    ds,bx
        mov     bx, curJob.SJI_pstate
        call    MemLock
        mov     ds, ax
        mov     ax,ds:[PS_dWP_Specific].DWPS_returnCode
        call    MemUnlock                       ; (preserves flags)
        pop     ds,bx
        .leave
        ret
GetPrinterReturnCode    endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        SpoolLock/UnlockPrintJob
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Set/reset teh flag to tell whether the keyboard monitor
                        should listen to keystrokes or not.

CALLED BY:      PrintGraphicsPage, PrintGraphicsLabels

PASS:           nothing

RETURN:         nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
                Name    Date            Description
                ----    ----            -----------
                Dave    1/94            Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_NONSPOOL
SpoolLockPrintJob       proc    far
curJob  local   SpoolJobInfo
        uses    ax, bx, di
        .enter  inherit
        mov     al, TRUE
        mov     bx, curJob.SJI_pstate
        mov     di, DR_PRINT_ESC_SET_JOB_STATUS
        call    curJob.SJI_pDriver
        .leave
        ret
SpoolLockPrintJob       endp

SpoolUnlockPrintJob     proc    far
curJob  local   SpoolJobInfo
        uses    ax, bx, di
        .enter  inherit
        clr     al
        mov     bx, curJob.SJI_pstate
        mov     di, DR_PRINT_ESC_SET_JOB_STATUS
        call    curJob.SJI_pDriver
        .leave
        ret
SpoolUnlockPrintJob     endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                SpoolProcessErrors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       This routine puts up a the appropriate GenSummons and waits
                for the OK button to be pressed.

CALLED BY:      INTERNAL
                PrintGraphicsPage

PASS:		nothing

RETURN:         carry   =       set - catastrophic quit, no endpage call
                                        AX = GSRT_FAULT on exit with carry
                carry   =       clear - check ax
                ax      =       flag to quit or keep going.
                                GSRT_COMPLETE = OK do another swath
                                GSRT_FAULT = quit, ejecting the paper.

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
                Name    Date            Description
                ----    ----            -----------
                dave    02/94           Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_NONSPOOL
SpoolProcessErrors      proc    far
		uses    bx
curJob  local	SpoolJobInfo
		.enter  inherit

	;Take the start and finish of this routine from SpoolErrorBox below.

		; only one thread can be here at a time

		mov	ax, dgroup			; set ds -> dgroup
		mov	ds, ax
		mov	bx, ds:[errorThreadLock]
		call	ThreadGrabThreadLock		; only one at a time
		
		; call to the print driver error handler .

		mov	dx, ss
		lea	si, curJob			; dx:si <- SpoolJobInfo
		mov	bx, curJob.SJI_pstate
		mov	di, DR_PRINT_ESC_PROCESS_ERRORS
		call	curJob.SJI_pDriver

	;Take the end of the routine from the SpoolErrorBox routine below.

		mov	cx, dgroup
		mov	ds, cx
		mov	bx, ds:[errorThreadLock]
		call	ThreadReleaseThreadLock

	        .leave
	        ret
SpoolProcessErrors      endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NonSpoolPaperFeedBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up paper feed dialog box

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ax = InteractionCommand
			IC_OK = Paper Insert
			IC_DISMISS = Cancel
			IC_NULL = Cancel
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NONSPOOL	;--------------------------------------------------------------
NonSpoolPaperFeedBox	proc	far
	uses	bx,si
	.enter

	mov	bx, handle NonSpoolPaperFeedDialog
	mov	si, offset NonSpoolPaperFeedDialog
	call	UserCreateDialog
	call	UserDoDialog
	call	UserDestroyDialog

	.leave
	ret
NonSpoolPaperFeedBox	endp
endif	; if _NONSPOOL --------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolErrorBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine puts up a the appropriate GenSummons and waits
		for the OK button to be pressed.

CALLED BY:	INTERNAL

PASS:		cx	- PrinterError enum
		dx	- print queue handle 
			  (can be zero if it doesn't apply)

RETURN:		ax - InteractionCommand response from dialog trigger
		     IC_NULL if call was reentrant on the same thread

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Use UserStandardDialog to put up a message and get a 
		response

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	04/90		Compressed into one dialog box
		Jim	05/90		Changed to use UserStandardDialog
		dhunter	09/02/00	Made reentrant

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolErrorBox	proc	far
		uses	bx, cx, dx, si, di, bp, ds
		.enter

		; only one thread can be here at a time

		mov	ax, dgroup			; set ds -> dgroup
		mov	ds, ax
		mov	bx, ds:[errorThreadLock]
		call	ThreadGrabThreadLock		; only one at a time

		; A reentrant call (errorBoxCount already one) probably means
		; the error we're waiting for the user to acknowledge has
		; been cleared.  Close the existing error and return.

		inc	ds:[errorBoxCount]
		cmp	ds:[errorBoxCount], 1		; > 1 if reentered
	LONG	ja	closeBox
		
		; set the SI_PAUSE flag for the queue

		push	dx				; save queue handle
		call	PauseSpoolThread

		; first set up all the current strings in the resource segment

		mov	bx, handle ErrorBoxesUI
		push	bx				;save ErrorBoxesUI hptr
		call	MemLock
		mov	ds, ax				; ds = ErrorBoxesUI
		tst	dx				; if no args...
		jz	userStandardSetup		;  ...just put up box
		call	GetArgumentStrings		; set current printer...
		LONG jc	exit

		; Need:
		; ax - CustomDialogBoxFlags.
		; di:bp - error message string.
		; cx:dx - First string argument.
		; bx:si - Second string argument.
		; StandardDialogParams
		;	SDP_type
		;	SDP_customFlags
		;	SDP_customString
		;	SDP_stringArg1
		;	SDP_stringArg2
		;	SDP_customTriggers (if GIT_MULTIPLE_RESPONSE)
userStandardSetup:	
		mov	si, cx				; so we can addr things

		; lock down the segment with all the error message strings
		; then set SDP_type and SDP_customFlags

		mov	ax, cs:errTypesAndFlags[si]	; get flags in al,ah

		; set up stack frame for StandardDialogParams structure

		sub	sp, size StandardDialogParams
		mov	bp, sp				; ss:bp = params
		mov	ss:[bp].SDP_customFlags, ax

		; set up fptr to resource triggers (only used if
		; GIT_MULTIPLE_REPONSE)

		mov	bx, cs:errResponseTriggers[si]	; trigger list offset
EC <		andnf	ax, mask CDBF_INTERACTION_TYPE			>
EC <		cmp	ax, GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE >
EC <		jne	notCustom					>
EC <		tst	bx						>
EC <		ERROR_Z	SPOOL_ERROR_BOX_BAD_ERROR_TABLE_ENTRY		>
EC <notCustom:								>

		mov	ss:[bp].SDP_customTriggers.offset, bx
		mov	ss:[bp].SDP_customTriggers.segment, cs

		; set up the offsets to the right chunks
		; but use different strings if there is no queue to get the
		; info from

		tst	dx				; given any queue to 
		jz	noQueue				;  work with ?

		mov	bx, cs:errMessageStrings[si]	; err str chunk handle
		mov	ax, ds:[bx]			; set err msg offset
		mov	ss:[bp].SDP_customString.offset, ax

		mov	bx, cs:errArg1Strings[si]	; arg 1 chunk handle
		clr	ax				; assume no 1st arg
		tst	bx				; if 0, skip deref
		jz	haveArg1Offset
		mov	ax, ds:[bx]			; ax = arg1 offset
haveArg1Offset:
		mov	ss:[bp].SDP_stringArg1.offset, ax

		mov	bx, cs:errArg2Strings[si]	; arg 2 chunk handle
		clr	ax				; assume no 2nd arg
		tst	bx				; if 0, skip deref
		jz	haveArg2Offset
		mov	ax, ds:[bx]			; bx = arg2 chunk
haveArg2Offset:
		mov	ss:[bp].SDP_stringArg2.offset, ax

		; setup all the segments
setUpSegments:
		mov	ax, ds
		mov	ss:[bp].SDP_customString.segment, ax
		mov	ss:[bp].SDP_stringArg1.segment, ax
		mov	ss:[bp].SDP_stringArg2.segment, ax
		clr	ss:[bp].SDP_helpContext.segment
		; all done, now just call the thing

							; pass params on stack
		call	UserStandardDialog		; put up the DB
							; return value in ax
		cmp	ax, IC_NULL			; if null, make it
		jne	exit				;  DISMISS
		mov	ax, IC_DISMISS

		; unpause the thread and release the error code
exit:
		pop	bx				; ^hbx = ErrorBoxesUI
		call	MemUnlock
		pop	dx				; restore queue handle
		call	UnPauseSpoolThread
reallyExit:
		mov	cx, dgroup
		mov	ds, cx
		dec	ds:[errorBoxCount]
		mov	bx, ds:[errorThreadLock]
		call	ThreadReleaseThreadLock
		.leave
		ret

		; there was no queue, so use different strings, that don't
		; require any arguments
noQueue:
		mov	bx, cs:errMessageStringsNoArgs[si]
		mov	ax, ds:[bx]			; error string offset
		mov	ss:[bp].SDP_customString.offset, ax
		clr	ax
		mov	ss:[bp].SDP_stringArg1.offset, ax	; no args
		mov	ss:[bp].SDP_stringArg2.offset, ax
		jmp	setUpSegments

		; This action requires a bit of knowledge about the dialog
		; created by UserStandardDialog:
		;
		; 1. The dialog is a child of our app object.
		; 2. The dialog is modal and therefore has the focus.
		;
		; We return with IC_NULL here in the hopes that the caller will
		; return quietly to the method handler that started this mess,
		; poll the port for errors, and bring the new error to the
		; user's attention.
closeBox:
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_OK
		mov	bx, segment GenInteractionClass
		mov	si, offset GenInteractionClass
		mov	di, mask MF_RECORD
		call	ObjMessage			; di = event handle
		mov	ax, MSG_META_SEND_CLASSED_EVENT
		mov	bx, handle spoolAppObj
		mov	si, offset spoolAppObj		; ^lbx:si = appObj
		mov	cx, di				; cx = event handle
		mov	dx, TO_FOCUS
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		call	ObjMessage
		mov	ax, IC_NULL
		jmp	reallyExit
		
SpoolErrorBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PauseSpoolThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the SI_PAUSE flag in a print queue

CALLED BY:	INTERNAL
		SpoolErrorBox

PASS:		dx	- handle to print queue

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If the passed handle is valid (non-zero), them set the 
		QI_error flag to SI_PAUSE

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PauseSpoolThread proc	near
		uses	ax, bx, ds
		.enter

		; if the queue handle is invalid, just bail

		tst	dx
		jz	done

		; first, lock the queue

		call	LockQueue
		mov	ds, ax

		; now dereference the queue handle and set the flag

		mov	bx, dx			; set up an addressing reg
		mov	bx, ds:[bx]		; dereference handle
		mov	ds:[bx].QI_error, SI_PAUSE ; set pause flag
		
		; all done, release the queue

		call	UnlockQueue
done:
		.leave
		ret
PauseSpoolThread endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnPauseSpoolThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the SI_PAUSE flag in a print queue

CALLED BY:	INTERNAL
		SpoolErrorBox

PASS:		dx	- handle to print queue

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If the passed handle is valid (non-zero), them set the 
		QI_error flag to SI_PAUSE

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnPauseSpoolThread proc	near
		uses	ax, bx, ds
		.enter

		; if the queue handle is invalid, just bail

		tst	dx
		jz	done

		; first, lock the queue

		call	LockQueue
		mov	ds, ax

		; now dereference the queue handle and set the flag

		mov	bx, dx			; set up an addressing reg
		mov	bx, ds:[bx]		; dereference handle
		mov	ds:[bx].QI_error, SI_KEEP_GOING ; reset pause flag
		
		; all done, release the queue

		call	UnlockQueue
done:
		.leave
		ret
UnPauseSpoolThread endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetArgumentStrings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current printer, port, etc out of the PrintQueue 
		and into the resource chunk

CALLED BY:	INTERNAL
		SpooleErrorBox

PASS:		dx	- print queue handle
		ax	- segment of ErrorBoxesUI

RETURN:		carry	- set if some error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Lock/Own the PrintQueue and copy the strings for the current
		job of the passed queue to the chunks in the ErrorBoxesUI 
		resource.  The resource is guaranteed not to move.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetArgumentStrings proc	near
		uses	ax, bx, cx, dx, si, di, es, ds
		.enter

		; Lock the resource and resize all the chunks

		mov	es, ax

		; first lock down the resource and the PrintQueue

		call	LockQueue		; lock down the print queue
		LONG jc	noQueue			; something is screwy
		mov	ds, ax			; ds -> print queue
		assume	es:ErrorBoxesUI

		; set up pointer to current job

		mov	bx, dx			; bx = print queue handle
		mov	bx, ds:[bx]		; ds:bx -> print queue

		; already realloc'd the chunks, just copy them over
		; do the page number while we've got the queue info
		
		mov	di, es:[CurPageString]
		push	dx
		mov	ax, ds:[bx].QI_curPage
		inc	ax			; 1-origin, please
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii
		pop	dx

		; now the spool file name

		mov	di, es:[CurSpoolFileString]; get pointer to chunk
		mov	si, ds:[bx].QI_curJob	; *ds:si -> current job
		mov	bx, ds:[si]		; ds:bx -> current Job
		add	bx, JIS_info		; ds:bx -> JobParameters block
		mov	si, bx			; ds:si -> JobParameters block
		add	si, JP_fname		; ds:si -> spool file name
		mov	cx, size JP_fname	; size of block to copy
DBCS <		shr	cx, 1						>
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>

		; now move the parent application name

		mov	si, bx			; reset back to start of block
		add	si, JP_parent		; ds:si -> app name
		mov	cx, size JP_parent	; string length
		mov	di, es:[CurAppString]
DBCS <		shr	cx, 1						>
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>

		; now move the printer name

		mov	si, bx			; reset back to start of block
		add	si, JP_deviceName	; ds:si -> device name
		mov	cx, size JP_deviceName	; string length
		mov	di, es:[CurPrinterString]
DBCS <		shr	cx, 1						>
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>

		; now move the document name

		mov	si, bx			; reset back to start of block
		add	si, JP_documentName	; ds:si -> doc name
		mov	cx, size JP_documentName; string length
		mov	di, es:[CurDocumentString]
DBCS <		shr	cx, 1						>
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>

		; get the printer port type 

		mov	si, ds:[bx].JP_portInfo.PPI_type ; get port type
		segmov	ds, es, cx		; ds -> ErrorBoxesUI res
		mov	si, cs:portStrings[si]	; get chunk handle of string
		mov	si, ds:[si]		; deref chunk handle
		ChunkSizePtr ds, si, cx
		mov	di, es:[CurPortString]
DBCS <		shr	cx, 1						>
SBCS <		rep	movsb						>
DBCS <		rep	movsw						>

		call	UnlockQueue		; release the queue
		assume	es:nothing
		clc				; no error
exit:
		.leave
		ret

		; no print queue, something is amiss
noQueue:
		mov	bx, handle dgroup
		call	MemDerefDS
		VSem	ds, [queueSemaphore]	; release it
		stc				; signal error
		jmp	exit

GetArgumentStrings endp


		; These are the CustomDialogBoxFlags used to configure
		; the dialog box
errTypesAndFlags	CustomDialogBoxFlags \
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_TIMEOUT
	<1,CDT_WARNING,GIT_NOTIFICATION,0>,	; PERROR_WARMUP
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; PERROR_SERVICE
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_PAPER_MISFEED
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_NO_PRINTER
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_NO_TONER
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_NO_PAPER
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_OFF_LINE
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_SERIAL_ERR
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_PARALLEL_ERR
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_NETWORK_ERR
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_SOME_PROBLEM
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; PERROR_FATAL
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; PERROR_FILE_SYSTEM_FULL
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; PERROR_FILE_SYSTEM_ERROR
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_NO_SPOOL_FILE
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_NO_PRINT_DRIVER
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_NO_PORT_DRIVER
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_NO_PRINTERS
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_NO_MODE_AVAIL
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; SERROR_CANT_ALLOC_BITMAP
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_NO_VIDMEM_DRIVER
	<1,CDT_NOTIFICATION,GIT_NOTIFICATION,0>,; SERROR_MANUAL_PAPER_FEED
	<1,CDT_NOTIFICATION,GIT_NOTIFICATION,0>,; SERROR_CANT_LOAD_PORT_DRIVER
	<1,CDT_NOTIFICATION,GIT_NOTIFICATION,0>,; SERROR_PORT_BUSY
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; SERROR_TEST_NO_PAPER
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; SERROR_TEST_OFFLINE
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; SERROR_TEST_PARALLEL_ERROR
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_MISSING_COM_PORT
	<1,CDT_QUESTION,GIT_AFFIRMATION,0>,	; SERROR_PRINT_ON_STARTUP
	<1,CDT_ERROR,GIT_NOTIFICATION,0>,	; SERROR_CANNOT_OPEN_FILE
	<1,CDT_ERROR,GIT_MULTIPLE_RESPONSE,0>,	; SERROR_CANNOT_CONVERT_PAGE
	<1,CDT_ERROR,GIT_NOTIFICATION,0>	; SERROR_RESERVATION_ERROR

CheckHack <length errTypesAndFlags eq (SpoolError / 2)>


errOKCancelResponse	StandardDialogResponseTriggerTable <2>
	StandardDialogResponseTriggerEntry <
		ErrOKTriggerMoniker,
		IC_OK
	>
	StandardDialogResponseTriggerEntry <
		ErrCancelTriggerMoniker,
		IC_DISMISS
	>

errOKAsCancelResponse	StandardDialogResponseTriggerTable <1>
	StandardDialogResponseTriggerEntry <
		ErrOKTriggerMoniker,
		IC_DISMISS
	>


		; These are the response trigger lists to be used
		; with UserStandardDialog (used with GIT_MULTIPLE_RESPONSE).
errResponseTriggers	word \
	offset errOKCancelResponse,		; PERROR_TIMEOUT
	0,					; PERROR_WARMUP
	0,					; PERROR_SERVICE
	offset errOKCancelResponse,		; PERROR_PAPER_MISFEED
	offset errOKCancelResponse,		; PERROR_NO_PRINTER
	offset errOKCancelResponse,		; PERROR_NO_TONER
	offset errOKCancelResponse,		; PERROR_NO_PAPER
	offset errOKCancelResponse,		; PERROR_OFF_LINE
	offset errOKCancelResponse,		; PERROR_SERIAL_ERR
	offset errOKCancelResponse,		; PERROR_PARALLEL_ERR
	offset errOKCancelResponse,		; PERROR_NETWORK_ERR
	offset errOKCancelResponse,		; PERROR_SOME_PROBLEM
	offset errOKAsCancelResponse,		; PERROR_FATAL
	0,					; PERROR_FILE_SYSTEM_FULL
	0,					; PERROR_FILE_SYSTEM_ERROR
	0,					; SERROR_NO_SPOOL_FILE
	0,					; SERROR_NO_PRINT_DRIVER
	0,					; SERROR_NO_PORT_DRIVER
	0,					; SERROR_NO_PRINTERS
	0,					; SERROR_NO_MODE_AVAIL
	offset errOKCancelResponse,		; SERROR_CANT_ALLOC_BITMAP
	0,					; SERROR_NO_VIDMEM_DRIVER
	0,					; SERROR_MANUAL_PAPER_FEED
	0,					; SERROR_CANT_LOAD_PORT_DRIVER
	0,					; SERROR_PORT_BUSY
	offset errOKCancelResponse,		; SERROR_TEST_NO_PAPER
	offset errOKCancelResponse,		; SERROR_TEST_OFFLINE
	offset errOKCancelResponse,		; SERROR_TEST_PARALLEL_ERROR
	0,					; SERROR_MISSING_COM_PORT
	0,					; SERROR_PRINT_ON_STARTUP
	0,					; SERROR_CANNOT_OPEN_FILE
	offset errOKAsCancelResponse,		; SERROR_CANNOT_CONVERT_PAGE
	0					; SERROR_RESERVATION_ERROR

CheckHack <length errResponseTriggers eq (SpoolError / 2)>


		; These are offsets to the error message strings to be used
		; with UserStandardDialog.
errMessageStrings	nptr.near \
	ErrorBoxesUI:TimeoutText,		; PERROR_TIMEOUT
	ErrorBoxesUI:WarmupText,		; PERROR_WARMUP
	ErrorBoxesUI:ServiceText,		; PERROR_SERVICE
	ErrorBoxesUI:PaperFeedText,		; PERROR_PAPER_MISFEED
	ErrorBoxesUI:NoPrinterText,		; PERROR_NO_PRINTER
	ErrorBoxesUI:NoTonerText,		; PERROR_NO_TONER
	ErrorBoxesUI:NoPaperText,		; PERROR_NO_PAPER
	ErrorBoxesUI:OffLineText,		; PERROR_OFF_LINE
	ErrorBoxesUI:ComTroubleText,		; PERROR_SERIAL_ERR
	ErrorBoxesUI:ComTroubleText,		; PERROR_PARALLEL_ERR
	ErrorBoxesUI:ComTroubleText,		; PERROR_NETWORK_ERR
	ErrorBoxesUI:SomeProblemText,		; PERROR_SOME_PROBLEM
	ErrorBoxesUI:FatalErrorText,		; PERROR_FATAL
	ErrorBoxesUI:FSFullText,		; PERROR_FILE_SYSTEM_FULL
	ErrorBoxesUI:FSErrorText,		; PERROR_FILE_SYSTEM_ERROR
	ErrorBoxesUI:NoSpoolText,		; SERROR_NO_SPOOL_FILE
	ErrorBoxesUI:DriverLoadText,		; SERROR_NO_PRINT_DRIVER
	ErrorBoxesUI:PortDriverLoadText,	; SERROR_NO_PORT_DRIVER
	ErrorBoxesUI:NoPrintersText,		; SERROR_NO_PRINTERS
	ErrorBoxesUI:NoPrintModeText,		; SERROR_NO_MODE_AVAIL
	ErrorBoxesUI:NoBitmapText,		; SERROR_CANT_ALLOC_BITMAP
	ErrorBoxesUI:NoVidMemText,		; SERROR_NO_VIDMEM_DRIVER
	ErrorBoxesUI:ManualPaperText,		; SERROR_MANUAL_PAPER_FEED
	ErrorBoxesUI:PortDriverLoadText,	; SERROR_CANT_LOAD_PORT_DRIVER
	ErrorBoxesUI:PortBusyText,		; SERROR_PORT_BUSY
	ErrorBoxesUI:NoPaperText,		; SERROR_TEST_NO_PAPER
	ErrorBoxesUI:OffLineText,		; SERROR_TEST_OFFLINE
	ErrorBoxesUI:TestErrorText,		; SERROR_TEST_PARALLEL_ERROR
	ErrorBoxesUI:MissingCOMText,		; SERROR_MISSING_COM_PORT
	ErrorBoxesUI:PrintOnStartText,		; SERROR_PRINT_ON_STARTUP
	ErrorBoxesUI:CannotOpenFileText,	; SERROR_CANNOT_OPEN_FILE
	ErrorBoxesUI:CannotConvertPageText,	; SERROR_CANNOT_CONVERT_PAGE
	ErrorBoxesUI:ReservationError		; SERROR_RESERVATION_ERROR

CheckHack <length errMessageStrings eq (SpoolError / 2)>


		; These are offsets to the error message strings to be used
		; with UserStandardDialog when there are no arguments to be had
errMessageStringsNoArgs	nptr.near \
	ErrorBoxesUI:TimeoutText,		; PERROR_TIMEOUT
	ErrorBoxesUI:WarmupNoArgText,		; PERROR_WARMUP
	ErrorBoxesUI:ServiceNoArgText,		; PERROR_SERVICE
	ErrorBoxesUI:PaperFeedNoArgText,	; PERROR_PAPER_MISFEED
	ErrorBoxesUI:NoPrinterNoArgText,	; PERROR_NO_PRINTER
	ErrorBoxesUI:NoTonerNoArgText,		; PERROR_NO_TONER
	ErrorBoxesUI:NoPaperNoArgText,		; PERROR_NO_PAPER
	ErrorBoxesUI:OffLineNoArgText,		; PERROR_OFF_LINE
	ErrorBoxesUI:ComTroubleNoArgText,	; PERROR_SERIAL_ERR
	ErrorBoxesUI:ComTroubleNoArgText,	; PERROR_PARALLEL_ERR
	ErrorBoxesUI:ComTroubleNoArgText,	; PERROR_NETWORK_ERR
	ErrorBoxesUI:SomeProblemNoArgText,	; PERROR_SOME_PROBLEM
	ErrorBoxesUI:FatalErrorNoArgText,	; PERROR_FATAL
	ErrorBoxesUI:FSFullText,		; PERROR_FILE_SYSTEM_FULL
	ErrorBoxesUI:FSErrorText,		; PERROR_FILE_SYSTEM_ERROR
	ErrorBoxesUI:NoSpoolText,		; SERROR_NO_SPOOL_FILE
	ErrorBoxesUI:DriverLoadNoArgText,	; SERROR_NO_PRINT_DRIVER
	ErrorBoxesUI:PortDriverLoadText,	; SERROR_NO_PORT_DRIVER
	ErrorBoxesUI:NoPrintersText,		; SERROR_NO_PRINTERS
	ErrorBoxesUI:NoPrintModeNoArgText,	; SERROR_NO_MODE_AVAIL
	ErrorBoxesUI:NoBitmapText,		; SERROR_CANT_ALLOC_BITMAP
	ErrorBoxesUI:NoVidMemText,		; SERROR_NO_VIDMEM_DRIVER
	ErrorBoxesUI:ManualPaperText,		; SERROR_MANUAL_PAPER_FEED
	ErrorBoxesUI:PortDriverLoadText,	; SERROR_CANT_LOAD_PORT_DRIVER
	ErrorBoxesUI:PortBusyText,		; SERROR_PORT_BUSY
	ErrorBoxesUI:NoPaperNoArgText,		; SERROR_TEST_NO_PAPER
	ErrorBoxesUI:OffLineNoArgText,		; SERROR_TEST_OFFLINE
	ErrorBoxesUI:TestErrorText,		; SERROR_TEST_PARALLEL_ERROR
	ErrorBoxesUI:MissingCOMText,		; SERROR_MISSING_COM_PORT
	ErrorBoxesUI:PrintOnStartText,		; SERROR_PRINT_ON_STARTUP
	ErrorBoxesUI:CannotOpenFileText,	; SERROR_CANNOT_OPEN_FILE
	ErrorBoxesUI:CannotConvertPageNoArgText,; SERROR_CANNOT_CONVERT_PAGE
	ErrorBoxesUI:ReservationError		; SERROR_RESERVATION_ERROR

CheckHack <length errMessageStringsNoArgs eq (SpoolError / 2)>


		; These are offsets to the first argument strings to be used
		; with UserStandardDialog.
errArg1Strings	nptr.near \
	0,					; PERROR_TIMEOUT
	ErrorBoxesUI:CurPrinterString,		; PERROR_WARMUP
	ErrorBoxesUI:CurPrinterString,		; PERROR_SERVICE
	ErrorBoxesUI:CurPrinterString,		; PERROR_PAPER_MISFEED
	ErrorBoxesUI:CurPrinterString,		; PERROR_NO_PRINTER
	ErrorBoxesUI:CurPrinterString,		; PERROR_NO_TONER
	ErrorBoxesUI:CurPrinterString,		; PERROR_NO_PAPER
	ErrorBoxesUI:CurPrinterString,		; PERROR_OFF_LINE
	ErrorBoxesUI:CurPrinterString,		; PERROR_SERIAL_ERR
	ErrorBoxesUI:CurPrinterString,		; PERROR_PARALLEL_ERR
	ErrorBoxesUI:CurPrinterString,		; PERROR_NETWORK_ERR
	ErrorBoxesUI:CurPrinterString,		; PERROR_SOME_PROBLEM
	ErrorBoxesUI:CurPrinterString,		; PERROR_FATAL
	0,					; PERROR_FILE_SYSTEM_FULL
	0,					; PERROR_FILE_SYSTEM_ERROR
	ErrorBoxesUI:CurSpoolFileString,	; SERROR_NO_SPOOL_FILE
	ErrorBoxesUI:CurPrinterString,		; SERROR_NO_PRINT_DRIVER
	ErrorBoxesUI:CurPortString,		; SERROR_NO_PORT_DRIVER
	0,					; SERROR_NO_PRINTERS
	ErrorBoxesUI:CurPrinterString,		; SERROR_NO_MODE_AVAIL
	0,					; SERROR_CANT_ALLOC_BITMAP
	0,					; SERROR_NO_VIDMEM_DRIVER
	0,					; SERROR_MANUAL_PAPER_FEED
	ErrorBoxesUI:CurPortString,		; SERROR_CANT_LOAD_PORT_DRIVER
	0,					; SERROR_PORT_BUSY
	ErrorBoxesUI:CurPrinterString ,		; SERROR_TEST_NO_PAPER
	ErrorBoxesUI:CurPrinterString ,		; SERROR_TEST_OFFLINE
	0,					; SERROR_TEST_PARALLEL_ERROR
	0,					; SERROR_MISSING_COM_PORT
	0,					; SERROR_PRINT_ON_STARTUP
	0,					; SERROR_CANNOT_OPEN_FILE
	ErrorBoxesUI:CurDocumentString,		; SERROR_CANNOT_CONVERT_PAGE
	0					; SERROR_RESERVATION_ERROR

CheckHack <length errArg1Strings eq (SpoolError / 2)>


		; These are offsets to the second argument strings to be used
		; with UserStandardDialog.
errArg2Strings	nptr.near \
	0,					; PERROR_TIMEOUT
	0,					; PERROR_WARMUP
	0,					; PERROR_SERVICE
	0,					; PERROR_PAPER_MISFEED
	0,					; PERROR_NO_PRINTER
	0,					; PERROR_NO_TONER
	0,					; PERROR_NO_PAPER
	0,					; PERROR_OFF_LINE
	ErrorBoxesUI:CurPortString,		; PERROR_SERIAL_ERR
	ErrorBoxesUI:CurPortString,		; PERROR_PARALLEL_ERR
	ErrorBoxesUI:CurPortString,		; PERROR_NETWORK_ERR
	0,					; PERROR_SOME_PROBLEM
	0,					; PERROR_FATAL
	0,					; PERROR_FILE_SYSTEM_FULL
	0,					; PERROR_FILE_SYSTEM_ERROR
	0,					; SERROR_NO_SPOOL_FILE
	0,					; SERROR_NO_PRINT_DRIVER
	0,					; SERROR_NO_PORT_DRIVER
	0,					; SERROR_NO_PRINTERS
	0,					; SERROR_NO_MODE_AVAIL
	0,					; SERROR_CANT_ALLOC_BITMAP
	0,					; SERROR_NO_VIDMEM_DRIVER
	0,					; SERROR_MANUAL_PAPER_FEED
	0,					; SERROR_CANT_LOAD_PORT_DRIVER
	0,					; SERROR_PORT_BUSY
	0,					; SERROR_TEST_NO_PAPER
	0,					; SERROR_TEST_OFFLINE
	0,					; SERROR_TEST_PARALLEL_ERROR
	0,					; SERROR_MISSING_COM_PORT
	0,					; SERROR_PRINT_ON_STARTUP
	0,					; SERROR_CANNOT_OPEN_FILE
	ErrorBoxesUI:CurPageString,		; SERROR_CANNOT_CONVERT_PAGE
	0					; SERROR_RESERVATION_ERROR

CheckHack <length errArg2Strings eq (SpoolError / 2)>

PrintError	ends
