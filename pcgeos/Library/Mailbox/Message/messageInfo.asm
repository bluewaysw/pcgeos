COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		messageInfo.asm

AUTHOR:		Adam de Boor, Jun  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 3/94		Initial revision


DESCRIPTION:
	Functions for extracting info from a message.
		

	$Id: messageInfo.asm,v 1.1 97/04/05 01:20:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MessageCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetBodyMboxRefBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the opaque mbox-ref to the message body.

CALLED BY:	(GLOBAL) Transport drivers.
PASS:		cxdx	= MailboxMessage
RETURN:		carry clear if okay:
			^hbx	= mbox-ref
			ax destroyed
		carry set on error:
			ax	= MailboxError
					ME_NOT_ENOUGH_MEMORY
					ME_INVALID_MESSAGE
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetBodyMboxRefBlock	proc	far
	uses	cx,dx,ds,si,es,di
	.enter
	call	MIGetMboxRefAndSize		;ds:si = mbox-ref, cx = size.
	jc	done
	push	cx				;save size of subject
	mov	ax, cx				;ax = size to allocate
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			;bx = hptr, ax = sptr
	pop	cx
	jc	outOfMem

	; copy mbox-ref to destination block
	mov	es, ax
	clr	di				; (clears carry)
	rep	movsb
	call	MemUnlock
	
unlock:
	call	UtilVMUnlockDS
done:
	.leave
	ret
outOfMem:
	mov	ax, ME_NOT_ENOUGH_MEMORY
	jmp	unlock
MailboxGetBodyMboxRefBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MIGetMboxRefAndSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock message and get the mbox-ref and the size of the
		mbox-ref.

CALLED BY:	MailboxGetBodyMboxRefBlock
PASS:		cxdx	= MailboxMessage
RETURN:		carry clear if success
			cx	= size of mbox-ref for message body
			ds:si	= mbox-ref
		carry set on error
			ax	= ME_INVALID_MESSAGE
DESTROYED:	nothing
SIDE EFFECTS:	message locked (use UtilVMUnlockDS to unlock)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIGetMboxRefAndSize	proc	near
	uses	di
	.enter
	call	MessageLockCXDX		;*ds:di = MailboxMessageDesc
	jc	done
	mov	si, ds:[di]
	mov	si, ds:[si].MMD_bodyRef	;*ds:si = mbox-ref
	ChunkSizeHandle ds, si, cx	;cx = size
	mov	si, ds:[si]		;es:di = mbox-ref
	clc
done:
	.leave
	ret
MIGetMboxRefAndSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetStorageType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches the MailboxStorage token for the message.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry set if error:
			ax	= MailboxError (message is invalid)
		carry clear if ok:
			bxax	= MailboxStorage
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetStorageType	proc	far
	.enter

	mov	bx, offset MMD_bodyStorage
	call	MIGetMessageDWord

	.leave
	ret
MailboxGetStorageType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetSubjectLMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the subject/summary of a message into an lmem block

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		bx	= handle of lmem block into which to copy the subject.
RETURN:		carry set on error:
			ax	= MailboxError (invalid message, insufficient
				  memory)
		carry clear if ok:
			^lbx:ax	= null-terminated subject
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 1/94    	Initial version
	ardeb	5/22/95		Changed to fixup ds and es, as necessary

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetSubjectLMem	proc	far
	uses	cx,si,di,bp,dx
	.enter

	mov	bp, ds
	mov	ax, es
	;
	; Find size of subject string
	;
	call	MIGetSubjectSizeCommon	; cx = size, es:si = string
	jc	done

	push	es			; save subject segment
	mov	es, ax			; es <- passed ES for fixup by LMemAlloc
	;
	; Allocate chunk in destination block
	;
	call	ObjLockObjBlock		; in case lmem block is an object blk
	mov	ds, ax			; ds = dest blk
	clr	dx			; assume passed DS not same
	cmp	ax, bp
	jne	allocChunk		; yes
	dec	dx			; no -- flag it

allocChunk:
	;
	; Allocate a chunk to hold the subject.
	;
	mov	al, mask OCF_DIRTY

	push	ds:[LMBH_flags]
	ornf	ds:[LMBH_flags], mask LMF_RETURN_ERRORS
	call	LMemAlloc		; *ds:ax = new chunk
	pop	ds:[LMBH_flags]
	jc	outOfMem
	
	inc	dx			; fix up saved passed-DS value?
	jnz	doCopy			; => no
	mov	bp, ds
doCopy:
	mov	dx, es			; save passed ES
	segmov	es, ds
	pop	ds			; ds:si <- subject, *es:ax <- dest

	;
	; Copy string to destination chunk
	;
	mov	di, ax
	mov	di, es:[di]		; es:di = dest chunk
	rep	movsb			; copy cx bytes (flags preserved)

	mov	es, dx			; return ES properly

unlock:
	call	MemUnlock		; unlock dest blk
	call	UtilVMUnlockDS		; unlock message blk
	mov	ds, bp			; ds <- passed or fixed-up value

done:
	.leave
	ret

outOfMem:
	pop	ds			; ds <- subject block, for unlock
	mov	ax, ME_NOT_ENOUGH_MEMORY
	jmp	unlock
MailboxGetSubjectLMem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetSubjectBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the subject/summary of a message into a global
		memory block

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry set on error:
			ax	= MailboxError (invalid message, insufficient
				  memory)
		carry clear if ok:
			^hbx	= null-terminated subject
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetSubjectBlock	proc	far
	uses	cx,si,di,ds,es
	.enter

	;
	; Find size of subject string
	;
	call	MIGetSubjectSizeCommon	; cx = size, ds:si = string
	jc	done

	;
	; Allocate memory block
	;
	push	cx			; save size of subject
	mov_tr	ax, cx
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc		; bx = hptr, ax = sptr
	pop	cx			; cx = size of subject
	jc	outOfMem

	;
	; Copy string to destination block
	;
	mov	es, ax
	clr	di			; es:di = dest blk (clears carry)
	rep	movsb			; copy cx bytes (flags preserved)

	call	MemUnlock		; unlock dest blk

unlock:
	call	UtilVMUnlockDS		; unlock message blk

done:
	.leave
	ret

outOfMem:
	mov	ax, ME_NOT_ENOUGH_MEMORY
	jmp	unlock
MailboxGetSubjectBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MIGetSubjectSizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock message and get size of subject string

CALLED BY:	(INTERNAL) MailboxGetSubjectLMem, MailboxGetSubjectBlock
PASS:		cxdx	= MailboxMessage
RETURN:		carry clear if success
			cx	= size of subject string including null
			es:si	= subject string
			es:di	= char after null
			ds	= es
			ax unchanged
		carry set on error
			ax	= ME_INVALID_MESSAGE
DESTROYED:	nothing
SIDE EFFECTS:	message locked (use UtilVMUnlockDS to unlock)

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIGetSubjectSizeCommon	proc	near
	push	ax
	call	MessageLockCXDX		; *ds:di = MailboxMessageDesc
	jc	error
	mov	di, ds:[di]
	mov	di, ds:[di].MMD_subject
	mov	di, ds:[di]
	segmov	es, ds			; es:di = subject string
	mov	si, di			; si = nptr to string
	LocalStrSize	includeNull	; cx = size include null
	pop	ax
	clc
	ret

error:
	pop	cx			; discard saved ax
	ret
MIGetSubjectSizeCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetMessageFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the MailboxMessageFlags for a message

CALLED BY:	(GLOBAL) MAOutboxSendableConfirmation
PASS:		cxdx	= MailboxMessage
RETURN:		carry clear if ok
			ax	= MailboxMessageFlags
		carry set on error
			ax	= ME_INVALID_MESSAGE
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetMessageFlags proc	far
		uses	bx
		.enter
		mov	bx, offset MMD_flags
		call	MIGetMessageDWord
		jc	done
			CheckHack <mask MIMF_EXTERNAL eq 00ffh>
		clr	ah		; "andnf ax, mask MIMF_EXTERNAL",
					;  only return external flags.
					;  (clears carry)
done:
		.leave
		ret
MailboxGetMessageFlags endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetDestApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the GeodeToken for the destination app of the
		message.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		es:di	= GeodeToken buffer
RETURN:		carry clear if success
			es:di filled in
		carry set on error
			ax	= ME_INVALID_MESSAGE
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetDestApp	proc	far
	uses	ds,si,es,di,cx
	.enter
	mov	si, di				;es:si = GeodeToken buffer
	call	MessageLockCXDX
	jc	done
	mov	di, ds:[di]			;ds:di = MailboxMessageDesc
	add	di, offset MMD_destApp		;(clears carry)
	xchg	di, si				;es:di = GeodeToken buffer
	mov	cx, size GeodeToken
	rep	movsb
	call	UtilVMUnlockDS
done:
	.leave
	ret
MailboxGetDestApp	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetStartBound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the start bound of a message.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry clear if ok
			axbx	= FileDateAndTime
		carry set on error
			ax	= ME_INVALID_MESSAGE
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetStartBound	proc	far
	.enter
	mov	bx, offset MMD_transWinOpen
	call	MIGetMessageDWord
	jc	done
	xchg	ax, bx		; ax <- high, bx <- low
done:
	.leave
	ret
MailboxGetStartBound	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetEndBound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the end bound of a message.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry clear if ok
			axbx	= FileDateAndTime
		carry set on error
			ax	= ME_INVALID_MESSAGE
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	9/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetEndBound	proc	far
	.enter
	mov	bx, offset MMD_transWinClose
	call	MIGetMessageDWord
	jc	done
	xchg	ax, bx		; ax <- high, bx <- low
done:
	.leave
	ret
MailboxGetEndBound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetBodyFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches the MailboxDataFormat token for the message.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry set if error:
			ax	= MailboxError (message is invalid)
		carry clear if ok:
			bxax	= MailboxDataFormat
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetBodyFormat	proc	far
	.enter

	mov	bx, offset MMD_bodyFormat
	call	MIGetMessageDWord

	.leave
	ret
MailboxGetBodyFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MIGetMessageDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a dword out of a message

CALLED BY:	(INTERNAL) MailboxGetBodyFormat,
			   MailboxGetEndBound,
			   MailboxGetStartBound,
			   MailboxGetMessageFlags
PASS:		cxdx	= MailboxMessage to interrogate
		bx	= offset within MailboxMessageDesc of low word
RETURN:		carry clear if ok
			bxax	= dword requested
		carry set on error
			ax	= MailboxError (ME_INVALID_MESSAGE)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIGetMessageDWord proc	near
		uses	ds, di
		.enter
		call	MessageLockCXDX
		jc	done
		mov	di, ds:[di]
		mov	ax, ({dword}ds:[di][bx]).low
		mov	bx, ({dword}ds:[di][bx]).high
		call	UtilVMUnlockDS
done:
		.leave
		ret
MIGetMessageDWord endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetBodyRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves the app-reference to the body of a message (i.e.
		the address of the message body in the format understood and
		used by applications registering a message with the Mailbox
		library).

		Each call must be matched by a call to MailboxDoneWithBody.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		es:di	= place to store app-reference to body
		ax	= # bytes pointed to by es:di
RETURN:		carry set on error:
			ax	= MailboxError (invalid message, unable to load
				  driver, insufficient memory, app-ref buffer
				  too small, no message body available)
		carry clear if ok:
			es:di	= filled
			ax	= # bytes used in app-ref buffer
DESTROYED:	nothing
SIDE EFFECTS:	data driver loaded

PSEUDO CODE/STRATEGY:
	Each call must be matched by a call to MailboxDoneWithBody.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetBodyRef	proc	far

	push	bx		; to be popped by MIGetStealBodyCommon in
				;  non-EC
	mov	bx, DR_MBDD_GET_BODY
	GOTO_ECN	MIGetStealBodyCommon, bx

MailboxGetBodyRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxStealBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allows a caller to take possession of the body of a
		message. The caller is then responsible for destroying the
		data. If the message body is within a VM file, the caller is
		responsible for calling MailboxDoneWithVMFile after freeing the
		data that make up the body.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		es:di	= place to store app-reference to body
		ax	= # bytes pointed to by es:di
RETURN:		carry set on error:
			ax	= MailboxError (invalid message, unable to load
				  driver, insufficient memory, app-ref buffer
				  too small, body in-use by someone else, no
				  message body available)
		carry clear if ok:
			es:di	= filled
			ax	= # bytes used in app-ref buffer
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxStealBody	proc	far

	push	bx		; to be popped by MIGetStealBodyCommon in
				;  non-EC
	mov	bx, DR_MBDD_STEAL_BODY
	FALL_THRU_ECN	MIGetStealBodyCommon, bx

MailboxStealBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MIGetStealBodyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the actual work of getting message body from data driver.

CALLED BY:	(INTERNAL) MailboxGetBodyRef, MailboxStealBody
PASS:		cxdx	= MailboxMessage
		es:di	= place to store app-reference to body
		ax	= # bytes pointed to by es:di
		bx	= DR_MBDD_GET_BODY or DR_MBDD_STEAL_BODY

		saved on stack (to be popped by us in non-ec):
			bx
RETURN:		carry set on error:
			ax	= MailboxError (invalid message, unable to load
				  driver, insufficient memory, app-ref buffer
				  too small, body in-use by someone else, no
				  message body available)
		carry clear if ok:
			es:di	= filled
			ax	= # bytes used in app-ref buffer
DESTROYED:	nothing
SIDE EFFECTS:	if DR_MBDD_GET_BODY is passed:
			data driver remains loaded
		if DR_MBDD_STEAL_BODY is passed:
			MMD_bodyRef freed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIGetStealBodyCommon	proc	ecnear
driverFunc	local	MailboxDataDriverFunction	push	bx
bodyRefs	local	MBDDBodyRefs
strat		local	fptr.far
	uses	bx,cx,dx,si,di,ds
	.enter

	Assert	fptr, esdi
	movdw	ss:[bodyRefs].MBDDBR_appRef, esdi
	mov	ss:[bodyRefs].MBDDBR_appRefLen, ax

	;
	; Get body storage
	;
	call	MessageLockCXDX		; *ds:di = MailboxMessageDesc
	jc	exit
	mov	di, ds:[di]
	movdw	cxdx, ds:[di].MMD_bodyStorage

	;
	; Load data driver, get data driver strategy
	;
	call	MessageLoadDataDriver	; bx = driver handle, cx = size of 
					;   mbox-ref, si = size of app-ref,
					;   dxax = strategy
	jc	done
	movdw	ss:[strat], dxax
	mov	ax, ME_APP_REF_BUF_TOO_SMALL
	cmp	si, ss:[bodyRefs].MBDDBR_appRefLen
	ja	unloadDriver		; error if passed buf too small

	;
	; copy the mbox-ref info from message desc, setup temp app-ref buffer
	;
	push	di			; save nptr to MailboxMessageDesc
	mov	di, ds:[di].MMD_bodyRef	; *ds:di = mbox ref
	mov	di, ds:[di]		; ds:di = mbox ref
	movdw	ss:[bodyRefs].MBDDBR_mboxRef, dsdi
	ChunkSizePtr	ds, di, cx
	mov	ss:[bodyRefs].MBDDBR_mboxRefLen, cx

	;
	; Call the driver to get body
	;
	mov	cx, ss
	lea	dx, ss:[bodyRefs]	; cx:dx = MBDDBodyRefs
	mov	di, ss:[driverFunc]
	call	ss:[strat]
	pop	di			; ds:di = MailboxMessageDesc
	jc	unloadDriver

	;
	; If DR_MBDD_STEAL_BODY, unload driver and free MMD_bodyRef
	;
	cmp	ss:[driverFunc], DR_MBDD_STEAL_BODY
	jne	dontFree
	call	MailboxFreeDriver
	ornf	ds:[di].MMD_flags, mask MIMF_BODY_STOLEN
	clr	ax
	xchg	ax, ds:[di].MMD_bodyRef
	call	LMemFree
	call	UtilVMDirtyDS
	call	UtilUpdateAdminFile

dontFree:
	mov	ax, ss:[bodyRefs].MBDDBR_appRefLen ; ax = # of bytes used in
						   ;  app-ref buf
	clc				; no error

done:
	;
	; Unlock message
	;
	call	UtilVMUnlockDS

exit:
	.leave
	FALL_THRU_POP	bx
	ret

unloadDriver:
	;
	; Error fetching the body, so unload the driver.
	;
	push	ax
	call	MailboxFreeDriver
	pop	ax
	stc
	jmp	done
MIGetStealBodyCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxDoneWithBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Indicates the body reference returned by an earlier call to
		MailboxGetBodyRef will no longer be used. The data driver is
		free to close the file, etc. No further use of the body via
		this reference may be made.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		es:di	= app-reference to body
		ax	= # bytes in app-reference
RETURN:		carry set if passed MailboxMessage is invalid
DESTROYED:	nothing
SIDE EFFECTS:	data driver unloaded

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	8/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxDoneWithBody	proc	far
	uses	ax,bx,cx,dx,si,di,ds
	.enter

	Assert	fptr, esdi
	push	di			; save nptr to app-ref

	;
	; Get storage driver token
	;
	call	MessageLockCXDX		; *ds:di = MailboxMessageDesc
	jc	badMessage
	mov	di, ds:[di]
	movdw	cxdx, ds:[di].MMD_bodyStorage	; cxdx = MailboxStorage
	call	UtilVMUnlockDS

	;
	; Get data driver handle
	;
	call	AdminGetDataDriverMap	; ax = map handle
	call	DMapGetDriverHandle	; bx = driver handle
	pop	si			; es:si = app-ref
	jc	done			; jump if storage type invalid
	pushdw	cxdx			; save MailboxStorage
	movdw	cxdx, essi		; cx:dx = app-ref
	;
	; Tell data driver we're done with the body
	;
	call	GeodeInfoDriver		; ds:si = MBDDInfo
	mov	di, DR_MBDD_DONE_WITH_BODY
	call	ds:[si].MBDDI_common.DIS_strategy

	;
	; Unload the data driver
	;
	popdw	cxdx
	call	DMapUnload

done:
	clc
exit:
	.leave
	ret

badMessage:
	pop	di
	jmp	exit
MailboxDoneWithBody	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetTransData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the transData dword for the message

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry set if error:
			ax	= MailboxError (message is invalid)
		carry clear if ok:
			bxax	= transData
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetTransData proc far
		.enter
		mov	bx, offset MMD_transData
		call	MIGetMessageDWord
		.leave
		ret
MailboxGetTransData endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxSetTransData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the 32-bit transData registered with a message. The caller
		is responsible for freeing any resources referred to by the
		previous transData dword, since the Mailbox library places
		absolutely no interpretation on the transData, and thus cannot
		know what needs to be freed when one transData dword replaces
		another.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
		bxax	= new transData
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			ax	= ME_SUCCESS
DESTROYED:	nothing
SIDE EFFECTS:	only the obvious

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 6/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxSetTransData proc	far
		uses	ds, di
		.enter
		call	MessageLockCXDX
		jc	done
		mov	di, ds:[di]
		movdw	ds:[di].MMD_transData, bxax
		call	UtilVMDirtyDS
		call	UtilVMUnlockDS
		call	UtilUpdateAdminFile
			CheckHack <ME_SUCCESS eq 0>
		clr	ax			; (clears carry)
done:
		.leave
		ret
MailboxSetTransData endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the MailboxTransport bound to a message

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		carry set if error:
			ax	= MailboxError (message is invalid)
		carry clear if ok:
			bxax	= MailboxTransport
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetTransport proc	far
		.enter
		mov	bx, offset MMD_transport
		call	MIGetMessageDWord
		.leave
		ret
MailboxGetTransport endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MailboxGetTransOption
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the MailboxTransportOption bound to a message.

CALLED BY:	(GLOBAL)
PASS:		cxdx	= MailboxMessage
RETURN:		if carry set:
			ax	= MailboxError (message invalid)
		if carry clear:
			ax	= MailboxTransportOption
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MailboxGetTransOption proc	far
		uses	bx
		.enter
		mov	bx, offset MMD_transOption
		call	MIGetMessageDWord
		.leave
		ret
MailboxGetTransOption endp

MessageCode	ends

