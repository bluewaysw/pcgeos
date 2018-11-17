COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1999.  All rights reserved.
	GLOBALPC CONFIDENTIAL

PROJECT:	Native Ethernet Support
MODULE:		ODI Ethernet driver
FILE:		ethodiInit.asm

AUTHOR:		Allen Yuen, Dec 07, 1999

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	12/07/99   	Initial revision


DESCRIPTION:
		
	Init and exit code for EtherODI.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode		segment	resource

lslSignatureString	byte	"LINKSUP$"

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIContactLSL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish communicaiton with LSL, and register stack

CALLED BY:	EtherInit

PASS:		nothing
RETURN:		carry set on error
DESTROYED:	ax, cx, dx, si, di, bp, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/30/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIContactLSL	proc	near
		uses	bx
		.enter

	;
	;  First, let's see if we can find the LSL layer.
	;  If we can't there's no point in continuing...
		mov	ax, LSL_SIGNATURE_FUNC

trySlot:
		push	ax
		call	SysLockBIOS
		int	LSL_INT		; AL <- 0xFF if installed
					; ES:SI <- "LINKSUP$" if installed
					; DX:BX <- LSL's Entry point
		call	SysUnlockBIOS

		cmp	al, 0xFF
		pop	ax
		jne	nextSlot

		segmov	ds, cs					; ds:di <- lsl sig.
		mov	di, offset lslSignatureString
		mov	cx, length lslSignatureString /2

		xchg	di, si					; ds:si <- lsl sig.
								; es:di <- possible sig.

		repe	cmpsw
		jne	nextSlot

	;
	;  The LSL layer seems to be here.  Squirrel away
	;  its entry point off into dgroup, and then try
	;  to install ourselves as a protocol stack.
		GetDGroup	ds, ax
		movdw	ds:[lslEntryPoint], dxbx

								; ds -> DGROUP
		call	EthODIRegisterProtoStack	; carry set on error
							; bp preserved, all else toast
		jc	failure

	;
	;  Find an ethernet card that supports TCPIP.
		call	EthODIFindMLID
		jc	deregisterProtoStack	; => no card, back out

	;
	;  Bind our stack to the ethernet card
		call	EthODIBindStack

		clc				; success

done:
		.leave
		ret

nextSlot:
	;
	; Keep trying until we've reached the last slot.
		inc	ah		; next slot
		jnz	trySlot

failure:
		stc
		jmp	done	

deregisterProtoStack:
		call	EthODIDeregisterProtoStack
		jmp	failure
EthODIContactLSL	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIRegisterProtoStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register protocol stack with LSL.

CALLED BY:	EtherInit

PASS:		DS	-> DGROUP
RETURN:		carry set on error
DESTROYED:	AX, BX, CX, DX, SI, DI, ES, DS
		BP preserved

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/30/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ipStackShortNameLength	byte	length ipStackShortName - 1
ipStackShortName	char	"IP",0
arpStackShortNameLength	byte	length arpStackShortName - 1
arpStackShortName	char	"ARP",0
; The name strings must be "length-preceded".
.assert	offset ipStackShortNameLength + size ipStackShortNameLength \
	eq offset ipStackShortName
.assert	offset arpStackShortNameLength + size arpStackShortNameLength \
	eq offset arpStackShortName

EthODIRegisterProtoStack		proc
		protoEntryPoints	local	ProtSupEntryStruct
		protoStackInfo		local	ProtoStackInfoStruct
		.enter

		call	SysLockBIOS

	;
	;  While MLID's can register directly with LSL, Protocol
	;  stacks have to work through an additional layer to get the
	;  entry point for registering a new stack.
		segmov	es, ss		; ES:DI -> buffer to fill in
		lea	si, protoEntryPoints
		mov	bx, LSLIF_GET_PROTSUP_ENTRY
		call	ds:[lslEntryPoint]

	;
	;  Having been informed of the correct location of the entry
	;  points, store them in DGROUP, then try and install ourselves
	;  as a protocol stack...
		GetDGroup	ds, ax

		movdw	ds:[lslProtoEntry], \
				ss:[protoEntryPoints].PSES_protoEntry, ax
		movdw	ds:[lslGenEntry], ss:[protoEntryPoints].PSES_genEntry, ax

	;
	;  Register IP stack.
		lea	si, protoStackInfo
		mov	es:[si].PSIS_short.segment, cs
		mov	es:[si].PSIS_short.offset, \
				offset ipStackShortNameLength
		mov	es:[si].PSIS_recvHandler.segment, \
				segment EthODIIpRecvHandler
		mov	es:[si].PSIS_recvHandler.offset, \
				offset EthODIIpRecvHandler
		mov	es:[si].PSIS_cntrlHandler.segment, segment EthODICntrlHandler
		mov	es:[si].PSIS_cntrlHandler.offset, offset EthODICntrlHandler
		mov	bx, LSLPF_REGISTER_PROTO_STACK
		call	ds:[lslProtoEntry]	; bx = stack ID,
						; ax = LSLErrorCode, ZF
		stc
		jnz	exit			; return error if can't reg
		mov	ds:[ipStackId], bx

	;
	;  Register ARP stack.
		mov	ss:[protoStackInfo].PSIS_short.segment, cs
		mov	ss:[protoStackInfo].PSIS_short.offset, \
				offset arpStackShortNameLength
		mov	ss:[protoStackInfo].PSIS_recvHandler.segment, \
				segment EthODIArpRecvHandler
		mov	ss:[protoStackInfo].PSIS_recvHandler.offset, \
				offset EthODIArpRecvHandler
		segmov	es, ss
		lea	si, ss:[protoStackInfo]	; es:si = protoStackInfo
		mov	bx, LSLPF_REGISTER_PROTO_STACK
		call	ds:[lslProtoEntry]	; bx = stack ID,
						; ax = LSLErrorCode, ZF
		stc
		jnz	exit
		mov	ds:[arpStackId], bx

		clc				; success

exit:
		call	SysUnlockBIOS		; flags preserved

		.leave
		ret
EthODIRegisterProtoStack		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIFindMLID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find an logical board that supports TCPIP.

CALLED BY:	EthODIContactLSL
PASS:		nothing
RETURN:		CF clear if found
			lslBoardNum filled
DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/12/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIFindMLID	proc	near
	.enter

	GetDGroup	ds, bx
	clr	bp			; start at logical board #0

tryBoard:
	;
	; Get entry point of this logical board
	;
	mov	bx, LSLPF_GET_MLID_CONTROL_ENTRY
	mov	ax, bp			; ax = board #
	call	SysLockBIOS
	call	ds:[lslProtoEntry]	; es:si = MLID control handler,
					;  ax = LSLErrorCode
	call	SysUnlockBIOS
	cmp	ax, LSLEC_NO_MORE_ITEMS
	stc
	je	exit			; => can't find a usable board
	cmp	ax, LSLEC_ITEM_NOT_PRESENT
	je	next

	;
	; See if this logical board recognizes IP.
	;
	mov	bx, LSLPF_GET_PROTOCOL_ID
	mov	ax, ds:[ipStackId]
	mov	cx, bp			; cx = board #
	segmov	es, ds, si
	mov	si, offset ipProtoId	; es:si = ipProtoId
	call	SysLockBIOS
	call	ds:[lslProtoEntry]	; ax = LSLErrorCode, ZF
	call	SysUnlockBIOS
if	ERROR_CHECK
	jz	ecOk
	pushf
	Assert	e, ax, LSLEC_ITEM_NOT_PRESENT
	popf
ecOk:
endif	; ERROR_CHECK
	jnz	next

	;
	; See if this logical board recognizes ARP.
	;
	mov	bx, LSLPF_GET_PROTOCOL_ID
	mov	ax, ds:[arpStackId]
	mov	cx, bp			; cx = board #
	segmov	es, ds, si
	mov	si, offset arpProtoId	; es:si = arpProtoId
	call	SysLockBIOS
	call	ds:[lslProtoEntry]	; ax = LSLErrorCode, ZF
	call	SysUnlockBIOS
	jz	found
	Assert	e, ax, LSLEC_ITEM_NOT_PRESENT

next:
	inc	bp			; next logical board
	jmp	tryBoard

found:
	mov	ds:[lslBoardNum], bp
	clc				; success

exit:
	.leave
	ret
EthODIFindMLID	endp

if 0	; for testing only


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIRegisterPrescanRxChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	FOR TESTING ONLY

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/16/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
	protoStackChain	StackChainStruct <,
				,
				SR_FIRST,
				EthODIPrescanRxHandler,
				EthODIPrescanRxControlHandler,
				,
				LDT_DEST_PROMISCUOUS,

				>
idata	ends

EthODIRegisterPrescanRxChain	proc	near
	.enter

	GetDGroup	ds, ax

	mov	bx, LSLPF_REGISTER_PRESCAN_RX_CHAIN
	mov	ax, ds:[lslBoardNum]
	mov	ds:[protoStackChain].SCS_boardNum, ax
	mov	ax, ds:[ipStackId]
	mov	ds:[protoStackChain].SCS_id, ax
	segmov	es, ds
	mov	si, offset protoStackChain	; es:si = protoStackChain
	call	SysLockBIOS
	call	ds:[lslProtoEntry]
	call	SysUnlockBIOS
	Assert	e, ax, LSLEC_SUCCESSFUL

	.leave
	ret
EthODIRegisterPrescanRxChain	endp

endif	; if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIBindStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bind our stack to the logical board.

CALLED BY:	EthODIContactLSL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/12/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIBindStack	proc	near
	.enter

	call	SysLockBIOS
	GetDGroup	ds, ax

	;
	; Bind IP
	;
	mov	bx, LSLPF_BIND_STACK
	mov	ax, ds:[ipStackId]
	mov	cx, ds:[lslBoardNum]
	call	ds:[lslProtoEntry]
	Assert	e, ax, LSLEC_SUCCESSFUL

	;
	; Bind ARP
	;
	mov	bx, LSLPF_BIND_STACK
	mov	ax, ds:[arpStackId]
	mov	cx, ds:[lslBoardNum]
	call	ds:[lslProtoEntry]
	Assert	e, ax, LSLEC_SUCCESSFUL

	mov	ds:[linkEstablished], TRUE

	call	SysUnlockBIOS

	.leave
	ret
EthODIBindStack	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIInitRecvBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init the link list of free ECB blocks.

CALLED BY:	EthDevInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	si, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We use ECB_nextLink.offset to maintain a linked list of free ECBs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/25/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIInitRecvBuffers	proc	near

	;
	; Make the list head point to the first array entry.
	;
	GetDGroup	ds, ax
	mov	di, offset recvEcbArray
	mov	ds:[recvEcbFreeList], di
	mov	si, offset recvBuffers

next:
	;
	; Fill in fields that never change.
	;
	mov	ds:[di].ECB_fragCount, 1
	mov	ds:[di].ECB_fragments.PFP_addr.segment, ds
	mov	ds:[di].ECB_fragments.PFP_addr.offset, si
	mov	ds:[di].ECB_fragments.PFP_size, RECV_BUFFER_SIZE

	;
	; Make each array entry point to the next one.
	;
	add	si, RECV_BUFFER_SIZE
	add	di, size ECBAndFragDesc
	mov	ds:[di - size ECBAndFragDesc].ECB_nextLink.offset, di
	cmp	di, offset recvEcbArray + size ECBAndFragDesc \
			* NUM_RECV_BUFFERS
	jb	next

	;
	; Null-terminate the last array entry.
	;
	mov	ds:[di - size ECBAndFragDesc].ECB_nextLink.offset, NULL

	ret
EthODIInitRecvBuffers	endp

if 0	; for testing only

ResidentCode	segment	resource
prescanRxCalled	word
EthODIPrescanRxHandler	proc	far
	cmp	{word} ds:[di].LAS_protId, 0
	jne	stop
	cmp	{word} ds:[di].LAS_protId[2], 0
	jne	stop
	cmp	{word} ds:[di].LAS_protId[4], 0
	jne	stop
cont:
	inc	cs:[prescanRxCalled]
	mov	ax, LSLEC_OUT_OF_RESOURCES
	ret

stop:
	jmp	cont
EthODIPrescanRxHandler	endp
EthODIPrescanRxControlHandler	proc	far
	ret
EthODIPrescanRxControlHandler	endp
ResidentCode	ends

endif	; if 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIDetachLSL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister stack, and stop communication with LSL.

CALLED BY:	EthDevExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/14/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIDetachLSL	proc	near

	FALL_THRU EthODIDeregisterProtoStack

EthODIDetachLSL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EthODIDeregisterProtoStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister protocol stack with LSL.

CALLED BY:	EthODIContactLSL, EthODIDetachLSL
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/12/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EthODIDeregisterProtoStack	proc	near
	uses	bx
	.enter

	GetDGroup	ds, ax
	mov	ds:[linkEstablished], FALSE
	call	SysLockBIOS		; in case LSL turns interrupt on
	INT_OFF				; need to pass interrupt off

	;
	; Deregister IP stack.  This also implicitly unbinds the stack.
	;
	mov	bx, LSLPF_DEREGISTER_STACK
	mov	ax, ds:[ipStackId]
	call	ds:[lslProtoEntry]
	Assert	e, ax, LSLEC_SUCCESSFUL

	;
	; Deregister ARP stack.  This also implicitly unbinds the stack.
	;
	mov	bx, LSLPF_DEREGISTER_STACK
	mov	ax, ds:[arpStackId]
	call	ds:[lslProtoEntry]
	Assert	e, ax, LSLEC_SUCCESSFUL

	INT_ON
	call	SysUnlockBIOS

	.leave
	ret
EthODIDeregisterProtoStack	endp

InitCode		ends
