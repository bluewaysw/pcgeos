COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Main
FILE:		mainProcess.asm

ROUTINES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/89		Initial version

DESCRIPTION:
	Misc routines

	$Id: cmainProcess.asm,v 1.2 98/06/03 13:44:56 joon Exp $

------------------------------------------------------------------------------@

UtilCode	segment resource

if _NEWDESK

COMMENT @----------------------------------------------------------------------

MESSAGE:	DesktopCancelOptions -- MSG_DESKTOP_CANCEL_OPTIONS
							for DesktopClass

DESCRIPTION:	Rset the options

PASS:
	*ds:si - instance data
	es - segment of DesktopClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/28/93		Initial version

------------------------------------------------------------------------------@
DesktopCancelOptions	method dynamic	DesktopClass, MSG_DESKTOP_CANCEL_OPTIONS

	; see if there are any options saved

	segmov	ds, cs
	lea	si, newdeskbaString			;dssi = category
	mov	cx, cs
	lea	dx, warningsString
	call	InitFileReadInteger
	jc	noOptionsSaved

	; options are saved

	mov	ax, MSG_META_LOAD_OPTIONS
	mov	bx, handle OptionsMenu
	mov	si, offset OptionsMenu
	clr	di
	GOTO	ObjMessage

noOptionsSaved:
	FALL_THRU	DesktopResetOptions

DesktopCancelOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DesktopResetOptions -- MSG_DESKTOP_RESET_OPTIONS
							for DesktopClass

DESCRIPTION:	Rset the options

PASS:
	*ds:si - instance data
	es - segment of DesktopClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/28/93		Initial version

------------------------------------------------------------------------------@
DesktopResetOptions	method DesktopClass, MSG_DESKTOP_RESET_OPTIONS

if 0
	; delete the category

	segmov	ds, cs
	lea	si, newdeskbaString			;dssi = category
	call	InitFileDeleteCategory
endif

	; and reset stuff

	; stuff default values

	mov	bx, handle FileDeleteOptionsGroup
	mov	si, offset FileDeleteOptionsGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, OCDL_FULL
	clr	dx
	call	sendMessage
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	sendMessage
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	sendMessage
	mov	ax, MSG_GEN_APPLY
	call	sendMessage

	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	cx, mask OMI_CONFIRM_EMPTY_WB or mask OMI_CONFIRM_READ_ONLY or \
		    mask OMI_CONFIRM_REPLACE or mask OMI_CONFIRM_EXECUTABLE or \
		    mask OMI_ASK_BEFORE_RETURNING
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	sendMessage
	mov	cx, mask OptionsMenuItems
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	sendMessage
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
	call	sendMessage
	mov	ax, MSG_GEN_APPLY
	call	sendMessage

	ret

;---

sendMessage:
	clr	di
	call	ObjMessage
	retn

DesktopResetOptions	endm

warningsString	char	"warnings", 0
newdeskbaString	char	"fileManager", 0
endif

if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopRunIclasBatchFileIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Way of forcing thing on the queue.  See called
		routine for details.

CALLED BY:	MSG_DESKTOP_RUN_ICLAS_BATCH_FILE_IF_NEEDED
PASS:		*ds:si	= BAApplicationClass object
		ds:di	= BAApplicationClass instance data
		ds:bx	= BAApplicationClass object (same as *ds:si)
		es 	= segment of BAApplicationClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	2/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BAAppRunIclasBatchFileIfNeeded	method dynamic DesktopClass,
				MSG_BA_APP_RUN_ICLAS_BATCH_FILE_IF_NEEDED
	uses	ax, cx, dx, bp
	.enter
		call	IclasRunSpecialBatchFileIfNeeded
	.leave
	ret
BAAppRunIclasBatchFileIfNeeded	endm
endif		; _NEWDESKBA


if _DOS_LAUNCHERS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopHandleCreateOrEditLauncher
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	DOS:Create Launcher or DOS:Edit Launcher was selected

CALLED BY:	MSG_CREATE_DOS_LAUNCHER, MSG_EDIT_DOS_LAUNCHER

PASS:		es - segment of DesktopClass

RETURN:		none

DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwn	06/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopHandleCreateOrEditLauncher	method DesktopClass,
					MSG_CREATE_DOS_LAUNCHER, 
					MSG_EDIT_DOS_LAUNCHER
	.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	mov	es:[creatingLauncher], 1
	cmp	ax, MSG_CREATE_DOS_LAUNCHER
	je	gotCreateEdit
	mov	es:[creatingLauncher], 0

gotCreateEdit:
	mov	bx, ss:[targetFolder]		; bx:si = target folder object
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	tst	bx				; check if any target
	jz	noFolder

	call	ObjMessageCall			; send to folder object
	jmp	done

	; don't check tree, because tree window can't select files.
noFolder:
	cmp	ax, MSG_CREATE_DOS_LAUNCHER
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	bx, handle GetCreateLauncherFileBoxSelectTrigger
	mov	si, offset GetCreateLauncherFileBoxSelectTrigger
	mov	cx, handle GetCreateLauncherFileBox
	mov	dx, offset GetCreateLauncherFileBox	; default to create
	je	sendIt

	mov	bx, handle GetEditLauncherFileBoxSelectTrigger
	mov	si, offset GetEditLauncherFileBoxSelectTrigger
	mov	cx, handle GetEditLauncherFileBox	; ...else edit
	mov	dx, offset GetEditLauncherFileBox
sendIt:
	push	cx, dx
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjMessageCall

	pop	bx, si
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageForce
done:
	.leave
	ret
DesktopHandleCreateOrEditLauncher	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopCreateEditFileSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user hit OK on either the Create File Selector or Edit
		File Selector.

CALLED BY:	MSG_DOS_LAUNCHER_FILE_SELECTED

PASS:		none

RETURN:		none

DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwn	06/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopCreateEditFileSelected	method DesktopClass,
						MSG_DOS_LAUNCHER_FILE_SELECTED
	.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	sub	sp, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE
	mov	cx, ss
	mov	dx, sp				; copy into stack buffer
	mov	bx, handle CreateLauncherFileSelector
	mov	si, offset CreateLauncherFileSelector
	cmp	es:[creatingLauncher], 0
	jne	gotObject
	mov	bx, handle EditLauncherFileSelector
	mov	si, offset EditLauncherFileSelector
gotObject:
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	call	ObjMessageCall

	mov	di, dx
	mov	bx, ax				; put diskhandle in bx
	clr	ax
	mov	cx, -1
	LocalFindChar				; go to end of string
	not	cx				; get length to cx
	LocalPrevChar esdi			; point es:di to null
	mov	si, di				; si points to null at end
	std					; reverse direction flag
	LocalLoadChar ax, C_BACKSLASH		; find last '\\'
	LocalFindChar
	cld					; clear direction flag
	mov	ax, bx				; restore diskhandle to ax
	mov	bx, si				; point path to null at end
	jne	gotFileNameStart
	LocalNextChar esdi
SBCS <	mov	{byte} es:[di], 0		; replace '\\' with null >
DBCS <	mov	{wchar} es:[di], 0		; replace '\\' with null >
	mov	bx, sp				; sp points to path start
gotFileNameStart:
	LocalNextChar esdi
	mov	si, di
	mov	bp, di				; save this in bp
	segmov	ds, es, di			; ds:si = name, es:di = idata
	mov	di, offset launcherGeosName
	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2
	rep	movsw				; copy into idata
	mov	si, bp				; reset
	mov	di, offset launchFileName
	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2
	rep	movsw				; copy into idata

	call	DOSLauncherFileSelected		; pass ax, ds:bx as path
	add	sp, PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE

	.leave
	ret
DesktopCreateEditFileSelected	endm
endif			; _DOS_LAUNCHERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopRemoteErrorBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up error box for UI thread.

CALLED BY:	MSG_REMOTE_ERROR_BOX

PASS:		cx - error code

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopRemoteErrorBox	method	DesktopClass, MSG_REMOTE_ERROR_BOX
	mov	ax, cx				; pass error code in ax
	call	DesktopOKError			; do regular error box
	ret
DesktopRemoteErrorBox	endp


UtilCode	ends


if _ICON_AREA
ToolCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopShowDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts the drive buttons on the Toolbar at the bottom of
		Desktop's primary

CALLED BY:	DesktopSetDriveLocation

PASS:		none
RETURN:		none
DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	06/09/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopShowDrives	proc	near
	.enter

	call	ShowHourglass

	mov	cl, DRIVES_SHOWING
	mov	ax, MSG_TA_SET_DRIVE_LOCATION
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall				; dismiss dialog

	mov	ax, MSG_TA_MOVE_DRIVE_TOOLS
	mov	cx, handle IconArea
	mov	dx, offset IconArea			; destination
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog		; source
	call	ObjMessageCall

	call	HideHourglass

	.leave
	ret
DesktopShowDrives	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopFloatHideDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If cx = DRIVES_FLOATING
			Puts the drive buttons into a floating dialog and
			initiates it

		If cx = DRIVES_HIDDEN
			Hides the drive buttons from view by putting them
			into a floating dialog and NOT initating it.

		if cx = DRIVES_SHOWING
			call DesktopShowDrives to put the drives back in the
			ToolArea.

CALLED BY:	MSG_SET_DRIVES_LOCATION

PASS:		none
RETURN:		none
DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	06/09/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopSetDrivesLocation	method DesktopClass, MSG_SET_DRIVES_LOCATION
	.enter

	call	ShowHourglass

	cmp	cx, DRIVES_SHOWING
	jne	notDrivesShowing

	call	DesktopShowDrives
	jmp	exit

notDrivesShowing:
	push	cx				; new location

	mov	ax, MSG_TA_GET_DRIVE_LOCATION
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall
	cmp	cl, DRIVES_SHOWING
	jne	alreadyDialog

	mov	ax, MSG_TA_MOVE_DRIVE_TOOLS
	mov	cx, handle FloatingDrivesDialog
	mov	dx, offset FloatingDrivesDialog		; destination
	mov	bx, handle IconArea
	mov	si, offset IconArea			; source
	call	ObjMessageCall

alreadyDialog:
	pop	cx					; pop new location
	cmp	cx, DRIVES_FLOATING
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	je	gotMessage
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
gotMessage:
	push	cx					; save location
	mov	cx, IC_DISMISS				; if it was floating...
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall

	pop	cx					; restore location
	mov	ax, MSG_TA_SET_DRIVE_LOCATION
	mov	bx, handle FloatingDrivesDialog
	mov	si, offset FloatingDrivesDialog
	call	ObjMessageCall

exit:
	call	HideHourglass

	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication

	.leave
	ret
DesktopSetDrivesLocation	endm


if _PREFERENCES_LAUNCH


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopLaunchPreferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch PrefMgr

PASS:		
		ds - dgroup of class
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
	srs	9/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
prefFileName char "Preferences",0
prefToken GeodeToken <<"PMGR">,MANUFACTURER_ID_GEOWORKS>

DesktopLaunchPreferences	method dynamic DesktopClass, 
						MSG_DESKTOP_LAUNCH_PREFERENCES
	.enter

	mov	dx,MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
	jc	done

	;    Create LoadAppData block
	;

	mov	cx, mask HAF_LOCK shl 8
	mov	ax,size LoadAppData
	call	MemAlloc
	jc	destroyAppLaunchBlock

	;   Copy file name and token to LoadAppData block
	;

	mov	es,ax
	segmov	ds,cs
	mov	di,offset LAD_file
	mov	si,offset prefFileName
	mov	cx,size prefFileName
	rep	movsb
	mov	di,offset LAD_token
	mov	si,offset prefToken
	mov	cx,size prefToken
	rep	movsb

	call	MemUnlock			;LoadAppData block
	mov	cx,bx				;LoadAppData block

	;    Use MF_FORCE_QUEUE so that this code segment isn't locked
	;    when the application launches.
	;

	mov	bx,handle 0
	mov	di,mask MF_FORCE_QUEUE
	mov	ax,MSG_DESKTOP_LOAD_APPLICATION
	call	ObjMessage

done:
	.leave
	ret

destroyAppLaunchBlock:
	mov	bx,dx
	call	MemFree
	jmp	done

DesktopLaunchPreferences		endm
endif


ToolCode	ends	
endif		; _ICON_AREA


if _PEN_BASED

PseudoResident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopAbortQuickTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Easy way to abort quick-transfer on process thread.

CALLED BY:	MSG_DESKTOP_ABORT_QUICK_TRANSFER

PASS:		ds	= dgroup
		es 	= segment of DesktopClass
		ax	= MSG_DESKTOP_ABORT_QUICK_TRANSFER

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/24/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopAbortQuickTransfer	method	dynamic	DesktopClass,
					MSG_DESKTOP_ABORT_QUICK_TRANSFER
EC <	ECCheckDGroup	ds						>
	mov	ds:[fileDragging], 0
	mov	ds:[delayedFileDraggingEnd], BB_FALSE
	xor	bx, bx				; return END_OTHER
						; (carry clear - don't check
						;	quick-transfer status)
	call	ClipboardHandleEndMoveCopy
	ret
DesktopAbortQuickTransfer	endm


PseudoResident	ends

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopLaunchFromToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch app from token

PASS:		
		ds - dgroup of class
		es - segment of DesktopClass
		cxdx - token chars
		bp - manuf ID

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
	srs	9/28/93   	Initial version
	brianc	1/22/98		adapted for general launching

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0
if _DOCMGR or GPC_SIGN_UP_ICON

UtilCode	segment	resource

launchFromTokenProgram	TCHAR	"Program",0

DesktopLaunchFromToken	method dynamic DesktopClass, 
						MSG_DESKTOP_LAUNCH_FROM_TOKEN
tokenHigh	local	word	push	cx
tokenLow	local	word	push	dx
	.enter

	mov	dx,MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
	jc	done

	;    Create LoadAppData block
	;

	mov	cx, mask HAF_LOCK shl 8 or mask HF_SWAPABLE
	mov	ax,size LoadAppData
	call	MemAlloc
	jc	destroyAppLaunchBlock

	;   Copy file name and token to LoadAppData block
	;

	mov	es,ax
	segmov	ds,SEGMENT_CS
	mov	di,offset LAD_file
	mov	si,offset launchFromTokenProgram
	mov	cx,size launchFromTokenProgram
	rep	movsb
	mov	ax, tokenHigh
	mov	{word}es:[LAD_token].GT_chars[0], ax
	mov	ax, tokenLow
	mov	{word}es:[LAD_token].GT_chars[2], ax
	mov	ax, ss:[bp]			; passed BP
	mov	{word}es:[LAD_token].GT_manufID, ax

	call	MemUnlock			;LoadAppData block
	mov	cx,bx				;LoadAppData block

	;    Use MF_FORCE_QUEUE so that this code segment isn't locked
	;    when the application launches.
	;

	mov	bx,handle 0
	mov	di,mask MF_FORCE_QUEUE
	mov	ax,MSG_DESKTOP_LOAD_APPLICATION
	call	ObjMessage

done:
	.leave
	ret

destroyAppLaunchBlock:
	mov	bx,dx
	call	MemFree
	jmp	done

DesktopLaunchFromToken		endm

UtilCode	ends

endif  ; _DOCMGR or GPC_SIGN_UP_ICON
endif
