COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		Net Utils
FILE:		hugelmemC.asm

AUTHOR:		Andy Chiu, Mar  7, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96   	Initial revision


DESCRIPTION:
	C stubs for the huge lmem routines
		


	$Id: hugelmemC.asm,v 1.1 97/04/05 01:25:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

HugeLMemCode	segment	resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemCreate

C DECLARATION:

HugeLMemHandle
	_pascal HugeLMemCreate(word maxBlocks, word minSize, word maxSize);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMCREATE	proc	far	
		.enter

		C_GetThreeWordArgs	ax, bx, cx, dx
					; ax <- maxBlocks
					; bx <- minSize
					; cx <- maxSize

		call	HugeLMemCreate	; bx <- handle
		jc	error

		mov_tr	ax, bx		; ax <- handle
exit:
		.leave
		ret
error:
		clr	ax
		jmp	exit
HUGELMEMCREATE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemForceDestroy

C DECLARATION:

	void 
	  _pascal HugeLMemForceDestroy(HugeLMemHandle handle);

	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMFORCEDESTROY	proc	far	
		.enter

		C_GetOneWordArg	bx, ax, cx	; bx <- HugeLMemHandle
		call	HugeLMemForceDestroy

		.leave
		ret
HUGELMEMFORCEDESTROY	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemDestroy

C DECLARATION:	
	Boolean
	  _pascal HugeLMemDestory(HugeLMemHandle handle);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMDESTROY	proc	far
		.enter

		C_GetOneWordArg	bx, ax, cx	; bx <- HugeLMemHandle
		call	HugeLMemDestroy
		jc	error

		clr	ax			; no error

exit:
		.leave
		ret
error:
		mov	ax, TRUE
		jmp	exit
HUGELMEMDESTROY	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemAllocLock

C DECLARATION:	
	Boolean
	  _pascal HugeLMemAllocLock(HugeLMemHandle handle, word chunkSize,
			word timeout, optr *newBufferOptr);
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMALLOCLOCK	proc	far	han:hptr,
					chunkSize:word,
					timeout:word,
					newBufferOptr:fptr
		uses	di, ds
		.enter

		mov	ax, chunkSize
		mov	bx, han
		mov	cx, timeout
		call	HugeLMemAllocLock	; ^lax:cx <- new buffer
						; ds:di <- new buffer

		jc	error

		les	bx, newBufferOptr
		movdw	es:[bx], axcx

		clr	ax			; return value
		
exit:
		.leave
		ret
error:
		mov	ax, TRUE
		jmp	exit
		
HUGELMEMALLOCLOCK	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemFree

C DECLARATION:	
	Boolean
	  _pascal HugeLMemFree(optr hugeLMemOptr);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMFREE	proc	far
		C_GetTwoWordArgs	ax, cx, bx, dx ; ^lax:cx huge lmem optr

		call	HugeLMemFree
		jc	error

		clr	ax		; no error
		
exit:
		ret

error:
		mov	ax, TRUE
		jmp	exit
HUGELMEMFREE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemLock

C DECLARATION:	
	void *
	  _pascal HugeLMemLock(MemHandle handle);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMLOCK	proc	far
		.enter

		C_GetOneWordArg	bx, ax, dx ; bx <- hptr part of hugelmem chunk

		call	HugeLMemLock	; ax <- seg address
		clr	dx
		xchg	dx, ax		; dx:ax <- return value

		.leave
		ret
HUGELMEMLOCK	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemUnlock

C DECLARATION:	
	void
	 _pascal HugeLMemUnlock(HugeLMemHandle handle);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMUNLOCK	proc	far
		.enter

		C_GetOneWordArg	bx, ax, dx ; bx = hptr part of hugelmem chunk

		call	HugeLMemUnlock
		
		.leave
		ret
HUGELMEMUNLOCK	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	HugeLMemRealloc

C DECLARATION:	
	Boolean
	 _pascal HugeLMemRealloc(optr hugeLMemOptr, word size);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	3/ 7/96		Initial Revision

------------------------------------------------------------------------------@
HUGELMEMREALLOC	proc	far
		uses	si,di,bp,ds
		.enter

		C_GetThreeWordArgs	bx, ax, cx, dx
					; ^lbx:ax <- HugeLMemOptr
					; cx      <- size to resize

		call	MemDerefDS	; *ds:ax = handle of hugelmem chunk

		call	HugeLMemReAlloc	; carry set if eror
		jc	error

		clr	ax		; no error

exit:		
		.leave
		ret
error:
		mov	ax, TRUE
		jmp	exit
		
HUGELMEMREALLOC	endp

HugeLMemCode	ends

	SetDefaultConvention






