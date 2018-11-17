COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiNotes.asm

AUTHOR:		Gene Anderson, Aug  5, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/ 5/92		Initial revision


DESCRIPTION:
	Code for SSNoteController
		

	$Id: uiNotes.asm,v 1.1 97/04/07 11:12:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSNoteControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

NoteControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSNCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSNoteControlClass
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSNCGetInfo		method dynamic SSNoteControlClass,
						 MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSNC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSNCGetInfo		endm

SSNC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	0,				; GCBI_initFileKey
	SSNC_gcnList,			; GCBI_gcnList
	length SSNC_gcnList,		; GCBI_gcnCount
	SSNC_notifyTypeList,		; GCBI_notificationList
	length SSNC_notifyTypeList,	; GCBI_notificationCount
	SSNCName,			; GCBI_controllerName

	handle SSNoteControlUI,		; GCBI_dupBlock
	SSNC_childList,			; GCBI_childList
	length SSNC_childList,		; GCBI_childCount
	SSNC_featuresList,		; GCBI_featuresList
	length SSNC_featuresList,	; GCBI_featuresCount
	SSNC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	SSNC_helpContext>		; GCBI_helpContext


if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif

SSNC_helpContext	char	"dbSSNote", 0

SSNC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_CELL_NOTES_CHANGE>

SSNC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_CELL_NOTES_CHANGE>

;---

SSNC_childList	GenControlChildInfo	\
	<offset NotesText, mask SSNCF_NOTES, mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSNC_featuresList	GenControlFeaturesInfo	\
	<offset NotesText,  SSNCNotesName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSNCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSNoteControl

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSNoteControlClass
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
SSNCUpdateUI		method dynamic SSNoteControlClass,
						MSG_GEN_CONTROL_UPDATE_UI

	;
	; Get the notification data
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	bx
	call	MemLock
	mov	dx, ax
	;
	; Set the text
	;
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	si, offset NotesText		;^lbx:si <- OD of list
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				;cx <- NULL-terminated
	clr	bp				;dx:bp <- ptr to text
	call	ObjMessage
	;
	; Done with the notification data
	;
	pop	bx
	call	MemUnlock
	ret
SSNCUpdateUI		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSNCSetNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to set notes

CALLED BY:	MSG_SSOC_SET_NOTES
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSNoteControlClass
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
SSNCSetNotes		method dynamic SSNoteControlClass,
						MSG_SSNC_SET_NOTES
	call	SSCGetChildBlockAndFeatures
	;
	; Get the text from the text beasty
	;
	mov	si, offset NotesText		;^lbx:si <- OD of text object
	clr	dx				;dx <- allocate, please
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; Send the text off to the spreadsheet
	;
	mov	ax, MSG_SPREADSHEET_SET_NOTE_FOR_ACTIVE_CELL
	call	SSCSendToSpreadsheet
	ret
SSNCSetNotes		endm

NoteControlCode	ends
