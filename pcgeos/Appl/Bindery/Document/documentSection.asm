COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentSection.asm

ROUTINES:
	Name				Description
	----				-----------
    INT InsertOrAppendSection	insert or append a section

    INT DeleteSection		Delete a section

    INT ModifyArticleRegionsSectionCallback 
				Modify the section number stored with each
				region and insert or delete text as
				appropriate for the section operation

    INT DeleteArticleRegionAccessories 
				Delete the accessory objects for an article
				region

    INT FindSectionPosition	Find the y position of a section

    INT FSPCallback		Callback to find the y position of a
				section

    INT FindPageAndSection	Find the page and section for a given
				position.	 Note that this is NOT an
				absolute position on a page, but rather a
				window position (which is very different
				when not in page mode).

    INT LockArticleBeingEdited	Lock the article being edited (normally
				called when in a mode other than page mode)

    INT FindPageAndSectionAbs	Find the page and section for an absolute
				given position

    INT FPASCallback		Callback to find the y position of a
				section

    INT MapPageToSectionPage	Find the section for an absolute page

    INT MapPageCallback		Callback to find the section for a page

    INT InitNewSection		Initialize a new section

METHODS:
	Name			Description
	----			-----------
    StudioDocumentInsertPage	Insert a graphic region

				MSG_STUDIO_DOCUMENT_INSERT_PAGE,
				MSG_STUDIO_DOCUMENT_APPEND_PAGE
				StudioDocumentClass

    StudioDocumentDeletePage	Delete a all the graphic regions
				associated with a page

				MSG_STUDIO_DOCUMENT_DELETE_PAGE
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for StudioDocumentClass

	$Id: documentSection.asm,v 1.1 97/04/04 14:39:08 newdeal Exp $

------------------------------------------------------------------------------@

idata segment

suspendNotification	word

idata ends

;---

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentInsertPage -- MSG_STUDIO_DOCUMENT_INSERT_PAGE
						for StudioDocumentClass

DESCRIPTION:	Insert a graphic region

PASS:		*ds:si - instance data
		es - segment of StudioDocumentClass
		ax - The message
		bp - page number
RETURN:

DESTROYED: 	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentInsertPage	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_INSERT_PAGE,
					MSG_STUDIO_DOCUMENT_APPEND_PAGE

	call	IgnoreUndoAndFlush
	mov_tr	dx, ax

	call	LockMapBlockES
	mov	ax, ds:[di].SDI_currentPage	;reference page
	call	MapPageToSectionPage		;ax = section
						;bx = page in section

	call	VMUnlockES
	mov_tr	cx, ax				;cx = section #
	mov	bp, bx				;bp = page # in section

	clr	cx				;cx = 1st section
	mov	ax, MSG_STUDIO_DOCUMENT_INSERT_APPEND_PAGES_LOW
	call	ObjCallInstanceNoLock

	call	AcceptUndo
	ret

StudioDocumentInsertPage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentDeletePage -- MSG_STUDIO_DOCUMENT_DELETE_PAGE
						for StudioDocumentClass

DESCRIPTION:	Delete all the regions for a page

PASS:	*ds:si - instance data
	es - segment of StudioDocumentClass
	ax - The message
	bp - region number to delete

RETURN: nada

DESTROYED: bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentDeletePage	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_DELETE_PAGE

	call	IgnoreUndoAndFlush

	; redraw the document

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	call	LockMapBlockES
	call	SuspendDocument
		
	mov	ax, ds:[di].SDI_currentPage
	call	MapPageToSectionPage		;ax = section
						;bx = page in section

	; if there are multiple master pages and conditions are right then
	; delete a set of master pages

	call	SectionArrayEToP_ES		;es:di = SectionArrayElement
	xchg	ax, bx				;ax = page in section
						;bx = section #
	mov	cx, 1				;if we are at the last page of
	cmp	ax, es:[di].SAE_numPages	;the section then only
	jz	gotNumPagesToDelete		;delete one page
	clr	dx				;dxax = page #
	mov	cx, es:[di].SAE_numMasterPages
	div	cx				;ax = set #, ah = remainder
	mul	cx				;ax = offset to delete at
	mov	dx, es:[di].SAE_numPages
	sub	dx, ax				;dx = max pages to delete
	cmp	cx, dx
	jbe	gotNumPagesToDelete
	mov	cx, dx
gotNumPagesToDelete:
	xchg	ax, bx				;ax = section number
						;bx = page in section
		
deleteLoop:
	push	cx
	mov	cx, 1
	mov	dx, 1				;direct user action
	call	AddDeletePageToSection
	pop	cx
	loop	deleteLoop

	call	UnsuspendDocument
	call	VMDirtyES
	call	VMUnlockES

	call	AcceptUndo
	ret

StudioDocumentDeletePage	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	InsertOrAppendSection

DESCRIPTION:	insert or append a section

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data
	ax - section to insert before / append after
	cx:dx - text object to get section name from (or cx=0 and dx = chunk
		(in StringsUI) of name)
	di - zero to insert / non-zero to append

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
InsertOrAppendSection	proc	far
	mov	bx, ds:[LMBH_handle]

document	local	optr	\
		push	bx, si
sectionNum	local	word	\
		push	ax
appendFlag	local	word	\
		push	di
sectionName	local	NAME_ARRAY_MAX_NAME_SIZE dup (char)
nameLength	local	word
	.enter

	call	IgnoreUndoAndFlush

EC <	call	AssertIsStudioDocument					>

	; get the name and its length

	push	si, bp
	movdw	bxsi, cxdx
	jcxz	nameInChunk

	mov	dx, ss
	lea	bp, sectionName
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage			;cx = length
	jmp	common

nameInChunk:
	push	ds
	mov	bx, handle StringsUI
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			;ds:si = name
	ChunkSizePtr	ds, si, cx		;cx = length
	dec	cx				;don't count null-terminator
	segmov	es, ss
	lea	di, sectionName
	push	cx
	rep	movsb
	pop	cx
	call	MemUnlock
	pop	ds
common:

	pop	si, bp
	tst	cx
	stc
	LONG jz	doneNoUnlock
	mov	nameLength, cx

	; lock the section array

	call	LockMapBlockDS
	mov	si, offset SectionArray		;*ds:si = array

	; see if this section name already exists (its an error if so)

	segmov	es, ss
	lea	di, sectionName
	clr	dx				;no return buffer
	call	NameArrayFind
	cmp	ax, CA_NULL_ELEMENT
	jz	noError
	stc
	segmov	es, ds
	jmp	doneUnlock
noError:

	; calculate the element size

	mov	ax, sectionNum
	call	ChunkArrayElementToPtr		;ds:di = reference element
	mov_tr	cx, ax
	mov	ax, nameLength
	add	ax, size SectionArrayElement

	; create a new section element in the array

	tst	appendFlag
	jnz	append
	call	ChunkArrayInsertAt
	inc	sectionNum
	jmp	afterInsertAppend
append:
	mov	bx, ds:[si]			;if last one then append
	inc	cx
	cmp	cx, ds:[bx].CAH_count
	jz	reallyAppend
	push	ax				;else move up one and insert
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr
	pop	ax
	call	ChunkArrayInsertAt
	jmp	afterInsertAppend
reallyAppend:
	call	ChunkArrayAppend
afterInsertAppend:

	; suspend the articles

	push	si, di
	segmov	es, ds
	call	loadDocumentObj
	call	SuspendDocument
	segmov	ds, es
	pop	si, di

	; copy the section data from the old element to the new

	call	ChunkArrayPtrToElement
	push	ax				;save new section number
	segmov	es, ds
	push	di
	mov	ax, sectionNum
	call	ChunkArrayElementToPtr
	mov	si, di				;ds:si = source element
	pop	di				;es:di = destination element
	mov	cx, size SectionArrayElement
	rep	movsb

	; copy in the name

	push	ds
	segmov	ds, ss
	lea	si, sectionName
	mov	cx, nameLength
	rep	movsb
	pop	ds
	pop	ax				;ax = new section number

	push	ax
	segmov	es, ds				;es = map block
	mov	si, offset SectionArray
	call	ChunkArrayElementToPtr
	clr	ax
	mov	ds:[di].SAE_numPages, ax
	add	di, offset SAE_masterPages
	mov	cx, MAX_MASTER_PAGES
	rep	stosw
	pop	ax

	; update the section number stored in article regions and insert
	; a C_SECTION_BREAK character where appropriate

	push	ax, si, bp
	call	loadDocumentObj
	call	GetFileHandle
	mov	cx, bx				;cx = file
	mov_tr	dx, ax				;dx = region
	mov	bp, 1				;bp = ammount
	segmov	ds, es				;ds = map block
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset ModifyArticleRegionsSectionCallback
	call	ChunkArrayEnum
	pop	ax, si, bp

	; initialize the new section

	call	loadDocumentObj
	call	InitNewSection

	; unsuspend the articles

	call	UnsuspendDocument
	clc					;no error

doneUnlock:
	pushf
	call	VMDirtyES
	call	VMUnlockES
	call	loadDocumentObj
	popf
doneNoUnlock:

	jc	exit
	mov	ax, mask NF_SECTION
	call	SendNotification
	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp
	clc
exit:
	call	AcceptUndo
	.leave
	ret

;---

loadDocumentObj:
	movdw	bxsi, document
	call	MemDerefDS
	retn

InsertOrAppendSection	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteSection

DESCRIPTION:	Delete a section

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data
	ax - section to delete

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/14/92		Initial version

------------------------------------------------------------------------------@
DeleteSection	proc	far
	mov	bx, ds:[LMBH_handle]

document	local	optr	\
		push	bx, si
	.enter

	call	IgnoreUndoAndFlush

EC <	call	AssertIsStudioDocument					>

	; lock the section array

	call	LockMapBlockDS
	mov	si, offset SectionArray		;*ds:si = array

	; make sure that there is more than one section

	mov	di, ds:[si]
	cmp	ds:[di].CAH_count, 1
	stc
	LONG jz	doneUnlock

	; suspend the articles

	segmov	es, ds				;es = map block
	call	loadDocumentObj			;*ds:si = document
	call	SuspendDocument

	; if we are deleting the first section then make sure that the
	; "follows last section" flag in the second section is not set

	tst	ax
	jnz	notDeletingFirstSection
	inc	ax
	call	SectionArrayEToP_ES
	andnf	es:[di].SAE_flags, not mask SF_PAGE_NUMBER_FOLLOWS_LAST_SECTION
	clr	ax
notDeletingFirstSection:

	; delete the master pages for the section

	push	ax
	call	SectionArrayEToP_ES		;es:di = section
	clr	bx
	mov	cx, es:[di].SAE_numMasterPages
destroyLoop:
	mov	ax, es:[di][bx].SAE_masterPages
	call	DeleteMasterPage
	add	bx, size word
	loop	destroyLoop
	pop	ax

	; update the section number stored in article regions and delete
	; text in the section to be nuked

	pushdw	esdi
	call	loadDocumentObj
	push	ax, bp
	call	GetFileHandle
	mov	cx, bx				;cx = file
	mov_tr	dx, ax				;dx = region
	mov	bp, -1				;bp = ammount
	segmov	ds, es				;ds = map block
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset ModifyArticleRegionsSectionCallback
	call	ChunkArrayEnum
	pop	ax, bp
	popdw	esdi

	; delete the pages that are in the section

	call	loadDocumentObj
	mov	cx, es:[di].SAE_numPages
	clr	bx
destroyPageLoop:
	push	cx
	mov	cx, 1				;delete flag
	mov	dx, 1				;direct user action
	call	AddDeletePageToSection
	pop	cx
	loop	destroyPageLoop

	; delete the section array element

	segmov	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayElementToPtr
	call	ChunkArrayDelete

	; unsuspend the articles

	call	loadDocumentObj
	call	UnsuspendDocument

	clc					;no error

	segmov	ds, es

doneUnlock:
	call	VMDirtyDS
	call	VMUnlockDS

	jc	exit

	call	loadDocumentObj
	call	LockMapBlockES
	mov	ax, mask NF_SECTION
	call	SendNotification
	call	VMUnlockES
	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp
	clc
exit:
	call	AcceptUndo
	.leave
	ret

;---

loadDocumentObj:
	movdw	bxsi, document
	call	MemDerefDS
	retn

DeleteSection	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ModifyArticleRegionsSectionCallback

DESCRIPTION:	Modify the section number stored with each region and insert
		or delete text as appropriate for the section operation

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	cx - vm file
	dx - section # to modify after
	bp - amount to modify by

RETURN:
	carry - set to end (always returned clear)

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
ModifyArticleRegionsSectionCallback	proc	far
	clr	ax
	mov	bx, C_SECTION_BREAK
foundFirstFlag	local	word	\
		push	ax
charPosition	local	dword	\
		push	ax, ax
insertBuf	local	2 dup (char) \
		push	bx
replaceParams	local	VisTextReplaceParameters
	.enter

	push	ds:[LMBH_handle]

	mov	bx, cx
	mov	ax, ds:[di].AAE_articleBlock
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjLockObjBlock
	mov	ds, ax				;ds = article block

	mov	si, offset ArticleRegionArray
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	tst	cx
	LONG jz done
	add	di, ds:[di].CAH_offset

	; We scan each region associated with the text object and do two
	; things:
	;
	; * for each region in a section after the section passed, we modify
	;   the section number stored with the region
	;
	; * if we are inserting a section:
	;   * insert a C_SECTION_BREAK character at the beginning of the
	;     first region in the section passed (or at the end of the last
	;     region if there are no regions in the section passed)
	;
	; * if we are deleting a section:
	;   * delete all text in the given section
	;   * delete the region

modifyLoop:
	cmp	dx, ds:[di].VLTRAE_section
	ja	addCharCount
	jnz	adjust

	; we've found the first region in the section

	cmp	{word} ss:[bp], 1
	jnz	deletingSection

	; *** insert/append section

	tst	foundFirstFlag
	jnz	adjust
	call	insertSectionBreak
	inc	foundFirstFlag
adjust:
	mov	ax, ss:[bp]
	add	ds:[di].VLTRAE_section, ax
addCharCount:
	adddw	charPosition, ds:[di].VLTRAE_charCount, ax
	add	di, size ArticleRegionArrayElement
	jmp	next

	; *** delete section

deletingSection:
	call	ChunkArrayPtrToElement		;ax = region #
	push	bx, cx, dx, bp
	push	ax, si

	clr	cx
	mov	si, ds:[si]
	inc	ax
	cmp	ax, ds:[si].CAH_count		;is last region ?
	jnz	notLastSection
	inc	cx
notLastSection:

	; delete the text in the region (since the region is about to be
	; nuked)

	movdw	dxax, charPosition
	movdw	replaceParams.VTRP_range.VTR_start, dxax
	adddw	dxax, ds:[di].VLTRAE_charCount
	movdw	replaceParams.VTRP_range.VTR_end, dxax

	; if this is the last section then we want to delete the last
	; character of the previous section (the section break)

	sub	replaceParams.VTRP_range.VTR_start.low, cx
	sbb	replaceParams.VTRP_range.VTR_start.high, 0
	sub	charPosition.low, cx
	sbb	charPosition.high, 0

	clr	ax
	clrdw	replaceParams.VTRP_insCount, ax
	mov	replaceParams.VTRP_flags, ax
	mov	si, offset ArticleText
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	lea	bp, replaceParams
	call	ObjCallInstanceNoLock

	pop	ax, si
	call	ChunkArrayElementToPtr

	; now we must move the lines that exist in this region to the
	; previous or next region

EC <	tstdw	ds:[di].VLTRAE_charCount				>
EC <	ERROR_NZ REGION_SHOULD_HAVE_NO_CHARACTERS_AT_THIS_POINT		>

	push	di
	mov	dx, -1
	tst	ax				;if this is the first region
	jnz	gotDirection			;use move backwards
	mov	dx, 1

	; dx holds the direction to move (-1 for backwards, 1 for forwards)
	; we need to keep moving until we find a non-empty region that we
	; can move the lines and the height to

gotDirection:
	add	ax, dx
EC <	ERROR_S	NO_PREVIOUS_NON_EMPTY_REGIONS				>
EC <	mov	di, ds:[si]						>
EC <	cmp	ax, ds:[di].CAH_count					>
EC <	ERROR_AE NO_SUBSEQUENT_EMPTY_REGIONS				>
	call	ChunkArrayElementToPtr
	test	ds:[di].VLTRAE_flags, mask VLTRF_EMPTY
	jnz	gotDirection

	mov	bx, di				;ds:bx = dest
	pop	di
	adddw	ds:[bx].VLTRAE_lineCount, ds:[di].VLTRAE_lineCount, ax
	addwbf	ds:[bx].VLTRAE_calcHeight, ds:[di].VLTRAE_calcHeight, ax

	call	DeleteArticleRegionAccessories
	call	ChunkArrayDelete
	pop	bx, cx, dx, bp

	; *** common

next:
	dec	cx
	LONG jnz modifyLoop

	; check for appending a section at the end in which case we need to
	; add the C_SECTION_BREAK character now

	tst	foundFirstFlag
	jnz	done
	cmp	{word} ss:[bp], 1
	jnz	done
	call	insertSectionBreak

done:
	call	MemUnlock

	pop	bx
	call	MemDerefDS

	clc
	.leave
	ret

;---

	; Insert a C_SECTION_BREAK character at charPosition

insertSectionBreak:
	call	ChunkArrayPtrToElement
	push	ax, cx, dx, si, bp

	movdw	dxax, charPosition
	movdw	replaceParams.VTRP_range.VTR_start, dxax
	movdw	replaceParams.VTRP_range.VTR_end, dxax
	movdw	replaceParams.VTRP_insCount, 1
	mov	replaceParams.VTRP_textReference.TR_type, TRT_POINTER
	mov	replaceParams.VTRP_flags, 0
	lea	ax, insertBuf
	movdw	replaceParams.VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, ssax
	mov	si, offset ArticleText
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	lea	bp, replaceParams
	call	ObjCallInstanceNoLock

	pop	ax, cx, dx, si, bp
	call	ChunkArrayElementToPtr
	retn

ModifyArticleRegionsSectionCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteArticleRegionAccessories

DESCRIPTION:	Delete the accessory objects for an article region

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleRegionArrayElement

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
	Tony	9/14/92		Initial version

------------------------------------------------------------------------------@
DeleteArticleRegionAccessories	proc	far	uses ax, di
	.enter

	mov	ax, offset VLTRAE_region
	call	DBFreeRefDS
	mov	ax, offset ARAE_drawRegion
	call	DBFreeRefDS
	.leave
	ret

DeleteArticleRegionAccessories	endp

DocSTUFF ends


DocNotify segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindSectionPosition

DESCRIPTION:	Find the y position of a section

CALLED BY:	INTERNAL

PASS:
	es - locked map block
	ax - section

RETURN:
	dx.ax - section y position

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
FindSectionPosition	proc	far	uses bx, cx, si, di, bp, ds
	.enter

	mov_tr	cx, ax				;cx = count
	clrdw	dxbp				;dxbp = result
	jcxz	done
	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset FSPCallback
	call	ChunkArrayEnum
done:
	mov_tr	ax, bp				;dxax = result
	.leave
	ret

FindSectionPosition	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FSPCallback

DESCRIPTION:	Callback to find the y position of a section

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	dxbp - section y position

RETURN:
	dxbp - updated
	carry - set to end (when cx reaches 0)

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
FSPCallback	proc	far
	movdw	bxsi, dxbp			;bxsi = current
	mov	ax, ds:[di].SAE_numPages
	mul	ds:MBH_pageSize.XYS_height
	adddw	bxsi, dxax
	movdw	dxbp, bxsi
	clc
	loop	done
	stc
done:
	ret

FSPCallback	endp

DocNotify ends

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindPageAndSection

DESCRIPTION:	Find the page and section for a given position.  Note that
		this is NOT an absolute position on a page, but rather a
		window position (which is very different when not in page
		mode).

CALLED BY:	INTERNAL

PASS:
	es - locked map block
	cx - x position
	dx.bp - y position

RETURN:
	carry - set if error (cannot be mapped)
	cx - section #
	dx - (absolute) page #

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
FindPageAndSection	proc	far	uses bp
	.enter

	cmp	es:MBH_displayMode, VLTDM_PAGE
	jz	pageMode

	; if we are not in page mode then we must convert to an absolute
	; position

	push	ax, bx, cx, si, di, ds

	mov_tr	ax, bp					;dxax = y pos

	sub	sp, size PointDWFixed
	mov	bp, sp

	movdw	ss:[bp].PDF_y.DWF_int, dxax
	clr	ax
	mov	ss:[bp].PDF_y.DWF_frac, ax
	movdw	ss:[bp].PDF_x.DWF_int, axcx
	mov	ss:[bp].PDF_x.DWF_frac, ax

	; first call the text object to find the region under the point

	call	LockArticleBeingEdited

	push	bp
	mov	ax, MSG_VIS_LARGE_TEXT_REGION_FROM_POINT
	call	ObjCallInstanceNoLock		;cx = region
	pop	bp

	cmp	cx, CA_NULL_ELEMENT
	jz	error

	; get the real position of the region

	mov	si, offset ArticleRegionArray
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr	;ds:di = ArticleRegionArrayElement
	movdw	dxbp, ds:[di].VLTRAE_spatialPosition.PD_y	;dxbp = y pos
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	add	sp, size PointDWFixed
	pop	ax, bx, cx, si, di, ds

pageMode:
	call	FindPageAndSectionAbs
	clc
done:
	.leave
	ret

error:
	add	sp, size PointDWFixed
	pop	ax, bx, cx, si, di, ds
	stc
	jmp	done

FindPageAndSection	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LockArticleBeingEdited

DESCRIPTION:	Lock the article being edited (normally called when in a
		mode other than page mode)

CALLED BY:	INTERNAL

PASS:
	es - map block

RETURN:
	*ds:si - article

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/11/92		Initial version

------------------------------------------------------------------------------@
LockArticleBeingEdited	proc	far	uses ax, bx, cx, di
	.enter

	segmov	ds, es
	mov	si, offset ArticleArray
	clr	ax
	call	ChunkArrayElementToPtr		;ds:di = ArticleArrayElement

	mov	bx, ds:[di].AAE_articleBlock
	call	VMBlockToMemBlockRefDS
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, offset ArticleText		;*ds:si = text object

	.leave
	ret

LockArticleBeingEdited	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindPageAndSectionAbs

DESCRIPTION:	Find the page and section for an absolute given position

CALLED BY:	INTERNAL

PASS:
	es - locked map block
	cx - x position
	dx.bp - y position

RETURN:
	cx - section #
	dx - (absolute) page #

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
FindPageAndSectionAbs	proc	far	uses ax, bx, si, di, bp, ds
	.enter

	clr	cx
	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset FPASCallback
	call	ChunkArrayEnum
	mov	dx, cx					;dx = page
	mov_tr	di, ax
	call	ChunkArrayPtrToElement			;ax = section
	mov_tr	cx, ax					;cx = section

	.leave
	ret

FindPageAndSectionAbs	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FPASCallback

DESCRIPTION:	Callback to find the y position of a section

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	cx - running page total
	dx.bp - y position

RETURN:
	dx.bp - space for this section subtracted out
	cx - updated
	ds:ax - section element
	carry - set to end

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
FPASCallback	proc	far
	movdw	bxsi, dxbp		;bxsi = y position
	tst	bx
	js	gotit

	mov	ax, ds:[di].SAE_numPages
	mul	ds:MBH_pageSize.XYS_height
	subdw	bxsi, dxax
	jge	next

	; its in this section -- compute the page number

	adddw	bxsi, dxax
	movdw	dxax, bxsi
	div	ds:MBH_pageSize.XYS_height		;ax = #
	add	cx, ax
gotit:
	mov_tr	ax, di
	stc
	ret

next:
	movdw	dxbp, bxsi
	add	cx, ds:[di].SAE_numPages
	mov_tr	ax, di
	clc
	ret

FPASCallback	endp

DocCommon ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	MapPageToSectionPage

DESCRIPTION:	Find the section for an absolute page

CALLED BY:	INTERNAL

PASS:
	es - locked map block
	ax - absolute page #

RETURN:
	ax - section #
	bx - page number in the section

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
MapPageToSectionPage	proc	far	uses cx, dx, si, di, ds
	.enter

	mov_tr	cx, ax				;cx = page
	clr	dx				;dx = section
	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset MapPageCallback
	call	ChunkArrayEnum
	mov_tr	ax, dx
	mov	bx, cx

	.leave
	ret

MapPageToSectionPage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MapPageCallback

DESCRIPTION:	Callback to find the section for a page

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	cx - pages left
	dx - section #

RETURN:
	cx, dx - updated
	carry - set to end

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
MapPageCallback	proc	far
	cmp	cx, ds:[di].SAE_numPages
	jae	notThisSection

	; its in this section

	stc
	ret

notThisSection:
	sub	cx, ds:[di].SAE_numPages
	inc	dx
	clc
	ret

MapPageCallback	endp

DocNotify ends

DocCreate segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	InitNewSection

DESCRIPTION:	Initialize a new section

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - map block (locked)
	ax - section number to initialize

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
	Tony	3/ 9/92		Initial version

------------------------------------------------------------------------------@
InitNewSection	proc	far
EC <	call	AssertIsStudioDocument					>

	; Duplicate each master page needed and recalculate the flow regions
	; for it

	call	SectionArrayEToP_ES

	push	ax
	clr	bx
	mov	cx, es:[di].SAE_numMasterPages
createLoop:
	call	DuplicateMasterPage
	mov	es:[di][bx].SAE_masterPages, ax
	call	RecalcMPFlowRegions
	add	bx, size word
	loop	createLoop
	pop	ax

	clr	bx
	clr	cx
	clr	dx				;not direct user action
	call	AddDeletePageToSection

	ret

InitNewSection	endp

DocCreate ends
