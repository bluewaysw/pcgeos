COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiHeight.asm
FILE:		uiHeight.asm

AUTHOR:		Gene Anderson, Jul  6, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/ 6/92		Initial revision

DESCRIPTION:
	Row Height controller

	$Id: uiHeight.asm,v 1.1 97/04/07 11:12:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSRowHeightControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

WidthControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSHCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSRowHeightControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRowHeightControlClass
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

SSHCGetInfo	method dynamic SSRowHeightControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSHC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSHCGetInfo	endm

SSHC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSHC_IniFileKey,		; GCBI_initFileKey
	SSHC_gcnList,			; GCBI_gcnList
	length SSHC_gcnList,		; GCBI_gcnCount
	SSHC_notifyTypeList,		; GCBI_notificationList
	length SSHC_notifyTypeList,	; GCBI_notificationCount
	SSHCName,			; GCBI_controllerName

	handle SSRowHeightUI,		; GCBI_dupBlock
	SSHC_childList,			; GCBI_childList
	length SSHC_childList,		; GCBI_childCount
	SSHC_featuresList,		; GCBI_featuresList
	length SSHC_featuresList,	; GCBI_featuresCount
	SSRHC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	SSHC_helpContext>		; GCBI_helpContext


if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSHC_helpContext	char	"dbRowHeight", 0

SSHC_IniFileKey	char	"ssHeight", 0

SSHC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE>

SSHC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_CELL_WIDTH_HEIGHT_CHANGE>

;---

SSHC_childList	GenControlChildInfo	\
	<offset RowHeightDB, mask SSRHCF_CUSTOM,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSHC_featuresList	GenControlFeaturesInfo	\
	<offset RowHeightDB, SSHCCustomName, 0>


if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSHCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSRowHeightControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRowHeightControlClass
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

SSHCUpdateUI	method dynamic SSRowHeightControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	dl, ds:NSSCWHC_flags		;dl <- SSheetWidthHeightFlags
	mov	cx, ds:NSSCWHC_height		;cx <- row height
	call	MemUnlock
	pop	ds
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	;
	; Is there a custom height DB?
	;
EC <	test	ax, mask SSRHCF_CUSTOM		;>
EC <	ERROR_Z	CONTROLLER_NO_UI_FOR_CONTROLLER	;>
	;
	; Is the height indeterminate?
	;
	clr	bp				;bp <- assume has value
	test	dl, mask SSWHF_MULTIPLE_HEIGHTS	;multiple heights
	jz	noMultWidths			;branch if not multiple heights
	dec	bp				;bp <- indeterminate value
noMultWidths:
	push	cx
	andnf	cx, not (ROW_HEIGHT_AUTOMATIC)	;cx <- height only
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	si, offset RHRange		;^lbx:si <- OD of range
	call	SSWC_ObjMessageSend
	pop	cx
	;
	; Set the "Automatic" option
	;
	clr	ax				;ax <- assume not indeterminate
	test	dl, mask SSWHF_MULTIPLE_HEIGHTS
	jz	notIndeterminate
	ornf	ax, ROW_HEIGHT_AUTOMATIC	;ax <- indeterminate booleans
notIndeterminate:
	andnf	cx, ROW_HEIGHT_AUTOMATIC	;cx <- 0 or ROW_HEIGHT_AUTOMATIC
	push	cx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	si, offset RHOptions
	call	SSWC_ObjMessageSend
	pop	cx
	;
	; If we're setting the "Automatic" option, disable the range else
	; enable it.
	;
	mov	ax, MSG_GEN_SET_ENABLED		;ax <- assume enabling
	jcxz	doEnable			;branch if not automatic
	inc	ax				;ax <- MSG_GEN_SET_NOT_ENABLED
CheckHack <MSG_GEN_SET_ENABLED eq MSG_GEN_SET_NOT_ENABLED-1>
doEnable:
	mov	si, offset RHRange
	mov	dl, VUM_NOW
	call	SSWC_ObjMessageSend

	ret
SSHCUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSHCSetHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the height (from the spin gadget)
CALLED BY:	MSG_SSHC_SET_ROW_HEIGHT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRowHeightControlClass
		ax - the message

		dx.cx - current value
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSHCSetHeight	method dynamic SSRowHeightControlClass, \
						MSG_GEN_APPLY
	;
	; Let our superclass to its thing
	;
	mov	di, offset SSRowHeightControlClass
	call	ObjCallSuperNoLock
	;
	; Get the "Automatic" flag
	;
	call	SSCGetChildBlockAndFeatures	;bx <- child block
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	si, offset RHOptions
	call	SSWC_ObjMessageCall		;ax <- selected booleans
	push	ax
	;
	; Get the height
	;
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	mov	si, offset RHRange
	call	SSWC_ObjMessageCall		;dx.cx <- current value
	;
	; Send the results to the spreadsheet
	;
	pop	ax				;ax <- selected booleans
	ornf	ax, dx				;ax <- flag + value
	mov	cx, ax				;cx <- flag + height
	mov	ax, MSG_SPREADSHEET_SET_ROW_HEIGHT
	mov	dx, SPREADSHEET_ADDRESS_USE_SELECTION
	call	SSCSendToSpreadsheet
	ret
SSHCSetHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSHCRowHeightAutomatic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a change in the automatic flag
CALLED BY:	MSG_SSHC_ROW_HEIGHT_AUTOMATIC

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRowHeightControlClass
		ax - the message

		cx - selected booleans
		dx - indeterminate booleans
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSHCRowHeightAutomatic	method dynamic SSRowHeightControlClass, \
						MSG_SSRHC_ROW_HEIGHT_AUTOMATIC
	call	SSCGetChildBlockAndFeatures	;bx <- child block
	;
	; If "Automatic" is set, disable the range
	;
	mov	ax, MSG_GEN_SET_ENABLED		;ax <- assume enabling
	jcxz	doEnable
CheckHack <MSG_GEN_SET_ENABLED eq MSG_GEN_SET_NOT_ENABLED-1>	
	inc	ax				;ax <- MSG_GEN_SET_NOT_ENABLED
doEnable:
	mov	si, offset RHRange
	mov	dl, VUM_NOW
	call	SSWC_ObjMessageSend
	ret
SSHCRowHeightAutomatic	endm

WidthControlCode	ends
