COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

			GEOWORKS CONFIDENTIAL

PROJECT:	Socket
MODULE:		TCP/IP Driver
FILE:		tcpipLink.asm

AUTHOR:		Jennifer Wu, Jul  8, 1994

ROUTINES:
	Name			Description
	----			-----------
	LinkCreateLinkTable	Create the table for keeping track of link
				connections
	LinkCreateLoopbackEntry	Create the loopback entry in the link table
	LinkCreateMainLinkEntry	Create the main link entry in the link table

	LinkTableAddEntry	Add a new entry into the link table and
				fill in the LinkControlBlock
	LinkTableDeleteEntry	Delete a closed link from the link table.
	LinkTableGetEntry	Get the entry in the link table corresponding
				to the given domain handle
	LinkTableDestroyTable	Free all memory used by the link table.

	LinkGetLocalAddr	Find the local address of the given link

	LinkResolveLinkAddr	Resolve a link address

	LinkStopLinkResolve	Stop resolving link address

	CloseAllLinks		Close all link connections, unregistering
				the link drivers and unloading them
	
	LinkCheckOpen		Check whether a link is opened

	LinkOpenConnection	Open a link connection unless one is 
				already open
	
	LinkCheckIfLoopback	Returns loopback domainhandle if remote
				address for connection is a loopback address

	LinkSetupMainLink	Load the main link driver and register it
	LinkStoreLinkAddress	Store the link address in the LCB
	LinkOpenLink		Tell link driver to establish link connection
	LinkLoadLinkDriver	Load the link driver used by TCP for
				establishing connections
    LinkUnloadLinkDriver    Unload the link driverused by TCP for
				establishing connections

	LinkGetMTU		Get the mtu of the given link.
	LinkGetMediumAndUnit	Get the medium and unit for a link.
	LinkGetMediumAndUnitConnection
				Look for a link over the specified medium
				and unit.
	LinkGetMediumAndUnitConnectionCB

	LinkCheckLocalAddr	Verify the address belongs to the link.

	LinkSendData		Send data over the given link.

	ECCheckLinkDomainHandle	Verify that the domain handle is legal
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/ 8/94		Initial revision

DESCRIPTION:
	

	$Id: tcpipLink.asm,v 1.38 98/06/25 15:31:30 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LinkCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkCreateLinkTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the table for keeping track of link level drivers.
		Initialize it to contain the entry for the loopback link.

CALLED BY:	TcpipInit

PASS:		es	= dgroup

RETURN:		carry set if insufficient memory
		else carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Create the chunk array for the link table in an lmem block
		block and store its optr in dgroup.
		Create an entry for the loopback link.
		Create an entry for the main link.
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkCreateLinkTable	proc	far
		uses	ax, bx, cx, si, ds
		.enter

	;
	; Allocate the LMem block for the link table and make sure
	; we own it.
	;
		mov	ax, LMEM_TYPE_GENERAL
		clr	cx				; default block header
		call	MemAllocLMem			; bx <- block handle
	
		mov	ax, handle 0
		call	HandleModifyOwner

		mov	ax, mask HF_SHARABLE
		call	MemModifyFlags
	;
	; Create the chunk array for the link table and save its
	; optr in dgroup.
	;
		push	bx
		call	MemLockExcl
		mov	ds, ax	
		clr	bx, cx, si, ax		; var size, dflt hdr, alloc chunk
		call	ChunkArrayCreate	; *ds:si = link table
		pop	bx
		jc	noMemory

		movdw	es:[linkTable], bxsi		; ^lbx:si = link table
	;
	; Create loopback entry and entry for main link in the link table.
	;		
		call	LinkCreateLoopbackEntry		
		call	LinkCreateMainLinkEntry
		call	MemUnlockExcl			
		clc
exit:
		.leave
		ret

noMemory:
EC <		WARNING	TCPIP_CANNOT_CREATE_LINK_TABLE		>
		call	MemFree
		stc	
		jmp	exit

LinkCreateLinkTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkCreateLoopbackEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the loopback entry in the link table.  

CALLED BY:	LinkCreateLinkTable

PASS:		*ds:si	= link table

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		ChunkArrayAppend returns new element all zeroed so 
		no need to initialize zero fields.

		Connection handle for the link set to zero since we
		never attempt to open it.
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/24/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkCreateLoopbackEntry	proc	near
		uses	ax, di
		.enter

		mov	ax, size LinkControlBlock
		call	ChunkArrayAppend		; ds:di = new LCB

EC <		call	ChunkArrayPtrToElement					>
EC <		tst	ax							>
EC <		ERROR_NE TCPIP_INTERNAL_ERROR	; loopback must be first!	>
		
		mov	ds:[di].LCB_state, LS_OPEN	; loopback is always open

		mov	ds:[di].LCB_strategy.segment, segment TcpipDoNothing 
		mov	ds:[di].LCB_strategy.offset, offset TcpipDoNothing
		
		mov	ds:[di].LCB_mtu, MAX_LINK_MTU	; no limit on loopback
		mov	ds:[di].LCB_minHdr, TCPIP_SEQUENCED_PACKET_HDR_SIZE
		
		movdw	ds:[di].LCB_localAddr, LOOPBACK_LOCAL_IP_ADDR

		.leave
		ret
LinkCreateLoopbackEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkCreateMainLinkEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the main link entry in the link table.

CALLED BY:	LinkCreateLinkTable

PASS:		*ds:si	= link table

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Allocate basic LinkControlBlock.  When we have an actual
		address for the link, the entry can be resized later.

		ChunkArrayAppend returns the element all zeroed so no
		need to initialize zero fields.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 7/95			Initial version
	jwu	4/19/97			Added closeSem code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkCreateMainLinkEntry	proc	near
		uses	ax, bx, di
		.enter
	;
	; Append a new LinkControlBlock to array.  
	;
		mov	ax, size LinkControlBlock
		call	ChunkArrayAppend		; ds:di = LCB
		
EC <		call	ChunkArrayPtrToElement				>
EC <		cmp	ax, MAIN_LINK_DOMAIN_HANDLE			>
EC <		ERROR_NE TCPIP_INTERNAL_ERROR	; main link must be 2nd!>
	;
	; Set state to closed and allocate sempahores.
	;
		mov	ds:[di].LCB_state, LS_CLOSED
		clr	ds:[di].LCB_openCount		; no open attempts yet

		clr	bx				; initially blocking 
		call	ThreadAllocSem
		mov	ds:[di].LCB_sem, bx
		
		mov	ax, handle 0
		call	HandleModifyOwner

		clr	bx
		call	ThreadAllocSem
		mov	ds:[di].LCB_closeSem, bx

		mov	ax, handle 0
		call	HandleModifyOwner

		.leave
		ret
LinkCreateMainLinkEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkTableAddEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new entry into the link table and fill in the 
		LCB.

CALLED BY:	TcpipAddDomain

PASS:		ax	= client handle
		cl	= min header size
		es:dx	= driver entry point
		bp	= driver handle
		ds	= dgroup

RETURN:		bx	= index of entry in table (used as domain handle)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Append the entry to the chunk array for the link table
		Fill in the information, initializing defaults
		Return index in table

		NOTE:  currently uses default MTU.  Need a way for
			link to specify its MTU.

			Don't need to allocate LCB_sem because only
			main link needs it.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkTableAddEntry	proc	far
		uses	ax, cx, di, si, ds
		.enter
	;
	; Create a new entry at end of array.
	;
		push	ax				; save client handle
		movdw	bxsi, ds:[linkTable]		; ^lbx:si = array
		call	MemLockExcl				
		mov	ds, ax				; *ds:si = array

		mov	ax, size LinkControlBlock
		call	ChunkArrayAppend		; *ds:di = new entry
		pop	ax				; ax = client handle
	;
	; Update all the info in the LinkControlBlock for the given
	; protocol.  
	;						
		movdw	ds:[di].LCB_strategy, esdx
		mov	ds:[di].LCB_minHdr, cl
		mov	ds:[di].LCB_mtu, DEFAULT_LINK_MTU
		mov	ds:[di].LCB_state, LS_CLOSED
		mov	ds:[di].LCB_clientHan, ax
		mov	ds:[di].LCB_drvr, bp
		clr	ds:[di].LCB_linkSize

		call	ChunkArrayPtrToElement		; ax = index #
		
		call	MemUnlockExcl
		
		mov_tr	bx, ax				; bx = index #
							;  aka domain handle
		.leave
		ret
LinkTableAddEntry	endp

COMMENT @----------------------------------------------------------------

C FUNCTION:	LinkTableDeleteEntry

C DECLARATION:	extern void _far
		_far _pascal LinkTableDeleteEntry(word link);

CALLED BY:	TcpipLinkClosed via message queue

SYNOPSIS:	Link closed and there is no registered client.

STRATEGY:
		deref dgroup
		grab reg sem
		if not registered {
			lock link table and get entry
			if link closed {
				grab client handle and driver handle
				push fptr of link strategy on stack
				unlock link table

				call link driver to unregister
				free link driver

				relock link table
				if not main link, delete entry
				count number links left
				if 2 left {
					if main link driver not loaded 
						destroy thread and timer
				}
			}
			unlock link table
		}
		release reg sem
		exit

		NOTE:  This routine MUST be called from driver's thread
		       so that the detach for destroying thread  will not 
		       process until this task is completed.

			Code does not need to P taskSem because there
			are no clients and none will register as long
			as regSem is P-ed.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	1/23/95		Initial version
	jwu	9/22/95		2nd version
-------------------------------------------------------------------------@
	SetGeosConvention

LINKTABLEDELETEENTRY	proc	far		link:word

		uses 	di, si, ds
		.enter
	;
	; Make sure there is still no TCPIP client.
	;
		mov	bx, handle dgroup
		call	MemDerefES
		
		mov	bx, es:[regSem]
		call	ThreadPSem

		tst	es:[regStatus]
		LONG	jne	exit
	;
	; Make sure link is still closed.
	;
		movdw	bxsi, es:[linkTable]
		call	MemLockExcl
		mov	ds, ax				; *ds:si = link table
		mov	ax, link
		call	ChunkArrayElementToPtr		; ds:di = LCB

EC <		ERROR_C TCPIP_INTERNAL_ERROR 	; link value out of bounds!	>
		cmp	ds:[di].LCB_state, LS_CLOSED
		jne	done		
	;
	; Unregister and free link driver, unlocking link table during
	; call out of TCP.
	;
		clr	dx
		xchg	dx, ds:[di].LCB_drvr

		mov	cx, ds:[di].LCB_clientHan
		pushdw	ds:[di].LCB_strategy
		call	MemUnlockExcl

		mov	bx, cx				; bx = client handle
		mov	di, DR_SOCKET_UNREGISTER
		call	PROCCALLFIXEDORMOVABLE_PASCAL

EC <		tst	dx						>
EC <		ERROR_E TCPIP_INTERNAL_ERROR	; missing drvr handle!	>	
		mov	bx, dx				; bx = driver handle
		call	GeodeFreeDriver
	;
	; Remove entry from link table and find out how many are left.
	; Do NOT remove the main link entry!
	;
		mov	bx, es:[linkTable].handle
		call	MemLockExcl
		mov	ds, ax				; *ds:si = array

		mov	ax, link
		cmp	ax, MAIN_LINK_DOMAIN_HANDLE
		je	getCount

		mov	cx, 1				; just delete one
		call	ChunkArrayDeleteRange
getCount:
	;
	; Okay to destroy thread and timer if only two links (loopback
	; and main link) are left and the main link driver is not loaded.
	;
		call	ChunkArrayGetCount
		cmp	cx, NUM_FIXED_LINK_ENTRIES
		ja	done

		mov	ax, MAIN_LINK_DOMAIN_HANDLE
		call	ChunkArrayElementToPtr		; ds:di = LCB
		tst	ds:[di].LCB_drvr
		jne	done
		call	TcpipDestroyThreadAndTimerFar
done:
		call	MemUnlockExcl
exit:
		mov	bx, es:[regSem]
		call	ThreadVSem

		.leave
		ret

LINKTABLEDELETEENTRY	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkTableGetEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the entry in the link table corresponding to the
		given domain handle.

CALLED BY:	TcpipGetLocalAddr
		TcpipLinkOpened
		TcpipLinkClosed
		TcpipCheckLinkIsMain
		TcpipGetDefaultIPAddr
		LinkGetLocalAddr
		LinkOpenConnection
		LinkGetMediumAndUnit
		LINKGETMTU
		LINKCHECKLOCALADDR
		LINKSENDDATA
		IPAddressControlAddChild

PASS:		bx	= domain handle

RETURN:		ds:di 	= LinkControlBlock 
		bx	= handle of link table (so caller can unlock it)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

NOTE:		Caller MUST NOT have link table locked when calling this.
		Caller MUST unlock link table. (use MemUnlockExcl)
			
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkTableGetEntry	proc	far
		uses	ax, cx, dx, si
		.enter

		mov_tr	dx, bx				; dx = domain handle
		
		mov	bx, handle dgroup
		call	MemDerefDS
		movdw	bxsi, ds:[linkTable]		; ^lbx:si = link table
		call	MemLockExcl
		mov	ds, ax				; *ds:si = link table

		mov_tr	ax, dx				; ax = entry to find
		call	ChunkArrayElementToPtr		; ds:di = LCB
							; cx = element size
EC <		ERROR_C	TCPIP_INTERNAL_ERROR	; invalid entry	# for table	>
		
		.leave
		ret
LinkTableGetEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkTableDestroyTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free all memory used by the link table.

CALLED BY:	TcpipExit

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, di (allowed)

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/29/96			Initial version
	jwu	3/04/97			VSems if clients blocked

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkTableDestroyTable	proc	far

		uses	ds
		.enter
	
	;
	; Make sure no clients are blocked before freeing semaphores.
	;
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry		; ^hbx = link table 

		push	bx
	;
	; Wake up any clients block on LCB_sem.
	;
		tst	ds:[di].LCB_semCount		; no waiters?	
EC <		WARNING_NZ TCPIP_EXITING_WITH_CLIENTS_BLOCKED		>
		jz	checkCloseSem

		mov	bx, ds:[di].LCB_sem
		mov	cx, ds:[di].LCB_semCount			
wakeLoop:
		call	ThreadVSem
		loop	wakeLoop
checkCloseSem:
	;
	; Wake up any clients blocked on LCB_closeSem.
	;
		tst	ds:[di].LCB_closeCount		; no waiters?
EC <		WARNING_NZ TCPIP_EXITING_WITH_CLIENTS_BLOCKED		>
		jz	freeSem

		mov	bx, ds:[di].LCB_closeSem			
		mov	cx, ds:[di].LCB_closeCount
wake2Loop:
		call	ThreadVSem
		loop	wake2Loop
freeSem:
	;
	; The only things to free are the main link's semaphores
	; and the link table.
	;
		mov	bx, ds:[di].LCB_sem
		call	ThreadFreeSem
		mov	bx, ds:[di].LCB_closeSem
		call	ThreadFreeSem
		pop	bx
		call	MemUnlockExcl
		call	MemFree

		.leave
		ret
LinkTableDestroyTable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkGetLocalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	LinkGetLocalAddr

C DECLARATION:	extern dword _far
		_far _pascal LinkGetLocalAddr(word link);

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
LINKGETLOCALADDR	proc	far	
		C_GetOneWordArg bx, ax, cx
		call	LinkGetLocalAddr		; bxcx = addr
		movdw	dxax, bxcx
		ret
LINKGETLOCALADDR	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkGetLocalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the local address of the given link.

CALLED BY:	SocketStoreConnectionInfo
		LINKGETLOCALADDR

PASS: 		bx	= domain handle of link

RETURN:		bxcx	= local address of the link (whether link open/closed)
		carry set if link closed  
		else carry clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkGetLocalAddr	proc	far
		uses	di, si, ds
		.enter

	;
	; Get local address of link and set carry according to 
	; link state.
	;	

		call	LinkTableGetEntry		; ds:di = LCB
							; bx = table's block
		movdw	sicx, ds:[di].LCB_localAddr

		cmp	ds:[di].LCB_state, LS_OPEN		
		je	okay				; carry clear

		stc		
okay:
		call	MemUnlockExcl			; flags preserved
		
		mov	bx, si				; bxcx = local addr
		
		.leave
		ret
LinkGetLocalAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkResolveLinkAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have link driver resolve link address.

CALLED BY:	TcpipResolveAddr

PASS:		ds:si 	= link address string (non-null terminated)
		cx	= link addr size
		dx:bp	= buffer for resolved link addr
		ax	= buffer size (after space for IP addr deducted)

RETURN:		carry set if error
			ax = SocketDrError
		else
			cx = resolved addr size
			dx = access point ID (0 if none)
			ax unchanged

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Load link driver
		Get link driver's strategy routine and have it
		resolve the link address, returning the results.
		Free link driver


REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/10/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkResolveLinkAddr	proc	far
		uses	bx, di, es
		.enter

EC <		tst	cx						>
EC <		ERROR_E TCPIP_INTERNAL_ERROR	; should be non-zero 	>
	;
	; Load link driver and have it resolve the link address.
	;
		call	LinkLoadLinkDriver		; bx = driver handle
		jc	error

		push	ds, si
		call	GeodeInfoDriver			; ds:si = driver info
		movdw	esdi, dssi			
		pop	ds, si
		pushdw	es:[di].DIS_strategy

		mov	di, DR_SOCKET_RESOLVE_ADDR
		call	PROCCALLFIXEDORMOVABLE_PASCAL	

		pushf
		call	LinkUnloadLinkDriver
	;
	; Get access point ID.
	;
		clr	dx				; assume no ID
		cmp	{byte} ds:[si], LT_ID
		jne	done
		mov	dx, ds:[si+1]			; dx = ID
done:
		popf
exit:
		.leave
		ret
error:
		mov	ax, SDE_DRIVER_NOT_FOUND	
		jmp	exit

LinkResolveLinkAddr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkStopLinkResolve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have link driver interrupt resolving an address.

CALLED BY:	TcpipStopResolve

PASS:		ds:si	= link address string (non-null terminated)
		cx	= link addr size

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If no link driver, just exit
		Else, 
			Load link driver
			Get link driver's strategy routine and have it
			stop resolving the link address
			Free link driver

NOTES:
		Load the link driver again to prevent it from 
		exiting unexpectedly while we're stopping a resolve.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 7/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkStopLinkResolve	proc	far
		uses	ax, bx, cx, dx, di, es
		.enter

EC <		tst	cx						>
EC <		ERROR_E TCPIP_INTERNAL_ERROR	; should be non-zero 	>

	;
	; If no link driver, just exit.
	;
		mov	bx, handle dgroup
		call	MemDerefES

		tst_clc	es:[di].LCB_drvr
		jz	exit
	;
	; Load link driver, stop resolve, free driver.
 	;
		call	LinkLoadLinkDriver		; bx = driver handle
		jc	exit

		push	ds, si
		call	GeodeInfoDriver			; ds:si = driver info
		movdw	esdi, dssi
		pop	ds, si

		pushdw	es:[di].DIS_strategy
		mov	di, DR_SOCKET_STOP_RESOLVE
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		call	LinkUnloadLinkDriver		
exit:
		.leave
		ret
LinkStopLinkResolve	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseAllLinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close all link connections, unregistering the link drivers
		and unloading them.

CALLED BY:	TCPIPDETACHALLOWED

PASS:		es	= dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For each link, if the link is opened, close it first.
		Then unregister it and unload the driver.  Delete 
		entry for link if not a fixed entry.

		Caller MUST have regSem P-ed.  There are no clients
		and none can register while caller has regSem P-ed 
		so it's safe to unlock the link table without grabbing
		the task semaphore.

		Can't use ChunkArrayEnum because link table needs to 
		be unlocked.  Not using loop instruction because CX 
		gets used during the loop.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 8/94			Initial version
	jwu	9/25/95			Unlock link table for drvr calls

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseAllLinks	proc	far
		uses	ax, bx, cx, dx, di, si, ds
drvrEntry	local	fptr
		.enter

EC <		tst	es:[regStatus]				>
EC <		ERROR_NE TCPIP_STILL_REGISTERED			>
	;
	; Process each link connection, backwards as entries may be 
	; deleted during enumeration.
	;	
		movdw	bxsi, es:[linkTable]
		call	MemLockExcl
		mov	ds, ax				; *ds:si = link table
		call	ChunkArrayGetCount		; cx = count
		mov	dx, cx				
		dec	dx
closeLoop:		
	;
	; Only process entries where the driver is loaded because only
	; the loopback and main link entries may have a null driver field
	; and these entries never get deleted so code.
	; 
		mov	ax, dx				; ax = index
		call	ChunkArrayElementToPtr		; ds:di = LCB
EC <		ERROR_C TCPIP_INVALID_DOMAIN_HANDLE			>

		clr	cx
		xchg	cx, ds:[di].LCB_drvr
		jcxz	next
	;
	; If the link is open, close it.  Unlock link table during
	; calls outside of the TCP driver.
	;
		push	ax				
		mov	si, ds:[di].LCB_clientHan
		movdw	drvrEntry, ds:[di].LCB_strategy, ax

		mov	al, LS_CLOSED
		xchg	al, ds:[di].LCB_state

		push	ds:[di].LCB_connection	
		call	MemUnlockExcl
		pop	bx				; bx = link connection

		cmp	al, LS_CLOSED
		je	closed

		mov	ax, SCT_FULL
		mov	di, DR_SOCKET_DISCONNECT_REQUEST
		pushdw	drvrEntry
		call	PROCCALLFIXEDORMOVABLE_PASCAL
closed:
	;
	; Unregister and unload driver.  
	;
		mov	bx, si				; bx = client handle
		mov	di, DR_SOCKET_UNREGISTER
		pushdw	drvrEntry
		call	PROCCALLFIXEDORMOVABLE_PASCAL

		mov	bx, cx				; bx = driver handle
	;
	; Must call LinkUnloadLinkDriver for the main link.
	;
	    pop     ax
	    push    ax
	    cmp ax, MAIN_LINK_DOMAIN_HANDLE
	    jne notMain
	    call    LinkUnloadLinkDriver
	    jmp delete
notMain:
		call	GeodeFreeDriver
	;
	; Delete entries for all links other than the loopback and main
	; link.  
	;
delete:
		movdw	bxsi, es:[linkTable]
		call	MemLockExcl
		mov	ds, ax				; *ds:si = link array
		pop	ax				; ax = link handle

		cmp	ax, MAIN_LINK_DOMAIN_HANDLE
		jbe	next

		mov	cx, 1
		call	ChunkArrayDeleteRange
next:
		dec	dx
		LONG	jns	closeLoop
		call	MemUnlockExcl

		.leave
		ret
CloseAllLinks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkCheckOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the main link is open and that it has the same
		link address.

CALLED BY:	TcpipSendDatagramCommon

PASS:		ds:si	= remote address (non-null terminated string)
			(FXIP: address cannot be in a movable code resource)

		NOTE:  SocketInfoBlock MUST NOT be locked and taskSem
			MUST NOT be P-ed when this is called!

RETURN:		carry clear if open
			ax	= link handle
		else carry set
			ax	= SocketDrError

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/24/96			Initial version
	ed	6/28/00			DHCP support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkCheckOpen	proc	far
		uses	bx, cx, di, si, es
		.enter
	;
	; If we are using the loopback link, no need to open a link.
	;
		call	LinkCheckIfLoopback	; ax = loopback domain handle
		jnc	exit

	;
	; First check if on the DHCP thread. If so, we don't need to check
	; the link status, as it's marked closed but really open.
	;

		mov	bx, handle dgroup
		call	MemDerefES
		mov	bx, es:[dhcpThread]
		cmp	bx, ss:[0].TPD_threadHandle
		jne	notDhcp
		mov	ax, MAIN_LINK_DOMAIN_HANDLE
		jmp	exit

	;
	; Get entry of main link from table.
	;
notDhcp:
		call	TcpipGainAccessFar
		segmov	es, ds, bx		; es:si = address
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		mov	cx, bx			; cx = link handle, in case...
		call	LinkTableGetEntry	; ds:di = LCB
						; ^hbx = table

		segxchg	es, ds			; es:di = LCB
						; ds:si = address
		cmp	es:[di].LCB_state, LS_CLOSED
		je	noGood
	;
	; Link is open.  Compare the link address w/ remote address.
	;
		lodsw	
		xchg	cx, ax			; cx = link addr size
						; ax = link handle
		cmp	cx, es:[di].LCB_linkSize
		jne	noGood

		jcxz	unlock			; carry already clear

		add	di, offset LCB_linkAddr
		repe	cmpsb
		je	unlock			; carry already clear
noGood:
		mov	ax, SDE_DESTINATION_UNREACHABLE
		stc
unlock:
		call	MemUnlockExcl
		call	TcpipReleaseAccessFar
exit:
		.leave
		ret
LinkCheckOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkOpenConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a link connection.  If the connection is already open
		this does nothing.

CALLED BY:	TcpipDataConnectRequest
		TcpipSendDatagramCommon
		TcpipMediumConnectRequest

PASS:		ds:si	= remote address (non-null terminated string)
			  (FXIP: address cannot be in a movable code resource)
		cx	= timeout value (in ticks)

		NOTE:  SocketInfoBlock MUST NOT be locked and taskSem
			MUST NOT be P-ed when this is called!

RETURN:		carry clear if opened
		ax = domain handle of link connection
		else carry set if error
		ax = SocketDrError possibly 
			(SDE_DRIVER_NOT_FOUND	
			 SDE_ALREADY_REGISTERED 
			 SDE_MEDIUM_BUSY	
			 SDE_INSUFFICIENT_MEMORY
			 SDE_LINK_OPEN_FAILED
			 SDE_CONNECTION_TIMEOUT
			 SDE_CONNECTION_RESET
			 SDE_CONNECTION_RESET_BY_PEER)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

		gain access
		check if loopback
		if closeCount != 0 or LS_CLOSING, wait until link closed

		load main link driver if not loaded
		if connection closed, open it
		Check link address with current address
		if connection being opened
			if address different
				return medium busy
			else
				wait for open to complete
				return link handle if opened, else error
		else link is open
			if address same
				return success
	    	        else if no connections
				close current link
				open new link
		        else return medium busy
		release access


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/11/94		Initial version
	jwu	9/22/95		Unlock link table when calling link driver
	jwu	7/29/96		Non blocking link connect requests 
	jwu	4/19/97		queue link open requests
	ed	6/30/00		GCN notification

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkOpenConnection	proc	far
		uses	bx, cx, dx, di, ds, es
		.enter
	;
	; If we are using loopback link, no need to open a link.
	;		
		call	LinkCheckIfLoopback	; ax = loopback domain handle
		LONG	jnc	exit

		segmov	es, ds, bx			; es:si = address
theStart:
	;
	; Get entry of main link from table.  
	;
		call	TcpipGainAccessFar
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = table
	;
	; If others are waiting for link to close, or link is closing,
	; wait for link to close before opening a new connection.  
	;
		tst	ds:[di].LCB_closeCount
		jnz	waitForClose

		cmp	ds:[di].LCB_state, LS_CLOSING
		jne	setupLink
waitForClose:
		inc	ds:[di].LCB_closeCount
		push	ds:[di].LCB_closeSem
		call	MemUnlockExcl			; release table
		call	TcpipReleaseAccessFar

		pop	bx
		call	ThreadPSem			; wait for close
		jmp	theStart			; start over when awake
setupLink:
	; 
	; If link driver is not loaded, load and register it now.
	;
		segxchg	es, ds				; es:di = LCB
							; ds:si = address
		call	LinkSetupMainLink		; ax = SocketDrError
		LONG	jc	unlockTable
	;
	; If link is closed, open it now. 
	;
		mov	dx, cx				; dx = timeout value
		cmp	es:[di].LCB_state, LS_CLOSED
		LONG	je	openNow				
	;
	; Check if link is being opened to same address as current.
	; 
		call	LinkCompareLinkAddress
		lahf
		cmp	es:[di].LCB_state, LS_OPEN
		je	isOpen
	;
	; Link is being opened.  If address is different, return medium
	; busy.  Else wait for open to complete.
	;
		sahf
		jc	mediumBusy			; addrs differ

		inc	es:[di].LCB_semCount
		push	es:[di].LCB_sem
		call	MemUnlockExcl
		call	TcpipReleaseAccessFar

		pop	bx		
		call	ThreadPSem			; wait for open
	;
	; Check if link is opened, returning success or error.
	;
		call	TcpipGainAccessFar
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = table
		cmp	ds:[di].LCB_state, LS_OPEN
		je	success				; carry clr from cmp

		mov	ax, ds:[di].LCB_error
		jmp	gotError
mediumBusy:
		mov	ax, SDE_MEDIUM_BUSY		
gotError:
		stc
		jmp	unlockTable

isOpen:
	;
	; Link is already open.  If link address matches, return success.
	; If not, close the current connection if it's not busy and open
	; a new one.  If link cannot be closed, return medium busy.
	;
		sahf
		jc	different
success:
		mov	ax, MAIN_LINK_DOMAIN_HANDLE
		jmp	unlockTable			; carry is clr
different:
	;
	; If no connections exist, close current link and reopen another
	; one.  Unlock link table before calling out of TCP driver.
	;				
		test	es:[di].LCB_options, mask LO_ALWAYS_BUSY
		jnz	mediumBusy

		mov	ax, MAIN_LINK_DOMAIN_HANDLE
		call	TSocketCheckLinkBusy
		jc	mediumBusy
		
		mov	ax, es:[di].LCB_connection
		pushdw	es:[di].LCB_strategy
		call	MemUnlockExcl

		mov_tr	bx, ax				; bx = link connection
		mov	ax, SCT_FULL
		mov	di, DR_SOCKET_DISCONNECT_REQUEST
		call	PROCCALLFIXEDORMOVABLE_PASCAL
	;
	; Relock link table for open attempt.
	;
		segmov	es, ds, bx			; es:si = address
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry
		segxchg	es, ds				; es:di = LCB
							; ds:si = address
openNow:
	;
	; Store link address and open the link.
	;
		call	LinkStoreLinkAddress
		jc	unlockTable

		mov	es:[di].LCB_state, LS_OPENING
		call	MemUnlockExcl			; unlock link table
		mov	ax, TSNT_OPENING
		call	LinkSendNotification		; Send GCN notify
		call	LinkOpenLink			; ax = error or handle
		jmp	releaseAccess
unlockTable:
		call	MemUnlockExcl
releaseAccess:
		call	TcpipReleaseAccessFar
exit:
		.leave
		ret


LinkOpenConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkCheckIfLoopback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the domain handle for the loopback link 
		if the remote address is a loopback address.

CALLED BY:	LinkOpenConnection

PASS:		ds:si	= remote address (not null terminated)

RETURN:		carry set if not loopback address
		else
		ax	= loopback domain handle

DESTROYED:	ax if not loopback address

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/24/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkCheckIfLoopback	proc	near
		uses	si		
		.enter

		lodsw					; ax = size of link part
							; ds:si = link part
		add	si, ax				; ds:si = ip addr
		mov	al, ds:[si]
		cmp	al, LOOPBACK_NET
		jne	notLoopback

		mov	ax, LOOPBACK_LINK_DOMAIN_HANDLE
		jmp	exit				; carry clr from cmp
notLoopback:
		stc
exit:
		.leave
		ret
LinkCheckIfLoopback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkSetupMainLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If driver not already loaded, load the main link driver, 
		get its strategy routine and register it.

CALLED BY:	LinkOpenConnection

PASS:		es:di	= LCB of main link entry

RETURN:		carry clear if successful
		else carry set		
		ax = SocketDrError
			(SDE_DRIVER_NOT_FOUND	-- no link driver
			 SDE_ALREADY_REGISTERED -- shouldn't happen
			 SDE_MEDIUM_BUSY	-- link driver in use 
			 SDE_INSUFFICIENT_MEMORY)

DESTROYED:	ax if not returned

PSEUDO CODE/STRATEGY:

		Load the default link driver.
		Get its strategy routine
		Register it.
		If registration fails, unload link driver.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkSetupMainLink	proc	near
		uses	bx, cx, dx, bp, di, si, ds
		.enter
	;
	; If link driver already loaded, do nothing.
	;
		tst_clc	es:[di].LCB_drvr
		jnz	exit
	;
	; Load default link driver and get the strategy routine.
	;
		call	LinkLoadLinkDriver		; bx = driver handle
		mov	ax, SDE_DRIVER_NOT_FOUND
		jc	exit
		
		call	GeodeInfoDriver
		movdw	cxdx, ds:[si].DIS_strategy		

		mov	es:[di].LCB_drvr, bx		
		movdw	es:[di].LCB_strategy, cxdx
	;
	; Register the link driver.  Registration fails if the link
	; driver is already registered, either by us or someone else.
	;
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	si, offset categoryString
		mov	si, ds:[si]			; ds:si = domain name

		push	di, bx
		pushdw	cxdx
		call	GeodeGetProcessHandle
		mov_tr	ax, bx				; our geode handle 
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		mov	cl, SDT_LINK
		mov	dx, segment TcpipClientStrategy
		mov	bp, offset TcpipClientStrategy	; dx:bp = client entry
		mov	di, DR_SOCKET_REGISTER
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; bx = client handle
							; or ax = SocketDrError
							; ch, cl = min hdr sizes
		mov_tr	dx, bx
		pop	di, bx
		call	MemUnlock			; preserves flags
		jc	failed		

		mov	es:[di].LCB_clientHan, dx
	;
	; Use larger of two minimum header sizes.
	;
		cmp	cl, ch
		jae	haveSize
		
		mov	cl, ch
haveSize:
		mov	es:[di].LCB_minHdr, cl
		clc
exit:				
		.leave
		ret

failed:
	;
	; Unload link driver.  ES:SI = LinkControlBlock.
	;
		clr	bx
		xchg	bx, es:[di].LCB_drvr		
		call	LinkUnloadLinkDriver
		stc
		jmp	exit

LinkSetupMainLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkCompareLinkAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the given address with the current link address.

CALLED BY:	LinkOpenConnection

PASS:		ds:si	= link address
		es:di	= LCB

RETURN:		carry set if address is the same
		else carry clear

DESTROYED:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/19/97			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkCompareLinkAddress	proc	near
		uses	cx
		.enter
	;
	; First compare the size for a quick elimination check.
	;
		mov	cx, ds:[si]			; cx = link addr size
		cmp	cx, es:[di].LCB_linkSize
		jne	different

		jcxz	same				; both addrs are null
	;
	; Same size so compare actual address contents.
	;
		push	si, di
		inc	si
		inc	si
		add	di, offset LCB_linkAddr
		repe	cmpsb
		pop	si, di
		jne	different
same:
		clc					
		jmp	exit
different:
		stc
exit:
		.leave
		ret
LinkCompareLinkAddress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkStoreLinkAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the link address in the link control block.

CALLED BY:	LinkOpenConnection

PASS:		es:di	= LinkControlBlock	
		ds:si	= remote address (non-null terminated)

RETURN:		carry set if error
		ax = SocketDrError
		else
		es:di - updated to point to new element 

DESTROYED:	ax, di if not returned

PSEUDO CODE/STRATEGY:
		Resize current element to fit link address
		store link addr size
		store link address

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 7/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkStoreLinkAddress	proc	near
		uses	bx, cx, si
		.enter
	;
	; Resize link entry, if needed.
	;
		lodsw					; ax = size of address
		mov_tr	cx, ax
		cmp	cx, es:[di].LCB_linkSize
		je	storeAddr

		push	si, ds, cx
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	si, ds:[linkTable].chunk	
		segmov	ds, es, bx			; *ds:si = chunk array
		mov	ax, MAIN_LINK_DOMAIN_HANDLE	
		add	cx, size LinkControlBlock	; cx = new size
		call	ChunkArrayElementResize		
	;
	; Redereference LCB.	
	;
		pushf
		call	ChunkArrayElementToPtr		
		segmov	es, ds, si			; es:di = LCB
		popf
		pop	si, ds, cx			; ds:si = address
		jc	error

		mov	es:[di].LCB_linkSize, cx
storeAddr:
	;
	; Copy address into LCB.
	;
		push	di
		add	di, offset LCB_linkAddr
		rep	movsb
		pop	di				
		clc
exit:
		.leave
		ret
error:
		mov	ax, SDE_INSUFFICIENT_MEMORY
		jmp	exit
LinkStoreLinkAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkOpenLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the link driver to establish the link connection,
		updating the LinkControlBlock with local IP address of 
		link connection, mtu, connection handle and link state.

CALLED BY:	LinkOpenConnection

PASS:		ds:si	= remote address (non-null terminated)
		dx	= timeout value (in ticks)

RETURN:		carry set if error
			ax = SocketDrError
		else
			ax = link domain handle	

DESTROYED:	cx, dx, di, ds (allowed by caller)

PSEUDO CODE/STRATEGY:

NOTE:
		Caller has access.  Return with access held!

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	4/ 7/95			Initial version
	ed	6/30/00			GCN notification

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkOpenLink	proc	near
		uses	bx, si
		.enter
	;
	; Allocate the connection to get a handle.  
	;
		segmov	es, ds, bx			; es:si = address
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry		; ds:di = LCB
		mov	ax, SDE_NO_ERROR		; reset error
		xchg	ds:[di].LCB_error, ax		; ax = last error
		mov	ds:[di].LCB_lastError, ax	; save last error
		mov	ax, ds:[di].LCB_clientHan
		pushdw	ds:[di].LCB_strategy		; for alloc
		call	MemUnlockExcl

		mov_tr	bx, ax				; bx = client handle
		mov	di, DR_SOCKET_ALLOC_CONNECTION
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; ax = error or handle
		jc	checkError
	;
	; Store connection handle and open the connection.
	;
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry		; ds:di = LCB
		mov	ds:[di].LCB_connection, ax
		inc	ds:[di].LCB_openCount		; one more open attempt
		push	ds:[di].LCB_openCount		; save open count
		pushdw	ds:[di].LCB_strategy
		call	MemUnlockExcl
		segmov	ds, es, bx			; ds:si = link addres

		mov_tr	bx, ax				; bx = conn handle
		mov	cx, dx				; cx = timeout
		mov	ax, ds:[si]			; ax = link addr size
		inc	si
		inc	si				; ds:si = link address
		mov	di, DR_SOCKET_LINK_CONNECT_REQUEST
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; ax = error
		pop	cx				; restore open count
		jc	checkError
	;
	; Release access and wait for open to complete.
	;
		mov	bx, MAIN_LINK_DOMAIN_HANDLE			
		call	LinkTableGetEntry				
EC <		tst	ds:[di].LCB_semCount	; no waiters yet!!	>
EC <		ERROR_NZ TCPIP_INTERNAL_ERROR				>
		inc	ds:[di].LCB_semCount				
		push	ds:[di].LCB_sem
		call	MemUnlockExcl					

		call	TcpipReleaseAccessFar

		pop	bx				; LCB_sem
		call	ThreadPSem			
	;
	; Regain access for caller.
	;

		call	TcpipGainAccessFar
checkError:
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry
	;
	; Compare the current open count against the last known open count.
	; If different, someone else came along and started opening the
	; link again before we woke up, so just retrieve the last error
	; and exit.
	;
		cmp	cx, ds:[di].LCB_openCount
		je	ourOpen
		mov	ax, ds:[di].LCB_lastError
		jmp	gotError
	;
	; If state is still OPENING, the alloc or link connect request
	; failed immediately. Reset state to CLOSED and returnerror. 
	;
ourOpen:
		CheckHack <LS_CLOSED lt LS_OPENING>
		CheckHack <LS_CLOSING lt LS_OPENING>
		CheckHack <LS_OPENING lt LS_OPEN>
		cmp	ds:[di].LCB_state, LS_OPENING
		jne	checkOpen

		mov	ds:[di].LCB_connection, 0
		mov	ds:[di].LCB_state, LS_CLOSED
		push	ax
		mov	ax, TSNT_CLOSED
		call	LinkSendNotification
		pop	ax
		jmp	gotError
checkOpen:
	;
	; If link successfully opened, return link handle.
	; Else get the error and return that.
	;		
		mov	ax, MAIN_LINK_DOMAIN_HANDLE	; hope for the best...
		ja	unlockTable			; it's open; carry clr

		mov	ax, ds:[di].LCB_error
	;
	; If error is SDE_INTERRUPTED, wake up any clients waiting for
	; link to close.  Keep link table locked so clients can't
	; proceed until we're done here.
	;
		cmp	ax, SDE_INTERRUPTED
		jne	gotError
		
		tst	ds:[di].LCB_closeCount
		jz	gotError

		push	bx, ax
		mov	cx, ds:[di].LCB_closeCount
		mov	bx, ds:[di].LCB_closeSem
wakeLoop:
		call	ThreadVSem			; destroys AX!
		loop	wakeLoop
		mov	ds:[di].LCB_closeCount, cx	; no more waiters
		pop	bx, ax
gotError:
		stc					
unlockTable:
		call	MemUnlockExcl			; flags preserved

		.leave
		ret
LinkOpenLink	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkLoadLinkDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the link driver used by TCP to establish connections.

CALLED BY:	LinkSetupMainLink
		LinkGetMediumAndUnit
		LinkResolveLinkAddr
		IPAddressControlAddChild via LinkLoadLinkDriverFar
		TcpipGetMinDgramHdr via LinkLoadLinkDriverFar

PASS:		nothing

RETURN:		carry set if failed
		else carry clear and
		bx = link driver's handle

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Read permanent name of link driver from INI
		If name read,
		  Try using GeodeUseDriverPermName
		  If success, exit
		Read long name of link driver from INI
		Call GeodeUseDriver

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	dhunter	8/10/00			Use GeodeUseDriverPermName instead
	dh  8/22/99         Optimized to use GeodeFind first
	jwu	7/13/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString	socketString, <"socket", 0>

LinkLoadLinkDriverFar	proc	far
		call	LinkLoadLinkDriver
		ret
LinkLoadLinkDriverFar	endp


LinkLoadLinkDriver	proc	near
		uses	ax, cx, dx, di, si, ds, es
driverName	local	FileLongName
driverPermName  local   GEODE_NAME_SIZE dup (char)
		.enter
	;	
	; Set up category and key strings.
	;	
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	si, ds:[categoryString]		; ds:si = category str
		mov	dx, ds:[linkDriverPermanentKeyString]
							; cx:dx = key string
		assume	ds:nothing
	;
	; Read the permanent driver name from the INI file.
	;
		push	bp				; local var ...
		segmov	es, ss, di
		lea	di, driverPermName		
		mov	bp, InitFileReadFlags \
				<IFCC_INTACT, 0, 0, GEODE_NAME_SIZE>
		call	InitFileReadString		; cx = # chars read
		pop	bp				; local var ...
		mov	bx, handle Strings
		call	MemUnlock			; unlock strings
		jc	loadDriver      ; default to load driver if name unavailable
	;
	; Pad the name with spaces to the requisite length.
	;
		push	di
		add	di, cx		; di <- ptr to last char read + 1
		sub	cx, 8		; cx = -(# spaces needed)
		neg	cx		; cx = # spaces needed
		jcxz	padded
		mov	al, C_SPACE
		rep	stosb		; write the spaces
padded:
		pop	si		; es:si = permanent name
	;
	; Use GeodeUseDriverPermName to reuse the driver.  This will
	; fail if the driver is not loaded.
	;
		push	ds
		segmov	ds, es, ax			; ds:si = driver name
		mov	ax, SOCKET_PROTO_MAJOR
		mov	bx, SOCKET_PROTO_MINOR 
		call	GeodeUseDriverPermName		; CF set if not found
		pop	ds
	;
	; If the geode was found, we're done.
	;
		jnc	exit
	;
	; Set up category and key strings.
	;
loadDriver:
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		mov	cx, ax
		assume	ds:Strings
		mov	si, ds:[categoryString]		; ds:si = category str
		mov	dx, ds:[linkDriverKeyString]	; cx:dx = key string
		assume	ds:nothing
	;
	; Read the full driver name from the INI file.
	;
		push	bp				; local var ...
		segmov	es, ss, di
		lea	di, driverName		
		mov	bp, InitFileReadFlags \
				<IFCC_INTACT, 0, 0, FILE_LONGNAME_BUFFER_SIZE>
		call	InitFileReadString
		pop	bp				; local var ...
		
		mov	bx, handle Strings
		call	MemUnlock			; unlock strings
		jc	exit
	;
	; Switch to the socket directory.
	;
		call	FilePushDir
		
		mov	bx, SP_SYSTEM
		segmov	ds, cs, si
		mov	dx, offset socketString
		call	FileSetCurrentPath
		jc	done
	;
	; Load the driver.
	;
		segmov	ds, es, ax
		mov_tr	si, di				; ds:si = driver name
		mov	ax, SOCKET_PROTO_MAJOR
		mov	bx, SOCKET_PROTO_MINOR 
		call	GeodeUseDriver
done:
		call	FilePopDir
exit:		
		.leave
		ret
LinkLoadLinkDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkUnloadLinkDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unload the link driver used by TCP to establish connections.

CALLED BY:	LinkSetupMainLink
		LinkGetMediumAndUnit
		LinkResolveLinkAddr
		IPAddressControlAddChild via LinkLoadLinkDriverFar
		TcpipGetMinDgramHdr via LinkLoadLinkDriverFar
		CloseAllLinks

PASS:		bx = link driver's handle

RETURN:		carry set if library was exited

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		Call GeodeFreeDriver.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	dhunter	8/10/00			Removed semaphore nonsense
	dh	8/22/99			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkUnloadLinkDriverFar	proc	far
		call	LinkUnloadLinkDriver
		ret
LinkUnloadLinkDriverFar	endp

LinkUnloadLinkDriver    proc    near
		call	GeodeFreeDriver
		ret
LinkUnloadLinkDriver    endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkGetMTU
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	LinkGetMTU

C DECLARATION:	extern word _far
		_far _pascal LinkGetMTU(word link);

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
LINKGETMTU	proc	far		link:word
		uses	di, ds
		.enter

		mov	bx, link			; bx = link domain han
		call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx  = link table
		mov	ax, ds:[di].LCB_mtu		; ax = mtu of link
		call	MemUnlockExcl

		.leave
		ret
LINKGETMTU	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkGetMediumAndUnit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the medium and unit.

CALLED BY:	TcpipGetMediumAndUnit

PASS:		es	= dgroup

RETURN:		carry set if error, else
		cxdx	= MediumType
		bl	= MediumUnitType
		bp	= MediumUnit (port)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if main link is loaded
			get driver strategy
		else load it and get driver strategy
		query for the info
		unload link driver if loaded

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	1/ 5/95			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkGetMediumAndUnit	proc	far
		uses	ax, di, si
		.enter
	;
	; Find out if link driver is loaded or not.  If loaded, get
	; its strategy routine, else load the driver and get the strategy
	; routine from there.
	;
		push	ds
		mov	bx, MAIN_LINK_DOMAIN_HANDLE
		call	LinkTableGetEntry		; ds:si = LCB
							; ^hbx = link table
		movdw	cxdx, ds:[di].LCB_strategy
		mov	ax, ds:[di].LCB_drvr
		call	MemUnlockExcl
		pop	ds

		tst	ax
		je	loadDriver
		clr	bx
		jmp	query
loadDriver:
		call	LinkLoadLinkDriver		; bx = driver handle
		jc	exit
		
		push	ds
		call	GeodeInfoDriver
		movdw	cxdx, ds:[si].DIS_strategy
		pop	ds
query:
	;
	; Query link driver for the medium and unit. 
	;
		push	bx				; driver handle
		pushdw	cxdx	
		mov	ax, SGIT_MEDIUM_AND_UNIT
		mov	di, DR_SOCKET_GET_INFO
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; cxdx = MediumType
							; bl = MediumUnitType
							; bp = MediumUnit (port)
	;
	; Unload link driver if loaded here for the query.
	;		
		pop	ax				; driver handle
		tst_clc	ax
		je	exit

		xchg	bx, ax				; bx = driver handle
		call	LinkUnloadLinkDriver
		xchg	bx, ax				; bl = MediumUnitType
		clc
exit:
		.leave
		ret		
LinkGetMediumAndUnit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkGetMediumAndUnitConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a link over the specified MediumAndUnit.  If 
		found, return the link domain handle.

CALLED BY:	TcpipGetMediumConnection
PASS:		es	= dgroup
		dx:bx	= MediumAndUnit
		ds:si	= buffer in which to place link address
		cx	= size of buffer

RETURN:		carry set if no link is connected over unit of medium
		else
			cx = connection handle
			ax = size of link address, whether it fit in the
			     buffer or not.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Enum over links, looking for one with matching MediumAndUnit.
	If found, return the connection handle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkGetMediumAndUnitConnection	proc	far
		uses	bx, dx, di, si, ds
mediumAndUnit	local	fptr.MediumAndUnit	push dx, bx
destBuf		local	fptr			push ds, si
destBufSize	local	word			push cx
		ForceRef mediumAndUnit	; LinkGetMediumAndUnitConnectionCB
		ForceRef destBuf	; LinkGetMediumAndUnitConnectionCB
		ForceRef destBufSize	; LinkGetMediumAndUnitConnectionCB
		.enter

		movdw	bxsi, es:[linkTable]
		call	MemLockExcl
		mov	ds, ax			; *ds:si = link table
		push	bx			; save link table handle

		mov	bx, cs
		mov	di, offset LinkGetMediumAndUnitConnectionCB
		call	ChunkArrayEnum		; ax = link domain handle
						; cx = link addr size
		cmc				; return carry clear if found
		xchg	cx, ax			; return cx = link domain handle
						; and ax = address size

		pop	bx
		call	MemUnlockExcl			;flags preserved
		
		.leave
		ret

LinkGetMediumAndUnitConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkGetMediumAndUnitConnectionCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search for a link connected over MediumAndUnit, returning
		the link domain handle.

CALLED BY:	LinkGetMediumAndUnitConnection via ChunkArrayEnum
PASS:		*ds:si 	= LinkTable
		ds:di	= LinkControlBlock
		ss:bp	= inherited frame
RETURN:		carry set if link is found over MediumAndUnit:
			ax	= link domain handle
			cx	= size of link address
		else carry clear
			cx, dx preserved.
DESTROYED:	bx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	2/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkGetMediumAndUnitConnectionCB	proc	far
		uses	dx, es
		.enter	inherit	LinkGetMediumAndUnitConnection
	;
	; Don't bother querying for medium and unit if link driver is
	; not loaded or if link is closed.
	;
		tst_clc	ds:[di].LCB_drvr
		je	exit				

		cmp	ds:[di].LCB_state, LS_CLOSED
		je	exit

		push	bp, di
		pushdw	ds:[di].LCB_strategy
		mov	ax, SGIT_MEDIUM_AND_UNIT
		mov	di, DR_SOCKET_GET_INFO
		call	PROCCALLFIXEDORMOVABLE_PASCAL	; cxdx = MediumType
							; bl = MediumUnitType
							; bp = MediumUnit (port)
		mov_tr	ax, bp				; ax = MediumUnit (port)
		pop	bp, di
	;
	; Check if medium and unit of link matches.  If found,
	; return domain handle of the link.
	;
		push	bp
		les	bp, mediumAndUnit		; es:bp = MediumAndUnit
		cmpdw	es:[bp].MU_medium, cxdx
		jne	mismatch

		cmp	es:[bp].MU_unitType, bl
		jne	mismatch
	
		cmp	bl, MUT_NONE			; no unit to check?
		je	copyIt

		cmp	es:[bp].MU_unit, ax
		jne	mismatch
copyIt:
	;
	; Copy the link address into the buffer.
	;
		pop	bp
		push	bp
		push	si, di
		mov	si, di			; ds:si <- LCB
		les	di, ss:[destBuf]
		mov	cx, ss:[destBufSize]
		mov	ax, ds:[si].LCB_linkSize
		inc	ax			; another two bytes for the
		inc	ax			;  address size word
		cmp	ax, cx			; bigger than dest buf?
		jae	doCopy			; yes -- copy what will fit
		mov	cx, ax			; no -- copy only the address
doCopy:
		add	si, offset LCB_linkSize	; external rep of link addr
						;  includes size word, so start
						;  move from there
		rep	movsb
		pop	si, di
		mov_tr	cx, ax			; cx <- link address size

		call	ChunkArrayPtrToElement	; ax = link domain handle
		stc				; abort enum
done:
		pop	bp
exit:	
		.leave
		ret
mismatch:
		clc
		jmp	done
LinkGetMediumAndUnitConnectionCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkCheckLocalAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	LinkCheckLocalAddr

C DECLARATION:	extern word _far
		_far _pascal LinkCheckLocalAddr(word link, dword addr);

PSEUDOCODE:	
		Returns non-zero value if address is not the local 
		address of the link.

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	9/30/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
LINKCHECKLOCALADDR	proc	far	link:word,
					addr:dword
		uses	di, ds
		.enter
		
		mov	bx, link
		call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = link table
		movdw	dxax, addr
		cmpdw	dxax, ds:[di].LCB_localAddr
		je	match
		
		mov	ax, -1				; non-zero
		jmp	done
match:
		clr	ax
done:	
		call	MemUnlockExcl
		
		.leave
		ret
LINKCHECKLOCALADDR	endp
	SetDefaultConvention


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	LinkSendData

C DECLARATION:	extern word _far
		_far _pascal LinkSendData(optr dataBuffer, word link);

PSEUDOCODE:	If link is closed, drop the packet. 

		logBrkPt is used for swat to set a breakpoint for logging
		the contents of the packet

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jwu	7/18/94		Initial version
	jwu	9/22/95		Unlock link table when calling link driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention
LINKSENDDATA	proc	far		dataBuffer:optr,
					link:word
		uses	si, di, ds
		.enter
	;
	; Make sure link is open before attempting to send data.
	;
		mov	bx, link			; bx = link domain han
EC <		tst	bx						>
EC <		ERROR_E LOOPBACK_SHOULD_NOT_REACH_LINK_LEVEL		>
		call	LinkTableGetEntry		; ds:di = LCB
							; ^hbx = link table
		mov	dx, ds:[di].LCB_clientHan
		cmp	ds:[di].LCB_state, LS_OPEN		
		je	linkOpen
		push	ds
		push	bx
		mov	bx, handle dgroup
		call	MemDerefDS
		mov	bx, ds:[dhcpThread]
		tst	bx
		pop	bx
		pop	ds
		jz	notOpen
	;
	; Unlock the link table before calling out of TCP driver.
	; Get the size and data offset from the buffer.
	;
linkOpen:
		push	bp				
		pushdw	ds:[di].LCB_strategy	
		call	MemUnlockExcl

		movdw	bxbp, dataBuffer
		call	HugeLMemLock
		mov	es, ax
		mov	di, es:[bp]			; es:di = SPH
logBrkPt::		
		mov	ax, es:[di].PH_dataOffset	
		mov	cx, es:[di].PH_dataSize
		call	HugeLMemUnlock
		
		xchg	dx, bx				; ^ldx:bp = buffer
							; bx = client handle
		mov	di, DR_SOCKET_SEND_DATAGRAM
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	bp 
		clr	ax				; no error
		jmp	exit
notOpen:
	; 
	; Free data buffer as it cannot be sent.
	;
EC <		WARNING TCPIP_DISCARDING_OUTPUT_BUFFER		>
		call	MemUnlockExcl
		movdw	axcx, dataBuffer
		call	HugeLMemFree
		mov	ax, SDE_DESTINATION_UNREACHABLE
exit:		
		.leave
		ret

LINKSENDDATA	endp
	SetDefaultConvention

if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckLinkDomainHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the domain handle is legal.

CALLED BY:	TcpipLinkOpened
		TcpipLinkClosed
		TcpipReceivePacket

PASS:		bx	= domain handle

RETURN:		carry set if invalid

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Ensure that the domain handle does not exceed the 
		number of connections we know about.

		That's about all we can do...
REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	7/ 8/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckLinkDomainHandle	proc	far
		uses	ax, bx, cx, dx, si, ds
		.enter
		
		mov	dx, bx				; dx = link domain handle
		mov	bx, handle dgroup
		call	MemDerefDS				
		movdw	bxsi, ds:[linkTable]
		call	MemLockShared
		mov	ds, ax				; *ds:si = link table
		
		call	ChunkArrayGetCount		; cx = # entries
		call	MemUnlockShared
		
		cmp	dx, cx				; carry set if <
		cmc
		
		.leave
		ret
ECCheckLinkDomainHandle	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LinkSendNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out a GCN update on the status of the link

CALLED BY:	LinkOpenConnection
		LinkOpenLink
PASS:		ax	- TcpipStatusNotificationType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	6/30/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LinkSendNotification	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	; Record the message

		mov_tr	bp, ax
		mov	ax, MSG_META_NOTIFY
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_TCPIP_LINK_STATUS
		clr	bx, si
		mov	di, mask MF_RECORD
		call	ObjMessage

	; Send it off to the GCN list
		
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_TCPIP_STATUS_NOTIFICATIONS
		mov	cx, di
		clr	dx
		mov	bp, mask GCNLSF_SET_STATUS
		call GCNListSend

		.leave
		ret
LinkSendNotification	endp


LinkCode	ends

