COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Dumb Raster video drivers
FILE:		dumbcomPointer.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
   GLB	VidHidePtr	Erase the pointer cursor
   GLB	VidShowPtr	Draw the pointer cursor
   GLB	VidMovePtr	Update the cursor position
   GLB	VidSetPtr	Set up a new cursor picture

   INT	CondHidePtr	Temporarily hide the cursor while in a drawing operation
   INT	ReShowPtr	Show the cursor


REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	tony	11/88	initial version


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

	$Id: dumbcomPointer.asm,v 1.1 97/04/18 11:42:27 newdeal Exp $

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
		test for save-under overlaps;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	10/88...	Initial version
	Doug	1/90		Added save-under overlap detection

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidMovePtr	proc	near
	mov	cx,cs
	mov	ds,cx

	; erase cursor if visible

	cmp	cs:[cursorCount],0
	jnz	noCursorCheckXOR

	push	ax, bx

	call	EraseCursor

	; if moving XOR region with pointer then do special stuff

	cmp	cs:[xorFlags], 0
	jz	noXOR
	pop	ax, bx
	push	ax, bx
	sub	ax, cs:[cursorX]
	sub	bx, cs:[cursorY]
	call	UpdateXORForPtr
noXOR:

	; store new position

	pop	ds:[cursorX], ds:[cursorY]

	call	DrawCursor
	jmp	common

AfterCursorRedrawn:

	; store new position

	mov	ds:[cursorX],ax
	mov	ds:[cursorY],bx

common:
if	SAVE_UNDER_COUNT	gt	0
	cmp	cs:[suCount], 0			; any active save under areas?
	jne	CheckSUAreas
endif
	clr	al
	ret

	; there is not cursor, but check the XOR update, will you ?
noCursorCheckXOR:
	cmp	cs:[xorFlags], 0
	jz	AfterCursorRedrawn
	push	ax, bx
	sub	ax, cs:[cursorX]
	sub	bx, cs:[cursorY]
	call	UpdateXORForPtr
	pop	ax, bx
	jmp	AfterCursorRedrawn

if	SAVE_UNDER_COUNT	gt	0
CheckSUAreas:
	mov	ax, ds:[cursorX]		; Fetch location to check at
	mov	bx, ds:[cursorY]
	mov	cx, ax				; Pass rectangle = point
	mov	dx, bx
	GOTO	VidCheckUnder
endif

VidMovePtr	endp
	public	VidMovePtr

ifndef	BIT_CLR4

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
	mov	cx,CUR_SIZE		;handle 16 words

	; Test for inverse mono drivers: are we in inverse mode?
INVRSE <mov	dl, cs:[inverseDriver]					>

VSP_loop:
	lodsw				;get mask word
	not	ax
	mov	bx, ds:[si][CUR_IMAGE_SIZE-2]

INVRSE <tst	dl							>
INVRSE <jz	continueLoadPointer					>
INVRSE <not	bx			; inverse mode: invert pointer	>
INVRSE <xor	bx, ax							>
INVRSE <continueLoadPointer:						>

	; ax = 0's, bx = 1's

	stosb				;store 0's low
	mov	al,bl
	stosb				;store 1's low
	mov	al,ah
	stosb				;store 0's high
	mov	al,bh
	stosb				;store 1's high

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
endif

COMMENT @-----------------------------------------------------------------------

FUNCTION:	CondHidePtr

DESCRIPTION:	Temporarily hide the pointer while in a drawing operation

CALLED BY:	INTERNAL
		CommonRectHigh

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

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

ifndef	BIT_CLR4

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
-------------------------------------------------------------------------------@

DrawCursor	proc	near
	mov	ax,cs
	mov	ds,ax

	; calculate X variables

	clr	bh
	clr	dx				;value to self modify jumps 1,2
	mov	ax,ds:[cursorX]			;calculate real x position
	mov	bl,ds:[cursorHotX]
	sub	ax,bx
	mov	cx,ax
	mov	bl,0				;value to self modify 3rd jumnp

	; ax = x byte position -- set up correct draw and erase code to use
	; based on clipping state

	jb	DC_left				;if clipped left then branch

	shr	ax,1				;get byte position
	shr	ax,1
	shr	ax,1
						;assume entirely visible
	mov	bh,offset EraseCursorNormal-EC_eraseRoutine - 1
	mov	di,CUR_SIZE+8-1			;bits covered
	mov	bp, -3
	cmp	ax,SCREEN_BYTE_WIDTH-2
	jb	DC_together			;if no clipping then branch

	mov	di,CUR_SIZE-1			;assume clipped one byte right
	mov	bh,offset EraseCursor2-EC_eraseRoutine - 1
	mov	bp, -2
	mov	bl,offset DCL_skip3 - DCL_jump3 - 1
	jz	DC_together			;if clipped 1 right then branch

	; 2 bytes clipped in x (right)

	mov	dh,offset DCL_skip2 - DCL_jump2 - 1
	mov	bh,offset EraseCursor1-EC_eraseRoutine - 1
	mov	di,CUR_SIZE-8-1			;bits covered
	mov	bp, -1
	jmp	short DC_together

DC_left:
	; assume clipped one byte left
	mov	bh,offset EraseCursor2-EC_eraseRoutine - 1
	mov	di,CUR_SIZE-1			;bits covered
	mov	bp, -2
	mov	dl,offset DCL_skip1 - DCL_jump1 - 1
	cmp	ax,-8			;test for 1 byte clipped
	jge	DC_togetherLeft

	; 2 bytes clipped in x (left)

	mov	dh,offset DCL_skip2 - DCL_jump2 - 1
	mov	bh,offset EraseCursor1- EC_eraseRoutine - 1
	mov	di,CUR_SIZE-8-1			;bits covered
	mov	bp, -1

DC_togetherLeft:
	clr	ax

DC_together:
	and	cl,7				;cl = shift count
	mov	ds:[DCL_jump1],dl		;self modify draw routine
	mov	ds:[DCL_jump2],dh
	mov	ds:[DCL_jump3],bl
	mov	ds:[EC_eraseRoutine],bh		;store erase routine
	StoreNextScanMod	<ds:[DCL_nextScanOffset]>, bp

	mov	bp,ax				;save byte offset in bp
	shl	ax,1
	shl	ax,1
	shl	ax,1				; don't need this for tandy 
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
if IS_REALLY_SMALL_BANKS
	mov	ds:[cursorScanLine], di
	mov	ds:[cursorXPosition], bp
	CalcScanLine	di, bp			;; Calc scan line, add offset
else
	CalcScanLine	di, bp			;; Calc scan line, add offset
	mov	ds:[cursorScreenAddr],di
endif

	mov	bp,offset dgroup:cursorBuffer

	; point at cursor data

	add	si,offset dgroup:cursorImage

	; ds:si = cursor data
	; cl = shift count
	; es:di = screen address
	; bp = background buffer
	; ch = lines to draw

	FALL_THRU	DrawCursorLow

DrawCursor	endp
	public	DrawCursor

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawCursorLow

DESCRIPTION:	Draw the cursor not clipped in X

CALLED BY:	INTERNAL
		DrawCursor

PASS:
	ds:si - data
	ds:bp - background save buffer
	cl - shift count
	ch - lines to draw
	es:di - screen buffer address

RETURN:
	none

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

DrawCursorLow	proc	near
DCL_loop:

	; Do first byte

	lodsb				;bl = zeros
	mov	bl,al
	lodsb				;dl = ones
	mov	dl,al

	mov	bh,0ffh			;shift in 1's
	clr	dh			;shift in 0's
	ror	bx,cl			;bl = data, bh = bits for next byte
	ror	dx,cl			;dl = data, dh = bits for next byte

DCL_1	label	byte
DCL_jump1	=	DCL_1 + 1
	jmp	short DCL_skip1
	.warn	-unreach
RW <	xornf di, 1h							>
	mov	al,es:[di]		;get screen data
RW <	xornf di, 1h							>
	.warn	@unreach
	mov	ds:[bp],al		;save background
	and	al,bl			;mask out bits to RESET
	xor	al,dl			;mask in bits to SET
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	inc	bp

DCL_skip1 label near

	; Do second byte

	lodsb				;bl = zeros data
	mov	bl,al
	lodsb				;dl = zeros data
	mov	dl,al
	mov	al,bh			;save shifted bits
	mov	ah,dh

	mov	bh,0ffh			;shift in 1's
	clr	dh			;shift in 0's
	ror	bx,cl			;bl = data, bh = bits for next byte
	ror	dx,cl			;dl = data, dh = bits for next byte
	and	bl,al			;or in bits from first byte
	xor	dl,ah

DCL_2	label	byte
DCL_jump2	=	DCL_2 + 1
	jmp	short DCL_skip2
	.warn	-unreach
RW <	xornf di, 1h							>
	mov	al,es:[di]		;get screen data
RW <	xornf di, 1h							>
	.warn	@unreach
	mov	ds:[bp],al		;save background
	and	al,bl			;mask out bits to RESET
	xor	al,dl			;mask in bits to SET
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	inc	bp

	; Do third byte

DCL_skip2 label near

DCL_3	label	byte
DCL_jump3	=	DCL_3 + 1
	jmp	short DCL_skip3
	.warn	-unreach
RW <	xornf di, 1h							>
	mov	al,es:[di]		;get screen data
RW <	xornf di, 1h							>
	.warn	@unreach
	mov	ds:[bp],al		;save background
	and	al,bh			;mask out bits to RESET
	xor	al,dh			;mask in bits to SET
ifdef	REVERSE_WORD
	call	DoStosb
else
	stosb
endif
	inc	bp

DCL_skip3 label near

	NextScanMod	di,DCL_nextScanOffset
	dec	ch
	jz	DCL_end
	jmp	DCL_loop
DCL_end:
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
if IS_REALLY_SMALL_BANKS
	mov	di,ds:[cursorScanLine]
	mov	ax, ds:[cursorXPosition]
	CalcScanLine	di, ax
else
	mov	di,ds:[cursorScreenAddr]
endif

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
ifdef	REVERSE_WORD
	call	DoMovsw
	call	DoMovsb
else
	movsw
	movsb
endif

	NextScan di, -3
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

EraseCursor2	proc	near
EC2_loop:
ifdef REVERSE_WORD
	call	DoMovsw
else
	movsw
endif

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
ifdef REVERSE_WORD
	call	DoMovsb
else
	movsb
endif
	NextScan di, -1
	loop	EC1_loop
	ret

EraseCursor1	endp
	public	EraseCursor1
endif
