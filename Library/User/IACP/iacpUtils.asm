COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		iacpUtils.asm

AUTHOR:		Adam de Boor, Oct 12, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT IACPLockListBlockExcl	Lock the IACPListBlock for exclusive access

    INT IACPLockListBlockShared	Lock the IACPListBlock for shared access

    INT IACPUnlockListBlockExcl	Unlock the IACPListBlock for exclusive
				access

    INT IACPUnlockListBlockShared
				Unlock the IACPListBlock for shared access

    INT IACPLocateDocument	Find a document in the registry, given its
				48-bit ID

    INT IACPLD_callback		Callback function to locate a document
				given its 48-bit ID.

    INT IACPFindServer		Locate a particular server in the server
				array for an IACP list

    INT IACPFindList		Locate an IACPList structure given a
				GeodeToken

    EXT IACPDuplicateALB	Make a copy of the given block of memory.

    INT IACPDeleteConnection	Delete a connection that has no more optrs
				in it.

    INT IACPDC_unlinkCallback	Look for a particular connection and unlink
				it from its IACPList, nuking the IACPList
				if it has neither connections nor servers.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/12/92	Initial revision


DESCRIPTION:
	Utility functions used by iacpMain.asm
		

	$Id: iacpUtils.asm,v 1.1 97/04/07 11:47:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



IACPCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLockListBlockExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the IACPListBlock for exclusive access

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		ds	= locked IACPListBlock
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLockListBlockExcl proc	near
		uses	bx, ax
		.enter
		mov	bx, handle IACPListBlock
		call	MemLockExcl
		mov	ds, ax
		.leave
		ret
IACPLockListBlockExcl endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLockListBlockShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the IACPListBlock for shared access

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		ds	= locked IACPListBlock
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLockListBlockShared proc	far
		uses	bx, ax
		.enter
		mov	bx, handle IACPListBlock
		call	MemLockShared
		mov	ds, ax
		.leave
		ret
IACPLockListBlockShared endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPUnlockListBlockExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the IACPListBlock for exclusive access

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPUnlockListBlockExcl proc	near
		uses	bx
		.enter
		mov	bx, handle IACPListBlock
		call	MemUnlockExcl
		.leave
		ret
IACPUnlockListBlockExcl endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPUnlockListBlockShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the IACPListBlock for shared access

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPUnlockListBlockShared proc	far
		uses	bx
		.enter
		mov	bx, handle IACPListBlock
		call	MemUnlockShared
		.leave
		ret
IACPUnlockListBlockShared endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLocateDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a document in the registry, given its 48-bit ID

CALLED BY:	(INTERNAL) IACPCheckAndLocateDocument, IACPUnregisterDocument
PASS:		ax	= disk handle
		cxdx	= FileID
		^lbx:si	= server (bx == 0 if shouldn't check server)
		ds	= IACPListBlock
RETURN:		carry set if found:
			ax	= index of IACPDocument in iacpDocArray
		carry clear if no such doc registered
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		inline-expands ChunkArrayEnum as there aren't enough registers
		passed through to perform the requisite comparison.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPLocateDocument proc	near
		uses	di, bp
		.enter
		mov	di, ds:[iacpDocArray]
		mov	bp, ds:[di].CAH_count
		tst	bp
		jz	done
		add	di, ds:[di].CAH_offset
searchLoop:
		cmp	ds:[di].IACPD_disk, ax
		jne	no
		cmp	ds:[di].IACPD_id.high, cx
		jne	no
		cmp	ds:[di].IACPD_id.low, dx
		jne	no
		tst	bx
		jz	yes
		cmp	ds:[di].IACPD_server.handle, bx
		jne	no
		cmp	ds:[di].IACPD_server.chunk, si
		je	yes
no:
		add	di, size IACPDocument
		dec	bp
		jnz	searchLoop
		clc
done:
		.leave
		ret
yes:
		mov	di, ds:[iacpDocArray]
		mov	ax, ds:[di].CAH_count
		sub	ax, bp		; ax <- index
		stc
		jmp	done		
IACPLocateDocument endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPLD_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to locate a document given its 48-bit
		ID.

CALLED BY:	(INTERNAL) IACPLocateDocument via ChunkArrayEnum
PASS:		ds:di	= IACPDocument to check
		ax	= disk handle
		cxdx	= FileID
		bp	= element #
RETURN:		carry set if found (stop enumerating)
			bp	= untouched
		carry clear if not found (keep going)
			bp	= element # of next one
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	(0)
IACPLD_callback proc	far
		.enter
no:
		inc	bp
		clc
done:
		.leave
		ret
IACPLD_callback endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPFindServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate a particular server in the server array for an
		IACP list

CALLED BY:	(INTERNAL) IACPUnregisterServer via ChunkArrayEnum
PASS:		*ds:si	= server array
		ds:di	= IACPServer to check
		^lcx:dx	= optr of server being sought
		ax	= element # of this entry
RETURN:		carry set if this is the one:
			ax	= element # of the entry
		carry clear if this isn't the one:
			ax	= element # of the next entry
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPFindServer	proc	far
		.enter
		cmp	ds:[di].IACPS_object.handle, cx
		jne	no
		cmp	ds:[di].IACPS_object.chunk, dx
		je	done
no:
		stc
		inc	ax
done:
		cmc
		.leave
		ret
IACPFindServer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPFindList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate an IACPList structure given a GeodeToken

CALLED BY:	(INTERNAL)
PASS:		es:di	= GeodeToken
		(es:di *cannot* be pointing to the movable XIP code resource.)
		ds	= locked IACPListBlock 
RETURN:		carry set if found:
			ax	= element number
		carry clear if list not around
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPFindList	proc	near
		uses	bx, cx, dx, bp, si, di
		.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr (es:di) passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
		mov	cx, {word}es:[di].GT_chars[0]
		mov	dx, {word}es:[di].GT_chars[2]
		mov	bp, es:[di].GT_manufID

	;
	; Inline expansion of ChunkArrayEnum so we can do this in more
	; than one thread at a time.
	; 
		mov	di, ds:[iacpListArray]
		mov	si, ds:[di].CAH_count
		add	di, size ChunkArrayHeader - size IACPList
		mov	ax, -1
findLoop:
		inc	ax			; advance elt #
		dec	si			; reduce elt counter
		jl	notFound
		add	di, size IACPList	; advance to next elt
	;
	; See if this IACPList is the one we want.
	; 
		cmp	{word}ds:[di].IACPL_token.GT_chars[0], cx
		jne	findLoop
		cmp	{word}ds:[di].IACPL_token.GT_chars[2], dx
		jne	findLoop
		cmp	ds:[di].IACPL_token.GT_manufID, bp
		jne	findLoop
	;
	; Found it. AX = element number. Set carry to indicate our happiness.
	; 
		stc
done:
		.leave
		ret

notFound:
		clc
		jmp	done
IACPFindList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPDuplicateALB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a copy of the given block of memory.

CALLED BY:	(EXTERNAL) IACPConnect
PASS:		bx	= handle of block to duplicate
RETURN:		dx	= old handle
		bx	= new handle
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPDuplicateALB proc	far
		uses	ax, ds, si, di, es, cx
		.enter
	;
	; Figure the size of the block.
	; 
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		push	ax		; save for copy
	;
	; Allocate another the same size, locked. (XXX: pass NO_ERR flag.
	; Ought to be able to handle an error more gracefully, but I have
	; no time to code it -- ardeb 11/23/92)
	; 
		mov	dx, bx
		call	MemOwner
		push	bx
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAlloc
		mov	es, ax
		pop	ax
		call	HandleModifyOwner
	;
	; Lock down the source block.
	; 
		xchg	bx, dx
		call	MemLock
		mov	ds, ax
	;
	; Copy the contents from the old to the new.
	; 
		clr	si, di
		pop	cx
		shr	cx
		rep	movsw
	;
	; Unlock the old.
	; 
		call	MemUnlock
	;
	; Unlock the new.
	; 
		xchg	bx, dx
		call	MemUnlock
		.leave
		ret
IACPDuplicateALB endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPDeleteConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a connection that has no more optrs in it.

CALLED BY:	(INTERNAL) IACPShutdown
PASS:		*ds:bp	= IACPConnectionStruct
		IACPListBlock locked for exclusive access
RETURN:		nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPDeleteConnection proc	near
		uses	bx, si, di
		.enter
	;
	; Unlink it from the list of connections...
	; 
		mov	si, offset iacpListArray
		mov	bx, cs
		mov	di, offset IACPDC_unlinkCallback
		call	ChunkArrayEnum
	;
	; ...and free the chunk.
	; 
		mov	ax, bp
		call	LMemFree
		.leave
		ret
IACPDeleteConnection endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPDC_unlinkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a particular connection and unlink it from its
		IACPList, nuking the IACPList if it has neither connections
		nor servers.

CALLED BY:	(INTERNAL) IACPDeleteConnection via ChunkArrayEnum
PASS:		*ds:si	= iacpListArray
		ds:di	= IACPList to check
		bp	= IACPConnection chunk
RETURN:		carry set if found and unlinked connection
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPDC_unlinkCallback proc	far
		.enter
	;
	; ds:bx = address of link to next connection.
	; 
		lea	bx, ds:[di].IACPL_connections
connectionLoop:
		mov	ax, ds:[bx]	; ax <- next connection

		cmp	ax, bp		; this the one we're nuking?
		je	foundLink	; yes
		tst	ax		; end of the line?
		jz	done		; yes -- try the next list (carry clear)
	;
	; Point ds:bx to the IACPCS_next field of *ds:ax and loop.
	; 
		mov_tr	bx, ax
		mov	bx, ds:[bx]
		CheckHack <offset IACPCS_next eq 0>
		jmp	connectionLoop

foundLink:
	;
	; *ds:bx points to the handle of the connection we're nuking, so
	; replace it with our connection's IACPCS_next field.
	; 
		mov	si, ds:[bp]
		mov	ax, ds:[si].IACPCS_next
		mov	ds:[bx], ax
	;
	; Reduce the number of connections for this list by one.
	; 
		dec	ds:[di].IACPL_numConnect
		jnz	doneStop
	;
	; No more connections. See if there are any more servers for the list.
	; 
		mov	si, ds:[di].IACPL_servers
		call	ChunkArrayGetCount
		jcxz	nukeList		; => no more servers, so no more
						;  need for the list
doneStop:
	;
	; Tell caller to stop enumerating.
	; 
		stc
done:
		.leave
		ret

nukeList:
	;
	; Nothing left for the list, so nuke the array of servers, then the
	; IACPList structure itself.
	; 
		mov_tr	ax, si			; ax <- servers array
		call	LMemFree
		mov	si, offset iacpListArray
		call	ChunkArrayDelete
		jmp	doneStop
IACPDC_unlinkCallback endp

IACPCommon	ends
