COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		NetWare Driver
FILE:		nwSimpleSem.asm

AUTHOR:		Chung Liu, Mar  7, 1993

ROUTINES:
	Name			Description
	----			-----------
	NWSimpleSem		strategy for semaphore calls
	NWSimpleOpenSem
	NWSimplePSem
	NWSimpleVSem
	NWSimpleCloseSem
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/93   	Initial revision


DESCRIPTION:
	This file contains code for the simplified semaphore model 
	which only uses NW_OPEN_SEMAPHORE and NW_CLOSE_SEMAPHORE, to 
	avoid problems that arise when a workstation loses its connection
	after having opened and grabbed a semaphore.  

	This file replaces code in nwSem.asm, nwSemHigh.asm and nwSemLow.asm

	$Id: nwSimpleSem.asm,v 1.1 97/04/18 11:48:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;include	Internal/fileInt.def
idata	segment			;fixed resource

originalPSP	word	0		;Used by NWSemSetPSPAndLockBios and
					;by NWSemRestorePSPAndUnlockBios.

idata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSimpleSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for simple NetWare semaphore calls.

CALLED BY:	NetWareStrategy
PASS:		al - NetWareSemaphoreFunction to call
RETURN:		returned from called proc
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NetWareResidentCode	segment resource
NWSimpleSem	proc	near
	call	NWSimpleSemInternal
	ret
NWSimpleSem	endp
NetWareResidentCode	ends

NetWareSemaphoreCode	segment resource
NWSimpleSemInternal	proc	far
	clr	ah
	mov_tr	di, ax

EC <	cmp	di, NetSemaphoreFunction	>
EC <	ERROR_AE NW_ERROR_INVALID_DRIVER_FUNCTION			>

	call	cs:[netWareSimpleSemCalls][di]
	ret
NWSimpleSemInternal	endp

netWareSimpleSemCalls	nptr	\
	offset	NWSimpleOpenSem,
	offset	NWSimplePSem,
	offset	NWSimpleVSem,
	offset 	NWSimpleCloseSem

.assert (size netWareSimpleSemCalls eq NetSemaphoreFunction)
NetWareSemaphoreCode	ends

NetWareSemaphoreCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSemSetPSPAndLockBios
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls SysLockBIOS and sets the our PSP to the PSP passed 
		in, saving the original GEOS PSP.

		This function should be called in conjunction with
		NWSemRestorePSPAndUnlockBios when it is not desired that 
		certain NetWare open calls be undone when GEOS exits.

		The PSP passed in should be that of a TSR program, or 
		of COMMAND.COM.  WARNING: Testing using the PSP of COMMAND.COM
		shows that sometimes the semaphore is dropped, so this is
		not reliable!

		Needs to be followed by a call to NWSemRestorePSPAndUnlockBios
		after the relevant NetWare Int21 call is done.

CALLED BY:	NWSimplePSem
PASS:		bx 	= new PSP to set
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	Leaves BIOS locked.  

PSEUDO CODE/STRATEGY:
	Save our current PSP.
	Find out the PSP of COMMAND.COM.
	Lock Bios.
	Set the PSP to the PSP of COMMAND.COM
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSemSetPSPAndLockBios	proc	near
	uses	ax,bx,cx,es
	.enter

	push	bx				;other PSP

	;
	; save our current PSP so that NWSemRestorePSPAndUnlockBios can
	; restore it.
	;
	mov	ah, MSDOS_GET_PSP
	call	FileInt21			; bx <- PSP

	mov	cx, segment idata
	mov	es, cx
	mov	es:[originalPSP], bx

if 0
	;	
	; find out the PSP of the command interpreter. This is accomplished
	; by walking the PSP chain looking for one whose parent is itself!
	;
findCommandLoop:
	mov	ax, bx
	mov	es, bx				; es <- PSP to check
	mov	bx, es:[PSP_parentId]		; bx <- next PSP
	cmp	bx, ax				; same as this one?
	jne	findCommandLoop
else
	pop	es				;other PSP
endif
	;
	; es is now the segment of the resident portion of the command
	; interpreter.  Set it to be the PSP, but grab the BIOS lock first
	; so that nothing dangerous happens while we have the PSP changed.
	;
	call	SysLockBIOS
	
	mov	bx, es
	mov	ah, MSDOS_SET_PSP
	call	FileInt21
	
	.leave
	ret
NWSemSetPSPAndLockBios	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSemRestorePSPAndUnlockBios
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the original PSP, and call SysUnlockBIOS.  

CALLED BY:	NWSimplePSem
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSemRestorePSPAndUnlockBios	proc	near
	uses	ax,bx,cx,ds
	.enter
	mov	cx, segment idata
	mov	ds, cx
	mov	bx, ds:[originalPSP]
	tst	bx
EC <	ERROR_Z NW_ERROR						>
	jz 	unlock			;hope that PSP wasn't altered 

	mov	ah, MSDOS_SET_PSP
	call	FileInt21
	
unlock:
	call	SysUnlockBIOS
	.leave
	ret
NWSemRestorePSPAndUnlockBios	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSimpleOpenSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a block describing a simple netware semaphore, to
		prepare for the call to NWSimplePSem.

CALLED BY:	Net Library
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

		bx	= PSP under which to open the semaphore, 
			  or 0 to just use our own PSP.

RETURN:		if error: (not enough memory to allocate semaphore block)
			carry flag set 
			ax	= 0xFF 
		else:
			cx 	= handle for semaphore.
			ax	= 0

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	MemAlloc a block of size NSOS_Frame, and copy in the values.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSimpleOpenSem	proc	near
	uses	ds,si,es,di,bx,dx
	.enter

	mov	di, bx		;di = other PSP	
	push	cx		;initial value
	;
	; allocate a memory block for the semaphore
	;
	mov	ax, size NSOS_Frame
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	error

	;
	; copy the semaphore info into the allocated block
	;
	mov	es, ax
	clr	es:[NSOS_nwSemHandle].high
	clr	es:[NSOS_nwSemHandle].low
	pop	ax	
	mov	es:[NSOS_initialValue], al
	mov	es:[NSOS_pollInterval], dx
	mov	es:[NSOS_psp], di
	mov	di, offset NSOS_name

	;
	; copy the name while counting its length
	;
	clr	cx
copyLoop:
	lodsb
	tst	ax
	jz	copyDone
	stosb
	inc	cx
	jmp	copyLoop
	
copyDone:
	mov	es:[NSOS_nameLen], cl

	call	MemUnlock
	clr	ax
	mov	cx, bx		;handle of block allocated
	
exit:
	.leave
	ret

error:
	mov	ax, 0xff
	clr	cx
	jmp 	exit
NWSimpleOpenSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSimplePSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait on a NetWare semaphore for a specified amount of 
		time. Must have already opened the semaphore using NetOpenSem

		The NetWare call to open the semaphore is done under the
		PSP passed to NWSimpleOpenSem.  If that PSP is 0, then the
		regular GEOS PSP is used.

CALLED BY:	Net Library
PASS:		cx 	= handle for semaphore, obtained from NWSimpleOpenSem
		dx	= timeout value, in ticks, before giving up waiting
			  on this semaphore.  Note that if the semaphore was
			  created with a poll interval of 0, then this timeout
			  value is ignored (assumed to be 0).
RETURN:		if timeout:
			carry set, al = 0
		if NetWare error:
			carry set, al <> 0
		if success:
			carry clear
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Obtain semaphore info from semaphore handle.
	cx = timeout value / poll interval
	loop
		call NFC_OPEN_SEMAPHORE
		if open count is 1
			success (return carry clear)
		else
			sleep for poll interval ticks
		decrement cx
	until cx is 0
	fail (return carry set)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSimplePSem	proc	near
bufferBlock	local	hptr
semBlock	local	hptr
timeout		local	word
pollInterval	local	word		
initValue	local	byte
otherPSP	local	word
	uses	ds,si,es,di,bx,cx,dx
	.enter
	
	mov	timeout, dx

	;
	; get semaphore info from semaphore handle
	;
	mov	semBlock, cx
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[NSOS_pollInterval]
	mov	pollInterval, ax
	mov	al, ds:[NSOS_initialValue]
	mov	initValue, al
	mov	bx, ds:[NSOS_psp]
	mov	otherPSP, bx
	
	;
	; allocate the request buffer for NFC_OPEN_SEMAPHORE
	;
	mov	bx, size NReqBuf_OpenSemaphore
	clr	cx				;no reply buffer
	call	NetWareAllocRRBuffers		;es:si = request buffer
						;es:di = reply buffer
	mov	bufferBlock, bx

	;
	; fill in the request buffer.
	;	
	mov	cl, ds:[NSOS_nameLen]
	mov	es:[si].NREQBUF_OS_semNameLength, cl
	push	si				;save the offset to the ReqBuf
	mov	di, si
	add	di, offset NREQBUF_OS_semName	;es:di = dest
	mov	si, offset NSOS_name		;ds:si = name
						;cx = count
	rep movsb

	;
	; calculate the number of times we should go around the pollLoop.
	; If pollInterval is zero, then just repeat once.
	;
	
	clr	dx
	mov	ax, timeout
	mov	cx, pollInterval
	tst	cx
	jz	repeatOnce
	div	cx				;dx:ax / cx -> ax
	tst	ax
	jnz	nonZeroRepeat

repeatOnce:
	mov	ax, 1				;don't want to LOOP on cx=0 !!!
	
nonZeroRepeat:

	mov	cx, ds
	segmov	ds, es
	mov	es, cx				;es = semaphore segment
	pop	dx				;ds:dx = request buffer

	mov	cx, ax				;repeat count

	;
	; if otherPSP != 0, then reset the PSP for the NetWare call.
	;
	mov	bx, otherPSP			
	tst	bx
	jz	pollLoop
	call	NWSemSetPSPAndLockBios

pollLoop:
	push	cx, dx
	
	;
	; call NFC_OPEN_SEMAPHORE
	;
	mov	cl, initValue
	mov	ax, NFC_OPEN_SEMAPHORE
	call	NetWareCallFunction		;returns:
						; bl = open count
						; al = completion code
						; cx, dx = semaphore handle
	
	tst	al
	jnz	fail
	cmp	bl, initValue
	jle	success	

	;
	; semaphore is busy
	;
	mov	ax, NFC_CLOSE_SEMAPHORE
	call	NetWareCallFunction

	;
	; sleep for the pollInterval
	;
	mov	ax, pollInterval
	call	TimerSleep

	pop	cx, dx
	loop 	pollLoop

	;
	; timed out! 
	;
	clr	ax
	stc	
	
exit:
	pushf
	tst	otherPSP
	jz	skipRestorePSP
	call	NWSemRestorePSPAndUnlockBios

skipRestorePSP:
	mov	bx, semBlock
	call	MemUnlock
	mov	bx, bufferBlock
	call	MemFree

	popf

	.leave
	ret

fail:
	pop	bx, bx				;remove count from stack
	stc
	jmp	exit

success:
	pop	bx, bx				;remove count from stack
	movdw	es:[NSOS_nwSemHandle], cxdx
	clc
	jmp	exit
NWSimplePSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSimpleVSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release a NetWare semaphore. Must have opened the semaphore
		with NWSimplePSem.

CALLED BY:	Net Library
PASS:		cx = handle for semaphore (returned by NWSimpleOpenSem)
RETURN:		al = NetWareReturnCode
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	call NFC_CLOSE_SEMAPHORE
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSimpleVSem	proc	near
	uses	bx, cx, dx, ds
	.enter
 	mov	bx, cx
	call	MemLock
	push	bx
	mov	ds, ax
	movdw	cxdx, ds:[NSOS_nwSemHandle]
EC <	tst	cx						>
EC <	ERROR_Z NW_ERROR					>
EC <	tst	dx						>
EC <	ERROR_Z NW_ERROR					>	

	mov	bx, ds:[NSOS_psp]
	tst	bx
	jz	skipSetPSP
	call	NWSemSetPSPAndLockBios

skipSetPSP:
	mov	ax, NFC_CLOSE_SEMAPHORE
	call	NetWareCallFunction

	tst	bx
	jz	skipRestorePSP
	call	NWSemRestorePSPAndUnlockBios

skipRestorePSP:
	clr	ds:[NSOS_nwSemHandle].high
	clr	ds:[NSOS_nwSemHandle].low

	pop	bx
	call	MemUnlock
	.leave
	ret
NWSimpleVSem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWSimpleCloseSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close a NetWare semaphore.

CALLED BY:	Net Library
PASS:		cx = semaphore handle (returned by NetOpenSem)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/ 7/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWSimpleCloseSem	proc	near
	uses	bx
	.enter
	mov	bx, cx
	call	MemFree
	.leave
	ret
NWSimpleCloseSem	endp

NetWareSemaphoreCode	ends




