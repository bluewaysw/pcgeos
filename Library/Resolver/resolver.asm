COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Socket project
MODULE:		Resolver
FILE:		resolver.asm

AUTHOR:		Steve Jang, Dec 14, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94   	Initial revision

DESCRIPTION:
	Resolver that provides services related to DNS
	This file contains entry points to resolver.

STARTUP/EXIT SEQUENCE:

       	       	       	resolver       	     detach
		       operations         delay period
flags			   |		       |
	                   |     RSF_TIMER_STARTED
			   |    	       |     RSF_SHUTTING_DOWN
			   v   	       	       v
START -------> REGISTER -------> UNREGISTER -------> DETACH -------> EXIT
1. resource  	 1. create     	 1. initiate   	     1. destroy	     1. res
   alloc            socket	    detach      	socket  	dealloc
2. load	         2. create                           2. destroy      2. save
   cache            event queue                         event queue     cache
		 3  create threads                   3. kill threads

START:		library is loaded
REGISTER:	ResolverRegister called
UNREGISTER:	ResolverUnregister called -> detach timer is started
DETACH:		detach timer expires and detach procedure begins
EXIT:		library is unloaded

	$Id: resolver.asm,v 1.24 98/06/16 18:10:50 jwu Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResolverCommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEntryRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry routine to resolver lib

CALLED BY:	kernel
PASS:		di	= LibraryCallType
RETURN:		carry set on error
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEntryRoutine	proc	far
		uses	ax, bx, cx, dx, es, ds
		.enter
		cmp	di, LCT_ATTACH
		jne	next
		call	ResolverInit
		jmp	done
next:
		cmp	di, LCT_DETACH
		jne	next2
		call	ResolverExit
next2:
done:
		.leave
		ret
ResolverEntryRoutine	endp
ForceRef ResolverEntryRoutine


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize resolver

CALLED BY:	LCT_ATTACH
PASS:		nothing
RETURN:		carry set if initialization failed
DESTROYED:	ax, bx, cx, dx, es, ds

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
resCategory		char	"resolver",0
cacheSizeKwd		char	"cacheSize",0
clientTimeoutStr	char	"clientTimeout",0
minQueryTimeoutStr	char	"minQueryTimeout",0
maxQueryTimeoutStr	char	"maxQueryTimeout",0
nsRetryStr		char	"nsRetry",0
ResolverInit	proc	near
		.enter
	;
	; Allocate a hugelmem
	;
		GetDgroup es, bx
		mov	ax, RESOLVER_HUGELMEM_NUM_BLOCKS
		mov	bx, RESOLVER_HUGELMEM_MIN_OPT_SIZE
		mov	cx, RESOLVER_HUGELMEM_MAX_OPT_SIZE
		call	HugeLMemCreate	; bx = HugeLMem handle
LONG		jc	failed
		mov	es:hugeLMem, bx
	;
	; Allocate QueryBlock
	;
		mov	ax, RESOLVER_MAX_QUERY_MSG_SIZE
		mov	cl, mask HF_SWAPABLE
		mov	ch, mask HAF_ZERO_INIT or mask HAF_LOCK
                mov     bx, handle 0            ; bx=geode handle of ourselves
                call    MemAllocSetOwner        ; bx = handle of block
LONG		jc	failed
		mov	es:queryMessage, bx
	;
	; Fill in fields that will never change
	;
		mov	ds, ax		; ds = segment of query message
		mov	ds:RM_flags, mask RMF_RD
		call	MemUnlock
	;
	; Read in the number of the cache entries allowed
	;
		GetDgroup es, ax
		
		mov	cx, cs
		mov	ds, cx
		mov	si, offset resCategory
		mov	dx, offset cacheSizeKwd
		mov	ax, RESOLVER_DEFAULT_CACHE_SIZE
		call	InitFileReadInteger	; ax = cache size allowed
		mov	es:cacheSizeAllowed, ax
	;
	; Read in client query timeout
	;
		mov	dx, offset clientTimeoutStr
		mov	ax, RESOLVER_DEFAULT_TIMEOUT
		call	InitFileReadInteger
		mov	es:clientTimeout, ax
	;
	; read minimum query timeout value
	;
		mov	dx, offset minQueryTimeoutStr
		mov	ax, RESOLVER_MIN_QUERY_TIMEOUT
		call	InitFileReadInteger
		mov	es:minQueryTimeout, ax
	;
	; read minimum query timeout value
	;
		mov	dx, offset maxQueryTimeoutStr
		mov	ax, RESOLVER_MAX_QUERY_TIMEOUT
		call	InitFileReadInteger
		mov	es:maxQueryTimeout, ax
	;
	; read minimum query timeout value
	;
		mov	dx, offset nsRetryStr
		mov	ax, RESOLVER_RETRY_NS_COUNT
		call	InitFileReadInteger
		mov	es:nsRetry, ax
	;
	; Read cache
	;
readCache::
		segmov	ds, es, ax
		call	CacheLoad	; CF = 0
	;
	; Set up cache refresh timer
	;
		call	CacheRefreshTimerStart
	;
	; Reduce cache if necessary
	;
reduceCache::	mov	ax, es:cacheSizeAllowed
		cmp	ax, es:cacheSize
		ja	done
		call	CacheDeallocateHalf
done:
		clc
failed:
EC <		WARNING_C RW_MEMORY_ERROR				>
		.leave
		ret
ResolverInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit resolver

CALLED BY:	LCT_DETACH
PASS:		nothing
RETURN:		nothing
DESTROYED:	es, bx
NOTE:
	most of exit procedure will be performed by event thread just
	before it exits.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverExit	proc	near
		.enter
	;
	; Stop cache refresh timer
	;
		call	CacheRefreshTimerStop
	;
	; Save current cache into cache file
	;
		GetDgroup ds, bx
		call	CacheSave
EC <		WARNING_C RW_CACHE_NOT_SAVED				>
	;
	; Destroy hugelmem
	;
		mov	bx, ds:hugeLMem
		call	HugeLMemForceDestroy
	;
	; Deallocate message block
	;
		mov	bx, ds:queryMessage
		call	MemFree
		clc				; always success
exit::
		.leave
		ret
ResolverExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register with resolver
CALLED BY:	External
PASS:		nothing
RETURN:		carry set if failed to register
		* this happens when resolver is exiting.

DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverRegister	proc	near
		uses	ax,bx,cx,dx,di,si,bp,ds
		.enter
	;
	; If anyone else is registered, resolver has been initialized
	;
		GetDgroup ds, bx
		PSem	ds, mutex
		inc	ds:registerCount
		cmp	ds:registerCount, 1
LONG		ja	success 		; there's another client
	;
	; Check if detach timer started
	;
		test	ds:resolverStatus, mask RSF_TIMER_STARTED
		jz	firstRegister		; we are the first to register
	;
	; Nobody is currently registered, but the detach timer has been
	; started.  In this case, we just stop the timer, and proceed.
	; We should not initialize things but just use the current setup.
	;
		movdw	axbx, ds:detachTimer
		call	TimerStop
		BitClr	ds:resolverStatus, RSF_TIMER_STARTED
		jmp	success
firstRegister:
	;
	; Reinitialize resolver status flag
	;
EC <		Assert_dgroup	ds					>
		BitClr	ds:resolverStatus, RSF_SHUTTING_DOWN
	;
	; Create socket for datagrams
	;
		mov	ax, SDT_DATAGRAM
		call	SocketCreate	; bx = socket
LONG		jc	fail		; ax = socketError
		mov	ds:socketHandle, bx
		mov	cx, MANUFACTURER_ID_SOCKET_16BIT_PORT
		mov	dx, ds:resolverPort
		clr	bp
		call	SocketBind	; ax = socketError
LONG		jc	failFreeSocket
		inc	ds:resolverPort	; change port number
	;
	; Allocate event queue
	;
		mov	ax, size ResolverEventStruct
		mov	bx, handle ResolverQueueBlock
		mov	cl, RESOLVER_EVENT_Q_MIN_LEN
		mov	dx, RESOLVER_EVENT_Q_MAX_LEN
		call	QueueLMemCreate	; ^lbx:cx = queue
LONG		jc	failFreeSocket
		mov	ds:eventQueue, cx
	;
	; Start up event thread
	;
		mov	al, PRIORITY_STANDARD
		mov_tr	bx, cx		; bx = event queue handle
		mov	cx, segment ResolverEventThread
		mov	dx, offset  ResolverEventThread
		mov	di, RESOLVER_EVENT_THREAD_STACK
		mov	bp, handle 0
		call	ThreadCreate	; bx = thread handle, cx = 0
		jc	failFreeAll	; destroyed ax,dx,si,di,bp
	;
	; Start up server thread
	;
		mov	bx, ds:socketHandle
		mov	al, PRIORITY_UI
		mov	cx, segment ResolverServerThread
		mov	dx, offset ResolverServerThread
		mov	di, RESOLVER_SERVER_THREAD_STACK
		mov	bp, handle 0
		call	ThreadCreate	; bx = thread handle, cx = 0
		jc	failFreeAllKillServer
success:
	;
	;
	; There could have been some long time elapse between last unregister.
	; Try to update cache
	;
		call	CacheUpdateTTL
		jnc	done		; cache was last accessed within today
		call	CacheRefresh
done:
		VSem	ds, mutex
		.leave
		ret
failFreeAllKillServer:
		BitSet	ds:resolverStatus, RSF_SHUTTING_DOWN
failFreeAll:
		mov	bx, handle ResolverQueueBlock
		mov	cx, ds:eventQueue
		call	QueueLMemDestroy
fail:
		dec	ds:registerCount
		stc
		jmp	done
failFreeSocket:
		mov	bx, ds:socketHandle
		call	SocketClose
		jmp	fail
ResolverRegister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverUnregister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister with resolver
CALLED BY:	External
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing( flags preserved )
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverUnregister	proc	near
		uses	ax,bx,cx,ds,si,bp
		.enter
		pushf
		GetDgroup ds, bx
		PSem	ds, mutex
		dec	ds:registerCount
		tst	ds:registerCount
		jnz	done
	;
	; Start detach timer only if we are the last to unregister
	;
		mov	ax, TIMER_ROUTINE_ONE_SHOT
		mov	cx, RESOLVER_DETACH_DELAY
		mov	bx, segment ResolverTimeoutCallback
		mov	si, offset ResolverTimeoutCallback
		mov	bp, handle 0
		call	TimerStartSetOwner
		movdw	ds:detachTimer, axbx
		BitSet	ds:resolverStatus, RSF_TIMER_STARTED
done:
		VSem	ds, mutex
		popf
		.leave
		ret
ResolverUnregister	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverResolveAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a domain name into IP address

CALLED BY:	DR_RESOLVER_GET_ADDRESS
PASS:		ds:si	= address string( non-null terminated - doesn't matter)
		cx	= len of address string
		dx	= access point ID
RETURN:		carry set if error
			dx = ResolverError
		carry clear if successful
			dxbp = dword IP address that can be used with
			       socket library
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/16/95    	Initial version
	SJ	10/6/95		added access point parameter

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverResolveAddress	proc	far
		uses	ax,bx,cx,si,di,ds,es
		.enter
	;
	; Check parameters
	;
EC <		call	ECCheckDomainAddressString			>
	;
	; Inc address string size
	;
		push	dx		; save access id
		movdw	dxbp, dssi	; save address string
		inc	cx		; cx = address string len + nul
	;
	; Prepare parameters for DR_RESOLVER_GET_HOST_BY_NAME
	;
		mov	bx, handle ResolverAnswerBlock
		call	MemLockExcl
	;
	; Make a duplicate of address string
	; ( after this point we won't need addr fptr passed in by the caller )
	;
		mov	ds, ax
		mov	es, ax
		call	LMemAlloc		; allocate a chunk for addr str
		jc	unlockBlock		; es adjusted
		mov	di, ax
		mov	di, es:[di]		; es:di = new chunk
		movdw	dssi, dxbp		; ds:si = address string
		dec	cx			; leave room for nul
EC <		CheckMovsbIntoChunk	ax	; *es:ax = new chunk	>
SBCS <		rep	movsb			; cx: addr str len -> 0	>
if DBCS_PCGEOS
	; DBCS TBD: conversion of Unicode host address to SBCS
		jcxz	copyDone
		push	ax
copyLoop:
		lodsw				; assume high-byte 0
		stosb
		loop	copyLoop
		pop	ax
copyDone:
endif
		mov	{byte}es:[di], 0	; insert null
	;
	; Create Answer chunk array
	;
		segmov	ds, es, dx		; ds = ResolverAnswerBlock
		mov	dx, ax			; dx = name chunk
		mov	cx, size ResolverAnswerHeader
		clr	bx, si
		call	ChunkArrayCreate	; *ds:si = answer chunk array
		jc	unlockBlock
	;
	; Initialize Chunk Array
	;
		mov	di, ds:[si]		; ds:di = ResponderAnswerHeader
		pop	ds:[di].RAH_accessId	; fill in access point Id
unlockBlock:
		mov	bx, handle ResolverAnswerBlock
		call	MemUnlockShared
		jc	memError
		mov	cx, si			; ^lbx:cx = answer chunk array
		mov	si, dx			; ^lbx:si = address string
	;
	; Call real routine
	;
		call	ResolverGetHostByName	; ^lbx:cx = answer filled in
		pushf				; ds, es destroyed if they
	;					; were pointing to answer block
	; Find the desired answer
	;
		call	MemLockShared
		mov	ds, ax
		popf
		jc	freeAnswerChunk
checkAnswer::
		push	si			; save address string handle
		mov	si, cx			; *ds:si = answer chunk array
		mov	dx, RRT_A		; find address type
		mov	bx, segment FindAnswerCallback
		mov	di, offset FindAnswerCallback
		call	ChunkArrayEnum
		pop	si			; restore addr str handle
EC <		WARNING_NC RW_VERY_STRANGE				>
		jnc	notFound		; very strange
	;
	; Record result to dxbp
	; : ds:bp = answer section
	;
		add	bp, offset RAS_data
		movdw	dxax, ds:[bp]
		mov	bp, ax
		clc
freeAnswerChunk:
	;
	; ^lbx:cx = answer chunk array
	; ^lbx:si = address string
	;
		pushf
		mov	ax, cx
		call	LMemFree
		mov	ax, si
		call	LMemFree
		popf
unlockDone:
		mov	bx, handle ResolverAnswerBlock
		call	MemUnlockShared
	;
	; record error condition before returning error
	; ( if no error, do nothing )
	;
		jnc	done
		call	ResolverHandleError
		stc
done:
		.leave
		ret
memError:
		pop	dx			; pop access Id off
		mov	dx, RE_MEMORY_ERROR
		jmp	unlockDone
notFound:
		mov	dx, RE_TIMEOUT
		stc
		jmp	unlockDone
ResolverResolveAddress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverHandleError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	record number of errors occured so far in INI file
		( this error count will be used to detect possible cache
		  corruption )

CALLED BY:	ResolverResolveAddress
PASS:		dx = resolver error
RETURN:		nothing
DESTROYED:	carry cleared

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	7/29/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

errorCountStr	char	"errorCount", 0
ResolverHandleError	proc	near
		uses	ax,cx,dx,si,bp,ds
		.enter
	;
	; the following 2 errors does not indicate that cache was corrupted
	;
		cmp	dx, RE_INFO_NOT_AVAILABLE
		je	done
		cmp	dx, RE_HOST_NOT_AVAILABLE
		je	done
	;
	; increment error count in INI file
	;
		segmov	ds, cs, ax
		mov	si, offset resCategory
		mov	cx, cs
		mov	dx, offset errorCountStr
		call	InitFileReadInteger	; ds, si, dx saved
		jnc	incWrite
	;
	; this is the first entry, pretend we read 0
	;
		clr	ax
incWrite:
	;
	; increment the number and write the result back to INI file
	;
		inc	ax
		cmp	ax, RESOLVER_FAILURE_ALLOWANCE
		jb	writeNow
	;
	; Delete the cache because we hit the failure allowance.
	; Then, clear the error record.
	;
		mov	ax, RE_DELETE_CACHE
		ResolverPostEvent_NullESDS
		clr	ax
writeNow:
		mov	bp, ax
		call	InitFileWriteInteger
		call	InitFileCommit
done:
		.leave
		ret
ResolverHandleError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverGetHostByName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the host IP address from a host name

CALLED BY:	DR_GET_HOST_BY_NAME

PASS:		^lbx:si	= name of the host( e.g. "balance.cs.mtu.edu",0 )
		^lbx:cx = chunk array used to return result

ABOUT ^lbx:cx CHUNK:
   Before you call this routine, you must allocate a chunk array with
   ResolverAnswerHeader in lmem block, and initialize its header as follows:

   RAH_common   = ChunkArrayHeader ( no need to modify )
   RAH_error    = 0
   RAH_accessId = access point ID ( see socket library definition for this )

RETURN:		if carry clr,
			^lbx:cx = filled in with IP addresses
		if carry set,
			dx = ResolverError

DESTROYED:	ds, es if they were pointing at the block that contained
		answer chunk array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverGetHostByName	proc	far
		push	bp
		mov	bp, RRT_A
		call	ResolverGetHostInfo	; ds possibly destroyed
		pop	bp
		ret
ResolverGetHostByName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverGetHostByAddr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get host name from an IP address
		Not supported yet.

CALLED BY:	DR_RESOLVER_GET_HOST_BY_ADDR

		* Not supported yet *

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverGetHostByAddr	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Not implemented yet
	;
		mov	dx, RE_UNSUPPORTED_FUNCTION
		stc
		.leave
		ret
ResolverGetHostByAddr	endp
ForceRef ResolverGetHostByAddr


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverGetHostInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets information about a given host

CALLED BY:	DR_RESOLVER_GET_HOST_INFO
PASS:		^lbx:si	= name of the host( null terminated )
		^lbx:cx = chunk array to use to return the result
		bp	= ResolverQueryType

ABOUT ^lbx:cx CHUNK ARRAY:
   Before you call this routine, you must allocate a chunk array with
   ResolverAnswerHeader in lmem block, and initialize its header as follows:

   RAH_common   = ChunkArrayHeader ( no need to modify )
   RAH_error    = 0
   RAH_accessId = access point ID ( see socket library definition for this )

RETURN:		if carry clear,
			^lbx:cx = ResolverAnswerHeader + ResolverAnswerSections
		if carry set,
			dx = ResolverError
DESTROYED:	ds, es if they were pointing at the block that contained
		answer chunk array

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverErrorConversionTable	word	\
REC_FORMAT_ERROR,	RE_INTERNAL_FAILURE,
REC_SERVER_FAILURE,	RE_TEMPORARY,
REC_NAME_ERROR,		RE_HOST_NOT_AVAILABLE,
REC_NOT_IMPLEMENTED,	RE_INFO_NOT_AVAILABLE,
REC_REFUSED,		RE_INFO_NOT_AVAILABLE,
REC_NO_NAME_SERVER,	RE_NO_NAME_SERVER,
REC_INTERRUPTED,	RE_INTERRUPTED
ResolverGetHostInfo	proc	far
NEC <		uses	ax,bx,cx,si,di,bp,ds				>
EC <		uses	ax,bx,cx,si,di,bp,ds,es				>
		.enter
	;
	; Check parameters
	;
EC <		Assert_optr	bxsi					>
EC <		Assert_optr	bxcx					>
	;
	; Register with Resolver( start up thread, etc if first time )
	;
		call	ResolverRegister
LONG		jc	registerError
	;
	; open resolver domain medium( TCP/IP )
	;
		call	OpenResolverDomainMedium
LONG		jc	openDomainError
	;
	; Allocate a semaphore to block on
	;
		push	bx
		clr	bx
		call	ThreadAllocSem	; bx = sem handle
		mov_tr	di, bx		; di = sem handle
	;
	; Allocate a request ID
	;
		call	RequestAllocId ; dx = request ID
		pop	bx
LONG		jc	deallocSem
	;
	; Enqueue initial request event
	; dx	 = request ID
	; di	 = semaphore to v to unblock client thread
	; bp	 = ResolverQueryType
	; ^lbx:si= address of the host
	; ^lbx:cx= answer chunk
	;

	;
	; duplicate ^lbx:si and pass the copy to event thread
	; ( this is done because event thread will modify contents of
	;   ^lbx:si )
	;
		call	MemLockExcl
		mov	ds, ax
		call	LMemCopyChunk	; ax = chunk handle to the duplicate
		call	MemUnlockShared
		xchg	ax, si		; ^lbx:si = a duplicate of name string
		mov	ax, RE_QUERY_INFO
		ResolverPostEvent_NullESDS
LONG		jc	done
	;
	; block until a reply comes in or timeout happens
	;
		push	cx		; save answer chunk array handle
		GetDgroup ds, cx
		xchg	bx, di
		mov	cx, ds:clientTimeout
		call	ThreadPTimedSem
		xchg	bx, di
		cmp	ax, SE_TIMEOUT
		pop	cx		; restore answer chunk array handle
LONG		je	cleanUp
		clc
finish:
	;
	; ^lbx:si = copy of domain name chunk
	; di	  = semaphore allocated for this client
	; dx	  = Request id
	;
		pushf
		call	MemLockShared
		call	IdInvalidate  ; dx is now an invalid id
				      ; synchronized in ResolverEventQueryInfo
		mov	ds, ax
		mov	ax, si
		call	LMemFree
		popf
	;
	; Check for error
	;
		mov	si, cx
		mov	si, ds:[si]
		jnc	skip
	;
	; If carry is set, we have time out error
	;
		mov	ds:[si].RAH_error, REC_SERVER_FAILURE
skip:
		mov	si, ds:[si].RAH_error
		mov	dx, RE_NO_ERROR
		tst	si
		jz	skipCheckError		; carry clear
	;
	; convert ResolverErrorCode to ResolverError
	; : convert this to table lookup when you have time
	; si = ResponseErrorCode
	;
		push	di
		mov	di, offset ResolverErrorConversionTable
matchLoop:
		cmp	di, offset ResolverErrorConversionTable +\
			    size ResolverErrorConversionTable
		jae	defaultError
		mov	dx, {word}cs:[di + size word]
		cmp	{word}cs:[di], si
		je	doneError
		add	di, size word + size word
		jmp	matchLoop
defaultError:
		mov	dx, RE_MEMORY_ERROR
doneError:
		pop	di
	;
	; dx = ResolverError
	;
		stc
skipCheckError:
		call	MemUnlockShared
		mov	bx, di
		call	ThreadFreeSem
done:
	;
	; Done with resolver, unregister
	;
		call	ResolverUnregister
reallyDone:
		.leave
		ret
deallocSem:
	;
	; deallocate the semaphore in di
	;
		mov	bx, di
		call	ThreadFreeSem		; free semaphore
		stc
		mov	dx, RE_TEMPORARY	; since some request ids
		jmp	done			; should be cleaned up later
registerError:
		mov	dx, RE_OUT_OF_RESOURCE
		jmp	reallyDone
openDomainError:
		mov	dx, RE_OPEN_DOMAIN_MEDIUM
		jmp	done
cleanUp:
	;
	; Request failed with timeout;
	; enqueue an event to terminate request
	; ( see ResolverTerminateRequestEvent )
	;
		mov	ax, RE_END_REQUEST_NO_V
		ResolverPostEvent_NullESDS	; terminate request
		stc
		jmp	finish

ResolverGetHostInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverDeleteCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all cache entries to start building cache all over
		again.

CALLED BY:	Global
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

TEST ONLY:
		if cx happens to be TEST_ONLY, we pretend a day has passed.
		* of course this is for EC testing version only.

NOTE:
   Resolver will keep each cache entry for at most 7 days.  TTL(time to live)
   value gets updated each day and expired entries will get deallocated.
   This func is provided only to make sure a way out of desperate situation.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/30/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverDeleteCache	proc	far
		uses	ax
		.enter
TESTONLY <	cmp	cx, TEST_ONLY					>
TESTONLY <	jne	normal						>
TESTONLY <	call	TwentyFourHourCallback				>
TESTONLY <	jmp	done						>
TESTONLY < normal:							>
	;
	; reinitialize cache
	;
		call	ResolverRegister
		mov	ax, RE_DELETE_CACHE
		ResolverPostEvent_NullESDS
		call	ResolverUnregister
	;
	; cache file will be overriden by current cache at the time we exit
	;
done::
		.leave
		ret
ResolverDeleteCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverStopResolve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a resolve operation.

CALLED BY:	DR_RESOLVER_STOP_RESOLVE

PASS:		ds:si	= address string (non-null terminated - doesn't matter)
		cx	= size of address string

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jwu	8/ 7/96			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverStopResolve	proc	far
		uses	ds, si, es, di, cx, ax, bx
		.enter
	;
	; Register( just in case people call this routine when there is
	;           no registered client )
	;
		call	ResolverRegister
	;
	; copy address string to a block which will be used in
	; RE_INTERRUPT_REQUEST events.  Make it a domain string representation
	; used internally in resolver.
	;
		mov	ax, cx
		add	ax, 2	; extra byte at start, and null at the end
		push	cx
		mov	cl, mask HF_SHARABLE or mask HF_SWAPABLE
		mov	ch, mask HAF_LOCK
		call	MemAlloc	; ax = segment, bx = block handle
		pop	cx
		jc	done
		mov	es, ax
		mov	di, 1
		rep movsb		; bx = block containing the string
		clr	{byte}es:[di]	;      being queried		
		call	MemUnlock
	;
	; Post RE_INTERRUPT_REQUEST
	;
		mov	ax, RE_INTERRUPT_QUERY
		call	ResolverPostEvent
	;
	; Unregister
	;
		call	ResolverUnregister
done:
		.leave
		ret
ResolverStopResolve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenResolverDomainMedium
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open TCP/IP domain medium so that we can send/receive
		data

CALLED BY:	ResolverGetHostInfo
PASS:		^lbx:cx = answer chunk array
			  ( see ResolverAnswerHeader, ResolverAnswerSection )
RETURN:		carry set if error encounterd
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jang	9/19/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenResolverDomainMedium	proc	near
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Get Access ID
	;
		call	MemLockShared
		mov	ds, ax
		mov	si, cx
		mov	si, ds:[si]
		mov	dx, ds:[si].RAH_accessId
		call	MemUnlockShared
	;
	; Open medium: just to make sure that the link is there
	;
		GetDgroup es, bx
		mov	bx, es			; bx = dgroup seg
		mov	es:[socketAddress].SA_domain.high, bx
		mov	es:[socketAddress].SA_domain.low, offset socketDomain
		mov	es:[linkId], dx
		mov	cx, es
		mov	dx, offset socketAddress
		mov	bp, OPEN_DOMAIN_TIMEOUT
		call	SocketOpenDomainMedium		; ax = SocketError
		
		.leave
		ret
OpenResolverDomainMedium	endp

ResolverCommonCode	ends

ResolverResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverTimeoutCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach timeout occured; post RE_DETACH event
CALLED BY:	ResolverUnregister via timer interrupt code (be careful!)
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	; We turn off read/write checking for this routine, because
	; r/w checking code grabs heap semaphore, which should not occur in
	; timer invoked routines.  --- AY 11/9/95
		.norcheck
		.nowcheck

ResolverTimeoutCallback	proc	far
		.enter
	;
	; Clear RSF_TIMER_STARTED
	;
		GetDgroup ds, ax

	;
	; This flag should be cleared in RE_DETACH handler when we know for
	; sure that nobody is registered.  If this is cleared here,
	; somebody may call ResolverRegister between the time ObjMessage
	; queues the event to ui thread and the time RE_DETACH event is
	; actually handled, which causes trouble.
	;
	;	BitClr	ds:resolverStatus, RSF_TIMER_STARTED
	;
		
	;
	; Send detach event
	; : since we are in interrupt code, we cannot call a routine in a
	;   movable resource (not to mention a routine that does PSem.)  Hence
	;   we tell the UI thread to call it for us.
	;
		mov	ax, SGIT_UI_PROCESS
		call	SysGetInfo		; ax = UI thread hptr
		mov_tr	bx, ax			; bx = UI thread hptr

		mov	dx, size ProcessCallRoutineParams
		sub	sp, dx
		mov	bp, sp		; ss:bp = ProcessCallRoutineParams
		mov	ss:[bp].PCRP_address.segment, vseg ResolverPostEvent
		mov	ss:[bp].PCRP_address.offset, offset ResolverPostEvent
		mov	ss:[bp].PCRP_dataAX, RE_DETACH
		mov	ax, MSG_PROCESS_CALL_ROUTINE
		mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
		call	ObjMessage
		add	sp, dx		; pop ProcessCallRoutineParams

		.leave
		ret
ResolverTimeoutCallback	endp

ifdef	READ_CHECK
		.rcheck
endif

ifdef	WRITE_CHECK
		.wcheck
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindAnswerCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the desired answer in an answer chunkarray

CALLED BY:	ResolverGetAddress( via ChunkArrayEnum )
PASS:		ds:di	= current element
		dx	= type of ResourceRecord to find
RETURN:		carry set if target was found
		ds:bp	= ResolverAnswerSection that contains the answer
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindAnswerCallback	proc	far
	;
	; Compare the answer type with the type passed in
	;
		cmp	ds:[di].RAS_type, dx
		mov	bp, di
		je	cont				; carry clear
		stc
cont:
		cmc
		ret
FindAnswerCallback	endp

ResolverResidentCode	ends

ResolverCommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverAddDhcpDnsServers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the DNS servers found via DHCP.

CALLED BY:	TCPIP
PASS:		dx	- Size of DNS server list buffer
		es:di	- DNS server ip's
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/06/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverAddDhcpDnsServers	proc	far
		uses	ds
		.enter
		;pusha
		push	ax, cx, dx, bx, bp, si, di

		mov	bx, handle dgroup
		call	MemDerefDS
		cmp	dx, IP_ADDR_SIZE
		jb	done
		movdw	ds:[dhcpDns1], ({dword}es:[di]), ax
		cmp	dx, (IP_ADDR_SIZE*2)
		jb	done
		movdw	ds:[dhcpDns2], ({dword}es:[di+IP_ADDR_SIZE]), ax

done:
		pop	ax, cx, dx, bx, bp, si, di
		;popa
		.leave
		ret
ResolverAddDhcpDnsServers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverAddDhcpDnsServers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the DNS servers found via DHCP.

CALLED BY:	TCPIP
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	2/12/01    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverRemoveDhcpDnsServers	proc	far
	uses	ax, bx, ds
	.enter

	mov	bx, handle dgroup
	call	MemDerefDS
	clr	ax
	clrdw	ds:[dhcpDns1], ax
	clrdw	ds:[dhcpDns2], ax
	call	ResolverRegister
	mov	ax, RE_REQUEST_RESTART
	mov	bx, RRR_DHCP_EXPIRED
	call	ResolverPostEvent
	call	ResolverUnregister

	.leave
	ret
ResolverRemoveDhcpDnsServers	endp

ResolverCommonCode	ends
