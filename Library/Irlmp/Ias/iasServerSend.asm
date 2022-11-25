COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	Geoworks Confidential

PROJECT:	GEOS
MODULE:		Irlmp
FILE:		iasServerSend.asm

AUTHOR:		Andy Chiu, Feb 11, 1996

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/11/96   	Initial revision


DESCRIPTION:
	These are methods that handle sending data back to who we
	are connected too.
		

	$Id: iasServerSend.asm,v 1.1 97/04/05 01:07:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IasCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFSetDataSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used when we don't want to start writing at the begining
		of the data stream.  For stuff like the argument count
		where we don't know what the value is until after
		writing some stuff.  So we move the pointer up
		so we can start writing data at a later point

CALLED BY:	MSG_ISF_SET_DATA_SIZE
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		cx	= size of the data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/19/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFSetDataSize		method dynamic IasServerFsmClass, 
					MSG_ISF_SET_DATA_SIZE
		.enter
	;
	; Check to see if we have an lmem to write the data too.
	;
		
		tst	ds:[di].ISFI_currentPacketOptr.handle
		jnz	writeSize
	;
	; We don't a buffer to write data.  So lets make it.
	;
		call	ISSCreateSendBuffer
		
writeSize:
		mov	ds:[di].ISFI_currentPacketSize, cx
		
		.leave
		ret
ISFSetDataSize	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFSendData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send some data to whoever we have a connection too.
		The data will get buffered, and be sent out either after
		a packet is full, or MSG_ISF_FLUSH_DATA is called


CALLED BY:	MSG_ISF_SEND_DATA
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		dx:bp	= Data to pass
		cx	= size of data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- check to see if we have a huge lmem locked down and ready to go
	- if we don't then create it
	- see if we have enough space to write the data.
	- if we don't then send the data off and create a new buffer
	- If we created a new buffer, write the new data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFSendData	method dynamic IasServerFsmClass, 
					MSG_ISF_SEND_DATA
		uses	ax, cx
		.enter

	;
	; Check to see if we have an lmem to write the data too.
	;
		
		tst	ds:[di].ISFI_currentPacketOptr.handle
		jnz	writeData

	;
	; We don't a buffer to write data.  So lets make it.
	;
		call	ISSCreateSendBuffer

	;
	; Check to see if we have the size to write the data.
	;
writeData:
		call	ISSCheckSendSize
		jc	exit
	;
	; If cx is positive, that means we have space to write the data
	;
	; XXX, no code write now to support multiple frames
	;
	;
		mov	si, di
		movdw	esdi, ds:[si].ISFI_currentPacket
		add	di, ds:[si].ISFI_currentPacketSize
		add	ds:[si].ISFI_currentPacketSize, cx
		movdw	dssi, dxbp
		rep	movsb

exit:
		.leave
		ret
ISFSendData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFFlushData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the data that we have flushed out to whoever we
		are connected too.

CALLED BY:	MSG_ISF_FLUSH_DATA
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFFlushData	method dynamic IasServerFsmClass, 
					MSG_ISF_FLUSH_DATA
		uses	ax, cx, dx, bp
		.enter
	;
	; See if there is any data that we have.  If not, then just
	; exit.
	; 
		tst	ds:[di].ISFI_currentPacketOptr.handle
EC <		WARNING_Z	IRLMP_IAS_FLUSH_WITH_NO_DATA		>
		jz	exit
	;
	; We have a packet to send.  Let's wrap up the sucker and
	; send it.  Since we're flushing it, it's the last packet.
	;
		push	si
		movdw	dxax, ds:[di].ISFI_currentPacketOptr
		mov	si, IIF_iasControlByte
		call	IUMakeLastNoAckFrame
		pop	si
	;
	; Unlock the block since we're not going to be writing anymore
	; data to it.
	;
		mov	bx, dx
		call	HugeLMemUnlock
	;
	; Lets get the endpoint and send this data on its way
	;
		sub	sp, size IrlmpDataArgs
		mov	bp, sp
		mov	cx, size IrlmpFrameHeader
		mov	ax, ds:[di].ISFI_currentPacketSize
		sub	ax, cx			; ax <- size of data
		mov	ss:[bp].IDA_dataSize, ax
		mov	ss:[bp].IDA_dataOffset, cx
		clrdw	cxdx
		xchgdw	cxdx, ds:[di].ISFI_currentPacketOptr
		movdw	ss:[bp].IDA_data, cxdx
		
		movdw	cxdx, ssbp
		mov	bp, ds:[di].ISFI_serverHandle
		mov	ax, MSG_ISF_CALL_RESPONSE
		call	ObjCallInstanceNoLock

		add	sp, size IrlmpDataArgs

exit:
		.leave
		ret
ISFFlushData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFInsertData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert some data into the stream.  Used to write the
		control byte or a count of the number of parameters.
		The buffer must already be big enough. 

CALLED BY:	MSG_ISF_INSERT_DATA
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		cx	= offset of data
		dx	= data to write
		bp	= FALSE if writing byte
			= TRUE if writing word
RETURN:		carry set if it could not insert
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/12/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFInsertData	method dynamic IasServerFsmClass, 
					MSG_ISF_INSERT_DATA
		uses	ax, cx, dx, bp
		.enter
	;
	; Check to see if we have an lmem to write the data too.
	;
		
		tst	ds:[di].ISFI_currentPacketOptr.handle
		jnz	checkSize

	;
	; We don't have a buffer to write data.  So lets make it.
	;
		call	ISSCreateSendBuffer
checkSize:
	;
	; See if the buffer is big enough.
	;
		call	ISSCheckSendSize
		jc	exit
	;
	; Insert the data into the buffer.
	;
		les	si, ds:[di].ISFI_currentPacket
		add	si, cx
		cmp	bp, FALSE
		jnz	writeWord

		mov	{byte} es:[si], dl
		jmp	exitClear

writeWord:
		mov	{word} es:[si], dx

exitClear:
		clc
exit:
		.leave
		ret

ISFInsertData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISFSendByteOrWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write one byte to the string.  This routine
		is useful for just writing something quick,
		without having to pass a buffer

CALLED BY:	MSG_ISF_SEND_BYTE_OR_WORD
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		ds:bx	= IasServerFsmClass object (same as *ds:si)
		es 	= segment of IasServerFsmClass
		ax	= message #
		dx	= data to write
		bp	= FALSE if writing byte
			= TRUE if writing word
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISFSendByteOrWord	method dynamic IasServerFsmClass, 
					MSG_ISF_SEND_BYTE_OR_WORD
		uses	ax, cx, dx, bp
		.enter

	;
	; Check to see if we have an lmem to write the data too.
	;
		
		tst	ds:[di].ISFI_currentPacketOptr.handle
		jnz	writeData

	;
	; We don't a buffer to write data.  So lets make it.
	;
		call	ISSCreateSendBuffer

	;
	; Check to see if we have the size to write the data.
	;
writeData:
		clr	cx
		inc	cx			; cx <- one
		cmp	bp, FALSE
		jz	checkSize

		inc	cx			; cx <- two
EC <		cmp	bp, TRUE					>
EC <		ERROR_NZ -1						>
checkSize:
		call	ISSCheckSendSize
		jc	exit
	;
	; We have space to write the data.
	;
	; XXX, no code write now to support multiple frames
	;
	;
		mov	si, di
		movdw	esdi, ds:[si].ISFI_currentPacket
		add	di, ds:[si].ISFI_currentPacketSize
		add	ds:[si].ISFI_currentPacketSize, cx
		cmp	bp, FALSE
		jnz	writeWord

		mov	es:[di], dl
		jmp	exit
		
writeWord:
		mov	es:[di], dx

exit:
		.leave
		ret
ISFSendByteOrWord	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISSCreateSendBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a HugeLMem that we can use to send data.

CALLED BY:	ISFSendData, ISFInsertData
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
RETURN:		ISFI_currentPackeOptr and ISFI_currentPacket are set.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISSCreateSendBuffer	proc	near
		class	IasServerFsmClass
		uses	ax,cx,dx,si,bp
		.enter

	;
	; Create a HugeLMemBlock so that we can write our return values
	; into it.  We don't really know how big it should be, so
	; we use the max packet size that we can send.  We'll realloc
	; it later to make it smaller.  Or add another packet
	; if we need it.
	;
		pushdw	dsdi			; save fptr to instance data
		clr	ax
		mov	al, ds:[di].ISFI_frameSize
		mov	al, ds:[di].ISFI_frameSize
		call	IrlmpGetPacketSize
		call	UtilsAllocHugeLMemDataLocked
			; ^ldx:ax = HugeLMem data block
			; ds:di   = data block
	;
	; Save the optr and fptr of the data in our instance data.
	;
		movdw	cxsi, dsdi
		popdw	dsdi

		movdw	ds:[di].ISFI_currentPacketOptr, dxax
		movdw	ds:[di].ISFI_currentPacket, cxsi
	;
	; The size of the data should be after the control byte in
	; an IrlmpIasFrame.
	;
		mov	ds:[di].ISFI_currentPacketSize, IIF_iasArgs

		.leave
		ret
ISSCreateSendBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ISSCheckSendSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the size we're going to add to the buffer
		will fit in how much space we allocated

CALLED BY:	
PASS:		*ds:si	= IasServerFsmClass object
		ds:di	= IasServerFsmClass instance data
		cx	= number of bytes to add
RETURN:		carry set if error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISSCheckSendSize	proc	near
		class	IasServerFsmClass
		uses	ax,bx,cx
		.enter
	;
	; Find out what the current packet size is and compare it
	; with how much space we have left.
	;
		clr	ax
		mov	al, ds:[di].ISFI_frameSize
		mov	bx, cx
		call	IrlmpGetPacketSize	; cx <- packet size

		sub	cx, ds:[di].ISFI_currentPacketSize
		sub	cx, bx			; carry set if bx > cx

		.leave
		ret
ISSCheckSendSize	endp



IasCode	ends

