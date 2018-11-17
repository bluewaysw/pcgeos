COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		hash library
FILE:		hc.asm

AUTHOR:		Paul L. DuBois, Nov 21, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB HASHTABLERESIZE		C stub for HashTableResize

    GLB HASHTABLECREATE		C stub for HashTableCreate

    GLB HASHTABLEADD		C stub for HashTableAdd

    GLB HASHTABLEREMOVE		C stub for both HashTableLookup and
				HashTableRemove

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/21/94   	Initial revision


DESCRIPTION:
	C stubs for hash table routines.
	Functions in this file default to pascal calling convention.

	$Id: hc.asm,v 1.1 97/05/30 06:48:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CCode	segment	resource
SetGeosConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HASHTABLERESIZE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for HashTableResize

CALLED BY:	GLOBAL

C DECLARATION:	extern Boolean _far _pascal
		    HashTableResize(optr ht, word numBuckets);

PSEUDO CODE/STRATEGY:
	Returns FALSE on failure		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HASHTABLERESIZE	proc	far	ht: optr, numBuckets: word
public HASHTABLERESIZE
	;uses	cs,ds,es,si,di
	.enter
		mov	bx, ss:[ht].high
		call	MemDerefDS
		mov	si, ss:[ht].low
		mov	cx, ss:[numBuckets]
		call	HashTableResize
		mov	ax, 1		; assume success
		jnc	done
		clr	ax		; signal failure
done:
	.leave
	ret
HASHTABLERESIZE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HASHTABLECREATE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for HashTableCreate

CALLED BY:	GLOBAL

extern	ChunkHandle _pascal HashTableCreate
	(MemHandle mh,
	 HashTableFlags flags,
	 word headerSize,
	 word numHeads,
	 PCB(word, hashFn, (dword data))
	 PCB(Boolean, compFn, (dword cbData, dword eltData)));

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HASHTABLECREATE	proc	far				\
	mh: hptr,	flags: HashTableFlags,		\
	hSize: word,	nHeads: word,			\
	hashFn: vfptr,	compFn: vfptr
public HASHTABLECREATE
	uses	ds
	.enter
		mov	bx, ss:[mh]
		call	MemDerefDS
		clr	al
		mov	bx, ss:[flags]
		mov	cx, ss:[hSize]
		mov	dx, ss:[nHeads]
		pushdw	ss:[compFn]
		pushdw	ss:[hashFn]
		call	HashTableCreate
		jnc	success
		clr	ax		; signal failure
success:
		add	sp, 2*(size vfptr)
	.leave
	ret
HASHTABLECREATE	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HASHTABLEADD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for HashTableAdd

CALLED BY:	GLOBAL

C DECLARATION:	extern Boolean
		    _pascal HashTableAdd(optr ht, dword eltData);

PSEUDO CODE/STRATEGY:
	Return FALSE if element wasn't added.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HASHTABLEADD	proc	far	ht: optr, eltData: dword
public HASHTABLEADD
	uses	ds,si
	.enter
		mov	bx, ht.high
		call	MemDerefDS
		mov	si, ht.low
		movdw	cxdx, ss:[eltData]
		call	HashTableAdd	; stc if not added
		mov	ax, 1		; assume success
		jnc	done
		clr	ax
done:
	.leave
	ret
HASHTABLEADD	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HASHTABLEREMOVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for both HashTableLookup and HashTableRemove

CALLED BY:	GLOBAL

C DECLARATION:	extern Boolean _far _pascal
			HashTableLookup(optr ht, word hash,
					dword cbData, dword* eltData);

PSEUDO CODE/STRATEGY:
	HT_LookupLow performs the real work of HashTableLookup and
	HashTableRemove -- just call that instead.  This routine is
	used for both HASHTABLELOOKUP and HASHTABLEREMOVE.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/21/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HASHTABLEREMOVE	proc	far	ht: optr, hash: word,			\
				cbData: dword, eltData: fptr.dword
public HASHTABLEREMOVE
	uses	ds,si

		mov	bx, 1		; tell HT_LookupLow to remove
		jmp	callIt

HASHTABLELOOKUP	label	far
public HASHTABLELOOKUP
		clr	bx		; tell HT_LookupLow not to remove

callIt:
	.enter
		push	bx
		mov	bx, ht.high
		call	MemDerefDS
		pop	bx

		mov	si, ht.low
		mov	ax, ss:[hash]
		movdw	cxdx, ss:[cbData]
		call	HT_LookupLow	; carry set if not successful
		mov	ax, 0		; assume not.  don't use clr here
		jc	notFound

	; Success -- fill in *eltData and return true
	;
		lds	si, ss:[eltData]
		movdw	ds:[si], cxdx
		mov	ax, 1

notFound:
	.leave
	ret
HASHTABLEREMOVE	endp

SetDefaultConvention
CCode	ends
