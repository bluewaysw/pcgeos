COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Database manager.
FILE:		ErrorCheck.asm

AUTHOR:		John Wedgwood, Jun 21, 1989

ROUTINES:
	Name			Description
	----			-----------
	DBCheckIsGroup		Check 'ax' for being a vm block handle.
	DBCheckIsItem		Check 'di' for being an item reference.
	DBCheckIsItemBlock	Check 'es' for being an item block segment.
	DBCheckIsChunk		Check 'di' for being a valid chunk handle.
	DBValidateGroup		Check a locked group block for consistency.
	DBValidateItemBlock	Check a locked item block for consistency.
	DBValidateMapBlock	Check a locked map block for consistency.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	6/21/89		Initial revision

DESCRIPTION:
	Error checking code for the database manager.

	$Id: dbaseErrorCheck.asm,v 1.1 97/04/05 01:17:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ERROR_CHECK

DBaseCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCheckIsGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the 'ax' parameter to the database routines is
		a valid group. (is a vm-handle).

CALLED BY:	Internal.
PASS:		ax = value to check.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dies if 'ax' is not a valid vm-handle.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCheckIsGroup	proc	far
	call	ECVMCheckVMBlockHandle
	ret
DBCheckIsGroup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCheckIsItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the 'di' parameter to the database routines to see that
		it is a valid item-reference.

CALLED BY:	Internal.
PASS:		di = value to check.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dies if di is not a valid reference.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCheckIsItem	proc	far
	ret				;
DBCheckIsItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCheckIsItemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks that 'es' contains a segment address of an item block.

CALLED BY:	Internal.
PASS:		es = segment address to check.
		bx = file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dies if es is not the segment address of an item block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCheckIsItemBlock	proc	far
	pushf				;
	push	ax, ds, bp, di, bx	;
	segmov	ds, es			;
	call	ECLMemValidateHeapFar	; Check the entire heap.
	;
	; memory handle, vm-handle.
	;
	mov	ax, ds:DBIBH_vmHandle	; Check vm-handle.
	call	ECVMCheckVMBlockHandle
					;
	mov	bx, ds:LMBH_handle	; bx <- memory handle.
	call	ECVMCheckMemHandle	;
					;
	pop	ax, ds, bp, di, bx	;
	popf				;
	ret				;
DBCheckIsItemBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCheckIsChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks that es:*di is a valid chunk.

CALLED BY:	Internal.
PASS:		es = segment address of lmem heap.
		di = chunk handle to check.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dies if es:*di does not point to a chunk in an lmem heap.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	0	;unused
DBCheckIsChunk	proc	far
	pushf				;
	push	bx			;
	call	DBCheckIsItemBlock	; Check es for being an item-block.
	pop	bx			;
	popf				;
					;
	pushf				;
	push	ds, ax			;
	segmov	ds, es			;
	mov	ax, di			;
	call	ECLMemExists		; Check chunk handle.
	pop	ds, ax			;
	popf				;
	ret				;
DBCheckIsChunk	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBValidateGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks an entire group block for consistency.

CALLED BY:	Internal.
PASS:		ds = segment address of locked group block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dies with a fatal-error if the block doesn't check out.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBValidateGroup	proc	far
	pushf					;
	call	CheckNormalECEnabled
	jz	done
	push	ax, bx, si			;
	mov	ax, ds:DBGH_vmemHandle		; ax <- vm-block handle.
	call	DBCheckIsGroup			; Check vm-block handle.
	mov	bx, ds:DBGH_handle		; bx <- memory handle.
	call	ECVMCheckMemHandle		; Check for valid memory handle.
;**********************************************************************
;
; Check the free-list for the items.
;
	mov	si, ds:DBGH_itemFreeList	; ds:si <- ptr to first item.
DBVG_IFreeLoop:					;
	tst	si				;
	jz	DBVG_endIFreeCheck		;
	;
	; Check that si is in the bounds of the heap of structures.
	; Check that si is even.
	;
	mov	si, ds:[si].DBFIS_next		; si <- ptr to next item.
	jmp	DBVG_IFreeLoop			;
DBVG_endIFreeCheck:				;

;**********************************************************************
;
; Check the free-list for the item-blocks.
;
	mov	si, ds:DBGH_blockFreeList	; ds:si <- ptr to first item.
DBVG_BFreeLoop:					;
	tst	si				;
	jz	DBVG_endBFreeCheck		;
	;
	; Check that si is in the bounds of the heap of structures.
	; Check that si is even.
	;
	mov	si, ds:[si].DBFIS_next		; si <- ptr to next item.
	jmp	DBVG_BFreeLoop			;
DBVG_endBFreeCheck:				;

;**********************************************************************
;
; Check the list of item-blocks.
;
	mov	si, ds:DBGH_itemFreeList	; ds:si <- ptr to first item.
DBVG_blockLoop:					;
	tst	si				;
	jz	DBVG_endBlockCheck		;
	;
	; Check that si is in the bounds of the heap of structures.
	; Check that si is even.
	;
	mov	si, ds:[si].DBFIS_next		; si <- ptr to next item.
	jmp	DBVG_blockLoop			;
DBVG_endBlockCheck:				;

;**********************************************************************
	;
	; for each item block (DBGH_itemBlocks)
	;	count = reference count for the item block.
	;	verify = 0
	;	foreach item in the group
	;	    if item is in item-block then
	;	    verify++
	;	done
	;	if (count != verify) then
	;	    Error
	;	fi
	; done
	;
	pop	ax, bx, si			;
done:
	popf					;
	ret					;
DBValidateGroup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBValidateItemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks an entire item-block for consistency.

CALLED BY:	Internal.
PASS:		es = segment address of locked item block.
		bx = file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dies if the item-block doesn't check out.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBValidateItemBlock	proc	far
	call	DBCheckIsItemBlock	; Check the entire heap.
	ret				;
DBValidateItemBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCheckIBRefCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the reference count for the given item block matches
		the actual number of references to the block.

CALLED BY:	INTERNAL
PASS:		ds:si	= DBItemBlockInfo
		es	= locked item block
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		XXX: USES INTERNAL LMEM DEFINITIONS...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBCheckIBRefCount proc	far
;
; The whole procedure is commented out because the Mailbox Library itself
; allocates chunks in DB blocks to store extra data, which violates the
; assumption that the number of in-use chunks is the same as the reference
; count.   --- AY 7/13/94
;
if 0
		uses ax, si, cx, ds, bx
		.enter
	;
	; Assume that the number of in-use chunk handles in the item info
	; block should match the reference count, since each item should have
	; one and only one handle...
	; XXX: Might get screwed if someone takes it into his/her head to
	; allocate extra data chunks in a dbase block once he/she has locked
	; down an item...
	; 
		pushf
		push	ds, si

		segmov	ds, es
		mov	si, ds:[LMBH_offset]
		mov	cx, ds:[LMBH_nHandles]
		clr	bx
countLoop:
		lodsw
		tst	ax
		jz	doneLoop
		inc	bx
doneLoop:
		loop	countLoop
		pop	ds, si

		cmp	bx, ds:[si].DBIBI_refCount
		ERROR_NE	BAD_ITEM_BLOCK_REFERENCE_COUNT
		popf
		.leave
endif
		ret
DBCheckIBRefCount endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBValidateMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks a map block for consistency.

CALLED BY:	Internal.
PASS:		ds = segment address of locked map block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Dies if the map block doesn't check out.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBValidateMapBlock	proc	far
	pushf				;
	push	ax, bx, cx, di, si	;

	mov	ax, ds:DBMB_mapGroup	; ax <- group (vm-block handle).
	mov	di, ds:DBMB_mapItem	; di <- item reference.
	mov	cx, ax			;
	or	cx, di			;
	jcxz	DBVMB_noMap		; HandleMem case of no map block
	call	DBCheckIsGroup		; Make sure it is a valid group.
	call	DBCheckIsItem		; Make sure it is a valid item.
DBVMB_noMap:				;
	mov	ax, ds:DBMB_vmemHandle	; ax <- vm-block handle of map block.
	call	ECVMCheckVMBlockHandle	; Make sure it is a valid handle.
	mov	bx, ds:DBMB_handle	; bx <- memory handle.
	call	ECVMCheckMemHandle	; Check for valid memory handle.
	pop	ax, bx, cx, di, si	;
	popf				;
	ret				;
DBValidateMapBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBEnsureNotExplicitUngrouped
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If explicit group is given, make sure it's not a member of
		the ungrouped set

CALLED BY:	(INTERNAL) DBAlloc
PASS:		bx	= file handle
		ax	= group handle or DB_UNGROUPED
RETURN:		only if group handle is DB_UNGROUPED or for a group outside
			the ungrouped set
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 4/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBEnsureNotExplicitUngrouped proc	far
		uses	ds
		.enter
		call	ECVMCheckVMFile

		cmp	ax, DB_UNGROUPED
		je	done
		
		call	DBCheckIsGroup
		call	DBGroupLock
		test	ds:[DBGH_flags], 
			mask GF_IS_UNGROUP or mask GF_NEW_UNGROUP
		
		ERROR_NZ	UNGROUPED_GROUP_MAY_NOT_BE_PASSED_AS_AN_EXPLICIT_GROUP
		call	DBGroupUnlock
done:
		.leave
		ret
DBEnsureNotExplicitUngrouped endp

DBaseCode	ends

endif
