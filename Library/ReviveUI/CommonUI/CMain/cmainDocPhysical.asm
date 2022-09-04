COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainDocPhysical.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:
	MSG_GEN_DOCUMENT_PHYSICAL_***

	$Id: cmainDocPhysical.asm,v 1.68 97/01/03 15:12:40 ptrinh Exp $

------------------------------------------------------------------------------@

DocNewOpen segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentComputeAccessFlags --
		MSG_GEN_DOCUMENT_COMPUTE_ACCESS_FLAGS for OLDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message
	ss:bp - DocumentCommonParams

RETURN:
	al - VMAccessFlags (or FileAccessFlags)
	ah - destroyed
	cx, dx, bp - unchanged

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 5/91		Initial version

------------------------------------------------------------------------------@
OLDocumentComputeAccessFlags	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_COMPUTE_ACCESS_FLAGS

	call	GetParentAttrs
	mov_trash	di, ax			; di = GDGA_*
	call	GetUIParentAttrs
	mov	bx, ax				; bx = GDCI_*

	and	ax, mask GDCA_MODE
	test	bx, mask GDCA_VM_FILE
	jz	dosFile

	; its a VM file

	tst	ax
	jz	viewerMode
	cmp	ax, GDCM_SHARED_SINGLE shl offset GDCA_MODE
	mov	al, mask VMAF_DISALLOW_SHARED_MULTIPLE
	jz	sharedCommon
	clr	al			;no flags if SHARED_MULTIPLE
sharedCommon:

	; look for read-only or read-write

	test	ss:[bp].DCP_docAttrs, mask GDA_READ_ONLY
	jz	notReadOnly
	or	al, mask VMAF_FORCE_READ_ONLY
notReadOnly:

	test	ss:[bp].DCP_docAttrs, mask GDA_READ_WRITE
	jz	notReadWrite
	or	al, mask VMAF_FORCE_READ_WRITE
notReadWrite:

	test	bx, mask GDCA_FORCE_DEMAND_PAGING
	jnz	keepDemandPaging
	;
	; Turn off demand paging for all document control documents.
	;
	or	al, mask VMAF_NO_DEMAND_PAGING
keepDemandPaging:
	ret

viewerMode:
	mov	al, mask VMAF_FORCE_READ_ONLY or \
					mask VMAF_DISALLOW_SHARED_MULTIPLE
	jmp	sharedCommon

dosFile:
	tst	ax
	jz	dosViewer
	cmp	ax, GDCM_SHARED_SINGLE shl offset GDCA_MODE
	mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_WRITE>
	jz	dosCommon
	mov	al, FileAccessFlags <FE_NONE, FA_READ_WRITE>
dosCommon:

	; look for read-only or read-write

	test	ss:[bp].DCP_docAttrs, mask GDA_READ_ONLY
	jz	notDosReadOnly
	and	al, not mask FAF_MODE
	or	al, FA_READ_ONLY shl offset FAF_MODE
notDosReadOnly:

	test	ss:[bp].DCP_docAttrs, mask GDA_READ_WRITE
	jz	notDosReadWrite
	and	al, not mask FAF_MODE
	or	al, FA_READ_WRITE shl offset FAF_MODE
notDosReadWrite:

	test	bx, mask GDCA_DOS_FILE_DENY_WRITE
	jz	notDosDenyWrite
	and	al, not mask FAF_EXCLUDE
	or	al, FE_DENY_WRITE shl offset FAF_EXCLUDE
notDosDenyWrite:
	ret

dosViewer:
	mov	al, FileAccessFlags <FE_NONE, FA_READ_ONLY>
	jmp	dosCommon

OLDocumentComputeAccessFlags	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalOpen -- MSG_GEN_DOCUMENT_PHYSICAL_OPEN
		for OLDocumentClass

DESCRIPTION:	Really open a file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	ss:bp - DocumentCommonParams

RETURN:
	carry - set if error
	ax - file handle (if successful) or error code (if error)
	cx - non-zero if template document opened
	dx - non-zero if a new file was created
	bp - unchanged

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/22/91		Initial version

------------------------------------------------------------------------------@


OLDocumentPhysicalOpen	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_OPEN

	call	GetParentAttrs
	mov_trash	cx, ax			;cx = attrs

	mov	ax, MSG_GEN_DOCUMENT_COMPUTE_ACCESS_FLAGS
	call	ObjCallInstanceNoLock

	push	ds
	segmov	ds, ss				;ds:dx = filename
	lea	dx, ss:[bp].DCP_name

	mov	ah, VMO_OPEN 			;assume no create
	test	ss:[bp].DCP_flags, mask DOF_CREATE_FILE_IF_FILE_DOES_NOT_EXIST
	jz	10$
	mov	ah, VMO_CREATE
10$:

	test	cx, mask GDGA_VM_FILE
	jz	notVM

	clr	cx				;use default compression
	call	VMOpen
	pop	ds
	jc	done
	
	; ax = VMStatus, bx = file handle

	; check for wrong file type

	cmp	ax, VM_CREATE_OK
	jz	noFileTypeCheck
	call	CheckFileType
	jc	closeError
noFileTypeCheck:

	; check for a password

	call	CheckPassword
	jnc	passwordOK
closeError:
	push	ax
	mov	al, FILE_NO_ERRORS
	call	VMClose
	pop	ax
	stc
	jmp	done
passwordOK:

	clr	cx				;assume no template
	mov	dx, 1				;assume file created
	cmp	ax, VM_CREATE_OK
	jz	notReadOnly
	dec	dx

	cmp	ax, VM_OPEN_OK_TEMPLATE
	jnz	notTemplate
	dec	cx			; flag template opened
	jmp	vmDone
notTemplate:
	cmp	ax, VM_OPEN_OK_READ_WRITE_SINGLE
	jnz	notSharedSingle
	ornf	ss:[bp].DCP_docAttrs, mask GDA_SHARED_SINGLE
notSharedSingle:
	cmp	ax, VM_OPEN_OK_READ_WRITE_MULTIPLE
	jnz	notSharedMultiple
	ornf	ss:[bp].DCP_docAttrs, mask GDA_SHARED_MULTIPLE
notSharedMultiple:

	cmp	ax, VM_OPEN_OK_READ_ONLY
	jnz	notReadOnly
	ornf	ss:[bp].DCP_docAttrs, mask GDA_READ_ONLY
	jmp	vmDone
notReadOnly:
	ornf	ss:[bp].DCP_docAttrs, mask GDA_READ_WRITE

vmDone:

	clc
	mov_trash	ax, bx
done:
	ret

notVM:
		CheckHack	<VMO_OPEN eq 0>	; also relies on AH being only
						; VMO_OPEN, or VMO_CREATE
	test	ah, VMO_CREATE
	jnz	createNormal
	call	FileOpen
	pop	ds
	jc	regularOpen

	mov	bx, ax				; bx = file handle
	call	CheckPassword
	jnc	regularOpen
	push	ax
	clr	ax
	call	FileClose
	pop	ax
	stc

regularOpen:
	mov	cx, 0
	mov	dx, cx
	ret

createNormal:
	mov	ah, FILE_CREATE_NO_TRUNCATE
	test	cx, mask GDGA_NATIVE
	jz	90$
	ornf	ah, mask FCF_NATIVE
90$:
	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate
	pop	ds
	jc	done
	
	; see if the file was actually created. If it's 0 bytes, it was, for
	; all intents and purposes

	mov	bx, ax
	call	FileSize
	or	ax, dx		; (clears carry)
	mov_tr	ax, bx
	jnz	regularOpen	; => file has bytes so it existed before
	
	mov	cx, dx		; cx <- 0 => not template
	dec	dx		; flag file created
	ret

OLDocumentPhysicalOpen	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckPassword

DESCRIPTION:	If the given file has a password then ask the user for it

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	bx - file handle
	ss:bp - DocumentCommonParams

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 7/92		Initial version

------------------------------------------------------------------------------@
CheckPassword	proc	near	uses bx, cx, dx, si, di, bp, ds, es
	test	ss:[bp].DCP_flags, mask DOF_REOPEN
	jz	5$
	ret
5$:

passedAX		local	word	push ax
documentChunk		local	word	push si
if DBCS_PCGEOS
filePassword		local	FILE_PASSWORD_SIZE dup (byte)
userPassword		local	MAX_PASSWORD_SOURCE_LENGTH + 1 dup (wchar)
userEncryptedPassword	local	FILE_PASSWORD_SIZE dup (byte)
else
filePassword		local	FILE_PASSWORD_SIZE dup (char)
userPassword		local	MAX_PASSWORD_SOURCE_SIZE + 1 dup (char)
userEncryptedPassword	local	FILE_PASSWORD_SIZE dup (char)
endif
	.enter

	segmov	es, ss
	lea	di, filePassword
	mov	ax, FEA_PASSWORD
	mov	cx, FILE_PASSWORD_SIZE
	call	FileGetHandleExtAttributes
	jnc	gotPassword
	cmp	ax, ERROR_ATTR_NOT_FOUND
	jz	doneGood
	cmp	ax, ERROR_ATTR_NOT_SUPPORTED
	stc
	jnz	done
doneGood:
	clc
	mov	ax, passedAX
done:
	.leave
	ret


gotPassword:
SBCS <	cmp	{char} es:[di], 0					>
DBCS <	cmp	{wchar} es:[di], 0					>
	jz	doneGood
tryAgain:

if not _REDMOTIF ;----------------------- Not needed for Redwood project
if (not _NIKE) and (not _JEDIMOTIF) ;------------- Not needed for NIKE project
	; duplicate the password dialog and add it as a child of the application

	mov	bx, handle GetPasswordDialog
	mov	si, offset GetPasswordDialog
	call	UserCreateDialog

	; set help file for this dialog to be same as the document

	sub	sp, size FileLongName
	movdw	cxdx, sssp

	push	si, bp				;save dialog, locals
	mov	si, documentChunk		;si = GenDocument
	mov	ax, MSG_META_GET_HELP_FILE
	call	ObjCallInstanceNoLock
	pop	si, bp				;^lbx:si = dialog
	jnc	fixupStack

	mov	ax, MSG_META_SET_HELP_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
fixupStack:
	add	sp, size FileLongName

	; display dialog box to get document password

	call	UserDoDialog
	push	ax				;save response

	; get text from text object

	push	bp
	mov	dx, ss
	lea	bp, userPassword
SBCS <	mov	cx, size userPassword					>
DBCS <	mov	cx, length userPassword					>
	mov	si, offset GetPasswordText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	mov	si, offset GetPasswordDialog
	call	UserDestroyDialog
	pop	ax

	cmp	ax, IC_OK
	mov	ax, 0
	stc
	jnz	done

	; encrypt the password

	push	ds
	segmov	ds, ss
	lea	si, userPassword
	lea	di, userEncryptedPassword
	call	UserEncryptPassword

	; compare passwords

	lea	si, filePassword
	mov	cx, FILE_PASSWORD_SIZE
	repe	cmpsb
	pop	ds
	LONG jz	doneGood

	mov	ax, SDBT_BAD_PASSWORD
	call	CallUserStandardDialog
endif ;(not _NIKE) and (not _JEDIMOTIF) ;--------- Not needed for NIKE project
endif ;not _REDMOTIF ;------------------- Not needed for Redwood project

	jmp	tryAgain			;better not be hit in Redwood


CheckPassword	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckFileType

DESCRIPTION:	Ensure that the opened file has the correct token characters

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	bx - file handle
	ss:bp - DocumentCommonParams

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 7/92		Initial version

------------------------------------------------------------------------------@
CheckFileType	proc	near	uses bx, cx, dx, si, di, bp, ds, es
	test	ss:[bp].DCP_flags, mask DOF_REOPEN
	jz	5$
	ret
5$:

passedAX	local	word	push ax
objToken	local	GeodeToken
fileToken	local	GeodeToken
	.enter

EC <	call	AssertIsGenDocument					>

	push	bp
	mov	cx, ss
	lea	dx, objToken
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_TOKEN
	call	GenCallParent
	pop	bp

	segmov	es, ss
	lea	di, fileToken
	mov	ax, FEA_TOKEN
	mov	cx, size fileToken
	call	FileGetHandleExtAttributes
	jc	done

	segmov	ds, ss
	lea	si, objToken
	mov	cx, size objToken
	repe	cmpsb
	mov	ax, ERROR_FILE_FORMAT_MISMATCH
	stc
	jnz	done

	clc
	mov	ax, passedAX
done:
	.leave
	ret

CheckFileType	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentCreateUIForDocument --
		MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version
	Cassie  10/14/92	Added code to set display block output.

------------------------------------------------------------------------------@
OLDocumentCreateUIForDocument	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT

	; if we have a GenDisplay to duplicate, do so

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	call	GenCallParent
	jcxz	noDisplay

	; duplicate the sucker and store the handle of the duplicated block
	push	cx
	mov	bx, cx

	; Duplicated block needs to be run by the same thread as is running
	; the rest of the UI for this application.  We'll figure this out
	; by fetching the thread running the application object.
	;
	push	bx, si
	clr	bx
	call	GeodeGetAppObject
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo
	pop	bx, si
	mov	cx, ax				; pass thread to run in cx
	clr	ax				; have current geode own block
	call	ObjDuplicateResource		;bx = new block
	pop	cx
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_display, bx

	; add the display to the display control

	push	si
	push	bx, dx				;save display's OD
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY_GROUP
	call	GenCallParent			;cx:dx = display control
	mov	bx, cx
	mov	si, dx				;bx:si = display control
	pop	cx, dx				;cx:dx = display to add
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; set the display usable

	pop	si
	push	si

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, cx				;bx:si = display
	mov	si, dx
	test	ds:[di].OLDI_attrs, mask OLDA_USER_OPENED
	jz	setOutput

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

setOutput:
	; Set the output of the duplicated display block 
	; to be this document 
	;
	mov	cx, ds:[LMBH_handle]
	pop	dx				;^lcx:dx = document 
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, dx				;*ds:si = document

noDisplay:

	mov	ax, MSG_META_DOC_OUTPUT_CREATE_UI_FOR_DOCUMENT
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentCreateUIForDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentAttachUIToDocument --
		MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentAttachUIToDocument	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

	; if we have a view to connect to, connect to it

	mov	di, ds:[LMBH_handle]		;di:bp = data to send to
	mov	bp, si				;SET_CONTENT if view exists
	call	CallSetContent

	mov	ax, MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentAttachUIToDocument	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	CallSetContent

DESCRIPTION:	Handle default UI interaction for document (if any)

CALLED BY:	OLDocumentAttachUIToDocument, OLDocumentDetachUIFromDocument

PASS:
	*ds:si - document object
	di:bp - data to send to view in cx:dx

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
CallSetContent	proc	far
	class	OLDocumentClass

EC <	call	AssertIsGenDocument					>

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_VIEW
	call	GenCallParent
	jcxz	noView

	; if a display exists then use that handle (assume that the view
	; was duplicated along with the display)

	push	di
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_display
	tst	ax
	jz	noDisplay
	mov_trash	cx, ax
noDisplay:
	pop	di

	push	si
	mov	bx, cx				;bx:si = view
	mov	si, dx
	mov	cx, di
	mov	dx, bp				;cx:dx = data
	mov	ax, MSG_GEN_VIEW_SET_CONTENT

	; use MF_CALL to force the set content to complete before we
	; do anything else (like queuing a message to close/delete ourself)

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

noView:

	ret

CallSetContent	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentReadCachedDataFromFile --
		MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentReadCachedDataFromFile	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE

	mov	ax, MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentReadCachedDataFromFile	endm

DocNewOpen	ends

;---

DocNew segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalCreate --
		MSG_GEN_DOCUMENT_PHYSICAL_CREATE for OLDocumentClass

DESCRIPTION:	Really create the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	ss:bp - DocumentCommonParams with DCP_name being the
		name of the file to create and thread's current directory
		already set appropriately.

RETURN:
	carry - set if error
	bp - unchanged
	ax - file handle (if successful) or error code (if error)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/22/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalCreate	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_CREATE

if DC_DISALLOW_SPACES_FILENAME
	;
	; check for trailing or leading spaces
	;
.assert (offset DCP_name eq 0)
	call	CheckSpacesFilename
	jc	exit
endif

	; call correct create routine

	call	GetParentAttrs			;ax = attributes
	mov_trash	bx, ax

	; compute access flags

	mov	ax, MSG_GEN_DOCUMENT_COMPUTE_ACCESS_FLAGS
	call	ObjCallInstanceNoLock		;al = access flags

	segmov	ds, ss				;ds:dx = filename
	lea	dx, ss:[bp].DCP_name

	; assume VM file

	mov	ah, VMO_CREATE_ONLY
	clr	cx				;default threshhold
	test	bx, mask GDGA_VM_FILE
	jz	notVM
	call	VMOpen
	jc	exit			;if error then return ax (error code)
	mov_trash	ax, bx		;else return file handle
	ornf	ss:[bp].DCP_docAttrs, mask GDA_READ_WRITE
exit:
if _JEDIMOTIF
	jnc	notVMFull
	cmp	ax, VM_SHARING_DENIED
	jne	notVMFullErr
	call	checkDiskFull
	jnz	notVMFullErr
	mov	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
notVMFullErr:
	stc
notVMFull:
endif
	Destroy	cx, dx
	ret

notVM:
	mov	ah, FILE_CREATE_ONLY
	test	bx, mask GDGA_NATIVE
	jz	90$
	ornf	ah, mask FCF_NATIVE
90$:
	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate
if _JEDIMOTIF
	jnc	notFull
	cmp	ax, ERROR_ACCESS_DENIED
	jne	notFullErr
	call	checkDiskFull
	jnz	notFullErr
	mov	ax, ERROR_SHORT_READ_WRITE
notFullErr:
	stc
notFull:
endif
	Destroy	cx, dx
	ret

if _JEDIMOTIF
checkDiskFull	label	near
	push	ax, bx, cx, dx
	mov	cx, 0				; no buffer
	call	FileGetCurrentPath		; bx = disk handle/SP
	call	DiskGetVolumeFreeSpace		; dx:ax = free space
						; (if we get error, ax will
						;  be non-zero, so we say
						;  "not disk full")
	or	dx, ax
	pop	ax, bx, cx, dx
	retn
endif
OLDocumentPhysicalCreate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSpacesFilename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check for leading and trailing spaces in filename

CALLED BY:	INTERNAL
			OLDocumentPhysicalCreate
			OLDocumentContinueRename
			OLFileSelectorContinueRename
PASS:		ss:bp = filename
RETURN:		carry clear of filename okay
			ax destroyed
		carry set if error
			ax = ERROR_ILLEGAL_FILENAME
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DC_DISALLOW_SPACES_FILENAME

CheckSpacesFilename	proc	far
	uses	cx, es, di
	.enter
	segmov	es, ss, di
	lea	di, ss:[bp].DCP_name
	LocalCmpChar	es:[di], C_SPACE	; leading space?
	je	spaceCheck
	LocalLoadChar	ax, C_NULL
	mov	cx, length DCP_name
	LocalFindChar
	LocalPrevChar	esdi			; point to null
	LocalPrevChar	esdi			; point to last char
	LocalCmpChar	es:[di], C_SPACE
spaceCheck:
	mov	ax, ERROR_INVALID_NAME		; assume error
	stc					; assume error
	je	done				; trail/lead space, error
	clc					; else, indicate no error
done:
	.leave
	ret
CheckSpacesFilename	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertErrorCode

DESCRIPTION:	Convert VM errors to normal file errors

CALLED BY:	INTERNAL

PASS:
	ax - error code

RETURN:
	ax - new error code

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/22/91		Initial version

------------------------------------------------------------------------------@
ConvertErrorCode	proc	far	uses cx, di, es
	.enter

	segmov	es, cs
	mov	di, offset vmErrorList
	mov	cx, length vmErrorList
	repne scasw
	jnz	done
	mov	ax, cs:[di][(errorList-vmErrorList)-2]
done:
	.leave
	ret

vmErrorList	word	\
	VM_FILE_NOT_FOUND,
	VM_SHARING_DENIED,
	VM_WRITE_PROTECTED,
	VM_FILE_EXISTS,
	VM_UPDATE_INSUFFICIENT_DISK_SPACE,
	VM_CANNOT_CREATE,
	VM_FILE_FORMAT_MISMATCH

errorList	word	\
	ERROR_FILE_NOT_FOUND,
	ERROR_ACCESS_DENIED,
	ERROR_WRITE_PROTECTED,
	ERROR_FILE_EXISTS,
	ERROR_SHORT_READ_WRITE,
	ERROR_ACCESS_DENIED,
	ERROR_FILE_FORMAT_MISMATCH

ConvertErrorCode	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalCopyTemplate --
		MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE for OLDocumentClass

DESCRIPTION:	Copy document to an untitled file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/13/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalCopyTemplate	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_PHYSICAL_COPY_TEMPLATE

	mov	di, 1200
	call	ThreadBorrowStackSpace
	push	di

	sub	sp, size DocumentCommonParams
	mov	bp, sp
	mov	ss:[bp].DCP_docAttrs, mask GDA_UNTITLED
	mov	ss:[bp].DCP_flags, 0

if UNTITLED_DOCS_ON_SP_TOP
	mov	ss:[bp].DCP_diskHandle, SP_TOP
else
	mov	ss:[bp].DCP_diskHandle, SP_DOCUMENT
endif
	mov	{TCHAR}ss:[bp].DCP_path[0], 0

if CUSTOM_DOCUMENT_PATH
	call	OLDocumentInitDocCommonParams
endif ; CUSTOM_DOCUMENT_PATH
	
	call	PushAndSetPath
	jc	error

	clr	cx
createLoop:
	mov	dx, ss
	mov	ax, MSG_GEN_DOCUMENT_GENERATE_NAME_FOR_NEW
	call	ObjCallInstanceNoLock			;returns ss:bp = name
	mov	ax, ERROR_FILE_NOT_FOUND
	cmp	cx, GEN_DOCUMENT_GENERATE_NAME_ERROR
	jz	error
	clr	ax
	cmp	cx, GEN_DOCUMENT_GENERATE_NAME_CANCEL
	jz	error

	push	cx
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS
	call	ObjCallInstanceNoLock
	pop	cx
	jnc	noError

	call	ConvertErrorCode
	inc	cx
	cmp	ax, ERROR_FILE_EXISTS
if _JEDIMOTIF
	jz	createLoop
else
	jz	tryAgain
endif
	cmp	ax, ERROR_ACCESS_DENIED
if _JEDIMOTIF
	je	maybeDiskFull
else
	jz	tryAgain
endif
	cmp	ax, ERROR_SHARING_VIOLATION
	je	tryAgain
error:
	stc
	jmp	done

tryAgain:
	call	GetDocOptions
	test	ax, mask DCO_TRANSPARENT_DOC
	jz	createLoop
	mov	ax, SDBT_TRANSPARENT_NEW_FILE_EXISTS
	call	FarCallStandardDialogSS_BP
	jmp	createLoop

noError:
	call	StoreNewDocumentName

	; clear template bit

	clr	ax
	push	ax			;push word of zero to write
	call	OLDocumentGetFileHandle
	mov	di, sp			;es:di = zero GeosFileHeaderFlags
	segmov	es, ss
	mov	cx, size GeosFileHeaderFlags
	mov	ax, FEA_FLAGS
	call	FileSetHandleExtAttributes

	; clear user notes

	mov	cx, GFH_USER_NOTES_BUFFER_SIZE	; cx <- size of same
	mov	ax, FEA_USER_NOTES		; ax <- attr to set
	call	FileSetHandleExtAttributes
	pop	cx			;pop word to write

done:
	call	FilePopDir
	lea	sp, ss:[bp+(size DocumentCommonParams)]

	pop	di
	call	ThreadReturnStackSpace

	ret

if _JEDIMOTIF
maybeDiskFull:
	push	ax, bx, cx, dx
	mov	cx, 0				; no buffer
	call	FileGetCurrentPath		; bx = disk handle/SP
	call	DiskGetVolumeFreeSpace		; dx:ax = free space
						; (if we get error, ax will
						;  be non-zero, so we say
						;  "not disk full")
	or	dx, ax
	pop	ax, bx, cx, dx
	jnz	tryAgain			; not disk full
	mov	ax, ERROR_SHORT_READ_WRITE	; else, return disk full err
	jmp	short error
endif

OLDocumentPhysicalCopyTemplate	endm


if CUSTOM_DOCUMENT_PATH

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentInitDocCommonParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the passed DocumentCommonParams with the
		parent's GenPath

CALLED BY:	(INTERNAL) OLDocumentPhysicalCopyTemplate

PASS:		*ds:si	- GenDocumentClass object
		ss:bp	- DocumentCommonParams

RETURN:		DocumentCommonParams structure modified.

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ptrinh	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentInitDocCommonParams	proc	near
	uses	ax,cx,dx
	.enter

	push	bp				; DocumentCommonParams

	;
	; Get the path from the parent
	;
	lea	bp, ss:[bp].DCP_path
	mov	dx, ss				; dx:bp - buffer
	mov	cx, size PathName
	mov	ax, MSG_GEN_PATH_GET
	call	GenCallParent
	pop	bp				; DocumentCommonParams
	jc	nullifyPath


	mov	ss:[bp].DCP_diskHandle, cx

done:
	.leave
	ret

nullifyPath:
	mov	{TCHAR}ss:[bp].DCP_path[0], 0
	jmp	done

OLDocumentInitDocCommonParams	endp
endif ; CUSTOM_DOCUMENT_PATH


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentInitializeDocumentFile --
		MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentInitializeDocumentFile	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	mov	ax, MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupNewDoc --
		MSG_GEN_DOCUMENT_GROUP_NEW_DOC for OLDocumentGroupClass

DESCRIPTION:	Create a new file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_NEW_DOC
	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

RETURN:
	cx:dx - new Document object created
	carry - set if error

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

OLDocumentGroupNewDoc	method dynamic OLDocumentGroupClass,
					MSG_GEN_DOCUMENT_GROUP_NEW_DOC
if FLOPPY_BASED_DOCUMENTS
	;	
	; Don't allow opening if we've exceeded the maximum size already.
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_OLDG_GET_TOTAL_SIZE	
	call	ObjCallInstanceNoLock
	cmpdw	dxcx, MAX_TOTAL_FILE_SIZE	
	pop	ax, cx, dx, bp
	jb	continueNew
	mov	ax, SDBT_CANT_CREATE_TOTAL_FILES_TOO_LARGE
	call	CallUserStandardDialog
	stc
	ret

continueNew:
endif

if (not VOLATILE_SYSTEM_STATE)
	;
	; Ignore input
	;
if _JEDIMOTIF
	push	dx, bp
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	UserCallApplication
	pop	dx, bp
endif		

if CUSTOM_DOCUMENT_PATH
	;
	; We don't use passed diskHandle and path.
	;
	mov	ss:[bp].DCP_diskHandle, 0
	mov	{TCHAR}ss:[bp].DCP_path[0], 0
endif ; CUSTOM_DOCUMENT_PATH

	mov	ax, MSG_GEN_DOCUMENT_NEW
	call	CreateDocObject
	;
	; Accept input
	;
if _JEDIMOTIF
	call	AllowInputSomeTimeInTheFuture
endif
	Destroy	ax
	ret

else
	;
	; Record our true message and send out a query now to our parent,
	; so opened apps will be saved.
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OLDG_REALLY_NEW_DOC
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage
	mov	cx, di			;pass in cx to MSG_META_QUERY_DOCUMENTS

	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	GOTO	ObjCallInstanceNoLock

endif

OLDocumentGroupNewDoc	endm



COMMENT @----------------------------------------------------------------------

METHOD:		OLDocumentGroupReallyNewDoc --
		MSG_OLDG_REALLY_NEW_DOC for OLDocumentGroupClass

DESCRIPTION:	Create a new file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentGroupClass

	ax - MSG_GEN_DOCUMENT_GROUP_NEW_DOC
	dx - size DocumentCommonParams
	ss:bp - DocumentCommonParams

RETURN:
	cx:dx - new Document object created
	carry - set if error

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

if	VOLATILE_SYSTEM_STATE

OLDocumentGroupReallyNewDoc	method dynamic OLDocumentGroupClass,
					MSG_OLDG_REALLY_NEW_DOC
	mov	ax, MSG_GEN_DOCUMENT_NEW
	call	CreateDocObject
	Destroy	ax
	ret
OLDocumentGroupReallyNewDoc	endm

endif



DocNew ends

;---

DocSaveAsClose	segment resource




COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalSaveAs -- MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS
				for OLDocumentClass

DESCRIPTION:	Really do save as

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	ss:bp - DocumentCommonParams
		DOF_SAVE_AS_OVERWRITE_EXISTING_FILE - important

RETURN:
	carry - set if error
	bp - unchanged
	ax - file handle (if successful) or error code (if error)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalSaveAs	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS

if DISPLAY_SAVING_MESSAGE

	call	CreateSaveDialogCheckParams	;hold the user's hand,
						; if DCP_diskHandle = SP_TOP
	pushdw	cxdx
endif

	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	SendUndoMessage

	call	OLDocumentUnregisterDoc

	call	OLDocumentGetFileHandle		;bx = old file handle

	call	GetParentAttrs			;ax = attributes, ZF = is VM
	mov_trash	cx, ax
	push	ds
	lea	dx, ss:[bp].DCP_name

	jz	regularFile

	mov	ax, MSG_GEN_DOCUMENT_COMPUTE_ACCESS_FLAGS
	call	ObjCallInstanceNoLock		; al <- access flags

	mov	ah, VMO_CREATE_ONLY
	test	ss:[bp].DCP_flags, mask DOF_SAVE_AS_OVERWRITE_EXISTING_FILE
	jz	10$
	mov	ah, VMO_CREATE_TRUNCATE
10$:
	segmov	ds, ss				;ds:dx = filename

	clr	cx				;default threshhold
	call	VMSaveAs
	pop	ds
	jc	exit
	mov_trash	ax, bx			;ax = file handle
	ornf	ss:[bp].DCP_docAttrs, mask GDA_READ_WRITE
exit:
	jnc	fileClosed

	; reregister file that couldn't be save-ased, as it were.
	call	OLDocumentRegisterOpenDoc

fileClosed:

if DISPLAY_SAVING_MESSAGE
	popdw	cxdx
	call	DestroySaveDialog		;destroy dialog
endif
	Destroy	cx, dx
	ret

	; normal file -- open new file before sending notification

regularFile:
	segmov	ds, ss				;ds:dx = filename

	mov	ah, FILE_CREATE_ONLY
	test	ss:[bp].DCP_flags, mask DOF_SAVE_AS_OVERWRITE_EXISTING_FILE
	jz	20$
	mov	ah, FILE_CREATE_TRUNCATE
20$:
	test	cx, mask GDGA_NATIVE
	jz	21$
	ornf	ah, mask FCF_NATIVE
21$:
	mov	al, FILE_ACCESS_RW or FILE_DENY_RW
	mov	cx, FILE_ATTR_NORMAL
	call	FileCreate
	pop	ds
	jc	exit

	; actually save the data

	mov_trash	cx, ax			;save file handle
	push	cx, bp
	mov	ax, MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE
	call	ObjCallInstanceNoLock
	pop	cx, bp
	jc	saveError

	mov	bx, cx
	mov	al, FILE_NO_ERRORS
	call	FileCommit

	call	OLDocumentGetFileHandle
	clr	ax
	call	FileClose

	mov_trash	ax, cx			;return file handle
	jmp	exit

	; if error then close file and delete it

saveError:
	push	ax			;save error code
	mov	bx, cx
	mov	al, FILE_NO_ERRORS
	call	FileClose

	push	ds
	segmov	ds, ss
	lea	dx, ss:[bp].DCP_name
	call	FileDelete
	pop	ds

	pop	ax
	stc
	jmp	exit

OLDocumentPhysicalSaveAs	endm





COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateSaveDialog

SYNOPSIS:	Creates a dialog box for saving, if ATTR_GEN_PATH isn't
		set to SP_TOP.

CALLED BY:	OLDocumentPhysicalSaveAs

PASS:		*ds:si -- GenDocument

RETURN:		^lcx:dx -- created dialog

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 4/93       	Initial version

------------------------------------------------------------------------------@

if DISPLAY_SAVING_MESSAGE

CreateSaveDialogCheckVardata	proc	far		uses	bx, si, bp, ax
	.enter

if UNTITLED_DOCS_ON_SP_TOP
	;
	; If saving to the ramdisk, forget this box and return zeroes.
	; (5/8/94 cbh)
	;
	clrdw	cxdx
	call	DocCheckIfOnRamdisk		;if on RAM disk, forget it.
	jz	exit
endif
	call	DoSaveDialog
exit:
	.leave
	ret
CreateSaveDialogCheckVardata	endp

endif



COMMENT @----------------------------------------------------------------------

ROUTINE:	CreateSaveDialogCheckParams

SYNOPSIS:	Creates a dialog box for saving, is DCP_diskHandle != SP_TOP.

CALLED BY:	OLDocumentPhysicalSaveAs

PASS:		*ds:si -- GenDocument
		ss:bp -- DocumentCommonParams

RETURN:		^lcx:dx -- created dialog

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 4/93       	Initial version

------------------------------------------------------------------------------@

if DISPLAY_SAVING_MESSAGE

CreateSaveDialogCheckParams	proc	far		uses	bx, si, bp, ax
	.enter

	;
	; If saving to the ramdisk, forget this box and return zeroes.
	; (5/8/94 cbh)
	;
	clrdw	cxdx
	cmp	ss:[bp].DCP_diskHandle, SP_TOP
	je	exit
	call	DoSaveDialog
exit:
	.leave
	ret
CreateSaveDialogCheckParams	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSaveDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level save dialog stuff.

CALLED BY:	CreateSaveDialogCheckVardata, CreateSaveDialogCheckParams

PASS:		*ds:si -- GenDocument

RETURN:		^lcx:dx -- created dialog

DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 9/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if DISPLAY_SAVING_MESSAGE

DoSaveDialog	proc	near
	.enter
	mov	bx, handle SaveDialog
	mov	si, offset SaveDialog
	call	UserCreateDialog

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	movdw	cxdx, bxsi
	.leave
	ret
DoSaveDialog	endp

endif





COMMENT @----------------------------------------------------------------------

ROUTINE:	DestroySaveDialog

SYNOPSIS:	Creates a dialog box for saving.

CALLED BY:	OLDocumentPhysicalSaveAs

PASS:		^lcx:dx -- dialog box to destroy (null if none)

RETURN:		nothing (flags preserved)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	8/ 4/93       	Initial version

------------------------------------------------------------------------------@

if DISPLAY_SAVING_MESSAGE

DestroySaveDialog	proc	far	uses	bx, si
	.enter
	pushf
	tst	cx				;no dialog up, exit
	jz	exit
	movdw	bxsi, cxdx
	call	UserDestroyDialog
exit:
	popf
	.leave
	ret
DestroySaveDialog	endp

endif


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalClose -- MSG_GEN_DOCUMENT_PHYSICAL_CLOSE
						for OLDocumentClass

DESCRIPTION:	Physically close the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalClose	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_CLOSE

	call	OLDocumentUnregisterDoc

	call	OLDocumentGetFileHandle		;bx = file handle
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GDI_fileHandle, 0

	; call correct close routine

	call	GetParentAttrs			;ax = attribute, ZF = is VM
	jz	notVM
	mov	al, FILE_NO_ERRORS		;allow errors
	call	VMClose
if 0
EC <	ERROR_C	OL_ERROR						>
endif
	jmp	common

notVM:
	mov	al, FILE_NO_ERRORS
	call	FileClose

common:

if _JEDIMOTIF
	;
	; rename after closing, if necessary, no need to remove vardata
	; as document object will be going away as well
	;
	mov	ax, TEMP_OL_DOCUMENT_RENAME_AFTER_CLOSE
	call	ObjVarFindData
	jnc	done

	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
EC <	ERROR_C	OL_ERROR						>
NEC <	jc	donePopDir						>
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].GDI_fileName	;ds:dx = old name
	segmov	es, ds				;es:di = new name
	mov	di, bx
	call	FileRename			;just ignore error, we already
						;	done enough checks
donePopDir:
	call	FilePopDir
done:
endif

	Destroy	ax, cx, dx, bp
	ret

OLDocumentPhysicalClose	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalDelete -- MSG_GEN_DOCUMENT_PHYSICAL_DELETE
					for OLDocumentClass

DESCRIPTION:	Really delete the file

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalDelete	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_DELETE

	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
EC <	ERROR_C	OL_ERROR						>
NEC <	jc	done							>
	mov_tr	bx, ax				; bx <- disk handle

EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].GDI_fileName	;ds:dx = file name
	call	FileDelete

EC <	ERROR_C	CANNOT_DELETE_FILE_JUST_CLOSED				>
	call	FilePopDir

	Destroy	ax, cx, dx, bp
NEC <done:								>
	ret

OLDocumentPhysicalDelete	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalSaveAsFileHandle --
		MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE
							for OLDocumentClass

DESCRIPTION:	Save DOS file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	cx - new file handle

RETURN:
	carry - set if error
	ax - error code (if error)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalSaveAsFileHandle	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE

	; get OD to send to

	push	cx
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT
	call	GenCallParent			;cx:dx = output
	pop	bp

	mov	bx, cx
	mov	cx, ds:[LMBH_handle]
	xchg	dx, si				;bx:si = output
						;cx:dx = document

	mov	ax, MSG_META_DOC_OUTPUT_PHYSICAL_SAVE_AS_FILE_HANDLE
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	GOTO	ObjMessage

OLDocumentPhysicalSaveAsFileHandle	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentDestroyUIForDocument --
		MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentDestroyUIForDocument	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

	; if we have a GenDisplay to biff, do so

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_DISPLAY
	call	GenCallParent
	jcxz	noDisplay

	push	si
EC <	call	GenCheckGenAssumption					>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	clr	bx
	xchg	bx, ds:[di].GDI_display
	mov	si, dx				;bx:si = display

	; nuke the display

if	(1)
	; Let's give the 'ol Display the same treatment as we do dialogs
	; residing in a single block which we wish to get rid of --
	; Dismiss it, change the linkage to one-way upward only,
	; remove it from any window list it is on, & NUKE it.  The
	; slow, non-optimized approach will be taken if any objects
	; within the block are on the active list.
	;				-- Doug 1/93
	;

	mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

else
	; set the display not usable

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	DocOperations_ObjMessage_fixupDS

	; remove the display from the display control

	mov	ax, MSG_GEN_FIND_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	DocOperations_ObjMessage	;cx:dx = display control
	xchg	bx, cx				;bx:si = display control
	xchg	dx, si				;cx:dx = display
	mov	bp, mask CCF_MARK_DIRTY
	mov	ax, MSG_GEN_REMOVE_CHILD
	clr	bp
	call	DocOperations_ObjMessage_fixupDS

	; free the UI block

	mov	bx, cx
	mov	si, dx				;bx:si = display
	mov	ax, MSG_META_BLOCK_FREE
	call	DocOperations_ObjMessage_fixupDS
endif

	pop	si

noDisplay:

	mov	ax, MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentDestroyUIForDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentDetachUIFromDocument --
		MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT for OLDocumentClass

DESCRIPTION:	Handle default UI interaaction for document (if any)

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentDetachUIFromDocument	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT

	; if we have a view to connect to, connect to it

	clr	di			;di:bp = data to send to
	clr	bp			;SET_CONTENT if view exists
	call	CallSetContent

	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	SendUndoMessage

	mov	ax, MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentDetachUIFromDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentSaveAsCompleted --
		MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentSaveAsCompleted	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_SAVE_AS_COMPLETED

	mov	ax, MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentSaveAsCompleted	endm

DocSaveAsClose ends

;---

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalSave -- MSG_GEN_DOCUMENT_PHYSICAL_SAVE
						for OLDocumentClass

DESCRIPTION:	Really save the document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - file handle (if successful) or error code (if error)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalSave	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_SAVE

if DISPLAY_SAVING_MESSAGE
	call	CreateSaveDialogCheckVardata	;hold the user's hand, if
						; ATTR_GEN_PATH != SP_TOP
	pushdw	cxdx
endif
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	SendUndoMessage

	mov	ax, MSG_META_DOC_OUTPUT_PHYSICAL_SAVE
	call	SendNotificationToOutput
	jc	common

	; call correct save routine

	call	OLDocumentGetFileHandle		;bx = file handle
	call	GetParentAttrs			;ax = attribute, ZF = is VM

	jz	commit
	call	VMSave
	jnc	common


;	Eat VM_UPDATE_BLOCK_WAS_LOCKED and VM_UPDATE_NOTHING_DIRTY, which
;	should not be reported to the user. We will display a warning
;	to the programmer though, so he can be aware that this is happening.
;
;	This is done so autosaves (or saves) on files that can be accessed
;	by multiple apps will not put up errors if by some chance one of the
;	blocks is locked when we try to save.
;

	cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED
EC <	WARNING_Z	SAVE_FAILED_DUE_TO_BLOCK_LOCKED_BY_ANOTHER_THREAD>
	jz	ignore
	cmp	ax, VM_UPDATE_NOTHING_DIRTY
EC <	WARNING_Z	SAVE_ATTEMPTED_WHEN_NO_BLOCKS_WERE_DIRTY	>
	stc
	jnz	common
ignore:
	clc
	jmp	common

commit:
	clr	al
	call	FileCommit

common:
if DISPLAY_SAVING_MESSAGE
	popdw	cxdx
	call	DestroySaveDialog		;destroy dialog
endif
	Destroy	cx, dx, bp
	ret

OLDocumentPhysicalSave	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalUpdate --
			MSG_GEN_DOCUMENT_PHYSICAL_UPDATE for OLDocumentClass

DESCRIPTION:	Update changes to the file

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - file handle (if successful) or error code (if error)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalUpdate	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_UPDATE

	mov	ax, MSG_META_DOC_OUTPUT_PHYSICAL_UPDATE
	call	SendNotificationToOutput
	jc	done

	call	OLDocumentGetFileHandle

	call	GetParentAttrs		; ax <- attrs, ZF <- is VM
	jz	done

	call	VMUpdate
	jc	err
noErr:
	clr	al
	call	FileCommit
done:

	Destroy	cx, dx, bp
	ret
err:

;	Eat VM_UPDATE_BLOCK_WAS_LOCKED and VM_UPDATE_NOTHING_DIRTY, which
;	should not be reported to the user. We will display a warning
;	to the programmer though, so he can be aware that this is happening.

	cmp	ax, VM_UPDATE_BLOCK_WAS_LOCKED
EC <	WARNING_Z	SAVE_FAILED_DUE_TO_BLOCK_LOCKED_BY_ANOTHER_THREAD>
	jz	ignore
	cmp	ax, VM_UPDATE_NOTHING_DIRTY
EC <	WARNING_Z	SAVE_ATTEMPTED_WHEN_NO_BLOCKS_WERE_DIRTY	>
	stc
	jnz	done
ignore:
	clc
	jmp	done	

OLDocumentPhysicalUpdate	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalCheckForModifications --
		MSG_GEN_DOCUMENT_PHYSICAL_CHECK_FOR_MODIFICATIONS
						for OLDocumentClass

DESCRIPTION:	Check to see if a "shared multiple" file is modified

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if file modified
	ax, cx, dx, bp - destroyed

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 7/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalCheckForModifications	method dynamic	OLDocumentClass,
			MSG_GEN_DOCUMENT_PHYSICAL_CHECK_FOR_MODIFICATIONS

	call	OLDocumentGetFileHandle		;bx = file handle
	call	VMCheckForModifications

	Destroy	ax, cx, dx, bp
	ret

OLDocumentPhysicalCheckForModifications	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendNotificationToOutput

DESCRIPTION:	Load file handle and call OLDocSendNotification

CALLED BY:	INTERNAL

PASS:
	*ds:si - GenDocument
	ax - method to send

RETURN:
	ax - from notification
	carry - from notification (clear if no notification)

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
SendNotificationToOutput	proc	far	uses cx, dx, si, bp
	.enter

EC <	call	AssertIsGenDocument					>

	; get OD to send to

	push	ax
	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_OUTPUT
	call	GenCallParent			;cx:dx = output

	call	OLDocumentGetFileHandle
	mov_trash	bp, ax
	pop	ax

	mov	bx, cx
	mov	cx, ds:[LMBH_handle]
	xchg	dx, si				;bx:si = output
						;cx:dx = document

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret

SendNotificationToOutput	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentWriteCachedDataToFile --
		MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentWriteCachedDataToFile	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE

	mov	ax, MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentWriteCachedDataToFile	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentDocumentHasChanged --
		MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED for OLDocumentClass

DESCRIPTION:	...

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
	Tony	8/ 7/91		Initial version

------------------------------------------------------------------------------@
OLDocumentDocumentHasChanged	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED

	mov	ax, MSG_META_DOC_OUTPUT_DOCUMENT_HAS_CHANGED
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentDocumentHasChanged	endm

DocCommon ends

;---

DocMisc segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalRevert -- MSG_GEN_DOCUMENT_PHYSICAL_REVERT
							for OLDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalRevert	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_REVERT

	mov	ax, MSG_META_DOC_OUTPUT_PHYSICAL_REVERT
	call	SendNotificationToOutput
	jc	common				;return carry set if error

	; call correct revert routine

	call	OLDocumentGetFileHandle		;bx = file handle

	call	GetParentAttrs			;ax = attribute, ZF = is VM
	jz	common				;carry is clear
	call	VMGetAttributes			;al = VMAttributes
	test	al, mask VMA_BACKUP
	jnz	revert
	call	VMDiscardDirtyBlocks
	jmp	short common			;return error, if any

revert:
	call	VMRevert
done:
	clc	
common:
	Destroy	ax, cx, dx, bp
	ret

OLDocumentPhysicalRevert	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentPhysicalRevertToAutoSave --
		MSG_GEN_DOCUMENT_PHYSICAL_REVERT_TO_AUTO_SAVE
							for OLDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentPhysicalRevertToAutoSave	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_PHYSICAL_REVERT_TO_AUTO_SAVE

	mov	ax, MSG_META_DOC_OUTPUT_PHYSICAL_REVERT_TO_AUTO_SAVE
	call	SendNotificationToOutput
	jc	common				;return carry set if error

	; call correct revert routine

	call	OLDocumentGetFileHandle		;bx = file handle

	call	GetParentAttrs			;ax = attribute, ZF = is VM
	jz	common				;carry is clear
	call	VMDiscardDirtyBlocks

common:
	Destroy	ax, cx, dx, bp
	ret

OLDocumentPhysicalRevertToAutoSave	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentUpdateEarlierCompatibleDocument --
		MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT
						 for OLDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - error code (if error) or 0 if no error

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentUpdateEarlierCompatibleDocument	method dynamic	OLDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT

	mov	ax, MSG_META_DOC_OUTPUT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentUpdateEarlierCompatibleDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentUpdateEarlierIncompatibleDocument --
		MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
		for OLDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - file handle (if no error) or error code (if error)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentUpdateEarlierIncompatibleDocument	method dynamic	OLDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

	mov	ax, MSG_META_DOC_OUTPUT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentUpdateEarlierIncompatibleDocument	endm

DocMisc	ends

;---

DocObscure segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentAttachFailed --
		MSG_GEN_DOCUMENT_ATTACH_FAILED for OLDocumentClass

DESCRIPTION:	...

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
OLDocumentAttachFailed	method dynamic	OLDocumentClass,
				MSG_GEN_DOCUMENT_ATTACH_FAILED

	mov	ax, MSG_META_DOC_OUTPUT_ATTACH_FAILED
EC <	call	AssertIsGenDocument					>
	call	SendNotificationToOutput
	Destroy	cx, dx, bp
	ret

OLDocumentAttachFailed	endm

DocObscure ends
