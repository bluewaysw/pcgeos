COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bpt.asm

AUTHOR:		Adam de Boor, Apr 14, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/92		Initial revision


DESCRIPTION:
	Functions for managing breakpoints and the heap in which they are
	allocated.
		

	$Id: bpt.asm,v 1.22 97/02/13 15:18:37 guggemos Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	include	stub.def
	include Internal/heapInt.def	; for HandleMem

.386
	assume	ds:cgroup, es:cgroup, ss:sstack

BptFreeBlock	struct
    BFB_size	word			; size of this block, including size
					;  word
    BFB_next	nptr.BptFreeBlock	; pointer to the next free block
BptFreeBlock	ends

bptHeap		segment

bptFreeList	nptr.word	cgroup:bptHeapStart

bptHeapStart	word	BPT_HEAP_SIZE, 0, (BPT_HEAP_SIZE-4)/2 dup(?)

bptHeap		ends

scode	segment

bptChain	nptr.BptDesc	0	; currently-set breakpoints

if TRACK_INT_21
bptInt21Table	nptr	int21Counts
else
bptInt21Table	nptr	0
endif
	ForceRef	bptInt21Table	; used by Tcl code

bptHeapOffset	nptr	bptHeapStart
bptHeapSize	word	BPT_HEAP_SIZE

	ForceRef	bptHeapOffset	; used by Tcl code
	ForceRef	bptHeapSize	; used by Tcl code

bptsInstalled	byte	FALSE		; TRUE if breakpoints installed

bptSkipAddr	dword		; Where to set the breakpoint
bptSkipDesc	nptr.BptDesc	; BptDesc being skipped, if known
bptSkipMask1	byte		; Place to save interrupt controller mask 1
				; to be restored when the step is complete.
bptSkipIF	byte		; Interrupt mask before skip

if DEBUG AND DEBUG_BPT_EC

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BptVerifyHeap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the bpt heap is copacetic.

CALLED BY:	(INTERNAL)
PASS:		ds = es = cgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		A number of things to check:
			1) free list is sorted in ascending order
			2) no free list blocks overlap
			3) everything is properly coalesced
			4) no blocks overlap (must use the free list to
			   determine whether size is byte or word)
			5) there are no gaps in the heap.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BptVerifyHeap	proc	near
		uses	ax, bx
		.enter
	;
	; First check the free list.
	; 
		mov	bx, offset bptFreeList - offset BFB_next
checkFreeListLoop:
		mov	bx, ds:[bx].BFB_next
		tst	bx
		jz	checkEntireHeap
		mov	ax, ds:[bx].BFB_next
		tst	ax
		jz	checkEntireHeap
		cmp	ax, bx
		jbe	freeListCorrupt
		sub	ax, bx
		cmp	ax, ds:[bx].BFB_size
		ja	checkFreeListLoop	; be => next is within this one
						;  or didn't coalesce when we
						;  should have
freeListCorrupt:
		pushf
		push	cs
		call	freeListCorruptNotify
freeListCorruptNotify:
		call	IRQCommon		; pretend interrupt 255 caught
		.inst	byte	255

checkEntireHeap:
	;
	; Now verify all the blocks in the heap.
	; I'd love to, except I don't record anywhere the actual size of
	; the heap, so...
	; 
		.leave
		ret
BptVerifyHeap	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Alloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate room in the breakpoint heap

CALLED BY:	EXTERNAL
PASS:		cx	= number of bytes to allocate (< 255)
RETURN:		si	= offset of allocated space
			= 0 if no more room
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Alloc	proc	near
		uses	ax, bx
		.enter
DA DEBUG_BPT_EC, <call	BptVerifyHeap					>

	DPC DEBUG_BPT, 'A'
	DPW DEBUG_BPT, cx

		cmp	cx, size BptFreeBlock
		jae	findFirstFree
		mov	cx, size BptFreeBlock-1
findFirstFree:
		inc	cx		; allocate room for size byte, too
		mov	si, offset bptFreeList-offset BFB_next
findLoop:
		mov	bx, si			; ds:bx <- previous
		mov	si, ds:[bx].BFB_next	; ds:si <- next
		tst	si
		jz	done
		
		mov	ax, ds:[si].BFB_size
		cmp	ax, cx
		jb	findLoop
		
	;
	; Figure if it's worthwhile to split the block in two.
	; 
		sub	ax, cx
		cmp	ax, size BptFreeBlock	; remainder smaller than a
						;  free block?
		jb	adjustLink		; yes -- just keep size the
						;  same
	;
	; Yes. Set this formerly-free block to have the size requested by the
	; caller.
	; 
		mov	ds:[si], cl
	;
	; Figure the start of the remainder and set that as the next pointer
	; for the previous block.
	; 
		add	cx, si
		mov	ds:[bx].BFB_next, cx
		mov	bx, cx
	;
	; Set the size of the remainder.
	; 
		mov	ds:[bx].BFB_size, ax
adjustLink:
	;
	; Adjust the linkage. If we split the block, this is just copying
	; the BFB_next from the former free block to the remainder. If we didn't
	; split the block, this is unlinking the former free block from the
	; free list.
	; 
		mov	ax, ds:[si].BFB_next
		mov	ds:[bx].BFB_next, ax
	;
	; Point to the actual data, not the size byte.
	; 
		inc	si
done:
	DPW DEBUG_BPT, si
DA DEBUG_BPT_EC, <call	BptVerifyHeap					>
		.leave
		ret
Bpt_Alloc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Free
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a block allocated with Bpt_Alloc

CALLED BY:	EXTERNAL
PASS:		si	= offset of allocated block
RETURN:		nothing
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Free	proc	near
		uses	ax, bx, di
		.enter
	DPC DEBUG_BPT, 'F'
	DPW DEBUG_BPT, si
DA DEBUG_BPT_EC, <call	BptVerifyHeap					>

		mov	{byte}ds:[si], 0	; convert size byte to word
		dec	si		; point to size byte
		mov	di, offset bptFreeList - offset BFB_next
insertLoop:
		mov	bx, di			; bx <- previous block
		mov	di, ds:[bx].BFB_next	; di <- next free block
		tst	di
		jz	foundSpot		; => no next free block, so
						;  found previous free for
						;  insertion
		cmp	di, si			; next free above this one?
		jb	insertLoop		; no, so not found insert
						;  point yet
foundSpot:
	;
	; If not inserting at front of the list, see if we can coalesce with
	; the previous block.
	; 
		cmp	bx, offset bptFreeList - offset BFB_next
		je	insert
		
		mov	ax, ds:[bx].BFB_size
		add	ax, bx
		cmp	ax, si
		jne	insert
	;
	; Give the bytes for the newly-free block to its preceding block, then
	; make it look as if the preceding block is the one having been freed.
	; 
		lodsw				; ax <- passed block's size
		add	ds:[bx].BFB_size, ax
		mov	si, bx
		jmp	tryCoalesceAfter

insert:
	;
	; Couldn't coalesce with the block before it, so we must insert it
	; in the free list. Then we'll try and coalesce with the following
	; block.
	; 
		mov	ds:[bx].BFB_next, si
		mov	ds:[si].BFB_next, di

tryCoalesceAfter:
		mov	ax, ds:[si].BFB_size
		add	ax, si
		cmp	ax, di
		jne	done
	;
	; Block being freed reaches to the next one, so coalesce the two.
	; 
		mov	ax, ds:[di].BFB_next
		mov	ds:[si].BFB_next, ax
		mov	ax, ds:[di].BFB_size
		add	ds:[si].BFB_size, ax
done:
DA DEBUG_BPT_EC, <call	BptVerifyHeap					>
		.leave
		ret
Bpt_Free	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BptFindChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the BptDesc for a given address

CALLED BY:	Bpt_Set, Bpt_Check
PASS:		cx:dx	= address for which to look (cx = handle if XIP)
		ax	= XIP page (or BPT_NOT_XIP)
RETURN:		carry set if found:
			ds:si	= BptDesc
			ds:bx	= "BptDesc" for previous (might be the
				  bptChain variable's address instead...)
		carry clear if not found
			si, bx	= destroyed
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BptFindChain	proc	near
		uses	ax, di, bp
		.enter
	DA  DEBUG_BPT, <push ax>
	DPC DEBUG_BPT, 'f'
	DPW DEBUG_BPT, cx
	DPW DEBUG_BPT, dx
	DA  DEBUG_BPT, <pop ax>
	DPW DEBUG_BPT, ax

	;
	; First see if there's already a breakpoint set at that address.
	; 
		mov	si, offset bptChain - offset BD_next
		mov	bp, offset BD_addr.segment
		cmp	ax, BPT_NOT_XIP
		je	findLoop
		mov	bp, offset BD_handle
findLoop:
		mov	bx, si
		mov	si, ds:[bx].BD_next
		tst	si
		jz	done

		cmp	ds:[si].BD_xipPage, ax	; this is overriding concern...
		jne	findLoop		; mismatch here means can't
						;  possibly be right

		tst	ds:[si].BD_handle
		jz	checkLinear

		cmp	dx, ds:[si].BD_addr.offset
		jne	findLoop

		cmp	cx, ds:[si][bp]		; compare to handle or segment,
						;  as appropriate
		jne	findLoop
found:
	DPC	DEBUG_BPT, 'f', inv
		stc
done:
	DA DEBUG_BPT, <pushf>
	DPW DEBUG_BPT, si
	DA DEBUG_BPT, <popf>
		.leave
		ret

checkLinear:
	;
	; Check low four bits of offset first. If they don't match, the
	; linear address can't match, and once we've checked them, we can
	; forget them so we can use a 17-bit comparison, not 32-bit.
	; 
		mov	ax, ds:[si].BD_addr.offset
		mov	di, ax
		xor	ax, dx
		test	ax, 0xf
		jnz	findLoop
	;
	; Recover the offset of the breakpoint and turn it into a segment.
	; 
		mov_tr	ax, di
		shr	ax
		shr	ax
		shr	ax
		shr	ax
	;
	; Add in the segment of the breakpoint to generate the linear segment
	; of the breakpoint.
	; 
		add	ax, ds:[si].BD_addr.segment
		pushf
		pop	bp
	;
	; Convert the offset for which we seek to a segment
	; 
		mov	di, dx
		shr	di
		shr	di
		shr	di
		shr	di
	;
	; Add in its segment to get the linear segment of cx:dx
	; 
		add	di, cx
		pushf
	;
	; Finally, see if there's a match.
	; 
		cmp	ax, di
		pop	ax
		jne	toFindLoop

	    ; check bit 17, to cope with breakpoints in the HMA
		xor	ax, bp
		test	ax, 1
		jz	found
toFindLoop:
		mov	bp, offset BD_addr.segment	; must be non-xip
							;  or wouldn't be here
		jmp	findLoop
BptFindChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_WriteWordByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes out a byte by reading in the word, putting the byte
		in the correct half, and then writing back out the byte.
		This is used for _WRITE_ONLY_WORDS versions of the stub.

CALLED BY:	Bpt_...

PASS:		es:di	= destination address
		al	= byte to write

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	3/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	 _WRITE_ONLY_WORDS

Bpt_WriteWordByte	proc	near
		uses	bx,si
		.enter
		
		mov	si, di
		and	si, not 1
		pushf
		dsi				; ensure consistency
		mov	{word} bx, es:[si]
		test	di, 1
		jnz	setItOdd
		
		; Even - put in low byte
		mov	bl, al
		jmp	setIt

setItOdd:
		; Odd - put in high byte
		mov	bh, al

setIt:		
		; Stuff It!
		mov	{word} es:[si], bx
		popf				; restore IF & friends
		
		.leave
		ret
Bpt_WriteWordByte	endp

endif	;_WRITE_ONLY_WORDS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BptRestore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore an instruction that was replaced by a 0xcc

CALLED BY:	GLOBAL

PASS:		es:si = location to restore
		ds:bx = BptDesc

RETURN:		Void.

DESTROYED:	ax

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/ 5/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BptRestore	proc	near
		.enter
	DPS DEBUG_BPT, br
	DPW DEBUG_BPT es
	DPW DEBUG_BPT si
	DPW DEBUG_BPT bx
		call	Kernel_EnsureESWritable
		push	ax
		
		mov	al, ds:[bx].BD_inst
	DPB <DEBUG_BPT or DEBUG_XIP>, al
if	 _WRITE_ONLY_WORDS
		xchg	di, si
		call	Bpt_WriteWordByte
		xchg	si, di
else	;_WRITE_ONLY_WORDS is FALSE
		mov	es:[si], al
endif	;_WRITE_ONLY_WORDS
		
		pop	ax
		call	Kernel_RestoreWriteProtect
		.leave
		ret
BptRestore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BptDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a BptDesc.

CALLED BY:	Bpt_Clear, Bpt_Check
PASS:		ds:bx	= BptDesc to nuke
		ds:si	= its predecessor
RETURN:		nothing
DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BptDelete	proc	near
		uses	es, di
		.enter
;	DPC DEBUG_BPT_EC, 'D', inverse
;	DPW DEBUG_BPT_EC, bx
;	DPW DEBUG_BPT_EC, si
	;
	; See if we have to zombify the breakpoint, owing to the block in
	; which the breakpoint is installed having been swapped out, and our
	; INT 3 instruction with it.
	; 
		mov	es, ds:[kdata]

	; first lets see if it's an XIP handle that's currently mapped out
		cmp	ds:[bx].BD_xipPage, BPT_NOT_XIP
		je	notXIP
		
	; if the kernel is gone, there's nothing we need to do: the
	; instruction was removed by Bpt_SysExiting -- ardeb 10/23/95

		test	ds:[sysFlags], mask nomap
		jnz	notXIP

	; it is an XIP handle, if it's mapped in, treat like a normal bpt
		push	di
		mov	di, ds:[curXIPPageOff]
		mov	ax, es:[di]
		cmp	ax, ds:[bx].BD_xipPage
		pop	di
		je	notXIP

	; if it's mapped out and still SET_PENDING then we can just biff it
	; since it never got installed anyways...
		test	ds:[bx].BD_state, mask BSF_SET_PENDING
		jnz	notXIP

	; it's mapped out, so marked as delete pending and when it get
	; mapped in, it will be taken care of - this doesn't work quite
	; right...
;		or	ds:[bx].BD_state, mask BSF_DELETE_PENDING
	; try mapping in the proper page, return the instruction to its proper
	; value and then remap in the old page
	; 12/6/94: the instruction will get restored by Bpt_UpdatePending
	; at its checkRestore label, because we (the stub) are mapping the page
	; 				-- ardeb
	; 
		push	dx, bx
		mov	dx, ds:[bx].BD_xipPage
		call	Kernel_SafeMapXIPPage

		mov	dx, BPT_NOT_XIP		; dx <- restore page
		call	Kernel_SafeMapXIPPage
		pop	dx, bx
		clr	ds:[bx].BD_addr.segment
	; once we clear the segment we can fall through as it knows the
	; instuction has already be replaced and it will take the breakpoint
	; out of the bpt list

notXIP:
		mov	di, ds:[bx].BD_handle
		tst	di
		jz	biffIt
		test	es:[di].HM_flags, mask HF_SWAPPED
		jz	biffIt
	;
	; Turn the BptDesc into a zombie by setting BD_clients to 0, rather
	; than pointing back to itself. We don't need to worry about checking
	; for zombies when setting a breakpoint, as Bpt_BlockChange will always
	; be called before Swat is notified of the change in the block's status,
	; and it will nuke the 
	;
	; NOTE: If we change breakpoint-setting to be handle-relative, this
	; will change.
	; 
		mov	ds:[bx].BD_clients, 0
		jmp	done
biffIt:
	;
	; Unlink the BptDesc from its predecessor.
	; 
		mov	ax, ds:[bx].BD_next
		mov	ds:[si].BD_next, ax
	;
	; Replace the instruction with the real one, unless the block is
	; no longer resident (segment of BD_addr is 0).
	; 
		mov	ax, ds:[bx].BD_addr.segment
		mov	si, ds:[bx].BD_addr.offset
		tst	ax
		jz	instructionReplaced

	; don't try to stick in a bogus value if we haven't the proper
	; value to stick in 
		test	ds:[bx].BD_state, mask BSF_SET_PENDING
		jnz	instructionReplaced

		mov	es, ax
		call	BptRestore
if 0
		call	Kernel_EnsureESWritable
		push	ax
		mov	al, ds:[bx].BD_inst
		mov	es:[si], al
		pop	ax
		call	Kernel_RestoreWriteProtect
endif
instructionReplaced:
	;
	; Now free the BptDesc itself.
	; 
		mov	si, bx
		call	Bpt_Free
done:
		.leave
		ret
BptDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a breakpoint at a particular address, registering a
		client that's interested in the breakpoint.

CALLED BY:	EXTERNAL
PASS:		cx:dx	= address at which to set the breakpoint
			  cx = handle if ax != BPT_NOT_XIP
		bx	= BptClient being registered
		ax	= BPT_NOT_XIP for non XIP, XIP page otherwise
RETURN:		si	= offset of BptDesc
			= 0 if breakpoint couldn't be set
			= if si = 0, ax = error code
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Set		proc	near
		uses	di
		.enter
		mov	di, ax	; save xip page info (*not* mov_tr -- ax needed
				;  for BptFindChain)

	;
	; Mark this new client as the last -- always needed.
	; 
		ornf	ds:[bx].BC_flags, mask BCF_LAST
	;
	; See if there's a breakpoint already set at this location
	; 

		push	bx
		call	BptFindChain
		pop	bx
		mov	ax, RPC_TOOBIG
		jnc	notFound

	;
	; Found one, so just link the given BptClient record onto the end of
	; the list.
	; 
		mov	ds:[bx].BC_next, si	; point back to BD to make
						;  clearing these things
						;  easier
		push	bx
		mov	bx, si
		CheckHack <offset BC_next eq offset BD_clients>
		mov_tr	ax, si
linkClientLoop:
		mov_tr	si, ax
		mov	ax, ds:[si].BC_next
		cmp	ax, bx			; end of the list?
		jnz	linkClientLoop		; no -- keep going

		pop	ax			; ax <- new client
		mov	ds:[si].BC_next, ax	; point to new
		andnf	ds:[si].BC_flags, not mask BCF_LAST
		mov	si, bx			; ds:si <- BptDesc again
		mov_tr	bx, ax
		mov	ax, RPC_TOOBIG
		jmp	done

notFound:
		push	ax
		DPC	DEBUG_FALK2, 'R'
		DPW	DEBUG_FALK2, cx
		DPW	DEBUG_FALK2, dx
		pop		ax



	;
	; Didn't find one already set, so allocate room for a new one.
	; 
		push	cx
		mov	cx, size BptDesc
		call	Bpt_Alloc
		pop	cx

		tst	si
	   .warn -jmp		; ec.def not included here.
		jz	done		; => couldn't alloc, so can't set
	   .warn @jmp
	;
	; Point new client back at BD, to make clearing such things easier.
	; 
		mov	ds:[bx].BC_next, si
	;
	; Initialize the new BptDesc.
	; 
                mov     ds:[si].BD_installed, 0
		mov	ds:[si].BD_addr.segment, cx
		mov	ds:[si].BD_addr.offset, dx
		mov	ds:[si].BD_clients, bx

		mov	ds:[si].BD_xipPage, BPT_NOT_XIP

	; this set pending bit will be turned off when the actual
	; instruction is fetched, this will either happen immediately
	; down below if it's a normal handle, or it's an XIP handle that
	; is currently mapped in. If it's an XIP handle that is not mapped
	; in, then that will happen when it gets mapped in
		mov	ds:[si].BD_state, mask BSF_SET_PENDING
		push	bx			; save client offset
	;
	; Locate the handle in which the breakpoint address is found.
	; 
		push	ax, es, dx
	DA  DEBUG_BPT, <push ax>
	DPC DEBUG_BPT, 'h'
	DPW DEBUG_BPT, cx
	DA  DEBUG_BPT, <pop ax>

		cmp	di, BPT_NOT_XIP
		je	findHandle

DA	DEBUG_BPT, <push ax>
DPS	DEBUG_BPT, xip
DA	DEBUG_BPT, <pop ax>

	; if di was not BPT_NOT_XIP, we have an XIP resource, 
	; and the passed in segment was actually the handle

		mov	bx, cx
		call	Kernel_TestForXIPHandle
		jc	gotAddr
	DA	DEBUG_BPT, <push ax>
	DPC	DEBUG_BPT, 'n'
	DA	DEBUG_BPT, <pop ax>
		mov	di, BPT_NOT_XIP		; masquerade as a normal handle
						;  if mapped in
gotAddr:
		mov	cx, ax
		mov	ds:[si].BD_addr.segment, ax
		mov	ds:[si].BD_xipPage, dx
		jmp	haveHandle
findHandle:
		mov	ax, BPT_NOT_XIP
		call	Kernel_SegmentToHandle
		jnc	haveHandle
		clr	bx
haveHandle:
	DPW DEBUG_BPT, bx
		mov	ds:[si].BD_handle, bx
		pop	ax, es, dx

	; if di is not BPT_NOT_XIP at this point, we are setting a breakpoint
	; for an XIP resource that is not currently mapped in, so don't try
	; to write to memory, that should happen when it gets banked
	; in (I cross my fingers)
		cmp	di, BPT_NOT_XIP
		jne	linkChain

	; let's check the memory for READ_ONLY before we add this breakpoint
	; to the list	
	;
	; Fetch original instruction from memory. A breakpoint will be put
	; there when we continue the machine, if appropriate.
	; 
if	 _WRITE_ONLY_WORDS
	; In this case, we have to use Bpt_WriteWordByte since we can only
	; safely write words.
		push	es, di		; move bpt address into es:di for
		mov	es, cx		; Bpt_WriteWordByte
		mov	di, dx
		
		call	Kernel_EnsureESWritable
		mov	bx, ax		; save value for Restore..
		
		mov	al, es:[di]	; get original value
		mov	ah, al
		inc	ah		; insure ah != al
		xchg	al, ah		; al=test, ah=inst
		call	Bpt_WriteWordByte	; write test value
		mov_tr	al, ah		; al=inst
		mov	ah, es:[di]	; ah=memory value after write
		call	Bpt_WriteWordByte	; write out orig value, always
		pop	es, di
		
		xchg	ax, bx		; pass value from _EnsureESWritable
		call	Kernel_RestoreWriteProtect
		mov_tr	ax, bx		; AL = instruction,
					; AH = memory value after write of
					;      test value
					  
		cmp	ah, al

else	;_WRITE_ONLY_WORDS is FALSE
		push	es, cx
		mov	es, cx
		call	Kernel_EnsureESWritable
		mov_tr	cx, ax
		mov	bx, dx
	DPW DEBUG_BPT, es:[bx]
		mov	al, es:[bx]	; get original value
		mov	ah, al
		inc	ah		; insure ah != al
		mov	es:[bx], ah	; write out something different
		cmp	es:[bx], al
		mov	es:[bx], al 	; restore value either way
	DA  DEBUG_BPT, pushf
	DPW DEBUG_BPT, es:[bx]
	DA  DEBUG_BPT, popf

		lahf			; save CMP result
		xchg	ax, cx		; ax <- wp data, cx <- inst + CMP res
		call	Kernel_RestoreWriteProtect
		mov_tr	ax, cx		; al <- inst, ah <- CMP res
		sahf
		pop	es, cx
endif	;_WRITE_ONLY_WORDS

if 0
		pushf
		push	ax, dx, bx
		mov	dx, ds:[oldXIPPage]
		mov	ax, 1
		call	Kernel_SafeMapXIPPage
		pop	ax, dx, bx
		popf
endif
		je	readOnly	; if the value after the write was
					; still equal to the original al then
					; we are dealing with readOnly memory

	; ok we have writable memory so save the original value away
	; and clear the state, as we have fully initialized the bpt
		mov	ds:[si].BD_inst, al
		mov	ds:[si].BD_state, 0
	;
	; Link the new BD as the head of the chain.
	; 
linkChain:
		mov	bx, si
		xchg	ds:[bptChain], bx	; make it the head of the list
		mov	ds:[si].BD_next, bx	;  and point it to the previous
						;   head....
		pop	bx
done:
DA	DEBUG_BPT, <push ax>
DPW	DEBUG_BPT, ds:[si].BD_addr.segment
DPW	DEBUG_BPT, ds:[si].BD_addr.offset
DPW	DEBUG_BPT, ds:[si].BD_handle
DPW	DEBUG_BPT, ds:[si].BD_xipPage
DPB	DEBUG_BPT, ds:[si].BD_state
DA	DEBUG_BPT, <pop ax>

		.leave
		ret
readOnly:
		clr	si			; means couldn't set bpt
		mov	ax, RPC_ACCESS
		pop	bx
		jmp	done
Bpt_Set		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear a breakpoint we set before. Does *not* free the client
		itself.

CALLED BY:	EXTERNAL
PASS:		ds:si	= BptClient to clear
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Clear	proc	near
		uses	bx, si, ax, di
		.enter
	;
	; First find the BptDesc itself.
	; 
		mov	ax, si
findBDLoop:
		mov_tr	bx, ax
		mov	ax, ds:[bx].BC_next
		test	ds:[bx].BC_flags, mask BCF_LAST
		jz	findBDLoop
	;
	; ds:ax = BptDesc
	; 
		mov	di, ax
			CheckHack <BD_clients eq BC_next>
findPrevLoop:
		mov_tr	bx, ax
		mov	ax, ds:[bx].BC_next
		cmp	ax, si
		jne	findPrevLoop
		
	;
	; ds:di	= BptDesc
	; ds:si	= BptClient to unlink
	; ds:bx	= previous "BptClient" (may be BptDesc...)
	; 
		mov	ax, ds:[si].BC_next	; standard unlink...
		mov	ds:[bx].BC_next, ax
	;
	; Now need to deal with the cleared client having been the last in
	; the chain...
	; 
		cmp	ax, di		; cleared client's next ptr the BD?
		jne	done		; no => previous can't be new last
	;
	; Cleared client was the end of the line, so we have to set BCF_LAST
	; in the previous entry, unless the previous entry was the BptDesc
	; itself, which implies we should nuke the breakpoint itself, there
	; being no further interest in it.
	; 
		cmp	bx, di
		je	freeBpt
		ornf	ds:[bx].BC_flags, mask BCF_LAST
done:
		.leave
		ret
freeBpt:
	;
	; No more clients, so biff the bpt. Must find it first...
	; 
		mov	bx, di
		mov	ax, offset bptChain - offset BD_next
findBDPrevLoop:
		mov_tr	si, ax
		mov	ax, ds:[si].BD_next
		cmp	ax, bx
		jne	findBDPrevLoop
		
		call	BptDelete
		jmp	done
Bpt_Clear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Check
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if we've set a breakpoint at the location of stoppage

CALLED BY:	IRQCommon
PASS:		ds = es = scode
		ss:bp	= state_block
		interrupts OFF
RETURN:		only if breakpoint is to be reported to the host
DESTROYED:	Many things

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Check	proc	near
		.enter
DPC	DEBUG_BPT, 'C', inv

		mov	cx, ss:[bp].state_cs
		mov	ax, BPT_NOT_XIP
		call	Kernel_XIPSegmentToHandle	; dx <- xip page (or
							;  unchanged), cx <-
							;  handle (or unchanged)
		jc	findChain
		mov_tr	ax, dx				; ax <- xip page

findChain:
		mov	dx, ss:[bp].state_ip
		
		call	BptFindChain
		jc	gotOne
done:
		.leave
		ret

gotOne:
		call	TB_AdjustForOverhead
	;
	; Now call all the clients to see if they want to stop the machine
	; or what. We start out with the thing marked unconditionaly, but
	; not marked as being taken -- that's up to our clients to decide.
	; 
		mov	cx, mask BCS_UNCONDITIONAL
		mov	bx, si
		CheckHack <offset BD_clients eq offset BC_next>
clientLoop:
		mov	di, si		; save previous
		mov	si, ds:[si].BC_next

	DPC DEBUG_BPT, 'C'
	DPW DEBUG_BPT, si
	DPW DEBUG_BPT, cx

		cmp	si, bx
		jz	clientLoopDone
	;
	; Call the client handler and see what it wants to do
	; 
		push	bx, si, di
		call	ds:[si].BC_handler
		pop	bx, si, di

		CheckHack <(BCR_OK lt BCR_REMOVE) and \
			   (BCR_REMOVE_AND_FREE gt BCR_REMOVE)>
		cmp	ax, BCR_REMOVE
		jb	clientLoop

	;
	; Wants to remove itself from the list and possibly have us free its
	; client record.
	; 
		mov	ax, ds:[si].BC_next	; do the removable
		mov	ds:[di].BC_next, ax	;  in any case
		xchg	di, si			;  ds:si <- previous (again)
		je	clientLoop	; => just remove, and that's now
					;  done, so loop

		xchg	di, si		; ds:si <- BptClient, ds:di <- previous
		call	Bpt_Free
		mov	si, di		; ds:si <- previous
		jmp	clientLoop

clientLoopDone:
	;
	; Called all the clients. See if there are no more clients of this
	; breakpoint and unset it if so. Note that in this case skipping
	; the breakpoint is a little special, as we don't want the breakpoint
	; instruction re-installed; we just need to continue the machine.
	; 
		cmp	ds:[bx].BD_clients, bx
		jnz	checkContinue
	    ;
	    ; Must find the previous pointer again, as one of the clients
	    ; could have nuked the one that was pointing to this one. Sigh.
	    ; 
	    	mov	ax, offset bptChain - offset BD_next
findPrevAgainLoop:
		mov_tr	si, ax
		mov	ax, ds:[si].BD_next
		cmp	ax, bx
		jne	findPrevAgainLoop

		call	BptDelete

		test	cx, mask BCS_TAKE_IT
		jz	continueMachine

checkContinue:
	;
	; See if the consensus is that the breakpoint should be taken.
	; 
		test	cx, mask BCS_TAKE_IT
		jnz	done			; yup -- just return

	;
	; Skip over the breakpoint by storing the proper instruction there
	; and calling the common code, restoring the machine state and
	; going back there...
	; 
		push	es
		les	di, ds:[bx].BD_addr

		call	Kernel_EnsureESWritable
		push	ax
if	 _WRITE_ONLY_WORDS
		mov	al, ds:[bx].BD_inst
		call	Bpt_WriteWordByte
else	;_WRITE_ONLY_WORDS is FALSE
		mov	al, ds:[bx].BD_inst
		stosb
endif	;_WRITE_ONLY_WORDS
		pop	ax
		call	Kernel_RestoreWriteProtect

		pop	es
		mov	ds:[bptSkipDesc], bx
		call	Bpt_Skip	; set machine state as appropriate

continueMachine:
	DPC DEBUG_BPT, 'S', inverse

		call	RestoreState	; and continue. If stepping, the
					;  revectored single-step trap
					;  will deal with things
		iret
Bpt_Check	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BptSkipRecover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recover from a skipped breakpoint

CALLED BY:	Single step trap, set by RpcSkipBpt and HandleCBreak
PASS:		bptSkipAddr	= Address of skipped instruction
		bptSkipMask1	= Mask to store in interrupt controller 1
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	Save registers we use
	Load address at which a breakpoint should be stored and store it.
	Restore the single-step vector to RpcStepReply
	Clear TFlag in the saved flags (CPU saves flags w/TFlag still on)
	Restore registers and return control.
		
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SBRFrame	struct	; stack frame at ss:sp during BptSkipRecover
    SBRF_bx     word            ; saved BX
    SBRF_ds     word            ; saved DS
    SBRF_ax	word		; saved AX
    SBRF_bp	word		; saved BP
    SBRF_es	sptr		; saved ES
    SBRF_retf	fptr.far	; far return address
    SBRF_flags	word		; flags saved by int 1
SBRFrame	ends

BptSkipRecover	proc	far
	;
	; Save the three registers with which we dick. We use
	; BP so we can reference into the stack later, though it
	; costs us a byte in the es:[bp], below.
	; 
		push	es
		push	bp
		push	ax
                push    ds

                mov     ds, cs:[stubDSSelector]
                push    bx
        ; NOTE:  You must modify SBRFrame if you change the saved registers

	;
	; Fetch the address at which to store the breakpoint and do
	; so, getting the instruction at the same time so we know if we
	; have to play games.
	; 
		les	bp, cs:bptSkipAddr
	DPC DEBUG_BPT, 'k'
	DPW DEBUG_BPT, es
	DPW DEBUG_BPT, bp
		mov	ds:[bptSkipAddr].segment, 0	; so we don't mistakenly
							;  avoid installing the
							;  breakpoint next time.
		clr	bx
		xchg	ds:[bptSkipDesc], bx		; ditto
                mov     ds:[bx].BD_installed, 1		; mark bpt as installed
		call	Kernel_EnsureESWritable
if	 _WRITE_ONLY_WORDS
		; For this case, write out the breakpoint in a word.
		push	di, ax
		mov	di, bp
		mov	al, 0cch
		call	Bpt_WriteWordByte
		pop	di, ax
else	;_WRITE_ONLY_WORDS is FALSE
;;                push    es                              ; store es for now
;;                mov     bx, es                          ; Get an alias to this code segment
;;                call    GPMIAlias
;;                mov     es, bx                          ; Write INT 3 to this code spot
		mov	{byte}es:[bp], 0xcc
;;                call    GPMIFreeAlias                   ; Free the used alias
;;                pop     es                              ; Return to our old cs setting
endif	;_WRITE_ONLY_WORDS
		call	Kernel_RestoreWriteProtect
	;
	; Restore the vector for single-stepping. SingleStep is
	; interrupt 1, so the vector address is 1*4 and our regular
	; handler is RpcStepReply
	;
		push	dx
		mov     dx, offset RpcStepReply
		call	SetStepHandler
		pop     dx

	;
	; All done. Go back to doing our thing. Note we must
	; clear out the T bit from the flags word we're restoring,
	; as well as resetting the interrupt bit to what it was before
	; the step.
	; 
		mov	bp, sp
		mov	ax, [bp].SBRF_flags
		and	ax, NOT (TFlag or IFlag)
		or	ah, cs:[bptSkipIF]
		mov	[bp].SBRF_flags, ax
	;
	; Restore the interrupt mask w/timer interrupts enabled...
	; 
		mov	al, cs:[bptSkipMask1]
		out	PIC1_REG, al
                pop     bx
                pop     ds
		pop	ax
		pop	bp
		pop	es
		iret
BptSkipRecover	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BptStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to stuff an INT 3 at es:di while coping with
		the memory possibly being write-protected.

CALLED BY:	(INTERNAL)
PASS:		es:di	= place at which to store 0xcc
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BptStore	proc	near
	DPS DEBUG_BPT, bs
	DPW DEBUG_BPT, es
	DPW DEBUG_BPT, di
	DPW DEBUG_BPT, es:[di]
		call	Kernel_EnsureESWritable
if	 _WRITE_ONLY_WORDS
	; Can only write words in this version of the stub.  So, read the word
	; and determine which half of the word should contain the INT 3, and
	; then write it back out.
	
		push	ax
		mov	al, 0cch
		call	Bpt_WriteWordByte
		pop	ax
else	;_WRITE_ONLY_WORDS is FALSE
	push	ax
	DPC	DEBUG_FALK2, 'P'
	DPW	DEBUG_FALK2, es
	DPW	DEBUG_FALK2, di
		mov	{byte}es:[di], 0xcc	; restore breakpoint now
	pop		ax
endif	;_WRITE_ONLY_WORDS
		call	Kernel_RestoreWriteProtect
		ret
BptStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Skip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of the machine to skip over a breakpoint, but
		don't actually do it yet.

CALLED BY:	Bpt_RpcSkip, Bpt_Check
PASS:		the usual
		the correct instruction to be executed should already
			have been written where the breakpoint will
			eventually be installed.
RETURN:		state block set up to continue the machine, either to
		    execute a single instruction, or to run free (if the
		    instruction being skipped has been emulated for some
		    reason)
		if single-stepping:
			single-step vector changed to BptSkipRecover
			bptSkipAddr set to the address of the breakpoint
			bptSkipMask1 holds real PIC1 mask
			bptSkipIF holds interrupt flag to restore when skip is
			    complete
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Skip	proc	near
		.enter
	DPC DEBUG_BPT, 'S', inv
	;
	; See if the thing is a software interrupt of some sort. If so, we
	; need to emulate it, as 286 and later processors turn off the TF
	; early in the handling of INT so the trap isn't actually taken
	; until the interrupt returns.
	;
	; We also take care of emulating PUSHF and IN AL, 21h instructions
	; to avoid having to clean up after having executed them.
	;
			CheckHack <offset state_cs eq offset state_ip+2>
		les	di, {fptr}ss:[bp].state_ip
	DPW DEBUG_BPT, es
	DPW DEBUG_BPT, di
		mov	ax, es:[di]
	DPW DEBUG_BPT, ax
		cmp	al, 0xcd	; two-byte software interrupt?
		je	emulateInterrupt
		cmp	al, 0xcc	; breakpoint?
		je	breakpoint

		cmp	ax, 0x21e4	; byte IN from 21h?
		je	emulatePIC1Read
		cmp	al, 0x9c	; pushf?
		je	emulatePushf
		
		cmp	al, 0xfa	; CLI?
		je	emulateIF
		cmp	al, 0xfb	; STI?
		je	emulateIF
		jmp	setupForSkip
	;--------------------
emulateIF:
		andnf	[bp].state_flags, not IFlag	; assume CLI
		test	al, 1			; CLI (0xfa vs. 0xfb for STI)?
		jz	emulatedIncIP		; yes -- done
		ornf	ss:[bp].state_flags, IFlag
		jmp	emulatedIncIP
	;--------------------
breakpoint:
		mov	al, RPC_HALT_BPT
		inc	ss:[bp].state_ip	; pretend bpt hit
		segmov	es, ds
		mov	ds:[bptSkipDesc], 0	; act as if BptSkipRecover
						;  was hit... (never set
						;  bptSkipAddr, but caller
						;  might have set this beast)
		jmp	IRQCommon_StoreHaltCode
	;--------------------
emulatePushf:
		cmp	ss:[bp].state_ss, sstack
		je	setupForSkip		; can't do this on stub stack

		call	BptStore		; restore breakpoint now
		mov	es, ss:[bp].state_ss
		mov	di, ss:[bp].state_sp	; es:di <- ss:sp
		dec	di
		dec	di			; room for push...
		mov	ax, ss:[bp].state_flags
		andnf	ax, NOT TFlag 		; Clear TF
		mov	es:[di], ax		; push flags
		mov	ss:[bp].state_sp, di	; store new sp
		jmp	emulatedIncIP
	;--------------------
emulatePIC1Read:
		call	BptStore		; restore breakpoint now
		mov	al, ss:[bp].state_PIC1
		mov	ss:[bp].state_al, al
		inc	ss:[bp].state_ip	; two-byte instruction just
						;  emulated
		.assert	$ eq emulatedIncIP
emulatedIncIP:
		inc	ss:[bp].state_ip
	;
	; Restore ES to scode and continue the machine normally, without
	; messing with single-stepping or the step vector.
	; 
emulated:
		segmov	es, ds
		mov	ds:[bptSkipDesc], 0	; act as if BptSkipRecover
						;  was hit... (never set
						;  bptSkipAddr, but caller
						;  might have set this beast)
done:
		.leave
		ret
	;--------------------
emulateInterrupt:
		cmp	ss:[bp].state_ss, sstack
		je	setupForSkip		; can't do this on stub stack

	;
	; Stuff the breakpoint back at the instruction start.
	; 
		push	ax
		call	BptStore
		pop	ax
		call	EmulateInterrupt
		jmp	emulated
	;--------------------
setupForSkip:
	;
	; Save the address of the instruction we're about to execute
	; 
		mov	ds:[bptSkipAddr].offset, di
		mov	ds:[bptSkipAddr].segment, es
	;
	; Re-vector the single-step trap to our own routine.
	; 
                push    dx
                mov     dx, offset BptSkipRecover
                call    SetStepHandler
                pop     dx

;		clr	ax
;		mov	es, ax
;		mov	es:[1*4].offset, offset BptSkipRecover
;		segmov	es, ds
	;
	; Go do the other stuff associated with continuing
	; 
		mov	al, [bp].state_PIC1
		mov	ds:[bptSkipMask1], al
		or	[bp].state_PIC1, TIMER_MASK; Keep timer interrupt OFF
						; so the thread won't c-switch
;;;;  XXX Look at the use of this flag!  It is what gets left on the stack for the longe run!
		or	[bp].state_flags, TFlag	; Set trace bit on return.
	;
	; Save the interrupt flag and clear it out of the saved flags.
	; This is to prevent the processor from taking an interrupt
	; upon return, executing the first instruction of the interrupt
	; routine, trapping to BptSkipRecover, restoring the breakpoint
	; instruction, continuing the interrupt routine, returning
	; to the instruction we wanted to step over and taking the
	; now-present breakpoint at that location. You might think this
	; is an unusual case, but the handling of the SKIPBPT rpc
	; on a 4.77 MHz 8088 appears to take .52 ms to return to
	; the interrupted program, which is exactly the time it takes
	; to send out the first byte of the reply.
	;
		mov	al, [bp].state_flags.high
		and	al, IFlag SHR 8
		mov	ds:[bptSkipIF], al
		and	[bp].state_flags, NOT IFlag

		jmp	done
Bpt_Skip	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_BlockChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of a change in a block on the heap.

CALLED BY:	KernelMemory
PASS:		al	= Function code:
			    DEBUG_REALLOC   - block reallocated
			    DEBUG_DISCARD   - block discarded
			    DEBUG_SWAPOUT   - block swapped out
			    DEBUG_SWAPIN    - block swapped in
			    DEBUG_MOVE	    - block moved
			    DEBUG_FREE	    - block freed
			    DEBUG_MODIFY    - block flags modified
			    DEBUG_MEM_LOADER_MOVED - guess. ss:[bp].state_es is
						 new segment of loader.

		bx	= affected handle (HM_addr usable for all
			  except DEBUG_MOVE, DEBUG_SWAPOUT, and DEBUG_DISCARD)
		dx	= actual HM_addr, if it's 0 and al != DEBUG_MOVE
		ds	= kernel data segment
		es	= destination segment for DEBUG_MOVE
		ss:bp	= StateBlock, if DEBUG_MEM_LOADER_MOVED
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_BlockChange	proc	near
		uses	ax, cx, si, ds, es, di, dx
		.enter
	;
	; First get the new segment of the block into CX. If the block's been
	; freed, we force the new segment to 0, so any affected bpt won't
	; fire. If the thing's been swapped out, discarded, swapped in,
	; or resized, its HM_addr field is valid (it's 0 if the thing's history)
	; 
		cmp	al, DEBUG_MODIFY
		je	done			; do nothing on flags-change

		clr	cx
		cmp	al, DEBUG_FREE
		je	haveNewSegment
		cmp	al, DEBUG_SWAPOUT
		je	haveNewSegment
		cmp	al, DEBUG_DISCARD
		je	haveNewSegment

		mov	cx, es
		cmp	al, DEBUG_MOVE
		je	checkForZero

		push	ax
		segmov	es, ds			; Kernel_GetHandleAddress needs
						;  es = kdata
		call	Kernel_GetHandleAddress
		mov_tr	cx, ax
		pop	ax

		cmp	al, DEBUG_MEM_LOADER_MOVED
		jne	checkForZero
		mov	cx, ss:[bp].state_es
		clr	bx			; handle is 0, so all
						;  breakpoints (all of which
						;  have BD_handle set to 0
						;  since we're unable to look
						;  up handles until the kernel
						;  is loaded) get adjusted.
checkForZero:
		tst	cx
		jnz	haveNewSegment
		mov	cx, dx
haveNewSegment:
	DPC DEBUG_BPT, 'M', inverse
	DPW DEBUG_BPT, bx
	DPW DEBUG_BPT, cx

		PointDSAtStub
	;
	; Now find any breakpoint set in this block and adjust the segment
	; portion of its address to match the new one. Note that we do *not*
	; free the breakpoint when the handle has been freed. The host should
	; free up the various clients and only then will we free BptDesc.
	; 
		mov	si, offset bptChain - offset BD_next
bptLoop:
		mov	dx, si			; save prev pointer, in case
						;  the thing is a zombie...
		mov	si, ds:[si].BD_next
bptLoopHaveNext:
		tst	si
		jz	done
		
		cmp	ds:[si].BD_handle, bx
		jne	bptLoop
		
		tst	ds:[si].BD_clients
		jz	handleZombie

		mov	ds:[si].BD_addr.segment, cx
		jcxz	bptLoop

		tst	ds:[bptsInstalled]
		jz	bptLoop
		les	di, ds:[si].BD_addr
		call	BptStore
		jmp	bptLoop
done:
		.leave
		ret

handleZombie:
	;
	; Deal with a zombie BptDesc, as created when the last breakpoint
	; for an address is cleared while the block is swapped out (with our
	; INT 3 still in it). When the block comes back in from the device,
	; or if its swap space is discarded, we can finally free the BptDesc.
	; If the block is resident, we need also to restore the instruction
	; overwritten by the breakpoint.
	; 
		mov	es, ds:[kdata]
		test	es:[bx].HM_flags, mask HF_SWAPPED
		jnz	bptLoop		; if block still swapped, just ignore
					;  the breakpoint
		jcxz	biffZombie	; if block still not resident, it
					;  means the thing was discarded from
					;  the swap device, so we need no
					;  longer tend this zombie
		mov	es, cx		; es <- new segment
		mov	di, ds:[si].BD_addr.offset

		call	Kernel_EnsureESWritable
		push	ax
if	 _WRITE_ONLY_WORDS
		mov	al, ds:[si].BD_inst
		call	Bpt_WriteWordByte
else	;_WRITE_ONLY_WORDS is FALSE
		mov	al, ds:[si].BD_inst
		stosb
endif	;_WRITE_ONLY_WORDS
		pop	ax
		call	Kernel_RestoreWriteProtect

biffZombie:
	;
	; Now need to remove the zombie from the breakpoint chain.
	; 
		mov	ax, ds:[si].BD_next
		xchg	dx, si			; ds:si <- previous BptDesc
		mov	ds:[si].BD_next, ax	; unlink the zombie
		xchg	dx, si		; ds:si <- zombie again.

		call	Bpt_Free	;  and free this one
	;
	; Point si to the next descriptor; ds:dx is still valid as the previous
	; descriptor.
	; 
		mov_tr	si, ax
		jmp	bptLoopHaveNext
Bpt_BlockChange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_ResLoad
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a resource being loaded in fresh, resetting any
		breakpoints in the resource.

CALLED BY:	KernelResLoad
PASS:		ax	= new segment of the resource
		bx	= handle of the resource
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_ResLoad	proc	near
		uses	ds, si, di, es, ax
		.enter
		PointDSAtStub
		mov	si, offset bptChain - offset BD_next
		mov	es, ax
bptLoop:
		mov	si, ds:[si].BD_next
		tst	si
		jz	done
		cmp	ds:[si].BD_handle, bx
		jne	bptLoop
	;
	; Store the segment of the resource in the BD_addr.segment field.
	; 
		mov	ds:[si].BD_addr.segment, es
	;
	; Now fetch the current instruction at the offset and replace it
	; with a breakpoint. 
	; 
		tst	ds:[bptsInstalled]	; just in case...
		jz	bptLoop

		mov	di, ds:[si].BD_addr.offset
		mov	al, es:[di]
		mov	ds:[si].BD_inst, al
		call	BptStore
		jmp	bptLoop

done:
		.leave
		ret
Bpt_ResLoad	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_SysExiting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the system is in the process of exiting and will
		no longer be mapping XIP pages in (nor be able to do so)

CALLED BY:	(EXTERNAL) KernelProcess
PASS:		ds = es = cgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di
SIDE EFFECTS:	XIP pages for existing breakpoints mapped in & out
     		sysFlags.nomap set

PSEUDO CODE/STRATEGY:
		Because Bpt_Uninstall has been called (from SaveState) and that
		has replaced the instructions for all mapped-in XIP
		pages, and because Bpt_UpdatePending will remove the
		instruction for any page that gets mapped in by us, we need 
		only map in all pages with breakpoints in them, and set
		the "nomap" flag to keep Bpt_Install from installing them
		again.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_SysExiting	proc	near
		uses	es
		.enter
		mov	es, ds:[kdata]
		mov	bx, ds:[curXIPPageOff]
		mov	cx, ds:[bx]
		
		mov	si, offset bptChain - offset BD_next
bptLoop:
		mov	si, ds:[si].BD_next
		tst	si
		jz	done
		
	;
	; See if we need to do anything about this breakpoint. We do if it's
	; an XIP page that's not currently mapped in.
	;
		mov	dx, ds:[si].BD_xipPage
			CheckHack <BPT_NOT_XIP eq -1>
		inc	dx
		jz	bptLoop
		dec	dx
		
		cmp	dx, cx		; current page?
		je	bptLoop		; => already removed
	;
	; Map in the page. This will cause the breakpoint to be removed (because
	; we're doing the mapping). We also set the BD_addr.segment to 0 as
	; added insurance that the thing won't be installed again.
	;
		call	Kernel_SafeMapXIPPage
		mov	dx, BPT_NOT_XIP
		call	Kernel_SafeMapXIPPage
		mov	ds:[si].BD_addr.segment, 0
		jmp	bptLoop
done:
		ornf	ds:[sysFlags], mask nomap
		.leave
		ret
Bpt_SysExiting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Install
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install all the breakpoints that need to be installed.

CALLED BY:	RestoreState
PASS:		ds = es = scode
		[bp].state_flags set for continuation; specifically, TF set
			if single-stepping the machine
RETURN:		nothing
DESTROYED:	anything but segments & bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Install	proc	near
		uses	es, ds, bp
		.enter
	;
	; If single-stepping, then don't install, unless we're stepping to
	; skip a breakpoint, as indicated by bptSkipAddr.segment being non-zero.
	; 10/8: don't install if restoring to our own stack, as we're not
	; continuing the machine.
	; 

	; if oldXIPPage is BPT_NOT_XIP, then install them all as means we
	;  are mapping in an XIP page to and the brekapoints will get 
	; uninstalled here so we can see what really goes there
;		cmp	ds:[oldXIPPage], BPT_NOT_XIP
;		jne	installAll

;; Don't determine breakpoints installed as a group, but individually
;;		tst	ds:[bptsInstalled]
;;		jnz	done
		
DA DEBUG_INIT,<	test	ds:[sysFlags], mask running			>
DA DEBUG_INIT,<	jz	checkTF		; ignore SS if patient never run>
					;  allows bpts to be set in stub
					;  during its initialization

		mov	bx, ds:our_SS
	DPC	DEBUG_BPT, 'S'
	DPC	DEBUG_BPT, 'S'
	DPW	DEBUG_BPT, ss:[bp].state_ss
		cmp	ss:[bp].state_ss, bx
		je	done

DA DEBUG_INIT, <checkTF:						>

		test	ss:[bp].state_flags, TFlag
		jz	installAll
		
		tst	ds:[bptSkipAddr].segment
		jz	done

	;
	; Loop through all the breakpoints, installing an INT 3 for each
	; one that's resident and isn't the breakpoint being skipped.
	; 
installAll:
		mov	si, offset bptChain - offset BD_next
bptLoop:
		mov	si, ds:[si].BD_next
		tst	si
		jz	allInstalled

        ; Skip if already installed
                tst     ds:[si].BD_installed
                jnz     bptLoop
                		
	;
	; If geos gone, don't install any bpt with a non-zero handle.
	; 
		tst	ds:[si].BD_handle
		jz	checkSkip
		test	ds:[sysFlags], mask geosgone
		jnz	bptLoop

	; see if it's an XIP handle...
		mov	dx, ds:[si].BD_xipPage
			CheckHack <BPT_NOT_XIP eq -1>
		inc	dx
		jz	checkSkip

	; it's an XIP handle, if sysFlags.nomap is set, we don't install it,
	; as we'll have no way to remove it.

		dec	dx

		test	ds:[sysFlags], mask nomap
		jnz	bptLoop

	; see if the page is currently mapped in. can't install it if not

		push	es
		mov	bx, ds:[curXIPPageOff]
		mov	es, ds:[kdata]
		cmp	dx, es:[bx]
		pop	es
		jne	bptLoop

	; if the bpt is still pending we can't install it yet
		test	ds:[si].BD_state, mask BSF_SET_PENDING
		jnz	bptLoop
checkSkip:
		cmp	si, ds:[bptSkipDesc]
		je	bptLoop

		les	di, ds:[si].BD_addr
		mov	ax, es
		tst	ax
		jz	bptLoop		; => block non-resident, so nothing
					;  to set

		cmp	ax, ds:[bptSkipAddr].segment
		jne	installBpt
		cmp	di, ds:[bptSkipAddr].offset
		je	bptLoop
installBpt:
                mov     ds:[si].BD_installed, 1
		call	BptStore
		jmp	bptLoop
allInstalled:
		mov	ds:[bptsInstalled], TRUE
done:
		.leave
		ret

Bpt_Install	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_UpdatePending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deal with pending breakpoints

CALLED BY:	KernelMemoryBankPage
PASS:		ds = es = scode
		bx = page number
RETURN:		nothing
DESTROYED:	anything but segments & bp

PSEUDO CODE/STRATEGY:
		for all bpts that have BSF_SET_PENDING set for the 
			new page I fetch the original instruction and tuen off
			the BSF_SET_PENDING to allow it to get installed by
			Bpt_Install
		for all bpts that have BSF_DELETE_PENDING set for the new
			page, I turn off the BSF_DELETE_PENDING bit and
			call BptDelete which restores the original instruction
			and biffs the BptDesc structure from the list and
			frees up its memory
			THIS IS NO LONGER USED

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_UpdatePending	proc	near
		uses	es, si, dx, ax, di, bx, bp
		.enter
	;
	; Loop through all the breakpoints, installing an INT 3 for each
	; one that's resident and isn't the breakpoint being skipped.
	; 
		mov	si, offset bptChain - offset BD_next
bptLoop:
		mov	bp, si
		mov	si, ds:[si].BD_next
		tst	si
		jz	done

	;
	; If geos gone, don't install any bpt with a non-zero handle.
	; 
		tst	ds:[si].BD_handle
		jz	bptLoop

	; see if it's an XIP handle...
		mov	dx, ds:[si].BD_xipPage
		cmp	dx, BPT_NOT_XIP
		jz	bptLoop

	; it's an XIP handle, so see if it's currently banked in

		cmp	dx, bx
		jne	bptLoop

		test	ds:[si].BD_state, mask BSF_SET_PENDING
		jz	checkDelete

	; get the original instruction if it is an XIP breakpoint
		les	di, ds:[si].BD_addr
		mov	al, es:[di]

	; we now have enough information to complete the bpt and turn off
	; the set pending bit
		mov	ds:[si].BD_inst, al
		and	ds:[si].BD_state, not mask BSF_SET_PENDING

	; NOTE: I don't have to actually install the breakpoint since
	; Bpt_Install gets called in the call to RestoreState. so I
	; let it happen there...

	; fallthru, it might be both
checkDelete:
if 0
		test	ds:[si].BD_state, mask  BSF_DELETE_PENDING
		jz	checkRestore
	; ok, it's a delete pending so lets replace the instruction
	; and delete it. Since we know it's mapped in we can set the
	; xipPage field to BPT_NOT_XIP so BptDelete doesn't bother to
	; check again
		mov	ds:[si].BD_xipPage, BPT_NOT_XIP
		and	ds:[si].BD_state, not mask BSF_DELETE_PENDING
	; now nuke the BptDesc...
		push	bx
		mov	bx, bp	
		xchg	bx, si	; set up pointers
		push	si	; save predeccesor pointer
		call	BptDelete
		pop	si	; ds:[si] is the predeccesor of the deleted
				; bpt which is what we want
		pop	bx
		jmp	bptLoop
checkRestore:
endif
	; if oldXIPPage == BPT_NOT_XIP, then we want to restore the instruction
	; so we can see the orginal memory (pages get banked out with
	; breakpoints set in them) as the stub is trying to map the page in
	; just for its own use. once it's done with the page, it will map
	; in the original one. when this page (the one now mapped) gets mapped
	; in by GEOS once more, the breakpoint we removed here will get reset
	; by Bpt_Install.
	;
	; This whole thing allows us to just have 1 call to the stub for each
	; ResourceCallInt (after mapping in the new page) rather than 2 (one
	; before the map to remove any active breakpoints, and one after to
	; install ones for the page now mapped in).
	;
	; This behaviour is also taken advantage of in BptDelete, which simply
	; maps in the page for the breakpoint it's trying to delete, then
	; remaps the original page, trusting us to restore the original
	; instruction for it. -- ardeb 12/6/94

		cmp	ds:[oldXIPPage], BPT_NOT_XIP
		je	bptLoop

	; ok, lets put in the instruction
		push	bx
		mov	bx, si
		les	si, ds:[bx].BD_addr
		call	BptRestore
		mov	si, bx
		pop	bx
		jmp	bptLoop
done:
		.leave
		ret
Bpt_UpdatePending	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Uninstall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the breakpoints we installed before.

CALLED BY:	SaveState
PASS:		ds = es = scode
RETURN:		nothing
DESTROYED:	anything but segments & bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_Uninstall 	proc	near
		uses	es
		.enter
;; Uninstall each one individually
;;		tst	ds:[bptsInstalled]
;;		jz	done
		mov	si, offset bptChain - offset BD_next
bptLoop:
		mov	si, ds:[si].BD_next
		tst	si
		jz	allRemoved
		
        ; Skip if already uninstalled
                tst     ds:[si].BD_installed
                jz      bptLoop

	;
	; If geos gone, don't install any bpt with a non-zero handle.
	; 
		tst	ds:[si].BD_handle
		jz	checkAddr
		test	ds:[sysFlags], mask geosgone
		jnz	bptLoop
checkAddr:

	; make sure it's not an XIP handle pointing to a resource that's
	; not mapped in
		mov	ax, ds:[si].BD_xipPage
		cmp	ax, BPT_NOT_XIP
		je	notXIP

	; see if it's ready to boogy, if it's still pending we can't do anything
		test	ds:[si].BD_state, mask BSF_SET_PENDING
		jnz	bptLoop

		push	es, di
		mov	es, ds:[kdata]
		mov	di, ds:[curXIPPageOff]
		cmp	es:[di], ax
		pop	es, di
		jne	bptLoop

notXIP:
		les	di, ds:[si].BD_addr
		mov	ax, es
		tst	ax
		jz	bptLoop

		DPS	DEBUG_BPT, bui
		DPW	DEBUG_BPT, es
		DPW	DEBUG_BPT, di
		call	Kernel_EnsureESWritable
		push	ax
if	 _WRITE_ONLY_WORDS
		mov	al, ds:[si].BD_inst
		call	Bpt_WriteWordByte
else	;_WRITE_ONLY_WORDS is FALSE
		mov	al, ds:[si].BD_inst
		stosb
endif	;_WRITE_ONLY_WORDS
		pop	ax
		call	Kernel_RestoreWriteProtect

                ; Mark no longer installed
                mov     ds:[si].BD_installed, 0

		jmp	bptLoop

allRemoved:
		mov	ds:[bptsInstalled], FALSE
done:
		.leave
		ret
Bpt_Uninstall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_RpcSkip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip a breakpoint at the behest of Swat.

CALLED BY:	RPC_SKIPBPT
PASS:		{word}CALLDATA = offset BptClient to skip
RETURN:		doesn't
DESTROYED:	?
SIDE EFFECTS:	The machine is continued.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Bpt_RpcSkip	proc	near
	;
	; Locate the BptDesc so we can get the segment/offset it contains
	; 
		DPC	DEBUG_BPT, 'S'
		mov	ax, {word}ds:[CALLDATA]
		DPW	DEBUG_BPT, ax
findBDLoop:
		mov_tr	bx, ax
		mov	ax, ds:[bx].BC_next
		test	ds:[bx].BC_flags, mask BCF_LAST
		jz	findBDLoop
	;
	; Save the offset of the BptDesc so Bpt_Install knows not to install
	; it when we continue.
	; 
		mov	ds:[bptSkipDesc], ax
	;
	; Set up to skip over the breakpoint.
	; 
		call	Bpt_Skip
	;
	; Do common machine-continue things.
	; 
		jmp	RpcContinueComm
Bpt_RpcSkip	endp

scode		ends

scode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Bpt_Init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialization code for Bpt heap

CALLED BY:	MainHandleInit
PASS:		ds = es = cgroup
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
heapSizeArg	char	'h'
heapSize	char	5 dup(?)

Bpt_Init	proc	near
		uses	bx		; preserve noStartee flag for our
					;  caller...
		.enter
	;
	; See if user has specified a heap size.
	; 
		push	es
		PointESAtStub
		mov	di, offset heapSizeArg
		mov	bx, offset heapSize
		mov	dx, size heapSize
		call	FetchArg
		pop	es
		cmp	bx, offset heapSize
		je	done		; => leave heap at default
	;
	; Convert from ASCII
	; 
		mov	si, offset heapSize
		clr	ax, cx
cvtLoop:
		mov	dx, 10		; current n *= 10
		mul	dx
		mov_tr	dx, ax		; save that in DX...
		lodsb	cs:		;  ...while we load the next char
		andnf	ax, 0xf		; ascii -> binary, of course
					;  (isn't it obvious?)
		add	ax, dx

		cmp	si, bx		; end o' the number?
		jne	cvtLoop		; no. sigh.
		
	;
	; Set as size of initial free block and figure difference from
	; default, so we can adjust the kernel load point.
	; 
		mov	ds:[bptHeapStart], ax
		mov	ds:[bptHeapSize], ax
		sub	ax, BPT_HEAP_SIZE
		add	ax, 15		; round up to nearest paragraph
		sar	ax		; convert to number
		sar	ax		;  of paragraphs.
		sar	ax		;  use SAR as value could be
		sar	ax		;  negative...
	;
	; Increase or reduce kernel load point by that much.
	; 
		add	ds:[kcodeSeg], ax
done:
	;
	; Now calibrate timing breakpoints.
	; 
		call	TB_Calibrate
		.leave
		ret
Bpt_Init	endp

scode	ends
