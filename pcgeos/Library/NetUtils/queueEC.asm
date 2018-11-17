COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		queueEC.asm

AUTHOR:		Steve Jang, Apr 12, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/12/94   	Initial revision


DESCRIPTION:
	EC code for queue mechanism
		

	$Id: queueEC.asm,v 1.1 97/04/05 01:25:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;				EC Code
; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

QueueECCode		segment	resource

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateQueueCreateParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine checks the parameters to QueueCreate to make
		sure they are reasonable

CALLED BY:	QueueLMemCreate
PASS:		ax = entry size
		cl = initial size
		dx = max length
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	8/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateQueueCreateParams	proc	far
		uses	ax,bx,cx,dx
		.enter
	;
	; compare max queue length and initial queue length
	;
		and	cx, 0x00ff
		cmp	cx, dx
		ERROR_A	ERROR_INITIAL_LENGTH_LARGER_THAN_MAX
	;
	; check max queue length
	;
		cmp	dx, QUEUE_MAX_LENGTH
		ERROR_A	ERROR_MAX_QUEUE_LENGTH_BEYOND_REASON
		cmp	dx, QUEUE_LOW_MAX_LENGTH
		WARNING_A WARNING_MAX_QUEUE_LENGTH_TOO_BIG
	;
	; check max queue length x element size
	;
		mul	dx
		tst	dx
		ERROR_NZ ERROR_MAX_LEN_BY_ELT_SIZE_BEYOND_REASON
		cmp	ax, QUEUE_LOW_MAX_SIZE
		WARNING_A WARNING_MAX_LEN_BY_ELT_SIZE_TOO_BIG

		.leave
		ret
ECValidateQueueCreateParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateQueueDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the given queue.

CALLED BY:	QueueEnqueueStart/End, QueueDequeueStart/End
PASS:		*ds:si	= queue
		ds:si = queue for ECValidateQueueDSSIptr
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	1. Chunk must be in LMem heap and valid
	2. (totalSize - size QueueStruct + 1) mod eltSize should be 0
	3. front and end should be within range of [offset buffer - totalSize]
	4. All the semaphores should be valid

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateQueueDSSIptr	proc	far
		push	si
		GOTO	ECValidateQueueDSSICommon, si
ECValidateQueueDSSIptr	endp		

ECValidateQueueDSSI	proc	far
		push	si
		mov	si, ds:[si]
		FALL_THRU ECValidateQueueDSSICommon, si
ECValidateQueueDSSI	endp		

ECValidateQueueDSSICommon proc	far
		uses	ax,bx,cx,dx,si,ds
		.enter
		call	ECCheckLMemChunk
	;
	; checking front and end pointers
	;
		mov	ax, ds:[si].QS_totalSize
		mov	bx, offset QS_buffer
		
		mov	dx, ds:[si].QS_front
		cmp	dx, ax
		ERROR_AE QUEUE_IS_CORRUPTED
		cmp	dx, bx
		ERROR_B	QUEUE_IS_CORRUPTED

		mov	dx, ds:[si].QS_end
		cmp	dx, ax
		ERROR_AE QUEUE_IS_CORRUPTED
		cmp	dx, bx
		ERROR_B	QUEUE_IS_CORRUPTED
	;
	; checking total size and elt size
	; ax = total size
	;
		sub	ax, size QueueStruct
		push	ax
		clr	dx
		mov	bx, ds:[si].QS_eltSize
		div	bx
		tst	dx
		ERROR_NZ QUEUE_IS_CORRUPTED
		pop	bx
		mov	ax, ds:[si].QS_numEnqueued
		mov	cx, ds:[si].QS_eltSize
		mul	cx
		cmp	bx, ax
		ERROR_B	QUEUE_IS_CORRUPTED
		.leave
		FALL_THRU_POP	si
		ret
ECValidateQueueDSSICommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckLegalEndOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks whether someone already called a EnqueueStart or
		DequeueStart operation.

CALLED BY:	QueueEnqueueEnd, QueueDequeueEnd,
		QueueEnqueueAbort, QueueDequeueAbort
PASS:		*ds:si	= queue
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SJ	4/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckLegalEndOperation	proc	far
		uses	ax,bx,cx,si
		.enter
		mov	si, ds:[si]
		mov	bx, ds:[si].QS_syncSem
		clr	cx
		call	ThreadPTimedSem
		cmp	ax, SE_TIMEOUT
		ERROR_NE END_QUEUE_OPERATION_WITHOUT_STARTING_ONE
		.leave
		ret
ECCheckLegalEndOperation	endp

endif

QueueECCode		ends
