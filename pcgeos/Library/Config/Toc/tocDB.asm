COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tocDB.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

DESCRIPTION:
	This file contains the Toc interface to the DB routines
	

	$Id: tocDB.asm,v 1.1 97/04/04 17:51:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocAllocDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and lock a DB item

CALLED BY:	TocAllocNameArray, TocAllocSortedNameArray,
		TocAllocChunkArray

PASS:		cx - size of item 

RETURN:		*ds:si - new chunk
		ax:di - dbptr of new item

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocAllocDBItem	proc near
		uses	bx
		.enter

		call	LoadDSDGroup
		mov	bx, ds:[tocFileHandle]
		
		mov	ax, DB_UNGROUPED
		call	DBAlloc			; ax:di <- item
		call	TocDBLock		; *ds:si - chunk
		
		.leave
		ret
TocAllocDBItem	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCDBLOCKGETREF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down an item from the current TOC file, returning its
		far * and an optr, for further lmem manipulation.

CALLED BY:	GLOBAL
PARAMETERS:	void *(DBGroupAndItem, optr *)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGeosConvention
TOCDBLOCKGETREF	proc	far thing:DBGroupAndItem, refPtr:fptr.optr
		uses	ds, si, di
		.enter
		mov	ax, ss:[thing].DBGI_group
		mov	di, ss:[thing].DBGI_item
		call	TocDBLock
		mov	dx, ds		; dx:ax <- return value
		mov	ax, ds:[si] 
		mov	bx, ds:[LMBH_handle]
		lds	di, ss:[refPtr]
		mov	ds:[di].chunk, si
		mov	ds:[di].handle, bx
		.leave
		ret
TOCDBLOCKGETREF endp
SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TOCDBLOCK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down an item from the current TOC file

CALLED BY:	GLOBAL
PARAMETERS:	void *(DBGroupAndItem)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TOCDBLOCK	proc	far
		mov	bx, di		; save DI
		C_GetOneDWordArg ax, di, cx, dx
		push	ds, si
		call	TocDBLock	
		mov	dx, ds
		mov	ax, ds:[si]
		pop	ds, si
		mov	di, bx
		.leave
		ret
TOCDBLOCK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocDBLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock a DB item in the config library's TOC file

CALLED BY:	GLOBAL

PASS:		ax:di - DBItem to lock

RETURN:		*ds:si - item

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocDBLock	proc far
		uses	bx, es, di
		.enter
		call	LoadDSDGroup
		mov	bx, ds:[tocFileHandle]
		
		call	DBLock
		segmov	ds, es, si
		mov	si, di
		
		.leave
		ret
TocDBLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocDBLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the map item of the Toc file

CALLED BY:	TocLockCategoryArray, TocLockDiskArray

PASS:		nothing 

RETURN:		*ds:si - map item

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocDBLockMap	proc near
		uses	bx,ax,di
		.enter
		call	LoadDSDGroup
		mov	bx, ds:[tocFileHandle]
		call	DBGetMap
		call	TocDBLock
		.leave
		ret
TocDBLockMap	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocDBUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock a db item in the TOC file.

CALLED BY:	internal (UTILITY)

PASS:		ds - segment to unlock

RETURN:		nothing 

DESTROYED:	nothing - flags preserved 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocDBUnlock	proc far
		uses	es
		.enter
		segmov	es, ds
		call	DBUnlock
		.leave
		ret
TocDBUnlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TocDBDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the Toc Dbitem as dirty

CALLED BY:	UTILITY

PASS:		ds - segment of dbitem to mark dirty

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TocDBDirty	proc near
		uses	es
		.enter
		segmov	es, ds
		call	DBDirty
		.leave
		ret
TocDBDirty	endp

