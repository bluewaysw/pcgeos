COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	LAUNCHER
MODULE:		Launcher
FILE:		launcher.asm

AUTHOR:		Andrew Wilson, Nov 21, 1990

ROUTINES:
- LauncherOpenApplication
	- LauncherSetupAppOrDocPrompt
- LauncherCommandStringIsSet
	- ExpandCommandString
		- AppendArgs
		- ParseCodeword
			- ExpandFileCodeword
			- ExpandPassedFileCodeword
			- ExpandDriveCodeword
			- ExpandDirectoryCodeword
			- ExpandCheckCodeword
			- ExpandArgumentsCodeword
			- ExpandListCodeword
			- ExpandDollarCodeword
- LauncherArgumentsConfirmed
	- GetLauncherFilename
- LauncherCreateNewStateFile
- LauncherRestoreFromState
- LauncherErrorHandler
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/90	Initial revision
	roger	11/22/91	Revised and Added multiple file checks.
	dlitwin	03/17/92	Updated to 2.0 for integration with Desktop

DESCRIPTION:
	This file contains code to implement the "launcher" application.

	The launcher allows users to click in any directory on images
	of their programs and have PCGEOS run the programs.  It does this
	by having its own token image and appropriate knowledge of where
	the program to be launched is.

	$Id: launcher.asm,v 1.1 97/04/04 16:13:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1


include	geos.def
include	heap.def
include geode.def
include resource.def
include	ec.def

include object.def
include	gstring.def
include	graphics.def
include win.def
include lmem.def
include system.def
include file.def
include disk.def
include	library.def

include Objects/processC.def

include	Internal/fileInt.def
include	Internal/dos.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def
UseLib	Objects/vTextC.def

include	launcher.def


;	Declaration of our process class
;
LauncherClass	class	GenProcessClass
MSG_LAUNCHER_COMMAND_STRING_SET	message
MSG_LAUNCHER_NO_FILE_CHOSEN	message
MSG_LAUNCHER_FILE_CHOSEN	message
MSG_LAUNCHER_ARGS_CONFIRMED	message
MSG_LAUNCHER_FILE_CHECK		message
MSG_LAUNCHER_RUN_APP		message
MSG_LAUNCHER_READ_DOC		message
LauncherClass	endc

if 0
;not used
FILENAME_MAX_LEN	equ	PATH_BUFFER_SIZE + DOS_DOT_FILE_NAME_LENGTH_ZT

CommandComInfo	struct
	CCI_diskHandle	hptr
	CCI_pathname	char	FILENAME_MAX_LEN dup (?)
CommandComInfo	ends
endif

LauncherDataFlags	record
	LDF_PROMPT_USER:1,		; Prompt user before restarting Geos?
	LDF_NO_ARGS:1,			; launcher has no command Line args
	LDF_PROMPT_ARGS:1		; prompt user for args runtime?
	LDF_ARGS_SET:1,			; launcher has args in LDC_Arguments
	LDF_PROMPT_FILE:1		; simple append-file-to-end-of-args
	LDF_CONFIRM:1,			; confirm arguments after expasion
	LDF_PROMPT_DOC:1		; prompt to run app or read doc?
	LDF_UNUSED:1
LauncherDataFlags	end

;
; FatalErrors
;
FILE_ARG_PATH_ERROR				enum FatalErrors


idata	segment
	LauncherClass	mask CLASSF_NEVER_SAVED
idata	ends

udata	segment
	restarting	byte
udata	ends

include launcher.rdef


Main	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is when the launcher just has been open.  We check if
		the arguments have already been set and if so immediatley

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherOpenApplication	method	LauncherClass, MSG_GEN_PROCESS_OPEN_APPLICATION
;	.enter

	mov	di, offset LauncherClass	;ES:DI <- ptr to class struct
	call	ObjCallSuperNoLock

	;
	; add ourselves to SHUTDOWN_CONTROL list
	;
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	call	GCNListAdd

;	HACK! We check to see if we are trying to restart from state (a bad
;	thing for this application). If we are, we just send a MSG_META_QUIT to
;	ourselves.
;
	tst	es:[restarting]
	jnz	exitFromLauncher

	mov	bx, handle LauncherStrings
	call	MemLock
	mov	ds, ax				; put LauncherStrings seg in ds
	mov	dx, ax				; put LauncherStrings seg in dx

	assume ds:LauncherStrings
	mov	si, ds:[launcherFlags]
	assume ds:dgroup
	mov	al, {byte} ds:[si]		; put flags in al
	test	al, mask LDF_NO_ARGS
	jz	useArgs				; not no-args, keep 'em
		; else no args, 0 arg buffer just to make sure
	assume ds:LauncherStrings
	mov	si, ds:[launcherCommandString]
	assume ds:dgroup
SBCS <	mov	{byte} ds:[si], 0		; make sure args are null>
DBCS <	mov	{wchar} ds:[si], 0		; make sure args are null>
useArgs:

	assume ds:LauncherStrings
	mov	bp, ds:[launcherCommandString]	; put launcherComm.. in dx:bp
	assume ds:dgroup
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle CommandStringText
	mov	si, offset CommandStringText
	mov	di, mask MF_CALL
	call	ObjMessage			; set UI text
	mov	bx, handle LauncherStrings	; restore handle

	assume ds:LauncherStrings
	mov	si, ds:[launcherFlags]
	assume ds:dgroup
	mov	al, {byte} ds:[si]		; put flags in al
	test	al, mask LDF_PROMPT_DOC		; ask for doc or app?
	jnz	promptDoc

LauncherOpenApplication__RunAppResume label near;; jmp from LauncherRunApp
	test	al, mask LDF_PROMPT_ARGS
	jnz	promptArgs

	call	MemUnlock			; unlock LauncherStrings block
	mov	ax, MSG_LAUNCHER_COMMAND_STRING_SET
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	exit

promptArgs:
	call	MemUnlock			; unlock LauncherStrings block
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle CommandStringPrompt
	mov	si, offset CommandStringPrompt
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	exit

exitFromLauncher:
	mov	ax, MSG_META_QUIT
	mov	bx, handle LauncherApp
	mov	si, offset LauncherApp
	mov	di, mask MF_CALL
	call	ObjMessage

exit:
	.leave
	ret

promptDoc:
	; Make sure the file exists and is a file.  If not, go back upstairs
	; and press on since this is an acceptable condition.  (EC warn,
	; though.)
	push	dx
	assume ds:LauncherStrings
	mov	dx, ds:[launcherDocFile]
	assume ds:dgroup
	call	FileGetAttributes
	pop	dx
EC <	WARNING_C LAUNCHER_DOC_FILE_NOT_PRESENT				>
	jc	LauncherOpenApplication__RunAppResume
	test	cx, mask FA_SUBDIR or mask FA_VOLUME
EC <	WARNING_NZ LAUNCHER_DOC_FILE_NOT_A_FILE				>
	jnz	LauncherOpenApplication__RunAppResume

	call	LauncherSetupAppOrDocPrompt

	call	MemUnlock			; unlock LauncherStrings block
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle AppOrDocPrompt
	mov	si, offset AppOrDocPrompt
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	exit

LauncherOpenApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove ourselves from SHUTDOWN_CONTROL list

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		ds:si	= dgroup
		es 	= segment of class
		ax	= MSG_GEN_PROCESS_CLOSE_APPLICATION

RETURN:		cx	= handle of extra state block

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/6/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherCloseApplication	method	LauncherClass, MSG_GEN_PROCESS_CLOSE_APPLICATION

	;
	; remove ourselves from SHUTDOWN_CONTROL list
	;
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	call	GCNListRemove

	clr	cx				; no extra state block
	ret
LauncherCloseApplication	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherConfirmShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle GCNSCT_UNSUSPEND by quitting DOS launcher

CALLED BY:	MSG_META_CONFIRM_SHUTDOWN

PASS:		ds:si	= dgroup
		es 	= segment of class
		ax	= MSG_META_CONFIRM_SHUTDOWN

		bp	= GCNShutdownControlType

RETURN:		cx	= handle of extra state block

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/6/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherConfirmShutdown	method	LauncherClass, MSG_META_CONFIRM_SHUTDOWN

	cmp	bp, GCNSCT_UNSUSPEND
	jne	reply

	;
	; GCNSCT_UNSUSPEND, quit
	;
	mov	ax, MSG_META_QUIT
	mov	bx, handle LauncherApp
	mov	si, offset LauncherApp
	mov	di, mask MF_CALL
	GOTO	ObjMessage		; <-- EXIT HERE ALSO

reply:
	mov	ax, SST_CONFIRM_END
	mov	cx, -1			; allow shutdown
	call	SysShutdown
	ret
LauncherConfirmShutdown	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherCommandStringIsSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This takes down the Command String editing box if it was up,
		Expands the Command String and pops up the File to Append
		box if requested.

CALLED BY:	GLOBAL

PASS:		es = dgroup

RETURN:		nothing

DESTROYED:	all but es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/31/92		This was previously LauncherOpenApplication.
	dlitwin	4/28/92		Broken out to add argument prompting and 
				file appending functionality.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherCommandStringIsSet	method	LauncherClass,
						MSG_LAUNCHER_COMMAND_STRING_SET
	.enter

	mov	bx, handle LauncherStrings
	call	MemLock				; lock LauncherStrings
	mov	ds, ax				; into ds
	assume	ds:LauncherStrings
	mov	si, ds:[launcherFlags]
	assume	ds:dgroup
	mov	cl, ds:[si]			; put flags in cl
	assume	ds:dgroup
	call	MemUnlock			; unlock LauncherStrings

	push	cx				; save launcherFlags
	test	cl, mask LDF_PROMPT_ARGS
	jz	skipTakedown			; skip takedown if not put up

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle CommandStringPrompt
	mov	si, offset CommandStringPrompt
	mov	di, mask MF_CALL
	call	ObjMessage

skipTakedown:
	clr	dx				; allocate block for us
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	bx, handle CommandStringText
	mov	si, offset CommandStringText
	mov	di, mask MF_CALL
	call	ObjMessage			; grab UI text

	;	ax = length of string, cx = block handle of string buffer
	mov	bx, cx				; put handle in bx

	call	ExpandCommandString
	pushf					; save state of carry
	call	MemUnlock			; unlock returned block
	call	MemFree				; free returned block
	popf					; restore state of carry
	pop	cx				; restore launcherFlags
	jnc	checkFileAppend

	pushf					; save carry (error?)
	mov	ax, MSG_META_QUIT		; This must be done before the 
	mov	bx, handle LauncherApp		; DOS_EXEC which may or may
	mov	si, offset LauncherApp		; not quit the app
	clr	di
	call	ObjMessage
	popf					; restore carry (error?)
	mov	ax, ERROR_ARGS_TOO_LONG		; doubles as parse error msg.
	call	LauncherErrorHandler
	jmp	exit

checkFileAppend:
	test	cl, mask LDF_PROMPT_FILE
	jnz	promptForFile

	mov	ax, MSG_LAUNCHER_FILE_CHOSEN	; continue from here
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage	
	jmp	exit

promptForFile:
	;
	; switch to launcherWorkingDirectory
	;
	mov	bx, handle LauncherStrings
	call	MemLock				; lock LauncherStrings
	mov	ds, ax				; into ds
	assume	ds:LauncherStrings
	mov	si, ds:[launcherWorkingDirectory]	; ds:si = working dir
	assume	ds:dgroup
	cmp	{TCHAR} ds:[si], 0		; any working dir?
	assume	ds:dgroup
	je	pathSet				; nope
	movdw	cxdx, dssi			; cx:dx = working dir
	clr	bp				; disk handle
	mov	bx, handle AppendFileFileSelector
	mov	si, offset AppendFileFileSelector
	mov	ax, MSG_GEN_PATH_SET
	mov	di, mask MF_CALL
	call	ObjMessage
pathSet:
	mov	bx, handle LauncherStrings
	call	MemUnlock			; unlock LauncherStrings

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle AppendFileDialog
	mov	si, offset AppendFileDialog
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

exit:
	.leave
	ret
LauncherCommandStringIsSet	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherNoFileChosen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Here the user was prompted for a file to append on to the 
		end of the arguments string but they chose not to.  We take
		down the file selector and then change the flag so the 
		LauncherFileChosen routine does not copy the file selector's
		selection onto the end of the arguments.

CALLED BY:	GLOBAL

PASS:		es = dgroup

RETURN:		nothing

DESTROYED:	all but es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/29/92		Added for AppendFile functionality
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherNoFileChosen	method	LauncherClass,
						MSG_LAUNCHER_NO_FILE_CHOSEN
	.enter

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle AppendFileDialog
	mov	si, offset AppendFileDialog
	mov	di, mask MF_CALL
	call	ObjMessage			; close file selector

	mov	bx, handle LauncherStrings
	call	MemLock				; lock down LauncherStrings
	mov	ds, ax
	assume	ds:LauncherStrings
	mov	si, ds:[launcherFlags]
	assume	ds:dgroup
	and	{byte} ds:[si], not mask LDF_PROMPT_FILE
	call	MemUnlock			; unlock LauncherStrings

	mov	ax, MSG_LAUNCHER_FILE_CHOSEN	; go on like file was chosen
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage	

	.leave
	ret
LauncherNoFileChosen	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherFileChosen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the prompt for file flag is set, this takes down the
		AppendFileDialog and copies its contents to the end of the
		Command String.  It then puts up the Confirm Args box or
		puts a call to LuancherArgsConfirmed on the queue.

CALLED BY:	GLOBAL

PASS:		es = dgroup

RETURN:		nothing

DESTROYED:	all but es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/31/92		This was previously LauncherOpenApplication.
	dlitwin	4/28/92		Added for AppendFile functionality
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherFileChosen	method	LauncherClass,
						MSG_LAUNCHER_FILE_CHOSEN
	.enter

	mov	bx, handle LauncherStrings
	call	MemLock				; lock LauncherStrings
	mov	ds, ax				; lock down into ds
	assume	ds:LauncherStrings
	mov	si, ds:[launcherFlags]
	mov	cl, {byte} ds:[si]		; put flags into cl
	assume	ds:dgroup

	test	cl, mask LDF_PROMPT_FILE
	jnz	appendTheFile
	jmp	doneAppendingFile

appendTheFile:
	push	cx, bx				; save launcherFlags, handle
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle AppendFileDialog
	mov	si, offset AppendFileDialog
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, offset launcherCommandString
	ChunkSizeHandle	ds, ax, cx
	mov	bp, cx				; put size in bp
	add	cx, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE
	call	LMemReAlloc			; make room for full path

SBCS <	sub	sp, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE	>
DBCS <	sub	sp, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE + DOS_DOT_FILE_NAME_LENGTH_ZT + 1	>
	mov	cx, ss				; put stack segment in cx
	mov	dx, sp				; point cx:dx to stack buffer
	push	bp				; save this size after stack buf
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	mov	bx, handle AppendFileFileSelector
	mov	si, offset AppendFileFileSelector
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	bx, ax				; put disk handle in bx
	segmov	es, ds, si			; put LauncherStrings seg in es

	mov	ds, cx				; put stack segment in ds
	mov	si, dx				; ds:si points to tail portion
	pop	di				; restore old args size
	LocalPrevChar	esdi			; back up to overwrite nullchar
	assume	es:LauncherStrings
	add	di, es:[launcherCommandString]	; es:di points to dest. buffer
	assume	es:dgroup
	push	di				; save start of dest. buffer 
	mov	cx, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE
	call	FileConstructFullPath
EC <	ERROR_C	FILE_ARG_PATH_ERROR					>
;
; We have a problem here -- the path could contain GEOS longname directories.
; We can't just pass the path to the DOS app because DOS doesn't know how to
; interpret GEOS longnames.  Instead, we will parse the path and convert any
; GEOS longnames to DOS names - brianc 10/20/94
;
	;
	; copy full path back into stack buffer and begin parsing
	;	ds:si = stack buffer
	;	es = launcherCommandString segment
	;
	pop	di				; es:di = full path
	push	ds, si, es, di
	segxchg	ds, es				; ds:si = full path
	xchg	si, di				; es:di = stack buffer
	LocalCopyString
	pop	ds, si, es, di			; ds:si = full path on stack
						; es:di = launcherCommandString
	mov	bx, si				; ds:bx = full path
copyStart:
	LocalGetChar	ax, dssi		; copy over drive letter/color
	LocalPutChar	esdi, ax
	LocalCmpChar	ax, C_BACKSLASH
	jne	copyStart
findComponentEnd:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_BACKSLASH
	je	foundComponentEnd
	LocalCmpChar	ax, 0
	jne	findComponentEnd
foundComponentEnd:
	push	{word} ds:[si-(size TCHAR)]	; save and null-term comp.
	mov	{TCHAR} ds:[si-(size TCHAR)], 0
	mov	dx, bx				; ds:dx = full path ending at
						;	component
	mov	ax, FEA_DOS_NAME		; get DOS name
	mov	cx, DOS_DOT_FILE_NAME_LENGTH_ZT	; give me it all!
if DBCS_PCGEOS
	push	es, di				; save dest in CommmandString
	segmov	es, ds, di			; es:di = stack work buf
	lea	di, ds:[bx][(PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE)]
endif
	call	FileGetPathExtAttributes	; put in launcherCommandString
						; DBCS: returns in DOS char set
EC <	ERROR_C	FILE_ARG_PATH_ERROR					>
if DBCS_PCGEOS
	pop	es, di				; es:di = dest in CommandString
	push	si
						; ds:si = DOS name (SBCS)
	lea	si, ds:[bx][(PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE)]
	mov	ax, '_'				; default char
	clr	cx				; null-terminated
	push	bx, dx
	mov	bx, cx				; current code page
	mov	dx, bx				; use primary FSD
	call	LocalDosToGeos			; cx = length
	pop	bx, dx
	add	di, cx				; leaves esdi past NULL
	add	di, cx				; char offset -> byte offset
	pop	si
else
	LocalClrChar	ax
	LocalFindChar				; find null-terminator
endif
	LocalPrevChar	esdi			; back up to overwrite null
	LocalLoadChar	ax, C_BACKSLASH
	LocalPutChar	esdi, ax		; put out delimiter
	pop	{word} ds:[si-(size TCHAR)]	; restore byte after comp.
	cmp	{TCHAR} ds:[si-(size TCHAR)], 0	; end of path?
	jne	short findComponentEnd		; nope, process next component
	LocalPrevChar	esdi
	LocalClrChar	ax
	LocalPutChar	esdi, ax		; null terminate DOS path

SBCS <	add	sp, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE	>
DBCS <	add	sp, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE + DOS_DOT_FILE_NAME_LENGTH_ZT + 1	>

	segmov	ds, es, si			; put LauncherStrings in ds
	assume	ds:LauncherStrings
	sub	di, ds:[launcherCommandString]	; get real length into di
	assume	ds:dgroup 
	mov	cx, di
	mov	ax, offset launcherCommandString
	call	LMemReAlloc			; shink to fit
	
	pop	cx, bx				; restore launcherFlags, handle

doneAppendingFile:
	;
	; copy command string into ConfirmArgsText for either LDF_CONFIRM
	; or !LDF_CONFIRM as MSG_LAUNCHER_ARGS_CONFIRMED gets the command
	; string from ConfirmArgsText - brianc 4/14/93
	;
	push	cx				; save LDF_
	mov	dx, cs
	mov	bp, offset nullArgs
	test	cx, mask LDF_PROMPT_FILE
	jnz	copyArgs			; copy prompt file
	test	cx, mask LDF_NO_ARGS
	jnz	haveArgs			; if no args, no args!
copyArgs:
	mov	dx, ds				; put LauncherStrings seg in dx
	assume	ds:LauncherStrings
	mov	bp, ds:[launcherCommandString]	; put launcherComm.. in dx:bp
	assume	ds:dgroup
haveArgs:
	clr	cx				; it is null terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle ConfirmArgsText
	mov	si, offset ConfirmArgsText
	mov	di, mask MF_CALL
	call	ObjMessage			; set UI text
	mov	bx, handle LauncherStrings
	call	MemUnlock			; unlock LauncherStrings
	pop	cx				; restore LDF_

	test	cl, mask LDF_CONFIRM		; flags in cl
	jnz	confirmArgs

	mov	ax, MSG_LAUNCHER_ARGS_CONFIRMED	; continue from here
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage	
	jmp	exit

confirmArgs:
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle ConfirmArgs
	mov	si, offset ConfirmArgs
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

exit:
	.leave
	ret
LauncherFileChosen	endm

SBCS <nullArgs	byte	0						>
DBCS <nullArgs	wchar	0						>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherArgumentsConfirmed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Basically this is the launcher's code.  This is called after
		the arguments to the launcher have been confirmed.  It sets
		up for and calls DosExec and handles error cases.

CALLED BY:	GLOBAL

PASS:		es = dgroup

RETURN:		nada

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/31/92		This was previously LauncherOpenApplication.
				Broken out to add argument prompting features.
	dlitwin 4/27/92		Changed name from LauncherCommandStringIsSet
				to allow the Confirm arguments feature.
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherArgumentsConfirmed	method	LauncherClass,
						MSG_LAUNCHER_ARGS_CONFIRMED
	.enter

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle ConfirmArgs
	mov	si, offset ConfirmArgs
	mov	di, mask MF_CALL
	call	ObjMessage

	clr	dx				; allocate block for us
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	bx, handle ConfirmArgsText
	mov	si, offset ConfirmArgsText
	mov	di, mask MF_CALL
	call	ObjMessage			; grab UI text

	;	ax = length of string, cx = block handle of string buffer
	mov	bx, cx				; put handle in bx

	call	ExpandCommandString		; with no codewords, just copies
	pushf					; save state of carry
	call	MemUnlock			; unlock returned block
	call	MemFree				; free returned block
	popf					; restore state of carry
	jnc	noExpandError

	mov	ax, ERROR_ARGS_TOO_LONG		; doubles as parsing error msg.
	jmp	doneChecking

noExpandError:
	mov	bx, handle LauncherStrings
	call	MemLock
	mov	ds, ax				; lock it down into ds
	assume	ds:LauncherStrings
	mov	si, ds:[launcherCheckFile]	; ds:si <- file name
SBCS <	tst	<{byte} ds:[si]>					>
DBCS <	tst	<{wchar} ds:[si]>					>
	jz	checkSecondFile			; no file to check

	mov	dx, si				; ds:dx <- file name
	call	FileGetAttributes		; carry set if file nonexistent
	mov	ax, ERROR_FILE_NOT_FOUND
	jc	doneChecking			; skip other checks on error

checkSecondFile:
	mov	si, ds:[launcherCheckFile2]	; ds:si <- file name
SBCS <	tst	<{byte} ds:[si]>					>
DBCS <	tst	<{wchar} ds:[si]>					>
	je	doneChecking

	mov	dx, si				; ds:dx <- file name
	call	FileGetAttributes		; carry set if file nonexistent
	mov	ax, ERROR_FILE_NOT_FOUND

doneChecking:
	jc	launcherError			; goto error code if carry set

	mov	cl, mask DEF_FORCED_SHUTDOWN	; set default DosExec flag
	assume ds:LauncherStrings
	mov	si, ds:[launcherFlags]
	assume ds:dgroup
	test	{byte} ds:[si], mask LDF_PROMPT_USER	; should we prompt?
	jz	noPrompt
	or	cl, mask DEF_PROMPT
noPrompt:
	push	cx				; save DosExec flag

	mov	bx, handle LauncherStrings
	call	GetLauncherFilename 		; name - ds:si, bx - handle
	jnc	gotFilenameNoError

	pop	cx				; remove this from stack
	jmp	launcherError			; because of error.

gotFilenameNoError:
	segmov	es, ds, di
	assume	es:LauncherStrings
	mov	di, es:[launcherCommandString]	; ES:DI <- arguments

	clr	ax				; AX <- environment disk
	mov	bp, es:[launcherWorkingDirectory]  ; dx:bp <- environment dir
	mov	dx, es

	pop	cx				; pop prompt flag

	push	ds, si

	call	DosExec

	pop	ds, si
	
	jnc	noError
	cmp	ax, ERROR_DOS_EXEC_IN_PROGRESS
	je	noErrorQuit

launcherError:
	call	LauncherErrorHandler

noErrorQuit:
	;
	; we only QUIT on error.  If DosExec is successful, we'll let the
	; launcher shutdown.  We return no state file, so the field will
	; not restart us.  Previously we QUIT even if the DosExec was
	; successful.  This caused problems with the launcher getting
	; DETACH from both the field (via the DosExec) and from the QUIT.
	; This situation didn't seem to be handled by the UI well.  So,
	; this change was necessary - brianc 5/4/93
	;
	mov	ax, MSG_META_QUIT		; This must be done before the 
	mov	bx, handle LauncherApp		; DOS_EXEC which may or may
	mov	si, offset LauncherApp		; not quit the app
	clr	di
	call	ObjMessage

noError:
	assume	ds:dgroup
	assume	es:dgroup
	mov	bx, handle LauncherStrings
	call	MemUnlock

	.leave
	ret
LauncherArgumentsConfirmed	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandCommandString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This parses the Command String and expands any codewords into
		text by popping up UI objects for the user. 

CALLED BY:	LauncherCommandStringIsSet

PASS:		es - dgroup
		ax - length of Command String
		bx - handle to Command String

RETURN:			carry - clear
		on error:
			carry - set
			ax    - error code (LauncherErrorCodes)

DESTROYED:	di, si, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandCommandString	proc	near
	uses	es
	.enter

	mov	cx, ax				; put size in cx
	inc	cx				; + null char
DBCS <	shl	cx, 1				; #chars -> # bytes	>
	mov	dx, bx				; save returned block's handle
	mov	bx, handle LauncherStrings
	call	MemLock
	mov	ds, ax				; lock down into ds
	mov	ax, offset launcherCommandString
	call	LMemReAlloc			; size it correctly
	segmov	es, ds, si			; put LauncherStrings in es

	mov	bx, dx				; restore returned block
	call	MemLock				; lock down returned block
	mov	ds, ax				; put it in ds

	assume es:LauncherStrings
	mov	di, es:[launcherCommandString]
	assume es:dgroup
	clr	si
	rep	movsb				; block move the text

	mov	bx, handle LauncherStrings
	call	MemUnlock			; unlock LauncherStrings

	mov	bx, dx				; restore returned block handle
	clc					; no error

	.leave
	ret
ExpandCommandString	endp






if 0
;*********************************************************************
;	THIS IS THE COMMAND STRING CODE, TO REPLACE ABOVE CODE LATER
;*********************************************************************

	segmov	ds, es, di			; put dgroup in ds
	mov	cx, ax				; put length in cx
	call	MemLock
	mov	es, ax				; lock down into es

	push	bx				; save this handle for later
	mov	bx, handle launcherCommandString ; segment of LauncherStrings
	call	MemLock
	mov	ds, ax				; lock down into ds
	mov	cx, 1				; realloc to 1 byte length
	mov	ax, offset launcherCommandString	; handle in ax
	call	LMemReAlloc

	; in the parse loop, the Command String segment is in es, and 
	; the LauncherStrings segment is in ds
	assume	ds:LauncherStrings
	mov	si, ds:[launcherCommandString]
	assume	ds:dgroup
	clr	di				; es:di points to CommStr
	clr	dx				; es:dx points to start also
parseLoop:
SBCS <	mov	al, '$'				; look for this character>
DBCS <	mov	ax, '$'				; look for this character>
SBCS <	repne	scasb				; search until found	>
DBCS <	repne	scasw				; search until found	>
	jne	outOfParseLoop			; reached end of CommStr
	
	call	AppendArgs			; copy non-codeword args
	jc	parseError
	call	ParseCodeword			; expand codeword
	jnc	parseLoop

parseError:
	pop	bx
	call	MemUnlock			; unlock Command String block
	call	MemFree				; free it up
	stc					; set carry because of error
	jmp	expandError

outOfParseLoop:
	call	AppendArgs			; append remaining args

;	What was I thinking here???

;	FIX so it takes out 'return' characters

	assume	es:LauncherStrings
	mov	si, es:[launcherCommandString]
	assume	es:dgroup
	sub	di, si				; get 
	pop	bx
	call	MemUnlock			; unlock Command String block
	call	MemFree				; free it up

	segmov	ds, es, di			; put LauncherStrings seg in ds
	clc					; no error

expandError:
	.leave
	ret
ExpandCommandString	endp
;*********************************************************************
endif








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This copies the arguments between codewords into the arguments
		buffer (lmem chunk in LauncherStrings).  When copying, the '$'
		of the next codeword (or null if at the end of the Command
		String) is included, but the pointers are adjusted so that
		the expanded codeword will overwrite this '$'.  If there is no
		next codeword (if the string ends with arguments, then the
		null copied on the end will end the arguments string.

CALLED BY:	ExpandCommandString

PASS:		es:dx - beginning of args we are to scan from CommStr
		es:di - start of new Codeword in CommStr (char after '$')
		ds    - segment of lmem heap of arguments chunk

RETURN:		es:di - start of new Codeword in CommStr (char after '$')
		ds    - segment of lmem heap of arguments chunk
		carry - set on error, ax = error code

DESTROYED:	ax, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
AppendArgs	proc	near
	uses cx
	.enter

	mov	cx, di				; put end of args into cx
	sub	cx, dx				; get args size into cx
	mov	ax, offset launcherCommandString	; handle in ax
	ChunkSizeHandle	ds, ax, bp		; get previous size
	add	cx, bp				; new size is the sum of these
	call	LMemReAlloc			; make room

	mov	ax, ds				; swap es and ds
	mov	cx, es				;   via ax and cx
	mov	ds, cx
	mov	es, ax

PrintMessage <cx is garbage, here>
	assume es:LauncherStrings
	mov	di, es:[offset launcherCommandString]	; dereference handle
	assume es:dgroup
	add	di, bp				; point es:di at end of chunk
	mov	si, dx				; point ds:si to beg. of args
	rep	movsb				; copy args
	dec	di				; step back so $ is overwritten


	.leave
	ret
AppendArgs	endp
endif


if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This determines the type of codeword and calls an appropriate
		routine to pop up a UI object and copy this text to the lmem
		arguments chunk.

CALLED BY:	ExpandCommandString

PASS		es:di - one after end of newly appended args in lmem chunk 
		ds:si - start of new Codeword in CommStr (char after '$')
		cx    - characters left to parse in Command String

RETURN:		es:di - text Command String after Codeword's trailing '$'
		ds    - segment of arguments lmem chunk
		cx    - charaters left to parse in Command String

DESTROYED:	none
 
PSEUDO CODE/STRATEGY:
	uses a table of procedure pointers (null terminated) and loops
	checking against codewords defined in a string resource.  When
	in finds a match it calls the corresponding routine from the table.is

	NOTE:  THIS SWITCHES THE DS AND ES SEGMENTS BACK, FROM:
		es - LauncherStrings lmem segment
		ds - Command String memory block segment
	TO:
		ds - LauncherStrings lmem segment
		es - Command String memory block segment

	BEFORE calling a codeword routine or 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseCodeword	proc	near
	uses	bx
	.enter

	push	es				; save LauncherStrings segment
	mov	bp, si				; save CommStr position in bp
	mov	bx, handle LauncherCodewords	; LauncherCodewords segment
	call	MemLock
	mov	es, ax				; lock down codeword resource
	mov	ax, cx				; save chars left to parse in ax

	mov	bx, offset CodewordJumpTable	; point to first entry of table
	mov	dx, es:[LMBH_offset]		; dx is first codeword handle
codewordLoop:
	tst	cs:[bx]				; have we tried all codewords?
	jz	notACodeword
	ChunkSizeHandle	es, dx, cx		; get length of chunk into cx
	mov	di, dx				; put codeword handle in di
	mov	di, es:[di]			; dereference this chunk
	repnz	cmpsb				; compare the two strings
	jz	foundMatch
	inc	dx				; next codeword handle
	inc	dx
	inc	bx				; next jump table entry
	inc	bx
	mov	si, bp				; go back to start of codeword
	jmp	codewordLoop

notACodeword:
	mov	bx, handle LauncherCodewords
	call	MemUnlock			; unlock codeword resource
	pop	es				; restore LauncherStrings seg
	mov	ax, ERROR_ARGS_TOO_LONG		; doubles as parsing error msg.
	stc					; set carry for error
	jmp	exit

foundMatch:
	mov	dx, cs:[bx]			; put routine offset in dx
	
	mov	bx, handle LauncherCodewords
	call	MemUnlock			; unlock codeword resource
	pop	es				; restore LauncherStrings seg
	
	call	dx				; call codeword table routine

exit:

	.leave
	ret
ParseCodeword	endp

CodewordJumpTable	label word
	word	offset ExpandFileCodeword
	word	offset ExpandPassedFileCodeword
	word	offset ExpandDriveCodeword
	word	offset ExpandDirectoryCodeword
	word	offset ExpandCheckCodeword
	word	offset ExpandArgumentsCodeword
	word	offset ExpandListCodeword
	word	offset ExpandDollarCodeword
	word	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandFileCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine pops up a file selector and appends the selected
		file to the Command String.

CALLED BY:	ParseCodeword

PASS:		ds:si points to '(' of arguments or ending '$'

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandFileCodeword	proc	near
	.enter
	.leave
	ret
ExpandFileCodeword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandPassedFileCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine takes the file name passed in by GeoManager and
		appends it to the Command String.  If no file is passed in from
		GeoManager, it acts just like ExpandFileCodeword.

CALLED BY:	ParseCodeword

PASS:		ds:si points to '(' of arguments or ending '$'

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandPassedFileCodeword	proc	near
	.enter
	.leave
	ret
ExpandPassedFileCodeword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandDriveCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine works like ExpandFileCodeword, but restricts its
		selection to the drives of the PC.

CALLED BY:	ParseCodeword

PASS:		ds:si points to '(' of arguments or ending '$'

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandDriveCodeword	proc	near
	.enter
	.leave
	ret
ExpandDriveCodeword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandDirectoryCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine works like ExpandFileCodeword, but restricts its
		selection to directories.

CALLED BY:	ParseCodeword

PASS:		ds:si points to '(' of arguments or ending '$'

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandDirectoryCodeword	proc	near
	.enter
	.leave
	ret
ExpandDirectoryCodeword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandCheckCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine pops up a dialog that presents a message and 
		allows the user to continue or cancel the launcher.

CALLED BY:	ParseCodeword

PASS:		ds:si points to '(' of arguments or ending '$'

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandCheckCodeword	proc	near
	.enter
	.leave
	ret
ExpandCheckCodeword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandArgumentsCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine pops up a dialog that allows the user to type
		in text to be used as arguments.

CALLED BY:	ParseCodeword

PASS:		ds:si points to '(' of arguments or ending '$'

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandArgumentsCodeword	proc	near
	.enter
	.leave
	ret
ExpandArgumentsCodeword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandListCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine pops up a list of choices that the user can
		select.  For each list item there is accompanying text that
		will be appended to the Command String if that item is chosen.

CALLED BY:	ParseCodeword

PASS:		ds:si points to '(' of arguments or ending '$'

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandListCodeword	proc	near
	.enter
	.leave
	ret
ExpandListCodeword	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandDollarCodeword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called when the user wants to pass a '$' 
		character in the Command String and so uses the syntax '$$'.

CALLED BY:	ParseCodeword

PASS:		ds:si - points to character after codeword ('(' or '$')
		es    - LauncherStrings segment
		ax    - characters left to parse in the Command String

RETURN: 	???

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandDollarCodeword	proc	near
	.enter

	

	.leave
	ret
ExpandDollarCodeword	endp



endif





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLauncherFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the filename of the program we want to run.

CALLED BY:	LauncherCommandStringIsSet

PASS:		ds	- sptr to LauncherStrings block

RETURN:		ds:si	- ptr to filename to launch
		bx	- disk handle of filename to launch
		carry	- set if not found
		ax	- error code if not found

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/26/91	Initial version
	dlitwin	3/31/92		Changed to grab DiskSave from file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLauncherFilename	proc	near	uses	cx, dx, bp, di, es
	.enter
	assume	ds:LauncherStrings

	mov	si, offset launcherDiskSave
	ChunkSizeHandle	ds, si, cx
	jcxz	defaultLauncher			; no DiskSave info

	mov	si, ds:[si]			; dereference the DiskSave
	mov	cx, cs				; call back routine is in
	mov	dx, offset LauncherCallBack	;    fptr cx:dx
	call	DiskRestore
	mov	bx, ax				; put disk handle in bx
	mov	ax, ERROR_FILE_NOT_FOUND	; if there was an error...
	mov	si, ds:[launcherFileName]
	jmp	exit

defaultLauncher:
	; if there is no DiskSave information, then we assume that we are
	; looking at the default launcher (if not too bad, their launcher is
	; messed up anyway).  In this case we null out the filename and pass
	; a null disk handle so DosExec will start up command.com.  We also
	; build out SP_TOP to the working directory so command.com has a
	; reasonable working directory.

	mov	si, ds:[launcherFileName]
SBCS <	mov	{byte} ds:[si], 0		; null out filename	>
DBCS <	mov	{wchar} ds:[si], 0		; null out filename	>

	mov	ax, offset launcherWorkingDirectory
	mov	cx, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE
	call	LMemReAlloc			; make sure there is enough room
	push	es				; save dgroup
	segmov	es, ds, di			; put launcherStrings in es
	mov	di, ax				; di is handle of  Working Dir
	mov	di, es:[di]			; dereference Working Dir
	mov	bx, SP_TOP
	mov	dx, -1				; as non-zero as it gets...
	call	FileConstructFullPath
	mov	di, ax
	mov	di, es:[di]			; dereference Working Dir
	mov	bp, di				; save start pos
	clr	ax				; search for null
DBCS <	shr	cx, 1				; # bytes -> # chars	>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	sub	di, bp				; get length
	mov	cx, di
	inc	cx				; account for null
DBCS <	inc	cx							>
	mov	ax, offset launcherWorkingDirectory
	call	LMemReAlloc			; shrink to fit
	pop	es				; restore dgroup

	clr	bx				; no file name, handle is 0

exit:

	assume	ds:dgroup
	.leave
	ret
GetLauncherFilename	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called by DiskRestore if the disk can't
		be found.


CALLED BY:	DiskRestore (called in GetLauncherFilename)

PASS:		ds:dx	= drive name (null-terminated, with trailing ':')
		ds:di	= disk name (null-terminated)
		ds:si	= buffer to which the disk handle was saved
		ax	= DiskRestoreError that would be returned if
				callback weren't being called.
		bx, bp	= as passed to DiskRestore

RETURN:		carry clear if disk should be in drive;
			ds:si	= new position of buffer, if it moved
		carry set if user canceled the restore:
			ax	= error code to return (usually
				  DRE_USER_CANCELED_RESTORE)

DESTROYED:	???
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherCallBack	proc far
	.enter

	mov	bx, handle LauncherErrorStrings
	call	MemLock
	mov	es, ax				; es is errorstrings segment
	assume	es:LauncherErrorStrings

	sub	sp, size StandardDialogParams
	mov	bp, sp				; point ss:bp to stack frame

	mov	ss:[bp].SDP_customFlags, mask CDBF_SYSTEM_MODAL or	\
		(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or		\
		(GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE)

	mov	ss:[bp].SDP_customString.segment, es
	mov	bx, es:[DiskNotFoundSysModal]
	mov	ss:[bp].SDP_customString.offset, bx
	mov	ss:[bp].SDP_stringArg1.segment, ds
	mov	ss:[bp].SDP_stringArg1.offset, di	; disk name
	mov	ss:[bp].SDP_stringArg2.segment, ds
	mov	ss:[bp].SDP_stringArg2.offset, dx	; drive name
	mov	ss:[bp].SDP_customTriggers.segment, cs
	mov	ss:[bp].SDP_customTriggers.offset, \
				offset SDRT_DiskNotFoundSysModal
	movdw	ss:[bp].SDP_helpContext, 0
	call	UserStandardDialog

	cmp	ax, IC_OK			; did they relace the disk?
	jne	canceled

	clc					; clear the carry (no error)
	jmp	exit				; skip to exit

canceled:
	mov	ax, DRE_USER_CANCELED_RESTORE
	stc					; set the carry

exit:
	mov	bx, handle LauncherErrorStrings
	call	MemUnlock
	assume	es:dgroup

	.leave
	ret
LauncherCallBack	endp

SDRT_DiskNotFoundSysModal	label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry	<
		SDRT_DiskNotFoundSysModal_OK,	; SDRTE_moniker
		IC_OK				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry	<
		SDRT_DiskNotFoundSysModal_Cancel,	; SDRTE_moniker
		IC_DISMISS			; SDRTE_responseValue
	>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherFileCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current selection is a directory
		a normal file and enables or disables the "OK"
		button accordingly.  Also edits or creates double-clicked file.

CALLED BY:	GLOBAL
PASS:	 	cx:dx - OD of GenFileSelector (will be needed later when
				default-action support is added)
		bp - 	GenFileSelectorEntryFlags       record

RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/28/92		Stole from mainLauncher.asm and modified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherFileCheck	method LauncherClass, MSG_LAUNCHER_FILE_CHECK
	.enter

	mov	bx, handle AppendFileOK
	mov	si, offset AppendFileOK

	mov	ax, MSG_GEN_SET_NOT_ENABLED	;Assume its NOT a normal file
	push	bp
	test	bp, mask GFSEF_NO_ENTRIES	;If nothing selected, treat
	jne	common				; like directory
	and	bp, mask GFSEF_TYPE 
	cmp	bp, GFSET_FILE shl offset GFSEF_TYPE
	jne	common				;Branch if not a file
	mov	ax, MSG_GEN_SET_ENABLED	;Not a dir, so is a normal file
common:
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	pop	bp
	cmp	ax, MSG_GEN_SET_ENABLED
	jne	exit
	test	bp, mask GFSEF_OPEN		;If double click, activate 
	je	exit				; default button
	mov	ax, MSG_GEN_ACTIVATE
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	.leave
	ret
LauncherFileCheck	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Copied from procClass.asm

;	Default method for creating a new state file name, opening the
; new file & stuffing the name back into the AppAttachBlock.  Called
; from within UI_AttachToStateFile if no state file was passed.  Can
; be subclassed to provide forced state file usage/different naming scheme,
; etc.
;
;	Pass:
;		dx - Block handle to block of structure AppInstanceReference
;		CurPath	- Set to state directory
;
;	Return:
;		ax - VM file handle (0 if you want no state file)

DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherCreateNewStateFile	method	LauncherClass,
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
	clr	ax		;No state file
	ret
LauncherCreateNewStateFile	endp	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherRestoreFromState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	HACK: We determine whether we are starting from state or not
		here.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherRestoreFromState	method LauncherClass,
					MSG_GEN_PROCESS_RESTORE_FROM_STATE
	mov	es:[restarting], TRUE
	mov	di, offset LauncherClass
	call	ObjCallSuperNoLock
	ret
LauncherRestoreFromState	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherErrorHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop up a UserStandardDialog and pass it different strings
		depending on which error code is passed in.

CALLED BY:	global

PASS:		ax	- error code
		ds:si	- filename of file not found
			(if applicable to the error code)

RETURN:		nothing

DESTROYED:	all
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherErrorHandler	proc near
	.enter

	push	ax				; save error code
	mov	bx, handle LauncherErrorStrings	; LauncherErrorStrings segment
	call	MemLock
	mov	es, ax				; lock down into es
	assume	es:LauncherErrorStrings
	mov	bx, ax				; save this segment in bx
	pop	ax				; restore error code

	sub	sp, size StandardDialogParams
	mov	bp, sp				; point bp to stack frame
	mov	ss:[bp].SDP_customFlags, mask CDBF_SYSTEM_MODAL or	\
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or	\
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)

	cmp	ax, ERROR_FILE_NOT_FOUND
	je	loadFileNotFoundString

	cmp	ax, ERROR_ARGS_TOO_LONG
	je	loadParseErrorString

	cmp	ax, ERROR_INSUFFICIENT_MEMORY
	je	loadMemError

	mov	ss:[bp].SDP_customString.segment, bx
	mov	si, es:[DosExecError]
	mov	ss:[bp].SDP_customString.offset, si
	jmp	stackFrameSet

loadFileNotFoundString:
	mov	ss:[bp].SDP_customString.segment, bx ; LauncherErrorStrings seg
	mov	si, es:[NotFoundError]
	mov	ss:[bp].SDP_customString.offset, si
	mov	ax, ds				; put filename seg in ax
	mov	ss:[bp].SDP_stringArg1.segment, ax
	mov	ss:[bp].SDP_stringArg1.offset, si
	jmp	stackFrameSet

loadParseErrorString:
	mov	ss:[bp].SDP_customString.segment, bx ; LauncherErrorStrings seg
	mov	si, es:[ParseError]
	mov	ss:[bp].SDP_customString.offset, si
	jmp	stackFrameSet

loadMemError:
	mov	ss:[bp].SDP_customString.segment, bx ; LauncherErrorStrings seg
	mov	si, es:[OutOfMemoryError]
	mov	ss:[bp].SDP_customString.offset, si

stackFrameSet:
	movdw	ss:[bp].SDP_helpContext, 0
	call	UserStandardDialog

	assume	es:dgroup
	mov	bx, handle LauncherErrorStrings	; LauncherErrorStrings segment
	call	MemUnlock

	.leave
	ret
LauncherErrorHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherRunApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run application was chosen.  Jump back to OpenApplication
		and continue on as if we were never here.

CALLED BY:	MSG_LAUNCHER_RUN_APP

PASS:		*ds:si	= LauncherClass object
		ds:di	= LauncherClass instance data
		ds:bx	= LauncherClass object (same as *ds:si)
		es 	= segment of LauncherClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp (allowed)
SIDE EFFECTS:	
	Does not return.  Jumps to OpenApplication.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/24/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherRunApp	method dynamic LauncherClass, 
					MSG_LAUNCHER_RUN_APP

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle AppOrDocPrompt
	mov	si, offset AppOrDocPrompt
	mov	di, mask MF_CALL
	call	ObjMessage

	; We got here because OpenApplication popped up the
	; dialog box to check for "Run App" or "Read Doc" and
	; the user wisely whose to run the application.  So,
	; since OpenAllication is written the way it is, we can
	; simply set the stage back the way it was in OpenApplication
	; and just jump directly there.  HACK! EEK!
	mov	bx, handle LauncherStrings
	call	MemLock
	mov	ds, ax
	assume ds:LauncherStrings
	mov	si, ds:[launcherFlags]
	assume ds:dgroup
	mov	al, {byte} ds:[si]
	jmp	LauncherOpenApplication__RunAppResume

LauncherRunApp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherReadDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User requested to read the documentation file.
		This will use IACP to launch the document reader
		application indicated by the launcherDocReaderToken.
		
		This function assumes the doc file exists.

CALLED BY:	MSG_LAUNCHER_READ_DOC

PASS:		*ds:si	= LauncherClass object
		ds:di	= LauncherClass instance data
		ds:bx	= LauncherClass object (same as *ds:si)
		es 	= segment of LauncherClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp (allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	9/24/99   	Initial version
	jfh  3/24/00	keep dialog box open and launcher running
				so user can run app after reading doc (fixes bug 1303)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherReadDoc	method dynamic LauncherClass, 
					MSG_LAUNCHER_READ_DOC

   ;	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
   ;	mov	cx, IC_DISMISS
   ;	mov	bx, handle AppOrDocPrompt
   ;	mov	si, offset AppOrDocPrompt
   ;	mov	di, mask MF_CALL
   ;	call	ObjMessage

	; Run application to read doc file.
	;
	; File existence has already been confirmed, BTW.
	;
	mov	bx, handle LauncherStrings
	call	MemLock
	mov	ds, ax
	assume ds:LauncherStrings
	mov	si, ds:[launcherDocFile]		; ds:si = fname
	assume ds:dgroup

	segmov	es, ds, di
	mov	di, si
	clr	al
	mov	cx, 1000h
	repne scasb					; es:di = 1 past NULL
	dec	di
	mov	cx, di					;
	sub	cx, si					; cx = len fname
	mov	bp, cx					; save len in bp
	mov	al, '\\'
	dec	di					; es:di = last char
	std
	repne scasb
	cld
	mov	cx, 0					; len path = 0
	jne	noPath					; ds:si = tail only

	inc	di					; es:di -> last bslash
	mov	cx, di	
	sub	cx, si					; cx = len path
	inc	di					; ds/es:di = tail
	sub	bp, di
	add	bp, si					; bp = len tail
	xchg	si, di

	; ds:si	= tail, bp = tail len
	; ds:di = path, cx = path len

	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
   LONG	jc	ackDie

	mov	bx, dx
	call	MemLock
	mov	es, ax
	jcxz	noPath

	push	si
	mov	si, di
	; check for drive letter here,
	cmp	{byte}ds:[si+1], C_COLON
	jne	loadCopy
	mov	al, ds:[si]
	mov	ah, C_CAP_A
	cmp	al, ah
	jb	loadCopy
	cmp	al, C_CAP_Z
	jbe	haveDisk
	mov	ah, C_SMALL_A
	cmp	al, ah
	jb	loadCopy
	cmp	al, C_SMALL_Z
	ja	loadCopy
haveDisk:
	inc	si					; move ds:si past drv
	inc	si
	dec	cx					; 2 less bytes to copy
	dec	cx
	sub	al, ah					; 0-based drive #
	call	DiskRegisterDiskSilently		; bx = disk handle
	jc	loadCopy				; hmm. no disk.
	mov	es:[ALB_diskHandle], bx
	tst	cx					; path is "\" if len=0
	jne	loadCopy				; branch if not
	inc	cx					; copy that slash	

loadCopy:
	lea	di, es:[ALB_path]
	cmp	cx, size ALB_path
	jle	copyPath
	mov	cx, size ALB_path
copyPath:
	rep movsb
	pop	si

noPath:
	lea	di, es:[ALB_dataFile]
	mov	cx, size ALB_dataFile
	cmp	bp, cx
	jg	copyTail
	mov	cx, bp
copyTail:
	rep movsb

	mov	bx, dx
	call	MemUnlock
	
	segmov	es, ds, di
	assume es:LauncherStrings
	mov	di, es:[launcherDocReaderToken]		; es:di = reader token
	clr	cx, dx
	mov	ax, mask IACPCF_FIRST_ONLY or \
		    (IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	call	IACPConnect
	jc	ackDie

	; if successful, appLaunchBlock is free'd.
	; just shutdown connection so we aren't hooked to it anymore
	clr	cx, dx
	call	IACPShutdown

ackDie:
	mov	bx, handle LauncherStrings
	call	MemUnlock
	; No matter what, the launcher quits at this point.
	;
  ;	mov	ax, MSG_META_QUIT
  ;	mov	bx, handle LauncherApp
  ;	mov	si, offset LauncherApp
  ;	mov	di, mask MF_CALL
  ;	GOTO	ObjMessage			;;; <<<--- EXIT POINT

     ; nah - let's just return
	.leave
	ret

LauncherReadDoc	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LauncherSetupAppOrDocPrompt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the contents of the AppOrDocPrompt dialog.

CALLED BY:	LauncherOpenApplication
PASS:		ds - LauncherStrings
RETURN:		nothing
DESTROYED:	ax, cx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Replace AppOrDocText with custom text

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	7/28/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LauncherSetupAppOrDocPrompt	proc	near
	uses	bx, dx, bp
	.enter
	assume	ds:LauncherStrings

	;
	; If launcherAppOrDocCustomText is not null, replace the contents
	; of AppOrDocText with the string.
	;
	mov	bp, ds:[launcherAppOrDocCustomText]
SBCS <	tst	<{byte} ds:[bp]>					>
DBCS <	tst	<{wchar} ds:[bp]>					>
	jz	done			; no custom text
	mov	dx, ds			; dx:bp <- string
	clr	cx			; cx <- null-terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bx, handle AppOrDocText
	mov	si, offset AppOrDocText
	mov	di, mask MF_CALL
	call	ObjMessage

done:
	.leave
	ret
LauncherSetupAppOrDocPrompt	endp

Main	ends
