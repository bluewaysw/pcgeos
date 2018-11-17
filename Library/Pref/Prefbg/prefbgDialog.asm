COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefbgDialog.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/27/92   	Initial version.

DESCRIPTION:
	

	$Id: prefbgDialog.asm,v 1.1 97/04/05 01:29:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <bgCategory	char	BACKGROUND_CATEGORY,0			>
SBCS <bgKey		char	BACKGROUND_NAME_KEY,0			>
DBCS <bgCategory	wchar	BACKGROUND_CATEGORY,0			>
DBCS <bgKey		wchar	BACKGROUND_NAME_KEY,0			>


COMMENT @----------------------------------------------------------------------

FUNCTION:	PrefBGDialogVisOpen

DESCRIPTION:	set some things up

PASS:		*ds:si - PrefBGDialogClass object		
		es - segment of PrefBGDialogClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

------------------------------------------------------------------------------@
PrefBGDialogVisOpen	method	PrefBGDialogClass, MSG_VIS_OPEN
	uses	ax, bp, si
	.enter

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ClipboardAddToNotificationList	;Get notified when a scrap is
						; added/deleted.


	.leave
	mov	di, offset PrefBGDialogClass
	GOTO	ObjCallSuperNoLock
PrefBGDialogVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGDialogVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the transfer item from the notify list.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefBGDialogVisClose	method	dynamic	PrefBGDialogClass,
				MSG_VIS_CLOSE

	mov	cx, ds:[LMBH_handle]
	mov	dx, offset BackgroundDialog
	call	ClipboardRemoveFromNotificationList

	mov	di, offset PrefBGDialogClass
	GOTO	ObjCallSuperNoLock
PrefBGDialogVisClose	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefBGDialogClass object
		ds:di	= PrefBGDialogClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefBGDialogApply	method	dynamic	PrefBGDialogClass, 
					MSG_GEN_APPLY
	.enter
	
	mov	di, offset PrefBGDialogClass
	call	ObjCallSuperNoLock

	call	ResetField

	.leave
	ret
PrefBGDialogApply	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GoToBackgroundDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go to the background directory.

CALLED BY:	SearchForBackgroundFiles, BackgroundPaste

PASS:		nothing 

RETURN:		carry set if couldn't open directory

DESTROYED:	ax, cx, es, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SBCS <backgroundDir	char	"BACKGRND",0				>
DBCS <backgroundDir	wchar	"BACKGRND",0				>
GoToBackgroundDir	proc	near

		uses 	bx, dx, ds

		.enter

		mov	ax, SP_USER_DATA
		call	FileSetStandardPath

	;
	; See if a local version of the BACKGRND dir exists --
	; otherwise, create it.
	;

		sub	sp, size DirPathInfo
		mov	di, sp
		segmov	es, ss

		segmov	ds, cs
		mov	dx, offset backgroundDir
		mov	ax, FEA_PATH_INFO
		mov	cx, size DirPathInfo
		call	FileGetPathExtAttributes
		pop	ax			; DirPathInfo
		jc	createDir

		test	ax, mask DPI_EXISTS_LOCALLY
		jz	createDir
	;
	; It exists -- go to it.
	;
		clr	bx			;BX <- use current disk handle
		call	FileSetCurrentPath

		jnc	done			
		cmp	ax, ERROR_PATH_NOT_FOUND ;missing directory?
		stc				 ;make sure error is indicated
		je	createDir
done:
		.leave
		ret

createDir:
		call	FileCreateDir
		jc	done
		clr	bx
		call	FileSetCurrentPath
		jmp	done

GoToBackgroundDir	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BackgroundPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles creating a background file from the current scrap.

PASS:		*ds:si - PrefBGDialogClass object

RETURN:		nothing 
DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefBGDialogPaste	method	PrefBGDialogClass, MSG_PREF_BG_DIALOG_PASTE

	call	GoToBackgroundDir
	jnc	continue
	ret
continue:
		
	clr	bp			;Get normal transfer item
	call	ClipboardQueryItem
	tst	bp
	LONG	jz	finishTransfer	;If no scrap, exit
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardTestItemFormat
	jnc	gstringExists
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat
	LONG	jc	finishTransfer	;If no text or gstring scrap, just exit

;	PUT UP A BOX COMPLAINING THAT THERE IS NO GSTRING SCRAP

	push	bx, ax
	mov	bp, offset badPasteString
	call	PutupErrorBox
	jmp	popFinishTransfer

gstringExists:

;	CREATE A BACKGROUND FILE FROM THE PASSED GSTRING

	push	bx, ax
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardRequestItemFormat
EC <	tst	ax							>
EC <	ERROR_Z	NO_GRAPHICS_STRING	;Exit if no gstring scrap	>

;	CREATE GSTRING FROM SCRAP

	push	cx, dx			;Save width/height
	mov_tr	si, ax			;SI <- vmem block handle of gstring
	mov	cx, GST_VMEM
	call	GrLoadGString		;SI <- gstring handle
	pop	cx, dx			;Restore width/height

	; size is unreliable if coming from text layer of text object, compute
	push	ax, bx, di
	clr	di, dx
	call	GrGetGStringBounds
	sub	cx, ax			; cx = width
	sub	dx, bx			; dx = height
	pop	ax, bx, di

	call	PrefBGDialogCreateVMFile		;Creates a VM file with the appropriate

	LONG	jc destroyFinishTransfer ; headers, etc. Exit if error creating
					; the file. Returns BX as VM handle,
	push	si
	push	bx, ax
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	GenCallApplication
	pop	bx, ax

	mov	cx, GST_VMEM
	call	GrCreateGString		;DI <- new gstring to draw to

	; store the HugeArray block handle into the map block
	
	push	bp, ds
	call	VMGetMapBlock		; ax = map block handle
	call	VMLock
	mov	ds, ax
	mov	ds:[FBGMB_data], si	;store data block handle
	call	VMUnlock
	pop	bp, ds	

	pop	si
	push	si			;Save source gstring
	clr	dx			;No control flags
	call	GrCopyGString		;Copy scrap into VM file
	call	GrEndGString		;End the string
	mov	si, di			;SI <- dest gstring
	clr	di			;DI <- GState drawn into (none)
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString	;Destroy the dest gstring
	mov	al, FILE_NO_ERRORS
	call	VMClose			;Close the VM file

;	UPDATE THE .INI FILE TO POINT TO THE NEW/OVERWRITTEN FILE

	sub	sp, FILE_LONGNAME_BUFFER_SIZE
	mov	dx, ss
	mov	bp, sp			;CX:DX <- dest ptr for filename
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	si, offset BackgroundPasteFilename
	call	ObjCallInstanceNoLock
	jcxz	refresh			;Exit if no text (i dunno why)

	call	BackgroundWriteFileName
	call	ResetField
refresh:

	add	sp, FILE_LONGNAME_BUFFER_SIZE

	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	GenCallApplication

	mov	si, offset ChooseBackgroundList
	mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjCallInstanceNoLock

	pop	si			;Restore string to destroy

destroyFinishTransfer:			;Destroy the source gstring and exit...
	mov	dl, GSKT_LEAVE_DATA
	clr	di			;no associated GState
	call	GrDestroyGString
popFinishTransfer:
	pop	bx, ax
finishTransfer:
	call	ClipboardDoneWithItem
	ret
PrefBGDialogPaste	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BackgroundWriteFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the background filename to the .ini file

CALLED BY:	BackgroundPaste

PASS:		dx:bp - pointer to filename

RETURN:		nothing 

DESTROYED:	ax,cx,dx,es,di,si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BackgroundWriteFileName	proc near
	uses	ds

	.enter

	mov	es, dx
	mov	di, bp

   	mov	cx, cs
	mov	ds, cx
	mov	si, offset bgCategory		;DS:SI <- category string
	mov	dx, offset bgKey		;CX:DX <- key string
	call	InitFileWriteString
	call	InitFileCommit

	.leave
	ret
BackgroundWriteFileName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutupErrorBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up an error box

CALLED BY:	GLOBAL
PASS:		BP - handle in strings resource of primary string
		CX:DX - optional secondary string
RETURN:		nada
DESTROYED:	ax, bx, di, bp
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutupErrorBox	proc	near	uses	ds
	.enter

;	LOCK STRINGS RESOURCE

	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
	xchg	di, ax
	mov	bp, ds:[bp]		;DI:BP <- error string
	mov	ax, mask CDBF_SYSTEM_MODAL or CDT_ERROR shl \
			offset CDBF_DIALOG_TYPE or\
			GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
	call	PrefBGUserStandardDialog
	call	MemUnlock

	.leave
	ret
PutupErrorBox	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGUserStandardDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set up params and call UserStandardDialog

CALLED BY:	PutupErrorBox

PASS:		ax - CustomDialogBoxFlags
			(can't be GIT_MULTIPLE_RESPONSE)
		di:bp = error string
		cx:dx = arg 1
		bx:si = arg 2

RETURN:		ax = InteractionCommand response

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefBGUserStandardDialog	proc	far

	; we must push 0 on the stack for SDP_helpContext

	push	bp, bp			;push dummy optr
	mov	bp, sp			;point at it
	mov	ss:[bp].segment, 0
	mov	bp, ss:[bp].offset

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
.assert (offset SDP_customString eq offset SDP_customFlags+2)
.assert (offset SDP_customFlags eq 0)
	push	ax		; save SDP_type, SDP_customFlags
				; params passed on stack
	call	UserStandardDialog
	ret
PrefBGUserStandardDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefBGDialogCreateVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Queries the user for a file name for a VM file. Tries to create
		it. Gives appropriate feedback/errors to the user. Also creates
		the map block and first block of the VM file, so it is ready
		for use by the background-file-creation code.

CALLED BY:	PrefBGDialogPaste

PASS:		cx, dx - width/height of gstring
		ds - segment of objects
		si - gstring handle

RETURN:		ds - fixed up 
		carry set if error/file not created
		else, 
			BX - VM file handle


DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/90	Initial version
       chrisb   10/92		revised

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BackgroundFileToken GeodeToken <<'B','K','G','D'>,MANUFACTURER_ID_GEOWORKS>
BackgroundFileProtocol ProtocolNumber <BG_PROTO_MAJOR, BG_PROTO_MINOR>

PrefBGDialogCreateVMFile	proc	near	

	uses	si

stringWidth	local	word	push	cx
stringHeight	local	word	push	dx
gstring		local	hptr	push	si
filename	local	FileLongName

	.enter

getFilename:
	mov	bx, ds:[LMBH_handle]
	push	bx

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	si, offset BackgroundPasteFilename
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset BackgroundPasteGetFilenameBox
	call	UserDoDialog
	pop	bx
	call	MemDerefDS

	cmp	ax, IC_OK
LONG	jne	errorExit	;If the user cancelled, exit...

;	GET THE USER'S FILENAME

	push	bp
	mov	dx, ss
	lea	bp, ss:[filename]
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	si, offset BackgroundPasteFilename
	call	ObjCallInstanceNoLock
	pop	bp

	tst	cx
LONG	jz	noFilename

	push	ds
	segmov	ds, ss			;DS:DX <- ptr to filename
	lea	dx, ss:[filename]
	mov	ax, (VMO_CREATE_ONLY shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx			;Default compression
 	call	VMOpen
	pop	ds

	jc	diskerror		;Branch if error
openOK:

; 	SET FILE ATTRIBUTES

	mov	ax, FEA_TOKEN
	segmov	es, cs, di
	mov	di, offset BackgroundFileToken
	mov	cx, size BackgroundFileToken
	call	FileSetHandleExtAttributes

	mov	di, offset BackgroundFileProtocol
	mov	cx, size BackgroundFileProtocol
	mov	ax, FEA_PROTOCOL
	call	FileSetHandleExtAttributes

;	CREATE MAP BLOCK, ETC. FOR NEW FILE

	push	ds				; UI objects
	clr	ax
	mov	cx, size FieldBGMapBlock
	call	VMAlloc
	call	VMSetMapBlock
	mov	cx, ss:[stringWidth]
	mov	dx, ss:[stringHeight]
	mov	si, ss:[gstring]

	push	bp
	call	VMLock				; bp - vm mem handle
	mov	ds, ax

	call	VMDirty				;Set map block dirty
	mov	ds:[FBGMB_width], cx
	mov	ds:[FBGMB_height], dx

	push	bx				; vm file handle
	clr	di, dx
	call	GrGetGStringBounds
	mov	ds:[FBGMB_xOffset], ax
	mov	ds:[FBGMB_yOffset], bx
	pop	bx

	mov	ds:[FBGMB_type], FBGFT_STANDARD_GSTRING
	mov	ds:[FBGMB_data], 0	;no data block yet
	call	VMUnlock
	pop	bp
	pop	ds			; UI objects

	clc				
	jmp	exit

diskerror:

;	SOME KIND OF DISK ERROR WAS ENCOUNTERED

	cmp	ax, VM_SHARING_DENIED
	je	tryOverwrite
	cmp	ax, VM_FILE_EXISTS	;Did the file exist?
	jnz	noOverwrite		;Branch if other error...

tryOverwrite:

	; THE FILE EXISTS. ASK THE USER IF HE WANTS TO OVERWRITE IT

	push	ds, bp
	mov	bx, handle overwriteString
	call	MemLock
	mov	cx, ss			;CX:DX <- filename
	mov	ds, ax
	xchg	di, ax
	assume ds:Strings
	mov	bp, ds:[overwriteString];DI:BP <- error string.
	assume ds:dgroup
	mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE
	call	PrefBGUserStandardDialog
	call	MemUnlock
	pop	ds, bp

	cmp	ax, IC_YES
	je	overwriteFile		;If no overwrite, get new filename
	cmp	ax, IC_NO
	jnz	errorExit		;If detaching, just exit
	jmp	getFilename		;Else, get a new filename

overwriteFile:
	call	OverwriteVMFile		;Try to overwrite the VM file
LONG	jnc	openOK

noOverwrite:
	push	bp
	mov	bp, offset sharingDeniedString
	cmp	ax, VM_SHARING_DENIED
	je	gotString
	mov	bp, offset fullDiskString
	cmp	ax, ERROR_SHORT_READ_WRITE	;Is it disk full?
	je	gotString
	mov	bp, offset dosErrorString

gotString:
	call	PutupErrorBox			;Putup the error.
	pop	bp

errorExit:
	stc					;Signify error
exit:
	.leave
	ret

noFilename:
	push	bp
	mov	bp, offset noFilenameString
	call	PutupErrorBox
	pop	bp

	jmp	getFilename
PrefBGDialogCreateVMFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OverwriteVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to overwrite the passed VM file...

CALLED BY:	GLOBAL

PASS:		SS:DX <- ptr to filename
		ds - segment of UI objects

RETURN:		carry set if couldn't overwrite, AX <- file error
		else, bx <- VM file handle
	
DESTROYED:	assume everything
 
PSEUDO CODE/STRATEGY:
	Try to overwrite the file
	If VM_SHARING_DENIED error {
		Check to see if the current BG is this file
		If not
			return VM_SHARING_DENIED error
		else
			reset the current BG so the file won't be in use
			try to open the file again
	}
	return any error


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OverwriteVMFile	proc	near

passedFilename	local	nptr	push	dx
uiHandle	local	hptr	push	ds:[LMBH_handle]
initFileName	local	FileLongName

	.enter


;	OVERWRITE THE FILE

	segmov	ds, ss
	mov	ax, (VMO_CREATE_TRUNCATE shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx			;Default compression
	call	VMOpen			;
	jnc	exit		;If we truncated the file OK, branch...
	cmp	ax, VM_SHARING_DENIED	;
	jne	errorExit		;

;	IF THE BG FILE IS ALREADY OPENED BY THE FIELD, RESET THE FIELD AND TRY
;	TO OPEN IT AGAIN...

	push	bp
	segmov	es, ss	
	mov	cx, cs
	mov	ds, cx
	mov	si, offset bgCategory
	mov	dx, offset bgKey	;CX:DX <- key string
	lea	di, ss:[initFileName]
	mov	bp, size initFileName
	call	InitFileReadString
	pop	bp

	jc	noMatch			;If no bg selected, exit
	jcxz	noMatch
					;ES:DI <- filename in init file

	segmov	ds, ss			; ds:si - passed filename
	mov	si, ss:[passedFilename]

	clr	cx
	call	LocalCmpStrings
	jne	noMatch

	;
	; Set none selected in the choose background list, so that the
	; field closes the currently open background file
	;

	mov	bx, ss:[uiHandle]
	call	MemDerefDS

	push	bp
	mov	si, offset ChooseBackgroundList
	clr	cx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_SAVE_OPTIONS
	call	ObjCallInstanceNoLock
	pop	bp

	call	ResetField

	mov	dx, ss:[passedFilename]
	segmov	ds, ss			;DS:DX <- ptr to filename
	mov	ax, (VMO_CREATE_TRUNCATE shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx			;Default compression
	call	VMOpen			;
	jmp	exit			;Return any error

noMatch:
	mov	ax, VM_SHARING_DENIED
errorExit:
	stc
exit:
	;
	; Fixup DS before exiting
	;

	push	bx
	mov	bx, ss:[uiHandle]
	call	MemDerefDS
	pop	bx
	.leave
	ret
OverwriteVMFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BackgroundTransferNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out when the current clipboard contents change.
		We check to see if there are TEXT or GSTRING contents, and 
		if not, we disable the paste trigger.

CALLED BY:	GLOBAL
PASS:		*ds:si - PrefBGDialogClass object

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 9/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BackgroundTransferNotify	method	PrefBGDialogClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

	clr	bp			;Get normal transfer item
	call	ClipboardQueryItem
	tst	bp
	jz	setTriggerNotEnabled

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardTestItemFormat

	mov	bp, MSG_GEN_SET_ENABLED
	jnc	setTrigger
	mov	dx, CIF_TEXT
	call	ClipboardTestItemFormat

	jnc	setTrigger

setTriggerNotEnabled:
	mov	bp, MSG_GEN_SET_NOT_ENABLED	

setTrigger:
	call	ClipboardDoneWithItem
	mov_tr	ax, bp
	mov	si, offset BackgroundPasteTrigger
	mov	dl, VUM_NOW
	GOTO	ObjCallInstanceNoLock

BackgroundTransferNotify	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the field reset itself

CALLED BY:	BackgroundPaste

PASS:		ds - segment of UI objects

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Send a message to the field to have it re-scan the .INI file

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetField	proc near
	uses	ax, cx, dx, bp, si
	.enter

	;
	; Create a message to send to the field
	;

	mov	ax, MSG_GEN_FIELD_RESET_BG
	mov	bx, segment GenFieldClass	; method is for GenField
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle

	;
	; Call the app to send it there
	;

	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallApplication

	.leave
	ret
ResetField	endp

