COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiDrawApplication.asm
FILE:		uiDrawApplication.asm

AUTHOR:		Gene Anderson, Jun  8, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 8/92		Initial revision

DESCRIPTION:
	Draw subclass of application 

	$Id: uiDrawApplication.asm,v 1.1 97/04/04 15:51:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment

	DrawApplicationClass			;declare the class

idata	ends

InitCode segment resource

DA_ObjMessageSend		proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
DA_ObjMessageSend		endp

DA_ObjMessageCall	proc	near
	uses	di
	.enter

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	.leave
	ret
DA_ObjMessageCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawApplicationAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle attach for application object

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DrawApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawApplicationAttach		method dynamic DrawApplicationClass,
						MSG_META_ATTACH
	push	ax, cx, dx, si, bp
	;
	; Set things that are solely dependent on the interface level
	;
	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	jnz	keepDrawOptionsMenu

	push	si
	GetResourceHandleNS DrawOptionsMenu, bx
	mov	si, offset DrawOptionsMenu
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	DA_ObjMessageSend
	pop	si
keepDrawOptionsMenu:

	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	keepUserLevel
	push	si
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	DA_ObjMessageSend
	pop	si
keepUserLevel:

	;
	; and also change the .ini file category based on interfaceLevel.
	;
	mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
	mov	cx, 9				;'geodraw0' + NULL
	call	ObjVarAddData
	mov	{word}ds:[bx+0], 'ge'
	mov	{word}ds:[bx+2], 'od'
	mov	{word}ds:[bx+4], 'ra'
	mov	{word}ds:[bx+6], 'w'		;'geodraw' + NULL
	
	call	UserGetDefaultUILevel		;ax = UIInterfaceLevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	callSuper
	mov	{word}ds:[bx+7], '0'		;'geodraw0' + NULL

callSuper:
	;
	; Send on to our superclass
	;
	pop	ax, cx, dx, si, bp
	mov	di, offset DrawApplicationClass
	GOTO	ObjCallSuperNoLock
DrawApplicationAttach		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawApplicationLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle loading options from geos.ini file

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DrawApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;ifndef PRODUCT_NDO2000
;
;settingsTable	DrawFeatures	\
; INTRODUCTORY_FEATURES,
; BEGINNING_FEATURES,
; INTERMEDIATE_FEATURES
;
;else

settingsTable	DrawFeatures	\
 INTRODUCTORY_FEATURES,
 BEGINNING_FEATURES,
 INTERMEDIATE_FEATURES,
 ADVANCED_FEATURES
	
;endif

featuresKey	char	"features", 0

DrawApplicationLoadOptions		method dynamic DrawApplicationClass,
						MSG_META_LOAD_OPTIONS,
						MSG_META_RESET_OPTIONS
	mov	di, offset DrawApplicationClass
	call	ObjCallSuperNoLock

	; if no features settings are stored then use
	; defaults based on the system's user level

	sub	sp, INI_CATEGORY_BUFFER_SIZE
	movdw	cxdx, sssp

	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock
	mov	ax, sp
	push	si, ds
	segmov	ds, ss
	mov_tr	si, ax
	mov	cx, cs
	mov	dx, offset featuresKey
	call	InitFileReadInteger
	pop	si, ds
	mov	bp, sp
	lea	sp, ss:[bp+INI_CATEGORY_BUFFER_SIZE]
	jnc	done

	;
	; no geos.ini file settings -- set objects based on level
	;
	call	UserGetDefaultLaunchLevel	;ax <- user level (0-3)
;ifndef PRODUCT_NDO2000
;	cmp	ax, UIIL_INTERMEDIATE		;Ensure highest level is
;	jbe	gotLevel			; intermediate.
;	mov	ax, UIIL_INTERMEDIATE
;gotLevel:
;endif
	mov_tr	di, ax
	shl	di				;di <- table offset

	GetResourceHandleNS UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	DA_ObjMessageCall		;ax <- selection

	mov	cx, cs:settingsTable[di]
	cmp	ax, cx
	je	afterSetUserLevel
	;
	; The user level is different -- update the list
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				;dx <- no indeterminates
	call	DA_ObjMessageSend
	mov	cx, 1				;cx <- mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	DA_ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	DA_ObjMessageSend
afterSetUserLevel:
done:
	ret
DrawApplicationLoadOptions		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawApplicationUpdateAppFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update features for Draw

CALLED BY:	MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DrawApplicationClass
		ax - the message

		ss:bp - GenAppUpdateFeaturesParams

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; This table has an entry corresponding to each feature bit in the
; DrawFeatures record.  The entry is a pointer to the list of
; objects to turn on/off for that feature.
;
usabilityTable	fptr \
	interactiveCreateList,		;DF_INTERACTIVE_CREATE
	basicOptionsList,		;DF_BASIC_OPTIONS
	extendedOptionsList,		;DF_EXTENDED_OPTIONS
	basicGeometryList,		;DF_BASIC_GEOMETRY
	extendedGeometryList,		;DF_EXTENDED_GEOMETRY
	basicAttributesList,		;DF_BASIC_ATTRIBUTES
	extendedAttributesList,		;DF_EXTENDED_ATTRIBUTES
	basicTextEditingList,		;DF_BASIC_TEXT_EDITING 
	extendedTextEditingList,	;DF_EXTENDED_TEXT_EDITING 
	basicPolylineEditingList,	;DF_BASIC_POLYLINE_EDITING 
	extendedPolylineEditingList,	;DF_EXTENDED_POLYLINE_EDITING 
	rulersList,			;DF_RULERS
if _BITMAP_EDITING
	bitmapEditingList,		;DF_BITMAP_EDITING
else
	0,
endif
	impexList

interactiveCreateList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple LeftToolbar
	GenAppMakeUsabilityTuple DrawCreateMenu, reversed, reparent
	GenAppMakeUsabilityTuple DrawGrObjToolControl
	GenAppMakeUsabilityTuple DrawGrObjToolTools, restart, end

basicOptionsList	label	GenAppUsabilityTuple
if _BITMAP_EDITING
	GenAppMakeUsabilityTuple DrawConvertControl
endif
	GenAppMakeUsabilityTuple DrawDuplicateInteraction, popup
;ifdef PRODUCT_NDO2000
	GenAppMakeUsabilityTuple DrawDuplicateManyControl
;endif
	GenAppMakeUsabilityTuple DrawDraftModeControl, end

extendedOptionsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawCustomDuplicateControl
	GenAppMakeUsabilityTuple DrawDuplicateControl, recalc
	GenAppMakeUsabilityTuple DrawDuplicateTools, restart
	GenAppMakeUsabilityTuple DrawPasteInsideInteraction
	GenAppMakeUsabilityTuple DrawPasteInsideTools, restart
	GenAppMakeUsabilityTuple DrawHideShowControl
	GenAppMakeUsabilityTuple DrawHandleControl
	GenAppMakeUsabilityTuple DrawToolControl
	GenAppMakeUsabilityTuple DrawInstructionControl
	GenAppMakeUsabilityTuple DrawInstructionControl
	GenAppMakeUsabilityTuple DrawStyleSheetControl
	GenAppMakeUsabilityTuple DrawObscureAttrControl
	GenAppMakeUsabilityTuple RightToolbar
;;;	GenAppMakeUsabilityTuple BottomToolbar
	GenAppMakeUsabilityTuple FloatingToolbox
	GenAppMakeUsabilityTuple DrawEditTools, restart
	GenAppMakeUsabilityTuple ExtAttrDialog, end

basicGeometryList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawTransformMenu
	GenAppMakeUsabilityTuple DrawArrangeMenu
	GenAppMakeUsabilityTuple DrawRotateControl
	GenAppMakeUsabilityTuple DrawFlipControl
	GenAppMakeUsabilityTuple DrawFlipTools, restart
	GenAppMakeUsabilityTuple DrawDepthControl
	GenAppMakeUsabilityTuple DrawGroupControl
	GenAppMakeUsabilityTuple DrawGroupTools, restart
	GenAppMakeUsabilityTuple DrawDepthTools, restart
	GenAppMakeUsabilityTuple DrawNudgeControl, end

extendedGeometryList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawFlipControl, popup
	GenAppMakeUsabilityTuple DrawNudgeControl, popup
	GenAppMakeUsabilityTuple DrawRotateControl, popup
	GenAppMakeUsabilityTuple DrawRotateControl, recalc
	GenAppMakeUsabilityTuple DrawScaleControl
	GenAppMakeUsabilityTuple DrawSkewControl
	GenAppMakeUsabilityTuple DrawTransformControl
	GenAppMakeUsabilityTuple DrawArcControl
	GenAppMakeUsabilityTuple DrawAlignDistributeControl
	GenAppMakeUsabilityTuple DrawAlignToGridControl, end

basicAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawBothColorSelector, reversed
	GenAppMakeUsabilityTuple DrawBothColorTools, reversed, restart
;;;	GenAppMakeUsabilityTuple DrawAttributeMenu
	GenAppMakeUsabilityTuple DrawAreaAttrInteraction
	GenAppMakeUsabilityTuple DrawLineAttrInteraction
	GenAppMakeUsabilityTuple DrawCharFGColorControl
	GenAppMakeUsabilityTuple DrawAreaColorTools, restart
	GenAppMakeUsabilityTuple DrawLineColorTools, restart
	GenAppMakeUsabilityTuple DrawLineAttrTools, restart
	GenAppMakeUsabilityTuple DrawTextColorTools, restart, end

extendedAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawBackgroundAttrInteraction
	GenAppMakeUsabilityTuple DrawAreaColorSelector, recalc
ifdef DO_PIZZA
else
	GenAppMakeUsabilityTuple DrawAreaAttrControl
endif
	GenAppMakeUsabilityTuple DrawLineColorSelector, recalc
	GenAppMakeUsabilityTuple DrawLineAttrControl, recalc
	GenAppMakeUsabilityTuple DrawCharFGColorControl, recalc
	GenAppMakeUsabilityTuple DrawGradientAttrInteraction
	GenAppMakeUsabilityTuple DrawDefaultAttributesControl, end

basicTextEditingList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawGrObjToolControl, recalc
	GenAppMakeUsabilityTuple DrawTextMenu
	GenAppMakeUsabilityTuple DrawFontControl
	GenAppMakeUsabilityTuple FontTools, restart
	GenAppMakeUsabilityTuple DrawTextStyleControl
	GenAppMakeUsabilityTuple TextStyleTools, restart
	GenAppMakeUsabilityTuple DrawPointSizeControl
	GenAppMakeUsabilityTuple PointSizeTools, restart
	GenAppMakeUsabilityTuple ParagraphMenu
	GenAppMakeUsabilityTuple DrawJustificationControl
	GenAppMakeUsabilityTuple JustificationTools, restart
	GenAppMakeUsabilityTuple DrawCharFGColorControl
	GenAppMakeUsabilityTuple DrawTextColorTools, restart, end

extendedTextEditingList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawTextStyleControl, recalc
	GenAppMakeUsabilityTuple DrawPointSizeControl, recalc
	GenAppMakeUsabilityTuple ParagraphMenu, popup
	GenAppMakeUsabilityTuple DrawFontAttrControl
	GenAppMakeUsabilityTuple DrawTextStyleSheetControl
	GenAppMakeUsabilityTuple DrawJustificationControl, popup
	GenAppMakeUsabilityTuple JustificationTools, restart
	GenAppMakeUsabilityTuple DrawLineSpacingControl
	GenAppMakeUsabilityTuple DrawParaSpacingControl
	GenAppMakeUsabilityTuple DrawParaBGColorControl
	GenAppMakeUsabilityTuple DrawMarginControl
	GenAppMakeUsabilityTuple DrawTabControl
	GenAppMakeUsabilityTuple DrawDefaultTabsControl
	GenAppMakeUsabilityTuple BorderSubMenu
	;;; GenAppMakeUsabilityTuple DrawDropCapControl
	GenAppMakeUsabilityTuple DrawHyphenationControl
	GenAppMakeUsabilityTuple DrawCharBGColorControl
ifndef GPC  ; always there for GPC
	GenAppMakeUsabilityTuple DrawSpellControl
endif
	GenAppMakeUsabilityTuple DrawSearchReplaceControl, end

basicPolylineEditingList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawGrObjToolControl, recalc
	GenAppMakeUsabilityTuple DrawSplinePointControl
	GenAppMakeUsabilityTuple DrawSplineOpenCloseControl
	GenAppMakeUsabilityTuple DrawPolylineMenu, end

extendedPolylineEditingList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawGrObjToolControl, recalc
	GenAppMakeUsabilityTuple DrawSplineSmoothnessControl, end

rulersList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawRulerInteraction
	GenAppMakeUsabilityTuple DrawRulerShowControl
	GenAppMakeUsabilityTuple DrawRulerTypeControl
	GenAppMakeUsabilityTuple DrawGridControl
	GenAppMakeUsabilityTuple DrawGuideControl, end 	

if _BITMAP_EDITING
bitmapEditingList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawBitmapToolControl
	GenAppMakeUsabilityTuple DrawBitmapToolTools, restart
	GenAppMakeUsabilityTuple DrawBitmapFormatControl, end
endif

impexList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawImpexSubGroup, end

levelTable			label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple DrawGrObjToolControl, recalc
	GenAppMakeUsabilityTuple DrawTextStyleControl, recalc
	GenAppMakeUsabilityTuple DrawPointSizeControl, recalc
;;;	GenAppMakeUsabilityTuple DrawJustificationControl, recalc
	GenAppMakeUsabilityTuple DrawCreateControl, recalc
ifdef DO_PIZZA
else
	GenAppMakeUsabilityTuple DrawAreaAttrControl, recalc
endif
	GenAppMakeUsabilityTuple DrawCustomShapeControl, recalc
	GenAppMakeUsabilityTuple DrawEditControl, recalc
	GenAppMakeUsabilityTuple DrawEditTools, restart
	GenAppMakeUsabilityTuple DrawViewControl, recalc
	GenAppMakeUsabilityTuple DrawViewTools, restart
	GenAppMakeUsabilityTuple DrawDisplayControl, recalc
	GenAppMakeUsabilityTuple DrawSearchReplaceControl, recalc
	GenAppMakeUsabilityTuple DrawSpellControl, recalc
	GenAppMakeUsabilityTuple DrawDocumentControlObj, recalc, end

DrawApplicationUpdateAppFeatures	method dynamic DrawApplicationClass,
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

	push	bp
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; Call General Tsuo -- um -- general routine to update usability
	;
	mov	ss:[bp].GAUFP_table.segment, cs
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable

	mov	ss:[bp].GAUFP_levelTable.segment, cs
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	GetResourceHandleNS	CreateEditMenuSpace, bx
	mov	ss:[bp].GAUFP_reparentObject.handle, bx
	mov	ss:[bp].GAUFP_reparentObject.offset, offset CreateEditMenuSpace

	GetResourceHandleNS	CreateMenubarSpace, bx
	mov	ss:[bp].GAUFP_unReparentObject.handle, bx
	mov	ss:[bp].GAUFP_unReparentObject.offset, offset CreateMenubarSpace
	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock

;ifndef PRODUCT_NDO2000
;	;
;	; Make the attributes menu available or not depending upon
;	; which features the user has turned on/off.
;	;
;	test	ss:[bp].GAUFP_featuresChanged, \
;			mask DF_BASIC_ATTRIBUTES or \
;			mask DF_EXTENDED_ATTRIBUTES
;	jz	done
;	mov	ax, MSG_GEN_SET_NOT_USABLE
;	test	ss:[bp].GAUFP_featuresOn, \
;			mask DF_BASIC_ATTRIBUTES or \
;			mask DF_EXTENDED_ATTRIBUTES
;	jz	setState
;	mov	ax, MSG_GEN_SET_USABLE
;setState:
;	push	si
;	GetResourceHandleNS	DrawAttributeMenu, bx
;	mov	si, offset DrawAttributeMenu
;	mov	dl, VUM_NOW
;	mov	di, mask MF_FIXUP_DS
;;;;	call	ObjMessage
;	pop	si
;
;	;
;	; OK, we're done.
;	;
;done:
;endif
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	ObjCallInstanceNoLock

	ret
DrawApplicationUpdateAppFeatures		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawApplicationSetUserLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user level

CALLED BY:	MSG_DRAW_APPLICATION_SET_USER_LEVEL
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DrawApplicationClass
		ax - the message

		cx - user level

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawApplicationSetUserLevel	method dynamic	DrawApplicationClass,
				MSG_DRAW_APPLICATION_SET_USER_LEVEL
	mov	ax, cx				;ax <- new features
	;
	; find the corresponding bar states and level
	;
	push	si
	clr	di, bp
	mov	cx, (length settingsTable)	;cx <- # entries
	mov	dl, UIIL_INTRODUCTORY		;dl <- UIInterfaceLevel
	mov	dh, dl				;dh <- nearest so far (level)
	mov	si, 16				;si <- nearest so far (# bits)
findLoop:
	cmp	ax, cs:settingsTable[di]
	je	found
	push	ax, cx
	;
	; See how closely the features match what we're looking for
	;
	mov	bx, ax
	xor	bx, cs:settingsTable[di]
	clr	ax				;no bits on
	mov	cx, 16
countBits:
	ror	bx, 1
	jnc	nextBit				;bit on?
	inc	ax				;ax <- more bit
nextBit:
	loop	countBits

	cmp	ax, si				;fewer differences?

	ja	nextEntry			;branch if not fewer difference
	;
	; In the event we don't find a match, use the closest
	;
	mov	si, ax				;si <- nearest so far (# bits)
	mov	dh, dl				;dh <- nearest so far (level)
	mov	bp, di				;bp <- corresponding entry
nextEntry:
	pop	ax, cx
	inc	dl				;dl <- next UIInterfaceLevel
	inc	di
	inc	di
	loop	findLoop
	;
	; No exact match -- set the level to the closest
	;
	mov	dl, dh				;dl <- nearest level
	mov	di, bp				;di <- corresponding entry
	;
	; Set the app features and level
	;
found:
	pop	si
	clr	dh				;dx <- UIInterfaceLevel
	push	dx
	mov	cx, ax				;cx <- features to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- UIInterfaceLevel to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
	call	ObjCallInstanceNoLock

	;
	; if not attaching, save after user level change
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
;ifdef PRODUCT_NDO2000
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	ObjCallInstanceNoLock
;else
;	mov	ax, MSG_META_SAVE_OPTIONS
;	call	UserCallApplication
;endif
done:
	ret
DrawApplicationSetUserLevel	endm

DrawApplicationSetTemplateUserLevel	method	dynamic	DrawApplicationClass,
				MSG_GEN_APPLICATION_SET_TEMPLATE_USER_LEVEL
	mov	dx, INTRODUCTORY_FEATURES
	cmp	cx, UIIL_INTRODUCTORY
	je	gotFeatures
	mov	dx, BEGINNING_FEATURES
	cmp	cx, UIIL_BEGINNING
	je	gotFeatures
	mov	dx, INTERMEDIATE_FEATURES
gotFeatures:
	mov	ax, MSG_DRAW_APPLICATION_SET_USER_LEVEL
	mov	cx, dx
	push	cx
	call	ObjCallInstanceNoLock
	; update list
	pop	cx
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret
DrawApplicationSetTemplateUserLevel	endm		


COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawApplicationChangeUserLevel --
		MSG_DRAW_APPLICATION_CHANGE_USER_LEVEL
						for DrawApplicationClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of DrawApplicationClass

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
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
DrawApplicationChangeUserLevel	method dynamic	DrawApplicationClass,
					MSG_DRAW_APPLICATION_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	ret

DrawApplicationChangeUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawApplicationCancelUserLevel --
		MSG_DRAW_APPLICATION_CANCEL_USER_LEVEL
						for DrawApplicationClass

DESCRIPTION:	Cancel user change to the user level

PASS:
	*ds:si - instance data
	es - segment of DrawApplicationClass

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
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
DrawApplicationCancelUserLevel	method dynamic	DrawApplicationClass,
					MSG_DRAW_APPLICATION_CANCEL_USER_LEVEL

	mov	cx, ds:[di].GAI_appFeatures

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	ret

DrawApplicationCancelUserLevel	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawApplicationQueryResetOptions --
		MSG_DRAW_APPLICATION_QUERY_RESET_OPTIONS
						for DrawApplicationClass

DESCRIPTION:	Make sure that the user wants to reset options

PASS:
	*ds:si - instance data
	es - segment of DrawApplicationClass

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
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
DrawApplicationQueryResetOptions	method dynamic	DrawApplicationClass,
				MSG_DRAW_APPLICATION_QUERY_RESET_OPTIONS

	; ask the user if she wants to reset the options

	push	ds:[LMBH_handle]
	clr	ax
	pushdw	axax				;SDOP_helpContext
	pushdw	axax				;SDOP_customTriggers
	pushdw	axax				;SDOP_stringArg2
	pushdw	axax				;SDOP_stringArg1
	GetResourceHandleNS	ResetOptionsQueryString, bx
	mov	ax, offset ResetOptionsQueryString
	pushdw	bxax
	mov	ax, CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION, 0>
	push	ax
	call	UserStandardDialogOptr
	pop	bx
	call	MemDerefDS
	cmp	ax, IC_YES
	jnz	done

	mov	ax, MSG_META_RESET_OPTIONS
	call	ObjCallInstanceNoLock
done:
	ret

DrawApplicationQueryResetOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawApplicationUserLevelStatus --
		MSG_DRAW_APPLICATION_USER_LEVEL_STATUS
						for DrawApplicationClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of DrawApplicationClass

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
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
if 0
DrawApplicationUserLevelStatus	method dynamic	DrawApplicationClass,
				MSG_DRAW_APPLICATION_USER_LEVEL_STATUS

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, ADVANCED_FEATURES
	jz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_NOW
	GetResourceHandleNS	FineTuneTrigger, bx
	mov	si, offset FineTuneTrigger
	mov	di, mask MF_FIXUP_DS
	GOTO	ObjMessage

DrawApplicationUserLevelStatus	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawApplicationInitiateFineTune
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the fine tune dialog box

CALLED BY:	MSG_DRAW_APPLICATION_INITIATE_FINE_TUNE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DrawApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawApplicationInitiateFineTune	method dynamic DrawApplicationClass,
				MSG_DRAW_APPLICATION_INITIATE_FINE_TUNE
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	DA_ObjMessageCall			;ax = features

	mov_tr	cx, ax
	clr	dx
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	DA_ObjMessageSend

	GetResourceHandleNS	FineTuneDialog, bx
	mov	si, offset FineTuneDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	DA_ObjMessageSend
	ret
DrawApplicationInitiateFineTune		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawApplicationFineTune
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set fine tune settings

CALLED BY:	MSG_DRAW_APPLICATION_FINE_TUNE
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DrawApplicationClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawApplicationFineTune		method dynamic DrawApplicationClass,
					MSG_DRAW_APPLICATION_FINE_TUNE

	;
	; get fine tune settings
	;
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	DA_ObjMessageCall		;ax <- new features

	;
	; update the level list
	;
	mov_tr	cx, ax				;cx <- new features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	DA_ObjMessageSend
	mov	cx, 1				;cx <- mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	DA_ObjMessageSend

	;
	; if not attaching, save after fine tune
	;
	mov	si, offset DrawApp
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
;ifdef PRODUCT_NDO2000
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	ObjCallInstanceNoLock
;else
;	mov	ax, MSG_META_SAVE_OPTIONS
;	call	UserCallApplication
;endif
done:

	ret
DrawApplicationFineTune		endm

InitCode	ends

CommonCode	segment

DrawApplicationKbdChar	method	dynamic DrawApplicationClass, MSG_META_KBD_CHAR
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
		GetResourceSegmentNS	DrawTemplateWizardClass, ds
		mov	cx, ds
		pop	ds
		mov	dx, offset DrawTemplateWizardClass
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
DBCS <		cmp	cx, C_LATIN_SMALL_LETTER_Z			>
		ja	callSuper
SBCS <		cmp	cl, C_SMALL_A					>
DBCS <		cmp	cx, C_LATIN_SMALL_LETTER_A			>
		jae	eatIt
callSuper:
		pop	ax, cx, dx, bp, si
		mov	di, offset DrawApplicationClass
		GOTO	ObjCallSuperNoLock
DrawApplicationKbdChar	endm

CommonCode	ends
