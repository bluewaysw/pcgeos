COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		mainProtocol.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/ 2/93   	Initial version.

DESCRIPTION:
	Code for the protocol interaction dialog.  Moved here from
	mainMain.asm. 	

	$Id: mainProtocol.asm,v 1.1 97/04/04 16:55:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	not _TELNET

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveInactivePorts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable serial ports that aren't available

CALLED BY:	ProtocolInteractionInitiate

PASS:		bp      - SerialDeviceMap record
		ds	- segment of UI objects

RETURN:		nothing

DESTROYED:	bp, bx, dx, ax, di, cx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dennis	07/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

portTable	label	word
	dw	offset	ProtocolUI:SetCom1
	dw	offset	ProtocolUI:SetCom2
	dw	offset	ProtocolUI:SetCom3
	dw	offset	ProtocolUI:SetCom4
portTableEnd	label	word

RemoveInactivePorts 	proc	near
		uses	si
		.enter
	;
	; Lock down the object block holding the items so we can more
	; efficiently send them messages.
	;
		GetResourceHandleNS	SetCom1, bx
		call	ObjSwapLock
		push	bx

		mov	bx, offset portTable 		;set ptr into  table
			CheckHack <SERIAL_COM2 - SERIAL_COM1 eq 2>
topLoop:
		mov	si, cs:[bx]

		shr	bp, 1
		jc	enable
		mov     ax, MSG_GEN_SET_NOT_ENABLED
		jmp	sendIt
enable:
		mov	ax, MSG_GEN_SET_ENABLED

sendIt:
		mov     dl, VUM_NOW
		push	bp
		call	ObjCallInstanceNoLock 
		pop	bp
next:
		shr	bp, 1				;skip unused bit
		add	bx, 2				;
		cmp	bx, offset portTableEnd		;
		jb	topLoop
	;
	; Re-lock object block we had on entry...
	;
		pop	bx
		call	ObjSwapUnlock
		.leave
		ret
RemoveInactivePorts 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProtocolInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ProtocolInteractionClass object
		ds:di	- ProtocolInteractionClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ProtocolInteractionInitiate	method	dynamic	ProtocolInteractionClass, 
					MSG_GEN_INTERACTION_INITIATE

		uses	ax,cx,dx,bp
		.enter
		push	ds
		segmov	ds, es		; dgroup
		call	SerialCheckPorts
		pop	ds
		call	RemoveInactivePorts
		.leave
		mov	di, offset ProtocolInteractionClass
		GOTO	ObjCallSuperNoLock
ProtocolInteractionInitiate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProtocolInteractionApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hack MSG_GEN_APPLY for Protocol box

CALLED BY:	MSG_GEN_APPLY (sent by UI)

PASS:		method stuff
		es - segment where ProtocolInteraction class defined

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	09/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProtocolInteractionApply	method	ProtocolInteractionClass, MSG_GEN_APPLY
	;
	; set the flag saying that we are handling protocol-interaction
	;
	mov	es:[protocolInteraction], TRUE
	mov	es:[reportedProtocolInteractionError], FALSE
	;
	; call superclass to send MSG_GEN_APPLY to the various lists
	;
	mov	di, offset ProtocolInteractionClass
	call	ObjCallSuperNoLock
	;
	; then fetch and store the states of the various gadgets in the dialog
	;
	call	StoreProtocolSettings
	;
	; reset protocol-interaction flag via application queue as we want
	; it reset after all the various lists have sent out their
	; notifications
	;
	mov	bx, es:[termProcHandle]
	mov	ax, MSG_DONE_PROTOCOL_INTERACTION
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
ProtocolInteractionApply	endm

StoreProtocolSettings	method	ProtocolInteractionClass,
					MSG_PROTOCOL_INTERACTION_STORE_SETTINGS
;we make this assumption in ProtocolInteractionDeref
EC <	cmp	si, offset ProtocolBox					>
EC <	ERROR_NE	0						>

	GetResourceHandleNS	ProtocolUI, bx
	mov	si, offset ProtocolUI:ComList
	call	GenItemGroupGetSelection		; ax = selection
	mov	ds:[si].PII_comListState, ax

	mov	si, offset ProtocolUI:BaudList
	call	GenItemGroupGetSelection		; ax = selection
	mov	ds:[si].PII_baudListState, ax

	mov	si, offset ProtocolUI:DataList
	call	GenItemGroupGetSelection		; ax = selection
	mov	ds:[si].PII_dataListState, ax

	mov	si, offset ProtocolUI:ParityList
	call	GenItemGroupGetSelection		; ax = selection
	mov	ds:[si].PII_parityListState, ax

	mov	si, offset ProtocolUI:StopList
	call	GenItemGroupGetSelection		; ax = selection
	mov	ds:[si].PII_stopListState, ax

	mov	si, offset ProtocolUI:FlowList
	call	GenBooleanGroupGetSelectedBooleans	; ax = selected booleans
	mov	ds:[si].PII_flowListState, ax

	mov	si, offset ProtocolUI:StopRemoteList
	call	GenBooleanGroupGetSelectedBooleans	; ax = selected booleans
	mov	ds:[si].PII_stopRemoteListState, ax

	mov	si, offset ProtocolUI:StopLocalList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	GenBooleanGroupGetSelectedBooleans	; ax = selected booleans
	mov	ds:[si].PII_stopLocalListState, ax
	ret
StoreProtocolSettings	endm

GenItemGroupGetSelection	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax = selection
	call	ProtocolInteractionDeref
	ret
GenItemGroupGetSelection	endp

GenBooleanGroupGetSelectedBooleans	proc	near
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; ax = selected booleans
	call	ProtocolInteractionDeref
	ret
GenBooleanGroupGetSelectedBooleans	endp

ProtocolInteractionDeref	proc	near
	mov	si, offset ProtocolBox
	mov	si, ds:[si]
	add	si, ds:[si].ProtocolInteraction_offset
	ret
ProtocolInteractionDeref	endp

TermDoneProtocolInteraction	method	TermClass, \
				MSG_DONE_PROTOCOL_INTERACTION
	mov	es:[protocolInteraction], FALSE
	call	TermDisplayProtocolWarningBoxIfNeeded
	ret
TermDoneProtocolInteraction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TermResetProtocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle "reset" in Protocol box

CALLED BY:	

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProtocolInteractionReset	method	ProtocolInteractionClass, MSG_GEN_RESET
;we make this assumption in ProtocolInteractionDeref
EC <	cmp	si, offset ProtocolBox					>
EC <	ERROR_NE	0						>
	;
	; fetch and restore the states of the various gadgets in the dialog
	;
	GetResourceHandleNS	ProtocolUI, bx
	call	ProtocolInteractionDeref
	mov	cx, ds:[si].PII_comListState
	mov	si, offset ProtocolUI:ComList
	call	GenItemGroupSetSingleSelection

	mov	cx, ds:[si].PII_baudListState
	mov	si, offset ProtocolUI:BaudList
	call	GenItemGroupSetSingleSelection

	mov	cx, ds:[si].PII_dataListState
	mov	si, offset ProtocolUI:DataList
	push	cx
	call	GenItemGroupSetSingleSelection
	pop	cx
	mov	ax, MSG_TERM_ADJUST_USER_FORMAT
	call	SendStatusToProc

	mov	cx, ds:[si].PII_parityListState
	mov	si, offset ProtocolUI:ParityList
	call	GenItemGroupSetSingleSelection

	mov	cx, ds:[si].PII_stopListState
	mov	si, offset ProtocolUI:StopList
	call	GenItemGroupSetSingleSelection

	mov	cx, ds:[si].PII_flowListState
	mov	si, offset ProtocolUI:FlowList
	push	cx
	call	GenBooleanGroupSetGroupState
	pop	cx
	mov	ax, MSG_TERM_SET_USER_FLOW
	call	SendStatusToProc

	mov	cx, ds:[si].PII_stopRemoteListState
	mov	si, offset ProtocolUI:StopRemoteList
	push	cx
	call	GenBooleanGroupSetGroupState
	pop	cx
	mov	ax, MSG_TERM_USER_STOP_REMOTE_SIGNAL
	call	SendStatusToProc

	mov	cx, ds:[si].PII_stopLocalListState
	mov	si, offset ProtocolUI:StopLocalList
	call	GenBooleanGroupSetGroupState
	;
	; disable Apply/Reset
	;
	GetResourceHandleNS	ProtocolBox, bx
	mov	si, offset ProtocolBox
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
	mov	di, mask MF_CALL
	call	ObjMessage
	ret
ProtocolInteractionReset	endm

GenItemGroupSetSingleSelection	proc	near
	clr	dx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage		; ax = selection
	call	ProtocolInteractionDeref
	ret
GenItemGroupSetSingleSelection	endp

GenBooleanGroupSetGroupState	proc	near
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	di, mask MF_CALL
	call	ObjMessage
	call	ProtocolInteractionDeref
	ret
GenBooleanGroupSetGroupState	endp

SendStatusToProc	proc	near
	mov	bp, cx				; simulate turning on this one
	mov	bx, es:[termProcHandle]
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	GetResourceHandleNS	ProtocolUI, bx
	call	ProtocolInteractionDeref
	ret
SendStatusToProc	endp
endif	; !_TELNET

