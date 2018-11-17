COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  ==CONFIDENTIAL INFORMATION== 
%  COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
%  ALL RIGHTS RESERVED  --
%  THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
%  NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
%  RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
%  NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
%  CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
%  AGREEMENT.
%  
%  Project: Word for Windows Translation Library
%  File:    manager.asm
%  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include geos.def
include geode.def
include Objects/processC.def
include	file.def
include library.def
include object.def
include graphics.def
include gstring.def
include win.def
include system.def
include resource.def
include heap.def
include ec.def
include sem.def

UseLib	ui.def				; Include library definitions only
UseLib	math.def
UseLib	impex.def

DefLib	Internal/xlatLib.def

; segment must be "public 'CODE'" to ensure that it combines
; properly with the C segment of the same name.

IMPTPROC_TEXT   segment public 'CODE'
  extrn  IMPORTPROCEDURE: far
  extrn  GETFORMAT: far
IMPTPROC_TEXT   ends

;EXPTPROC_TEXT   segment public 'CODE'
;  extrn  EXPORTPROCEDURE: far
;EXPTPROC_TEXT   ends

udata		segment
            threadSem   hptr		; library's semaphore
udata		ends

; Define all of the formats we support, and the structures Impex expects
;
; If you change these, you *MUST* change the corresponding enumeration in
; libfmt.h.
;
DefTransLib

DefTransFormat	TF_MSWORD_8_0, \
		"Microsoft Word 8.0 (97)", \
		"*.doc", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE>

if 0
DefTransFormat	TF_MSWORD_6_0, \
		"Microsoft Word 6.0 (95)", \
		"*.doc", \
		0, \
		0, \
		<mask IFI_IMPORT_CAPABLE>
endif

EndTransLib	<mask IDC_TEXT>

; Include the Library/Trans/TransCommon code.

REENTRANT_CODE equ FALSE

include transCommonGlobal.def
include	transLibEntry.asm		; library entry point

ASM     segment resource
        assume cs:ASM

TransExport proc far
        uses    es,ds,si,di
        .enter
;          push    ds                    ; arg 1: pointer to export data block
;          push    si
;          mov     ax,idata              ; DS=dgroup
;          mov     ds,ax
;          call    EXPORTPROCEDURE       ; Call high-level procedure to do work
                                        ; AX returns error code
        clr ax
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
                                        ; AX -> TransError
          mov     cx,dx                 ; CX -> Format number or NO_IDEA_FORMAT
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


