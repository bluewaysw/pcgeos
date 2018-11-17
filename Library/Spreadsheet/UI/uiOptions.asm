COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiOptions.asm

AUTHOR:		Gene Anderson, Aug  5, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/ 5/92		Initial revision


DESCRIPTION:
	Code for SSOptionsControl
		

	$Id: uiOptions.asm,v 1.1 97/04/07 11:12:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSOptionsControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

OptionsControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSOCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSOptionsControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSOptionsControlClass
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

SSOCGetInfo	method dynamic SSOptionsControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSOC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSOCGetInfo	endm

SSOC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSOC_IniFileKey,		; GCBI_initFileKey
	SSOC_gcnList,			; GCBI_gcnList
	length SSOC_gcnList,		; GCBI_gcnCount
	SSOC_notifyTypeList,		; GCBI_notificationList
	length SSOC_notifyTypeList,	; GCBI_notificationCount
	SSOCName,			; GCBI_controllerName

	handle SSOptionsControlUI,	; GCBI_dupBlock
	SSOC_childList,			; GCBI_childList
	length SSOC_childList,		; GCBI_childCount
	SSOC_featuresList,		; GCBI_featuresList
	length SSOC_featuresList,	; GCBI_featuresCount
	SSOC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif


SSOC_IniFileKey	char	"ssOptions", 0

SSOC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DOC_ATTR_CHANGE>

SSOC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_DOC_ATTR_CHANGE>

;---

SSOC_childList	GenControlChildInfo	\
	<offset OptionsList, mask SSOCF_DRAW_GRID or \
				mask SSOCF_DRAW_NOTE_BUTTON or \
				mask SSOCF_DRAW_HEADER_FOOTER_BUTTON or \
				mask SSOCF_SHOW_FORMULAS, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSOC_featuresList	GenControlFeaturesInfo	\
	<offset DrawGridEntry, DrawGridName, 0>,
	<offset DrawNoteEntry, DrawNoteName, 0>,
	<offset DrawHeaderFooterEntry, DrawHeaderFooterName, 0>,
	<offset ShowFormulasEntry, ShowFormulasName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSOCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSOptionsControl

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSOptionsControlClass
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
	gene	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSOCUpdateUI		method dynamic SSOptionsControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	test	ss:[bp].GCUUIP_features, mask SSOCF_DRAW_GRID or \
					mask SSOCF_DRAW_NOTE_BUTTON or \
					mask SSOCF_DRAW_HEADER_FOOTER_BUTTON
	jz	noListOptions
	;
	; Get the notification data
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	cx, es:NSSDAC_drawFlags		;cx <- SpreadsheetDrawFlags
	call	MemUnlock
	;
	; Set the options in the list
	;
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset OptionsList		;^lbx:si <- OD of list
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx				;dx <- no indeterminates
	call	ObjMessage
noListOptions:
	ret
SSOCUpdateUI		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSOCSetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to set options to the target spreadsheet

CALLED BY:	MSG_SSOC_SET_OPTIONS
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSOptionsControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSOCSetOptions		method dynamic SSOptionsControlClass,
						MSG_SSOC_SET_OPTIONS
	mov	ax, MSG_SPREADSHEET_ALTER_DRAW_FLAGS
	mov	dx, cx
	not	dx
	andnf	dx, mask SDF_DRAW_GRID or \
			mask SDF_DRAW_NOTE_BUTTON or \
			mask SDF_DRAW_HEADER_FOOTER_BUTTON or \
			mask SDF_SHOW_FORMULAS
	mov	ax, MSG_SPREADSHEET_ALTER_DRAW_FLAGS
	call	SSCSendToSpreadsheet
	ret
SSOCSetOptions		endm

OptionsControlCode	ends
