COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Compress -- Compress
FILE:		compressMain.asm

AUTHOR:		David Loftesness, April 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dl      04/26/92        Initial revision.

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: compressMain.asm,v 1.1 97/04/04 17:49:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Entry Point for this Library

CALLED BY:	Internal
PASS:		
RETURN:		carry set for error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Need to alloc a semaphore if we're attaching, free it otherwise.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DL	4/27/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	CompressLibraryEntry:far
CompressLibraryEntry		proc	far
	uses	bx
	.enter
	;
	; Check if we're attaching or detaching
	;
	segmov	ds, dgroup, bx
	cmp	di, LCT_DETACH		; adios
	je	deallocSemaphore
	cmp	di, LCT_ATTACH		; hola
	jne	CLE_done

	mov	bx, 1
	call	ThreadAllocSem		; returns bx = handle of sem.
	mov	ds:[DecompSem], bx
	mov	ax, handle 0		; Make sure we own it and not
	call	HandleModifyOwner	; the attaching thread.

	jmp	CLE_done

deallocSemaphore:
	mov	bx, ds:[DecompSem]
	call	ThreadFreeSem
	
CLE_done:
	clc				;Signal no error.
	.leave
	ret
CompressLibraryEntry		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		COMPRESSDECOMPRESS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compresses or Decompresses some stuff

CALLED BY:	those wacky app writers
PASS (on stack):		

RETURN:		AX 	= # of bytes written out (0 if error)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		*P semaphore
		*Check out args to see where source and dest are
		*Set flags so ReadData and WriteData know what to do
		*Call Explode
		*Return

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		* Only one client can be decompressing or compressing
		at once.  EXPLODE/IMPLODE dictate this.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DL	1/14/93		Initial version
	ATW	1/25/93		Fixed lots of bugs, changed to have C interface

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
COMPRESSDECOMPRESS		proc	far	flags:CompLibFlags,
						sourceFileHan:hptr,
						sourceBuffer:fptr,
						sourceBufferSize:word,
						destFileHan:word,
						destBuffer:fptr	
		uses	bx, cx, dx, bp es, ds, si, di
		.enter
	;
	; P the semaphore
	;
	mov	bx, segment dgroup
	mov	ds, bx
	mov	es, bx
	clr	es:[BytesWritten]
	mov	bx, es:[DecompSem]
	call	ThreadPSem		; block away!
						; ax <- semaphore error
	;
	; Store the args n such
	;		Redundant code here, but checking which case
	;		would take almost as much time, eh?
	mov	cx, flags
	mov	es:[CurFlags], cx
	movdw	es:[SourceBuffer], sourceBuffer, ax
	movdw	es:[DestBuffer], destBuffer, ax
	mov	ax, sourceFileHan
	mov	es:[SourceFile], ax
	mov	ax, destFileHan
	mov	es:[DestFile], ax
	mov	ax, sourceBufferSize
	mov	es:[BytesTotal], ax
	
	; Set up args to pkware library call
	;
	;
	; Allocate the buffers
	;
	mov	ax, PK_DECOMPRESS_BUFFER
	test	cx, mask CLF_DECOMPRESS
	jnz	alloc_block
	mov	ax, PK_COMPRESS_BUFFER
alloc_block:
	mov	cx, ALLOC_DYNAMIC_LOCK
	or	ch, HAF_ZERO_INIT

	call	MemAlloc
	mov	cx, 0
	jc	errorVSem

	push	bx			;Save handle of block

	mov	cx, offset ReadData
	pushdw	cscx			; = CompressCode
	mov	cx, offset WriteData
	pushdw	cscx

	push	ax			; seg of buffer
	clr	ax
	push	ax			; zero offset
	;
	; if cl indicates compress, push some more args here
	;

	mov	ax, PK_CMP_BINARY
	test	es:[CurFlags], mask CLF_MOSTLY_ASCII
	jz	10$
	mov	ax, PK_CMP_ASCII
10$:
	mov	es:[CompressType], ax

	test	es:[CurFlags], mask CLF_DECOMPRESS
	jnz	cl_explode

	;
	; Push pointer to compression type
	;
	mov	ax, offset CompressType
	pushdw	esax

	;
	; Push pointer to Dictionary Size
	;
	mov	es:[DictionarySize], PK_DICT_SIZE
	mov	ax, offset DictionarySize
	pushdw	esax

	;
	; pick the right routine to call
	;
	call	IMPLODE
	jmp	cl_cleanup
cl_explode:
	call	EXPLODE
cl_cleanup:

EC <	cmp	ax, PKZE_NO_ERROR					>
EC <	je	noError							>
EC <	cmp	ax, PKZE_ABORT						>
EC <	ERROR_NZ	COMPRESS_ERROR					>
EC <noError:								>


	;
	; Free that data block
	;
	pop	bx
	call	MemFree

	;
	; V that semaphore
	;
vSem:
	push	ax			;Save error code
	segmov	es, dgroup, ax
	mov	bx, es:[DecompSem]
	call	ThreadVSem
	pop	ax			;Restore error code
	tst	ax			;If error, exit with error
	jnz	error

	mov	ax, es:[BytesWritten]

EC <	tst	ax							>
EC <	ERROR_Z	-1							>
exit:
	.leave
	ret
error:
	clr	ax
	jmp	exit

errorVSem:
	mov	ax, -1			;Signal error
	jmp	vSem
COMPRESSDECOMPRESS		endp
