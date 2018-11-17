include stdapp.def
include vm.def
include objects\gCtrlC.def
include library.def
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include gstring.def

UseLib math.def
DefLib main\jpeg.def

include Internal/heapInt.def

ErrorHandlerContext	struct
	EHC_ss	word
	EHC_ds	word
	EHC_es	word
	EHC_di	word
	EHC_si	word
	EHC_cs	word
	EHC_ip	word
	EHC_sp	word
	EHC_bp	word
	EHC_stackBot	word
ErrorHandlerContext	ends

global  JPEGIMPORT: far
global  JPEGTESTFILE: far
global  JPEGEXPORT: far
global  PALGSTRINGCOLELEMENT: far
global  MY_GRPARSEGSTRING:far

global _set_error_handler:far


        SetGeosConvention               ; set calling convention


INIT    segment resource
        assume cs:INIT

        db      "OK"
        dw      InfoResource            ; resource containing format names
        dw      1                       ; contains two sub-formats
        dw      4000h                   ; this is a graphics translator
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
          push    ds                    ; arg 1: pointer to impex data block
          push    si

          mov     ax,idata              ; DS=dgroup
          mov     ds,ax
          mov     ax,25                 ; Allocate default float stack size
          mov     bl,FLOAT_STACK_GROW
          call    FloatInit
          call    JPEGEXPORT            ; Call high-level procedure to do work
          call    FloatExit
          mov     bx,dx                 ; BX:AX returns error code or format ID
        .leave
        ret
TransExport endp

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
          call    JPEGIMPORT            ; Call high-level procedure to do work
          call    FloatExit
          mov     bx,dx                 ; BX:AX returns error code or format ID
          movdw   dxcx,_vmc             ; VMChain of object returned in DX:CX
        .leave
        ret
TransImport endp

TransGetFormat proc far
        uses    es,ds,si,di
        .enter

        push    si                    ; argument file handle

        mov     ax,idata              ; DS=dgroup
        mov     ds,ax
        mov     ax,25                 ; Allocate default float stack size
        mov     bl,FLOAT_STACK_GROW
        call    FloatInit
        call    JPEGTESTFILE          ; Call high-level procedure to do work
        call    FloatExit

        mov     cx, ax
        xor     ax, ax
        .leave
        ret

TransGetFormat endp

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

TransGetExportOptions proc far
        push    ax                             ; 01ED 50
        push    cx                             ; 01EE 51
        push    bx                             ; 01EF 53
        push    bp                             ; 01F0 55
        push    si                             ; 01F1 56
        push    di                             ; 01F2 57
        push    ds                             ; 01F3 1E
        mov     ax,MSG_GEN_VALUE_GET_VALUE
        mov     bx,dx
        mov     si,offset JpegQuality
        mov     di,mask MF_CALL
        call    ObjMessage
        push    dx
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

TransInitImportUI proc far
        ret
TransInitImportUI endp

TransInitExportUI proc far
        ret
TransInitExportUI endp

ASM     ends

include manager.rdef

InfoResource    segment lmem LMEM_TYPE_GENERAL,mask LMF_IN_RESOURCE

                dw      fmt_1_name,fmt_1_mask
                D_OPTR  0 
                D_OPTR  JpegExportGroup
                dw      0C000h     ; Currently we only support import

        dw      0

fmt_1_name      chunk   char
        char    "XJPEG",0
fmt_1_name      endc

fmt_1_mask      chunk   char
        char    "*.jpg",0
fmt_1_mask      endc

InfoResource    ends

ASM_FIXED               segment 

_MYPARSEGSTRING_callback proc far
        uses    si,di,ds,es
        .enter
                push ds                         ; push ptr argument for routine
                push si
                push di                         ; push gstate argument
                push bx                         ; push memory handle
                call PALGSTRINGCOLELEMENT
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

	SetDefaultConvention

; WARNING: THIS ROUTINE MUST BE LOCATED IN A FIXED RESOURCE!  RCI WILL SCREW
; UP THE ALGORITHM IF IT OCCURS BETWEEN THIS ROUTINE AND ITS CALLER!
; Thanks for your cooperation. -Dave

_set_error_handler	proc far	errorContextP:fptr.word
		uses	es, di
		.enter
		mov	ax, size ErrorHandlerContext
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		tst	bx
		jz	returnMem
		mov	cx, es		; original ES
		mov	es, ax
		clr	ax
		mov	es:[EHC_ss], ss
		mov	es:[EHC_ds], ds
		mov	es:[EHC_es], cx
		mov	es:[EHC_di], di
		mov	es:[EHC_si], si
		mov	ax, ss:[bp]	; caller's BP
		mov	es:[EHC_bp], ax
		mov	ax, ss:[bp]+2	; return off
		mov	es:[EHC_ip], ax
		mov	ax, ss:[bp]+4	; return seg
		mov	es:[EHC_cs], ax
		mov	ax, bp
		add	ax, 2		; SP to return to caller
		mov	es:[EHC_sp], ax
		mov	ax, ss:[TPD_stackBot]
		mov	es:[EHC_stackBot], ax
		call	MemUnlock
returnMem:
		mov	es, errorContextP.segment
		mov	di, errorContextP.offset
		mov	es:[di], bx
		mov	ax, 0			; error handler set
		.leave
		ret
_set_error_handler	endp

	SetGeosConvention

ASM_FIXED                ends
