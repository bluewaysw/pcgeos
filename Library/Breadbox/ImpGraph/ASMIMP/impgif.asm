COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) Breadbox Computer Company 1997 -- All Rights Reserved

PROJECT:        Import GIF library
FILE:           impgif.asm

AUTHOR:         Lysle Shields

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
    Name	Date		Description
    ----	----		-----------
    FR      07/08/97        Initial revision

DESCRIPTION:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;============================================================================
;       EXPORTED PROCEDURES
;============================================================================

global ImpGIFCreate:far
global IMPGIFCREATE:far
global ImpGIFDestroy:far
global IMPGIFDESTROY:far
global ImpGIFProcess:far
global IMPGIFPROCESS:far
global ImpGIFProcessFile:far
global IMPGIFPROCESSFILE:far
global ImpGIFGetInfo:far
global IMPGIFGETINFO:far
if PROGRESS_DISPLAY
global IMPGIFGETPROGRESSINFO:far
endif
global IMPPACKBITS:far

ImpGIFCode segment

;----------------------------------------------------------------------------
; Routine:  ImpGIFCreate
;----------------------------------------------------------------------------
; Description:
;    Create a block of data that is used by all future transactions.
;
; Inputs:
;    AX            - VM File handle to create GIF bitmap in
;    CX            - AllocWatcher handle
;    SI            - 1 if want 256 palette downgrading, else 0
;	 ES:DI		   - MimeStatus ptr
;
; Outputs:
;    BX            - Returned MemHandle/ImpGIFHandle
;    carry         - set if failed, clear if success
;
; Destroys:        CX, DX
;
;----------------------------------------------------------------------------

ImpGIFCreate proc far
        ; Allocate a block of memory that will be used as a segment
        push cx
        mov dx, ax
        mov ax, size ImpGIFStruct
        mov cl, mask HF_SWAPABLE or mask HF_SHARABLE
        mov ch, mask HAF_ZERO_INIT or mask HAF_LOCK
        call MemAlloc
        jc no_create

        pop cx

        ; Initialize the structure with the passed data
        ; (vm file in this case)
        push ds
        mov ds, ax
        mov [IGS_vmFile], dx
        mov ax, size GIFHeader
        mov [IGS_bytesNeeded], ax
        mov ax, offset IStateReviewHeader
        mov [IGS_stateFunction], ax
        mov ax, IG_STATUS_OK
        mov [IGS_lastStatus], ax
        mov [IGS_allocWatcher], cx
        mov cx, si
        mov [IGS_wantSystemPalette], cl
        mov ax, 1
        mov [IGS_loopCount], ax
		movdw [IGS_mimeStatus], esdi, ax

        push bx

        ; Now create the uncompression dictionary
        call IDictionaryCreate
        jc cancel_create

        pop bx
        pop ds
        call MemUnlock

        ; Return the BlockHandle in BX
        ; Carry is clear if allocated, else set
        clc
        ret
no_create:
        xor bx, bx
        stc
        ret

cancel_create:
        ; We were able to create the block, but not the dictionary.

        ; Ensure everything is gone.
        call IDictionaryDestroy

        pop bx
        pop ds
        call MemUnlock
        call MemFree
	jmp	no_create

ImpGIFCreate endp


;----------------------------------------------------------------------------
; Routine:  ImpGIFDestroy
;----------------------------------------------------------------------------
; Description:
;    When done with a GIF import, you destroy the structure by calling it
;    here.
;
; Inputs:
;    BX            - ImpGIFHandle
;
; Destroys:        BX
;
;----------------------------------------------------------------------------

ImpGIFDestroy proc far
        push ds
        push ax
        push bx
        call MemLock
        mov ds, ax
        call IDictionaryDestroy
        pop bx
        call MemUnlock
        call MemFree
        pop ax
        pop ds
        ret
ImpGIFDestroy endp

;----------------------------------------------------------------------------
; Routine:  InBufferAddData
;----------------------------------------------------------------------------
; Description:
;    Take in a group of data and stores the data into the incoming buffer.
;    Since the buffer is a wrap around buffer, it is not enough to just
;    do a rep movsb.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Data coming in
;    CX            - Number of data bytes coming in
;    carry         - set if this is the last block, else cleared
;
; Destroys:  AX, CX, DI
;
;----------------------------------------------------------------------------
InBufferAddData proc near
        ; set flag that we are on the last block if the carry is set
        jnc not_lastBlock
        mov al, 0xFF
        mov [IGS_hitLast], al

not_lastBlock:
        ; Check the number of bytes available for the incoming size
EC <    mov ax, INBUFFER_SIZE      >
EC <    sub ax, [IGS_inBufCount]   >
EC <    cmp ax, cx                 >
EC <    jg enough_space            >
EC <    mov ax, 0xFFFF             >
EC <    call FatalError            >

EC < enough_space:                 >
        ; Don't add anything if we weren't given anything
        cmp cx, 0
        je skip_add

        ; Note how many more characters we are going to have
        add [IGS_inBufCount], cx

        ; Add one character at a time to the input buffer
        mov si, [IGS_inBufEnd]
loop_add_data:
        mov al, es:[di]
        mov ds:[si].IGS_inBuffer, al
        inc di
        inc si
        and si, INBUFFER_SIZE-1
        loop loop_add_data
        mov [IGS_inBufEnd], si
skip_add:
        ret
InBufferAddData endp

;----------------------------------------------------------------------------
; Routine:  InBufferGetByte
;----------------------------------------------------------------------------
; Description:
;    Read in one byte of data.  Standard code will follow the call with
;    a jc (Jump if Carry) command to take care of error conditions.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry set
;       AX         - ImpGIFStatus error
;                        IG_STATUS_NEED_DATA, or IG_STATUS_END_FOUND
;    carry clear
;       AL         - byte of data
;
; Destroys:  AH, BX
;
;----------------------------------------------------------------------------

InBufferGetByte proc near
        ; Only grab a byte if we have not caught up with the end position
        mov bx, [IGS_inBufPos]
        cmp bx, [IGS_inBufEnd]
        je buffer_empty

        ; Grab the byte and update the position (wrapping as needed)
        mov al, [bx].IGS_inBuffer
        inc bx
        and bx, INBUFFER_SIZE-1
        mov [IGS_inBufPos], bx

        ; One less character in the buffer, note it.
        dec [IGS_inBufCount]
        clc
        ret

buffer_empty:
        ; No data is in the buffer.  Are we hitting the end of the stream
        ; or is there supposed to be more?
        test [IGS_hitLast], 0xFF
        jnz end_found

        ; There is supposed to be more, but we don't have it
        mov ax, IG_STATUS_NEED_DATA
        stc
        ret

end_found:
        ; The end of the stream has been reached.  No data to give.
        mov ax, IG_STATUS_END_DATA
        stc
        ret
InBufferGetByte endp


;----------------------------------------------------------------------------
; Routine:  InBufferPeekByte
;----------------------------------------------------------------------------
; Description:
;    Look at the byte at the front of the buffer.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry set
;       AX         - ImpGIFStatus error
;                        IG_STATUS_NEED_DATA, or IG_STATUS_END_FOUND
;    carry clear
;       AL         - first byte of data
;
; Destroys:  AH, BX
;
;----------------------------------------------------------------------------

InBufferPeekByte proc near
        ; Only grab a byte if we have not caught up with the end position
        mov bx, [IGS_inBufPos]
        cmp bx, [IGS_inBufEnd]
        je buffer_empty

        ; Get the first byte without removing it
        mov al, [bx].IGS_inBuffer
        clc
        ret

buffer_empty:
        ; No data is in the buffer.  Are we hitting the end of the stream
        ; or is there supposed to be more?
        test [IGS_hitLast], 0xFF
        jnz end_found

        ; There is supposed to be more, but we don't have it
        mov ax, IG_STATUS_NEED_DATA
        stc
        ret

end_found:
        ; The end of the stream has been reached.  No data to give.
        mov ax, IG_STATUS_END_DATA
        stc
        ret
InBufferPeekByte endp


;----------------------------------------------------------------------------
; Routine:  InBufferGetWord
;----------------------------------------------------------------------------
; Description:
;    Read a word and put into AX
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry set
;       AX         - ImpGIFStatus error
;                        IG_STATUS_NEED_DATA, or IG_STATUS_END_FOUND
;    carry clear
;       CX         - word of data
;
; Destroys:  AX, BX, CX
;
;----------------------------------------------------------------------------

InBufferGetWord proc near
        call InBufferGetByte
        jc bad_word
        mov cl, al
        call InBufferGetByte
        jc bad_word
        mov ch, al
        ret
bad_word:
        ; AX contains the error msg
        stc
        ret
InBufferGetWord endp


;----------------------------------------------------------------------------
; Routine:  InBufferGetData
;----------------------------------------------------------------------------
; Description:
;    Read a group of data into a destination buffer
;    NOTE:  This routine assumes that there is enough data in the buffer!
;    NOTE:  This routine can be optimized if necessary
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Destination buffer
;    CX            - Number of bytes
;
; Destroys:  AX, BX, CX, DI
;
;----------------------------------------------------------------------------

InBufferGetData proc near
        ; Make sure a call with CX = 0 to zero gets no data
        test cx, 0xFFFF
        je get_data_done
get_data_loop:
        call InBufferGetByte
        stosb
        loop get_data_loop
get_data_done:
        ret
InBufferGetData endp


;----------------------------------------------------------------------------
; Routine:  InBufferSkipBytes
;----------------------------------------------------------------------------
; Description:
;    Skip a group of bytes
;    NOTE:  This routine assumes that there is enough data in the buffer!
;    NOTE:  This routine can be optimized if necessary
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    CX            - Number of bytes
;
; Destroys:  AX, BX, CX, DI
;
;----------------------------------------------------------------------------

InBufferSkipBytes proc near
        ; Make sure a call with CX = 0 to zero gets no data
        test cx, 0xFFFF
        je skip_data_done
skip_data_loop:
        call InBufferGetByte
        loop skip_data_loop
skip_data_done:
        ret
InBufferSkipBytes endp


;----------------------------------------------------------------------------
; Routine:  IStateReviewHeader
;----------------------------------------------------------------------------
; Description:
;    This routine reviews the header that should not be available.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX, CX
;
;----------------------------------------------------------------------------

IStateReviewHeader proc near
        ; Make sure this is a gif
        call InBufferGetByte
        cmp al, 'G'
        jne not_a_gif
        call InBufferGetByte
        cmp al, 'I'
        jne not_a_gif
        call InBufferGetByte
        cmp al, 'F'
        jne not_a_gif
        call InBufferGetByte
        cmp al, '8'
        jne not_a_gif
        call InBufferGetByte
        mov cl, GST_87A
        cmp al, '7'
        je looks_like_gif_so_far
        mov cl, GST_89A
        cmp al, '9'
        jne not_a_gif
looks_like_gif_so_far:
        call InBufferGetByte
        cmp al, 'a'
        je is_a_gif
not_a_gif:
        mov ax, IG_STATUS_ERROR_NOT_GIF
        ret


is_a_gif:
        ; Ok, the signature is correct.  Record the subtype
        mov [IGS_subType], cl

        ; Let's assume the rest of the header is good
        ; (This part is called the Logical Screen Descriptor, but
        ;  we've combined it with the header since it always is here)

        ; Get the width and height
        call InBufferGetWord
        mov [IGS_width], cx
        mov [IGS_xClip], cx
	cmp cx, 2048
	ja not_a_gif
        call InBufferGetWord
        mov [IGS_height], cx
	cmp cx, 2048
	ja not_a_gif
	mov ax, cx
	push dx
	mul [IGS_width]
	cmp dx, 16h
	pop dx
	jae not_a_gif
        call InBufferGetByte
        mov [IGS_gifInfo], al
        call InBufferGetByte
        mov [IGS_backColor], al

        ; Ignore the aspect ratio
        call InBufferGetByte

        ; How many pixels per color (and thus number colors) is this GIF?
        mov cl, [IGS_gifInfo]
        and cl, mask GIB_SIZE_GLOBAL_COLOR_TABLE
        inc cl
        mov [IGS_globalBitsPerPixel], cl
        mov ax, 1
        shl ax, cl
        mov [IGS_globalColorMapSize], ax

        ; Determine the color resolution (in powers of two bits)
        mov al, [IGS_gifInfo]
        and al, mask GIB_COLOR_RESOLUTION
        mov cl, offset GIB_COLOR_RESOLUTION
        shr al, cl
        inc al
        mov [IGS_globalColorBitResolution], al

        ; Are we to get a global palette?
        test [IGS_gifInfo], mask GIB_GLOBAL_COLOR_TABLE
        je no_global_table

        ; Next up is the global color table.
        ; Look for 3 times the size of the color map
        mov ax, offset IStateReviewGlobalColor
        mov bx, [IGS_globalColorMapSize]
        shl bx, 1
        add bx, [IGS_globalColorMapSize]
        jmp done_with_header

no_global_table:
        ; Next up might be extensions, otherwise we'll start the
        ; local image descriptor.
        ; Just looking for a single indicator
        mov ax, offset IStateReviewExtensionsStart
        mov bx, 1

        ; fall into done_with_header

done_with_header:
        ; Record the next state function
        mov [IGS_stateFunction], ax
        mov [IGS_bytesNeeded], bx

        ; Got here, so it must be good.
        mov ax, IG_STATUS_OK
        ret

        ; I don't know what this file is, its not a GIF
IStateReviewHeader endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewGlobalColor
;----------------------------------------------------------------------------
; Description:
;    Processes the global color table (by reading it in)
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX, CX, ES, DI
;
;----------------------------------------------------------------------------

IStateReviewGlobalColor proc near
        ; Enough data has been located for the global color map
        push ds
        pop es
        mov di, IGS_globalPalette
        mov cx, [IGS_bytesNeeded]
        call InBufferGetData

        ; Copy the global palette into the local palette (for now)
        mov cx, 768/2
        push si
        mov si, IGS_globalPalette
        mov di, IGS_palette
        rep movsw
        pop si

        ; Done with the global table.
        ; On to extensions
        mov ax, offset IStateReviewExtensionsStart
        mov [IGS_stateFunction], ax
        mov bx, 1
        mov [IGS_bytesNeeded], bx

        ; Still good to go
        mov ax, IG_STATUS_OK
        ret
IStateReviewGlobalColor endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewExtensionsStart
;----------------------------------------------------------------------------
; Description:
;    Looks to see if we should start with an extension or not.
;    If this is a GIF87a, we don't bother with extensions.  If this is a
;    GIF89a, we look for the introducer character then move on to
;    handling a standard extension.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateReviewExtensionsStart proc near
        ; Are we a GIF87a?  If so, we don't see an extension
; I've found GIFs that say they are older, but still have extensions.
; Well, since there is no harm in processing them, we'll go ahead and do
; it.
;        mov al, [IGS_subType]
;        cmp al, GST_87A
;        je no_extension

        call InBufferPeekByte
        cmp al, GIF_INTRODUCER_CHARACTER
        je extension_found
; no_extension:
        ; Well, no more extensions found.  Let's move on to
        ; figuring out what to do next.
        mov ax, offset IStateReviewNextMajorSection
        mov bx, 1
        jmp extension_done

extension_found:
        ; We have an extension!  Let's read the extension header
        ; and determine which one to process
        mov ax, offset IStateReviewExtensionHeader
        mov bx, size GIFExtensionHeader

extension_done:
        mov [IGS_stateFunction], ax
        mov [IGS_bytesNeeded], bx
        mov ax, IG_STATUS_OK
        ret
IStateReviewExtensionsStart endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewNextMajorSection
;----------------------------------------------------------------------------
; Description:
;    Determine if the next major section is a LocalDescriptor or the
;    Trailer.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateReviewNextMajorSection proc near
;        clr ax
;        mov [IGS_vmBlock], ax
        call InBufferPeekByte
        cmp al, LOCAL_IMAGE_SEPERATOR
        je found_local_image
        cmp al, GIF_TRAILER
        je found_trailer

        ; I don't know what we are doing here, but this is wrong.
        mov ax, IG_STATUS_ERROR
        ret

found_local_image:
        ; Let's move on to reviewing the local image
        mov ax, offset IStateReviewLocalImageDesc
        mov bx, size GIFLocalImageDesc
        jmp next_major_section_done

found_trailer:
        ; Pull in the trailer and report what we found
        call InBufferGetByte

        ; Go into the trailer state where it will stay forever.
        clr bx
        mov ax, offset IStateReviewTrailer
        jmp next_major_section_done

next_major_section_done:
        mov [IGS_bytesNeeded], bx
        mov [IGS_stateFunction], ax
        mov ax, IG_STATUS_OK
        ret
IStateReviewNextMajorSection endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewTrailer
;----------------------------------------------------------------------------
; Description:
;    Trailer was found.  Just stay here forever until destroyed
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateReviewTrailer proc near
        ; Just report this error forever.
        mov ax, IG_STATUS_FOUND_END_OF_GIF
        ret
IStateReviewTrailer endp


;----------------------------------------------------------------------------
; Routine:  IStateReviewLocalImageDesc
;----------------------------------------------------------------------------
; Description:
;    Process the Local Image Descriptor and get ready for doing an image.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX, CX, ES, SI, DI
;
;----------------------------------------------------------------------------

IStateReviewLocalImageDesc proc near
        ; We now have a local image descriptor in the input buffer.
        ; Let's process that.

        ; Read in the whole structure in one whallop
        mov cx, size GIFLocalImageDesc
        push ds
        pop es
        mov di, IGS_localImage
        call InBufferGetData

        ; Do we have a color table to consider?
        mov al, [IGS_localImage.GLID_info]
        test al, mask GLIB_LOCAL_COLOR_TABLE
        je no_color_table

        ; Yes, we have a color table.  Get the information for this table.
        ; How many colors?
        and al, mask GLIB_SIZE_LOCAL_COLOR_TABLE
        mov cl, offset GLIB_SIZE_LOCAL_COLOR_TABLE
        shr al, cl
        inc al
        mov [IGS_bitsPerPixel], al
        mov cl, al
        mov ax, 1
        shl ax, cl
        mov [IGS_colorMapSize], ax

        ; Get the next so many bytes (plus one) for the palette and first
        ; block
        mov bx, ax
        shl bx, 1
        add bx, ax
        mov ax, offset IStateReviewLocalColorTable
        jmp local_image_desc_done

no_color_table:
        ; No, we don't have a color table.

        ; Copy global color map into current palette
        push ds
        pop es
        ; Determine number of bytes to copy
        mov cx, [IGS_globalColorMapSize]
        mov [IGS_colorMapSize], cx
        shl cx, 1
        add cx, [IGS_globalColorMapSize]
        mov si, IGS_globalPalette
        mov di, IGS_palette
        test cx, 1
        je even_count_copy
        ; Copy first byte
        movsb
even_count_copy:
        shr cx, 1
        ; Copy the rest as words
        rep movsw

        ; Now copy the smaller information considering
        mov al, [IGS_globalBitsPerPixel]
        mov [IGS_bitsPerPixel], al

        mov bx, 1
        mov ax, offset IStatePrepareImage

local_image_desc_done:
        mov [IGS_stateFunction],ax
        mov [IGS_bytesNeeded], bx
        mov ax, IG_STATUS_OK
        ret
IStateReviewLocalImageDesc endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewLocalColorTable
;----------------------------------------------------------------------------
; Description:
;    Read in the local color table.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX, ES, CX, DI
;
;----------------------------------------------------------------------------

IStateReviewLocalColorTable proc near
        ; Read in all the data for the palette
        mov cx, [IGS_bytesNeeded]
        push ds
        pop es
        mov di, offset IGS_palette
        call InBufferGetData

        ; Done with all palette information for the next image.
        ; Let's start decompression this sucker.
        mov ax, 1
        mov [IGS_bytesNeeded], ax
        mov ax, offset IStatePrepareImage
        mov [IGS_stateFunction], ax
        mov ax, IG_STATUS_OK
        ret
IStateReviewLocalColorTable endp


;----------------------------------------------------------------------------
; Routine:  IDetermineFormat
;----------------------------------------------------------------------------
; Description:
;    Based on all the information in the given ImpGIFStruct, determine
;    what the best bitmap format should be used.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

G_bitsToFormat byte BMF_MONO,                                 ; 0 bits
                    BMF_MONO, BMF_4BIT, BMF_4BIT, BMF_4BIT,   ; 1 - 4 bits
                    BMF_8BIT, BMF_8BIT, BMF_8BIT, BMF_8BIT    ; 5 - 8 bits

IDetermineFormat proc near
        ; Get the number of pixels deep this image is.
        mov bl, [IGS_bitsPerPixel]
        clr bh

        ; Clear the inverted flag
        mov [IGS_inverted], bh

        ; Convert the number of bits into a GEOS standard bitmap format.
        mov bl, cs:G_bitsToFormat[bx]

        ; Is this monochrome?
        cmp bl, BMF_MONO
        jne determine_format_done

        ; If we are monochrome, see if we are black and white in the
        ; palette.
        mov ax, word ptr [IGS_palette]
        cmp ax, 0x0
        jne not_black_white
        mov ax, word ptr [IGS_palette+2]
        cmp ax, 0x00FF
        jne not_black_white
        mov ax, word ptr [IGS_palette+4]
        cmp ax, 0xFFFF
        ; If equal, this definitely is a black/white monochrome.
        ; Keep it like it is.
        je determine_format_done
not_black_white:
        ; Well, perhaps its white/black (inverted).
        mov ax, word ptr [IGS_palette]
        cmp ax, 0xFFFF
        jne not_white_black
        mov ax, word ptr [IGS_palette+2]
        cmp ax, 0xFF00
        jne not_white_black
        mov ax, word ptr [IGS_palette+4]
        cmp ax, 0
        jne not_white_black

        ; Well, it is white_black, which is inverted from what we
        ; usually get.  Ok, set the invert flag to 1.
        inc [IGS_inverted]
        jmp determine_format_done

not_white_black:
        ; At this point, we have a monochrome image, but they are
        ; not using the colors white and black.  This means
        ; that we are forced to use a fancier color scheme.  Let's
        ; just bump it up to a 4 bit image.
        mov bl, BMF_4BIT

        ; Fall into determine_format_done

determine_format_done:
        ; Are we transparent and need a mask?
        test [IGS_frameInfo], mask GIIB_TRANSPARENT
        je no_format_mask
        or bl, mask BMT_MASK

no_format_mask:
        ; Ok, that's pretty much it.  Store the sucker.
        mov [IGS_format], bl
        ret
IDetermineFormat endp


;----------------------------------------------------------------------------
; Routine:  IConstructPaletteRemapTable
;----------------------------------------------------------------------------
; Description:
;    Construct a map table that tells how pixel colors are mapped from
;    one color to another.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IConstructPaletteRemapTable proc near
        uses di, ax, bx, cx, dx, si
        .enter

        ; Start our pointers (offsets into DS)
        mov di, IGS_remapColors
        mov si, IGS_palette

        ; Do all colors (usually 256)
        mov cx, [IGS_colorMapSize]
construct_pal:
        push di
        mov al, [si]
        inc si
        mov bl, [si]
        inc si
        mov bh, [si]
        inc si
        ; Use a gstate (DI) of 0 for the default mappings.
        clr di
        call GrMapColorRGB
        pop di
        mov [di], ah
        inc di
        loop construct_pal

        .leave
        ret
IConstructPaletteRemapTable endp

;----------------------------------------------------------------------------
; Routine:  IAttachPalette
;----------------------------------------------------------------------------
; Description:
;    Put the current palette in the current bitmap
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IAttachPalette proc near
        uses ax, bx, cx, bp, es, si, di
        .enter
        test [IGS_useSystemPalette], 1
        je do_attach_pal
        call IConstructPaletteRemapTable
        jmp attach_done
do_attach_pal:
        mov bx, [IGS_vmFile]
        mov ax, [IGS_vmBlock]
        call VMLock
        or ax, ax
        je could_not_attach_palette
        mov es, ax

        ; Determine where the palette is
        mov di, word ptr es:[0x28]
        add di, 0x1c
        mov si, IGS_palette
        mov cx, [IGS_colorMapSize]
        shl cx, 1
        add cx, [IGS_colorMapSize]

        ; Copy over the palette
        rep movsb

        ; Release the header
        call VMDirty
        call VMUnlock
could_not_attach_palette:
attach_done:
        .leave
        ret

IAttachPalette endp

;----------------------------------------------------------------------------
; Routine:  AllocWatcherAllocateAsm
;----------------------------------------------------------------------------
; Description:
;    Determine the size of the bitmap and then calculate how much memory
;    that is.  Then try getting that from the alloc watcher
;
; Inputs:
;    BX            - AllocWatcher Handle
;    DX:AX         - Size to try allocating
;
; Outputs:
;    carry         - set if not enough space, clear if ok.
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

AllocWatcherAllocateAsm proc near
        uses ds, ax, bx, dx, cx
        .enter

        push ax

        ; Grab the block
        call MemPLock
        mov ds, ax
        pop ax

        mov cx, word ptr [0]
        sub cx, ax
        mov ax, cx

        mov cx, word ptr [2]
        sbb cx, dx
        mov dx, cx

        ; Jump if we have a carry (enough room)
        jnc alloc_enough_avail

        ; Not enough space!
        ; Return a bad status
        stc
        jmp alloc_done

alloc_enough_avail:
        mov word ptr [0], ax
        mov word ptr [2], dx
        clc
        jmp alloc_done

alloc_done:
        pushf
        call MemUnlockV
        popf
        .leave
        ret
AllocWatcherAllocateAsm endp

;----------------------------------------------------------------------------
; Routine:  ITryToAllocate
;----------------------------------------------------------------------------
; Description:
;    Determine the size of the bitmap and then calculate how much memory
;    that is.  Then try getting that from the alloc watcher
;    NOTE:  The bigger width and height between local image and field are
;           user *per* frame.  This is to ensure that if all frames are
;           rendered individually, there is enough space.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry         - set if not enough space, clear if ok.
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

ITryToAllocate proc near
        mov al, [IGS_format]
        mov bx, [IGS_localImage.GLID_width]
        and al, not mask BMT_MASK
        cmp al, BMF_MONO
        jne not_mono
        add bx, 7
        mov cl, 3
        jmp calc_bytes
not_mono:
        cmp al, BMF_4BIT
        jne not_16
        add bx, 3
        mov cl, 1
        jmp calc_bytes
not_16:
        ; Assume 256 now
        mov cl, 0

        ; Fall into calc_bytes

calc_bytes:
        ; Calculate the number of bytes for the pixel data
        shr bx, cl

        ; Do we need to do transparent?
        test [IGS_format], mask BMT_MASK
        je not_transparent

        ; Yep, need to calculate in the mask cost
        mov ax, [IGS_localImage.GLID_width]
        cmp ax, [IGS_width]
        jge local_is_wider
        mov ax, [IGS_width]
local_is_wider:
        add ax, 7
        shr ax, 1
        shr ax, 1
        shr ax, 1
        add bx, ax
not_transparent:
        ; At this point, bx contains the number of bytes per line
        ; Need to mulitple by the number of Y lines.
        mov ax, [IGS_localImage.GLID_height]
        cmp ax, [IGS_height]
        jge local_is_taller
        mov ax, [IGS_height]
local_is_taller:
        mul bx

        ; Now the complete size is in dx:ax
        movdw [IGS_memoryUsed], dxax

        ; Check to see if we have enough memory to do the transaction
        ; (if we are told to watch for that).
        mov bx, [IGS_allocWatcher]
        or bx, bx
        je no_alloc_watcher
        call AllocWatcherAllocateAsm
no_alloc_watcher:

        ret
ITryToAllocate endp


;----------------------------------------------------------------------------
; Routine:  IStatePrepareImage
;----------------------------------------------------------------------------
; Description:
;    We are just about ready to start decompressing an image.  We have
;    the color tables setup.  Prepare anything and everything for this
;    next image.
;
;    However, we do have one byte ready to tell how big the next block
;    of compressed data is.  This will be used to prime the system.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStatePrepareImage proc near
        ; We are now ready to create the image and get things going
        ; What format is this image?  (put in IGS_format)
        call IDetermineFormat

        ; Make sure we have enough memory for this bitmap before
        ; creating it through the fake memory allocation limitation
        ; routines.
        call ITryToAllocate
        LONG jc could_not_create_bitmap

        ; Don't use the system palette by default
        and [IGS_useSystemPalette], 0

        ; Only 256 color maps get remapped
;        mov ax, [IGS_colorMapSize]
;        cmp ax, 256
        mov al, [IGS_format]
        and al, not mask BMT_MASK
        cmp al, BMF_8BIT
        jne cant_use_sys_pal

        ; Use the system palette if we are told to use it
        mov al, [IGS_wantSystemPalette]
        or [IGS_useSystemPalette], al
cant_use_sys_pal:
        ; Create a new complex bitmap
        ; For now we will always add a palette ???
        mov al, [IGS_format]
        mov bl, al
        and bl, not mask BMT_MASK
        cmp bl, BMF_MONO
        je prepare_image_with_sys_pal
        test [IGS_useSystemPalette], 1
        jne prepare_image_with_sys_pal
        or al, mask BMT_PALETTE or mask BMT_COMPLEX
        jmp prepare_image_continue
prepare_image_with_sys_pal:
        ; If system palette, just a huge bitmap
  or [IGS_useSystemPalette], 1
        or al, mask BMT_HUGE
prepare_image_continue:
        mov bx, [IGS_vmFile]
        mov cx, [IGS_localImage.GLID_width]
        mov dx, [IGS_localImage.GLID_height]
        call GrCreateBitmapRaw
        mov [IGS_vmBlock], ax
        or ax, ax
        je could_not_create_bitmap

        ; Put a palette on the bitmap (or create a remap table)
        call IAttachPalette

        ; Clear the y position, count, and pass count
        clr ax
        mov [IGS_yPos], ax
        mov [IGS_rasterPass], al
        mov [IGS_yCount], ax

        ; Compute the x clip point. This is only done once for the first
        ; image, if the clip was not already set by the field.
        mov ax, [IGS_xClip]
        or ax, ax
        jnz clip_is_set
        mov ax, [IGS_localImage.GLID_width]
        sub ax, [IGS_localImage.GLID_x]
        mov [IGS_xClip], ax

        ; Bring in the first raster
clip_is_set:
        call IRasterLock

        ; Prepare the line output state information
        call IResetOutput

        ; ??? Prepare uncompress tables here!

        ; We are now ready to uncompress the image.
        mov ax, offset IStateUncompressStart
        mov [IGS_stateFunction], ax
        mov ax, 2
        mov [IGS_bytesNeeded], ax
        mov ax, IG_STATUS_OK
        ret
could_not_create_bitmap:
        mov ax, IG_STATUS_COULD_NOT_CREATE
        ret
IStatePrepareImage endp


;----------------------------------------------------------------------------
; Routine:  IStateReviewExtensionHeader
;----------------------------------------------------------------------------
; Description:
;    Determine what extension header is being processed and have another
;    one handle it.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateReviewExtensionHeader proc near
        ; Skip the introducer
        call InBufferGetByte
        ; Get the label character
        call InBufferGetByte
        push ax
        ; Get the number of remaining bytes in this header
        call InBufferGetByte
        clr ah

        ; Add one because we want to grab the terminator too (or the
        ; the beginning count of the next data block).
        inc ax
        mov [IGS_bytesNeeded], ax
        pop ax

        ; What type of extension do we have?
        cmp al, GIF_EXTENSION_GRAPHICS_CONTROL
        je graphics_control_found

        cmp al, GIF_EXTENSION_APPLICATION
        je application_control_found

        ; Its some extension we don't care about it.  We'll have to
        ; go through the skip logic to make this work.
        mov ax, offset IStateReviewSkipExtensionData
        jmp ext_header_done

;;
;; FEATURE NOTE:  If you want to add support for new types of extensions,
;;                you can do it here just by doing a compare for the label
;;                and then jumping to anther IStateReview... function.
;;                -- LES 98/08/05
;;
application_control_found:
        mov ax, offset IStateReviewApplicationControl
        jmp ext_header_done

graphics_control_found:
        ; We have a graphics control header.  Let's process that sucker.
        mov ax, offset IStateReviewGraphicsControl

        ; Fall through to ext_header_done

ext_header_done:
        mov [IGS_stateFunction], ax
        mov ax, IG_STATUS_OK
        ret

IStateReviewExtensionHeader endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewGraphicsControl
;----------------------------------------------------------------------------
; Description:
;    Found a Graphics control extension.  Let's process it.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateReviewGraphicsControl proc near
        push cx
        ; Get the GIFDisposalMethod
        call InBufferGetByte
        mov [IGS_frameInfo], al
        call InBufferGetWord
        mov [IGS_delayTime], cx
        call InBufferGetByte
        mov [IGS_transparentColor], al

        ; Skip the terminator
        call InBufferGetByte

        ; We are done with this extension.  It is time to look for yet
        ; another extension -- or at least one more byte.
        mov bx, offset IStateReviewExtensionsStart
        mov [IGS_stateFunction], bx
        mov ax, 1
        mov [IGS_bytesNeeded], ax

        mov ax, IG_STATUS_OK
        pop cx
        ret
IStateReviewGraphicsControl endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewApplicationControl
;----------------------------------------------------------------------------
; Description:
;    Found an Application control extension.  Let's process it.
;    This version only looks for "NETSCAPE2.0" extensions to get the
;    number of loops.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateReviewApplicationControl proc near
        push cx
        mov cx, [IGS_bytesNeeded]
        cmp cx, 12
        jne not_good

        call InBufferGetByte
        dec cx
        cmp al, 'N'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, 'E'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, 'T'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, 'S'
        je still_good
not_good:
        jmp not_netscape_control

still_good:
        call InBufferGetByte
        dec cx
        cmp al, 'C'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, 'A'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, 'P'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, 'E'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, '2'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, '.'
        jne not_netscape_control
        call InBufferGetByte
        dec cx
        cmp al, '0'
        jne not_netscape_control
        call InBufferGetByte

        ; Finally!  We now have the number of bytes following this tag
        clr ah
        inc ax
        mov [IGS_bytesNeeded], ax
        mov bx, offset IStateGrabLoopCount
        jmp app_control_done

not_netscape_control:
        mov [IGS_bytesNeeded], cx
        mov bx, offset IStateReviewSkipExtensionData
        ; Fall into app_control_done
app_control_done:
        mov [IGS_stateFunction], bx
        mov ax, IG_STATUS_OK
        pop cx
        ret
IStateReviewApplicationControl endp

IStateGrabLoopCount proc near
        push cx
        call InBufferGetByte
        call InBufferGetWord
        mov [IGS_loopCount], cx
        call InBufferGetByte

        ; Skip any remaining data
        mov cx, [IGS_bytesNeeded]
        sub cx, 4
        call InBufferSkipBytes

        ; Lets move on now
        mov ax, 1
        mov [IGS_bytesNeeded], ax
        mov ax, offset IStateReviewExtensionsStart
        mov [IGS_stateFunction], ax
        mov ax, IG_STATUS_OK
        pop cx
        ret
IStateGrabLoopCount endp

;----------------------------------------------------------------------------
; Routine:  IStateReviewSkipExtensionData
;----------------------------------------------------------------------------
; Description:
;    There are more extensions here than I care.  Skip them.
;    NOTE:  At this point, there is enough data.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateReviewSkipExtensionData proc near
        ; First skip the remaining bytes waiting except for the last
        ; byte which tells if there is more to come.
        mov cx, [IGS_bytesNeeded]
        dec cx
        call InBufferSkipBytes

        ; Get the count of bytes to follow (or a terminator if zero)
;        call InBufferGetByte
;some GIFs have LOCAL_IMAGE_SEPERATOR right here (better not be a skip of
;LOCAL_IMAGE_SEPEATOR bytes!)
	call InBufferPeekByte
	cmp al, LOCAL_IMAGE_SEPERATOR
	je end_extension
; other GIFs have no terminator and have another GIF_INTRODUCER_CHARACTER
; here
	cmp al, GIF_INTRODUCER_CHARACTER
	je end_extension
	call InBufferGetByte
        test al, 0xFF
        je terminator_found

        ; Not zero, must be another block we need to skip
        clr ah
        inc ax

        ; Same state.  Do it again.  AX is the number of bytes to skip
        ; plus one for the following block count or terminator.
        jmp skip_ext_done

terminator_found:
        ; We are done with this extension.  It is time to look for yet
        ; another extension -- or at least one more byte.
end_extension:
        mov bx, offset IStateReviewExtensionsStart
        mov [IGS_stateFunction], bx
        mov ax, 1

skip_ext_done:
        mov [IGS_bytesNeeded], ax

        ; Keep going
        mov ax, IG_STATUS_OK
        ret
IStateReviewSkipExtensionData endp

;----------------------------------------------------------------------------
; Routine:  IRasterLock
;----------------------------------------------------------------------------
; Description:
;    Lock the currently being worked on raster
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry         - clear if ok, set if not locked
;
; Destroys:        AX, BX, CX, DX, DI
;
;----------------------------------------------------------------------------

IRasterLock proc near
          ; Don't lock if we don't have a bitmap block yet
          mov di, [IGS_vmBlock]
          or di, di
          je raster_lock_failed

          ; Lock in a the bitmap's raster at the current Y position
          mov bx, [IGS_vmFile]
          clr dx
          mov ax, [IGS_yPos]
          cmp ax, [IGS_localImage.GLID_height]
          jge raster_lock_failed

          push ds
          call HugeArrayLock

          ; Did we get the raster?
          or ax, ax
          je raster_lock_failed_pop_ds

          ; ??? Do we want to store the raster size for comparison?

          mov ax, ds
          pop ds
          mov [IGS_rasterSegment], ax
          mov [IGS_rasterOffset], si

          ; All done.  Report a good status
          clc
          ret

raster_lock_failed_pop_ds:
          pop ds
raster_lock_failed:
          clr ax
          mov [IGS_rasterSegment], ax
          mov [IGS_rasterOffset], ax
          stc
          ret
IRasterLock endp

;----------------------------------------------------------------------------
; Routine:  IRasterUnlock
;----------------------------------------------------------------------------
; Description:
;    Unlock the current raster (if any)
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry         - clear if ok, set if not locked
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IRasterUnlock proc near
        push ax
        ; Do we have a raster locked?
        mov ax, [IGS_rasterSegment]
        or ax, ax
        je no_raster_to_unlock

        ; Unlock the current raster
        push ds
        mov ds, ax

        ; If it was locked, it was changed and thus made dirty
        call HugeArrayDirty

        call HugeArrayUnlock
        pop ds

        ; Clear the pointer
        clr ax
        mov [IGS_rasterSegment], ax
        mov [IGS_rasterOffset], ax

no_raster_to_unlock:
        pop ax
        ret
IRasterUnlock endp


;----------------------------------------------------------------------------
; Routine:  IResetLine1Bit
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing a monochrome output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        AX
;
;----------------------------------------------------------------------------
IResetLine1Bit proc near
        mov al, 0x80
        mov [IGS_outputPixelMask], al
        mov ax, [IGS_outputPixelPosStart]
        mov [IGS_outputPixelPos], ax
        clr ax
        mov [IGS_xPos], ax
        ret
IResetLine1Bit endp


;----------------------------------------------------------------------------
; Routine:  IResetLine4Bit
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing a 4 bit output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        AX
;
;----------------------------------------------------------------------------
IResetLine4Bit proc near
        mov al, 4
        mov [IGS_outputPixelMaskOffset], al
        mov ax, [IGS_outputPixelPosStart]
        mov [IGS_outputPixelPos], ax
        clr ax
        mov [IGS_xPos], ax
        mov [IGS_outputPixelByte], al
        ret
IResetLine4Bit endp


;----------------------------------------------------------------------------
; Routine:  IResetLine8Bit
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing an 8 bit output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        AX
;
;----------------------------------------------------------------------------
IResetLine8Bit proc near
        mov ax, [IGS_outputPixelPosStart]
        mov [IGS_outputPixelPos], ax
        clr ax
        mov [IGS_xPos], ax
        ret
IResetLine8Bit endp


;----------------------------------------------------------------------------
; Routine:  IResetOutputMask
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for transparency masking.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        AX
;
;----------------------------------------------------------------------------
IResetOutputMask proc near
        mov al, 0x80
        mov [IGS_outputMask], al
        clr ax
        mov [IGS_outputMaskPos], ax
        mov [IGS_outputMaskByte], al
        ret
IResetOutputMask endp


;----------------------------------------------------------------------------
; Routine:  IOutput1Bit
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing a monochrome output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;    AL            - Color to output
;
; Destroys:        AX, CL
;
;----------------------------------------------------------------------------
IOutput1Bit proc near
        xor al, [IGS_inverted]
        test al, 1
        jne just_shift_over

        ; Set the bit since we have a non-even numbered color
        mov al, [IGS_outputPixelMask]
        or [IGS_outputPixelByte], al

just_shift_over:
        shr [IGS_outputPixelMask], 1
        jnc output_bit_done

        ; Carry got set, must be the end of a byte
        ; Rotate the carry back to the top.
        rcr [IGS_outputPixelMask], 1

        ; Output the byte and clear it
        mov al, [IGS_outputPixelByte]
        call IOutput8Bit
        clr al
        mov [IGS_outputPixelByte], al
output_bit_done:
        ret
IOutput1Bit endp


;----------------------------------------------------------------------------
; Routine:  IOutput4Bit
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing a 4 bit output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;    AL            - Color to output
;
; Destroys:        AX, CL
;
;----------------------------------------------------------------------------
IOutput4Bit proc near
        and al, 0x0F
        mov cl, [IGS_outputPixelMaskOffset]
        shl al, cl
        or [IGS_outputPixelByte], al

        ; Toggle between shifting left 4 bits and 0 bits
        xor cl, 4
        mov [IGS_outputPixelMaskOffset], cl

        ; If we just became nonzero, then we are ready to output the byte
        ; Otherwise, not and don't output
        jz no_4bit_output

        ; Output the value the byte
        mov al, [IGS_outputPixelByte]
        call IOutput8Bit

        ; reset 4 bit
        clr al
        mov [IGS_outputPixelByte], al
no_4bit_output:
        ret
IOutput4Bit endp


;----------------------------------------------------------------------------
; Routine:  IOutput8Bit
;----------------------------------------------------------------------------
; Description:
;    Outputing 8 bits is just adding a byte to the output pixel position.
;    In fact, this routine is used by all the pixel output routines
;    (but not transparency mask).
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;    AL            - Color to output
;
; Destroys:        AX, DI
;
;----------------------------------------------------------------------------
IOutput8Bit proc near
        ; Just output the byte to the end.
        add di, [IGS_outputPixelPos]
        stosb
        inc [IGS_outputPixelPos]

        ret
IOutput8Bit endp


;----------------------------------------------------------------------------
; Routine:  IOutputPixel
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing an 8 bit output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    AL            - Color to output
;
; Outputs:
;    carry         - clear if more to output, set if image filled
;
; Destroys:        AX, ES, DI
;
;----------------------------------------------------------------------------

rasterIncrementsPerPass          word  8, 8, 4, 2, 0
rasterStartsPerPass              byte  0, 4, 2, 1, 0

IOutputPixel proc near
        uses cx
        .enter
EC <    test [IGS_rasterSegment], 0xFFFF >
EC <    jne pixel_raster_is_locked       >
EC <    mov ax, 0xFFFF                   >
EC <    call FatalError                  >
EC < pixel_raster_is_locked:             >

        ; Get the address of the current raster
        mov es, [IGS_rasterSegment]
        mov di, [IGS_rasterOffset]

        ; Do any transparency output
        call [IGS_outputTransparentFunction]

        test [IGS_useSystemPalette], 1
        je output_pixel_without_pal_convert

        ; Remap the color to a new color
        push bx
        clr ah
        mov bx, ax
        mov al, IGS_remapColors[bx]
        pop bx

output_pixel_without_pal_convert:
        ; Do the pixel output
        push cx
        mov cx, [IGS_xPos]
        cmp cx, [IGS_xClip]
        jge dont_output_pixel
        call [IGS_outputPixelFunction]
dont_output_pixel:
        pop cx

        ; Update our X position.
        inc [IGS_xPos]

        ; Are we at the right?
        mov ax, [IGS_xPos]
        cmp ax, [IGS_localImage.GLID_width]
        jl raster_not_done_yet

        ; Yep, we're done all right.

        ; Flush the current raster
        mov es, [IGS_rasterSegment]
        mov di, [IGS_rasterOffset]

        call IFlushOutputMask
        call [IGS_outputFlushLineFunction]

        ; Reset the line information
        call IResetOutputMask
        call [IGS_outputResetLineFunction]

        ; Now let's move to the next line

        ; Is this interlaced?
        mov al, [IGS_localImage.GLID_info]
        test al, mask GLIB_INTERLACE
        je not_interlaced

        mov al, [IGS_rasterPass]
        clr ah
        shl ax, 1
        mov di, ax
        mov ax, cs:[rasterIncrementsPerPass+di]
        add ax, [IGS_yPos]
check_y_again:
        mov [IGS_yPos], ax
        cmp ax, [IGS_localImage.GLID_height]
        jl output_pixel_continue

        ; Past the end.  Need to go to the next raster pass and
        ; start on the right y position
        inc [IGS_rasterPass]
        mov al, [IGS_rasterPass]
        clr ah
        mov di, ax
        mov al, cs:[rasterStartsPerPass+di]
        mov [IGS_yPos], ax

        ; Better check if this y is good.  Small images
        ; can be interlaced but not be handled correctly.
        jmp check_y_again

not_interlaced:
        inc [IGS_yPos]

        ; Fall through to output_pixel_continue

output_pixel_continue:
        inc [IGS_yCount]
        mov ax, [IGS_yCount]
        cmp ax, [IGS_localImage.GLID_height]
        jl still_more_rasters
        stc
        jmp output_pixel_done

still_more_rasters:
        ; Move to the new raster
        call IRasterUnlock
        call IRasterLock

raster_not_done_yet:
        clc

output_pixel_done:
        .leave
        ret

IOutputPixel endp

;----------------------------------------------------------------------------
; Routine:  IOutputNotTransparent
;----------------------------------------------------------------------------
; Description:
;    Doing operations for something not transparent does nothing.
;    Do nothing.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;    AL            - Color (8 bit or less)
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IOutputNotTransparent proc near
        ret
IOutputNotTransparent endp


;----------------------------------------------------------------------------
; Routine:  IOutputTransparent
;----------------------------------------------------------------------------
; Description:
;    Passed color may be transparent.  Checks and updates next bit in
;    transparency mask
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Raster in memory
;    AL            - Color (8 bit or less)
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IOutputTransparent proc near
        push ax
        ; Are we transparent or not?
        cmp al, [IGS_transparentColor]
        ; We are the transparent color, store a 0 by skipping
        je next_output_mask_bit

        ; We are the transparent color, store a 1
        mov al, [IGS_outputMask]
        or [IGS_outputMaskByte], al

        ; Now let's rotate to the next bit

next_output_mask_bit:
        shr [IGS_outputMask], 1
        ; If mask bit doesn't fall off end, we are still in the same byte.
        jnc output_mask_bit_done

        ; Reset the mask bit by rotating the carry back to the top
        rcr [IGS_outputMask], 1

        ; Now store the mask data byte
        push di
        add di, [IGS_outputMaskPos]
        mov al, [IGS_outputMaskByte]
        stosb
        pop di

        ; Next position in the mask data
        inc [IGS_outputMaskPos]

        ; Clear the mask byte
        clr al
        mov [IGS_outputMaskByte], al

output_mask_bit_done:
        pop ax
        ret
IOutputTransparent endp


;----------------------------------------------------------------------------
; Routine:  IFlushOutputMask
;----------------------------------------------------------------------------
; Description:
;    Flush any remaining mask data waiting to go out (if any)
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;
; Destroys:        AX
;
;----------------------------------------------------------------------------
IFlushOutputMask proc near
        ; If mask at the top, nothing to flush
        test [IGS_outputMask], 0x80
        jne no_mask_to_flush

        ; Now store the mask data byte
        push di
        add di, [IGS_outputMaskPos]
        mov al, [IGS_outputMaskByte]
        stosb
        pop di

        ; Clear the mask byte
        clr al
        mov [IGS_outputMaskByte], al
no_mask_to_flush:
        ret
IFlushOutputMask endp


;----------------------------------------------------------------------------
; Routine:  IFlush1Bit
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing a monochrome output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;
; Destroys:        AX, DI
;
;----------------------------------------------------------------------------
IFlush1Bit proc near
        ; If mask is at top, there is nothing to flush
        test [IGS_outputPixelMask], 0x80
        jnz flush_1bit_done

        ; Ok, flush the remaining byte
        mov al, [IGS_outputPixelByte]
        jmp IOutput8Bit
flush_1bit_done:
        ret
IFlush1Bit endp


;----------------------------------------------------------------------------
; Routine:  IFlush4Bit
;----------------------------------------------------------------------------
; Description:
;    Reset the logic for doing a 4 bit output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;
; Destroys:        AX, DI
;
;----------------------------------------------------------------------------
IFlush4Bit proc near
        ; Are we shifting 4 or 0?  If shifting 4, we have no data to flush.
        test [IGS_outputPixelMaskOffset], 4
        jnz no_4bit_flush
        mov al, [IGS_outputPixelByte]
        jmp IOutput8Bit
no_4bit_flush:
        ret
IFlush4Bit endp


;----------------------------------------------------------------------------
; Routine:  IFlush8Bit
;----------------------------------------------------------------------------
; Description:
;    Flush the 8 bit output.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    ES:DI         - Pointer to raster line
;
; Destroys:        AX
;
;----------------------------------------------------------------------------
IFlush8Bit proc near
        ; Nope, nothing to flush
        ret
IFlush8Bit endp


;----------------------------------------------------------------------------
; Routine:  IResetOutput
;----------------------------------------------------------------------------
; Description:
;    Set up the function pointers and reset the settings for doing output
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        AX, BX, CX, DX
;
;----------------------------------------------------------------------------
IResetOutput proc near
        ; Start by assuming we are NOT transparent
        clr bx
        mov cx, offset IOutputNotTransparent

        ; Are we transparent?
        mov al, [IGS_format]
        test al, mask BMT_MASK
        je not_trans

        ; This is a transparent image.
        mov cx, offset IOutputTransparent

        ; Calculate how much space before the start of the first pixel.
        mov bx, [IGS_localImage.GLID_width]
        add bx, 7
        shr bx, 1
        shr bx, 1
        shr bx, 1

not_trans:
        ; Record which transparency output routine to use
        mov [IGS_outputTransparentFunction], cx

        ; At this point, we also know what the start position for
        ; the pixels is.
        mov [IGS_outputPixelPosStart], bx

        ; Now that we have the transparency figured out, let's
        ; work out the details for the actual pixels.
        ; We want to have a special routine to output each so we
        ; don't have to figure it out per pixel (for speed).
        ; We also want to have a quick reset routine for also a slight
        ; bit more of speed (and perhaps organization).

        ; BX will be the reset routine
        ; CX will be the output routine

        and al, not mask BMT_MASK
        cmp al, BMF_MONO
        jne reset_output_not_mono
        mov bx, offset IResetLine1Bit
        mov cx, offset IOutput1Bit
        mov dx, offset IFlush1Bit
        jmp reset_output_done
reset_output_not_mono:
        cmp al, BMF_4BIT
        jne reset_output_not_4bit
        mov bx, offset IResetLine4Bit
        mov cx, offset IOutput4Bit
        mov dx, offset IFlush4Bit
        jmp reset_output_done
reset_output_not_4bit:
        cmp al, BMF_8BIT
        jne reset_output_not_8bit
        mov bx, offset IResetLine8Bit
        mov cx, offset IOutput8Bit
        mov dx, offset IFlush8Bit
        jmp reset_output_done
reset_output_not_8bit:
        ; What is this?  Can't be legal.
        mov ax, 0xFFFF
        call FatalError
        ret
reset_output_done:
        ; Record the two routines
        mov [IGS_outputResetLineFunction], bx
        mov [IGS_outputPixelFunction], cx
        mov [IGS_outputFlushLineFunction], dx

        ; Before leaving, let's reset the line based on the above.
        call IResetOutputMask
        call [IGS_outputResetLineFunction]
        ret
IResetOutput endp


;----------------------------------------------------------------------------
; Routine:  IDictionaryLock
;----------------------------------------------------------------------------
; Description:
;    Lock the dictionary and pattern
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------
IDictionaryLock proc near
        ; Lock the dictionary
        clr ax
        mov bx, [IGS_dictionaryHandle]
        or bx, bx
        je dict_lock_failed
        call MemLock
dict_lock_failed:
        mov [IGS_dictionarySegment], ax

        ; Lock the pattern
        clr ax
        mov bx, [IGS_patternHandle]
        or bx, bx
        je pattern_lock_failed
        call MemLock
pattern_lock_failed:
        mov [IGS_patternSegment], ax

        ret
IDictionaryLock endp

;----------------------------------------------------------------------------
; Routine:  IDictionaryUnlock
;----------------------------------------------------------------------------
; Description:
;    Unlock the dictionary and pattern
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        BX
;
;----------------------------------------------------------------------------
IDictionaryUnlock proc near
        ; Unlock the dictionary
        mov bx, [IGS_dictionaryHandle]
        or bx, bx
        je no_dict_to_unlock
        call MemUnlock
no_dict_to_unlock:

        ; Unlock the pattern buffer
        mov bx, [IGS_patternHandle]
        or bx, bx
        je no_pattern_to_unlock
        call MemUnlock
no_pattern_to_unlock:

        clr bx
        mov [IGS_dictionarySegment], bx
        mov [IGS_patternSegment], bx
        ret
IDictionaryUnlock endp

;----------------------------------------------------------------------------
; Routine:  IDictionaryCreate
;----------------------------------------------------------------------------
; Description:
;    Create the memory for the dictionary
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry         - clear if ok, else set
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------
IDictionaryCreate proc near
        ; Allocate room for the dictionary
        mov ax, size ImpGIFDictionaryEntry * MAX_SIZE_DICTIONARY
        mov cl, mask HF_SWAPABLE or mask HF_SHARABLE
        clr ch
        call MemAlloc
        jc bad_dict_alloc
        mov [IGS_dictionaryHandle], bx

        mov ax, MAX_SIZE_UNCOMPRESS_PATTERN
        mov cl, mask HF_SWAPABLE or mask HF_SHARABLE
        clr ch
        call MemAlloc
        jc bad_dict_alloc
        mov [IGS_patternHandle], bx

bad_dict_alloc:
        ret
IDictionaryCreate endp


;----------------------------------------------------------------------------
; Routine:  IDictionaryDestroy
;----------------------------------------------------------------------------
; Description:
;    Destroy the dictionary memory
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry         - clear if ok, else set
;
; Destroys:        BX
;
;----------------------------------------------------------------------------
IDictionaryDestroy proc near
        ; Throw away the dictionary (if any)
        mov bx, [IGS_dictionaryHandle]
        or bx, bx
        je no_dict_to_destroy
        call MemFree

no_dict_to_destroy:
        ; Free the pattern block (if any)
        mov bx, [IGS_patternHandle]
        or bx, bx
        je no_pattern_to_destroy
        call MemFree

no_pattern_to_destroy:
        ; Throw away the handles
        clr ax
        mov [IGS_dictionaryHandle], ax
        mov [IGS_patternHandle], ax
        ret
IDictionaryDestroy endp


;----------------------------------------------------------------------------
; Routine:  IDictionaryInitialize
;----------------------------------------------------------------------------
; Description:
;    Initialize the dictionary with the normal data.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IDictionaryInitialize proc near
        push es
        push di
        push cx
        push ax

        ; Determine the number of initial table entries
        ; and special codes
        mov cl, [IGS_codeSize]
        mov [IGS_initCodeSize], cl
        mov ax, 1
        shl ax, cl
        mov [IGS_codeClear], ax
        inc ax
        mov [IGS_codeEOF], ax
        inc ax
        mov [IGS_codeFirstFree], ax
        mov [IGS_codeFree], ax
        mov al, [IGS_codeSize]
        inc al
        mov [IGS_codeSize], al
        mov [IGS_initCodeSize], al

        ; Determine the next major code (bit size change)
        mov ax, [IGS_codeClear]
        shl ax, 1
        mov [IGS_codeMax], ax

        ; Set up the mask for reading in codes
        mov cl, [IGS_codeSize]
        mov ax, 1
        shl ax, cl
        dec ax
        mov [IGS_codeMask], ax

        ; Clear the bit count and the incoming bit buffer (all of 2 bytes)
        clr ax
        mov [IGS_codeBufferBits], al
        mov [IGS_codeBuffer], ax

        ; Now setup the main table info
        call IDictionaryClear

        mov cx, [IGS_codeClear]

        ; Clear the dictionary lower entries
        mov es, [IGS_dictionarySegment]
        clr di

        mov bx, 0x8000          ; High bit set means end of pattern
        clr al

        ; Loop through all the entries that are known now and setup
        ; the first character (suffix) and the offset to the prefix
        ; (which is always zero for a terminator pattern entry).
clear_dict_entry:
        ; Store the suffix first
        stosb

        inc al

        ; Store the prefix next (always zero at)
        mov es:[di], bx
        add di, 2
        loop clear_dict_entry

        ; Clear old junk out (safety measure)
        xor ax, ax
        mov [IGS_codeOld], ax
        mov [IGS_charFin], al

        pop ax
        pop cx
        pop di
        pop es
        ret
IDictionaryInitialize endp


;----------------------------------------------------------------------------
; Routine:  IDictionaryClear
;----------------------------------------------------------------------------
; Description:
;    Initialize the dictionary with the normal data.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IDictionaryClear proc near
        uses ax, bx, cx
        .enter

        ; Clear all the other registers
;        mov al, [IGS_initCodeSize]
;        mov [IGS_codeSize], al
;        mov ax, [IGS_codeClear]
;        shl ax, 1
;        mov [IGS_codeMax], ax
;        mov ax, [IGS_codeFirstFree]
;        mov [IGS_codeFree], ax

        ; Determine the number of initial table entries
        ; and special codes
        mov al, [IGS_initCodeSize]
        dec al
        mov [IGS_codeSize], al

        mov cl, [IGS_codeSize]
        mov [IGS_initCodeSize], cl
        mov ax, 1
        shl ax, cl
        mov [IGS_codeClear], ax
        inc ax
        mov [IGS_codeEOF], ax
        inc ax
        mov [IGS_codeFirstFree], ax
        mov [IGS_codeFree], ax
        mov al, [IGS_codeSize]
        inc al
        mov [IGS_codeSize], al
        mov [IGS_initCodeSize], al

        ; Determine the next major code (bit size change)
        mov ax, [IGS_codeClear]
        shl ax, 1
        mov [IGS_codeMax], ax

        ; Set up the mask for reading in codes
        mov cl, [IGS_codeSize]
        mov ax, 1
        shl ax, cl
        dec ax
        mov [IGS_codeMask], ax

        ; Note that we are the first code to come in.
        clr al
        mov [IGS_isFirstCode], al

        .leave
        ret
IDictionaryClear endp

;----------------------------------------------------------------------------
; Routine:  IStateUncompressStart
;----------------------------------------------------------------------------
; Description:
;    Start up the uncompression engine.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX
;
;----------------------------------------------------------------------------

IStateUncompressStart proc near
        ; Get the first code size
        call InBufferGetByte
        mov [IGS_codeSize], al

        ; Get the first byte of the block count
        call InBufferGetByte
        or al, al
        je no_graphic_data_found

        ; Record this as the count of data in the upcoming data block.
        ; Add one to the bytes needed to get the data block plus the
        ; beginning of the next data block (or whatever it will be).
        ; There will always be at least a terminator, so its safe to grab.
        clr ah
        mov [IGS_uncompressCount], al
;do this in next state now
;	inc ax
        mov [IGS_bytesNeeded], ax

        ; Setup the dictionary
        call IDictionaryInitialize
        call IDictionaryClear

        ; Go ahead and go uncompress state knowing there
        ; will be enough data.
        mov ax, offset IStateUncompressCheckEnd
        mov [IGS_stateFunction], ax
        mov ax, IG_STATUS_OK
        ret

no_graphic_data_found:
        mov ax, IG_STATUS_GIF_DONE
        ret
IStateUncompressStart endp

;----------------------------------------------------------------------------
; Routine:  IStateUncompressCheckEnd
;----------------------------------------------------------------------------
; Description:
;    Handle GIFs without trailing terminator.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX
;
;----------------------------------------------------------------------------

IStateUncompressCheckEnd proc near
        ; Do we have enough data for terminator?
        mov ax, [IGS_inBufCount]
        cmp ax, [IGS_bytesNeeded]
        jg request_terminator

	; If not enough data for terminator and end of data, thats okay
	test [IGS_hitLast], 0xFF
	jnz enough_data
	; Else, fall through to request extra data with terminator

request_terminator:
	; Request terminator
	inc [IGS_bytesNeeded]

enough_data:
        ; Go ahead and go uncompress state knowing there
        ; will be enough data.
        mov ax, offset IStateUncompressData
        mov [IGS_stateFunction], ax
        mov ax, IG_STATUS_OK
	ret
IStateUncompressCheckEnd endp

;----------------------------------------------------------------------------
; Routine:  IDataBlockGetByte
;----------------------------------------------------------------------------
; Description:
;    Read one byte in from the currently being processed data block
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry clear
;        AL        - Next byte in block
;    carry set
;                  - Not enough data in buffer.  Can't get a byte
;
; Destroys:        AX, BX, CL
;
;----------------------------------------------------------------------------
IDataBlockGetByte proc near
         test [IGS_uncompressCount], 0xFF
         je data_block_no_data
         dec [IGS_uncompressCount]

         ; In buffer can't return an error, so just get a byte
         ; and note a good status.
         call InBufferGetByte
         clc
         ret
data_block_no_data:
         ; Note that we don't have data to give
         stc
         ret
IDataBlockGetByte endp

;----------------------------------------------------------------------------
; Routine:  IUncompressGetCode
;----------------------------------------------------------------------------
; Description:
;    Read in one uncompression code based on the current compression state.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry clear
;        AX        - Next code
;    carry set
;                  - Not enough data in buffer.  Can't get code
;
; Destroys:        AX, BX, CL
;
;----------------------------------------------------------------------------
IUncompressGetCode proc near

        ; I didn't want to resort to having a 24 bit or 32 bit buffer,
        ; so all we do is handle the special case of when we want more
        ; bits than can fit in a 16 bit buffer with 8 bits flowing over.
        ; Check out 'not_enough_room'.  Otherwise, we are justing using
        ; a 16 bit buffer, shifting the bits over as they are taken.

        ; Do we need to get more bits??
check_again:
        mov al, [IGS_codeBufferBits]
        cmp al, [IGS_codeSize]
        jge got_enough
        call IDataBlockGetByte
        jc data_block_empty

        ; Is there room to store the byte?
        cmp [IGS_codeBufferBits], 8
        jg not_enough_room

        ; Add a byte into the bit buffer (shifting into place)
        mov cl, [IGS_codeBufferBits]
        clr ah
        shl ax, cl
        or [IGS_codeBuffer], ax
        add [IGS_codeBufferBits], 8

        jmp check_again

not_enough_room:
        ; We have a total of more than 16 bits, more than 8 in codeBuffer
        ; and 8 more in AL.  We can't fit them all in codeBuffer, but
        ; we know we have enough for the final code.  Let's just process
        ; it.

        ; Get 8 bits out of the codeBuffer (that's the low bits of the code)
        mov bl, byte ptr [IGS_codeBuffer]

        ; Shift the codeBuffer over by 8 bits to make room.
        mov cl, 8
        shr [IGS_codeBuffer], cl
        sub [IGS_codeBufferBits], cl

        ; Put the last byte into the code buffer.
        mov cl, [IGS_codeBufferBits]
        clr ah
        shl ax, cl
        or [IGS_codeBuffer], ax
        add [IGS_codeBufferBits], 8

        ; Get the remaining upper half of the yet to be finished code.
        mov cl, [IGS_codeSize]
        sub cl, 8
        mov al, 1
        shl al, cl
        dec al
        mov bh, byte ptr [IGS_codeBuffer]
        and bh, al
        shr [IGS_codeBuffer], cl
        sub [IGS_codeBufferBits], cl

        ; Return the final code.
        mov ax, bx
        clc
        ret


got_enough:
        ; Everything is fine.  Let's get the code and shift.
        mov ax, [IGS_codeBuffer]
        and ax, [IGS_codeMask]

        ; Fix up the mask's position and buffer bit count
        mov cl, [IGS_codeSize]
        shr [IGS_codeBuffer], cl
        sub [IGS_codeBufferBits], cl

        ; Got a code.  Exit with a good status
        clc
        ret

data_block_empty:
        ; Just report an error
        ret
IUncompressGetCode endp

;----------------------------------------------------------------------------
; Routine:  IDictionaryGrowCode
;----------------------------------------------------------------------------
; Description:
;    The code size is now bigger, grow it and update related fields
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Destroys:        AX
;
;----------------------------------------------------------------------------
IDictionaryGrowCode proc near
        mov al, [IGS_codeSize]
        cmp al, MAX_NUM_CODE_BITS
        jge dict_cant_grow_code

        ; One more to the code size and double the max code
        inc al
        mov [IGS_codeSize], al
        shl [IGS_codeMax], 1
        shl [IGS_codeMask], 1
        or [IGS_codeMask], 1

dict_cant_grow_code:
        ret
IDictionaryGrowCode endp

;----------------------------------------------------------------------------
; Routine:  IDictionaryAddCode
;----------------------------------------------------------------------------
; Description:
;    Add a new entry to the dictionary.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;                    with:
;                        [IGS_codeFree]        - next free slot
;                        [IGS_codeOld]         - Previous code
;                        [IGS_charFin]         - Last character output
;                        plus the whole mask variables (if we increase)
;
; Destroys:        Nothing
;
;----------------------------------------------------------------------------
IDictionaryAddCode proc near
        uses es, di, ax, bx
        .enter
        mov bx, [IGS_codeFree]
        cmp bx, MAX_SIZE_DICTIONARY-2
        jge dict_add_too_big

        ; Get the dictionary out
        mov es, [IGS_dictionarySegment]

        ; Find the free code index as a multiple of entries
        mov di, bx
        shl di, 1
        add di, bx

        ; Store the new entry (code is stored as an offset into the dict.)
        mov al, [IGS_charFin]
        stosb
        mov ax, [IGS_codeOld]
        shl ax, 1
        add ax, [IGS_codeOld]
        stosw

        ; Update the table
        inc bx
        mov [IGS_codeFree], bx
        cmp bx, [IGS_codeMax]
        jl dict_add_code_dont_grow_code
        call IDictionaryGrowCode
dict_add_code_dont_grow_code:

        ; Fall into dict_add_too_big since the same.

dict_add_too_big:
        ; dictionary is full.  Just leave it.
        .leave
        ret
IDictionaryAddCode endp


;----------------------------------------------------------------------------
; Routine:  IUncompressCode
;----------------------------------------------------------------------------
; Description:
;    Work out a single code decompression.  Should always output
;    a string of data.
;    No control codes at this point, just true decompressing.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    carry         - set if image filled, we're done.  Else, continue.
;
; Destroys:        AX, BX, ES, DI, CX
;
;----------------------------------------------------------------------------

IUncompressCode proc near
         ; Is this the first code since we cleared the dictionary?
         test [IGS_isFirstCode], 1
         je uncompress_first_code

         ; Not the first code.  We've got an old code.
         ; That means we do all the complex logic.
         push ax
         push es
         mov es, [IGS_patternSegment]
         mov di, 0

         ; Is this a special case pattern of C[...]C
         ; where C is the character and [...] is the pattern?

         cmp ax, [IGS_codeFree]
         jl uncompress_not_special_case

         ; This is the special C[...]C case, just add a C
         ; at the beginning and process like normal.
         mov al, [IGS_charFin]
         stosb
         mov ax, [IGS_codeOld]
uncompress_not_special_case:

         ; Process whole uncompress string like normal
         push ds
         mov ds, [IGS_dictionarySegment]

         ; Multiple the current code by three to get an offset
         ; and put into SI
         mov si, ax
         shl si, 1
         add si, ax

         mov cx, MAX_SIZE_UNCOMPRESS_PATTERN-1
uncompress_main_loop:
         ; Copy over the suffix
         movsb

         ; Get the next address in the table
         mov si, [si]

         ; Keep going through the table if there is more
         ; and our pattern is not overflowed.
         test si, 0x8000
         loope uncompress_main_loop

; uncompress_overflowed_pattern:
         ; What was the last character output?
         ; Record it for later.
         mov al, es:[di-1]
         pop ds
         mov [IGS_charFin], al

         ; At this point, we have DI uncompressed bytes to output
         ; as pixels, but they are in reverse order.
uncompress_output_pixels:
         or di, di
         je uncompress_output_done
         dec di
         mov al, es:[di]
         push es
         push di
         call IOutputPixel
         pop di
         pop es

         ; If we are told the image is filled, stop!  We're done somehow
         jc uncompress_end_of_image

         ; Otherwise, keep outputting this pattern
         jmp uncompress_output_pixels

uncompress_output_done:
         ; We are done outputing the pattern,
         ; now update the dictionary.
         call IDictionaryAddCode

         ; Everything is good, but the picture is NOT filled.
         clc

uncompress_end_of_image:
         ; [1*] Careful, don't mess up carry here
         pop es
         pop ax
         mov [IGS_codeOld], ax

         ; Return carry flag from [1*]
         ret

uncompress_first_code:
         ; This is the first code since a dictionary clear command.
         ; We can simplify the rules a bit.
         ; Mark this as a processed first code
         or [IGS_isFirstCode], 1

         ; Record the result of doing the first code (last character
         ; and last code), then output the pixel (has to be a pixel).
         mov [IGS_charFin], al
         mov [IGS_codeOld], ax
         call IOutputPixel

         ; Return the carry state from IOutputPixel
         ret
IUncompressCode endp

;----------------------------------------------------------------------------
; Routine:  IStateUncompressData
;----------------------------------------------------------------------------
; Description:
;    One block of uncompressed data is waiting.  Start or continue
;    uncompressing.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, BX, CX
;
;----------------------------------------------------------------------------

IStateUncompressData proc near
         ; At this point, we have IGS_uncompressCount bytes (plus one) in
         ; the InBuffer ready to be processed.
         ; The goal here is to loop through all that uncompressed data
         ; and then leave this state either when we are done or if there
         ; is a need of more data to process.
uncompress_continue:
         call IUncompressGetCode
         jnc uncompress_has_code

         ; We ran out of data in this block.  We need more data.
         ; The next byte tells how much.
         call InBufferGetByte

         ; Have we found the end?
         or al, al
         je uncompress_end_found

         ; Nope, another block of data coming.  Get the next N+1 bytes.
         ; And the next N bytes will in the block when it gets here.
         clr ah
         mov [IGS_uncompressCount], al
         inc ax
         mov [IGS_bytesNeeded], ax
         mov ax, IG_STATUS_OK
         ret
uncompress_has_code:
         ; Yeah, we have a code in AX.  Now what??
         ; Is this the clear code?
         cmp ax, [IGS_codeClear]
         jne uncompress_not_clear_code

         ; Clear out the dictionary.
         call IDictionaryClear
         jmp uncompress_continue

uncompress_not_clear_code:
         ; Is this the end code?
         cmp ax, [IGS_codeEOF]
         jne uncompress_not_end

         ; Flush the reamining bytes in this block
         ; and then go to to uncompress_end_found, when done
uncompress_flush:
         test [IGS_uncompressCount], 0xFF
         je uncompress_end_found
         call IDataBlockGetByte
         jmp uncompress_flush

uncompress_not_end:
         ; Ok, this is a regular code.
         ; Its getting confusing here, so let a subroutine handle
         ; the code processing.
         call IUncompressCode

         ; One down, couple zillion to go.  So let's get the next code.
         jnc uncompress_continue

         ; Hmmm.... says we're done with the image itself.
         jc uncompress_flush

uncompress_end_found:
         ; End of the compression data.  So we must be done, right?
         ; Well, I hope so.  The next state will only be if someone
         ; is trying t find the next frame of the animation.  This
         ; might be more extensions.  I'm not sure, but it starts
         ; the whole process of getting a gif over (after the header).
         call InBufferPeekByte
         cmp al, GIF_TRAILER
         je noExtraBlocks
         cmp al, GIF_INTRODUCER_CHARACTER
         je noExtraBlocks

	 call InBufferGetByte
	 clr ah
	 tst al
	 je noExtraBlocks

	 ; Another compressed section exists.  Be sure to skip it.
	 inc ax
	 mov [IGS_bytesNeeded], ax
	 mov ax, offset IStateSkipExtraCompressedSubBlocks
	 mov [IGS_stateFunction], ax
	 mov ax, IG_STATUS_OK
	 jmp done

noExtraBlocks:
	 ; We've reached the end of the compresed data.  Next section.
         mov ax, offset IStateReviewExtensionsStart
         mov [IGS_stateFunction], ax
         mov ax, 1
         mov [IGS_bytesNeeded], ax
         mov ax, IG_STATUS_GIF_DONE
done:
         ret
IStateUncompressData endp

;----------------------------------------------------------------------------
; Routine:  IStateSkipExtraCompressedSubBlocks
;----------------------------------------------------------------------------
; Description:
;    One block of uncompressed data is waiting.  Skip it.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;    DS:IGS_bytesNeeded  - Number of bytes in subblock plus 1.
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        AX, CX
;
;----------------------------------------------------------------------------

IStateSkipExtraCompressedSubBlocks proc near
        ; Skip the compressed bytes (minus the next header)
	; If zero (after minnusing the extra one), we are done
	mov cx, [IGS_bytesNeeded]
	dec cx
	tst cx
	je doneWithExtra

	; Pull it all out
grabBytes:
	call InBufferGetByte
	loop grabBytes

        ; Some gif files end their compression with a small 2 byte
        ; compression block that is a 1 (for 2 bytes) followed by
        ; a zero.  When this occurs, we just count it as an ending
        cmp al, 0
        jne notAFunnyEnding
        mov ax, [IGS_bytesNeeded]
        cmp ax, 2
        jne notAFunnyEnding

        ; Pull off any zeros remaining
pullZeros:
        call InBufferPeekByte
        cmp al, 0
        jne doneWithExtra
        call InBufferGetByte
        jmp pullZeros

notAFunnyEnding:
	; Is there another block?
	call InBufferGetByte
	clr ah
	inc ax
	mov [IGS_bytesNeeded], ax
	mov ax, IG_STATUS_OK

	; Do this state again
	jmp subblocks_done

doneWithExtra:
        mov ax, offset IStateReviewExtensionsStart
        mov [IGS_stateFunction], ax
        mov ax, 1
        mov [IGS_bytesNeeded], ax
        mov ax, IG_STATUS_GIF_DONE
subblocks_done:
	ret
IStateSkipExtraCompressedSubBlocks endp

;----------------------------------------------------------------------------
; Routine:  IUpdateGIFState
;----------------------------------------------------------------------------
; Description:
;    Does one step of the GIF processing code.  This might be evaluating
;    one header, processing one block of data code, etc.  This routine
;    first determines if there is enough data before continuing.
;    If not enough data is found, an error message is created.
;
; Inputs:
;    DS:0          - ImpGIFStruct
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        ???
;
;----------------------------------------------------------------------------

IUpdateGIFState proc near
		; Have we canceled yet?
		push	es, bx
		movdw	esbx, [IGS_mimeStatus]
		mov		ax, es:[bx].MS_mimeFlags
		pop		es, bx
		test	ax, mask MIME_STATUS_ABORT
		jnz		abort_found

        ; Do we have enough data to do a state?
        mov ax, [IGS_bytesNeeded]
        cmp ax, [IGS_inBufCount]
        jg not_enough_for_state

        ; Ok.  we have enough for this state.  Let's process it
        ; and return back to our parent.
        jmp [IGS_stateFunction]

not_enough_for_state:
        test [IGS_hitLast], 0xFF
        jnz state_has_reached_end
        ; Well, we just don't have enough data and supposedly there is
        ; more to come.  We'll just ask for more.
        mov ax, IG_STATUS_NEED_DATA
        ret
state_has_reached_end:
        ; Don't know what to say, but we've reached the end of the stream.
        ; No more data, no more processing.  But this doesn't mean
        ; we have reached the end of the gif.
        mov ax, IG_STATUS_END_DATA
        ret

abort_found:
		; Leave in an ugly state -- we aborted somewhere
		mov ax, IG_STATUS_ABORTED
		ret
IUpdateGIFState endp

;----------------------------------------------------------------------------
; Routine:  ImpGIFProcess
;----------------------------------------------------------------------------
; Description:
;    Process a group of bytes and return the appropriate error message or
;    a completed uncompressed file.
;
; Inputs:
;    BX            - ImpGIFHandle
;    ES:DI         - Data coming in
;    CX            - Number of data bytes coming in
;    carry         - set if this is the last block, else cleared
;
; Outputs:
;    AX            - Return ImpGIFStatus
;
; Destroys:        BX, DS
;
;----------------------------------------------------------------------------

ImpGIFProcess proc far
	; Added handle validity check 2001/1/18 -martin
	lahf				; save CF
	tst	bx
	jz	nullHandle
	sahf				; restore CF
        ; Lock in the gif importur structure and make it DS	
        push bx
        pushf
        call MemLock
        mov ds, ax
        popf

        ; Add the data to the buffer
        call InBufferAddData

        mov ax, [IGS_lastStatus]
        cmp ax, IG_STATUS_GIF_DONE
        jne not_after_picture
        clr ax
        mov [IGS_vmBlock], ax
not_after_picture:
        ; Lock in the current raster (if any)
        call IDictionaryLock
        call IRasterLock
process_loop:
        ; do an interration of of import
        push ds
        call IUpdateGIFState
        pop ds

        ; Loop until we have either IG_STATUS_NEED_DATA
        ;      or IG_STATUS_GIF_DONE
        cmp ax, IG_STATUS_OK
        je process_loop

        mov [IGS_lastStatus], ax

        ; Unlock the current raster (if any)
        call IRasterUnlock
        call IDictionaryUnlock

        ; Release the gif import structure
        pop bx
        call MemUnlock
done:	
        ret

nullHandle:
	mov	ax, IG_STATUS_ERROR
	jmp	done	
ImpGIFProcess endp

;----------------------------------------------------------------------------
; Routine:  ImpGIFProcessFile
;----------------------------------------------------------------------------
; Description:
;    Process a whole file starting from the beginning and going to the end
;    returning any errors that may of caused a problem -- or a finished
;    graphic.
;
; Inputs:
;    ES:DI *       - ImpBmpParameters
;    BX            - AllocWatcherHandle
;    CX            - MimeDrv resolution
;    AX            - Status message
;    SI            - non-0 if want system palette, else 0
;
; Outputs:
;    DX:BX         - Amount of memory used
;    AX            - ImpBmpStatus
;
; Destroys:        Assume all
;
;----------------------------------------------------------------------------

ImpGIFProcessFile proc far

impgifhandle                   local word
bufferHandle                   local word
bufferSegment                  local word
inFile                         local hptr.FileHandle
finalStatus                    local word
statusObj                      local optr
fileSize                       local word  ; Number of 512 byte blocks
blockCount                     local word  ; Lets just count blocks
statusMsg                      local word

        .enter
        ; Record the status message (before we screw up AX)
        mov statusMsg, ax

        or si, si
        je no_sys_palette
        mov si, 1
no_sys_palette:
        ; Try to create a import GIF session
        mov ax, es:[di].IBP_source
        mov inFile, ax
        movdw dxax, es:[IBP_status]
        movdw [statusObj], dxax
        or dx, dx
        je no_size_needed_no_status
        push bx
        mov bx, inFile
        call FileSize
        mov bx, FILEBUFFER_SIZE
        div bx
        inc ax            ; Round up the count so we don't have div 0
        mov fileSize, ax
        pop bx
no_size_needed_no_status:
        mov ax, es:[di].IBP_dest
        xchg cx, bx
		push es, di
		push es:[di].IBP_mimeStatus.segment
		push es:[di].IBP_mimeStatus.offset
		pop	di
		pop	es
        call ImpGIFCreate
		pop	es, di
        jc out_of_memory_closer

        ; Now that we have a file, let's work with it
        mov impgifhandle, bx

        push es, di

        ; Create a buffer to hold incoming data
        mov ax, FILEBUFFER_SIZE
        mov cl, mask HF_SWAPABLE or mask HF_SHARABLE
        mov ch, mask HAF_ZERO_INIT or mask HAF_LOCK
        call MemAlloc
        jc no_buffer_created

        ; Hold onto that buffer
        mov bufferHandle, bx
        mov bufferSegment, ax

read_and_process_loop:
        inc blockCount
        ; Output a status here.
        movdw bxsi, [statusObj]
        or bx, bx
        jne no_status_to_output

        ; Calculate the percent done
        clr dx
        mov ax, blockCount
        mov di, 100
        mul di
        mov di, fileSize
        div di
        mov cx, ax
        mov di, mask MF_CALL
        mov ax, statusMsg
        call ObjMessage
        cmp ax, FALSE
        jne continue_read

        ; User is wishing to abort.
        mov ax, IG_STATUS_ABORTED
        jmp abort_requested

out_of_memory_closer:
        jmp out_of_memory

no_status_to_output:
continue_read:
        ; Try reading a block of data from the file
        mov ax, bufferSegment
        mov ds, ax
        clr al
        clr dx
        mov bx, inFile
        mov cx, FILEBUFFER_SIZE
        call FileRead

        ; cx = number of bytes in file buffer
        ; bx = ImpGIFHandle
        ; es:di = pointer to file buffer
        mov ax, bufferSegment
        mov es, ax
        clr di
        mov bx, impgifhandle

        ; Set the carry if under full size
        clc
        cmp cx, FILEBUFFER_SIZE-1

        ; Process a group of data for the GIF
        ; Return an error, success, or a request for more data
        call ImpGIFProcess

        ; Are we needing more data?
        cmp ax, IG_STATUS_NEED_DATA
        je read_and_process_loop

abort_requested:
        mov finalStatus, ax

        pop es, di

        ; Destroy the file buffer
        mov bx, bufferHandle
        call MemFree

        jmp done_gif_file
no_buffer_created:
        call ImpGIFDestroy
        ; Fall through to out_of_memory
out_of_memory:
        ; Not enough memory for processing this file
        mov ax, IG_STATUS_COULD_NOT_CREATE
        mov finalStatus, ax
        clr dx
        clr bx
        movdw [IGS_memoryUsed], dxbx

done_gif_file:
        ; Copy over data from the GIF import session
        mov bx, impgifhandle
        push ds
        call MemLock
        mov ds, ax
        mov ax, [IGS_vmBlock]
        mov es:[di].IBP_bitmap, ax
        mov ax, [IGS_localImage.GLID_width]
        mov es:[di].IBP_width, ax
        mov ax, [IGS_localImage.GLID_height]
        mov es:[di].IBP_height, ax
        mov al, [IGS_format]
        mov es:[di].IBP_format, al
        ; Get the amount of memory used.
        movdw dxax, [IGS_memoryUsed]

        call MemUnlock
        pop ds

        push dx
        push ax

        ; Destroy the GIF import session
        mov bx, impgifhandle
        call ImpGIFDestroy

        pop bx
        pop dx

        ; Everything went ok, we're done
        mov ax, finalStatus

        mov si, ax
        shl si, 1
        mov ax, cs:[errorTransTable+si]

        .leave
        ret
ImpGIFProcessFile endp

; Table for translation from ImpGIFStatus to ImpBmpStatus
errorTransTable  word  IBS_NO_ERROR,       ; IG_STATUS_OK
                       IBS_NO_ERROR,       ; IG_STATUS_GIF_DONE
                       IBS_SYS_ERROR,      ; IG_STATUS_NEED_DATA
                       IBS_IMPORT_STOPPED, ; IG_STATUS_END_DATA
                       IBS_UNKNOWN_FORMAT, ; IG_STATUS_ERROR_NOT_GIF
                       IBS_SYS_ERROR,      ; IG_STATUS_ERROR
                       IBS_IMPORT_STOPPED, ; IG_STATUS_FOUND_END_OF_GIF
                       IBS_NO_MEMORY,      ; IG_STATUS_COULD_NOT_CREATE
                       IBS_IMPORT_STOPPED, ; IG_STATUS_NO_GRAPHIC
                       IBS_IMPORT_STOPPED  ; IG_STATUS_ABORTED

;----------------------------------------------------------------------------
; Routine:  ImpGIFGetInfo
;----------------------------------------------------------------------------
; Description:
;    Gets information about the previously loaded bitmap.
;
; Inputs:
;    BX            - ImpGIFHandle
;    ES:DI         - Pointer to ImpGIFInfo structure
;
; Destroys:        BX
;
;----------------------------------------------------------------------------

ImpGIFGetInfo proc far
        push ds
        push es
        push ax
        push cx
        push bx
        push dx
        call MemLock
        mov ds, ax

        ; Do the Get Info
        mov ax, [IGS_vmBlock]
        mov es:[di+IGI_bitmap], ax
        mov ax, [IGS_width]
        mov es:[di+IGI_fieldWidth], ax
        mov ax, [IGS_height]
        mov es:[di+IGI_fieldHeight], ax
        mov al, [IGS_format]
        mov es:[di+IGI_format], al
        mov ax, [IGS_localImage.GLID_width]
        mov es:[di+IGI_bitmapWidth], ax
        mov ax, [IGS_localImage.GLID_height]
        mov es:[di+IGI_bitmapHeight], ax
        mov ax, [IGS_localImage.GLID_x]
        mov es:[di+IGI_bitmapX], ax
        mov ax, [IGS_localImage.GLID_y]
        mov es:[di+IGI_bitmapY], ax
        mov ax, [IGS_delayTime]
        mov es:[di+IGI_delay], ax
        mov ax, [IGS_loopCount]
        mov es:[di+IGI_loopCount], ax
        mov al, [IGS_frameInfo]
        mov cl, offset GIIB_DISPOSAL_METHOD
        shr al, cl
        mov es:[di+IGI_removeMethod], al
        mov al, [IGS_backColor]
        mov es:[di+IGI_backgroundColor], al
        movdw dxax, [IGS_memoryUsed]
        movdw es:[di+IGI_memoryUsed], dxax

        ; Copy over the palette for the image
        push si
        push di
        add di, IGI_palette
        mov si, IGS_palette
        mov cx, (256*3)/2
        rep movsw
        pop di
        pop si

        ; Copy over the global palette for the image
        push si
        push di
        add di, IGI_globalPalette
        mov si, IGS_globalPalette
        mov cx, (256*3)/2
        rep movsw
        pop di
        pop si

        pop dx
        pop bx
        call MemUnlock
        pop cx
        pop ax
        pop es
        pop ds
        ret
ImpGIFGetInfo endp

;----------------------------------------------------------------------------
; C stubs:
;----------------------------------------------------------------------------
IMPGIFCREATE proc far file:word, allocwatcher:word, useSysPal:word, mimeStatus:fptr
        uses bx, cx, dx, es, di
        .enter

		movdw esdi, mimeStatus, ax
        mov ax, file
        mov cx, allocwatcher
        mov si, useSysPal
        call ImpGIFCreate
        mov ax, bx

        .leave
        ret
IMPGIFCREATE endp


;----------------------------------------------------------------------------
IMPGIFDESTROY proc far impgifhandle:word
        uses bx
        .enter

        mov bx, impgifhandle
        call ImpGIFDestroy

        .leave
        ret
IMPGIFDESTROY endp


;----------------------------------------------------------------------------
IMPGIFPROCESS proc far impgifhandle:word,
                       inData:fptr,
                       numDataBytes:word,
                       isLast:word
        uses bx, cx, dx, ds, es, si, di
        .enter

        mov bx, impgifhandle
        movdw esdi, inData
        mov cx, numDataBytes
        mov dx, isLast
        inc dx
        cmp dx, 1           ; carry set if ax == 0, else carry is clear
        call ImpGIFProcess

        .leave
        ret
IMPGIFPROCESS endp


;----------------------------------------------------------------------------
IMPGIFPROCESSFILE proc far params:fptr,     ; ImpBmpParams ptr
                           watcher:word,    ; AllocWatcherHandle
                           usedMem:fptr,    ; dword ptr
                           resolution:word, ; MimeRes
                           useSysPal:word,  ; Boolean useSys
                           statusMsg:word   ; Status message to use (if any)
        uses bx, cx, dx, ds, es, si, di
        .enter

        ; Prepare the registers and call the real routine
        movdw esdi, params
        mov bx, watcher
        mov cx, resolution
        mov si, useSysPal
        mov ax, statusMsg
        call ImpGIFProcessFile

        ; Record the amount of used memory
        movdw esdi, usedMem
        movdw es:[di], dxbx

        .leave
        ret
IMPGIFPROCESSFILE endp


;----------------------------------------------------------------------------
IMPGIFGETINFO proc far impgifhandle:word, infoBlock:fptr
        uses bx, es, di
        .enter

        mov bx, impgifhandle
        movdw esdi, infoBlock
        call ImpGIFGetInfo

        .leave
        ret
IMPGIFGETINFO endp


;----------------------------------------------------------------------------

if PROGRESS_DISPLAY

IMPGIFGETPROGRESSINFO proc far impgifhandle:word, infoBlock:fptr
        uses ax, bx, es, di, ds
        .enter

        mov bx, impgifhandle
        movdw esdi, infoBlock
        call MemLock
        mov ds, ax

        ; Do the Get Info
        mov ax, [IGS_vmBlock]
        mov es:[di+IGPI_bitmap], ax
        mov ax, [IGS_width]
        mov es:[di+IGPI_fieldWidth], ax
        mov ax, [IGS_height]
        mov es:[di+IGPI_fieldHeight], ax
	mov ax, [IGS_yPos]
	mov es:[di+IGPI_yPos], ax

        call MemUnlock

        .leave
        ret
IMPGIFGETPROGRESSINFO endp

endif


;----------------------------------------------------------------------------

ImpGIFCode ends

;----------------------------------------------------------------------------

ImpGraphCode segment

GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR = -1

IMPPACKBITS	proc	far	destBits:fptr, srcBits:fptr, srcSize:word
		uses	bx, cx, dx, ds, si, es, di
		.enter
		lds	si, srcBits
		les	di, destBits
		mov	cx, srcSize

		; Start the whole process
		;
		push	di			; save starting offset
newSeed:
		jcxz	done
		lodsb
		dec	cx
		jmp	uniqueStart

		; We've run out of bytes in the middle of a unique series
cleanUpUnique:
		dec	dl
EC <		cmp	dl, 127			; can't be more than 127     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		mov	es:[bx], dl		; end unique count

		; We're done - return the number of bytes in the scan-line
done:
		mov	ax, di			; last offset => AX
		pop	di			; starting offset => DI
		sub	ax, di			; ax = # destination bytes

		.leave
		ret

		; We've just found a byte that does not match the previous
uniqueStart:
		mov	bx, di
		inc	di			; leave room for count byte
		stosb				; store this first byte
		mov	ah, al
		mov	dx, 0x101		; initialize both counts
uniqueByte:
		jcxz	cleanUpUnique
		lodsb
		dec	cx
		stosb
		cmp	ah, al
		je	endUniqueness
		mov	ah, al
		mov	dh, 1			; initialize repeat count
uniqueContinue:
		inc	dl			; increment unique count
		cmp	dl, 128			; compare against maximum count
		jne	uniqueByte
EC <		cmp	dl, 128			; can't be more than 127     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		dec	dl			; reached maximum byte count
		mov	es:[bx], dl		; ...so store (count - 1)
		jmp	newSeed			; look for a new seed byte again
endUniqueness:
		inc	dh			; increment repeat count
		cmp	dh, 2			; if only two matches
		jle	uniqueContinue		; ...then keep on going
		cmp	dl, 2			; if unique count is only 2(+1),
		je	matchStart		; ...then no unique bytes
		sub	dl, 3			; subtract repeat length
EC <		cmp	dl, 127			; can't be more than 127     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		mov	es:[bx], dl		; store unique count
		inc	di

		; We've found three consecutive matching bytes.
matchStart:
		sub	di, 2			; we've written three matching
		mov	bx, di			; ...bytes, we'll use byte 0
		sub	bx, 2			; ...to hold the count and start
						; ...storing bytes at byte 2
matchByte:
		jcxz	cleanUpRepeat
		lodsb
		dec	cx
		cmp	ah, al
		jne	endMatching
		inc	dh			; increment repeat count
		cmp	dh, 128			; see if we've wrapped
		jbe	matchByte		; ...if not, continue
		dec	dh			; ...else end run of matches

		; We've end a run of matching bytes. Store the count
endMatching:
EC <		cmp	dh, 3			; must be at least 3 matches >
EC <		ERROR_B	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
EC <		cmp	dh, 128			; can't be more than 128     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		dec	dh
		neg	dh
		mov	es:[bx], dh
		jmp	uniqueStart

		; We've run out of bytes in the middle of a repeat series
cleanUpRepeat:
EC <		cmp	dh, 128			; can't be more than 128     >
EC <		ERROR_A	GRAPHICS_BITMAP_COMPACTION_INTERNAL_ERROR	     >
		dec	dh
		neg	dh
		mov	es:[bx], dh
		jmp	done

IMPPACKBITS	endp

ImpGraphCode ends

;----------------------------------------------------------------------------
