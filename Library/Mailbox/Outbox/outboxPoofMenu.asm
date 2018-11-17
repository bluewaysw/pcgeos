COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxPoofMenu.asm

AUTHOR:		Allen Yuen, Oct 13, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT OPMCreateKids		Create one child for each system message
				type, as determined by all transport
				capabilities.

    INT OPMCreateChild		Build one Poof menu item with the passed
				moniker.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/13/94   	Initial revision


DESCRIPTION:
	Implementation of the OutboxPoofMenu class, an interaction that gives
	itself one GenTrigger for each supported system message type from
	all available transports.

	$Id: outboxPoofMenu.asm,v 1.1 97/04/05 01:21:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_POOF_MESSAGE_CREATION	; REST OF FILE IS A NOP IF THIS IS FALSE

MailboxClassStructures	segment	resource
	OutboxPoofMenuClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPMSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the specific Poof menu items as available from current
		transports.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= OutboxPoofMenuClass object
		es 	= segment of OutboxPoofMenuClass
		ax	= message #
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/13/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPMSpecBuild	method dynamic OutboxPoofMenuClass, MSG_SPEC_BUILD

	push	ax
	mov	ax, MSG_SPEC_GET_ATTRS
	push	bp
	call	ObjCallInstanceNoLock	; cl = SpecAttrs
	pop	bp
	test	cl, mask SA_USES_DUAL_BUILD
	jz	buildKids
	test	bp, mask SBF_WIN_GROUP
	jz	toSuper

buildKids:
	call	OPMCreateKids
	mov	ax, MGCNLT_NEW_TRANSPORT
	call	UtilAddToMailboxGCNList

toSuper:
	pop	ax
	mov	di, offset OutboxPoofMenuClass
	GOTO	ObjCallSuperNoLock

OPMSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPMMbNotifyNewTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some transport has been changed.  Rebuild Poof menu items.

CALLED BY:	MSG_MB_NOTIFY_NEW_TRANSPORT
PASS:		*ds:si	= OutboxPoofMenuClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPMMbNotifyNewTransport	method dynamic OutboxPoofMenuClass, 
					MSG_MB_NOTIFY_NEW_TRANSPORT
	call	OTMDestroyKids
	call	OPMCreateKids

	ret
OPMMbNotifyNewTransport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPMCreateKids
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create one child for each system message type, as determined
		by all transport capabilities.

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= OutboxPoofMenu object
		bp	= SpecBuildFlags with only SBF_UPDATE_MODE used
RETURN:		ds fixed up
DESTROYED:	ax, bx, cx, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPMCreateKids	proc	near
	uses	es
	.enter

	call	MediaGetAllTransportCapabilities	; ax = capabilities
	mov	cx, handle ROStrings

	;
	; Loop thru the three system message types.  We are doing it in
	; reverse order here.
	;
	mov	bx, mask MBTC_CAN_SEND_CLIPBOARD
	test	ax, bx
	jz	checkFile
	mov	dx, offset uiPoofMenuClipboard
	call	OPMCreateChild

checkFile:
	mov	bx, mask MBTC_CAN_SEND_FILE
	test	ax, bx
	jz	checkQuickMessage
	mov	dx, offset uiPoofMenuFile
	call	OPMCreateChild

checkQuickMessage:
	mov	bx, mask MBTC_CAN_SEND_QUICK_MESSAGE
	test	ax, bx
	jz	done
	mov	dx, offset uiPoofMenuQuickMessage
	call	OPMCreateChild

done:
	.leave
	ret
OPMCreateKids	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPMCreateChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build one Poof menu item with the passed moniker.

CALLED BY:	(INTERNAL) OPMCreateKids
PASS:		*ds:si	= OutboxPoofMenu object
		^lcx:dx	= string to use as moniker of child
		bp	= SpecBuildFlags
		bx	= MailboxTransportCapabilities (only one of the
			  MBTC_CAN_SEND_* bits can be set)
RETURN:		ds fixed up
DESTROYED:	bx, dx, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPMCreateChild	proc	near
	uses	ax,cx,bp,si
	class	OutboxPoofMenuClass
	.enter

if ERROR_CHECK
	;
	; Make sure al contains exactly one of these bits, and nothing else.
	;
	cmp	bx, mask MBTC_CAN_SEND_QUICK_MESSAGE
	je	EC_okay
	cmp	bx, mask MBTC_CAN_SEND_FILE
	je	EC_okay
	Assert	e, bx, <mask MBTC_CAN_SEND_CLIPBOARD>
EC_okay:
endif

	push	bx			; save MailboxTransportCapabilities
					;  for the new trigger

	DerefDI	OutboxPoofMenu
	test	ds:[di].OPMI_attrs, mask OPMA_BRINGS_UP_WINDOW
	pushf

	;
	; Allocate ReplaceVisMonikerFrame first.
	;
		; make sure it's at an even offset.
		CheckHack <(offset RVMF_updateMode and 1) eq 0>
		CheckHack <(size ReplaceVisMonikerFrame and 1) eq 0>
		; make sure SBF_UPDATE_MODE is the last two bits.
		CheckHack <offset SBF_UPDATE_MODE eq 0>
	push	bp			; push RVMF_updateMode + even align
	sub	sp, offset RVMF_updateMode - \
			(offset RVMF_source + size RVMF_source)
	pushdw	cxdx			; push RVMF_source
					; ss:sp = ReplaceVisMonikerFrame

	;
	; Instantiate a GenTrigger in our block.
	;
	mov	dx, si			; *ds:dx = OutboxPoofMenu
	segmov	es, <segment GenTriggerClass>, di
	mov	di, offset GenTriggerClass
	mov	bx, ds:[OLMBH_header].LMBH_handle
	call	ObjInstantiate		; *ds:si = GenTrigger
	mov	di, bp			; di = SpecBuildFlags

	;
	; Add the new trigger to the menu
	;
	xchg	si, dx			; *ds:si = OutboxPoofMenu
	mov	cx, bx			; ^lcx:dx = GenTrigger
	mov	ax, MSG_GEN_ADD_CHILD
		CheckHack <CCO_FIRST eq 0>
	clr	bp			; bp = CCO_FIRST
	call	ObjCallInstanceNoLock

	;
	; Pass the moniker to the new trigger
	;
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	bp, sp			; ss:bp = ReplaceVisMonikerFrame
	mov	ss:[bp].RVMF_sourceType, VMST_OPTR
	mov	ss:[bp].RVMF_dataType, VMDT_TEXT
	push	si			; save lptr of menu
	mov	si, dx			; *ds:si = GenTrigger
	mov	dx, size ReplaceVisMonikerFrame
	call	ObjCallInstanceNoLock	; RVMF_updateMode is trashed on return!
	pop	dx			; dx = lptr of menu
	add	sp, size ReplaceVisMonikerFrame

	;
	; Tell the trigger to send us a message when the user hits the trigger.
	;
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	cx, bx			; ^lcx:dx = menu
	call	ObjCallInstanceNoLock
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	cx, MSG_OPM_POOF_TYPE_SELECTED
	call	ObjCallInstanceNoLock

	;
	; If we're marked as bringing up a window, mark the trigger likewise.
	;
	popf				; ZF set if not marked
	jz	setPoofType
	mov	ax, HINT_TRIGGER_BRINGS_UP_WINDOW
	clr	cx
	call	ObjVarAddData

setPoofType:
	;
	; Store the MailboxTransportCapabilities of this trigger
	;
	mov	ax, ATTR_GEN_TRIGGER_ACTION_DATA
	mov	cx, size MailboxTransportCapabilities
	call	ObjVarAddData		; ds:bx = extra data
	pop	ds:[bx]

	;
	; Set the trigger usable
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dx, di			; dl = VisUpdateMode
	call	ObjCallInstanceNoLock

	.leave
	ret
OPMCreateChild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPMPoofTypeSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up the send dialog box for the Poof type that the user
		has selected.

CALLED BY:	MSG_OPM_POOF_TYPE_SELECTED
PASS:		cx	= MailboxTransportCapabilities
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	10/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OPMPoofTypeSelected	method dynamic OutboxPoofMenuClass,
					MSG_OPM_POOF_TYPE_SELECTED

	;
	; See which poof dialog we should use.
	;
	mov	dx, MDT_QUICK_MESSAGE
	test	cx, mask MBTC_CAN_SEND_QUICK_MESSAGE
	jnz	gotTemplate
	mov	dx, MDT_FILE
	test	cx, mask MBTC_CAN_SEND_FILE
	jnz	gotTemplate
	mov	dx, MDT_CLIPBOARD

gotTemplate:
	call	ObjBlockGetOutput
	mov	ax, MSG_MAILBOX_SEND_CONTROL_POOF_SELECTED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
OPMPoofTypeSelected	endm

OutboxUICode	ends

endif	; _POOF_MESSAGE_CREATION
