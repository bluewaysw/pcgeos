COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		NetWare Driver
FILE:		semNW.asm (NetWare semaphore code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version
	Eric	8/92		Ported to 2.0.

DESCRIPTION:
	see Net/semHigh.asm.

RCS STAMP:
	$Id: nwSem.asm,v 1.1 97/04/18 11:48:42 newdeal Exp $

------------------------------------------------------------------------------@
; substituted by nwSimpleSem.asm

if 0

NetWareCommonCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCallOpenSemaphore

DESCRIPTION:	Call NetWare to request that this semaphore be opened. In case
		we are the first to request the semaphore, indicate what the
		initial value for the semaphore should be.

CALLED BY:	

PASS:		es:di	= name of semaphore to open. Must be null-terminated,
			and no longer that NW_SEMAPHORE_NAME_LENGTH chars,
			not including the null-term. We will temporarily
			stuff a byte value at es:[di-1], so make sure (di>0).

		cx	= initial value for semaphore, if NetWare creates
				it with this call. For NW 2.2 and 3.11,
				( 0 <= cx <= 127).

RETURN:		es:di	= same

DESTROYED:	ax, bx, cx, dx, si, bp, ds

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

.assert (offset NREQBUF_OS_semNameLength) eq 0
.assert (offset NREQBUF_OS_semName) eq 1

NetWareCallOpenSemaphore	proc	near
	;find the length of this name

	push	cx
					;pass es:di = null term string
	mov	cx, NW_SEMAPHORE_NAME_LENGTH
					;pass cx = max length for string,
					;	w/out null term
	call	NetWareGetAndStuffStringLength
					;returns es:di = length byte, stuffed
					;temporary before start of name.
					;ah = old value which was there.
					;al = string length
					;trashes cx, dx
	pop	cx

;------------------------------------------------------------------------------
	push	ax			;save byte to repair later

	segmov	ds, es, ax
	mov	dx, di			;pass ds:dx = request buffer

	mov	ax, NFC_OPEN_SEMAPHORE

EC <	cmp	cx, 127			;check for bad initial value	>
EC <	ERROR_A NW_ERROR		;not supported yet!		>

before: ForceRef before

	call	NetWareCallFunction	;call NetWare
					;Also returns cx:dx = sem handle.
after:	ForceRef after

EC <	tst	al			;check completion code		>
EC <	ERROR_NZ NW_ERROR						>

	;repair the byte before the string passed to us.

	pop	ax
EC <	cmp	al, es:[di]		;is length still there?		>
EC <	ERROR_NE NW_ERROR						>

	mov	es:[di], ah		;restore old data value that preceeded
					;the string.

	inc	di			;restore es:di = name
	ret
NetWareCallOpenSemaphore	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareGetAndStuffStringLength

DESCRIPTION:	Determine the length of the passed string, and stuff this
		length value into the byte that preceeds the string in
		memory.

CALLED BY:	misc.

PASS:		es:di	= string (IMPORTANT: di cannot be 0, or we would
			be writing out of this memory block!)

		cx	= maximum length for string, w/out null terminator.

RETURN:		es:di	= pointer to length byte, followed by the string.
			This is the length in chars, without the null term
			at the end of the string.

		al	= count value which has been stored into es:[di].

		ah	= the byte value which existed at es:[di-1].
			Caller must remember to restore this to es:[di].


DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareGetAndStuffStringLength	proc	near
	.enter

EC <	tst	di			;CANNOT be 0 offset. See above	>
EC <	ERROR_Z	NW_ERROR						>
EC <	cmp	cx, 255			;must be 255 or less		>
EC <	ERROR_A NW_ERROR						>

	;make sure that we find a null-term within CX+1 characters.

	mov	dx, di			;es:dx = name
	inc	cx
	clr	al			;search for null term
	repne	scasb			;sets es:di = byte after null term

	;If we found the null-term, then the Z flag is set, and es:di points
	;to the byte AFTER the null term. So (di-dx)-1 is the length of
	;the string, not including the null-term.
	;
	;If we did not find the null-term, then the Z flag is not set.

EC <	ERROR_NE NW_ERROR		;no null term!			>

	sub	di, dx
	dec	di			;di = length w/out null term

	xchg	dx, di			;dx = length
					;es:di = start of name
	dec	di			;back up one byte

	mov	al, dl			;al = length
	mov	ah, dl			;ah = length

	xchg	ah, es:[di]		;get byte which we will overwrite
					;save string length byte here

	.leave
	ret
NetWareGetAndStuffStringLength	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCallWaitOnSemaphore

DESCRIPTION:	

CALLED BY:	

PASS:		cx:dx	= NetWare semaphore handle

RETURN:		cx:dx	= same
		carry set if was not successful (PC/GEOS can not wait on
			NetWare semaphores, because it would stop the whole
			DOS machine.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareCallWaitOnSemaphore	proc	near
	uses	ax, bp
	.enter

	clr	bp			;timeout = 0 (WE NEVER WAIT!)
	mov	ax, NFC_WAIT_ON_SEMAPHORE

before:	ForceRef before
	call	NetWareCallFunction	;call NetWare
after:	ForceRef after

	;check for timeout case

	cmp	al, 0xFE
	stc
	je	done			;skip to end...

EC <	tst	al			;check completion code		>
EC <	ERROR_NZ NW_ERROR						>

	;was successful

	clc

done:
	.leave
	ret
NetWareCallWaitOnSemaphore	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareSignalSemaphore

DESCRIPTION:	

CALLED BY:	

PASS:		cx:dx	= NetWare semaphore handle

RETURN:		cx:dx	= same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareSignalSemaphore	proc	near
	uses	ax
	.enter

	mov	ax, NFC_SIGNAL_SEMAPHORE

before:	ForceRef before
	call	NetWareCallFunction	;call NetWare
after: ForceRef after

EC <	tst	al			;check completion code		>
EC <	ERROR_NZ NW_ERROR						>

	.leave
	ret
NetWareSignalSemaphore	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCloseSemaphore

DESCRIPTION:	

CALLED BY:	

PASS:		cx:dx	= NetWare semaphore handle

RETURN:		cx:dx	= same

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareCloseSemaphore	proc	near
	uses	ax
	.enter

	mov	ax, NFC_CLOSE_SEMAPHORE

before:	ForceRef before
	call	NetWareCallFunction	;call NetWare
after:	ForceRef after

EC <	tst	al			;check completion code		>
EC <	ERROR_NZ NW_ERROR						>

	.leave
	ret
NetWareCloseSemaphore	endp

NetWareCommonCode	ends

endif
