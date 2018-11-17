COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentMisc.asm

ROUTINES:
	Name			Description
	----			-----------
    INT GotoPageCommon		Go to the next page

METHODS:
	Name			Description
	----			-----------
    StudioDocumentRecreateCachedGStates  
				Recreate all cached gstates for the
				document

				MSG_VIS_RECREATE_CACHED_GSTATES
				StudioDocumentClass

    StudioDocumentSetStartingSection  
				Set the starting section number

				MSG_STUDIO_DOCUMENT_SET_STARTING_SECTION
				StudioDocumentClass

    StudioDocumentSetDisplayMode Set the display mode for the document

				MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE
				StudioDocumentClass

    StudioDocumentSetDisplayModeLow  
				Set the display mode for the document
				without changing any of the UI

				MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE_LOW
				StudioDocumentClass

    StudioDocumentNextPage	Go to the next page

				MSG_META_PAGED_OBJECT_NEXT_PAGE
				StudioDocumentClass

    StudioDocumentPreviousPage	Go to the previous page

				MSG_META_PAGED_OBJECT_PREVIOUS_PAGE
				StudioDocumentClass

    StudioDocumentGotoPage	Go to a page

				MSG_META_PAGED_OBJECT_GOTO_PAGE
				StudioDocumentClass

    StudioDocumentLoadStyleSheet Load a style sheet

				MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET
				StudioDocumentClass

    RedwoodPrintNotifyPrintDB	MSG_PRINT_NOTIFY_PRINT_DB
				StudioDocumentClass

    StudioDocumentSetMiscFlags	MSG_STUDIO_DOCUMENT_SET_MISC_FLAGS
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for StudioDocumentClass

	$Id: documentMisc.asm,v 1.1 97/04/04 14:38:57 newdeal Exp $

------------------------------------------------------------------------------@

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentRecreateCachedGStates --
		MSG_VIS_RECREATE_CACHED_GSTATES for StudioDocumentClass

DESCRIPTION:	Recreate all cached gstates for the document

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
	Tony	12/21/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentRecreateCachedGStates	method dynamic	StudioDocumentClass,
						MSG_VIS_RECREATE_CACHED_GSTATES

	push	si
	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
	mov	bx, segment VisClass
	mov	si, offset VisClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	si

	mov	ax, MSG_VIS_SEND_TO_CHILDREN
	call	ObjCallInstanceNoLock

	; send to all open master pages

	push	si
	mov	di, ds:[OpenMasterPageArray]
	mov	cx, ds:[di].CAH_count
	jcxz	noMasterPages
	add	di, ds:[di].CAH_offset
mpLoop:
	push	cx, di
	push	ds:[di].OMP_content
	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
	mov	bx, segment GrObjBodyClass
	mov	si, offset GrObjBodyClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	dx, TO_TARGET
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	pop	bx
	mov	si, offset MasterPageContent
	clr	di
	call	ObjMessage
	pop	cx, di
	add	di, size OpenMasterPage
	loop	mpLoop
noMasterPages:
	pop	si					;document chunk

	ret

StudioDocumentRecreateCachedGStates	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSetStartingSection --
		MSG_STUDIO_DOCUMENT_SET_STARTING_SECTION for StudioDocumentClass

DESCRIPTION:	Set the starting section number

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - starting section number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 2/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSetStartingSection	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_SET_STARTING_SECTION

	call	IgnoreUndoAndFlush

	; store the new value

	call	LockMapBlockES
	mov	es:MBH_startingSectionNum, cx

	; send notifications

	mov	ax, mask NotifyFlags
	call	SendNotification

	call	VMDirtyES
	call	VMUnlockES

	; redraw the document

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	call	AcceptUndo

	ret

StudioDocumentSetStartingSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSetDisplayMode --
		MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE for StudioDocumentClass

DESCRIPTION:	Set the display mode for the document

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - VisTextDisplayModes

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/28/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSetDisplayMode	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE

	call	MarkBusy
	call	IgnoreUndoAndFlush

	push	cx
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	cx

	mov	ax, MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE_LOW
	call	ObjCallInstanceNoLock

	; store the font and point size as well

	call	LockMapBlockES

	push	dx
	call	UserGetDefaultMonikerFont	;cx = font, dx = size
	mov	es:[MBH_draftFont], cx
	mov	es:[MBH_draftPointSize], dx
	call	VMDirtyES
	pop	dx

	call	SetViewForDisplayMode

	call	SendDocumentSizeToView

	mov	ax, mask NF_DOCUMENT
	call	SendNotification

	call	VMUnlockES

	; make sure the the Studio tool is selected

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].SDI_state, mask SDS_TARGET
	jz	afterTarget
	call	SetStudioToolIfNotPageMode
afterTarget:

	call	AcceptUndo
	call	MarkNotBusy

	ret

StudioDocumentSetDisplayMode	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentSetDisplayModeLow --
		MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE_LOW for StudioDocumentClass

DESCRIPTION:	Set the display mode for the document without changing any
		of the UI

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - VisTextDisplayModes

RETURN:
	dx - old mode

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/28/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentSetDisplayModeLow	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_SET_DISPLAY_MODE_LOW

	; store the new mode

	call	LockMapBlockES
	mov	dx, cx
	xchg	dx, es:MBH_displayMode
	call	VMDirtyES

	; tell the article to enter the new display mode

	mov	ax, MSG_VIS_LARGE_TEXT_SET_DISPLAY_MODE
	mov	di, mask MF_RECORD
	call	ObjMessage
	call	SendToFirstArticle

	call	VMUnlockES

	ret

StudioDocumentSetDisplayModeLow	endm

DocSTUFF ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentNextPage -- MSG_META_PAGED_OBJECT_NEXT_PAGE
						for StudioDocumentClass

DESCRIPTION:	Go to the next page

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
	Tony	4/ 2/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentNextPage	method dynamic	StudioDocumentClass,
					MSG_META_PAGED_OBJECT_NEXT_PAGE

	mov	cx, ds:[di].SDI_currentPage
	inc	cx
	GOTO	GotoPageCommon

StudioDocumentNextPage	endm

;---

StudioDocumentPreviousPage	method dynamic	StudioDocumentClass,
					MSG_META_PAGED_OBJECT_PREVIOUS_PAGE

	mov	cx, ds:[di].SDI_currentPage
	jcxz	done
	dec	cx
	GOTO	GotoPageCommon
done:
	ret

StudioDocumentPreviousPage	endm

;---

StudioDocumentGotoPage	method dynamic	StudioDocumentClass,
					MSG_META_PAGED_OBJECT_GOTO_PAGE

	call	LockMapBlockES
	clr	ax
	push	cx
	call	SectionArrayEToP_ES		;es:di = section
	pop	cx
	sub	cx, es:[di].SAE_startingPageNum
	call	VMUnlockES

	FALL_THRU	GotoPageCommon

StudioDocumentGotoPage	endm

;---

GotoPageCommon	proc	far
	class	StudioDocumentClass

	call	LockMapBlockES

	cmp	cx, es:MBH_totalPages
	jb	20$
	mov	cx, es:MBH_totalPages
	dec	cx
20$:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	cx, ds:[di].SDI_currentPage
	LONG jz	done

	mov	ax, cx
	call	MapPageToSectionPage		;ax = section, bx = page

	; calculate notification flags

	mov	bp, mask NF_PAGE
	cmp	ax, ds:[di].SDI_currentSection
	jz	30$
	ornf	bp, mask NF_SECTION
30$:
	mov	ds:[di].SDI_currentSection, ax
	mov	ds:[di].SDI_currentPage, cx

	push	bp, si, ds

	; calculate position to scroll to and scroll

	call	SectionArrayEToP_ES		; es:di = SectionArrayElement
	call	FindSectionPosition		;dxax = section Y
	movdw	cxbp, dxax

	mov_tr	ax, bx
	mul	es:MBH_pageSize.XYS_height
	adddw	dxax, cxbp			;dxax = y position to scroll to
	mov_tr	cx, ax				;dxcx = y position

	; we now have a Y position (dxcx), but if we are not in page mode
	; then we need to do some mapping

	cmp	es:MBH_displayMode, VLTDM_PAGE
	jz	gotYPosition

	; lock the region array for the text object being edited

	push	si, ds
	call	LockArticleBeingEdited

	mov	si, ds:[ArticleRegionArray]
	mov	bx, ds:[si].CAH_count
	add	si, ds:[si].CAH_offset
	clr	ax
scanLoop:
	cmpdw	dxcx, ds:[si].VLTRAE_spatialPosition.PD_y
	jbe	foundRegion
	inc	ax
	add	si, size ArticleRegionArrayElement
	dec	bx
	jnz	scanLoop
	dec	ax
	sub	si, size ArticleRegionArrayElement	; none found -- back up
foundRegion:
	mov_tr	cx, ax
	mov	si, offset ArticleText
	mov	ax, MSG_VIS_LARGE_TEXT_GET_REGION_POS
	call	ObjCallInstanceNoLock		;dxax = y pos, cx = height
	mov_tr	cx, ax				;dxcx = ypos

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
	pop	si, ds

gotYPosition:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	mov	si, offset MainView
	mov	ax, MSG_GEN_VIEW_SCROLL_SET_Y_ORIGIN
	call	DN_ObjMessageNoFlags

	; send notification(s)

	pop	ax, si, ds
	call	SendNotification

done:
	call	VMUnlockES
	ret

GotoPageCommon	endp

DocNotify ends

DocMiscFeatures segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentLoadStyleSheet --
		MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET for StudioDocumentClass

DESCRIPTION:	Load a style sheet

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	bp - SSCLoadStyleSheetParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/25/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentLoadStyleSheet	method dynamic	StudioDocumentClass,
				MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET

	call	IgnoreUndoAndFlush

	call	StyleSheetOpenFileForImport
	LONG jc	done

	; bx = file handle

	; We need to get a StyleSheetParams structure from the file.

	call	VMGetMapBlock
	call	VMLock
	push	bx, bp
	mov	es, ax			;es = map block

	sub	sp, size StyleSheetParams
	mov	bp, sp

	; first do the graphics styles

	push	bx, si
	call	initParams

	mov	ax, es:MBH_graphicStyles
	mov	ss:[bp].SSP_xferStyleArray.SCD_vmBlockOrMemHandle, ax

	mov	ax, es:MBH_areaAttrElements
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_vmBlockOrMemHandle, ax

	mov	ax, es:MBH_lineAttrElements
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, ax

	push	es
	call	LockMapBlockES
	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock			;ax = handle
	call	VMUnlockES
	pop	es
	mov_tr	bx, ax
	mov	si, offset AttributeManager		;bxsi = attr manager
	mov	ax, MSG_GOAM_LOAD_STYLE_SHEET
	mov	dx, size StyleSheetParams
	mov	di, mask MF_STACK
	call	ObjMessage
	pop	bx, si

	; now do the text styles

	call	initParams

	mov	ax, es:MBH_textStyles
	mov	ss:[bp].SSP_xferStyleArray.SCD_vmBlockOrMemHandle, ax

	mov	ax, es:MBH_charAttrElements
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_vmBlockOrMemHandle, ax

	mov	ax, es:MBH_paraAttrElements
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].\
					SCD_vmBlockOrMemHandle, ax

	call	GetFirstArticle			;bxsi = article
	mov	ax, MSG_VIS_TEXT_LOAD_STYLE_SHEET
	mov	dx, size StyleSheetParams
	mov	di, mask MF_STACK
	call	ObjMessage

	add	sp, size StyleSheetParams

	pop	bx, bp
	call	VMUnlock
	mov	al, FILE_NO_ERRORS
	call	VMClose

done:

	call	AcceptUndo
	ret

;---

initParams:
	mov	ss:[bp].SSP_xferStyleArray.SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_vmFile, bx
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_vmFile, bx

	mov	ss:[bp].SSP_xferStyleArray.SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[0].SCD_chunk, VM_ELEMENT_ARRAY_CHUNK
	mov	ss:[bp].SSP_xferAttrArrays[(size StyleChunkDesc)].SCD_chunk,
							VM_ELEMENT_ARRAY_CHUNK
	retn

StudioDocumentLoadStyleSheet	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentSetMiscFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the document's MiscStudioDocumentFlags.

CALLED BY:	MSG_STUDIO_DOCUMENT_SET_MISC_FLAGS
PASS:		*ds:si	= StudioDocumentClass object
		ds:di	= StudioDocumentClass instance data
		ds:bx	= StudioDocumentClass object (same as *ds:si)
		es 	= segment of StudioDocumentClass
		ax	= message #

		cx	- MiscStudioDocumentFlags to set
		dx	- MiscStudioDocumentFlags to clear

RETURN:		dx	- old MiscStudioDocumentFlags
DESTROYED:	ax, cx
	bx, si, di, ds, es (message handler)

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	11/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentSetMiscFlags	method dynamic StudioDocumentClass, 
					MSG_STUDIO_DOCUMENT_SET_MISC_FLAGS
	call	LockMapBlockES
	mov	ax, es:MBH_miscFlags
	mov	di, ax				; save old flags
	or	ax, cx
	not	dx
	and	ax, dx
	mov	es:MBH_miscFlags, ax
	call	VMUnlockES

	; The status has changed so send a notification out.

	call	SendHyperlinkStatusChangeNotification

	mov	dx, di				; return old flags in dx
	ret
StudioDocumentSetMiscFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentGetMiscFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the document's MiscStudioDocumentFlags.

CALLED BY:	MSG_STUDIO_DOCUMENT_GET_MISC_FLAGS
PASS:		*ds:si	= StudioDocumentClass object
		ds:di	= StudioDocumentClass instance data
		ds:bx	= StudioDocumentClass object (same as *ds:si)
		es 	= segment of StudioDocumentClass
		ax	= message #
RETURN:		dx 	= MiscStudioDocumentFlags
DESTROYED:	
	bx, si, di, ds, es (message handler)

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentGetMiscFlags	method dynamic StudioDocumentClass, 
					MSG_STUDIO_DOCUMENT_GET_MISC_FLAGS
	call	LockMapBlockES
	mov	dx, es:MBH_miscFlags
	call	VMUnlockES

	ret
StudioDocumentGetMiscFlags	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentGetPageNameGraphicID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the unique ID to store in the next page name graphic.

CALLED BY:	MSG_STUDIO_DOCUMENT_GET_PAGE_NAME_GRAPHIC_ID
PASS:		*ds:si	= StudioDocumentClass object
		ds:di	= StudioDocumentClass instance data
		ds:bx	= StudioDocumentClass object (same as *ds:si)
		es 	= segment of StudioDocumentClass
		ax	= message #

RETURN:		cx	= ID
DESTROYED:	nothing
SIDE EFFECTS:	
	Increments ID stored in map block.
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	12/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentGetPageNameGraphicID	method dynamic StudioDocumentClass, 
					MSG_STUDIO_DOCUMENT_GET_PAGE_NAME_GRAPHIC_ID
		call	LockMapBlockES
		mov	cx, es:MBH_pageNameGraphicID
		inc	es:MBH_pageNameGraphicID
		call	VMUnlockES

		ret
StudioDocumentGetPageNameGraphicID	endm


DocMiscFeatures ends


