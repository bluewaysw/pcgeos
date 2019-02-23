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
                sub     bp, 16
                mov     bx, cs:[currentColor]   ; get current draw color

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
		mov	ah, ds:[si]			; save data byte in al
		inc	si

                NextScan        di, 0
                jc      pageDCB

nopageDCB:
                shl     ah,1                           
                jnc     pix2                        
                mov     [es:di],bx                     
pix2:
                inc     di                           
                inc     di                           
                shl     ah,1                           
                jnc     pix3                        
                mov     [es:di],bx                     
pix3:
                inc     di                           
                inc     di                           
                shl     ah,1                           
                jnc     pix4                        
                mov     [es:di],bx                     
pix4:
                inc     di                            
                inc     di                           
                shl     ah,1                          
                jnc     pix5                       
                mov     [es:di],bx                    
pix5:
                inc     di                           
                inc     di                           
                shl     ah,1                           
                jnc     pix6                        
                mov     [es:di],bx                     
pix6:
                inc     di                           
                inc     di                           
                shl     ah,1                           
                jnc     pix7                        
                mov     [es:di],bx                     
pix7:
                inc     di                           
                inc     di                            
                shl     ah,1                           
                jnc     pix8                       
                mov     [es:di],bx                    
pix8:
                inc     di                           
                inc     di                             
                shl     ah,1                          
                jnc     done                       
                mov     [es:di],bx                    
done:
                inc     di                           
                inc     di                            
                ret

pageDCB:
                mov     dx, cs:[pixelsLeft]
                cmp     dx, 8
                ja      nopageDCB

                shl     ah, 1         
                jnc     loop1      
                mov     [es:di], bx        
loop1:
                inc     di
                inc     di                           
                dec     dx
                jnz     DCB_1
                call    MidScanNextWin
DCB_1:
                shl     ah, 1
                jnc     loop2
                mov     [es:di], bx 
loop2:
                inc     di
                inc     di                           
                dec     dx
                jnz     DCB_2
                call    MidScanNextWin
DCB_2:
                shl     ah, 1
                jnc     loop3      
                mov     [es:di], bx
loop3:
                inc     di                           
                inc     di
                dec     dx
                jnz     DCB_3
                call    MidScanNextWin
DCB_3:
                shl     ah,1          
                jnc     loop4
                mov     [es:di], bx
loop4:
                inc     di
                inc     di                           
                dec     dx
                jnz     DCB_4
                call    MidScanNextWin
DCB_4:
                shl     ah,1    
                jnc     loop5
                mov     [es:di], bx
loop5:
                inc     di                           
                inc     di
                dec     dx
                jnz     DCB_5
                call    MidScanNextWin
DCB_5:
                shl     ah,1                   
                jnc     loop6
                mov     [es:di], bx
loop6:
                inc     di                           
                inc     di
                dec     dx
                jnz     DCB_6
                call    MidScanNextWin
DCB_6:
                shl     ah,1     
                jnc     loop7
                mov     [es:di], bx
loop7:
                inc     di                           
                inc     di
                dec     dx
                jnz     DCB_7
                call    MidScanNextWin
DCB_7:
                shl     ah,1
                jnc     loop8   
                mov     [es:di], bx
loop8:
                inc     di                           
                inc     di
                dec     dx
                jnz     DCB_8
                call    MidScanNextWin
DCB_8:
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
                sub     bp, 32
                mov     bx, cs:[currentColor]   ; get current draw color

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
                sub     bp, 48
                mov     bx, cs:[currentColor]   ; get current draw color

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
                sub     bp, 64
                mov     bx, cs:[currentColor]   ; get current draw color

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


