COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Thread
FILE:		threadErrorCheck.asm

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	This file contains error checking routines for the Thread module

	$Id: threadErrorCheck.asm,v 1.1 97/04/05 01:15:16 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckThreadHandle

DESCRIPTION:	Check a thread handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - thread handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


ECCheckThreadHandleFar	proc	far
EC <	call	ECCheckThreadHandle					>
	ret
ECCheckThreadHandleFar	endp
	public	ECCheckThreadHandleFar

if	ERROR_CHECK

ECCheckThreadHandle	proc	near
	call	CheckHandleLegal
	pushf
	push	ds
	LoadVarSeg	ds
	cmp	ds:[bx].HT_handleSig, SIG_THREAD
	ERROR_NZ	ILLEGAL_THREAD
	pop	ds
	popf
	ret

ECCheckThreadHandle	endp



CheckThreadDI	proc	near
	xchg	bx,di
	call	ECCheckThreadHandle
	xchg	bx,di
	ret

CheckThreadDI	endp


CheckThreadSI	proc	near
	xchg	bx,si
	call	ECCheckThreadHandle
	xchg	bx,si
	ret

CheckThreadSI	endp
endif
