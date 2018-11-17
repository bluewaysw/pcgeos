COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		mediaInit.asm

AUTHOR:		Adam de Boor, Apr 12, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/12/94		Initial revision


DESCRIPTION:
	Initialize the maps.
		

	$Id: mediaInit.asm,v 1.1 97/04/05 01:20:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the status & transport maps

CALLED BY:	(EXTERNAL) AdminInitFile, AdminInit
PASS:		bx	= admin file handle (just a shortcut...)
		ax	= block handle of status map (0 if none allocated)
		cx	= block handle of transport map (0 if non allocated)
RETURN:		ax	= block handle of status map
		cx	= block handle of transport map
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaInit	proc	near
		uses	ds, bp, si
		.enter
ife	_HAS_SWAP_SPACE
	;
	; The status map gets zeroed at the start, then filled in as media
	; become detected.
	; 
		tst	ax
		jnz	emptyStatusMap
		call	MediaInitStatus		; ax <- block handle
emptyStatusMap:
		push	ax, cx
		call	VMLock
		mov	ds, ax
	;
	; Easiest is to reinitialize the entire heap, rather than
	; freeing up the reasons and addresses and other things.
	;
		push	bx
		push	dx, di
		mov	ax, LMEM_TYPE_GENERAL
		mov	bx, bp			; bx <- mem handle
		mov	cx, 2			; cx <- # handles
		mov	dx, size LMemBlockHeader; dx <- header size
		mov	si, 64			; si <- initial space
		mov	di, mask LMF_IS_VM	; di <- flags
		call	LMemInitHeap
else
	;
	; When there's swap space, we allocate a block to hold the status
	; map each time the system boots.
	;
		push	cx, bx			; saved passed MT map & admin
						;  file
		mov	ax, LMEM_TYPE_GENERAL	; ax <- heap type
		clr	cx			; cx <- default header size
		call	MemAllocLMem
		mov	ax, mask HF_SHARABLE
		call	MemModifyFlags
		mov_tr	ax, bx			; ax <- handle to return
		pop	cx, bx			; cx <- MT map, bx <- admin
						;  file

		push	ax			; save status handle
		push	cx			; save MT handle

		push	bx			; save admin file
		mov	bp, ax			; bp <- mem handle for release
		mov_tr	bx, ax			; bx <- mem handle for grab
		call	MemThreadGrab
		mov	ds, ax
endif	; _HAS_SWAP_SPACE
		
	;
	; Allocate the chunk array to hold the available media/unit pairs.
	; 
		clr	bx, si, cx	; bx <- variable-sized elements
					; si <- allocate chunk, please
					; cx <- use default header
		call	ChunkArrayCreate
ife	_HAS_SWAP_SPACE
		pop	dx, di
endif	; !_HAS_SWAP_SPACE
		pop	bx		; bx <- admin file
EC <		cmp	si, ds:[LMBH_offset]				>
EC <		ERROR_NE	MEDIA_STATUS_MAP_NOT_FIRST_CHUNK	>

ife	_HAS_SWAP_SPACE
	;
	; Dirty and unlock the status block -- we need it no longer.
	;
		call	VMDirty
		call	VMUnlock
else
	;
	; Release the status block -- we need it no longer.
	;
		xchg	bx, bp		; bx <- mem handle
		call	MemThreadRelease
		mov_tr	bx, bp
endif	; _HAS_SWAP_SPACE

		pop	cx		; cx <- MT
	;
	; Just need to make sure the arrays are allocated for the transport
	; map. They don't get nuked at the start of each session.
	; 
		tst	cx
		jnz	fixTransport
		call	MediaInitTransport	; cx <- block handle
		jmp	done
fixTransport:
		mov	ax, cx			; ^vbx:ax <- MT map
		call	UtilFixTwoChunkArraysInBlock
done:
		pop	ax		; ax <- status handle
		.leave
		ret
MediaInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaInitStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a block to hold the media status map.

CALLED BY:	(INTERNAL) MediaInit
PASS:		bx	= VM file handle
RETURN:		ax	= block handle of map
DESTROYED:	ds, bp, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ife	_HAS_SWAP_SPACE
MediaInitStatus	proc	near
		uses	cx, bx
		.enter
	;
	; Allocate a standard LMem block in the VM file.
	; 
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx		; default header size
		call	VMAllocLMem
	;
	; Mark the VM block for later EC.
	; 
		mov	cx, MBVMID_MEDIA_STATUS
		call	VMModifyUserID
		.leave
		ret
MediaInitStatus	endp
endif	; _HAS_SWAP_SPACE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MediaInitTransport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a block to hold the media -> transport map.

CALLED BY:	(INTERNAL) MediaInit
PASS:		bx	= VM file handle
RETURN:		cx	= block handle of map
DESTROYED:	ds, bp, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MediaInitTransport	proc	near
		uses	ax, bx
		.enter
		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size MediaTransportHeader
		call	VMAllocLMem
		push	ax, bx
		call	VMLock
		mov	ds, ax
		mov	ds:[MTH_allCaps], 0
EC <		mov	ds:[MTH_sendUpdate], FALSE			>
	;
	; First allocate the chunk array that holds MediaTransportMediaElement
	; structures.
	; 
		clr	bx, si, cx	; bx <- variable-sized elements
					; si <- allocate chunk, please
					; cx <- use default header
		call	ChunkArrayCreate
EC <		cmp	si, ds:[LMBH_offset]				>
EC <		ERROR_NE	MEDIA_TRANSPORT_MEDIA_MAP_NOT_FIRST_CHUNK>
	;
	; Now allocate the ElementArray in which the transport tokens are
	; placed.
	; 
		mov	bx, size MediaTransportElement
		clr	si, cx		; si <- allocate chunk please
					; cx <- use default header
		call	ElementArrayCreate
EC <		mov	ax, ds:[LMBH_offset]				>
EC <		inc	ax						>
EC <		inc	ax						>
EC <		cmp	si, ax						>
EC <		ERROR_NE	MEDIA_TRANSPORT_MAP_NOT_SECOND_CHUNK	>
   		call	VMDirty
		call	VMUnlock
	;
	; Mark the VM block for later EC.
	; 
		pop	ax, bx
		mov	cx, MBVMID_MEDIA_TRANSPORT
		call	VMModifyUserID
		mov_tr	cx, ax
		.leave
		ret
MediaInitTransport endp

Init	ends
