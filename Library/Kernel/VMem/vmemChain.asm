COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel VM Manager -- High-level interface routines
FILE:		vmemHigh.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------
    GLB	VMCopyVMChain		Copy a VM chain from one file to another
    GLB	VMFreeVMChain		Free a VM chain
    GLB	VMCompareVMChains	Compare two VM chains
    GLB VMInfoVMChain		Return size of chain, and number of blks


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/91		Initial revision

DESCRIPTION:
	This file contains routines to manage VM chains

	$Id: vmemChain.asm,v 1.1 97/04/05 01:16:03 newdeal Exp $

------------------------------------------------------------------------------@

VMUtils	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMCopyVMChain

DESCRIPTION:	Copy a VM chain from one file to another.

		The VM chain routines now also take DB items (VM chains
		have BP=0, while DB items have BP = item).

CALLED BY:	GLOBAL

PASS:
	bx - source file
	ax:bp - source VM chain
	dx - destination file

RETURN:
	ax:bp - destination chain created

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		HugeArrays are stored in chains, but there are other VMBlock
		handles scattered in the blocks (references to other blocks).
		These need to be handled specially by the VMChain code.  To
		mark a chain as a HugeArray, the low bit of the handle stored
		in word zero of the block is set.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version
	jim	6/92		changed to nuke option to force-set userID

------------------------------------------------------------------------------@

VMCopyVMChain	proc	far	uses  si, di, ds, es
	.enter

	call	CopyTreeLow

	.leave
	ret

VMCopyVMChain	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyTreeLow

DESCRIPTION:	Low level routine to copy a chain or a tree

CALLED BY:	VMCopyVMChain

PASS:
	VM override set set to 0
	bx - source file
	ax:bp - source VM chain
	dx - destination file

RETURN:
	ax:bp - destination chain created

DESTROYED:
	si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		HugeArrays are stored in chains, but there are other VMBlock
		handles scattered in the blocks (references to other blocks).
		These need to be handled specially by the VMChain code.  To
		mark a chain as a HugeArray, the low bit of the handle stored
		in word zero of the block is set.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	jim	6/92		changed to nuke option to force-set userID

------------------------------------------------------------------------------@
CopyTreeLow	proc	near

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	tst	bp			;bp = 0 ==> VM, bp != 0 ==> LMem
	LONG jnz copyDBItem

	push	ax
	call	VMLock
	mov	ds, ax
	mov	ax, ds:[VMCL_next]
	cmp	ax, VM_CHAIN_TREE
	call	VMUnlock
	jz	copyTree

	; this is not a tree -- use the standard procedure

	tst	ax
	jz	atEnd

	; call ourself recursively to copy the rest of the chain -- then link
	; this block to the rest of the chain

	clr	bp			;copy VM block, not DB item
	call	CopyTreeLow		;ax = destination block

atEnd:
	mov_tr	si, ax			;save rest of chain link
	pop	ax

	; copy this block

	call	CopyVMBlock
	mov	es:[VMCL_next], si
	call	VMUnlock

	; check to see if this is a HugeArrayDirectory block, in which case
	; we have some more work to do.  HugeArrays store VM block handles
	; all over the place, and we'll need to fixup those handles.  Check
	; the UserID for the block for SVMID_HA_DIR_ID.

	push	ax, cx, di		; save trashed regs
	xchg	bx, dx			; get dest file handle in bx
	call	VMInfo
	xchg	bx, dx
	cmp	di, SVMID_HA_DIR_ID	; check for HugeArrayDir block
	pop	ax, cx, di		; restore regs
	jne	done
	xchg	bx, dx
	call	FixupHugeArrayChain	; fix the block links, bx.ax -> dir
	xchg	bx, dx
done:
	clr	bp			;Clear BP to denote VM chain
exit:
	pop	di
	call	ThreadReturnStackSpace
	ret

copyTree:
	;
	;	bp = mem handle of source tree block
	;	(on stack) = VM block handle of source tree block
	;	bx = source file
	;	dx = dest file
	;
	pop	ax

	; this is a tree of VM blocks -- first copy the tree block

	call	CopyVMBlock		;ax = dest block, es = dest block
					;bp = mem handle of dest block

	mov	si, es:[VMCT_count]
	tst	si
	jz	treeDone
	mov	di, es:[VMCT_offset]

treeLoop:
	; ax = tree block, bp = tree block mem handle
	push	ax
	push	es:[di]			;save source chain to copy
	push	es:[di]+2
	call	VMUnlock		;unlock dest tree block
	pop	ax			;axbp = source chain to copy
	pop	bp

	tstdw	axbp
	jz	nullNode
	push	cx, si, di
	call	CopyTreeLow		;axbp = new chain
	pop	cx, si, di
nullNode:

	pushdw	axbp
	mov	bp, sp
	mov	ax, ss:[bp+4]		; ax <- tree block

	xchg	bx, dx			;bx = dest file, dx = source file
	call	VMLock			;lock dest tree block again
	xchg	bx, dx			;bx = source file, dx = dest file
	mov	es, ax
	popdw	es:[di]			; store new chain
	call	VMDirty			; must dirty here in case we branch
					;	back to treeLoop and unlock
	pop	ax			; ax <- tree block
	add	di, size dword
	dec	si
	jnz	treeLoop

treeDone:
	call	VMDirty
	call	VMUnlock		;unlock dest tree block
	clr	bp			;return 0 for low word
	jmp	exit

copyDBItem:
	push	cx
	mov	di, bp			;DI <- source item
	mov	bp, dx
	mov	cx, DB_UNGROUPED
	call	DBCopyDBItem
	mov	bp, di
	pop	cx
	jmp	exit

CopyTreeLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyVMBlock

DESCRIPTION:	Copy a VM block from one file to another

CALLED BY:	CopyTreeLow

PASS:
	bx - source file
	ax - source block
	dx - dest file

RETURN:
	ax - dest block (locked)
	es - dest block (locked)
	bp - dest block memory handle (dirty)

DESTROYED:
	di, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	jim	6/92		changed to nuke option to force-set userID

------------------------------------------------------------------------------@
CopyVMBlock	proc	near	uses cx, si
	.enter

	; lock the block to copy and get the user ID

	LoadVarSeg	es, si

	push	ax
	call	VMLock
	mov	si, {word}es:[bp].HM_flags	;si <- source flags
	mov	ds, ax			;ds = source
	pop	ax
	push	bp			;save source mem handle
	call	VMInfo			;cx = size, di = user ID

	xchg	bx, dx			;bx = dest file, dx = source file
;	mov_trash	ax, di		;ax = user ID
;do this after we've locked the block to prevent stuff happening if block gets
;written/read before we lock and copy in the source block (maybe only affects EC)
	clr	ax
	call	VMAlloc			;ax = new block handle
	push	ax

	call	VMLock			;lock dest
	andnf	si, mask HF_LMEM		;si <- HF_LMEM flag in source
	ornf	{word}es:[bp].HM_flags, si	;copy HF_LMEM flag to dest
	mov	es, ax
	pop	ax			;ax = VM block handle being copied
; update UID here
	push	cx
	mov	cx, di
	call	VMModifyUserID
	pop	cx

	clr	di
	shr	cx, 1			;cx = # words
	test	si, mask HF_LMEM	;lmem block?
	mov	si, di
	rep	movsw
	jz	notLMem			;branch if not lmem
	mov	es:LMBH_handle, bp	;stuff mem handle of dest
notLMem:

	mov	cx, bp			;cx = dest handle
	call	VMDirty			; must src dirty here, as block might
					;  have been written out between the
					;  VMAlloc and the VMLock...
	pop	bp
	call	VMUnlock		;unlock source
	mov	bp, cx			;bp = dest handle
	xchg	bx, dx			;bx = dest file, dx = source file

	call	VMDirty			;mark dest dirty, always

	.leave
	ret

CopyVMBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMCopyVMBlock

DESCRIPTION:	Copy a VM block to a new file

CALLED BY:	GLOBAL

PASS:
	bx - VM file
	ax - VM block handle
	dx - destination file handle

RETURN:
	ax - new block

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

VMCopyVMBlock	proc	far	uses di, ds, es, bp
	.enter

	call	CopyVMBlock
	call	VMUnlock		;unlock destination

	.leave
	ret

VMCopyVMBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMFreeVMChain

DESCRIPTION:	Free a VM chain

CALLED BY:	GLOBAL

PASS:
	bx - VM file (or override file set)
	ax:bp - VM chain

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

VMFreeVMChain	proc	far	uses ax, cx, si, di, bp, ds, es, dx
	.enter

EC <	call	ECVMCheckVMFile		; check bx parameter.	>

	;
	; Grab the file for the duration, so we can safely mess with
	; VMH_noCompress
	;
	push	bp
	call	EnterVMFileFar
	pop	bp

	;
	; Disable file compression until the entire VM chain has been freed.
	;
	mov	cl, ds:[VMH_compressFlags]
	or	cl, mask VMCF_NO_COMPRESS
	xchg	ds:[VMH_compressFlags], cl

	segxchg	es, ds			; es <- header, ds <- kdata
	call	FreeVMChainLow
	segxchg	es, ds			; ds <- header, es <- kdata

	;
	; Re-enable compression, if it was enabled before, and make sure the
	; file is properly compressed.
	;
	mov	ds:[VMH_compressFlags], cl
	call	VMCheckCompression

	;
	; Release the file.
	;
	call	ExitVMFileFar

	.leave
	ret

VMFreeVMChain	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FreeVMChainLow

DESCRIPTION:	Low level routine to free a VM chain

CALLED BY:	VMFreeVMChain

PASS:
	bx - VM file
	ax:bp - VM chain
	es - VMHeader

RETURN:
	es - fixed up as needed

DESTROYED:
	ax, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

FreeVMChainLow	proc	near	uses cx, si, ds
	.enter

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	tst	bp			;Check if DB item or VM chain
	jz	blockLoop		;If BP = 0, then is a VM chain

;	The caller passed in a DB item, so free it.

	mov	di, bp			;axdi <- group_and_item
        call    DBInfo                  ;make sure the item is valid

EC <    ERROR_C -1                    > ;fail on incorrect DBItem - this is
                                        ;important for detecting cases where
                                        ;the C version of VMFreeVMChain()
                                        ;has been passed a VMBlock rather
                                        ;than a VMChain. -- mgroeber 11/20/00

        jc      done

	call	DBFree
	jmp	done

blockLoop:
	tst	ax			; allow for empty chain
	jz	done

	; lock block and check for chain

	;
	; Make sure the block is ok. This still won't take care of the
	; case where something was written out with a handle for a block that
	; had been freed and reused but that state hadn't made it out to the
	; file, but we can't cover everything, and that case might not ever
	; happen...
	;
	cmp	ax, offset VMH_blockTable
	jb	done
	cmp	ax, es:[VMH_lastHandle]
	jae	done
	mov	di, ax
	test	es:[di].VMBH_sig, VM_IN_USE_BIT
	jz	done
	cmp	es:[di].VMBH_sig, VMBT_DUP
	jb	done

	;
	; Fetch the "next" pointer from the block.
	;
	push	es:[VMH_blockTable].VMBH_memHandle
	push	ax
	push	es:[VMH_blockTable].VMBH_memHandle
	call	VMLock
	call	MemDerefStackES
	mov	ds, ax
	mov	cx, ds:[VMCL_next]
	cmp	cx, VM_CHAIN_TREE
	jnz	freeBlock

	; freeing a tree

	mov	cx, ds:[VMCT_count]
	jcxz	freeBlock

	push	bp
	mov	si, ds:[VMCT_offset]
treeLoop:
	movdw	axbp, ds:[si]
	call	FreeVMChainLow
	add	si, size dword
	loop	treeLoop
	pop	bp

freeBlock:
	;
	; release the block before we free it, please, just to be neat.
	;
	; cx = next block
	;
	call	VMUnlock
	pop	ax			; ax <- vm block handle

	call	VMFree
	mov_tr	ax, cx			; ax <- next block

	;
	; deref the VMHeader in case VMFree moved it
	;
	call	MemDerefStackES
	jmp	blockLoop

done:

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

FreeVMChainLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMCompareVMChains

DESCRIPTION:	Compare two chains of VM blocks.  The override VM file
		is not used.

CALLED BY:	GLOBAL

PASS:
	bx - VM file
	ax:bp - VM chain

	dx - VM file
	cx:di - VM chain


RETURN:
	carry - set if equal

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

VMCompareVMChains	proc	far	uses ax, cx, si, di, bp, ds, es
	.enter

	call	CompareChainsLow

	.leave
	ret

VMCompareVMChains	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CompareChainsLow

DESCRIPTION:	Compare two chains of VM blocks

CALLED BY:	VMCompareVMChains

PASS:
	bx - VM file
	ax:bp - VM chain

	dx - VM file
	cx:di - VM chain

RETURN:
	carry - set if equal

DESTROYED:
	ax, cx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

CompareChainsLow	proc	near
	tst	bp
	LONG jnz isDBItem
	tst_clc	di			;If first file is VM chain, and 2nd
	jnz	done			; is DB, exit with carry clear
next:
	call	VMLock
	mov	ds, ax			;ds = source block
	push	bp			;save handle

	xchg	ax, cx			;ax:bx = dest file and block
	xchg	bx, dx			;bx = dest, dx = source

	push	ax
	call	VMInfo			;cx = size, di = UserID
	pop	ax
	call	VMLock
	xchg	bx, dx			;bx = source, dx = dest
	mov	es, ax			;es = dest block
	mov	ax, di			;ax = save UserID

	; ds and es are VM blocks

	mov	si, ds:[VMCL_next]
	mov	di, es:[VMCL_next]
	cmp	si, VM_CHAIN_TREE
	jz	compareTree

	tst	si
	jz	10$
	tst_clc	di			;exists -- other must exist
	jz	common
	jmp	compare
10$:
	tst_clc	di			;does not exist -- other must not exist
	jnz	common

compare:
	cmp	ax, SVMID_HA_DIR_ID	; check for HugeArray signature
	LONG je	compareHugeArray
	shr	cx, 1			;cx = # words
	dec	cx			;skip first word
	mov	si, 2
	mov	di, si
	repe	cmpsw
	clc
	jnz	common

	; blocks compared -- loop to compare next blocks

	mov	cx, es:[VMCL_next]	;ax = next block (for dx file)
	mov	ax, ds:[VMCL_next]	;cx = next block (for bx file)
	stc				;mark equal

	; carry - set if still equal

common:
	pushf
	call	VMUnlock
	popf
	pop	bp
	pushf
	call	VMUnlock
	popf
	jnc	done

	tst	ax
	jnz	next
	stc

done:
	ret

compareTree:

	; its a tree -- compare block before chains

	mov	cx, ds:[VMCT_offset]
	shr	ax
	clr	si
	clr	di
	repe	cmpsw
	clc
	jnz	common

	; compare all chains

	mov	cx, ds:[VMCT_count]
	jcxz	common
	mov	si, ds:[VMCT_offset]
treeLoop:
	movdw	axbp, ds:[si]		;axbp = source chain
	movdw	cxdi, es:[si]		;cxdi = dest chain
	add	si, size word
	push	cx, si, di, ds, es
	call	CompareChainsLow
	pop	cx, si, di, ds, es
	jnc	common
	loop	treeLoop
	jmp	common

	; the thing is in a HugeArray chain.  Don't check the headers,
	; which contain other vm block handles.  Skip checking the first
	; block altogether, since it's chock full of handles (dir entries).
nextHA:
	call	VMLock
	mov	ds, ax			;ds = source block
	push	bp			;save handle

	xchg	ax, cx			;ax:bx = dest file and block
	xchg	bx, dx			;bx = dest, dx = source

	push	ax
	call	VMInfo			;cx = size
	pop	ax
	call	VMLock
	xchg	bx, dx			;bx = source, dx = dest
	mov	es, ax			;es = dest block

	; ds and es are VM blocks

	mov	si, ds:[VMCL_next]
	mov	di, es:[VMCL_next]
	cmp	si, VM_CHAIN_TREE
	clc
	je	commonHA

	tst	si
	jz	checkEndHA
	tst_clc	di			;exists -- other must exist
	jz	commonHA
	jmp	compareHA
checkEndHA:
	tst_clc	di			;does not exist -- other must not exist
	jnz	commonHA

compareHA:
	mov	si, size HugeArrayBlock
	mov	di, si
	sub	cx, si			;don't compare the first part of block
	shr	cx, 1			;cx = # words
	repe	cmpsw
	clc
	jnz	commonHA

	; blocks compared -- loop to compare next blocks
compareHugeArray:
	mov	cx, es:[VMCL_next]	;ax = next block (for dx file)
	mov	ax, ds:[VMCL_next]	;cx = next block (for bx file)
	stc				;mark equal

	; carry - set if still equal

commonHA:
	pushf
	call	VMUnlock
	popf
	pop	bp
	pushf
	call	VMUnlock
	popf
	jnc	doneHA

	tst	ax
	jnz	nextHA
	stc

doneHA:
	ret

isDBItem:
	tst_clc	di			;If first file is DB, and 2nd is VM
	LONG jz	common			; chain, exit with carry clear

	xchg	bp, di
	call	DBLock
	segmov	ds, es
	mov	si, ds:[di]		;DS:SI <- first item
	mov	bx, dx
	mov	di, bp
	call	DBLock			;ES:DI <- second item
	mov	di, es:[di]

	mov	cx, es:[di].LMC_size	;If sizes of items are different,
	cmp	cx, ds:[si].LMC_size	; then exit with carry clear
	jne	noMatch
	dec	cx
	dec	cx
	shr	cx,1
	jnc	40$
	cmpsb
	jne	noMatch
40$:
	repe	cmpsw
	stc
	je	doUnlock
noMatch:
	clc
doUnlock:
	call	DBUnlock
	segmov	es, ds
	call	DBUnlock
	jmp	common

CompareChainsLow	endp

;=====================================================================

COMMENT @----------------------------------------------------------------------

FUNCTION:	VMAllocLMem

DESCRIPTION:	Utility routine to allocate a VM block with a local memory heap

CALLED BY:	GLOBAL

PASS:
	ax - type of heap (LMemType)
	bx - vm file handle
	cx - size of block header (or 0 for default)

RETURN:
	ax - vm block handle:
		vm user id - 0
		lmem handles - 2 (the minimum)
		lmem heap space - 64 bytes

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/91		Initial version

------------------------------------------------------------------------------@
VMAllocLMem	proc	far	uses cx
	.enter

	push	bx				;save file handle
	call	MemAllocLMem			;bx = mem block
	mov	cx, bx				;cx = mem block
	pop	bx

	clr	ax				;allocate new VM block
	call	VMAttach			;ax = vm block

	.leave
	ret

VMAllocLMem	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMInfoVMChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns the number of blocks in vm chain, and the total size
		of the chain in bytes

CALLED BY:
PASS:		bx	= vm file handle
		ax:bp	= vm chain
RETURN:
		cxdx <- sum of sizes of VM blocks and DB items (in bytes)
		si   <- number of VM blocks in chain
		di   <- number of DB items in chain

		carry set if error (bad block in chain)

DESTROYED:	nothing
SIDE EFFECTS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMInfoVMChain	proc	far
	vmChainLowWord		local	word	push bp
	byteSizeBlocks		local	dword
	byteSizeItems		local	dword
	numBlocks		local	word
	numItems		local	word

	ForceRef VMInfoVMChain
	ForceRef byteSizeBlocks
	ForceRef byteSizeItems
	ForceRef numBlocks
	ForceRef numItems

	uses	ax
	.enter
EC <		Assert	fileHandle, bx					>
	;
	; init the counts to 0
	;
		clrdw	byteSizeBlocks
		clrdw	byteSizeItems
		clr	numBlocks
		clr	numItems
	;
	; start the recursion
	;
		mov	cx, vmChainLowWord		; ax:cx is vm chain
		;bx is vm file
		;axcx is vm chain
		;bp is locals
		call	VMInfoVMChainLow		; size & blocks filled
							; carry set if error
done::
	;
	; move return values into registers
	;
		pushf					; save error flag
		movdw	cxdx, byteSizeBlocks
		adddw	cxdx, byteSizeItems
		mov	si, numBlocks
		mov	di, numItems
		popf					; restore error flag
	.leave
	ret
VMInfoVMChain	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VMInfoVMChainLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	recursivly gets size and block count for a vm chain

CALLED BY:	VMInfoVMChain
PASS:		;bx is vm file
		;axcx is vm chain
		;bp is locals
RETURN:		update counts
		carry set if an invalid block was found
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SK	5/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VMInfoVMChainLow	proc	near
	uses	ds
	.enter inherit VMInfoVMChain
EC <		Assert	fileHandle, bx					>
	;
	; is it a chain or a DBItem?
	;
		tst	cx
		jz	doChainsAndTrees
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;    	     a db item		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doDBItem::
	;
	; make sure that the group/item block is valid, if it is valid
	; count it
	;
		;bx is vm file handle
		;ax is block handle
		mov	di, cx				; ax:di is group:item
		call	DBInfo				; cx <- size
		LONG jc	done				; an error occured
		inc	numItems
ifdef USE_DBLOCK
	;
	; lock down the item
	;
		push	es				; save es
		;ax is group
		;di is item
		;bx is vm file
		call	DBLock				; es:*di ptr to item
	;
	; get the size
	;
		ChunkSizeHandle	es, di, cx
		clr	ax
		adddw	byteSizeItems, axcx
	;
	; unlock it
	;
		;es is segment of locked block
		call	DBUnlock
		pop	es				; restore es
		clc					; no error
else
	;
	; add the size of the item...
	;
		clr	ax
		adddw	byteSizeItems, axcx
endif

		jmp	done
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     chains and trees	;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doChainsAndTrees:
	;
	; is there anything to do?
	;
		tst	ax
		clc					; no error
		jz	done				; is null chain
	;
	; count this block
	;
		mov	dx, ax				; copy block hdl
		;bx is vm file handle
		;ax is block handle
		call	VMInfo				; cx <- size
							; ax <- mem hdl (or 0)
							; di <- user id
		LONG jc	done				; error occured
		inc	numBlocks
		clr	ax				; high word of dword
		adddw	byteSizeBlocks, axcx
	;
	; lock down this block
	;
		push	bp				; save locals
		mov_tr	ax, dx				; block handle
		;bx is vm file
		call	VMLock				; bp <- mem handle
							; ax <- segment
		mov	ds, ax
	;
	; see if it is a tree or a chain
	;
		mov	ax, ds:[VMCL_next]
		cmp	ax, VM_CHAIN_TREE
		je	doTree
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;     just a chain		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;
	; its not a tree, just a chain.  unlock this block and go on.
	; the bp for locals is on the stack
	;
		;bp is mem handle
		call	VMUnlock			; flags preserved
		pop	bp				; restore locals

		tst	ax				; clears carry
		jz	done				; chain ends here
	;
	; go do the next block, sorta like tail recursion, only we are
	; not at the end, since the tree stuff is below us...  oh well.  ;)
	;
		;bx is vm file
		;bp is locals
		;ax:cx is chain
		;clr	cx				; ax:cx is chain
		;call	VMInfoVMChainLow		; carry set on error
		jmp	doChainsAndTrees
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;    	   just a tree		;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
doTree:
	;
	; bp is mem handle of the block, the bp for locals is on the stack
	;
		mov_tr	ax, bp
		pop	bp				; restore locals
		push	ax				; save mem handle
	;
	; loop through the branches
	;
		mov	si, ds:[VMCT_offset]		; first chain
		mov	di, ds:[VMCT_count]		; chains to do
		tst	di				; any children?
		jz	exitTreeLoop			; nope!
treeLoop:
		movdw	axcx, ds:[si]
		;bx is vm file
		;bp is locals
		push	si, di
		call	VMInfoVMChainLow		; carry set on error
		pop	si, di
		jc	exitTreeLoop
		add	si, size dword			; move to next chain
		dec	di				; one less child chain
		clc					; no error
		jnz	treeLoop
exitTreeLoop:
;end treeLoop
	;
	; done with tree block, unlock it
	;
		mov_tr	ax, bp				; save locals
		pop	bp				; mem handle
		call	VMUnlock			; flags preserved
		mov_tr	bp, ax				; restore locals
done:
	.leave
	ret
VMInfoVMChainLow	endp

VMUtils	ends
