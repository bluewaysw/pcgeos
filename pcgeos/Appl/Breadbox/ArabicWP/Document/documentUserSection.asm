COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentUserSection.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the UI section related code for WriteDocumentClass

	$Id: documentUserSection.asm,v 1.1 97/04/04 15:56:36 newdeal Exp $

------------------------------------------------------------------------------@

DocSTUFF segment resource

if _SECTION_SUPPORT

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentInitSectionList --
		MSG_WRITE_DOCUMENT_INIT_SECTION_LIST for WriteDocumentClass

DESCRIPTION:	Initialize a section list (send # of entries)

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx:dx - list

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentInitSectionList	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_INIT_SECTION_LIST

	push	ds:[di].WDI_currentSection	;save the current section

	call	LockMapBlockDS			;bp = block to unlock
	mov	si, offset SectionArray
	clr	bx				;no callback
	call	ElementArrayGetUsedCount	;ax = number of entries
	call	VMUnlockDS

	movdw	bxsi, cxdx
	mov_tr	cx, ax
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	di
	call	ObjMessage

	pop	cx
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage
	clr	cx
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	clr	di
	GOTO	ObjMessage

WriteDocumentInitSectionList	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentQuerySectionList --
		MSG_WRITE_DOCUMENT_QUERY_SECTION_LIST for WriteDocumentClass

DESCRIPTION:	Handle a dynamic list query for a section list

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx:dx - list
	bp - item number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentQuerySectionList	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_QUERY_SECTION_LIST

	mov_tr	ax, bp				;ax = entry #

	call	LockMapBlockDS			;bp = block to unlock

	sub	sp, size ReplaceItemMonikerFrame
	mov	bp, sp
	pushdw	cxdx
	mov	ss:[bp].RIMF_item, ax
	mov	ss:[bp].RIMF_sourceType, VMST_FPTR
	mov	ss:[bp].RIMF_dataType, VMDT_TEXT
	mov	ss:[bp].RIMF_itemFlags, 0

	mov	si, offset SectionArray
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	BAD_SECTION_NUMBER					>
	mov	si, ds:[si]
	mov	ax, ds:[si].NAH_dataSize
	add	ax, size NameArrayElement
	add	di, ax				;ds:di = name
	sub	cx, ax				;cx = length
	movdw	ss:[bp].RIMF_source, dsdi
	mov	ss:[bp].RIMF_length, cx

	popdw	bxsi				;bxsi = list
	mov	dx, size ReplaceItemMonikerFrame
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	di, mask MF_FIXUP_DS or mask MF_STACK or mask MF_CALL
	call	ObjMessage

	add	sp, size ReplaceItemMonikerFrame
	call	VMUnlockDS

	ret

WriteDocumentQuerySectionList	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentInsertSection --
		MSG_WRITE_DOCUMENT_INSERT_SECTION for WriteDocumentClass

DESCRIPTION:	Insert a section

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentInsertSection	method dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_INSERT_SECTION

	push	si
	GetResourceHandleNS	InsertSectionList, bx
	mov	si, offset InsertSectionList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax = section to insert before
	mov	cx, bx
	mov	dx, offset InsertSectionText	;cxdx = text object
	clr	di				;flag = insert
	pop	si

	call	InsertOrAppendSection

	jnc	done
	mov	ax, offset SectionSameNameString
	call	DisplayError
done:

	ret

WriteDocumentInsertSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentAppendSection --
		MSG_WRITE_DOCUMENT_APPEND_SECTION for WriteDocumentClass

DESCRIPTION:	Append a section

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentAppendSection	method dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_APPEND_SECTION

	push	si
	GetResourceHandleNS	AppendSectionList, bx
	mov	si, offset AppendSectionList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax = section to append after
	mov	cx, bx
	mov	dx, offset AppendSectionText	;cxdx = text object
	mov	di, 1				;flag = append
	pop	si

	call	InsertOrAppendSection

	jnc	done
	mov	ax, offset SectionSameNameString
	call	DisplayError
done:
	ret

WriteDocumentAppendSection	endm

endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentCreateTitlePage --
		MSG_WRITE_DOCUMENT_CREATE_TITLE_PAGE for WriteDocumentClass

DESCRIPTION:	Create a title page

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	9/28/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentCreateTitlePage	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_CREATE_TITLE_PAGE

	call	LockMapBlockES
	call	DoesTitlePageExist
	call	VMUnlockES
	jc	done

	mov	ax, offset CreateTitlePageString
	call	ConfirmIfNeeded
	cmp	ax, IC_YES
	jnz	done

	clr	cx
	mov	dx, offset TitlePageSectionName
	clr	ax					;ax = section #
	clr	di					;insert
	call	InsertOrAppendSection

	mov	ax, MSG_WRITE_DOCUMENT_GOTO_TITLE_PAGE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

done:
	ret

WriteDocumentCreateTitlePage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentDeleteTitlePage --
		MSG_WRITE_DOCUMENT_DELETE_TITLE_PAGE for WriteDocumentClass

DESCRIPTION:	Delete a title page

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	9/28/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentDeleteTitlePage	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_DELETE_TITLE_PAGE

	call	LockMapBlockES
	call	DoesTitlePageExist
	call	VMUnlockES
	jnc	done

	mov	ax, offset DeleteTitlePageString
	call	ConfirmIfNeeded
	cmp	ax, IC_YES
	jnz	done

	clr	ax					;ax = section #
	call	DeleteSection
done:
	ret

WriteDocumentDeleteTitlePage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentGotoTitlePage --
		MSG_WRITE_DOCUMENT_GOTO_TITLE_PAGE for WriteDocumentClass

DESCRIPTION:	Goto a title page

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	9/28/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentGotoTitlePage	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_GOTO_TITLE_PAGE

	call	LockMapBlockES
	call	DoesTitlePageExist
	jnc	done

	mov	ax, MSG_VIS_TEXT_SELECT_START
	mov	di, mask MF_RECORD
	call	ObjMessage
	call	SendToFirstArticle

	mov	ax, MSG_VIS_TEXT_SHOW_POSITION
	clrdw	dxcx
	mov	di, mask MF_RECORD
	call	ObjMessage
	call	SendToFirstArticle

done:
	call	VMUnlockES
	ret

WriteDocumentGotoTitlePage	endm

if _SECTION_SUPPORT

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentUpdateRenameSection --
		MSG_WRITE_DOCUMENT_UPDATE_RENAME_SECTION for WriteDocumentClass

DESCRIPTION:	Update the text objects in the "rename section" dialog box

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx - current selection

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentUpdateRenameSection	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_UPDATE_RENAME_SECTION

	cmp	cx, GIGS_NONE
	jz	exit

	call	IgnoreUndoAndFlush

	GetResourceHandleNS	RenameSectionText, bx

	call	LockMapBlockDS			;bp = block to unlock

	mov_tr	ax, cx
	mov	si, offset SectionArray
	call	ChunkArrayElementToPtr
EC <	cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT		>
EC <	ERROR_Z	BAD_SECTION_NUMBER					>
	mov	si, ds:[si]
	mov	ax, ds:[si].NAH_dataSize
	add	ax, size NameArrayElement
	add	di, ax				;ds:di = name
	sub	cx, ax				;cx = length
DBCS <	shr	cx, 1				;# bytes -> # chars	>

	mov	si, offset RenameSectionText
	movdw	dxbp, dsdi
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	clr	di
	call	ObjMessage

	call	VMUnlockDS

	call	AcceptUndo

exit:
	ret

WriteDocumentUpdateRenameSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentDeleteSection -- MSG_WRITE_DOCUMENT_DELETE_SECTION
						for WriteDocumentClass

DESCRIPTION:	Delete a section

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentDeleteSection	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_DELETE_SECTION

	push	si
	GetResourceHandleNS	DeleteSectionList, bx
	mov	si, offset DeleteSectionList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax = section to delete
	pop	si

	call	DeleteSection

	ret

WriteDocumentDeleteSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentRenameSection -- MSG_WRITE_DOCUMENT_RENAME_SECTION
						for WriteDocumentClass

DESCRIPTION:	Rename a section

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentRenameSection	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_RENAME_SECTION
sectionName	local	MAX_SECTION_NAME_SIZE dup (TCHAR)
sectionNum	local	word
	.enter

	push	ds:[LMBH_handle], si

	; get the name and its length

	push	si
	push	bp
	GetResourceHandleNS	RenameSectionList, bx
	mov	si, offset RenameSectionList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage				;ax = selection
	pop	bp
	mov	sectionNum, ax

	push	bp
	mov	si, offset RenameSectionText
	mov	dx, ss
	lea	bp, sectionName
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage			;cx = length
	pop	bp
	pop	si
	stc
	jcxz	doneNoUnlock
	cmp	sectionNum, GIGS_NONE
	stc
	jz	doneNoUnlock

	; lock the section array

	call	LockMapBlockDS
	mov	si, offset SectionArray		;*ds:si = array

	; see if this section name already exists (its an error if so)

	segmov	es, ss
	lea	di, sectionName
	clr	dx
	call	NameArrayFind
	cmp	ax, CA_NULL_ELEMENT
	jz	noMatch
	mov	ax, offset SectionSameNameString
	call	DisplayError
	stc
	jmp	doneUnlock
noMatch:

	; change the name

	mov	ax, sectionNum
	call	NameArrayChangeName
	clc

doneUnlock:
	pushf
	call	VMDirtyDS
	call	VMUnlockDS
	popf
doneNoUnlock:

	popdw	bxsi
	call	MemDerefDS

	jc	exit

	; If we successfully renamed the section then we need to update the
	; title of any master page display 

	call	LockMapBlockES

	mov	ax, sectionNum
	call	SectionArrayEToP_ES
	mov	cx, es:[di].SAE_numMasterPages
	clr	bx
updateNameLoop:
	mov	ax, es:[di][bx].SAE_masterPages
	push	bx, cx
	call	FindOpenMasterPage
	mov	dx, bx				;dx = display block
	pop	bx, cx
	jnc	next
	mov	ax, sectionNum
	call	SetMPDisplayName
next:
	add	bx, size word
	loop	updateNameLoop

	mov	ax, mask NF_SECTION
	call	SendNotification

	call	VMUnlockES

	; we must redraw in case we are displaying section names

	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp

	clc
exit:
	.leave
	ret

WriteDocumentRenameSection	endm

endif

DocSTUFF ends
