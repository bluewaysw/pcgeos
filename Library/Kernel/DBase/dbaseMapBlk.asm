COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Database Manager -- Map-block maintenance
FILE:		dbMapBlk.asm

AUTHOR:		John Wedgwood, Jul 24, 1989

METHODS:
	Name			Description
	----			-----------
	DBInitDBMap		Create the database manager map block.
	DBLockDBMap		Lock the database manager map block.
	DBUnlockDBMap		Unlock the database manager map block.
	DBDirtyDBMap		Mark map block as dirty.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	7/24/89		Initial revision

DESCRIPTION:
	This file contains the implementation of map-block for database
	manager. The routines here create, initialize, lock, and unlock the
	database managers map-block. This block is not intended to be accessed
	by the application. The database managers map-block is intended to hold
	data-structures needed by the manager to handle the database file.

	Currently the only thing held in the database managers map block is
	the map-group and map-item that the application sets.

	Applications can specify a map-item, which is the standard database
	group/item pair. The application can use the high-level routines:
		DBSetMap(), DBGetMap(), and DBLockMap()
	to manipulate this map-item.

	The application interface to the map-item is covered in more detail
	in the file /staff/pcgeos/Spec/db.doc. The code is in Code.asm

USAGE:	Where possible:
	bx = Database file handle.
	ds = segment address of map block.

	$Id: dbaseMapBlk.asm,v 1.1 97/04/05 01:17:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBaseCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInitDBMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the database managers map block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
RETURN:		ax = map block
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Create a VM block to hold the datbase manager information.
	Call VMSetMapBlock() to make this the map block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBInitDBMap	proc	far 	uses cx, ds, bp
	.enter
	mov	cx, size DBMapBlock	;
	mov	ax, DB_MAP_ID		;
	call	VMAlloc			; ax <- handle.
	push	ax			;
	call	VMSetDBMap		; Make this the map block.
	call	VMLock			;
	mov	ds, ax			;
	;
	; Initialize the map block (initialized to 0 by VMAlloc).
	;

	push	ds			; allocate old-style ungrouped group
					;  in case file is used in old system
	call	DBGroupAlloc				; ax <- vm-handle.
	call	DBGroupLock				; ds <- seg of group.
	ornf	ds:DBGH_flags, mask GF_IS_UNGROUP	; Mark as the ungroup.
	call	DBGroupDirty				; Mark dirty.
	call	DBGroupUnlock				; Release the ungroup.
	pop	ds
	mov	ds:[DBMB_ungrouped], ax

	pop	ax			; ax <- map handle, for return
	mov	ds:DBMB_vmemHandle, ax	; set vmem handle.
	call	VMDirty			;
	call	VMUnlock		; Unlock the map block.
	.leave
	ret				;
DBInitDBMap	endp

DBaseCode	ends

kcode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBLockDBMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the database managers map block into memory.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
RETURN:		ds = segment address of database map block.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBLockDBMap	proc	far 	uses ax, bp
	.enter
	call	VMGetDBMap		; ax <- map block handle
	tst	ax
	jnz	mapExists

	; map block does not exist -- create it

	call	DBInitDBMap
mapExists:

EC <	tst	ax			; Must have one...	>
EC <	ERROR_Z	DB_NO_MAP_BLOCK		;			>

	call	VMLock			; ax <- segment, bp <- handle.
	mov	ds, ax			;
	mov	ds:DBMB_handle, bp	; save the handle.
					;
EC <	call	DBValidateMapBlock	;	>
	.leave
	ret				;
DBLockDBMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUnlockDBMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the database manager's map block.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of map block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBUnlockDBMap	proc	far
	push	bp			;
EC <	call	DBValidateMapBlock	;	>
					;
	mov	bp, ds:DBMB_handle	; bp <- handle to unlock.
	call	VMUnlock		; unlock it...
	pop	bp			;
	ret				;
DBUnlockDBMap	endp

kcode	ends

DBaseCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDirtyDBMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark map block as dirty.

CALLED BY:	Internal.
PASS:		bx = Database file handle.
		ds = segment address of locked map block.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBDirtyDBMap	proc	near
	push	bp			;
EC <	call	DBValidateMapBlock	;	>
					;
	mov	bp, ds:DBMB_handle	;
	call	VMDirty			;
	pop	bp			;
	ret				;
DBDirtyDBMap	endp

DBaseCode	ends
