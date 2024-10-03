include stdapp.def

include geos.def        ; standard macros
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include gstring.def


EspCode segment

; public routines defined in this module
global MYVMCOPYVMCHAIN:far
global MYVMFREEVMCHAIN:far
global MYGRMAPCOLORINDEX:far

SetGeosConvention

MYVMCOPYVMCHAIN  proc    far     sourceFile:word,
                                 sourceChainL:word,
                                 sourceChainH:word,
                                 destFile:word

	.enter

        mov     dx, destFile
        mov     bx, sourceFile
        mov     ax, sourceChainL
        mov     bp, sourceChainH
        call    VMCopyVMChain
        mov     dx, bp

	.leave
	ret

MYVMCOPYVMCHAIN  endp

MYVMFREEVMCHAIN  proc    far     sourceFile:word,
                                 sourceChainL:word,
                                 sourceChainH:word

	.enter

        mov     bx, sourceFile
        mov     ax, sourceChainL
        mov     bp, sourceChainH
        call    VMFreeVMChain
        mov     dx, bp

	.leave
	ret

MYVMFREEVMCHAIN  endp

MYGRMAPCOLORINDEX proc  far     _gstate:word,
                                _col:word
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

MYGRMAPCOLORINDEX endp


EspCode ends

