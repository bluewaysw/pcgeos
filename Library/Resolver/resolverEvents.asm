COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Socket project
MODULE:		resolver
FILE:		resolverEvent.asm

AUTHOR:		Steve Jang, Dec 14, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94   	Initial revision

DESCRIPTION:
	Resolver event handlers.

	$Id: resolverEvents.asm,v 1.24 98/10/01 17:14:55 reza Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResolverResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetches events from event queue and processes it

CALLED BY:	ThreadCreate
PASS:		cx	= queue handle( queue is in ResolverQueueBlock )
RETURN:		nothing
DESTROYED:	everthing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventThread	proc	far
		mov_tr	si, cx			; ^lbx:si = queue
eventLoop:
		mov	bx, handle ResolverQueueBlock
		mov	cx, FOREVER_WAIT
		call	QueueDequeueLock	; ds:di = front entry
		push	si			; cx = size of the entry
EC <		ERROR_C	RFE_GENERAL_FAILURE	; this should never happen>
NEC <		WARNING_C RW_ERROR_LOCKING_BAD_BAD_BAD ; warn the QAs	>
NEC <		jc	errorLocking		; this is better than crash>
		mov	ax, ds:[di].RES_ax
		mov	bx, ds:[di].RES_bx
		mov	cx, ds:[di].RES_cx
		mov	dx, ds:[di].RES_dx
		mov	bp, ds:[di].RES_bp
		mov	es, ds:[di].RES_es
		push	ds:[di].RES_ds, ds:[di].RES_si
		mov	di, ds:[di].RES_di
		call	QueueDequeueUnlock	; nothing changed
		pop	ds, si
		push	ax			; save ResolverEvent
		call	ResolverHandleEvent	; everthing destroyed
		pop	ax			; ax = ResolverEvent
	;
	; Jump to ThreadDestroy if RE_DETACH.  We have to jump here instead of
	; in the RE_DETACH handler because the handler is in a movable resource
	; and we don't want to leave the resource locked forever.
	; --- AY 4/12/96
	;
		cmp	ax, RE_DETACH
		jne	continue
	;
	; if there is any client, we can't kill the event thread
	;
		GetDgroup ds, ax
		tst	ds:registerCount
		jnz	continue
	;
	; destroy the thread
	;
		clr	cx, dx
		jmp	ThreadDestroy

continue:

errorLocking::
		pop	si			; *ds:si = queue
	;
	; At this point, ResolverRequestBlock and ResolverCacheBlock must
	; be unlocked by convention
	;
	; ResolverRequestBlock may be locked at this time by an outside
	; client trying to make a request, so do not check its lock count.
	; -dhunter 8/26/2000
	;
EC <		mov	bx, handle ResolverCacheBlock			>
EC <		mov	ax, MGIT_FLAGS_AND_LOCK_COUNT			>
EC <		call	MemGetInfo	; ah = lock count		>
EC <		tst	ah						>
EC <		ERROR_NZ RFE_INFO_BLOCK_LOCKED				>
		jmp	eventLoop
ResolverEventThread	endp

ResolverResidentCode	ends

ResolverActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverPostEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Post an event to the event queue

IMPORTANT:	ResolverRequestBlock and ResolverCacheBlock segments cannot
		be passed in as arguments to any event.  If either block
		segment	is passed in in ES or DS, they will be converted to
		a null segment.

		The reason for this is:

		* At the beginning of each event handler, it is always
		  assumed that ResolverRequestBlock and ResolverCacheBlock
		  are unlocked.  This insures mutually exclusive access to
		  cache among events.

		* some routines might post an event when it has either of
		  the blocked locked in ds or es, and then unlock them after
		  ResolverPostEvent call returns( but the event not handled
		  yet. )

		When you call the routine, DS/ES can only contain one of the
		following:
		1. dgroup
		2. some segment that is not ResolverCacheBlock or
		   ResolverRequestBlock

		Use this macro if you are not passing any value in ES/DS:
		ResolverPostEvent_NullESDS

CALLED BY:	Utility
PASS:		ax	= event code
		rest	= variable
RETURN:		carry set on error
		ax = QueueErrors
DESTROYED:	ax

EC ONLY BUG(?):	any segment reg containing handle of ResolverRequestBlock or
		RequestCacheBlock in LMBH_handle location will be converted
		to NULL_SEGMENT.  Passing segments of these two blocks are
		not allowed to be passed in as parameters.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverPostEvent	proc	far
		uses	bx,cx,si,di,bp,es,ds
		.enter
	;
	; Check DS for ResolverRequestBlock or ResolverCacheBlock segment
	;
		push	di
EC <		mov	di, ds						>
EC <		cmp	di, NULL_SEGMENT				>
EC <		je	cont1						>
EC <		cmp	ds:LMBH_handle, handle ResolverRequestBlock	>
EC <		je	convert1					>
EC <		cmp	ds:LMBH_handle, handle ResolverCacheBlock	>
EC <		jne	cont1						>
EC < convert1:								>
EC <		mov	di, NULL_SEGMENT				>
EC <		mov	ds, di						>
EC < cont1:								>
	;
	; Lock the queue
	;
		push	ds
		push	bx, cx, si
		GetDgroup ds, bx
		mov	bx, handle ResolverQueueBlock
		mov	si, ds:eventQueue
		mov	cx, RESIZE_QUEUE
		call	QueueEnqueueLock	; ds:di = ResolverEventStruct
		jc	failed			; cx    = element size
		mov	ds:[di].RES_ax, ax
		mov	ds:[di].RES_dx, dx
		mov	ds:[di].RES_bp, bp
	;
	; check ES for ResolverRequestBlock or ResolverCacheBlock segment
	;
EC <		mov	ax, es						>
EC <		cmp	ax, NULL_SEGMENT				>
EC <		je	cont2						>
EC <		cmp	es:LMBH_handle, handle ResolverRequestBlock	>
EC <		je	convert2					>
EC <		cmp	es:LMBH_handle, handle ResolverCacheBlock	>
EC <		jne	cont2						>
EC < convert2:								>
EC <		mov	ax, NULL_SEGMENT				>
EC <		mov	es, ax						>
EC < cont2:								>
		mov	ds:[di].RES_es, es
		segmov	es, ds, ax
		mov_tr	bp, di
		pop	es:[bp].RES_bx, es:[bp].RES_cx, es:[bp].RES_si
		pop	es:[bp].RES_ds
		pop	es:[bp].RES_di
		call	QueueEnqueueUnlock
		clc
done:
		.leave
		ret
failed:
		mov	ax, cx
		jmp	done
ResolverPostEvent	endp

DefResolverEvent macro proc, cnst
.assert ($-ResolverEventTable) eq cnst, <event table is corrupted>
.assert (type proc eq near), <event handler should be a near routine>
		nptr proc
		endm

ResolverEventTable label nptr
DefResolverEvent ResolverEventQueryInfo,	RE_QUERY_INFO
DefResolverEvent ResolverEventQueryName,	RE_QUERY_NAME
DefResolverEvent ResolverEventSpawnChildQuery,	RE_SPAWN_CHILD_QUERY
DefResolverEvent ResolverEventQueryNameServers,	RE_QUERY_NAME_SERVERS
DefResolverEvent ResolverEventRequestRestart,	RE_REQUEST_RESTART
DefResolverEvent ResolverEventEndRequest,	RE_END_REQUEST
DefResolverEvent ResolverEventEndRequestNoV,	RE_END_REQUEST_NO_V
DefResolverEvent ResolverEventResponse,		RE_RESPONSE
DefResolverEvent ResolverEventDetach,		RE_DETACH
DefResolverEvent ResolverEventReduceCache,	RE_REDUCE_CACHE
DefResolverEvent ResolverEventUpdateCache,	RE_UPDATE_CACHE
DefResolverEvent ResolverEventDeleteCache,	RE_DELETE_CACHE
DefResolverEvent ResolverEventQueryTimerExpired,RE_QUERY_TIMER_EXPIRED
DefResolverEvent ResolverEventInterruptQuery,	RE_INTERRUPT_QUERY


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverHandleEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles an event fetched by event thread

CALLED BY:	ResolverEventThread
PASS:		ax	= event code
		rest	= variable
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverHandleEvent	proc	far

ifdef LOG_IN_INI_FILE
		call	LogResolverEventIn
endif
		push	ax
		xchg	ax, di
		mov	di, cs:[ResolverEventTable][di]
		xchg	ax, di
		call	{nptr}ax
		pop	ax

ifdef LOG_IN_INI_FILE
		call	LogResolverEventOut
endif

		ret
ResolverHandleEvent	endp

ifdef LOG_IN_INI_FILE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogResolverEventInIniFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Logs events in ini file

CALLED BY:	ResolverHandleEvent
PASS:		ax	= event code
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	reza    	9/29/98    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LogResolverEventIn	proc	near
	uses	dx
	.enter
		mov	dx, offset inKey
		call	LogResolverEventInIniFile
	.leave
	ret
LogResolverEventIn	endp

LogResolverEventOut	proc	near
	uses	dx
	.enter
		mov	dx, offset outKey
		call	LogResolverEventInIniFile
	.leave
	ret
LogResolverEventOut	endp

;
; LogResolverEventInIniFile
;
; Pass:		ax = event code
;		dx = offset to ini file keyword
; Return:	nothing
; Destroyed:	nothing
;
LogResolverEventInIniFile	proc	near
	uses	cx, dx, bp, ds, si
	.enter
		mov	bp, ax
		segmov	ds, cs, si
		mov	si, offset resolverCategory
		mov	cx, cs
		call	InitFileWriteInteger
		call	InitFileCommit
	.leave
	ret
LogResolverEventInIniFile	endp

resolverCategory char "resolver", 0
inKey		 char "eventIn", 0
outKey		 char "eventOut", 0

endif ; LOG_IN_INI_FILE

; ============================================================================
;
; 				EVENT HANDLERS
;
; ============================================================================

;
; All event handlers return nothing and destroy everything
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventQueryInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query information about a node in DNS
CALLED BY:	RE_QUERY_INFO
PASS:		dx	  = request ID
		bp	  = ResolverQueryType
		di	  = semaphore to V when result was obtained
	  	^lbx:si = name of the host
	  	^lbx:cx = chunk array passed in by the caller
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventQueryInfo	proc	near
TESTP <		WARNING	TEST_RE_QUERY_INFO				>
	;
	; Allocate request entry
	;
		push	di
		call	MemLockExcl		; locking answer block
	;					; synchronizes IdCheck also
	; Check if the id is valid.  If the id is not valid, this is a
	; dead event.  Client who posted RE_QUERY_INFO may timeout even before
	; this routine is reached.  In which case ^lbx:si and ^lbx:cx are
	; completely invalid.
	;
		call	IdCheck
LONG		jz	invalidId		; id is invalid
		mov	ds, ax
		mov	es, ax
		mov	ax, bp
		call	DomainNameInsertByte	; insert extra byte at start
LONG		jc	unlockExitPop		
		mov	di, es:[si]		; es:di = name with extra byte
		call	ConvertToDomainName	; es:di converted to DNS format
		call	RequestCreate		; ds:si = request node
						; ds:*bp = same as ds:si
EC <		WARNING_C RW_MEMORY_ERROR				>
LONG		jc	unlockExitPop		
	;
	; Initialize request node( in ResolverRequestBlock )
	; ds:si = new request node
	; *es:cx= answer chunk array
	;
		pop	ds:[si].RN_blockSem	; recover block sem
		BitSet	ds:[si].NC_flags, NF_INIT_REQUEST
		mov	ds:[si].RN_id, dx
		mov	ds:[si].RN_stype, ax
		mov	ds:[si].RN_sclass, NC_IN
		movdw	ds:[si].RN_answer, bxcx
		mov	ds:[si].RN_slist, 0
		mov	ds:[si].RN_matchCount, 0
		mov	ds:[si].RN_queryTimer.low, 0
		mov	ds:[si].RN_queryTimer.high, 0
	;
	; Get access ID
	;
		push	di			; save offset to domain name
		mov	di, cx
		mov	di, es:[di]
		mov	di, es:[di].RAH_accessId
		mov	ds:[si].RN_accessId, di
	;
	; Add request node to request tree
	;
		mov	di, ds:RBH_root
		mov	di, ds:[di]		; ds:di = root node
		call	TreeAddChild		; nothing changed
		pop	di			; es:di = domain name passed in
	;
	; Check local cache for information
	;
		mov	dx, ax			; dx = type we are looking for
		push	ds, si			; save request node
		call	RecordFind		; ds:si = destroyed or
LONG		jnc	foundLocal		; ds:si = ResourceRecord
		pop	ds, si
	;
	; Initialize timestamp and work allowed
	;
		call	TimerGetCount		; bxax = current time
		clr	dx
		mov	cx, RESOLVER_REQUEST_TTL
		adddw	bxax, cxdx
		movdw	ds:[si].RN_timeStamp, bxax
		mov	ds:[si].RN_workAllowed, RESOLVER_REQUEST_WORK_ALLOWED
	;
	; Initialize Slist
	; es:di = domain name passed in
	; *ds:bp= current RequestNode
	; ds:si = current RequestNode
	;
		call	SlistInitialize		; ax = chunk handle of slist
EC <		WARNING_C RW_SLIST_PROBLEM				>
LONG		jc	slistProblem		; cx = match count
						; si,di,ds,es trashed
		mov	bx, handle ResolverRequestBlock
		call	MemDerefDS		; dereference Request Block
		mov	si, ds:[bp]		; dereference RequestNode
		mov	ds:[si].RN_slist, ax
		mov	ds:[si].RN_matchCount, cx
	;
	; Send queries
	;	
		mov	dx, ds:[si].RN_id
		mov	ax, RE_QUERY_NAME_SERVERS
		ResolverPostEvent_NullESDS
TESTP <		WARNING	TEST_AT_CR_2					>
unlockRequestExit:
	;
	; Unlock request node and exit
	;
		mov	ax, ds:[si].RN_answer.segment
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
		mov	bx, ax
unlockExit:
	;
	; bx = mem handle of answer chunk array
	;
		call	MemUnlockShared
		ret
invalidId:
		pop	di
		jmp	unlockExit
unlockExitPop:
		pop	di
		jmp	unlockExit
foundLocal:
	;
	; on stack: seg, offset of current RequestNode
	; ds:si = first ResourceRecord found
	; dx = ResourceRecordType
	;
		pop	es, di		; es:di = RequestNode
		push	bx		; save bx whatever it is
		mov	bx, es:[di].RN_answer.high
		call	MemUnlockShared	; unlock answer block
		call	ConstructAnswer	; ds:si unlocked
		call	MemLockExcl	; relock it so that it can be unlocked
		pop	bx		; restore bx
	;
	; Exit the client request
	;
		mov	dx, es:[di].RN_id
		push	es, di		; save RequestNode
		mov	ax, RE_END_REQUEST
		ResolverPostEvent_NullESDS
		pop	ds, si		; restore RequestNode
TESTP <		WARNING	TEST_AT_CR_1					>
		jmp	unlockRequestExit
		
cannotOpenDomain::
	;
	; *ds:bp= current RequestNode
	; ds:si = current RequestNode
	;
	; First we write some error message in answer chunk.
	;
	;	movdw	bxdi, ds:[si].RN_answer
	;	call	MemDerefES		; deref answer chunk
	;	mov	di, es:[di]
	;	mov	es:[di].RAH_error, REC_CANNOT_OPEN_DOMAIN
	;	jmp	endRequest
	;
slistProblem:
	;
	; We could not initialize SLIST and we are in deep trouble.
	; we have a request node that will probably sit there for a couple
	; of minutes doing nothing while the frustrated user is pounding on
	; random keys...  we don't want that.  So, we at least free the request
	; node and return an error message or something.
	;
	; es:di = domain name passed in
	; *ds:bp= current RequestNode
	; ds:si = current RequestNode

	;
	; First we write some error message in answer chunk.
	;
		mov	bx, handle ResolverRequestBlock
		call	MemDerefDS
		mov	si, ds:[bp]		; deref request node
		movdw	bxdi, ds:[si].RN_answer
		call	MemDerefES		; deref answer chunk
		mov	di, es:[di]
		mov	es:[di].RAH_error, REC_NO_NAME_SERVER
endRequest::
	;
	; Queue an end request event
	;
		mov	dx, ds:[si].RN_id
		mov	ax, RE_END_REQUEST
		ResolverPostEvent_NullESDS
		jmp	unlockRequestExit
		
ResolverEventQueryInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventQueryName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query name for an IP address
CALLED BY:	RE_QUERY_NAME
PASS:		Not implemented
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventQueryName	proc	near
TESTP <		WARNING	TEST_RE_QUERY_NAME				>
		ret
ResolverEventQueryName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventSpawnChildQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spawn a child query for a given parent query
CALLED BY:	RE_SPAWN_CHILD_QUERY
PASS:		cx	= domain name handle
		dx	= request id of parent
		bp	= parent request node handle
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventSpawnChildQuery	proc	near
TESTP <		WARNING	TEST_RE_SPAWN_CHILD_QUERY			>

	;
	; Lock query message block to store our domain name temporarily
	;
		GetDgroup es, bx
		mov	bx, es:queryMessage
		call	MemLock		; should be unlocked at some point
		mov	es, ax		; es = message buffer block
	;
	; Verify that we still need to spawn a request
	; : This is necessary since a request node might go away between the
	;   time this event was enqueued and the time it actually got here.
	;
	;
		mov_tr	bx, bp		; bx = parent request node handle
		call	TreeSearchId	; ds:si/*bp = parent( locked )
LONG		jc	unlockBuffer
		cmp	bx, bp
LONG		jne	unlockExit
	;
	; Find the domain name to query
	; cx = domain name chunk handle to find
	;
		mov_tr	dx, bx		; dx = parent request node handle
		mov	bp, si		; ds:[bp] = parent
		mov	si, ds:[si].RN_slist
		mov	bx, segment FindNameServerCallback
		mov	di, offset FindNameServerCallback
		call	ChunkArrayEnum	; ds:ax = current SlistElement
		mov_tr	bx, dx		; dx = parent request node handle
		mov	di, ax		; ds:di = SlistElement
LONG		jnc	unlockExit
	;
	; Create request node
	; [ ResolverRequestBlock locked in ds ]
	; ds:*bx = Parent node
	; ds:di  = SlistElement in Parent
	;
	; Copy domain name to queryMessage block since RequestCreate cannot
	; get domain name in ResolverRequestBlock.  The reason being that
	; any fptr into ResolverRequestBlock will become invalid when
	; RequestCreate routine allocates a node in request tree.
	;
		push	ds:[di].SE_serverName	; save domain name chunk handle
		push	si, bx			; save slist & parent node
		mov	cx, ds:[di].SE_nameLen
		mov	si, ds:[di].SE_serverName
		mov	si, ds:[si]		; ds:si = domain name to copy
		mov	di, offset RM_data	; es:di = buf for domain name
		push	cx
		rep movsb
		pop	cx
		mov	di, offset RM_data
		pop	si, bx		; ds:*bx = Parent node, si = slist
		call	RequestCreate	; ds:si/*bp = request node created
					; ResolverRequestBlock locked once more
EC <		WARNING_C RW_MEMORY_ERROR				>
LONG		jc	unlockExitPop
	;
	; Dereference parent node
	;
		mov	di, ds:[bx]	; ds:di = parent node
	;
	; Initialize request node & query name servers
	;
		call	TreeAddChild	; no change
		call	RequestAllocId	; dx = new id
		mov	ds:[si].RN_id, dx
		mov	ds:[si].RN_stype, RRT_A
		mov	ds:[si].RN_sclass, NC_IN
		mov	ds:[si].RN_nameLen, cx
		clr	ax
		pop	ds:[si].RN_answer.low	; pop domain name chunk handle
		mov	ds:[si].RN_answer.high, ax
		mov	ds:[si].RN_blockSem, ax
		mov	ds:[si].RN_timeStamp.high, ax
		mov	ds:[si].RN_timeStamp.low, ax
		mov	ds:[si].RN_workAllowed, ax
		mov	dx, ds:[di].RN_accessId	; copy parent's access id
		mov	ds:[si].RN_accessId, dx
		mov	ds:[si].RN_queryTimer.low, ax
		mov	ds:[si].RN_queryTimer.high, ax
	;
	; initialize slist/matchCount/answer
	; dx = accessId
	;
		mov	ax, ds:[si].NC_flags
		and	ax, mask NF_LEVEL
		cmp	ax, MAX_REQUEST_TREE_DEPTH
		jae	useAccPnt
initSlist::
		mov	di, offset RM_data
		call	SlistInitialize		; ax = chunk handle of slist
EC <		WARNING_C RW_SLIST_PROBLEM	; cx = match count	>
		jc	slistProblem
		jmp	slistReady
useAccPnt:
	;
	; Since our request tree is too deep, we just use DNS address from
	; access point library
	; dx	= access id
	; ds	= ResolverRequestBlock segment
	;
		push	bx, cx
		clr	al
		mov	bx, size SlistElement
		clr	cx, si
		call	ChunkArrayCreate	; *ds:si = array
		pop	bx, cx
		jc	slistProblem
		call	SlistUseAccessPoint	; *ds:si filled in
		mov	ax, si			; ax = chunk handle of slist
EC <		WARNING_C RW_SLIST_PROBLEM	; cx = -1		>
	;
	; # of labels to match = number of labels there are...
	;
		push	es, di
		mov	di, ds:[bp]
		add	di, offset RN_name
		call	DomainNameCountLabels	; cx = # of labels to match
		pop	es, di
		JC	slistProblem
slistReady:
	;
	; Dereference RequestNode
	;
		mov	bx, handle ResolverRequestBlock
		call	MemDerefDS
		mov	si, ds:[bp]
		mov	ds:[si].RN_slist, ax
		mov	ds:[si].RN_matchCount, cx
	;
	; Query name servers
	;
		mov	dx, ds:[si].RN_id
		mov	ax, RE_QUERY_NAME_SERVERS
		ResolverPostEvent_NullESDS
unlockTwiceExit:
	;
	; we need to unlock twice since RequestBlock was locked by
	; RequestCreate once more.
	;
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock	; we need to unlock twice
unlockExit:
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
unlockBuffer:
		GetDgroup ds, bx
		mov	bx, ds:queryMessage
		call	MemUnlock
done::
		ret
unlockExitPop:
		pop	di
		jmp	unlockExit
slistProblem:
	;
	; We cannot find the address of name server, so we mark error in
	; the answer chunk and exit.
	;
		jmp	unlockTwiceExit
ResolverEventSpawnChildQuery	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventQueryNameServers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query name servers of a request
CALLED BY:	RE_QUERY_NAME_SERVERS
PASS:		dx	= request id
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventQueryNameServers	proc	near
TESTP <		WARNING	TEST_RE_QUERY_NAME_SERVERS			>
	;
	; Find the request node
	;
		call	TreeSearchId	; ds:si = RequestNode
		jc	done
	;
	; Determine RN_queryTimeout
	; t2 = t1 / ( NS count * retry count )
	; t2 = t2 < min timeout ? min timeout : t2
	;
		GetDgroup es, ax
		push	si			; save request node
		mov	si, ds:[si].RN_slist
		call	ChunkArrayGetCount	; cx = count of slist elts
		clr	dx
		mov	ax, es:clientTimeout
		div	cx
		clr	dx
		mov	cx, es:nsRetry
		div	cx
		cmp	ax, es:minQueryTimeout
		ja	longEnough
		mov	ax, es:minQueryTimeout
longEnough:
		cmp	ax, es:maxQueryTimeout
		jb	shortEnough
		mov	ax, es:maxQueryTimeout
shortEnough:
		pop	si		; ds:si = request node
		mov	ds:[si].RN_queryTimeout, ax
	;
	; Query name servers
	;
		call	QueryNameServers
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
done:
		ret
ResolverEventQueryNameServers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventRequestRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restart a request afresh
CALLED BY:	RE_REQUEST_RESTART
PASS:		bx	= RequestRestartReason
		dx	= request id
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/18/95    	Initial version
	ed	2/12/01		DHCP Expire support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventRequestRestart	proc	near
TESTP <		WARNING	TEST_RE_REQUEST_RESTART				>
	;
	; First check if handling a DHCP expiration event. If so, don't
	; worry about request nodes, as we don't have one.
	;
		cmp	bx, RRR_DHCP_EXPIRED
		jne	notDhcp
		mov	bx, handle ResolverRequestBlock
		call	MemLock
		je	doRequestRestart
	;
	; Find request node
	;
notDhcp:
		call	TreeSearchId		; ds:si/*bp = RequestNode
		jc	done
	;
	; Check local cache for answer
	;
		segmov	es, ds, ax
		mov	di, si
		add	di, offset RN_name
		mov	dx, ds:[si].RN_stype
		push	ds, si
		call	RecordFind		; ds:si = ResourceRecord found
		jnc	foundInCache
		pop	ds, si
	;
	; restart reqeust
	;
doRequestRestart:
		call	RequestRestart
doneUnlock:
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
done:
		ret
foundInCache:
	;
	; ds:si = first ResourceRecord found
	;
		mov	bx, ds:LMBH_handle
		call	HugeLMemUnlock
	;
	; return the answer since we have found what we were looking for
	;
		pop	ds, si		; ds:si/*bp = RequestNode
		call	ResponseReturnAnswer
	;
	; Exit the client request
	;
		mov	dx, es:[di].RN_id
		mov	ax, RE_END_REQUEST
		ResolverPostEvent_NullESDS
		jmp	doneUnlock
ResolverEventRequestRestart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventEndRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a query request by deallocating it
CALLED BY:	RE_END_REQUEST
PASS:		dx	= request ID
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventEndRequest	proc	near
TESTP <		WARNING	TEST_RE_END_REQUEST				>
		mov	cx, UNBLOCK
		call	ResolverEndRequestCommon
TESTP <		WARNING	TEST_AT_ER_1					>
		ret
ResolverEventEndRequest	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventEndRequestNoV
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a query request by deallocating it
CALLED BY:	RE_END_REQUEST_NO_V
PASS:		dx	= request ID
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventEndRequestNoV	proc	near
		mov	cx, DO_NOT_UNBLOCK
		call	ResolverEndRequestCommon
		ret
ResolverEventEndRequestNoV	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEndRequestCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End a query request by deallocating it
CALLED BY:	ResolverEventEndRequest or ResolverEventEndRequestNoV
PASS:		dx	= request ID
		cx	= UNBLOCK / DO_NOT_UNBLOCK
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEndRequestCommon	proc	near
	;
	; Find the request and terminate it
	;
		call	TreeSearchId ;ds:di = prev node, ds:si/*bp = node found
		jc	finish	     ; request exited already
		call	TreeRemoveNode
		call	RequestExit
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
finish:
		ret
ResolverEndRequestCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A response is received
CALLED BY:	RE_RESPONSE
PASS:		^lbx:bp	= packet received
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventResponse	proc	near
TESTP <		WARNING	TEST_RE_RESPONSE				>
	;
	; Find the relevant request
	;
		call	HugeLMemLock
		mov	es, ax
		mov	di, es:[bp]
		call	ResponseCacheData
		mov	dx, es:[di].RM_id
		mov	cx, bp		; cx = chunk handle of packet
		push	di		; save fptr to the packet
		call	TreeSearchId	; ds:di = prev node, ds:si/*bp = target
		pop	di
TESTP <		WARNING_C NO_REQUEST_FOUND_FOR_RESPONSE			>
		jc	discardNoUnlock
checkError::
	;
	; Check for error
	; ^lbx:cx = packet
	; es:di   = packet
	; ds:si/*bp = request
	; dx = request id
	;
		call	ResponseCheckError
		jnc	checkCname
	;
	; handle error if error code was returned from NS
	; dx = request id
	;
TESTP <		tst	ax						>
TESTP <		WARNING_NZ RESPONSE_CONTAINS_DEFINED_ERROR		>
TESTP <		WARNING_Z RESPONSE_CORRUPTED				>
TESTP <		jz	discard						>
		call	ResponseHandleError
discard:
	;
	; Discard packet
	; ^lbx:cx = packet
	; es:di   = packet
	; ds:si/*bp = request
	;
		mov_tr	ax, bx
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
		mov_tr	bx, ax
discardNoUnlock:
		mov	ax, bx
		call	HugeLMemUnlock
		call	HugeLMemFree
		ret		
checkCname:
	;
	; Check for CNAME
	; ^lbx:cx = packet
	; es:di   = packet
	; ds:si/*bp = RequestNode
	; dx = request id
	;
		call	ResponseCheckCname	; es:dx	= cname found
		jc	checkAnswer
TESTP <		WARNING	RESPONSE_CONTAINS_ALIAS				>
		call	RequestChangeSname	; ds,si changed while realloc
		jc	discard
	;
	; Post RE_REQUEST_RESTART event
	;
		push	bx
		mov	bx, RRR_SNAME_CHANGED
		mov	dx, ds:[si].RN_id
		mov	ax, RE_REQUEST_RESTART
		ResolverPostEvent_NullESDS
		pop	bx
		jmp	discard
checkAnswer:
	;
	; Check for answer
	; ^lbx:cx = packet
	; es:di   = packet
	; ds:si/*bp = request
	; dx = request id
	;
		call	ResponseCheckAnswer
		jc	checkDelegation
TESTP <		WARNING	RESPONSE_CONTAINS_ANSWER			>
		call	ResponseReturnAnswer	; no change
		jmp	discard
checkDelegation:
	;
	; Check for delegation
	; ^lbx:cx = packet
	; es:di   = packet
	; ds:si/*bp = request
	; dx = request id
	;
		call	ResponseCheckDelegation
		jc	discard
TESTP <		WARNING	RESPONSE_CONTAINS_DELEGATION			>
	;
	; Post RE_REQUEST_RESTART event
	;
		push	bx
		mov	bx, RRR_DELEGATION
		mov	dx, ds:[si].RN_id
		mov	ax, RE_REQUEST_RESTART
		ResolverPostEvent_NullESDS
		pop	bx
		jmp	discard
ResolverEventResponse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Kill event thread
CALLED BY:	RE_DETACH
PASS:		nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 4/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventDetach	proc	near
TESTP <		WARNING	TEST_RE_DETACH					>
	;
	; Block any new register requests
	;
		GetDgroup ds, bx
		PSem	ds, mutex
	;
	; detach timer must have expired and sent us this event
	;
		BitClr	ds:resolverStatus, RSF_TIMER_STARTED
	;
	; check if a new client registered after timer has expired and before
	; we reached this code
	;
		tst	ds:registerCount
		jnz	exit			; indeed there is a new client
	;
	; Mark as shutting down; destroy server thread
	;
		BitSet	ds:resolverStatus, RSF_SHUTTING_DOWN
	;
	; Deallocate event queue
	;
		mov	bx, handle ResolverQueueBlock
		mov	cx, ds:eventQueue
		call	QueueLMemDestroy
	;
	; Save the cache ( moved back to ResolverExit routine )
	;	call	CacheSave
	;
	; We want to wait until server thread is dead
	;
		PSem	ds, exitSem, TRASH_BX
exit:
	;
	; Unblock any blocked request
	;
		VSem	ds, mutex, TRASH_BX
	;
	; Destroy event thread
	;
	; We can't jump to ThreadDestroy here, as this is a movable routine.
	; We have to return all the way to fixed code to jump to ThreadDestroy.
	; --- AY 4/12/96
	;
		ret
ResolverEventDetach	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventReduceCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deallocate half of the cache entries

CALLED BY:	RE_REDUCE_CACHE
PASS:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventReduceCache	proc	near
		call	CacheDeallocateHalf	; ds, es destroyed
		ret
ResolverEventReduceCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventUpdateCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all cache entries that are expired

CALLED BY:	RE_UPDATE_CACHE
PASS:		nothing		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventUpdateCache	proc	near
		call	CacheUpdateTTL
		jnc	done
		call	CacheRefresh
done:
		ret
ResolverEventUpdateCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventDeleteCache
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all cache entries

CALLED BY:	RE_DELETE_CACHE
PASS:		nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	11/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventDeleteCache	proc	near
	;
	; Delete all cache entries without saving them to a file
	;
		clr	dx
		call	CacheReinitialize
		ret
ResolverEventDeleteCache	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventQueryTimerExpired
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Query timer has expired

CALLED BY:	ResolverPostEvent
PASS:		dx	= request ID

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	7/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventQueryTimerExpired	proc	near
	;
	; find the request node
	;
		call	TreeSearchId	; ds:si = RequestNode
		jc	done
	;
	; clear timer handle
	;
		clr	ds:[si].RN_queryTimer.low
		clr	ds:[si].RN_queryTimer.high
	;
	; Compare name server address just queried, and the first name server
	; in SLIST.  If they are the same, put that name server to the end of
	; SLIST.  Otherwise just query the name server at the head of SLIST.
	;
		mov	bp, si
		mov	si, ds:[si].RN_slist	; *ds:si = slist chunk array
		mov	ax, 0			; first element
		call	ChunkArrayElementToPtr	; ds:di = 1st SlistElement
EC <		ERROR_C	RFE_GENERAL_FAILURE				>
NEC <		jc	bail						>
		mov	ax, ds:[bp].RN_nsQueried
		cmp	ds:[di].SE_serverName, ax
		jne	bail			; no need to rotate
		mov	bp, si			; *ds:bp = slist chunk array
	;
	; Append the first element to the end of slist
	;
		call	ChunkArrayAppend	; ds:di = new element
		jc	bail
		push	di
		mov	ax, 0
		call	ChunkArrayElementToPtr	; ds:di = 1st element
EC <		ERROR_C	RFE_GENERAL_FAILURE				>
NEC <		jc	bailPop						>
		mov	si, di			; ds:si = first element
		segmov	es, ds, ax
		pop	di			; es:di = last element
		mov	cx, size SlistElement
		rep movsb			; copy the element
	;
	; bp still contains chunk handle for slist
	;
		mov	si, bp
		mov	ax, 0
		mov	cx, 1
		call	ChunkArrayDeleteRange
bail:
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
	;
	; Now the first element have been moved to the end of slist
	; Query the name server
	; dx = still request ID
	;
		call	TreeSearchId
EC <		ERROR_C	0						>
		call	QueryNameServers
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
done:
		ret
NEC < bailPop:								>
NEC <		pop	ax						>
NEC <		jmp	bail						>
		
ResolverEventQueryTimerExpired	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResolverEventInterruptQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt a query request for a certain domain string

CALLED BY:	RE_INTERRUPT_QUERY
PASS:		bx	= null terminated domain string block with an extra
			  byte at start
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResolverEventInterruptQuery	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
	;
	; Traverse through first generation of requests and terminate any
	; request to query for the name string
	;
		mov	dx, bx
		call	MemLock		; lock it here so we don't have to lock
		mov	es, ax		; every time callback is called
		clr	di
		call	ConvertToDomainName
	;
	; Get the root of request tree
	;
		mov	bx, handle ResolverRequestBlock
		call	MemLock
		mov	ds, ax
		mov	bp, ds:RBH_root
		mov	si, ds:[bp]
		mov	di, ds:[bp]
	;
	; call TreeEnum
	;
		mov	bx, segment InterruptQueryCallback
		mov	ax, offset InterruptQueryCallback
		call	TreeEnum
	;
	; Unlock request block
	;
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
	;
	; free the domain string block
	;
		mov	bx, dx
		call	MemUnlock
		call	MemFree
		.leave
		ret
ResolverEventInterruptQuery	endp


ResolverActionCode	ends

ResolverResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNameServerCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the domain name handle in a chunk array
CALLED BY:	ChunkArrayEnum
PASS:		ds:di	= current SlistElement
		cx	= domain name handle to find
RETURN:		carry set if name found
			ds:ax	= SlistElement that contains the id
		carry clr if not
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNameServerCallback	proc	far
		cmp	cx, ds:[di].SE_serverName
		jne	notFound
		mov	ax, di
		stc
		jmp	done
notFound:
		clc
done:
		ret
FindNameServerCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InterruptQueryCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interrupt query for the domain name string passed in

CALLED BY:	ResolveEventInterruptQuery( thru TreeEnum )
PASS:		ds:di = previous node
		ds:si = current node
		ds:*bp = current node
		cx = current level
		dx = domain name string 
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InterruptQueryCallback	proc	far
		uses	dx, bp, es
		.enter
		jc	done
		cmp	cx, 1	; we are only interested in the top level reqs
		jne	done
	;
	; compare strings
	;
		mov	bx, dx
		call	MemDerefES	; es = domain string passed in
		clr	di
		add	si, offset RN_name
		call	DomainNameCompare
		jne	done
		sub	si, offset RN_name
	;
	; first record error code in answer chunk array
	;
		mov	bx, ds:[si].RN_answer.segment
		call	MemLockShared
		mov	es, ax
		mov	di, ds:[si].RN_answer.offset
		mov	di, es:[di]
		mov	es:[di].RAH_error, REC_INTERRUPTED
		call	MemUnlockShared
	;
	; Terminate the request
	;
		mov	dx, ds:[si].RN_id
		mov	ax, RE_END_REQUEST
		ResolverPostEvent_NullESDS
done:
		clc
		.leave
		ret
InterruptQueryCallback	endp

ResolverResidentCode	ends
