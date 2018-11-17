COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatStack.asm

AUTHOR:		jimmy lefkowitz

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision
	jimmy	6/19/92		Created math library

ROUTINES:
	Name			Description
	----			-----------
	FloatSetStackSize	change the size of the fp stack
	FloatInit		Create a floating point stack
	FloatExit		Destroy a floating point stack

DESCRIPTION:
	Routines that manipulate the stack for the floating point library.

	$Id: floatStack.asm,v 1.1 97/04/05 01:23:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatSetStackSizeFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	an extra routine to call the real routine so that
		hardware libraries can also get to this code

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/19/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	FloatSetStackSizeFar:far
FloatSetStackSizeFar	proc	far
	.enter
	call	FloatSetStackSizeInternal
	.leave
	ret
FloatSetStackSizeFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatSetStackSizeInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the size of the fp stack

CALLED BY:	GLOBAL

PASS:		ax = number of elements desired on stack

RETURN:		Void.

DESTROYED:	Nada

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/19/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	FloatSetStackSizeInternal:far
FloatSetStackSizeInternal	proc	far
	uses	cx, bx, si, di, es, ds, dx
	.enter
	;
EC <	clr	dx				;>
	mov	cx, FPSIZE
	mul	cx
EC <	tst	dx				;>
EC <	ERROR_NZ	FLOAT_STACK_SIZE_TOO_LARGE;>
EC <	call	ECCheckNumStacks		;>
EC <	push	ax, cx				;>
EC <	cmp	ax, FP_MIN_STACK_SIZE		;>
EC <	ERROR_B		FLOAT_INIT_SIZE_TOO_SMALL ;>
EC <	pop	ax, cx				;>

NOFXIP<	segmov	ds, dgroup, si			;ds <- seg addr of dgroup >
FXIP <	mov	si, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov	bx, si				;restore bx		>

	mov	si, ds:stackHanOffset		;si <- offset of FP stack handle
	mov	bx, ss:[si]			;bx <- handle of FP stack
EC <	tst	bx				;>
EC <	ERROR_Z	FLOAT_CALL_TO_SET_STACK_SIZE_BEFORE_CALL_TO_FLOAT_INIT	;>

	; fist allocate a new, temporary block to copy the current data to
	; and copy the stuff over
	mov_tr	cx, ax
	call	MemLock
	mov	ds, ax
	dec	cx
	add	cx, size FloatStackVars	; cx = total size of new block - 1
	cmp	cx, ds:[FSV_bottomPtr]
	jl	doShrink	
	je	doUnlock
	; if we don't jump then we are enlarging, so Realloc the block and
	; copy the stuff
	add	cx, 2		; 1 byte to get n bytes from n-1, and 1
				; for the extra unsed bytes at the bottom
	push	cx
	mov	ax, cx
	clr	cx
	mov	si, size FloatStackVars 
	call	MemReAlloc
	pop	cx		; cx = total size of new block - 1
	dec	cx
	push	cx
	mov	es, ax
	mov	ds, ax		; ds:si <- points to actual stack data
	mov	di, cx		
	sub	di, ds:[FSV_bottomPtr]
	add	di, si			; di = place for old data in new block
	mov	cx, ds:[FSV_bottomPtr]
	sub	cx, ds:[FSV_topPtr]
	add	di, cx
	sub	di, 2
	add	si, cx
	sub	si, 2
	shr	cx			; always even amount so move words
	std			; set the direction flag to go backwards
	rep	movsw
	cld			; unset it so noone kills me...
	pop	cx
	xchg	ds:[FSV_bottomPtr], cx
	sub	cx, ds:[FSV_bottomPtr]
	neg	cx
	add	ds:[FSV_topPtr], cx
doUnlock:
	call	MemUnlock
	.leave
	ret
doShrink:
EC <	push	cx							>
EC <	mov	cx, ds:[FSV_bottomPtr]					>
EC <	sub	cx, ds:[FSV_topPtr]					>
EC <	cmp	ax, cx							>
EC <	ERROR_L	FLOAT_RESIZE_TOO_SMALL_TO_HOLD_CURRENT_STACK_ELEMENTS	>
EC <	pop	cx							>

	dec	cx
	push	cx
	sub	cx, ds:[FSV_bottomPtr]
	add	cx, ds:[FSV_topPtr]
	segmov	es, ds
	mov	di, cx
	mov	si, ds:[FSV_topPtr]
	mov	cx, ds:[FSV_bottomPtr]
	sub	cx, ds:[FSV_topPtr]
	shr	cx			; always even amount, so move words
	rep	movsb
	pop	cx
	xchg	cx, ds:[FSV_bottomPtr]
	sub	cx, ds:[FSV_topPtr]
	sub	cx, ds:[FSV_bottomPtr]
	neg	cx
	mov	ds:[FSV_topPtr], cx
	jmp	doUnlock
FloatSetStackSizeInternal	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatInit

DESCRIPTION:	Initializes a floating point stack for the thread by
		allocating a block of memory and making note of it
		in ThreadPrivateData.

CALLED BY:	GLOBAL ()

PASS:		ax - FP stack size (# of elements)
		bl - type of stack (FloatStackType enum)

RETURN:		bx = handle of floating point stack 
		(this is needed for the coprocessor libraries
		 so normal apps won't need to worry about this)

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version
	Don	3/93		Hack for initializing fp stack linkage

-------------------------------------------------------------------------------@

FloatInit	proc	far	uses	ax,cx,dx,si,ds
	.enter

	;
	; Allocate a stack
	;
EC <	cmp	ax, FP_MIN_STACK_ELEMENTS				>
EC <	ERROR_B		FLOAT_INIT_SIZE_TOO_SMALL 			>
EC <	cmp	bl, FLOAT_STACK_TYPE_BOUND				>
EC <	ERROR_AE	BAD_FLOAT_STACK_TYPE				>
	mov	cl, FPSIZE
	mul	cl
	add	ax,  (size FloatStackVars)	;ax <- + size for variables
	mov	dx, bx				; save type in dx
	mov	cx, (mask HF_SWAPABLE or mask HF_SHARABLE) or \
		    ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8)

	; because we start out with the topPtr and the bottomPtr the same
	; when we push our first number, there is one unsed byte left at the
	; bottom of the stack.  This means that we actually neeed to allocate
	; 1 extra byte....
	inc	ax
	push	ax				;save size
	call	MemAlloc
	mov	ds, ax
	;
	; Initialize the stack variables
	;
	pop	ax				;ax <- stack size
	dec	ax				;ax <- offset to end
	mov	ds:FSV_bottomPtr, ax
	mov	ds:FSV_topPtr, ax
	mov	ds:FSV_handle, bx
	mov	ds:FSV_stackType, dl
	call	InitRandomNumber
	mov	cx, ss:[TPD_threadHandle]
	mov	ds:FSV_thread, cx		;store owning thread
	;
	; Save the old FP stack, if any
	; In the ThreadPrivateData mini-heap we have a word for storing
	; the handle of the floating-point stack for each thread.
	;
	; We need to be careful, however, that we're not linking in
	; the heap from another thread, as this thread may have been
	; duplicated from a thread that already contained a fp stack heap,
	; and all of the data in TPD_heap is copied into a new thread. So,
	; we simply compare the FSV_thread value against our thread, and
	; if the value is different, we know that no fp stack had yet
	; been allocated for this heap
	;
NOFXIP<	segmov	ds, dgroup, ax			;ds <- seg addr of dgroup >
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	si, ds:stackHanOffset		;si <- offset of FP handle
	xchg	bx, ss:[si]			;bx <- old FP stack handle
	tst	bx
	jz	storeLink

	mov	dx, bx
	call	MemLock
	mov	ds, ax
	cmp	ds:FSV_thread, cx
	je	unlockOld
	clr	dx
unlockOld:
	call	MemUnlock
	mov	bx, dx

storeLink:
	mov_tr	ax, bx				;ax <- old FP stack handle
	mov	bx, ss:[si]			;bx <- new FP stack handle
	call	MemModifyOtherInfo
	;
	; Done with the stack for now
	;
	call	MemUnlock			;unlock FP stack
EC <	call	ECCheckNumStacks					>

	.leave
	ret
FloatInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitRandomNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the random number generator w/o loading
		any
CALLED BY:	FloatInit()

PASS:		ds - seg addr of FloatStackVars
RETURN:		none
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitRandomNumber	proc	near
	uses	bx
	.enter

	mov	ds:FSV_randomX.F_exponent, BIAS+32	;2^32
	call	TimerGetDateAndTime
	ornf	dx, 0x8000				;force normalized number
	mov	ds:FSV_randomX.F_mantissa_wd3, dx
	mov	ds:FSV_randomX.F_mantissa_wd2, cx
	mov	ds:FSV_randomX.F_mantissa_wd1, bx
	mov	ds:FSV_randomX.F_mantissa_wd0, ax

	.leave
	ret
InitRandomNumber	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatExit

DESCRIPTION:	Frees floating point stack for current thread

CALLED BY:	GLOBAL ()

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/91		Initial version

-------------------------------------------------------------------------------@

FLOATEXIT	proc	far
	FALL_THRU	FloatExit
FLOATEXIT	endp

FloatExit	proc	far	uses	ax, bx, si, ds
	.enter

	;
	; Get the current FP stack
	;
NOFXIP<	segmov	ds, dgroup, ax			;ds <- seg addr of dgroup >
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	si, ds:stackHanOffset		;si <- offset of FP stack handle
	mov	bx, ss:[si]			;bx <- handle of FP stack
EC <	tst	bx				;>
EC <	ERROR_Z	FLOAT_TOO_MANY_CALLS_TO_EXIT	;>
	;
	; Get the old FP stack, if any
	;
	mov	ax, MGIT_OTHER_INFO		;ax <- MemGetInfoType
	call	MemGetInfo			;ax == old stack handle
	;
	; Free the current FP stack
	;
	call	MemFree
	;
	; Make the old FP stack the current one
	;
	mov	ss:[si], ax			;save new current stack

	.leave
	ret
FloatExit	endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckNumStacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that FloatInit() has been called a reasonable
		number of times.
CALLED BY:	FloatInit()

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/28/92		Initial version
	Don	11/4/99		Adjusted limit upward to avoid Impex
				situation that is completely valid

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FP_MAX_INIT_CALLS	equ 5

ECCheckNumStacks	proc	near
	uses	ax, bx, cx, si, ds
	.enter

	mov	cx, 1				;cx <- # of stacks
NOFXIP<	segmov	ds, dgroup, ax			;ds <- seg addr of dgroup >
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	si, ds:stackHanOffset		;si <- offset of FP handle
	mov	bx, ss:[si]			;bx <- current stack
stackLoop:
	tst	bx				;any next stack?
	jz	done				;branch if none
	inc	cx				;one more stack
	mov	ax, MGIT_OTHER_INFO		;ax <- MemGetInfoType
	call	MemGetInfo			;ax == next stack
	mov	bx, ax				;bx <- next stack handle
	jmp	stackLoop

done:
	cmp	cx, FP_MAX_INIT_CALLS		;too many calls?
	ERROR_A	FLOAT_TOO_MANY_CALLS_TO_INIT	;death...

	.leave
	ret
ECCheckNumStacks	endp

endif
