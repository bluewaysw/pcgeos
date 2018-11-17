COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Shell -- Dialog
FILE:		dialogMain.asm

AUTHOR:		Martin Turon, December 5, 1992

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/05/92        Initial version.

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: dialogMain.asm,v 1.1 97/04/07 10:44:59 newdeal Exp $

=============================================================================@



COMMENT @-------------------------------------------------------------------
			ShellReportFileError
----------------------------------------------------------------------------

DESCRIPTION:	Brings up a dialog box to report all standard file
		errors.   

CALLED BY:	GLOBAL

PASS:		ax	= FileError
		ds:dx	= FileLongName (dx = -1 if not available)
		
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/14/92	Initial version

---------------------------------------------------------------------------@
ShellReportFileError	proc	far
		uses	bx, bp, di, si, es
		.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif

		pushf
		mov	bx, (mask REF_GENERIC_ERROR_AVAILABLE shl 8) \
			    + REEST_FPTR
		cmp	dx, -1
		jne	continue
		mov	bl, REEST_NONE
continue:
		mov	bp, cs
		mov	si, offset ShellGenericError
		segmov	es, cs
		mov	di, offset ShellFileErrorTable	
		call	ShellReportErrorLow
		popf
		.leave
		ret
ShellReportFileError	endp



COMMENT @-------------------------------------------------------------------
		ShellReportError
----------------------------------------------------------------------------

SYNOPSIS:	Displays a dialog box showing error with OK icon.

CALLED BY:	GLOBAL

PASS:		ax 	= error code
		es:di 	= table of ErrorTableEntry to search
		bl	= ReportErrorExtraStringType
			if REEST_FPTR:  ds:dx   = null-terminated string
			if REEST_HPTR:  ^hcx:0  = null-terminated string
			if REEST_OPTR:  ^lcx:dx = null-terminated string
		bh	= ReportErrorFlags
			if REF_GENERIC_ERROR_AVAILABLE:	 
				bp:si = fptr to ErrorTableEntry to use
					if none is found in table.

RETURN:		carry set if error was processed and reported
		carry clear if error not found

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine calls UserStandardDialog, which means the calling 
	thread is blocked.   As a consequence, activity the caller
	normally handles will be postponed until the user responds to
	the dialog.  For example, if GeoManager calls this routine
	from its process thread, folders will no longer update their
	views if exposed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/5/92		Initial version

----------------------------------------------------------------------------@
ShellReportError	proc	far

if ERROR_CHECK
	;
	; Validate that the array is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, es						>
FXIP<		mov	si, di						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>

	;
	; Validate that the error message is not in a movable code segment
	;
FXIP<		test	bh, mask REF_GENERIC_ERROR_AVAILABLE		>
FXIP<		jz	noGeneric					>
FXIP<		push	bx						>
FXIP<		mov	bx, bp						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx						>
FXIP<noGeneric:								>
endif

	;
	; Do the work
	;
		call	ShellReportErrorLow
		ret
ShellReportError	endp

ShellReportErrorLow	proc	near
		uses	di
		.enter

errorLoop:
	;
	; Find entry for given error code
	;
		cmp	es:[di].ETE_error, ERROR_TABLE_LAST_ENTRY
		je	noErrorMatch			; yes, no match
		cmp	es:[di].ETE_error, ax		; does this one match?
		je	foundErrorEntry			; yes, use it
		add	di, size ErrorTableEntry	; move to next entry
		jmp	errorLoop

noErrorMatch:
	;
	; error code not found, put up generic error message
	;
		test	bh, mask REF_GENERIC_ERROR_AVAILABLE
		jz	notHandled
		mov	es, bp
		mov	di, si

foundErrorEntry:
		call	ShellReportErrorTableEntry
		stc
done:
		.leave
		ret

notHandled:
		clc
		jmp	done

ShellReportErrorLow	endp



COMMENT @-------------------------------------------------------------------
			ShellReportErrorTableEntry
----------------------------------------------------------------------------

DESCRIPTION:	Brings up a dialog for the given ErrorTableEntry

CALLED BY:	INTERNAL

PASS:		es:di 	= table of ErrorTableEntry
		bl	= ReportErrorExtraStringType
			if REEST_FPTR:  ds:dx   = null-terminated string
			if REEST_HPTR:  ^hcx:0  = null-terminated string
			if REEST_OPTR:  ^lcx:dx = null-terminated string

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/8/92		Initial version

---------------------------------------------------------------------------@
if _FXIP
idata	segment
endif

nullString	char	NULL

if _FXIP
idata	ends
endif

ShellReportErrorTableEntry	proc	near
		uses	bx, cx, bp, di, ds
extraStringHandle	local	hptr	push	cx
freeExtraString		local	byte
		.enter

		clr	freeExtraString
	;
	; Get fptr to extra string in cx:dx
	;
		cmp	bl, REEST_NONE
		je	noString
		
		cmp	bl, REEST_FPTR
		je	gotString	

		mov	freeExtraString, 1	
		xchg	cx, bx		; cx = ReportErrorExtraStringType
		call	MemLock		; bx = handle of extra string
		mov	ds, ax
		
		cmp	cl, REEST_HPTR
		jne	dereferenceOptr
		clr	dx
		jmp	gotString

dereferenceOptr:
		mov	bx, dx
		mov	dx, ds:[bx]

gotString:
		mov	cx, ds
		jmp	getFlags

noString:
NOFXIP<		mov	cx, cs						>
FXIP<		mov	cx, segment dgroup				>
		mov	dx, offset nullString

getFlags:

	;
	; Calculate proper CustomDialogBoxFlags:
	;	1) assume error dialog which isn't system modal
	;	2) correct if really notification dialog
	;	3) correct if really system modal
	;

		mov	bx, es:[di].ETE_flags		; get flags
		mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
	 		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		test	bx, mask ETF_NOTICE		; not notice, use error
		jz	notNotice
		mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
			    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
notNotice:

		test	bx, mask ETF_SYS_MODAL		; system modal box?
		jz	notModal				; nope
		ornf	ax, mask CDBF_SYSTEM_MODAL
notModal:

	;
	; Get error string in di:bp
	;

		push	bp
		movdw	bxbp, es:[di].ETE_string
		push	ax
		call	MemLock
		mov	ds, ax
		mov_tr	di, ax
		pop	ax
		mov	bp, ds:[bp]

	;
	; set up and call UserStandardDialog
	;	di:bp = error string
	;	cx:dx = filename string (if passed, and needed)
	;	ax    = CustomDialogBoxFlags
	;

		call	ShellCallUserStandardDialog	; put up box
		pop	bp

		call	MemUnlock
	;
	; If extra string needs to be freed, do so.
	;
		tst	freeExtraString
		jz	extraStringFreed
		mov	bx, extraStringHandle
		call	MemFree

extraStringFreed:

		.leave
		ret
ShellReportErrorTableEntry	endp



COMMENT @-------------------------------------------------------------------
			ShellCallUserStandardDialog
----------------------------------------------------------------------------

DESCRIPTION:	Calls UserStandardDialog with the given arguments.

CALLED BY:	INTERNAL - ShellReportErrorTableEntry

PASS:		ax 	= CustomDialogBoxFlags
		di:bp 	= error string
		cx:dx 	= arg 1
		bx:si 	= arg 2

RETURN:		ax 	= InteractionCommand

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	12/8/92		Pulled out of FileMgrs

---------------------------------------------------------------------------@
ShellCallUserStandardDialog	proc	near
	uses	ds
	.enter
	mov	ds, ax
	clr	ax
.assert (offset SDP_helpContext eq offset SDP_customTriggers+4)
	push	ax		; don't care about SDP_helpContext
	push	ax
.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	push	ax		; don't care about SDP_customTriggers
	push	ax
.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	push	bx		; save SDP_stringArg2 (bx:si)
	push	si
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	cx		; save SDP_stringArg1 (cx:dx)
	push	dx
.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	push	di		; save SDP_customString (di:bp)
	push	bp
.assert (offset SDP_customFlags eq 0)
	push	ds		; SDP_customFlags
				; params are on stack
	call	UserStandardDialog
	.leave
	ret
ShellCallUserStandardDialog	endp


;
; Does not handle:
;	ERROR_INSUFFICIENT_MEMORY
;	ERROR_DIFFERENT_DEVICE
; 	ERROR_NO_MORE_FILES
;	ERROR_SHARING_VIOLATION
;	ERROR_ALREADY_LOCKED
;	ERROR_SHARING_OVERFLOW
;	ERROR_NETWORK_CONNECTION_BROKEN
;	ERROR_NETWORK_ACCESS_DENIED
;	ERROR_NETWORK_NOT_LOGGED_IN
;	ERROR_SHORT_READ_WRITE
;	ERROR_ARGS_TOO_LONG
;	ERROR_DISK_UNAVAILABLE
;	ERROR_DISK_STALE
;	ERROR_FILE_FORMAT_MISMATCH
;	ERROR_CANNOT_MAP_NAME
;	ERROR_DIRECTORY_NOT_EMPTY
;	ERROR_ATTR_NOT_SUPPORTED
;	ERROR_ATTR_NOT_FOUND
;	ERROR_ATTR_SIZE_MISMATCH
;	ERROR_ATTR_CANNOT_BE_SET
;	ERROR_CANNOT_MOVE_DIRECTORY
;	ERROR_PATH_TOO_LONG
;	ERROR_ARGS_INVALID
;	ERROR_CANNOT_FIND_COMMAND_INTERPRETER
;	ERROR_NO_TASK_DRIVER_LOADED
;	ERROR_LINK_ENCOUNTERED
;	ERROR_NOT_A_LINK
;	ERROR_TOO_MANY_LINKS
;
ShellFileErrorTable	ErrorTableEntry		\
	<ERROR_UNSUPPORTED_FUNCTION, 	FileUnsupportedFunction, 	0>,
	<ERROR_FILE_NOT_FOUND,		FileNotFoundErrStr, 		0>,
	<ERROR_PATH_NOT_FOUND,		PathNotFoundErrStr, 		0>,
	<ERROR_TOO_MANY_OPEN_FILES,	NotEnoughMemoryErrStr, 		0>,
	<ERROR_ACCESS_DENIED,		AccessDeniedErrStr, 
					mask ETF_SHOW_EXTRA_STRING>,
	<ERROR_INVALID_DRIVE,		InvalidVolumeErrStr,		0>,
	<ERROR_IS_CURRENT_DIRECTORY,	IsCurrentDirectoryErrStr, 
					mask ETF_SHOW_EXTRA_STRING>,
	<ERROR_WRITE_PROTECTED,		WriteProtectedErrStr, 		0>,
	<ERROR_UNKNOWN_VOLUME,		UnknownVolumeErrStr, 		0>,
	<ERROR_DRIVE_NOT_READY,		DriveNotReadyErrStr, 		0>,
	<ERROR_CRC_ERROR,		DriveNotReadyErrStr, 		0>,
	<ERROR_SEEK_ERROR,		DriveNotReadyErrStr, 		0>,
	<ERROR_UNKNOWN_MEDIA,		DriveNotReadyErrStr, 		0>,
	<ERROR_SECTOR_NOT_FOUND,	DriveNotReadyErrStr, 		0>,
	<ERROR_WRITE_FAULT,		DriveNotReadyErrStr, 		0>,
	<ERROR_READ_FAULT,		DriveNotReadyErrStr, 		0>,
	<ERROR_GENERAL_FAILURE,		DriveNotReadyErrStr, 		0>,
	<ERROR_INVALID_NAME,		InvalidNameErrStr, 		0>,
	<ERROR_FILE_EXISTS,		FileExistsErrStr, 		0>,
	<ERROR_DOS_EXEC_IN_PROGRESS,	DosExecInProgressErrStr,
					mask ETF_SHOW_EXTRA_STRING>,
	<ERROR_FILE_IN_USE,		AccessDeniedErrStr,
					mask ETF_SHOW_EXTRA_STRING>,
	<ERROR_DIRECTORY_NOT_EMPTY,	DirNotEmptyErrStr,
					mask ETF_SHOW_EXTRA_STRING>,
	<ERROR_PATH_TOO_LONG,		PathTooLongErrStr, 		0>,
	<ERROR_TOO_MANY_LINKS,		TooManyLinks, 			0>

ShellGenericError	ErrorTableEntry 	\
	<ERROR_TABLE_LAST_ENTRY,	GenericErrStr, 0>
