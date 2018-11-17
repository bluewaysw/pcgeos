COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/DBase
FILE:		dbaseC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the lmem routines

	$Id: dbaseC.asm,v 1.1 97/04/05 01:17:39 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Common	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBGetMap

C DECLARATION:	extern DBGroupAndItem
			_pascal DBGetMap(DBFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBGETMAP	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	push	di
	call	DBGetMap
	mov_trash	dx, ax		;dx = group
	mov_trash	ax, di		;ax = item
	pop	di
	ret

DBGETMAP	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBLockGetRefUngrouped

C DECLARATION:	extern void *
			_pascal DBLockGetRefUngrouped(DBFileHandle file,
						DBGroup group, DBItem item
						optr *refPtr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBLOCKGETREFUNGROUPED	proc	far	file:word, dbgroup:word, item:word,
					refPtr:fptr
						uses di, es
	.enter

	mov	ax, dbgroup
	mov	bx, file
	mov	di, item
	call	DBLock
	mov	dx, es
	mov	cx, es:[di]		;save offset

	mov_tr	ax, di
	mov	bx, es:[LMBH_handle]

	les	di, refPtr
	stosw				;store chunk
	mov_tr	ax, bx
	stosw				;store handle

	mov_tr	ax, cx			; ax <- offset (dx:ax <- fptr)

	.leave
	ret

DBLOCKGETREFUNGROUPED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBRawAlloc

C DECLARATION:	extern DBGroupAndItem
			_pascal DBRawAlloc(DBFileHandle file,
						DBGroup group,
						word size);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBRAWALLOC	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = grp, cx = sz

	push	di
	call	DBAlloc
	mov_trash	dx, ax		;dx = group
	mov_trash	ax, di		;ax = item
	pop	di
	ret

DBRAWALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBReAllocUngrouped

C DECLARATION:	extern void
		    _pascal DBReAllocUngrouped(DBFileHandle file,
						    DBGroupAndItem id,
						    word size);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBREALLOCUNGROUPED	proc	far	file:word, id:DBGroupAndItem,
					sz:word
				uses di
	.enter

	mov	bx, file
	mov	ax, id.DBGI_group
	mov	di, id.DBGI_item
	mov	cx, sz
	call	DBReAlloc

	.leave
	ret

DBREALLOCUNGROUPED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBFreeUngrouped

C DECLARATION:	extern void
			_pascal DBFreeUngrouped(DBFileHandle file,
						     DBGroupAndItem id);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBFREEUNGROUPED	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = grp, cx = it

	xchg	cx, di
	call	DBFree
	xchg	cx, di
	ret

DBFREEUNGROUPED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBGroupAlloc

C DECLARATION:	extern DBGroup
			_pascal DBGroupAlloc(DBFileHandle file);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBGROUPALLOC	proc	far
	C_GetOneWordArg	bx,   ax,cx	;bx = file

	call	DBGroupAlloc
	ret

DBGROUPALLOC	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBGroupFree

C DECLARATION:	extern void
			_pascal DBGroupFree(DBFileHandle file, DBGroup group);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBGROUPFREE	proc	far
	C_GetTwoWordArgs	bx, ax,   cx,dx	;bx = file, ax = group

	call	DBGroupFree
	ret

DBGROUPFREE	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBInsertAtUngrouped

C DECLARATION:	extern void
		    _pascal DBInsertAtUngrouped(DBFileHandle file,
			                        DBGroupAndItem id,
						word insertOffset,
						word insertCount);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBINSERTATUNGROUPED	proc	far	file:word, id:DBGroupAndItem,
					insertOffset:word, insertCount:word
				uses di
	.enter

	mov	bx, file
	mov	ax, id.DBGI_group
	mov	di, id.DBGI_item
	mov	dx, insertOffset
	mov	cx, insertCount
	call	DBInsertAt

	.leave
	ret

DBINSERTATUNGROUPED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBDeleteAtUngrouped

C DECLARATION:	extern void
		    _pascal DBDeleteAtUngrouped(DBFileHandle file,
		    				DBGroupAndItem id,
						word deleteOffset,
						word deleteCount);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBDELETEATUNGROUPED	proc	far	file:word, id:DBGroupAndItem,
					deleteOffset:word, deleteCount:word
				uses di
	.enter

	mov	bx, file
	mov	ax, id.DBGI_group
	mov	di, id.DBGI_item
	mov	dx, deleteOffset
	mov	cx, deleteCount
	call	DBDeleteAt

	.leave
	ret

DBDELETEATUNGROUPED	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBRawCopyDBItem

C DECLARATION:	extern DBGroupAndItem
		    _pascal DBRawCopyDBItem(VMFileHandle srcFile,
		 			    DBGroupAndItem srcID,
					    VMFileHandle destFile
					    DBGroup destGroup);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBRAWCOPYDBITEM	proc	far	srcFile:hptr, srcID:DBGroupAndItem,
				destFile:hptr, destGroup:word
				uses di
	.enter

	mov	bx, srcFile
	mov	ax, srcID.DBGI_group
	mov	di, srcID.DBGI_item
	mov	bp, destFile	; (no local vars, so nuking BP is ok)
	mov	cx, destGroup
	call	DBCopyDBItem

	mov_tr	dx, ax		; dxax <- item created
	mov_tr	ax, di
	.leave
	ret

DBRAWCOPYDBITEM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBINFOUNGROUPED
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	DBInfoUngrouped

C DECLARATION:	extern Boolean
			_pascal DBInfoUngrouped(VMFileHandle file,
					DBGroupAndItem grpAndItem,
					word *sizePtr)
					
RETURN:		TRUE if group & item are fine (*sizePtr == item size)
		FALSE if group/item is invalid (*sizePtr unchanged)
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/27/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBINFOUNGROUPED proc	far	file:hptr, grpAndItem:DBGroupAndItem, 
				sizePtr:fptr.word
		uses	di, ds
		.enter
		mov	bx, ss:[file]
		mov	ax, ss:[grpAndItem].DBGI_group
		mov	di, ss:[grpAndItem].DBGI_item

		call	DBInfo
		mov	ax, 0		; assume bad
		jc	done
		
		lds	di, ss:[sizePtr]
		mov	ds:[di], cx
		dec	ax
done:
		.leave
		ret
DBINFOUNGROUPED endp


C_Common	ends

;-

C_System	segment resource

COMMENT @----------------------------------------------------------------------

C FUNCTION:	DBSetMapUngrouped

C DECLARATION:	extern void
			_pascal DBSetMapUngrouped(DBFileHandle file,
						  DBGroup group, DBItem item);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
DBSETMAPUNGROUPED	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	;bx = file, ax = grp, cx = it

	xchg	cx, di
	call	DBSetMap
	xchg	cx, di
	ret

DBSETMAPUNGROUPED	endp

C_System	ends

	SetDefaultConvention

