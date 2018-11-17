COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiBorder.asm
FILE:		uiBorder.asm

AUTHOR:		Gene Anderson, Jul 29, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/29/92		Initial revision

DESCRIPTION:
	

	$Id: uiBorder.asm,v 1.1 97/04/07 11:12:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;---------------------------------------------------

SpreadsheetClassStructures	segment	resource

	SSBorderControlClass		;declare the class record

SpreadsheetClassStructures	ends

;---------------------------------------------------

BorderControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSBorderControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderControlClass
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBCGetInfo	method dynamic SSBorderControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSBC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSBCGetInfo	endm

SSBC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSBC_IniFileKey,		; GCBI_initFileKey
	SSBC_gcnList,			; GCBI_gcnList
	length SSBC_gcnList,		; GCBI_gcnCount
	SSBC_notifyTypeList,		; GCBI_notificationList
	length SSBC_notifyTypeList,	; GCBI_notificationCount
	SSBCName,			; GCBI_controllerName

	handle SSBorderUI,		; GCBI_dupBlock
	SSBC_childList,			; GCBI_childList
	length SSBC_childList,		; GCBI_childCount
	SSBC_featuresList,		; GCBI_featuresList
	length SSBC_featuresList,	; GCBI_featuresCount
	SSBC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	SSBC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSBC_helpContext	char	"dbSSBorder", 0

SSBC_IniFileKey	char	"ssBorder", 0

SSBC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_ATTR_CHANGE>

SSBC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_CELL_ATTR_CHANGE>

;---

SSBC_childList	GenControlChildInfo	\
	<offset SidesList, mask SSBCF_SIDES, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSBC_featuresList	GenControlFeaturesInfo	\
	<offset SidesList, SSBCSidesName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSBorderControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderControlClass
		ax - the message

		ss:bp - GenControlUpdateUIParams
			GCUUIP_manufacturer
			GCUUIP_changeType
			GCUUIP_dataBlock
			GCUUIP_features
			GCUUIP_childBlock

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBCUpdateUI	method dynamic SSBorderControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	dl, ds:NSSCAC_borderInfo	;dl <- CellBorderInfo
	mov	dh, ds:NSSCAC_borderIndeterminates
	call	MemUnlock
	pop	ds
	mov	al, dh				;al <- border indeterminates
	not	al
	andnf	dl, al				;dl <- ignore indeterminates
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	;
	; Does the cell border feature exist?
	;
	test	ax, mask SSBCF_SIDES
	jz	noSides
	push	ax, cx, dx
	;
	; Always clear the "outline" list
	;
	andnf	ds:[di].SSBCI_status, not (mask CBI_OUTLINE)
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	mov	si, offset OutlineList		;^lbx:si <- OD of list
	call	SSBC_ObjMessageSend
	;
	; Set the appropriate sides in the list
	;
	mov	cl, dl				;cl <- booleans to set
	mov	dl, dh				;dl <- indeterminates
	clr	ch, dh
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	si, offset LTRBList		;^lbx:si <- OD of list
	call	SSBC_ObjMessageSend
	pop	ax, cx, dx
noSides:

	ret
SSBCUpdateUI	endm

SSBC_ObjMessageSend	proc	near
	uses	di, cx, dx, bp
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
SSBC_ObjMessageSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCSetOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the user selecting "outline"
CALLED BY:	MSG_SSBC_SET_OUTLINE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderControlClass
		ax - the message

		cx - CellBorderInfo

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBCSetOutline	method dynamic SSBorderControlClass, \
						MSG_SSBC_SET_OUTLINE
	;
	; Save the current status
	;
	mov	ds:[di].SSBCI_status, cl
	;
	; Turn off everything in the LTRB sides list
	;
	call	SSCGetChildBlockAndFeatures
	mov	si, offset LTRBList		;^lbx:si <- OD of list
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	cx, dx				;cx <- none selected
	call	SSBC_ObjMessageSend
	ret
SSBCSetOutline	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCSetSides
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the user selecting "left","top","right" or "bottom"
CALLED BY:	MSG_SSBC_SET_SIDES

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderControlClass
		ax - the message

		cl - CellBorderInfo

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBCSetSides	method dynamic SSBorderControlClass, \
						MSG_SSBC_SET_SIDES
	;
	; Save the current status
	;
	mov	ds:[di].SSBCI_status, cl
	;
	; Turn off the "outline" list
	;
	call	SSCGetChildBlockAndFeatures
	mov	si, offset OutlineList		;^lbx:si <- OD of list
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	call	SSBC_ObjMessageSend
	ret
SSBCSetSides	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSBCGenApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
CALLED BY:	MSG_GEN_APPLY

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSBorderControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSBCGenApply	method dynamic SSBorderControlClass, \
						MSG_GEN_APPLY
	push	{word}ds:[di].SSBCI_status		;save status
	;
	; Do the superclass thing
	;
	mov	di, offset SSBorderControlClass
	call	ObjCallSuperNoLock
	;
	; Send the current list status off to the spreadsheet
	;
	call	SSCGetChildBlockAndFeatures
	pop	cx				;cl <- CellBorderInfo
	mov	ax, MSG_SPREADSHEET_SET_CELL_BORDERS
	call	SSCSendToSpreadsheet
	ret
SSBCGenApply	endm

BorderControlCode	ends
