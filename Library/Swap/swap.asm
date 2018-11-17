COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Library -- Swap Driver Utilities
FILE:		swap.asm

AUTHOR:		Adam de Boor, Jun 17, 1990

ROUTINES:
	Name			Description
	----			-----------
	SwapInit		Initialize a swap map
	SwapWrite		Write a block to the swap device.
	SwapRead		Read a block from the swap device.
	SwapFree		Free a list of pages from a block.
	SwapCompact		Compact pages of a block.
	SwapLockDOS		Grab the DOS/BIOS lock.
	SwapUnlockDOS		Release the DOS/BIOS lock.
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/17/90		Initial revision


DESCRIPTION:
	Functions to manipulate a swap map to help out swap drivers...
	

	$Id: swap.asm,v 1.1 97/04/07 11:15:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;	Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def

;------------------------------------------------------------------------------
;  FULL_EXECUTE_IN_PLACE : Indicates that the swap lib is going to
;       be used in a system where all geodes (or most, at any rate)
;       are to be executed out of ROM.  
;------------------------------------------------------------------------------
ifndef FULL_EXECUTE_IN_PLACE
        FULL_EXECUTE_IN_PLACE           equ     FALSE
endif

;------------------------------------------------------------------------------
;  The .GP file only understands defined/not defined;
;  it can not deal with expression evaluation.
;  Thus, for the TRUE/FALSE conditionals, we define
;  GP symbols that _only_ get defined when the
;  condition is true.
;-----------------------------------------------------------------------------
if      FULL_EXECUTE_IN_PLACE
        GP_FULL_EXECUTE_IN_PLACE        equ     TRUE
endif

if FULL_EXECUTE_IN_PLACE
include Internal/xip.def
endif
include resource.def
include ec.def
include library.def
include	system.def

DefLib		Internal/swap.def

include	Internal/fileInt.def

include	sysstats.def			;for SysGetInfo
include	Internal/heapInt.def		;for internal SysGetInfo types and
					; for HandleSwappedMem




;------------------------------------------------------------------------------
;	Constants
;------------------------------------------------------------------------------

SWAP_PAGE_LIST_TOO_LONG					enum FatalErrors
SWAP_LIST_DOESNT_COVER_BLOCK				enum FatalErrors
SWAP_LIST_CORRUPT					enum FatalErrors
NAUGHTY_PAGE_READ_ROUTINE				enum FatalErrors
KAFF_KAFF						enum FatalErrors
SWAP_COMPACT_UNEXPECTED_ERROR				enum FatalErrors
SWAP_COMPACT_CANNOT_ALLOCATE_TRANSFER_BUFFER		enum FatalErrors
SWAP_COMPACT_OUT_OF_PAGES_BELOW_LIMIT			enum FatalErrors
SWAP_FREE_LIST_CORRUPTED				enum FatalErrors
SWAP_COMPACT_BLOCK_IS_DISCARDABLE			enum FatalErrors

;
; If CHECK_COMPACTION is turned on, the relocations for SwapCompact are
; checked for data integrity.  A few Kbytes of extra buffers are allocated
; to make sure the data has not changed between before and after the 
; compaction.
;
CHECK_COMPACTION		equ	FALSE

if CHECK_COMPACTION

RELOC_CHECK_BLOCK_SIZE		equ	5000

SWAP_COMPACT_CANNOT_ALLOC_RELOC_CHECK_BUFFER		enum FatalErrors
SWAP_COMPACT_RELOC_UNEXPECTED_ERROR			enum FatalErrors
SWAP_COMPACT_RELOC_DATA_CORRUPTED			enum FatalErrors

WARNING_RELOC_CHECK_NOT_COMPLETE_BEFORE			enum Warnings
WARNING_RELOC_CHECK_NOT_COMPLETE_AFTER			enum Warnings

endif

;
;  Statistics gathering for swap space efficiency measurement.
; Set the following equate to TRUE to enable code to measure how efficiently
; the swap space is being used.  This code causes the SwapMap block to be
; twice as large, but it should still be a reasonable size (couple of K) in
; most situations. There are TCL functions to display the statistics in a
; nice format.  The extra word is used to store the actual #bytes being used
; in the page.

GATHER_SWAP_STATS		equ	FALSE

if GATHER_SWAP_STATS
idata		segment
swapSegment	sptr	0
idata		ends
endif

idata	segment
KernelInMemory	BooleanByte	TRUE
idata	ends

;==============================================================================
;
;			  INTERFACE ROUTINES
;
;==============================================================================

Init		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine required b/c we're a library.

CALLED BY:	Kernel
PASS:		various and sundry
RETURN:		carry clear to indicate happiness
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapEntry	proc	far
		.enter
		clc
		.leave
		ret
SwapEntry	endp
ForceRef	SwapEntry	;Exported in .gp file as library entry pt


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a swap map.

CALLED BY:	GLOBAL (swap driver)
PASS:		ax	= number of pages handled by the driver
		bx	= driver's handle
		cx	= size of a page
		si:di	= address of the page write routine
		dx:bp	= address of the page read routine
RETURN:		ax	= segment of the swap map
		bx	= handle of the swap map
		carry set on error
DESTROYED:	cx, dx, bp, si, di, ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SwapInit	proc	far	uses ds, es
		.enter
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, sidi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, dxbp					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; Allocate a fixed block to hold the SwapMap and attendant linked
	; table.
	;
computeSize:
		push	ax
		shl	ax		; 1 word per page handled
		jc	tooBig
if GATHER_SWAP_STATS
		shl	ax, 1		; 1 more word for stats gathering
		jc	tooBig
endif
		add	ax, size SwapMap
		jc	tooBig

		push	cx
		mov	cx, ALLOC_FIXED
		call	MemAllocSetOwner
if GATHER_SWAP_STATS
		mov	cx, dgroup		; save away segment so we 
		mov	ds, cx			;  can find it later from
		mov	ds:[swapSegment], ax	;  TCL.
endif
		pop	cx
		jc	errorPopAX
	;
	; Initialize the various fields.
	;
		mov	ds, ax
		mov	es, ax
		mov	ds:[SM_page], cx
		mov	ds:[SM_read.offset], bp
		mov	ds:[SM_read.segment], dx
		mov	ds:[SM_write.offset], di
		mov	ds:[SM_write.segment], si
	;
	; Initialize all the pages to free.
	;
		pop	ax
		mov	ds:[SM_total], ax
		mov	ds:[SM_numFree], ax
		mov	di, offset SM_pages
		mov	ds:[SM_freeList], di
		xchg	cx, ax		; (1-byte inst)
initLoop:
		lea	ax, es:[di+2]
		stosw
		loop	initLoop
		mov	{word}ds:[di-2], SWAPNIL	; Terminate...
		mov	ax, ds
		clc
done:
		.leave
		ret
errorPopAX:
		pop	ax
		jmp	done
tooBig:
	;
	; Cut the number of pages in half, so the map will fit in 64K
	;
		pop	ax
		shr	ax
		jmp	computeSize
SwapInit	endp


Init		ends
Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a list of pages back to the swap map.

CALLED BY:	GLOBAL
PASS:		ax	= swap map
		bx	= head of list to free
RETURN:		nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	While in most cases the page list will be sorted by ascending
	file position, this will not be true in all cases, so we cannot assume
	it (e.g. if a write fails and earlier, non-clustered pages must be
	allocated for a block, the list will not be sorted). So the loop
	runs like this:
	
		bx <- page to free (in ax on entry)
		bx before first free page?
			- yes: store at front of page
			- no:
				si = first free page
				do {
					ax = next(si)
				} while (ax < bx) {
					si = ax
				} repeat;
				insert bx between si and ax
		ax = next page to free
		loop if not nil

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapFree	proc	far	uses bx, si, ds
		.enter
		mov	ds, ax
		xchg	ax, bx		; ax <- first page
pageLoop:
	;
	; Set up for loop. si = first entry in free list, bx = page being freed.
	;
		mov	si, ds:[SM_freeList]
		mov	bx, ax
		cmp	bx, si		; Goes before head of free list?
		ja	scanLoop	; No -- scan as usual (handles empty
					;  free list too, since SWAPNIL unsigned
					;  is above anything possible in the 
					;  swap map)
		xchg	ax, si		; Place head in ax and SM_freeList+2 in
		mov	si, SM_freeList+2; si (1-byte inst)
		jmp	foundSlot
scanLoop:
		lodsw			; Fetch next block
		cmp	bx, ax		; Page being freed go before it?
		jb	foundSlot	; Oui -- get out.
		xchg	si, ax		; No. Shift focus to next block (1-b i)
		jmp	scanLoop
foundSlot:
	;
	; At this point, ax is the page before which the page being freed is to
	; be inserted, while si is the page that points to ax
	;
		xchg	ds:[bx], ax	; Link new page into list while
					;  fetching out next page to be freed
		mov	ds:[si-2], bx
		inc	ds:[SM_numFree]	; Note another free page
		cmp	ax, SWAPNIL	; Hit end of list?
		jne	pageLoop	; Nope -- free the next page too
		.leave
		ret
SwapFree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a memory block out to the swap device, using the
		callback routine bound to the swap map when it was initialized.

CALLED BY:	GLOBAL (Swap Drivers)
PASS:		ax	= segment of allocated SwapMap
		cx	= size of block to write (bytes)
		dx	= segment of block to write
RETURN:		carry set if block could not be written, else
		ax	= initial page
DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapWrite	proc	far	uses ds, bx, si
		.enter
		mov	ds, ax
	;
	; Calculate the number of pages needed to hold the entire block
	;
		push	dx		; save block segment
		mov	ax, cx
		mov	di, ds:[SM_page]
		clr	dx

		dec	di
		add	ax, di		; round # pages up...
		adc	dx, 0		; handle blocks >= 60K (for 4K page)
		inc	di

		div	di
		xchg	di, ax		; di <- # pages
		pop	dx
	;
	; Try and allocate room for the thing in the swap file.
	;
		mov	bx, -1		; search not limited
		call	AllocSwap	;ax = func(es, bx, di)
		jc	done		; Error -- return now
		
	;
	; Attempt to write the block to the indicated pages
	;
EC <		push	cx						>
		clr	bx		; write from start of block
		call	WritePageList	;ax,carry = func(bx, dx, ax)
EC <		pop	cx		; recover block size for EC	>
		jc	writeError	; Error -- go free page list and return
	;
	; Make sure the allocated list of pages adequately covers the
	; block swapped out. There is one special case in this code: if the
	; block being swapped is 64K long (when rounded up to a page), the
	; final size based on the number of pages will be 0 because it is
	; truncated to 16 bits.
	; 
EC <		push	ax						>
EC <		xchg	si, ax						>
EC <		clr	ax						>
EC <checkLoop:								>
EC <		cmp	si, SWAPNIL					>
EC <		je	checkDone					>
EC <		add	ax, ds:[SM_page]				>
EC <		mov	si, ds:[si]					>
EC <		jnc	checkLoop	; => < 64K, still		>
EC <		cmp	si, SWAPNIL	; if >= 64K, must be at end	>
EC <		ERROR_NE	SWAP_LIST_CORRUPT			>
EC <		tst	ax		; must be = 64K...		>
EC <		ERROR_NZ	SWAP_LIST_CORRUPT			>
EC <		mov	ax, cx		; assume it's correct...	>
EC <checkDone:								>
EC <		cmp	ax, cx						>
EC <		ERROR_B	SWAP_LIST_DOESNT_COVER_BLOCK			>
EC <		pop	ax						>

done:
		.leave
		ret
writeError:
		xchg	bx, ax
		mov	ax, ds
		call	SwapFree
		stc
		jmp	done
SwapWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a block from the swap device via a swap map

CALLED BY:	GLOBAL (Swap Drivers)
PASS:		ax	= segment of SwapMap
		bx	= initial page of swapped block
		cx	= size of swapped block (bytes)
		dx	= segment to which block is to be read
RETURN:		carry clear if no error
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapRead	proc	far	uses si, dx, ds, es
groupHead	local	word		; Head of page-group being written
pageList	local	word		; Head of entire page list
EC<lastOff	local	word						>
		.enter
		mov	ds, ax		; ds <- swap map
		mov	es, ax		; es <- swap map (for later use)
	;
	; Make sure the allocated list of pages adequately covers the
	; block to be swapped in.
	; 
EC <		mov	si, bx						>
EC <		clr	ax						>
EC <checkLoop:								>
EC <		cmp	si, SWAPNIL					>
EC <		je	checkDone					>
EC <		add	ax, ds:[SM_page]				>
EC <		mov	si, ds:[si]					>
EC <		jnc	checkLoop	; => < 64K, still		>
EC <		cmp	si, SWAPNIL	; if >= 64K, must be at end	>
EC <		ERROR_NE	SWAP_LIST_CORRUPT			>
EC <		tst	ax		; must be = 64K...		>
EC <		ERROR_NZ	SWAP_LIST_CORRUPT			>
EC <		mov	ax, cx		; assume it's correct...	>
EC <checkDone:								>
EC <		cmp	ax, cx						>
EC <		ERROR_B	SWAP_LIST_DOESNT_COVER_BLOCK			>
EC <		sub	ax, ds:[SM_page]				>
EC <		cmp	ax, cx						>
EC <		ERROR_A	SWAP_PAGE_LIST_TOO_LONG				>

	;
	; First read in all the pages
	;
		xchg	ax, bx			; ax <- page list
		mov	ss:[pageList], ax
		mov	ds, dx			; Point ds at new bytes
		clr	dx			; Start at beginning of buffer
EC <		mov	lastOff, -1					>
pageLoop:
	;
	; Find the next group of contiguous pages
	;
		mov	si, ax
		mov	ss:[groupHead], ax

scanLoop:
		lodsw	es:		; Fetch next page
		cmp	ax, si		; Matches
		je	scanLoop

		push	ax		; Save head of next group
		
	;
	; Figure the number of bytes to read based on the number of pages and
	; the total number of bytes left.
	; 
		sub	si, ss:[groupHead]; Figure number of pages
		mov	ax, si
		shr	ax
		mov	si, dx		; Preserve read offset
		mul	es:[SM_page]	; Get # of bytes
		jnc	haveSize	; => dx is insignificant, so < 64K
		;
		; Group spans 64K, so back up a page and get the last bit on
		; the next round. We can't just back up the "next page" pointer
		; we saved on the stack as that could be SWAPNIL. Instead, we
		; have to get back to the number of pages in the group and add
		; that, shifted left 1 bit, to the groupHead to get the last
		; page that we'll be unable to read this time through.
		; 
		div	es:[SM_page]
		inc	sp		; discard saved "next page"
		inc	sp
		dec	ax
		shl	ax
		add	ax, ss:[groupHead]
		push	ax		; save new "next page"
		clr	ax		; ax must have been 0, since we don't
					;  do > 64K
		sub	ax, es:[SM_page]
haveSize:

		mov	dx, si		; Restore read offset
		sub	cx, ax		; Reduce # of bytes we're reading in
					;  by the # stored in this group
		jae	moreToCome	; >= 0 means we're ok.
		add	ax, cx		; Else adjust # of bytes by amount of
					;  of overdraft so we don't
					;  overwrite things.
		clr	cx
moreToCome:
		push	cx		; Save # bytes left
		xchg	cx, ax		; cx <- # bytes to read

		mov	ax, ss:[groupHead]; ax <- starting page #
		sub	ax, offset SM_pages
		shr	ax

EC <		push	cx						>
EC <		push	dx						>
EC <		cmp	lastOff, dx					>
EC <		ERROR_E	KAFF_KAFF					>
EC <		mov	lastOff, dx					>
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, es:[SM_read]				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	es:[SM_read]
		jc	error

EC <		pop	ax						>
EC <		cmp	ax, dx						>
EC <		ERROR_NE	NAUGHTY_PAGE_READ_ROUTINE		>
EC <		pop	ax						>
EC <		cmp	ax, cx						>
EC <		ERROR_NE	NAUGHTY_PAGE_READ_ROUTINE		>

		add	dx, cx		; Adjust buffer pointer by amount read
		pop	cx		; Recover bytes left
		pop	ax		;  and next page
		cmp	ax, SWAPNIL
		LONG jne pageLoop
		
	;
	; Now free up all the pages we used.
	;
		mov	ax, es		; ax <- swap map
		mov	bx, ss:[pageList]
		call	SwapFree
done:
		.leave
		ret
error:
EC <		add	sp, 10						>
NEC<		add	sp, 6						>
		stc
		jmp	done
SwapRead	endp

if CHECK_COMPACTION

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapReadNoFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a block from the swap device via a swap map, but don't
		call SwapFree on the pages for the block.  

CALLED BY:	GLOBAL (Swap Drivers)
PASS:		ax	= segment of SwapMap
		bx	= initial page of swapped block
		cx	= size of swapped block (bytes)
		dx	= segment to which block is to be read
RETURN:		carry clear if no error
DESTROYED:	ax, bx, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapReadNoFree	proc	far	uses si, dx, ds, es
groupHead	local	word		; Head of page-group being written
pageList	local	word		; Head of entire page list
		.enter
		mov	ds, ax		; ds <- swap map
		mov	es, ax		; es <- swap map (for later use)
	;
	; First read in all the pages
	;
		xchg	ax, bx			; ax <- page list
		mov	ss:[pageList], ax
		mov	ds, dx			; Point ds at new bytes
		clr	dx			; Start at beginning of buffer
pageLoop:
	;
	; Find the next group of contiguous pages
	;
		mov	si, ax
		mov	ss:[groupHead], ax

scanLoop:
		lodsw	es:		; Fetch next page
		cmp	ax, si		; Matches
		je	scanLoop

		push	ax		; Save head of next group
		
	;
	; Figure the number of bytes to read based on the number of pages and
	; the total number of bytes left.
	; 
		sub	si, ss:[groupHead]; Figure number of pages
		mov	ax, si
		shr	ax
		mov	si, dx		; Preserve read offset
		mul	es:[SM_page]	; Get # of bytes
		jnc	haveSize	; => dx is insignificant, so < 64K
		;
		; Group spans 64K, so back up a page and get the last bit on
		; the next round. We can't just back up the "next page" pointer
		; we saved on the stack as that could be SWAPNIL. Instead, we
		; have to get back to the number of pages in the group and add
		; that, shifted left 1 bit, to the groupHead to get the last
		; page that we'll be unable to read this time through.
		; 
		div	es:[SM_page]
		inc	sp		; discard saved "next page"
		inc	sp
		dec	ax
		shl	ax
		add	ax, ss:[groupHead]
		push	ax		; save new "next page"
		clr	ax		; ax must have been 0, since we don't
					;  do > 64K
		sub	ax, es:[SM_page]
haveSize:

		mov	dx, si		; Restore read offset
		sub	cx, ax		; Reduce # of bytes we're reading in
					;  by the # stored in this group
		jae	moreToCome	; >= 0 means we're ok.
		add	ax, cx		; Else adjust # of bytes by amount of
					;  of overdraft so we don't
					;  overwrite things.
		clr	cx
moreToCome:
		push	cx		; Save # bytes left
		xchg	cx, ax		; cx <- # bytes to read

		mov	ax, ss:[groupHead]; ax <- starting page #
		sub	ax, offset SM_pages
		shr	ax
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, es:[SM_read]				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	es:[SM_read]
		jc	error

		add	dx, cx		; Adjust buffer pointer by amount read
		pop	cx		; Recover bytes left
		pop	ax		;  and next page
		cmp	ax, SWAPNIL
		jne	pageLoop
		
	;
	; Now free up all the pages we used.
	;
		mov	ax, es		; ax <- swap map
		mov	bx, ss:[pageList]
		;call	SwapFree
done:
		.leave
		ret
error:
		add	sp, 6				
		stc
		jmp	done
SwapReadNoFree	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapCompact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate data in the swap driver to reduce the total 
		space used by the driver to below the desired target.

CALLED BY:	GLOBAL (Swap Drivers)
PASS:		ax	= segment of SwapMap
		cx	= swap driver ID.
		dx	= in Kbytes, the desired maximum space to be 
			  taken up in Extended Memory.
		
RETURN:		carry set if couldn't meet the target. 
DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapCompact	proc	far
maxPage		local	word
bufHandle	local	hptr
swapDriverID	local	nptr

if 	CHECK_COMPACTION
beforeHan	local	hptr						
afterHan	local	hptr						
beforeSeg	local	sptr						
afterSeg	local	sptr						
endif

		uses	ax,bx,cx,dx,si,di,ds,es
		.enter
		mov	swapDriverID, cx
		mov	es, ax			;SwapMap
		mov	cx, es:[SM_page]
	;
	; maximum page desired is the target usage divided by 
	; the page size.  (If page size is 1K, then the maximum page is
	; the desired target usage).
	;
		mov	ax, dx			;ax = max. Kbytes.
		mov	bx, 1024		;bytes/Kbytes.
		cmp	cx, bx
		je	gotPage

		mul	bx			;dx:ax = target in bytes
		div	cx			;ax = max. page number
		inc	ax			;round up
gotPage:
	;
	; now we have the maximum page in swap driver's terms, i.e., 
	; pages starting at 0, numbered sequentially.  Transform
	; that to the type of page that can be used to lookup into the
	; swap map.
	; 
		add	ax, offset SM_pages
		shl	ax
		mov	maxPage, ax

	;
	; Need a page size buffer.
	;
		mov	ax, cx			;page size

if 	CHECK_COMPACTION
	; twice the space for EC, so we can do an integrity check.
		shl	ax			
endif
		mov	cl, 0
		mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
		call	MemAlloc
EC <		ERROR_C SWAP_COMPACT_CANNOT_ALLOCATE_TRANSFER_BUFFER	>
		mov	bufHandle, bx
		push	ax			;buffer segment

if 	CHECK_COMPACTION
	;
	; Allocate a couple of large blocks for integrity checks...
	;
		mov	ax, RELOC_CHECK_BLOCK_SIZE
		mov	cl, mask HF_FIXED
		mov	ch, 0
		call	MemAlloc
		ERROR_C SWAP_COMPACT_CANNOT_ALLOC_RELOC_CHECK_BUFFER
		mov	beforeHan, bx
		mov	beforeSeg, ax

		mov	ax, RELOC_CHECK_BLOCK_SIZE
		mov	cl, mask HF_FIXED
		mov	ch, 0
		call	MemAlloc
		ERROR_C SWAP_COMPACT_CANNOT_ALLOC_RELOC_CHECK_BUFFER
		mov	afterHan, bx
		mov	afterSeg, ax
endif
	;
	; Walk the handle table
	;
		mov	ax, SGIT_HANDLE_TABLE_START
		call	SysGetInfo
		mov	si, ax

		mov	ax, SGIT_HANDLE_TABLE_SEGMENT
		call	SysGetInfo
		mov	ds, ax			;ds:si = Handle Table

		mov	ax, SGIT_LAST_HANDLE
		call	SysGetInfo
		mov	cx, ax

		mov	bx, swapDriverID
		mov	ax, maxPage
		pop	dx			;buffer segment

testHandleLoop:
	; bx = the calling swap driver.
	; cx = last handle (exit case)
	; ds:si = handle to test
	; ax = maximum page to use.
	; dx = buffer segment
		; Are we swapped out?
		tst	ds:[si].HSM_addr
		jnz	nextHandle

		; Are we swapped out to this device?
		cmp	ds:[si].HSM_swapDriver, bx
		jne	nextHandle

		; Skip discarded blocks
		test	ds:[si].HSM_flags, mask HF_DISCARDED
		jnz	nextHandle

if 0
;; so it turns out some discardable VM blocks are not discarded under
;; certain conditions.

EC <		test	ds:[si].HSM_flags, mask HF_DISCARDABLE		>
EC <		ERROR_NZ SWAP_COMPACT_BLOCK_IS_DISCARDABLE		>
endif

		; caught one!
if 	CHECK_COMPACTION
		push	ax, bx, cx, dx
	;
	; Read the block into a memory block before the relocation, so 
	; that we can compare the bytes with what is in the block after
	; relocation.  They should be the same, or else...
	;
		mov	ax, es			;SwapMap
		mov	bx, ds:[si].HSM_swapID
		mov	cx, ds:[si].HSM_size
		shl	cx
		shl	cx
		shl	cx
		shl	cx
		cmp	cx, RELOC_CHECK_BLOCK_SIZE
		jbe	gotSize
	;
	; don't go over the block size, even if it means not checking
	; the whole block.
	;
		mov	cx, RELOC_CHECK_BLOCK_SIZE
		WARNING_A WARNING_RELOC_CHECK_NOT_COMPLETE_BEFORE
gotSize:
		mov	dx, beforeSeg
		call	SwapReadNoFree
		ERROR_C	SWAP_COMPACT_RELOC_UNEXPECTED_ERROR
		pop	ax, bx, cx, dx
endif

		mov	di, ds:[si].HSM_swapID
		call	RelocPageList
		mov	ds:[si].HSM_swapID, di

if	CHECK_COMPACTION
		pushf
		push	ax, bx, cx, dx, ds, si, es, di
	;
	; Read the block into memory now that it has been relocated, and
	; compare the bytes with what was in the block before relocation.
	; They should be the same, otherwise relocation is messing up
	; somewhere.
	;
		mov	ax, es			;SwapMap
		mov	bx, ds:[si].HSM_swapID
		mov	cx, ds:[si].HSM_size
		shl	cx
		shl	cx
		shl	cx
		shl	cx
		cmp	cx, RELOC_CHECK_BLOCK_SIZE
		jbe	gotSizeAfter
	;
	; don't go over the block size, even if it means not checking
	; the whole block.
	;
		mov	cx, RELOC_CHECK_BLOCK_SIZE
		WARNING_A WARNING_RELOC_CHECK_NOT_COMPLETE_AFTER
gotSizeAfter:
		mov	dx, afterSeg
		call	SwapReadNoFree
		ERROR_C	SWAP_COMPACT_RELOC_UNEXPECTED_ERROR

	;
	; Compare beforeSeg with afterSeg.  Hopefully, they will
	; contain the same data.
	;
		mov	cx, ds:[si].HSM_size
		shl	cx
		shl	cx
		shl	cx
		shl	cx
		mov	ds, beforeSeg
		mov	es, afterSeg
		clr	si, di
		cmp	cx, RELOC_CHECK_BLOCK_SIZE
		jbe	gotSizeCmp		;don't go over the block size.
		mov	cx, RELOC_CHECK_BLOCK_SIZE
gotSizeCmp:
		repe	cmpsb			;Z=1 if no mismatch.
		ERROR_NZ SWAP_COMPACT_RELOC_DATA_CORRUPTED
		
		pop	ax, bx, cx, dx, ds, si, es, di
		popf
endif
		jc	done			;missed the target

nextHandle:
		; test next handle
		add	si, size HandleGen
		cmp	si, cx
		jbe	testHandleLoop
		clc

done:	
		pushf
if 	CHECK_COMPACTION
		mov	bx, beforeHan
		call	MemFree
		mov	bx, afterHan
		call	MemFree
endif
		mov	bx, bufHandle
		call	MemFree
		popf

		.leave
		ret
SwapCompact	endp


;==============================================================================
;
;			   UTILITY ROUTINES
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocSwap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate enough pages to hold the memory block

CALLED BY:	SwapWrite, WritePageList
PASS:		ds	= segment of SwapMap
		bx	= page beyond which allocation cannot go. -1
			  if unrestricted (used by WritePageList)
		di	= number of pages required to hold the block
RETURN:		ax	= first page to write
		carry set if couldn't find enough pages
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The allocation proceeds in two phases: phase1 attempts to get a
	cluster of pages big enough to	hold the entire block. Failing
	that, phase2 kicks in and tries to allocate enough pages, contiguous
	or not.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocSwap	proc	near	uses cx, dx, bx, si
		.enter
		cmp	ds:[SM_numFree], di
		jb	done	; If there aren't enough pages left to hold the
				;  block, get out now.
	;
	; First see if we can find enough pages that are contiguous
	; to hold the thing. cx is a counter that is reset each time
	; a non-contiguous link is seen. If cx reaches zero, we've found
	; a block that's big enough.
	;
		lea	cx, [di-1]	; Initialize counter. We want di
					;  contiguous pages, but that means we
					;  only need to search di-1 pages for
					;  contiguity -- we don't care if the
					;  last one is contiguous with its next
					;  page or not.
		mov	dx, SM_freeList	; Signal region begins at head
		mov	ax, ds:[SM_freeList]; Fetch listhead
		jcxz	needOne		; If need only one page, we're done.
phase1:
		mov	si, ax		; Point to next (not done below so we've
					;  got something in SI if we hit the end
					;  at the same time cx runs out)
		lodsw			; Fetch next page #
		cmp	ax, si		; Is it immediately after this one
					;  (lodsw added 2 to si)?
		je	wasContig	; Ja -- another one for the gipper
		mov	cx, di		; Nope -- reset the counter
		lea	dx, [si-2]	; Record page that points to start
					;  of potential contiguous region for
					;  use should the region end up big
					;  enough.
wasContig:
		cmp	ax, SWAPNIL	; Hit the end?
		loopne	phase1		; Loop if not so and haven't found
					;  region big enough.
		jne	gotContig	; If hit the end, it means we're short
					;  of pages, so fall into phase 2
		;--------------------
phase2:
	;
	; Couldn't allocate a contiguous range of pages -- just take
	; the first n on the list, pointing si at the last one to use.
	;
		mov	ax, ds:[SM_freeList]
		mov	dx, SM_freeList
		mov	si, ax
		lea	cx, [di-1]
		jcxz	boundsCheck
findEnd:
		mov	si, ds:[si]
		loop	findEnd

boundsCheck:
	;
	; Make sure final page not beyond the limit set by the caller
	;
		cmp	bx, si
		jb	done
gotList:
		sub	ds:[SM_numFree], di	; Reduce free-page count
		
		mov	bx, ds:[si]		; Fetch page after end
		mov	{word}ds:[si], SWAPNIL	; Terminate returned list

		mov	si, dx			; Fetch page before list
		mov	ds:[si], bx		; Link around returned list
		clc				; Signal success
done:
		.leave
		ret
		;--------------------
needOne:
	;
	; When we've found a contiguous block, si points to the
	; final page. Set si to the first page (the only one we need)
	;
		mov	si, ax
gotContig:
	;
	; SI points to final page in the list. To find the first
	; page in the contiguous region, we need to figure
	;	si - (di-1) * 2
	; e.g.
	; 	di = 3
	;		n	: n+2
	;		n+2	: n+4
	;	si ->	n+4	: nil
	;	(n+4) - (3-1) * 2 = n
	;
		cmp	si, bx
		jae	phase2		; last page is out-of-bounds -- try
					;  for non-contiguous pages instead.
		lea	ax, [di-1]
		shl	ax
		sub	ax, si		; in reverse order
		neg	ax		;  so compensate
		jmp	gotList
AllocSwap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WritePageList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a block to the swap device in pages.

CALLED BY:	SwapWrite, WritePageList (in case of error)
PASS:		ds	= segment of SwapMap
		cx	= number of bytes to swap
		ax	= first page to use in swap file
		di	= number of pages being written
		dx:bx	= address from which to start writing
RETURN:		carry set if couldn't swap entire block.
		ax	= head of page list (may be different if initial list
			  couldn't be used due to disk space constraints)
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
		This function is made somewhat more complicated by the
		necessity of handling an error when performing a write. In
		such a case, we figure how many pages were actually written,
		then try to allocate another set of pages from earlier in the
		file to hold the rest.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WritePageList	proc	near	uses dx, bp, bx, es
listHead	local	word		; Head of page list, in case it changes
groupHead	local	word		; Head of group being written out
prevTail	local	word		; Tail of previously written group
bytesLeft	local	word		; Bytes left to write
blockSeg	local	sptr		; Segment of the block
		.enter
		mov	ss:[bytesLeft], cx
		mov	ss:[blockSeg], dx
	;
	; Work down the list, writing out contiguous pieces to
	; the swap device.
	;
		mov	cx, di
		mov	ss:[listHead], ax
		mov	ss:[prevTail], SWAPNIL
		mov	dx, bx		; Start writing from the beginning
writeLoop:
		cmp	ax, SWAPNIL	; End of loop?
		je	done
		mov	ss:[groupHead], ax 	; Save starting page
	;
	; figure # of contiguous pages
	;
		xchg	si, ax		; si <- first page
contigLoop:
		lodsw			; fetch next
		cmp	ax, si		; contiguous?
		loope	contigLoop	; loop if so and more pages to write
		
		mov	bx, si
		sub	bx, ss:[groupHead]
		shr	bx		; divide by two to get actual # pages

	;
	; Figure how many bytes that is.
	;
figureSize:
		push 	ax, cx
		push	bx

		mov	ax, ds:[SM_page]; Calculate # of bytes to write
		mov	cx, dx
		mul	bx
		jnc	haveSize
		;
		; Block is 64K. We can't write 64K at once b/c we've only
		; got one word of size, so we reduce our aim by one page
		; and refigure the number of bytes we're writing.
		; 
		mov	dx, cx		; dx <- saved write offset
		pop	bx		; clear the stack
		pop	ax, cx		; recover pages left and clear stack
		dec	bx		; one fewer page being written
		dec	si		; back up to last page in
		dec	si		;  the group
		mov	ax, si		; set that as the next page to write
		inc	cx		;  and record one more page as still
					;  needing writing
		jmp	figureSize

haveSize:
		xchg	cx, ax		; cx <- # to write, ax <- write offset
		sub	ss:[bytesLeft], cx	; Adjust size left
		jae	notFrag		; Any left (or exact fit)?
		add	cx, ss:[bytesLeft]; Trim amount to write by size of
					;  overdraft
if GATHER_SWAP_STATS
	; ds:si -> last page to be written.  If the #bytesLeft is less than
	; 0, write something out in the extra part of the SwapMap buffer 
	; allocated when we want to GATHER_SWAP_STATS.  We can read
	; this info later for statistics gathering purposes.
		push	ax, bx
		mov	bx, ds:[SM_total]	; ax = #pages
		shl	bx, 1			; to get to extra space
		mov	ax, ds:[SM_page]	; page size
		add	ax, ss:[bytesLeft]	; calc #bytes used in page
		mov	ds:[si][bx], ax		; store result
		pop	ax, bx
endif
notFrag:
	;
	; Call the callback function to perform the write.
	;
		xchg	dx, ax		; dx <- offset from which to write (as
					;  preserved through above calculations)
		push	ds
		segmov	es, ds		; es <- swap map
		mov	ds, ss:[blockSeg]; Point ds:dx at buffer
		mov	ax, ss:[groupHead]; ax <- page number from which to
		sub	ax, offset SM_pages	; start writing
		shr	ax
		push	cx
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, es:[SM_write]				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	es:[SM_write]
		pop	ax		; ax <- amount that should have been
					;  written, if no error
		pop	ds
		pop	bx		; Recover pages we hope were written
		jc	writeError
	;
	; Handle end-of-loop bookkeeping.
	;		
		dec	si		; Record last page of this group in case
		dec	si		;  next group fails
		mov	ss:[prevTail], si
		
		add	dx, ax		; Adjust write base by amount written 
		
		pop	ax, cx
		tst	cx		; Clears carry
		jnz	writeLoop
done:
		mov	ax, ss:[listHead]; Return head of list, possibly
					;  modified from input value.
		.leave
		ret
	;------------------------------------------------------------
writeError:
	;
	; Calculate pages written, rounding down (a partial page is
	; unhelpful).
	; bx = pages supposed to have been written
	; cx = # bytes actually written
	; si = map index 2 past last page to have been written
	;
		mov_trash	ax, cx
		mov	cx, dx
		clr	dx		; 32-bit divide...
		div	ds:[SM_page]
		mov	dx, cx		; shift write base back into dx
		pop	cx		;  and recover # pages left
		sub	bx, ax		; figure pages unwritten
		add	cx, bx		; Add unwritten pages back into total

		push	ax		; Save pages written for re-linking

	;
	; Point dx back at first unwritten portion of block
	;
		mov	bx, dx		; preserve dx
		mul	ds:[SM_page]
		add	bx, ax		; Adjust block base
		mov	dx, bx		; Shift block base back to dx

	;
	; Allocate a new set of pages linked into the existing list of
	; already-written pages.
	;
		mov	bx, ss:[groupHead]	; Figure first unwritten page
		pop	ax		; Recover pages written
		shl	ax		; Pages -> words for map
		mov	si, ax		; Calculate last written page
		lea	si, [bx][si-2]	;  assuming at least one was written.
					;  This will be bx+ax-2, since ax is
					;  one-origin.
		jnz	wroteSome	; NZ (from shl) => wrote at least one
					;  from this group.
		mov	si, ss:[prevTail]	; Link to first bad page is ss:[prevTail]
wroteSome:
		add	bx, ax		; bx <- first bad page. allocation
					;  may not go beyond this.
		mov	di, cx		; Pass new number of pages needed
		call	AllocSwap
		jc	noMore		; Couldn't allocate enough pages for
					;  the rest of the block -- return
					;  error (caller will free page list)
	;
	; Link in new pages in place of the ones that didn't work
	;
		cmp	si, SWAPNIL	; Was very first page bad?
		jne	notFirst	; No
		mov	ss:[listHead], ax	; Yes -- replace the entire list
		jmp	writeNew
notFirst:
		mov	ds:[si], ax	; Link last good to first new
writeNew:
		push	bx		; Save head of bad list for freeing
		mov	bx, dx		; Pass initial offset in bx
		xchg	ax, cx		; Figure number of bytes left to write
		mul	ds:[SM_page]	;  based on number of unwritten pages
		xchg	ax, cx
		mov	dx, ss:[blockSeg];  Pass segment in dx
		call	WritePageList	; Recurse to write new pages.
	;
	; Free the old pages. If WritePageList returned an error, our caller
	; will free the pages we just linked in.
	;
		pop	bx		; bx <- head of bad page list
		push	ax
		mov	ax, ds		; ax <- segment of swap map
		pushf
		call	SwapFree
		popf
		pop	ax
noMore:
		inc	sp		; Discard saved "next page". Doesn't
		inc	sp		;  nuke the carry.
		jmp	done
WritePageList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RelocPageList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Relocate the page list so that no pages go above the 
		maximum page.

CALLED BY:	SwapCompact
PASS:		es	= segment of SwapMap
		di	= first page of list
		ax	= highest page to use
		dx	= address of a buffer of the size of a page in the
			  swap driver, to be used for the relocation.
RETURN:		di	= new first page (may have changed.)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RelocPageList	proc	near
firstPage	local	word
		uses	ax,bx,cx,dx,si,ds,es
		.enter
	
		segmov	ds, es
		mov	cx, ds:[SM_freeList]

	;
	; Look at the first one separately, because we have to
	; return the new first page.
	;
		mov	firstPage, di		;initialize it.
		mov	si, di			;si <- first page 
		mov	di, ds:[si]		;save the second page,
						; so we can restore the link.
		cmp	si, ax			;is it too high?
		jle	nextPageLoop
		call	RelocPage	
EC <		ERROR_C SWAP_COMPACT_UNEXPECTED_ERROR			>
		jc	exitLoop
EC <		call	ECCheckSwapMapDS				>
		mov	firstPage, si		;new first page.	
		mov	ds:[si], di		;update next page link.


nextPageLoop:
	;
	; we need to keep a pointer to the previous page in SwapMap so
	; that we can update the link if the page number changes (i.e.,
	; is relocated.)  Initial value is the first page.
	;
		mov	bx, si

	; ds = swap map
	; si = current page
	; ax = highest page
	; bx = previous page, to update the link.
	; dx = buffer segment

		mov	si, ds:[si]		;follow link
		cmp	si, SWAPNIL		;test for end of page list.
		je	exitLoop

		cmp	si, ax
		jle	nextPageLoop

		mov	di, ds:[si]		;save the next page link,
						; so we can restore the link
						; after the page moves.
		call	RelocPage		;old page -> si <- new page
		jc	exitLoop		;oh, no, we failed!
EC <		call	ECCheckSwapMapDS				>

		mov	ds:[bx], si		;update the previous link.
		mov	ds:[si], di		;update the next link.
EC <		call	ECCheckSwapMapDS				>
		jmp	nextPageLoop
exitLoop:

		mov	di, firstPage
		.leave
		ret
RelocPageList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreePage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a page to the free list.

CALLED BY:	RelocPage
PASS:		si	= page to add to free list
		ds	= SwapMap

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Uses the same scheme as SwapFree.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
;
; Calls to FreePage were replaced with calls to SwapFree.
;
FreePage	proc	near
 		uses	ax,bx,cx,ds,si
		.enter
		mov 	bx, si			;bx = page being freed
		mov	si, ds:[SM_freeList]	;si = free list
		cmp	bx, si		;goes before head of free list?
		ja	scanLoop	;no
	;		
	; add page bx before head of free list
	;
		mov	ax, si			;ax = head of free list
		mov	si, SM_freeList+2	
		jmp	foundSlot

scanLoop:
		lodsw			;fetch next free page
		cmp	bx, ax		;does page being freed go before it?
		jb	foundSlot	;yes
		xchg	si, ax		;no. 
		jmp	scanLoop

foundSlot:
	;
	; At this point, ax is the page before which the page being freed
	; is to be inserted, while si is the page that points to ax.
	; And oh yeah, bx = page to add.
	;
		mov	ds:[bx], ax	;Link new page into list
		mov	ds:[si-2], bx
		inc	ds:[SM_numFree]

		.leave
		ret
FreePage	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RelocPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the passed page is above the maximim page limit, move
		the contents of the page to another page below that limit,
		and return the number of the new page. 

CALLED BY:	Internal (RelocPageList)
PASS:		si	= page to relocate
		ax	= highest page
		dx	= buffer segment of page size.
		ds	= SwapMap

RETURN:		si	= new page where data is stored
		cx	= updated free list
		ds	= SwapMap (with freelist updated)
		carry set if couldn't relocate the page to below the limit.
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RelocPage	proc	near
newPage		local	word
		uses	ax,bx,dx,es,di,ds
		.enter
EC <		call	ECCheckSwapMapDS				>
		call	AllocPageBelowLimit		;ax <- new page
EC <		ERROR_C SWAP_COMPACT_OUT_OF_PAGES_BELOW_LIMIT		>
		jc	done
		mov	newPage, ax
	;
	; read the page into the buffer, using the SwapMap routine.
	;
		segmov	es, ds		;es = SwapMap
		mov	ds, dx	
		clr	dx		;ds:dx = buffer
		mov	ax, si		;ax = starting page number
		sub	ax, offset SM_pages
		shr	ax
		mov	cx, es:[SM_page]
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, es:[SM_read]				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	es:[SM_read]	;ax, bx destroyed.
EC <		ERROR_C SWAP_COMPACT_UNEXPECTED_ERROR			>
	;
	; now write out to the new page. ds:dx is already setup.
	;
		mov	ax, newPage
		sub	ax, offset SM_pages
		shr	ax
		mov	cx, es:[SM_page]
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, es:[SM_write]				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	es:[SM_write]
EC <		ERROR_C SWAP_COMPACT_UNEXPECTED_ERROR			>
		jc 	freeAndExit	;error in write. try to back out.
if 	CHECK_COMPACTION
		push	es, si
	;
	; the buffer segment in ds is twice the size in EC.  Use that
	; space to read the new page back in, and check it against the
	; original.
	;
		mov	cx, es:[SM_page]
		mov	dx, cx			;start halfway into buffer.
		mov	ax, newPage		;read from where we just
						; wrote into.
		sub	ax, offset SM_pages
		shr	ax
if FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, es:[SM_read]				>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		call	es:[SM_read]
	;
	; compare the two halves of the buffer.  They should be identical.
	;	
		mov	di, es:[SM_page]
		clr	si
		segmov	es, ds
		mov	cx, di
		repe	cmpsb
		ERROR_NZ SWAP_COMPACT_RELOC_DATA_CORRUPTED
		pop	es, si
endif

	; ax = SwapMap
	; si = page to relocate.
EC <		call	ECCheckSwapMapES				>
		mov	ax, es		;ax = SwapMap
		mov	{word}es:[si], SWAPNIL
		mov	bx, si
		call	SwapFree
EC <		call	ECCheckSwapMapES				>
		mov	si, newPage
		clc

done:
		.leave
		ret

freeAndExit:
		mov	ax, es		;ax = SwapMap
		mov	si, newPage
		mov	{word}es:[si], SWAPNIL
		mov	bx, si
		call	SwapFree
		stc
		jmp	done
RelocPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocPageBelowLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a page in the free list that is numbered below the
		maximum page number.

CALLED BY:	RelocPage
PASS:		ax	= maximum page number
		ds	= SwapMap 
RETURN:		if there's a free page below the maximum page number:
			carry clear
			ax = new page
			ds = SwapMap with updated freelist (new page taken
			     out.)
		else:
			carry set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocPageBelowLimit	proc	near
		uses	bx,cx,dx,ds,si
		.enter
		mov	bx, ax			;bx = max. page.
	;
	; just return the first page in the free list <= max page.
	;
		mov	dx, SM_freeList		;preceeding page in this
						; case is just the pointer
						; to the head of the list.
		mov	ax, ds:[SM_freeList]
nextPageLoop:
		cmp	ax, bx
		jle	foundOne

		mov	si, ax			;setup for lodsw
		mov	dx, si			;save preceeding page, so
						; that if we find a page
						; we can update the link.
		lodsw	
		cmp	ax, SWAPNIL
		jne	nextPageLoop

	;
	; if we've reached there, then we walked through the whole free
	; list, unable to find a page numbered lower than the max. page.
	; In other words, we've failed.
	;
		stc
		jmp	done

foundOne:
	; ax = page in question
	; dx = preceeding page in free list.
		mov	si, ax
		mov	bx, ds:[si]		;bx <- rest of free list
		mov	{word}ds:[si], SWAPNIL	;terminate page.
		mov	si, dx
		mov	ds:[si], bx		;update next pointer of
						; previous page in free list.
		dec	ds:[SM_numFree]
		clc
done:
		.leave
		ret
AllocPageBelowLimit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSwapMapDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the consistency of the SwapMap.

CALLED BY:	internal
PASS:		ds	= SwapMap
RETURN:	 	if failure:
			does not return.
		else:
			nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	ERROR_CHECK
ECCheckSwapMapDS	proc	near
		uses	ax,bx,ds,si
		.enter
	;
	; Check for self reference in the SwapMap free list.
	;
		mov	si, ds:[SM_freeList]
		cmp	si, SWAPNIL
		je	exitLoop
checkLoop:
		mov	bx, si			;save previous offset
		lodsw
		cmp	ax, bx			;self-reference?
		ERROR_Z	SWAP_FREE_LIST_CORRUPTED
		cmp	ax, SWAPNIL
		je	exitLoop
		xchg	si, ax
		jmp	checkLoop
exitLoop:
		.leave
		ret
ECCheckSwapMapDS	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSwapMapES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the consistency of the SwapMap.

CALLED BY:	internal
PASS:		es	= SwapMap
RETURN:	 	if failure:
			does not return.
		else:
			nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	ERROR_CHECK
ECCheckSwapMapES	proc	near
		uses	ax,bx,ds,si
		.enter
	;
	; Check for self reference in the SwapMap free list.
	;
		segmov	ds, es
		mov	si, ds:[SM_freeList]
		cmp	si, SWAPNIL
		je	exitLoop
checkLoop:
		mov	bx, si			;save previous offset
		lodsw
		cmp	ax, bx			;self-reference?
		ERROR_Z	SWAP_FREE_LIST_CORRUPTED
		cmp	ax, SWAPNIL
		je	exitLoop
		xchg	si, ax
		jmp	checkLoop
exitLoop:
		.leave
		ret
ECCheckSwapMapES	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapLockDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Desc:	Grab the DOS/BIOS lock. This should be called by a swap
		driver before calling on some DOS-level driver to avoid
		conflicts with TSRs like disk caches.
		The lock won't be grabbed if SwapClearKernelFlag has been
		called
	Pass:	nothing
	Return:	nothing
	Nuked:	flags

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	1/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapLockDOS	proc	far
	.enter
		call	SwapIsKernelInMemory?
		jnc	done
		call	SysLockBIOS
done:	.leave
	ret
SwapLockDOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapUnlockDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Desc: 	Release the DOS/BIOS lock.
	Pass:	nothing
	Return:	nothing
	Nuked:	nothing (flags intact)
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	1/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapUnlockDOS	proc	far
	.enter
		pushf
		call	SwapIsKernelInMemory?
		jnc	done
		call	SysUnlockBIOS
done:
		popf
	.leave
	ret
SwapUnlockDOS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapIsKernelInMemory?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if kernel can be called

CALLED BY:	
PASS:		nothing
RETURN:		Carry Set iff kernel can be called
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	1/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapIsKernelInMemory?	proc	far
	uses	ax,ds
	.enter
		segmov	ds, dgroup, ax
		cmp	ds:[KernelInMemory], BB_TRUE
		cmc		; KernelInMemory is either 0 or BB_TRUE. if
				;  BB_TRUE, CF is now 0, and we want it 1
				;  if 0, CF is now 1 (0 being below BB_TRUE)
				;  and we want it 0
	.leave
	ret
SwapIsKernelInMemory?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapSetKernelFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the flag in the swap library to say the the
		kernel in in memory and may be called

CALLED BY:	
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (not even flags)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	1/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapSetKernelFlag	proc	far
	uses	ax, ds
	.enter
		segmov	ds, dgroup, ax
		mov	ds:[KernelInMemory], BB_TRUE
	.leave
	ret
SwapSetKernelFlag	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapClearKernelFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets flag in swap library to say the kernel is not in
		memory and may not be called

CALLED BY:	
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (not even flags)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	1/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapClearKernelFlag	proc	far
	uses	ax,ds
	.enter
		segmov	ds, dgroup, ax
		mov	ds:[KernelInMemory], BB_FALSE
	.leave
	ret
SwapClearKernelFlag	endp

Resident	ends



