COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VM Tree Data Driver
FILE:		vmtreeWrite.asm

AUTHOR:		Chung Liu, Jul  6, 1994

ROUTINES:
	Name			Description
	----			-----------
	VMTreeWriteInitialize
	VMTAllocWriteStateLocked
	VMTreeWriteNextBlock
	VMTAddDBItem
	VMTAddBlock
	VMTLinkBlock
	VMTAddAndPushChain
	VMTAddAndPushTree
	VMTreeWriteComplete
	VMTFindAndFixupHugeArrays
	VMTWriteCancel
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 6/94   	Initial revision


DESCRIPTION:
	Code for DR_MBDD_WRITE_*.

	The blocks we receive are stored in a VM file obtained from the
	Mailbox Library's VM Store.  

	A dword stack is allocated for each write-state.  See the initial
	state of the stack below.

	As we receive each block, we figure out how many children the
	block is expected to have.  Then, for each child from RIGHT to
	LEFT, we push onto the stack the dword consisting of the VM block 
	handle of the current block, and an offset into the block of
	where the link is to the child block.  

	Then, we pop a dword from the stack, and place our VM block handle
	or DBGroupAndItem into the VM block and offset popped from the 
	stack.  This way the blocks of the VM Tree are linked together,
	reconstructed from how they were sent from the DR_MBDD_READ_* side.
	
	When we initialize the stack, we create a dummy VM block of dword
	size, and push that VM block and offset 0 onto the stack.  This
	is used to hold the head block of the VM tree.

	When the write is complete, we check if the whole tree is a
	HugeArray.  If so, it needs to have its pointers btw. VM blocks
	fixed up.  Also, the dummy block needs to be freed.

	$Id: vmtreeWrite.asm,v 1.1 97/04/18 11:41:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeWriteInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the first call issued by the transport driver before
		receiving a message. It effectively passes to the receiving
		data driver the values that were returned from the sending
		data driver's DR_MBDD_READ_INITIALIZE function. As for
		reading, the driver is expected to allocate some state
		information to track the transaction.

		The driver returns a suitable 16-bit token for the transport
		driver to identify the message body more efficiently on
		subsequent calls.

CALLED BY:	DR_MBDD_WRITE_INITIALIZE
PASS:		bx	= number of blocks in the message
		cxdx	= number of bytes in the message body
RETURN:		carry set if body could not be accessed:
			ax	= MailboxError
		carry clear if ok:
			si	= token to pass to subsequent calls

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Allocate a write state.
	Call the VM store to get a file in which to store the message.
	Allocate a stack.
	
	XXX: should use cx:dx to see if there's enough room to store
	the message before we even start.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeWriteInitialize	proc	far
stateBlockHandle	local	hptr
	uses	bx,cx,dx,ds,di
	.enter
	push	ax				;preserve if no error
	push	bx
	call	VMTAllocWriteStateLocked	;*ds:di = write state
	mov	stateBlockHandle, bx
	pop	bx				;number of blocks in msg.
	mov	si, ds:[di]			;ds:si = write state.
	;
	; Ask the mailbox library for a file in which to store the 
	; incoming message.
	;
	call	MailboxGetVMFile		;bx = VMFileHandle
	jc	getVMFileError		
	mov	ds:[si].VMTWS_vmFile, bx
	;
	; Allocate a dummy VM block, the address of which we can push
	; on the stack, so that the handle of the head block of the VM 
	; tree will be held there.  
	;
	mov	ax, VMTREE_VM_USER_ID
	mov	cx, size VMTreeDummyBlock
	call	VMAlloc
	mov	ds:[si].VMTWS_holdHeadBlock, ax
	;
	; Also need a stack
	;
	call	VMTSAlloc
	mov	ds:[si].VMTWS_stack, bx
	;
	; Initialize the stack.
	;
	mov	dx, ax
	mov	ax, offset VMTDB_vmChain
	call	VMTSPush
	;
	; We survived, so restore ax.
	;
	pop	ax
	mov	si, di				;use chunk handle as token.
exit:
	;
	; unlock the segment in which the write state resides.
	;
	mov	bx, stateBlockHandle
	call	MemUnlockShared
	
	.leave
	ret

getVMFileError:
	pop	ax
	mov	ax, ME_CANNOT_CREATE_MESSAGE_FILE
	jmp	exit
VMTreeWriteInitialize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTAllocWriteStateLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a VMTreeWriteState chunk in the readWriteStateBlock
		segment. Returns with the segment of the chunk locked.
		Caller must unlock the segment when done accessing the 	
		chunk
CALLED BY:	VMTreeWriteInitialize
PASS:		nothing
RETURN:		bx	= block handle to unlock when done accessing
		*ds:di	= VMTreeWriteState
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTAllocWriteStateLocked	proc	near
	uses	ax,cx
	.enter
	mov	bx, handle VMTreeState
	call	MemLockExcl
	mov	ds, ax
	mov	cx, size VMTreeWriteState
	call	LMemAlloc
	mov	di, ax			; di = handle of VMTreeWriteState chunk
	call	MemDowngradeExclLock
	.leave
	ret
VMTAllocWriteStateLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeWriteNextBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the next block of data to the message body. The
		driver may either consume the data block, taking responsibility
		for it and its handle, or it may allow the caller to free the
		block on return.

CALLED BY:	DR_MBDD_WRITE_NEXT_BLOCK
PASS:		si	= token returned by DR_MBDD_WRITE_INITIALIZE
		dx	= extra word returned by DR_MBDD_READ_NEXT_BLOCK on
			  sending machine (in this case, the user ID of the
			  block sent over.)
		cx	= number of bytes in the block
		bx	= handle of data block
RETURN:		carry set on error:
			ax	= MailboxError
		carry clear if ok:
			ax	= 0 if data block has been consumed. non-zero
				  if block should be freed by caller.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeWriteNextBlock	proc	far
dataBlock	local	hptr		push	bx
blockSize	local	word		push	cx
stateBlock	local	hptr
	uses 	bx,cx,dx,si,di,ds,es
	.enter
	call	VMTGetReadOrWriteStateLocked	;ds:di = write state
	mov	stateBlock, bx
	mov	bx, dataBlock	
	mov	ax, ds:[di].VMTWS_vmFile
	mov	cx, ds:[di].VMTWS_stack
	;
	; Depending on what type of block we have, determine what to
	; push on the stack.  Remember that DB items are disguised as
	; tree blocks with VMCT_count = -1.
	;
	push	ax
	call	MemLock
	mov	ds, ax
	pop	ax
	;
	; If VMCL_next = VM_CHAIN_TREE, we have either a tree block or a
	; disguised DB item.  If VMCL_next = 0, we have a leaf block.
	;
	cmp	ds:[VMCL_next], VM_CHAIN_TREE
	je	doTreeOrDBItem

	cmp	ds:[VMCL_next], 0
	call	MemUnlock			;flags preserved
	je	doLeaf
	jmp	doChain

doTreeOrDBItem:
	cmp	ds:[VMCT_count], -1
	call	MemUnlock			;flags preserved
	je	doDB
	jmp	doTree
	
doDB:
	mov	dx, cx				;dx = stack handle
	mov	cx, blockSize
	call	VMTAddDBItem
	mov	ax, 1				;block was NOT consumed.
	jmp	exit
doLeaf:
	call	VMTAddBlock
	clr	ax				;block was consumed.
	jmp	exit
doChain:
	call	VMTAddAndPushChain
	clr	ax				;block was consumed.
	jmp	exit
doTree:
	call	VMTAddAndPushTree	
	clr	ax				;block was consumed.
exit:
	clc
	mov	bx, stateBlock
	call	MemUnlockShared
	.leave
	ret
VMTreeWriteNextBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTAddDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a DB item from the data in the memory block, and
		link it to the VM tree.  The DB item is allocated ungrouped
		in the same VM file as the rest of the tree.

CALLED BY:	VMTreeWriteNextBlock
PASS:		ax	= VMFileHandle to add block
		bx	= handle of block to add to VM tree.  Block data
			  only starts at offset size VMChainTree, because 
			  the data came disguised as a VM tree.
		cx	= size of block
		dx	= stack handle

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTAddDBItem	proc	near
dbGroupAndItem		local	dword
	uses	ax,bx,cx,dx,ds,es,si,di
	.enter
	; 
	; ^hbx includes a VMChainTree before the DB item data, so adjust
	; the count accordingly.
	;
	sub	cx, size VMChainTree
	;
	; Allocate a DB item in the same VM file as the tree.  Then
	; lock the item down, so we can copy data to it.
	; 
	push	ax				;preserve VM file
	push	bx				;preserve data block handle
	mov	bx, ax				;bx = VM file of tree
	mov	ax, DB_UNGROUPED
	call	DBAlloc				;ax:di = group and item
	movdw	dbGroupAndItem, axdi
	call	DBLock				;*es:di = item
	mov	di, es:[di]			;es:di = item
	pop	bx				;bx = data block handle
	;
	; Lock down the data block, so we can copy the data to the db item.
	;
	call	MemLock
EC <	ERROR_C	ERROR_BLOCK_IS_DISCARDED_AND_I_DONT_KNOW_WHY	>
	mov	ds, ax
	mov	si, size VMChainTree			;ds:si = data
	;
	; Copy the data. cx = block size.
	;
	rep	movsb
	;
	; Unlock the DB item and the memory block.
	;
	call	DBDirty
	call	DBUnlock
	call	MemUnlock
	;
	; link the DB item to the VM tree.
	;
	pop	ax				;ax = VM file handle
	mov	bx, dx				;bx = stack handle
	movdw	cxdx, dbGroupAndItem
	call	VMTLinkBlock
	.leave
	ret
VMTAddDBItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTAddBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attach block of memory to the VM file, linking it to the
		rest of the VM tree.

CALLED BY:	VMTreeWriteNextBlock, VMTAddAndPushChain, VMTAddAndPushTree
PASS:		ax	= VMFileHandle to add block
		bx	= handle of block to add to VM tree
		cx	= stack handle
		dx	= user ID for the block 
RETURN:		ax	= new VM block
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTAddBlock	proc	near
	uses	bx,cx,dx,ds,si
	.enter
	;
	; use the VMAttach call to turn the memory block into a VM
	; block beloging to the VM file.
	;
	push	ax, cx				;save VM file and stack.
	mov	cx, bx				;cx = mem handle to attach
	mov	bx, ax				;bx = vm file handle
	clr	ax				;alloc new VM block.
	call	VMAttach			;ax = vm block
	mov	cx, dx				;cx = user ID
	call	VMModifyUserID
	mov	cx, ax				;cx = vm block
	pop	ax, bx				;ax = VM file handle
						;bx = stack handle
	;
	; Link our new VM block to the top item on the stack.
	; ax = VM file handle, bx = stack handle
	;
	clr	dx
	call	VMTLinkBlock
	mov	ax, cx				;return ax = new VM block
	.leave
	ret
VMTAddBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTLinkBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Link the passed VM block or DB item to the VM tree.

CALLED BY:	VMTAddBlock, VMTAddDBItem
PASS:		cx:dx	= VM block handle (dx = 0) or DB item (cx = group,
			  dx = item) to link to VM tree.
		bx	= stack handle
		ax	= VM file handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTLinkBlock	proc	near
vmFile		local	hptr		push 	ax
vmBlock		local	dword		push	cx, dx
vmMemHandle	local	hptr
	uses	ax,bx,cx,dx,ds,si
	.enter
	;
	; Link our new VM block to the top item on the stack.
	;
	call 	VMTSPop				;dx:ax = element
EC <	ERROR_C ERROR_VMTREE_DD_UNEXPECTED_ERROR		>
	;
	; dx = VM block handle of soon-to-be parent of new vm block
	; ax = offset in VM block of dword link which should be set to
	;      the new vm block.
	; Get the parent locked down, so we can set the link.
	;
	push	ax				;save offset into parent
	push	bp				;destroyed by VMLock
	mov	bx, vmFile			;parent is in same vm file
	mov	ax, dx				;ax = vm block of parent
	call	VMLock
	mov	cx, bp				;needed for VMUnlock
	pop	bp
	mov	vmMemHandle, cx			;needed for VMUnlock
	mov	ds, ax				;ds = segment of new parent
	pop	si				;si = offset into parent
	;
	; Set the link.  If si=0, then we're dealing with the word size link
	; of a chain block; otherwise, we have the dword link of a tree block.
	;
	movdw	axbx, vmBlock			;ax:bx = the child to be linked
	tst	si				
	jz	chainLink
	movdw	ds:[si], axbx			;set the tree link
	jmp	unlockIt
chainLink:
	mov	ds:[si], ax
unlockIt:
	;
	; We don't need the parent anymore. Mark it dirty so our changes
	; are kept.
	;
	push	bp
	mov	bp, vmMemHandle
	call	VMDirty
	call	VMUnlock
	pop	bp

	.leave
	ret
VMTLinkBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTAddAndPushChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the chain memory block to the VM tree, and push
		the link to the VM block's child on the stack.

CALLED BY:	VMTreeWriteNextBlock
PASS:		ax	= VMFileHandle to add block
		bx	= handle of block to add to VM tree
		cx	= stack handle
		dx	= user ID for the block
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTAddAndPushChain	proc	near
	uses	ax,bx,dx,ds
	.enter
	;
	; Zero out the VMCL_next field, so that if anything messes up
	; during the write-next calls, we'll be able to cleanup.
	;
	push	ax				; save the file handle
	call	MemLock
	mov	ds, ax
	clr	ds:[VMCL_next]
	call	MemUnlock
	pop	ax
	call	VMTAddBlock
	;
	; Push the VM block of the new block, and the offset of the
	; link to the child.
	;
	mov	dx, ax				;dx = new block
	mov	bx, cx				;bx = stack handle
	mov	ax, offset VMCL_next		;ax = offset into block of
						;  link to child.
	call	VMTSPush
	.leave
	ret
VMTAddAndPushChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTAddAndPushTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the tree memory block to the VM tree, and push
		the link to the VM block of each child on the stack,
		from right to left.

CALLED BY:	VMTreeWriteNextBlock
PASS:		ax	= VMFileHandle to add block
		bx	= handle of block to add to VM tree
		cx	= stack handle
		dx	= user ID for the block 
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTAddAndPushTree	proc	near
vmFileHptr		local	hptr	push	ax
blockHptr		local	hptr
	uses	ax,bx,cx,dx,ds,si
	.enter

	;
	; Add the block to the VM file.
	;
	call	VMTAddBlock
	mov	dx, ax				;dx = new vm block

	;
	; Lock the block.
	;
	push	bp
	mov	bx, ss:[vmFileHptr]
	call	VMLock				; ax = sptr, bp = hptr
	mov	ds, ax
	mov_tr	ax, bp
	pop	bp
	mov	ss:[blockHptr], ax		; there's a slight chance that
						; the mem handle is changed,
						; e.g. if memory is low
EC <	cmp	ds:[VMCL_next], VM_CHAIN_TREE			>
EC <	ERROR_NE ERROR_THIS_VM_BLOCK_IS_NOT_A_TREE		>

	mov	bx, cx				;bx = stack handle
	;
	; To push from right to left, we start at the last child.
	; Offset of last child link = (treeCount - 1) * size dword + treeOffset
	;
	mov	cx, ds:[VMCT_count]		;cx = number of children
	jcxz	exit				;cx = number of children
	mov	ax, cx
	dec	ax
	shl	ax
	shl	ax				; ax *= size dword
	add	ax, ds:[VMCT_offset]		; ax = offset of last link
EC <	add	ax, size dword - 1					>
EC <	Assert	fptr, dsax						>
EC <	sub	ax, size dword - 1					>

	;
	; dx:ax = last link, cx = number of children.
	; Skip a link if the original link on the sending side was a null link,
	; which mean no VM block was associated with that link.
	;
	; We also zero out the links to children blocks, so that if something
	; fails during the write-next calls, we'll be able to clean up.
	;
pushLoop:
	mov	si, ax
	tstdw	ds:[si]
	jz	nextLink			; skip if this was a null link
	call	VMTSPush	
	clrdw	ds:[si]				; zero out the link
nextLink:
	sub	ax, size dword
	loop	pushLoop
exit:
	;
	; Unlock the VM block.
	;
	push	bp
	mov	bp, ss:[blockHptr]
	call	VMUnlock
	pop	bp

	.leave
	ret
VMTAddAndPushTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeWriteComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signals to the data driver that the reception of the
		message body is complete. The driver may free the state
		information it allocated in DR_MBDD_WRITE_INITIALIZE.

CALLED BY:	
PASS:		si	= token returned by DR_MBDD_WRITE_INITIALIZE
		cx:dx	= pointer to buffer for app-ref of body (size 
			  determined by MBDDI_appRefSize).
RETURN:		carry set if message body couldn't be commited to
		disk:
			ax	= MailboxError
		carry clear if message body successfully committed.
			cx:dx	= filled with app-ref to the data.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If huge array, need to call FixupHugeArrayChain (RESTRICTED GLOBAL).

	If there are any blocks left on the stack, then 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeWriteComplete	proc	far
appRef			local	dword		push	cx, dx
stateToken		local	word		push	si
stateBlock		local	hptr
dummyHandle		local	word
chainHead		local	dword
	uses	bx,cx,dx,si,di,ds,es
	.enter
	push	ax				;preserve if no error
	call	VMTGetReadOrWriteStateLocked	;ds:di = write state
	mov	stateBlock, bx
	;
	; Obtain the head block of the VM tree, and get rid of the
	; dummy block we allocated to hold the handle of the head block.
	;
	mov	bx, ds:[di].VMTWS_vmFile
	mov	ax, ds:[di].VMTWS_holdHeadBlock
	push	bp
	call	VMLock
	mov	dx, bp
	pop	bp
	mov	dummyHandle, dx
	mov	es, ax				;es = segment of dummy block
	movdw	chainHead, es:[VMTDB_vmChain], dx
	;
	; Free the dummy VM block
	;
	push	bp
	mov	bp, dummyHandle
	call	VMUnlock
	pop	bp
	mov	ax, ds:[di].VMTWS_holdHeadBlock
	call	VMFree
	;
	; The stack should be empty, otherwise there was something wrong
	; with the sequence of write-next calls.
	;
	; bx = VM file handle
	mov	ax, bx				;save vm file in ax
	mov	bx, ds:[di].VMTWS_stack
	call	VMTSGetCount
	mov	bx, ax				;bx = vm file, dx = vm block
	cmp	cx, 0
	jne 	stackMismatchError

	;
	; Look through the entire tree searching for huge arrays that need
	; fixing up.  The special case is that if the head is a DB item,
	; then we don't have to check at all, because then there's no
	; possibility of there being a huge array.
	; 
	movdw	dxax, chainHead
	tst	ax
	jnz	fillAppRef			;dx:ax = DB item
	mov	ax, dx				;ax = head of VM tree
	push	ax, di
	call	VMTFindAndFixupHugeArrays
	pop	ax, di

fillAppRef:
	;
	; We just need the VM file handle and the VM block handle of the
	; head of the VM tree to fill in the app-ref.
	;
	movdw	essi, appRef			;es:si = app-ref buffer
	movdw	es:[si].VMTAR_vmChain, chainHead, ax
	mov	es:[si].VMTAR_vmFile, bx
	;
	; This is a good point to flush all changes to the disk.
	;
	call	VMUpdate
	jc	updateError
	; call	MailboxDoneWithVMFile
	;
	; Get rid of the stack and write state.
	;
	mov	bx, ds:[di].VMTWS_stack
	call	VMTSFree
	mov	ax, stateToken
	call	LMemFree
	mov	bx, stateBlock
	call	MemUnlockShared
	pop	ax				;we survived, so restore ax
exit:
	.leave
	ret

updateError:
	pop	ax
	mov	ax, ME_CANNOT_SAVE_MESSAGE_FILE	
	jmp	exit

stackMismatchError:
	; bx = vm file, chainHead = start of chain
	; ds:di = write state
	pop	ax				;don't need to restore it.
	push	bp
	movdw	axbp, chainHead
	call	VMFreeVMChain
	pop	bp
	call	MailboxDoneWithVMFile

	mov	bx, ds:[di].VMTWS_stack
	call	VMTSFree
	mov	ax, stateToken
	call	LMemFree
	mov	bx, stateBlock
	call	MemUnlock

	mov	ax, ME_MESSAGE_BLOCKS_ARE_MISMATCHED	
	stc
	jmp	exit
VMTreeWriteComplete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTFindAndFixupHugeArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recursive routine to run through the VM tree looking for
		chains with a huge array directory block in them and fix up
		the rest of that chain as a huge array.

CALLED BY:	(INTERNAL) VMTreeWriteComplete, self
PASS:		^vbx:ax	= head of chain to check
RETURN:		nothing
DESTROYED:	ax, cx, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTFindAndFixupHugeArrays proc	near
	.enter
	;
	; Tail-recursing loop to run down a regular chain. We support having
	; a huge array *anywhere* in a chain, but it has to be the tail end
	; of the chain.
	; 
again:
	;
	; See if the current block is a huge array directory block.
	; 
	push	ax
	call	VMInfo
EC <	ERROR_C ERROR_VMTREE_INVALID_HEAD_BLOCK				>
   	pop	ax
	cmp	di, SVMID_HA_DIR_ID		;check for HugeArrayDir
	jne	nextBlock
	;
	; It is a huge array. Fix up the rest of the chain as a huge array
	; and boogie.
	; 
	call	FixupHugeArrayChain
done:
	.leave
	ret

nextBlock:
	;
	; Current block isn't a huge array, so advance to the next block in
	; the chain.
	; 
	push	ds, bp
	call	VMLock
	mov	ds, ax
	mov	ax, ds:[VMCL_next]
	cmp	ax, VM_CHAIN_TREE
	je	doTree

processAX:
	;
	; Release the current block (bp = mem handle)
	; 
	call	VMUnlock
	pop	ds, bp
	;
	; If there is a next block, tail-recurse.
	; 
	tst	ax
	jnz	again
	jmp	done

doTree:
	;
	; Hit a tree block. Load up the number of children and the start of
	; the pointer array.
	; 
	mov	cx, ds:[VMCT_count]
	mov	si, ds:[VMCT_offset]
treeLoop:
	;
	; Fetch and test the low word to see if it's a VM block or a DB item.
	; 
	lodsw
	tst	ax
	;
	; Fetch the high word in case it is a VM block (or to skip it if it's
	; a DB item...)
	; 
	lodsw
	jnz	nextTreeChain		; jump if DB item
	tst	ax			; see if high word is zero
	jnz	doTreeChain		; jump if not a null branch

nextTreeChain:
	;
	; Advance to the next child chain in the tree (si already advanced by
	; lodsw)
	; 
	loop	treeLoop

	mov_tr	ax, cx			; ax <- 0 so we boogie after unlock
	jmp	processAX

doTreeChain:
	;
	; Recurse on this child chain (ax is handle, of course)
	; 
	push	cx, si
	call	VMTFindAndFixupHugeArrays
	pop	cx, si
	jmp	nextTreeChain
VMTFindAndFixupHugeArrays endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTreeWriteCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For some reason, the attempt to write the message has
		failed.  Free the blocks that already have been
		processed by write-next.

CALLED BY:	DR_MBDD_WRITE_FAILED
PASS:		si	= token returned by DR_MBDD_WRITE_INITIALIZE
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	10/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTreeWriteCancel	proc	far
stateBlock	local	hptr
dummyHandle	local	word
chainHead	local	dword
	uses	ax,bx,cx,dx,ds,di
	.enter
	call	VMTGetReadOrWriteStateLocked		;ds:di = write state
	mov	stateBlock, bx
	;
	; Obtain the head block of the VM tree, and get rid of the
	; dummy block we allocated to hold the handle of the head block.
	;
	mov	bx, ds:[di].VMTWS_vmFile
	mov	ax, ds:[di].VMTWS_holdHeadBlock
	push	bp
	call	VMLock
	mov	dx, bp
	pop	bp
	mov	dummyHandle, dx
	mov	es, ax				;es = segment of dummy block
	movdw	chainHead, es:[VMTDB_vmChain], ax
	;
	; Free the dummy VM block
	;
	push	bp
	mov	bp, dummyHandle
	call	VMUnlock
	pop	bp
	mov	ax, ds:[di].VMTWS_holdHeadBlock
	call	VMFree
	;
	; Free the partial tree we already have.  The links to blocks
	; that weren't received yet are set to zero, so this should work.
	;
	push	bp
	movdw	axbp, chainHead
	call	VMFreeVMChain
	pop	bp
	;
	; Free the rest of the stuff...
	;
	call	MailboxDoneWithVMFile

	mov	bx, ds:[di].VMTWS_stack
	call	VMTSFree
	mov	ax, si				;state token
	call	LMemFree
	mov	bx, stateBlock
	call	MemUnlockShared

	.leave
	ret
VMTreeWriteCancel	endp


Movable		ends



