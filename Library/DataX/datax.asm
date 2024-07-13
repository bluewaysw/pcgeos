COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		datax.asm

AUTHOR:		Robert Greenwalt, Nov  5, 1996

ROUTINES:
	Name			Description
	----			-----------
	DataxEntry		library entry point

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 5/96   	Initial revision


DESCRIPTION:
		
	

	$Id: datax.asm,v 1.1 97/04/04 17:54:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Init		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataxEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine required b/c we're a library.

CALLED BY:	Kernel
PASS:		among other things:
		di = LibraryCallType
RETURN:		carry clear to indicate happiness
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	robertg	11/ 5/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataxEntry	proc	far
	ForceRef DataxEntry
	uses	bx, ds, ax, di, cx
	.enter
	;
	; Load up our dgroup and check for the clients that come and
	; go, speaking of M
	;
		mov	bx, handle dgroup
		call	MemDerefDS

		cmp	di, LCT_NEW_CLIENT
		jne	notNewClient
		inc	ds:[intRefCount]
		jmp	done
notNewClient:
		cmp	di, LCT_CLIENT_EXIT
		jne	done
		dec	ds:[intRefCount]
		ja	done
	;
	; all've gone.  self destruct
	;
		mov	cx, cs
		call	MemSegmentToHandle
		mov	bx, cx
		call	MemOwner
		mov	ax, MSG_DXH_KILL_SELF
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:	
	clc
	.leave
	ret
DataxEntry	endp

Init		ends
