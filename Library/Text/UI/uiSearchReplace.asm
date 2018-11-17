COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiSearchReplaceControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	SearchReplaceControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/92		Initial version

DESCRIPTION:
	This file contains routines to implement SearchReplaceControlClass

	$Id: uiSearchReplace.asm,v 1.1 97/04/07 11:17:48 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	SearchReplaceControlClass		;declare the class record

ifdef GPC_SEARCH
	OverrideCenterOnMonikersClass
endif

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextSRControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	SearchReplaceControlScanFeatureHints --
		MSG_GEN_CONTROL_SCAN_FEATURE_HINTS for SearchReplaceControlClass

DESCRIPTION:	Alter SRCF_REPLACE_ALL_IN_SELECTION based on .ini file.

PASS:
	*ds:si - instance data
	es - segment of SearchReplaceControlClass

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
	brianc	1/4/98		Initial version

------------------------------------------------------------------------------@
ifdef GPC_SEARCH
SearchReplaceControlScanFeatureHints	method	dynamic SearchReplaceControlClass, MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
	mov	di, offset SearchReplaceControlClass
	call	ObjCallSuperNoLock
	push	dx
	segmov	ds, cs, cx
	mov	si, offset replaceInSelectionStringCat
	mov	dx, offset replaceInSelectionStringKey
	call	InitFileReadBoolean	; C clr if found
	pop	dx
	jc	removeReplaceInSelection
	cmp	ax, TRUE
	je	leaveReplaceInSelection
removeReplaceInSelection:
	mov	ds, dx
	mov	si, bp
	ornf	ds:[si].GCSI_appProhibited, mask SRCF_REPLACE_ALL_IN_SELECTION
leaveReplaceInSelection:
	;
	; build feature flags to determine if we should have close button
	;
	mov	ds, dx
	mov	si, bp
	mov	ax, SRC_DEFAULT_FEATURES
	ornf	ax, ds:[si].GCSI_userAdded
	mov	bx, ds:[si].GCSI_userRemoved
	not	bx
	andnf	ax, bx
	ornf	ax, ds:[si].GCSI_appRequired
	mov	bx, ds:[si].GCSI_appProhibited
	not	bx
	andnf	ax, bx
	call	SR_CheckFullHeight
	jnc	notFullHeight
	ornf	ds:[si].GCSI_appProhibited, mask SRCF_CLOSE
notFullHeight:
	ret
SearchReplaceControlScanFeatureHints	endm

replaceInSelectionStringCat	char	"text",0
replaceInSelectionStringKey	char	"ReplaceInSelection",0
endif ; GPC_SEARCH
		
COMMENT @----------------------------------------------------------------------

MESSAGE:	SearchReplaceControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for SearchReplaceControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of SearchReplaceControlClass

	ax - The message

RETURN:
	cx:dx - list of children

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
SearchReplaceControlGetInfo	method dynamic	SearchReplaceControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SRC_dupInfo
	GOTO	SR_CopyDupInfoCommon

SearchReplaceControlGetInfo	endm

SR_CopyDupInfoCommon	proc	far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SR_CopyDupInfoCommon	endp

SRC_dupInfo	GenControlBuildInfo	<
	mask GCBF_DO_NOT_DESTROY_CHILDREN_WHEN_CLOSED,	; GCBI_flags
	offset SRC_IniFileKey,		; GCBI_initFileKey
	offset SRC_gcnList,		; GCBI_gcnList
	length SRC_gcnList,		; GCBI_gcnCount
	offset SRC_notifyTypeList,	; GCBI_notificationList
	length SRC_notifyTypeList,	; GCBI_notificationCount
	SRCName,			; GCBI_controllerName

	handle SearchReplaceControlUI,	; GCBI_dupBlock
	offset SRC_childList,		; GCBI_childList
	length SRC_childList,		; GCBI_childCount
	offset SRC_featuresList,		; GCBI_featuresList
	length SRC_featuresList,		; GCBI_featuresCount
	SRC_DEFAULT_FEATURES,		; GCBI_features

	handle SearchReplaceControlToolboxUI,	; GCBI_toolBlock
	offset SRC_toolList,		; GCBI_toolList
	length SRC_toolList,		; GCBI_toolCount
	offset SRC_toolFeaturesList,	; GCBI_toolFeaturesList
	length SRC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SRC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	SRC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

SRC_helpContext	char	"dbFindRepl", 0

SRC_IniFileKey	char	"searchreplace", 0

SRC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_REPLACE_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE>

SRC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SEARCH_REPLACE_ENABLE_CHANGE>

;---

ifdef GPC_SEARCH

SEARCH_TOP_FEATURES equ mask SRCF_FIND_NEXT or mask SRCF_FIND_PREV or mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION or mask SRCF_FIND_FROM_TOP or mask SRCF_SPECIAL_CHARS or mask SRCF_WILDCARDS

SEARCH_BOTTOM_FEATURES equ mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION

SRC_childList	GenControlChildInfo	\
	<offset SearchReplyBar, mask SRCF_CLOSE, 0>,
	<offset SearchTop, SEARCH_TOP_FEATURES, 0>,
	<offset SearchReplaceMisc, mask SRCF_IGNORE_CASE or mask SRCF_PARTIAL_WORDS, 0>,
	<offset SearchBottom, SEARCH_BOTTOM_FEATURES, 0>
else
SRC_childList	GenControlChildInfo	\
	<offset SearchReplyBar, mask SRCF_FIND_NEXT or mask SRCF_FIND_PREV or mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION or mask SRCF_CLOSE or mask SRCF_FIND_FROM_TOP, 0>,	
	<offset SearchText, mask SRCF_FIND_NEXT or mask SRCF_FIND_PREV or mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION or mask SRCF_FIND_FROM_TOP, 0>,
	<offset ReplaceText, mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION, 0>,
	<offset SearchReplaceMisc, mask SRCF_SPECIAL_CHARS or mask SRCF_WILDCARDS or mask SRCF_IGNORE_CASE or mask SRCF_PARTIAL_WORDS, 0>
endif


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SRC_featuresList	GenControlFeaturesInfo	\
	<offset MiscChars, MiscCharsName, 0>,
	<offset WildcardChars, WildcardName, 0>,
	<offset	CaseSensitiveOption, IgnoreCaseName, 0>,
	<offset	PartialWordOption, PartialWordName, 0>,
	<offset	ReplaceAllTrigger, ReplaceAllName, 0>,
	<offset	ReplaceAllInSelectionTrigger, ReplaceAllInSelectionName, 0>,
	<offset	ReplaceTrigger, ReplaceCurrentName, 0>,
	<offset	FindPrevTrigger, FindPrevName, 0>,
	<offset	FindNextTrigger, FindNextName, 0>,
	<offset CloseTrigger, CloseName, 0>,
	<offset FindFromTopTrigger, FindFromTopName, 0>,
	<offset SearchNoteOptions, SearchNoteOptionsName, 0>

SRC_toolList		GenControlChildInfo \
	<offset SearchReplaceToolTrigger, mask SRCTF_SEARCH_REPLACE, mask GCCF_IS_DIRECTLY_A_FEATURE>

SRC_toolFeaturesList	GenControlFeaturesInfo \
	<offset SearchReplaceToolTrigger, SRCName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddOrRemoveToGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the app has supplied a selection type (via the appropriate 
		vardata entry), we add ourselves to the select state list.

CALLED BY:	GLOBAL
PASS:		ax - MSG_META_GCN_LIST_ADD/REMOVE
		*ds:si - object
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddOrRemoveToGCNList	proc	far
	.enter

;	If the user has set this attribute, this means that we need to update
;	the REPLACE_IN_SELECTION trigger, so add ourselves to the SELECT_STATE
;	GCN list.

	push	ax
	mov	ax, ATTR_SEARCH_CONTROL_SELECTION_TYPE
	call	ObjVarFindData
	pop	ax
	jnc	exit
	
	sub	sp, size GCNListParams
	mov	bp, sp
	mov	cx, ds:[LMBH_handle]
	movdw	ss:[bp].GCNLP_optr, cxsi
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, dx
	call	GenCallApplication
	add	sp, size GCNListParams
exit:
	.leave
	ret
AddOrRemoveToGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlAddToGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method will allow the object to be added to/removed from
		the GCNLists only if the appropriate vardata entry is present:
		ATTR_SEARCH_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlAddToGCNList	method	SearchReplaceControlClass,
				MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
	.enter
	push	ax
	mov	ax, ATTR_SEARCH_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS
	call	ObjVarFindData
	pop	ax
	jnc	exit
	
;	The ATTR is present, then pass the message to our superclass, thereby
;	putting ourselves on the enable/disable list.

	mov	di, offset SearchReplaceControlClass
	call	ObjCallSuperNoLock
exit:

;	Add ourselves to the GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE list
;	so we can get MSG_ABORT_ACTIVE_SEARCH.

	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
	call	AddOrRemoveToGCNList
	
;	Now, add ourselves from the SelectionState list if the app
;	has supplied a selectionType

	mov	ax, MSG_META_GCN_LIST_ADD
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	call	AddOrRemoveToGCNList
	.leave
	ret
SearchReplaceControlAddToGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a handler for the GWNT_SELECT_STATE_CHANGE 
		notification - all others are ignored.

CALLED BY:	GLOBAL
PASS:		cx - manuf id
		dx - type
		bp - block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlNotifyWithDataBlock	method SearchReplaceControlClass,
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	.enter
	cmp	dx, GWNT_SELECT_STATE_CHANGE
	jne	callSuper
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	je	handleIt
callSuper:
	mov	di, offset SearchReplaceControlClass
	call	ObjCallSuperNoLock
	.leave
	ret
handleIt:

;	There has been a change in selection in the targeted object. Update
;	the ReplaceAllInSelection trigger appropriately.
;
;	If the app provided a selection type to compare, use it, otherwise
;	use SDT_TEXT by default. 
;


	push	ax, cx, dx, bp, es
	clr	dl				;Assume no selection
	tst	bp				;If no target, then there is
	jz	noBlock				; no selection.

;	Lock down the notification block and check to see if there is a
;	selection of the appropriate type.

	mov	bx, bp
	call	MemLock
	mov	es, ax
	mov	ax, ATTR_SEARCH_CONTROL_SELECTION_TYPE
	call	ObjVarFindData
	mov	ax, SDT_TEXT
	jnc	noTypeSet
	mov	ax, ds:[bx]			;AX <- type of selection we
						; will operate on.
noTypeSet:
	cmp	ax, es:[NSSC_selectionType]	;If we can't operate on the
	jnz	noSelection			; current selection, then
						; assume no selection.
	mov	dl, es:[NSSC_clipboardableSelection]
noSelection:
	mov	bx, bp
	call	MemUnlock			;Unlock the data block

noBlock:

;	If the new selection state is different from the old selection state,
;	then update the search/replace triggers accordingly.

	cmp	dl, ds:[di].SRCI_haveSelection
	je	gotoSuper
	mov	ds:[di].SRCI_haveSelection, dl
	call	UpdateSearchReplaceTriggers
gotoSuper:
	pop	ax, cx, dx, bp, es
	jmp	callSuper
SearchReplaceControlNotifyWithDataBlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We subclass MSG_META_RESOLVE_VARIANT_SUPERCLASS here to add
		our hints before we are built

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlResolveVariantSuperclass	method	SearchReplaceControlClass,
				MSG_META_RESOLVE_VARIANT_SUPERCLASS
	push	ax, cx, dx, bp


;	Set up size hints for this critter

	mov	ax, HINT_SIZE_WINDOW_AS_RATIO_OF_FIELD
	mov	cx, size SpecWinSizePair
	call	ObjVarAddData
	mov	ds:[bx].SWSP_x, mask SWSS_RATIO or PCT_55

	mov	ds:[bx].SWSP_y, 0

if 0
	mov	ax, HINT_MINIMUM_SIZE
	mov	cx, size CompSizeHintArgs
	call	ObjVarAddData
	mov	ds:[bx].CSHA_width, SpecWidth<SST_PIXELS, 250>
	mov	ds:[bx].CSHA_height, 0
	mov	ds:[bx].CSHA_count, 0
endif	

	pop	ax, cx, dx, bp
	mov	di, offset SearchReplaceControlClass
	GOTO	ObjCallSuperNoLock
SearchReplaceControlResolveVariantSuperclass	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the search box

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
	atw	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlInitiate	method	SearchReplaceControlClass,
					MSG_GEN_CONTROL_NOTIFY_INTERACTABLE
	mov	di, offset SearchReplaceControlClass
	call	ObjCallSuperNoLock

if 0
	call	UpdateSearchControlUI		;Make different portions of
						; the UI visible depending
						; on the flags passed in.

;	ENABLE OR DISABLE THE UI OF THE BOX DEPENDING UPON WHETHER OR NOT THERE
;	IS AN OBJECT THAT HANDLES SEARCH METHODS AVAILABLE

	mov	di, ds:[si]
	add	di, ds:[di].SearchReplaceControl_offset
	test	ds:[di].DBI_state, mask DBS_OPEN
	jnz	alreadyOpen
	ornf	ds:[di].DBI_state, mask DBS_OPEN
	clr	cx			;Disable all the UI
	call	UpdateSearchUIForTargetObject

	mov	ax, MSG_QUERY_IF_HANDLES_SEARCH_SPELL_METHODS
	clrdw	bxdi
	call	GenControlOutputActionRegs

alreadyOpen:
endif

;	SELECT THE SEARCH AND REPLACE TEXT ENTRIES

	call	SR_GetFeaturesAndChildBlock
	mov_tr	cx, ax
	test	cx, mask SRCF_FIND_NEXT or mask SRCF_FIND_PREV or mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL
	jz	exit
	push	si
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	si, offset SearchText
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	push	dx
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE	;dxax = size
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	dx

	pop	si

	mov_tr	bp, ax			;BP <- # chars in search text
	mov	cx, bx			;CX:DX <- optr of SearchText object
	mov	dx, offset SearchText
	mov	ax, MSG_META_TEXT_EMPTY_STATUS_CHANGED
	call	ObjCallInstanceNoLock

	call	SR_GetFeaturesAndChildBlock
	test	ax, mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL
	jz	exit
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	mov	si, offset ReplaceText
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

exit:	
	ret
SearchReplaceControlInitiate	endp

;---

SR_GetFeaturesAndChildBlock	proc	far
EC <	push	es, di							>
EC <	mov	di, segment GenControlClass				>
EC <	mov	es, di							>
EC <	mov	di, offset GenControlClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	CONTROLLER_OBJECT_INTERNAL_ERROR		>
EC <	pop	es, di							>
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData			;ds:bx = data
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
SR_GetFeaturesAndChildBlock	endp

TextSRControlCommon ends

;---

TextSRControlCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlRemoveFromGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method will allow the object to be added to/removed from
		the GCNLists only if the appropriate vardata entry is present:
		ATTR_SEARCH_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlRemoveFromGCNList	method	SearchReplaceControlClass,
				MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
	.enter
	push	ax
	mov	ax, ATTR_SEARCH_CONTROL_INTERACT_ONLY_WITH_TARGETED_TEXT_OBJECTS
	call	ObjVarFindData
	pop	ax
	jnc	exit
	
;	The ATTR is present, then pass the message to our superclass, thereby
;	putting ourselves on the enable/disable list.

	mov	di, offset SearchReplaceControlClass
	call	ObjCallSuperNoLock
exit:

;	Remove ourselves from the GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
;	list so we can get MSG_ABORT_ACTIVE_SEARCH.

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_SPELL_CHANGE
	call	AddOrRemoveToGCNList

;	Now, remove ourselves from the SelectionState list if the app
;	has supplied a selectionType

	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	call	AddOrRemoveToGCNList
	.leave
	ret
SearchReplaceControlRemoveFromGCNList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueryUserForGlobalDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine puts up a standard error dialog box containing
		the passed text.

CALLED BY:	GLOBAL
PASS:		bx - chunk in string resource containing text to display
		*DS:SI <- SearchReplaceControl
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
QueryUserForGlobalDelete	proc	near	uses dx, bp, si
	.enter
	mov	dx, size GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, (CDT_QUESTION shl offset CDBF_DIALOG_TYPE or GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE)
	mov	di, offset GlobalDeleteQueryString
	mov	bx, handle GlobalDeleteQueryString
	call	MemLock
	push	ds
assume	ds:TextStrings
	mov	ds, ax
	mov	di, ds:[di]		;DS:SI <- ptr to string to display
assume	ds:dgroup
	pop	ds
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, di
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GADDP_finishOD.handle, ax
	mov	ss:[bp].GADDP_finishOD.offset, si
	mov	ss:[bp].GADDP_message, MSG_SRC_REPLACE_ALL_OCCURRENCES_QUERY_RESPONSE
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication
	add	sp, size GenAppDoDialogParams
	mov	bx, handle TextStrings
	call	MemUnlock
	.leave
	ret
QueryUserForGlobalDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSearchReplaceOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets search and replace options from the list items in the box.
CALLED BY:	GLOBAL
PASS:		ds - segment of block SearchReplaceControl is in
RETURN:		cl - SearchOptions
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSearchReplaceOptions	proc	near	uses	ax, bx, dx, di, si, bp
	.enter

ifdef GPC_SEARCH
	mov	cx, mask SO_IGNORE_CASE or mask SO_PARTIAL_WORD
else
	mov	cx, mask SO_IGNORE_CASE		; default SearchOptions
endif

	mov	ax, ATTR_SEARCH_CONTROL_DEFAULT_SEARCH_OPTIONS
	call	ObjVarFindData
	jnc	gotDefaultOptions

	mov	cl, {SearchOptions}ds:[bx]
	andnf	cl, mask SO_IGNORE_CASE or mask SO_PARTIAL_WORD

gotDefaultOptions:
	call	SR_GetFeaturesAndChildBlock
	test	ax, mask SRCF_IGNORE_CASE or mask SRCF_PARTIAL_WORDS
	jz	exit

	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	si, offset SearchReplaceOptions
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov_tr	cx, ax
exit:
	.leave
	ret
GetSearchReplaceOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlReplaceAllResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the user clicked "YES" in the query dialog box, this 
		continues with the global search and replace.

CALLED BY:	GLOBAL
PASS:		cx - InteractionCommand
			IC_YES, IC_NO, IC_NULL (if dismissed by system)
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlReplaceAllResponse	method	SearchReplaceControlClass,
				MSG_SRC_REPLACE_ALL_OCCURRENCES_QUERY_RESPONSE
	cmp	cx, IC_YES
	jne	exit
	mov	ax, MSG_SRC_REPLACE_ALL_OCCURRENCES_NO_QUERY
	call	ObjCallInstanceNoLock
exit:
	ret
SearchReplaceControlReplaceAllResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToReplaceTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed method off to the replace trigger.

CALLED BY:	GLOBAL
PASS:		ax - method to send
		cx, dx, bp - data
		*ds:si - SearchReplaceControl
RETURN:		nada
DESTROYED: 	ax, cx, dx
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMessageToReplaceTrigger	proc	near	uses	si,bp, di
	.enter
	push	ax
	call	SR_GetFeaturesAndChildBlock
	test	ax, mask SRCF_REPLACE_CURRENT
	pop	ax
	jz	exit
	mov	si, offset ReplaceTrigger
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	.leave
	ret
SendMessageToReplaceTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlSearchAborted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the UI gadgetry that depends on a search being
		active.

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
	atw	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlSearchAborted	method	SearchReplaceControlClass,
						MSG_SRC_SEARCH_ABORTED,
						MSG_ABORT_ACTIVE_SEARCH
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	SendMessageToReplaceTrigger
	ret
SearchReplaceControlSearchAborted	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateIfFeatureExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine calls ObjMessage if the zero flag is clear.

CALLED BY:	GLOBAL
PASS:		z flag clear if we want to send a message
		^lbx:di - object
		ax - message
RETURN:		nada
DESTROYED:	di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateIfFeatureExists	proc	near
	.enter
	jz	exit
	push	ax, cx, dx, bp, si
	mov	si, di
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, dx, bp, si
exit:
	.leave
	ret
UpdateIfFeatureExists	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSearchReplaceTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the search and replace triggers.

CALLED BY:	GLOBAL
PASS:		*ds:si - SearchReplaceControl object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSearchReplaceTriggers	proc	far
	class	SearchReplaceControlClass
	.enter

;	We update the search and replace triggers - their enabled status
;	depends upon 2 factors:
;
;	1) The flags set in SRCI_enableFlags
;	2) Whether or not there is text in the SearchText box
;
;	And, for the ReplaceAllInSelectionTrigger,
;
;	3) Whether or not there is a selection or not (SRCI_haveSelection)
;

	call	SR_GetFeaturesAndChildBlock
	push	ax			;Save features	

;	Determine whether or not there is text in the SearchText box. If not,
;	all the triggers should be disabled.

	push	si
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	mov	si, offset SearchText
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;Returns AX = text size
	pop	si

	mov_tr	bp, ax			;BP <- # chars in the text object
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	tst	bp			;If no search text, 
	jz	setSearchObjects	; disable all the triggers

;	If searching is not allowed in this object, then branch to disable
;	the triggers (else, enable them).

	mov	di, ds:[si]		;
	add	di, ds:[di].SearchReplaceControl_offset
	test	ds:[di].SRCI_enableFlags, mask SREF_SEARCH
	jz	setSearchObjects	;Branch if searching is not allowed
	mov	ax, MSG_GEN_SET_ENABLED
setSearchObjects:
	pop	dx			;DX <- SearchReplaceControlFeatures

	mov	di, offset FindNextTrigger
	test	dx, mask SRCF_FIND_NEXT
	call	UpdateIfFeatureExists

	mov	di, offset FindPrevTrigger
	test	dx, mask SRCF_FIND_PREV
	call	UpdateIfFeatureExists

	mov	di, offset FindFromTopTrigger
	test	dx, mask SRCF_FIND_FROM_TOP
	call	UpdateIfFeatureExists


;	Now, do the "replace all" trigger - it should be enabled if there is
;	search text and the SSEF_REPLACE bit is set.

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	tst	bp			;Branch to disable if no text
	jz	setReplaceObjects
	mov	di, ds:[si]		;
	add	di, ds:[di].SearchReplaceControl_offset
	test	ds:[di].SRCI_enableFlags, mask SREF_REPLACE
	jz	setReplaceObjects	;Branch if replaces are not allowed
	mov	ax, MSG_GEN_SET_ENABLED
setReplaceObjects:	
	mov	di, offset ReplaceAllTrigger
	test	dx, mask SRCF_REPLACE_ALL
	call	UpdateIfFeatureExists

;	Now, do the "replace all in selection" trigger - it should match
;	the state of the "replace all" trigger, except that we force it 
;	to be disabled if there is no selection.

	mov	di, ds:[si]		;
	add	di, ds:[di].SearchReplaceControl_offset
	tst	ds:[di].SRCI_haveSelection
	jnz	haveSelection
	mov	ax, MSG_GEN_SET_NOT_ENABLED
haveSelection:
	test	dx, mask SRCF_REPLACE_ALL_IN_SELECTION
	mov	di, offset ReplaceAllInSelectionTrigger
	call	UpdateIfFeatureExists
	.leave
	ret
UpdateSearchReplaceTriggers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlSearchTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is *no* text in the search text object, this
		method handler disables the search/replace all triggers

CALLED BY:	GLOBAL
PASS:		CX:DX <- object that was made dirty - ignore this method
			 if it ain't the search object.
		bp - non-zero if text object is empty	 
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlSearchTextEmptyStatusChanged	method	SearchReplaceControlClass,
				MSG_META_TEXT_EMPTY_STATUS_CHANGED
	cmp	dx, offset SearchText
	jne	exit

	call	UpdateSearchReplaceTriggers
exit:
	ret
SearchReplaceControlSearchTextEmptyStatusChanged	endm


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlTextLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler is called when the search or replace box 
		loses the focus. It disables various triggers.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlTextLostFocus	method	SearchReplaceControlClass, MSG_META_TEXT_LOST_FOCUS
	clr	ds:[di].SRCI_focusInfo
	mov	ax, MSG_SRC_UPDATE_SPECIAL_CHARS_BY_FOCUS_INFO
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage
SearchReplaceControlTextLostFocus	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlUpdateSpecialCharsByFocusInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the current UI state of the special chars buttons, 
		depending upon what has the focus.

CALLED BY:	GLOBAL
PASS:		*ds:si <- search box
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlUpdateSpecialCharsByFocusInfo	method	SearchReplaceControlClass,
			MSG_SRC_UPDATE_SPECIAL_CHARS_BY_FOCUS_INFO
	call	UpdateSpecialCharsByFocusInfo
	ret
SearchReplaceControlUpdateSpecialCharsByFocusInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSpecialCharsByFocusInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine checks to see which item has the focus, and
		updates the special char UI accordingly.

CALLED BY:	GLOBAL
PASS:		*ds:si <- SearchReplaceControl object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateSpecialCharsByFocusInfo	proc	near
	class	SearchReplaceControlClass

	mov	bx, ds:[si]
	add	bx, ds:[bx].SearchReplaceControl_offset
	mov	dl, ds:[bx].SRCI_focusInfo

	call	SR_GetFeaturesAndChildBlock
	mov_tr	cx, ax
	test	cl, mask SRCF_SPECIAL_CHARS or mask SRCF_WILDCARDS
	jz	exit

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	dl, SRFI_SEARCH_TEXT		;If the search text has the
	jz	enableSearchGadgets		; focus, enable all UI

EC <	cmp	dl, SRFI_REPLACE_TEXT					>
EC <	ERROR_NZ	BAD_FOCUS_INFO					>


;	DISABLE THE CHARS NOT ALLOWED IN THE REPLACE STRING
;	(Wildcards and Graphics chars)

ifndef GPC_SEARCH  ; separate lists, no disabling
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	di, offset justWildcardsList
	test	cl, mask SRCF_SPECIAL_CHARS
	jz	disable
	mov	di, offset disableWildcardsAndGraphicsList
	test	cl, mask SRCF_WILDCARDS
	jnz	disable
	mov	di, offset disableJustGraphicsList
disable:
	mov	dl, VUM_NOW
	mov	si, cs
	call	SendMessageToItemsInList
endif

	mov	ax, MSG_GEN_SET_ENABLED		;Enable other special chars
	mov	di, offset nonGraphicsList	;
	test	cl, mask SRCF_SPECIAL_CHARS
	jz	exit
doCall:
	mov	dl, VUM_NOW
	mov	si, cs
ifdef GPC_SEARCH
	push	di
	call	SendMessageToItemsInList
	pop	di
	cmp	di, offset justWildcardsList
	je	exit
	test	cl, mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	exit
	mov	di, offset replaceList
	mov	si, cs
	call	SendMessageToItemsInList
else
	call	SendMessageToItemsInList
endif
exit:
	ret

enableSearchGadgets:
	mov	di, offset miscCharsList	;Enable all but wildcards
	test	cl, mask SRCF_WILDCARDS		; if wildcard bit is clear.
	jz	doCall
	mov	di, offset allCharsList		;Else, enable all chars if
	test	cl, mask SRCF_SPECIAL_CHARS	; both bits set.
	jnz	doCall
	mov	di, offset justWildcardsList	;Else, just enable the 
	jmp	doCall				; wildcards

UpdateSpecialCharsByFocusInfo	endp

allCharsList		lptr	WildcardChars
miscCharsList		lptr	GraphicSpecialChar
nonGraphicsList		lptr	PageBreakSpecialChar
			lptr	CRSpecialChar
			lptr	TabSpecialChar
			lptr	0

ifdef GPC_SEARCH
replaceList		lptr	RPageBreakSpecialChar
			lptr	RCRSpecialChar
			lptr	RTabSpecialChar
			lptr	0
endif

justWildcardsList 	lptr	WildcardChars
			lptr	0

disableWildcardsAndGraphicsList	lptr	WildcardChars
disableJustGraphicsList		lptr	GraphicSpecialChar
				lptr	0		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlTextGainedFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method handler is called when the search or replace box 
		loses the focus. It disables various triggers.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlTextGainedFocus	method	SearchReplaceControlClass,
			MSG_META_TEXT_GAINED_FOCUS
	mov	al, SRFI_SEARCH_TEXT
	cmp	dx, offset SearchText
	je	10$
	mov	al, SRFI_REPLACE_TEXT
10$:
	mov	ds:[di].SRCI_focusInfo, al
	call	UpdateSpecialCharsByFocusInfo

	ret
SearchReplaceControlTextGainedFocus	endp


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
	.enter
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
	.enter
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
SBCS <	clr	ah							>
	clr	bx			;bx = upper case count
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
SBCS <	searchString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (char)>
SBCS <	replaceString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (char)>
DBCS <	searchString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (wchar)>
DBCS <	replaceString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (wchar)>
	searchLength	local	word
	replaceLength	local	word

	.enter inherit far	
	push	ax
	mov	ax, replaceLength		;
DBCS <	shl	ax, 1				; # chars -> # bytes	>
	add	ax, searchLength		;
DBCS <	add	ax, searchLength		; # chars -> # bytes	>
	add	ax, size SearchReplaceStruct	;Add space for structure at
						; beginning of buffer.
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	mov	ax, ds:[LMBH_handle]
	mov	es:[SRS_replyObject].handle, ax
	mov	es:[SRS_replyObject].chunk, si
;
;	NOTE: The following code is different than the code in the spell
;	      library. We don't want to preserve document case in most
;	      cases.
;
;
;	The following table lists whether or not we should preserve the case
;	of the document string or just use the case of the replace string.
;
;		Search String	    Replace String	Preserve Document Case?
;
;		  All Caps	   all caps		     yes
;		  All Caps	   all lower/mixed case/		
;					initial cap	     no
;
;		Initial Cap	   initial cap     	     yes
;		Initial Cap	   all lower/all caps/
;					mixed case	     no
;
;		  All Lower	   all lower		     yes
;		  All Lower	   initial cap/ all caps/
;				        mixed case	     no
;
;		Mixed Case	    all			     never
;
;	Basically, if the replace string has the same case as the search
;	string, we want to maintain whatever case existed in the document.
;
;	Otherwise, the replace string overrides the document case.
;
	push	ds, si
	segmov	ds, ss
	lea	si, replaceString	;DS:SI <- replace string
	call	GetStringCaseInfo	;CL <- StringCaseFlags for passed
					; string
	mov	ch, cl
	lea	si, searchString
	call	GetStringCaseInfo
	clr	ah
	cmp	cl, SCI_MIXED_CASE
	je	noPreserveCase
	cmp	cl, ch			;If case flags match, then preserve 
	jne	noPreserveCase		; case of document string. Else, branch

	mov	ah, mask SO_PRESERVE_CASE_OF_DOCUMENT_STRING
noPreserveCase:

	pop	ds, si			;
	pop	cx			;Restore passed SearchSpellOptions
	or	ah, ch			;
	mov	es:[SRS_params], ah	;
	mov	cx, replaceLength	;
	mov	es:[SRS_replaceSize], cx;
	mov	cx, searchLength	;CX <- size of search text
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
	mov	cx, replaceLength
	lea	si, replaceString
if DBCS_PCGEOS
	rep	movsw
else
	shr	cx
	jnc	20$
	movsb
20$:
	rep	movsw
endif
	pop	ds
	mov	dx, bx
	call	MemUnlock			;Unlock the block
	.leave
	ret
CreateSearchReplaceStruct	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertGraphicToSpecialChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts the graphics char to the appropriate char

CALLED BY:	GLOBAL
PASS:		es:di - ptr to char *past* graphics char
		es:bp - ptr to first char in string
RETURN:		al - special char
DESTROYED:	dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertGraphicToSpecialChar	proc	near	uses	bp, es, di, cx
	.enter
	mov	ax, di
	sub	ax, bp
DBCS <	shr	ax, 1			;byte offset -> char offset	>
DBCS <	EC <ERROR_C	ODD_SIZE_FOR_DBCS_TEXT				>>
	dec	ax			;AX <- position in text
	mov	dx, size VisTextGetGraphicAtPositionParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].VTGGAPP_position.low, ax
	clr	ss:[bp].VTGGAPP_position.high
	sub	sp, size VisTextGraphic
	movdw	ss:[bp].VTGGAPP_retPtr, sssp

	mov	ax, MSG_VIS_TEXT_GET_GRAPHIC_AT_POSITION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	mov	bp, sp
	mov	ax, ss:[bp].VTG_vmChain.low
	add	sp, size VisTextGetGraphicAtPositionParams + size VisTextGraphic
	mov	cx, length specialCharChunks
	segmov	es, cs
	mov	di, offset specialCharChunks
	repne	scasw
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		>
	sub	di, offset specialCharChunks+2
SBCS <	shr	di, 1							>
SBCS <	mov	al, cs:[specialChars][di]				>
DBCS <	mov	ax, cs:[specialChars][di]				>
	.leave
	ret
ConvertGraphicToSpecialChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextStringWithSpecialChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the text string from the passed object, and maps all
		graphic chars to the appropriate special char

CALLED BY:	GLOBAL
PASS:		ss:dx - ptr to store string
		^lbx:si - text object to get string from
RETURN:		cx - # chars in string (including null)
		buffer filled with data
DESTROYED:	ax, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextStringWithSpecialChars	proc	near	uses	bp, es
	.enter
	mov	bp, dx
	mov	dx, ss		;DX:BP <- ptr to dest for text
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	jcxz	exit
	push	cx		;Save # chars in string
	segmov	es, ss
	mov	di, bp		;ES:DI <- ptr to string
loopTop:
SBCS <	mov	al, C_GRAPHIC						>
SBCS <	repne	scasb							>
DBCS <	mov	ax, C_GRAPHIC						>
DBCS <	repne	scasw							>
	jne	endLoop
	call	ConvertGraphicToSpecialChar
SBCS <	mov	es:[di][-1], al						>
DBCS <	mov	es:[di][-2], ax						>
	tst	cx
	jnz	loopTop
endLoop:
	pop	cx		;Restore # chars in string
exit:
	inc	cx		
	.leave
	ret
GetTextStringWithSpecialChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlPassToOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passes the passed search/replace methods off to the output.

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
	atw	3/22/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
replaceAllWithNullKeyString	char	"QueryGlobalDelete",0
textCategoryString		char	"text",0
SearchReplaceControlPassToOutput	method	SearchReplaceControlClass,
				MSG_SRC_FIND_NEXT,
				MSG_SRC_FIND_PREV,
				MSG_REPLACE_CURRENT,
				MSG_REPLACE_ALL_OCCURRENCES,
				MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION,
				MSG_SRC_REPLACE_ALL_OCCURRENCES_NO_QUERY,
				MSG_SRC_FIND_FROM_TOP

SBCS <	searchString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (char)>
SBCS <	replaceString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (char)>
DBCS <	searchString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (wchar)>
DBCS <	replaceString	local	SEARCH_REPLACE_MAX_WORD_LENGTH	dup (wchar)>
	searchLength	local	word
	replaceLength	local	word
;
;	The 4 local vars above are inherited
;
	methodNumber	local	word
	.enter
	mov	methodNumber, ax
	push	si


;	Create block with data in this format:
;
;			SearchReplaceStruct<>			
;			data	Null-Terminated Search String
;			data	Null-Terminated Replace string
;


;	GET REPLACEMENT TEXT

	call	SR_GetFeaturesAndChildBlock
SBCS<	mov	{char} searchString, 0					>
DBCS<	mov	{wchar} searchString, 0					>
SBCS<	mov	{char} replaceString, 0					>
DBCS<	mov	{wchar} replaceString, 0				>
	clr	cx
	cmp	methodNumber, MSG_SRC_FIND_NEXT
	je	skipReplace
	cmp	methodNumber, MSG_SRC_FIND_PREV
	je	skipReplace
	cmp	methodNumber, MSG_SRC_FIND_FROM_TOP
	je	skipReplace

	mov	si, offset ReplaceText
	lea	dx, replaceString	;SS:DX <- ptr to dest for text
	call	GetTextStringWithSpecialChars

skipReplace:
	mov	replaceLength, cx
EC <	cmp	cx, SEARCH_REPLACE_TEXT_MAXIMUM				>
EC <	ERROR_A	REPLACE_STRING_TOO_LARGE				>

;	GET SEARCH TEXT

	mov	si, offset SearchText
	lea	dx, searchString		;SS:DX <- ptr to dest for text
	call	GetTextStringWithSpecialChars

EC <	cmp	cx,1							>
EC <	ERROR_Z	NO_SEARCH_STRING					>

	mov	searchLength, cx
EC <	cmp	cx, SEARCH_REPLACE_TEXT_MAXIMUM				>
EC <	ERROR_A	SEARCH_STRING_TOO_LARGE					>

	cmp	replaceLength,1
	jnz	haveReplaceString
	cmp	methodNumber, MSG_REPLACE_ALL_OCCURRENCES
	jnz	haveReplaceString

;	IF THE .INI FILE FLAG IS NOT SET, QUERY THE USER BEFORE DOING A GLOBAL
;	REPLACE WITH AN EMPTY STRING

	push	ds, cx, dx
	segmov	ds, cs, cx
	mov	si, offset textCategoryString
	mov	dx, offset replaceAllWithNullKeyString
	call	InitFileReadBoolean
	pop	ds, cx, dx
	jc	doQuery
	tst	ax
	jz	haveReplaceString
doQuery:
	pop	si
	call	QueryUserForGlobalDelete
	jmp	exit
haveReplaceString:

	pop	si
	call	GetSearchReplaceOptions
	mov	ah, cl

	cmp	methodNumber, MSG_SRC_FIND_FROM_TOP
	jne	checkFindPrev
	ornf	ah, mask SO_START_FROM_TOP
checkFindPrev:

	cmp	methodNumber, MSG_SRC_FIND_PREV
	jne	10$
	ornf	ah, mask SO_BACKWARD_SEARCH
10$:
	ornf	ah, mask SO_IGNORE_SOFT_HYPHENS
	call	CreateSearchReplaceStruct

	call	MemLock
	mov	es, ax

	mov	ax, methodNumber	
	cmp	ax, MSG_SRC_REPLACE_ALL_OCCURRENCES_NO_QUERY
	jne	80$
	mov	ax, MSG_REPLACE_ALL_OCCURRENCES
	jmp	sendToOutput
80$:

	cmp	ax, MSG_SRC_FIND_FROM_TOP
	je	90$
	cmp	ax, MSG_SRC_FIND_NEXT
	je	90$
	cmp	ax, MSG_SRC_FIND_PREV
	jne	sendToOutput
90$:
	mov	ax,MSG_SEARCH 
sendToOutput:

;	Set the appropriate reply msg

	mov	cx, MSG_SRC_SEARCH_STRING_NOT_FOUND_FOR_REPLACE_ALL
	cmp	ax, MSG_REPLACE_ALL_OCCURRENCES
	je	unlock
	mov	cx, MSG_SRC_SEARCH_STRING_NOT_FOUND_FOR_REPLACE_ALL_IN_SELECTION
	cmp	ax, MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION
	je	unlock
	mov	cx, MSG_SRC_SEARCH_STRING_NOT_FOUND_FOR_SEARCH
unlock:
	mov	es:[SRS_replyMsg], cx
	call	MemUnlock

;	Before we activate the seach command, we need to set the
;	state of the ReplaceTrigger or else the output of the controller
;	could reply back with a result (thereby setting the ReplaceTrigger's
;	new state which we would then inadvertently overwrite). -Don 9/4/00

	push	ax, dx
	cmp	ax, MSG_SEARCH
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jne	setReplaceTrigger
	mov	di, ds:[si]
	add	di, ds:[di].SearchReplaceControl_offset
	test	ds:[di].SRCI_enableFlags, mask SREF_REPLACE
	je	setReplaceTrigger
	mov	ax, MSG_GEN_SET_ENABLED
setReplaceTrigger:
	mov	dl, VUM_NOW
	call	SendMessageToReplaceTrigger
	pop	ax, dx

;	OK - do something!

	mov	cx,TRUE				;Set "replace all from start"
	clrdw	bxdi				; flag
	call	GenControlOutputActionRegs
exit:
	.leave
	ret
SearchReplaceControlPassToOutput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToItemsInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Passes a method to all the objects in the passed table.

CALLED BY:	GLOBAL
PASS:		SI:DI <- far ptr to null-terminated list of chunk handles
		BX - handle of block containing objects
		AX - method to send
		CX,DX,BP - data
		DS - controller segment (to be fixed up)
RETURN:		nada
DESTROYED:	si, di
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMessageToItemsInList	proc	near	uses	es
	.enter
EC <	tst	bx							>
EC <	ERROR_Z	CONTROLLER_OBJECT_INTERNAL_ERROR			>
	mov	es, si
10$:
	mov	si, es:[di]			;*DS:SI <- next object in list
	tst	si				;If at end of list, exit
	jz	exit
	push	ax, cx, dx, bp, di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, cx, dx, bp, di
	inc	di
	inc	di
	jmp	10$
exit:
	.leave
	ret
SendMessageToItemsInList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlSearchStringNotFound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method puts up a standard box telling the user that the
		search string has *not* been found.

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
	atw	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlSearchStringNotFound	method	SearchReplaceControlClass,
		MSG_SRC_SEARCH_STRING_NOT_FOUND_FOR_SEARCH,
		MSG_SRC_SEARCH_STRING_NOT_FOUND_FOR_REPLACE_ALL,
		MSG_SRC_SEARCH_STRING_NOT_FOUND_FOR_REPLACE_ALL_IN_SELECTION


	mov	bx, offset SearchStringNotFoundString
	cmp	ax, MSG_SRC_SEARCH_STRING_NOT_FOUND_FOR_REPLACE_ALL_IN_SELECTION
	jne	10$
	mov	bx, offset ReplaceAllInSelectionStringNotFoundString
10$:
	mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE or GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	call	SearchPutupBox
	mov	ax, MSG_SRC_SEARCH_ABORTED
	GOTO	ObjCallInstanceNoLock
SearchReplaceControlSearchStringNotFound	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchPutupBox
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
SearchPutupBox	proc	near	uses dx, bp, si
	.enter
	mov	dx, size GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, ax
	mov	si, bx
	mov	bx, handle TextStrings
	call	MemLock
	push	ds
assume	ds:TextStrings
	mov	ds, ax
	mov	si, ds:[si]		;DS:SI <- ptr to string to display
assume	ds:dgroup
	pop	ds
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, si
	clr	ss:[bp].GADDP_finishOD.handle
	clr	ss:[bp].GADDP_finishOD.offset
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication
	add	sp, size GenAppDoDialogParams
	mov	bx, handle TextStrings
	call	MemUnlock
	.leave
	ret
SearchPutupBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the UI.

CALLED BY:	GLOBAL
PASS:		ss:bp - GenControlUpdateUIParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlUpdateUI	method	SearchReplaceControlClass, 
					MSG_GEN_CONTROL_UPDATE_UI
	.enter
EC <	cmp	ss:[bp].GCUUIP_changeType, GWNT_SEARCH_REPLACE_ENABLE_CHANGE >
EC <	ERROR_NZ	CONTROLLER_OBJECT_INTERNAL_ERROR		   >

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax

	mov	cl, es:[NSREC_flags]
	call	MemUnlock
	mov	ds:[di].SRCI_enableFlags, cl
	mov	bx, ss:[bp].GCUUIP_childBlock

;	If none of the search/replace features are allowed, just exit.

	test	ss:[bp].GCUUIP_features, mask SRCF_FIND_NEXT or mask SRCF_FIND_PREV or mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	exit

;	Enable or disable the search gadgetry depending upon whether or not
;	search/replace is enabled on the current object.
;
;	The search text needs to be enabled if *either* search or replace is
;	allowed.
;

	push	si
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	cl, mask SREF_SEARCH or mask SREF_REPLACE
	jz	10$
	mov	ax, MSG_GEN_SET_ENABLED
10$:
	mov	dl, VUM_NOW
	mov	si, offset SearchText
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage


	test	ss:[bp].GCUUIP_features, mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	noReplaceFeatures

;	Enable or disable the replace text object depending upon whether or not
;	there are replace options available.
	
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	cl, mask SREF_REPLACE
	jz	20$
	mov	ax, MSG_GEN_SET_ENABLED
20$:
	mov	dl, VUM_NOW
	mov	si, offset ReplaceText
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

noReplaceFeatures:

;	ENABLE/DISABLE THE GADGETS USED BY BOTH SEARCH AND REPLACE

	test	ss:[bp].GCUUIP_features, mask SRCF_PARTIAL_WORDS or mask SRCF_IGNORE_CASE 
	jz	updateNoteOptions

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	cl, mask SREF_REPLACE or mask SREF_SEARCH
	jz	30$
	mov	ax, MSG_GEN_SET_ENABLED
30$:
	mov	dl, VUM_NOW
	mov	si, offset SearchReplaceOptions
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

updateNoteOptions:
	test	ss:[bp].GCUUIP_features, mask SRCF_NOTES_OPTIONS
	jz	updateTriggers
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	mov	si, offset SearchNoteOptions
	clr	di
	call	ObjMessage

updateTriggers:
	pop	si
	call	UpdateSearchReplaceTriggers
exit:
	.leave
	ret

SearchReplaceControlUpdateUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetObjMonikerFromVardata
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the moniker for the passed object to the vismoniker set
		in the lmem chunk.

CALLED BY:	GLOBAL
PASS:		^lbp:dx - object to set moniker for
		ax - vardata type
RETURN:		nada
DESTROYED:	ax, bx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetObjMonikerFromVardata	proc	near
	.enter
	call	ObjVarFindData
	jnc	exit
	mov	ax, ds:[bx]	;*DS:AX - VisMoniker to set for object
	push	cx, bp, si
	movdw	bxsi, bpdx	;^lBX:SI <- optr of object to set moniker

;	Set the moniker of the passed object

	mov	cx, ds:[LMBH_handle]
	mov	dx, ax
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, bp, si
exit:
	.leave
	ret
SetObjMonikerFromVardata	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This subclass changes the vis monikers of various triggers
		if the app specifies them.

CALLED BY:	GLOBAL
PASS:		*ds:si - SearchReplaceControl object
		es - segment of SearchReplaceControl class
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlGenerateUI	method	SearchReplaceControlClass,
				MSG_GEN_CONTROL_GENERATE_UI
	.enter

	mov	di, offset SearchReplaceControlClass
	call	ObjCallSuperNoLock

ifdef GPC_SEARCH
;	If dialog, add HINT_CENTER_CHILDREN_ON_MONIKERS
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jne	notDialog
	mov	ax, HINT_CENTER_CHILDREN_ON_MONIKERS
	clr	cx
	call	ObjVarAddData
	mov	ax, HINT_LEFT_JUSTIFY_MONIKERS
	clr	cx
	call	ObjVarAddData
	;
	; if all vertical elements are enabled,
	; display search window at bottom of screen to make room to show
	; misspelled word in document
	;
	call	SR_GetFeaturesAndChildBlock
	call	SR_CheckFullHeight
	jnc	notDialog
	mov	ax, HINT_POSITION_WINDOW_AT_RATIO_OF_PARENT
	mov	cx, size SpecWinSizePair
	call	ObjVarAddData
	mov	ds:[bx].SWSP_x, 0
	mov	ds:[bx].SWSP_y, mask SWSS_RATIO or PCT_90	; auto bump up
	mov	ax, MSG_SPEC_SCAN_GEOMETRY_HINTS
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
	call	ObjCallInstanceNoLock
notDialog:
endif

ifdef GPC_SEARCH
;	Mirror SCRF_SPECIAL_CHARS for Replace
	call	SR_GetFeaturesAndChildBlock
	test	ax, SEARCH_BOTTOM_FEATURES
	jz	leaveReplace
	test	ax, mask SRCF_SPECIAL_CHARS
	jnz	leaveReplace
	mov	ax, MSG_GEN_SET_NOT_USABLE
	push	si
	mov	si, offset ReplaceSpecialCharsMenu
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
leaveReplace:
endif

;	If all of the special features bits are off, remove the
;	SearchReplaceSpecialCharsMenu

	call	SR_GetFeaturesAndChildBlock
	mov	bp, bx
	mov_tr	cx, ax
ifdef GPC_SEARCH
	test	cx, SEARCH_TOP_FEATURES
	jz	menuExists
	test	cx, mask SRCF_SPECIAL_CHARS or mask SRCF_WILDCARDS
	jnz	menuExists
else
	test	cx, mask SRCF_SPECIAL_CHARS or mask SRCF_WILDCARDS
	jnz	menuExists

	test	cx, mask SRCF_IGNORE_CASE or mask SRCF_PARTIAL_WORDS
	jz	menuExists	;Branch if the menu has already been deleted
endif

	push	si
	mov	ax, MSG_GEN_SET_NOT_USABLE
ifdef GPC_SEARCH
	mov	si, offset SearchSpecialCharsMenu
else
	mov	si, offset SearchReplaceSpecialCharsMenu
endif
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

menuExists:
	test	cx, mask SRCF_FIND_NEXT
	jz	checkFindPrev
	mov	ax, ATTR_SEARCH_CONTROL_SET_FIND_NEXT_MONIKER
	mov	dx, offset FindNextTrigger
	call	SetObjMonikerFromVardata
checkFindPrev:
	test	cx, mask SRCF_FIND_PREV
	jz	checkFindFromTop
	mov	ax, ATTR_SEARCH_CONTROL_SET_FIND_PREV_MONIKER
	mov	dx, offset FindPrevTrigger
	call	SetObjMonikerFromVardata
checkFindFromTop:
	test	cx, mask SRCF_FIND_FROM_TOP
	jz	checkReplaceCurrent
	mov	ax, ATTR_SEARCH_CONTROL_SET_FIND_FROM_TOP_MONIKER
	mov	dx, offset FindFromTopTrigger
	call	SetObjMonikerFromVardata

checkReplaceCurrent:
	test	cx, mask SRCF_REPLACE_CURRENT
	jz	checkReplaceAllInSelection
	mov	ax, ATTR_SEARCH_CONTROL_SET_REPLACE_CURRENT_MONIKER
	mov	dx, offset ReplaceTrigger
	call	SetObjMonikerFromVardata

checkReplaceAllInSelection:
	test	cx, mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	checkReplaceAll
	mov	ax, ATTR_SEARCH_CONTROL_SET_REPLACE_ALL_IN_SELECTION_MONIKER
	mov	dx, offset ReplaceAllInSelectionTrigger
	call	SetObjMonikerFromVardata

checkReplaceAll:
	test	cx, mask SRCF_REPLACE_ALL
	jz	checkNoteOptions
	mov	ax, ATTR_SEARCH_CONTROL_SET_REPLACE_ALL_MONIKER
	mov	dx, offset ReplaceAllTrigger
	call	SetObjMonikerFromVardata

checkNoteOptions:
	test	cx, mask SRCF_NOTES_OPTIONS
	jz	checkReplaceWith
	mov	ax, ATTR_SEARCH_CONTROL_SET_INCLUDE_NOTE_MONIKER
	mov	dx, offset IncludeNote
	call	SetObjMonikerFromVardata
	mov	ax, ATTR_SEARCH_CONTROL_SET_EXCLUDE_NOTE_MONIKER
	mov	dx, offset ExcludeNote
	call	SetObjMonikerFromVardata
	mov	ax, ATTR_SEARCH_CONTROL_SET_NOTE_ONLY_MONIKER
	mov	dx, offset NoteOnly
	call	SetObjMonikerFromVardata

checkReplaceWith:
	test	cx, mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or \
			mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	exit
	mov	ax, ATTR_SEARCH_CONTROL_SET_REPLACE_WITH_MONIKER
	mov	dx, offset ReplaceText
	call	SetObjMonikerFromVardata
exit:
	.leave
	ret

SearchReplaceControlGenerateUI	endp

ifdef GPC_SEARCH
SR_CheckFullHeight	proc	far
	test	ax, mask SRCF_FIND_NEXT
	jz	haveFullHeight			; not full height, C clr
	test	ax, mask SRCF_FIND_PREV
	jz	haveFullHeight			; not full height, C clr
	test	ax, mask SRCF_IGNORE_CASE or mask SRCF_PARTIAL_WORDS
	jz	haveFullHeight			; not full height, C clr
	test	ax, mask SRCF_REPLACE_CURRENT
	jz	haveFullHeight			; not full height, C clr
	test	ax, mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	haveFullHeight			; not full height, C clr
	stc					; else full height
haveFullHeight:
	ret
SR_CheckFullHeight	endp
endif

ifdef GPC_SEARCH
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set trigger sizes

CALLED BY:	GLOBAL
PASS:		*ds:si - SearchReplaceControl object
		es - segment of SearchReplaceControl class
		cx - block handle
		dx - features
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/4/98		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlTweakDuplicatedUI	method	SearchReplaceControlClass,
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	.enter
	;
	; get widest trigger
	;
	mov	bx, cx			; bx = block handle
	mov	cx, 0
	mov	si, offset FindNextTrigger
	mov	ax, mask SRCF_FIND_NEXT
	call	updateMonikerWidth	; cx = widest trigger
	mov	si, offset FindPrevTrigger
	mov	ax, mask SRCF_FIND_PREV
	call	updateMonikerWidth	; cx = widest trigger
	mov	si, offset ReplaceTrigger
	mov	ax, mask SRCF_REPLACE_CURRENT
	call	updateMonikerWidth	; cx = widest trigger
	mov	si, offset ReplaceAllTrigger
	mov	ax, mask SRCF_REPLACE_ALL
	call	updateMonikerWidth	; cx = widest trigger
	mov	si, offset ReplaceAllInSelectionTrigger
	mov	ax, mask SRCF_REPLACE_ALL_IN_SELECTION
	call	updateMonikerWidth	; cx = widest trigger
	mov	ax, mask SRCF_FIND_FROM_TOP
	mov	si, offset FindFromTopTrigger
	call	updateMonikerWidth	; cx = widest trigger
	;
	; set all triggers to that width
	;
	mov	si, cs
	mov	di, offset triggerList
	mov	ax, MSG_GEN_SET_FIXED_SIZE
	sub	sp, size SetSizeArgs
	mov	bp, sp
	mov	ss:[bp].SSA_width, cx
	mov	ss:[bp].SSA_height, 0
	mov	ss:[bp].SSA_count, 0
	mov	ss:[bp].SSA_updateMode, VUM_MANUAL
	mov	dx, size SetSizeArgs
	call	SendMessageToItemsInList
	add	sp, size SetSizeArgs
	.leave
	ret

updateMonikerWidth	label	near
	test	dx, ax
	jz	updateExit		; trigger not used
	push	dx, di
	push	cx			; save widest so far
	mov	ax, MSG_GEN_GET_MONIKER_SIZE
	clr	dx, bp
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; cx = width
	pop	di
	cmp	cx, di
	jae	updateDone		; new width larger, return it
	mov	cx, di			; return previous widest
updateDone:
	pop	dx, di
updateExit:
	retn
SearchReplaceControlTweakDuplicatedUI	endm

triggerList	lptr	FindNextTrigger
		lptr	FindPrevTrigger
		lptr	ReplaceTrigger
		lptr	ReplaceAllTrigger
		lptr	ReplaceAllInSelectionTrigger
		lptr	FindFromTopTrigger
		lptr	0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlAddSpecialCharToFocusText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the passed special char to the focus text object.

CALLED BY:	GLOBAL
PASS:		cx - SpecialChar
		GPC <dx - 0 for SearchText, 1 for ReplaceText>
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlAddSpecialCharToFocusText	method SearchReplaceControlClass,
				MSG_SRC_ADD_SPECIAL_CHAR_TO_FOCUS_TEXT
	.enter

SPECIAL_CHAR_WIDTH	equ	15
SPECIAL_CHAR_HEIGHT	equ	10

	call	SR_GetFeaturesAndChildBlock

;	Get the OD of the current focus text object 

	mov	si, offset SearchText
ifdef GPC_SEARCH
	tst	dx
	jz	10$
else
	cmp	ds:[di].SRCI_focusInfo, SRFI_SEARCH_TEXT
	jz	10$
endif
	mov	si, offset ReplaceText
ifndef GPC_SEARCH  ; don't check in case message send by app instead of UI gadget
EC <	cmp	ds:[di].SRCI_focusInfo, SRFI_REPLACE_TEXT		>
EC <	ERROR_NZ	BAD_FOCUS_INFO					>
endif
10$:

;	Replace the current selection with a graphic

	mov	dx, size ReplaceWithGraphicParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].RWGP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	mov	di, cx
	mov	ax, cs:[specialCharChunks][di]
	mov	ss:[bp].RWGP_graphic.VTG_vmChain.low, ax
	mov	ss:[bp].RWGP_graphic.VTG_size.XYS_width, SPECIAL_CHAR_WIDTH
	mov	ss:[bp].RWGP_graphic.VTG_size.XYS_height, SPECIAL_CHAR_HEIGHT
	mov	ss:[bp].RWGP_graphic.VTG_type, VTGT_GSTRING
	mov	ss:[bp].RWGP_graphic.VTG_flags, mask VTGF_DRAW_FROM_BASELINE
	clr	ax
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_drawOffset.XYO_y, ax
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_drawOffset.XYO_x, ax

	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e11.WWF_int, 1
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e11.WWF_frac, ax

	clrwwf	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e12, ax
	clrwwf	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e21, ax
	
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e22.WWF_int, 1
	mov	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e22.WWF_frac, ax

	clrdwf	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e31, ax
	clrdwf	ss:[bp].RWGP_graphic.VTG_data.VTGD_gstring.VTGG_tmatrix.TM_e32, ax

	mov	ss:[bp].RWGP_graphic.VTG_vmChain.high, ax
	mov	ss:[bp].RWGP_pasteFrame, ax
	mov	ss:[bp].RWGP_sourceFile, ax
	mov	ax, MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, dx
	.leave
	ret
SearchReplaceControlAddSpecialCharToFocusText	endp

specialCharChunks	lptr	WildcardGString, WildcharGString, \
				GraphicGString, CRGString, PageBreakGString, \
				TabGString

specialChars		Chars	WC_MATCH_MULTIPLE_CHARS, WC_MATCH_SINGLE_CHAR,\
				C_GRAPHIC, C_CR, C_PAGE_BREAK, C_TAB


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSendSearchNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the appropriate search/spell notifications out.

CALLED BY:	GLOBAL
PASS:		CL - SearchReplaceEnableFlags
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global TextSendSearchNotification:far
TextSendSearchNotification	proc	far	uses	ax, bx, cx, dx, bp, di
	.enter

	clr	bx
	tst	cl
	jz	5$

	push	es
	mov	dl, cl
	mov	ax, size NotifySearchReplaceEnableChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	mov     es:[NSREC_flags], dl
	call	MemUnlock
	pop	es
5$:

;	Record a notification event

	mov	bp, bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_SEARCH_REPLACE_ENABLE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			;DI <- event handle

;	Send it to the appropriate gcn list

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_APP_TARGET_NOTIFY_SEARCH_REPLACE_CHANGE
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	tst	bx
	jnz	10$
	ornf	ss:[bp].GCNLMP_flags, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_STACK
	call	ObjMessage
	add	sp, dx
	.leave
	ret
TextSendSearchNotification	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlSendEventToSearchText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an event to the search text object

CALLED BY:	GLOBAL
PASS:		*ds:si - SearchReplaceControl obj
		bp - event handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlSendEventToSearchText method SearchReplaceControlClass, 
				MSG_SRC_SEND_EVENT_TO_SEARCH_TEXT
	.enter
	call	SR_GetFeaturesAndChildBlock
	mov	cx, bx
	mov	bx, bp
	test	ax, mask SRCF_FIND_NEXT or mask SRCF_FIND_PREV or mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	freeMsg
	mov	si, offset SearchText
	call	MessageSetDestination
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	MessageDispatch
exit:
	.leave
	ret
freeMsg:
	call	ObjFreeMessage
	jmp	exit
SearchReplaceControlSendEventToSearchText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlSendEventToReplaceText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an event to the replace text obj

CALLED BY:	GLOBAL
PASS:		*ds:si - SearchReplaceControl obj
		bp - event handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlSendEventToReplaceText method SearchReplaceControlClass, 
				MSG_SRC_SEND_EVENT_TO_REPLACE_TEXT
	.enter
	call	SR_GetFeaturesAndChildBlock
	mov	cx, bx
	mov	bx, bp
	test	ax, mask SRCF_REPLACE_CURRENT or mask SRCF_REPLACE_ALL or mask SRCF_REPLACE_ALL_IN_SELECTION
	jz	freeMsg
	mov	si, offset ReplaceText
	call	MessageSetDestination
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	MessageDispatch
exit:
	.leave
	ret
freeMsg:
	call	ObjFreeMessage
	jmp	exit
SearchReplaceControlSendEventToReplaceText	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchReplaceControlGetNoteSearchState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the note options (include/exclude notes, note only) chosen
		by the user.

CALLED BY:	MSG_SRC_GET_NOTE_SEARCH_STATE
PASS:		*ds:si	= SearchReplaceControlClass object
		ds:di	= SearchReplaceControlClass instance data
		es 	= segment of SearchReplaceControlClass
		ax	= message #
RETURN:		cl	= SearchNoteOptionType
DESTROYED:	ax, ch
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchReplaceControlGetNoteSearchState	method dynamic SearchReplaceControlClass, 
					MSG_SRC_GET_NOTE_SEARCH_STATE
		uses	dx, bp
		.enter
	;
	; Find out what selection is chosen.
	;
		call	SR_GetFeaturesAndChildBlock	;ax = features
							;^hbx = child block
	;
	; If we don't have note options, then we return the default
	; note option.
	;
		test	ax, mask SRCF_NOTES_OPTIONS
		mov	cl, SNOT_EXCLUDE_NOTE
		jz	exit
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset SearchNoteOptions	;^lbx:si = item group
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			;cx,dx,bp trashed
							;ax = selection
		Assert	etype al, SearchNoteOptionType
		mov_tr	cx, ax				;cx = selection
exit:		
		.leave
		ret
SearchReplaceControlGetNoteSearchState		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OverrideCenterOnMonikersGetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to override HINT_CENTER_ON_MONIKERS

CALLED BY:	MSG_VIS_COMP_GET_MARGINS
PASS:		*ds:si	= OverrideCenterOnMonikersClass object
		ds:di	= OverrideCenterOnMonikersClass instance data
		es 	= segment of OverrideCenterOnMonikersClass
RETURN:		ax = left margin
		see MSG_VIS_COMP_GET_MARGINS
DESTROYED:	ax, ch
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/4/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef GPC_SEARCH
OverrideCenterOnMonikersGetMargins	method dynamic OverrideCenterOnMonikersClass, MSG_VIS_COMP_GET_MARGINS
;
; hack to override HINT_CENTER_ON_MONIKERS
;
	mov	di, offset OverrideCenterOnMonikersClass
	call	ObjCallSuperNoLock
	mov	ax, 0
	ret
OverrideCenterOnMonikersGetMargins	endp
endif

TextSRControlCode ends

endif		; not NO_CONTROLLERS

