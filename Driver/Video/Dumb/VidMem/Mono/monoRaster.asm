COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Cluster mode dithering for filling mono bitmaps
FILE:		monoRaster.asm

AUTHOR:		Jim DeFrisco, Mar  3, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT FillBWScanCluster	Transfer a scan line's worth of system
				memory to screen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/ 3/92		Initial revision


DESCRIPTION:
	Need a clustered dither filling mode for mono bitmaps
		

	$Id: monoRaster.asm,v 1.1 97/04/18 11:42:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillBWScanCluster
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

FillBWScanCluster	proc	near
		uses	bp
		.enter

		; init some stuff.  Get the dithers ready

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

		; store shift amount as self-mod value to save register space
		; this won't affect the flags register, so last compare is ok

		clr	ch			; assume no initial shift out
		clr	ah
		mov	cl, ss:[bmShift]	; load up shift amount
		tst	ss:[bmPreload]
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
		dec	bp			; if zero, then no center bytes
		jz	FBS_right
FBS_center:
		clr	ah			; clear for rotate
		lodsb				; next data byte
		ror	ax, cl			; rotate into place
		xchg	ch, ah			; save out bits, 
		or	al, ah			; combine old/new bits
		call	CMYKbmMidMask		; do middle bytes
		dec	bp			; one less to do
		jg	FBS_center		; loop to do next byte 
FBS_right:
		mov	al, ds:[si]		; get last byte
		shr	al, cl			; shift bits
		or	al, ch			; get extra bits, if any
		call	CMYKbmRightMask		; do right side
		.leave
		ret
FillBWScanCluster	endp

