COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		mainAppUI.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/92		Initial version

DESCRIPTION:
	This file contains the scalable UI code for WriteApplicationClass

	$Id: mainAppUI.asm,v 1.1 97/04/04 15:57:07 newdeal Exp $

------------------------------------------------------------------------------@

idata segment

changingLevels	BooleanByte	BB_FALSE

if _REGION_LIMIT
regionLimit	word		0
regionWarning	word		0
endif

idata ends

;---

AppInitExit segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationAttach -- MSG_META_ATTACH
						for WriteApplicationClass

DESCRIPTION:	Deal with starting GeoWrite

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

	cx - AppAttachFlags
	dx - Handle of AppLaunchBlock, or 0 if none.
	bp - Handle of extra state block, or 0 if none.

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationAttach	method dynamic	WriteApplicationClass, MSG_META_ATTACH

	push	ax, cx, dx, si, bp

	push	si
	GetResourceHandleNS	WriteEditControl, bx
	mov	si, offset WriteEditControl
	mov	ax, MSG_GEN_CONTROL_GENERATE_UI
	call	AIE_ObjMessageSend
	pop	si

	; set things that are solely dependent on the UI state

	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	jnz	keepOptionsMenu

	push	si
	GetResourceHandleNS	OptionsMenu, bx
	mov	si, offset OptionsMenu
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	AIE_ObjMessageSendNow
	pop	si
keepOptionsMenu:

	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	keepUserLevel
	push	si
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	AIE_ObjMessageSendNow
	pop	si
keepUserLevel:

	;
	; and also change the .ini file category based on interfaceLevel.
	;
	mov	ax, ATTR_GEN_INIT_FILE_CATEGORY
	mov	cx, 7				;'write0' + NULL
	call	ObjVarAddData
	mov	{word}ds:[bx+0], 'aw'
	mov	{word}ds:[bx+2], 'p'
	
	call	UserGetDefaultUILevel		;ax = UIInterfaceLevel
	cmp	ax, UIIL_INTRODUCTORY
	jne	callSuper
	mov	{word}ds:[bx+3], '0'		;'write0' + NULL

callSuper:
	pop	ax, cx, dx, si, bp
	mov	di, offset WriteApplicationClass
	call	ObjCallSuperNoLock

	; get the misc settings

	push	si				; Save chunk handle
	GetResourceHandleNS	MiscSettingsList, bx
	mov	si, offset MiscSettingsList
	call	AIE_GetBooleans
	push	es
	GetResourceSegmentNS dgroup, es		; es = dgroup
	mov	es:[miscSettings], ax
	pop	es
	pop	dx				; Restore chunk handle
	mov	cx, ds:LMBH_handle		; ^lcx:dx <- optr for app obj
	
	;
	; Add ourselves to the clipboard notification list so we can set the
	; merge-items in the print dialog box correctly.
	;
	call	ClipboardAddToNotificationList	; Add app object to list

	; If we are not configured to have the Help Editor then turn it off

	push	ds
	segmov	ds, cs
	mov	si, offset configureCategory
	mov	cx, cs
	mov	dx, offset helpEditorKey
	call	InitFileReadBoolean
	pop	ds
	jc	noHelpEditor
	tst	ax
	jnz	afterHelpEditor
noHelpEditor:

	; no help editor -- turn it off

	GetResourceHandleNS	HelpEditorEntry, bx
	mov	si, offset HelpEditorEntry
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	AIE_ObjMessageSendNow

afterHelpEditor:

	; If we are not configured to have the Thesaurus then nuke it

if 0
	push	ds
	segmov	ds, cs
	mov	si, offset configureCategory
	mov	cx, cs
	mov	dx, offset noThesaurusKey
	call	InitFileReadBoolean
	pop	ds
	jc	afterThesaurus
	tst	ax
	jz	afterThesaurus

	; no thesaurus -- turn it off

	GetResourceHandleNS	WriteThesaurusControl, bx
	mov	si, offset WriteThesaurusControl
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	AIE_ObjMessageSendNow
endif

afterThesaurus:

	; si and ds are trashed at this point

if _REGION_LIMIT

	GetResourceSegmentNS dgroup, es		; es = dgroup
	mov	es:regionLimit, 0		; assume no region limit
	mov	es:regionWarning, 0

	segmov	ds, cs
	mov	si, offset textCategory
	mov	cx, cs
	mov	dx, offset regionLimitKey
	call	InitFileReadInteger
	jc	afterRegionLimit
	mov	es:regionLimit, ax		; save the region limit

	mov	dx, offset regionWarningKey
	call	InitFileReadInteger
	jc	afterRegionLimit
	mov	es:regionWarning, ax		; save the region warning limit

afterRegionLimit:

endif		

	; send a null notification to the GrObjBitmapToolControl so that
	; can be enabled even before GrObjTools are shown.

	call	SendBitmapToolNotification
		
	ret

WriteApplicationAttach	endm

configureCategory	char	"configure", 0
helpEditorKey		char	"helpEditor", 0
noThesaurusKey		char	"noThesaurus", 0
if _REGION_LIMIT
textCategory		char	"text", 0
regionLimitKey		char	"regionLimit", 0
regionWarningKey	char	"regionWarning", 0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendBitmapToolNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send notification to bitmap tool controller, so it
		will enable itself

CALLED BY:	WriteApplicationLoadOptions
PASS:		*ds:si - Application
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/20/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendBitmapToolNotification		proc	near
gcnParams	local	GCNListMessageParams
	.enter
		
	mov	ax, size VisBitmapNotifyCurrentTool
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE \
			or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax

	movdw	es:[VBNCT_toolClass], -1
	call	MemUnlock
	mov	ax, 1
	call	MemInitRefCount

	push	bp
	mov	bp, bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_BITMAP_CURRENT_TOOL_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event
	pop	bp

	mov	gcnParams.GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	gcnParams.GCNLMP_ID.GCNLT_type,
			GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE
	mov	gcnParams.GCNLMP_block, bx
	mov	gcnParams.GCNLMP_event, di
	mov	gcnParams.GCNLMP_flags, mask GCNLSF_SET_STATUS

	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST   ; Update GCN list
	mov	dx, size GCNListMessageParams		   ; create stack frame
	push	bp
	lea	bp, gcnParams
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	pop	bp
		
	.leave
	ret
SendBitmapToolNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteApplicationDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach the application.

CALLED BY:	via MSG_META_DETACH
PASS:		*ds:si	= Instance
		... other args ...
RETURN:		whatever the superclass does
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteApplicationDetach	method dynamic	WriteApplicationClass, MSG_META_DETACH
	;
	; Remove ourselves from the clipboard notification list
	;
	push	cx, dx				; Save info for superclass
	mov	cx, ds:LMBH_handle		; ^lcx:dx <- our object
	mov	dx, si
	call	ClipboardRemoveFromNotificationList
	pop	cx, dx				; Restore info for superclass
	
	;
	; Let superclass detach
	;
	mov	di, offset WriteApplicationClass
	call	ObjCallSuperNoLock
	ret
WriteApplicationDetach	endm


;---

AIE_ObjMessageSendNow	proc	near
	mov	dl, VUM_NOW
	FALL_THRU	AIE_ObjMessageSend
AIE_ObjMessageSendNow	endp

AIE_ObjMessageSend	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	AIE_ObjMessage
	pop	di
	ret
AIE_ObjMessageSend	endp

AIE_ObjMessage	proc	near
	call	ObjMessage
	ret
AIE_ObjMessage	endp

;---

	; returns ax = booleans
AIE_GetBooleans	proc	near
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	FALL_THRU	AIE_ObjMessageCall
AIE_GetBooleans	endp

;---

AIE_ObjMessageCall	proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	AIE_ObjMessage
	pop	di
	ret
AIE_ObjMessageCall	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationLoadOptions -- MSG_META_LOAD_OPTIONS
						for WriteApplicationClass

DESCRIPTION:	Open the app

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@

SettingTableEntry	struct
    STE_showBars	WriteBarStates
    STE_features	WriteFeatures
SettingTableEntry	ends

settingsTable	SettingTableEntry	\
 <INTRODUCTORY_BAR_STATES, INTRODUCTORY_FEATURES>,
 <BEGINNING_BAR_STATES, BEGINNING_FEATURES>,
 <INTERMEDIATE_BAR_STATES, INTERMEDIATE_FEATURES>,
 <ADVANCED_BAR_STATES, ADVANCED_FEATURES>

featuresKey		char	"features", 0

;---

WriteApplicationLoadOptions	method dynamic	WriteApplicationClass,
							MSG_META_LOAD_OPTIONS,
							MSG_META_RESET_OPTIONS

	mov	di, offset WriteApplicationClass
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
	jnc	common

	; no .ini file settings -- set objects correctly based on level

	push	si

	call	UserGetDefaultLaunchLevel		;ax = UserLevel (0-3)
	mov	bl, size SettingTableEntry
	mul	bl
	mov_tr	di, ax				;calculate array offset

	push	cs:[settingsTable][di].STE_features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	AIE_ObjMessageCall			;ax = selection
	pop	cx
	cmp	ax, cx
	jz	afterSetUserLevel
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	AIE_ObjMessageSend
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	AIE_ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	AIE_ObjMessageSend
afterSetUserLevel:

	mov	cx, cs:[settingsTable][di].STE_showBars
	call	SetBarState

	pop	si

common:

	; tell the GrObjHead to send notification about the current tool

	push	si
	GetResourceHandleNS	WriteHead, bx
	mov	si, offset WriteHead
	mov	ax, MSG_GH_SEND_NOTIFY_CURRENT_TOOL
	mov	di, mask MF_FORCE_QUEUE
	call	AIE_ObjMessageSend
	pop	si
		
	ret

WriteApplicationLoadOptions	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationSetBarState --
		MSG_WRITE_APPLICATION_SET_BAR_STATE for WriteApplicationClass

DESCRIPTION:	Set the bar state

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

	cx - new bar state

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationSetBarState	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_SET_BAR_STATE
	call	SetBarState
	ret

WriteApplicationSetBarState	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetBarState

DESCRIPTION:	Set the state of the "show bar" boolean group

CALLED BY:	INTERNAL

PASS:
	cx - new state

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
	Tony	9/24/92		Initial version

------------------------------------------------------------------------------@
SetBarState	proc	near	uses si
	.enter

	push	cx
	GetResourceHandleNS	ShowBarList, bx
	mov	si, offset ShowBarList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	AIE_ObjMessageCall			;ax = bits set
	pop	cx

	xor	ax, cx					;ax = bits changed
	jz	done

	push	ax
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	call	AIE_ObjMessageSend
	pop	cx
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	AIE_ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	AIE_ObjMessageSend
done:
	.leave
	ret

SetBarState	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationForceDrawingToolsVisible --
		MSG_WRITE_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE
						for WriteApplicationClass

DESCRIPTION:	Force the drawing tools to be visible

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
	Tony	9/22/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationForceDrawingToolsVisible	method dynamic	\
						WriteApplicationClass,
			MSG_WRITE_APPLICATION_FORCE_DRAWING_TOOLS_VISIBLE

	mov	cx, ds:[di].WAI_barStates
	mov	bp, mask WBS_SHOW_DRAWING_TOOLS
	test	cx, bp
	jnz	done

	ornf	cx, bp
	call	SetBarState
done:
	ret

WriteApplicationForceDrawingToolsVisible	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationGraphicsWarn --
		MSG_WRITE_APPLICATION_GRAPHICS_WARN for WriteApplicationClass

DESCRIPTION:	Give warning about the graphics menu

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
WriteApplicationGraphicsWarn	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_GRAPHICS_WARN

	mov	ax, offset GraphicsWarnString
	clr	cx
	mov	dx,
		 CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_NOTIFICATION,0>
	call	ComplexQuery

	ret

WriteApplicationGraphicsWarn	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationUpdateBars -- MSG_WRITE_APPLICATION_UPDATE_BARS
						for WriteApplicationClass

DESCRIPTION:	Update toolbar states

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

	cx - Booleans currently selected
	bp - Booleans whose state have been modified

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationUpdateBars	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_UPDATE_BARS

	mov	ds:[di].WAI_barStates, cx
	mov_tr	ax, cx				;ax = new state

	test	bp, mask WBS_SHOW_STYLE_BAR
	jz	noStyleBarChange
	push	ax
	clr	cx				;never avoid popout update
	GetResourceHandleNS	StyleToolbar, bx
	mov	di, offset StyleToolbar
	test	ax, mask WBS_SHOW_STYLE_BAR
	mov	ax, 0				;clear "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noStyleBarChange:

	test	bp, mask WBS_SHOW_FUNCTION_BAR
	jz	noFunctionBarChange
	push	ax
	clr	cx				;never avoid popout update
	GetResourceHandleNS	FunctionToolbar, bx
	mov	di, offset FunctionToolbar
	test	ax, mask WBS_SHOW_FUNCTION_BAR
	mov	ax, 0				;clear "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noFunctionBarChange:

	test	bp, mask WBS_SHOW_GRAPHIC_BAR
	jz	noGraphicBarChange
	push	ax
	clr	cx				;never avoid popout update
	GetResourceHandleNS	GraphicsToolbar, bx
	mov	di, offset GraphicsToolbar
	test	ax, mask WBS_SHOW_GRAPHIC_BAR
	mov	ax, 0				;clear "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noGraphicBarChange:

	test	bp, mask WBS_SHOW_DRAWING_TOOLS
	jz	noDrawingToolsChange
	push	ax
	mov	cx, bp
	and	cx, mask WBS_SHOW_BITMAP_TOOLS		; set cx to non-zero if

	GetResourceHandleNS	GrObjDrawingTools, bx
	mov	di, offset GrObjDrawingTools
	test	ax, mask WBS_SHOW_DRAWING_TOOLS
	mov	ax, 1				;set "parent is popout" flag
	call	updateToolbarUsability
	pop	ax

	; if turning drawing tools off then change to the GeoWrite tool

	push	ax, si, bp
	test	ax, mask WBS_SHOW_DRAWING_TOOLS
	jnz	drawingToolsOn

	GetResourceHandleNS	WriteHead, bx
	mov	si, offset WriteHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, segment EditTextGuardianClass
	mov	dx, offset EditTextGuardianClass
	clr	bp
	call	AIE_ObjMessageSend
	jmp	afterDrawingToolChange

drawingToolsOn:

	; if we only have a simple graphics layer then warn the user
if 0

	; The drawing tools are now shown for all levels (and features),
	; so we no longer need to warn the user based on the current
	; app features.  Sean 3/9/99.
	;
	mov	ax, MSG_GEN_APPLICATION_GET_APP_FEATURES
	call	ObjCallInstanceNoLock
	test	ax, mask WF_GRAPHICS_LAYER or mask WF_COMPLEX_GRAPHICS
	jnz	afterDrawingToolChange

	; we want to delay once through the queue before doing this so that
	; the drawing tools have a chance to come up

	mov	ax, MSG_WRITE_APPLICATION_GRAPHICS_WARN
	mov	bx, ds:[LMBH_handle]

	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	dx, mask MF_FORCE_QUEUE
	mov	ax, MSG_META_DISPATCH_EVENT

	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

endif
		
afterDrawingToolChange:
	pop	ax, si, bp
noDrawingToolsChange:

if _BITMAP_EDITING
	test	bp, mask WBS_SHOW_BITMAP_TOOLS
	jz	noBitmapToolsChange
	push	ax
	mov	cx, bp
	and	cx, mask WBS_SHOW_DRAWING_TOOLS		; set cx to non-zero if
							; drawing tools are on
	GetResourceHandleNS	GrObjBitmapTools, bx
	mov	di, offset GrObjBitmapTools
	test	ax, mask WBS_SHOW_BITMAP_TOOLS
	mov	ax, 1				;set "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noBitmapToolsChange:
endif

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	test	ds:[si].GAI_states, mask AS_ATTACHING
	jnz	exit			; no change when attaching
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication
	pop	ax, cx, dx, bp
exit:

	ret

;---

	; pass:
	;	ax - non-zero if parent is the popout
	;	*ds:si - application object
	;	bxdi - toolbar
	;	zero flag - set for usable
	;	cx - non-zero to avoid popout update
	;	ax - non-zero if parent is the popout
	; destroy:
	;	ax, bx, cx, dx, di

updateToolbarUsability:
	push	bp

	mov_tr	bp, ax				;bp = parent flag
	mov	ax, MSG_GEN_SET_USABLE
	jnz	gotMessage
	mov	ax, MSG_GEN_SET_NOT_USABLE
gotMessage:

	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	dl, VUM_NOW
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	gotMode
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
gotMode:
	pop	di

	push	si
	mov	si, di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	cmp	ax, MSG_GEN_SET_USABLE
	jnz	usabilityDone			;if not "set usable" then done
	tst	cx
	jnz	usabilityDone			;if avoid popout update flag
						;set then done

	tst	bp
	jz	afterParentFlag
	mov	ax, MSG_GEN_FIND_PARENT
	call	AIE_ObjMessageCall		;cxdx = parent
	movdw	bxsi, cxdx
afterParentFlag:
	mov	ax, MSG_GEN_INTERACTION_POP_IN
	call	AIE_ObjMessageSend

usabilityDone:
	pop	si
	pop	bp
	retn

WriteApplicationUpdateBars	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationToolbarVisibility --
		MSG_WRITE_APPLICATION_TOOLBAR_VISIBILITY
						for WriteApplicationClass

DESCRIPTION:	Notification that the toolbar visibility has changed

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

	cx - WriteBarStates
	bp - non-zero if opening, zero if closing

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/29/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationToolbarVisibility	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_TOOLBAR_VISIBILITY
	GetResourceSegmentNS	dgroup, es

	test	ds:[di].GAI_states, mask AS_DETACHING
	jnz	done

	tst	es:[changingLevels]
	jnz	done

	tst	bp				;if opening then bail
	jnz	done

	; if closing then we want to update the bar states appropriately

	mov	bp, cx
	mov	cx, ds:[di].WAI_barStates		;cx = old
	not	bp
	and	cx, bp
	cmp	cx, ds:[di].WAI_barStates
	jz	done

	; if we are iconifying then we don't want to turn the beasts off

	push	cx, si
	GetResourceHandleNS	WritePrimary, bx
	mov	si, offset WritePrimary
	mov	ax, MSG_GEN_DISPLAY_GET_MINIMIZED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;carry set if minimized
	pop	cx, si
	jc	done

	mov	ax, MSG_WRITE_APPLICATION_SET_BAR_STATE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

done:
	ret

WriteApplicationToolbarVisibility	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationUpdateMiscSettings --
		MSG_WRITE_APPLICATION_UPDATE_MISC_SETTINGS for WriteApplicationClass

DESCRIPTION:	Update misc settings 

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

	cx - Booleans currently selected
	bp - Booleans whose state have been modified

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationUpdateMiscSettings	method dynamic	WriteApplicationClass,
				MSG_WRITE_APPLICATION_UPDATE_MISC_SETTINGS
	GetResourceSegmentNS	dgroup, es
	mov	es:[miscSettings], cx
	mov_tr	ax, cx				;ax = selected booleans

	; if the "show invisibles" flag has changed then recalculate
	; all cached gstates

	test	bp, mask WMS_SHOW_INVISIBLES
	jz	noShowInvisiblesChange
	push	ax, bp

	; send a MSG_VIS_RECREATE_CACHED_GSTATES to all documents

	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;cx = event
	GetResourceHandleNS	WriteDocumentGroup, bx
	mov	si, offset WriteDocumentGroup
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	AIE_ObjMessageSend

	pop	ax, bp
noShowInvisiblesChange:

	; if the "display page and section" flag or the "show invisibles"
	; flag has changed then redraw all views

	test	bp, mask WMS_DISPLAY_SECTION_AND_PAGE or \
		    mask WMS_SHOW_INVISIBLES
	jz	noRedrawChange
	push	ax, bp
	GetResourceHandleNS	WriteViewControl, bx
	mov	si, offset WriteViewControl
	mov	ax, MSG_GVC_REDRAW
	call	AIE_ObjMessageSend
	pop	ax, bp
noRedrawChange:

	; if the "automatic layout recalc" flag has changed to ON then
	; recalculate as needed

	test	bp, mask WMS_AUTOMATIC_LAYOUT_RECALC
	jz	noRecalcChange
	push	ax, bp
	test	ax, mask WMS_AUTOMATIC_LAYOUT_RECALC
	pushf


	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jnz	10$
	mov	ax, MSG_GEN_SET_ENABLED
	GetResourceHandleNS	RecalcTrigger, bx
	mov	si, offset RecalcTrigger
	mov	dl, VUM_NOW
	call	AIE_ObjMessageSend
10$:

	popf
	jz	afterRecalc
	mov	ax, MSG_WRITE_DOCUMENT_RECALC_LAYOUT
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	GetResourceHandleNS	WriteDocumentGroup, bx
	mov	si, offset WriteDocumentGroup
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	AIE_ObjMessageSend
afterRecalc:
	pop	ax, bp
noRecalcChange:

	mov	si, offset WriteApp
	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset
	test	ds:[si].GAI_states, mask AS_ATTACHING
	jnz	exit			; no change when attaching
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	call	UserCallApplication
	pop	ax, cx, dx, bp
exit:

	ret

WriteApplicationUpdateMiscSettings	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationUpdateAppFeatures --
		MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
					for WriteApplicationClass

DESCRIPTION:	Update feature states

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

	ss:bp - GenAppUpdateFeaturesParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version
	sean	3/14/99		GlobalPC UI changes.

------------------------------------------------------------------------------@

; This table has an entry corresponding to each feature bit.  The entry is a
; point to the list of objects to turn on/off

if FULL_EXECUTE_IN_PLACE

AppInitExit ends

UsabilityTableSeg	segment	lmem	LMEM_TYPE_GENERAL

usabilityTable	fptr	\
	editFeaturesEntry,	;WF_EDIT_FEATURES
	simpleTextAttributesList, ;WF_SIMPLE_TEXT_ATTRIBUTES
	simplePageLayoutList,	;WF_SIMPLE_PAGE_LAYOUT
	simpleGraphicsLayerList, ;WF_SIMPLE_GRAPHICS_LAYER
	characterMenuList,	;WF_CHARACTER_MENU
	colorList,		;WF_COLOR

	graphicLayerList,	;WF_GRAPHICS_LAYER_ENTRY
	miscOptionsList,	;WF_MISC_OPTIONS
	complexTextAttributeList, ;WF_COMPLEX_TEXT_ATRIBUTES

	rulerControlList,	;WF_RULER_COLTROL
	complexPageLayoutList,	;WF_COMPLEX_PAGE_LAYOUT
	complexGraphicsList,	;WF_COMPLEX_TEXT_ATRIBUTES

	helpEditorList		;WF_HELP_EDITOR


editFeaturesEntry	label	GenAppUsabilityTuple
ifdef GPC  ; (always have search/replace)
	GenAppMakeUsabilityTuple WriteTextCountControl, end
else  ; always have Thesaurus
	GenAppMakeUsabilityTuple WriteSearchReplaceControl
	GenAppMakeUsabilityTuple WriteTextCountControl
;	GenAppMakeUsabilityTuple WriteThesaurusControl, end
endif

simpleTextAttributesList label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteTextStyleControl, recalc
	GenAppMakeUsabilityTuple InsertSubMenu
	GenAppMakeUsabilityTuple WriteMarginControl
	GenAppMakeUsabilityTuple WriteTabControl
	GenAppMakeUsabilityTuple BorderSubMenu
	GenAppMakeUsabilityTuple ShowToolsPopup
	GenAppMakeUsabilityTuple ShowStyleBarEntry, toolbar
	GenAppMakeUsabilityTuple WriteJustificationControl, popup
	GenAppMakeUsabilityTuple WriteLineSpacingControl, popup
	GenAppMakeUsabilityTuple WriteTextStyleSheetControl, end

simplePageLayoutList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple InnerPrintGroup
	GenAppMakeUsabilityTuple LayoutMenu
	GenAppMakeUsabilityTuple WritePageSizeControl
	GenAppMakeUsabilityTuple WritePageSetupDialog, end

simpleGraphicsLayerList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowDrawingToolsEntry, toolbar, end

characterMenuList	label	GenAppUsabilityTuple
ifdef GPC
	GenAppMakeUsabilityTuple WriteTextStyleControlGroup, reversed, reparent
else
	GenAppMakeUsabilityTuple WriteTextStyleControl, reversed, reparent
endif
	GenAppMakeUsabilityTuple CharacterMenu
	GenAppMakeUsabilityTuple StyleToolbar, restart, end

colorList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteParaBGColorControl
	GenAppMakeUsabilityTuple WriteCharFGColorControl
	GenAppMakeUsabilityTuple WriteCharBGColorControl
	GenAppMakeUsabilityTuple WriteBorderColorControl
	GenAppMakeUsabilityTuple WriteAreaColorControl, end


graphicLayerList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteInstructionPopup
	GenAppMakeUsabilityTuple WriteGrObjToolControl, recalc
	GenAppMakeUsabilityTuple ShowGraphicBarEntry, toolbar
if _BITMAP_EDITING
	GenAppMakeUsabilityTuple ShowBitmapToolsEntry, toolbar
endif
	GenAppMakeUsabilityTuple GraphicsMenu, end

miscOptionsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowFunctionBarEntry, toolbar
	GenAppMakeUsabilityTuple MiscSettingsPopup
	GenAppMakeUsabilityTuple WriteToolControl, end

complexTextAttributeList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ViewTypeSubGroup
	GenAppMakeUsabilityTuple InsertNumberMenu
	GenAppMakeUsabilityTuple InsertDateMenu
	GenAppMakeUsabilityTuple InsertTimeMenu
	GenAppMakeUsabilityTuple WriteFontAttrControl
	GenAppMakeUsabilityTuple WriteDefaultTabsControl
	GenAppMakeUsabilityTuple WriteParaAttrControl
	GenAppMakeUsabilityTuple WriteTextStyleControl, recalc
	GenAppMakeUsabilityTuple WriteLineSpacingControl, recalc
	GenAppMakeUsabilityTuple WriteParaSpacingControl
	GenAppMakeUsabilityTuple WriteBorderControl, recalc
	GenAppMakeUsabilityTuple WriteHyphenationControl
	GenAppMakeUsabilityTuple WritePageControl, recalc
	GenAppMakeUsabilityTuple WriteTextStyleSheetControl, recalc, end


rulerControlList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RulerPopup
	GenAppMakeUsabilityTuple RulerSubGroup
	GenAppMakeUsabilityTuple WriteTextRulerControl
	GenAppMakeUsabilityTuple WriteRulerShowControl
	GenAppMakeUsabilityTuple WriteRulerTypeControl, end

complexPageLayoutList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple HeaderFooterSubGroup, popup
	GenAppMakeUsabilityTuple TitlePageSubGroup, popup
	GenAppMakeUsabilityTuple PageSubMenu
	GenAppMakeUsabilityTuple SectionSubMenu
	GenAppMakeUsabilityTuple EditMasterPageTrigger

	GenAppMakeUsabilityTuple ConfirmationEntry
	GenAppMakeUsabilityTuple AutomaticLayoutRecalcEntry
	GenAppMakeUsabilityTuple DoNotDeletePagesWithGraphicsEntry
	GenAppMakeUsabilityTuple DTPModeEntry
	GenAppMakeUsabilityTuple DisplaySectionNameEntry
	GenAppMakeUsabilityTuple PasteGraphicsToCurrentLayerEntry
	GenAppMakeUsabilityTuple WriteGrObjObscureAttrControl
	GenAppMakeUsabilityTuple RecalcTrigger, end

complexGraphicsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteGrObjToolControl, recalc
	GenAppMakeUsabilityTuple GradientDialog
	GenAppMakeUsabilityTuple WriteGrObjStyleSheetControl

	GenAppMakeUsabilityTuple PolylinePopup
	GenAppMakeUsabilityTuple GrOptionsPopup

	GenAppMakeUsabilityTuple WriteTransformControl
	GenAppMakeUsabilityTuple WriteArcControl
	GenAppMakeUsabilityTuple PasteInsidePopup

	GenAppMakeUsabilityTuple WriteHideShowControl
	GenAppMakeUsabilityTuple WriteCustomDuplicateControl
	GenAppMakeUsabilityTuple AttributesPopup
	GenAppMakeUsabilityTuple WriteSkewControl
	GenAppMakeUsabilityTuple WriteConvertControl, end

helpEditorList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple InsertContextNumberMenu
	GenAppMakeUsabilityTuple HelpEditMenu, end

;---

levelTable		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteSearchReplaceControl, restart
;	GenAppMakeUsabilityTuple WriteSpellControl, restart
;	GenAppMakeUsabilityTuple SpellTools, restart
	GenAppMakeUsabilityTuple SearchReplaceTools, restart
	GenAppMakeUsabilityTuple WriteViewControl, recalc
	GenAppMakeUsabilityTuple WriteDisplayControl, recalc
	GenAppMakeUsabilityTuple WriteGrObjToolControl, recalc
	GenAppMakeUsabilityTuple WriteDocumentControl, recalc, end

;---

UsabilityTableSeg	ends

AppInitExit	segment	resource

else

usabilityTable	fptr	\
	editFeaturesEntry,	;WF_EDIT_FEATURES
	simpleTextAttributesList, ;WF_SIMPLE_TEXT_ATTRIBUTES
	simplePageLayoutList,	;WF_SIMPLE_PAGE_LAYOUT
	simpleGraphicsLayerList, ;WF_SIMPLE_GRAPHICS_LAYER
	characterMenuList,	;WF_CHARACTER_MENU
	colorList,		;WF_COLOR

	graphicLayerList,	;WF_GRAPHICS_LAYER_ENTRY
	miscOptionsList,	;WF_MISC_OPTIONS
	complexTextAttributeList, ;WF_COMPLEX_TEXT_ATRIBUTES

	rulerControlList,	;WF_RULER_COLTROL
	complexPageLayoutList,	;WF_COMPLEX_PAGE_LAYOUT
	complexGraphicsList,	;WF_COMPLEX_TEXT_ATRIBUTES

	helpEditorList		;WF_HELP_EDITOR


editFeaturesEntry	label	GenAppUsabilityTuple
ifdef GPC  ; (always have search/replace)
	GenAppMakeUsabilityTuple WriteTextCountControl, end
else  ; always have Thesaurus
	GenAppMakeUsabilityTuple WriteSearchReplaceControl
	GenAppMakeUsabilityTuple WriteTextCountControl
;	GenAppMakeUsabilityTuple WriteThesaurusControl, end
endif

simpleTextAttributesList label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteTextStyleControl, recalc
	GenAppMakeUsabilityTuple InsertSubMenu
	GenAppMakeUsabilityTuple WriteMarginControl
	GenAppMakeUsabilityTuple WriteTabControl
	GenAppMakeUsabilityTuple BorderSubMenu
	GenAppMakeUsabilityTuple ShowToolsPopup
	GenAppMakeUsabilityTuple ShowStyleBarEntry
	GenAppMakeUsabilityTuple WriteJustificationControl, popup
	GenAppMakeUsabilityTuple WriteLineSpacingControl, popup
	GenAppMakeUsabilityTuple WritePageControl
	GenAppMakeUsabilityTuple WriteTextStyleSheetControl, end

simplePageLayoutList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple InnerPrintGroup
	GenAppMakeUsabilityTuple LayoutMenu
	GenAppMakeUsabilityTuple WritePageSizeControl
	GenAppMakeUsabilityTuple WritePageSetupDialog, end

simpleGraphicsLayerList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowDrawingToolsEntry, end

characterMenuList	label	GenAppUsabilityTuple
ifdef GPC
	GenAppMakeUsabilityTuple WriteTextStyleControlGroup, reversed, reparent
else
	GenAppMakeUsabilityTuple WriteTextStyleControl, reversed, reparent
endif
	GenAppMakeUsabilityTuple CharacterMenu
	GenAppMakeUsabilityTuple StyleToolbar, restart, end

colorList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteParaBGColorControl
	GenAppMakeUsabilityTuple WriteCharFGColorControl
	GenAppMakeUsabilityTuple WriteCharBGColorControl
	GenAppMakeUsabilityTuple WriteBorderColorControl
	GenAppMakeUsabilityTuple WriteAreaColorControl, end


graphicLayerList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteInstructionPopup
	GenAppMakeUsabilityTuple ShowGraphicBarEntry, toolbar
if _BITMAP_EDITING
	GenAppMakeUsabilityTuple ShowBitmapToolsEntry, toolbar
endif
	GenAppMakeUsabilityTuple GraphicsMenu, end

miscOptionsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowFunctionBarEntry, toolbar
	GenAppMakeUsabilityTuple MiscSettingsPopup
	GenAppMakeUsabilityTuple WriteToolControl, end

complexTextAttributeList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ViewTypeSubGroup
	GenAppMakeUsabilityTuple InsertNumberMenu
	GenAppMakeUsabilityTuple InsertDateMenu
	GenAppMakeUsabilityTuple InsertTimeMenu
	GenAppMakeUsabilityTuple WriteFontAttrControl
	GenAppMakeUsabilityTuple WriteDefaultTabsControl
	GenAppMakeUsabilityTuple WriteParaAttrControl
	GenAppMakeUsabilityTuple WriteTextStyleControl, recalc
	GenAppMakeUsabilityTuple WriteLineSpacingControl, recalc
	GenAppMakeUsabilityTuple WriteParaSpacingControl
	GenAppMakeUsabilityTuple WriteBorderControl, recalc
	GenAppMakeUsabilityTuple WriteHyphenationControl
	GenAppMakeUsabilityTuple WritePageControl, recalc
	GenAppMakeUsabilityTuple WriteTextStyleSheetControl, recalc, end


rulerControlList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple RulerPopup
	GenAppMakeUsabilityTuple RulerSubGroup
	GenAppMakeUsabilityTuple WriteTextRulerControl
	GenAppMakeUsabilityTuple WriteRulerShowControl
	GenAppMakeUsabilityTuple WriteRulerTypeControl, end

complexPageLayoutList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple HeaderFooterSubGroup, popup
	GenAppMakeUsabilityTuple TitlePageSubGroup, popup
	GenAppMakeUsabilityTuple PageSubMenu

	GenAppMakeUsabilityTuple SectionSubMenu
	GenAppMakeUsabilityTuple EditMasterPageTrigger
	GenAppMakeUsabilityTuple ConfirmationEntry
	GenAppMakeUsabilityTuple AutomaticLayoutRecalcEntry
	GenAppMakeUsabilityTuple DoNotDeletePagesWithGraphicsEntry
	GenAppMakeUsabilityTuple DTPModeEntry
	GenAppMakeUsabilityTuple DisplaySectionNameEntry
	GenAppMakeUsabilityTuple PasteGraphicsToCurrentLayerEntry
	GenAppMakeUsabilityTuple WriteGrObjObscureAttrControl
	GenAppMakeUsabilityTuple RecalcTrigger, end

complexGraphicsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple GradientDialog
	GenAppMakeUsabilityTuple WriteGrObjStyleSheetControl
	GenAppMakeUsabilityTuple PolylinePopup
	GenAppMakeUsabilityTuple GrOptionsPopup
	GenAppMakeUsabilityTuple WriteTransformControl
	GenAppMakeUsabilityTuple WriteArcControl
	GenAppMakeUsabilityTuple PasteInsidePopup
	GenAppMakeUsabilityTuple WriteHideShowControl
	GenAppMakeUsabilityTuple WriteCustomDuplicateControl
	GenAppMakeUsabilityTuple AttributesPopup
	GenAppMakeUsabilityTuple WriteSkewControl
	GenAppMakeUsabilityTuple WriteConvertControl, end

helpEditorList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple HelpEditMenu, end

;---

levelTable		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WriteSearchReplaceControl, restart
;	GenAppMakeUsabilityTuple WriteSpellControl, restart
;	GenAppMakeUsabilityTuple SpellTools, restart
	GenAppMakeUsabilityTuple SearchReplaceTools, restart
	GenAppMakeUsabilityTuple WriteViewControl, recalc
	GenAppMakeUsabilityTuple WriteDisplayControl, recalc
	GenAppMakeUsabilityTuple WriteGrObjToolControl, recalc
	GenAppMakeUsabilityTuple WriteDocumentControl, recalc, end

;---

endif

WriteApplicationUpdateAppFeatures	method dynamic	WriteApplicationClass,
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

	GetResourceSegmentNS dgroup, es, TRASH_BX
	mov	es:[changingLevels], BB_TRUE

	; call general routine to update usability

if FULL_EXECUTE_IN_PLACE

	;
	; lock the block which contains the "usabilityTable"
	;
	mov	bx, handle UsabilityTableSeg	;bx = table block handle
	push	bx
	call	MemLock				;ax =  block seg
	mov	ss:[bp].GAUFP_table.segment, ax
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable
	mov	ss:[bp].GAUFP_levelTable.segment, ax
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	; We manually re-parent the font & point size controls here.
	; This MUST be done this way, because they would be unre-parented
	; to the wrong parent if we do it automatically.  And the styles
	; menu MUST be unre-parented automatically.  Sean 3/14/99.
	;
	test	ss:[bp].GAUFP_featuresChanged, mask WF_CHARACTER_MENU
	jz	continue
	push	dx
	mov	dx, mask WF_CHARACTER_MENU
	and	dx, ss:[bp].GAUFP_featuresOn
	call	ReparentFontPointSizeMenus
ifdef GPC
	call	ReparentCharColorControllers
endif
	pop	dx	
continue:

	GetResourceHandleNS	CharacterMenu, bx
	mov	ss:[bp].GAUFP_reparentObject.handle, bx
	mov	ss:[bp].GAUFP_reparentObject.offset, offset CharacterMenu

	;
	;  Handle "unreparenting" automatically
	;
	clrdw	ss:[bp].GAUFP_unReparentObject

	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock

	pop	bx				;bx = table block handle
	call	MemUnlock

else

	mov	ss:[bp].GAUFP_table.segment, cs
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable
	mov	ss:[bp].GAUFP_levelTable.segment, cs
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	; We manually re-parent the font & point size controls here.
	; This MUST be done this way, because they would be unre-parented
	; to the wrong parent if we do it automatically.  And the styles
	; menu MUST be unre-parented automatically.  Sean 3/14/99.
	;
	test	ss:[bp].GAUFP_featuresChanged, mask WF_CHARACTER_MENU
	jz	continue
	push	dx
	mov	dx, mask WF_CHARACTER_MENU
	and	dx, ss:[bp].GAUFP_featuresOn
	call	ReparentFontPointSizeMenus
ifdef GPC
	call	ReparentCharColorControllers
endif
	pop	dx	
continue:
	
	GetResourceHandleNS	CharacterMenu, bx
	mov	ss:[bp].GAUFP_reparentObject.handle, bx
	mov	ss:[bp].GAUFP_reparentObject.offset, offset CharacterMenu

	;
	;  Handle "unreparenting" automatically
	;
	clrdw	ss:[bp].GAUFP_unReparentObject

	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock

endif
	mov	es:[changingLevels], BB_FALSE

	ret

WriteApplicationUpdateAppFeatures	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationSetUserLevel --
		MSG_WRITE_APPLICATION_SET_USER_LEVEL for WriteApplicationClass

DESCRIPTION:	Set the user level

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

	ax - The message

	cx - user level (bits)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/16/92		Initial version
	sean	3/14/99		GlobalPC UI changes

------------------------------------------------------------------------------@
REPARENT_STYLE_BAR equ 0
REPARENT_DRAWING_TOOLS equ 1
WriteApplicationSetUserLevel	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_SET_USER_LEVEL

	mov	ax, cx				;ax <- new features

	; find the corresponding bar states and level

	push	si
	clr	di, bp
	mov	cx, (length settingsTable)	;cx <- # entries
	mov	dl, UIIL_INTRODUCTORY		;dl <- UIInterfaceLevel
	mov	dh, dl				;dh <- nearest so far (level)
	mov	si, 16				;si <- nearest so far (# bits)
findLoop:
	cmp	ax, cs:settingsTable[di].STE_features
	je	found
	push	ax, cx
	;
	; See how closely the features match what we're looking for
	;
	mov	bx, ax
	xor	bx, cs:settingsTable[di].STE_features
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
	add	di, (size SettingTableEntry)
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
	push	cs:settingsTable[di].STE_showBars
	push	dx
	mov	cx, ax				;cx <- features to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- UIInterfaceLevel to set
	push	cx
	mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
	call	ObjCallInstanceNoLock
	pop	dx
	call	UpdateRulerVisibility

	; Need to re-parent the GrObjToolsControl to show it in the style
	; bar if we're dismissing the drawing tools, or to put it on the
	; left side of the document (as a child of GrObjToolsToolbar) if
	; we're just showing these drawing tools.  This change corresponds
	; to a change from level 2<->3.  Sean 3/8/99.
	;
	mov	bx, REPARENT_STYLE_BAR
	cmp	dx, UIIL_BEGINNING 
	jle	reparentTools
	mov	bx, REPARENT_DRAWING_TOOLS
reparentTools:		
	call	ReparentGrObjTools
ifdef GPC		
	; update ParaBGColorControl for user level changes (must do here
	; instead of in tables since this is triggered off level change,
	; not feature change)
	push	si
	GetResourceHandleNS	WriteParaBGColorControl, bx
	mov	si, offset WriteParaBGColorControl
	mov	ax, MSG_GEN_CONTROL_REBUILD_NORMAL_UI
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_CONTROL_REBUILD_TOOLBOX_UI
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
endif

	pop	cx				;cx <- bar state

	; if we are attaching then don't change the toolbar states (so
	; that they are left the way the user set them)

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
	call	SetBarState
ifndef PRODUCT_NDO2000
	;
	; if not attaching, save after user level change
	;
	mov	ax, MSG_META_SAVE_OPTIONS
	call	UserCallApplication
endif
done:

	ret

WriteApplicationSetUserLevel	endm

WriteApplicationSetTemplateUserLevel	method	dynamic	WriteApplicationClass,
				MSG_GEN_APPLICATION_SET_TEMPLATE_USER_LEVEL
	mov	dx, INTRODUCTORY_FEATURES
	cmp	cx, UIIL_INTRODUCTORY
	je	gotFeatures
	mov	dx, BEGINNING_FEATURES
	cmp	cx, UIIL_BEGINNING
	je	gotFeatures
	mov	dx, INTERMEDIATE_FEATURES
	cmp	cx, UIIL_INTERMEDIATE
	je	gotFeatures
	mov	dx, ADVANCED_FEATURES
gotFeatures:
	mov	ax, MSG_WRITE_APPLICATION_SET_USER_LEVEL
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
WriteApplicationSetTemplateUserLevel	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateRulerVisibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the visibility of the rulers depending on the
		user level.  Level 1--don't show horizontal ruler.
		Level 2-4--show horizontal ruler.

CALLED BY:	WriteApplicationSetUserLevel
PASS:		dx	= user level
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Can change the state of the WriteRulerShowControl	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/08/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateRulerVisibility	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Don't show the horizontal ruler if we're at user level 1.
	;
	clr	cx
	cmp	dx, UIIL_INTRODUCTORY
	jle	updateRulers
	mov	cx, mask RSCA_SHOW_HORIZONTAL	; horizontal ruler level 2-4

	; Change the ruler's visibility
	;
updateRulers:
	mov	ax, MSG_RSCC_CHANGE_STATE
	GetResourceHandleNS	WriteRulerShowControl, bx
	mov	si, offset WriteRulerShowControl
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage			
		
	.leave
	ret
UpdateRulerVisibility	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReparentGrObjTools
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The GrObj tools are part of the Style toolbar in user
		levels 1 & 2, and they are part of the Drawing tools
		toolbar (along the left side of the document) for user
		levels 3 & 4.  This routine re-parents the drawing tools
		if necessary.

CALLED BY:	WriteApplicationUpdateBars
PASS:		bx	= REPARENT_STYLE_BAR (0) or REPARENT_DRAWING_TOOLS
			  this describes the NEW parent (i.e the parent we
			  will move the GrObjDrawingTools to).
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Re-parents the GrObjDrawingTools toolbar (either to either
		the StyleToolbar along the top, or the GrObjToolsToolbar
		which is along the left side of the document).

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/08/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReparentGrObjTools	proc	near

	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Compute who we want to be the current parent of the drawing tools
	; toolbar.
	;
	GetResourceHandleNS	StyleToolbar, dx
	mov	si, offset StyleToolbar	
	cmp	bx, REPARENT_STYLE_BAR
	jne	computedParent
	GetResourceHandleNS	GrObjToolsToolbar, dx
	mov	si, offset GrObjToolsToolbar
computedParent:
	mov	bx, dx			; ^lbx:si = optr of current parent 
		
	; See if the object is a child of the current parent.  If not,
	; then it is already a child of the correct parent--finished.
	;
	mov	ax, MSG_GEN_FIND_CHILD
	GetResourceHandleNS	GrObjDrawingTools, cx
	mov	dx, offset GrObjDrawingTools
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	jc	finished
	push	cx, dx, bx, si
		
	; Must set object not usable before removing it.
	;
	mov	ax, MSG_GEN_SET_NOT_USABLE
	movdw	bxsi, cxdx
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; Remove the drawing tools from the current parent
	;
	mov	ax, MSG_GEN_REMOVE_CHILD
	pop	cx, dx, bx, si
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; Compute the new parent, and add the drawing tools to
	; that parent.
	;
	mov	ax, MSG_GEN_ADD_CHILD
	GetResourceHandleNS	StyleToolbar, bp
	mov	di, offset StyleToolbar
	cmpdw	bxsi, bpdi
	jne	foundNewParent
	GetResourceHandleNS	GrObjToolsToolbar, bp
	mov	di, offset GrObjToolsToolbar
foundNewParent:
	movdw	bxsi, bpdi
	mov	bp, CCO_LAST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		

	; Make sure the drawing tools are visible (since we made them
	; not usable to remove them).
	;
	mov	ax, MSG_GEN_SET_USABLE
	movdw	bxsi, cxdx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
finished:
		
	.leave
	ret
ReparentGrObjTools	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReparentFontPointSizeMenus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-parents the font & point-size controllers.  In level 1,
		these menus are not available (only their toolbox UI),
		so they are children of a hidden dialog.  In level 2,
		(or whenever the character menu is visible) these
		controllers must be re-parented to the character menu.
		Here they display their menu (normal) UI.

CALLED BY:	WriteAppliationUpdateAppFeatures
PASS:		dx	= 0 if character menu disappearing
			= non-zero if character menu appearing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	WriteFontControl & WritePointSizeControl could be
		re-parented.  The two parents are the HiddenDialog(when
		the CharacterMenu is not visible) and the CharacterMenu.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/11/99    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReparentFontPointSizeMenus	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Compute who we want to be the current parent of the controllers
	; toolbar.
	;
	GetResourceHandleNS	CharacterMenu, bx
	mov	si, offset CharacterMenu	
	tst	dx
	jz	computedParent
	GetResourceHandleNS	HiddenDialog, bx
	mov	si, offset HiddenDialog
computedParent:
		
	; See if the object is a child of the current parent.  If not,
	; then it is already a child of the correct parent--finished.
	;
	mov	ax, MSG_GEN_FIND_CHILD
	GetResourceHandleNS	WriteFontControl, cx
	mov	dx, offset WriteFontControl
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
LONG	jc	finished
	push	cx, dx, bx, si
		
	; Must set objects not usable before removing it.
	;
	mov	ax, MSG_GEN_SET_NOT_USABLE
	movdw	bxsi, cxdx
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_SET_NOT_USABLE
	GetResourceHandleNS	WritePointSizeControl, bx
	mov	si, offset WritePointSizeControl
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; Remove the controllers from the current parent
	;
	mov	ax, MSG_GEN_REMOVE_CHILD
	pop	cx, dx, bx, si
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_REMOVE_CHILD
	GetResourceHandleNS	WritePointSizeControl, cx
	mov	dx, offset WritePointSizeControl
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		
		
	; Compute the new parent, and add the controllers to
	; that parent.
	;
	mov	ax, MSG_GEN_ADD_CHILD
	GetResourceHandleNS	CharacterMenu, bp
	mov	di, offset CharacterMenu
	cmpdw	bxsi, bpdi
	jne	foundNewParent
	GetResourceHandleNS	HiddenDialog, bp
	mov	di, offset HiddenDialog
foundNewParent:
	movdw	bxsi, bpdi
	mov	bp, CCO_FIRST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		

	mov	ax, MSG_GEN_ADD_CHILD
	GetResourceHandleNS	WriteFontControl, cx
	mov	dx, offset WriteFontControl
	mov	bp, CCO_FIRST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
		
	; Make sure the drawing tools are visible (since we made them
	; not usable to remove them).
	;
	mov	ax, MSG_GEN_SET_USABLE
	movdw	bxsi, cxdx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_SET_USABLE
	GetResourceHandleNS	WritePointSizeControl, bx
	mov	si, offset WritePointSizeControl
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
finished:
		
	.leave
	ret
ReparentFontPointSizeMenus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReparentCharColorControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-parents the character color controllers.  If there
		is a character menu, they are in there.  If there is no
		character menu, they are in the styles menu.

CALLED BY:	WriteAppliationUpdateAppFeatures
PASS:		dx	= 0 if character menu disappearing
			= non-zero if character menu appearing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/1/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC
ReparentCharColorControllers	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Compute who we want to be the current parent of the controllers
	; toolbar.
	;
	GetResourceHandleNS	CharacterMenu, bx
	mov	si, offset CharacterMenu	
	tst	dx
	jz	computedParent
	GetResourceHandleNS	WriteTextStyleControlGroup, bx
	mov	si, offset WriteTextStyleControlGroup
computedParent:
		
	; See if the object is a child of the current parent.  If not,
	; then it is already a child of the correct parent--finished.
	;
	mov	ax, MSG_GEN_FIND_CHILD
	GetResourceHandleNS	WriteCharBGColorControl, cx
	mov	dx, offset WriteCharBGColorControl
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
LONG	jc	finished
	push	cx, dx, bx, si
		
	; Must set objects not usable before removing it.
	;
	mov	ax, MSG_GEN_SET_NOT_USABLE
	movdw	bxsi, cxdx
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_SET_NOT_USABLE
	GetResourceHandleNS	WriteCharFGColorControl, bx
	mov	si, offset WriteCharFGColorControl
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; Remove the controllers from the current parent
	;
	mov	ax, MSG_GEN_REMOVE_CHILD
	pop	cx, dx, bx, si
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_REMOVE_CHILD
	GetResourceHandleNS	WriteCharFGColorControl, cx
	mov	dx, offset WriteCharFGColorControl
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		
		
	; Compute the new parent, and add the controllers to
	; that parent.
	;
	mov	ax, MSG_GEN_ADD_CHILD
	GetResourceHandleNS	CharacterMenu, bp
	mov	di, offset CharacterMenu
	cmpdw	bxsi, bpdi
	jne	foundNewParent
	GetResourceHandleNS	WriteTextStyleControlGroup, bp
	mov	di, offset WriteTextStyleControlGroup
foundNewParent:
	movdw	bxsi, bpdi
	mov	bp, CCO_LAST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		

	mov	ax, MSG_GEN_ADD_CHILD
	GetResourceHandleNS	WriteCharBGColorControl, cx
	mov	dx, offset WriteCharBGColorControl
	mov	bp, CCO_LAST
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
		
	; Make sure the drawing tools are visible (since we made them
	; not usable to remove them).
	;
	mov	ax, MSG_GEN_SET_USABLE
	movdw	bxsi, cxdx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_SET_USABLE
	GetResourceHandleNS	WriteCharFGColorControl, bx
	mov	si, offset WriteCharFGColorControl
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
finished:
		
	.leave
	ret
ReparentCharColorControllers	endp
endif

		



COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationChangeUserLevel --
		MSG_WRITE_APPLICATION_CHANGE_USER_LEVEL
						for WriteApplicationClass

DESCRIPTION:	User change to the user level

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
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationChangeUserLevel	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	ret

WriteApplicationChangeUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationCancelUserLevel --
		MSG_WRITE_APPLICATION_CANCEL_USER_LEVEL
						for WriteApplicationClass

DESCRIPTION:	Cancel User change to the user level

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
	Tony	11/16/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationCancelUserLevel	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_CANCEL_USER_LEVEL

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

WriteApplicationCancelUserLevel	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationQueryResetOptions --
		MSG_WRITE_APPLICATION_QUERY_RESET_OPTIONS
						for WriteApplicationClass

DESCRIPTION:	Make sure that the user wants to reset options

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
	Tony	11/24/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationQueryResetOptions	method dynamic	WriteApplicationClass,
				MSG_WRITE_APPLICATION_QUERY_RESET_OPTIONS

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
	mov	ax, CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION,0>
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

WriteApplicationQueryResetOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationUserLevelStatus --
		MSG_WRITE_APPLICATION_USER_LEVEL_STATUS
						for WriteApplicationClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of WriteApplicationClass

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
WriteApplicationUserLevelStatus	method dynamic	WriteApplicationClass,
				MSG_WRITE_APPLICATION_USER_LEVEL_STATUS

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, ADVANCED_FEATURES
	jz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_NOW
	GetResourceHandleNS	FineTuneTrigger, bx
	mov	si, offset FineTuneTrigger
	call	AIE_ObjMessageSend
	ret

WriteApplicationUserLevelStatus	endm
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationInitiateFineTune --
		MSG_WRITE_APPLICATION_INITIATE_FINE_TUNE
						for WriteApplicationClass

DESCRIPTION:	Bring up the fine tune dialog box

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
	Tony	9/22/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationInitiateFineTune	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_INITIATE_FINE_TUNE

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	AIE_ObjMessageCall			;ax = features

	mov_tr	cx, ax
	clr	dx
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	AIE_ObjMessageSend

	GetResourceHandleNS	FineTuneDialog, bx
	mov	si, offset FineTuneDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	AIE_ObjMessageSend

	ret

WriteApplicationInitiateFineTune	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteApplicationFineTune --
		MSG_WRITE_APPLICATION_FINE_TUNE for WriteApplicationClass

DESCRIPTION:	Set the fine tune settings

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
	Tony	9/22/92		Initial version

------------------------------------------------------------------------------@
WriteApplicationFineTune	method dynamic	WriteApplicationClass,
					MSG_WRITE_APPLICATION_FINE_TUNE

	; get fine tune settings

	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	call	AIE_GetBooleans			;ax = new features

	mov_tr	cx, ax				;cx = new features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	AIE_ObjMessageSend
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	AIE_ObjMessageSend

ifndef PRODUCT_NDO2000
	;
	; if not attaching, save after fine tune
	;
	mov	si, offset WriteApp
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GAI_states, mask AS_ATTACHING
	jnz	done
	mov	ax, MSG_META_SAVE_OPTIONS
	call	UserCallApplication
done:
endif

	ret

WriteApplicationFineTune	endm

AppInitExit ends
