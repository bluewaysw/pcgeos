COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		uiHeader.asm
FILE:		uiHeader.asm

AUTHOR:		Gene Anderson, Jul 22, 1992

ROUTINES:
	Name			Description
	----			-----------
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	7/22/92		Initial revision

DESCRIPTION:
	

	$Id: uiHeader.asm,v 1.1 97/04/07 11:12:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSHeaderFooterControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

HeaderControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSHFCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSHeaderFooterControlClass
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSHeaderFooterControlClass
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

SSHFCGetInfo	method dynamic SSHeaderFooterControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSHFC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSHFCGetInfo	endm

SSHFC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	SSHFC_IniFileKey,		; GCBI_initFileKey
	SSHFC_gcnList,			; GCBI_gcnList
	length SSHFC_gcnList,		; GCBI_gcnCount
	SSHFC_notifyTypeList,		; GCBI_notificationList
	length SSHFC_notifyTypeList,	; GCBI_notificationCount
	SSHFCName,			; GCBI_controllerName

	handle SSHeaderUI,		; GCBI_dupBlock
	SSHFC_childList,		; GCBI_childList
	length SSHFC_childList,		; GCBI_childCount
	SSHFC_featuresList,		; GCBI_featuresList
	length SSHFC_featuresList,	; GCBI_featuresCount
	SSHFC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSHFC_IniFileKey	char	"ssHeaderFooter", 0

SSHFC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DOC_ATTR_CHANGE>

SSHFC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_DOC_ATTR_CHANGE>

;---

SSHFC_childList	GenControlChildInfo	\
	<offset SetHeaderTrigger, mask SSHFCF_SET_HEADER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SetFooterTrigger, mask SSHFCF_SET_FOOTER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ClearHeaderTrigger, mask SSHFCF_CLEAR_HEADER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ClearFooterTrigger, mask SSHFCF_CLEAR_FOOTER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>
					
; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSHFC_featuresList	GenControlFeaturesInfo	\
	<offset ClearFooterTrigger, SSClearFooterName, 0>,
	<offset ClearHeaderTrigger, SSClearHeaderName, 0>,
	<offset SetFooterTrigger, SSSetFooterName, 0>,
	<offset SetHeaderTrigger, SSSetHeaderName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSHFCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSHeaderFooterControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSHeaderFooterControlClass
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

SSHFCUpdateUI	method dynamic SSHeaderFooterControlClass, \
						MSG_GEN_CONTROL_UPDATE_UI
	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	dx, ds:NSSDAC_header.CR_start.CR_row
	mov	cx, ds:NSSDAC_footer.CR_start.CR_row
	call	MemUnlock
	pop	ds
	push	cx				;save footer info
	mov	bx, ss:[bp].GCUUIP_childBlock
	;
	; Enable / disable
	;
	mov	cx, mask SSHFCF_CLEAR_HEADER	;cx <- SSHFCFeatures
	mov	si, offset ClearHeaderTrigger
	call	SSHFCDoEnableDisable
	pop	dx
	mov	cx, mask SSHFCF_CLEAR_FOOTER	;cx <- SSHFCFeatures
	mov	si, offset ClearFooterTrigger
	call	SSHFCDoEnableDisable
	ret
SSHFCUpdateUI	endm

SSHFCDoEnableDisable	proc	near
	uses	bp
	.enter
	;
	; ss.[bp].GCUUIP_features
	; cx - SSHFCFeatures to check for
	; ^lbx:si - OD of feature
	; dx - start of range (enable) or -1 (disable)
	;
	test	ss:[bp].GCUUIP_features, cx	;feature exist?
	jz	noUI				;branch if not
	mov	ax, MSG_GEN_SET_ENABLED
	cmp	dx, -1				;any header?
	jne	gotMessage
CheckHack <MSG_GEN_SET_NOT_ENABLED eq MSG_GEN_SET_ENABLED+1>
	inc	ax				;disable
gotMessage:
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW			;dl <- VisUpdateMode
	call	ObjMessage
noUI:

	.leave
	ret
SSHFCDoEnableDisable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSHFCSetHeaderFooter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the
CALLED BY:	MSG_SSHFC_SET_HEADER_FOOTER

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSHeaderFooterControlClass
		ax - the message

		cx - TRUE to remove header/footer range
		dx - MSG_SPREADSHEET_{HEADER,FOOTER}_RANGE

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSHFCSetHeaderFooter	method dynamic SSHeaderFooterControlClass, \
						MSG_SSHFC_SET_HEADER_FOOTER
	mov	ax, dx				;ax <- message to send
	call	SSCSendToSpreadsheet
	ret
SSHFCSetHeaderFooter	endm

HeaderControlCode	ends
