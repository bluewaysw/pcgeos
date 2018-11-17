COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Novell NetWare Library
FILE:		msg.asm (NetObjMessage code)


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version
	Eric	8/92		Ported to 2.0.

DESCRIPTION:
	This library allows PC/GEOS applications to access the Novell NetWare
	Applications Programmers Interface (API). This permits an application
	to send and receive packets, set up connections between nodes on the
	network, access Novell's "Bindery", which contains information about
	network users, etc.

RCS STAMP:
	$Id: msg.asm,v 1.1 97/04/05 01:25:01 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetMessageCode
;------------------------------------------------------------------------------

NetMessageCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetObjMessage

DESCRIPTION:	Send the passed message (and data) to a remote object
		over the network.

		This function is very similar to ObjMessage, except that
		the destination object, process, or thread are on a
		remote node which is also running PC/GEOS and the
		Network Library.

		Specific features:
			- "send" and "call" - type messages are fully supported.

			- can broadcast to all nodes on network (with 95%
			reliability), send to a specific node, or send over
			a connection that has already been established with
			a process on another node (100% reliability).

			- can address message to a "type" of object on the
			destination node(s), such as the System object,
			current focused GenApplication, etc.

			- can address message to a type of application on the
			destination node(s), by passing a Token ID.

			- can address message to a specific object on the
			destination node.

			- can pass data on stack, and/or can pass an extra
			data block on the global heap (of ANY size). Remote
			object can return stack and/or global heap data.

			- can pass exotic ObjMessage flags such as
			MF_CHECK_DUPLICATE, for remote ObjMessage to handle.

			- the Network Library and Application's protocol
			numbers are passed along with the packet, to ensure
			matching APIs across the net.

IMPORTANT:	See /s/p/Include/net.def for full documentation on the
		arguments that can be passed.

PASS:		ax	= message to send
		bx:si	= Minor Address: OD of object on remote node, or
			  a special constant. (See below)
		
		cx, dx, bp = message data (depending upon the flags passed
			     in di, these may have special meaning)

		di	= NLMessageFlags record: similar to ObjMessage's
			  MessageFlags record. See Include/net.def.

		es.low	= Source Connection ID, when sending message via
			  a specific connection (NLMF_CONNECTION_ID_ES=1).

RETURN:		ax, cx, dx, bp, carry flag = return data
		di	= NLErrorCodes (if NLMF_RETURN_ERROR passed in di)
		ds, es	= same as passed (this might be useful, if you are
			  sending a message from your application's process
			  object, since DGROUP will not move in 12X.)

		If you passed data on the stack, it will still be there.

		If you passed a data block, it will have been freed.

DESTROYED:	assume everything is trashed...

PSEUDO CODE/STRATEGY:
	create a default HugeECB to place all of this info into
		place message, addressing, and register info into it
		add stack-based and heap-based data into HugeECB structure

	call specific network driver (such as NW) to queue up this HugeECB
	for transmission. It may block the calling thread on a semaphore
	in the HugeECB, so that it can return transmission success
	information.

	When specific network driver has finished sending this SEND message,
	or has received return values from this CALL message, it will lock the
	HugeECB, and VSem the semaphore, waking us up again.

	When return from specific network driver, set up return registers
	and data blocks as appropriate.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version
	Eric	8/92		Ported to 2.0.

------------------------------------------------------------------------------@

NetObjMessage	proc	far
	uses	ds, es
	.enter

EC <	call	ECCheckNetObjMessageParams	;check params		>

	;create a HugeECB to hold our message data. Unload registers,
	;stack data, and heap data into HugeECB.

	call	NetObjMessageMoveArgsIntoHugeECB
						;returns ^hbx = HugeECB,
						;unlocked.

	;Now pass this HugeECB onto the specific network driver,
	;for transmission.

	mov	cx, bx				;^hcx = HugeECB (unlocked)
	mov	di, DR_NET_SEND_HECB
	segmov	es, <segment dgroup>, ax
	call	NetCallDriver

	.leave
	ret
NetObjMessage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetObjMessageMoveArgsIntoHugeECB

DESCRIPTION:	Grab all of the register, stack, and heap-based message
		arguments, and place them into a newly-created HugeECB.

CALLED BY:	NetObjMessage

PASS:		<SAME ARGS AS NetObjMessage>

RETURN:		ss:bp	= stack data as passed
		^hbx	= HugeECB, with all reg, stack, and heap data
			  copied in. (UNLOCKED... the specific network
			  driver will know whether any of the internal values
			  need to be updated when this block is locked. For
			  example, under NetWare, a FPTR is kept inside this
			  block, to point to one of the data fragments
			  in the block. The NW Driver has a routine called
			  NetWareDriver_LockHECB which knows how to deal
			  with this.)

DESTROYED:	ax, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetObjMessageMoveArgsIntoHugeECB	proc	near

	;determine the total size of this packet

	push	dx, cx, ax, bx

	mov	bx, cx			;pass ^hbx = global block
	clr	ax			;assume no bytes from heap
	mov	cx, ax			;and no bytes from stack

	test	di, mask NLMF_MAJOR_ADDR_ON_STACK or mask NLMF_STACK
	jz	10$			;skip if no data on stack...

	mov	cx, dx			;cx = data on stack

10$:
	test	di, mask NLMF_PASSED_DATA_BLOCK 
	jz	20$			;skip if no global data block

	push	cx, di, si
	mov	ax, MGIT_SIZE
	call	MemGetInfo		;returns ax = size in bytes

EC <	test	ax, 0x000F		;make sure is mult. of 16	>
EC <	ERROR_NZ NL_ERROR		;				>
EC <	push	ax							>
EC <	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT				>
EC <	call	MemGetInfo		;returns ah = lock count	>
EC <	tst	ah			;lock count MUST be 0		>
EC <	ERROR_NZ NL_ERROR						>
EC <	pop	ax							>

	pop	cx, di, si

20$:	;allocate a HugeECB to hold the entire packet, and ECB.
	;	ax	= size of data on heap
	;	cx	= size of data on stack

	push	cx
	mov	dx, ax			;dx = amount of data on heap
	add	cx, ax			;cx = total data on heap and stack

					;pass di = NLMessageFlags, indicating
					;whether is IPX or SPX packet. Also,
					;we know that either NLMF_SEND or
					;NLMF_CALL is set, so a "send" type
					;packet will be created (i.e. the
					;callback routine for departing ECBs
					;will be used.)

					;pass dx = BOGUS socket # (for now)

	mov	bx, es			;in case is SPX packet, pass es.low
					;=source connection number

	call	NetCreateHECB		;returns ^hbx = HugeECB with defaults.
					;does not trash DX, SI, DI, BP
	pop	cx

	;pop registers from stack into ECB
	;	dx	= size of data on heap
	;	cx	= size of data on stack
	;	si	= passed SI
	;	di	= passed DI
	;	ss:bp	= data on stack

	call	MemLock
	mov	es, ax

	pop	es:[HECB_msg].NLMPS_minorAddress.handle	;from BX
	mov	es:[HECB_msg].NLMPS_minorAddress.chunk, si
	pop	es:[HECB_msg].NLMPS_message		;from AX
	mov	es:[HECB_msg].NLMPS_nlMessageFlags, di
	mov	di, bx					;^hdi = HugeECB
	pop	bx					;from CX
	mov	es:[HECB_msg].NLMPS_cx, bx
	pop	es:[HECB_msg].NLMPS_dx			;from DX

	mov	es:[HECB_msg].NLMPS_bp, bp

	;copy stack data into HugeECB

	push	di			;save handle of HugeECB
	segmov	ds, ss			;set ds:si = stack data
	mov	si, bp
	mov	di, offset HECB_msg.NLMPS_msgData
					;set es:di = dest inside HugeECB

	tst	cx
	jz	50$			;skip if none...

	rep	movsb			;copy CX bytes from stack to HugeECB

	;we just copied stack data over. If this included a
	;NLNodeSocketAddrAndTokenID structure, then copy some of the
	;information from it to the ECB and IPX structures.

	test	es:[HECB_msg].NLMPS_nlMessageFlags, \
						mask NLMF_MAJOR_ADDR_ON_STACK
	jz	50$

	;copy NLNodeSocketAddrAndTokenID into the IPX structure

	push	di			;save pointer to end of msg data
	sub	si, size NLNodeSocketAddrAndTokenID
					;set ds:si = NLNodeSocketAddrAndTokenID
					;structure on stack

	mov	di, offset HECB_msg.NLMPS_spx.IPXSPX_ipx.IPX_dest
	mov	cx, size NovellNodeSocketAddrStruct
	rep	movsb

	;copy the socket address and node address over to the ECB

	sub	si, size NovellNodeSocketAddrStruct
					;set ds:si = NLNodeSocketAddrAndTokenID
					;structure on stack

	mov	ax, ds:[si].NLNST_nodeSocket.NNSAS_socket
	mov	es:[HECB_ecb].ECB_socketAddress, ax

	add	si, offset NLNST_nodeSocket.NNSAS_node
	mov	di, offset HECB_ecb.ECB_immediateAddress
	mov	cx, size NovellNodeAddress
	rep	movsb
	pop	di			;es:di = end of msg data from above

50$:	;copy global heap data into HugeECB
	;	es:di = end of msg data from above

	tst	dx
	jz	80$			;skip if none...

	mov	cx, dx			;cx = amount of data
	mov	es:[HECB_msg].NLMPS_cx, cx
					;rather than passing a global handle
					;to the remote node, pass the size of
					;the data.

	call	MemLock			;lock block on global heap
	mov	ds, ax			;ds:si = start of data
	clr	si

	rep	movsb			;copy CX bytes from stack to HugeECB

	call	MemFree			;free the passed memory block

80$:	;restore ^hbx = HugeECB, and return

	pop	bx	
	call	MemUnlock		;unlock the HugeECB
	ret
NetObjMessageMoveArgsIntoHugeECB	endp

if ERROR_CHECK
ECCheckNetObjMessageParams	proc	near
	;check some special conditions upon which we insist

	test	di, mask NLMF_CALL or mask NLMF_SEND
	ERROR_Z NL_ERROR_MUST_SPECIFY_EITHER_CALL_OR_SEND
					;must specify at least one

	test	di, mask NLMF_CALL
	jz	10$

	test	di, mask NLMF_CONNECTION_ID_ES
	ERROR_Z NL_ERROR_MUST_USE_CONNECTION_FOR_CALL_MESSAGES
				;have to use an established connection in
				;order to send a message using "call".

	test	di, mask NLMF_SEND
	ERROR_NZ NL_ERROR_MUST_SPECIFY_EITHER_CALL_OR_SEND
					;can't specify both SEND and CALL

10$:
;	test	di, mask NLMF_CUSTOM_IN_BLOCK
;	jz	20$
;
;	test	di, mask NLMF_PASSED_DATA_BLOCK
;	ERROR_Z NL_ERROR_MUST_PASS_DATA_BLOCK_FOR_CUSTOM_IN_BLOCK
;
;20$:
	test	di, mask NLMF_MAJOR_ADDR_ON_STACK
	jz	30$

	test	di, mask NLMF_CONNECTION_ID_ES
	ERROR_NZ NL_ERROR_SPECIFY_ONLY_ONE_MAJOR_ADDRESS
				;cannot have both NLMF_MAJOR_ADDR_ON_STACK and
				;NLMF_CONNECTION_ID_ES. Make up your mind!
	jmp	short 40$

30$:
	test	di, mask NLMF_CONNECTION_ID_ES
	ERROR_Z	NL_ERROR_MUST_SPECIFY_A_MAJOR_ADDRESS
				;must have either NLMF_MAJOR_ADDR_ON_STACK or
				;NLMF_CONNECTION_ID_ES.

40$:
	ret
ECCheckNetObjMessageParams	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetUnpackHugeECBAndDispatchLocalMessage

DESCRIPTION:	This routine is called by the specific network drivers.

		Unload data from the passed HugeECB into registers,
		stack, and the heap, and then dispatch the message.

PASS:		ds	= HugeECB

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version
	Eric	8/92		Ported to 2.0.

------------------------------------------------------------------------------@

NetUnpackHugeECBAndDispatchLocalMessage	proc	far
	.enter

if ERROR_CHECK
	;first, make sure that minor address is NLMA_APP_PROCESS,
	;as nothing else is supported yet.

	cmp	ds:[HECB_msg].NLMPS_minorAddress.handle, \
							NLMA_APP_PROCESS
	ERROR_NE NL_ERROR

	tst	ds:[HECB_msg].NLMPS_minorAddress.chunk
	ERROR_NZ NL_ERROR

	;make sure that a major address has been passed

	test	ds:[HECB_msg].NLMPS_nlMessageFlags, \
					mask NLMF_MAJOR_ADDR_ON_STACK
	ERROR_Z NL_ERROR
endif

	;assume that we will have to deliver this message to multiple
	;destination objects (such as "all of the GeoGram process objects"),
	;and initialize our loop variable.

	clr	cx

dispatchLoop:
	;determine the destination for this message, on this machine

	call	NetDetermineLocalDestination
					;sets ^lbx:si = destination object
					;and cx = "next" value

	;make sure that we found something

	tst	bx
	LONG jz finishUp		;skip to end if not...

	;save the OD of the destination object

	mov	ds:[HECB_msg].NLMPS_minorAddress.handle, bx
	mov	ds:[HECB_msg].NLMPS_minorAddress.chunk, si

	push	ds:[HECB_handle]	;save handle of this HugeECB
	push	cx			;save value for next time through loop

;------------------------------------------------------------------------------
	;load up some initial registers that we will use below
	;(will either not be changed by any code, so will reach the
	;call to ObjMessage, OR may be changed by code below, so set
	;up default value here -- bp is good example)

	mov	dx, ds:[HECB_msg].NLMPS_dx
	mov	bp, ds:[HECB_msg].NLMPS_bp

;------------------------------------------------------------------------------
	;stack data: first check for NLNodeSocketAddrAndTokenID structure,
	;which would be at the END of the stack data area.

	mov	bx, offset HECB_msg.NLMPS_msgData
					;ds:bx = start of data portion

	test	ds:[HECB_msg].NLMPS_nlMessageFlags, \
						mask NLMF_MAJOR_ADDR_ON_STACK
	jz	10$			;no, just simple stack data...

	;Yes: NLMF_MAJOR_ADDR_ON_STACK is set. Let's decrement DX, so that this
	;extra junk is NOT copied to the stack.

	add	bx, size NLNodeSocketAddrAndTokenID
					;push data pointer forward
					;(is used below to find end of
					;ALL stack data)
	sub	dx, size NLNodeSocketAddrAndTokenID

10$:	;now check for normal stack data

	test	ds:[HECB_msg].NLMPS_nlMessageFlags, mask NLMF_STACK
	jz	15$			;skip if no stack data...

	add	bx, dx			;ds:bx = end of all stack data,
					;for the code below this MOVSB

	sub	sp, dx			;MAKE ROOM ON STACK

	mov	si, offset HECB_msg.NLMPS_msgData
					;ds:si = start of data portion

	mov	di, ss			;set es:di = dest on stack
	mov	es, di
	mov	di, sp	

	mov	cx, dx			;cx = size of data
	rep	movsb			;at end, ds:si = rest of data in packet

	mov	bp, sp			;set ss:bp = dest on stack
					;	(for ObjMessage call below)

15$:	;now set ds:si = next byte following any stack data

	mov	si, bx

;------------------------------------------------------------------------------
	;see if we need to create a block on the heap
	;	ds:si	= data in HugeECB, if we need it.

	mov	cx, ds:[HECB_msg].NLMPS_cx
					;load up another register, in case
					;we have to override its value here

	test	ds:[HECB_msg].NLMPS_nlMessageFlags, mask NLMF_PASSED_DATA_BLOCK
	jz	30$			;skip if not...

	;create the block

	mov	ax, cx			;ax = size of block to create
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
					;allocate as HF_SWAPABLE, HF_SHARABLE,
					;and HAF_LOCK.
	call	MemAlloc		;returns bx = handle of block
					;and ax = segment of block
	mov	es, ax			;set es:di = block (is locked)
	clr	di

	mov	cx, ds:[HECB_msg].NLMPS_cx ;cx = size of block
	rep	movsb
	call	MemUnlock
	mov	cx, bx			;set ^hcx = local block, for local
					;ObjMessage...

;------------------------------------------------------------------------------
30$:	;grab the rest of the registers

	mov	ax, ds:[HECB_msg].NLMPS_message
	mov	si, ds:[HECB_msg].NLMPS_minorAddress.chunk
	mov	di, ds:[HECB_msg].NLMPS_nlMessageFlags
	ANDNF	di, MASK_MF_ONLY_FLAGS	;only keep valid flags for ObjMessage

	push	ds:[HECB_msg].NLMPS_minorAddress.handle
	mov	bx, ds:[HECB_handle]	;^hbx = handle of HugeECB
	call	MemUnlock		;unlock it
	pop	bx

;------------------------------------------------------------------------------
	;now dispatch the message locally. Will only be MF_CALL type
	;if we are running in one of the created threads, in which it
	;is ok to block. Otherwise, is NLMF_SEND type, which means
	;MF_FORCE_QUEUE locally, so this call will return right away. Peachy.

EC <	test	di, mask NLMF_CALL	;not supported yet!		>
EC <	ERROR_NZ NL_ERROR						>

	push	dx, di
	call	ObjMessage		;does not trash ds

;ACK! Will eventually need to handle return values here! Might just
;want to keep the HugeECB around (but unlocked), so that we could
;just swap the source and dest address, etc. (Are addresses necessary when
;going across a connection?)

	;see if we need to clean up the stack

	pop	dx, di
	test	di, mask MF_STACK
	jz	loopForNext		;skip if not...

	add	sp, dx			;fix up stack pointer before returning

;------------------------------------------------------------------------------
loopForNext:
	;get the loop counter, and see if we are done

	pop	bx, cx
	tst	cx			;is there another possible dest?
	jz	freeHECB		;skip to end if not...

	;we have to loop, to deliver this message again. Lock the HugeECB

	call	MemLock
	mov	ds, ax
	jmp	dispatchLoop		;loop for next...

finishUp: ;now free the HugeECB

	mov	bx, ds:[HECB_handle]

freeHECB:
	call	MemFree			;nuke the HugeECB

	.leave
	ret
NetUnpackHugeECBAndDispatchLocalMessage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetDetermineLocalDestination

DESCRIPTION:	Determine the local OD that this message should be sent to.

PASS:		ds	= HugeECB (locked)
		cx	= "next" field. When delivering message to several
			applications which have the same TokenID, this field
			tells us where to start GeodeForEach again.

RETURN:		ds	= same
		^lbx:si	= destination for message (bx=0 if none)
		cx	= "next" field: 0 if no other possible destinations
			  after this one. Otherwise, contains a value that
			  should be passed back to this routine to continue.

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

;PrintMessage <NetDetermineLocalDestination is hard-coded for now: >
;PrintMessage <only handles messages addressed to application process objects>
;PrintMessage <by their TokenID.> 

NetDetermineLocalDestination	proc	near

	;handle the MAJOR_ADDR = <NodeSocketAddr><TokenID> case.
	;First, set ds:si = GHToken structure in the message
	;portion of the HugeECB.

	mov	bx, cx			;bx = Geode to start with ("next")

;SAVE BYTES
	mov	cx, ds
	mov	dx, offset HECB_msg.NLMPS_msgData
					;cx:dx = start of data portion

	add	dx, ds:[HECB_msg].NLMPS_dx
					;point to end of stack data

	sub	dx, (size NLNodeSocketAddrAndTokenID) - \
		    (offset NLNST_token)
					;back up to the start of the
					;NLNodeSocketAddrAndTokenID structure,
					;then move forward to point to the
					;GHToken token field within it.

PrintMessage <CLEANUP THIS>
if 1
	;cx:dx	= GHToken to look for
	;bx	= geode from which to start (0 = beginning of list).

	mov	di, cs			;pass di:si = CallBack routine
	mov	si, offset NetGeodeFindByTokenID_callback
	call	GeodeForEach		;returns carry set if found a match:
					;	^hbx = last Geode processed --
					;		(the one we matched)
					;	^hsi = next geode
					;else
					;	bx = 0.

	;In case there is a match, then let's return cx = the next geode to
	;check, after we have sent the message to this one.

	mov	cx, si			;^hcx = next geode (if any)
	clr	si			;^lbx:si = destination

	tst	bx			;is there a match?
	jz	done			;skip if not (cx does not matter)...

;	push	bx
;	clr	cx			;default: there is no next geode
;	mov	ax, 1			;skip the first geode we are given
;	mov	di, cs			;pass di:si = CallBack routine
;	mov	si, offset NetGeodeFindNext_callback
;	call	GeodeForEach		;returns cx = next geode, or 0 if none
;	pop	bx

else

	segmov	es, cs			;es:di = 8 char name to match
	mov	di, offset Foo
	mov	ax, GEODE_NAME_SIZE
	clr	cx
	clr	dx
	call	GeodeFind

	clr	si			;^hbx:si = destination
	clr	cx			;no more to send
endif

done::

	ret
NetDetermineLocalDestination	endp

if 0
Foo	char	"geogram ",0
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetGeodeFindByTokenID_callback

DESCRIPTION:	Find the next Geode in the list, using a TokenID value.

CALLED BY:	GeodeForEach (NLProc_DetermineLocalDestination)

PASS:		ds:bp		= pointer to GHToken structure to search for

		From GeodeForEach:
		^hbx		= handle of this Geode
		es		= segment of this Geode's core block

RETURN:		carry set if found a match

DESTROYED:	?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		From GF_callback

------------------------------------------------------------------------------@

NetGeodeFindByTokenID_callback	proc	far
	uses	cx
	.enter

	;check the Token instead of the name

	mov	ds, cx
	mov	si, dx		;ds:si = GHToken we are looking for

	mov	di, offset GH_geodeToken
				;es:di = GHToken for this Geode

	mov	cx, size GeodeToken
	repe	cmpsb		;compare the two

	clc
	jne	done		;skip if not the same...

	stc			;signal match (stop processing)

done:
	.leave
	ret
NetGeodeFindByTokenID_callback	endp


if 0
NetGeodeFindNext_callback	proc	far
	dec	ax		;one less to skip
	clc
	jns	done		;skip this one...

	;return with cx = this geode

	stc
	mov	cx, bx		;return ^hcx = this geode

done:
	ret
NetGeodeFindNext_callback	endp
endif

NetMessageCode	ends
