COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		Outbox
FILE:		outboxDetails.asm

AUTHOR:		Adam de Boor, May 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/27/94		Initial revision


DESCRIPTION:
	
		

	$Id: outboxDetails.asm,v 1.1 97/04/05 01:21:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CONTROL_PANELS		; REST OF FILE IS A NOP UNLESS THIS IS TRUE

MailboxClassStructures	segment	resource
	OutboxDetailsClass
MailboxClassStructures	ends

OutboxUICode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODMdSetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the gadgets in the outbox details box that are specific
		to us.

CALLED BY:	MSG_MD_SET_MESSAGE
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
		cxdx	= MailboxMessage
		bp	= address # (+ dups) to display
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODMdSetMessage	method dynamic OutboxDetailsClass, MSG_MD_SET_MESSAGE
		uses	cx, dx, bp, si, ax
		.enter
	;
	; Add ourselves to the appropriate GCN list, so we know if the message
	; goes away.
	; 
		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilAddToMailboxGCNList
	;
	; Set the current ID to be for just the address in question, so
	; ODShowDests knows what to put in.
	; 
		mov	ax, bp
		ornf	ax, mask TID_ADDR_INDEX
		mov	ds:[di].ODI_curID, ax
	;
	; Put the message into dxax for the duration, as that's what MessageLock
	; expects.
	; 
		MovMsg	dxax, cxdx
	;
	; Set up the # failures & reason. This will also set these things usable
	; again, if they were set not-usable by having selected List All before.
	; 
		call	ODListFailuresAndReason
	;
	; Set up the bounds.
	;
		call	ODShowBounds
	;
	; List the selected destinations.
	; 
		call	ODShowDests
	;
	; See if there are other addresses than that selected.
	; 
		call	ODCheckOtherAddresses

		mov	ax, MSG_GEN_SET_USABLE
		jc	changeUsable
		mov	ax, MSG_GEN_SET_NOT_USABLE
changeUsable:
		pushf
		mov	dl, VUM_NOW
		mov	si, offset OutboxPanelDetailsListAllGroup
		call	ObjCallInstanceNoLock
		popf
		jnc	done
	;
	; The thing is usable, but we're not listing all the addresses, so
	; turn off the LIST_ALL boolean.
	; 

		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_BOOLEAN_STATE
		mov	cx, ODLS_LIST_ALL
		clr	dx
		call	ObjCallInstanceNoLock
done:
		.leave
		mov	di, offset OutboxDetailsClass
		GOTO	ObjCallSuperNoLock
ODMdSetMessage	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODListFailuresAndReason
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user the number of times the transmission failed and
		why the latest attempt did so.

CALLED BY:	(INTERNAL) ODMdSetMessage
PASS:		*ds:si	= OutboxDetails
		dxax	= message
		bp	= address #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	object block & chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODListFailuresAndReason proc	near
		class	OutboxDetailsClass
		uses	dx, ax, si, di, bp, cx
		.enter
	;
	; Get the flags & reason token from the address we're displaying.
	; 
		push	ds, si
		call	MessageLock

		mov	di, ds:[di]
		mov	si, ds:[di].MMD_transAddrs
		mov_tr	ax, bp
		call	ChunkArrayElementToPtr

		mov	al, ds:[di].MITA_flags
		mov	cx, ds:[di].MITA_reason
		call	UtilVMUnlockDS
		pop	ds, si
	;
	; Create a textual representation of the number of tries.
	; 
		and	ax, mask MTF_TRIES
		push	ax, cx		; save # tries & reason token for
					;  setting reason text
		mov	di, sp		; for clearing the stack

			CheckHack <width MTF_TRIES eq 4>
			CheckHack <offset MTF_TRIES eq 0>
		cmp	ax, 10
		jb	isSingle
	;
	; It's into double digits, so we have to do more work.
	; 
		cmp	ax, MTF_INFINITY
		je	tooMany
if DBCS_PCGEOS
		add	ax, 00010000h - 10
		adc	dx, (00010000h - 10) shr 16
					; dx = high digit, ax = low digit
		add	ax, C_DIGIT_ZERO
		push	ax
		mov_tr	ax, dx		; ax = high digit
		add	ax, C_DIGIT_ZERO
else
		add	ax, 0100h - 10	; ah = high digit, al = low digit
		xchg	ah, al		; put ones digit into the second byte
		add	ax, (C_ZERO shl 8) or C_ZERO
endif
		mov	cx, 2		; 2 digits to display.
		jmp	setFailures

tooMany:
	;
	; It's been tried our definition of infinity, which is > 14, so that's
	; what we put up (it also needs no localization)
	; 
			CheckHack <MTF_INFINITY eq 15>
if DBCS_PCGEOS
		LocalLoadChar	ax, C_DIGIT_FOUR
		push	ax
		LocalLoadChar	ax, C_DIGIT_ONE
		push	ax
		LocalLoadChar	ax, C_SPACE
		push	ax
		LocalLoadChar	ax, C_GREATER_THAN_SIGN
else
		mov	ax, C_ONE or (C_FOUR shl 8)
		push	ax
		mov	ax, C_GREATER_THAN or (C_SPACE shl 8)
endif
		mov	cx, 4
		jmp	setFailures

isSingle:
	;
	; Still single digits. Convert to ascii, please.
	; 
SBCS <		add	al, C_ZERO					>
DBCS <		add	ax, C_DIGIT_ZERO				>
		mov	cx, 1

setFailures:
	;
	; Set the initial bytes of the string to set and set it.
	; ax	= initial byte(s)
	; cx	= length of the string
	; di	= sp above the string, for clearing the stack
	; 
		push	ax		; set initial bytes of the string
		mov	bp, sp
		mov	dx, ss		; dx:bp <- pointer to string
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	si, offset OutboxPanelDetailsNumFailures
		call	ObjCallInstanceNoLock
	;
	; Make sure the thing is usable.
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
	;
	; Clear the stack and get set to get the reason for the most recent
	; failure.
	; 
		mov	sp, di
		pop	ax, cx

		tst	ax
		jz	useNAString		; => never tried
	;
	; Fetch the reason string into a chunk in our block, please.
	; 
		mov_tr	ax, cx
		call	OutboxGetReason		; *ds:ax <- string
		mov	dx, ds:[LMBH_handle]
		mov_tr	bp, ax			; ^ldx:bp <- optr of string

setReason:
	;
	; Set that string as the text of the reason text object.
	; ^ldx:bp = optr of reason (must be optr b/c it's likely to be in
	;	    the same block)
	; 
		clr	cx
		push	dx, bp			; save for possible free
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
		mov	si, offset OutboxPanelDetailsReason
		call	ObjCallInstanceNoLock
	;
	; Make sure the object is usable...
	; 
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
		pop	dx, bp
	;
	; If the string is in the same block, free it.
	; 
		cmp	dx, ds:[LMBH_handle]
		jne	done
		mov_tr	ax, bp
		call	LMemFree
done:
		.leave
		ret

useNAString:
	;
	; Use a standard string, since there can be no reason for
	; failure, there never having been an attempt to send.
	; 
	; Alternative: just set the beastie not-usable...
	; 
		mov	dx, handle uiNoReasonString
		mov	bp, offset uiNoReasonString
		jmp	setReason
ODListFailuresAndReason endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODShowBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the transmission bounds of the message.

CALLED BY:	(INTERNAL) ODMdSetMessage
PASS:		*ds:si	= OutboxDetails object
		dxax	= MailboxMessage
RETURN:		ds fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	1/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODShowBounds	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	class	OutboxDetailsClass
	.enter

	DerefDI	OutboxDetails
	mov	si, ds:[di].MDI_boundText
	mov	cx, ds			; *cx:si = boundText

	;
	; Get dates and times of bounds.
	;
	call	MessageLock		; *ds:di = MailboxMessageDesc
	mov	di, ds:[di]
	pushdw	ds:[di].MMD_transWinClose
	movdw	bxax, ds:[di].MMD_transWinOpen
	call	UtilVMUnlockDS

	;
	; Create string for start bound.
	;
	mov	ds, cx			; *ds:si = boundText
		CheckHack <UFDTF_SHORT_FORM eq 0>
	clr	cx			; cx = UFDTF_SHORT_FORM
	call	UtilFormatDateTime	; *ds:ax = string, cx still zero
	mov	dx, ds:[OLMBH_header].LMBH_handle
	push	ax			; save string lptr
	mov_tr	bp, ax			; ^ldx:bp = string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_OPTR
	call	ObjCallInstanceNoLock
	pop	ax			; *ds:ax = string
	call	LMemFree

	;
	; Add " and ".
	;
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	mov	dx, handle uiAnd
	mov	bp, offset uiAnd
	clr	cx			; null-terminated
	call	ObjCallInstanceNoLock

	;
	; Create string for end bound.
	;
	popdw	bxax			; bxax = MMD_transWinClose
		CheckHack <UFDTF_SHORT_FORM eq 0>
	clr	cx			; cx = UFDTF_SHORT_FORM
	call	UtilFormatDateTime	; *ds:ax = string, cx still zero
	mov	dx, ds:[OLMBH_header].LMBH_handle
	push	ax			; save string lptr
	mov_tr	bp, ax			; ^ldx:bp = string
	mov	ax, MSG_VIS_TEXT_APPEND_OPTR
	call	ObjCallInstanceNoLock
	pop	ax			; *ds:ax = string
	call	LMemFree

	.leave
	ret
ODShowBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODShowDests
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	List all the appropriate destinations for the message in
		the destination text object.

CALLED BY:	(INTERNAL) ODMdSetMessage, ODListAllAddresses
PASS:		*ds:si	= OutboxDetails object with ODI_curID set
		dxax	= MailboxMessage
		bp	= address for which we were brought on screen
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	block & chunks are likely to move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODShowDests	proc	near
curAddr		local	word		push bp
objSeg		local	sptr		push ds
		uses	dx, ax, cx, si, di, bx
		class	OutboxDetailsClass
		.enter
	;
	; Fetch the current display ID while we're pointing at the detail
	; box.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].OutboxDetails_offset
		mov	bx, ds:[di].ODI_curID
	;
	; Biff the current contents of the text object -- we always start from
	; scratch.
	; 
		push	dx, ax, bp
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		mov	si, offset OutboxPanelDetailsDestination
		call	ObjCallInstanceNoLock
		pop	dx, ax, bp
		mov	ss:[objSeg], ds		; apparently, there are times
						;  when the block moves during
						;  this message...
	;
	; Call ODAppendOneDest for all the addresses the user has chosen to
	; display.
	; 
		mov	cx, ss:[curAddr]
		mov	di, offset ODAppendOneDest
		call	OUAddrEnum
		mov	ds, ss:[objSeg]
		.leave
		ret
ODShowDests	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODAppendOneDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append the user-readable form of this address to the 
		destination text object, followed by a carriage return

CALLED BY:	(INTERNAL) ODShowDests
PASS:		ds:di	= MailboxInternalTransAddr
		ss:bp	= inherited frame
RETURN:		ss:[objSeg] = fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODAppendOneDest	proc	near
		uses	ds, di, ax, cx, dx, bp, si
		.enter	inherit ODShowDests
		Assert	stackFrame, bp
	;
	; Point to the user-readable address.
	; 
		mov	dx, ds
		lea	ax, ds:[di].MITA_opaque
		add	ax, ds:[di].MITA_opaqueLen

		mov	ds, ss:[objSeg]
		mov	si, offset OutboxPanelDetailsDestination
	;
	; Append a return to the current text if there's anything there, to
	; separate the last address from this one.
	; 
		push	bp
		push	dx, ax
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		call	ObjCallInstanceNoLock
		or	ax, dx
		jz	appendAddress
	;
	; There's something there, so stuff a carriage return after it.
	; 
		mov	ax, C_CR
		push	ax
		mov	dx, ss
		mov	bp, sp
		mov	cx, 1
		mov	ax, MSG_VIS_TEXT_APPEND_PTR
		call	ObjCallInstanceNoLock
		pop	ax		; clear stack
appendAddress:
		pop	dx, bp		; dx:bp <- text to append
		clr	cx		; cx <- null-terminated
		mov	ax, MSG_VIS_TEXT_APPEND_PTR
		call	ObjCallInstanceNoLock
	;
	; Store back the fixed-up object block segment.
	; 
		pop	bp		; restore frame pointer
		mov	ss:[objSeg], ds
		.leave
		ret
ODAppendOneDest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODCheckOtherAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the message has other unsent addresses that
		might be displayable.

CALLED BY:	(INTERNAL) ODMdSetMessage
PASS:		*ds:si	= OutboxDetails object
		dxax	= MailboxMessage
		bp	= address for which we were brought on screen
RETURN:		carry set if there are other addresses
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODCheckOtherAddresses proc	near
		uses	ds, si, di, cx, ax, bx, dx
		.enter
		call	MessageLock
		mov	si, ds:[di]
		mov	si, ds:[si].MMD_transAddrs
		mov	ax, bp
		call	ChunkArrayElementToPtr
		mov	cx, ds:[di].MITA_medium
		mov	dx, di
		mov	bx, cs
		mov	di, offset checkCallback
		call	ChunkArrayEnum
		call	UtilVMUnlockDS
		.leave
		ret
	;--------------------
	; Callback to see if an address is for the same medium as the one the
	; user chose, but isn't the one the user chose.
	;
	; Pass:	ds:di	= MailboxInternalTransAddr to check
	; 	cx	= medium for selected address
	; 	dx	= offset of selected address
	; Return:	carry set if address is unsent, non-duplicate address
	;			for the the same medium and isn't the one the
	;			user chose
	;
checkCallback:
			CheckHack <MAS_SENT eq 0>
		test	ds:[di].MITA_flags, mask MTF_STATE
		jz	callbackDone		; (carry clear)
		test	ds:[di].MITA_flags, mask MTF_DUP
		jnz	callbackDone		; (carry clear)
		cmp	ds:[di].MITA_medium, cx
		clc
		jne	callbackDone
		cmp	di, dx
		je	callbackDone
		stc
callbackDone:
		retf
ODCheckOtherAddresses endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODListAllAddresses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change what's being display to show or not show all the
		addresses of the current message

CALLED BY:	MSG_OD_LIST_ALL_ADDRESSES
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
		cx	= ODLS_LIST_ALL if should list all addresses, or 0
			  if should list only the specific ones.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	lots

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODListAllAddresses method dynamic OutboxDetailsClass, MSG_OD_LIST_ALL_ADDRESSES
		.enter
			CheckHack <ODLS_LIST_ALL eq 1>
		Assert	be, cx, ODLS_LIST_ALL
	;
	; Calculate the proper value for ODI_curID
	; 
		mov	ax, ds:[di].MDI_address
		mov	bp, ax			; bp <- selected address, for
						;  ODShowDests
		ornf	ax, mask TID_ADDR_INDEX	; assume showing only selected
		jcxz	setCurID		; => correct

		clr	ax			; show all, please
setCurID:
		mov	ds:[di].ODI_curID, ax
	;
	; Reinitialize the destinations text object using the new curID and the
	; existing message info.
	; 
		movdw	dxax, ds:[di].MDI_message
		call	ODShowDests
	;
	; Now we need to put back or remove the # failures & reason objects.
	; 
		tst	cx
		jnz	removeReasonStuff	; => showing all, so # & reason
						;  not appropriate

		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL		; delay update until reason
						;  is also set usable (we're
						;  assuming the two objects
						;  are in the same visual group
						;  of course)
		mov	si, offset OutboxPanelDetailsNumFailures
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	si, offset OutboxPanelDetailsReason
		call	ObjCallInstanceNoLock
done:
		.leave
		ret

removeReasonStuff:
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	si, offset OutboxPanelDetailsNumFailures
		call	ObjCallInstanceNoLock

		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	si, offset OutboxPanelDetailsReason
		call	ObjCallInstanceNoLock
		jmp	done
ODListAllAddresses endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODSendMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Submit all the displayed addresses that aren't currently
		queued for transmission

CALLED BY:	MSG_OD_SEND_MESSAGE
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	addresses may be marked. OutboxTransmitMessage may be called.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODSendMessage	method dynamic OutboxDetailsClass, MSG_OD_SEND_MESSAGE
numMarked	local	word
talID		local	TalID
		.enter
		mov	ss:[numMarked], 0	; nothing marked yet
	;
	; Allocate a talID for marking eligible addresses.
	; 
		call	AdminAllocTALID
		mov	ss:[talID], ax
	;
	; Run through all the addresses, marking those not already queued for
	; transmission.
	; 
		movdw	dxax, ds:[di].MDI_message
		mov	bx, ds:[di].ODI_curID
		mov	cx, ds:[di].MDI_address
		mov	di, offset ODSendMessageCallback
		call	OUAddrEnum
	;
	; If we marked anything, call OutboxTransmitMessage to get it sent.
	; 
		tst	ss:[numMarked]
		jz	done
		mov	cx, ss:[talID]
		push	ds:[OLMBH_header].LMBH_handle	; for de-ref
		call	OutboxTransmitMessage
		call	MemDerefStackDS	; *ds:si = self
done:
		call	UtilInteractionComplete
		.leave
		ret
ODSendMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODSendMessageCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to see if a displayed address is currently
		being sent to, and to mark it for transmission if not.

CALLED BY:	(INTERNAL) ODSendMessage via OUAddrEnum
PASS:		ds:di	= MailboxInternalTransAddr to check
		*ds:bx	= MailboxMessageDesc
		ss:bp	= inherited frame
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	address will have its MITA_addrList changed and ss:[numMarked]
     			will be increased if the address is not currently
			queued for transmission.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODSendMessageCallback proc near
		uses	ax
		.enter	inherit	ODSendMessage
		mov	al, ds:[di].MITA_flags
		andnf	al, mask MTF_STATE
		cmp	al, MAS_SENDING shl offset MTF_STATE
		je	done
		cmp	al, MAS_QUEUED shl offset MTF_STATE
		je	done
		mov	ax, ss:[talID]
		mov	ds:[di].MITA_addrList, ax
		call	UtilVMDirtyDS
		inc	ss:[numMarked]
done:
		.leave
		ret
ODSendMessageCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODDeleteMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the currently-displayed set of addresses. Deletion is
		accomplished by setting MAS_SENT for each address.

CALLED BY:	MSG_OD_DELETE_MESSAGE
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	message is removed from the outbox if no more addresses
     			remain unsent.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODDeleteMessage	method dynamic OutboxDetailsClass, MSG_OD_DELETE_MESSAGE
	;
	; Run through all the addresses, marking them as sent.
	; 
		movdw	dxax, ds:[di].MDI_message
		mov	bx, ds:[di].ODI_curID
		mov	cx, ds:[di].MDI_address
		GOTO	OUDeleteMessage

ODDeleteMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODGetTransportMedia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the transport + medium token for the selected address
		in our message

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= OutboxDetails object
RETURN:		cxdx	= MailboxTransport
		bx	= MailboxTransportOption
		ax	= media token for OM routines
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODGetTransportMedia proc	near
		uses	ds, si, di
		class	OutboxDetailsClass
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].MessageDetails_offset
		movdw	dxax, ds:[di].MDI_message
		mov	cx, ds:[di].MDI_address
		call	MessageLock

		mov_tr	ax, cx
		mov	si, ds:[di]
		movdw	cxdx, ds:[si].MMD_transport
		mov	bx, ds:[si].MMD_transOption
		mov	si, ds:[si].MMD_transAddrs
		push	cx
		call	ChunkArrayElementToPtr
		pop	cx

		mov	ax, ds:[di].MITA_medium
		call	UtilVMUnlockDS
		.leave
		ret
ODGetTransportMedia endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODMdGetTitleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the transport+medium string to use in the title.

CALLED BY:	MSG_MD_GET_TITLE_STRING
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
RETURN:		*ds:ax	= chunk with string to use
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	blocks & chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODMdGetTitleString method dynamic OutboxDetailsClass, MSG_MD_GET_TITLE_STRING
		.enter
		call	ODGetTransportMedia
		call	OutboxMediaGetTransportString
		.leave
		ret
ODMdGetTitleString endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODMdGetDeliveryVerb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the transport+medium verb to use in the delivery
		trigger's moniker

CALLED BY:	MSG_MD_GET_DELIVERY_VERB
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
RETURN:		*ds:ax	= chunk with string to use
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	block & chunks may move

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODMdGetDeliveryVerb method dynamic OutboxDetailsClass, MSG_MD_GET_DELIVERY_VERB
		.enter
		call	ODGetTransportMedia
		call	OutboxMediaGetTransportVerb
		.leave
		ret
ODMdGetDeliveryVerb endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODMdReleaseMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from the GCN list to which we added ourselves
		in MSG_MD_SET_MESSAGE

CALLED BY:	MSG_MD_RELEASE_MESSAGE
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/30/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODMdReleaseMessage method dynamic OutboxDetailsClass, MSG_MD_RELEASE_MESSAGE
		uses	ax
		.enter
		tst	ds:[di].MDI_message.high
		jz	passOn
		mov	ax, MGCNLT_OUTBOX_CHANGE
		call	UtilRemoveFromMailboxGCNList
passOn:
		.leave
		mov	di, offset OutboxDetailsClass
		GOTO	ObjCallSuperNoLock
ODMdReleaseMessage endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ODMbNotifyBoxChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replacement to MessageDetails implementation of this method
		to take care of address number comparison in list-all mode
		and possible rebuild of destination-address text object, etc.

CALLED BY:	MSG_MB_NOTIFY_BOX_CHANGE
PASS:		*ds:si	= OutboxDetails object
		ds:di	= OutboxDetailsInstance
		cxdx	= MailboxMessage removed/added
		bp	= MABoxChange
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ODMbNotifyBoxChange method dynamic OutboxDetailsClass, 
			MSG_MB_NOTIFY_BOX_CHANGE

		cmpdw	ds:[di].MDI_message, cxdx
		jne	done		; => not us, so don't bother super
		
			CheckHack <MACT_REMOVED eq 0>
		test	bp, mask MABC_TYPE
		jnz	toSuper

		mov	bx, bp
		andnf	bx, mask MABC_ADDRESS
		cmp	bx, MABC_ALL shl offset MABC_ADDRESS
		je	toSuper

		cmp	bx, ds:[di].MDI_address
		je	toSuper		; => original address sent to, so
					;  bring down, as, even if we are
					;  displaying all addresses, we have no
					;  basis for choosing another address
					;  to go back to if the user elects to
					;  stop displaying everything
		
		tst	ds:[di].ODI_curID
		jnz	done
	;
	; Displaying everything, so update that, in case this was one of
	; the addresses we were showing.
	; 
		MovMsg	dxax, cxdx
		mov	bp, ds:[di].MDI_address
		call	ODShowDests

done:
		ret

toSuper:
		mov	di, offset OutboxDetailsClass
		GOTO	ObjCallSuperNoLock

ODMbNotifyBoxChange endm

OutboxUICode	ends

endif	; _CONTROL_PANELS
