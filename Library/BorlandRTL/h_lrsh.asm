;	$Id: h_lrsh.asm,v 1.1 97/04/07 12:04:16 newdeal Exp $
;[]-----------------------------------------------------------------[]
;|      H_LRSH.ASM -- long shift right                               |
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
        public  LXRSH@
        public  F_LXRSH@
        public  N_LXRSH@

N_LXRSH@ proc near
        pop     bx                      ;fix up for far return
        push    cs
        push    bx
	.fall_thru
N_LXRSH@ endp

LXRSH@ proc far
	.fall_thru
LXRSH@ endp

F_LXRSH@ proc far
        cmp     cl,16
        jae     lrsh@small
        mov     bx,dx                   ; save the high bits
        shr     ax,cl                   ; now shift each half
        sar     dx,cl
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
lrsh@small:
        sub     cl,16                   ; for shifts more than 15, do this
                                        ; short sequence.
        xchg    ax,dx                   ;
        cwd                             ; We have now done a shift by 16.
        sar     ax,cl                   ; Now shift the remainder.
        ret
F_LXRSH@ endp

_TEXT   ends

