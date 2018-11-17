                include stdapp.def

                SetGeosConvention               ; set calling convention

ASM_TEXT        segment public 'CODE'

        if ERROR_CHECK
        global F_CHKSTK@:far
; Called with AX containing the number of bytes to be allocated on the stack.
; Must return with the stackpointer lowered by AX bytes.
F_CHKSTK@       proc far
        pop     cx                      ; save return address
        pop     dx
        sub     sp,ax                   ; allocated space on stack
        push    dx                      ; restore return address
        push    cx
        call    ECCHECKSTACK            ; still enough room on stack?
        ret                             ; return to calling routine
F_CHKSTK@       endp
        endif

ASM_TEXT        ends
