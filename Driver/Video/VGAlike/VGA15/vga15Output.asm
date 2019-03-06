COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

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

        $Id: vga16Output.asm,v 1.2 96/08/05 03:51:43 canavese Exp $

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

		; check the dither flag and do the right thing

		test	cs:[driverState], mask VS_DITHER
		LONG jnz	BlastDitheredRect

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
		BlastDitheredRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle in MM_COPY, mask all 1s, dithered.

CALLED BY:	INTERNAL
		DrawOptRect
PASS:		dx - number of words covered by rectangle + 1
		cx - pattern index (scan line number AND 7)
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
RETURN:		nothing	
DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		We have a 4x4 ditherMatrix, so align stuff and copy the 
		four bytes across in the right order.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredRect proc	near

		; setup some stuff.  Get index to point at beginning of
		; ditherMatrix scan line (each 4 bytes), get scan size

		call	SetTempDither		; setup tempDither matrix
		mov	bx, cx			; line offset in bx
		shl	bx, 1			; *4
		shl	bx, 1
                shl     bx, 1
                and     bx, 0x018               ; pointer into tempDither
NMEM <		mov	si, cs:[modeInfo].VMI_scanSize ; optimization	>

		tst	dx
		jz	oneByteWide

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line

NMEM <          cmp     di, cs:[lastWinPtr]     ; is it in the last line  >
NMEM <          jae     firstPartial            ; check for complete line  >

lineLoop:
		call	BlastDitheredScan	; do a scan line
		dec	bp			; fewer scans to do
		jz	done
                add     bl, 8                   ; onto next scan
                and     bl, 0x18                ; limit it to 16 bytes
NMEM <		NextScan di,si			; adjust ptr to next scan line>
NMEM <		jc	lastWinLine		; oops, on last line in wind.>
MEM <		NextScan di			; adjust ptr to next scan line>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		jns	lineLoop					>
NMEM <		jmp	lineLoop					>
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
		push	dx
		mov	dx, cs:[pixelsLeft]
		call	BlastDitheredScan
		call	MidScanNextWin		; goto next window
		pop	dx
		push	dx
		sub	dx, cs:[pixelsLeft]
                tst     dx
                jz      null1
                call	BlastDitheredScan
null1:
		pop	dx
		dec	bp
		jz	done
                add     bl, 8                   ; onto next scan
                and     bl, 0x18                ; limit it to 16 bytes
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif		

		; it's only a byte wide.  Do it quickly.
oneByteWide:
                mov     ax, cs:[tempDither][bx]
                mov     es:[di], ax             ; store the color
		dec	bp			; one less line to do
		jz	done
                add     bl, 8
                and     bl, 0x18
NMEM <		NextScan di, si			; always enuf room todo 1 pix >
MEM <		NextScan di			; always enuf room todo 1 pix >
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneByteWide
BlastDitheredRect endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastDitheredScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a single scan line of dither stuff

CALLED BY:	BlastDitheredRect
PASS:		bx	- offset into tempDither of current scan line
		dx	- #pixels to write
		es:di	- points at starting pixel
		tempDither	- already setup (entries rotated in X so
				  that the first element in each scan is
				  the Nth element in the ditherMatrix scan
				  where N=(left side of rect) AND 7

RETURN:		nothing
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredScan	proc	near
                uses    bp, si

                .enter
		mov	ax, {word} cs:[tempDither][bx]
		mov	cx, {word} cs:[tempDither][bx+2]
                mov     bp, {word} cs:[tempDither][bx+4]
                mov     si, {word} cs:[tempDither][bx+6]
		push	dx
		jmp	startLine
pixLoop:
                stosw                           ; first byte
                mov     es:[di], cx
		inc	di
                inc     di
                mov     es:[di], bp
		inc	di
                inc     di
                mov     es:[di], si
		inc	di
                inc     di
startLine:
		sub	dx, 4
		jns	pixLoop

		; down to less than 4 pixels on the scan line, do one at a time

		add	dx, 4
		jz	doneLine
                stosw
		dec	dx
		jz	doneLine
                mov     es:[di], cx
		inc	di
                inc     di
		dec	dx
		jz	doneLine
                mov     es:[di], bp
		inc	di
                inc     di
doneLine:
		pop	dx
                shl     dx, 1                   ; 1 pixel = 2 bytes
		sub	di, dx			; restore line pointer
                shr     dx, 1
                .leave
                ret
BlastDitheredScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTempDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Optimization to setup a temporary dither matrix with the
		scan lines rotated in x to reflect which pixel we are 
		starting on (enables more efficient drawing routines)
CALLED BY:	INTERNAL
PASS:		si	- x offset (at least low two bits of it)
RETURN:		nothing
DESTROYED:	al, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTempDither   proc    near

                test    cs:[driverState], mask VS_DITHER
                jnz     handleDither

                mov     ax,cs:[currentColor]

                mov     word ptr cs:[tempDither],ax
                mov     word ptr cs:[tempDither+2],ax   
                mov     word ptr cs:[tempDither+4],ax   
                mov     word ptr cs:[tempDither+6],ax 
                mov     word ptr cs:[tempDither+8],ax 
                mov     word ptr cs:[tempDither+10],ax   
                mov     word ptr cs:[tempDither+12],ax  
                mov     word ptr cs:[tempDither+14],ax    
                mov     word ptr cs:[tempDither+16],ax     
                mov     word ptr cs:[tempDither+18],ax  
                mov     word ptr cs:[tempDither+20],ax    
                mov     word ptr cs:[tempDither+22],ax  
                mov     word ptr cs:[tempDither+24],ax   
                mov     word ptr cs:[tempDither+26],ax    
                mov     word ptr cs:[tempDither+28],ax    
                mov     word ptr cs:[tempDither+30],ax   

done:
                retn                                 

handleDither:
                push      si

                and       si,3
                mov       ax, si
                shl       ax, 1
                mov       si, ax

                mov     ax,word ptr cs:[ditherMatrix]     
                mov     word ptr cs:[tempDither][si],ax   
                mov     ax,word ptr cs:[ditherMatrix+8]   
                mov     word ptr cs:[tempDither+8][si],ax 
                mov     ax,word ptr cs:[ditherMatrix+16]   
                mov     word ptr cs:[tempDither+16][si],ax 
                mov     ax,word ptr cs:[ditherMatrix+24]  
                mov     word ptr cs:[tempDither+24][si],ax

                mov     si, cs:ditherRotTab[si]

                mov     ax,word ptr cs:[ditherMatrix+2]   
                mov     word ptr cs:[tempDither][si],ax  
                mov     ax,word ptr cs:[ditherMatrix+10]  
                mov     word ptr cs:[tempDither+8][si],ax
                mov     ax,word ptr cs:[ditherMatrix+18]  
                mov     word ptr cs:[tempDither+16][si],ax
                mov     ax,word ptr cs:[ditherMatrix+26] 
                mov     word ptr cs:[tempDither+24][si],ax

                mov     si, cs:ditherRotTab[si]

                mov     ax,word ptr cs:[ditherMatrix+4]    
                mov     word ptr cs:[tempDither][si],ax   
                mov     ax,word ptr cs:[ditherMatrix+12]  
                mov     word ptr cs:[tempDither+8][si],ax 
                mov     ax,word ptr cs:[ditherMatrix+20]   
                mov     word ptr cs:[tempDither+16][si],ax 
                mov     ax,word ptr cs:[ditherMatrix+28]  
                mov     word ptr cs:[tempDither+24][si],ax

                mov     si, cs:ditherRotTab[si]

                mov     ax,word ptr cs:[ditherMatrix+6]    
                mov     word ptr cs:[tempDither][si],ax  
                mov     ax,word ptr cs:[ditherMatrix+14]   
                mov     word ptr cs:[tempDither+8][si],ax 
                mov     ax,word ptr cs:[ditherMatrix+22]   
                mov     word ptr cs:[tempDither+16][si],ax 
                mov     ax,word ptr cs:[ditherMatrix+30]  
                mov     word ptr cs:[tempDither+24][si],ax

                pop     si
                jmp     done

ditherRotTab    dw      2,4,6,0,2,4

SetTempDither   endp

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
		tst	dx
		jz	oneByteWide	

		; calculate #bytes to write

		inc	dx			; number of bytes to draw

NMEM <          cmp     di, cs:[lastWinPtr]     ; is it in the last line   >
NMEM <          jae     firstPartial            ; check for complete line   >

lineLoop:
		mov	cx, dx			; setup count
notLoop:
                mov     bx, ds:[di]
                xor     bx, 07FFFh
                mov     es:[di], bx
		inc	di
                inc     di                      ; 2 byte pixel
		loop	notLoop			; to loop or not to loop...
		sub	di, dx			; restore scan pointer
                sub     di, dx                  ; 1 pixel = 2 bytes
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

		; it's only a byte wide.  Do it quickly.
oneByteWide:
		mov	cx, bp			; get line count in cd
oneLoop:
                mov     bx, ds:[di]
                xor     bx, 07FFFh
                mov     es:[di], bx
		dec	cx			; one less line to do
		jz	done
NMEM <          NextScanBoth di,si                                          >
MEM <		NextScan di						>
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneLoop

ifndef	IS_MEM
                ; first line is already an partial scan
firstPartial:
                clc
                call    SetNextWinSrc
		clc
		call	SetNextWin

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
                jb      lineLoop
		mov	cx, cs:[pixelsLeft]	; #pixels left in window
pixLoop1:
                mov     bx, ds:[di]
                xor     bx, 07FFFh
                mov     es:[di], bx
		inc	di
                inc     di
		loop	pixLoop1
		call	MidScanNextWinSrc	; goto next window
		call	MidScanNextWin		; goto next window
		mov	cx, dx			; setup remaining count
		sub	cx, cs:[pixelsLeft]
                jcxz    null1
pixLoop2:
                mov     bx, ds:[di]
                xor     bx, 07FFFh
                mov     es:[di], bx
		inc	di
                inc     di
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

		; check the dither flag and do the right thing

		test	cs:[driverState], mask VS_DITHER
		LONG jnz	SpecialDitheredRect

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
		SpecialDitheredRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a dithered rectangle, some random mix mode, w/draw mask

CALLED BY:	INTERNAL
		DrawSpecialRect
PASS:		dx - number of words covered by rectangle - 1
		cx - pattern index
		es:di - buffer address for first left:top of rectangle
		bp - number of lines to draw
		si - low three bits of x position
RETURN:		nothing	
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpecialDitheredRect proc	near

		; setup some stuff.  Get index to point at beginning of
		; ditherMatrix scan line (each 4 bytes), get scan size

		push	si
		call	SetTempDither		; setup tempDither matrix
		pop	si
		mov	bx, cx			; line offset in bx
		xchg	si, cx			; in si too.  xoffset in cx
                shl     bx, 1                   ; *8
		shl	bx, 1
                shl     bx, 1
                and     bx, 0x018               ; pointer into tempDither
		and	cx, 0x7			; need low three bits

		tst	dx
		jz	oneByteWide

		; calculate #bytes in the middle of the line and
		; offset to next line

		inc	dx			; total #bytes in line

NMEM <          cmp     di, cs:[lastWinPtr]     ; is it in the last line   >
NMEM <          jae     firstPartial            ; check for complete line   >

lineLoop:
		call	BlastDitheredMaskedScan	; do a scan line
		dec	bp			; fewer scans to do
		jz	done
                add     bl, 8                   ; onto next scan
                and     bl, 0x18                ; limit it to 16 bytes
		inc	si			; next mask scan
		and	si, 7
NMEM <          NextScanBoth di                 ; adjust ptr to next scan >
NMEM <		jc	lastWinLine		; oops, on last line in wind.>
MEM <           NextScanBoth di                 ; adjust ptr to next scan >
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		jns	lineLoop					>
NMEM <		jmp	lineLoop					>
done:
		pop	ds			; pushed in DrawSpecialRect
		ret

		; it's only a byte wide.  Do it quickly.
oneByteWide:
                mov     ch, 080h
                shr     ch, cl
                mov     ax, cs:[tempDither][bx]
                call    WriteSpecialPixel
                dec     di
                dec     di

		dec	bp			; one less line to do
		jz	done
                add     bl, 8
                and     bl, 0x18
		inc	si
		and	si, 7
NMEM <          NextScanBoth di                     ; always enuf room todo 1 pix >
MEM <		NextScan di			; always enuf room todo 1 pix >
MEM <		segmov	ds, es			; make sure they match 	>
MEM <		tst	cs:[bm_scansNext]	;			>
MEM <		js	done						>
		jmp	oneByteWide

ifndef	IS_MEM

                ; first line is already an partial scan
firstPartial:
                clc
                call    SetNextWinSrc
		clc
		call	SetNextWin

		; the current line is no totally in the window, so take it slow
lastWinLine:
		cmp	dx, cs:[pixelsLeft]	; if doing less, do normal
                jb      lineLoop
                push    cx
		push	dx
		mov	dx, cs:[pixelsLeft]
		call	BlastDitheredMaskedScan
		call	MidScanNextWinSrc	; goto next window
		call	MidScanNextWin		; goto next window
		pop	dx
		push	dx
		sub	dx, cs:[pixelsLeft]

                add     cx,cs:[pixelsLeft]
                and     cx,0007h

                tst     dx
                jz      null1

                call	BlastDitheredMaskedScan
null1:
		pop	dx
                pop     cx
		dec	bp
		jz	done
                add     bl, 8                   ; onto next scan
                and     bl, 0x18                ; limit it to 16 bytes
		inc	si
		and	si, 7			; limit to size of mask buffer
		FirstWinScan			; set di to start of next
		jmp	lineLoop
endif		
SpecialDitheredRect endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlastDitheredMaskedScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a scan line, dithered, with a draw mask

CALLED BY:	INTERNAL
		SpecialDitheredRect
PASS:		bx	- offset into tempDither of current scan line
		dx	- #pixels to write
		cl	- low three bits of left side x position
		es:di	- points at starting pixel
		tempDither	- already setup (entries rotated in X so
				  that the first element in each scan is
				  the Nth element in the ditherMatrix scan
				  where N=(left side of rect) AND 7
RETURN:		
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlastDitheredMaskedScan		proc	near
                uses    bx, cx, bp, si
		.enter

		; setup ch to hold a bit flag to use in testing the mask
	
		mov	ch, 80h			; bit zero
		shr	ch, cl			; ah = single bit tester

		mov	cl, al			; al gets trashed all the time
		push	dx
		jmp	startLine
pixLoop:
		mov	ax, {word} cs:[tempDither][bx]
		call	WriteSpecialPixel

                mov     ax, {word} cs:[tempDither][bx+2]
		call	WriteSpecialPixel

                mov     ax, {word} cs:[tempDither][bx+4]
		call	WriteSpecialPixel

                mov     ax, {word} cs:[tempDither][bx+6]
		call	WriteSpecialPixel
startLine:
		sub	dx, 4
		jns	pixLoop

		; down to less than 4 pixels on the scan line, do one at a time

		add	dx, 4
		jz	doneLine
		mov	ax, {word} cs:[tempDither][bx]
		call	WriteSpecialPixel

		dec	dx
		jz	doneLine
                mov     ax, {word} cs:[tempDither+2][bx]
		call	WriteSpecialPixel

		dec	dx
		jz	doneLine
                mov     ax, {word} cs:[tempDither+4][bx]
		call	WriteSpecialPixel
doneLine:
		pop	dx
		sub	di, dx			; restore line pointer
                sub     di, dx

		.leave
		ret

BlastDitheredMaskedScan		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSpecialPixel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lots of stuff to do, mask, dither, mix a pixel

CALLED BY:	BlastDitheredMaskedScan
PASS:		ch	- current mask bit
		ah	- color to use
		es:di	- frame buffer pointer
		si	- mask buffer index
RETURN:		ch	- advanced to next pixel
		di	- points at next pixel
DESTROYED:	al

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteSpecialPixel proc	near
		test	ch, cs:[maskBuffer][si]
		jz	donePix
                push    cs:[currentColor]
                mov     cs:[currentColor], ax
                mov     ax, ds:[di]
		call	cs:[modeRoutine]
                mov     es:[di], ax
                mov     ax, cs:[currentColor]
                pop     cs:[currentColor]
donePix:
		inc	di
                inc     di
		shr	ch, 1
		jc	reloadMask
		ret
reloadMask:
		mov	ch, 0x80
		ret
WriteSpecialPixel endp


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
                xor     ax, 07FFFh
		ret
ModeXOR		label  near	
                xor     ax, cs:[currentColor]
		ret
ModeSET		label  near	
                mov     ax, 0x7FFF
		ret
ModeOR		label  near	
                or      ax, cs:[currentColor]
		ret
ModeRoutines	endp

