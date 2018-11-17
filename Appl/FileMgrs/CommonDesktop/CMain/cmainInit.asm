COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cmainInit.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/15/92   	Initial version.

DESCRIPTION:
	Initialization code for DesktopClass	

	$Id: cmainInit.asm,v 1.9 98/08/20 08:18:49 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


InitCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start up desktop

CALLED BY:	MSG_META_ATTACH

PASS:		dx - AppLaunchBlock, if any
		es - segment of DesktopClass

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopAttach	method	DesktopClass, MSG_META_ATTACH
	uses	ax
	.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	mov	al, FALSE
	mov	es:[willBeDetaching], al
ifndef ZMGR
if _TREE_MENU		
GMONLY <	mov	es:[treeRelocated], al	; no Tree Window for FileCabinet >
endif
endif
	mov	es:[modalBoxUp], al
	mov	es:[hackModalBoxUp], al
	mov	es:[forceQuit], al
	mov	es:[doingMultiFileLaunch], al
	mov	es:[loggingOut], al

	mov	al, TRUE
	;
	; assume startFromScratch true
	; will set FALSE in MSG_GEN_PROCESS_RESTORE_FROM_STATE handler
	;
	mov	es:[startFromScratch], al
	mov	es:[showDeleteProgress], al
	mov	es:[fileOpProgressType], FOPT_NONE


	.leave
	; call superclass
	;
	segmov	es, <segment DesktopClass>, di
	mov	di, offset DesktopClass
	GOTO	ObjCallSuperNoLock
DesktopAttach	endp

DesktopRestoreFromState	method	DesktopClass,
					MSG_GEN_PROCESS_RESTORE_FROM_STATE
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	es:[startFromScratch], FALSE
	pop	es
	mov	di, offset DesktopClass
	call	ObjCallSuperNoLock

if _NEWDESKBA
	;
	; Since we are restoring from state, make sure there is an active
	; FT under the field.  We need to do this because when we logged out,
	; there was no active FT.
	;
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	UserCallApplication
endif

	ret
DesktopRestoreFromState	endm


if	_PCMCIA_FORMAT


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopOpenComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we shutdown to format a pcmcia card.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of DesktopClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopOpenComplete	method extern dynamic DeskApplicationClass, 
					MSG_GEN_APPLICATION_OPEN_COMPLETE
	.enter

	mov	di,offset DeskApplicationClass
	call	ObjCallSuperNoLock

	call	DesktopHandlePCMCIAFormatOnOpenComplete

	.leave
	ret
DesktopOpenComplete		endm





endif	;_PCMCIA_FORMAT

InitCode	ends


DetachCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	exit file system

CALLED BY:	MSG_META_DETACH

PASS:		dx:bp - MSG_META_ACK OD

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version
	dlitwin	03/25/93	added Empty WB on logout and Unhook
				of SortView pop up menu

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDetach	method	DesktopClass, MSG_META_DETACH
	push	ax, dx, si, bp, es		; save params
	;
	; handle forced quit
	;
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	cmp	es:[forceQuit], TRUE
	jne	notForced
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; report error
	call	DesktopOKError			; wait for user acknowledge
notForced:
	call	CloseDialogBoxes

if _GMGRONLY
if not _ZMGR
			; state
if _ICON_AREA
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCallFixup		; take down dialog
endif	; _ICON_AREA
endif

	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	mov	bp, mask CCF_MARK_DIRTY
	mov	bx, segment GenClass
	mov	si, offset GenClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
if _ICON_AREA
	mov	cx, di
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCallFixup
endif	; _ICON_AREA
endif		; if _GMGRONLY

if not _DOCMGR
if _GMGRONLY or (_NEWDESK and (not GPC_WASTEBASKET_EMPTY))
if (not (_ZMGR))
	;
	; Skip emptying the Wastebasket if we are closing for any
	; reason other than a regular shutdown
	;
	clr	bx
	call	SysSetExitFlags
	test	bl, mask EF_PANIC or mask EF_RUN_DOS or		\
			mask EF_OLD_EXIT or mask EF_RESET
	jnz	skipEmptyWastebasket

	mov	ss:[loggingOut], TRUE
	mov	ax, MSG_EMPTY_WASTEBASKET
	mov	bx, handle 0			; send to process
	call	ObjMessageCall

skipEmptyWastebasket:
endif		; if (not (_ZMGR or _NIKE))
endif		; if _GMGRONLY or _NEWDESK
endif	; if not _DOCMGR

if GPC_FOLDER_WINDOW_MENUS
	call	NDUnhookWBOptionsMenu
else
ND<	call	NDUnhookSortViewMenu	>
endif

	;
	; call superclass (UI) to exit
	;
	pop	ax, dx, si, bp, es		; save params
	mov	di, offset DesktopClass
	call	ObjCallSuperNoLock
	ret
DesktopDetach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return block of state information to save when quitting

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		nothing

RETURN:		cx - handle of block of state information

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/27/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopCloseApplication	method	DesktopClass, MSG_GEN_PROCESS_CLOSE_APPLICATION
	push	ax, cx, dx, si, bp, es		; save params

if _CONNECT_TO_REMOTE
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	call	AbortFileLinking
endif
	;
	; remove ourselves from file change notification
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	mov	cx, handle 0
	clr	dx
	call	GCNListRemove
if GPC_SIGN_UP_ICON
	;
	; watch for IFE_OWNER_INFO (reg/sign-up status)
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_NOTIFY_INIT_FILE_CHANGE
	mov	cx, handle 0
	clr	dx	
	call	GCNListRemove
endif

if _NEWDESKBA
	;
	; Remove the APP OBJECT from GCNSLT_SHUTDOWN_CONTROL.
	;
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	mov	cx, handle Desktop		
	mov	dx, offset Desktop		
	call	GCNListRemove
endif	; if _NEWDESKBA



if OPEN_CLOSE_NOTIFICATION
	;
	; turn off open/close notification
	;

	call	FileDisableOpenCloseNotification
endif
		
if _NEWDESKBA and not GPC_NO_PRINT

	;
	; Set the printer redirection for DOS apps
	;
	call	NewDeskSetPrinterRedirection

endif		; if _NEWDESK
	
	;
	; remove ourselves to GenApplication GCN List for display control
	; notification
	;
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ax, handle 0
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type,			\
				GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, size GCNListParams
	mov	di, mask MF_CALL or mask MF_STACK
	mov	bx, handle Desktop
	mov	si, offset Desktop
	call	ObjMessage
	add	sp, size GCNListParams
	;
	; clobber global stuff
	;
	mov	di, ss:[calcGState]
	call	GrDestroyState
	mov	ss:[exitFlag], 1		; indicate exiting
	push	bx
	mov	bx, ss:[commandInfoBlock]	; COMMAND.COM info
	tst	bx
	jz	noComBlock
	call	MemFree				; free it
noComBlock:
	pop	bx
	;
	; call stupid superclass
	;
	pop	ax, cx, dx, si, bp, es		; retrieve params
	mov	di, offset DesktopClass
	call	ObjCallSuperNoLock
	;
	; return extra state block
	;
;don't return collapsed branch buffer as disk handles won't match after
;shutdown
;	mov	cx, ss:[collapsedBranchBuffer]	; save collapsed paths
	mov	cx, 0
	ret
DesktopCloseApplication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Guided and Unguided each will have a permanent state file
		name.

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		*ds:si	= DesktopClass object
		ds:di	= DesktopClass instance data
		ds:bx	= DesktopClass object (same as *ds:si)
		es 	= segment of DesktopClass
		ax	= message #
		dx	= Block handle to block of structure AppLaunchBlock
		CurPath	= Set to state directory
RETURN:		ax	= VM file handle (0 if we don't want a state
			  file/couldn't create one).
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/22/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _NEWDESKBA	;--------------------------------------------------------------

guidedStateFile		char	"NEWDESKG.STA", C_NULL
unguidedStateFile	char	"NEWDESKU.STA", C_NULL

DesktopCreateNewStateFile	method dynamic DesktopClass, 
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
	push	dx
	segmov	ds, cs
	mov	dx, offset cs:[guidedStateFile]
	call	UtilAreWeInEntryLevel?
	jc	createState
	mov	dx, offset cs:[unguidedStateFile]

createState:
	mov	ax, (VMO_CREATE_TRUNCATE shl 8) or mask VMAF_FORCE_DENY_WRITE \
			or mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION
	clr	cx			; Use standard compaction threshhold
	call	VMOpen
	pop	si			; si = AppLaunchBlock
	jc	error

	mov	bp, bx			; bp = VM file handle
	mov	bx, si			; bx = AppLaunchBlock
	mov	si, dx			; ds:si = state file name

	.assert (size guidedStateFile eq size unguidedStateFile)

	call	MemLock			; lock AppLaunchBlock
	mov	es, ax
	mov	di, offset AIR_stateFile
	mov	cx, size guidedStateFile
	rep	movsb
	call	MemUnlock

	mov	ax, bp
	ret				; <==== GOOD EXIT

error:
	clr	ax			; no state file created
	ret				; <==== BAD EXIT
DesktopCreateNewStateFile	endm

endif	;----------------------------------------------------------------------


if _NEWDESKBA and not GPC_NO_PRINT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewDeskSetPrinterRedirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the printer redirection so that the output of DOS
		apps will go to the right place.

CALLED BY:	DesktopCloseApplication

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
portKey	char "port",0
netPortName char "CUSTOM:NET",0
queueKey char "queue",0

NewDeskSetPrinterRedirection	proc far
		uses	ds
		
printerName	local	GEODE_MAX_DEVICE_NAME_SIZE dup (char)
port		local	GEODE_MAX_DEVICE_NAME_SIZE dup (char)
queue		local	GEODE_MAX_DEVICE_NAME_SIZE dup (char)
		
		.enter
		
	;
	; Get the default printer from the spool library
	;
		call	SpoolGetDefaultPrinter
		segmov	es, ss
		lea	di, ss:[printerName]
		call	SpoolGetPrinterString
		jc	done
		
	;
	; Read the port name for this printer
	;
		
		push	bp
		segmov	ds, es
		mov	si, di			; ds:si - category name
		mov	cx, cs
		mov	dx, offset portKey
		lea	di, ss:[port]
		mov	bp, size port
		call	InitFileReadString
		pop	bp
		jc	done
		
	;
	; See if the port name matches CUSTOM:NET.  If not, bail.
	;
		
		segmov	ds, cs
		mov	si, offset netPortName
		mov	cx, size netPortName
		repe	cmpsb
		jne	done
		
	;
	; It does, so fetch the queue key, and set the redirection.
	;
		
		push	bp
		segmov	ds, ss
		lea	si, ss:[printerName]
		mov	cx, cs
		mov	dx, offset queueKey
		lea	di, ss:[queue]
		mov	bp, size queue
		call	InitFileReadString
		pop	bp
		jc	done
		
		mov	cx, ss
		lea	dx, ss:[queue]
		mov	bx, PARALLEL_LPT1
		call	NetPrintStartCapture
done:	
		
		.leave
		ret
		
NewDeskSetPrinterRedirection	endp
endif		; if _NEWDESK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseDialogBoxes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	closes a table of dialog boxes

CALLED BY:	DesktopDetach

PASS:		none
RETURN:		none
DESTROYED:	all

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseDialogBoxes	proc	near
	.enter

	mov	cx, NUM_DIALOG_BOXES
	clr	di
dialogLoop:
	push	cx, di
	mov	bx, cs:[dialogHandleTable][di]
	mov	si, cs:[dialogOffsetTable][di]
	mov	ax, cs:[dialogMethodTable][di]
	mov	cx, IC_DISMISS	; in case MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessageCallFixup
	pop	cx, di
	add	di, 2
	loop	dialogLoop

	.leave
	ret
CloseDialogBoxes	endp



dialogHandleTable	label	word
	word	handle RenameFromEntry
NOTFC<	word	handle ChangeAttrNameList ; no Change Attr in FileCabinet >
	word	handle DuplicateFromEntry
	word	handle GetInfoFileList

NUM_DIALOG_BOXES = ($-dialogHandleTable)/2

dialogOffsetTable	label	word
	word	offset RenameFromEntry
NOTFC<	word	offset ChangeAttrNameList ; no Change Attr in FileCabinet >
	word	offset DuplicateFromEntry
	word	offset GetInfoFileList

.assert (($-dialogOffsetTable)/2) eq NUM_DIALOG_BOXES

dialogMethodTable	label	word
	word	MSG_CLEAR_FILE_LIST
NOTFC<	word	MSG_CLEAR_FILE_LIST ; no Change Attr in FileCabinet	>
	word	MSG_CLEAR_FILE_LIST
	word	MSG_CLEAR_FILE_LIST

.assert (($-dialogMethodTable)/2) eq NUM_DIALOG_BOXES

DetachCode	ends





InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore saved state

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		cx - AppAttachFlags
		dx - AppLaunchBlock handle
		bp - handle of block of extra state information

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/27/89		Initial version
	dlitwin 9/18/92		Added NewDesk initialization stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DesktopOpenApplication	method	dynamic DesktopClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION

	push	ax, cx, dx, ds, si, bp, es	; save params

	;
	; read the settings in the ini file - CP
	;
GM<	call	InitFolderCachingVars			>

	;
	; clear willBeDetaching again to handle GenAppLazarus - brianc 7/29/93
	;
	mov	ss:[willBeDetaching], FALSE
	; some others, just in case
	mov	ss:[forceQuit], FALSE

	mov	ax, SP_TOP
	call	FileSetStandardPath	; start off in a safe directory

if OPEN_CLOSE_NOTIFICATION

	;
	; Ask the kernel to notify us whenever files are
	; opened/closed. 
	;

	call	FileEnableOpenCloseNotification

endif		; if _NEWDESK

BA<	call	BASetUserTypeIndex			>
BA<	call	SetDesktopCreateFolderPermissions	>
BA<	call	BASetStudentPermissions			>
BA<	call	BATrimGuidedDesktopMenu			>

ifndef 	ZMGR			; no Tree Window for zoomer
if _TREE_MENU			; no Tree Window for NIKE
if 	_GMGRONLY		; no Tree Window for FileCabinet
	tst	bp				; check if anything
	jnz	haveState			; if so, use it
	;
	; allocate buffer for collapsed branches
	;
	mov	ss:[collapsedBranchBuffer], 0	; in case error
	mov	ax, (INIT_NUM_COLLAPSED_BRANCH_BUFFER_ENTRIES)* \
					(size CollapsedBranchEntry)
	mov	ss:[collapsedBranchBufSize], ax	; save size
	mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE or \
					(mask HAF_ZERO_INIT shl 8)
						; init to zeros
	call	MemAlloc
	jnc	save				; if no error, use it
memError:
	mov	ss:[forceQuit], TRUE		; mark as forced-quit
	jmp	short afterErr

haveState:
	mov	bx, bp
	push	bx				; save extra data block handle
	mov	ax, MGIT_SIZE
	call	MemGetInfo			; get size of extra block
	clr	dx				; dx:ax = block size in bytes
	mov	bx, size CollapsedBranchEntry	; bx = size of entries in block
	div	bx				; ax = # entries in block
	mul	bx				; ax = actual size of block
	mov	ss:[collapsedBranchBufSize], ax	; save actual size
	push	ax				; save size
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	jnc	noErr
	add	sp, 4				; clean up stack
	jmp	short memError			; handle error

noErr:
	mov	bp, bx				; save new collapsed buffer
	mov	es, ax
	clr	di
	pop	cx				; retrieve extra block size
	pop	bx				; retrieve extra block handle
	call	MemLock				; lock it
	mov	ds, ax
	clr	si
	rep movsb				; copy over to collapsed buffer
	call	MemUnlock			; unlock extra block
						;	(freed by UI)
	mov	bx, bp				; retrieve collapsed buffer
	call	MemUnlock			; unlock it
save:
	mov	ss:[collapsedBranchBuffer], bx	; save collapsed paths buffer
afterErr:
endif		; if _GMGRONLY
endif		; if _TREE_MENU		
endif		; if (not _ZMGR)
	;
	; do pre-superclass stuff
	;
	call	DoPreSuperClassStartup
	;
	; pass on to superclass
	;
	pop	ax, cx, dx, ds, si, bp, es	; retrieve params.
	mov	di, offset DesktopClass
	call	ObjCallSuperNoLock

ifndef GPC_ONLY
if _GMGRONLY or _NEWDESK
	; Force the application to install it's token into the token
	; database. If the token isn't in the database, and the user
	; browses to the directory the file manager is in, we'll get a
	; crash because of the attempt to launch another copy of the
	; app in order to install the token.  edigeron 10/24/00
	mov	ax, MSG_GEN_APPLICATION_INSTALL_TOKEN
	mov	bx, handle Desktop
	mov	si, offset Desktop
	mov	di, mask MF_CALL
	call	ObjMessage
endif
endif
		
if _GMGRONLY
if not _ZMGR		; ZManager has floating drives button in icon area,
			;	let user initiate it herself!
if _ICON_AREA
	mov	ax, MSG_TA_GET_DRIVE_LOCATION
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall
	cmp	cl, DRIVES_FLOATING
	jne	notFloating
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall

notFloating:
endif	; _ICON_AREA
endif
endif		; if _GMGRONLY

	;
	; add ourselves to GenApplication GCN List for display control
	; notification
	;
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	ax, handle 0
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type,	\
				GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, size GCNListParams
	mov	di, mask MF_CALL or mask MF_STACK
	mov	bx, handle Desktop
	mov	si, offset Desktop
	call	ObjMessage
	add	sp, size GCNListParams

if GPC_UI_LEVEL_DIALOG

	; raise the UI level dialog if this is our first launch
		
	call	DoUILevelDialog
endif

	;
	; open Application directory if starting from scratch
	;

	cmp	ss:[startFromScratch], FALSE
	je	afterOpen

if _GMGR and not _HMGR and (not SINGLE_DRIVE_DOCUMENT_DIR)

	;
	; Likely should have .INI entry for determining which
	; directory to show first, but we don't so just set
	; the value here (note that this was previously
	; SP_APPLICATIONS). -DLR 10/4/98
	;
if not _GMGR
	mov	bx, SP_DOCUMENT
else
if _DOCMGR
	mov	bx, SP_DOCUMENT
else
	mov	bx, SP_APPLICATION
endif
endif

NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset InitNullPath				>
FXIP <		mov	dx, ss						>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	bp, sp			;dx:bp = null string	>
	call	CreateMaxFolderWindow
FXIP <		pop	bp						>
endif

if _HMGR
NOFXIP <	mov	dx,cs						>
NOFXIP <	mov	bp,offset rootDir				>
FXIP <		mov	dx, ss						>
FXIP <		mov	bp, C_BACKSLASH					>
FXIP <		push	bp						>
FXIP <		mov	bp, sp						>
	mov	bx,ss:[geosDiskHandle]
	call	CreateMaxFolderWindow
FXIP <		pop	bp						>
endif

if SINGLE_DRIVE_DOCUMENT_DIR

	; For word processors

	mov	cl, DOCUMENT_DRIVE_NUM
	mov	ax, MSG_DRIVETOOL_INTERNAL
	mov	bx, handle 0
	call	ObjMessageForce
endif
		

if _NEWDESK
	mov	bx, STANDARD_PATH_OF_DESKTOP_VOLUME
	mov	dx, cs
	mov	bp, offset InitDesktopPath
	mov	ax, NIL				; zoom lines from center>
	mov	cx, WOT_DESKTOP
	call	CreateNewFolderWindow

BA<	call	OpenSpecialBAFolders  			>

endif



afterOpen:

if _NEWDESKBA
	;
	; Set the assistance window usable in entry level
	;
	call	UtilAreWeInEntryLevel?
	jnc	afterAssistance
	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, handle AssistantPrimary
	mov	si, offset AssistantPrimary
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageForce

afterAssistance:

	;
	; Add the app object to the GCNSLT_SHUTDOWN_CONTROL system notification
	; list so we can turn off input across a suspend.
	;
	mov	cx, handle Desktop
	mov	dx, offset Desktop
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_SHUTDOWN_CONTROL
	call	GCNListAdd

endif	; _NEWDESKBA

	cmp	ss:[forceQuit], TRUE		; need to quit?
	jne	exit				; nope
	mov	ax, MSG_META_QUIT			; else, queue up a quit
	mov	bx, handle Desktop		; bx:si = GenApp
	mov	si, offset Desktop
	call	ObjMessageForce
exit:
	ret
DesktopOpenApplication	endp

if not SINGLE_DRIVE_DOCUMENT_DIR
ife FULL_EXECUTE_IN_PLACE
GM< LocalDefNLString	InitNullPath	<0>				>
endif
endif

if _HMGR
LocalDefNLString	rootDir	<C_BACKSLASH, 0>
endif

ND< LocalDefNLString	InitDesktopPath	<ND_DESKTOP_RELATIVE_PATH, 0>	>


if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BASetUserTypeIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the baUserType to an index value based on the
		Iclas UserType

CALLED BY:	DesktopOpenApplication

PASS: 		none
RETURN:		none (baUserTypeIndex set correctly)
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/05/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BASetUserTypeIndex	proc	near
	uses	ax
	.enter

	call	IclasGetCurrentUserType
	cmp	ah, UT_GENERIC
	jne	checkStudent
	clr	ss:[baUserTypeIndex]
	jmp	exit
checkStudent:
	cmp	ah, UT_STUDENT
	jne	checkAdmin
	mov	ss:[baUserTypeIndex], 2
	jmp	exit
checkAdmin:
	cmp	ah, UT_ADMIN
	jne	checkTeacher
	mov	ss:[baUserTypeIndex], 4
	jmp	exit
checkTeacher:
	cmp	ah, UT_TEACHER
	jne	checkOffice
	mov	ss:[baUserTypeIndex], 6
	jmp	exit
checkOffice:
	;
	; default to office worker, if things aren't right in non-ec
	;
EC<	cmp	ah, UT_OFFICE				>
EC<	ERROR_NE	ERROR_INVALID_ICLAS_USER_TYPE	>
	mov	ss:[baUserTypeIndex], 8

exit:
	.leave
	ret
BASetUserTypeIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDesktopCreateFolderPermissions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the desktop pop up menu item "Create Folder" not usable
		if the user doesn't have permissions to create a folder.

CALLED BY:	DesktopOpenApplication

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/ 4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDesktopCreateFolderPermissions	proc	near
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	call	IclasGetUserPermissions
	test	ax, mask UP_CREATE_FOLDER
	jnz	hasPermission

	mov	bx, handle DesktopMenuCreateFolder
	mov	si, offset DesktopMenuCreateFolder
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjMessageCall

hasPermission:
	.leave
	ret
SetDesktopCreateFolderPermissions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BASetStudentPermissions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the user is a student or generic student, we set the
		NetworkPrinterConsole and Attributes GlobalMenu triggers
		not usable.

CALLED BY:	DesktopOpenApplication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/20/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BASetStudentPermissions	proc	near
	uses	ax,bx,cx,dx,si,di,bp

	cmp	ss:[baUserTypeIndex], 4
	jge	noRestriction

	.enter
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	bx, handle GlobalMenuNetworkPrinterConsole
	mov	si, offset GlobalMenuNetworkPrinterConsole
	call	ObjMessageCall
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	bx, handle GlobalMenuAttributes
	mov	si, offset GlobalMenuAttributes
	call	ObjMessageCall
	.leave

noRestriction:
	ret
BASetStudentPermissions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BATrimGuidedDesktopMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are in Guided Mode, we don't want certain items in
		the Desktop popup menu.  Luckily this is always a fixed object
		(not copied from a template when the folder is opened like
		other folder's menus) because the desktop is always open.

CALLED BY:	DesktopOpenApplication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/10/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BATrimGuidedDesktopMenu	proc	near
	uses	ax,bx,cx,dx,bp,di,si

	call	UtilAreWeInEntryLevel?
	jnc	notEntryLevel
	.enter

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	bx, handle DesktopMenuSelectAll
	mov	si, offset DesktopMenuSelectAll
	mov	dl, VUM_NOW
	call	ObjMessageCall

	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	bx, handle DesktopMenuCreateFolder
	mov	si, offset DesktopMenuCreateFolder
	mov	dl, VUM_NOW
	call	ObjMessageCall

	.leave
notEntryLevel:
	ret
BATrimGuidedDesktopMenu	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenSpecialBAFolders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens special folders depending on who we are (student,
		teacher, entry level etc.)

CALLED BY:	DesktopOpenApplication

PASS:		^lcx:dx	= Desktop FolderClass object
RETURN:		none
DESTROYED:	ax, cx, dx, bp, di, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/09/92	Initial version
	joon	12/16/92	Handle auto login to a class

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenSpecialBAFolders	proc	near
desktopFolder	local	optr			push	cx, dx
classesFolder	local	optr
autologinClass	local	IclasPathStruct
classNameBuffer	local	CLASS_DESCRIPTION_LENGTH+1 dup (char)

	.enter

	mov	dx, WOT_STUDENT_CLASSES
	cmp	ss:[baUserTypeIndex], 2		; UT_STUDENT
	je	openFolder

	cmp	ss:[baUserTypeIndex], 0		; UT_GENERIC
	je	openFolder

	mov	dx, WOT_TEACHER_CLASSES
	cmp	ss:[baUserTypeIndex], 6		; UT_TEACHER
	je	openFolder

	cmp	ss:[baUserTypeIndex], 8		; UT_OFFICE
	jne	done				;any other type of user

	mov	dx, WOT_OFFICE_HOME

openFolder:
	push	bx, si, bp
	movdw	bxsi, ss:[desktopFolder]
	mov	ax, MSG_ND_FOLDER_OPEN_NEWDESK_OBJECT
	call	ObjMessageCall
	mov	di, ax				;save GeosFileType
	pop	bx, si, bp
	jc	done

	cmp	di, GFT_DIRECTORY		;make sure we opened a folder
	jne	done

	cmp	ss:[baUserTypeIndex], 0		; UT_GENERIC
	je	student

	cmp	ss:[baUserTypeIndex], 2		; UT_STUDENT
	jne	done

student:
	movdw	ss:[classesFolder], cxdx	;save classesFolder optr

	mov	ax, TRUE			;delete autologin file
	mov	cx, ss
	lea	dx, ss:[autologinClass]
	call	IclasGetAutologClass		;check for class to autologinto
	jc	done

	movdw	esdi, cxdx
	mov	cx, ss
	lea	dx, ss:[classNameBuffer]
	call	IclasPathStructToGeosClassName	;get geos name for class
	jc	done

	push	bx, si, bp
	movdw	bxsi, ss:[classesFolder]
	mov	ax, MSG_FOLDER_OPEN_ICON
	call	ObjMessageCall		;open class folder
	pop	bx, si, bp
done:
	.leave
	ret
OpenSpecialBAFolders	endp

endif		; if _NEWDESKBA



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPreSuperClassStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	startup stuff

CALLED BY:	DesktopOpenApplication

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoPreSuperClassStartup	proc	near
	;
	; initialize global variables
	;
	call	InitGlobalVariables

if _WRITABLE_TOKEN_DATABASE
	;
	; add default monikers for files and folders
	;
	call	SetUpDesktopMonikers		; set up private monikers
endif
	;
	; make UI changes for small screens
	;
GM<	call	MakeSmallScreenChanges		>
	;
	; disable DOS launcher stuff via .ini file
	;
if not _NEWDESK
	call	DisableDosLaunchersViaIniFile
endif			; if (not _NEWDESK)

if _WRITABLE_TOKEN_DATABASE
	;
	; disable launching apps to get token via .ini file
	;
	call	DisableTokenLaunching
endif

	;
	; set background color for folder windows
	;
	call	SetDefaultFolderBackgroundColor

if GPC_DEBUG_MODE
	;
	; set debug mode options
	;
	call	SetDebugModeOptions
endif

if GPC_CREATE_DESKTOP_LINK
	;
	; set create link options
	;
	call	SetCreateLinkOptions
endif

	;
	; get display type
	;	needed for SetUpFontAndGState and LookUpDesktopMonikers
	;
;	mov	bx, handle GenAppInterface
;	mov	si, offset GenAppInterface:Desktop
;	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
;	call	ObjMessageCallFixup		; ah - display type
;						; bp - system font pointsize
;use VUP_QUERY to field, to avoid building GenApp object - brianc 4/21/92
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, VUQ_DISPLAY_SCHEME		; get display scheme
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	mov	bx, handle Desktop
	mov	si, offset Desktop
	mov	ax, MSG_GEN_CALL_PARENT
	call	ObjMessageCall		; ah = display type, bp = ptsize
;end of change
	mov	ss:[desktopDisplayType], ah
	;
	; set up desktop font and pointsize and create global calc gState
	;	bp = system font pointsize
	;
	call	SetUpFontAndGState

if _GMGR and not _ZMGR and _ICON_AREA
	cmp	ss:[startFromScratch], TRUE
	jne	skipLoadingOptions
	;
	; Ask the drives list where the drives are.  This means this
	; object will load its options twice, which is a waste, but
	; the only real fix is to move all the drive creation stuff
	; into the UI thread, which would be quite a hassle.
	;
	mov	bx, handle OptionsDrivesList
	mov	si, offset OptionsDrivesList
	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjMessageCallFixup	

	mov	bx, handle OptionsDrivesList	; to GeoManager
	mov	si, offset OptionsDrivesList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCallFixup
	mov	cl, al				; cl = DriveButtonLocations
	mov	ax, MSG_TA_SET_DRIVE_LOCATION
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCallFixup
skipLoadingOptions:
endif		; if _GMGR and not _ZMGR and _ICON_AREA
	;
	; get mappings from geos.ini file
	;
	call	GetInitFileMappings

	;
	; before initializing drives, clean up after GenAppLazarus by
	; destroying any existing drives.  If we started normally, there
	; will be no drives to destroy.
	;
GM<	call	GMClearDrives			>
	;
	; add ourselves for file system change notification
	; (we only handle MSG_NOTIFY_DRIVE_CHANGE)
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_FILE_SYSTEM
	mov	cx, handle 0
	clr	dx
	call	GCNListAdd
if GPC_SIGN_UP_ICON
	;
	; watch for IFE_OWNER_INFO (reg/sign-up status)
	;
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_NOTIFY_INIT_FILE_CHANGE
	mov	cx, handle 0
	clr	dx	
	call	GCNListAdd
endif

	;
	; initialize drives
	;
GM<	call	GMInitDrives			>
ND<	call	NDInitDrives			>
 	;

	;
	; initialize desktop
	;
ND <	call	NDInitDesktop			>

	;
	; get system directory pathnames
	;
	call	GetSystemPathnames
if _DOCMGR
	;
	; position window based on video mode
	;
	push	bx, cx, dx, di, si, bp
	mov	dx, (size AddVarDataParams) + (size SpecWinSizePair)
	sub	sp, dx
	mov	bp, sp
	mov	si, bp
	add	si, size AddVarDataParams
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ss:[bp].AVDP_data.offset, si
	mov	ss:[bp].AVDP_dataSize, size SpecWinSizePair
	mov	ss:[bp].AVDP_dataType, \
			HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
	mov	ss:[si].SWSP_x, mask SWSS_RATIO or PCT_20  ; TV
	mov	ss:[si].SWSP_y, mask SWSS_RATIO or PCT_35
	call	UserGetDisplayType
	push	ax
	and	ah, mask DT_DISP_SIZE
	cmp	ah, DS_STANDARD shl offset DT_DISP_SIZE
	pop	ax
	jne	notStandard				; probably 800x600
	and	ah, mask DT_DISP_ASPECT_RATIO
	cmp	ah, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	je	addVarData				; TV
	mov	ss:[si].SWSP_x, mask SWSS_RATIO or PCT_20  ; 640x480
	mov	ss:[si].SWSP_y, mask SWSS_RATIO or (PCT_35+(PCT_40-PCT_35)/2)
	jmp	short addVarData
		
notStandard:
	mov	ss:[si].SWSP_x, mask SWSS_RATIO or PCT_25  ; 800x600
	mov	ss:[si].SWSP_y, mask SWSS_RATIO or PCT_40
addVarData:
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	bx, handle FileSystemDisplay
	mov	si, offset FileSystemDisplay
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, (size AddVarDataParams) + (size SpecWinSizePair)
	pop	bx, cx, dx, di, si, bp
endif
	ret
DoPreSuperClassStartup	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitGlobalVariables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize global variables

CALLED BY:	DesktopOpenApplication

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/03/89	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitGlobalVariables	proc	near
	.enter

	mov	ss:[targetFolder], 0	; no windows opened yet
	mov	ss:[exitFlag], 0	; not handling MSG_META_DETACH yet

	.leave
	ret
InitGlobalVariables	endp


if _GMGR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeSmallScreenChanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make UI changes for small screens

CALLED BY:	DoPreSuperClassStuff

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	09/26/92	Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeSmallScreenChanges	proc	near
	.enter

	mov	ss:[smallScreen], FALSE
	;
	; presumptuous way to get screen size
	;
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	ax, MSG_VIS_GET_SIZE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	mov	bx, handle Desktop
	mov	si, offset Desktop
	mov	ax, MSG_GEN_CALL_PARENT
	call	ObjMessageCallFixup		; cx = width, dx = height
	cmp	cx, DESKTOP_SMALL_SCREEN_WIDTH_THRESHOLD
	ja	normalScreen
	;
	; we're on a small screen
	;
	mov	ss:[smallScreen], TRUE
normalScreen:
	;
	; If small screen:
	;
	; turn on 'maximized-name-on-primary', so we can take advantage of
	; the UI's feature of showing only the 'maximized-name-on-primary'
	; instead of both the app name and the 'maximized-name-on-primary'
	; when on a small screen.  This allows us to never show the folder
	; path in the FolderInfo area of Folder windows, leaving that valuable
	; space for the selection info.  (PrintFolderInfoString handles the
	; latter.)
	;
	mov	cl, ss:[smallScreen]
	mov	ax, MSG_DESKDC_SET_MAXIMIZED_NAME_STATE
	mov	bx, handle DisplayControl
	mov	si, offset DisplayControl
	call	ObjMessageCallFixup

	.leave
	ret
MakeSmallScreenChanges	endp
endif		; if _GMGR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableDosLaunchersViaIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	disable DOS Launcher functionality if .ini file
		flag is set

CALLED BY:	INTERNAL
			DoPreSuperClassStuff

PASS:		ds - dgroup of DeskApplicationClass (desktop dgroup)

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _NEWDESK
DisableDosLaunchersViaIniFile	proc	near
	push	ds
	mov	cx, cs
	mov	dx, offset dosLaunchersKey
	mov	ds, cx
	mov	si, offset getDesktopInitfileCategory
	call	InitFileReadBoolean
	pop	ds
	jc	done			; not found, leave alone
	tst	ax
	jnz	done			; TRUE, leave alone

	;
	; disable DOS launcher related stuff
	;
if _DOS_LAUNCHERS
	mov	bx, handle LauncherGroup
	mov	si, offset LauncherGroup
	call	disableItem
endif 	; if (_DOS_LAUNCHERS)

if (_GMGRONLY and _ICON_AREA)
	mov	bx, handle QuickViewDosRoom
	mov	si, offset QuickViewDosRoom
	call	disableItem
endif		; if (_GMGRONLY and _ICON_AREA)
done:
	ret

if (not (_ZMGR))
disableItem:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	di
	call	ObjMessage
	retn
endif		; if (not (_ZMGR or _NIKE))

DisableDosLaunchersViaIniFile	endp

dosLaunchersKey	char	"dosLaunchers",0
endif	; if (not _NEWDESK)

if _WRITABLE_TOKEN_DATABASE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableTokenLaunching
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	disable launching apps to get token

CALLED BY:	INTERNAL
			DoPreSuperClassStuff

PASS:		ds - dgroup of DeskApplicationClass (desktop dgroup)

RETURN:		ss:[disableTokenLaunch]

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableTokenLaunching	proc	near
EC<	ECCheckDGroup	ds						>
	mov	ds:[disableTokenLaunch], BB_FALSE
	push	ds
	mov	cx, cs
	mov	dx, offset disableTokenLaunchKey
	mov	ds, cx
	mov	si, offset getDesktopInitfileCategory
	call	InitFileReadBoolean
	pop	ds
	jc	done			; not found, leave alone
	tst	ax
	jz	done			; FALSE, leave alone
	mov	ds:[disableTokenLaunch], BB_TRUE
done:
	ret
DisableTokenLaunching	endp

disableTokenLaunchKey	char	"disableTokenLaunching",0

endif	; _WRITABLE_TOKEN_DATABASE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDefaultFolderBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set background color for folders

CALLED BY:	DoPreSuperClassStartup

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	4/17/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

fmBackgroundColorCategory	char	"motifOptions",0
fmBackgroundColorKey		char	"fileMgrColor",0

SetDefaultFolderBackgroundColor	proc	near
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	mov	al, C_WHITE
	mov	cx, cs
	mov	dx, offset fmBackgroundColorKey
	mov	ds, cx
	mov	si, offset fmBackgroundColorCategory
	call	InitFileReadInteger
	mov	ss:[folderBackgroundColor], al

	.leave
	ret
SetDefaultFolderBackgroundColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDebugModeOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set options for debug mode

CALLED BY:	DoPreSuperClassStartup

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/12/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if GPC_DEBUG_MODE
if GPC_ONLY
; reinclude if other debug mode options added

DocFilePath	struct
	DFP_disk	word
	DFP_path	TCHAR
SBCS <	DFP_dummy	byte					>
DocFilePath	ends

SetDebugModeOptions	proc	near
	uses	ax,cx,dx,si,ds
;this is a bit of stack space, but we shouldn't be deep in the call stack
addVarDataParams	local	AddVarDataParams
docFilePath		local	DocFilePath
	.enter
	mov	cx, cs
	mov	dx, offset debugKey
	mov	ds, cx
	mov	si, offset getDesktopInitfileCategory
	call	InitFileReadBoolean
	jc	useDefault			; not found, use default
	mov	ss:[debugMode], ax
useDefault:
	;
	; make file selectors use document virtual root if not in debug mode
	;
	cmp	ss:[debugMode], TRUE
	je	done
	mov	docFilePath.DFP_disk, SP_DOCUMENT
	mov	{TCHAR}docFilePath.DFP_path, 0
	mov	cx, NUM_FILE_SELECTORS
	mov	di, offset fsList
fsLoop:
	push	cx, di, bp
	movdw	bxsi, cs:[di]
	mov	addVarDataParams.AVDP_data.segment, ss
	lea	ax, docFilePath
	mov	addVarDataParams.AVDP_data.offset, ax
	mov	addVarDataParams.AVDP_dataSize, size DocFilePath
	mov	addVarDataParams.AVDP_dataType, ATTR_GEN_FILE_SELECTOR_VIRTUAL_ROOT
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	lea	bp, addVarDataParams
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_ATTRS
	call	ObjMessageCall			; cx = current attrs
	ornf	cx, mask FSA_USE_VIRTUAL_ROOT
	mov	ax, MSG_GEN_FILE_SELECTOR_SET_ATTRS
	call	ObjMessageCall
	pop	cx, di, bp
	add	di, size optr
	loop	fsLoop
done:
	.leave
	ret
SetDebugModeOptions	endp

fsList	optr \
	MoveToEntry,
	CopyToEntry,
	RecoverToEntry,
	RecoverSrc,
	CreateLinkToEntry
NUM_FILE_SELECTORS = ($-fsList)/(size optr)
endif ;GPC_ONLY
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCreateLinkOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set options for create links

CALLED BY:	DoPreSuperClassStartup

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/12/98		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if GPC_CREATE_DESKTOP_LINK

createLinkKey	char	'debugLinks',0

SetCreateLinkOptions	proc	near
	uses	ax,cx,dx,si,ds
	.enter
	mov	cx, cs
	mov	dx, offset createLinkKey
	mov	ds, cx
	mov	si, offset getDesktopInitfileCategory
	call	InitFileReadBoolean
	jc	useDefault			; not found, use default
	mov	ss:[debugLinks], ax
useDefault:
	;
	; set UI based on create link mode
	; - create link dialog has no file selector
	;
	cmp	ss:[debugLinks], TRUE
	jne	removeFS
	mov	bx, handle CreateLinkPrompt
	mov	si, offset CreateLinkPrompt
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	jmp	short done

removeFS:
	mov	bx, handle CreateLinkToEntry
	mov	si, offset CreateLinkToEntry
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	bx, handle CreateLinkToCurrentDir
	mov	si, offset CreateLinkToCurrentDir
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	.leave
	ret
SetCreateLinkOptions	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpFontAndGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize stuff

CALLED BY:	DesktopOpenApplication

PASS:		bp - system font pointsize

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	added header
	clee	5/16/94		use GrFontMetrics to measure the length
				instead of using GrTextWidth

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; on to use GrTextWidth, off to use (GrCharWidth)*(# chars)
; - much better results if on
; - slower for XIP if on
;
ACCURATE_NAMES_AND_DETAILS_POSITIONS	equ	1

SetUpFontAndGState	proc	near
	push	ds, si
if NEW_FONT_HANDLING
	;
	; get font and pointsize from geos.ini, if any
	;
	push	bp				; save system pointsize
	mov	cx, cs
	mov	dx, offset desktopFontIDKey
	mov	ds, cx
	mov	si, offset getDesktopInitfileCategory
	clr	bp				; return global buffer
	call	InitFileReadString
	jc	useDefaultFontID		; skip if no entry
	call	MemLock
	mov	ds, ax
	clr	si
	mov	dl, mask FEF_BITMAPS or mask FEF_OUTLINES or \
				mask FEF_STRING or mask FEF_DOWNCASE
	call	GrCheckFontAvail			; cx = font ID
	call	MemFree				; free font name buffer
	cmp	cx, FID_INVALID		; valid font?
	jne	haveFontID			; yes, use it
useDefaultFontID:
	mov	cx, DESKTOP_FONT_ID
haveFontID:
	mov	ss:[desktopFontID], cx
	mov	cx, cs
	mov	dx, offset desktopPointSizeKey
	mov	ds, cx
	mov	si, offset getDesktopInitfileCategory
	call	InitFileReadInteger		; ax = point size
	pop	bp				; retrieve system point size
	jnc	havePointSize
	mov	ax, bp
	dec	ax				; 1 smaller than system pt. size
havePointSize:
	mov	ss:[desktopFontSize], ax
else		; if NEW_FONT_HANDLING
	mov	ss:[desktopFontID], DESKTOP_FONT_ID
	mov	ss:[desktopFontSize], DESKTOP_FONT_SIZE
endif		; if NEW_FONT_HANDLING
	;
	; create GState with no window for calc'ing stuff
	;
	mov	cx, ss:[desktopFontID]
	mov	dx, ss:[desktopFontSize]
	clr	ah				; no fractional part
	clr	al				; normal text
	call	GrFindNearestPointsize
	cmp	cx, FID_INVALID		; anything matching?
	jne	savePointSize			; yes, use nearest pointsize
	mov	ss:[desktopFontID], DESKTOP_FONT_ID	; use default font
	mov	dx, DESKTOP_FONT_SIZE		; use default pointsize
savePointSize:
	mov	ss:[desktopFontSize], dx	; save closest pointsize
	clr	di				; no window
	call	GrCreateState
	mov	ss:[calcGState], di		; save calc gState
	mov	cx, ss:[desktopFontID]
	mov	dx, ss:[desktopFontSize]
	clr	ah				; no fractional part
	call	GrSetFont
	mov	si, GFMI_ROUNDED or GFMI_HEIGHT
	call	GrFontMetrics			; dx = font box height
	mov	cx, ss:[desktopFontSize]
	add	cx, 3				; at least 3 more than ptsize
	cmp	dx, cx
	jae	SFG_10				; is it?
	mov	dx, cx				; if not, use this
SFG_10:
	mov	ss:[desktopFontHeight], dx	; font box height
	;
	; Figure width of widest longname
	;
if ACCURATE_NAMES_AND_DETAILS_POSITIONS
	segmov	ds, cs, si
	mov	si, offset widest32Filename
FXIP <		clr	cx						>
FXIP <		call	SysCopyToStackDSSI	;ds:si = str on stack	>
	mov	cx, -1				; quit at null
	call	GrTextWidth			; dx = width of filename
FXIP <		call	SysRemoveFromStack				>
	mov_tr	ax, dx
if _DOCMGR
	;
	; set width that will allow Names and Details to fit with large
	; font (no problem for small and medium fonts)
	;
	mov	ax, 195
endif
else
	;
	; we should use GrFontMetrics instead of using GrTextWidth.
	; -- clee,  5/16/94.
	;
	mov	si, GFMI_MAX_WIDTH		;widest char
	call	GrFontMetrics			;dx = width of widest char
	push	dx				
	mov	ax, LONG_FILENAME_LENGTH	;32 chars for filename
	mul	dl				;ax = length of filename
endif
	mov	ss:[widest32FilenameWidth], ax
	mov	ss:[uncompressedLongTextWidth], ax
	;
	; Figure width of widest 8.3 name for compressed display
	; 
	mov	bp, ax				;bp =length of filename
if ACCURATE_NAMES_AND_DETAILS_POSITIONS
FXIP <		segmov	ds, cs, si					>
	mov	si, offset widest83Filename
FXIP <		clr	cx						>
FXIP <		call	SysCopyToStackDSSI	;ds:si = str on stack	>
	mov	cx, -1				; quit at null
	call	GrTextWidth			; dx = width of filename
FXIP <		call	SysRemoveFromStack				>
	mov	ax, dx
else
	segmov	ds, ss, si
	mov	si, C_PERIOD
	push	si
	mov	si, sp				;ds:si = ptr to '.'
	mov	cx, -1
	call	GrTextWidth			;dx = width of the dot
	pop	cx				;restore the stack
	mov	cx, dx				;cx = width of the dot
	pop	dx				;cx = width of widest char
	mov	ax, FILENAME_WITH_EXT		;ax = 11 chars
	mul	dl
	add	ax, cx				;ax = dos filename length
endif
	mov	ss:[widest83FilenameWidth], ax
	mov	ss:[compressedLongTextWidth], ax
	sub	bp, ax				; bp = diff. btwn 32 and 8.3
						;  for calculating compressed
						;  positions
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
	;
	; use compressed spacing for ZMGR's SEPARATE_NAMES_AND_DETAILS
	;
	mov	ss:[uncompressedLongTextWidth], ax
	mov	bp, 0
endif
	add	ax, 2 + \
			TEXT_ICON_WIDTH + TEXT_ICON_HORIZ_SPACING + \
				LONG_TEXT_HORIZ_SPACING + \
				LONG_TEXT_HORIZ_SPACING*2
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
	;
	; save end of name for ZMGR's SEPARATE_NAMES_AND_DETAILS
	;
	push	ax
endif
	;
	; Figure width of widest file size.
	;
	segmov	ds, cs, si
	mov	si, offset widestFilesize
FXIP <		clr	cx						>
FXIP <		call	SysCopyToStackDSSI	;ds:si = str on stack	>
	mov	cx, -1				; quit at null
	call	GrTextWidth			; dx = width of filesize
FXIP <		call	SysRemoveFromStack				>
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
	mov	ss:[widestFileSize], dx		; store for ZMGR
endif
	add	ax, dx
if _ZMGR and SEPARATE_NAMES_AND_DETAILS
	;
	; save end of filesize for ZMGR's SEPARATE_NAMES_AND_DETAILS
	;
	mov	ss:[separateFileSizeEndPos], ax
	pop	ax				; restore end of name
endif
						; save file date position
	mov	ss:[compressedFullFileDatePos], ax
	mov	ss:[uncompressedFullFileDatePos], ax
	add	ss:[uncompressedFullFileDatePos], bp
;;FXIP<	segmov	ds, cs, si						>
;;	mov	si, offset widestDate
;;	mov	cx, -1				; quit at null
;;	call	GrTextWidth			; dx = width of date
	;
	; Figure width of widest date & time
	; 
	push	ax				; save X position
	push	ds, es, di
NOFXIP<	segmov	es, dgroup, di						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	di, offset getInfoStringBuffer
	mov	ax, FileTime <12,58,58/2>	; 12:58:58 - a wide time
	mov	bx, FileDate <
		1988-FILE_BASE_YEAR,		; FD_YEAR
		9,				; FD_MONTH (September)
		28				; FD_DAY
	>
	call	UtilFormatDateAndTime
	mov	si, di
	segmov	ds, es
	mov	di, ss:[calcGState]
	call	GrTextWidth			; dx <- length of it
	pop	ds, es, di
	pop	ax				; retrieve X position

	add	ax, dx
;
; No attributes in ZMGR's Names and Sizes or Names and Dates
;
if GPC_NO_NAMES_AND_DETAILS_ATTRS ne TRUE
if (not _ZMGR or not SEPARATE_NAMES_AND_DETAILS)
	;
	; Figure width of widest list of file attributes.
	; 
	add	ax, LONG_TEXT_HORIZ_SPACING*2
						; save file attr position
	mov	ss:[compressedFullFileAttrPos], ax
	mov	ss:[uncompressedFullFileAttrPos], ax
	add	ss:[uncompressedFullFileAttrPos], bp
if ACCURATE_NAMES_AND_DETAILS_POSITIONS
	mov	si, offset widestAttr
FXIP <		clr	cx						>
FXIP <		call	SysCopyToStackDSSI	;ds:si = str on stack	>
	mov	cx, -1				; quit at null
	call	GrTextWidth			; dx = width of attrs
FXIP <		call	SysRemoveFromStack				>
else
	mov	si, GFMI_MAX_WIDTH or GFMI_ROUNDED
	call	GrFontMetrics			;dx = widest char width
	push	ax				;save ax
	mov	ax, WIDEST_ATTR_LENGTH
	mul	dl				;ax = lenght of widest attri
	pop	dx
endif
	add	ax, dx
endif
endif
						; save total width
	mov	ss:[compressedFullFileWidth], ax
	mov	ss:[uncompressedFullFileWidth], ax
	add	ss:[uncompressedFullFileWidth], bp
NOFXIP <	segmov	ds, cs, si					>
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
	mov	si, offset mainEllipsesString
	mov	cx, 3
	call	GrTextWidth
	mov	ss:[ellipsesWidth], dx
	pop	ds, si
	ret
SetUpFontAndGState	endp

if NEW_FONT_HANDLING
;
; keys for font and pointsize
;
desktopFontIDKey	byte	'fontId', 0
desktopPointSizeKey	byte	'fontSize', 0
endif		; if NEW_FONT_HANDLING

;
; widest possible filename
;
if ACCURATE_NAMES_AND_DETAILS_POSITIONS
if GPC_NAMES_AND_DETAILS_TITLES
; we'll use a more 'average width'
widest83Filename	TCHAR	'OOOOOOOO.OOO',0	; 8.3 name
widest32Filename	TCHAR	'OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO',0 ; 32 name
else
widest83Filename	TCHAR	'WWWWWWWW.WWW',0	; 8.3 name
widest32Filename	TCHAR	'WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW',0 ; 32 name
endif
endif
widestFilesize	TCHAR	'888888',0		; (6 chars)
;;widestDate	TCHAR	'18/28/88',0		; (8 chars)
;;widestTime	TCHAR	'18:18:18 pm',0		; (11 chars)
if not _ZMGR
if GPC_NO_NAMES_AND_DETAILS_ATTRS ne TRUE
if ACCURATE_NAMES_AND_DETAILS_POSITIONS
widestAttr	TCHAR	'WWWWWW',0		; (6 chars)
						;  can't have both M and P...
endif
endif
endif

if FULL_EXECUTE_IN_PLACE
idata	segment
endif

mainEllipsesString	TCHAR	"..."

if FULL_EXECUTE_IN_PLACE
idata	ends
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetInitFileMappings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize stuff

CALLED BY:	INTERNAL
			DesktopOpenApplication

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/26/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetInitFileMappings	proc	near
	push	ds, si
	;
	; mapping of non-GEOS filenames/extensions to tokens
	;
	clr	ss:[filenameTokenMapBuffer]
	mov	cx, cs
	mov	dx, offset filenameTokenInitfileKey
	mov	ds, cx
	mov	si, offset getDesktopInitfileCategory
	clr	bp				; return global buffer
	call	InitFileReadString
	jc	10$				; skip if no buffer
	mov	ss:[filenameTokenMapBuffer], bx	; save buffer handle
10$:
	;
	; mapping of GEOS executable tokens to pathnames
	;
	clr	ss:[tokenPathnameMapBuffer]
	mov	cx, cs
	mov	dx, offset tokenPathnameInitfileKey
	mov	si, offset getDesktopInitfileCategory
	clr	bp				; return global buffer
	call	InitFileReadString
	jc	20$				; skip if no buffer
	mov	ss:[tokenPathnameMapBuffer], bx	; save buffer handle
20$:
	;
	; mapping of DOS datafiles to DOS applications
	;
	clr	ss:[dosAssociationMapBuffer]
	mov	cx, cs
	mov	dx, offset dosAssociationInitfileKey
	mov	si, offset getDesktopInitfileCategory
	clr	bp				; return global buffer
	call	InitFileReadString
	jc	30$				; skip if no buffer
	mov	ss:[dosAssociationMapBuffer], bx	; save buffer handle
30$:
	;
	; mapping of DOS applications to parameters
	;
	clr	ss:[dosParameterMapBuffer]
	mov	cx, cs
	mov	dx, offset dosParameterInitfileKey
	mov	si, offset getDesktopInitfileCategory
	clr	bp				; return global buffer
	call	InitFileReadString
	jc	40$				; skip if no buffer
	mov	ss:[dosParameterMapBuffer], bx	; save buffer handle
40$:
if _NEWDESK ;GPC_FOLDER_WINDOW_MENUS
	;
	; while we have category, get folder window browse mode
	;
	mov	cx, cs
	mov	dx, offset browseModeKey
	call	InitFileReadInteger
	jc	60$				; not found, leave default
	mov	ss:[browseMode], al
60$:
if _NDO2000
	; No where better to put this...
		mov	cx, cs
		mov	dx, offset lowerDesktopIconsKey
		call	InitFileReadBoolean
		jc	70$
		mov	ss:[lowerDesktopIcons], ax
70$:
endif
endif
ifdef SMARTFOLDERS
	;
	; check if allowing saving/restoring positions and size
	;
	mov	ss:[saveWinPosSize], FALSE
	mov	cx, cs
	mov	dx, offset saveWinPosSizeKey
	call	InitFileReadBoolean
	jc	noSaveWinPosSize
	mov	ss:[saveWinPosSize], ax
noSaveWinPosSize:
endif
if GPC_POPUP_MENUS
	;
	; check if allowing popup windows outside Desktop
	;
	mov	cx, cs
	mov	dx, offset allPopupsKey
	call	InitFileReadBoolean
	jc	noAllPopups			; not found, leave default
	mov	ss:[allPopups], ax
noAllPopups:
endif
if _DOCMGR
	;
	; check if allowing dirs
	;
	mov	ss:[showDirs], FALSE
	segmov	ds, cs, cx
	mov	si, offset showDirsCat
	mov	dx, offset showDirsKey
	call	InitFileReadBoolean
	jc	noDirs
	mov	ss:[showDirs], ax
noDirs:
endif
	pop	ds, si
	ret
GetInitFileMappings	endp


;
; desktop's geos.ini category
;
getDesktopInitfileCategory	byte	"fileManager",0

;
; geos.ini keys
;
filenameTokenInitfileKey	byte	'filenameTokens',0
tokenPathnameInitfileKey	byte	'tokenPathnames',0
dosAssociationInitfileKey	byte	'dosAssociations',0
dosParameterInitfileKey		byte	'dosParameters',0
if GPC_DEBUG_MODE
debugKey			byte	'debug', 0
endif
if GPC_DEBUG_MODE or (_NEWDESK and _NDO2000)
browseModeKey			byte	'browseMode', 0
endif
if _NEWDESK and _NDO2000
lowerDesktopIconsKey		byte	'lowerDesktopIcons',0
endif

if _DOCMGR
udata	segment
showDirs	word
udata	ends

showDirsCat	char	'docManager',0
showDirsKey	char	'showDirs',0
endif

ifdef SMARTFOLDERS
saveWinPosSizeKey	char	'saveWinPosSize',0
endif

if GPC_POPUP_MENUS
allPopupsKey		char	'allPopups',0
endif

if GPC_UI_LEVEL_DIALOG
uiLevelDialogShownKey	char	'uiLevelDialogShown',0
endif

if _GMGR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GMInitDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize all the UI and relating to drives by looping
		through all possible drives and initialize UI for that drive.

CALLED BY:	DesktopOpenApplication

PASS:		none
RETURN:		none
DESTROYED:	all

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	added header
	dlitwin	10/07/92	broke out into many subroutines
	dlitwin	10/16/92	made into GeoManager only routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GMInitDrives	proc	near
	.enter

	mov	ss:[formatCurDrive], -1		; this one needs initializing
	mov	ss:[copyCurDrive], -1		; this one needs initializing
	mov	ss:[renameCurDrive], -1		; this one needs initializing
if _ICON_AREA
	call	GetDriveButtonToolAreaDestination
endif

if (_ZMGR and not _PMGR)
	mov	dx, offset PrimaryInterface:FloatingDrivesDialog
endif		; if (_ZMGR and (not _PMGR))

	clr	ax				; drive number = al = 0
	clr	bx				; num drives added
	mov	cx, DRIVE_MAX_DRIVES		; number of drives

	;
	; loop through all possible drives
	;
driveLoop:
	call	IsDriveValid
	jc	next

	push	cx, dx
if _ICON_AREA
	call	DoIconAreaDrive
endif	;  if _ICON_AREA
if not _ZMGR
if (_TREE_MENU)		
GMONLY <	call	DoTreeDrive					>
endif		
GMONLY<	call	DoKeyboardDrive	>
endif
if _DISK_OPS
	call	DoFormatDrive
	call	DoCopySrcDrive
	call	DoCopyDestDrive
	call	DoRenameDrive
endif
	pop	cx, dx
next:
	inc	al
	loop	driveLoop

if _DISK_OPS
	call	SetCopyRenameDriveDefaults
	call	SetFormatDriveDefaults
endif

	.leave
	ret
GMInitDrives	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GMClearDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	support for GenAppLazarus - clear any created drives

CALLED BY:	INTERNAL
			DoPreSuperClassStartup

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GMClearDrives	proc	near

	;
	; Remove all the "DriveTool" children of the IconArea object.
	;

	mov	ax, MSG_GEN_DESTROY
	mov	bx, segment DriveToolClass
	mov	si, offset DriveToolClass
	mov	di, mask MF_RECORD
	mov	dl, VUM_NOW
	clr	bp
	call	ObjMessage		; di - event handle

if _ICON_AREA
	mov	cx, di
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	LoadBXSI	IconArea
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
			
GMONLY<	mov	bx, handle FloatingDrivesDialog				>
GMONLY<	mov	si, offset FloatingDrivesDialog				>
GMONLY<	call	clearAllChildren					>
endif	;_ICON_AREA

if not _ZMGR
if (_TREE_MENU)
GMONLY<	mov	bx, handle TreeMenuDriveList				>
GMONLY<	mov	si, offset TreeMenuDriveList				>
GMONLY<	call	clearAllChildren					>
endif
	mov	bx, handle OpenDrives
	mov	si, offset OpenDrives
	call	clearAllChildren
endif

if _DISK_OPS
	mov	bx, handle DiskFormatSourceList
	mov	si, offset DiskFormatSourceList
	call	clearAllChildren

	mov	bx, handle DiskCopySourceList
	mov	si, offset DiskCopySourceList
	call	clearAllChildren

	mov	bx, handle DiskCopyDestList
	mov	si, offset DiskCopyDestList
	call	clearAllChildren

	mov	bx, handle DiskRenameDriveList
	mov	si, offset DiskRenameDriveList
	call	clearAllChildren
endif
	ret			; <-- EXIT HERE

clearThisOne	label	near
	pushdw	bxsi
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	mov	bp, 0
	call	ObjMessageCallFixup
	popdw	bxsi
	retn

clearAllChildren	label	near
nextChild:
	clr	cx				; start with first child
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjMessageCallFixup		; ^lcx:dx = child
	jc	noMoreChildren
	call	clearThisOne
	jmp	short nextChild

noMoreChildren:
	retn

GMClearDrives	endp


if _ICON_AREA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDriveButtonToolAreaDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set dx to be one of two ToolAreaClass objects.  The IconArea
		object is placed at the bottom of the GeoManager Primary, and
		the FloatingDrivesDialog is a free floating dialog box.  This
		ToolAreaClass object is where the drive buttons will be placed
		as they are instantiated


		Drives buttons are built out to different places depending on 
		what filemanager we are using.  For the FileCabinet and Palm
		Connect, we want to always build them out to the IconArea, for
		Zoomer we want to build them out to the FloatingDrivesDialog
		(which, in Zoomer, is a child of the IconArea) and in
		GeoManager we want to build them to either of these two (in
		GeoManager the FloatingDrivesDialog is not a child of the
		IconArea, but a free floating dialog) depending on the Options.

CALLED BY:	GMInitDrives, DesktopDriveChangeNotify

PASS:		none
RETURN:		dx = offset IconArea or offset FloatingDrivesDialog
DESTROYED:	all

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Initial version
	dlitwin	9/28/93		Hacked in some conditionals for other
				file managers.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDriveButtonToolAreaDestination	proc	near
	.enter

			;
			; FileCabinet and PManager
			;
if (_FCAB or _PMGR)
	mov	dx, offset IconAreaResource:IconArea
else
			;
			; ZManager
			;
if _ZMGR
	mov	dx, offset PrimaryInterface:FloatingDrivesDialog
else
			;
			; GeoManager
			;
	mov	ax, MSG_TA_GET_DRIVE_LOCATION
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall
	cmp	cl, DRIVES_SHOWING
	mov	dx, offset IconAreaResource:IconArea
	je	gotDestinationObject
						; for FLOATING and HIDDEN
	mov	dx, offset PrimaryInterface:FloatingDrivesDialog

gotDestinationObject:
	; if drives were floating, the FloatingDrivesDialog will be initated
	; AFTER MSG_GEN_OPEN_APPLICATION has been called on the superclass.

endif		; if _ZMGR
endif		; if (_FCAB or _PMGR)
	.leave
	ret
GetDriveButtonToolAreaDestination	endp
endif		; if _ICON_AREA
endif		; if _GMGR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDInitDesktop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize all the links in the Desktop directory.

CALLED BY:	DesktopOpenApplication

PASS:		none
RETURN:		none
DESTROYED:	all

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	4/6/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef GPC_ONLY
uiCategory char "ui", 0
haveEnvAppKey char "haveEnvironmentApp", 0
endif

if _NEWDESK
NDInitDesktop	proc	near
	call	FilePushDir

	;
	; cd to desktop directory
	;
	mov	bx, STANDARD_PATH_OF_DESKTOP_VOLUME
	segmov	ds, cs, dx
	mov	dx, offset InitDesktopPath
	call	FileSetCurrentPath		; set Desktop as current path
	jnc	continue
	call	FileCreateDir
	call	FileSetCurrentPath
	LONG jc	done

	.assert (handle DrivesDirectory eq handle WorldLink) and \
		(handle DrivesDirectory eq handle DocumentLink) and \
		(handle DrivesDirectory eq handle WasteLink) and \
		(handle DrivesDirectory eq handle ToolsLink) and \
		(handle DrivesDirectory eq handle GamesLink) and \
		(handle DrivesDirectory eq handle OfficeLink) 
continue:
	mov	bx, handle DrivesDirectory
	call	MemLock
	mov	ds, ax

if GPC_DESKTOP_LINKS_IN_INI

	push	ds
	segmov	ds, cs, cx
	mov	si, offset desktopLinksCat
	mov	dx, offset desktopLinksDoneKey
	call	InitFileReadBoolean
	jc	doLinks
	tst	ax
	jnz	linksDone
doLinks:
	mov	dx, offset desktopLinksKey
	mov	di, SEGMENT_CS
	mov	ax, offset createDesktopLinkCallback
	mov	bp, 0
	call	InitFileEnumStringSection
	mov	dx, offset desktopLinksDoneKey
	mov	ax, -1
	call	InitFileWriteBoolean
linksDone:
	pop	ds

else ; !GPC_DESKTOP_LINKS_IN_INI

	; create link to world
		
	mov	bx, SP_APPLICATION
	mov	si, offset WorldLink
	mov	dx, ds:[si]
	call	createLink

	mov	ax, 'nW'
	mov	bx, 'OR'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_SYSTEM_FOLDER
	call	setWOT

	; create link to document

	mov	bx, SP_DOCUMENT
	mov	si, offset DocumentLink
	mov	dx, ds:[si]
	call	createLink

	mov	ax, 'nD'
	mov	bx, 'OC'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_SYSTEM_FOLDER
	call	setWOT

	; create link Tools

	mov	bx, SP_APPLICATION
	mov	si, offset ToolsLink
	mov	dx, ds:[si]

	call	createSubLink
	mov	ax, 'FL'
	mov	bx, '52'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_SYSTEM_FOLDER
	call	setWOT

	; create link Games

	mov	bx, SP_APPLICATION
	mov	si, offset GamesLink
	mov	dx, ds:[si]

	call	createSubLink
	mov	ax, 'FL'
	mov	bx, '52'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_SYSTEM_FOLDER
	call	setWOT	

	; create link Office

	mov	bx, SP_APPLICATION
	mov	si, offset OfficeLink
	mov	dx, ds:[si]

	call	createSubLink
	mov	ax, 'FL'
	mov	bx, '52'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_SYSTEM_FOLDER
	call	setWOT	
endif ; GPC_DESKTOP_LINKS_IN_INI

	; special handling for move from "Waste" to "Wastebasket"
	; (if "Waste" exists but "Wastebasket" does not, delete "Waste"
	mov	si, offset WasteLink
	mov	dx, ds:[si]
	push	es, di
DBCS <	push	bx							>
	push	ax
	segmov	es, ss, di
	mov	di, sp
	mov	cx, (size TCHAR)*2
	call	FileReadLink
	jc	afterSpecialWaste	
	cmp	bx, SP_WASTE_BASKET
	jne	afterSpecialWaste
	pop	ax
DBCS <	pop	bx							>
DBCS <	push	bx							>
	push	ax
SBCS <	cmp	al, C_NULL						>
DBCS <	cmp	ax, C_NULL						>
	je	removeWaste
SBCS <	cmp	al, '.'							>
DBCS <	cmp	ax, '.'							>
	jne	afterSpecialWaste
SBCS <	cmp	ah, C_NULL						>
DBCS <	cmp	bx, C_NULL						>
	jne	afterSpecialWaste
removeWaste:
	call	FileDelete
afterSpecialWaste:
	pop	ax
DBCS <	pop	bx							>
	pop	es, di

	; create link to wastebasket

	mov	bx, SP_WASTE_BASKET
	mov	si, offset WastebasketLink
	mov	dx, ds:[si]
	call	createLink

	mov	ax, 'nd'
	mov	bx, 'WB'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_WASTEBASKET
	call	setWOT
if GPC_FULL_WASTEBASKET
	call	UpdateWastebasket
endif

if GPC_SIGN_UP_ICON
	;
	; create dummy link for "Sign Up"
	;
	call	UtilUpdateSignUp
endif

if GPC_MAIN_SCREEN_LINK
if 0	;ifndef GPC_ONLY
	push	ds, si, ax, cx, dx
	clr	ax					;ax <- default = FALSE
	segmov	ds, cs, cx
	mov	si, offset uiCategory
	mov	dx, offset haveEnvAppKey
	call	InitFileReadBoolean
	tst	ax					;environment app?
	pop	ds, si, ax, cx, dx
	jz	noMainScreen				;branch if not
endif

	;
	; create dummy link for "GlobalPC Main Screen"
	;
	push	ds
	sub	sp, FILE_LONGNAME_LENGTH+2
DBCS <	sub	sp, FILE_LONGNAME_LENGTH+2			>
	mov	dx, sp

	call	GPCGetMainScreenName
	segmov	ds, ss, bx
	mov	bx, SP_TOP		; dummy path
	segmov	es, ss
	clr	ax
	push	ax			; null-path
	mov	di, sp			; es:di = ""
	mov	cx, -1			; no extended attributes

ifndef GPC_ONLY
	; edigeron 11/3/00 - move this check to here, and if we don't have an
	; environment app, check if the link already exists. If so, delete it.
	; But first make sure it's a link and not a file.
	push	ds, si, dx
	segmov	ds, cs, cx
	clr	ax					;ax <- default = FALSE
	mov	si, offset uiCategory
	mov	dx, offset haveEnvAppKey
	call	InitFileReadBoolean
	; cx has the code segment in it now, therefore != 0, so that meets
	; our needs
	pop	ds, si, dx
	jc	createMainScreenLink
	tst	ax					;environment app?
	jnz	createMainScreenLink
	call	FileGetAttributes
	jc	noMainScreenLink
	test	cx, mask FA_LINK
	jz	noMainScreenLink
	call	FileDelete
noMainScreenLink:
	pop	ax
	jmp	noMainScreen
createMainScreenLink:
endif	
	call	FileCreateLink
	pop	ax

	mov	ax, 'nd'
	mov	bx, 'MS'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_LOGOUT
	call	setWOT

noMainScreen::
	add	sp, FILE_LONGNAME_LENGTH+2
DBCS <	add	sp, FILE_LONGNAME_LENGTH+2			>
	pop	ds
endif

	; create drives (My Computer) directory

if GPC_NO_DRIVES_FOLDER ne TRUE
	mov	si, offset DrivesDirectory
	mov	dx, ds:[si]
	call	FileCreateDir

	mov	ax, 'nM'
	mov	bx, 'YC'
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	setToken

	mov	ax, WOT_SYSTEM_FOLDER
	call	setWOT

	; create link to preferences

	clr	bx
	mov	si, offset DrivesDirectory
	mov	dx, ds:[si]
	call	FileSetCurrentPath

	push	ds, es
	segmov	ds, cs, ax
	mov	es, ax
	mov	bx, SP_APPLICATION
	mov	dx, offset preferencesString	; ds:dx = "{EC} Preferences"
	mov	di, offset preferencesPath
		; es:di = "Utilities\{EC} Preferences"
	clr	cx			; get extended attributes from target
	call	FileCreateLink
	pop	ds, es
endif

	; clean up - unlock strings block

	mov	bx, handle DrivesDirectory
	call	MemUnlock
done:
	call	FilePopDir
	ret

if GPC_DESKTOP_LINKS_IN_INI
;	
; Pass: ds:si = string section (token chars, manuf ID, sp, path, link name)
;
createDesktopLinkCallback	label	far
	;
	; allocate path buffer
	;
	sub	sp, PATH_BUFFER_SIZE
	segmov	es, ss, di
	mov	di, sp			; es:di = buffer for path
	;
	; get token chars and separator
	;
	LocalGetChar	ax, dssi
	mov	bl, al
	LocalGetChar	ax, dssi
	mov	bh, al
	push	bx			; (1) token chars high
	LocalGetChar	ax, dssi
	mov	bl, al
	LocalGetChar	ax, dssi
	mov	bh, al
	push	bx			; (2) token chars low
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, ','
	mov	cx, 2 * (size word)	; in case error
	jne	donePop
	;
	; get manuf ID
	;
	call	asciiToHex		; ax = value
	jc	donePop
	push	ax			; (3) manuf ID
	add	cx, (size word)
	;
	; get StandardPath
	;
	call	asciiToHex		; ax = value
	jc	donePop
	push	ax			; (4) StandardPath
	add	cx, (size word)
	;
	; copy path into path buffer
	;
copyPathLoop:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax
	je	donePop
	LocalCmpChar	ax, ','
	jne	copyPathLoop
	mov	{TCHAR}es:[di-(size TCHAR)], 0	; null-terminate path
	;
	; get WOT
	;
	call	asciiToHex		; ax = value
	jc	donePop
	mov	bp, ax			; bp = WOT
	;
	; get link name and create it
	;
	mov	dx, si			; ds:dx = link name
	mov	di, sp
	add	di, cx			; es:di = path (skips pushes)
	pop	bx			; (4) StandardPath
	call	checkSysFolderEmpty	; if empty system folder
	jc	deleteLink		;	delete any existing link
	clr	cx			; get extended attribute from target
	call	FileCreateLink		; (ignore error)
skipCreate:
	pop	si			; (3) si = manuf ID
	pop	bx			; (2) bx = token chars low
	pop	ax			; (1) ax = token chars high
	call	setToken		; (ignore error)
	mov	ax, bp			; ax = WOT
	call	setWOT			; (ignore error)
	clr	cx			; no more stuff on stack
donePop:
	add	sp, cx
	add	sp, PATH_BUFFER_SIZE
	retf

deleteLink:
	;
	; ds:dx = link name
	; pwd = path containing link
	;
	call	FileDelete		; ignore error
	jmp	skipCreate		; branch back to clean up stack

asciiToHex:
	push	cx
	mov	bx, 10
	clr	cx
numLoop:
SBCS <	clr	ax						>
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	je	notNum
	LocalCmpChar	ax, ','
	je	doneNum			; carry clear
	LocalCmpChar	ax, '0'
	jb	notNum
	LocalCmpChar	ax, '9'
	ja	notNum
	sub	ax, '0'
	xchg	ax, cx			; ax = prev, cx = digit
	mul	bx			; dx:ax = prev*10
	add	cx, ax			; don't need to handle overflow
	jmp	short numLoop

notNum:
	stc
doneNum:
	mov	ax, cx			; ax = total
	pop	cx
	retn
endif

;
; Pass:	ds:dx = name of link
;	bx = disk handle of destination
;
createLink:
	segmov	es, ss
	clr	ax
	push	ax
	mov	di, sp			; es:di = ""
	clr	cx			; get extended attributes from target
	call	FileCreateLink
	pop	ax
	retn

if not GPC_DESKTOP_LINKS_IN_INI
createSubLink:	
	segmov	es, ds
	mov	di, dx			; es:di = ""
	clr	cx			; get extended attributes from target
	call	FileCreateLink
endif
		
;
; Pass:	ds:dx = name of link
;	ax:bx:si = GeodeToken
;
setToken:
	segmov	es, ss
	mov	cx, size GeodeToken
	sub	sp, cx
	mov	di, sp
	mov	{word}es:[di].GT_chars[0], ax
	mov	{word}es:[di].GT_chars[2], bx
	mov	es:[di].GT_manufID, si
	mov	ax, FEA_TOKEN
	call	FileSetPathExtAttributes
	add	sp, cx
	retn

;
; Pass:	ds:dx = name of link
;	ax = NewDeskObjectType
;
setWOT:
	segmov	es, ss
	mov	cx, size NewDeskObjectType
	sub	sp, cx
	mov	di, sp
	mov	{NewDeskObjectType}es:[di], ax
	mov	ax, FEA_DESKTOP_INFO
	call	FileSetPathExtAttributes
	add	sp, cx
	retn

;
; Pass: es:di = link path
;	bx = link SP
;	bp = WOT
; Return:
;	carry set if empty system folder link deleted
;
checkSysFolderEmpty:
	cmp	bp, WOT_SYSTEM_FOLDER
	clc					; assume not system folder
	jne	haveSFE				; not system folder, C clear
	call	FilePushDir
	push	ds, dx
	segmov	ds, es				; ds:dx = path
	mov	dx, di
	call	FileSetCurrentPath
	pop	ds, dx
	jc	haveSFEPopDir			; no such directory, C set
	push	ax, bx, cx, dx, bp
	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS
	mov	ss:[bp].FEP_returnAttrs.segment, 0
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_COUNT_ONLY
	mov	ss:[bp].FEP_returnSize, 0
	mov	ss:[bp].FEP_matchAttrs.segment, 0
	mov	ss:[bp].FEP_bufSize, 0
	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum			; dx = count
	jc	haveSFECount			; enum error, C set
	cmp	dx, 1
	jne	notJustDirInfo
	push	ds, dx
	segmov	ds, dgroup, dx
	mov	dx, offset dirinfoFilename
	call	FileGetAttributes
	pop	ds, dx
	jc	notJustDirInfo			; not found, have real count
	dec	dx				; else, ignore dir info file
notJustDirInfo:
	tst_clc	dx
	jnz	haveSFECount			; not empty, C clear
	stc					; else, indicate empty
haveSFECount:
	pop	ax, bx, cx, dx, bp
haveSFEPopDir:
	call	FilePopDir			; (preserves flags)
haveSFE:
	retn

NDInitDesktop	endp

if GPC_NO_DRIVES_FOLDER ne TRUE
EC  <preferencesString	char	"EC Preferences",0			>
NEC <preferencesString	char	"Preferences",0				>
EC  <preferencesPath	char	"Utilities",92,"EC Preferences",0	>
NEC <preferencesPath	char	"Utilities",92,"Preferences",0		>
endif

if GPC_DESKTOP_LINKS_IN_INI
desktopLinksCat	char	"fileManager",0
desktopLinksKey	char	"desktopLinks",0
desktopLinksDoneKey	char	"linksDone",0
endif

if not GPC_NO_PRINT
printerLinkName	char	"Printer",0
endif

if GPC_MAIN_SCREEN_LINK
GPCGetMainScreenName	proc	near
	push	dx
	mov	si, offset GPCMainScreenLink
	mov	si, ds:[si]
	push	si			; save " Main Screen" offset
	segmov	es, ds, cx
	mov	di, si
	call	LocalStringLength	; cx = length of " Main Screen"
	mov	bp, FILE_LONGNAME_LENGTH+1  ; IFRS takes buffer + null
	sub	bp, cx			; max for <product>
DBCS <	shl	bp, 1			; length to size	>
	segmov	es, ss, cx		; es:di = buffer for <product>
	mov	di, dx
	push	ds
	segmov	ds, cs, cx
	mov	si, offset prodNameCat
	mov	dx, offset prodNameKey
	call	InitFileReadString	; cx!=0 if found
	pop	ds			; restore string segment
	add	di, cx			; advance past <product>, if any
DBCS <	add	di, cx							>
	tst	cx
	jnz	append
	mov	si, offset GPCMainScreenGPC
	mov	si, ds:[si]		; ds:si = default <product>
	LocalCopyString			; (es:di wasn't altered if no .ini)
	LocalPrevChar	esdi		; back up over null
append:
	pop	si			; ds:si = " Main Screen"
	LocalCopyString			; append to <product>
	pop	dx
	ret
GPCGetMainScreenName	endp

prodNameCat char "ui",0
prodNameKey char "productName",0
endif

endif ; _NEWDESK


if _NEWDESK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDInitDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize all the links in the Desktop directory.  For NewDesk
		only (non-Wizard) it is done in the Drives directory as well.

CALLED BY:	DesktopOpenApplication

PASS:		none
RETURN:		none
DESTROYED:	all

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDInitDrives	proc	near
	.enter
	call	NDCreateDriveLinkIndexBlock	; index locked down into es
	push	bx				; save index block handle

	call	NDLoopForDoCopyDestDrive

	;
	; Links are now built out in the Verify thread, so we don't need
	; to build them out here for Wizard, only for NewDesk.
	;
NDONLY<	call	NDInitDriveLinks					>

	pop	bx			; restore index block handle
	call	MemFree
if GPC_FOLDER_WINDOW_MENUS
	;
	; create again as contents were destroyed in NDInitDriveLinks
	; (we need for later reference)
	;
	call	NDCreateDriveLinkIndexBlock
	call	MemUnlock
endif

	.leave
	ret
NDInitDrives	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDLoopForDoCopyDestDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop through the valid drives and create ui elements for
		the copy disk destination list.

CALLED BY:	NDInitDrives

PASS:		es - locked down segment of drive link index table

RETURN:		none
DESTROYED:	all but es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDLoopForDoCopyDestDrive	proc	near
	.enter

	clr	ax				; drive number = al = 0

driveLoop:
	call	NDDoWeNeedADriveLink
	jc	next

	call	DoCopyDestDrive
next:
	inc	al
	cmp	al, DRIVE_MAX_DRIVES		; number of drives
	jne	driveLoop

	.leave
	ret
NDLoopForDoCopyDestDrive	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDCreateDriveLinkIndexBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates and fills the drive link index table with a bit
		set for each valid drive.

CALLED BY:	NDInitDrives

PASS:		nothing

RETURN:		bx is block handle of drive link index table
		es - segment of locked down index table

DESTROYED:	preserves bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/09/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if GPC_FOLDER_WINDOW_MENUS
InitCode ends

UtilCode segment resource

NDGetDriveLinkIndexBlock	proc	far
	uses	ax, ds
	.enter
	segmov	ds, dgroup, ax
	mov	bx, ds:[driveLinkIndexBlock]
EC <	tst	bx						>
EC <	ERROR_Z	-1						>
	call	MemLock
	jc	exit
	mov	es, ax
exit:
	.leave
	ret
NDGetDriveLinkIndexBlock	endp

idata	segment
driveLinkIndexBlock	hptr	0
idata	ends

UtilCode ends

InitCode segment resource
endif

NDCreateDriveLinkIndexBlock	proc	near
	uses	bp
	.enter

	mov	ax, (DRIVE_MAX_DRIVES / 8) + 1
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
if GPC_FOLDER_WINDOW_MENUS
	mov	ss:[driveLinkIndexBlock], bx
endif
	mov	es, ax

	clr	ax			; start with drive 0
driveLoop:
BA<	call	IclasDriveGetStatus				>
NDONLY<	call	DriveGetStatus					>
	jc	nextDrive

	;
	; index table is a 32 byte bitfield (256 bits).  To check a bit, we
	; take the drive number, divide it by 8 to get the byte to operate on
	; and take the low 3 bits of the drive number (remainder of divide by
	; 8) and shift in that many bits.  We then set that bit position.
	;
	clr	ah			; ax is drive number
	mov	di, ax
	shr	di, 1
	shr	di, 1			; divide by 8 to get index byte
	shr	di, 1
	mov	cl, al
	and	cl, 0x07		; mask off high bits
	mov	dx, 1
	shl	dx, cl			; shift bitmask into place
	or	{byte} es:[di], dl	; set bit

	;
	; If the drive is C: then go to the root of it to make dos 3.3
	; happy on 286's. This should not hurt anything on ram drives. 
	; -ron 9/16/93
	;
		cmp	al, 2
		jne	nextDrive
		push	ds, dx, bx, ax
		clr	bx
		call	FilePushDir
		segmov	ds, cs
		mov	dx, offset cDrivePath
		call	FileSetCurrentPath	; destroys ax on error
		call	FilePopDir
		pop	ds, dx, bx, ax
nextDrive:

	inc	al			; go to next drive
	cmp	al, DRIVE_MAX_DRIVES
	jne	driveLoop

if GPC_NO_DRIVES_FOLDER
	;
	; remove drive links specified by geos.ini file
	;
	push	bx, ds, si
	segmov	ds, cs, cx
	mov	si, offset noDriveLinkCat
	mov	dx, offset noDriveLinkKey
	mov	bp, 0				; allocate block
	call	InitFileReadString		; bx = block
	jc	noDriveDone
	call	MemLock
	mov	ds, ax
	clr	si
SBCS <	clr	ah							>
noDriveLoop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	endNoDriveList
	LocalCmpChar	ax, 'A'
	jb	endNoDriveList
	LocalCmpChar	ax, 'Z'
	ja	endNoDriveList
	sub	ax, 'A'
	;
	; remove drive from table
	;
	mov	di, ax
	shr	di, 1
	shr	di, 1			; divide by 8 to get index byte
	shr	di, 1
	mov	cl, al
	and	cl, 0x07		; mask off high bits
	mov	dx, 1
	shl	dx, cl			; shift bitmask into place
	not	dl
	andnf	{byte} es:[di], dl	; turn off bit
	jmp	short noDriveLoop
endNoDriveList:
	call	MemFree
noDriveDone:
	pop	bx, ds, si
endif  ; GPC_NO_DRIVES_FOLDER

	.leave
	ret
NDCreateDriveLinkIndexBlock	endp

cDrivePath	char	"C:", C_BACKSLASH, 0

if GPC_NO_DRIVES_FOLDER

noDriveLinkCat	char	'fileManager',0
noDriveLinkKey	char	'noDriveLink',0

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDoWeNeedADriveLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the drive link index table to see if we need to create
		a drive link.

CALLED BY:	NDDoDriveLinksForDirectory

PASS:		al - drive number
		es - segment of locked index table

RETURN:		carry clear to accept drive
		carry set to reject it

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/14/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if GPC_FOLDER_WINDOW_MENUS
InitCode ends

UtilCode segment resource

NDDoWeNeedADriveLink	proc	far
else
NDDoWeNeedADriveLink	proc	near
endif
	uses	ax, dx, cx, di
	.enter

	;
	; index table is a 32 byte bitfield (256 bits).  To check a bit, we
	; take the drive number, divide it by 8 to get the byte to operate on
	; and take the low 3 bits of the drive number (remainder of divide by
	; 8) and shift in that many bits.  We then test that bit position.
	;
	clr	ah			; make ax the drive number
	mov	di, ax
	shr	di
	shr	di			; divide by 8 for byte to index
	shr	di
	mov	cl, al
	and	cl, 0x07		; mask off top five bits
	mov	dx, 1
	shl	dl, cl
	test	{byte} es:[di], dl
checkRes::
	stc				; default to not valid
	jz	exit
	clc
exit:
	.leave
	ret
NDDoWeNeedADriveLink	endp

if GPC_FOLDER_WINDOW_MENUS
UtilCode ends

InitCode segment resource
endif

if _NEWDESKONLY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDInitDriveLinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create drive links in the Drives directory, and nuke any
		inappropriate drive links in the drives or Desktop dir.

CALLED BY:	NDInitDrives

PASS:		es	- locked down index block
RETURN:		nothing
DESTROYED:	all

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDInitDriveLinks	proc	near
	.enter

	call	FilePushDir
	mov	bx, STANDARD_PATH_OF_DESKTOP_VOLUME
	segmov	ds, cs, dx
	mov	dx, offset InitDesktopPath
	call	FileSetCurrentPath		; set Desktop as current path
	jnc	nukeInvalidDrives
	call	FileCreateDir
	call	FileSetCurrentPath
nukeInvalidDrives:
	call	NDNukeInvalidDriveLinks		; clean up Desktop

	;
	; get the name of the DrivesDirectory
	;
if GPC_NO_DRIVES_FOLDER ne TRUE
	mov	bx, handle DrivesDirectory
	call	MemLock
	mov	ds, ax
	mov	bp, offset DrivesDirectory
	mov	dx, ds:[bp]
	clr	bx
	call	FileSetCurrentPath
	jnc	unlock
	call	FileCreateDir
	call	FileSetCurrentPath
unlock:
	mov	bx, handle DrivesDirectory
	call	MemUnlock
	jc	done

	call	NDNukeInvalidDriveLinks		; clean up Desktop/Drives
endif

	;
	; Create new links in the Drives directory
	;
	clr	ax				; drive number = al = 0
driveLoop:
	call	NDDoWeNeedADriveLink
	jc	next

	call	NDCreateDriveLinks
next:
	inc	al
	cmp	al, DRIVE_MAX_DRIVES		; number of drives
	jne	driveLoop
done::
	call	FilePopDir

	.leave
	ret
NDInitDriveLinks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDNukeInvalidDriveLinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerates through the current directory and finds drive
		links.  If the drive is no longer valid (as per the drive
		index table, or if the token of the built out drive link
		doesn't match the drive type) it destroys the link.  If
		it is valid it clears the bit from the index table (as it
		already exists).  This leaves us with a list of drive links
		that need to be created.

CALLED BY:	NDInitDrives

PASS:		es - locked down drive link index table
		current directory is directory to clean up.
		
RETURN:		es - locked down drive link index table (updated)

DESTROYED:	preserves es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDNukeInvalidDriveLinks	proc	near
	.enter

	sub	sp, size FileEnumParams
	mov	bp, sp				; ss:bx is FileEnumParams
	mov	ss:[bp].FEP_searchFlags, FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS
	mov	ss:[bp].FEP_returnAttrs.segment, cs
	mov	ss:[bp].FEP_returnAttrs.offset, offset driveLinkReturnAttrs
	mov	ss:[bp].FEP_returnSize, size FileLongName + size NewDeskObjectType
	mov	ss:[bp].FEP_matchAttrs.segment, 0
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	mov	ss:[bp].FEP_skipCount, 0

	call	FileEnum
	jc	error				; if error, give message

	tst	bx
	jz	done				; exit if no files

	push	bx				; save FileEnum block
	call	MemLock	
	mov	ds, ax				; ds is FileEnum block
	clr	dx				; ds:dx is filename of first

removeOrRegisterLoop:
	push	si
	mov	si, dx
	cmp	{NewDeskObjectType}ds:[si][(size FileLongName)], WOT_DRIVE
	pop	si
	jne	removeNext
	call	NDRemoveOrRegisterDriveLink
removeNext:
	add	dx, size FileLongName + size NewDeskObjectType
	loop	removeOrRegisterLoop

	pop	bx				; restore FileEnum block
	call	MemUnlock	
	call	MemFree				; unlock and free FileEnum block
	jmp	done

error:
	call	DesktopOKError
done:	
	.leave
	ret
NDNukeInvalidDriveLinks	endp


driveLinkReturnAttrs	FileExtAttrDesc	\
	<FEA_NAME,		0,	size FileLongName>,
	<FEA_DESKTOP_INFO,	size FileLongName,	size NewDeskObjectType>,
	<FEA_END_OF_LIST>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDRemoveOrRegisterDriveLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called on buffer entries of a FileName buffer created
		by FileEnum.  These files are drive links (i.e.of type
		WOT_DRIVE).  From each we get its drive number and if this
		drive still exists, mark it in the index table, if not, nuke
		the link.

CALLED BY:	NDNukeInvalidDriveLinks

PASS:		ds:dx - filename of link
		current directory is set to that of file pointed to by ds:dx
		es    - locked down drive link index table block
		
RETURN:		nothing

DESTROYED:	ax, bx, bp, di, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/09/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDRemoveOrRegisterDriveLink	proc	near
	uses	cx, dx, ds, es
	.enter

	push	es				; save index table segment
	clr	bx				; use current dir

	push	ds, dx				; save original filename
	mov	cx, size PathName
	sub	sp, cx				; push stack buffer
	segmov	es, ss, di
	mov	di, sp				; es:di is stack buffer
	call	FileReadLink

	segmov	ds, es, dx
	mov	dx, sp				; ds:dx is link target name
	call	FSDLockInfoShared
	mov	es, ax
	mov	cx, sp				; cx is current stack
	add	cx, size PathName		; cx is stack with popped buf.
	call	DriveLocateByName
	mov	sp, cx				; pop drive name stack buffer
	pop	ds, dx				; restore orig. filename
	mov	al, es:[si].DSE_number
	call	FSDUnlockInfoShared
	pop	es				; drive link index table segment
	jc	removeLink			; flags from DriveLocateByName

	tst	si
	jz	removeLink
		
	;
	; the index table is a 32 byte bitfield (256 values).  To go from
	; a value to the proper bit, divide by 8 to get which of the 32
	; bytes, and then take the bottom 3 bits (remainder of divide by 8)
	; and or at that bit position.
	;
	clr	ah				; ax is drive number
	mov	di, ax				; di is drive number
	shr	di, 1
	shr	di, 1				; divide by 8...
	shr	di, 1
	mov	cl, al
	and	cl, 0x07			; remove five high bits
	mov	bx, 1
	shl	bx, cl				; move into bit position
	test	{byte} es:[di], bl		; nuke drive?
	jz	removeLink

	;
	; Check the token characters of the link and see if they are valid.
	; If not set them valid, and nuke link if there is any trouble.
	;
	call	NDCheckDriveLinkToken
	jc	removeLink

	not	bl				; bl is negative flag
	and	{byte} es:[di], bl		; remove flag if set
	jmp	done

removeLink:
	call	FileDelete

done:
	.leave
	ret
NDRemoveOrRegisterDriveLink	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDCheckDriveLinkToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets an existing drive link to the correct token characters
		(faster than reading them, checking them and the writing them
		if not correct).  If there is any problem writing them, we
		return carry set which will destroy the link and rebuild it.

CALLED BY:	NDRemoreOrRegisterDriveLink

PASS:		al - drive number
		ds:dx - filename of link
		current directory is set to that of file pointed to by ds:dx

RETURN:		carry	set if token couldn't be set
			clear if they are set correctly

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDCheckDriveLinkToken	proc	near
	uses	ax, bx, cx, dx, bp, si, di, ds, es
	.enter

	; Get token for drive from .ini file

	call	GetDriveTokenFromIniFile
	jc	useDefault

	push	di, cx, bx			; push token onto stack
	segmov	es, ss
	mov	di, sp				; es:di = GeodeToken
	call	setToken
	pop	di, cx, bx			; remove token from stack
	jmp	done				;  without changing flags

useDefault:
	; Get token for drive type into es:di

	segmov	es, cs
	call	NDGetDriveTypeFromDriveNumber	; puts WDT in bp
	mov	di, bp
CheckHack< size GeodeToken eq 6 >
	shl	di, 1				; double WDT
	add	di, bp				; triple WDT for GeodeToken size
	add	di, offset driveLinkTokenTable
	call	setToken
done:
	.leave
	ret

setToken:
	;
	; if this fails it will return carry set, the drive will be nuked
	; and the link will be rebuilt.
	;
	mov	ax, FEA_TOKEN
	mov	cx, size GeodeToken
	call	FileSetPathExtAttributes
	retn

NDCheckDriveLinkToken	endp

endif		; if _NEWDESKONLY
endif		; if _NEWDESK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDriveTokenFromIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get drive token from .ini file

CALLED BY:	NDCheckDriveLinkToken

PASS:		al - drive number

RETURN:		carry clear if token found ( bx:cx:di = GeodeToken )
		carry set if no token found

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	8/19/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

systemCat char "system",0

GetDriveTokenFromIniFile	proc	near
token	local	10 dup (char)
	uses	ax,dx,si,ds,es
	.enter

	; Construct the drive icon key

	clr	ah
	add	al, 'a'
	push	ax
	push	'n '
	push	'co'
	push	'ei'
	push	'iv'
	push	'dr'

	; read from .ini file

	segmov	ds, cs
	mov	si, offset systemCat
	mov	cx, ss
	mov	dx, sp
	mov	es, cx
	lea	di, ss:[token]

	push	bp
	mov	bp, size token
	call	InitFileReadString
	pop	bp
	jc	done

	cmp	cx, size GT_chars + 1
	jc	done

	segmov	ds, ss
	lea	si, ss:[token+4]
	call	UtilAsciiToHex32
	jc	done

	mov	bx, {word}ss:[token][0]
	mov	cx, {word}ss:[token][2]
	mov	di, ax
	clc				; got GeodeToken from .ini file
done:
	lahf
	add	sp, 12			; remove drive icon key from stack
	sahf

	.leave
	ret
GetDriveTokenFromIniFile	endp

if _GMGR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsDriveValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the drive status of at drive and returns carry set
		if not present.  If we are in FileCabinet or NewDeskBA
		only accept floppies.

CALLED BY:	InitDrives

PASS:		al - drive number

RETURN:		ah - the drive status
		carry clear to accept drive
		carry set to reject it

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsDriveValid	proc	near
	.enter

	call	DriveGetStatus			; drive exist?
	
if _BMGR
	jc	done
	call	BMGRIsDriveValid
done:
endif

if _DOCMGR
	jc	done				; not present
	;
	; DocMgr HACK: A: only
	;
	cmp	al, 0
	je	done				; C clear
	stc
	jmp	short done
accept:
	clc
done:
endif

if _FCAB
	push	ax
	jc	done

	andnf	ah, mask DS_TYPE		; isolate drive type
	cmp	ah, DRIVE_5_25 shl offset DS_TYPE
	je	isAFloppy
	cmp	ah, DRIVE_3_5 shl offset DS_TYPE
	stc
	jne	done

isAFloppy:
	clc
done:
	pop	ax
endif		; if _FCAB

	.leave
	ret
IsDriveValid	endp
endif		; if _GMGR


if _NEWDESKONLY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDCreateDriveLinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a link and places it in the Drives directory (if it
		exists) or the Desktop (if not).

CALLED BY:	InitDrives

PASS:		al = drive number
		es = locked down drive link index buffer
		current directory is Drives dir or Desktop dir
		
RETURN:		none

DESTROYED:	preserves ax, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/09/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDCreateDriveLinks	proc	near
	uses	ax, es
	.enter

	sub	sp, size FileLongName
	mov	dx, sp
if GPC_CUSTOM_FLOPPY_NAME
	tst	al
	jnz	notA
	call	GPCGetFloppyDiskName
	jmp	short createLink
notA:
endif
	call	NDGetDriveLinkName
createLink::

	;
	; Allocate enough space for a drive name followed by a colon,
	; a backslash, and a dot.
	;

	mov	cx, DRIVE_NAME_MAX_LENGTH + 4
	sub	sp, cx				; allocate on the stack
	segmov	es, ss, bp
	mov	di, sp				; es:di is stack buffer
	call	DriveGetName

	mov	bp, ax				; save drive number in bp
SBCS <	mov	ax, ':' or (C_BACKSLASH shl 8)			>
DBCS <	mov	ax, ':'						>
	stosw
DBCS <	mov	ax, C_BACKSLASH					>
DBCS <	stosw							>
	mov	ax, '.'
	stosw
DBCS <	mov	ax, C_NULL					>
DBCS <	stosw							>

	mov	di, sp				; es:di is path
	segmov	ds, ss, bx			; ds gets stack segment
						;  so ds:dx is the link name
	clr	bx				; no disk handle and drive name
	mov	cx, -1				;  in es:di makes a drive link
	call	FileCreateLink			; cx != 0 means no target attrs.
	jnc	linkCreated

	;
	; creating the link failed, so don't bother trying to set the attrs
	; 
	add	sp, (size FileLongName) + DRIVE_NAME_MAX_LENGTH + 4
	jmp	exit

linkCreated:
	mov	ax, bp				; restore drive number to al
	call	NDGetDriveTypeFromDriveNumber	; puts WDT in bp
CheckHack< size GeodeToken eq 6 >
	mov	ax, bp
	shl	bp, 1				; double WDT
	add	bp, ax				; triple WDT for GeodeToken size
	add	bp, offset driveLinkTokenTable	; bp is drive token index

	mov	ax, FEA_MULTIPLE
	segmov	es, ss, di
	sub	sp, size FileExtAttrDesc
	mov	di, sp				; es:di is the third FEAD
	mov	es:[di].FEAD_attr, FEA_DESKTOP_INFO
	mov	es:[di].FEAD_value.segment, cs
	mov	es:[di].FEAD_value.offset, offset driveWOT
	mov	es:[di].FEAD_size, size NewDeskObjectType
	sub	sp, size FileExtAttrDesc
	mov	di, sp				; es:di is the second FEAD
	mov	es:[di].FEAD_attr, FEA_FILE_ATTR
	mov	es:[di].FEAD_value.segment, cs
	mov	es:[di].FEAD_value.offset, offset driveLinkAttrs
	mov	es:[di].FEAD_size, size FileAttrs
	sub	sp, size FileExtAttrDesc
	mov	di, sp				; es:di is the first FEAD
	mov	es:[di].FEAD_attr, FEA_TOKEN
	mov	es:[di].FEAD_value.segment, cs
	mov	es:[di].FEAD_value.offset, bp
	mov	es:[di].FEAD_size, size GeodeToken
	mov	cx, 3
	call	FileSetPathExtAttributes	; set link's WOT to WOT_DRIVE
						;   as well as FA_SUBDIR flag
	add	sp, DRIVE_NAME_MAX_LENGTH + 4 + (size FileLongName) +	\
			(3 * (size FileExtAttrDesc))	 ; pop buffers
exit:
	.leave
	ret
NDCreateDriveLinks	endp

driveWOT	NewDeskObjectType	WOT_DRIVE

driveLinkAttrs	FileAttrs	mask FA_SUBDIR

driveLinkTokenTable	label	GeodeToken
	GeodeToken <'FL52', MANUFACTURER_ID_GEOWORKS>	; WDT_FLOPPY5_25
	GeodeToken <'FL35', MANUFACTURER_ID_GEOWORKS>	; WDT_FLOPPY3_5
	GeodeToken <'HDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_HARDDISK
	GeodeToken <'CDRM', MANUFACTURER_ID_GEOWORKS>	; WDT_CD_ROM
	GeodeToken <'NDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_NETDISK
	GeodeToken <'RDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_RAMDISK
	GeodeToken <'VDSK', MANUFACTURER_ID_GEOWORKS>	; WDT_REMOVABLE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDGetDriveLinkName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds a name for a link given a drive number.
			If the drive name (A:, B:, CALVIN:) is greater than
		can fit with the default string "Drive " prepended to it
		will have just the drive name (no "Drive ").

CALLED BY:	DoNDDriveLinks

PASS:		al	- drive number
		ss:dx	- buffer to place name

RETURN:		ss:dx filled with link name

DESTROYED:	bx, cx, bp, di, si, es, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/09/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDGetDriveLinkName	proc	near
	.enter

	push	ax				; save drive number
	mov	bx, handle NDDriveNameTemplate
	call	MemLock				; lock DeskStrings resource
	mov	es, ax
	mov	si, offset NDDriveNameTemplate
	mov	di, es:[si]			; es:di is "Drive " string
	mov	cx, -1
	clr	ax
	repne	scasb				; get length
	not	cx
	mov	bp, cx				; save length in bp
	pop	ax				; restore drive number
	clr	cx
	call	DriveGetName			; get drive name length
	add	cx, bp				; get sum
	cmp	cx, FILE_LONGNAME_LENGTH
	mov	di, dx				; default to beginning of buffer
	jg	skipPrepend

	segmov	ds, es, cx
	mov	si, ds:[si]			; ds:si is "Drive " string
	segmov	es, ss, cx			; es:di is file link buffer
	mov	cx, bp				; length of "Drive " string
	rep	movsb
	dec	di				; null will be overwritten

skipPrepend:
	segmov	es, ss, cx			; es:di is file link buffer
	mov	cx, FILE_LONGNAME_LENGTH
	call	DriveGetName			; get drive name into buffer

	mov	bx, handle NDDriveNameTemplate
	call	MemUnlock			; unlock DeskStrings resource

	.leave
	ret
NDGetDriveLinkName	endp

if GPC_CUSTOM_FLOPPY_NAME
GPCGetFloppyDiskName	proc
	mov	bx, handle GPCFloppyDiskName
	call	MemLock
	mov	ds, ax
	mov	si, offset GPCFloppyDiskName
	mov	si, ds:[si]
	segmov	es, ss, cx
	mov	di, dx
	LocalCopyString
	mov	bx, handle GPCFloppyDiskName
	call	MemUnlock
	ret
GPCGetFloppyDiskName	endp
endif

endif		; if _NEWDESKONLY




if _GMGR
if _ICON_AREA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoIconAreaDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a drive number in al and creates a drive button for
		it, placing the button in the ToolAreaClass object in dx.

CALLED BY:	InitDrives

PASS:		al = drive number to be added
		ah = DriveStatus
		dx = offset IconArea or offset FloatingDrivesDialog
		
RETURN:		none

DESTROYED:	preserves ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _DOCMGR
DriveIconStruct	struct
    DIS_type DriveStatus	<>
    DIS_icon lptr
    DIS_help lptr
DriveIconStruct ends
else
DriveIconStruct	struct
    DIS_type DriveStatus	<>
    DIS_icon lptr
DriveIconStruct ends
endif

; To keep the table more readable...
.assert offset DS_TYPE eq 0

if _DOCMGR
driveIcons	DriveIconStruct	\
    <DRIVE_5_25 ,  offset Floppy525Template, offset FloppyFocusHelp>,
    <DRIVE_3_5 ,	offset Floppy35Template, offset FloppyFocusHelp>,
    <DRIVE_FIXED,	offset HardDiskTemplate, offset DiskFocusHelp>,
    <DRIVE_CD_ROM ,	offset CDRomTemplate, offset CDRomFocusHelp>,
    <DRIVE_PCMCIA ,	offset PCMCIADiskTemplate, offset DiskFocusHelp>,
    <DRIVE_FIXED or mask DS_NETWORK, offset NetDiskTemplate, offset DiskFocusHelp>,
    <DRIVE_RAM,		offset RamDiskTemplate, offset DiskFocusHelp>,
    <DRIVE_UNKNOWN,	offset NetDiskTemplate, offset DiskFocusHelp>
else
driveIcons	DriveIconStruct	\
    <DRIVE_5_25 ,  offset Floppy525Template>,
    <DRIVE_3_5 ,	offset Floppy35Template>,
    <DRIVE_FIXED,	offset HardDiskTemplate>,
    <DRIVE_CD_ROM ,	offset CDRomTemplate>,
    <DRIVE_PCMCIA ,	offset PCMCIADiskTemplate>,
    <DRIVE_FIXED or mask DS_NETWORK, offset NetDiskTemplate>,
    <DRIVE_RAM,		offset RamDiskTemplate>,
    <DRIVE_UNKNOWN,	offset NetDiskTemplate>
endif

DoIconAreaDrive	proc	near
	uses	ax
	.enter
	;
	; add appropriate drive icon to drive area
	;
	push	ax				; save drive
	mov	cx, handle IconAreaResource	; cx:dx = dest. for new icon
	cmp	dx, offset IconAreaResource:IconArea
	je	gotResource
	mov	cx, handle PrimaryInterface
gotResource:
	;
	; check for removable disk first
	;
	andnf	ah, mask DS_TYPE or mask DS_NETWORK or mask DS_MEDIA_REMOVABLE
	mov	bx, handle RemovableDiskTemplate
	mov	si, offset RemovableDiskTemplate
if _DOCMGR
	mov	di, offset DiskFocusHelp
endif
	cmp	ah, DRIVE_FIXED shl offset DS_TYPE or mask DS_MEDIA_REMOVABLE
	je	copy
	;
	; now check for other types of disks
	;
	andnf	ah, mask DS_TYPE or mask DS_NETWORK
	clr	bx
startLoop:
	cmp	ah, cs:[driveIcons][bx].DIS_type
	je	found
	add	bx, size DriveIconStruct
	cmp	bx, size driveIcons
	jb	startLoop
EC <	ERROR	UNKNOWN_DRIVE_TYPE				>

found:
if _DOCMGR
	mov	di, cs:[driveIcons][bx].DIS_help
endif
	mov	si, cs:[driveIcons][bx].DIS_icon		
	mov	bx, handle IconAreaTemplates
copy:
	mov	ax, MSG_GEN_COPY_TREE
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
if _DOCMGR
	push	di
	call	ObjMessageCallFixup		; cx:dx = new drive tool object
	pop	di
else
	call	ObjMessageCallFixup		; cx:dx = new drive tool object
endif
	pop	bp				; retrieve new drive number
	push	bp				;  ...and immediately save it!
	mov	bx, cx				; bx:si = new drive tool object
	mov	si, dx
	mov	ax, MSG_DRIVE_TOOL_SET_DRIVE
if _DOCMGR
	;
	; add focus help
	;
	push	di
	call	ObjMessageCallFixup
	pop	di
	mov	dx, size AddVarDataParams + (size optr)
	sub	sp, dx
	mov	bp, sp
	mov	ax, handle DeskStringsCommon
	mov	({optr}ss:[bp][(size AddVarDataParams)]).handle, ax
	mov	({optr}ss:[bp][(size AddVarDataParams)]).offset, di
	lea	ax, ss:[bp][(size AddVarDataParams)]
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ss:[bp].AVDP_data.offset, ax
	mov	ss:[bp].AVDP_dataSize, size optr
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_FOCUS_HELP
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams + (size optr)
else
	call	ObjMessageCallFixup
endif
	pop	bp				; retrieve drive number
	;
	; check for drive icon moniker override
	;
	call	CheckDriveINIOverride
	;
	; set keyboard accelerator for drive button, based on drive letter
	;	SHIFT + drive letter
	;	^lbx:si = new drive button
	;	bp = drive number
	;
	mov	cx, bp				; cl = drive number
	cmp	cl, 26
	jae	afterAccel			; only for drives 'A'-'Z'
	clr	ch
	add	cx, 'a'				; convert to drive letter
	ornf	cx, mask KS_PHYSICAL or mask KS_SHIFT	; allowing 'A' or 'a'
	mov	ax, MSG_GEN_SET_KBD_ACCELERATOR
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
afterAccel:
	;
	; set usable
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup

	.leave
	ret
DoIconAreaDrive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDriveINIOverride
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there is an override in the .INI file for the
		drive icon

CALLED BY:	DoIconAreaDrive()

PASS:		^lbx:si	= DriveToolClass object
		bp.low	= drive number to be added
		bp.high	= DriveStatus
		
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/13/98		Initial version
	joon	8/20/98		Modified version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDriveINIOverride	proc	near
drive	local	word			push	bp
object	local	optr			push	bx, si
moniker	local	optr
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	mov	ax, ss:[drive]		; al = drive number
	call	GetDriveTokenFromIniFile; bx:cx:di = GeodeToken
	LONG jc	done

	push	bx, cx
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx			; default size
	call	MemAllocLMem		; ^hbx = block handle
	mov	ss:[moniker].handle, bx
	pop	ax, bx

	mov	si, di			; ax:bx:si = GeodeToken
	mov	dh, ss:[desktopDisplayType]
	mov	cx, ss:[moniker].handle	; allocate chunk in block
	push	(VMS_ICON shl offset VMSF_STYLE) or mask VMSF_GSTRING
	push	0			; unused buffer size
	call	TokenLoadMoniker	; ^lcx:di = icon moniker
	mov	ss:[moniker].offset, di
	LONG jc	done

	; insert the drive name in the icon moniker

	mov	bx, ss:[moniker].handle
	call	MemLock
	mov	ds, ax

	; make sure we have a gstring moniker

	mov	si, ds:[di]		; ds:si = VisMoniker
	test	ds:[si].VM_type, mask VMT_GSTRING
	jz	freeBlock

	; reset cached size so moniker size will be recalculated

	clr	ax
	mov	ds:[si].VM_width, ax
	mov	ds:[si].VM_data+VMGS_height, ax

	; get length of drive name

	mov	ax, ss:[drive]
	clr	cx			; buffer size = 0 so we get length
	call	DriveGetName		;  of name back always

	; insert space for drive name gstring commands

	push	cx
	mov	ax, di			; *ds:ax = icon moniker
	add	cx, (size OpSetFont) + (size OpDrawTextAtCP)
	mov	bx, VM_data+VMGS_gstring
	call	LMemInsertAt
	pop	cx

	; set font and font size

	mov	si, ds:[di]
	add	si, VM_data+VMGS_gstring
	mov	ds:[si].OSF_opcode, GR_SET_FONT
	mov	ds:[si].OSF_size.WBF_int, DRIVETOOL_LABEL_POINTSIZE
	mov	ds:[si].OSF_size.WBF_frac, 0
	mov	ds:[si].OSF_id, DRIVETOOL_LABEL_FONT
	add	si, size OpSetFont

	; draw text (drive name)

	mov	ds:[si].ODTCP_opcode, GR_DRAW_TEXT_CP
DBCS <	shr	cx, 1							>
	mov	ds:[si].ODTCP_len, cx
DBCS <	shl	cx, 1							>
	add	si, size OpDrawTextAtCP

	push	es, di
	segmov	es, ds
	mov	di, si
	mov	ax, ss:[drive]
	call	DriveGetName
	pop	es, di

	mov	bx, ss:[moniker].handle
	call	MemUnlock

	; update icon moniker

	push	bx, bp
	movdw	bxsi, ss:[object]
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	movdw	cxdx, ss:[moniker]
	mov	bp, VUM_MANUAL
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bx, bp

freeBlock:
	call	MemFree
done:
	.leave
	ret
CheckDriveINIOverride	endp

endif		; if _ICON_AREA
endif		; if _GMGR


if not _ZMGR
if _GMGRONLY
if (_TREE_MENU)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoTreeDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add appropriate tree drive button to tree drive list

CALLED BY:	InitDrives

PASS:		al = drive number
		
RETURN:		none

DESTROYED:	preserves ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoTreeDrive	proc	near
	uses	ax
	.enter

	clr	ah
	push	ax				; save drive
	mov	bx, handle MiscUI
	mov	si, offset MiscUI:DriveLetterButtonTemplate
	mov	ax, MSG_GEN_COPY_TREE
	mov	cx, handle TreeMenuDriveList	; cx = block to copy into
	mov	dx, offset TreeMenuDriveList	; dx = chunk of parent
	mov	bp, CCO_LAST			; not dirty
	call	ObjMessageCallFixup		; cx:dx = new drive letter obj
	mov	bx, cx				; bx:si = new drive letter obj
	mov	si, dx
	pop	bp				; retrieve new drive number
	mov	cx, FALSE			; no mnemonic
	mov	ax, MSG_DRIVE_LETTER_SET_DRIVE	; set it
	call	ObjMessageCallFixup
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup

	.leave
	ret
DoTreeDrive	endp
endif		; if (_TREE_MENU)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoKeyboardDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add appropriate keyboard drive button to keyboard menu list

CALLED BY:	InitDrives

PASS:		al = drive number
		
RETURN:		none

DESTROYED:	preserves ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoKeyboardDrive	proc	near
	uses ax
	.enter

	clr	ah
	push	ax				; save drive number
	mov	bx, handle MiscUI
	mov	si, offset MiscUI:KeyboardDriveTriggerTemplate
	mov	ax, MSG_GEN_COPY_TREE
	mov	cx, handle OpenDrives		; cx = block to copy into
	mov	dx, offset OpenDrives		; dx = chunk of parent
	mov	bp, CCO_LAST			; not dirty
	call	ObjMessageCallFixup

	mov	bx, cx				; cx:dx = new trigger obj
	mov	si, dx				; bx:si = new trigger obj
						; drive number on stack
	mov	dx, size AddVarDataParams
	mov	cx, sp				; save ptr to drive # (on stack)
	sub	sp, dx				; allocate this on the stack
	mov	bp, sp				; ss:bp points to stack
	mov	ax, ss
	mov	ss:[bp].AVDP_data.segment, ax
	mov	ss:[bp].AVDP_data.offset, cx
	mov	ss:[bp].AVDP_dataSize, size byte
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size AddVarDataParams	; pop structure off stack

	pop	ax				; restore drive number
	clr	cx				; give it zero size buffer so
	call	DriveGetName			; it will tell us how much
EC <	tst	cx							>
EC <	ERROR_Z	DRIVE_TOOL_BOUND_TO_INVALID_DRIVE			>
	inc	cx				; make room for ':'
	sub	sp, cx				; allocate on the stack
	segmov	es, ss, di
	mov	di, sp				; es:di points to stack buffer
	mov	bp, sp				; save in bp too
	push	cx				; save stack buffer size
	call	DriveGetName			; called with enough space
	mov	ax, ':' or (0 shl 8)		; add colon on end
	stosw
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, ss
	mov	dx, bp				; cx:dx points to drive name
	mov	bp, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup

	pop	ax				; pop stack buffer size
	add	sp, ax				; pop the stack buffer

	.leave
	ret
DoKeyboardDrive	endp
endif		; if _GMGRONLY
endif		; if (not _ZMGR)


if _GMGR
if _DISK_OPS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFormatDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up Format Disk for this drive

CALLED BY:	InitDrives

PASS:		al = drive number

RETURN:		none

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoFormatDrive	proc	near
	.enter

	;
	; See if the disk is formattable.  Check the (extended status)
	; DES_FORMATTABLE flag.
	;

	push	ax
	call	DriveGetExtStatus
	mov_tr	cx, ax
	pop	ax
	test	cx, mask DES_FORMATTABLE
	jz	done

	mov	dx, offset DiskMenuResource:DiskFormatSourceList
	mov	bx, FALSE			; don't set mnemonic
	call	DoDriveLetterCommon		; (di = identifier)
	jnz	notCurrent

store:
	mov	ss:[formatCurDrive], di		; save current drive identifier

notCurrent:
	cmp	ss:[formatCurDrive], -1		; have we stored default yet?
	jz	store				; no, store this as default
done:
	.leave
	ret
DoFormatDrive	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCopySrcDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add a ui item to the Copy Source dialog

CALLED BY:	InitDrives

PASS:		al = drive number
		
RETURN:		none

DESTROYED:	preserves ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoCopySrcDrive	proc	near
	uses	ax
	.enter

	call	CheckUnknownMedia
	je	done
	andnf	ah, mask DS_TYPE		; mask out drive types
	cmp	ah, DRIVE_5_25 shl offset DS_TYPE
	je	allowIt
	cmp	ah, DRIVE_3_5 shl offset DS_TYPE
	jne	done
allowIt:
	mov	dx, offset DiskMenuResource:DiskCopySourceList
	mov	bx, FALSE			; don't set mnemonic
	call	DoDriveLetterCommon		; Z set if current drive
	jnz	notCurrent			; no
						; (di = identifier)
store:
	mov	ss:[copyCurDrive], di		; save current drive identifer
notCurrent:
	cmp	ss:[copyCurDrive], -1		; have we stored default yet?
	jz	store				; no, store this as default
done:
	.leave
	ret
DoCopySrcDrive	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCopyRenameDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add a ui item to the Rename dialog

CALLED BY:	InitDrives

PASS:		al = drive number
		
RETURN:		none

DESTROYED:	preserves ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoRenameDrive	proc	near
	.enter

if _ZMGR
	;
	; only allow rename of PCMCIA in ZMGR
	;
	push	ax
	call	DriveGetStatus			; ah = DriveStatus
	andnf	ah, mask DS_TYPE
	cmp	ah, DRIVE_PCMCIA shl offset DS_TYPE
	pop	ax
	jne	done				; not PCMCIA
endif

	mov	dx, offset DiskMenuResource:DiskRenameDriveList
	mov	bx, FALSE			; no mnemonic
	call	DoDriveLetterCommon		; (di = identifier)
	jnz	notCurrent
store:
	mov	ss:[renameCurDrive], di		; save current drive
notCurrent:
	cmp	ss:[renameCurDrive], -1		; have we stored default yet?
	jz	store				; no, store this as default

if _ZMGR
done:
endif
	.leave
	ret
DoRenameDrive	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFormatDriveDefaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the list item of the default drive in the Format Disk
		dialog.

CALLED BY:	InitDrives

PASS:		none
RETURN:		none
DESTROYED:	all

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFormatDriveDefaults	proc	near
	.enter

	;
	; select current drive for format drive list
	;
	mov	bx, handle DiskFormatSourceList
	mov	si, offset DiskFormatSourceList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	cx, ss:[formatCurDrive]
	cmp	cx, -1				; any?
	je	noFormatDrives			; no, disable format

	call	ObjMessageFixup
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	enableDisable

noFormatDrives:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
enableDisable:
	mov	bx, handle DiskFormatButton
	mov	si, offset DiskFormatButton
	mov	dl, VUM_NOW
	push	ax
	call	ObjMessageFixup
	pop	ax
	mov	bx, handle DiskFormatBox
	mov	si, offset DiskFormatBox
	mov	dl, VUM_NOW
	call	ObjMessageFixup
	.leave
	ret
SetFormatDriveDefaults	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCopyRenameDriveDefaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the list item of the default drive in the Copy Disk
		and Rename Disk dialogs

CALLED BY:	InitDrives

PASS:		none
RETURN:		none
DESTROYED:	all

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCopyRenameDriveDefaults	proc	near
	.enter

	;
	; select current drive for copy source list
	;
	mov	bx, handle DiskCopySourceList
	mov	si, offset DiskCopySourceList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	cx, ss:[copyCurDrive]
	cmp	cx, -1				; any?
	jz	noCopyDrives			; no, disable copy

	call	ObjMessageFixup
if not _ZMGR
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	copyEnableDisable
else
	jmp	short selectRename
endif

noCopyDrives:
if not _ZMGR
	mov	ax, MSG_GEN_SET_NOT_ENABLED
copyEnableDisable:
	mov	bx, handle DiskCopyButton
	mov	si, offset DiskCopyButton
	mov	dl, VUM_NOW
	push	ax
	call	ObjMessageFixup
	pop	ax
	mov	bx, handle DiskCopyBox
	mov	si, offset DiskCopyBox
	mov	dl, VUM_NOW
	call	ObjMessageFixup
endif

selectRename::
	;
	; select current drive for rename drive list
	;
	mov	bx, handle DiskRenameDriveList
	mov	si, offset DiskRenameDriveList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	cx, ss:[renameCurDrive]
	cmp	cx, -1
	je	noRenameDrives
	call	ObjMessageFixup
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	renameEnableDisable

noRenameDrives:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
renameEnableDisable:
if not _ZMGR
	mov	bx, handle DiskRenameButton
	mov	si, offset DiskRenameButton
else
	mov	bx, handle UtilMenuDiskRename
	mov	si, offset UtilMenuDiskRename
endif
	mov	dl, VUM_NOW
	push	ax
	call	ObjMessageFixup
	pop	ax
	mov	bx, handle DiskRenameBox
	mov	si, offset DiskRenameBox
	mov	dl, VUM_NOW
	call	ObjMessageFixup

	.leave
	ret
SetCopyRenameDriveDefaults	endp
endif		; if _DISK_OPS
endif		; if _GMGR





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCopyDestDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add a ui item to the Copy Dest dialog

CALLED BY:	InitDrives

PASS:		al = drive number
		
RETURN:		none

DESTROYED:	preserves ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _DISK_OPS
DoCopyDestDrive	proc	near
	uses	ax
	.enter

	call	CheckUnknownMedia
	je	done

	call	DriveGetStatus
	andnf	ah, mask DS_TYPE		; mask out drive types
	cmp	ah, DRIVE_5_25 shl offset DS_TYPE
	je	allowIt
	cmp	ah, DRIVE_3_5 shl offset DS_TYPE
	jne	done

allowIt:
	mov	dx, offset DiskMenuResource:DiskCopyDestList
	mov	bx, FALSE			; don't set mnemonic
	call	DoDriveLetterCommon

done:
	.leave
	ret
DoCopyDestDrive	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckUnknownMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check to see if a drive is of a media that we can handle

CALLED BY:	DoFormatDrive, DoCopySrcDrive, DoCopyDestDrive

PASS:		al = drive number

RETURN:		zero flag SET if unknown media

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckUnknownMedia proc near
	uses	ax
	.enter

						; make sure it's a media
	call	DriveGetDefaultMedia		;  type we can handle
	cmp	ah, MEDIA_CUSTOM		;  i.e. it ain't custom

	.leave
	ret
CheckUnknownMedia endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoDriveLetterCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make a DriveLetter ui object for the given drive

CALLED BY:	DoFormatDrive, DoCopySrcDrive, DoRenameDrive, DoCopyDestDrive

PASS:		al = drive number
		dx = chunk handle of object to append to 
		bx = TRUE to set mnemonic
		     FALSE to not set mnemonic

		
RETURN:		^lbx:si = new drive letter
		di = identifier for drive button

DESTROYED:	preserves ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/07/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoDriveLetterCommon	proc	near

	uses	ax

	.enter

	clr	ah
	push	bx				; save mnemonic flag
	push	ax	 			; save drive
	mov	bx, handle MiscUI
	mov	si, offset MiscUI:DriveLetterButtonTemplate
	mov	ax, MSG_GEN_COPY_TREE
	mov	cx, handle DiskMenuResource
;	mov	bp, CCO_LAST			; not dirty
;mark dirty as we'll delete anyway - brianc 7/15/93
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
	call	ObjMessageCallFixup		; cx:dx = new drive letter obj
	pop	bp				; retrieve new drive number
	mov	bx, cx				; bx:si = new drive letter obj
	mov	si, dx
	pop	cx				; get mnemonic flag
	mov	ax, MSG_DRIVE_LETTER_SET_DRIVE
	call	ObjMessageCallFixup		; preserves bp = drive letter
	push	ax				; ax = GenItem identifier
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage
	pop	di				; save for return
	;
	; select this letter if it is current drive
	;	bx:si = drive letter to check
	;	bp - this drive number
	;
	push	bx
	clr	cx				; get disk handle only
	call	FileGetCurrentPath		; plenty fast routine
	call	DiskGetDrive
	pop	bx
	mov	cx, bp				; cl - drive number
	cmp	cl, al				; current drive?
						; Z set if so
	.leave
	ret
DoDriveLetterCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSystemPathnames
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get Application and Document directory pathnames

CALLED BY:	INTERNAL
			DesktopOpenApplication

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/27/90	Initial version
	brianc	08/16/90	modified for all system folders

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSystemPathnames	proc	near
	;
	; get GEOS system disk handle
	;
	mov	ax, SGIT_SYSTEM_DISK
	call	SysGetInfo
	mov	ss:[geosDiskHandle], ax
	;
	; make default tree drive the application drive 
	;
if not _ZMGR
if _GMGRONLY
if _TREE_MENU		
	mov	bx, ss:[geosDiskHandle]
	call	DiskGetDrive			; al = drive
	call	DriveGetDefaultMedia		; ah = media
	mov	cx, ax				; cx = drive/media (identifier)
	mov	bx, handle TreeMenuDriveList
	mov	si, offset TreeMenuDriveList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessageFixup
;	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
;	mov	cx, TRUE
;	call	ObjMessageFixup			; allow apply
endif		; if _TREE_MENU		
endif		; if _GMGRONLY
endif		; if (not _ZMGR)
	ret
GetSystemPathnames	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDriveChangeNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle drive change notification

CALLED BY:	MSG_NOTIFY_DRIVE_CHANGE

PASS:		ds	= dgroup
		es 	= segment of DesktopClass
		ax	= MSG_NOTIFY_DRIVE_CHANGE

		cx	= GCNDriveChangeNotificationType
		dx	= drive number

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Ignore GCNDriveChangeNotificationType and drive number
		and just rebuild our drive lists.

		Should also close folders to destroyed drives.

		This may not be the best resource for this, but if we get
		this message, we are going to rebuild the drive lists, so
		we'll need that code (which is in InitCode).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/2/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _GMGR
DesktopDriveChangeNotify	method	DesktopClass, MSG_NOTIFY_DRIVE_CHANGE
	cmp	cx, GCNDCNT_DESTROYED
	je	driveCreateDestroyCommon
	cmp	cx, GCNDCNT_CREATED
	LONG jne	done

driveCreateDestroyCommon:
	push	cx				; save destroy/create flag
	;
	; drive destroyed, find and remove from each drive list
	; drive created, remove any existing one before creating
	;
if _ICON_AREA
	clr	cx
	mov	bx, handle IconArea
	mov	si, offset IconArea
	call	findAndDestroyChild
GMONLY<	mov	bx, handle FloatingDrivesDialog				>
GMONLY<	mov	si, offset FloatingDrivesDialog				>
GMONLY<	clr	cx							>
GMONLY<	call	findAndDestroyChild					>
endif	; _ICON_AREA

if not _ZMGR
if _TREE_MENU		
GMONLY<	mov	bx, handle TreeMenuDriveList				>
GMONLY<	mov	si, offset TreeMenuDriveList				>
GMONLY<	call	findAndDestroyChildItem					>
endif 	;_TREE_MENU
		
	push	dx				; save drive number
	mov	cx, -1				; start at 1st child (will inc)
checkOpenDrive:
	inc	cx
	push	dx, cx				; save drive #, child #
	mov	bx, handle OpenDrives
	mov	si, offset OpenDrives
	mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
	call	ObjMessageCallFixup		; ^lcx:dx = child
	pop	di, bp				; di = drive #, bp = child #
	jc	doneOpenDrive			; not found, cx = 0
	push	di, bp				; save drive #, child #
	movdw	bxsi, cxdx
EC <	mov	cx, segment GenTriggerClass				>
EC <	mov	dx, offset GenTriggerClass				>
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				>
EC <	call	ObjMessageCallFixup					>
EC <	ERROR_NC	DESKTOP_FATAL_ERROR				>
	push	ax				; make room for return
	mov	ax, sp
	mov	dx, size GetVarDataParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GVDP_buffer.segment, ss
	mov	ss:[bp].GVDP_buffer.offset, ax
	mov	ss:[bp].GVDP_bufferSize, size word
	mov	ss:[bp].GVDP_dataType, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	ax, MSG_META_GET_VAR_DATA
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage			; drive on stack
	add	sp, size GetVarDataParams
EC <	cmp	ax, -1							>
EC <	ERROR_E	DESKTOP_FATAL_ERROR					>
	pop	ax				; al = drive
	clr	ah
	mov	bp, ax				; bp = drive #
	pop	dx, cx				; dx = drive #, cx = child #
	cmp	dx, bp				; is this the one?
	jne	checkOpenDrive			; nope, continue
	call	destroyThisOne			; else, destroy it
doneOpenDrive:
	pop	dx				; dx = drive number
endif

if _DISK_OPS
	mov	bx, handle DiskFormatSourceList
	mov	si, offset DiskFormatSourceList
	call	findAndDestroyChildItem

	mov	bx, handle DiskCopySourceList
	mov	si, offset DiskCopySourceList
	call	findAndDestroyChildItem

	mov	bx, handle DiskCopyDestList
	mov	si, offset DiskCopyDestList
	call	findAndDestroyChildItem

	mov	bx, handle DiskRenameDriveList
	mov	si, offset DiskRenameDriveList
	call	findAndDestroyChildItem
endif
		
	pop	cx
	cmp	cx, GCNDCNT_DESTROYED
	je	maybeDisableThings			; if destroyed, done

if _CONNECT_TO_REMOTE
	;
	; drive created, if waiting for RFSD connection, assume it has
	; happened
	;
	push	es
NOFXIP<	segmov	es, dgroup, ax						>
FXIP<	GetResourceSegmentNS dgroup, es					>
	call	FileLinkingEstablished
	pop	es
endif

	;
	; If we are detaching, don't bother adding new drive - brianc 7/15/93
	;
	push	dx				; save drive number
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication		; ax = ApplicationStates
	pop	dx
	jnc	done				; no answer, no app obj
	test	ax, mask AS_DETACHING
	jnz	done

;	mov	ss:[formatCurDrive], -1		; this one needs initializing
;	mov	ss:[copyCurDrive], -1		; this one needs initializing
;	mov	ss:[renameCurDrive], -1		; this one needs initializing
;must initialize to current selection, not -1 - brianc 7/12/93
	push	dx				; save drive number
if _DISK_OPS
	mov	bx, handle DiskRenameDriveList
	mov	si, offset DiskRenameDriveList
	mov	di, offset renameCurDrive
	call	initToCurSel

	mov	bx, handle DiskCopySourceList
	mov	si, offset DiskCopySourceList
	mov	di, offset copyCurDrive
	call	initToCurSel

	mov	bx, handle DiskFormatSourceList
	mov	si, offset DiskFormatSourceList
	mov	di, offset formatCurDrive
	call	initToCurSel
endif
	pop	dx				; dx = drive number

	;
	; drive created, add item to end of each drive list
	;	dx = drive number
	;
	push	dx				; save drive number
if _ICON_AREA
	call	GetDriveButtonToolAreaDestination	; dx = dest
endif	;_ICON_AREA
	pop	ax				; al = drive number
	call	DriveGetStatus
if _ICON_AREA
	call	DoIconAreaDrive
endif
if not _ZMGR
if (_TREE_MENU)		
GMONLY <	call	DoTreeDrive					>
endif		
GMONLY<	call	DoKeyboardDrive	>
endif
if _DISK_OPS
	call	DoFormatDrive
	call	DoCopySrcDrive
	call	DoCopyDestDrive
	call	DoRenameDrive
endif

adjustDefaults:
if _DISK_OPS
	call	SetCopyRenameDriveDefaults
	call	SetFormatDriveDefaults
endif
done:
	ret			; <-- EXIT HERE

maybeDisableThings:

if _CONNECT_TO_REMOTE
	;
	; drive destroyed, if RFSD connection active, assume it has
	; gone away
	;
	push	es
NOFXIP<	segmov	es, dgroup, ax						>
FXIP<	GetResourceSegmentNS dgroup, es					>
	call	FileLinkingRemoved
	pop	es
endif

	;
	; drive destroyed, tell folders to close if on destroyed disk
	;	dx = drive
	;
	mov	cl, dl			; cl = drive
	mov	ax, MSG_CLOSE_IF_DRIVE
	mov	di, mask MF_FIXUP_DS
	call	SendToTreeAndBroadcast

if _DISK_OPS
	mov	bx, handle DiskRenameDriveList
	mov	si, offset DiskRenameDriveList
	mov	di, offset renameCurDrive
	call	setNeg1IfEmpty

	mov	bx, handle DiskCopySourceList
	mov	si, offset DiskCopySourceList
	mov	di, offset copyCurDrive
	call	setNeg1IfEmpty

	mov	bx, handle DiskFormatSourceList
	mov	si, offset DiskFormatSourceList
	mov	di, offset formatCurDrive
	call	setNeg1IfEmpty
endif
	jmp	adjustDefaults

;
; pass:
; 	^lbx:si	= list to examine for emptiness
; 	ss:di	= word to set to -1 if list is empty
; return:
; 	nothing
; destroyed:
; 	ax, cx, dx, bp
setNeg1IfEmpty:
	push	di
	mov	ax, MSG_GEN_COUNT_CHILDREN
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	tst	dx
	jnz	sN1IEDone
		.assert (type copyCurDrive eq word) and \
			(type formatCurDrive eq word)
	mov	{word}ss:[di], -1
sN1IEDone:
	retn

;
; pass:
; 	^lbx:si	= list to set from
; 	ss:di	= word to init
; return:
; 	nothing
; destroyed:
; 	ax, cx, dx, bp
initToCurSel:
	push	di
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage			; ax = cur sel
	pop	di
		.assert (type copyCurDrive eq word) and \
			(type formatCurDrive eq word)
	mov	{word}ss:[di], ax
	retn

;
; pass:
;	^lbx:si = parent object
;	cx = starting child
;	dx = drive #
; return:
;	nothing
;
if _ICON_AREA
findAndDestroyChild	label	near
	push	dx
	mov	ax, MSG_TA_FIND_DRIVE
	call	ObjMessageCallFixup		; ^lcx:dx = child
endif
checkChild:
	; on stack = drive #
	jcxz	noChild
	pushdw	bxsi
	movdw	bxsi, cxdx
	call	destroyThisOne
	popdw	bxsi
noChild:
	pop	dx
	retn
;
; pass:
;	^lbx:si = object to destroy
;
destroyThisOne	label	near
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	clr	bp
	call	ObjMessageCallFixup
	retn

;
; pass:
;	^lbx:si = parent object
;	dx = drive number
;
findAndDestroyChildItem	label	near
EC <	push	cx, dx							>
EC <	mov	cx, segment DriveListClass				>
EC <	mov	dx, offset DriveListClass				>
EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS				>
EC <	call	ObjMessageCallFixup					>
EC <	pop	cx, dx							>
EC <	ERROR_NC	DESKTOP_FATAL_ERROR				>
	push	dx
	mov	cl, dl				; cl = drive number
	mov	ax, MSG_DRIVE_LIST_GET_DRIVE_OPTR
	call	ObjMessageCallFixup		; ^lcx:dx = item (or null)
	jmp	short checkChild

DesktopDriveChangeNotify	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopRemovingDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update ToolGroup if removing disk that is providing
		tool libraries

CALLED BY:	MSG_META_REMOVING_DISK

PASS:		ds	= dgroup
		es 	= segment of DesktopClass
		ax	= MSG_META_REMOVING_DISK

		cx	= disk handle of removed disk

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/22/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	INSTALLABLE_TOOLS

DesktopRemovingDisk	method	dynamic	DesktopClass, MSG_META_REMOVING_DISK

	;
	; notify ToolGroup
	;
	push	si
	mov	bx, handle ToolGroup
	mov	si, offset ToolGroup
	mov	ax, MSG_TM_REBUILD_IF_ON_DISK
	call	ObjMessageNone
	pop	si
	;
	; in case superclass needs to do something with it
	;
	mov	di, offset DesktopClass
	GOTO	ObjCallSuperNoLock

DesktopRemovingDisk	endm

endif	; INSTALLABLE_TOOLS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFolderCachingVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _GMGR

InitFolderCachingVars	proc	near
	uses	ax,cx,dx,si,ds
	.enter

	; no folders are opened yet
	mov	ss:[numFiles], 0

	; read the maximum number of folders
	mov	cx, cs
	mov	ds, cx
	mov	si, offset fileManagerString

	mov	dx, offset maxFoldersString
	call	InitFileReadInteger
	jc	setToMaxValueFolders

	cmp	ax, MAX_NUM_FOLDER_WINDOWS
	jle	numFoldersOK

setToMaxValueFolders:
	mov	ax, MAX_NUM_FOLDER_WINDOWS

numFoldersOK:
	cmp	ax, 1
	jge	numFoldersNotNeg

	; don't want to break old code by neg numbers
	mov	ax, 1

numFoldersNotNeg:
	mov	ss:[maxNumFolderWindows], ax

	;
	; now check initialize the max file size
	;
	mov	dx, offset maxFilesString
	call	InitFileReadInteger
	jc	setValueFiles

	cmp	ax, 0
	jge	numFilesOK

setValueFiles:
	clr	ax

numFilesOK:
	mov	ss:[maxNumFiles], ax

	;
	; now check the lru number (max. number in full window mode)
	;
if not _DOCMGR
	mov	dx, offset lruNumberString
	call	InitFileReadInteger
	jc	setDefault

	cmp	ax, MAX_NUM_FOLDER_WINDOWS
	jle	lruNumOK

	;
	; if a very big number was set then it will be reduced the
	; tablesize
	;
	mov	ax, MAX_NUM_FOLDER_WINDOWS
	jmp	lruNumOK

setDefault:
	mov	ax, NUM_LRU_ENTRIES

lruNumOK:
	cmp	ax, 1
	jge	lruNumNotTooSmall

	mov	ax, 1

lruNumNotTooSmall:
	mov	ss:[lruNumber], al
else
	; edigeron 11/1/00 - On systems that have both GeoManager and
	; DocMgr, the two file managers will have different desires for
	; maximum number of open windows. So, just force the DocMgr to
	; use the maximum defined in the source instead of looking at
	; the ini key.
	mov	ss:[lruNumber], NUM_LRU_ENTRIES
endif

	;
	; initilize the isDisplayMizimized variable
	;
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	ObjMessageCall			; carry set if
						; maximized
	jnc	isOverlapping

	mov	ss:[displayIsMaximized], BW_TRUE
	jmp	done

isOverlapping:
	mov	ss:[displayIsMaximized], BW_FALSE

done:
	.leave
	ret
InitFolderCachingVars	endp

fileManagerString	char	"fileManager",0
maxFoldersString	char	"maxOverlappingFolders",0
maxFilesString		char	"maxFiles",0
lruNumberString		char	"maxFullSizedFolders",0

endif	; _GMGR

if GPC_UI_LEVEL_DIALOG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoUILevelDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Raise the UI level dialog if INI tells us it was never
		raised before.  (It's a one-time deal, see?)

CALLED BY:	DesktopOpenApplication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none?

PSEUDO CODE/STRATEGY:
		Read value from INI
		If not true (or not present),
		   Raise dialog
		   Set INI value to TRUE	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter 12/04/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoUILevelDialog	proc	near
		uses	ax,bx,cx,dx,si,di,ds
		.enter
	;
	; Read value from INI.
	;
		mov	ax, cs
		mov	ds, ax
		mov	si, offset getDesktopInitfileCategory
		mov_tr	cx, ax
		mov	dx, offset uiLevelDialogShownKey
		call	InitFileReadBoolean
		jc	raiseIt			; not found, raise it
		tst	ax
		jnz	done			; value is TRUE, leave
raiseIt:
		push	ds, si
	;
	; Raise dialog.
	;
		mov	bx, handle GPCUILevelBox
		mov	si, offset GPCUILevelBox
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
		pop	ds, si
	;
	; Set INI value to TRUE.
	;
		mov	ax, TRUE
		call	InitFileWriteBoolean
done:
		.leave
		ret
DoUILevelDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopChangeUILevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the User Level preference module.

CALLED BY:	MSG_DESKTOP_CHANGE_UI_LEVEL

PASS:		*ds:si	= DesktopClass object
		ds:di	= DesktopClass instance data
		ds:bx	= DesktopClass object (same as *ds:si)
		es 	= segment of DesktopClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything allowed
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter  1/09/01   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
changeLevelAppToken	GeodeToken	<'PMGR', MANUFACTURER_ID_GEOWORKS>
changeLevelDataFile	TCHAR		"User Level Module", 0

DesktopChangeUILevel	method dynamic DesktopClass, 
					MSG_DESKTOP_CHANGE_UI_LEVEL
	;
	; Allocate an AppLaunchBlock for connecting to the app via IACP.
	;
	mov	ax, size AppLaunchBlock
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc		; ^hbx = ax = block
	mov	es, ax
	mov	es:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION

	;
	; Copy the data file name into ALB_dataFile.
	;
	segmov	ds, cs, si
	mov	si, offset changeLevelDataFile	; ds:si = changeLevelDataFile
	mov	di, offset ALB_dataFile	; es:di = ALB_dataFile
		CheckHack <(size changeLevelDataFile and 1) eq 0>
	mov	cx, size changeLevelDataFile / 2
	rep	movsw
	call	MemUnlock

	;
	; Connect to the app via IACP.
	;
	segmov	es, cs, di
	mov	di, offset changeLevelAppToken	; es:di = changeLevelAppToken
	mov	ax, IACPConnectFlags <0, 0, 1, IACPSM_USER_INTERACTIBLE>
	call	IACPConnect		; bp = IACPConnection, CF on error
	jc	done

	;
	; Shut down the connection right away.
	;
	clr	cx			; client shutting down
	call	IACPShutdown
done:
	ret
DesktopChangeUILevel	endm

endif ; GPC_UI_LEVEL_DIALOG


InitCode ends
