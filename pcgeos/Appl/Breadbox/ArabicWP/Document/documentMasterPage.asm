COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentMasterPage.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the master page related code for WriteDocumentClass

	$Id: documentMasterPage.asm,v 1.1 97/04/04 15:56:40 newdeal Exp $

------------------------------------------------------------------------------@

DocCreate segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DuplicateMasterPage

DESCRIPTION:	Duplicate a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - SectionArrayElement

RETURN:
	ax - new master page VM block

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
DuplicateMasterPage	proc	far	uses bx, cx, dx, si, di, bp
	.enter
EC <	call	AssertIsWriteDocument					>

	; Duplicate empty master page block

	mov	bx, handle MasterPageTempUI
	call	DuplicateAndAttachObj		;ax = VM block, bx = mem handle
	push	ax

	; set the body to the correct attribute manager

	push	ds
	mov	ax, es:MBH_grobjBlock
	push	ax				;save VM block of main body
	call	WriteVMBlockToMemBlock
	mov_tr	cx, ax				;cx = handle of main body

	.warn -private
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, offset MasterPageBody
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	pop	ds:[di].WMPGOBI_mainGrobjBody
	call	MemUnlock
	pop	ds
	.warn @private

	mov	si, offset MasterPageBody
	mov	dx, offset AttributeManager
	mov	ax, MSG_GB_ATTACH_GOAM
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; Initialize the bounds of the body

	sub	sp, size RectDWord
	mov	bp, sp
	mov	ax, es:MBH_pageSize.XYS_width
	mov	ss:[bp].RD_right.low, ax
	mov	ax, es:MBH_pageSize.XYS_height
	mov	ss:[bp].RD_bottom.low, ax
	clr	ax
	mov	ss:[bp].RD_right.high, ax
	mov	ss:[bp].RD_bottom.high, ax
	clrdw	ss:[bp].RD_left, ax
	clrdw	ss:[bp].RD_top, ax
	mov	ax, MSG_GB_SET_BOUNDS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size RectDWord
	pop	ax

	.leave
	ret

DuplicateMasterPage	endp

DocCreate ends

DocManipCommon segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetSectionToOperateOn

DESCRIPTION:	Determine which section to operate on

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block
	ax, cx, dx - arguments to ComplexQuery (if query needed)

RETURN:
	carry - set to abort
	ax - section

DESTROYED:
	bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
GetSectionToOperateOn	proc	far
	class	WriteDocumentClass
EC <	call	AssertIsWriteDocument					>

	; if complex page layout then use current

	push	ax
	call	GetAppFeatures				;ax = features
	test	ax, mask WF_COMPLEX_PAGE_LAYOUT
	pop	ax
	jnz	useCurrentSection

	call	DoesTitlePageExist			;carry set if so
	jnc	useCurrentSection

	call	ComplexQuery
	cmp	ax, IC_NULL
	jz	abort
	cmp	ax, IC_DISMISS
	jz	abort
	cmp	ax, IC_YES
	mov	ax, 0
	jz	gotSection
	inc	ax
	jmp	gotSection

useCurrentSection:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].WDI_currentSection
gotSection:
	clc
	ret

abort:
	stc
	ret

GetSectionToOperateOn	endp

DocManipCommon ends

DocEditMP segment resource

DEMP_ObjMessageNoFlags	proc	near
	push	di
	clr	di
	call	ObjMessage
	pop	di
	ret
DEMP_ObjMessageNoFlags	endp

DEMP_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DEMP_ObjMessageFixupDS	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentEditMasterPage --
		MSG_WRITE_DOCUMENT_EDIT_MASTER_PAGE for WriteDocumentClass

DESCRIPTION:	Edit the master page for the document

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
	Tony	6/ 2/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentEditMasterPage	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_EDIT_MASTER_PAGE,
					MSG_WRITE_DOCUMENT_EDIT_HEADER,
					MSG_WRITE_DOCUMENT_EDIT_FOOTER
msg			local	word	push	ax
objChunk		local	word	push	si
bodyVMBlock		local	word
fileHandle		local	hptr
headerFooterMemHandle	local	word
	.enter

	call	LockMapBlockES

	call	GetFileHandle
	mov	fileHandle, bx

	cmp	ax, MSG_WRITE_DOCUMENT_EDIT_HEADER
	mov	ax, offset EditHeaderTitlePageString
	jz	gotStrings
	mov	ax, offset EditFooterTitlePageString
gotStrings:
	mov	cx, offset EditHeaderTitlePageTable
	mov	dx, CustomDialogBoxFlags \
			<0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>

	; if we don't have complex text attributes and we have a master
	; page then ask the user which one section to work on

	call	GetSectionToOperateOn
	jnc	5$
toAbort:
	jmp	abort
5$:

	; if there are multiple master pages then ask the user which master
	; page should be edited

	call	SectionArrayEToP_ES			;es:di = section
							;cx = element size
	clr	bx
	cmp	es:[di].SAE_numMasterPages, 1
	jz	gotMasterPage

	mov	ax, offset EditWhichMasterPageString
	mov	cx, offset EditWhichMasterPageTable
	mov	dx, CustomDialogBoxFlags \
			<0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>
	call	ComplexQuery			;ax = InteractionCommand
	cmp	ax, IC_NULL
	jz	toAbort
	cmp	ax, IC_DISMISS			;cancel
	jz	toAbort
	clr	bx
	cmp	ax, IC_YES			;left
	jz	gotMasterPage
	mov	bx, size word			;right

	; bx = offset to master page

gotMasterPage:
	mov	ax, es:[di][bx].SAE_masterPages	;ax = VM block

	mov	bodyVMBlock, ax
	call	WriteVMBlockToMemBlock		;ax = mem block

	; make the correct object the target/focus (for edit header/footer)

	mov	di, offset MPBH_header
	cmp	msg, MSG_WRITE_DOCUMENT_EDIT_HEADER
	jz	gotObjectToEdit
	mov	di, offset MPBH_footer
	cmp	msg, MSG_WRITE_DOCUMENT_EDIT_FOOTER
	jz	gotObjectToEdit
	clr	si				;no object -- just edit master
	jmp	gotObjectOptr
gotObjectToEdit:
	mov	ax, bodyVMBlock
	mov	bx, fileHandle
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax				;bx = master page block
	push	bx, ds
	call	ObjLockObjBlock
	mov	ds, ax
	movdw	axsi, ds:[di]
	mov	bx, fileHandle
	tst	ax				;if zero then none exists
	jz	null				;(margins too small)
	call	VMVMBlockToMemBlock
	mov	ss:[headerFooterMemHandle], ax
null:
	pop	bx, ds
	call	MemUnlock			;unlock master page block

	tst	ax
	jz	null2

gotObjectOptr:
	; only open the master page when there is header/footer to edit
	mov	di, si		; preserve the offset of header/footer obj
	mov	si, ss:[objChunk]
	mov	ax, ss:[bodyVMBlock]
	call	WriteVMBlockToMemBlock		; ax = mem block
	mov_tr	cx, ax	
	push	bp
	mov	ax, MSG_WRITE_DOCUMENT_OPEN_MASTER_PAGE
	call	ObjCallInstanceNoLock
	mov	si, di		; offset of header/footer obj
	tst	si
	jz	abort

	mov	ax, ss:[headerFooterMemHandle]
	mov_tr	bx, ax				;bxsi = object (header/footer)
	mov	ax, MSG_GO_BECOME_EDITABLE
	call	DEMP_ObjMessageNoFlags

	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL
	call	ObjMessage			;cxdx = ward
	movdw	bxsi, cxdx
	mov	dx, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SHOW_POSITION
	call	DEMP_ObjMessageNoFlags

	; Force Right to left text object
	mov	ax, MSG_VIS_TEXT_SET_FEATURES
	mov	cx, mask VTF_RIGHT_TO_LEFT
	mov	dx, 0
	call	DEMP_ObjMessageNoFlags

	; force the GeoWrite tool

	call	SetGeoWriteTool
	jmp	abort

null2:
	mov	ax, offset NoHeaderErrorString
	cmp	msg, MSG_WRITE_DOCUMENT_EDIT_HEADER
	jz	gotError
	mov	ax, offset NoFooterErrorString
gotError:
	call	DisplayError

abort:
	call	VMUnlockES

	.leave
	ret

WriteDocumentEditMasterPage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentOpenMasterPage --
		MSG_WRITE_DOCUMENT_OPEN_MASTER_PAGE for WriteDocumentClass

DESCRIPTION:	Open a master page

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx - memory handle of master page

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentOpenMasterPage	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_OPEN_MASTER_PAGE
document		local	lptr	push	si
bodyVMBlock		local	word
sectionNumber		local	word
masterPageOffset	local	word
contentBlock		local	hptr
displayBlock		local	hptr
fileHandle		local	hptr
	.enter

	call	LockMapBlockES
	call	MemBlockToVMBlockCX
	mov	bodyVMBlock, cx

	call	GetFileHandle
	mov	fileHandle, bx

	mov_tr	ax, cx
	call	FindOpenMasterPage
	jnc	notCurrentlyOpen

	; master page exists -- display handle is bx

	mov	si, offset MasterPageDisplay
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	DEMP_ObjMessageNoFlags
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	DEMP_ObjMessageNoFlags
	jmp	done

notCurrentlyOpen:

	; we must find the section number and master page offset

	mov_tr	cx, ax
	push	si
	segxchg	ds, es				;ds = map block, es = document
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset FindMasterToOpenCallback
	call	ChunkArrayEnum			;dx = offset of element
EC <	ERROR_NC MASTER_PAGE_NOT_FOUND					>
	mov	masterPageOffset, ax
	mov	di, dx
	call	ChunkArrayPtrToElement		;ax = element
	mov	sectionNumber, ax
	segxchg	ds, es
	pop	si

	; *** the master page is not currently being edited ***

	; start by duplicating blocks

	clr	ax				;make current process the owner
	mov	bx, handle MasterPageContent
	mov	cx, -1				;use thread in block
	call	ObjDuplicateResource		;bx = content block
	mov	contentBlock, bx
	mov	si, offset MasterPageContent
	mov	ax, MSG_WRITE_MASTER_PAGE_CONTENT_SET_DOCUMENT_AND_MP
	mov	cx, ds:[LMBH_handle]
	mov	dx, document			;cxdx = document
	push	bp
	mov	bp, bodyVMBlock
	call	DEMP_ObjMessageNoFlags
	pop	bp

	clr	ax				;make current process the owner
	mov	bx, handle MasterPageDisplay
	mov	cx, -1				;use thread in block
	call	ObjDuplicateResource		;bx = display block
	mov	displayBlock, bx
	mov	si, offset MasterPageDisplay
	mov	ax, MSG_WRITE_MASTER_PAGE_DISPLAY_SET_DOCUMENT_AND_MP
	mov	cx, ds:[LMBH_handle]
	mov	dx, document			;cxdx = document
	push	bp
	mov	bp, bodyVMBlock
	call	DEMP_ObjMessageNoFlags
	pop	bp

	; store the block in the master page array

	mov	si, offset OpenMasterPageArray
	call	ChunkArrayAppend		;ds:di = entry
	mov	ds:[di].OMP_display, bx
	mov	cx, contentBlock
	mov	ds:[di].OMP_content, cx
	mov	ax, bodyVMBlock
	mov	ds:[di].OMP_vmBlock, ax

	; add the display to the display control

	mov	cx, bx
	mov	dx, offset MasterPageDisplay	;cx:dx = display
	GetResourceHandleNS	WriteDisplayGroup, bx
	mov	si, offset WriteDisplayGroup
	mov	ax, MSG_GEN_ADD_CHILD
	push	bp

	mov	bp, CCO_LAST

	call	DEMP_ObjMessageNoFlags
	pop	bp

	mov	ax, sectionNumber
	mov	bx, masterPageOffset
	mov	dx, displayBlock
	mov	si, document
	call	SetMPDisplayName

	; if there are no overlapping MDI windows then nuke "redraw"

	GetResourceHandleNS	WriteDisplayControl, bx
	mov	si, offset WriteDisplayControl
	mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
	push	bp
	mov	di, mask MF_CALL
	call	ObjMessage			;dx = prohibited features
	pop	bp
	test	dx, mask GDCF_OVERLAPPING_MAXIMIZED
	jz	afterRedraw
	mov	bx, displayBlock
	mov	si, offset MPRedrawTrigger
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	DEMP_ObjMessageNoFlags
afterRedraw:

if _USE_SINGLE_WINDOW_FOR_DOC_AND_MASTER_PAGE

	;
	; Gross hack here for Nike: since we only want one window open
	; for the document, so set the document not usable
	;
	push	bp
	mov	si, document
	mov	ax, MSG_GEN_DOCUMENT_GET_DISPLAY
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	DEMP_ObjMessageFixupDS
	pop	bp
endif

	; set the display usable

	mov	bx, displayBlock
	mov	si, offset MasterPageDisplay
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_USABLE
	call	DEMP_ObjMessageNoFlags

if _USE_SINGLE_WINDOW_FOR_DOC_AND_MASTER_PAGE
endif

	mov	si, document
	mov	ax, bodyVMBlock
	mov	bx, displayBlock
	mov	cx, contentBlock
	call	AttachUIForMasterPage
done:
	call	VMUnlockES
	.leave
	ret

WriteDocumentOpenMasterPage	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindMasterToOpenCallback

DESCRIPTION:	Callback routine to find a master page

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	cx - master page VM block

RETURN:
	carry - set if found
	offset of element
	dx - offset of element
	ax - master page offset

DESTROYED:
	bx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/19/92		Initial version

------------------------------------------------------------------------------@
FindMasterToOpenCallback	proc	far
	mov	dx, di
	clr	ax
	mov	bx, ds:[di].SAE_numMasterPages
	add	di, offset SAE_masterPages
compareLoop:
	cmp	cx, ds:[di]
	stc
	jz	done
	add	di, size word
	add	ax, size word
	dec	bx
	jnz	compareLoop
	clc
done:
	ret

FindMasterToOpenCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetMPDisplayName

DESCRIPTION:	Set the name of a master page display

CALLED BY:	INTERNAL

PASS:
	*ds:si - write document
	ax - sectionNumber
	bx - master page offset (0 to 2)
	dx - display block
	es - map block (locked)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 3/92		Initial version

------------------------------------------------------------------------------@
SetMPDisplayName	proc	far	uses ax, bx, cx, dx, si, di, bp, ds, es
nameBuffer	local	(MAX_SECTION_NAME_SIZE + 100) dup (char)
	.enter
	call	SectionArrayEToP_ES
	mov	ax, es:[di].SAE_numMasterPages
	add	di, size SectionArrayElement	;esdi = name
	sub	cx, size SectionArrayElement	;cx = name length
	push	cx				;name length
	pushdw	esdi				;name ptr

	; set the title for the display

	push	ax, bx
	mov	bx, handle StringsUI
	call	ObjLockObjBlock
	mov	ds, ax
	pop	ax, bx

	mov	si, offset MasterPageString	;assume no left/right
	cmp	ax, 1				;numMasterPages
	jz	gotMPString
	mov	si, offset LeftMasterPageString
	tst	bx
	jz	gotMPString
	mov	si, offset RightMasterPageString
gotMPString:
	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx		;cx <- size of string
	LocalPrevChar dscx			;don't copy NULL
	segmov	es, ss
	lea	di, nameBuffer
	rep	movsb				;copy string

	popdw	dssi				;dssi = name ptr
	pop	cx				;cx = name length
	rep	movsb
	clr	ax
	LocalPutChar esdi, ax			;null terminate

	mov	bx, dx
	mov	si, offset MasterPageDisplay	;bxsi = display
	mov	cx, ss
	lea	dx, nameBuffer
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	push	bp
	mov	bp, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	mov	bx, handle StringsUI
	call	MemUnlock
	.leave
	ret

SetMPDisplayName	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentCloseMasterPage --
		MSG_WRITE_DOCUMENT_CLOSE_MASTER_PAGE for WriteDocumentClass

DESCRIPTION:	Close a master page

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx - master page body vm block

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentCloseMasterPage	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_CLOSE_MASTER_PAGE

	mov_tr	ax, cx
	call	FindOpenMasterPage
	jnc	notVisible

if _USE_SINGLE_WINDOW_FOR_DOC_AND_MASTER_PAGE
endif

	call	DetachUIForMasterPage
	call	DestroyUIForMasterPage
notVisible:

if _USE_SINGLE_WINDOW_FOR_DOC_AND_MASTER_PAGE
	;
	; Gross hack here for Nike: since we only want one window open
	; for the document, so set the document usable
	;
	mov	ax, MSG_GEN_DOCUMENT_GET_DISPLAY
	call	ObjCallInstanceNoLock
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	call	DEMP_ObjMessageFixupDS

endif

	ret

WriteDocumentCloseMasterPage	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DestroyUIForMasterPage

DESCRIPTION:	Delete the UI for a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - vm block

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 3/92		Initial version

------------------------------------------------------------------------------@
DestroyUIForMasterPage	proc	far	uses ax, bx, cx, dx, si, di
	.enter
EC <	call	AssertIsWriteDocument					>

	; if the master page is open then close it

	call	FindOpenMasterPage
	jnc	done

	mov	si, offset OpenMasterPageArray
	mov	di, dx
	call	ChunkArrayDelete

	; set the display not usable

	push	cx				;save content block
	mov	si, offset MasterPageDisplay
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	DEMP_ObjMessageNoFlags

	; remove the display from the display control

	push	bx
	movdw	cxdx, bxsi			;cx:dx = display
	GetResourceHandleNS	WriteDisplayGroup, bx
	mov	si, offset WriteDisplayGroup
	mov	ax, MSG_GEN_REMOVE_CHILD
	push	bp
	clr	bp
	call	DEMP_ObjMessageNoFlags
	pop	bp
	pop	bx

	mov	si, offset MPHorizontalRulerView
	mov	ax, MSG_META_BLOCK_FREE
	call	DEMP_ObjMessageNoFlags

	pop	bx				;bx = content block
	mov	si, offset MPHorizontalContent
	mov	ax, MSG_META_BLOCK_FREE
	call	DEMP_ObjMessageNoFlags

done:
	.leave
	ret

DestroyUIForMasterPage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DetachUIForMasterPage

DESCRIPTION:	Detach the UI for a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	ax - VM block of master page body
	bx - master page display block
	cx - master page content block

RETURN:
	none

DESTROYED:
	dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 2/92		Initial version

------------------------------------------------------------------------------@
DetachUIForMasterPage	proc	far	uses ax, bx, cx
	.enter
EC <	call	AssertIsWriteDocument					>

	call	WriteVMBlockToMemBlock			;ax = body block

	;    Detach the ruler contents from the ruler views

	push	ax, cx, si				;document chunk
	clrdw	cxdx
	mov	si, offset MPHorizontalRulerView
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call	DEMP_ObjMessageFixupDS

	mov	si, offset MPVerticalRulerView
	call	DEMP_ObjMessageFixupDS

	mov	si, offset MasterPageView
	call	DEMP_ObjMessageFixupDS
	pop	ax, cx, si				;document chunk

	;    Detach the rulers to the contents

	; Add the rulers as children of the content

	push	ax, bx, cx, si, bp
	mov_tr	bx, ax				;bx = body block
	mov	si, offset MPVerticalRuler
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_REMOVE
	call	DEMP_ObjMessageFixupDS

	mov	si, offset MPHorizontalRuler
	call	DEMP_ObjMessageFixupDS

 	mov	ax, MSG_VIS_REMOVE_NON_DISCARDABLE
	mov	si, offset MasterPageBody
	call	DEMP_ObjMessageFixupDS

	;    Notify the GrObjBody that it has been added to
	;    the Document/Content. And pass GrObjHead to it.
	;

	mov	ax,MSG_GB_DETACH_UI
	call	DEMP_ObjMessageFixupDS

	pop	ax, bx, cx, si, bp

	.leave
	ret

DetachUIForMasterPage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AttachUIForMasterPage

DESCRIPTION:	Attach the UI for a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	ax - VM block of master page body
	bx - master page display block
	cx - master page content block

RETURN:
	none

DESTROYED:
	dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 2/92		Initial version

------------------------------------------------------------------------------@
AttachUIForMasterPage	proc	far
	.enter
EC <	call	AssertIsWriteDocument					>

	push	ax
	call	WriteVMBlockToMemBlock			;ax = body block

	;    Attach the ruler contents to the ruler views

	push	ax, si					;document chunk
	mov	dx, offset MPHorizontalContent
	mov	si, offset MPHorizontalRulerView
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call	DEMP_ObjMessageFixupDS

	mov	dx, offset MPVerticalContent
	mov	si, offset MPVerticalRulerView
	call	DEMP_ObjMessageFixupDS

	mov	dx, offset MasterPageContent
	mov	si, offset MasterPageView
	call	DEMP_ObjMessageFixupDS
	pop	ax, si					;document chunk

	;    Attach the rulers to the contents

	push	ax, bx, cx, si, bp
	mov	bx, cx				;bx = content block
	mov_tr	cx, ax				;cx = body block
	mov	bp, CCO_FIRST
	mov	ax, MSG_VIS_ADD_CHILD
	mov	si, offset MPVerticalContent
	mov	dx, offset MPVerticalRuler
	call	DEMP_ObjMessageFixupDS

	mov	si, offset MPHorizontalContent 
	mov	dx, offset MPHorizontalRuler
	call	DEMP_ObjMessageFixupDS

	;    Add the graphic body as the first child of the
	;    Document/Content. Don't mark dirty because we don't
	;    want the document dirtied as soon as it is open, nor
	;    do we save the Document/Content or the parent pointer
	;    in the GrObjBody.
	;

	mov	ax, MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD
	mov	dx, offset MasterPageBody		;cxdx = body
	mov	si, offset MasterPageContent
	call	DEMP_ObjMessageFixupDS

	; tell the ruler which content to talk to GCN list

	xchgdw	bxsi, cxdx			;bxsi = body, cxdx = content
	mov	si, offset MPHorizontalRuler	;bxsi = ruler
	mov	ax, MSG_TEXT_RULER_SET_GCN_CONTENT
	call	DEMP_ObjMessageFixupDS
	pop	ax, bx, cx, si, bp

	;    Notify the GrObjBody that it has been added to
	;    the Document/Content. And pass GrObjHead to it.
	;

	push	bx, cx, si
	mov_tr	bx, ax
	mov	si, offset MasterPageBody
	GetResourceHandleNS	WriteHead, cx
	mov	dx, offset WriteHead
	mov	ax,MSG_GB_ATTACH_UI
	call	DEMP_ObjMessageFixupDS
	pop	bx, cx, si
	pop	ax

	; update the size of the view

	call	SendMPSizeToView

	.leave
	ret

AttachUIForMasterPage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendMPSizeToView

DESCRIPTION:	Send the master page size to the view

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	ax - VM block of master page body
	bx - master page display block
	cx - master page content block

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
SendMPSizeToView	proc	far	uses ax, bx, cx, dx, si
	.enter
EC <	call	AssertIsWriteDocument					>

	push	cx
	mov	cx, bx
	mov	dx, offset MasterPageView	;cxdx = display
	call	WriteVMBlockToMemBlock
	mov_tr	bx, ax
	mov	ax, offset MasterPageBody	;bxax = grobj body

	call	SetViewSize			;dxcx = width, bxax = height

	mov	dx, ax				;cx = width, dx = height
	pop	bx
	mov	si, offset MasterPageContent
	mov	ax, MSG_VIS_SET_SIZE
	call	DEMP_ObjMessageFixupDS

	.leave
	ret

SendMPSizeToView	endp

DocEditMP ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteMasterPage

DESCRIPTION:	Delete a master page block

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - vm block

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 3/92		Initial version

------------------------------------------------------------------------------@
DeleteMasterPage	proc	far	uses bx, cx, dx, bp, si, di
	.enter

EC <	call	AssertIsWriteDocument					>

	call	FindOpenMasterPage		;bx = display, cx = content
						;ax = master page VM block
	jnc	notVisible
	call	DetachUIForMasterPage
	call	DestroyUIForMasterPage
notVisible:

	call	WriteVMBlockToMemBlock
	mov_tr	bx, ax

	; detach the body from the GOAM

	mov	si, offset MasterPageBody
	mov	ax, MSG_GB_CLEAR
	call	DS_ObjMessageNoFlags

	; free the block containing the body

	call	ObjFreeObjBlock

	.leave
	ret

DeleteMasterPage	endp

DocSTUFF ends

DocPageSetup segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindOpenMasterPage

DESCRIPTION:	Find an open master page (if it exists)

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - VM block of master page

RETURN:
	carry - set if found
	bx - block containing display
	cx - block containing content
	dx - offset of element
	ds:si - OpenMasterPageArray entry

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 2/92		Initial version

------------------------------------------------------------------------------@
FindOpenMasterPage	proc	far	uses si
	class	WriteDocumentClass
EC <	call	AssertIsWriteDocument					>
	.enter

	mov	si, offset OpenMasterPageArray

	; search this ourself (simpler then ChunkArrayEnum)

	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	jcxz	notFound
	add	si, ds:[si].CAH_offset
searchLoop:
	cmp	ax, ds:[si].OMP_vmBlock
	jz	found
	add	si, size OpenMasterPage
	loop	searchLoop
notFound:
	clc
done:
	.leave
	ret

found:
	mov	bx, ds:[si].OMP_display
	mov	cx, ds:[si].OMP_content
	mov	dx, si
	stc
	jmp	done

FindOpenMasterPage	endp

DocPageSetup ends
