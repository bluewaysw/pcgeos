COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		VidMem/Clr2
FILE:		clr2Raster.asm

AUTHOR:		Joon Song, Oct 7, 1996

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/7/96   	Initial revision


DESCRIPTION:
	Low-level raster drawing routines for 2-bit/pixel vidmem

	$Id: clr2Raster.asm,v 1.1 97/04/18 11:43:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Blt

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BltSimpleLine	proc		near
		push	ds			; save window seg
NMEM <		segmov	ds, es			; set both -> screen	>
MEM  <		mov	ds, ss:[bm_lastSegSrc]	; get source segment	>

		mov	ax, ss:[bmRight]	; ax = right pixel position
		mov	bx, ss:[bmLeft]		; bx = left pixel position

		; calculate masks, and save shift amount, other good things

		mov	dx, ax		 	; dx = right pixel position
		shr	dx, 3			; pixel -> word
		mov	ch, dl			; ch = right word
		mov	dx, bx			; dx = left pixel position
		shr	dx, 3			; pixel -> word
		sub	ch, dl			; ch = # words to write

		mov	dx, bx			; dx = left pixel position
		mov	ah, dl			; save the low byte for later
		sub	dx, ss:[d_x1]		; dx = index into blt dest
		add	dx, ss:[d_x1src]	; dx = left side of source
		mov	al, dl			; calculate shift value
		and	ax, 0707h		; if no shift, result == 0
		sub	ah, al			; ah = # pixels shift
		mov	cl, ah			; cl = shift amount, ch= #words
		sal	cl, 1			; cl = shift amount (2/pixel)

		; calculate byte indices into scan line, both source and dest

		mov	ax, ss:[bmRight] 	; ax = right pixel position
		mov	dx, bx			; dx = left pixel position
		shr	ax, 3			; ax = right pixel word index
		shl	ax, 1			; ax = word aligned byte index
		shr	dx, 3			; dx = left pixel word index
		shl	dx, 1			; dx = word aligned byte index
		add	di, dx			; byte index for destination
		sub	bx, ss:[d_x1]		; bx = #pix index into dest blt
		add	bx, ss:[d_x1src] 	; bx = source left side
		shr	bx, 3			; bx = source left word index
		shl	bx, 1			; bx = source left byte index
		add	si, bx

		; check to see if we need to shift anything, use diff routine

		tst	cl			; check shift amount
		je	BSL_wordmove
		jmp	BltShift		;  shift, use slower routine

BSL_wordmove:
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

		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[leftMaskTable][bx]

		lodsw
		and	ax, bx			; apply mask
		mov	dx, es:[di]		; get destination
		not	bx
		and	dx, bx
		or	ax, dx
		stosw
		dec	cx			; see if done
		je	BSL_doright

		; copy middle words

		rep	movsw

		; handle right word specially
BSL_doright:
		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[rightMaskTable][bx]

		lodsw
		and	ax, bx			; apply right mask
		mov	dx, es:[di]		; get destination
		not	bx
		and	dx, bx			; apply reverse mask
		or	ax, dx
		stosw
BSL_last:
		pop	ds			; restore ds
		ret

		; special case: copy line right to left
BSL_RightToLeft:
		; shift pointers to start at right side
		add	si, cx			; add to source and dest
		add	si, cx			; add to source and dest
		add	di, cx
		add	di, cx
		std				; go backwards

		; mask right word

		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[rightMaskTable][bx]

		lodsw
		and	ax, bx			; do right side
		mov	dx, es:[di]		; get destination
		not	bx			; reverse mask
		and	dx, bx			; save bits from dest
		or	ax, dx
		stosw
		dec	cx
		je	BSL_rldoleft

		; draw middle words

		rep	movsw

		; mask left word
BSL_rldoleft:
		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[leftMaskTable][bx]

		lodsw
		and	ax, bx			; apply left mask
		mov	dx, es:[di]		; get destination
		not	bx
		and	dx, bx			; apply reverse mask
		or	ax, dx
		stosw
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
		cx	- counts (ch=word count, cl=bit shift count)

RETURN:		nothing
		jumped to by BltShift, so this returns to BltSimpleLine's caller

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		read/shift/write the words;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BltShift	proc		near

		; if source and dest on same scan line, use different rout

		push	bp
		mov	ax, ss:[d_y1]	; get one y value
		cmp	ax, ss:[d_y2]	; check against other
		jne	BS_normal	; normal case

		mov	ax, ss:[d_x1src]; use slow routine if copying to right
		cmp	ax, ss:[d_x1]
		jge	BS_normal
		jmp	BltShiftHoriz	; blting horizontally

		;   read/shift/write the bits to buffer
BS_normal:
		tst	cl		; if shift left, do separate
		js	BS_shiftLeft	; do left shifting

		; test for single word write, need to combine masks

		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		mov	dx, ss:[leftMaskTable][bx]

		tst	ch		; check # words to write
		jz	BS_srDoRight	; writing only one

		; shifting right, do left side word (and mask it)
BS_srLeft::
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bp		; clear shift out bits
		shld_bp_ax_cl		; bp = shift out bits
		shl	ax, cl		; do the shift
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply left mask
		mov	bx, es:[di]	; get destination word		
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
		dec	ch		; one less word to write
		jz	BS_srRight	; if no middle words, do right side

		; do the middle words
BS_smallLoop:
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		mov	bx, bp		; bx = previous shift out bits
		clr	bp		; clear shift out bits
		shld_bp_ax_cl		; bp = new shift out bits
		shl	ax, cl		; do shift
		or	ax, bx		; combine with previous shift out bits
		xchg	al, ah		; little-endian <-> big-endian
		stosw			; save in temp buffer
		dec	ch		; keep going till middle done
		jne	BS_smallLoop
BS_srRight:
		mov	dx, 0xffff	; no left side mask

		; do the right side
BS_srDoRight:
		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		and	dx, ss:[rightMaskTable][bx]	; combine lt/rt masks

		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		shl	ax, cl		; do shift
		or	ax, bp		; combine with previous shift out bits
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply right mask
		mov	bx, es:[di]	; get destination word
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
			
		; all done, cleanup and exit
BS_done:
		pop	bp
		pop	ds		; restore data seg
		ret			; returns to BltSimpleLine's caller

;---------------------------------------------------------------------

		; special case: need to shift left
		; check for need to preload the first value (more src than dest)
BS_shiftLeft:
		neg	cl		; make shift positive
		lodsw			; get first source word
		xchg	al, ah		; little-endian <-> big-endian
		shr	ax, cl		; do shift
		mov	bp, ax		; bp = previous word shifted

		; test for single word write, need to combine masks

		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		mov	dx, ss:[leftMaskTable][bx]

		tst	ch		; check # words to write
		jz	BS_slDoRight	; writing only one

		; shifting left, do left side word (and mask it)
BS_slLeft::
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bx		; no shift out bits
		shrd_bx_ax_cl		; bx = shift out bits
		shr	ax, cl		; do shift
		or	bp, bx		; combine with previous shift out bits
		xchg	bp, ax		; bp = previous word shifted
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply left mask
		mov	bx, es:[di]	; get destination word
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
		dec	ch		; one less word to write
		jz	BS_slRight	; if no middle words, do right side

		; do the middle words

BSL_smallLoop:
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bx		; no shift out bits
		shrd_bx_ax_cl		; bx = shift out bits
		shr	ax, cl		; do shift
		or	bp, bx		; combine with previous shift out bits
		xchg	bp, ax		; bp = previous word shifted
		xchg	al, ah		; little-endian <-> big-endian
		stosw			; save in temp buffer
		dec	ch		; keep going till middle done
		jne	BSL_smallLoop
BS_slRight:
		mov	dx, 0xffff	; no left side mask

		; do the right side
BS_slDoRight:
		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		and	dx, ss:[rightMaskTable][bx]	; combine lt/rt masks

		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bx		; no shift out bits
		shrd_bx_ax_cl		; bx = shift out bits
		or	bp, bx		; combine with previous shift out bits
		xchg	bp, ax		; bp = previous word shifted
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply right mask
		mov	bx, es:[di]	; get destination word
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
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

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	04/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BltShiftHoriz	proc		near
		std			; move data backwards

		; shift pointers to start at right side

		clr	ah
		mov	al, ch		; ax = number of words to move
		shl	ax, 1		; ax = number of bytes to move
		add	si, ax
		add	di, ax

		tst	cl		; if shift left, do separate
		js	BSH_shiftLeft	; do left shifting

		; test for single word write, need to combine masks

		lodsw			; get first source word
		xchg	al, ah		; little-endian <-> big-endian
		shl	ax, cl		; do shift
		mov	bp, ax		; bp = previous word shifted

		; test for single word write, need to combine masks

		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		mov	dx, ss:[rightMaskTable][bx]

		tst	ch		; check # words to write
		jz	BSH_slDoLeft	; writing only one

		; shifting left, do right side word (and mask it)
BSH_slRight::
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bx		; no shift out bits
		shld_bx_ax_cl		; bx = shift out bits
		shl	ax, cl		; do shift
		or	bp, bx		; combine with previous shift out bits
		xchg	bp, ax		; bp = previous word shifted
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply left mask
		mov	bx, es:[di]	; get destination word
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
		dec	ch		; one less word to write
		jz	BSH_slLeft	; if no middle words, do left side

		; do the middle word
BSL_smallLoop:
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bx		; no shift out bits
		shld_bx_ax_cl		; bx = shift out bits
		shl	ax, cl		; do shift
		or	bp, bx		; combine with previous shift out bits
		xchg	bp, ax		; bp = previous word shifted
		xchg	al, ah		; little-endian <-> big-endian
		stosw			; save in temp buffer
		dec	ch		; keep going till middle done
		jne	BSL_smallLoop
BSH_slLeft:
		mov	dx, 0xffff	; no left side mask

		; do the left side
BSH_slDoLeft:
		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		and	dx, ss:[leftMaskTable][bx]	; combine lt/rt masks

		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bx		; no shift out bits
		shld_bx_ax_cl		; bx = shift out bits
		or	bp, bx		; combine with previous shift out bits
		xchg	bp, ax		; bp = previous word shifted
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply right mask
		mov	bx, es:[di]	; get destination word
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
			
		; all done, cleanup and exit
BSH_done:
		cld			; clear direction
		pop	bp
		pop	ds		; restore data seg
		ret			; returns to BltSimpleLine's caller

;---------------------------------------------------------------------

		; special case: need to shift left
BSH_shiftLeft:
		neg	cl		; make shift positive

		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		mov	dx, ss:[rightMaskTable][bx]

		tst	ch		; check # words to write
		jz	BSH_srDoLeft	; writing only one

		; shifting right, do right side word (and mask it)
BSH_srRight::
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		clr	bp		; clear shift out bits
		shrd_bp_ax_cl		; bp = shift out bits
		shr	ax, cl		; do the shift
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply left mask
		mov	bx, es:[di]	; get destination word		
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
		dec	ch		; one less word to write
		jz	BSH_srLeft	; if no middle words, do left side

		; do the middle words
BSH_smallLoop:
		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		mov	bx, bp		; bx = previous shift out bits
		clr	bp		; clear shift out bits
		shrd_bp_ax_cl		; bp = new shift out bits
		shr	ax, cl		; do shift
		or	ax, bx		; combine with previous shift out bits
		xchg	al, ah		; little-endian <-> big-endian
		stosw			; save in temp buffer
		dec	ch		; keep going till middle done
		jne	BSH_smallLoop
BSH_srLeft:
		mov	dx, 0xffff	; no left side mask

		; do the left side
BSH_srDoLeft:
		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		and	dx, ss:[leftMaskTable][bx]	; combine lt/rt masks

		lodsw			; get next source word
		xchg	al, ah		; little-endian <-> big-endian
		shr	ax, cl		; do shift
		or	ax, bp		; combine with previous shift out bits
		xchg	al, ah		; little-endian <-> big-endian
		and	ax, dx		; apply right mask
		mov	bx, es:[di]	; get destination word
		not	dx		; create negative image mask
		and	bx, dx		; apply mask to existing bits
		or	ax, bx		; combine parts
		stosw			; write out the word
		jmp	BSH_done	; continue with copy to screen
		
BltShiftHoriz	endp

VidEnds		Blt


VidSegment	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

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
	sar	ax, 3			; want to get byte index
	sar	bp, 3			; want to get byte index
	sar	bx, 3			; bx = word index
	sal	bx, 1			; bx = word aligned byte index
	add	si, bp			; add bytes-to-left-side to indices
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sar	bx, 1
	sub	bp, bx			; bp = # dest bytes to write
	mov	dx, ss:ditherScan	; dx = line's dither pattern

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
	jnz	FBS_left		; more than one, don't combine masks
	mov	ah, bl			; only one, combine masks
	and	ah, bh
	mov	cs:[FBS_rMask], ah	; store SELF MODIFIED and-immediate
	mov	bl, ch			; get initial shift out bits
	jmp	short FBS_right
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

;
;       NOTE - this routine *only* modifies the output buffer at
;              positions that correspond to set pixels (1 bits) in
;              AL. It does nothing for pixels that are 0. If you want
;              to set the output buffer for both set *and* cleared
;              bits in AL, use CopyBitmapByte below
;
;	Pass:  al - bitmap data to write out
;	       dx - dither pattern
;	       bh - any associated mask	
;
WriteBitmapByte	proc	near
	and	al, bh			; nuke any bits not in the mask
	call	BuildDataByteFar	; expand byte into buffer
	test	bh, 0x0f		; if mask zeroes, skip write	
	jz	byte2
	mov	ah, {byte} ss:[dataBuff2]
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
byte2:
	inc	di
	test	bh, 0xf0		; check out next two
	jz	done
	mov	ah, {byte} ss:[dataBuff2+1]
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
done:
	inc	di
	ret
WriteBitmapByte	endp

;
;	NOTE - this routine will modify the output buffer (screen) based on
;	       both the set *and* clear pixels in AL
;
;	Pass:		al - bitmap data to write out (treated as "dither pattern")
;			bh - any associated mask (treated as "new bits AND mask")
;			es:di - frame buffer position for new pixels
;
;	Return:		di - advanced past new pixels
;	Destroyed:	ax, bx, dx
;
CopyBitmapByte	proc	near
	call	BuildDataByteFar	; expand byte into buffer
	call	BuildDataMaskFar
	test	bh, 0x0f		; if mask zeroes, skip write	
	jz	byte2
	mov	dl, {byte} ss:[dataBuff2]
	mov	ah, {byte} ss:[dataMask2]		
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
byte2:
	inc	di
	test	bh, 0xf0		; check out next two
	jz	done
	mov	dl, {byte} ss:[dataBuff2+1]
	mov	ah, {byte} ss:[dataMask2+1]
	mov	al, es:[di]		; al = screen data
	call	ss:[modeRoutine]					   
	mov	es:[di], al		; write byte
done:
	inc	di
	ret
CopyBitmapByte	endp


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
	sar	ax, 3			; want to get byte index
	sar	bp, 3			; want to get byte index
	sar	bx, 3			; bx = word index
	sal	bx, 1			; bx = word aligned byte index
	add	si, bp			; add bytes-to-left-side to indices
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sar	bx, 1
	sub	bp, bx			; bp = # dest bytes to write

	;              
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
	call	CopyBitmapByte
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
	call	CopyBitmapByte
	dec	bp			; one less to do
	jg	PBS_center		; loop to do next byte of bitmap

PBS_right:
	mov	al, ds:[si]		; get last byte
	shr	al, cl			; shift bits
	or	al, bl			; get extra bits, if any
PBS_rMask equ (this byte) + 1
	mov	bh, 03h			; SELF MODIFIED and-immediate
	and	al, ss:lineMask		; apply user-spec draw mask
	call	CopyBitmapByte

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
	sar	ax, 3			; want to get byte indices
	sar	bx, 2
	sar	bp, 3
	add	si, bp			; add bytes-to-left-side to indices
	and 	bx, 0xfffe		; clear low 2
	add	di, bx			; add to screen offset too
	mov	bp, ax			; get right side in bp
	sar	bx, 1
	sub	bp, bx			; bp = # dest bytes to write
	mov	dx, 0xffff		; set the pixels to black (ffff)
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
bitmapLeftMask	local	word
bitmapRightMask	local	word
bitmapMask	local	word
		.enter

		; calculate # word to fill in

		mov	ax, ss:[bmRight]	; ax = right side
		mov	bx, ss:[bmLeft]		; bx = left side
		mov	cx, bx			; cx = left side
		and	cx, 0xfff8		; cx = left side word aligned
		sub	cx, ss:[d_x1]		; cx = pixel index into bitmap
		sar	cx, 1			; cx = byte index into bitmap
		add	si, cx			; add to bitmap offset
		sar	ax, 3			; ax = word index of right pix
		sar	bx, 3			; bx = word index of left pix
		mov	cx, ax			; cx = right side
		sub	cx, bx			; cx = # dest words to write
		sal	bx, 1			; bx = word aligned byte offset
		add	di, bx			; add to screen offset

		; setup left and right masks

		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[leftMaskTable][bx]
		mov	ss:[bitmapLeftMask], bx

		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[rightMaskTable][bx]
		mov	ss:[bitmapRightMask], bx

		; setup bitmap mask

		clr	bx
		mov	bl, ss:[lineMask]
		and	bl, 0x0f
		mov	al, cs:[ColorMaskTable][bx]
		mov	bl, ss:[lineMask]
		shr	bl, 4
		mov	ah, cs:[ColorMaskTable][bx]
		mov	ss:[bitmapMask], ax

		; set bh = 0 for MapBitmapColor macro

		clr	bx

		; check for a palette

		test	ss:[bmType], mask BMT_PALETTE
		LONG jnz handlePalette

		; OK, we're ready to roll.  If there is no shifting, then we
		; can copy them!

		test	ss:[bmShift], 1		; check low bit for shift
		LONG jnz moveShift		;  rats, have to do it hard way

		; we're all setup.  Just convert 4-bit colors to 2-bit colors
		; and copy the bytes.  Do the left and right specially, though.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	cx
		LONG jz	loadRight		; if only one word to do...

		lodsw				; get 1st left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		andnf	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	cx
		jz	doRight
colorLoop:
		lodsw
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		loop	colorLoop
doRight:
		mov	ax, 0xffff		; so we can use common code
loadRight:
		and	ss:[bitmapRightMask], ax	; deal with right side

		lodsw				; get 1st left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		andnf	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret

moveShift:
		; if there is shifting to do, then things are a little harder.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	cx
		LONG jz	loadRight2		; if only one word to do...

		lodsw				; get 1st left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]
		shr	dl, 4
		or	al, dl
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al

		lodsw				; get 2nd left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		andnf	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	cx
		jz	doRight2
colorLoop2:
		lodsw
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		loop	colorLoop2
doRight2:
		mov	ax, 0xffff		; so we can use common code
loadRight2:
		and	ss:[bitmapRightMask], ax	; deal with right side

		lodsw				; get 1st left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		and	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret

handlePalette:
		; there is a palette for this bitmap, so we must map
		; the entries to the palette before writing them out

		test	ss:[bmShift], 1		; check low bit for shift
		LONG jnz paletteMoveShift	;  rats, have to do it hard way

		; we're all setup.  Just convert 4-bit colors to 2-bit colors
		; and copy the bytes.  Do the left and right specially, though.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	cx
		LONG jz	paletteLoadRight	; if only one word to do...

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		andnf	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	cx
		jz	paletteDoRight
paletteColorLoop:
		lodsw				; get 1st middle word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd middle word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		loop	paletteColorLoop
paletteDoRight:
		mov	ax, 0xffff		; so we can use common code
paletteLoadRight:
		and	ss:[bitmapRightMask], ax	; deal with right side

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		andnf	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret

paletteMoveShift:
		; if there is shifting to do, then things are a little harder.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	cx
		LONG jz	paletteLoadRight2	; if only one word to do...

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al

		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		andnf	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	cx
		jz	paletteDoRight2
paletteColorLoop2:
		lodsw				; get 1st middle word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd middle word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		loop	paletteColorLoop2
paletteDoRight2:
		mov	ax, 0xffff		; so we can use common code
paletteLoadRight2:
		and	ss:[bitmapRightMask], ax	; deal with right side

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		andnf	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		andnf	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret
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
PutColorScanMask	proc	near
bitmapShiftCount local	byte
bitmapLeftMask	local	word
bitmapRightMask	local	word
bitmapMask	local	word
wordCount	local	word
maskPtr		local	word
		.enter

		; calculate # word to fill in

		mov	ax, ss:[bmRight]	; ax = right side
		mov	bx, ss:[bmLeft]		; bx = left side
		mov	cx, bx			; cx = left side
		and	cx, 0xfff8		; cx = left side word aligned
		sub	cx, ss:[d_x1]		; cx = pixel index into bitmap
		mov	dx, cx			; dx = pixel index into bitmap
		and	dl, 7			; dl = shift count
		mov	ss:[bitmapShiftCount], dl ; save shift count
		mov	dx, si			; dx = start of bitmap data
		sar	cx, 1			; cx = byte index into bitmap
		add	si, cx			; add to bitmap offset
		sar	cx, 2			; cx = bit index into mask
		sub	dx, ss:[bmMaskSize]	; dx = start of mask data
		add	dx, cx			; add to mask offset
		mov	ss:[maskPtr], dx	; save mask ptr
		sar	ax, 3			; ax = word index of right pix
		sar	bx, 3			; bx = word index of left pix
		mov	cx, ax			; cx = right side
		sub	cx, bx			; cx = # dest words to write
		mov	ss:[wordCount], cx	; save word count
		sal	bx, 1			; bx = word aligned byte offset
		add	di, bx			; add to screen offset

		; setup left and right masks

		mov	bx, ss:[bmLeft]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[leftMaskTable][bx]
		mov	ss:[bitmapLeftMask], bx

		mov	bx, ss:[bmRight]
		and	bx, 0x07
		shl	bx, 1
		mov	bx, ss:[rightMaskTable][bx]
		mov	ss:[bitmapRightMask], bx

		; check for a palette

		test	ss:[bmType], mask BMT_PALETTE
		LONG jnz handlePalette

		; OK, we're ready to roll.  If there is no shifting, then we
		; can copy them!

		test	ss:[bmShift], 1		; check low bit for shift
		LONG jnz moveShift		;  rats, have to do it hard way

		; we're all setup.  Just convert 4-bit colors to 2-bit colors
		; and copy the bytes.  Do the left and right specially, though.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	ss:[wordCount]
		LONG jz	loadRight		; if only one word to do...

		call	SetBitmapMask
		and	ss:[bitmapLeftMask], ax

		lodsw				; get 1st left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	ss:[wordCount]
		jz	doRight
colorLoop:
		call	SetBitmapMask

		lodsw
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		dec	ss:[wordCount]
		jnz	colorLoop
doRight:
		mov	ax, 0xffff		; so we can use common code
loadRight:
		and	ss:[bitmapRightMask], ax	; deal with right side

		call	SetBitmapMask
		and	ss:[bitmapRightMask], ax

		lodsw				; get 1st left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret

moveShift:
		; if there is shifting to do, then things are a little harder.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	cx
		LONG jz	loadRight2		; if only one word to do...

		call	SetBitmapMask
		and	ss:[bitmapLeftMask], ax

		lodsw				; get 1st left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]
		shr	dl, 4
		or	al, dl
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al

		lodsw				; get 2nd left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	ss:[wordCount]
		jz	doRight2
colorLoop2:
		call	SetBitmapMask

		lodsw
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		dec	ss:[wordCount]
		jnz	colorLoop2
doRight2:
		mov	ax, 0xffff		; so we can use common code
loadRight2:
		and	ss:[bitmapRightMask], ax	; deal with right side

		call	SetBitmapMask
		and	ss:[bitmapRightMask], ax

		lodsw				; get 1st left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		xchg	al, ah
		MapBitmapColor			; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret

handlePalette:
		; there is a palette for this bitmap, so we must map
		; the entries to the palette before writing them out

		test	ss:[bmShift], 1		; check low bit for shift
		LONG jnz paletteMoveShift	;  rats, have to do it hard way

		; we're all setup.  Just convert 4-bit colors to 2-bit colors
		; and copy the bytes.  Do the left and right specially, though.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	cx
		LONG jz	paletteLoadRight	; if only one word to do...

		call	SetBitmapMask
		and	ss:[bitmapLeftMask], ax

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	ss:[wordCount]
		jz	paletteDoRight
paletteColorLoop:
		call	SetBitmapMask

		lodsw				; get 1st middle word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd middle word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		dec	ss:[wordCount]
		jnz	paletteColorLoop
paletteDoRight:
		mov	ax, 0xffff		; so we can use common code
paletteLoadRight:
		and	ss:[bitmapRightMask], ax	; deal with right side

		call	SetBitmapMask
		and	ss:[bitmapRightMask], ax

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret

paletteMoveShift:
		; if there is shifting to do, then things are a little harder.

		mov	ax, ss:[bitmapLeftMask]	; get left mask setup
		tst	cx
		LONG jz	paletteLoadRight2	; if only one word to do...

		call	SetBitmapMask
		and	ss:[bitmapLeftMask], ax

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al

		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapLeftMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		dec	ss:[wordCount]
		jz	paletteDoRight2
paletteColorLoop2:
		call	SetBitmapMask

		lodsw				; get 1st middle word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd middle word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw
		dec	ss:[wordCount]
		jnz	paletteColorLoop2
paletteDoRight2:
		mov	ax, 0xffff		; so we can use common code
paletteLoadRight2:
		and	ss:[bitmapRightMask], ax	; deal with right side

		call	SetBitmapMask
		and	ss:[bitmapRightMask], ax

		lodsw				; get 1st left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].high
		mov	al, es:[di+1]
		call	ss:[modeRoutine]
		mov	dh, al
		lodsw				; get 2nd left word
		xchg	al, ah			; byte-swap
		shl	ax, 4			; remove high nibble
		mov	dl, ds:[si]		; get next byte
		shr	dl, 4			; move to low nibble
		or	al, dl			; or in low nibble
		MapPaletteBitmapColor		; ax -> dl : 4-bit -> 2-bit
		mov	ah, ss:[bitmapRightMask].low
		mov	al, es:[di]
		call	ss:[modeRoutine]
		mov	ah, dh
		stosw

		.leave
		ret
PutColorScanMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBitmapMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift 1-bit mask so we can do word aligned writes to
		video memory and then convert to a 2-bit mask.

CALLED BY:	PutColorScanMask
PASS:		stack frame
RETURN:		ax = bitmap mask
		bh = 0
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	10/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBitmapMask	proc	near
	.enter	inherit PutColorScanMask

	mov	bx, ss:[maskPtr]
	mov	ax, ds:[bx]
	inc	bx
	mov	ss:[maskPtr], bx
	xchg	al, ah
	mov	cl, ss:[bitmapShiftCount]
	shl	ax, cl
	andnf	ah, ss:[lineMask]
	clr	bx
	mov	bl, ah
	and	bl, 0x0f
	mov	al, cs:[ColorMaskTable][bx]
	mov	bl, ah
	shr	bl, 4
	mov	ah, cs:[ColorMaskTable][bx]
	mov	ss:[bitmapMask], ax

	.leave
	ret
SetBitmapMask	endp

ColorMaskTable		byte	\
	00000000b, 11000000b, 00110000b, 11110000b,
	00001100b, 11001100b, 00111100b, 11111100b,
	00000011b, 11000011b, 00110011b, 11110011b,
	00001111b, 11001111b, 00111111b, 11111111b

ifidn PRODUCT,<RESPONDER>
ColorConversionTable	byte	\
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b,
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0000b, 0000b, 0100b, 0100b, 1000b, 1000b, 1100b, 1100b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0001b, 0001b, 0101b, 0101b, 1001b, 1001b, 1101b, 1101b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0010b, 0010b, 0110b, 0110b, 1010b, 1010b, 1110b, 1110b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b,
        0011b, 0011b, 0111b, 0111b, 1011b, 1011b, 1111b, 1111b
                
else ; RESPONDER
ColorConversionTable	byte	\
	1111b, 1011b, 1011b, 1011b, 1011b, 1011b, 1011b, 0111b,
	1011b, 0111b, 0111b, 0111b, 0111b, 0111b, 0111b, 0011b,
	1110b, 1010b, 1010b, 1010b, 1010b, 1010b, 1010b, 0110b,
	1010b, 0110b, 0110b, 0110b, 0110b, 0110b, 0110b, 0010b,
	1110b, 1010b, 1010b, 1010b, 1010b, 1010b, 1010b, 0110b,
	1010b, 0110b, 0110b, 0110b, 0110b, 0110b, 0110b, 0010b,
	1110b, 1010b, 1010b, 1010b, 1010b, 1010b, 1010b, 0110b,
	1010b, 0110b, 0110b, 0110b, 0110b, 0110b, 0110b, 0010b,
	1110b, 1010b, 1010b, 1010b, 1010b, 1010b, 1010b, 0110b,
	1010b, 0110b, 0110b, 0110b, 0110b, 0110b, 0110b, 0010b,
	1110b, 1010b, 1010b, 1010b, 1010b, 1010b, 1010b, 0110b,
	1010b, 0110b, 0110b, 0110b, 0110b, 0110b, 0110b, 0010b,
	1110b, 1010b, 1010b, 1010b, 1010b, 1010b, 1010b, 0110b,
	1010b, 0110b, 0110b, 0110b, 0110b, 0110b, 0110b, 0010b,
	1101b, 1001b, 1001b, 1001b, 1001b, 1001b, 1001b, 0101b,
	1001b, 0101b, 0101b, 0101b, 0101b, 0101b, 0101b, 0001b,

	1110b, 1010b, 1010b, 1010b, 1010b, 1010b, 1010b, 0110b,
	1010b, 0110b, 0110b, 0110b, 0110b, 0110b, 0110b, 0010b,
	1101b, 1001b, 1001b, 1001b, 1001b, 1001b, 1001b, 0101b,
	1001b, 0101b, 0101b, 0101b, 0101b, 0101b, 0101b, 0001b,
	1101b, 1001b, 1001b, 1001b, 1001b, 1001b, 1001b, 0101b,
	1001b, 0101b, 0101b, 0101b, 0101b, 0101b, 0101b, 0001b,
	1101b, 1001b, 1001b, 1001b, 1001b, 1001b, 1001b, 0101b,
	1001b, 0101b, 0101b, 0101b, 0101b, 0101b, 0101b, 0001b,
	1101b, 1001b, 1001b, 1001b, 1001b, 1001b, 1001b, 0101b,
	1001b, 0101b, 0101b, 0101b, 0101b, 0101b, 0101b, 0001b,
	1101b, 1001b, 1001b, 1001b, 1001b, 1001b, 1001b, 0101b,
	1001b, 0101b, 0101b, 0101b, 0101b, 0101b, 0101b, 0001b,
	1101b, 1001b, 1001b, 1001b, 1001b, 1001b, 1001b, 0101b,
	1001b, 0101b, 0101b, 0101b, 0101b, 0101b, 0101b, 0001b,
	1100b, 1000b, 1000b, 1000b, 1000b, 1000b, 1000b, 0100b,
	1000b, 0100b, 0100b, 0100b, 0100b, 0100b, 0100b, 0000b
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

		mov	bx, ss:[d_x1]		; get left side position
		shr	bx, 3			; get left side word position
		shl	bx, 1			; get word aligned byte positon
		add	si, bx			; ds:si -> left side of source
		mov	ax, ss:[d_dx]		; ax = width of transfer (pixs)
		inc	ax			; round up
		shr	ax, 1			; ax = bytes of transfer
		sub	cx, ax			; see if enough room to copy
		js	GOS_noRoom		;  nope, quit with error

		push	cx, bp			; save remaining count
		mov	cl, ss:[shiftCount]	; get bit shift (always left)
		shl	cl, 1			; 2 bits/pixel
		mov	bp, ax			; bp = bytes of transfer
		tst	bp
		jz	done

		; preload first word

		lodsw				; ax = first word
		xchg	al, ah			; little-endian <-> big-endian
		shr	ax, cl			; do shift
		mov	dx, ax			; dx = previous word shifted
GOS_loop:
		lodsw				; ax = next word
		xchg	al, ah			; little-endian <-> big-endian
		shrd_bx_ax_cl			; bx = shift out bits
		shr	ax, cl			; do shift
		or	dx, bx			; combine with prev word
		xchg	dx, ax			; dx = previous word shifted

		clr	bh
		mov	bl, al			; bx = first byte
		and	bl, 0x0f		; bx = first 2 pixels
		mov	bl, cs:[TwoToFourColorTable][bx]
		xchg	bl, al			; al = first 4-bit byte
		stosb
		dec	bp
		jz	done

		shr	bl, 4			; bx = second 2 pixels
		mov	al, cs:[TwoToFourColorTable][bx]
		stosb
		dec	bp
		jz	done

		mov	bl, ah
		and	bl, 0x0f		; bx = third 2 pixels
		mov	al, cs:[TwoToFourColorTable][bx]
		stosb
		dec	bp
		jz	done

		mov	bl, ah
		shr	bl, 4			; bx = last 2 pixels
		mov	al, cs:[TwoToFourColorTable][bx]
		stosb
		dec	bp
		jnz	GOS_loop

		; all done, restore count and leave
done:
		pop	cx, bp			; restore #bytes left
		ret

;----------------------------------------------------------------------------

		; no room left, set #bytes left in buffer to -1 and quit
GOS_noRoom:
		mov	cx, -1			; set result
		ret

GetOneScan	endp

TwoToFourColorTable	byte	\
	11111111b, 01111111b, 10001111b, 00001111b,
	11110111b, 01110111b, 10000111b, 00000111b,
	11111000b, 01111000b, 10001000b, 00001000b,
	11110000b, 01110000b, 10000000b, 00000000b

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
INV_CLR2 < not	al			>
	and	al, ah		;
INV_CLR2 < not	al			>
ByteNOP	label	near		;
	ret
ByteCOPY label	near		; (screen^~(data^mask))v(data^mask^pattern)
INV_CLR2 < not	al			>
	not	ah		;
	and	al, ah		;
	not	ah		;
	and	ah, dl		;
	or	al, ah		; 
INV_CLR2 < not	al			>
	ret
ByteAND	label	near		; screen^((data^mask^pattern)v~(data^mask))
INV_CLR2 < not	al			>
	not	ah		
	mov	cs:[BMR_saveMask], ah
	not	ah
	and	ah, dl
	or	ah, cs:[BMR_saveMask]
	and	al, ah
INV_CLR2 < not	al			>
	ret
ByteXOR	label	near		; screenXOR(data^mask^pattern)
	and	ah, dl
ByteINV	label	near		; screenXOR(data^mask) 
	xor	al, ah
	ret
ByteOR	label	near		; screenv(data^mask^pattern) 
	and	ah, dl
ByteSET	label	near		; (screen^~(data^mask))v(data^mask^setColor)
INV_CLR2 < not	al			>
	or	al, ah
INV_CLR2 < not	al			>
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
