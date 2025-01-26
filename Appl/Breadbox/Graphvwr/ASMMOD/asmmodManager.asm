include stdapp.def

EspCode segment

global MYVMCOPYVMCHAIN:far
global MYVMFREEVMCHAIN:far


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

EspCode ends

