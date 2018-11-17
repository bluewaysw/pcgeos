COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem
FILE:		clr4Raster.asm

AUTHOR:		Jim DeFrisco, Jun  4, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	6/ 4/92		Initial revision


DESCRIPTION:
	Low-level raster drawing routines for 4-bit/pixel vidmem
		

	$Id: clr4Raster.asm,v 1.1 97/04/18 11:42:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Blt

COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltSimpleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	blt a single scan line (vertically)

CALLED BY:	INTERNAL

PASS:		bx	- first x point in simple region
		ax	- last x point in simple region
		d_x1	- left side of blt
		d_x2	- right side of blt
		es:si	- points to scan line start of source
			- (except for VidMem, where the source and dest segs
			   may not be the same)
		es:di	- points to scan line start of dest


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		mask left;
		copy left byte;
		mask = ff;
		copy middle bytes
		mask right;
		copy right byte;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

BltSimpleLine	proc		near
		push	ds			; save window seg
		mov	ds, ss:[bm_lastSegSrc]	; get source segment	

		mov	bx, ss:[bmLeft]		; save these for later
		mov	ax, ss:[bmRight]	

		; calculate masks, and save shift amount, other good things

		mov	dx, ax		 	; recalc # bytes
		shr	dx, 1
		mov	cx, dx
		mov	dx, bx			; calc #bytes to draw
		shr	dx, 1
		sub	cx, dx			; cx = # bytes to write
		mov	dx, bx			; get dest left side
		mov	ah, dl			; save the low byte for later
		sub	dx, ss:[d_x1]		; dx = index into blt dest
		add	dx, ss:[d_x1src]	; dx = left side of source
		mov	al, dl			; calculate shift value
		and	ax, 0101h		; if no shift, result == 
		sub	ah, al			; ah = #bits shift right 
		push	ax			; save #shifts

		; calculate byte indices into scan line, both source and dest

		mov	ax, ss:[bmRight] 	; get right side coord
		mov	dx, bx			; left side coord saved in bx
		shr	ax, 1			; calc byte index
		shr	dx, 1			;   for both
		add	di, dx			; byte index for destination
		sub	bx, ss:[d_x1]		; bx = #pix index into dest blt
		add	bx, ss:[d_x1src] 	; bx = source left side
		shr	bx, 1			; bx = source left byte index
		add	si, bx
		mov	dx, {word} ss:[bmRMask]	; restore masks
		pop	bx			; bh = #bits to shift right

		; check to see if we need to shift anything, use diff routine

		tst	bh			; check shift amount
		je	BSL_bytemove
		jmp	BltShift		;  shift, use slower routine

BSL_bytemove:
		tst	cx
		jne	BSL_doleft
		and	dl, dh			; combine masks
		jmp	BSL_doright

		; check to see if we are copying right to left
BSL_doleft:
		mov	ax, ss:[d_x1]		; get dest left side coord
		cmp	ax, ss:[d_x1src]	; compare to source left side
		jg	BSL_RightToLeft		; do it backwards 

		; mask left word 

		lodsb
		and	al, dh			; apply mask
		mov	ah, es:[di]		; get destination
		not	dh
		and	ah, dh
		or	al, ah
		stosb
		dec	cx			; see if done
		je	BSL_doright

		; copy middle bytes

		rep	movsb

		; handle right word specially
BSL_doright:
		lodsb
		and	al, dl			; apply right mask
		mov	ah, es:[di]		; get destination
		not	dl
		and	ah, dl			; apply reverse mask
		or	al, ah
		stosb

BSL_last:
		pop	ds			; restore ds
		ret


		; special case: copy line right to left
BSL_RightToLeft:
		; shift pointers to start at right side
		add	si, cx				; add to source and dest
		add	di, cx
		std					; go backwards

		; mask right byte 

		lodsb
		and	al, dl				; do right side
		mov	ah, es:[di]			; get destination
		not	dl				; reverse mask
		and	ah, dl				; save bits from dest
		or	al, ah
		stosb
		dec	cx
		je	BSL_rldoleft

		; draw middle words

		rep	movsb

		; mask left byte 
BSL_rldoleft:
		lodsb
		and	al, dh				; apply left mask
		mov	ah, es:[di]			; get destination
		not	dh
		and	ah, dh				; apply reverse mask
		or	al, ah
		stosb
		cld			
		jmp	short BSL_last

BltSimpleLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltShift
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a single scan line that needs to be shifted

CALLED BY:	INTERNAL
		BltSimpleLine

PASS:		ds:si	- ptr to start of src pixels to move (may need adjust)
		es:di	- ptr to start of dst pixels to move 
		dx	- masks (dh=left, dl=right)
		cx	- byte count
		bh	- shift count

RETURN:		nothing
		jumped to by BltShift, so this returns to BltSimpleLine's caller

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		read/shift/write the bytes;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BltShift	proc		near

		; calculate preload flag.  The calculation goes like this:
		; let dr=dest right, dl=dest left, sr=src right, sl=src left
		; let diff1= ((dl^1)-(sl^1)), diff2=((dr^1)-(sr^1))
		; then flag = (diff1 XOR diff2) AND diff1
		; if flag < 0, then preload

		push	dx		; save masks
		mov	ah, byte ptr ss:[bmLeft] ; ah = dest left
		and	ah, 1		; ah = dl^1
		mov	dx, ss:[bmLeft] ; calc index into source scan
		sub	dx, ss:[d_x1]	; cx = index
		add	dx, ss:[d_x1src] ; cx = source left
		and	dl, 1		; isolate low bit
		sub	ah, dl		; ah = ((dl^1)-(sl^1))
		mov	al, byte ptr ss:[bmRight] ; al = dest right
		and	al, 1		; al = dr^1
		mov	dx, ss:[bmRight] ; calc index into source scan
		sub	dx, ss:[d_x1]	; cx = index
		add	dx, ss:[d_x1src] ; cx = source right
		and	dl, 1		; isolate low three bits
		sub	al, dl		; al = ((dr^1)-(sr^1))
		xor	al, ah		; al=(diff1 XOR diff2)
		and	ah, al		; ah=(diff1 XOR diff2) AND diff1
		mov	bl, ah		; save test result
					;  bl = preload test flag, bh=shift#
		pop	dx		; restore masks, dh=left, dl=right

		; if source and dest on same scan line, use different rout

		mov	ax, ss:[d_y1]	; get one y value
		cmp	ax, ss:[d_y2]	; check against other

		jne	BS_normal	; normal case
		mov	ax, ss:[d_x1src]; use slow routine if copying to right
		cmp	ax, ss:[d_x1]
		jge	BS_normal
		jmp	BltShiftHoriz	; blting horizontally

		;   read/shift/write the bits to buffer
BS_normal:
		tst	bh		; if shift left, do separate
		mov	bh, 4		; shift is always by a nibble
		js	BS_shiftLeft	; do left shifting

		; check for need to preload first value (more src than dest)

		tst	bl 		; if high bit not set
		mov	bl, 0		; assume not set
		jns	BS_start	;  then skip preload
		clr	ah		; clear initial shift bits
		lodsb			; get first source byte
		xchg	cl, bh		; load shift amount in cl
		ror	ax, cl		; do shift
		xchg	cl, bh		; restore regs
		mov	bl, ah		; new initial shift-out bits

		; test for single byte write, need to combine masks
BS_start:
		tst	cx		; check # bytes to write
		jne	BS_srLeft	; writing more than one
		and	dl, dh		; combine masks
		jmp	BS_srRight	; do right side

		; shifting right, do left side byte (and mask it)
BS_srLeft:	
		clr	ah		; slear out initial shift-in bits
		lodsb			; get next source byte
		xchg	bh, cl
		ror	ax, cl		; do the shift
		xchg	bh, cl
		xchg	bl, ah		; get old shift-in bits
		or	al, ah		; al=new bits to write
		and	al, dh		; apply left mask
		mov	ah, es:[di]	; get destination byte
		not	dh		; create negative image mask
		and	ah, dh		; apply mask to existing bits
		or	al, ah		; combine parts
		stosb			; write out the byte
		dec	cx		; one less byte to write
		jz	BS_srRight	; if no middle bytes, do right side

		; do the middle bytes

BS_smallLoop:
		clr	ah		; clear out initial shift-in
		lodsb			; get next source byte
		xchg	bh, cl
		ror	ax, cl		; do the shift
		xchg	bh, bl
		xchg	bl, ah		; get old shift-in byte
		or	al, ah		; combine bits
		stosb			; save in temp buffer
		dec	cx		; keep going till middle done
		jnz	BS_smallLoop

		; do the right side
BS_srRight:
		clr	ah		; slear out initial shift-in bits
		lodsb			; get next source byte
		xchg	cl, bh
		ror	ax, cl		; do the shift
		xchg	cl, bh
		xchg	bl, ah		; get old shift-in bits
		or	al, ah		; al=new bits to write
		and	al, dl		; apply right mask
		mov	ah, es:[di]	; get destination byte
		not	dl		; create negative image mask
		and	ah, dl		; apply mask to existing bits
		or	al, ah		; combine parts
		stosb			; write out the byte
			
		; all done, cleanup and exit
BS_done:
		pop	ds		; restore data seg
		ret			; returns to BltSimpleLine's caller

;---------------------------------------------------------------------

		; special case: need to shift left
		; check for need to preload the first value (more src than dest)
BS_shiftLeft:
		push	bx		; save preload flag
		clr	ah
		lodsb			; get first source byte
		xchg	bh, cl
		rol	ax, cl		; do shift
		xchg	bh, cl
		mov	bl, al		; initial shift-out bits

		; test for single byte write, need to combine masks

		tst	cx		; check # bytes to write
		jne	BS_slLeft	; writing more than one
		and	dl, dh		; combine masks
		jmp	BS_slRight	; do right side

		; shifting left, do left side byte (and mask it)
BS_slLeft:	
		clr	ah		; slear out initial shift-in bits
		lodsb			; get next source byte
		xchg	bh, cl
		rol	ax, cl		; do the shift
		xchg	bh, cl
		xchg	bl, al		; get old shift-in bits
		or	al, ah		; al=new bits to write
		and	al, dh		; apply left mask
		mov	ah, es:[di]	; get destination byte
		not	dh		; create negative image mask
		and	ah, dh		; apply mask to existing bits
		or	al, ah		; combine parts
		stosb			; write out the byte
		dec	cx		; one less byte to write
		jz	BS_slRight	; if no middle bytes, do right side

		; do the middle bytes

BSL_smallLoop:
		clr	ah		; clear out initial shift-in
		lodsb			; get next source byte
		xchg	bh, cl
		rol	ax, cl		; do the shift
		xchg	bh, cl
		xchg	bl, al		; get old shift-in byte
		or	al, ah		; combine bits
		stosb			; save in temp buffer
		dec	cx		; keep going till middle done
		jnz	BSL_smallLoop

		; do the right side
BS_slRight:
		pop	cx		; restore postload flag in spent reg
		mov	al, bl		; assume no postload
		tst	cl		; check postload
		jns	BSL_finish	;  no postload
		clr	ah		; slear out initial shift-in bits
		lodsb			; get next source byte
		xchg	bh, cl
		rol	ax, cl		; do the shift
		xchg	bh, cl
		xchg	bl, al		; get old shift-in bits
BSL_finish:
		or	al, ah		; al=new bits to write
		and	al, dl		; apply right mask
		mov	ah, es:[di]	; get destination byte
		not	dl		; create negative image mask
		and	ah, dl		; apply mask to existing bits
		or	al, ah		; combine parts
		stosb			; write out the byte
		jmp	BS_done		; continue with copy to screen

BltShift	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltShiftHoriz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Blt part of a scan line horizontally to the right, with 
		need to shift

CALLED BY:	INTERNAL
		BltShift

PASS:		lots, see BltShift header, above

RETURN:		nothing
		returns to BltSimpleLine's caller

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		copy line to intermediate buffer
		copy buffer to new location

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		this is the easy way out.  It's a little slower, but results 
		in a lot less code.  We'll see, may change if performance is
		not good enough.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BltShiftHoriz	proc		near

		; allocate a temp buffer on the stack 
		push	es			; save extra seg
		push	bp			; save frame pointer
		mov	bp, sp
		mov	ax, cx			; move # bytes to ax
		add	ax, 2			; a little extra
		and	al, 0feh		; make sure it's even
		sub	sp, ax			; allocate some 
		mov	ax, sp			; save poitner to buffer
		push	di			; save frame dest
		mov	di, ax			; di -> temp buffer
		segmov	es, ss			; es:di -> temp buffer
		push	cx			; save byte count
		tst	bh			; if shift left, branch
		mov	bh, 4			; we always shift 4 here
		js	BSH_left		;  yes, shift left

		; shifting right, check for preload

		tst	bl			; see if high bit set
		mov	bl, 0			; assuume no preload
		jns	BSH_smallLoop		;  no, skip preload
		clr	ah
		lodsb				; get first source byte
		xchg	bh, cl
		ror	ax, cl			; do the shift
		xchg	bh, cl
		mov	bl, ah			; save shift out bits
BSH_smallLoop:
		clr	ah
		lodsb				; get next source byte
		xchg	bh, cl
		ror	ax, cl
		xchg	bh, cl
		xchg	bl, ah			; get/save shift out bits
		or	al, ah			; combine this/prev
		stosb				; save in temp buffer
		dec	cx
		jns	BSH_smallLoop		; do all the bytes

		; done with copy, now copy to screen
BSH_write:
		pop	cx			; restore count
		pop	di			; restore dest ptr
		segmov	es, ds			; set up es:di -> screen
		segmov	ds, ss			; ds -> temp block
		mov	si, sp			; ds:si -> temp buffer
		tst	cx			; see if only 1 byte to write
		jne	BSH_wleft		;  nope, do left
		and	dl, dh			; combine the masks
		jmp	short BSH_wRight	; and just do the right side
BSH_wleft:
		lodsb				; get left byte
		and	al, dh			; mask left
		mov	ah, es:[di]		; get dest byte
		not	dh			; reverse mask
		and	ah, dh			; mask existing bits
		or	al, ah			; combine for left byte
		stosb				; write to screen
		dec	cx			; one less to go
		jz	BSH_wRight		;  if done, do right side
		rep	movsb
BSH_wRight:
		lodsb				; get left byte
		and	al, dl			; mask left
		mov	ah, es:[di]		; get dest byte
		not	dl			; reverse mask
		and	ah, dl			; mask existing bits
		or	al, ah			; combine for left byte
		stosb				; write to screen
		mov	sp, bp			; restore stack pointer
		pop	bp			; restore frame pointer
		pop	es			; restore extra seg
		pop	ds			; pushed by BltSimpleLine
		ret				; ret to BltSimpleLine's caller

		; special case: shifting left
BSH_left:
		push	bx			; save postload flag
		clr	ah
		lodsb				; get first source byte
		xchg	bh, cl
		rol	ax, cl			; do the shift
		xchg	bh, cl
		mov	bl, al			; save shift out bits
BSHL_smallLoop:
		clr	ah
		lodsb				; get next source byte
		xchg	bh, cl
		rol	ax, cl
		xchg	bh, cl
		xchg	bl, al			; get/save shift out bits
		or	al, ah			; combine this/prev
		stosb				; save in temp buffer
		dec	cx
		js	BSH_write
		jne	BSHL_smallLoop		; do all the bytes
		pop	cx
		tst	bl			; see if high bit set
		mov	cx, 0
		js	BSHL_smallLoop		;  yes, load one more
		mov	al, bl			;  no, just use last read
		stosb
		jmp	BSH_write		; all done, write out to screen
		
BltShiftHoriz	endp

VidEnds		Blt


VidSegment	Bitmap


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillBWScan
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
		dx	- index into pattern table
		ds:si	- pointer to bitmap data
		es:di	- pointer into frame buffer to start of scan line

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

NullBMScan	proc	near
		ret
NullBMScan	endp

FillBWScan	proc	near
		uses	bp
		.enter
	mov	bx, ss:[bmLeft]
	mov	ax, ss:[bmRight]

	; calculate # bytes to fill in

	mov	bp, bx			; get # bits into image at start
	sub	bp, ss:[d_x1]		; get left coordinate
	mov	cl, 3			; want to get byte indices
	sar	ax, cl
	sar	bx, 1
	sar	bp, cl
	add	si, bp			; add bytes-to-left-side to indices
	and 	bx, 0xfffc			; clear low 2
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sar	bx, 1
	sar	bx, 1
	sub	bp, bx			; bp = # dest bytes to write
	mov	dx, ss:ditherScan	;  dx = line's dither pattern

	; init shift-out bits if more source bytes than destination bytes

	clr	ch			; assume no initial shift out bits
	clr	ah
	mov	cl, ss:[bmShift]	; load shift amount
	tst	ss:[bmPreload]		; see if pre-boarding
	jns	FBS_skipPreload		; if same source or less, skip preload
	lodsb				; get first byte of bitmap
	ror	ax, cl			; get shift out bits in ah
	mov	ch, ah			; and save them

FBS_skipPreload:
	mov	bx, {word} ss:[bmRMask]	; get mask bytes
	or	bp, bp			; test # bytes to draw
	jnz	FBS_left		;  more than one, don't combine masks
	mov	ah, bl			;  only one, combine masks
	and	ah, bh
	mov	cs:[FBS_rMask], ah	; store SELF MODIFIED and-immediate
	mov	bl, ch			; get initial shift out bits
	jmp	short	FBS_right
FBS_left:
	mov	cs:[FBS_rMask], bl	; store SELF MODIFIED and-immediates
	mov	bl, ch			; init shift out bits
	clr	ah			; clear for future rotate
	lodsb				; get next byte of bitmap
	ror	ax, cl			; shift bits
	xchg	bl, ah			; save bits shifted out
	or	al, ah			; get bitmap data for mask
	and	al, ss:lineMask
	call	WriteBitmapByte		; write out the byte
	dec	bp			; if zero, then no center bytes
	jz	FBS_right
	mov	bh, 0xff		; mask for middle

FBS_center:
	clr	ah			; clear for rotate
	lodsb				; next data byte
	ror	ax, cl			; rotate into place
	xchg	bl, ah			; save out bits, restore old out bits
	or	al, ah			; combine old/new bits
	and	al, ss:lineMask
	call	WriteBitmapByte
	dec	bp			; one less to do
	jg	FBS_center		; loop to do next byte of bitmap

FBS_right:
	mov	al, ds:[si]		; get last byte
	shr	al, cl			; shift bits
	or	al, bl			; get extra bits, if any
	and	al, ss:lineMask
FBS_rMask equ (this byte) + 1
	mov	bh, 03h			; SELF MODIFIED and-immediate
	call	WriteBitmapByte

	.leave
	ret
FillBWScan	endp

WriteBitmapByte	proc	near
	call	BuildDataByteFar	; expand byte into buffer
	test	bh, 0xc0		; if mask zeroes, skip write	
	jz	byte2
	mov	ah, {byte} ss:[dataBuff4]
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
byte2:
	inc	di
	xchg	dl, dh
	test	bh, 0x30		; check out next two
	jz	byte3
	mov	ah, {byte} ss:[dataBuff4+1]
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
byte3:
	inc	di
	xchg	dl, dh
	test	bh, 0x0c		; next byte
	jz	byte4
	mov	ah, {byte} ss:[dataBuff4+2]
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
byte4:
	inc	di
	xchg	dl, dh
	test	bh, 0x03
	jz	done	
	mov	ah, {byte} ss:[dataBuff4+3]
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
done:
	inc	di
	ret

WriteBitmapByte	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Monochrome bitmap drawline

CALLED BY:	PutBitsSimple
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		dx	- index into pattern table
		ds:si	- pointer to bitmap data
		es:di	- pointer into frame buffer to start of scan line

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
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutBWScan	proc	near
		uses	bp
		.enter
	mov	bx, ss:[bmLeft]
	mov	ax, ss:[bmRight]

	; calculate # bytes to fill in

	mov	bp, bx			; get # bits into image at start
	sub	bp, ss:[d_x1]		; get left coordinate
	mov	cl, 3			; want to get byte indices
	sar	ax, cl
	sar	bx, 1
	sar	bp, cl
	add	si, bp			; add bytes-to-left-side to indices
	and 	bx, 0xfffc			; clear low 2
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sar	bx, 1
	sar	bx, 1
	sub	bp, bx			; bp = # dest bytes to write
	clr	dx			; set the pixels to black (0)

	; init shift-out bits if more source bytes than destination bytes

	clr	ch			; assume no initial shift out bits
	clr	ah
	mov	cl, ss:[bmShift]	; load shift amount
	tst	ss:[bmPreload]		; check for pre-boarding
	jns	PBS_skipPreload		; if same source or less, skip preload
	lodsb				; get first byte of bitmap
	ror	ax, cl			; get shift out bits in ah
	mov	ch, ah			; and save them

PBS_skipPreload:
	mov	bx, {word} ss:[bmRMask]	; get mask bytes
	or	bp, bp			; test # bytes to draw
	jnz	PBS_left		;  more than one, don't combine masks
	mov	ah, bl			;  only one, combine masks
	and	ah, bh
	mov	cs:[PBS_rMask], ah	; store SELF MODIFIED and-immediate
	mov	bl, ch			; get initial shift out bits
	jmp	short	PBS_right
PBS_left:
	and	bl, ss:lineMask		; apply draw mask to right side mask
	mov	cs:[PBS_rMask], bl	; store SELF MODIFIED and-immediates
	mov	bl, ch			; init shift out bits
	clr	ah			; clear for future rotate
	lodsb				; get next byte of bitmap
	ror	ax, cl			; shift bits
	xchg	bl, ah			; save bits shifted out
	or	al, ah			; get bitmap data for mask
	and	al, ss:lineMask		; combine left/line masks
	call	WriteBitmapByte
	dec	bp			; if zero, then no center bytes
	jz	PBS_right
	mov	bh, 0xff

PBS_center:
	clr	ah			; clear for rotate
	lodsb				; next data byte
	ror	ax, cl			; rotate into place
	xchg	bl, ah			; save out bits, restore old out bits
	or	al, ah			; combine old/new bits
	and	al, ss:lineMask		; apply user-spec draw mask
	call	WriteBitmapByte
	dec	bp			; one less to do
	jg	PBS_center		; loop to do next byte of bitmap

PBS_right:
	mov	al, ds:[si]		; get last byte
	shr	al, cl			; shift bits
	or	al, bl			; get extra bits, if any
PBS_rMask equ (this byte) + 1
	mov	bh, 03h			; SELF MODIFIED and-immediate
	and	al, ss:lineMask		; apply user-spec draw mask
	call	WriteBitmapByte

	.leave
	ret
PutBWScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Monochrome bitmap drawline

CALLED BY:	PutBitsSimple
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		dx	- index into pattern table
		ds:si	- pointer to bitmap data
		es:di	- pointer into frame buffer to start of scan line

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
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutBWScanMask	proc	near
		uses	bp
		.enter
	mov	bx, ss:[bmLeft]
	mov	ax, ss:[bmMaskSize]	; get mask size, store it in code
	inc	ax			; one more, already did lodsb
	neg	ax			; mask is stored first
	mov	cs:[PBSM_mask1], ax	; store offset to mask
	mov	cs:[PBSM_mask2], ax	; store offset to mask
	mov	cs:[PBSM_mask3], ax	; store offset to mask
	mov	cs:[PBSM_preM], ax	; preload mask as well
	mov	ax, ss:[bmRight]

	; calculate # bytes to fill in

	mov	bp, bx			; get # bits into image at start
	sub	bp, ss:[d_x1]		; get left coordinate
	mov	cl, 3			; want to get byte indices
	sar	ax, cl
	sar	bx, 1
	sar	bp, cl
	add	si, bp			; add bytes-to-left-side to indices
	and 	bx, 0xfffc			; clear low 2
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sar	bx, 1
	sar	bx, 1
	sub	bp, bx			; bp = # dest bytes to write
	clr	dx			; set the pixels to black (0)

	; ready to go.  load up shift amount, check for pre-boarding passengers

	clr	ch			; assume no initial shift out bits
	mov	ah, 0xff
	mov	cl, ss:[bmShift]	; load shift amount
	tst	ss:[bmPreload]
	jns	PBSM_skipPreload	; if same source or less, skip preload
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
	mov	bx, {word} ss:[bmRMask]	; get mask bytes
	or	bp, bp			; test # bytes to draw
	jne	PBSM_left		;  more than one, don't combine masks
	xchg	ah, bl			;  only one, combine masks
	and	ah, bh
	mov	cs:[PBSM_rMask], ah	; store SELF MODIFIED and-immediate
	xchg	bl, ch			; bl = initial overflow data, ch=mask
	jmp	PBSM_right
PBSM_left:
	and	bl, ss:lineMask		; apply draw mask to right side mask
	mov	cs:[PBSM_rMask], bl	; store SELF MODIFIED and-immediates
	mov	bl, ch			; init shift out bits
	mov	ch, ah			; ch = extra mask bits
	clr	ah			; clear for future rotate
	lodsb				; get next byte of bitmap
	ror	ax, cl			; shift bits
	xchg	bl, ah			; save bits shifted out
	or	ah, al			; get bitmap data for mask
	and	bh, ss:lineMask		; combine left/line masks
	and	bh, ch			; apply overflow mask bits
	xchg	ah, ch			; save current bitmap data
PBSM_mask1 equ (this word) + 2
	mov	al, ds:[si][1234h]	; apply mask stored with bitmap
	mov	ah, 0xff		; init overflow bits
	ror	ax, cl			; rotate mask data
	xchg	ah, ch			; save old, restore data
	and	bh, al			; apply new mask bits too
	and	ah, bh			; apply combination to data
	mov	al, ah
	call	WriteBitmapByte
	dec	bp			; if zero, then no center bytes
	jz	PBSM_right

PBSM_center:
	clr	ah			; clear for rotate
	lodsb				; next data byte
	ror	ax, cl			; rotate into place
	xchg	bl, ah			; save out bits, restore old out bits
	or	ah, al			; combine old/new bits
	mov	bh, ss:lineMask		; get copy of mask
	and	bh, ch			; apply overflow mask bits
	xchg	ah, ch			; save current bitmap data
PBSM_mask2 equ (this word) + 2
	mov	al, ds:[si][1234h]	; apply mask stored with bitmap
	mov	ah, 0xff		; init overflow bits
	ror	ax, cl			; rotate mask data
	xchg	ah, ch			; save old, restore data
	and	bh, al			; apply new mask bits
	and	ah, bh			; apply user-spec draw mask
	mov	al, ah
	call	WriteBitmapByte
	dec	bp			; one less to do
	jg	PBSM_center		; loop to do next byte of bitmap

PBSM_right:
	mov	ah, ds:[si]		; get last byte
	inc	si			; bump pointer so mask data
					; ...will be accessed correctly
	shr	ah, cl			; shift bits
	or	ah, bl			; get extra bits, if any
PBSM_rMask equ (this byte) + 1
	mov	bh, 03h			; SELF MODIFIED and-immediate
	and	bh, ss:lineMask		; apply user-spec draw mask
	and	bh, ch			; apply overflow mask bits
	xchg	ah, ch			; save current bitmap data
PBSM_mask3 equ (this word) + 2
	mov	al, ds:[si][1234h]	; apply mask stored with bitmap
	mov	ah, 0xff		; init overflow bits
	ror	ax, cl			; rotate mask data
	xchg	ah, ch			; save old, restore data
	and	bh, al			; apply new mask bits
	and	ah, bh
	mov	al, ah
	call	WriteBitmapByte

	.leave
	ret
PutBWScanMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a color scan line (4-bit/pixel)

CALLED BY:	INTERNAL
		PutBitsSimple
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		dx	- index into pattern table
		ds:si	- pointer to bitmap data
		es:di	- pointer into frame buffer to start of scan line

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColorScan	proc	near
		uses	bp
		.enter

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		mov	bp, bx			; get # bits into image
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	ax, ss:[bmRight]	; get right side to get #bytes
		sar	ax, 1
		sar	bx, 1
		sar	bp, 1
		add	si, bp			; index into bitmap
		add	di, bx			; add to screen offset too
		mov	bp, ax			; get right side in bp
		sub	bp, bx			; bp = # dest bytes to write


		; check for a palette
		test	ss:[bmType], mask BMT_PALETTE	; test for palettw
		LONG jnz	handlePalette

		; OK, we're ready to roll.  If there is no shifting, then we
		; can copy them !  

		test	ss:[bmShift], 1		; check low bit for shift
		jnz	moveShift		;  rats, have to do it hard way

		; we're all setup.  Just copy the bytes.  Do the left and right
		; specially, though.

		mov	ah, ss:[bmLMask]	; get left mask setup
		tst	bp			; if only one byte to do...
		jz	loadRight
		lodsb				; get left byte
		mov	dl, al			; as if this were a dither
		mov	al, es:[di]		; get screen data
		call	ss:[modeRoutine]
		stosb				; store 
		dec	bp			; see if any middle bytes
		jz	doRight
		mov	cx, bp
colorLoop:
		lodsb				; get next data byte
		mov	dl, al			; it's like a dither
		mov	al, es:[di]		; screen content
		mov	ah, 0xff		; no mask
		call	ss:[modeRoutine]
		stosb
		loop	colorLoop
doRight:
		mov	ah, 0xff		; so we can use common code
loadRight:
		and	ah, ss:[bmRMask]	; deal with right side
		lodsb				; get data byte
		mov	dl, al
		mov	al, es:[di]		; get screen data
		call	ss:[modeRoutine]
		stosb
done:
		.leave
		ret

		; if there is shifting to do, then things are a little
		; more difficult.  Make do.
moveShift:
		mov	cl, 4			; always shifting by 4
		clr	ah			; initial rotated bits
		clr	dh			; no overflow, initially
		
		; handle left side first
		
		mov	dl, ss:[bmLMask]	; load up left mask
		tst	bp			; if only one byte, finish
		jz	loadRightShift
		lodsb				; get data byte
		ror	ax, cl			; do nibble-rotate
		mov	dh, ah			; save shift out bits

		cmp	dl, 0xff
		je	shiftLoop

		xchg	dl, al			; dl = data to write
		mov	ah, al			; mask up in ah
		mov	al, es:[di]		; screen content
		call	ss:[modeRoutine]	; deal with mix modes
		stosb				; save left side
		dec	bp			; see if any middle to do
		jz	doRightShift

		; do middle bytes
shiftLoop:
		clr	ah
		lodsb				; get next data byte 
		ror	ax, cl
		or	al, dh			; apply overflow bits
		mov	dh, ah			; save new overflow
		mov	ah, 0xff
		mov	dl, al
		mov	al, es:[di]		; load screen
		call	ss:[modeRoutine]
		stosb
		dec	bp
		jnz	shiftLoop

		; do right side
doRightShift:
		mov	dl, 0xff		; so we can share code 
loadRightShift:
		and	dl, ss:[bmRMask]	; combine masks
		clr	ah
		lodsb				; get data byte
		ror	ax, cl 
		or	al, dh			; combine old overflow
		mov	ah, dl			; ah = mask
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb				; store final byte !
		jmp	done
		
handlePalette:
		; there is a palette for this bitmap, so we must map
		; the entries to the palette before writing them out
		;
		test	ss:[bmShift], 1		; check low bit for shift
		jnz	paletteMoveShift	;  rats, have to do it hard way

		mov	ah, ss:[bmLMask]	; get left mask setup
		tst	bp			; if only one byte to do...
		jz	paletteLoadRight
		lodsb				; get left byte
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		mov	dl, al			; as if this were a dither
		mov	al, es:[di]		; get screen data
		call	ss:[modeRoutine]
		stosb				; store 
		dec	bp			; see if any middle bytes
		jz	paletteDoRight
		mov	cx, bp
paletteMapLoop:
		lodsb				; get next data byte
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es			; restore es
		mov	dl, al			; it's like a dither
		mov	al, es:[di]		; screen content
		mov	ah, 0xff		; no mask
		call	ss:[modeRoutine]
		stosb
		loop	paletteMapLoop
paletteDoRight:
		mov	ah, 0xff		; so we can use common code
paletteLoadRight:
		and	ah, ss:[bmRMask]	; deal with right side
		lodsb				; get data byte
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es
		mov	dl, al
		mov	al, es:[di]		; get screen data
		call	ss:[modeRoutine]
		stosb

		jmp	done

		; if there is shifting to do, then things are a little
		; more difficult.  Make do.
paletteMoveShift:
		mov	cl, 4			; always shifting by 4
		clr	ah			; initial rotated bits
		clr	dh			; no overflow, initially
		
		; handle left side first
		
		mov	dl, ss:[bmLMask]	; load up left mask
		tst	bp			; if only one byte, finish
		jz	paletteLoadRightShift
		lodsb				; get data byte
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es			; restore es
		ror	ax, cl			; do nibble-rotate
		mov	dh, ah			; save shift out bits
		xchg	dl, al			; dl = data to write
		mov	ah, al			; mask up in ah
		mov	al, es:[di]		; screen content
		call	ss:[modeRoutine]	; deal with mix modes
		stosb				; save left side
		dec	bp			; see if any middle to do
		jz	paletteDoRightShift

		; do middle bytes
paletteShiftLoop:
		clr	ah
		lodsb				; get next data byte 
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es			; restore es
		ror	ax, cl
		or	al, dh			; apply overflow bits
		mov	dh, ah			; save new overflow
		mov	ah, 0xff
		mov	dl, al
		mov	al, es:[di]		; load screen
		call	ss:[modeRoutine]
		stosb
		dec	bp
		jnz	paletteShiftLoop

		; do right side
paletteDoRightShift:
		mov	dl, 0xff		; so we can share code 
paletteLoadRightShift:
		and	dl, ss:[bmRMask]	; combine masks
		clr	ah
		lodsb				; get data byte
		push	es
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es			; restore es
		ror	ax, cl 
		or	al, dh			; combine old overflow
		mov	ah, dl			; ah = mask
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb				; store final byte !
		jmp	done
PutColorScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutColorScanMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a color scan line, with a mask

CALLED BY:	INTERNAL
		PutBitsSimple
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region
		dx	- index into pattern table
		ds:si	- pointer to bitmap data
		es:di	- pointer into frame buffer to start of scan line

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutColorScanMask proc	near

getMaskPtr	local	word
nBytes		local	word

		.enter

		; calculate # bytes to fill in

		mov	bx, ss:[bmLeft]
		sub	bx, ss:[d_x1]		; get left coordinate
		mov	ss:[nBytes], bx
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]	; get right side to get #bytes
		sar	ax, 1
		sar	bx, 1

		push	ss:[nBytes]		;save before shifting
		sar	ss:[nBytes], 1
		add	di, bx			; add to screen offset too
		mov	cx, si			; cx <- start of data
		sub 	cx, ss:[bmMaskSize]	; cx <- start of mask data
		add	si, ss:[nBytes]		; index into bitmap
		sar	ss:[nBytes]
		sar	ss:[nBytes]
		add	cx, ss:[nBytes]		; index into mask
		mov	ss:[nBytes], ax		; get right side in ss:[nBytes]
		sub	ss:[nBytes], bx		; nBytes = # bytes to write

		; use bx to store pointer to mask data

		mov	bx, cx			; ds:bx -> mask data
		mov	dl, ds:[bx]		; grab first mask byte
		inc	bx

		pop	cx
		and	cx, 7			;only want low 3 bits
		mov	dh, 0x80
		shr	dh, cl			; init test bit

		; check for a palette

		test	ss:[bmType], mask BMT_PALETTE	; test for palettw
		LONG jnz	handlePalette

		
		; OK, we're ready to roll.  This time we need to do each byte
		; individually, since there might be a mask.

		test	ss:[bmShift], 1		; check low bit for shift
		jnz	moveShift		;  rats, have to do it hard way

		; no shifting of the data required.

		mov	ah, ss:[bmLMask]	; get left mask setup
		tst	ss:[nBytes]		; if only one byte to do...
		jz	loadRight
		lodsb				; get left byte
		call	ApplyMaskAH		; do the mask-the-pixels thing

		mov	ch, dl
		mov	dl, al			; dl = data
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	dl, ch
		stosb				; store 
		dec	ss:[nBytes]			; see if any middle bytes
		jz	doRight
maskLoop:
		lodsb
		call	SetMaskAH
		mov	ch, dl
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	dl, ch
		stosb
		dec	ss:[nBytes]
		jnz	maskLoop
doRight:
		mov	ah, 0xff		; so we can use common code
loadRight:
		and	ah, ss:[bmRMask]	; deal with right side
		lodsb				; get data byte
		call	ApplyMaskAH
		mov	ch, dl
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	dl, ch
		stosb
done:
		.leave
		ret

		; if there is shifting to do, then things are a little
		; more difficult.  Make do.
moveShift:
		mov	cl, 4			; always shifting by 4
;;;		mov	cs:[nextLeft], 0xff	; init with no masking
		mov	ss:[getMaskPtr], bx	; save 
		mov	bx, dx			; need to make dx available
		
		; handle left side first
		
		mov	dl, ss:[bmLMask]	; load up left mask
		tst	ss:[nBytes]		; if only one byte, finish
		jz	loadRightShift
		clr	ah			; initial rotated bits
		lodsb				; get data byte
		ror	ax, cl			; do nibble-rotate
		mov	ch, ah			; save shift out bits

		cmp	dl, 0xff
		je	shiftLoop

		;
		; the destination bitmap has an overlapping pixel
		; to the left, so let's do that one here
		;

		mov	ah, dl			;assume 0x0f
		test	bl, bh
		jnz	writeByte

		clr	ah

writeByte:
		mov	dl, al			
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb				; save left side

		;
		;  update mask ptr
		;
		shr	bh
		jnc	noProblem

		push	di
		mov	di, ss:[getMaskPtr]
		mov	bl, ds:[di]
		inc	di
		mov	ss:[getMaskPtr], di
		pop	di
		mov	bh, 0x80

noProblem:
		dec	ss:[nBytes]		; see if any middle to do
		jz	doRightShift

		; do middle bytes
shiftLoop:
		clr	ah
		lodsb				; get next data byte 
		ror	ax, cl
		or	al, ch			; apply overflow bits
		mov	ch, ah			; save new overflow
		call	GetMaskAH
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb
		dec	ss:[nBytes]
		jnz	shiftLoop

		; do right side
doRightShift:
		mov	dl, 0xff		; so we can share code 
loadRightShift:
		and	dl, ss:[bmRMask]	; combine masks
		clr	ah
		lodsb				; get data byte
		ror	ax, cl 
		or	al, ch			; combine old overflow
		call	GetMaskAH
		and	ah, dl
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb				; store final byte !
		jmp	done

		
handlePalette:
		; OK, we're ready to roll.  This time we need to do each byte
		; individually, since there might be a mask.

		test	ss:[bmShift], 1		; check low bit for shift
		jnz	paletteMoveShift	; rats, have to do it hard way

		; no shifting of the data required.

		mov	ah, ss:[bmLMask]	; get left mask setup
		tst	ss:[nBytes]		; if only one byte to do...
		jz	paletteLoadRight
		lodsb				; get left byte
		push	es,bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es, bx			; restore es
		call	ApplyMaskAH		; do the mask-the-pixels thing
		mov	ch, dl
		mov	dl, al			; dl = data
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	dl, ch
		stosb				; store 
		dec	ss:[nBytes]		; see if any middle bytes
		jz	paletteDoRight
paletteMaskLoop:
		lodsb
		push	es, bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es,bx			; restore es
		call	SetMaskAH
		mov	ch, dl
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	dl, ch
		stosb
		dec	ss:[nBytes]
		jnz	paletteMaskLoop
paletteDoRight:
		mov	ah, 0xff		; so we can use common code
paletteLoadRight:
		and	ah, ss:[bmRMask]	; deal with right side
		lodsb				; get data byte
		push	es,bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es,bx			; restore es
		call	ApplyMaskAH
		mov	ch, dl
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	dl, ch
		stosb
		jmp	done

		; if there is shifting to do, then things are a little
		; more difficult.  Make do.
paletteMoveShift:
		mov	cl, 4			; always shifting by 4
;;;		mov	cs:[nextLeft], 0xff	; init with no masking
		mov	cs:[getMaskPtr], bx	; save 
		mov	bx, dx			; need to make dx available
		
		; handle left side first
		
		mov	dl, ss:[bmLMask]	; load up left mask
		tst	ss:[nBytes]		; if only one byte, finish
		jz	paletteLoadRightShift
		clr	ah			; initial rotated bits
		lodsb				; get data byte
		push	es,bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es,bx			; restore es
		ror	ax, cl			; do nibble-rotate
		mov	ch, ah			; save shift out bits
		call	GetMaskAH		; ah = shifted mask bits 
		and	ah, dl
		mov	dl, al			
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb				; save left side
		dec	ss:[nBytes]		; see if any middle to do
		jz	paletteDoRightShift

		; do middle bytes
paletteShiftLoop:
		clr	ah
		lodsb				; get next data byte 
		push	es,bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es,bx			; restore es
		ror	ax, cl
		or	al, ch			; apply overflow bits
		mov	ch, ah			; save new overflow
		call	GetMaskAH
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb
		dec	ss:[nBytes]
		jnz	paletteShiftLoop

		; do right side
paletteDoRightShift:
		mov	dl, 0xff		; so we can share code 
paletteLoadRightShift:
		and	dl, ss:[bmRMask]	; combine masks
		clr	ah
		lodsb				; get data byte
		push	es, bx
		les	bx, ss:[bmPalette]	; es:bx - palette
		xlat	es:[bx]
		pop	es, bx			; restore es
		ror	ax, cl 
		or	al, ch			; combine old overflow
		call	GetMaskAH
		and	ah, dl
		mov	dl, al
		mov	al, es:[di]
		call	ss:[modeRoutine]
		stosb				; store final byte !
		jmp	done
PutColorScanMask endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMaskAH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		bh = left pixel mask pixel desired
		bl = mask byte

Return:		ah = 1 nibble/pixel mask

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar  5, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 1
GetMaskAH	proc	near
	.enter	inherit PutColorScanMask

	mov	ah, 0xff
	call	GetMaskCommon

	.leave
	ret
GetMaskAH	endp

GetMaskCommon	proc	near
	.enter	inherit PutColorScanMask

	test	bl, bh
	jnz	shiftRight

	and	ah, 0x0f

shiftRight:
	shr	bh
	jc	nextByte

checkRight:
	test	bl, bh
	jnz	shiftForNextRound

	and	ah, 0xf0
	
shiftForNextRound:
	shr	bh
	jc	nextByteNextRound
	
done:	
	.leave
	ret

nextByte:
	push	di
	mov	di, ss:[getMaskPtr]
	mov	bl, ds:[di]
	inc	di
	mov	ss:[getMaskPtr], di
	pop	di
	mov	bh, 0x80
	jmp	checkRight

nextByteNextRound:
	push	di
	mov	di, ss:[getMaskPtr]
	mov	bl, ds:[di]
	inc	di
	mov	ss:[getMaskPtr], di
	pop	di
	mov	bh, 0x80
	jmp	done

GetMaskCommon	endp
	
		; utility routines to build mask for 4-bit color bitmap data

else

		; this one is for the rotated case.
GetMaskAH	proc	near
		mov	ah, 0xff
		test	bl, bh			; check a pixel
		jz	killRight
checkNext:
		shr	bh, 1			; down to next pixel
		jc	nextMaskByte1
getLeft:
		test	bl, bh			; check next one
		jz	setNextLeft
;;;		mov	cs:[nextLeft], 0xff
doneCheck:
		shr	bh, 1			; get ready for next time
		jc	nextMaskByte2
done:
		ret

		; kill left pixel
setNextLeft:		
		and 	ah, 0x0f
		jmp	doneCheck
killRight:
		and 	ah, 0xf0
		jmp	checkNext
nextMaskByte1:
;;;		mov	cs:[nextLeft], 0xff
nextMaskByte2:
		mov	dh, 80h
getMaskPtr equ	(this word) + 1
		mov	bx, 1234h		
		mov	dl, ds:[bx]
		inc	bx
		mov	cs:[getMaskPtr], bx
		mov	bx, dx
		jmp	done
GetMaskAH	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMaskAH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		dh - bit
		dl - mask byte

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar  5, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 1
SetMaskAH	proc	near
	.enter	inherit PutColorScanMask

	mov	ah, 0xff
	mov	ss:[getMaskPtr], bx
	mov	bx, dx
	call	GetMaskCommon
	mov	dx, bx
	mov	bx, ss:[getMaskPtr]

	.leave
	ret
SetMaskAH	endp

ApplyMaskAH	proc	near
	.enter	inherit PutColorScanMask

	mov	ss:[getMaskPtr], bx
	mov	bx, dx
	call	GetMaskCommon
	mov	dx, bx
	mov	bx, ss:[getMaskPtr]

	.leave
	ret
ApplyMaskAH	endp

else

		; these ones are for the non-rotated case
SetMaskAH	label	near
		mov	ah, 0xff
ApplyMaskAH	proc	near
		test	dl, dh			; check a pixel
		jz	killLeft
checkNext:
		shr	dh, 1			; down to next pixel
		jc	nextMaskByte1
getRight:
		test	dl, dh			; check next one
		jz	killRight
doneCheck:
		shr	dh, 1			; get ready for next time
		jc	nextMaskByte2
done:
		ret

		; kill left pixel
killLeft:		
		and	ah, 0x0f
		jmp	checkNext
killRight:
		and 	ah, 0xf0
		jmp	doneCheck
nextMaskByte1:
		and 	ah, 0xf0
nextMaskByte2:
		mov	dh, 80h
		mov	dl, ds:[bx]
		inc	bx
		jmp	done
ApplyMaskAH	endp

endif

VidEnds		Bitmap

NMEM <VidSegment	GetBits	>
MEM  <VidSegment	Misc	>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOneScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy one scan line of video buffer to system memory

CALLED BY:	INTERNAL
		VidGetBits

PASS:           ds:si   - address of start of scan line in frame buffer
		es:di   - pointer into sys memory where scan line to be stored
		cx      - # bytes left in buffer
		d_x1    - left side of source
		d_dx    - # source pixels
		shiftCount - # bits to shift

RETURN:         es:di   - pointer moved on past scan line info just stored
												cx      - # bytes left in buffer
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
GetOneScan	proc		near

		; first calculate index into scan line

		mov	dx, cx			; use dx for buffer count 
		mov	bx, ss:[d_x1]		; get left side position
		mov	ax, ss:[d_dx]		; ax = width of transfer (pixs)
		inc	ax			; round up
		shr	bx, 1
		shr	ax, 1
		add	si, bx			; ds:si -> left side of source
		mov	ch, al			; save this count
		sub	dx, ax			; see if enough room to copy
		js	GOS_noRoom		;  nope, quit with error
		push	dx			; save remaining count
		mov	cl, ss:[shiftCount]	; get bit shift (always left)
		tst	cl			; do it fast if no shifting
		jz	fast

		; get first shift in byte

		clr	ah			; clear out initial shift-in
		lodsb				; get first byte
		rol	ax, cl			; do the shift
		mov	bl, al			; save initial bits

		; do the read/shift work, write result 
GOS_smallLoop:
		clr	ah			; clear out initial shift-in
		lodsb				; get next source byte
		rol	ax, cl			; do the shift
		xchg	bl, al			; get old shift-in byte
		or	al, ah			; combine bits
		stosb				; save in temp buffer
		dec	ch			; keep going till middle done
		jnz	GOS_smallLoop

		; all done, restore count and leave
done:
		pop	cx			; restore #bytes left
		ret

;----------------------------------------------------------------------------

		; no room left, set #bytes left in buffer to -1 and quit
GOS_noRoom:
		mov	cx, -1			; set result
		ret

		; don't do the shift if we don't need to
fast:
		mov	cl, ch			; make cx=#bytes
		clr	ch
		rep	movsb
		jmp	done
GetOneScan	endp

NMEM <VidEnds		GetBits	>
MEM  <VidEnds		Misc	>

VidSegment	Bitmap

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ByteModeRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set of routines for implementing drawing mode on non-EGA
		compatible display modes

CALLED BY:	Bitmap drivers

PASS:		al = screen data
		dl = scan line dither pattern
		ah = new bits AND mask

		where:	new bits = bits to write out (as in bits from a
				   bitmap).  For objects like rectangles,
				   where newBits=all 1s, ah will hold the
				   mask only.  Also: this mask is a final
				   mask, including any user-specified draw
				   mask.

RETURN:		al = byte to write

DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		see below for each mode

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;	the comments below use the following conventions (remember 
;	boolean algebra?...)
;		AND	^
;		OR	v
;		NOT	~




BMR_saveMask	byte	0
ByteModeRoutines	proc		near
	ForceRef ByteModeRoutines
ByteCLEAR label	near		; (screen^~(data^mask))v(data^mask^resetColor)
	not	ah		;
	and	al, ah		;
ByteNOP	label	near		;
	ret
ByteCOPY label	near		; (screen^~(data^mask))v(data^mask^pattern)
	not	ah		;
	and	al, ah		;
	not	ah		;
	and	ah, dl		;
	or	al, ah		; 
	ret
ByteAND	label	near		; screen^((data^mask^pattern)v~(data^mask))
	not	ah		
	mov	cs:[BMR_saveMask], ah
	not	ah
	and	ah, dl
	or	ah, cs:[BMR_saveMask]
	and	al, ah
	ret
ByteXOR	label	near		; screenXOR(data^mask^pattern)
	and	ah, dl
ByteINV	label	near		; screenXOR(data^mask) 
	xor	al, ah
	ret
ByteOR	label	near		; screenv(data^mask^pattern) 
	and	ah, dl
ByteSET	label	near		; (screen^~(data^mask))v(data^mask^setColor)
	or	al, ah
	ret
ByteModeRoutines	endp


ByteModeRout	label	 word
	nptr	ByteCLEAR
	nptr	ByteCOPY
	nptr	ByteNOP
	nptr	ByteAND
	nptr	ByteINV
	nptr	ByteXOR
	nptr	ByteSET
	nptr	ByteOR

VidEnds		Bitmap





















