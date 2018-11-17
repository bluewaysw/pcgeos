COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Database
MODULE:		DBCommon		
FILE:		dbCommonUtil.asm

AUTHOR:		Ted H. Kim, 9/14/92

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
	GetMappedRowAndColNumber	
				Re-orders source fields
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	9/92		Initial revision

DESCRIPTION:
	This file contains all common utility routines for database libraries.

	$Id: dbCommonUtil.asm,v 1.1 97/04/07 11:43:21 newdeal Exp $

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
MAX_CACHE_SIZE	equ	3000		;Max # bytes we buffer up before
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

DBCS <	shl	ax, 1			;make space for DBCS import >

	add	ax, extraBytes		;
	mov	dx, ax			;DX <- blockSize
	mov	cx, ALLOC_DYNAMIC_LOCK	;
	call	MemAlloc		;BX <- cache handle, AX <- segment
	jc	exit			;Exit if we couldn't allocate memory

;	SETUP CACHE BUFFER INFO

	mov	es, ax
	mov	es:[CIB_size], dx	;Save cluster size
DBCS <	mov	es:[CIB_maxSize], dx	;Save cluster size		>
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
		cx - number of chars to write
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

DBCS <	; Convert # of Chars to # of bytes at first			>
DBCS <	shl	cx				;cx <- # bytes to output>

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
DBCS <EC ; In DBCS # of bytes should be even		>>
DBCS <EC <	ERROR_C	CACHE_WRITE_BLOCK_IS_NOT_EVEN	>>
SBCS <	jnc	10$					>
SBCS <	movsb						>
SBCS <10$:						>
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
	add     es:[CIB_offset], cx		;update CIF_offset

	shr	cx, 1
DBCS <EC ; In DBCS # of bytes should be even		>>
DBCS <EC <	ERROR_C	CACHE_WRITE_BLOCK_IS_NOT_EVEN	>>
SBCS <	jnc	20$					>
SBCS <	movsb						>
SBCS <20$:						>
	rep	movsw

	mov	dx, si				;DS:DX <- updated source
	xchg	cx, ax				;CX <- # bytes left to write
DBCS <	shr	cx;				;CX <- # chars left >

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
OutputCacheFlush	proc	far	uses	ds, bx, cx, dx, si
	.enter
	call	MemDerefDS
	mov	bx, ds:[CIB_file]
EC <	tst	bx							>
EC <	ERROR_Z	OUTPUT_CACHE_ROUTINE_CALLED_AFTER_ERROR_RETURNED	>

	mov	cx, ds:[CIB_offset]
	sub	cx, size OutputCacheInfoBlock	;CX <- # bytes to write

if DBCS_PCGEOS
	push	si, di, ax, es, bx

	shr	cx				;cx <- # chars to convert
EC <	ERROR_C	CACHE_WRITE_BLOCK_IS_NOT_EVEN ; cx should be even	>
	segmov	es, ds, si
	mov     di, size OutputCacheInfoBlock	;es:di <- ptr to dest (DOS)
	mov	si, di				;ds:si <- ptr to src (GEOS)

	mov	ax, C_PERIOD			;default character
	clr	dx				;use primary FSD
	mov	bx, CODE_PAGE_SJIS		;only support SJIS
	call	LocalGeosToDos			;convert Unicode to SJIS

	pop	si, di, ax, es, bx
if 0 ;Koji. Why???
	dec	cx				;cx <- # bytes to write
endif
endif
	clc
	jcxz	exit				;Exit if no data to write
	push	ax
	mov	ax, C_NULL			;default character
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
RETURN:		SBCS	al - next char from file (or EOF)
		DBCS	ax - next char from file (or EOF)
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
InputCacheGetChar	proc	far		uses	es, cx, di, si
	.enter
	call	MemDerefES
getChar:
	mov	di, es:[CIB_offset]	;
	cmp	di, es:[CIB_size]	;Check to see if at end of cached block
					; (need to read more from file)
	je	readFromFile		;Branch if so
EC <	ERROR_A	READ_BEYOND_CACHE_END					>
	inc	es:[CIB_offset]		;Bump offset to next character
DBCS <	inc	es:[CIB_offset]		;Bump offset to next character	>

	LocalGetChar	ax, esdi, noAdvance
	clc				;Return no error
exit:
	.leave
	ret

readFromFile:
	LocalLoadChar	ax, EOF		;
	tst	es:[ICIB_EOF]		;At end of file?
	stc				;
	jnz	exit			;Exit with EOF character if so...

;	READ THE NEXT CLUSTER_SIZE BYTES FROM THE FILE

	push	bx, ds, dx
SBCS <	clr	al							>
SBCS <	mov	cx, es:[CIB_size]					>
SBCS <	sub	cx, size InputCacheInfoBlock	;CX <- # bytes to read	>
SBCS <	mov	bx, es:[CIB_file]		;BX <- file to read from>
SBCS <	segmov	ds, es							>
SBCS <	mov     dx, size InputCacheInfoBlock    ;DS:DX <- ptr to put data>

	; read data into buffer block
DBCS <	mov	cx, es:[CIB_maxSize]					>
DBCS <	sub	cx, size InputCacheInfoBlock	;CX <- # bytes to read *2 >
DBCS <	shr	cx				;cx <- # bytes to read	>
DBCS <	mov	dx, size InputCacheInfoBlock	;			>
DBCS <	add	dx, cx				;ds:dx <- ptr to put data>
DBCS <	segmov	ds, es, ax			;			>
DBCS <	clr	al				;FileRead flag		>
DBCS <	mov	bx, es:[CIB_file]		;BX <- file to read from>

	call	FileRead

DBCS <	pushf					; save FileRead flags	>
DBCS <	call	ConvertInputCache		; convert dos to geos	>
DBCS <	jc	readError			; something is wrong!	>
DBCS <	popf							>

	pop	bx, ds, dx;
DBCS <	pushf					; save FileRead flags	>
	mov     es:[CIB_offset], size InputCacheInfoBlock
SBCS <	jnc	getChar				;No errors - get a char from>
						; cache.
DBCS <	shl	cx				;cx <- size of text	>
	add	cx, size InputCacheInfoBlock	;
	mov	es:[CIB_size], cx		;

DBCS <	popf					; restore flags>
DBCS <	jnc	getChar				; get a char from cache	>

	mov	es:[ICIB_EOF], TRUE		;
	cmp	ax, ERROR_SHORT_READ_WRITE	;If we have read to end of
						; file, branch
	je	getChar				;
DBCS <readError:							>
DBCS <	popf					;clean stuck up		>
DBCS <	pop	bx, ds, dx			;			>
	stc					;Else, some kind of disk error

;	Any more reads from this cache will result in a FatalError
EC <	mov	es:[CIB_offset], -1					>

	jmp	exit
InputCacheGetChar	endp


if DBCS_PCGEOS
;;;
;;; PASS	ds:dx	= ptr from which data is read
;;;		es	= ds (ptr to Cache block)
;;;		bx	= file handle
;;;	carry set if error:
;;;		ax	= ERROR_SHORT_READ_WRITE (hit end-of-file)
;;;			  ERROR_ACCESS_DENIED (file not opened for reading)
;;;	carry clear if no error:
;;;		ax	= destroyed
;;;		cx	= number of bytes read
;;; RETURN	es:[size InputCacheInfoBlock] <- Unicode data
;;;		cx	= # of chars (including null)
;;;
;;;
ConvertInputCache	proc	near
	uses	ax, bx, si, di, bp
	.enter

	mov	bp, bx				; save file handle
	jnc	readOK				; FileRead returns OK?
						; If so, convert buffer
	cmp	ax, ERROR_SHORT_READ_WRITE	; Is short read?
	jne	done				; If so, never mind :)
						;  otherwise return w/ carry
readOK:
	mov	di, size InputCacheInfoBlock	; es:di <- ptr to dest (GEOS)
	mov	si, dx				; ds:si <- ptr to src (DOS)
	mov	ax, C_PERIOD			; default character
	clr	dx				; use primary FSD
	mov	bx, CODE_PAGE_SJIS		; only support SJIS
	call	LocalDosToGeos			; convert SJIS to Unicode

	jnc	done				; if no carry, great!

	cmp	al, DTGSS_CHARACTER_INCOMPLETE	; split character?
	jne	done				;  branch if not
	push	cx				; save # of chars

	clrdw	cxdx
	mov	dl, ah
	negdw	cxdx				; # of bytes to backup

	mov	bx, bp				; restore file handle
	mov	al, FILE_POS_RELATIVE		; al <- FilePosMode
	call	FilePos
	pop	cx
done:
	.leave
	ret
ConvertInputCache	endp
endif


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
DBCS <	dec	es:[CIB_offset]						>
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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMappedRowAndColNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rearrange the transfer file according to the map list block. 

CALLED BY:	(GLOBAL)

PASS:		ax - column number to be mapped
		bx - handle of map block
		cl - ImpexFlag

RETURN:		if the field is mapped,
			carry set
			ax = mapped column number

		if the field is not mapped,
			carry clear

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMappedRowAndColNumber	proc	far	uses	bx, cx, dx, ds, si, di
	mapBlock	local	hptr
	colNumber	local	word
	impexFlag	local	byte
	.enter

	; grab the number of output fields from map list block

	mov	colNumber, ax			; save column number to map
	mov	mapBlock, bx			; save handle map list block
	mov	impexFlag, cl			; save impexFlag
	tst	bx				; no map list block?
	je	mapped				; if not, use default mapping
	call	MemLock				; lock this block
	mov	ds, ax
	clr	di				; ds:di - header
	mov	cx, ds:[di].MLBH_numDestFields	; cx - # of output fields
	mov	si, ds:[di].MLBH_chunk1		; si - chunk handle

	; now sort the chunk array based on CML_dest field

	push	si
	mov	cx, cs				; cx:dx - callback routine
	mov	dx, offset CallBack_CompareDestFields
	call	ChunkArraySort			; sort the array
	pop	si

	; find the chunk array entry whose source map field
	; matches the column number of current cell data

	mov	cx, colNumber
	mov     bx, cs				; bx:di - callback routine
	
	test	impexFlag, mask IF_IMPORT	; file import? 
	je	import				; if not, skip
	mov     di, offset CallBack_FindMapEntryImport
	jmp	common
import:
	mov     di, offset CallBack_FindMapEntryExport
common:
	call    ChunkArrayEnum
	jnc	quit				; skip if not mapped
mapped:
	stc					; field is being mapped
quit:
	pushf

	; unlock the map block and exit

	mov	bx, mapBlock			; bx - handle map list block
	tst	bx				
	je	exit				
	call	MemUnlock		
exit:
	popf

	.leave
	ret
GetMappedRowAndColNumber	endp

CallBack_CompareDestFields	proc	far
	mov	ax, ds:[si].CML_dest		; ax - first element
	cmp	ax, es:[di].CML_dest		; compare 1st element to 2nd
	ret
CallBack_CompareDestFields	endp

CallBack_FindMapEntryImport	proc	far
	cmp	cx, ds:[di].CML_source		; source field match?
	clc					; assume no match
	jne	exit				; if not found, continue... 
	mov	ax, ds:[di].CML_dest		; return dest. field number
	stc					; return with carry set
exit:
	ret
CallBack_FindMapEntryImport	endp

CallBack_FindMapEntryExport	proc	far
	cmp	cx, ds:[di].CML_dest		; destination field match?
	clc					; assume no match
	jne	exit				; if not found, continue... 
	mov	ax, ds:[di].CML_source		; return source field number
	stc					; return with carry set
exit:
	ret
CallBack_FindMapEntryExport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultFieldName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the default field name into the FieldInfoBlock

CALLED BY:	(INTERNAL) CreateFieldInfoBlock

PASS:		dx - column number
		cx - limit on the length of field name
		es:di - ptr to copy the field name into

RETURN:		es - not changed

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	THK	11/92		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultFieldName	proc	far	uses	ax, bx, cx, dx, ds, si, di
	.enter

	; lock the resource block with the default field name

	push	es, di
	push	cx
	inc	dx
        mov	bx, handle Strings

	call    MemLock			        
	mov     es, ax                          ; set up the segment
	mov     di, offset DefaultFieldName     ; handle of error messages
	mov     di, es:[di]                     ; dereference the handle

	; now search for the 1st space character in this string

	push	di				; es:di - beg of string
	mov	cx, -1
	LocalLoadChar	ax, ' '			; character to search for
	LocalFindChar				; search for ' '

	; convert the field number to ascii string

	mov	ax, dx				; ax - number to convert
	call	ConvertWordToAscii		; covnert the number to ascii

	; copy the field name into FieldInfoBlock

	pop	si
	segmov	ds, es				; ds:si - source string
	sub	di, si
	mov	cx, di				; cx - # of bytes to copy

DBCS <EC <	push	cx					>
DBCS <EC <	shr	cx			; to see if cx is odd/even>
DBCS <EC <	ERROR_C	0			; if odd, then error>
DBCS <EC <	pop	cx					>

	; check to see if the string is too long

	pop	dx				; maximum field name length
	cmp	cx, dx				; is field name too long?
	jle	ok				; if not, skip
	mov	cx, dx				; if so, copy only the maximum

DBCS <EC <	push	cx					>
DBCS <EC <	shr	cx			; to see if cx is odd/even>
DBCS <EC <	ERROR_C	0			; if odd, then error>
DBCS <EC <	pop	cx					>

ok:
	pop	es, di				; es:di - destination
	rep	movsb				; copy the string
	LocalClrChar	es:[di]			; null terminate the string
	call	MemUnlock			; unlock the resource block

	.leave
	ret
GetDefaultFieldName	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ConvertWordToAscii

DESCRIPTION:	Converts a hex number into a non-terminated ASCII string.
		If a 0 is passed, a '0' will be stored.

CALLED BY:	INTERNAL ()

PASS:		ax - number to convert
		es:di - location to store ASCII chars

RETURN:		es:di - addr past last char converted

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	WARNING: Maximum number of ASCII chars returned will be 4.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

ConvertWordToAscii	proc	near	uses	bx,cx,dx
	.enter

	; first clear the space with space characters 

	push	ax, di			; save the pointer
	LocalClrChar	ax		; 
	LocalPutChar	esdi, ax	; why 4 times?
	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax
	LocalPutChar	esdi, ax
	pop	ax, di			; restore the pointer

	clr	cx			; init count
	mov	bx, 10			; divide the number by 10

convLoop:
	clr	dx
	div	bx			; ax <- quotient, dx <- remainder
	push	dx			; save digit
	inc	cx			; inc count
	cmp	cx, 4			; max # of bytes?
	je	storeLoop		; if so, exit
	tst	ax			; done?
	jnz	convLoop		; loop while not

storeLoop:
	pop	ax			; retrieve digit
	add	ax, '0'			; convert to ASCII
	LocalPutChar	esdi, ax	; save it
	loop	storeLoop

	.leave
	ret
ConvertWordToAscii	endp

CommonCode	ends
