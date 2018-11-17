COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		outboxReason.asm

AUTHOR:		Adam de Boor, May  9, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/ 9/94		Initial revision


DESCRIPTION:
	Functions to track the reasons for failed transmission.
		

	$Id: outboxReason.asm,v 1.1 97/04/05 01:21:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Outbox		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down the outbox reason map & fetch the name array
		it holds.

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		*ds:si	= reason name array
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORLock		proc	near
		uses	bx, ax, bp
		.enter
	;
	; Get the vptr of the reason map & error-check the heck out of it.
	; 
		call	AdminGetReasons

EC <		call	ECVMCheckVMFile					>
EC <		push	ax, cx, di					>
EC <		call	VMInfo						>
EC <		ERROR_C	OUTBOX_REASON_MAP_INVALID			>
EC <		cmp	di, MBVMID_OUTBOX_REASONS			>
EC <		ERROR_NE OUTBOX_REASON_MAP_INVALID			>
EC <		pop	ax, cx, di					>
	;
	; Lock down the block & error-check the heck out of it.
	; 
		call	VMLock
		mov	ds, ax

EC <		mov	bx, bp						>
EC <		call	ECCheckLMemHandle				>
EC <		call	ECLMemValidateHeap				>
	;
	; Load SI and DI with the requisite values (& error-check the...)
	; 
		mov	si, ds:[LMBH_offset]		; si <- name array

EC <		call	ECLMemValidateHandle				>

		.leave
		ret
ORLock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ORStoreReason
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a reason string in the array and return its
		element # for storage

CALLED BY:	(EXTERNAL)
PASS:		^lcx:dx	= null-terminated string 
RETURN:		ax	= reason token
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ORStoreReason	proc	far
		uses	ds, si, cx, di, es, bx
EC <		uses	dx					>
		.enter
	;
	; Point to the null-terminated string.
	; 
		mov	bx, cx
		call	MemLock
		push	bx
		mov	es, ax
		mov	di, dx
		mov	di, es:[di]
	; EC: pass something reasonable in DX:AX even though we don't store
	; additional data with the element.
EC <		mov_tr	dx, ax					>
EC <		clr	ax					>
	;
	; Lock down the name array.
	; 
		call	ORLock
	;
	; Store the string in the name array.
	; 
		clr	bx, cx			; bx <- leave data alone if
						;  already exists
						; cx <- string is null-term
		call	NameArrayAdd
		jc	done			; => was added
	;
	; Avoid reference-count build-up by forcing the count back to 1 if
	; didn't just create the entry.
	; 
		call	ChunkArrayElementToPtr
		mov	ds:[di].REH_refCount.WAAH_low, 1
		call	UtilVMDirtyDS
done:
		pop	bx
		call	MemUnlock
		call	UtilVMUnlockDS
		.leave
		ret
ORStoreReason	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutboxGetReason
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the reason a transmission failed.

CALLED BY:	(EXTERNAL)
PASS:		ds	= locked lmem block
		ax	= reason token
RETURN:		*ds:ax	= null-terminated reason string
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 9/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutboxGetReason	proc	far
		uses	es, di, si, cx
		.enter
	;
	; Point to the reason string.
	; 
		segmov	es, ds
		call	ORLock
		call	ChunkArrayElementToPtr	; cx <- elt size

EC <		ERROR_C	OUTBOX_INVALID_REASON_TOKEN			>
EC <		cmp	ds:[di].REH_refCount.WAAH_high, EA_FREE_ELEMENT	>
EC <		ERROR_E	OUTBOX_INVALID_REASON_TOKEN			>
	;
	; Allocate room for the string in the destination block. Note that the
	; name array code does *not* store the null byte when told names are
	; null-terminated, so we have to allocate one byte more than the element
	; size would seem to dictate.
	; 
		sub	cx, size RefElementHeader - size TCHAR
		push	ds
		segmov	ds, es
		mov	al, mask OCF_DIRTY
		call	LMemAlloc
		segmov	es, ds
		pop	ds
	;
	; Set up for the move and do it, please.
	; 
		lea	si, ds:[di+size RefElementHeader]
		mov	di, ax
		mov	di, es:[di]
DBCS <		shr	cx		; cx = # chars			>
		dec	cx		; null byte not actually there...
		LocalCopyNString
		LocalClrChar	es:[di]
	;
	; Release the map block and return the modified segment in DS again.
	; AX remains the chunk handle allocated.
	; 
		call	UtilVMUnlockDS
		segmov	ds, es
		.leave
		ret
OutboxGetReason	endp

Outbox		ends
