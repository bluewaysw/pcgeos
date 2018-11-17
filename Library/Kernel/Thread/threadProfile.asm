COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Kernel
MODULE:		Thread
FILE:		threadProfile.asm

AUTHOR:		Andrew Wilson, Sep 11, 1996

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/96		Initial revision

DESCRIPTION:
	Contains code for doing single-step profiling

	$Id: threadProfile.asm,v 1.1 97/04/05 01:15:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	SINGLE_STEP_PROFILING

LOG_LAST_THOUSAND_INSTRUCTIONS	equ	FALSE
if	LOG_LAST_THOUSAND_INSTRUCTIONS
SSData	segment
InstData	struct
	ID_rout	fptr.far (0)
	ID_AX	word	(0)
	ID_BX	word	(0)
	ID_CX	word	(0)
	ID_DX	word	(0)
	ID_BP	word	(0)
	ID_DI	word	(0)
	ID_SI	word	(0)
	ID_SP	word	(0)
	ID_ES	sptr	(0)
	ID_DS	sptr	(0)
	ID_SS	sptr	(0)
InstData	ends
storedInstructions	InstData 1000 dup (<>)
endData	label byte
currentAddress		nptr	storedInstructions
SSData	ends
endif

SSProfile segment resource
; If someone changes the single-step vector, this should catch it.
breakpoints	byte	512 dup (0xcc)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepInitAccountant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do "Whatever it is" the accounting code needs to do

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Depends on accounting code

PSEUDO CODE/STRATEGY:
		Likely allocate some memory, pop into some funky
		processor mode, or arrange the augury sticks around
		the fire.  It all depends.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ssName	char "SSEMMXXX",0
SingleStepInitAccountant	proc	far
		uses	ax, bx, dx, si, ds
		.enter
	;
	;  Set up everything we need for histogram
	;  analysis of code execution.  This is basically
	;  a big block of EMS memory that we can use, and
	;  a cache of counters in dgroup.
		
	;
	;  Make sure no one else is here right now
		call	SysLockBIOSFar
		call	SysEnterCritical

	;
	;  Get our hands on block our name 
		segmov	ds, cs
		mov	si, offset ssName

	;
	;  Look for block left over from the last time...
		mov	ax, EMF_SEARCH
		int	EMM_INT
		tst	ah
		jnz	getNewBlock ; => Couldn't find one

	;
	;  There was one.  Free it.
		mov	ah, high EMF_FREE
		int	EMM_INT
		tst	ah
		jnz	error ; => mysterious problem

getNewBlock:
	;
	;  Calculate size of counter array needed to
	;  hold entire range of possible instructions
		mov	bx, NUM_PAGES_OF_COUNTERS
%out	TODD - turn hard-coded size into soft-coded size

	;
	;  Allocate one mondo-huge block to store the counters in
		mov	ax, EMF_ALLOC
		int	EMM_INT
		tst	ah
		jnz	error ; => Couldn't get it

	;
	;  Associate this block with us, so we can find it
	;  again if we need it (like if we crash).
		mov	ax, EMF_SET_NAME
		int	EMM_INT
		tst	ah
		jnz	error ; => mysterious problem

	;
	;  Now stuff the block handle away in dgroup
	;  so we can refer to it later.
		mov	ax, segment dgroup
		mov	ds, ax

		mov	ds:[blobHandle], dx

	;
	;  Finally, initialize the pageStart array for
	;  our page table so we can get to pages quickly
		mov	cx, CACHE_SIZE_PAGES
		mov	ax, offset cachePage
		clr	si
topOfLoop:
		mov	ds:pageStart[si], ax
		add	ax, size CachePage
		add	si, size nptr
		loop	topOfLoop
	;
	; Zero-initialize the array
	;
		call	SingleStepResetAccountant
	
		clc					; no problems
done:
	;
	;  We're done screwing around.  Let others in.
		call	SysExitCritical
		call	SysUnlockBIOSFar
		.leave
		ret
error:
	;
	;  Something bad happened.  Mark the block as
	;  invalid, and return an error...
		mov	ax, segment dgroup
		mov	ds, ax

		clr	ds:[blobHandle]
		stc
		jmp	done

SingleStepInitAccountant	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepFreeAccountant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo "Whatever it is" that we did in InitAccountant

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Depends on account code

PSEUDO CODE/STRATEGY:
		Free memory, pop back into normal mode, or pick
		up all the sticks and put out the fire.  It all
		depends.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SingleStepFreeAccountant	proc	far

		uses	ax, dx, ds
		.enter
	;
	;  Get hands on dgroup, and find out what then
	;  EMS handle of our array of counters is.
		mov	ax, segment dgroup
		mov	ds, ax

		mov	ax, ds:[blobHandle]
		tst	ax
		jz	done	; => Nothing to free

	;
	;  Free the entire array "just-like-that"
		mov	dx, ax
		mov	ax, EMF_FREE
		int	EMM_INT
done:
		.leave
		ret
SingleStepFreeAccountant	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveAndDisableSingleStepping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves and disables the trap flag

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveAndDisableSingleStepping	proc	far	uses	ds, ax
	.enter
	LoadVarSeg	ds, ax
	mov	ds:[singleStepping], 0
	TRAP_OFF	ax
	.leave
	ret
SaveAndDisableSingleStepping	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreSingleStepping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pulls the old trap status off the stack and uses it

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreSingleStepping	proc	far
	.enter
	push	ds, ax

;	Swat keeps trashing *our* single-step vector, so let's make sure
;	it's set up here.

	pushf
	clr	ax
	mov	ds, ax
	cmp	ds:[4].segment, segment SingleStepHandler
	jz	vectorOK

;	OK, somebody (whose initials are "s.w.a.t.") trashed our single-step
;	vector, so re-establish it.

	LoadVarSeg	ds, ax
	tst	ds:[singleStepHooked]
	jz	notHookedYet

;	We're supposed to be hooked into the single-step interrupt, but our
;	handler was overridden, so re-install it.

	clr	ds:[singleStepHooked]
	call	HookSingleStepInterrupt
vectorOK:
	cmp	ds:[4].segment, segment SingleStepHandler
	ERROR_NZ	-1
	cmp	ds:[4].offset, offset SingleStepHandler
	ERROR_NZ	-1
notHookedYet:	
	popf

;	See if we were single-stepping before, and if so, begin again

	pushf
	LoadVarSeg	ds, ax
	tst	ds:[savedSingleStepping]
	jz	alreadyDisabled
	mov	ds:[singleStepping], -1
	popf
	TRAP_ON	ax
exit:
	pop	ds, ax	
	.leave
	ret
alreadyDisabled:		
	popf
	jmp	exit
RestoreSingleStepping	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HookSingleStepInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hooks the single step interrupt.

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HookSingleStepInterrupt	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

;	Set the flag that says that we have hooked the single step vector,
;	and exit if already hoooked

	LoadVarSeg	es, ax
	mov	al, -1
	xchg	al, es:[singleStepHooked]
	tst	al
	jnz	exit

;	Catch the "single-step" interrupt, so we can do our magic

	mov	ax, SINGLE_STEP_INTERRUPT_NUMBER
	mov	bx, segment SingleStepHandler
	mov	cx, offset SingleStepHandler
	LoadVarSeg	es
	mov	di, offset oldSingleStepVector
	call	SysCatchInterrupt
exit:
	.leave
	ret
HookSingleStepInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnhookSingleStepInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unhooks the single step interrupt.

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnhookSingleStepInterrupt	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

;	Set the flag that says that we have hooked the single step vector,
;	and exit if already hoooked

	LoadVarSeg	es, ax
	clr	al
	xchg	al, es:[singleStepHooked]
	tst	al
	jz	exit

;	Restore the interrupt vector to what it was before

	mov	ax, SINGLE_STEP_INTERRUPT_NUMBER
	mov	di, offset oldSingleStepVector
	call	SysResetInterrupt
exit:
	.leave
	ret
UnhookSingleStepInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartSingleStepping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Catches the single-step vector, and turns on single-stepping

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags intact)
SIDE EFFECTS:	Turns on single-stepping

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SINGLE_STEP_INTERRUPT_NUMBER	equ	1
; The interrupt generated by the "trap" flag

StartSingleStepping	proc	far
	uses	ax, es
	.enter

;	Set the flag that says that we are single stepping, and exit if we
;	are already single-stepping

	LoadVarSeg	es, ax
	mov	es:[singleStepping], -1
	mov	es:[savedSingleStepping], -1

;	Turn on the TRAP flag, which generates an interrupt after every
;	instruction executed

	TRAP_ON	ax
	.leave
	ret
StartSingleStepping	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopSingleStepping
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turns off single-stepping.

CALLED BY:	EndGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags intact)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopSingleStepping	proc	far
	uses	ax, es
	.enter
	LoadVarSeg	es, ax
	mov	es:[savedSingleStepping], 0
	mov	es:[singleStepping], 0		;Do not change to CLR

;	Turn off the TRAP flag, so no more interrupts are generated

	TRAP_OFF	ax

	.leave
	ret
StopSingleStepping	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles the single-step interrupt

CALLED BY:	interrupt vector when trap flag is on
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SingleStepStack	struct
	SSS_saveBP	word
	SSS_saveDS	word
	SSS_retAddr	fptr.far
	SSS_intFlags	word
SingleStepStack	ends
BASE_ADDRESS_OF_XIP_IMAGE	equ	(1024*1024)
; This is the 32-bit address at which the first page in the XIP image lies
; It doesn't matter where, as long as it matches what the "xipoffset" tool
; generates, which is 1M.

udata		segment
	lastFarPtr	fptr.far
	lastFlags	word
	logAX		word
	logBX		word
	logCX		word
	logDX		word
	logDI		word
	logSI		word
	logES		word

udata		ends

SingleStepHandler	proc	far
	.enter
	.186
	push	ds
	push	bp
	mov	bp, sp
	LoadVarSeg	ds
	pusha
	push	es

	incdw	ds:[instructionsSinceLastInterrupt]

;-----------------------------------------------------------------------------
;		Debug Code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
	mov	ds:[logAX], ax
	mov	ds:[logBX], bx
	mov	ds:[logCX], cx
	mov	ds:[logDX], dx
	mov	ds:[logDI], di
	mov	ds:[logSI], si
	mov	ds:[logES], es
endif

	mov	al, -1
	xchg	ds:[inSingleStep], al
	tst	al
	ERROR_NZ	-1
;-----------------------------------------------------------------------------

;	Increment our count of instructions
	add	ds:[instructionCount].low, 1
	adc	ds:[instructionCount].high, 0
	adc	ds:[instructionCountHigh].low, 0
	adc	ds:[instructionCountHigh].high, 0

	; Get ret addr (next instruction to be executed) and convert it to
	; a 32-bit address.

	; First, see if we are executing in the map page

;-----------------------------------------------------------------------------
;		Debug Code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
mov	bx, ss:[bp].SSS_retAddr.segment
;EC <cmp	bx, 0xf000						>
;EC <ERROR_AE	-1						>
;EC <cmp	bx, ds:[loaderVars].KLV_heapStart			>
;EC <ERROR_B	-1						>
mov	ds:lastFarPtr.segment, bx
mov	bx, ss:[bp].SSS_retAddr.offset
mov	ds:lastFarPtr.offset, bx
mov	bx, ss:[bp].SSS_intFlags
mov	ds:lastFlags, bx
endif

if	LOG_LAST_THOUSAND_INSTRUCTIONS
	call	LogAddressInBigLog
endif
;-----------------------------------------------------------------------------

	mov	bx, ss:[bp].SSS_retAddr.segment

	sub	bx, ds:[loaderVars].KLV_mapPageAddr
	jb	isReal
	cmp	bx, MAPPING_PAGE_SIZE/16
	jae	isReal

;	We have an offset into the XIP image. Find out our exact offset into
;	the XIP map page, then figure out where the XIP map page lies in
;	32-bit address space, and add those two values together:

	shl	bx, 4
	add	bx, ss:[bp].SSS_retAddr.offset
	mov	cx, bx			;CX = offset within XIP page

;	Convert the current XIP page into a 32-bit offset. 
;	Multiplying by 32K is the same as shifting to the right 15 bits
;	(which is the same as putting a value in the high word and shift it
;	to the right once).

	mov	bx, ds:[curXIPPage]
	clr	ax
.assert MAPPING_PAGE_SIZE le PHYSICAL_PAGE_SIZE*2
	shrdw	bxax
if	MAPPING_PAGE_SIZE eq PHYSICAL_PAGE_SIZE
	shrdw	bxax
endif
	adddw	bxax, BASE_ADDRESS_OF_XIP_IMAGE
	add	ax, cx
	adc	bx, 0
	jmp	common
	
isReal:

;	We have a non-XIP address - convert it to a 32-bit value like
;	so:
;
;	32BitValue = (segment*16) + offset

	mov	ax, ss:[bp].SSS_retAddr.segment
	clr	bx
	shldw	bxax
	shldw	bxax
	shldw	bxax
	shldw	bxax
	add	ax, ss:[bp].SSS_retAddr.offset
	adc	bx, 0
common:
ife	LOG_LAST_THOUSAND_INSTRUCTIONS
	call	LogAddress
endif

;	Set the trap flag appropriately - doing this every time ensures that
;	if the user mucks with the trap flag (or has done a pushf/popf around
;	an operation that sets the trap flag), we'll continue to single-step.

	mov	ax, ss:[bp].SSS_intFlags
	andnf	ax, not mask CPU_TRAP
	tst	ds:[singleStepping]
	jz	setFlags
	ornf	ax, mask CPU_TRAP

setFlags:
	mov	ss:[bp].SSS_intFlags, ax

	tst	ds:[inSingleStep]
	ERROR_Z	-1
	mov	al, 0
	xchg	ds:[inSingleStep], al
	tst	al
	ERROR_Z	-1
	pop	es
	popa

;----------------------------------------------------------------------------
; Debug code
;----------------------------------------------------------------------------

if	ERROR_CHECK
	mov	bp, es
	cmp	bp, ds:[logES]
	ERROR_NZ	-1
	cmp	ax, ds:[logAX]
	ERROR_NZ	-1
	cmp	bx, ds:[logBX]
	ERROR_NZ	-1
	cmp	cx, ds:[logCX]
	ERROR_NZ	-1
	cmp	dx, ds:[logDX]
	ERROR_NZ	-1
	cmp	di, ds:[logDI]
	ERROR_NZ	-1
	cmp	si, ds:[logSI]
	ERROR_NZ	-1
endif
	pop	bp
	pop	ds
	.leave
	iret
SingleStepHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogAddressInBigLog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keeps track of the last 1000 instructions

CALLED BY:	
PASS:		ss:bp - SingleStepStack
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/18/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	LOG_LAST_THOUSAND_INSTRUCTIONS
LogAddressInBigLog	proc	near
	uses	ds, ax, bx, es
	.enter
	mov	ax, segment SSData
	mov	ds, ax
	mov	bx, ds:[currentAddress]
	mov	ax, ss:[bp].SSS_retAddr.segment
	mov	ds:[bx].ID_rout.segment, ax
	mov	ax, ss:[bp].SSS_retAddr.offset
	mov	ds:[bx].ID_rout.offset, ax
	LoadVarSeg	es, ax
	mov	ax, es:[logAX]
	mov	ds:[bx].ID_AX, ax
	mov	ax, es:[logBX]
	mov	ds:[bx].ID_BX, ax
	mov	ax, es:[logCX]
	mov	ds:[bx].ID_CX, ax
	mov	ax, es:[logDX]
	mov	ds:[bx].ID_DX, ax
	mov	ax, es:[logDI]
	mov	ds:[bx].ID_DI, ax
	mov	ax, es:[logSI]
	mov	ds:[bx].ID_SI, ax
	mov	ax, es:[logES]
	mov	ds:[bx].ID_ES, ax
	mov	ax, ss:[bp].SSS_saveDS
	mov	ds:[bx].ID_DS, ax
	mov	ax, ss:[bp].SSS_saveBP
	mov	ds:[bx].ID_BP, ax
	mov	ax, bp
	add	ax, size SingleStepStack
	mov	ds:[bx].ID_SP, ax
	mov	ds:[bx].ID_SS, ss
	add	bx, size InstData
	cmp	bx, offset endData
	jb	10$
	mov	bx, offset storedInstructions
10$:
	mov	ds:[currentAddress], bx
	.leave
	ret
LogAddressInBigLog	endp
endif

ife	LOG_LAST_THOUSAND_INSTRUCTIONS	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogAddress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Logs an address

CALLED BY:	SingleStepHandler
PASS:		BX.AX - 32-bit address we want to log
		DS - dgroup
RETURN:		nothing
DESTROYED:	anything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LogAddress	proc	near
		uses	es
		pusha
		.enter
;-----------------------------------------------------------------------------
;		Debug Code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
mov	di, ds
cmp	di, segment dgroup
ERROR_NZ	-1
endif
;-----------------------------------------------------------------------------

	;
	;  From the linear address of an instruction, determine
	;  when EMS page holds the instruction count, which
	;  cachePage in the EMS page, and at what offset within
	;  the cachePage the counter lies.  And do it fast.

	;
	;  First, determine offset of counter in EMS page
		shldw	bxax				; calc counter offset
		shldw	bxax
		push	ax				; save counter offset

	;
	;  Then, determine offset of the start of the cachePage
	;  holding that counter
		mov	di, 03fc0h
		and	di, ax				; di <- cachePage offset

	;
	;  Then, determine which 16k EMS page holds that cachePage
		shldw	bxax
		shldw	bxax				; bx <- EMS page #

	;
	;  Determine if cachePage is currently cached
		mov	cx, CACHE_SIZE_PAGES
		clr	si
lookForPage:
		cmp	ds:pageBlock[si], bx		; right EMS page?
		jne	tryNextPage	; => can't be the one
		cmp	ds:pageOffset[si], di		; right cachePage?
		je	pageIsCached	; => this is the one!
tryNextPage:
		add	si, 2
		loop	lookForPage ;=> Try next page

	;
	;  We don't have the desired cachePage in the cache.
	;  Flush the oldest cache page out to the EMS blob,
	;  and then zero it out.
	;  Mark the page as now belonging to the desired
	;  cachePage, and begin using it to accumulate hits.

	;
	;  Determine oldest cachePage
		mov	si, ds:[oldestCachePage]	; si <- page #
;-----------------------------------------------------------------------------
;		Debug Code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
cmp	si, size pageBlock
ERROR_AE	-1
test	si, 1
ERROR_NZ	-1
endif
;-----------------------------------------------------------------------------

	;
	;  Update page table, and map in the EMS block
	;  that holds the counters for the old cachePage
		xchg	bx, ds:pageBlock[si]		; bx <- get & set block

							; bx -> EMS block
							; ds -> dgroup
push	si

		call	MapSSPage		; bx <- EMS page w/block
		mov	es, bx

pop	cx
;-----------------------------------------------------------------------------
;		Debug Code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
cmp	si, cx
ERROR_NZ	-1
cmp	si, size pageOffset
ERROR_AE	-1
test	si, 1
ERROR_NZ	-1
endif
;-----------------------------------------------------------------------------
		xchg	di, ds:pageOffset[si]		; es:di <- page start

	;
	;  Get offset to start of cachePage contents
		mov	si, ds:pageStart[si]		; ds:si <- cache start

	;
	;  Add the cached counts into the actual counters
	;  while clearing out the contents of the cachePage
		mov	cx, NUM_COUNTERS_IN_CACHE_PAGE
topOfLoop:
		clrdw	dxax
		xchgdw	dxax, ds:[si]			; get and clear counts

;-----------------------------------------------------------------------------
;		Debug Code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
cmp	si, offset cachePage
ERROR_B		-1

cmp	si, offset oldestCachePage
ERROR_AE	-1

cmp	di, PHYSICAL_PAGE_SIZE-size dword
ERROR_A	-1
endif
;-----------------------------------------------------------------------------

		adddw	es:[di], dxax			; add to real counters

		mov	ax, size dword
		add	si, ax				; advance to next set
		add	di, ax				;   of counters...
		loop	topOfLoop ; => One more time!

	;
	;  With that done, unmap the page, and update the
	;  oldest page pointer to point to new oldest page
							; ds -> dgroup
		call	UnMapSSPage

		mov	si, ds:[oldestCachePage]	; si <- page #
		sub	ds:[oldestCachePage], 2		; adjust oldestPAge
		jb	wrapOldestPage	; => off end

pageIsCached:
	;
	;  We have a valid pageCache with the counts for
	;  the indicated instruction in page SI.  Increment
	;  the count in the cachePage for the specified
	;  instruction.
		mov	si, ds:pageStart[si]		; ds:si <- cache start

		pop	ax				; recover instr. offset
		andnf	ax, 0003fh			; calc offset in cPage
		add	si, ax				; add to start of cPage

;-----------------------------------------------------------------------------
;		Debug Code
;-----------------------------------------------------------------------------
if	ERROR_CHECK
cmp	si, offset cachePage
ERROR_B		-1

cmp	si, offset oldestCachePage
ERROR_AE	-1
endif
;-----------------------------------------------------------------------------

		incdw	ds:[si]				; adjust 32-bit counter
		.leave
		popa
		ret
wrapOldestPage:
	;
	;  We've gone of the bottom of the Page table,
	;  wrap around doing our fake "LRU" algorithm
		mov	ds:[oldestCachePage],  ( (CACHE_SIZE_PAGES-1) shl 1)
		jmp	pageIsCached
LogAddress	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapSSPage/UnMapSSPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map a page from EMS blob in through XIP window

CALLED BY:	LogAddress, 
PASS:		bx	-> page # of emsBlob to map in
		ds	-> dgroup
RETURN:		For MapSSPage:
			bx	<- segment of page
		For UnMapSSPage:
			nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Alters mapping of XIP window

PSEUDO CODE/STRATEGY:
		Just call EMM, and let it do its thing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MapSSPage	proc	near
		uses	ax, dx
		.enter
	;
	;  Temporarily swap the currently mapped XIP
	;  code with the appropriate page from our EMS
	;  blob.
							; bx <- page #
		mov	dx, ds:[blobHandle]		; dx <- EMS Handle
		mov	ah, high EMF_MAP_BANK		; ah <- command
		mov	al, ds:[loaderVars].KLV_mapPage	; al <- mapping seg
		int	EMM_INT			; ax <- non-zero on error
			; No point in checking for an error,
			; all we can do is crash
;-----------------------------------------------------------------------------
;	Debug Code
;-----------------------------------------------------------------------------
EC <tst	ah							>
EC <ERROR_NZ	-1						>	
;-----------------------------------------------------------------------------



	;
	;  Return the segment of the mapped page in BX
		mov	bx, ds:[loaderVars].KLV_mapPageAddr

		.leave
		ret
MapSSPage		endp

UnMapSSPage	proc	near
		uses	ax, bx, dx
		.enter
	;
	;  Remap the XIP page that was there just a
	;  moment ago, so no one will notice we just
	;  used their mapping window.
		mov	bx, ds:[curXIPPage]		; bx <- page #
if	MAPPING_PAGE_SIZE eq PHYSICAL_PAGE_SIZE * 2
		shl	bx, 1
elseif	MAPPING_PAGE_SIZE ne PHYSICAL_PAGE_SIZE
		ErrMessage <Write code to deal with big mapping page>
endif
		mov	dx, ds:[loaderVars].KLV_emmHandle; dx <- EMS Handle
		mov	ah, high EMF_MAP_BANK		; ah <- command
		mov	al, ds:[loaderVars].KLV_mapPage	; al <- mapping seg
		int	EMM_INT
			; No point in checking for an error,
			; all we can do is crash
;-----------------------------------------------------------------------------
;	Debug Code
;-----------------------------------------------------------------------------
EC <tst	ah						>
EC <ERROR_NZ	-1					>
;-----------------------------------------------------------------------------

		.leave
		ret
UnMapSSPage	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepResetAccountant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SingleStepResetAccountant	proc	far
		uses	ax, bx, cx, di, ds, es
		.enter

		LoadVarSeg	ds, ax
	;
	;  Map in each page of counters and reset
	;  them all to zero while no one is looking.

		clr	bx
		mov	cx, NUM_PAGES_OF_COUNTERS
topOfLoop:
		push	cx				; save page count
		push	bx
	;
	;  Silently bank in and clear one EMS page

		INT_OFF
		call	MapSSPage		; bx <- segment
		mov	es, bx			; es:di <- destination
		clr	ax, di			; ax <- zero

		mov	cx, 16384 / 2		; cx <- size of EMS page
		rep	stosw

		call	UnMapSSPage
		INT_ON
		pop	bx
		pop	cx

	;
	;  Advance to next page, and do it again
		inc	bx				; restore page count
		loop	topOfLoop ; => One more time!

	;
	;  Simple, no?

		clc

		.leave
		ret

SingleStepResetAccountant	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepGetAccountLog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in buffer with accounting findings

CALLED BY:	GLOBAL
PASS:		ax:di	-> 16k buffer to fill
	method specific:
		bx	-> page # to dump
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:
	Temporarily steals XIP window to do copy.

PSEUDO CODE/STRATEGY:
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SingleStepGetAccountingLog	proc	far
		uses	ax, bx, cx, si, di, ds, es
		.enter

		LoadVarSeg	ds, si
	;
	;  Make sure the page is valid

		cmp	bx, NUM_PAGES_OF_COUNTERS
		jae	error	; => too large

	;
	;  While no one is looking, map in the page
	;  of counters and dump them to the other buffer.

		INT_OFF
		call	MapSSPage		; bx <- segment

		push	ds			; save Mr. Dgroup

		mov	es, ax			; es:di <- destination
		mov	ds, bx			; ds:si <- source
		clr	si

		mov	cx, 16384 / 2		; cx <- size
		rep	movsw

		pop	ds			; restore Mr. Dgroup

		call	UnMapSSPage
		INT_ON
	;
	;  Well, that was pleasant.  Return and be done.

		clc
done:
		.leave
		ret
error:
	;
	;  No more data to give...

		stc
		jmp	done

SingleStepGetAccountingLog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProfileMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traps the special profile key, directing DumpProfileLog
		to do its thing when hit.

CALLED BY:	
PASS:		al 		- MF_DATA
		di 		- event type
				  (or 0 if to retrieve additional data)
		cx, dx, bp, si 	- event data
		ss:sp 		- stack frame of Input Manager


RETURN:		AL = 0, indicating no more to come, & Nothing being returned
		es unchanged

DESTROYED:	nothing
SIDE EFFECTS:	
		Sets 

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProfileMonitor	proc	far
	uses	ds
	.enter
	;
	; If PrintScreen pressed...
	;
	cmp	di, MSG_META_KBD_CHAR
	jne	done
	cmp	cx, DUMP_PROFILE_KEY
	jne	done
	mov	bx, dx
	andnf	bx, DUMP_PROFILE_FLAG_MASK
	cmp	bx, DUMP_PROFILE_FLAG_VALUE
	jne	done

	;
	; ... invoke routine that dumps the log
	;
	mov	ax, segment dgroup
	mov	ds, ax
	mov	bx, ds:[uiHandle]
	mov	dx, size ProcessCallRoutineParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].PCRP_address.segment, segment DumpProfileLogFixed
	mov	ss:[bp].PCRP_address.offset, offset DumpProfileLogFixed
	mov	ax, MSG_PROCESS_CALL_ROUTINE
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
	call	ObjMessage
	add	sp, size ProcessCallRoutineParams
	clr	al
done:
	.leave
	ret
ProfileMonitor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpProfileLogFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the single-step profile log to a file.

CALLED BY:	ProfileMonitor on the UI thread via MSG_PROCESS_CALL_ROUTINE
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything

SIDE EFFECTS:	The profile array is reset

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpProfileLogFixed	proc	far
	;
	; Turn off the profile mechanism's single-stepping
	;
	call	SaveAndDisableSingleStepping

	call	DumpProfileLogMovable

	call	RestoreSingleStepping
	ret
DumpProfileLogFixed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepHookVideo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hooks the video driver interrupt, so we are sure the trap
		flag is off.

CALLED BY:	InitGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VIDEO_BIOS	= 10h
SingleStepHookVideo	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
;	Catch the "single-step" interrupt, so we can do our magic

	mov	ax, VIDEO_BIOS
	mov	bx, segment VideoBiosHandler
	mov	cx, offset VideoBiosHandler
	LoadVarSeg	es
	mov	di, offset oldVideoBiosHandler
	call	SysCatchInterrupt
	.leave
	ret
SingleStepHookVideo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepUnhookVideo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unhooks the video driver interrupt before exiting

CALLED BY:	EndGeos
PASS:		nothing
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SingleStepUnhookVideo	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter
;	Release the "single-step" interrupt

	mov	ax, VIDEO_BIOS
	LoadVarSeg	es
	mov	di, offset oldVideoBiosHandler
	call	SysResetInterrupt
	.leave
	ret
SingleStepUnhookVideo	endp
SSProfile ends

idata	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VideoBiosHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepts the video bios handler

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	andrew	9/17/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VideoBiosHandler	proc	far
	.enter

;	The trap flag is off here, so even if the video bios code pops the
;	flags off the stack, we're OK. Since the video bios calls don't return
;	flags, we don't have anything to worry about.

;	Emulate a software interrupt here...

	call	SaveAndDisableSingleStepping
	pushf
	call	cs:[oldVideoBiosHandler]
	call	RestoreSingleStepping
	.leave
	iret
VideoBiosHandler	endp

idata	ends


SSMovable	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleStepGetAccountingInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return pointer and size of accounting info

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		dx:si	<- to info block
		cx	<- size of info block
DESTROYED:	nothing
SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:
		Give 'em a pointer to dgroup, and let them know
		how many bytes are relevant.

		Gadz, I bet a snotty protected mode kernel would
		just freak at the mere thought of that.  :-)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	todd	9/13/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SingleStepGetAccountingInfo	proc	far
		.enter
	;
	;  Inform caller of location and size of
	;  the accounting statistics appropriate to
	;  this accounting method.
		mov	dx, ds
		mov	si, offset startOfAccountInfo
		mov	cx, (offset endOfAccountInfo - offset startOfAccountInfo)
		.leave
		ret
SingleStepGetAccountingInfo	endp


PrintSSPDebugChar	proc	far	uses	ax, bx
	.enter	

;	Use "Write Char in Teletype Mode" bios call

	mov	ah, 0x0e
	clr	bx
	int	10h
	.leave
	ret
PrintSSPDebugChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DumpProfileLog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the single-step profile log to a file.

CALLED BY:	ProfileMonitor on the UI thread
PASS:		nothing
RETURN:		nothing
DESTROYED:	everything

SIDE EFFECTS:	The profile array is reset

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/11/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DumpProfileLogMovable	proc	far

	;
	; Before we do anything, make sure we can allocate a buffer
	; block for the data
	;
	mov	cx, ALLOC_STATIC_LOCK
	mov	ax, 4000h			; for the 16K pages
	call	MemAllocFar			; bx = handle, ax = segment
	jc	done
	push	bx				; +1 : buffer handle
	push	ax				; +2 : buffer segment

	;
	; Place log files in SP_TOP
	;
	call	FilePushDir
	mov	ax, SP_TOP
	call	FileSetStandardPath

	;
	; Create a new file for the log
	;
	sub	sp, 12				; provide buffer for filename
	clr	dx
	push	dx				; Null terminate at first char
	mov	dx, sp
	segmov	ds, ss				; ds:dx = buffer for filename
	mov	ax, (mask FCF_NATIVE or FILE_CREATE_ONLY) shl 8 or \
			FILE_DENY_RW or FILE_ACCESS_W
	CheckHack <FILE_ATTR_NORMAL eq 0>
	clr	cx
	call	FileCreateTempFile		; ax = file handle
						; ds:dx = pathname
	mov	bx, ax				; bx = file handle
	lahf					; save carry
	add	sp, 14				; restore stack
	sahf					; restore carry
	pop	si				; -2 : si = buffer segment
	jc	donePop				;  and quit if error

	;
	; Dump the data into the log file
	;
	call	WriteProfileArray

	mov	al, FILE_NO_ERRORS
	call	FileCloseFar

	;
	; Zero the profile array for the next run
	;
	call	SingleStepResetAccountant

donePop:
	;
	; Restore original path
	;
	call	FilePopDir

	;
	; Free buffer block
	;
	pop	bx				; -1 : buffer handle
	call	MemFree
done:
	ret
DumpProfileLogMovable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteProfileArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dumps the entire profiling array to a log file

CALLED BY:	DumpProfileLog
PASS:		bx = file handle of log file
		si = segment of buffer
RETURN:		carry set if error writing log file
			ax = error returned from FileWrite
DESTROYED:	everything except bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	9/12/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteProfileArray	proc	near
	uses	bx
	.enter

	mov	cx, NUM_PAGES_OF_COUNTERS	; cx = loop counter
%out	TODD - turn hard-coded size into soft-coded size
	clr	ax				; ax = current page
		
	jcxz	done
	mov	ds, si
	clr	di, dx				; ds:si = buffer
writePage:
	; cx = countdown counter
	; ax = current page
	; ds:si = ds:dx = buffer

	push	ax, cx				; +1 : counters
	push	bx				; +2 : file handle
	mov	bx, ax				; bx = page #
	mov	ax, ds				; ax:di = buffer
	call	SingleStepGetAccountingLog	; ax:di = filled buffer

	pop	bx				; -2 : file handle
	mov	al, FILE_NO_ERRORS		; al = write flags
	mov	cx, 4000h			; cx = bytes to write
EC <	call	FileWriteNoCheckFar		; ax, cx changed	>
NEC <	call	FileWriteFar						>
	pop	ax, cx				; -1 : counters
	inc	ax
	loop	writePage
done:
	.leave
	ret
WriteProfileArray	endp

SSMovable	ends
endif	;SINGLE_STEP_PROFILING
