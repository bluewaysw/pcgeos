COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasServerEvents.asm

AUTHOR:		Andy Chiu, Dec 14, 1995

ROUTINES:
	Name			Description
	----			-----------
	ISFChangeState
	ISFLmConnectIndication
	ISFLmDisconnectIndication
	ISFCallResponse
	ISFLmDataIndication

	ISFSetServerIrlmpHandle	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial revision


DESCRIPTION:
	Event handling for the IAS Server FSM
		

	$Id: iasServerEvents.asm,v 1.1 97/04/05 01:07:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


IasCode		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFChangeState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change state.

CALLED BY:	MSG_ISF_CHANGE_STATE
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		dx	= next state (IasServerFsmState)
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFChangeState	method dynamic IasServerFsmClass, 
					MSG_ISF_CHANGE_STATE
		.enter

		Assert	etype	dx, IasServerFsmState

		mov	ds:[di].ISFI_state, dx

		.leave
		ret
ISFChangeState	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFLmConnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Connect.indication received by the IAS Server

CALLED BY:	MSG_ISF_LM_CONNECT_INDICATION
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		cx	= client handle
		ss:bp	= IrlmpConnectArgs
		dx	= size IrlmpConnectArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 4/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFLmConnectIndication	method dynamic IasServerFsmClass, 
					MSG_ISF_LM_CONNECT_INDICATION
		uses	ax, cx, dx, bp
		.enter
	;
	; Look at the connect args
	;
		push	cx			; save client endpoint
		movdw	cxdx, ssbp
	;
	; Rember some info about the connection.
	;
		mov	al, ss:[bp].ICA_QoS.QOS_param.ICP_dataSize
		mov	ds:[di].ISFI_frameSize, al
	;
	; Free the connect request that was sent to us.
	;
		call	IUFreeDataArgs
	;
	; Now send it an empty frame to say we connected.
	;
		pop	si			; si <- client endpoint
		sub	sp, size IrlmpDataArgs
		mov	bp, sp

		clr	ss:[bp].IDA_dataSize
		mov	cx, ss
		mov_tr	dx, bp
	;
	; IrlmpConnectResponse ends up sending a message via MF_CALL
	; and doesn't fix up ds because it doesn't know DS is a movable
	; segment.  So we have to manually fix it up.
	;
		mov	bx, ds:[LMBH_handle]
		call	IrlmpConnectResponse
EC <		ERROR_C	IRLMP_CANNOT_CONNECT_RESPONSE			>
		call	MemDerefDS
		
		lahf
		add	sp, size IrlmpDataArgs
		sahf				; carry set if error
		jc	exit
	;
	; LM_Connect.indication is only expected in the ISFS_DISCONNECTED
	; state.
	;
		cmp	ds:[di].ISFI_state, ISFS_DISCONNECTED
EC <		WARNING_NE IRLMP_ILLEGAL_STATE_AND_EVENT_COMBINATION	>
		jne	exit
	;
	; Change to the R-waiting state. 
	;
		mov	ds:[di].ISFI_state,  ISFS_WAITING
		
exit:
		.leave
		ret
ISFLmConnectIndication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFLmDisconnectIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Disconnect.indication received by the IAS Server.

CALLED BY:	MSG_ISF_LM_DISCONNECT_INDICATION
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		cx	= lptr to client endpoint
		ss:bp	= IrlmpDataArgs
		dx	= size IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFLmDisconnectIndication	method dynamic IasServerFsmClass, 
					MSG_ISF_LM_DISCONNECT_INDICATION
		uses	ax, cx, dx, bp
		.enter
	;
	; Free the data args that were passed to us.
	;
		movdw	cxdx, ssbp
		call	IUFreeDataArgs
	;
	; Change to the R-disconnected state. 
	;
		mov	ds:[di].ISFI_state,  ISFS_DISCONNECTED

	;
	; Let's get rid of our client handle to irlmp and unregister.
	;
		push	si
		clr	si
		xchg	ds:[di].ISFI_serverHandle, si
		call	IrlmpUnregister
		pop	si

	;
	; Free the IasServerFsm object.
	;
		mov	ax, MSG_META_OBJ_FREE
		mov	bx, si			; bx <- client chunk
		call	IasServerFsmSend

		.leave
		ret
ISFLmDisconnectIndication	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFCallResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Results of the current operation is returned

CALLED BY:	MSG_ISF_CALL_RESPONSE
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		cx:dx	= IrlmpDataArgs
		bp	= client handle of requesting endpoint
RETURN:		carry clear on success
			ax = IE_SUCCESS
		carry set if error
			ax = IrlmpError
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFCallResponse	method dynamic IasServerFsmClass, 
					MSG_ISF_CALL_RESPONSE
		uses	ax
		.enter
		Assert	fptr, dssi
	;
	; In the execute state.  Send the packet to who we're connected
	; to.
	;
		mov	bx, si				; bx <- lptr to fsm
		mov	si, bp
		call	IrlmpDataRequest

		.leave
		ret
ISFCallResponse	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFLmDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Data.indication

CALLED BY:	MSG_ISF_LM_DATA_INDICATION
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		cx	= client handle
		ss:bp	= IrlmpDataArgs
		dx	= size IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFLmDataIndication	method dynamic IasServerFsmClass, 
					MSG_ISF_LM_DATA_INDICATION
		uses	ax, cx, dx, bp
		.enter
		
		Assert	etype	ds:[di].ISFI_state, IasServerFsmState

		mov_tr	ax, cx			; ax <- client handle
		movdw	cxdx, ssbp
		mov_tr	bp, ax			; bp <- client handle

		mov	ax, ds:[di].ISFI_state

		cmp	ax, ISFS_WAITING
		jz	waiting

		cmp	ax, ISFS_RECEIVING
		jz	receiving

		cmp	ax, ISFS_RETURNING
		jz	returning

EC <		WARNING	IRLMP_ILLEGAL_STATE_AND_EVENT_COMBINATION	>
		jmp	freeArgs

	;
	; If the packet is not an ack, then pass it off to 
	; the next state.
	;
waiting:
		call	ISAWaitingDataIndication
		jmp	exit
	;
	; Pretend this doesn't happen right now (12/14) ACJ
	;
receiving:
		call	ISAReceivingDataIndication
		jmp	exit

	;
	; Send the results of the query
	;
returning:
		call	ISAReturningReceiveAck

exit:
		.leave
		ret

freeArgs:
		call	IUFreeDataArgs
		jmp	exit
ISFLmDataIndication	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFSetServerIrlmpHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the server's handle to the irlmp library

CALLED BY:	MSG_ISF_SET_SERVER_IRLMP_HANDLE
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		cx	= handle to irlmp library
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 1/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFSetServerIrlmpHandle	method dynamic IasServerFsmClass, 
					MSG_ISF_SET_SERVER_IRLMP_HANDLE

		mov	ds:[di].ISFI_serverHandle, cx
		ret
ISFSetServerIrlmpHandle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFMetaFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take care of destroying the ias thread when it's the
		last ias object.

CALLED BY:	MSG_META_FINAL_OBJ_FREE
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	6/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFMetaFinalObjFree	method dynamic IasServerFsmClass, 
					MSG_META_FINAL_OBJ_FREE


	;
	; Save the handle to this block
	;
		push	ds:[LMBH_handle]
	;
	; Decrement the server count
	;
		call	UtilsLoadDGroupDS
		PSem	ds, iasServerSem
		dec	ds:[iasServerCount]
		jnz	doVsem
	;
	; If this is the last object, then detach the thread.
	;
		clr	bx
		xchg	ds:[iasServerThread], bx
		clr	cx, dx, bp, di
		mov	ax, MSG_META_DETACH
		call	ObjMessage

doVsem:
		VSem	ds, iasServerSem

	;
	; Continue on with the method.
	;
		pop	bx
		call	MemDerefDS
		mov	ax, MSG_META_FINAL_OBJ_FREE
		mov	di, offset IasServerFsmClass
		GOTO	ObjCallSuperNoLock
ISFMetaFinalObjFree	endm



IasCode		ends















