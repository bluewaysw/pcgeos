COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS	
MODULE:		ResEdit/Main
FILE:		mainProcess.asm

AUTHOR:		Cassie Hartzog, Sep 25, 1992

ROUTINES:
	Name			Description
	----			-----------
	MainProcessOpenApplication	The application is opening. Do some 
				preliminary setup work. 
	SetupFileSelector	Set the default directory for the file 
				selector. 
	MainProcessMetaVmFileDirty	Don't pass this message up if we're in 
				batch mode. 
	MainProcessCloseApplication	Application is closing, remove it from 
				gcnlist. 
	MainProcessGetRestoringFromState	Tell whether or not restoring 
				from state. 
	GCNCommon		send a gcnlist ADD or REMOVE message 
	ResEditProcessClipboard	Pass clipboard events on to app target. 
	ProcessSetSourcePath	Change the top-level source path. 
	ProcessSetDestinationPath	Change the top-level destination path. 
	SaveFileSelectorPath	Save the FileSelector's path in the .ini file. 
	ResEditApplicationUpdatePrintUI	An object has either opened or closed. 
	REASetBatchMode		Sets whether a batch process is being run (so 
				that screen updates can be supressed). 
	REAGetBatchMode		Returns whether a batch process is being run 
				(so that screen updates can be supressed). 
	REAEndBatch		Turn off batch mode and put up the New/Open 
				dialog. 
	REACancelBatch		Cancel an in-progress batch job. 
	SetBatchMode		Turn on or off batch mode. 
	IsBatchMode		Sets the carry flag if we're in batch mode. 
	IsBatchModeCancelled	Sets the carry flag if the user has cancelled 
				the batch job. 
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CH	9/25/92		Initial revision


DESCRIPTION:
	Code for ResEditProcess and ResEditApplication class.
	
	$Id: mainProcess.asm,v 1.1 97/04/04 17:13:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata 	segment
    ResEditProcessClass		mask CLASSF_NEVER_SAVED
    ResEditApplicationClass

idata	ends

udata	segment
    restoringFromState		BooleanByte (?)
udata	ends

MainProcessCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The application is opening.  Do some preliminary setup work.

CALLED BY:	UI - MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message
		cx	- AppAttachFlags
		dx	- handle of AppLaunchBlock
		bp 	- handle of extra state block

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainProcessOpenApplication		method dynamic ResEditProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION

	push	cx
	mov	di, offset ResEditProcessClass
	call	ObjCallSuperNoLock
	pop	cx

	; Start with batch processing mode off.

	mov	al, BM_OFF	
	call	SetBatchMode

	; Add ResEditApp to the text select state change GCNList
	; so it can tell the document whenever text is selected or
	; deselected and the Edit menu can be updated properly.
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	call	GCNCommon

	; if restoring from state, don't change anything
	;
	mov	es:[restoringFromState], BB_TRUE	;assume restoring
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	done
	mov	es:[restoringFromState], BB_FALSE	;we're not restoring

	call	FilePushDir

	; Initialize the new/open file selector in the APPLICATION directory
	; 
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset NewFileSelector
	clr	di
	mov	ax, SP_TOP
	mov	dx, offset NewFileKey
	call	SetupFileSelector

	; Initialize creation of new executables in the DOCUMENT directory
	;
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset DestFileSelector
	mov	di, offset DestFileCurrentPath
	mov	ax, SP_DOCUMENT
	mov	dx, offset DestinationKey
	call	SetupFileSelector

	; Initialize the top-level source directory
	;
	mov	si, offset SourceFileSelector
	mov	di, offset SourceFileCurrentPath
	mov	ax, SP_TOP
	mov	dx, offset SourceKey
	call	SetupFileSelector

	; Initialize the ResetSource directory to be the same
	; as the top-level source directory.
	;
	mov	si, offset ResetSourcePathSelector
	clr	di
	mov	ax, SP_TOP
	mov	dx, offset SourceKey
	call	SetupFileSelector

	; Turn on or off advanced features (patch files, NULL geodes)
	;
	call	EnableDisableAdvancedFeatures

	call	FilePopDir
done:
	ret
MainProcessOpenApplication		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default directory for the file selector.

CALLED BY:	MainProcessOpenApplication

PASS:		ax	- StandardPath to use if no .ini file setting
		^ldx	- .ini key to look for directory in
		^lbx:si	- FileSelector
		^lbx:di	- GenGlyph holding path (if one defined)

RETURN:		nothing

DESTROYED:	ax, cx, dx, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/22/92	Initial version
	Don	9/9/00		Improved user feedback on path settings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <defaultSelection	char	'.', 0					>
DBCS <defaultSelection	wchar	'.', 0					>

SetupFileSelector		proc	near
	uses	bx,bp,si,di
	.enter
	
	push	di				; save GenGlyph chunk
	push	bx, si				; save GenFileSelctor

	push	ax
	mov	si, dx
	GetResourceHandleNS	StringsUI, bx
	call	MemLock
	mov	ds, ax
	mov	dx, ds:[si]			; ds:si <- key string
	mov	cx, ds				; cx:dx <- key string
	pop	ax
	mov	si, offset CategoryString	
	mov	si, ds:[si]			; ds:si <- category string

	clr	bp				; allocate a block
	call	InitFileReadString		; ^hbx <- contains dest path
	jnc	haveIniKey
	clr	bx				; there is no block to free

haveIniKey:
	; if there is no block containing a pathname use the 
	; StandardPath passed in ax, with no relative path.
	;
	mov	cx, ds
	mov	bp, offset NullPath		
	mov	dx, ds:[bp]			; cx:dx <- empty path string
	mov	bp, ax				; bp <- StandardPath
	tst	bx				; any path in .ini file?
	jz	setPath				; no, use StandardPath
	;
	; else use the pathname from the ini file
	;
	call	MemLock
	mov	cx, ax
	clr	dx				; cx:dx <- pathname
	clr	bp				; use current disk handle

setPath:
	; Tell the GenFileSelector to set its path. Also need to set
	; the selection, so that MSG_G_F_S_GET_FULL_SELECTION_PATH
	; will always yield meaningful results -Don 9/9/00
	;
	mov	ax, bx
	pop	bx, si
	push	ax				; save the block handle
	mov	ax, MSG_GEN_PATH_SET
        mov	di, mask MF_CALL or mask MF_FIXUP_DS
        call    ObjMessage			; carry set if path invalid

	mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
	mov	cx, cs
	mov	dx, offset defaultSelection
        mov	di, mask MF_CALL or mask MF_FIXUP_DS
        call    ObjMessage			; carry set if path invalid

	pop	ax				; ^hax <- body string block

	; Display the path in a more user-friendly manner
	;
	pop	di				; restore GenGlyph chunk
	tst	ax
	jz	done				; no path pre-defined, so done
	tst	di
	jz	freePathBlock			; no chunk, so free memory
	push	ax
	call	DisplayUserFriendlyPath
	pop	ax
freePathBlock:
	mov_tr	bx, ax
	call	MemFree	

done:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	.leave
	ret
SetupFileSelector		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableDisableAdvancedFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable advanced features (currently just
		things having to do with patch files)

CALLED BY:	MainProcessOpenApplication

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, bp, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		By default all features are assumed to be turned ON,
		so this routine only does something if instructed
		to turn a feature OFF.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/9/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

categoryString		char	"resedit", 0
patchFeatureKey		char	"patchFiles", 0

EnableDisableAdvancedFeatures		proc	near
		.enter
	;
	; Let's check for support of patch files
	;
		segmov	ds, cs, cx
		mov	si, offset categoryString	; ds:si <- category
		mov	dx, offset patchFeatureKey
		mov	ax, TRUE			; assume features ON
		call	InitFileReadBoolean
		cmp	ax, TRUE
		je	done
	;
	; OK - time to turn off the advance features
	;
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset FileMenuUI:CreatePatchTrigger
		call	disableUI
		mov	si, offset FileMenuUI:CreateNullPatchTrigger
		call	disableUI
		mov	si, offset FileMenuUI:ResEditBatchOptionPatchFiles
		call	disableUI
		mov	si, offset FileMenuUI:ResEditBatchOptionPatchAndNull
		call	disableUI
done:
		.leave
		ret
	;
	; Set a single UI object not usable
	;
disableUI:
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		call	ObjMessage
		retn
EnableDisableAdvancedFeatures		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainProcessMetaVmFileDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't pass this message up if we're in batch mode, since we
		don't want the changes "committed" when we close the
		document.

CALLED BY:	MSG_META_VM_FILE_DIRTY
PASS:		*ds:si	= ResEditProcessClass object
		ds:di	= ResEditProcessClass instance data
		ds:bx	= ResEditProcessClass object (same as *ds:si)
		es 	= segment of ResEditProcessClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	9/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainProcessMetaVmFileDirty	method dynamic ResEditProcessClass, 
					MSG_META_VM_FILE_DIRTY
		.enter

	; Is batch mode on?

		call	IsBatchMode
		jc	done

	; Okay, we can call the superclass.
	
		mov	di, offset ResEditProcessClass
		call	ObjCallSuperNoLock

done:
		.leave
		ret
MainProcessMetaVmFileDirty	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Application is closing, remove it from gcnlist.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainProcessCloseApplication		method dynamic ResEditProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	; Remove ResEdit from the text select state change GCNList.
	;
        mov     ax, MSG_META_GCN_LIST_REMOVE
        call    GCNCommon

	clr	cx				; no extra state block
	ret
MainProcessCloseApplication		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MainProcessGetRestoringFromState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell whether or not restoring from state.

CALLED BY:	MSG_RESEDIT_GET_RESTORING_FROM_STATE,
		AttachUIToDocument

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message
RETURN:		al - BB_TRUE if restoring from state, BB_FALSE if not
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
	Restoring from state applies only to the first call from 
	AttachUIToDocument.  Subsequent attach's will want clean UI.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainProcessGetRestoringFromState	method dynamic ResEditProcessClass,
					MSG_RESEDIT_GET_RESTORING_FROM_STATE
	mov	al, es:[restoringFromState]
	mov	es:[restoringFromState], BB_FALSE
	ret
MainProcessGetRestoringFromState		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCNCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send a gcnlist ADD or REMOVE message

CALLED BY:	MainProcessOpenApplication, MainProcessCloseApplication
PASS:		ax	- MSG_META_GCN_LIST message
RETURN:		nothing
DESTROYED:	bx,di,bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCNCommon		proc	near
	uses	cx,si
	.enter

     	mov     dx, size GCNListParams
        sub     sp, dx
        mov     bp, sp
        mov     ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
        mov     ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	clr	bx
	call	GeodeGetAppObject
        movdw   ss:[bp].GCNLP_optr, bxsi
        mov     ax, MSG_META_GCN_LIST_ADD
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
        add     sp, size GCNListParams

	.leave
	ret
GCNCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditProcessClipboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass clipboard events on to app target.

CALLED BY:	UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message

RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/27/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditProcessClipboard		method dynamic ResEditProcessClass,
		MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED

	push	si, es
	GetResourceSegmentNS	ResEditDocumentClass, es
	mov	bx, es
	mov	si, offset  ResEditDocumentClass	
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si, es

	mov	cx, di
	mov	dx, TO_APP_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLock

	ret
ResEditProcessClipboard		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessSetSourcePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the top-level source path.

CALLED BY:	MSG_RESEDIT_SET_SOURCE_PATH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assumes SourceFileInteraction DB is still up when
		this routine is called. If completed successfully,
		the DB will be brought down.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessSetSourcePath		method dynamic ResEditProcessClass,
				MSG_RESEDIT_SET_SOURCE_PATH

	; Save the top-level source path in the .ini file
	;
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset SourceFileSelector
	mov	di, offset SourceFileCurrentPath
	mov	cx, offset SourceKey
	call	SaveFileSelectorPath
	jc	error

	; No error - dismiss dialog box
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset SourceFileInteraction
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	ret

error:
	call	DisplayErrorString
	jmp	done		
ProcessSetSourcePath		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessResetSourcePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the top-level source path.

CALLED BY:	MSG_RESEDIT_RESET_SOURCE_PATH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/9/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessResetSourcePath		method dynamic ResEditProcessClass,
				MSG_RESEDIT_RESET_SOURCE_PATH

	; Reload the default source path
	;
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset SourceFileSelector
	mov	di, offset SourceFileCurrentPath
	mov	ax, SP_TOP
	mov	dx, offset SourceKey
	call	SetupFileSelector

	ret
ProcessResetSourcePath		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessSetDestinationPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the top-level destination path.

CALLED BY:	MSG_RESEDIT_SET_DESTINATION_PATH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assumes DestFileInteraction DB is still up when
		this routine is called. If completed successfully,
		the DB will be brought down.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessSetDestinationPath		method dynamic ResEditProcessClass,
				MSG_RESEDIT_SET_DESTINATION_PATH

	; Save the top-level destination path in the .ini file
	;
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset DestFileSelector
	mov	di, offset DestFileCurrentPath
	mov	cx, offset DestinationKey
	call	SaveFileSelectorPath
	jc	error

	; No error - dismiss dialog box
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset DestFileInteraction
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	ret

error:
	call	DisplayErrorString
	jmp	done		
ProcessSetDestinationPath		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessResetDestinationPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the top-level destination path.

CALLED BY:	MSG_RESEDIT_RESET_DESTINATION_PATH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditProcessClass
		ax - the message

RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/9/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessResetDestinationPath		method dynamic ResEditProcessClass,
					MSG_RESEDIT_RESET_DESTINATION_PATH

	; Reload the default destination path
	;
	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset DestFileSelector
	mov	di, offset DestFileCurrentPath
	mov	ax, SP_DOCUMENT
	mov	dx, offset DestinationKey
	call	SetupFileSelector

	ret
ProcessResetDestinationPath		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveFileSelectorPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the FileSelector's path in the .ini file.

CALLED BY:	ProcessSetDestinationPath, ProcessSetSourcePath

PASS: 		^lbx:si	- GenFileSelector
 		^lbx:di	- GenGlyph
		^lcx	- key string

RETURN:		carry	- set (error)
		ax	- ErrorValue
			- or -
		carry	- clear (success)
		ax	- garbage

DESTROYED:	cx, dx, si, di, es, ds, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveFileSelectorPath	proc	near
	uses	bx	
	.enter
	
	; Validate the path, and update the UI if it looks good
	;
	call	ValidatePath
	jc	exit				; if error, bail now
	call	DisplayUserFriendlyPath

	sub	sp, (size PathName *2)
	mov	dx, sp

	; get the full pathname and disk handle
	;
	push	cx
	mov	cx, ss				; cx:dx <- first path buffer
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	mov	di, mask MF_CALL
	call 	ObjMessage			; ax <- disk handle
	mov	bx, ax			
	jc	failure

	; construct the full pathname
	; 
	mov	ds, cx
	mov	si, dx				; ds:si <- tail of path
	mov	es, cx
	mov	di, dx
	add	di, size PathName		; es:di <- second buffer
	mov	dx, -1				; add drive name
	mov	cx, size PathName
	push	di
	call	FileConstructFullPath
	pop	di				; es:di <- full pathname
	jc	failure

	; write the pathname out as the body of the passed key
	;	
	pop	si

	GetResourceHandleNS	StringsUI, bx
	call	MemLock
	mov	ds, ax
	mov	dx, ds:[si]			; ds:si <- key string
	mov	cx, ds				; cx:dx <- key string

	mov	si, offset CategoryString	
	mov	si, ds:[si]			; ds:si <- category string
	call	InitFileWriteString
	call	InitFileCommit

	call	MemUnlock
	clc					; success!
done:
	mov_tr	bx, ax				; save error code
	lahf
	add	sp, (size PathName *2)
	sahf
	mov_tr	ax, bx				; ErrorValue => AX
exit:
	.leave
	ret

failure:
	add	sp, 2
	mov	ax, EV_PATH_GET
	stc					; failure!
	jmp	done
SaveFileSelectorPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ValidatePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the top-level directory that user has selected, and
		verify that it is a GEOS tree.

CALLED BY:	SaveFileSelectorPath

PASS:		^lbx:si	- GenFileSelector
		ax	- sub-routine to call for additional checking

RETURN:		carry	= Clear if a valid GEOS tree
		ax	= garbage
			- or -
		carry	= Set otherwise
		ax	= ErrorValue

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/91		Initial version (ProtoBiffer)
	Don	9/9/00		Updated for use in ResEdit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBCS <kernelName	char	"GEOS.GEO", 0				>
DBCS <kernelName	wchar	"GEOS.GEO", 0				>
SBCS <kernelPath	char	"SYSTEM", 0				>
DBCS <kernelPath	wchar	"SYSTEM", 0				>

ValidatePath	proc	near
thePath	local	PATH_BUFFER_SIZE dup (char)
	uses	bx, cx, dx, di, si, bp, ds
	.enter
	
	; Get the Path selected by the user
	;
	call	FilePushDir
	push	bp				; save local variables frame
	mov	ax, MSG_GEN_PATH_GET
	mov	cx, size thePath
	mov	dx, ss
	lea	bp, ss:[thePath]		; buffer => DX:BP
	mov	di, mask MF_CALL
	call	ObjMessage			; fill buffer, handle => CX
	pop	bp				; restore local variables

	; Go to this directory, and then go to the SYSTEM subdirectory
	;
	mov	bx, cx				; disk handle => BX
	lea	dx, ss:[thePath]		; path => DS:DX
	call	FileSetCurrentPath
	jc	error
	clr	bx
	segmov	ds, cs
	mov	dx, offset kernelPath
	call	FileSetCurrentPath
	jc	error

	; Now check for the Kernel (always non-EC!!!)
	;
	segmov	ds, cs
	mov	dx, offset kernelName		; file name => DS:DX
	mov	al, FullFileAccessFlags<1, FE_EXCLUSIVE, 0, 0, FA_READ_WRITE>
	call	FileOpen
	jnc	closeFile			; if no carry, success
	cmp	ax, ERROR_FILE_NOT_FOUND	; if not ERROR_FILE_NOT_FOUND
	jne	success				; then we have a GEOS directory

	; Else we have an error. Display something to user
error:
	mov	ax, EV_PATH_NOT_VALID_FOR_GEODES
	stc					; failure
	jmp	done
success:
	clc					; success
done:
	call	FilePopDir

	.leave
	ret

	; Close the file we opened above
	;
closeFile:
	mov	bx, ax				; file handle => BX 
	clr	al				; ignore errors
	call	FileClose			; close the file
	jmp	success
ValidatePath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayUserFriendlyPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the path in a user-friendly manner

CALLED BY:	SetupFileSelector, SaveFileSelectorPath

PASS: 		^lbx:si	- GenFileSelector
		^lbx:si	- GenGlyph

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This is definitely a bit of a hack (!!!), but it turns
		out that whenever we change the source directory we
		also want to update some text in the NewFileInteraction DB.
		So we just look for SourceFileCurrentPath and if so change
		the moniker for NewFileCurrentSourcePath.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/9/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayUserFriendlyPath	proc	near
	uses	ax, bx, cx, dx, di, si, bp, ds, es
	.enter
	
	sub	sp, (size PathName *2)
	mov	dx, sp

	; get the full pathname and disk handle
	;
	push	bx, di
	mov	cx, ss				; cx:dx <- first path buffer
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
	mov	di, mask MF_CALL
	call 	ObjMessage			; ax <- disk handle
	mov	bx, ax			
	jc	donePop

	; construct the full pathname
	; 
	mov	ds, cx
	mov	si, dx				; ds:si <- tail of path
	mov	es, cx
	mov	di, dx
	add	di, size PathName		; es:di <- second buffer
	mov	dx, -1				; add drive name
	mov	cx, size PathName
	push	di
	call	FileConstructFullPath
	pop	di				; es:di <- full pathname
	jc	donePop

	; display the pathname in the GenGlyph
	;	
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	pop	bx, si
	movdw	cxdx, esdi
	mov	bp, VUM_NOW
	mov	di, mask MF_CALL
	push	cx, dx
	call	ObjMessage

	; a bit of a horrible hack, but if we're mucking with
	; SourceFileCurrentPath we also want to update another glyph,
	; NewFileCurrentSourcePath. So, we do it.
	;
	pop	cx, dx
	GetResourceHandleNS	ProjectMenuUI, di
	cmp	bx, di
	jne	done
	cmp	si, offset ProjectMenuUI:SourceFileCurrentPath
	jne	done
	GetResourceHandleNS	FileMenuUI, bx
	mov	si, offset FileMenuUI:NewFileCurrentSourcePath
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	bp, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	add	sp, (size PathName *2)

	.leave
	ret

donePop:
	add	sp, 4
	jmp	done
DisplayUserFriendlyPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to show the user a message.

CALLED BY:	MSG_RESEDIT_DOCUMENT_MESSAGE or called directly

PASS:		AX	= ErrorValue
		DX:BP	= Possible data for first string argument
		BX:SI	= Possible data for second string argument

RETURN:		nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/15/92	Initial version
	Don	9/9/00		Moved from other code, updated

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayErrorString	proc	far
	uses	bx,cx,dx,si,bp
	.enter

EC <	cmp	ax, ErrorValue						>
EC <	ERROR_AE	DISPLAY_ERROR_BAD_ERROR_VALUE			>
EC <	cmp	ax, EV_NO_ERROR						>
EC <	ERROR_E		DISPLAY_ERROR_BAD_ERROR_VALUE			>
	mov_tr	cx, ax

	clr	ax
	pushdw	axax				;SDP_helpContext
	pushdw	axax				;SDP_customTriggers
	pushdw	bxsi				;SDP_stringArg2
	pushdw	dxbp				;SDP_stringArg1

	mov	bx, handle ErrorStrings
	call	MemLock
	mov	ds, ax
	mov	si, offset ErrorStrings:ErrorArray
	mov	si, ds:[si]			;ds:si <- ErrorArray

	add	si, cx
	mov	si, ds:[si]			;^lsi <- string handle
	mov	si, ds:[si]
	pushdw	dssi				;SDP_customString

	mov	ax, CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION, 0>
	push	ax				;SDP_customFlags
	call	UserStandardDialog
	call	MemUnlock

	.leave
	ret
DisplayErrorString	endp


;==========================================================================
;	Methods for ResEditApplication class
;==========================================================================



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResEditApplicationUpdatePrintUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An object has either opened or closed.

CALLED BY:	MSG_GEN_APPLICATION_VISIBLITY_NOTIFICATION
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditApplicationClass
		ax - the message
		^lcx:dx - object that has become visible
		bp - non-zero if open, 0 if close
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	9/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResEditApplicationUpdatePrintUI	 method dynamic ResEditApplicationClass,
				MSG_RESEDIT_APPLICATION_NOTIFY_VISIBILITY


	push	si
	GetResourceSegmentNS	dgroup, es
	mov	bx, es
	mov	si, offset  ResEditDocumentClass
	mov	ax, MSG_RESEDIT_DOCUMENT_UPDATE_PRINT_UI
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	cx, di
	mov	dx, TO_APP_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	GOTO	ObjCallInstanceNoLock

ResEditApplicationUpdatePrintUI		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REASetBatchMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets whether a batch process is being run (so that screen
		updates can be supressed).

CALLED BY:	MSG_RESEDIT_APPLICATION_SET_BATCH_MODE

PASS:		*ds:si	= ResEditApplicationClass object
		ds:di	= ResEditApplicationClass instance data
		ds:bx	= ResEditApplicationClass object (same as *ds:si)
		es 	= segment of ResEditApplicationClass
		ax	= message #
		cl	= BatchValue

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REASetBatchMode	method dynamic ResEditApplicationClass, 
					MSG_RESEDIT_APPLICATION_SET_BATCH_MODE
		.enter

		mov	ds:[di].REA_batchMode, cl

		.leave
		ret
REASetBatchMode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REAGetBatchMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns whether a batch process is being run (so that screen
		updates can be supressed).

CALLED BY:	MSG_RESEDIT_APPLICATION_GET_BATCH_MODE

PASS:		*ds:si	= ResEditApplicationClass object
		ds:di	= ResEditApplicationClass instance data
		ds:bx	= ResEditApplicationClass object (same as *ds:si)
		es 	= segment of ResEditApplicationClass
		ax	= message #

RETURN:		al	= BatchValue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REAGetBatchMode	method dynamic ResEditApplicationClass, 
					MSG_RESEDIT_APPLICATION_GET_BATCH_MODE
		.enter

		mov	al, ds:[di].REA_batchMode

		.leave
		ret
REAGetBatchMode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REAEndBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off batch mode and put up the New/Open dialog.

CALLED BY:	MSG_RESEDIT_APPLICATION_END_BATCH
PASS:		*ds:si	= ResEditApplicationClass object
		ds:di	= ResEditApplicationClass instance data
		ds:bx	= ResEditApplicationClass object (same as *ds:si)
		es 	= segment of ResEditApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	9/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REAEndBatch	method dynamic ResEditApplicationClass, 
					MSG_RESEDIT_APPLICATION_END_BATCH
		uses	ax, cx, dx, bp
		.enter

	; Turn off batch processing mode.

		mov	al, BM_OFF	
		call	SetBatchMode

	; Put up New/Open dialog.  We kept it from going up when the last
	; document was closed so it wouldn't go over the batch status dialog
	; before it is closed by the user.

		mov 	ax, MSG_RESEDIT_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditDocumentControl
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
REAEndBatch	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REACancelBatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel an in-progress batch job.

CALLED BY:	MSG_RESEDIT_APPLICATION_CANCEL_BATCH
PASS:		*ds:si	= ResEditApplicationClass object
		ds:di	= ResEditApplicationClass instance data
		ds:bx	= ResEditApplicationClass object (same as *ds:si)
		es 	= segment of ResEditApplicationClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	9/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REACancelBatch	method dynamic ResEditApplicationClass, 
					MSG_RESEDIT_APPLICATION_CANCEL_BATCH
		uses	ax, cx, dx, bp
		.enter

	; End batch mode.

		mov	ax, MSG_RESEDIT_APPLICATION_END_BATCH
		GetResourceHandleNS	AppResource, bx
		mov	si, offset ResEditApp
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
REACancelBatch	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBatchMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn on or off batch mode.

CALLED BY:	ResEditApplicationRunBatchJob
PASS:		al	= BatchMode value
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBatchMode	proc	far
		uses	bx,cx,si,di
		.enter

		mov	cl, al
		mov	ax, MSG_RESEDIT_APPLICATION_SET_BATCH_MODE
		GetResourceHandleNS	AppResource, bx
		mov	si, offset ResEditApp
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
SetBatchMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsBatchMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the carry flag if we're in batch mode.

CALLED BY:	EXTERNAL
PASS:		ds must be a valid LMem block
RETURN:		if in batch mode, carry set
		else, carry clear
DESTROYED:	nothing
SIDE EFFECTS:	Fixes up ds.

PSEUDO CODE/STRATEGY:

		NOTE: If the batch process has been cancelled, batch mode is
		considered on, until the job is aborted.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsBatchMode	proc	far
		uses	ax,bx,si,di
		.enter

		mov	ax, MSG_RESEDIT_APPLICATION_GET_BATCH_MODE
		GetResourceHandleNS	AppResource, bx
		mov	si, offset ResEditApp
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		cmp	al, BM_OFF
		je	done
		stc
done:
		.leave
		ret
IsBatchMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsBatchModeCancelled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the carry flag if the user has cancelled the batch job.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		if batch mode has been cancelled, carry set
		else, carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsBatchModeCancelled	proc	far
		uses	ax,bx,si,di,bp
		.enter

		mov	ax, MSG_RESEDIT_APPLICATION_GET_BATCH_MODE
		GetResourceHandleNS	AppResource, bx
		mov	si, offset ResEditApp
		mov	di, mask MF_CALL
		call	ObjMessage
		cmp	al, BM_CANCELLED
		je	done
		stc
done:
		cmc
		.leave
		ret
IsBatchModeCancelled	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REPProcessCreateUiThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give the UI thread a bigger stack size.

CALLED BY:	MSG_PROCESS_CREATE_UI_THREAD

PASS:		ds	= ResEditProcessClass core block
		es 	= segment of ResEditProcessClass
		ax	= message #
		cx:dx	= object class for new thread
		bp	= stack size to use for the new thread
RETURN:		CF clear if thread created
			ax	= handle of new thread
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	The default UI thread stack overflows when the EC version is
	minimized and then restored.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	3/09/01   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REPProcessCreateUiThread	method dynamic ResEditProcessClass, 
					MSG_PROCESS_CREATE_UI_THREAD

	mov	bp, INTERFACE_THREAD_DEF_STACK_SIZE + 500
					; bp = new stack size
	mov	di, offset ResEditProcessClass
	GOTO	ObjCallSuperNoLock

REPProcessCreateUiThread	endm

MainProcessCode		ends





