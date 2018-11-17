COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	COPYRIGHT (C) GEOWORKS 1994 -- ALL RIGHTS RESERVED

PROJECT:	SOCKET PROJECT
MODULE:		RESOLVER
FILE:		RESOLVERACTIONS.ASM

AUTHOR:		STEVE JANG, DEC 14, 1994

REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	12/14/94   	INITIAL REVISION
	ED	06/13/00	Removed DHCP call

DESCRIPTION:
	INTERNAL OPERATIONS OF RESOLVER SUCH AS CACHED DOMAIN NAME TREE,
	REQUEST COORDINATION, ETC.

	$Id: resolverActions.asm,v 1.20 97/10/20 14:49:11 jang Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResolverActionCode	segment resource

; ============================================================================
;
;			       REQUEST
;
; ============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RequestCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CREATE A QUERY REQUEST
CALLED BY:	ResovlerEventQueryInfo
PASS:		ES:DI	= DOMAIN NAME WE ARE SEARCHING FOR( DNS FORMAT )
			  [ SHOULD NOT BE IN RESOLVERREQUESTBLOCK SINCE
			    THIS BLOCK WILL MOVE THE BLCOK AND INVALIDATE
			    THIS FPTR]
RETURN:		DS:SI	= REQUEST NODE( ResolverRequestBlock locked )
			  [ ONLY DOMAIN NAME AND NODE COMMON PART IS
			    INITIALIZED; BUT NOT ADDED TO TREE YET ]
		DS:*BP	= THE SAME AS DS:SI
		CARRY SET IF MEMORY ERROR, NOTHING CHANGED

DESTROYED:	ES,DI IF ES WAS SEGMENT OF ResolverRequestBlock
		SINCE A NEW NODE NEEDS TO BE ALLOCATED IN ResolverRequestBlock

REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 6/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RequestCreate	proc	near
		uses	ax,bx,cx,es,di
		.enter
	;
	; ALLOCATE A REQUEST NODE
	;
		mov	bx, handle ResolverRequestBlock
		call	MemLock
		mov	ds, ax
		clr	al
if DBCS_PCGEOS  ; always SBCS string
		push	di
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx
		pop	di
		add	cx, size RequestNode	; INCLUDES NULL
else
		call	LocalStringLength	; CX = DOMAIN NAME LENGTH
		add	cx, size RequestNode +1 ; INCLUDE NULL
endif
		call	LMemAlloc		; AX = NEW CHUNK
		JC	memError
	;
	; COPY DOMAIN NAME
	;
		sub	cx, size RequestNode	; LENGHT OF THE STRING
		mov_tr	bp, ax
		mov	si, ds:[bp]		; DS:SI = REQUESTNODE
		mov	ds:[si].RN_nameLen, cx
		add	si, offset RN_name
		xchg	di, si
		segxchg	es, ds
EC <		CheckMovsbIntoChunk bp		; *es:bp = chunk handle	>
		rep	movsb			; COPY DOMAIN NAME
		segmov	ds, es, ax
		mov	si, ds:[bp]		; DS:SI/*BP = NEW REQUEST NODE
	;
	; INITIALIZE NODECOMMON PART
	;
		clr	ds:[si].NC_flags
		mov	ds:[si].NC_child, bp	; CHILD POINTS TO ITSELF
done:
		.leave
		ret
memError:
		call	MemUnlock
		jmp	done
RequestCreate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RequestExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	FREES A REQUEST NODE
CALLED BY:	ResolverEventEndRequest
PASS:		CX	= UNBLOCK to unblock client thread
			  DO_NOT_UNBLOCK not to unblock client thread
		DS:*BP	= node to deallocate
			  [ node must have been removed from its parent ]
RETURN:		BP = destroyed
DESTROYED:	NOTHING
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 6/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RequestExit	proc	near
		uses	ax,bx,si,di
		.enter
	;
	; if this request is initial request, V block sem
	;
		mov	si, ds:[bp]
		test	ds:[si].NC_flags, mask NF_INIT_REQUEST
		jz	freeChunk
	;
	; if cx = UNBLOCK, V blockSem
	;
		cmp	cx, UNBLOCK
		jne	freeChunk
		mov	bx, ds:[si].RN_blockSem
		call	ThreadVSem
freeChunk:
	;
	; Stop query timer if any
	;
		tst	ds:[si].RN_queryTimer.low
		jz	skipStop
		movdw	axbx, ds:[si].RN_queryTimer
		call	TimerStop
skipStop:
	;
	; Destroy all the children first
	;
		call	RequestDestroyChildren
		mov	si, ds:[si].RN_slist
		tst	si
		jz	skip			; slist was never allocated
		call	SlistDestroy
skip:
		mov	ax, bp
		call	LMemFree
		.leave
		ret
RequestExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RequestDestroyChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy all the children of a request node

CALLED BY:	RequestExit
PASS:		ds:si = parent node
RETURN:		bp    = chunk handle to parent node
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RequestDestroyChildren	proc	near
		uses	ax,di
		.enter
		call	TreeGotoChild
		jc	done
destroyLoop:
	;
	; Destroy all children
	; ds:di     = parent node
	; ds:si/*bp = first child to destroy
	;
		call	RequestDestroyChildren
		mov	ax, bp
		call	TreeGotoNext
		pushf
	;
	; Destroy current child
	; ds:di/*ax = current child node to remove
	; ds:si/*bp = next sibling
	;
		push	si
		mov	si, ds:[di].RN_slist
		tst	si
		jz	skip
		call	SlistDestroy		; destroy slist
skip:
		call	LMemFree		; destroy RequestNode
		pop	si
		popf
		jnc	destroyLoop		; destroy the next sibling
	;
	; should have come back to parent
	;
done:
		.leave
		ret
RequestDestroyChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RequestAllocId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allocate an id to use for a request
CALLED BY:	ResolverGetHostInfo
PASS:		nothing
RETURN:		carry clr if success
			DX	= unique request Id
		carry set if failed
			we have too many simultaneous queries
DESTROYED:	NOTHING
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 6/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RequestAllocId	proc	far
		uses	ax,bx,si,ds
		.enter
		GetDgroup ds, bx
		cmp	ds:validId, 1111111111111111b	; all IDs are in use
		je	doneC
		mov	bx, handle ResolverRequestBlock
		call	MemLock
		mov	ds, ax
reassign:
		inc	ds:RBH_curId
		mov	dx, ds:RBH_curId
		tst	dx			; 0 is root
		jz	reassign
		call	IdValidate		; carry set if id is already
		jc	reassign		; in use, so to speak
		call	MemUnlock
done:
		.leave
		ret
doneC:
		stc
		jmp	done
RequestAllocId	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RequestChangeSname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CHANGE THE NAME WE ARE SEARCHING FOR
CALLED BY:	RESOLVEREVENTRESPONSE
PASS:		ES:DX	= CNAME
		ES:DI	= PACKET
		DS:SI/*BP = REQUESTNODE
RETURN:		DS:SI ADJUSTED TO POINT TO THE RIGHT OFFSET FOR THE NODE
DESTROYED:	NOTHING
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 6/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RequestChangeSname	proc	near
		uses	ax,bx,cx,dx,di
		.enter
	;
	; Skip Question part
	;
		mov	di, dx
	;
	; es:di	= CNAME in packet
	; Realloc RequestNode
	;
		mov	di, dx
if DBCS_PCGEOS  ; always SBCS string
		push	di
		clr	al
		mov	cx, -1
		repne	scasb
		not	cx
		pop	di
		mov	ax, bp
		add	cx, size RequestNode     ; INCLUDES NULL
else
		call	LocalStringLength
		mov	ax, bp
		add	cx, size RequestNode + 1 ; INCLUDE NULL
endif
		call	LMemReAlloc		; REQUESTNODE DATA UNCHANGED
		jc	done
		mov	si, ds:[bp]		; RE-DEREFERENCE SI
		segxchg	ds, es
		xchg	si, di			; DS:SI = NAME TO COPY
		sub	cx, size RequestNode
		mov	es:[di].RN_nameLen, cx
		push	di
		add	di, offset RN_name	; ES:DI = NAME FIELD
EC <		CheckMovsbIntoChunk bp		; *es:bp = chunk handle	>
		rep movsb
		pop	si
		segxchg	ds, es
done:
		.leave
		ret
RequestChangeSname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RequestRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	RESTART A REQUEST; THIS HAPPENS WHEN A NEW SNAME WAS ASSIGNED
		OR A FOREIGN NAME SERVER RETURNED DELEGATION TO BETTER NAME
		SERVERS.
CALLED BY:	RESOLVEREVENTRESPONSE
PASS:		ds:si/*bp = RequestNode
		bx	  = RequestRestartReason
RETURN:		NOTHING
DESTROYED:	NOTHING
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 9/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RequestRestart	proc	near
		uses	ax,bx,cx,si,es,di
		.enter
	;
	; RECONSTRUCT SLIST
	;
		segmov	es, ds, ax
		mov	di, si
		add	di, offset RN_name
		call	SlistInitialize	; AX = NEW SLIST; CX = MATCH COUNT
		jc	done
	;
	; Dereference RequestNode
	;
		push	bx
		mov	bx, handle ResolverRequestBlock
		call	MemDerefDS
EC <		mov	si, NULL_SEGMENT				>
EC <		mov	es, si						>
		mov	si, ds:[bp]
		pop	bx
	;
	; Check match count
	;
		cmp	bx, RRR_SNAME_CHANGED
		je 	skipMatchCountCheck
		cmp	bx, RRR_DHCP_EXPIRED
		je	skipMatchCountCheck
	;
	; Match count must be lower
	; - actually this is remaining number of labels to match, so the lower
	;   the match count, the more labels have been matched already.
	;
		cmp	cx, ds:[si].RN_matchCount
		jge	destroyNewSlist
		
skipMatchCountCheck:
		mov	ds:[si].RN_matchCount, cx
		xchg	ax, ds:[si].RN_slist
		xchg	ax, si		; *DS:SI = OLD SLIST TO GET RID OF
		call	SlistDestroy	; destroy old list
		mov_tr	si, ax		; DS:SI = REQUESTNODE
	;
	; POST QUERY NAME SERVER EVENT FOR CURRENT REQUEST
	;
		cmp	bx, RRR_DHCP_EXPIRED
		je	done
		mov	dx, ds:[si].RN_id
		mov	ax, RE_QUERY_NAME_SERVERS
		ResolverPostEvent_NullESDS
done:
		.leave
		ret
destroyNewSlist:
		mov_tr	si, ax
		call	SlistDestroy	
		jmp	done
RequestRestart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConstructAnswer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	FILL IN THE ANSWER CHUNK ARRAY IN REQUESTNODE WITH THE
		RESOURCE RECORDS FOUND IN THE CACHE
CALLED BY:	RESOLVEREVENTQUERYINFO
PASS:		ES:DI	= REQUESTNODE
		DS:SI	= FIRST RESOURCERECORD FOUND
		DX	= RESOURCERECORDTYPE
RETURN:		carry set if error
		else
		   RESOURCERECORD IN DS:SI UNLOCKED
		   NOTHING( CHUNK ARRAY IN RN_ANSWER IS READY TO BE RETURNED )
DESTROYED:	NOTHING
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 9/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConstructAnswer	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
		.enter
		movdw	cxbp, dssi		; BXBP = FIRST RR
		mov	bx, es:[di].RN_answer.high
		call	MemLockExcl
		mov	ds, ax
		mov	si, es:[di].RN_answer.low
addLoop:
	;
	; BX	 = MEM HANDLE OF ANSWER CHUNK ARRAY
	; DS:*SI = ANSWER CHUNK ARRAY
	; CX:BP  = RESOURCERECORD
	; DX	 = RESOURCERECORDTYPE FOR ANSWER
	;
		call	GetResourceRecordSize	; AX = SIZE OF RR
		sub	ax, size ResourceRecordCommon - \
			    size ResolverAnswerSection
		call	ChunkArrayAppend	; DS:DI = NEW ELT
		jc	errorDone
		push	bx			; SAVE CHUNK ARRAY MEM HANDLE
		segmov	es, ds, ax		; ES:DI = RESOLVERANSWERSECTION
		mov	ds, cx
		xchg	si, bp			; DS:SI = RESOURCERECORD
		segmov	es:[di].RAS_type, ds:[si].RR_common.RRC_type, ax
		mov	cx, ds:[si].RR_common.RRC_dataLen
	;
	; COPY DATA SECTION
	;
		push	si
		add	si, offset RR_data
		add	di, offset RAS_data
EC <		CheckMovsbIntoChunk bp		; *es:bp = chunk handle	>
		rep movsb
		pop	si			; DS:SI = RESOURCERECORD
		movdw	axsi, ds:[si].RR_next
		mov	bx, ds:LMBH_handle	; UNLOCK LAST RESOURCERECORD
		call	HugeLMemUnlock		;
		mov	bx, ax			; ^LBX:SI = NEXT RR
		call	RecordFindNext		; DS:SI = RESOURCERECORD
		pop	bx			; BX	= MEM HANDLE OF ANSWER
		jc	noMore
		mov	cx, ds
		xchg	bp, si			; CX:BP = NEXT RESOURCERECORD
		segmov	ds, es, ax		; *DS:SI= ANSWER CHUNK ARRAY
		jmp	addLoop
noMore:
	;
	; *es:bp = answer chunk array
	; bx = answer block
	;
		segmov	ds, es, ax
		mov	si, ds:[bp]		; ds:si = answer chunk array
		mov	ds:[si].RAH_error, REC_NO_ERROR
unlockBlock:
		call	MemUnlockShared
	;	call	MemUnlock
		.leave
		ret
errorDone:
	;
	; DS:*SI = ANSWER CHUNK ARRAY	; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
	; ( RETURN ERROR )
	;
		mov	si, ds:[si]
		mov	ds:[si].RAH_error, REC_INTERNAL_ERROR
		mov	bx, ds:LMBH_handle
		jmp	unlockBlock
ConstructAnswer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetResourceRecordSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	RETURN THE SIZE OF A RESOURCERECORD
CALLED BY:	CONSTRUCTANSWER
PASS:		CX:BP	= FPTR TO RESOURCERECORDCOMMON + DATA
RETURN:		AX	= SIZE OF THE RR
DESTROYED:	NOTHING
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/10/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetResourceRecordSize	proc	near
		uses	ds, si
		.enter
		movdw	dssi, cxbp
		mov	ax, ds:[si].RR_common.RRC_dataLen
		add	ax, size ResourceRecord
		.leave
		ret
GetResourceRecordSize	endp

; ============================================================================
;
;				RESPONSE
;
; ============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseCheckError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CHECK FOR ERRORS IN RESPONSE PACKET
CALLED BY:	RESOLVEREVENTREPONSE
PASS:		^LBX:CX   = PACKET
		ES:DI	  = PACKET
		DS:SI/*BP = REQUESTNODE
RETURN:		CARRY CLEAR IF NO ERROR
			ax = destroyed
		CARRY SET IF ERROR
			AX = RESPONSEERRORCODE
			     0 MEANS CORRUPTED PACKET 
DESTROYED:	ax
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 9/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseCheckError	proc	near
		uses	cx,dx,si,di
		.enter
	;
	; CHECK HEADER
	;
		mov	ax, es:[di].RM_flags
		test	ax, mask RMF_QR
		jz	strange
		mov	cx, ax
		and	cx, mask RMF_OPCODE
		tst	cx
		jnz	strange
	;
	;	test	ax, mask RMF_RD		; sometimes we want to handle
	;	jz	strange			; delegation ourselves
	;
		test	ax, mask RMF_Z
		jnz	strange
	;
	; CHECK QUESTION SECTION
	;
		add	di, offset RM_data
		push	si			; save RequestNode offset
		add	si, offset RN_name	; name in request node
		call	DomainNameCompare	; CX = LENGTH OF STRINGS
		pop	si
TESTP <		WARNING_NE RESPONSE_NAME_MISMATCH			>
		jne	strange
		add	di, cx
	;
	; check defined error
	;
		and	ax, mask RMF_RCODE
		mov	cl, offset RMF_RCODE
		shr	ax, cl
		tst	ax
		jnz	error
	;
	; CHECK QTYPE AND QCLASS
	; ES:DI = QTYPE
	;
		mov	ax, es:[di]
		cmp	ax, ds:[si].RN_stype
		jne	strange
checkClass::
		add	di, size word
		mov	ax, ds:[si].RN_sclass
		cmp	ax, es:[di]
		jne	strange
done:
		.leave
		ret
strange:
		clr	ax
		stc
		jmp	done
error:
	;
	; Return all kinds of errors
	;
	;	cmp	ax, REC_NAME_ERROR
	;	jne	strange
	;	test	es:[di].RM_flags, mask RMF_AA
	;	jz	strange
	;
		stc
		jmp	done	; return error code in ax
ResponseCheckError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseHandleError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dispose of a request if necessary( according to error code )

CALLED BY:	ResolverEventResponse
PASS:		ax	= ResolverError
		dx	= request ID
		ds:si	= RequestNode
RETURN:		nothing
DESTROYED:	ax
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseHandleError	proc	near
		uses	bx,bp,es,di
		.enter
		cmp	ax, RE_NO_ERROR
		je	done
	;
	; Record error code in answer chunk array if I am the initial request;
	; otherwise I just free myself and tell the parent request node.
	;
		test	ds:[si].NC_flags, mask NF_INIT_REQUEST
		jz	endRequest
		mov	bx, ds:[si].RN_answer.high
		push	ax			; push error code
		call	MemLockShared
		mov	es, ax
		mov	bp, ds:[si].RN_answer.low
		mov	bp, es:[bp]
		pop	es:[bp].RAH_error
		call	MemUnlockShared
endRequest:
	;
	; Terminate the request
	;
		mov	ax, RE_END_REQUEST
		ResolverPostEvent_NullESDS
done:
		.leave
		ret
ResponseHandleError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseCheckCname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the response packet contains CNAME
CALLED BY:	ResolverEventReponse
PASS:		es:di	= packet
RETURN:		es:dx	= CNAME found
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseCheckCname	proc	near
		uses	ax,bx,cx,di
		.enter
	;
	; Get number of answer entries
	;
		mov	cx, es:[di].RM_anCount
		jcxz	noCname
	;
	; Skip header and question part
	;
		mov_tr	bx, cx
		mov	cx, MAX_HOST_NAME_SIZE
		add	di, offset RM_data
		clr	al
		repne	scasb		; skip domain name
		mov_tr	cx, bx
		add	di, size word + size word; skip QTYPE and QCLASS
findLoop:
	;
	; Skip name
	;
		mov	dx, di
		mov_tr	bx, cx
		mov	cx, MAX_HOST_NAME_SIZE
		repne	scasb
		mov_tr	cx, bx
		cmp	es:[di].RRC_type, RRT_CNAME
		je	found
		add	di, es:[di].RRC_dataLen
		add	di, size ResourceRecordCommon
		loop	findLoop
		jmp	noCname
found:
		mov	dx, di
		add	dx, size ResourceRecordCommon
		clc
done:
		.leave
		ret
noCname:
		stc
		jmp	done
ResponseCheckCname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseCheckAnswer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the packet contains an answer
CALLED BY:	ResolverEventResponse
PASS:		es:di	= packet
RETURN:		carry clear if there is an answer
		carry set if no answer
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseCheckAnswer	proc	near
		.enter
		tst	es:[di].RM_anCount
		jz	noAnswer
		clc
done:
		.leave
		ret
noAnswer:
		stc
		jmp	done
ResponseCheckAnswer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseCheckDelegation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if there is delegation
CALLED BY:	ResolverEventResponse
PASS:		es:di	= packet
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseCheckDelegation	proc	near
		.enter
		tst	es:[di].RM_anCount
		jnz	noDelegation
		tst	es:[di].RM_nsCount
		jz	noDelegation
		clc
done:
		.leave
		ret
noDelegation:
		stc
		jmp	done
ResponseCheckDelegation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseCacheData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cache all the resource record contained in packet
CALLED BY:	ResolverEventResponse
PASS:		es:di = packet
RETURN:		nothing
DESTROYED:	nothing
WARNING:
	ResolverCacheBlock may move and every fptr into ResolverCacheBlcok
	must be considered 'destroyed.'

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseCacheData	proc	near
		uses	bx,dx,ds,si,bp
		.enter
		mov	dx, segment CacheResourceRecordCallback
		mov	si, offset CacheResourceRecordCallback
		clr	bp			; no valid owner name yet
		call	ResponsePacketEnum	; carry set if mem error
	;					; ds
	; PacketEnum with CacheResourceRecordCallback may move
	; ResolverCacheBlock.  But no one should have this block locked
	; at this point anyway.
	;
		.leave
		ret
ResponseCacheData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResponseReturnAnswer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the answer to a query in case the query is the initial
		request; in case the query is a child request, update request
		tree and resend queries
CALLED BY:	ResolverEventResponse
PASS:		ds:si/*bp = RequestNode
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponseReturnAnswer	proc	near
		uses	cx,dx,si,bp,es,di
		.enter
	;
	; Check whether this is the init request or child request
	;
		test	ds:[si].NC_flags, mask NF_INIT_REQUEST
		jz	childRequest
	;
	; Construct answer( answer should have been cached by now )
	;
		push	ds, si
		segmov	es, ds, dx
		mov	di, si
		add	di, offset RN_name
		mov	dx, ds:[si].RN_stype
		call	RecordFind		; ds:si = ResourceRecord
		pop	es, di			; es:di = RequestNode
		jc	done			; this is a bizare case
		call	ConstructAnswer		; ds:si unlocked
		segmov	ds, es			;
		mov	si, di			; ds:si = RequestNode
exitRequest:
	;
	; Exit request
	; ds:si = request node
	;
		mov	dx, ds:[si].RN_id
		mov	ax, RE_END_REQUEST
		mov	cx, UNBLOCK
		ResolverPostEvent_NullESDS
done:
		.leave
		ret
childRequest:
	;
	; Resend queries for parent node
	;
		call	TreeGotoParent		; ds:si = parent
		mov	dx, ds:[si].RN_id
		mov	ax, RE_QUERY_NAME_SERVERS
		ResolverPostEvent_NullESDS
		mov	si, ds:[bp]		; ds:si = node to remove
		jmp	exitRequest
ResponseReturnAnswer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RESPONSEPACKETENUM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LOOP THROUGH ALL THE RESOURCE RECORDS IN A RESPONSE PACKET
		CALLING THE CALL BACK ROUTINE
CALLED BY:	UTILITY
PASS:		ES:DI	= PACKET
		DX:SI	= CALLBACK ROUTINE
RETURN:		AX,BX,CX,BP,DS RETURNED FROM CALLBACK
DESTROYED:	NOTHING
CALLBACK ROUTINE:

	PASS:	ES:DI	= CURRENT RESOURCE RECORD IN THE PACKET
		AX,BX,BP,DS PASSED IN FROM CALLER
	RETURN: CARRY SET TO ABORT
		CARRY CLEAR AND AX,BX,BP,DS
	DESTROYED: CAN DESTROY DI, SI, DX
	

REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 9/95    	INITIAL VERSION

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResponsePacketEnum	proc	near
		uses	cx,dx,si,di
		.enter
	;
	; we don't need to do this checking
	;
	;	cmp	es:[di].RM_qdCount, 1	; we only use 1 question in
	;	jne	done			; each packet
	;	
		mov	cx, es:[di].RM_anCount
		add	cx, es:[di].RM_nsCount
		add	cx, es:[di].RM_arCount
		jcxz	done
	;
	; skip and question part
	;
		tst	es:[di].RM_qdCount
		pushf
		add	di, offset RM_data	
	;
	; if question part is missing, jump over skipping question part
	;
		popf
		jz	callbackLoop
		push	cx, ax
		clr	al
		mov	cx, MAX_HOST_NAME_SIZE
		repne scasb
		pop	cx, ax
		add	di, size word + size word ; skip QTYPE and QCLASS
callbackLoop:
		push	di, si, dx, cx
		pushdw	dxsi
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		pop	di, si, dx, cx
		jc	done
	;
	; Go to next resource record
	; 1. skip resource record
	;
		push	cx, ax
		mov	cx, MAX_HOST_NAME_SIZE
		clr	al
		repne scasb
		pop	cx, ax
		dec	cx
		jz	done
		add	di, es:[di].RRC_dataLen
		add	di, size ResourceRecordCommon
		jmp	callbackLoop	
done:
		.leave
		ret
ResponsePacketEnum	endp

; ============================================================================
;
;				 SLIST
;
; ============================================================================

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlistInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize slist
CALLED BY:	utility
PASS:		es:di	= target domain name fptr
		ds:si	= current request node
RETURN:		ax	= chunk handle of slist
		cx	= # of unmatched labels( as in TreeSearchDomainName )
		carry set if mem error or trouble getting name server addr

DESTROYED:	es,ds,si,di

REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	SJ	1/ 5/95    	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlistInitialize	proc	near
		slist		local	nptr
		lastNode	local	dword
		accessId	local	word
		uses	bx,dx,bp
		.enter
	;
	; Initialize
	;
		mov	dx, ds:[si].RN_accessId		; dx = access id
		mov	bx, size SlistElement
		clr	si, cx
		call	ChunkArrayCreate		; *ds:si = slist
		LONG	jc	done
	;
	; *ds:si = chunk array for slist
	; es:di  = domain name to query
	; dx	 = access id
	;
		mov	slist, si			; slist = chunk array
		mov	accessId, dx
	;
	; examine cache for name servers( cache block is locked here )
	;
		call	TreeSearchDomainName		; ds:si = best match
restart:						; cx= # labels to match
		movdw	lastNode, dssi
		mov	dx, RRT_NS
		movdw	bxsi, ds:[si].RRN_resource
		call	RecordFindNext			; ds:si= ResourceRecord
		LONG	jnc	found
		movdw	dssi, lastNode
	;
	; examine shorter path
	;
		inc	cx				; increment # of labels
							;   to match
		call	TreeGotoParent			; ds:si= parent
		jnc	restart
		dec	cx				; go to parent failed
unlockCacheUseSbelt:
	;
	; unlock cache block
	;
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
	;
	; read information from sbelt
	;
		mov	bx, handle ResolverRequestBlock
		call	MemDerefDS
		mov	si, slist			; *ds:si = slist
		mov	dx, accessId
		call	SlistUseAccessPoint
		LONG	jc	done			; must be memory
	; see if we have any stored DNS servers from DHCP
		mov	bx, handle dgroup
		call	MemDerefES
		tstdw	es:[dhcpDns1]
		LONG	jz	noServersFromDhcp

	; First check if the server is already in the list
		call	ChunkArrayGetCount
		clr	ax
		call	ChunkArrayElementToPtr
checkNext1:
		cmpdw	ds:[di].SE_address, es:[dhcpDns1], ax
		je	checkServer2
		add	di, size SlistElement
		loopne	checkNext1
		
	; *ds:si = ChunkArray, ax = element size
	; return: ds:di = block
		call	ChunkArrayAppend
		jc	noServersFromDhcp
	; If these errors occur, ChunkArrayAppend didn't zero init the
	; memory like it's supposed to. Allen says it zero inits, Dave says
	; it doesn't, hence why this EC code is here.     -Ed
EC <		tst	ds:[di].SE_flags				>
EC <		ERROR_NZ RFE_GENERAL_FAILURE				>
EC <		tst	ds:[di].SE_nameLen				>
EC <		ERROR_NZ RFE_GENERAL_FAILURE				>
EC <		tst	ds:[di].SE_serverName				>
EC <		ERROR_NZ RFE_GENERAL_FAILURE				>
	;		clr	ax
	;		mov	ds:[di].SE_flags, ax
	;		mov	ds:[di].SE_nameLen, ax
	;		mov	ds:[di].SE_serverName, ax
		movdw	ds:[di].SE_address, es:[dhcpDns1], ax

checkServer2:
		tstdw	es:[dhcpDns2]
		jz	noServersFromDhcp

	; First check if the server is already in the list
		call	ChunkArrayGetCount
		clr	ax
		call	ChunkArrayElementToPtr
checkNext2:
		cmpdw	ds:[di].SE_address, es:[dhcpDns1], ax
		je	noServersFromDhcp
		add	di, size SlistElement
		loopne	checkNext2

		call	ChunkArrayAppend
		jc	noServersFromDhcp
EC <		tst	ds:[di].SE_flags				>
EC <		ERROR_NZ RFE_GENERAL_FAILURE				>
EC <		tst	ds:[di].SE_nameLen				>
EC <		ERROR_NZ RFE_GENERAL_FAILURE				>
EC <		tst	ds:[di].SE_serverName				>
EC <		ERROR_NZ RFE_GENERAL_FAILURE				>
	;		mov	ds:[di].SE_flags, ax
	;		mov	ds:[di].SE_nameLen, ax
	;		mov	ds:[di].SE_serverName, ax
		movdw	ds:[di].SE_address, es:[dhcpDns2], ax
noServersFromDhcp:
	;
	; check if sbelt contains any DNS address
	; *ds:si = sbelt chunk array
	;
		push	cx
		call	ChunkArrayGetCount	; cx = # of elt in array
		jcxz	doneFree		; was jcxz useDhcp
		pop	cx
if 0
doneClr:
endif
		mov	ax, slist
		clc
done:
		.leave
		ret
unlockError:
	;
	; unlock cacheBlock
	;
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
		stc
		jmp	done
found:	;
	; some NS information found in cache
	; ds:si = ResourceRecord
	;
		segmov	es, ds, di
		mov	di, si				; es:di= ResourceRecord
		mov	bx, handle ResolverRequestBlock
		call	MemDerefDS
		mov	si, slist			; *ds:si= slist ch arry
		call	SlistAppendElt
		pushf
		movdw	axsi, es:[di].RR_next
		mov	bx, es:LMBH_handle
		call	HugeLMemUnlock
		mov_tr	bx, ax				; ^lbx:si = RR_next
		popf
		jc	unlockError
	;
	; Is there any more NS resource information?
	;
		mov	dx, RRT_NS
		call	RecordFindNext
		LONG	jc	unlockCacheUseSbelt
		jmp	found				; ds:si = next NS RR
		
if 0
useDhcp:
	;
	; *ds:si = slist chunk array
	;
		pop	cx
	;
	; Use DHCP to figure out a valid name server
	;
		mov	dx, accessId
		call	RunDHCP
		jc	doneFree
	;
	; Try again
	;
		call	SlistUseAccessPoint
		jc	done
		
		call	ChunkArrayGetCount	; cx = # of elt in array
		jcxz	doneFree
		mov	cx, -1
		jmp	doneClr
endif
doneFree:
	;
	; Free the chunk array handle for slist
	;
		add	sp, 2			; get the old cx off the stack
		mov	ax, slist
		call	LMemFree
		stc
		jmp	done
		
SlistInitialize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlistAppendElt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a name server to slist
CALLED BY:	SlistInitialize
PASS:		es:di	= ResourceRecord to use ( must be RRT_NS type )
		*ds:si	= slist
RETURN:		carry set if error
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlistAppendElt	proc	near
		uses	ax,cx,si,di,es,dx
		.enter
		mov	bx, di			; es:bx = ResourceRecord
		clr	al
		mov	cx, es:[bx].RR_common.RRC_dataLen
		call	LMemAlloc		; ax = handle
		jc	done
		call	ChunkArrayAppend	; ds:di = new SlistElement
		jc	doneFree
		mov	ds:[di].SE_flags, 0
		mov	ds:[di].SE_address.high, 0
		mov	ds:[di].SE_address.low, 0
		mov	ds:[di].SE_nameLen, cx
		mov	ds:[di].SE_serverName, ax
		segxchg	ds, es
		mov	si, bx			; ds:si = ResourceRecord
		add	si, offset RR_data	; ds:si = name to add
		mov	di, ax
		mov	di, es:[di]		; es:di = buffer for name
EC <		CheckMovsbIntoChunk ax		; *es:dx = chunk 	>
		rep movsb
		segxchg	es, ds
done:
		.leave
		ret
doneFree:
		call	LMemFree
		stc
		jmp	done
SlistAppendElt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlistUseAccessPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instantiate slist using access point library services.

CALLED BY:	SlistInitialize
PASS:		dx	= accessId
		ds	= ResolverRequestBlock segment( locked )
		*ds:si	= slist chunk array
RETURN:		new addresses added to *ds:si slist		
		carry set if mem error
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dnsEntry	word	\
	(APSP_AUTOMATIC or APSP_DNS1),
	(APSP_AUTOMATIC or APSP_DNS2),
	APSP_DNS1,
	APSP_DNS2

SlistUseAccessPoint	proc	near
		uses	ax,bx,cx,dx,si,di,es,bp
		.enter
	;
	; *ds:si = chunk array for slist
	; initialize loop variables
	;
		mov_tr	ax, dx
		mov	bx, offset dnsEntry
		mov	bp, MAX_ADDR_STRING_PROPERTY_SIZE
		segmov	es, ss, di
		sub	sp, MAX_ADDR_STRING_PROPERTY_SIZE + size dword
		mov	di, sp
repeatRead:
	;
	; ax    = access id
	; bx    = index to dnsEntry table
	; bp	= MAX_ADDR_STRING_PROPERTY_SIZE
	; es:di = buffer allocated on stack
	; *ds:si = chunk array allocated for sbelt
	;
	; ax = access point ID
	; bx = index to dnsEntry table
	;
	; if bx reached the end of dnsEntry table, jump to exit
	;
		cmp	bx, offset dnsEntry + size dnsEntry
		jae	exit
	;
	; read a DNS address from access point DB
	;
		clr	cx
		mov	dx, {word}cs:[bx]
		push	bx
		call	AccessPointGetStringProperty	; cx = string length
		pop	bx
		pushf
	;
	; advance index to dnsEntry table
	;
		add	bx, size word
		popf
		jc	repeatRead
	;
	; parse address string and store the address in sbelt - *ds:si
	; ax = access point id
	; bx = index to dnsEntry table
	; bp = MAX_ADDR_STRING_PROPERTY_SIZE
	; es:di = address string
	; ds:*si = sbelt chunk array
	;
		call	SlistAppendDnsEntry
		jc	exit
		jmp	repeatRead
exit:
	;
	; return the stack space we used
	;
		add	sp, MAX_ADDR_STRING_PROPERTY_SIZE + size dword
error::
		.leave
		ret
SlistUseAccessPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlistAppendDnsEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append address of a name server to SBELT

CALLED BY:	SlistUseAccessPoint
PASS:		es	= stack segment
		es:di	= address string ( ex "123.132.344.5",0 )
		es:di+MAX_ADDR_STRING_PROPERTY_SIZE = buffer for dword
		*ds:si	= sbelt chunk array
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jang	9/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlistAppendDnsEntry	proc	near
		uses	ax, cx, di, bp
		.enter
	;
	; parse address
	;
		push	ds, si
		segmov	ds, es, si
		mov	si, di				 ; ds:si = addr string
		add	di, MAX_ADDR_STRING_PROPERTY_SIZE; es:di = dword buffer
		mov	cx, size dword			 ; IP addr = dword
parseLoop:
		call	ParseAndStoreIPAddress
		jc	errorPop
		loop	parseLoop
		pop	ds, si
		sub	di, size dword			 ; move the ptr back to
							 ; the start of IP addr
		mov	bp, di				 ; es:bp = IP addr
	;
	; es:di  = IP addr
	; *ds:si = chunk array for SBELT
	;
		call	ChunkArrayAppend
		jc	done
		clr	ax
		mov	ds:[di].SE_flags, ax
		mov	ds:[di].SE_nameLen, ax
		mov	ds:[di].SE_serverName, ax
		segmov	ds:[di].SE_address.high, es:[bp].high, ax
		segmov	ds:[di].SE_address.low, es:[bp].low, ax
done:
		.leave
		ret
errorPop:
		pop	ds, si
		jmp	done
SlistAppendDnsEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParseAndStoreIPAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parses a part of IP address string and stores the result
		into the location passed in.
CALLED BY:	SbeltSetupCallback
PASS:		ds:si	= IP address string
		es:di	= location of parsed byte to store
RETURN:		si,di	= adjusted to the next byte
		carry set if IP address is corrupted
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParseAndStoreIPAddress	proc	far
		uses	ax,bx,cx,dx
		.enter
		clr	bx
		cmp	{TCHAR}ds:[si], '.' ; if first char is '.' -> error
		je	doneC
parseLoop:
		LocalGetChar	ax, dssi	; al = char read; si adjusted
		LocalCmpChar	ax, '0'
		jb	checkDot
		LocalCmpChar	ax, '9'
		ja	checkDot
	;
	; This is a numeric digit
	;
SBCS <		clr	ah						>
		sub	al, '0'		; al = 0 - 9
		xchg	ax, bx		; ax = curr result; bx = curr digit
		mov	cx, 10
		mul	cx
		add	ax, bx
		mov_tr	bx, ax
		jmp	parseLoop
finish:
		mov	al, bl
		stosb			; di adjusted
		clc
done:
		.leave
		ret
checkDot:
		LocalCmpChar	ax, '.'		; if char is '.' -> finish
		je	finish
		LocalCmpChar	ax, 0		; if char is 0, -> finish
		je	finish
		LocalCmpChar	ax, ' '		; if char is " ", -> finish
EC <		WARNING_E RW_BAD_IP_ADDRESS				>
		je	finish
doneC:
		stc
		jmp	done
ParseAndStoreIPAddress	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlistDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy slist
CALLED BY:	Utility
PASS:		ds:*si = slist
RETURN:		nothing
DESTROYED:	si
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlistDestroy	proc	near
		uses	ax,bx,di
		.enter
	;
	; Free all the name chunks
	;
		mov	bx, segment FreeNameChunkCallback
		mov	di, offset FreeNameChunkCallback
		call	ChunkArrayEnum			; ax destroyed
	;
	; Free chunk array
	;
		mov	ax, si
		call	LMemFree
		.leave
		ret
SlistDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LMemCopyChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a chunk in LMem
CALLED BY:	Utility
PASS:		ds:*si	= chunk to copy
RETURN:		carry set if mem error,	ax destroyed
		otherwise
			ds:*ax	= duplicate of ds:*si
			es:*ax	= the same as ds:*ax
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LMemCopyChunk	proc	far
NEC <		uses	cx, si, di					>
EC <		uses	cx, si, di, bx					>
		.enter
		ChunkSizeHandle	ds, si, cx
		call	LMemAlloc	; ax = new chunk
		jc	done
EC <		mov	bx, ax						>
		mov	si, ds:[si]
		segmov	es, ds, di
		mov	di, ax
		mov	di, es:[di]
EC <		CheckMovsbIntoChunk bx	; ds:*bx = new chunk		>
		rep movsb
		clc
done:
		.leave
		ret
LMemCopyChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RunDHCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run DHCP to figure out a name server for the current host

CALLED BY:	SlistInitialize
PASS:		dx = access point id
RETURN:		carry set on error
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jang	9/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0
RunDHCP		proc	far
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter
	;
	; Try auto configuration
	; 1. query socket name on our local side
	; 2. use DHCP to configure name server address for the access point
	; 3. try to use access point after that
	;
		push	dx			; save accessId(dx)
	;
	; Get medium and unit for tcpip domain
	;
		GetDgroup ds, di
		mov	di, offset socketAddress
		call	SocketGetAddressMedium	; cxdx = MediumType
		jc	failPop			; bl = MediumUnitType
						; bp = MediumUnit
	;
	; allocate MediumAndUnit on stack
	;
		sub	sp, size MediumAndUnitAligned
		mov	bp, sp
		movdw	ss:[bp].MU_medium, cxdx
		mov	ss:[bp].MU_unitType, bl
		mov	ss:[bp].MU_unit, bp
		mov	dx, ss
		mov	ax, bp			; dx:ax = MediumAndUnit
		mov	si, offset socketDomain	; ds:si = domain name
		GetDgroup es, di
		mov	di, offset ipAddress	; es:di = buffer for address
		mov	cx, IP_ADDR_SIZE
		call	SocketGetMediumAddress
		lahf
		add	sp, size MediumAndUnitAligned
		sahf
		movdw	dxax, es:[di]		; dxax = IP address
		pop	bx			; bx = access point id
		jc	done
contDhcp::
	;
	; local IP address = dxax
	; access point ID = bx
	;
		call	DHCPConfigure		; carry set on error
done:
		.leave
		ret
failPop:
		pop	bx
		stc
		jmp	done
RunDHCP		endp
endif

; ============================================================================
;
;			      RESOURCE RECORD
;
; ============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordConvertTTL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert TTL value into day unit

CALLED BY:	RecordAppend
PASS:		es:[di].RRC_ttl = TTL value in seconds
RETURN:		es:[di].RRC_ttl = TTL value in days
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordConvertTTL	proc	far
		uses	ax,bx,dx
		.enter
	;
	; If TTL is larger than 7 days, we just make it 7 days
	; (MAX_CACHE_ENTRY_LIFE)
	;
		movdw	bxax, es:[di].RRC_ttl
		cmpdw	bxax, MAX_CACHE_ENTRY_LIFE_IN_SEC
		ja	maxLife
	;
	; Devide by days in sec( we do this by looping )
	;
		mov	dx, 1			; at least it lives 1 day
divLoop:
		cmpdw	bxax, SECONDS_IN_A_DAY
		jbe	exitLoop
		subdw	bxax, SECONDS_IN_A_DAY
		inc	dx
		jmp	divLoop
exitLoop:
		clr	bx
		mov	ax, dx
		jmp	store
maxLife:
		clr	bx
		mov	ax, MAX_CACHE_ENTRY_LIFE
store:
		movdw	es:[di].RRC_ttl, bxax
		.leave
		ret
RecordConvertTTL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordFindDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a duplicate record in a node
CALLED BY:	CacheResourceRecordCallback
PASS:		ds:si	= ResourceRecordNode
		es:di	= ResourceRecordCommon + data to add
RETURN:		if found, carry clear
			  ds:si = ResourceRecord entry found
		otherwise carry set
			  ds:si = unchanged
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordFindDuplicate	proc	far
		rrNodeFptr	local	fptr
		uses	bx,cx,dx,bp
		.enter
	;
	; Set things up for search
	;
		movdw	rrNodeFptr, dssi
		mov	dx, es:[di].RRC_type
		mov	bx, ds:[si].RRN_resource.high
		mov	si, ds:[si].RRN_resource.low
	;
	; search for duplicate
	;
searchNext:
		tst	bx
		jz	notFound
		call	RecordFindNext
		jc	notFound
	;
	; compare the data portion
	;
		mov	cx, ds:[si].RR_common.RRC_dataLen
		cmp	cx, es:[di].RRC_dataLen
		jne	searchNextSetup
		push	di, si
		add	di, size ResourceRecordCommon
		add	si, offset RR_data
		repe cmpsb
		pop	di, si
		je	done			; duplicate found : carry clear
searchNextSetup:
		mov	bx, ds:[si].RR_next.high
		mov	si, ds:[si].RR_next.low
		mov	cx, ds			;cx = seg of ResourceRecord
		call	MemSegmentToHandle	;^hcx = current ResourceRecord
		xchg	bx, cx			;^hbx = current ResourceRecord
		call	HugeLMemUnlock
		mov	bx, cx			;^hbx = new ResourceRecord 
		jmp	searchNext
notFound:
		movdw	dssi, rrNodeFptr
		stc
done:
		.leave
		ret
RecordFindDuplicate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append an RR to RR node
CALLED BY:	utility
PASS:		ds:si	= ResourceRecordNode to append to
		es:di	= ResourceRecordCommon followed by RDATA
RETURN:		carry set if memory error
		carry clear otherwise
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordAppend	proc	far
		newRR	local	dword
NEC <		uses	ax,bx,cx,si,di,es,ds				>
EC <		uses	ax,bx,cx,si,di,es,ds,dx				>
		.enter
	;
	; Verify we don't add a CNAME RR that points to itself, thus
	; causing infinite loops for badly misconfigured name servers
	;
		cmp	es:[di].RRC_type, RRT_CNAME
		jne	notCNAME
		push	di
		add	di, size ResourceRecordCommon
		call	RecursiveCompareRRNWithString
						; carry -> set
						; if new RR points to itself
		pop	di
		cmc
		LONG jnc done
notCNAME:
	;
	; Allocate an HugeLMem block to store the new RR
	;
		push	ds, si
		push	es, di
		GetDgroup ds, bx
		mov	ax, es:[di].RRC_dataLen
		add	ax, size ResourceRecord
		mov	bx, ds:hugeLMem
		mov	cx, NO_WAIT
		call	HugeLMemAllocLock ; ^lax:cx / ds:di = new chunk
LONG		jc	memError
	;
	; copy RR data
	;
		movdw	newRR, axcx
EC <		mov	dx, cx		  ; bx = new chunk handle	>
		segmov	es, ds, si	  ; es:di = new RR
		add	di, offset RR_common
		pop	ds, si		  ; ds:si = RR to store
		mov	cx, ds:[si].RRC_dataLen
		add	cx, size ResourceRecordCommon
EC <		CheckMovsbIntoChunk dx		; *es:dx= new RR chunk	>
		rep movsb
		mov	di, newRR.offset
		mov	di, es:[di]	  ; es:di = new RR
		pop	ds, si		  ; ds:si = RR node to add this rr to
	;
	; Verify optr
	;
EC <		push	ax, bx						>
EC <		movdw	axbx, ds:[si].RRN_resource			>
EC <		tst	ax						>
EC <		jz	skipAssert					>
EC <		Assert	optr, axbx					>
EC < skipAssert:							>
EC <		pop	ax, bx						>
		movdw	es:[di].RR_next, ds:[si].RRN_resource, ax
		movdw	ds:[si].RRN_resource, newRR, ax
	;
	; Adjust TTL
	;
		add	di, offset RR_common
		call	RecordConvertTTL
	;
	; Unlock new RR appended
	;
		mov	bx, es:LMBH_handle
		call	HugeLMemUnlock
	;
	; Adjust global variable for cache size
	;
		GetDgroup es, ax 
		mov	ax, es:cacheSize
		inc	ax
		mov	es:cacheSize, ax
		cmp	ax, es:cacheSizeAllowed
		ja	reduceCache
		clc
done:
		.leave
		ret
memError:
		pop	es, di
		pop	ds, si
		jmp	done
reduceCache:
	;
	; cache is over the limit, reduce cache size next time we get
	; the chance
	;
		mov	ax, RE_REDUCE_CACHE
		ResolverPostEvent_NullESDS
		jmp	done
RecordAppend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecursiveCompareRRNWithString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the data in the passed RRN with the hostname
		portion in passed string. Repeating this process until
		we reach the top level RRN.

CALLED BY:	RecordAppend
		RecursiveCompareRRNWithString		
PASS:		ds:si	= ResourceRecordNode
		es:di	= hostname string to compare against
			  prepended by length in bytes
RETURN:		carry set if complete node name matches string
		carry clear otherwise
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	
	1. compare node with string
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	reza   	3/19/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecursiveCompareRRNWithString	proc	near
	uses	si, dx, cx, ax, di
	.enter
	;
	; See if the 2 parts match
	;
		mov	al, es:[di]		; al = size of host component
		inc	di			; es:di = start of hostname
		mov	dx, si			; dx = saved offset of RRN
		add	si, offset RRN_name
		mov	cl, ds:[si]		; cl = size of node component
		inc	si			; ds:si = start of nodename
		cmp	cl, al			; components must be
		jne	noMatch			; equal size

		clr	ch			; cx = string length
		push	di, cx
		repe	cmpsb
		pop	di, cx
		jne	noMatch
		mov	si, dx			; ds:si = RRN
	;
	; Get our the node level
	;
		mov	ax, ds:[si].RRN_tree.NC_flags
		andnf	ax, mask NF_LEVEL	; ax = level
	;
	; See if we've come to the end of the hostname
	;
		add	di, cx			; es:di = rest of hostname
						; after 1st component
		cmp	{byte} es:[di], 0
		jz	checkTopLevel		; end of hostname?
	;
	; Get the parent node 
	;
		cmp	ax, 1			; if we're at the top
		je	noMatch			; level we can't match anymore 

		call	TreeGotoParent		; carry -> set if this
						; is root
						; ds:si = parent node
EC <		ERROR_C RFE_TREE_BUG					>
NEC <		jc	noMatch						>

		call	RecursiveCompareRRNWithString
		jmp	done
	;
	; Check if the node is the top level
	;
checkTopLevel:
		cmp	ax, 1
		jne	noMatch

		stc
		jmp	done
noMatch:
		clc
done:
	.leave
	ret
RecursiveCompareRRNWithString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordFind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a specific type of RR in our cache
CALLED BY:	Utility
PASS:		es:di	= domain name
		dx	= ResourceRecordType
RETURN:		carry set if not found
			ds:si	= destroyed
		carry clear if found,
			ds:si	= ResourceRecord structure (HugeLMemLock'ed)
DESTROYED:	ds, si
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordFindFar	proc	far
		call	RecordFind
		ret
RecordFindFar	endp

RecordFind	proc	near
		uses	ax,bx,cx
		.enter
		call	TreeSearchDomainName	; ds:si = best match
		jcxz	nodeFound
		mov	bx, ds:LMBH_handle
		call	MemUnlock
notFound::
		stc
done:
		.leave
		ret
nodeFound:
	;
	; ds:si = ResourceRecordNode
	;
		movdw	axsi, ds:[si].RRN_resource
		mov	bx, ds:LMBH_handle
		call	MemUnlock
		mov_tr	bx, ax
		call	RecordFindNext	; ds:si = ResourceRecord if success
		jmp	done		
RecordFind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordFindNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Find the next ResourceRecord structure
CALLED BY:	Utility
PASS:		^lbx:si	= next resource record to search( bx = 0 if no RR )
		dx	= ResourceRecordType
RETURN:		carry clear if found,
			ds:si = ResourceRecord found (HugeLMem Locked)
		carry set if not
			ds:si = destroyed
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordFindNext	proc	near
		uses	ax,bx,cx
		.enter
		tst	bx
		jz	notFound
restart:
		call	HugeLMemLock
		mov	ds, ax
		mov	si, ds:[si]
		cmp	dx, ds:[si].RR_common.RRC_type
		je	found
	;
	; If the record is a cname, redirect our search to canonical name
	;
		cmp	ds:[si].RR_common.RRC_type, RRT_CNAME
		je	redirect
		movdw	cxsi, ds:[si].RR_next
		call	HugeLMemUnlock
		jcxz	notFound
		mov_tr	bx, cx
		jmp	restart
found:
		clc
done:
		.leave
		ret
notFound:
		stc
		jmp	done
redirect:
	;
	; ds:si = ResourceRecord containing a CNAME
	; find the ResourceRecordNode indicated by CNAME data and start search
	; there.
	;
		push	es, di
		segmov	es, ds, di
		mov	di, si
		add	di, offset RR_data	; es:di = canonical domain name
		call	TreeSearchDomainName	; ds:si = best match
		mov	bx, es:LMBH_handle
		pop	es, di
	;
	; Now unlock CNAME RR block
	;
		call	HugeLMemUnlock
	;
	; If alias node was not found, record cannot be found
	;
		tst	cx
		stc
		jnz	notFoundUnlock
	;
	; ds:si = canonical ResourceRecordNode
	;
		movdw	bxsi, ds:[si].RRN_resource
		call	RecordFindNext
notFoundUnlock:
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
		jmp	done
RecordFindNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordCloseOrSaveAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a chain of resource records after saving them into a
		file if file handle is given

CALLED BY:	CacheRRCloseCB
PASS:		^lbx:dx = resource record optr ( bx = 0 if none )
		ax	= file handle
RETURN:		carry set on file error( out of diskspace )
DESTROYED:	ax, bx, cx, dx

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordCloseOrSaveAll	proc	near
		uses	ds, di, bp, es
		.enter
		mov_tr	bp, ax
		GetDgroup es, ax
	;
	; if bx = 0, nothing to deallocate
	;
		tst	bx			; CF = 0
		jz	done
repeat:
	;
	; ^lbx:dx = chain to deallocate
	; bp      = file handle
	;
		call	HugeLMemLock
		mov	ds, ax
		mov	di, dx
		mov	di, ds:[di]
		movdw	axcx, ds:[di].RR_next
	;
	; Save ResourceRecord if file is open
	; ds:di = ResourceRecord
	; ax:cx = optr to next record
	; bp    = file handle ( 0 if nothing to save )
	;
		tst	bp		; carry clear
		jz	skipSave
save::
	;
	; Save current node
	;
		call	RecordSaveToFile; carry set if file write error
skipSave:
		call	HugeLMemUnlock
		jc	done		; exit with file error( disk full )
		xchgdw	axcx, bxdx	; exchange cur and next
	;
	; Free HugeLMem chunk if file handle = 0
	; not ax:cx = record to be deleted
	;
		tst	bp
		jnz	skipDelete
		call	HugeLMemFree		
		dec	es:cacheSize
skipDelete:
	;
	; Continue if bx is non zero
	;
		tst	bx		; CF = 0
		jnz	repeat
done:
		.leave
		ret
RecordCloseOrSaveAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordSaveToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save a resource record entry to a file

CALLED BY:	RecordCloseOrSaveAll
PASS:		ds:di	= ResourceRecord to save
		bp	= file handle( 0 if nothing to save )
RETURN:		carry set if out of disk space
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordSaveToFile	proc	near
		uses	ax,bx,cx,dx
		.enter
		tst	bp
		jz	done
	;
	; Find out how many bytes we need to write
	;
		clr	al		; we want error to be returned
		mov	bx, bp
		mov	cx, ds:[di].RR_common.RRC_dataLen
		add	cx, size ResourceRecord
		mov	dx, di
		call	FileWrite
EC <		jc	error						>
done:
		.leave
		ret
EC < error:								>
EC <		cmp	ax, ERROR_SHORT_READ_WRITE			>
EC <		WARNING_NE RW_FILE_WRITE_ERROR				>
EC <		stc							>
EC <		jmp	done						>
		
RecordSaveToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordSaveNodeToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the current node to a file

CALLED BY:	CacheRRCloseCB
PASS:		ax	= file handle
		ds:si	= node to save	
RETURN:		carry set if out of disk space
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordSaveNodeToFile	proc	near
		uses	ax,bx,cx,dx
		.enter
EC <		tst	ax						>
EC <		ERROR_Z	RFE_SAVE_ERROR					>
	;
	; Write the node into the file
	;
		mov	bx, ax
		clr	al
		mov	cx, size ResourceRecordNode + 1
		clr	dh
		mov	dl, {byte}ds:[si].RRN_name
		add	cx, dx
		mov	dx, si
		call	FileWrite
EC <		jc	error						>
done::
		.leave
		ret
EC < error:								>
EC <		cmp	ax, ERROR_SHORT_READ_WRITE			>
EC <		WARNING_NE RW_FILE_WRITE_ERROR				>
EC <		stc							>
EC <		jmp	done						>
		
RecordSaveNodeToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                RecordDeleteOld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Delete all the records older than TTL limit updating delete-
                Count.  If deleteCount reaches 0, stop.

CALLED BY:      CacheRRUpdateCB

PASS:           ax      = TTL limit( number of days to live )
                bxdx    = optr to the first resource record in RR chain
                es:deleteCount  = number of RR to delete
		es:cacheSize	= total number of cache entries

RETURN:         bxdx    = optr to new first resource record of RR chain
                bxdx    = 0 if list is now empty
                es:deleteCount adjusted
		es:cacheSize adjusted
		carry set if deleteCount reached 0

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:
		head = first;
		previous = 0;
		current = first;
	(*)
		if (current == 0) { quit }
		next = current.next;
		if (current.value > cx) {
			delete current;
			cacheSize--;
			deleteSize--;
			if (deleteSize == 0) { quit }
		} else {
			previous = current;
		}
		current = next;
		jmp (*)

	quit:
		return head

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        kho     10/24/95        Initial version
	kho	5/24/96    	Mostly rewritten

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordDeleteOld	proc	near
		uses	ax, cx
head		local	optr
previous	local	optr
current		local	optr
nextNode	local	optr
currentValue	local	word
		.enter

		mov_tr	cx, ax				; cx <- value
	;
	; head = first;
	; previous = 0;
	; current = first;
	;
		movdw	head, bxdx
		movdw	current, bxdx
		clr	ax
		movdw	previous, axax
start:
	;
	; if (current == 0) { quit }
	;
		movdw	bxdx, current
		tst	bx				; CF = 0
		jz	quit
	;
	; nextNode = current.next;
	; currentValue = current.value;
	;
		call	FindNodeValueAndNext		; nextNode/currentValue
							; filled in
	;
	; if (current.value > cx) {
	;	...
	; }
		cmp	currentValue, cx
		jb	freeNode
	;
	; else {
	;	previous = current;
	; }
	;
		movdw	previous, current, ax
goNext:
	;
	; current = nextNode;
	;
		movdw	current, nextNode, ax
	;
	; jmp loop
	;
		jmp	start

freeNode:
	;
	; /* bxdx is current */
	; delete current
	;
		call	DeleteCurrentNode		; head, previous.next 
							; updated if needed
	;
	; cacheSize--; deleteSize--;
	;
		Assert	dgroup, es
		dec	es:[cacheSize]
		dec	es:[deleteCount]
	;
	; if (deleteCount == 0) { quit }
	;
		stc
		jnz	goNext
quit:
	;
	; return head
	;
		movdw	bxdx, head
		.leave
		ret
RecordDeleteOld	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindNodeValueAndNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the value and next fields of "current", and fill
		in the local variable

CALLED BY:	RecordDeleteOld
PASS:		bx:dx	= current node optr
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		locals filled

PSEUDO CODE/STRATEGY:
		lock block,
		fill in locals,
		unlock block

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindNodeValueAndNext	proc	near
		uses	ax, ds, si
		.enter	inherit	RecordDeleteOld
		Assert	optr, bxdx
	;
	; Lock block
	;
		call	LockLMemBlockAndDeref		; ds:si - ptr
	;
	; Fill in locals
	;
		movdw	nextNode, ds:[si].RR_next, ax
		mov	ax, ds:[si].RR_common.RRC_ttl.low
		mov	currentValue, ax
	;
	; Check that nextNode is valid
	;
EC <		tst	nextNode.handle					>
EC <		jz	skipAssert					>
		Assert	optr, nextNode
EC < skipAssert:							>
	;
	; Unlock block
	;
		call	HugeLMemUnlock

		.leave
		ret
FindNodeValueAndNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteCurrentNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete current node, and adjust "head" or the previous
		linkage if necessary.

CALLED BY:	RecordDeleteOld
PASS:		bx:dx	= current
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if (head == current) {
			head = nextNode;
		}
		if (previous != 0) {
			previous.next = nextNode;
		}
		free current

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	5/24/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteCurrentNode	proc	near
		uses	ax, cx, ds, si
		.enter	inherit	RecordDeleteOld
		Assert	optr, bxdx
	;
	; if (head == current) {
	;	head = nextNode
	; }
	;
		cmpdw	head, bxdx
		jne	continue

		movdw	head, nextNode, ax
continue:
	;
	; if (previous != 0) {
	;	previous.next = nextNode;
	; }
	;
		tstdw	previous
		jz	freeNode
	;
	; Lock down previous node
	;
		push	bx, dx
		movdw	bxdx, previous
		call	LockLMemBlockAndDeref		; ds:si - ptr
	;
	; Assert previous.next == current
	;
EC <		push	ax, cx						>
EC <		movdw	axcx, current					>
EC <		Assert	e, ds:[si].RR_next.handle, ax			>
EC <		Assert	e, ds:[si].RR_next.chunk, cx			>
EC <		pop	ax, cx						>
	;
	;	previous.next = nextNode;
	;
		movdw	ds:[si].RR_next, nextNode, ax
		call	HugeLMemUnlock
		pop	bx, dx
freeNode:
		movdw	axcx, bxdx
		call	HugeLMemFree			; cx <- size
	
		.leave
		ret
DeleteCurrentNode	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockLMemBlockAndDeref
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock lmem block and deref
PASS:		bx:dx	= optr
RETURN:		ds:si	= ptr
DESTROYED:	nothing
SIDE EFFECTS:	
		Block is locked, and must be unlocked later
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockLMemBlockAndDeref	proc	near
		uses	ax
		.enter
		Assert	optr, bxdx
		call	HugeLMemLock
		mov_tr	ds, ax
		mov	si, dx
		mov	si, ds:[si]
		.leave
		ret
LockLMemBlockAndDeref	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindBestAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the best address for a RR node
CALLED BY:	Utility
PASS:		ds:si	= first address RR( RR node unlocked )
RETURN:		axdx	= IP address
DESTROYED:	ds, si
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/11/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindBestAddress	proc	far
		uses	bx
		.enter
		mov	dx, {word}ds:[si].RR_data
		mov	ax, {word}ds:[si+2].RR_data
		mov	bx, ds:LMBH_handle
		call	HugeLMemUnlock
		.leave
		ret
FindBestAddress	endp

ResolverActionCode	ends

ResolverResidentCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeNameChunkCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free domain name of a name server in SlistElement
CALLED BY:	ChunkArrayEnum in SlistDestroy
PASS:		ds:di = current element
RETURN:		nothing
DESTROYED:	ax
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeNameChunkCallback	proc	far
		mov	ax, ds:[di].SE_serverName
		tst	ax
		jz	done
		call	LMemFree
done:
		clc
		ret
FreeNameChunkCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CacheResourceRecordCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cache the resource record passed in
CALLED BY:	ResponsePacketEnum
PASS:		es:di	= a resource record in response packet
		es:bp	= ptr to last valid owner name
RETURN:		carry set if memory error
		es:bp	= ptr to last valid owner name
DESTROYED:	ds,si
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 9/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CacheResourceRecordCallback	proc	far
		uses	ax,bx
		.enter
	;
	; Find or allocate ResourceRecordNode to add this record to
	;
	; If the owner name at es:di is null, try using the last valid
	; owner name.  If there is no last valid owner name, don't cache
	; this record.
	;
		mov	ax, di			; save di
		tst	{byte}es:[di]		; owner name non-null?
		jnz	addName			; Branch if so
		mov	di, bp			; Try last valid owner name
		tst	di			; There is one, right?
		jz	done			; Branch if not
addName:
		call	TreeAddDomainName	; ds:si	= last visited node
		jc	done
		mov	bp, di			; es:bp = valid owner name
		mov	di, ax			; restore original di
	;
	; es:di = resource record in a packet
	; skip ResourceRecord name
	;
		mov_tr	bx, cx
		mov	cx, MAX_HOST_NAME_SIZE
		clr	al
		repne scasb
		mov_tr	cx, bx			; es:di = ResourceRecordCommon
	;					;         followed by RDATA
	; ds:si = ResourceRecordNode
	; es:di = ResourceRecordCommon + data to add
	;
		call	RecordFindDuplicate	; ds:si = ResourceRecord found
		jnc	updateTTL
	;
	; ds:si = ResourceRecordNode
	;
EC <		push	ax, bx						>
EC <		movdw	axbx, ds:[si].RRN_resource			>
EC <		tst	ax						>
EC <		jz	skipAssert					>
EC <		Assert	optr, axbx					>
EC < skipAssert:							>
EC <		pop	ax, bx						>
		call	RecordAppend		; buffer allocated in hugelmem
unlockExit:
	;
	; Unlock ResourceRecordNode
	;
		mov	bx, handle ResolverCacheBlock
		call	MemUnlock
done:
		.leave
		ret
updateTTL:
	;
	; Update TTL of the existing record
	; es:di = ResourceRecordCommon + data to add
	; ds:si = resource record found
	;
		call	RecordConvertTTL	; convert TTL in the packet
		movdw	bxax, es:[di].RRC_ttl
		movdw	ds:[si].RR_common.RRC_ttl, bxax		
		mov	bx, ds:LMBH_handle
		call	HugeLMemUnlock
		jmp	unlockExit
CacheResourceRecordCallback	endp

ResolverResidentCode	ends






; **************************************************************************
;
; 			CODE THAT WAS REMOVED
;
; **************************************************************************


if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlistSetupSbelt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct sbelt
CALLED BY:	ResolverInit
PASS:		nothing
RETURN:		carry set if SBELT format in .ini file is bad
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlistSetupSbelt	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Do a enum on list of strings in .init file
	;
		mov	bx, handle ResolverRequestBlock
		call	MemLock
		mov	ds, ax

		mov	bx, size SlistElement
		clr	si, cx
		call	ChunkArrayCreate	; *ds:si = chunk array
		mov	ds:RBH_sbelt, si

		mov	cx, ds
		mov	si, offset resSbeltKwd
		mov	dx, ds:[si]		; cx:dx = keyword
		mov	si, offset resCategory
		mov	si, ds:[si]		; ds:si = category
		mov	bp, mask IFRF_FIRST_ONLY
		mov	di, segment SbeltSetupCallback
		mov	ax, offset SbeltSetupCallback
		call	InitFileEnumStringSection
		jc	unlockDone
unlockDone:
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
		.leave
		ret
SlistSetupSbelt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SlistUseSbelt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy Sbelt and return
CALLED BY:	SlistInitialize
PASS:		nothing
RETURN:		carry set if mem error, ax = destroyed
		otherwise
			ax	= chunk handle to a duplicate of sbelt
			cx	= -1 (match count)
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 5/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SlistUseSbelt	proc	near
		uses	bx,ds,si,bp
		.enter
		mov	bx, handle ResolverRequestBlock
		call	MemLock
		mov	ds, ax
		mov	si, ds:RBH_sbelt	; ds:*si = sbelt
		call	LMemCopyChunk		; ds:*ax = copy of sbelt
		jc	done
	;
	; Now copy all the name chunks
	;
		clr	cx			; index starts at 0
		mov	si, ax			; ds:*si = new slist
		mov	bx, segment ReplaceNameChunkWithCopyCallback
		mov	di, offset ReplaceNameChunkWithCopyCallback
		call	ChunkArrayEnum		; ax,bx,cx,bp = destroyed
EC <		WARNING_C RW_MEMORY_ERROR				>
		jc	done			; mem error
		mov_tr	ax, si
		mov	cx, -1
done:
		mov	bx, handle ResolverRequestBlock
		call	MemUnlock
		.leave
		ret
SlistUseSbelt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceNameChunkWithCopyCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the name chunk in SlistElement
CALLED BY:	ChunkArrayEnum via SlistUseSbelt
PASS:		ds:di	= slist element
		cx	= element index
RETURN:		nothing
DESTROYED:	ax, si
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	1/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceNameChunkWithCopyCallback proc	far
		
		mov	bx, ds
		push	si
		mov	si, ds:[di].SE_serverName
		call	LMemCopyChunk	; ax = new copy
		pop	si
		jc	done		; error case
		mov	bp, ds
		cmp	bp, bx
		je	noChange	; block did not move
	;
	; dereference SlistElement again since the block moved
	; *ds:si = slist chunk array
	;
		push	ax, cx
		mov	ax, cx
		call	ChunkArrayElementToPtr	; ds:di = SlistElement
		pop	ax, cx
noChange:
		mov	ds:[di].SE_serverName, ax
		inc	cx
done:
		ret
ReplaceNameChunkWithCopyCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SbeltSetupCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build sbelt by reading strings from .ini file

CALLED BY:	SlistSetupSbelt ( via InitFileEnumStringSection )
PASS:		ds:si	= string section
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	2/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SbeltSetupCallback	proc	far
		uses	bx, ds
		.enter
	;
	; Allocate a dummy domain name string: ".",0
	;
		mov	bx, handle ResolverRequestBlock
		mov	dx, ds			; save string seg in dx
		mov	bp, si			; dx:bp = string fptr
		call	MemDerefDS
		mov	cx, 2
		call	LMemAlloc		; ax = new chunk
		jc	done			; memory error
		mov	di, ax
		mov	di, ds:[di]
		mov	{byte}ds:[di], '.'
		mov	{byte}ds:[di+1], 0	; ".",0
		mov	si, ds:RBH_sbelt
		call	ChunkArrayAppend	; ds:di = new element
		jc	done			; memory error
		segmov	es, ds, bx
		mov	es:[di].SE_flags, 0
		mov	es:[di].SE_serverName, ax
		mov	es:[di].SE_nameLen, 1	; this doesn't matter
		add	di, offset SE_address
	;
	; Now loop around the string section parsing address
	;
		mov	cx, 4			; IP address has 4 parts
		movdw	dssi, dxbp
parseLoop:
	;
	; ds:si = next digit to parse
	; es:di = byte location to store the parsed result
	;
		call	ParseAndStoreIPAddress	; si, di adjusted
		jc	done
		loop	parseLoop
done:
		.leave
		ret
SbeltSetupCallback	endp

endif


