COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Serial/IR communication protocol
MODULE:		Control routines
FILE:		irlapControl.asm

AUTHOR:		Steve Jang, Oct 11, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/11/94   	Initial revision

DESCRIPTION:
	Routines and states that control IrLAP machine.

	$Id: irlapControl.asm,v 1.1 97/04/18 11:57:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IrlapConnectionCode	segment resource



if _SOCKET_INTERFACE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlapCleanUpDataTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cleans up all the data in output/input buffer

CALLED BY:	Socket link connection and disconnection routines
		IrlapSocketConnectIndication
		IrlapSocketDisconnectIndication

PASS:		ds	= station
RETURN:		nothing
DESTROYED:	nothing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlapCleanUpDataTransfer	proc	far
		uses	ax, bx, cx
		.enter
EC <		IrlapCheckStation ds					>
	;
	; Flush outgoing data request events
	;
		mov	bx, ds:IS_clientHandle
		call	IrlapNativeFlushDataRequests
	;
	; Reinitialize data packet being reassembled
	;
		clr	ax, cx
		xchgdw	axcx, ds:IS_seqPacket.IPA_packet
		tst	ax
		jz	done
		call	HugeLMemFree
done:	
		.leave
		ret
IrlapCleanUpDataTransfer	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DataRequestFLUSH_DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A data request to be discarded

CALLED BY:	IrlapCheckStateEvent
PASS:		ds	= segment offset
		es 	= dgroup
		ax	= event code
		cx	= data size
		dx:bp	= hugelmem handle for DataRequestParams
RETURN:		nothing
DESTROYED:	everything

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DataRequestFLUSH_DATA	proc	far
		.enter
EC <		WARNING FLUSHING_DATA_REQUEST				>
	;
	; Unpackage DataRequestParams
	;
		dec	ds:IS_pendingData
		dec	ds:IS_pendingConnectedData
		push	cx
		mov	ax, dx
		mov	cx, bp
		IrlapLockPacket	esdi, dxbp
		movdw	dxbp, es:[di].DRP_buffer
		mov	si, es:[di].DRP_dataOffset
if _SOCKET_INTERFACE
		mov	di, es:[di].DRP_seqInfo
endif
		IrlapUnlockPacket ax
		call	HugeLMemFree
		pop	cx
	;
	; parameters:
	;	dxbp = data buffer
	;	di   = seqInfo
	;	si   = dataOffset
	;	cx   = dataSize
	;
	; Free the packet if (seqInfo == dataSize)
	;
		cmp	si, cx
		jne	done
		movdw	axcx, dxbp
		call	HugeLMemFree
done:
		.leave
		ret
DataRequestFLUSH_DATA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopFlushResponseFLUSH_DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit FLUSH_DATA state

CALLED BY:	IrlapCheckStateMachine
PASS:		ds	= station
RETURN:		nothing
DESTROYED:	everything
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	10/11/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopFlushResponseFLUSH_DATA	proc	far
		uses	ax, ds
		.enter
EC <		WARNING FLUSH_DATA_REQUEST_END				>
	;
	; change state back to its original state
	;
		mov	ax, ds:IS_savedState
		mov	ds:IS_state, ax
		.leave
		ret
StopFlushResponseFLUSH_DATA	endp


IrlapConnectionCode	ends
