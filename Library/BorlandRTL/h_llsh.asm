;	$Id: h_llsh.asm,v 1.1 97/04/07 12:04:17 newdeal Exp $
;[]-----------------------------------------------------------------[]
;|      H_LLSH.ASM -- long shift left                                |
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
        public  LXLSH@
        public  F_LXLSH@
        public  N_LXLSH@

N_LXLSH@ proc near
        pop     bx                      ;fix up for far return
        push    cs
        push    bx
	.fall_thru
N_LXLSH@ endp

LXLSH@ proc far
	.fall_thru
LXLSH@ endp

F_LXLSH@ proc far
        cmp     cl,16
        jae     llsh@small
        mov     bx,ax                   ; save the low bits
        shl     ax,cl                   ; now shift each half
        shl     dx,cl
;
;                       We now have a hole in DX where the upper bits of
;                       AX should have been shifted.  So we must take our
;                       copy of AX and do a reverse shift to get the proper
;                       bits to be or'ed into DX.
;
        neg     cl
        add     cl,16
        shr     bx,cl
        or      dx,bx
        retf
llsh@small:
        sub     cl,16                   ; for shifts more than 15, do this
                                        ; short sequence.
        xchg    ax,dx
        xor     ax,ax                   ; We have now done a shift by 16.
        shl     dx,cl                   ; Now shift the remainder.
        ret
F_LXLSH@ endp

_TEXT   ends

