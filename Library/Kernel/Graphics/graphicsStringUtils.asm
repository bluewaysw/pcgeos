COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel Library
FILE:		graphicsStringUtils.asm

AUTHOR:		Jim DeFrisco, 13 October 1989

ROUTINES:
		Name			Description
		----			-----------
	    GBL	DestroyString		Kill a graphics string
	    GBL	SetStringPos		Set current pos in a graphics string

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	2/90		Initial revision


DESCRIPTION:
		This file contains some of the support routines for the
		graphics string capability in the kernel.
		
	$Id: graphicsStringUtils.asm,v 1.1 97/04/05 01:13:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a new graphics string handle and structure

CALLED BY:	INTERNAL

PASS:		bx	- handle to file or memory buffer where string is
			- set to 0 for paths (this GString block is used)
		si	- if cl == GST_CHUNK, this is chunk handle
						(or zero to alloc a chunk)
			  if cl == GST_VMEM, this is a vmem block handle
						(or zero to alloc a huge array)
		cl	- GStringType enum: (actually GSflags)
			      GST_CHUNK	- writing to a memory chunk
			      GST_STREAM	- writing to a stream
			      GST_VMEM		- writing to a vmem block
			      GST_PTR		- accessing a static ptr gs
			      GST_PATH		- creating a path
		ch	- CreateGStringControl record.  Bits for:
				CSGC_WRITING	     - internal flg, for writes

RETURN:		di	- graphics state handle
		ax	- gstring handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		allocate/init gstring handle;
		allocate/init gstring structure block;
		allocate a chunk for a file buffer;
		allocate a chunk for a substring relocation buffer;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/89		Initial version
		jim	2/90		moved over from kernel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocGString	proc	far
		uses	bx, cx, dx, bp, ds, es
		.enter

		; Save some of the passed parameters

EC <		cmp	cl, GStringType	; check passed type	>
EC <		ERROR_AE GRAPHICS_INVALID_GSTRING_TYPE		>
		push	cx			; save read/write flag
		push	bx			; save file/mem handle

		; allocate space for the gstring structure. do the InitLMem
		; thing.

		mov	cx, INIT_GSTRING_FLAGS	; allocation flags
		mov	ax, INIT_GSTRING_SIZE	; allocate to initial size
		call	MemAllocFar		; get a block, init to 0s
		mov	ds, ax			; set up ptr to gstring block

		; ds -> structure, initialize it.

		mov	ax, LMEM_TYPE_GSTRING	; indicate type of block
		mov	dx, size GString	; offset to start of lmem part
		mov	cx, 2			; just a few handles
		push	si, di
		mov	si, 16			; allocate a few bytes more
		clr	di
		clr	bp
		call	LMemInitHeap		; set up lmem header
		pop	si, di
		clr	cx			; allocate a file buffer chunk
		pop	ds:[GSS_hString]	; save block/file handle
		mov	ds:[GSS_firstBlock], si	;    and save it
		mov	ds:[GSS_curPos].high, cx ; init current position
		mov	ds:[GSS_curPos].low, cx
		call	LMemAlloc		;  in case we need it.
		mov	ds:[GSS_fileBuffer], ax	; store file buffer chunk han
		call	LMemAlloc		;  in case we need it.
		mov	ds:[GSS_readBuffer], ax	; store file buffer chunk han
		mov	ds:[GSS_readBytesAvail], cx

		; test string buffer to see if it's a file or a memory
		; block.

		pop	cx			; restore flags
		mov	ds:[GSS_flags], cx	;  in gstring block as well

		; do whatever specific initialization is required

		mov	bx, cx
		clr	bh
		shl	bx
		shl	bx
		mov	ax, cs:initRoutines[bx].offset
		mov	bx, cs:initRoutines[bx].segment
		call	ProcCallFixedOrMovable	; call specific init routine

		; all done with initialization, unlock gstring block

		mov	si, ds:[GSS_firstBlock]	; return block handle
		mov	bx, ds:[GSS_header].LMBH_handle	; get han to GS struct
		call	MemUnlock		; unlock the block

		; allocate a gstate to go along with the gstring
		; and stuff the gstring handle in there

		xchg	cx, bx			; cx = gs handle, bx = gs type
		cmp	bl, GST_PATH		; writing to a path ?
		je	done			; if paths, don't create GState
		clr	di			; no window
		call	GrCreateState		; alloc a default gstate
		mov	bx, di			; bx = gstate handle
		call	MemLock			; lock it down
		mov	ds, ax			; ds -> gstate
		mov	ds:[GS_gstring], cx	; store gstring handle
		call	MemUnlock		; unlock the gstate
done:
		mov	ax, cx			; return gstring handle in ax
		.leave
		ret

AllocGString	endp

initRoutines	fptr	\
		InitMemGString,
		InitStreamGString,
		InitVMemGString,
		InitPtrGString,
		InitPathGString


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPtrGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special init for pointer (static) gstring

CALLED BY:	INTERNAL
		AllocGString
PASS:		ds	- ptr to locked GString block
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Nothing much to do here.  For EC, FatalError if they are 
		trying to write to it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPtrGString	proc	far
EC <		test	ch, mask CGSC_WRITING		; if reading, ok >
EC <		ERROR_NZ GRAPHICS_CANT_WRITE_TO_PTR_GSTRING		 >
		ret
InitPtrGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDestroyGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill a graphics string

CALLED BY:	GLOBAL

PASS:		di	- handle to graphics state (0 for none)
		si	- handle to graphics string
		dl	- GStringKillType enum
				GSKT_KILL_DATA	- delete data in string along
						  with gstring handle
				GSKT_LEAVE_DATA	- leaves data alone, but frees
						  gstring handle and asooc.
						  overhead
RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		de-allocate gstring structure block;
		de-allocate gstring handle;
		destroy gstate;

		if (GSKT_KILL_DATA) and (type = (GST_CHUNK or GST_VMEM)) {
		    free the data blocks (lmem chunks/vm blocks) that
			contain the gstring data;
		    }


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrDestroyGString	proc	far
		uses	ax, bx, cx, dx, bp, ds, si
		.enter

		; make sure KillType is ok

EC <		cmp	dl, GStringKillType	; value OK ?	>
EC <		ERROR_AE GRAPHICS_BAD_DESTROY_STRING_KILL_TYPE	>

                ; first we need to lock the gstate to get access to the
		; gstring handle

		mov     bx, si                  ; gstate handle in bx
		call    MemLock	        	; lock the gstate
		mov     ds, ax                  ; ds -> gstate
		clr	bx			; we want to store a zero
		xchg	bx, ds:[GS_gstring]     ; fetch gstring handle
EC <            tst     bx                      ; check for valid handle >
EC <            ERROR_Z GRAPHICS_BAD_GSTRING_HANDLE ; fatal error       >

		; lock down the gstring structure

		call	MemLock			; ax -> GString struct
		mov	ds, ax			; ds -> GString struct
		;
		; See if there is an associated GState, and if so, see
		; if we're in the middle of playing a gstring.
		;
		tst	di			;any GState?
		jz	noGState		;branch if no GState
		test	ds:[GSS_flags], mask GSF_CONTINUING
		jz	noGState
		;
		; If we're in the middle of playing a gstring, we need
		; to clean up after outselves.  A GrSaveTransform()
		; was done at the start of the string, so we must do
		; the corresponding GrRestoreTransform() here.
		;
		call	GrRestoreTransform
noGState:

		; if we're going to biff the data, do it now

		cmp	dl, GSKT_KILL_DATA	; well ?
		jne	freeGStringBlock

		; see what type of string it is, and do the "right thing"

		mov	ax, ds:[GSS_flags]	; get flags
		and	ax, mask GSF_HANDLE_TYPE
EC <		cmp	al, GST_STREAM 		; exit for stream >
EC <		ERROR_Z	GRAPHICS_CANT_DESTROY_STREAM_GSTRING_DATA	>
EC <		cmp	al, GST_PTR 		; exit for stream >
EC <		ERROR_Z	GRAPHICS_CANT_DESTROY_PTR_GSTRING_DATA	>
		push	bx			; save gstring handle
		cmp	al, GST_VMEM 		; do one thing for vm blks
		LONG je	deleteHugeArray

		; delete chunk for memory based gstring

		push	ds			; save GString segment
		mov	cx, ds:[GSS_firstBlock]	; get chunk handle
		mov	bx, ds:[GSS_hString]	; get memory handle
		call	ObjLockObjBlock		; lock it down
		mov	ds, ax
		mov	ax, cx			; chunk in ax
		call	LMemFree
		call	MemUnlock		; dont need block anymore
		pop	ds			; restore GString segment

		; done deleting data, continue with freeing
dataDeleteDone:
		pop	bx			; restore gstring handle

		; free the GString block. We also need to reset the
		; file position for the file if we have a "stream"
		; and have been reading data.
freeGStringBlock:
		mov	ax, ds:[GSS_flags]	; get flags
		and	ax, mask GSF_HANDLE_TYPE
		cmp	al, GST_STREAM 		; did we have a stream open?
		jne	freeMemory
		mov	cx, ds:[GSS_readBytesAvail]
		jcxz	freeMemory		; if no more bytes, we're OK
		push	bx
		mov	dx, cx
		neg	dx
		mov	cx, -1			; sign extend the file pos
		mov	al, FILE_POS_RELATIVE
		mov	bx, ds:[GSS_hString]	; get stream (file) handle
		call	FilePosFar
		pop	bx
freeMemory:
		call	MemFree			; release gstring block
		mov     bx, si                  ; gstate handle in bx
		call	MemDerefDS		; ds = gstate segment
		mov	cl, ds:[GS_pathFlags]
		call    MemUnlock		; unlock the gstate
		test	cl, mask PF_DEFINING_PATH
		jnz	done			; if path, don't free GState
		xchg	si, di			; di <- GString's GState
		call    GrDestroyState          ; free the gstate
		mov_tr	di, si			; di <- associated GState
done:
		.leave
		ret

		; need to delete data for a VM chain...
deleteHugeArray:
		push	di
		mov	bx, ds:[GSS_hString]	; get vm file handle
		mov	di, ds:[GSS_firstBlock]	; get first vm block handle
		call	HugeArrayDestroy	; kill it
		pop	di
		jmp	dataDeleteDone
GrDestroyGString endp

GraphicsCommon ends

;-----------------------------------------------------------
;-----------------------------------------------------------
;-----------------------------------------------------------

GraphicsString segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitMemGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization specific to chunk-based gstring

CALLED BY:	INTERNAL
		AllocGString
PASS:		ds	- points to locked GString block
		cx	- flags as passed to AllocGString
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		If the passed ChunkHandle was passed as zero, allocate 
		a chunk in the data block.		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitMemGString	proc	far
		.enter

		mov	ax, ds:[GSS_firstBlock]		; fetch chunk handle
		tst	ax				; if zero, alloc chunk
		jz	allocBlock

		; if we are READING (playing) the gstring, leave the current
		; position at zero.  If we are WRITING to the gstring, then
		; position curPos at the end of the chunk.
getChunkSize:
		test	ch, mask CGSC_WRITING		; if reading, done
		jz	done

		; since we are writing, position curPos at the end of the 
		; chunk.

		push	bx, si
		mov	si, ax				; save chunk handle
		mov	bx, ds:[GSS_hString]		; get block handle
		push	ds
		call	ObjLockObjBlock			; ax -> block
		mov	ds, ax				; ds -> data block
		ChunkSizeHandle ds, si, si		; si = chunk size
		call	MemUnlock			; release block
		pop	ds
		mov	ds:[GSS_curPos].low, si		; store as current pos
		pop	bx, si
done:
		.leave
		ret

		; allocate a chunk in the passed block
allocBlock:
		push	bx, cx, ds
		mov	bx, ds:[GSS_hString]		; get mem block handle
		call	ObjLockObjBlock			; lock the block
		mov	ds, ax				; ds -> block
		clr	al				; no object flags
		clr	cx				; alloc it empty
		call	LMemAlloc			; allocate chunk
		call	MemUnlock			; release the block
		pop	bx, cx, ds
		mov	ds:[GSS_firstBlock], ax		; store chunk handle
		jmp	getChunkSize
InitMemGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitStreamGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some initialization specific to a stream-based gstring

CALLED BY:	INTERNAL
		AllocGString
PASS:		ds	- points to locked GString block
		cx	- flags as passed to AllocGString
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

metafileHeader	label	byte
		GSComment <(offset endMetafileHeader - offset metafileData)>
metafileData	label	byte
		char	"GEOS METAFILE 2.0"
endMetafileHeader	label byte
METAFILE_HEADER_SIZE equ (offset endMetafileHeader)-(offset metafileHeader)

InitStreamGString	proc	far
		uses	cx, dx
		.enter

		; record the current position in the file

		mov	bx, ds:[GSS_hString]	; get stream handle
		clr	cx, dx
		mov	al, FILE_POS_RELATIVE
		call	FilePosFar
		movdw	ds:[GSS_filePos], dxax

		; write out the header as the first element of the stream
		; but only if we are writing !

		test	ds:[GSS_flags].high, mask CGSC_WRITING
		jz	done

		push	ds
		mov	al, FILE_NO_ERRORS
		mov	cx, METAFILE_HEADER_SIZE
		segmov	ds, cs, dx
		mov	dx, offset metafileHeader	; ds:dx -> header bytes
FXIP <		call	SysCopyToStackDSDXFar	;ds:dx = str on stack	>
		call	FileWriteFar
FXIP <		call	SysRemoveFromStackFar				>
		pop	ds
done:
		.leave
		ret
InitStreamGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitVMemGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization specific to a vmem-based gstring

CALLED BY:	INTERNAL
		AllocGString
PASS:		ds	- locked GString block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitVMemGString	proc	far
		uses	di
		.enter

		mov	bx, ds:[GSS_hString]		; fetch VM file handle
		mov	di, ds:[GSS_firstBlock]		; fetch chunk handle
		tst	di				; if zero, alloc chunk
		jz	allocBlock

		; if we are READING (playing) the gstring, leave the current
		; position at zero.  If we are WRITING to the gstring, then
		; position curPos at the end of the chunk.

		test	ch, mask CGSC_WRITING		; if reading, done
		jz	done

		; since we are writing, position curPos at the end of the 
		; array.

		push	dx, ax
		call	HugeArrayGetCount		; get #elements
		movdw	ds:[GSS_curPos], dxax
		pop	dx, ax
done:
		.leave
		ret

		; allocate a HugeArray to put the gstring into
allocBlock:
		push	cx
		clr	cx				; variable sized elem
		call	HugeArrayCreate
		mov	ds:[GSS_firstBlock], di		; save dir block handle
		pop	cx
		jmp	done
InitVMemGString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPathGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Specific initialization for path style gstrings

CALLED BY:	INTERNAL
		AllocGString
PASS:		ds	- pointer to locked GString block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPathGString	proc	far
		uses	cx
		.enter
		and	ds:[GSS_flags], not mask GSF_HANDLE_TYPE
		mov	ds:[GSS_flags], GST_CHUNK	; fake like a memory gs
		mov	bx, ds:[GSS_header].LMBH_handle	; get han to GS struct
		mov	ds:[GSS_hString], bx		; self-reference
		clr	cx
		clr	al
		call	LMemAlloc			; allocate a chunk
		mov	ds:[GSS_firstBlock], ax
		.leave
		ret
InitPathGString	endp

GraphicsString ends
