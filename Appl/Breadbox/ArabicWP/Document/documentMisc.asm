COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentMisc.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for WriteDocumentClass

	$Id: documentMisc.asm,v 1.1 97/04/04 15:56:52 newdeal Exp $

------------------------------------------------------------------------------@

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentRecreateCachedGStates --
		MSG_VIS_RECREATE_CACHED_GSTATES for WriteDocumentClass

DESCRIPTION:	Recreate all cached gstates for the document

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
	Tony	12/21/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentRecreateCachedGStates	method dynamic	WriteDocumentClass,
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

WriteDocumentRecreateCachedGStates	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSetStartingSection --
		MSG_WRITE_DOCUMENT_SET_STARTING_SECTION for WriteDocumentClass

DESCRIPTION:	Set the starting section number

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	dx - starting section number

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
WriteDocumentSetStartingSection	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_SET_STARTING_SECTION

	call	IgnoreUndoAndFlush

	; store the new value

	call	LockMapBlockES
	mov	es:MBH_startingSectionNum, dx

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

WriteDocumentSetStartingSection	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSetDisplayMode --
		MSG_WRITE_DOCUMENT_SET_DISPLAY_MODE for WriteDocumentClass

DESCRIPTION:	Set the display mode for the document

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentSetDisplayMode	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_SET_DISPLAY_MODE

	call	MarkBusy
	call	IgnoreUndoAndFlush

	push	cx
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	cx

	mov	ax, MSG_WRITE_DOCUMENT_SET_DISPLAY_MODE_LOW
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

	; make sure the the GeoWrite tool is selected

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].WDI_state, mask WDS_TARGET
	jz	afterTarget
	call	SetGeoWriteToolIfNotPageMode
afterTarget:

	call	AcceptUndo
	call	MarkNotBusy

	ret

WriteDocumentSetDisplayMode	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentSetDisplayModeLow --
		MSG_WRITE_DOCUMENT_SET_DISPLAY_MODE_LOW for WriteDocumentClass

DESCRIPTION:	Set the display mode for the document without changing any
		of the UI

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentSetDisplayModeLow	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_SET_DISPLAY_MODE_LOW

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

WriteDocumentSetDisplayModeLow	endm

DocSTUFF ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentNextPage -- MSG_META_PAGED_OBJECT_NEXT_PAGE
						for WriteDocumentClass

DESCRIPTION:	Go to the next page

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
	Tony	4/ 2/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentNextPage	method dynamic	WriteDocumentClass,
					MSG_META_PAGED_OBJECT_NEXT_PAGE

	mov	cx, ds:[di].WDI_currentPage
	inc	cx
	GOTO	GotoPageCommon

WriteDocumentNextPage	endm

;---

WriteDocumentPreviousPage	method dynamic	WriteDocumentClass,
					MSG_META_PAGED_OBJECT_PREVIOUS_PAGE

	mov	cx, ds:[di].WDI_currentPage
	jcxz	done
	dec	cx
	GOTO	GotoPageCommon
done:
	ret

WriteDocumentPreviousPage	endm

;---

WriteDocumentGotoPage	method dynamic	WriteDocumentClass,
					MSG_META_PAGED_OBJECT_GOTO_PAGE

	call	LockMapBlockES
	clr	ax
	push	cx
	call	SectionArrayEToP_ES		;es:di = section
	pop	cx
	sub	cx, es:[di].SAE_startingPageNum
	call	VMUnlockES

	FALL_THRU	GotoPageCommon

WriteDocumentGotoPage	endm

;---

GotoPageCommon	proc	far
	class	WriteDocumentClass

	call	LockMapBlockES

	cmp	cx, es:MBH_totalPages
	jb	20$
	mov	cx, es:MBH_totalPages
	dec	cx
20$:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
ifdef _VS150
	or	ds:[di].WDI_state, mask WDS_GOTO_PAGE
endif
	cmp	cx, ds:[di].WDI_currentPage
	LONG jz	done

	mov	ax, cx
	call	MapPageToSectionPage		;ax = section, bx = page

	; calculate notification flags

	mov	bp, mask NF_PAGE
	cmp	ax, ds:[di].WDI_currentSection
	jz	30$
	ornf	bp, mask NF_SECTION
30$:
	mov	ds:[di].WDI_currentSection, ax
	mov	ds:[di].WDI_currentPage, cx

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
ifdef _VS150
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
else
	call	DN_ObjMessageNoFlags
endif

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

MESSAGE:	WriteDocumentLoadStyleSheet --
		MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET for WriteDocumentClass

DESCRIPTION:	Load a style sheet

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentLoadStyleSheet	method dynamic	WriteDocumentClass,
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
	call	WriteVMBlockToMemBlock			;ax = handle
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

WriteDocumentLoadStyleSheet	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedwoodPrintNotifyPrintDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_PRINT_NOTIFY_PRINT_DB
PASS:		*ds:si	= WriteDocumentClass object
		ds:di	= WriteDocumentClass instance data
		ds:bx	= WriteDocumentClass object (same as *ds:si)
		es 	= segment of WriteDocumentClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	1/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150
	
RedwoodPrintNotifyPrintDB	method dynamic WriteDocumentClass, 
					MSG_PRINT_NOTIFY_PRINT_DB
	.enter

	cmp	bp, PCS_PRINT_BOX_VISIBLE
	jne	callSuper

	;
	; save the regs for the call to the super class
	;
	push	ax, cx, dx, bp, si, es

	;
	; set up dx:bp to hold the PageSizeReport
	;
	sub	sp, size PageSizeReport
	mov	bp, sp
	mov	dx, ss

	;
	; being here means that the PrintControlbox is just about to be
	; put onto the screen.  Now we want to get the data from the
	; document, i.e. the file handle
	;
	push	bx

	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	mov	bx, ds:[di].GDI_fileHandle

	;
	; save bp - it points to the PageSizeReport
	;
	mov	si, bp

	call	VMGetMapBlock
	call	VMLock

	mov	es, ax
	clr	bx

	mov	cx, es:[bx].MBH_pageSize.XYS_width
	mov	ss:[si].PSR_width.low, cx
	clr	ss:[si].PSR_width.high

	mov	cx, es:[bx].MBH_pageSize.XYS_height
	mov	ss:[si].PSR_height.low, cx
	clr	ss:[si].PSR_height.high

	mov	cx, es:[bx].MBH_pageInfo
	mov	ss:[si].PSR_layout, cx

	call	VMUnlock

	pop	bx

	;
	; We want to reset the pagesize of the print control, to be
	; the same as the one picked in the page size control
	;
	GetResourceHandleNS WritePrintControl, bx
	mov	bp, si
	mov	dx, ss
	mov	si, offset WritePrintControl
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_PRINT_SET_PRINT_CONTROL_PAGE_SIZE
	call	ObjMessage 

	add	sp, size PageSizeReport

	;
	; restore the data from the initial call
	;
	pop	ax, cx, dx, bp, si, es

callSuper:
	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock	

	.leave
	ret
RedwoodPrintNotifyPrintDB	endm

else


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WDPrintNotifyPrintDb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notifies that the print dialog box is coming up or going down.
		If coming up, and there's nothing in the clipboard, then
		the Merge triggers will be disabled.

CALLED BY:	MSG_PRINT_NOTIFY_PRINT_DB
PASS:		*ds:si	= WriteDocumentClass object
		ds:di	= WriteDocumentClass instance data
		ds:bx	= WriteDocumentClass object (same as *ds:si)
		es 	= segment of WriteDocumentClass
		ax	= message #

		cx:dx	= OD of the PrintControlClass object
		bp	= PrintControlStatus

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	LEW	6/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WDPrintNotifyPrintDb	method dynamic WriteDocumentClass, 
					MSG_PRINT_NOTIFY_PRINT_DB
	.enter

	cmp	bp, PCS_PRINT_BOX_VISIBLE
	jne	done

	mov	ax, MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	call	UserCallApplication

done:
	.leave
	ret
WDPrintNotifyPrintDb	endm



endif

DocMiscFeatures ends

