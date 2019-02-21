COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		vga8Chars.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92		Initial revision

DESCRIPTION:
	
	$Id: vga8Chars.asm,v 1.2 96/08/05 03:51:45 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char1In1Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character, 1 byte of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char1In1Out	proc	near
                uses    bx

                .enter
NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>

                push    ax, dx
                mov     ax, 8
                mul     cs:[pixelBytes]
                sub     bp, ax
                pop     ax, dx

                mov     bl, cs:[currentColor].RGB_blue   ; get current draw color
                mov     ax, {word} cs:[currentColor].RGB_red

		; do next scan.  Load data byte and go for it.
scanLoop:
                call    DrawOneDataByte
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp						>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
                .leave
		pop	ax
		jmp	PSL_afterDraw
Char1In1Out	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOneDataByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one data byte, part of a series

CALLED BY:	
PASS:		ds:si	- points to byte to draw
		es:di	- points into frame buffer
		al	- color to draw with
RETURN:		nothing
DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawOneDataByte proc    near
                mov     bh, ds:[si]                     ; save data byte in al
		inc	si


                xchg    al, bl

                NextScan        di, 0
                jc      pageDCB

nopageDCB:
                shl     bh,1
                jnc     pix2                        
                mov     [es:di],ax                     
                mov     [es:di+2], bl
pix2:
                add     di, cs:[pixelBytes]
                shl     bh,1                           
                jnc     pix3                        
                mov     [es:di],ax                     
                mov     [es:di+2], bl
pix3:
                add     di, cs:[pixelBytes]
                shl     bh,1                           
                jnc     pix4                        
                mov     [es:di],ax                     
                mov     [es:di+2], bl
pix4:
                add     di, cs:[pixelBytes]
                shl     bh,1                          
                jnc     pix5                       
                mov     [es:di],ax                     
                mov     [es:di+2], bl
pix5:
                add     di, cs:[pixelBytes]
                shl     bh,1                           
                jnc     pix6                        
                mov     [es:di],ax                     
                mov     [es:di+2], bl
pix6:
                add     di, cs:[pixelBytes]
                shl     bh,1                           
                jnc     pix7                        
                mov     [es:di],ax                     
                mov     [es:di+2], bl
pix7:
                add     di, cs:[pixelBytes]
                shl     bh,1                           
                jnc     pix8                       
                mov     [es:di],ax                     
                mov     [es:di+2], bl
pix8:
                add     di, cs:[pixelBytes]
                shl     bh,1                          
                jnc     done                       
                mov     [es:di],ax                     
                mov     [es:di+2], bl
done:
                add     di, cs:[pixelBytes]
                xchg    al, bl
                ret

pageDCB:
                mov     dx, cs:[pixelsLeft]
                cmp     dx, 8
                ja      nopageDCB

                cmp     cs:[pixelsLeft], 0
                jnz     nosplit

                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask 
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_1
nosplit:
                shl     bh, 1
                jnc     loop1      
                mov     [es:di],ax                     
                mov     [es:di+2], bl
loop1:
                add     di, cs:[pixelBytes]
                dec     dx

                jnz     DCB_1
                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask 
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_2
DCB_1:
                shl     bh, 1
                jnc     loop2
                mov     [es:di],ax
                mov     [es:di+2], bl
loop2:
                add     di, cs:[pixelBytes]
                dec     dx

                jnz     DCB_2
                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_3
DCB_2:
                shl     bh, 1
                jnc     loop3      
                mov     [es:di],ax
                mov     [es:di+2], bl
loop3:
                add     di, cs:[pixelBytes]
                dec     dx

                jnz     DCB_3
                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_4
DCB_3:
                shl     bh,1
                jnc     loop4
                mov     [es:di],ax                     
                mov     [es:di+2], bl
loop4:
                add     di, cs:[pixelBytes]
                dec     dx
                jnz     DCB_4
                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_5
DCB_4:
                shl     bh,1
                jnc     loop5
                mov     [es:di],ax                     
                mov     [es:di+2], bl
loop5:
                add     di, cs:[pixelBytes]
                dec     dx
                jnz     DCB_5
                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_6
DCB_5:
                shl     bh,1                   
                jnc     loop6
                mov     [es:di],ax                     
                mov     [es:di+2], bl
loop6:
                add     di, cs:[pixelBytes]
                dec     dx
                jnz     DCB_6
                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_7
DCB_6:
                shl     bh,1     
                jnc     loop7
                mov     [es:di],ax                     
                mov     [es:di+2], bl
loop7:
                add     di, cs:[pixelBytes]
                dec     dx
                tst     dx
                jnz     DCB_7
                push    cx
                xchg    al, bl
                test    bh, 0x80
                call    PutSplitedPixelMask
                xchg    al, bl
                pop     cx
                shl     bh, 1
                dec     dx
                jmp     DCB_8
DCB_7:
                shl     bh,1
                jnc     loop8   
                mov     [es:di],ax                     
                mov     [es:di+2], bl
loop8:                              
                add     di, cs:[pixelBytes]
                
                cmp     di, 0
                jnz     DCB_8

;                dec     dx
;                jnz     DCB_8
;                cmp     cs:[restBytes], 0
;                jnz     DCB_8
                call    MidScanNextWin
DCB_8:
                xchg    al, bl
                ret

DrawOneDataByte endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char2In2Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character, 2 bytes of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char2In2Out	proc	near
                uses    bx

                .enter
NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
                push    ax, dx
                mov     ax, 16
                mul     cs:[pixelBytes]
                sub     bp, ax
                pop     ax, dx
                mov     bl, cs:[currentColor].RGB_blue   ; get current draw color
                mov     ax, {word} cs:[currentColor].RGB_red

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
                call    DrawOneDataByte
                dec     ch                      ; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
                .leave
		pop	ax
		jmp	PSL_afterDraw
Char2In2Out	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char3In3Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character, 3 bytes of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char3In3Out	proc	near
                uses    bx

                .enter
NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
                push    ax, dx
                mov     ax, 24
                mul     cs:[pixelBytes]
                sub     bp, ax
                pop     ax, dx

                mov     bl, cs:[currentColor].RGB_blue   ; get current draw color
                mov     ax, {word} cs:[currentColor].RGB_red

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
                .leave
		pop	ax
		jmp	PSL_afterDraw
Char3In3Out	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Char4In4Out
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a character,4 bytes of picture data

CALLED BY:	INTERNAL
		FastCharCommon
PASS:		ds:si - character data
		es:di - screen position
		ch - number of lines to draw
		on stack - ax
RETURN:		ax - popped off stack
DESTROYED:	ch, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Char4In4Out	proc	near
                uses    bx

                .enter
NMEM <		mov	bp, cs:[modeInfo].VMI_scanSize			>
                push    ax, dx
                mov     ax, 32
                mul     cs:[pixelBytes]
                sub     bp, ax
                pop     ax, dx

                mov     bl, cs:[currentColor].RGB_blue   ; get current draw color
                mov     ax, {word} cs:[currentColor].RGB_red

		; do next scan.  Load data byte and go for it.
scanLoop:
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		call	DrawOneDataByte
		dec	ch			; one less scan to do
		jz	done
NMEM <		NextScan di,bp			; onto next scan line	>
MEM <		NextScan di			; onto next scan line	>
MEM <		tst	cs:[bm_scansNext]	; if zero, done		>
MEM <		jns	scanLoop					>
NMEM <		jmp	scanLoop					>
done:
                .leave
		pop	ax
		jmp	PSL_afterDraw
Char4In4Out	endp


