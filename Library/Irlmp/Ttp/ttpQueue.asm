COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Irlmp Library
MODULE:		TinyTP
FILE:		ttpQueue.asm

AUTHOR:		Chung Liu, Dec 19, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/19/95   	Initial revision


DESCRIPTION:
	Transmit and Receive queues in TinyTP
		

	$Id: ttpQueue.asm,v 1.1 97/04/05 01:07:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPTxQueueAppendTail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the data request to the end of the transmit queue.

CALLED BY:	TTPDataRequest
PASS:		ds:di	= IrlmpEndpoint
		cx:dx	= IrlmpDataArgs
		al	= TTPQueueEntryType
RETURN:		ds:di	= IrlmpEndpoint (ds may have moved)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPTxQueueAppendTail	proc	near
	uses	si,es,di,cx
	.enter
	mov	si, ds:[di].IE_txQueue		;*ds:si = txQueue array	
	call	ChunkArrayAppend		;ds:di = new TTPQueueEntry

	segmov	es, ds				;es:di = TTPQueueEntry
	movdw	dssi, cxdx			;ds:si = IrlmpDataArgs
	mov	es:[di].TQE_type, al
	mov	cx, size IrlmpDataArgs
	rep	movsb

	segmov	ds, es				;return segment of 
						;  IrlmpEndpoint (may have 
						;  moved.)
	
	.leave
	ret
TTPTxQueueAppendTail	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPTxQueueDeQueueHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pop off the head of TxQueue

CALLED BY:	TTPCheckTxQueue
PASS:		ds:di	= IrlmpEndpoint 
		cx:dx	= TTPQueueEntry buffer
RETURN:		carry clear if okay:
			cx:dx	= TTPQueueEntry filled in with entry pop'ed
				off the head of the queue.
		carry set if queue is empty

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPTxQueueDeQueueHead	proc	near
	uses	si,ax,cx
	.enter
	;
	; First check if queue is empty.
	;
	push	cx
	mov	si, ds:[di].IE_txQueue		;*ds:si = txQueue array
	call	ChunkArrayGetCount		;cx = count
	jcxz	popAndExitCarrySet
	pop	cx				;cx:dx = TTPQueueEntry 
	;
	; Get the first element
	;
	mov	ax, 0		
	call	ChunkArrayGetElement		;cx:dx = filled in.
	;
	; Delete the first element
	;
	clr	ax				;start at element 0
	mov	cx, 1				;delete only one.
	call	ChunkArrayDeleteRange

	clc
exit:
	.leave
	ret

popAndExitCarrySet:
	pop	cx
	stc
	jmp	exit
TTPTxQueueDeQueueHead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPTxQueueGetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of entries in the transmit queue.

CALLED BY:	TTPDataRequest, TTPDisconnectRequest
PASS:		ds:di	= IrlmpEndpoint
RETURN:		ax	= number of entries in queue
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPTxQueueGetCount	proc	near
	uses	si, cx
	.enter
	mov	si, ds:[di].IE_txQueue		;*ds:si = queue array
	call	ChunkArrayGetCount		
	mov	ax, cx			;return number of elements in ax
	.leave
	ret
TTPTxQueueGetCount	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPTxQueueFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush the transmit queue.

CALLED BY:	TTPDisconnectRequest
PASS:		ds:di	= IrlmpEndpoint
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPTxQueueFlush	proc	near
	uses	si, bx, di
	.enter
	mov	si, ds:[di].IE_txQueue		;*ds:si = queue array
	mov	bx, cs
	mov	di, offset TTPTxQueueFlushCallback
	call	ChunkArrayEnum

	call	ChunkArrayZero
	.leave
	ret
TTPTxQueueFlush	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTPTxQueueFlushCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback to free HugeLMem buffers in each queue element.

CALLED BY:	TTPTxQueueFlush (via ChunkArrayEnum)
PASS:		*ds:si	= array
		ds:di	= TTPQueueEntry
RETURN:		carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	12/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTPTxQueueFlushCallback	proc	far
	uses	ax,cx
	.enter
	movdw	axcx, ds:[di].TQE_data.IDA_data
	call	HugeLMemFree
	clc
	.leave
	ret
TTPTxQueueFlushCallback	endp
