include stdapp.def
include vm.def
include Objects/gCtrlC.def
include library.def
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include gstring.def

UseLib math.def

; make UI elements available to us
include manager.rdef

IMPGIF_TEXT   segment public 'CODE'
	extrn GIFIMPORT: far
	extrn GIFTESTFILE: far
IMPGIF_TEXT   ends

EXPGIF_TEXT   segment public 'CODE'
	extrn GIFEXPORT: far
EXPGIF_TEXT   ends

	SetGeosConvention               ; set calling convention

;================================================================================

INIT    segment resource
	assume cs:INIT

;--------------------------------------------------------------------------------

	db      "OK"
	dw      InfoResource            ; resource containing format names
	dw      1                       ; contains two sub-formats
	dw      4000h                   ; this is a graphics translator
	db      "OK"

;--------------------------------------------------------------------------------

global  LibraryEntry: far

LibraryEntry proc far
	clc
	ret
LibraryEntry endp

;--------------------------------------------------------------------------------

INIT    ends

;================================================================================

ASM     segment resource
	assume cs:ASM

global  TransExport: far
global  TransImport: far
global  TransGetFormat: far
global  TransGetImportUI: far
global  TransGetExportUI: far
global  TransInitImportUI: far
global  TransInitExportUI: far
global  TransGetImportOptions: far
global  TransGetExportOptions: far

;--------------------------------------------------------------------------------

TransExport proc far
	uses    es,ds,si,di
	.enter
	  push    ds                    ; arg 1: pointer to impex data block
	  push    si

	  mov     ax,idata              ; DS=dgroup
	  mov     ds,ax
	  mov     ax,25                 ; Allocate default float stack size
	  mov     bl,FLOAT_STACK_GROW
	  call    FloatInit
	  call    GIFEXPORT            	; Call high-level procedure to do work
	  call    FloatExit
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
	  mov     ax,25                 ; Allocate default float stack size
	  mov     bl,FLOAT_STACK_GROW
	  call    FloatInit
	  call    GIFIMPORT             ; Call high-level procedure to do work
	  call    FloatExit
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
	mov     ax,25                 ; Allocate default float stack size
	mov     bl,FLOAT_STACK_GROW
	call    FloatInit
	call    GIFTESTFILE           ; Call high-level procedure to do work
	call    FloatExit

	mov     cx, ax
	xor     ax, ax
	.leave
	ret

TransGetFormat endp

;--------------------------------------------------------------------------------

TransGetImportUI proc far
	mov     bp,00004h                      ; 0006 BD0800
	push    di                             ; 0009 57
	push    ds                             ; 000A 1E
	mov     bx,handle InfoResource         ; 000B BB1400
	call    MemLock                        ; 000E 9A05000000
	mov     ds,ax                          ; 0013 8ED8
	mov     ax,0000Eh                      ; 0015 B80E00
	mul     cx                             ; 0018 F7E1
	mov     di,00010h                      ; 001A BF1000
	add     di,ax                          ; 001D 03F8
	mov     cx,[ds:bp+di+002h]             ; 001F 3E8B4B02
	mov     dx,[ds:bp+di]                  ; 0023 3E8B13
	call    MemUnlock                      ; 0026 9A06000000
	xor     ax,ax                          ; 002B 33C0
	mov     bx,ax                          ; 002D 8BD8
	pop     ds                             ; 002F 1F
	pop     di                             ; 0030 5F
	ret
TransGetImportUI endp

;--------------------------------------------------------------------------------

TransGetExportUI proc far
	mov     bp,00004h                      ; 0006 BD0800
	push    di                             ; 0009 57
	push    ds                             ; 000A 1E
	mov     bx,handle InfoResource         ; 000B BB1400
	call    MemLock                        ; 000E 9A05000000
	mov     ds,ax                          ; 0013 8ED8
	mov     ax,0000Eh                      ; 0015 B80E00
	mul     cx                             ; 0018 F7E1
	mov     di,00014h                      ; 001A BF1000
	add     di,ax                          ; 001D 03F8
	mov     cx,[ds:bp+di+002h]             ; 001F 3E8B4B02
	mov     dx,[ds:bp+di]                  ; 0023 3E8B13
	call    MemUnlock                      ; 0026 9A06000000
	xor     ax,ax                          ; 002B 33C0
	mov     bx,ax                          ; 002D 8BD8
	pop     ds                             ; 002F 1F
	pop     di                             ; 0030 5F
	ret
TransGetExportUI endp

;--------------------------------------------------------------------------------

TransGetImportOptions proc far
	push    ax                             ; 01ED 50
	push    cx                             ; 01EE 51
	push    bx                             ; 01EF 53
	push    bp                             ; 01F0 55
	push    si                             ; 01F1 56
	push    di                             ; 01F2 57
	push    ds                             ; 01F3 1E

comment %
	mov     ax,MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov     bx,dx
	mov     si,offset BmpExpBitFormGroup
	mov     di,mask MF_CALL
	call    ObjMessage

%
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
	pop     ds                             ; 0236 1F
	pop     di                             ; 0237 5F
	pop     si                             ; 0238 5E
	pop     bp                             ; 0239 5D
	pop     bx                             ; 023A 5B
	pop     cx                             ; 023B 59
	pop     ax                             ; 023C 58
	ret
TransGetImportOptions endp

;--------------------------------------------------------------------------------

TransGetExportOptions proc far
        push    ax                             ; 01ED 50
        push    cx                             ; 01EE 51
        push    bx                             ; 01EF 53
        push    bp                             ; 01F0 55
        push    si                             ; 01F1 56
        push    di                             ; 01F2 57
        push    ds                             ; 01F3 1E

        mov     ax,MSG_GEN_ITEM_GROUP_GET_SELECTION
        mov     bx,dx
        mov     si,offset GifExpFormGroup
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
        pop     ds                             ; 0236 1F
        pop     di                             ; 0237 5F
        pop     si                             ; 0238 5E
        pop     bp                             ; 0239 5D
        pop     bx                             ; 023A 5B
        pop     cx                             ; 023B 59
        pop     ax                             ; 023C 58
        ret
TransGetExportOptions endp

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

InfoResource    segment lmem LMEM_TYPE_GENERAL,mask LMF_IN_RESOURCE

		dw      fmt_1_name,fmt_1_mask
		D_OPTR  0
		D_OPTR  GifExportGroup
		dw      0C000h     ; Currently we only support import

	dw      0

fmt_1_name      chunk   char
	char    "GIF",0
fmt_1_name      endc

fmt_1_mask      chunk   char
	char    "*.gif",0
fmt_1_mask      endc

InfoResource    ends

;================================================================================
