include stdapp.def
include vm.def
include library.def
include resource.def    ; idata/udata, ProcCallFixedOrMovable etc.
include graphics.def

UseLib Objects/colorC.def
UseLib Objects/gValueC.def


png_ui_TEXT   segment public 'CODE'
    extrn  PNGIMPORTATTACH: far
png_ui_TEXT   ends

; UI symbols defined in C that we need to access here: prefix with underscore!
global _PngImportGroup: nptr
global _PngExportGroup: nptr
global _PngAlphaMethodGroup: nptr
global _PngAlphaBlendColor: nptr
global _PngAlphaThresholdValue: nptr
global _PngExpFormGroup: nptr

; global functions implemented in C
; segment must be "public 'CODE'" to ensure that it combines
; with properly the C segment of the same name.
; imptpng_TEXT = "imppng.goc" - ".goc + "TEXT"
imppng_TEXT   segment public 'CODE'
    extrn  PNGIMPORT: far
    extrn  PNGTESTFILE: far
imppng_TEXT   ends

exppng_TEXT   segment public 'CODE'
    extrn  PNGEXPORT: far
exppng_TEXT   ends


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


PNG_ALPHA_OPTIONS_SIZE equ     6        ; sizeof(struct ie_uidata)

;================================================================================

INIT    segment resource
    assume cs:INIT

    db  "OK"
    dw  InfoResource            ; resource containing format names
    dw  1                       ; contains one sub-format
    dw  4000h                   ; this is a graphics translator
    db  "OK"

LibraryEntry proc far
    clc
    ret
LibraryEntry endp

INIT    ends

;================================================================================

ASM     segment resource
    assume cs:ASM

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
        call    PNGEXPORT            ; Call high-level procedure to do work
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
        call    PNGIMPORT            ; Call high-level procedure to do work
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
        call    PNGTESTFILE          ; Call high-level procedure to do work
        ;call    FloatExit

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

TransGetImportOptions proc far uses ax,bx,cx,bp,si,di,ds
    .enter

    mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION    ; message to get selected item
    mov     bx,dx                                   ; dialog handle
    mov     si, offset _PngAlphaMethodGroup         ; UI element is PngAlphaMethodGroup
    mov     di, mask MF_CALL                        ; flags
    call    ObjMessage                              ; get selected item

    push    ax                                      ; store selected method

    mov     ax, MSG_GEN_VALUE_GET_VALUE             ; get alpha threshold (WWFixed)
    mov     si, offset _PngAlphaThresholdValue
    mov     di, mask MF_CALL
    call    ObjMessage
    and     dx, 00FFh                               ; clamp to byte range
    push    dx                                      ; store threshold

    mov     ax, MSG_COLOR_SELECTOR_GET_COLOR        ; grab blend color selection
    mov     si, offset _PngAlphaBlendColor
    mov     di, mask MF_CALL
    call    ObjMessage

    mov     ax, cx                                  ; AL=index/red, AH=flags
    mov     bx, dx                                  ; BL=green, BH=blue
    test    ah, CF_RGB                              ; already RGB values?
    jnz     short color_ready

    mov     ah, al                                  ; convert palette index to RGB
    xor     dx, dx
    xor     di, di
    call    GrMapColorIndex

color_ready:
    xor     ah, ah                                  ; clear flag bits before storing red
    push    bx                                      ; save green & blue (BH/BL)
    push    ax                                      ; save red (AL)

    mov     ax, PNG_ALPHA_OPTIONS_SIZE              ; size of options structure (bytes)
    mov     cl, mask HF_SWAPABLE                    ; 50h = movable + swapable
    mov     ch, mask HAF_ZERO_INIT or mask HAF_LOCK ; 40h = zero filled + locked
    call    MemAlloc                                ; allocate options structure
    xor     dx,dx                                   ; no special flags
    jc      alloc_fail                              ; jump if error

    mov     ds, ax                                  ; set DS to options block
    mov     di, bx                                  ; save mem handle while we use BX

    pop     ax                                      ; red (AL)
    pop     bx                                      ; green/blue (BL/BH)
    pop     dx                                      ; threshold (DL)
    pop     cx                                      ; method (word)

    mov     [ds:00000h], cx                         ; store method
    mov     [ds:00002h], dl                         ; store alpha threshold
    mov     [ds:00003h], al                         ; store blend color red
    mov     [ds:00004h], bl                         ; store blend color green
    mov     [ds:00005h], bh                         ; store blend color blue

    mov     bx, di                                  ; restore mem handle
    call    MemUnlock                               ; unlock options structure
    mov     dx,di                                   ; return handle in DX
    clc                                             ; clear carry to indicate success
    jmp     short iopt_done

alloc_fail:
    add     sp, 8                                   ; discard saved values on error

iopt_err:
iopt_done:
    .leave
    ret
TransGetImportOptions endp

;--------------------------------------------------------------------------------

TransGetExportOptions proc far uses ax,bx,cx,bp,si,di,ds
        .enter

        mov     ax,MSG_GEN_ITEM_GROUP_GET_SELECTION
        mov     bx,dx
        mov     si,offset _PngExpFormGroup
        mov     di,mask MF_CALL
        call    ObjMessage

        push    ax                                      ; store selected option

        mov     ax,00002h                               ; size of options structure (bytes), 2 = word
        mov     cl, mask HF_SWAPABLE                    ; 50h = movable + swapable
        mov     ch, mask HAF_ZERO_INIT or mask HAF_LOCK ; 40h = zero filled + locked
        call    MemAlloc                                ; allocate options structure
        xor     dx,dx                                   ; no special flags
        jc      iopt_err                                ; jump if error

        push    ax                                      ; save pointer to options structure
        pop     ds                                      ; set DS to point to it
        pop     ax                                      ; restore selected option
        mov     [ds:00000h],ax                          ; move selected value to bottom of options structure (?)
        call    MemUnlock                               ; unlock options structure
        mov     dx,bx                                   ; restore dialog handle
        clc
iopt_err:
        .leave
        ret
TransGetExportOptions endp

;--------------------------------------------------------------------------------

TransInitImportUI proc far
        or      cx, cx
        jz      short tiu_done

        push    cx                                  ; uiHandle
        push    dx                                  ; uiChunk
        call    PNGIMPORTATTACH
tiu_done:
        ret
TransInitImportUI endp

;--------------------------------------------------------------------------------

TransInitExportUI proc far
        ret
TransInitExportUI endp

ASM     ends

;================================================================================

InfoResource    segment lmem LMEM_TYPE_GENERAL, mask LMF_IN_RESOURCE

    dw  fmt_1_name,fmt_1_mask
        D_OPTR  _PngImportGroup ; nptr to import options group ui element root
        D_OPTR  _PngExportGroup ; nptr to export options group ui element root
        dw  0C000h          ; 8000h = only support import, 0C000h = import and export
    dw  0                   ; closing

fmt_1_name      chunk   char
        char    "PNG", 0
fmt_1_name      endc

fmt_1_mask      chunk   char
        char    "*.png", 0
fmt_1_mask      endc

InfoResource    ends

;================================================================================
