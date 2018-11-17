COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		mainApp.asm

ROUTINES:
	Name			Description
	----			-----------
    INT UpdateUI		Update the given UI objects

    INT SetEnabledIfZ		Update the given UI objects

    INT SetEnabledIfNZ		Update the given UI objects

    INT SendListSetExcl		Update the given UI objects

    INT SendListSetNonExcl	Update the given UI objects

    INT SendValueSetValue	Update the given UI objects

    INT SendValueSetDistance	Update the given UI objects

    INT DN_ObjMessageNoFlags	Update the given UI objects

    INT CheckForUsableMergeScrap 
				Check to see if a usable merge scrap
				exists.

    INT StudioApplicationUpdateSampleCommon 
				Update the text in one of our objects to
				reflect the current date or time in the
				selected format.

METHODS:
	Name			Description
	----			-----------
    StudioApplicationCreateGraphicsFrame  
				Create a graphics frame

				MSG_STUDIO_APPLICATION_CREATE_GRAPHICS_FRAME
				StudioApplicationClass

    StudioApplicationInitSectionList  
				Initialize a list displaying sections

				MSG_STUDIO_APPLICATION_INIT_SECTION_LIST
				StudioApplicationClass

    StudioApplicationInitTextObject  
				Initialize a text object

				MSG_STUDIO_APPLICATION_INIT_TEXT_OBJECT
				StudioApplicationClass

    StudioApplicationUpdateUIForFirstPage  
				Update the UI for the page setup dialog box
				for the user changing the "Follow last
				section" flag

				MSG_STUDIO_APPLICATION_UPDATE_UI_FOR_FIRST_PAGE
				StudioApplicationClass

    StudioApplicationUpdateUIForColumns  
				Update the UI for the page setup dialog box

				MSG_STUDIO_APPLICATION_UPDATE_UI_FOR_COLUMNS
				StudioApplicationClass

    StudioApplicationVisibilityNotification  
				Handle groups becoming visible or not
				visibile

				MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION
				StudioApplicationClass

    StudioApplicationSetDocumentState  
				Set the state of the document (and update
				any objects that are visible)

				MSG_STUDIO_APPLICATION_SET_DOCUMENT_STATE
				StudioApplicationClass

    StudioApplicationClipboardNotifyNormalTransferItemChanged  
				Notice that the clipboard has changed

				MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
				StudioApplicationClass

    StudioApplicationUpdateDateSample  
				Update the displayed sample date to the
				selected format

				MSG_STUDIO_APPLICATION_UPDATE_DATE_SAMPLE
				StudioApplicationClass

    StudioApplicationUpdateTimeSample  
				Update the displayed sample time to the
				selected format

				MSG_STUDIO_APPLICATION_UPDATE_TIME_SAMPLE
				StudioApplicationClass

    StudioApplicationInitializeTimeSample  
				Initialize the InsertTimeSampleText when
				the box first comes up.

				MSG_STUDIO_APPLICATION_INITIALIZE_TIME_SAMPLE
				StudioApplicationClass

    StudioApplicationInitializeDateSample  
				Initialize the InsertDateSampleText when
				the box first comes up.

				MSG_STUDIO_APPLICATION_INITIALIZE_DATE_SAMPLE
				StudioApplicationClass

    StudioApplicationMetaQuit	Never quit.

				MSG_META_QUIT
				StudioApplicationClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for StudioApplicationClass

	$Id: mainApp.asm,v 1.1 97/04/04 14:39:39 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioApplicationClass
idata ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationCreateGraphicsFrame --
		MSG_STUDIO_APPLICATION_CREATE_GRAPHICS_FRAME
					for StudioApplicationClass

DESCRIPTION:	Create a graphics frame

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

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
	Tony	10/22/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationCreateGraphicsFrame	method dynamic	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_CREATE_GRAPHICS_FRAME

	; choose the frame tool

	push	si
	GetResourceHandleNS	StudioHead, bx
	mov	si, offset StudioHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, es
	mov	dx, offset WrapFrameClass
	clr	bp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	; show the graphics tools

	mov	ax, MSG_STUDIO_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE
	call	ObjCallInstanceNoLock

	ret

StudioApplicationCreateGraphicsFrame	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationInitSectionList --
		MSG_STUDIO_APPLICATION_INIT_SECTION_LIST
						for StudioApplicationClass

DESCRIPTION:	Initialize a list displaying sections

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx:dx - GenDynamicList
	bp - non-zero if opening

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
StudioApplicationInitSectionList	method dynamic	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_INIT_SECTION_LIST

	tst	bp
	jz	done

	; pass this on to the model document

	push	si
	mov	ax, MSG_STUDIO_DOCUMENT_INIT_SECTION_LIST
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	cx, di
	mov	dx, TO_MODEL
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	call	ObjCallInstanceNoLock
done:
	ret

StudioApplicationInitSectionList	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationInitTextObject --
		MSG_STUDIO_APPLICATION_INIT_TEXT_OBJECT for StudioApplicationClass

DESCRIPTION:	Initialize a text object

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx:dx - text object
	bp - non-zero if opening

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
StudioApplicationInitTextObject	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_INIT_TEXT_OBJECT

	tst	bp
	jz	done
	movdw	bxsi, cxdx
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	clr	di
	call	ObjMessage
done:
	ret

StudioApplicationInitTextObject	endm

DocSTUFF ends

DocPageSetup segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationUpdateUIForFirstPage --
		MSG_STUDIO_APPLICATION_UPDATE_UI_FOR_FIRST_PAGE
					for StudioApplicationClass

DESCRIPTION:	Update the UI for the page setup dialog box for the user
		changing the "Follow last section" flag

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - booleans selected
	dx - booleans indeterminate
	bp - booleans changed

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationUpdateUIForFirstPage	method dynamic	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_UPDATE_UI_FOR_FIRST_PAGE

	mov	ax, MSG_GEN_SET_ENABLED
	test	cx, mask SF_PAGE_NUMBER_FOLLOWS_LAST_SECTION
	jz	gotMessage
	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotMessage:

	mov	dl, VUM_NOW
	GetResourceHandleNS	LayoutFirstPageValue, bx
	mov	si, offset LayoutFirstPageValue
	clr	di
	call	ObjMessage

	ret

StudioApplicationUpdateUIForFirstPage	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationUpdateUIForColumns --
		MSG_STUDIO_APPLICATION_UPDATE_UI_FOR_COLUMNS
					for StudioApplicationClass

DESCRIPTION:	Update the UI for the page setup dialog box

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	dx - number of columns

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 1/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationUpdateUIForColumns	method dynamic	StudioApplicationClass,
				MSG_STUDIO_APPLICATION_UPDATE_UI_FOR_COLUMNS

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	dx, 1
	jnz	gotMessage
	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotMessage:

	mov	dl, VUM_NOW
	GetResourceHandleNS	LayoutColumnSpacingDistance, bx
	mov	si, offset LayoutColumnSpacingDistance
	call	objMessageNoFlags
	mov	si, offset LayoutColumnRuleWidthDistance
	call	objMessageNoFlags

	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	objMessageNoFlags

	ret

objMessageNoFlags:
	clr	di
	call	ObjMessage
	retn

StudioApplicationUpdateUIForColumns	endm

DocPageSetup ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationVisibilityNotification --
		MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION for StudioApplicationClass

DESCRIPTION:	Handle groups becoming visible or not visibile

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx - GroupsVisible
	dx - no data (for now :)
	bp - non-zero if group opening

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/27/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationVisibilityNotification	method dynamic	StudioApplicationClass,
					MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION

	tst	bp
	jz	closing

	; group is opening

	or	ds:[di].SAI_visibility, cx
	mov_tr	ax, cx				;ax = group to update
	mov	cx, mask NotifyFlags
	call	UpdateUI
	ret

closing:
	not	cx
	and	ds:[di].SAI_visibility, cx
	ret

StudioApplicationVisibilityNotification	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioApplicationSetDocumentState --
		MSG_STUDIO_APPLICATION_SET_DOCUMENT_STATE
						for StudioApplicationClass

DESCRIPTION:	Set the state of the document (and update any objects that
		are visible)

PASS:
	*ds:si - instance data
	es - segment of StudioApplicationClass

	ax - The message

	cx:dx - UIUpdateData
	bp - NotifyFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/27/92		Initial version

------------------------------------------------------------------------------@
StudioApplicationSetDocumentState	method dynamic	StudioApplicationClass,
					MSG_STUDIO_APPLICATION_SET_DOCUMENT_STATE

	mov	ax, ds:[di].SAI_visibility

	; If the document state has changed then copy it in

	push	si, ds
	segmov	es, ds
	add	di, offset SAI_uiData		;es:di = dest
	movdw	dssi, cxdx			;ds:si = source
	mov	cx, size UIUpdateData
	push	cx, si, di
	repe	cmpsb
	pop	cx, si, di
	jnz	dataChanged

	; no change -- exit

	pop	si, ds
	ret

dataChanged:
	rep	movsb				;store new data
	pop	si, ds

	mov	cx, bp				;cx = NotifyFlags
	call	UpdateUI
	ret

StudioApplicationSetDocumentState	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateUI

DESCRIPTION:	Update the given UI objects

CALLED BY:	INTERNAL

PASS:
	*ds:si - write application object
	ax - mask of objects that are visible and thus are candidates for
	     being updated (GroupsVisible)
	cx - mask of things to update (NotifyFlags)

RETURN:
	none

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	This is a guide to the various labels.
	
		if NF_PAGE
		    if GV_DELETE_PAGE, update DeletePageTrigger
afterDeletePage:

afterPage:	if NF_TOTAL_PAGES
		    if GV_PRINT, update StudioPrintControl
afterPrint:

fterTotalPages:	if NF_SECTION
		    if GV_PRINT, update StudioPrintControl
afterPrint2:	    if GV_PAGE_SETUP, update page setup control
afterPageSetup:	    if GV_SECTION_MENU, update delete section trigger
afterDeleteSection: if GV_TITLE_PAGE_MENU, update title page stuff
afterTitlePage:

afterSection:	if NF_SECTION or NF_PAGE_SIZE
		    if GV_PLATFORM_EMULATION, update platform gadget
afterPlatform:	    if GV_PAGE_SIZE update, page size control
afterPageSize:

afterSectionOrSize:
		if NF_DOCUMENT
		    update toolbar and view control
		    if GV_SET_FIRST_SECTION, update first section dialog
terSetFirstSection: if GV_DISPLAY_MODE, update display mode list

afterDocument:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/27/92		Initial version

------------------------------------------------------------------------------@
UpdateUI	proc	near
	mov	bx, ds:[LMBH_handle]

visibility	local	GroupsVisible	\
		push	ax
notifications	local	NotifyFlags	\
		push	cx
obj		local	optr		\
		push	bx, si
	.enter
	class	StudioApplicationClass

	;*********************************************************
	;	Update page related things
	;*********************************************************

	test	notifications, mask NF_PAGE
	jz	afterPage

	;--------------------------------------
	; Update "Delete Page"
	;--------------------------------------

	test	visibility, mask GV_DELETE_PAGE
	jz	afterDeletePage

	call	derefData				;ds:di = data
	GetResourceHandleNS	DeletePageTrigger, bx
	mov	si, offset DeletePageTrigger
	cmp	ds:[di].UIUD_totalPages, 1	;if one page then can't delete
	call	SetEnabledIfNZ
afterDeletePage:

afterPage:

	;*********************************************************
	;	Update total # of page related things
	;*********************************************************

	test	notifications, mask NF_TOTAL_PAGES
	jz	afterTotalPages

	;--------------------------------------
	; Update the print control
	;--------------------------------------

	test	visibility, mask GV_PRINT
	jz	afterPrint

	call	derefData
	GetResourceHandleNS	StudioPrintControl, bx
	mov	si, offset StudioPrintControl
	mov	cx, ds:[di].UIUD_section.SAE_startingPageNum
	mov	dx, ds:[di].UIUD_totalPages
	add	dx, cx
	dec	dx
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	call	DN_ObjMessageNoFlags
afterPrint:

afterTotalPages:

	;*********************************************************
	;	Update current section related things
	;*********************************************************

	test	notifications, mask NF_SECTION
	LONG jz	afterSection

	;--------------------------------------
	; Update the print control
	;--------------------------------------

	test	visibility, mask GV_PRINT
	jz	afterPrint2

	call	derefData
	GetResourceHandleNS	StudioPrintControl, bx
	mov	si, offset StudioPrintControl
	mov	cx, ds:[di].UIUD_pageSize.XYS_width
	mov	dx, ds:[di].UIUD_pageSize.XYS_height
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
	call	DN_ObjMessageNoFlags
afterPrint2:

	;--------------------------------------
	; Update the page setup control
	;--------------------------------------

	test	visibility, mask GV_PAGE_SETUP
	LONG jz	afterPageSetup

	call	derefData
	GetResourceHandleNS	LayoutFirstBooleanGroup, bx
	mov	si, offset LayoutFirstBooleanGroup
	mov	cx, ds:[di].UIUD_section.SAE_flags
	push	ds:[di].UIUD_currentSection
	and	cx, mask SF_PAGE_NUMBER_FOLLOWS_LAST_SECTION
	call	SendListSetNonExcl
	pop	cx
	tst	cx
	call	SetEnabledIfNZ

	call	derefData
	mov	si, offset LayoutFirstPageValue
	push	ds:[di].UIUD_section.SAE_flags
	mov	cx, ds:[di].UIUD_section.SAE_startingPageNum
	call	SendValueSetValue
	pop	cx
	test	cx, mask SF_PAGE_NUMBER_FOLLOWS_LAST_SECTION
	call	SetEnabledIfZ

	call	derefData
	mov	cx, ds:[di].UIUD_section.SAE_numColumns
	mov	si, offset LayoutColumnsValue
	call	SendValueSetValue
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	dec	cx
	jcxz	oneColumn
	mov	ax, MSG_GEN_SET_ENABLED
oneColumn:
	mov	dl, VUM_NOW
	mov	si, offset LayoutColumnSpacingDistance
	call	DN_ObjMessageNoFlags
	mov	si, offset LayoutColumnRuleWidthDistance
	call	DN_ObjMessageNoFlags

	call	derefData
	mov	cx, ds:[di].UIUD_section.SAE_columnSpacing
	mov	si, offset LayoutColumnSpacingDistance
	call	SendValueSetDistance
	call	derefData
	mov	si, offset LayoutColumnRuleWidthDistance
	mov	cx, ds:[di].UIUD_section.SAE_ruleWidth
	call	SendValueSetDistance

	call	derefData
	clr	cx
	cmp	ds:[di].UIUD_section.SAE_numMasterPages, 1
	jz	gotAlternate
	inc	cx
gotAlternate:
	mov	si, offset LayoutMasterPageList
	call	SendListSetExcl

	call	derefData
	mov	cx, ds:[di].UIUD_section.SAE_leftMargin
	mov	si, offset LayoutMarginLeftDistance
	call	SendValueSetDistance
	call	derefData
	mov	cx, ds:[di].UIUD_section.SAE_topMargin
	mov	si, offset LayoutMarginTopDistance
	call	SendValueSetDistance
	call	derefData
	mov	cx, ds:[di].UIUD_section.SAE_rightMargin
	mov	si, offset LayoutMarginRightDistance
	call	SendValueSetDistance
	call	derefData
	mov	cx, ds:[di].UIUD_section.SAE_bottomMargin
	mov	si, offset LayoutMarginBottomDistance
	call	SendValueSetDistance

	call	derefData
	push	bp
	mov	dx, ds
	lea	bp, ds:[di].UIUD_sectionName		;dx:bp = name
	clr	cx					;null terminated
	mov	si, offset LayoutSectionNameText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	DN_ObjMessageNoFlags
	pop	bp

afterPageSetup:
	;--------------------------------------
	; Update the delete section group (trigger)
	;--------------------------------------

	test	visibility, mask GV_SECTION_MENU
	jz	afterDeleteSection

	call	derefData
	GetResourceHandleNS	DeleteSectionDialog, bx
	mov	si, offset DeleteSectionDialog
	cmp	ds:[di].UIUD_totalSections, 1
	call	SetEnabledIfNZ
afterDeleteSection:

	;--------------------------------------
	; Update the title page stuff
	;--------------------------------------

	test	visibility, mask GV_TITLE_PAGE_MENU
	jz	afterTitlePage

	call	derefData
	GetResourceHandleNS	CreateTitlePageTrigger, bx
	mov	si, offset CreateTitlePageTrigger
	test	ds:[di].UIUD_flags, mask UIUF_TITLE_PAGE_EXISTS
	pushf
	call	SetEnabledIfZ
	popf
	pushf
	mov	si, offset GotoTitlePageTrigger
	call	SetEnabledIfNZ
	popf
	mov	si, offset DeleteTitlePageTrigger
	call	SetEnabledIfNZ
afterTitlePage:

afterSection:

	;*********************************************************
	;	Update things related to section or page size
	;*********************************************************

	test	notifications, mask NF_SECTION or mask NF_PAGE_SIZE
	LONG jz	afterSectionOrSize

	;--------------------------------------
	; Update the items in platform emulation dialog
	;--------------------------------------

	test	visibility, mask GV_PLATFORM_EMULATION
	jz	afterPlatform

	; Update emulation item group, enable/disable the GenValues
	; and GenBooleanGroup
	;
	call	derefData
	push	bp
	GetResourceHandleNS	EmulationItemGroup, bx
	mov	si, offset EmulationItemGroup
	mov	cx, ds:[di].UIUD_currentEmulationState
	and	cx, mask PES_PLATFORM	; just want the ItemGroup bits...
		CheckHack <(offset PES_PLATFORM) eq 0>
	clr	dx			; not indeterminate
	call	SendListSetExcl		; kills bp,cx
	clr	cx			; don't care about GIGSF_MODIFIED
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
					; enable/disable the GenValues and
					; GenBooleanGroup
	call	DN_ObjMessageNoFlags

	; Update the GenValues
	;
	mov	bp, sp			; restore bp
	mov	bp, ss:[bp]		; faster than pop/push
	call	derefData
	mov	si, offset CustomWidthValue
	mov	cx, ds:[di].UIUD_customSize.XYS_width
	push	ds:[di].UIUD_customSize.XYS_height	; save for later
	call	SendValueSetValue
	mov	si, offset CustomHeightValue
	pop	cx
	call	SendValueSetValue

	; Update the GenBooleanGroup
	;
	mov	bp, sp			; restore bp
	mov	bp, ss:[bp]		; faster than pop/push
	call	derefData
	mov	si, offset EmulationBooleanGroup
	mov	cx, ds:[di].UIUD_currentEmulationState
	and	cx, not mask PES_PLATFORM ; just want the BooleanGroup bits...
	clr	dx			; none indeterminate
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	DN_ObjMessageNoFlags
	pop	bp

afterPlatform:

	;--------------------------------------
	; Update the page size control
	;--------------------------------------

	test	visibility, mask GV_PAGE_SIZE
	jz	afterPageSize
;;;
;;; StudioPageSizeControl removed, so this is unnecessary
;;;		-- dubois 8/11/94
if 0
	call	derefData
	push	bp
	GetResourceHandleNS	StudioPageSizeControl, bx
	mov	si, offset StudioPageSizeControl
	sub	sp, size PageSizeReport
	mov	dx, ss
	mov	bp, sp				; PageSizeReport => DX:BP
	clr	ax
	mov	cx, ds:[di].UIUD_pageSize.XYS_width
	movdw	ss:[bp].PSR_width, axcx
	mov	cx, ds:[di].UIUD_pageSize.XYS_height
	movdw	ss:[bp].PSR_height, axcx
	mov	ax, {word} ds:[di].UIUD_pageInfo
	mov	ss:[bp].PSR_layout, ax
	mov	ax, MSG_PZC_SET_PAGE_SIZE
	call	DN_ObjMessageNoFlags
	add	sp, size PageSizeReport		; clean up stack frame
	pop	bp
endif
afterPageSize:

afterSectionOrSize:

	;*********************************************************
	;	Update the per-document stuff
	;*********************************************************

	test	notifications, mask NF_DOCUMENT
	jz	afterDocument

	;--------------------------------------
	; Update Graphic Toolbar
	;--------------------------------------

	; if we are editing the document and we are not in page mode then
	; make the graphic tools disabled

	call	derefData
	GetResourceHandleNS	GrObjDrawingTools, bx
	mov	si, offset GrObjDrawingTools
	cmp	ds:[di].UIUD_displayMode, VLTDM_PAGE
	jz	gotGrToolStatus
	test	ds:[di].UIUD_flags, mask UIUF_DOCUMENT_IS_TARGET
gotGrToolStatus:
	pushf
	call	SetEnabledIfZ
	popf
		CheckHack <(seg GrObjDrawingTools) eq (seg GrObjBitmapTools)>
	mov	si, offset GrObjBitmapTools
	call	SetEnabledIfZ

	;--------------------------------------
	; Update View Control
	;--------------------------------------

	call	derefData
	GetResourceHandleNS	ViewControlGroup, bx
	mov	si, offset ViewControlGroup
	cmp	ds:[di].UIUD_displayMode, VLTDM_DRAFT_WITHOUT_STYLES
	call	SetEnabledIfNZ

	;--------------------------------------
	; Update "Set First Section" dialog
	;--------------------------------------

	test	visibility, mask GV_SET_FIRST_SECTION
	jz	afterSetFirstSection

	call	derefData
	GetResourceHandleNS	SetFirstSectionValue, bx
	mov	si, offset SetFirstSectionValue
	mov	cx, ds:[di].UIUD_startingSectionNum
	call	SendValueSetValue
afterSetFirstSection:

	;--------------------------------------
	; Update "Display Mode" list
	;--------------------------------------

	test	visibility, mask GV_DISPLAY_MODE
	jz	afterDisplayMode

	call	derefData
	GetResourceHandleNS	ViewTypeList, bx
	mov	si, offset ViewTypeList
	mov	cx, ds:[di].UIUD_displayMode
	call	SendListSetExcl
afterDisplayMode:

afterDocument:

	.leave
	ret

;---

derefData:
	push	bx
	movdw	bxdi, obj
	call	MemDerefDS
	mov	di, ds:[di]
	add	di, ds:[di].Gen_offset
	add	di, offset SAI_uiData			;ds:di = data
	pop	bx
	retn

UpdateUI	endp

;------------

SetEnabledIfZ	proc	near
	lahf
	xor	ah, mask CPU_ZERO
	sahf
	FALL_THRU	SetEnabledIfNZ
SetEnabledIfZ	endp

SetEnabledIfNZ	proc	near
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jz	gotDelete
	mov	ax, MSG_GEN_SET_ENABLED
gotDelete:
	mov	dl, VUM_NOW
	GOTO	DN_ObjMessageNoFlags
SetEnabledIfNZ	endp

;------------

	; cx = value

SendListSetExcl	proc	near	uses	ax, dx
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	DN_ObjMessageNoFlags

	.leave
	ret

SendListSetExcl	endp

;------------

	; cx = value

SendListSetNonExcl	proc	near	uses	ax, dx
	.enter

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	call	DN_ObjMessageNoFlags

	.leave
	ret

SendListSetNonExcl	endp

;---

SendValueSetValue	proc	near	uses ax, bp
	.enter

	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp				;not indeterminate
	call	DN_ObjMessageNoFlags

	.leave
	ret

SendValueSetValue	endp

;---

SendValueSetDistance	proc	near	uses ax, cx, dx, bp
	.enter

	mov	dx, cx
	clr	cx
	shr	dx
	rcr	cx
	shr	dx
	rcr	cx
	shr	dx
	rcr	cx

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	bp				;not indeterminate
	call	DN_ObjMessageNoFlags

	.leave
	ret

SendValueSetDistance	endp

;---

DN_ObjMessageNoFlags	proc	near	uses di
	.enter
	clr	di
	call	ObjMessage
	.leave
	ret
DN_ObjMessageNoFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationClipboardNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notice that the clipboard has changed

CALLED BY:	via MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
PASS:		*ds:si	= Instance
		es	= segment of class structure (dgroup)
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationClipboardNotifyNormalTransferItemChanged	method dynamic \
			StudioApplicationClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	;
	; All the entries are in the same block. We get it now.
	;
	GetResourceHandleNS	MergeOneEntry, bx

	call	CheckForUsableMergeScrap
	jc	noScrap				; Branch if it wasn't right

	;
	; We want to enable this UI.
	;
	mov	si, offset MergeOneEntry
	call	enableItemNow
 	mov	si, offset MergeAllEntry
 	call	enableItemNow

quit:
	ret

noScrap::
	;
	; There is no scrap, we want to disable this UI and set the selection
	; to be MT_NONE.
	;
	mov	cx, MT_NONE
	clr	dx

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	si, offset MergeList
	mov	di, mask MF_CALL
	call	ObjMessage

	mov	si, offset MergeOneEntry
	call	disableItemNow
	mov	si, offset MergeAllEntry
	call	disableItemNow

	jmp	quit


;--------------------

disableItemNow	label	near
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jmp	doSomethingNow

enableItemNow	label	near
	mov	ax, MSG_GEN_SET_ENABLED

doSomethingNow:
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage
	retn

StudioApplicationClipboardNotifyNormalTransferItemChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForUsableMergeScrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a usable merge scrap exists.

CALLED BY:	StudioApplicationClipboardNotifyNormalTransferItemChanged
PASS:		es	= dgroup
RETURN:		carry set if such a scrap exists.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForUsableMergeScrap	proc	near
	uses	ax, bx, cx, dx, bp
	.enter

	clr	bp				; Just for pasting
	call	ClipboardQueryItem		; bx:ax <- header block
						; bp <- format count
	tst	bp				; any item?
	stc					; assume not
	jz	done				; done if assumption correct

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_SPREADSHEET
	call	ClipboardTestItemFormat		; bx:ax <- ClipboardItemHeader
						; cx:dx fmt manuf, fmt type
						; sets carry correctly
done:
	pushf
	call	ClipboardDoneWithItem
	popf

	.leave
	ret
CheckForUsableMergeScrap	endp

DocNotify ends

DocMiscFeatures	segment 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationUpdateDateSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the displayed sample date to the selected format

CALLED BY:	MSG_STUDIO_APPLICATION_UPDATE_DATE_SAMPLE
PASS:		*ds:si	= StudioApplication object
		cx	= DateTimeFormat to use
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationUpdateDateSample method StudioApplicationClass, 
				MSG_STUDIO_APPLICATION_UPDATE_DATE_SAMPLE
	.enter
	GetResourceHandleNS InsertDateSampleText, bx
	mov	si, offset InsertDateSampleText
	call	StudioApplicationUpdateSampleCommon
	.leave
	ret
StudioApplicationUpdateDateSample endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationUptimeTimeSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the displayed sample time to the selected format

CALLED BY:	MSG_STUDIO_APPLICATION_UPDATE_TIME_SAMPLE
PASS:		*ds:si	= StudioApplication object
		cx	= DateTimeFormat to use
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Time		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationUpdateTimeSample method StudioApplicationClass, 
				MSG_STUDIO_APPLICATION_UPDATE_TIME_SAMPLE
	.enter
	GetResourceHandleNS InsertTimeSampleText, bx
	mov	si, offset InsertTimeSampleText
	call	StudioApplicationUpdateSampleCommon
	.leave
	ret
StudioApplicationUpdateTimeSample endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationUpdateSampleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the text in one of our objects to reflect the
		current date or time in the selected format.

CALLED BY:	(INTERNAL) StudioApplicationUpdateTimeSample,
			   StudioApplicationUpdateDateSample
PASS:		^lbx:si	= object to update
		cx	= DateTimeFormat to use
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationUpdateSampleCommon proc	near
buffer	local	DATE_TIME_BUFFER_SIZE dup(char)
	.enter
	push	bx, si
	mov	si, cx			; si <- format enum
	segmov	es, ss
	lea	di, ss:[buffer]		; es:di <- buffer into which to format
	call	TimerGetDateAndTime	; fetch current time

	call	LocalFormatDateTime	; and format it (cx <- # chars w/o null)

	pop	bx, si			; ^lbx:si <- target text object
	mov	dx, es
	push	bp
	lea	bp, ss:[buffer]		; dx:bp <- buffer
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp
	.leave
	ret
StudioApplicationUpdateSampleCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationInitializeTimeSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the InsertTimeSampleText when the box first
		comes up.

CALLED BY:	MSG_STUDIO_APPLICATION_INITIALIZE_TIME_SAMPLE
PASS:		*ds:si	= StudioApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationInitializeTimeSample method dynamic StudioApplicationClass, 
				MSG_STUDIO_APPLICATION_INITIALIZE_TIME_SAMPLE
	GetResourceHandleNS	TimeFormatList, bx
	mov	si, offset TimeFormatList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax <- format
	mov_tr	cx, ax
	GOTO	StudioApplicationUpdateTimeSample
StudioApplicationInitializeTimeSample endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioApplicationInitializeDateSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the InsertDateSampleText when the box first
		comes up.

CALLED BY:	MSG_STUDIO_APPLICATION_INITIALIZE_DATE_SAMPLE
PASS:		*ds:si	= StudioApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioApplicationInitializeDateSample method dynamic StudioApplicationClass, 
				MSG_STUDIO_APPLICATION_INITIALIZE_DATE_SAMPLE
	GetResourceHandleNS	DateFormatList, bx
	mov	si, offset DateFormatList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax <- format
	mov_tr	cx, ax
	GOTO	StudioApplicationUpdateDateSample
StudioApplicationInitializeDateSample endm

DocMiscFeatures ends
