COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Levels (Sample PC GEOS application)
FILE:		levels.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the Levels application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: levels.asm,v 1.1 97/04/04 16:33:36 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include vm.def

include object.def
include graphics.def

include gstring.def
include initfile.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def
UseLib Objects/vTextC.def
UseLib Objects/styles.def
UseLib Objects/Text/tCtrlC.def

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

;
; NOTE:	Create states for each level (duplicate them if necessary) even if
;	your application doesn't support all of the levels.
;
LevelsBarStates	record
    LBS_SHOW_SNARF_BAR:1
    LBS_SHOW_ZONK_BAR:1
    :14
LevelsBarStates	end

INTRODUCTORY_BAR_STATES	= 0

BEGINNING_BAR_STATES	= mask LBS_SHOW_SNARF_BAR

INTERMEDIATE_BAR_STATES	= BEGINNING_BAR_STATES

ADVANCED_BAR_STATES	= INTERMEDIATE_BAR_STATES or \
			  mask LBS_SHOW_ZONK_BAR

DEFAULT_BAR_STATES	= ADVANCED_BAR_STATES

;---

;
; NOTE:	Create features for each level (duplicate them if necessary) even
;	if your application doesn't support all of the levels.
;
LevelsFeatures	record
    LF_FOO_FEATURES:1
    LF_DORF_STUFF:1
    LF_WHIFFLE_ATTRIBUTES:1
    LF_SIMPLE_TEXT:1		;for SET_FEATURES_IF_APP_FEATURE_OFF
    LF_COMPLEX_TEXT:1		;for SET_FEATURES_IF_APP_FEATURE_OFF
    LF_MORE_TEXT:1		;for ADD_FEATURES_IF_APP_FEATURE_ON
    :10
LevelsFeatures	end

INTRODUCTORY_FEATURES	=	0

BEGINNING_FEATURES	=	mask LF_FOO_FEATURES or \
				mask LF_SIMPLE_TEXT

INTERMEDIATE_FEATURES	=	BEGINNING_FEATURES or \
				mask LF_DORF_STUFF or \
				mask LF_COMPLEX_TEXT

ADVANCED_FEATURES	=	INTERMEDIATE_FEATURES or \
				mask LF_WHIFFLE_ATTRIBUTES or \
				mask LF_MORE_TEXT

DEFAULT_FEATURES	= ADVANCED_FEATURES

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

LevelsProcessClass	class	GenProcessClass
LevelsProcessClass	endc

LevelsApplicationClass	class	GenApplicationClass

MSG_LEVELS_APPLICATION_SET_USER_LEVEL		message
MSG_LEVELS_APPLICATION_INITIATE_FINE_TUNE	message
MSG_LEVELS_APPLICATION_FINE_TUNE		message
MSG_LEVELS_APPLICATION_UPDATE_BARS		message
MSG_LEVELS_APPLICATION_CHANGE_USER_LEVEL	message
MSG_LEVELS_APPLICATION_CANCEL_USER_LEVEL	message
MSG_LEVELS_APPLICATION_QUERY_RESET_OPTIONS	message
MSG_LEVELS_APPLICATION_USER_LEVEL_STATUS	message

    LAI_barStates	LevelsBarStates

LevelsApplicationClass	endc

idata	segment
	LevelsProcessClass	mask CLASSF_NEVER_SAVED
	LevelsApplicationClass
idata	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		levels.rdef

;------------------------------------------------------------------------------
;		Code for LevelsProcessClass
;------------------------------------------------------------------------------

AppInitExit	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationAttach -- MSG_META_ATTACH
						for LevelsApplicationClass

DESCRIPTION:	Deal with starting Levels app

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationAttach	method dynamic	LevelsApplicationClass, MSG_META_ATTACH

	push	ax, cx, dx, si, bp

	; set things that are solely dependent on the UI state

	call	UserGetInterfaceOptions
	test	ax, mask UIIO_OPTIONS_MENU
	jnz	keepOptionsMenu
	GetResourceHandleNS	OptionsMenu, bx
	mov	si, offset OptionsMenu
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	AIE_ObjMessageSend
keepOptionsMenu:

	pop	ax, cx, dx, si, bp
	mov	di, offset LevelsApplicationClass
	GOTO	ObjCallSuperNoLock

LevelsApplicationAttach	endm

;---

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

AIE_ObjMessageCall	proc	near
	push	di
	mov	di, mask MF_CALL
	call	AIE_ObjMessage
	pop	di
	ret
AIE_ObjMessageCall	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationLoadOptions -- MSG_META_LOAD_OPTIONS
						for LevelsApplicationClass

DESCRIPTION:	Open the app

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
    STE_showBars	LevelsBarStates
    STE_features	LevelsFeatures
SettingTableEntry	ends

settingsTable	SettingTableEntry	\
 <INTRODUCTORY_BAR_STATES, INTRODUCTORY_FEATURES>,
 <BEGINNING_BAR_STATES, BEGINNING_FEATURES>,
 <INTERMEDIATE_BAR_STATES, INTERMEDIATE_FEATURES>,
 <ADVANCED_BAR_STATES, ADVANCED_FEATURES>

featuresKey	char	"features", 0

;---

LevelsApplicationLoadOptions	method dynamic	LevelsApplicationClass,
							MSG_META_LOAD_OPTIONS,
							MSG_META_RESET_OPTIONS

	mov	di, offset LevelsApplicationClass
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

	; no .ini file settings -- set objects correctly based on level

	call	UserGetDefaultLaunchLevel	;ax = UserLevel (0-3)
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

done:
	ret

LevelsApplicationLoadOptions	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetBarState

DESCRIPTION:	Set the state of the "show bar" boolean group

CALLED BY:	INTERNAL

PASS:
	cx - new state

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/24/92		Initial version

------------------------------------------------------------------------------@
SetBarState	proc	near
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
	ret

SetBarState	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationUpdateBars -- MSG_LEVELS_APPLICATION_UPDATE_BARS
						for LevelsApplicationClass

DESCRIPTION:	Update toolbar states

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationUpdateBars	method dynamic	LevelsApplicationClass,
					MSG_LEVELS_APPLICATION_UPDATE_BARS

	mov	ds:[di].LAI_barStates, cx
	mov_tr	ax, cx

	test	bp, mask LBS_SHOW_SNARF_BAR
	jz	noSnarfBarChange
	push	ax
	GetResourceHandleNS	SnarfToolbar, bx
	mov	di, offset SnarfToolbar
	test	ax, mask LBS_SHOW_SNARF_BAR
	call	updateToolbarUsability
	pop	ax
noSnarfBarChange:

	test	bp, mask LBS_SHOW_ZONK_BAR
	jz	noZonkBarChange
	push	ax
	GetResourceHandleNS	ZonkToolbar, bx
	mov	di, offset ZonkToolbar
	test	ax, mask LBS_SHOW_ZONK_BAR
	call	updateToolbarUsability
	pop	ax
noZonkBarChange:

	ret

;---

	; pass:
	;	*ds:si - application object
	;	bxdi - toolbar
	;	zero flag - set for usable
	; destroy:
	;	ax, di

updateToolbarUsability:
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
	clr	di
	call	ObjMessage
	pop	si
	retn

LevelsApplicationUpdateBars	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationUpdateAppFeatures --
		MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
					for LevelsApplicationClass

DESCRIPTION:	Update feature states

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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

------------------------------------------------------------------------------@

; This table has an entry corresponding to each feature bit.  The entry is a
; point to the list of objects to turn on/off

usabilityTable	fptr	\
	fooFeaturesList,	;LF_FOO_FEATURES
	dorfStuffList,		;LF_DORF_STUFF
	whiffleAttributesList,	;LF_WHIFFLE_ATTRIBUTES
	simpleTextList,		;LF_SIMPLE_TEXT
	complexTextList,	;LF_COMPLEX_TEXT
	moreTextList		;LF_MORE_TEXT


fooFeaturesList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowSnarfBarEntry, toolbar
	GenAppMakeUsabilityTuple FooTrigger, end

dorfStuffList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ShowZonkBarEntry, toolbar
	GenAppMakeUsabilityTuple DorfTrigger, end

whiffleAttributesList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple WhiffleTrigger, end

;
; NOTE: for the StyleByFeature list, the same object uses different
; features specified with HINT_GEN_CONTROL_SCALABLE_UI_DATA.
; Because of this, it is marked as "recalc".
;
; The object "ByReparent" is marked such that:
; (1) if "simple text" is on, it is a direct menu
; (2) if "complex text" (and by implication, "simple text") it is a
;     sub-menu of "AMenu".
; The object "AMenu" is marked such that:
; (1) it only exists if "complex text" is on
simpleTextList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ByFeature, recalc, end

complexTextList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple AMenu
	GenAppMakeUsabilityTuple ByReparent, reversed, reparent
	GenAppMakeUsabilityTuple ByFeature, recalc, end

moreTextList		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ByFeature, recalc, end

;
; This table has an entry corresponding to each level (intro, beginning, etc.)
;
levelTable 		label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple ByLevel, recalc, end

;---

LevelsApplicationUpdateAppFeatures	method dynamic	LevelsApplicationClass,
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

	; call general routine to update usability

	mov	ss:[bp].GAUFP_table.segment, cs
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable
	mov	ss:[bp].GAUFP_levelTable.segment, cs
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	GetResourceHandleNS AMenu, bx
	mov	ss:[bp].GAUFP_reparentObject.handle, bx
	mov	ss:[bp].GAUFP_reparentObject.offset, offset AMenu
	clrdw	ss:[bp].GAUFP_unReparentObject

	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock

	ret

LevelsApplicationUpdateAppFeatures	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationSetUserLevel --
		MSG_LEVELS_APPLICATION_SET_USER_LEVEL for LevelsApplicationClass

DESCRIPTION:	Set the user level

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

	ax - The message

	cx - user level (as feature bits)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	NOTE: the user level set here is expressed in terms of feature bits

	NOTE:	The algorithm used to compute closest (non-exact) level
		match is based on the Levenshtein distance (obviously just
		using substitutions :-) (that's basically the minimum
		number of operations (e.g., substitutions) that it takes to
		transform the current feature bits into the requested
		bits).  Note that there's no bias or weighting of any
		particular bits over any others.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/16/92		Initial version

------------------------------------------------------------------------------@
LevelsApplicationSetUserLevel	method dynamic	LevelsApplicationClass,
					MSG_LEVELS_APPLICATION_SET_USER_LEVEL
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

	jae	nextEntry			;branch if not fewer difference
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
	mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- bar state
	call	SetBarState
	ret
LevelsApplicationSetUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationChangeUserLevel --
		MSG_LEVELS_APPLICATION_CHANGE_USER_LEVEL
						for LevelsApplicationClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationChangeUserLevel	method dynamic	LevelsApplicationClass,
					MSG_LEVELS_APPLICATION_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	clr	di
	call	ObjMessage
	pop	si

	ret

LevelsApplicationChangeUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationCancelUserLevel --
		MSG_LEVELS_APPLICATION_CANCEL_USER_LEVEL
						for LevelsApplicationClass

DESCRIPTION:	Cancel user change to the user level

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationCancelUserLevel	method dynamic	LevelsApplicationClass,
					MSG_LEVELS_APPLICATION_CANCEL_USER_LEVEL

	mov	cx, ds:[di].GAI_appFeatures

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	clr	di
	call	ObjMessage

	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	clr	di
	call	ObjMessage

	ret

LevelsApplicationCancelUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationQueryResetOptions --
		MSG_LEVELS_APPLICATION_QUERY_RESET_OPTIONS
						for LevelsApplicationClass

DESCRIPTION:	Make sure that the user wants to reset options

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationQueryResetOptions	method dynamic	LevelsApplicationClass,
				MSG_LEVELS_APPLICATION_QUERY_RESET_OPTIONS

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

LevelsApplicationQueryResetOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationUserLevelStatus --
		MSG_LEVELS_APPLICATION_USER_LEVEL_STATUS
						for LevelsApplicationClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationUserLevelStatus	method dynamic	LevelsApplicationClass,
				MSG_LEVELS_APPLICATION_USER_LEVEL_STATUS

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

LevelsApplicationUserLevelStatus	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationInitiateFineTune --
		MSG_LEVELS_APPLICATION_INITIATE_FINE_TUNE
						for LevelsApplicationClass

DESCRIPTION:	Bring up the fine tune dialog box

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationInitiateFineTune	method dynamic	LevelsApplicationClass,
					MSG_LEVELS_APPLICATION_INITIATE_FINE_TUNE

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

LevelsApplicationInitiateFineTune	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	LevelsApplicationFineTune --
		MSG_LEVELS_APPLICATION_FINE_TUNE for LevelsApplicationClass

DESCRIPTION:	Set the fine tune settings

PASS:
	*ds:si - instance data
	es - segment of LevelsApplicationClass

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
LevelsApplicationFineTune	method dynamic	LevelsApplicationClass,
					MSG_LEVELS_APPLICATION_FINE_TUNE

	; get fine tune settings

	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	AIE_ObjMessageCall		;ax = new features

	mov_tr	cx, ax				;cx = new features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	AIE_ObjMessageSend
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	AIE_ObjMessageSend
	ret

LevelsApplicationFineTune	endm

AppInitExit	ends
