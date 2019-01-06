include geos.def        ; standard macros
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include gstring.def


; public routines defined in this module
global MY_GRMAPCOLORINDEX:far

        SetGeosConvention               ; set calling convention

ASM_TEXT          segment resource

MY_GRMAPCOLORINDEX proc far _gstate:word, _col:word
        uses    bx,di
        .enter
                mov di,_gstate
                mov ah,{byte}_col
                call GrMapColorIndex
                mov ah,bl
                mov dl,bh
                mov dh,{byte}_col
        .leave
        ret
MY_GRMAPCOLORINDEX endp

ASM_TEXT          ends

