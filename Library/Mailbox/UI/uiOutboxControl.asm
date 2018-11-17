COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		uiOutboxControl.asm

AUTHOR:		Adam de Boor, Mar 22, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/22/95		Initial revision


DESCRIPTION:
	Implementation of the MailboxOutboxControlClass
		

	$Id: uiOutboxControl.asm,v 1.1 97/04/05 01:19:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MailboxClassStructures	segment	resource

	MailboxOutboxControlClass

MailboxClassStructures	ends

OutboxUICode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCGenControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the GenControlbuildInfo for this controller

CALLED BY:	MSG_GEN_CONTROL_GET_INFO
PASS:		*ds:si	= MailboxOutboxControl object
		ds:di	= MailboxOutboxControlInstance
		cx:dx	= GenControlBuildInfo buffer
RETURN:		GenControlBuildInfo buffer filled in
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCGenControlGetInfo method dynamic MailboxOutboxControlClass, 
				MSG_GEN_CONTROL_GET_INFO
		.enter
	;
	; Copy the information from our structure to the buffer
	;
		push	ds, si
		movdw	esdi, cxdx
		segmov	ds, cs
		mov	si, offset MOCBuildInfo
	CheckHack <(size MOCBuildInfo and 1) eq 0>
		mov	cx, size MOCBuildInfo / 2
		rep	movsw
		pop	ds, si
		.leave
		ret
MOCGenControlGetInfo endm

FEATURES	= mask MOCFeatures

MOCBuildInfo	GenControlBuildInfo <
		mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,
		MOC_iniKey,			; GCBI_initFileKey
		0,				; GCBI_gcnList
		0,				; GCBI_gcnCount
		0,				; GCBI_notificationList
		0,				; GCBI_notificationCount
		MOCName,			; GCBI_controllerName

		handle OutboxControlUI,		; GCBI_dupBlock
		MOC_childList,			; GCBI_childList
		length MOC_childList,		; GCBI_childCount
		MOC_featuresList,		; GCBI_featuresList
		length MOC_featuresList,	; GCBI_featuresCount
		FEATURES,			; GCBI_features

		0,				; GCBI_toolBlock
		0,				; GCBI_toolList
		0,				; GCBI_toolCount
		0,				; GCBI_toolFeaturesList
		0,				; GCBI_toolFeaturesCount
		MOC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
		0,				; GCBI_helpContext
		0>				; GCBI_reserved

if _FXIP
ControlInfoXIP	segment	resource
endif

MOC_iniKey		char	"mailboxOutboxControl", 0

FIRST_CHILD	equ	<<offset MOCMessageList, 0, mask GCCF_ALWAYS_ADD>>

MOC_childList		GenControlChildInfo \
			FIRST_CHILD,
			<offset MOCCancelTrigger,
			     mask MOCF_STOP_SENDING,
			     mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset MOCSendTrigger,
			     mask MOCF_START_SENDING,
			     mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset MOCDeleteTrigger,
			     mask MOCF_DELETE_MESSAGE,
			     mask GCCF_IS_DIRECTLY_A_FEATURE>

MOC_featuresList	GenControlFeaturesInfo \
			<offset MOCSendTrigger, MOCSendName, 0>,
			<offset MOCCancelTrigger, MOCCancelName, 0>,
			<offset MOCDeleteTrigger, MOCDeleteName, 0>

if _FXIP
ControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCGenControlAddToGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add ourselves to the requisite GCN lists.

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= MailboxOutboxControl object
		ds:di	= MailboxOutboxControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	added to MGCNLT_OUTBOX_CHANGE gcn list on the mailbox app

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCGenControlAddToGcnLists method dynamic MailboxOutboxControlClass, 
				MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		uses	ax
		.enter
		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilAddToMailboxGCNList
		.leave
		mov	di, offset MailboxOutboxControlClass
		GOTO	ObjCallSuperNoLock
MOCGenControlAddToGcnLists endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCGenControlRemoveFromGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add ourselves to the requisite GCN lists.

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= MailboxOutboxControl object
		ds:di	= MailboxOutboxControlInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	added to MGCNLT_OUTBOX_CHANGE gcn list on the mailbox app

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCGenControlRemoveFromGcnLists method dynamic MailboxOutboxControlClass, 
				MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		uses	ax
		.enter
		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilRemoveFromMailboxGCNList

		mov	ax, MSG_ML_RELEASE_MESSAGES
		mov	bx, offset MOCMessageList
		call	MOCCallChild

		.leave
		mov	di, offset MailboxOutboxControlClass
		GOTO	ObjCallSuperNoLock
MOCGenControlRemoveFromGcnLists endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCGenControlTweakDuplicatedUi
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the message list to rescan initially.

CALLED BY:	MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
PASS:		*ds:si	= MailboxOutboxControl object
		ds:di	= MailboxOutboxControlInstance
		^hcx	= duplicated ui block
		dx	= features mask
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCGenControlTweakDuplicatedUi method dynamic MailboxOutboxControlClass, 
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
		.enter
	;
	; Queue a rescan so the thing gets build once we've stored our child
	; block handle, etc.
	;
		mov	bx, cx
		mov	si, offset MOCMessageList
		mov	ax, MSG_ML_RESCAN
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
MOCGenControlTweakDuplicatedUi endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCMbNotifyBoxChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the message list

CALLED BY:	MSG_MB_NOTIFY_BOX_CHANGE
PASS:		*ds:si	= MailboxOutboxControl object
		ds:di	= MailboxOutboxControlInstance
		cxdx	= MailboxMessage affected
		bp	= MABoxChange
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCMbNotifyBoxChange method dynamic MailboxOutboxControlClass, 
					MSG_MB_NOTIFY_BOX_CHANGE
		.enter

		call	MOCCheckPendingNotification	; CF set if found
		adc	dx, 0		; set bit 0 if CF set

		mov	bx, offset MOCMessageList
		mov	ax, MSG_ML_UPDATE_LIST
		call	MOCCallChild
		.leave
		ret
MOCMbNotifyBoxChange endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCCheckPendingNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if there are pending notification for the outbox control
		opject in the event queue.

CALLED BY:	
PASS:		*ds:si	= MailboxOutboxControl object
		ax	= MSG_MB_NOTIFY_BOX_CHANGE
RETURN:		carry set if notification found in event queue
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	4/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCCheckPendingNotification	proc	near
	uses	cx
	.enter

	mov	bx, offset matchCallback
	pushdw	csbx
	mov	bx, ds:[OLMBH_header].LMBH_handle
	clr	cx		; assume no match
	mov	di, mask MF_FORCE_QUEUE or mask MF_DISCARD_IF_NO_MATCH \
			or mask MF_CHECK_DUPLICATE or mask MF_CUSTOM
	call	ObjMessage

	shr	cx		; carry set if cx was 1

	.leave
	ret


matchCallback	label	far
;	Pass:	ax	= MSG_MB_NOTIFY_BOX_CHANGE
;		ds:bx	= HandleEvent
;		cx	= 0
;	Return:	di	= PROC_SE_EXIT / PROC_SE_CONTINUE
;		cx	= 0 if PROC_SE_CONTINUT (not match)
;			  1 if PROC_SE_EXIT (match)

		CheckHack <PROC_SE_CONTINUE eq 0>
	clr	di		; di = PROC_SE_CONTINUE, assume no match
	cmp	ds:[bx].HE_method, ax
	jne	done
	mov	di, PROC_SE_EXIT
	inc	cx

done:
	retf

MOCCheckPendingNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCEnableFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/disable features based on passed mask

CALLED BY:	MSG_MAILBOX_OUTBOX_CONTROL_ENABLE_FEATURES
PASS:		*ds:si	= MailboxOutboxControl object
		ds:di	= MailboxOutboxControlInstance
		cx	= MOCFeatures to be enabled
		dx	= MOCToolboxFeatures to be enabled
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We don't do anything toolwise, so ignore that parameter for now

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCEnableFeatures method dynamic MailboxOutboxControlClass, 
				MSG_MAILBOX_OUTBOX_CONTROL_ENABLE_FEATURES
		.enter
	;
	; Get the current set of normal features so we know which things to
	; tweak.
	;
		push	cx
		mov	ax, MSG_GEN_CONTROL_GET_NORMAL_FEATURES
		call	ObjCallInstanceNoLock
		pop	cx
	;
	; Now form masks of the features that are set that are to be enabled
	; (in CX) and of features that are set that are to be disabled (in DX)
	;
		mov	dx, cx
		not	dx
		and	cx, ax			; cx <- features to enable
		and	dx, ax			; dx <- features to disable
	;
	; Disable Those That Are To Be Disabled
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	processFeatures
	;
	; Enable Those That Are To Be Enabled
	;
		mov	dx, cx
		mov	ax, MSG_GEN_SET_ENABLED
		call	processFeatures
		.leave
		ret

	;--------------------
	; Send a message to the children indicated by the passed feature bits.
	;
	; Pass:
	; 	*ds:si	= MailboxOutboxControl
	; 	cx	= MOCFeatures mask indicating children to be called
	; 	ax	= MSG_GEN_SET_ENABLED/MSG_GEN_SET_NOT_ENABLED
	; Return:
	; 	nothing
	; Destroyed:
	; 	bx, bp, di
mocFeatureList	word	MOCSendTrigger, MOCCancelTrigger, MOCDeleteTrigger

processFeatures:
		push	cx
		mov	di, offset mocFeatureList
		mov	cx, length mocFeatureList
featureLoop:
		test	dx, 1
		jz	nextFeature

		mov	bx, cs:[di]
		push	di, dx, cx, ax
		mov	dl, VUM_NOW
		call	MOCCallChild
		pop	di, dx, cx, ax
nextFeature:
		add	di, type mocFeatureList
		shr	dx
		loop	featureLoop
		pop	cx
		retn
		
MOCEnableFeatures endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MOCCallChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a method in one of our child objects.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= MailboxOutboxControl
		bx	= chunk of child to call
		ax	= message to send it
		cx, dx, bp = data for message
RETURN:		ax, cx, dx, bp, flags = return values
DESTROYED:	bx, di
SIDE EFFECTS:	?

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MOCCallChild	proc	near
		class	MailboxOutboxControlClass
		uses	si
		.enter
		push	ax, bx
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData
EC <		ERROR_NC	CHILDREN_NOT_BUILT_YET			>
		mov	bx, ds:[bx].TGCI_childBlock
		pop	ax, si
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		ret
MOCCallChild	endp

OutboxUICode	ends

; Local Variables:
; messages-use-class-abbreviation: nil
; End:
