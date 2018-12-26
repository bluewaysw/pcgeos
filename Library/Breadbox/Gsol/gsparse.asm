include geos.def        ; standard macros
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include gstring.def


global GSOLONEGSTRINGELEMENT: far

; public routines defined in this module
global MY_GRPARSEGSTRING:far

        SetGeosConvention               ; set calling convention

ASM_FIXED                segment resource

_MYPARSEGSTRING_callback proc far
        uses    si,di,ds,es
        .enter
                push ds                         ; push ptr argument for routine
                push si
                push di                         ; push gstate argument
                push bx                         ; push memory handle
                call GSOLONEGSTRINGELEMENT
        .leave
        ret
_MYPARSEGSTRING_callback endp

MY_GRPARSEGSTRING proc far _gstate:word, _gstring:word, _flags:word, _h:word
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

ASM_FIXED                ends
