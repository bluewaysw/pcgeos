COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Pen library
MODULE:		Ink
FILE:		inkControlClass.asm

AUTHOR:		Andrew Wilson, Mar 31, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/31/92		Initial revision

DESCRIPTION:
	Contains tables/routines for the ink controller.
	
	$Id: inkControlClass.asm,v 1.1 97/04/05 01:27:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PenClassStructures	segment	resource

	InkControlClass

PenClassStructures	ends

InkCommon	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	InkControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for InkControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of InkControlClass

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
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
InkControlGetInfo	method dynamic	InkControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	si, offset IC_dupInfo
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
InkControlGetInfo	endm

IC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	IC_IniFileKey,			; GCBI_initFileKey
	IC_gcnList,			; GCBI_gcnList
	length IC_gcnList,		; GCBI_gcnCount
	IC_notifyTypeList,		; GCBI_notificationList
	length IC_notifyTypeList,	; GCBI_notificationCount
	ICName,				; GCBI_controllerName

	handle InkControlUI,		; GCBI_dupBlock
	IC_childList,			; GCBI_childList
	length IC_childList,		; GCBI_childCount
	IC_featuresList,		; GCBI_featuresList
	length IC_featuresList,		; GCBI_featuresCount
	IC_DEFAULT_FEATURES,		; GCBI_features

	handle InkControlToolboxUI,	; GCBI_toolBlock
	IC_toolList,			; GCBI_toolList
	length IC_toolList,		; GCBI_toolCount
	IC_toolFeaturesList,		; GCBI_toolFeaturesList
	length IC_toolFeaturesList,	; GCBI_toolFeaturesCount
	IC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
PenControlInfoXIP	segment	resource
endif

IC_IniFileKey	char	"ink", 0

IC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_INK_STATE_CHANGE>

IC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_INK_HAS_TARGET>


;---

IC_childList	GenControlChildInfo	\
	<offset InkToolList, mask ICF_PENCIL_TOOL or mask ICF_ERASER_TOOL or mask ICF_SELECTION_TOOL,0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

IC_featuresList	GenControlFeaturesInfo	\
	<offset SelectEntry, SelectName, 0>,
	<offset EraserEntry, EraserName, 0>,
	<offset PencilEntry, PencilName, 0>

;---

IC_toolList	GenControlChildInfo	\
	<offset InkTBToolList, mask ICTF_PENCIL_TOOL or mask ICTF_ERASER_TOOL or mask ICTF_SELECTION_TOOL,
				0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

IC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset SelectTool, EraserName, 0>,
	<offset EraserTool, EraserName, 0>,
	<offset PencilTool, PencilName, 0>

if FULL_EXECUTE_IN_PLACE
PenControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selected tool, based on the passed info...

CALLED BY:	GLOBAL
PASS:		*ds:si - InkControl object
		ss:bp - GenControlUpdateUIParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkControlUpdateUI	method	InkControlClass, MSG_GEN_CONTROL_UPDATE_UI
	.enter
	mov	cx, ss:[bp].GCUUIP_dataBlock

;	CX is either -1 (which was passed by old ink objects) or 0x8000 or-ed
;	with the current InkTool.

	cmp	cx, -1			;If old style ink object, don't set 
	je	exit			; the tool.
	andnf	cx, 0x7fff
	call	SetSelectedTool
exit:
	.leave
	ret
InkControlUpdateUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkControlSetToolFromList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out a GCN notification to set all ink objects to have
		the passed tool.

CALLED BY:	GLOBAL
PASS:		*ds:si - InkControl object
		cx - InkTool
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkControlSetToolFromList	method	InkControlClass,
				MSG_IC_SET_TOOL_FROM_LIST

;	Record an event to send to all controlled ink objects

	mov	ax, MSG_INK_SET_TOOL
	mov	di, mask MF_RECORD
	call	ObjMessage			;DI <- event handle

	push	si
	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_CONTROLLED_INK_OBJECTS
	mov	dx, size GCNListMessageParams
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx
	pop	si

	call	SetSelectedTool

	ret
InkControlSetToolFromList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSelectedTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the selection in both of the GCN lists

CALLED BY:	GLOBAL
PASS:		cx - InkTool
		*DS:SI - InkControl object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSelectedTool	proc	near
	.enter

;	Save the new selected tool in vardata

	push	cx
	mov	ax, TEMP_INK_CONTROL_SELECTED_TOOL
	mov	cx, size InkTool
	call	ObjVarAddData
	pop	cx
	mov	ds:[bx], cx		

;	Set the selection of both the toolbox and normal UI.

	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarFindData
	jnc	exit			;Exit if no UI built yet...

;	If no features, or the block of toolbox UI isn't built yet, then 
;	don't bother setting the selection, as InkTBToolList doesn't exist
;	yet.

	tst	ds:[bx].TGCI_toolboxFeatures
	jz	noTools
	
	tst	ds:[bx].TGCI_toolBlock
	jz	noTools

	push	bx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	bx, ds:[bx].TGCI_toolBlock
	mov	si, offset InkTBToolList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx
	
noTools:

;	If no features, or if the block of normal UI isn't built yet, then
;	don't bother setting the selection, as InkToolList doesn't exist yet.

	tst	ds:[bx].TGCI_features
	jz	exit
	tst	ds:[bx].TGCI_childBlock
	jz	exit


	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	bx, ds:[bx].TGCI_childBlock
	mov	si, offset InkToolList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

exit:
	.leave
	ret
SetSelectedTool	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the selection of the duplicated UI.

CALLED BY:	GLOBAL
PASS:		cx - duplicated block handle
		dx - features mask
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkControlTweakDuplicatedUI	method	InkControlClass, 
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI, 
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI
	.enter

	tst	dx
	jz	exit

;	Get the offset of the object in which we want to set the selection,
;	based on the method passed in...

	mov	bp, offset InkTBToolList	
	cmp	ax, MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI
	je	10$
	mov	bp, offset InkToolList
10$:

;	If the selected tool has been changed from the default, then modify
;	the selection

	mov	ax, TEMP_INK_CONTROL_SELECTED_TOOL
	call	ObjVarFindData
	jnc	exit

	mov	ax, ds:[bx]		;AX <- InkTool stored in vardata
	mov	bx, cx
	mov	si, offset InkToolList	;^lBX:SI <- list of tools
	mov_tr	cx, ax			;CX <- InkTool to select
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx			;Do not want indeterminate selection
	clr	di
	call	ObjMessage

exit:
	.leave
	ret
InkControlTweakDuplicatedUI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkControlScanFeatureHints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This nukes all features if the system is not pen based.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkControlScanFeatureHints	method	InkControlClass, 
				MSG_GEN_CONTROL_SCAN_FEATURE_HINTS
	.enter
	push	cx, dx, bp
	mov	di, offset InkControlClass
	call	ObjCallSuperNoLock
	pop	cx, es, di

	call	SysGetPenMode
	tst	ax			;Exit if pen based
	jnz	exit

;	We are not pen based, so nuke the features

	mov	es:[di].GCSI_appProhibited, mask InkControlToolboxFeatures
	cmp	cx, GCUIT_TOOLBOX
	jz	exit
	mov	es:[di].GCSI_appProhibited, mask InkControlFeatures
exit:
	.leave
	ret
InkControlScanFeatureHints	endp

InkCommon	ends
