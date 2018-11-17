
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Ups Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		parseStack.asm

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
	These are some utility routines that manipulate the argument stack
	and the corresponding floating point numbers.
		
	$Id: parseStack.asm,v 1.1 97/04/05 01:27:11 newdeal Exp $

-------------------------------------------------------------------------------@


EvalCode	segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	StacksRotateUp

DESCRIPTION:	Let x be the number of argument stack elements to rotate.
		StacksRotateUp(dx) will make the dxth item the top item.

		This routine will swap the top (x-1) argument stack elements
		with the xth element. (The top of stack is element #1).
		If the xth element is a number, the corresponding floating
		point number will be moved to the top of the floating point
		stack.

		eg.
		    for an argument stack containing
			A B C D E (E= top)
		    and a floating pt stack containing
			  1 2
		    StacksRotateUp(4) will result in
			A C D E B
			  2     1

CALLED BY:	INTERNAL (FunctionChoose, FunctionIf)

PASS:		dx - number of argument stack elements to rotate
		es:bx - pointer to the top of the argument stack

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	We will refer to the element that we want to roll to the top of
	the stacks as the "target".

	We will call FloatRoll to roll the floating point target only
	if the argument target is a number.  If it is not, the floating
	point stack need not be touched.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

RotStruct	struct
	RS_floatCount	word	; number of fp numbers affected in the roll
	RS_topArg	word	; offset to arg stack top
	RS_targetArg	word	; offset to arg stack target
	RS_priorArg	word	; offset to arg preceeding target
	RS_floatRollReq	byte	; boolean flag
RotStruct	ends

StacksRotateUp	proc	near	uses	bx,cx,dx,ds,di,si

	PR_local	local	RotStruct
	.enter

	cmp	dx, 1				; trivial reject?
	je	done				; done if so

	;
	; init vars
	;
	segmov	ds,es,ax
	mov	PR_local.RS_floatCount, 0
	mov	PR_local.RS_floatRollReq, 0
	mov	PR_local.RS_topArg, bx

	;-----------------------------------------------------------------------
	; determine if FloatRoll required

	mov	cx, dx				; cx <- target number
popLoop:
	test	es:[bx].ASE_type, mask ESAT_NUMBER	; number?
	je	checkTarget

	inc	PR_local.RS_floatCount		; inc fp number if so

checkTarget:
	cmp	cx, 1				; target reached?
	jne	nextArg				; branch if not

	mov	PR_local.RS_targetArg, bx	; save location
	test	es:[bx].ASE_type, mask ESAT_NUMBER	; number?
	je	nextArg				; branch if not

	dec	PR_local.RS_floatRollReq	; else a FloatRoll is required

nextArg:
	call	Pop1Arg				; drop this argument
	loop	popLoop				; loop while not done

	mov	PR_local.RS_priorArg, bx	; save this location

	;-----------------------------------------------------------------------
	; RS_floatRollReq = boolean - do we need to call FloatRoll
	; RS_floatCount = number of fp numbers we have to deal with

	cmp	PR_local.RS_floatRollReq, 0	; roll required?
	je	rollArgStack			; branch if not

	mov	bx, PR_local.RS_floatCount	; bx <- target
	call	FloatRoll

rollArgStack:
	;-----------------------------------------------------------------------
	; perform the roll for the argument stack
	; (the argument stack grows downwards towards low mem)

	;
	; copy the target to the top of the argument stack
	;
	mov	cx, PR_local.RS_priorArg
	mov	si, PR_local.RS_targetArg	; ds:si <- source = target
	sub	cx, si				; cx <- size of target
	push	cx				; save target size
	mov	di, PR_local.RS_topArg
	sub	di, cx				; es:di <- destination
	rep	movsb
	pop	cx				; retrieve target size

	;
	; move the rolled items over the old target
	;
	mov	di, si
	dec	di				; es:di <- destination
	sub	si, cx
	dec	si				; ds:si <- source
	mov	cx, PR_local.RS_priorArg
	sub	cx, PR_local.RS_topArg
	std
	rep	movsb
	cld

done:
	.leave
	ret
StacksRotateUp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StacksRotateDown

DESCRIPTION:	Let x be the number of argument stack elements to rotate.
		StacksRotateDown(dx) will make the top item the dxth item.

		This routine will swap the top argument stack element
		with the next (x-1) elements. (The top of stack is element #1).
		If the top element is a number, the corresponding floating
		point number will be moved accordingly.

		eg.
		    for an argument stack containing
			A B C D E (E= top)
		    and a floating pt stack containing
			  1 2   3
		    StacksRotateDown(4) will result in
			A E B C D
			  3 1 2

CALLED BY:	INTERNAL (FunctionChoose)

PASS:		dx - number of argument stack elements to rotate
		es:bx - pointer to the top of the argument stack

RETURN:		nothing

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	We will refer to the top-most element as the "target".

	We will call FloatRollDown to roll the floating point target only
	if the argument target is a number.  If it is not, the floating
	point stack need not be touched.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

RotDownStruct	struct
	RDS_floatCount		word	; number of fp numbers affected
	RDS_targetArg		word	; offset to arg stack target
	RDS_priorToTargetArg	word	; offset to arg preceeding target
	RDS_priorToRollArg	word	; offset to element dx+1
	RDS_floatRollReq	byte	; boolean flag
RotDownStruct	ends

StacksRotateDown	proc	near	uses	bx,cx,dx,ds,di,si

	PR_local	local	RotDownStruct
	.enter

	cmp	dx, 1				; trivial reject?
	je	done				; done if so

	;
	; init vars
	;
	segmov	ds,es,ax
	mov	PR_local.RDS_floatCount, 0
	mov	PR_local.RDS_floatRollReq, 0
	mov	PR_local.RDS_targetArg, bx

	;-----------------------------------------------------------------------
	; determine if FloatRollDown required

	test	es:[bx].ASE_type, mask ESAT_NUMBER	; number?
	je	doPop
	dec	PR_local.RDS_floatRollReq
doPop:
	mov	cx, dx				; cx <- target number
popLoop:
	test	es:[bx].ASE_type, mask ESAT_NUMBER	; number?
	je	nextArg
	inc	PR_local.RDS_floatCount		; inc fp number if so
nextArg:
	call	Pop1Arg				; drop this argument
	cmp	cx,dx				; dealing with target?
	jne	doLoop				; branch if not
	mov	PR_local.RDS_priorToTargetArg, bx ;save this location
	mov	si, bx
	sub	si, PR_local.RDS_targetArg	; si <- target size
doLoop:
	loop	popLoop				; loop while not done

	mov	PR_local.RDS_priorToRollArg, bx	; save this location

	;-----------------------------------------------------------------------
	; RDS_floatRollReq = boolean - do we need to call FloatRollDown
	; RDS_floatCount = number of fp numbers we have to deal with

	cmp	PR_local.RDS_floatRollReq, 0	; roll required?
	je	rollArgStack			; branch if not

	mov	bx, PR_local.RDS_floatCount	; bx <- target
	call	FloatRollDown

rollArgStack:
	;-----------------------------------------------------------------------
	; perform the roll for the argument stack
	; (the argument stack grows downwards towards low mem)
	; si = target size

	;
	; make space for target arg
	;
	mov	cx, PR_local.RDS_targetArg
	mov	di, cx
	sub	di, si				; di <- destination
	push	di				; save destination location
	push	si				; save target size
	mov	si, cx				; si <- source = target
	sub	cx, PR_local.RDS_priorToRollArg
	neg	cx				; cx <- num bytes
	rep	movsb

	;
	; copy target arg into vacated space
	;
	pop	cx				; retrieve target size
	pop	si				; retrieve location of target
	rep	movsb

done:
	.leave
	ret
StacksRotateDown	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StacksDropNArgs

DESCRIPTION:	Drops N arguments and their corresponding floating point
		numbers (if applicable) from the argument stack.

CALLED BY:	INTERNAL ()

PASS:		cx - number of arguments to drop
		es:bx - pointer to the top of the argument stack

RETURN:		es:bx - pointer to the top of the argument stack

DESTROYED:	ax, cx(=0)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

StacksDropNArgs	proc	near
	tst	cx
	je	done

dropLoop:
	call	StacksDropArg
	loop	dropLoop
done:
	ret
StacksDropNArgs	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StacksDropArg

DESCRIPTION:	Drops the argument and its corresponding floating point
		number (if applicable) from the top of the argument and
		floating point stacks.
		eg.
		    for an argument stack containing
			A B C D E (E= top)
		    and a floating pt stack containing
			  1 2 3 4
		    StacksDropArg() will result in
			A B C D
			  1 2 3

CALLED BY:	INTERNAL (FunctionChoose, FunctionIf)

PASS:		es:bx - pointer to the top of the argument stack

RETURN:		es:bx - pointer to the top of the argument stack

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

StacksDropArg	proc	near
	test	es:[bx].ASE_type, mask ESAT_NUMBER
	je	popArg

	call	FloatDrop

popArg:
	GOTO	Pop1Arg
StacksDropArg	endp

EvalCode	ends
