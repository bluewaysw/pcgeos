COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Net Library
FILE:		semaphore.asm (high-level semaphore code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version
	Eric	8/92		Ported to 2.0.

DESCRIPTION:
	See our SPEC document for information about network-based
	semaphores and the support that this library provides.

RCS STAMP:
	$Id: semaphore.asm,v 1.1 97/04/05 01:24:47 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetSemaphoreCode
;------------------------------------------------------------------------------

NetSemaphoreCode	segment	resource	;start of code resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetOpenSem

DESCRIPTION:	Open a network-based semaphore (creating it first if
		necessary), such that the calling application can then
		P() and V() on the semaphore.

PASS:		ds:si	= name for semaphore (null terminated, and up
				to NET_SEMAPHORE_NAME_LENGTH (=124) chars max,
				including null term.)

		cx	= initial value (1 means one P() permitted, etc.)
				Maximum initial value: 127

		dx	= poll interval (# of ticks between attempts
				to grab the semaphore over the network).
				If you set this to 0, it means that no
				process will EVER wait for the semaphore.
				All PSem operations will ignore the
				timeout value passed, and return immediately
				if the semaphore cannot be grabbed.

		bx	= PSP under which to open the semaphore, or
			   	0 to just use our own PSP.

	FUTURE:
		bp	= scope: (4 is the only value permitted for now)
				0	pc/geos-wide (redundant?)
				2	workstation-wide
				4	server-wide
				8	LAN-wide (possible?)
				12	WAN-wide (possible?)

RETURN:		ds, es	= same
		carry flag set if error (ax = error code)
		cx	= handle for semaphore (actually a PC/GEOS LMem handle)

DESTROYED:	dx, si, di, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetOpenSem	proc	far
	uses	es, di
	.enter

	;pass this request on to the specific network driver.

	segmov	es, <segment dgroup>, ax
	mov	di, DR_NET_SEMAPHORE_FUNCTION
	mov	al, NSF_OPEN
	call	NetCallDriver

	.leave
	ret
NetOpenSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetPSem

DESCRIPTION:	Wait on a network-based semaphore, for a specified amount
		of time. Must have already opened the semaphore using
		NetOpenSem.

PASS:		cx	= handle for semaphore (the value returned from
			NetOpenSem, which is actually a PC/GEOS LMem handle)

		dx	= timeout value (# of ticks before we will give
				up waiting on this semaphore). Note that if
				the semaphore was created with a poll interval
				of 0, then this timeout value is ignored
				(assumed to be 0).

RETURN:		carry flag set if timeout
		cx	= same

DESTROYED:	nothing (what about ax, bx, since we are a movable lib?)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetPSem	proc	far
	uses	es, di
	.enter

	;pass this request on to the specific network driver.

	segmov	es, <segment dgroup>, ax
	mov	di, DR_NET_SEMAPHORE_FUNCTION
	mov	al, NSF_P
	call	NetCallDriver

	.leave
	ret
NetPSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetVSem

DESCRIPTION:	Release (signal) a network-based semaphore.
		Must have already opened the semaphore using NetOpenSem.

PASS:		cx	= handle for semaphore (the value returned from
			NetOpenSem, which is actually a PC/GEOS LMem handle)

RETURN:		cx	= same

DESTROYED:	nothing (what about ax, bx, since we are a movable lib?)

PSEUDO CODE/STRATEGY:
	PSem(SemVars)
	use the passed semaphore handle to find the item for this semaphore
		in our list. (It is an LMem handle, so this just means
		indirect to get the offset of the chunk.)

	get NetWare handle for the server-based semaphore
	VSem(SemVars)

	call NetWare "Signal Semaphore".

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetVSem	proc	far
	uses	es, di
	.enter

	;pass this request on to the specific network driver.

	segmov	es, <segment dgroup>, ax
	mov	di, DR_NET_SEMAPHORE_FUNCTION
	mov	al, NSF_V
	call	NetCallDriver

	.leave
	ret
NetVSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetCloseSem

DESCRIPTION:	Close a network-based semaphore. Actually, all that we
		are doing is decrementing the in-use count for the specified
		semaphore. If it reaches 0, it means that no threads in
		this instance of PC/GEOS are using the semaphore anymore,
		and we can tell NetWare to "close" the semaphore. If no
		other workstations have the semaphore open, NetWare will
		free the semaphore from the server's memory.

PASS:		cx	= handle for semaphore (the value returned from
			NetOpenSem, which is actually a PC/GEOS LMem handle)

RETURN:		ds, es, cx = same

DESTROYED:	nothing (what about ax, bx, since we are a movable lib?)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetCloseSem	proc	far
	uses	es, di
	.enter

	;pass this request on to the specific network driver.

	segmov	es, <segment dgroup>, ax
	mov	di, DR_NET_SEMAPHORE_FUNCTION
	mov	al, NSF_CLOSE
	call	NetCallDriver

	.leave
	ret
NetCloseSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetVAllSem

DESCRIPTION:	Release (signal) a network-based semaphore, repeating the
		operation until the value is equal to the initial semaphore
		value.

		WARNING: this should only be used for one "master" PC/GEOS
			thread to signal a number of "slave" threads across
			the network.

			If any of the slave threads were to attempt to
			VSem or VSemAll the semaphore, the semaphore may
			end up with a value greater than its initial value.

PASS:		cx	= handle for semaphore (the value returned from
			NetOpenSem, which is actually a PC/GEOS LMem handle)

RETURN:		cx	= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetVAllSem	proc	far
	uses	es, di
	.enter

	;not written yet

	.leave
	ret
NetVAllSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetInfoSem

DESCRIPTION:	Get information about a network-based semaphore.

PASS:		cx	= handle for semaphore (the value returned from
			NetOpenSem, which is actually a PC/GEOS LMem handle)

RETURN:	

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetInfoSem	proc	far
	uses	es, di
	.enter

	;not written yet

	.leave
	ret
NetInfoSem	endp

NetSemaphoreCode	ends
