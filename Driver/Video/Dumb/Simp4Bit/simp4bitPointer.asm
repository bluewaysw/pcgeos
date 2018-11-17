COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	Copyright (c) GeoWorks 1995 -- All Rights Reserved


PROJECT:	Simp4Bit video driver
FILE:		simp4bitPointer.asm

AUTHOR:		Andrew Wilson

ROUTINES:
	Name		Description
	----		-----------
   GLB	DrawCursor	Draw the pointer cursor
   GLB	EraseCursor	Erase the pointer cursor

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	tony	11/88	initial version
	andrew	 4/95	initial E3G rev
	JimG	 9/96	working E3G rev


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
		  1	  0		black
		  1	  1		white

	A possible upgrade to this scheme is to allow a foreground and
	background color for cursors.  This would be ok as a user preference,
	but would not be good to use for program feedback since not
	everyone will have color monitors.

	PLEASE NOTE:
	    This code was previously buggy and has been fixed and tested
	    on Penelope and BOR1 (Intel E3G test board).  It has not,
	    however, been tested on Responder.  --JimG 9/16/96

	$Id: simp4bitPointer.asm,v 1.1 97/04/18 11:43:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
	Jim	10/88...	Initial version
	JimG	09/16/96	Working E3G Rev

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
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

	;ds:si = structure
	; translate old current position to new one, based on new hotpoint

EC <	mov	bl, ds:[si].PD_width					>
EC <	and	bl, mask PDW_WIDTH	; Get width portion of byte	> 
EC <	cmp	bl, 16			; only support these for now	>
EC <	ERROR_NE VIDEO_ONLY_SUPPORTS_16x16_CURSORS			>
	mov	bx,word ptr ds:[si][PD_hotX]	;bl = hotX, bh = hotY
	mov	cs:[cursorHotX], bl	; store new x hot point
	mov	cs:[cursorHotY], bh	; store new y hot point

	; get pointer to cursor data
	;copy data, changing mask,image to ZEROS, ONES
	; zeros = not mask
	; ones = data

	add	si, size PointerDef	; ds:si -> data
	segmov	es,cs
	mov	di,offset cursorImage
	mov	cx,CUR_SIZE*2		;2 bytes/row * CUR_SIZE rows


VSP_loop:
	mov	al, ds:[si][CUR_IMAGE_SIZE]	; get byte of data
	call	BuildDataByte
	mov	bx, cs:[dataBuff4]
	mov	dx, cs:[dataBuff4+2]

	lodsb				;get a byte of the mask
NON_INV_CLR4 <	not	al		;1's compliment stored mask	>
	call	BuildDataByte		;Builds the 1 byte into 4 bytes of data
					; in dataBuff4
	mov	al, {byte} cs:[dataBuff4]	;Write out alternating bytes
	mov	ah, bl				;of mask (low)/data (high)
INV_CLR4<xor	ah, al	;To invert ptr, data=data^mask, then 1's compl	>
INV_CLR4<not	al	;the mask we store since we didn't do it earlier>
	stosw
	mov	al, {byte} cs:[dataBuff4+1]
	mov	ah, bh
INV_CLR4<xor	ah, al							>
INV_CLR4<not	al							>
	stosw
	mov	al, {byte} cs:[dataBuff4+2]
	mov	ah, dl
INV_CLR4<xor	ah, al							>
INV_CLR4<not	al							>
	stosw
	mov	al, {byte} cs:[dataBuff4+3]
	mov	ah, dh
INV_CLR4<xor	ah, al							>
INV_CLR4<not	al							>
	stosw
	
	loop	VSP_loop

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
	public	VidSetPtr

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawCursor

DESCRIPTION:	Draw the cursor when the optimization variables might be
		incorrect

CALLED BY:	INTERNAL
		VidSetPtr, VidMovePtr

PASS:
	cursorX, cursorY - cursor position
	cursorHotX, cursorHotY - cursor hot spot

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Calculate optimization variables and fall through to DrawCursor

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	JimG	09/16/96	Working E3G Rev
-------------------------------------------------------------------------------@

pixelWidths	word	CUR_SIZE-1, 	;# pixels affected on the screen
			CUR_SIZE-2-1,	; (at most)
			CUR_SIZE-4-1,
			CUR_SIZE-6-1,
			CUR_SIZE-8-1,
			CUR_SIZE-10-1,
			CUR_SIZE-12-1,
			CUR_SIZE-14-1

routineOffsets	label	word
		byte	0
		byte	offset EraseCursor1-EC_eraseRoutine - 1
		byte	0
		byte	offset EraseCursor2-EC_eraseRoutine - 1
		byte	0
		byte	offset EraseCursor3-EC_eraseRoutine - 1
		byte	0
		byte	offset EraseCursor4-EC_eraseRoutine - 1
		byte	0
		byte	offset EraseCursor5-EC_eraseRoutine - 1
		byte	0
		byte	offset EraseCursor6-EC_eraseRoutine - 1
		byte	0
		byte	offset EraseCursor7-EC_eraseRoutine - 1
		byte	0
		byte	offset EraseCursor8-EC_eraseRoutine - 1
		


DrawCursor	proc	near
	segmov	ds, cs, ax

	; calculate X variables

	clr	bh
	clr	dx				;value to self modify jumps 1,2
	mov	ax,ds:[cursorX]			;calculate real x position
	mov	bl,ds:[cursorHotX]
	sub	ax,bx
	mov	cx,ax				;CX <- screen position
	mov	bl,0				;value to self modify 3rd jump

	; ax = x byte position -- set up correct draw and erase code to use
	; based on clipping state

	jb	DC_left				;if clipped left then branch

	shr	ax,1				;get byte position
						;assume entirely visible
	mov	bh,offset EraseCursorNormal-EC_eraseRoutine - 1
	mov	di,CUR_SIZE+2-1			;max pixels covered by pointer
	mov	bp, -9
	cmp	ax,SCREEN_BYTE_WIDTH-8
	jb	DC_together			;if no clipping then branch

;	The cursor will be clipped - setup BX, BP, and DI correctly	

	mov	bx, SCREEN_BYTE_WIDTH
	sub	bx, ax		;BX <- # screen bytes cursor will take up (1-8)
EC <	tst	bx							>
EC <	ERROR_Z	-1							>
	mov	bp, bx
	neg	bp
	shl	bx, 1
	mov	di, ds:[pixelWidths-2][bx]
	mov	bx, ds:[routineOffsets-2][bx]
	jmp	short DC_together

DC_left:
	mov	bx, CUR_SIZE
	sub	bx, ax			;BX <- # pixels on screen
EC <	tst	bx							>
EC <	ERROR_Z	-1							>
	shr	bx, 1	;BX <- # screen bytes cursor will take up (0-7)
	mov	bp, bx
	neg	bp	;BP <- # screen bytes cursor will take up (negated)
	inc	bp
	mov	di, ds:[pixelWidths][bx]
	mov	bx, ds:[routineOffsets][bx]
	clr	ax				;Start at byte offset 0

DC_together:
	and	cl,1				;cl = shift count
	jz	10$				;Branch if no shift
	mov	cl, 4				;Else, we need to shift a full
						; nibble
10$:
	mov	ds:[EC_eraseRoutine],bh		;store erase routine
	StoreNextScanMod	<ds:[DCL_nextScanOffset]>, bp
	push	bp

	mov	bp,ax				;save byte offset in bp
	shl	ax,1
	mov	ds:[cursorRegLeft],ax		;calculate cursor region bounds
	add	ax,di
	mov	ds:[cursorRegRight],ax

	; calculate Y variables

	clr	bh
	clr	si				;assume no skip to data
	mov	ax,ds:[cursorY]			;calc real y positon
	mov	bl,ds:[cursorHotY]		;bh still 0
	sub	ax,bx
	mov	ch,CUR_SIZE			;assume all lines on screen
	jns	DC_notAbove			;if not above screen then branch
	add	ch,al				;decrease lines to draw
	sub	si,ax				;increase data offset
	shl	si,1
	shl	si,1
	clr	ax
DC_notAbove:
	cmp	ax,SCREEN_HEIGHT-CUR_SIZE	;check for clipped bottom
	jb	DC_notBelow
	add	ch,(SCREEN_HEIGHT-CUR_SIZE) mod 256	;adjust lines to draw
	sub	ch,al
DC_notBelow:

	mov	ds:[cursorLines],ch		;store lines to draw

	mov	ds:[cursorRegTop],ax		;store cursor region top
	mov	di,ax				;calc cursor region bottom
	add	al,ch
	adc	ah,0
	mov	ds:[cursorRegBottom],ax

	; calc data address

	SetBuffer	es, ax
	CalcScanLine	di, bp			;; Calc scan line, add offset
	mov	ds:[cursorScreenAddr],di

	mov	bp,offset dgroup:cursorBuffer

	; point at cursor data

	add	si,offset dgroup:cursorImage

	; ds:si = cursor data
	; cl = shift count
	; es:di = screen address
	; bp = background buffer
	; ch = lines to draw
	pop	ax			;
	neg	ax
	dec	al			; must pass # bytes in row - 1
	mov	cs:[DCL_numBytesPerLine], al

	FALL_THRU	DrawCursorLow

DrawCursor	endp
	public	DrawCursor

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawCursorLow

DESCRIPTION:	Draw the cursor not clipped in X

CALLED BY:	INTERNAL
		DrawCursor

PASS:
	ds:si 	= data
	ds:bp	= background save buffer
	cl	= shift count (0 or 4)
	ch	= lines to draw
	es:di	= screen buffer address

	cs:[DCL_numBytesPerLine] = # bytes in this line - 1
	
RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	First of all, notice that this requires the (# bytes - 1) be passed
	in via self-modifying the immediate value of a "mov ah, xxxx"
	instrunction since ah is actually used in the code and it is much
	faster to load ah this way than by using push/pops.  Note also that
	this value is (# bytes - 1).. the "- 1" is important!
	
	The tricky part of this loop is that there are actually only
	(# bytes - 1) words (low byte = MASK, hi byte = XOR data) in the
	bitmap source but we must store and write (# bytes) bytes of the
	video buffer.  This is because we may be skewed and need to start
	writing on the half-byte.  So, to make things simple, we do the
	main "rowLoop" (# bytes - 1) times.  After that, we fake the last
	byte of data to be "do nothing" --> XOR data == 0 and mask == FF and
	execute the last part of the loop again ("shortLoop").
	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	JimG	09/16/96	Working E3G Rev
-------------------------------------------------------------------------------@

DrawCursorLow	proc	near

nextRow:
	mov	ah, 0cch		;IMMEDIATE VALUE SELF-MODIFIED
DCL_numBytesPerLine = $-1
	
	mov	bh, 0xff		;Start with 1s in the mask
	clr	dh			;And 0s in the XOR data
rowLoop:
	lodsb				;BL <- mask
	mov	bl, al
	lodsb	
	mov	dl, al			;XOR data

shortLoop:
SWAPPED <rol	bx, cl			;bl <- mask, bh <- bits for next>
SWAPPED <rol	dx, cl			;dl <- xor, dh <- bits for next>
SWAPPED <rol	bh, cl							>
SWAPPED <rol	dh, cl							>
NSWAPPED<ror	bx, cl							>
NSWAPPED<ror	bx, cl							>
NSWAPPED<ror	bh, cl							>
NSWAPPED<ror	bh, cl							>
	mov	al, es:[di]		;Copy screen data to dest buffer
	mov	ds:[bp], al


	and	al,bl			;mask out bits to RESET
	xor	al,dl			;mask in bits to SET
	stosb
	inc	bp			;advance save buffer ptr
	dec	ah
	jg	rowLoop			; Loop (# bytes - 1) times
	
	; Done reading actual pointer image.  For the last byte, which may
	; or may not contain a half-byte's worth of data, clear the XOR data
	; and set the mask FF so that nothing is drawn and loop one last
	; time.
	;
	mov	dl, 0			; DON'T USE CLR -- PRESERVE FLAGS
	mov	bl, 0xff
	jz	shortLoop		; Loop one last time.. looping done
					; when ah == -1.


	NextScanMod	di,DCL_nextScanOffset
	dec	ch
	jnz	nextRow
	ret

DrawCursorLow	endp
	public	DrawCursorLow



COMMENT @-----------------------------------------------------------------------

FUNCTION:	EraseCursor

DESCRIPTION:	Erase the cursor

CALLED BY:	INTERNAL
		VidSetPtr, VidMovePtr

PASS:
	cursorByteX - cursor byte x position
	cursorScreenAddr - screen address to start at
	cursorLines - number of lines to draw
	cursorBuffer - data to recover
	ds - cs

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

EraseCursor	proc	near

	; point at cursor data

	SetBuffer	es, ax
	mov	si,offset dgroup:cursorBuffer
	mov	cl,ds:[cursorLines]
	clr	ch
	mov	di,ds:[cursorScreenAddr]

	jmp	short EraseCursor		;SELF MODIIED
EC_eraseRoutine = this byte - 1

EraseCursor	endp
	public	EraseCursor

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EraseCursorNormal

DESCRIPTION:	Erase the cursor not clipped in X

CALLED BY:	INTERNAL
		EraseCursor

PASS:
	ds:si - data
	cx - lines to draw
	es:di - screen buffer address

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

EraseCursorNormal	proc	near
ECN_loop:
	movsw
	movsw
	movsw
	movsw
	movsb

	NextScan di, -9
	loop	ECN_loop
	ret

EraseCursorNormal	endp
	public	EraseCursorNormal

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EraseCursor2

DESCRIPTION:	Erase a two byte wide cursor

CALLED BY:	INTERNAL
		EraseCursor

PASS:
	ds:si - data
	cx - lines to draw
	es:di - screen buffer address

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@


EraseCursor8	proc	near
EC8_loop:
	movsw	
	movsw
	movsw		
	movsw
	NextScan di, -8
	loop	EC8_loop
	ret
EraseCursor8	endp
EraseCursor7	proc	near
EC7_loop:
	movsw	
	movsw
	movsw		
	movsb
	NextScan di, -7
	loop	EC7_loop
	ret
EraseCursor7	endp
EraseCursor6	proc	near
EC6_loop:
	movsw	
	movsw
	movsw		
	NextScan di, -6
	loop	EC6_loop
	ret
EraseCursor6	endp

EraseCursor5	proc	near
EC5_loop:
	movsw	
	movsw
	movsb		
	NextScan di, -5
	loop	EC5_loop
	ret
EraseCursor5	endp

EraseCursor4	proc	near
EC4_loop:
	movsw	
	movsw
	NextScan di, -4
	loop	EC4_loop
	ret
EraseCursor4	endp

EraseCursor3	proc	near
EC3_loop:
	movsw	
	movsb		
	NextScan di, -3
	loop	EC3_loop
	ret
EraseCursor3	endp

EraseCursor2	proc	near
EC2_loop:
	movsw

	NextScan di, -2
	loop	EC2_loop
	ret

EraseCursor2	endp
	public	EraseCursor2

COMMENT @-----------------------------------------------------------------------

FUNCTION:	EraseCursor1

DESCRIPTION:	Erase a one byte wide cursor

CALLED BY:	INTERNAL
		EraseCursor

PASS:
	ds:si - data
	cx - lines to draw
	es:di - screen buffer address

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

EraseCursor1	proc	near
EC1_loop:
	movsb
	NextScan di, -1
	loop	EC1_loop
	ret

EraseCursor1	endp
	public	EraseCursor1
