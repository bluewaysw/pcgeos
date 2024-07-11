COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Fido Library
FILE:		mentry.asm

AUTHOR:		Paul L. DuBois, Sep  1, 1994

ROUTINES:
	Name			Description
	----			-----------
    PRV FidoLibraryEntry	Entry point for Fido library

    PRV FE_Attach		Create an lmem heap and stick it in
				dgroup:[globals]

    PRV FE_Detach		Delete the heap in dgroup:[globals]

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	9/ 1/94   	Initial revision


DESCRIPTION:
	Entry-point routine and helpers.  None of these routines
	are exported to anyone outside this file.

	$Id: mentry.asm,v 1.2 98/10/05 12:54:32 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MainCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FidoLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for Fido library

CALLED BY:	PRIVATE
		Called only by the kernel
PASS:		di	- LibraryCallType
RETURN:		
DESTROYED:	can destroy everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/ 5/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FidoLibraryEntry	proc	far
		shl	di, 1
		call	cs:[FidoEntryTable][di]
		ret

FidoEntryTable		nptr.near	\
	fle_attach,		;LCT_ATTACH
	fle_detach,		;LCT_DETACH
	doNothing,		;LCT_NEW_CLIENT
	doNothing,		;LCT_NEW_CLIENT_THREAD
	doNothing,		;LCT_CLIENT_THREAD_EXIT
	doNothing		;LCT_CLIENT_EXIT
.assert length FidoEntryTable eq LibraryCallType

fle_attach:
		call	FE_Attach
		retn

fle_detach:
		call	FE_Detach
		retn
doNothing:
		clc
		retn
FidoLibraryEntry	endp
ForceRef	FidoLibraryEntry

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FE_Attach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an lmem heap and stick it in dgroup:[globals]

CALLED BY:	PRIVATE
		FidoLibraryEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/30/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FE_Attach	proc	near
	uses ax,bx,cx, ds,si
	.enter
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS
		pop	bx

	; Create the block containing global state; save handle
	; in dgroup:[globals], making sure it's owned by fido
	;
		mov	ax, LMEM_TYPE_GENERAL
		mov	cx, size FidoGlobalsHeader
		call	MemAllocLMem	; bx <- handle
		mov	ax, (0 shl 8) or (mask HF_SHARABLE)
		call	MemModifyFlags
		mov	ax, handle 0
		call	HandleModifyOwner
		mov	ds:[globals], bx

	; Now create a few arrays in there.  Save the
	; chunk handles in the header of the lmem block.
	;
		call	MemLock
		mov	ds, ax		; ds <- lmem block
		
	; Clients
		mov	cx, size FidoClients
		call	LMemAlloc
		mov	ds:[FGH_clients], ax
		mov_tr	si, ax
		mov	si, ds:[si]	; ds:si <- FidoClients
		clr	ds:[si].FC_count
EC <		mov	ds:[si].FC_unused, FC_MAGIC_NUMBER		>

		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		
	.leave
	ret
FE_Attach	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FE_Detach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the heap in dgroup:[globals]

CALLED BY:	PRIVATE
		FidoLibraryEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	EC:	dgroup:[globals]

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/31/94		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FE_Detach	proc	near
	uses	ds, bx
	.enter
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS
		pop	bx

		mov	bx, ds:[globals]
EC <		mov	ds:[globals], 0xcccc				>
		call	MemFree
	.leave
	ret
FE_Detach	endp

MainCode	ends
