;	$Id: h_lursh.asm,v 1.1 97/04/07 12:03:59 newdeal Exp $
;[]-----------------------------------------------------------------[]
;|      H_LURSH.ASM -- long shift right                              |
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
        public  LXURSH@
        public  F_LXURSH@
        public  N_LXURSH@

N_LXURSH@ proc near
        pop     bx                      ;fix up far return
        push    cs
        push    bx
	.fall_thru
N_LXURSH@ endp

LXURSH@ proc far
	.fall_thru
LXURSH@ endp

F_LXURSH@ proc far
        cmp     cl,16
        jae     lsh@small
        mov     bx,dx                   ; save the high bits
        shr     ax,cl                   ; now shift each half
        shr     dx,cl
;
;                       We now have a hole in AX where the lower bits of
;                       DX should have been shifted.  So we must take our
;                       copy of DX and do a reverse shift to get the proper
;                       bits to be or'ed into AX.
;
        neg     cl
        add     cl,16
        shl     bx,cl
        or      ax,bx
        ret
lsh@small:
        sub     cl,16                   ; for shifts more than 15, do this
                                        ; short sequence.
        xchg    ax,dx
        xor     dx,dx                   ; We have now done a shift by 16.
        shr     ax,cl                   ; Now shift the remainder.
        ret
F_LXURSH@ endp

_TEXT   ends

