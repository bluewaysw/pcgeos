
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		floatConstants.asm

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
	File containing routines that place commonly used numeric constants
	on the floating point stack.
		
	$Id: floatConstants.asm,v 1.1 97/04/05 01:22:56 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	Float0, Float1, Float2, Float10 (originally 0., 1., 2., 10.)

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		nothing

RETURN:		constant C on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	1. 2. // FCONSTANT .5
	1. FCONSTANT +INF    7FFF ' +INF  >BODY 8+ !
	1. FCONSTANT -INF    FFFF ' -INF  >BODY 8+ !

	: FVAR   ( KMB 850613 )( DJL 890424 )
	   CREATE F,   ( FP: X --- )
	   ;CODE
	   BX PUSH   CS PUSH   AX, # 3 ADD   BX, AX MOV
	   CX, CX XOR   CX, CS: DATAFLAG XCHG   CX DEC   1$ JZ   2$ JNS
	   ( retrieve )   AX, # ' LEFfetch MOV   AX JMPI
	  1$: ( store )   AX, # ' LEF! MOV   AX JMPI
	  2$: ( increment )  AX, # ' LEF+! MOV   AX JMPI
	   END-CODE

	: FVARS   0   DO 0. FVAR   LOOP ;   ( N --- ) ( KMB 85 06 06 )

	: FLOAT   ( D --- ) ( FP: --- X ) ( uses DPL ) ( KMB 861108 )
	  D->F   DPL fetch 8000 -
	  IF DPL fetch ?DUP
	    IF 1. DUP ABS 0   DO 10.*   LOOP
	      0<   IF **   ELSE //   THEN
	    THEN
	  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMinus16382	proc	near
	mov	ax, -16382
	cwd
	call	FloatDwordToFloat
	ret
FloatMinus16382	endp

FloatMinus1	proc	near
	call	Float1
	call	FloatNegate		; destroys nothing
	ret
FloatMinus1	endp

FloatMinusPoint5	proc	near
	call	FloatPoint5		; destroys ax,dx
	call	FloatNegate		; destroys nothing
	ret
FloatMinusPoint5	endp

Float0	proc	near	uses	si
	.enter
	mov	si, offset cs:table0
	call	PushFPNum
	.leave
	ret
Float0	endp

FloatPoint5	proc	near	uses	si
	.enter
	mov	si, offset cs:tablePoint5
	call	PushFPNum
	.leave
	ret
FloatPoint5	endp

Float1 proc	near	uses	si
	.enter
	mov	si, offset cs:table1
	call	PushFPNum
	.leave
	ret
Float1	endp

Float2 proc	near	uses	si
	.enter
	mov	si, offset cs:table2
	call	PushFPNum
	.leave
	ret
Float2	endp

Float5	proc	near	uses	si
	.enter
	mov	si, offset cs:table5
	call	PushFPNum
	.leave
	ret
Float5	endp

Float10 proc	near	uses	si
	.enter
	mov	si, offset cs:table10
	call	PushFPNum
	.leave
	ret
Float10	endp

Float16384	proc	near
	clr	dx
	mov	ax, 16384
	call	FloatDwordToFloat
	ret
Float16384	endp

table0	label	word
	word	0, 0, 0, 0, 0

tablePoint5	label	word
	word	0, 0, 0, 8000h, 3ffeh

table1	label	word
	word	0, 0, 0, 8000h, 3fffh

table2	label	word
	word	0, 0, 0, 8000h, 4000h

table5	label	word
	word	0, 0, 0, 0a000h, 4001h

table10	label	word
	word	0, 0, 0, 0a000h, 4002h


;
; number of seconds in a minute
;
Float3600 proc	near	uses	si
	.enter
	mov	si, offset cs:table3600
	call	PushFPNum
	.leave
	ret
Float3600	endp

;
; number of seconds in a day
;
Float86400 proc	near	uses	si
	.enter
	mov	si, offset cs:table86400
	call	PushFPNum
	.leave
	ret
Float86400	endp

table3600	label	word
	word	0, 0, 0, 0e100h, 400ah

table86400	label	word
	word	0, 0, 0, 0a8c0h, 400fh


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatErr (originally FERR)

DESCRIPTION:	Pushes the error NAN onto the fp stack.

CALLED BY:	INTERNAL ()

PASS:		nothing

RETURN:		error NAN on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatErr	proc	near	uses	si
	.enter
	mov	si, offset cs:tableErr
	call	PushFPNum
	.leave
	ret
FloatErr	endp

tableErr	label	word
	word	0, 0, 0, 0c000h, FP_NAN
