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

include ansicGeode.def


WCC_TEXT        SEGMENT BYTE PUBLIC 'CODE'
                ASSUME  CS:WCC_TEXT

	public __U4M
	public __U4D
	public __I4M
	public __I4D
	public __CHP

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
if 0
	.386
	__U4D proc far

	push dx							;push dividend in dx:ax to stack
	push ax
	push cx							;push divisor in cx:bx to stack
	push bx
	
	pop ecx							;pop divisor from stack to ecx
	pop eax							;pop low qword from stack to eax
	mov edx, 0h						;set high qword of dividend to 0h

	div ecx							;unsigned divide	

	push eax						;push quotient to stack
	push edx						;push remainder to stack

	pop bx							;pop low word of remainder from stack to bx
	pop cx							;pop high word of remainder from stack to cx
	pop ax							;pop low word of qoutient from stack to ax
	pop dx							;pop high word of qoutient from stack to dx
	
	ret
	__U4D endp
endif

__U4D proc far
    ; Input:
    ; dx:ax = 32-bit dividend (high:low)
    ; cx:bx = 32-bit divisor (high:low)
    ; Output:
    ; dx:ax = quotient (high:low)
    ; cx:bx = remainder (high:low)
if 0
    ; Save the dividend (dx:ax) and divisor (cx:bx) on the stack
    push dx            ; Save high part of dividend
    push ax            ; Save low part of dividend
    push cx            ; Save high part of divisor
    push bx            ; Save low part of divisor

    ; Check if we can perform a simple 16-bit division (divisor high part = 0)
    mov ax, cx         ; Copy high word of divisor to ax
    or  ax, ax         ; Is the high part of the divisor (cx) zero?
    jnz full_division  ; If not zero, perform full 32-bit division

    ; Simple 16-bit division: divide dx:ax by bx (low part of divisor)
    pop bx             ; Load low word of divisor (bx) from stack
    xor dx, dx         ; Clear high part of dividend for 16-bit division
    div bx             ; Divide dx:ax by bx -> ax = quotient, dx = remainder

    mov cx, dx         ; Store remainder in cx
    xor dx, dx         ; Clear high part of quotient
    jmp end_division   ; Jump to end

full_division:
    ; Full 32-bit division
    ; dx:ax = dividend, cx:bx = divisor

    pop bx             ; Load low word of divisor (bx)
    pop cx             ; Load high word of divisor (cx)

    ; Step-by-step division using 16-bit operations

    ; 1. Prepare dividend and divisor
    push dx            ; Save high part of dividend on the stack
    push ax            ; Save low part of dividend on the stack

    ; 2. Set up for division
    xor dx, dx         ; Clear high part of dividend for division
    div bx             ; Divide dx:ax by bx (low word of divisor)

    ; 3. Get quotient and remainder (low)
    mov bx, ax         ; Store quotient in bx
    mov ax, dx         ; Store remainder in ax
    div cx             ; Divide ax (remainder) by cx (high word of divisor)

    ; 4. Prepare for return
    mov cx, ax         ; Store remainder in cx
    mov dx, bx         ; Store quotient in dx

end_division:
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
; Note: This is a temporary implementation. This function must be reimplemented in 8086 assembler instructions.
if 0
	.386
	__I4D proc far

	push dx							;push dividend in dx:ax to stack
	push ax
	push cx							;push divisor in cx:bx to stack
	push bx
	
	pop ecx							;pop divisor from stack to ecx
	pop eax							;pop low qword from stack to eax
	
	cdq								;extend dividend in eax to edx:eax
	idiv ecx						;signed divide	

	push eax						;push quotient to stack
	push edx						;push remainder to stack

	pop bx							;pop low word of remainder from stack to bx
	pop cx							;pop high word of remainder from stack to cx
	pop ax							;pop low word of quotient from stack to ax
	pop dx							;pop high word of quotient from stack to dx
	
	ret
	__I4D endp
endif

__I4D proc far
    ; Input:
    ; dx:ax = 32-bit dividend (high:low)
    ; cx:bx = 32-bit divisor (high:low)
    ; Output:
    ; dx:ax = quotient (high:low)
    ; cx:bx = remainder (high:low)
if 0
    ; Save the dividend (dx:ax) and divisor (cx:bx) on the stack
    push dx            ; Save high part of dividend
    push ax            ; Save low part of dividend
    push cx            ; Save high part of divisor
    push bx            ; Save low part of divisor

    ; Check if we can do a simple 16-bit signed division (if cx == 0)
    or  cx, cx	       ; Check if high part of divisor is 0
    jnz full_signed_division  ; If high part of divisor is not 0, go to full division

    ; Simple 16-bit signed division: (dx:ax) / bx
    idiv bx            ; Signed divide dx:ax by bx -> quotient in ax, remainder in dx

    mov bx, dx         ; Store remainder in cx
    xor dx, dx         ; Clear high part of quotient
    xor cx, cx         ; Clear high part of quotient
    jmp end_signed_division ; Jump to end

full_signed_division:
    ; Full 32-bit signed division
    ; dx:ax = dividend, cx:bx = divisor

    ; Step-by-step signed division using 16-bit operations

    ; 1. Save the dividend
    push dx            ; Save high word of dividend on the stack
    push ax            ; Save low word of dividend on the stack

    ; 2. Prepare for division
    cwd                ; Sign-extend ax into dx:ax (needed for signed division)
    idiv bx            ; Divide dx:ax by bx (low word of divisor)

    ; 3. Get quotient and remainder (low part)
    mov bx, ax         ; Save quotient in bx
    mov ax, dx         ; Save remainder in ax
    cwd                ; Sign-extend ax (remainder) into dx:ax
    idiv cx            ; Divide remainder (ax) by cx (high word of divisor)

    ; 4. Prepare results for return
    mov cx, ax         ; Store remainder in cx
    mov dx, bx         ; Store quotient in dx

end_signed_division:
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
__I4D endp


; __CHP
;
; Sets fpu rouding toward zero (truncate) and rounds the top element of fpu stack.

	__CHP proc far
	uses ax, bp
	.enter

	mov bp, sp
	;push 0000h					;allocate 2byte on stack
	sub sp, 2
	fstcw -2[bp]				;store fpu control word
	fwait
	mov ax, -2[bp]				;store old fpu control word in ax
	mov byte ptr -1[bp], 1fh	;set fpu control word with rounding toward zero
	fldcw -2[bp]				;load new fpu control word
	frndint						;round top element from fpu stack
	mov -2[bp], ax				;restore old fpu control word
	fstcw -2[bp]				;set old fpu control word
	fwait
	mov sp, bp					;restore stackpointer

	.leave
	ret
	__CHP endp
	
WCC_TEXT        ENDS
