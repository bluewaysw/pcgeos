COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiFormatControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the VisBitmapFormatControlClass

	$Id: uiFormatControl.asm,v 1.1 97/04/04 17:43:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BitmapClassStructures	segment resource
	VisBitmapFormatControlClass
BitmapClassStructures	ends

VisBitmapUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisBitmapFormatControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for VisBitmapFormatControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of VisBitmapFormatControlClass

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
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
VisBitmapFormatControlGetInfo	method dynamic	VisBitmapFormatControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset VBFC_dupInfo
	call	CopyDupInfoCommon
	ret
VisBitmapFormatControlGetInfo	endm

VBFC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	VBFC_IniFileKey,		; GCBI_initFileKey
	VBFC_gcnList,			; GCBI_gcnList
	length VBFC_gcnList,		; GCBI_gcnCount
	VBFC_notifyList,		; GCBI_notificationList
	length VBFC_notifyList,		; GCBI_notificationCount
	VBFCName,			; GCBI_controllerName

	handle VisBitmapFormatControlUI,; GCBI_dupBlock
	VBFC_childList,			; GCBI_childList
	length VBFC_childList,		; GCBI_childCount
	VBFC_featuresList,		; GCBI_featuresList
	length VBFC_featuresList,	; GCBI_featuresCount

	VBFC_DEFAULT_FEATURES,		; GCBI_features

	0,
	0,
	0,
	0,
	0,
	0,
	VBFC_helpContext>		; GCBI_helpContext

if _FXIP
BitmapControlInfoXIP	segment resource
endif

VBFC_helpContext	char	"dbBitmapFrmt", 0

VBFC_IniFileKey		char	"VisBitmapFormat", 0

VBFC_gcnList		GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_FORMAT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_BODY_SELECTION_STATE_CHANGE>

VBFC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_BITMAP_CURRENT_FORMAT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_BODY_SELECTION_STATE_CHANGE>

;---


VBFC_childList		GenControlChildInfo \
	<offset VisBitmapFormatItemGroup, mask VBFCF_MONO or \
					  mask VBFCF_4BIT or \
					  mask VBFCF_8BIT, 0>,
	<offset VisBitmapResolutionInteraction, mask VBFCF_72_DPI or \
					        mask VBFCF_300_DPI or \
					        mask VBFCF_CUSTOM_DPI, 0>


VBFC_featuresList	GenControlFeaturesInfo	\
	<offset DpiCustomItem, DpiCustomName, 0>,
	<offset Dpi300Item, Dpi300Name, 0>,
	<offset Dpi72Item, Dpi72Name, 0>,
	<offset Color4BitItem, Color4BitName, 0>,
	<offset MonoItem, MonoName, 0>,
	<offset Color8BitItem, Color8BitName, 0>

if _FXIP
BitmapControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapFormatControlSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the new bitmap format

CALLED BY:	MSG_VBCF_SET_FORMAT

PASS:		*ds:si = VisBitmapFormatControl object
		ds:di = VisBitmapFormatControl instance

RETURN:		nothing

DESTROYED:	ax, bx, di

COMMENTS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	Feb 24, 1992 	Initial version.
	don	11-13-93	Added code to deal with missing
				controller features

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapFormatControlSetFormat	method dynamic	VisBitmapFormatControlClass,
						MSG_VBFC_SET_FORMAT
features	local	word
resolution	local	word
format		local	BMFormat
changed		local	BooleanByte
		.enter
		ForceRef	unused
	;
	; Grab the last reported values, just in case we don't
	; have all of the controller's features
	;
		push	si
		mov	ax, TEMP_VIS_BITMAP_FORMAT_INSTANCE
		call	ObjVarDerefData
		mov	ax, ds:[bx].TVBFI_resolution
		mov	ss:[resolution], ax
		mov	al, ds:[bx].TVBFI_format
		mov	ss:[format], al
		mov	ss:[changed], BB_FALSE
		call	GetChildBlockAndFeatures
		mov	ss:[features], ax
	;
	; Grab the current resolution
	;
		test	ss:[features], mask VBFCF_72_DPI or \
				       mask VBFCF_300_DPI or \
				       mask VBFCF_CUSTOM_DPI
		jz	getFormat		
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset VisBitmapResolutionItemGroup
		call	ObjMessage_near_call_save_bp
	;
	; If custom or unknown, assume custom
	;
		tst	ax			;see if custom
		jz	getValue
		cmp	ax, GIGS_NONE
		jne	haveResolution
	;
	; Ask the GenValue for the custom selection
	;
getValue:
		test	ss:[features], mask VBFCF_CUSTOM_DPI
		jz	getFormat
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		mov	si, offset VisBitmapCustomResolutionValue
		call	ObjMessage_near_call_save_bp
		mov_tr	ax, dx			; resolution => AX
haveResolution:
		cmp	ss:[resolution], ax
		je	getFormat
		mov	ss:[resolution], ax	; store resolution
		mov	ss:[changed], BB_TRUE	; mark as changed
	; 
	; Get the format of the bitmap
	;
getFormat:
		test	ss:[features], mask VBFCF_MONO or mask VBFCF_4BIT
		jz	spewData
		mov	si, offset VisBitmapFormatItemGroup
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjMessage_near_call_save_bp
		cmp	ss:[format], al
		je	spewData
		mov	ss:[format], al		; store format
		mov	ss:[changed], BB_TRUE	; mark as changed
	;
	; Send message to ourselves to change the format. We do this so
	; that multiple format-change messages are not sent, thereby
	; allowing us to ask the user to confirm the change.
	;
spewData: 
		mov	bx, ds:[LMBH_handle]
		pop	si			; my OD => ^lBX:SI
		tst	ss:[changed]		; if no changes, do nothing
		jz	done
		mov	ax, MSG_VBFC_SET_FORMAT_NOW
		mov	cl, ss:[format]
		mov	dx, ss:[resolution]
		mov	di, mask MF_FORCE_QUEUE or \
			    mask MF_CHECK_DUPLICATE or \
			    mask MF_REPLACE
		call	ObjMessage		
done:
		.leave
		ret
VisBitmapFormatControlSetFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapFormatControlSetFormatNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the format of the bitmap now, after having the
		three possible MSG_VBFC_SET_FORMAT messages.

CALLED BY:	GLOBAL (MSG_VBFC_SET_FORMAT_NOW)

PASS:		*DS:SI	= VisBitmapFormatControlClass object
		DS:DI	= VisBitmapFormatControlClassInstance
		CL	= BMFormat
		DX	= Resolution

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisBitmapFormatControlSetFormatNow method dynamic VisBitmapFormatControlClass,
						  MSG_VBFC_SET_FORMAT_NOW

	; gets clobbered by a low-level generic routine doing an ObjMessage
	; without any fixups..  so:
		push	ds:[OLMBH_header].LMBH_handle
	;
	; First ask the user if we should really alter the bitmap
	;
		clr	ax
		push	ax, ax			; SDOP_helpContext
		push	ax, ax			; SDOP_customTriggers
		push	ax, ax			; SDOP_stringArg2
		push	ax, ax			; SDOP_stringArg1
		mov	ax, handle ConfirmFormatChangeString
		push	ax
		mov	ax, offset ConfirmFormatChangeString
		push	ax			; SDOP_customString
		mov	ax, CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			    GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE
		push	ax			; SDOP_customFlags
		call	UserStandardDialogOptr

		pop	bp
		xchg	bp, bx
		call	MemDerefDS
		xchg	bp, bx

		cmp	ax, IC_YES
		je	makeTheChange
	;
	; The user chose to abort the change. Reset our UI
	;
		mov	ax, MSG_GEN_RESET
		mov	di, offset VisBitmapFormatControlClass
		GOTO	ObjCallSuperNoLock
	;
	; The user confirmed the change. Do so now.
	;
makeTheChange:
		mov	ax, MSG_VIS_BITMAP_SET_FORMAT_AND_RESOLUTION
		mov	bp, dx			; resolution also to BP
		mov	bx, segment VisBitmapClass
		mov	di, offset VisBitmapClass
		call	GenControlOutputActionRegs
		ret
VisBitmapFormatControlSetFormatNow	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapFormatControlEstimateBitmapSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Enables or disables the custom resolution GenValue

CALLED BY:	MSG_VBFC_ESTIMATE_BITMAP_SIZE

PASS:		*ds:si	= VisBitmapFormatControl object
		ds:di	= VisBitmapFormatControl instance
		cx	= Bitmap resolution (72, 300, or 0 (custom))

RETURN:		nothing

DESTROYED:	ax, bx, di

COMMENTS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	Feb 24, 1992 	Initial version.
	don	11-13-93	Added code to deal with missing
				controller features

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapFormatControlEstimateBitmapSize 	method dynamic	\
						VisBitmapFormatControlClass, \
						MSG_VBFC_ESTIMATE_BITMAP_SIZE
		.enter
	;
	; Enable or disable the custom resolution object
	;
		mov	ax, MSG_GEN_SET_ENABLED
		jcxz	setStatus
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setStatus:
		mov	dl, VUM_NOW
		mov	bx, mask VBFCF_CUSTOM_DPI
		mov	di, offset VisBitmapCustomResolutionValue
		call	SendMessageToChild

		.leave
		ret
VisBitmapFormatControlEstimateBitmapSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapFormatControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the bitmap format UI

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si	= VisBitmapFormatControl object
		ds:di 	= VisBitmapFormatControl instance
		ss:bp	= GenControlUpdateUIParams

RETURN:		nothing

DESTROYED:	ax, bx, di

COMMENTS:	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	Feb 24, 1992 	Initial version.
	don	11-13-93	Added code to deal with missing
				controller features

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapFormatControlUpdateUI	method dynamic VisBitmapFormatControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
		uses	cx, dx
		.enter
	;
	; First, reset the "Apply" trigger
	;
		push	bp
		mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
		mov	di, offset VisBitmapFormatControlClass
		call	ObjCallSuperNoLock
		pop	bp
	;
	; Determine which notification we've received. If it is an
	; object selection, then enable or disable all of the gadgetry
	; in this object & exit.
	;
		cmp	ss:[bp].GCUUIP_changeType, \
				GWNT_BITMAP_CURRENT_FORMAT_CHANGE
		je	newBitmapFormat
		mov	bx, ss:[bp].GCUUIP_dataBlock
		call	MemLock
		mov	es, ax
		mov	ax, MSG_GEN_SET_ENABLED	; assume a bitmap is selected
		test	es:[GONSSC_selectionState].GSS_flags, \
				mask GSSF_BITMAP_SELECTED
		jnz	setStatus
		mov	ax, MSG_GEN_SET_NOT_ENABLED
setStatus:
		push	ax
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	bx, mask VBFCF_MONO or \
			    mask VBFCF_4BIT or \
			    mask VBFCF_8BIT
		mov	di, offset VisBitmapFormatItemGroup
		call	SendMessageToChild

		pop	ax
		mov	bx, mask VBFCF_72_DPI or \
			    mask VBFCF_300_DPI or \
			    mask VBFCF_CUSTOM_DPI
		mov	di, offset VisBitmapResolutionInteraction
		call	SendMessageToChild
		jmp	done
	;
	; A new bitmap has been selected. Store the format & resolution,
	; for later use.
	;
newBitmapFormat:
		mov	ax, TEMP_VIS_BITMAP_FORMAT_INSTANCE
		mov	cx, size TempVisBitmapFormatInstance
		call	ObjVarAddData
		mov	di, bx			; vardata => DS:DI
		mov	bx, ss:[bp].GCUUIP_dataBlock
		call	MemLock
		mov	es, ax
		mov	al, es:[VBNCF_format]
		mov	cx, es:[VBNCF_xdpi]
		mov	ds:[di].TVBFI_format, al
		mov	ds:[di].TVBFI_resolution, cx
		call	MemUnlock
		push	ax			;save BMFormat
	;
	; Initialize the custom resolution (if present)
	;
		push	bp
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp			; determinate
		mov	bx, mask VBFCF_CUSTOM_DPI
		mov	di, offset VisBitmapCustomResolutionValue
		call	SendMessageToChild		
		pop	bp
	;
	; Initialize the resolution UI (if present)
	;
		mov	ax, ss:[bp].GCUUIP_features
		cmp	cx, 72			;is the resolution 72 DPI?
		jne	check300
		test	ax, mask VBFCF_72_DPI	;is 72 DPI in the list?
		jnz	haveResolution
check300:
		cmp	cx, 300			;is the resolution 300 DPI?
		jne	customResolution
		test	ax, mask VBFCF_300_DPI	;is 300 in the list?
		jnz	haveResolution
customResolution:
		clr	cx			;it's custom
haveResolution:
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			;determinate
		mov	bx, mask VBFCF_72_DPI or \
			    mask VBFCF_300_DPI or \
			    mask VBFCF_CUSTOM_DPI
		mov	di, offset VisBitmapResolutionItemGroup
		call	SendMessageToChild
	;
	; Set the custom resolution enabled or disabled
	;
		mov	ax, MSG_VBFC_ESTIMATE_BITMAP_SIZE
		call	ObjCallInstanceNoLock
	;
	; Initialize the format UI
	;
		pop	cx			;restore format
		clr	ch			;make format a word
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	dx			;determinate
		mov	bx, mask VBFCF_MONO or \
			    mask VBFCF_4BIT
		mov	di, offset VisBitmapFormatItemGroup	
		call	SendMessageToChild
done:
		.leave
		ret
VisBitmapFormatControlUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetChildBlockAndFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the child block & features for this controller

CALLED BY:	INTERNAL

PASS:		*ds:si	= VisBitmapFormatControl object

RETURN:		ax	= VBFCFeatures
		bx	= handle of child block (may be 0)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetChildBlockAndFeatures	proc	near
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData
		mov	ax, ds:[bx].TGCI_features
		mov	bx, ds:[bx].TGCI_childBlock
		ret
GetChildBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMessageToChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to a child of the controller

CALLED BY:	INTERNAL

PASS:		*ds:si	= VisBitmapFormatControl object
		ax	= message
		bx	= VBFCFeature that must be present
		cx,dx,bp= message data
		di	= chunk handle of child object

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendMessageToChild		proc	near
		uses	si
		.enter

		; Send the message to the child, if it is present
		;
		push	ax, di			; save message, object
		mov	di, bx			; feature(s) => DI
		call	GetChildBlockAndFeatures
		and	ax, di			; any features set?
		pop	ax, si			; restore message, object
		jz	done
		tst	bx
		jz	done
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
SendMessageToChild		endp

ObjMessage_near_call_save_bp	proc	near
		push	bp
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		pop	bp
		ret
ObjMessage_near_call_save_bp	endp

VisBitmapUIControllerCode	ends
