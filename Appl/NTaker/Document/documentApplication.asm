COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentApplication.asm

AUTHOR:		Andrew Wilson, Nov  3, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 3/92		Initial revision

DESCRIPTION:
	Contains code for our subclass of the application object.	

	$Id: documentApplication.asm,v 1.1 97/04/04 16:17:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserLevelCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationLoadOptions -- MSG_META_LOAD_OPTIONS
						for NTakerApplicationClass

DESCRIPTION:	Open the app

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
    STE_showBars	NTakerToolbarStates
    STE_features	NTakerFeatures
SettingTableEntry	ends

settingsTable	SettingTableEntry	\
 <INTRODUCTORY_TOOLBAR_STATES, INTRODUCTORY_FEATURES>,
 <BEGINNING_TOOLBAR_STATES, BEGINNING_FEATURES>,
 <INTERMEDIATE_TOOLBAR_STATES, INTERMEDIATE_FEATURES>,
 <ADVANCED_TOOLBAR_STATES, ADVANCED_FEATURES>

featuresKey	char	"features", 0

;---

NTakerApplicationLoadOptions	method dynamic	NTakerApplicationClass,
							MSG_META_LOAD_OPTIONS,
							MSG_META_RESET_OPTIONS

	mov	di, offset NTakerApplicationClass
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
	jnc	exit

	; no .ini file settings -- set objects correctly based on level

	push	si

	call	UserGetDefaultLaunchLevel		;ax = UserLevel (0-3)
;	mov	bl, size SettingTableEntry
;	mul	bl
.assert	size SettingTableEntry eq 4
	shl	ax
	shl	ax
	mov_tr	di, ax				;calculate array offset

	push	cs:[settingsTable][di].STE_features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCall			;ax = selection
	pop	cx
	mov	es:[features], ax		;AX <- old features
	cmp	ax, cx
	jz	afterSetUserLevel
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageSend
	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	ObjMessageSend
afterSetUserLevel:

	mov	cx, cs:[settingsTable][di].STE_showBars
	call	SetToolbarState

	pop	si

exit:
	ret
NTakerApplicationLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerApplicationSetUserLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the user level in terms of feature bits.

CALLED BY:	GLOBAL
PASS:		cx - NTakerFeatures
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 3/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerApplicationSetUserLevel	method	dynamic NTakerApplicationClass,
				MSG_NTAKER_APPLICATION_SET_USER_LEVEL
	.enter
	mov_tr	ax, cx				;ax <- new features
	mov	es:[features], ax
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
countBits:					;Count the # bits different
	ror	bx, 1				; between the items
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
	mov_tr	cx, ax				;cx <- features to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_FEATURES
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- UIInterfaceLevel to set
	mov	ax, MSG_GEN_APPLICATION_SET_APP_LEVEL
	call	ObjCallInstanceNoLock
	pop	cx				;cx <- bar state
	call	SetToolbarState

;	Redo the UI on any open displays

	mov	ax, MSG_NTAKER_DISPLAY_REDO_UI
	GetResourceSegmentNS	NTakerDisplayClass, es
	mov	bx, es
	mov	si, offset NTakerDisplayClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				;CX <- gstate handle
	
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	GetResourceHandleNS	NTakerDispGroup, bx
	mov	si, offset NTakerDispGroup
	call	ObjMessageSend

;	Re-display the note list on any open documents

	mov	ax, MSG_NTAKER_DOC_CHANGE_FEATURES
	mov	bx, es
	mov	si, offset NTakerDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di

	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	GetResourceHandleNS	NTakerDocumentGroup, bx
	mov	si, offset NTakerDocumentGroup
	call	ObjMessageSend

	.leave
	ret
NTakerApplicationSetUserLevel	endp

ObjMessageSend	proc	near
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage
	ret
ObjMessageSend	endp

ObjMessageCall	proc	near
	mov	di, mask MF_FIXUP_DS  or mask MF_CALL
	call	ObjMessage
	ret
ObjMessageCall	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationChangeUserLevel --
		MSG_NTAKER_APPLICATION_CHANGE_USER_LEVEL
						for NTakerApplicationClass

DESCRIPTION:	User change to the user level

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationChangeUserLevel	method dynamic	NTakerApplicationClass,
					MSG_NTAKER_APPLICATION_CHANGE_USER_LEVEL

	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_APPLY
	GetResourceHandleNS	SetUserLevelDialog, bx
	mov	si, offset SetUserLevelDialog
	clr	di
	call	ObjMessage
	pop	si

	ret

NTakerApplicationChangeUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationCancelUserLevel --
		MSG_NTAKER_APPLICATION_CANCEL_USER_LEVEL
						for NTakerApplicationClass

DESCRIPTION:	Cancel User change to the user level

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationCancelUserLevel	method dynamic	NTakerApplicationClass,
					MSG_NTAKER_APPLICATION_CANCEL_USER_LEVEL

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

NTakerApplicationCancelUserLevel	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationQueryResetOptions --
		MSG_NTAKER_APPLICATION_QUERY_RESET_OPTIONS
						for NTakerApplicationClass

DESCRIPTION:	Make sure that the user wants to reset options

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationQueryResetOptions	method dynamic	NTakerApplicationClass,
				MSG_NTAKER_APPLICATION_QUERY_RESET_OPTIONS

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

NTakerApplicationQueryResetOptions	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationUserLevelStatus --
		MSG_NTAKER_APPLICATION_USER_LEVEL_STATUS
						for NTakerApplicationClass

DESCRIPTION:	Update the "Fine Tune" trigger

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationUserLevelStatus	method dynamic	NTakerApplicationClass,
				MSG_NTAKER_APPLICATION_USER_LEVEL_STATUS

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, ADVANCED_FEATURES
	jz	10$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	dl, VUM_NOW
	GetResourceHandleNS	FineTuneTrigger, bx
	mov	si, offset FineTuneTrigger
	clr	di
	GOTO	ObjMessage

NTakerApplicationUserLevelStatus	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationInitiateFineTune --
		MSG_NTAKER_APPLICATION_INITIATE_FINE_TUNE
						for NTakerApplicationClass

DESCRIPTION:	Bring up the fine tune dialog box

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationInitiateFineTune	method dynamic	NTakerApplicationClass,
					MSG_NTAKER_APPLICATION_INITIATE_FINE_TUNE

	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	ObjMessageCall			;ax = features

	mov_tr	cx, ax
	clr	dx
	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessageSend

	GetResourceHandleNS	FineTuneDialog, bx
	mov	si, offset FineTuneDialog
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageSend

	ret

NTakerApplicationInitiateFineTune	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationFineTune --
		MSG_NTAKER_APPLICATION_FINE_TUNE for NTakerApplicationClass

DESCRIPTION:	Set the fine tune settings

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationFineTune	method dynamic	NTakerApplicationClass,
					MSG_NTAKER_APPLICATION_FINE_TUNE

	; get fine tune settings

	GetResourceHandleNS	FeaturesList, bx
	mov	si, offset FeaturesList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjMessageCall			;ax = new features

	mov_tr	cx, ax				;cx = new features
	GetResourceHandleNS	UserLevelList, bx
	mov	si, offset UserLevelList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageSend

	mov	cx, 1					;mark modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	ObjMessageSend
	ret

NTakerApplicationFineTune	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationSetToolbarState --
		MSG_NTAKER_APPLICATION_SET_BAR_STATE for NTakerApplicationClass

DESCRIPTION:	Set the bar state

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationSetToolbarState	method dynamic	NTakerApplicationClass,
					MSG_NTAKER_APPLICATION_SET_TOOLBAR_STATE
	call	SetToolbarState
	ret

NTakerApplicationSetToolbarState	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetToolbarState

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
SetToolbarState	proc	near	uses si
	.enter

	push	cx
	GetResourceHandleNS	ShowBarList, bx
	mov	si, offset ShowBarList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjMessageCall			;ax = bits set
	pop	cx

	xor	ax, cx					;ax = bits changed
	jz	done					;Exit if none changed

	push	ax
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	call	ObjMessageSend
	pop	cx
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	ObjMessageSend
	mov	ax, MSG_GEN_APPLY
	call	ObjMessageSend
done:
	.leave
	ret

SetToolbarState	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationToolbarVisibility --
		MSG_NTAKER_APPLICATION_TOOLBAR_VISIBILITY
						for NTakerApplicationClass

DESCRIPTION:	Notification that the toolbar visibility has changed

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

	ax - The message

	cx - NTakerBarStates
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
NTakerApplicationToolbarVisibility	method dynamic	NTakerApplicationClass,
					MSG_NTAKER_APPLICATION_TOOLBAR_VISIBILITY

	test	ds:[di].GAI_states, mask AS_DETACHING
	jnz	done

	tst	bp				;if opening then bail
	jnz	done

	; if closing then we want to update the bar states appropriately

	mov	bp, cx
	mov	cx, ds:[di].NAI_toolbarStates		;cx = old
	not	bp
	and	cx, bp
	cmp	cx, ds:[di].NAI_toolbarStates
	jz	done

	; if we are iconifying then we don't want to turn the beasts off

	push	cx, si
	GetResourceHandleNS	NTakerPrimary, bx
	mov	si, offset NTakerPrimary
	mov	ax, MSG_GEN_DISPLAY_GET_MINIMIZED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;carry set if minimized
	pop	cx, si
	jc	done

	mov	ax, MSG_NTAKER_APPLICATION_SET_TOOLBAR_STATE
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

done:
	ret

NTakerApplicationToolbarVisibility	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationUpdateToolbars -- MSG_NTAKER_APPLICATION_UPDATE_TOOLBARS
						for NTakerApplicationClass

DESCRIPTION:	Update toolbar states

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
NTakerApplicationUpdateToolbars	method dynamic	NTakerApplicationClass,
					MSG_NTAKER_APPLICATION_UPDATE_TOOLBARS
EC <	test	cx, not mask NTakerToolbarStates			>
EC <	ERROR_NZ	-1						>

	mov	ds:[di].NAI_toolbarStates, cx
	mov_tr	ax, cx				;ax = new state

	test	bp, mask NTS_SHOW_TOOLBAR
	jz	noToolbarChange
	push	ax
	clr	cx				;never avoid popout update
	GetResourceHandleNS	NTakerIconBar, bx
	mov	di, offset NTakerIconBar
	test	ax, mask NTS_SHOW_TOOLBAR
	mov	ax, 0				;clear "parent is popout" flag
	call	updateToolbarUsability
	pop	ax
noToolbarChange:

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
	call	ObjMessageSend
	cmp	ax, MSG_GEN_SET_USABLE
	jnz	usabilityDone			;if not "set usable" then done
	tst	cx
	jnz	usabilityDone			;if avoid popout update flag
						;set then done

	tst	bp
	jz	afterParentFlag
	mov	ax, MSG_GEN_FIND_PARENT
	call	ObjMessageCall		;cxdx = parent
	movdw	bxsi, cxdx
afterParentFlag:
	mov	ax, MSG_GEN_INTERACTION_POP_IN
	call	ObjMessageSend

usabilityDone:
	pop	si
	pop	bp
	retn

NTakerApplicationUpdateToolbars	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerApplicationUpdateAppFeatures --
		MSG_GEN_APPLICATION_UPDATE_APP_FEATURES
					for NTakerApplicationClass

DESCRIPTION:	Update feature states

PASS:
	*ds:si - instance data
	es - segment of NTakerApplicationClass

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
	cardListList,	;NF_CARD_LIST
	keywordsList, 	;NF_KEYWORDS
	searchList,	;NF_SEARCH
	miscList,	;NF_MISC_OPTIONS
	toolList,	;NF_TOOLS
	topicList	;NF_CREATE_TOPICS

cardListList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple	StartupViewGroup
	GenAppMakeUsabilityTuple	ViewMenu, end
keywordsList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple	PrintKeywords	
	GenAppMakeUsabilityTuple	SearchKeywordBox, end

searchList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple	SearchSubGroup, end

miscList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple	DisplayDates, end

toolList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple	ShowToolbarEntry, toolbar
	GenAppMakeUsabilityTuple	NTakerToolControl, end
topicList	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple	PrintCurTopic, end

levelTable 	label	GenAppUsabilityTuple
	GenAppMakeUsabilityTuple	NTakerSearchControl, recalc	
	GenAppMakeUsabilityTuple	NTakerDisplayControl, recalc
	GenAppMakeUsabilityTuple	NTakerDocumentControl, recalc, end

NTakerApplicationUpdateAppFeatures	method dynamic	NTakerApplicationClass,
					MSG_GEN_APPLICATION_UPDATE_APP_FEATURES

	; call general routine to update usability

	mov	ss:[bp].GAUFP_table.segment, cs
	mov	ss:[bp].GAUFP_table.offset, offset usabilityTable
	mov	ss:[bp].GAUFP_tableLength, length usabilityTable
	mov	ss:[bp].GAUFP_levelTable.segment, cs
	mov	ss:[bp].GAUFP_levelTable.offset, offset levelTable

	;
	;  Handle "unreparenting" automatically
	;
	clrdw	ss:[bp].GAUFP_unReparentObject
	clrdw	ss:[bp].GAUFP_reparentObject

	mov	ax, MSG_GEN_APPLICATION_UPDATE_FEATURES_VIA_TABLE
	call	ObjCallInstanceNoLock

	ret

NTakerApplicationUpdateAppFeatures	endm

UserLevelCode	ends


