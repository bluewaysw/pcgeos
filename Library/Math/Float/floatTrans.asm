
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 1/91

ROUTINES:
	Name			Description
	----			-----------
	Constants:
	----------
	FloatLn2
	FloatLn10
	FloatPi
	FloatPiDiv2
	FloatSqrt2

	Routines:
	---------
	FloatSqr
	FloatSqrt
	FloatFPNum
	FloatDoLn1plusX
	FloatLn1plusX
	FloatDoLn
	FloatLn
	FloatLog
	FloatLg
	FloatMaxExpArg
	FloatMinExpArg
	FloatExpBC
	FloatDoExp
	FloatExpC
	FloatExp
	FloatExponential
	FloatDoSin
	FloatDoCos
	FloatCos
	FloatSin
	FloatDoTan
	FloatTan
	FloatDoArcSin
	FloatArcSin
	FloatArcCos
	FloatDoArcTan
	FloatArcTan
	FloatArcTan2
	Is8087
	FloatPushAddOverMult
	FloatPushOverMult
	FloatPushAddMult
	FloatPushAdd
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial revision

DESCRIPTION:
	Transcendental Functions

	$Id: floatTrans.asm,v 1.1 97/04/05 01:23:08 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLg10

DESCRIPTION:	Pushes the log base 2 of 10 onto the floating point stack.

CALLED BY:	INTERNAL (ConvertBase10Mantissa)

PASS:		ds - fp stack seg

RETURN:		log base 2 of 10 on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLg10	proc	near	uses	si
	.enter
	mov	si, offset cs:tableLg10
	call	PushFPNum
	.leave
	ret
FloatLg10	endp

tableLg10	label	word
	word	8afeh, 0cd1bh, 784bh, 0d49ah, 4000h


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLn2

DESCRIPTION:	Pushes the natural log of 2 onto the floating point stack.

CALLED BY:	INTERNAL (many)

PASS:		ds - fp stack seg

RETURN:		ln 2 on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
.69314 .71805 .59945 .30942 0 FP# FCONSTANT |LN2  ' |LN2 ' LN2 REDIRECT

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLn2	proc	near	uses	si
	.enter
	mov	si, offset cs:tableLn2
	call	PushFPNum
	.leave
	ret
FloatLn2	endp

tableLn2	label	word
	word	079abh, 0d1cfh, 17f7h, 0b172h, 3ffeh


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLn10

DESCRIPTION:	Pushes the natural log of 10 onto the floating point stack.

CALLED BY:	INTERNAL (FloatLn10Far, FloatLog)

PASS:		ds - fp stack seg

RETURN:		ln 10 on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLn10	proc	near	uses	si
	.enter
	mov	si, offset cs:tableLn10
	call	PushFPNum
	.leave
	ret
FloatLn10	endp

tableLn10	label	word
	word	0ac16h, 0aaa8h, 8dddh, 935dh, 4000h


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatPi

DESCRIPTION:	.23846 is more accurate but loses last bit in resulting value

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg

RETURN:		PI on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
3.14159 .26535 .89793 ( .23846 ) .2385 0

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatPi	proc	near	uses	si
	.enter
	mov     si, offset cs:tablePi
	call	PushFPNum
	.leave
	ret
FloatPi	endp

tablePi	label	word
	word	0c235h, 2168h, 0daa2h, 0c90fh, 4000h

FloatPiDiv2	proc	near
	call	FloatPi
	call	FloatDivide2
	ret
FloatPiDiv2	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSqrt2 (originally SQRT2)

DESCRIPTION:	Pushes the square root of 2 onto the fp stack.

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg

RETURN:		sqrt 2 on the fp stack

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	2. SQRT FCONSTANT SQRT2

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatSqrt2	proc	near	uses	si
	.enter
	mov	si, offset cs:tableSqrt2
	call	PushFPNum
	.leave
	ret
FloatSqrt2	endp

tableSqrt2	label	word
	word	6484h, 0f9deh, 0f333h, 0b504h, 3fffh


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSqr

DESCRIPTION:	Squares the number on the top of the fp stack.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		X^2 on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatSqr	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	FloatMultiply
	.leave
	ret
FloatSqr	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSqrt

DESCRIPTION:	Gives the square root of the number on the top of the
		fp stack.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL (FloatSqrt2, FloatArcSin)

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		sqrt X on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	?NONAN1
	IF FDUP F0<
	  IF FDROP FERR
	  ELSE FDUP F0= NOT
	    IF EXP/FRAC 2 /MOD SWAP   IF -1 2SCALE 1+   THEN
	    1. 5 0 DO FOVER FOVER // ++ 2./   LOOP FSWAP FDROP 2SCALE
	    THEN
	  THEN
	THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatSqrt	proc	near	uses	bx,cx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done			; done if NAN

	call	FloatDup
	call	FloatLt0		; num < 0 ?
	jnc	ge0			; ok if so

	;
	; sqrt of negative
	;

	FloatDrop trashFlags
	call	FloatErr
	jmp	short done

ge0:
	call	FloatSign		; 0?
	je	done			; done if so

	call	FloatExpFrac		; bx <- unbiased exponent, dest ax
	mov	ax, bx
if 0
	;
	; now for Forth's /MOD
	;
	; idiv can give a negative remainder, which should not be
	;
	cwd
	mov	bx, 2
	idiv	bx			; ax <- quot, dx <- rem

	tst	dx
	je	over
else
	sar	ax, 1
	jnc	over
endif

	push	ax			; save quotient
	mov	bx, -1
	call	Float2Scale		; destroys ax
	pop	ax			; retrieve quotient
	inc	ax

over:
	push	ax			; save quotient
	call	Float1			; destroys ax,dx

	mov	cx, 5
sqrtLoop:
	call	FloatOver		; destroys ax
	call	FloatOver		; destroys ax
	call	FloatDivide		; destroys ax,dx
	call	FloatAdd		; destroys ax,dx
	call	FloatDivide2		; destroys nothing
	loop	sqrtLoop

	call	FloatSwap		; destroys ax
	FloatDrop			; destroys nothing
	pop	bx			; retrieve quotient
	call	Float2Scale		; destroys ax
done:
	.leave
	ret
FloatSqrt	endp


;
;	The following polynomial and rational approximations are taken from
;	"Computer Approximations" by J.F. Hart et al. (1968).
;

COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoLn1plusX (originally "(LN(1+X))" )

DESCRIPTION:	Evaluates natural logarithm of 1+X1 to 19+ significant digits
		for 1/2^.5 <= 1+X1 <= 2^.5.
		( FP: X1 --- X2 )

CALLED BY:	INTERNAL (FloatLn1plusX, FloatDoLn)

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		ln (1+X) on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: (LN(1+X))  ( FP: X1 --- X2 ) ( KMB 85 06 11 )
| Evaluates natural logarithm of 1+X1 to 19+ significant digits for
| 1/2^.5 <= 1+X1 <= 2^.5.  Approximation 2705.
  FDUP 2. ++ //   FDUP FDUP **
  FDUP
  [  .42108 .73712 .17979 .7145    0 FP#] FOVER **
  [ -.96376 .90933 .68686 .59324   1 FP#] ++ FOVER **
  [  .30957 .29282 .15376 .50062   2 FP#] ++ **
  [ -.24013 .91795 .59210 .50987   2 FP#] ++
  FSWAP FDUP
  [ -.89111 .09027 .93783 .12337   1 FP#] ++ FOVER **
  [  .19480 .96607 .00889 .73052   2 FP#] ++ **
  [ -.12006 .95897 .79605 .25472   2 FP#] ++
  // ** ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoLn1plusX	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	Float2
	call	FloatAdd
	call	FloatDivide
	call	FloatDup
	call	FloatDup
	call	FloatMultiply
	call	FloatDup

	mov	si, offset cs:tableLn1plusX
	call	FloatPushOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd

	call	FloatSwap		; destroys ax
	call	FloatDup		; destroys ax

	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd

	call	FloatDivide
	call	FloatMultiply
	.leave
	ret
FloatDoLn1plusX	endp

tableLn1plusX	label	word
	word	6545h, 4798h, 0c390h, 0d798h, 3ffdh
	word	0b117h, 9240h, 0fb68h, 9a33h, 0c002h
	word	21c5h, 8999h, 8923h, 0f7a8h, 4003h
	word	8e1ch, 6c10h, 8104h, 0c01ch, 0c003h
	word	5793h, 6155h, 0e70fh, 8e93h, 0c002h
	word	6b73h, 2c24h, 04bdh, 9bd9h, 4003h
	word	8e03h, 6c10h, 8104h, 0c01ch, 0c002h


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLn1plusX (originally LN(1+X))

DESCRIPTION:	( fp: X1 --- X2 )

CALLED BY:	GLOBAL ()
		no routine calls FloatLn1plusX

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		ln (1+X) on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: LN(1+X)  ( FP: X1 --- X2 ) ( KMB 85 08 19 )
  ?NONAN1
  IF FDUP -1. >>
    IF FSIGN 0< DUP   IF FDUP 1. ++ // FNEGATE   THEN   ( FS | X3 )
      FDUP 1. ++ EXP/FRAC   FDUP SQRT2 >>   IF 1+ 2./   THEN   ( FS N | X3 X4 )
      DUP   IF ( X3 not small ) 1. -- FSWAP   THEN FDROP
      (LN(1+X))   ( FS N | X5 )
      S->F LN2 ** ++   IF FNEGATE   THEN
    ELSE FDROP FERR
    THEN
  THEN ;


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLn1plusX	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	LONG jnc done

	call	FloatDup
	call	FloatMinus1
	call	FloatCompAndDrop
	jle	error

	call	FloatSign		; bx <- sign
	jge	over

	pushf
	call	FloatDup
	call	Float1
	call	FloatAdd
	call	FloatDivide
	call	FloatNegate
	popf

over:
	pushf
	call	FloatDup
	call	Float1
	call	FloatAdd
	call	FloatExpFrac		; bx <- unbiased exponent
	call	FloatDup
	call	FloatSqrt2
	call	FloatCompAndDrop
	jle	over2

	inc	bx
	push	bx
	call	FloatDivide2		; destroys ax,bx
	pop	bx

over2:
	tst	bx
	push	bx
	je	over3

	call	Float1
	call	FloatSub
	call	FloatSwap

over3:
	FloatDrop trashFlags
	call	FloatDoLn1plusX

	pop	ax			; ax <- integer
	call	FloatWordToFloat
	call	FloatLn2
	call	FloatMultiply
	call	FloatAdd

	popf
	jge	done

	call	FloatNegate
	jmp	short done

error:
	FloatDrop trashFlags
	call	FloatErr

done:
	.leave
	ret
FloatLn1plusX	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoLn (originally "|(LN)")

DESCRIPTION:	( N F | X )

CALLED BY:	INTERNAL (FloatLn)

PASS:		

RETURN:		

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
    : |(LN)
	EXP/FRAC FDUP SQRT2 >>   IF 2./ 1+   THEN   ( N F | X )
	1. -- (LN(1+X)) S->F LN2 ** ++ ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoLn	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatExpFrac		; bx <- unbiased exponent
	call	FloatDup		; destroys ax
	call	FloatSqrt2		; 
	call	FloatCompAndDrop
	jle	over

	call	FloatDivide2
	inc	bx

over:
	push	bx			; push unbiased exponent
	call	Float1
	call	FloatSub		; destroys ax,dx
	call	FloatDoLn1plusX
	pop	ax			; ax <- integer
	call	FloatWordToFloat
	call	FloatLn2
	call	FloatMultiply
	call	FloatAdd

	.leave
	ret
FloatDoLn	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLn (originally LN)

DESCRIPTION:	Performs the natural log operation on the fp number.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		ln X on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: LN   ( FP: X1 --- X2 )( KMB 850819 )( DJL 870506 )
  ?NONAN1
  IF FSIGN ?DUP
    IF 0>
       IF (LN)
       ELSE FDROP FERR  ( should be replaced by -infinity )
       THEN
    ELSE FDROP FERR
    THEN
  THEN ;


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLn	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatSign		; bx <- sign
	jle	error

	call	FloatDoLn
	jmp	short done

error:
	FloatDrop trashFlags
	call	FloatErr		; should be replaced by -infinity

done:
	.leave
	ret
FloatLn	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLog (originally LOG10)

DESCRIPTION:	Implements log to the base 10.

CALLED BY:	INTERNAL ()

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		log X on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLog	proc	near
EC<	call	FloatCheck1Arg >

	call	FloatLn

	call	FloatIsNoNAN1
	jnc	done

	call	FloatLn10
	call	FloatDivide

done:
	ret
FloatLog	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatLg

DESCRIPTION:	Implements log to the base 2.

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		lg X on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatLg	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign
	jl	err

	call	FloatExpFrac		; bx <- unbiased exponent
	FloatDrop trashFlags		; lose X
	mov	ax, bx
	call	FloatWordToFloat
	jmp	short done

err:
	FloatDrop trashFlags
	call	FloatErr

done:
	.leave
	ret
FloatLg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatMaxExpArg, FloatMinExpArg (originally MAXEXPARG, MINEXPARG)

DESCRIPTION:	Utility routines.

CALLED BY:	INTERNAL (FloatExpC, FloatExp)

PASS:		ds - fp stack seg

RETURN:		

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	LN2  16384. ** FCONSTANT MAXEXPARG
	LN2 -16382. ** FCONSTANT MINEXPARG

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatMaxExpArg	proc	near
	call	FloatLn2
	call	Float16384
	call	FloatMultiply
	ret
FloatMaxExpArg	endp

FloatMinExpArg	proc	near
	call	FloatLn2
	call	FloatMinus16382
	call	FloatMultiply
	ret
FloatMinExpArg	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatExpBC (originally |EXPBC)

DESCRIPTION:	Evaluates 2^X1-1 for 19+ significant digits for 0 <= X1 < .5.
		( FP: X1 --- X2 )

CALLED BY:	INTERNAL (FloatDoExp)

PASS:		X on the fp stack
		ds - fp stack seg

RETURN:		X on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
  Approximation 1324.
  ?NONAN1
  IF FDUP FDUP **
    FDUP
    [  .60613 .30790 .74800 .42575   2 FP#] FOVER **
    [  .30285 .61978 .21164 .59206   5 FP#] ++ **
    [  .20802 .83036 .50596 .27129   7 FP#] ++
    FSWAP FDUP
    [  .17492 .20769 .51057 .14559   4 FP#] ++ FOVER **
    [  .32770 .95471 .93281 .18053   6 FP#] ++ **
    [  .60024 .28040 .82517 .36653   7 FP#] ++
    // ** FDUP FNEGATE 1. ++ // 2.*
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatExpBC	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatDup
	call	FloatDup
	call	FloatMultiply
	call	FloatDup

	mov	si, offset cs:tableExpBC
	call	FloatPushOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	call	FloatSwap
	call	FloatDup
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd

	call	FloatDivide
	call	FloatMultiply
	call	FloatDup
	call	FloatNegate
	call	Float1
	call	FloatAdd
	call	FloatDivide
	call	FloatMultiply2
done:
	.leave
	ret
FloatExpBC	endp

tableExpBC	label	word
	word	1898h, 0f405h, 06fch, 0f274h, 4004h
	word	0ad08h, 14e1h, 3d54h, 0ec9bh, 400dh
	word	5fafh, 0c3a3h, 0d84ah, 0fdf0h, 4013h
	word	776fh, 387bh, 108bh, 0daa7h, 4009h
	word	0e85ch, 9b7bh, 0b182h, 0a003h, 4011h
	word	0837eh, 0e709h, 0f814h, 0b72dh, 4015h


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoExp (originally "(EXP)")

DESCRIPTION:	( --- N )( fp: X1 --- X2 )

CALLED BY:	INTERNAL (FloatExpC, FloatExp)

PASS:		ds - fp stack seg

RETURN:		bx - N

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: (EXP)   ( --- N )( FP: X1 --- X2 )( KMB 850902 )( DJL 870506 )
  LN2 // INTFRAC FSWAP F->D DROP   ( N' | XF )
  FDUP FSIGN 0<
  IF -.5 <<    IF 1. ++ 1- 0  ELSE FABS -1 THEN
  ELSE .5 >>   ANDIF 1. -- FABS 1+ -1 THEN
  THEN                                        ( N F | |XF'| )
  EXPBC   IF FDUP 1. ++ // FNEGATE   THEN ;   ( N | 2^XF'-1 )

expanded:
---------
  LN2 // INTFRAC                ( fp: int frac )
  FSWAP                         ( fp: frac int )
  F->D                          ( fp: frac )
  DROP   ( N' | XF )            ( ax )
  FDUP                          ( fp: frac frac )
  FSIGN                         ( fp: frac frac ) ( ax bx )
  0<                            ( ax )

   IF -.5 <<                    ( fp: frac ) ( ax F )
     IF
         1. ++                  ( fp: frac+1 ) ( ax )
         1-                     ( ax-1 )
         0                      ( ax-1 0 )
     ELSE
         FABS                   ( fp: frac ) ( ax )
         -1                     ( fp: frac ) ( ax -1 )
     THEN
   ELSE                         ( fp: frac frac ) ( ax )
     .5 >>                      ( fp: frac ) ( ax F )
     ANDIF
       1. -- FABS               ( fp: frac-1 )
       1+                       ( ax+1 )
       -1                       ( ax+1 -1 )
   THEN
  THEN ( N F | |XF'| )

  EXPBC

  IF FDUP 1. ++ // FNEGATE   THEN ;   ( N | 2^XF'-1 )

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoExp	proc	near	uses	cx,di
	.enter
EC<	call	FloatCheck1Arg >

	clr	cx			; init flag

	call	FloatLn2
	call	FloatDivide
	call	FloatIntFrac		; ( fp: int frac )
	call	FloatSwap		; ( fp: frac int )
	call	FloatFloatToDword		; dx:ax <- dbl
	mov	di, ax			; save N
	call	FloatDup
	call	FloatSign		; bx <- sign, ( fp: frac frac )
	jge	ge0

	;
	; < 0
	;
	call	FloatMinusPoint5
	call	FloatCompAndDrop
	jge	over2

	call	Float1
	call	FloatAdd
	dec	di
	jmp	short doneCheck

over2:
	call	FloatAbs
	dec	cx
	jmp	short doneCheck

ge0:
	;
	; >= 0
	;
	call	FloatPoint5
	call	FloatCompAndDrop

	;??? ANDIF
	jle	doneCheck

	call	Float1
	call	FloatSub
	call	FloatAbs
	inc	di
	dec	cx

doneCheck:
	call	FloatExpBC

	tst	cx
	je	done

	call	FloatDup
	call	Float1
	call	FloatAdd
	call	FloatDivide
	call	FloatNegate

done:
	mov	bx, di
	.leave
	ret
FloatDoExp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatExpC (originally EXPC)

DESCRIPTION:	( FP: X1 --- X2 )

CALLED BY:	INTERNAL (???)

PASS:		ds - fp stack seg

RETURN:		

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: EXPC   ( FP: X1 --- X2 ) ( KMB 85 09 02 )
  ?NONAN1
  IF FDUP MINEXPARG >>
    IF FDUP MAXEXPARG <<
      IF FSIGN
        IF (EXP) ?DUP   IF 1. ++ 2SCALE 1. --   THEN
        THEN
      ELSE FDROP FERR
      THEN
    ELSE FDROP -1.
    THEN
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

if 0
FloatExpC	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatDup		; destroys ax,bx,cx,dx,es
	call	FloatMinExpArg
	call	FloatCompAndDrop
	jle	cleanStack

	call	FloatDup
	call	FloatMaxExpArg
	call	FloatCompAndDrop
	jge	error

	call	FloatSign		; bx <- sign
	je	done

	call	FloatDoExp		; bx <- ???
	tst	bx
	je	done

	call	Float1
	call	FloatAdd
	call	Float2Scale
	call	Float1
	call	FloatSub
	jmp	short done

cleanStack:
	FloatDrop trashFlags
	call	FloatMinus1
	jmp	short done

error:
	FloatDrop trashFlags
	call	FloatErr
	
done:
	.leave
	ret
FloatExpC	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatExp (originally EXP)

DESCRIPTION:	Exponentiation - raises e to the given fp number.
		( FP: X1 --- X2 )

CALLED BY:	INTERNAL (FloatExponential)

PASS:		X1 on the fp stack
		ds - fp stack seg

RETURN:		X2 = e^X1 on the fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: EXP   ( FP: X1 --- X2 ) ( KMB 85 09 02 )
  ?NONAN1
  IF FDUP MINEXPARG >>
    IF FDUP MAXEXPARG <<
      IF FSIGN
        IF (EXP) 1. ++ 2SCALE
        ELSE FDROP 1.
        THEN
      ELSE FDROP FERR
      THEN
    ELSE FDROP 0.
    THEN
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatExp	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatDup
	call	FloatMinExpArg
	call	FloatCompAndDrop
	jle	cleanStack0

	call	FloatDup
	call	FloatMaxExpArg
	call	FloatCompAndDrop
	jge	error

	call	FloatSign		; bx <- sign
	je	cleanStack1

	call	FloatDoExp		; bx <- ???
	call	Float1
	call	FloatAdd
	call	Float2Scale
	jmp	short done

cleanStack0:
	FloatDrop trashFlags
	call	Float0
	jmp	short done
	
error:
	FloatDrop trashFlags
	call	FloatErr
	jmp	short done

cleanStack1:
	FloatDrop trashFlags
	call	Float1

done:
	.leave
	ret
FloatExp	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatExponential (originally ^^)

DESCRIPTION:	Exponentiation - raises one fp number to another.
		( fp: X1 X2 --- X1^X2)

CALLED BY:	GLOBAL ()

PASS:		X1, X2 on fp stack (X2 = top)
		ds - fp stack seg

RETURN:		X1^X2 on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: ^^   ( FP: X1 X2 --- X1^X2 ) ( KMB 85 08 19 )
  ?NONAN2
  IF FOVER FSIGN FDROP ?DUP
    IF 0<   ( F1 | X1 X2 )
      IF ( X1 < 0 ) INTFRAC F0=
        IF ( X2 is an integer ) FDUP F->D DROP 1 AND
          FSWAP FABS LN ** EXP   IF FNEGATE   THEN
        ELSE ( X2 is not an integer ) FDROP FDROP FERR
        THEN
      ELSE ( X1 > 0 ) FSWAP LN ** EXP
      THEN
    ELSE ( X1 = 0 ) FSIGN 0=   ( F2 | 0 X2 )
      IF ( X2 = 0 ) FDROP FDROP FERR
      ELSE ( X2 <> 0 ) FDROP
      THEN
    THEN
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatExponential	proc	near	uses	bx
	.enter
EC<	call	FloatCheck2Args >

	call	FloatIsNoNAN2
	jnc	done

	call	FloatOver
	call	FloatSign		; bx <- sign
	FloatDrop			; destroys nothing
	je	x1zero

	jg	x1gt0

	;
	; X1 < 0
	;
	call	FloatIntFrac
	call	FloatEq0		; 0 fraction?
	jnc	x2notInt		; branch if so

	;
	; X2 is an integer
	;
	call	FloatDup
	call	FloatFloatToDword		; dx:ax <- dbl
	and	ax, 1
	pushf
	call	FloatSwap
	call	FloatAbs
	call	FloatLn
	call	FloatMultiply
	call	FloatExp
	popf
	jz	done

	call	FloatNegate
	jmp	short done
	
x1gt0:
	;
	; X1 > 0
	;
	call	FloatSwap
	call	FloatLn
	call	FloatMultiply
	call	FloatExp
	jmp	short done

x1zero:
	;
	; X1 = 0
	;
	call	FloatSign
	je	x2zero

	;
	; X2 <> 0
	;
	FloatDrop
	jmp	short done

x2zero:
	;
	; X2 = 0
	;
x2notInt:
	;
	; X2 is not an integer
	;
	FloatDrop trashFlags
	FloatDrop trashFlags
	call	FloatErr
done:
	.leave
	ret
FloatExponential	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoSin (originally "|(SIN)")

DESCRIPTION:	Evaluates the sine of X1 to 17+ significant digits for
		|X1| <= PI/4
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL (FloatComputeSin)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Approximation 3043.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoSin	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	FloatDup
	call	FloatMultiply

	mov	si, offset cs:tableDoSin
	call	FloatPushOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAddMult
	.leave
	ret
FloatDoSin	endp

tableDoSin	label	word
	word	1331h, 6e5ch, 69c3h, 0f1f7h, 3fd9h
	word	0b8eh, 0d80ah, 31cch, 0f180h, 0bfe1h
	word	0c0a7h, 18f7h, 17e5h, 0a83ch, 3fe9h
	word	0cff5h, 6a97h, 6671h, 9969h, 0bff0h
	word	0f9f3h, 0ac37h, 0e33bh, 0a335h, 3ff6h
	word	04f8h, 2df2h, 0e731h, 0a55dh, 0bffbh
	word	0c205h, 2168h, 0daa2h, 0c90fh, 3ffeh


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoCos (originally "|(COS)")

DESCRIPTION:	Evaluates the cosine of X1 to 17+ significant digits for
		|X1| <= PI/4.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL (FloatComputeSin)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Approximation 3824.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoCos	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	FloatMultiply

	mov	si, offset cs:tableDoCos
	call	FloatPushOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	.leave
	ret
FloatDoCos	endp

tableDoCos	label	word
	word	0d503h, 0ac0ah, 35cch, 0d92ch, 0bfd5h
	word	05d8h, 08a6fh, 0aeah, 0fce6h, 3fddh
	word	0b176h, 0a400h, 0f61eh, 0d368h, 0bfe5h
	word	1e31h, 81f9h, 8341h, 0f0fah, 3fech
	word	0de9dh, 0e46ah, 0e3f1h, 0aae9h, 0bff3h
	word	4e2fh, 0dad5h, 0f840h, 81e0h, 3ff9h
	word	0f230h, 0f22eh, 0e64dh, 9de9h, 0bffdh
	word	0ffffh, 0ffffh, 0ffffh, 0ffffh, 03ffeh


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatComputeSin (originally |[SIN])

DESCRIPTION:	Computes sin(X1) for -2*PI < X1 < 2*PI
		( FP: X1 --- X2 )

CALLED BY:	INTERNAL (FloatSin)

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
[[ I80387 NOT ][
: |[SIN]   ( FP: X1 --- X2 )( KMB 880718 )
| Computes sin(X1) for -2*PI < X1 < 2*PI
   FSIGN 0< FABS 3 2SCALE INTFRAC FSWAP F->D DROP
   CASE
      0   OF (SIN)                 ENDOF
      1   OF FNEGATE 1. ++ (COS)   ENDOF
      2   OF (COS)                 ENDOF
      3   OF FNEGATE 1. ++ (SIN)   ENDOF
      4   OF (SIN)                 NOT   ENDOF
      5   OF FNEGATE 1. ++ (COS)   NOT   ENDOF
      6   OF (COS)                 NOT   ENDOF
      7   OF FNEGATE 1. ++ (SIN)   NOT   ENDOF
   ENDCASE   IF FNEGATE   THEN ;
]

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatComputeSin	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign		; bx <- sign
	pushf

	call	FloatAbs
	mov	bx, 3
	call	Float2Scale
	call	FloatIntFrac
	call	FloatSwap		; ( fp: frac int )
	call	FloatFloatToDword		; dx:ax <- dbl, ax <- int
	tst	ax
	je	ax0

	cmp	ax, 1
	je	ax1

	cmp	ax, 2
	je	ax2

	cmp	ax, 3
	je	ax3

	cmp	ax, 4
	je	ax4

	cmp	ax, 5
	je	ax5

	cmp	ax, 6
	je	ax6

	;
	; ax = 7
	;
	call	FloatNegate
	call	Float1
	call	FloatAdd
ax4:
	call	FloatDoSin
	jmp	short doneNegate

ax3:
	call	FloatNegate
	call	Float1
	call	FloatAdd
ax0:
	call	FloatDoSin
	jmp	short done

ax1:
	call	FloatNegate
	call	Float1
	call	FloatAdd
ax2:
	call	FloatDoCos
	jmp	short done

ax5:
	call	FloatNegate
	call	Float1
	call	FloatAdd
ax6:
	call	FloatDoCos

doneNegate:
	popf
	jge	doNegate
	jmp	short exit
done:
	popf
	jge	exit

doNegate:
	call	FloatNegate

exit:
	.leave
	ret
FloatComputeSin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatComputeTan (originally |[TAN])

DESCRIPTION:	Computes tan(X1) for -PI < X1 < PI
		( FP: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
[[ I80387 NOT ][
: |[TAN]   ( FP: X1 --- X2 )( KMB 880718 )
| Computes tan(X1) for -PI < X1 < PI
   FSIGN 0< FABS 2 2SCALE INTFRAC FSWAP F->D DROP
   CASE
      0   OF (TAN)                       ENDOF
      1   OF FNEGATE 1. ++ (TAN) 1/X     ENDOF
      2   OF FSIGN 0=
            IF FDROP FERR
            ELSE (TAN) 1/X         NOT
            THEN                         ENDOF
      3   OF FNEGATE 1. ++ (TAN)   NOT   ENDOF
   ENDCASE   IF FNEGATE   THEN ;
]

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatComputeTan	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatSign		; bx <- sign
	pushf
	call	FloatAbs
	mov	bx, 2
	call	Float2Scale
	call	FloatIntFrac
	call	FloatSwap
	call	FloatFloatToDword		; dx:ax <- dbl
	tst	ax
	je	ax0

	cmp	ax, 1
	je	ax1

	cmp	ax, 2
	je	ax2

	cmp	ax, 3
	je	ax3
	jmp	short done

ax0:
	call	FloatDoTan
	jmp	short done

ax1:
	call	FloatNegate
	call	Float1
	call	FloatAdd
	call	FloatDoTan
	call	FloatInverse
	jmp	short done

ax2:
	call	FloatSign
	je	error

	call	FloatDoTan
	call	FloatInverse
	jmp	short doneNegate

error:
	FloatDrop trashFlags
	call	FloatErr
	jmp	short done

ax3:
	call	FloatNegate
	call	Float1
	call	FloatAdd
	call	FloatDoTan

doneNegate:
	popf
	jl	exit
	jmp	short doNegate
done:
	popf
	jge	exit

doNegate:
	call	FloatNegate

exit:
	.leave
	ret
FloatComputeTan	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCos (originally COS)

DESCRIPTION:	Performs the cosine operation.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		cos(X) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatCos	proc	near
EC<	call	FloatCheck1Arg >

	call	FloatPiDiv2
	call	FloatAdd
	call	FloatSin
	ret
FloatCos	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSin

DESCRIPTION:	Performs the sine operation.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		sin(X) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatSin	proc	near
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatPi
	call	FloatMultiply2
	call	FloatDivide
	call	FloatIntFrac
	call	FloatSwap
	FloatDrop trashFlags
	call	FloatComputeSin
done:
	ret
FloatSin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoTan (originally "|(TAN)")

DESCRIPTION:	Evaluates the tangent of X1 to 19+ significant digits for
		|X1| <= PI/4
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack

RETURN:		X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Approximation 4285.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoTan	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	FloatDup
	call	FloatMultiply
	call	FloatDup

	mov	si, offset cs:tableDoTan
	call	FloatPushOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	call	FloatSwap
	call	FloatDup
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	call	FloatDivide
	call	FloatMultiply
	.leave
	ret
FloatDoTan	endp

tableDoTan	label	word
	word	35d9h, 0affah, 0c16ah, 8e0bh, 3ff0h
	word	64b6h, 0eac2h, 1579h, 8c30h, 3ffah
	word	3d5fh, 0dech, 1599h, 0f81ch, 0c002h
	word	5644h, 792bh, 11a0h, 83ffh, 4009h
	word	8215h, 0d6c1h, 0cf82h, 0cc30h, 0c00ch
	word	0e770h, 0328h, 0d958h, 9b80h, 0c006h
	word	0cc1dh, 8f8dh, 02cah, 94eeh, 400bh
	word	0a1b9h, 97bfh, 0e79fh, 81fdh, 0c00dh


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatTan (originally TAN)

DESCRIPTION:	Performs the tangent operation.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		tan(X) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatTan	proc	near
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatPi
	call	FloatDivide
	call	FloatIntFrac
	call	FloatSwap
	FloatDrop trashFlags
	call	FloatComputeTan

done:
	ret
FloatTan	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoArcSin (originally "|(ASIN)")

DESCRIPTION:	Evaluates the arcsine of X1 to 17+ significant digits for
		|X1| <= .5
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
  Approximation 4698.
  FDUP FDUP **
  FDUP
  [ -.36148 .64568 .03475 .23002   2 FP#] FOVER **
  [  .49908 .74735 .18143 .34756   3 FP#] ++ FOVER **
  [ -.19037 .55915 .75077 .92670   4 FP#] ++ FOVER **
  [  .27058 .67326 .43406 .43538   4 FP#] ++ **
  [ -.12828 .25499 .97869 .27732   4 FP#] ++
  FSWAP FDUP
  [ -.75411 .43644 .19617 .07887   2 FP#] ++ FOVER **
  [  .71974 .04229 .53630 .34267   3 FP#] ++ FOVER **
  [ -.22941 .55932 .65797 .84211   4 FP#] ++ FOVER **
  [  .29196 .71576 .43051 .75556   4 FP#] ++ **
  [ -.12828 .25499 .97869 .27795   4 FP#] ++
  // ** ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoArcSin	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	FloatDup
	call	FloatMultiply
	call	FloatDup

	mov	si, offset cs:tableDoArcSin
	call	FloatPushOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	call	FloatSwap
	call	FloatDup
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	call	FloatDivide
	call	FloatMultiply
	.leave
	ret
FloatDoArcSin	endp

tableDoArcSin	label	word
	word	1a9dh, 0bf23h, 3692h, 9098h, 0c004h
	word	8af2h, 0dd8h, 3255h, 0f98bh, 4007h
	word	1a87h, 3a84h, 3076h, 0edf8h, 0c009h
	word	3404h, 0aed4h, 0e091h, 0a91dh, 400ah
	word	0b16ch, 0ee6ah, 6a7eh, 0a05ah, 0c009h
	word	5dcbh, 1d37h, 0a7cch, 96d2h, 0c005h
	word	33f5h, 0f4c3h, 6316h, 0b3efh, 4008h
	word	54ach, 3e26h, 7eb3h, 8f62h, 0c00ah
	word	65a7h, 0ed5dh, 0bec6h, 0b67ah, 400ah
	word	0b1a5h, 0ee6ah, 6a7eh, 0a05ah, 0c009h


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatArcSin (originally ASIN)

DESCRIPTION:	Performs the arc sine operation.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		arcsin(X) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: ASIN   ( FP: X1 --- X2 ) ( KMB 85 08 19 )
  ?NONAN1
  IF FSIGN 0< FABS FDUP 1. >>
    IF FDROP DROP FERR
    ELSE FDUP .5 >>
      IF FNEGATE 1. ++ 2./ SQRT (ASIN) 2.* FNEGATE PI/2 ++
      ELSE (ASIN)
      THEN   IF FNEGATE   THEN
    THEN
  THEN ;

: ASIN   ( FP: X1 --- X2 ) ( KMB 85 08 19 )
  ?NONAN1
  IF FSIGN 0<                   ( F<0 )
    FABS FDUP                   ( fp: X X)
    1.                          ( fp: X X 1 )
    >>                          ( fp: X )
    IF
      FDROP DROP FERR           () ( fp: ERR )
    ELSE
      FDUP                      ( fp: X X )
      .5                        ( fp: X X .5 )
      >>                        ( fp: X )
      IF
        FNEGATE 1.              ( fp: X 1 )
        ++                      ( fp: X )
        2./                     ( fp: X )
        SQRT                    ( fp: X )
        (ASIN)                  ( fp: X )
        2.*                     ( fp: X )
        FNEGATE                 ( fp: X )
        PI/2                    ( fp: X P )
        ++                      ( fp: X )
      ELSE
        (ASIN)
      THEN
      IF FNEGATE   THEN
    THEN
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatArcSin	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatSign		; bx <- sign
	pushf

	call	FloatAbs
	call	FloatDup
	call	Float1
	call	FloatCompAndDrop
	jg	error

	call	FloatDup
	call	FloatPoint5
	call	FloatCompAndDrop
	jle	doArcSin

	call	FloatNegate
	call	Float1
	call	FloatAdd
	call	FloatDivide2
	call	FloatSqrt
	call	FloatDoArcSin
	call	FloatMultiply2
	call	FloatNegate
	call	FloatPiDiv2
	call	FloatAdd
	jmp	short over

doArcSin:
	call	FloatDoArcSin

over:
	popf
	jge	done
	call	FloatNegate
	jmp	short done

error:
	FloatDrop trashFlags
	popf
	call	FloatErr
done:
	.leave
	ret
FloatArcSin	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatArcCos (originally ACOS)

DESCRIPTION:	Performs the arc cosine operation.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		arccos(X) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatArcCos	proc	near
EC<	call	FloatCheck1Arg >

	call	FloatArcSin
	call	FloatNegate
	call	FloatPiDiv2
	call	FloatAdd
	ret
FloatArcCos	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatDoArcTan (originally "|(ATAN)")

DESCRIPTION:	Evaluates the arctangent of X1 to 17+ significant digits for
		|X1| <= 1.
		( FP: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		X on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
  Approximation 5100.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatDoArcTan	proc	near	uses	si
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatDup
	call	FloatDup
	call	FloatMultiply
	call	FloatDup

	mov	si, offset cs:tableDoArcTan
	call	FloatPushOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	call	FloatSwap
	call	FloatDup
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddOverMult
	call	FloatPushAddMult
	call	FloatPushAdd
	call	FloatDivide
	call	FloatMultiply
	.leave
	ret
FloatDoArcTan	endp

tableDoArcTan	label	word
	word	2380h, 82abh, 0c71ch, 0c7f0h, 3ffbh
	word	0fc5bh, 93fbh, 90a0h, 0b527h, 4002h
	word	2d73h, 0cda0h, 468bh, 0c094h, 4006h
	word	0b21fh, 6049h, 215dh, 8b44h, 4009h
	word	0c460h, 0d077h, 8466h, 0ac9bh, 400ah
	word	0a713h, 2afdh, 318bh, 0bd71h, 400ah
	word	0bb9fh, 3b21h, 0e770h, 9737h, 4009h
	word	2742h, 35edh, 0e9d9h, 9fabh, 4004h
	word	04c4h, 3e2eh, 2bb6h, 0d389h, 4007h
	word	80f5h, 0bf1fh, 35fah, 0e3b3h, 4009h
	word	0e6abh, 2081h, 0b824h, 0e508h, 400ah
	word	6055h, 34d8h, 2d73h, 0d6a5h, 400ah
	word	0bbdfh, 3b21h, 0e770h, 9737h, 4009h


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatArcTan (originally ATAN)

DESCRIPTION:	Performs the arc tangent operation.
		( fp: X1 --- X2 )

CALLED BY:	INTERNAL ()

PASS:		X on fp stack
		ds - fp stack seg

RETURN:		arctan(X) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: ATAN   ( FP: X1 --- X2 ) ( KMB 85 06 11 )
  ?NONAN1
  IF FSIGN 0< FABS FDUP 1. >>
    IF 1/X (ATAN) FNEGATE PI/2 ++
    ELSE (ATAN)
    THEN   IF FNEGATE   THEN
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatArcTan	proc	near	uses	bx
	.enter
EC<	call	FloatCheck1Arg >

	call	FloatIsNoNAN1
	jnc	done

	call	FloatSign	; bx <- sign
	pushf

	call	FloatAbs
	call	FloatDup
	call	Float1
	call	FloatCompAndDrop
	jle	over

	call	FloatInverse
	call	FloatDoArcTan
	call	FloatNegate
	call	FloatPiDiv2
	call	FloatAdd
	jmp	short over2

over:
	call	FloatDoArcTan

over2:
	popf
	jge	done

	call	FloatNegate

done:
	.leave
	ret
FloatArcTan	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatArcTan2 (originally ATAN2)

DESCRIPTION:	( fp: X Y --- ANGLE )

CALLED BY:	INTERNAL ()

PASS:		ds - fp stack seg

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
: ATAN2   ( FP: X Y --- ANGLE ) ( KMB 861113 )
  ?NONAN2
  IF FSIGN ?DUP   ( NSY NSY  or  0 | X Y )
    IF ( Y<>0 ) FSWAP FSIGN ?DUP   ( NSY NSX NSX  or  NSY 0 | Y X )
      IF ( X<>0 ) // ATAN 0<   ( NSY F | ANGLE' )
        IF ( X<0 ) PI 0<   IF ( Y<0 ) --   ELSE ( Y>0 ) ++   THEN ( | ANGLE )
        ELSE DROP   ( | ANGLE )
        THEN
      ELSE ( X=0 ) FDROP FDROP PI/2 0<   IF FNEGATE   THEN   ( | ANGLE )
      THEN
    ELSE ( Y=0 ) FDROP FSIGN FDROP ?DUP   ( NSX NSX  or  0 )
      IF ( X<>0 ) 0<   IF PI   ELSE 0.   THEN ( | ANGLE )
      ELSE ( X=0 ) FERR   ( | ERR )
      THEN
    THEN
  THEN ;

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatArcTan2	proc	near	uses	bx
	.enter
EC<	call	FloatCheck2Args >

	call	FloatIsNoNAN2
	jnc	done

	call	FloatSign		; bx <- sign, flags set
	je	y0

	pushf				; 1st ?DUP, sign(Y)

	;-----------------------------------------------------------------------
	; Y != 0

	call	FloatSwap
	call	FloatSign		; bx <- sign(X), flags set
	je	yNE0x0

	pushf				; 2nd ?DUP, sign(X)

	;
	; X != 0
	;
	call	FloatDivide
	call	FloatArcTan
	popf				; get flags from 2nd FloatSign, sign(X)
	jge	yNE0xPOS

	;
	; X < 0
	;
	call	FloatPi
	popf				; get flags from 1st FloatSign, sign(Y)
	jge	yNE0xNEG

	call	FloatSub
	jmp	short done

yNE0xNEG:
	call	FloatAdd
	jmp	short done

yNE0xPOS:
	popf				; clear stack of 1st FloatSign
	jmp	short done

yNE0x0:
	FloatDrop trashFlags		; lose X
	FloatDrop trashFlags		; lose Y
	call	FloatPiDiv2
	popf				; get flags from 1st FloatSign, sign(Y)
	jge	done

	call	FloatNegate
	jmp	short done

y0:
	;-----------------------------------------------------------------------
	; Y = 0

	FloatDrop trashFlags		; lose Y
	call	FloatSign		; bx <- sign(X), flags set
	FloatDrop			; lose X
	je	err			; error if X = 0
	jg	zero

	call	FloatPi
	jmp	short done

zero:
	call	Float0
	jmp	short done

err:
	;-----------------------------------------------------------------------
	; (Y != 0) & (X == 0)

	call	FloatErr

done:
	.leave
	ret
FloatArcTan2	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	Is8087

DESCRIPTION:	for future coprocessor support

CALLED BY:	INTERNAL ()

PASS:		

RETURN:		0  no NPX
		0 -1  NPX and CPU is 8086/8088 implying 8087
		1 -1  NPX is 80287
		2 -1  NPX is 80387

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

if 0
Is8087	proc	near
	push	bx			; Make room for flag
	clr	bx			; Set flag to false.
	fninit
	mov	ax, bx			; Set ax to zero
	mov	cx, bx			; Set cx to zero
	mov	{word} ss:[bp-2], ax	; Clear CTL-WRD
	fnstcw	ss:[bp-2]		; Pop control word.
	mov	{word} ax, ss:[bp-2] 
	cmp	ah, 03    		; Will be 03 if 80x87 is present.
	jne	3$			; Jump if no 80x87 present.

	dec	bx			; Set flag true, 8087 found.
	push	sp			; get sp in ax using push/pop
	pop	ax			; ax <> sp in 8086/8088
	cmp	ax, sp 
	jnz	2$			; jump if is 8087

	inc	cx 

	;
	; I80287/387 or if no coprocessor specified at compile: no FWAIT's
	; generated
	;

1$:
	fld1				; form infinity
	fldz	
	fdiv				; 8087/80287 says +inf = -inf
	fld	0 ST         
	fchs				; form negative infinity
	fcompp				; 80387 says +inf <> -inf

FORTH    0DF C, 0E0 C, ASSEMBLER	; ???

	fninit
	sahf				; did infinities match
	je	2$			; jump if is 80287

	inc	cx			; is 80387
2$:
	push	cx 
3$:
	ret
Is8087	endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatPushAddOverMult,
		FloatPushOverMult,
		FloatPushAddMult,
		FloatPushAdd

DESCRIPTION:	Routines containing common code sequences.

CALLED BY:	INTERNAL (floatTrans routines)

PASS:		si - offset into cs to 5 word lookup table entry

RETURN:		si - updated to point past the 5 words

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

FloatPushAddOverMult	proc	near
	call	PushFPNum		; destroys nothing
	call	FloatAdd		; destroys ax,dx
	call	FloatOver		; destroys ax
	GOTO	FloatMultiply		; destroys ax,dx
FloatPushAddOverMult	endp

FloatPushOverMult	proc	near
	call	PushFPNum
	call	FloatOver		; destroys ax
	GOTO	FloatMultiply		; destroys ax,dx
FloatPushOverMult	endp

FloatPushAddMult	proc	near
	call	PushFPNum		; destroys nothing
	call	FloatAdd		; destroys ax,dx
	GOTO	FloatMultiply		; destroys ax,dx
FloatPushAddMult	endp

FloatPushAdd	proc	near
	call	PushFPNum		; destroys nothing
	GOTO	FloatAdd		; destroys ax,dx
FloatPushAdd	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatArcCosh

DESCRIPTION:	Returns the inverse hyperbolic cosine of the number.
		The number must should be >= 1.

		ACOSH(z) = ln( z +/- sqrt(z^2 - 1)), z >= 1
		The plus sign is used.

		Domain [1, +inf)
		Range  (-inf, +inf)

CALLED BY:	INTERNAL ()

PASS:		z on fp stack
		ds - fp stack seg

RETURN:		ACOSH(z) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatArcCosh	proc	near
	call	FloatDup		; ( fp: z z )
	call	Float1			; ( fp: z z 1 )
	call	FloatCompAndDrop	; ( fp: z )
	jl	err

	call	FloatDup		; ( fp: z z )
	call	FloatSqr		; ( fp: z z^2 )
	call	Float1			; ( fp: z z^2 1 )
	call	FloatSub		; ( fp: z z^2-1 )
	call	FloatSqrt
	call	FloatAdd
	call	FloatLn			; ACOSH
done:
	ret

err:
	FloatDrop trashFlags
	call	FloatErr
	jmp	short done
FloatArcCosh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatArcSinh

DESCRIPTION:	Returns the inverse hyperbolic sine of the number.

		ASINH(z) = ln( z +/- sqrt(z^2 + 1))

		Domain (-inf, +inf)
		Range  (-inf, +inf)

CALLED BY:	INTERNAL ()

PASS:		z on fp stack
		ds - fp stack seg

RETURN:		ASINH(z) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatArcSinh	proc	near
	call	FloatDup		; ( fp: z z )
	call	FloatSqr		; ( fp: z z^2 )
	call	Float1			; ( fp: z z^2 1 )
	call	FloatAdd		; ( fp: z z^2-1 )
	call	FloatSqrt
	call	FloatAdd
	GOTO	FloatLn			; ASINH
FloatArcSinh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatArcTanh

DESCRIPTION:	Returns the inverse hyperbolic sine of the number.

				   1+z
		ATANH(z) = .5 * ln ---, z^2 < 1
				   1-z

		Domain (-1, 1)
		Range  (-inf, +inf)

CALLED BY:	INTERNAL ()

PASS:		z on fp stack
		ds - fp stack seg

RETURN:		ATANH(z) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatArcTanh	proc	near
	call	FloatDup		; ( fp: z z )
	call	FloatSqr		; ( fp: z z^2 )
	call	Float1
	call	FloatCompAndDrop	; ( fp: z )
	jge	err

	call	FloatDup		; ( fp: z z )
	call	Float1			; ( fp: z z 1 )
	call	FloatAdd		; ( fp: z 1+z )
	call	FloatSwap		; ( fp: 1+z z )
	call	FloatNegate
	call	Float1			; ( fp: 1+z -z 1 )
	call	FloatAdd		; ( fp: 1+z 1-z )
	call	FloatDivide
	call	FloatLn
	call	FloatDivide2		; ATANH
done:
	ret

err:
	FloatDrop trashFlags
	call	FloatErr
	jmp	short done
FloatArcTanh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatCosh

DESCRIPTION:	Returns the hyperbolic cosine of the number.

			  e^z + e^-z
		COSH(z) = ----------
			      2

CALLED BY:	INTERNAL ()

PASS:		z on fp stack
		ds - fp stack seg

RETURN:		COSH(z) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatCosh	proc	near
	call	FloatDup		; ( fp: z z )
	call	FloatExp		; ( fp: z e^z )
	call	FloatSwap		; ( fp: e^z z)
	call	FloatNegate		; ( fp: e^z -z )
	call	FloatExp		; ( fp: e^z e^-z )
	call	FloatAdd
	GOTO	FloatDivide2
FloatCosh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatSinh

DESCRIPTION:	Returns the hyperbolic sine of the number.

			  e^z - e^-z
		SINH(z) = ----------
			      2

CALLED BY:	INTERNAL ()

PASS:		z on fp stack
		ds - fp stack seg

RETURN:		SINH(z) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

FloatSinh	proc	near
	call	FloatDup		; ( fp: z z )
	call	FloatExp		; ( fp: z e^z )
	call	FloatSwap		; ( fp: e^z z)
	call	FloatNegate		; ( fp: e^z -z )
	call	FloatExp		; ( fp: e^z e^-z )
	call	FloatSub
	GOTO	FloatDivide2
FloatSinh	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	FloatTanh

DESCRIPTION:	Returns the hyperbolic tangent of the number.

			SINH(z)
		TANH =	-------
			COSH(z)
		
			e^z - e^-z
		     =	----------
			e^z + e^-z

CALLED BY:	INTERNAL ()

PASS:		z on fp stack
		ds - fp stack seg

RETURN:		TANH(z) on fp stack

DESTROYED:	ax,dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

;
; let a = e^z
;     b = e^-z
;

FloatTanh	proc	near
	call	FloatDup		; ( fp: z z )
	call	FloatExp		; ( fp: z a )
	call	FloatSwap		; ( fp: a z )
	call	FloatNegate		; ( fp: a -z )
	call	FloatExp		; ( fp: a b )
	call	FloatOver
	call	FloatOver		; ( fp: a b a b )
	call	FloatSub		; ( fp: a b a-b )
	call	FloatRot
	call	FloatRot		; ( fp: a-b a b )
	call	FloatAdd
	GOTO	FloatDivide		; TANH
FloatTanh	endp
