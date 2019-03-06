COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		vga8Pointer.asm

AUTHOR:		Jim DeFrisco, Oct  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/ 8/92	Initial revision

DESCRIPTION:
	These are a set of routines to support the use of a cursor for
	the pointing device.
		
	The cursor is limited to a 16x16 pixel bitmap (by the sizing 
	of the holding buffers).  

	The definition of a pointer allows for the specification of a "hot
	spot".  This indicates where on the cursor shape the "current
	position" should be reported as.

	The way the mask and image are combined with the background are as
	follows:

		mask	image	->	screen
		pixel	pixel		pixel
		-----	-----		------
		  0	  0		unchanged
		  0	  1		xor
		  1	  0		black
		  1	  1		white

	For the 8-bit video drivers, we need to store the image in a 
	buffer local to the video driver.  Since there is no shifting 
	required, we only need to establish the size of the transfer and
	the starting positions.

		(screen AND (not MASK)) XOR IMAGE
	We'll also use a local buffer to store the image the cursor sits
	on top of.

	$Id: vga8Pointer.asm,v 1.2 96/08/05 03:51:47 canavese Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidHidePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the graphics pointer 

CALLED BY:	EXTERNAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	if (EraseCursor called)
		   ax,bx,cx,dx,si,di,bp,es are destroyed
		else
		   nothing destroyed

PSEUDO CODE/STRATEGY:
	 	increment the visible count
		If the visible count is 1
		   erase the cursor
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidHidePtr	proc	near
	inc	cs:[cursorCount]	; increment the nesting count
	cmp	cs:[cursorCount],1	; if the cursor wasn't showing
	jnz	VHP_done		;  then all done 
	push	es
	push	ds
	mov	cx, cs
	mov	ds, cx
	call	EraseCursor		;  else erase it
	pop	ds
	pop	es
VHP_done:
	ret

VidHidePtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidShowPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the graphics pointer 

CALLED BY:	EXTERNAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	if pointer is redrawn
		   ax,bx,cx,dx,si,di,bp
		else
		   cx, di destroyed

PSEUDO CODE/STRATEGY:
		If the visible count is 0
		   draw the cursor
		else
		   just decrement the count
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidShowPtr	proc	near
	dec	cs:[cursorCount]	; set new value for nest count
EC <	ERROR_S	VIDEO_HIDE_CURSOR_COUNT_UNDERFLOW			>
	jnz	VShP_done
	push	es
	push	ds
	mov	cx, cs
	mov	ds, cx
	call	DrawCursor		;  yes, draw it
	pop	ds
	pop	es
VShP_done:
	ret

VidShowPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidMovePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the position of the pointer

CALLED BY:	INTERNAL

PASS:		ax	- new x position
		bx	- new y position

RETURN:		al	- mask of save-under areas that pointer hot-spot
			  overlaps with

DESTROYED:	ah,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		if (cursor is showing)
		   erase it;
		translate position to account for hot point;
		update the position variables;
		if (cursor was showing)
		   draw it;
		test for save-under overlaps;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidMovePtr	proc	near
	mov	cx,cs
	mov	ds,cx

	; erase cursor if visible

	cmp	cs:[cursorCount],0
	jnz	AfterCursorRedrawn

	push	ax
	push	bx

	call	EraseCursor

	; if moving XOR region with pointer then do special stuff

	cmp	cs:[xorFlags], 0
	jz	noXOR
	pop	bx
	pop	ax
	push	ax
	push	bx
	sub	ax, cs:[cursorX]
	sub	bx, cs:[cursorY]
	call	UpdateXORForPtr
noXOR:

	; store new position

	pop	ds:[cursorY]
	pop	ds:[cursorX]

	call	DrawCursor
	jmp	common

AfterCursorRedrawn:

	; store new position

	mov	ds:[cursorX],ax
	mov	ds:[cursorY],bx

common:
;	cmp	cs:[suCount], 0			; any active save under areas?
;	jne	CheckSUAreas
	clr	al
	ret

if (0)
CheckSUAreas:
	mov	ax, ds:[cursorX]		; Fetch location to check at
	mov	bx, ds:[cursorY]
	mov	cx, ax				; Pass rectangle = point
	mov	dx, bx
	GOTO	VidCheckUnder
endif

VidMovePtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the picture data for the pointer cursor

CALLED BY:	EXTERNAL

PASS:		ds:si contains a far pointer to the following structure:

		PointerDef defined in cursor.def
	
		if si == -1, then the default pointer shape is used
RETURN:		nothing

DESTROYED:	(if pointer erased and redrawn)
		   ax,bx,cx,dx,si,di,bp,ds
		else
		   ax,bx,cx,si,di,bp,ds

PSEUDO CODE/STRATEGY:
		pre-shift and store the correct mask and image data into
		some extra screen memory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Currently cursor size is fixed at 16x16 pixels.  The
		pointer definition structure contains width and height
		fields anyway.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/92...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSetPtr	proc	near
	push	es
	cmp	cs:[cursorCount], 0	; see if it's currently on-screen
	jnz	VSPnoshow		;  no, safe to proceed
	push	ds			; save passed params
	push	si
	segmov	ds, cs			; erase cursor wants ds -> cs
	call	EraseCursor		;  yes, restore screen before changing
	pop	si
	pop	ds
VSPnoshow:
	cmp	si, -1			;custom pointer ?
	jne	VSP_custom
	segmov	ds,cs
	mov	si, offset pBasic
VSP_custom:

	; ds:si = structure
	; translate old current position to new one, based on new hotpoint

EC <	mov	bl, ds:[si].PD_width					>
EC <    and     bl, mask PDW_WIDTH      ; Get width portion of byte     > 
EC <	cmp	bl, 16			; only support these for now	>
EC <	ERROR_NE VIDEO_ONLY_SUPPORTS_16x16_CURSORS			>
	mov	bx,word ptr ds:[si][PD_hotX]	;bl = hotX, bh = hotY
	mov	cs:[cursorHotX], bl	; store new x hot point
	mov	cs:[cursorHotY], bh	; store new y hot point

	; get pointer to cursor data.  We're going to copy the data to the area
	; just past the bottom of the screen.  First the mask, with 8 copies
	; (each 3 bytes) each shifted one more pixel to the right.  This is
	; followed by the same treatment for the data.

	add	si, size PointerDef	; ds:si -> mask data

	; set the destination to be the buffer we have to store the mask

	segmov	es, cs
	mov	di, offset ptrMaskBuffer 
	mov	cx, size ptrMaskBuffer	; clearing mask and picture 
        mov     al, 0xff
        rep     stosb                   ; clear the buffer, but do something
	mov	cx, size ptrMaskBuffer	;  different for the picture (we xor 
        mov     ax, 0xff                ;  the picy
        rep     stosb

	; first do the mask.  

	mov	di, offset ptrMaskBuffer
	mov	dx, CUR_SIZE		; 16 scan lines
maskLoop:
	lodsw				; get next word (scan) of mask data
	xchg	al,ah
	mov	bx, ax
        clr     ax
	mov	cx, CUR_SIZE		; 16 pixels/scan
mPixLoop:
	shl	bx, 1			; top bit into carry
	jnc	mSkipOne
        mov     es:[di], ax
        mov     es:[di+2], al        
mSkipOne:
        add     di, 3
	loop	mPixLoop		; do entire scan line
	dec	dx
	jnz	maskLoop		; do all of mask	

	; now do the picture data.  

	mov	dx, CUR_SIZE		; 16 scan lines
pictureLoop:
	lodsw				; get next word (scan) of picture data
	xchg	al,ah
	mov	bx, ax
        clr     ax
	mov	cx, CUR_SIZE		; 16 pixels/scan
pPixLoop:
	shl	bx, 1			; top bit into carry
	jc	pSkipOne
        mov     es:[di], ax
        mov     es:[di+2], al
pSkipOne:
        add     di, 3
	loop	pPixLoop		; do entire scan line
	dec	dx
	jnz	pictureLoop		; do all of mask	

	; draw new cursor

	cmp	cs:[cursorCount],0
	jnz	VSP_done
	push	ds
	segmov	ds, cs			;EraseCursor wants ds == cs
	call	DrawCursor
	pop	ds
VSP_done:
	pop	es
	ret

VidSetPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CondHidePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Temporarily hide the pointer while in a drawing operation

CALLED BY:	INTERNAL
		CommonRectHigh
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CondHidePtr	proc	near
	cmp	cs:[cursorCount],0	;test for hidden
	jnz	THP_ret
	cmp	cs:[hiddenFlag],0
	jnz	THP_ret
	push	ax, bx, cx, dx, si, di, bp, ds, es

	segmov	ds,cs			;point at variables
	mov	ds:[hiddenFlag],1	;set hidden
	call	EraseCursor

	pop	ax, bx, cx, dx, si, di, bp, ds, es
THP_ret:
	ret

CondHidePtr	endp
	public	CondHidePtr


CondShowPtrFar	proc	far
	push	bp
	call	CondShowPtr
	pop	bp
	ret
CondShowPtrFar	endp

CondShowPtr	proc	near
	push	ds, es
	segmov	ds,cs			;point at variables
	mov	ds:[hiddenFlag],0
	call	DrawCursor
	pop	ds, es
	ret

CondShowPtr	endp
	public	CondShowPtr


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the cursor when the optimization variables might be
		incorrect
CALLED BY:	INTERNAL
		VidSetPtr, VidMovePtr
PASS:		cursorX, cursorY - cursor position
		cursorHotX, cursorHotY - cursor hot spot
RETURN:		
DESTROYED:	
		ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:
		We have pre-shifted versions of the cursor mask and image.
		So we want to figure out which one to use (low three bits)
		and do the right transfer (on byte boundaries), taking into
		account any clipping (transfer fewer bytes if clipped).

		To effect the transfer, we use the bitblt hardware on the 
		casio device.  The BIOS calls are:

			SET_DMA_TRANSFER_OFFSET(mask)
			DO_DMA_TRANSFER(OR mode)
			SET_DMA_TRANSFER_OFFSET(picture)
			DO_DMA_TRANSFER(XOR mode)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCursor	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter

		mov	ax, cs:[cursorX]	; calc position to draw 
		mov	bx, cs:[cursorY]
		sub	al, cs:[cursorHotX]
		sbb	ah, 0
		sub	bl, cs:[cursorHotY]
		sbb	bh, 0			; ax,bx = cursor position

		; we'll need to calc the width and the height of the 
		; transfer, so start out by assuming the full cursor size
		; cl = width, ch = height, dl = left offset, dh = scan offset

		clr	dx
		mov	cl, CUR_SIZE
		mov	ch, cl

		; do different stuff if off left of screen 
	
		tst	ax			; check for neg coord
		LONG js	offLeft

		; OK, it may be entirely inside the screen.  Check the right.
	
		mov	si, cs:[DriverTable].VDI_pageW	; get right side coord
		sub	si, CUR_SIZE
		cmp	ax, si			; check right side
		LONG ja	offRight		;  else clip right side

		; If we are off the screen on top, then we need to adjust 
		; the Y offset, else we are starting from scan line 320.
checkHeight:
		tst	bx			; see if off the top
		LONG js	offTop			;  take less-traveled road

		mov	si, cs:[DriverTable].VDI_pageH
		sub	si, CUR_SIZE
		cmp	bx, si			; check off the bottom too
		LONG ja	offBottom

		; all ready to set the offsets, go for it.
		; cl = width, ch = height, dl = left offset, dh = scan offset
		; usage:ds:si -> pointer data
		; 	es:di -> frame buffer
		; 	bx = offset into scan line
		;	dx = offset from one scan line to the next
		; 	bp = bytes left in this window
		; 	ah = height
calcIndex:
		mov	cs:[cursorRegLeft], ax
		mov	cs:[cursorRegTop], bx
		add	al, cl
		adc	ah, 0
		dec	ax
		mov	cs:[cursorRegRight], ax
		inc	ax
		sub	al, cl
		sbb	ah, 0
		add	bl, ch
		adc	bh, 0
		dec	bx
		mov	cs:[cursorRegBottom], bx
		inc	bx
		sub	bl, ch
		sbb	bh, 0
		mov	cs:[backX], ax
		mov	cs:[backY], bx
		mov	cs:[backWidth], cl
		mov	cs:[backHeight], ch
		shl	dh, 1			; *16 for scan index
		shl	dh, 1
		shl	dh, 1
		shl	dh, 1
		add	dl, dh
		clr	dh			; dx = byte offset into picture
		mov	si, offset ptrMaskBuffer ; figure source address
		add	si, dx			; 
                add     si, dx
                add     si, dx
		segmov	ds, cs			; ds:si -> maskBuffer (source)

		mov	di, bx
		mov	bx, ax
                push    bx
                CalcLineOffset  bx
		CalcScanLineBoth di, bx, es, ds	; ds,es:[di] -> destination
                pop     bx
		mov	bp, cs:[curWinEnd]	; calc #bytes left
		sub	bp, di			; bp = #bytes left 
		mov	dx, cs:[modeInfo].VMI_scanSize ; get bytes per scan
		mov	ah, ch			; ah = height
		mov	ch, cl			; ch,cl = width

		mov	bx, offset cs:backBuffer

                cmp     dx, 4096
                jae     care

		mov	cl, 4
		shl	dx, cl			; see if we're gonna be past
		cmp	dx, bp			; going to overflow window ?
		mov	cl, ch			; copy width back again
                jbe     drawLoop
care:
                clc
		push	di
		pushf
                call    SetNextWinSrc
		popf
		pop	di
                call    SetNextWin

                jnc     careScanLoop

                xor     ch, ch
                cmp     cx, word ptr cs:[pixelsLeft]  

                LONG ja      splitStart
                jmp     careScanLoop

		; finally, draw the sucker
		; ds:di	-> frame buffer (read window)
		; es:di -> frame buffer (write window)
		; cl, ch - width loop counters
		; ah     - height loop counter
		; al	 - scratch register
		; cs:si	 - offset into cursor definition buffer
		; cs:bx	 - offset into background save buffer
drawLoop:
		mov	ch, cl			; reload width
                push    ax
pixLoop:
                mov     ax, ds:[di]             ; get screen data
                mov     cs:[bx], ax             ; store background
                and     ax, cs:[si]             ; or in the mask
                xor     ax, cs:[si+768]         ; xor the picture data
                stosw
		inc	si
                inc     si
		inc	bx
                inc     bx
                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx], al             ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                add     di, cs:[pixelRestBytes]
                inc     si
		inc	bx
		dec	ch
		jnz	pixLoop
                pop     ax

                push    ax, dx
                mov     ax, cx
                mul     cs:[pixelBytes]
                sub     di, ax
                add     si, 48
                sub     si, cx
                sub     si, cx
                sub     si, cx
                pop     ax, dx

		add	di, cs:[modeInfo].VMI_scanSize
		dec	ah
		jnz	drawLoop
done:
		.leave
		ret

		; off the left side of the screen.  This gets a bit complex.
offLeft:
		neg	ax			; that many bits over
		mov	dl, al			; start in from the left
		sub	cl, al			; that means fewer scans
		clr	ax
		jmp	checkHeight

		; off the right side of the screen. This just means we
		; transfer fewer bytes in width.
offRight:
		sub	si, ax			; assume one less
		xchg	si, ax
		add	cl, al			; cl = #bytes wide
		xchg	si, ax
		jmp	checkHeight
		
		; the cursor is off the top of the screen. Adjust accordingly
offTop:
		neg	bx			; bl = #scans off top
		mov	dh, bl			; dh = scan index
		sub	ch, bl			; do that many less
		clr	bx
		jmp	calcIndex

		; this is simple.  We just need to reduce the number of scan
		; lines to copy.
offBottom:
		sub	si, bx			; bx = -(#lines to shorten)
		xchg	si, bx
		add	ch, bl			; make it shorter
		xchg	si, bx
		jmp	calcIndex
		
		; section of code to deal with drawing the cursor when we
		; are getting close to the end of the memory window.
careScanLoop:
		mov	ch, cl			; reload width
                push    ax
carePixLoop:
                mov     ax, ds:[di]             ; get screen data
                mov     cs:[bx], ax             ; store background
                and     ax, cs:[si]             ; or in the mask
                xor     ax, cs:[si+768]         ; xor the picture data
                stosw
		inc	si
                inc     si
		inc	bx
                inc     bx
                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx], al             ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                add     di, cs:[pixelRestBytes]
                inc     si
		inc	bx
		dec	ch
		jnz	carePixLoop
                pop     ax

                push    ax, dx
                mov     ax, cx
                mul     cs:[pixelBytes]
                sub     di, ax
                add     si, 48
                sub     si, cx
                sub     si, cx
                sub     si, cx
                pop     ax, dx

		dec	ah
		jz	done
		NextScanBoth di
		jnc	careScanLoop

		cmp	cx, cs:[pixelsLeft]	; if big enuf, just do it
                jbe     careScanLoop

splitStart:
		mov	ch, cs:[pixelsLeft].low
                tst     ch
                jz      null0
                push    ax
splitScanLoop:
                mov     ax, ds:[di]             ; get screen data
                mov     cs:[bx], ax             ; store background
                and     ax, cs:[si]             ; or in the mask
                xor     ax, cs:[si+768]         ; xor the picture data
                stosw
		inc	si
                inc     si
		inc	bx
                inc     bx
                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx], al             ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                add     di, cs:[pixelRestBytes]
                inc     si
		inc	bx
		dec	ch
		jnz	splitScanLoop
                pop     ax
null0:
		mov	ch, cl
		sub	ch, cs:[pixelsLeft].low

                push    ax
                push    cx

                cmp     cs:[restBytes], 0
                jz      over
                
                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx+2], al           ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                inc     si
                inc     bx

                cmp     cs:[restBytes], 1
                jz      over

                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx], al             ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                inc     si
                inc     bx

                cmp     cs:[restBytes], 2
                jz      over

                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx-2], al           ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                inc     si
                inc     bx
over:
                call    MidScanNextWinSrc
                call    MidScanNextWin

                tst     ch
                jz      done2

                cmp     cs:[restBytes], 3
                jz      done3

                cmp     cs:[restBytes], 2
                jz      left1

                cmp     cs:[restBytes], 1
                jz      left2

                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx+2], al           ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                inc     si
                inc     bx

left2:
                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx], al             ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                inc     si
                inc     bx

left1:
                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx-2], al           ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data

                inc     si
                inc     bx
done3:
                mov     di, cs:[restBytesOver]
                dec     ch
done2:
                mov     al, ch
                pop     cx
                mov     ch, al
                pop     ax
                tst     ch
                jz      null1
noSplit:
                push    ax
splitScanLoop2:
                mov     ax, ds:[di]             ; get screen data
                mov     cs:[bx], ax             ; store background
                and     ax, cs:[si]             ; or in the mask
                xor     ax, cs:[si+768]         ; xor the picture data
                stosw
		inc	si
                inc     si
		inc	bx
                inc     bx
                mov     al, ds:[di]             ; get screen data
                mov     cs:[bx], al             ; store background
                and     al, cs:[si]             ; or in the mask
                xor     al, cs:[si+768]         ; xor the picture data
                stosb
                add     di, cs:[pixelRestBytes]
                inc     si
		inc	bx
		dec	ch
		jnz	splitScanLoop2
                pop     ax

null1:
		dec	ah
		LONG jz	done
		FirstWinScan		
		jmp	careScanLoop	

DrawCursor	endp

if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		cl = width (area to save)
		ch = height
		bx = scan line to start saving
		ax = x position to start saving
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	10/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveBackground	proc	near
		uses	ax, si, ds, di, es, bx, cx
		.enter

		mov	cs:[backX], ax
		mov	cs:[backY], bx
		mov	cs:[backWidth], cl
		mov	cs:[backHeight], ch

		; get ds:si -> frame buffer

		mov	si, bx
                push    ax
                CalcLineOffset  ax
		CalcScanLineSrc	si, ax, ds	; ds:si -> frame buffer
                pop     ax
		segmov	es, cs, di
		mov	di, offset backBuffer	; es:di -> save area

		mov	ax, cs:[modeInfo].VMI_scanSize
		mov	bx, ax			; save another copy
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		add	ax, si
		mov	ax, bx			; restore scan size
		jc	partialWindow

		; the cursor is entirely inside the current memory window, 
		; DO IT FAST !

		mov	bh, ch			; scan line counter
		mov	bl, cl			; save copy of pixel counter
		clr	ch
		sub	ax, cx			; distance to next scan 
scanLoop:
		mov	cl, bl			; set up width
		rep	movsb
		add	si, ax			; onto next scan line
		dec	bh
		jnz	scanLoop
done:		
		.leave
		ret

		; part of cursor is in the next window
partialWindow:
		mov	bh, ch
		mov	bl, cl
		clr	ch
partLoop:
		mov	cl, bl
		rep	movsb
		mov	cl, bl
		sub	si, cx
doneScan:
		dec	bh
		jz	done
		NextScanSrc si, , ax
		jc	checkPartCursor
		jmp	partLoop

		; this isn't done yet -- in some situations we'll only get
		; 1/2 a cursor.
checkPartCursor:
		mov	cl, bl
		cmp	cx, cs:[pixelsLeft]
		jbe	partLoop
		mov	cl, cs:[pixelsLeft].low
		rep	movsb
		mov	cl, cs:[pixelsLeft].low
		sub	si, cx
		jmp	doneScan
		
SaveBackground	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the cursor

CALLED BY:	INTERNAL
		VidSetPtr, VidMovePtr
PASS:		cursorByteX - cursor byte x position
		cursorScreenAddr - screen address to start at
		cursorLines - number of lines to draw
		cursorBuffer - data to recover
		ds - cs
RETURN:		
DESTROYED:	
		ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		This is much easier than drawing the cursor -- we just have
		to copy the corresponding area from VRAM to DDRAM.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	9/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseCursor	proc	near
		uses	ax, si, ds, di, es, bx, cx

		.enter

		mov	ax, cs:[backX]
		mov	bx, cs:[backY]
		mov	cl, cs:[backWidth]
		mov	ch, cs:[backHeight]

		; get ds:si -> frame buffer

		mov	di, bx
                push    ax
                CalcLineOffset  ax
		CalcScanLine	di, ax, es	; es:di -> frame buffer
                pop     ax
		segmov	ds, cs, si
		mov	si, offset backBuffer	; ds:si -> save area

		mov	ax, cs:[modeInfo].VMI_scanSize
		mov	bx, ax			; save another copy

                cmp     ax, 4096
                jae     partialWindow

		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		shl	ax, 1
		add	ax, di
		jc	partialWindow
		cmp	ax, cs:[curWinEnd]	; calc #bytes left
                jae     partialWindow

		; the area is entirely inside the current memory window, 
		; DO IT FAST !

		mov	ax, bx			; restore scan size
		mov	bh, ch			; scan line counter
		mov	bl, cl			; save copy of pixel counter
		clr	ch

                push    dx
                push    ax
                mov     ax, cx
                mul     cs:[pixelBytes]
                mov     dx, ax
                pop     ax
                sub     ax, dx                  ; distance to next scan
                pop     dx
scanLoop:
		mov	cl, bl			; set up width

                push    ax
loop0:
                mov     ax, cs:[si]
                mov     es:[di], ax
                mov     al, cs:[si+2]
                mov     es:[di+2], al

                add     si, 3
                add     di, cs:[pixelBytes]

                loop    loop0

                pop     ax
		add	di, ax			; onto next scan line
		dec	bh
		jnz	scanLoop
done:		
		.leave
		ret

		; part of cursor is in the next window
partialWindow:
		mov	ax, bx			; restore scan size
		mov	bh, ch
		mov	bl, cl
		clr	ch

                clc
                call    SetNextWin                   

                jc      splitLine
        
partLoop:
		mov	cl, bl

                push    ax

loop1:
                mov     ax, cs:[si]
                mov     es:[di], ax
                mov     al, cs:[si+2]
                mov     es:[di+2], al

                add     si, 3
                add     di, cs:[pixelBytes]

                loop    loop1
                pop     ax

		mov	cl, bl

                push    ax, dx
                mov     ax, cx
                mul     cs:[pixelBytes]
                sub     di, ax
                pop     ax, dx

doneScan::
		dec	bh
		jz	done
		NextScan di, ax
		jnc	partLoop

splitLine:
		mov	cl, bl
		cmp	cx, cs:[pixelsLeft]
                jbe     partLoop
		mov	cx, cs:[pixelsLeft]
                jcxz    null2

                push    ax
loop2:
                mov     ax, cs:[si]
                mov     es:[di], ax
                mov     al, cs:[si+2]
                mov     es:[di+2], al

                add     si, 3
                add     di, cs:[pixelBytes]

                loop    loop2
                pop     ax

null2:
		mov	cl, bl
		sub	cx, cs:[pixelsLeft]

                push    bx, ax
                mov     ax, cs:[si]
                mov     bl, cs:[si+2]
                xchg    al, bl
                add     si, 3
                call    PutSplitedPixel
                pop     bx, ax

                jcxz    null3
split3:
                push    ax
loop3:
                mov     ax, cs:[si]
                mov     es:[di], ax
                mov     al, cs:[si+2]
                mov     es:[di+2], al

                add     si, 3
                add     di, cs:[pixelBytes]

                loop    loop3
                pop     ax
null3:
		dec	bh
		jz	done

		FirstWinScan
		jmp	partLoop
		
EraseCursor	endp
