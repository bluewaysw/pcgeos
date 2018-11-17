COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		CSV/Shared
FILE:		sharedCache.asm

AUTHOR:		Andrew Wilson, Jun 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	OutputCacheAttach	Attach an output cache to the passed file
	OutputCacheWrite	Write data to the cache.
	OutputCacheFlush	Flush out the current contents of the cache
	OutputCacheDestroy	Nuke the cache (NOTE: This does not flush
				the cache -- this should already have been
				done)
	InputCacheAttach	Attach an input cache to the passed file
	InputCacheGetChar	Read data from the cache
	InputCacheUnGetChar	Un-read a byte from the cache (can not be 
				called twice in a row).
	InputCacheDestroy	Detach an input cache from the passed file

REVISION HISTORY:

DESCRIPTION:
	This file contains code to implement code that buffers up writes to
	a file and writes them out a cluster at a time.

	$Id: sharedCache.asm,v 1.1 97/04/07 11:42:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDiskClusterSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the cluster size of the disk on which the passed file
		resides.

CALLED BY:	GLOBAL
PASS:		bx - file handle
RETURN:		nada
DESTROYED:	es, dx, cx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAX_CACHE_SIZE	equ	3000		;Max # chars we buffer up before
					; flushing it do disk.

GetDiskClusterSize	proc	near	uses	bp
	volumeInfo	local	DiskInfoStruct
	.enter

;	GET CLUSTER SIZE, WHICH WE WILL USE AS THE # BYTES OF DATA WE WILL
;	CACHE BEFORE WRITING OUT TO DISK

	call	FileGetDiskHandle	;
	segmov	es, ss			;
	lea	di, volumeInfo		;ES:DI <- ptr to dest for
					; DiskInfoStruct
	call	DiskGetVolumeInfo	;AX <- sectors per cluster
EC <	ERROR_C	-1							>
	mov	ax, volumeInfo.DIS_blockSize
					;blockSize = MIN(MAX_CACHE_SIZE, AX)
					;	   + size OutputCacheInfoBlock
	cmp	ax, MAX_CACHE_SIZE	;
	jb	save			;
	mov	ax, MAX_CACHE_SIZE
save:
	.leave
	ret
GetDiskClusterSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateCacheBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine allocates a cache block with the passed # extra
		bytes at the beginning.

CALLED BY:	GLOBAL
PASS:		ax - # extra bytes to alloc
		bx - file handle to attach cache to
RETURN:		bx - cache block handle
		es - ptr to block
		carry set if memory error (ax = -1)
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocateCacheBlock	proc	near	uses	ax, cx, dx, bp, di
	extraBytes	local	word
	fileHan		local	hptr
	.enter	
	mov	extraBytes,ax

	mov	fileHan, bx		;
	call	GetDiskClusterSize	;AX <- cluster size

;	ALLOCATE THE CACHE BUFFER

	add	ax, extraBytes		;
	mov	dx, ax			;DX <- blockSize
	mov	cx, ALLOC_DYNAMIC_LOCK	;
	call	MemAlloc		;BX <- cache handle, AX <- segment
	jc	exit			;Exit if we couldn't allocate memory

;	SETUP CACHE BUFFER INFO

	mov	es, ax
	mov	es:[CIB_size], dx	;Save cluster size
	mov	dx, fileHan		;Save associated file handle
	mov	es:[CIB_file], dx
	mov	dx, extraBytes
	mov	es:[CIB_offset], dx	;Save offset
exit:
	.leave
	ret
AllocateCacheBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputCacheAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attaches a cache that buffers up writes to a file.

CALLED BY:	GLOBAL
PASS:		bx - file to attach cache to
RETURN:		bx - cache handle to pass to cache routines
		carry set if couldn't allocate cache
DESTROYED:	es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputCacheAttach	proc	far
	.enter
	mov	ax, size OutputCacheInfoBlock	;
	call	AllocateCacheBlock
	.leave
	ret
OutputCacheAttach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputCacheWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This code writes the data to/through the cache.

CALLED BY:	GLOBAL
PASS:		bx - cache handle
		cx - number of bytes to write
		ds:dx - buffer from which to write

RETURN:		carry set if error
			ax - FileErrors (or unchanged if no error)
		
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputCacheWrite	proc	far	uses	es, cx, si, di
	.enter
	push	ax					
	call	MemDerefES

EC <	tst	es:[CIB_file]						>
EC <	ERROR_Z	OUTPUT_CACHE_ROUTINE_CALLED_AFTER_ERROR_RETURNED	>

cacheLoopTop:
	jcxz	noErrorExit			;Exit if no bytes left to
						; flush.
	mov	ax, es:[CIB_size]
	sub	ax, es:[CIB_offset]		;AX <- # bytes that can be
						; copied into cache before it
						; overflows
EC <	ERROR_BE CACHE_OFFSET_EXCEEDS_SIZE				>

	cmp	ax, cx				;
	jbe	nonSimple			;Branch if data won't fit or
						; if it fits exactly

;	SIMPLE CASE - DATA TO WRITE OUT FITS ENTIRELY IN CACHE, SO JUST COPY
;	IT IN.

	mov	si, dx				;DS:SI <- source
	mov	di, es:[CIB_offset]		;ES:DI <- dest
	shr	cx, 1
	jnc	10$
	movsb	
10$:
	rep	movsw				;Copy data into cache
	mov	es:[CIB_offset], di
EC <	cmp	di, es:[CIB_size]		;Whine if cache full	>
EC <	ERROR_AE	CACHE_OFFSET_EXCEEDS_SIZE			>
noErrorExit:
	pop	ax
	clc
exit:
	.leave
	ret

nonSimple:

;	THE DATA WE ARE WRITING OUT WILL FILL THE CACHE, SO FILL THE CACHE,
;	FLUSH THE CACHE, AND BRANCH BACK UP.

	xchg	ax, cx				;AX <- total # bytes to write
						; out
						;CX <- # bytes to add to cache
	sub	ax, cx				;AX <- # bytes left to write 

;	COPY BYTES FROM SOURCE TO FILL CACHE BUFFER

	mov	si, dx				;DS:SI <- source
	mov	di, es:[CIB_offset]		;ES:DI <- dest
	shr	cx, 1
	jnc	20$
	movsb
20$:
	rep	movsw
	xchg	cx, ax				;CX <- # bytes left to write
	call	OutputCacheFlush			;Flush cache
	jnc	cacheLoopTop
	add	sp, size word
	stc
	jmp	exit				;Exit if error flushing cache
OutputCacheWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputCacheFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine flushes the current cache data out to disk

CALLED BY:	GLOBAL
PASS:		bx - cache handle
RETURN:		carry set if error
		AX <- unchanged if no error
		      FileErrors if error
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputCacheFlush	proc	far	uses	ds, bx, cx, dx
	.enter
	call	MemDerefDS
	mov	bx, ds:[CIB_file]
EC <	tst	bx							>
EC <	ERROR_Z	OUTPUT_CACHE_ROUTINE_CALLED_AFTER_ERROR_RETURNED	>
	mov	cx, ds:[CIB_offset]
	sub	cx, size OutputCacheInfoBlock	;CX <- # bytes to write
	clc
	jcxz	exit				;Exit if no data to write
	push	ax
	clr	al
	mov	dx, offset OCIB_data		;DS:DX <- data to write out
	call	FileWrite
	mov	ds:[CIB_offset], size OutputCacheInfoBlock
	pop	bx
EC <	jnc	10$							>
EC <	clr	ds:[CIB_file]						>
EC <10$:								>
	jc	exit
	mov_tr	ax, bx				;Restore old value of AX if
						; no error
exit:
	.leave
	ret
OutputCacheFlush	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputCacheDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the passed cache.

CALLED BY:	GLOBAL
PASS:		bx - cache to destroy
RETURN:		nada
DESTROYED:	nothing (flags preserved)
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputCacheDestroy	proc	far
	pushf	
if	ERROR_CHECK
	push	es
	call	MemDerefES
	tst	es:[CIB_file]	;Skip check if destroying after error
	jz	10$		; returned.
	cmp	es:[CIB_offset], size OutputCacheInfoBlock
	ERROR_NZ CACHE_NOT_FLUSHED
10$:
	pop	es
endif
	call	MemFree
	popf
	ret
OutputCacheDestroy	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputCacheAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attaches a cache that buffers up writes to a file.

CALLED BY:	GLOBAL
PASS:		bx - file to attach cache to
RETURN:		bx - cache handle to pass to cache routines
		carry set if couldn't allocate cache
DESTROYED:	es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputCacheAttach	proc	far
	.enter
	mov	ax, size InputCacheInfoBlock
	call	AllocateCacheBlock
	jc	exit
	mov	es:[ICIB_EOF],0		;
	mov	ax, es:[CIB_size]	;
	mov	es:[CIB_offset], ax	;
exit:
	.leave
	ret
InputCacheAttach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputCacheGetChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine gets a character from the cached file

CALLED BY:	GLOBAL
PASS:		bx - handle of cache block
RETURN:		al - next byte from file (or EOF)
		 - or -
		carry set if error (ax = file error) 
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputCacheGetChar	proc	far		uses	es, cx, di
	.enter
	call	MemDerefES
getByte:
	mov	di, es:[CIB_offset]	;
	cmp	di, es:[CIB_size]	;Check to see if at end of cached block
					; (need to read more from file)
	je	readFromFile		;Branch if so
EC <	ERROR_A	READ_BEYOND_CACHE_END					>
	inc	es:[CIB_offset]		;Bump offset to next character
	mov	al, es:[di]		;
	clc				;Return no error
exit:
	.leave
	ret

readFromFile:
	mov	al, EOF			;
	tst	es:[ICIB_EOF]		;At end of file?
	stc				;
	jnz	exit			;Exit with EOF character if so...

;	READ THE NEXT CLUSTER_SIZE BYTES FROM THE FILE

	push	bx, ds, dx
	clr	al
	mov	cx, es:[CIB_size]
	sub	cx, size InputCacheInfoBlock	;CX <- # bytes to read
	mov	bx, es:[CIB_file]		;BX <- file to read from
	segmov	ds, es
	mov	dx, size InputCacheInfoBlock	;DS:DX <- ptr to put data
	call	FileRead
	pop	bx, ds, dx;
	mov	es:[CIB_offset], size InputCacheInfoBlock
	jnc	getByte				;No errors - get byte from
						; cache.
	add	cx, size InputCacheInfoBlock	;
	mov	es:[CIB_size], cx		;
	mov	es:[ICIB_EOF], TRUE		;
	cmp	ax, ERROR_SHORT_READ_WRITE	;If we have read to end of
						; file, branch
	je	getByte				;
	stc					;Else, some kind of disk error

;	Any more reads from this cache will result in a FatalError
EC <	mov	es:[CIB_offset], -1					>

	jmp	exit
InputCacheGetChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputCacheUnGetChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine modifies the cache information so the last char
		read via InputCacheGetChar will be returned on the *next* 
		call to InputCacheGetChar, as if it had never been called in
		the first place

CALLED BY:	GLOBAL
PASS:		bx <- input cache handle
RETURN:		nada
DESTROYED:	nada (flags preserved)
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/15/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputCacheUnGetChar	proc	far	uses	es
	.enter
	pushf
	call	MemDerefES
EC <	push	ax							>
EC <	mov	ax, es:[CIB_offset]					>
EC <	cmp	ax, es:[CIB_size]					>   
EC <	ERROR_A	READ_BEYOND_CACHE_END					>
EC <	pop	ax							>
	dec	es:[CIB_offset]
EC <	cmp	es:[CIB_offset], size InputCacheInfoBlock		>
EC <	ERROR_B	CANNOT_UNGET_CHAR_FROM_PREVIOUS_BLOCK			>
	popf
	.leave
	ret
InputCacheUnGetChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputCacheDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the passed cache.

CALLED BY:	GLOBAL
PASS:		bx - cache to destroy
RETURN:		nada
DESTROYED:	nothing (flags preserved)
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputCacheDestroy	proc	far
	pushf	
	call	MemFree
	popf
	ret
InputCacheDestroy	endp

CommonCode	ends
