COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright Geoworks 1996.  All rights reserved.
			GEOWORKS CONFIDENTIAL

PROJECT:	Hash table module.	
MODULE:		
FILE:		initfileHash.asm

AUTHOR:		Jim Wood, Nov  8, 1996

ROUTINES:
	Name			Description
	----			-----------
 ?? INT InitFileInitHashTable	Create the hash table used to speed up ini
				reads and writes.

 ?? INT HashProcessIniFile	Process one ini file.

 ?? INT HashAddPrimaryEntry	Hash a new category for the primary init
				file

 ?? INT HashAddEntry		Add an entry to the table.

 ?? INT HashCheckForCollision	See if the category already in this element
				is different than the one we're hashing.

 ?? INT HashDealWithCollision	Deal with a collision when building the
				table.

 ?? INT HashHashCat		Get the hash value for the passed category
				string.

 ?? INT HashGetNextCat		Find the next category in the ini file.

 ?? INT HashCreateTable		Create the chunk array for the table.

 ?? INT HashFindCategory	Locates the given category.

 ?? INT HashRemoveCategory	Remove the hash entry for a category

 ?? INT HashUpdateTblPtrs	update all the chunk array element pointers
				located after the element just deleted.

 ?? INT HashFindCategoryLow	Locates the given category.

 ?? INT HashUpdateHashTable	Update all of the hash table entries
				located after the current pointer into the
				file.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/ 8/96   	Initial revision


DESCRIPTION:
		
	

	$Id: initfileHash.asm,v 1.1 97/04/05 01:18:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HASH_INIFILE
InitfileRead	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileInitHashTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the hash table used to speed up ini reads and writes.

CALLED BY:	InitGeos

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileInitHashTable	proc	far
		
		uses	ax,bx,cx,dx,si,di,bp, ds, es
		.enter inherit 
	;
	; Grab the ini file sem and get dgroup  ( ds <- dgroup ).
	;
		call	LoadVarSegDS_PInitFile
		segmov	es, ds			; es <- dgroup
	;
	; Allocate a block for the table.
	;
		call	HashCreateTable		;bx <- blk, *ds:si <- array
		mov	es:[hashTableBlkHandle], bx
		mov	es:[hashTableChunkHandle], si
	;
	; Process each ini file.
	;
		clr	di			; init file counter
iniFileLoop:
	;
	; Get the next ini block handle.
	;
		mov	bx, es:[loaderVars][di].KLV_initFileBufHan
		tst	bx
		jz	cleanUp
	;
	; Process the file, then set up for getting next ini blk handle.
	;
		clr	ax			; start at begining of file
		call	HashProcessIniFile
		add	di, size hptr
		cmp	di, (MAX_INI_FILES* size hptr)
		jb	iniFileLoop
cleanUp:
		mov	bx, es:[hashTableBlkHandle]
		call	MemUnlock
		
		segmov	ds, es			; ds <- dgroup
		call	VInitFile		
		
		.leave
		ret
InitFileInitHashTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashProcessIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process one ini file.

CALLED BY:	InitFileInitHashTable

PASS:		^hbx	= ini file block handle
		*ds:si	= hash table chunk array
		es	= dgroup		
		di	= Offset into the KLV_initFileBufHan
			  variable.   We use it as an offset into
			  any hash table entry we deal with as each element
		  	  can have ptrs into different ini buffers.  See
 			  initfileVariable.def and the definition of
			  InitFileHashEntry for more details.   	  

		ax	= offset into the ini buffer where we want to start
			  processing. so that *(^hbx:ax) is where we should
			  start. This is 0 when building and something else
		    	  if we're writting something out.

RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashProcessIniFile	proc	near

	; !!! MUST BE IDENTICAL to local vars in HashAddPrimaryEntry
		tableSeg		local	sptr	push	ds
		tableHandle		local	hptr	push	si
		iniFileBlkHan		local	hptr	push	bx
		iniFileBlkHanOffset	local	word	push	di
		iniFileBufferOffset	local	word	push	ax
		ForceRef	tableSeg
		ForceRef	tableHandle
		ForceRef	iniFileBlkHan
		ForceRef	iniFileBlkHanOffset
		uses	ax,bx,cx,dx,si,di,bp, ds
		.enter 
	
	;
	; Lock the ini file block and save the segment.
	;
		call	MemLock			; ax <- seg of ini file
		mov	ds, ax
		mov	es:[initFileBufSegAddr], ax
		mov	si, ss:[iniFileBufferOffset] ; ds:si <- ini file start
						; 
processNextCategory:
	;
	; Get the next cat string from the ini file, hash it, then add
	; the entry to the table.  Loop.
	;
		call	HashGetNextCat		; ds:si <- category string
		jc	done
		
		call	HashHashCat		; dx <- table location
		call	HashAddEntry
		jmp	processNextCategory
done:
		call	MemUnlock		
		.leave
		ret
HashProcessIniFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashAddPrimaryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hash a new category for the primary init file

CALLED BY:	CreateCategory
PASS:		cx	- near pointer to new category
		es	- dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/16/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashAddPrimaryEntry	proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds
	; !!! MUST BE IDENTICAL to local vars in HashProcessIniFile
		tableSeg		local	sptr
		tableHandle		local	hptr
		iniFileBlkHan		local	hptr
		iniFileBlkHanOffset	local	word
		iniFileBufferOffset	local	word
		ForceRef	iniFileBlkHan
		ForceRef	iniFileBufferOffset
		uses	ax,bx,cx,dx,si,di,bp, ds
		.enter
	;
	; we only write to the primary init file, which is offset 0
	;
		clr	ss:[iniFileBlkHanOffset]
	;
	; get the hash block
	;
		mov	bx, es:[hashTableBlkHandle]
		mov	si, es:[hashTableChunkHandle]
		call	MemLock
		mov	ss:[tableSeg], ax
		mov	ss:[tableHandle], si
	;
	; hash the category
	;
		mov	ds, es:[initFileBufSegAddr]
		mov	si, cx			; ds:si = category
		call	HashHashCat		; dx <- table location
		call	HashAddEntry
		
		.leave
		ret
HashAddPrimaryEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashAddEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an entry to the table.

CALLED BY:	HashProcessIniFile

PASS:		bp	= stackframe from HashProcessIniFile
			tableSeg
			tableHandle
			initFileBlkHanOffset
		si	= nptr to category string in ini file
		dx	= table position
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashAddEntry	proc	near
		uses	ax,bx,cx,dx,si,di,bp, ds
		.enter inherit HashProcessIniFile
EC <		Assert	le dx, INITFILE_HASH_TABLE_SIZE			>
EC <		Assert	stackFrame bp					>
	;
	; Get the table in ds:si
	;
		mov	cx, si			; cx <- nptr to category
		mov	ax, ss:[tableSeg]
		mov	ds, ax
		mov	si, ss:[tableHandle]	; *ds:si chunk array
	;
	; Load up the table entry.  dx is the table entry number.
	;
		mov	si, ds:[si]		; ds:si <- header
		add	si, offset IFHTH_table	; ds:si <- table
		shl	dx			; convert index to word sized
		add	si, dx			; ds:si <- entry location
	;
	; See if we already have an element.
	;
		tst	{word}ds:[si]
		jnz	elementExists
	;
	; No element here yet.  Create one and stick it in the table.
	;
	;	mov	bx, si
		mov	si, ss:[tableHandle]	; *ds:si <- chunk array 
		call	ChunkArrayAppend	; di <- offset of element
		segmov	tableSeg, ds, ax
		sub	di, ds:[si]		; make offset relative to chunk
	; ChunkArrayAppend might have caused the lmem block to move, so
	; calculate the offset again
		mov	bx, ds:[si]
		add	bx, offset IFHTH_table
		add	bx, dx
	 	mov	ds:[bx], di		; store offset in hash table
		add	di, ds:[si]		; ds:di = new IFHE
		jmp	haveElement
elementExists:
	;
	; See if this is a collision or just a duplicate category in a
	; different ini file.
	;
		mov	di, ds:[si]		; ds:di <- offset in chunk
		mov	ax, di			; save offset
		mov	si, ss:[tableHandle]
		add	di, ds:[si]		; ds:di = existing IFHE
		call	HashCheckForCollision		
		jz	haveElement
	;
	; Deal with the collision.
	; pass in the offset of the elem in chunk instead of absolute address
	; because the lmem block might move, which will result in a bogus
	; address
		
		call	HashDealWithCollision
		jmp	finish
haveElement:
	;
	; Element is in ds:di.  
	;
		mov	bx, ss:[iniFileBlkHanOffset]
	; if this a catPtr already exists it's because the ini file has two
	; entries for the same category. We ignore all but the first entry.
		tst	ds:[di][bx].IFHE_catPtrs
		jnz	finish
		mov	ds:[di][bx].IFHE_catPtrs, cx		
finish:		
		.leave
		ret
		
HashAddEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashCheckForCollision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the category already in this element is different
		than the one we're hashing.

CALLED BY:	HashAddEntry

PASS:		ds:di	= existing element we collided with
		es	= dgroup
		cx	= nptr to category we're hashing relative to the
			  segment in initFileBufSegAddr in dgroup
RETURN:		z flag set if no collision.  This means that target string
		equals the existing element string.
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashCheckForCollision	proc	near
		uses	ax, bx, cx, dx, ds, es, si, di
		.enter

	;
 	; Get a hold of a ptr to a category within this existing element.
	;
		clr	bx
catLoop:
		mov	ax, ds:[di][bx].IFHE_catPtrs
		tst	ax
		jnz	foundCat

		add	bx, size hptr
		cmp	bx, (MAX_INI_FILES* size hptr)
		jb	catLoop
	;
	; If we reach this point, it means that all the pointers
	; were null, so why does this entry even exist?  In NEC,
	; just ignore this entry.
	;
EC <		ERROR	INIT_FILE_CORRUPT_HASH_TABLE			>
NEC <		inc	bx				; clear z flag	>
NEC <		jmp	done						>
	;
	; We found a pointer to the category label.  See if this
	; is the desired category.
	;
foundCat:		
		mov	si, ax
		mov	bx, es:[loaderVars][bx].KLV_initFileBufHan
		call	MemLock
		mov	ds, ax				; ds:si <- file str

		mov	di, cx				
		mov	cx, es:[catStrLen]		; length
		mov	es, es:[initFileBufSegAddr]	; es:di <- hash str

		repe	cmpsb		
NEC < done:								>
		call	MemUnlock

		
		.leave
		ret
HashCheckForCollision	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashDealWithCollision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a collision when building the table.

CALLED BY:	HashAddEntry

PASS:		ds:di	= the existing element we collided with
		ax	= offset of element in chunk
		cx	= nptr to target category relative to current ini blk
		es	= dgroup
		*ds:si	= the hash table chunk		
RETURN:		nothing
DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashDealWithCollision	proc	near
		uses	ax,bx,cx,dx,si,di,bp, ds, es
		.enter	inherit HashProcessIniFile
	;
	; Get to the end of the chain.
	;
		mov	bx, ss:[iniFileBlkHanOffset]
findEndLoop:
		tst	ds:[di].IFHE_next
		jz	atEnd

		mov	di, ds:[di].IFHE_next	; offset from start of chunk
		add	di, ds:[si]		; ds:di = next IFHE
		call	HashCheckForCollision
		jnz 	findEndLoop
	;
	; We don't want to clobber an exisiting entry
	;
		tst	ds:[di][bx].IFHE_catPtrs
		jnz	done
		mov	ds:[di][bx].IFHE_catPtrs, cx
		jmp	done		
atEnd:
		call	ChunkArrayAppend	; ds:di <- element
		segmov	tableSeg, ds, dx
	;
	; Set up the element.
	;
		mov	ds:[di][bx].IFHE_catPtrs, cx
		sub	di, ds:[si]		; convert to chunk-relative
	;
	; the lmem block may have moved due to the ChunkArrayAppend, so the
	; position of the existing IFHE might have moved, so we calculate it
	; again
	;
		mov	si, ss:[tableHandle]
		add	ax, ds:[si]
		mov_tr	bx, ax
		mov	ds:[bx].IFHE_next, di
done:
		.leave
		ret
HashDealWithCollision	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashHashCat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the hash value for the passed category string.

CALLED BY:	ini Hash routines

PASS:		ds:si 	= string to hash
RETURN:		dx	= value
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/ 8/96    	Initial version
	hash code from adam 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashHashCat	proc	near
		uses	ax,bx,cx,si,di,bp
		.enter

		clr	bx, dx
		mov	cl, 5
		clr	ah
charLoop:		
		lodsb
	;
	; When building the table ']' signals the end of a string.  When
	; reading and such the strings are ASCIIZ...
	;
		cmp	al, ']'		; end of cat string?
		je	done		; yes		

		tst	al
		jz	done
	;
	; Skip this if it's a space.
	;
		cmp	al, ' '
		je	charLoop
	;
	; Downsize this if it's a cap. but let non-letters slip through.
	;
		cmp	al, 'z'
		ja	ready
		cmp	al, 'a'
		jb	ready
		sub	al, 'a'-'A'
ready:
	;
	; Multiply existing value by 33
	; 
		movdw	dibp, bxdx	; save current value for add
		rol	dx, cl		; *32, saving high 5 bits in low ones
		shl	bx, cl		; *32, making room for high 5 bits of
					;  dx
		mov	ch, dl
		andnf	ch, 0x1f	; ch <- high 5 bits of dx
		andnf	dl, not 0x1f	; nuke saved high 5 bits
		or	bl, ch		; shift high 5 bits into bx
		adddw	bxdx, dibp	; *32+1 = *33
	;
	; Add current character into the value.
	; 
		add	dx, ax
		adc	bx, 0
		jmp	charLoop
done:
	; nifty steveK business to speed this up.

		mov	ax, dx
		mov	dx, bx		; dxax <- value
divideLoop:
		cmpdw	dxax, 65536*INITFILE_HASH_TABLE_SIZE
		jb	finishUp

		subdw	dxax, 65536*INITFILE_HASH_TABLE_SIZE
		jmp	divideLoop
finishUp:
		mov	bx, INITFILE_HASH_TABLE_SIZE
		div	bx
finished::		
		.leave
	ret
HashHashCat	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashGetNextCat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next category in the ini file.

CALLED BY:	InitFileInitHashTable

PASS:		ds:si	= ptr to ini buffer
RETURN:		ds:si	= ptr to category, just after '[' delimeter
		catStrLen in dgoup set to the length of this category string.
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashGetNextCat	proc	near
		uses	ax,bx,cx,dx,di,bp
		.enter 
	;
	; We simply parse through the file looking for a '['.
	;
		mov	ah, '['			; marks category
findLoop:
		lodsb
		cmp	al, MSDOS_TEXT_FILE_EOF
		je	eof

		cmp	al, '\\'
		je	escapedChar

		cmp	al, INIT_FILE_COMMENT
		je	commentChar

afterComment:
		cmp	ah, al
		jne	findLoop

		push	es
		segmov	es, ds
		mov	di, si			; es:di <- ptr to cat
		mov	cx, MAX_INITFILE_CATEGORY_LENGTH 
		mov	al, ']'			; check for this
		repne	scasb
		dec	di			; move back to ]
		sub	di, si			; di <- the length
EC <		Assert  le di, MAX_INITFILE_CATEGORY_LENGTH		>
		pop	es
		mov	es:[catStrLen], di		
		clc
exit:
		.leave
		ret
eof:
		stc				; return EOF found
		jmp	exit

escapedChar:					; Escaped char hit...
		lodsb				; read past escaped char
		cmp	al, MSDOS_TEXT_FILE_EOF
		je	eof
		jmp	findLoop		; & continue w/NEXT char

commentChar:					; Comment char hit...
		lodsb				; read through EOLN,
		cmp	al, MSDOS_TEXT_FILE_EOF
		je	eof
		
		cmp	al, '\n'
		jne	commentChar

		jmp	short afterComment	; continue with EOLN itself

HashGetNextCat	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashCreateTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the chunk array for the table.
	
CALLED BY:	InitFileInitHashTable

PASS:		nothing
RETURN:		bx	= block handle of table chunk array (LOCKED!)
		*ds:si	= chunk array, ready to party

	
DESTROYED:	nothing
NOTES:
		The structure of the table is this.  The chunk array header
		contains the 271 possible hash buckets.  Each one of these
		entries is either NULL or a chunk array element number.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/ 8/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashCreateTable	proc	near

		uses	ax,cx,dx,di,bp
		
		.enter
	;
	; Create the block.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx
		call	MemAllocLMem
		push	bx			; save heap handle
	;
	; Make the thing sharable.
	;
		clr	ah			; clear no flags
		mov	al, mask HF_SHARABLE
		call	MemModifyFlags

	;
	; Make the chunk array.  ChunkArrayCreate zeros things out for us.
	;
		call	MemLock			; ax <- segment
		mov	ds, ax			; block for the new array
		mov	bx, size InitFileHashEntry	; bx <- elem size
		mov	cx, size InitFileHashTableHeader
						; cx <- header size
		clr	ax, si			; si = create a chunk handle
						; al = ObjChunkFlags
		call	ChunkArrayCreate	; *ds:si <- array
		pop	bx			; recover heap handle


		.leave
		ret
HashCreateTable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashFindCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locates the given category.

CALLED BY:	FindCategory for now.

PASS:		es, bp - dgroup
		dgroup:[catStrAddr] - category ASCIIZ string
		dgroup:[catStrOffset]
		dgroup:[catStrLen]
		dgroup:[currentIniOffset]

RETURN:		IF CATEGORY FOUND:
			CARRY CLEAR
		    	dgroup:[initFileBufPos] - offset from
				BufAddr to character after ']'
		ELSE
			CARRY SET
			initFileBufPos - unchanged

DESTROYED:	nothing	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashFindCategory	proc	near
		uses	bx, dx, si, di, ds
		.enter
	;
	; Hash the string to get the table location.
	;
		lds	si, es:[catStrAddr]	;ds:si <- string to hash
		call	HashHashCat		; dx <- table location
	;
	; Search for the category
	;
		call	HashFindCategoryLow
	;
	; Unlock the hash table
	;
		mov	bx, es:[hashTableBlkHandle]
		call	MemUnlock
		.leave
		ret
HashFindCategory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashRemoveCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the hash entry for a category

CALLED BY:	InitFileDeleteCategory
PASS:		es, bp	- dgroup
		dgroup:[catStrAddr] - category ASCIIZ string
		dgroup:[catStrOffset]
		dgroup:[catStrLen]
		dgroup:[currentIniOffset]
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EW	12/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashRemoveCategory	proc	far
		uses	ax, bx, cx, dx, si, di, bp, ds
		.enter
	;
	; Hash the string to get the table location.
	;
		lds	si, es:[catStrAddr]	;ds:si <- string to hash
		call	HashHashCat		; dx <- table location
	;
	; Search for the category
	;
		call	HashFindCategoryLow	; ds:di = IFHE
EC <		ERROR_C INIT_FILE_CORRUPT_HASH_TABLE			>
	;
	; Remove the pointer to the first init file
	;
		clr	{word}ds:[di].IFHE_catPtrs
	;
	; See if this category is in any other file
	;
		CheckHack <MAX_INI_FILES gt 1>
		mov	bx, 2*(MAX_INI_FILES-1)
check:
		tst_clc	ds:[di].IFHE_catPtrs[bx]
		jnz	cleanup
		dec	bx
		dec	bx
		jnz	check
	;
	; There are no other references, so we need to deallocate this
	; chunk array entry.  We start by checking to see if this entry
	; is referenced directly by the hash table.
	;
		mov	si, es:[hashTableChunkHandle]
		mov	si, ds:[si]			; ds:si <- header
	 	mov	bx, si				; bx = chunk base
		add	si, offset IFHTH_table
		shl	dx				; convert to word
		add	si, dx				; ds:si <- tableloc
		sub	di, bx				; di = relative offset
	;
	; walk down the linked list until we find the pointer to the
	; selected entry
	;
docmp:
		cmp	di, ds:[si]
		je	found
		mov	si, ds:[si]	; offset relative to chunk
EC <		tst	si						>
EC <		ERROR_Z INIT_FILE_CORRUPT_HASH_TABLE			>
		add	si, bx	; actual offset
		add	si, offset IFHE_next
		jmp	docmp
	;
	; make the entry which points to the deleted entry point to the
	; entry following the deleted entry, or null
	;
found:
		add	di, bx
	 	segmov	ds:[si], ds:[di].IFHE_next, ax
	;
	; remove the actual element
	; 
		mov	cx, di
		mov	si, es:[hashTableChunkHandle]
		call	ChunkArrayDelete
	; does ds:di point to the same element, if not this means that we
	; deleted the last element in the chunk array, so we needn't update teh
	; hash table
		cmp	cx, di
		jne	cleanup
		sub	di, bx				; restore relative ptr
	;
	; all elements after this one just moved up, so we need to update
	; pointers to them in the hash table
	;
		call	HashUpdateTblPtrs
	;
	; Unlock the hash table
	;
cleanup:
		mov	bx, es:[hashTableBlkHandle]
		call	MemUnlock
		.leave
		ret
HashRemoveCategory	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashUpdateTblPtrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update all the chunk array element pointers located after
		the element just deleted.

CALLED BY:	HashRemoveCategory	
PASS:		es	- dgroup
		ds:di	- reletive ptr to chunk array element
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		loop through the entire hash table
			if chunkPtr > di
			   chunkPtr -= size InitFileHashEntry
		loop through all elements in chunkarray
			if IFHTH_next > di
			   IFHTH_next -= size InitFileHashEntry

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	mjoy    	3/ 6/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashUpdateTblPtrs	proc	near
		uses	si, bx, cx
		.enter
		mov	si, es:[hashTableChunkHandle]	; ds:si - header
		mov	si, ds:[si]			; si - chunk base
		add	si, offset IFHTH_table	; ds:si<- table
		mov	bx, 2*INITFILE_HASH_TABLE_SIZE
updateHash:						; ds:[si][bx]=hash slot
		sub	bx, 2
		jb	hashDone			; no more slots
		cmp	ds:[si][bx], di			; do we need to shift?
	 	jb	updateHash
		sub	{word}ds:[si][bx], size InitFileHashEntry
		jmp	updateHash
hashDone:
	;  
	;  similarly, we need to update all the IFHE_next pointers
	; 
	 	sub	si, offset IFHTH_table
	    	mov	cx, ds:[si].CAH_count
		add	si, ds:[si].CAH_offset
		sub	si, size InitFileHashEntry
updateNext:
		add	si, size InitFileHashEntry
		jcxz	done
		dec	cx
		cmp	ds:[si].IFHE_next, di
	 	jb	updateNext
		sub	ds:[si].IFHE_next, size InitFileHashEntry
		jmp	updateNext
done:
		.leave
		ret
HashUpdateTblPtrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashFindCategoryLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locates the given category.

CALLED BY:	HashFindCategory, HashRemoveCategory

PASS:		es, bp - dgroup
		dx     - hash value
		dgroup:[catStrAddr] - category ASCIIZ string
		dgroup:[catStrOffset]
		dgroup:[catStrLen]
		dgroup:[currentIniOffset]

RETURN:		IF CATEGORY FOUND:
			CARRY CLEAR
		    	dgroup:[initFileBufPos] - offset from
				BufAddr to character after ']'
			ds:di	- InitFileHashEntry (hash table block locked)
		ELSE
			CARRY SET
			initFileBufPos - unchanged
			hash table block locked

DESTROYED:	nothing	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashFindCategoryLow	proc	far

		uses	ax,bx,cx,dx,si,bp
		.enter
	;
	; Lock down the chunk array block.
	;
		mov 	bx, es:[hashTableBlkHandle]
		call	MemLock
		mov	ds, ax
		mov	bx, es:[hashTableChunkHandle]	; *ds:si table
	;
	; Get the element chunk handle from the table.
	;
		mov	si, ds:[bx]			; ds:si <- header
		add	si, offset IFHTH_table
		shl	dx				; convert to word
		add	si, dx				; ds:si <- tableloc
		tst	{word}ds:[si]
		jz	fail
	;
	; An element exists.  Get the element and check the nptr in the
	; appropriate spot.
	;
		mov	di, ds:[si]			; di <-offset in chunk
scanElement:
	;
	; all the pointers in the table are relative to the chunk, so we need
	; to add in the chunk's base address to get a real pointer
	;
		add	di, ds:[bx]			; ds:di <- IFHE
	;
	; currentIniOffset is the offset to the ini blk handle in kvars.
	; Again, we use it to know which catPtr to look at.
	;
		push	bx
		mov	bx, es:[currentIniOffset]	 
		mov	cx, ds:[di][bx].IFHE_catPtrs	
		pop	bx
	; if cx is zero it could mean that there is not entry for that cat in
	; the current ini file. But there could still be some value in
	; IFHT_next
		
		jcxz	setUpForRetry
	;
	; We have an nptr.  See if it actually matches the category string.
	;
		pushdw	dsdi				; save element
		mov	es:[initFileBufPos], cx
		lds	si, es:[catStrAddr]		; ds:si cat string
		call	CmpString
		jc	popAndRetry
		call	GetChar
		jc	error
		
;		cmp	al, ']'
;		jne	huh?

		mov	ax, es:[initFileBufPos]
		mov	es:[curCatOffset], ax
		popdw	dsdi
		clc
		jmp	exit
popAndRetry:
		popdw	dsdi
		
setUpForRetry:
	;
	; Get the next element and try again.
	;
		tst	ds:[di].IFHE_next
		jz	fail
		
		mov	di, ds:[di].IFHE_next
		jmp	scanElement
		
fail:
		stc
		
exit:
	;
	; LEAVE HASH BLOCK LOCKED
	;
		.leave
		ret

error:
		popdw	dsdi
		GOTO	CorruptedIniFileError
HashFindCategoryLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashUpdateHashTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update all of the hash table entries located after the current
		pointer into the file.

CALLED BY:	InitFileWrite

PASS:		es - dgroup
		dgroup:[initFileBufPos] - offset from buffer to insertion loc
			(new data will start at this location)
		cx - amount of space added (negative if space removed)
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimw	11/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashUpdateHashTable	proc	far
		uses	ax, bx, cx, si, di, ds
		.enter
	;
	; get a pointer to the table
	;
		mov	bx, es:[hashTableBlkHandle]
		mov	si, es:[hashTableChunkHandle]
		call	MemLock
		mov	ds, ax
	;
	; set up for loop
	;
		mov	ax, cx				; ax = adjustment
		mov	di, ds:[si]			; ds:di = array
		mov	cx, ds:[di].CAH_count		; cx = # of elements
		add	di, ds:[di].CAH_offset		; ds:di = 1st element
		
		mov	si, es:[initFileBufPos]
		sub	di, size InitFileHashEntry
		CheckHack <offset IFHE_catPtrs eq 0>
	;
	; main loop:
	;  ds:di = <some element>.IFHE_catPtrs[0]
	;  cx    = # of remaining elements
	;  si    = offset at which to start adjusting
	;  ax    = amount by which to adjust
	;
top:
		add	di, size InitFileHashEntry	; goto next entry
		jcxz	done
		dec	cx
		cmp	si, ds:[di]			; past insert point?
		ja	top				; branch if not
		add	ds:[di], ax			; adjust the offset
		jmp	top
done:
		call	MemUnlock
		.leave
		ret
HashUpdateHashTable	endp


InitfileRead	ends

endif	; HASH_INIFILE
