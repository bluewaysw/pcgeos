COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) MyTurn.com 2000.  All rights reserved.
	MYTURN.COM CONFIDENTIAL

PROJECT:	GlobalPC
MODULE:		Internet Dialup Shortcut
FILE:		idialControl.asm

AUTHOR:		David Hunter, Oct 15, 2000

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/15/00   	Initial revision


DESCRIPTION:
		
	This library defines and implements an additional trigger for
	an application's titlebar that allows the user to rapidly
	disconnect the current PPP session, or alternatively launch
	the IDialup application.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
GSTRING_TEMPLATE_DOESNT_HAVE_GR_SET_TEXT_ATTR_FIRST	enum	FatalErrors
endif

idata	segment
	IDialControlClass
	IDialTriggerClass
idata	ends

IDialControlCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide information about the controller

CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si	= IDialControlClass object
		ds:di	= IDialControlClass instance data
		ds:bx	= IDialControlClass object (same as *ds:si)
		es 	= segment of IDialControlClass
		ax	= message #
		cx:dx	= GenControlDupInfo structure to fill in

RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Copy the default info
	Remove the trigger feature in the AUI

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/15/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialControlGetInfo	method dynamic IDialControlClass, 
					MSG_GEN_CONTROL_GET_INFO
		mov	si, offset IDC_dupInfo
		mov	es, cx
		mov	di, dx				;es:di = dest
		segmov	ds, cs
		copybuf	GenControlBuildInfo
	;
	; If in the AUI, remove the trigger feature.
	;
		call	UserGetDefaultUILevel		; ax = level
		cmp	ax,  UIIL_INTRODUCTORY
		je	done				; branch if CUI
		mov	di, dx
		mov	es:[di].GCBI_features, IDIAL_DEFAULT_FEATURES and \
			not mask IDCF_TRIGGER
done:
		ret
IDialControlGetInfo	endp

IDC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
	0,				; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	0,				; GCBI_controllerName

	handle IDialControlUI,		; GCBI_dupBlock
	IDC_childList,			; GCBI_childList
	length IDC_childList,		; GCBI_childCount
	IDC_featuresList,		; GCBI_featuresList
	length IDC_featuresList,	; GCBI_featuresCount
	IDIAL_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0				; GCBI_toolFeatures
>

IDC_childList	GenControlChildInfo	\
	<offset IDTrigger, mask IDCF_TRIGGER, mask GCCF_IS_DIRECTLY_A_FEATURE>

IDC_featuresList	GenControlFeaturesInfo	\
	<offset IDTrigger, 0, 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept to do special things.

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI

PASS:		*ds:si	= IDialControlClass object
		ds:di	= IDialControlClass instance data
		ds:bx	= IDialControlClass object (same as *ds:si)
		es 	= segment of IDialControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Give ourselves HINT_CUSTOM_EXTRA_MARGINS and HINT_SEEK_TITLE_BAR_RIGHT
	Set the trigger to a default state.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialControlGenerateUI	method dynamic IDialControlClass, 
					MSG_GEN_CONTROL_GENERATE_UI
		uses	ax, cx, dx, bp
		.enter

		mov	di, offset IDialControlClass
		call	ObjCallSuperNoLock
	;
	; Return if the trigger feature is off.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData			; ds:bx = vardata
		test	ds:[bx].TGCI_features, mask IDCF_TRIGGER
		jz	done
	;
	; Give the trigger some extra space between itself and the other
	; triggers in the titlebar.  This is done before HINT_SEEK_TITLE_BAR
	; is set to sneak this change into the visual update.
	;
		mov	ax, HINT_CUSTOM_EXTRA_MARGINS
		mov	cx, size Rectangle
		call	ObjVarAddData			; ds:bx = Rectangle
		clr	ax
		mov	ds:[bx].R_left, ax
		mov	ds:[bx].R_top, ax
		mov	ds:[bx].R_right, CONTROLLER_CUSTOM_SPACING
		mov	ds:[bx].R_bottom, ax
	;
	; The trigger won't appear in the titlebar unless we, the generic
	; parent, have the appropriate hint.  Rather than asking the
	; client application to set it, we set it ourselves.  Nice!
	;
		mov	ax, MSG_GEN_ADD_GEOMETRY_HINT
		mov	dl, VUM_NOW
		mov	cx, HINT_SEEK_TITLE_BAR_RIGHT
		call	ObjCallInstanceNoLock

	;
	; Set the trigger to a default state.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData			; ds:bx = vardata
		mov	ax, MSG_IDIAL_TRIGGER_SET_STATE
		mov	bx, ds:[bx].TGCI_childBlock
		mov	si, offset IDTrigger
		clr	cx				; state = offline
		clr	di
		call	ObjMessage
done:
		.leave
		ret
IDialControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialControlNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass GWNT_PPP_STATUS_NOTIFICATION on to the trigger.

CALLED BY:	MSG_META_NOTIFY

PASS:		*ds:si	= IDialControlClass object
		ds:di	= IDialControlClass instance data
		ds:bx	= IDialControlClass object (same as *ds:si)
		es 	= segment of IDialControlClass
		ax	= message #
		cx:dx	= NotificationType (cx = NT_manuf, dx = NT_type)
		bp	= change specific data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialControlNotify	method dynamic IDialControlClass, 
					MSG_META_NOTIFY
	;
	; We're only interested in GWNT_PPP_STATUS_NOTIFICATION.
	;
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	done
		cmp	dx, GWNT_PPP_STATUS_NOTIFICATION
		jne	done
	;
	; Find the trigger and send it the notify.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData			; ds:bx = vardata
		jnc	done
		test	ds:[bx].TGCI_features, mask IDCF_TRIGGER
		jz	done
		mov	ax, MSG_IDIAL_TRIGGER_NOTIFY
		mov	bx, ds:[bx].TGCI_childBlock
		mov	si, offset IDTrigger
		clr	di
		call	ObjMessage
done:		
		ret
IDialControlNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialControlAddToGCNLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept to add/remove ourselves to special GCN list

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS

PASS:		*ds:si	= IDialControlClass object
		ds:di	= IDialControlClass instance data
		ds:bx	= IDialControlClass object (same as *ds:si)
		es 	= segment of IDialControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Don't optimize by not adding/removing to GCN list if the
		trigger feature isn't set, because we could get
		REMOVE_FROM_GCN_LISTS after the feature list has been
		cleared.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialControlGCNLists	method dynamic IDialControlClass, 
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS,
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		mov	bp, ax				; bp = msg
		mov	cx, ds:[LMBH_handle]
		mov	dx, si				; cx:dx = oself
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_PPP_STATUS_NOTIFICATIONS
		cmp	bp, MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		jne	remove
		call	GCNListAdd
		jmp	done
remove:
		call	GCNListRemove
	;
	; With us removed from the GCN list, the trigger will never stop
	; flashing if it was disconnecting, so we must tell it ourselves.
	; Also, since this message always preceeds the freeing of our
	; child block, it would be a good idea to stop said flashing,
	; lest a timer event arrive for the trigger post partem.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarDerefData			; ds:bx = vardata
		mov	bx, ds:[bx].TGCI_childBlock
		tst	bx				; got child block?
		jz	done				; sorry, no can do
		mov	ax, MSG_IDIAL_TRIGGER_STOP_FLASHING
		mov	si, offset IDTrigger
		clr	di
		call	ObjMessage
done:
		ret
IDialControlGCNLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialControlDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept detach to ensure trigger cleans up

CALLED BY:	MSG_META_DETACH

PASS:		*ds:si	= IDialControlClass object
		ds:di	= IDialControlClass instance data
		ds:bx	= IDialControlClass object (same as *ds:si)
		es 	= segment of IDialControlClass
		ax	= message #
	 	cx 	= caller's ID
		dx:bp 	= callers' OD:  OD which will be sent a MSG_META_ACK
				when the object has finished detaching.

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	When detaching, the controller will optimize its demise (ooh!) by
	not bothering to nicely removing each child before freeing the
	entire child block.  We must intervene before the children vanish
	and stop the trigger from flashing, as the system will die if it
	gets a timer event for the trigger post partem and the process is
	still around.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialControlDetach	method dynamic IDialControlClass, 
					MSG_META_DETACH
	;
	; Make the trigger stop flashing to ensure the flash timer is killed.
	;
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData			; ds:bx = vardata
		jnc	callSuper		; skip if no vardata
		test	ds:[bx].TGCI_features, mask IDCF_TRIGGER
		jz	callSuper		; branch if no trigger
		push	si
		mov	ax, MSG_IDIAL_TRIGGER_STOP_FLASHING
		mov	bx, ds:[bx].TGCI_childBlock	; ^hbx = child block
		mov	si, offset IDTrigger	; ^lbx:si = trigger
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
callSuper:
		mov	ax, MSG_META_DETACH
		mov	di, offset IDialControlClass
		call	ObjCallSuperNoLock	; do super stuff

		ret
IDialControlDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialControlAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set kerning values for each of our trigger monikers.

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si	= IDialControlClass object
		ds:di	= IDialControlClass instance data
		ds:bx	= IDialControlClass object (same as *ds:si)
		es 	= segment of IDialControlClass
		ax	= message #
RETURN:		nuthin'
DESTROYED:	nuthin'
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	11/29/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialControlAttach	method dynamic IDialControlClass, 
					MSG_META_ATTACH
	uses	ax, cx, dx, bp
	.enter
	;
	; do the CONNECT button
	;
	mov	bx, handle CUIMonikers
	mov	ax, offset CUIConnectC8Moniker
	mov	dx, offset connectTextKerning
	call	SetMonikerCharacterKerning	; dx <- character kerning value
	push	ds
	segmov	ds, dgroup, cx

	;
	; do the DISCONNECT button
	;
	mov	ax, offset CUIDisconnectC8Moniker
	mov	dx, offset disconnectTextKerning
	call	SetMonikerCharacterKerning
	pop	ds
	mov	ax, MSG_META_ATTACH
	mov	di, offset IDialControlClass
	call	ObjCallSuperNoLock	; do super stuff
	.leave
	ret
IDialControlAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMonikerCharacterKerning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the TA_trackKern for the GR_SET_TEXT_ATTR opcode,
		which should appear first in the GString of the
		specified moniker.

CALLED BY:	BuildCUIButtonMoniker
PASS:		^lbx:ax	<- moniker optr
		dx - chunk handle of ASCII kerning value	
RETURN:		dx - character kerning value
DESTROYED:	nuthin'
SIDE EFFECTS:	nuthin'

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	11/28/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMonikerCharacterKerning	proc	near
	uses	ds, di, ax
	.enter
	push	ax
	call	MemLock
	mov	ds, ax

	;
	; convert ASCII kerning value to numeric
	;
	mov	di, dx
	mov	di, ds:[di]		; ds:di <- addr of kerning chunk
	call	LocalAsciiToFixed	; dx:ax <- kerning value, dx with int.
	pop	di
	mov	di, ds:[di]		; ds:si <- addr of chunk
.warn -field
EC <	cmp	ds:[di].VM_data.VMGS_gstring.OSTA_opcode, GR_SET_TEXT_ATTR >
EC <	ERROR_NE GSTRING_TEMPLATE_DOESNT_HAVE_GR_SET_TEXT_ATTR_FIRST >
	mov	ds:[di].VM_data.VMGS_gstring.OSTA_attr.TA_trackKern, dx
.warn +field
	call	MemUnlock
	.leave
	ret
SetMonikerCharacterKerning	endp

IDialControlCode	ends

IDialTriggerCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the difference between the two text chunks that
		will comprise the moniker for the trigger, and adjust the
		size to accomidate the largest one.

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
		ds:bx	= IDialTriggerClass object (same as *ds:si)
		es 	= segment of IDialTriggerClass
		ax	= message #
		cx	= RecalcSizeArgs -- suggested width for object
		dx	= RecalcSizeArgs -- suggested height
		
RETURN:		cx	= width to use
		dx	= height to use
DESTROYED:	nuthin'
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	11/29/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerRecalcSize	method dynamic IDialTriggerClass, 
					MSG_VIS_RECALC_SIZE
defaultHeight		local	word	
connectWidth		local	word
disconnectWidth		local	word
	.enter
	;
	; call super to get the default height
	;
	mov	di, offset IDialTriggerClass
	push	bp
	call	ObjCallSuperNoLock
	pop	bp

	;
	; save the default height
	;
	mov	ss:[defaultHeight], dx

	;
	; Create a GState to run GrGetTextBounds on.
	;
	push	bp
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; bp <- gstate handle	
	mov	di, bp
	pop	bp
	jc	haveGState

	clr	di
	call	GrCreateState	; di <- handle of GState

haveGState:
	;
	; Set the font and text style from the CONNECT GString
	;
	mov	bx, handle CUIMonikers
	call	MemLock		; ax <- seg addr.
	mov	ds, ax
	mov	si, offset CUIConnectC8Moniker
	mov	si, ds:[si]
.warn -field
	lea	si, ds:[si].VM_data.VMGS_gstring.OSTA_attr	; ds:si <- source
.warn +field
EC <	cmp	{byte}ds:[si-1], GR_SET_TEXT_ATTR >
EC <	ERROR_NE GSTRING_TEMPLATE_DOESNT_HAVE_GR_SET_TEXT_ATTR_FIRST >	
	call	GrSetTextAttr

	;
	; Calculate and save for "CONNECT" string
	;
	mov	si, offset connectText
	mov	si, ds:[si]
	clr	ax, bx			; we'll draw at 0, 0
	call	GrGetTextBounds		; ax = left bound
					; bx = top bound
					; cx = right bound
					; dx = bottom bound
	sub	cx, ax			; cx <- width
	inc	cx			; +1 for shadow
	mov	ss:[connectWidth], cx

	;
	; Set the font and text style from the DISCONNECT GString
	;
	mov	si, offset CUIDisconnectC8Moniker
	mov	si, ds:[si]
.warn -field
	lea	si, ds:[si].VM_data.VMGS_gstring.OSTA_attr	; ds:si <- source
.warn +field
EC <	cmp	{byte}ds:[si-1], GR_SET_TEXT_ATTR >
EC <	ERROR_NE GSTRING_TEMPLATE_DOESNT_HAVE_GR_SET_TEXT_ATTR_FIRST >	
	call	GrSetTextAttr

	;
	; Calculate and save for "DISCONNECT" string
	;
	mov	si, offset disconnectText
	mov	si, ds:[si]
	clr	ax, bx
	call	GrGetTextBounds
	sub	cx, ax
	inc	cx
	mov	ss:[disconnectWidth], cx

	;
	; Set the size of the trigger to the largest one.
	;
	mov	cx, ss:[disconnectWidth]
	cmp	cx, ss:[connectWidth]
	ja	destroyState

	;
	; "CONNECT" is the one, or they're both the same. . .
	;
	mov	cx, ss:[connectWidth]

destroyState:
	;
	; Destroy our GState
	;	
	call	GrDestroyState

	;
	; Clean up
	;
	mov	bx, handle CUIMonikers
	call	MemUnlock

	;
	; Add some padding to the width
	;
	add	cx, 6
	mov	dx, ss:[defaultHeight]	; return the default height
	.leave
	ret
IDialTriggerRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerGoOffline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the transition from online to offline.

CALLED BY:	MSG_IDIAL_TRIGGER_GO_OFFLINE

PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
		ds:bx	= IDialTriggerClass object (same as *ds:si)
		es 	= segment of IDialTriggerClass
		ax	= message #
		cx:dx	= the trigger

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/15/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerGoOffline	method dynamic IDialTriggerClass, 
					MSG_IDIAL_TRIGGER_GO_OFFLINE
	;
	; Skip this if we've already initiated the disconnect, as indicated
	; by the presence of the temporary vardata we create below.
	;
		mov	ax, TEMP_IDIAL_TRIGGER_FLASH
		call	ObjVarFindData			; carry set if found
	LONG	jc	done
	;
	; Skip the moniker business if we're not usable.
	;
		test	ds:[di].GI_states, mask GS_USABLE
		jz	disconnect
	;
	; Decide which flash moniker list to use, depending on the default
	; UI level.
	;
		mov	bx, handle CUIFlashMonikers
		mov	di, offset CUIFlashMonikers	; bx:di = list
		call	UserGetDefaultUILevel		; ax = level
		cmp	ax, UIIL_INTRODUCTORY
		je	gotList				; branch if CUI
		mov	bx, handle AUIFlashMonikers
		mov	di, offset AUIFlashMonikers	; bx:di = list
	;
	; Decide which moniker in the list to use, depending on the system
	; display mode.  Copy that moniker to our block.
	;
gotList:
		mov	cx, ds:[LMBH_handle]		; cx = dest block
		push	cx				; save handle
		push	si				; save si
		call	MemLock				; ax = list block seg
		mov	ds, ax				; *ds:di = VisMonikerList
		call	UserGetDisplayType		; ah = DisplayType
		mov	bh, ah				; bh = DisplayType
		mov	bp, VMS_ICON shl offset VMSF_STYLE \
			or mask VMSF_COPY_CHUNK or mask VMSF_GSTRING
		call	VisFindMoniker			; cx:dx = copied moniker
		mov	bx, ds:[LMBH_handle]		; bx = list block
		call	MemUnlock
		pop	si				; restore si
		pop	bx				; bx = obj block
		call	MemDerefDS			; *ds:si = oself
	;
	; Create the temporary vardata to hold stuff.  Fill it in with our
	; new flash moniker and a new timer.
	;
		mov	ax, TEMP_IDIAL_TRIGGER_FLASH
		mov	cx, size IDialTriggerFlashStruct
		call	ObjVarAddData			; ds:bx = vardata
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset		; ds:di = instance data
		mov	ds:[bx].IDTFS_moniker, dx	; save flash moniker
		mov	ax, ds:[di].GI_visMoniker	; ax = current moniker
		mov	ds:[bx].IDTFS_oldMoniker, ax	; save it too
		push	bx				; save vardata offset
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:[LMBH_handle]		; bx:si = timer OD
		mov	di, FLASH_DELAY			; di = timer interval
		mov	dx, MSG_IDIAL_TRIGGER_FLASH	; dx = msg
		clr	cx				; cx = timer delay
		call	TimerStart			; bx = timer handle,
							; ax = timer ID
		pop	si				; si = vardata
		mov	ds:[si].IDTFS_timer, bx		; save timer data
		mov	ds:[si].IDTFS_timerID, ax
	;
	; Start the disconnect procedure on another thread.
	;
disconnect:
		mov	al, PRIORITY_UI
		mov	cx, vsegment CloseMedium
		mov	dx, offset CloseMedium		; cx:dx = thread routine
		mov	di, DISCONNECT_THREAD_STACK_SIZE
		call	GeodeGetProcessHandle		; bx = caller's handle
		mov	bp, bx				; bp = caller's handle
		call	ThreadCreate
done:
		ret
IDialTriggerGoOffline	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerGoOnline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the transition from offline to online.

CALLED BY:	MSG_IDIAL_TRIGGER_GO_ONLINE

PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
		ds:bx	= IDialTriggerClass object (same as *ds:si)
		es 	= segment of IDialTriggerClass
		ax	= message #
		cx:dx	= the trigger

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/15/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerGoOnline	method dynamic IDialTriggerClass, 
					MSG_IDIAL_TRIGGER_GO_ONLINE
	;
	; Start the application busy state.
	;
		clr	bx				; current process
		call	GeodeGetAppObject		; *bx:si = app obj
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Launch the internet dialup application.
	;
		call	LaunchIDial
	;
	; End the application busy state.
	;
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		call	ObjMessage
		
		ret
IDialTriggerGoOnline	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LaunchIDial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Launch the IDialup application.

CALLED BY:	IDialTriggerGoOnline
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Call IACPConnect
	Call IACPShutdown if no problems

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/15/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialToken	GeodeToken	< "IDIA", MANUFACTURER_ID_GEOWORKS >

LaunchIDial	proc	near
		uses	bx, si, di
		.enter

		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock	; ^hdx = AppLaunchBlock
		segmov	es, cs, ax
		mov	di, offset IDialToken
		mov	ax, mask IACPCF_FIRST_ONLY or \
			IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE
		mov	bx, dx				; ^hbx = AppLaunchBlock
		call	IACPConnect			; bp = IACPConnection (\CF)
							; ax = IACPConnectError (CF)
		jc	done				; branch on error
		clr	cx				; cx = 0 (client)
		call	IACPShutdown
done:
		.leave
		ret
LaunchIDial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the medium of the TCPIP domain (disconnect PPP)

CALLED BY:	Thread created by LaunchIDial
PASS:		nothing interesting
RETURN:		nothing
DESTROYED:	anything
SIDE EFFECTS:	PPP will tell us PPP_STATUS_CLOSED after disconnecting

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCPDomain	TCHAR	"TCPIP", 0

CloseMedium	proc	near
		sa	local	SocketAddress
		xa	local	TcpAccPntResolvedAddress
		mau	local	MediumAndUnit
		.enter

		mov	ss:[sa].SA_port.SP_port, 80
		mov	ss:[sa].SA_port.SP_manuf, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	ss:[sa].SA_domainSize, size TCPDomain
		segmov	ss:[sa].SA_domain.segment, cs, ax
		mov	ss:[sa].SA_domain.offset, offset TCPDomain
		mov	ss:[sa].SA_addressSize, size xa
		mov	ss:[xa].TAPRA_linkSize, 3
		mov	ss:[xa].TAPRA_linkType, LT_ID
		mov	ss:[xa].TAPRA_accPntID, 1

		segmov	ds, ss, ax
		lea	di, ss:[sa]			; ds:di = SocketAddress
		push	bp				; save frame ptr
		call	SocketGetAddressMedium
		mov	ax, bp				; ax = MediumUnit
		pop	bp				; restore frame ptr
		jc	done
		movdw	ss:[mau].MU_medium, cxdx
		mov	ss:[mau].MU_unitType, bl
		mov	ss:[mau].MU_unit, ax
		mov	dx, ds
		lea	bx, ss:[mau]			; dx:bx = MediumAndUnit
		segmov	ds, cs, ax
		mov	si, offset TCPDomain
		call	SocketCloseDomainMedium
done:
		.leave
		clrdw	dxbp
		jmp	ThreadDestroy
CloseMedium	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the trigger's moniker to reflect the new state.

CALLED BY:	MSG_IDIAL_TRIGGER_NOTIFY

PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
		ds:bx	= IDialTriggerClass object (same as *ds:si)
		es 	= segment of IDialTriggerClass
		ax	= message #
		bp	= change specific data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If new status is opened or closed, and the trigger action message
	isn't correct, call SetTrigger to set the message and the moniker.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/15/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerNotify	method dynamic IDialTriggerClass, 
					MSG_IDIAL_TRIGGER_NOTIFY
	;
	; Only respond when the status goes fully opened or closed.
	;
		andnf	bp, PPPStatusBits
		cmp	bp, PPP_STATUS_CLOSED
		je	goodState
		cmp	bp, PPP_STATUS_OPEN
		jne	done
	;
	; Compare the new status to the trigger's current state.
	; (Just in case you're wondering, the next line is not a typo.
	; If the trigger is currently online, it's action will be to
	; go offline.)
	;
	; ax = trigger's current state is online
	; bx = new status is online
	;
goodState:
		mov	ax, BB_TRUE		; assume trigger is online
		cmp	ds:[di].GTI_actionMsg, MSG_IDIAL_TRIGGER_GO_OFFLINE
		je	gotOldOnline		; branch if correct
		mov	ax, BB_FALSE		; trigger currently offline
gotOldOnline:
		mov	bx, BB_TRUE		; assume new status online
		cmp	bp, PPP_STATUS_OPEN
		je	gotNewOnline		; branch if correct
		mov	bx, BB_FALSE		; new status offline
gotNewOnline:
		cmp	ax, bx			; Has there been a change?
		je	done			; branch if not
	;
	; If the trigger's still flashing, stop it.
	;
		mov	ax, MSG_IDIAL_TRIGGER_STOP_FLASHING
		call	ObjCallInstanceNoLock
	;
	; Set the trigger to the new state.
	;
		mov	ax, MSG_IDIAL_TRIGGER_SET_STATE
		mov	cx, bx			; cx = new state
		call	ObjCallInstanceNoLock
done:
		ret
IDialTriggerNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the trigger's visMoniker and action message.

CALLED BY:	MSG_IDIAL_TRIGGER_SET_STATE

PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
		ds:bx	= IDialTriggerClass object (same as *ds:si)
		es 	= segment of IDialTriggerClass
		ax	= message #
		cx	= new state: non-zero if online, zero if offline

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Choose the moniker list, trigger message, and focus help appropriate
	to the trigger state and the user interface level.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00   	Initial version
	dhunter 10/27/00	Added bubble help

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerSetState	method dynamic IDialTriggerClass, 
					MSG_IDIAL_TRIGGER_SET_STATE
	;
	; Choose the moniker list, trigger message, and focus help appropriate
	; to the trigger state and the user interface level.
	;
		mov	bp, offset FocusHelpOnline	; bp = help text
		mov	bx, cx				; bx = state
		call	UserGetDefaultUILevel		; ax = level
		cmp	ax, UIIL_INTRODUCTORY
		jne	AUI
		mov	cx, handle CUIOnlineMonikers	; assume online
		mov	dx, offset CUIOnlineMonikers	; cx:dx = moniker list
		tst	bx
		jnz	gotList				; branch if online
		mov	dx, offset CUIOfflineMonikers
		jmp	getHelp				; get offline help
AUI:
		mov	cx, handle AUIOnlineMonikers	; assume online
		mov	dx, offset AUIOnlineMonikers	; cx:dx = moniker list
		tst	bx
		jnz	gotList				; branch if online
		mov	dx, offset AUIOfflineMonikers
getHelp:
		mov	bp, offset FocusHelpOffline
gotList:
		mov	ax, MSG_IDIAL_TRIGGER_GO_OFFLINE	; assume online
		jnz	gotMsg
		mov	ax, MSG_IDIAL_TRIGGER_GO_ONLINE
gotMsg:
		mov	ds:[di].GTI_actionMsg, ax

		push	bp
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	bp, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock

		mov	ax, ATTR_GEN_FOCUS_HELP
		mov	cx, size optr
		call	ObjVarAddData			; ds:bx = vardata
		pop	ds:[bx].offset			; set offset
		mov	ds:[bx].handle, handle FocusHelpOnline	; and handle
		
		ret
IDialTriggerSetState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerFlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alternate the trigger's moniker to cause a flashing effect.

CALLED BY:	MSG_IDIAL_TRIGGER_FLASH

PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
		ds:bx	= IDialTriggerClass object (same as *ds:si)
		es 	= segment of IDialTriggerClass
		ax	= message #
		(may be some timer data, but who cares)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Exit if vardata not present
	Swap current VisMoniker with the one in vardata
	Invalidate our image so we get redrawn

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerFlash	method dynamic IDialTriggerClass, 
					MSG_IDIAL_TRIGGER_FLASH

		mov	ax, TEMP_IDIAL_TRIGGER_FLASH
		call	ObjVarFindData		; ds:bx = vardata
		jnc	done			; branch if not found
	;
	; Swap current VisMoniker with the one in vardata
	;
		mov	ax, ds:[di].GI_visMoniker	; ax = current
		xchg	ax, ds:[bx].IDTFS_moniker	; ax = new
		mov	ds:[di].GI_visMoniker, ax	; store it
	;
	; Invalidate our image so we get redrawn.
	;
		mov	ax, MSG_VIS_MARK_INVALID
		mov	cl, mask VOF_IMAGE_INVALID
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjCallInstanceNoLock
done:
		ret
IDialTriggerFlash	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerGenRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept message to assert the flash timer's demise

CALLED BY:	MSG_GEN_REMOVE

PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
		ds:bx	= IDialTriggerClass object (same as *ds:si)
		es 	= segment of IDialTriggerClass
		ax	= message #

RETURN:		whatever superclass returns
DESTROYED:	whatever superclass destroys
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerGenRemove	method dynamic IDialTriggerClass, 
					MSG_GEN_REMOVE
	;
	; If the trigger's still flashing, stop it.  This ensures no timer is
	; left running.
	;
		mov	ax, MSG_IDIAL_TRIGGER_STOP_FLASHING
		call	ObjCallInstanceNoLock
	;
	; Then call the superclass.
	;
		mov	ax, MSG_GEN_REMOVE
		mov	di, offset IDialTriggerClass
		call	ObjCallSuperNoLock

		ret
IDialTriggerGenRemove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IDialTriggerStopFlashing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the trigger's still flashing, stop it.

CALLED BY:	IDialTriggerNotify, IDialTrigerDetach
PASS:		*ds:si	= IDialTriggerClass object
		ds:di	= IDialTriggerClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	Exit if the vardata is not present.
	Stop the timer.
	Restore our VisMoniker to the original moniker.
	Delete the flash moniker.
	Delete the vardata.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/16/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IDialTriggerStopFlashing	method dynamic IDialTriggerClass,
					MSG_IDIAL_TRIGGER_STOP_FLASHING
		uses	ax,cx,dx,bp
		.enter
	;
	; Exit if the vardata is not present.
	;
		mov	ax, TEMP_IDIAL_TRIGGER_FLASH
		call	ObjVarFindData		; ds:bx = vardata
		jnc	done			; branch if not found
	;
	; Stop the timer.
	;
		mov_tr	bp, bx			; ds:bp = vardata
		mov	bx, ds:[bp].IDTFS_timer
		mov	ax, ds:[bp].IDTFS_timerID
		call	TimerStop
	;
	; Restore our visMoniker to the original moniker if necessary,
	; setting ax to the handle of the flash moniker.
	;
		mov	dx, ds:[di].GI_visMoniker
		mov	ax, ds:[bp].IDTFS_moniker
		mov	cx, ds:[bp].IDTFS_oldMoniker
		cmp	dx, cx			; if dx = cx, then branch since
		je	delete			;  GI_visMoniker is okay
		mov	ax, dx			; dx = flash moniker
		mov	ds:[di].GI_visMoniker, cx ; restore old moniker
delete:
	;
	; Delete the flash moniker in ax.
	;
		call	ObjFreeChunk
	;
	; Delete the vardata.
	;
		mov	ax, TEMP_IDIAL_TRIGGER_FLASH
		call	ObjVarDeleteData
done:
		.leave
		ret
IDialTriggerStopFlashing	endp

IDialTriggerCode	ends
