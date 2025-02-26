; Copyright 2020	Falk Rehwagen, Jirka Kunze
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
;
;    http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.


Resident	segment	public	'CODE'
                ASSUME  CS:Resident

	public __U4M
	public __U4D
	public __I4M
	public __I4D

	public TRUETYPE_GRMULWWFIXED

; __U4M
; __I4M
;
; Multiplies two 32bit integers (signed and unsigned).
;
; In:
;	dx:ax	int1 ( dx: high( int1 ); ax low( int1 ) )
;	cx:bx	int2 ( cx: high( int2 ); bx low( int2 ) )
;
; Out:
;	dx:ax	product of int1 and int2
;
; Description:
;	dx := low( high( int1 ) * low( int2 ) ) + --> part1
;	      low( high( int2 ) * low( int1 ) ) + --> part2
;	      high( low( int1 ) * low( int2 ) )   --> part3
;	ax := low( low( int1 ) * low( int2 ) )    --> part4

	__U4M proc far
	.fall_thru
	__U4M endp

	__I4M proc far

	push bx				; save low( int2 )
	push ax				; save low( int1 )

	xchg ax, dx			; ax := high( int1 ), dx := low( int1 )
	mul bx				; ax := low( high( int1 ) * low( int2 ) ) --> part1
	xchg ax, bx			; bx := part1, ax := low( int2 )

	pop ax				; restore low( int1 )
	xchg ax, cx			; ax := high( int2 ), cx := low( int1 )
	mul cx				; ax := low( low( int1 ) * high( int2 ) ) --> part2
	add ax, bx			; ax := part1 + part2

	xchg ax, cx			; cx := part1 + part2, ax := high( int2 )
	pop bx				; restore low( int2 )
	mul bx				; ax := low( high( int2 ) * low( int2 ) ) --> part4
						; dx := high( high( int2 ) * low( int2 ) ) --> part3

	add dx, cx			; dx := part 3 + part 1 + part 2

	ret

	__I4M endp

; __U4D
;
; Divide two 32 bit unsigned integers.
;
; In:
;	dx:ax	dividend
;	cx:bx	divisor
;
; Out:
;	dx:ax	qoutient
;	cx:bx	remainder
;
; Note: This is a temporary implementation. This function must be reimplemented in 8086 assembler instructions.

	;.386
	__U4D proc far
if 0
	shl edx, 16		;edx <- high dividend
	mov dx, ax		;dx <- low dividend

	shl ecx, 16		;ecx <- high divisor
	mov cx, bx		;cx <- low divisor

	mov eax, edx		;eax <- dividend

	mov edx, 0h		;set high qword of dividend to 0h
	div ecx			;unsigned divide

	mov ecx, edx		
	mov bx, cx		;bx <- low remainder
	shr ecx, 16		;cx <- high remainder

	mov edx, eax		;ax <- low qoutient
	shr edx, 16 		;dx <- high qoutient	
endif	
	or      cx,cx		; check for easy case
	jne     noteasy		; easy if divisor is 16 bit
        dec     bx              ; decrement divisor
        jz	done        	; if not dividing by 1
	inc	bx              ; - put divisor back
        cmp   	bx, dx          ; - if quotient will be >= 64K
        jg	lowpart
;
;       12-aug-88, added thanks to Eric Christensen from Fox Software
;       divisor < 64K, dividend >= 64K, quotient will be >= 64K
;
;       *note* this sequence is used in ltoa's #pragmas; any bug fixes
;              should be reflected in ltoa's code bursts
;
	mov	cx, ax		; - - save low word of dividend
	mov	ax, dx		; - - get high word of dividend
	sub	dx, dx		; - - zero high part
        div	bx		; - - divide bx into high part of dividend
        xchg	ax, cx		; - - swap high part of quot,low word of dvdnd

lowpart:
	div	bx		; - calculate low part
	mov	bx, dx		; - get remainder
	mov	dx, cx		; - get high part of quotient
	sub	cx, cx          ; - zero high part of remainder

        ret                     ; return


noteasy:                        ; have to work to do division
;
;       check for divisor > dividend
;
	cmp	cx, dx		; - quit if divisor <= dividend
        jb	smaller
        jne	notequal
        cmp	bx, ax		; - - compare the lower order words
        ja	notequal	; - - if divisor <= dividend
        sub	ax, bx		; - - - calulate remainder
        mov	bx, ax		; - - - ...
        sub	cx, cx		; - - - ...
        sub	dx, dx		; - - - quotient = 1
        mov	ax, 1		; - - - ...
        ret			; - - - return

notequal:
        sub   cx,cx           ; - set divisor = 0 (this will be quotient)
        sub   bx,bx           ; - ...
        xchg  ax,bx           ; - return remainder = dividend
        xchg  dx,cx           ; - and quotient = 0
        ret                   ; - return

smaller:
; SJHowe 24-01-2000
;
; At this point here what is known is that cx > 0 and dx > cx. At the very
; least cx is 1 and dx 2.
;
; Consider the quotient
;
; The maximum it can be is when division is
;
; FFFF:FFFF / 0001:0000
;
; The minimum it can be is when division is
;
; 0002:0000 / 0001:FFFF
;
; Doing the division reveals the quotient lies 1 between FFFF. It cannot
; exceed FFFF. Therefore there is no need to keep track of the quotient's
; high word, it is always 0.
;
; Accordingly register DI has been eliminated below
;
; Should make algoritm a little faster.
;
; SJHowe 24-01-2000

	push	bp		; save work registers
	push	si		; ...
	sub	si, si		; zero quotient
	mov	bp, si		; and shift count
moveup:				; loop until divisor > dividend
	shl	bx, 1		; - divisor *= 2
	rcl	cx, 1		; - ...

	jc	backup		; - know its bigger if carry out
        inc	bp		; - increment shift count
        cmp	cx, dx		; - check if its bigger yet
        jb	moveup		; - no, keep going
        ja	divlup		; - if below, know we're done
        cmp	bx, ax		; - check low parts (high parts equal)
        jbe 	moveup		; until divisor > dividend
divlup:                         ; division loop
        clc                     ; clear carry for rotate below
loop1:				; loop
	rcl	si, 1		; - - shift bit into quotient
        dec	bp		; - - quif( -- shift < 0 ) NB carry not changed
        js	donediv		; - - ...
backup:				; - - entry to remove last shift
	rcr	cx, 1		; - - divisor /= 2 (NB also used by 'backup')
        rcr	bx, 1		; - - ...
        sub	ax, bx		; - - dividend -= divisor
        sbb	dx, cx		; - - c=1 iff it won't go
        cmc                 	; - - c=1 iff it will go
        jc	loop1		; - until it won't go
          
loop2:
        shl	si, 1		; - - shift 0 into quotient
        dec	bp		; - - going to add, check if done
        js	toomuch		; - - if done, we subtracted to much
        shr	cx, 1		; - - divisor /= 2
	rcr	bx, 1		; - - ...
        add	ax, bx		; - - dividend += divisor
        adc	dx, cx		; - - c = 1 iff bit of quotient should be 1
	jnc	loop2		; - until divisor will go into dividend
	jmp	loop1
toomuch:			; we subtracted too much
	add	ax, bx		; dividend += divison
	adc	dx, cx		; ...
donediv:			; now quotient in si, remainder in dx;ax
        mov	bx, ax		; move remainder to cx;bx
        mov	cx, dx	; ...
        mov	ax, si		; move quotient to dx;ax
        xor	dx, dx		; ...
        pop	si		; restore registers
        pop	bp		; ...
done:
    	ret			; Return
	__U4D endp

; __I4D
;
; Divide two 32 bit signed integers.
;
; In:
;	dx:ax	dividend
;	cx:bx	divisor
;
; Out:
;	dx:ax	qoutient
;	cx:bx	remainder
;
; Note: This is an implementation with 80386.
;	.386
	__I4D proc far
if 0
	shl edx, 16		;edx <- high dividend
	mov dx, ax		;dx <- low dividend

	shl ecx, 16		;ecx <- high divisor
	mov cx, bx		;cx <- low divisor

	mov eax, edx		;eax <- dividend
	
	cdq			;extend dividend in eax to edx:eax
	idiv ecx		;signed divide

	mov ecx, edx		
	mov bx, cx		;bx <- low remainder
	shr ecx, 16		;cx <- high remainder

	mov edx, eax		;ax <- low qoutient
	shr edx, 16 		;dx <- high qoutient
endif	
	or	dx, dx		; check sign of dividend
	js	divneg		; handle case where dividend < 0
	or	cx, cx		; check sign of divisor
	jns	__U4D		; jump if positive  24-jan-00

	; dividend >= 0, divisor < 0
notU4D:	neg	cx		; take positive value of divisor
	neg	bx		; ...
	sbb	cx, 0		; ...
	call	__U4D		; do unsigned division
	neg	dx		; negate quotient
	neg	ax		; ...
	sbb	dx, 0		; ...
	ret			; and return

divneg:				; dividend is negative
	neg	dx		; take absolute value of dividend
	neg	ax		; ...
	sbb	dx, 0		; ...
	or	cx, cx		; check sign of divisor
	jns	negres		; negative result if divisor > 0

	; dividend < 0, divisor < 0
	neg	cx		; negate divisor too
	neg	bx		; ...
	sbb	cx, 0		; ...
	call	__U4D		; and do unsigned division
	neg	cx		; negate remainder
	neg	bx		; ...
	sbb	cx, 0		; ...
	ret			; and return

	; dividend < 0, divisor >= 0
negres:	call	__U4D		; do unsigned division
	neg	cx		; negate remainder
	neg	bx		; ...
	sbb	cx, 0		; ...
	neg	dx		; negate quotient
	neg	ax		; ...
	sbb	dx, 0		; ...
    	ret			; Return

	ret
	__I4D endp


	SetGeosConvention               ; set calling convention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueType_GrRegMul32ToDDF
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply 2 WWFixed numbers and return a DDFixed number

CALLED BY:	GLOBAL
PASS:		dx.cx		= multiplicand
		bx.ax		= multiplier
RETURN:		bxdx.cxax	= result
		dx.cx		= same as result from old GrMul32
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:			D.C		dx.cx
					B.A		bx.ax
				-----------		-----
			  A*D + (A*C >> 16)	      bxdx.cxax
 	    (B*D << 16) + B*C
      -------------------------------------
      (B*D << 16) + A*D + B*C + (A*C >> 16)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/12/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TrueType_GrRegMul32ToDDF	proc	near
	uses	bp, si, di
	.enter

        mov	si, dx		;si.cx = multiplicand
	mov	di, ax		;bx.di = multiplier

	mov	ax, si
	xor	ax, bx		;if signs are different then SFlag will be set
	pushf			;save flags

	tst	si
	js	neg_sicx	;if signed, negate operand
after_sicx:

	tst	bx
	js	neg_bxdi	;if signed, negate operand
after_bxdi:

	mov	ax, cx
	mul	di		;0.dxax = C*A
	mov	bp, dx		;0.bp = C*A
	push	ax		;save lowest word

	mov	ax, si
	mul	bx		;dxax.0 = D*B
	push	dx		;save highest word

	xchg	ax, cx		;cx.0 = D*B, ax = C
	mul	bx		;dx.ax = C*B
	add	bp, ax
	adc	cx, dx		;cx.bp = D*B + C*B + C*A

	mov	ax, si
	mul	di		;dx.ax = D*A
	add	ax, bp
	adc	dx, cx		;dx.ax = middle two words of answer
	pop	bx		;bx <= highest word
	adc	bx, 0		;add carry to highest word
	pop	cx		;cx <= lowest word
	xchg	ax, cx		;answer = bxdx.cxax

	popf
	js	neg_bxdxcxax	;if signs of operands are different,
done:				; negate result
	.leave
	ret

neg_sicx:
	negdw	sicx		;make multiplicand
	jmp	short after_sicx

neg_bxdi:
	negdw	bxdi		;make multiplier positive
	jmp	short after_bxdi

neg_bxdxcxax:
	neg	ax
	cmc
	not	cx
	adc	cx, 0
	not	dx
	adc	dx, 0
	not	bx
	adc	bx, 0
	jmp	short done

TrueType_GrRegMul32ToDDF	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueType_GrMulWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiplies two fixed point numbers
		dx.cx = dx.cx * bx.ax

CALLED BY:	GLOBAL

PASS:		dx.cx	multiplicand
		bx.ax	multiplier

RETURN:		dx.cx	result

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/20/89		Initial version
	JS	6/9/92		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TrueType_GrMulWWFixed	proc	far
	uses	ax, bx
	.enter
	call	TrueType_GrRegMul32ToDDF
	.leave
	ret
TrueType_GrMulWWFixed	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TrueType_GrMulWWFixed

C DECLARATION:	extern WWFixedAsDWord
		    _far _pascal GrTTMulWWFixed(WWFixedAsDWord i,
							WWFixedAsDWord j);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
TRUETYPE_GRMULWWFIXED	proc	far	ni:dword, nj:dword
	.enter

	mov	dx, ni.high
	mov	cx, ni.low
	mov	bx, nj.high
	mov	ax, nj.low
	call	TrueType_GrMulWWFixed
	mov_trash	ax, cx

	.leave
	ret

TRUETYPE_GRMULWWFIXED	endp

Resident        ENDS
