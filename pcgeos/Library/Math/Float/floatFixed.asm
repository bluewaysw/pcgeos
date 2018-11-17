COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatFixed.asm

AUTHOR:		John Wedgwood, Jul 10, 1991

ROUTINES:
	Name			Description
	----			-----------
GLBL	FloatPushNumberFar	Push a number on the fp stack
GLBL	FloatPopNumberFar	Pop a number from the fp stack
GLBL	FloatCompFar		Compare two numbers leaving them
GLBL	FloatCompESDIFar	Compare a number with a number on the stack
GLBL	FloatCompAndDropFar	Compare two numbers and remove them
GLBL	FloatDupFar		Duplicate the top number on the fp stack
GLBL	FloatAbsFar		Take the absolute value of a number
GLBL	FloatDropFar		Drop a value from the fp stack
GLBL	FloatPickFar		Duplicate a value from the fp stack
GLBL	FloatGetStackPointer	Get the fp-stack pointer

	FloatEnter		Lock fp stack, ds <- segment address
	FloatEnter_DSSI		Lock fp stack, ds:si <- top of stack
	FloatEnter_ES		Lock fp stack, es <- segment address

	FloatOpDone		Release the fp stack pointed at by ds
	FloatOpDone_ES		Release fp stack pointed at by es
	
	FloatGetStackHan	Get memory handle of fp stack

	FloatPushNumber		Push a number on the locked fp stack
	FloatPopNumber		Pop a number from the locked fp stack
	
	FloatGetSP_DSSI		Get stack pointer into ds:si
	FloatGetSP_ESDI		Get stack pointer into es:di
	
	FloatDecSP		Decrement fp stack pointer pointed at by ds
	FloatDecSP_FPSIZE	Decrement fp stack pointer pointed at by ds

	CheckOverflow		Check for stack overflow

	FloatDecSP_ES_FPSIZE	Decrement fp stack pointer pointed at by es
	
	FloatIncSP		Increment fp stack pointer pointed at by ds
	FloatIncSP_FPSIZE	Increment fp stack pointer pointed at by ds
	
	CheckUnderflow		Check for stack underflow

	FloatIsNoNAN1		Check number on locked fp stack being NAN
	FloatIsInfinity		Check number on locked fp stack being infinity

	FloatComp		Compare numbers on the locked fp stack
	FloatCompESDI		Compare number with value on locked fp stack
	FloatCompAndDrop	Compare numbers on locked fp stack, remove them

	FloatDup		Duplicate the top number on locked fp stack
	FloatPick		Duplicate a number on locked fp stack
	FloatAbs		Take absolute value of number on locked fp stack

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 7/10/91	Initial revision

DESCRIPTION:
	Floating point code that belongs in fixed resources in order to
	eliminate the ~730 cycle overhead that goes along with each floating
	point call.

	$Id: floatFixed.asm,v 1.1 97/04/05 01:23:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatPushNumberFar

DESCRIPTION:	Pushes a given floating point number onto the floating
		point stack.

CALLED BY:	GLOBAL ()

PASS:		ds:si - 5 word (80 bit) fp number

RETURN:		carry clear if successful

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatPushNumberFar	proc	far	uses	es
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	
	call	FloatEnter_ES		; es <- fp stack seg
	call	FloatPushNumber
	call	FloatOpDone_ES		; unlock fp stack
	.leave
	ret
FloatPushNumberFar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatPopNumberFar

DESCRIPTION:	Pops a floating point number off the floating point stack
		into the given location.

CALLED BY:	GLOBAL (FloatAsciiToFloat)

PASS:		es:di - location to store 5 words

RETURN:		carry clear if successful

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatPopNumberFar	proc	far	uses	ds,si
	.enter
	call	FloatEnter		; ds <- fp stack seg
	call	FloatPopNumber
	call	FloatOpDone		; unlock fp stack
	.leave
	ret
FloatPopNumberFar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCompFar

DESCRIPTION:	Compares 2 floating point numbers.
		See also FloatCompAndDropFar.

CALLED BY:	GLOBAL ()

PASS:		X1, X2 on fp stack (X2 = top)

RETURN:		flags set by what you may consider to be a cmp X1,X2
		X1, X2 intact

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatCompFar	proc	far	uses	ds
	.enter
	call	FloatEnter
	call	FloatComp
	lahf
	mov	ds:[FSV_status], ax		; put flags in the status
	call	FloatOpDone
	.leave
	ret
FloatCompFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatCompESDIFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the fp number on the stack to a number pointed at 
		by es:di.

CALLED BY:	GLOBAL ()
PASS:		X1 pointed at by es:di
		X2 pointed at by ds:si
RETURN:		flags set by what you may consider to be a 'cmp es:di, ds:si'
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatCompESDIFar	proc	far
	uses	ds
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	
	call	FloatEnter
	call	FloatCompESDI
	lahf
	mov	ds:[FSV_status], ax		; put flags in the status
	call	FloatOpDone
	.leave
	ret
FloatCompESDIFar	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCompAndDropFar

DESCRIPTION:	Compares 2 floating point numbers.
		See also FloatCompFar.

CALLED BY:	GLOBAL ()

PASS:		X1, X2 on fp stack (X2 = top)

RETURN:		flags set by what you may consider to be a cmp X1,X2
		X1, X2 popped off

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatCompAndDropFar	proc	far	uses	ds
	.enter
	call	FloatEnter
	call	FloatCompAndDrop
	lahf
	mov	ds:[FSV_status], ax		; put flags in the status
	call	FloatOpDone
	.leave
	ret
FloatCompAndDropFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatDupFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate the top most entry on the fp-stack

CALLED BY:	Global
PASS:		nothing
RETURN:		carry set on error
		al = FloatErrorType
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	 7/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLOATDUP	proc	far
	uses	ds
	.enter
	call	FloatEnter		; ds <- segment address of fp stack
	call	FloatDup		; Call local routine
	
	call	FloatIsNoNAN1		; is the result an error code?
	cmc				; carry is a boolean, so flip bit

	jnc	done

	call	FloatIsInfinity		; al <- error code
	stc				; FloatIsInfinity clears carry if non-inf

done:
	call	FloatOpDone		; unlock the fp stack
	.leave
	ret
FLOATDUP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatAbsFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the absolute value of the top number on the fp stack.

CALLED BY:	Global
PASS:		nothing
RETURN:		carry set on error
		al	= FloatErrorType
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FLOATABS	proc	far
	uses	ds
	.enter
	call	FloatEnter		; ds <- segment address of fp stack
	call	FloatAbs		; Call local routine
	
	call	FloatIsNoNAN1		; is the result an error code?
	cmc				; carry is a boolean, so flip bit

	jnc	done

	call	FloatIsInfinity		; al <- error code
	stc				; FloatIsInfinity clears carry if non-inf

done:
	call	FloatOpDone		; unlock the fp stack
	.leave
	ret
FLOATABS	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDropFar

DESCRIPTION:	

CALLED BY:	GLOBAL ()

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing, flags remain intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	don't want FloatDispatch to call FloatIsNoNAN1 on what remains

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATDROP	proc	far	uses	ds
	.enter
	pushf
	call	FloatEnter
	FloatDrop	trashFlags
	call	FloatOpDone
	popf
	.leave
	ret
FLOATDROP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatPickFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate some number on the fp stack

CALLED BY:	Global
PASS:		bx = which number to duplicate
RETURN:		carry set on error
		al	= FloatErrorType
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatPickFar	proc	far
	uses	ds
	.enter
	call	FloatEnter		; ds <- segment address of fp stack
	call	FloatPick		; Call local routine
	
	call	FloatIsNoNAN1		; is the result an error code?
	cmc				; carry is a boolean, so flip bit

	jnc	done

	call	FloatIsInfinity		; al <- error code
	stc				; FloatIsInfinity clears carry if non-inf

done:
	call	FloatOpDone		; unlock the fp stack
	.leave
	ret
FloatPickFar	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetStackPointer

DESCRIPTION:	Primarily for use by applications for error recovery.
		Applications can bail out of involved operations by saving
		the stack pointer prior to commencing operations and
		restoring the stack pointer in the event of an error.

		NOTE:
		-----
		If you set the stack pointer, the current stack pointer
		must be less than or equal to the value you pass. Ie.
		you must be throwing something (or nothing) away.

CALLED BY:	GLOBAL ()

PASS:		nothing

RETURN:		ax - stack pointer

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FLOATGETSTACKPOINTER	proc	far	uses	ds, bx, dx
	.enter
	call	FloatEnter

	; save the difference so if the stack depth changes we end up
	; at the same relative place in the stack on StackSetPointer
	mov	ax, ds:FSV_bottomPtr
	sub	ax, ds:FSV_topPtr
	clr	dx			; dx:ax = difference
	mov	bx, FPSIZE
	div	bx			; ax = quotient
	; the quotient should always have zxero remainder
EC <	tst	dx							>
EC <	ERROR_NZ	FLOAT_BAD_STACK_POINTER				>
	call	FloatOpDone
	.leave
	ret
FLOATGETSTACKPOINTER	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatEnter, FloatEnter_DSSI, FloatEnter_ES

DESCRIPTION:	Called by the global routines to lock the fp stack prior
		to access.

CALLED BY:	INTERNAL (many)

PASS:		nothing

RETURN:		FloatEnter
		    ds - seg addr of fp stack
		FloatEnter_DSSI
		    ds - seg addr of fp stack
		    si - offset to top of stack
		FloatEnter_ES
		    es - seg addr of fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatEnter	proc	far	uses	ax,bx
	.enter
	call	FloatGetStackHan	; bx <- mem han
	call	MemLock			; ax <- seg addr
	mov	ds, ax
EC<	call	FloatCheckStack >
	.leave
	ret
FloatEnter	endp

FloatEnter_DSSI	proc	far	uses	ax,bx
	.enter
	call	FloatGetStackHan	; bx <- mem han
	call	MemLock			; ax <- seg addr
	mov	ds, ax
EC<	call	FloatCheckStack >
	mov	si, ds:FSV_topPtr
	.leave
	ret
FloatEnter_DSSI	endp

FloatEnter_ES	proc	far	uses	ax,bx
	.enter
	call	FloatGetStackHan	; bx <- mem han
	call	MemLock			; ax <- seg addr
	mov	es, ax
EC<	call	FloatCheckStack_ES >
	.leave
	ret
FloatEnter_ES	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatOpDone

DESCRIPTION:	This routine unlocks the fp stack.  Called by the global
		routines when they are done accessing the fp stack.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg

RETURN:		nothing

DESTROYED:	nothing, flags are preserved

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatOpDone	proc	far	uses	bx
	.enter

EC<	call	FloatCheckStack >

	mov	bx, ds:FSV_handle
	call	MemUnlock

	.leave
	ret
FloatOpDone	endp


FloatOpDone_ES	proc	far	uses	bx
	.enter

EC<	call	FloatCheckStack_ES >

	mov	bx, es:FSV_handle
	call	MemUnlock

	.leave
	ret
FloatOpDone_ES	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetStackHan

DESCRIPTION:	Retrieves the fp stack handle from the thread's
		ThreadPrivateData.

CALLED BY:	INTERNAL ()

PASS:		nothing

RETURN:		bx - fp stack handle

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatGetStackHan	proc	far	uses	ds
	.enter

	;
	; Get the offset
	;
NOFXIP<	segmov	ds, dgroup, ax			;ds <- seg addr of dgroup >
FXIP <	mov_tr	ax, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefDS			;ds = dgroup		>
FXIP <	mov_tr	bx, ax				;restore bx		>
	mov	bx, ds:stackHanOffset		;bx <- offset of handle
	mov	bx, ss:[bx]			;bx <- handle of FP stack
EC <	tst	bx				;>
EC <	ERROR_Z	FLOAT_INIT_HAS_NOT_BEEN_CALLED_FOR_THIS_THREAD	;>

EC<	call	ECCheckMemHandle >
	.leave
	ret
FloatGetStackHan	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatPushNumber

DESCRIPTION:	Pushes a given floating point number onto the floating
		point stack.

CALLED BY:	INTERNAL (FloatPushNumberFar)

PASS:		ds:si - 5 word (80 bit) fp number
		es - fp stack seg

RETURN:		carry clear if successful

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatPushNumber	proc	far	uses	cx,di,si
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	call	FloatDecSP_ES_FPSIZE
	mov	di, es:FSV_topPtr	; es:di <- top of fp stack

	mov	cx, FPSIZE/2
	rep	movsw
	clc
	.leave
	ret
FloatPushNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatPopNumber

DESCRIPTION:	Pops a floating point number off the floating point stack
		into the given location.

CALLED BY:	INTERNAL (FloatFloatToAscii, FloatPopNumberFar)

PASS:		ds - fp stack seg
		es:di - location to store 5 words

RETURN:		carry clear if successful

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatPopNumber	proc	far	uses	cx,di,si
	.enter
;	call	FloatGetSP_DSSI		; ds:si <- top of fp stack
	FloatGetSP_DSSI
	call	FloatIncSP_FPSIZE	; drop number

	mov	cx, FPSIZE/2
	rep	movsw
	clc
	.leave
	ret
FloatPopNumber	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatGetSP_DSSI, FloatGetSP_ESDI

DESCRIPTION:	Get the address of the top of the fp stack.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack segment

RETURN:		FloatGetSP_DSSI: ds:si - top of fp stack
		FloatGetSP_ESDI: es:di - top of fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@
if 0
FloatGetSP_DSSI	proc	far
EC<	call	FloatCheckStack >

	mov	si, ds:FSV_topPtr
	ret
FloatGetSP_DSSI	endp

FloatGetSP_ESDI	proc	far
EC<	call	FloatCheckStack >

	segmov	es, ds, di
	mov	di, ds:FSV_topPtr
	ret
FloatGetSP_ESDI	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDecSP_ES_FPSIZE

DESCRIPTION:	Decrement the fp stack pointer by FPSIZE.

CALLED BY:	INTERNAL (FloatPushNumber)

PASS:		es - fp stack seg

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
			es may change, as the stack may grow, but it
			will always point to the right thing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDecSP_ES_FPSIZE	proc	far	uses	ds, ax
	.enter
EC<     call    FloatCheckStack_ES >

	sub     es:FSV_topPtr, FPSIZE		; decrement
	segmov	ds, es, ax
	call	CheckOverflow
	segmov	es, ds, ax
	.leave
	ret
FloatDecSP_ES_FPSIZE	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDecSP, FloatDecSP_FPSIZE

DESCRIPTION:	Decrement the fp stack pointer by the amount specified.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack segment
		FloatDecSP
		    cx - number to decrement stkTop by

RETURN:		carry clear if successful
		carry set if stack overflow

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDecSP	proc	far
EC<     call    FloatCheckStack >
	sub     ds:FSV_topPtr, cx		; decrement
	GOTO	CheckOverflow
FloatDecSP	endp
 
FloatDecSP_FPSIZE	proc	far
EC<     call    FloatCheckStack >
	sub     ds:FSV_topPtr, FPSIZE		; decrement
	FALL_THRU	CheckOverflow
FloatDecSP_FPSIZE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckOverflow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sees if the stack is going to overflow

CALLED BY:	GLOBAL

PASS:		ds = locked down fp stack address

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	depending on the type of stack, there is different
			behavoir by the stack. The three types of stacks
			are :

			FLOAT_STACK_GROW - allocate more space when needed
			FLOAT_STACK_WRAP - drop off bottom half of stack
			FLOAT_STACK_ERROR - return an error (carry flag)

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/26/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckOverflow	proc	far
	cmp	ds:FSV_topPtr, size FloatStackVars
	clc					; assume ok
	jge	done				; done if ok
	; now see what to do in case of overflow
	; choices are:	GROW the stack
	; 		WRAP knock off the bottom half of the stack
	;		ERROR return the carry set and let caller deal with it
	
	cmp	ds:FSV_stackType, FLOAT_STACK_ERROR
	je	doneError
	push	ax, cx, dx, bx
	clr	dx
	mov	ax, ds:FSV_bottomPtr
	sub	ax, ds:FSV_topPtr
	mov	cx, FPSIZE
	div	cx
	dec	ax
	cmp	ds:FSV_stackType, FLOAT_STACK_GROW
	je	growStack
	cmp	ds:FSV_stackType, FLOAT_STACK_WRAP
	je	wrapStack
doneError:
	stc
EC<	ERROR_C	FLOAT_STACK_OVERFLOW >
done:
	ret
growStack:
	add	ax, FLOAT_STACK_GROW_AMOUNT
	add	ds:FSV_topPtr, FPSIZE
	mov	bx, ds:FSV_handle
	call	FloatSetStackSizeInternal
	call	MemDerefDS			; block may have moved
doneCommon:
	sub	ds:FSV_topPtr, FPSIZE
	pop	ax, cx, dx, bx
	jmp	done
wrapStack:
	push	di, si, es
	; we are going to get rid of the bottom INT((n+1)/2) elements
	; on the stack, and move up the remaining ones
	add	ds:FSV_topPtr, FPSIZE
	mov	dx, 01h
	and	dx, ax			; check for even or odd
	shr	ax
	mov	bx, ax			; number of numbers eliminated
	tst	dl
	jz	contWrap
	inc	bx
	mov	dx, FPSIZE		; if odd, ds:si must move up one fpNum
contWrap:
	mul	cl			; ax = # of bytes to copy up
	mov_tr	cx, ax
	segmov	es, ds, di
	mov	di, ds:FSV_bottomPtr
	sub	di, 2
	mov	si, ds:FSV_bottomPtr
	sub	si, ds:FSV_topPtr
	sub	si, cx			
	add	si, size FloatStackVars ; ds:si = source data
	sub	si, 2
	sub	si, dx			; adjust for even, odd
	push	cx
	shr	cx			; move in words since always even
	std
	rep	movsw
	cld
	pop	cx
	mov	ax, ds:FSV_bottomPtr
	sub	ax, cx
	mov	ds:FSV_topPtr, ax
NOFXIP<	segmov	es, dgroup, di						>
FXIP <	mov	di, bx							>
FXIP <	mov	bx, handle dgroup					>
FXIP <	call	MemDerefES		; es = dgroup			>
FXIP <	mov	bx, di			; restore bx			>
	sub	es:[stackDepth], bx
	pop	di, si, es
	jmp	doneCommon
CheckOverflow	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIncSP, FloatIncSP_FPSIZE

DESCRIPTION:	Increment the fp stack pointer by the amount specified.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack segment
		FloatIncSP
		    cx - number to increment stkTop by

RETURN:		carry clear if successful
		carry set if stack underflow

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatIncSP	proc	far	uses	cx
	.enter
EC<     call    FloatCheckStack >
	add     ds:FSV_topPtr, cx			; increment
	call	CheckUnderflow
	.leave
	ret
FloatIncSP	endp

FloatIncSP_FPSIZE	proc	far	
	uses	cx
	.enter
EC<     call    FloatCheckStack >
	add     ds:FSV_topPtr, FPSIZE		; increment
	call	CheckUnderflow
	.leave
	ret
FloatIncSP_FPSIZE	endp

CheckUnderflow	proc	far
	mov	cx, ds:FSV_topPtr
	cmp	cx, ds:FSV_bottomPtr		; compare with stack bottom
	clc					; assume ok
	jle	exit				; done if ok
	stc					; else underflow
exit:
EC<	ERROR_C	FLOAT_STACK_UNDERFLOW >
	ret
CheckUnderflow	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIsNoNAN1 (originally /?NONAN1)

DESCRIPTION:	Tells if the topmost number on the fp stack is not an error.
		( X --- X F )

CALLED BY:	INTERNAL (many)

PASS:		ds - fp stack seg

RETURN:		carry - set if NOT an error code,
			clear otherwise.

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatIsNoNAN1	proc	far	uses	si
	.enter
EC<	call	FloatCheck1Arg >

;	call    FloatGetSP_DSSI         ; ds:si <- top of fp stack
	FloatGetSP_DSSI
	call	FloatIsNoNANCommon	
	.leave
	ret
FloatIsNoNAN1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatIsNoNANCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	tests for a NAN for any float (not neccesarily on fp stack)

CALLED BY:	GLOBAL

PASS:		ds:si = float

RETURN:		carry - set if NOT an error code,
			clear otherwise.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	1/14/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FloatIsNoNANCommon	proc	far
	.enter
	mov	ax, ds:[si].F_exponent	; ax <- exponent
	and	ah, 7fh			; clear sign bit
	inc	ax			; 7fffh ?
	clc				; assume error
	jo	done			; branch if assumption correct
	stc				; else indicate not error
done:
	.leave
	ret
FloatIsNoNANCommon	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatIsInfinity

DESCRIPTION:	Tells if the topmost fp number is infinity

CALLED BY:	INTERNAL (FloatFloatToAscii)

PASS:		number on fp stack
		ds - fp stack seg

RETURN:		carry - boolean bit
			set if TRUE
SBCS<			dl - ASCII '+' if +infinity, '-' otherwise	>
DBCS<			dx - ASCII '+' if +infinity, '-' otherwise	>
			al - FloatErrorType
		carry clear otherwise

DESTROYED:	ah,dh

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatIsInfinity	proc	far	uses	si
	.enter
EC<	call	FloatCheck1Arg >

;	call	FloatGetSP_DSSI
	FloatGetSP_DSSI
	mov	ax, ds:[si].F_exponent	; get exponent

	mov	dx, ax
	test	dh, 80h
	mov	dx, FLOAT_POS_INFINITY shl 8 or '+'
	je	signGotten
	
	mov	dx, FLOAT_NEG_INFINITY shl 8 or '-'

signGotten:
	and	ah, 7fh			; ignore sign bit
	xor	ax, 7fffh		; toggle all exponent bits
	jnz	notInf

	cmp	ds:[si].F_mantissa_wd3, 8000h
					; infinity has mantissa = 8000...000h
	jne	notInf

	clr	ax
	cmp	ax, ds:[si].F_mantissa_wd2
	jnz	notInf

	cmp	ax, ds:[si].F_mantissa_wd1
	jnz	notInf

	cmp	ax, ds:[si].F_mantissa_wd0
	stc
	jz	done

notInf:
	clc

done:
	mov	al, FLOAT_GEN_ERR
	jnc	quit

	mov	al, dh

quit:
DBCS<	mov	dh, 0	; (can't change Carry)  Make ASCII into Unicode!  >

	.leave
	ret
FloatIsInfinity	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatComp (originally /FCOMP)

DESCRIPTION:	FloatComp works only with normalized operands
		( fp: X1 X2 --- X1 X2 )

CALLED BY:	INTERNAL (FloatCompAndDrop)

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		flags set by what you may consider to be a cmp X1,X2
		X1, X2 intact

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatComp	proc	far	uses	si,es,di
	.enter
EC<	call	FloatCheck2Args >

;	call	FloatGetSP_DSSI			; ds:si <- top of fp stack
	FloatGetSP_DSSI
	segmov	es, ds, di			; es:di <- 2nd # on stack
	lea	di, ds:[si + size FloatNum]	; (2nd # is "X1")
	
	call	FloatCompPtr			; Compare ds:si to es:di
	.leave
	ret
FloatComp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatCompESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare the top number on the stack with a number pointed
		at by es:di.

CALLED BY:	External
PASS:		ds	= fp stack segment
RETURN:		flags set by what you may consider to be a 'cmp es:di, ds:si'
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Watch out. It's easy to think that the comparison is going to be
		cmp	(ds:si), (es:di)
	and it's just the opposite.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatCompESDI	proc	near
	uses	si
	.enter
EC<	call	FloatCheck1Arg >
;	call	FloatGetSP_DSSI			; ds:si <- top of fp stack
	FloatGetSP_DSSI
	call	FloatCompPtr			; Do the comparison
	.leave
	ret
FloatCompESDI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FloatCompPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare 2 fp numbers

CALLED BY:	FloatComp
PASS:		ds:si	= First number
		es:di	= Second number	
RETURN:		flags set by what you may consider to be a "cmp es:di, ds:si"
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 7/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FloatCompPtr	proc	far
	uses	bx, cx
	.enter
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		pushdw	bxsi						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		movdw	bxsi, esdi					>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		popdw	bxsi						>
endif
	;
	; es:di	= X1
	; ds:si	= X2
	;
	mov	ax, ds:[si].F_exponent		; ax <- exp2
	mov	bx, es:[di].F_exponent		; bx <- exp1

	mov	cx, ax
	or	cx, bx
	and	cx, 7fffh
	LONG jz	equal

	mov	cx, ax
	xor	cx, bx				; equal signs and exponents?
	je	sameSignsAndExponents		; branch if so

	;
	; signs and/or exponents differ
	;
	test	ah, 80h				; X2 negative?
	jnz	1$				; branch if so

	;
	; X2 positive
	;
	test	bh, 80h				; X1 negative?
	jnz	lesser				; branch if so, X1 < X2

	; X1 also positive
	cmp	ax, bx
	jl	greater

	jg	lesser

1$:
	;
	; X2 negative
	;
	test	bh, 80h				; X1 negative?
	jz	greater				; branch if not

	; X1 also negative
	cmp	ax, bx
	ja	greater

lesser:
	;
	; X1 < X2
	;
	clr	bx
	jmp	short done

greater:
	;
	; X1 > X2
	;
	mov	bx, 2				; bx <- 2
	jmp	short done

sameSignsAndExponents:
	;
	; equal signs and exponents
	;
	and	ah, 80h				; positive?
	jz	bothPositive

	; both arguments negative
	mov	ax, ds:[si].F_mantissa_wd3
	cmp	ax, es:[di].F_mantissa_wd3	; X2 - X1
	jb	lesser
	ja	greater

	mov	ax, ds:[si].F_mantissa_wd2
	cmp	ax, es:[di].F_mantissa_wd2
	jb	lesser
	ja	greater

	mov	ax, ds:[si].F_mantissa_wd1
	cmp	ax, es:[di].F_mantissa_wd1
	jb	lesser
	ja	greater

	mov	ax, ds:[si].F_mantissa_wd0
	cmp	ax, es:[di].F_mantissa_wd0
	jb	lesser
	ja	greater

	jmp	short equal

bothPositive:
	;
	; both arguments positive
	;
	mov	ax, ds:[si].F_mantissa_wd3
	cmp	ax, es:[di].F_mantissa_wd3
	jb	greater
	ja	lesser

	mov	ax, ds:[si].F_mantissa_wd2
	cmp	ax, es:[di].F_mantissa_wd2
	jb	greater
	ja	lesser

	mov	ax, ds:[si].F_mantissa_wd1
	cmp	ax, es:[di].F_mantissa_wd1
	jb	greater
	ja	lesser

	mov	ax, ds:[si].F_mantissa_wd0
	cmp	ax, es:[di].F_mantissa_wd0
	jb	greater
	ja	lesser

equal:
	;
	; both numbers equal
	;
	mov	bx, 1				; bx <- 1

done:
	cmp	bx, 1				; set flags
	.leave
	ret
FloatCompPtr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCompAndDrop (originally FCOMPDROP)

DESCRIPTION:	( --- F ) ( FP: X1 X2 --- )

CALLED BY:	INTERNAL ()

PASS:		X1, X2 on the fp stack (X2 = top)

RETURN:		flags set by what you may consider to be a cmp X1,X2
		both numbers are popped off

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatCompAndDrop	proc	far
	.enter
	call	FloatComp		; destroys ax
	pushf				; preserve flags
	FloatDrop	trashFlags
	FloatDrop	trashFlags
	popf				; restore flags
	.leave
	ret
FloatCompAndDrop	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDup (originally /FDUP)

DESCRIPTION:	Duplicates the number on the top of the fp stack.
		( fp: X --- X X )

CALLED BY:	INTERNAL (many)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X duplicated on fp stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDup	proc	far	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	mov	bx, 1
	call	FloatPick		; destroys ax
	.leave
	ret
FloatDup	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatPick (originally /FPICK)

DESCRIPTION:	Selects a fp number from the fp stack.
		( N --- ) ( fp: X1 X2 ... XN --- X1 X2 ... XN X1 )

CALLED BY:	INTERNAL (FloatDup, FloatOver)

PASS:		bx - N
		ds - fp stack seg

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	achieved with a block move

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatPick	proc	far	uses	cx,es,di,si
	.enter
EC<	call	FloatCheckNArgs >

	mov	ax, FPSIZE
	cmp	bl, 1			; Check for simple case
	je	skipMul			; Branch if multiply by one
	mul	bl			; ax <- offset to fp num
skipMul:

	call	FloatDecSP_FPSIZE
;	call	FloatGetSP_ESDI		; es:di <- top of fp stack	
	FloatGetSP_ESDI

	mov	si, di
	add	si, ax
	mov	cx, FPSIZE/2
	rep	movsw
	.leave
	ret
FloatPick	endp
	public FloatPick

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatAbs (originally /FABS)

DESCRIPTION:	Gives the absolute value of the number on the top of the
		fp stack.
		( fp: X --- |X| )

CALLED BY:	INTERNAL (FloatDoExp, FloatExponential, FloatASin, FloatATan)

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		abs X on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatAbs	proc	far	uses	si
	.enter
EC<	call	FloatCheck1Arg >

;	call    FloatGetSP_DSSI         	; ds:si <- top of fp stack
	FloatGetSP_DSSI
	andnf	ds:[si].F_exponent, not (mask FE_SIGN)
	.leave
	ret
FloatAbs	endp
