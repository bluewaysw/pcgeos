COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Hash Library
FILE:		hIndex.asm

AUTHOR:		Paul L. DuBois, Nov 21, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB HashTableResize		Expand and rehash a hash table

    GLB HashTableCreate		Create a hash table in an LMem heap

    GLB HashTableLookup		Look up an entry in the hash table

    GLB HashTableRemove		Remove an element from the hash table

    EXT HT_LookupLow		Look up an entry in the hash table

    INT HT_SlowCheck		Check to see if a chunklet really matches by
				calling the comparison callback routine

    GLB HashTableAdd		Add an entry

    INT HT_CheckChain		Check a chain to see if it contains an element

    INT HT_HashData		Call the hash function and return the full hash
				value and the corresponding hash chain.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/21/94   	Initial revision


DESCRIPTION:
	Routines that manage the index chunk.
	These are also the user-level hash table routines.

	$Id: hindex.asm,v 1.1 97/05/30 06:48:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashTableResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand and rehash a hash table

CALLED BY:	GLOBAL
PASS:		*ds:si	- hash table
		cx	- new # buckets
RETURN:		carry	- set on error
DESTROYED:	nothing
SIDE EFFECTS:
	Hash table integrity is checked before and afterwards.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashTableResize	proc	far
	uses	ax,bx,cx,dx, es,di,si,bp
	.enter

	; Resize index chunk.  OK to punt if this fails, we haven't
	; messed up any data structures (yet :)
	;		
EC <		call	ECCheckHashTable				>
		tst	cx
	LONG_EC	jz	errorDone

		mov	bx, cx		; save for later
		shl	cx		; each bucket is 2 bytes
		mov	di, ds:[si]
		add	cx, ds:[di].HTH_headerSize
		mov	ax, si
		call	LMemReAlloc
		jc	done

	; Null out list heads in preparation for re-hashing everything
	; Also, update HTH_headerSize
	;
		mov	di, ds:[si]	; ds:di <- hash table
		mov	ds:[di].HTH_tableSize, bx

		segmov	es, ds, ax
		add	di, es:[di].HTH_headerSize
		mov	cx, bx
		mov	ax, MH_NULL_ELEMENT
		rep	stosw

	; Mark free miniheap elements so we don't try to hash them
	;
		mov	si, ds:[si]
		mov	di, si		; ds:di <- hash table
		mov	si, ds:[si].HTH_heap
		call	MHMarkFree

	; Finally... re-create hash bucket lists
	;
		mov	si, ds:[si]	; ds:si <- mini heap
		mov	cx, ds:[si].MHH_size
		mov	bp, offset MHH_data

		jcxz	done		; don't need to call MHRestoreFree
					; because there aren't any elts.
addLoop:
	; ds:di	- hash table
	; ds:si	- mini heap
	; ds:si+bp - current chunklet
		cmp	ds:[si+bp].HTE_link, MH_FREE_ELEMENT
		je	al_next

		push	cx
		movdw	cxdx, ({dword}ds:[si+bp].HTE_data)
		call	HT_HashData	; ax <- hash, bx <- entry #
EC <		cmp	ah, ds:[si+bp].HTE_keyBits			>
EC <		ERROR_NE HASH_TABLE_INTERNAL_ERROR			>
		pop	cx

	; Point ds:[di+bx] at list head, push current elt onto list
	;
		shl	bx		; heads are a word apiece
		add	bx, ds:[di].HTH_headerSize

		mov	dx, ds:[di+bx]	; dx <- old list head
		mov	ds:[di+bx], bp	; current chunklet is now head
		mov	ds:[si+bp].HTE_link, dx
al_next:
		add	bp, ds:[si].MHH_entrySize
		loop	addLoop
		
		mov	si, ds:[di].HTH_heap
		call	MHRestoreFree
		clc
done:
	.leave
EC <		call	ECCheckHashTable				>
	ret

errorDone:
		stc
		jmp	done
HashTableResize	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashTableCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a hash table in an LMem heap

CALLED BY:	GLOBAL
PASS:
	ds	- block for new table
	al	- ObjChunkFlags to pass to LMemAlloc
	bx	- HashTableFlags
	cx	- size for HashTableHeader (this allows for reserving extra
		  space)  0 = default.  Extra space is initialized to zeros.
	dx	- initial # of list heads/buckets
	stack	- vfptr to comparison function (pushed first),
		  vfptr to hash function

RETURN:
	args not popped off stack
	carry set if couldn't allocate chunk and LMF_RETURN_ERRORS set
	carry clear if array allocated:
		*ds:ax	- table (block possibly moved)

DESTROYED:	nothing
SIDE EFFECTS:	
	WARNING: This routine MAY resize the LMem block, moving it on the
		 heap and invalidating stored segment pointers and current
		 register or stored offsets to it.

PSEUDO CODE/STRATEGY:
	Rounds header size up to nearest word

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashTableCreate	proc	far	hashFn: vfptr,
				compFn: vfptr
	uses	cx,si,di,es
objChunkFlags	local	word		push	ax
tableChunk	local	lptr
		
	.enter
if ERROR_CHECK
		Assert	lmem, ds:[LMBH_handle]
		push	bx
		and	bx, mask HTF_ENTRY_SIZE
		tst	bx
		ERROR_Z	HASH_TABLE_BAD_ENTRY_SIZE
		cmp	bx, 4
		ERROR_A	HASH_TABLE_BAD_ENTRY_SIZE
		pop	bx
		tst	dx
		ERROR_Z HASH_TABLE_BAD_TABLE_SIZE
endif

		tst	cx
		jnz	notZero
		mov	cx, size HashTableHeader
notZero:
EC <		cmp	cx, size HashTableHeader			>
EC <		ERROR_B	HASH_TABLE_HEADER_TOO_SMALL			>
		inc	cx		; round up to nearest word
		and	cx, 0xfffe
		mov	si, cx		; si <- header size
		add	cx, dx
		add	cx, dx		; allocate one word per entry
		call	LMemAlloc	; ax <- new chunk
		jc	done
		
	; Initialize the header
		mov	ss:[tableChunk], ax
		mov_tr	di, ax
		mov	di, ds:[di]
		mov	ds:[di].HTH_flags, bx
		mov	ds:[di].HTH_tableSize, dx
		movdw	ds:[di].HTH_hashFunction, hashFn, ax
		movdw	ds:[di].HTH_compFunction, compFn, ax
		mov	ds:[di].HTH_headerSize, si

	; Initialize the rest of the chunk
		segmov	es, ds, ax
		add	di, size HashTableHeader		

	; Zero out the rest of the header, if there is any
		mov_tr	cx, si		; cx <- header size
		sub	cx, size HashTableHeader
		jz	initHeads

		shr	cx		; convert to words
		clr	ax
		rep	stosw
		
	; Set all the list heads to MH_NULL_ELEMENT
	; es:di points just past the header and is word aligned
initHeads:
		mov	ax, MH_NULL_ELEMENT
		mov	cx, dx		; cx <- # list heads (word apiece)
		rep	stosw		

	; allocate the "heap" chunk
allocHeap::
CheckHack <offset HTF_ENTRY_SIZE eq 0>
CheckHack <width HTF_ENTRY_SIZE le 8>
		mov	ax, ss:[objChunkFlags]
		mov	cx, bx		; cx <- flags
		and	cx, mask HTF_ENTRY_SIZE
		add	cx, size HashTableEntry
		call	MiniHeapCreate
		jc	cleanUp

		mov_tr	cx, ax		; cx <- new chunk
		mov	si, ss:[tableChunk]
		mov	ax, si		; ax <- index chunk
		mov	si, ds:[si]
		mov	ds:[si].HTH_heap, cx
if ERROR_CHECK
		push	si
		mov	si, ax		; *ds:si <- table
		call	ECCheckHashTable
		pop	si
endif
		clc

done:
	.leave
	ret

	; need to return with error after cleaning up chunks...
cleanUp:
		mov	ax, ss:[tableChunk]
		call	LMemFree
		stc
		jmp	done
		
HashTableCreate	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashTableLookup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up an entry in the hash table

CALLED BY:	GLOBAL
PASS:		*ds:si	- Hash table
		ax	- hash value of the item you're looking up
		cxdx	- passed to callback routine
RETURN:		carry	- set if not found
		cxdx	- data from the entry
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	C stub HASHTABLELOOKUP directly calls HT_LookupLow, so don't
	mess with this routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashTableLookup	proc	far
		push	bx
		clr	bx		; don't delete, just look up
		call	HT_LookupLow
		pop	bx
	ret
HashTableLookup	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashTableRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove an element from the hash table

CALLED BY:	GLOBAL
PASS:		*ds:si	- hash table
		ax	- hash value of the item you're removing
		cxdx	- passed to callback routine
RETURN:		carry	- set if not found
		cxdx	- data from the entry
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	C stub HASHTABLEREMOVE directly calls HT_LookupLow, so don't
	mess with this routine.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashTableRemove	proc	far
		push	bx
		mov	bx, 1		; lookup and delete
		call	HT_LookupLow
		pop	bx
	ret
HashTableRemove	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HT_LookupLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up an entry in the hash table

CALLED BY:	EXTERNAL
		HashTableLookup, HashTableRemove, HASHTABLELOOKUP,
		HASHTABLEREMOVE
PASS:		*ds:si	- Hash table
		ax	- hash value of the item you're looking up
		bx	- non zero to delete the item found
		cxdx	- passed to callback routine
RETURN:		carry	- set if not found
		cxdx	- data from the entry
DESTROYED:	bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Take ax % <table size> as the chain to search.

	Look through the chain for a match.  The high byte of the
	hash value is compared with the stored byte in each element,
	to reduce the number of calls to the callback comparison routine.

	(note that the high byte was picked because it is less likely to
	be related to ax % <table size>)

	Handle deletions by keeping a pointer to the previous "link" field
	around -- this conveniently handles both the case where we are
	deleting the first element in a chain (in which case the pointer
	will be somewhere in the index chunk) and otherwise (pointer will
	point to a HTE_link field in some chunklet).

	When we delete, we just massage the data on the other end of that
	pointer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HT_LookupLow	proc	far
	remove	local	word			push	bx
	index	local	nptr.HashTableHeader
	uses	ax,si,di
	.enter

EC <		call	ECCheckHashTable				>

		mov	si, ds:[si]	; ds:si <- index
		mov	ss:[index], si
		mov	bx, ds:[si].HTH_tableSize

	; get the chain # into bx
	;
		push	dx, ax
		clr	dx
EC <		tst	bx						>
EC <		ERROR_Z	-1						>
		div	bx		; dx <- chain #
		mov	bx, dx
		pop	dx, ax

	; Get the first chunklet in the chain into bx
	; We can bail out quick here if it turns out the chain is empty
	; Keep a pointer to the previous link field around, in case we
	; need to perform a delete.
	;
		shl	bx
		add	bx, ds:[si].HTH_headerSize
		lea	di, ds:[si+bx]
		mov	bx, ds:[di]

		cmp	bx, MH_NULL_ELEMENT
		je	fail
		
	; Loop over elements in the chain
	; ds:[si+bx] - chunklet
	; ds:di - prev link field
	; ax - hash value
	; cxdx - callback data
	;
		mov	si, ds:[si].HTH_heap
		mov	si, ds:[si]	; ds:si <- mini heap
EC <		call	ECCheckMiniHeap					>
compLoop:
EC <		call	ECCheckUsedChunklet				>
		cmp	ds:[si+bx].HTE_keyBits, ah
		je	cl_slowCheck
cl_next:
		lea	di, ds:[si+bx].HTE_link
		mov	bx, ds:[di]
		cmp	bx, MH_NULL_ELEMENT
		jne	compLoop
		jmp	fail
cl_slowCheck:
		call	HT_SlowCheck
		jnc	success
		jmp	cl_next

	; It is OK if we read garbage bytes (ie, the table is storing
	; < 4 bytes/entry) since the value of the unused portions of cxdx
	; is undefined.  It's also more time/effort/space efficient to do
	; this than to make yet another jump table...
success:
PrintMessage <Note: read checking turned off here>
.norcheck
		mov	dx, {word}ds:[si+bx].HTE_data
		mov	cx, {word}ds:[si+bx].HTE_data[2]
		tst	ss:[remove]
		jnz	removeIt
noRemove:
		clc

done:
	.leave
	ret

removeIt:
	; Fix up previous link field to point to chunklet after this one,
	; then set the chunklet free
	;
		memmov	ds:[di], ds:[si+bx].HTE_link, ax
		mov	si, ss:[index]
		mov	si, ds:[si].HTH_heap
		call	MHFree
		jmp	noRemove
fail:
		stc
		jmp	done
HT_LookupLow	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HT_SlowCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if a chunklet really matches by calling the
		comparison callback routine
CALLED BY:	INTERNAL
		HT_LookupLow
PASS:		ds:si	- mini heap
		bx	- chunklet
		cxdx	- data to pass to callback
		stack	- inherited frame
RETURN:		carry	- set if not equal
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Deal with callbacks written in C and assembly.  This relies
	on the HTF_C_API_CALLBACKS flag in the hash table header.

	Assembly callback:
	Pass:	axbx	- data from hash table entry
		cxdx	- data from caller
	Return:	carry	- set if not equal

	C callback:
	Boolean cb(dword callbackData, dword elementData)
	Returns true if equal
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HT_SlowCheck	proc	near
	uses	ax,bx,cx,dx,di
	.enter inherit HT_LookupLow
		mov	di, ss:[index]	; ds:di <- index chunk
		test	ds:[di].HTH_flags, mask HTF_C_API_CALLBACKS
		jnz	pascalCall

	; see comment by HT_LookupLow::success for an explanation
PrintMessage <Note: read checking turned off here>
.norcheck
		memmov	ss:[TPD_dataBX], {word}ds:[si+bx].HTE_data, ax
		memmov	ss:[TPD_dataAX], {word}ds:[si+bx].HTE_data[2], ax
		movdw	bxax, ds:[di].HTH_compFunction
		call	ProcCallFixedOrMovable
done:
	.leave
	ret

pascalCall:
	; luser's callbacks written in C, use PROCCALLFIXEDORMOVABLE_PASCAL
	;
		push	ds

	; arg 1: callbackData
		pushdw	cxdx

	; arg 2: elementData
		pushdw	({dword}ds:[si+bx].HTE_data)

	; arg 3: void *header
		pushdw	dsdi

	; arg n: routine to call
;;		pushdw	ds:[di].HTH_compFunction
		push	ds:[di].HTH_compFunction.segment
		push	ds:[di].HTH_compFunction.offset

		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	ds		; in case it called GEODELOADDGROUP
;;		rcr	ax		; but what if low bit isn't set?
		tst_clc	ax
		jnz	done
		stc
		jmp	done		

HT_SlowCheck	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashTableAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an entry

CALLED BY:	GLOBAL
PASS:		*ds:si	- Hash table
		bx	- ds from C stub, undefined otherwise
		cxdx	- data to copy (see notes below)
RETURN:		*ds:si	- Hash table (block possibly moved)
		carry	- set on error
DESTROYED:	nothing
SIDE EFFECTS:	
	LMem block might be resized.

PSEUDO CODE/STRATEGY:

	Use a jump table to copy the right # of bytes.

	Bytes are written little-endian style, which means that the least
	significant bytes of cxdx are used first.  If only two bytes are
	being stored in each entry, cx is ignored.  If three bytes, ch
	is ignored.

Hash function should be:
	Pass:	cxdx	- data
	Return:	ax	-  16 bits of hash
	May Destroy cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashTableAdd	proc	far

dataCX	local	word	push	cx
dataDX	local	word	push	dx		
table	local	lptr	push	si
	uses	ax, bx, di
	.enter

EC <		call	ECCheckHashTable				>

		mov	di, ds:[si]

	; Check to see whether it already exists in the chain
	; Do this in EC even if HTF_NO_REPEAT_INSERT is set, so
	; we can fatal error if assumtion isn't met.
	;
		call	HT_HashData	; bx <- entry #, ax <- hash
		mov	cx, ss:[dataCX]
		mov	dx, ss:[dataDX]

if ERROR_CHECK
		call	HT_CheckChain
		jc	addIt
		test	ds:[di].HTH_flags, mask HTF_NO_REPEAT_INSERT
		ERROR_NZ HASH_TABLE_DUPLICATE_ENTRY
		stc
		jmp	done
else
		test	ds:[di].HTH_flags, mask HTF_NO_REPEAT_INSERT
		jz	addIt
		call	HT_CheckChain
		cmc			; invert sense -- stc means found
		jc	done		; already exists, so punt
endif
		
CheckHack <offset HTF_ENTRY_SIZE eq 0>
addIt:
		shl	bx
		add	bx, ds:[di].HTH_headerSize
		mov_tr	cx, bx		; ds:[di+cx] <- offset to chain head

	; Alloc chunklet and fill in
		mov	si, ds:[di].HTH_heap
		mov	di, ds:[di].HTH_flags
		call	MHAlloc		; can shuffle heap
		mov	dx, bx		; dx <- chunklet
		add	bx, ds:[si]	; ds:bx <- chunklet (pointer)

		and	di, mask HTF_ENTRY_SIZE
		shl	di		; cs:[copyTable][di] <- function to use
		mov	ds:[bx].HTE_keyBits, ah
		call	cs:[copyTable][di]

	; Stick it on the head of the chain
		mov	si, ss:[table]
		mov	di, ds:[si]
		add	di, cx		; ds:di <- head of chain
		memmov	ds:[bx].HTE_link, ds:[di], ax
		mov	ds:[di], dx	; store new chunklet offset
done:
		mov	cx, ss:[dataCX]
		mov	dx, ss:[dataDX]
	.leave
	ret

copyTable	nptr	0, copy1, copy2, copy3, copy4

copy1:
		memmov	{byte}ds:[bx].HTE_data[0], dataDX.low, al
		retn
copy3:
		memmov	{byte}ds:[bx].HTE_data[2], dataCX.low, al
		memmov	{word}ds:[bx].HTE_data[0], dataDX, ax
		retn
copy4:
		memmov	{word}ds:[bx].HTE_data[2], dataCX, ax
copy2:
		memmov	{word}ds:[bx].HTE_data[0], dataDX, ax
		retn

HashTableAdd	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HT_CheckChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a chain to see if it contains an element

CALLED BY:	INTERNAL
		HashTableAdd
PASS:		ds:di	- Hash Table
		bx	- chain #
		cxdx	- data (or cl, cx, cxdl)
RETURN:		carry	- set on failure (not found)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HT_CheckChain	proc	near
	uses	bx, si, di
	.enter

	; get chain head into bx
;; XXX new
		shl	bx
		add	bx, ds:[di].HTH_headerSize
		mov	bx, ds:[di+bx]
		mov	si, ds:[di].HTH_heap
		mov	si, ds:[si]		; ds:si <- mini heap

		mov	di, ds:[di].HTH_flags
		and	di, mask HTF_ENTRY_SIZE
		shl	di
		mov	di, cs:[cmpTable][di]	; di <- "function" to use

		cmp	bx, MH_NULL_ELEMENT
		je	notFound

checkLoop:
		jmp	di
afterCmp:
		je	found
		mov	bx, ds:[si+bx].HTE_link
		cmp	bx, MH_NULL_ELEMENT
		jne	checkLoop

notFound:
		stc
done:
	.leave
	ret

cmpTable	nptr	0, cmp1, cmp2, cmp3, cmp4

found:
		clc
		jmp	done

cmp1:
		cmp	{byte} ds:[si+bx].HTE_data, dl
		jmp	afterCmp
cmp3:
		cmp	{word} ds:[si+bx].HTE_data, dx
		jne	afterCmp
		cmp	{byte} ds:[si+bx].HTE_data[2], cl
		jmp	afterCmp

cmp4:
		cmp	{word} ds:[si+bx].HTE_data[2], cx
		jne	afterCmp
cmp2:
		cmp	{word} ds:[si+bx].HTE_data, dx
		jmp	afterCmp

HT_CheckChain	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HT_HashData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the hash function and return the full hash value and
		the corresponding hash chain.

CALLED BY:	INTERNAL
		HashTableAdd
PASS:		ds:di	- Hash table
		cxdx	- data
RETURN:		ax	- 16-bit hash value
		bx	- entry # of chain
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	NOTE: assumes hash function doesn't shuffle chunks.

	For now, assumes that it is C function's responsibility to
	load dgroup

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HT_HashData	proc	near
		test	ds:[di].HTH_flags, mask HTF_C_API_CALLBACKS
		jnz	pascalCall

		movdw	bxax, ds:[di].HTH_hashFunction
		call	ProcCallFixedOrMovable	;ax <- hash (destroy bxcxdx)
afterCall:
		Destroy	cx, dx
		push	ax		; save hash value
		clr	dx
		mov	bx, ds:[di].HTH_tableSize
EC <		tst	bx						>
EC <		ERROR_Z	-1						>
		div	bx		; dx <- remainder
		mov	bx, dx		; bx <- remainder
		pop	ax		; restore hash value
		ret

pascalCall:
		push	ds
	; arg 1: elementData
		pushdw	cxdx

	; arg 2: void *header
		pushdw	dsdi
		
	; arg n: routine to call
		pushdw	ds:[di].HTH_hashFunction
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	ds
		jmp	afterCall
		
HT_HashData	endp

MainCode	ends
