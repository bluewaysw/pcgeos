COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR communication protocol	
MODULE:		loopback driver
FILE:		loopbackUtil.asm

AUTHOR:		Steve Jang, Sep  6, 1994

ROUTINES:
	Name			Description
	----			-----------
	AddConnection		adds a connection entry to InfoResource
	RemoveConnection	removes a conncetion entry from InfoResource
	FindConnection		find a connection entry in InfoResource	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94   	Initial revision

DESCRIPTION:
	
	Utilities for loopback function	

	$Id: loopbackUtil.asm,v 1.1 97/04/18 11:57:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoopbackCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a connection entry to LoopbackInfoResource

CALLED BY:	Utility
PASS:		ds	= LoopbackInfoResource segment
		bx	= local port
		dx	= remote port
RETURN:		ax	= connection handle
		ds:si	= connection entry fptr
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddConnection	proc	near
		uses	bx, cx
		.enter
	;
	; allocate a connection entry
	;
		mov	cx, size LoopbackConnection
		clr	al
		call	LMemAlloc		; ax = new chunk handle
		mov	bx, ax			; bx = new chunk handle
		mov	si, ds:[bx]
		mov	ds:[si].LC_localPort, bx
		mov	ds:[si].LC_remotePort, dx
		clr	ds:[si].LC_status
	;
	; add the entry to connection list
	;
		xchg	bx, ds:[LIH_connection]
		mov	ds:[si].LC_next, bx
		
		.leave
		ret
AddConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a connection entry from LoopbackInfoResource

CALLED BY:	Utility
PASS:		bx	= connection handle
RETURN:		carry set if connection entry was not found
DESTROYED:	bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveConnection	proc	near
		uses	ax, di, si, ds
		.enter
	;
	; Find the connection handle
	;
		mov_tr	di, bx		; save connection handle
		mov	bx, handle LoopbackInfoResource
		call	MemLockShared
		mov	ds, ax
		mov_tr	bx, di		; restore connection handle
		call	FindConnection	; ds:si = connection entry
		jc	notFound	; ds:di = field to remove conn. handle
	;
	; Remove the connection entry from list and LMEM block
	;
		mov	ax, ds:[si].LC_next
		xchg	ax, ds:[di]	; ax = connection handle to remove
		call	LMemFree
		mov	bx, handle LoopbackInfoResource
		call	MemUnlockShared
		clc
notFound:
		.leave
		ret
RemoveConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds a connection entry

CALLED BY:	Utility
PASS:		bx	= connection handle
		ds	= LoopbackInfoResource segment
RETURN:		carry set if not found
		otherwise
			ds:si	= connection entry
			ds:di	= memory location that contains the connection
				  handle( for removal )
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindConnection	proc	near
		.enter
		
		mov 	di, offset LIH_connection
		mov	si, ds:[di]
findLoop:
	;
	; di = mem location that contains a connection handle
	; si = connection handle in ds:[di]
	; bx = connection handle to find
	;
		tst	si
		jz	notFound
		cmp	si, bx
		mov	si, ds:[si]		; deref connection handle
		je	found
		mov	di, si
		add	di, offset LC_next
		mov	si, ds:[si].LC_next	; next connection handle
		jmp	findLoop
notFound:
		stc
found:
		.leave
		ret
FindConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyAllConnections
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy all existing connections

CALLED BY:	LoopbackUnregister
PASS:		es	= dgroup
		ds	= LoopbackInfoResource segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	9/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyAllConnections	proc	near
		uses	ax,si
		.enter
	;
	; Start at the beginning of the list
	;
		mov	si, offset LIH_connection
		mov	si, ds:[si]
removeLoop:
		tst	si
		jz	done
		mov	ax, si
		mov	si, ds:[si]
		mov	si, ds:[si].LC_next
		call	LMemFree
		jmp	removeLoop
done:
		clr	ds:LIH_connection
		.leave
		ret
DestroyAllConnections	endp

LoopbackCode	ends
