COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/Gen
FILE:		genC.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

DESCRIPTION:
	This file contains C interface routines for the Gen utility routines

	$Id: genC.asm,v 1.1 97/04/07 11:45:11 newdeal Exp $

------------------------------------------------------------------------------@

	SetGeosConvention

C_Gen	segment	resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenCopyChunk

C DECLARATION:	extern word
			_far _pascal GenCopyChunk(MemHandle destBlock,
				MemHandle blk, ChunkHandle chnk,
				word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENCOPYCHUNK	proc	far	destBlock:word,
				blk:word, chnk:word,
				flags:word

	uses	ds, es, si, bp
	.enter

	mov	bx, destBlock
	call	MemDerefDS		; ds = destination block
	mov	bx, blk
	call	MemDerefES		; es = source chunk block
	mov	ax, chnk		; *es:ax = source chunk
	mov	bp, flags
	call	GenCopyChunk		; ax = new chunk
	.leave
	ret
GENCOPYCHUNK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenInsertChild

C DECLARATION:	extern void
			_far _pascal GenInsertChild(
				MemHandle mh, ChunkHandle chnk,
				optr childToAdd,
				optr referenceChild,
				word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENINSERTCHILD	proc	far	mh:word, chnk:word,
				childToAdd:dword,
				referenceChild:dword,
				flags:word

	uses	ds, si, bp
	.enter

	mov	bx, mh
	call	MemDerefDS	; ds = object block
	mov	si, chnk	; *ds:si = object
	mov	cx, childToAdd.high
	mov	dx, childToAdd.low
	mov	ax, referenceChild.high
	mov	bx, referenceChild.low
	mov	bp, flags
	call	GenInsertChild
	.leave
	ret
GENINSERTCHILD	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenSetUpwardLink

C DECLARATION:	extern void
			_far _pascal GenSetUpwardLink(
				MemHandle mh, ChunkHandle chnk,
				optr parent);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENSETUPWARDLINK	proc	far	mh:word, chnk:word,
					parent:dword

	uses	ds, si
	.enter

	mov	bx, mh
	call	MemDerefDS	; ds = object block
	mov	si, chnk	; *ds:si = object
	mov	cx, parent.high	; ^lcx:dx = parent to upward link to
	mov	dx, parent.low
	call	GenSetUpwardLink
	.leave
	ret
GENSETUPWARDLINK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenRemoveDownwardLink

C DECLARATION:	extern void
			_far _pascal GenRemoveDownwardLink(
				MemHandle mh, ChunkHandle chnk,
				word flags);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENREMOVEDOWNWARDLINK	proc	far
	C_GetThreeWordArgs	bx, ax, cx,  dx	; bx=mh, ax=chnk, cx=flags

	uses	ds, si
	.enter

	call	MemDerefDS	; ds = object block
	mov	si, ax		; *ds:si = object
	mov	bp, cx		; bp = flags
	call	GenRemoveDownwardLink
	.leave
	ret
GENREMOVEDOWNWARDLINK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenSpecShrink

C DECLARATION:	extern void
			_far _pascal GenSpecShrink(
				MemHandle mh, ChunkHandle chnk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENSPECSHRINK	proc	far
	C_GetTwoWordArgs	bx, ax,  cx, dx	; bx=mh, ax=chnk

	uses	ds, si
	.enter

	call	MemDerefDS	; ds = object block
	mov	si, ax		; *ds:si = object
	call	GenSpecShrink
	.leave
	ret
GENSPECSHRINK	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenProcessGenAttrsBeforeAction

C DECLARATION:	extern void
			_far _pascal GenProcessGenAttrsBeforeAction(
				MemHandle mh, ChunkHandle chnk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENPROCESSGENATTRSBEFOREACTION	proc	far
	C_GetTwoWordArgs	bx, ax,  cx, dx	; bx=mh, ax=chnk

	uses	ds, si
	.enter

	call	MemDerefDS	; ds = object block
	mov	si, ax		; *ds:si = object
	call	GenProcessGenAttrsBeforeAction
	.leave
	ret
GENPROCESSGENATTRSBEFOREACTION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenProcessGenAttrsAfterAction

C DECLARATION:	extern void
			_far _pascal GenProcessGenAttrsAfterAction(
				MemHandle mh, ChunkHandle chnk);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENPROCESSGENATTRSAFTERACTION	proc	far
	C_GetTwoWordArgs	bx, ax,  cx, dx	; bx=mh, ax=chnk

	uses	ds, si
	.enter

	call	MemDerefDS	; ds = object block
	mov	si, ax		; *ds:si = object
	call	GenProcessGenAttrsAfterAction
	.leave
	ret
GENPROCESSGENATTRSAFTERACTION	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GenFindObjectInTree

C DECLARATION:	extern optr
			_far _pascal GenFindObjectInTree(
				optr startObject,
				dword childTable);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/91		Initial version

------------------------------------------------------------------------------@
GENFINDOBJECTINTREE	proc	far	startObject:optr,
					childTable:fptr

	uses	ds, si, es, di
	.enter
if      FULL_EXECUTE_IN_PLACE
        ;
        ; Make sure the fptr passed in is valid
        ;
EC <    pushdw  bxsi                                            >
EC <    movdw   bxsi,  childTable                                     >
EC <    call    ECAssertValidFarPointerXIP                      >
EC <    popdw   bxsi                                            >
endif

	mov	bx, segment idata
	mov	ds, bx			; ds = fix-uppable segment
	mov	bx, startObject.high	; ^lbx:si = object to start search from
	mov	si, startObject.low
	mov	es, childTable.high	; es:di = table of children to find
	mov	di, childTable.low
	call	GenFindObjectInTree	; ^lcx:dx = object found
	mov	ax, dx			; ^ldx:ax = object found
	mov	dx, cx
	.leave
	ret
GENFINDOBJECTINTREE	endp

C_Gen	ends

	SetDefaultConvention
