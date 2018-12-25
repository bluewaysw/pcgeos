include stdapp.def
include gstring.def

            SetGeosConvention                   ; set calling convention

global  PALGSTRINGCOLELEMENT: far

idata   segment

global  MY_GRPARSEGSTRING:far

;---------------------------------------------------------------------------

_MYPARSEGSTRING_callback    proc far

            uses    si,di,ds,es

            .enter
                push ds                         ; push ptr argument for routine
                push si
                push di                         ; push gstate argument
                push bx                         ; push memory handle
                call PALGSTRINGCOLELEMENT
            .leave

            ret

_MYPARSEGSTRING_callback endp

;---------------------------------------------------------------------------

MY_GRPARSEGSTRING   proc far    _gstate:word,
                                _gstring:word,
                                _flags:word,
                                _h:word

            uses    bx,cx,dx,si,di

            .enter

                mov di,_gstate                  ; load arguments
                mov si,_gstring
                mov dx,_flags
                mov bx,segment _MYPARSEGSTRING_callback
                mov cx,offset _MYPARSEGSTRING_callback
                                                ; pointer to callback thunk
                mov bp,_h                       ; handle passed to callback
                call GrParseGString             ; do it!
            .leave

            ret
MY_GRPARSEGSTRING endp

idata       ends
