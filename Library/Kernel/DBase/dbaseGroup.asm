COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Database manager.
FILE:		dbGroup.asm

AUTHOR:		John Wedgwood, Jul 24, 1989

METHODS:
	Name			Description
	----			-----------
	DBGroupLock		Lock a group block.
	DBGroupUnlock		Unlock a group block.
	DBGroupDirty		Dirty the group block.
	DBGroupGetUngrouped	Get the "ungrouped" group.
	DBGroupNewUngrouped	Create a new "ungrouped" group.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	7/24/89		Initial revision

DESCRIPTION:
	This file contains routines which manipulate group blocks at the
	highest level (lock and unlock).

USAGE:	Where possible the following registers are defined:
	bx = Database file handle.
	ax = VM-handle of the group block.
	ds = segment address of the locked group block.

	$Id: dbaseGroup.asm,v 1.1 97/04/05 01:17:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


kcode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a database group block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ax = group vmem handle.
RETURN:		ds = segment address of the group.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupLock	proc	far	uses ax, bp
	.enter
	call	VMLock			; ds <- seg addr, bp <- handle.
	mov	ds, ax			;
	mov	ds:DBGH_handle, bp	; save the memory handle.
					;
EC <	call	DBValidateGroup		; needs : ds = seg addr of group. >
	.leave
	ret				;
DBGroupLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a database group block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of the group block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/24/89		Initial version
	ardeb	4/1/94		added ungroup-full stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupUnlock	proc	far
	push	bp
EC <	call	DBValidateGroup		; needs : ds = seg addr of group. >
					;
	mov	bp, ds:DBGH_handle	; bp <- memory handle.
	call	VMUnlock		; Unlock it.
	pop	bp
	ret				;
DBGroupUnlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dirty a group block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of locked group block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupDirty	proc	far
	push	bp			;
EC <	call	DBValidateGroup		; needs : ds = seg addr of group. >
	mov	bp, ds:DBGH_handle	;
	call	VMDirty			;
	pop	bp			;
	ret				;
DBGroupDirty	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupGetUngrouped
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the current "ungrouped" group.

CALLED BY:	DBAlloc
PASS:		bx = byte file handle (vm file handle).
RETURN:		ax = ungrouped group to use.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupGetUngrouped	proc	far	uses ds
	.enter
	call	DBLockDBMap		; ds <- seg addr of map block.
	mov	ax, ds:DBMB_newUngrouped; ax <- group block.
	tst	ax
	jnz	done
	call	DBGroupNewUngrouped	; won't move map block
	mov	ax, ds:[DBMB_newUngrouped]
done:
	call	DBUnlockDBMap		; Release map block.
	.leave
	ret				;
DBGroupGetUngrouped	endp

kcode	ends

DBaseCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGroupNewUngrouped
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new ungrouped group block.

CALLED BY:	External.
PASS:		bx = file handle.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Offhand, it looks like there might be a synch problem here, with two
	things allocating a new ungroup at the same time, but since the
	allocation is triggered by finding DBMB_newUngrouped set to 0
	with the DB map block locked, there is no synch problem (the
	DB map block is the mutex point)
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGroupNewUngrouped	proc	far	uses ax, ds
	.enter
	;
	; First look for another ungrouped block that's become available
	; since being taken off the market.
	; 
	call	VMFindAvailUngroup
	jc	setUngroup

	call	DBGroupAlloc				; ax <- vm-handle.
	call	DBGroupLock				; ds <- seg of group.
	ornf	ds:DBGH_flags, mask GF_NEW_UNGROUP	; Mark as the ungroup.
	call	DBGroupDirty				; Mark dirty.
	call	DBGroupUnlock				; Release the ungroup.

setUngroup:						;
	call	DBLockDBMap				; ds <- seg of map.
	mov	ds:DBMB_newUngrouped, ax		; Make current ungroup.
	call	DBDirtyDBMap				; Mark dirty.
	call	DBUnlockDBMap				; Release the map block
	.leave
	ret						;
DBGroupNewUngrouped	endp

DBaseCode	ends
