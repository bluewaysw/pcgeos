COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainDocObscure.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLDocument		Open look document class

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

DESCRIPTION:

	$Id: cmainDocObscure.asm,v 1.1 97/04/07 10:51:48 newdeal Exp $

------------------------------------------------------------------------------@

DocObscure segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentEditUserNotes --
		MSG_GEN_DOCUMENT_EDIT_USER_NOTES for OLDocumentClass

DESCRIPTION:	Edit the user notes for the document

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
	Tony	8/15/91		Initial version

------------------------------------------------------------------------------@
OLDocumentEditUserNotes	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_EDIT_USER_NOTES

	call	OLDocumentGetFileHandle		;ax = file handle
	mov_trash	di, ax			;di = file handle

	; make dialog box a child of the application

	push	si
	mov	bx, handle EditUserNotesSummons
	mov	si, offset EditUserNotesSummons
	push	ds:[LMBH_handle]
	call	UserCreateDialog
	call	MemDerefStackDS

	; read the user notes

	clr	bp
	call	GetSetUserNotes
	pop	ax

	; set help file for this dialog to be same as the document

	sub	sp, size FileLongName
	movdw	cxdx, sssp

	push	si
	mov	si, ax				;si = GenDocument
	mov	ax, MSG_META_GET_HELP_FILE
	call	ObjCallInstanceNoLock
	pop	si
	jnc	fixupStack

	push	di
	mov	ax, MSG_META_SET_HELP_FILE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
fixupStack:
	add	sp, size FileLongName

	; display dialog box for editing user notes

	call	UserDoDialog
	cmp	ax, IC_APPLY
	jnz	noSave

	;XXX: test response type

	; save the user notes

	mov	bp, -1
	call	GetSetUserNotes
	xchg	bx, di
	call	FileCommit
	xchg	bx, di
noSave:

	call	UserDestroyDialog

	Destroy	ax, cx, dx, bp
	ret

OLDocumentEditUserNotes	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetSetUserNotes

DESCRIPTION:	Get or set the user notes

CALLED BY:	OLDocumentEditUserNotes

PASS:
	bp - zero to read notes, non-zero to write notes
	di - file handle
	bx - block containing summons

RETURN:
	EditUserNotesText chunk - set

DESTROYED:
	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/15/91		Initial version

------------------------------------------------------------------------------@
GetSetUserNotes	proc	near	uses bx, si, di, ds, es
	.enter

	sub	sp, GFH_USER_NOTES_BUFFER_SIZE
	mov	dx, sp
	segmov	es, ss
	
	mov	si, offset EditUserNotesTextEdit

	tst	bp
	jnz	notRead

	; read user notes into buffer

	push	bx				; save summons block
	mov	bx, di				; bx <- file handle
	mov	di, dx				; es:di <- buffer
	mov	cx, GFH_USER_NOTES_BUFFER_SIZE	; cx <- size of same
	mov	ax, FEA_USER_NOTES		; ax <- attr to get
	call	FileGetHandleExtAttributes
	pop	bx

	jc	done

	; copy notes to text object

	mov	bp, dx
	mov	dx, ss				;dx:bp = text
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	mov	cx, TEXT_ADDRESS_PAST_END_LOW
	mov	dx, cx
	clr	di
	call	ObjMessage
	jmp	done

notRead:

	; get notes from text object

	push	dx, di
	mov	bp, dx
	mov	dx, ss				;dx:bp = buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di, bx				;bx <- file handle,
						; es:di <- text to write
	
	mov	cx, GFH_USER_NOTES_BUFFER_SIZE
	mov	ax, FEA_USER_NOTES
	call	FileSetHandleExtAttributes

done:
	add	sp, GFH_USER_NOTES_BUFFER_SIZE

	.leave
	ret

GetSetUserNotes	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentRename --
		MSG_GEN_DOCUMENT_RENAME for OLDocumentClass

DESCRIPTION:	Rename the document

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
	Tony	8/15/91		Initial version

------------------------------------------------------------------------------@
OLDocumentRename	method dynamic	OLDocumentClass, MSG_GEN_DOCUMENT_RENAME
newName	local	FileLongName
	.enter

	call	GetUIParentAttrs		;ax = GenDocumentControlAttrs

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	di, ds:[di].GDI_fileName

	push	si
	mov	bx, handle RenameDialog
	mov	si, offset RenameDialog
	push	ds:[LMBH_handle]
	call	UserCreateDialog		; doesn't fixup DS
	call	MemDerefStackDS

	mov	si, offset RenameText
	call	SetTextObjectForFileType

	push	bp
	movdw	dxbp, dsdi
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	; set help file for this dialog to be same as the document

	pop	si				;si = GenDocument
	push	si

	sub	sp, size FileLongName
	movdw	cxdx, sssp

	push	bp
	mov	ax, MSG_META_GET_HELP_FILE
	call	ObjCallInstanceNoLock
	jnc	fixupStack

	mov	ax, MSG_META_SET_HELP_FILE
	mov	si, offset RenameDialog
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
fixupStack:
	pop	bp
	add	sp, size FileLongName

	; display dialog box for editing user notes

	mov	si, offset RenameDialog
	push	ds:[LMBH_handle]
	call	UserDoDialog

	; get the new text

	push	ax, bp				;ax=IC, bp=locals
	lea	bp, newName
	mov	dx, ss
	mov	cx, size newName
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	si, offset RenameText
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax, bp				;ax = IC, bp = locals
	
	; to check whether the text obj contains visible character for filename

	mov	dx, si
	call	MemDerefStackDS
	call	CheckForBlankTextObj
	push	ds:[LMBH_handle]
	pushf
	mov	si, offset RenameDialog
	call	UserDestroyDialog
	popf
	call	MemDerefStackDS
	pop	si				;si = GenDocument
	jc	fileNameInvalid

	cmp	ax, IC_APPLY
	jnz	noRename

	; save changes and close the file

	call	OLDocMarkBusy

	push	bp
	mov	ax, MSG_GEN_DOCUMENT_CLOSE_FILE
	call	ObjCallInstanceNoLock
	pop	bp

	push	bp
	lea	bp, newName
	mov	dx, size newName
	mov	ax, MSG_OL_DOCUMENT_CONTINUE_RENAME
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage
	pop	bp

noRename:

	.leave
	ret

fileNameInvalid:
	push	bp
	clr	ax
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
		(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or\
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].SDOP_customString.handle, handle BlankFileNameErrStr
	mov	ss:[bp].SDOP_customString.chunk, offset BlankFileNameErrStr
	mov	ss:[bp].SDOP_stringArg1.handle, ax
	mov	ss:[bp].SDOP_stringArg2.handle, ax
	mov	ss:[bp].SDOP_customTriggers.segment, ax
	mov	ss:[bp].SDOP_helpContext.segment, ax
	call	UserStandardDialogOptr
	pop	bp

	
	jmp	noRename

OLDocumentRename	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentContinueRename -- MSG_OL_DOCUMENT_CONTINUE_RENAME
							for OLDocumentClass

DESCRIPTION:	Finish a rename

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	ss:bp - FileLongName

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 7/92		Initial version

------------------------------------------------------------------------------@
OLDocumentContinueRename	method dynamic	OLDocumentClass,
					MSG_OL_DOCUMENT_CONTINUE_RENAME

	call	FilePushDir
if DC_DISALLOW_SPACES_FILENAME
	;
	; check for trailing or leading spaces
	;
	call	CheckSpacesFilename
	jnc	noError
	mov	ax, SDBT_FILE_ILLEGAL_NAME	; in case error
.assert (offset DCP_name eq 0)
	call	FarCallStandardDialogSS_BP
	jmp	short continue

noError:
endif
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	lea	dx, ds:[bx].GFP_path
	mov	bx, ds:[bx].GFP_disk
	call	FileSetCurrentPath

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].GDI_fileName	;ds:dx = current name
	segmov	es, ss
	mov	di, bp				;es:di = new name
	call	FileRename
	jc	error

	; rename was successful -- copy new name into object

	push	si, ds
	mov	si, dx
	segxchg	ds, es				;es:di = GDI_fileName (dest)
	xchg	si, di				;ds:si = new name (source)
	mov	cx, size FileLongName
	rep	movsb
	pop	si, ds

	; re-open the file

continue:

	mov	ax, MSG_GEN_DOCUMENT_REOPEN_FILE
	call	ObjCallInstanceNoLock

	mov	bx, 1
	call	SendCompleteUpdateToDC

	call	OLDocMarkNotBusy

	call	FilePopDir
	ret

error:
	cmp	ax, ERROR_FILE_EXISTS
	mov	ax, SDBT_RENAME_FILE_EXISTS
	jz	gotErrorCode
	mov	ax, SDBT_RENAME_ERROR
gotErrorCode:

	movdw	cxdx, esdi			;cxdx = file name
	call	CallUserStandardDialog
	jmp	continue

OLDocumentContinueRename	endm

if _DUI			; will need to update cmainUIDocumentControl.ui
			;	and .gp files for other SPUIs


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_DOCUMENT_DUPLICATE
PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		ds:bx	= OLDocumentClass object (same as *ds:si)
		es 	= segment of OLDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		This could be combined with the rename function above.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentDuplicate	method dynamic OLDocumentClass, 
					MSG_GEN_DOCUMENT_DUPLICATE
newName	local	FileLongName
	.enter

	call	GetUIParentAttrs		;ax = GenDocumentControlAttrs

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	di, ds:[di].GDI_fileName

	push	si
	mov	bx, handle CopyDialog
	mov	si, offset CopyDialog
	push	ds:[LMBH_handle]
	call	UserCreateDialog		; doesn't fixup DS
	call	MemDerefStackDS

	mov	si, offset CopyText
	call	SetTextObjectForFileType

	push	bp
	movdw	dxbp, dsdi
	clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	bp

	; set help file for this dialog to be same as the document

	pop	si				;si = GenDocument
	push	si

	sub	sp, size FileLongName
	movdw	cxdx, sssp

	push	bp
	mov	ax, MSG_META_GET_HELP_FILE
	call	ObjCallInstanceNoLock
	jnc	fixupStack

	mov	ax, MSG_META_SET_HELP_FILE
	mov	si, offset CopyDialog
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
fixupStack:
	pop	bp
	add	sp, size FileLongName

	; display dialog box for duplicate

	mov	si, offset CopyDialog
	push	ds:[LMBH_handle]
	call	UserDoDialog			;doesn't fixup DS

	; get the new text

	push	ax, bp				;ax=IC, bp=locals
	lea	bp, newName
	mov	dx, ss
	mov	cx, size newName
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	si, offset CopyText
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax, bp				;ax = IC, bp = locals
	
	; to check whether the text obj contains visible character for filename

	mov	dx, si
	call	MemDerefStackDS
	call	CheckForBlankTextObj
	push	ds:[LMBH_handle]
	pushf
	mov	si, offset CopyDialog
	call	UserDestroyDialog		;doesn't fixup DS
	popf
	call	MemDerefStackDS
	pop	si				;si = GenDocument
	jc	fileNameInvalid

	cmp	ax, IC_APPLY
	jnz	noCopy

	; save changes and close the file

	call	OLDocMarkBusy

	push	bp
	mov	ax, MSG_GEN_DOCUMENT_CLOSE_FILE
	call	ObjCallInstanceNoLock
	pop	bp

	push	bp
	lea	bp, newName
	mov	dx, size newName
	mov	ax, MSG_OL_DOCUMENT_CONTINUE_DUPLICATE
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage
	pop	bp

noCopy:

	.leave
	ret

fileNameInvalid:
	push	bp
	clr	ax
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
		(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or\
		(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].SDOP_customString.handle, handle BlankFileNameErrStr
	mov	ss:[bp].SDOP_customString.chunk, offset BlankFileNameErrStr
	mov	ss:[bp].SDOP_stringArg1.handle, ax
	mov	ss:[bp].SDOP_stringArg2.handle, ax
	mov	ss:[bp].SDOP_customTriggers.segment, ax
	mov	ss:[bp].SDOP_helpContext.segment, ax
	call	UserStandardDialogOptr
	pop	bp

	
	jmp	noCopy

OLDocumentDuplicate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentContinueDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_OL_DOCUMENT_CONTINUE_DUPLICATE
PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		ds:bx	= OLDocumentClass object (same as *ds:si)
		es 	= segment of OLDocumentClass
		ax	= message #
		ss:bp	= filename for duplicate
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentContinueDuplicate	method dynamic OLDocumentClass, 
					MSG_OL_DOCUMENT_CONTINUE_DUPLICATE

	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	lea	dx, ds:[bx].GFP_path
	mov	bx, ds:[bx].GFP_disk
	call	FileSetCurrentPath

	;
	; Before we do the FileCopy, we need to make sure that the new name
	; doesn't equal to any of the existing files.
	;
	push	ds
	segmov	ds, ss, ax
	mov	dx, bp			;ds:dx = new name
	call	FileGetAttributes	;carry set -> file not found
	pop	ds			;ax,cx trashed
	cmc
	mov	ax, ERROR_FILE_EXISTS	;in case found
	jc	error

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	si, ds:[di].GDI_fileName	;ds:si = current name
	segmov	es, ss
	mov	di, bp				;es:di = new name
	clr	cx, dx				;use current path
	call	FileCopy
	pop	si
	jc	error

	; re-open the file

continue:

	mov	ax, MSG_GEN_DOCUMENT_REOPEN_FILE
	call	ObjCallInstanceNoLock

	mov	bx, 1
	call	SendCompleteUpdateToDC		;just in case

	call	OLDocMarkNotBusy

	call	FilePopDir
	ret

error:
	cmp	ax, ERROR_FILE_EXISTS
	mov	ax, SDBT_RENAME_FILE_EXISTS	;works for copy, as well
	jz	gotErrorCode
	mov	ax, SDBT_BACKUP_ERROR		;oh well, use backup
gotErrorCode:

	mov	cx, ss				;cxdx = file name
						;(only needed for FILE_EXISTS)
	call	CallUserStandardDialog
	jmp	continue

OLDocumentContinueDuplicate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close and delete document

CALLED BY:	MSG_GEN_DOCUMENT_DELETE
PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		ds:bx	= OLDocumentClass object (same as *ds:si)
		es 	= segment of OLDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentDelete	method dynamic OLDocumentClass, 
					MSG_GEN_DOCUMENT_DELETE
	;
	; Create the dialog to ask user for confirmation
	;
	push	ds:[LMBH_handle], si
	mov	bx, handle DeleteDialog
	mov	si, offset DeleteDialog
	call	UserCreateDialog
	mov	ax, SST_WARNING
	call	UserStandardSound
	call	UserDoDialog
	call	UserDestroyDialog
	pop	bx, si
	call	MemDerefDS
	cmp	ax, IC_APPLY
	jne	done
	;
	; close and delete document
	;
	mov	cx, TRUE
	call	OLDocDestroyDocument
	;
	; return to list screen or create new document
	;
	mov	ax, MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
	call	SendToDocumentControl
done:
	ret
OLDocumentDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentUseTemplate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this document and open a template.

CALLED BY:	MSG_GEN_DOCUMENT_USE_TEMPLATE
PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		ds:bx	= OLDocumentClass object (same as *ds:si)
		es 	= segment of OLDocumentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentUseTemplate	method dynamic OLDocumentClass, 
					MSG_GEN_DOCUMENT_USE_TEMPLATE

	mov	ax, MSG_GEN_DOCUMENT_CONTROL_INITIATE_USE_TEMPLATE_DOC
	call	SendToDocumentControl
	ret
OLDocumentUseTemplate	endm

endif	; _DUI

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentChangeType -- MSG_GEN_DOCUMENT_CHANGE_TYPE
							for OLDocumentClass

DESCRIPTION:	Change the access to a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	cx - GenDocumentType

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 5/92		Initial version

------------------------------------------------------------------------------@


ChangeTypeFlags	record
    CAF_MODIFY_GEOS_FLAGS:1
    CAF_NEW_SHARED_SINGLE_FLAG:1
    CAF_NEW_SHARED_MULTIPLE_FLAG:1
    CAF_NEW_TEMPLATE_FLAG:1
    CAF_CONVERT_FROM_READ_ONLY:1
    CAF_CONVERT_TO_READ_ONLY:1
    CAF_MODIFY_BACKUP_BIT:1
    CAF_NEW_BACKUP_BIT:1
    CAF_PROMPT_TEMPLATE_MOVE:1
    CAF_REOPEN:1
ChangeTypeFlags	end

accessChangeTable	ChangeTypeFlags	\
;MOD   PUB  MULTI  TEMP   FROM  TO   MOD   NEW   MOVE  REOPEN \
;GEOS  LIC  -USER  LATE   R/O   R/O  BACK  BACK \
; ********* from: GDT_NORMAL ************** \
 <0,   0,   0,     0,     0,    0,    0,   0,    0,    0>, ;NORMAL
 <0,   0,   0,     0,     0,    1,    0,   0,    0,    1>, ;READ_ONLY
 <1,   0,   0,     1,     0,    0,    0,   0,    1,    0>, ;TEMPLATE
 <1,   0,   0,     1,     0,    1,    0,   0,    1,    0>, ;READ_ONLY_TEMPLATE
 <1,   1,   0,     0,     0,    0,    0,   0,    0,    1>, ;PUBLIC
 <1,   0,   1,     0,     0,    0,    1,   0,    0,    1>, ;MULTI_USER
; ********* from: GDT_READ_ONLY **************
 <0,   0,   0,     0,     1,    0,    0,   0,    0,    1>, ;NORMAL
 <0,   0,   0,     0,     0,    0,    0,   0,    0,    0>, ;READ_ONLY
 <1,   0,   0,     1,     1,    0,    0,   0,    1,    0>, ;TEMPLATE
 <1,   0,   0,     1,     1,    1,    0,   0,    1,    0>, ;READ_ONLY_TEMPLATE
 <1,   1,   0,     0,     1,    0,    0,   0,    0,    1>, ;PUBLIC
 <1,   0,   1,     0,     1,    0,    1,   0,    0,    1>, ;MULTI_USER
; ********* from: GDT_TEMPLATE **************
 <1,   0,   0,     0,     0,    0,    0,   0,    0,    1>, ;NORMAL
 <1,   0,   0,     0,     0,    1,    0,   0,    0,    1>, ;READ_ONLY
 <0,   0,   0,     0,     0,    0,    0,   0,    0,    0>, ;TEMPLATE
 <0,   0,   0,     0,     0,    1,    0,   0,    0,    0>, ;READ_ONLY_TEMPLATE
 <1,   1,   0,     0,     0,    0,    0,   0,    0,    1>, ;PUBLIC
 <1,   0,   1,     0,     0,    0,    1,   0,    0,    1>, ;MULTI_USER
; ********* from: GDT_READ_ONLY_TEMPLATE **************
 <1,   0,   0,     0,     1,    0,    0,   0,    0,    1>, ;NORMAL
 <1,   0,   0,     0,     1,    1,    0,   0,    0,    1>, ;READ_ONLY
 <0,   0,   0,     0,     1,    0,    0,   0,    0,    0>, ;TEMPLATE
 <0,   0,   0,     0,     0,    0,    0,   0,    0,    0>, ;READ_ONLY_TEMPLATE
 <1,   1,   0,     0,     1,    0,    0,   0,    0,    1>, ;PUBLIC
 <1,   0,   1,     0,     1,    0,    1,   0,    0,    1>, ;MULTI_USER
; ********* from: GDT_PUBLIC **************
 <1,   0,   0,     0,     0,    0,    0,   0,    0,    1>, ;NORMAL
 <1,   0,   0,     0,     0,    1,    0,   0,    0,    1>, ;READ_ONLY
 <1,   0,   0,     1,     0,    0,    0,   0,    1,    0>, ;TEMPLATE
 <1,   0,   0,     1,     0,    1,    0,   0,    1,    0>, ;READ_ONLY_TEMPLATE
 <0,   0,   0,     0,     0,    0,    0,   0,    0,    0>, ;PUBLIC
 <1,   0,   1,     0,     0,    0,    1,   0,    0,    1>, ;MULTI_USER
; ********* from: GDT_MULTI_USER **************
 <1,   0,   0,     0,     0,    0,    1,   1,    0,    1>, ;NORMAL
 <1,   0,   0,     0,     0,    1,    1,   1,    0,    1>, ;READ_ONLY
 <1,   0,   0,     1,     0,    0,    1,   1,    1,    0>, ;TEMPLATE
 <1,   0,   0,     1,     0,    1,    1,   1,    1,    0>, ;READ_ONLY_TEMPLATE
 <1,   1,   0,     0,     0,    0,    1,   1,    0,    1>, ;PUBLIC
 <0,   0,   0,     0,     0,    0,    0,   0,    0,    0>  ;MULTI_USER

OLDocumentChangeType	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_CHANGE_TYPE
	call	OLDocumentGetFileHandle

	; save changes (unless the file is currently read-only)

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_READ_ONLY
	jnz	afterSave

	push	cx
	mov	ax, MSG_GEN_DOCUMENT_SAVE
	call	ObjCallInstanceNoLock
	pop	cx
	jc	done
afterSave:

	; temporarily close the file...

	push	cx
	mov	ax, MSG_GEN_DOCUMENT_CLOSE_FILE
	call	ObjCallInstanceNoLock
	pop	cx

	; we must queue a message to complete the operation since the
	; file will not actually be closed until a trip around the queue

	mov	ax, MSG_OL_DOCUMENT_CONTINUE_CHANGE_TYPE
	call	SendToSelfOnQueue
done:
	ret

OLDocumentChangeType	endm

;---

	; cx = new type

OLDocumentContinueChangeType	method dynamic OLDocumentClass,
					MSG_OL_DOCUMENT_CONTINUE_CHANGE_TYPE

	call	FilePushDir
	mov	ax, ATTR_GEN_PATH_DATA
	call	ObjVarFindData
	lea	dx, ds:[bx].GFP_path
	mov	bx, ds:[bx].GFP_disk
	call	FileSetCurrentPath

	mov	ax, cx
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	xchg	ax, ds:[di].GDI_type		;ax = old type

	; ax = new type, cx = old type

	; construct a table index so that we can work table driven

	mov	di, (size ChangeTypeFlags) * GenDocumentType
	mul	di
	shl	cx
	add	ax, cx
	mov_tr	di, ax
	mov	ax, cs:accessChangeTable[di]

	tst	ax
	LONG jz	reopenFile
	push	ax

	; if we need to modify to NOT read-only then do it

	test	ax, mask CAF_CONVERT_FROM_READ_ONLY
	jz	afterFromReadOnly
	call	getDSDXFile
	call	FileGetAttributes		;cx = attributes
	LONG jc	error
	andnf	cx, not mask FA_RDONLY
	call	FileSetAttributes
	LONG jc	error
afterFromReadOnly:

	; if we need to change the VMA_BACKUP bit then do so

	pop	ax
	push	ax
	test	ax, mask CAF_MODIFY_BACKUP_BIT
	jz	afterChangeBackup
	call	GetParentAttrs
	jz	afterChangeBackup
	call	getDSDXFile
	mov	ah, VMO_OPEN
	mov	al, mask VMAF_FORCE_READ_WRITE
	call	VMOpen
	LONG jc	error
	pop	ax
	push	ax
	test	ax, mask CAF_NEW_BACKUP_BIT
	mov	ax, mask VMA_BACKUP
	jnz	gotBackupBit
	xchg	al, ah
gotBackupBit:
	call	VMSetAttributes
	mov	al, FILE_NO_ERRORS
	call	VMClose
afterChangeBackup:

	; if we need to change the GEOS attributes then do it

	pop	ax
	push	ax
	test	ax, mask CAF_MODIFY_GEOS_FLAGS
	jz	afterModifyGeos

	clr	dx
	test	ax, mask CAF_NEW_SHARED_SINGLE_FLAG
	jz	10$
	mov	dx, mask GFHF_SHARED_SINGLE
10$:
	test	ax, mask CAF_NEW_SHARED_MULTIPLE_FLAG
	jz	20$
	ornf	dx, mask GFHF_SHARED_MULTIPLE
20$:
	test	ax, mask CAF_NEW_TEMPLATE_FLAG
	jz	30$
	ornf	dx, mask GFHF_TEMPLATE
30$:
	push	dx				;allocate a word on the stack

	segmov	es, ss
	mov	di, sp
	mov	cx, size GeosFileHeaderFlags
	mov	ax, FEA_FLAGS
	call	getDSDXFile
	call	FileSetPathExtAttributes
	pop	dx
	LONG jc	error
afterModifyGeos:

	; if we need to prompt for possibly moving a template then do so

	pop	ax
	push	ax
	test	ax, mask CAF_PROMPT_TEMPLATE_MOVE
	jz	afterPrompt

	mov	ax, SDBT_PROMPT_MOVE_TEMPLATE
	call	CallUserStandardDialog
	cmp	ax, IC_OK
	jnz	afterPrompt

	; allocate a buffer on the stack to copy the template directory
	; and destination name to

	pop	ax
	push	ax

	push	si
	sub	sp, size PathName
	movdw	cxdx, sssp			;cxdx = buffer

	; send a message to the document control to get the template directory 

	mov	ax, MSG_GEN_DOCUMENT_GROUP_GET_TEMPLATE_DIR
	call	GenCallParent

	segmov	es, ss
	mov	di, sp				;esdi = buffer
	clr	ax
	mov	cx, length PathName
	LocalFindChar
SBCS <	mov	{char} es:[di-1], C_BACKSLASH	;add backslash at end	>
DBCS <	mov	{wchar} es:[di-2], C_BACKSLASH	;add backslash at end	>

	call	getDSDXFile
	mov	si, dx				;ds:si = source name
	push	si
copyNameLoop:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax
	jnz	copyNameLoop
	pop	si
	mov	di, sp

	clr	cx				;cx = source disk handle
	mov	dx, SP_TEMPLATE
	call	FileMove
	lahf
	add	sp, size PathName
	sahf
	pop	si
	jc	error

	; change the current directory to be the template directory in case
	; we need to change the attributes below

	call	SetTemplateDir
afterPrompt:

	; if we need to modify to TO read-only then do it

	pop	ax
	push	ax
	test	ax, mask CAF_CONVERT_TO_READ_ONLY
	jz	afterToReadOnly
	call	getDSDXFile
	call	FileGetAttributes		;cx = attributes
	LONG jc	error
	ornf	cx, mask FA_RDONLY
	call	FileSetAttributes
	LONG jc	error
afterToReadOnly:

	; re-open the file if so instructed

	pop	ax
	test	ax, mask CAF_REOPEN
	jz	closeTheFile

	; create structure to pass to the document group to re-open the file

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GDI_attrs, not mask GDA_READ_ONLY
	ornf	ds:[di].GDI_attrs, mask GDA_READ_WRITE
	test	ax, mask CAF_CONVERT_TO_READ_ONLY
	jz	notReadOnly
	andnf	ds:[di].GDI_attrs, not mask GDA_READ_WRITE
	ornf	ds:[di].GDI_attrs, mask GDA_READ_ONLY
notReadOnly:

reopenFile:
	mov	ax, MSG_GEN_DOCUMENT_REOPEN_FILE
	call	ObjCallInstanceNoLock

done:
	call	FilePopDir
	ret

error:
	pop	ax
	mov	al, SDBT_CANNOT_CHANGE_TYPE
	call	FarCallStandardDialogDS_SI

closeTheFile:
	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	call	ObjCallInstanceNoLock
	call	OLDocRemoveObj
	jmp	done

;---

getDSDXFile:
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].GDI_fileName
	pop	di
	retn

OLDocumentContinueChangeType	endm



COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentChangePassword -- MSG_GEN_DOCUMENT_CHANGE_PASSWORD
							for OLDocumentClass

DESCRIPTION:	Change the password for a document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	bp - GenDocumentChangePasswordParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/ 5/92		Initial version

------------------------------------------------------------------------------@


OLDocumentChangePassword	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_CHANGE_PASSWORD

	sub	sp, FILE_PASSWORD_SIZE
	mov	di, sp
	segmov	es, ss				;es:di = buffer

	push	si, ds
	segmov	ds, ss
	lea	si, ss:[bp].GDCPP_password
	call	UserEncryptPassword
	pop	si, ds

	jnc	noConfirm
	mov	ax, SDBT_CONFIRM_PASSWORD_CHANGE
	call	CallUserStandardDialog
	cmp	ax, IC_YES
	jnz	done
noConfirm:

	call	OLDocumentGetFileHandle

	; change the password

	mov	ax, FEA_PASSWORD
	mov	cx, FILE_PASSWORD_SIZE
	call	FileSetHandleExtAttributes
	jnc	done

	mov	al, SDBT_CANNOT_CHANGE_PASSWORD
	call	FarCallStandardDialogDS_SI
done:
	add	sp, FILE_PASSWORD_SIZE
	ret

OLDocumentChangePassword	endm



COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentQuickBackup -- MSG_GEN_DOCUMENT_QUICK_BACKUP
						for OLDocumentClass

DESCRIPTION:	Make a quick backup of a document

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
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@

if not _DUI
OLDocumentQuickBackup	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_QUICK_BACKUP

	call	FilePushDir
	call	SetBackupDir
	jc	done

	; put up a dialog box telling the user what is happening

	mov	cx, si
	mov	bx, handle QuickBackupDialog
	mov	si, offset QuickBackupDialog
	push	ds:[LMBH_handle]
	call	UserCreateDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage
	call	MemDerefStackDS
	pushdw	bxsi				;save dialog OD
	mov	si, cx				;*ds:si = document

	;
	; check if document is itself a backup
	;
	call	CheckIfBackup
	jc	backupError

	mov	ax, MSG_GEN_DOCUMENT_UPDATE
	call	ObjCallInstanceNoLock

	; allocate a buffer on the stach and construct the source name

	push	si, ds
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, ds:[di].GDI_fileHandle	;si = source (file handle)
	lea	di, ds:[di].GDI_fileName
	segmov	es, ds				;es:di = dest name
	clr	dx				;current dir = dest

	clr	ax
	mov	ds, ax				;signal source is a file handle
	call	FileCopy
	pop	si, ds
	jnc	noError

backupError:
	mov	ax, SDBT_BACKUP_ERROR
	call	CallUserStandardDialog
	jmp	common

noError:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GDI_attrs, mask GDA_BACKUP_EXISTS
common:
	call	SendNotificationToDC

	popdw	bxsi
	call	UserDestroyDialog

done:
	call	FilePopDir

	ret

OLDocumentQuickBackup	endm
endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for NIKE project


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckIfBackup

DESCRIPTION:	Check if current doc is in backup dir

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	carry set if in backup dir

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/28/94		Initial version

------------------------------------------------------------------------------@


CheckIfBackup	proc	near
	uses	ax, cx, dx, bp, ds, si, es, di
	.enter
	mov	cx, size PathName
	sub	sp, cx
	mov	dx, ss
	mov	bp, sp
	mov	ax, MSG_GEN_PATH_GET
	call	ObjCallInstanceNoLock		; cx = disk handle
	jc	done				; if can't get path, pretend
						;	is backup dir, no
						;	backup or restore
	mov	ds, dx
	mov	si, bp				; ds:si = path 1, cx = disk 1
	mov	ax, segment backupDirDisk
	mov	es, ax
	mov	dx, es:[backupDirDisk]
	mov	di, offset backupDirPath
	call	FileComparePaths
	cmp	al, PCT_EQUAL			; same path?
	stc					; assume so
	je	done
	clc					; else, not backup dir
done:
	lea	sp, ds:[si][size PathName]
	.leave
	ret
CheckIfBackup	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ConstructFullPathToESDI

DESCRIPTION:	Construct the full path to a document into es:di

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - buffer

RETURN:
	ds:di - pointing to GDI_fileName
	cx - disk handle

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/11/92		Initial version

------------------------------------------------------------------------------@


ConstructFullPathToESDI	proc	near	uses ax, bx, di
	.enter

	mov	ax, ATTR_GEN_PATH_DATA	
	call	ObjVarFindData
	mov	cx, ds:[bx].GFP_disk		;cx = disk handle
	push	si
	lea	si, ds:[bx].GFP_path		;ds:si = source path
SBCS <	cmp	{char} ds:[si], C_BACKSLASH				>
DBCS <	cmp	{wchar} ds:[si], C_BACKSLASH				>
	jz	10$
	call	copyString
10$:
	LocalLoadChar ax, C_BACKSLASH
	LocalPutChar esdi, ax
	pop	si
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	lea	si, ds:[si].GDI_fileName	;ds:si = source name
	call	copyString

	.leave
	ret

;---

	; copy ds:si to es:di, leave es:di pointing at null

copyString:
	push	si
copyLoop:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax
	jnz	copyLoop
	LocalPrevChar	esdi
	pop	si
	retn

ConstructFullPathToESDI	endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentRecoverQuickBackup --
		MSG_GEN_DOCUMENT_RECOVER_QUICK_BACKUP for OLDocumentClass

DESCRIPTION:	Recover a document from the quick backup

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
	Tony	8/10/92		Initial version

------------------------------------------------------------------------------@


OLDocumentRecoverQuickBackup	method dynamic	OLDocumentClass,
					MSG_GEN_DOCUMENT_RECOVER_QUICK_BACKUP

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_CLOSING
	jnz	error

	mov	ax, SDBT_REVERT_QUICK_CONFIRM
	call	FarCallStandardDialogDS_SI
	cmp	ax, IC_YES
	jnz	error

	mov	ax, GDO_REVERT_QUICK
	call	OLDocSetOperation

	mov	ax, MSG_GEN_DOCUMENT_CLOSE_FILE
	call	ObjCallInstanceNoLock

	; at this point we must queue a message to finish the revert, since
	; we need to be fully detached before physically doing the revert

	mov	ax, MSG_OL_DOCUMENT_CONTINUE_REVERT_QUICK
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	Destroy	ax, cx, dx, bp
	ret

error:
	call	OLDocClearOperation
	Destroy	ax, cx, dx, bp
	ret

OLDocumentRecoverQuickBackup	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentContinueRevertQuick --
		MSG_OL_DOCUMENT_CONTINUE_REVERT_QUICK for OLDocumentClass

DESCRIPTION:	Continue reverting after a trip through the queue

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
	Tony	10/30/91		Initial version

------------------------------------------------------------------------------@


OLDocumentContinueRevertQuick	method dynamic	OLDocumentClass,
				MSG_OL_DOCUMENT_CONTINUE_REVERT_QUICK

	call	FilePushDir
	call	SetBackupDir

	; allocate a buffer on the stach and construct the source name

	sub	sp, size PathName
	mov	di, sp
	segmov	es, ss

	;
	; error, if current file is in backup dir
	;
	call	CheckIfBackup
	jc	revertError

	push	si
	call	ConstructFullPathToESDI
	mov	dx, cx				;dx = dest disk handle

	clr	cx				;current dir = source
	call	FileCopy
	pop	si
	jnc	noError

revertError:
	mov	ax, SDBT_REVERT_QUICK_ERROR
	call	FarCallStandardDialogDS_SI

noError:
	add	sp, size PathName
	call	FilePopDir

	; mark the document as not dirty

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GDI_attrs, not (mask GDA_DIRTY or mask GDA_SAVE_FAILED)

	mov	ax, MSG_GEN_DOCUMENT_REOPEN_FILE
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_DOCUMENT_FILE_CHANGED_REINITIALIZE_CREATED_UI
	call	ObjCallInstanceNoLock

	ret

OLDocumentContinueRevertQuick	endm



COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentSetEmpty -- MSG_GEN_DOCUMENT_SET_EMPTY
						for OLDocumentClass

DESCRIPTION:	Set the default empty file

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
	Tony	8/11/92		Initial version

------------------------------------------------------------------------------@


OLDocumentSetEmpty	method dynamic	OLDocumentClass,
						MSG_GEN_DOCUMENT_SET_EMPTY,
						MSG_GEN_DOCUMENT_CLEAR_EMPTY

	call	OLDocMarkBusy

	; see if a default empty file exists

	push	ax
	call	FilePushDir
	call	SetTemplateDir
	mov	bx, handle defaultDocumentName
	call	MemLock
	mov	es, ax
 assume es:nothing
	mov	dx, es:[defaultDocumentName]		;es:dx = default name

	push	ds
	segmov	ds, es
	call	FileGetAttributes			;test for existence
	pop	ds
	pop	ax					;ax = message
	jc	noneExists

	; file exists

	cmp	ax, MSG_GEN_DOCUMENT_CLEAR_EMPTY
	mov	ax, SDBT_QUERY_CLEAR_EMPTY
	jz	gotMessage
	mov	ax, SDBT_QUERY_SET_EMPTY_ONE_EXISTS
	jmp	gotMessage

noneExists:
	cmp	ax, MSG_GEN_DOCUMENT_CLEAR_EMPTY
	jz	done
	mov	ax, SDBT_QUERY_SET_EMPTY_NONE_EXISTS

gotMessage:
	call	CallUserStandardDialog
	cmp	ax, IC_YES
	jz	setEmpty
	cmp	ax, IC_NO
	jnz	done

	; reset the default empty document

	push	ds
	segmov	ds, es
	call	FileDelete
	pop	ds
done:
	mov	bx, handle defaultDocumentName
	call	MemUnlock
	call	FilePopDir

	mov	bx, 1				;update doc control (not losing
	call	SendNotificationToDC		;target)

	call	OLDocMarkNotBusy
	ret

setEmpty:

	push	dx
	mov	ax, MSG_GEN_DOCUMENT_UPDATE
	call	ObjCallInstanceNoLock
	pop	dx

	push	si, ds
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, ds:[di].GDI_fileHandle	;si = source (file handle)
	mov	di, dx				;es:di = dest
	clr	dx				;current dir = dest

	clr	ax
	mov	ds, ax				;signal source is a file handle
	call	FileCopy
	pop	si, ds
	jc	error

	; mark the new document as a template

	push	ds
	segmov	ds, es
	mov	dx, di				;ds:dx = file
	mov	ax, mask GFHF_TEMPLATE
	push	ax				;new flags
	segmov	es, ss
	mov	di, sp				;es:di points at flags
	mov	ax, FEA_FLAGS
	mov	cx, size word
	call	FileSetPathExtAttributes
	pop	ax
	pop	ds
	jnc	done

error:
	mov	ax, SDBT_SET_EMPTY_ERROR
	call	CallUserStandardDialog
	jmp	done

OLDocumentSetEmpty	endm



COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentSetDefault -- MSG_GEN_DOCUMENT_SET_DEFAULT
						for OLDocumentClass

DESCRIPTION:	Set the default empty file

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
	Tony	8/11/92		Initial version

------------------------------------------------------------------------------@


OLDocumentSetDefault	method dynamic	OLDocumentClass,
						MSG_GEN_DOCUMENT_SET_DEFAULT,
						MSG_GEN_DOCUMENT_CLEAR_DEFAULT
					uses bx, si
	mov	bx, ds:[LMBH_handle]
msg		local	word	push	ax
category	local	INI_CATEGORY_BUFFER_SIZE dup (char)
	.enter

	; get category from app object

	push	ds
	push	bp
	mov	cx, ss
	lea	dx, category
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	GenCallApplication
	pop	bp

	push	si, bp
	segmov	ds, ss
	lea	si, category			;ds:si = category
	mov	cx, cs
	mov	dx, offset defaultKey		;cx:dx = key
	mov	bp, INITFILE_INTACT_CHARS	;create buffer
	call	InitFileReadString
	pop	si, bp
	pop	ds
	jc	noneExists

	; file exists

	call	MemFree
	cmp	msg, MSG_GEN_DOCUMENT_CLEAR_DEFAULT
	mov	ax, SDBT_QUERY_CLEAR_DEFAULT
	jz	gotMessage
	mov	ax, SDBT_QUERY_SET_DEFAULT_ONE_EXISTS
	jmp	gotMessage

noneExists:
	cmp	ax, MSG_GEN_DOCUMENT_CLEAR_DEFAULT
	jz	done
	mov	ax, SDBT_QUERY_SET_DEFAULT_NONE_EXISTS

gotMessage:

	call	CallUserStandardDialog
	cmp	ax, IC_YES
	jz	setDefault
	cmp	ax, IC_NO
	jnz	done

	; reset the default empty document

	segmov	ds, ss
	lea	si, category			;ds:si = category
	mov	cx, cs
	mov	dx, offset defaultKey		;cx:dx = key
	call	InitFileDeleteEntry
done:
	.leave
	call	MemDerefDS
	mov	bx, 1				;update doc control (not losing
	call	SendNotificationToDC		;target)
	ret

setDefault:

	; fetch the path from the document object into a block on the heap.

	push	bp
	mov	ax, MSG_GEN_PATH_GET
	clr	dx
	call	ObjCallInstanceNoLock

	; figure the final size we'll need for the block: the current size +
	; room for a virtual name + separator and null-terminator + the bytes
	; required to hold the saved disk handle.

	mov	bx, dx
	mov	ax, MGIT_SIZE
	call	MemGetInfo			; ax <- current block size
	add	ax, size FileLongName + 2	; add room for filename & sep.

	mov	bx, cx				; bx <- disk handle
	clr	cx				; just figure size, thanks
	call	DiskSave			; cx <- bytes required to save
						;  the disk handle
	add	ax, cx

	; now enlarge the block to hold all that.

	push	cx				; save buffer size required
	push	bx				; and disk handle
	mov	bx, dx				; bx <- path block again
	mov	cx, mask HAF_LOCK shl 8
	call	MemReAlloc
	jc	insufficientMemory

	; find the null-terminator in the path...

	mov	es, ax
	clr	di
	clr	ax
	mov	cx, -1
	LocalFindChar

	; append a backslash to it to separate it from the file name

	LocalPrevChar	esdi
	LocalLoadChar ax, C_BACKSLASH
	LocalPrevChar	esdi	; point to char before null
SBCS <	scasb			; already separated?			>
DBCS <	scasw			; already separated?			>
	je	addFileName	; yes
	LocalPutChar	esdi, ax	; no -- store one
addFileName:

	; tack the filename onto the end, stopping as soon as we get to the
	; null terminator

	push	si
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	add	si, offset GDI_fileName
EC <	mov	cx, size GDI_fileName					>
nameCopyLoop:
	LocalGetChar	ax, dssi
	LocalPutChar	esdi, ax
	LocalIsNull	ax
EC <	loopne	nameCopyLoop						>
EC <	ERROR_NE	OL_DOCUMENT_INVALID_DOCUMENT_FILE_NAME		>
NEC <	jne	nameCopyLoop						>
	pop	si

   	pop	bx		; bx <- disk handle
	pop	cx		; cx <- size required to save it
	call	DiskSave	; do it, babe

	; arrange the registers correctly for writing the whole thing
	; out to the ini file under the passed key.

	mov	bx, dx		; bx <- data handle (for safekeeping)
	pop	bp		; bp <- frame pointer
	push	bp, si, ds	;  that we're about to nuke...
	lea	si, ss:[category]
	segmov	ds, ss		; ds:si <- category

	add	di, cx		; di <- total # bytes to write
	mov	bp, di		; bp <- size of buffer
	clr	di		; es:di <- buffer of data
	mov	cx, cs		; cx:dx <- key
	mov	dx, offset defaultKey

	call 	InitFileWriteData
	call	InitFileCommit
	pop	bp, si, ds

freeDone:
	call	MemFree
	jmp	done

insufficientMemory:
	pop	bp
	jmp	freeDone

OLDocumentSetDefault	endm

defaultKey	char	"defaultDocument", 0



COMMENT @----------------------------------------------------------------------

MESSAGE:	OLDocumentCopyTo -- MSG_GEN_DOCUMENT_COPY_TO for OLDocumentClass

DESCRIPTION:	Make a copy of this document

PASS:
	*ds:si - instance data
	es - segment of OLDocumentClass

	ax - The message

	ss:bp - DocumentCommonParams

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
	Tony	8/12/92		Initial version

------------------------------------------------------------------------------@


OLDocumentCopyTo	method dynamic	OLDocumentClass,
						MSG_GEN_DOCUMENT_COPY_TO

	call	OLDocMarkBusy

	; set the destination directory to be that of the destination

	call	PushAndSetPath
	jc	done

	; look for the destination already existing

	push	ds
	segmov	ds, ss
	lea	dx, ss:[bp].DCP_name
	call	FileGetAttributes
	pop	ds
	jc	doSave				;if does not exist then save it

	mov	ax, SDBT_FILE_SAVE_AS_FILE_EXISTS
	call	FarCallStandardDialogSS_BP
	cmp	ax, IC_YES
	stc
	jnz	done

doSave:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_READ_ONLY
	jz	update

	; warn user that changes made to this document will not be copied.

	mov	ax, SDBT_FILE_COPY_FILE_IS_PUBLIC_OR_READ_ONLY
	movdw	bxdi, ssbp
	call	FarCallStandardDialogDS_SI
	jmp	retry

update:
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_UPDATE
	call	ObjCallInstanceNoLock
	pop	bp

retry:
	push	si, ds
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, ds:[di].GDI_fileHandle	;si = source (file handle)

	clr	ax
	mov	ds, ax
	segmov	es, ss
	lea	di, ss:[bp].DCP_name
	clr	dx				;current dir = dest
	call	FileCopy
	pop	si, ds

	jnc	done

	mov	cx, offset CallStandardDialogSS_BP
	call	HandleSaveError
	jnc	retry

done:
	call	FilePopDir

	call	OLDocMarkNotBusy
	ret

OLDocumentCopyTo	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move this document

CALLED BY:	MSG_GEN_DOCUMENT_MOVE_TO
PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		ds:bx	= OLDocumentClass object (same as *ds:si)
		es 	= segment of OLDocumentClass
		ax	= message #
		ss:bp	= DocumentCommonParams
RETURN:		carry set if error
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _DUI

OLDocumentMoveTo	method dynamic OLDocumentClass, 
					MSG_GEN_DOCUMENT_MOVE_TO
	; can't move a read-only file

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDI_attrs, mask GDA_READ_ONLY
	jz	notReadOnly

	mov	ax, SDBT_CANT_MOVE_READ_ONLY_DOCUMENT
	call	FarCallStandardDialogDS_SI
	jmp	done	

notReadOnly:
	; compare name and path to make sure we aren't moving to the same file

	push	si
	lea	si, ds:[di].GDI_fileName
	segmov	es, ss
	lea	di, ss:[bp].DCP_name
	clr	cx
	call	LocalCmpStrings
	pop	si
	jnz	continue

	push	si
	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath
	lea	si, ds:[bx].GFP_path
	mov	cx, ax
	lea	di, ss:[bp].DCP_path
	mov	dx, ss:[bp].DCP_diskHandle
	call	FileComparePaths
	pop	si
	cmp	al, PCT_EQUAL
	je	done

continue:
	; save changes and close the file

	call	OLDocMarkBusy

	push	bp
	mov	ax, MSG_GEN_DOCUMENT_CLOSE_FILE
	call	ObjCallInstanceNoLock
	pop	bp

	push	bp
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_OL_DOCUMENT_CONTINUE_MOVE_TO
	mov	dx, size DocumentCommonParams
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bp
done:
	ret
OLDocumentMoveTo	endm

endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for Redwood project



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentContinueMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish 'move to' operation.

CALLED BY:	MSG_OL_DOCUMENT_CONTINUE_MOVE_TO
PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		ds:bx	= OLDocumentClass object (same as *ds:si)
		es 	= segment of OLDocumentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _DUI

OLDocumentContinueMoveTo	method dynamic OLDocumentClass, 
					MSG_OL_DOCUMENT_CONTINUE_MOVE_TO

	; set the destination directory to be that of the destination

	call	PushAndSetPath
LONG	jc	reopen

	; look for the destination already existing

	push	ds
	segmov	ds, ss
	lea	dx, ss:[bp].DCP_name
	call	FileGetAttributes
	pop	ds
	jc	moveFile			;if does not exist then move it

	mov	ax, SDBT_FILE_SAVE_AS_FILE_EXISTS
	call	FarCallStandardDialogSS_BP
	cmp	ax, IC_YES
	stc					;assume not 'Yes'
	jnz	popDir				;abort if not 'Yes'

	push	ds				;ok, we want to overwrite
	segmov	ds, ss				; so delete the destination
	call	FileDelete			; file
	pop	ds
	jc	handleError

moveFile:
	push	ds, si

	mov	ax, ATTR_GEN_PATH_DATA
	mov	dx, TEMP_GEN_PATH_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath

	segmov	es, ds
	lea	di, ds:[bx].GFP_path		; es:di = source path

	push	di
	LocalClrChar	ax
	mov	cx, length PathName
	LocalFindChar				; scan for end of path
EC <	tst	cx							>
EC <	ERROR_Z	-1				; this should not happen>

	mov	ax, di				; save offset to end of path
SBCS <	cmp	{byte} es:[di-2], C_BACKSLASH	; does it already have a '\'>
DBCS <	cmp	{wchar} es:[di-(2*(size wchar))], C_BACKSLASH		>
	jne	addSlash
	LocalPrevChar	esdi
addSlash:
SBCS <	mov	{byte} es:[di-1], C_BACKSLASH	; add '\'		>
DBCS <	mov	{wchar} es:[di-(1*(size wchar))], C_BACKSLASH		>
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	lea	si, ds:[si].GDI_fileName
	LocalCopyNString			; add filename
	pop	si				; ds:si = source path
	mov	cx, ds:[bx].GFP_disk		; cx = source disk handle

	segmov	es, ss
	lea	di, ss:[bp].DCP_name		; es:di = destination filename
	clr	dx				; dx = destination disk handle

	push	ax
	call	FileMove
	pop	si
SBCS <	mov	{byte} ds:[si-1], 0		; restore end of path	>
DBCS <	mov	{wchar} ds:[si-(1*(size wchar))], 0			>
	pop	ds, si
	jnc	popDir				; jmp if successful

handleError:
	call	HandleMoveToError
	jnc	moveFile

popDir:
	call	FilePopDir
	jc	reopen

	push	bp
	mov	ax, MSG_GEN_PATH_SET		; set path to new document
	mov	cx, ss				;  location
	lea	dx, ss:[bp].DCP_path
	mov	bp, ss:[bp].DCP_diskHandle
	call	ObjCallInstanceNoLock
	pop	bp

	push	ds, si
	segmov	es, ds
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GDI_attrs, not mask GDA_UNTITLED	; now titled

	lea	di, ds:[di].GDI_fileName	; set new filename

	segmov	ds, ss
	lea	si, ss:[bp].DCP_name
	mov	cx, length FileLongName
	LocalCopyNString
	pop	ds, si

reopen:
	push	bp
	mov	ax, MSG_GEN_DOCUMENT_REOPEN_FILE
	call	ObjCallInstanceNoLock
	pop	bp

	mov	bx, 1
	call	SendCompleteUpdateToDC

	call	OLDocMarkNotBusy

	ret
OLDocumentContinueMoveTo	endm

endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for Redwood project



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleMoveToError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle 'move to' errors.

CALLED BY:	OLDocumentContinueMoveTo
PASS:		*ds:si - document object
		ax - error code
RETURN:		carry clear to retry
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	4/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _DUI

HandleMoveToError	proc	near
	uses	bx, dx, di
	.enter

EC <	call	AssertIsGenDocument					>

	;
	; If not opened by the user, there's no retry.
	; 
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLDI_attrs, mask OLDA_USER_OPENED
	jz	doneError

	cmp	ax, ERROR_WRITE_PROTECTED
	jz	writeProtect

	cmp	ax, ERROR_FILE_EXISTS
	jz	fileExists

	cmp	ax, ERROR_ACCESS_DENIED
	jz	fileExists

	cmp	ax, ERROR_FILE_IN_USE
	jz	fileExists

	mov	dx, SDBT_FILE_MOVE_INSUFFICIENT_DISK_SPACE
	cmp	ax, ERROR_SHORT_READ_WRITE
	jz	gotErrorCode

	mov	dx, SDBT_FILE_ILLEGAL_NAME
	cmp	ax, ERROR_INVALID_NAME
	jz	gotErrorCode

	mov	dx, SDBT_FILE_MOVE_ERROR
gotErrorCode:

	; put error code in buffer

	sub	sp, ERROR_STRING_BUFFER
	mov	di, sp
	push	dx, cx, es
	mov	bx, ss
	mov	es, bx				;es:di = bx:di = buffer
	mov	cx, mask UHTAF_NULL_TERMINATE
	clr	dx
	call	UtilHex32ToAscii
	pop	ax, cx, es

	call	FarCallStandardDialogDS_SI

	add	sp, ERROR_STRING_BUFFER
	jmp	doneError

writeProtect:
	mov	ax, SDBT_FILE_MOVE_WRITE_PROTECTED
	call	FarCallStandardDialogDS_SI
	cmp	ax, IC_YES
	jnz	doneError
	clc
	jmp	done

fileExists:
	mov	ax, SDBT_UNABLE_TO_OVERWRITE_EXISTING_FILE
	call	FarCallStandardDialogSS_BP

doneError:
	stc
done:
	.leave
	ret
HandleMoveToError	endp

endif ;(not _NIKE) and (not _JEDIMOTIF) and (not _DUI) ;- Not needed for Redwood project

DocObscure ends
