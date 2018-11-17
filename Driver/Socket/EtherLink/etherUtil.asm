COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet driver
FILE:		etherUtil.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:
	Name			Description
	----			-----------
	AddConnection		adds a connection entry to InfoResource
	RemoveConnection	removes a conncetion entry from InfoResource
	FindConnection		find a connection entry in InfoResource	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	07/08/98	Initial revision

DESCRIPTION:
	
	Utilities for handling connections.

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EtherCode	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds a connection entry to EtherInfoResource

CALLED BY:	INTERNAL
PASS:		ds	-> EtherInfoResource segment
		bx	-> local IP port #
		dx	-> remote IP port #
RETURN:		ax	<- connection chunk handle
		ds:si	<- connection entry fptr
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/24/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddConnection	proc	near
		uses	bx, cx
		.enter
	;
	; Allocate a connection entry
	;
		mov	cx, size EtherConnection
		clr	al
		call	LMemAlloc	; ax <- new chunk handle

		mov	bx, ax			; bx = new chunk handle
		mov	si, ds:[bx]
		clr	ds:[si].EC_connectionSem
		clr	ds:[si].EC_status
		mov	ds:[si].EC_localPort, bx
		mov	ds:[si].EC_remotePort, dx
		clr	ds:[si].EC_remoteConnection

	;
	; Add the entry to connection list atomically
	;
		pushf
		INT_OFF
		xchg	bx, ds:[EIH_connection]
		mov	ds:[si].EC_next, bx
		popf
		
		.leave
		ret
AddConnection	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes a connection entry from EtherInfoResource

CALLED BY:	INTERNAL
PASS:		bx	-> connection handle
RETURN:		carry set if connection entry was not found
DESTROYED:	bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/24/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveConnection	proc	near
		uses	ax, di, si, ds
		.enter
	;
	; Find the connection, given its handle
	;
		push	bx			; save connection handle
		mov	bx, handle EtherInfoResource
		call	MemLockShared	; ax <- segment of EIR
		mov	ds, ax
		pop	bx			; restore connection handle

		call	FindConnection	; ds:si <- connection entry
					; ds:di <- field to remove conn. handle
		jc	done ; => Which connection?

	;
	; Unlink the connection entry from list...
	;
		mov	ax, ds:[si].EC_next
		xchg	ax, ds:[di]	; ax = connection handle to remove

	;
	; ... then remove it from the block
	;
		call	LMemFree

		mov	bx, handle EtherInfoResource
		call	MemUnlockShared
		clc
done:
		.leave
		ret
RemoveConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds a connection entry

CALLED BY:	INTERNAL
PASS:		bx	-> connection handle
		ds	-> EtherInfoResource segment
RETURN:		carry set if not found
		otherwise
			ds:si	<- connection entry
			ds:di	<- memory location that contains the connection
				  handle( for removal )
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindConnection	proc	near
		.enter
		
		mov 	di, offset EIH_connection
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
		add	di, offset EC_next
		mov	si, ds:[si].EC_next	; next connection handle
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

CALLED BY:	EtherUnregister
PASS:		es	= dgroup
		ds	= EtherInfoResource segment
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	6/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyAllConnections	proc	near
		uses	ax,si
		.enter
removeLoop:
	;
	; Make sure there's something left...
		mov	si, ds:[EIH_connection]
		tst	si
		jz	done	; => No more...

		call	RemoveConnection
		jmp	removeLoop

done:
		clr	ds:[EIH_connection]
		.leave
		ret
DestroyAllConnections	endp

EtherCode	ends

ResidentCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherNewThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call client entry routine with a new thread

CALLED BY:	SCOIndication_newThread macro
PASS:		cx	= RegisterSetStruct mem handle
RETURN:		never
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherNewThread	proc	far
		mov	bx, cx
		push	bx
		call	MemLock
		mov	ds, ax
		push	ds:RSS_ds, ds:RSS_bx, ds:RSS_es
		mov	ax, ds:RSS_ax
		mov	cx, ds:RSS_cx
		mov	dx, ds:RSS_dx
		mov	bp, ds:RSS_bp
		mov	di, ds:RSS_di
		mov	si, ds:RSS_si
		call	MemUnlock
		pop	ds, bx, es
		SCOIndication
		pop	bx
		call	MemFree
		clr     cx, dx, bp, si
		jmp	ThreadDestroy
EtherNewThread	endp

ResidentCode		ends