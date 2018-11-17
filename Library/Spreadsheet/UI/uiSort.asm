COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiSort.asm
FILE:		uiSort.asm

AUTHOR:		Gene Anderson, May 22, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/22/92		Initial revision

DESCRIPTION:
	

	$Id: uiSort.asm,v 1.1 97/04/07 11:12:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSSortControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

SortControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSSCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSSortControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSSortControlClass
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

SSSCGetInfo	method dynamic SSSortControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSSC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSSCGetInfo	endm

SSSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSSC_IniFileKey,		; GCBI_initFileKey
	SSSC_gcnList,			; GCBI_gcnList
	length SSSC_gcnList,		; GCBI_gcnCount
	SSSC_notifyTypeList,		; GCBI_notificationList
	length SSSC_notifyTypeList,	; GCBI_notificationCount
	SSSCName,			; GCBI_controllerName

	handle SSSortControlUI,		; GCBI_dupBlock
	SSSC_childList,			; GCBI_childList
	length SSSC_childList,		; GCBI_childCount
	SSSC_featuresList,		; GCBI_featuresList
	length SSSC_featuresList,	; GCBI_featuresCount
	SSSC_DEFAULT_FEATURES,		; GCBI_features

	handle SSSortControlToolboxUI,	; GCBI_toolBlock
	SSSC_toolList,			; GCBI_toolList
	length SSSC_toolList,		; GCBI_toolCount
	SSSC_toolFeaturesList,		; GCBI_toolFeaturesList
	length SSSC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SSSC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	SSSC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif


SSSC_helpContext	char	"dbSSSort", 0

SSSC_IniFileKey	char	"ssSort", 0

SSSC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE>

SSSC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_SELECTION_CHANGE>

;---

SSSC_childList	GenControlChildInfo	\
    <offset SortDB, mask SSSCF_SORT_BY or \
			mask SSSCF_SORT_ORDER or \
			mask SSSCF_SORT_OPTIONS, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSSC_featuresList	GenControlFeaturesInfo	\
	<offset SortOptionsList, SortOptionsName, 0>,
	<offset SortOrderList, SortOrderName, 0>,
	<offset SortByList, SortByName, 0>

;---

SSSC_toolList	GenControlChildInfo	\
    <offset SortAscendingToolTrigger, mask SSSCTF_SORT_ASCENDING,
					 mask GCCF_IS_DIRECTLY_A_FEATURE>,
    <offset SortDescendingToolTrigger, mask SSSCTF_SORT_DESCENDING,
					 mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSSC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset SortAscendingToolTrigger, SortAscendingToolName, 0>,
	<offset SortDescendingToolTrigger, SortDescendingToolName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSSCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSSortControl
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSSortControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSSCUpdateUI	method dynamic SSSortControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	dx, ds:NSSSC_flags		;dx <- SSheetSelectionFlags
	call	MemUnlock
	pop	ds
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	;
	; Is there any selection beyond a single cell?
	;
	push	ax, dx, si
	mov	ax, MSG_GEN_SET_ENABLED
	test	dx, mask SSSF_SINGLE_CELL
	jz	gotSelection
	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotSelection:
	push	ax
	mov	si, offset SortDB		;^lbx:si <- OD of us
	mov	dl, VUM_NOW
	call	SSSCObjMessageSend
	pop	cx
	pop	ax, dx, si
	;
	; If just a single cell, we're done
	;
	test	dx, mask SSSF_SINGLE_CELL
	jnz	doneUI
	;
	; Deal with the "Sort by" list
	;
	test	ax, mask SSSCF_SORT_BY
	jz	noSortBy
	;
	; Sort by rows or by columns?
	;
	mov	cx, mask RSF_SORT_ROWS		;cx <- item to set
	test	dx, mask SSSF_SINGLE_ROW
	jz	gotBy
	clr	cx				;cx <- item to set
gotBy:
	push	dx
	clr	dx				;dx <- not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	si, offset SortByList		;^lbx:si <- OD of list
	call	SSSCObjMessageSend
	pop	dx				;dx <- SSheetSelectionFlags
noSortBy:
doneUI:
	;
	; Deal with tools, if we have them
	;
	mov	ax, ss:[bp].GCUUIP_toolboxFeatures 
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	cx, MSG_GEN_SET_ENABLED
	test	dx, mask SSSF_SINGLE_ROW
	jz	gotMsg
	mov	cx, MSG_GEN_SET_NOT_ENABLED
gotMsg:
	test	ax, mask SSSCTF_SORT_ASCENDING
	jz	noAscending
	push	ax, cx
	mov	si, offset SortAscendingToolTrigger
	mov	dl, VUM_NOW
	mov	ax, cx				;ax <- enable or disable
	call	SSSCObjMessageSend
	pop	ax, cx
noAscending:
	test	ax, mask SSSCTF_SORT_DESCENDING
	jz	noDescending
	push	ax, cx
	mov	si, offset SortDescendingToolTrigger
	mov	dl, VUM_NOW
	mov	ax, cx				;ax <- enable or disable
	call	SSSCObjMessageSend
	pop	ax, cx
noDescending:
	ret
SSSCUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSSCSort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "Sort" being pressed
CALLED BY:	MSG_SSSC_SORT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSSortControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSSCSort	method dynamic SSSortControlClass, \
						MSG_SSSC_SORT
	push	si
	call	SSCGetChildBlockAndFeatures
	clr	cl				;cl <- RangeSortFlags
	;
	; Get Rows/Columns
	;
	push	cx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset SortByList		;^lbx:si <- OD of list
	call	SSSCObjMessageCall
	pop	cx
	ornf	cl, al				;cl <- RangeSortFlags
	;
	; Get Ascending/Descending
	;
	push	cx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset SortOrderList	;^lbx:si <- OD of list
	call	SSSCObjMessageCall
	pop	cx
	ornf	cl, al				;cl <- RangeSortFlags
	;
	; Get Ignore Case
	;
	push	cx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	si, offset SortOptionsList	;^lbx:si <- OD of list
	call	SSSCObjMessageCall
	pop	cx
	ornf	cl, al				;cl <- RangeSortFlags
	;
	; Send the results off to the spreadsheet
	;
	pop	si
	GOTO	SSSCSortTrigger
SSSCSort	endm

SSSCObjMessageSend	proc	near
	uses	di, bp
	.enter
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SSSCObjMessageSend	endp

SSSCObjMessageCall	proc	near
	uses	di, bp
	.enter
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	.leave
	ret
SSSCObjMessageCall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSSCSortTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle sort from a trigger

CALLED BY:	MSG_SSSC_SORT_TRIGGER
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSSortControlClass
		ax - the message

		cl - RangeSortFlags

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSSCSortTrigger		method SSSortControlClass,
						MSG_SSSC_SORT_TRIGGER
	mov	ax, MSG_SPREADSHEET_SORT_RANGE
	call	SSCSendToSpreadsheet
	ret
SSSCSortTrigger		endm

SortControlCode	ends
