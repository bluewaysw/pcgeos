COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Hash Library
FILE:		hIndexEC.asm

AUTHOR:		Paul L. DuBois, Nov 18, 1994

ROUTINES:
	Name			Description
	----			-----------
    GLB ECCheckHashTable	Do some validity checking on a hash table

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/18/94   	Initial revision


DESCRIPTION:
	EC code for the index chunk of a hash table

	$Id: hindexec.asm,v 1.1 97/05/30 06:48:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckHashTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some validity checking on a hash table

CALLED BY:	GLOBAL
PASS:		*ds:si	- table
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	May fatal error
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	11/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckHashTable	proc	far
if ERROR_CHECK
		push	ax, bx, di

	; validate the chunk
		Assert	chunk, si, ds
		mov	di, ds:[si]

	; check (bytes taken up by list heads) + (header size) = chunk size
		mov	ax, ds:[di].HTH_tableSize
		tst	ax
		ERROR_Z	HASH_TABLE_BAD_TABLE_SIZE
		shl	ax
		add	ax, ds:[di].HTH_headerSize
		ChunkSizePtr	ds, di, bx
		cmp	ax, bx
		ERROR_NZ HASH_TABLE_CORRUPT

	; validate pointers within the header
PrintMessage <fix up this ec code?>
;		Assert	vfptr, ds:[di].HTH_hashFunction
;		Assert	vfptr, ds:[di].HTH_compFunction
		Assert	chunk, ds:[di].HTH_heap, ds

		mov	ax, ds:[di].HTH_flags
		and	ax, mask HTF_ENTRY_SIZE
		tst	ax
		ERROR_Z	HASH_TABLE_CORRUPT
		cmp	ax, 4
		ERROR_A	HASH_TABLE_CORRUPT
		
		pop	ax, bx, di
endif
	ret
ECCheckHashTable	endp

ECCode	ends
