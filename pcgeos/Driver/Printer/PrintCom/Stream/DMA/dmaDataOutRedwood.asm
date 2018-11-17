COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Printer Drivers
FILE:		dmaDataOutRedwood.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	4/93		Initial version


DESCRIPTION:
	contains the routines to write DMA Data out in
	the Redwood devices

	$Id: dmaDataOutRedwood.asm,v 1.1 97/04/18 11:49:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintDMADataOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the DMA controller for printing

CALLED BY:	INTERNAL

PASS:		es	- PState segment
		ds:si	- data
		cx	- length in bytes.

RETURN:		carry set on error.	

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	DMA some data out using channel 1 in demand transfer mode.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	04/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintDMADataOut	proc	near
	uses	ax,bx,cx,dx,di
	.enter

	dec	cx		;cx = number of bytes - 1

	push	cx
	mov	bx,ds
        mov     cl,4                    ; number of shifting:  4 times.
        rol     bx,cl                   ; ds = sssszzzzxxxxyyyy
        pop     cx                      ; --> bx = zzzzxxxxyyyyssss

        mov     ah,bl                   ; get upper 4 bit of ds, page address.
        and     bl,11110000b 
        add     bx,si                   ; add offset 
                                        ; bx = start offset of the real address.
        jnc     pageAddOK               ; if no carry, page address OK

        inc     ah                      ; adjust page address.

pageAddOK:
        and     ah,00001111b            ; AH = page address of the real address.

        mov     dx,bx
        add     dx,cx                   ; DX = end offset of the real address.

        cmp     dx,bx                   ; Is the end offset correct?
        jb      error                   ; no, it is illegal, exit.

	INT_OFF				;no interrupts, please.

	;first we disable -DREQs while programming the chip.
        mov     dx,ax			;save ax
        mov     al,REDWOOD_DMA_SET_MASK
        out     PC_SINGLE_REQUEST_MASK,al   ; set request mask flag on DMA.
	call	PrintDMADataOutWaitLoop

        mov     ax,dx			;recover ax

	;reset the byte order flip flop on the chip
        out     PC_CLEAR_FLIP_FLOP,al        ; clear byte flip-flop.
	call	PrintDMADataOutWaitLoop

	;set demand transfer, increment, read, and no auto-init.
	mov	al,REDWOOD_DMA_MODE		;assume forward
        cmp     es:[PS_redwoodSpecific].RS_direction,PRINT_DIRECTION_REVERSE
	jne	modeForDMAOK
	mov     al,REDWOOD_DMA_DEC_MODE	; ok load the backwards direction.
modeForDMAOK:
        out     PC_CHANNEL_MODE,al       ; set mode register on DMA.
	call	PrintDMADataOutWaitLoop

        mov     al,ah
        out     CHANNEL_ONE_PAGE,al      ; set page register for DMA.
	call	PrintDMADataOutWaitLoop

        cmp     es:[PS_redwoodSpecific].RS_direction,PRINT_DIRECTION_REVERSE
	jne	offsetOK
	add	bx,cx			; add the count to get to end.
offsetOK:

        mov     al,bl
        out     CHANNEL_ONE_OFFSET,al    ; set low  byte of starting address
	call	PrintDMADataOutWaitLoop

        mov     al,bh
        out     CHANNEL_ONE_OFFSET,al    ; set high byte of starting address
	call	PrintDMADataOutWaitLoop

        mov     al,cl
        out     CHANNEL_ONE_COUNT,al    ; set low  byte of transmiting count
	call	PrintDMADataOutWaitLoop

        mov     al,ch
        out     CHANNEL_ONE_COUNT,al    ; set high byte of transmiting count
	call	PrintDMADataOutWaitLoop

	;now we enable -DREQs again
        mov     al,REDWOOD_DMA_CHANNEL_NUMBER
        out     PC_SINGLE_REQUEST_MASK,al  ; clear request mask flag on DMA.
	call	PrintDMADataOutWaitLoop

	INT_ON				;let interrupts happen again.

	clc

exit:
	.leave
	ret

error:
	stc
	jmp	exit

PrintDMADataOut	endp

PrintDMADataOutWaitLoop	proc	near
        push    cx
        mov     cx, 10
loophere:
	nop
        loop    loophere
        pop     cx
	ret
PrintDMADataOutWaitLoop	endp
