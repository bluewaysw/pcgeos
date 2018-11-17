COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Stream Driver
FILE:		stream.asm

AUTHOR:		Adam de Boor, Jan  9, 1990

ROUTINES:
	Name			Description
	----			-----------
	StreamStrategy		Main entry point
	StreamNotify		Send notification
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/ 9/90		Initial revision


DESCRIPTION:
	Stream driver code.
		

	$Id: stream.asm,v 1.1 97/04/18 11:46:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			  System Definition
;------------------------------------------------------------------------------
_Driver		= 1

	.ioenable		;  We're running in supervisor mode...

;------------------------------------------------------------------------------
;			    Include Files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include	geode.def
include	resource.def
include	object.def
include	ec.def
include	library.def
include thread.def
include driver.def

include	Internal/semInt.def
include Internal/interrup.def
DefDriver	Internal/streamDr.def	; Our external definitions
DefDriver	Internal/strDrInt.def	; Our "internal" definitions

;------------------------------------------------------------------------------
;			    Useful Macros
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There are certain places in this code where assumptions
		have been made about data structures in order to generate
		more efficient code. This macro will verify these assumptions
		and produce an error message if they are invalid.

PASS:		expression that must evaluate true.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckHack	macro	expr
		local	msg
if not (expr)
ifb @CurProc
msg	equ	<expr must be true for stream driver to work>
else
msg	catstr <expr must be true for >, @CurProc, < to work>
endif
ErrMessage	%msg
endif
		endm

;------------------------------------------------------------------------------
;			     Error Codes
;------------------------------------------------------------------------------
INVALID_STREAM_FUNCTION					enum FatalErrors
STREAM_INVALID						enum FatalErrors
STREAM_STATE_INVALID					enum FatalErrors
SOMEONE_IS_BLOCKED_ON_STREAM				enum FatalErrors
STREAM_INVALID_SIDE					enum FatalErrors
STREAM_INVALID_BLOCK_FLAG				enum FatalErrors
STREAM_SET_NOTIFY_BAD_FLAGS				enum FatalErrors

STREAM_MAGIC	=	0xadeb		; Magic number placed in otherInfo
					;  field of a stream block for EC


;------------------------------------------------------------------------------
;		       Driver Information Table
;------------------------------------------------------------------------------
idata		segment

DriverTable	DriverInfoStruct <
	StreamStrategy, mask DA_CHARACTER, DRIVER_TYPE_STREAM
>
public	DriverTable

idata		ends

Resident	segment	resource


DefFunction	macro	funcCode, routine
if ($-streamFunctions) ne funcCode
	ErrMessage <routine not in proper slot for funcCode>
endif
		nptr	routine
		endm

streamFunctions	label	nptr
DefFunction	DR_INIT,			StreamDoNothing
DefFunction	DR_EXIT,			StreamDoNothing
DefFunction	DR_SUSPEND,			StreamDoNothing
DefFunction	DR_UNSUSPEND,			StreamDoNothing
DefFunction	DR_STREAM_GET_DEVICE_MAP,	StreamGetDeviceMap
DefFunction	DR_STREAM_CREATE,		StreamCreate
DefFunction	DR_STREAM_DESTROY,		StreamDestroy
DefFunction	DR_STREAM_SET_NOTIFY,		StreamSetNotify
DefFunction	DR_STREAM_GET_ERROR,		StreamGetError
DefFunction	DR_STREAM_SET_ERROR,		StreamSetError
DefFunction	DR_STREAM_FLUSH,		StreamFlush
DefFunction	DR_STREAM_SET_THRESHOLD,	StreamSetThreshold
DefFunction	DR_STREAM_READ,			StreamRead
DefFunction	DR_STREAM_READ_BYTE,		StreamReadByte
DefFunction	DR_STREAM_WRITE,		StreamWrite
DefFunction	DR_STREAM_WRITE_BYTE,		StreamWriteByte
DefFunction	DR_STREAM_QUERY,		StreamQuery


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Driver-level entry point to this driver

CALLED BY:	GLOBAL
PASS:		di	= function code (from StreamFunction/DriverFunction)
		bx	= stream token (except for DR_STREAM_CREATE)
		other parameters vary
RETURN:		carry set and AX = STREAM_CLOSING if stream is in the act
		of closing. ALL FUNCTIONS CAN RETURN THIS AND THE CALLER
		SHOULD BE PREPARED TO FIELD THIS OR EC CODE WILL ABORT
		AT SOME POINT AFTER THE STREAM IS FREED.
		If stream not closing, return value depends on function called
DESTROYED:	nothing here

PSEUDO CODE/STRATEGY:
	Preserve es to make life easier for driver routines.
	If error-checking and calling a function that actually receives a
		stream token, make sure it's ok.
	Call the function in question.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamStrategy	proc	far	uses es, ds
		.enter

EC <		cmp	di, StreamFunction				>
EC <		ERROR_AE INVALID_STREAM_FUNCTION			>
		cmp	di, DR_STREAM_CREATE
		jbe	noCheck

		;
		; lock down stream and make sure it doesn't
		; move.
		push	bx		; save original reference to stream

		push	ax			; save ax parameter
		call	MemLockFixedOrMovable	; lock down stream
		mov_tr	bx, ax			; bx <- new segment
		pop	ax			; restore ax parameter

EC <		call	StreamVerify					>
		push	ds		; Driver function might need it...
		mov	ds, bx
		;
		; See if the stream is in the process of being biffed. If
		; so, absolutely no operations on the stream are allowed.
		;
		test	ds:SD_state, mask SS_NUKING
		jnz	denied
		inc	ds:SD_useCount		; Increase count of resident
						;  threads
		pop	ds
noCheck:
		;
		; Call the indicated driver function (always returns stream
		; data in DS)
		;
		call	cs:streamFunctions[di]
		;
		; Exit the driver, dealing with waking up any waiting
		; stream-closer.
		;
		pushf

		cmp	di, DR_STREAM_CREATE
		jbe	exitNoUnlock

		cmp	di, DR_STREAM_DESTROY
		je	streamGone		; If was DESTROY, stream must
						;  be gone.


		call	SafePopf
		pop	bx		; restore original reference to stream

		pushf

		dec	ds:SD_useCount		; One more thread gone

		;
		;  Check for destroying the stream
		;	(flags saved over pop and Unlock)
		jnz	exit		; Not all absent, so can't
						;  close
		test	ds:SD_state, mask SS_NUKING or mask SS_LINGERING
		jnz	closing

exit:
		;
		; Unlock StreamData
		;  
		call	MemUnlockFixedOrMovable	; unlock the stream
exitNoUnlock:
		call	SafePopf
exitNoPopf:
done:
		.leave
		ret
denied:
	;
	; Recover passed DS and stream token and unlock it if necessary.
	; 
		pop	ds
		pop	bx
		call	MemUnlockFixedOrMovable
	;
	; Return appropriate error to caller.
	; 
		stc
		mov	ax, STREAM_CLOSING
		jmp	exitNoPopf
closing:
		;
		; Stream is closing in some way and all the threads are now
		; out of it. If the whole stream is being biffed, we want to
		; always wake up the pending destroyer. If we're waiting
		; for the data to go away, we only wake up the destroyer if
		; all the data are gone.
		;
		test	ds:SD_state, mask SS_NUKING
		jnz	nuking
		;
		; Stream is closing -- see if there are any data left in the
		; buffer.
		;
		tst	ds:SD_reader.SSD_sem.Sem_value
		jg	exit			; Yes -- can't close yet.
nuking:
		;
		; Wake up the destroyer now the stream is empty and everyone's
		; out of the thing.
		;
		push	ax, bx
		mov	ax, ds
		mov	bx, offset SD_closing
		call	ThreadWakeUpQueue
		pop	ax, bx
		jmp	exitNoUnlock		; don't unlock since stream
						;  will already have been freed
streamGone:
	;
	; If stream was destroyed, there's nothing to unlock, but we still
	; need to clear BX off the stack.
	; 
		call	SafePopf
		pop	bx
		jmp	done
StreamStrategy	endp



;------------------------------------------------------------------------------
;			   UTILITY ROUTINES
;------------------------------------------------------------------------------
if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamVerify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure a stream is valid

CALLED BY:	StreamStrategy
PASS:		bx	= stream token
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamVerify	proc	near	uses ax, ds
		.enter
		push	bx
		mov	ds, bx

		mov	bx, ds:SD_handle
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		cmp	ax, ds:SD_max
		ERROR_B		STREAM_INVALID

		mov	ax, MGIT_OTHER_INFO
		call	MemGetInfo
		cmp	ax, STREAM_MAGIC
		ERROR_NE	STREAM_INVALID

		mov	ax, MGIT_ADDRESS
		call	MemGetInfo

		pop	bx
		cmp	bx, ax
		ERROR_NE	STREAM_INVALID
		;
		; Now error-check the stream itself.
		;
		pushf
		INT_OFF

		test	ds:[SD_state], mask SS_NUKING
		jnz	ok		; All bets are off if the stream is
					;  being actively destroyed...this
					;  is due to the way VAllSem works,
					;  which see.

		tst	ds:[SD_unbalanced]
		jnz	ok		; Ditto if stream has been flagged
					;  as unbalanced.

		mov	ax, ds:SD_reader.SSD_sem.Sem_value
		add	ax, ds:SD_writer.SSD_sem.Sem_value
		add	ax, size StreamData
		tst	ds:SD_reader.SSD_lock.Sem_value
		jle	ok
		tst	ds:SD_writer.SSD_lock.Sem_value
		jle	ok 		; <= implies the stream is currently in
					;  use, so the value is likely to be
					;  in flux, so we can't really check it
					;  without dying unnecessarily.
		cmp	ax, ds:SD_max
		ERROR_NE	STREAM_STATE_INVALID
ok:
		call	SafePopf
		.leave
		ret
StreamVerify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamCheckSide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the passed side is one of the valid ones

CALLED BY:	INTERNAL
PASS:		ax	= side constant to verify
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamCheckSide	proc	near	uses ax	; so we can see what it was
		.enter
		cmp	ax, STREAM_READ
		je	ok
		cmp	ax, STREAM_WRITE
		ERROR_NE	STREAM_INVALID_SIDE
ok:
		.leave
		ret
StreamCheckSide	endp

endif		; ERROR_CHECK

SafePopf	label	far
		iret


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamPointAtSide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point at the appropriate side data for a stream

CALLED BY:	INTERNAL
PASS:		ax	= STREAM_READ if reader data wanted
			  STREAM_WRITE if writer data wanted
		bx	= stream token
RETURN:		ds:di	= StreamSideData address
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We only check the SNT_READER bit to make life easier for
		StreamSetNotify -- rather than it having to set AX with
		STREAM_READ (all 1s) or STREAM_WRITE (all 0s) it can just
		send us its StreamNotifyType and we'll do the right thing.
		That's one of the reasons why STREAM_READ is -1...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamPointAtSide proc	near
CheckHack <((STREAM_READ AND mask SNT_READER) ne 0) and ((STREAM_WRITE AND mask SNT_READER) eq 0)>

		.enter
		mov	ds, bx
		mov	di, offset SD_reader
		test	ax, mask SNT_READER
		jnz	10$
		mov	di, offset SD_writer
10$:
		.leave
		ret
StreamPointAtSide endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamNotifyInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal notification routine

CALLED BY:	StreamNotify, StreamSetError, StreamSetNotify,
		StreamCheckDataNotify
PASS:		ds	= stream to notify about
		di	= offset of StreamNotifier for stream
		ah	= STREAM_ACK if a method notifier must be
			  acknowlegded before being sent again.
			  STREAM_NOACK if notification requires no
			   acknowledgement
		cx,bp	= data to pass to function
		dx	= stream token
RETURN:		Nothing
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamNotifyInt	proc	near	uses ax, bx, si, di
		.enter
		tst	ds:[di].SN_ack		; Ack pending?
		jnz	done			; yes -- do nothing

		mov	al, ds:[di].SN_type
CheckHack <(SNM_ROUTINE eq 1) and (SNM_MESSAGE eq 2)>	; Simplifies branching
		cmp	al, SNM_ROUTINE
		jb	done		; => SNM_NONE
		mov	ds:[di].SN_ack, ah	; Note if ack required now
						;  before we can context switch,
						;  else anything the recipient
						;  does could be wiped out when
						;  we run again.
		mov	ax, ds:[di].SN_data
		ja	notifyMethod	; => SNM_MESSAGE
		;
		; Notifying by routine. We always call in this case.
		;
		mov	bx, ds			; bx <- stream segment
		call	ds:[di].SN_dest.SND_routine
		jmp	done
notifyMethod:
		;
		; Notifying by method. 
		;
		mov	bx, ds:[di].SN_dest.SND_message.handle
		;
		; Load the rest of the parameters to send the notification.
		; Note we do not call -- we're talking straight output here.
		;
		mov	si, ds:[di].SN_dest.SND_message.chunk
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
done:
		.leave
		ret
StreamNotifyInt	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamGenerateStreamToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the propper type of token for the stream

CALLED BY:	INTERNAL
PASS:		ds	-> stream

RETURN:		dx	<- stream token for stream
DESTROYED:	nothing
SIDE EFFECTS:	
		none

PSEUDO CODE/STRATEGY:
		examine fixed/movable		
		return segment if fixed,
		return Vsegment if movable.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/10/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamGenerateStreamToken	proc	near
	uses	bx
	.enter
	mov_tr	dx, ax				; dx <- ax value
	mov	bx, ds:[SD_handle]		; bx <- handle of stream
	mov	ax, MGIT_FLAGS_AND_LOCK_COUNT	
	call	MemGetInfo			; al <- HeapFlags
	test	al, mask HF_FIXED		; see if its fixed.
	
	mov	ax, ds				; ax <- stream segment
	jnz	done				; is it fixed?

	mov_tr	ax, bx				; ax <- handle of block
	stc					; CF <- 1 so high bit is set
	rcr	ax, 1
	sar	ax, 1				; SAR to duplicate high bit
	sar	ax, 1				; into high nibble
	sar	ax, 1				; ax <- block's virtual segment
done:
	xchg	ax, dx				; ax <- saved ax value
						; dx <- token
	.leave
	ret
StreamGenerateStreamToken	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamGenerateStreamTokenES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the proper type of token for the stream whose
		segment is in ES

CALLED BY:	(INTERNAL) StreamNotify
PASS:		es	= stream segment
RETURN:		dx	= stream token
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		shift segment to DS and call the usual routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamGenerateStreamTokenES proc near
		uses	ds
		.enter
		segmov	ds, es
		call	StreamGenerateStreamToken
		.leave
		ret
StreamGenerateStreamTokenES endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamCheckDataNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data notification if needed

CALLED BY:	INTERNAL
PASS:		ds:di	= address of StreamSideData to be notified.
RETURN:		Nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamCheckDataNotify proc near	uses cx, dx, bp
		.enter
		mov	cx, ds:[di].SSD_thresh
		cmp	cx, ds:[di].SSD_sem.Sem_value
		jg	done
CheckHack <(STREAM_READ eq -1) and (STREAM_WRITE eq 0)>
		;
		; Load BP with constant to indicate side being notified. AL
		; gets loaded with the bit to test in SD_state to check for
		; any previous notification during this operation.
		;
;		mov	al, mask SS_WDATA
		clr	bp		; BP <- STREAM_WRITE
		cmp	di, offset SD_writer
		je	isWriter
;		mov	al, mask SS_RDATA
		dec	bp		; BP <- STREAM_READ
isWriter:
		;
		;  No matter what type of notification we
		;	are talking about, dx gets the
		;	stream token.  For a fixed stream
		;	this is just the segment.  For a
		;	movable stream, this is the virtual
		;	segment.
		call	StreamGenerateStreamToken

		cmp	cx, 1			; Unbuffered?
		je	doSpecNotify		; Yes
doGenNotify:
		;
		; See if this side has already been notified during this
		; operation. If so, we refuse to send another notification.
		; This obviously assumes that each operation requires at most
		; one notification.
		; 
if (0)	; Some operations require more than one notification. - Joon (1/3/96)
		test	ds:SD_state, al
		jnz	done
		ornf	ds:SD_state, al
endif
		;
		; Perform general notification.
		;	CX	= # chars available
		;	DX	= stream token (already loaded)
		;	BP	= STREAM_READ/STREAM_WRITE (already loaded)
		;
		mov	cx, ds:[di].SSD_sem.Sem_value
		mov	ah, STREAM_ACK		; Need acknowledgement
		add	di, SSD_data		; Point to data notifier
		call	StreamNotifyInt
done:
		.leave		
		ret
doSpecNotify:
		;
		; May require special notification procedures, but only
		; if notifying by routine...
		;
		cmp	ds:[di].SSD_data.SN_type, SNM_ROUTINE
		jb	done			; => SNM_NONE
		ja	doGenNotify		; Not special after all
		mov	cx, ds:[di].SSD_data.SN_data
		tst	bp			; Reading?
		jnz	doReadSpecNotify
		;
		; Special notification to writer. Call the routine and
		; add returned byte if carry is set.
		;
		call	ds:[di].SSD_data.SN_dest.SND_routine
		jnc	done
		call	StreamWriteByteInt
		jmp	done
doReadSpecNotify:
		;
		; Do special notification to reader. AL is the current byte.
		; If the routine returns with the carry set, it means the
		; byte has been used and should be removed from the stream.
		;
		mov	bx, ds:[di].SSD_ptr	; Load current ptr
		mov	al, ds:[bx]		; Fetch current byte
		push	bx			; Preserve from attack
		call	ds:[di].SSD_data.SN_dest.SND_routine
		pop	bx			; Recover from attack
		jnc	done			; Byte not et -- leave queue
						;  alone
		cmp	bx, ds:[di].SSD_ptr	; Consumed some other way?
		jne	done			; Yes -- leave pointer and
						;  semaphores alone
		;
		; Adjust the reader's data pointer and semaphore, then give the
		; byte back to the writer, waking up anyone blocked there.
		;
		StreamUseByteHere	ds, SD_reader, bx
		dec	ds:SD_reader.SSD_sem.Sem_value
		VSem	ds, SD_writer.SSD_sem
		jmp	done
StreamCheckDataNotify endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamReadByteInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal byte-read routine. Handles writer notification, etc.

CALLED BY:	StreamReadByte, StreamRead
PASS:		ds	= stream data
RETURN:		al	= byte read
		carry clear unless stream is closing
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamReadByteInt proc	near
		.enter
		StreamGetByte	ds, al
		jc	closing
		push	ax
		mov	di, offset SD_writer
		call	StreamCheckDataNotify
		pop	ax
		clc
done:
		.leave
		ret
closing:
		mov	ax, STREAM_CLOSING
		jmp	done
StreamReadByteInt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamReadByteNBInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal non-blocking byte read routine. Handles notifying
		writer, etc.

CALLED BY:	StreamReadByte
PASS:		ds	= stream data segment
RETURN:		al	= byte read, if carry clear
		carry set if no byte available
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamReadByteNBInt proc near
		.enter
		StreamGetByteNB	ds, al
		jc	done
		push	ax
		mov	di, offset SD_writer
		call	StreamCheckDataNotify
		pop	ax
		clc
done:
		.leave
		ret
StreamReadByteNBInt endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWriteByteInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal write byte routine. Handles notifying reader

CALLED BY:	StreamCheckDataNotify, StreamWriteByte, StreamWrite
PASS:		ds	= stream data segment
		al	= byte to write
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamWriteByteInt proc	near
		.enter
		StreamPutByte	ds, al
		jc	closing
		mov	di, offset SD_reader
		call	StreamCheckDataNotify
		clc
done:
		.leave
		ret
closing:
		mov	ax, STREAM_CLOSING
		jmp	done
StreamWriteByteInt endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWriteByteNBInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Non-blocking, internal write byte routine. Handles
		notification of readers, etc.

CALLED BY:	StreamWriteByte
PASS:		ds	= stream data segment
		al	= byte to write
RETURN:		carry clear if byte written; carry set if no space
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamWriteByteNBInt proc near
		.enter
		StreamPutByteNB	ds, al
		jc	done
		mov	di, offset SD_reader
		call	StreamCheckDataNotify
		clc
done:
		.leave
		ret
StreamWriteByteNBInt endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFastMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an optimized byte move

CALLED BY:	StreamRead, StreamWrite
PASS:		ds:si	= source
		es:di	= dest
		cx	= byte count
RETURN:		nothing
DESTROYED:	bx, cx, si, di

PSEUDO CODE/STRATEGY:
		When moving bytes, it is fastest to move words.
		When moving words, at least on a '286, it is fastest to
		move them from an even address (ideally to an even address,
		but that's more than I think is necessary -- if we can
		ensure one address is even, that's a win). So, looking at the
		lowest bits of the count and the source, we get four
		possibilities:

		COUNT<b0>	SOURCE<b0>	STRATEGY
		=========	==========	========
		    0		     0		MOVSW(COUNT/2)
		    1		     0		MOVSW(COUNT/2), MOVSB
		    0		     1		MOVSB, MOVSW(COUNT/2)
		    1		     1		MOVSB, MOVSW(COUNT/2-1), MOVSB

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamFastMove	proc	near
		.enter
		;
		; Optimized byte-moving here: faster to move words, but
		; especially faster, on 286 and above, to move word-aligned
		; words.
		;
		jcxz	10$		; Handle bogus call...
		mov	bx, si		; Set BX to hold low bits of count and
		andnf	bx, 1		;  source address shifted left one bit
		shr	cx		;  to address the readMoveTable
		rcl	bx		;  for branching purposes
		shl	bx
		jmp	cs:fastMoveTable[bx]
fastMoveTable	nptr	bothEven, oddCountEvenAddr, evenCountOddAddr, \
			oddCountOddAddr
oddCountOddAddr:		; Move single byte before to align si, cx
				;  already rounded down
		movsb
		jcxz	10$	; Deal with count == 1
		;FALL_THRU
bothEven:			; Perfect match -- just move the words
		rep	movsw
		jmp	10$
evenCountOddAddr:		; Move single byte first to align si, then
				;  move the words, then move single byte after.
				;  Must decrement cx to account for byte moves
		movsb
		dec	cx
oddCountEvenAddr:		; SI aligned, so move the words, then take care
				;  of extra byte
		jcxz	onlyOne	; Deal with count == 1 (and also count == 2 for
				;  evenCountOddAddr)
		rep	movsw
onlyOne:
		movsb
10$:
		.leave
		ret
StreamFastMove	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamReadBulkCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bulk copy for StreamRead to fetch existing bytes from
		the stream.

CALLED BY:	StreamRead
PASS:		ds	= stream segment
		es:di	= buffer
		cx	= bytes to copy from the buffer. There must be
			  (at least) this many bytes in the buffer.
RETURN:		SD_reader.SSD_ptr updated
		es:di	= next free byte in caller's buffer
		any waiting writers woken up and data notification sent
DESTROYED:	bx, si, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamReadBulkCopy proc	near	uses cx
		.enter
		push	cx		; remember # bulk-copied for semaphore
					;  adjustment
		mov	si, ds:SD_reader.SSD_ptr	; Fetch data source
		mov	bp, ds:SD_max	; Figure the number of bytes until the
		sub	bp, si		;  end of the buffer.
		sub	bp, cx		; More than we need?
		jae	doFirstCopy	; Yes -- use CX unmodified
		add	cx, bp		; No -- reduce CX by overshoot. This
					;  *must* set the carry if it's to
					;  reduce cx...
doFirstCopy:	
		lahf			; Save carry for after semaphore mods
doSecondCopy:
		call	StreamFastMove
		sahf			; Recover carry from subtraction way
					;  back when
		jae	doneCopy	; Was enough there, so done
		;
		; Need a second copy. BP contains the negative of the number
		; of bytes we need to copy from the start of the buffer, so
		; negate it, transfer it to CX and point SI to the start of
		; the buffer and go back to do the copy. We clear AH so
		; the SAHF above will clear the carry and we won't come
		; back here again.
		;
		neg	bp
		mov	cx, bp
		mov	si, offset SD_data
		clr	ah
		jmp	doSecondCopy
doneCopy:
		cmp	si, ds:SD_max
		jne	10$
		mov	si, offset SD_data
10$:
		mov	ds:SD_reader.SSD_ptr, si	; Adjust reader's
							;  data pointer to
							;  after last byte moved
	;
	; Adjust the writer's semaphore, now, being sure to wake someone up
	; only if they're blocked on the thing.
	; 
		pop	bx
		INT_OFF
	;
	; Adjust the scheduling semaphores by the amount we moved now
	; we're sure the bytes are safe (no-one else can read the
	; bytes b/c we've got the read side locked, but someone could
	; have written over the ones we're copying if we'd adjusted
	; the writer semaphore before the move).
	;
		sub	ds:SD_reader.SSD_sem.Sem_value, bx; Take from reader
		add	ds:SD_writer.SSD_sem.Sem_value, bx
		cmp	ds:[SD_writer].SSD_sem.Sem_value, bx
		jge	noWakeup
	    ; Sem_value must have been -1, since value less than what we added
	    ; in, so wake the sole writer (others are blocked out by the
	    ; SSD_lock) blocked on SSD_sem.
		mov	ax, ds
		mov	bx, offset SD_writer.SSD_sem.Sem_queue
		call	ThreadWakeUpQueue
noWakeup:
		INT_ON
		;
		; Handle data notification
		;
		push	di			; preserve buffer ending addr
		mov	di, offset SD_writer
		call	StreamCheckDataNotify
		pop	di
		clc
		.leave
		ret
StreamReadBulkCopy		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWriteBulkCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bulk copy for StreamWrite to fetch existing bytes from
		the stream.

CALLED BY:	StreamWrite
PASS:		ds	= stream segment
		es:si	= buffer
		cx	= bytes to copy from the buffer. There must be
			  (at least) this many bytes in the buffer.
RETURN:		SD_writer.SSD_ptr updated
		es:si	= next byte in caller's buffer
		any waiting readers woken up and data notification sent
DESTROYED:	bx, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamWriteBulkCopy proc	near	uses cx
		.enter
		push	cx		; remember # bulk-copied for semaphore
					;  adjustment

		mov	di, ds:SD_writer.SSD_ptr	; Fetch data dest
		mov	bp, ds:SD_max	; Figure the number of bytes until the
		sub	bp, di		;  end of the buffer.
		sub	bp, cx		; More than we need?
		jae	doFirstCopy	; Yes -- use CX unmodified
		add	cx, bp		; No -- reduce CX by overshoot. This
					;  *must* set the carry if it's to
					;  reduce cx...
doFirstCopy:	
		lahf			; Save carry for after semaphore mods
doSecondCopy:
		segxchg ds, es		; Swap ES and DS b/c movs wants it
		call	StreamFastMove

		segxchg ds, es		; Swap ES and DS b/c we wants it
					;  yes precious...
		sahf			; Recover carry from subtraction way
					;  back when
		jae	doneCopy	; Was enough there, so done
		;
		; Need a second copy. BP contains the negative of the number
		; of bytes we need to copy from the start of the buffer, so
		; negate it, transfer it to CX and point SI to the start of
		; the buffer and go back to do the copy. We clear AH so
		; the SAHF above will clear the carry and we won't come
		; back here again.
		;
		neg	bp
		mov	cx, bp
		mov	di, offset SD_data
		clr	ah
		jmp	doSecondCopy
doneCopy:
		cmp	di, ds:SD_max
		jne	10$
		mov	di, offset SD_data
10$:
		mov	ds:SD_writer.SSD_ptr, di	; Adjust writer's
							;  data pointer to
							;  after last byte moved
	;
	; Adjust the reader's semaphore, now, being sure to wake someone up
	; only if they're blocked on the thing.
	; 
		pop	bx
		INT_OFF
	;
	; Adjust the scheduling semaphores by the amount we moved now
	; we're sure the bytes are safe (no-one else can write the
	; bytes b/c we've got the write side locked, but someone could
	; have written over the ones we're copying if we'd adjusted
	; the writer semaphore before the move).
	;
		sub	ds:SD_writer.SSD_sem.Sem_value, bx; Take from writer
		add	ds:SD_reader.SSD_sem.Sem_value, bx
		cmp	ds:[SD_reader].SSD_sem.Sem_value, bx
		jge	noWakeup
	    ; Sem_value must have been -1, since value less than what we added
	    ; in, so wake the sole reader (others are blocked out by the
	    ; SSD_lock) blocked on SSD_sem.
		mov	ax, ds
		mov	bx, offset SD_reader.SSD_sem.Sem_queue
		call	ThreadWakeUpQueue
noWakeup:
		INT_ON
		;
		; Handle data notification
		;
		push	di			; preserve buffer ending addr
		mov	di, offset SD_reader
		call	StreamCheckDataNotify
		pop	di
		clc
		.leave
		ret
StreamWriteBulkCopy		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamLockWriter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the writing side of a stream, handling stream closure

CALLED BY:	StreamWriteByte, StreamWrite
PASS:		ds	= stream
		ax	= STREAM_BLOCK/STREAM_NOBLOCK
RETURN:		carry clear, if ok. else
		carry set and ax = StreamError describing problem
			(STREAM_WOULD_BLOCK or STREAM_CLOSING)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamLockWriter proc	near
		.enter
	;
	; Not allowed to write anything if the LINGERING flag is set.
	;
		test	ds:SD_state, mask SS_LINGERING or mask SS_NUKING
		jnz	closing
	;
	; If STREAM_NOBLOCK specified, we have to do a non-blocking P on the
	; lock to make sure we don't block...
	;
		tst	ax
		jz	dontBlockOnLock
	;
	; Just do a regular StreamPSem on the lock for the write side. We
	; return STREAM_CLOSING if the NUKING or LINGERING bit gets set while
	; we're blocked.
	;
		StreamPSem	ds, SD_writer.SSD_lock, \
			<mask SS_NUKING or mask SS_LINGERING>
		jc	returnClosing
done:
		.leave
		ret
closing:
		stc
returnClosing:
		mov	ax, STREAM_CLOSING
		jmp	done
dontBlockOnLock:
	;
	; No need to use special macro as we never block, so the flags can't
	; change. The only error we can return is STREAM_WOULD_BLOCK.
	;
		PTimedSem	ds, SD_writer.SSD_lock, 0
		jnc	done
		mov	ax, STREAM_WOULD_BLOCK
		jmp	done
StreamLockWriter endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamLockReader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the reading side of a stream, dealing with closure and
		blocking vs. nonblocking mode

CALLED BY:	StreamReadByte, StreamRead
PASS:		ds	= StreamData segment
		ax	= STREAM_BLOCK/STREAM_NOBLOCK
RETURN:		carry clear if side locked
		carry set if couldn't lock side, either because stream is
			closing or because the side is already locked and
			STREAM_NOBLOCK was given. ax = StreamError describing
			problem.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamLockReader proc	near
		.enter
	;
	; If STREAM_NOBLOCK specified, we have to do a non-blocking P on the
	; lock to make sure we don't block...
	;
		tst	ax
		jz	dontBlockOnLock
	;
	; Just do a regular StreamPSem on the lock for the read side. We
	; return STREAM_CLOSING if the NUKING bit gets set while we're blocked.
	; It's ok for LINGERING to be set, as we're helping to alleviate that.
	;
		StreamPSem	ds, SD_reader.SSD_lock, <mask SS_NUKING>
		jc	returnClosing
done:
		.leave
		ret
returnClosing:
		mov	ax, STREAM_CLOSING
		jmp	done
dontBlockOnLock:
	;
	; No need to use special macro as we never block, so the flags can't
	; change. The only error we can return is STREAM_WOULD_BLOCK.
	;
		PTimedSem	ds, SD_reader.SSD_lock, 0
		jnc	done
		mov	ax, STREAM_WOULD_BLOCK
		jmp	done
StreamLockReader endp

;------------------------------------------------------------------------------
;			   DRIVER FUNCTIONS
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler to do nothing but clear the carry

CALLED BY:	DR_INIT, DR_EXIT, DR_SUSPEND, DR_UNSUSPEND
PASS:		Nothing
RETURN:		carry clear
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamDoNothing	proc	near
		.enter
		clc
		.leave
		ret
StreamDoNothing	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new stream

CALLED BY:	DR_STREAM_CREATE (StreamStrategy)
PASS:		ax	= buffer size
		bx	= geode handle to own the stream buffer
		cx	= ALLOC_FIXED mask for stream

RETURN:		bx	= stream token if carry clear, else
		ax	= error code if carry set:
			STREAM_CANNOT_ALLOC
				Cannot allocate a block of fixed memory
				to hold the stream buffer.
			STREAM_BUFFER_TOO_LARGE
				Owing to implementation details, a stream
				buffer cannot be larger than 32K, a size
				you exceeded.

DESTROYED:	ds (ds preserved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamCreate	proc	near	uses cx, si
		.enter
		cmp	ax, STREAM_MAX_STREAM_SIZE
		ja	bufferTooLarge
		tst	ax
		jz	bufferTooSmall
	;
	; Allocate the stream block fixed. Also make it sharable so
	; applications like the graphical setup program can safely free a
	; mouse driver.
	;
		add	ax, size StreamData
		push	ax
		and	cx, mask HF_FIXED
		jnz	doAlloc
		ornf	cx, (mask HAF_LOCK shl 8) or mask HF_SWAPABLE
doAlloc:
		or	cx, mask HF_SHARABLE or \
			   (mask HAF_ZERO_INIT) shl 8
		push	cx			; nuked by MemAlloc, but we
						;  need it for virtual
						;  segment creation...
		call	MemAllocSetOwner
		pop	cx
		jc	cannotAlloc
	;
	; Initialize things...
	;
		mov	ds, ax
		mov	ds:SD_handle, bx; Store block handle for freeing
		pop	ax		; Recover pointer limit
		mov	ds:SD_max, ax
	;
	; Set all bytes in buffer available for writing.
	;
		sub	ax, size StreamData
		mov	ds:SD_writer.SSD_sem.Sem_value, ax
	;
	; Notification threshold begins at 1 (unbuffered) for both sides
	;
		mov	ax, 1
		mov	ds:SD_reader.SSD_thresh, ax
		mov	ds:SD_writer.SSD_thresh, ax
		clr	ds:SD_useCount		; Pretend we're not here...
		clr	ds:SD_unbalanced	; in balance at start
	;
	; Start both sides as unlocked.
	;
		mov	ds:SD_reader.SSD_lock.Sem_value, ax
		mov	ds:SD_writer.SSD_lock.Sem_value, ax
	;
	; Both pointers begin at the start of the buffer.
	;
		mov	ax, offset SD_data
		mov	ds:SD_reader.SSD_ptr, ax
		mov	ds:SD_writer.SSD_ptr, ax
	;
	; Mark the block for EC purposes.
	;
EC <		mov	ax, STREAM_MAGIC				>
EC <		call	MemModifyOtherInfo				>
	;
	; Check for virtual segment vs real segment
	;
		mov	bx, ds		; Return stream segment in bx, not its
					;  handle
		test	cx, mask HF_FIXED		; (carry cleared)
		jnz	done

	;
	; Virtualize the segment (so the stream can move about...)
	;
		mov	bx, ds:[SD_handle]	; bx <- handle of block
		call	MemUnlock

		shr	bx,1			; turn bx into
		shr	bx,1			;  	virtual segment
		shr	bx,1
		shr	bx,1
		or	bx, 0f000h
done:
		.leave
		ret
cannotAlloc:
		add	sp, 4		; Discard both pushed values
bufferTooSmall:
		mov	ax, STREAM_CANNOT_ALLOC
		stc
		jmp	done
bufferTooLarge:
		mov	ax, STREAM_BUFFER_TOO_LARGE
		stc
		jmp	done
StreamCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy an open stream

CALLED BY:	DR_STREAM_DESTROY (StreamStrategy)
PASS:		ax	= STREAM_LINGER if should wait for all data to be
			  read.
		bx	= stream token
RETURN:		carry set if couldn't destroy the stream (e.g. if someone is
			already in a lingering destroy of the stream)
			ax	= STREAM_CLOSING
		carry clear if stream destroyed
DESTROYED:	bx, ax, ds (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamDestroy	proc	near
		.enter
		mov	ds, bx
		dec	ds:SD_useCount		; Pretend we're out so
						;  StreamShutdown isn't
						;  fooled
		call	StreamShutdown
		call	StreamFree
		.leave
		ret
StreamDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up a stream block.

CALLED BY:	(RESTRICTED GLOBAL) StreamDestroy
PASS:		bx	= stream token
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamFree	proc	far
		uses	ds, bx
		.enter
		mov	ds, bx
EC <		mov	bx, ds:SD_reader.SSD_lock.Sem_queue		>
EC <		or	bx, ds:SD_reader.SSD_sem.Sem_queue		>
EC <		or	bx, ds:SD_writer.SSD_lock.Sem_queue		>
EC <		or	bx, ds:SD_writer.SSD_sem.Sem_queue		>
EC <		tst	bx						>
EC <		ERROR_NZ	SOMEONE_IS_BLOCKED_ON_STREAM		>
		mov	bx, ds:SD_handle
		call	MemFree
		clc
		.leave
		ret
StreamFree	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shutdown access to the passed stream, waiting for data
		to drain out of it or discarding any data, as requested

CALLED BY:	(RESTRICTED GLOBAL)
PASS:		bx	= stream token
		ax	= STREAM_LINGER/STREAM_DISCARD
RETURN:		carry set on error:
			ax	= STREAM_CLOSING
		carry clear if ok:
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	access to the stream is revoked

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/10/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamShutdown	proc	far
		uses	ds, bx, ax
		.enter
		mov	ds, bx
		pushf

		INT_OFF
	;
	; Are we allowed to just biff the data?
	;
		tst	ax
		xchg	ax, bx		; ax:bx <- queue (for wakeup or block)
		mov	bx, offset SD_closing
		jnz	linger		; no -- see if anything's left
	;
	; See if someone's already lingering on this sucker
	;
		test	ds:SD_state, mask SS_LINGERING
		jz	destroy		; no -- can safely nuke it.
	;
	; Someone be hanging out -- wake the dude up and let it
	; destroy the stream for us.
	;
		call	ThreadWakeUpQueue
		call	SafePopf

	;
	; Return an error so the caller knows the port isn't really
	; closed yet (also avoids double-V [not W] of the port's
	; openSem in the parallel and serial drivers...)
	;
		stc
		mov	ax, STREAM_CLOSING
		jmp	done

linger:
	;
	; Make sure we're the only one lingering here...
	;
EC <		test	ds:[SD_state], mask SS_LINGERING		>
EC <		ERROR_NZ STREAM_STATE_INVALID				>
	;
	; See if there are any data remaining in the stream.
	;
		cmp	ds:SD_reader.SSD_sem.Sem_value, 0
		jle	destroy		; Nope -- go nuke the stream.

		ornf	ds:SD_state, mask SS_LINGERING
	;
	; Turn interrupts on during the notify
	;
		call	SafePopf
		pushf
	;
	; If data notifier registered, adjust threshold and force notify.
	; We won't get here if there's an actual notifier and the threshold
	; is one (notification would have occurred already and stream would
	; be draining), so we don't have to worry about that case.
	; 
		mov	ax, ds:[SD_reader].SSD_sem.Sem_value
		mov	ds:[SD_reader].SSD_thresh, ax
		mov	di, offset SD_reader
		call	StreamCheckDataNotify
		mov	di, DR_STREAM_DESTROY	; reload for strategy...
	;
	; Block on the SD_closing field of the stream -- this will
	; prevent more data from being written and cause any emptying
	; read to wake us up.
	;
		mov	ax, ds
		mov	bx, offset SD_closing
		call	ThreadBlockOnQueue
		INT_OFF
destroy:
	;
	; We can actually nuke the thing, but not until everyone's
	; done with the stream. We set the SS_NUKING flag to keep
	; other people out, then wake up anyone waiting on any of
	; the semaphores.
	;
		ornf	ds:SD_state, mask SS_NUKING
		tst	ds:SD_useCount
		jz	nukeIt				; We're the only one
	;
	; Wake up anyone who might be waiting. Theoretically, they
	; will all check the SD_state field after waking up, realize
	; the wakeup wasn't because data was there but was rather
	; because the stream is dying and abort. StreamStrategy will
	; wake us up when everyone's gone.
	; 
		VAllSem	ds, SD_reader.SSD_lock
		VAllSem	ds, SD_writer.SSD_lock
		VAllSem	ds, SD_reader.SSD_sem
		VAllSem	ds, SD_writer.SSD_sem

		mov	bx, offset SD_closing
		mov	ax, ds
		call	ThreadBlockOnQueue
nukeIt:
EC <		mov	bx, ds:SD_reader.SSD_lock.Sem_queue		>
EC <		or	bx, ds:SD_reader.SSD_sem.Sem_queue		>
EC <		or	bx, ds:SD_writer.SSD_lock.Sem_queue		>
EC <		or	bx, ds:SD_writer.SSD_sem.Sem_queue		>
EC <		tst	bx						>
EC <		ERROR_NZ	SOMEONE_IS_BLOCKED_ON_STREAM		>

		call	SafePopf	; finally restore interrupts
done:
		.leave
		ret
StreamShutdown	endp
;
; Table of offsets into a StreamSideData for each notifier structure. Indexed
; by StreamNotifyEvent*2
;
notifierOffsets	word	SSD_error	; SNE_ERROR
		word	SSD_data	; SNE_DATA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register a notifier for the stream

CALLED BY:	DR_STREAM_SET_NOTIFY (StreamStrategy)
PASS:		ax	= StreamNotifyType
		bx	= stream token
		cx:dx	= address of handling routine, if SNM_ROUTINE
			  destination of output if SNM_MESSAGE
		bp	= method to send if SNM_MESSAGE, data passed in AX
			  if SNM_ROUTINE (except for SNE_DATA with threshold
			  of 1, in which case this word is passed in CX)
RETURN:		Nothing
DESTROYED:	ax, ds (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamSetNotify	proc	near	uses di, bx
		.enter
EC <		test	ax, not StreamNotifyType			>
EC <		ERROR_NZ	STREAM_SET_NOTIFY_BAD_FLAGS		>
		call	StreamPointAtSide
CheckHack <offset SNT_EVENT eq 2>

		mov	bx, ax
		andnf	bx, mask SNT_EVENT
EC <		cmp	bx, StreamNotifyEvent shl offset SNT_EVENT	>
EC <		ERROR_AE	STREAM_SET_NOTIFY_BAD_FLAGS		>
		shr	bx		; Need *2 to index word table, so shift
					;  one less that we'd need to get the
					;  event right-justified.
		add	di, cs:notifierOffsets[bx]
		
		andnf	al, mask SNT_HOW
EC <		cmp	al, StreamNotifyMode				>
EC <		ERROR_AE	STREAM_SET_NOTIFY_BAD_FLAGS		>
   		
		mov	ds:[di].SN_type, al
		mov	ds:[di].SN_data, bp

		;
		; Both routine and method notification have cx:dx in
		; the same place, so just store them as if it's routine
		; notification.
		;
		mov	ds:[di].SN_dest.SND_routine.low, dx
		mov	ds:[di].SN_dest.SND_routine.high, cx
		;
		; Clear any left-over acknowledgement demands.
		;
		mov	ds:[di].SN_ack, 0
	;
	; Send the notification if pertinent
	; 
		cmp	bx, SNE_DATA shl 1
		jne	checkError
		sub	di, cs:notifierOffsets[bx]

		push	cx
		mov	cl, ds:[SD_state]	; save state over notification
		call	StreamCheckDataNotify
		mov	ds:[SD_state], cl	; restore state
		pop	cx
done:
		.leave
		ret
checkError:
		push	cx
		mov	cx, ds:[di-offset SSD_error].SSD_lastErr
		jcxz	errorCheckDone
		;
		;  No matter what type of notification we
		;	are talking about, dx gets the
		;	stream token.  For a fixed stream
		;	this is just the segment.  For a
		;	movable stream, this is the virtual
		;	segment.
		call	StreamGenerateStreamToken

		mov	ah, STREAM_NOACK
		call	StreamNotifyInt
errorCheckDone:
		pop	cx
		jmp	done
StreamSetNotify	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamGetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the stored error code for one side of a stream. Clears
		any pending error for the side.

CALLED BY:	DR_STREAM_GET_ERROR (StreamStrategy)
PASS:		ax	= STREAM_READ if error for reader desired
			  STREAM_WRITE if error for writer desired
		bx	= stream token
RETURN:		ax	= stored error token (0 if none stored)
DESTROYED:	ds (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamGetError	proc	near	uses di
		.enter
EC <		call	StreamCheckSide					>
		call	StreamPointAtSide
		clr	ax
		xchg	ax, ds:[di].SSD_lastErr
		.leave
		ret
StreamGetError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamSetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Post an error for the other side of a stream.

CALLED BY:	DR_STREAM_SET_ERROR (StreamStrategy)
PASS:		ax	= STREAM_READ if error being posted by reader
			  STREAM_WRITE if error being posted by writer
		bx	= stream token
		cx	= error code
RETURN:		nothing
DESTROYED:	ds, dx (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamSetError	proc	near	uses di
		.enter
EC <		call	StreamCheckSide					>
		not	ax			; Need to notify other side
		call	StreamPointAtSide
		;
		; Record error for posterity.
		;
		mov	ds:[di].SSD_lastErr, cx
		;
		; Now send the notification. There's no acknowledgement required
		; for errors as we assume each one counts.
		;
		mov	ah, STREAM_NOACK
   		lea	di, ds:[di].SSD_error
		;
		;  No matter what type of notification we
		;	are talking about, dx gets the
		;	stream token.  For a fixed stream
		;	this is just the segment.  For a
		;	movable stream, this is the virtual
		;	segment.
		call	StreamGenerateStreamToken

		call	StreamNotifyInt		
		.leave
		ret
StreamSetError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flush all data in the stream.

CALLED BY:	DR_STREAM_FLUSH (StreamStrategy)
PASS:		bx	= stream token
RETURN:		nothing
DESTROYED:	ds (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamFlush	proc	near	uses ax, bx, di
		.enter
		mov	ds, bx

		pushf

		INT_OFF
		;
		; See if there are any data in the stream (number of bytes
		; available stored in reader's semaphore)
		;
		mov	ax, ds:SD_reader.SSD_sem.Sem_value
		cmp	ax, 0
		jle	done		; none => nothing to flush so done
		;
		; Transfer those bytes to the writer and adjust the reader's
		; pointer.
		;
		add	ds:SD_writer.SSD_sem.Sem_value, ax
		mov	ds:SD_reader.SSD_sem.Sem_value, 0
		add	ax, ds:SD_reader.SSD_ptr
		mov	ds:SD_reader.SSD_ptr, ax	; Assume no wrap
		sub	ax, ds:SD_max			; correct?
		jb	noWrap				; yup
		add	ax, offset SD_data		; no -- offset from
		mov	ds:SD_reader.SSD_ptr, ax	;  start of buffer.
noWrap:
		;
		; See if there's a writer blocked (remember, there can only
		; be one blocked on the SSD_sem at a time b/c we keep the
		; writing side locked while waiting for more room, so we only
		; need to do one wakeup).
		; XXX: fencepost error here? (nope. writer will consume the
		; space w/o mangling Sem_value again, so we should be fine)
		;
		tst	ds:SD_writer.SSD_sem.Sem_queue
		jz	done
		mov	ax, ds			; ax:bx = queue
		mov	bx, offset SD_writer.SSD_sem.Sem_queue
		call	ThreadWakeUpQueue

		call	SafePopf

		mov	di, offset SD_writer
		call	StreamCheckDataNotify

		pushf
done:
		call	SafePopf
		.leave
		ret
StreamFlush	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamSetThreshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the notification threshold for one of the sides of 
		a stream. The threshold will take effect the next time
		an operation on the other side of the stream takes place.

CALLED BY:	DR_STREAM_SET_THRESHOLD (StreamStrategy)
PASS:		ax	= STREAM_READ/STREAM_WRITE
		bx	= stream token
		cx	= threshold
RETURN:		carry clear
DESTROYED:	ds (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamSetThreshold proc	near	uses di
		uses	ax, bx, cx
		.enter
EC <		call	StreamCheckSide					>
   		call	StreamPointAtSide
		mov	ds:[di].SSD_thresh, cx

		;
		;  Check for notification pending due to new threshold.
		mov	cl, ds:SD_state		; save state across notify
		call	StreamCheckDataNotify
		mov	ds:SD_state, cl		; restore state
		clc
		.leave
		ret
StreamSetThreshold endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamReadByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a single byte of data from the stream

CALLED BY:	DR_STREAM_READ_BYTE (StreamStrategy)
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= stream token
RETURN:		al	= byte read, if carry clear
		ax	= error code (STREAM_WOULD_BLOCK or STREAM_CLOSING) if
			  carry set
DESTROYED:	ds (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
readByteFuncs	nptr	StreamReadByteNBInt, StreamReadByteInt
StreamReadByte	proc	near	uses bx, di
		.enter
EC <		cmp	ax, STREAM_BLOCK				>
EC <		ERROR_A	STREAM_INVALID_BLOCK_FLAG			>
		mov	ds, bx
		call	StreamLockReader
		jc	done
		;
		; Call the right routine to fetch us the byte
		;
		xchg	ax, bx
		call	cs:readByteFuncs[bx]
		;
		; Acknowledge any notification that was sent and allow further
		; write notifications.
		;
		pushf
		andnf	ds:SD_state, not mask SS_WDATA
		mov	ds:SD_reader.SSD_data.SN_ack, 0
		VSem	ds, SD_reader.SSD_lock
		call	SafePopf
done:
		.leave
		ret
StreamReadByte	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a single byte of data to the stream

CALLED BY:	DR_STREAM_WRITE_BYTE (StreamStrategy)
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= stream token
		cl	= byte to write
RETURN:		carry clear if data written
		carry set if error. Error code in ax (STREAM_CLOSING or
			STREAM_WOULD_BLOCK)
DESTROYED:	ax, ds (saved by StreamStrategy)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
writeByteFuncs	nptr	StreamWriteByteNBInt, StreamWriteByteInt
StreamWriteByte	proc	near	uses bx, di
		.enter
EC <		cmp	ax, STREAM_BLOCK				>
EC <		ERROR_A	STREAM_INVALID_BLOCK_FLAG			>
   		mov	ds, bx
		call	StreamLockWriter
		jc	done
		;
		; Call the right routine to store the byte
		;
		xchg	ax, bx
		mov	al, cl
		call	cs:writeByteFuncs[bx]
		;
		; Acknowledge any notification that was sent.
		;
		pushf
		andnf	ds:SD_state, not mask SS_RDATA
		mov	ds:SD_writer.SSD_data.SN_ack, 0
		VSem	ds, SD_writer.SSD_lock
		call	SafePopf
done:
		.leave
		ret
StreamWriteByte	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a bunch of bytes from the stream

CALLED BY:	DR_STREAM_READ (StreamStrategy)
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= stream token
		cx	= number of bytes to read
		ds:si	= buffer to which to read them
RETURN:		cx	= number of bytes read if carry clear.
		ax	= error code if carry set (STREAM_WOULD_BLOCK or
			  STREAM_CLOSING). STREAM_WOULD_BLOCK only returned
			  if stream couldn't be locked and no data were
			  read as a result.
DESTROYED:	ds, es (both saved by StreamStrategy), ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamRead	proc	near	uses bx, di, si, bp
		.enter
		push	ds		; Transfer buffer segment to ES for
		pop	es		;  use with STOS and MOVS
		mov	ds, bx

		jcxz	zeroLength	; nothing to do

		call	StreamLockReader
		jc	exit

		mov	di, si		; Need to store in es:di

		cmp	ds:SD_writer.SSD_data.SN_type, SNM_ROUTINE
		jne	notSpec
		cmp	ds:SD_writer.SSD_thresh, 1
		LONG je	handleSpecNotify
notSpec:
		pushf
		INT_OFF
		cmp	ds:SD_reader.SSD_sem.Sem_value, cx
		jl	notEnoughHereDude
ifdef USE_OLD_ZERO_LENGTH_DETECT
		jcxz	zeroLen
endif
		;
		; There are enough bytes in the buffer to satisfy us. Of course,
		; they may not be contiguous, but StreamReadBulkCopy can handle
		; it.
		;
		call	SafePopf

		call	StreamReadBulkCopy
done:
		;
		; Now the transfer is complete, acknowledge any notification.
		; Don't want to do it until we've got the data or the
		; user might do another read when it shouldn't since we've
		; snarfed all the data...
		; 
		pushf

		andnf	ds:SD_state, not mask SS_WDATA
		mov	ds:SD_reader.SSD_data.SN_ack, 0

		VSem	ds, SD_reader.SSD_lock

		call	SafePopf
exit:
		.leave
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;; below the ret line ;;;;;;;;;;;;;;;;;;;;;;;;
zeroLength:
		clc				; no error
		jmp	exit

ifdef USE_OLD_ZERO_LENGTH_DETECT
	;
	; Special-case 0-byte read. If no data in the stream, and 
	; STREAM_NOBLOCK passed, return STREAM_WOULD_BLOCK and carry set.
	; 
zeroLen:
		jne	zeroDone	; => data in the stream
		tst	ax		; non-blocking?
		jnz	zeroDone

		pop	ax			; ax <- flags
		or	ax, mask CPU_CARRY	; "set" carry
		push	ax

		mov	ax, STREAM_WOULD_BLOCK
zeroDone:
		call	SafePopf
		jmp	done
endif ;USE_OLD_ZERO_LENGTH_DETECT

returnShortReadDiscardTotal:
	;
	; Not enough but caller doesn't want to block, so return what
	; we have so far.
	;
		inc	sp			; Discard saved total count
		inc	sp
		clc				; short read isn't an error in
						;  non-blocking mode.
		jmp	done
notEnoughHereDude:
	;
	; Copy out what we can in fast mode.
	;
		XchgTopStack cx			; stack <- bytes desired
						; cx <- flags
		push	ax			; STREAM_BLOCK/STREAM_NOBLOCK
		push	cx			; push flags

		mov	cx, ds:SD_reader.SSD_sem.Sem_value

		call	SafePopf

		jcxz	noneThere
		call	StreamReadBulkCopy
noneThere:
		pop	ax
		; cx = bytes copied out so far
		tst	ax
		jz	returnShortReadDiscardTotal
	;
	; Caller will let us block, so go into slow mode, reading a byte at a
	; time until the request is filled.
	;
		pop	ax
		push	ax		; Save again for total
		xchg	ax, cx
		sub	cx, ax
slowMode:
		test	ds:[SD_state], mask SS_NUKING or mask SS_LINGERING
							; check for stream going
		jnz	nukingOrLingering		;  away now, as
							;  StreamReadByteInt
							;  will (correctly) not
							;  do so before blocking
doSlowRead:
		push	di
		call	StreamReadByteInt	; Fetch next byte
		pop	di
		jc	calculateShortRead	; Error (closing)
		stosb
		loop	slowMode
		pop	cx		; Return total amount read
		jmp	done

handleSpecNotify:
	;
	; Writer requires special notifier, so we can't do bulk copies.
	;
		tst	ax
		push	cx		; save total requested
		jnz	slowMode	; if we may block, just go into
					;  standard slow mode
nbSlowMode:
		push	di
		call	StreamReadByteNBInt
		pop	di
		jc	calculateShortRead
		stosb
		loop	nbSlowMode
		pop	cx		; return total amount read
		jmp	done

nukingOrLingering:
	;
	; We're either a lingering stream or a nuking stream.  If we're
	; lingering, see whether any data is left.  If so, go to read it
	;
		test	ds:[SD_state], mask SS_LINGERING
		jz	calculateShortRead
		tst	ds:[SD_reader].SSD_sem.Sem_value
		jnz	doSlowRead

calculateShortRead:
	;
	; Got an error while reading a byte. We need to figure how many bytes we
	; actually read before we return.
	;
		pop	di		; recover total
		sub	di, cx
		mov	cx, di
		stc			; a short-read in blocking mode is an
					;  error
		mov	ax, STREAM_SHORT_READ_WRITE
		jmp	done
StreamRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a bunch of bytes to the stream

CALLED BY:	DR_STREAM_WRITE (StreamStrategy)
PASS:		ax	= STREAM_BLOCK/STREAM_NOBLOCK
		bx	= stream token
		cx	= number of bytes to write
		ds:si	= buffer from which to write them
RETURN:		cx	= number of bytes written, if carry clear.
		ax	= error code (StreamError) if carry set.
DESTROYED:	ds, es (both saved by StreamStrategy), ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamWrite	proc	near	uses bx, di, si, bp
		.enter
		push	ds			; Shift buffer segment to
		pop	es			;  ES 'cause everything else
						;  expects DS to be the stream
		mov	ds, bx

		jcxz	zeroLength		; nothing to do

		call	StreamLockWriter	; if C ax <- error
		jc	exit

		cmp	ds:SD_reader.SSD_data.SN_type, SNM_ROUTINE
		jne	notSpec
		cmp	ds:SD_reader.SSD_thresh, 1
		LONG je	handleSpecNotify
notSpec:
		pushf

		INT_OFF
		cmp	ds:SD_writer.SSD_sem.Sem_value, cx
		jl	notEnoughHereDude
ifdef USE_OLD_ZERO_LENGTH_DETECT
		jcxz	zeroLen
endif ;USE_OLD_ZERO_LENGTH_DETECT
		;
		;There are enough bytes in the buffer to satisfy us. Of course,
		;they may not be contiguous, but StreamWriteBulkCopy can handle
		;it.
		;

		call	SafePopf

		call	StreamWriteBulkCopy
done:
		;
		; Now the transfer is complete, acknowledge any notification.
		; Don't want to do it until we've written the data or the
		; user might do another write when it shouldn't since we've
		; snarfed all the space...
		; 
		pushf

		andnf	ds:SD_state, not mask SS_RDATA	; Allow further read
							;  notifications
		mov	ds:SD_writer.SSD_data.SN_ack, 0
		VSem	ds, SD_writer.SSD_lock

		call	SafePopf
exit:
		.leave
		ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;; below the ret line ;;;;;;;;;;;;;;;;;;;;;;;;
zeroLength:
		clc				; no error
		jmp	exit

ifdef USE_OLD_ZERO_LENGTH_DETECT
	;
	; Special-case 0-byte write. If no space in the stream, and
	; STREAM_NOBLOCK passed, return STREAM_WOULD_BLOCK and carry set.
	; 
zeroLen:
		jne	zeroDone	; => space in the stream
		tst	ax		; non-blocking?
		jnz	zeroDone
		pop	ax			; ax <- flags
		or	ax, mask CPU_CARRY	; "set" carry
		push	ax
		mov	ax, STREAM_WOULD_BLOCK
zeroDone:
		call	SafePopf
		jmp	done
endif ; USE_OLD_ZERO_LENGTH_DETECT


returnShortWrite:
	;
	; Not enough but caller doesn't want to block, so return what
	; we have so far.
	;
		inc	sp			; Discard saved total count
		inc	sp
		jmp	done
notEnoughHereDude:
	;======================================================================
	; Not enough room for full operation, but do what we can before
	; entering slow mode.
	;
		
		XchgTopStack	cx		; cx <- flags, save cx
		push	ax			; save cx

		push	cx			; push flags
		;
		; Copy in what we can in fast mode.
		;
		mov	cx, ds:SD_writer.SSD_sem.Sem_value

		call	SafePopf		; "enable" interrupts

		jcxz	noneThere
		call	StreamWriteBulkCopy
noneThere:
		pop	ax			; Recover block/noblock flag
		tst	ax			; (clears carry)
		jz	returnShortWrite
		;
		; Go into slow mode, writing a byte at a time until the
		; request is filled.
		;
		pop	ax
		push	ax		; Save again for total
		xchg	ax, cx
		sub	cx, ax
slowMode:
		lodsb	es:
		test	ds:[SD_state], mask SS_NUKING	; check for stream 
		jnz	calculateShortWrite		; going away now, as
							; StreamWriteByteInt
							; will (correctly) not
							; do so before blocking

		call	StreamWriteByteInt
		jc	calculateShortWrite
		loop	slowMode
		pop	cx		; Return total amount written
		jmp	done

handleSpecNotify:
	;
	; Reader requires special notifier, so we can't do bulk copies.
	;
		tst	ax		; ax = STREAM_BLOCK ?   (clears carry)
		push	cx		; save total requested
		jnz	slowMode	; if we may block, just go into
					;  standard slow mode
nbSlowMode:
		lodsb	es:
		call	StreamWriteByteNBInt
		jc	calculateShortWrite
		loop	nbSlowMode
		pop	cx		; return total amount written
		jmp	done

calculateShortWrite:
	;
	; Got an error while writing a byte. We need to figure how many bytes we
	; actually wrote before we return.
	;
		pop	di		; recover total
		sub	di, cx
		mov	cx, di
		stc			; a short-write in blocking mode is an
					;  error
		mov	ax, STREAM_SHORT_READ_WRITE
		jmp	done
StreamWrite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the number of bytes available to one side of a stream

CALLED BY:	DR_STREAM_QUERY (StreamStrategy)
PASS:		ax	= STREAM_READ/STREAM_WRITE to indicate the side
			  for which information is desired
		bx	= stream token
RETURN:		ax	= number of bytes available to the side.
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamQuery	proc	near	uses di
		.enter
EC <		call	StreamCheckSide					>
   		call	StreamPointAtSide
		mov	ax, ds:[di].SSD_sem.Sem_value
		;
		; Deal with someone being blocked on the semaphore by reseting
		; ax to 0 if it is negative.
		;
		tst	ax
		jge	10$
		clr	ax
10$:
		.leave
		ret
StreamQuery	endp
;------------------------------------------------------------------------------
;			  LIBRARY INTERFACE
;------------------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send notification through a StreamNotifier

CALLED BY:	GLOBAL
PASS:		ah	= STREAM_ACK if notifier must be acknowledged before
			  another notification will be sent out
		es	= stream to notify about
		ds:di	= offset of StreamNotifier for stream
		cx,bp   = data for notification routine
RETURN:		nothing
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamNotify	proc	far
		.enter
		call	StreamGenerateStreamTokenES	; dx <- token
		call	StreamNotifyInt
		.leave
		ret
StreamNotify	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWriteDataNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data notification to the writer if required

CALLED BY:	EXTERNAL (other drivers)
PASS:		es	= segment of stream.
RETURN:		nothing
DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamWriteDataNotify proc far	uses ds
		.enter
		segmov	ds, es, ax
		mov	di, offset SD_writer
		call	StreamCheckDataNotify
		andnf	ds:SD_state, not mask SS_WDATA
		.leave
		ret
StreamWriteDataNotify endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamReadDataNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send data notification to the reader if required

CALLED BY:	EXTERNAL (other drivers)
PASS:		es	= segment of stream.
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamReadDataNotify proc far	uses ds
		.enter
		segmov	ds, es, ax
		mov	di, offset SD_reader
		call	StreamCheckDataNotify
		andnf	ds:SD_state, not mask SS_RDATA
		.leave
		ret
StreamReadDataNotify endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamGetDeviceMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the map of existing stream devices for this driver

CALLED BY:	DR_STREAM_GET_DEVICE_MAP
PASS:		ds	= dgroup (from StreamStrategy)
RETURN:		ax	= 0
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StreamGetDeviceMap proc	near
		.enter
		clr	ax		; no devices here, mahn
		.leave
		ret
StreamGetDeviceMap endp

Resident	ends
