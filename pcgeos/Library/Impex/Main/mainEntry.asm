COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/Main
FILE:		mainEntry.asm

AUTHOR:		Don Reeves, May 28, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/28/92		Initial revision

DESCRIPTION:
	Contains code to implement the library entry point	

	$Id: mainEntry.asm,v 1.1 97/04/04 23:44:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImpexLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for Impex Library
		Allocates or frees thread list semaphore

CALLED BY:	EXTERNAL

PASS:		DI	= LibraryCallType
 
RETURNED:	Carry	= Clear

DESTROYED:	ax, bx, cx, ds, es

PSEUDO CODE/STRATEGY:
		If attaching, allocate thread list
		If new client, increment client count.
		If client exit, decrement client count, and if this is
		the last client, kill the impex thread.
		If detaching, free thread list

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	jimmy	3/91		Initial version
	jenny	9/91		Added client counting and impex exit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexLibraryEntry	proc	far

	; A little set-up work
	;
NOFXIP <	segmov	es, dgroup, ax					>
FXIP <		mov	bx, handle dgroup				>
FXIP <		call	MemDerefES		; es = dgroup		>
	cmp	di, LCT_ATTACH
	jne	doDetach

	; If attaching, allocate the thread list handle/semaphore
	;
	mov	ax, size ThreadListHeader
	mov	bx, handle 0
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HF_SHARABLE)
	call	MemAllocSetOwner		; allocate memory & set owner
	jc	exit				; branch if error
	mov	es:[threadList], bx		; save away handle
	mov	ds, ax 
	mov	ds:[TLH_handle], bx
	mov	ds:[TLH_size], size ThreadListHeader
	call	MemUnlock			; unlock the thread list
	jmp	done

	; If detaching, free thread list
doDetach:
	cmp	di, LCT_DETACH
	jne	done
	mov	bx, es:[threadList]
	call	MemFree
done:
	clc					; return success
exit:
	ret
ImpexLibraryEntry	endp
ForceRef		ImpexLibraryEntry

ResidentCode	ends
