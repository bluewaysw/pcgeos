
COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Dumb Raster video driver
FILE:		dumbcomRaster.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name			Description
	----			-----------
    INT BltSimpleLine		blt a single scan line (vertically)
    INT BltShift		Transfer a single scan line that needs to
				be shifted
    INT BltShiftHoriz		Blt part of a scan line horizontally to the
				right, with	 need to shift
    INT NullBMScan		Transfer a scan line's worth of system
				memory to screen
    INT FillBWScan		Transfer a scan line's worth of system
				memory to screen
    INT PutBWScan		Monochrome bitmap drawline
    INT PutBWScanMask		Monochrome bitmap drawline
    INT GetOneScan		Copy one scan line of video buffer to
				system memory
    INT ByteModeRoutines	Set of routines for implementing drawing
				mode on non-EGA compatible display modes

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/88	initial version


DESCRIPTION:
	This is the source for the Bitmap screen driver bit block transfer
	routines.

	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/usr/pcgeos/Spec/video.doc).  

	$Id: dumbcomRaster.asm,v 1.1 97/04/18 11:42:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


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
NMEM <		segmov	ds, es			; set both -> screen	>
MEM  <		mov	ds, ss:[bm_lastSegSrc]	; get source segment	>

		mov	bx, ss:[bmLeft]		; save these for later
		mov	ax, ss:[bmRight]	


		; calculate masks, and save shift amount, other good things

		mov	cl, 3			; divide by 8
		mov	dx, ss:[bmRight] 	; recalc # bytes
		shr	dx, cl
		mov	ch, dl
		mov	dx, bx			; calc #bytes to draw
		shr	dx, cl
		sub	ch, dl			; ch = # bytes to write
		mov	dx, bx			; get dest left side
		mov	ah, dl			; save the low byte for later
		sub	dx, ss:[d_x1]		; dx = index into blt dest
		add	dx, ss:[d_x1src]	; dx = left side of source
		mov	al, dl			; calculate shift value
		and	ax, 0707h		; if no shift, result == 
		sub	ah, al			; ah = #bits shift right 
		mov	cl, ah			; cl = shift amount, ch=#bytes
		push	cx			; save values

		; calculate byte indices into scan line, both source and dest

		mov	cl, 3
		mov	ax, ss:[bmRight] 	; get right side coord
		mov	dx, bx			; left side coord saved in bx
		shr	ax, cl			; calc byte index
		shr	dx, cl			;   for both
		add	di, dx			; byte index for destination
		sub	bx, ss:[d_x1]		; bx = #pix index into dest blt
		add	bx, ss:[d_x1src] 	; bx = source left side
		shr	bx, cl			; bx = source left byte index
		add	si, bx
		pop	cx			; restore counts
		mov	dx, {word} ss:[bmRMask]	; restore masks

		; check to see if we need to shift anything, use diff routine

		tst	cl			; check shift amount
		je	BSL_bytemove
		jmp	BltShift		;  shift, use slower routine

BSL_bytemove:
		mov	cl, ch			; don't need bit shift count
		clr	ch			; so just use whole word
		tst	cl
		jne	BSL_doleft
		and	dl, dh			; combine masks
		jmp	BSL_doright

		; check to see if we are copying right to left
BSL_doleft:
		mov	ax, ss:[d_x1]		; get dest left side coord
		cmp	ax, ss:[d_x1src]	; compare to source left side
		jg	BSL_RightToLeft		; do it backwards 

		; mask left word 

ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb
endif
		and	al, dh			; apply mask
RW <		xornf di, 1						>
		mov	ah, es:[di]		; get destination
RW <		xornf di, 1						>
		not	dh
		and	ah, dh
		or	al, ah
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb
endif
		dec	cx			; see if done
		je	BSL_doright

		; copy middle bytes

ifdef	REVERSE_WORD
		call	DoRepMovsbFar
else
		rep	movsb
endif

		; handle right word specially
BSL_doright:
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb
endif
		and	al, dl			; apply right mask
RW <		xornf di, 1						>
		mov	ah, es:[di]		; get destination
RW <		xornf di, 1						>
		not	dl
		and	ah, dl			; apply reverse mask
		or	al, ah
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb
endif

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

ifdef	REVERSE_WORD
		call	DoLodsbBackFar
else
		lodsb
endif
		and	al, dl				; do right side
RW <		xornf di, 1						>
		mov	ah, es:[di]			; get destination
RW <		xornf di, 1						>
		not	dl				; reverse mask
		and	ah, dl				; save bits from dest
		or	al, ah
ifdef	REVERSE_WORD
		call	DoStosbBackFar
else
		stosb
endif
		dec	cx
		je	BSL_rldoleft

		; draw middle words

ifdef	REVERSE_WORD
		call	DoRepMovsbBackFar
else
		rep	movsb
endif

		; mask left byte 
BSL_rldoleft:
ifdef	REVERSE_WORD
		call	DoLodsbBackFar
else
		lodsb
endif
		and	al, dh				; apply left mask
RW <		xornf di, 1						>
		mov	ah, es:[di]			; get destination
RW <		xornf di, 1						>
		not	dh
		and	ah, dh				; apply reverse mask
		or	al, ah
ifdef	REVERSE_WORD
		call	DoStosbBackFar
else
		stosb
endif
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
		cx	- counts (ch=byte count, cl=bit shift count)

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
		; let diff1= ((dl^7)-(sl^7)), diff2=((dr^7)-(sr^7))
		; then flag = (diff1 XOR diff2) AND diff1
		; if flag < 0, then preload

		push	dx		; save masks
		mov	ah, byte ptr ss:[bmLeft] ; ah = dest left
		and	ah, 7		; ah = dl^7
		mov	dx, ss:[bmLeft] ; calc index into source scan
		sub	dx, ss:[d_x1]	; cx = index
		add	dx, ss:[d_x1src] ; cx = source left
		and	dl, 7		; isolate low three bits
		sub	ah, dl		; ah = ((dl^7)-(sl^7))
		mov	al, byte ptr ss:[bmRight] ; al = dest right
		and	al, 7		; al = dr^7
		mov	dx, ss:[bmRight] ; calc index into source scan
		sub	dx, ss:[d_x1]	; cx = index
		add	dx, ss:[d_x1src] ; cx = source right
		and	dl, 7		; isolate low three bits
		sub	al, dl		; al = ((dr^7)-(sr^7))
		xor	al, ah		; al=(diff1 XOR diff2)
		and	ah, al		; ah=(diff1 XOR diff2) AND diff1
		mov	bh, ah		; save test result
					;  bh = preload test flag
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
		clr	bl		; clear out initial shift-save
		tst	cl		; if shift left, do separate
		js	BS_shiftLeft	; do left shifting

		; check for need to preload first value (more src than dest)

		tst	bh 		; if high bit not set
		jns	BS_start	;  then skip preload
		clr	ah		; clear initial shift bits
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get first source byte
endif
		ror	ax, cl		; do shift
		mov	bl, ah		; new initial shift-out bits

		; test for single byte write, need to combine masks
BS_start:
		tst	ch		; check # bytes to write
		jne	BS_srLeft	; writing more than one
		and	dl, dh		; combine masks
		jmp	BS_srRight	; do right side

		; shifting right, do left side byte (and mask it)
BS_srLeft:	
		clr	ah		; slear out initial shift-in bits
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get next source byte
endif
		ror	ax, cl		; do the shift
		xchg	bl, ah		; get old shift-in bits
		or	al, ah		; al=new bits to write
		and	al, dh		; apply left mask
RW <		xornf di, 1						>
		mov	ah, es:[di]	; get destination byte
RW <		xornf di, 1						>
		not	dh		; create negative image mask
		and	ah, dh		; apply mask to existing bits
		or	al, ah		; combine parts
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb			; write out the byte
endif
		dec	ch		; one less byte to write
		je	BS_srRight	; if no middle bytes, do right side

		; do the middle bytes

BS_smallLoop:
		clr	ah		; clear out initial shift-in
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get next source byte
endif
		ror	ax, cl		; do the shift
		xchg	bl, ah		; get old shift-in byte
		or	al, ah		; combine bits
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb			; save in temp buffer
endif
		dec	ch		; keep going till middle done
		jne	BS_smallLoop

		; do the right side
BS_srRight:
		clr	ah		; slear out initial shift-in bits
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get next source byte
endif
		ror	ax, cl		; do the shift
		xchg	bl, ah		; get old shift-in bits
		or	al, ah		; al=new bits to write
		and	al, dl		; apply right mask
RW <		xornf di, 1						>
		mov	ah, es:[di]	; get destination byte
RW <		xornf di, 1						>
		not	dl		; create negative image mask
		and	ah, dl		; apply mask to existing bits
		or	al, ah		; combine parts
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb			; write out the byte
endif
			
		; all done, cleanup and exit
BS_done:
		pop	ds		; restore data seg
		ret			; returns to BltSimpleLine's caller

;---------------------------------------------------------------------

		; special case: need to shift left
		; check for need to preload the first value (more src than dest)
BS_shiftLeft:
		neg	cl		; make shift positive
		clr	ah
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get first source byte
endif
		rol	ax, cl		; do shift
		mov	bl, al		; initial shift-out bits

		; test for single byte write, need to combine masks

		tst	ch		; check # bytes to write
		jne	BS_slLeft	; writing more than one
		and	dl, dh		; combine masks
		jmp	BS_slRight	; do right side

		; shifting left, do left side byte (and mask it)
BS_slLeft:	
		clr	ah		; slear out initial shift-in bits
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get next source byte
endif
		rol	ax, cl		; do the shift
		xchg	bl, al		; get old shift-in bits
		or	al, ah		; al=new bits to write
		and	al, dh		; apply left mask
RW <		xornf di, 1						>
		mov	ah, es:[di]	; get destination byte
RW <		xornf di, 1						>
		not	dh		; create negative image mask
		and	ah, dh		; apply mask to existing bits
		or	al, ah		; combine parts
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb			; write out the byte
endif
		dec	ch		; one less byte to write
		je	BS_slRight	; if no middle bytes, do right side

		; do the middle bytes

BSL_smallLoop:
		clr	ah		; clear out initial shift-in
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get next source byte
endif
		rol	ax, cl		; do the shift
		xchg	bl, al		; get old shift-in byte
		or	al, ah		; combine bits
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb			; save in temp buffer
endif
		dec	ch		; keep going till middle done
		jne	BSL_smallLoop

		; do the right side
BS_slRight:
		mov	al, bl		; assume no postload
		tst	bh		; preload for left shift is postload
		jns	BSL_finish	;  no postload
		clr	ah		; slear out initial shift-in bits
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb			; get next source byte
endif
		rol	ax, cl		; do the shift
		xchg	bl, al		; get old shift-in bits
BSL_finish:
		or	al, ah		; al=new bits to write
		and	al, dl		; apply right mask
RW <		xornf di, 1						>
		mov	ah, es:[di]	; get destination byte
RW <		xornf di, 1						>
		not	dl		; create negative image mask
		and	ah, dl		; apply mask to existing bits
		or	al, ah		; combine parts
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb			; write out the byte
endif
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
		mov	al, ch			; move # bytes to ax
		clr	ah
		add	ax, 2			; a little extra
		and	al, 0feh		; make sure it's even
		sub	sp, ax			; allocate some 
		mov	ax, sp			; save poitner to buffer
		push	di			; save frame dest
		mov	di, ax			; di -> temp buffer
		segmov	es, ss			; es:di -> temp buffer
		push	cx			; save byte count
		clr	bl			; save initial shift-in butes
		tst	cl			; if shift left, branch
		js	BSH_left		;  yes, shift left

		; shifting right, check for preload

		tst	bh			; see if high bit set
		jns	BSH_smallLoop		;  no, skip preload
		clr	ah
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get first source byte
endif
		ror	ax, cl			; do the shift
		mov	bl, ah			; save shift out bits
BSH_smallLoop:
		clr	ah
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get next source byte
endif
		ror	ax, cl
		xchg	bl, ah			; get/save shift out bits
		or	al, ah			; combine this/prev
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb				; save in temp buffer
endif
		dec	ch
		jns	BSH_smallLoop		; do all the bytes

		; done with copy, now copy to screen
BSH_write:
		pop	cx			; restore count
		pop	di			; restore dest ptr
		segmov	es, ds			; set up es:di -> screen
		segmov	ds, ss			; ds -> temp block
		mov	si, sp			; ds:si -> temp buffer
		tst	ch			; see if only 1 byte to write
		jne	BSH_wleft		;  nope, do left
		and	dl, dh			; combine the masks
		jmp	short BSH_wRight	; and just do the right side
BSH_wleft:
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get left byte
endif
		and	al, dh			; mask left
RW <		xornf di, 1						>
		mov	ah, es:[di]		; get dest byte
RW <		xornf di, 1						>
		not	dh			; reverse mask
		and	ah, dh			; mask existing bits
		or	al, ah			; combine for left byte
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb				; write to screen
endif
		dec	ch			; one less to go
		je	BSH_wRight		;  if done, do right side
		mov	cl, ch			; copy remaining count over
		clr	ch			; make it a word
ifdef	REVERSE_WORD
;		call	DoRepMovsbFar
;use manual load/store since we reversed store in stack buffer - brianc 2/10/97
		pushf
		push	ax
		Assert	ne, cx, 0
localLoop:
		call	DoLodsbFar
		call	DoStosbFar
		loop	localLoop
		pop	ax
		popf
else
		rep	movsb
endif
BSH_wRight:
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get left byte
endif
		and	al, dl			; mask left
RW <		xornf di, 1						>
		mov	ah, es:[di]		; get dest byte
RW <		xornf di, 1						>
		not	dl			; reverse mask
		and	ah, dl			; mask existing bits
		or	al, ah			; combine for left byte
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb				; write to screen
endif
		mov	sp, bp			; restore stack pointer
		pop	bp			; restore frame pointer
		pop	es			; restore extra seg
		pop	ds			; pushed by BltSimpleLine
		ret				; ret to BltSimpleLine's caller

		; special case: shifting left
BSH_left:
		neg	cl			; make shift positive
		clr	ah
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get first source byte
endif
		rol	ax, cl			; do the shift
		mov	bl, al			; save shift out bits
BSHL_smallLoop:
		clr	ah
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get next source byte
endif
		rol	ax, cl
		xchg	bl, al			; get/save shift out bits
		or	al, ah			; combine this/prev
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb				; save in temp buffer
endif
		dec	ch
		js	BSH_write
		jne	BSHL_smallLoop		; do all the bytes
		tst	bh			; see if high bit set
		js	BSHL_smallLoop		;  yes, load one more
		mov	al, bl			;  no, just use last read
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb
endif
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
	sar	bx, cl
	sar	bp, cl
	add	si, bp			; add bytes-to-left-side to indices
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sub	bp, bx			; bp = # dest bytes to write
	mov	dl, ss:linePatt		;  dl = pattern
	mov	dh, ss:lineMask 	;  dh = draw mask

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
	jne	FBS_left		;  more than one, don't combine masks
	mov	ah, bl			;  only one, combine masks
	and	ah, bh
	mov	cs:[FBS_rMask], ah	; store SELF MODIFIED and-immediate
	mov	bl, ch			; get initial shift out bits
	jmp	short	FBS_right
FBS_left:
	and	bl, dh			; apply draw mask to right side mask
	mov	cs:[FBS_rMask], bl	; store SELF MODIFIED and-immediates
	mov	bl, ch			; init shift out bits
	clr	ah			; clear for future rotate
	lodsb				; get next byte of bitmap
	ror	ax, cl			; shift bits
	xchg	bl, ah			; save bits shifted out
	or	ah, al			; get bitmap data for mask
	and	ah, bh			; mask off left side
	and	ah, dh			; apply user-spec draw mask
RW <	xornf di, 1							>
	mov	al, es:[di]		; al = screen data
RW <	xornf di, 1							>
	call	ss:[modeRoutine]					   
ifdef	REVERSE_WORD
	call	DoStosbFar
else
	stosb				; write byte
endif
	dec	bp			; if zero, then no center bytes
	jz	FBS_right

FBS_center:
	clr	ah			; clear for rotate
	lodsb				; next data byte
	ror	ax, cl			; rotate into place
	xchg	bl, ah			; save out bits, restore old out bits
	or	ah, al			; combine old/new bits
	and	ah, dh			; apply user-spec draw mask
RW <	xornf di, 1							>
	mov	al, es:[di]		; get screen data
RW <	xornf di, 1							>
	call	ss:[modeRoutine]	; call right routine
ifdef	REVERSE_WORD
	call	DoStosbFar
else
	stosb				; write the byte
endif
	dec	bp			; one less to do
	jg	FBS_center		; loop to do next byte of bitmap

FBS_right:
	mov	ah, ds:[si]		; get last byte
	shr	ah, cl			; shift bits
	or	ah, bl			; get extra bits, if any
FBS_rMask equ (this byte) + 2
	and	ah, 03h			; SELF MODIFIED and-immediate
	and	ah, dh			; apply user-spec draw mask
RW <	xornf di, 1							>
	mov	al, es:[di]		; get screen data
RW <	xornf di, 1							>
	call	ss:[modeRoutine]	; combine bits
ifdef	REVERSE_WORD
	call	DoStosbFar
else
	stosb				; write the byte		
endif
	.leave
	ret
FillBWScan	endp


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
	sar	bx, cl
	sar	bp, cl
	add	si, bp			; add bytes-to-left-side to indices
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sub	bp, bx			; bp = # dest bytes to write
	mov	dl, {byte} ss:setColor	;  dl = color of "set" pixels
	mov	dh, ss:lineMask 	;  dh = draw mask

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
	jne	PBS_left		;  more than one, don't combine masks
	mov	ah, bl			;  only one, combine masks
	and	ah, bh
	mov	cs:[PBS_rMask], ah	; store SELF MODIFIED and-immediate
	mov	bl, ch			; get initial shift out bits
	jmp	short	PBS_right
PBS_left:
	and	bl, dh			; apply draw mask to right side mask
	mov	cs:[PBS_rMask], bl	; store SELF MODIFIED and-immediates
	mov	bl, ch			; init shift out bits
	clr	ah			; clear for future rotate
	lodsb				; get next byte of bitmap
	ror	ax, cl			; shift bits
	xchg	bl, ah			; save bits shifted out
	or	ah, al			; get bitmap data for mask
	and	bh, dh			; combine left/line masks
	and	ah, bh			; apply combination to data

	call	ss:[mixRoutine]		; get/mix/set byte
;	mov	al, es:[di]		; al = screen data
;	not	bh
;	and	al, bh
;	not	bh
;	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
;	or	al, bh			; clear out bits we don't need
;	call	ss:[modeRoutine]					   
;	stosb				; write byte
	dec	bp			; if zero, then no center bytes
	jz	PBS_right

PBS_center:
	clr	ah			; clear for rotate
	lodsb				; next data byte
	ror	ax, cl			; rotate into place
	xchg	bl, ah			; save out bits, restore old out bits
	or	ah, al			; combine old/new bits
	and	ah, dh			; apply user-spec draw mask
	mov	bh, dh			; get copy of mask

	call	ss:[mixRoutine]		; get/mix/set byte
;	mov	al, es:[di]		; get screen data
;	not	bh
;	and	al, bh
;	not	bh
;	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
;	or	al, bh			; clear out bits we don't need
;	call	ss:[modeRoutine]	; call right routine
;	stosb				; write the byte

	dec	bp			; one less to do
	jg	PBS_center		; loop to do next byte of bitmap

PBS_right:
	mov	ah, ds:[si]		; get last byte
	shr	ah, cl			; shift bits
	or	ah, bl			; get extra bits, if any
PBS_rMask equ (this byte) + 1
	mov	bh, 03h			; SELF MODIFIED and-immediate
	and	bh, dh			; apply user-spec draw mask
	and	ah, bh

	call	ss:[mixRoutine]		; get/mix/set byte
;	mov	al, es:[di]		; get screen data
;	not	bh
;	and	al, bh
;	not	bh
;	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
;	or	al, bh			; clear out bits we don't need
;	call	ss:[modeRoutine]	; combine bits
;	stosb				; write the byte		

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

	CLEAR_PREFETCH_QUEUE

	; calculate # bytes to fill in

	mov	bp, bx			; get # bits into image at start
	sub	bp, ss:[d_x1]		; get left coordinate
	mov	cl, 3			; want to get byte indices
;;;	add	ax, 7
	sar	ax, cl
;;;	add	bx, 7
	sar	bx, cl
;;;	add	bp, 7
	sar	bp, cl
	add	si, bp			; add bytes-to-left-side to indices
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sub	bp, bx			; bp = # dest bytes to write
	mov	dl, {byte} ss:setColor	;  dl = color for "set" pixels
	mov	dh, ss:lineMask 	;  dh = draw mask

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
	and	bl, dh			; apply draw mask to right side mask
	mov	cs:[PBSM_rMask], bl	; store SELF MODIFIED and-immediates
	mov	bl, ch			; init shift out bits
	mov	ch, ah			; ch = extra mask bits
	clr	ah			; clear for future rotate
	lodsb				; get next byte of bitmap
	ror	ax, cl			; shift bits
	xchg	bl, ah			; save bits shifted out
	or	ah, al			; get bitmap data for mask
	and	bh, dh			; combine left/line masks
	and	bh, ch			; apply overflow mask bits
	xchg	ah, ch			; save current bitmap data
PBSM_mask1 equ (this word) + 2
	mov	al, ds:[si][1234h]	; apply mask stored with bitmap
	mov	ah, 0xff		; init overflow bits
	ror	ax, cl			; rotate mask data
	xchg	ah, ch			; save old, restore data
	and	bh, al			; apply new mask bits too
	and	ah, bh			; apply combination to data
	call	ss:[mixRoutine]		; get/mix/set byte
;	mov	al, es:[di]		; al = screen data
;	not	bh
;	and	al, bh
;	not	bh
;	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
;	or	al, bh			; clear out bits we don't need
;	call	ss:[modeRoutine]					   
;	stosb				; write byte
	dec	bp			; if zero, then no center bytes
	jz	PBSM_right

PBSM_center:
	clr	ah			; clear for rotate
	lodsb				; next data byte
	ror	ax, cl			; rotate into place
	xchg	bl, ah			; save out bits, restore old out bits
	or	ah, al			; combine old/new bits
	mov	bh, dh			; get copy of mask
	and	bh, ch			; apply overflow mask bits
	xchg	ah, ch			; save current bitmap data
PBSM_mask2 equ (this word) + 2
	mov	al, ds:[si][1234h]	; apply mask stored with bitmap
	mov	ah, 0xff		; init overflow bits
	ror	ax, cl			; rotate mask data
	xchg	ah, ch			; save old, restore data
	and	bh, al			; apply new mask bits
	and	ah, bh			; apply user-spec draw mask
	call	ss:[mixRoutine]		; get/mix/set byte
;	mov	al, es:[di]		; get screen data
;	not	bh
;	and	al, bh
;	not	bh
;	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
;	or	al, bh			; clear out bits we don't need
;	call	ss:[modeRoutine]	; call right routine
;	stosb				; write the byte
	dec	bp			; one less to do
	jg	PBSM_center		; loop to do next byte of bitmap

PBSM_right:
	mov	ah, ds:[si]		; get last byte
	inc	si			; advance ptr
	shr	ah, cl			; shift bits
	or	ah, bl			; get extra bits, if any
PBSM_rMask equ (this byte) + 1
	mov	bh, 03h			; SELF MODIFIED and-immediate
	and	bh, dh			; apply user-spec draw mask
	and	bh, ch			; apply overflow mask bits
	xchg	ah, ch			; save current bitmap data
PBSM_mask3 equ (this word) + 2
	mov	al, ds:[si][1234h]	; apply mask stored with bitmap
	mov	ah, 0xff		; init overflow bits
	ror	ax, cl			; rotate mask data
	xchg	ah, ch			; save old, restore data
	and	bh, al			; apply new mask bits
	and	ah, bh
	call	ss:[mixRoutine]		; get screen data, mix new data, write
;	mov	al, es:[di]		; get screen data
;	not	bh
;	and	al, bh
;	not	bh
;	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
;	or	al, bh			; clear out bits we don't need
;	call	ss:[modeRoutine]	; combine bits
;	stosb				; write the byte		
	.leave
		ret
PutBWScanMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSetBitmapByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by BW bitmap drawing routines

CALLED BY:	INTERNAL
		PutBWScan, PutBWScanMask
PASS:		bh	- net mask 
		es:di	- frame buffer pointer
RETURN:		al	- screen content, appropriately masked
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSetBitmapByte	proc	near
RW <		xornf di, 1						>
		mov	al, es:[di]		; get screen data
RW <		xornf di, 1						>
		not	bh
		and	al, bh
		not	bh
		and	bh, {byte} ss:[resetColor] ; figure which bits to save
		or	al, bh			; clear out bits we don't need
		call	ss:[modeRoutine]	; combine bits
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb				; write the byte
endif
		ret
GetSetBitmapByte	endp

GetMixBitmapByte	proc	near
RW <		xornf di, 1						>
		mov	al, es:[di]		; get screen data
RW <		xornf di, 1						>
		call	ss:[modeRoutine]	; combine bits
ifdef	REVERSE_WORD
		call	DoStosbFar
else
		stosb				; write the byte
endif
		ret
GetMixBitmapByte	endp
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
		add	ax, 7			; round up
		mov	cl, 3			; divide by eight for index
		shr	bx, cl
		shr	ax, cl
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
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get first byte
endif
		rol	ax, cl			; do the shift
		mov	bl, al			; save initial bits
INVRSE <	call	CheckInverseMode				>
INVRSE <	jnz	slowLoopInverse					>

		; do the read/shift work, invert (maybe), write result 
slowLoop:
		clr	ah			; clear out initial shift-in
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get next source byte
endif
		rol	ax, cl			; do the shift
		xchg	bl, al			; get old shift-in byte
		or	al, ah			; combine bits
NMEM <		not	al			; white=1 in frame buf	>
		stosb				; save in temp buffer
		dec	ch			; keep going till middle done
		jnz	slowLoop

		; all done, restore count and leave
done:
		pop	cx			; restore #bytes left
		ret

;----------------------------------------------------------------------------

		; no room left, set #bytes left in buffer to -1 and quit
GOS_noRoom:
		mov	cx, -1			; set result
		ret

		; since we don't need to do the shift, we can copy
		; the byte very quickly
fast:
		mov	cl, ch			; make cx=#bytes
		clr	ch
INVRSE <	call	CheckInverseMode				>
INVRSE <	jnz	fastInverse					>
NMEM <fastLoop:								>
ifdef	REVERSE_WORD
NMEM <		call	DoLodsbFar					>
else
NMEM <		lodsb							>
endif
NMEM <		not	al			; white=1 in frame buf	>
NMEM <		stosb							>
NMEM <		loop	fastLoop					>
MEM <		rep	movsb						>
		jmp	done

		; Note that there is no such thing as an inverted
		; memory driver, so we can easily exclude some code

ifdef	INVERSE_DRIVER
		; do the read/shift work, don't invert, write result 
slowLoopInverse:
		clr	ah			; clear out initial shift-in
ifdef	REVERSE_WORD
		call	DoLodsbFar
else
		lodsb				; get next source byte
endif
		rol	ax, cl			; do the shift
		xchg	bl, al			; get old shift-in byte
		or	al, ah			; combine bits
		stosb				; save in temp buffer
		dec	ch			; keep going till middle done
		jnz	slowLoopInverse
		jmp	done

		; we don't need to do the shift, but we do need to
		; invert each byte
fastInverse:					; deal with inverse
ifdef	REVERSE_WORD
		call	DoRepMovsb
else
		rep	movsb
endif
		jmp	done
endif
GetOneScan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckInverseMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if we are in inverse video mode

CALLED BY:	GetOneScan()

PASS:		Nothing

RETURN:		Z	= 1 if in NORMAL mode
			= 0 if in INVERSE mode

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/ 7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	INVERSE_DRIVER
CheckInverseMode	proc	near
		uses	ax, ds
		.enter

		segmov	ds, dgroup, ax
		tst	ds:[inverseDriver]

		.leave
		ret
CheckInverseMode	endp
endif

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
		dl = pattern
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
	not	ah		;
	and	ah, byte ptr ss:[resetColor]
	or	al, ah		; 
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
ByteINV	label	near		; screenXOR(mask) 
MEM <	not	ah		; reverse polarity			>
MEM <	and	ah, bh							>
	xor	al, ah
	ret
if (0)
ByteXOR	label	near		; screenXOR(data^mask^pattern)
INVRSE <tst	ss:[inverseDriver]					>
INVRSE <jz	notInverse						>
INVRSE <not	dl							>
INVRSE <and	ah, dl							>
INVRSE <not	dl							>
INVRSE <xor	al, ah							>
INVRSE <ret								>
INVRSE <notInverse:							>
	and	ah, dl
	xor	al, ah
	ret
endif
ByteSET	label	near		; (screen^~(data^mask))v(data^mask^setColor)
	not	ah		;
	and	al, ah		;
	not	ah		;
	and	ah, byte ptr ss:[setColor]
;;;	or	al, dl
;;;	ret
ByteOR	label	near		; screenv(data^mask^pattern) 
	and	ah, dl
	or	al, ah
	ret
ByteModeRoutines	endp


ByteModeRout	label	 word
	nptr	ByteCLEAR
	nptr	ByteCOPY
	nptr	ByteNOP
	nptr	ByteAND
	nptr	ByteINV
	nptr	ByteINV			; map XOR to INV for bitmaps
	nptr	ByteSET
	nptr	ByteOR

	; we need to do different things to the frame buffer contents, 
	; depending on if the mix mode involves the frame buffer bits or not.
ifdef	IS_MONO
ByteMixRout	label	 word
	nptr	GetSetBitmapByte
	nptr	GetSetBitmapByte
	nptr	GetMixBitmapByte
	nptr	GetMixBitmapByte
	nptr	GetMixBitmapByte
	nptr	GetMixBitmapByte
	nptr	GetSetBitmapByte
	nptr	GetMixBitmapByte
endif
VidEnds		Bitmap
