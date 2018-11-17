COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GlobalPC 1998 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers	
FILE:		cyber16Pointer.asm

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

	$Id: cyber16Pointer.asm,v 1.2$

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
	uses	ds, es
	.enter

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
if	SAVE_UNDER_COUNT gt 0
	segmov	ds, cs
	cmp	ds:[suCount], 0			; any active save under areas?
	jne	CheckSUAreas
endif	; SAVE_UNDER_COUNT gt 0
	clr	al

done:
	.leave
	ret

if	SAVE_UNDER_COUNT gt 0
CheckSUAreas:
	mov	ax, ds:[cursorX]		; Fetch location to check at
	mov	bx, ds:[cursorY]
	mov	cx, ax				; Pass rectangle = point
	mov	dx, bx
	call	VidCheckUnder
	jmp	done
endif	; SAVE_UNDER_COUNT gt 0

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
EC <	and	bl, mask PDW_WIDTH	; Get width portion of byte	> 
EC <	cmp	bl, 16			; only support these for now	>
EC <	ERROR_NE VIDEO_ONLY_SUPPORTS_16x16_CURSORS			>
	mov	bx, {word}ds:[si][PD_hotX]	;bl = hotX, bh = hotY

if ALLOW_BIG_MOUSE_POINTER
	cmp	cs:[cursorSize], CUR_SIZE	;adjust hotX, hotY if double
	je	bp0				; sized mouse pointer
	add	bx, bx				;bl = hotX, bh = hotY
bp0:
endif ; ALLOW_BIG_MOUSE_POINTER

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
	mov	cx, (size ptrMaskBuffer)/2	; clearing mask 
	mov	ax, 0xffff
	rep	stosw
	mov	cx, (size ptrMaskBuffer)/2	; clearing picture
	mov	ax, 0xffff
	rep	stosw

if ALLOW_BIG_MOUSE_POINTER
	cmp	cs:[cursorSize], CUR_SIZE
	jne	setBigPointer
endif ; ALLOW_BIG_MOUSE_POINTER

	; first do the mask.  

	mov	di, offset ptrMaskBuffer
	mov	dx, CUR_SIZE		; 16 scan lines
maskLoop:
	lodsw				; get next word (scan) of mask data
	xchg	al,ah
	mov	bx, ax
	clr	ax
	mov	cx, CUR_SIZE		; 16 pixels/scan
mPixLoop:
	shl	bx, 1			; top bit into carry
	jnc	mSkipOne
	mov	es:[di], ax
mSkipOne:
	inc	di
	inc	di	
	loop	mPixLoop		; do entire scan line
	dec	dx
	jnz	maskLoop		; do all of mask	

	; now do the picture data.  

	mov	di, offset ptrMaskBuffer + size ptrMaskBuffer
	mov	dx, CUR_SIZE		; 16 scan lines
pictureLoop:
	lodsw				; get next word (scan) of picture data
	xchg	al,ah
	mov	bx, ax
	clr	ax
	mov	cx, CUR_SIZE		; 16 pixels/scan
pPixLoop:
	shl	bx, 1			; top bit into carry
	jc	pSkipOne
	mov	es:[di], ax
pSkipOne:
	inc	di
	inc	di
	loop	pPixLoop		; do entire scan line
	dec	dx
	jnz	pictureLoop		; do all of mask	

drawCursor::
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


if ALLOW_BIG_MOUSE_POINTER

setBigPointer:
	;; set big mouse pointer

	mov	di, offset ptrMaskBuffer
	mov	dx, CUR_SIZE		; 16 scan lines
bpMaskLoop:
	lodsw				; get next word (scan) of mask data
	xchg	al, ah
	mov	bx, ax
	clr	ax
	mov	cx, CUR_SIZE		; 16 pixels/scan
bpmPixLoop:
	shl	bx, 1			; top bit into carry
	jnc	bpmSkipOne
	mov	es:[di], ax
	mov	es:[di+2], ax		; do 2 pixels
	mov	es:[di+CUR_SIZE*4], ax
	mov	es:[di+CUR_SIZE*4+2],ax	; do 2 pixels on next scanline
bpmSkipOne:
	add	di, 4
	loop	bpmPixLoop		; do entire scan line
	add	di, CUR_SIZE*4		; skip to next scanline
	dec	dx
	jnz	bpMaskLoop		; do all of mask	

	; now do the picture data.  

	mov	dx, CUR_SIZE		; 16 scan lines
bpPictureLoop:
	lodsw				; get next word (scan) of picture data
	xchg	al, ah
	mov	bx, ax
	clr	ax
	mov	cx, CUR_SIZE		; 16 pixels/scan
bppPixLoop:
	shl	bx, 1			; top bit into carry
	jc	bppSkipOne
	mov	es:[di], ax
	mov	es:[di+2], ax		; do 2 pixels
	mov	es:[di+CUR_SIZE*4], ax
	mov	es:[di+CUR_SIZE*4+2],ax	; do 2 pixels on next scanline
bppSkipOne:
	add	di, 4
	loop	bppPixLoop		; do entire scan line
	add	di, CUR_SIZE*4		; skip to next scanline
	dec	dx
	jnz	bpPictureLoop		; do all of mask
	jmp	drawCursor

endif ; ALLOW_BIG_MOUSE_POINTER

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
		ds, es

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
		mov	cl, {byte}cs:[cursorSize]
		mov	ch, cl

		; do different stuff if off left of screen 
	
		tst	ax			; check for neg coord
		LONG js	offLeft

		; OK, it may be entirely inside the screen.  Check the right.
	
		mov	si, cs:[DriverTable].VDI_pageW	; get right side coord
		sub	si, cs:[cursorSize]
		cmp	ax, si			; check right side
		LONG ja	offRight		;  else clip right side

		; If we are off the screen on top, then we need to adjust 
		; the Y offset, else we are starting from scan line 320.
checkHeight:
		tst	bx			; see if off the top
		LONG js	offTop			;  take less-traveled road

		mov	si, cs:[DriverTable].VDI_pageH
		sub	si, cs:[cursorSize]
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

		push	ax
		mov	al, dh
		mul	{byte}cs:[cursorSize]	; *cursorSize for scan index
		clr	dh
		add	dx, ax			; dx = index into picture
		add	dx, dx			; dx = byte offset into picture
		pop	ax

		mov	si, offset ptrMaskBuffer ; figure source address
		add	si, dx			; 
		segmov	ds, cs			; ds:si -> maskBuffer (source)

		mov	di, bx
		mov	bx, ax
		shl	bx, 1
		CalcScanLineBoth di, bx, es, ds	; ds,es:[di] -> destination
		shr	bx, 1
		mov	bp, cs:[curWinEnd]	; calc #bytes left
		sub	bp, di			; bp = #bytes left 

		mov	ax, cs:[modeInfo].VMI_scanSize ; get bytes per scan
		mul	cs:[cursorSize]
		cmp	ax, bp			; going to overflow window ?
		mov	ah, ch			; ah = height
		mov	bx, offset cs:backBuffer
		ja	careScanLoop

		; finally, draw the sucker
		; ds:di	-> frame buffer (read window)
		; es:di -> frame buffer (write window)
		; cl	 - width loop counters
		; ah	 - height loop counter
		; al	 - scratch register
		; cs:si	 - offset into cursor definition buffer
		; cs:bx	 - offset into background save buffer
drawLoop:
		mov	ch, cl			; reload width
		push	ax
pixLoop:
		mov	ax, ds:[di]		; get screen data
		mov	cs:[bx], ax		; store background
		and	ax, cs:[si]		; or in the mask
		xor	ax, cs:[si+(size ptrMaskBuffer)] ; xor the picture data
		stosw
		inc	si
		inc	si
		inc	bx
		inc	bx
		dec	ch
		jnz	pixLoop
		pop	ax

		shl	cx, 1			; 1 pixel = 2 bytes
		sub	di, cx
		add	si, cs:[cursorSize]
		add	si, cs:[cursorSize]
		sub	si, cx
		shr	cx, 1

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
		push	ax
carePixLoop:
		mov	ax, ds:[di]		; get screen data
		mov	cs:[bx], ax		; store to background buffer
		and	ax, cs:[si]		; or in the mask
		xor	ax, cs:[si+(size ptrMaskBuffer)] ; xor the picture data
		stosw
		inc	bx			; next background byte
		inc	bx
		inc	si			; next cursor picture byte
		inc	si
		dec	ch
		jnz	carePixLoop
		pop	ax

		shl	cx, 1			; 1 pixel = 2 bytes
		sub	di, cx
		add	si, cs:[cursorSize]
		add	si, cs:[cursorSize]
		sub	si, cx
		shr	cx, 1

		dec	ah
		jz	done
		NextScanBoth di
		jnc	careScanLoop

		cmp	cx, cs:[pixelsLeft]	; if big enuf, just do it
		jbe	careScanLoop

		mov	ch, cs:[pixelsLeft].low
		push	ax
splitScanLoop:
		mov	ax, ds:[di]		; get screen data
		mov	cs:[bx], ax		; store to background buffer
		and	ax, cs:[si]		; or in the mask
		xor	ax, cs:[si+(size ptrMaskBuffer)] ; xor the picture data
		stosw
		inc	bx			; next background byte
		inc	bx
		inc	si			; next cursor picture byte
		inc	si
		dec	ch
		jnz	splitScanLoop
		pop	ax

		call	MidScanNextWinSrc
		call	MidScanNextWin

		mov	ch, cl
		sub	ch, cs:[pixelsLeft].low
		push	ax
splitScanLoop2:
		mov	ax, ds:[di]		; get screen data
		mov	cs:[bx], ax		; store to background buffer
		and	ax, cs:[si]		; or in the mask
		xor	ax, cs:[si+(size ptrMaskBuffer)] ; xor the picture data
		stosw
		inc	bx			; next background byte
		inc	bx
		inc	si			; next cursor picture byte
		inc	si
		dec	ch
		jnz	splitScanLoop2
		pop	ax

		dec	ah
		LONG jz	done
		FirstWinScan		
		jmp	careScanLoop	

DrawCursor	endp


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
		shl	ax, 1
		CalcScanLine	di, ax, es	; es:di -> frame buffer
		shr	ax, 1
		segmov	ds, cs, si
		mov	si, offset backBuffer	; ds:si -> save area

		mov	ax, cs:[modeInfo].VMI_scanSize
		mov	bx, ax			; save another copy
		mul	cs:[cursorSize]
		add	ax, di
		jc	partialWindow
		cmp	ax, cs:[curWinEnd]	; calc #bytes left
		jae	partialWindow

		; the area is entirely inside the current memory window, 
		; DO IT FAST !

		mov	ax, bx			; restore scan size
		mov	bh, ch			; scan line counter
		mov	bl, cl			; save copy of pixel counter
		clr	ch
		sub	ax, cx			; distance to next scan 
		sub	ax, cx
scanLoop:
		mov	cl, bl			; set up width
		rep	movsw
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

partLoop:
		mov	cl, bl
		rep	movsw
		mov	cl, bl
		sub	di, cx
		sub	di, cx
doneScan::
		dec	bh
		jz	done
		NextScan di, ax
		jnc	partLoop

		mov	cl, bl
		cmp	cx, cs:[pixelsLeft]
		jbe	partLoop
		mov	cx, cs:[pixelsLeft]
		rep	movsw

		call	MidScanNextWin
		mov	cl, bl
		sub	cx, cs:[pixelsLeft]
		rep	movsw
		dec	bh
		jz	done

		FirstWinScan
		jmp	partLoop
		
EraseCursor	endp
