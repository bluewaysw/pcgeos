COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiRecalc.asm

AUTHOR:		Gene Anderson, Aug  4, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT SSRC_ObjMessageSend	Update UI for SSRecalcControl

    INT SSRC_ObjMessageCall	Update UI for SSRecalcControl

    INT IterationEnableDisable	Enable or disable the iteration values, as
				appropriate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	8/ 4/92		Initial revision
	witt	11/11/93	DBCS-ized some buffers.


DESCRIPTION:
	Code for SSRecalcControl
		

	$Id: uiRecalc.asm,v 1.2 98/02/01 19:22:52 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;---------------------------------------------------

SpreadsheetClassStructures	segment	resource
	SSRecalcControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

RecalcControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSRCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRecalcControlClass
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
SSRCGetInfo		method dynamic SSRecalcControlClass,
						 MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSRC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSRCGetInfo		endm

SSRC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSRC_IniFileKey,		; GCBI_initFileKey
	SSRC_gcnList,			; GCBI_gcnList
	length SSRC_gcnList,		; GCBI_gcnCount
	SSRC_notifyTypeList,		; GCBI_notificationList
	length SSRC_notifyTypeList,	; GCBI_notificationCount
	SSRCName,			; GCBI_controllerName

	handle SSRecalcUI,		; GCBI_dupBlock
	SSRC_childList,			; GCBI_childList
	length SSRC_childList,		; GCBI_childCount
	SSRC_featuresList,		; GCBI_featuresList
	length SSRC_featuresList,	; GCBI_featuresCount
	SSRC_DEFAULT_FEATURES,		; GCBI_features

	handle SSRecalcToolUI,		; GCBI_toolBlock
	SSRC_toolList,			; GCBI_toolList
	length SSRC_toolList,		; GCBI_toolCount
	SSRC_toolFeaturesList,		; GCBI_toolFeaturesList
	length SSRC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SSRC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	segment	resource
endif


SSRC_IniFileKey	char	"ssRecalc", 0

SSRC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_DOC_ATTR_CHANGE>

SSRC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_DOC_ATTR_CHANGE>

;---

SSRC_childList	GenControlChildInfo	\
	<offset RecalcTrigger, mask SSRCF_RECALC_NOW,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ConvergeDB, mask SSRCF_CONVERGE_DB, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSRC_featuresList	GenControlFeaturesInfo	\
	<offset RecalcTrigger, SSRCRecalcName, 0>,
	<offset ConvergeDB, SSRCConvergeName, 0>

;---

SSRC_toolList	GenControlChildInfo	\
	<offset RecalcTool, mask SSRCF_RECALC_NOW,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SSRC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset RecalcTool, SSRCRecalcToolName, 0>

if FULL_EXECUTE_IN_PLACE
SpreadsheetControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSRCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSRecalcControl

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRecalcControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSRCUpdateUI		method dynamic SSRecalcControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	;
	; Does the Calculation DB exist?
	;
	test	ss:[bp].GCUUIP_features, mask SSRCF_CONVERGE_DB
	LONG jz	noDB
	;
	; Get the notification block
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	bx
	call	MemLock
	push	ds
	mov	dx, ax
	mov	ds, ax
	mov	ax, ds:NSSDAC_circCount		;ax <- maximum # of iterations
	mov	cx, ds:NSSDAC_calcFlags		;cx <- SpreadsheetFlags
	pop	ds
	mov	bx, ss:[bp].GCUUIP_childBlock
	push	ax
	;
	; Update the Auto/Manual list
	;
	push	cx, dx
	andnf	cx, mask SF_MANUAL_RECALC	;cx <- selection
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	si, offset RecalcAutoList
	clr	dx				;dx <- not indeterminate
	call	SSRC_ObjMessageSend
	pop	cx, dx
	;
	; Update the Iteration list
	;
	push	cx, dx
	andnf	cx, mask SF_ALLOW_ITERATION	;cx <- selection
	mov	si, offset IterationList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx				;dx <- not indeterminate
	call	SSRC_ObjMessageSend
	pop	cx, dx
	;
	; Update the maximum number of iterations
	;
	pop	ax
	push	cx, dx, bp
	mov	cx, ax				;ax <- maximum # of iterations
	clr	bp				;bp <- not indeterminate
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	si, offset IterationNumMax
	call	SSRC_ObjMessageSend
	pop	cx, dx, bp
	;
	; Format the FloatNum as text
	;
	push	cx
SBCS<	sub	sp, FLOAT_TO_ASCII_NORMAL_BUF_LEN			>
DBCS<	sub	sp, FLOAT_TO_ASCII_NORMAL_BUF_LEN*(size wchar)		>
	mov	di, sp				;es:di <- ptr to buffer
	push	bx, ds
	segmov	es, ss
	mov	ds, dx
	mov	si, offset NSSDAC_converge	;ds:si <- ptr to FloatNum
	mov	ax, mask FFAF_FROM_ADDR or mask FFAF_NO_TRAIL_ZEROS
	mov	bh, DECIMAL_PRECISION
	mov	bl, DECIMAL_PRECISION - 1
	call	FloatFloatToAscii_StdFormat
	pop	bx, ds
	;
	; Set the text
	;
	push	bp
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	bp, di
	mov	dx, ss				;dx:bp <- ptr to text
	clr	cx				;cx <- NULL-terminated
	mov	si, offset IterationChangeMax
	call	SSRC_ObjMessageCall
	pop	bp
SBCS<	add	sp, FLOAT_TO_ASCII_NORMAL_BUF_LEN			>
DBCS<	add	sp, FLOAT_TO_ASCII_NORMAL_BUF_LEN*(size wchar)  	>
	;
	; If iteration is off, disable the appropriate features.
	;
	pop	cx				;cx <- SpreadsheetFlags
	call	IterationEnableDisable
	;
	; Done with the notification block
	;
	pop	bx				;bx <- handle of notification
	call	MemUnlock
noDB:
	ret
SSRCUpdateUI		endm

SSRC_ObjMessageSend	proc	near
	uses	ax, dx, di
	.enter

	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
SSRC_ObjMessageSend	endp

SSRC_ObjMessageCall	proc	near
	uses	bp, di
	.enter

	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
SSRC_ObjMessageCall	endp

if 0
	;
	; See SSRCSetRecalc() re: bug ND-000289.
	;

SSRC_SetTrigger		proc	near
	uses	si, dx, di
	.enter

	mov	si, offset RecalcTool
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	.leave
	ret
SSRC_SetTrigger		endp

endif
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSRCSetRecalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "Apply" from ConvergeDB

CALLED BY:	MSG_SSRC_SET_RECALC
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRecalcControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSRCSetRecalc		method dynamic SSRecalcControlClass,
						MSG_SSRC_SET_RECALC
	call	SSCGetChildBlockAndFeatures
SBCS<	sub	sp, (size SpreadsheetRecalcParams)+FLOAT_TO_ASCII_NORMAL_BUF_LEN	>
DBCS<	sub	sp, (size SpreadsheetRecalcParams)+(FLOAT_TO_ASCII_NORMAL_BUF_LEN*(size wchar))	>
	mov	bp, sp				;ss:bp <- params
	push	si
	;
	; Get the state of the various flags
	;
	mov	si, offset RecalcAutoList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	SSRC_ObjMessageCall
	mov	ss:[bp].SRP_flags, ax		;store flags
	mov	si, offset IterationList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	SSRC_ObjMessageCall
	ornf	ss:[bp].SRP_flags, ax		;add flags
	;
	; Get the "Maximum Iterations"
	;
	mov	si, offset IterationNumMax
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	SSRC_ObjMessageCall
	mov	ss:[bp].SRP_circCount, dx
	;
	; Get the text from the "Maximum Change"
	;
	push	bp
	mov	si, offset IterationChangeMax
	add	bp, (size SpreadsheetRecalcParams)
	mov	dx, ss				;dx:bp <- ptr to buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	SSRC_ObjMessageCall
	mov	si, bp
	pop	bp
	;
	; Attempt to parse it into a float
	;
	push	ds
	mov	es, dx
	lea	di, ss:[bp].SRP_converge	;es:di <- ptr to result buffer
	mov	ds, dx				;ds:si <- ptr to text
	mov	al, mask FAF_STORE_NUMBER	;al <- FloatAsciiToFloatFlags
	call	FloatAsciiToFloat
	pop	ds
	pop	si				;*ds:si - ourselves
	jc	quit				;branch if error
	;
	; Send the results off to the spreadsheet
	;
	mov	ax, MSG_SPREADSHEET_CHANGE_RECALC_PARAMS
	mov	dx, (size SpreadsheetRecalcParams)
	call	SSCSendToSpreadsheetStack
	;
	; Send an apply off to the interaction
	;
if 0
	push	si ;ND-000289
endif
	mov	si, offset ConvergeDB
	mov	ax, MSG_GEN_APPLY
	call	SSRC_ObjMessageSend
if 0
	;
	; ND-000289 - NewCalc, Calculate Now tool is always disabled.
	; 'Calculate Now' and the recalculate tool used to be disabled
	; if calculation was automatic.  The menu item was changed
	; to be always enabled; this changes to tool item to match.
	;

	;
	; Get the selection to enable/disable Calculate Now trigger
	;
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset RecalcAutoList
	mov	di, mask MF_CALL
	call 	ObjMessage	; return ax <-- selection
	
	pop	si			; to get *ds:si <-- controller
	mov_tr	cx, ax			; save returned selection in cx
	call	SSCGetToolBlockAndTools	; return bx <-- handle of tool block
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; disable RecalcToolTrigger
	jcxz	setTriggerState			; is 'Manual' or 'Automatic'
	mov	ax, MSG_GEN_SET_ENABLED		; enable RecalcToolTrigger

setTriggerState:
	call	SSRC_SetTrigger
endif

quit::
SBCS<	add	sp, (size SpreadsheetRecalcParams)+FLOAT_TO_ASCII_NORMAL_BUF_LEN	>
DBCS<	add	sp, (size SpreadsheetRecalcParams)+(FLOAT_TO_ASCII_NORMAL_BUF_LEN*(size wchar))	>
	ret


SSRCSetRecalc		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSRCRecalcNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle "recalculate now"

CALLED BY:	MSG_SSRC_RECALC_NOW
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRecalcControlClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSRCRecalcNow		method dynamic SSRecalcControlClass,
						MSG_SSRC_RECALC_NOW
	mov	ax, MSG_SPREADSHEET_RECALC
	call	SSCSendToSpreadsheet
	ret
SSRCRecalcNow		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSRCIterateOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle turning iteration on/off

CALLED BY:	MSG_SSRC_ITERATE_ON_OFF
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSRecalcControlClass
		ax - the message

		cx - current selection (SpreadsheetFlags)

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSRCIterateOnOff		method dynamic SSRecalcControlClass,
						MSG_SSRC_ITERATE_ON_OFF
	call	SSCGetChildBlockAndFeatures
	call	IterationEnableDisable
	ret
SSRCIterateOnOff		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IterationEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the iteration values, as appropriate

CALLED BY:	INTERNAL: SSRCIterateOnOff(), SSRCUpdateUI()
PASS:		bx - handle of child block
		cx - SpreadsheetFlags
RETURN:		none
DESTROYED:	ax, cx, dx, bp, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IterationEnableDisable	proc	near
	mov	ax, MSG_GEN_SET_ENABLED
	test	cx, mask SF_ALLOW_ITERATION
	jnz	allowIteration
	mov	ax, MSG_GEN_SET_NOT_ENABLED
allowIteration:
	mov	dl, VUM_NOW
	mov	si, offset IterationNumMax
	call	SSRC_ObjMessageSend
	mov	si, offset IterationChangeMax
	call	SSRC_ObjMessageSend
	ret
IterationEnableDisable	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JUGVGenValueGetTextFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return correct text filter

CALLED BY:	MSG_GEN_VALUE_GET_TEXT_FILTER

PASS:		nothing
RETURN:		al	<- VisTextFilters
DESTROYED:	(none)
		ah, cx, dx, bp allowed
SIDE EFFECTS:
		none
PSEUDO CODE/STRATEGY:
		none
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	7/ 1/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RecalcControlCode ends
