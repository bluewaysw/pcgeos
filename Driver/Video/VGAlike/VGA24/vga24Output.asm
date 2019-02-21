COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:           vga24Output.asm

AUTHOR:		Jim DeFrisco, Oct  7, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 7/92	Initial revision
        FR       9/24/97        24bit version created        

DESCRIPTION:
        Low-level rectangle drawing routines for TrueColor devices

        $Id: vga24Output.asm,v 1.2 96/08/05 03:51:43 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOptRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with draw mode GR_COPY and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of bytes covered by rectangle - 1
		cx - pattern index (scan line number AND 7)
		es:di - buffer address for first left:top of rectangle
		ds - Window structure
		bp - number of lines to draw
RETURN:		nothing	
DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawOptRect	proc	near

		; drawing a solid rectangle.  See if it's just one pixel wide,
		; and use the quick one...

NMEM <          mov     si, cs:[modeInfo].VMI_scanSize  ; optimization   >
                mov     bl, cs:[currentColor].RGB_blue
                mov     ax, {word} cs:[currentColor].RGB_red  ; get current color index
                xchg    al, ah                          ; different byte order

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line

		mov	cx, dx			; setup count
                mov     dx, cs:[pixelRestBytes]        

NMEM <          cmp     di, cs:[lastWinPtr]     ; is it in the last line   >
NMEM <          jae     firstPartial            ; check for complete line   >


lineLoop:
                push    cx, di
optLoop1:
                xchg    al, bl                  ; store one pixel
                stosb
                xchg    al, bl
                stosw
                add     di, dx                  ; next pixel
                loop    optLoop1

                pop     cx, di                  ; ptr to start position

		dec	bp			; fewer scans to do
		jz	done
NMEM <		NextScan di, si			; adj ptr to next scan line >
MEM <		NextScan di			; adj ptr to next scan line >
NMEM <          jc      lastWinLine             ; oops, on last line in win >
NMEM <		jmp	lineLoop					>
MEM <		tst	cs:[bm_scansNext]	; if negative, bogus	 >
MEM <		jns	lineLoop					>
done:
		ret

ifndef	IS_MEM
                ; first line is already an partial scan
firstPartial:
                clc                             ; ???
                call    SetNextWin              ; set pixles left correctly

		; the current line is no totally in the window, so take it slow
lastWinLine:
                cmp     cx, cs:[pixelsLeft]     ; if doing less, do normal
                jb      lineLoop

                push    cx                      ; save size 

		mov	cx, cs:[pixelsLeft]	; #pixels left in window
                jcxz    null0
optLoop2:
                xchg    al, bl                  ; put pixel
                stosb
                xchg    al, bl
                stosw
                add     di, dx                  ; next pixel
                loop    optLoop2
null0:
                pop     cx                      ; setup remaining count
                push    cx                      ; save size again
                sub     cx, cs:[pixelsLeft]

                xchg    al, ah
                call    PutSplitedPixel
                xchg    al, ah

                jcxz    null1
optLoop3:                                       ; put pixel
                xchg    al, bl
                stosb
                xchg    al, bl
                stosw
                add     di, dx                  ; next pixel position
                loop    optLoop3
null1:
                pop     cx
                dec     bp
                jz      done
		FirstWinScan			; set di to start of next
                jmp     lineLoop
endif		

DrawOptRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawNOTRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with draw mode MM_INVERT and all bits in the
		draw mask set

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of byte covered by rectangle - 1
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
RETURN:		nothing	
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawNOTRect	proc		near
		push	ds
NMEM <		mov	ds, cs:[readSegment]				>
MEM  <		segmov	ds, es						>

		; see if we can do it in one byte

NMEM <		mov	si, cs:[modeInfo].VMI_scanSize ; optimization	>
		clr	bh

		; calculate #bytes to write

		inc	dx			; number of bytes to draw

NMEM <          cmp     di, cs:[lastWinPtr]     ; is it in the last line   >
NMEM <          jae     firstPartial            ; check for complete line   >

lineLoop:
		mov	cx, dx			; setup count
notLoop:
                mov     bx, ds:[di]
                xor     bx, 0FFFFh
                mov     es:[di], bx
                mov     bl, ds:[di+2]
                xor     bl, 0FFh
                mov     es:[di+2], bl

                add     di, cs:[pixelBytes]

		loop	notLoop			; to loop or not to loop...

                push    ax, dx
                mov     ax, dx
                mul     cs:[pixelBytes]
                sub     di, ax                  ; restore scan pointer
                pop     ax, dx

		dec	bp			; fewer scans to do
		jz	done
NMEM <          NextScanBoth di,si              ; adjust ptr to next scan line>
NMEM <		jc	lastWinLine					      >
MEM <           NextScanBoth di                 ; adjust ptr to next scan line>
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	lineLoop
done:
		pop	ds
		ret

ifndef	IS_MEM
                ; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWin
                clc
                call    SetNextWinSrc

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
                jb      lineLoop
		mov	cx, cs:[pixelsLeft]	; #pixels left in window
                jcxz    null0
pixLoop1:
                mov     bx, ds:[di]
                xor     bx, 0FFFFh
                mov     es:[di], bx
                mov     bl, ds:[di+2]
                xor     bl, 0FFh
                mov     es:[di+2], bl

                add     di, cs:[pixelBytes]
		loop	pixLoop1
null0:
		mov	cx, dx			; setup remaining count
		sub	cx, cs:[pixelsLeft]

                cmp     cs:[restBytesSrc], 0
                jz      over
                
                mov     al, ds:[di]
                xor     al, 0xFF
                mov     ds:[di], al

                cmp     cs:[restBytesSrc], 1
                jz      over

                mov     al, ds:[di+1]
                xor     al, 0xFF
                mov     ds:[di+1], al

                cmp     cs:[restBytesSrc], 2
                jz      over

                mov     al, ds:[di+2]
                xor     al, 0xFF
                mov     ds:[di+2], al

over:
                call    MidScanNextWinSrc
                call    MidScanNextWin

                jcxz    done2

                cmp     cs:[restBytesSrc], 3
                jz      done3

                cmp     cs:[restBytesSrc], 2
                jz      left1

                cmp     cs:[restBytesSrc], 1
                jz      left2

                mov     al, ds:[di]
                xor     al, 0xFF
                mov     ds:[di], al
                inc     di
left2:
                mov     al, ds:[di]
                xor     al, 0xFF
                mov     ds:[di], al
                inc     di
left1:
                mov     al, ds:[di]
                xor     al, 0xFF
                mov     ds:[di], al
done3:
                mov     di, cs:[restBytesOverSrc]
                dec     cx
done2:
                jcxz    null1
pixLoop2:
                mov     bx, ds:[di]
                xor     bx, 0FFFFh
                mov     es:[di], bx
                mov     bl, ds:[di+2]
                xor     bl, 0FFh
                mov     es:[di+2], bl

                add     di, cs:[pixelBytes]
		loop	pixLoop2
null1:
		dec	bp
		jz	done
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif

DrawNOTRect	endp
ForceRef	DrawNOTRect


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpecialRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with a special draw mask or draw mode clipping
		left and right

CALLED BY:	INTERNAL
		DrawSimpleRect
PASS:		dx - number of words covered by rectangle - 1
		cx - pattern index
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
		si - low three bits of x position
RETURN:		nothing	
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
	REGISTER USAGE:
		es:di	- points into frame buffer
		si	- offset into 8-byte mask buffer
		al	- color
		bh	- one bit set to test mask buffer		 
		bl	- starting value for bh

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawSpecialRect	proc		near
		push	ds	
NMEM <		mov	ds, cs:[readSegment]				>
MEM  <		segmov	ds, es						>

		; setup ah to hold a bit flag to use in testing the mask
	
		mov	bl, 80h			; bit zero
		xchg	cx, si			; cx = low three bits of x pos
		and	cl, 7			
		shr	bl, cl			; ah = single bit tester
		mov	cx, si			; restore mask buffer index

		; calculate #bytes in the line, offset to next line

		inc	dx			; number of bytes
;                mov     si, cx                  ; mask index in si

NMEM <          cmp     di, cs:[lastWinPtr]     ; is it in the last line   >
NMEM <          LONG jae     firstPartial       ; check for complete line   >


lineLoop:
		push	di			; save pointer
		mov	cx, dx			; setup count
		mov	bh, bl			; reload tester
pixelLoop:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixelDone
                push    bx
                mov     ax, ds:[di]             ; get screen pixel
                mov     bl, ds:[di+2]
                xchg    al, bl
                call    cs:[modeRoutine]        ; apply mix mode
                xchg    al, bl
                mov     es:[di], ax             ; store result
                mov     es:[di+2], bl
                pop     bx
pixelDone:
                add     di, cs:[pixelBytes]
		shr	bh, 1			; testing next pixel
		jc	reloadTester
haveTester:
		loop	pixelLoop
		pop	di			; restore scan pointer
		dec	bp			; fewer scans to do
		jz	done
		inc	si			; next scan line
		and	si, 0x7
NMEM <          NextScanBoth di                 ; adjust ptr to next scan line>
NMEM <		jc	lastWinLine					>
MEM <           NextScanBoth di                                         >
MEM <		segmov	ds, es			; update source reg	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		jns	lineLoop					>
NMEM <		jmp	lineLoop					>
done:
		pop	ds
		ret

reloadTester:
		mov	bh, 80h
		jmp	haveTester

ifndef	IS_MEM
                ; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWin
                clc
                call    SetNextWinSrc

		; the current line is no totally in the window, so take it slow
lastWinLine:
                cmp     dx, cs:[pixelsLeft]     ; if doing less, do normal
                LONG jb lineLoop
		mov	bh, bl
		mov	cx, cs:[pixelsLeft]	; #pixels left in window
                jcxz    null0
pixLoop1:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixDone1
                push    bx
                mov     ax, ds:[di]             ; get screen pixel
                mov     bl, ds:[di+2]
                xchg    al, bl
                call    cs:[modeRoutine]        ; apply mix mode
                xchg    al, bl
                mov     es:[di], ax             ; store result
                mov     es:[di+2], bl
                pop     bx
pixDone1:
                add     di, cs:[pixelBytes]
                ror     bh, 1                   ; testing next pixel
		loop	pixLoop1
null0:
         
		mov	cx, dx			; setup remaining count
		sub	cx, cs:[pixelsLeft]

                push    bx

                test    cs:[maskBuffer][si], bh ; skip this pixel ?

                jz      maskout
                jmp     splitpix 
maskout:
;                tst     cx
;                jnz     go
;                cmp     cs:[restBytes], 0
;                jnz     done2
;go:
                call    MidScanNextWinSrc
                call    MidScanNextWin
                jcxz    done2
done4:
                jmp     done3

splitpix:
                cmp     cs:[restBytesSrc], 0
                jz      over
                
                mov     bl, ds:[di]
                call    cs:[modeRoutine]
                mov     ds:[di], bl

                cmp     cs:[restBytesSrc], 1
                jz      over

                mov     ah, ds:[di+1]
                call    cs:[modeRoutine]
                mov     ds:[di+1], ah

                cmp     cs:[restBytesSrc], 2
                jz      over

                mov     al, ds:[di+2]
                call    cs:[modeRoutine]
                mov     ds:[di+2], al

over:
                call    MidScanNextWinSrc
                call    MidScanNextWin

                jcxz    done2

                cmp     cs:[restBytesSrc], 3
                jz      done3

                cmp     cs:[restBytesSrc], 2
                jz      left1

                cmp     cs:[restBytesSrc], 1
                jz      left2

                mov     bl, ds:[di]
                call    cs:[modeRoutine]
                mov     ds:[di], bl
                inc     di
left2:          mov     ah, ds:[di]
                call    cs:[modeRoutine]
                mov     ds:[di], ah
                inc     di
left1:          mov     al, ds:[di]
                call    cs:[modeRoutine]
                mov     ds:[di], al

done3:
                mov     di, cs:[restBytesOverSrc]
                dec     cx
done2:
                pop     bx

                ror     bh
                jcxz    null1

pixLoop2:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixDone2
                push    bx
                mov     ax, ds:[di]             ; get screen pixel
                mov     bl, ds:[di+2]
                xchg    al, bl
                call    cs:[modeRoutine]        ; apply mix mode
                xchg    al, bl
                mov     es:[di], ax             ; store result
                mov     es:[di+2], bl
                pop     bx
pixDone2:
                add     di, cs:[pixelBytes]
                ror     bh, 1                   ; testing next pixel
		loop	pixLoop2
null1:
		dec	bp
		LONG jz	done
		FirstWinScan			; set di to start of next
		inc	si			; next scan line
		and	si, 0x7
		jmp	lineLoop
endif
		
DrawSpecialRect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MixModeRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various stub routines to implement mix modes

CALLED BY:	INTERNAL
		various low-level drawing routines
PASS:		ah - color
		al - screen
RETURN:		al - destination (byte to write out)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ModeRoutines        proc            near
        ForceRef ModeRoutines

ModeCLEAR       label near
                clr     ax
                clr     bl
ModeNOP         label near
		ret
ModeCOPY        label  near
                mov     ax, {word} cs:[currentColor].RGB_red
                mov     bl, cs:[currentColor].RGB_blue
		ret
ModeAND         label  near      
                and     ax, {word} cs:[currentColor].RGB_red
                and     bl, cs:[currentColor].RGB_blue
		ret
ModeINVERT      label  near
                xor     ax, 0FFFFh
                xor     bl, 0FFh
		ret
ModeXOR         label  near
                xor     ax, {word} cs:[currentColor].RGB_red
                xor     bl, cs:[currentColor].RGB_blue
		ret
ModeSET         label  near
                mov     ax, 0FFFFh
                mov     bl, 0FFh
		ret
ModeOR          label  near
                or      ax, {word} cs:[currentColor].RGB_red
                or      bl, cs:[currentColor].RGB_blue
		ret
ModeRoutines        endp

