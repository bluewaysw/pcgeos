;	$Id: h_ldiv.asm,v 1.1 97/04/07 12:04:19 newdeal Exp $
;[]-----------------------------------------------------------------[]
;|      H_LDIV.ASM -- long division routine                          |
;[]-----------------------------------------------------------------[]

;
;       C/C++ Run Time Library - Version 5.0
; 
;       Copyright (c) 1987, 1992 by Borland International
;       All Rights Reserved.
; 

        INCLUDE rules.asi

_TEXT   segment public byte 'CODE'
        assume  cs:_TEXT
        public  LDIV@
        public  F_LDIV@
        public  N_LDIV@
        public  LUDIV@
        public  F_LUDIV@
        public  N_LUDIV@
        public  LMOD@
        public  F_LMOD@
        public  N_LMOD@
        public  LUMOD@
        public  F_LUMOD@
        public  N_LUMOD@

N_LDIV@ proc near
        pop     cx                      ;fix up far return
        push    cs
        push    cx
	.fall_thru
N_LDIV@ endp
LDIV@ proc far
	.fall_thru
LDIV@ endp
F_LDIV@ proc far
        xor     cx,cx                   ; signed divide
        jmp     short common
F_LDIV@ endp

N_LUDIV@ proc near
        pop     cx                      ;fix up far return
        push    cs
        push    cx
	.fall_thru
N_LUDIV@ endp

LUDIV@ proc far
	.fall_thru
LUDIV@ endp

F_LUDIV@ proc far
        mov     cx,1                    ; unsigned divide
        jmp     short common
F_LUDIV@ endp

N_LMOD@ proc near
        pop     cx                      ;fix up far return
        push    cs
        push    cx
	.fall_thru
N_LMOD@ endp

LMOD@ proc far
	.fall_thru
LMOD@ endp

F_LMOD@ proc far
        mov     cx,2                    ; signed remainder
        jmp     short   common
F_LMOD@ endp

N_LUMOD@ proc near
        pop     cx                      ;fix up far return
        push    cs
        push    cx
	.fall_thru
N_LUMOD@ endp

LUMOD@ proc far
	.fall_thru
LUMOD@ endp

F_LUMOD@ proc far
        mov     cx,3                    ; unsigned remainder

;
;       di now contains a two bit control value.  The low order
;       bit (test mask of 1) is on if the operation is unsigned,
;       signed otherwise.  The next bit (test mask of 2) is on if
;       the operation returns the remainder, quotient otherwise.
;
common	label near
        push    bp
        push    si
        push    di
        mov     bp,sp                   ; set up frame
        mov     di,cx
;
;       dividend is pushed last, therefore the first in the args
;       divisor next.
;
        mov     ax,10[bp]               ; get the first low word
        mov     dx,12[bp]               ; get the first high word
        mov     bx,14[bp]               ; get the second low word
        mov     cx,16[bp]               ; get the second high word

        or      cx,cx
        jnz     slow@ldiv               ; both high words are zero

        or      dx,dx
        jz      quick@ldiv

        or      bx,bx
        jz      quick@ldiv              ; if cx:bx == 0 force a zero divide
                                        ; we don't expect this to actually
                                        ; work

slow@ldiv:

        test    di,1                    ; signed divide?
        jnz     positive                ; no: skip
;
;               Signed division should be done.  Convert negative
;               values to positive and do an unsigned division.
;               Store the sign value in the next higher bit of
;               di (test mask of 4).  Thus when we are done, testing
;               that bit will determine the sign of the result.
;
        or      dx,dx                   ; test sign of dividend
        jns     onepos
        neg     dx
        neg     ax
        sbb     dx,0                    ; negate dividend
        or      di,0Ch
onepos:
        or      cx,cx                   ; test sign of divisor
        jns     positive
        neg     cx
        neg     bx
        sbb     cx,0                    ; negate divisor
        xor     di,4
positive:
        mov     bp,cx
        mov     cx,32                   ; shift counter
        push    di                      ; save the flags
;
;       Now the stack looks something like this:
;
;               16[bp]: divisor (high word)
;               14[bp]: divisor (low word)
;               12[bp]: dividend (high word)
;               10[bp]: dividend (low word)
;                8[bp]: return CS
;                6[bp]: return IP
;                4[bp]: previous BP
;                2[bp]: previous SI
;                 [bp]: previous DI
;               -2[bp]: control bits
;                       01 - Unsigned divide
;                       02 - Remainder wanted
;                       04 - Negative quotient
;                       08 - Negative remainder
;
        xor     di,di                   ; fake a 64 bit dividend
        xor     si,si                   ;
xloop:
        shl     ax,1                    ; shift dividend left one bit
        rcl     dx,1
        rcl     si,1
        rcl     di,1
        cmp     di,bp                   ; dividend larger?
        jb      nosub
        ja      subtract
        cmp     si,bx                   ; maybe
        jb      nosub
subtract:
        sub     si,bx
        sbb     di,bp                   ; subtract the divisor
        inc     ax                      ; build quotient
nosub:
        loop    xloop
;
;       When done with the loop the four register value look like:
;
;       |     di     |     si     |     dx     |     ax     |
;       |        remainder        |         quotient        |
;
        pop     bx                      ; get control bits
        test    bx,2                    ; remainder?
        jz      usequo
        mov     ax,si
        mov     dx,di                   ; use remainder
        shr     bx,1                    ; shift in the remainder sign bit
usequo:
        test    bx,4                    ; needs negative
        jz      finish
        neg     dx
        neg     ax
        sbb     dx,0                    ; negate
finish:
        pop     di
        pop     si
        pop     bp
        retf    8

quick@ldiv:
        div     bx                      ; unsigned divide
                                        ; DX = remainder AX = quotient
        test    di,2                    ; want remainder?
        jz      quick@quo
        xchg    ax,dx

quick@quo:

        xor     dx,dx
        jmp     short finish

F_LUMOD@ endp

_TEXT   ends

