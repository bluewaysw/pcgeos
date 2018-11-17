COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentUserSection.asm

ROUTINES:
	Name				Description
	----				-----------
    INT DPS_ObjMessageNoFlags	Notification that a master page body has
				been unsuspended

    INT DPS_ObjMessageFixupDS	Notification that a master page body has
				been unsuspended

    INT ValidateNewPageSetup	Validate the user's changes to the Page
				Setup dialog box

    INT RecalculateSection	Recalculate the master pages for a section

    INT RecalculateArticleRegions 
				Recalculate the article regions

    INT RecalculateArticleRegionsLow 
				Recalculate the article regions ignoring
				the MANUAL flag

    INT DeleteArticleRegionsInSectionCallback 
				Delete all article regions in a given
				section

    INT ValidateNewPageSize	Validate the user's changes to the Page
				Size dialog box

    INT ValidateSectionForNewPageSize 
				Validate that the given section is legal
				for the new page size

    INT ChangeSectionPageSizeCallback 
				Change the page size for a section

    INT RecalcMPFlowRegions	Recalculate flow regions for a master page

    INT ConvertToPixelsAX	Recalculate flow regions for a master page

    INT ConvertToPixelsCX	Recalculate flow regions for a master page

    INT ConvertToPixelsDX	Recalculate flow regions for a master page

    INT DeleteFlowRegionCallback 
				Callback to delete the objects associated
				with a flow region

    INT DeleteFlowRegionAccessories 
				Delete the accessory objects to a flow
				region

    INT DBFreeRefDS		Free a db item, getting the file from DS

    INT CreateMPFlowRegion	Create a flow region for a master page

    INT ReapplyCommon		Reapply the master page for the section

    INT StudioDocumentReportPageSize
				Does the real work for ReportPageSizeHigh

    INT GetAppPageSizeAndMargins
				Retrieve the page size and margin info from
				the app object.

METHODS:
	Name			Description
	----			-----------
    StudioDocumentMPBodySuspend	Notification that a master page body has
				been suspended

				MSG_STUDIO_DOCUMENT_MP_BODY_SUSPEND
				StudioDocumentClass

    StudioDocumentMPBodyUnsuspend  
				Notification that a master page body has
				been unsuspended

				MSG_STUDIO_DOCUMENT_MP_BODY_UNSUSPEND
				StudioDocumentClass

    StudioDocumentChangePageSetup  
				Change the page setup

				MSG_STUDIO_DOCUMENT_CHANGE_PAGE_SETUP
				StudioDocumentClass

    StudioDocumentReportPageSizeHigh Handle a change in the page size

				MSG_PRINT_REPORT_PAGE_SIZE
				StudioDocumentClass

    StudioDocumentResetReapplyMasterPage  
				Reapply the master page for the section
				after resetting the master page

				MSG_STUDIO_DOCUMENT_RESET_REAPPLY_MASTER_PAGE
				StudioDocumentClass

    StudioDocumentReapplyExistingMasterPage  
				Reapply the master page for the section

				MSG_STUDIO_DOCUMENT_REAPPLY_EXISTING_MASTER_PAGE
				StudioDocumentClass

    StudioDocumentPlatformStatus
				Enable or disable the GenValue in platform
				emulation dialog.

				MSG_STUDIO_DOCUMENT_PLATFORM_STATUS
				StudioDocumentClass

    StudioDocumentSetPlatform	Handle platform change initiated by the
				PlatformItemGroup.

				MSG_STUDIO_DOCUMENT_SET_PLATFORM
				StudioDocumentClass
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the UI section related code for StudioDocumentClass

	$Id: documentPageSetup.asm,v 1.1 97/04/04 14:39:36 newdeal Exp $

------------------------------------------------------------------------------@

DocEditMP segment resource
COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentMPBodySuspend --
		MSG_STUDIO_DOCUMENT_MP_BODY_SUSPEND for StudioDocumentClass

DESCRIPTION:	Notification that a master page body has been suspended

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
	Tony	3/22/93		Initial version

------------------------------------------------------------------------------@
StudioDocumentMPBodySuspend	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_MP_BODY_SUSPEND

	inc	ds:[di].SDI_mpBodySuspendCount
	ret

StudioDocumentMPBodySuspend	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentMPBodyUnsuspend --
		MSG_STUDIO_DOCUMENT_MP_BODY_UNSUSPEND for StudioDocumentClass

DESCRIPTION:	Notification that a master page body has been unsuspended

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
	Tony	3/22/93		Initial version

------------------------------------------------------------------------------@
StudioDocumentMPBodyUnsuspend	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_MP_BODY_UNSUSPEND

	dec	ds:[di].SDI_mpBodySuspendCount
	jnz	done

	test	ds:[di].SDI_state, mask SDS_RECALC_ABORTED
	jz	done

	andnf	ds:[di].SDI_state, not mask SDS_RECALC_ABORTED

	mov	ax, MSG_STUDIO_DOCUMENT_RECALC_LAYOUT
	call	ObjCallInstanceNoLock

done:
	ret

StudioDocumentMPBodyUnsuspend	endm

DocEditMP ends

;---

DocPageSetup segment resource

DPS_ObjMessageNoFlags	proc	near
	push	di
	clr	di
	call	ObjMessage
	pop	di
	ret
DPS_ObjMessageNoFlags	endp

DPS_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DPS_ObjMessageFixupDS	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentChangePageSetup --
		MSG_STUDIO_DOCUMENT_CHANGE_PAGE_SETUP for StudioDocumentClass

DESCRIPTION:	Change the page setup

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
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentChangePageSetup	method dynamic	StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_CHANGE_PAGE_SETUP
section		local	SectionArrayElement
	.enter

	; get the data from the dialog box

	push	si
	GetResourceHandleNS	LayoutFirstPageValue, bx
	mov	si, offset LayoutFirstPageValue
	call	callValueGetValue
	mov	section.SAE_startingPageNum, dx

	mov	si, offset LayoutFirstBooleanGroup
	call	callBooleanGetValue
	mov	section.SAE_flags, ax

	mov	si, offset LayoutColumnsValue
	call	callValueGetValue
	mov	section.SAE_numColumns, dx

	mov	si, offset LayoutColumnSpacingDistance
	call	callValueGetDistance
	mov	section.SAE_columnSpacing, dx
	mov	si, offset LayoutColumnRuleWidthDistance
	call	callValueGetDistance
	mov	section.SAE_ruleWidth, dx

	mov	si, offset LayoutMasterPageList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	push	bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	inc	ax
	mov	section.SAE_numMasterPages, ax

	mov	si, offset LayoutMarginLeftDistance
	call	callValueGetDistance
	mov	section.SAE_leftMargin, dx
	mov	si, offset LayoutMarginTopDistance
	call	callValueGetDistance
	mov	section.SAE_topMargin, dx
	mov	si, offset LayoutMarginRightDistance
	call	callValueGetDistance
	mov	section.SAE_rightMargin, dx
	mov	si, offset LayoutMarginBottomDistance
	call	callValueGetDistance
	mov	section.SAE_bottomMargin, dx
	pop	si

	call	LockMapBlockES

	; verify that this new page setup is legal, given the page size

	call	ValidateNewPageSetup
	LONG jc	done

	call	IgnoreUndoAndFlush
	call	VMDirtyES

	call	SuspendDocument

	; Get the page setup changes from the various UI objects and stuff
	; them in the section array

	mov	ax, offset PageSetupTitlePageString
	mov	cx, offset EditHeaderTitlePageTable
	mov	dx, CustomDialogBoxFlags \
			<0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>
	call	GetSectionToOperateOn
	call	SectionArrayEToP_ES		;es:di = SectionArrayElement

	; has anything changed that requires recalculation ?

	mov	ax, section.SAE_numMasterPages
	cmp	ax, es:[di].SAE_numMasterPages
	jnz	gotRecalcFlag
	mov	ax, section.SAE_numColumns
	cmp	ax, es:[di].SAE_numColumns
	jnz	gotRecalcFlag
	mov	ax, section.SAE_ruleWidth
	cmp	ax, es:[di].SAE_ruleWidth
	jnz	gotRecalcFlag
	mov	ax, section.SAE_columnSpacing
	cmp	ax, es:[di].SAE_columnSpacing
	jnz	gotRecalcFlag
	mov	ax, section.SAE_leftMargin
	cmp	ax, es:[di].SAE_leftMargin
	jnz	gotRecalcFlag
	mov	ax, section.SAE_topMargin
	cmp	ax, es:[di].SAE_topMargin
	jnz	gotRecalcFlag
	mov	ax, section.SAE_rightMargin
	cmp	ax, es:[di].SAE_rightMargin
	jnz	gotRecalcFlag
	mov	ax, section.SAE_bottomMargin
	cmp	ax, es:[di].SAE_bottomMargin
gotRecalcFlag:

	pushf

	push	si, di, ds
	segmov	ds, ss
	lea	si, section
	add	si, offset SAE_startCopyVars
	add	di, offset SAE_startCopyVars
	mov	cx, (offset SAE_endCopyVars) - (offset SAE_startCopyVars)
	rep	movsb
	pop	si, di, ds

	popf
	jz	noRecalc
	call	RecalculateSection
	jmp	afterRecalc
noRecalc:
	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp
afterRecalc:

	call	UnsuspendDocument

	mov	ax, mask NF_PAGE or mask NF_SECTION or mask NF_TOTAL_PAGES
	call	SendNotification

	call	AcceptUndo

done:
	call	VMUnlockES

	.leave
	ret

;---

callValueGetValue:
	push	di, bp
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;dx.cx = value / 8
	pop	di, bp
	retn

;---

callBooleanGetValue:
	push	di, bp
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;ax = booleans
	pop	di, bp
	retn

;---

callValueGetDistance:
	call	callValueGetValue
	shl	cx
	rcl	dx
	shl	cx
	rcl	dx
	shl	cx
	rcl	dx
	retn

StudioDocumentChangePageSetup	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	ValidateNewPageSetup

DESCRIPTION:	Validate the user's changes to the Page Setup dialog box

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block
	ss:bp - inherited variables (including the new page setup)

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
	Tony	2/22/93		Initial version

------------------------------------------------------------------------------@
ValidateNewPageSetup	proc	near
	.enter inherit StudioDocumentChangePageSetup

	; to be legal in Y the columns must be at least 1 inch high

	mov	bx, section.SAE_topMargin
	add	bx, section.SAE_bottomMargin
	shr	bx
	shr	bx
	shr	bx				;convert to points
	mov	ax, es:MBH_pageSize.XYS_height
	sub	ax, bx				;ax = column height
	jbe	heightError
	cmp	ax, MINIMUM_COLUMN_HEIGHT
	jae	heightOK
heightError:
	mov	ax, offset ColumnTooShortString
	jmp	error

heightOK:

	; to be legal in X the column with must be OK

	; totalColumnSpacing = (numColumns-1) * columnSpacing

	mov	ax, section.SAE_numColumns
	dec	ax
	mul	section.SAE_columnSpacing	;ax = total spacing
	add	ax, section.SAE_leftMargin
	add	ax, section.SAE_rightMargin
	shr	ax
	shr	ax
	shr	ax
	mov_tr	bx, ax

	; calculate the column width
	;	= (pageWidth - totalSpacing) / numColumns

	mov	ax, es:MBH_pageSize.XYS_width
	sub	ax, bx
	jc	widthError
	div	section.SAE_numColumns
	cmp	ax, MINIMUM_COLUMN_WIDTH
	jae	regionOK
widthError:
	mov	ax, offset ColumnTooNarrowString
error:
	call	DisplayError
	stc
	jmp	done

regionOK:
	clc
done:
	.leave
	ret

ValidateNewPageSetup	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateSection

DESCRIPTION:	Recalculate the master pages for a section

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - section array element

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
	Tony	6/ 4/92		Initial version

------------------------------------------------------------------------------@
RecalculateSection	proc	far
EC <	call	AssertIsStudioDocument					>

	; Recalculate the master pages for the document

	clr	bx
	mov	cx, es:[di].SAE_numMasterPages
recalcLoop:
	mov	ax, es:[di][bx].SAE_masterPages
	tst	ax
	jnz	notNew
	call	DuplicateMasterPage		;create a new master page
	mov	es:[di][bx].SAE_masterPages, ax
notNew:
	call	RecalcMPFlowRegions

	push	bx, cx
	call	FindOpenMasterPage
	mov	dx, bx				;dx = display block
	pop	bx, cx
	jnc	noRename
	call	SetMPDisplayName
noRename:

	add	bx, size word
	loop	recalcLoop

	; Check for extra (unneeded) master pages at the end

checkExtraMasterPageLoop:
	cmp	bx, MAX_MASTER_PAGES * (size word)
	jz	afterCheckMP
	clr	ax
	xchg	ax, es:[di][bx].SAE_masterPages
	tst	ax
	jz	afterCheckMP
	call	VMDirtyES
	call	DeleteMasterPage
	add	bx, size word
	jmp	checkExtraMasterPageLoop
afterCheckMP:

	; now recalculate the article regions for the section

	call	RecalculateArticleRegions

	ret

RecalculateSection	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateArticleRegions

DESCRIPTION:	Recalculate the article regions

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - section array element

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
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
RecalculateArticleRegions	proc	far
	class	StudioDocumentClass

EC <	call	AssertIsStudioDocument					>

	push	ds
	call	StudioGetDGroupDS
	test	ds:[miscSettings], mask SMS_AUTOMATIC_LAYOUT_RECALC
	pop	ds
	jz	noRecalc

	mov	bx, ds:[si]
	add	bx, ds:[bx].Gen_offset
	tst	ds:[bx].SDI_mpBodySuspendCount
	jz	recalc
	ornf	ds:[bx].SDI_state, mask SDS_RECALC_ABORTED

noRecalc:
	ornf	es:[di].SAE_flags, mask SF_NEEDS_RECALC
	call	VMDirtyES
	ret

recalc:
	call	RecalculateArticleRegionsLow
	ret

RecalculateArticleRegions	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateArticleRegionsLow

DESCRIPTION:	Recalculate the article regions ignoring the MANUAL flag

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - section array element

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
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
RecalculateArticleRegionsLow	proc	far
EC <	call	AssertIsStudioDocument					>

	call	SuspendFlowRegionNotifications
	call	SuspendDocument

	push	bp
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	bp

	; recalculate the paths stored with the flow regions for each master
	; page

	clr	bx
	mov	cx, es:[di].SAE_numMasterPages
destroyLoop:
	mov	ax, es:[di][bx].SAE_masterPages
	call	RecalculateMPTextFlowRegions
	add	bx, size word
	loop	destroyLoop

	push	es:[di].SAE_numPages

	push	si, ds
	segmov	ds, es
	mov	si, offset SectionArray
	call	ChunkArrayPtrToElement
	pop	si, ds
	mov_tr	dx, ax				;dx = section number

	call	GetFileHandle
	mov	cx, bx

	; delete all old flow regions

	push	si, ds, es
	segmov	ds, es
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset DeleteArticleRegionsInSectionCallback
	call	ChunkArrayEnum
	pop	si, ds, es
	pop	cx				;cx = num pages
	mov_tr	ax, dx				;ax = section

	; create flow regions for all pages

	clr	bx
pageLoop:
	push	cx
	mov	cx, 0x0100			;pass "create only" flag
	clr	dx				;not direct user action
	call	AddDeletePageToSection
	pop	cx
	inc	bx
	loop	pageLoop

	call	UnsuspendDocument
	call	UnsuspendFlowRegionNotifications

	ret

RecalculateArticleRegionsLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteArticleRegionsInSectionCallback

DESCRIPTION:	Delete all article regions in a given section

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	cx - vm file
	dx - section number

RETURN:
	carry - set to end (always returned clear)

DESTROYED:
	ax, bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
DeleteArticleRegionsInSectionCallback	proc	far
	push	ds:[LMBH_handle]
	segmov	es, ds				;es = map block

	mov	bx, cx
	mov	ax, ds:[di].AAE_articleBlock
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	push	bx
	call	ObjLockObjBlock
	mov	ds, ax				;ds = article block

	mov	si, offset ArticleRegionArray
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	jcxz	done
	add	di, ds:[di].CAH_offset

deleteLoop:
	cmp	dx, ds:[di].VLTRAE_section
	jnz	next
	call	DeleteArticleRegion
	sub	di, size ArticleRegionArrayElement
next:
	add	di, size ArticleRegionArrayElement
	loop	deleteLoop
done:
	pop	bx
	call	MemUnlock

	pop	bx
	call	MemDerefDS

	clc
	ret

DeleteArticleRegionsInSectionCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentReportPageSizeHigh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MESSAGE:	StudioDocumentReportPageSize -- MSG_PRINT_REPORT_PAGE_SIZE
							for StudioDocumentClass
SYNOPSIS:	Handle a change in the page size

CALLED BY:	MSG_PRINT_REPORT_PAGE_SIZE
PASS:		*ds:si	= StudioDocumentClass object
		es 	= segment of StudioDocumentClass
		ax	= message #
		ss:bp	= PageSizeReport
RETURN:		
DESTROYED:	bx, si, di, ds, ex (message handler)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
       All the work is done by MSG_STUDIO_DOCUMENT_REPORT_PAGE_SIZE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	6/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentReportPageSizeHigh	method dynamic StudioDocumentClass, 
					MSG_PRINT_REPORT_PAGE_SIZE
		mov	dx, 1	;reset emulation to PET_NONE
		call	StudioDocumentReportPageSize
		ret
StudioDocumentReportPageSizeHigh	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentReportPageSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a change in the page size (does the real work)

CALLED BY:	StudioDocumentReportPageSizeHigh,
		StudioDocumentSetPlatform
PASS:		*ds:si	= StudioDocumentClass object
		ds:di	= StudioDocumentClass instance data
		es 	= segment of StudioDocumentClass
		dx 	= non-zero if emulation should be reset to PET_NONE
		ss:bp	= PageSizeReport
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version
	dubois	6/10/94   	re-named message

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentReportPageSize	proc	far
	class StudioDocumentClass

	mov	ax, ss:[bp].PSR_width.low
	mov	bx, ss:[bp].PSR_height.low
	mov	cx, ss:[bp].PSR_layout

resetEmulation	local	word		push	dx
	clr	dx
newHeight	local	word		push	bx
newWidth	local	word		push	ax
layout		local	PageLayout	push	cx
document	local	optr		push	ds:[LMBH_handle], si
oldWidth	local	dword		push	dx, dx
oldHeight	local	dword		push	dx, dx
fileHandle	local	hptr
widthChange	local	dword
heightChange	local	dword
insDelParams	local	InsertDeleteSpaceParams
	.enter

	; if this didn't come from the emulation gadget, reset emulation
	; gadget to PET_NONE
	; remember the .enter inherits...
	;
	call	LockMapBlockES

	tst	resetEmulation
	jz	noReset
	mov	es:MBH_currentEmulationState.low, PET_NONE
noReset:

	; verify that this new page setup is legal, given the page size

	call	ValidateNewPageSize
	LONG jc	done

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, newWidth
	mov	bx, newHeight
	mov	cx, layout
	mov	ds:[di].SDI_pageHeight, bx
	mov	ds:[di].SDI_size.PD_x.low, ax

	call	IgnoreUndoAndFlush
	call	VMDirtyES

	; DON'T suspend notifications because deleting space may cause
	; flow regions to be deleted, and we want to make sure we get
	; notification so that we clean up our ArticleArrayElement
	; structures.  Fail case is taking a multi-page document and
	; converting the page size to 1-inch high labels. -chrisb 5/94
		
;;	call	SuspendFlowRegionNotifications

	; Set common parameters

	clr	dx
	mov	insDelParams.IDSP_type, mask IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELETED_SPACE or mask IDST_RESIZE_OBJECTS_INTERSECTING_SPACE or mask IDST_DELETE_OBJECTS_SHRUNK_TO_ZERO_SIZE
	mov	insDelParams.IDSP_position.PDF_x.DWF_frac, dx
	mov	insDelParams.IDSP_space.PDF_x.DWF_frac, dx
	mov	insDelParams.IDSP_position.PDF_y.DWF_frac, dx
	mov	insDelParams.IDSP_space.PDF_y.DWF_frac, dx

	; First update the variables in the map block

	mov	es:MBH_pageInfo, cx
	mov	cx, ax
	mov	dx, bx
	xchg	cx, es:MBH_pageSize.XYS_width		;store new, get old
	xchg	dx, es:MBH_pageSize.XYS_height

	mov	oldWidth.low, cx
	mov	oldHeight.low, dx

	call	SendPageSizeToView

	sub	ax, cx				;ax = width change
	sub	bx, dx				;bx = height change
	push	bx
	cwd
	movdw	widthChange, dxax
	pop	ax
	cwd
	movdw	heightChange, dxax

	call	GetFileHandle
	mov	fileHandle, bx

	; Change the width of the main body

	movdw	insDelParams.IDSP_position.PDF_x.DWF_int, oldWidth, ax
	movdw	insDelParams.IDSP_space.PDF_x.DWF_int, widthChange, ax
	clrdw	insDelParams.IDSP_position.PDF_y.DWF_int
	clrdw	insDelParams.IDSP_space.PDF_y.DWF_int

	call	MarkBusy
	call	SuspendDocument

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MainBody
	call	callSpace

	; Now go through all the pages moving graphics as needed

	; note that this is an O(N^2) algorithm, since for each page we add
	; space, which causes the grobj to send a message to every grobj
	; object -- sigh

	mov	cx, es:MBH_totalPages
	clrdw	dxax
resizeLoop:
	pushdw	dxax
	adddw	dxax, oldHeight
	movdw	insDelParams.IDSP_position.PDF_y.DWF_int, dxax
	movdw	insDelParams.IDSP_space.PDF_y.DWF_int, heightChange, di
	clrdw	insDelParams.IDSP_position.PDF_x.DWF_int
	clrdw	insDelParams.IDSP_space.PDF_x.DWF_int
	popdw	dxax
	add	ax, newHeight
	adc	dx, 0
	call	callSpace
	loop	resizeLoop

	; Loop through each section, changing the bounds of the master pages
	; and recalculating the page setup

	movdw	insDelParams.IDSP_position.PDF_x.DWF_int, oldWidth, ax
	movdw	insDelParams.IDSP_space.PDF_x.DWF_int, widthChange, ax
	movdw	insDelParams.IDSP_position.PDF_y.DWF_int, oldHeight, ax
	movdw	insDelParams.IDSP_space.PDF_y.DWF_int, heightChange, ax

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset ChangeSectionPageSizeCallback
	call	ChunkArrayEnum

	; Reset the bounds of the document

	movdw	bxsi, document
	call	MemDerefDS

	call	UnsuspendDocument
	call	MarkNotBusy

	; update the size stored in the views

	call	SendDocumentSizeToView

	push	si
	mov	di, ds:[OpenMasterPageArray]
	mov	cx, ds:[di].CAH_count
	jcxz	noMasterPages
	add	di, ds:[di].CAH_offset
resizeMPLoop:
	push	cx
	mov	ax, ds:[di].OMP_vmBlock
	mov	bx, ds:[di].OMP_display
	mov	cx, ds:[di].OMP_content
	call	SendMPSizeToView
	add	di, size OpenMasterPage
	pop	cx
	loop	resizeMPLoop
noMasterPages:
	pop	si					;document chunk

;;	call	UnsuspendFlowRegionNotifications

	call	AcceptUndo

done:
	mov	ax, mask NF_PAGE_SIZE
	call	SendNotification

	call	VMUnlockES
	.leave
	ret

;---

callSpace:
	push	ax, cx, dx, bp
	lea	bp, insDelParams
 	mov	ax, MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
	call	DPS_ObjMessageNoFlags
	pop	ax, cx, dx, bp
	retn

StudioDocumentReportPageSize	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ValidateNewPageSize

DESCRIPTION:	Validate the user's changes to the Page Size dialog box

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block
	ss:bp - inherited variables (including newHeight and newWidth)

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
	Tony	2/22/93		Initial version

------------------------------------------------------------------------------@
ValidateNewPageSize	proc	near	uses si, ds
	.enter inherit StudioDocumentReportPageSize

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset ValidateSectionForNewPageSize
	call	ChunkArrayEnum
	jnc	done
	call	DisplayError
	stc
done:
	.leave
	ret

ValidateNewPageSize	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ValidateSectionForNewPageSize

DESCRIPTION:	Validate that the given section is legal for the new page size

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	ss:bp - inherited variables (including newHeight and newWidth)

RETURN:
	carry - set if error
		ax - error message if error

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/22/93		Initial version

------------------------------------------------------------------------------@
ValidateSectionForNewPageSize	proc	far
	.enter inherit StudioDocumentReportPageSize

	; to be legal in Y the columns must be at least 1 inch high

	mov	bx, ds:[di].SAE_topMargin
	add	bx, ds:[di].SAE_bottomMargin
	shr	bx
	shr	bx
	shr	bx				;convert to points
	mov	ax, newHeight
	sub	ax, bx				;ax = column height
	jbe	heightError
	cmp	ax, MINIMUM_COLUMN_HEIGHT
	jae	heightOK
heightError:
	mov	ax, offset PageSizeColumnTooShortString
	jmp	error

heightOK:

	; to be legal in X the column with must be OK

	; totalColumnSpacing = (numColumns-1) * columnSpacing

	mov	ax, ds:[di].SAE_numColumns
	dec	ax
	mul	ds:[di].SAE_columnSpacing	;ax = total spacing
	add	ax, ds:[di].SAE_leftMargin
	add	ax, ds:[di].SAE_rightMargin
	shr	ax
	shr	ax
	shr	ax
	mov_tr	bx, ax

	; calculate the column width
	;	= (pageWidth - totalSpacing) / numColumns

	mov	ax, newWidth
	sub	ax, bx
	jc	widthError
	div	ds:[di].SAE_numColumns
	cmp	ax, MINIMUM_COLUMN_WIDTH
	jae	regionOK
widthError:
	mov	ax, offset PageSizeColumnTooNarrowString
error:
	stc
	jmp	done

regionOK:
	clc
done:
	.leave
	ret

ValidateSectionForNewPageSize	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeSectionPageSizeCallback

DESCRIPTION:	Change the page size for a section

CALLED BY:	StudioDocumentReportPageSize (via ChunkArrayEnum)

PASS:
	ds:di - SectionArrayElement
	ss:bp - inherited variables (from StudioDocumentReportPageSize)

RETURN:
	carry - clear (continue enumeration)

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
ChangeSectionPageSizeCallback	proc	far
	.enter inherit StudioDocumentReportPageSize

	push	ds:[LMBH_handle]

	; loop through each master page

	mov	cx, ds:[di].SAE_numMasterPages
	clr	bx
changeSizeLoop:
	push	bx

	mov	ax, ds:[di][bx].SAE_masterPages
	mov	bx, fileHandle
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MasterPageBody

	; change the bounds of the body

	push	bp
	lea	bp, insDelParams
 	mov	ax, MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
	call	DPS_ObjMessageNoFlags
	pop	bp

	pop	bx
	add	bx, size hptr
	loop	changeSizeLoop

	; and recalculate the master page

	segmov	es, ds				;es:di = SectionArrayElement
	movdw	bxsi, document
	call	MemDerefDS
	call	RecalculateSection

	pop	bx
	call	MemDerefDS

	clc
	.leave
	ret

ChangeSectionPageSizeCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalcMPFlowRegions

DESCRIPTION:	Recalculate flow regions for a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es:di - SectionArrayElement
	bx - master page number * 2
	ax - master page VM block

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
RecalcMPFlowRegions	proc	far	uses ax, bx, cx, dx, si, bp, ds
	.enter
EC <	call	AssertIsStudioDocument					>

	call	IgnoreUndoAndFlush

	call	SuspendFlowRegionNotifications

	mov	cx, bx				;save master page # (*2)

	; lock master page block into DS

	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	push	bx				;save master page block
	call	ObjLockObjBlock
	mov	ds, ax
	push	cx				;save master page #

	; delete old flow regions for page

	push	di
	mov	si, offset FlowRegionArray
	mov	bx, cs
	mov	di, offset DeleteFlowRegionCallback
	call	ChunkArrayEnum
	pop	di
	call	ChunkArrayZero

	; create new flow regions for page based on page setup

	; totalColumnSpacing = (numColumns-1) * columnSpacing

	mov	ax, es:[di].SAE_numColumns
	dec	ax
	mov	cx, es:[di].SAE_columnSpacing
	call	ConvertToPixelsCX
	mul	cx				;ax = total spacing

	; calculate the column width
	;	= (pageWidth - totalSpacing) / numColumns

	mov	bx, es:MBH_pageSize.XYS_width
	mov	cx, es:[di].SAE_leftMargin
	call	ConvertToPixelsCX
	sub	bx, cx				;bx = page width - left
EC <	ERROR_C	BAD_COLUMN_WIDTH					>
	mov	cx, es:[di].SAE_rightMargin
	call	ConvertToPixelsCX
	sub	bx, cx				;bx = live text width
EC <	ERROR_C	BAD_COLUMN_WIDTH					>
	sub	bx, ax				;subtract out spacing
EC <	ERROR_C	BAD_COLUMN_WIDTH					>

	mov_tr	ax, bx
	clr	dx				;dx.ax = (width - spacing)
	div	es:[di].SAE_numColumns		;ax = width, dx = remainder
EC <	cmp	ax, MINIMUM_COLUMN_WIDTH				>
EC <	ERROR_B	BAD_COLUMN_WIDTH					>
	mov_tr	bp, ax				;bp = column width

	; get the left position for the columns (this is tricky if there
	; are two master pages)

	pop	bx				;bx = master page # (*2)
	mov	ax, es:[di].SAE_leftMargin	;position to create at
	cmp	es:[di].SAE_numMasterPages, 1
	jz	oneMasterPage
	tst	bx
	jz	oneMasterPage
	mov	ax, es:[di].SAE_rightMargin
oneMasterPage:

	call	ConvertToPixelsAX

	; loop to create the columns

	mov	cx, es:[di].SAE_numColumns
	mov	si, offset FlowRegionArray

	;	ax = current left side
	;	cx = number of columns (counter)
	;	bp = column width
	;	dx = remainder (extra pixels to distribute)

columnLoop:
	push	cx, dx, bp

	; set carry to create rule

	cmp	cx, 1
	clc
	jz	noRule
	tst_clc	es:[di].SAE_ruleWidth
	jz	noRule
	stc
noRule:
	pushf

	; calcuate column bounds

	mov	cx, ax
	add	cx, bp
	tst	dx
	jz	noExtraPixelsToDistribute
	inc	cx
	dec	dx
noExtraPixelsToDistribute:

	push	ax
	mov	ax, es:[di].SAE_topMargin
	call	ConvertToPixelsAX
	mov_tr	bx,ax
	mov	dx, es:MBH_pageSize.XYS_height
	mov	ax, es:[di].SAE_bottomMargin
	call	ConvertToPixelsAX
	sub	dx, ax
	pop	ax
	clr	bp				;use main article
	popf					;pass rule flag
	call	CreateMPFlowRegion

	mov_tr	ax, cx				;new left = old right
	mov	cx, es:[di].SAE_columnSpacing
	call	ConvertToPixelsCX
	add	ax, cx
	pop	cx, dx, bp
	loop	columnLoop

	; Create/move header and footer objects

	; Note that we must create the object one pixel larger on each
	; edge than we really want it to be because the text will end up
	; being inset one pixel

	; Header...

	mov	ax, HEADER_FOOTER_INSET_X-1		;ax = left

	mov	bx, HEADER_FOOTER_INSET_Y-1		;bx = top
	mov	cx, es:MBH_pageSize.XYS_width
	sub	cx, ax					;cx = right
	inc	cx
	mov	dx, es:[di].SAE_topMargin
	call	ConvertToPixelsDX
	sub	dx, HEADER_FOOTER_SPACING		;dx = bottom
	inc	dx
	push	cx, di
	mov	di, offset MPBH_header
	clr	bp					;header
	call	createDeleteHeaderFooter
	pop	cx, di

	; Footer...

	mov	dx, es:MBH_pageSize.XYS_height
	mov	bx, dx

	sub	dx, HEADER_FOOTER_INSET_Y		;dx= bottom
	inc	dx
	push	ax
	mov	ax, es:[di].SAE_bottomMargin
	call	ConvertToPixelsAX
	sub	bx, ax
	pop	ax
	add	bx, HEADER_FOOTER_SPACING		;bx = top
	dec	bx
	push	di
	mov	di, offset MPBH_footer
	mov	bp, 1					;footer
	call	createDeleteHeaderFooter
	pop	di

	pop	bx
	call	MemUnlock

	call	UnsuspendFlowRegionNotifications

	call	AcceptUndo

	.leave
	ret

	; pass:
	;	ax, bx, cx, dx = bounds
	;	ds:di = &optr
	;	bp = non-zero for footer
	; destroy:
	;	bx, dx, si, di, bp

createDeleteHeaderFooter:
	push	dx
	sub	dx, bx
	cmp	dx, MINIMUM_HEADER_FOOTER_HEIGHT 
	pop	dx
	LONG jl	noHeaderFooter

	sub	cx, ax				;cx = width
	sub	dx, bx				;dx = height
	tst	ds:[di].handle
	jz	createNewHeaderFooter

	; move the existing header/footer

	push	bx
	mov	bx, ds:[di].handle
	call	VMBlockToMemBlockRefDS		;bx = handle
	mov	si, bx
	pop	bx

	push	si, ds:[di].chunk		;push object optr
	clr	di
	push	di				;push y pos high
	call	MoveGrObj
	retn

	; ax, bx, cx, dx = bounds
	; bp = non-zero for footer
	; destroy: bx, cx, dx

createNewHeaderFooter:

	; create a new header/footer

	push	ds:[LMBH_handle], di

	clr	di
	push	di				;push y pos high
	push	ds:[LMBH_handle]
	mov	di, offset MasterPageBody
	push	di				;push body optr
	call	StudioGetDGroupDS
	push	ds
	mov	di, offset StudioHdrFtrGuardianClass ;push class pointer
	push	di
	mov	di, GRAPHIC_STYLE_HEADER_FOOTER
	push	di

	tst	bp
	jnz	footer
	mov	di, TEXT_STYLE_NORMAL
	jmp	hfCommon
footer:
	mov	di, TEXT_STYLE_NORMAL
hfCommon:
	push	di
	mov	di, HEADER_FOOTER_LOCKS
	push	di
	call	CreateGrObj			;cx:dx = new object

	pop	bx, di
	call	MemDerefDS
	call	MemBlockToVMBlockCX
	movdw	ds:[di], cxdx

	retn

noHeaderFooter:
	clrdw	bxsi
	xchgdw	bxsi, ds:[di]
	tst	bx
	jz	noHeaderFooterToDelete
	call	VMBlockToMemBlockRefDS		;bx = handle
	clr	cx
	mov	dx, mask GrObjLocks		;clear all the locks so that
	mov	ax, MSG_GO_CHANGE_LOCKS		;we can delete the object
	call	DPS_ObjMessageFixupDS
	mov	ax, MSG_GO_CLEAR
	call	DPS_ObjMessageFixupDS
noHeaderFooterToDelete:
	retn

RecalcMPFlowRegions	endp

;---

ConvertToPixelsAX	proc	near
	add	ax, 4
	shr	ax
	shr	ax
	shr	ax
	ret
ConvertToPixelsAX	endp

;---

ConvertToPixelsCX	proc	near
	xchg	ax, cx
	call	ConvertToPixelsAX
	xchg	ax, cx
	ret
ConvertToPixelsCX	endp

;---

ConvertToPixelsDX	proc	near
	xchg	ax, dx
	call	ConvertToPixelsAX
	xchg	ax, dx
	ret
ConvertToPixelsDX	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteFlowRegionCallback

DESCRIPTION:	Callback to delete the objects associated with a flow region

CALLED BY:	INTERNAL

PASS:
	*ds:si - array
	ds:di - FlowRegionArrayElement

RETURN:
	carry - set to end (always return clear)

DESTROYED:
	ax, bx, cx, dx, si, di, bp, es - can destroy

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
DeleteFlowRegionCallback	proc	far

	; delete the associated GrObj object

	movdw	bxsi, ds:[di].FRAE_flowObject
	call	VMBlockToMemBlockRefDS
	mov	ax, MSG_GO_CLEAR
	call	DPS_ObjMessageFixupDS

	call	DeleteFlowRegionAccessories

	clc
	ret

DeleteFlowRegionCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteFlowRegionAccessories

DESCRIPTION:	Delete the accessory objects to a flow region

CALLED BY:	INTERNAL

PASS:
	ds:di - FlowRegionArrayElement

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
DeleteFlowRegionAccessories	proc	far	uses si, di, bp
	.enter

	movdw	bxsi, ds:[di].FRAE_ruleObject
	tst	bx
	jz	noRuleObject
	call	VMBlockToMemBlockRefDS
	clr	cx
	mov	dx, mask GrObjLocks		;clear all the locks so that
	mov	ax, MSG_GO_CHANGE_LOCKS		;we can delete the rule object
	call	DPS_ObjMessageFixupDS
	mov	ax, MSG_GO_CLEAR
	call	DPS_ObjMessageFixupDS
noRuleObject:

	; free the region chunk

	mov	ax, offset FRAE_textRegion
	call	DBFreeRefDS
	mov	ax, offset FRAE_drawRegion
	call	DBFreeRefDS

	.leave
	ret

DeleteFlowRegionAccessories	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DBFreeRefDS

DESCRIPTION:	Free a db item, getting the file from DS

CALLED BY:	INTERNAL

PASS:
	ds:[di][ax] - db item to free
	ds - block owned by VM file

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
	Tony	9/15/92		Initial version

------------------------------------------------------------------------------@
DBFreeRefDS	proc	far	uses di
	.enter

	add	di, ax
	mov	ax, ds:[di].high
	tst	ax
	jz	done
	mov	di, ds:[di].low

	push	bx
	push	ax
	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo			;ax = VM file
	mov_tr	bx, ax				;bx = file
	pop	ax
	call	DBFree
	pop	bx
done:
	.leave
	ret

DBFreeRefDS	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateMPFlowRegion

DESCRIPTION:	Create a flow region for a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - flow region array
	ax, bx, cx, dx - region bounds
	es:di - SectionArrayElement
	bp - article
	carry - set to create rule

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
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
CreateMPFlowRegion	proc	near	uses ax, bx, cx, dx, di
	.enter

	pushf					;save rule flag

	; add an element to the array of flow regions for the master page

	sub	cx, ax				;cx = width
	sub	dx, bx				;dx = height
	push	ax, bx, cx, dx, di
	call	ChunkArrayAppend		;ds:di = FlowRegionArrayElement
	mov	ds:[di].FRAE_article, bp
	mov	ds:[di].FRAE_position.XYO_x, ax
	mov	ds:[di].FRAE_position.XYO_y, bx
	mov	ds:[di].FRAE_size.XYS_width, cx
	mov	ds:[di].FRAE_size.XYS_height, dx

	; create a GrObj object for the flow region

	push	ds:[LMBH_handle]

	clr	di
	push	di				;push y pos high
	push	ds:[LMBH_handle]
	mov	di, offset MasterPageBody
	push	di				;push body optr
	call	StudioGetDGroupDS
	push	ds
	mov	di, offset FlowRegionClass	;push class pointer
	push	di
	mov	di, GRAPHIC_STYLE_FLOW_REGION
	push	di
	mov	di, CA_NULL_ELEMENT
	push	di				;textStyle
	mov	di, MASTER_PAGE_FLOW_REGION_LOCKS
	push	di
	call	CreateGrObj			;cx:dx = new object
	pop	bx
	call	MemDerefDS

	; tell the flow region what master page block it is associated with

	mov	bx, ds:[LMBH_handle]
	call	VMMemBlockToVMBlock		;ax = master page VM block
	clr	bx				;bx = article VM block
	call	SetFlowRegionAssociation

	mov	ax, CA_LAST_ELEMENT
	call	ChunkArrayElementToPtr
	call	MemBlockToVMBlockCX
	movdw	ds:[di].FRAE_flowObject, cxdx

	pop	ax, bx, cx, dx, di

	; create ruler object

	popf
	jnc	noRule

	; gutter goes from top to bottom, left = right  = right + spacing/2

	push	ds:[LMBH_handle], si
	add	ax, cx				;ax = right side of region

	mov	cx, es:[di].SAE_ruleWidth
	call	ConvertToPixelsCX
	push	cx				;save rule width

	mov	cx, es:[di].SAE_columnSpacing
	call	ConvertToPixelsCX
	shr	cx
	add	ax, cx				;ax = object pos
	clr	cx				;width = 0

	clr	di
	push	di				;push y pos high
	push	ds:[LMBH_handle]
	mov	di, offset MasterPageBody
	push	di				;push body optr
	mov	di, segment LineClass
	push	di
	mov	di, offset LineClass		;push class pointer
	push	di
	mov	di, GRAPHIC_STYLE_RULE
	push	di
	mov	di, CA_NULL_ELEMENT
	push	di				;textStyle
	mov	di, RULE_LOCKS
	push	di
	call	CreateGrObj			;cx:dx = new object

	movdw	bxsi, cxdx
	pop	dx
	clr	cx				;dx.cx = width
	mov	ax, MSG_GO_SET_LINE_WIDTH
	call	DPS_ObjMessageNoFlags
	movdw	cxdx, bxsi

	pop	bx, si
	call	MemDerefDS

	mov	ax, CA_LAST_ELEMENT
	call	ChunkArrayElementToPtr
	call	MemBlockToVMBlockCX
	movdw	ds:[di].FRAE_ruleObject, cxdx

noRule:

	.leave
	ret

CreateMPFlowRegion	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentResetReapplyMasterPage --
		MSG_STUDIO_DOCUMENT_RESET_REAPPLY_MASTER_PAGE
						for StudioDocumentClass

DESCRIPTION:	Reapply the master page for the section after resetting
		the master page

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
	Tony	11/29/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentResetReapplyMasterPage	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_RESET_REAPPLY_MASTER_PAGE

	stc
	GOTO	ReapplyCommon

StudioDocumentResetReapplyMasterPage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentReapplyExistingMasterPage --
		MSG_STUDIO_DOCUMENT_REAPPLY_EXISTING_MASTER_PAGE
							for StudioDocumentClass

DESCRIPTION:	Reapply the master page for the section

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
	Tony	11/29/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentReapplyExistingMasterPage	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_REAPPLY_EXISTING_MASTER_PAGE

	clc
	FALL_THRU	ReapplyCommon

StudioDocumentReapplyExistingMasterPage	endm

;---

	; carry set to reset and reapply

ReapplyCommon	proc	far
	class	StudioDocumentClass
	pushf

	push	ds:[di].SDI_currentSection

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	call	LockMapBlockES

	call	IgnoreUndoNoFlush
	call	SuspendDocument

	pop	ax
	call	SectionArrayEToP_ES

	popf
	jnc	10$
	call	RecalculateSection
	jmp	common
10$:
	call	RecalculateArticleRegions
common:

	call	UnsuspendDocument
	call	AcceptUndo

	mov	ax, mask NF_PAGE or mask NF_TOTAL_PAGES
	call	SendNotification

	call	VMUnlockES

	ret

ReapplyCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentPlatformStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the GenValue and GenBooleanGroup
		in platform emulation dialog.

CALLED BY:	MSG_STUDIO_DOCUMENT_PLATFORM_STATUS
PASS:		*ds:si	= StudioDocumentClass object
		ds:di	= StudioDocumentClass instance data
		ds:bx	= StudioDocumentClass object (same as *ds:si)
		es 	= segment of StudioDocumentClass
		ax	= message #
		cx	= current selection or GIGS_NONE
		bp	= number selections
		dl	= GenItemGroupStateFlags
RETURN:		nothing
DESTROYED:	ax, bp, cx, dx

SIDE EFFECTS:	Enable or disable Custom{Width,Height}Value and the
		EmulationBooleanGroup objects.

PSEUDO CODE/STRATEGY:
	Assumes CustomHeightValue in same resource as CustomWidthValue
	genvalues are enabled iff cx = PET_CUSTOM
	booleans are enabled iff not PET_NONE, or not PET_CUSTOM

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	6/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentPlatformStatus	method dynamic StudioDocumentClass, 
					MSG_STUDIO_DOCUMENT_PLATFORM_STATUS
		GetResourceHandleNS	CustomWidthValue, bx
		mov	si, offset CustomWidthValue
		push	cx		; will get trashed
		call	sendMessage
		mov	si, offset CustomHeightValue
		pop	cx		; restore selection
		push	cx
		call	sendMessage
		pop	cx

		mov	si, offset EmulationBooleanGroup
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	cx, PET_NONE
		je	sendIt2
		cmp	cx, PET_CUSTOM
		je	sendIt2
		mov	ax, MSG_GEN_SET_ENABLED
sendIt2:
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		ret			; MAIN RETURN HERE

sendMessage:
		cmp	cx, PET_CUSTOM
		mov	ax, MSG_GEN_SET_ENABLED
		je	sendIt
		mov	ax, MSG_GEN_SET_NOT_ENABLED
sendIt:
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		retn
StudioDocumentPlatformStatus	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentSetPlatform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle platform change initiated by the PlatformItemGroup.

CALLED BY:	MSG_STUDIO_DOCUMENT_SET_PLATFORM
PASS:		*ds:si	= StudioDocumentClass object
		ds:di	= StudioDocumentClass instance data
		ds:bx	= StudioDocumentClass object (same as *ds:si)
		es 	= segment of StudioDocumentClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Sets the margins.

NOTES:
	ax holds the current PlatformEmulationState

PSEUDO CODE/STRATEGY:
	Save current width and height if changing from PET_NONE, so we can
	later restore when going back to PET_NONE.
	
	Change current width and height to:
	PET_NONE:	saved values from doc instance data
	PET_CUSTOM:	from GenValues, adjusted for margins
	other:		from WidthHeightTable, adjusted for margins and 
			possibly for tool heights.
       
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/19/94   	Initial version
	lester	12/ 5/94  	Added all the size comments and changed
				some of the sizes.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; Table of widths of usable viewing area on various platforms.  Note that
; this differs from page width in that usable width does not include margins.
;
; Notes on the Zoomer size:
; The Zoomer's physical screen size is 256x320 pixels.
; Width:
;   We use 254 pixels instead of 256 for the zoomer width because the 
;   BookReader text object has 1 pixel left and right margins. For the 
;   reason that we have 1 pixel margins, see BUG 31666.
; Height:
;   The height is more complicated because there are a few configurations
;   that change the available height. Here is the zoomer screen layout
;   from top to bottom:
;
;   menu bar = 13 pixels
;   book title bar (Book option) = 13 pixels 
;   clear line = 1 pixel
;   black line = 1 pixel
;   view = ??? (look at calculations below)
;   black line = 1 pixel
;   clear line = 1 pixel
;   tool box (Book option) = 37 pixels
;   				black border around tool = 1 pixel
;   				clear border around tool = 1 pixel
;				tool itself = 32 pixels
;   				clear border around tool = 1 pixel
;   				black border around tool = 1 pixel
;				clear line at bottom of screen = 1 pixel
;
;  View height with menu, title bar, and tools 
;       = 320 - 13 - 13 - 2 - 2 - 37 = 253 pixels
;
;  View height with title bar and tools but NO menu
;       = 320 - 13 - 2 - 2 - 37 = 266 pixels
;
;  View height with menu but NO title bar and NO tools
;       = 320 - 13 - 2 - 2 = 303 pixels
;
;  View height with NO menu, NO title bar, and  NO tools 
;       = 320 - 2 - 2 = 316 pixels
;
;  We are going to use the view height without the menu, title bar and
;  tools (316 pixels). If Bindery users want NO scrollbars under any 
;  condition on the zoomer, they will need to not use the last 13 pixels 
;  on the content page since the optional menu bar is 13 pixels tall.
;
; Notes on the Desktop size:
; Actual text object width is 428 pixels but we subtract 2 for the left and
; right margins to get 426 pixels.
;
; Notes on the PT9000 size:
; Actual width 640 pixels minus 2 for margins gives 638 pixels.
;
PlatformWidthHeightTable		word \
	0,	0,		; entry for PET_NONE (currently) unused
	0,	0,		; PET_CUSTOM is taken from GenValue
	426,	284,		; PET_DESKTOP (before resizing)
	254,	316,		; PET_ZOOMER without menu bar
	638,	358		; PET_PT9000
.assert ((size PlatformWidthHeightTable) eq (4*PlatformEmulationType))

; Table of heights of toolbar and title
;
ToolbarWidthHeightTable		word \
	0,	0,		; entry for PET_NONE (currently) unused
	0,	0,		; ditto for PET_CUSTOM
	0,	60,		; PET_DESKTOP
	0,	50,		; PET_ZOOMER
	0,	57		; PET_PT9000
.assert ((size ToolbarWidthHeightTable) eq (4*PlatformEmulationType))

StudioDocumentSetPlatform	method dynamic StudioDocumentClass, 
					MSG_STUDIO_DOCUMENT_SET_PLATFORM
		uses	ax, cx, dx, bp
emulationState	local	word		; contains the whole state
emulationType	local	word		; just the low byte, for making offsets
report		local	PageSizeReport
xMargins	local	word
yMargins	local	word
		.enter

CheckHack< (offset PES_PLATFORM) eq 0 >
CheckHack< (width PES_PLATFORM) eq 8 >

		call	LockMapBlockES

	; Save the previous emulation, so we can decide whether or not
	; to save the current width later on; also, update document's
	; instance data to reflect new state
	;
		mov	bl, es:MBH_currentEmulationState.low
					; bl <- previous PlatformEmulationType
		call	GetEmulationState	; ax <- PlatformEmulationState
		mov	es:MBH_currentEmulationState, ax
		mov	emulationState, ax
		mov	emulationType, ax	; this just holds low byte
		and	emulationType, mask PES_PLATFORM
		cmp	al, GIGS_NONE		; none? strange...
		LONG 	je	noChange

	; Warn the user that page name characters may flow onto different
	; pages and give them a chance to bail out.

		mov	ax, offset PlatformEmulationWarnString
		clr	cx
		mov	dx,
		 CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION, 0>
		call	ComplexQuery
		cmp	ax, IC_YES
		LONG	jne	noChange

	; Initialize a PageSizeReport with the current values, then
	; modify the width.  Routine .inherits our locals, and will
	; modify xMargins and yMargins
	;
		call	GetAppPageSizeAndMargins

	; If previous emulation was PET_NONE, save the current width/height
	; so we can restore it when going back to PET_NONE.
	;
		cmp	bl, PET_NONE
		jne	noSave
		mov	bx, report.PSR_width.low
		mov	es:MBH_userSize.XYS_width, bx
		mov	bx, report.PSR_height.low
		mov	es:MBH_userSize.XYS_height, bx

	;
	; Get new width and height into into bx/cx; method used depends on
	; the PlatformEmulationState (in ax).  xMargins and yMargins will
	; be added in to account for margins
	;

	; ... if PET_NONE, take size from document instance data.
	; Note that we don't need have to account for margins, because
	; we just cached the raw page size.  Nor do we care whether or not
	; the "toolbar" box is checked.
	;
noSave:
		mov	ax, emulationState
		cmp	al, PET_NONE		; back to normal?
		jne	tryCustom
		mov	bx, es:MBH_userSize.XYS_width
		mov	cx, es:MBH_userSize.XYS_height
		jmp	changeSize

	; ... if PET_CUSTOM, from Custom{Width,Height}Value.  Also save the
	; values in document instance data so we can update correctly when
	; moving between documents.
	;
tryCustom:
		cmp	al, PET_CUSTOM		; custom value?
		jne	useTable
		call	GetCustomValues		; into bx, cx
		mov	es:MBH_customSize.XYS_width, bx
		mov	es:MBH_customSize.XYS_height, cx
		jmp	addMargins

	; ... otherwise, from the table
	;
useTable:
		push	si
		mov	si, emulationType
		and	si, mask PES_PLATFORM	; low byte contains the enum
		shl	si, 1			; entries are two words each
		shl	si, 1
		mov	bx, cs:[PlatformWidthHeightTable][si]
		mov	cx, cs:[PlatformWidthHeightTable][si][2]
		pop	si

	;
	; If we passed through tryCustom or useTable, see if the "account
	; for toolbar" boolean is checked.  If so, subtract off some space
	; from bx and cx.
	;  --	actually, it seems that custom isn't supposed to respond to
	;	the toolbar box being checked or not, so custom will jump
	;	straight to addMargins.		-- pld 11/4/94
	; 
checkToolbar::
		test	ax, mask PES_TOOLBOX
		jz	addMargins		; nope, not selected
		push	si
		mov	si, emulationType
		shl	si, 1			; entries are two words each
		shl	si, 1
		mov	ax, cs:[ToolbarWidthHeightTable][si]
		sub	bx, ax
		mov	ax, cs:[ToolbarWidthHeightTable][si][2]
		sub	cx, ax
		pop	si

addMargins:
		add	bx, xMargins			; add in margins
		add	cx, yMargins

	; Make it so (and make sure to update the page size control)
	;
changeSize:
		call	VMUnlockES
		clr	ax
		movdw	report.PSR_width, axbx
		movdw	report.PSR_height, axcx
		clr	dx			; don't reset emulation gadget
		push	bp
		lea	bp, report
		call	StudioDocumentReportPageSize
		pop	bp
	;
	; Force the document to recalc hotspots on every page, by setting
	; SDI_currentPage to 0.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		clr	cx
		xchg	cx, ds:[di].SDI_currentPage
		jcxz	done			; if 0, all pages have been 
		push	cx			;  recalc'ed already
		push	di
		mov	cl, 1			; pretend we're deleting a page
						; so that recalc starts from
						; SDI_currentPage
		mov	ax, MSG_STUDIO_DOCUMENT_RECALC_HOTSPOTS
		call	ObjCallInstanceNoLock
		pop	di
		pop	ds:[di].SDI_currentPage	; restore real currentPage
done:
		.leave
		ret

noChange:
		call	VMUnlockES
		jmp	done

StudioDocumentSetPlatform	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEmulationState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get selected booleans from EmulationBooleanGroup, and
		selected item from EmulationItemGroup; combine them
		into a PlatformEmulationState record.

CALLED BY:	StudioDocumentSetPlatform
PASS:		nothing
RETURN:		ax	- PlatformEmulationState
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEmulationState	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter
CheckHack <(segment EmulationBooleanGroup) eq (segment EmulationItemGroup)>

		GetResourceHandleNS	EmulationBooleanGroup, bx
		mov	si, offset EmulationBooleanGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	ObjMessage
EC <	; do any bits spill over?					>
EC <		test	ax, mask PES_PLATFORM				>
EC <		ERROR_NZ STUDIO_INTERNAL_LOGIC_ERROR			>
		push	ax		; save that result

		mov	si, offset EmulationItemGroup
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage
EC <	; do any bits spill over?					>
EC <		cmp	ax, -1						>
EC <		je	guessItsOK					>
EC <		test	ax, not mask PES_PLATFORM			>
EC <		ERROR_NZ STUDIO_INTERNAL_LOGIC_ERROR			>
EC <guessItsOK:							>
		pop	bx
		or	ax, bx
	.leave
	ret
GetEmulationState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCustomValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get values from Custom{Width,Height}Value into bx and cx

CALLED BY:	StudioDocumentSetPlatform
PASS:		nothing
RETURN:		bx	- value from CustomWidthValue
		cx	- value from CustomHeightValue
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCustomValues	proc	near
	uses	ax,dx,si,di,bp
	.enter
		GetResourceHandleNS	CustomWidthValue, bx
		mov	si, offset CustomWidthValue
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage	; dx.cx <- value
		push	dx		; save width
		mov	si, offset CustomHeightValue
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage	; dx.cx <- value
		pop	bx		; bx <- saved width
		mov	cx, dx		; dx <- retrieved height
	.leave
	ret
GetCustomValues	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAppPageSizeAndMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the page size and margin info from the app object

CALLED BY:	INTERNAL
		StudioDocumentSetPlatform
PASS:		nothing (locals inherited)
RETURN:		report	- filled-out PageSizeReport
		xMargins - left + right margin (in points)
		yMargins - top + bottom margin (in points)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Don't bother filling in PSR_margins, since
	StudioDocumentReportPageSize just ignores that field.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAppPageSizeAndMargins	proc	near
	class	StudioApplicationClass
	uses	ds,ax,bx,cx,di
	.enter inherit StudioDocumentSetPlatform

	; Fill in ss:report
	;
		GetResourceHandleNS	StudioApp, bx
		call	MemLock
		mov	ds, ax
		mov	di, ds:StudioApp
		add	di, ds:[di].Gen_offset
		add	di, offset SAI_uiData
		clr	ax
		mov	cx, ds:[di].UIUD_pageSize.XYS_width
		movdw	ss:report.PSR_width, axcx
		mov	cx, ds:[di].UIUD_pageSize.XYS_height
		movdw	ss:report.PSR_height, axcx
		mov	ax, {word} ds:[di].UIUD_pageInfo
		mov	ss:report.PSR_layout, ax

	; Fill in ss:xMargins and yMargins.
	; Note that SAE_*Margin are in points*8.
	;
		mov	ax, ds:[di].UIUD_section.SAE_topMargin
		add	ax, ds:[di].UIUD_section.SAE_bottomMargin
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	yMargins, ax
		mov	ax, ds:[di].UIUD_section.SAE_leftMargin
		add	ax, ds:[di].UIUD_section.SAE_rightMargin
		shr	ax, 1
		shr	ax, 1
		shr	ax, 1
		mov	xMargins, ax
		call	MemUnlock
	.leave
	ret
GetAppPageSizeAndMargins	endp

DocPageSetup ends
