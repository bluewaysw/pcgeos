COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGALike video drivers
FILE:		vgacomPointer.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    GBL	VidHidePtr	Erase the pointer cursor
    GBL	VidShowPtr	Draw the pointer cursor
    GBL	VidMovePtr	Update the cursor position
    GBL	VidSetPtr	Set up a new cursor picture
    INT EraseCursor	actually erase the bugger
    INT DrawCursor	actually draw the bugger
    INT SaveBackground	copy some screen memory to backing store
    INT CopyCursor	copies the cursor data to current position
    INT CalcPtrLoc	calculates the pointer location
    INT CondHidePtr	see if pointer will interfere with current drawing
			operation and erase it if it will
    INT CondShowPtr	if pointer was temp erased, redraw it


	
REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	10/88	initial version
	jeremy	5/91	added support for EGA compatible, monochrome,
			and inverse mono EGA drivers


DESCRIPTION:
	These are a set of routines to support the use of a cursor for
	the pointing device.
		
	The cursor is currently limited to a 16x16 pixel bitmap (by the
	sizing of the holding buffers).  This may change before release
	if we find a reason why we should allow bigger ones.  There are
	also some optimizations in the code that assume a 16-pixel wide
	image.

	The definition of a pointer allows for the specification of a "hot
	spot".  This indicates where on the cursor shape the "current
	position" should be reported as.

	The EGA driver does the cursor by shifting the mask and image on the 
	fly.  If this proves to be not fast enough, we'll probably change
	it to store pre-shifted images for both the mask and the image.  The
	advantage of shift-on-the-fly is eliminating the need for large
	buffers.  (NOTE: this was tested.  For the EGA it was found that
	there was 0.8% increase in idle time when the images and masks were
	pre-shifted for a 16x16 pixel cursor, running on the Tandy ATs.  The
	buffer size requirement increased from 64 bytes to 768 bytes)

	The way the mask and image are combined with the background are as
	follows:

		mask	image	->	screen
		pixel	pixel		pixel
		-----	-----		------
		  0	  0		unchanged
		  0	  1		xor
		  1	  0		white
		  1	  1		black

	A possible upgrade to this scheme is to allow a foreground and
	background color for cursors.  This would be ok as a user preference,
	but would not be good to use for program feedback since not
	everyone will have color monitors.

	ADDED FOR THE MONOCHROME DRIVER:
	===== === === ========== ======
	Added support for the inverse mode of the Monochrome EGA driver.  The
	cursors are inverted by XORing the background mask with the cursor
	image.

	$Id: vgacomPointer.asm,v 1.1 97/04/18 11:42:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
	Jim	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VidHidePtr	proc	near
	inc	cs:cursorCount		; increment the nesting count
	cmp	cs:cursorCount, 1		; if the cursor wasn't showing
	jne	VHPdone			;  then all done 
	call	EraseCursor		;  else erase it
VHPdone:
	ret

VidHidePtr	endp
	public	VidHidePtr


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
	Jim	10/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VidShowPtr	proc	near
	dec	cs:cursorCount		; set new value for nest count
EC <	ERROR_S	VIDEO_HIDE_CURSOR_COUNT_UNDERFLOW			>
	cmp	cs:cursorCount, 0		; see if we need to draw it
	jg	VShPdone		;  no, just dec the visible flag
	mov	cs:cursorCount, 0		; just in case it went neg.
	call	CalcPtrLoc		; calc current pointer location
	call	DrawCursor		;  yes, draw it
VShPdone:
	ret

VidShowPtr	endp
	public	VidShowPtr


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
		Calc save-under overlap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version
	Doug	1/90		Added return of save-under data, for 
				window enter/leave fixes (to work w/save under)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidMovePtr	proc	near
	cmp	cs:cursorCount, 0		; is cursor visible now ?
	jnz	VMPnewpos		;  no, don't have to erase it
	push	ax			;  yes, save new position...
	push	bx
	call	EraseCursor		;  ...and erase it
	pop	bx			;  ...then restore new position
	pop	ax

;	now update the current position
VMPnewpos:

	push	ax			; Save hot-point position
	push	bx			; for save-under area check

	clr	ch
	mov	cl, cs:[cursorHotX]
	sub	ax, cx			; translate from hot point
	mov	cl, cs:[cursorHotY]
	sub	bx, cx			; translate from hot point

	; if moving XOR region with pointer then do special stuff

	cmp	cs:[xorFlags], 0
	jz	noXOR
	push	ax, bx			; save new position
	sub	ax, cs:[cursorX]
	sub	bx, cs:[cursorY]
	call	UpdateXORForPtr
	pop	ax, bx
noXOR:

	mov	cs:[cursorX], ax		; store them away
	mov	cs:[cursorY], bx

;	now positions are updated, redraw picture if necc
	cmp	cs:[cursorCount], 0	; if zero, then it was visible
	jnz	AfterCursorRedrawn

;	push	ax
;	push	bx

	call	CalcPtrLoc		; calc new location
	call	DrawCursor		;  yep, draw it

;	pop	bx
;	pop	ax

AfterCursorRedrawn:
	pop	bx			; Restore hot point position
	pop	ax			; for save-under area check

	cmp	cs:[suCount], 0			; any active save under areas?
	jne	CheckSUAreas
	clr	al
	ret

CheckSUAreas:
	mov	cx, ax				; Pass rectangle = point
	mov	dx, bx
	GOTO	VidCheckUnder

VidMovePtr	endp
	public	VidMovePtr


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the picture data for the pointer cursor

CALLED BY:	EXTERNAL

PASS:		ds:si contains a far pointer to the following structure:

		PointerDef defined in cursor.def
	
		if si == 0xffff, then set the default pointer shape.
		
RETURN:		nothing

DESTROYED:	(if pointer erased and redrawn)
		   ax,bx,cx,dx,si,di,bp,ds
		else
		   ax,bx,cx,si,di,bp,ds

PSEUDO CODE/STRATEGY:
		just shift on the fly, so save the mask and image data
		to some local buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Currently cursor size is fixed at 16x16 pixels.  

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VidSetPtr	proc	near
	push	es			; save window seg
	cmp	cs:cursorCount, 0	; see if it's currently on-screen
	jnz	VSPnoshow		;  no, safe to proceed
	push	ds, si			; save passed params
	call	EraseCursor		;  yes, restore screen before changing
	pop	ds, si
VSPnoshow:
	cmp	si, -1			; see if want to use standard cursor
	jne	VSPcom			;  no, skip ahead
	segmov	ds, cs			; set up addressing ds->cs
	mov	si, offset cs:pBasic	; ds:si -> basic cursor 
VSPcom:						; now both cases are the same
EC <	mov	bl, ds:[si].PD_width					>
EC <	and	bl, mask PDW_WIDTH	; Get width portion of byte	> 
EC <	cmp	bl, 16			; only support these for now	>
EC <	ERROR_NE VIDEO_ONLY_SUPPORTS_16x16_CURSORS			>
	mov	bx, word ptr ds:[si].PD_hotX	; bl <- hotX,  bh <- hotY
	add	si, size PointerDef	; ds:si -> cursor mask data

	; translate old current position to new one, based on new hotpoint

	clr	ch
	mov	ax, cs:[cursorX]		; get current x position
	mov	cl, cs:[cursorHotX]	; remove effect of old hot point
	add	ax, cx
	mov	cl, bl			; move over new hotpoint
	sub	ax, cx
	mov	cs:[cursorX], ax		; store new x position
	mov	cs:[cursorHotX], bl	; store new x hot point

	mov	ax, cs:[cursorY]		; get current y position
	mov	cl, cs:[cursorHotY]	; remove effect of old hot point
	add	ax, cx
	mov	cl, bh			; move over new hotpoint
	sub	ax, cx
	mov	cs:[cursorY], ax		; store new y position
	mov	cs:[cursorHotY], bh	; store new y hot point

;	since the source is required to have all 32 bytes for both image
;	and mask, just move them over.  but wait -- if we alter the mask on
;	the way in, we might reduce the flickering

;	ourMask = !passedMask
;	ourImage = passedImage

	segmov	es, cs			; get es:di pointing to local buffer
	mov	di, offset cs:cursorImage ; get pointer to buffer
	mov	cx, CUR_IMAGE_SIZE	; two 32-byte buffers to fill
	rep	movsw

; 	Invert the cursor's image if we're drawing on black.
MEGA <	tst	cs:[inverseDriver]					>
MEGA <	jz	noXOR							>
MEGA <	mov	di, offset cs:cursorImage+CUR_IMAGE_SIZE; get ptr to buff >
MEGA <	segmov	ds, cs			; get ds:si pointing to mask	>
MEGA <	mov	si, offset cs:cursorImage ; get pointer to mask buffer	>
MEGA <	mov	cx, CUR_IMAGE_SIZE	; one 32-byte buffers to fill	>
MEGA <xorLoop:								>
MEGA <	mov	al, ds:[si]						>
MEGA <	xor	{byte} es:[di], al					>
MEGA <	inc	di							>
MEGA <	inc	si							>
MEGA <	loop	xorLoop							>
MEGA <noXOR:								>

	; all done with the setup, so draw it if we need to

	cmp	cs:cursorCount, 0	; see if cursor should be visible
	jnz	VSPquit			;  no, just quit
	call	CalcPtrLoc		; calc new location
	call	DrawCursor		;  yes, draw the new image to the scrn
VSPquit:
	pop	es			; restore window seg
	ret

VidSetPtr	endp
	public	VidSetPtr



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the background image under cursor to the screen 

CALLED BY:	INTERNAL
		VidSetPtr, VidHidePtr

PASS:		d_ptrLoc	- index into frame buffer to current ptrloc
		d_byteXPos	- bytes into screen from left edge

RETURN:		es -> frame buffer
		ds -> frame buffer

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		copy the stored image of the area of the screen behind the
		cursor over the current cursor position. (clipped to the 
		screen bounds)

		calculate offset to upper left corner of cursor;
		for (line = curY; line < curY + height; line++)
		   if (line is on screen)
		      for (xBPos = curXBPos; xBPos < curXBPos+BWid; curXBPos++)
			 if (byte is on screen)
			    copy byte from backing store;
			 bump pointer to next byte on screen;
		      bump pointer to next scan line;


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EraseCursor	proc	near
	SetBuffer	es, si		; sets up es->frame_buf and 
	mov	dx, GR_CONTROL
	mov	ds, si			; also set ds -> frame buffer
	mov	si, CURSOR_BACK 	; set up source ptr to backing store
	mov	di, cs:[d_ptrLoc]	; get index to pointer location
	mov	ch, cs:[d_byteXPos]	; byte x position
	mov	cl, CUR_SIZE		; number of lines to do
	mov	bp, cs:[cursorY]		; bp = current line number

;	do all the EGA setup stuff
	mov	ax, EN_SR_ALL		; enable all bits in set/reset reg
	out	dx, ax
	mov	ax, BMASK_NONE		; but mask off all bits so contents
	out	dx, ax			;   of latches are just copied
	mov	ax, DATA_ROT_COPY	; set to the copy function
	out	dx, ax

	cmp	cs:[d_wholeFlag], 1	; see if on screen
	je	EraseWholePtr
	GOTO	ErasePartialPtr
EraseCursor	endp
	public	EraseCursor


EraseWholePtr	proc	near
	movsb				; move the byte over
	movsb				; move the byte over
	movsb				; move the byte over
	add	di, BWID_SCR-CUR_BWIDTH	; bump addr to next scan line
	dec	cl			; one less line to do
	jnz	EraseWholePtr
	GOTO	SetEGAState		; and reset state to former values
EraseWholePtr	endp


ErasePartialPtr	proc	near
;	for (line=curY; line < curY+cursorHeight; line++)
EPPlineloop:
	or	bp, bp			; see if it's negative
	js	EPPnline		;  yes, go to next line
	cmp	bp, HEIGHT_SCR		; if it's past the bottom
	jge	EPPdone			;  then stop drawing altogether

;	for (xbytepos=curX; xbytepos < curX+width; xbytepos++)
	mov	bh, ch			; bh <- left side byte position
	or	bh, bh			; see if we're off the left edge
	js	EPPnextx		;  yes, go to next byte
	cmp	bh, BWID_SCR		; see if off right edge
	jge	EPPnline		;  yes, go to next line

;	ok, we finally have identified a byte that needs to be copied. do it.
	lodsb
	mov	es:[di], al
EPPnextx:
	inc	bh			; bump the byte position
	js	EPPnextx2		;  yes, go to next byte
	cmp	bh, BWID_SCR		; see if off right edge
	jge	EPPnline		;  yes, go to next line
	lodsb
	mov	es:[di+1], al
EPPnextx2:
	inc	bh			; bump the byte position
	js	EPPnline		;  yes, go to next byte
	cmp	bh, BWID_SCR		; see if off right edge
	jge	EPPnline		;  yes, go to next line
	lodsb
	mov	es:[di+2], al

;	done with this scan line, adjust counters, pointers and continue
EPPnline:
	add	di, BWID_SCR		; just bump addr to the next scan line
	inc	bp			; bump line counter
	dec	cl			; one less line to do
	jnz	EPPlineloop
EPPdone:
	GOTO	SetEGAState		; and reset state to former values

ErasePartialPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the image of the cursor to the screen

CALLED BY:	INTERNAL
		VidSetPtr

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:
		Save the background behind the cursor
		AND the cursor mask with the screen
		OR the cursor image with the screen

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCursor	proc	near

;	save the screen memory 
	call	SaveBackground		; write screen mem to backing store
	segmov	ds, cs			; set up data seg -> driver space

;	OR the cursor mask data
	mov	ax, DATA_ROT_COPY	; OR the mask to the screen
	out	dx, ax			;  this sets the white part of the cur
	mov	ax, SR_BLACK		; set the color register to white
	out	dx, ax			;  this sets the white part of the cur
	mov	si, offset cs:cursorImage	; set up pointer to video mem
	call	CopyCursor		; OR the cursor mask

;	AND the cursor image data
	mov	ax, DATA_ROT_XOR	; AND the image to the screen
	out	dx, ax			;  this sets the black part of the cur
	mov	ax, SR_WHITE		; set the color register to black
	out	dx, ax			;  this sets the white part of the cur
	mov	si, offset cs:cursorImage+CUR_IMAGE_SIZE
	call	CopyCursor		; AND the cursor image

	GOTO	SetEGAState		; and reset state to former values

DrawCursor	endp
	public	DrawCursor


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the part of screen memory that sits under the cursor
		to backing store

CALLED BY:	INTERNAL

PASS:		nothing

RETURN:		es:di	- pointer to frame buffer
		ds	- pointer to frame buffer
		dx	- address of EGA graphics control register

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		copy data from the screen to the backing store, clipped 
		at the screen boundaries

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SaveBackground	proc	near
	SetBuffer	es, si		; sets up es->frame_buf and 
	mov	dx, GR_CONTROL
	mov	ds, si			; also set ds -> frame buffer

	mov	si, cs:[d_ptrLoc]	; get pointer into frame buffer
	mov	di, CURSOR_BACK 	; set up dest ptr to backing store

	mov	ch, cs:[d_byteXPos]	; ch = byte position (signed)
	mov	cl, CUR_SIZE		; cl = number of lines to do
	mov	bp, cs:[cursorY]		; bp = current line number

;	do all the EGA setup stuff
	mov	ax, EN_SR_ALL		; enable all bits in set/reset reg
	out	dx, ax
	mov	ax, BMASK_NONE		; but mask off all bits so contents
	out	dx, ax			;   of latches are just copied
	mov	ax, DATA_ROT_COPY	; set to the copy function
	out	dx, ax

	cmp	cs:[d_wholeFlag], 1	; see if on screen
	je	SaveWholePtr
	GOTO	SavePartialPtr
SaveBackground	endp
	public	SaveBackground


SaveWholePtr	proc	near
	movsb				; move the byte over
	movsb				; move the byte over
	movsb				; move the byte over
	add	si, BWID_SCR-CUR_BWIDTH
	dec	cl			; one less line to do
	jnz	SaveWholePtr
	ret
SaveWholePtr	endp


SavePartialPtr	proc	near
;	for (line=curX; line < curX+cursorHeight; line++)
SPPlineloop:
	or	bp, bp			; see if it's negative
	js	SPPnline			;  yes, go to next line
	cmp	bp, HEIGHT_SCR		; if it's past the bottom
	jge	SPPdone			;  then stop drawing altogether

;	for (xbytepos=curX; xbytepos < curX+width; xbytepos++)
	mov	bh, ch			; bh <- left side byte position
	or	bh, bh			; see if we're off the left edge
	js	SPPnextx		;  yes, go to next byte
	cmp	bh, BWID_SCR		; see if off right edge
	jge	SPPnline		;  yes, go to next line

;	ok, we finally have identified a byte that needs to be copied. do it.
	mov	al, ds:[si]
	stosb
SPPnextx:
	inc	bh			; bump the byte position
	js	SPPnextx2		;  yes, go to next byte
	cmp	bh, BWID_SCR		; see if off right edge
	jge	SPPnline		;  yes, go to next line
	mov	al, ds:[si+1]
	stosb
SPPnextx2:
	inc	bh			; bump the byte position
	js	SPPnline		;  yes, go to next byte
	cmp	bh, BWID_SCR		; see if off right edge
	jge	SPPnline		;  yes, go to next line
	mov	al, ds:[si+2]
	stosb

;	done with this scan line, adjust counters, pointers and continue
SPPnline:
	add	si, BWID_SCR		; just bump addr to the next scan line
	inc	bp			; bump line counter
	dec	cl			; one less line to do
	jnz	SPPlineloop
SPPdone:
	ret
SavePartialPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the cursor iamge or mask data to the current cursor
		position

CALLED BY:	INTERNAL

PASS:		es	- segment address of frame buffer
		ds	- driver segment
		dx	- GR_CONTROL register address
		si	- pointer to image or mask to copy over
		
		EGA registers must be set up in the correct mode:

		PASSED	write mode 0
		PASSED	read mode 0
	    NOT PASSED	bitmask 	= byte from cursor mask or image
					  (set in this routine)
		PASSED	enab set/reset 	= $F
		PASSED	set/reset 	= $0 for image $F for mask
		PASSED	data/rot	= OR for mask
					  AND for image


RETURN:		es	- frame buffer segment

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		using the draw mode that is set up prior to entry, write
		out the bits from the mask/image to the screen at the
		current cursor position.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyCursor	proc	near
	mov	di, cs:[d_ptrLoc]	; di = offset into frame buffer
	mov	cl, cs:[d_byteXPos]
	mov	cs:[d_temp1L], cl 	; save byte x position
	mov	cl, byte ptr cs:[cursorX] ; get lo byte of x position
	and	cl, 7			; cl = shift count
	mov	bl, CUR_SIZE		; d_temp1+1 = # of lines to do
	mov	cs:[d_temp1H], bl 
	mov	bp, cs:[cursorY]		; bp = current line number

	cmp	cs:[d_wholeFlag], 1	; see if on screen
	je	CopyWholePtr
	GOTO	CopyPartialPtr
CopyCursor	endp
	public	CopyCursor


CopyWholePtr	proc	near
;	implement separate loop for the no-shift case
	or	cl, cl			; see if any shifting needed
	jnz	CWPlineloop		;  yes, do long loop
	mov	al, BITMASK		; index to bitmask register

;-------------------------------
;	no shift loop
;-------------------------------
;	for (line=curY; line < curY+cursorHeight; line++)
CWPnsloop:
	mov	ah, ds:[si]		; get the next byte
	out	dx, ax			; set the bitmask
	or	es:[di], al		; read/write the latch in the EGA
	mov	ah, ds:[si+1]		; get the next byte
	out	dx, ax			; set the bitmask
	or	es:[di+1], al		; read/write the latch in the EGA
	add	di, BWID_SCR		; just bump addr to the next scan line
	add	si, 2		
	dec	bl			; one less line to do
	jnz	CWPnsloop
	ret


;-------------------------------
;	shift loop
;-------------------------------
;	for (line=curY; line < curY+cursorHeight; line++)
CWPlineloop:
	mov	bh, 0			; start out shifting in zeroes
	mov	al, ds:[si]		; get the next byte
	mov	ah, al			; copy byte to upper half
	xchg	bh, al			; save this byte, get the last one
	ror	ax, cl			; rotate correct # (not thru carry)
	mov	al, BITMASK		; index to bitmask register
	out	dx, ax			; set the bitmask
	or	es:[di], al		; read/write the latches
	mov	al, ds:[si+1]		; get the next byte
	mov	ah, al			; copy byte to upper half
	xchg	bh, al			; save this byte, get the last one
	ror	ax, cl			; rotate correct # (not thru carry)
	mov	al, BITMASK		; index to bitmask register
	out	dx, ax			; set the bitmask
	or	es:[di+1], al		; read/write the latches
	clr	ah
	xchg	bh, al			; save this byte, get the last one
	ror	ax, cl			; rotate correct # (not thru carry)
	mov	al, BITMASK		; index to bitmask register
	out	dx, ax			; set the bitmask
	or	es:[di+2], al		; read/write the latches
	add	di, BWID_SCR		; just bump addr to the next scan line
	add	si, 2	
	dec	bl			; one less line to do
	jnz	CWPlineloop
	ret
CopyWholePtr	endp


CopyPartialPtr	proc	near
;	implement separate loop for the no-shift case
	or	cl, cl			; see if any shifting needed
	jnz	CPPlineloop		;  yes, do long loop
	mov	al, BITMASK		; index to bitmask register

;-------------------------------
;	no shift loop
;-------------------------------
;	for (line=curY; line < curY+cursorHeight; line++)
CPPnsloop:
	or	bp, bp			; see if it's negative
	js	CPPnsnline		;  yes, go to next line
	cmp	bp, HEIGHT_SCR		; if it's past the bottom
	jl	CPPndone
	jmp	CPPdone			;  then stop drawing altogether
	
;	for (xbytepos=curX; xbytepos < curX+width; xbytepos++)
CPPndone:
	mov	ch, cs:[d_temp1L]	; ch <- left side byte position
	or	ch, ch			; see if we're off the left edge
	js	CPPnsx			;  yes, go to next byte
	cmp	ch, BWID_SCR		; see if off right edge
	jge	CPPnsx			;  yes, go to next line

	mov	ah, ds:[si]		; get the next byte
	out	dx, ax			; set the bitmask
	or	es:[di], al		; read/write the latch in the EGA
CPPnsx:
	inc	ch			; bump x position
	js	CPPnsnline		;  yes, go to next byte
	cmp	ch, BWID_SCR		; see if off right edge
	jge	CPPnsnline		;  yes, go to next line

	mov	ah, ds:[si+1]		; get the next byte
	out	dx, ax			; set the bitmask
	or	es:[di+1], al		; read/write the latch in the EGA
CPPnsnline:
	add	di, BWID_SCR		; just bump addr to the next scan line
	add	si, 2		
	inc	bp			; bump line counter
	dec	bl			; one less line to do
	jnz	CPPnsloop
	jmp	CPPdone


;-------------------------------
;	shift loop
;-------------------------------
;	for (line=curY; line < curY+cursorHeight; line++)
CPPlineloop:
	or	bp, bp			; see if it's negative
	js	CPPnline			;  yes, go to next line
	cmp	bp, HEIGHT_SCR		; if it's past the bottom
	jge	CPPdone			;  then stop drawing altogether

;	for (xbytepos=curX; xbytepos < curX+width; xbytepos++)
	mov	ch, cs:[d_temp1L]	; bh <- left side byte position
	mov	bh, 0			; start out shifting in zeroes
	mov	al, ds:[si]		; get the next byte
	mov	ah, al			; copy byte to upper half
	xchg	bh, al			; save this byte, get the last one
	ror	ax, cl			; rotate correct # (not thru carry)
	or	ch, ch			; see if we're off the left edge
	js	CPPnextx		;  yes, go to next byte
	cmp	ch, BWID_SCR		; see if off right edge
	jge	CPPnline		;  yes, go to next line
	mov	al, BITMASK		; index to bitmask register
	out	dx, ax			; set the bitmask
	or	es:[di], al		; read/write the latches
CPPnextx:
	mov	al, ds:[si+1]		; get the next byte
	mov	ah, al			; copy byte to upper half
	xchg	bh, al			; save this byte, get the last one
	ror	ax, cl			; rotate correct # (not thru carry)
	inc	ch			; bump the byte position
	js	CPPnextx2		;  yes, go to next byte
	cmp	ch, BWID_SCR		; see if off right edge
	jge	CPPnline		;  yes, go to next line
	mov	al, BITMASK		; index to bitmask register
	out	dx, ax			; set the bitmask
	or	es:[di+1], al		; read/write the latches
CPPnextx2:
	inc	ch			; bump the byte position
	js	CPPnline		;  yes, go to next byte
	cmp	ch, BWID_SCR		; see if off right edge
	jge	CPPnline		;  yes, go to next line
	clr	ah
	xchg	bh, al			; save this byte, get the last one
	ror	ax, cl			; rotate correct # (not thru carry)
	mov	al, BITMASK		; index to bitmask register
	out	dx, ax			; set the bitmask
	or	es:[di+2], al		; read/write the latches

CPPnline:
	add	di, BWID_SCR		; just bump addr to the next scan line
	add	si, 2	
	inc	bp			; bump line counter
	dec	bl			; one less line to do
	jnz	CPPlineloop
CPPdone:
	ret
CopyPartialPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcPtrLoc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Description

CALLED BY:	EXTERNAL

PASS:		cursorX	- current x position
		c_curY	- current y position

RETURN:		cx	- xpos >> 3
		di	- offset into frame buffer

		cs:[d_ptrLoc] 	= di
		cs:[d_byteXPos]	= cl

DESTROYED:	bp

PSEUDO CODE/STRATEGY:
		di = (ypos * 80) + (cx >> 8)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcPtrLoc	proc	near
	mov	cx, cs:[cursorX]		; get x position
	and	cx, 0fff8h		; force to a byte boundary
	mov	cs:[cursorRegLeft], cx	; save left side
	mov	di, cx
	add	di, 23
	mov	cs:[cursorRegRight], di	; save left side

	sar	cx, 1			; divide by 8 to get byte position
	sar	cx, 1			; (yes, this all works with negative
	sar	cx, 1			;   numbers)
	mov	di, cs:[cursorY]		; di = current line number
	mov	cs:[cursorRegTop], di	; save it
	mov	bp, di
	add	bp, 15
	mov	cs:[cursorRegBottom], bp	; save it

	mov	bp,cx			; offset into line
	CalcScanLine	di, bp		;; calc offset into screen buffer,
					;; add in bp

	mov	cs:[d_ptrLoc], di	; and save it
	mov	cs:[d_byteXPos], cl	; save byte offset into scan line

;	since we'll be all on-screen most of the time, do a check for it
	mov	ch, 0			; assume whole cursor is not on screen
	mov	bp, cs:[cursorY]		; get y position
	or	bp, bp			; first check y direction
	js	CPLblocked		;  nope, partially off screen
	cmp	bp, HEIGHT_SCR-CUR_SIZE	; see if fit on bottom
	jg	CPLblocked		;  nope
	or	cl, cl			; check x direction
	js	CPLblocked
	cmp	cl, BWID_SCR-CUR_BWIDTH
	jg	CPLblocked
	inc	ch
CPLblocked:
	mov	cs:[d_wholeFlag], ch	; signal it is on screen
	ret
CalcPtrLoc	endp
	public	CalcPtrLoc


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CondHidePtr, CondShowPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pointer interferes with drawing, erase it

		CondShowPtr is called at the end of each graphics call
		to determine if the pointer was temporarily erased during
		that call.

CALLED BY:	INTERNAL

PASS:		none

		all the clip parameters in the Window structure are assumed
		to be valid (W_clipRect.R_top, W_clipRect.R_bottom, wClipFirstON wClipLastON)

RETURN:		nothing

DESTROYED:	CondHidePtr	- nothing
		CondShowPtr	- ax,bx,cx,dx,si,di,bp,ds if pointer redrawn

PSEUDO CODE/STRATEGY:
		check bounds of mouse to where drawing is happening, erase it
		if it will interfere

		the complementary routine checks the temp erase flag and redraws
		the pointer if it was erased.  this is called after the 
		drawing is complete, before exiting the driver (at the end
		of the DriverEntry routine)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CondHidePtr	proc	near
	cmp	cs:cursorCount, 0		; if it's gone, don't try to erase it
	jne	CHPend			;   again
	cmp	cs:[hiddenFlag],0
	jne	CHPend

;	we have a live candidate, erase it
	mov	cs:[hiddenFlag], 1	; set the erased flag
	push	ax, bx, cx, dx, si, di, bp, ds, es
	call	EraseCursor		; then erase it
	pop	ax, bx, cx, dx, si, di, bp, ds, es
CHPend:
	ret
CondHidePtr	endp
	public	CondHidePtr


CondShowPtrFar	proc	far
	call	CondShowPtr
	ret
CondShowPtrFar	endp

CondShowPtr	proc	near
	push	ds, es, bp
	call	DrawCursor		;  yes, re-draw it
	mov	cs:[hiddenFlag],0
	pop	ds, es, bp
	ret

CondShowPtr	endp
	public	CondShowPtr
