COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CMain
FILE:		cmainPenInputControl.asm

AUTHOR:		David Litwin, Apr  8, 1994

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLPenInputControl	Open look pen input control class
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	4/ 8/94   	Initial revision
				this entire file was moved from the UI to
				the SPUI.  The old file was:
				/staff/pcgeos/Library/User/UI/uiPenInput.asm

DESCRIPTION:
	Code for the OLPenInputControlClass

	$Id: cmainPenInputControl.asm,v 1.1 97/04/07 10:52:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



CommonUIClassStructures segment resource

	OLPenInputControlClass	mask CLASSF_NEVER_SAVED or \
				mask CLASSF_DISCARD_ON_SAVE
if not _GRAFFITI_UI
	VisCachedGStateClass
	NotifyEnabledStateGenViewClass
endif

CommonUIClassStructures ends

;---------------------------------------------------

ControlCommon segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenPenInputControlInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the travel option of the object,
		and adds hints to keep object on screen.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/30/92	Initial version
	dlitwin	 4/18/94	Added call to superclass because we are
				built into a specific class now.
	dlitwin	4/27/94		Added in the code that used to be the
				handler of the ResolveVariantSuperclass,
				because that has a different purpose now
				that we are in the SPUI.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlInitialize	method	dynamic OLPenInputControlClass, 
				MSG_META_INITIALIZE

	;
	; Make the window stay above all other windows
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_WINDOW_PRIORITY
	mov	cx, size WinPriority
	call	ObjVarAddData
	mov	{WinPriority} ds:[bx], WIN_PRIO_POPUP+1

if _GRAFFITI_UI	and 0
;Graffiti shouldn't appear above sys modals - brianc 6/12/95
	;
	; Give the thing a custom layer priority so it shows up
	; in front of the password dialog box.  Also makes it show
	; up in front of error dialogs, including sysmodal ones.
	; So it goes.
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_LAYER_PRIORITY
	mov	cx, size LayerPriority
	call	ObjVarAddData
	mov	{WinPriority} ds:[bx], LAYER_PRIO_MODAL-1
endif
	;
	; Give the window a custom parent window (the system screen window)
	; so it'll stay above system modal dialogs. - Joon (7/8/94)
	;
	mov	ax, ATTR_GEN_WINDOW_CUSTOM_PARENT
	mov	cx, size hptr
	call	ObjVarAddData
	mov	{hptr.Window} ds:[bx], NULL	; system screen window

	;
	; Add various hints/attributes.
	;
	mov	ax, ATTR_GEN_WINDOW_ACCEPT_INK_EVEN_IF_NOT_FOCUSED
	clr	cx				; hint has no extra data
	call	ObjVarAddData
	mov	ax, HINT_TOOLBOX
	call	ObjVarAddData			; also has no extra data
	mov	ax, HINT_MINIMIZE_CHILD_SPACING
	call	ObjVarAddData			; also has no extra data
	mov	ax, HINT_CENTER_CHILDREN_HORIZONTALLY
	call	ObjVarAddData			; also has no extra data
	mov	ax, HINT_DISMISS_WHEN_DISABLED
	call	ObjVarAddData			; also has no extra data

if not _GRAFFITI_UI
if STYLUS_KEYBOARD
	mov	ax, HINT_KEEP_ENTIRELY_ONSCREEN
	call	ObjVarAddData			; also has no extra data
	mov	ax, HINT_WINDOW_MINIMIZE_TITLE_BAR
	call	ObjVarAddData			; also has no extra data
	mov	ax, HINT_WINDOW_ALWAYS_DRAW_WITH_FOCUS
	call	ObjVarAddData			; also has no extra data
	mov	ax, HINT_INITIAL_SIZE
	mov	cx, (size SpecWidth) + (size SpecHeight)
	call	ObjVarAddData
	mov	{word} ds:[bx], (SST_PIXELS shl offset SW_TYPE) or \
					STYLUS_BK_KEYBOARD_WIDTH
	mov	{word} ds:[bx+2], (SST_PIXELS shl offset SW_TYPE) or \
					STYLUS_BK_KEYBOARD_HEIGHT
	
else
	;
	; Put this hint on the box, to keep the box from being
	; forced onscreen every time it is brought up.
	;
	mov	ax, HINT_DONT_KEEP_INITIALLY_ONSCREEN or mask VDF_SAVE_TO_STATE
	call	ObjVarAddData			; also has no extra data
endif
endif

	;
	; Let our superclass do its thing
	;
	mov	ax, MSG_META_INITIALIZE
	mov	di, offset OLPenInputControlClass
	call	ObjCallSuperNoLock

	;
	; Set our block's output to the app focus so our keypresses go
	; to the right place.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	ds:[di].GCI_output, TO_APP_FOCUS

	;
	; If we are a developer defined PIC ('embedded') we will want to
	; skip putting ourselves on the active list.  Because embedded
	; keyboards aren't supported right now, we don't want the user
	; provided one to put itself on the list and then not take itself
	; off.
	;
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_IS_FLOATING_KEYBOARD
	call	ObjVarFindData
	jnc	setNotUsable

	;
	; Add the object to the active list, then send 
	; MSG_GEN_CONTROL_ADD_TO_GCN_LISTS so it'll add itself
	; to the appropriate GCNLists when it is restored from
	; state.  If we aren't on these lists a bunch of messages
	; won't get handled, and the keyboard won't come up.
	;
	; We do this here so that anyone using an embedded keyboard
	; won't have to worry about making sure it is on this list,
	; the object does it itself.
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].GCNLP_optr, cxsi
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST or mask GCNLTF_SAVE_TO_STATE
	call	UserCallApplication
	add	sp, size GCNListParams

	mov	ax, MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	call	ObjCallInstanceNoLock

exit:
	ret

setNotUsable:
	;
	; The only way to get here is if
	; ATTR_GEN_PEN_INPUT_CONTROL_IS_FLOATING_KEYBOARD is NOT set,
	; meaning that this is a user defined keyboard.
	;
	
	;
	; If we are a developer defined PIC ('embedded') we will want to
	; set ourselves not usable.  Because embedded keyboards aren't
	; supported right now, we don't want the user provided one to pop
	; up and conflict with the app generated one.
	;
	
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
	jmp	exit


OLPenInputControlInitialize	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	OLPenInputControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for OLPenInputControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of OLPenInputControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

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
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
OLPenInputControlGetInfo	method dynamic	OLPenInputControlClass,
					MSG_GEN_CONTROL_GET_INFO
	.enter

	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	si, offset GPIC_dupInfo
CheckHack <(GenControlBuildInfo and 1) eq 0>
	mov	cx, size GenControlBuildInfo / 2
	rep movsw

	.leave
	ret
OLPenInputControlGetInfo	endm

if PEN_INPUT_CONTROL_ALWAYS_ACTIVE
;add CUSTOM_ENABLE_DISABLE, ALWAYS_INTERACTABLE, and ALWAYS_UPDATE
GPIC_dupInfo	GenControlBuildInfo	<
	mask GCBF_CUSTOM_ENABLE_DISABLE				or \
	mask GCBF_ALWAYS_INTERACTABLE				or \
	mask GCBF_ALWAYS_UPDATE					or \
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST	or \
	mask GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED		or \
	mask GCBF_SPECIFIC_UI					or \
	mask GCBF_ALWAYS_ON_GCN_LIST				or \
	mask GCBF_IS_ON_ACTIVE_LIST				or \
	mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST,		; GCBI_flags
	GPIC_IniFileKey,		; GCBI_initFileKey
	GPIC_gcnList,			; GCBI_gcnList
	length GPIC_gcnList,		; GCBI_gcnCount
	GPIC_notifyTypeList,		; GCBI_notificationList
	length GPIC_notifyTypeList,	; GCBI_notificationCount
	GPICName,			; GCBI_controllerName

	handle GenPenInputControlUI,	; GCBI_dupBlock
	GPIC_childList,			; GCBI_childList
	length GPIC_childList,		; GCBI_childCount

	GPIC_featuresList,		; GCBI_featuresList
	length GPIC_featuresList,	; GCBI_featuresCount
	GPIC_DEFAULT_FEATURES,		; GCBI_features

	handle GenPenInputControlToolboxUI,	; GCBI_toolBlock
	GPIC_toolList,			; GCBI_toolList
	length GPIC_toolList,		; GCBI_toolCount
	GPIC_toolFeaturesList,		; GCBI_toolFeaturesList
	length GPIC_toolFeaturesList,	; GCBI_toolFeaturesCount
	GPIC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures
else
GPIC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST	or \
	mask GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED		or \
	mask GCBF_SPECIFIC_UI					or \
	mask GCBF_ALWAYS_ON_GCN_LIST				or \
	mask GCBF_IS_ON_ACTIVE_LIST				or \
	mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST,		; GCBI_flags
	GPIC_IniFileKey,		; GCBI_initFileKey
	GPIC_gcnList,			; GCBI_gcnList
	length GPIC_gcnList,		; GCBI_gcnCount
	GPIC_notifyTypeList,		; GCBI_notificationList
	length GPIC_notifyTypeList,	; GCBI_notificationCount
	GPICName,			; GCBI_controllerName

	handle GenPenInputControlUI,	; GCBI_dupBlock
	GPIC_childList,			; GCBI_childList
	length GPIC_childList,		; GCBI_childCount

	GPIC_featuresList,		; GCBI_featuresList
	length GPIC_featuresList,	; GCBI_featuresCount
	GPIC_DEFAULT_FEATURES,		; GCBI_features

	handle GenPenInputControlToolboxUI,	; GCBI_toolBlock
	GPIC_toolList,			; GCBI_toolList
	length GPIC_toolList,		; GCBI_toolCount
	GPIC_toolFeaturesList,		; GCBI_toolFeaturesList
	length GPIC_toolFeaturesList,	; GCBI_toolFeaturesCount
	GPIC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures
endif

if _FXIP
ControlInfoXIP	segment resource
endif

GPIC_IniFileKey	char	"penInputControl", 0

GPIC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_FOCUS_TEXT_OBJECT>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_CONTROLLERS_WITHIN_USER_DO_DIALOGS>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_FOCUS_WINDOW_KBD_STATUS>

GPIC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS>

;---

GPIC_childList	GenControlChildInfo	\
	<offset PenGroup, \
		mask GPICF_KEYBOARD or \
		mask GPICF_CHAR_TABLE or \
		mask GPICF_CHAR_TABLE_SYMBOLS or \
		mask GPICF_CHAR_TABLE_INTERNATIONAL or \
		mask GPICF_HWR_ENTRY_AREA or \
		mask GPICF_CHAR_TABLE_CUSTOM \
		, 0>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

if _GRAFFITI_UI
;no features for _GRAFFITI_UI
GPIC_featuresList	GenControlFeaturesInfo <>
else
GPIC_featuresList	GenControlFeaturesInfo \
	<offset TitleHWRGridItem, HWRGridName>,
	<offset TitleCharTableCustomItem, CharTableCustomName>,
	<offset TitleCharTableMathItem, CharTableMathName>,
	<offset TitleCharTableSymbolsItem, CharTableSymbolsName>,
	<offset TitleCharTableInternationalItem, CharTableInternationalName>,
	<offset TitleCharTableItem, CharTableName>,
	<offset TitleKeyboardItem, KeyboardName>
endif

;---

if _GRAFFITI_UI
;no tools for _GRAFFITI_UI
GPIC_toolList	GenControlChildInfo <>
else
GPIC_toolList	GenControlChildInfo	\
	<offset InitiateTrigger,
	mask GPICTF_INITIATE,
	mask GCCF_IS_DIRECTLY_A_FEATURE> 
endif

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

if _GRAFFITI_UI
;no tool features for _GRAFFITI_UI
GPIC_toolFeaturesList	GenControlFeaturesInfo <>
else
GPIC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset InitiateTrigger, InitiatePenInputName>
endif

if _FXIP
ControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlSetToDefaultPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the PIC to its default position.

CALLED BY:	MSG_GEN_PEN_INPUT_CONTROL_SET_TO_DEFAULT_POSITION
PASS:		*ds:si	= OLPenInputControlClass object
		cx	= width of field
RETURN:		nothing
DESTROYED:	cx

SIDE EFFECTS:
	Potentially (if non-stylus) leaves a MSG_GEN_SET_WIN_CONSTRAIN
	(with WCT_KEEP_PARTIALLY_VISIBLE) on the front of the queue, so
	if you are going to bring up the PIC, make sure you send your
	MSG_GEN_INTERACTION_INITIATE with MF_FORCE_QUEUE and
	MF_INSERT_AT_FRONT *after* this message is handled, so it will
	then insert itself on the queue before the win constrain can 
	take effect.

	Things need to be done this way because of how the UI Application
	code brings up the keyboard, so you are really better off sending
	a MSG_GEN_PEN_INPUT_CONTROL_BRING_UP_EMBEDDED_KEYBOARD.


PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI
OLPenInputControlSetToDefaultPosition	method dynamic OLPenInputControlClass, 
			MSG_GEN_PEN_INPUT_CONTROL_SET_TO_DEFAULT_POSITION
	uses	ax, dx, bp
	.enter

	mov	bx, ds:[LMBH_handle]
if not STYLUS_KEYBOARD
	;
	; If the position is -1, use the system default position
	; (centered horizontally at bottom of screen). We do this
	; by constraining the window to stay on screen, moving it
	; off the bottom edge of the screen, then unconstraining
	; the window.
	;
	mov	dl, VUM_MANUAL
	mov	dh, WCT_KEEP_VISIBLE
	mov	ax, MSG_GEN_SET_WIN_CONSTRAIN
	mov	di, mask MF_FIXUP_DS
	push	cx
	call	ObjMessage
	pop	cx
endif		; if (not STYLUS_KEYBOARD)

	;
	; Get the estimated width of keyboard for centering purposes
	;
IKBD <	push	es						>
IKBD <	segmov	es, dgroup, ax		;es = dgroup		>
IKBD <	cmp	es:[floatingKbdSize], KS_STANDARD		>
IKBD <	pop	es						>
IKBD <	mov	ax, STANDARD_GUESSTIMATE_OF_FLOATING_KBD_WIDTH	>
IKBD <	je	standard					>
IKBD <	mov	ax, ZOOMER_GUESSTIMATE_OF_FLOATING_KBD_WIDTH	>
IKBD <standard:							>
NOTIKBD<mov	ax, KEYBOARD_GUESSTIMATE_OF_FLOATING_KBD_WIDTH	>

	sub	cx, ax
	jns	positive
	clr	cx
positive:
	shr	cx, 1

	mov	dh, WPT_AT_SPECIFIC_POSITION
	mov	bp, 4000			;Off the bottom of the screen
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE

	mov	ax, MSG_GEN_SET_WIN_POSITION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

if not STYLUS_KEYBOARD
	;
	; We want the window to be constrained to the screen while
	; it comes up, then we want to nuke the constrain, so we
	; insert this message at the front of the queue, where it
	; will arrive after the box is brought up.  See BringUpKeyboard.
	; We don't bother if we aren't enabled though, as we want 
	; the constrain to be WCT_KEEP_VISIBLE when we initiate the
	; thing, and if we are disabled we aren't going to initiate
	; at this point.  When we do (later when being set enabled)
	; we will reset the winconstrain back.
	;
	mov	ax, MSG_GEN_GET_ENABLED
	call	ObjCallInstanceNoLock
	jnc	afterConstrainReset


	mov	ax, MSG_GEN_SET_WIN_CONSTRAIN
	mov	dx, (WCT_KEEP_PARTIALLY_VISIBLE shl 8) or VUM_MANUAL
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
afterConstrainReset:
endif		; if (not STYLUS_KEYBOARD)

	.leave
	ret
OLPenInputControlSetToDefaultPosition	endm
endif	; if (not _GRAFFITI_UI)



ControlCommon	ends





GenPenInputControlCode	segment	resource

if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI

ObjMessageFixupDS	proc	near
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	ret			
ObjMessageFixupDS	endp

ObjMessageCall	proc	near
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	ret			
ObjMessageCall	endp


if not STYLUS_KEYBOARD


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupCustomCharTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the data/moniker for the custom character table.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenPenInputControl object
		bx - child block
RETURN:		nada
DESTROYED:	cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupCustomCharTable	proc	near	uses	ax
	.enter

;	Setup the chartable information, if the custom char table exists.

	push	bx
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_CUSTOM_CHAR_TABLE_DATA
	call	ObjVarFindData			;ds:bx - ptr to extra data
EC <	ERROR_NC NO_CUSTOM_CHAR_TABLE_DATA				>
	movdw	dxbp, dsbx
	pop	bx

	;Add custom characters to the CharTableData structure
	push	si
	mov	ax, MSG_CHAR_TABLE_GET_CUSTOM_CHAR_TABLE_DATA
	mov	si, offset CharTableCustomObj	;^lBX:SI <- CharTableCustomObj
	call	ObjMessageFixupDS
	pop	si
	.leave
	ret
SetupCustomCharTable	endp

endif		; if (not STYLUS_KEYBOARD)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetermineStartupMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines which PenInputDisplayType should be active.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenPenInputControl object
		bx - child block
RETURN:		cx - PenInputDisplayType
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
keyName		char	"penInputDisplayType",0
category	char	"ui",0
DetermineStartupMode	proc	near	uses	ax, bx, dx, bp, di, si
	.enter

;	Check if the object has an attribute stating which item
;	to select.

	push	bx
	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_STARTUP_DISPLAY_TYPE
	call	ObjVarFindData
	mov	cx, ds:[bx]	
	pop	bx
	jc	common

;	Look in the .ini file for a default display to bring up.

	push	dx, ds, si
	segmov	ds, cs, cx
	mov	dx, offset keyName
	mov	si, offset category
	call	InitFileReadInteger
	mov_tr	cx, ax	
	pop	dx, ds, si
	jc	findFirst
common:	

EC <	cmp	cx, PenInputDisplayType				>
EC <	ERROR_AE	BAD_PEN_INPUT_DISPLAY_TYPE		>

;	Make sure that the desired identifier exists

	push	cx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	call	CallDisplayList
	pop	cx
	jc	exit		;Exit if item with identifier exists

	;
	; Either the desired identifier did not exist, or there was no
	; preference provided by the app, so just select the first one in
	; the list.
	; For Stylus just default to BigKeys, as we are in a situation
	; where our choices are fairly hardcoded.  Regular keyboard and 
	; HWR Grid can be turned on and off with feature bits, but the 
	; stylus specific stuff doesn't have feature bits. dlitwin 9/5/94
	;
findFirst:
if STYLUS_KEYBOARD
	mov	cx, PIDT_BIG_KEYS
else
	mov	ax, MSG_GEN_ITEM_GROUP_SCAN_ITEMS
	mov	cl, mask GSIF_FROM_START or mask GSIF_FORWARD
	clr	bp
	call	CallDisplayList			;Return AX = identifier to 
						; give the selection to
	mov_tr	cx, ax				;CX <- identifier of item to
						; select.
endif

exit:
	.leave
	ret
DetermineStartupMode	endp


if not STYLUS_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetObjectUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the passed object usable

CALLED BY:	GLOBAL
PASS:		^lBX:DX <- object
		DS - obj block
RETURN:		nada
DESTROYED:	cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/11/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetObjectUsable	proc	near	uses	ax, si
	.enter
	mov	ax, MSG_GEN_SET_USABLE
	mov	si, dx
	mov	dl, VUM_NOW
	call	ObjMessageFixupDS
	.leave
	ret
SetObjectUsable	endp
endif		; if (not STYLUS_KEYBOARD)
endif		; if (not _GRAFFITI_UI)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlGetMainView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the PenInputView.  For now there will always be a 
		main view (for all of the Motif and Stylus keyboards), but
		who knows in the future, so support for having no main view
		is in the API (carry set, null optr).

CALLED BY:	MSG_GEN_PEN_INPUT_CONTROL_GET_MAIN_VIEW
PASS:		*ds:si	= OLPenInputControlClass object
RETURN:		carry	= set if there is no main view
				^lcx:dx = null
			= clear if one exists:
				^lcx:dx = optr of main view
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlGetMainView	method dynamic OLPenInputControlClass, 
					MSG_GEN_PEN_INPUT_CONTROL_GET_MAIN_VIEW
if _GRAFFITI_UI
;return nothing for _GRAFFITI_UI
	clr	cx, dx
	stc
else
	uses	ax
	.enter

	call	PI_GetFeaturesAndChildBlock
	mov	cx, bx
	clr	dx
	stc
	jcxz	exit

	mov	dx, offset PenInputView
	clc

exit:
	.leave
endif
	ret
OLPenInputControlGetMainView	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We mess with the UI after it has been generated.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenPenInputControl object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLPenInputControlGenerateUI	method	OLPenInputControlClass,
				MSG_GEN_CONTROL_GENERATE_UI
	.enter

	;JEDI
if _GRAFFITI_UI
		push	ds
		mov	bx, handle ControlStrings	;^hbx = string block
		call	MemLock				;ax = string seg ptr
		mov	ds, ax				;ds = string seg ptr
		mov_tr	cx, ax				;cx = string seg ptr
		mov	bx, offset GraffitiName		;*ds:bx = str
		mov	bx, ds:[bx]			;ds:bx = str
		mov	dx, bx				;cx:dx = str
		pop	ds				;restore ds
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	bp, VUM_NOW
		call	ObjCallInstanceNoLock
		mov	bx, handle ControlStrings
		call	MemUnlock
endif		

if not _GRAFFITI_UI
	call	PI_GetFeaturesAndChildBlock
	tst	ax
	jz	exit

	call	DetermineStartupMode		;CX <- identifier of item to
						; give the selection to.

EC <	cmp	cx, PenInputDisplayType					>
EC <	ERROR_AE	CONTROLLER_OBJECT_INTERNAL_ERROR		>

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	CallDisplayList

	call	ForceApplyMsg
exit:
endif
	.leave
	ret
OLPenInputControlGenerateUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceApplyMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forces the display list to send out its apply message

CALLED BY:	GLOBAL
PASS:		bx <- child block
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/27/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI
ForceApplyMsg	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, TRUE
	call	CallDisplayList
	
	mov	ax,  MSG_GEN_APPLY
	GOTO	CallDisplayList
ForceApplyMsg	endp
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When we become interactable, check the status of the
		list and add the appropriate object.

CALLED BY:	GLOBAL
PASS:		*ds:si	= OLPenInputControlClass object
		es	= segment of OLPenInputControlClass (ui's dgroup)
		cx	= child block
		dx	= features mask 
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlTweakDuplicatedUI	method	OLPenInputControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	.enter

if _GRAFFITI_UI
	;
	; tell graffiti dialog to initialize itself
	; Routine below destroys ax, bx, di
	;
		push	cx, dx, si
if PEN_INPUT_CONTROL_ALWAYS_ACTIVE
	;
	; add GraffitiGroup (KeyboardControl) to active list
	;
		push	cx, si
		clr	bx
		call	GeodeGetAppObject		; ^lbx:si = app obj
		mov	dx, size GCNListParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST
		mov	ss:[bp].GCNLP_optr.handle, cx
		mov	ss:[bp].GCNLP_optr.offset, offset GraffitiGroup
		mov	ax, MSG_META_GCN_LIST_ADD
		mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage
		add	sp, size GCNListParams
		pop	cx, si
endif	; if PEN_INPUT_CONTROL_ALWAYS_ACTIVE
		mov	bx, cx
		mov	si, offset GraffitiGroup
		mov	ax, MSG_META_INITIALIZE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	cx, dx, si
endif	; if _GRAFFITI_UI

if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI
	;
	; Stylus doesn't do any of this crap, it just checks to see if 
	; the HWRGrid or VisKeyboard's feature bits are set and dynamically
	; substitutes their keys to switch to them with greyed out versions.
	;
if STYLUS_KEYBOARD
	call	StylusCheckForDisabledHWRGridOrVisKeyboard
else
	segmov	es, dgroup, ax
	mov	bx, cx
	mov	ax, dx

	tst	ax			;Exit if no features
	LONG jz	exit

IKBD <	call	InitPenInputControlUISizes				>

	;
	; If there is more than one feature enabled, set the tool bar usable.
	;
	push	ax
	
	clr	dx
	mov	cx, offset GPICF_KEYBOARD + 1	;CX <- # features
nextBit:
	shr	ax
	adc	dx, 0
	loop	nextBit			;DX <- # bits set
	pop	ax

	cmp	dx, 2			;If only one entry mode available,
	jb	noToolBar		; don't show any of the rest of the
					; junk.

;
;	Set the size of the HWR Grid object (it is smaller in dialog box
; 	controllers).
;

	test	ax, mask GPICF_HWR_ENTRY_AREA
	jz	noHWREntryArea
	push	ax, si
	mov	ax, MSG_VIS_SET_SIZE
	mov	si, offset HWRGridObj
IKBD_EC<call	ECCheckESDGroup						>
IKBD <	push	es							>
IKBD <	segmov	es, dgroup, cx						>
IKBD <	mov	cx, es:[charTableWidth]					>
IKBD <	mov	dx, es:[hwrGridHeight]					>
IKBD <	add	dx, es:[hwrGridVerticalMargin]				>
IKBD <	add	dx, 2							>
IKBD <	pop	es							>
NOTIKBD<mov	cx, FLOATING_KEYBOARD_MAX_WIDTH				>
NOTIKBD<mov	dx, KEYBOARD_HWR_GRID_HEIGHT + KEYBOARD_HWR_GRID_VERTICAL_MARGIN + 2 >
	call	ObjMessageFixupDS
	pop	ax, si


noHWREntryArea:


;	Add the TitlePenToolGroup to the controller, and set it usable (it must
;	be a direct child of the controller, or else it won't appear in the
;	correct place).
;
	push	ax
	mov	ax, MSG_GEN_ADD_CHILD
	mov	cx, bx
	mov	dx, offset TitlePenToolGroup
	mov	bp, CCO_LAST
	call	ObjCallInstanceNoLock
	pop	ax

setUsable:
	call	SetObjectUsable
noToolBar:
	test	ax, mask GPICF_CHAR_TABLE_CUSTOM
	jz	noCharTable

	call	SetupCustomCharTable

noCharTable:
	test	ax, mask GPICF_HWR_ENTRY_AREA
	jz	noHWRGrid

	push	si
	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	mov	cx, mask VTSF_MULTIPLE_CHAR_ATTRS
	mov	si, offset HWRContextObj
	call	ObjMessageFixupDS
	pop	si

	;
	; Set the doc bounds of the view - we do this explicitly because we
	; may be figuring out the geometry now.
	;
noHWRGrid:
	call	DetermineStartupMode		;CX <- identifier of item to
						; give the selection to.
EC <	cmp	cx, PenInputDisplayType					>
EC <	ERROR_AE	CONTROLLER_OBJECT_INTERNAL_ERROR		>

IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	dx, es:[charTableHeight]				>
IKBD <	inc	dx							>
NOTIKBD<mov	dx, FLOATING_KEYBOARD_MAX_HEIGHT			>
	cmp	cx, PIDT_HWR_ENTRY_AREA
	jne	setBounds
IKBD <	mov	dx, es:[hwrGridHeight]					>
IKBD <	add	dx, es:[hwrGridVerticalMargin]				>
IKBD <	add	dx, 3							>
NOTIKBD<mov	dx, KEYBOARD_HWR_GRID_HEIGHT+KEYBOARD_HWR_GRID_VERTICAL_MARGIN+3 >

setBounds:
IKBD_EC<call	ECCheckESDGroup						>
IKBD <	mov	cx, es:[charTableWidth]					>
NOTIKBD<mov	cx, FLOATING_KEYBOARD_MAX_WIDTH				>
	mov	si, offset PenInputView
	clr	di				; no fixup DS or ES
	call	GenViewSetSimpleBounds
exit:

endif		; endif if of else of if STYLUS_KEYBOARD

endif		; if (not _GRAFFITI_UI)

	.leave
	ret
OLPenInputControlTweakDuplicatedUI	endp


if STYLUS_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StylusCheckForDisabledHWRGridOrVisKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stylus doesn't do any of this crap, it just checks to
		see if the HWRGrid or VisKeyboard's feature bits are
		set and dynamically substitutes their keys to switch
		to them with greyed out versions.

CALLED BY:	OLPenInputControlTweakDuplicatedUI

PASS:		cx	= childblock
		dx	= features mask
RETURN:		nothing
DESTROYED:	bx, di, si

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StylusCheckForDisabledHWRGridOrVisKeyboard	proc	near
	uses	ax, cx, dx, bp
	.enter

	mov	bx, cx				; put childblock in bx
	test	dx, mask GPICF_HWR_ENTRY_AREA
	jnz	skipHWRStuff

	push	dx
	mov	ax, MSG_VIS_KEYMAP_ADD_SUBSTITUTE_CHAR
SBCS <	mov	dx, (CS_CONTROL shl 8) or C_CTRL_G ; normal HWRGrid	>
						   ; special char 
DBCS <	mov	dx, C_SYS_CTRL_G					>
SBCS <	mov	bp, (CS_CONTROL shl 8) or C_CTRL_V ; greyed HWRGrid	>
						   ; special char
DBCS <	mov	bp, C_SYS_CTRL_V					>
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	StylusSendToKeymaps

	mov	ax, MSG_META_ADD_VAR_DATA
	mov	dx, size AddVarDataParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].AVDP_dataType, ATTR_VIS_KEYBOARD_NO_HWR_GRID
	clr	ss:[bp].AVDP_dataSize
	mov	si, offset KeyboardObj
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size AddVarDataParams
	pop	dx

skipHWRStuff:
	test	dx, mask GPICF_KEYBOARD
	jnz	exit

	mov	ax, MSG_VIS_KEYMAP_ADD_SUBSTITUTE_CHAR
SBCS <	mov	dx, (CS_CONTROL shl 8) or C_CTRL_D ; normal Keyboard	>
						   ; spec. char 
DBCS <	mov	dx, C_SYS_CTRL_D					>
SBCS <	mov	bp, (CS_CONTROL shl 8) or C_CTRL_U ; greyed Keyboard	>
						   ; spec. char
DBCS <	mov	bp, C_SYS_CTRL_U					>
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	StylusSendToKeymaps

exit:
	.leave
	ret
StylusCheckForDisabledHWRGridOrVisKeyboard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StylusSendToKeymaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all the various VisKeymapClass objects

CALLED BY:	StylusCheckForDisabledHWRGridOrVisKeyboard

PASS:		ax	= Message
		bx	= childblock
		dx,bp= data to pass
		di	= MessageFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, si

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StylusSendToKeymaps	proc	near
	.enter

	mov	si, offset VisKeymapObjectsTable

loopTop:
	tst	<{word} cs:[si]>
	jz	exit

	push	ax, cx, dx, bp, si, di
	mov	si, cs:[si]			; get lptr of VisKeymapClass obj
	call	ObjMessage
	pop	ax, cx, dx, bp, si, di
	inc	si
	inc	si				; next lptr
	jmp	loopTop

exit:
	.leave
	ret
StylusSendToKeymaps	endp


VisKeymapObjectsTable	lptr \
	offset BigKeysObj,
	offset NumbersObj,
	offset PunctuationObj,
	offset HWRGridPICGadgetsKeymap,
	0

endif		; if STYLUS_KEYBOARD

if INITFILE_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPenInputControlUISizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are checking our initfile for the type of keyboard
		we want (standard (bullet) or Zoomer), we may have to change
		the constants that are set up in the block of UI we
		duplicated.  It defaults to standard, so if our .ini file
		says standard we don't have to do anything.  If the .ini file
		says Zoomer, we update these objects to have Zoomer constants.

CALLED BY:	OLPenInputControlTweakDuplicatedUI

PASS:		es	= dgroup
		^hbx	= block of UI to tweak
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPenInputControlUISizes	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
EC <	call	ECCheckESDGroup						>
	cmp	es:[floatingKbdSize], KS_STANDARD
LONG	je	exit

EC<	cmp	es:[floatingKbdSize], KS_ZOOMER				>
EC<	ERROR_NE	ERROR_PEN_INPUT_CONTROL_BAD_KEYBOARD_SIZE	>

	;
	; Set the fixed sizes of the PenGroup and HWRContextGroup
	; to the Zoomer constants.
	;
	mov	dx, size SetSizeArgs
	sub	sp, dx
	mov	bp, sp
	clr	ss:[bp].SSA_width
	mov	ss:[bp].SSA_height, \
			SpecHeight <SST_PIXELS, ZOOMER_CHAR_TABLE_HEIGHT+1>
	clr	ss:[bp].SSA_count
	mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_UI_QUEUE

	mov	ax, MSG_GEN_SET_FIXED_SIZE
	; bx is passed in as the handle to the block of UI to tweak
	mov	si, offset PenGroup
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ss:[bp].SSA_width, \
			SpecWidth<SST_PIXELS, ZOOMER_CHAR_TABLE_WIDTH>
	clr	ss:[bp].SSA_height

	mov	si, offset HWRContextGroup
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, dx

	;
	; Set the vis bounds and fonts of the VisKeyboard,
	; VisHWRGrid and CharTable objects
	;
	mov	ax, MSG_VIS_KEYBOARD_SET_TO_ZOOMER_SIZE
	mov	si, offset KeyboardObj
	call	ObjMessageFixupDS

	mov	ax, MSG_VIS_HWR_GRID_SET_TO_ZOOMER_SIZE
	mov	si, offset HWRGridObj
	call	ObjMessageFixupDS

	mov	bp, offset VisCharTableObjectTable
	mov	si, cs:[bp]
	mov	ax, MSG_VIS_CHAR_TABLE_SET_TO_ZOOMER_SIZE

loopTop:
	call	ObjMessageFixupDS
	inc	bp
	inc	bp		; next lptr
	mov	si, cs:[bp]
	tst	si
	jnz	loopTop

exit:
	.leave
	ret
InitPenInputControlUISizes	endp

VisCharTableObjectTable	lptr	\
	CharTableObj,
	CharTableSymbolsObj,
	CharTableInternationalObj,
	CharTableMathObj,
	CharTableCustomObj,
	0

endif		; if INITFILE_KEYBOARD


if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddCorrectDisplayObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the correct display to this object.

CALLED BY:	GLOBAL
PASS:		bx - block of children
		cx - PenInputDisplayType
RETURN:		nada
DESTROYED:	ax, cx, dx, bp, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddCorrectDisplayObj	proc	near

;	Ensure that no objects have been added to the content yet

	mov	si, offset PenInputContent	;^lBX:SI <- VisContent
EC <	push	cx						>
EC <	mov	ax, MSG_VIS_COUNT_CHILDREN			>
EC <	call	ObjMessageCall					>
EC <	tst	dx						>
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR	>
EC <	pop	cx						>
EC <	cmp	cx, PenInputDisplayType				>
EC <	ERROR_AE	BAD_PEN_INPUT_DISPLAY_TYPE		>

;	Add the appropriate child to the view and make it visible

	mov	di, cx
	shl	di				;DI <- offset into table of
						; object to add
	mov	cx, bx				;^lCX:DX <- child to add
	mov	dx, cs:[childTable][di]
EC <	tst	dx						>
EC <	ERROR_Z	BAD_PEN_INPUT_DISPLAY_TYPE			>

	mov	ax, MSG_VIS_ADD_CHILD
	mov	bp, CCO_FIRST shl offset CCF_REFERENCE
	call	ObjMessageFixupDS

	mov	ax, MSG_VIS_MARK_INVALID
	movdw	bxsi, cxdx
	mov	cl,	mask VOF_GEOMETRY_INVALID or \
			mask VOF_WINDOW_INVALID or \
			mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	GOTO	ObjMessageFixupDS
AddCorrectDisplayObj	endp


if STYLUS_KEYBOARD
childTable	lptr	\
	KeyboardObj,
	0,
	0,
	0,
	0,
	0,
	HWRGridObj,
	BigKeysObj,
	NumbersObj,
	PunctuationObj,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0
else


childTable	lptr	\
	KeyboardObj,
	CharTableObj,
	CharTableSymbolsObj,
	CharTableInternationalObj,
	CharTableMathObj,
	CharTableCustomObj,
	HWRGridObj,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0,
	0

endif			; if _STYLUS_KEYBOARD

.assert( (length childTable) eq PenInputDisplayType)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlSetDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the display of the pen input control to the current
		one.

CALLED BY:	GLOBAL
PASS:		*ds:si	= OLPenInputControlClass
		cx	= PenInputDisplayType of object to add
RETURN:		nada
DESTROYED:	ax, bx, dx, bp, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlSetDisplay	method	OLPenInputControlClass,
				MSG_GEN_PEN_INPUT_CONTROL_SET_DISPLAY
	.enter
EC <	cmp	cx, PenInputDisplayType					>
EC <	ERROR_AE	BAD_PEN_INPUT_DISPLAY_TYPE			>

	mov	bp, si			; bp = self lptr

	call	PI_GetFeaturesAndChildBlock

	test	ax, mask GPICF_KEYBOARD or mask GPICF_CHAR_TABLE or mask GPICF_CHAR_TABLE_SYMBOLS or mask GPICF_CHAR_TABLE_INTERNATIONAL or mask GPICF_HWR_ENTRY_AREA or mask GPICF_CHAR_TABLE_CUSTOM

	jz	exit

if STYLUS_KEYBOARD
	;
	; Set the PIDT in the UI, because that is what everyone cares
	; about. (Stylus only, because for everyone else they just change
	; the UI itself to change keyboards).  dlitwin 7/26/94
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	CallDisplayList
	pop	ax, cx, dx, bp
endif		; if STYLUS_KEYBOARD


	;
	; Set the various gen objects associated with the HWR Grid
	; usable, if they exist.
	;
	test	ax, mask GPICF_HWR_ENTRY_AREA
	jz	skipHWREntry
		

	push	ax, cx, bp

	mov	ax, MSG_GEN_SET_NOT_USABLE
	cmp	cx, PIDT_HWR_ENTRY_AREA
	jnz	setNotUsable

	mov	ax, MSG_GEN_SET_USABLE

	;
	;Set the PenToolGroup usable/not usable when
	;we switch to/from the HWR Grid display.
	;
setNotUsable:
	mov	si, offset PenToolGroup
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageFixupDS

	mov	si, offset HWRContextGroup
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageFixupDS

	mov	si, offset HWRGridTools
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageFixupDS

	pop	ax, cx, bp
		
	;
	; Remove any existing displays
	; First, find the first (only) child of the content
	;
skipHWREntry:
	push	cx
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	clr	cx				;Find first child
	mov	si, offset PenInputContent	;^lBX:SI <- VisContent
	push	bp				; save self lptr
	call	ObjMessageCall			;^lCX:DX <- Vis Child
	pop	bp				; bp = self lptr
	jc	noChildren

	;
	; Remove the child.
	;
	mov	ax, MSG_VIS_REMOVE
	movdw	bxsi, cxdx
	mov	dl, VUM_MANUAL
	call	ObjMessageFixupDS

noChildren:
	pop	cx

	;
	; Add the display object
	;
	push	cx

	push	bp				; preserve our obj lptr
	call	AddCorrectDisplayObj
	pop	si				; restore our obj lptr

	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	pop	cx		; cx = PenInputDisplayType

	;
	; tell Flow object whether or not the window should now receive
	;   ink input
	sub	cx, PIDT_HWR_ENTRY_AREA	; cx = zero if HWR, non-zero if others
	clr	di			; send message
	call	RegisterNoInkWin

exit:
	.leave
	ret
OLPenInputControlSetDisplay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PI_GetFeaturesAndChildBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the features and childBlock of the PenInputControl.

CALLED BY:	OLPenInputControlSetDisplay

PASS:		*ds:si	= OLPenInputControlClass
RETURN:		ax	= features of the PIC
		bx	= hptr of UI block
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/11/94    	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PI_GetFeaturesAndChildBlock	proc	near
	.enter

EC <	push	es, di							>
EC <	mov	di, segment OLPenInputControlClass			>
EC <	mov	es, di							>
EC <	mov	di, offset OLPenInputControlClass			>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	CONTROLLER_OBJECT_INTERNAL_ERROR		>
EC <	pop	es, di							>
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock

	.leave
	ret
PI_GetFeaturesAndChildBlock	endp
endif	; if (not _GRAFFITI_UI)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallDisplayList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the current display list.

CALLED BY:	GLOBAL
PASS:		ax, cx, dx, bp - message params
		bx - child block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI
CallDisplayList	proc	near	uses	si
	.enter
EC <	call	ECCheckMemHandle					>
	mov	si, offset TitlePenDisplayList
	call	ObjMessageCall
	.leave
	ret
CallDisplayList	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlGetDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the currently displayed keyboard

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		cx	- PenInputDisplayType
		carry	- set on error, cx = invalid
DESTROYED:	ax, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/01/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlGetDisplay	method	OLPenInputControlClass,
					MSG_GEN_PEN_INPUT_CONTROL_GET_DISPLAY
if _GRAFFITI_UI
	;
	; return GRAFFITI type
	;
	mov	cx, PIDT_GRAFFITI
	clc
else
	.enter

	; Ask child for the current keyboard
	;
	call	PI_GetFeaturesAndChildBlock
	tst	bx
	stc
	jz	exit

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	CallDisplayList
	mov_tr	cx, ax				; CX <- PenInputDisplayType
	clc
exit:
	.leave
endif
	ret
OLPenInputControlGetDisplay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlAddToGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the floating keyboard from any GCN lists it may
		reside on.

CALLED BY:	GLOBAL
PASS:		*ds:si - OLPenInputControlClass object
		ax - message #
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	No need to call our superclass, as we are implemented in
	the SPUI and our superclass won't have anything to do with
	controllers.  We only get called through the magic of the
	Controller's GCBF_SPECIFIC_UI flag.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/16/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlAddToGCNLists	method OLPenInputControlClass,
				MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	.enter

	;
	; The floating keyboard resides on the "ALWAYS_INTERACTABLE"
	; GCN list, so the user can click on it while modal boxes are
	; on screen.
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].GCNLP_optr, cxsi
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS
	call	UserCallApplication
	add	sp, size GCNListParams

	.leave
	ret
OLPenInputControlAddToGCNLists	endp



if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlMoveResizeWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method notifies the currently focused window whenever

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/20/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlMoveResizeWin	method	OLPenInputControlClass,
					MSG_VIS_MOVE_RESIZE_WIN
	mov	di, offset OLPenInputControlClass
	call	ObjCallSuperNoLock

	;
	; We are the floating keyboard, so get the position of the window
	; and inform the focus window, so they can move us to our correct
	; position when they get the focus.
	;
	mov	ax, MSG_VIS_GET_POSITION
 	call	ObjCallInstanceNoLock		;CX <- left edge of box
						;DX <- top edge of box

	push	si
	mov	ax, MSG_GEN_SET_KBD_POSITION
	clrdw	bxsi
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	si

	mov	cx, di
	mov	dx, TO_APP_FOCUS
	mov	ax, MSG_META_SEND_CLASSED_EVENT
	GOTO	ObjCallInstanceNoLock
OLPenInputControlMoveResizeWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCachedGStateVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles vis open (allocates a cached gstate)

CALLED BY:	GLOBAL
PASS:		stuff for vis open
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCachedGStateVisOpen	method	VisCachedGStateClass, MSG_VIS_OPEN
	.enter

	mov	di, offset VisCachedGStateClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallSuperNoLock
	jnc	exit				;If no gstate available

	mov	di, ds:[si]
	add	di, ds:[di].VisCachedGState_offset
	mov	ds:[di].VCGSI_gstate, bp
exit:
	.leave
	ret
VisCachedGStateVisOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisCachedGStateVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles vis close (allocates a cached gstate)

CALLED BY:	GLOBAL
PASS:		stuff for vis close
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisCachedGStateVisClose	method	VisCachedGStateClass, MSG_VIS_CLOSE

	mov	di, offset VisCachedGStateClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].VisCachedGState_offset
	clr	ax
	xchg	ax, ds:[di].VCGSI_gstate
	tst	ax
	jz	exit
	mov_tr	di, ax	
	GOTO	GrDestroyState

exit:
	ret
VisCachedGStateVisClose	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyEnabledStateGenViewSpecNotifyEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the view becomes enabled, it sets the enabled flag on
		the content.

CALLED BY:	GLOBAL
PASS:		*ds:si	= GenView object
RETURN:		carry	= set if visual state changed
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyEnabledStateGenViewSpecNotifyEnabled method NotifyEnabledStateGenViewClass,
				MSG_SPEC_NOTIFY_ENABLED,
				MSG_SPEC_NOTIFY_NOT_ENABLED
	.enter

	mov	di, offset NotifyEnabledStateGenViewClass
	call	ObjCallSuperNoLock
	jnc	noStateChange			;If we aren't changing our
						; enabled state, branch

	mov	di, ds:[si]
	add	di, ds:[di].GenView_offset
	movdw	bxsi, ds:[di].GVI_content
	mov	ax, MSG_VIS_INVALIDATE
	mov	dl, VUM_NOW
	call	ObjMessageFixupDS
	stc					;Signify that we are changing
						; our fully-enabled state
noStateChange:
	.leave
	ret
NotifyEnabledStateGenViewSpecNotifyEnabled	endp

endif	; if (not _GRAFFITI_UI)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlScanFeatureHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This nukes all features if the system is not pen based.

CALLED BY:	GLOBAL
PASS:		cx - GenControlUIType
		dx:bp - ptr to GenControlScanInfo struct to fill in
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlScanFeatureHints	method	OLPenInputControlClass, 
				MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
	.enter

	mov	es, dx
	mov	di, bp

	mov	ax, ATTR_GEN_PEN_INPUT_CONTROL_MAKE_VISIBLE_ON_ALL_SYSTEMS
	call	ObjVarFindData
	jc	exit

	call	FlowGetUIButtonFlags
	test	al, mask UIBF_NO_KEYBOARD
	jnz	exit

	call	UserGetFloatingKbdEnabledStatus
	tst	ax
	jnz	exit

;	We are not pen based, so nuke the features

	mov	es:[di].GCSI_appProhibited, mask GPICToolboxFeatures
	cmp	cx, GCUIT_TOOLBOX
	jz	exit
	mov	es:[di].GCSI_appProhibited, mask GPICFeatures
exit:
	.leave
	ret
OLPenInputControlScanFeatureHints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPICVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles vis open (add keyboard window to no-ink list) and
		changing the window layer if starting up from state so
		we don't come up behind everything.

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= OLPenInputControlClass object
		ds:di	= OLPenInputControlClass instance data
		ds:bx	= OLPenInputControlClass object (same as *ds:si)
		es 	= segment of OLPenInputControlClass
		ax	= message #
		bp	= 0 if top window, else window for object to open on
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If not using HWR grid, add keyboard window to no-ink list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPICVisOpen	method dynamic OLPenInputControlClass, 
					MSG_VIS_OPEN
	.enter

	push	si
	mov	di, offset OLPenInputControlClass
	call	ObjCallSuperNoLock

if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI

	; add view's window to no-ink list if not using HWR grid
	mov	ax, MSG_GEN_PEN_INPUT_CONTROL_GET_DISPLAY
	call	ObjCallInstanceNoLock	; rtn cx = PenInputDisplayType
	jc	afterHWRWinStuff

	sub	cx, PIDT_HWR_ENTRY_AREA
	je	afterHWRWinStuff

	clr	di
	call	RegisterNoInkWin

afterHWRWinStuff:

endif

	pop	si
	mov	ax, MSG_GEN_APPLICATION_GET_STATE
	call	UserCallApplication
	test	ax, mask AS_ATTACHING
	jz	exit

	mov	ax, MSG_VIS_QUERY_WINDOW
	call	ObjCallInstanceNoLock
	mov	di, cx
	mov	si, WIT_PARENT_WIN
	call	WinGetInfo
	mov	di, ax

	mov	ax, mask WPF_LAYER or 0		; leave priority alone
	call	GeodeGetProcessHandle
	mov	dx, bx
	call	WinChangePriority
exit:
	.leave
	ret
OLPICVisOpen	endm

if not _GRAFFITI_UI
;not needed for _GRAFFITI_UI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPICVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles vis close (remove keyboard window from no-ink list)

CALLED BY:	MSG_VIS_CLOSE
PASS:		*ds:si	= OLPenInputControlClass object
		ds:di	= OLPenInputControlClass instance data
		ds:bx	= OLPenInputControlClass object (same as *ds:si)
		es 	= segment of OLPenInputControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If not using HWR grid, remove keyboard window from no-ink list.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPICVisClose	method dynamic OLPenInputControlClass, 
					MSG_VIS_CLOSE

	; if we're using HWR grid, no need to remove window because it wasn't
	;   on the list anyway.  (No need to waste time.)
	mov	ax, MSG_GEN_PEN_INPUT_CONTROL_GET_DISPLAY
	call	ObjCallInstanceNoLock	; rtn cx = PenInputDisplayType
	jc	noNeedToRemove

	sub	cx, PIDT_HWR_ENTRY_AREA
	je	noNeedToRemove		; no need to remove if HWR grid

	; remove view's window from list
	push	si			; save self lptr
	clr	cx			; remove from list
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
				; make it a call such that passed
				;   handle remains valid when this msg
				;   reaches Flow object
	call	RegisterNoInkWin

	pop	si			; *ds:si = self

noNeedToRemove:
	mov	ax, MSG_VIS_CLOSE
	mov	di, offset OLPenInputControlClass
	GOTO	ObjCallSuperNoLock

OLPICVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegisterNoInkWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add/remove window from no-ink list maintained by flow object

CALLED BY:	INTERNAL, OLPenInputControlSetDisplay, OLPICVisOpen,
		OLPICVisClose
PASS:		*ds:si	= OLPenInputControlClass object
		cx	= non-zero to add, zero to remove
		di	= MessageFlags to pass to UserCallFlow
RETURN:		nothing
DESTROYED:	bx, si
		May destroy: ax, cx, dx, bp, ds, es (depends on passed di)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If the window for the keyboard is not build out yet, skip adding.
	(This happens sometimes when the OLPenInputControl object receives
	MSG_GEN_PEN_INPUT_CONTROL_SET_DISPLAY before MSG_VIS_OPEN.)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RegisterNoInkWin	proc	near

	push	cx, di

	; get view's window that keyboard is in
	call	PI_GetFeaturesAndChildBlock	; rtn bx = child block hptr
	mov	si, offset PenInputView
	mov	ax, MSG_GEN_VIEW_GET_WINDOW
	call	ObjMessageCall		; rtn cx = window handle

	mov	ax, MSG_FLOW_REGISTER_NO_INK_WIN
	mov	bp, cx			; bp = window handle
	pop	cx, di

	; Sometimes MSG_GEN_PEN_INPUT_CONTROL_SET_DISPLAY is received before
	;   the window is built out when the keyboard first comes on screen.
	;   If this is the case, just skip adding.  The window will be added
	;   when MSG_VIS_OPEN is handled later anyway.
	tst	bp
	jz	done			; window not built yet, skip.

	call	UserCallFlow

done:
	ret
RegisterNoInkWin	endp


if not STYLUS_KEYBOARD

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlResetConstrain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In Motif we set up a WinConstrainType of "always on screen"
		so when we position at the bottom of the screen it will
		be just where we want it (i.e. not hanging off the screen).
		Before we initiate it again we need to remove this constrain,
		so it can once again be moved off screen by the user.  Stylus
		doesn't use this because it is permanently on screen.

CALLED BY:	MSG_GEN_PEN_INPUT_CONTROL_RESET_CONSTRAIN
PASS:		*ds:si	= OLPenInputControlClass object
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlResetConstrain	method dynamic OLPenInputControlClass, 
				MSG_GEN_PEN_INPUT_CONTROL_RESET_CONSTRAIN
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_SET_WIN_CONSTRAIN
	mov	dx, (WCT_KEEP_PARTIALLY_VISIBLE shl 8) or VUM_MANUAL
	call	ObjCallInstanceNoLock

	.leave
	ret
OLPenInputControlResetConstrain	endm
endif		 ; if (not STYLUS_KEYBOARD)

endif	; if (not _GRAFFITI_UI)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from the active list.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= OLPenInputControlClass object
		ds:di	= OLPenInputControlClass instance data
		es 	= segment of OLPenInputControlClass
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlDetach	method dynamic OLPenInputControlClass, 
					MSG_META_DETACH
	uses	ax, cx, dx, bp
	.enter

	;
	; Remove ourselves from any GCNLists we are on.  We have the
	; GCBF_ALWAYS_ON_GCN_LIST set so we aren't removed from these
	; lists when just being set not interactable, but this time
	; we really do want to be removed, so we send the message manually
	; because the GenControl handler will check the flag and leave
	; us on otherwise.
	;
	mov	ax, MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
	call	ObjCallInstanceNoLock

	.leave

	mov	di, offset OLPenInputControlClass
	call	ObjCallSuperNoLock

	ret
OLPenInputControlDetach	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLPenInputControlRemoveFromGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the object from the active list.  The active list
		isn't like the normal lists that can be set up in the
		GenControlBuildInfo structure, and so we have to add it
		and remove it manually, so we do so when the others are
		being removed.


CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= OLPenInputControlClass object
		es 	= segment of OLPenInputControlClass
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	No need to call our superclass, as we are implemented in
	the SPUI and our superclass won't have anything to do with
	controllers.  We only get called through the magic of the
	Controller's GCBF_SPECIFIC_UI flag.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLPenInputControlRemoveFromGCNLists	method dynamic OLPenInputControlClass, 
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].GCNLP_optr, cxsi
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, MGCNLT_ACTIVE_LIST or mask GCNLTF_SAVE_TO_STATE
	call	UserCallApplication

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, size GCNListParams
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS
	call	UserCallApplication
	add	sp, size GCNListParams

	.leave
	ret
OLPenInputControlRemoveFromGCNLists	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoxedInteractionVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw box around interaction if monochrome display

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= BoxedInteractionClass object
		ds:di	= BoxedInteractionClass instance data
		ds:bx	= BoxedInteractionClass object (same as *ds:si)
		es 	= segment of BoxedInteractionClass
		ax	= message #
		cl	= DrawFlags: DF_EXPOSED set if GState is set to
			  update window
		^hbp	= GState to draw through.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/12/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenPenInputControlCode ends
