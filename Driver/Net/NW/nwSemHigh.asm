COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		PC/GEOS NetWare Driver
FILE:		semHigh.asm (high-level NetSem code)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version
	Eric	8/92		Ported to 2.0.

DESCRIPTION:
	This file contains code for the semaphore facilities provided
	by the Net library.

	IMPORTANT: see netware.def for information on some bugs in NetWare
	that relate to semaphores.

	See our SPEC document on why we also need to provide a higher-level
	interface to network-based semaphores.

RCS STAMP:
	$Id: nwSemHigh.asm,v 1.1 97/04/18 11:48:40 newdeal Exp $

------------------------------------------------------------------------------@
;substituted by nwSimpleSem.asm


;------------------------------------------------------------------------------
;			Structure Definitions
;------------------------------------------------------------------------------

if 0
;if NW_SEMAPHORES

INITIAL_SEM_DATA_BLOCK_SIZE	equ	(size NetSemDataBlockStruct) + \
					(size NetSemDataItem)*4

NSDB_PROTECT	equ	0x6723

NetSemDataBlockStruct	struct

    ;LMemHeader (this MUST be here!)

    NSDB_LMemHeader		LMemBlockHeader
   
    NSDB_protect		word
    NSDB_semList		lptr	;chunkarray containing lptrs to
					;NetSemDataItems.
NetSemDataBlockStruct	ends

;HACK FOR V1.2 (under V2.0, you can allocate semaphores on the heap)

AccessSemaphoreHandle	type	word	;will be hptr.Semaphore

NSDI_PROTECT	equ	0xBAF0

NetSemDataItem	struct
EC <NSDI_protect		word					>

    NSDI_pollInterval		word	;set to 0 for the first item in the list
					;which is a dummy item to simplify
					;deletes.

    NSDI_scope			word	;for future use

    NSDI_accessSem		AccessSemaphoreHandle
					;handle of PC/GEOS-based Access
					;Semaphore

    NSDI_netBasedSem		NetWareSemaphore
					;CHANGE THIS

    NSDI_inUseCount		word

    ;name starts here, and continues until end of chunk. Is null terminated.

    NSDI_nameRoot		char 4 dup (?)	;'GWAA'

    NSDI_name	label	byte

NetSemDataItem	ends

endif

if 0


;------------------------------------------------------------------------------
;				IDATA Resource
;------------------------------------------------------------------------------

idata	segment			;Fixed resource

;------------------------------------------------------------------------------
;THE FOLLOWING VARIABLES are controlled by the semDataSem semaphore.

semDataSem	Semaphore <1, 0>
				;semaphore controlling access to semData block

semData		hptr.SemDataStruct
				;handle of LMem block which contains semaphore
				;information.

HACK_MAX_NUM_ACCESS_SEMAPHORES equ 20

.assert (size Semaphore) eq (size dword)

hackAccessSemFlags	dword HACK_MAX_NUM_ACCESS_SEMAPHORES dup (0)
				;non-zero if corresponding semaphore
				;is allocated.

;end of semaphore-controlled data
;------------------------------------------------------------------------------

;This list of semaphores is NOT protected by the semDataSem semaphore, because
;threads need to block on semaphores in this list, WITHOUT hanging onto
;the semDataSem semaphore. Note:
;
;	- a thread will not attempt to block on a semaphore in this list,
;	until it has been granted permission to use that semaphore, by code
;	in NetOpenSem which (while holding the semDataSem semaphore) marks
;	the hackAccessSemFlags array, indicating that this semaphore is
;	allocated.
;
;	- a thread will not call NetCloseSem, and then NetPSem,
;	so we are assured that in our code in NetPSem which blocks on
;	a semaphore in this list WILL NEVER do so after the semaphore has
;	been freed from the list.
;
;	- For 2.0, we will not need this list of semaphores, as we will
;	allocate semaphores in the handle table. Regardless, the same
;	assertions hold true.

hackAccessSemList	Semaphore HACK_MAX_NUM_ACCESS_SEMAPHORES dup (<1,0>)

idata	ends

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles all net semaphore calls

CALLED BY:	NetWareStrategy
PASS:		al - NetWareSemaphoreFunction to call
RETURN:		returned from called proc
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	11/ 6/92    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment	resource	;start of code resource
NetWareSem	proc	near
	call NetWareSemInternal
	ret
NetWareSem	endp
NetWareResidentCode	ends

NetWareCommonCode	segment	resource
NetWareSemInternal	proc	far
	clr	ah
	mov_tr	di, ax

EC <	cmp	di, NetSemaphoreFunction	>
EC <	ERROR_AE NW_ERROR_INVALID_DRIVER_FUNCTION			>

	call	cs:[netWareSemaphoreCalls][di]
	ret
NetWareSemInternal	endp

netWareSemaphoreCalls	nptr	\
	offset	NetWareOpenSem,
	offset	NetWarePSem,
	offset	NetWareVSem,
	offset	NetWareCloseSem

.assert (size netWareSemaphoreCalls eq NetSemaphoreFunction)
NetWareCommonCode	ends

NetWareCommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareOpenSem

DESCRIPTION:	Open a network-based semaphore (creating it first if
		necessary), such that the calling application can then
		P() and V() on the semaphore.

PASS:		ds:si	= name for semaphore (null terminated, and up
				to NET_SEMAPHORE_NAME_LENGTH (~128) chars max,
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
		(what about ax, bx, since we are a movable lib?)

DATA STRUCTURES:
	Almost all of the information about the semaphores known to this
	instance of PC/GEOS is kept in a local heap. A semaphore ("SemVars")
	controls access to this list of semaphores.

	For each semaphore in the local heap, we have an LMem chunk which
	contains:

		semaphore name
		poll interval
		scope
		handle for the Access Semaphore for this Semaphore.
		NetWare handle for this semaphore
		chunk handle of the next item in the list.

	For each Net Semaphore we track, we have a local PC/GEOS-based
	semaphore called the "Access Semaphore". This semaphore controls
	access to the Net Semaphore. When more than one thread is waiting
	on the Net Semaphore, the Access Semaphore ensures that only one
	of the threads is permitted to poll the Net Semaphore, and that
	the other threads are kept in an ordered queue.

PSEUDO CODE/STRATEGY:
	PSem(SemVars)
	search for semaphore name in list
	if found {
		increment in-use count
	} else {
		create a new item in our list, and fill in:
			semaphore name string
			poll interval
			scope value
			set in-use count to 1

		call the Novell driver (or equiv.) to really open this
			Net Semaphore. It will return a Novell Handle for it.

		save the Novell Handle value in our list.

		allocate a PC/GEOS-based Access Semaphore, and save its
			handle in our list.
	}
	return the handle of this Net Semphore (LMem handle)
	VSem(SemVars)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NOS_Frame	struc
    NOS_pollInterval	word
    NOS_initialValue	word
    NOS_name		fptr
;   NOS_scope		word
NOS_Frame	ends

NetWareOpenSem	proc	near

;did not work! BP was pushed above stack frame, and then all offsets into
;stack frame were off by 2 bytes. When I tried to grab dword value from
;NOS_name, I got si:cx rather than ds:si.
;	vars	local	NOS_Frame	push	bp	\
;					push	ds	\
;					push	si	\
;					push	cx	\
;					push	dx

	vars	local	NOS_Frame	push	ds	\
					push	si	\
					push	cx	\
					push	dx

	.enter

	;get exclusive access to our SemData block

	segmov	es, <segment dgroup>, ax
	PSem	es, semDataSem, TRASH_AX_BX

	call	NetWareOpenSemGetSemDataBlock
					;(creates and) locks SemData block.
					;returns *ds:si = list

	;scan the block for a semaphore having the same exact name

	clr	dx			;default: not found
	mov	bx, cs
	mov	di, offset NetWareOpenSem_FindItemByNameCallback
	call	ChunkArrayEnum		;returns *ds:dx = chunk

	tst	dx			;find it?
	jz	createNew		;skip if not...

	;up the in-use count for this item

	mov	si, dx
	mov	si, ds:[si]		;ds:si = NetSemDataItem

EC <	cmp	ds:[si].NSDI_protect, NSDI_PROTECT			>
EC <	ERROR_NE NW_ERROR						>

	inc	ds:[si].NSDI_inUseCount
	mov	cx, dx			;return cx = chunk handle
	jmp	short unlockBlock

createNew:
	;create a new NetSemDataItem, and call our Network driver to
	;actually open this semaphore on the server.
	;	ds	= SemDataBlock

	call	NetWareOpenSem_CreateNewItem
					;returns ax = item chunk handle

EC <	cmp	ds:[NSDB_protect], NSDB_PROTECT				>
EC <	ERROR_NE NW_ERROR						>

	;save the chunk handle of this new item into our chunk array

	mov	si, ds:[NSDB_semList]
	call	ChunkArrayAppend
	mov	ds:[di]+0, ax
	mov	cx, ax			;return cx = chunk handle

unlockBlock:
	;unlock the SemData block

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	;release the SemData block

	segmov	es, <segment dgroup>, ax
	VSem	es, semDataSem, TRASH_AX_BX

	mov	ax, vars.NOS_name.segment
	mov	ds, ax			;restore ds = segment for name

	clc				;no errors yet

	.leave
	ret
NetWareOpenSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWarePSem

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

PSEUDO CODE/STRATEGY:
	PSem(SemVars)
	use the passed semaphore handle to find the item for this semaphore
		in our list. (It is an LMem handle, so this just means
		indirect to get the offset of the chunk.)
	get NetWare handle for the server-based semaphore
	get the handle of the Access Semaphore from this item.
	get the polltime from this item.
	VSem(SemVars)

	startTime = current system time

	PSem(AccessSemaphore)	/* sleep until we are "At Bat", or timeout */

	if (timeout) {
		return carry set, indicating TIMEOUT.
	} else {
	    /* We are now "At Bat", meaning we have the exclusive right
	    /* in this instance of PC/GEOS to attempt to grab the
	    /* Novell semaphore, and to poll until we get it.

	    repeat {

		call NetWare "Wait On Semaphore", with a timeout of 0.

		if (successful) {
			/* we have grabbed the Novell semaphore */

			VSem(AccessSemaphore)		/* next "Batter Up" */
			return(SUCCESS)

		} else {
			/* we did not get the semaphore. Will have to poll */

			if ((currentTime+polltime) > (starttime+timeout)) {
				VSem(AccessSemaphore)	/* next "Batter Up" */
				return(TIMEOUT)

			} else {
				/* sleep for a while, at bat, and then try
				 * again. */

				sleep(polltime)
			}
		}
	    } /* loop forever */

	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetPSem_Frame	struc
EC <NPSF_semHandle		lptr		;may be useful		>
EC <NPSF_timeout		word		;may be useful		>

    NPSF_pollInterval		word		;how often we poll for this
						;semaphore.

    NPSF_failTime		dword		;system time when we should fail
NetPSem_Frame	ends


NetWarePSem	proc	near
	uses	cx, dx, bp, si, di, ds, es
	vars	local	NetPSem_Frame

	.enter

	;save some info, in case we do a backtrace to see why this thread
	;is blocked later on.

EC <	mov	vars.NPSF_semHandle, cx					>
EC <	mov	vars.NPSF_timeout, dx					>

	;get exclusive access to our SemData block

	segmov	es, <segment dgroup>, ax
	PSem	es, semDataSem, TRASH_AX_BX

	call	NetWareOpenSemGetSemDataBlock
					;(creates and) locks SemData block.
					;returns *ds:si = list
					;does not trash dx

EC <	call	ECNetWareCheckSemHandle	;verify cx as LMem handle for sem >

	;grab some data from this NetSemDataItem, then release our exclusive
	;lock on this data (we MUST NOT block while holding this block.)

	mov	si, dx			;si = timeout interval

	mov	di, cx			;*ds:di = NetSemDataItem
	mov	di, ds:[di]		;ds:di = NetSemDataItem

	mov	ax, ds:[di].NSDI_pollInterval
	mov	vars.NPSF_pollInterval, ax

	mov	cx, ds:[di].NSDI_netBasedSem.high
	mov	dx, ds:[di].NSDI_netBasedSem.low

	mov	di, ds:[di].NSDI_accessSem

	;unlock the SemData block

	call	MemUnlock

	;release the SemData block

	VSem	es, semDataSem, TRASH_AX_BX

	;get the current system time, and record it as when we started
	;to wait for this semaphore

	call	TimerGetCount		;returns bx:ax = current time in ticks
	add	ax, si			;set bx:ax = time when we should fail
	adc	bx, 0

	mov	vars.NPSF_failTime.high, bx
	mov	vars.NPSF_failTime.low, ax

	;PSem(AccessSemaphore, timeout)	-sleep until we are "At Bat", or timeout

	PTimedSem es, [di], si, TRASH_AX_BX
	jc	done			;skip to end if timeout (no need to
					;release Access Semaphore)...

	;We are now "At Bat", meaning we have the exclusive right
	;in this instance of PC/GEOS to attempt to grab the
 	;Novell semaphore, and to poll until we get it.

attemptToGrabNetSemaphore:
	;call NetWare "Wait On Semaphore", with a timeout of 0.

					;pass cx:dx = NetWare semaphore handle
	call	NetWareCallWaitOnSemaphore
	jnc	haveResult		;skip if successful...

	;have to sleep for a while, and try again. (We hang on to the
	;AccessSemaphore the whole time, because we are first in line,
	;remember.) First, see by sleeping, we will exceeded the total
	;poll time.

	call	TimerGetCount		;returns bx:ax = current time in ticks

	cmp	bx, vars.NPSF_failTime.high
	jb	takeANap
	ja	reachedFailTime		;exceeded time...

	cmp	ax, vars.NPSF_failTime.low
	jae	reachedFailTime		;exceeded time...

takeANap:
	;sleep for a while (while holding the access semaphore), and
	;then try again.

	mov	ax, vars.NPSF_pollInterval
	call	TimerSleep
	jmp	short attemptToGrabNetSemaphore
					;loop to try again...
	
reachedFailTime:
	stc

haveResult:
	;release the AccessSemaphore, and return the carry flag set if
	;we timed out.

	pushf
	VSem	es, [di], TRASH_AX_BX
	popf

done:	;return with carry set if we timed out (either waiting on the
	;access semaphore, or while polling for the net-based semaphore.)

	.leave
	ret
NetWarePSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareVSem

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

NetWareVSem	proc	near
	uses	cx, dx, di, ds, es
	.enter

	;get exclusive access to our SemData block

	segmov	es, <segment dgroup>, ax
	PSem	es, semDataSem, TRASH_AX_BX

	call	NetWareOpenSemGetSemDataBlock
					;(creates and) locks SemData block.
					;returns *ds:si = list
					;does not trash dx

EC <	call	ECNetWareCheckSemHandle	;verify cx as LMem handle for sem >

	;grab some data from this NetSemDataItem, then release our exclusive
	;lock on this data.

	mov	di, cx			;*ds:di = NetSemDataItem
	mov	di, ds:[di]		;ds:di = NetSemDataItem

	mov	cx, ds:[di].NSDI_netBasedSem.high
	mov	dx, ds:[di].NSDI_netBasedSem.low

	;unlock the SemData block

	call	MemUnlock

	;release the SemData block

	VSem	es, semDataSem, TRASH_AX_BX

	;release the Net-based semaphore

					;pass cx:dx = NetSemaphore
	call	NetWareSignalSemaphore

	.leave
	ret
NetWareVSem	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCloseSem

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

PSEUDO CODE/STRATEGY:
	PSem(SemVars)
	use the passed semaphore handle to find the item for this semaphore
		in our list. (It is an LMem handle, so this just means
		indirect to get the offset of the chunk.)

	decrement the in-use count
	if 0 {
		get NetWare handle for the server-based semaphore
		call NetWare to "Close" this semaphore.
		remove this item from the linked list.
		free the LMem chunk containing info about this semaphore
	}
	VSem(SemVars)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareCloseSem	proc	near
	uses	dx, si, di, bp, ds, es
	.enter

	;get exclusive access to our SemData block

	segmov	es, <segment dgroup>, ax
	PSem	es, semDataSem, TRASH_AX_BX

	call	NetWareOpenSemGetSemDataBlock
					;(creates and) locks SemData block.
					;returns *ds:si = list
					;does not trash dx

EC <	call	ECNetWareCheckSemHandle	;verify cx as LMem handle for sem >

	;decrement the in-use count for this NetSemDataItem

	mov	di, cx			;*ds:di = NetSemDataItem
	mov	di, ds:[di]		;ds:di = NetSemDataItem

EC <	cmp	ds:[di].NSDI_protect, NSDI_PROTECT			>
EC <	ERROR_NE NW_ERROR						>

	dec	ds:[di].NSDI_inUseCount
EC <	ERROR_S	NW_ERROR		;went negative!			>

	LONG jnz unlockBlock		;skip if other threads still want
					;this net semaphore from this
					;machine's perspective.

closeNetSemaphore:
	ForceRef closeNetSemaphore

	;tell NetWare to close this semaphore (other machines may still
	;have it open), and then nuke our NetSemDataItem.

	push	cx
	mov	cx, ds:[di].NSDI_netBasedSem.high
	mov	dx, ds:[di].NSDI_netBasedSem.low
	call	NetWareCloseSemaphore
	pop	cx


	;make sure we are still pointing to the item, and dgroup

EC <	call	ECCheckDGroupES		;make sure es = dgroup		>

EC <	mov	di, cx							>
EC <	mov	di, ds:[di]						>
EC <	cmp	ds:[di].NSDI_protect, NSDI_PROTECT			>
EC <	ERROR_NE NW_ERROR						>

	;free the Access Semaphore, for use by other net semaphores

	mov	di, ds:[di].NSDI_accessSem
					;es:di = access semaphore

EC <	cmp	es:[di].Sem_value, 1	;no threads should be using	>	
EC <	ERROR_NE NW_ERROR						>
EC <	cmp	es:[di].Sem_queue, 0	;or blocked on this sem.	>
EC <	ERROR_NE NW_ERROR						>

	sub	di, (offset dgroup:hackAccessSemList) - \
		    (offset dgroup:hackAccessSemFlags)
					;es:di = access flag

EC <	cmp	word ptr es:[di], 1					>
EC <	ERROR_NE NW_ERROR						>

	mov	word ptr es:[di], 0

	;free the NetSemDataItem from the LMem heap

	mov	ax, cx
	call	LMemFree

	;find this chunk handle in our chunkarray, and nuke that item.

	mov	si, ds:[NSDB_semList]
	call	NetWareSemFindSemInList	;returns ds:di = item
EC <	ERROR_NC NW_ERROR		;fail if not found		>

	call	ChunkArrayDelete

	;see if we should just free the block

	call	ChunkArrayGetCount
	tst	cx
	jnz	unlockBlock		;skip if still have open semaphores...

freeSemDataBlock:
	ForceRef freeSemDataBlock

	;free this SemDataBlock

EC <	call	ECCheckDGroupES		;make sure es = dgroup		>

	call	MemFree
	clr	es:[semData]
	jmp	short done

unlockBlock:
	;unlock the SemData block

	call	MemUnlock

done:
	;release the SemData block

EC <	call	ECCheckDGroupES		;make sure es = dgroup		>
	VSem	es, semDataSem, TRASH_AX_BX

	.leave
	ret
NetWareCloseSem	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareVAllSem

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
if 0
NetWareVAllSem	proc	near
	.enter

	;not written yet

	.leave
	ret
NetWareVAllSem	endp
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareInfoSem

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
if 0
NetWareInfoSem	proc	near
	.enter

	;not written yet

	.leave
	ret
NetWareInfoSem	endp
endif

if 0
NetWareCommonCode	ends
endif

