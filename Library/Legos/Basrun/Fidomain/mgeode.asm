COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		mGeode.asm

AUTHOR:		Paul L. DuBois, Nov 30, 1994

ROUTINES:
	Name			Description
	----			-----------
    EXT ClientAddLib		Add to a FidoTask's library array

    EXT ClientAddDriver		Add to a FidoTask's driver array

    EXT ClientFreeGeodes	Gracefully destroy a FidoTask block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/30/94   	Initial revision


DESCRIPTION:
	Maintains lists of geodes that need to be freed (libraries and
	drivers).

	$Id: mgeode.asm,v 1.2 98/10/05 12:55:32 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MainCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClientAddLib
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add to a FidoTask's library array

CALLED BY:	EXTERNAL
PASS:		ax	- Handle of library
		bx	- hptr.FidoTask
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
	May resize client block, invalidating segment pointers to it.
	May shuffle chunks around inside the client block.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClientAddLib	proc	far
	uses	ax,bx,cx,ds,si
	.enter
		call	TaskLockDS
		mov_tr	bx, ax		; bx <- library handle

	; append a word to the chunk
		mov	ax, ds:[FT_openLibs]
		ChunkSizeHandle	ds, ax, si
		mov	cx, si
		add	cx, 2
		call	LMemReAlloc
		
	; increment count and fill in the word
		mov_tr	si, ax
		mov	si, ds:[si]	; ds:si <- ClientLibraries
EC <		cmp	ds:[si].CL_unused, CL_MAGIC_NUMBER		>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>

if ERROR_CHECK
	; See if the lib's already there -- shouldn't be
		push	es, di, ax, cx
		mov	cx, ds:[si].CL_count
		jcxz	notFound
		mov	di, si
		segmov	es, ds, ax
		add	di, offset CL_data	; es:di <- string of handles
		mov	ax, bx			; ax <- GeodeHandle
		repne	scasw
		ERROR_E	FIDO_LIB_ALREADY_ADDED
notFound:		
		pop	es, di, ax, cx
endif

		inc	ds:[si].CL_count
		add	si, cx		; ds:si points to end of chunk
		mov	ds:[si-2], bx
		
		call	TaskUnlockDS
	.leave
	ret
ClientAddLib	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClientAddDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add to a FidoTask's driver array

CALLED BY:	EXTERNAL
		FidoOpenModule
PASS:		ax	- driver handle
		bx	- hptr.FidoTask
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
	Grabs globals semaphore for a bit.
	May resize client block, invalidating segment pointers to it.
	May shuffle chunks around inside the client block.

PSEUDO CODE/STRATEGY:
	Could save some bytes by taking out code common to this and
	ClientAddLib, but it's pretty minimal

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClientAddDriver	proc	far
	uses	ax,bx,cx,ds,si
	.enter
		call	TaskLockDS
		mov_tr	bx, ax		; bx <- driver

	; append a word to the chunk
		mov	ax, ds:[FT_openDrivers]
		ChunkSizeHandle	ds, ax, si
		mov	cx, si
		add	cx, 2
		call	LMemReAlloc
		
	; increment count and fill in the word
		mov_tr	si, ax
		mov	si, ds:[si]	; ds:si <- ClientModules
EC <		cmp	ds:[si].CDR_unused, CDR_MAGIC_NUMBER		>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>
		inc	ds:[si].CDR_count
		add	si, cx		; ds:si points to end of chunk
		mov	ds:[si-2], bx
		
		call	TaskUnlockDS
	.leave
	ret
ClientAddDriver	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClientFreeGeodes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gracefully destroy a FidoTask block

CALLED BY:	EXTERNAL, ClientDestroyState
PASS:		ds	- client's private data block
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx
SIDE EFFECTS:
	Makes a bunch of GeodeFree{Library,Driver} calls

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	10/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClientFreeGeodes	proc	far
	uses	si
	.enter

	; Call GeodeFreeLibrary on all the library handles
		mov	si, ds:[FT_openLibs]
		mov	si, ds:[si]
EC <		cmp	ds:[si].CL_unused, CL_MAGIC_NUMBER		>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>
		mov	cx, ds:[si].CL_count
		add	si, offset CL_data
		jcxz	fl_fallThru

freeLib:
		lodsw
		mov	bx, ax

		; Make sure that the low bit is zero...		
		; See FidoRegLoadedCompLibs, which may set
		; the low bit of some of them....
		
		and	ax, 0xfffe
		cmp	ax, bx
		jne	noFree
		call	GeodeFreeLibrary
noFree:		loop	freeLib
fl_fallThru:

	; Call GeodeFreeDriver on all the driver handles
		mov	si, ds:[FT_openDrivers]
		mov	si, ds:[si]
EC <		cmp	ds:[si].CDR_unused, CDR_MAGIC_NUMBER		>
EC <		ERROR_NE FIDO_BAD_MAGIC_NUMBER				>
		mov	cx, ds:[si].CDR_count
		add	si, offset CDR_data
		jcxz	fd_fallThru

freeDriver:
		lodsw
		mov_tr	bx, ax
		call	GeodeFreeDriver
		loop	freeDriver
fd_fallThru:

	.leave
	ret
ClientFreeGeodes	endp

MainCode	ends
