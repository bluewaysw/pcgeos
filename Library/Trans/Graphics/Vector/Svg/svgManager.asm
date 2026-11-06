include stdapp.def
include vm.def
include library.def
DefLib Internal/xlatLib.def

svgAdapter_TEXT segment public 'CODE'
        extrn SVGADAPTERIMPORT:far
        extrn SVGADAPTEREXPORT:far
        extrn SVGADAPTERGETFORMAT:far
svgAdapter_TEXT ends

global LibraryEntry:far
global TransExport:far
global TransImport:far
global TransGetFormat:far
global TransGetImportUI:far
global TransGetExportUI:far
global TransInitImportUI:far
global TransInitExportUI:far
global TransGetImportOptions:far
global TransGetExportOptions:far

INIT segment resource
        assume cs:INIT

        db      "OK"
        dw      InfoResource
        dw      1
        dw      4000h
        db      "OK"

LibraryEntry proc far
        clc
        ret
LibraryEntry endp

INIT ends

ASM segment resource
        assume cs:ASM

TransExport proc far
        uses    es, ds, si, di
        .enter
        push    ds
        push    si
        mov     ax, idata
        mov     ds, ax
        call    SVGADAPTEREXPORT
        mov     bx, dx
        .leave
        ret
TransExport endp

TransImport proc far
        uses    es, ds, si, di
resultChain local dword
        .enter
        clrdw   resultChain
        push    ds
        push    si
        push    ss
        lea     ax, resultChain
        push    ax
        mov     ax, idata
        mov     ds, ax
        call    SVGADAPTERIMPORT
        mov     bx, dx
        movdw   dxcx, resultChain
        .leave
        ret
TransImport endp

TransGetFormat proc far
        uses    es, ds, si, di, bx, dx
        .enter
        push    si
        mov     ax, idata
        mov     ds, ax
        call    SVGADAPTERGETFORMAT
        mov     cx, ax
        clr     ax
        .leave
        retf
TransGetFormat endp

TransGetImportUI proc far
        clr     ax
        clr     bx
        clr     cx
        clr     dx
        ret
TransGetImportUI endp

TransGetExportUI proc far
        clr     ax
        clr     bx
        clr     cx
        clr     dx
        ret
TransGetExportUI endp

TransGetImportOptions proc far
        clr     dx
        ret
TransGetImportOptions endp

TransGetExportOptions proc far
        clr     dx
        ret
TransGetExportOptions endp

TransInitImportUI proc far
        ret
TransInitImportUI endp

TransInitExportUI proc far
        ret
TransInitExportUI endp

ASM ends

InfoResource segment lmem LMEM_TYPE_GENERAL, mask LMF_IN_RESOURCE

        dw      svgName, svgMask
          D_OPTR 0
          dw      0, 0
          dw      0c000h
        dw      0

svgName chunk char
        char    "SVG", 0
svgName endc

svgMask chunk char
        char    "*.svg", 0
svgMask endc

InfoResource ends
