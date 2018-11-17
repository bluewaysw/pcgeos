COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:           vga16Output.asm

AUTHOR:		Jim DeFrisco, Oct  7, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 7/92	Initial revision
        FR       9/ 4/97        16bit created        

DESCRIPTION:
        Low-level rectangle drawing routines for 16-bit devices

        $Id: vga16Output.asm,v 1.2$

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

NMEM <		mov	si, cs:[modeInfo].VMI_scanSize ; optimization	>
                mov     ax, cs:[currentColor]   ; get current color index
		tst	dx
		jz	oneByteWide

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line

NMEM <          cmp     di, cs:[lastWinPtr]     ; is it in the last line   >
NMEM <          jae     firstPartial            ; check for complete line   >

lineLoop:
		mov	cx, dx			; setup count
                rep     stosw                   ; fill in scan line
		sub	di, dx			; restore line pointer
                sub     di, dx                  ; 2 byte pixel
		dec	bp			; fewer scans to do
		jz	done
NMEM <		NextScan di, si			; adj ptr to next scan line >
MEM <		NextScan di			; adj ptr to next scan line >
NMEM <		jc	lastWinLine		; oops, on last line in win >
NMEM <		jmp	lineLoop					>
MEM <		tst	cs:[bm_scansNext]	; if negative, bogus	 >
MEM <		jns	lineLoop					>
done:
		ret

ifndef	IS_MEM
                ; first line is already an partial scan
firstPartial:
		clc
		call	SetNextWin

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
                jb      lineLoop
		mov	cx, cs:[pixelsLeft]	; #pixels left in window
                rep	stosw
		call	MidScanNextWin		; goto next window
                mov     cx, dx                  ; setup remaining count
                sub     cx, cs:[pixelsLeft]
                jcxz    null1
                rep     stosw                   ; do remaining part of line
null1:
                dec     bp
                jz      done
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif		

		; it's only a byte wide.  Do it quickly.
oneByteWide:
		mov	cx, bp			; get line count in cd
oneLoop:
                mov     es:[di], ax             ; store the color
		dec	cx			; one less line to do
		jz	done
NMEM <		NextScan di, si			; always enuf room todo 1 pix >
MEM <		NextScan di			; always enuf room todo 1 pix >
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneLoop

DrawOptRect	endp


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

		; check for one byte wide

		tst	dx
		jz	oneByteWide

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
                mov     ax, ds:[di]             ; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
                mov     es:[di], ax             ; store result
pixelDone:
                inc     di
		inc	di
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

oneByteWide:
		mov	si, cx			; mask index in si
		mov	bh, bl			; reload tester
oneByteLoop:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	lineDone
                mov     ax, ds:[di]             ; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
                mov     es:[di], ax             ; store result
lineDone:
		dec	bp			; fewer scans to do
		jz	done
		inc	si			; next scan line
		and	si, 0x7
NMEM <          NextScanBoth di                 ; adjust ptr to next scan line>
MEM <           NextScanBoth di                 ; adjust ptr to next scan line>
MEM <		segmov	ds, es			; reload source reg	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneByteLoop

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
pixLoop1:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixDone1
                mov     ax, ds:[di]             ; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
                mov     es:[di], ax             ; store result
pixDone1:
		inc	di
                inc     di
		shr	bh, 1			; testing next pixel
		jnc	nextPix1
		mov	bh, 80h
nextPix1:
		loop	pixLoop1
		call	MidScanNextWinSrc	; goto next window
		call	MidScanNextWin		; goto next window
		mov	cx, dx			; setup remaining count
		sub	cx, cs:[pixelsLeft]
                jcxz    null1
pixLoop2:
		test	cs:[maskBuffer][si], bh	; skip this pixel ?
		jz	pixDone2
                mov     ax, ds:[di]             ; get screen pixel
		call	cs:[modeRoutine]	; apply mix mode
                mov     es:[di], ax             ; store result
pixDone2:
		inc	di
                inc     di
		shr	bh, 1			; testing next pixel
		jnc	nextPix2
		mov	bh, 80h
nextPix2:
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
ModeRoutines	proc	near
		ForceRef ModeRoutines

ModeCLEAR	label near	
                clr     ax
ModeNOP		label near
		ret
ModeCOPY	label  near	
                mov     ax, cs:[currentColor]
		ret
ModeAND		label  near		
                and     ax, cs:[currentColor]
		ret
ModeINVERT	label  near
                xor     ax, 0FFFFh
		ret
ModeXOR		label  near	
                xor     ax, cs:[currentColor]
		ret
ModeSET		label  near	
                mov     ax, 0xFFFF
		ret
ModeOR		label  near	
                or      ax, cs:[currentColor]
		ret
ModeRoutines	endp

