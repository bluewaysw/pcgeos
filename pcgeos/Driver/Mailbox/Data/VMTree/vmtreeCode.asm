COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VM Tree Data Driver
FILE:		vmtreeCode.asm

AUTHOR:		Chung Liu, Jun 13, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/13/94   	Initial revision


DESCRIPTION:
	
	A bunch of DR_MBDD_* routines.		

	$Id: vmtreeCode.asm,v 1.1 97/04/18 11:41:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeStoreBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a message, returning a mboxRef to the message.

CALLED BY:	(Mailbox Library)
PASS:		cx:dx	= pointer to MBDDBodyRefs
			  NOTE: MBDDBR_mboxRef.offset is actually a *chunk
			  handle*, not an offset. This allows the driver to
			  enlarge or shrink the buffer, as needed.
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			*cx:dx.MBDDBR_mboxRef sized as small as possible and
				filled in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If MMF_BODY_DATA_VOLATILE, then call the Mailbox Library to
	obtain a VM file, and then copy the whole VM chain to the 
	new file.

	Otherwise, assume the VM file was obtained from the Mailbox
	Library from the application, and call MailboxGetVMFileName
	to obtain the file name with which to generate the mbox-ref.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeStoreBody	proc	far
	uses	bx,cx,dx,ds,es,si,di
	.enter
	push	ax				;save if no error.
	movdw	dssi, cxdx			;ds:si = MBDDBodyRefs
	les	di, ds:[si].MBDDBR_appRef	;es:di = app-ref
	test	ds:[si].MBDDBR_flags, mask MMF_BODY_DATA_VOLATILE
	jz	noCopy
	;
	; The caller indicated that the VM tree may go away anytime.
	; Copy the VM tree in app-ref to a VM file obtained from the
	; Mailbox Library.
	;
	mov	bx, es:[di].VMTAR_vmFile
	movdw	axcx, es:[di].VMTAR_vmChain
	call	VMTCreateSafeCopyOfTree		;^vbx:ax.cx = new tree
	jc	getVMFileError
	jmp	doMboxRef
noCopy:
	;es:di = app-ref
	mov	bx, es:[di].VMTAR_vmFile
	movdw	axcx, es:[di].VMTAR_vmChain

doMboxRef:
	;
	; Create the mbox-ref and update the segment of mbox-ref in
	; body-refs, because it may have moved due to resizing.
	; ds:si = body-refs, ^vbx:ax.cx = VM chain for which to create the
	; mbox-ref.
	;
	push	ds				;save body-refs segment
	lds	dx, ds:[si].MBDDBR_mboxRef	;*ds:dx = mbox-ref buffer
	call	VMTCreateMboxRef		;ds may have moved.
	mov	dx, ds				;dx = segment of mbox-ref
	pop	ds				;ds = segment of body-refs
	mov	ds:[si].MBDDBR_mboxRef.segment, dx
	mov	ds:[si].MBDDBR_mboxRefLen, cx	;store new size of mbox-ref
	;
	; If we've obtained a new file from the VM store, don't forget
	; to close it.
	;
	test	ds:[si].MBDDBR_flags, mask MMF_BODY_DATA_VOLATILE
	jz	noClose
	call	MailboxDoneWithVMFile
noClose:
	clc					;no errors.
	pop	ax				;we survived, so restore ax
exit:
	.leave
	ret

getVMFileError:
	pop	ax
	mov	ax, ME_CANNOT_CREATE_MESSAGE_FILE
	jmp	exit

VMTreeStoreBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTCreateSafeCopyOfTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a VM tree into a "safe" VM file obtained from the
		Mailbox Library's VM store.

CALLED BY:	VMTreeStoreBody
PASS:		bx	= VM file handle
		ax:cx	= head of chain
RETURN:		carry clear if okay:
			bx	= handle VM file containing copy.  (VM file
				  is obtained from the VM store.)
			ax:cx	= head of copy of chain.
		carry set if error (couldn't get new VM file):
			ax, bx, cx destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTCreateSafeCopyOfTree	proc	near
vmFile		local	hptr		push bx
vmChain		local	dword		push ax, cx
	uses	dx
	.enter
	;
	; Obtain a VM file from the Mailbox Library.  For that, we need to
	; get the number of blocks first.
	;
	call	VMTInfoVMChain			;bx = blocks, cx:dx = size
	jc	exit				; => tree is invalid
	call	MailboxGetVMFile		;bx = dest. VM file
	jc	exit
	;
	; Copy the VM tree.
	;
	mov	dx, vmFile
	xchg	dx, bx				;bx = source VM file,
						;dx = dest. VM file
	push	bp
	movdw	axbp, vmChain			;ax:bp = source chain
	call	VMCopyVMChain			;ax:bp = dest. chain
	mov	cx, bp				;ax:cx = dest. chain
	pop	bp
	mov	bx, dx				;return bx = new VM file
	clc
exit:
	.leave
	ret
VMTCreateSafeCopyOfTree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTCreateMboxRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a mbox-ref to the message, placing the reference
		in the passed chunk.  The chunk is resized to fit the
		mbox-ref.

CALLED BY:	VMTreeStoreBody
PASS:		*ds:dx	= VMTreeMboxRef 
		ax:cx	= head of VM chain
		bx	= VM file handle obtained from the Mailbox 
			  Library's VM store.
RETURN:		*ds:dx	= VMTreeMboxRef filled in. (ds may have moved due
			  to resizing.)
		cx	= new size of VMTreeMboxRef chunk
DESTROYED:	nothing
SIDE EFFECTS:	*ds:dx chunk is resized to fit the mbox-ref.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTCreateMboxRef	proc	near
vmChain		local	dword		push	ax, cx
vmFilename	local	FileLongName
	uses	ax,bx,ds,si,es,di
	.enter
	;
	; Obtain the VM file's filename and filename size, so that we
	; can figure out how big mbox-ref has to be.
	;
	push	dx				;save mbox-ref
	mov	cx, ss
	lea	dx, ss:[vmFilename]
	call	MailboxGetVMFileName
	movdw	esdi, cxdx
	LocalStrSize includeNull		;cx = bytes in filename
	add	cx, offset VMTMR_filename	;cx = desired mbox-ref size
	pop	ax				;*ds:ax = mbox-ref
	;
	; Resize Mbox-ref chunk to fit the filename.
	; XXX: Does this block have LMF_RETURN_ERRORS set?
	;
	call	LMemReAlloc			;ds may have moved.
EC <	ERROR_C ERROR_VMTREE_DD_UNEXPECTED_ERROR			>
	segmov	es, ds
	mov	di, ax
	mov	di, ds:[di]			;es:di = mbox-ref
	push	ax				;save chunk handle of mbox-ref
	;
	; Fill in mbox-ref with what we've got.
	;
	movdw	es:[di].VMTMR_vmChain, vmChain, ax
	add	di, offset VMTMR_filename	;es:di = dest
	segmov	ds, ss	
	lea	si, vmFilename			;ds:si=source filename
	LocalCopyString
	;
	; return *ds:dx = mbox-ref (ds may have moved due to resizing)
	;
	segmov	ds, es				;ds = segment of mbox-ref
	pop	dx				;dx = chunk handle of mbox-ref
	.leave
	ret
VMTCreateMboxRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeDeleteBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instructs the driver to delete the message body whose mbox-ref
		is passed.

CALLED BY:	DR_MBDD_DELETE_BODY
PASS:		cx:dx	= pointer to mbox-ref returned by DR_MBDD_STORE_BODY
RETURN:		carry set if unable to delete the message. 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Since the VM store may return the same VM file for many different
	callers, we can't just delete the VM file.  We have to traverse
	the tree and free each VM block and DB item.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeDeleteBody	proc	far
	uses	ax,bx,cx,dx,ds,si
	.enter
	;
	; First open the file, of course.
	;
	movdw	dssi, cxdx
	add	dx, offset VMTMR_filename
	call	MailboxOpenVMFile		;bx = VM file handle
	jc	openError
	;
	; Get rid of all the blocks and DB items in the tree.
	;
	push	bp
	movdw	axbp, ds:[si].VMTMR_vmChain
	call	VMFreeVMChain
	pop	bp
	;
	; Commit changes
	;
	call	VMUpdate
	call	MailboxDoneWithVMFile
	clc
exit:
	.leave
	ret
openError:
	mov	ax, ME_CANNOT_OPEN_MESSAGE_FILE
	jmp	exit
VMTreeDeleteBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeDeleteBodyAppRef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the message body whose app-ref is passed.  The 
		VM file in the app-ref must have been obtained from the
		Mailbox Library.  	

CALLED BY:	DR_MBDD_DELETE_BODY_APP_REF
PASS:		cx:dx	= app-ref
RETURN:		carry set if unable to delete message.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeDeleteBodyAppRef	proc	far
	uses	ds,si,ax,bx
	.enter
	movdw	dssi, cxdx			;ds:si = app-ref
	mov	bx, ds:[si].VMTAR_vmFile
	push	bp
	movdw	axbp, ds:[si].VMTAR_vmChain
	call	VMFreeVMChain
	pop	bp
	call	MailboxDoneWithVMFile
	clc	
	.leave
	ret
VMTreeDeleteBodyAppRef	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeStealBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the body of a message, returning an app-ref to it. The
		only difference between this and DR_MBDD_GET_BODY is the
		driver will *not* receive a DR_MBDD_DONE_WITH_BODY call: the
		caller is taking complete possession of the message body.

CALLED BY:	DR_MBDD_STEAL_BODY
PASS:		cx:dx	= pointer to MBDDBodyRefs. MBDDBR_flags is undefined
			  MBDDBR_mboxRef is an actual far pointer
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if successful:
			cx:dx.MBDDBR_appRef filled in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	XXX: Someone tell me how this would be different from VMTreeGetBody.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeStealBody	proc	far
	FALL_THRU	VMTreeGetBody
VMTreeStealBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeGetBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the body of a message, returning an app-ref to it.

CALLED BY:	DR_MBDD_GET_BODY
PASS:		cx:dx	= pointer to MBDDBodyRefs. MBDDBR_flags is undefined
			  MBDDBR_mboxRef is an actual far pointer
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if successful:
			cx:dx.MBDDBR_appRef filled in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeGetBody	proc	far
	uses	bx,si,di,bp,ds,es
	.enter
	push	ax				;preserve if no errors
	;
	; Get the mbox-ref that was passed in body-refs.
	;
	movdw	dssi, cxdx			;ds:si = body-refs
	les	di, ds:[si].MBDDBR_mboxRef	;es:di = mbox-ref
	; 
	; Open the VM file and validate the vm chain.
	;
	call	VMTOpenAndValidate		;bx = handle, ax.bp = chain
	jc	error
	;
	; Fill in the app-ref.
	;
	lds	si, ds:[si].MBDDBR_appRef	; ds:si = app-ref
	movdw	ds:[si].VMTAR_vmChain, axbp
	mov	ds:[si].VMTAR_vmFile, bx
	pop	ax				;restore passed ax

exit:
	.leave
	ret

error:
	pop	bx				;discard saved ax
	jmp	exit
VMTreeGetBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeDoneWithBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The recipient of the message is done with the body that
		was returned by a previous DR_MBDD_GET_BODY. The driver may
		do whatever cleanup or other work it deems appropriate.
CALLED BY:	DR_MBDD_DONE_WITH_BODY
PASS:		cx:dx	= pointer to app-ref returned by DR_MBDD_GET_BODY
			  (not necessarily at the same address; just the
			  contents are the same)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeDoneWithBody	proc	far
	uses	bx,ds,si
	.enter
	movdw	dssi, cxdx			;ds:si = app-ref
	mov	bx, ds:[si].VMTAR_vmFile
	call	MailboxDoneWithVMFile
	.leave
	ret
VMTreeDoneWithBody	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeBodySize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the number of bytes in a message body, for use
		in control panels and information dialogs and the like.
CALLED BY:	DR_MBDD_BODY_SIZE
PASS:		cx:dx	= pointer to mbox-ref for the body
RETURN:		carry set on error:
			ax	= MailboxError
			dx	= destroyed
		carry clear if ok:
			dxax	= number of bytes in the body (-1 if info not
			  	  available)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeBodySize	proc	far
	uses	bx,cx,ds,si
	.enter
	;
	; From the mbox-ref's filename, we need to obtain a VM file handle.
	;
	movdw	dssi, cxdx			;ds:si = mbox-ref
	add	dx, offset VMTMR_filename	;cx:dx = filename
	call	MailboxOpenVMFile		;bx = VM file handle
	jc	openError
	;
	; Luckily, we have a routine that does just what we want.
	;
	movdw	axcx, ds:[si].VMTMR_vmChain
	push	bx				;preserve VM file
	call	VMTInfoVMChain			;cx:dx = bytes
	pop	bx				;bx = VM file
	;
	; Done with the file.
	;
	pushf
	call	MailboxDoneWithVMFile
	movdw	dxax, cxdx			;return size in dx:ax
	popf
	jnc	exit
	mov	ax, ME_MESSAGE_BODY_INVALID
exit:
	.leave
	ret
openError:
	mov	ax, ME_CANNOT_OPEN_MESSAGE_FILE
	jmp	exit
	
VMTreeBodySize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeCheckIntegrity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the integrity of the message body.

CALLED BY:	DR_MBDD_CHECK_INTEGRITY
PASS:		cx:dx	= pointer to mbox-ref for the body
RETURN:		carry set if the message body is invalid
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeCheckIntegrity	proc	far
	uses	ax,bx,bp,es
	.enter

	movdw	esdi, cxdx
	call	VMTOpenAndValidate	; CF clear if valid, bx = vmfile handle
	jc	done

	call	MailboxDoneWithVMFile
	clc
done:
	.leave
	ret
VMTreeCheckIntegrity	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTOpenAndValidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the VM file and check the integrity of the VM tree.

CALLED BY:	VMTreeGetBody, VMTreeCheckIntegrity
PASS:		es:di	= VMTreeMboxref
RETURN:		carry clear if message valid
			bx	= vm file handle
			ax.bp	= vm chain
		carry set if message invalid
			ax	= ME_CANNOT_OPEN_MESSAGE_FILE
				  ME_MESSAGE_BODY_INVALID
			bx, bp - destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AY	3/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTOpenAndValidate	proc	near
	uses	cx,dx,si,di
	.enter

	;
	; Open the VM file.
	;
	mov	cx, es
	lea	dx, es:[di].VMTMR_filename	;cx:dx = VM filename
	call	MailboxOpenVMFile		;bx = VM file
	mov	ax, ME_CANNOT_OPEN_MESSAGE_FILE
	jc	done

	;
	; Check the VM tree.
	;
	movdw	axbp, es:[di].VMTMR_vmChain
	call	VMInfoVMChain
	jnc	done

	;
	; Error.  Close the VM file.
	;
	call	MailboxDoneWithVMFile
	mov	ax, ME_MESSAGE_BODY_INVALID
	stc

done:
	.leave
	ret
VMTOpenAndValidate	endp

Movable 	ends









