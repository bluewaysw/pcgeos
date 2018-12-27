COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Text library
MODULE:		UI
FILE:		uiSpell.asm

AUTHOR:		Andrew Wilson, Mar 11, 1992

    INT GetFeaturesAndChildBlock Return group

    GLB UpdateUIFromSpellState	Updates the UI from the selection state.

    GLB DisableFeatureObj	Disable the object if the feature is
				available.

    GLB DisableObj		Disable the object if the feature is
				available.

    GLB EnableFeatureObj	Enable the object if the feature is
				available.

    GLB EnableObj		Enable the object if the feature is
				available.

    GLB ObjMessageCallFixupDS	Just a space saver for a standard call to
				ObjMessage.

    GLB SpellGetICBuff		Gets the ICBuff stored in the instance data
				(or allocates one if one doesn't exist).

    GLB EditGetICBuff		Gets the ICBuff stored in the instance data
				(or allocates one if one doesn't exist).

    GLB GetICBuffCommon		Gets an ICBuff for the caller

    GLB ContinueSpellCheck	Sends a MSG_SC_CHECK to the output of the
				object with the appropriate parameters.

    GLB SetNumCharsAndSendSpellCheckToOutput Sends a MSG_SC_CHECK to the
				output of the object with the appropriate
				parameters.

    GLB SendMethodSpellCheckToOutput This methods sends MSG_SPELL_CHECK out
				to the current output.

    GLB DisableReplaceTriggers	Disables the replace triggers.

    GLB DisableSuggestions	Disables the suggestion list/box.

    GLB EnableSuggestions	Enables the suggestion list/box.

    GLB GiveDefaultToTrigger	This routine gives the default to the
				passed trigger.

    GLB SetStatusLine		Sets the status line of the text.

    GLB SendToSuggestionList	Sends the passed message to the suggestion
				list

    GLB GetUnknownWord		Gets the unknown word from the object

    GLB ReplaceCommon		This routine gets the text from the
				replacement text object, and sends it out
				with the passed method to the output.

    GLB CheckIfFlagActive	Returns ax=-1 if flag exists and is set to
				true in ini file.

    GLB AdjustWordForAAnError	Converts the first "a" or "an" in the
				"unknown" string into its complement.

    GLB CheckIsWhitespace	Returns carry set if passed char is
				whitespace

    GLB AdjustWordForDoubleWordError Nukes everything beyond the first word
				in the string.

    GLB DisplaySpellStatus	Displays the spell status in the status
				line.

    GLB ResetIgnoreBufferIfDesired Resets the ignore buffer if the
				"resetIgnoreListWhenBoxCloses" flag is set.

    GLB SpellPutupBox		This routine puts up a standard error
				dialog box containing the passed text.

    GLB CheckIfLowercase	Just a front end to the DR_LOCAL_IS_LOWER
				function.

    GLB CheckIfUppercase	Just a front end to the DR_LOCAL_IS_UPPER
				function.

    GLB GetStringCaseInfo	This routine returns StringCaseInfo for the
				passed string.

    GLB CreateSearchReplaceStruct This routine creates a search/replace
				structure.

    GLB AddGeometryHint		Adds a geometry hint to the passed object.

    GLB AppendEllipsis		Appends an ellipsis char to the passed text
				object

    GLB DestroyBXSI		Destroys the passed object

    GLB HighlightSelection	Highlights the "selection" in the passed
				context-display text object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/11/92		Initial revision

DESCRIPTION:
	This file contains routines to implement SpellControlClass

	$Id: uiSpell.asm,v 1.1 97/04/07 11:08:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpellClassStructures	segment	resource
	SpellControlClass	
SpellClassStructures	ends


SpellControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	SpellControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for SpellControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of SpellControlClass

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
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
SpellControlGetInfo	method dynamic	SpellControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep	movsb
	ret
SpellControlGetInfo	endm

SC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	offset SC_IniFileKey,		; GCBI_initFileKey
	offset SC_gcnList,		; GCBI_gcnList
	length SC_gcnList,		; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	SCName,				; GCBI_controllerName

	handle SpellControlUI,		; GCBI_dupBlock
	offset SC_childList,		; GCBI_childList
	length SC_childList,		; GCBI_childCount
	offset SC_featuresList,		; GCBI_featuresList
	length SC_featuresList,		; GCBI_featuresCount
	SC_DEFAULT_FEATURES,		; GCBI_features

	handle SpellControlToolboxUI,	; GCBI_toolBlock
	offset SC_toolList,		; GCBI_toolList
	length SC_toolList,		; GCBI_toolCount
	offset SC_toolFeaturesList,	; GCBI_toolFeaturesList
	length SC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	SC_helpContext>			; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
SpellControlInfoXIP	segment	resource
endif

SC_helpContext	char	"dbSpell", 0


SC_IniFileKey	char	"spell", 0

SC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>

;---

ifdef GPC_SPELL
SC_childList	GenControlChildInfo	\
	<offset SpellReplyBar, mask SF_CLOSE or mask SF_CHECK_TO_END, 0>,
	<offset SpellTopGroup, mask SF_STATUS or mask SF_CONTEXT or mask SF_ADD_TO_USER_DICTIONARY or mask SF_EDIT_USER_DICTIONARY, 0>,
	<offset SpellBottomGroup, mask SF_SUGGESTIONS, 0>,
	<offset SpellTriggerGroup, mask SF_SKIP or mask SF_SKIP_ALL or mask SF_REPLACE_CURRENT or mask SF_REPLACE_ALL, 0>,
	<offset SpellCheckToEndTrigger, mask SF_CHECK_TO_END, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpellCloseTrigger, mask SF_CLOSE, mask GCCF_IS_DIRECTLY_A_FEATURE>
else
SC_childList	GenControlChildInfo	\
	<offset SpellReplyBar, mask SF_CLOSE or mask SF_CHECK_ALL or mask SF_CHECK_TO_END or mask SF_CHECK_SELECTION or mask SF_SUGGESTIONS, 0>,	
	<offset SpellStatusText, mask SF_STATUS, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpellContext, mask SF_CONTEXT, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpellMiscGroup, mask SF_REPLACE_CURRENT or mask SF_REPLACE_ALL, 0>,
	<offset SpellTriggerGroup, mask SF_SKIP or mask SF_SKIP_ALL or mask SF_REPLACE_CURRENT or mask SF_REPLACE_ALL or mask SF_SUGGESTIONS or mask SF_ADD_TO_USER_DICTIONARY or mask SF_EDIT_USER_DICTIONARY, 0>,
	<offset SpellCheckAllTrigger, mask SF_CHECK_ALL, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpellCheckToEndTrigger, mask SF_CHECK_TO_END, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpellCheckSelectionTrigger, mask SF_CHECK_SELECTION, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpellStopSpellCheckTrigger, mask SF_SIMPLE_MODAL_BOX, 0>,
	<offset SpellCloseTrigger, mask SF_CLOSE, mask GCCF_IS_DIRECTLY_A_FEATURE>
endif

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SC_featuresList	GenControlFeaturesInfo	\
	<offset SpellStatusText, StatusName, 0>,
ifdef GPC_SPELL
	<offset SpellEditUserDictTrigger, EditUserDictionaryName, 0>,
else
	<offset SpellEditUserDictionaryControl, EditUserDictionaryName, 0>,
endif
	<offset SpellAddToUserDictTrigger, AddToUserDictionaryName, 0>,
	<offset SpellReplaceAllTrigger, ReplaceAllName, 0>,
ifdef GPC_SPELL
	<offset SpellReplaceTrigger, ReplaceCurrentName, 0>,
else
	<offset SpellReplaceGroup, ReplaceCurrentName, 0>,
endif
	<offset SpellSkipAllTrigger, SkipAllName, 0>,
ifdef GPC_SPELL
	<offset SpellSkipTrigger, SkipCurrentName, 0>,
else
	<offset SpellSkipGroup, SkipCurrentName, 0>,
endif
	<offset SpellCheckSelectionTrigger, CheckSelectionName,0>,
	<offset SpellCheckToEndTrigger, CheckToEndName,0>,
	<offset SpellCheckAllTrigger, CheckAllName,0>,
	<offset SpellSuggestList, PopupSuggestName, 0>,
	<offset SpellSuggestGroup, SimpleBoxName, 0>,
	<offset SpellContext, SpellContextName, 0>,
	<offset SpellCloseTrigger, SpellCloseName, 0>
	

SC_toolList		GenControlChildInfo \
	<offset SpellToolTrigger, mask STF_SPELL, mask GCCF_IS_DIRECTLY_A_FEATURE>

SC_toolFeaturesList	GenControlFeaturesInfo \
	<offset SpellToolTrigger, SpellName, 0>

if FULL_EXECUTE_IN_PLACE
SpellControlInfoXIP	ends
endif
;---

GetFeaturesAndChildBlock	proc	far
EC <	push	es, di							>
EC <	mov	di, segment GenControlClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenControlClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	NOT_GEN_CONTROL_OBJECT				>
EC <	pop	es, di							>

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
GetFeaturesAndChildBlock	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We subclass MSG_META_RESOLVE_VARIANT_SUPERCLASS here to add our hints before
		we are built

CALLED BY:	GLOBAL
PASS:		same as MSG_META_RESOLVE_VARIANT_SUPERCLASS
RETURN:		same as MSG_META_RESOLVE_VARIANT_SUPERCLASS
DESTROYED:	same as MSG_META_RESOLVE_VARIANT_SUPERCLASS
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/12/92		Initial version
	atw	12/1/92		Changed to not position box at bottom of screen

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlResolveVariantSuperclass	method	SpellControlClass,
				MSG_META_RESOLVE_VARIANT_SUPERCLASS	
	push	ax, cx, dx, bp

;	Make the box modal if that is desired

	mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
	call	ObjCallInstanceNoLock

if FLOPPY_BASED_USER_DICT
	mov	cx, (mask GIA_SYS_MODAL) or (0 shl 8)
else
	mov	cx, (mask GIA_MODAL) or (0 shl 8)
	test	ax, mask SF_SIMPLE_MODAL_BOX
	jnz	setAttrs
	mov	cx, (mask GIA_MODAL shl 8) or 0
setAttrs:
endif

	mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
	mov	di, offset SpellControlClass
	call	ObjCallSuperNoLock

	mov	ax, HINT_KEEP_INITIALLY_ONSCREEN
	clr	cx
	call	ObjVarAddData

if FLOPPY_BASED_USER_DICT
	;	
	; Needed to solve modality problems....
	;
	mov	ax, ATTR_GEN_INTERACTION_ABIDE_BY_INPUT_RESTRICTIONS
	clr	cx
	call	ObjVarAddData

	mov	ax, ATTR_GEN_HELP_TYPE
	mov	cx, size byte
	call	ObjVarAddData
	mov	{byte} ds:[bx], HT_SYSTEM_MODAL_HELP

endif

	pop	ax, cx, dx, bp
	mov	di, offset SpellControlClass
	GOTO	ObjCallSuperNoLock
SpellControlResolveVariantSuperclass	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the UI after a MSG_META_NOTIFY has arrived.

CALLED BY:	GLOBAL
PASS:		cx,dx,bp - args to MSG_META_NOTIFY_WITH_DATA_BLOCK
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlNotifyWithDataBlock	method	dynamic SpellControlClass,
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	bx, bp
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_SELECT_STATE_CHANGE
	je	doSelectionChange	
	cmp	dx, GWNT_SPELL_ENABLE_CHANGE
	jne	callSuper


	push	cx, dx, bp
	clr	cx
	tst	bx
	jz	setEnableFlags

	call	MemLock
	mov	es, ax
	mov	cx, es:[NSEC_spellEnabled]
	call	MemUnlock
setEnableFlags:
	mov	ds:[di].SCI_enableFlags, cx

	mov	ax, ATTR_SPELL_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS
	call	ObjVarFindData
	jnc	noDisable

;	If we are interacting with a targeted text object, enable/disable the
;	controller.

	tst	cx
	mov	cx, MSG_GEN_SET_ENABLED
	jnz	10$
	mov	cx, MSG_GEN_SET_NOT_ENABLED
10$:
	mov	ax, MSG_GEN_CONTROL_ENABLE_DISABLE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	
noDisable:
	pop	cx, dx, bp

;	If there is no active spell check, update the UI.

	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
exit:
	cmp	ds:[di].SCI_spellState, SBS_NO_SPELL_ACTIVE
	jne	callSuper
	call	UpdateUIFromSpellState
callSuper:
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, segment SpellControlClass
	mov	es, di
	mov	di, offset SpellControlClass
	GOTO	ObjCallSuperNoLock

doSelectionChange:
	clr	ds:[di].SCI_haveSelection
	tst	bp
	jz	exit
	mov	bx, bp
	call	MemLock
	mov	es, ax
	cmp	es:[NSSC_selectionType], SDT_TEXT
	jnz	unlock
	mov	al, es:[NSSC_deleteableSelection] ;AL <- 0 if no selection
	mov	ds:[di].SCI_haveSelection, al
unlock:
	call	MemUnlock
	jmp	exit
SpellControlNotifyWithDataBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateUIFromSpellState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the UI from the selection state.

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to SpellControl object
RETURN:		nada
DESTROYED:	ax, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateUIFromSpellState	proc	far	uses	cx, dx, bp
	class	SpellControlClass
	.enter

;	Enable/disable the "Check Selection" button depening upon whether or
;	not there is a selection.

	call	GetFeaturesAndChildBlock
	test	ax, mask SF_CHECK_TO_END
	jz	noCheckToEnd

	push	ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	tst	ds:[di].SCI_enableFlags
	jz	10$
	mov	ax, MSG_GEN_SET_ENABLED
10$:
	mov	dl, VUM_NOW
	push	si
	mov	si, offset SpellCheckToEndTrigger
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si
	pop	ax

noCheckToEnd:

	test	ax, mask SF_CHECK_SELECTION
	jz	exit

	mov	ax, MSG_GEN_SET_ENABLED
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	tst	ds:[di].SCI_haveSelection
	jnz	20$
	mov	ax, MSG_GEN_SET_NOT_ENABLED
20$:
	mov	dl, VUM_NOW
	push	si
	mov	si, offset SpellCheckSelectionTrigger
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

exit:
	.leave
	ret
UpdateUIFromSpellState	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlSetEnabled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If dict is not available, don't enable the spell control.

CALLED BY:	GLOBAL
PASS:		params for MSG_GEN_SET_ENABLED
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlSetEnabled	method	SpellControlClass, MSG_GEN_SET_ENABLED
	.enter
	call	CheckIfSpellAvailable	;
	tst	ax
	jz	notEnabled
	mov	ax, MSG_GEN_SET_ENABLED
callSuper:
	mov	di, offset SpellControlClass
	call	ObjCallSuperNoLock
exit:
	.leave
	ret
notEnabled:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_states, mask GS_ENABLED
	jz	exit
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jmp	callSuper
SpellControlSetEnabled	endp

SpellControlCommon ends

;---

SpellControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	SpellControlRebuildNormalUI --
		MSG_GEN_CONTROL_REBUILD_NORMAL_UI for SpellControlClass

DESCRIPTION:	We are such a *special* object that we need to rebuild ourself
		when the normal UI is rebuilt.

PASS:
	*ds:si - instance data
	es - segment of SpellControlClass

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
	Tony	12/14/92		Initial version

------------------------------------------------------------------------------@
SpellControlRebuildNormalUI	method dynamic	SpellControlClass,
					MSG_GEN_CONTROL_REBUILD_NORMAL_UI

	mov	ax, MSG_SPEC_UNBUILD_BRANCH
	mov	bp, mask SBF_VIS_PARENT_UNBUILDING
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_CONTROL_REBUILD_NORMAL_UI
	mov	di, offset SpellControlClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_UPDATE_WIN_GROUP
	mov	dl, VUM_NOW
	GOTO	ObjCallInstanceNoLock

SpellControlRebuildNormalUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableFeatureObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable the object if the feature is available.

CALLED BY:	GLOBAL
PASS:		z flag clear if we want to disable (jnz disable)
		^lBX:DI <- object
RETURN:		nada
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableFeatureObj	proc	near
	jnz	DisableObj
	ret
DisableFeatureObj	endp

DisableObj	proc	near	uses	ax, dx, si
	.enter	
	mov	si, di		;^lBX:SI <- object to disable
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageFixupDS
	.leave
	ret
DisableObj	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableFeatureObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable the object if the feature is available.

CALLED BY:	GLOBAL
PASS:		z flag clear if we want to disable (jnz disable)
		^lBX:DI <- object
RETURN:		nada
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableFeatureObj	proc	near
	jnz	EnableObj
	ret
EnableFeatureObj	endp

EnableObj	proc	near	uses	ax, dx, si
	.enter	
	mov	si, di		;^lBX:SI <- object to enable
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageFixupDS
	.leave
	ret
EnableObj	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessageCallFixupDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a space saver for a standard call to ObjMessage.

CALLED BY:	GLOBAL
PASS:		Same as ObjMessage (except for DS)
RETURN:		Whatever returned by ObjMessage
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMessageCallFixupDS	proc	near
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	ret
ObjMessageCallFixupDS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes down the spell box and generally shuts things down.

CALLED BY:	GLOBAL
PASS:		cx - GenControlInteractableFlags
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlExit	method	dynamic SpellControlClass, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE

	push	cx

if not FLOPPY_BASED_USER_DICT
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	clr	bx
	xchg	bx, ds:[di].SCI_ICBuffHan

	tst	bx
	jz	exit

	call	ICUpdateUser		;Save the user dictionary out to disk.
	call	ResetIgnoreBufferIfDesired
	call	ICExit
exit:

else	;FLOPPY_BASED_USER_DICT

	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	mov	bx, ds:[di].SCI_ICBuffHan
	tst	bx
	jz	noICBuff
	;
	; There is an ICBuff, update user dictionary, free it, and exit.
	;
	call	ICUpdateUser		
	call	ResetIgnoreBufferIfDesired
	call	ICFreeUserDict		
	call	ICExit
	jmp	short exit

noICBuff:
	;
	; No ICBuff, get one, free the user dictionary, and exit.  But
	; only if we're still think we have a user dictionary around to 
	; delete.
	;
	mov	ax, ATTR_SPELL_CONTROL_HAS_USER_DICT
	call	ObjVarFindData
	jnc	exitNoICBuff

	call	SpellGetICBuff		
	call	ICFreeUserDict		
	call	ICExit			

exit:
	mov	di, ds:[si]			;make sure no ICBuff reference
	add	di, ds:[di].SpellControl_offset
	mov	ds:[di].SCI_ICBuffHan, 0

	mov	ax, ATTR_SPELL_CONTROL_HAS_USER_DICT
	call	ObjVarDeleteData

exitNoICBuff:

endif   ;FLOPPY_BASED_USER_DICT

	mov	ax, MSG_SC_SPELL_CHECK_ABORTED
	call	ObjCallInstanceNoLock
	pop	cx
	mov	ax, MSG_GEN_CONTROL_NOTIFY_NOT_INTERACTABLE
	mov	di, offset SpellControlClass
	GOTO	ObjCallSuperNoLock
SpellControlExit	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellGetICBuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the ICBuff stored in the instance data (or allocates one
		if one doesn't exist).

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		bx - handle of ICBuff
			(0 if error)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellGetICBuff	proc	near	uses	di
	class	SpellControlClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	mov	bx, ds:[di].SCI_ICBuffHan
	tst	bx			;If an ICBuff allocated already, exit
	jnz	exit

	call	GetICBuffCommon
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	mov	ds:[di].SCI_ICBuffHan, bx

exit:
	.leave
	ret
SpellGetICBuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditGetICBuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the ICBuff stored in the instance data (or allocates one
		if one doesn't exist).

CALLED BY:	GLOBAL
PASS:		*ds:si - EditUserDictionaryControl object
RETURN:		bx - handle of ICBuff
			(0 if error)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditGetICBuff	proc	near	uses	di
	class	EditUserDictionaryControlClass
	.enter
	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	mov	bx, ds:[di].EUDCI_icBuff
	tst	bx			;If an ICBuff allocated already, exit
	jnz	exit

	call	GetICBuffCommon
	mov	di, ds:[si]
	add	di, ds:[di].EditUserDictionaryControl_offset
	mov	ds:[di].EUDCI_icBuff, bx

exit:
	.leave
	ret
EditGetICBuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetICBuffCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets an ICBuff for the caller

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		bx - handle of ICBuff (or 0 if error)
		*ds:si - control object
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetICBuffCommon	proc	near		uses	ax
	.enter	


;	INITIALIZE A NEW STRUCTURE TO COMMUNICATE WITH THE SPELL LIBRARY

	call	ICInit			;Allocate a new ICBuff structure
	cmp	ax, IC_RET_OK		;If one allocated, exit
	je	exit			;
					;Else, whine that we couldn't start
					; spell checking, and bring down the
					; box.
					;
	mov	bx, offset SpellInitOpenErrString
	cmp	ax, IC_RET_NO_OPEN
	je	5$
	mov	bx, offset SpellInitNoMemString
	cmp	ax, IC_RET_NOMEM
	je	5$
	mov	bx, offset SpellInitNoUserDictString
	cmp	ax, IC_RET_NO_USER_DICT
	je	5$
	mov	bx, offset SpellInitBadLangString
	cmp	ax, IC_RET_BAD_LANG
	je	5$
	mov	bx, offset SpellInitGenericErrString
5$:
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE or mask CDBF_SYSTEM_MODAL)
	call	SpellPutupBox

	push	bp
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock
	pop	bp

	clr	bx
exit:
	.leave
	ret
GetICBuffCommon	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContinueSpellCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_SC_CHECK to the output of the object with
		the appropriate parameters.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContinueSpellCheck	proc	near
	class	SpellControlClass
	mov	cx, SCSO_BEGINNING_OF_SELECTION shl offset SCO_START_OPTIONS
	FALL_THRU	SetNumCharsAndSendSpellCheckToOutput
ContinueSpellCheck	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNumCharsAndSendSpellCheckToOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_SC_CHECK to the output of the object with
		the appropriate parameters.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
		cx - SpellCheckStartOption
RETURN:		nada
DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNumCharsAndSendSpellCheckToOutput	proc	near
	class	SpellControlClass
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	cmp	ds:[di].SCI_spellState, SBS_CHECKING_SELECTION
	jne	10$
	ornf	cx,  mask SCO_CHECK_NUM_CHARS
	movdw	dxax, ds:[di].SCI_charsLeft
10$:
	FALL_THRU	SendMethodSpellCheckToOutput
SetNumCharsAndSendSpellCheckToOutput	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMethodSpellCheckToOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This methods sends MSG_SPELL_CHECK out to the current
		output.

CALLED BY:	GLOBAL
PASS:		cx - SpellCheckOptions
		dx:ax - data for SCI_numChars 
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMethodSpellCheckToOutput	proc	near	uses	bp
	.enter
	call	SpellGetICBuff
	tst	bx
	jz	exit
	sub	sp, size SpellCheckInfo
	mov	bp, sp
	mov	ss:[bp].SCI_ICBuff, bx
	mov	ss:[bp].SCI_options, cx
	movdw	ss:[bp].SCI_numChars, dxax
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].SCI_replyObj.handle, ax
	mov	ss:[bp].SCI_replyObj.chunk, si
	mov	ax, MSG_SPELL_CHECK
	mov	dx, size SpellCheckInfo
	clrdw	bxdi
	call	GenControlOutputActionStack
	add	sp, size SpellCheckInfo
exit:
	.leave
	ret
SendMethodSpellCheckToOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begins a spell session.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlStart	method	dynamic SpellControlClass, 
					MSG_SC_CHECK_ENTIRE_DOCUMENT,
					MSG_SC_CHECK_TO_END,
					MSG_SC_CHECK_SELECTION

	call	SpellGetICBuff		;If no ICBuff, exit.
	tst	bx
	jz	exit
	mov	ds:[di].SCI_spellState, SBS_CHECKING_DOCUMENT
	cmp	ax, MSG_SC_CHECK_SELECTION
	jne	10$
	mov	ds:[di].SCI_spellState, SBS_CHECKING_SELECTION
10$:

;	Disable the various "start spell check" triggers.

	push	ax
	call	GetFeaturesAndChildBlock

	mov	di, offset SpellCheckSelectionTrigger
	test	ax, mask SF_CHECK_SELECTION
	call	DisableFeatureObj

	mov	di, offset SpellCheckToEndTrigger
	test	ax, mask SF_CHECK_TO_END
	call	DisableFeatureObj

	mov	di, offset SpellCheckAllTrigger
	test	ax, mask SF_CHECK_ALL
	call	DisableFeatureObj

	pop	ax
	

;	GOTO THE BEGINNING OF THE DOCUMENT AND START SPELL CHECKING

	mov	cx, SCSO_BEGINNING_OF_DOCUMENT shl offset SCO_START_OPTIONS
	cmp	ax, MSG_SC_CHECK_ENTIRE_DOCUMENT
	je	90$
	mov	cx, SCSO_WORD_BOUNDARY_BEFORE_SELECTION shl offset SCO_START_OPTIONS
	cmp	ax, MSG_SC_CHECK_TO_END
	je	90$
	mov	cx, SCSO_WORD_BOUNDARY_BEFORE_SELECTION shl offset SCO_START_OPTIONS or mask SCO_CHECK_SELECTION
90$:
	call	SendMethodSpellCheckToOutput
exit:
	ret
SpellControlStart	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableReplaceTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the replace triggers.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableReplaceTriggers	proc	near	uses	ax, bx, di
	.enter
	call	GetFeaturesAndChildBlock

ifdef GPC_SPELL
	mov	di, offset SpellReplaceTrigger
else
	mov	di, offset SpellReplaceGroup
endif
	test	ax, mask SF_REPLACE_CURRENT
	call	DisableFeatureObj

	mov	di, offset SpellReplaceAllTrigger
	test	ax, mask SF_REPLACE_ALL
	call	DisableFeatureObj 
	.leave
	ret
DisableReplaceTriggers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableSuggestions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the suggestion list/box.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableSuggestions	proc	near	uses	ax, bx, di
	.enter
	call	GetFeaturesAndChildBlock

	mov	di, offset SpellSuggestList
	test	ax, mask SF_SUGGESTIONS
	jz	exit
	test	ax, mask SF_SIMPLE_MODAL_BOX
	jz	disable
	mov	di, offset SpellSuggestGroup
disable:
	call	DisableObj
exit:
	.leave
	ret
DisableSuggestions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableSuggestions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables the suggestion list/box.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableSuggestions	proc	near	uses	ax, bx, di
	.enter
	call	GetFeaturesAndChildBlock

	mov	di, offset SpellSuggestList
	test	ax, mask SF_SUGGESTIONS
	jz	exit
	test	ax, mask SF_SIMPLE_MODAL_BOX
	jz	enable
	mov	di, offset SpellSuggestGroup
enable:
	call	EnableObj
exit:
	.leave
	ret
EnableSuggestions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GiveDefaultToTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gives the default to the passed trigger.

CALLED BY:	GLOBAL
PASS:		^lbx:si <- trigger to give default to
RETURN:		nada
DESTROYED:	ax, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GiveDefaultToTrigger	proc	near	uses	ax
	.enter
	mov	ax, MSG_GEN_TRIGGER_MAKE_DEFAULT_ACTION
	call	ObjMessageFixupDS
	.leave
	ret
GiveDefaultToTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlReplacementTextUserModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Method sent out when the replacement text has been added.

CALLED BY:	GLOBAL
PASS:		CX:DX <- text object that is dirty
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlReplacementTextUserModified	method	dynamic SpellControlClass,
					MSG_META_TEXT_USER_MODIFIED

;	The user has changed the replacement word, so enable the replace/
;	replace all triggers (if they exist).
;
;	NOTE: Replace All is not available if checking a selection, so we
;	      do not enable it.
;	      
;

	call	GetFeaturesAndChildBlock
	cmp	ds:[di].SCI_spellState, SBS_CHECKING_DOCUMENT
	jne	skipReplaceAll

	mov	di, offset SpellReplaceAllTrigger
	test	ax, mask SF_REPLACE_ALL
	call	EnableFeatureObj

skipReplaceAll:

ifdef GPC_SPELL
	mov	di, offset SpellReplaceTrigger
else
	mov	di, offset SpellReplaceGroup
endif
	test	ax, mask SF_REPLACE_CURRENT
	jz	noDefault

;	Enable the "replace" trigger and give it the default.

	call	EnableFeatureObj
	mov	si, offset SpellReplaceTrigger
	call	GiveDefaultToTrigger

noDefault:
	ret
SpellControlReplacementTextUserModified	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStatusLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the status line of the text.

CALLED BY:	GLOBAL
PASS:		bp - chunk handle of text string
		bx - handle of child block 
RETURN:		nada
DESTROYED:	dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStatusLine	proc	near	uses	ax, cx, dx, si
	.enter
	clr	cx				;Null terminated
	mov	dx, handle SpellNotFreeString	;^lDX:BP - text
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	mov	si, offset SpellStatusText
	call	ObjMessageFixupDS
	.leave
	ret
SetStatusLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToSuggestionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed message to the suggestion list

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToSuggestionList	proc	near	uses	ax, bx, cx, si
	.enter
	mov_tr	cx, ax
	call	GetFeaturesAndChildBlock
	test	ax, mask SF_SUGGESTIONS
	jz	exit

	mov	si, offset SpellSeparateSuggestList
	test	ax, mask SF_SIMPLE_MODAL_BOX
	jnz	10$
	mov	si, offset SpellSuggestList
10$:
	mov_tr	ax, cx
	call	ObjMessageFixupDS
exit:
	.leave
	ret
SendToSuggestionList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlSpellCheckAborted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method is sent out when the current spell check session
		has been aborted (the text object has closed or something).

CALLED BY:	GLOBAL
PASS:		*ds:si - spell check object
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlSpellCheckAborted	method	SpellControlClass,
					MSG_SC_SPELL_CHECK_ABORTED,
					MSG_ABORT_ACTIVE_SPELL


	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset	
	mov	bx, ds:[di].SCI_ICBuffHan
	tst	bx
	jz	10$
	call	ICStopCheck
10$:

	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset	
	mov	ds:[di].SCI_spellState, SBS_NO_SPELL_ACTIVE
	call	UpdateUIFromSpellState

;	Disable the Skip, Skip All, Replace, ReplaceAll triggers, and myriad
;	other objects.

	call	GetFeaturesAndChildBlock

ifdef GPC_SPELL
	mov	di, offset SpellSkipTrigger
else
	mov	di, offset SpellSkipGroup
endif
	test	ax, mask SF_SKIP
	call	DisableFeatureObj

	mov	di, offset SpellSkipAllTrigger
	test	ax, mask SF_SKIP_ALL
	call	DisableFeatureObj

	mov	di, offset SpellAddToUserDictTrigger
	test	ax, mask SF_ADD_TO_USER_DICTIONARY
	call	DisableFeatureObj

	mov	di, offset SpellUnknownText

	;
	; REDWOOD
	;
	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT
	call	DisableFeatureObj

;OLD	call	DisableObj

	;
	; REDWOOD
	;
	mov	di, offset SpellReplaceText
	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT
	call	DisableFeatureObj

;OLD	call	DisableObj

	call	DisableSuggestions

	call	DisableReplaceTriggers

;	CLEAR OUT THE VARIOUS TEXT OBJECTS AND THE LIST OF ALTERNATE SPELLINGS

	push	ax				; NEW CP

	mov	ax, MSG_SUGGEST_LIST_RESET
	call	SendToSuggestionList

	pop	ax				; NEW CP

	;
	; REDWOOD
	;
	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT ;NEW CP
	jz	dontDoIt			; NEW CP

	push	si
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	si, offset SpellUnknownText
	call	ObjMessageFixupDS
	mov	si, offset SpellReplaceText
	call	ObjMessageFixupDS
	pop	si

dontDoIt:

	call	GetFeaturesAndChildBlock

;	Clear out the context area (if it exists)

	test	ax, mask SF_CONTEXT
	jz	noContext
	push	ax, si	
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	si, offset SpellContext
	call	ObjMessageFixupDS
	pop	ax, si
noContext:

;	ENABLE THE START SPELL CHECK TRIGGERS

	mov	di, offset SpellCheckAllTrigger
	test	ax, mask SF_CHECK_ALL
	call	EnableFeatureObj

	mov	bp, offset SpellNoCheckString
	test	ax, mask SF_STATUS
	jz	exit
	call	SetStatusLine
exit:
	ret
SpellControlSpellCheckAborted	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlEndOfDocumentReached
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler resets the dialog box to its "pre-spell
		session" state, notifies the user that spellchecking is 
		complete, and takes down the box.

CALLED BY:	GLOBAL
PASS:		CX <- SpellCheckResult
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlEndOfDocumentReached	method	SpellControlClass, 
				MSG_SC_SPELL_CHECK_COMPLETED
EC <	cmp	cx, SpellCheckResult					>
EC <	ERROR_AE BAD_SPELL_CHECK_RESULTS				>

	call	SpellGetICBuff

EC <	tst	bx							>
EC <	ERROR_Z	NO_IC_BUFF						>

	call	ICUpdateUser		;Update the user dictionary on disk
ifdef GPC_SPELL
	cmp	cx, SCR_DOCUMENT_CHECKED
	jb	queryContinue
endif
	mov	bx, cx
	shl	bx, 1
	mov	bx, cs:[spellCompleteStrings][bx]
	mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	SpellPutupBox

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	GOTO	ObjCallInstanceNoLock

ifdef GPC_SPELL
queryContinue:
	;
	; get appname from app
	;
	mov	dx, -1			; get appname from app
	mov	bp, (VMS_TEXT shl offset VMSF_STYLE) or mask VMSF_COPY_CHUNK
	mov	cx, ds:[LMBH_handle]	; copy into spell control block
	mov	ax, MSG_GEN_FIND_MONIKER
	call	ObjCallInstanceNoLock	; ^lcx:dx = moniker
	jcxz	useNullString
	mov	di, dx
	mov	di, ds:[di]
	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	useNullString
	add	di, offset VM_data.VMT_text	; ds:di = appname
	jmp	short haveString

useNullString:
	mov	al, 0
	mov	cx, (size TCHAR)		; null-terminator only
	call	LMemAlloc
	mov	dx, ax
	mov_tr	di, ax
	mov	di, ds:[di]			; ds:di = null appname
	mov	{TCHAR}ds:[di], 0
	;
	; ask user
	;
haveString:
	push	dx				; save appname chunk
	sub	sp, size GenAppDoDialogParams
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.segment, ds
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.offset, di
	mov	ax, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE or GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, ax
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GADDP_finishOD.handle, ax
	mov	ss:[bp].GADDP_finishOD.offset, si
	mov	ss:[bp].GADDP_message, MSG_SC_FINISHED_CHECK_SELECTION
	mov	si, bx
	mov	bx, handle Strings
	call	MemLock
	push	ds
	mov	ds, ax
	mov	si, offset SpellQueryString
	mov	si, ds:[si]		;DS:SI <- ptr to string to display
	pop	ds
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, si
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	dx, size GenAppDoDialogParams
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication
	add	sp, size GenAppDoDialogParams
	pop	ax				; *ds:ax = appname chunk
	call	LMemFree
	mov	bx, handle Strings
	call	MemUnlock
	ret
endif
SpellControlEndOfDocumentReached	endp

spellCompleteStrings	label	lptr
		lptr SpellWordCompletedString
		lptr SpellSelectionCompletedString
		lptr SpellEntireDocumentCompletedString

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlFinishedCheckSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User response when selection check is finished.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
		cx - IC_YES, continue checking document
		   - IC_NO, stop checking
RETURN:		nada
DESTROYED:
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/5/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC_SPELL
SpellControlFinishedCheckSelection	method	dynamic SpellControlClass, MSG_SC_FINISHED_CHECK_SELECTION
	cmp	cx, IC_YES
	jne	notYes
	mov	ax, MSG_SC_CHECK_TO_END
	GOTO	ObjCallInstanceNoLock
notYes:
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	GOTO	ObjCallInstanceNoLock
SpellControlFinishedCheckSelection	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlReplaceWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This gets the current word out of the replacement text and
		sends it off to the output.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlReplaceWord	method	dynamic SpellControlClass,
					MSG_SC_REPLACE_WORD
	mov	ax, MSG_REPLACE_CURRENT
	GOTO	ReplaceCommon
SpellControlReplaceWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetUnknownWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the unknown word from the object

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControlClass
		es:di - dest for word
RETURN:		cx - # chars (including null terminator)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetUnknownWord	proc	near	uses	ax, bx, dx, bp, di, si
	.enter
	call	GetFeaturesAndChildBlock
	movdw	dxbp, esdi
	mov	si, offset SpellUnknownText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessageCallFixupDS
	inc	cx
	.leave
	ret
GetUnknownWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlReplaceAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This gets the current word out of the replacement text and
		sends it off to the output.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlReplaceAll	method	dynamic SpellControlClass,
					MSG_SC_REPLACE_ALL
	mov	ax, MSG_REPLACE_ALL_OCCURRENCES
	FALL_THRU	ReplaceCommon
SpellControlReplaceAll	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets the text from the replacement text object,
		and sends it out with the passed method to the output.

CALLED BY:	GLOBAL
PASS:		*ds:si,ds:di - SpellControl object
		ax - method to send to output of SpellControl
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceCommon	proc	far
	class	SpellControlClass
SBCS <	searchString	local	SPELL_MAX_WORD_LENGTH	dup (char)	>
DBCS <	searchString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)	>
SBCS <	replaceString	local	SPELL_MAX_WORD_LENGTH	dup (char)	>
DBCS <	replaceString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)	>
	searchSize	local	word
	replaceSize	local	word
;
;	The 4 local vars above are inherited
;
	.enter
	push	ax, si
	call	GetFeaturesAndChildBlock

;	Create block with data in this format:
;
;			SearchReplaceStruct<>			
;			data	Null-Terminated Search String
;			data	Null-Terminated Replace string
;

	;
	; REDWOOD
	;
	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT ;NEW CP
	jz	exit

;	GET REPLACEMENT TEXT

	push	bp, si
	mov	dx, ss
	lea	bp, replaceString	;DX:BP <- ptr to dest for string
	mov	si, offset SpellReplaceText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessageCallFixupDS
	pop	bp, si

	inc	cx			;Add 1 for null terminator
	mov	replaceSize, cx

;allow replacement with null string - brianc 8/11/94
;EC <	cmp	cx,1							>
;EC <	ERROR_Z	NO_SPELL_REPLACE_STRING					>
EC <	cmp	cx, SPELL_MAX_WORD_LENGTH-1			>
EC <	ERROR_A	SPELL_REPLACE_STRING_TOO_LARGE				>

;	GET SOURCE TEXT

	segmov	es, ss
	lea	di, searchString	;ES:DI <- ptr to dest for string
	call	GetUnknownWord		;Returns CX <- # items in string
	mov	searchSize, cx

EC <	cmp	cx, SPELL_MAX_WORD_LENGTH				>
EC <	ERROR_A	SPELL_SEARCH_STRING_TOO_LARGE				>


	mov	ah, mask SO_IGNORE_CASE or mask SO_IGNORE_SOFT_HYPHENS
	call	CreateSearchReplaceStruct
	pop	cx, si

	cmp	cx, MSG_REPLACE_CURRENT
	jne	sendMethod

;	We are doing a replace, so adjust SCI_charsLeft (this is used when
;	checking a selection, so we know when to stop).

	mov	ax, replaceSize
	sub	ax, searchSize			;AX <- # chars to add to 
						; the count of chars left
						; to check (could be negative)
	cwd					;DX:AX <- sign extended value
	mov	di, ds:[si]			
	add	di, ds:[di].SpellControl_offset
	adddw	ds:[di].SCI_charsLeft, dxax
sendMethod:
	mov	dx, bx			;DX <- handle of SearchReplaceStruct
	mov_tr	ax, cx			;AX <- method to send
	clr	cx			;Clear "start from beginning" flag
	clrdw	bxdi			;No destination class
	call	GenControlOutputActionRegs

	;
	; REDWOOD
	;
contRedwood:
	call	ContinueSpellCheck
	.leave
	ret

	;
	; REDWOOD
	;
exit:
	pop	ax, si
	jmp	contRedwood

ReplaceCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfFlagActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns ax=-1 if flag exists and is set to true in ini file.

CALLED BY:	GLOBAL
PASS:		dx = offset to key string in CS
RETURN:		ax = -1 if flag is set to true in ini file
			else ax=0.
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/23/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfFlagActive	proc	near	uses	cx, si, ds
	.enter
	mov	cx, cs
	mov	ds, cx
	mov	si, offset TextCategory
	call	InitFileReadBoolean
	jnc	exit
	clr	ax
exit:
	.leave
	ret
CheckIfFlagActive	endp
TextCategory		char	"Text",0
AutoSuggestKey 		char	"AutoSuggest",0
AutoCheckSelectionKey	char	"AutoCheckSelections",0
ResetSkippedWordsKey	char	"ResetSkippedWordsWhenBoxCloses",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustWordForAAnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the first "a" or "an" in the "unknown" string
		into its complement.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl
RETURN:		bx - child block
DESTROYED:	ax, cx, dx, di, si, es 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustWordForAAnError	proc	near	uses	si
SBCS <	errorString	local	SPELL_MAX_WORD_LENGTH dup (char)	>
DBCS <	errorString	local	SPELL_MAX_WORD_LENGTH dup (wchar)	>
	.enter	

	call	GetFeaturesAndChildBlock

	;
	; REDWOOD
	;
	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT ;NEW CP
	jz	done

	segmov	es, ss
	lea	di, errorString
	call	GetUnknownWord

;	SET THE REPLACE STRING INCLUDING TO THE FIRST "A"

	push	ds
	segmov	ds,ss
	clr	cx
	lea	si, errorString
loopTop:
	LocalGetChar	ax, dssi
	inc	cx
EC <	LocalIsNull	ax						>
EC <	ERROR_Z	CONTROLLER_OBJECT_INTERNAL_ERROR			>
SBCS <	cmp	al, 'a'							>
DBCS <	cmp	ax, 'a'							>
	je	isA
SBCS <	cmp	al, 'A'							>
DBCS <	cmp	ax, 'A'							>
	jne	loopTop
isA:
	pop	ds

	push	bp
	mov	dx, ss
	lea	bp, errorString	;DX:BP <- ptr to string
	push	si
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset SpellReplaceText
	call	ObjMessageCallFixupDS
	pop	di

;	CONVERT A->AN or AN->A

SBCS <	mov	al, ss:[di]						>
DBCS <	mov	ax, ss:[di]						>
SBCS <	cmp	al, 'n'							>
DBCS <	cmp	ax, 'n'							>
	je	skipNext
SBCS <	cmp	al, 'N'							>
DBCS <	cmp	ax, 'N'							>
	jne	addN
skipNext:
	LocalNextChar	esdi
	jmp	common
addN:			;Insert an "n"
	push	di
FXIP <	mov	dx, dgroup						>
NOFXIP<	mov	dx, cs							>
	mov	bp, offset nString
	clr	cx
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	mov	si, offset SpellReplaceText
	call	ObjMessageCallFixupDS
	pop	di
common:

;	APPEND REMAINDER OF STRING.

	mov	dx, ss
	mov	bp, di
	clr	cx
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	call	ObjMessageCallFixupDS

	mov	ax, MSG_VIS_TEXT_SELECT_ALL	;Select all the replacement
						; text so the user can type
	call	ObjMessageCallFixupDS		; over it easily.
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjMessageFixupDS

	pop	bp

done:
	.leave
	ret
AdjustWordForAAnError	endp

if FULL_EXECUTE_IN_PLACE
idata	segment
endif

SBCS <nString	char	"n",0						>
DBCS <nString	wchar	"n",0						>


if FULL_EXECUTE_IN_PLACE
idata	ends
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIsWhitespace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if passed char is whitespace

CALLED BY:	GLOBAL
PASS:		ax - char to test (Null bytes are not whitespace)
RETURN:		z flag clear if whitespace (jne isWhitespace)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIsWhitespace	proc	near	uses	ax
	.enter
SBCS <	cmp	al, C_GRAPHIC		;Treat graphics escapes as whitespace>
DBCS <	cmp	ax, C_GRAPHIC		;Treat graphics escapes as whitespace>
	jz	whitespace
SBCS <	clr	ah							>
	call	LocalIsSpace
exit:
	.leave
	ret
whitespace:
SBCS <	or	ah, 1			;Clear the Z flag		>
DBCS <	cmp	al, C_GRAPHIC+1		;Clear the Z flag		>
	jmp	exit
CheckIsWhitespace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustWordForDoubleWordError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes everything beyond the first word in the string.

CALLED BY:	GLOBAL
PASS:		*ds:si - controller
RETURN:		bx - child block
DESTROYED:	ax, cx, dx, di, si, es 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustWordForDoubleWordError	proc	near	uses	si
SBCS <	errorString	local	SPELL_MAX_WORD_LENGTH dup (char)	>
DBCS <	errorString	local	SPELL_MAX_WORD_LENGTH dup (wchar)	>
	.enter

	;
	; REDWOOD
	;
	call	GetFeaturesAndChildBlock
	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT ;NEW CP
	jz	done

;	GET THE UNKNOWN STRING

	segmov	es, ss
	lea	di, errorString
	call	GetUnknownWord

;	NUKE EVERYTHING BEYOND THE FIRST WHITESPACE CHAR.

	push	bp
	push	ds, si
	segmov	ds, ss, dx
	mov	si, di		;DS:SI <- ptr to double-word string	
	mov	bp, di		;DX:BP <- ptr to errorString
	mov	cx, -1
loopTop:
	LocalGetChar	ax, dssi

;	If we've reached the end of the string without encountering a
;	whitespace, something has gone dreadfully wrong. Just abort out
;	of the loop gracefully.

	LocalIsNull	ax						
EC <	ERROR_Z	NO_WHITESPACE_IN_DOUBLE_WORD_ERROR		>
NEC <  	jz	endLoop						>
	inc	cx
	call	CheckIsWhitespace
	jz	loopTop
NEC <endLoop:							>

;	CX <- # chars in first word

	pop	ds, si

	call	GetFeaturesAndChildBlock
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset SpellReplaceText
	call	ObjMessageCallFixupDS

	mov	ax, MSG_VIS_TEXT_SELECT_ALL	;Select all the replacement
						; text so the user can type
	call	ObjMessageFixupDS
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjMessageFixupDS

	pop	bp

done:
	.leave
	ret
AdjustWordForDoubleWordError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplaySpellStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the spell status in the status line.

CALLED BY:	GLOBAL
PASS:		ax, cx - SpellErrorFlags
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplaySpellStatus	proc	near	uses	bp
	.enter

	mov	bp, offset SpellAErrorString
	test	ax, mask SEFH_A_ERROR
	jne	setStatus

	mov	bp, offset SpellAnErrorString
	test	ax, mask SEFH_AN_ERROR
	jne	setStatus

	mov	bp, offset SpellDblWordString
	test	cx, mask SEF_DOUBLE_WORD_ERROR
	jne	setStatus

	mov	bp, offset SpellCapErrorString
	test	cx, mask SEF_CAPITALIZATION_ERROR
	jne	setStatus

	mov	bp, offset SpellCompoundErrorString
	test	cx, mask SEF_COMPOUNDING_ERROR
	jne	setStatus

	mov	bp, offset SpellInvalidLeadingHyphenString
	test	cx, mask SEF_INVALID_PRE_CHARS
	jne	setStatus

	mov	bp, offset SpellInvalidTrailingHyphenString
	test	cx, mask SEF_INVALID_TRAILING_CHARS
	jne	setStatus

	mov	bp, offset SpellNotFreeString
	test	cx, mask SEF_NOT_FREE_STANDING_WORD
	jne	setStatus

	mov	bp, offset SpellAccentMisplacedString
	test	cx, mask SEF_ACCENT_ERROR
	jne	setStatus

	mov	bp, offset SpellNotFoundString
setStatus:
	call	SetStatusLine
	.leave
	ret
DisplaySpellStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlUnknownWordFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the method sent to the spell box when an unknown word
		is found.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
		ss:bp - ptr to null-terminated unknown word
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlUnknownWordFound	method	dynamic SpellControlClass,
					MSG_SC_UNKNOWN_WORD_FOUND

;	COPY OVER # CHARS LEFT TO COPY

	movdw	ds:[di].SCI_charsLeft, ss:[bp].UWI_numChars, ax

	call	GetFeaturesAndChildBlock
EC <	test	ax, mask SF_SKIP or mask SF_REPLACE_CURRENT		>
EC <	ERROR_Z	MUST_HAVE_EITHER_SKIP_OR_REPLACE_CURRENT_FEATURE_ENABLED>

	;
	; REDWOOD
	;
	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT ;NEW CP
if FLOPPY_BASED_USER_DICT
	LONG jz	closeAndExit
else
	LONG jz	exit
endif

;	Set the "unknown word" display and the replacement text

	mov	di, offset SpellUnknownText
	call	EnableObj

	mov	di, offset SpellReplaceText
	call	EnableObj

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss			;DX:BP <- ptr to null terminated string
	add	bp, ss:[bp].UWI_offset
	clr	cx

	push	si, bp
	mov	si, offset SpellUnknownText
	call	ObjMessageCallFixupDS

	mov	ax, MSG_VIS_TEXT_SELECT_START	;Force it to scroll to the 
	call	ObjMessageFixupDS		; beginning
	pop	si, bp

;	Nuke old suggestions

	mov	ax, MSG_SUGGEST_LIST_RESET
	call	SendToSuggestionList

	call	SpellGetICBuff
	mov	cx, bx
	call	ICGetErrorFlags	;AX,CX <- error flags

;	SET STATUS LINE

	push	ax
	call	GetFeaturesAndChildBlock
	test	ax, mask SF_STATUS
	pop	ax
	jz	noSetStatus

	call	DisplaySpellStatus

noSetStatus:
	test	cx, mask SEF_DOUBLE_WORD_ERROR
	LONG jne	doDoubleWord
	test	ax, mask SEFH_A_ERROR or mask SEFH_AN_ERROR
	LONG jne	doAAnError

	call	GetFeaturesAndChildBlock

;	Enable the "skip" and "add to user dict" buttons

ifdef GPC_SPELL
	mov	di, offset SpellSkipTrigger
else
	mov	di, offset SpellSkipGroup
endif
	test	ax, mask SF_SKIP
	call	EnableFeatureObj

	mov	di, offset SpellSkipAllTrigger
	test	ax, mask SF_SKIP_ALL
	call	EnableFeatureObj

	mov	di, offset SpellAddToUserDictTrigger
	test	ax, mask SF_ADD_TO_USER_DICTIONARY
	call	EnableFeatureObj

	call	EnableSuggestions

	call	DisableReplaceTriggers

	push	si
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	dx, ss			;DX:BP <- replacement text
	clr	cx
	mov	si, offset SpellReplaceText
	call	ObjMessageCallFixupDS

	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	ObjMessageFixupDS
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjMessageFixupDS
	pop	si

	mov	dx, offset AutoSuggestKey	;
	call	CheckIfFlagActive		;Returns AX nonzero if
	tst	ax				; autosuggest active.
	jz	giveDefault			;Branch if no auto-suggest

	mov	ax, MSG_GEN_ACTIVATE
	call	SendToSuggestionList
	
giveDefault:
	
if FLOPPY_BASED_USER_DICT
	;
	; Give the focus to the box, though this seems like overkill.
	; In Redwood, we'll call the superclass so the spell checker 
	; doesn't think it's coming up for the first time.  (Andrew
	; says what I need to do in the handler for MSG_GEN_INTERACTION_-
	; INITIATE is not bring up the dialog box if the spell check is in
	; progress, rather than do this hack, but the code works so I'll
	; leave it for now. -cbh 5/ 6/94)
	;
	push	es
	mov	di, segment SpellControlClass
	mov	es, di
	mov	di, offset SpellControlClass
	mov	ax, MSG_GEN_INTERACTION_INITIATE;Give the focus, etc to the
	call	ObjCallSuperNoLock		; box.
	pop	es
else
	mov	ax, MSG_GEN_INTERACTION_INITIATE;Give the focus, etc to the
	call	ObjCallInstanceNoLock		; box.
endif

	call	GetFeaturesAndChildBlock
	test	ax, mask SF_SKIP
	jz	getContext
	push	si
	mov	si, offset SpellSkipTrigger
	call	GiveDefaultToTrigger
	pop	si
getContext:

;	Get context if necessary

	test	ax, mask SF_CONTEXT
	jz	exit

	push	ax, si	
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	si, offset SpellContext
	call	ObjMessageFixupDS
	pop	ax, si

	mov	ax, MSG_META_GET_CONTEXT
	mov	dx, size GetContextParams
	sub	sp, dx
	mov	bp, sp
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].GCP_replyObj, cxsi
	mov	ss:[bp].GCP_numCharsToGet, MAX_CONTEXT_CHARS
	mov	ss:[bp].GCP_location, CL_CENTERED_AROUND_SELECTION
	clrdw	bxdi
	call	GenControlOutputActionStack
	add	sp, size GetContextParams
exit:
	ret


doAAnError:
	call	AdjustWordForAAnError
	jmp	doTwoWordErrorCommon
doDoubleWord:
	call	AdjustWordForDoubleWordError
doTwoWordErrorCommon:

;	Enable the skip and replace triggers, disable Add to User Dict and
;	"Skip All"/"Replace All" triggers.

	call	GetFeaturesAndChildBlock
ifdef GPC_SPELL
	mov	di, offset SpellSkipTrigger
else
	mov	di, offset SpellSkipGroup
endif
	test	ax, mask SF_SKIP
	call	EnableFeatureObj

ifdef GPC_SPELL
	mov	di, offset SpellReplaceTrigger
else
	mov	di, offset SpellReplaceGroup
endif
	test	ax, mask SF_REPLACE_CURRENT
	call	EnableFeatureObj
	
	mov	di, offset SpellSkipAllTrigger
	test	ax, mask SF_SKIP_ALL
	call	DisableFeatureObj

	mov	di, offset SpellReplaceAllTrigger
	test	ax, mask SF_REPLACE_ALL
	call	DisableFeatureObj

	mov	di, offset SpellAddToUserDictTrigger
	test	ax, mask SF_ADD_TO_USER_DICTIONARY
	call	DisableFeatureObj

	call	DisableSuggestions
	jmp	giveDefault

if FLOPPY_BASED_USER_DICT
closeAndExit:
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjCallInstanceNoLock
	jmp	short exit
endif

SpellControlUnknownWordFound	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlIgnoreWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler ignores the current unknown word and
		continues with the spell checking.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckWildcard	proc	near
	push	di
	LocalStrLength
	pop	di
	LocalLoadChar	ax, C_QUESTION_MARK
	push	cx, di
	LocalFindChar
	pop	cx, di
	je	done
	LocalLoadChar	ax, C_ASTERISK
	LocalFindChar
done:
	ret
CheckWildcard	endp

SpellControlIgnoreWord	method	dynamic SpellControlClass, MSG_SC_IGNORE_WORD
SBCS <	sourceString	local	SPELL_MAX_WORD_LENGTH	dup (char)	>
DBCS <	sourceString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)	>
	.enter
	segmov	es, ss
	lea	di, sourceString
	call	GetUnknownWord
	
	call	SpellGetICBuff
	tst	bx
	jz	exit

	; if there's a wildcard, handle like "Skip"
	call	CheckWildcard
	je	justSkip

	push	ds, si
	segmov	ds, ss			;DS:SI <- string to ignore
	lea	si, sourceString
	call	ICIgnore
	pop	ds, si

	call	ContinueSpellCheck
exit:
	.leave
	ret

justSkip:
	mov	cx, SCSO_END_OF_SELECTION shl offset SCO_START_OPTIONS
	call	SetNumCharsAndSendSpellCheckToOutput
	jmp	short exit
SpellControlIgnoreWord	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlAddUnknownWordToUserDictionary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method adds the unknown word to the user dictionary.

CALLED BY:	GLOBAL
PASS:		*ds:si - SpellControl object
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlAddUnknownWordToUserDictionary	method	SpellControlClass,
			MSG_SC_ADD_UNKNOWN_WORD_TO_USER_DICTIONARY
SBCS <	sourceString	local	SPELL_MAX_WORD_LENGTH	dup (char)	>
DBCS <	sourceString	local	SPELL_MAX_WORD_LENGTH	dup (wchar)	>
	.enter

if FLOPPY_BASED_USER_DICT

	;
	; First check for a disk.  If there is one in the drive, do nothing.
	; Otherwise, we'll ask *once* for a user dictionary.   6/14/94 cbh
	;
	push	ax
	mov	al, DOCUMENT_DRIVE_NUM
	call	DiskRegisterDisk		
	pop	ax
	jnc	doneWithFloppy

	push	ax
	call	WaitForUserDictInFloppy
	pop	ax

doneWithFloppy:

endif

	segmov	es, ss
	lea	di, sourceString
	call	GetUnknownWord

	call	SpellGetICBuff
	tst	bx
	jz	exit

	; if there's a wildcard, report error
	call	CheckWildcard
	je	wcErr

	push	ds, si
	segmov	ds, ss			;DS:SI <- string to ignore
	lea	si, sourceString
	call	ICAddUser
if CONSISTENT_USER_DICT
	cmp	ax, IC_RET_OK
	jne	noUpdate
	call	ICUpdateUser
noUpdate:
endif
	pop	ds, si

	call	SendChangeNotification

;	IF WE COULDN'T ADD THE WORD TO THE USER DICTIONARY, INFORM THE USER

	cmp	ax, IC_RET_OK
	je	continue
	mov	bx, offset SpellUserDictFullString
	cmp	dx, UR_USER_DICT_FULL
	je	30$
	mov	bx, offset SpellUserDictAddGenericString
30$:
	mov	ax, (CDT_ERROR shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	SpellPutupBox
	jmp	exit
continue:
	call	ContinueSpellCheck
exit:
	.leave
	ret

wcErr:
	mov	bx, offset SpellUserDictAddWildcardString
	jmp	short 30$
SpellControlAddUnknownWordToUserDictionary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlSkipWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skips the current word then continues the spell check session.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlSkipWord	method	SpellControlClass, MSG_SC_SKIP_WORD

;	GOTO THE END OF THE SELECTION AND RESUME CHECKING

	mov	cx, SCSO_END_OF_SELECTION shl offset SCO_START_OPTIONS
	call	SetNumCharsAndSendSpellCheckToOutput
	ret
SpellControlSkipWord	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetIgnoreBufferIfDesired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the ignore buffer if the "resetIgnoreListWhenBoxCloses"
		flag is set.

CALLED BY:	GLOBAL
PASS:		bx - handle of ICBuff
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetIgnoreBufferIfDesired	proc	near	uses	ax, dx
	.enter

	tst	bx
	jz	exit
	mov	dx, offset ResetSkippedWordsKey
	call	CheckIfFlagActive
	tst	ax
	jz	exit

;	IF WE HAVE AN IGNORE BUFFER, CLEAR THE WORDS FROM IT.

	call	ICResetIgnore
exit:
	.leave
	ret
ResetIgnoreBufferIfDesired	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlDismissInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine resets the ignore buffer when the interaction
		is cleared.

CALLED BY:	GLOBAL
PASS:		cx - InteractionCommand
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlDismissInteraction	method	SpellControlClass,
				MSG_GEN_GUP_INTERACTION_COMMAND

ifdef GPC_SPELL
	; do this before closing, as closing will remove ICBuffHan
	cmp	cx, IC_DISMISS
	jne	notDismiss
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	mov	bx, ds:[di].SCI_ICBuffHan
	call	ResetIgnoreBufferIfDesired
notDismiss:
endif

	push	cx
	mov	di, offset SpellControlClass
	call	ObjCallSuperNoLock
	pop	cx
ifndef GPC_SPELL
	cmp	cx, IC_DISMISS
	jne	exit

	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	mov	bx, ds:[di].SCI_ICBuffHan
	call	ResetIgnoreBufferIfDesired

exit:
endif
	ret
SpellControlDismissInteraction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlInitiateInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine starts a spell check session.

CALLED BY:	GLOBAL
PASS:		cl - 0 if area selected.
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlInteractionInitiate	method	dynamic SpellControlClass,
					MSG_GEN_INTERACTION_INITIATE

	mov	di, offset SpellControlClass
	call	ObjCallSuperNoLock

if FLOPPY_BASED_USER_DICT
	;
	; In Redwood, we set up to read the user dictionary from the floppy,
	; if the app is interested in user dictionaries.
	;
	call	GetFeaturesAndChildBlock
	test	ax, mask SF_EDIT_USER_DICTIONARY or \
		    mask SF_ADD_TO_USER_DICTIONARY
	jz	exit
	; 
	; Check if it's necessary to ask for a User Dictionary Disk.
	;
	mov	ax, ATTR_SPELL_CONTROL_NEVER_PROMPT_FOR_USER_DICT
	call	ObjVarFindData
	jnz	skipAskingDisk	; not necessary to ask for a disk.

	; otherwise prompt the user for inserting a disk
	call	AskForUserDictInFloppy

skipAskingDisk:
	mov	ax, ATTR_SPELL_CONTROL_HAS_USER_DICT
	clr	cx
	call	ObjVarAddData

	;	
	; Can't handle checking selected word easily.
	;
exit:
	ret
else

	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	cmp	ds:[di].SCI_spellState, SBS_NO_SPELL_ACTIVE
	jnz	exit

	call	GetFeaturesAndChildBlock
	test	ax, mask SF_SIMPLE_MODAL_BOX
	jnz	simpleBox

	test	ax, mask SF_CHECK_SELECTION
	jz	exit

ifndef GPC_SPELL
	tst	ds:[di].SCI_haveSelection
	jz	exit
endif

	mov	dx, offset AutoCheckSelectionKey
	call	CheckIfFlagActive
	tst	ax
	jz	exit

ifdef GPC_SPELL
	;
	; if auto-check, but no selection, check whole document
	;
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	tst	ds:[di].SCI_haveSelection
	jz	simpleBox
endif

	mov	ax, MSG_SC_CHECK_SELECTION

;	START SPELL CHECKING SELECTION

spellCheck:
	push	ax
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	GenCallApplication
	pop	ax
	call	ObjCallInstanceNoLock

	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	GenSendToApplicationViaProcess
exit:
	ret
simpleBox:
	mov	ax, MSG_SC_CHECK_ENTIRE_DOCUMENT
	jmp	spellCheck

endif

SpellControlInteractionInitiate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellPutupBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine puts up a standard error dialog box containing
		the passed text.

CALLED BY:	GLOBAL
PASS:		bx - chunk in string resource containing text to display
		ax - type of box to display
RETURN:		nada
DESTROYED:	ax, bx, cx, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellPutupBox	proc	near	uses dx, bp, si
	.enter
	mov	dx, size GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, ax
	mov	si, bx
	mov	bx, handle Strings
	call	MemLock
	push	ds
	mov	ds, ax
	mov	si, ds:[si]		;DS:SI <- ptr to string to display
	pop	ds
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, si
	clr	ss:[bp].GADDP_finishOD.handle
	clr	ss:[bp].GADDP_finishOD.offset
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication
	add	sp, size GenAppDoDialogParams
	mov	bx, handle Strings
	call	MemUnlock
	.leave
	ret
SpellPutupBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfLowercase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a front end to the DR_LOCAL_IS_LOWER function.

CALLED BY:	GLOBAL
PASS:		ax - char to check
RETURN:		z flag clear if is lowercase
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfLowercase	proc	near
SBCS <	uses	ax							>
	.enter
SBCS <	clr	ah							>
	call	LocalIsLower
	.leave
	ret
CheckIfLowercase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfUppercase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Just a front end to the DR_LOCAL_IS_UPPER function.

CALLED BY:	GLOBAL
PASS:		ax - char to check
RETURN:		z flag clear if is uppercase
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfUppercase	proc	near
SBCS <	uses	ax							>
DBCS <	uses	ax							>
	.enter
SBCS <	clr	ah							>
	call	LocalIsUpper
	.leave
	ret
CheckIfUppercase	endp

StringCaseInfo	etype	byte
	SCI_ALL_LOWER		enum	StringCaseInfo
	;String is all lower case

	SCI_INITIAL_CAP		enum	StringCaseInfo
	;String has only one capital - the first character

	SCI_ALL_CAP		enum	StringCaseInfo
	;String has more than one capital and no lower case chars

	SCI_MIXED_CASE		enum	StringCaseInfo
	;String has a non-initial capital *and* at least one lower case
	; character



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStringCaseInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine returns StringCaseInfo for the passed string.

CALLED BY:	GLOBAL
PASS:		ds:si <- ptr to string to get info for
RETURN:		cl - StringCaseInfo
DESTROYED:	ax, si
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStringCaseInfo	proc	near
	uses	bx
	.enter
SBCS <	clr	ah			;prepare for ax = char		>
	clr	bx			;clear count
	mov	cl, SCI_ALL_LOWER
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	exit			;Exit if null string
	call	CheckIfLowercase	;If begins with lowercase, branch
	jnz	checkForMixedCase	; to just check for mixed case
	call	CheckIfUppercase	;Branch if first character is *not*
	jz	checkForAllCaps		; upper case.
	mov	cl, SCI_INITIAL_CAP	;Else, set flag.

checkForAllCaps:
	LocalGetChar	ax, dssi	;Get next char
	LocalIsNull	ax		;If at end of string, branch
	jz	endString		;
	call	CheckIfLowercase	;Branch if lowercase char found
	jnz	notAllCaps		; (check if mixed case).
	call	CheckIfUppercase	;If not upper case, branch back up
	jz	checkForAllCaps		;
	inc	bx			;BX <- # uppercase chars found
	jmp	checkForAllCaps

endString:
	tst	bx			;If we found no non-initial caps, 
	jz	exit			; exit
	mov	cl, SCI_ALL_CAP		;Else, we have "all caps".
	jmp	exit

notAllCaps:
	tst	bx			;If we found multiple upper case chars
	jnz	isMixedCase		; followed by a lower case char,
					; branch (this is mixed case). Else,
					; we either have an initial cap, or
					; some random char followed by
					; lowercase chars (like %andrew).
checkForMixedCase:
	LocalGetChar	ax, dssi	;Scan to end of string. If we encounter
	LocalIsNull	ax		; an upper case character, then this
	jz	exit			; is mixed case, so exit.
	call	CheckIfUppercase
	jz	checkForMixedCase
isMixedCase:
	mov	cl, SCI_MIXED_CASE
exit:
	.leave
	ret

GetStringCaseInfo	endp

 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSearchReplaceStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine creates a search/replace structure.

CALLED BY:	GLOBAL
PASS:		ss:bp <- ptr to inherited local vars
		*ds:si - object to set as OD of SearchReplaceStruct
		ah - SearchSpellOptions to set
			SO_PRESERVE_CASE_OF_DOCUMENT_STRING will be set if
			necessary
RETURN:		dx, bx <- handle of block containing this data:
			SearchReplaceStruct<>
			data	Null-Terminated Search String
			data	Null-Terminated Replace string

DESTROYED:	ax, cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSearchReplaceStruct	proc	near	uses	si
	.enter inherit	ReplaceCommon
	push	ax
	mov	ax, replaceSize			;
	add	ax, searchSize			;
DBCS <	shl	ax, 1				; # chars -> # bytes	>
	add	ax, size SearchReplaceStruct	;Add space for structure at
						; beginning of buffer.
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	mov	bx, handle 0
	call	MemAllocSetOwner
	mov	es, ax
	clrdw	es:[SRS_replyObject]	;No replyObj for spell checking

;
;	The following table lists whether or not we should preserve the case
;	of the document string or just use the case of the replace string.
;
;		Search String	    Replace String	Preserve Document Case?
;
;		  All Caps	   all caps/lower	     yes
;		  All Caps	   mixed case/		
;					initial cap	     no
;
;		Initial Cap	   all lower/initial cap     yes
;		Initial Cap	   all caps/mixed case	     no
;
;		  All Lower	   all lower		     yes
;		  All Lower	   initial cap/ all caps/
;				        mixed case	     no
;
;		Mixed Case	   all lower		     yes
;		Mixed Case	   initial cap/ all caps/
;				        mixed case	     no
;
;	Basically, if the replace string is all lower case, always preserve
;	the case of the document string (the user might have just typed it
;	in that way). If the replace string is mixed case (Has internal caps),
;	then always use that case (so we replace "GEOWORKS" and "geoworks"
;	with "GeoWorks"). If the replace string has an initial capital or
;	all caps, only preserve the case if the search string also has an
;	initial capital or all caps, respectively.
;
	push	ds, si
	segmov	ds, ss
	lea	si, replaceString	;DS:SI <- replace string
	call	GetStringCaseInfo	;CL <- StringCaseFlags for passed
					; string
	cmp	cl, SCI_ALL_LOWER
	je	preserveCase
	cmp	cl, SCI_MIXED_CASE
	je	noPreserveCase
	mov	ch, cl
	lea	si, searchString	;DS:SI <- search string
	call	GetStringCaseInfo	;
	cmp	cl, ch			;If case flags match, then preserve 
	jne	noPreserveCase		; case of document string. Else, branch

preserveCase:
	mov	ah, mask SO_PRESERVE_CASE_OF_DOCUMENT_STRING
	jmp	10$
noPreserveCase:
	clr	ah
10$:

	pop	ds, si			;
	pop	cx			;Restore passed SearchSpellOptions
	or	ah, ch			;
	mov	es:[SRS_params], ah	;
	mov	cx, replaceSize		;
	mov	es:[SRS_replaceSize], cx;
	mov	cx, searchSize		;CX <- size of search text
	mov	es:[SRS_searchSize], cx
	mov	di, offset SRS_searchString

;	COPY OVER THE SOURCE STRING

	push	ds
	segmov	ds, ss
	lea	si, searchString
if DBCS_PCGEOS
	rep	movsw
else
	shr	cx
	jnc	15$
	movsb
15$:
	rep	movsw
endif
	mov	cx, replaceSize
	lea	si, replaceString
if not DBCS_PCGEOS
	shr	cx
	jnc	20$
	movsb
20$:
endif
	rep	movsw
	pop	ds
	mov	dx, bx
	call	MemUnlock			;Unlock the block
	.leave
	ret
CreateSearchReplaceStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlGetICBuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the ICBuff associated with this controller.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlGetICBuff	method	SpellControlClass, MSG_SC_GET_IC_BUFF
	.enter
	mov	ax, ds:[di].SCI_ICBuffHan
	.leave
	ret
SpellControlGetICBuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddGeometryHint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a geometry hint to the passed object.

CALLED BY:	GLOBAL
PASS:		cx - geometry hint
		^lbx:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddGeometryHint	proc	near	uses	ax, dx
	.enter	
	mov	ax, MSG_GEN_ADD_GEOMETRY_HINT
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessageFixupDS
	.leave
	ret
AddGeometryHint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Customize the UI for the controller based on which features
		are active.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlGenerateUI	method	SpellControlClass, MSG_GEN_CONTROL_GENERATE_UI
	.enter
ifdef GPC_SPELL
	;
	; If dialog, display spell window at bottom of screen to make
	; room to show misspelled word in document. Note that I added
	; a total hack to attempt to center the dialog box horizontally
	; in the CUI - it looks good there :) -Don 10/2/00
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jne	notDialog
	push	ax
	mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
	mov	cx, size SpecWinSizePair
	call	ObjVarAddData
	mov	ds:[bx].SWSP_x, mask SWSS_RATIO or (PCT_5 - 10)
	mov	ds:[bx].SWSP_y, mask SWSS_RATIO or PCT_90	; auto bump up
	mov	ax, MSG_SPEC_SCAN_GEOMETRY_HINTS
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock
	pop	ax
notDialog:
endif
	mov	di, offset SpellControlClass
	call	ObjCallSuperNoLock

;	Hide the various "explain text fields" if we are not in
;	SF_SIMPLE_MODAL_BOX mode.

	call	GetFeaturesAndChildBlock
EC <	test	ax, mask SF_SKIP or mask SF_REPLACE_CURRENT		>
EC <	ERROR_Z	MUST_HAVE_EITHER_SKIP_OR_REPLACE_CURRENT_FEATURE_ENABLED>
	test	ax, mask SF_SIMPLE_MODAL_BOX
	jnz	leaveExplainText
	
	test	ax, mask SF_SKIP
	jz	noSkipExplain
	mov	si, offset SpellSkipExplain
	call	DestroyBXSI
noSkipExplain:
	test	ax, mask SF_REPLACE_CURRENT
	jz	leaveExplainText
	mov	si, offset SpellReplaceExplain
	call	DestroyBXSI

leaveExplainText:
	
;	Now, make at most one of the suggest lists visible:
;
;	if SF_SIMPLE_MODAL_BOX
;
;		if SF_SUGGESTIONS 
;			destroy SpellSuggestList
;		else
;			destoy SpellSuggestGroup
;

	test	ax, mask SF_SIMPLE_MODAL_BOX
	jz	noDestroy
	mov	si, offset SpellSuggestGroup
	test	ax, mask SF_SUGGESTIONS
	jz	destroy
	mov	si, offset SpellSuggestList
destroy:
	call	DestroyBXSI
noDestroy:


;
;	Modify the hints in the box depending upon whether it is the simple
;	modal box or the advanced box.
;

	test	ax, mask SF_SIMPLE_MODAL_BOX
	jnz	doModalHints

noHints:

;	Either setup the "context area", or make the "unknown word" text
;	visible.

	test	ax, mask SF_CONTEXT
	jnz	setupContext

	test	ax, mask SF_REPLACE_ALL or mask SF_REPLACE_CURRENT 
	jz	exit			; NEW cbh 2/19/94

	mov	ax, MSG_GEN_SET_USABLE
	mov	si, offset SpellUnknownText
	mov	dl, VUM_NOW
	call	ObjMessageFixupDS
exit:
	.leave
	ret
doModalHints:

;	Add "HINT_EXPAND_WIDTH_TO_FIT_PARENT" to the groups that contain
;	the triggers/explain text.

	mov	cx, HINT_EXPAND_WIDTH_TO_FIT_PARENT
	test	ax, mask SF_SKIP or mask SF_REPLACE_CURRENT or mask SF_SUGGESTIONS
	jz	noHints
ifndef GPC_SPELL
	mov	si, offset SpellSkipReplaceSuggestGroup
	call	AddGeometryHint
endif

	test	ax, mask SF_SKIP
	jz	noSkipHints
ifdef GPC_SPELL
	mov	si, offset SpellSkipTrigger
else
	mov	si, offset SpellSkipGroup
endif
	call	AddGeometryHint
noSkipHints:
	test	ax, mask SF_REPLACE_CURRENT
	jz	noReplaceHints
ifdef GPC_SPELL
	mov	si, offset SpellReplaceTrigger
else
	mov	si, offset SpellReplaceGroup
endif
	call	AddGeometryHint
noReplaceHints:
	test	ax, mask SF_SUGGESTIONS
	jz	noHints
	mov	si, offset SpellSuggestGroup
	call	AddGeometryHint
	jmp	noHints
	
setupContext:

;	Make the ordinary, mild-mannered GenText object a super-duper
;	object with multiple char attrs.

	test	ax, mask SF_CONTEXT		;2/19/94 cbh
	jz	exit
	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	mov	cx, mask VTSF_MULTIPLE_CHAR_ATTRS
	mov	si, offset SpellContext
	call	ObjMessageFixupDS
	jmp	exit
	
SpellControlGenerateUI	endp







COMMENT @----------------------------------------------------------------------

ROUTINE:	AskForUserDictInFloppy

SYNOPSIS:	Sets up the stupid user dictionary on the ramdisk for Redwood.

CALLED BY:	SpellControlGenerateUI

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/19/94       	Initial version

------------------------------------------------------------------------------@

if FLOPPY_BASED_USER_DICT

AskForUserDictInFloppy	proc	near		uses	cx, dx, bp, si
	.enter
	push	ds:[LMBH_handle]
	mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
		    (GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE) or \
		    mask CDBF_SYSTEM_MODAL
	mov	bx, offset SpellFloppyUserDictString
	call	SpellPutupBox
	pop	bx
	call	MemDerefDS
	.leave
	ret
AskForUserDictInFloppy	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendEllipsis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends an ellipsis char to the passed text object

CALLED BY:	GLOBAL
PASS:		^lbx:si - VisText object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendEllipsis	proc	near
SBCS <	mov	ax, C_ELLIPSIS						>
DBCS <	mov	ax, C_HORIZONTAL_ELLIPSIS				>
	push	ax
	mov	ax, MSG_VIS_TEXT_APPEND
	mov	cx, 1		;CX <- 
	mov	dx, ss
	mov	bp, sp		;DX:BP <- ptr to ellipsis char
	call	ObjMessageCallFixupDS
	add	sp, size word
	ret
AppendEllipsis	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyBXSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys the passed object

CALLED BY:	GLOBAL
PASS:		^lbx:si - object to destroy
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyBXSI	proc	near	uses	ax, dx, bp
	.enter
	mov	ax, MSG_GEN_DESTROY
	mov	dl, VUM_NOW
	clr	bp
	call	ObjMessageFixupDS
	.leave
	ret
DestroyBXSI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HighlightSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Highlights the "selection" in the passed context-display
		text object

CALLED BY:	GLOBAL
PASS:		^lbx:si - object
		es - segment of block containing ContextData
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HighlightSelection	proc	near
	params	local	VisTextSetTextStyleParams		
	.enter
	clr	ax
	clrdw	params.VTSTSP_range.VTR_start, ax
	movdw	params.VTSTSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	params.VTSTSP_styleBitsToSet, ax
	mov	params.VTSTSP_styleBitsToClear, mask TextStyle
	mov	params.VTSTSP_extendedBitsToSet, ax
	mov	params.VTSTSP_extendedBitsToClear, mask VisTextExtendedStyles
	call	SetStyle

	movdw	dxax, es:[CD_selection].VTR_start
	subdw	dxax, es:[CD_range].VTR_start
EC <	tst	dx							>
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		>
	movdw	params.VTSTSP_range.VTR_start, dxax

	movdw	dxax, es:[CD_selection].VTR_end
	subdw	dxax, es:[CD_range].VTR_start
EC <	tst	dx							>
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		>
	movdw	params.VTSTSP_range.VTR_end, dxax

;	mov	params.VTSTSP_styleBitsToSet, dx
	mov	params.VTSTSP_styleBitsToSet, mask TS_UNDERLINE
	mov	params.VTSTSP_styleBitsToClear, dx
;	mov	params.VTSTSP_extendedBitsToSet, mask VTES_BOXED
	mov	params.VTSTSP_extendedBitsToSet, dx
	mov	params.VTSTSP_extendedBitsToClear, dx
	call	SetStyle
	.leave
	ret
SetStyle:
	push	bp
	mov	ax, MSG_VIS_TEXT_SET_TEXT_STYLE
	mov	dx, size params
	lea	bp, params
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	pop	bp
	retn
HighlightSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlContext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays context for the misspelled phrase...

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpellControlContext	method	dynamic SpellControlClass,
				MSG_META_CONTEXT
	.enter

;	Since the context arrives asynchronously, the user may already have
;	aborted the spell check by closing the box, etc. If so, free up
;	the context information.

	mov	bx, bp
	cmp	ds:[di].SCI_spellState, SBS_NO_SPELL_ACTIVE
	LONG je	freeAndExit
	push	bx
	call	MemLock
	mov	es, ax

;	Nuke any CRs or other special chars.

	push	ds, si
	mov	si, offset CD_contextData
	segmov	ds, es
nextChar:
	LocalGetChar	ax, dssi
	LocalIsNull	ax		;Exit if at end of text
	jz	EOT

;	If special char (char < C_SPACE), replace it with C_SPACE.

SBCS <	cmp	al, C_SPACE						>
DBCS <	cmp	ax, C_SPACE						>
	jae	nextChar
SBCS <	mov	{byte} ds:[si][-1], C_SPACE				>
DBCS <	mov	{wchar} ds:[si][-2], C_SPACE				>
	jmp	nextChar
EOT:
	pop	ds, si
	


;	We will put the text from the object into the context field, and 
;	highlight the selected area.

	call	GetFeaturesAndChildBlock
EC <	test	ax, mask SF_CONTEXT					>
EC <	ERROR_Z	NO_CONTEXT_FEATURE_SET					>

	mov	si, offset SpellContext		;^lBX:SI <- context

	mov	ax, MSG_META_SUSPEND
	call	ObjMessageFixupDS
	
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjMessageFixupDS
	
	tstdw	es:[CD_range.VTR_start]
	jz	atStart

;	If will not be displaying the start of the object, add an ellipsis,
;	and update the selection too.

	incdw	es:[CD_selection.VTR_start]
	incdw	es:[CD_selection.VTR_end]
	call	AppendEllipsis

atStart:

;	Copy the text from the context block into the context display area

	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	mov	dx, es
	mov	bp, offset CD_contextData
	clr	cx			;Null-terminated text
	call	ObjMessageFixupDS

	cmpdw	es:[CD_range].VTR_end, es:[CD_numChars], ax
	jz	atEnd

;	If will not be displaying the end of the object, add an ellipsis

	call	AppendEllipsis
atEnd:

	call	HighlightSelection

	mov	ax, MSG_META_UNSUSPEND
	call	ObjMessageCallFixupDS

	pop	bx
	call	MemUnlock
exit:
	.leave
	ret
freeAndExit:
	call	MemFree
	jmp	exit
SpellControlContext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpellControlVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opening spell dialog, start spell type based on selection

CALLED BY:	MSG_VIS_OPEN
PASS:		see MSG_VIS_OPEN
RETURN:		see MSG_VIS_OPEN
DESTROYED:	see MSG_VIS_OPEN
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/4/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0  ; let Text preferences decide to start spell check
ifdef GPC_SPELL
SpellControlVisOpen	method	dynamic	SpellControlClass, MSG_VIS_OPEN
	mov	di, offset SpellControlClass
	call	ObjCallSuperNoLock
	;
	; force queue start of spell check
	;
	mov	ax, MSG_SC_CHECK_ENTIRE_DOCUMENT
	mov	di, ds:[si]
	add	di, ds:[di].SpellControl_offset
	tst	ds:[di].SCI_haveSelection
	jz	gotSpellMethod
	mov	ax, MSG_SC_CHECK_SELECTION
gotSpellMethod:
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
SpellControlVisOpen	endm
endif
endif

SpellControlCode ends
