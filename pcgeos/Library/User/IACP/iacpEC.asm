COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		iacpEC.asm

AUTHOR:		Adam de Boor, Oct 28, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/28/92	Initial revision


DESCRIPTION:
	Error-checking code for IACP, of course.
		

	$Id: iacpEC.asm,v 1.1 97/04/07 11:47:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IACPCommon	segment	resource

if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPValidateConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed IACPConnection is copacetic

CALLED BY:	(INTERNAL)
PASS:		*ds:bp	= IACPConnectionStruct
RETURN:		only if structure valid
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPValidateConnection proc	far
		uses	si, ax, bx, cx, di
		.enter
	;
	; Make sure the handle itself is ok.
	; 
		mov	si, bp
		call	ECLMemValidateHandle

		mov	si, ds:[si]
		tst	si		; that allows free handles; we don't
		ERROR_Z	IACP_INVALID_CONNECTION
	;
	; Validate the link to the next thing.
	; 
		mov	si, ds:[si].IACPCS_next
		tst	si
		jz	linkOK
		call	ECLMemValidateHandle
		tst	{word}ds:[si]
		ERROR_Z	IACP_INVALID_CONNECTION
linkOK:
	;
	; Now check all the ODs
	; 
		mov	si, ds:[bp]
		ChunkSizePtr	ds, si, cx
		sub	cx, offset IACPCS_client
		shr	cx
		shr	cx
		add	si, offset IACPCS_client
odLoop:
		lodsw
		mov_tr	bx, ax
		lodsw
		xchg	ax, bx
		push	si
		mov_tr	si, ax
		tst	bx		; client/server gone?
		jz	nextOD		; yes -- ok
		call	ECCheckOD
nextOD:
		pop	si
		loop	odLoop
		.leave
		ret
IACPValidateConnection endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IACPValidateConnectionNoDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed IACPConnection is ok when we haven't
		locked the IACPListBlock down

CALLED BY:	(INTERNAL)
PASS:		bp	= IACPConnection
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IACPValidateConnectionNoDS proc	far
		uses	ds
		.enter
		call	IACPLockListBlockShared
		call	IACPValidateConnection
		call	IACPUnlockListBlockShared
		.leave
		ret
IACPValidateConnectionNoDS endp
endif

IACPCommon		ends
