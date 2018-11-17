COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainDocumentNew.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDocument		Open look document class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cmainDocument.asm

DESCRIPTION:

	$Id: cmainDocumentNew.asm,v 1.1 97/04/07 10:52:39 newdeal Exp $

------------------------------------------------------------------------------@
DocNewOpen segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentInitialize -- MSG_META_INITIALIZE for OLDocumentClass

DESCRIPTION:	Initialize for vis part of the instance data

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

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
	Tony	5/19/92		Initial version

------------------------------------------------------------------------------@
OLDocumentInitialize	method dynamic	OLDocumentClass, MSG_META_INITIALIZE

	mov	di, offset OLDocumentClass
	call	ObjCallSuperNoLock

	call	GetParentAttrs
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLDI_attrs, 0
	mov	ds:[di].OLDI_iacpEngConnects, 0
	mov	ds:[di].OLDI_disk, 0

	test	ax, mask GDGA_CONTENT_DOES_NOT_MANAGE_CHILDREN
	jz	10$
	andnf	ds:[di].VI_attrs, not mask VA_MANAGED
	andnf	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN
10$:

	test	ax, mask GDGA_LARGE_CONTENT
	jz	20$
	ornf	ds:[di].VCNI_attrs, mask VCNA_LARGE_DOCUMENT_MODEL or \
				    mask VCNA_WINDOW_COORDINATE_MOUSE_EVENTS
20$:

	call	GetUIParentAttrs
	test	ax, mask GDCA_DO_NOT_SAVE_FILES
	jz	30$
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GDI_attrs, mask GDA_READ_ONLY
30$:

	ret

OLDocumentInitialize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGrabModelIfAppropriate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the Model exclusive for this document if it's been
		opened by the user.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= document object
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGrabModelIfAppropriate proc	far
	class	OLDocumentClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDI_attrs, mask OLDA_USER_OPENED
	jz	done
	call	MetaGrabModelExclLow
done:
	.leave
	ret
OLDocumentGrabModelIfAppropriate endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StartAutoSave

DESCRIPTION:	Fire up auto-save for this document

CALLED BY:	INTERNAL

PASS:
	*ds:si - document

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@

StartAutoSave	proc	far

EC <	call	AssertIsGenDocument					>

	call	OLDocumentGetAttrs
	test	ax, mask GDA_READ_ONLY
	jnz	exit

	call	GetParentAttrs		;ax = attributes

	push	ax
	test	ax, mask GDGA_SUPPORTS_AUTO_SAVE
	jz	noAutoSave
	mov	dx, offset OLDI_autoSaveTimer
	clr	cx
	call	StartATimer
noAutoSave:
	pop	ax

	test	ax, mask GDGA_AUTOMATIC_CHANGE_NOTIFICATION
	jz	noChange
	call	OLDocumentGetAttrs
	test	ax, mask GDA_SHARED_MULTIPLE
	jz	noChange
	mov	dx, offset OLDI_changeTimer
	clr	cx
	call	StartATimer
noChange:

exit:
	ret

StartAutoSave	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	PushAndSetPath

DESCRIPTION:	Push the current path and set the given disk. If the disk
		is 0, the path bound to the object will be set

CALLED BY:	INTERNAL

PASS:
	ss:bp - DocumentCommonParams
	*ds:si	- document object if DCP_diskHandle is 0

RETURN:
	ax - error code (if error)
	ds - may be updated

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

LocalDefNLString emptyPath <".", 0>

PushAndSetPath	proc	far	uses bx, cx, dx
	.enter

	push	ax
	call	FilePushDir

	mov	bx, ss:[bp].DCP_diskHandle
	tst	bx
	jz	useObjectPath
	
	push	ds			; preserve object segment
	segmov	ds, ss
	lea	dx, ss:[bp].DCP_path
	call	FileSetCurrentPath
	pop	ds			; object segment
	jc	createDir2

done:
	jnc	doneNoError
	pop	bx
	push	ax
doneNoError:
	pop	ax

	.leave
	ret

	;
	; path specified in ATTR_GEN_PATH_DATA
	;
useObjectPath:
	call	useObjectPath2
	jnc	done				;branch if no error
	;
	; if the path doesn't exist, try to create it
	;
createDir::
	cmp	ax, ERROR_PATH_NOT_FOUND
	jne	doneError			;branch if other error
	;
	; get the path data
	;
	call	loadVars
	call	GenPathFetchDiskHandleAndDerefPath
	tst	ax
	jz	pathError			;branch if error getting disk
	;
	; try to create the dir
	;
	call	setDiskAndCreate
	jc	pathError			;branch if error
	;
	; success! set the path
	;
	call	loadVars
	call	GenPathSetCurrentPathFromObjectPath
	jmp	done

pathError:
	mov	ax, ERROR_PATH_NOT_FOUND
doneError:
	stc
	jmp	done

	;
	; the specified path doesn't exist; try to create it
	;
createDir2:
	cmp	ax, ERROR_PATH_NOT_FOUND
	jne	doneError			;branch if other error
	mov	dx, ss:[bp].DCP_diskHandle	;dx <- disk handle
	push	ds
	segmov	ds, ss
	lea	bx, ss:[bp].DCP_path		;ds:bx <- path
	call	setDiskAndCreate
	pop	ds
	jc	pathError			;branch if error
	;
	; success! set the path
	;
	push	ds
	segmov	ds, ss
	lea	dx, ss:[bp].DCP_path
	call	FileSetCurrentPath
	pop	ds
	jmp	done

	;
	; go to the right disk
	;
setDiskAndCreate:
	xchg	bx, dx				;bx <- disk handle
	push	ds, dx
	segmov	ds, cs
	mov	dx, offset emptyPath		;ds:dx <- "."
	call	FileSetCurrentPath
	pop	ds, dx				;ds:dx <- path
	jc	createError			;branch if error setting path
	;
	; actually try to create the dir
	;
	call	FileCreateDir
createError:
	retn

useObjectPath2:
	call	loadVars
	call	GenPathSetCurrentPathFromObjectPath
	retn

loadVars:
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	retn
PushAndSetPath	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StoreNewDocumentName

DESCRIPTION:	Store a document's file name

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ss:bp - DocumentCommonParams
	ax - file handle to store

RETURN:
	none

DESTROYED:
	ax, bx, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
StoreNewDocumentName	proc	far	uses cx, dx, di
	.enter
	class	OLDocumentClass

EC <	call	AssertIsGenDocument					>

	call	FilePushDir

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].OLDocument_offset
	mov	ds:[di].OLDI_disk, 0		; force re-fetch of ID
	mov	di, ds:[si]

	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_fileHandle, ax
	push	ax
	
	tst	ss:[bp].DCP_diskHandle		; path provided?
	jz	pathSet				; no -- leave object path alone
	
	push	bp
	mov	cx, ss
	lea	dx, ss:[bp].DCP_path
	mov	bp, ss:[bp].DCP_diskHandle
	mov	ax, MSG_GEN_PATH_SET
	call	ObjCallInstanceNoLock
	pop	bp

pathSet:
	mov	ax, ss:[bp].DCP_docAttrs	;bits to set
	mov	bx, mask GDA_READ_ONLY or mask GDA_READ_WRITE or \
		    mask GDA_SHARED_SINGLE or mask GDA_SHARED_MULTIPLE
						;bits to clear
	call	OLDocSetAttrs

	push	si, bp
	segmov	es, ds
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	add	di, offset GDI_fileName		;es:di = dest
	segmov	ds, ss
	lea	si, ss:[bp].DCP_name		;ds:si = source (file name)
SBCS <	mov	cx, size FileLongName					>
DBCS <	mov	cx, (size FileLongName)/2				>
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	pop	si, bp
	
	segmov	ds, es			; return fixed up segment

if _ISUI
	; if name is still untitled, mark it as such
	sub	sp, size DocumentCommonParams
	mov	cx, ss
	mov	dx, sp
	push	bp, es, si
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME
	call	GenCallParent
	mov	es, cx
	mov	di, dx
	lea	di, es:[di].DCP_name
	call	LocalStringLength		; cx = length w/o null
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	lea	si, ds:[si].GDI_fileName
	mov	bx, cx
SBCS <	clr	ax, dx							>
SBCS <	mov	al, ds:[bx][si]						>
SBCS <	mov	dl, ds:[bx][si]+(size TCHAR)				>
DBCS <	mov	ax, ds:[bx][si]						>
DBCS <	mov	dx, ds:[bx][si]+(size TCHAR)				>
	call	LocalCmpStrings
	pop	bp, es, si
	jne	notUntitled
	LocalIsNull	ax
	je	isUntitled
	LocalCmpChar	ax, C_SPACE
	jne	notUntitled
	LocalCmpChar	dx, '0'
	jb	notUntitled
	LocalCmpChar	dx, '9'
	ja	notUntitled
isUntitled:
	mov	ax, mask GDA_UNTITLED
	clr	bx
	call	OLDocSetAttrs
notUntitled:
	add	sp, size DocumentCommonParams
endif

	; get the "on writable media" flag

	pop	bx
	push	bx
	call	FileGetDiskHandle		;bx = disk handle
	call	DiskCheckWritable
	jnc	notWritable
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GDI_attrs, mask GDA_ON_WRITABLE_MEDIA

	; get the "backup exists" flag (only set this if the document is
	; not read-only and not public or multi-user)

	test	ds:[di].GDI_attrs, mask GDA_SHARED_SINGLE or \
				   mask GDA_SHARED_MULTIPLE or \
				   mask GDA_READ_ONLY
	jnz	noBackup
	call	SetBackupDir
	jc	noBackup
	lea	dx, ds:[di].GDI_fileName	;ds:dx = file name
	call	FileGetAttributes
	jc	noBackup
	ornf	ds:[di].GDI_attrs, mask GDA_BACKUP_EXISTS
noBackup:
notWritable:

	; get the document type

	pop	bx
	sub	sp, size word
	segmov	es, ss
	mov	di, sp
	mov	ax, FEA_FILE_ATTR
	mov	cx, size word
	call	FileGetHandleExtAttributes
	mov	dl, es:[di]			;dl = FileAttr
	mov	ax, FEA_FLAGS
	call	FileGetHandleExtAttributes
	mov	bx, 0
	jc	gotFlags
	mov	bx, es:[di]			;bx = GeosFileHeaderFlags
gotFlags:

	mov	ax, GDT_READ_ONLY
	test	dl, mask FA_RDONLY
	jnz	gotType
	mov	ax, GDT_TEMPLATE
	test	bx, mask GFHF_TEMPLATE
	jnz	gotType
	mov	ax, GDT_PUBLIC
	test	bx, mask GFHF_SHARED_SINGLE
	jnz	gotType
	mov	ax, GDT_MULTI_USER
	test	bx, mask GFHF_SHARED_MULTIPLE
	jnz	gotType
	mov	ax, GDT_NORMAL
gotType:
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_type, ax

	add	sp, size word

	call	FilePopDir

	call	OLDocumentRegisterOpenDoc

	.leave
	ret

StoreNewDocumentName	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetBackupDir

DESCRIPTION:	Set the backup directory to be the current directory

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	carry - set if error

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@
SetBackupDir	proc	far	uses bx, dx, ds
	.enter

	mov	bx, segment backupDirDisk
	mov	ds, bx
	mov	bx, ds:[backupDirDisk]
	mov	dx, offset backupDirPath
	call	FileSetCurrentPath

	.leave
	ret

SetBackupDir	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentOpen -- MSG_GEN_DOCUMENT_OPEN for OLDocumentClass

DESCRIPTION:	Open a file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_OPEN

	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

RETURN:
	carry - set if error
	bp - unchanged
	ax - file handle

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	[MSG_GEN_DOCUMENT_PHYSICAL_OPEN]
	MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT
	[MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE]
	MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentOpen	method OLDocumentClass, MSG_GEN_DOCUMENT_OPEN
					uses bp
	.enter

	call	OLDocMarkBusy

	push	ax				;save message

if FLOPPY_BASED_DOCUMENTS
	;	
	; Don't allow opening if we've exceeded the maximum size already.
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_OLDG_GET_TOTAL_SIZE	
	call	GenCallParent			
	cmpdw	dxcx, MAX_TOTAL_FILE_SIZE	
	pop	ax, cx, dx, bp
	jb	continueSave
	mov	ax, SDBT_CANT_OPEN_TOTAL_FILES_TOO_LARGE
	call	FarCallStandardDialogSS_BP
	jmp	notReopen

continueSave:
endif

	cmp	ax, MSG_META_ATTACH
	jz	noSetOpen
	test	ss:[bp].DCP_flags, mask DOF_REOPEN
	jnz	noSetOpen
	mov	ax, GDO_OPEN
	call	OLDocSetOperation
noSetOpen:

if ENFORCE_DOCUMENT_HANDLES
	; check available handles
	call	CheckHandles
	mov	ax, SDBT_CANT_OPEN_TOTAL_FILES_TOO_LARGE	; assume error
	LONG jc	displayErrorDialog		; (no need for PopDir)
endif

	call	PushAndSetPath
	jc	handleError

	clr	di				;no "read-only" tried
tryOpen:

	; open the file

	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_OPEN
	call	ObjCallInstanceNoLock
	LONG jnc noError

	;---------------------------------------------------------
	; Error case...
	;---------------------------------------------------------

handleError:

if SINGLE_DRIVE_DOCUMENT_DIR
	test	ss:[bp].DCP_flags, mask DOF_NO_ERROR_DIALOG
	LONG	jnz	notReopen			;done right for Redwood	
							;  1/13/94 cbh
endif

	tst	ax
	jz	returnErrorPopDir

	call	ConvertErrorCode

	cmp	ax, ERROR_ACCESS_DENIED
	jz	tryReadOnly
	cmp	ax, ERROR_SHARING_VIOLATION
	je	tryReadOnly
	cmp	ax, ERROR_WRITE_PROTECTED
	jnz	realError

	; handle write protected case -- try opening read-only if possible

tryReadOnly:
	call	GetUIParentAttrs
	mov	ax, SDBT_FILE_OPEN_SHARING_DENIED
	test	ss:[bp].DCP_docAttrs, mask GDA_READ_ONLY
	jnz	displayErrorDialogPopDir

	inc	di					;mark trying read-only
	ornf	ss:[bp].DCP_docAttrs, mask GDA_READ_ONLY
	andnf	ss:[bp].DCP_docAttrs, not mask GDA_READ_WRITE
	andnf	ss:[bp].DCP_flags,
			not mask DOF_CREATE_FILE_IF_FILE_DOES_NOT_EXIST
	jmp	tryOpen

returnErrorPopDir:
	call	FilePopDir
	jmp	returnError

displayErrorDialogPopDir:
	call	FilePopDir
	jmp	displayErrorDialog

realError:
	call	FilePopDir
realErrorAfterPopDir:
	mov_trash	bx, ax				;bx = error
	tst	bx
	jz	returnError
	mov	ax, SDBT_FILE_OPEN_FILE_TYPE_MISMATCH
	cmp	bx, ERROR_FILE_FORMAT_MISMATCH
	jz	displayErrorDialog
	mov	ax, SDBT_FILE_OPEN_SHARING_DENIED	;not perfect but oh well
	cmp	bx, VM_CANNOT_OPEN_SHARED_MULTIPLE
	jz	displayErrorDialog
	mov	ax, SDBT_FILE_OPEN_FILE_NOT_FOUND
	cmp	bx, ERROR_FILE_NOT_FOUND
	jz	displayErrorDialog
	mov	ax, SDBT_FILE_OPEN_INVALID_VM_FILE
	cmp	bx, VM_OPEN_INVALID_VM_FILE
	jz	displayErrorDialog
	mov	ax, SDBT_FILE_OPEN_INSUFFICIENT_DISK_SPACE
	cmp	bx, ERROR_SHORT_READ_WRITE
	jz	displayErrorDialog
	mov	ax, SDBT_FILE_OPEN_ERROR

displayErrorDialog:
	;
	; need to destroy document before putting up error message so we
	; won't try to access file to redraw stuff when the error box goes
	; away.
	; (Yes, we duplicate a few lines of code here...)
	;
	test	ss:[bp].DCP_flags, mask DOF_REOPEN
	jz	notReopen2
	push	ax, cx, dx, bp
 	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	call	FarCallStandardDialogSS_BP
	call	OLDocRemoveObj
	jmp	short notReopen

notReopen2:
	call	FarCallStandardDialogSS_BP

returnError:
	test	ss:[bp].DCP_flags, mask DOF_REOPEN
	jz	notReopen
 	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
	call	OLDocRemoveObj
notReopen:
	stc
done:
	call	OLDocClearOperation
	pop	cx			;discard message
	call	OLDocMarkNotBusy
	Destroy	cx, dx
	.leave
	ret

	;---------------------------------------------------------
	; Success case...
	;---------------------------------------------------------

	; ax = file handle
	; cx = non-zero if template
	; dx = non-zero if new file created
	; di = non-zero if trying to open the file read-only

noError:
	call	StoreNewDocumentName
	call	UserStoreDocFileName ; Store in the most-recently-opened list.
	call	FilePopDir

	; if file created then handle specially

	tst	dx
	jz	noCreate
	call	CreateNewFileCommon
	jc	returnError
	jmp	copeWithIACP

noCreate:
	test	ss:[bp].DCP_flags, mask DOF_FORCE_TEMPLATE_BEHAVIOR
	jnz	template
	jcxz	notTemplate
	call	GetUIParentAttrs
	and	ax, mask GDCA_MODE
	cmp	ax, GDCM_VIEWER shl offset GDCA_MODE
	jz	notTemplate

	; this is a template document -- make an untitled copy of it

template:
	call	CopyFromTemplate
	jnc	notTemplate		; success
	push	ax, bp			; save error code, DCP
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CLOSE	; close template
	call	ObjCallInstanceNoLock
	pop	ax, bp
	jmp	realErrorAfterPopDir

notTemplate:

	mov	ax, seg dgroup
	mov	es, ax

	; Opening existing file...
	; if opened VM file then check for invalid protocol

	call	GetParentAttrs
	mov_tr	cx, ax				;CX <- parent attrs
	call	FileOpenedCheckProtocol
	jnc	noProtoError
	push	ax, bp
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CLOSE
	call	ObjCallInstanceNoLock
	pop	ax, bp
	jmp	displayErrorDialog
noProtoError:

	; check for opening a read-only or public file in transparent
	; document mode

	call	GetUIParentAttrs
	and	ax, mask GDCA_MODE
	cmp	ax, GDCM_VIEWER shl offset GDCA_MODE
	jz	afterReadOnly

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_READ_ONLY
	jz	afterReadOnly

	call	GetDocOptions
	test	ax, mask DCO_TRANSPARENT_DOC
	jz	afterReadOnly

	mov	ax, SDBT_FILE_OPEN_READ_ONLY_PUBLIC_IN_TRANSPARENT_MODE
	call	FarCallStandardDialogSS_BP
	cmp	ax, IC_YES
	je	afterReadOnly

	; user does not want to open the file read only, so close it.

	push	bp
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CLOSE
	call	ObjCallInstanceNoLock
	pop	bp
	jmp	returnError

afterReadOnly:

	; if a VM file in backup mode then check for file dirty

	call	GetParentAttrs
	test	ax, mask GDGA_VM_FILE
	jz	afterVMDirtyTest
	call	GetUIParentAttrs
	test	ax, mask GDCA_SUPPORTS_SAVE_AS_REVERT
	jz	afterVMDirtyTest
	call	OLDocumentGetAttrs
	test	ax, mask GDA_SHARED_MULTIPLE
	jnz	afterVMDirtyTest

	call	OLDocumentGetFileHandle
	call	VMGetDirtyState			;al non-zero if DIRTY
	tst	al
	jz	afterVMDirtyTest

	; notify the user that the file is dirty, unless we're attaching

	pop	ax
	push	ax				;get message
	cmp	ax, MSG_META_ATTACH
	jz	noNotifyDirty

	;
	; in rudy, we don't want this dialog (file is not saved last
	; time it is closed, please save ..)
	; -- kho, 10/11/95
	;
	test	ss:[bp].DCP_flags, mask DOF_REOPEN
	jnz	skipDirtyWarning
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	jnz	skipDirtyWarning
	mov	ax, SDBT_FILE_OPEN_VM_DIRTY
	call	FarCallStandardDialogSS_BP
skipDirtyWarning:
		
	mov	ax, mask GDA_DIRTY
	jmp	setAttrsCommon

noNotifyDirty:
	mov	ax, mask GDA_ATTACH_TO_DIRTY_FILE or mask GDA_DIRTY
setAttrsCommon:
	clr	bx
	call	OLDocSetAttrs

afterVMDirtyTest:

	; send messages to get the document displayed

	pop	ax
	push	ax
	push	bp

	push	ax
	call	StartAutoSave
	pop	ax

	test	ss:[bp].DCP_flags, mask DOF_REOPEN
	jnz	noCreateUI

	call	DocumentCloseOthers

	cmp	ax, MSG_META_ATTACH
	jz	noCreateUI
	mov	ax, MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
noCreateUI:
	mov	ax, MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	call	ObjCallInstanceNoLock
	pop	bp
copeWithIACP:
	test	ss:[bp].DCP_flags, mask DOF_RAISE_APP_AND_DOC
	jz	addConnection

	;
	; Raise ourselves and our application, as instructed.
	; 
	push	bp
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjCallInstanceNoLock
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	GenCallApplication
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	GenCallApplication
	pop	bp

addConnection:
	mov	ax, ss:[bp].DCP_connection
	cmp	ax, -1
	je	grabModel		; => no change
	call	OLDocumentAddConnection
grabModel:
	call	OLDocumentGrabModelIfAppropriate

	;
	; If we've successfully opened a template, start the template "wizard".
	;
	test	ss:[bp].DCP_flags, mask DOF_FORCE_TEMPLATE_BEHAVIOR
	jz	getFileHandle

	push	bp
	mov	ax, MSG_GEN_DOCUMENT_INITIATE_TEMPLATE_WIZARD
	mov	dx, size DocumentCommonParams
	call	ObjCallInstanceNoLock
	pop	bp		

getFileHandle:
	call	OLDocumentGetFileHandle			;ax = file handle
	clc
	jmp	done

OLDocumentOpen	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DocumentCloseOthers

DESCRIPTION:	Close documents that need to be closed because this one
		is opening

CALLED BY:	OLDocumentNew, OLDocumentOpen

PASS:
	*ds:si - GenDocument object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/90		Initial version

------------------------------------------------------------------------------@
DocumentCloseOthers	proc	far
	uses	ax, bp
	class	OLDocumentClass
	.enter

EC <	call	AssertIsGenDocument					>

	mov	ax, mask GDA_OPENING
	clr	bx
	call	OLDocSetAttrs

	push	si
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	ax, MSG_GEN_DOCUMENT_CLOSE_IF_CLEAN_UNNAMED
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	pop	si
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	GenCallParent

	clr	ax
	mov	bx, mask GDA_OPENING
	call	OLDocSetAttrs

	.leave
	ret

DocumentCloseOthers	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentCloseIfCleanUnnamed --
		MSG_GEN_DOCUMENT_CLOSE_IF_CLEAN_UNNAMED for OLDocumentClass

DESCRIPTION:	Close file if clean and unnamed OR if the file is clean
		and named but only one document is allowed

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_CLOSE_IF_CLEAN_UNNAMED

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	Chris	4/19/93		Pulled out some code.  May I be struck down
				if I messed up anything.

------------------------------------------------------------------------------@
OLDocumentCloseIfCleanUnnamed	method dynamic OLDocumentClass,
				MSG_GEN_DOCUMENT_CLOSE_IF_CLEAN_UNNAMED

	; If the document is modified or it is closing or it is the
	; documentbeing opened then do not close it

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_CLOSING or mask GDA_OPENING
	jnz	done

	; if in transparent mode then *always* close it.  (We'll force
	; a save, not an update in the next routine. -4/19/93 cbh)
	push	es, ax
	segmov	es, dgroup, ax				;es = dgroup
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es, ax
	jnz	saveAndClose

	; if multiple files are allowed to be open then do nothing

	call	GetUIParentAttrs		;ax = attributes
	test	ax, mask GDCA_MULTIPLE_OPEN_FILES
	jnz	done

saveAndClose:
	;
	; If DCO_USER_CONFIRM_SAVE, then drop through to OLDocumentClose,
	; which will prompt the user.
	;
	push	es
	segmov	es, dgroup, ax			;es = dgroup
	test	es:[docControlOptions], mask DCO_USER_CONFIRM_SAVE
	pop	es
	jnz	close

	call	OLDocumentSaveOrUpdate

	call	OLDocumentClearDirtyIfOK
close:

	call	CallCloseDocument
done:
	Destroy	ax, cx, dx, bp
	ret

OLDocumentCloseIfCleanUnnamed	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentSaveOrUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save or update a document, as appropriate, to make sure it's
		on disk OK.  

CALLED BY:	OLDocumentCloseIfCleanUnnamed,
		OLDocumentDetach,
		OLDocNotifyFileChange

PASS:		*ds:si	= document
		es	= segment of OLDocumentClass

RETURN:		carry set if error writing file

DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:
		Does not modify GDA_DIRTY bit.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version
	martin	7/19/93		Added confirm save dialog
	chrisb	11/93		removed confirm save dialog

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentSaveOrUpdate proc	far
	uses	bx, di, es
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_attrs
	andnf	bx, mask GDA_DIRTY
	push	bx			; save dirty bit.

	;
	; if in transparent mode then always save, unless 
	; DCO_USER_CONFIRM_SAVE is set, in which case, do an update.
	;

	push	es, ax
	segmov	es, dgroup, ax	
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es, ax
	jz	update

	push	es, ax
	segmov	es, dgroup, ax
	test	es:[docControlOptions], mask DCO_USER_CONFIRM_SAVE
	pop	es, ax
	jz	save
		
update:
	; if can handle auto-save, then use DOCUMENT_UPDATE, not DOCUMENT_SAVE,
	; as it's the less-destructive option.

	call	GetParentAttrs
	test	ax, mask GDGA_SUPPORTS_AUTO_SAVE
	jz	save

	mov	ax, MSG_GEN_DOCUMENT_UPDATE	; act like auto-save
	mov	bl, mask OLDA_UPDATE_BEFORE_CLOSE
	jmp	doIt
save:
	mov	ax, MSG_GEN_DOCUMENT_SAVE
	mov	bl, mask OLDA_SAVE_BEFORE_CLOSE

doIt:
	call	ObjCallInstanceNoLock
	;
	; Store the type of action we just attempted, in case there's
	; an error, and we get a CLOSE later on.  This is necessary in
	; DCO_USER_CONFIRM_SAVE mode  to avoid putting up another
	; confirm save dialog.
	;

	lahf
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].OLDI_attrs, bl		; OLDocumentAttrs

	;
	; Restore the dirty flag to what it was on entry
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	pop	bx			; restore dirty bit	
	ornf	ds:[di].GDI_attrs, bx
	sahf
exit:
	.leave
	ret
OLDocumentSaveOrUpdate endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentClearDirtyIfOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the dirty flag if save or update was OK.
		Called after OLDocumentSaveOrUpdate, but
		before calling OLDocumentClose, so that the close
		doesn't prompt the user.

CALLED BY:	OLDocumentCloseIfCleanUnnamed,
		OLDocumentRemovingDisk

PASS:		*ds:si - document object
		if error
			carry set
		else
			carry clear 

RETURN:		GDA_DIRTY flag cleared if appropriate

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentClearDirtyIfOK	proc near
		.enter
		jc	done

		clr	ax				;bits to set
		mov	bx, mask GDA_DIRTY 		;bits to clear
		call	OLDocSetAttrs
done:
		.leave
		ret
OLDocumentClearDirtyIfOK	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	OLDocumentIsObjectFromThisDisk

DESCRIPTION:	Returns whether this object originated from the passed disk.

PASS:		ds:di 	- OLDocument GenInstance
		cx	- disk handle

RETURN:		carry set if originated from this disk

ALLOWED TO DESTROY:	
		bx
	
REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/16/93         Initial Version

------------------------------------------------------------------------------@

OLDocumentIsObjectFromThisDisk		proc	near
	class	OLDocumentClass

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_fileHandle	;get our file's disk handle
	call	FileGetDiskHandle		;in bx
	cmp	cx, bx
	clc					;assume no match
	jne	exit
	stc					;else return carry set
exit:
	ret
OLDocumentIsObjectFromThisDisk		endp



COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentRemovingDisk -- 
		MSG_META_REMOVING_DISK for OLDocumentClass

DESCRIPTION:	Notifies any apps or document controls that a disk is being
		removed.   Objects that originated from this disk will shut
		themselves down.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_DISK_REMOVED

		cx	- disk handle

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	4/16/93         Initial Version

------------------------------------------------------------------------------@

OLDocumentRemovingDisk	method dynamic	OLDocumentClass, 
					MSG_META_REMOVING_DISK

	call	OLDocumentIsObjectFromThisDisk
	jnc	exit				;not from disk being removed...

	call	OLDocumentSaveOrUpdate

	call	OLDocumentClearDirtyIfOK

	call	CallCloseDocument
exit:
	ret
OLDocumentRemovingDisk	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallCloseDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	call	MSG_GEN_DOCUMENT_CLOSE, passing bp=0 to
		specify a user action

CALLED BY:	OLDocumentRemovingDisk,
		OLDocumentCloseIfCleanUnnamed

PASS:		*ds:si - OLDocumentClass object

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallCloseDocument	proc near
		mov	ax, MSG_GEN_DOCUMENT_CLOSE
		clr	bp			; user-initiated
		call	ObjCallInstanceNoLock
		ret
CallCloseDocument	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentAddConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record another connection as interested in the document.
		If first user connection, set display usable.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= GenDocument object
		ax	= IACPConnection to add (0 if user)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentAddConnection proc	far
	uses	ax, bx, cx, dx, si, di, bp
	.enter

	mov_tr	bp, ax
	tst	bp
	LONG jz	markUserOpen

	;
	; Let IACP client know our od & the app object's server number
	; 
	push	si
		CheckHack <offset IDOAP_serverNum+size IDOAP_serverNum eq \
				size IACPDocOpenAckParams>
	push	ax
		CheckHack <offset IDOAP_connection+size IDOAP_connection eq \
				offset IDOAP_serverNum>
	push	bp
		CheckHack <offset IDOAP_docObj+size IDOAP_docObj eq \
				offset IDOAP_connection>
	push	ds:[LMBH_handle]
	push	si
		CheckHack <offset IDOAP_docObj eq 0>

	clr	bx
	call	GeodeGetAppObject
	mov	cx, bx			; ^lcx:dx <- app obj (the assumed
	mov	dx, si			;  server via which we got this call)
	call	IACPGetServerNumber	; ax <- server #

	mov	bp, sp
	mov	ss:[bp].IDOAP_serverNum, ax
	mov	ax, MSG_META_IACP_DOC_OPEN_ACK
	mov	dx, size IACPDocOpenAckParams
	clr	bx, si			; any class
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage
	mov	bp, ss:[bp].IDOAP_connection
	add	sp, dx
	mov	bx, di
	clr	cx			; no completion msg
	mov	dx, TO_SELF
	mov	ax, IACPS_SERVER	; server sending this one
	call	IACPSendMessage
	pop	si

	;
	; Now make sure the connection is in our array of active connections.
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].OLDI_iacpEngConnects
	tst	ax
	jnz	haveArray

	;
	; Don't even have an array yet, so create one
	; 
	push	si
	mov	bx, size IACPConnection
	mov	ax, mask OCF_IGNORE_DIRTY
	clr	si, cx
	call	ChunkArrayCreate
	mov_tr	ax, si
	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLDI_iacpEngConnects, ax

haveArray:
	;
	; See if connection is in the array
	; 
	push	si
	mov_tr	si, ax
	mov	bx, cs
	mov	di, offset OLDocumentFindConnection
	clr	ax
	call	ChunkArrayEnum
	jc	inArray
	;
	; Nope -- make room for it and stuff it.
	; 
	call	ChunkArrayAppend
	mov	ds:[di], bp
inArray:
	pop	si
done:	
	.leave
	ret

markUserOpen:
	;
	; Make sure document is marked as opened by the user.
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].OLDI_attrs
	ornf	ds:[di].OLDI_attrs, mask OLDA_USER_OPENED
	test	al,  mask OLDA_USER_OPENED
	jnz	done
	;
	; Wasn't user-opened before, so we need to set its display usable, etc.
	; 
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	tst	bx
	jz	done		; nothing to do -- assume non-mdi app has set
				;  things up correctly regardless of whether
				;  user has it open
	;
	; Get chunk handle of duplicated display from the document group
	; 
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	call	GenCallParent
	;
	; Set the beastie usable for immediate update
	; 
	push	si
	mov	si, dx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	call	MetaGrabModelExclLow
	jmp	done
OLDocumentAddConnection endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentFindConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate an IACP connection in a document's
		iacpEngConnects array

CALLED BY:	(INTERNAL) OLDocumentAddConnection & OLDocumentLostConnection
			   via ChunkArrayEnum
PASS:		*ds:si	= array
		ds:di	= &IACPConnection to check
		ax	= entry # of this connection
RETURN:		carry set if this is the one:
			ax	= preserved
		carry clear if it ain't:
			ax	= ax+1
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentFindConnection proc	far
	.enter
	cmp	ds:[di], bp
	je	done
	inc	ax
	stc
done:
	cmc
	.leave
	ret
OLDocumentFindConnection endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FileOpenedCheckProtocol

DESCRIPTION:	Check the protocol of the just opened document

CALLED BY:	OLDocumentOpen

PASS:
	*ds:si - object

RETURN:
	carry - set if error
	if error:
		ax = StandardDialogBox type for error box

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
FileOpenedCheckProtocol	proc	far	uses bx, cx, dx, di, bp, es
	.enter

EC <	call	AssertIsGenDocument					>

	call	OLDocumentGetFileHandle		;bx = file handle

	sub	sp, size ProtocolNumber
	mov	di, sp
	segmov	es, ss
	mov	cx, size ProtocolNumber
	mov	ax, FEA_PROTOCOL
	call	FileGetHandleExtAttributes
		CheckHack <offset PN_major eq 0 and offset PN_minor eq 2>
	pop	bx		; bx <- major #
	pop	bp		; bp <- minor #
	jc	doneGood			; => file w/o extended
						;  attributes, so we assume
						;  it's ok

	; if file's protocol is 0.0, assume it's ok, as it implies we're not
	; using protocols...

	mov	ax, bx
	or	ax, bp
	jz	doneGood

	; get protocol from document control

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL
	push	bp
	call	GenCallParent		;cx, dx = protocol
	pop	bp

	; if the protocol in the document control is 0.0, allow opening of
	; all documents, and the application takes responsibility.

	tst	dx		; minor 0?
	jnz	checkProtocol	; no -- check
	jcxz	doneGood	; branch if major also 0
checkProtocol:

	cmp	cx, bx
	ja	appMoreRecentNotCompat
	LONG jb	docMoreRecent

	; compare minor numbers

	cmp	dx, bp
	ja	appMoreRecentCompat
	LONG jb	docMoreRecent

	; no error

doneGood:
	clc
done:
	.leave
	ret

	; the application has a more recent and the file is not compatible

appMoreRecentNotCompat:
	clr	di
	mov	ax, HINT_GEN_DOCUMENT_CONTROL_NO_PROGRESS_DIALOG_ON_UPDATE_MAJOR
	call	ObjVarFindData
	jc	skipProgress
	call	DisplayProtoProgress
skipProgress:
	mov	cx, MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
	jmp	updateCommon

appMoreRecentCompat:
	clr	di
	mov	ax, HINT_GEN_DOCUMENT_CONTROL_PROGRESS_DIALOG_ON_UPDATE_MINOR
	call	ObjVarFindData
	jnc	skipProgress2
	call	DisplayProtoProgress
skipProgress2:
	mov	cx, MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT

updateCommon:
	call	OLDocumentGetFileHandle
	call	VMGetAttributes
	push	ax
	mov	ax, (mask VMA_NOTIFY_DIRTY) shl 8
	call	VMSetAttributes
	mov_tr	ax, cx
	call	ObjCallInstanceNoLock
	mov_tr	cx, ax				; save proto-change flag
	pop	ax
	pushf
	test	al, mask VMA_NOTIFY_DIRTY
	jz	10$
	mov	ax, mask VMA_NOTIFY_DIRTY
	call	VMSetAttributes
10$:
	popf

	call	BringDownProtoProgress
	jc	convertError
	jcxz	noProtoChange

	call	OLDocumentGetFileHandle			;bx = file
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL
	push	bp
	call	GenCallParent			;cx, dx = protocol
	pop	bp
	push	dx
	push	cx
	segmov	es, ss
	mov	di, sp				;es:di = buffer
	mov	ax, FEA_PROTOCOL
	mov	cx, size ProtocolNumber
	call	FileSetHandleExtAttributes
	lahf
	add	sp, size ProtocolNumber
	sahf
	jc	saveError

noProtoChange:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE
	call	ObjCallInstanceNoLock
saveError:
	mov	ax, SDBT_FILE_SAVE_ERROR
	jmp	done

convertError:
	mov	ax, SDBT_FILE_OPEN_APP_MORE_RECENT_THAN_DOC
doneCarrySet:
	stc
	jmp	done

	; if document has a more recent protocol than the application, so
	; just return an error

docMoreRecent:
	mov	ax, SDBT_FILE_OPEN_DOC_MORE_RECENT_THAN_APP
	jmp	doneCarrySet

FileOpenedCheckProtocol	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGainedModelExcl -- MSG_META_GAINED_MODEL_EXCL
						for OLDocumentClass

DESCRIPTION:	Notification that this is now the target document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_GAINED_DOC_EXCL

RETURN:

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@
OLDocumentGainedModelExcl	method dynamic OLDocumentClass,
						MSG_META_GAINED_MODEL_EXCL

	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GDI_attrs, mask GDA_CLOSING
	jnz	done

	ornf	ds:[bx].GDI_attrs, mask GDA_MODEL

	; update UI stuff

	mov	bx, 1					;not losing target
	call	SendCompleteUpdateToDC

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_PROCESS_UNDO_SET_CONTEXT
	call	SendUndoMessage
done:
	ret

OLDocumentGainedModelExcl	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendCompleteUpdateToDC

DESCRIPTION:	Send update (via MSG_OLDG_UPDATE_UI) to parent

CALLED BY:	INTERNAL

PASS:
	bx - 0 if losing target
	*ds:si - GenDocument

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SendCompleteUpdateToDC	proc	far

	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

EC <	call	AssertIsGenDocument					>

	push	bx
	call	SendNotificationToDC
	pop	bx

	sub	sp, size DocumentFileChangedParams
	mov	bp, sp

	; assume losing target

	clr	ax
SBCS <	mov	ss:[bp].DFCP_name, al					>
DBCS <	mov	{wchar}ss:[bp].DFCP_name, ax				>
SBCS <	mov	ss:[bp].DFCP_path, al					>
DBCS <	mov	{wchar}ss:[bp].DFCP_path, ax				>
	mov	ss:[bp].DFCP_diskHandle, ax
	clrdw	ss:[bp].DFCP_display, ax
	clrdw	ss:[bp].DFCP_document, ax
	tst	bx
	jz	sendit

	; fetch the file name itself, w/o leading path

	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_NAME
	mov	cx, ss
	lea	dx, ss:[bp].DFCP_name
	call	ObjCallInstanceNoLock		;get name in cx:dx (ss:bp)

	; now fetch the path

	push	bp
	mov	ax, MSG_GEN_PATH_GET
	mov	dx, ss
	lea	bp, ss:[bp].DFCP_path
	mov	cx, size DFCP_path
	call	ObjCallInstanceNoLock		;get full name & disk
	; XXX: check for error

	pop	bp

	mov	ss:[bp].DFCP_diskHandle, cx

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	call	GenCallParent			;cx:dx = display
	jcxz	noDisplay
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GDI_display
noDisplay:
	movdw	ss:[bp].DFCP_display, cxdx

	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].DFCP_document, axsi

sendit:
	mov	ax, MSG_OLDG_FILE_CHANGED
	call	GenCallParent

	add	sp, size DocumentFileChangedParams

	pop	di
	call	ThreadReturnStackSpace

	ret

SendCompleteUpdateToDC	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentRemoveConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a connection from a document.

CALLED BY:	(INTERNAL) OLDocumentSendCloseAck
       		MSG_META_IACP_LOST_CONNECTION
PASS:		*ds:si	= document object
		bp	= IACPConnection (0 = user)
RETURN:		nothing
DESTROYED:	di
SIDE EFFECTS:	object is removed and nuked if no more interest in it

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/92 	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentRemoveConnection method OLDocumentClass, MSG_META_IACP_LOST_CONNECTION
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	tst	bp
	jz	noTrivialReject
	tst	ds:[di].OLDI_iacpEngConnects	; could this possibly mean us?
	jz	done
noTrivialReject:
	call	RemoveConnection
done:
	ret

OLDocumentRemoveConnection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentRegisterUnregisterCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Co-routine to do most of the work of registering or
		unregistering a document.

CALLED BY:	(INTERNAL) OLDocumentRegisterOpenDoc,
			   OLDocumentUnregisterDoc
PASS:		*ds:si	= GenDocument
		Nothing pushed on the stack.
		Caller must be a far routine
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	see below

PSEUDO CODE/STRATEGY:
		This routine saves and loads up all the necessary registers,
		then calls its caller back to perform the actual
		registration or unregistration. When the caller returns back
		to us, we return for it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentRegisterUnregisterCommon proc	near
.warn -unref_local
passedBP	local	word	push bp	; cheap way to get at the return address
.warn @unref_local
	uses	ax, bx, cx, dx, si
	.enter
	pushf
	call	OLDocumentGetID		; ax, cxdx <- file ID
	clr	bx
	call	GeodeGetAppObject	; ^lbx:si <- server (app) object
	push	cs
	call	{nptr.near}ss:[bp+2]	; call back our (far) caller

	mov	{nptr.near}ss:[bp+2], offset farRet
					; change our return address to be that
					;  of a far return, so we can return
					;  to our caller's caller w/o destroying
					;  any registers or flags
	popf
	.leave
	ret
farRet:
	retf
OLDocumentRegisterUnregisterCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentRegisterOpenDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a document with IACP, using the app object for
		the current process as the server object.

CALLED BY:	(INTERNAL) OLDocumentNew, OLDocumentOpen,
       		OLDocumentPhysicalSaveAs
PASS:		*ds:si	= GenDocument
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentRegisterOpenDoc proc	far
	call	OLDocumentRegisterUnregisterCommon
	call	IACPRegisterDocument
	ret
OLDocumentRegisterOpenDoc endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentUnregisterDoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister a document with IACP.

CALLED BY:	(INTERNAL) OLDocumentPhysicalSaveAs,
			   OLDocumentPhysicalClose
PASS:		*ds:si	= GenDocument
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentUnregisterDoc		proc	far
	call	OLDocumentRegisterUnregisterCommon
	call	IACPUnregisterDocument
	ret
OLDocumentUnregisterDoc		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentGetID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the ID for the current file.

CALLED BY:	(INTERNAL) OLDocumentRegisterOpenDoc,
			   OLDocumentUnregisterDoc
PASS:		*ds:si	= GenDocument
RETURN:		ax	= disk handle
		cxdx	= file id
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentGetID proc	near
		uses	ds, di, es, bp, si, bx
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].OLDocument_offset
		
		tst	ds:[di].OLDI_disk
		jz	figureItOut
		mov	ax, ds:[di].OLDI_disk
		movdw	cxdx, ds:[di].OLDI_id
		jmp	done

figureItOut:
		call	OLDocumentGetFileHandle	; bx <- file handle
	;
	; Allocate room for the 6 bytes that make up the id
	; 
		sub	sp, size word + size FileID
		mov	di, sp
	;
	; Allocate room for the two FileExtAttrDescs and fill them in.
	; Disk handle comes back in low word, with file ID in high 2 words
	; 
	; 
		sub	sp, 2 * size FileExtAttrDesc
		mov	bp, sp
		mov	ss:[bp+0*FileExtAttrDesc].FEAD_attr, FEA_DISK
		movdw	ss:[bp+0*FileExtAttrDesc].FEAD_value, ssdi
		mov	ss:[bp+0*FileExtAttrDesc].FEAD_size, size word
		inc	di
		inc	di
		
		mov	ss:[bp+1*FileExtAttrDesc].FEAD_attr, FEA_FILE_ID
		movdw	ss:[bp+1*FileExtAttrDesc].FEAD_value, ssdi
		mov	ss:[bp+1*FileExtAttrDesc].FEAD_size, size FileID
	;
	; Get the extended attrs for the data file.
	; 
		mov	di, bp
		segmov	es, ss
		mov	ax, FEA_MULTIPLE
		mov	cx, 2
		call	FileGetHandleExtAttributes
EC <		ERROR_C	CANT_GET_FILE_ID_FOR_OPEN_FILE			>
	;
	; Clear off the FEADs
	; 
		lea	sp, ss:[bp+2*size FileExtAttrDesc]
	;
	; Pop the return values off the stack.
	; 
		pop	ax
		popdw	cxdx
	;
	; Save for unregister and for search.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].OLDocument_offset
		mov	ds:[di].OLDI_disk, ax
		movdw	ds:[di].OLDI_id, cxdx
done:
		.leave
		ret
OLDocumentGetID endp

DocNewOpen ends
DocNew segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentNew -- MSG_GEN_DOCUMENT_NEW for OLDocumentClass

DESCRIPTION:	Create a new file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_NEW

	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

RETURN:
	carry - set if error
	bp - unchnaged
	ax - file handle

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentNew	method dynamic OLDocumentClass, MSG_GEN_DOCUMENT_NEW

	call	OLDocMarkBusy

	mov	ax, GDO_NEW
	call	OLDocSetOperation

	; generate name if needed

	mov	cx, ss:[bp].DCP_docAttrs
	test	cx, mask GDA_UNTITLED
	jz	setPath

if CUSTOM_DOCUMENT_PATH
	;
	; If we have a valid disk handle or path, use it, else use
	; SP_DOCUMENT.  Allows GenDocumentControl to specify non-standard
	; directory via ATTR_GEN_PATH_DATA.
	;
	tst	ss:[bp].DCP_diskHandle
	jnz	setPath
	tst	{TCHAR}ss:[bp].DCP_path[0]
	jnz	setPath
endif ; CUSTOM_DOCUMENT_PATH

	; untitleds always go in SP_DOCUMENT

if UNTITLED_DOCS_ON_SP_TOP
	mov	ss:[bp].DCP_diskHandle, SP_TOP
else
	mov	ss:[bp].DCP_diskHandle, SP_DOCUMENT
endif
	mov	{TCHAR}ss:[bp].DCP_path[0], 0

setPath:
	call	PushAndSetPath
	jc	handleError
	test	cx, mask GDA_UNTITLED
	mov	cx, -1
	jz	tryCreate

	; test for user set empty file

	test	ss:[bp].DCP_flags, mask DOF_FORCE_REAL_EMPTY_DOCUMENT
	jnz	forceEmptyDoc
	call	CheckForUserEmptyFile
	LONG jnc copeWithIACP
forceEmptyDoc:
	clr	cx				;pass count = 0

createLoop:

	mov	dx, ss
	mov	ax, MSG_GEN_DOCUMENT_GENERATE_NAME_FOR_NEW
	call	ObjCallInstanceNoLock		;returns ss:bp = name
	cmp	cx, GEN_DOCUMENT_GENERATE_NAME_CANCEL
	jz	doneError
	mov	ax, SDBT_FILE_NEW_CANNOT_CREATE_TEMP_NAME
	cmp	cx, GEN_DOCUMENT_GENERATE_NAME_ERROR
	jz	error

tryCreate:

if ENFORCE_DOCUMENT_HANDLES
	; check available handles
	call	CheckHandles
	mov	ax, SDBT_CANT_CREATE_TOTAL_FILES_TOO_LARGE	; assume error
	jc	haveError
endif

	; create the file

	push	cx
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CREATE
	call	ObjCallInstanceNoLock
	pop	cx
	jnc	noError

	; error condition

handleError:
	call	ConvertErrorCode

	; error -- try another name

	cmp	ax, ERROR_ACCESS_DENIED
	jz	tryAgain
	cmp	ax, ERROR_SHARING_VIOLATION
	je	tryAgain
	cmp	ax, ERROR_FILE_EXISTS
	jz	tryAgain

;	If there is a non-VM file with the same name, then try opening it
;	again - 10/15/93 atw

	cmp	ax, ERROR_FILE_FORMAT_MISMATCH
	jz	tryAgain

	cmp	ax, ERROR_WRITE_PROTECTED
	jnz	notWriteProtected

	mov	ax, SDBT_FILE_NEW_WRITE_PROTECTED
haveError::
	call	FarCallStandardDialogSS_BP
	cmp	ax, IC_YES
	jnz	doneError
	jmp	createLoop

notWriteProtected:
	mov	bx, ax				;bx = error code
	mov	ax, SDBT_FILE_NEW_TOO_MANY_OPEN_FILES
	cmp	bx, ERROR_TOO_MANY_OPEN_FILES
	jz	error
	mov	ax, SDBT_FILE_NEW_INSUFFICIENT_DISK_SPACE
	cmp	bx, ERROR_SHORT_READ_WRITE
	jz	error
	mov	ax, SDBT_FILE_ILLEGAL_NAME
	cmp	bx, ERROR_INVALID_NAME
	jz	error
	mov	ax, SDBT_FILE_NEW_ERROR
error:
	call	FarCallStandardDialogSS_BP
doneError:
	stc
	jmp	done

tryAgain:
	call	GetDocOptions
	test	ax, mask DCO_TRANSPARENT_DOC
	jz	notTransparentError
	mov	ax, SDBT_TRANSPARENT_NEW_FILE_EXISTS
	call	FarCallStandardDialogSS_BP
notTransparentError:
	inc	cx
	jmp	createLoop

noError:

	; save name and file handle (ax = file handle)

	call	StoreNewDocumentName
	call	CreateNewFileCommon
	jc	done
copeWithIACP:

	mov	ax, ss:[bp].DCP_connection
	cmp	ax, -1
	je	grabModel
	call	OLDocumentAddConnection
grabModel:
	call	OLDocumentGrabModelIfAppropriate
	call	OLDocumentGetFileHandle		;ax = file handle
	clc					;no error

done:
	call	OLDocClearOperation		;preserves carry
	call	FilePopDir			;preserves carry
exit:
	call	OLDocMarkNotBusy
	Destroy	cx, dx
	ret

OLDocumentNew	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckForUserEmptyFile

DESCRIPTION:	If a user has set an empty file then make a duplicate of it

CALLED BY:	OLDocumentNew

PASS:
	*ds:si - document

RETURN:
	carry - clear if empty file duplicated successfully

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/21/91		Initial version

------------------------------------------------------------------------------@
CheckForUserEmptyFile	proc	near	uses bp
	.enter

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_UI_FEATURES
	call	GenCallParent				;ax = features
	test	ax, mask GDCF_SUPPORTS_USER_SETTABLE_EMPTY_DOCUMENT
	stc
	LONG jz	done

	; make a DocumentCommonParams structure and fill it in

	sub	sp, size DocumentCommonParams
	mov	bp, sp

	push	si, ds
	call	FilePushDir
	call	SetTemplateDir
	segmov	ds, ss
	lea	si, ss:[bp].DCP_path
	mov	cx, size DCP_path
	call	FileGetCurrentPath
	mov	ss:[bp].DCP_diskHandle, bx
	call	FilePopDir

	mov	bx, handle defaultDocumentName
	call	MemLock
	mov	ds, ax
	mov	si, ds:[defaultDocumentName]
	ChunkSizePtr	ds, si, cx
	segmov	es, ss
	lea	di, ss:[bp].DCP_name
	rep	movsb
	call	MemUnlock
	pop	si, ds

	mov	ss:[bp].DCP_flags, 0
	mov	ss:[bp].DCP_docAttrs, mask GDA_READ_ONLY
	call	PushAndSetPath		; push to dir holding the thing,
	jc	10$			;  to be consistent
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_OPEN
	call	ObjCallInstanceNoLock
10$:
	call	FilePopDir		; pop to previous dir (nukes nothing)
	jc	doneFreeParams

	call	DocumentCloseOthers

	call	StoreNewDocumentName

	; make sure that the default document has the correct protocol

	call	FileOpenedCheckProtocol
	jnc	noProtoError
	call	FarCallStandardDialogSS_BP
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CLOSE
	call	ObjCallInstanceNoLock
	pop	bp
	stc
	jmp	doneFreeParams
noProtoError:

	call	CopyFromTemplate			;returns carry
	mov	ax, MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	call	ObjCallInstanceNoLock
	call	OLDocumentGrabModelIfAppropriate
	call	StartAutoSave
	clc

doneFreeParams:
	lahf
	add	sp, size DocumentCommonParams
	sahf

done:

		
	.leave
	ret

CheckForUserEmptyFile	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateNewFileCommon

DESCRIPTION:	Common code for new file created

CALLED BY:	OLDocumentNew, OLDocumentOpen

PASS:
	*ds:si - document object

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
CreateNewFileCommon	proc	far	uses bp
	.enter

EC <	call	AssertIsGenDocument					>

	; if a DB or VM file then do special setup

	call	OLDCNewVMFile

	; initialize the document file

	mov	ax, MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
	call	ObjCallInstanceNoLock
	jc	error

	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE
	call	ObjCallInstanceNoLock
	jc	newFileError

	; Close any clean, untitled documents

	call	DocumentCloseOthers

	call	StartAutoSave

	mov	ax, MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	call	ObjCallInstanceNoLock
	clc
	jmp	done

newFileError:
	mov	cx, SDBT_FILE_NEW_INSUFFICIENT_DISK_SPACE
	cmp	ax, ERROR_SHORT_READ_WRITE
	je	haveNewFileError
	cmp	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
	je	haveNewFileError
	mov	cx, SDBT_FILE_NEW_ERROR
haveNewFileError:
	mov_tr	ax, cx
	call	FarCallStandardDialogDS_SI
error:
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_CLOSE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_DELETE
	call	ObjCallInstanceNoLock
	stc
done:
	.leave
	ret

CreateNewFileCommon	endp

if ENFORCE_DOCUMENT_HANDLES
CheckHandles	proc	far
	uses	cx, dx, bp, ds, si
	.enter

	;
	; Set up GetVarDataParams
	;
	push	ax				;buffer
	mov	bp, sp
	mov	ax, ATTR_GEN_DOCUMENT_GROUP_DOCUMENT_HANDLES
	push	ax				;GVDP_dataType
	mov	ax, size word
	push	ax				;GVDP_bufferSize
	push	ss, bp				;GVDP_buffer
	;
	; See if the ATTR exists on the parent (GenDocumentGroupClass)
	;
	mov	ax, MSG_META_GET_VAR_DATA
	mov	bp, sp
	mov	dx, (size GetVarDataParams)
	call	GenCallParent
	add	sp, (size GetVarDataParams)
	pop	cx				;cx = handle count
	cmp	ax, -1				;-1 if not found
	jne	gotCount
	;
	; try .ini file
	;
	mov	cx, cs
	mov	ds, cx
	mov	si, offset documentHandlesCat
	mov	dx, offset documentHandlesKey
	call	InitFileReadInteger		; C clear if found
	mov	cx, ax
	jnc	gotCount
	;
	; else, use default value
	;
	mov	cx, OL_DOCUMENT_MINIMUM_HANDLES
gotCount:
	mov	ax, SGIT_NUMBER_OF_FREE_HANDLES
	call	SysGetInfo			; ax = free handles
	cmp	ax, cx				; C set if free < needed
done:
	.leave
	ret
CheckHandles	endp

documentHandlesCat	char	"docControlOptions",0
documentHandlesKey	char	"documentHandles",0
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	OLDCNewVMFile

DESCRIPTION:	If the newly created file is a VM file, set the header

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocument

RETURN:
	ax = file handle

DESTROYED:
	ax, bx, cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocExtAttrs	struct		; extended attributes we set for a new file
    OLDEA_protocol	ProtocolNumber
    OLDEA_release	ReleaseNumber
    OLDEA_token		GeodeToken
    OLDEA_creator	GeodeToken
OLDocExtAttrs	ends

OLDCNewVMFile	proc	near	uses si, bp
	.enter
	class	OLDocumentClass

EC <	call	AssertIsGenDocument					>

	call	OLDocumentGetFileHandle		;bx = file handle

	call	GetParentAttrs			;flags = VM|DB
	jnz	setVMAttributes

	test	ax, mask GDGA_NATIVE
	jnz	setExtAttrs			;not native, so set up
						; regular extended attrs
	jmp	done

setVMAttributes:
	call	GetUIParentAttrs		;ax = attributes

	; test for backup mode requested

	mov	cx, mask VMA_SYNC_UPDATE
	test	ax, mask GDCA_SUPPORTS_SAVE_AS_REVERT
	jz	noBackup
	ornf	cl, mask VMA_BACKUP
noBackup:

	; test for multi-thread access

	call	GetMultiThreadAccess
	jc	singleThread			;multi-thread, so jump
	or	cx, mask VMA_SINGLE_THREAD_ACCESS
singleThread:

	; test for automatic dirty requested

	call	GetParentAttrs
	test	ax, mask GDGA_AUTOMATIC_DIRTY_NOTIFICATION
	jz	noAutoDirty
	ornf	cl, mask VMA_NOTIFY_DIRTY
noAutoDirty:
	test	ax, mask GDGA_VM_FILE_CONTAINS_OBJECTS
	jz	noObjects
	ornf	cl, VMA_OBJECT_ATTRS
noObjects:
	mov_tr	ax, cx
	call	VMSetAttributes

	; if dirty notification enabled, set the dirty limit to the default

	test	al, mask VMA_NOTIFY_DIRTY
	jz	setExtAttrs

	clr	cx
	call	VMSetDirtyLimit

	; set the protocol number of the document (and check for protocol
	; errors)

setExtAttrs:
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_PROTOCOL
	call	GenCallParent			;cx, dx = protocol
	
	sub	sp, size OLDocExtAttrs
	mov	bp, sp				;ss:bp <- buffer for new
						; attrs
	mov	ss:[bp].OLDEA_protocol.PN_major, cx
	mov	ss:[bp].OLDEA_protocol.PN_minor, dx

	segmov	es, ss
	push	bx				;save VM file handle

	; get release # of application

	mov	bx, ds:[LMBH_handle]
	call	MemOwner			;bx = owner

	lea	di, ss:[bp].OLDEA_release
	mov	ax, GGIT_GEODE_RELEASE
	call	GeodeGetInfo

	; get the token and creator

	mov	cx, es
	lea	dx, ss:[bp].OLDEA_token
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_TOKEN
	push	bp
	call	GenCallParent
	pop	bp

	lea	dx, ss:[bp].OLDEA_creator
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_CREATOR
	push	bp
	call	GenCallParent
	pop	bp

	pop	bx				; bx <- file handle

	;
	; Now set up the array of extended attribute descriptors for the
	; actual setting.
	; 
	sub	sp, 4 * size FileExtAttrDesc
	mov	di, bp
	mov	bp, sp
	
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_attr, FEA_PROTOCOL
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_protocol
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][0*FileExtAttrDesc].FEAD_size, size OLDEA_protocol

	mov	ss:[bp][1*FileExtAttrDesc].FEAD_attr, FEA_RELEASE
	mov	ss:[bp][1*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_release
	mov	ss:[bp][1*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][1*FileExtAttrDesc].FEAD_size, size OLDEA_release

	mov	ss:[bp][2*FileExtAttrDesc].FEAD_attr, FEA_TOKEN
	mov	ss:[bp][2*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_token
	mov	ss:[bp][2*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][2*FileExtAttrDesc].FEAD_size, size OLDEA_token

	mov	ss:[bp][3*FileExtAttrDesc].FEAD_attr, FEA_CREATOR
	mov	ss:[bp][3*FileExtAttrDesc].FEAD_value.segment, ss
	lea	ax, ss:[di].OLDEA_creator
	mov	ss:[bp][3*FileExtAttrDesc].FEAD_value.offset, ax
	mov	ss:[bp][3*FileExtAttrDesc].FEAD_size, size OLDEA_creator

	;
	; Finally, set the attributes for the file.
	; 
	mov	cx, 4
	mov	di, bp
	mov	ax, FEA_MULTIPLE
	call	FileSetHandleExtAttributes

	;
	; Clear the stack of the descriptors and the attributes themselves.
	; 
	add	sp, 4*size FileExtAttrDesc + size OLDocExtAttrs
done:
	mov	ax, bx				;return file handle in ax

	.leave
	ret

OLDCNewVMFile	endp

GetMultiThreadAccess	proc	near
	uses	cx, dx, bp
	.enter

	;
	; Set up GetVarDataParams
	;
	mov	ax, ATTR_GEN_DOCUMENT_GROUP_ALLOW_MULTIPLE_WRITE_ACCESS
	push	ax				;GVDP_dataType
	clr	ax
	push	ax				;GVDP_bufferSize
	push	ax, ax				;GVDP_buffer
	;
	; See if the ATTR exists on the parent (GenDocumentGroupClass)
	;
	mov	ax, MSG_META_GET_VAR_DATA
	mov	bp, sp
	mov	dx, (size GetVarDataParams)
	call	GenCallParent
	add	sp, (size GetVarDataParams)
	cmp	ax, -1				;if not found,
	je	done				;...return carry clear
	stc
done:
	.leave
	ret
GetMultiThreadAccess	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyFromTemplate

DESCRIPTION:	Copy document to template file

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	ss:bp - DocumentCommonParams

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/21/91		Initial version

------------------------------------------------------------------------------@
CopyFromTemplate	proc	far

retryTemplate:
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE
	call	ObjCallInstanceNoLock
	pop	bp
	jnc	noError
	tst	ax
	jz	done

	mov	cx, offset CallStandardDialogDS_SI
	call	HandleSaveError
	jnc	retryTemplate

	call	ConvertErrorCode
done:
	stc
	ret

noError:
	clr	ax		; set nothing
	mov	bx, mask GDA_READ_ONLY or mask GDA_READ_WRITE or \
		    mask GDA_SHARED_SINGLE or mask GDA_SHARED_MULTIPLE or \
		    mask GDA_CLOSING	; clear all these
	call	OLDocSetAttrs
	clc
	ret

CopyFromTemplate	endp

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGenerateNameForNew --
			MSG_GEN_DOCUMENT_GENERATE_NAME_FOR_NEW for
						OLDocumentClass

DESCRIPTION:	Generate a file name

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - MSG_GEN_DOCUMENT_GENERATE_NAME_FOR_NEW
	cx - number of times that this method has been called trying to
	     generate a unique name (from 0)
	dx:bp - DocumentCommonParams buffer

RETURN:
	cx - GEN_DOCUMENT_GENERATE_NAME_ERROR if error,
	     GEN_DOCUMENT_GENERATE_NAME_CANCEL to cancel, else unchanged
	dx:bp - new file name encoded appropriately

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
OLDocumentGenerateNameForNew	method dynamic OLDocumentClass,
					MSG_GEN_DOCUMENT_GENERATE_NAME_FOR_NEW
					uses dx
	.enter


	; if in transparent mode then ask the user
	push	es
	segmov	es, dgroup, ax			;es = dgroup	
	test	es:[docControlOptions], mask DCO_TRANSPARENT_DOC
	pop	es
	jz	notTransparent

	andnf	ss:[bp].DCP_docAttrs, not mask GDA_UNTITLED

	; make dialog box a child of the application

	call	GetUIParentAttrs
	mov	bx, handle FileNewSummons
	mov	si, offset FileNewSummons
	call	UserCreateDialog

	; set the text object appropriate fir the file type

	mov	si, offset FileNewTextEdit
	call	SetTextObjectForFileType

	; do it

	mov	si, offset FileNewSummons
	call	UserDoDialog

	; get the text from the text object (dx:bp = DocumentCommonParams)

	push	ax, cx, bp			;save return value from dialog
	mov	si, offset FileNewTextEdit
	mov	cx, size DCP_name
	add	bp, offset DCP_name
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax, cx, bp			;get return value from dialog

	; free the dialog

	mov	si, offset FileNewSummons
	call	UserDestroyDialog

	cmp	ax, IC_APPLY
	jz	toDone
	mov	cx, GEN_DOCUMENT_GENERATE_NAME_CANCEL	;indicate cancel
toDone:
	jmp	done

notTransparent:
	cmp	cx, DOCUMENT_MAX_GENERATED_NAMES
	jb	noError
	mov	cx, GEN_DOCUMENT_GENERATE_NAME_ERROR
	stc
	jmp	done
noError:

	push	cx

	push	cx				;save #

	mov	cx, dx
	mov	dx, bp
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DEFAULT_NAME
	call	GenCallParent			;cx:dx = name, ax = attrs

	mov_trash	bx, ax			;bx = attrs

	segmov	es, cx
	mov	di, dx
	CheckHack	<offset DCP_name eq 0>	;es:di = name
	mov	cx, length DCP_name
	clr	ax
	LocalFindChar				;find end of name
	LocalPrevChar esdi			;es:di = null terminator
	pop	cx

	; es:di = null terminator at end of name

	jcxz	doneGood

	test	bx, mask GDGA_VM_FILE		;if VM file then use space
	jz	noSeparator			;as a seperator
	LocalLoadChar ax, ' '
	LocalPutChar esdi, ax
noSeparator:

	; convert cx to ascii, get 10's digit

	cmp	cx, 10
	jb	noTens

	LocalLoadChar ax, '0'
10$:
	inc	al
	sub	cx, 10
	cmp	cx, 10
	jae	10$
	LocalPutChar esdi, ax
noTens:

	mov	ax, cx
	add	al, '0'
	LocalPutChar esdi, ax
	clr	ax
	LocalPutChar esdi, ax

doneGood:
	pop	cx
	clc					;return no error

done:
	Destroy	ax
	.leave
	ret

OLDocumentGenerateNameForNew	endm

DocNew ends
