COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		NetWare Driver
FILE:		resident.asm


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version
	Eric	8/92		Ported to 2.0

DESCRIPTION:
	This file contains SOME of the resident code for this driver.
	See other .asm files for more.


RCS STAMP:
	$Id: nwResident.asm,v 1.1 97/04/18 11:48:42 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			NetWareResidentCode
;------------------------------------------------------------------------------

NetWareResidentCode	segment	resource	;start of code resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareStrategy

DESCRIPTION:	This is the main strategy routine for this driver.

CALLED BY:	Net Library, applications...

PASS:		di	= NetDriverFunctions enum

RETURN:		carry set if error

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareStrategy	proc	far

	;check the function code

	cmp	di, NetDriverFunction
	jae	badCall

	;seems ok. Some more EC:

EC <	test	di, 1							>
EC <	ERROR_NZ NW_ERROR_INVALID_DRIVER_FUNCTION			>

EC <	tst	cs:[NetDriverProcs][di]					>
EC <	ERROR_Z NW_ERROR						>

	;call the function:

	call	cs:[NetDriverProcs][di]
	ret

badCall: ;Error: function code is illegal.

EC <	ERROR	NW_ERROR_INVALID_DRIVER_FUNCTION			>

NEC <	stc								>
NEC <	ret								>

NetWareStrategy endp

NetDriverProcs	nptr.near	\
	NetWareResidentCode:NetWareInit,
	NetWareResidentCode:NetWareExit,
	NetWareResidentCode:NetWareSuspend,
	NetWareResidentCode:NetWareUnsuspend,
	NetWareResidentCode:NetWareUserFunction,
	NetWareResidentCode:Stub,		; NetWareInitializeHECB
	NetWareResidentCode:Stub,		; NetWareSendHECB
	NetWareResidentCode:NWSimpleSem, 	; was: NetWareSem
	NetWareResidentCode:NetWareGetDefaultConnectionID,
	NetWareResidentCode:NetWareGetServerNameTable,
	NetWareResidentCode:NetWareGetConnectionIDTable,
	NetWareResidentCode:NetWareScanForServer,
	NetWareResidentCode:NWServerAttach,
	NetWareResidentCode:NWServerLogin,
	NetWareResidentCode:NWServerLogout,
	NetWareResidentCode:NWServerChangeUserPassword,
	NetWareResidentCode:NWServerVerifyUserPassword,
	NetWareResidentCode:NWServerGetNetAddr,
	NetWareResidentCode:NWServerGetWSNetAddr,
	NetWareResidentCode:NWMapDrive,
	NetWareResidentCode:Stub, 	; DR_NET_MESSAGING
	NetWareResidentCode:NetWarePrint,
	NetWareResidentCode:NetWareObject,
	NetWareResidentCode:NetWareTextMessage,
	NetWareResidentCode:NetWareGetVolumeName,
	NetWareResidentCode:NetWareGetDriveCurrentPath,
	NetWareResidentCode:Stub,		; NetWareGetStationAddress
	NetWareResidentCode:NWUnmapDrive

.assert	(size NetDriverProcs	eq NetDriverFunction)

Stub 	proc near
	ret
Stub	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareInit

DESCRIPTION:	

CALLED BY:	NetWareStrategy

PASS:		
;	PASS:	cx	= di passed to GeodeLoad. Garbage if loaded via
;			  GeodeUseDriver
;		dx	= bp passed to GeodeLoad. Garbage if loaded via
;			  GeodeUseDriver
;	RETURN:	carry set if driver initialization failed. Driver will be
;			unloaded by the system.
;		carry clear if initialization successful.
;
;	DESTROYS:	bp, ds, es, ax, di, si, cx, dx

RETURN:		carry set if error

DESTROYED:	all regs

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareInit	proc	near

	;by default: IPX and the NetWare shell are not around

	segmov	ds, <segment dgroup>, ax
	mov	ds:[ipxPresent], FALSE
	mov	ds:[netwarePresent], FALSE

	;first, make sure we are running on DOS 3.0 or better
	;(or else int 2Fh will do nothing!)

	mov	ax, 0x3000
	call	FileInt21		;returns [al, ah] = DOS version #
	cmp	al, 0x03		;at or above DOS 3.0?
	jb	done			;skip if not (CY=1)...

	;see if IPX exists. If not, then there is no possible
	;way that NetWare is around.

	call	NetWareGetIPXEntryPoint
	jc	done			;skip to end if error...

EC <	call	ECCheckDGroupDS		;assert ds = dgroup		>
	mov	ds:[ipxPresent], TRUE

	;now see if the NetWare shell's ConnectionIDTable is accessible

	push	es
	clr	ax			;default: segment = nil
	mov	es, ax
	mov	ax, NFC_GET_CONNECTION_ID_TABLE
	call	NetWareCallFunction	;es:si = ConnectionIDTable

	mov	ax, es
	pop	es

	tst	ax			;is the shell present?
	stc
	jz	done			;skip if not...

	;YES: IPX and the NetWare shell are present

EC <	call	ECCheckDGroupDS		;assert ds = dgroup		>
	mov	ds:[netwarePresent], TRUE

	;now handle more detailed initialization

if NW_SOCKETS
	CallMod	NetWareInitVarsBlock
endif

;Moved this call up to the Net Library, so that 1) it can control
;whether we open the socket or not for each specific network driver,
;and 2) because the Net Library has not yet recorded the address of our
;strategy routine, and calling NetWareOpenMainSocket calls a Net Library
;function which attempts to call the NW Driver.
;
;if NW_GEOWORKS_STATIC_SOCKET
;	;open the main GeoWorks socket on this workstation, so that
;	;we can receive incoming messages.
;
;	CallMod	NetWareOpenMainSocket
;endif

if NW_TEXT_MESSAGES
	;tell the NetWare shell that messages from the console should be
	;held at the server, because we will be polling for them.

	CallMod	NetWareGrabAllAlerts
endif

	clc				;no error
	call	RegisterNWDriver	

done:
	ret
NetWareInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegisterNWDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register ourself to the net Library

CALLED BY:	NetWareInit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ISR	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
netwareDomainName	char 	"NETWARE",0

RegisterNWDriver	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	segmov	ds, cs, si
	mov	si, offset netwareDomainName
	mov	cx, cs
	mov	dx, offset cs:NetWareStrategy	; cx:dx - strategy routine
	mov	bx, handle 0	
	call	NetRegisterDomain
	.leave
	ret
RegisterNWDriver	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareExit

DESCRIPTION:	

CALLED BY:	NetWareStrategy

;	PASS:	nothing
;	RETURN:	nothing
;	DESTROYS:	ax, bx, cx, dx, si, di, ds, es
;
;	NOTES:	If the driver has GA_SYSTEM set, the handler for this function
;		*must* be in fixed memory and may not use anything in movable
;		memory.

DESTROYED:	all regs.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareExit	proc	near

;Moved this call up to the Net Library, so that 1) it can control
;whether we close the socket or not for each specific network driver.
;
;if NW_GEOWORKS_STATIC_SOCKET
;	;close the main GeoWorks socket.
;
;	CallMod	NetWareCloseMainSocket
;endif

;NOT SUPPORTED YET
;if NW_SOCKETS
;	;close all remaining static and dynamic sockets
;
;	call	NetWareCloseAllSockets
;endif


if NW_TEXT_MESSAGES
	;tell the NetWare shell to once again display messages from the console
	;on the 25th line on the DOS character screen.

	segmov	ds, <segment dgroup>, ax	;ds = dgroup
	clc					;pass flag: DO stop timer.
	call	NetWareReleaseAllAlerts
endif

if NW_SOCKETS
	;nuke vars block (ds = dgroup)

	call	NetWareNukeVarsBlock
endif

	clc
	ret
NetWareExit	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareSuspend

DESCRIPTION:	This routine is called by the Net Library, when a V1.2
		task switcher driver (TaskMax, B&F, DOS5) is preparing to
		switch.

IMPORTANT:	Due to the nature of the call to this routine, we must NOT:
		    - take too long
		    - attempt to grab any semaphores, or block for any reason
		    - call any routines which are not fixed.

		It is OK to:
		    - call FileGrabSystem for the DOS lock (because
		    TaskPrepareForSwitch has already grabbed the
		    DOS thread-lock, so our call will just be a nested
		    lock, which is ok.)

CALLED BY:	NetWareStrategy

;	SYNOPSIS:	Prepare the device for going into stasis while PC/GEOS
;			is task-switched out. Typical actions include disabling
;			interrupts or returning to text-display mode.
;
;	PASS:	cx:dx	= buffer in which to place reason for refusal, if
;			  suspension refused (DRIVER_SUSPEND_ERROR_BUFFER_SIZE
;			  bytes long)
;	RETURN:	carry set if suspension refused:
;			cx:dx	= buffer filled with null-terminated reason,
;				  standard PC/GEOS character set.
;		carry clear if suspension approved
;	DESTROYS:	ax, di
;

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareSuspend	proc	near

if NW_TEXT_MESSAGES
	;tell the NetWare shell to once again display messages from the console
	;on the 25th line on the DOS character screen.

	segmov	ds, <segment dgroup>, ax	;ds = dgroup
	stc					;pass flag: DO NOT stop timer.
	call	NetWareReleaseAllAlerts		;MUST be in resident resource
endif

	;finish up

	clc
	ret
NetWareSuspend	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareUnsuspend

DESCRIPTION:	

CALLED BY:	NetWareStrategy

;	SYNOPSIS:	Reconnect to the device when PC/GEOS is task-switched
;			back in.
;
;	PASS:	nothing
;	RETURN:	nothing
;	DESTROYS:	ax, di
;

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

NetWareUnsuspend	proc	near

if NW_TEXT_MESSAGES
	;tell the NetWare shell to once again display messages from the console
	;on the 25th line on the DOS character screen.

	segmov	ds, <segment dgroup>, ax	;ds = dgroup
	CallMod	NetWareGrabAllAlerts
endif

	clc
	ret
NetWareUnsuspend	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareAllocRRBuffers

DESCRIPTION:	In preparation for a typical call to NetWare, allocate
		empty request and reply buffers. The caller will fill
		in the request buffer, and then use NetWareCallFunctionRR.
		The result buffer can then be examined, and biffed.

		This routine will allocate the request and reply buffers
		in the same block on the global heap, placing some additional
		information at the beginning of the block.

		IMPORTANT: after calling NetWare, the caller of this routine
		has ultimate responsibility for nuking this memory block.

CALLED BY:	INTERNAL

PASS:		bx	= size of Request buffer (including initial size word)
		cx	= size of Reply buffer (including initial size word)
						(can be 0, for no reply buffer)

RETURN:		cx	= same
		^hbx	= block containing both the Reply and Request buffers,
				which is currently LOCKED on the heap.
				(The handle is also stored in the block,
				for convenience in later freeing the block.)
		es:si	= Request Buffer
		es:di	= Reply Buffer 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareAllocRRBuffers	proc	far
	uses	ax
	.enter

	;allocate a block on the global heap to hold both the request and
	;the reply buffers.

	push	bx, cx
	add	bx, cx	 		;bx = total size for block
	add	bx, (offset NRR_requestSize)
					;add room at beginning of block
					;for handle, protect byte(s).

	;first, allocate a global memory block to hold our local memory heap

	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
					;allocate as HF_SWAPABLE and HAF_LOCK
	mov	ax, bx
	call	MemAlloc		;returns bx = handle of block
	mov	es, ax

	mov	es:[NRR_handle], bx	;save handle of block, so can free
					;it later on.
EC <	mov	es:[NRR_protect]+0, 'RR';save protect word		>
	pop	ax, cx

	;stuff the sizes of each of the buffers into the correct field
	;in each buffer. Use Lo-Hi format, since we are running on PCs.

	mov	es:[NRR_requestSize], ax
	sub	es:[NRR_requestSize], size word

	;don't stuff the reply buffer size, if it is 0

	mov	si, offset NRR_requestSize

	jcxz	done

	mov	di, si
	add	di, ax
	mov	word ptr es:[di]+0, cx
	sub	word ptr es:[di]+0, size word

done:
	.leave
	ret
NetWareAllocRRBuffers	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCallFunctionRR

DESCRIPTION:	Call a NetWare function which expects to be passed
		a request and reply buffer. This routine will fill in
		some common fields in the reply buffer, call the NetWare
		function, and verify that the reply buffer has been properly
		returned by NetWare.

		The result buffer can then be examined, and biffed.

		NOTE: upon return, the caller can use this same Request/
		Reply buffer pair again, to call a NetWare function in a
		loop, for example. You can safely assume that nothing in
		the Request buffer has changed (unless NetWare changes it).

		As for the Reply buffer, NetWare may have made it smaller,
		by changing the size value which is stored at the beginning
		of that buffer (the actual block on the global heap,
		which contains both the request and reply buffers, will still
		be the same size).

		Be sure to reset the size of the reply buffer back to
		the expected maximum size:

			mov	word ptr es:[di]+0, MAX_REPLY_SIZE

CALLED BY:	INTERNAL

PASS:		ax	= function code & subcode.
				High byte will be passed in AH, 
				low byte will be passed in DL & also
				in the request buffer
		es:si	= Request Buffer
		es:di	= Reply Buffer
		bx, cx, dh, bp = other registers to pass onto NetWare.

RETURN:		al	= completion code
		CARRY SET if al is nonzero

DESTROYED:	dl, nothing else.

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

NetWareCallFunctionRR	proc	far
	uses	ds
	.enter
	segmov	ds, es
	mov	ds:[si].NREQBUF_subFunc, al
					;save function sub-code into
					;the request buffer, after the
					;size word.

	call 	NetWareCallFunctionAX
	.leave
	ret
NetWareCallFunctionRR	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NetWareCallFunctionAX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call NetWare via int 21h

IMPORTANT:	This routine must not block on anything except the DOS
		semaphore, so that task switching works properly.

CALLED BY:	internal

PASS:		ax - NetWareFunctionCode -- low byte will be passed to
			NetWare in DL

RETURN:		values returned from function called
		IF ERROR:
			carry set
		ELSE:
			carry clear

DESTROYED:	dl (contains low byte of NetWareFunctionCode)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareCallFunctionAX	proc far

	;
	; Some NOVELL functions require the subfunction to be passed
	; in DL, and some require it to be passed in AL.  To be safe,
	; pass it in both:
	;

	mov	dl, al
	call	NetWareCallFunction
	tst	al
	jz	done
	stc
done:
	ret
NetWareCallFunctionAX	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	NetWareCallFunctionAllocReply

DESCRIPTION:	Allocate a Reply buffer of the specified size, and then
		call a NetWare function which will use that reply buffer.
		The caller can then (AND MUST) free the buffer.

		IMPORTANT: after calling NetWare, the caller of this routine
		has ultimate responsibility for nuking this memory block.

CALLED BY:	is a library routine

PASS:		ah	= function code (will be passed to NetWare in the
				AH register)
		cx	= size of Reply buffer (including initial size word)
		ds:si	= optional read-only Request buffer (could be in code
				segment, for example)
		bx, dx, bp = other data to pass to NetWare function

RETURN:		es:di	= Reply Buffer
		al	= completion code
		ah, bx, dx, bp = other values returned from NetWare function

DESTROYED:	cx only

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	12/91		Initial version

------------------------------------------------------------------------------@

if 0	;not used yet

NetWareCallFunctionAllocReply	proc	far
	;allocate a block on the global heap to hold both the request and
	;the reply buffers.

	push	ax, bx, cx
	mov	ax,  cx 		;ax = total size for block
	add	ax, (offset NRR_requestSize)
					;add room at beginning of block
					;for handle, protect byte(s).

	;first, allocate a global memory block to hold our local memory heap

	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
					;allocate as HF_SWAPABLE and HAF_LOCK
	call	MemAlloc		;returns bx = handle of block

	mov	es, ax			;set es:di = Reply buffer
	mov	di, offset NRR_requestSize
					;since this block DOES NOT have a
					;request buffer, the reply buffer
					;will sit where the request buffer
					;normally does.

	mov	es:[NRR_handle], bx	;save handle of block, so can free
					;it later on.
EC <	mov	es:[NRR_protect]+0, 'PR';save protect word "RePly"	>
	pop	ax, bx, cx

	;stuff the sizes of each of the buffers into the correct field
	;in each buffer. Use Lo-Hi format, since we are running on PCs.

	sub	cx, size word
	mov	word ptr es:[NRR_requestSize], cx

	;now call NetWare, using our library routine to grab the DOS semaphore.

	call	NetWareCallFunction
	ret
NetWareCallFunctionAllocReply	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckDGroupDS

DESCRIPTION:	

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	2/92		Initial version

------------------------------------------------------------------------------@

if ERROR_CHECK

ECCheckDGroupDS	proc	far
	pushf
	cmp	ds:[dgroupHere], DGROUP_PROTECT1
	ERROR_NE NW_ERROR
	popf
	ret
ECCheckDGroupDS	endp

ECNetWareCheckRRBufferES	proc	far
	pushf
	cmp	es:[NRR_protect]+0, 'RR'	;check protect word
	ERROR_NE NW_ERROR
	popf
	ret
ECNetWareCheckRRBufferES	endp

endif

NetWareResidentCode	ends

