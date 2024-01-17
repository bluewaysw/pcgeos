include stdapp.def
include vm.def
include impex.def
include Objects/gCtrlC.def

; segment must be "public 'CODE'" to ensure that it combines
; properly with the C segment of the same name.

imptproc_TEXT   segment byte public 'CODE'
  extrn  IMPORTPROCEDURE: far
  extrn  GETFORMAT: far
imptproc_TEXT   ends

exptproc_TEXT   segment byte public 'CODE'
  extrn  EXPORTPROCEDURE: far
exptproc_TEXT   ends


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


INIT    segment resource
        assume cs:INIT

        db      "OK"
        dw      InfoResource            ; resource containing format names
        dw      1                       ; contains one sub-format
        dw      mask IDC_TEXT           ; this is a text translator
        db      "OK"

LibraryEntry proc far
        clc
        ret
LibraryEntry endp

INIT    ends


ASM     segment resource
        assume cs:ASM

TransExport proc far
        uses    es,ds,si,di
        .enter
          push    ds                    ; arg 1: pointer to export data block
          push    si
          call    EXPORTPROCEDURE      ; Call high-level procedure to do work
                                        ; AX returns error code
        .leave
        ret
TransExport endp

TransImport proc far
        uses    es,ds,si,di
_vmc    local   dword
        .enter
          push    ds                    ; arg 1: pointer to import data block
          push    si
          push    ss                    ; arg 2: pointer to vm chain return buf
          lea     ax,_vmc
          push    ax
          call    IMPORTPROCEDURE       ; Call high-level procedure to do work
          mov     bx,dx                 ; BX:AX returns error code or format ID
          movdw   dxcx,_vmc             ; VMChain of object returned in DX:CX
        .leave
        ret
TransImport endp

TransGetFormat proc far
        uses    es,ds,si,di,bx,dx
        .enter
          push    si                    ; handle of file to be tested
          mov     ax,idata              ; DS=dgroup
          mov     ds,ax
          call    GETFORMAT             ; Call high-level procedure to do work
          mov     cx,ax                 ; return word value
          xor     ax,ax
        .leave
        retf
TransGetFormat endp

TransGetImportUI proc far
        mov     bp,4                    ; offset of pointer in info entry
        push    di
        push    ds
        mov     bx,handle InfoResource
        call    MemLock
        mov     ds,ax
        mov     ax,14                   ; size of one entry
        mul     cx
        mov     di,offset infoTable
        add     di,ax
        mov     cx,[ds:bp+di+002h]
        mov     dx,[ds:bp+di]
        call    MemUnlock
        xor     ax,ax
        mov     bx,ax
        pop     ds
        pop     di
        ret
TransGetImportUI endp

TransGetExportUI proc far
        xor     cx,cx
        ret
TransGetExportUI endp

TransGetImportOptions proc far
        push    ax
        push    cx
        push    bx
        push    bp
        push    si
        push    di
        push    ds

        cmp     dx,0                    ; UI not yet initialized?
        je      iopt_err                ; return no options (null handle)

        mov     ax,MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
        mov     bx,dx
        mov     si,offset booleanOptions
        mov     di,mask MF_CALL
        call    ObjMessage

        push    ax
        mov     ax,00002h
        mov     cl,050h
        mov     ch,040h
        call    MemAlloc
        xor     dx,dx
        jc      iopt_err
        push    ax
        pop     ds
        pop     ax
        mov     [ds:00000h],ax          ; booleanOptions
        call    MemUnlock
        mov     dx,bx
        clc
iopt_err:
        pop     ds
        pop     di
        pop     si
        pop     bp
        pop     bx
        pop     cx
        pop     ax
        ret
TransGetImportOptions endp

TransGetExportOptions proc far
        xor     dx,dx
        ret
TransGetExportOptions endp

TransInitImportUI proc far
        ret
TransInitImportUI endp

TransInitExportUI proc far
        ret
TransInitExportUI endp

ASM     ends

                include htmlimpt.rdef

InfoResource    segment lmem LMEM_TYPE_GENERAL,mask LMF_IN_RESOURCE

infoTable       dw      fmt_1_name,fmt_1_mask
                D_OPTR  ImportSettings
                dw      0,0
                dw      0C000h          ; we support import and export

                dw      0

fmt_1_name      chunk   char
        char    "HTML (Hypertext Markup Language)",0
fmt_1_name      endc

fmt_1_mask      chunk   char
        char    "*.htm",0
fmt_1_mask      endc

InfoResource    ends
