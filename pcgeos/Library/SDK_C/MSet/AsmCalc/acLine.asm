COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990, 1993 -- All Rights Reserved

PROJECT:	PC SDK
MODULE:		Sample Library -- Mandelbrot Set Library
FILE:		calcLineBasedAlg.asm

AUTHOR:		Paul DuBois, Aug 10, 1993

ROUTINES:
	Name			Description
	----			-----------
GLB	MSSetupCalcVectors	Copy in calculation vectors
GLB	MSLINEBASEDDOLINE	C stub for MSLineBasedDoLine
GLB	MSLineBasedDoLine	Assembly routine to calculate one line
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/20/93  	Updated for SDK
	Doug	5/16/90		Initial revision


DESCRIPTION:
	An algorithm to generate all points in Mandelbrot space requested.
	This one's simple -- just one line at a time.

	$Id: acLine.asm,v 1.1 97/04/07 10:43:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcThreadResource		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSSetupCalcVectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	MSSetupCalcVectors

C DECLARATION:	extern void
		_far _pascal MSSetupCalcVectors(
			MSetCalcParameters _far* mscpP,
			MSetPrecision		 precision);

SYNOPSIS:	Set up the MSCP_*Vec fields based on precision

CALLED BY:	GLOBAL
RETURN:		void
DESTROYED:	nothing
SIDE EFFECTS:	Alters MSCP_*Vec

PSEUDO CODE/STRATEGY:
	We assume that *mscpP is paragraph aligned, and furthermore starts at
	a 0 offset.  This is a safe assumption, since it should be pointing
	to the beginning of a MemLocked block, which should always have the
	correct alignment.  This assumption is critical for the operation of
	the calculation routines, which access the fields directly off a
	segment register.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/21/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention	;sets the calling conventions
MSSETUPCALCVECTORS	proc	far	mscpP:fptr,
					prec:MSetPrecision
	uses	ax,ds,si
	.enter
		lds	si, mscpP
EC<		tst	si					>
EC<		ERROR_NZ ERROR_PARAMS_NOT_AT_OFFSET_ZERO	>

	;
	; Set up vectors to reflect parameters of operation
	;
		cmp	prec, MSP_16BIT
		je	set16BitMath

;set48BitMath:
		mov	ax, offset FP48CalcPoint
		mov	ds:[MSCP_calcPointVec], ax
		mov	ax, offset FP48Copy
		mov	ds:[MSCP_copyVec], ax
		mov	ax, offset FP48Add
		mov	ds:[MSCP_addVec], ax
		mov	ax, offset FP48Sub
		mov	ds:[MSCP_subVec], ax
		jmp	afterMathSet
set16BitMath:
		mov	ax, offset FP16CalcPoint
		mov	ds:[MSCP_calcPointVec], ax
		mov	ax, offset FP16Copy
		mov	ds:[MSCP_copyVec], ax
		mov	ax, offset FP16Add
		mov	ds:[MSCP_addVec], ax
		mov	ax, offset FP16Sub
		mov	ds:[MSCP_subVec], ax
afterMathSet:
	.leave
	ret
MSSETUPCALCVECTORS	endp
	SetDefaultConvention	;restores calling conventions to defaults

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLINEBASEDDOLINE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	MSLineBasedDoLine

C DECLARATION:	extern MSetCalcReturnFlags
		_far _pascal MSLineBasedDoLine(
			word lineNum,
			_far MSetCalcParameters* mscpP,
			_far word* dataP);

PSEUDO CODE/STRATEGY:
	We assume that *mscpP is paragraph aligned, and starts at offset 0.
	This is a safe assumption, since it should be pointing to the
	beginning of a MemLocked block, which should always have the correct
	alignment.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/18/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	SetGeosConvention	;sets the calling conventions
MSLINEBASEDDOLINE	proc	far	lineNum:word,
					mscpP:fptr,
					dataP:fptr
	uses	dx,si,ds,es
	.enter
	
		mov	dx, lineNum
		lds	si, mscpP
EC<		tst	si					>
EC<		ERROR_NZ ERROR_PARAMS_NOT_AT_OFFSET_ZERO	>
		les	si, dataP

		call	MSLineBasedDoLine
		;al is already set

	.leave
	ret
MSLINEBASEDDOLINE	endp
	SetDefaultConvention	;restores calling conventions to defaults


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSLineBasedDoLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs calculations for 1 line of data

CALLED BY:	GLOBAL
PASS:		ds:0	= pointing to an MSetParameters block
		es:si	= pointing to where the calculated points should
			  be put
		dx	= y line in document to do
RETURN:		al	= MSetCalcReturnFlags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

BUGS/FIXES:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version
	dubois	8/20/93    	Modified for SDK

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSLineBasedDoLine	proc	near
retval	local	MSetCalcReturnFlagsAsm

	uses	bx,cx,dx,si,di,bp
	.enter

		clr	retval
		clr	cx			; X doc position of 0

	;
	; Set up A and B.  A should be just MSCP_left, since we're starting
	; at the beginning of a line.  Calculate B by subtracting MSCP_vRes
	; repeatedly to MSCP_top.
	;
		push	si			; save offset
		push	dx
		mov	si, offset MSCP_left	; start A at left value
		mov	di, offset MSCP_vars.MN_A
		call	ds:[MSCP_copyVec]
		mov	si, offset MSCP_top	; start B at top value
		mov	di, offset MSCP_vars.MN_B
		call	ds:[MSCP_copyVec]
		pop	dx
		mov	cx, dx
		tst	cx
		je	startLine

calculateB:
		push	cx
		mov	si, offset MSCP_vars.MN_B
		mov	bx, offset MSCP_vRes
		mov	di, offset MSCP_vars.MN_B
		call	ds:[MSCP_subVec]		; could trash: ax
				;use sub because y mset coordinate should
				;decrease as y screen coordinate increases
		pop	cx
		loop	calculateB

	;
	; For each point on this line, if the stored value is zero (the
	; point has not been calculated yet), calculate the point.
	; Continue to the next point unless there are messages waiting or
	; the line is finished.
	;
startLine:
		pop	si			; get offset
		mov	cx, ds:[MSCP_pixelWidth]	; count for line
EC<		tst	cx					>
EC<		ERROR_Z	ERROR_PIXEL_WIDTH_ZERO			>

doOnePoint:
		push	cx			; save points-left count

		mov	ax, es:[si]		; get current value
		tst	ax			; if calculated, use
		jnz	pointDone		; else calculate

		ornf	retval, mask MSCRF_BLOCK_DIRTIED
		push	si
		call	ds:[MSCP_calcPointVec]	; call point calculation routine
		;could trash:	bx,cx,dx,si,di,bp
		pop	si
		mov	es:[si], ax		; store result

pointDone:
				; Move (A,B) over to next point
		push	si
		mov	si, offset MSCP_vars.MN_A
		mov	bx, offset MSCP_hRes
		mov	di, offset MSCP_vars.MN_A
		call	ds:[MSCP_addVec]
		pop	si
		add	si, 2			; adjust data pointer

		pop	cx			; restore points-left count


		clr	bx			; get info on current thread
		call	GeodeInfoQueue		; see if a message is waiting
		tst	ax			; ax = # events in queue
		jnz	gotMessage		; abort if non-zero

		loop	doOnePoint
done:
		mov	al, retval
	.leave
	ret

gotMessage:
		ornf	retval, mask MSCRF_MESSAGE_WAITING
		jmp	done

MSLineBasedDoLine	endp

CalcThreadResource		ends
