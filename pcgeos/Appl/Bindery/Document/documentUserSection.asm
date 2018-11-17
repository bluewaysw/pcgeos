COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentUserSection.asm

ROUTINES:
	Name				Description
	----				-----------
METHODS:
	Name			Description
	----			-----------
    StudioDocumentInitSectionList  
				Initialize a section list (send # of
				entries)

				MSG_STUDIO_DOCUMENT_INIT_SECTION_LIST
				StudioDocumentClass

    StudioDocumentQuerySectionList  
				Handle a dynamic list query for a section
				list

				MSG_STUDIO_DOCUMENT_QUERY_SECTION_LIST
				StudioDocumentClass

    StudioDocumentInsertSection	Insert a section

				MSG_STUDIO_DOCUMENT_INSERT_SECTION
				StudioDocumentClass

    StudioDocumentAppendSection	Append a section

				MSG_STUDIO_DOCUMENT_APPEND_SECTION
				StudioDocumentClass

    StudioDocumentCreateTitlePage  
				Create a title page

				MSG_STUDIO_DOCUMENT_CREATE_TITLE_PAGE
				StudioDocumentClass

    StudioDocumentDeleteTitlePage  
				Delete a title page

				MSG_STUDIO_DOCUMENT_DELETE_TITLE_PAGE
				StudioDocumentClass

    StudioDocumentGotoTitlePage	Goto a title page

				MSG_STUDIO_DOCUMENT_GOTO_TITLE_PAGE
				StudioDocumentClass

    StudioDocumentUpdateRenameSection  
				Update the text objects in the "rename
				section" dialog box

				MSG_STUDIO_DOCUMENT_UPDATE_RENAME_SECTION
				StudioDocumentClass

    StudioDocumentDeleteSection	Delete a section

				MSG_STUDIO_DOCUMENT_DELETE_SECTION
				StudioDocumentClass

    StudioDocumentRenameSection	Rename a section

				MSG_STUDIO_DOCUMENT_RENAME_SECTION
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the UI section related code for StudioDocumentClass

	$Id: documentUserSection.asm,v 1.1 97/04/04 14:39:15 newdeal Exp $

------------------------------------------------------------------------------@

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentInitSectionList --
		MSG_STUDIO_DOCUMENT_INIT_SECTION_LIST for StudioDocumentClass

DESCRIPTION:	Initialize a section list (send # of entries)

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentInitSectionList	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_INIT_SECTION_LIST

	push	ds:[di].SDI_currentSection	;save the current section

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

StudioDocumentInitSectionList	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentQuerySectionList --
		MSG_STUDIO_DOCUMENT_QUERY_SECTION_LIST for StudioDocumentClass

DESCRIPTION:	Handle a dynamic list query for a section list

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentQuerySectionList	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_QUERY_SECTION_LIST

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

StudioDocumentQuerySectionList	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentInsertSection --
		MSG_STUDIO_DOCUMENT_INSERT_SECTION for StudioDocumentClass

DESCRIPTION:	Insert a section

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentInsertSection	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_INSERT_SECTION

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

StudioDocumentInsertSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentAppendSection --
		MSG_STUDIO_DOCUMENT_APPEND_SECTION for StudioDocumentClass

DESCRIPTION:	Append a section

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentAppendSection	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_APPEND_SECTION

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

StudioDocumentAppendSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentCreateTitlePage --
		MSG_STUDIO_DOCUMENT_CREATE_TITLE_PAGE for StudioDocumentClass

DESCRIPTION:	Create a title page

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentCreateTitlePage	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_CREATE_TITLE_PAGE

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

	mov	ax, MSG_STUDIO_DOCUMENT_GOTO_TITLE_PAGE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

done:
	ret

StudioDocumentCreateTitlePage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentDeleteTitlePage --
		MSG_STUDIO_DOCUMENT_DELETE_TITLE_PAGE for StudioDocumentClass

DESCRIPTION:	Delete a title page

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentDeleteTitlePage	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_DELETE_TITLE_PAGE

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

StudioDocumentDeleteTitlePage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentGotoTitlePage --
		MSG_STUDIO_DOCUMENT_GOTO_TITLE_PAGE for StudioDocumentClass

DESCRIPTION:	Goto a title page

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentGotoTitlePage	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_GOTO_TITLE_PAGE

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

StudioDocumentGotoTitlePage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentUpdateRenameSection --
		MSG_STUDIO_DOCUMENT_UPDATE_RENAME_SECTION for StudioDocumentClass

DESCRIPTION:	Update the text objects in the "rename section" dialog box

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentUpdateRenameSection	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_UPDATE_RENAME_SECTION

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

StudioDocumentUpdateRenameSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentDeleteSection -- MSG_STUDIO_DOCUMENT_DELETE_SECTION
						for StudioDocumentClass

DESCRIPTION:	Delete a section

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentDeleteSection	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_DELETE_SECTION

	push	si
	GetResourceHandleNS	DeleteSectionList, bx
	mov	si, offset DeleteSectionList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax = section to delete
	pop	si

	call	DeleteSection

	ret

StudioDocumentDeleteSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentRenameSection -- MSG_STUDIO_DOCUMENT_RENAME_SECTION
						for StudioDocumentClass

DESCRIPTION:	Rename a section

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

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
StudioDocumentRenameSection	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_RENAME_SECTION
sectionName	local	MAX_SECTION_NAME_SIZE dup (char)
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

StudioDocumentRenameSection	endm

DocSTUFF ends
