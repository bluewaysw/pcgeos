COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		IAS
FILE:		iasServerActions.asm

AUTHOR:		Andy Chiu, Dec 14, 1995

ROUTINES:
	Name			Description
	----			-----------
	ISAReturningReceiveAck
	ISAWaitingDataIndication
	ISAWaitActiveDataIndication
	ISAExecuteCommand
	ISAReceivingDataIndication

	ISAGetValueByClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95   	Initial revision


DESCRIPTION:
	Actions done by the IAS Server FSM
		

	$Id: iasServerActions.asm,v 1.1 97/04/05 01:07:55 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAReturningReceiveAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We received an act after sending a packet of return 
		data.

		This routine is currently not done. XXX

CALLED BY:	(INTERNAL) ISFLmDataIndication

PASS:		ds:si	= IasServerFsm object
		cx:dx	= IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAReturningReceiveAck	proc	near
		class	IasServerFsmClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
if 0
	;
	; Pointer to our IrlmpDataArgs
	;
		movdw	dssi, cxdx

	;
	; Get a pointer to the data.
	;
		movdw	bxdi, ds:[si].ICA_data.handle
		call	HugeLMemLock		; ax <- segment address

		mov_tr	es, ax
		mov	di, es:[di]		; esdi <- Data
		add	di, ds:[si].ICA_dataOffset

	;
	; Get the Control byte
	;
		call	IUGetControlByte	; al <- control byte
	
endif
	;
	; Check to see if this is an acknowlegment of 
	; the last request made.
	;
		mov	bl, al
		andnf	bl, mask IICB_OPCODE

		mov	di, ds:[si]
;;		add	di, ds:[di].IasServerFsm_offset

		cmp	bl, ds:[di].ISFI_lastRequest
		jz	consume
	
	;
	; Check to see if this is an acknowlegment of our response
	;
		test	al, mask IICB_ACK
		; !* Need a warning here
		jz	consume

		test	al, mask IICB_LAST
		jnz	consume

consume:
		call	IUFreeDataArgs

		.leave
		ret
ISAReturningReceiveAck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAWaitingDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_Data.indication in the R-Waiting state.

CALLED BY:	(INTERNAL) ISFLmDataIndication
PASS:		ds:si	= IasServerFsm object
		ds:di	= IasServerFsm instance data
		cx:dx	= IrlmpDataArgs
		bp	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAWaitingDataIndication	proc	near
		class	IasServerFsmClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	;
	; Check if it's an ack.  If it is then get rid of it.
	;
		call	IUGetControlByte	; al <- ctrl byte
		test	al, mask IICB_ACK
		jz	saveData

		call	IUFreeDataArgs	
		jmp	exit

	;
	; Send this sucker to the R-WaitActive State to deal with.
	; But first, let's create a chunk array to keep track
	; of the packets.
	;
saveData:
	;
	; Go directly to the WaitActive state
	;
		mov	ds:[di].ISFI_state, ISFS_WAIT_ACTIVE
		call	ISAWaitActiveDataIndication

exit:
		.leave
		ret
ISAWaitingDataIndication	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAWaitActiveDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Got a LM_data.indication while in the wait-active state.

CALLED BY:	(INTERNAL) ISAWaitingDataIndication
PASS:		ds:si	= Ias Server FSM
		ds:di	= Ias Server FSM instance data
		cx:dx 	= IrlmpDataArgs
		bp	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/14/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAWaitActiveDataIndication	proc	near
		class	IasServerFsmClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	;
	; Check to see if this is a single packet.
	;
		call	IUGetControlByte	; al <- ctrl byte
		test	al, mask IICB_LAST
		jnz	gotLastPacket
	;
	; Add the packet to our chunk array.  Right now, we're not
	; handling multiple packet.
	;
	; XXX not supported yet
	; jmp	freeAndExit
	;
	; XXX not currently supported

	;
	; We have to create a packet array so to hold all the packets.
	;
		push	si				; lptr to self
		call	ISACreatePacketChunkArray	; ds may have changed
		jc	freeAndExit
		call	ISADataPacketChunkArrayAppend
		jc	freeAndExit

		mov	bx, si
		pop	si
		mov	di, ds:[si]		; ds:di <- instance data
		mov	ds:[di].ISFI_packetList, bx	; save chunk array lptr

	;
	; Change the state we're in now. 
	;
		mov	ds:[di].ISFI_state, ISFS_RECEIVING
	;
	; Send an ack for this packet received.
	; pass	bp	= client handle
	; 	*ds:si	= IasServerFsm object
	; 	al	= opcode
	;
		andnf	al, mask IICB_OPCODE
		mov	ds:[di].ISFI_lastRequest, al	; remember the op code
		call	ISAReturnAck
		
exit:
		.leave
		ret
gotLastPacket:
		mov	ds:[di].ISFI_state, ISFS_EXECUTE
		call	ISAExecuteCommand
		jmp	exit
	;
	; Error, so free the data and go off on our merry way.
	;
freeAndExit:
		call	IUFreeDataArgs
		jmp	exit
		
ISAWaitActiveDataIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAExecuteCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decode the packets and execute the command

CALLED BY:	(INTERNAL) ISAReceivingDataIndication,
		ISAWaitActiveDataIndication
PASS:		*ds:si	= Ias Server Fsm object
		ds:di	= Ias Server Fsm instance data
		cx:dx	= IrlmpDataArgs
		bp	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Find out what kind of packet it is.
	- We only handle GetValueByClass currently
	- If the op code is not supported, then exit
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAExecuteCommand	proc	near
		class	IasServerFsmClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;Get the OP code.
	;		
		call	IUGetControlByte	; al <- control byte
		andnf	al, mask IICB_OPCODE	; al <- opcode
	;
	; If the opcode is not a GetValueByClass, then we have to
	; return that the function is unsupported.
	;
		cmp	al, IIOC_GET_VALUE_BY_CLASS
		jnz	unsupported

	;
	; OK, it is a get value by class.
	;
		call	ISAGetValueByClass

done:
	;
	; Free the data args.  Free anything in our packet list
	;
		call	ISAFreePacketList
		call	IUFreeDataArgs

	;
	; Go to our new state.
	;
		mov	dx, ISFS_WAITING
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_ISF_CHANGE_STATE
		call	ObjMessage
		
		.leave
		ret

unsupported:
	;
	; The command is unsupported.  Insert the control byte
	;
		push	cx, dx
		mov	bp, FALSE		; write byte
		mov_tr	dl, al
		mov	cx, IIF_iasControlByte
		mov	ax, MSG_ISF_INSERT_DATA
		call	ObjCallInstanceNoLock
		
		mov	bp, FALSE		; write byte
		mov	dx, IGVBCRC_IRLMP_ERROR
		mov	ax, MSG_ISF_SEND_BYTE_OR_WORD
		call	ObjCallInstanceNoLock

		mov	ax, MSG_ISF_FLUSH_DATA
		call	ObjCallInstanceNoLock
		pop	cx, dx
		jmp	done
		
ISAExecuteCommand	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAReceivingDataIndication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	LM_data.indication while in the receiving state.

CALLED BY:	(INTERNAL) ISFLmDataIndication
PASS:		*ds:si	= IasServerFsm object
		ds:di	= IasServerFsm instance data
		cx:dx	= IrlmpDataArgs
		bp	= client handle		
RETURN:		nothing
DESTROYED:	nothing (ds may have changed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 9/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAReceivingDataIndication	proc	near
		class	IasServerFsmClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter

	;
	; Get the control byte and see if the packet is for
	; the op code we're expecting. If for some reason it's
	; an ack, also ignore it.
	;
		call	IUGetControlByte	; al <- ctrl byte
		mov	bl, al
		test	bl, mask IICB_ACK
		jnz	freeArgs
		
		andnf	bl, mask IICB_OPCODE	; bl <- opcode
		cmp	ds:[di].ISFI_lastRequest, bl
EC <		WARNING_NZ	IRLMP_IAS_RECEIVED_PACKET_FOR_DIFFERENT_OPCODE>
		jnz	freeArgs
	;
	; Check if it's the last frame.  If it is, let's execute the
	; sucker.
	;
		test	al, mask IICB_LAST
		jnz	gotLastPacket
	;
	; Send an ack for this packet received.
	; pass	bp	= client handle
	; 	*ds:si	= IasServerFsm object
	; 	al	= opcode
	;
		mov_tr	al, bl			; al <- op code
		call	ISAReturnAck
	;
	; It's another packet.  Let's add it to our set.
	;
		mov	si, ds:[di].ISFI_packetList
		call	ISADataPacketChunkArrayAppend
		jc	freeArgs
		jmp	exit
		
gotLastPacket:
		mov	ds:[di].ISFI_state, ISFS_EXECUTE
		call	ISAExecuteCommand

exit:
		.leave
		ret

freeArgs:
		call	IUFreeDataArgs
		jmp	exit
		
		
ISAReceivingDataIndication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAGetValueByClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We  have a get value by class packet.  Let's do it.


CALLED BY:	(INTERNAL) ISAExecuteCommand
PASS:		ds:si	= IasServerClass
		cx:dx	= IrlmpDataArgs
		bp	= client handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/ 1/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAGetValueByClass	proc	near
pself		local	dword		push ds, si
multiPacket	local	BooleanWord
;
; This is either the mem handle to the buffer we create, of the
; HugeLMem block
memHandle	local	hptr				
		class	IasServerFsmClass
		uses	ax,bx,cx,dx,si,di,bp,ds,es
		.enter

		Assert	objectPtr	dssi, IasServerFsmClass
		Assert	fptr		cxdx
		
	;
	; See if there's a packet array.  If there is, then
	; we need to create a data buffer
	;
		mov	di, ds:[si]
		tst	ds:[di].ISFI_packetList
		jz	singlePacket
		call	ISAMakeDataBuffer	; es:di <- data buffer
						; bx <- handle of block
		mov	ss:multiPacket, BW_TRUE
		mov	ss:memHandle, bx
		jmp	getValueCall
	;
	; Setup the call to our database to see if we can find it.
	;
singlePacket:
		movdw	dsdi, cxdx
		movdw	dxax, ds:[di].IDA_data		; ^ldx:ax <- data
		mov	si, ds:[di].IDA_dataOffset

		movdw	bxdi, dxax			; ^lbx:di <- data
		call	HugeLMemLock			; ax <- segment
		mov	ss:memHandle, bx
		mov_tr	ds, ax
		mov	di, ds:[di]		; ds:di <- begining of data
		add	di, si			; add offset
		inc	di			; go past control byte
		mov	ss:multiPacket, BW_FALSE
	;
	; PASS:
	; ES:DI points to our data.  It should be in the format of
	; 8 bit unsigned integer (class name length)
	; "Length" octets - (class name)
	; 8 bit unsigned integer (attribute name length)
	; "Length" octets - (attribute name)
	;
		segmov	es, ds			; es:di <- search params
		movdw	dssi, ss:pself		; *ds:si <- server fsm 
getValueCall:
		call	IrdbGetValueByClass

	;
	; All the data should be ready to go. Lets get this
	; thing on its way
	;
		mov	ax, MSG_ISF_FLUSH_DATA
		call	ObjCallInstanceNoLock
	;
	; Change state back to Waiting
	;
		mov	dx, ISFS_WAITING
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, MSG_ISF_CHANGE_STATE
		call	ObjMessage
	;
	; Clean up.  Either unlock the packet that we locked.
	; Or free up the buffer that we created.
	;
		mov	bx, ss:memHandle
		cmp	ss:multiPacket, BW_FALSE
		jz	singlePacketUnlock

		call	MemFree
		
		jmp	exit
		
singlePacketUnlock:
		call	HugeLMemUnlock
		
exit:
		.leave
		ret
ISAGetValueByClass	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAReturnAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return an acknowledgement of packets received.

CALLED BY:	(INTERNAL) ISAReceivingDataIndication,
		ISAWaitActiveDataIndication
PASS:		*ds:si	= IasServerFsm object
		bp	= client handle
		al	= OpCode
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAReturnAck	proc	near
		uses	ax,bx,cx,dx,di,bp
		.enter

		Assert	objectPtr	dssi, IasServerFsmClass
		Assert	etype		al, IrlmpIasOpCode		

	;
	; Save the parameters for later use
	;
		pushdw	dssi				; save object ptr
		push	bp				; save client handle
		mov_tr	bl, al
	;
	; Create the frame of data that we'll send
	;
		mov	cx, size IrlmpIasFrame
		call	UtilsAllocHugeLMemDataLocked	; ^ldx:ax <- data
							; ds:di = data
	;
	; Add the ack bit to the op code
	;
		ornf	bl, mask IICB_ACK		; add the ack bit

		mov	ds:[di].IIF_iasControlByte, bl
	;
	; Unlock the block, we won't write anything more to it.
	;
		mov	bx, dx				; bx <- handle of hlmem
		call	HugeLMemUnlock
	;
	; Restore some of the parameters
	;
		pop	bx				; client handle
		popdw	dssi
	;
	; Create a buffer to send the IrlmpDataArgs
	;
		sub	sp, size IrlmpDataArgs
		mov	bp, sp
		movdw	ss:[bp].IDA_data, dxax
		mov	ss:[bp].IDA_dataSize, size IrlmpIasControlByte
		mov	ss:[bp].IDA_dataOffset, IIF_iasControlByte
	;
	; Send the buffer off
	;
		mov	cx, ss
		mov	dx, bp			; cx:dx <- IrlmpDataArgs
		mov	bp, bx			; bp <- client handle
		mov	ax, MSG_ISF_CALL_RESPONSE
		call	ObjCallInstanceNoLock

		add	sp, size IrlmpDataArgs
		
		.leave
		ret
ISAReturnAck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISACreatePacketChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a chunk array so that we can keep a list of packets
		that we receive

CALLED BY:	(INTERNAL) ISAWaitActiveDataIndication
PASS:		ds	= segment to put chunk array in
RETURN:		*ds:si	= Chunk array
DESTROYED:	nothing
SIDE EFFECTS:	ds may have changed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	12/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISACreatePacketChunkArray	proc	near
		uses	ax,bx,cx
		.enter
	;
	; Create a Chunk Array to hold all fptrs of data
	; that we will get.
	;
		mov	bx, size IrlmpDataArgs	;  element size
		clr	si, ax, cx		; alloc chunk handle
						; No ObjChunkFlags
						; default ChunkArrayHeader

		call	ChunkArrayCreate	; *ds:si <- chunk array

		.leave
		ret
ISACreatePacketChunkArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISADataPacketChunkArrayAppend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the packet to the chunk array.

CALLED BY:	(INTERNAL) ISAReceivingDataIndication,
		ISAWaitActiveDataIndication
PASS:		*ds:si  = Data Packet Chunk Array
		cx:dx	= IrlmpDataArgs
RETURN:		nothing
DESTROYED:	nothing (ds may of changed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	1/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISADataPacketChunkArrayAppend	proc	near
		class IasServerFsmClass
		uses	cx,dx,si,di,es
		.enter

		call	ChunkArrayAppend	; ds:di <- chunk array
EC <		WARNING_C IRLMP_IAS_LOST_DATA_DUE_TO_ERROR		>
		jc	exit

		segmov	es, ds			; es:di <- dest
		movdw	dssi, cxdx		; ds:si <- src
		mov	cx, size IrlmpDataArgs	
		rep	movsb			; copy the data

		segmov	ds, es
exit:
		.leave
		ret
ISADataPacketChunkArrayAppend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAFreePacketList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we have a packet list.
		If we do, then free it.

CALLED BY:	(INTERNAL) ISAExecuteCommand
PASS:		ds:di	= IasServerFsm instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAFreePacketList	proc	near
		class	IasServerFsmClass
		uses	ax
		.enter

		mov	ax, ds:[di].ISFI_packetList
		tst	ax
		jz	done

		push	cx, dx, bx, di, si
		
		mov	si, ax			; *ds:si <- chunk array
		mov	bx, SEGMENT_CS
		mov	di, offset ISAFreePacketListCallback
		call	ChunkArrayEnum		; cx, dx trashed

		pop	cx, dx, bx, di, si	
		
		call	LMemFree
done:
		.leave
		ret
ISAFreePacketList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAFreePacketListCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loop through the packet list and release all
		the IrlmpDataArgs that they hold.

CALLED BY:	(INTERNAL) ISAFreePacketList via ChunkArrayEnum
PASS:		ds:di	= Chunk array element
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAFreePacketListCallback	proc	far
		.enter

		movdw	cxdx, dsdi
		call	IUFreeDataArgs
		
		.leave
		ret
ISAFreePacketListCallback	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAMakeDataBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make one big buffer to combine all the chunk
		packets that we got.  Should only be called when you
		have a packet list.  This routine won't do anything if
		there's no packet list.

CALLED BY:	(INTERNAL) ISAGetValueByClass
PASS:		*ds:si	= IasServerFsm object
		cx:dx	= IrlmpDataArgs (of last packet)
RETURN:		bx	= handle of buffer
		es:di	= buffer
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAMakeDataBuffer	proc	near
;;pself		local	dword	push	ds, si
dataArgs	local	dword	push	cx, dx		
		class	IasServerFsmClass
		uses	cx,dx,si,bp,ds
		.enter
	;
	; Do we have a packet array.  If not, then just use
	; the last packet.
	;
		mov	di, ds:[si]
		mov	si, ds:[di].ISFI_packetList
		tst	si
EC <		ERROR_Z	-1						>
NEC <		jz	done						>
	;
	; Count the number of bytes we need to read.
	;
		mov	bx, SEGMENT_CS
		mov	di, offset ISAPacketListFindSizeCallback
		clr	ax
		call	ChunkArrayEnum			; ax <- data size
	;
	; Add the size of the last packet.
	;
		les	di, ss:dataArgs
		add	ax, es:[di].IDA_dataSize
		sub	ax, size IrlmpIasControlByte	; cx <- total size
	;
	; Now create a buffer that we can use.
	;
		mov	cx, (mask HAF_LOCK shl 8)
		call	MemAlloc			; ax <- block address
							; bx <- block handle
		jc	done
	; 
	; Now copy all the data into the buffer.
	;
		push	bx
		mov	bx, SEGMENT_CS
		mov	di, offset ISAPacketListCopyData
		mov_tr	es, ax
		clr	dx				; es:dx <- buffer
		call	ChunkArrayEnum
	;
	; Copy the last but of data from the current packet.
	;
		push	bp
		lds	si, ss:dataArgs
		movdw	bxdi, ds:[si].IDA_data
		mov	cx, ds:[si].IDA_dataSize
		sub	cx, size IrlmpIasControlByte	; cx <- data size
		mov	bp, ds:[si].IDA_dataOffset

		call	HugeLMemLock		; ax <- segment

		mov_tr	ds, ax
		mov	si, ds:[di]		; ds:di <- raw data
		add	si, bp
		add	si, size IrlmpIasControlByte

		mov	di, dx			; es:di <- buffer
		rep	movsb

		pop	bp
		pop	bx
		clr	di
done:
		lahf	
		.leave
		sahf
		ret
ISAMakeDataBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAPacketListFindSizeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count how big the packet should be.

CALLED BY:	(INTERNAL) ISAMakeDataBuffer (via ChunkArrayEnum)
PASS:		ax	= 0
		ds:di	= Chunk array element (IrlmpDataArgs
RETURN:		ax	= the current buffer count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAPacketListFindSizeCallback	proc	far
		uses	cx
		.enter

		mov	cx, ds:[di].IDA_dataSize
		sub	cx, size IrlmpIasControlByte

		add	ax, cx

		.leave
		ret
ISAPacketListFindSizeCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISAPacketListCopyData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	(INTERNAL) ISAMakeDataBuffer (via ChunkArrayEnum)
PASS:		ds:di	= Chunk Array element
		es:dx	= where to write data
RETURN:		dx	= updated to next place to write
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISAPacketListCopyData	proc	far
		uses	ax, cx, ds
		.enter

		mov	cx, ds:[di].IDA_dataSize
		sub	cx, size IrlmpIasControlByte

		movdw	bxsi, ds:[di].IDA_data
		call	HugeLMemLock		; ax = segment

		mov	di, ds:[di].IDA_dataOffset
		mov_tr	ds, ax
		mov	si, ds:[si]		; ds:si <- raw data
		add	si, di
		add	si, size IrlmpIasControlByte	; ds:si <- data

		mov	di, dx			; es:di <- buffer
		rep	movsb

		mov	dx, di

		call	HugeLMemUnlock

		.leave
		ret
ISAPacketListCopyData	endp


IasCode	ends





