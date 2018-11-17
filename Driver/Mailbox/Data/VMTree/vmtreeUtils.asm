COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Clavin
MODULE:		VM Tree Data Driver
FILE:		vmtreeUtils.asm

AUTHOR:		Chung Liu, Jul  5, 1994

ROUTINES:
	Name			Description
	----			-----------
	VMTGetReadOrWriteStateLocked
	VMTInfoVMChain
	VMTGetVMTreeInfo
	VMTGetVMBlockInfo
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 5/94   	Initial revision


DESCRIPTION:
	Home of stuff...
		

	$Id: vmtreeUtils.asm,v 1.1 97/04/18 11:41:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTGetReadOrWriteStateLocked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the chunk handle for a VMTreeReadState or a 
		VMTreeWriteState in readWriteStateBlock, return the
		read or write state with the segment locked.  The caller
		is responsible for MemUnlockShared the segment

CALLED BY:	VMTreeReadNextBlock, VMTreeWriteNextBlock, etc.
PASS:		si	= read or write state (chunk handle)
RETURN:		*ds:si 	= read or write state
		ds:di	= read or write state
		bx	= handle to unlock when done accessing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTGetReadOrWriteStateLocked	proc	near
	uses	ax
	.enter
	mov	bx, handle VMTreeState
	call	MemLockShared
	mov	ds, ax				;*ds:si = read state
	mov	di, ds:[si]
	.leave
	ret
VMTGetReadOrWriteStateLocked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTInfoVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of blocks in the VM Chain, and the
		total size of the chain in bytes.

CALLED BY:	VMTreeReadInitialize
PASS:		bx	= VM file
		ax:cx	= VM chain
RETURN:		carry set if chain is invalid:
			bx, cx, dx = destroyed
		carry clear if chain is valid:
			bx	= number of blocks
			cx:dx	= size of chain in bytes
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTInfoVMChain	proc	near
	mov	dx, cx
	mov	cx, ax
	call	VMTGetVMTreeInfo
	ret
VMTInfoVMChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTGetVMTreeInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain size and block count of VM Chain.

CALLED BY:	VMTInfoVMChain
PASS:		cx:dx	= VM block handle (dx = 0) or cx:dx = DB group
			  and item.
		bx	= VM file handle.
RETURN:		carry set if tree is invalid
			bx, cx, dx = destroyed
		carry clear if tree is valid:
			bx	= number of blocks
			cxdx	= size in bytes
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Traverse the tree, calling adding up number of blocks and size
	of each block.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	6/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTGetVMTreeInfo	proc	near
blockCount	local	word
totalBytes	local	dword
	uses	ax,ds,si,es,di
	.enter

	clr	ax
	movdw	totalBytes, axax
	mov	blockCount, ax
	
	tst	dx
	jnz	dbItem

	;--------------------
	; Loop for summing size of a single chain, which may terminate in a
	; tree block or a leaf
chainLoop:
	call	VMTGetVMBlockInfo
	jc	done
	
	; Lock down the block so we can decide how to proceed.
	mov	si, bp
	mov	ax, cx				;cx = VM block
	call	VMLock
	xchg	si, bp				;si = mem handle of vm block
	mov	ds, ax				;ds = segment of VM block

	; Distinguish btw chain, tree, leaf, or db group and item.
	mov	ax, ds:[VMCL_next]
	cmp	ax, VM_CHAIN_TREE
	je	tree				;handle tree block.

	; For the other options (leaf, chain), we don't need
	; to keep the block locked.
	call	unlockSI

	tst_clc	ax
	jz	exit

	;
	; Block is a chain link.  Size and block count is ours plus that
	; of ax = VMCL_next.  Also, bx = VM file handle, cx = VM block handle.
	;
	mov_tr	cx, ax
	jmp	chainLoop			; tail-recurse to process the
						;  rest of the chain
	;--------------------
	; Get size of the DB item, claiming it's a single block
dbItem:
	;
	; bx = VM file, cx = DB group, and dx = DB item.  
	; Return the size of the DB item, and a block count of 1.
	;
	mov	ax, cx				;ax = group
	mov	di, dx				;di = item
	call	DBInfo
	jc	done				;=> invalid item or group
	mov	dx, cx
	clr	cx				; (clears carry)
	mov	bx, 1				;we count as one block
	jmp	done

	;--------------------
	; Found a tree block in the chain, so sum the sizes of its subchains
tree:
	;
	; si = mem handle to VMUnlock
	; ds = segment of VM block
	;
	mov	di, ds:[VMCT_offset]
	mov	cx, ds:[VMCT_count]

treeLoop:
	push	bx, cx				;save VM file, count
	movdw	cxdx, ds:[di]			;cxdx <- subtree
	mov	ax, cx
	or	ax, dx
	jz	nextChild

	call	VMTGetVMTreeInfo		;cx:dx = byte count
						;bx = block count
	jc	popDone				;=> error in subtree, so stop

	adddw	totalBytes, cxdx
	add	blockCount, bx

nextChild:
	pop	bx, cx				;bx = VM file, cx = count
	add	di, size dword
	loop	treeLoop
	;
	; unlock the block
	;
	call	unlockSI

	;--------------------
exit:
	;
	; set the return values
	;
	movdw	cxdx, totalBytes
	mov	bx, blockCount
	clc
done:
	.leave
	ret

popDone:
	pop	bx, cx
	call	unlockSI
	stc
	jmp	done

;----
unlockSI:
	xchg	bp, si
	call	VMUnlock
	mov	bp, si
	retn
VMTGetVMTreeInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMTGetVMBlockInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convenience stub to get the dword size of a VM block.

CALLED BY:	VMTGetVMTreeInfo
PASS:		bx	= VM file
		cx	= VM block
RETURN:		carry set if block is invalid
		carry clear if ok:
			totalBytes updated by the block size
			blockCount incremented
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMTGetVMBlockInfo	proc	near
	uses	ax, di, cx
	.enter	inherit	VMTGetVMTreeInfo
	mov_tr	ax, cx				;ax = VM block
	call	VMInfo				;cx = size of block.
EC <	WARNING_C	ILLEGAL_VM_BLOCK_HANDLE			>
	jc	done
	add	totalBytes.low, cx
	adc	totalBytes.high, 0
	inc	blockCount
	clc
done:
	.leave
	ret
VMTGetVMBlockInfo	endp


Movable		ends
