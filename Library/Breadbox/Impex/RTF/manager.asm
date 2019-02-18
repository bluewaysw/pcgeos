include stdapp.def
include vm.def
include impex.def
include Objects/gCtrlC.def

; segment must be "public 'CODE'" to ensure that it combines
; properly with the C segment of the same name.

imptproc_TEXT   segment public 'CODE'
  extrn  IMPORTPROCEDURE: far
  extrn  GETFORMAT: far
imptproc_TEXT   ends

exptproc_TEXT   segment public 'CODE'
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
ifndef FAKE_DOC
        dw      1                       ; contains one sub-format
else
        dw      2                       ; contains two sub-formats
endif
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
          mov     ax,idata              ; DS=dgroup
          mov     ds,ax
          call    EXPORTPROCEDURE       ; Call high-level procedure to do work
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
          mov     ax,idata              ; DS=dgroup
          mov     ds,ax
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
        xor     cx,cx
        ret
TransGetImportUI endp

TransGetExportUI proc far
        xor     cx,cx
        ret
TransGetExportUI endp

TransGetImportOptions proc far
        xor     dx,dx
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


global FINDNEXTUSEDTOKEN: far

UTILITY	segment resource
	assume cs:UTILITY

SetGeosConvention

;void _pascal FindNextUsedToken(MemHandle mem, ChunkHandle tokenArray, word* token)
FINDNEXTUSEDTOKEN proc far mem:hptr, tokenArray:lptr, token:fptr
	uses ax, bx, si, di, ds, es
	.enter
;index = ElementArrayTokenToUsedIndexHandles(*mem, tokenArray, *token, 0, usedCB);
	mov	bx, ss:[mem]
	call	MemDerefDS
	mov	si, ss:[tokenArray]
	xor	bx, bx
	les	di, ss:[token]
	mov	ax, es:[di]
	call	ElementArrayTokenToUsedIndex
;index++;
	inc	ax
;*token = ElementArrayUsedIndexToTokenHandles(*mem, tokenArray, index, 0, usedCB);
	call	ElementArrayUsedIndexToToken
	mov	es:[di], ax
	.leave
	retf
FINDNEXTUSEDTOKEN endp

SetDefaultConvention

UTILITY	ends

;                include htmlimpt.rdef

InfoResource    segment lmem LMEM_TYPE_GENERAL,mask LMF_IN_RESOURCE

infoTable       dw      fmt_1_name,fmt_1_mask
                D_OPTR  0
                dw      0,0
                dw      0C000h          ; we support import and export

ifdef FAKE_DOC
                dw      fmt_2_name,fmt_2_mask
                D_OPTR  0
                dw      0,0
                dw      04000h          ; we only support export
endif

                dw      0               ; no more formats

fmt_1_name      chunk   char
        char    "Rich Text Format (RTF)",0
fmt_1_name      endc

fmt_1_mask      chunk   char
        char    "*.rtf",0
fmt_1_mask      endc

ifdef FAKE_DOC
fmt_2_name      chunk   char
        char    "Microsoft Word 8.0 (97)", 0
fmt_2_name      endc

fmt_2_mask      chunk   char
        char    "*.doc", 0
fmt_2_mask      endc
endif

InfoResource    ends
