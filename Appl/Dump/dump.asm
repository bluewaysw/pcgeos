COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeey Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		dump
FILE:		dump.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/89		Initial version

DESCRIPTION:
	This file contains a screen dump utility. It hangs out until activated
	by typing the print-screen sequence.

	$Id: dump.asm,v 1.1 97/04/04 15:36:36 newdeal Exp $

------------------------------------------------------------------------------@

include dump.def

;------------------------------------------------------------------------------
;			File-specific Include Files
;------------------------------------------------------------------------------
include lmem.def
;include event.def
;include keyboard.def
;include mouse.def	; For MSG_META_KBD_CHAR
include gstring.def	; For monikers (gstring macros)...
include initfile.def
;include character.def	; For .rdef strings
include system.def	; For ExitFlags et al
include disk.def	; For resolving disk handle in DFS

;include coreBlock.def

; NEW .def files for 2.0

include win.def
include Objects/inputC.def
include Objects/gFSelC.def
include Internal/im.def
include	Internal/videoDr.def
UseLib Objects/vTextC.def
UseLib Objects/vLTextC.def
UseLib Objects/Text/tCtrlC.def

;------------------------------------------------------------------------------
;			Resource Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
MAX_DUMP	= 100	; highest dumpnumber allowed

_INHOUSE_RESTRICTIONS	= FALSE		; TRUE if should enforce inHouse key
;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include	dump.rdef

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	DumpClass	mask CLASSF_NEVER_SAVED
	DumpApplicationClass

;
; Monitor structure required/used by IM
; 
monitor		Monitor	<>

;
; Pointer to output-format descriptor.
;
dumpProcs	fptr.DumpProcs	ClipboardProcs

;
; Tables for setting the format.
;
allProcs	fptr.DumpProcs	ClipboardProcs, EPSProcs, TiffProcs, \
				EPSTiffProcs, FPSProcs, PCXProcs,
				GIFProcs, JPEGProcs, BMPProcs

;
; Logging variables
;
logFile		hptr	0		; File handle for annotation file

;
; Instance data for the program -- all variables saved to and restored from
; state file.
;
procVars	DumpInstance	<,		; Meta instance
	DF_CLIPBOARD,		; Current format
	0,			; Dump number
	BB_FALSE,		; Logging disabled
	FILE_CREATE_TRUNCATE,	; Do not append
	;
	; PostScript vars
	;
	BB_FALSE,		; Include field window
	1,			; Single-page output
	BB_FALSE,		; Portrait mode by default
	PSCS_GREY,		; Map to greyscale by default
	0,			; these 4 0`s will get intiliazed
	0,			; according to which country`s version
	0,			; one is running this under
	0,			;
	
	;
	; Tiff vars
	;
	TCS_PALETTE,		; Dump color as color
	TCS_NONE		; No image compression
	
>


inputCatString		char	"input", 0
blinkingCursorString 	char	"blinking cursor", 0
idata	ends

;---------------------------------------------------

udata	segment

; dumpName serves two purposes. In DumpPreFreeze, it fetches the file
; selector's current path, which is then used by DumpOpenFile to set
; the dumper's current directory. Once that's done, the actual name of the
; dump file is built from "filename" and the current dump number into the
; dumpName buffer.

dumpName	PathName		; Buffer for filename, including 1
					;  chars null-termination
dumpDiskHandle	hptr			; Disk on which dumpName lies

filename	PathName		; Buffer for fetching the user-
					;  specified name
filenameLength	word			; Length of "Dump Name:" fetched.

;
; Pointer to driver of area being dumped (for getting screen characteristics)
;
vidDriver	fptr.DevInfo

file		hptr	?	; Handle of file being written

sliceHeight	word		; Calculated slice height for current
				;  image. All but the last slice are guaranteed
				;  to be this many rows. The height is
				;  calculated to yield slices of about 8K
				;  in length (this is mostly for TIFF).

curDumpFunc	DumpMessages	; method that prompted this dump

udata	ends

global TESTCOLOR:far

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

CommonCode segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open ourselves for interactive use.

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds	= dgroup
		cx	= AppAttachFlags (ignored)
		dx	= handle of AppLaunchBlock (ignored)
		bp	= handle of block from which to restore state
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dumpInHouseThings	optr	EnableAll, RemoveFromExpressTrigger, ReturnToExpressTrigger

if _INHOUSE_RESTRICTIONS
dumpCategory	char	'dump', 0
inhouseKey	char	'inhouse', 0
endif

DumpOpenApplication method	DumpClass, MSG_GEN_PROCESS_OPEN_APPLICATION
		.enter

		push	ax, bx, cx, dx

	; allow only clipboard if colors <= 256   jfh 2/20/02
		call TESTCOLOR

	; get the customized papersizes to initialize the program
		push	si, ds
		sub	sp, size PageSizeReport
		segmov	ds, ss
		mov	si, sp			; ds:si <- PageSizeReport
		call	SpoolGetDefaultPageSizeInfo
		mov	ax, ds:[si].PSR_width.low
		mov	bx, ds:[si].PSR_height.low
		mov	ds:[procVars].DI_psPageWidth, ax
		mov	ds:[procVars].DI_psPageHeight, bx
		add	sp, size PageSizeReport
		
	;
	; Fetch the PS image height and width from the two ranges and
	; convert the appropriately.
	; 
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	si, offset WidthRange
		mov	bx, handle WidthRange
		mov	di, mask MF_CALL
		call	ObjMessage
		call	DumpPSSetImageWidth

		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	si, offset HeightRange
		mov	bx, handle HeightRange
		mov	di, mask MF_CALL
		call	ObjMessage
		call	DumpPSSetImageHeight

		pop	si, ds
		mov	di, ds:[si]		; retrieve di
	;
	; Switch to the document directory as the logical place to store
	; screen dumps.
	;
		mov	ax, SP_DOCUMENT
		call	FileSetStandardPath
	;
	; Insert a monitor into the input chain so we see when the
	; user presses PrtScr. We place the monitor immediately after
	; the scan conversion so there's no chance of the code going
	; anywhere...
	; 
		mov	bx, offset monitor
		mov	al, ML_DRIVER+1
		mov	cx, segment InputMonitor
		mov	dx, offset InputMonitor
		
		call	ImAddMonitor

		pop	ax, bx, cx, dx

	;
	; See if we've got any state to restore...
	;
		tst	bp
		jz	none		; Nope
		
		push	ds		; Save class segment for calling super
		mov	bx, bp
		call	MemLock
		jc	fail
	;
	; Copy entire state block to our own.
	;
		push	cx
		mov	ds, ax
		mov	cx, size DumpInstance
		clr	si
		mov	di, offset procVars
		rep	movsb
		pop	cx
	;
	; Unlock the state block
	;
		call	MemUnlock
		pop	ds
		
	;
	; Now act on whatever parts of the new state require immediate
	; attention...
	;
		
		;
		; First set the procedure table given the format number. We
		; assume the objects will reflect the proper state by restoring
		; themselves from the state file...
		;
		mov	si, ds:procVars.DI_format
		mov	ax, ds:allProcs[si].offset
		mov	ds:dumpProcs.offset, ax
		mov	ax, ds:allProcs[si].segment
		mov	ds:dumpProcs.segment, ax
fail:
		pop	cx, dx, bp
		mov	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
passItUp:
		;
		; Pass the message off to the superclass to do the rest of
		; things
		;
		mov	di, offset DumpClass
		CallSuper	MSG_GEN_PROCESS_OPEN_APPLICATION
		.leave
		ret
LocalDefNLString nullStr <0>

none:
		push	ax, bx, cx, dx, bp, si, ds
	;
	; If not restoring from state, set default destination directory
	; to be SP_DOCUMENT.
	; 
		mov	cx, cs
		mov	dx, offset nullStr
		mov	bp, SP_DOCUMENT
		mov	bx, handle DirSelect
		mov	si, offset DirSelect
		mov	ax, MSG_GEN_PATH_SET
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Set various in-house things usable or not.
	;
if _INHOUSE_RESTRICTIONS
		segmov	ds, cs, cx
		mov	si, offset dumpCategory
		mov	dx, offset inhouseKey
		call	InitFileReadBoolean
		jc	notInHouse
		tst	ax
		jz	notInHouse
notInHouse:
		mov	ax, MSG_GEN_SET_NOT_USABLE
setInHouseThingies:
else
		mov	ax, MSG_GEN_SET_USABLE
endif ; _INHOUSE_RESTRICTIONS

		mov	cx, length dumpInHouseThings
		mov	si, offset dumpInHouseThings
sIHLoop:
		xchg	bx, ax
		lodsw	cs:
		xchg	dx, ax
		lodsw	cs:
		xchg	bx, ax
		push	si
		push	ax
		push	cx
		mov	si, dx
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		pop	cx
		pop	ax
		pop	si
		loop	sIHLoop
		
		pop	ax, bx, cx, dx, bp, si, ds
		jmp	passItUp
DumpOpenApplication endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish off our interactive mode.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		ds=es=group
RETURN:		cx	= handle of block to save
DESTROYED:	ax, cx, es, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCloseApplication	method	DumpClass, MSG_GEN_PROCESS_CLOSE_APPLICATION
		.enter
	;
	; Remove the monitors we installed
	;
		mov	bx, offset monitor
		mov	al, mask MF_REMOVE_IMMEDIATE
		call	ImRemoveMonitor

	;
	; Allocate a block o' memory for the state
	;
		mov	ax, size DumpInstance
		mov	cx, ALLOC_DYNAMIC_LOCK
		clr	bx		; clear bx in case of error
		call	MemAlloc
		jc	error
		
		;
		; Transfer all of procVars to the state block for
		; next time -- it's the only state we need.
		;
		mov	es, ax
		clr	di
		mov	si, offset procVars
		mov	cx, size DumpInstance
		rep	movsb

		call	MemUnlock
error:
		mov	cx, bx
		.leave
		ret
DumpCloseApplication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpNoBlink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off the blinking cursor control in the [input] section
		and tell the user the system must restart. When s/he
		acknowledges, restart the system.

CALLED BY:	MSG_DUMP_NO_BLINK
PASS:		es=ds=dgroup
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpNoBlink	method	DumpClass, MSG_DUMP_NO_BLINK
		.enter
	;
	; Turn off the blinking cursor.
	;
		mov	cx, ds
		mov	si, offset inputCatString
		mov	dx, offset blinkingCursorString
		clr	ax		; FALSE
		call	InitFileWriteBoolean
	;
	; Restart the system.
	;
		mov	ax, SST_RESTART
		call	SysShutdown
		.leave
		ret
DumpNoBlink	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpBlinkOk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-enable the blinking cursor the next time GEOS is run.

CALLED BY:	MSG_DUMP_BLINK_OK
PASS:		ds=es=dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpBlinkOk	method	DumpClass, MSG_DUMP_BLINK_OK
		.enter
	;
	; Turn on the blinking cursor.
	;
		mov	cx, ds
		mov	si, offset inputCatString
		mov	dx, offset blinkingCursorString
		mov	ax, TRUE
		call	InitFileWriteBoolean
		.leave
		ret
DumpBlinkOk	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpBanish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a MSG_DUMP_BANISH method sent to us by taking down
		our primary.

CALLED BY:	MSG_DUMP_BANISH
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpBanish	method	DumpClass, MSG_DUMP_BANISH
		.enter
		mov	bx, handle DumpPrimary
		mov	si, offset DumpPrimary
	;
	; First take it off the screen so it gives up the app exclusive etc..
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
	;
	; Set the application non-focusable and non-targetable.
	; 
		mov	ax, MSG_GEN_SET_ATTRS
		mov	bx, handle DumpApp
		mov	cx, mask GA_TARGETABLE shl 8	; clear this bit
		mov	si, offset DumpApp
		clr	di
		call	ObjMessage
		mov	ax, MSG_GEN_APPLICATION_SET_STATE
		clr	cx
		mov	dx, mask AS_FOCUSABLE or mask AS_MODELABLE
		clr	di
		call	ObjMessage
		.leave
		ret
DumpBanish	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpDoStandardChunkDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call UserStandardDialog passing strings described by
		optrs, rather than fptrs.

CALLED BY:	?
PASS:		ax	= CustomDialogBoxFlags

		^ldi:bp	= format string (always passed)
		^lcx:dx	= first string argument
		;
		;	bx,si = NOTHING!!!! this routine does not take
		;	a second string argument...
		;
RETURN:		ax	= StandardDialogBoxResponses
DESTROYED:	bx, cx, dx, si, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpDoStandardChunkDialog	proc	far	uses ds

		.enter
		push	di
		push	cx

		push	ax			; save flags

		xchg	di, bx			; Lock DI
		call	MemLock
		xchg	ax, di			; ax <- bx, di <- di's segment
		xchg	ax, bx			; bx <- bx
		
		xchg	cx, bx			; Lock CX
		call	MemLock
		xchg	ax, cx			; ax <- bx, cx <- cx's segment
;		xchg	ax, bx			; bx <- bx
		
;		call	MemLock
;		xchg	ax, bx			; bx <- bx's segment
		
		mov	ds, di
		mov	bp, ds:[bp]		; di:bp <- ^ldi:bp

		mov	ds, bx
		mov	si, ds:[si]		; bx:si <- ^lbx:si

		xchg	dx, si
		mov	ds, cx
		mov	si, ds:[si]		; cx:dx <- ^lcx:dx
		xchg	dx, si

		pop	ax			; ax <- saved flags

		mov	bx, bp
		sub	sp, size StandardDialogParams
		mov	bp, sp

		mov	ss:[bp].SDP_customFlags, ax
		mov	ss:[bp].SDP_customString.segment, di
		mov	ss:[bp].SDP_customString.offset, bx
		mov	ss:[bp].SDP_stringArg1.segment, cx
		mov	ss:[bp].SDP_stringArg1.offset, dx
		mov	ss:[bp].SDP_stringArg2.segment, cx
		mov	ss:[bp].SDP_stringArg2.offset, dx
		clr	ss:[bp].SDP_customTriggers.segment
		clr	ss:[bp].SDP_customTriggers.offset
		clr	ss:[bp].SDP_helpContext.segment
		
		;
		;	USD pops all this crap off the stack...
		;
		call	UserStandardDialog

		
;		pop	bx			; bx
;		call	MemUnlock
		pop	bx			; cx
		call	MemUnlock
		pop	bx			; di
		call	MemUnlock
		.leave
		ret
DumpDoStandardChunkDialog	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the user of an error.

CALLED BY:	EXTERNAL
PASS:		bp	= chunk of error string in Strings resource
RETURN:		nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpError	proc	far	uses bx, si, ax, di, dx, cx

		.enter
		call	GeodeGetProcessHandle
		cmp	bx, handle 0
		jne	shipToOurselves

		; make the thing system modal, in case we're banished or
		; behind things.
		mov	ax, mask CDBF_SYSTEM_MODAL or \
				(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
				(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
		mov	di, handle Strings
		mov	cx, di
		mov	bx, di
		call	DumpDoStandardChunkDialog
done:
		.leave
		ret

shipToOurselves:
		mov	bx, handle 0
		mov	ax, MSG_DUMP_NOTIFY_ERROR
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	done
DumpError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpNotifyError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the user, on our own time, of something s/he's done
		wrong.

CALLED BY:	MSG_DUMP_NOTIFY_ERROR
PASS:		ds = es = dgroup
		bp	= chunk in Strings of error message.
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpNotifyError	method dynamic DumpClass, MSG_DUMP_NOTIFY_ERROR
		.enter
		call	DumpError
		.leave
		ret
DumpNotifyError	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpPreFreeze
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle interaction with the UI before freezing the screen.

CALLED BY:	InputFreeze
PASS:		ds	= dgroup
RETURN:		carry set if screen shouldn't be frozen
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpPreFreeze	proc	far
		uses	cx, dx, si, di, bp
		.enter
	;
	; Fetch the current path and set it as our own.
	;
		mov	dx, ds
		mov	bp, offset dumpName
		mov	cx, size dumpName
		mov	ax, MSG_GEN_PATH_GET
		mov	bx, handle DirSelect
		mov	si, offset DirSelect
		mov	di, mask MF_CALL
		call	ObjMessage
		jcxz	directoryNotSelected
		mov	ds:[dumpDiskHandle], cx
	;
	; Fetch the file name for dumping.
	;
		mov	bx, handle NameText
		mov	si, offset NameText
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		mov	dx, segment filename
		mov	bp, offset filename
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		jcxz	filenameMissing
		mov	ds:[filenameLength], cx
	;
	; Call the output module before we freeze the screen, to give it a
	; chance to do Good Things.
	; 
		push	ds
		lds	bx, ds:[dumpProcs]
		mov	ax, ds:[bx].DP_preFreeze.offset
		mov	bx, ds:[bx].DP_preFreeze.segment
		tst	bx
		jz	donePopDS
		call	ProcCallFixedOrMovable
donePopDS:
		pop	ds
done:
		.leave
		ret

filenameMissing:
		mov	bp, offset filenameMissingStr
		call	DumpError
		stc
		jmp	done

directoryNotSelected:
		mov	bp, offset noDirSelected
		call	DumpError
		stc
		jmp	done
DumpPreFreeze	endp

;----------------------------------------------------------------------------
;
;			    SETUP ROUTINES
;
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the output format for the next dump

CALLED BY:	MSG_DUMP_SET_FORMAT
PASS:		ds	= dgroup
		cx	= DumpFormats for new format
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		Use the DumpFormats to index into our table of procedure
			tables and set the current set of procs.
		Record the format in our state block.
		Use the format to decide what to set active and inactive.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dumpUIEnable	optr	PostscriptBox, NumPagesRange, TiffBox, PaperControl,
			DumpNumberRange, NameText, DirSelect, AnnotateGroup

if length dumpUIEnable ne width DumpUIEnable
ErrMessage <DumpUIEnable doesn't match dumpUIEnable, goober>
endif

DumpSetFormat	method	DumpClass, MSG_DUMP_SET_FORMAT
		.enter
		mov	ds:procVars.DI_format, cx; Save number for state-save
		;
		; Point dumpProcs at the proper procedure table.
		;
		mov	si, cx
		mov	ax, ds:allProcs[si].segment
		mov	ds:dumpProcs.segment, ax
		mov	es, ax
		mov	ax, ds:allProcs[si].offset
		mov	ds:dumpProcs.offset, ax
		mov	si, ax

		;
		; Now enable the things that want to be enabled and disable
		; the ones that don't...
		;
		mov	di, es:[si].DP_enable
		mov	cx, width DumpUIEnable
		mov	si, offset dumpUIEnable
enableLoop:
		;
		; Fetch the destination of the method in bx:si
		lodsw	cs:
		xchg	dx, ax			; 1-byte move
		lodsw	cs:
		xchg	bx, ax			; 1-byte move
		push	si
		mov	si, dx
		
		;
		; Figure the method to send.
		;
		mov	ax, MSG_GEN_SET_ENABLED	; Assume enable
		shr	di
		jc	10$				; Correct
		mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
		;
		; Send the message -- neither need nor want return value.
		;
		push	di
		push	cx
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_NOW		; Update instantly, if not
						;  sooner
		call	ObjMessage
		;
		; Recover loop variables and loop
		;
		pop	cx
		pop	di
		pop	si
		loop	enableLoop
		.leave
		ret
DumpSetFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpEnableAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable all our UI components so someone can make screen
		dumps of them.

CALLED BY:	MSG_DUMP_ENABLE_ALL
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpEnableAll	method dynamic DumpClass, MSG_DUMP_ENABLE_ALL
		.enter
		mov	cx, length dumpUIEnable
		mov	si, offset dumpUIEnable
enableLoop:
		lodsw	cs:		; ax <- chunk
		xchg	dx, ax		; (1-byte inst)
		lodsw	cs:		; ax <- handle
		xchg	bx, ax
		push	si
		mov	si, dx		; ^lbx:si <- object
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		clr	di		; no need for return value
		push	cx
		call	ObjMessage
		pop	cx
		pop	si
		loop	enableLoop
		.leave
		ret
DumpEnableAll	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpSetOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the output orientation for postscript formats.

CALLED BY:	MSG_PS_ORIENTATION
PASS:		cx	= -1 to set landscape mode, 0 to set portrait mode
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DumpSetOrientation method DumpClass, MSG_PS_ORIENTATION
		.enter
		mov	ds:procVars.DI_psRotate?, cl
		.leave
		ret
DumpSetOrientation endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpSetNumPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the desired number of copies for full-page postscript
		mode

CALLED BY:	MSG_PS_NUM_PAGES
PASS:		dx.cx	= number of copies desired (fraction ignored)
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpSetNumPages	method 	DumpClass, MSG_PS_NUM_PAGES
		.enter
		mov	ds:procVars.DI_psNumPages, dl
		.leave
		ret
DumpSetNumPages	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpSetNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the number of the next dump.

CALLED BY:	MSG_DUMP_SET_NUMBER
PASS:		dx.cx	= number of next dump
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpSetNumber	method 	DumpClass, MSG_DUMP_SET_NUMBER
		.enter
		mov	ds:procVars.DI_dumpNumber, dl
		.leave
		ret
DumpSetNumber	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpPSSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color mapping for the next postscript dump

CALLED BY:	MSG_PS_SET_COLOR
PASS:		cx	= PSColorScheme
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpPSSetColor	method 	DumpClass, MSG_PS_SET_COLOR
		.enter
		mov	ds:procVars.DI_psColorScheme, cx
		.leave
		ret
DumpPSSetColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpPSSetImageWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the desired final width of the image

CALLED BY:	MSG_PS_SET_IMAGE_WIDTH
PASS:		ds = es = dgroup
		dx.cx	= width of image, in points
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpPSSetImageWidth method DumpClass, MSG_PS_SET_IMAGE_WIDTH
		.enter
	; XXX: convert to points*8 to change as little as possible
	; -- ardeb 7/7/92
		shl	cx
		rcl	dx
		shl	cx
		rcl	dx
		shl	cx
		rcl	dx
		mov	ds:[procVars].DI_psImageWidth, dx
		.leave
		ret
DumpPSSetImageWidth endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpPSSetImageHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the desired final height of the image

CALLED BY:	MSG_PS_SET_IMAGE_HEIGHT
PASS:		ds = es = dgroup
		dx.cx	= image height, in points
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpPSSetImageHeight method DumpClass, MSG_PS_SET_IMAGE_HEIGHT
		.enter
	; XXX: convert to points*8 to change as little as possible
	; -- ardeb 7/7/92
		shl	cx
		rcl	dx
		shl	cx
		rcl	dx
		shl	cx
		rcl	dx
		mov	ds:[procVars].DI_psImageHeight, dx
		.leave
		ret
DumpPSSetImageHeight endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpTiffSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color scheme to use for the next TIFF dump

CALLED BY:	MSG_TIFF_SET_COLOR
PASS:		cx	= TiffColorScheme
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpTiffSetColor method	DumpClass, MSG_TIFF_SET_COLOR
		.enter
		mov	ds:[procVars].DI_tiffColorScheme, cx
		.leave
		ret
DumpTiffSetColor endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpTiffSetCompression
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the compression scheme to use for the next TIFF dump

CALLED BY:	MSG_TIFF_SET_COMPRESSION
PASS:		cx	= TiffCompressionScheme
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpTiffSetCompression method	DumpClass, MSG_TIFF_SET_COMPRESSION
		.enter
		mov	ds:[procVars].DI_tiffCompression, cx
		.leave
		ret
DumpTiffSetCompression endp

;----------------------------------------------------------------------------
;
;			  ANNOTATION/LOGGING
;
;----------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpSetAnnotationStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Field a change to the annotation list

CALLED BY:	MSG_DUMP_ANNOTATION_STATUS
PASS:		ds	= dgroup
		cx	= DumpAnnotationStatus
RETURN:		Nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version
	ardeb	5/6/92		Adapted to GenItemGroup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpSetAnnotationStatus	method	DumpClass, MSG_DUMP_ANNOTATION_STATUS
		.enter
		mov	al, FILE_CREATE_TRUNCATE
		test	cx, mask DAS_APPEND
		jz	setAppendMode
		mov	al, FILE_CREATE_NO_TRUNCATE
setAppendMode:
		mov	ds:[procVars].DI_logAppend?, al
		
		mov	dx, MSG_GEN_SET_NOT_ENABLED
		clr	ax
		test	cx, mask DAS_ENABLED
		jz	10$
		mov	dx, MSG_GEN_SET_ENABLED
		dec	ax
10$:
		mov	ds:procVars.DI_logging?, al
		;
		; If just turned logging off, close down any file we had
		; open.
		;
		jnz	tweakUI
		tst	ds:logFile
		jz	tweakUI
		xchg	ds:logFile, ax
		mov	bx, ax
		mov	al, FILE_NO_ERRORS
		call	FileClose
tweakUI:
	;
	; Enable or disable the Append and Log Name objects based on whether
	; annotation is turned on or off.
	; 
		mov_tr	ax, dx
		mov	bx, handle AppendSelect
		mov	si, offset AppendSelect
		push	ax
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		pop	ax
		push	ax
		mov	si, offset AnnotateFile
		clr	di
		call	ObjMessage
		pop	ax
		mov	si, offset TxtGlyph
		clr	di
		call	ObjMessage

		.leave
		ret
DumpSetAnnotationStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpOpenLog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the log file is open and return its handle

CALLED BY:	DumpWriteNotes
PASS:		ds	= dgroup
RETURN:		bx	= file handle
		Carry set if error opening file
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpOpenLog	proc	near	uses cx, dx, si, di, ax, bp
		.enter

	;
	; Fetch the name of the log file from the object
	;
		mov	dx, ds
		mov	bp, offset filename
		mov	bx, handle AnnotateFile
		mov	si, offset AnnotateFile
		mov	di, mask MF_CALL
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage
		stc
		jcxz	done			; => Name not given

	;
	;  Add a .TXT to the end of the thing
	;
		add	bp, cx
		mov	ds:[bp], 'T' shl 8 or '.'
		mov	ds:[bp+2], 'T' shl 8 or 'X'
		mov	{byte}ds:[bp+4], 0

	;
	;  Create the damn thing.
	;
		mov	ah, ds:procVars.DI_logAppend?
		ornf	ah, mask FCF_NATIVE
		mov	al, FILE_DENY_W or FILE_ACCESS_W
		mov	cx, FILE_ATTR_NORMAL
		mov	dx, offset filename	; XXX: trust return value?
		call	FileCreate
		mov	bx, ds:logFile
		jc	checkCurrent

	;
	;  Close the old file, if any
	;
		tst	bx
		jz	recordNew

		push	ax			;save new file
		mov	al, FILE_NO_ERRORS
		call	FileClose
		pop	ax

recordNew:
		mov	ds:logFile, ax
	;
	; Seek to the end of the file, in case appending was
	; requested.
	;
		mov_tr	bx, ax
		clr	cx
		mov	dx, cx
		mov	al, FILE_POS_END
		call	FilePos
done:
		.leave
		ret
checkCurrent:
	;
	;  If there's already a log file open, then it's likely that we
	;  tried to open it again. No problem.
	;
		tst_clc	bx
		jnz	done
		stc
		jmp	done
		
DumpOpenLog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpDismissAnnotation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If not in "retain-last-annotation" mode, bring down the
		annotation box.

CALLED BY:	DumpWriteNotes, DumpAbort
PASS:		Nothing
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpDismissAnnotation	proc	near	uses bx, si, di, ax, bp
		.enter
		mov	bx, handle AnnotationBox
		mov	si, offset AnnotationBox
		mov	cx, IC_DISMISS
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
DumpDismissAnnotation	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpWriteNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the text currently in the annotation text object
		and write it to the log file.

CALLED BY:	MSG_WRITE_NOTES
PASS:		ds	= dgroup
		es	= dgroup
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		All text written is in SBCS.
		All NewLines are converted into CR-LF pairs.
		The DBCS version of char convert requires an input
		  buffer and a seperate output buffer.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* The annotation file is always written using SBCS.
		* In DBCS a MemAlloc() buffer should be allocated.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version
	witt	10/ 9/93	Added DBCS support (but it ain't pretty)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

separator	char	"\r\n================\r\n"

DumpWriteNotes	method	DumpClass, MSG_WRITE_NOTES
SBCS<expandBuf	local	MAX_NOTES_TEXT_LENGTH*2 dup(char)	>
DBCS<expandBuf	local	MAX_NOTES_TEXT_LENGTH*2 dup(wchar)	>
fileHandle	local	hptr

; CheckHack< (offset expandBuf) eq 0 >		; (**)
CheckHack< (size expandBuf) > (size dumpName) >
		.enter
		;
		; Make sure the log file is open.
		;
		call	DumpOpenLog
		LONG jc	openError
		;
		; Write the file-separator string out first
		;
		push	ds
		segmov	ds, cs, dx
		mov	dx, offset separator
		mov	cx, size separator
		clr	al
		call	FileWrite
		pop	ds
		LONG jc	writeError
		
		;
		; Write the dumpfile's name to the log.
		;
if DBCS_PCGEOS
		push	ds
		;
		;  Now convert filename from DBCS to Dos charset.
		;	(From dumpName to expandBuf)
		;
		mov	dx, offset ds:dumpName	; ds:dx DBCS filename
		segmov	es, ss, ax	; es:di = actual DOS filename.
		lea	di, ss:[expandBuf]
		mov	cx, length expandBuf
		mov	ax, FEA_DOS_NAME
		call	FileGetPathExtAttributes
		jc	writeErr_popDS		; Hmmm... FSD isn't DOS!!
		;
		;  expandBuf (es:di) now holds SBCS DOS filename.
		;
		segmov	ds, es, ax		; ds:dx -> buffer
		lea	di, expandBuf
else
					; First figure the length of the
		mov	di, offset dumpName	;  null-terminated dumpName
endif
		mov	dx, di		; start of buffer for FileWrite()
		mov	cx, -1
		clr	ax
		repne	scasb
		neg	cx		; gives 2 more than actual # chars
					;  in the string, which is what we
					;  want since we're adding \r\n to the
					;  end.
		mov	ds:[di-1], '\r' or ('\n' shl 8)	; may overflow into
							;  filename buffer

		call	FileWrite		; ds:dx -> buffer
SBCS< 		mov	{byte}ds:[di-1], 0	;; why is this here? witt >
DBCS<writeErr_popDS: 	pop	ds						>
		assume	ds:dgroup
		LONG jc	writeError

		;
		; Now fetch the note text and write it out.
		;
		mov	fileHandle, bx
		mov	bx, handle NotesText
		mov	si, offset NotesText
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		clr	dx		; Allocate me a block, please
		mov	di, mask MF_CALL
		push	bp
		call	ObjMessage
		pop	bp
	
		;
		; Lock down the text
		;
		mov	bx, cx		; bx <- handle
		mov_tr	cx, ax		; cx <- length
		call	MemLock
		
		;
		; Write it all out -- cx contains the number of bytes in the
		; text.
		;
		push	ds
		mov	ds, ax
		;
		; Convert carriage returns into return-linefeed pairs
		;
		segmov	es, ss, di
		lea	di, expandBuf
		mov	dx, di
		clr	si
		jcxz	itBeExpanded
expandLoop:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '\r'	; Carriage return?
		jne	10$
		LocalPutChar	esdi, ax	; Store return
		LocalLoadChar	ax, '\n'	;  and replace with newline
10$:
		LocalPutChar	esdi, ax
		loop	expandLoop

itBeExpanded:
		sub	di, bp		; Figure number of bytes to write
		add	di, size expandBuf	; (**)
		mov	cx, di		; cx <- count

if DBCS_PCGEOS
		clr	ax			; you've been terminated.
		LocalPutChar	esdi, ax

		; Registers ;
		;  ax = 0, bx = handle to NotesText, cx = size of NotesText,
		;  dx = buffer offset, si = <trash>, di = <trash>,
		;  bp = frame ptr (also expandBuf) (**)
		;  ds = segment of NotesText, es = ss
		;  (After the FileWrite call, all regs are available.)
		;
		mov	si, bx		; save handle NotesText
		shr	cx, 1
		mov	di, cx		; save char count
		;
		;	Allocate a buffer half the size as expandBuf
		;	Convert string from expandBuf into tempBuff.
		;	Copy string back to tempBuff.
		;
		mov	ax, (length expandBuf + 1) and 0x7ffe
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
		call	MemAlloc
		push	bx		; save handle to tempBuff
		push	si		; save handle to NotesText
		push	di		; save char count
		mov	es, ax		; es:di = dest
		clr	di			
	
		segmov	ds, ss, ax	; ds:si = source
		lea	si, expandBuf

		clr	ax, bx, dx	; default subs char, DosCodePage
		pop	cx		; char count w/out NULL.
		call	LocalGeosToDos	; new byte count -> cx

		segmov	ds, es, ax	; ds:dx <- buffer
		mov	dx, di
		pop	bx		; retrive NotesText
else

		segmov	ds, ss, ax	; ds:dx <- buffer (dx set above)
endif
		clr	al		; We can take errors
		xchg	bx, fileHandle	; Recover file handle & save block
		jcxz	expandBufferWritten
		call	FileWrite
expandBufferWritten:
		lahf
if DBCS_PCGEOS
		pop	bx		; free tempBuff
		call	MemFree
endif
		pop	ds
		;
		; Preserve error return while we free the block of memory
		;
		mov	bx, fileHandle
		call	MemFree
		sahf
		jc	writeError

done:
		call	DumpDismissAnnotation
		.leave
		ret

openError:
		push	bp
		mov	bp, offset noteOpenError
		jmp	callErr
writeError:
		push	bp
		mov	bp, offset noteWriteError
callErr:
		call	DumpError
		pop	bp
		jmp	done
DumpWriteNotes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort the current dump cycle by removing the dump file
		and decrementing the dump number.

CALLED BY:	MSG_ABORT_DUMP
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	doesn't matter

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 5/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpAbort	method	DumpClass, MSG_ABORT_DUMP
		.enter
		mov	dx, offset dumpName
		call	FileDelete
		dec	ds:procVars.DI_dumpNumber
		jns	done
		mov	ds:procVars.DI_dumpNumber, MAX_DUMP-1
done:
		call	DumpDismissAnnotation
		.leave
		ret
DumpAbort	endp

;----------------------------------------------------------------------------
;
;			   DUMPING ROUTINES
;
;----------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the contents of the screen on which the pointer is
		currently located.

CALLED BY:	MSG_DUMP
PASS:		ds=es=dgroup
RETURN:		Nothing
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpScreen	method	DumpClass, MSG_DUMP_SCREEN
		;
		; Find the window and driver on which the pointer currently
		; resides.
		; 
		call	ImGetPtrWin	; di = root win, bx = driver handle
	;
	; Can't call DumpWindowCommon here as that would PLock the window,
	; and that could cause us to deadlock...
	; 
		mov	ds:[curDumpFunc], ax
		push	ds:[screenRect].R_bottom	; ymax
		push	ds:[screenRect].R_right		; xmax
		push	ds:[screenRect].R_top		; ymin
		push	ds:[screenRect].R_left		; xmin
		call	DumpCommon	; Dump whole window
		ret
DumpScreen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the window currently under the mouse

CALLED BY:	MSG_DUMP_WINDOW, MSG_DUMP_WINDOW_NO_PTR
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	lots of things

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpWindow	method	DumpClass, MSG_DUMP_WINDOW, MSG_DUMP_WINDOW_NO_PTR
		.enter
		;
		; Fetch the screen the pointer is on. This nets us the root
		; window and handle of the driver for the window as well.
		;
		call	ImGetPtrWin	; di = root window, bx = driver handle
		;
		; If user wants the pointer out of the way, nuke it now.
		;
		cmp	ax, MSG_DUMP_WINDOW_NO_PTR
		pushf			; for possible restore
		jne	noHide
		push	es,ds,si,di,ax,bx,cx,dx,bp	; Video drivers tend
							;  to biff a lot of regs
		call	GeodeInfoDriver
		mov	di, DR_VID_HIDEPTR
		call	ds:[si].DIS_strategy
		pop	es,ds,si,di,ax,bx,cx,dx,bp
noHide:
		push	bx		; save driver handle for ptr restore
		;
		; Fetch the current mouse position and locate the window in
		; which the mouse resides. NOTE: This is the smallest window
		; containing the mouse...
		;
		mov	cx, ds:mousePos.P_x
		mov	dx, ds:mousePos.P_y
		push	ax		; save dump function
		call	WinLocatePoint	; di <- smallest window containing
					;  (cx,dx)
		pop	ax
		cmp	di, -1		; di == -1 => window not w/in referent
		je	noWin
		call	DumpWindowCommon; Dump the window the system found
noWin:
		pop	bx		; recover driver handle
		popf			;  and result of method comparison
		jne	noRestore	; => pointer not hidden
		;
		; Turn the pointer back on again now that the dump is complete.
		;
		push	es,ds,si,di,ax,bx,cx,dx,bp	; Video drivers tend
							;  to biff a lot of regs
		call	GeodeInfoDriver
		mov	di, DR_VID_SHOWPTR
		call	ds:[si].DIS_strategy
		pop	es,ds,si,di,ax,bx,cx,dx,bp
noRestore:
		.leave
		ret
DumpWindow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpWindowCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for dumping a window, be it the one under the
		pointer or the root window of a screen.

CALLED BY:	DumpScreen, DumpWindow
PASS:		di	= window handle
		ds	= dgroup
		ax	= DumpMessages for function being performed
RETURN:		nothing
DESTROYED:	Everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpWindowCommon proc	near
		.enter
		mov	ds:[curDumpFunc], ax
		;
		; Figure the bounds of the window.
		;
		call	WinGetWinScreenBounds
	;
	; If window is off-screen to the left, truncate to 0 to avoid
	; confusing the hell out of things.
	; 
		tst	bx
		jns	checkXmin
		clr	bx
checkXmin:
		tst	ax
		jns	checkXmax
		clr	ax
checkXmax:
		cmp	cx, ds:[screenRect].R_right
		jbe	checkYmax
		mov	cx, ds:[screenRect].R_right
checkYmax:
		cmp	dx, ds:[screenRect].R_bottom
		jbe	pushBounds
		mov	dx, ds:[screenRect].R_bottom
pushBounds:
		push	dx		; ymax
		push	cx		; xmax
		push	bx		; ymin
		push	ax		; xmin
		call	DumpCommon	; Dump whole window
		.leave
		ret
DumpWindowCommon endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dump the currently selected rectangle of the screen

CALLED BY:	MSG_DUMP_RECT
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	lots

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpRect	method	DumpClass, MSG_DUMP_RECT
		.enter
		mov	ds:[curDumpFunc], ax
		push	ds:rectBox.R_bottom
		push	ds:rectBox.R_right
		push	ds:rectBox.R_top
		push	ds:rectBox.R_left
		call	ImGetPtrWin	; di <- root window of screen
		call	DumpCommon
		.leave
		ret
DumpRect	endp

;------------------------------------------------------------------------------
;
;			 COMMON DUMP ROUTINE
;
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCalcBMSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the size needed to hold a bitmap of a given
		dimensions

CALLED BY:	DumpCommon
PASS:		di	= bitmap type (bits outside BMT_FORMAT may be set)
		ax	= bitmap width
		dx	= bitmap height
RETURN:		dx:ax	= number of bytes required
DESTROYED:	di ((not mask BMT_FORMAT) bits masked out)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCalcBMSize	proc	near
		.enter
		;
                ; case BMT_FORMAT:
                ;    BMF_MONO:   #bytes = ((width+7)>>3) * height
                ;    BMF_4BIT:   #bytes = ((width+1)>>1) * height
                ;    BMF_8BIT:   #bytes = width * height
                ;    BMF_24BIT:  #bytes = width * height * 3
		;  
		and	di, mask BMT_FORMAT
		shl	di
		jmp	cs:{word}CBMSTable[di]
CBMSTable	label	word
		dw	mono
		dw	bit4
		dw	bit8
		dw	bit24
mono: 				; bytesPerScan = (width+7)/8
		add	ax, 7
		shr	ax
		shr	ax
		jmp	15$
bit4: 				; bytesPerScan = (width+1)/2
		inc	ax
15$:
		shr	ax
		jmp	timesHeight
bit24: 				; bytesPerScan = width*3
		mov	di, ax
		shl	ax
		add	ax, di
		.assert	$-timesHeight eq 0
bit8:
				; bytesPerScan = width
timesHeight:
		mul	dx
		add	ax, size Bitmap
		adc	dx, 0
		.leave
		ret
DumpCalcBMSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCheckFileRequired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if current format requires a file to which to dump

CALLED BY:	INTERNAL
PASS:		ds	= dgroup
RETURN:		carry set if file required
		carry clear if not
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCheckFileRequired proc	near
		uses	ds, bx
		.enter
		lds	bx, ds:[dumpProcs]
		test	ds:[bx].DP_enable, mask DUI_DESTDIR
		jz	done
		stc
done:
		.leave
		ret
DumpCheckFileRequired endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a dump file for the current output format

CALLED BY:	DumpCommon
PASS:		DS=ES=dgroup
RETURN:		AX	= file handle, if carry clear
		carry set => error
DESTROYED:	CX, DX

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpOpenFile	proc	near	uses bx, bp, si, di
		.enter
	;
	; See if DUI_DESTDIR set for the current format. If not, then not
	; creating a file...
	; 
		call	DumpCheckFileRequired
		jnc	done
	;
	; Set our current directory properly, based on what was in the
	; selector.
	; 
		mov	bx, ds:[dumpDiskHandle]
		mov	dx, offset dumpName
		call	FileSetCurrentPath

		;
		; Fetch the current text from the filename text object
		;
		mov	si, offset filename
		mov	cx, ds:[filenameLength]
		mov	di, offset dumpName
genName:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '%'		; Special "dump number" token?
		je	convertNum
storeAndLoop:
		LocalPutChar	esdi, ax
		loop	genName
		;
		; Append output-specific suffix
		; 
		LocalLoadChar	ax, '.'
		LocalPutChar	esdi, ax
		mov	cx, length DP_suffix
		push	ds
		lds	si, ds:dumpProcs
		add	si, DP_suffix
		LocalCopyNString
		pop	ds
		;
		; Null-terminate the name
		;
		clr	ax
		LocalPutChar	esdi, ax

		;
		; dumpName now contains the filename to use. Create the
		; thing, truncating it at the same time.
		;
		mov	ah, FILE_CREATE_TRUNCATE or mask FCF_NATIVE
		mov	al, FILE_ACCESS_W or FILE_DENY_NONE
		mov	cx, FILE_ATTR_NORMAL
		mov	dx, offset dumpName
		call	FileCreate
		jc	error
		;
		; Store the file handle even if we got an error
		;
		mov	ds:file, ax
done:
		.leave
		ret
convertNum:
		;
		; Convert the current dump number (which must be < 100) into
		; ascii and store it in the filename being generated.
		;
		mov	al, ds:procVars.DI_dumpNumber	; Fetch dump number
		aam				; Convert to ten's and one's
						;  in ah and al, respectively
if DBCS_PCGEOS
		mov	dl, al			; store unit's digit
		mov	al, ah			; ten's digit first
		clr	ah
		add	al, '0'
		LocalPutChar	esdi, ax
		mov	al, dl			; one's digit
		clr	ah
		add	al, '0'

else
		add	ax, '0' or ('0' shl 8)	; Convert both to ascii
		xchg	al, ah			; Store ten's digit first
		stosb
		mov	al, ah			; Shift one's digit back
						;  to al for storing.
endif
		jmp	storeAndLoop
error:
		call	DumpThaw
		mov	bp, offset couldNotCreate
		call	DumpError
		stc
		jmp	done
DumpOpenFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCallPrologue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the prologue function for the output file.

CALLED BY:	DumpCommon
PASS:		si	= bitmap format
		bp	= file handle
		cx	= total width
		dx	= total height
RETURN:		Carry set on error (screen thawed)
DESTROYED:	es, bx, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCallPrologue proc	near	uses bp, di
		.enter
		les	bx, ds:dumpProcs
		mov	ax, es:[bx].DP_prologue.offset
		mov	bx, es:[bx].DP_prologue.segment
		mov	bp, ds:file
		call	ProcCallFixedOrMovable
		jnc	done
		call	DumpThaw
		mov	bp, offset couldNotInitialize
		call	DumpError
		stc
done:
		.leave
		ret
DumpCallPrologue endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCallSlice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the slice function for the output file.

CALLED BY:	DumpCommon
PASS:		si	= bitmap slice handle
		bp	= file handle
		cx	= bitmap size
RETURN:		Carry set on error
DESTROYED:	es, bx, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCallSlice 	proc	near	uses bp, di
		.enter
		les	bx, ds:dumpProcs
		mov	ax, es:[bx].DP_slice.offset
		mov	bx, es:[bx].DP_slice.segment
		mov	bp, ds:file
		call	ProcCallFixedOrMovable
		jnc	done
		call	DumpThaw
		mov	bp, offset couldNotWriteSlice
		call	DumpError
		stc
done:
		.leave
		ret
DumpCallSlice	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCallEpilogue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the epilogue function for the output file.

CALLED BY:	DumpCommon
PASS:		bp	= file handle
RETURN:		Carry set on error
DESTROYED:	es, bx, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCallEpilogue proc	near	uses bp
		.enter
		les	bx, ds:dumpProcs
		mov	ax, es:[bx].DP_epilogue.offset
		mov	bx, es:[bx].DP_epilogue.segment
		mov	bp, ds:file
		call	ProcCallFixedOrMovable
		jnc	done
		; screen already thawed by this point...
		mov	bp, offset couldNotFinish
		call	DumpError
		stc
done:
		.leave
		ret
DumpCallEpilogue endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform whatever actions are necessary to complete a dump,
		when it was successful

CALLED BY:	DumpCommon
PASS:		ds 	= dgroup
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 4/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpComplete	proc	near	uses bx, si, di, cx, dx, bp
		.enter
		call	DumpCheckFileRequired
		jnc	done
	;
	; Up the dump file number for next time.
	; 
		mov	al, ds:procVars.DI_dumpNumber
		inc	ax			; (is single-byte instruction)
		cmp	al, MAX_DUMP		; Wrap at 100
		jl	20$
		clr	al
20$:
		mov	ds:procVars.DI_dumpNumber, al
	;
	; Update range displaying the next dump number.
	;
		clr	cx
		mov	cl, al
		clr	bp			; not indeterminate
		mov	bx, handle DumpNumberRange
		mov	si, offset DumpNumberRange
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		call	ObjMessage
	;
	; Put up annotation box if annotation enabled
	;
		tst	ds:procVars.DI_logging?
		jz	done
	;
	; First set the text for the file display
	;
		mov	bx, handle FileDisplay
		mov	si, offset FileDisplay
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	dx, segment dumpName
		mov	bp, offset dumpName
		clr	cx			; Null-terminated...
		mov	di, mask MF_CALL
		call	ObjMessage

	;
	; Now put up the summons.
	;
		mov	bx, handle AnnotationBox
		mov	si, offset AnnotationBox
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		.leave
		ret
DumpComplete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the bitmap format we'll get from a window's driver

CALLED BY:	DumpCommon
PASS:		di	= window handle
		ds	= dgroup
RETURN:		ax	= BMFormat
		vidDriver pointed to driver's DevInfo structure
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
		Use the DR_VID_INFO function to locate the driver's DevInfo.
		Extract the type from there.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpGetFormat	proc	near	uses di, ds
		.enter
		lds	si, ds:[vidDriver]
		;
		; Extract the format from the VideoDriverInfo, dealing with its
		; being a byte field and our wanting to return a word.
		;
		clr	ax
		mov	al, ds:[si].VDI_bmFormat
		.leave
		ret
DumpGetFormat	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCalcSliceHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the number of rows to fetch at a time given the
		size of the image being gotten.

CALLED BY:	DumpCommon
PASS:		cx	= image width
		dx	= image height
		si	= BMFormat for the bitmap
		ds	= dgroup
RETURN:		ax	= slice height, also stored in ds:sliceHeight
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCalcSliceHeight proc near	uses di
		.enter
		push	dx		; save height for later
		;
		; First figure the total size of the bitmap.
		; XXX: Adds in size Bitmap, but I don't think it matters much --
		; this is all so approximate anyway.
		;
		mov	ax, cx		; ax <- width
		mov	di, si		; di <- format
		call	DumpCalcBMSize
		;
		; Divide the total size by 8K (our optimal size, at least as
		; far as TIFF is concerned), rounding up.
		;
		add	ax, 8 * 1024 - 1
		adc	dx, 0
		mov	di, 8 * 1024	; Shooting for 8K slices
		div	di		; ax <- # of slices
		;
		; Now divide the image height by the number of slices we've 
		; decided to get. Again we need to round up.
		;
		mov	di, ax		; di <- # of slices for division
		pop	ax		; recover image height
		push	ax		;  and save it again...
		clr	dx		; clear high word so we can do 32b/16b
		div	di		; ax <- lines/slice, dx <- remainder
		tst	dx
		jz	exact
		inc	ax		; round up
exact:
		mov	ds:sliceHeight, ax
		pop	dx		; dx <- image height
		.leave
		ret
DumpCalcSliceHeight endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpFrameIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frame the area being dumped, if appropriate.

CALLED BY:	DumpCommon
PASS:		dgroup::curDumpFunc set to method being handled
		dgroup::dumpState holding inverting gstate for entire screen
		dgroup::rectBox holding rectangle about to be dumped
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpFrameIt	proc	near
		uses	ds, di, ax, bx, cx, dx
		.enter
		segmov	ds, dgroup, ax
		cmp	ds:[curDumpFunc], MSG_DUMP_RECT
		jne	done
		mov	di, ds:[dumpState]

		mov	ax, ds:[rectBox].R_left
		mov	bx, ds:[rectBox].R_top
		mov	cx, ds:[rectBox].R_right
		mov	dx, ds:[rectBox].R_bottom

		dec	ax
		dec	bx
		inc	cx
		inc	dx
		call	GrDrawRect
		dec	ax
		dec	bx
		inc	cx
		inc	dx
		call	GrDrawRect
done:
		.leave
		ret
DumpFrameIt	endp

DumpThaw	proc	near
		call	DumpFrameIt
		call	InputThaw
		ret
DumpThaw	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to dump a piece of the screen.

CALLED BY:	DumpScreen, DumpWindow, DumpArea
PASS:		di	= window handle for finding the format of the
			  bitmap GrGetBitmap will be returning.
		on stack= screen coordinates of rectangle being dumped
		dumpState= graphics state opened on the root window of the
			   screen.
RETURN:		nothing
DESTROYED:	lots

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpCommon 	proc	near call	xmin:word,
					ymin:word,
					xmax:word,
					ymax:word
		uses	ax, bx, cx, dx
		.enter
		call	DumpFrameIt
		;
		; Open the dump file.
		;
		call	DumpOpenFile
		LONG jc Return
		;
		; Figure the format for the bitmap we'll be getting back
		;
		call	DumpGetFormat
		push	ax		; Save it
		;
		; We're given the area bounds as coordinates, but we need
		; them as upper-left and width/height. Replace xmax and ymax
		; with the appropriate values...
		;
		mov	cx, xmax
		sub	cx, xmin
		inc	cx		; Need width (1-origin)
		mov	xmax, cx
		mov	dx, ymax
		sub	dx, ymin
		inc	dx		; Need height (1-origin)
		mov	ymax, dx
		;
		; Figure the slice height now so the prologue function knows.
		;
		pop	si		; si <- bitmap format
		call	DumpCalcSliceHeight
		;
		; Contact the output module to initialize things.
		;
		call	DumpCallPrologue
		LONG jc	Fail
		;
		; Fetch the graphics state created when the screen was frozen.
		; It's open to a detached root window on the screen, which is
		; sufficient for our purposes.
		;
		mov	di, ds:dumpState
		;============================================================
		; Now fetch the area in appropriate-height chunks, passing each
		; to the output-format's slice routine.
		;
		; During the loop, BX contains the Y coordinate for the top
		; of the current slice.
		;
		clr	bx
SliceLoop:
		;
		; Figure the number of scanlines to fetch -- sliceHeight
		; or the number of lines left in the rect.
		;
		mov	dx, ymax
		sub	dx, bx
		cmp	dx, ds:sliceHeight
		jl	10$
		mov	dx, ds:sliceHeight
10$:
		;------------------------------------------------------------
		; Extract the bitmap slice from the screen.
		; 
		mov	cx, xmax
		push	bx		; save Y coord for later
		add	bx, ymin
		mov	ax, xmin
		call	GrGetBitmap
		tst	bx		; BX == 0 => failure
		jz	failAndThaw
		;------------------------------------------------------------
		; Lock down the bitmap's block and write the whole thing
		; out to the output file.
		;
		push	ds, dx, di
		call	MemLock		; Make sure it's in memory
		;
		; Use the parameters of the bitmap to determine the size to
		; write, since the bitmap code fudges and the heap code rounds
		; up.
		;
		mov	ds, ax
		mov	ax, ds:B_width
		mov	di, {word}ds:B_type
		mov	dx, ds:B_height
		call	DumpCalcBMSize
		mov	cx, ax		; cx <- bitmap size
		mov	si, bx		; si <- memory block

		call	MemUnlock	; Unlock block so it can be freed

		mov	ax, mask HF_SWAPABLE
		call	MemModifyFlags	; Mark block as swappable in case
					;  output module keeps it around a bit

		pop	ds, dx, di	; Recover biffed registers
		
		;
		; Call the slice() procedure for the output file.
		;
		call	DumpCallSlice
		pop	bx		; Recover the Y coord
		jc	Fail
		
		;
		; Update the loop counter and see if we should continue...
		; 
		add	bx, dx		; Add in the # lines actually fetched
		cmp	bx, ymax
		jl	SliceLoop
		;
		; Close everything down:
		;	free the gstate
		;	call the output-file's epilogue function
		;	close the file
		;	release the video driver exclusive
		;
		call	DumpThaw

		call	DumpCallEpilogue
		jc	Fail

		call	DumpCheckFileRequired
		jnc	complete

		mov	bx, ds:file
		clr	al
		call	FileClose
complete:
		call	DumpComplete
Return:
		;
		; Restore registers and get out of here.
		; 
		.leave
		ret	@ArgSize
failAndThaw:
		call	DumpThaw
Fail:
		;
		; Failure -- remove the file after closing it.
		;
		mov	dx, dgroup
		mov	ds, dx		; Just in case
		call	DumpCheckFileRequired
		jnc	doneFail

		mov	bx, ds:[file]
		clr	al
		call	FileClose
		mov	dx, offset dumpName
		call	FileDelete
		;
		; We don't increment the dump number so the user knows the dump
		; didn't succeed....
		;
doneFail:
		stc
		jmp	Return
DumpCommon 	endp

;------------------------------------------------------------------------------
;
;		    DumpApplication Implementation
;
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DARemoveFromExpress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the application from the express menu by setting
		its list entry not usable.

CALLED BY:	MSG_DA_REMOVE_FROM_EXPRESS
PASS:		*ds:si	= DumpApplication object
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DARemoveFromExpress method dynamic DumpApplicationClass, MSG_DA_REMOVE_FROM_EXPRESS
		.enter
		mov	dx, offset DumpHiddenTextMoniker
		call	DAHackListEntry
		mov	di, ds:[si]
		add	di, ds:[di].DumpApplication_offset
		mov	si, offset DAI_removeTrigger
		mov	bx, offset DAI_returnTrigger
		call	DADisableEnable
		.leave
		ret
DARemoveFromExpress		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DAReturnToExpress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the application to the express menu by setting
		its list entry usable.

CALLED BY:	MSG_DA_RETURN_TO_EXPRESS
PASS:		*ds:si	= DumpApplication object
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DAReturnToExpress method dynamic DumpApplicationClass, MSG_DA_RETURN_TO_EXPRESS
		.enter
		mov	dx, offset DumpTextMoniker
		call	DAHackListEntry
		mov	di, ds:[si]
		add	di, ds:[di].DumpApplication_offset
		mov	si, offset DAI_returnTrigger
		mov	bx, offset DAI_removeTrigger
		call	DADisableEnable
		.leave
		ret
DAReturnToExpress		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DAHackListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the list entry for this application in the express
		menu and send it the method passed to us in ax

CALLED BY:	DARemoveFromExpress, DAReturnToExpress
PASS:		*ds:si	= DumpApplication object
		dx	= chunk handle of moniker to use in express menu
RETURN:		nothing
DESTROYED:	ax, di, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DAHackListEntry	proc	near
		.enter
		mov	cx, ds:[LMBH_handle]
		mov	ax, MSG_GEN_APPLICATION_SET_TASK_ENTRY_MONIKER
		call	ObjCallInstanceNoLock
		.leave
		ret
DAHackListEntry endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DADisableEnable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable one object while enabling the other

CALLED BY:	DARemoveFromExpress, DAReturnToExpress
PASS:		ds:di	= DumpApplicationInstance
		si	= offset w/in DAI of optr for trigger to disable
		bx	= offset w/in DAI of optr for trigger to enable
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DADisableEnable	proc	near
		.enter
		push	ds:[di][bx].handle
		push	ds:[di][bx].chunk
		mov	bx, si
		mov	si, ds:[di][bx].chunk
		mov	bx, ds:[di][bx].handle
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		pop	si
		pop	bx
		mov	ax, MSG_GEN_SET_ENABLED
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		.leave
		ret
DADisableEnable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DAUnbanish
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unbanish the primary.

CALLED BY:	(INTERNAL) DABringToTop, DANotifyTaskSelected
PASS:		*ds:si	= DumpApplication object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	primary is set usable and app is made focusable and targetable
     			again

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DAUnbanish	proc	near
		class	DumpApplicationClass
		uses	ax, cx, dx, bp, si
		.enter
	;
	; Make sure our primary is usable too, and on-screen.
	; 
		mov	si, offset DumpPrimary
		mov	bx, handle DumpPrimary
		
		mov	ax, MSG_GEN_GET_USABLE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		jc	done

		mov	ax, MSG_GEN_SET_USABLE
		mov	dx, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Make ourselves focusable and targetable again.
	; 
		mov	si, offset DumpApp
		mov	cx, mask GA_TARGETABLE
		mov	ax, MSG_GEN_SET_ATTRS
		call	ObjCallInstanceNoLock
		
		mov	cx, mask AS_FOCUSABLE or mask AS_MODELABLE
		clr	dx
		mov	ax, MSG_GEN_APPLICATION_SET_STATE
		call	ObjCallInstanceNoLock
	;
	; Raise our geode up, now that we're focusable. This can have the effect
	; of bring ourselves up from out of nowhere, but c'est la vie.
	; 
		call	GeodeGetProcessHandle
		mov	cx, bx
		clr	dx, bp
		mov	ax, MSG_GEN_SYSTEM_BRING_GEODE_TO_TOP
		call	UserCallSystem
done:
		.leave
		ret
DAUnbanish	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DABringToTop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with unbanishing ourselves when the user has asked
		us to come to the top, via the express menu usually.

CALLED BY:	MSG_GEN_BRING_TO_TOP
PASS:		*ds:si	= DumpApplication object
		ds:di	= DumpApplicationInstance
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DABringToTop	method dynamic DumpApplicationClass, MSG_GEN_BRING_TO_TOP
		test	ds:[di].GI_states, mask GS_USABLE
		jz	passItUp
		call	DAUnbanish
passItUp:
		mov	di, offset DumpApplicationClass
		GOTO	ObjCallSuperNoLock
DABringToTop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DANotifyTaskSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure primary unbanished when we're selected this way.

CALLED BY:	MSG_META_NOTIFY_TASK_SELECTED
PASS:		*ds:si	= DumpApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	Primary set usable

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DANotifyTaskSelected method dynamic	DumpApplicationClass,
					MSG_META_NOTIFY_TASK_SELECTED
		call	DAUnbanish

		mov	di, offset DumpApplicationClass
		GOTO	ObjCallSuperNoLock
DANotifyTaskSelected endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATransparentDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle transparent mode by not detaching if we are banished

CALLED BY:	GLOBAL (MSG_META_TRANSPARENT_DETACH)

PASS:		*DS:SI	= DumpApplicationClass object
		DS:DI	= DumpApplicationClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 1/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DATransparentDetach	method dynamic	DumpApplicationClass,
					MSG_META_TRANSPARENT_DETACH
		.enter

		; If we're not usable, swallow message
		;
		test	ds:[di].GI_states, mask GS_USABLE
		jz	done
		mov	di, offset DumpApplicationClass
		call	ObjCallSuperNoLock
done:
		.leave
		ret
DATransparentDetach	endm

CommonCode	ends

