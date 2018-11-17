COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		mainApp.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for WriteApplicationClass

	$Id: mainApp.asm,v 1.2 98/02/17 03:35:41 gene Exp $

------------------------------------------------------------------------------@

GeoWriteClassStructures	segment	resource
	WriteApplicationClass
GeoWriteClassStructures	ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationCreateGraphicsFrame --
		MSG_WRITE_APPLICATION_CREATE_GRAPHICS_FRAME
					for WriteApplicationClass

DESCRIPTION:	Create a graphics frame

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
WriteApplicationCreateGraphicsFrame	method dynamic	WriteApplicationClass,
				MSG_WRITE_APPLICATION_CREATE_GRAPHICS_FRAME

	; choose the frame tool

	push	si
	GetResourceHandleNS	WriteHead, bx
	mov	si, offset WriteHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, es
	mov	dx, offset WrapFrameClass
	clr	bp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	; show the graphics tools

	mov	ax, MSG_WRITE_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE
	call	ObjCallInstanceNoLock

	ret

WriteApplicationCreateGraphicsFrame	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationInitSectionList --
		MSG_WRITE_APPLICATION_INIT_SECTION_LIST
						for WriteApplicationClass

DESCRIPTION:	Initialize a list displaying sections

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
WriteApplicationInitSectionList	method dynamic	WriteApplicationClass,
				MSG_WRITE_APPLICATION_INIT_SECTION_LIST

	tst	bp
	jz	done

	; pass this on to the model document

	push	si
	mov	ax, MSG_WRITE_DOCUMENT_INIT_SECTION_LIST
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

WriteApplicationInitSectionList	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationInitTextObject --
		MSG_WRITE_APPLICATION_INIT_TEXT_OBJECT for WriteApplicationClass

DESCRIPTION:	Initialize a text object

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
WriteApplicationInitTextObject	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_INIT_TEXT_OBJECT

	tst	bp
	jz	done
	movdw	bxsi, cxdx
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	clr	di
	call	ObjMessage
done:
	ret

WriteApplicationInitTextObject	endm

DocSTUFF ends

DocPageSetup segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationUpdateUIForFirstPage --
		MSG_WRITE_APPLICATION_UPDATE_UI_FOR_FIRST_PAGE
					for WriteApplicationClass

DESCRIPTION:	Update the UI for the page setup dialog box for the user
		changing the "Follow last section" flag

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
if _SECTION_SUPPORT
WriteApplicationUpdateUIForFirstPage	method dynamic	WriteApplicationClass,
				MSG_WRITE_APPLICATION_UPDATE_UI_FOR_FIRST_PAGE

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

WriteApplicationUpdateUIForFirstPage	endm
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationUpdateUIForColumns --
		MSG_WRITE_APPLICATION_UPDATE_UI_FOR_COLUMNS
					for WriteApplicationClass

DESCRIPTION:	Update the UI for the page setup dialog box

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
WriteApplicationUpdateUIForColumns	method dynamic	WriteApplicationClass,
				MSG_WRITE_APPLICATION_UPDATE_UI_FOR_COLUMNS

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

WriteApplicationUpdateUIForColumns	endm

DocPageSetup ends

DocNotify segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationVisibilityNotification --
		MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION for WriteApplicationClass

DESCRIPTION:	Handle groups becoming visible or not visibile

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
WriteApplicationVisibilityNotification	method dynamic	WriteApplicationClass,
					MSG_GEN_APPLICATION_VISIBILITY_NOTIFICATION

	tst	bp
	jz	closing

	; group is opening

	or	ds:[di].WAI_visibility, cx
	mov_tr	ax, cx				;ax = group to update
	mov	cx, mask NotifyFlags
	call	UpdateUI
	ret

closing:
	not	cx
	and	ds:[di].WAI_visibility, cx
	ret

WriteApplicationVisibilityNotification	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationSetDocumentState --
		MSG_WRITE_APPLICATION_SET_DOCUMENT_STATE
						for WriteApplicationClass

DESCRIPTION:	Set the state of the document (and update any objects that
		are visible)

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
WriteApplicationSetDocumentState	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_SET_DOCUMENT_STATE

	mov	ax, ds:[di].WAI_visibility

	; If the document state has changed then copy it in

	push	si, ds
	segmov	es, ds
	add	di, offset WAI_uiData		;es:di = dest
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

WriteApplicationSetDocumentState	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateUI

DESCRIPTION:	Update the gicen UI objects

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
	class	WriteApplicationClass

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
	cmp	ds:[di].UIUD_section.SAE_numPages, 1
				;if one page in section then can't delete
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
	GetResourceHandleNS	WritePrintControl, bx
	mov	si, offset WritePrintControl
	mov	cx, ds:[di].UIUD_startingPageNum
	mov	dx, ds:[di].UIUD_totalPages
	add	dx, cx
	dec	dx
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
if LIMITED_FAX_SUPPORT
	push	ax, cx, dx
	call	DN_ObjMessageNoFlags
	pop	ax, cx, dx
	mov	si, offset WriteFaxPrintControl
endif
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
	GetResourceHandleNS	WritePrintControl, bx
	mov	si, offset WritePrintControl
	mov	cx, ds:[di].UIUD_pageSize.XYS_width
	mov	dx, ds:[di].UIUD_pageSize.XYS_height
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_SIZE
if LIMITED_FAX_SUPPORT
	push	ax, cx, dx
	call	DN_ObjMessageNoFlags
	pop	ax, cx, dx
	mov	si, offset WriteFaxPrintControl
endif
	call	DN_ObjMessageNoFlags
afterPrint2:

	;--------------------------------------
	; Update the page setup control
	;--------------------------------------

	test	visibility, mask GV_PAGE_SETUP
	LONG jz	afterPageSetup

	GetResourceHandleNS	LayoutFirstBooleanGroup, bx

if _SECTION_SUPPORT
	call	derefData
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

elseif _ALLOW_STARTING_PAGE
	;
	; If have a title page, so update the First Page spinner
	;
	call	derefData
	test	ds:[di].UIUD_updateFlags, mask UIUF_TITLE_PAGE_EXISTS
	jnz	haveTitlePage			; if next section
	test	ds:[di].UIUD_flags, mask UIUF_TITLE_PAGE_EXISTS
	jz	noTitlePage			; if curr section

haveTitlePage:
	;
	; Compare the name of the section.
	;
	push	es, di, bx, cx			; temp registers
	lea	si, ds:[di].UIUD_sectionName	; ds:si - curr section name
	mov	bx, handle TitlePageSectionName
	call	MemLock
	mov_tr	es, ax
	mov	di, offset TitlePageSectionName	
	mov	di, es:[di]			; es:di - "Title Page"
	push	di				; ptr to "Title Page"
	LocalStrLength				; cx - length of "Title Page"
	pop	di				; ptr to "Title Page"
	call	LocalCmpStrings
	pop	es, di, bx, cx			; temp registers
	je	haveZF				; jmp if titled page

	mov	si, offset LayoutFirstPageValue
	call	derefData
	mov	cx, ds:[di].UIUD_section.SAE_startingPageNum
	call	SendValueSetValue

noTitlePage:
	or	sp, sp				; clear ZF

haveZF:
	mov	si, offset LayoutFirstPageValue
	call	SetEnabledIfNZ
endif

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

if _LABELS
	; update the minmum margin values

	call	derefData
	mov	cx, ds:[di].UIUD_pageInfo
	and	cx, mask PLP_TYPE
	cmp	cx, PT_LABEL
	mov	di, offset minimumNormalMargins
	jne	resetMarginMinimums
	mov	di, offset minimumLabelMargins
resetMarginMinimums:
	mov	si, offset LayoutMarginLeftDistance
	call	SendValueSetMinimum
	mov	si, offset LayoutMarginTopDistance
	call	SendValueSetMinimum
	mov	si, offset LayoutMarginRightDistance
	call	SendValueSetMinimum
	mov	si, offset LayoutMarginBottomDistance
	call	SendValueSetMinimum
endif

	; update the actual margin values

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

	test	visibility, mask GV_PAGE_SIZE
	jz	afterPageSize

	call	derefData
	push	bp
	GetResourceHandleNS	WritePageSizeControl, bx
	mov	si, offset WritePageSizeControl
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
afterPageSize:

	;--------------------------------------
	; Update the delete section group (trigger)
	;--------------------------------------

if _SECTION_SUPPORT
	test	visibility, mask GV_SECTION_MENU
	jz	afterDeleteSection

	call	derefData
	GetResourceHandleNS	DeleteSectionDialog, bx
	mov	si, offset DeleteSectionDialog
	cmp	ds:[di].UIUD_totalSections, 1
	call	SetEnabledIfNZ
afterDeleteSection:
endif

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
if _BITMAP_EDITING
	GetResourceHandleNS	GrObjBitmapTools, bx
	popf
	mov	si, offset GrObjBitmapTools
	call	SetEnabledIfZ
else
	popf
endif

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

if _SECTION_SUPPORT
	test	visibility, mask GV_SET_FIRST_SECTION
	jz	afterSetFirstSection

	call	derefData
	GetResourceHandleNS	SetFirstSectionValue, bx
	mov	si, offset SetFirstSectionValue
	mov	cx, ds:[di].UIUD_startingSectionNum
	call	SendValueSetValue
afterSetFirstSection:
endif

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
	add	di, offset WAI_uiData			;ds:di = data
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

if _SECTION_SUPPORT
SendListSetNonExcl	proc	near	uses	ax, dx
	.enter

	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	call	DN_ObjMessageNoFlags

	.leave
	ret

SendListSetNonExcl	endp
endif

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

if _LABELS
; Resets the minmum value of a GenValue object
; Pass:		bx:si	= GenValue object
;		cs:di	= Minimum integer value
; Returns:	di	= di + 2
; Destroys:	ax, cx

SendValueSetMinimum	proc	near
	push	di
	mov	ax, MSG_GEN_VALUE_SET_MINIMUM
	mov	dx, cs:[di]			; get minimum integer value
	clr	cx				; clear fractional value
	call	DN_ObjMessageNoFlags
	pop	di
	add	di, (size word)			; go to next margin value
	ret
SendValueSetMinimum	endp
endif

;---

DN_ObjMessageNoFlags	proc	near	uses di
	.enter
	clr	di
	call	ObjMessage
	.leave
	ret
DN_ObjMessageNoFlags	endp

if _LABELS
if _DWP
minimumNormalMargins	word	\
			(MINIMUM_LEFT_MARGIN_SIZE/8),
			(MINIMUM_TOP_MARGIN_SIZE/8),
			(MINIMUM_RIGHT_MARGIN_SIZE/8),
			(MINIMUM_BOTTOM_MARGIN_SIZE/8)
else
minimumNormalMargins	word	\
			(MINIMUM_MARGIN_SIZE/8),
			(MINIMUM_MARGIN_SIZE/8),
			(MINIMUM_MARGIN_SIZE/8),
			(MINIMUM_MARGIN_SIZE/8)
endif
minimumLabelMargins	word	\
			(MINIMUM_LABEL_MARGIN_SIZE/8),
			(MINIMUM_LABEL_MARGIN_SIZE/8),
			(MINIMUM_LABEL_MARGIN_SIZE/8),
			(MINIMUM_LABEL_MARGIN_SIZE/8)
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteApplicationClipboardNotifyNormalTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notice that the clipboard has changed

CALLED BY:	via MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
PASS:		*ds:si	= Instance
		es	= segment of class structure
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteApplicationClipboardNotifyNormalTransferItemChanged	method dynamic \
			WriteApplicationClass,
			MSG_META_CLIPBOARD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
	;
	; All the entries are in the same block. We get it now.
	;
ifdef _VS150
	GetResourceHandleNS	MergeOn, bx
else
	GetResourceHandleNS	MergeOneEntry, bx
endif

	call	CheckForUsableMergeScrap
	jc	noScrap				; Branch if it wasn't right

	;
	; We want to enable this UI.
	;
ifdef _VS150
	mov	si, offset MergeOn
	call	enableItemNow
else
	mov	si, offset MergeOneEntry
	call	enableItemNow
 	mov	si, offset MergeAllEntry
 	call	enableItemNow
endif

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
ifdef _VS150
	mov	si, offset MergeOnOff
else
	mov	si, offset MergeList
endif
	mov	di, mask MF_CALL
	call	ObjMessage

ifdef _VS150
	mov	si, offset MergeOn
	call	disableItemNow
else
	mov	si, offset MergeOneEntry
	call	disableItemNow
	mov	si, offset MergeAllEntry
	call	disableItemNow
endif

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

WriteApplicationClipboardNotifyNormalTransferItemChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForUsableMergeScrap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a usable merge scrap exists.

CALLED BY:	WriteApplicationClipboardNotifyNormalTransferItemChanged
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
		WriteApplicationUpdateDateSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the displayed sample date to the selected format

CALLED BY:	MSG_WRITE_APPLICATION_UPDATE_DATE_SAMPLE
PASS:		*ds:si	= WriteApplication object
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
WriteApplicationUpdateDateSample method WriteApplicationClass, 
				MSG_WRITE_APPLICATION_UPDATE_DATE_SAMPLE
	.enter
	GetResourceHandleNS InsertDateSampleText, bx
	mov	si, offset InsertDateSampleText
	call	WriteApplicationUpdateSampleCommon
	.leave
	ret
WriteApplicationUpdateDateSample endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteApplicationUptimeTimeSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the displayed sample time to the selected format

CALLED BY:	MSG_WRITE_APPLICATION_UPDATE_TIME_SAMPLE
PASS:		*ds:si	= WriteApplication object
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
WriteApplicationUpdateTimeSample method WriteApplicationClass, 
				MSG_WRITE_APPLICATION_UPDATE_TIME_SAMPLE
	.enter
	GetResourceHandleNS InsertTimeSampleText, bx
	mov	si, offset InsertTimeSampleText
	call	WriteApplicationUpdateSampleCommon
	.leave
	ret
WriteApplicationUpdateTimeSample endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteApplicationUpdateSampleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the text in one of our objects to reflect the
		current date or time in the selected format.

CALLED BY:	(INTERNAL) WriteApplicationUpdateTimeSample,
			   WriteApplicationUpdateDateSample
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
WriteApplicationUpdateSampleCommon proc	near
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
WriteApplicationUpdateSampleCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteApplicationInitializeTimeSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the InsertTimeSampleText when the box first
		comes up.

CALLED BY:	MSG_WRITE_APPLICATION_INITIALIZE_TIME_SAMPLE
PASS:		*ds:si	= WriteApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteApplicationInitializeTimeSample method dynamic WriteApplicationClass, 
				MSG_WRITE_APPLICATION_INITIALIZE_TIME_SAMPLE
	GetResourceHandleNS	TimeFormatList, bx
	mov	si, offset TimeFormatList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax <- format
	mov_tr	cx, ax
	GOTO	WriteApplicationUpdateTimeSample
WriteApplicationInitializeTimeSample endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteApplicationInitializeDateSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the InsertDateSampleText when the box first
		comes up.

CALLED BY:	MSG_WRITE_APPLICATION_INITIALIZE_DATE_SAMPLE
PASS:		*ds:si	= WriteApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteApplicationInitializeDateSample method dynamic WriteApplicationClass, 
				MSG_WRITE_APPLICATION_INITIALIZE_DATE_SAMPLE
	GetResourceHandleNS	DateFormatList, bx
	mov	si, offset DateFormatList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax <- format
	mov_tr	cx, ax
	GOTO	WriteApplicationUpdateDateSample
WriteApplicationInitializeDateSample endm

COMMENT @----------------------------------------------------------------------

METHOD:		WriteApplicationMetaQuit -- 
		MSG_META_QUIT for WriteApplicationClass

DESCRIPTION:	Never quit.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_META_QUIT

RETURN:		
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/23/93         Initial Version

------------------------------------------------------------------------------@

ifdef _VS150

WriteApplicationMetaQuit	method dynamic	WriteApplicationClass, \
				MSG_META_QUIT
	;
	; Do nothing.  Hopefully we'll have saved documents by a different
	; means.
	;
	ret
WriteApplicationMetaQuit	endm

endif

DocMiscFeatures ends


WriteCommonCode	segment

WriteApplicationKbdChar	method	dynamic WriteApplicationClass, MSG_META_KBD_CHAR
	;
	; check if template wizard is active
	;
		push	ax, cx, dx, bp, si
		push	cx, dx
		mov	ax, MSG_META_GET_FOCUS_EXCL
		call	ObjCallInstanceNoLock
		movdw	bxsi, cxdx
		pop	cx, dx
		jnc	callSuper
		tst	bx
		jz	callSuper
		push	cx, dx
		push	ds
		GetResourceSegmentNS	WriteTemplateWizardClass, ds
		mov	cx, ds
		pop	ds
		mov	dx, offset WriteTemplateWizardClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, dx
		jnc	callSuper
SBCS <		cmp	ch, CS_CONTROL					>
DBCS <		cmp	ch, CS_CONTROL_HB				>
		jne	checkCtrls
SBCS <		cmp	cl, VC_MENU					>
DBCS <		cmp	cx, C_SYS_MENU					>
		je	eatIt
SBCS <		cmp	cl, VC_LWIN					>
DBCS <		cmp	cx, C_SYS_LWIN					>
		je	eatIt
SBCS <		cmp	cl, VC_RWIN					>
DBCS <		cmp	cx, C_SYS_RWIN					>
		je	eatIt
SBCS <		cmp	cl, VC_F1					>
DBCS <		cmp	cx, C_SYS_F1					>
		jb	callSuper
SBCS <		cmp	cl, VC_F12					>
DBCS <		cmp	cx, C_SYS_F12					>
		ja	callSuper
	; eat Express, Calculator, F-keys
eatIt:
		pop	ax, cx, dx, bp, si
		ret

checkCtrls:
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	callSuper
SBCS <		cmp	cl, C_CAP_A					>
DBCS <		cmp	cx, C_LATIN_CAPITAL_LETTER_A			>
		jb	callSuper
SBCS <		cmp	cl, C_CAP_Z					>
DBCS <		cmp	cx, C_LATIN_CAPITAL_LETTER_Z			>
		jbe	eatIt
SBCS <		cmp	cl, C_SMALL_Z					>
DBCS <		CMP	cx, C_LATIN_SMALL_LETTER_Z			>
		ja	callSuper
SBCS <		cmp	cl, C_SMALL_A					>
DBCS <		cmp	cx, C_LATIN_SMALL_LETTER_A			>
		jae	eatIt
callSuper:
		pop	ax, cx, dx, bp, si
		mov	di, offset WriteApplicationClass
		GOTO	ObjCallSuperNoLock
WriteApplicationKbdChar	endm

WriteCommonCode	ends
