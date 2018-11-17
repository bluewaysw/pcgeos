COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VMem Kernel Code
FILE:		vmemHugeArray.asm

AUTHOR:		Jim DeFrisco, 12 August 1991

ROUTINES:
	Name			Description
	----			-----------
	HugeArrayCreate		Create a huge array
	HugeArrayDestroy	Destroy a huge array
	HugeArrayLock		Dereference a huge array element
	HugeArrayUnlock		Unlock a reference to an element
	HugeArrayInsert		Insert element(s) into a huge array
	HugeArrayAppend		Append element(s) to the end of a huge array
	HugeArrayReplace	Replace existing element(s) data
	HugeArrayDelete		Delete an element from a huge array
	HugeArrayGetCount	Count the number of elements in a huge array

	HugeArrayNext		Low-level version of HugeArrayLock.
	HugeArrayPrev		Low-level version of HugeArrayLock
	HugeArrayDirty		Mark an element dirty (mark VM block dirty)
	HugeArrayExpand		Low-level version of HugeArrayInsert
	HugeArrayContract	Low-level version of HugeArrayDelete

	FixupHugeArrayChain	(Internal) Fix up HA dir block pointers
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	8/12/91		Initial revision


DESCRIPTION:
	This file contains descriptions of the routines used to
	create and manipulate huge arrays.  A huge array is a 
	standard PC/GEOS data structure that is capable of holding an 
	enormous amount of data.  The elements in the array can be of fixed 
	or variable size.  32-bit element numbers are supported, allowing 
	4G elements in a single array.  Each element is limited to about 
	64K bytes (less a little overhead). The size of the array is also 
	limited by available disk space.
		
	The array is allocated as a chain of VM blocks, using the standard
	VM chaining support in the kernel.  The first block in the chain is
	called the directory block, and contains enough information to locate
	any element in the array.  Most HugeArray routines take both a VM
	File Handle and a handle to the huge array, which is the VM block 
	handle of the directory block (the first block in the chain). The 
	creator of the array is also allowed to add his/her own information 
	into this directory block.  Blocks will be allowed to grow to some 
	internally determined limit (probably about 4K), at which time new 
	VM blocks will be allocated.

	The directory block and data blocks will be ChunkArrays.  Since 
	these are LMem blocks, this poses a slight problem since the first 
	word of an LMem block is the memory block handle, while the first 
	word of a VM block that is part of a VM Chain is the link to the 
	next block.  When locked, the HugeArray code will replace the 
	VMChain block handle with the memory handle for the block, and 
	replace the Chain handle when the block is unlocked.

	The following diagram illustrates the format of the blocks.

	Directory block:
	+-----------------------------------------------+<------+
	| HugeArrayDirectory structure:			|       |
	|  HAD_header:	LMemBlockHeader	 (LMBH_handle)  |---+   |
	|  HAD_xdir:	VM blk handle for extra 	|   |   |
	|		 directory blocks, (always zero	|   |   |
	|  		 for this implementation)	|   |   |
	|  HAD_data:	VM blk handle of 1st data block	|---+	|
    	|  HAD_dir:	chunk han of index chunk array	|   |	|
    	|  HAD_size:	array element size (0=variable)	|   |	|
    	+-----------------------------------------------+   |	|
    	|  block of user-defined info (variable sized)  |   |	|
    	+-----------------------------------------------+   |	|
   	| ChunkArray of HugeArrayDirEntry structures	|   |	|
	|						|   |	|
       	| First entry always:				|   |	|
       	|  HADE_last:    -1				|   |	|
	|  HADE_size:	 0				|   |	|
	|  HADE_block:   0      			|   |   |
	|						|   |	|
	+-----------------------------------------------+   |	|
							    |	|
							    |	|
	First data block:				    |	|
	+-----------------------------------------------+ <-+	|
	| HugeArrayBlock structure:			|       |
	|  HAB_header:	LMemBlockHeader	 (LMBH_handle)  |---+   |
	|  HAB_prev:	VM blk handle to prev data block|---)---+
	|  HAB_next:	VM blk handle to next data block|---+
	|  HAB_dir:	VM blk handle to dir block	|   |
	+-----------------------------------------------+   |
	| ChunkArray of elements			|   |
	|						|   |
	|						|   |
	+-----------------------------------------------+   |
							    |
							    |
	Next data block:				    |
	+-----------------------------------------------+ <-+
	|						|
		
	$Id: vmemHugeArray.asm,v 1.1 97/04/05 01:16:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapHAElemToCAElem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change a huge array element number and convert it to a
		chunk array element number and return #elements left in 
		block (including element)

CALLED BY:	INTERNAL
		HugeArrayLock, HugeArrayDelete

PASS:		dx.ax		- element number
		ds:di		- pointer to dir entry for element

RETURN:		dx		- chunk array element number
		ax		- #elements following element in chunk array
				  (including element in question)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		figure it all out from the element numbers stored in the
		directory block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAP_HAE_ELEM_TO_CAE_ELEM	macro	reg

if	ERROR_CHECK
		pushdw	dxax

		pushdw	dxax
		subdw	dxax, ds:[reg].HADE_last ; calc #elements available
		cmp	dx, 0xffff		; should be -1
		je	elemNumOK
		tst	dx			; if not, must be zero
		jnz	elemNumError
		tst	ax
		jz	elemNumOK
elemNumError:
		ERROR	HUGE_ARRAY_CORRUPTED
elemNumOK:
		popdw	dxax
		subdw	dxax, <ds:[reg-(size HugeArrayDirEntry)].HADE_last>
		decdw	dxax			; calc offset into chunk array
		tst	dx			; should be zero
		ERROR_NZ HUGE_ARRAY_CORRUPTED

		popdw	dxax
endif

		; figure out #elements left first.

		mov	dx, ax
		sub	ax, ds:[reg].HADE_last.low ; calc #elements available
		neg	ax
		inc	ax			; ax = #elements left

		; subtract the HADE_last from the previous block

		sub	dx, ds:[reg-(size HugeArrayDirEntry)].HADE_last.low
		dec	dx

endm

;-----

VMHugeArray	segment resource

MapHAElemToCAElem proc	near	; was in VMHugeArray...

		MAP_HAE_ELEM_TO_CAE_ELEM	di

		ret
MapHAElemToCAElem endp

VMHugeArray	ends

	;FIXED stuff first

kcode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference a Huge Array element.  
		Should be used with HugeArrayUnlock

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)
		dx.ax	- element number to dereference

RETURN:		ds:si	- pointer to requested element 
		ax	- #consecutive elements available starting with 
			  returned pointer (if ax=0, pointer is invalid)
		cx	- #consecutive elements available before (and 
			  including) the requested element.
		dx	- size of the element 
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the appropriate VM block;
		calculate the number of elements available.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayLock	proc	far
		uses	bp
		.enter

		; we do out own EnterHugeArray for speed.  we cheat by
		; not making the directory block an lmem block since we
		; know that we will not modify it

		mov_tr	cx, ax
		mov	ax, di
		call	VMLock	
		mov	ds, ax
		mov_tr	ax, cx

		; find the correct directory entry for the element number
		; in dx.ax

		; *** This is a modified inline version of ScanHADirectory ***

		; scan through the directory structure, looking for the 
		; right block.  First get pointer to directory entries.

		mov	si, ds:[HAD_dir]
		mov	si, ds:[si]
		mov	cx, ds:[si].CAH_count	; get count of dir entries
		dec	cx			; one less (1st one bogus)
		jz	noElements
		add	si, ds:[si].CAH_offset	; ds:di = element #0
		add	si, size HugeArrayDirEntry ; ds:di = element #1

		; the directory entries have the element number of the final
		; element in that block.  Keep looping until we hit the 
		; entry with a larger number.  
		; cx    = the # of dir entries.
		; dx.ax = element # to match
scanLoop:
		cmpdw	ds:[si].HADE_last, dxax	; check if found block yet
		jae	found			; branch with carry clear
		add	si, size HugeArrayDirEntry
		loop	scanLoop

		; if we fall out of the loop, then the element number passed
		; is too large.  So we should return zero elements found...

		; there are no elements in the array.  Return zero for count.
noElements:
		mov	dx, ds:[HAD_size]	; fetch size of elements
		clr	ax			; no elements available
		call	VMUnlock
		jmp	done

found:
		; found the right block.  Lock it down and calculate the
		; number of elements available in the block from that point.

		MAP_HAE_ELEM_TO_CAE_ELEM si	; dx=elem#, ax = #left

		push	ax			; save #elements left
		mov	ax, ds:[si].HADE_handle	; get handle
		mov	cx, ds:[HAD_size]	; get size in case it's fixed
		call	LockHABlock		; lock down the block
		mov	ds, ax			; ds -> data block
		mov_tr	ax, dx			; ax = chunk array elem #
		mov	si, HUGE_ARRAY_DATA_CHUNK ; *ds:si -> chunk array
		mov	dx, di
		call	ChunkArrayElementToPtr	; ds:di -> element
						; cx -> element size
		mov	si, di
		mov	di, dx
		mov	dx, cx			; dx -> element size
		call	VMUnlock
		mov_tr	cx, ax			; restore element#
		inc	cx			; count is one more than elem#
		pop	ax			; restore -(#elements)
done:
		.leave
		ret

HugeArrayLock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayUnlockDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a HugeArray block

CALLED BY:	GLOBAL
PASS:		ds	- points to locked HugeArray dir block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayUnlockDir proc	far
		FALL_THRU	HugeArrayUnlock
HugeArrayUnlockDir endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a dereferenced Huge Array element.  
		Should be used with HugeArrayLock

CALLED BY:	GLOBAL

PASS:		ds	- sptr to element block (returned by HugeArrayLock)

RETURN:		nothing

DESTROYED:	nothing, not even the flags

PSEUDO CODE/STRATEGY:
		unlock the appropriate VM block;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayUnlock	proc	far
		FALL_THRU	UnlockHABlock
HugeArrayUnlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnlockHABlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a HugeArray block, do the special hacks

CALLED BY:	INTERNAL
		called from all over

PASS:		ds	- Huge array VM block

RETURN:		nothing

DESTROYED:	nothing, not even the flags

PSEUDO CODE/STRATEGY:
		reset the HF_LMEM bit in the handle structure;
		stuff the VM chain handle into the LMBH_handle field;
		umlock the block;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnlockHABlock	proc	far
		uses	ax, bx, bp
		.enter
	
		pushf					; save everything

		; before we unlock it, check to see if we should compact it.

ifdef MEASURE_HUGE_ARRAY_COMPACTION
		call	MeasureLMemCompaction
endif
		call	CheckLMemCompact		; compact if >25% free
							;  space

		; unlock the block and set/clear appropriate fields

		mov	bp, ds				; save segment in bp

		mov	bx, ds:[LMBH_handle]		; get mem handle
		LoadVarSeg ds, ax			; ds -> handle table
		
		;
		; If the lock-count of this block is >1 then we don't do 
		; anything. Someone else will be the last person to unlock
		; this block.
		;
		cmp	ds:[bx].HM_lockCount, 1		; Check for more lockers
		ja	justUnlock			; Branch if more

		;
		; This is the last unlock of this huge-array block.
		; Clear the HF_LMEM flag and move the "next" link in the
		; huge-array chain (vm handle) into the LMBH_handle field
		; of the LMemBlockHeader.
		;
		and	ds:[bx].HM_flags, not mask HF_LMEM ; clr the LMem bit
		mov	ds, bp				; ds -> block (again)
		mov	ax, ds:[HAB_next]		; get link to next blk
		mov	ds:[LMBH_handle], ax		; stuff VMChain handle

justUnlock:
		mov	ds, bp				; Restore ds (jic)
		mov	bp, bx				; pass handle in bp
		call	VMUnlock			; unlock the block
		popf

		.leave
		ret
UnlockHABlock	endp

		; since we're stuffing word zero (the link field for VM chains)
		; with the VM handle of the next block, we better make sure
		; that it's the right thing for both the directory block and
		; data blocks.
CheckHack	<(offset HAD_data) eq (offset HAB_next)> ; offsets must match



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckLMemCompact
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we should compact the LMem heap

CALLED BY:	INTERNAL
		CombineHABlocks()
PASS:		ds	- points to LMem block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check to see if the ratio of free space to total space 
		is greater than 25%, and if we're going to gain more
		than 1,024 bytes.  If so, compact it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/25/93		Initial version
	Don	3/10/00		Adjusted algorithm to prevent
				  needless memory thrashing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckLMemCompact	proc	near
		uses	ax
		.enter

EC <		call	ECLMemValidateHeapFar				>
		mov	ax, ds:[LMBH_totalFree]
		cmp	ax, 1024
		jb	done
		shl	ax, 1
		shl	ax, 1
		cmp	ax, ds:[LMBH_blockSize]
		jb	done
ifdef	MEASURE_HUGE_ARRAY_COMPACTION
		call	CountLMemContracts
endif
		;
		; Removed this call (so this routine essentially does
		; nothing) because it results in much wasted energy
		; compressing blocks repeatedly that later are expanded
		; during creating of HugeArrays). Ideally we would still
		; call this function to re-claim space once an entire
		; sequence of operations with a HugeArray is completed,
		; but that is the purpose of HugeArrayCompressBlocks().
		; -Don 4/30/00
		;
;;;		call	LMemContract
done:
		.leave
		ret
CheckLMemCompact	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of element(s) in a HugeArray

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)

RETURN:		dx.ax	- number of elements in array

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		calculate the number of elements in the array;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayGetCount proc	far
		uses	ds, si, bp
		.enter

		; lock down the directory block.  That's all we'll need

		; since we will only look at the directory we can just call
		; VMLock directly and save some cycles

		mov	ax, di
		call	VMLock
		mov	ds, ax
		mov	si, ds:[HAD_dir]
		mov	si, ds:[si]		; ds:si = directory
		mov	ax, ds:[si].CAH_count	; get count of dir entries
		dec	ax			; one less (1st one bogus)
		jz	noElements

		; get to the last directory entry (same as count ret by Enter.)

		; do inline ChunkArrayElementToPtr
			CheckHack <(size HugeArrayDirEntry) eq 8>

		shl	ax
		shl	ax
		shl	ax
		add	si, size ChunkArrayHeader
		add	si, ax
		movdw	dxax, ds:[si].HADE_last	; get number of last element
		incdw	dxax			; count is one more (0 based)

		; all done, clean up and leave
done:
		call	VMUnlock		; unlock dir block

		.leave
		ret

		; no directoy blocks, count is zero
noElements:
		mov	dx, ax
		jmp	done
HugeArrayGetCount endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark a VM block in a HugeArray dirty.

CALLED BY:	GLOBAL

PASS:		ds	- points to a locked HugeArray element

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just mark the block dirty.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayDirty proc	far
		uses	bp
		.enter
		mov	bp, ds:[LMBH_handle]	; get mem handle
		call	VMDirty

		.leave
		ret
HugeArrayDirty endp


ifdef	MEASURE_HUGE_ARRAY_COMPACTION

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MeasureLMemCompaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Analysis code to check to see what percent of the block 
		is free, and keep bin counts.

CALLED BY:	INTERNAL

PASS:		ds	- LMem block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MeasureLMemCompaction		proc	far
		.enter
		; check out the amount of free space in the block
		; don't do statistics on directory blocks.

		tst	ds:[HAD_xdir]			; this will be zero for
		LONG jz	done				;   dir blocks

		push	ax, cx
		mov	cx, ds:[LMBH_totalFree]
		mov	ax, ds:[LMBH_blockSize]

		incdw	cs:[totalChecked]
		incdw	cs:[totalZero]
		jcxz	accounted
		decdw	cs:[totalZero]
		incdw	cs:[totalMoreHalf]
		shl	cx, 1			; see if > 50%
		cmp	cx, ax	
		ja	accounted
		decdw	cs:[totalMoreHalf]
		incdw	cs:[totalHalf]
		shl	cx, 1			; see if > 25%
		cmp	cx, ax
		ja	accounted
		decdw	cs:[totalHalf]
		incdw	cs:[totalQuarter]
		shl	cx, 1			; see if > 12.5%
		cmp	cx, ax
		ja	accounted
		decdw	cs:[totalQuarter]
		incdw	cs:[totalEigth]
accounted:
		pop	ax, cx
done:			
		.leave
		ret
MeasureLMemCompaction		endp

CountLMemContracts	proc	far
		inc	cs:[countLMemContract]
		ret
CountLMemContracts	endp

totalChecked	dword	0
totalZero	dword	0
totalEigth	dword	0
totalQuarter	dword	0
totalHalf	dword	0
totalMoreHalf	dword	0

countLMemContract	word 0
endif

kcode ends

;----------

VMHugeArray	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a Huge Array

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		cx	- #bytes to allocate per element (0=variable size)
		di	- HugeArray header size (for directory block)
			  di=0 if no additional space needed, else
			  di=(size HugeArrayDirectory)+(size additional info)

RETURN:		di	- Huge Array Handle (this is a VM block handle)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		allocate a VM block for the directory block;
		initialize the directory block header.
		if (need to allocate initial elements)
			allocate enough VM blocks for the elements.


		We allocate a bogus directory block entry, to help mark the
		beginning of the chain for code that traverses the directoy
		block elements.  This bogus block is identified by a 
		HADE_handle field == 0.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayCreate	proc	far
		uses	ds, dx, ax, bx, si
elemSize	local	word		\
		push	cx
memHandle	local	word
		.enter

		; do a little parameter checking...

		tst	di				; fixup header size
		jnz	checkHeaderSize
		mov	di, size HugeArrayDirectory
checkHeaderSize:
EC <		cmp	di, size HugeArrayDirectory		>
EC <		ERROR_B	HUGE_ARRAY_BAD_HEADER_SIZE		>

		; calculate the size we need for the directory block.  This
		; is the size of the passed extra header space + size for 
		; one HugeArrayDirEntry stucture + size of HugeArrayDirectory
		; structure.  The initial DirEntry is a bogus one to make
		; some other code a little easier to write.

		mov	ax, LMEM_TYPE_GENERAL		; just a plain lmem blk
		mov	cx, di				; header size
		call	VMAllocLMem			; ax = VM block
		push	ax				; save handle

		mov	cx, SVMID_HA_DIR_ID		; give it the right ID
		call	VMModifyUserID			; set ID for block
 
		push	bp				; save frame ptr
		call	VMLock				; lock it down
		mov	ds, ax				; ds -> dir block
		mov_tr	ax, bp				; move handle out of bp
		pop	bp
		mov	memHandle, ax			; save memory handle

		; initialize the HugeArrayDirectory structure

		mov	dx, elemSize			; retrieve size
		mov	ds:[HAD_size], dx		; save in dir header
		pop	dx				; restore vm block han
		mov	ds:[HAD_self], dx		; .and save it
		clr	ax
		mov	ds:[HAD_data], ax		; no data blks yet
		mov	ds:[HAD_xdir], ax		; no xtra dir blocks

		; create a chunk array for the directory block

		mov	bx, size HugeArrayDirEntry	; directoy element size
		clr	cx				; don't need xtra hdr
		clr	si				; 0 to alloc chunk han
		call	ChunkArrayCreate		; create the dir array
		mov	ds:[HAD_dir], si		; save chunkarr handle
		call	ChunkArrayAppend		; ds:di -> new element
		clr	ax
		mov	ds:[di].HADE_handle, ax		; no handle
		mov	ds:[di].HADE_size, ax		; no size
		dec	ax
		mov	ds:[di].HADE_last.low, ax	; set last elem # to -1
		mov	ds:[di].HADE_last.high, ax

		; note that we do not have to mark the block as dirty here
		; since that was already done by several routines above (like
		; the ChunkArray routines for instance)

		; all done.  Unlock the block and return the VM block handle.

		call	UnlockHABlock

		mov	cx, elemSize
		mov	di, dx				; return handle in di

		.leave
		ret

HugeArrayCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a Huge Array

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Free the VM chain.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		When we need to expand the spec for HugeArrays to include 
		multiple directory blocks, then this function will need to 
		free two VMChains -- one for data blocks and the other for 
		directory blocks.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayDestroy proc	far
		uses	ax,bp
		.enter
		mov	ax, di
		clr	bp
		call	VMFreeVMChain
		.leave
		ret
HugeArrayDestroy endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append element(s) to the end of a HugeArray

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)
		cx	- number of elements to append (fixed size elements)
			  OR
			  size of new element (variable size elements)
		bp.si	- fptr to buffer holding element data
			  (if bp=0, then allocate space but don't initialize)

RETURN:		dx:ax	- new element number (if multiple elements appended,
			  this is the number of the first element appended)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		find the end of the array;
		add data to end of last block;
		check for block overflow;.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayAppend	proc	far
		uses	cx, ds, di, es
		.enter

		; catch zero # elements added, and don't allow zero-sized 
		; variable ones...

		jcxz	exit

if ERROR_CHECK
	;
	; Validate that the element data is not in a movable code segment
	;
FXIP<		tst	bp						>
FXIP<		jz	noData						>
FXIP<		push	bx						>
FXIP<		mov	bx, bp						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx						>
FXIP<noData:								>
endif
		; lock down the directory block.

		push	si			; save pointer to data
		mov	dx, cx			; save element count
		call	EnterHugeArray		; *ds:si -> dir chunk array
		mov_tr	ax, cx			; ax = chunk array count
		call	ChunkArrayElementToPtr	; ds:di -> last dir entry
		mov	cx, dx			; restore size info
		pop	ax			; bp:ax -> init data
		pushdw	ds:[di].HADE_last

		; allocate a chain of VM blocks to hold the data

		call	AllocHAChain		; allocate the chain

		; restore pointer to initialization data.  If null, we're
		; all done.

		mov_tr	si, ax			; bp:si -> init data
		tst	bp			; anything to add ?
		jz	done

		; initialize the elements

		call	InitHAChain		; init the blocks
done:
		popdw	dxax
		incdw	dxax			; dx:ax -> first new element
EC <		call	ECCheckHugeArray				>
		call	UnlockHABlock		; unlock dir block, cleanup
exit:
		.leave
		ret
HugeArrayAppend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert element(s) into a HugeArray

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)
		cx	- number of elements to insert (fixed size elements)
			  OR
			  size of new element (variable sized elements)
		dx:ax	- element number. New element will be inserted before 
			  this one
		bp.si	- fptr to buffer holding element data
			  (if bp=0, then allocate space but don't initialize)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		find the proper position in the array;
		insert data, creating new blocks as necc.;
		check for block overflow;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayInsert	proc	far
		uses	ax, dx, cx, ds, di, es
		.enter

		; catch zero # elements added, and don't allow zero-sized 
		; variable ones...

		jcxz	done

if ERROR_CHECK
	;
	; Validate that the element data is not in a movable code segment
	;
FXIP<		tst	bp						>
FXIP<		jz	noData						>
FXIP<		push	bx						>
FXIP<		mov	bx, bp						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx						>
FXIP<noData:								>
endif

		; we want to split the block at the desired element, so
		; first we have to find the spot.

		push	di			; save block handle
		push	si			; save data pointer
		push	cx			; save count/size
		call	EnterHugeArray		; *ds:si -> directory
		jcxz	noElements		; no lock if nothing there
;EC <		call	TestSizes					>

		; find the correct directory entry for the element number
		; in dx.ax

		call	ScanHADirectory		; ds:di -> directory entry
		jc	noElements		; if element # is out of bounds

		; found the right block.  Split the block at the desired element
		; number at add a chain of data blocks at that point.

		call	MapHAElemToCAElem	; dx=elem#, ax = #left

		pop	cx			; restore count/size
		call	InsertElements		; allocate the space

		; restore pointer to initialization data.  If null, we're
		; all done.

		pop	si			; bp:si -> init data
		tst	bp			; anything to add ?
		jz	doneInit

		; initialize the elements

		call	InitHAChain		; init the blocks

doneInit:
		pop	di
EC <		call	ECCheckHugeArray				>
		call	UnlockHABlock		; unlock dir block, cleanup
done:
		.leave
		ret

		; there are no elements in the array.  Do an append
noElements:
		call	UnlockHABlock		; get back out
		pop	cx
		pop	si
		pop	di
		call	HugeArrayAppend		; append it.
		jmp	done
HugeArrayInsert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertElements
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine that does an optimal insertion of elements
		into a HugeArray block

CALLED BY:	INTERNAL
		HugeArrayInsert, HugeArrayExpand

PASS:		*ds:si	- pointer to HugeArray dir chunk array
		ds:di	- pointer to dir entry for block to insert into
		dx	- element number in the block to insert new elements
			  before
		cx	- number of new elements (fixed size elements)
			  OR
			  size of a variable sized element

RETURN:		*ds:si		- dir block ChunkArray, ds may have changed
		ds:di		- pointer to dir entry for first one allocated
				  (may be same entry as was passed)
		dx		- local ChunkArray element number for 1st elem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If the block we're adding to is small enough to take the new 
		elements without overflowing, add it quick, else
		Split the block and allocate a new block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertElements	proc	near
		uses	ax, cx
		.enter

		mov	ax, cx			; assume variable sized
		tst	ds:[HAD_size]		; elements variable sized ?
		jnz	calcAdditionSize	;  no, calculate size of add
haveAddSize:
		add	ax, ds:[di].HADE_size	; see if overflow
		jc	bigAddition		;  yep, block will be too big
		cmp	ax, HA_UPPER_LIMIT	; see if too big
		ja	bigAddition		;  yep, too big

		; the addition is small enough to add to the current block.
		; add the new elements.

		mov	ds:[di].HADE_size, ax	; adjust the block size
		
		; cruise throught the dir entries, adjusting the HADE_last
		; fields.  Count is one for  variable sized, cx for fixed.

		mov	ax, cx			; assume fixed
		tst	ds:[HAD_size]		; do it different for variable
		jnz	adjustLast
		mov	ax, 1
adjustLast:
		call	ModifyElementCounts
		call	HugeArrayDirty

		; all directory adjustments made.  Now insert the space into 
		; the data block.

		push	si, di, es		; save dir pointers
		segmov	es, ds			; es -> dir block
		mov	ax, ds:[di].HADE_handle	; get data block handle
		call	LockHABlock
		mov	ds, ax			; ds -> data block
		mov	si, HUGE_ARRAY_DATA_CHUNK ; *ds:si -> data chunk array
		mov	ax, dx			; ax = local element number
		push	cx			; save # to add
		call	ChunkArrayElementToPtr	; ds:di -> element
		pop	cx
		mov	ax, cx			; ax = size (if variable)
		call	ChunkArrayInsertAt	; insert the new element
		dec	cx			; one less to do if fixed
		jcxz	elemAdded
		tst	es:[HAD_size]		; if fixed size, more to go
		jnz	addRestFixed
elemAdded:
		call	ChunkArrayPtrToElement	; get local element number
		mov	dx, ax			; return dx = element number
		call	HugeArrayDirty		; Dirty the data block
		call	UnlockHABlock		; release the data block
		segmov	ds, es			; ds -> dir block
		pop	si, di, es
done:
		.leave
		ret

		; fixed sized elements, calculate the size of the total 
		; addition of elements.
calcAdditionSize:
		push	dx
		mov	ax, ds:[HAD_size]	; get element size
		mul	cx			; dx.ax = addition size
		tst	dx			; if set, too much to add
		pop	dx			; restore register
		jz	haveAddSize		;  if zero, continue testing
						;  if not, too big to expand
		; the size of the addition is too big to just expand the 
		; block where it should go.  Split the block and allocate
		; a new chain of blocks.
bigAddition:
		call	SplitHABlock		; split the block in two

;	Now that we have split the block, it is entirely possible that the
;	first half of the block can now fit in with the previous block, and
;	that the second half of the block can fit in with the next block.
;	Soooo... Let's check it out.

		add	di, size HugeArrayDirEntry
		call	CombineWithNextIfPossible

		sub	di, size HugeArrayDirEntry
		call	CombineWithPreviousIfPossible

		call	AllocHAChain		; alloc new space for elements

		jmp	done

		; we're adding fixed sized elements, and there are more to do

addRestFixed:
		push	bx, dx
		mov	bx, ds:[si]
		add	ds:[bx].CAH_count, cx
		mov	ax, ds:[bx].CAH_elementSize
		mul	cx			;ax = total size
		mov_tr	cx, ax
		sub	bx, di			;bx = offset
		neg	bx
		mov	ax, si
		call	LMemInsertAt
		add	bx, ds:[si]
		mov	di, bx
		pop	bx, dx
		jmp	elemAdded

InsertElements	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace element(s) in a HugeArray

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)
		cx	- number of elements to replace (fixed size elements)
			  OR
			  size of new element (variable size elements)
		dx:ax	- element number. New element will be replaceed 
			  starting with this one
		bp.si	- fptr to buffer holding element data
			  (if bp=0, then replace all bytes with 0)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		delete the elements;
		insert the new ones;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This accomplishes this function the slow, easy to program 
		way.  It might be rewritten if it becomes important.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayReplace	proc	far
		uses	ds, di, es
		.enter

if ERROR_CHECK
	;
	; Validate that the element data is not in a movable code segment
	;
FXIP<		tst	bp						>
FXIP<		jz	noData						>
FXIP<		push	bx						>
FXIP<		mov	bx, bp						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx						>
FXIP<noData:								>
endif
		
		; find out if the elements are fixed or variable 

		push	di, cx, si
		call	EnterHugeArray		; 
		tst	ds:[HAD_size]		; get size
		call	UnlockHABlock		; preserves flags
		pop	di, cx, si

		; if variable, different procedure.

		jz	handleVariable		
		jcxz	done			; no elements to replace

		; fixed size, so cx=number of elements to replace

		call	HugeArrayDelete		; delete them
addNewElements:
		call	HugeArrayInsert		; insert new ones
done:
		.leave
		ret

		; variable sized, only dealing with one element
handleVariable:
		push	cx			; save new element size
		mov	cx, 1			; delete a single element
		call	HugeArrayDelete
		pop	cx			; restore new element size
		jcxz	done			; don't add zero-sized...
		jmp	addNewElements
HugeArrayReplace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete element(s) in a HugeArray

CALLED BY:	GLOBAL

PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)
		cx	- number of elements to delete
		dx:ax	- element number. New element will be deleted starting
			  with this one.

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		find the proper position in the array;
		delete data, collapsing/freeing blocks as necc.;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayDelete	proc	far
		uses	ax, si, ds, di, dx, cx, es
		.enter

EC <		call	ECCheckStack					>

		; lock down the directory structure and find out what block
		; the element is in.

		jcxz	exit			; handle this first
		push	cx
		call	EnterHugeArray		; *ds:si -> directory
		jcxz	noElements		; no lock if nothing there
		pop	cx			; restore #elements to delete

		; while there are still block to delete, delete them and keep
		; locking the next block.
blockLoop:
		call	ScanHADirectory		; ds:di -> directory entry
		jc	collectGarbage		; if element # is out of bounds

		; ds:di -> directory entry

		push	dx, ax			; save element number
		push	cx			; save # to delete
		call	MapHAElemToCAElem	; dx=elem#, ax=#left in block
						; cx = #to delete
		cmp	cx, ax			; see if all to delete are here
		ja	haveDelCount		;  yes, last time around
		mov	ax, cx			; only delete this many
haveDelCount:
		call	DeletePartialBlock	; get rid of them.
		pop	cx			; restore delete count
		sub	cx, ax			; subtract # we did this time
		pop	dx, ax			; restore element#
		tst	cx			; see if any more to do
		jnz	blockLoop

		; done with the delete operation.  Scan through the blocks 
		; and see if we should combine any.
collectGarbage:
		call	CollectGarbage
done:
EC <		call	ECCheckHugeArray				>
		call	UnlockHABlock
exit:
		.leave
		ret

		; no elements, restore stack and leave
noElements:
		pop	cx
		jmp	done
HugeArrayDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayCompressBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all the free space from the ChunkArrays that hold
		the HugeArray data

CALLED BY:	GLOBAL
PASS:		bx	- VM file handle
		di	- VM block handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: only compresses the data blocks

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayCompressBlocks	proc	far
		uses	ax, bp, ds, si, dx, cx
		.enter

		clr	dx, ax			; start at element zero
		call	HugeArrayLock		; ds -> 1st data block
		tst	ax			; if ax = zero, no elements
		jz	done
		jmp	startCompress		;  (trashes ax,cx,dx)
compressLoop:
		call	LockHABlock		;  else lock the next one...
		mov	ds, ax			; ds -> next data block
startCompress:
		call	LMemContract		; contract the block
		call	HugeArrayDirty		; it's changed
		mov	ax, ds:[HAB_next]	; get link to next block
		call	UnlockHABlock		; unlock this one...
		tst	ax			; if zero, we're done
		jnz	compressLoop
done:
		.leave
		ret
HugeArrayCompressBlocks	endp


;------------------------------------------------------------------------
;	Low-level routines
;------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the next HugeArray element

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to element in block

RETURN:		ds:si	- pointer to next element (may be different block)
		ax	- #consecutive elements available with returned pointer
			- Returns zero if we were at the last element in the
			  array.
		dx	- Size of the element (only if variable sized)
				else dx is undefined

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the appropriate VM block;
		unlock the previous one;
		calculate the number of elements available.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayNext proc	far
		uses	di, cx, bx
		.enter

		; see if the current element is the last one in the block.  If
		; so, lock the next block, else get a pointer to the next one

		mov	di, si				; ds:di -> element
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> chunk array
		call	ChunkArrayGetCount		; cx = #elements
		dec	cx				; cx = last element #
		call	ChunkArrayPtrToElement		; ax = element number


		; see if it's the last element

		sub	cx, ax				; cx = #elements left
		jz	lockNextBlock			; if no more, lock next
		inc	ax				; need pointer to next
done:
		push	cx				; save count
		call	ChunkArrayElementToPtr		; ds:di -> element
							; cx -> element size
		mov	dx, cx				; dx -> element size
		pop	ax				; return count in ax
		mov	si, di				; ds:si -> element
		.leave
		ret

		; need to lock the next block.  first we need the file handle.
lockNextBlock:
		mov	cx, ds:[HAB_next]		; get next vm handle
		jcxz	done				; if no more blocks..
		mov	bx, ds:[LMBH_handle]		; get mem handle
		call	VMMemBlockToVMBlock		; bx = file, ax=block
		call	UnlockHABlock			; unlock current block
		mov	ax, cx				; lock the new one
		call	LockHABlock			; 
		mov	ds, ax				; ds -> data block
		mov	si, HUGE_ARRAY_DATA_CHUNK	; chunk array handle
		call	ChunkArrayGetCount		; cx = # elements 
		clr	ax				; want element #0
		jmp	done
HugeArrayNext endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayPrev
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the prev HugeArray element

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to element

RETURN:		ds:si	- pointer to prev element (may be a different block)
		ds:di	- pointer to first element in block
		ax	- #elements available from first element in block
			  to previous element. (eg., if si == di then ax=1)
			- Returns zero if we were at the first element of the
			  array.
		dx	- Size of the element (if variable sized)
				else dx is undefined
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the appropriate VM block;
		unlock the previous one;
		calculate the number of elements available.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayPrev proc	far
		uses	cx, bx
		.enter

		; see if the current element is the first one in the block.  If
		; so, lock the prev block, else get a pointer to the next one

		mov	di, si				; ds:di -> element
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> chunk array
		call	ChunkArrayPtrToElement		; ax = element number
		mov	cx, ax				; cx = difference
		inc	cx				; cx = #elements between

		; see if it's the first element

		tst	ax				; see if first element
		jz	lockPrevBlock			; if no more, lock prev
		dec	ax				; need pointer to prev
done:
		push	cx
		call	ChunkArrayElementToPtr		; ds:di -> element
							; cx -> element size
		mov	dx, cx				; dx -> element size
		push	di
		clr	ax
		call	ChunkArrayElementToPtr		; ds:di -> first elem
		pop	si				; ds:si -> prev elem
		pop	ax
		.leave
		ret

		; need to lock the next block
lockPrevBlock:
		mov	cx, ds:[HAB_prev]		; get next vm handle
		jcxz	done
		mov	bx, ds:[LMBH_handle]		; get mem handle
		call	VMMemBlockToVMBlock		; bx = file, ax=block
		call	UnlockHABlock			; unlock current block
		mov	ax, cx				; lock the new one
		call	LockHABlock			; 
		mov	ds, ax				; ds -> data block
		mov	si, HUGE_ARRAY_DATA_CHUNK	; chunk array handle
		call	ChunkArrayGetCount		; cx = # elements 
		mov	ax, cx
		dec	ax				; ax = last element #
		jmp	done
HugeArrayPrev endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayExpand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert element(s) into a HugeArray

CALLED BY:	GLOBAL

PASS:		ds:si	- pointer to locked HugeArray element
		cx	- number of elements to insert (fixed size elements)
			  OR
			  size of element in at ds:si (variable size elements)
		bp.di	- fptr to buffer holding element data
			  (if bp=0, then allocate space but don't initialize)

RETURN:		ds:si	- points to first new element added
		ax	- #consecutive elements available starting with 
			  returned pointer (if ax=0, pointer is invalid)
		cx	- #consecutive elements available before (and 
			  including) the requested element.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		find the proper position in the array;
		insert data, creating new blocks as necc.;
		check for block overflow;.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This should probably be re-written for optimization...

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayExpand	proc	far
		uses	di, bx, dx
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		tst	bp						>
EC <		jz	noInitialize					>
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, bpdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
EC <noInitialize:							>
endif

		; don't allow zero-sized variable elements and trivial reject
		; request for zero count fixed ones

		jcxz	done

		; first, we need to find out which element this is.

		push	di				; save init data ptr
		push	cx				; save elem count/size
		mov	di, si				; ds:di -> element
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> chunkarray
		call	ChunkArrayPtrToElement		; ax = element number
		push	ax				; save element number

		; next search through the directory entries to find the right
		; block

		mov	bx, ds:[LMBH_handle]		; get mem handle
		call	VMMemBlockToVMBlock		; bx = file, ax=block
		mov_tr	dx, ax				; dx = block handle
		mov	ax, ds:[HAB_dir]		; ax = dir block handle
		call	UnlockHABlock			; unlock data block
		call	LockHABlock			; ax -> dir block
		mov	ds, ax				; ds -> dir block
		mov	si, ds:[HAD_dir]		; *ds:si -> dir chunkar
		clr	ax
		call	ChunkArrayElementToPtr		; ds:di -> first entry
		call	ChunkArrayGetCount		; cx = # dir entries
findBlockLoop:
		cmp	ds:[di].HADE_handle, dx		; find 
		je	foundBlock			; found it
		add	di, size HugeArrayDirEntry	; bump to next entry
		loop	findBlockLoop

		; if we fall out of the loop, something bad has happened

EC <		ERROR	HUGE_ARRAY_DIR_BLOCK_OVERFLOW			>
NEC <		jmp	badThingHappened		; do something in NEC >

		; found the right directory entry.  Do the same as for Insert.
foundBlock:
		pop	dx				; restore element #
		pop	cx				; restore count/size
		call	InsertElements			; alloc new space 

		; restore pointer to initialization data.  If null, we're
		; all done.

		pop	si				; bp:si -> init data
		tst_clc	bp				; anything to add ?
		jz	doneInit

		; initialize the elements
if	FULL_EXECUTE_IN_PLACE
EC <		xchg	bx, bp				>
EC <		call	ECAssertValidFarPointerXIP	>
EC <		xchg	bx, bp				>
endif

		call	InitHAChain			; init the blocks
EC <		call	ECCheckHugeArray				>
doneInit:
		mov	ax, ds:[di].HADE_handle		; relock data block
		call	UnlockHABlock			; unlock dir block
		call	LockHABlock			; ax -> data block
		mov	ds, ax				; save data block addr

		; dereference element number

		mov_tr	ax, dx				; ax = elem#
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> data block
		mov	di, ds:[si]
		mov	dx, ds:[di].CAH_count		; dx = # elements
		call	ChunkArrayElementToPtr		; ds:di -> element
		mov	si, di				; ds:si -> elememt
		mov_tr	cx, ax				; cx = element #
		mov_tr	ax, dx				; ax = # elements
		sub	ax, cx				; ax = # elements after
		inc	cx				; cx = # elements before
done:
		.leave
		ret

		; oops.  fell out of the directory entry chunk.  bad news,
		; just bail.
NEC <badThingHappened:							>
NEC <		mov	ax, dx				; relock the block >
NEC <		pop	dx				; restore element# >
NEC <		pop	cx						>
NEC <		pop	di						>
NEC <		jmp	done						>

HugeArrayExpand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayContract
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete element(s) in a HugeArray

CALLED BY:	GLOBAL

PASS:		ds:si	- points to a locked HugeArray element
		cx	- number of elements to delete

RETURN:		ds:si	- points to same element number, ds may have changed
		ax	- number of elements available with pointer.
			  (if ax=0) the HugeArray is now empty.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		find the proper position in the array;
		delete data, collapsing/freeing blocks as necc.;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HugeArrayContract proc	far
		uses	dx, cx, di, es, bx
		.enter

		; first, we need to find out which element this is.

		push	cx				; save elem count
		mov	di, si				; ds:di -> element
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> chunkarray
		call	ChunkArrayPtrToElement		; ax = element number
		pop	cx				; restore total count

		; next search through the directory entries to find the right
		; block

		push	ax, cx				; save info we have 
		mov	bx, ds:[LMBH_handle]		; get mem handle
		call	VMMemBlockToVMBlock		; bx = file, ax=block
		mov	dx, ax				; save block handle
		mov	ax, ds:[HAB_dir]		; ax = dir block handle
		call	LockHABlock			; ax -> dir block
		call	UnlockHABlock			; unlock data block
		mov	ds, ax				; ds -> data block
		mov	si, ds:[HAD_dir]		; *ds:si -> dir chunkar
		clr	ax
		call	ChunkArrayElementToPtr		; ds:di -> first entry
		call	ChunkArrayGetCount		; cx = # dir entries
findBlockLoop:
		cmp	ds:[di].HADE_handle, dx		; find 
		je	foundBlock			; found it
		add	di, size HugeArrayDirEntry	; bump to next entry
		loop	findBlockLoop

		; if we fall out of the loop, something bad has happened

EC <		ERROR	HUGE_ARRAY_DIR_BLOCK_OVERFLOW			>
NEC <		pop	ax, cx						>
NEC <		jmp	done						>

		; found the right directory entry.  
		; ds:di -> directory entry
foundBlock:
		pop	ax, cx				; ax=elem#, cx = total
		inc	ax
		add	ax, ds:[di-(size HugeArrayDirEntry)].HADE_last.low
		mov	dx, ds:[di-(size HugeArrayDirEntry)].HADE_last.high
		adc	dx, 0
		mov	di, ds:[HAD_self]		; di = dir block handle
		call	UnlockHABlock			; unlock dir block
		call	HugeArrayDelete
		call	HugeArrayLock			; ds:si -> element
NEC <done:								>
		.leave
		ret

HugeArrayContract endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize an array element. If it gets smaller then data at the
		end is truncated (and lost). If it gets larger the new data
		is zero-initialized.

CALLED BY:	GLOBAL
PASS:		bx	- VM file handle in which to create the array
		di	- VM block handle (returned by HugeArrayCreate)
		dx:ax	- element number.
		cx	- new element size.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayResize	proc	far
		uses	ax, di, si, ds, es, bp
		.enter
		push	cx			; Save new size
		call	EnterHugeArray		; *ds:si <- directory array
						; cx <- # of directory blocks
		segmov	es, ds, cx		; es <- dir block
		pop	cx			; Restore new size

		;
		; The elements must be variable sized.
		;
EC <		tst	ds:[HAD_size]		; check size		>
EC <		ERROR_NZ HUGE_ARRAY_ELEMENTS_MUST_BE_VARIABLE_SIZED	>

		;
		; es	= Segment of the directory chunk-array
		; *es:si= Directory chunk-array
		; dx.ax	= Element to resize
		; cx	= New size
		; ds	= es (useful if LockAndCheckResizeElement says "no")
		;
		call	LockAndCheckResizeElement
		;
		; es:di	= Directory entry
		; bp	= Chunk array element number
		; carry set if resize is possible in this block
		; If resize is possible:
		;	*ds:si	= Chunk array
		;	ax	= Chunk array element number
		;	cx	= New size (unchanged)
		;
		jnc	splitBlock		; Branch if can't be done

resizeInPlace:
		;
		; The element can be resized in the current chunk-array.
		;
		; *ds:si= Chunk array
		; ax	= Chunk array element number
		; cx	= New size
		;
		call	ChunkArrayElementResize

		; note that we do not have to mark the block as dirty here
		; since the call to ChunkArrayElementResize above does so.

		call	HugeArrayDirty		; Dirty this block

		;
		; All done...
		;
		call	UnlockHABlock		; Release data block
		
		segmov	ds, es			; ds <- directory block
		call	UnlockHABlock		; Release directory
		.leave
		ret

;-----------------------------------------------------------------------------
splitBlock:
		;
		; We split the block before the current element. 
		;
		; *es:si= Directory chunk-array
		; es:di	= Directory entry for element dx.ax
		; ds	= es
		; dx.ax	= Element we are resizing
		; cx	= New size
		; bp	= Chunk array element number
		;
		xchg	dx, bp			; dx <- chunk array element
						; Preserve element number
		call	SplitHABlock		; Split the block
		mov	dx, bp			; Restore element number
		
		;
		; Try again...
		;
		call	LockAndCheckResizeElement
		jc	resizeInPlace		; Branch if we can resize here
		
		;
		; Split after the current element
		;
		inc	bp			; bp <- next element
		xchg	dx, bp			; dx <- chunk array element
						; Preserve element number
		call	SplitHABlock		; Split the block again...
		mov	dx, bp			; Restore element number
		
		call	LockAndCheckResizeElement
		;
		; This will always succeed because the element is in a block
		; by itself.
		;
EC <		ERROR_NC -1					>
		jmp	resizeInPlace

HugeArrayResize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockAndCheckResizeElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down an element and check to see if it can be resized.

CALLED BY:	HugeArrayResize
PASS:		es	= Segment of the directory array
		*es:si	= Directory array
		dx.ax	= Element to resize
		cx	= New size
RETURN:		es:di	= Directory entry of the chunk-array containing dx.ax
		bp	= Chunk array element number, always
			  (same as cx, if carry set)
		carry set if a resize is possible in the current block
			*ds:si	= Chunk array containing element
			ax	= Chunk array element number
			cx	= Unchanged (new size)
		carry clear if you really should try a different block
			ax, cx, si, ds unchanged
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	An element can be resized if:
		1) It is getting smaller
		2) The change won't exceed HA_UPPER_LIMIT
		3) The change won't exceed 64K in a single block
		4) The element is in a block by itself

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockAndCheckResizeElement	proc	near
	uses	bx, bp
	push	dx

passedDS	local	word		push	ds
passedSI	local	word		push	si
passedAX	local	word		push	ax
newSize		local	word		push	cx
	.enter
	;
	; Find the right directory entry for dx.ax.
	;
	segmov	ds, es				; ds <- segment of directory
	call	ScanHADirectory			; ds:di <- directory entry
						; carry set if not found
EC <	ERROR_C	HUGE_ARRAY_BAD_ELEMENT_NUMBERS			>
	push	di				; Save directory entry

	;
	; Found the right block.  Lock it down so we can figure the
	; current element size.
	;
	call	MapHAElemToCAElem		; dx <- carray-element number
						; ax nuked
	push	dx				; Save element number

	mov	ax, ds:[di].HADE_handle		; ax <- handle
	call	LockHABlock			; ax <- segment of data block
	mov	ds, ax				; ds <- data block

	;
	; es	= Segment of directory block
	; es:di	= Directory entry
	;
	; ds	= Segment of data block
	; dx	= Chunk array element number
	;
	mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si <- chunk array
	call	ChunkArrayGetCount		; cx <- elements in block
	mov	bx, cx				; Save count in bx

	;
	; There is more than one element, get the old size and see if we are
	; exceeding any bounds.
	;
	mov	ax, dx				; ax <- chunk array element #
	call	ChunkArrayElementToPtr		; ds:di <- element
						; cx <- old element size
	mov	dx, newSize			; dx <- new element size

	cmp	bx, 1				; Check for one element
	je	useThisBlock			; Branch if only one


	; I nuked the "je quit" line that followd this compare because
	; it was returning the carry clear, when if the sizes are equal
	; we want the carry set, as it will obviously fit in this block
	; if its the same size...
	; and I changed the jb to a jbe so its just uses the same block
	; for the equal case - jimmy 9/94
	cmp	dx, cx				; Check for new < old
	jbe	useThisBlock			; Resize element

	;
	; The element is growing larger. Check to see if there is
	; enough space to do this.
	;
	sub	dx, cx				; dx <- change in size

	mov	cx, ds:LMBH_blockSize		; cx <- block size
	sub	cx, ds:LMBH_totalFree		; cx <- total used block

	add	cx, dx				; cx <- final block size
	jc	splitBlock			; Branch if over 64K

	cmp	cx, HA_UPPER_LIMIT		; Check for past our limit
	ja	splitBlock			; Branch if it is

useThisBlock:
	;
	; *ds:si= Chunk array
	; ax	= Chunk array element number
	;
	stc					; Signal: use this block

quit:
	;
	; ds, si, and ax should be set for return
	; On stack:
	;	Offset to directory entry
	;
	mov	cx, newSize			; Restore cx (new size)
	pop	dx				; Restore element number
	pop	di				; Restore directory entry
	.leave

	mov	bp, dx				; Return element number in bp
	pop	dx				; Restore passed dx
	ret


splitBlock:
	;
	; Unlock the data block and restore all the passed values
	;
	call	UnlockHABlock			; Release the block
	
	mov	ds, passedDS			; Restore registers
	mov	si, passedSI
	mov	ax, passedAX

	clc					; Signal: try different block
	jmp	quit
LockAndCheckResizeElement	endp

if	FULL_EXECUTE_IN_PLACE
VMHugeArrayResidentXIP		segment	resource
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate a huge-array.

CALLED BY:	LargeLineAdjustForReplacement
PASS:		On stack:
			File			(pushed first)
			Array			(pushed second)
			Callback routine(vfptr) (pushed third)
			Element to start at	(pushed fourth)
			Number to process	(pushed fifth)
		cx, dx, bp, es = Set for callback
RETURN:		carry set if callback aborted
		ax, cx, dx, bp, es = Returned from callback
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Callback should be defined as:
		Pass:	ds:di	= Pointer to element
			fixed size elements:
			    ax - undefined
			    cx, dx, bp, es - data passed to GArrayEnum 
			variable sized elements:
			    ax - element size
			    cx, dx, bp, es - data passed to GArrayEnum
		Return:	carry set to abort
			ax, cx, dx, bp, es - Data for next callback
		Destroyed: nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Note: If number to process is overlarge, HugeArrayEnum will
	stop with the last element. Passing a number to process of -1
	will insure this.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayEnum	proc	far	processCount:dword,
				startElement:dword,
				callback:dword,
				array:word,
				file:hptr
	uses	bx, di, si, ds
cbBP	local	word		push	bp
cbAX	local	word		push	ax
cbCX	local	word		push	cx
cbDX	local	word		push	dx
dirEnd	local	word
	.enter
ForceRef	processCount
ForceRef	callback
ForceRef	cbBP
	;
	; First things first... We need to lock down the vm-block which
	; contains the chunk-array which contains the first element to 
	; process.
	;
	mov	bx, file		; bx <- file
	mov	di, array		; di <- array

	movdw	dxax, startElement	; dx.ax <- element to start with
FXIP<	call	EnterHugeArrayFar	; *ds:si <- directory		>
NOFXIP<	call	EnterHugeArray						>

					; cx <- # of directory blocks

	;
	; We use a 'tst' here because it clears the carry, which is what we
	; want if the branch is taken.
	;
	tst	cx			; Check for no directory entries
	jz	quit			; Branch if no elements

	push	ax			; Save startElement.low
	ChunkSizeHandle	ds, si, ax	; ax <- offset to end of list
	add	ax, ds:[si]		; ax <- ptr to end of directory
	mov	dirEnd, ax		; Save ptr to directory end
	pop	ax			; Restore startElement.low

FXIP<	call	ScanHADirectoryFar	; ds:di <- directory entry	>
NOFXIP<	call	ScanHADirectory						>

EC <	ERROR_C HUGE_ARRAY_BAD_ELEMENT_NUMBERS				>
   
	;
	; We have the right block to start with... We need to figure which
	; element in this block we want to start with
	;

if FULL_EXECUTE_IN_PLACE
	;
	;  For XIP code, we want to add the code in-line, to save
	;  the overhead of doing a far call.
	MAP_HAE_ELEM_TO_CAE_ELEM	di
else
	call	MapHAElemToCAElem	; dx=elem#, ax = #left
endif

;-----------------------------------------------------------------------------
enumLoop:
	;
	; ds:di	= Directory entry
	; dx	= Element to start with in current chunk array
	; bx	= File handle
	; es	= Set for callback
	;
	cmp	di, dirEnd		; Check for past end
	jae	quit			; Branch if no more elements
					; (Carry is clear if we branch)

	push	ds			; Save directory segment
	mov	ax, ds:[di].HADE_handle	; ax <- vm-block handle
	call	LockHABlock		; ax <- segment of the block
	mov	ds, ax			; ds <- segment of the block
	mov	si, HUGE_ARRAY_DATA_CHUNK ; *ax:si <- chunk array

	;
	; Set up and process the elements
	;
	push	bx, di			; Save file, ptr to directory entry
	mov	bx, cs			; bx:di <- vfptr to callback routine
	mov	di, offset HugeArrayEnumCallback
	mov	ax, dx			; ax <- element to start from
	mov	cx, -1			; cx <- # of elements to process

	call	ChunkArrayEnumRange	; Process what's left of this block
	pop	bx, di			; Restore file, ptr to directory entry

	jcxz	noAbort			; Branch if ran out of elements
	jc	releaseAndExit		; Branch if callback aborted
	
	call	UnlockHABlock		; Release current block
	pop	ds			; Restore directory segment

	;
	; Move to the next block
	;
	add	di, size HugeArrayDirEntry
	clr	dx			; Start from start of next group
	jmp	enumLoop		; Go do it...
;-----------------------------------------------------------------------------
noAbort:
	clc				; Signal: did not abort

releaseAndExit:
	;
	; ds	= Segment address of last block we processed
	; carry set if callback aborted
	; On stack:
	;	Segment of directory block
	;
	call	UnlockHABlock		; Release current block (preserves flags)
	pop	ds			; Release directory block

quit:
	call	UnlockHABlock		; Release everything (preserves flags)
	
	;
	; Restore the registers
	;
	mov	ax, cbAX
	mov	cx, cbCX
	mov	dx, cbDX
	.leave
	ret	@ArgSize
HugeArrayEnum	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayEnumCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback for ChunkArrayEnum called from HugeArrayEnum

CALLED BY:	ChunkArrayEnum
PASS:		*ds:si	= Chunk array
		ds:di	= Array element
		ss:bp	= Inheritable stack frame
RETURN:		carry set if callback aborted
		cx	= 0, if we ran out of elements
			= non-zero, if we didn't
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayEnumCallback	proc	far
	.enter	inherit	HugeArrayEnum
	tstdw	processCount		; Check for no more elements
	jz	noMoreElements		; Branch if no more to process

	;
	; There is more...
	;
	decdw	processCount		; One less to process
	
	;
	; Set up to call the *real* callback
	;
	mov	cx, cbCX
	mov	dx, cbDX

	push	bp			; Save frame ptr

if not FULL_EXECUTE_IN_PLACE
EC <	push	ds, si							>
if	ERROR_CHECK
HMA <	cmp	bx, HMA_SEGMENT			;check hi-mem segment	>
HMA <	je	realSegment						>
endif
EC <	cmp	callback.high.high, high MAX_SEGMENT			>
EC <	ERROR_AE	ILLEGAL_SEGMENT					>
realSegment::
EC <	movdw	dssi, callback						>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>

	lea	bx, callback		; ss:bx <- ptr to callback dword
	mov	bp, cbBP

	call	{dword} ss:[bx]		; Call the callback
else
	mov	ss:[TPD_dataAX], ax
	mov	ss:[TPD_dataBX], bx
	movdw	bxax, callback		; bx:ax <- virtual fptr to callback
	mov	bp, ss:[bp]		; bp <- BP to pass to callback

	call	ProcCallFixedOrMovable
endif
	
	mov	bx, bp			; BX <- BP from callback
	pop	bp			; restore frame pointer


	mov	cbAX, ax		; Save registers
	mov	cbCX, cx
	mov	cbDX, dx
	mov	cbBP, bx
	
	;
	; Carry is set to abort...
	;
	mov	cx, 1			; Signal: more elements

quit:
	.leave
	ret

noMoreElements:
	clr	cx			; Signal: no more elements
	stc				; Signal: abort
	jmp	quit
HugeArrayEnumCallback	endp

if FULL_EXECUTE_IN_PLACE
VMHugeArrayResidentXIP		ends
endif

;------------------------------------------------------------------------
;	Support routines
;------------------------------------------------------------------------

kcode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HugeArrayLockDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a huge array directory block

CALLED BY:	EXTERNAL
		EnterGraphics
PASS:		bx.di		- HugeArray file/block handle
RETURN:		ax		- segment address
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HugeArrayLockDir proc	far
		.enter
		mov	ax, di
		call	LockHABlock
		.leave
		ret
HugeArrayLockDir endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockHABlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a HugeArray block, do the special hacks

CALLED BY:	INTERNAL
		called from all over

PASS:		bx	- VM file handle
		ax	- VM block handle to lock

RETURN:		ax	- segment address of block
		carry clear always

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		lock the block;
		stuff the memory handle into the LMBH_handle field;
		set the HF_LMEM bit in the handle structure;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockHABlock	proc	far
		uses	ds, bp
		.enter
	
		; lock the block and set appropriate fields

		call	VMLock				; lock the block
		mov	ds, ax				; es -> dir block
		mov	ds:[LMBH_handle], bp		; save handle
		LoadVarSeg ds				; ds -> kdata
		or	ds:[bp].HM_flags, mask HF_LMEM	; set the LMem bit
							; clears the carry

		.leave
		ret
LockHABlock	endp


kcode	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to lock down directoy block and data block

CALLED BY:	INTERNAL
		various HA routines

PASS:		bx	- VM file handle
		di	- VM block handle for directory block

RETURN:		*ds:si	- directory block ChunkArray
		cx	- #directory entry blocks (not counting bogus one)
		carry clear always
			(There is EC code which counts on this)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		When each block is locked, the memory handle is stuffed
		into the first word of the block, and the LMem bit is set
		in the LMemBlockHeader.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
EnterHugeArrayFar	proc	far
	call	EnterHugeArray
	ret
EnterHugeArrayFar	endp
endif

EnterHugeArray	proc	near
		uses	ax, bp
		.enter

		; lock the directory block and set up some pointers.

		mov	ax, di				; set up block handle
		call	LockHABlock			; lock the dir block
							; Clears the carry
		mov	ds, ax				; ds -> dir block
		mov	si, ds:[HAD_dir]		; dir chunk handle
		mov	bp, ds:[si]			; get # dir entries
		mov	cx, ds:[bp].CAH_count
		
		;
		; The count is always at least one. This means that the
		; this decrement will always clear the carry since cx will
		; never go from 0 to -1.
		;
		; The above is a total lie - "dec" does not affect the carry.
		; However, LockHABlock clears the carry, so it should always
		; be clear here anyway.
		;
		dec	cx				; less 1 for bogus blk

		.leave
		ret
EnterHugeArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanHADirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan the directory for the right block

CALLED BY:	INTERNAL
		HugeArrayLock, HugeArrayDelete

PASS:		*ds:si	- points to directory block chunk array
		dx.ax	- element number to scan for

RETURN:		carry	- clear if found element
		ds:di	- points at directory entry (if carry clear)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		scan entries til we find one where element resides

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE
ScanHADirectoryFar	proc	far
	call	ScanHADirectory
	ret
ScanHADirectoryFar	endp
endif

ScanHADirectory	proc	near
		uses	cx
		.enter

		; scan through the directory structure, looking for the 
		; right block.  First get pointer to directory entries.

		mov	di, ds:[si]
		mov	cx, ds:[di].CAH_count	; get count of dir entries
		dec	cx			; one less (1st one bogus)
		add	di, ds:[di].CAH_offset	; ds:di = element #0
		add	di, size HugeArrayDirEntry ; ds:di = element #1

		; the directory entries have the element number of the final
		; element in that block.  Keep looping until we hit the 
		; entry with a larger number.  
		; cx    = the # of dir entries.
		; dx.ax = element # to match
scanLoop:
		cmpdw	ds:[di].HADE_last, dxax	; check if found block yet
		jae	done			; branch with carry clear
		add	di, size HugeArrayDirEntry
		loop	scanLoop

		; if we fall out of the loop, then the element number passed
		; is too large.  So we should return zero elements found...

		stc				; signal element not found

done:
		.leave
		ret
ScanHADirectory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeHABlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a huge array data block

CALLED BY:	INTERNAL
		DeletePartialBlock
		
PASS:		*ds:si		- points to directory chunk array
		ds:di		- ptr to dir entry of block to free
		bx		- VM File handle

RETURN:		*ds:si		- still points to dir block (may change)
		ds:di		- ptr to dir entry of block after one freed
				  (or before if it was the last one)
		carry		- set if we deleted the last block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		relink the VM chain (plus HAB_prev links);
		free VM block;
		free dir entry;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FreeHABlock	proc	near
		uses	ax, cx, dx, es
		.enter

		; lock the block to get the HAB_prev and HAB_next fields

		push	ds
		mov	ax, ds:[di].HADE_handle		; get handle
		call	LockHABlock			; ax -> block
		mov	ds, ax				; ds -> data block
		mov	cx, ds:[HAB_prev]		; get prev link
		mov	dx, ds:[HAB_next]		; get next link
		call	UnlockHABlock			; release data block
		pop	ds				; ds -> dir block

		; these should match what is in the directory...

EC <		cmp	cx, ds:[di-(size HugeArrayDirEntry)].HADE_handle >
EC <		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS			>
EC <		tst	dx				; test is bad if last >
EC <		jz	skipTest			;  block	>
EC <		cmp	dx, ds:[di+(size HugeArrayDirEntry)].HADE_handle >
EC <		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS			>
EC <skipTest:								>

		; relink the prior and following blocks 

		jcxz	atFirstBlock			; no previous block
		segmov	es, ds				; es -> dir block
		mov	ax, cx				; lock prev block
		call	LockHABlock			; lock previous blk
		mov	ds, ax				; ds -> prev data blk
		mov	ds:[HAB_next], dx		; stuff next field
		call	HugeArrayDirty
		call	UnlockHABlock
		segmov	ds, es				; ds -> dir block
relinkNextBlk:
		or	dx, dx				; see if we're at end
		jz	biffBlock			; if so, we're done
		push	ds
		mov	ax, dx
		call	LockHABlock			;
		mov	ds, ax				; ds -> next block
		mov	ds:[HAB_prev], cx		; store new prev link
		call	HugeArrayDirty
		call	UnlockHABlock
		pop	ds
							
		; done re-linking.  Biff VM block and dir entry
biffBlock:
		mov	ax, ds:[di].HADE_handle		; get VM handle
		call	VMFree

		; these ops done on the directory entries
		call	ChunkArrayDelete		; biff dir entry

		; note that we do not have to mark the block as dirty here
		; since the call to ChunkArrayDelete above does so.
		.leave
		ret

		; if we're at the first block, then re-stuff the head pointer
atFirstBlock:
		mov	ds:[HAD_data], dx		; skip over blk
		call	HugeArrayDirty
		jmp	relinkNextBlk
FreeHABlock	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeletePartialBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete part or all of a data block's elements.  Do garbage
		collection.

CALLED BY:	INTERNAL
		HugeArrayDelete

PASS:		*ds:si		- pointer to Directory chunk array
		ds:di		- pointer to dir entry for block in question
		dx		- element# in block to delete from
		ax		- #elements to delete

RETURN:		ds		- still points to directory block, may have
				  changed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		delete the elements using ChunkArrayDelete;
		modify all the dir entries to reflect new element numbers;
		If (block is now empty)
		    free block and dir entry
		If (block size < HA_LOWER_LIMIT)
		    try to combine block with a neighbor
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeletePartialBlock proc	near
		uses	es, dx, ax, cx
		.enter

		;
		; First, delete the elements in question. Save dir block 
		; info in es
		;
		segmov	es, ds				; es -> dir block
		push	di, si, ax			; save dir entry ptrs
		mov	cx, ax				; cx = delete count

		;
		; Get the chunk-array optr.
		;
		mov	ax, es:[di].HADE_handle		; get handle for block
		call	LockHABlock			; ax -> block
		mov	ds, ax				; ds -> data block
		mov	si, HUGE_ARRAY_DATA_CHUNK	; chunk handle to data

		;
		; Check for deleting from block start.
		;
		mov	ax, dx				; ax = element #
		tst	ax				; if starting from zero
		jnz	deleteSomeElements		;  then check further
		
		;
		; First element to nuke is zero. Check to see if we can just 
		; nuke the entire block.
		;
		push	ax				; save element number
		mov	ax, cx				; save count
		call	ChunkArrayGetCount		; get size of block
		xchg	ax, cx				; restore count
		cmp	ax, cx				; if =, bail
		pop	ax				; restore element #
		jz	deleteWholeBlock

deleteSomeElements:
		;
		; We can't nuke the entire block, but we can nuke part of it.
		;
		; *ds:si= Chunk array
		; ax	= First element to nuke
		; cx	= Number of elements to nuke
		;
		call	ChunkArrayDeleteRange		; Nuke 'em Jesus...

		;
		; Before we unlock the block, get the current count and size
		;
		call	ChunkArrayGetCount		; cx = # elements left
		push	bx				; save VMfile handle
		mov	bx, ds:[LMBH_handle]		; get block mem han
		mov	dx, ds:[LMBH_blockSize]		; get #bytes of data
		sub	dx, ds:[LMBH_totalFree]		; dx = #bytes used
		mov	ax, bx				; ax = handle
		pop	bx				; restore VM file han

		; note that we do not have to mark the block as dirty here
		; since the call to ChunkArrayGetCount above does so.

		call	UnlockHABlock			; done with it for now

		;
		; Get back to directory and modify entries. Check for special
		; conditions for garbage collection.
		;
		pop	di, si, ax			; dir entry,chunk ptrs
		segmov	ds, es				; ds -> dir block
		jcxz	deleteBlock			; biff block altogether
		mov	ds:[di].HADE_size, dx		; save new block size

		;
		; Cruise through all dir entries and fixup HADE_last fields
		;
modBlockCounts:
		neg	ax				; want to subtract...
		call	ModifyElementCounts		; change counts...
		call	HugeArrayDirty

		;
		; The block is OK, leave it alone.  The directory info is
		; all updated, so we're ready to leave...
		;
done:
		.leave
		ret

deleteWholeBlock:
		;
		; Just delete the whole thing.
		;
		call	UnlockHABlock			; unlock data block
		pop	di, si, ax			; restore regts
		segmov	ds, es				; ds:di -> dir entry

deleteBlock:
		;
		; The block has been squeezed out of existance.  Delete it.
		;
		call	FreeHABlock			; delete the block and
							;  relink everything.
		jnc	modBlockCounts			; if wasn't last blk..
		jmp	done				;  else we're done
DeletePartialBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineHABlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine two HugeArray data blocks

CALLED BY:	INTERNAL
		DeletePartialBlock

PASS:		*ds:si		- pointer to directory ChunkArray
		ds:di		- pointer to dir element for 1st block 
				  (next dir element is block to combine with)

RETURN:		*ds:si		- still points to dir block (may have changed)
		ds:di		- pointer to dir element for new combined
				  block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		fixup the HADE_last field of first dir entry
		append the elements from the second to the first
		free the second block
		comput/fixup the HADE_size field of the first dir entry


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CombineHABlocks	proc	near
		uses	ax, dx, es, cx, bx
block1		local	hptr
block2		local	hptr
		.enter

		; copy over the new "last" field

		mov	ax, ds:[di+(size HugeArrayDirEntry)].HADE_last.low
		mov	ds:[di].HADE_last.low, ax
		mov	ax, ds:[di+(size HugeArrayDirEntry)].HADE_last.high
		mov	ds:[di].HADE_last.high, ax

		; lock down both blocks to get at the data.  We'll 
		; need to cycle through all the elements, appending them
		; to the first block.

		mov	dx, ds:[HAD_size]		; dx= element size
		mov	ax, ds:[di].HADE_handle		; get 1st VM handle
		call	LockHABlock			; lock the block
		mov	es, ax				; es -> block
		mov	ax, es:[LMBH_handle]		; grab mem handle
		mov	block1,	ax			; save the handle
		mov	ax, ds:[di+(size HugeArrayDirEntry)].HADE_handle
		call	LockHABlock			; lock the 2nd block
		mov	es, ax				; es -> block
		mov	ax, es:[LMBH_handle]		; grab mem handle
		mov	block2,	ax			; save the handle

		push	ds, si, di			; save dir ptrs
		segmov	ds, es				; ds -> 2nd block
		mov	si, HUGE_ARRAY_DATA_CHUNK	; get ChunkArray handle
		call	ChunkArrayGetCount		; cx = #elements to move
EC <		tst	cx				; any elements?	>
EC <		ERROR_Z HUGE_ARRAY_CORRUPTED				>
		clr	ax				; start w/element zero
		tst	dx				; if zero, variable size
		LONG jz	copyVarElemLoop

		; fixed size elements (cx = count)

		; allocate elements

		mov	bx, block1			; append space
		call	MemDerefDS
		mov	si, HUGE_ARRAY_DATA_CHUNK	; get ChunkArray handle
		push	cx
		call	ChunkArrayGetCount		; cx = new entry #
		mov_tr	ax, cx
		pop	cx
		call	AppendManyElements
		call	ChunkArrayElementToPtr		; ds:di -> new space
		segmov	es, ds				; es:di -> new elements
		mov	bx, block2		
		call	MemDerefDS
		mov	si, ds:[HUGE_ARRAY_DATA_CHUNK]	; ds:si -> ChunkArray
		mov	ax, ds:[si].CAH_elementSize
		mul	cx
		mov_tr	cx, ax
		add	si, ds:[si].CAH_offset
		rep	movsb
		
		; free the second data block. First unlock data blocks
freeExtraData:
		mov	bx, block1			; append space
		call	MemDerefDS
		call	HugeArrayDirty
		call	UnlockHABlock			; unlock the 1st blk
		mov	bx, block2		
		call	MemDerefDS
		call	UnlockHABlock			; unlock the 2nd blk

		pop	ds, si, di			; restore dir pointers
		call	ChunkArrayPtrToElement		; need to save elem#
		push	ax				; save element #
		add	di, size HugeArrayDirEntry	; ds:di -> dir entry
		mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
		mov	bx, ds:LMBH_handle		; bx <- block in file
		call	MemGetInfo			; ax = VM file handle
		mov_tr	bx, ax
		call	FreeHABlock			;  for block to free
		jc	havePrevBlock			; if block was last one
		sub	di, size HugeArrayDirEntry	;  else back up ptr

		; compute the size of the new block and save it.
havePrevBlock:
		push	ds
		mov	ax, ds:[di].HADE_handle		; lock the block
		call	LockHABlock			; ax -> block
		mov	ds, ax				; ds -> data block
		mov	bx, ds:[LMBH_handle]		; get me handle
		mov	dx, ds:[LMBH_blockSize]
		sub	dx, ds:[LMBH_totalFree]		; ax = #bytes used
		call	UnlockHABlock			; release data block
		pop	ds
		pop	ax				; restore dir entry elem
		call	ChunkArrayElementToPtr		; ds:di -> dir entry
		mov	ds:[di].HADE_size, dx		; save block size
		call	HugeArrayDirty
		
		.leave
		ret

		; special loop for copying variable sized elements
copyVarElemLoop:
		push	cx				; save loop count
		push	ax				; save element #
		mov	bx, block2		
		call	MemDerefDS
		mov	si, HUGE_ARRAY_DATA_CHUNK
		call	ChunkArrayElementToPtr		; ds:di ->elem, cx=size
		push	ds, di				; save source ptr
		mov	bx, block1
		call	MemDerefDS
		mov	si, HUGE_ARRAY_DATA_CHUNK
		mov	ax, cx	
		call	ChunkArrayAppend		; append ax bytes
		segmov	es, ds				; es:di -> new space
		pop	ds, si				; ds:si -> element
		rep	movsb				; copy data
		pop	ax				; restore elem #
		inc	ax
		pop	cx				; restore loop count
		loop	copyVarElemLoop
		jmp	freeExtraData
CombineHABlocks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ModifyElementCounts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cruise through directory entries, adding a delta amount to
		all HADE_last fields following the modified directory entry

CALLED BY:	INTERNAL
		InsertElements, DeletePartialBlock, AllocHABlock

PASS:		*ds:si	- pointer to directory block chunk array
		ds:di	- pointer to first affected directory entry
		ax	- signed #elements to add/sub

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		cruise through all the directory entries

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/91		Initial version
		Don	03/00		Performance optimizations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ModifyElementCounts	proc	near
		uses	cx, dx, di
		.enter
	;
	; Determine the number of entries after the one affected
	;
		mov_tr	dx, ax				; dx = count
		call	ChunkArrayGetCount		; cx = #dir entries
EC <		cmp	cx, 0						>
EC <		ERROR_Z	HUGE_ARRAY_CORRUPTED				>
		call	ChunkArrayPtrToElement		; ax = element #
		sub	cx, ax				; elements after current
EC <		ERROR_LE HUGE_ARRAY_CORRUPTED				>
	;
	; OK, modify those entries accordingly
	;
		mov_tr	ax, dx				; ax = count
		cwd					; sign extend count
dirEntryLoop:
		add	ds:[di].HADE_last.low, ax	; modify abs elem #s
		adc	ds:[di].HADE_last.high, dx
		add	di, size HugeArrayDirEntry	; bump to next one
		loop	dirEntryLoop

		.leave
		ret
ModifyElementCounts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CollectGarbage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine any HA blocks, if we can

CALLED BY:	INTERNAL
		HugeArrayDelete

PASS:		*ds:si		- pointer to directory ChunkArray

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		scan through the blocks and combine if we can

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CollectGarbage	proc	near
		uses	ax, cx, di, dx
		.enter

		; check out how many we have left

		pushf					; save everything
		call	ChunkArrayGetCount		; cx = # to go
		jcxz	done
		mov	ax, 1				; start at first one
		call	ChunkArrayElementToPtr		; ds:di -> 1st dir entry
combineLoop:
		inc	ax				; see if done
		cmp	cx, ax
		jbe	done
		mov	dx, ds:[di].HADE_size		; check out size
		add	di, size HugeArrayDirEntry	; check next one
		add	dx, ds:[di].HADE_size
		jc	combineLoop
		cmp	dx, HA_UPPER_LIMIT
		ja	combineLoop
		sub	di, size HugeArrayDirEntry
		call	CombineHABlocks			; combine the suckers
		dec	cx				; one less block
		jmp	combineLoop			; do same block again
done:
		popf
		.leave
		ret
CollectGarbage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure there are no consecutive blocks that can fit
		together.

CALLED BY:	INTERNAL
		HugeArrayDelete

PASS:		*ds:si		- pointer to directory ChunkArray

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		scan through the blocks and combine if we can

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0
;Taken out, as it would erroneously die on old huge arrays
TestSizes	proc	near
		uses	ax, cx, di, dx
		.enter

		; check out how many we have left

		pushf					; save everything
		call	ChunkArrayGetCount		; cx = # to go
		jcxz	done
		mov	ax, 1				; start at first one
		call	ChunkArrayElementToPtr		; ds:di -> 1st dir entry
combineLoop:
		inc	ax				; see if done
		cmp	cx, ax
		jbe	done
		mov	dx, ds:[di].HADE_size		; check out size
		add	di, size HugeArrayDirEntry	; check next one
		add	dx, ds:[di].HADE_size
		jc	combineLoop
		cmp	dx, HA_UPPER_LIMIT
		ja	combineLoop
		ERROR	-1
done:
		popf
		.leave
		ret
TestSizes	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocHAChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the proper number of blocks and dir entries

CALLED BY:	INTERNAL
		HugeArrayAppend...

PASS:		*ds:si		- directory block ChunkArray
		ds:di		- pointer to dir entry.  Place blocks after
				  this one.  (could be initial bogus entry)
		cx		- number of elements 
				  or 
				  size of element (for variable sized elements)

RETURN:		*ds:si		- dir block ChunkArray, ds may have changed
		ds:di		- pointer to dir entry for first one allocated
				  (may be same entry as was passed)
		dx		- local ChunkArray element number for 1st elem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		allocate blocks the size of HA_DESIRED_BLOCK_SIZE til done.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocHAChain	proc	near
		uses	ax, cx, bp
		totalNumElements	local	word
	; The total number of elements to allocate
		
		elementsPerBlock	local	word
	; The # elements to allocate per block (used when allocating fixed
	; sized elements that won't fit into a single block).
		
		.enter

		; get the element size.  If zero, means we're allocating a
		; variable sized beast.

		clr	dx
		mov	ax, 1			; assume one element
		tst	ds:[HAD_size]		; check for variable size
		jz	allocSimple
		mov	ax, ds:[HAD_size]	; ax = element size
		mul	cx			; else get total size
		tst	dx			; if many blocks, start loop
		jnz	multiBlock
		cmp	ax, HA_DESIRED_BLOCK_SIZE
		ja	multiBlock
		xchg	cx, ax			; else do simple alloc

		; cx = #bytes, ax = #elements
allocSimple:
		call	AllocHABlock		; alloc a single block
		call	CombineWithNextIfPossible
done:
		.leave
		ret

		; allocate a chain of blocks.  First, figure out how many
		; elements should go in a single block
multiBlock:
		mov	totalNumElements, cx
		mov	cx, ds:[HAD_size]	; cx = element size
		clr	dx
		mov	ax, HA_DESIRED_BLOCK_SIZE
		div	cx			; ax = #elements/block
		inc	ax			; round up (need at least one)
		mov	elementsPerBlock, ax
		mul	ds:[HAD_size]		;Multiply the # elements/block
		mov_tr	cx, ax			; by the element size to get
						; the total size of the entries
						; we are adding, and put in CX
		mov	ax, elementsPerBlock
		
		; allocate the first block.  Then save the dir entry element
		; number so we can find it again later.

		call	AllocHABlock		; allocate first block
		; Returns ds:di - ptr to dir entry for new HugeArr block
		; dx - chunkarray element # for 1st element

		call	ChunkArrayPtrToElement	; ax = element number
		push	ax, dx			;Save 1st elem # in 1st block
						; for return value, and element
						; # of directory entry
		mov	dx, totalNumElements	; restore total #elements
		mov	ax, elementsPerBlock	; restore #elements/block
		jmp	nextBlock
blockLoop:
	;
	; DX <- # elements left to allocate space for
	; AX <- # elements to allocate in each block
	; DS:DI <- ptr to HugeArrayDirEntry to allocate elements after
	;
		cmp	dx, ax			; Allocate elements for the
		ja	allocBlock		; last block?
		mov	ax, dx			; Just allocate # elements left
allocBlock:
		push	dx			; save total # elements left
		call	AllocHABlock
		pop	dx			; restore total # elements
nextBlock:
		sub	dx, ax			; calc #elements left
		jnz	blockLoop
		call	CombineWithNextIfPossible

		; all done.  restore element number of first dir entry and
		; get pointer to it.

		pop	ax, dx			;AX <- index # of first dir
						; entry
						;DX <- 1st element #
		call	ChunkArrayElementToPtr	; ds:di -> first dir entry
		jmp	done

AllocHAChain	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocHABlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a single HugeArray block

CALLED BY:	INTERNAL
		AllocHAChain

PASS:		*ds:si		- pointer to dir ChunkArray
		ds:di		- pointer to dir entry to place new block after
		ax		- number of elements that represents
		cx		- # bytes to allocate

RETURN:		ds:di		- points to new entry (ds may have changed)
		dx		- local chunkarray element number for 1st elem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		alloc a new block
		alloc a new dir entry

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocHABlock	proc	near
		uses	ax, es, cx
		.enter

		; if the block we're following is small, just combine this one

		mov	dx, ax				; dx=ax = element count
		tst	ds:[di].HADE_handle		; if at the first one.
		jz	allocNewBlock			;  then alloc a new one
		push	cx
		add	cx, ds:[di].HADE_size		; cx = new block size
		cmp	cx, HA_UPPER_LIMIT		; can it fit in the blk?
		pop	cx
		ja	allocNewBlock

		; we're gonna tag on the new elements to the end of this
		; block.  Adjust the last field, from here on out...

		call	ModifyElementCounts		; add in new amount

		; alloc space at the end of the block.

		mov	ax, ds:[di].HADE_handle		; get block handle 
		call	LockHABlock			; ax -> locked block seg
allocNewSpace:
		xchg	cx, dx				; cx = elem cnt
							; dx = elem size (var)
		push	ds, si, di			; save dir entry ptrs
		mov	ds, ax
		mov	si, ds:[HUGE_ARRAY_DATA_CHUNK]	; ds:si -> chunkarray
		push	ds:[si].CAH_count		; new first elem #
		tst	ds:[si].CAH_elementSize
		mov	si, HUGE_ARRAY_DATA_CHUNK
		jz	varSizeAlloc
		call	AppendManyElements
		jmp	afterAlloc
varSizeAlloc:
		mov_tr	ax, dx
varSizeAllocLoop:
		call	ChunkArrayAppend
		loop	varSizeAllocLoop
afterAlloc:

		; done adding elements.  Get the size of the block, then 
		; unlock it.

		mov	dx, ds:[LMBH_blockSize]
		sub	dx, ds:[LMBH_totalFree]		; ax = #bytes used 

		; note that we do not have to mark the block as dirty here
		; since the call to ChunkArrayAppend above does so.

		call	UnlockHABlock			; unlock data block
		
		pop	ax				; restore 1st elem #
		pop	ds, si, di			; restore dir entry ptr
		mov	ds:[di].HADE_size, dx		; store size of block
		mov	dx, ax				; set return value
		call	HugeArrayDirty

		.leave
		ret

		; allocate a new directory element and fill in some info
allocNewBlock:
		tst	ds:[HAD_data]			; handle first blk spec
		jz	handleLastBlock
		IsLastDirEntry				; is it the last one ?
		jz	handleLastBlock
		add	di, size HugeArrayDirEntry	; else bump pointer 
		call	ChunkArrayInsertAt		; ds:di -> new entry

		; init the new entry, fixup HADE_last fields
initDirEntry:
		mov	ax, ds:[di-(size HugeArrayDirEntry)].HADE_last.low
		mov	ds:[di].HADE_last.low, ax
		mov	ax, ds:[di-(size HugeArrayDirEntry)].HADE_last.high
		mov	ds:[di].HADE_last.high, ax
		mov	ax, dx				; ax = counts
		call	ModifyElementCounts
		call	HugeArrayDirty

		; allocate the block.  Just need enough room initially to 
		; hold HAB structure and requested space.

		call	AllocNewDataBlock		; ax -> locked block seg
		jmp	allocNewSpace

		; last directory entry.  just append new one
handleLastBlock:
		call	ChunkArrayAppend		; append new element
		jmp	initDirEntry
AllocHABlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineWithNextIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current block can be combined with the
		next block (the sum of the sizes < HA_UPPER_LIMIT)

CALLED BY:	GLOBAL
PASS:		*ds:si - pointer to directory ChunkArray
		ds:di - HugeArrayDirEntry for current block
RETURN:		nothing
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CombineWithNextIfPossible	proc	near	uses	ax, cx
	.enter

;	Check to see if we are the *last* block in the chain - if so, don't
;	do anything, as there is no next block to combine with.

	call	ChunkArrayPtrToElement
	inc	ax			;Element # of next element (if any)
	call	ChunkArrayGetCount
	cmp	ax, cx
	jae	exit			;Branch if no next element
	
	mov	ax, ds:[di].HADE_size
	add	ax, ds:[di + size HugeArrayDirEntry].HADE_size
	jc	exit
	cmp	ax, HA_UPPER_LIMIT
	ja	exit
	call	CombineHABlocks
exit:	
	.leave
	ret
CombineWithNextIfPossible	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineWithPreviousIfPossible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the current block can be combined with the
		previous block (the sum of the sizes < HA_UPPER_LIMIT)

CALLED BY:	GLOBAL
PASS:		*ds:si - pointer to directory ChunkArray
		ds:di - HugeArrayDirEntry for current block
RETURN:		ds:di - pointing to HugeArrayDirEntry for current block 
			(possibly combined with previous block)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CombineWithPreviousIfPossible	proc	near	uses	ax
	.enter

;	Exit if we are the 0th or 1st element (the 0th element is not a valid
;	element, so we cannot combine the 1st element with the 0th element
;	anyway).

	call	ChunkArrayPtrToElement
	cmp	ax, 1
	jbe	exit
	mov	ax, ds:[di].HADE_size
	add	ax, ds:[di - size HugeArrayDirEntry].HADE_size
	jc	exit
	cmp	ax, HA_UPPER_LIMIT
	ja	exit
	sub	di, size HugeArrayDirEntry
	call	CombineHABlocks
exit:	
	.leave
	ret
CombineWithPreviousIfPossible	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	AppendManyElements

DESCRIPTION:	Append many elements to a huge array block

CALLED BY:	INTERNAL

PASS:
	*ds:si - chunk array
	cx - # of elements to append

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
	Tony	11/ 3/92		Initial version

------------------------------------------------------------------------------@
AppendManyElements	proc	near	uses ax, bx, cx, dx, di
	.enter

	mov	di, ds:[si]
	mov	ax, ds:[di].CAH_elementSize
	add	ds:[di].CAH_count, cx
	mul	cx				; ax = size to add
	mov_tr	cx, ax				; cx = size to add
	ChunkSizePtr	ds, di, bx		; bx = offset to insert at
	mov	ax, si
	call	LMemInsertAt

	.leave
	ret

AppendManyElements	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocNewDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a new VM block for data

CALLED BY:	INTERNAL
		AllocHABlock, SplitHABlock

PASS:		*ds:si	- pointer to dir chunk array
		ds:di	- dir entry for block (already allocated)

RETURN:		ds:di	- HADE_handle initialized
		ax	- segment handle of new block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		allocate the block;
		init block data;
		link block in VM Chain;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocNewDataBlock proc	near
		uses	cx, ds, es, dx, si, di
		.enter

		; allocate the block.  Just need enough room initially to 
		; hold HAB structure and requested space.

		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size HugeArrayBlock		; total space needed
		call	VMAllocLMem			; ax = block

		mov	cx, SVMID_HA_BLOCK_ID		; give it the right ID
		call	VMModifyUserID			; set ID for block
 
		mov	ds:[di].HADE_handle, ax		; store vm handle
		call	HugeArrayDirty

		; lock the block and init the header

		segmov	es, ds				; es -> dir block
		push	bp
		call	VMLock				; lock the block
		mov	ds, ax
		mov	ds:[LMBH_handle], bp		; save mem handle
		pop	bp

		; init the fields that we know so far

		mov	dx, es:[HAD_self]		; vm blk handle of dir
		mov	ds:[HAB_dir], dx		; fill dir field

		; create the ChunkArray for the data

		push	bx
		clr	al
		mov	bx, es:[HAD_size]		; element size
		clr	cx				; no extra header info
		clr	si
		call	ChunkArrayCreate		; *ds:si -> chunk array
EC <		cmp	si, HUGE_ARRAY_DATA_CHUNK			>
EC <		ERROR_NZ HUGE_ARRAY_WRONG_CHUNK_ALLOCATED		>
		pop	bx

		; next we need to link this block with the others around it.
		; if this is the first block, it's easy.  Load up block handles
		; cx=prev, dx=next, ax=curr.  The following code works ok even 
		; if the block we added is the new 1st block, since there is a
		; always a 0th dir entry that has HADE_handle set to zero.

		mov	ax, es:[di].HADE_handle		; load up handles
		mov	cx, es:[di-(size HugeArrayDirEntry)].HADE_handle
		mov	ds:[HAB_prev], cx		; save prev handle
		call	HugeArrayDirty
		jcxz	headBlock

		; this is not the head block, so we need to lock it down and
		; swap out the next field...

		push	ds
		xchg	ax, cx				; ax=prev, cx=curr
		call	LockHABlock			; lock prev blk
		mov	ds, ax				; ds -> prev blk
		mov	dx, ds:[HAB_next]		; dx = next blk
		mov	ds:[HAB_next], cx		; store new link
		call	HugeArrayDirty
		call	UnlockHABlock
		mov	ax, cx				; ax = curr 
		pop	ds
doNextBlk:
EC <		tst	dx						>
EC <		jz	ecLastBlock					>
EC <		cmp	dx, es:[di+(size HugeArrayDirEntry)].HADE_handle >
EC <		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS			>
EC <ecLastBlock:							>
		mov	ds:[HAB_next], dx		; store next field
		call	HugeArrayDirty
		tst	dx				; is there a next one?
		jz	linksAdded

		; have a real next block.  Lock it down and twiddle.

		push	ds
		xchg	ax, dx				; ax = next, dx=curr
		call	LockHABlock			; lock it down
		mov	ds, ax
EC <		mov	ax, es:[di-(size HugeArrayDirEntry)].HADE_handle >
EC <		cmp	ax, ds:[HAB_prev]				>
EC <		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS			>
		mov	ds:[HAB_prev], dx		; save new prev blk
		call	HugeArrayDirty
		call	UnlockHABlock
		pop	ds				; ds -> new data block

		; all the links are in place. Return the segment
		; of the new (locked) block
linksAdded:
		mov	ax, ds

		.leave
		ret

		; head data block.  
headBlock:
		mov	dx, es:[HAD_data]		; dx = next block
		mov	es:[HAD_data], ax		; save as head ptr
		push	ds
		segmov	ds, es
		call	HugeArrayDirty
		pop	ds
		jmp	doNextBlk

AllocNewDataBlock endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplitHABlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Split an existing block in two

CALLED BY:	INTERNAL
		HugeArrayInsert

PASS:		*ds:si	- pointer to directory ChunkArray
		ds:di	- pointer to dir entry for block to split
		dx	- ChunkArray element number of element to split at
			  (put this element in the second block)

RETURN:		ds:di	- points to dir entry for first part of block (or 
			  previous block if dx passed as zero)
			  (ds may change)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		add a new block to the scheme of things;
		copy the data over;
		check for null resulting blocks and kill them;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplitHABlock	proc	near
		uses	ax, dx, cx
		.enter

		; if it's the first element of the block, don't allocate
		; anything.  Just adjust the dir pointer to the previous blk.

		tst	dx			; at first element ?
		jnz	reallySplitIt		; don't allocate, just adjust
		sub	di, size HugeArrayDirEntry ; backup to previous block
done:
		.leave
		ret

		; OK, no easy way out.  Alloc a new VM block to put the
		; beginning elements into.  Do all the right dir entry stuff.
reallySplitIt:
		call	ChunkArrayInsertAt	; ds:di -> new dir entry

		; note that we do not have to mark the block as dirty here
		; since the call to ChunkArrayInsertAt above does so.

		mov	ax, ds:[di-(size HugeArrayDirEntry)].HADE_last.low
		add	ax, dx
		mov	ds:[di].HADE_last.low, ax ; copy over to init
		mov	ax, ds:[di-(size HugeArrayDirEntry)].HADE_last.high
		adc	ax, 0
		mov	ds:[di].HADE_last.high, ax ; copy over to init
		call	AllocNewDataBlock	; allocate the sucker

		; now we need to copy the elements into the new block.
		; dx holds the number of elements to copy from second to first 
		; lock both blocks to do the dirty work

		mov	cx, dx
		push	es, ds, di			; save dir entry ptr
;;;		mov	ax, ds:[di].HADE_handle		; lock new one
;;;		call	LockHABlock
		mov	es, ax				; es -> new block
		mov	ax, ds:[di+(size HugeArrayDirEntry)].HADE_handle
		call	LockHABlock			; lock exitsing block
		mov	dx, ds:[HAD_size]		; check for variable
		mov	ds, ax				; ds -> existing block
		mov	ax, dx				; ax = element size
		mov	dx, cx				; dx = #elem again
		tst	ax				; check for var sized
		LONG jz	copyVarElem			; diff for var sized

		; it's all fixed size, allocate all the new space then
		; do a block copy of the data.

		push	cx				; save #elements
		mul	dx				; ax = size of move
		mov	dx, ax				; save in dx
		push	ds				; save existing blk ptr
		segmov	ds, es				; ds -> new block
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> chunkarray
		call	AppendManyElements
		clr	ax				; setup at element0
		call	ChunkArrayElementToPtr		; ds:di -> element
		segmov	es, ds				; es:di -> first elem
		pop	ds				; ds -> old block
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> old data
		push	di
		clr	ax
		call	ChunkArrayElementToPtr		; get pointer to 0th
		mov	si, di				; ds:si -> source
		pop	di
		mov	cx, dx				; cx = #bytes to move
		rep	movsb
		pop	cx				; restore #elements

		; all done with new block.  delete elements from old block
		; ds -> old block
		; cx  = element count
deleteCopies:
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> old data
		clr	ax				; deleting element 0
							; cx == number to nuke
		call	ChunkArrayDeleteRange		; Nuke the range

		; old block is OK now, get sizes, unlock blocks, update
		; dir entries

		mov	dx, ds:[LMBH_blockSize]
		sub	dx, ds:[LMBH_totalFree]		; dx = #bytes used

		; note that we do not have to mark the block as dirty here
		; since the call to ChunkArrayDeleteRange above does so.

		call	UnlockHABlock
		segmov	ds, es				; unlock new block too
		mov	ax, ds:[LMBH_blockSize]
		sub	ax, ds:[LMBH_totalFree]		; ax = #bytes used
		call	HugeArrayDirty
		call	UnlockHABlock
		pop	es, ds, di			; ds:di -> new dir ent
		mov	ds:[di].HADE_size, ax		; store new block size
		mov	ds:[di+(size HugeArrayDirEntry)].HADE_size, dx
		mov	si, ds:[HAD_dir]		; reload chunk handle
		jmp	done

copyVarElem:
		; copy variables sized elements from one block to the other.
		; ds -> old block
		; es -> new block
		; cx  = #elements to copy
		clr	ax				; start at element 0
		mov	dx, cx				; save element count
copyVarLoop:
		push	cx, ax				; save #elements, cur#
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> old data
		call	ChunkArrayElementToPtr		; ds:di -> elem, cx=size
		push	ds, di				; save existing blk ptr
		segmov	ds, es				; ds -> new block
		mov	si, HUGE_ARRAY_DATA_CHUNK	; *ds:si -> chunkarray
		mov	ax, cx				; ax = elem size
		call	ChunkArrayAppend		; ds:di -> element
		segmov	es, ds				; es:di -> dest elem
		pop	ds, si				; ds:si -> src elem
		rep	movsb				; copy data
		pop	cx, ax				; restore #elements,
		inc	ax				; on to next element
		loop	copyVarLoop
		mov	cx, dx				; restore elem count
		jmp	deleteCopies
		
		
SplitHABlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitHAChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a string of HugeArray elements

CALLED BY:	INTERNAL
		HugeArrayAppend, HugeArrayInsert

PASS:		ds:di		- pointer to dir entry for first blk allocated
		bp:si		- pointer to initialization data
		dx		- element number in block 
		cx		- #elements to init (or size of variable sized)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		copy the data to the space.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitHAChain	proc	near
		uses	ax, cx, dx, di, si, es
		.enter

		; check to see if this is a single element.  If not, do
		; some looping...

		tst	ds:[HAD_size]		; is element size zero ?
		jz	singleElement		;  yes, then single element
		cmp	cx, 1			; Is it a single element ?
		jne	multiElement		;  no, loop
		mov	cx, ds:[HAD_size]	; set cx=#bytes to copy

		; single element, cx=#bytes to copy
singleElement:
		push	ds, di
		push	si, cx			; save init data ptr
		mov	ax, ds:[di].HADE_handle	; lock the block
		call	LockHABlock
		mov	ds, ax			; ds -> data block
		mov	si, HUGE_ARRAY_DATA_CHUNK ; *ds:si -> data
		mov	ax, dx			; ax = element number
		call	ChunkArrayElementToPtr	; ds:di -> element
		segmov	es, ds			; es:di -> element
		pop	si, cx			; bp:si -> init data
		mov	ds, bp			; ds:si -> init data
		rep	movsb			; copy the data
		segmov	ds, es			; ds -> data block
		call	HugeArrayDirty
		call	UnlockHABlock		; unlock the data block
		pop	ds, di			; restore dir ptrs
done:
		.leave
		ret

		;
		; There are multiple elements to copy, and they are all 
		; the same size.  cx=#elements
		;
		; We grab a pointer to the place to copy the data in the
		; huge-array. Then we copy as many elements as we can at
		; once into the array.
		;
		; We then grab a pointer to the start of the next chunk-array
		; and continue.
		;
multiElement:
		;
		; ds:di	= Directory entry
		; bp:si	= Data to copy
		; dx	= Element number to start writing at
		; cx	= Number of elements to copy
		;
		push	dx			; Save element to start at
		mov	ax, ds:HAD_size		; ax <- size of each element
		mul	cx			; dx.ax <- # of bytes to copy
		pop	dx			; Restore element to start at

copyLoop:
		;
		; ds:di	= Current directory entry
		; bp:si	= Data to copy
		; ax	= Number of bytes left to copy
		; dx	= Element number in current entry to start at
		;
		tst	ax			; Check for no more to copy
		jz	endCopyLoop		; Branch if nothing left

		push	ds, di, ax		; Restore directory entry,
						;   Total # of bytes to copy
		;
		; Get a pointer to the destination
		;
		push	ax, si			; Save total count, source.low
		mov	ax, ds:[di].HADE_handle	; get block handle
		call	LockHABlock		; ax <- segment of destination
		mov	ds, ax			; ds <- segment of destination
		mov	si, HUGE_ARRAY_DATA_CHUNK ; *ds:si <- Chunk array
		
		mov	ax, dx			; ax <- element to point at
		call	ChunkArrayElementToPtr	; ds:di <- ptr to destination
		ChunkSizeHandle	ds, si, cx	; cx <- offset to end of chunk
		add	cx, ds:[si]		; cx <- ptr to end of chunk
		sub	cx, di			; cx <- bytes before end of chunk
		pop	ax, si			; Restore total count, src.low
		
		;
		; ds:di	= Destination
		; bp:si	= Source
		; ax	= Total number of bytes to copy
		; cx	= Number of bytes available after destination pointer
		;
		cmp	ax, cx			; Check for having enough space
		jbe	gotBytes		; Branch if we do
		mov	ax, cx			; ax <- # of bytes to copy
gotBytes:
		push	ax			;save # bytes to copy
		
		;
		; Copy the data.
		;
		; ds:di	= Destination
		; bp:si	= Source
		; ax	= Number of bytes to copy
		;
		mov	cx, ax			; cx <- # of bytes to copy
		segmov	es, ds, ax		; es:di <- Desination
		mov	ds, bp			; ds:si <- source
		
		rep	movsb			; Move the data
		
		;
		; Release this block
		;
		segmov	ds, es, ax		; ds <- Destination block
		call	HugeArrayDirty		; Dirty the block
		call	UnlockHABlock		; Release the chunk-array

		pop	cx			; cx = number bytes copied
		pop	ds, di, ax		; Restore directory entry,
						;   Total # of bytes to copy,
						;   # of bytes copied
		;
		; Advance to the next directory entry
		;
		add	di, size HugeArrayDirEntry ; ds:di <- next entry
		sub	ax, cx			; ax <- # of bytes left to copy
		clr	dx			; dx <- Place to start copying
		jmp	copyLoop		; Loop to copy more

endCopyLoop:
		;
		; All done copying.
		;
		jmp	done
InitHAChain	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupHugeArrayChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fixes up a hugearray directory's pointers to its elements
		in the VM Chain

CALLED BY:	RESTRICTED GLOBAL
		CopyTreeLow from VMCopyVMChain
PASS:		bx.ax	- VM file/block handle to dir block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		fixup all the links in the blocks

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 2/92		Initial version
	insik	3/ 1/93		Exported for restricted global for use by ui

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixupHugeArrayChain	proc	far
		uses	ds, es, ax, bp, cx, di, si, dx
		.enter

		mov	cx, ax			; cx = dir block handle
		call	VMLock			; ax -> dir block
		mov	ds, ax			; ds -> dir block
		mov	dx, ds:[VMCL_next]	; dx = block han of next blk
		mov	ds:[HAD_self], cx	; store new "self" reference
		mov	ds:[HAD_data], dx	; store next field

		; di will be used below as a repository for the "prev" handle.
		; This will be used to modify the HAB_prev field of the data
		; blocks.  However, the first data block should have this 
		; field be ZERO, *not* the handle of the dir block.  Change
		; this line of code to effect that.  jim  6/1/93.

;		mov	di, cx			; also save handle here
		clr	di			; first data block HAB_prev 
						;  field should be zero (see
						;  code below)

		; we need to do the LMem thing, like LockHABlock.

		mov	ds:[LMBH_handle], bp	; store memory handle
		push	ds
		LoadVarSeg ds
		or	ds:[bp].HM_flags, mask HF_LMEM	; set the LMem bit
		pop	ds			; restore ds -> dir block

		; get ds:si -> directory entries, then we can fly through
		; the blocks, one at a time.

		mov	si, ds:[HAD_dir]	; get dir chunk handle
		mov	si, ds:[si]		; ds:si -> ChunkArray
		mov	cx, ds:[si].CAH_count	; get count of dir entries
		dec	cx			; one less (1st one bogus)
		jz	noElements
		add	si, ds:[si].CAH_offset	; ds:si = element #0
		add	si, size HugeArrayDirEntry ; ds:si = element #1

		; ds:si -> Dir entry for next block to change
		; dx = new VM block handle of next block to change
		; di = prev block
		; cx = count of blocks left to change
blockLoop:
EC <		tst	dx			; can't be zero here 	>
EC <		ERROR_Z HUGE_ARRAY_CORRUPTED	;  bail if it is	>
		mov	ds:[si].HADE_handle, dx	; save new block handle in dir
		mov	ax, dx			; lock the block
		call	VMLock			; lock the block
		mov	es, ax			; es -> block
		mov	es:[HAB_prev], di	; store prev block
		mov	di, dx			;  and curr will become prev
		mov	dx, es:[VMCL_next]	; get next block, will bec curr
		mov	es:[HAB_next], dx	;  and save it immediately
		mov	ax, ds:[HAD_self]	; get dir block handle
		mov	es:[HAB_dir], ax	;  and store it
		call	VMDirty
		call	VMUnlock		; release data block
		add	si, size HugeArrayDirEntry ; ds:si -> next entry
		loop	blockLoop

		; all done with all blocks.  Unlock the dir block and exit
noElements:
		call	HugeArrayDirty		; dirty the dir block
		call	UnlockHABlock		; release dir block

		.leave
		ret
FixupHugeArrayChain	endp

;---------------------------------------------------------------------------
;		ERROR CHECKING CODE
;---------------------------------------------------------------------------

ECCheckHugeArrayFar	proc	far
EC <		uses	ax, bx, cx, dx, si, di, ds, es			>
EC <		.enter							>
EC <		pushf							>
EC <		call	EnterHugeArray					>
EC <		call	ECCheckHugeArray				>
EC <		call	UnlockHABlock					>
EC <		popf							>
EC <		.leave							>
		ret
ECCheckHugeArrayFar	endp


if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckHugeArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the HugeArray data structures

CALLED BY:	INTERNAL

PASS:		ds	- points to locked directory block

RETURN:		nothing	 (FatalError if something is wrong)

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		make sure:
		    - element numbers are ascending in the dir entries;
		    - each VM block exists
		    - number of elements in each block agrees with header
		    - HADE_size field is correct for each block
		    - next/prev links are correct


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckHugeArray proc	near
		uses	ax, bx, cx, dx, si, di, es
		.enter
		pushf

		; get error checking level and only do this if ECF_VMEM is
		; set.

		push	bx, ax
		call	SysGetECLevel
		test	ax, mask ECF_VMEM
		pop	bx, ax
		LONG jz	done

		; check the VMUserID for SVMID_HA_DIR_ID 

		push	cx, ax, di
		mov	ax, ds:[HAD_self]		; check out the ID
		call	VMInfo				; di = ID
		cmp	di, SVMID_HA_DIR_ID		; make sure ID is right
		ERROR_NE HUGE_ARRAY_BAD_DIRECTORY
		pop	cx, ax, di

		; get the count of directory entries

		mov	si, ds:[HAD_dir]		; *ds:si -> entries

		call	ECCheckChunkArray		; check it out
;EC <		call	TestSizes					>

		call	ChunkArrayGetCount		; cx = #dir entries
		cmp	cx, 1				; always has at least 1
		je	checkEmptyArray			; looks empty, make sure
		ERROR_B HUGE_ARRAY_BAD_DIRECTORY
		push	cx				; save count

		; OK, we have a non-empty array.  Must have a head data link.

		tst	ds:[HAD_data]			; must be non-zero
		ERROR_Z	HUGE_ARRAY_BAD_BLOCK_LINKS

		; Also make sure the HADE_self field is accurate.

		mov	bx, ds:[LMBH_handle]		; get memory handle
		call	VMMemBlockToVMBlock		; get VM handle
		cmp	ds:[HAD_self], ax		; make sure handle OK
		ERROR_NE HUGE_ARRAY_BAD_DIRECTORY
		call	VMInfo				; see if block is valid
		ERROR_C	HUGE_ARRAY_BAD_DIRECTORY

		; The extended dir block field should be zero (for now)

		tst	ds:[HAD_xdir]
		ERROR_NZ HUGE_ARRAY_BAD_DIRECTORY

		; go through each entry, and check some stuff:
		;  - HADE_last fields should ascend
		;  - VM block should be valid
		;  - next/prev links should be valid
		;  - #elements in block should match info in dir entry

		mov	ax, 1				; start at first elem
		mov	si, ds:[HAD_dir]		; *ds:si -> entries
		call	ChunkArrayElementToPtr		; ds:di -> first entry
		pop	cx				; restore dir elem count
		dec	cx				; first one bogus...
checkNumLoop:
		call	ECCheckHABlock
		loop	checkNumLoop
done:
		popf
		.leave
		ret

checkEmptyArray:
		tst	ds:[HAD_data]			; must be zero if empty
		ERROR_NZ HUGE_ARRAY_BAD_BLOCK_LINKS
		jmp	done

ECCheckHugeArray endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckHABlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check out a HugeArray block

CALLED BY:	INTERNAL
		ECCheckHugeArray

PASS:		ds:di	-> dir entry of block to check

RETURN:		ds:di	-> advanced to next dir entry

DESTROYED:	ax,bx,dx

PSEUDO CODE/STRATEGY:
		make sure:
		    - each VM block exists
		    - number of elements in each block agrees with header
		    - next/prev links are correct

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckHABlock	proc	near
		uses	cx
		.enter

;	The first entry can be empty/have HADE_last = 0xffffffff, so skip
;	this EC code.

		cmpdw	<ds:[di-(size HugeArrayDirEntry)].HADE_last>, -1
		je	skipElementNumberCheck
		mov	ax, ds:[di-(size HugeArrayDirEntry)].HADE_last.low
		mov	dx, ds:[di-(size HugeArrayDirEntry)].HADE_last.high
		cmpdw	dxax, <ds:[di].HADE_last>
		ERROR_AE HUGE_ARRAY_BAD_ELEMENT_NUMBERS
skipElementNumberCheck:
		mov	ax, ds:[di].HADE_handle
		push	di				; make sure block OK
		call	VMInfo
		pop	di
		ERROR_C HUGE_ARRAY_BAD_BLOCK

		segmov	es, ds				; es -> dir
		mov	ax, es:[di].HADE_handle		; lock blk, check links
		call	LockHABlock			; ax -> block
		mov	ds, ax				; ds -> block
		mov	dx, ds:[HAB_prev]		; check prev link
		tst	dx
		jz	checkHead

		;
		;  We want to skip this next bit if the passed block was
		;  the bogus one
		;

		cmp	es:[di-(size HugeArrayDirEntry)].HADE_last.high, 0xffff
		jne	notBogus
		cmp	es:[di-(size HugeArrayDirEntry)].HADE_last.low, 0xffff
		je	getNext

notBogus:
		cmp	dx, es:[di-(size HugeArrayDirEntry)].HADE_handle
		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS
getNext:		
		mov	dx, ds:[HAB_next]
		tst	dx				; check for last block
		jz	checkLast
		cmp	dx, es:[di+(size HugeArrayDirEntry)].HADE_handle
		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS
checkCount:
		mov	si, HUGE_ARRAY_DATA_CHUNK	; get data chunk handle
		call	ECCheckChunkArray		; check it out
		call	ChunkArrayGetCount		; see if count is ok
		clr	dx
		add	cx, es:[di-(size HugeArrayDirEntry)].HADE_last.low
		adc	dx, es:[di-(size HugeArrayDirEntry)].HADE_last.high
		cmp	cx, es:[di].HADE_last.low
		ERROR_NE HUGE_ARRAY_BAD_ELEMENT_NUMBERS
		cmp	dx, es:[di].HADE_last.high
		ERROR_NE HUGE_ARRAY_BAD_ELEMENT_NUMBERS

		call	UnlockHABlock
		segmov	ds, es				; ds -> dir block
		add	di, size HugeArrayDirEntry	; bump to next one
		.leave
		ret
checkHead:
		mov	dx, es:[di].HADE_handle
		cmp	dx, es:[HAD_data]		; must be first block
		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS
		jmp	getNext

checkLast:
		pop	cx				; pop loop count
		cmp	cx, 1				; on last leg ?
		ERROR_NE HUGE_ARRAY_BAD_BLOCK_LINKS
		push	cx
		jmp	checkCount
ECCheckHABlock	endp
endif


VMHugeArray	ends
