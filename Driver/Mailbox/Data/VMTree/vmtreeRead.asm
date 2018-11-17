COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VM Tree Data Driver
FILE:		vmtreeRead.asm

AUTHOR:		Chung Liu, Jun 15, 1994

ROUTINES:
	Name			Description
	----			-----------
	VMTreeReadInitialize
	VMTAllocReadStateLocked
	VMTreeReadNextBlock
	VMTBlockInfoAndCopy
	VMTDBInfoAndCopy
	VMTPushVMChildren
	VMTreeReadComplete
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94   	Initial revision


DESCRIPTION:
	Code for DR_MBDD_READ_*.
		

	$Id: vmtreeRead.asm,v 1.1 97/04/18 11:41:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeReadInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the first call issued by the transport driver before
		beginning the transmission of a message. The driver is
		expected to locate the message body and allocate some state
		information to track the transaction.

		The driver returns a suitable 16-bit token for the transport
		driver to identify the message body more efficiently on
		subsequent calls.

CALLED BY:	DR_MBDD_READ_INITIALIZE
PASS:		cx:dx	= pointer to mboxRef for the message body
RETURN:		carry set if body could not be accessed:
			ax	= MailboxError
					ME_CANNOT_OPEN_MESSAGE_FILE
		carry clear if ok:
			si	= token to pass to subsequent calls
			bx	= number of blocks in the message
			cxdx	= number of bytes in the message body

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeReadInitialize	proc	far
chainHead	local	dword
stateHandle	local	hptr
blockCount	local	word
vmFile		local	hptr
	uses	ds,di
	.enter
	push	ax				;preserve if no error.
	movdw	dssi, cxdx			;ds:si = mbox-ref
	movdw	chainHead, ds:[si].VMTMR_vmChain, ax

	;
	; Try to open the file, and bail out if there's a problem.
	;
	add	dx, offset VMTMR_filename	;cx:dx = filename of VM File
	call	MailboxOpenVMFile
	jc	vmOpenFailed
	mov	vmFile, bx

	;mov	ax, headBlock
	;clr	cx				;ax:cx = head of chain
	movdw	axcx, chainHead
	call	VMTInfoVMChain
	jnc	bodyOK

	; message body is invalid, so close the VM file and return that error
	mov	bx, vmFile
	call	MailboxDoneWithVMFile
	pop	ax				; discard saved AX
	mov	ax, ME_MESSAGE_BODY_INVALID
	stc
	jmp	exit

bodyOK:
	mov	blockCount, bx			;also, cx:dx = body size

	; 
	; Allocate a state chunk with a stack to help transmit the VM Tree.
	;
	call	VMTAllocReadStateLocked	
	mov	stateHandle, bx
	mov	si, ds:[di]			;ds:si = read state
	mov	bx, vmFile
	mov	ds:[si].VMTRS_vmFile, bx

	call	VMTSAlloc			;bx = stack handle
	mov	ds:[si].VMTRS_stack, bx

	;
	; Initialize stack by pushing the head of the VM tree or chain.
	;
	push	dx
	;mov	dx, headBlock
	;clr	ax
	movdw	dxax, chainHead
	call	VMTSPush			
	pop	dx
	;
	; Don't forget to unlock the state segment.
	;
	mov	bx, stateHandle
	call	MemUnlockShared
	;
	; Return values. cx:dx is already the message size.
	;
	mov	bx, blockCount			
	mov	si, di				;return chunk handle as token
	pop	ax
exit:
	.leave
	ret
vmOpenFailed:
	pop	ax
	mov	ax, ME_CANNOT_OPEN_MESSAGE_FILE
	jmp	exit
VMTreeReadInitialize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTAllocReadStateLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a VMTreeReadState chunk in the readWriteStateBlock
		segment. Returns with the segment of the chunk locked.
		Caller must MemUnlockShared the segment when done accessing 
		the chunk.

CALLED BY:	VMTreeReadInitialize
PASS:		nothing
RETURN:		bx	= block handle to unlock when done accessing
		*ds:di	= VMTreeReadState
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTAllocReadStateLocked	proc	near
	uses	ax, cx
	.enter
	mov	bx, handle VMTreeState
	call	MemLockExcl
	mov	ds, ax
	mov	cx, size VMTreeReadState
	call	LMemAlloc	
	mov	di, ax			; di = handle of chunk
	call	MemDowngradeExclLock
	.leave
	ret
VMTAllocReadStateLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeReadNextBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYSNOPSIS:	Fetch the next block of data from the message body. The
		returned block will be freed by the caller.

CALLED BY:	DR_MBDD_READ_NEXT_BLOCK
PASS:		si	= token returned by DR_MBDD_READ_INITIALIZE
RETURN:		carry set on error:
			ax	= MailboxError
					ME_NOT_ENOUGH_MEMORY
			bx,cx,dx are destroyed.
		carry clear if ok:
			dx	= extra word to pass to data driver on
				  receiving machine. (Here it happens
				  to be a VMTreeBlockType.)
			cx	= number of bytes in the block
			bx	= handle of block holding the data (0 if
				  no more data in the body)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Pop a VM block from the stack.
	- Push each child of the block onto the stack (right to left if
	  it's a VM Tree).
	- Return a copy of the VM block just popped.

	XXX: Watch out for the possibility of zero-sized blocks, or
	a VMTree having a null ptr. as a child.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeReadNextBlock	proc	far
vmFile		local	word
vmBlock		local	dword
blockMemHandle	local	word
stackHandle	local	hptr
stateBlockHan	local	hptr
	uses	ds,si,di
	.enter
	push	ax				;preserve if no error
	call	VMTGetReadOrWriteStateLocked
	mov	stateBlockHan, bx
	mov	si, di				;ds:si = read state
	mov	dx, ds:[si].VMTRS_vmFile
	mov	vmFile, dx

	; 
	; Pop a vm block handle from the top of the stack.
	;
	mov	bx, ds:[si].VMTRS_stack
	mov	stackHandle, bx
	call	VMTSPop				;dx:ax = VM block handle
	movdw	vmBlock, dxax
	jnc	moreBlocks
	clr	bx, cx, dx
	clc
	pop	ax
	jmp	exit

moreBlocks:
	;
	; Get the VM block locked in memory, so we can play with it.
	;
	push	ax, bp
	mov	bx, vmFile			;VM file handle of messages
	mov	ax, dx				;VM block 
	call	VMLock				;destroys bp
	mov	ds, ax				;ds = segment of VM block
	mov	dx, bp
	pop	ax, bp
	mov	blockMemHandle, dx		;needed for VMUnlock
	
	; 
	; Distinguish btw DB item, leaf block, chain, or tree.
	;

	; If we have a DB item, then dx = group block, ax = item.
	; If not a DB item, then ax = 0.
	tst	ax
	jnz	doDBItem

	; Differentiate btw leaf block, chain, or tree.
	mov	ax, ds:[VMCL_next]
	cmp	ax, 0
	je	doLeaf
	cmp	ax, VM_CHAIN_TREE
	je	doTree

doChain::
	;
	; the block is a chain link.  Push the child on the stack and
	; return a copy of the block.
	; 
	mov	dx, ax
	clr	ax				;dx:ax = child of block
	mov	bx, stackHandle			;bx = stack
	call	VMTSPush
	jmp	blockInfoAndCopy

doTree:
	;
	; block is a tree block. Push children in reverse order and
	; return a copy of the block.  ds = locked block segment.
	;
	mov	bx, stackHandle
	call	VMTPushVMChildren 
	jmp	blockInfoAndCopy

doDBItem:
	mov	bx, vmFile
	movdw	axdx, vmBlock
	call	VMTDBInfoAndCopy		
	clr	di				;no user ID for a DB block
	jmp	unlockAndExit
	
doLeaf:
blockInfoAndCopy:
	; 
	; Make a copy of our block, and get its size.
	;
	mov	bx, vmFile
	mov	cx, vmBlock.high
	call	VMTBlockInfoAndCopy		;di = user ID of block
	jc	memAllocError

unlockAndExit:
	; di = user ID of VM block
	mov	dx, di				;dx = user ID of block
	push	bp
	mov	bp, blockMemHandle
	call	VMUnlock
	pop	bp
	pop	ax
exit:
	;
	; unlock readWriteStateBlock, which contains the read state.
	;
	push	bx
	mov	bx, stateBlockHan
	call	MemUnlockShared
	pop	bx
	.leave
	ret

memAllocError:
	pop	ax
	mov	ax, ME_NOT_ENOUGH_MEMORY
	jmp	exit

VMTreeReadNextBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTBlockInfoAndCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an unlocked block containing a copy of the 
		locked block that is passed in.

CALLED BY:	VMTreeReadNextBlock
PASS:		bx	= VM file
		cx	= VM block 
RETURN:		carry clear if okay:
			bx 	= handle of new block containing copied block
			cx	= block size.
			di	= user ID of the block
		else carry set if not enough memory:
			bx, cx are destroyed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTBlockInfoAndCopy	proc	near
	uses	ax,dx,ds,si,es
	.enter
	;
	; First find out the size of the block.
	;
	mov	ax, cx				;block handle
	call	VMInfo				;cx = size of block
						;di = user ID of block
						;ax is destroyed.
EC <	ERROR_C ERROR_VMTREE_DD_UNEXPECTED_ERROR		>

	;
	; Allocate the new block.
	;
	push	cx				;block size
	mov	ax, cx				;size to alloc
	mov 	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			;bx = handle of new block
	pop	cx				;recover the block size.
	jc	exit
	mov	es, ax				;es = segment of new block

	;
	; Copy the data over.  cx = block size.
	;
	push	cx, di				;save block size and user ID
	clr	si, di				;ds:si = vm block,
						;es:di = dest. in new block
	rep	movsb
	
	;
	; Return the new block unlocked.
	;
	call	MemUnlock			;bx = handle of unlocked block
	pop	cx, di				;return the block size and
						;  user ID of block.

exit:
	.leave
	ret
VMTBlockInfoAndCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTDBInfoAndCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the DB item into a block, and find the size of the
		DB item.
CALLED BY:	VMTreeReadNextBlock
PASS:		bx	= VM file
		ax	= group 
		dx	= item
		ds	= segment of locked group block.
RETURN:		carry clear if okay:
			bx 	= handle of new block containing copied 
				  DB item
			cx	= size of DB item
		else carry set if not enough memory:
			bx, cx are destroyed.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTDBInfoAndCopy	proc	near
	uses	ax,dx,ds,si,es,di
	.enter
	mov	di, dx				;di = item
	call	DBLock				;*es:di = database item.
	;
	; get the db item's size.
	;
	ChunkSizeHandle	es, di, cx		;cx = size
	segmov	ds, es				;*ds:di = db item.
	;
	; allocate a block to copy the db item.
	;
	push	cx				;preserve item size
	mov	ax, cx				;
	add	ax, size VMChainTree		;size to alloc
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			;bx = handle of new block
	pop	cx				;recover the block size
	jc	exit				;not enough memory
	mov	es, ax				;es = segment of new block
	;
	; Fill in the fake VMChainTree to indicate we're a DB block. 
	; A tree count of -1 indicates that this is not a tree block, but
	; that DB data comes next.
	;
	mov	es:[VMCL_next], VM_CHAIN_TREE
	mov	es:[VMCT_offset], size VMChainTree
	mov	es:[VMCT_count], -1
	;
	; copy the data over
	;
	mov	si, ds:[di]			;ds:si = item
	mov	di, size VMChainTree		;es:di = dest. in new block
	push	cx				;save so we can return the size
	rep	movsb
	segmov	es, ds				;es = segment of item block
	call	DBUnlock
	call	MemUnlock			;return new block unlocked
	pop	cx				;return the block size...
	add	cx, size VMChainTree		; ... plus the tree header.
	
exit:
	.leave
	ret
VMTDBInfoAndCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTPushVMChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push each child of the VM tree block onto the stack,
		*from right to left*.

CALLED BY:	VMTreeReadNextBlock
PASS:		ds	= segment of locked VM tree block
		bx	= stack handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTPushVMChildren	proc	near
	uses	ax,cx,dx,ds,si
	.enter
	mov	cx, ds:[VMCT_count]
	tst	cx				;skip empty trees
	jz	exit
	mov	si, ds:[VMCT_offset]		;first child ptr.
	;
	; Calculate offset of entry for the last child of the tree, because
	; we start from the end to push right to left.  Each entry in
	; the list is a dword, so:
	; 	offset of last child link = (cx - 1) * size dword + si
	; 
	mov	ax, cx
	dec	ax
	shl	ax
	shl	ax
	add	si, ax				;si = last child 

	; cx = child count
	; bx = stack handle
	; ds:si = entry for last child
treeLoop:
	movdw	dxax, ds:[si]
	tstdw	dxax
	jz	nullChild
	call	VMTSPush
nullChild:
	sub	si, size dword
	loop	treeLoop
exit:
	.leave
	ret
VMTPushVMChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeReadComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signals to the data driver that the transmission of the
		message body is complete. The driver may free the state
		information it allocated in DR_MBDD_READ_INITIALIZE.

CALLED BY:	DR_MBDD_READ_COMPLETE			
PASS:		si	= token returned by DR_MBDD_READ_INITIALIZE
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeReadComplete	proc	far
readStateBlockHan	local	hptr
	uses	ax,bx,ds,si,di
	.enter
	call	VMTGetReadOrWriteStateLocked	;ds:di = read state
	mov	readStateBlockHan, bx
	;
	; Close the VM file containing the message.
	;
	mov	bx, ds:[di].VMTRS_vmFile
	call	MailboxDoneWithVMFile
	;
	; Free the stack, which might not be empty if the caller didn't finish
	; reading all the blocks.
	;
	mov	bx, ds:[di].VMTRS_stack
	call	VMTSFree
	;
	; Free the read state
	;
	mov	ax, si
	call	LMemFree
	;
	;
	; unlock readWriteStateBlock, which contains the read state.
	;
	mov	bx, readStateBlockHan
	call	MemUnlockShared
	.leave
	ret
VMTreeReadComplete	endp

Movable 	ends

