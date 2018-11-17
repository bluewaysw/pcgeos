COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		genEdit.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenDisplayControlClass	Window menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement GenDisplayControlClass

	$Id: uiDispCtrl.asm,v 1.1 97/04/07 11:47:11 newdeal Exp $

------------------------------------------------------------------------------@

;---------------------------------------------------

UserClassStructures	segment resource

	GenDisplayControlClass		;declare the class record

UserClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

ControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenDisplayControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GenDisplayControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GenDisplayControlClass

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
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
GenDisplayControlGetInfo	method dynamic	GenDisplayControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GDC_dupInfo
	GOTO	CopyDupInfoCommon

GenDisplayControlGetInfo	endm

GDC_dupInfo	GenControlBuildInfo	<
	mask GCBF_CUSTOM_ENABLE_DISABLE or mask GCBF_ALWAYS_ON_GCN_LIST or \
				mask GCBF_ALWAYS_INTERACTABLE or \
				mask GCBF_ALWAYS_UPDATE or \
				mask GCBF_IS_ON_ACTIVE_LIST, ; GCBI_flags
	GDC_IniFileKey,			; GCBI_initFileKey
	GDC_gcnList,			; GCBI_gcnList
	length GDC_gcnList,		; GCBI_gcnCount
	GDC_notifyTypeList,		; GCBI_notificationList
	length GDC_notifyTypeList,	; GCBI_notificationCount
	GDCName,			; GCBI_controllerName

	handle GenDisplayControlUI,	; GCBI_dupBlock
	GDC_childList,			; GCBI_childList
	length GDC_childList,		; GCBI_childCount
	GDC_featuresList,		; GCBI_featuresList
	length GDC_featuresList,	; GCBI_featuresCount
	GDC_DEFAULT_FEATURES,		; GCBI_features

	handle GenDisplayControlToolboxUI,	; GCBI_toolBlock
	GDC_toolList,			; GCBI_toolList
	length GDC_toolList,		; GCBI_toolCount
	GDC_toolFeaturesList,		; GCBI_toolFeaturesList
	length GDC_toolFeaturesList,	; GCBI_toolFeaturesCount
	GDC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	segment	resource
endif

GDC_IniFileKey	char	"displayControl", 0

GDC_gcnList	GCNListType \
    <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_CHANGE>,
    <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_DISPLAY_LIST_CHANGE>

GDC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_DISPLAY_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_DISPLAY_LIST_CHANGE>

;---

GDC_childList	GenControlChildInfo	\
	<offset OverlappingList, mask GDCF_OVERLAPPING_MAXIMIZED,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TileTrigger, mask GDCF_TILE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DisplayListGroup, mask GDCF_DISPLAY_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GDC_featuresList	GenControlFeaturesInfo	\
	<offset DisplayListGroup, DisplayListName>,
	<offset TileTrigger, TileName>,
	<offset OverlappingList, OverlappingName>

;---

GDC_toolList	GenControlChildInfo	\
	<offset OverlappingToolList, mask GDCTF_OVERLAPPING_MAXIMIZED,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TileToolTrigger, mask GDCTF_TILE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset DisplayToolList, mask GDCTF_DISPLAY_LIST,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

GDC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset DisplayToolList, DisplayListName>,
	<offset TileToolTrigger, TileName>,
	<offset OverlappingToolList, OverlappingName>

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenDisplayControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GenDisplayControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GenDisplayControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
GenDisplayControlUpdateUI	method dynamic GenDisplayControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	mov	bx, ss:[bp].GCUUIP_dataBlock
	cmp	ss:[bp].GCUUIP_changeType, GWNT_DISPLAY_LIST_CHANGE
	LONG jz	displayListChange

	; get notification data

	push	bx

	push	bp
	push	si
	sub	sp, size ReplaceVisMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RVMF_dataType, VMDT_NULL	;assume no name
	tst	bx
	jz	nullName
	call	MemLock
	mov	es, ax

	; save the selected display number

	mov	ax, TEMP_GDC_CACHED_SELECTED_DISPLAY
	mov	cx, size word
	call	ObjVarAddData
	mov	ax, es:NDC_displayNum
	mov	ds:[bx], ax

	; update the primary's long term moniker (if needed)

	clr	cx
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GDCII_attrs, mask GDCA_MAXIMIZED_NAME_ON_PRIMARY
	jz	toAfterName

	tst	es:NDC_overlapping
	jnz	nullName
	cmp	es:NDC_name, 0
	jnz	notNullName
nullName:
	mov	ax, TEMP_GDC_CACHED_NAME
	call	ObjVarFindData
	LONG jnc gotName			;if not present then set it
	VarDataSizePtr	ds, bx, cx
	jcxz	toAfterName
	clr	cx
	call	ObjVarAddData
	jmp	gotName
toAfterName:
	jmp	afterName

notNullName:
	mov	ax, TEMP_GDC_CACHED_NAME
	call	ObjVarFindData
	jnc	noMatch
	VarDataSizePtr	ds, bx, cx
	jcxz	noMatch
	push	si
	mov	si, bx
	mov	di, offset NDC_name
	repe	cmpsb
	pop	si
	mov	cx, 0					;don't alter flags!
	jz	afterName
noMatch:

	mov	di, offset NDC_name			;get the string size
	call	LocalStringSize				;cx <- size w/o NULL
	LocalNextChar escx				;cx <- size w/NULL
	mov	ax, TEMP_GDC_CACHED_NAME
	call	ObjVarAddData
	push	si
	segxchg	ds, es
	mov	si, offset NDC_name			;ds:si = source
	mov	di, bx					;es:di = dest
	rep	movsb
	segxchg	ds, es
	pop	si

	mov	ss:[bp].RVMF_dataType, VMDT_TEXT
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	mov	ss:[bp].RVMF_source.segment, es
	mov	ss:[bp].RVMF_source.offset, offset NDC_name
	mov	ss:[bp].RVMF_length, 0
gotName:
	mov	dx, size ReplaceVisMonikerFrame
	mov	ax, MSG_GEN_PRIMARY_REPLACE_LONG_TERM_MONIKER
	mov	di, mask MF_RECORD or mask MF_STACK
	mov	bx, segment GenPrimaryClass
	mov	si, offset GenPrimaryClass
	call	ObjMessage
	mov	cx, di
afterName:
	add	sp, size ReplaceVisMonikerFrame
	pop	si

	jcxz	reallyAfterName
	mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
	call	GenCallParent
reallyAfterName:
	pop	bp

	; update overlapping list

	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask GDCF_OVERLAPPING_MAXIMIZED
	jz	noOverlapping
	;
	; if no data block, leave current state of overlapping list
	; - brianc 3/9/93
	;
	tst	ss:[bp].GCUUIP_dataBlock
	jz	noOverlapping
	clr	cx

	tst	es:NDC_overlapping
	jz	10$
	inc	cx
10$:

	clr	dx
	mov	si, offset OverlappingList
	call	setSingleSelection
noOverlapping:


	; update display list

	test	ax, mask GDCF_DISPLAY_LIST
	jz	noList
	mov	cx, es:NDC_displayNum
	clr	dx
	mov	si, offset DisplayList
	call	setSingleSelection
noList:

	; update overlapping tool list

	mov	ax, ss:[bp].GCUUIP_toolboxFeatures
	mov	bx, ss:[bp].GCUUIP_toolBlock
	test	ax, mask GDCTF_OVERLAPPING_MAXIMIZED
	jz	noOverlappingTool
	;
	; if no data block, leave current state of overlapping tool list
	; - brianc 3/10/93
	;
	tst	ss:[bp].GCUUIP_dataBlock
	jz	noOverlappingTool
	clr	cx
	tst	es:NDC_overlapping
	jz	20$
	inc	cx
20$:
	clr	dx
	mov	si, offset OverlappingToolList
	call	setSingleSelection
noOverlappingTool:

	; update display tool list

	test	ax, mask GDCTF_DISPLAY_LIST
	jz	noListTool
	mov	cx, es:NDC_displayNum
	clr	dx
	mov	si, offset DisplayToolList
	call	setSingleSelection
noListTool:

	pop	bx
	tst	bx
	jz	noUnlock
	call	MemUnlock
noUnlock:
	ret

	; if the display list has changed then redo all the lists

displayListChange:
	tst	bx
	jz	done
	call	MemLock
	mov	es, ax

	test	ss:[bp].GCUUIP_features, mask GDCF_DISPLAY_LIST
	jz	noList2
	mov	ax, TEMP_GDC_CACHED_LIST_DATA
	call	testUpdateList
	jnc	noList2
	mov	cx, ss:[bp].GCUUIP_childBlock
	mov	dx, offset DisplayList
	call	updateList

noList2:

	test	ss:[bp].GCUUIP_toolboxFeatures, mask GDCTF_DISPLAY_LIST
	jz	noToolList2
	mov	ax, TEMP_GDC_CACHED_TOOL_LIST_DATA
	call	testUpdateList
	jnc	noToolList2
	mov	cx, ss:[bp].GCUUIP_toolBlock
	mov	dx, offset DisplayToolList
	call	updateList
noToolList2:

	call	MemUnlock
done:
	ret

;---

	; return carry set to update

testUpdateList:
	push	bx
	call	ObjVarFindData
	jnc	addit
	mov	cx, ds:[bx].NDLC_counter
	cmp	cx, es:NDLC_counter
	jnz	addit
	cmpdw	ds:[bx].NDLC_group, es:NDLC_group, cx
	clc
	jz	testDone
addit:
	mov	cx, size NotifyDisplayListChange
	call	ObjVarAddData
	mov	cx, es:NDLC_counter
	mov	ds:[bx].NDLC_counter, cx
	movdw	ds:[bx].NDLC_group, es:NDLC_group, cx
	stc
testDone:
	pop	bx
	retn

;---

	; cxdx = list

updateList:
	push	bp
	push	bx
	mov	bp, -1
	mov	ax, TEMP_GDC_CACHED_SELECTED_DISPLAY
	call	ObjVarFindData
	jnc	30$
	mov	bp, ds:[bx]
30$:
	pop	bx
	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_NUM_ITEMS
	call	SendToTargetDGRegs
	pop	bp
	retn

;---

setSingleSelection:
	push	ax				; preserve feature flags
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	;
	; we can safely MF_FORCE_QUEUE here -- this fixes timing problems
	; introduced by using MF_FORCE_QUEUE and MF_INSERT_AT_FRONT in
	; the handler for MSG_GEN_DISPLAY_GROUP_SET_NUM_ITEMS, breaking the
	; requirement that the list items be initialized (via
	; MSG_GEN_DISPLAY_GROUP_SET_NUM_ITEMS) before the list selection is
	; set (here) - brianc 4/9/93
	;
;	mov	di, mask MF_FIXUP_DS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	ax				; restore feature flags
	retn

;---


GenDisplayControlUpdateUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenDisplayControlScanFeatureHints --
			MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
			for GenDisplayControlClass

DESCRIPTION:	Scan the hints for feature info, turn off display list
		if in transparent doc mode

PASS:
	*ds:si - instance data
	es - segment of GenDisplayControlClass

	ax - The message

	cx - GenControlUIType
	dx:bp - ptr to GenControlScanInfo structure to fill in

RETURN:
	dx:bp - structure filled out

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/2/92		Initial version

------------------------------------------------------------------------------@
GenDisplayControlScanFeatureHints	method dynamic	GenDisplayControlClass,
					MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
	uses	ax, cx, dx, bp
	.enter

	; let superclass handle regular scanning

	push	cx, dx, bp			; save GenControlScanInfo
	mov	di, offset GenDisplayControlClass
	call	ObjCallSuperNoLock
	pop	cx, es, di			; es:di = GenControlScanInfo

	; now turn off things if we're in transparent document mode

	clr	bx
	call	GeodeGetUIData			; bx = specific UI
	mov	ax, SPIR_GET_DOC_CONTROL_OPTIONS
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable		; ax = DocControlOptions
	test	ax, mask DCO_ALWAYS_ALLOW_OVERLAPPING_DISPLAYS
	jnz	forceOverlapping
	test	ax, mask DCO_TRANSPARENT_DOC
	jz	done				; not transparent doc, done

	mov	ax, HINT_DISPLAY_CONTROL_NO_FEATURES_IF_TRANSPARENT_DOC_CTRL_MODE
	call	ObjVarFindData			; carry set if found
	jnc	done				; no hint, leave alone
	cmp	cx, GCUIT_NORMAL
	mov	ax, mask GDICFeatures ; else turn everything off
	je	haveType
	mov	ax, mask GDICToolboxFeatures
haveType:
	ornf	es:[di].GCSI_appProhibited, ax

done:
	.leave
	ret

forceOverlapping:
	cmp	cx, GCUIT_NORMAL
	jnz	done
	and	es:[di].GCSI_userRemoved, not mask GDICFeatures
	jmp	done

GenDisplayControlScanFeatureHints	endm

ControlCommon ends

;---

ControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenDisplayControlDestroyUI -- MSG_GEN_CONTROL_DESTROY_UI
						for GenDisplayControlClass

DESCRIPTION:	Destroy our temporary data when destroying the UI

PASS:
	*ds:si - instance data
	es - segment of GenDisplayControlClass

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
	Tony	10/13/92		Initial version

------------------------------------------------------------------------------@
GenDisplayControlDestroyUI	method dynamic	GenDisplayControlClass,
					MSG_GEN_CONTROL_DESTROY_UI

	mov	bx, TEMP_GDC_CACHED_LIST_DATA
	FALL_THRU	GDCDestroyCommon

GenDisplayControlDestroyUI	endm

GDCDestroyCommon	proc	far
	xchg	ax, bx
	call	ObjVarDeleteData
	xchg	ax, bx

	mov	di, offset GenDisplayControlClass
	GOTO	ObjCallSuperNoLock
GDCDestroyCommon	endp

;---

GenDisplayControlDestroyToolboxUI	method dynamic	GenDisplayControlClass,
					MSG_GEN_CONTROL_DESTROY_TOOLBOX_UI

	mov	bx, TEMP_GDC_CACHED_TOOL_LIST_DATA
	GOTO	GDCDestroyCommon

GenDisplayControlDestroyToolboxUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenDisplayControlSetOverlapping -- MSG_GDC_SET_OVERLAPPING
						for GenDisplayControlClass

DESCRIPTION:	Set the scale factor

PASS:
	*ds:si - instance data
	es - segment of GenDisplayControlClass

	ax - The message

	cx - 1 for overlapping, 0 for full-size

if _NIKE
	cx - 0 for full-size, 1 for tile-vertically, 2 for tile-horizontally
endif

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
GenDisplayControlSetOverlapping	method dynamic	GenDisplayControlClass,
							MSG_GDC_SET_OVERLAPPING

	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_FULL_SIZED
	jcxz	10$


	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_OVERLAPPING


10$:
	GOTO	SendToTargetDGRegs

GenDisplayControlSetOverlapping	endm

;---

GenDisplayControlTile	method dynamic	GenDisplayControlClass, MSG_GDC_TILE
	mov	ax, MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
	FALL_THRU	SendToTargetDGRegs

GenDisplayControlTile	endm

;---

SendToTargetDGRegs	proc	far	uses bx, di
	.enter

	mov	bx, segment GenDisplayGroupClass
	mov	di, offset GenDisplayGroupClass
	call	GenControlOutputActionRegs

	.leave
	ret
SendToTargetDGRegs	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenDisplayControlListApply -- MSG_GDC_LIST_APPLY
						for GenDisplayControlClass

DESCRIPTION:	Apply a change in the selected display

PASS:
	*ds:si - instance data
	es - segment of GenDisplayControlClass

	ax - The message

	cx - number of selected display

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
GenDisplayControlListApply	method dynamic	GenDisplayControlClass,
						MSG_GDC_LIST_APPLY

	mov	ax, MSG_GEN_DISPLAY_GROUP_SELECT_DISPLAY
	call	SendToTargetDGRegs
	ret

GenDisplayControlListApply	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenDisplayControlListQuery -- MSG_GDC_LIST_QUERY
						for GenDisplayControlClass

DESCRIPTION:	Get moniker for the dynamic list

PASS:
	*ds:si - instance data
	es - segment of GenDisplayControlClass

	ax - The message

	cx:dx - list
	bp - index

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
GenDisplayControlListQuery	method dynamic	GenDisplayControlClass,
						MSG_GDC_LIST_QUERY

	mov	ax, MSG_GEN_DISPLAY_GROUP_SET_MONIKER
	call	SendToTargetDGRegs
	ret

GenDisplayControlListQuery	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDisplayControlSwapDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap GenDisplays

CALLED BY:	MSG_GDC_SWAP
PASS:		*ds:si	= GenDisplayControlClass object
		ds:di	= GenDisplayControlClass instance data
		ds:bx	= GenDisplayControlClass object (same as *ds:si)
		es 	= segment of GenDisplayControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenDisplayControlResizeDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize GenDisplays

CALLED BY:	MSG_GDC_RESIZE_DISPLAYS
PASS:		*ds:si	= GenDisplayControlClass object
		ds:di	= GenDisplayControlClass instance data
		ds:bx	= GenDisplayControlClass object (same as *ds:si)
		es 	= segment of GenDisplayControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ControlCode ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

