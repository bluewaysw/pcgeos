COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990, 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		calc16Bit.asm

AUTHOR:		Adam de Boor, Jan 11, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/93  	Updated for SDK
	Adam	1/11/90		Initial revision


DESCRIPTION:
	Calculation routines for simple, fast, 16-bit fixed-point operation.
		

	$Id: ac16Bit.asm,v 1.1 97/04/07 10:43:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CalcThreadResource		segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP16CalcPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine count value for point in the set

CALLED BY:	GLOBAL
		MSLineBasedDoLine

PASS:		ds		= ptr to locked MSetParameters block
		ds:[MSCP_vars].MN_A.MSN_16bit, MN_B.MSN_16bit
				= point to determine value for

RETURN:		ax		= value of point

DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	This is a fast version of FP48CalcPoint, as you can tell from
	the name. It uses only 12 bits of fraction, rather than 44,
	employing only the FN_high fields of the various fixed-point
	numbers it uses.
	
	Starts  with x, y at (0,0), then calculates new point as
	(x^2 - y^2 + a, 2xy + b), until x^2 + y^2 >= 4 or a maximum # of
	iterations is reached:

	X = A;
	Y = B;
	count = 1;
	loop {
		tempXPos = X
		xSquared = X * X;
		ySquared = Y * Y;
		if xSquared + ySquared >= 4, DONE:
		X = xSquared - ySquared + A;
		Y = tempXPos * Y + 2 + B;
		count ++;
		if count >= maxDwell, DONE;
	}


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	8/25/93  	Tweaked for SDK
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP16CalcPoint	proc	near
	uses	bp
	.enter

	;M48_\([a-zA-Z0-9]\)*
	; Initialize
	;
				;	X = A;
		mov	ax, ds:[MSCP_vars].MN_A.MSN_16bit
		mov	ds:[MSCP_vars].MN_X.MSN_16bit, ax
				;	Y = B;
		mov	ax, ds:[MSCP_vars].MN_B.MSN_16bit
		mov	ds:[MSCP_vars].MN_Y.MSN_16bit, ax
				;	count = 1;
		mov	ds:[MSCP_count], 1
				;	loop {
MQI_10:
	;
	; Main loop. Figure X * X first
	;
				; tempXPos = X

		mov	ax, ds:[MSCP_vars].MN_X.MSN_16bit
		mov	bp, ax		; keep here in register - it's quick
				; xSquared = x * x;
		imul	ax
		mov	cx, dx		; cx.bx = xSquared
		mov	bx, ax
		mov	si, dx		; si.di = xSquared
		mov	di, ax
	;
	; Y * Y next...
	;
				;	ySquared = y * y;
		mov	ax, ds:[MSCP_vars].MN_Y.MSN_16bit
		imul	ax
	;
	; Figure xSquared+ySquared with 24 bits of fraction and
	; 8 bits of integer so we don't overflow too drastically.
	; 		if xSquared + ySquared >= 4 then DONE
		add	di, ax
		adc	si, dx
		jc	MQI_90
		cmp	si, 4 SHL 8
		jae	MQI_90
					; cx.bx = xSquared
					; dx.ax = ySquared

				; X = xSquared - ySquared + A;
		sub	bx, ax
		sbb	cx, dx
		shl	bx, 1		; Normalize, after subtract
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1
		shl	bx, 1
		rcl	cx, 1

		shl	bx, 1		; get rounding bit
		adc	cx, ds:[MSCP_vars].MN_A.MSN_16bit	; add in msetA
		mov	ds:[MSCP_vars].MN_X.MSN_16bit, cx	; & store new M16_X

				; product	= 2 * tempXPos * Y;
		mov	ax, ds:[MSCP_vars].MN_Y.MSN_16bit
		imul	bp
		shl	ax, 1		; Normalize, after multiply
		rcl	dx, 1
		shl	ax, 1
		rcl	dx, 1
		shl	ax, 1
		rcl	dx, 1
		shl	ax, 1
		rcl	dx, 1

		shl	ax, 1		; *2
		rcl	dx, 1
		shl	ax, 1		; get rounding bit
				; Y = product + B
		adc	dx, ds:[MSCP_vars].MN_B.MSN_16bit ; round up, too
		mov	ds:[MSCP_vars].MN_Y.MSN_16bit, dx
				;		count ++;
		mov	ax, ds:[MSCP_count]
		inc	ax
		mov	ds:[MSCP_count], ax
				;		if count >= maxDwell, DONE;
		cmp	ax, ds:[MSCP_maxDwell]
		jae	MQI_93
				;	} loop
		jmp	MQI_10
MQI_90:
		mov	ax, ds:[MSCP_count]	; load most-recent count
MQI_93:
	.leave
	ret

FP16CalcPoint	endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP16Add
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Integer Addition

		Adds two 16 bit numbers

CALLED BY:	GLOBAL

PASS:	ds:si	- ptr to A
	ds:bx	- ptr to B
	ds:di	- ptr to C


RETURN:		C = A + B

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FP16Add		proc	near
		mov	ax, ds:[si]		; Add values
		add	ax, ds:[bx]
		mov	ds:[di], ax		; & store
		ret
FP16Add		endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP16Sub
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Integer Subtraction

		Subtracts two signed words.

CALLED BY:	GLOBAL

PASS:	ds:si	- ptr to A
	ds:bx	- ptr to B
	ds:di	- ptr to C

RETURN:		C = A - B

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		lofty pseudo code here;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FP16Sub		proc	near
		mov	ax, ds:[si]		; Add values
		sub	ax, ds:[bx]
		mov	ds:[di],ax		; & store
		ret
FP16Sub		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FP16Copy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a word

CALLED BY:	EXTERNAL
PASS:		ds:[si]	= FixNum to copy
		ds:[di]	= FixNum to which to copy it
RETURN:		Nothing
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	1/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FP16Copy		proc	near
		mov	ax, ds:[si]		; copy integer
		mov	ds:[di],ax
		ret
FP16Copy		endp

CalcThreadResource		ends
