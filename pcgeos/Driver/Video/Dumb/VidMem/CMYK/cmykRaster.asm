COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VidMem driver	
FILE:		cmykRaster.asm

AUTHOR:		Jim DeFrisco, Mar  2, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/ 2/92		Initial revision


DESCRIPTION:
	bitmap drawing functions for CMYK module of vidmem
		

	$Id: cmykRaster.asm,v 1.1 97/04/18 11:43:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKColorBitmapInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock down some resources, if bitmap is color

CALLED BY:	VidPutBits
PASS: 		bl	- BMType, shifted left once
RETURN:		nothing
DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; just a little macro to create named offsets to the 16 different
	; color cache entries (see cmykColorRaster.asm)
cacheOff = offset CMYKClrBitmap:colorCache
irpc	entry, <0123456789ABCDEF>
	CACHE_&entry = cacheOff
	cacheOff = cacheOff + (size ColorCacheEntry)
	ditherOff = offset CMYKClrBitmap:dither&entry
	DITHER_&entry = ditherOff
endm

CMYKColorBitmapInitFar	proc	far
		call	CMYKColorBitmapInit
		ret
CMYKColorBitmapInitFar	endp

CMYKColorBitmapInit	proc	near
		clr	ss:colorTransferSeg, ss:colorDitherSeg
		shr	bl, 1			; get format back in place
		test	bl, mask BMT_COMPLEX	; used for Fills
		jnz	done
		and	bl, mask BMT_FORMAT	; if mono, don't do anything
		cmp	bl, BMF_MONO
		jne	initColor
done:
		ret

		; bitmap is color.  Do some initialization
initColor:
		mov	bx, handle CMYKClrBitmap	; lock down code res
		call	MemLock
		mov	cs:[modifyCMYK4], ax
		mov	cs:[modifyCMYK8], ax
		mov	cs:[modifyCMYK24], ax
		mov	cs:[modifyCMYK4mask], ax
		mov	cs:[modifyCMYK8mask], ax
		mov	cs:[modifyCMYK24mask], ax
		push	ds
		mov	ds, ax
		assume	ds:CMYKClrBitmap
		mov	bl, ss:[currentDrawMode]	; get draw mode
		clr	bh
		shl	bx, 1
		mov	bx, ds:[CMYKModeRout][bx]
		mov	ss:[modeRoutine], bx
		mov	ds:[curCacheEntry], 0		; mark cache empty
		mov	ax, 0xffff
		; this creates 32 lines of code....
irpc		entry, <0123456789ABCDEF>
		mov	ds:[CACHE_&entry].CCE_usage, ax
		mov	ds:[CACHE_&entry].CCE_dither, DITHER_&entry
endm
		assume	ds:nothing
		pop	ds
		
		mov	bx, handle CMYKDither
		call	MemLock
		mov	ss:[colorDitherSeg], ax

		clr	ax				; assume no transfer
		mov	bx, ss:[colorTransfer]
		tst	bx
		jz	storeTransferSeg
		call	MemLock
storeTransferSeg:
		mov	ss:[colorTransferSeg], ax
		jmp	done



CMYKColorBitmapInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKColorBitmapCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the resources locked in CMYKColorBitmapInit

CALLED BY:	VidPutBits
PASS:		nothing
RETURN:		nothing
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMYKColorBitmapCleanupFar proc	far
		call	CMYKColorBitmapCleanup
		ret
CMYKColorBitmapCleanupFar endp

CMYKColorBitmapCleanup	proc	near
		mov	bx, ss:[colorTransfer]
		tst	bx
		jz	doDither
		tst	ss:[colorTransferSeg]
		jz	doDither
		call	MemUnlock
		mov	ss:[colorTransferSeg], 0
doDither:
		mov	bx, handle CMYKDither
		tst	ss:[colorDitherSeg]
		jz	done
		call	MemUnlock
		mov	ss:[colorDitherSeg], 0
		mov	bx, handle CMYKClrBitmap
		call	MemUnlock
done:
		ret
CMYKColorBitmapCleanup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScanCMYK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Monochrome bitmap drawline

CALLED BY:	PutBitsSimple
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ds:si	- pointer to bitmap data
		es:di	- pointer into frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutBWScanCMYK		proc	near
		
		; fill the CMY planes with zeroes, then draw the B/W bitmap
		; to the black plane.

		mov	al, ss:[bm_cacheType] 
		and	al, mask BMT_FORMAT
		cmp	al, BMF_3CMY			; do UC removal ?
		je	doCMY

		; for CMYK, clear other planes and do black only

		call	ResetCMYKPlane			; clear yellow
		add	di, ss:[bm_bpMask]		; get to 
		call	ResetCMYKPlane			; clear cyan
		add	di, ss:[bm_bpMask]		; get to 
		call	ResetCMYKPlane			; clear magenta
		jmp	lastPlane

		; for CMY, ignore black and fill the other three
doCMY:
		call	PutBWScan			; draw it to yellow
		add	di, ss:[bm_bpMask]
		call	PutBWScan			; draw it to cyan
lastPlane:
		add	di, ss:[bm_bpMask]
		call	PutBWScan			; draw it to mag/black
		ret
PutBWScanCMYK		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBWScanMaskCMYK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as PutBWScanCMYK, except it has a mask

CALLED BY:	PutBitsSimple
PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

		ds:si	- pointer to bitmap data
		es:di	- pointer into frame buffer

RETURN:		bp intact

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutBWScanMaskCMYK	proc	near
		
		; fill the CMY planes with zeroes, then draw the B/W bitmap
		; to the black plane.

		mov	al, ss:[bm_cacheType] 
		and	al, mask BMT_FORMAT
		cmp	al, BMF_3CMY			; do UC removal ?
		je	doCMY

		; fill the CMY planes with zeroes, then draw the B/W bitmap
		; to the black plane.

		call	ResetCMYKPlaneMask		; clear yellow
		add	di, ss:[bm_bpMask]		; get to 
		call	ResetCMYKPlaneMask		; clear cyan
		add	di, ss:[bm_bpMask]		; get to 
		call	ResetCMYKPlaneMask		; clear magenta
		jmp	lastPlane

		; for CMY printers, ignore black plane
doCMY:
		call	PutBWScanMask
		add	di, ss:[bm_bpMask]		; get to 
		call	PutBWScanMask
lastPlane:
		add	di, ss:[bm_bpMask]		; get to 
		call	PutBWScanMask			; write bitmap to black
		ret
PutBWScanMaskCMYK		endp



COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillBWScanCMYK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a scan line's worth of system memory to screen

CALLED BY:	INTERNAL

PASS:		d_x1	- x coordinate to start drawing
		d_y1	- scan line to draw to
		d_x2	- x coordinate of right side of image
		d_dx	- width of image (pixels)
		d_bytes	- width of image (bytes) (bytes/scan/plane)

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
	Jim	03/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

FillBWScanCMYK	proc	near
		uses	bp
		.enter

		; init some stuff.  Get the dithers ready

		InitDitherIndex <ss:[yellowBase]>

		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		mov	bp, bx			; get # bits into image 
		sub	bp, ss:[d_x1]		; get left coordinate
		mov	cl, 3			; want to get byte indices
		sar	ax, cl
		sar	bx, cl
		sar	bp, cl
		add	si, bp			; add bytes-to-left-side 
		add	di, bx			; add to screen offset too
		mov	bp, ax			; get right side in bp
		sub	bp, bx			; bp = # dest bytes to write
		mov	al, ss:lineMask 	;  
		mov	cs:[cmykMask], al

		; init shift-out bits 

		clr	ch			; assume no initial shift out
		clr	ah
		mov	cl, ss:[bmShift]	; load shift amount
		tst	ss:[bmPreload]		; see if preboarding
		jns	FBS_skipPreload		;  skip preload on flag value
		lodsb				; get first byte of bitmap
		ror	ax, cl			; get shift out bits in ah
		mov	ch, ah			; and save them

FBS_skipPreload:
		mov	bx, {word} ss:[bmRMask]	; get mask bytes
		or	bp, bp			; test # bytes to draw
		jne	FBS_left		;  more than 1, don't combine
		and	bl, bh
		mov	cs:[cmykRightMask], bl	; store SELF MOD and-immediate
		jmp	FBS_right
FBS_left:
		mov	cs:[cmykLeftMask], bh
		mov	cs:[cmykRightMask], bl
		clr	ah			; clear for future rotate
		lodsb				; get next byte of bitmap
		ror	ax, cl			; shift bits
		xchg	ch, ah			; save bits shifted out
		or	al, ah			; get bitmap data for mask
		call	CMYKbmLeftMask		; do left side
		inc	di
		dec	bp			; if zero, then no center bytes
		jz	FBS_right
FBS_center:
		clr	ah			; clear for rotate
		lodsb				; next data byte
		ror	ax, cl			; rotate into place
		xchg	ch, ah			; save out bits, 
		or	al, ah			; combine old/new bits
		call	CMYKbmMidMask		; do middle bytes
		inc	di
		dec	bp			; one less to do
		jg	FBS_center		; loop to do next byte 
FBS_right:
		mov	al, ds:[si]		; get last byte
		shr	al, cl			; shift bits
		or	al, ch			; get extra bits, if any
		call	CMYKbmRightMask		; do right side
		.leave
		ret
FillBWScanCMYK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetCMYKPlane
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a plane with zeroes/ones (depends on ON_BLACK bit)

CALLED BY:	INTERNAL
		PutBWScanCMYK
PASS:		es:di	- points to beginning of a scan line
			
			- PutLineSetup called to setup all bitmap drawing vars
RETURN:		nothing	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		fill the space with the resetColor

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetCMYKPlane		proc	near
		uses	di, ax, bx, cx, dx
		.enter
		mov	bx, ss:[bmLeft]	; get bounds of fill on line
		mov	ax, ss:[bmRight]

		; calculate # bytes to fill in

		mov	cl, 3		; want to get byte indices
		sar	ax, cl
		sar	bx, cl
		add	di, bx		; add to screen offset too
		mov	cx, ax		; get right side in bp
		sub	cx, bx		; cx = # dest bytes to write
		mov	dl, ss:linePatt		;  dl = color of "set" pixels
		mov	dh, ss:lineMask 	;  dh = draw mask

		mov	bx, {word} ss:[bmRMask]	; get mask bytes
		or	cx, cx		; test # bytes to draw
		jne	RCP_left	;  more than 1, don't combine masks
		mov	ah, bl		;  only one, combine masks
		and	ah, bh
		mov	cs:[RCP_rMask], ah ; store SELF MODIFIED and-immediate
		jmp	RCP_right
RCP_left:
		and	bl, dh		; apply draw mask to right side mask
		mov	cs:[RCP_rMask], bl ; store SELF MODIFIED and-immediates
		mov	ah, {byte} ss:[resetColor] ; get color to fill in plane
		and	bh, dh		; combine left/line masks
		and	ah, bh		; apply combination to data
		mov	al, es:[di]	; al = screen data
		not	bh
		and	al, bh
		not	bh
		and	bh, {byte} ss:[resetColor] ; figure out bits to save
		or	al, bh		; clear out bits we don't need
		call	ss:[modeRoutine]	
		stosb			; write byte
		dec	cx		; if zero, then no center bytes
		jz	RCP_right

RCP_center:
		mov	ah, {byte} ss:resetColor
		and	ah, dh		; apply user-spec draw mask
		mov	al, es:[di]	; get screen data
		mov	bh, dh		; get copy of mask
		not	bh
		and	al, bh
		not	bh
		and	bh, {byte} ss:[resetColor] ; figure out which bits to save
		or	al, bh		; clear out bits we don't need
		call	ss:[modeRoutine] ; call right routine
		stosb			; write the byte
		loop	RCP_center

RCP_right:
		mov	ah, {byte} ss:resetColor ; get last byte
RCP_rMask equ (this byte) + 1
		mov	bh, 03h			; SELF MODIFIED and-immediate
		and	bh, dh			; apply user-spec draw mask
		and	ah, bh
		mov	al, es:[di]		; get screen data
		not	bh
		and	al, bh
		not	bh
		and	bh, {byte} ss:[resetColor] ; figure out bits to save
		or	al, bh			; clear out bits we don't need
		call	ss:[modeRoutine]	; combine bits
		stosb				; write the byte
		.leave
		ret
ResetCMYKPlane		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetCMYKPlaneMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a plane with zeroes/ones (depends on ON_BLACK bit)

CALLED BY:	INTERNAL
		PutBWScanCMYK
PASS:		es:di	- points to beginning of a scan line
			
			- PutLineSetup called to setup all bitmap drawing vars
RETURN:		nothing	
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		fill the space with the resetColor

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetCMYKPlaneMask	proc	near
		uses	di, ax, bx, cx, dx, si, bp
		.enter
		mov	bx, ss:[bmLeft]
		mov	ax, ss:[bmMaskSize]	; store mask size in code
		neg	ax			; mask is stored first
		mov	cs:[RCPM_mask1], ax	; store offset to mask
		mov	cs:[RCPM_mask2], ax	; store offset to mask
		mov	cs:[RCPM_mask3], ax	; store offset to mask
		mov	cs:[RCPM_preM], ax	; store offset to mask
		mov	ax, ss:[bmRight]

	; calculate # bytes to fill in

		mov	dx, bx
		sub	dx, ss:[d_x1]
		mov	cl, 3			; want to get byte indices
		sar	ax, cl
		sar	bx, cl
		sar	dx, cl
		add	si, dx
		add	di, bx			; add to screen offset too
		mov	bp, ax			; get right side in bp
		sub	bp, bx			; cx = # dest bytes to write
		mov	dl, {byte} ss:setColor	;  dl = color for "set" pixels
		mov	dh, ss:lineMask 	;  dh = draw mask

		mov	ah, 0xff		; init mask shift out
		mov	cl, ss:[bmShift]	; load shift amount
		tst	ss:[bmPreload]		; check for pre-boarders
		jns	RCPM_skipPreload	; if same source or less, skip
RCPM_preM equ (this word) + 2
		mov	al, ds:[si][1234h]	; preload the mask byte too
		ror	ax, cl			; ah = init overflow bits

	; at this point, ah=overflow mask bits
RCPM_skipPreload:
		mov	bx, {word} ss:[bmRMask]	; get mask bytes
		or	bp, bp			; test # bytes to draw
		jne	RCPM_left		;  more than 1, don't combine
		mov	ch, ah			; move mask overflow bits
		and	bl, bh
		mov	cs:[RCPM_rMask], bl ; store SELF MODIFIED and-immediate
		jmp	RCPM_right
RCPM_left:
		and	bl, dh		; apply draw mask to right side mask
		mov	cs:[RCPM_rMask], bl ; store SELF MOD and-immediates
		and	bh, dh			; combine left/line masks
RCPM_mask1 equ (this word) + 2
		mov	al, ds:[si][1234h]	; apply mask stored with bitmap
		inc	si			; so mask will be right
		mov	ah, 0xff
		ror	ax, cl
		xchg	ah, ch			; get old overflow, save new
		or	ah, al
		and	ah, bh
		and	ah, {byte} ss:resetColor
		mov	al, es:[di]		; al = screen data
		not	bh
		and	al, bh
		not	bh
		and	bh, {byte} ss:[resetColor] ; which bits to save
		or	al, bh			; clear out bits we don't need
		call	ss:[modeRoutine]
		stosb				; write byte
		dec	bp			; if zero, then no center bytes
		jz	RCPM_right

RCPM_center:
		mov	ah, {byte} ss:resetColor
		mov	bh, dh			; get copy of mask
RCPM_mask2 equ (this word) + 2
		mov	al, ds:[si][1234h]	; apply mask stored with bitmap
		inc	si			; so mask will be right
		mov	ah, 0xff
		ror	ax, cl
		xchg	ah, ch			; get old overflow, save new
		or	ah, al
		and	ah, bh
		and	ah, {byte} ss:resetColor
		mov	al, es:[di]		; get screen data
		not	bh
		and	al, bh
		not	bh
		and	bh, {byte} ss:[resetColor] ; which bits to save
		or	al, bh			; clear out bits we don't need
		call	ss:[modeRoutine]	; call right routine
		stosb				; write the byte
		dec	bp
		jnz	RCPM_center
RCPM_right:
		mov	ah, {byte} ss:resetColor
RCPM_rMask equ (this byte) + 1
		mov	bh, 03h			; SELF MODIFIED and-immediate
		and	bh, dh			; apply user-spec draw mask
RCPM_mask3 equ (this word) + 2
		mov	al, ds:[si][1234h]	; apply mask stored with bitmap
		inc	si			; so mask will be right
		mov	ah, 0xff
		ror	ax, cl
		xchg	ah, ch			; get old overflow, save new
		or	ah, al
		and	ah, bh
		and	ah, {byte} ss:resetColor
		mov	al, es:[di]		; get screen data
		not	bh
		and	al, bh
		not	bh
		and	bh, {byte} ss:[resetColor] ; which bits to save
		or	al, bh			; clear out bits we don't need
		call	ss:[modeRoutine]	; combine bits
		stosb				; write the byte		
		.leave
		ret
ResetCMYKPlaneMask	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMYKbmMask routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as ClusterMask routines, above, except these do 	
		draw masks and draw modes.

CALLED BY:	CMYKbmCluster routines
PASS:		NextDitherWord invoked
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		
p
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CMYKbmRightMask proc	near
		push	dx
cmykRightMask	equ (this byte) + 1
		and	al, 12h			; set up mask
		jmp	cmykMaskCommon
CMYKbmRightMask endp

CMYKbmMidMask proc	near
		push	dx
		jmp	cmykMaskCommon
CMYKbmMidMask endp

CMYKbmLeftMask proc	near
		push	dx
cmykLeftMask	equ (this byte) + 1
		and	al, 12h			; set up mask
cmykMaskCommon	label	near
cmykMask	equ	(this byte) + 1
		and	al, 12h
		mov	ah, al			; save bitmap bits
		NextDitherByte <ss:[yellowBase]>
		mov	dl, al			; setup yellow dither
		mov	al, es:[di]
		call	CMYKbmDoMode
		mov	es:[di], al
		mov	bx, ss:[bm_bpMask]	; go to cyan plane
		mov	dl, {byte} ss:[cyanWord]
		mov	al, es:[di][bx]
		call	CMYKbmDoMode
		mov	es:[di][bx], al
		shl	bx, 1			; go to magenta plane
		mov	dl, {byte} ss:[magentaWord]
		mov	al, es:[di][bx]
		call	CMYKbmDoMode
		mov	es:[di][bx], al
		add	bx, ss:[bm_bpMask]	; go to magenta plane
		mov	dl, {byte} ss:[blackWord]
		mov	al, es:[di][bx]
		call	CMYKbmDoMode
		mov	es:[di][bx], al
		pop	dx
		ret
CMYKbmLeftMask endp

CMYKbmDoMode	proc	near
		mov	dh, ah			; save bitmap data
		call	ss:[modeRoutine]	; apply mode
		mov	ah, dh			; restore bitmap data
		ret
CMYKbmDoMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutCMYKColorScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routines for 4-, 8-, and 24-bit bitmap drawing

CALLED BY:	PutBitsSimple
PASS:		ds:si	- pointer into bitmap data
		es:di	- pointer into frame buffer
			
		also	- PutLineSetup called to setup values in ss:
RETURN:		nothing
DESTROYED:	most everything (except bp)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SelfModFarCall	macro	target, lbl
	.inst	byte 9ah
	.inst	word offset target
lbl	label	word
	.inst	word 0
	endm

PutCMYKColor4 proc	near
		SelfModFarCall <CMYKClrBitmap:PutColor4>, modifyCMYK4
		ret
PutCMYKColor4 endp

PutCMYKColor8 proc	near
		SelfModFarCall <CMYKClrBitmap:PutColor8>, modifyCMYK8
		ret
PutCMYKColor8 endp

PutCMYKColor24 proc	near
		SelfModFarCall <CMYKClrBitmap:PutColor24>, modifyCMYK24
		ret
PutCMYKColor24 endp

PutCMYKColor4Mask proc	near
		SelfModFarCall <CMYKClrBitmap:PutColor4Mask>, modifyCMYK4mask
		ret
PutCMYKColor4Mask endp

PutCMYKColor8Mask proc	near
		SelfModFarCall <CMYKClrBitmap:PutColor8Mask>, modifyCMYK8mask
		ret
PutCMYKColor8Mask endp

PutCMYKColor24Mask proc	near
		SelfModFarCall <CMYKClrBitmap:PutColor24Mask>, modifyCMYK24mask
		ret
PutCMYKColor24Mask endp


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
		uses	bp, di, si
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
	mov	al, es:[di]		; al = screen data
	not	bh
	and	al, bh
	not	bh
	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
	or	al, bh			; clear out bits we don't need
	call	ss:[modeRoutine]					   
	stosb				; write byte
	dec	bp			; if zero, then no center bytes
	jz	PBS_right

PBS_center:
	clr	ah			; clear for rotate
	lodsb				; next data byte
	ror	ax, cl			; rotate into place
	xchg	bl, ah			; save out bits, restore old out bits
	or	ah, al			; combine old/new bits
	and	ah, dh			; apply user-spec draw mask
	mov	al, es:[di]		; get screen data
	mov	bh, dh			; get copy of mask
	not	bh
	and	al, bh
	not	bh
	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
	or	al, bh			; clear out bits we don't need
	call	ss:[modeRoutine]	; call right routine
	stosb				; write the byte
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
	mov	al, es:[di]		; get screen data
	not	bh
	and	al, bh
	not	bh
	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
	or	al, bh			; clear out bits we don't need
	call	ss:[modeRoutine]	; combine bits
	stosb				; write the byte		
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
		uses	bp, di, si
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
	sar	bx, cl
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
	mov	al, es:[di]		; al = screen data
	not	bh
	and	al, bh
	not	bh
	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
	or	al, bh			; clear out bits we don't need
	call	ss:[modeRoutine]					   
	stosb				; write byte
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
	mov	al, es:[di]		; get screen data
	not	bh
	and	al, bh
	not	bh
	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
	or	al, bh			; clear out bits we don't need
	call	ss:[modeRoutine]	; call right routine
	stosb				; write the byte
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
	mov	al, es:[di]		; get screen data
	not	bh
	and	al, bh
	not	bh
	and	bh, {byte} ss:[resetColor] ; figure out which bits to save
	or	al, bh			; clear out bits we don't need
	call	ss:[modeRoutine]	; combine bits
	stosb				; write the byte		
	.leave
		ret
PutBWScanMask	endp


NullBMScan	proc	near
		ret
NullBMScan	endp

VidSegment	Misc

GetOneScan	proc	near
		ret
GetOneScan	endp

VidEnds		Misc


VidSegment	Blt

BltSimpleLine	proc	near
		ret
BltSimpleLine	endp

VidEnds		Blt


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
	ForceRef	ByteModeRoutines
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
ByteINV	label	near		; screenXOR(data^mask) 
	xor	al, ah
	ret
ByteXOR	label	near		; screenXOR(data^mask^pattern)
INVRSE <tst	ss:[inverseDriver]					>
INVRSE <jz	notInverse						>
INVRSE <not	dl							>
	; Ok, this goes against style guidelines, but we need speed and
	; dl back in its original form: duplicate three lines
	; and "ret" in the middle of this function.
INVRSE <and	ah, dl							>
INVRSE <not	dl							>
INVRSE <xor	al, ah							>
INVRSE <ret								>
INVRSE <notInverse:							>
	and	ah, dl
	xor	al, ah
	ret
ByteSET	label	near		; (screen^~(data^mask))v(data^mask^setColor)
	not	ah		;
	and	al, ah		;
	not	ah		;
	and	ah, byte ptr ss:[setColor]
	or	al, dl
	ret
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
	nptr	ByteXOR
	nptr	ByteSET
	nptr	ByteOR

VidEnds		Bitmap


