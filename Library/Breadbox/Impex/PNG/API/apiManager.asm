include stdapp.def
include vm.def
include library.def
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include graphics.def

UseLib Objects/colorC.def
UseLib Objects/gValueC.def

;================================================================================
; UI symbols defined in C that we need to access here: prefix with underscore

global _ImportGroup: nptr
global _ExportGroup: nptr

;================================================================================
; global functions implemented in C
; segment must be "public 'CODE'" to ensure that it combines
; properly with the C segment of the same name.
; imptpng_TEXT = "imp.goc" - ".goc + "_TEXT"

imp_TEXT   segment public 'CODE'
    extrn  IMPORTPROCEDURE: far
    extrn  TESTFILE: far
imp_TEXT   ends

exp_TEXT   segment public 'CODE'
    extrn  EXPORTPROCEDURE: far
exp_TEXT   ends

ui_TEXT   segment public 'CODE'
    extrn  GATHERIMPORTOPTIONS: far
    extrn  GATHEREXPORTOPTIONS: far
ui_TEXT   ends

;================================================================================
; the following functions are required by the GEOS translator interface

global  LibraryEntry: far
global  TransExport: far
global  TransImport: far
global  TransGetFormat: far
global  TransGetImportUI: far
global  TransGetExportUI: far
global  TransInitImportUI: far
global  TransInitExportUI: far
global  TransGetImportOptions: far
global  TransGetExportOptions: far


;================================================================================
; initialization segment for translator
;================================================================================

NUMBER_OF_FORMATS equ 1         ; number of supported formats, must match number of entries in InfoResource

INIT    segment resource
    assume cs:INIT

    db  "OK"
    dw  InfoResource            ; resource containing format names
    dw  NUMBER_OF_FORMATS       ; contains one sub-format
    dw  4000h                   ; this is a graphics translator
    db  "OK"

LibraryEntry proc far
    clc
    ret
LibraryEntry endp

INIT    ends

;================================================================================
; standard translator info resource segment
; Each format variation supported by the translator
; requires one entry in this resource.
;================================================================================

InfoResource    segment lmem LMEM_TYPE_GENERAL, mask LMF_IN_RESOURCE

    dw  fmt_1_name,fmt_1_mask
        D_OPTR  _ImportGroup        ; nptr to import options group ui element root
        D_OPTR  _ExportGroup        ; nptr to export options group ui element root
        dw  0C000h                  ; 8000h = only support import, 0C000h = import and export
    dw  0                           ; closing

fmt_1_name      chunk   char
        char    "PNG", 0
fmt_1_name      endc

fmt_1_mask      chunk   char
        char    "*.png", 0
fmt_1_mask      endc

InfoResource    ends

;================================================================================
; main code segment for translator functions
;================================================================================

ASM     segment resource
    assume cs:ASM

;--------------------------------------------------------------------------------
; The following three functions are the main import/export/format test entry points
;--------------------------------------------------------------------------------
TransExport proc far
    uses    es,ds,si,di
        .enter
        push    ds                    ; arg 1: pointer to impex data block
        push    si

        mov     ax,idata              ; DS=dgroup
        mov     ds,ax
        ;mov     ax,25                 ; Allocate default float stack size
        ;mov     bl,FLOAT_STACK_GROW
        ;call    FloatInit
        call    EXPORTPROCEDURE            ; Call high-level procedure to do work
        ;call    FloatExit
        mov     bx,dx                 ; BX:AX returns error code or format ID
        .leave
        ret
TransExport endp

;--------------------------------------------------------------------------------

TransImport proc far
    uses    es,ds,si,di
_vmc    local   dword
        .enter
        push    ds                    ; arg 1: pointer to impex data block
        push    si
        push    ss                    ; arg 2: pointer to vm chain return buf
        lea     ax,_vmc
        push    ax

        mov     ax,idata              ; DS=dgroup
        mov     ds,ax
        ;mov     ax,25                 ; Allocate default float stack size
        ;mov     bl,FLOAT_STACK_GROW
        ;call    FloatInit
        call    IMPORTPROCEDURE            ; Call high-level procedure to do work
        ;call    FloatExit
        mov     bx,dx                 ; BX:AX returns error code or format ID
        movdw   dxcx,_vmc             ; VMChain of object returned in DX:CX
        .leave
        ret
TransImport endp

;--------------------------------------------------------------------------------

TransGetFormat proc far
    uses    es,ds,si,di
        .enter

        push    si                    ; argument file handle

        mov     ax,idata              ; DS=dgroup
        mov     ds,ax
        ;mov     ax,25                 ; Allocate default float stack size
        ;mov     bl,FLOAT_STACK_GROW
        ;call    FloatInit
        call    TESTFILE          ; Call high-level procedure to do work
        ;call    FloatExit

        mov     cx, ax
        xor     ax, ax
        .leave
        ret

TransGetFormat endp

;--------------------------------------------------------------------------------
; Get the UI dialog for import/export options
;
; These functions retrieve the import / export dialog UI structure from InfoResource.
; The resource contains format-specific UI elements and their configuration.
;
; Input:
;   CX - Format index (which format variation to get UI for)
; Output:
;   DX:CX - UI dialog element optr (object pointer)
;   AX:BX - Reserved (set to 0)
;--------------------------------------------------------------------------------
TransGetImportUI proc far
        mov     bp,00004h                      ; Base offset in InfoResource
        push    di                             ; Save DI
        push    ds                             ; Save DS
        mov     bx,handle InfoResource         ; Get handle to InfoResource
        call    MemLock                        ; Lock resource and get pointer
        mov     ds,ax                          ; DS = resource pointer
        mov     ax,0000Eh                      ; Size of each format entry
        mul     cx                             ; Multiply by format index
        mov     di,00010h                      ; Offset to first format entry
        add     di,ax                          ; Add format offset
        mov     cx,[ds:bp+di+002h]             ; Get high word of UI optr
        mov     dx,[ds:bp+di]                  ; Get low word of UI optr
        call    MemUnlock                      ; Unlock resource
        xor     ax,ax                          ; Clear return registers
        mov     bx,ax
        pop     ds                             ; Restore DS
        pop     di                             ; Restore DI
        ret
TransGetImportUI endp

;--------------------------------------------------------------------------------

TransGetExportUI proc far
        mov     bp,00004h                      ; Base offset in InfoResource
        push    di                             ; Save DI
        push    ds                             ; Save DS
        mov     bx,handle InfoResource         ; Get handle to InfoResource
        call    MemLock                        ; Lock resource and get pointer
        mov     ds,ax                          ; DS = resource pointer
        mov     ax,0000Eh                      ; Size of each format entry
        mul     cx                             ; Multiply by format index
        mov     di,00014h                      ; Offset to export UI field
        add     di,ax                          ; Add format offset
        mov     cx,[ds:bp+di+002h]             ; Get high word of UI optr
        mov     dx,[ds:bp+di]                  ; Get low word of UI optr
        call    MemUnlock                      ; Unlock resource
        xor     ax,ax                          ; Clear return registers
        mov     bx,ax
        pop     ds                             ; Restore DS
        pop     di                             ; Restore DI
        ret
TransGetExportUI endp

;--------------------------------------------------------------------------------
; Get the values that have been chosen / selected in the UI import options.
;--------------------------------------------------------------------------------

TransGetImportOptions proc far uses ax,bx,cx,bp,si,di,ds
    .enter

    push    dx              ; Pass dialog handle as argument
    call    GATHERIMPORTOPTIONS
    mov     dx, ax         ; Move returned handle to DX

    .leave
    ret
TransGetImportOptions endp

;--------------------------------------------------------------------------------
; Get the values that have been chosen / selected in the export options
;--------------------------------------------------------------------------------
TransGetExportOptions proc far uses ax,bx,cx,bp,si,di,ds
    .enter

    push    dx              ; Pass dialog handle as argument
    call    GATHEREXPORTOPTIONS
    mov     dx, ax         ; Move returned handle to DX

    .leave
    ret
TransGetExportOptions endp

;--------------------------------------------------------------------------------
; The following two functions are called once when the import/export dialog is
; created. They can be used to initialize UI elements to default values.
; Not used here.
;--------------------------------------------------------------------------------
TransInitImportUI proc far
        ret
TransInitImportUI endp

;--------------------------------------------------------------------------------

TransInitExportUI proc far
        ret
TransInitExportUI endp

ASM     ends

;================================================================================