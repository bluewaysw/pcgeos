
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		VGALike video drivers
FILE:		vgacomRaster.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name		Description
	----		-----------
    INT BltSimpleLine		blt a single scan line
    INT ReadWriteEdge		blt a single scan line
    INT BltSimpleRight		Blt a simple line from right to left
    INT BltShift		Transfer a single scan line that needs to
				be shifted
    INT DisplayBuffer		Utility routine for BltShift, to copy temp
				buffer to screen (copies just one bit plane
				of data, up to one screen width by one scan
				line)
    INT PutColorScan		Transfer a scan line's worth of system
				memory to screen
    INT LoadUp8Pixels		Shift in enough data to make a whole 4x1
				byte output
    INT LoadUp8Palette		Shift in enough data to make a whole 4x1
				byte output
    INT LoadUp8PaletteOdd	Shift in enough data to make a whole 4x1
				byte output
    INT PaletteMap8Pixels	Shift in enough data to make a whole 4x1
				byte output
    INT LoadUp8PixelsOdd	Shift in enough data to make a whole 4x1
				byte output
    INT LoadUpSomePixels	Shift in enough data to make a whole 4x1
				byte output
    INT FillBWScan		Transfer a scan line's worth of system
				memory to screen draws monochrome info as a
				mask, using current area color
    INT PutBWScan		Draw a b/w scan line of a monochrome bitmap
    INT DoMonoPalette		Do some setup work for a monochrome bitmap
				with a palette
    INT PutBWScanMask		Write a monochrome bitmap with a store mask
    INT NullBMScan		Write a monochrome bitmap with a store mask
    INT SetMEGAFillColor	Some stuff to do special for MEGA
    INT GetOneScan		Copy one scan line of video buffer to
				system memory
    INT ReadOneByte		Copy one scan line of video buffer to
				system memory

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/88	initial version
	jeremy	5/91	added support for EGA compatible, monochrome,
			and inverse mono EGA drivers
	jim	3/92	Optimized Color Bitmap drawing code, removed 512-byte
			table

DESCRIPTION:
	This is the source for some of the VGALike video drivers bit block 
	transfer routines.

	$Id: vgacomRaster.asm,v 1.1 97/04/18 11:42:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

VideoBlt	segment	resource

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltSimpleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	blt a single scan line 

CALLED BY:	INTERNAL

PASS:		bx	- first x point in simple region
		ax	- last x point in simple region
		d_x1	- left side of blt
		d_x2	- right side of blt
		es:si	- points to scan line start of source
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		if source is to right of destination
		   mask left;
		   copy left byte;
		   mask = ff;
		   copy middle bytes
		   mask right;
		   copy right byte;
		else
		   do the same, but from right to left

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

BltSimpleLine	proc	near
	push	ds			; save window seg
	segmov	ds, es			; set both -> screen

	; calc some setup values

	mov	bx, ss:[bmLeft]		; save passed values for BltShift
	mov	ax, ss:[bmRight]

	; calculate # bytes to fill in and indices into source and dest
	; scan lines.  We have to compensate here if the left side of the
	; clip region is to the right of the left side of the destination
	; rectangle.

	mov	dx, bx			; save left clipped side of dest
	mov	cl, 3			; want to do two 3bit shifts
	sar	ax, cl			; ax = byte index to right side of dest
	sar	bx, cl			; bx = byte index to left side of dest
	add	di, bx			; add bytes to left side of dest
	sub	dx, ss:[d_x1]		; sub dest unclipped left side
	add	dx, ss:[d_x1src]	; get offset to source
	mov	ch, dl			; save low byte of position for later
	sar	dx, cl			; shift to get byte index
	add	si, dx			;  add that to source index
	sub	ax, bx			; ax = count of bytes - 1
	mov	dx, GR_CONTROL		; set dx -> ega control register
	mov	bx, {word} ss:[bmRMask]	; bx = left/right masks

	; check to see if we need to shift anything, then use another routine

	xchg	cx, ax			; cx = count, ah=low byte of source
	mov	al, ah			; get low byte of source in ah
	mov	ah, byte ptr ss:[bmLeft] ;  and low byte of dest pos
	and	ax, 0707h		; isolate low three bits of each
	cmp	al, ah			; if == then on same bit boundary
	je	BSL_bytemove		;  yes, do fast one
	jmp	BltShift		;  no, need to do slow one

BSL_bytemove:
	tst	cx			; see if need to combine left/right
	jnz	BSL_nocombine		;  no, check on direction of transfer
	mov	ah, bl			; combine masks
	and	ah, bh
	mov	al, BITMASK		; set up EGA reg number
	jmp	short	BSL_last

	; check to see if we need to copy from right to left
BSL_nocombine:
	mov	ax, ss:[d_x1]		; get destination left side
	cmp	ax, ss:[d_x1src]	; compare to source left side
	jg	BltSimpleRight		;  copy right to left

	mov	al, BITMASK		; set up EGA reg number
	mov	ah, bh			; set up left mask
	out	dx, ax			; set up mask

	mov	bh, cl			; save count here, only use 1 push
	push	bx

	; need special code to read/write the edges

	call	ReadWriteEdge
	inc	si			; bump memory pointers
	inc	di
	mov	al, BITMASK
	pop	bx

BSL_common label near
	dec	bh			; if zero, then no center bytes
	jz	BSL_right

	mov	cl, bh
	clr	ch
	mov	ah, 0xff		; use solid mask for center
	out	dx, ax			; set mask
	rep	movsb			; move the bytes

BSL_right:
	mov	ah, bl			; get right mask
BSL_last:
	out	dx, ax

	; need special code to read/write the edges

	call	ReadWriteEdge
	cld				; make sure flag set right
	pop	ds			; restore ds
	ret


BltSimpleLine	endp
	public	BltSimpleLine

		; utility routine to read/write edge EGA bytes

ReadWriteEdge	proc	near
		ReadBitPlanes	ds, si, bh,bl,ch,cl
		StartBitWrite
		WriteBitPlanes	ds, di, bh,bl,ch,cl
		EndBitWrite
		ret
ReadWriteEdge	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltSimpleRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Blt a simple line from right to left

CALLED BY:	INTERNAL
		BltSimpleLine

PASS:		si	- offset to left side of source block
		di	- offset to left side of dest block
		cx	- #bytes to copy - 1
		dx	- EGA control register address
		bh	- left side mask
		bl	- right side mask
		es,ds	- frame buffer

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		   mask right;
		   copy right byte;
		   mask = ff;
		   copy middle bytes
		   mask left;
		   copy left byte;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	03/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	BltSimpleRight
BltSimpleRight	proc	near
		add	si, cx			; get to right side of blt
		add	di, cx			; for both source and dest
		std				; we want to do it backwards
		mov	al, BITMASK		; set up EGA reg index

		; do right side -- first mask it, then copy it

		mov	ah, bl			; set up right mask
		out	dx, ax			; set up mask
		mov	bl, cl			; save count, only use 1 push
		push	bx

		; need special code to read/write the edges

		call	ReadWriteEdge
		dec	si			; bump memory pointers
		dec	di
		mov	al, BITMASK
		pop	bx
		xchg	bh, bl			; get left mask in bl
		jmp	BSL_common		; rejoin code above

BltSimpleRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltShift
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a single scan line that needs to be shifted

CALLED BY:	INTERNAL
		BltSimpleLine

PASS:		ds:si	- ptr to start of src pixels to move (may need adjust)
		es:di	- ptr to start of dst pixels to move 
		al	- low 3 bits of source x position
		ah	- low 3 bits of dest x pos
		bl	- right side mask
		bh	- left side mask
		cx	- # destination bytes to fill
		dx	- GR_CONTROL (EGA control register)

RETURN:		nothing
		jumped to by BltShift, so this returns to BltSimpleLine's caller

DESTROYED:	ax,bx,cx,dx,si,di

STACK USAGE:
		see BFrame structure, below

PSEUDO CODE/STRATEGY:
		allocate a buffer on the stack;
		copy/shift current scan line (one bit plane at a time) to
		  this buffer;
		copy the buffer to its new location on screen;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine allocates a buffer on the stack which can be
		as many as SCREEN_BYTE_WIDTH bytes.  No stack overflow
		checking is done.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BFrame	struct				; stack frame structure
    BF_dptr	dw	?		; destination ptr (into frame buffer)
    BF_pbuff	dw	?		; pointer to stack frame buffer
    BF_rmask	db	?		; right side mask
    BF_lmask	db	?		; left side mask
    BF_bytes	db	?		; # bytes to copy
    BF_preload	db	?		; result of preload test
    BF_plane	db	?		; current bit plane
    BF_shift	db	?		; shift amount
BFrame	ends

BFS	equ	<[bp-size BFrame]>

		public	BltShift
BltShift	proc	near
		push	es		; save extra seg
		push	bp		; save bp, use as frame pointer
		mov	bp, sp		; bp -> current frame
		sub	sp, size BFrame	; allocate local space
		mov	BFS.BF_bytes, cl ; # bytes/scan line 
		add	cx, 2		; make sure even number, + need 1 extra
		and	cx, 0feh	;  low bit 0
		sub	sp, cx		; allocate room for bit plane buffer
		mov	BFS.BF_pbuff, sp ; save pointer for later (sp has
					;   ptr to buffer)
		mov	BFS.BF_dptr, di ; save dest pointer too

		; calculate and save shift amount, other good things

		sub	ah, al		; ah = #bits to shift right (may be < 0)
		mov	BFS.BF_shift, ah	; save shift amount (never be 0)
CEGA <		mov	BFS.BF_plane, 3 ; #bit planes (less 1)		>
MEGA <		mov	BFS.BF_plane, 0 ; #bit planes (less 1)		>
		mov	word ptr BFS.BF_rmask, bx; save left/right masks

		; calculate preload flag.  The calculation goes like this:
		; let dr=dest right, dl=dest left, sr=src right, sl=src left
		; let diff1= ((dl^7)-(sl^7)), diff2=((dr^7)-(sr^7))
		; then flag = (diff1 XOR diff2) AND diff1
		; if flag < 0, then preload

		mov	bx, ss:[d_x1]	; we're going to need these a few times
		mov	dx, ss:[d_x1src]
		mov	cx, ss:[bmLeft] ; calc index into source scan
		mov	ah, cl		; ah = dest left
		and	ah, 7		; ah = dl^7
		sub	cx, bx		; cx = index
		add	cx, dx		; cx = source left
		and	cl, 7		; isolate low three bits
		sub	ah, cl		; ah = ((dl^7)-(sl^7))
		mov	cx, ss:[bmRight] ; calc index into source scan
		mov	al, cl		; al = dest right
		and	al, 7		; al = dr^7
		sub	cx, bx		; cx = index
		add	cx, dx		; cx = source right
		and	cl, 7		; isolate low three bits
		sub	al, cl		; al = ((dr^7)-(sr^7))
		xor	al, ah		; tests for equality (high bit)
		and	ah, al
		mov	BFS.BF_preload, ah	; save test result
		mov	dx, GR_CONTROL	; reload control reg address

		; for each bit plane...
		;   set up the right plane, read/shift/write the bits to buffer
BS_bigLoop:
		push	si		; save source pointer too
		segmov	es, ss		; es -> stack seg for buffer
		mov	di, BFS.BF_pbuff	; get ptr to temp buffer
		mov	ah, BFS.BF_plane	; get next plane to do
		mov	al, READ_MAP	; set up reg to read
		out	dx, ax		; set up right bit plane
		mov	ch, BFS.BF_bytes	; get # bytes/scan to write
		mov	cl, BFS.BF_shift	; get shift amount
		clr	bl		; clear out initial shift-save
		tst	cl		; if shift left, do separate
		js	BS_shiftLeft	; do left shifting

		; check for need to preload the 1st value (more src than dest)
		cmp	byte ptr BFS.BF_preload, 0 ; if > 0, 
		jns	BS_smallLoop	;  then skip preload
		clr	ah		; clear initial shift bits
		lodsb			; get first source byte
		ror	ax, cl		; do shift
		mov	bl, ah		; new initial shift-out bits

		; do the read/shift work, save result in temp buffer
BS_smallLoop:
		clr	ah		; clear out initial shift-in
		lodsb			; get next source byte
		ror	ax, cl		; do the shift
		xchg	bl, ah		; get old shift-in byte
		or	al, ah		; combine bits
		;
		; This is where we want to store data into the output buffer.
		; al	= byte to store.
		; es:di	= frame buffer.
		; If this is the first byte, we need to apply the left-mask.
		; If this is the last  byte, we need to apply the right-mask.
		;
		stosb			; save in temp buffer
		dec	ch		; keep going till middle done
		jns	BS_smallLoop

		; done with this bit plane
BS_nextPlane:
		push	es		; xchg segregs
		segmov	es, ds		; ds:si -> stack frame
		pop	ds		; es:di -> frame buffer
		mov	si, BFS.BF_pbuff ; get pointer to buffer
		mov	di, BFS.BF_dptr	 ; get pointer to screen
		mov	bx, word ptr BFS.BF_rmask ; get masks
		mov	cl, BFS.BF_plane ; get bit plane
		mov	ch, BFS.BF_bytes ; get # bytes to write
		clr	ax		; no mask
		call	DisplayBuffer	; copy stack buffer to screen
		push	es		; restore segregs
		segmov	es, ds		; 
		pop	ds		; 
		pop	si		; restore source pointer
		dec	byte ptr BFS.BF_plane ; 1 less bit plane to do
		jns	BS_bigLoop	; not done, continue

		; all done, cleanup and exit

		mov	sp, bp		; restore stack pointer
		pop	bp		; restore frame pointer
		pop	es		; restore extra seg
		pop	ds		; restore data seg
		ret			; returns to BltSimpleLine's caller

;---------------------------------------------------------------------

		; special case: need to shift left
		; check for need to preload the first value (more src than dest)
BS_shiftLeft:
		neg	cl		; make positive
		clr	ah
		lodsb			; get first source byte
		rol	ax, cl		; do shift
		mov	bl, al		; new initial shift-out bits

		; check # bytes to write, if 0, then combine masks and do right
BSL_smallLoop:
		clr	ah		; clear out initial shift bits
		lodsb			; get next source byte
		rol	ax, cl		; do the shift
		xchg	bl, al		; get old shift-in byte
		or	al, ah		; combine bits
		stosb			; save in temp buffer
		dec	ch		; keep going till middle done
		js	BS_nextPlane
		jne	BSL_smallLoop
		cmp	byte ptr BFS.BF_preload, 0 ; if > 0, 
		js	BSL_smallLoop	;  then preload done
		mov	al, bl
		stosb
		jmp	BS_nextPlane	; continue with copy to screen
BltShift	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for BltShift, to copy temp buffer to screen
		(copies just one bit plane of data, up to one screen width
		 by one scan line)

CALLED BY:	INTERNAL
		BltShift

PASS:		ds:si	- source buffer
		es:di	- dest ptr (into screen memory)
		dx	- GR_CONTROL
		cl	- which bit plane to write
		ch	- # bytes to write
		bl	- right mask
		bh	- left mask
		ax	- offset from mask data to image data (0 for no mask)

RETURN:		nothing

DESTROYED:	ax,cx,si,di

PSEUDO CODE/STRATEGY:
		just copy buffer from stack frame to screen

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	DisplayBuffer
DisplayBuffer	proc	near
		
		; use bp to store mask offset

		push	bp			; save frame pointer
		mov	bp, ax			; save offset

		; twiddle with EGA to enable writes to one plane

		StartBitWrite			; set up EGA regs
		mov	dx, GR_SEQUENCER	; set up correct plane to write
		mov	ah, 1			;  and use as shift count
		shl	ah, cl
		mov	al, MAP_MASK		; set up right EGA reg
		out	dx, ax			; sets right plane to write
		mov	dx, GR_CONTROL		; restore EGA reg address
		mov	cl, ch			; # bytes to write
		clr	ch

		; if only one byte to write, combine masks and be done with it

		mov	al, BITMASK		; get set to mask
		mov	ah, bh			; get left mask
		tst	bp			; see if any mask component
		jnz	DB_masked		;  yes, do it different
		tst	cx			; only one byte ?
		jne	DB_many			;  no, normal case
		and	ah, bl			; combine right mask
		jmp	DB_right		; make like it's the right one

		; do the left byte, appropriately masked
DB_many:
		out	dx, ax
		lodsb				; get left byte to write
		and	es:[di], al		; write it
		inc	di
		dec	cx			; one less to do
		je	DB_doright

		; read bytes from buffer and write, one at a time

		mov	ah, 0xff		; solid mask for middle
		mov	al, BITMASK
		out	dx, ax			; set up mask
DB_loop:
		lodsb				; get next byte
		and	es:[di], al		; write it out
		inc	di			; bump dest pointer
		loop	DB_loop			; do all the bytes

		; do the right byte, appropriately masked
DB_doright:
		mov	al, BITMASK
		mov	ah, bl			; get right side mask
DB_right	label	near
		out	dx, ax			; set up mask
		lodsb				; get byte
		and	es:[di], al		; write byte

		; clean up EGA, restore some regs and exit

		mov	dx, GR_SEQUENCER
CEGA <		mov	ax, MAP_MASK_ALL	; re-enable all planes	>
MEGA <		mov	ax, MAP_MASK_0		; enable just one plane	>
		out	dx, ax			
		mov	dx, GR_CONTROL		; restore dx
		EndBitWrite
		pop	bp
		ret
DisplayBuffer	endp

;-------------------------------------------------------------------------

		; some mask stored with image, do the right thing
DB_masked:
		and	ah, ds:[si][bp]		; combine with stored mask
		tst	cx			; only one byte ?
		jne	DBM_many		;  no, normal case
		and	ah, bl			; combine right mask
		jmp	DB_right		; make like it's the right one

		; do the left byte, appropriately masked
DBM_many:
		out	dx, ax
		lodsb				; get left byte to write
		and	es:[di], al		; write it
		inc	di
		dec	cx			; one less to do
		je	DBM_doright

		; read bytes from buffer and write, one at a time
DBM_loop:
		mov	al, BITMASK
		mov	ah, ds:[si][bp]		; get mask from buffer
		out	dx, ax			; set up mask
		lodsb				; get next byte
		and	es:[di], al		; write it out
		inc	di			; bump dest pointer
		loop	DBM_loop		; do all the bytes

		; do the right byte, appropriately masked
DBM_doright:
		mov	al, BITMASK
		mov	ah, bl			; get right side mask
		and	ah, ds:[si][bp]		; combine with stored mask
		jmp	short DB_right

VideoBlt	ends


VideoBitmap	segment	resource
ifndef IS_MEGA

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:

		build out a group of 8 pixels, then
		write each byte, using write mode 0 of EGA

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/89		Initial version
	Jim	12/89		Changed to new 4-bit wide pixels
	Jim	8/90		changed to use write mode 0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

		; this macro is used to shift in one 4-bit pixel into 4
		; 1-byte planes of data
		;
		; Pass:	  al = byte containing pixel data.
		;	  bl, bh, cl, ch = data.
		; Return: bl, bh, cl, ch = data with new pixel shifted in.
		;
ShiftInPixel	macro				; 16 clock cycles
		rcl	al, 1			; do plane 3
		rcl	bl, 1			; 
		rcl	al, 1			; do plane 2
		rcl	bh, 1			; 
		rcl	al, 1			; do plane 1
		rcl	cl, 1			; 
		rcl	al, 1			; do plane 0
		rcl	ch, 1			; 
endm

		; this macro writes the registers out to the EGA
Write8Pixels	macro	control
		mov	al, es:[di]		; load the latches
		
		mov	dx, GR_SEQUENCER	; enable plane 0
		mov	ax, MAP_MASK_0
		out	dx, ax
		mov	es:[di], ch		; write out plane 0

CEGA <		shl	ah, 1			; enable next plane	>
CEGA <		out	dx, ax						>
CEGA <		mov	es:[di], cl		; write out plane 1	>

CEGA <		shl	ah, 1			; enable next plane	>
CEGA <		out	dx, ax						>
CEGA <		mov	es:[di], bh		; write out plane 2	>
		
CEGA <		shl	ah, 1			; enable next plane	>
CEGA <		out	dx, ax						>

CEGA <		mov	al, bl						>
CEGA <		stosb				; write out plane 3	>
MEGA <		inc	di			; and move to next byte >

ifnb	<control>
		; Caller doesn't want GR_CONTROL loaded into dx.
else
		mov	dx, GR_CONTROL		; get i/o address of cntrlR
endif

endm

		; define a type for the preload flags so we don't get
		; confused
PCSPreloadFlags	record
    :5,				; unused bits
    PL_FIRST_DATA:1,		; preload the first data byte
    PL_BYTE_BOUNDARY:1,		; preloaded on byte boundaries
    PL_FIRST_MASK:1		; preload the first mask byte
PCSPreloadFlags	end

PutColorFrame	struct
    midCount	word			; #middle bytes to write
    maskPointer	word			; ptr to mask data
    bitmapMask	byte			; for bitmaps with masks
    preloadflag	PCSPreloadFlags		; pixel index into data
					;  bit0: preload first byte?
					;  bit1: byte boundary(screen)
					;	 on odd bound (bitmap)
PutColorFrame	ends

loadUpPalette	label	near
		mov	dx, offset cs:LoadUp8PaletteOdd - 3
		and	cl, mask PL_BYTE_BOUNDARY ; set this flag
		jnz	load8SetJump
		mov	dx, offset cs:LoadUp8Palette - 3
		jmp	load8SetJump

PutColorScan	proc	near
PCframe		local	PutColorFrame
		.enter			

		; first set up some info and save values on stack

		mov	bx, ss:[bmLeft]		; get left and right values
		mov	ax, ss:[bmRight]
		mov	cl, al			; calc shift amount
		and	cl, 7			; isolate low three bits
		mov	cs:rightCount, cl	; save initial mask
		mov	cs:rightShift, cl	; save initial mask
		mov	cl, ss:lineMask		; optimize for inner loop
		mov	cs:middleLineMask, cl
		mov	cl, bl
		and	cl, 7
		mov	cs:leftCount, cl	; save initial mask
		mov	cl, ss:[bmShift]	
		mov	cs:maskShift, cl	; amount to shift mask
		mov	dx, si			; calc mask pointer
		sub	dx, ss:[bmMaskSize]	; get to beginning of mask
		mov	PCframe.maskPointer, dx

		; calc preload flags and # bytes to fill in

		mov	ch, ss:[bmPreload]	; get preload flag
		rol	ch, 1			; get preload bit into bit 0
		and	ch, 1
		shl	cl, 1

		; Since we are going to be nuking dx in a moment, we can use
		; it here.  If there is a palette, use a different pixel load
		; routine

		test	ss:[bmType], mask BMT_PALETTE
		jnz	loadUpPalette
		mov	dx, offset cs:LoadUp8PixelsOdd - 3
		and	cl, mask PL_BYTE_BOUNDARY ; set this flag
		jnz	load8SetJump
		mov	dx, offset cs:LoadUp8Pixels - 3
load8SetJump	label	near
		;
		; Set to the correct offset and stuff the routine to call.
		;
		sub	dx, offset cs:load8routine1label
		mov	cs:load8routine1, dx
		add	dx, offset cs:load8routine1 - offset cs:load8routine2
		mov	cs:load8routine2, dx

		or	ch, cl
		shr	cl, 1 
		xor	cl, bl
		shl	cl, 1			; get to proper offset
		shl	cl, 1
		and	cl, mask PL_FIRST_DATA
		or	ch, cl
		mov	PCframe.preloadflag, ch
		mov	dx, bx			; save starting position
		mov	cl, 3			; want to get byte indices
		shr	ax, cl
		shr	bx, cl
		add	di, bx			; add to screen offset too
		sub	dx, ss:[d_x1]		; sub left coordinate
		mov	cx, dx			; save register for use later
		shr	dx, 1			; div by 2 since 4bit/pixel
		add	si, dx			; add in the initial data ptr

		; check for mask, bump source pointer over it if present

		mov	cs:initLeftMask, 0xff
		test	ss:[bmType], mask BMT_MASK ; mask present ?
		jz	maskDone		;  yes, do some calculations
		add	cl, cs:maskShift	; make sure shifting doesn't
		adc	ch, 0
		shr	cx, 1			;  overflow to next byte
		shr	cx, 1
		shr	cx, 1
		add	PCframe.maskPointer, cx	; save away index

		; if we need to preload, then preload the mask as well

		mov	cs:initLeftMask, 0
		test	PCframe.preloadflag, mask PL_FIRST_MASK 
		jz	maskDone
		mov	cx, bx			; save old bx
		mov	bx, PCframe.maskPointer ; get pointer 
		dec	bx			; point to prev mask byte
		mov	dh, ds:[bx]		; load mask byte
		clr	dl
		xchg	bx, cx			; restore bx
		mov	cl, cs:[maskShift]	; get shift count
		shr	dx, cl			; shift mask
		mov	cs:[initLeftMask], dl	; save shifted preloaded mask

		; mask calcs done, set up controller: set draw mode
maskDone:
		mov	cx, ax			; figure out #middle bytes
		sub	cx, bx			
		mov	dx, GR_CONTROL		; get i/o address of cntrlR
		mov	ax, WR_MODE_0		; set write mode 2
		out	dx, ax			; set mode
		mov	ax, EN_SR_NONE		; set write mode 2
		out	dx, ax			; set mode
		mov	bl, ss:[currentDrawMode] ; get mode
		clr	bh			; make into a byte table index
		mov	ah, ss:egaFunc[bx]	; grab ega mode equivalent
		mov	al, DATA_ROT		; set up right reg
		out	dx, ax			; set data/rot register
		mov	cs:rightTestBit, mask PL_BYTE_BOUNDARY

		; check to see if there is only one byte to draw.  if so, do
		; some extra calcs and make like we're drawing the right side
		; byte

		dec	cx			; cx = #middle bytes
		mov	PCframe.midCount, cx	; save count
		jns	doLeftMask		; if negative, then one byte 
		mov	cl, ss:[bmLMask]	; combine masks
		and	ss:[bmRMask], cl
		mov	cl, cs:leftCount	; new left side value
		sub	cs:rightCount, cl	; new right side value
		mov	cs:rightTestBit, mask PL_FIRST_DATA
		mov	bx, PCframe.maskPointer	; get pointer to mask data

		; right side may need a pre-load too

		test	PCframe.preloadflag, mask PL_FIRST_DATA 
		jz	jmptotheright
		lodsb				; get first byte
		test	ss:[bmType], mask BMT_PALETTE
		jz	shiftPreload
		push	es
		les	bx, ss:[bmPalette]	; es:bx -> palette
		xlat	es:[bx]			; translate byte
		pop	es
shiftPreload:
		mov	cl, 4			; shift up a nibble
		shl	al, cl			; do it
		mov	cs:rightPreLoad, al
jmptotheright:
		mov	al, cs:initLeftMask	; combine masks
		test	ss:[bmType], mask BMT_MASK
		LONG jz	sendRMask
		jmp	doRightMask		;  only need to do right

		; DO LEFT SIDE BYTE		; set up mask first
doLeftMask:
		mov	ah, 0xff		; assume all bits
		mov	bx, PCframe.maskPointer	; get it
		test	ss:[bmType], mask BMT_MASK ; may not do anything
		jz	sendLMask
		mov	cl, cs:maskShift
		clr	ah
		mov	al, ds:[bx]		; apply mask
		ror	ax, cl
initLeftMask	equ	(this byte) + 1
		or	al, 0xff		; get last overflow mask bits
		mov	cs:initMidMask, ah
		mov	ah, al			; set it up
		inc	bx
		mov	PCframe.maskPointer, bx	; set up next pointer
sendLMask:
		and	ah, ss:[bmLMask]	; combine with left mask
		and	ah, ss:lineMask		; see if bit still set
		mov	al, BITMASK
		out	dx, ax			; apply mask

		; OK, we're ready to party.  See if we have to pre-load the
		; first byte in order to do some shifting

		test	PCframe.preloadflag, mask PL_FIRST_DATA
		jz	loadLeftPlane
		lodsb				; get first byte
		test	ss:[bmType], mask BMT_PALETTE
		jz	shiftPreloadLeft
		push	es
		les	bx, ss:[bmPalette]	; es:bx -> palette
		xlat	es:[bx]			; translate byte
		pop	es
shiftPreloadLeft:
		mov	cl, 4			; shift up a nibble
		shl	al, cl			; do it

		; we init the plane spaces with a single bit.  We can tell
		; when we're done building a byte when the bit is shifted out.
loadLeftPlane:
leftCount	equ (this byte) + 1		; init all the planes
		mov	cl, 0xff
		mov	ch, 1			; get a bit in the right
		shl	ch, cl			;   slot
		mov	cl, mask PL_FIRST_DATA	; check for pre-loading first  
		call	LoadUpSomePixels	; load up the plane data
		mov	cs:middlePreLoad1, al	; save byte, just in case
		mov	cs:middlePreLoad2, al	; save byte, just in case
		Write8Pixels			; write out the pixels

		mov	bx, PCframe.maskPointer
		test	ss:[bmType], mask BMT_MASK
		LONG jnz anyMiddleLeftMask	;  yes, different center loop
		mov	ah, ss:lineMask		; see if bit still set
		mov	al, BITMASK
		out	dx, ax			;  apply mask
		mov	al, cs:middlePreLoad2	; save byte, just in case
		jmp	anyMiddleLeft

		; DO MIDDLE BYTES
nextMiddle:
middlePreLoad1	equ	(this byte) + 1
		mov	al, 0xff

load8routine1label:
load8routine1	equ	(this word) + 1
		call	LoadUp8Pixels		; MODIFIED

		mov	cs:middlePreLoad1, al
anyMiddleLeft:
		dec	PCframe.midCount	; any left ?
		jns	nextMiddle
		
		mov	dx, GR_CONTROL
		mov	cs:rightPreLoad, al
		mov	al, 0xff		; set up whole mask 

		; DO RIGHT SIDE BYTE
		; ch = left over mask
sendRMask:
		mov	ah, al
		and	ah, ss:[bmRMask] 
		and	ah, ss:lineMask		; see if bit still set
		mov	al, BITMASK
		out	dx, ax			; apply mask

rightCount	equ	(this byte) + 1
		mov	cl, 0xff
		mov	ch, 0x80		; get a bit in the right
		shr	ch, cl			;   slot
rightTestBit	equ	(this byte) + 1
		mov	cl, 0xff 		; this is BYTE_BOUNDARY normly
rightPreLoad	equ	(this byte) + 1
		mov	al, 0xff
		call	LoadUpSomePixels	; load up the plane data
		mov	al, cl			; save one plane of data
		mov	cl, 7			; this is the max
rightShift	equ	(this byte) + 2
		sub	cl, 0xff
		shl	bl, cl			; do all the shifts
		shl	bh, cl			; do all the shifts
		shl	ch, cl			; do all the shifts
		shl	al, cl			; do all the shifts
		mov	cl, al			; move plane back
		Write8Pixels	

CEGA <		mov	ax, EN_SR_ALL		; enable set/reset	>
MEGA <		mov	ax, 0x0101		; enable s/r for plane 1 >
		out	dx, ax			; 
		mov	ax, BMASK_ALL		; set all bit masks
		out	dx, ax			; set mode
		
		mov	dx, GR_SEQUENCER
		mov	ax, MAP_MASK_ALL	; Re-enable all planes.
		out	dx, ax
		.leave
		ret

nextMiddleMask:
maskShift	equ	(this byte) + 1
		mov	cl, 0xff		; SELF_MODIFICATION
		clr	ah
		mov	al, ds:[bx]		; apply mask
		ror	ax, cl
initMidMask	equ	(this byte) + 1
		or	al, 0xff		; get last overflow mask bits
		mov	cs:initMidMask, ah
middleLineMask	equ	(this byte) + 1
		and	al, 0xff		; see if bit still set
		mov	ah, al
		mov	al, BITMASK		;  no, just enable all pixels
		out	dx, ax			;  apply mask
		inc	bx			; for next time
		push	bx			; save mask pointer
middlePreLoad2	equ	(this byte) + 1
		mov	al, 0xff

load8routine2	equ	(this word) + 1
		call	LoadUp8Pixels		; load/write pixels

		mov	dx, GR_CONTROL
		mov	cs:middlePreLoad2, al
		pop	bx			; restore mask pointer
anyMiddleLeftMask:
		dec	PCframe.midCount	; any left ?
		jns	nextMiddleMask		;  no, do the right byte
		;
		; At this point al may be garbage (if we get here from
		; loadLeftPlane) but the value we want to store in rightPreLoad
		; is still intact in middlePreLoad2.
		;
		mov	al, cs:middlePreLoad2	; reload al.
		mov	cs:rightPreLoad, al
		mov	al, cs:initMidMask
doRightMask:
		mov	cl, cs:maskShift
		mov	ah, ds:[bx]		; apply bitmap mask
		shr	ah, cl
		or	al, ah
		jmp	sendRMask		;  no, do the right byte
PutColorScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadUp8Pixels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift in enough data to make a whole 4x1 byte output

CALLED BY:	PutColorScan

PASS:		ds:si	- pointer to next source byte

RETURN:		bl,bh,cl,ch - 4 planes of info ready to go
		ds:si	- points at NEXT byte to read

DESTROYED:	al	- has current byte in it

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadUp8Pixels	proc	near

	; add in those four pixels

	push	di			; save index
	lodsw				; grab bitmap data
	rol	ah, 1			; align pixels in each half of the
	rol	ah, 1			;  word in a funny way
	mov	di, ax			; save original bits
	and	ax, 0x33cc		; isolate bits from planes 2 and 3
	or	al, ah			; combine them
	xor	ah, ah			; make them an index
	xchg	di, ax			; restore originals, di -> table
	shl	di, 1			; table entries are words
	mov	bx, cs:splitTable[di]	; add in 8 bits (4 ea in bl and bh)
	and	ax, 0xcc33		; isolate other (plane 0/1) bits
	or	al, ah			; combine, as before
	rol	al, 1			; rotate, so we can use the same table
	rol	al, 1
	xor	ah, ah			; make it an index
	mov	di, ax			; setup to access table
	shl	di, 1			; table entries are words
	mov	cx, cs:splitTable[di]	; add in 8 bits (4 ea in cl and ch)

	; make room for four more pixels

	mov	di, cx			; save cx
	mov	cl, 4
	shl	di, cl			; shift cx bits and bx bits
	shl	bx, cl
	mov	cx, di			; restore cx bits

	; load up next four pixels and combine with what's there

	lodsw
rejoinLoadUp8	label	near
	rol	ah, 1			; align pixels in each half of the
	rol	ah, 1			;  word in a funny way
	mov	di, ax			; save original bits
	and	ax, 0x33cc		; isolate bits from planes 2 and 3
	or	al, ah			; combine them
	xor	ah, ah			; make them an index
	xchg	di, ax			; restore originals, di -> table
	shl	di, 1			; table entries are words
	or	bx, cs:splitTable[di]	; add in 8 bits (4 ea in bl and bh)
	and	ax, 0xcc33		; isolate other (plane 0/1) bits
	or	al, ah			; combine, as before
	rol	al, 1			; rotate, so we can use the same table
	rol	al, 1
	xor	ah, ah			; make it an index
	mov	di, ax			; setup to access table
	shl	di, 1			; table entries are words
	or	cx, cs:splitTable[di]	; add in 8 bits (4 ea in cl and ch)
	
	pop	di			; restore index
	Write8Pixels noControl	; write em out
	
	ret
LoadUp8Pixels	endp

LoadUp8Palette	proc	near

	; add in those four pixels

	push	di			; save index
	lodsw				; grab bitmap data
	call	PaletteMap4Pixels	; do the mapping
	rol	ah, 1			; align pixels in each half of the
	rol	ah, 1			;  word in a funny way
	mov	di, ax			; save original bits
	and	ax, 0x33cc		; isolate bits from planes 2 and 3
	or	al, ah			; combine them
	xor	ah, ah			; make them an index
	xchg	di, ax			; restore originals, di -> table
	shl	di, 1			; table entries are words
	mov	bx, cs:splitTable[di]	; add in 8 bits (4 ea in bl and bh)
	and	ax, 0xcc33		; isolate other (plane 0/1) bits
	or	al, ah			; combine, as before
	rol	al, 1			; rotate, so we can use the same table
	rol	al, 1
	xor	ah, ah			; make it an index
	mov	di, ax			; setup to access table
	shl	di, 1			; table entries are words
	mov	cx, cs:splitTable[di]	; add in 8 bits (4 ea in cl and ch)

	; make room for four more pixels

	mov	di, cx			; save cx
	mov	cl, 4
	shl	di, cl			; shift cx bits and bx bits
	shl	bx, cl
	mov	cx, di			; restore cx bits
	lodsw
	call	PaletteMap4Pixels	; do the mapping
	jmp	rejoinLoadUp8
LoadUp8Palette	endp

LoadUp8PaletteOdd	proc	near
	clr	cx
	clr	bx

	ShiftInPixel			; shift in pixel 0
	lodsw				; (20) Grab 4 pixels at once.
	call	PaletteMap4Pixels

	; make room for four more pixels

	push	di			; save index
	mov	di, cx			; save cx
	mov	cl, 4
	shl	di, cl			; shift cx bits and bx bits
	shl	bx, cl
	mov	cx, di			; restore cx bits
	
	; add in those four pixels

	rol	ah, 1			; align pixels in each half of the
	rol	ah, 1			;  word in a funny way
	mov	di, ax			; save original bits
	and	ax, 0x33cc		; isolate bits from planes 2 and 3
	or	al, ah			; combine them
	xor	ah, ah			; make them an index
	xchg	di, ax			; restore originals, di -> table
	shl	di, 1			; table entries are words
	or	bx, cs:splitTable[di]	; add in 8 bits (4 ea in bl and bh)
	and	ax, 0xcc33		; isolate other (plane 0/1) bits
	or	al, ah			; combine, as before
	rol	al, 1			; rotate so we can use the same table
	rol	al, 1
	xor	ah, ah			; make it an index
	mov	di, ax			; setup to access table
	shl	di, 1			; table entries are words
	or	cx, cs:splitTable[di]	; add in 8 bits (4 ea in cl and ch)
	pop	di			; restore index

	lodsw				; Grab 4 pixels at once.
	call	PaletteMap4Pixels
	jmp	rejoinLoad8Odd
LoadUp8PaletteOdd	endp

PaletteMap4Pixels	proc	near
	push	es, bx
	les	bx, ss:[bmPalette]	; es:bx -> palette
	xlat	es:[bx]
	xchg	al, ah
	xlat	es:[bx]
	xchg	al, ah
	pop	es, bx
	ret
PaletteMap4Pixels	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadUp8PixelsOdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift in enough data to make a whole 4x1 byte output

CALLED BY:	PutColorScan

PASS:		ds:si	- pointer to next source byte
		al	- preloaded value (carry over from last source byte)

RETURN:		bl,bh,cl,ch - 4 planes of info ready to go
		ds:si	- points at NEXT byte to read

DESTROYED:	al	- has current byte in it

PSEUDO CODE/STRATEGY:
		The basic operation is this.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadUp8PixelsOdd	proc	near
	clr	cx
	clr	bx

	ShiftInPixel			; shift in pixel 0
	lodsw				; (20) Grab 4 pixels at once.

	; make room for four more pixels

	push	di			; save index
	mov	di, cx			; save cx
	mov	cl, 4
	shl	di, cl			; shift cx bits and bx bits
	shl	bx, cl
	mov	cx, di			; restore cx bits
	
	; add in those four pixels

	rol	ah, 1			; align pixels in each half of the
	rol	ah, 1			;  word in a funny way
	mov	di, ax			; save original bits
	and	ax, 0x33cc		; isolate bits from planes 2 and 3
	or	al, ah			; combine them
	xor	ah, ah			; make them an index
	xchg	di, ax			; restore originals, di -> table
	shl	di, 1			; table entries are words
	or	bx, cs:splitTable[di]	; add in 8 bits (4 ea in bl and bh)
	and	ax, 0xcc33		; isolate other (plane 0/1) bits
	or	al, ah			; combine, as before
	rol	al, 1			; rotate so we can use the same table
	rol	al, 1
	xor	ah, ah			; make it an index
	mov	di, ax			; setup to access table
	shl	di, 1			; table entries are words
	or	cx, cs:splitTable[di]	; add in 8 bits (4 ea in cl and ch)
	pop	di			; restore index

	lodsw				; Grab 4 pixels at once.
rejoinLoad8Odd	label	near
	ShiftInPixel			; shift in pixel 5
	ShiftInPixel			; shift in pixel 6
	mov	al, ah			; al <- last data byte
	ShiftInPixel			; shift in pixel 7
		
	mov	cs:lu8poRestoreAL, al	; Save byte to restore below.
	Write8Pixels noControl		; write em out
lu8poRestoreAL	equ	(this byte) + 1
	mov	al, 12h			; MODIFIED
	ret
LoadUp8PixelsOdd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadUpSomePixels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift in enough data to make a whole 4x1 byte output

CALLED BY:	PutColorScan

PASS:		ds:si	- pointer to next source byte
		al	- might contain preloaded value (carry over from last
			  source byte)
		cl	- bit to test to figure out if we should load first
			  or not. Record of type PCSPreloadFlag

RETURN:		bl,bh,cl,ch - 4 planes of info ready to go
		ds:si	- points at NEXT byte to read

DESTROYED:	al	- has current byte in it

PSEUDO CODE/STRATEGY:
		do it FAST

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LoadUpSomePixels proc	near
PCframe		local	PutColorFrame
		.enter	inherit
		test	ss:[bmType], mask BMT_PALETTE	; check for palette
		LONG jnz	doPalette
		test	PCframe.preloadflag, cl	
		jz	loadFirst
		ShiftInPixel		; shift in pixel 0
		jc	shorterJump
loadFirst:
		lodsb			; get next 2 pixels
		ShiftInPixel		; shift in pixel 0
shorterJump:
		jc	done
		ShiftInPixel		; shift in pixel 1
		jc	done
		lodsb			; get next 2 pixels
		ShiftInPixel		; shift in pixel 2
		jc	done
		ShiftInPixel		; shift in pixel 3
		jc	done
		lodsb			; get next 2 pixels
		ShiftInPixel		; shift in pixel 4
		jc	done
		ShiftInPixel		; shift in pixel 5
		jc	done
		lodsb			; get next 2 pixels
		ShiftInPixel		; shift in pixel 6
		jc	done
		ShiftInPixel		; shift in pixel 7
done:
		.leave
		ret

		; do palette version
doPalette:
		push	es, di
		les	di, ss:[bmPalette]	; es:bx -> palette
		test	PCframe.preloadflag, cl	
		jz	loadFirstPal
		ShiftInPixel		; shift in pixel 0
		jc	shorterJumpPal
loadFirstPal:
		lodsb			; get next 2 pixels
		xchg	bx, di
		xlat	es:[bx]
		xchg	bx, di
		ShiftInPixel		; shift in pixel 0
shorterJumpPal:
		LONG jc	donePal
		ShiftInPixel		; shift in pixel 1
		jc	donePal
		lodsb			; get next 2 pixels
		xchg	bx, di
		xlat	es:[bx]
		xchg	bx, di
		ShiftInPixel		; shift in pixel 2
		jc	donePal
		ShiftInPixel		; shift in pixel 3
		jc	donePal
		lodsb			; get next 2 pixels
		xchg	bx, di
		xlat	es:[bx]
		xchg	bx, di
		ShiftInPixel		; shift in pixel 4
		jc	donePal
		ShiftInPixel		; shift in pixel 5
		jc	donePal
		lodsb			; get next 2 pixels
		xchg	bx, di
		xlat	es:[bx]
		xchg	bx, di
		ShiftInPixel		; shift in pixel 6
		jc	donePal
		ShiftInPixel		; shift in pixel 7
donePal:
		pop	es, di
		jmp	done		
LoadUpSomePixels endp


endif

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen
		draws monochrome info as a mask, using current area color

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		ds:si	- pointer to bitmap data
		es	- segment of frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		set drawing color;
		mask left;
		shift and copy left byte;
		shift and copy middle bytes
		mask right;
		shift and copy right byte;
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	01/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FillBWScan	proc	near
		uses	bp
		.enter

		; fetch some previously calculated values

		mov	bx, ss:[bmLeft]		; grab other precalc values
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		mov	dx, bx			; get #bits into image at start
		sub	dx, ss:[d_x1]		; get left coordinate
		mov	cl, 3			; want to get byte indices
		sar	ax, cl
		sar	bx, cl
		sar	dx, cl
		add	si, dx			; add bytes-to-left-side 
		add	di, bx			; add to screen offset too
		mov	dx, ax			; get right side in dx
		sub	dx, bx			; dx = # dest bytes to write
		mov	bp, dx		; save byte count

		; Mono EGA: set fill color.

MEGA <		call	SetMEGAFillColor				>

		; store shift amount as self-modified value 
		; this won't affect the flags register, so compare still valid

		mov	cl, ss:[bmShift]	; load up shift amount
		clr	ch			; assume no initial shift out 
		clr	ah
		mov	dx, GR_CONTROL		; set up i/o port
		tst	ss:[bmPreload]		; check for preloading
		jns	FBS_skipPreload		; if same source or less, skip
		lodsb				; get first byte of bitmap
		ror	ax, cl			; get shift out bits in ah
		mov	ch, ah			; and save them
FBS_skipPreload:
		mov	bx, {word} ss:[bmRMask]	; restore masks in bx
		tst	bp		; test # bytes to draw
		jz	oneByte			;  more than one, don't combine
		mov	cs:[FBS_rMask+2], bl	; store SELF MODIFIED and-imm
		mov	bl, ch			; init shift out bits
		mov	ch, ss:lineMask		; get line mask
		clr	ah			; clear for future rotate
		lodsb				; get next byte of bitmap
		ror	ax, cl			; shift bits
		xchg	bl, ah			; save bits shifted out
		or	ah, al			; get bitmap data for mask
		and	ah, bh			; mask off left side
		and	ah, ch			; use draw mask too
		mov	al, BITMASK		; set up bitmask reg #
		out	dx, ax			; set up mask
		or	byte ptr es:[di], al	; read/write latches
		inc	di			; bump dest pointer
		dec	bp		; if zero, then no center bytes
		jz	FBS_right
		mov	bh, BITMASK		; use extra reg to hold const
FBS_center:
		clr	ah			; clear for rotate
		lodsb				; next data byte
		ror	ax, cl			; rotate into place
		xchg	bl, ah			; save out bits, restore old 
		or	ah, al			; combine old/new bits
		and	ah, ch			; use draw mask too
		mov	al, bh			; setup mask reg #
		out	dx, ax			; write out mask
		or	byte ptr es:[di], al	; read/write latches
		inc	di
		dec	bp		; one less to do
		jg	FBS_center		; loop to do next byte of bitmap
FBS_right:
		mov	ah, ds:[si]		; get last byte
		shr	ah, cl			; shift bits
		or	ah, bl			; get extra bits, if any
FBS_rMask	label	byte
		and	ah, 03h			; SELF MODIFIED and-immediate
		and	ah, ch			; use draw mask too
		mov	al, BITMASK		; setup mask reg #
		out	dx, ax			; write bitmask
		or	byte ptr es:[di], al	; read/write EGA latches

		.leave
		ret
	    
		; one-byte wide data
oneByte:
		mov	ah, bl			;  only one, combine masks
		and	ah, bh
		mov	cs:[FBS_rMask+2], ah	; store SELF MODIFIED and-imm
		mov	bl, ch			; get initial shift out bits
		mov	ch, ss:lineMask		; get line mask
		jmp	short	FBS_right
FillBWScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a b/w scan line of a monochrome bitmap

CALLED BY:	INTERNAL
		PutBitsSimple
PASS:		bitmap drawing vars setup by PutLineSetup
RETURN:		nothing
DESTROYED:	most everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteMonoVGAByte macro	bMask, trashReg
		mov	al, BITMASK
ifb <trashReg>
		push	ax
else
		mov	trashReg, ah
endif
		and	ah, bMask
		out	dx, ax
		mov	al, SETRESET
		mov	ah, {byte} ss:[setColor]
		out	dx, ax
		or	es:[di], al
		mov	al, SETRESET
		mov	ah, {byte} ss:[resetColor]
		out	dx, ax
ifb <trashReg>
		pop	ax
else
		mov	ah, trashReg
		mov	al, BITMASK
endif
		not	ah
		and	ah, bMask
		out	dx, ax
		or	es:[di], al
endm

PutBWScan	proc	near
		uses	bp
		.enter

		; fetch some previously calculated values

		mov	bx, ss:[bmLeft]		; grab other precalc values
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		mov	dx, bx			; get #bits into image at start
		sub	dx, ss:[d_x1]		; get left coordinate
		mov	cl, 3			; want to get byte indices
		sar	ax, cl
		sar	bx, cl
		sar	dx, cl
		add	si, dx			; add bytes-to-left-side 
		add	di, bx			; add to screen offset too
		mov	dx, ax			; get right side in dx
		sub	dx, bx			; dx = # dest bytes to write
		mov	bp, dx		; save byte count

		; Mono EGA: set fill color.

MEGA <		call	SetMEGAFillColor				>

		; we need to check the palette, if we are drawing to a color
		; device, and cheat by setting the setColor and resetColor
		; to the zero and one values

CEGA <		test	ss:[bmType], mask BMT_PALETTE		>
CEGA <		jz	palOK					>
CEGA <		call	DoMonoPalette				>
CEGA <palOK:							>

		; store shift amount as self-modified value 
		; this won't affect the flags register, so compare still valid

		clr	ch			; assume no initial shift out 
		clr	ah
		mov	dx, GR_CONTROL		;  
		mov	cl, ss:[bmShift]	; load shift amount
		tst	ss:[bmPreload]		; see if we need to preload
		jns	PBS_skipPreload		; if same source or less, skip
		lodsb				; get first byte of bitmap
		ror	ax, cl			; get shift out bits in ah
		mov	ch, ah			; and save them
PBS_skipPreload:
		mov	bx, {word} ss:[bmRMask]	; restore masks in bx
		tst	bp		; test # bytes to draw
		LONG jz	oneByte			;  more than one, don't combine
		mov	cs:[PBS_rMask], bl	; store SELF MODIFIED and-imm
		mov	bl, ch			; init shift out bits
		mov	ch, ss:lineMask		; get line mask
		clr	ah			; clear for future rotate
		lodsb				; get next byte of bitmap
		ror	ax, cl			; shift bits
		xchg	bl, ah			; save bits shifted out
		or	ah, al			; get bitmap data for mask
		and	bh, ch			; bh = left AND lineMask
		WriteMonoVGAByte bh
		inc	di			; bump dest pointer
		dec	bp		; if zero, then no center bytes
		jz	PBS_right
PBS_center:
		clr	ah			; clear for rotate
		lodsb				; next data byte
		ror	ax, cl			; rotate into place
		xchg	bl, ah			; save out bits, restore old 
		or	ah, al			; combine old/new bits
		WriteMonoVGAByte ch, bh
		inc	di
		dec	bp		; one less to do
		jg	PBS_center		; loop to do next byte of bitmap
PBS_right:
		mov	ah, ds:[si]		; get last byte
		shr	ah, cl			; shift bits
		or	ah, bl			; get extra bits, if any
PBS_rMask	equ (this byte) + 2
		and	ch, 0x12		; combine right/line masks
		WriteMonoVGAByte ch, bh

		.leave
		ret
	    
		; one-byte wide data
oneByte:
		mov	ah, bl			;  only one, combine masks
		and	ah, bh
		mov	cs:[PBS_rMask], ah	; store SELF MODIFIED and-imm
		mov	bl, ch			; get initial shift out bits
		mov	ch, ss:lineMask		; get line mask
		jmp	PBS_right

PutBWScan	endp

ifndef	IS_MEGA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoMonoPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some setup work for a monochrome bitmap with a palette

CALLED BY:	INTERNAL
		PutBWScan, PutBWScanMask
PASS:		nothing
RETURN:		nothing
DESTROYED:	al

PSEUDO CODE/STRATEGY:
		set the setColor and the resetColor to the right values

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoMonoPalette	proc	near
		uses	ds, si
		.enter

		lds	si, ss:[bmPalette]	; ds:si -> palette
		lodsb				; get resetColor
		mov	{byte} ss:[resetColor], al ; set color for 0 bits
		lodsb
		mov	{byte} ss:[setColor], al   ; set color for 1 bits

		.leave
		ret
DoMonoPalette	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a monochrome bitmap with a store mask

CALLED BY:	see above
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutBWScanMask	proc	near
		uses	bp
		.enter

		; fetch some previously calculated values

		mov	bx, ss:[bmLeft]		; grab other precalc values
		mov	ax, ss:[bmMaskSize]	; get byte size of mask
		inc	ax			; lodsb already done
		neg	ax
		mov	cs:[PBSM_mask1], ax	; self modify code
		mov	cs:[PBSM_mask2], ax
		mov	cs:[PBSM_mask3], ax
		mov	cs:[PBSM_preM], ax
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		mov	dx, bx			; get #bits into image at start
		sub	dx, ss:[d_x1]		; get left coordinate
		mov	cl, 3			; want to get byte indices
		sar	ax, cl
		sar	bx, cl
		sar	dx, cl
		add	si, dx			; add bytes-to-left-side 
		add	di, bx			; add to screen offset too
		mov	dx, ax			; get right side in dx
		sub	dx, bx			; dx = # dest bytes to write
		mov	bp, dx		; save byte count

		; Mono EGA: set fill color.

MEGA <		call	SetMEGAFillColor				>

		; we need to check the palette, if we are drawing to a color
		; device, and cheat by setting the setColor and resetColor
		; to the zero and one values

CEGA <		test	ss:[bmType], mask BMT_PALETTE		>
CEGA <		jz	palOK					>
CEGA <		call	DoMonoPalette				>
CEGA <palOK:							>

		; store shift amount as self-modified value 
		; this won't affect the flags register, so compare still valid

		clr	ch			; assume no initial shift out 
		mov	ah, 0xff
		mov	dx, GR_CONTROL		;  
		mov	cl, ss:[bmShift]	; load up shift amount
		tst	ss:[bmPreload]
		jns	PBSM_skipPreload	; if same source or less, skip
		lodsb				; get first byte of bitmap
		clr	ah
		ror	ax, cl			; get shift out bits in ah
		mov	ch, ah			; and save them
PBSM_preM equ (this word) + 2
		mov	al, ds:[si][1234h]	; preload the mask byte too
		mov	ah, 0xff		; init overflow mask bits
		ror	ax, cl			; ah = init overflow bits

	; at this point, ch=overflow data bits, ah=overflow mask bits
PBSM_skipPreload:
		mov	bx, {word} ss:[bmRMask]	; restore masks in bx
		tst	bp		; test # bytes to draw
		LONG jz	oneByte			;  more than one, don't combine
		mov	cs:[PBSM_rMask], bl	; store SELF MODIFIED and-imm
		mov	bl, ch			; init shift out bits
		mov	ch, ah			; get line mask
		clr	ah			; clear for future rotate
		lodsb				; get next byte of bitmap
		ror	ax, cl			; shift bits
		xchg	bl, ah			; save bits shifted out
		or	ah, al			; get bitmap data for mask
		and	bh, ss:lineMask		; bh = left AND lineMask
		and	bh, ch			; apply overflow mask bits
		xchg	ah, ch			; save current bitmap data
PBSM_mask1 equ (this word) + 2
		mov	al, ds:[si][1234h]	; apply mask stored with bitmap
		mov	ah, 0xff		; init overflow bits
		ror	ax, cl			; rotate mask data
		xchg	ah, ch			; save old, restore data
		and	bh, al			; apply new mask bits too
		WriteMonoVGAByte bh
		inc	di			; bump dest pointer
		dec	bp		; if zero, then no center bytes
		jz	PBSM_right
PBSM_center:
		clr	ah			; clear for rotate
		lodsb				; next data byte
		ror	ax, cl			; rotate into place
		xchg	bl, ah			; save out bits, restore old 
		or	ah, al			; combine old/new bits
		mov	bh, ss:lineMask		; needs to be in bh
		and	bh, ch			; apply overflow mask bits
		xchg	ah, ch			; save current bitmap data
PBSM_mask2	equ (this word) + 2
		mov	al, ds:[si][1234h]	; apply mask stored with bitmap
		mov	ah, 0xff		; init overflow bits
		ror	ax, cl			; rotate mask data
		xchg	ah, ch			; save old, restore data
		and	bh, al			; apply new mask bits too
		WriteMonoVGAByte bh
		inc	di
		dec	bp		; one less to do
		jg	PBSM_center		; loop to do next byte of bitmap
PBSM_right:
		mov	ah, ds:[si]		; get last byte
		inc	si			; bump pointer so mask data
						; ...will be accessed correctly
		shr	ah, cl			; shift bits
		or	ah, bl			; get extra bits, if any
PBSM_rMask	equ (this byte) + 2
		and	ch, 0x12		; combine right/line masks
		and	ch, ss:[lineMask]
		mov	bh, ch			; needs to be in bh
		xchg	ah, ch			; save current bitmap data
PBSM_mask3	equ (this word) + 2
		mov	al, ds:[si][1234h]	; apply mask stored with bitmap
		mov	ah, 0xff		; init overflow bits
		ror	ax, cl			; rotate mask data
		xchg	ah, ch			; save old, restore data
		and	bh, al			; apply new mask bits
		WriteMonoVGAByte bh

		.leave
		ret
	    
		; one-byte wide data
oneByte:
		xchg	ah, bl			;  only one, combine masks
		and	ah, bh
		mov	cs:[PBSM_rMask], ah	; store SELF MODIFIED and-imm
		xchg	bl, ch			; get initial shift out bits
		jmp	PBSM_right

PutBWScanMask	endp

NullBMScan	proc	near
		ret
NullBMScan	endp

ifdef	IS_MEGA


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMEGAFillColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some stuff to do special for MEGA

CALLED BY:	FillBWScan, PutBWScan
PASS:		nothing
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMEGAFillColor proc	near

		mov	dx, GR_CONTROL					
		xchg	ax, cx		; save ax			
		mov	al, ss:[ditherMatrix]				
		clr	ah						
		tst	ss:[inverseDriver]				
		jnz doInverseDriverCase				

		; We're in normal mode.  Set the fill color to white if
		; the patternBuffer is not 0xff.
		cmp	al, 0xff					
		je	doneSettingColor				
setMEGAColor:							
		clr	al						
		out	dx, ax						
doneSettingColor:							
		xchg	ax, cx		; recover ax			
		mov	cl, 3		; want to get byte indices 	
		ret

		; Mono EGA stuff...

		; Inverse driver: if the currentDrawMode is MM_XOR or
		; the patternBuffer is non-zero, set the fill color to
		; black.  If the currentDrawMode not XOR and the
		; patternBuffer is zero, set the fill color to white.

		; At this point, al == the first byte of the patternBuffer,
		; 		 ah == 0
doInverseDriverCase:						
		not	ah			; ah <- 0xff		
		tst	al			; anything in pBuffer?	
		jnz 	setMEGAColor		; jump if so.		

		cmp	ss:[currentDrawMode], MM_XOR			
		je	setMEGAColor		; jump if mode is XOR	

		; Since the mode is not XOR and the patternBuffer is
		; zero, set the fill pattern to white.
		clr	ah			; ah <- 0		
		jmp	setMEGAColor					
SetMEGAFillColor endp

endif

if	(DISPLAY_CMYK_BITMAPS eq TRUE)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutCMYKScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a scan line of a CMYK bitmap

CALLED BY:	INTERNAL
		PutBitsSimple
PASS:		bitmap drawing vars setup by PutLineSetup
RETURN:		nothing
DESTROYED:	most everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutCMYKScan	proc	near
		uses	bp
		.enter

		; fetch some previously calculated values

		mov	bx, ss:[bmLeft]		; grab other precalc values
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		mov	dx, bx			; get #bits into image at start
		sub	dx, ss:[d_x1]		; get left coordinate
		mov	cl, 3			; want to get byte indices
		sar	ax, cl
		sar	bx, cl
		sar	dx, cl
		add	si, dx			; add bytes-to-left-side 
		add	di, bx			; add to screen offset too
		mov	dx, ax			; get right side in dx
		sub	dx, bx			; dx = # dest bytes to write
		mov	ss:[cmykWidth], dx	; store width
		inc	ss:[cmykWidth]		; one more for good measure
		mov	bp, dx			; save byte count

		; we need to check the palette, if we are drawing to a color
		; device, and cheat by setting the setColor and resetColor
		; to the zero and one values

		test	ss:[bmType], mask BMT_PALETTE
		jz	palOK
		call	DoMonoPalette
palOK:
		; do each component.

		call	PutComponentScan
		add	di, ss:[cmykWidth]
		call	PutComponentScan
		add	di, ss:[cmykWidth]
		call	PutComponentScan
		add	di, ss:[cmykWidth]
		call	PutComponentScan
		
		.leave
		ret
PutCMYKScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutComponentScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	8/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PutComponentScan proc	near
		uses	bp, dx, di, ax
		.enter

		; store shift amount as self-modified value 
		; this won't affect the flags register, so compare still valid

		clr	ch			; assume no initial shift out 
		clr	ah
		mov	dx, GR_CONTROL		;  
		mov	cl, ss:[bmShift]	; load shift amount
		tst	ss:[bmPreload]		; see if we need to preload
		jns	PCMY_skipPreload	; if same source or less, skip
		lodsb				; get first byte of bitmap
		ror	ax, cl			; get shift out bits in ah
		mov	ch, ah			; and save them
PCMY_skipPreload:
		mov	bx, {word} ss:[bmRMask]	; restore masks in bx
		tst	bp		; test # bytes to draw
		LONG jz	oneByte			;  more than one, don't combine
		mov	cs:[PCMY_rMask], bl	; store SELF MODIFIED and-imm
		mov	bl, ch			; init shift out bits
		mov	ch, ss:lineMask		; get line mask
		clr	ah			; clear for future rotate
		lodsb				; get next byte of bitmap
		ror	ax, cl			; shift bits
		xchg	bl, ah			; save bits shifted out
		or	ah, al			; get bitmap data for mask
		and	bh, ch			; bh = left AND lineMask
		WriteMonoVGAByte bh
		inc	di			; bump dest pointer
		dec	bp		; if zero, then no center bytes
		jz	PCMY_right
PCMY_center:
		clr	ah			; clear for rotate
		lodsb				; next data byte
		ror	ax, cl			; rotate into place
		xchg	bl, ah			; save out bits, restore old 
		or	ah, al			; combine old/new bits
		WriteMonoVGAByte ch, bh
		inc	di
		dec	bp			; one less to do
		jg	PCMY_center		; loop to do next byte 
PCMY_right:
		mov	ah, ds:[si]		; get last byte
		shr	ah, cl			; shift bits
		or	ah, bl			; get extra bits, if any
PCMY_rMask	equ (this byte) + 2
		and	ch, 0x12		; combine right/line masks
		WriteMonoVGAByte ch, bh
		inc	si			; bump past last input byte

		.leave
		ret
	    
		; one-byte wide data
oneByte:
		mov	ah, bl			;  only one, combine masks
		and	ah, bh
		mov	cs:[PCMY_rMask], ah	; store SELF MODIFIED and-imm
		mov	bl, ch			; get initial shift out bits
		mov	ch, ss:lineMask		; get line mask
		jmp	PCMY_right

PutComponentScan	endp
endif

VideoBitmap	ends


VideoGetBits	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOneScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one scan line of video buffer to system memory

CALLED BY:	INTERNAL
		VidGetBits

PASS:		ds:si	- address of start of scan line in frame buffer
		es:di	- pointer into sys memory where scan line to be stored
		cx	- # bytes left in buffer
		d_x1	- left side of source
		d_dx	- # source pixels
		shiftCount - # bits to shift

RETURN:		es:di	- pointer moved on past scan line info just stored
		cx	- # bytes left in buffer
			- set to -1 if not enough room to fit next scan (no
			  bytes are copied)

DESTROYED:	ax,bx,dx,si

PSEUDO CODE/STRATEGY:
		if (there's enough room to fit scan in buffer)
		   copy the scan out
		else
		   just return

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	GetOneScan
GetOneScan	proc	near
		uses	bp
		.enter

		; first calculate index into scan line

		mov	dx, cx			; use dx for buffer count 
		mov	bx, ss:[d_x1]		; get left side position
		mov	ax, ss:[d_dx]		; ax = pixel width
		add	ax, 7			; round up
		mov	cl, 3			; divide by eight for index
		shr	bx, cl
		add	si, bx			; ds:si -> left side of source
		mov	ax, ss:[d_dx]		; ax = pixel width
		inc	ax			; calc #bytes needed
		shr	ax, 1			; round, then 2pix/byte
		sub	dx, ax			; see if enough room to copy
		mov	cx, -1			; in case we're done
		js	exit			;  yes, quit with error
		push	dx			; save remaining count
		mov	bp, ss:[d_dx]		; get pix count for loop count

		; read in the first bytes and align them

		call	ReadOneByte		; read in the bytes
		mov	ax, cx			; free up cl
		mov	dh, 8			; get pixel count too
		mov	cl, ss:[shiftCount]	; get shift amout
		sub	dh, cl
		shl	ax, cl			; shift all data up
		shl	bx, cl
		mov	cx, ax			; set up right register

		; the big loop.  we create one dest byte each time round
pixLoop:
		clr	dl			; signal in first part of loop
pixelLoopNoClear:
		shl	bh, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg
		shl	bl, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg
		shl	ch, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg
		shl	cl, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg

		; see if we've hit the end of the line or our data.
		
		dec	bp
		jz	doneLoop

		dec	dh
		jz	readByte		; z => out of bits
midPixelLoop:

		inc	dx			; note have one pixel (can't
						;  carry into dh, so use single-
						;  byte instruction)

		shl	bh, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg
		shl	bl, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg
		shl	ch, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg
		shl	cl, 1			; shift bit into carry
		rcl	al, 1			; shift bit into result reg

		stosb				; write the byte

		; see if we've hit the end of the line or our data

		dec	bp			; one fewer pixel
		jz	doneLoop

		dec	dh
		jnz	pixLoop			; z => out of bits

		; read the next byte
readByte:
		shr	dl, 1			; set the carry if finished loop
		call	ReadOneByte		; doesn't affect carry
		mov	dx, 800h		; init bit count and pixel-
						;  stored flag
		jnc	midPixelLoop		; if dl was 0 on entry, we need
						;  to jump back to the middle of
						;  the loop to get the second
						;  pixel.
		jmp	pixelLoopNoClear	; else go back to the end of the
						;  second half of the loop.

doneLoop:
		;
		; We've read all the pixels but there may be one lingering in
		; al. If dl is zero it means we got out before the second half,
		; so the pixel is still there. Shift it up to its rightful place
		; in the top nibble of al and store the whole byte.
		;
		tst	dl
		jnz	done
		shl	al
		shl	al
		shl	al
		shl	al
		stosb
done:
		; restore count and return.
		pop	cx
exit:
		.leave
		ret

		
GetOneScan	endp

;--------	utility routine used by GetOneScan.  Reads entire byte into
;		four registers (bh,bl,ch,cl). assumes ds:si -> screen buffer
;		trashes ax,dx. bumps si.  Code calling this assumes that 
;		the carry flag is unaffected.  SO DON'T hooey WITH IT.  thanks.
ReadOneByte	proc	near			; reads 4 bit planes into regs
		mov	ah, al			; preserve possible pixel
		mov	al, READ_MAP_0
		mov	dx, GR_CONTROL		; set up i/o address
		out	dx, al			; point controller at map reg
		inc	dx			; point at controller data reg
		mov	al, 3			; start with plane 3
		out	dx, al
		mov	bh, ds:[si]		; get plane 3 data
		dec	ax			; to next plane (one-byte inst)
		out	dx, al
		mov	bl, ds:[si]		; get plane 2 data
		dec	ax			; to next plane (one-byte inst)
		out	dx, al
		mov	ch, ds:[si]		; get plane 1 data
		dec	ax			; to next plane (one-byte inst)
		out	dx, al
		lodsb				; get plane 0 data & advance
		mov	cl, al			;  to next byte
		mov	al, ah			; recover possible pixel
		ret
ReadOneByte	endp

VideoGetBits	ends


VideoBitmap	segment	resource

ifndef IS_MEGA


	; splitTable.
	; this table converts:
	;    fedcba9876543210
	; into:
	;    ....ea62....fb73
	; The table is accessed twice for each word of the bitmap that is
	; loaded.

	even			; make sure we start on a word boundary
splitTable	label	word
	word	0x0000	; 0
	word	0x0200	; 
	word	0x0002	; 
	word	0x0202	; 
	word	0x0400	;
	word	0x0600	; 
	word	0x0402	; 
	word	0x0602	; 
	word	0x0004	;
	word	0x0204	; 
	word	0x0006	; 
	word	0x0206	; 
	word	0x0404	;
	word	0x0604	; 
	word	0x0406	; 
	word	0x0606	; 
	word	0x0100	; 20
	word	0x0300	; 
	word	0x0102	; 
	word	0x0302	; 
	word	0x0500	;
	word	0x0700	; 
	word	0x0502	; 
	word	0x0702	; 
	word	0x0104	;
	word	0x0304	; 
	word	0x0106	; 
	word	0x0306	; 
	word	0x0504	;
	word	0x0704	; 
	word	0x0506	; 
	word	0x0706	; 
	word	0x0001	; 30
	word	0x0201	; 
	word	0x0003	; 
	word	0x0203	; 
	word	0x0401	;
	word	0x0601	; 
	word	0x0403	; 
	word	0x0603	; 
	word	0x0005	;
	word	0x0205	; 
	word	0x0007	; 
	word	0x0207	; 
	word	0x0405	;
	word	0x0605	; 
	word	0x0407	; 
	word	0x0607	; 
	word	0x0101	; 40
	word	0x0301	; 
	word	0x0103	; 
	word	0x0303	; 
	word	0x0501	;
	word	0x0701	; 
	word	0x0503	; 
	word	0x0703	; 
	word	0x0105	;
	word	0x0305	; 
	word	0x0107	; 
	word	0x0307	; 
	word	0x0505	;
	word	0x0705	; 
	word	0x0507	; 
	word	0x0707	; 
	word	0x0800	; 50
	word	0x0a00	; 
	word	0x0802	; 
	word	0x0a02	; 
	word	0x0c00	;
	word	0x0e00	; 
	word	0x0c02	; 
	word	0x0e02	; 
	word	0x0804	;
	word	0x0a04	; 
	word	0x0806	; 
	word	0x0a06	; 
	word	0x0c04	;
	word	0x0e04	; 
	word	0x0c06	; 
	word	0x0e06	; 
	word	0x0900	; 60
	word	0x0b00	; 
	word	0x0902	; 
	word	0x0b02	; 
	word	0x0d00	;
	word	0x0f00	; 
	word	0x0d02	; 
	word	0x0f02	; 
	word	0x0904	;
	word	0x0b04	; 
	word	0x0906	; 
	word	0x0b06	; 
	word	0x0d04	;
	word	0x0f04	; 
	word	0x0d06	; 
	word	0x0f06	; 
	word	0x0801	; 70
	word	0x0a01	; 
	word	0x0803	; 
	word	0x0a03	; 
	word	0x0c01	;
	word	0x0e01	; 
	word	0x0c03	; 
	word	0x0e03	; 
	word	0x0805	;
	word	0x0a05	; 
	word	0x0807	; 
	word	0x0a07	; 
	word	0x0c05	;
	word	0x0e05	; 
	word	0x0c07	; 
	word	0x0e07	; 
	word	0x0901	; 80
	word	0x0b01	; 
	word	0x0903	; 
	word	0x0b03	; 
	word	0x0d01	;
	word	0x0f01	; 
	word	0x0d03	; 
	word	0x0f03	; 
	word	0x0905	;
	word	0x0b05	; 
	word	0x0907	; 
	word	0x0b07	; 
	word	0x0d05	;
	word	0x0f05	; 
	word	0x0d07	; 
	word	0x0f07	; 
	word	0x0008	; 0
	word	0x0208	; 
	word	0x000a	; 
	word	0x020a	; 
	word	0x0408	;
	word	0x0608	; 
	word	0x040a	; 
	word	0x060a	; 
	word	0x000c	;
	word	0x020c	; 
	word	0x000e	; 
	word	0x020e	; 
	word	0x040c	;
	word	0x060c	; 
	word	0x040e	; 
	word	0x060e	; 
	word	0x0108	; 20
	word	0x0308	; 
	word	0x010a	; 
	word	0x030a	; 
	word	0x0508	;
	word	0x0708	; 
	word	0x050a	; 
	word	0x070a	; 
	word	0x010c	;
	word	0x030c	; 
	word	0x010e	; 
	word	0x030e	; 
	word	0x050c	;
	word	0x070c	; 
	word	0x050e	; 
	word	0x070e	; 
	word	0x0009	; 30
	word	0x0209	; 
	word	0x000b	; 
	word	0x020b	; 
	word	0x0409	;
	word	0x0609	; 
	word	0x040b	; 
	word	0x060b	; 
	word	0x000d	;
	word	0x020d	; 
	word	0x000f	; 
	word	0x020f	; 
	word	0x040d	;
	word	0x060d	; 
	word	0x040f	; 
	word	0x060f	; 
	word	0x0109	; 40
	word	0x0309	; 
	word	0x010b	; 
	word	0x030b	; 
	word	0x0509	;
	word	0x0709	; 
	word	0x050b	; 
	word	0x070b	; 
	word	0x010d	;
	word	0x030d	; 
	word	0x010f	; 
	word	0x030f	; 
	word	0x050d	;
	word	0x070d	; 
	word	0x050f	; 
	word	0x070f	; 
	word	0x0808	; 50
	word	0x0a08	; 
	word	0x080a	; 
	word	0x0a0a	; 
	word	0x0c08	;
	word	0x0e08	; 
	word	0x0c0a	; 
	word	0x0e0a	; 
	word	0x080c	;
	word	0x0a0c	; 
	word	0x080e	; 
	word	0x0a0e	; 
	word	0x0c0c	;
	word	0x0e0c	; 
	word	0x0c0e	; 
	word	0x0e0e	; 
	word	0x0908	; 60
	word	0x0b08	; 
	word	0x090a	; 
	word	0x0b0a	; 
	word	0x0d08	;
	word	0x0f08	; 
	word	0x0d0a	; 
	word	0x0f0a	; 
	word	0x090c	;
	word	0x0b0c	; 
	word	0x090e	; 
	word	0x0b0e	; 
	word	0x0d0c	;
	word	0x0f0c	; 
	word	0x0d0e	; 
	word	0x0f0e	; 
	word	0x0809	; 70
	word	0x0a09	; 
	word	0x080b	; 
	word	0x0a0b	; 
	word	0x0c09	;
	word	0x0e09	; 
	word	0x0c0b	; 
	word	0x0e0b	; 
	word	0x080d	;
	word	0x0a0d	; 
	word	0x080f	; 
	word	0x0a0f	; 
	word	0x0c0d	;
	word	0x0e0d	; 
	word	0x0c0f	; 
	word	0x0e0f	; 
	word	0x0909	; 80
	word	0x0b09	; 
	word	0x090b	; 
	word	0x0b0b	; 
	word	0x0d09	;
	word	0x0f09	; 
	word	0x0d0b	; 
	word	0x0f0b	; 
	word	0x090d	;
	word	0x0b0d	; 
	word	0x090f	; 
	word	0x0b0f	; 
	word	0x0d0d	;
	word	0x0f0d	; 
	word	0x0d0f	; 
	word	0x0f0f	; 
endif

VideoBitmap	ends
