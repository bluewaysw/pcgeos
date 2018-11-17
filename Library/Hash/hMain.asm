COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Hash library
FILE:		hMain.asm

AUTHOR:		Paul L. DuBois, Nov  7, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB HASHTABLEHASH		C stub for HashTableHash

    GLB HashTableHash		Hash a string

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/ 7/94   	Initial revision


DESCRIPTION:
	Stuff which doesn't fit in other files.

	$Id: hmain.asm,v 1.1 97/05/30 06:48:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include geos.def
include localize.def

MainCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HASHTABLEHASH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for HashTableHash

CALLED BY:	GLOBAL

C DECLARATION:	extern word
			_far _pascal HashTableHash(char*);

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
HASHTABLEHASH	proc	far	hashStr: fptr.char
public HASHTABLEHASH
	uses	ds,si
	.enter
		lds	si, ss:[hashStr]
PrintMessage <remove swatting code for release version>
patchMeHere::
		nop
hash1::
		call	HashTableHash
		jmp	done
.warn -unreach
hash2::
		call	HashTableHash2
.warn @unreach
done:
	.leave
	ret
HASHTABLEHASH	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashTableHash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inspired by original sdbm hash3 function

CALLED BY:	GLOBAL
PASS:		ds:si	- ASCIIZ string to search
RETURN:		ax	- hash value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	thanks to hilfinger who used Duff's device as an example in 164.
	i won't use it here.

	original fn was:

	hash = 0
	foreach char C in string
	    h = C + 65599*h (65599 = 0x0001 003f)

	however, we don't care about any of the high words, so just multiply
	by the low word of (ie, 0x3f)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashTableHash	proc	far
	uses	bx,cx,dx,si
	.enter

		clr	cx		; cx holds hash val
		mov	bx, 0x3f

		lodsb							
		tst	al
DBCS <		jnz	hashLoop					>
DBCS <		tst	{byte}ds:[si]
		jz	done						
hashLoop:
	; cx - hash
	; al - non-null char
	; compute cx <- hash * 3fh + char
		xchg	ax, cx		; cl <- char, ax <- hash
		mul	bx		; ax <- low(h*3f)
		clr	ch		; cx <- char
		add	cx, ax		; cx <- char + low(h*3f)
		lodsb
		tst	al
DBCS <		jnz	doloop						>
DBCS <		tst	{byte}ds:[si]					>
DBCS < doloop:								>
		loopnz	hashLoop
done:
		mov_tr	ax, cx
	.leave
	ret
HashTableHash	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HashTableHash2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inspired by a bsd hash4 function

CALLED BY:	GLOBAL
PASS:		ds:si	- ASCIIZ string to hash
RETURN:		ax	- hash value
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	hash = 0
	foreach char in string
	     hash  = (hash shl 5) + hash + char

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HashTableHash2	proc	far
	uses	bx,cx,dx,si
	.enter

		clr	bx		; hash = 0
		clr	ah		; so we can use ax as char value
		mov	cl, 5		; for the shl

		lodsb
		tst	al
		jz	done
hashLoop:
	; al - non-null char
	; bx - hash
		add	ax, bx		; ax <- hash + char
		shl	bx, cl		; bx <- hash shl 5
		add	bx, ax		; bx <- hash shl 5 + hash + char
		lodsb
		tst	al
		loopnz	hashLoop
done:
		mov_tr	ax,bx
	.leave
	ret
HashTableHash2	endp

MainCode	ends
