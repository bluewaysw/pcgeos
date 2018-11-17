COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Video drivers
FILE:		vidcomRaster.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    GLB VidBitBlt		Transfer a block of pixels on the screen.
    INT BltQuick		Faster bitblt routine when source and dest
				are on same	x position
    INT BltLineSetup		Do some setup info for blt routines
    EXT VidGetBits		Copy a block of information from video
				memory to system memory.	 The cursor
				is NOT erased.  Clipping regions are
				ignored for the reads (all bits are
				returned).
    GLB VidPutBits		Transfer raw pixel data from system to
				video memory, clipped to the current clip
				region.  Data must be uncompacted.
    INT PutBitsSimple		Clip and draw each scan line of bitmap
    INT PutLineSetup		Do some setup info for bitmap routines
    GLB PutScanFront		Far entry point for put-scan routines.

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	Jim	12/88	initial version
	jeremy	5/91	Added support for the mono EGA driver


DESCRIPTION:
	This is the source for the common video raster routines

	This file is included in each video driver
		
	The complete specification for screen drivers can be found on the 
	system in the pcgeos spec directory (/usr/pcgeos/Spec/video.doc).  
	The raster primitives are specified in usr/pcgeos/Spec/bitmap.doc

	$Id: vidcomRaster.asm,v 1.1 97/04/18 11:41:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSegment	Blt


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidBitBlt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer a block of pixels on the screen.

CALLED BY:	GLOBAL

PASS:		ax 	- x position, source
		bx 	- y position, source
		cx	- x position, dest
		dx	- y position, dest

		si	- width, pixels
		bp	- height, pixels

		ds	- points to graphics state info
		es	- points to Window structure

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		do all the setup;
		If (source and dest on same bit boundary)
		   call fastblt
		else
		   call slowblt

		to handle overlapping regions, the relative positions of the
		source and destination blocks are looked at and the following
		actions taken:

		source LEFT of dest:	copy bytes from RIGHT side of source
					to RIGHT side of destination first, 
					then DECREASE x position.
		source RIGHT of dest:	copy bytes from LEFT side of source
					to LEFT side of destination first, 
					then INCREASE x position.
		source ABOVE dest:	copy bytes from BOTTOM side of source
					to BOTTOM side of destination first, 
					then DECREASE y position.
		source BELOW dest:	copy bytes from TOP side of source
					to TOP side of destination first, 
					then INCREASE y position.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The current drawing mode is ignored: all bitblts are done
		as COPYs.
		We should also support drawing through a draw mask

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidBitBlt	proc	far
		; before we save anything, make sure we have positive
		; coordinate values.  The surgeon general has announced that
		; bltting from negative screen space can be hazardous to
		; your health.

		tst	bx			; test the source position
		jns	checkDest		;  ok, check the destination

		; source position is negative, adjust it

		neg	bx			; amount we are negative
		add	dx, bx			; adjust destination
		sub	bp, bx			; fewer lines to do
		mov	bx, 0			; src now at 0 (don't use CLR)
		jg	checkDest		; continue checking destination
VBB_exitFar:
		jmp	VBB_exit		; nothing left to blt

		; check the destination
checkDest:
		tst	dx			; destination negative ?
NMEM <		jns	destOK			;  no, OK to blt now	>
MEM <		jns	sizeOK			;  no, OK to blt now	>

		; destination is negative, so do the same as we did for source

		neg	dx			; get amt we are negative
		add	bx, dx			; adjust the source line
		sub	bp, dx			; fewer lines to do
		mov	dx, 0			; dst now at 0 (don't use CLR)
		jle	VBB_exitFar		; if there are no lines left..
						;  ...then hasta la vista
ifndef	IS_MEM
		; Do one last test - make sure we are not blitting off
		; the bottom of video memory, as we'll both waste time
		; and possibly access memory we should not be touching.
		; So, make sure that (sourceY + height) & (destY + height)
		; are both less than the height of the screen. If either
		; is larger, decrease the number of lines we are copying
		; to compensate.
destOK:
		tst	bp			; if negative lines...
		js	sizeOK			;  ...don't do anything here
		mov	di, bx
		add	di, bp
		dec	di
		sub	di, ss:[DriverTable.VDI_pageH]
		jbe	checkBltHeightDest
		sub	bp, di			; decrease # of lines
checkBltHeightDest:
		mov	di, dx
		add	di, bp
		dec	di
		sub	di, ss:[DriverTable.VDI_pageH]
		jbe	sizeOK
		sub	bp, di			; decrease # of lines
endif
		; save parameters
sizeOK:
		mov	ss:[d_x1src], ax	; save endpoints
		mov	ss:[d_y1], bx
		mov	ss:[d_x1], cx
		mov	ss:[d_y2], dx
		mov	ss:[d_dy], bp		; dy = line count
		mov	ss:[d_dx], si		; dx = width

		; check for collision with pointer (check source and dest)

		cmp	cx, ax			; set  ax = min (ax,cx)
		jg	VBB_xset		;  and cx = max (ax,cx)
		xchg	ax, cx
VBB_xset:
		add	cx, si			; add in width
		dec	cx
		cmp	dx, bx			; set  bx = min (ax,cx)
		jg	VBB_yset		;  and dx = max (ax,cx)
		xchg	dx, bx
VBB_yset:
		add	dx, bp			; add in height 
		dec	dx

		; check for collision with pointer and save under area

NMEM <		call	CheckCollisions					>

		; set up segment registers

		push	es			; save window & gr state segs
		push	ds				
		segmov	ds, es			; ds -> Window structure
		SetBuffer	es, dx		; es -> screen memory
ifdef	IS_VGALIKE
		; set up ega registers

		mov	dx, GR_CONTROL		; ega control register
		mov	ax, WR_MODE_0
		out	dx, ax
CEGA <		mov	ax, EN_SR_ALL					>
MEGA <		mov	ax, 0x0101		; enable plane 1 only	>
		out	dx, ax
		mov	ax, SR_BLACK
		out	dx, ax
		mov	ax, DATA_ROT_OR
		out	dx, ax
endif

CASIO <		call	SetCasioModeFar					>

		; DO IT...

		mov	bx, ss:[d_y1]		; load source y postion
ifdef	REAL_BLT_SUPPORT
		mov	ax, ss:[d_x1src]	; load up parameters
		mov	cx, ss:[d_x1]		; destination x position
		mov	dx, ss:[d_y2]		; destination y position
		call	DoBlt
else
		; === BBX FR 11/10/97 implement dynamic buffer allocation
		;			for VESA drivers
		;			defined in macro BltQuickBuffer locally

ifdef	IS_VGA8
		BltQuickBuffer
else

ifdef	IS_VGA24
		BltQuickBuffer
else
		call	BltQuick
endif

endif
		; === BBX
endif

		; restore EGA to default state

EGA <		mov	dh, C_BLACK		; set color to black	>
EGA <		mov	dl, MM_COPY		; and cody draw mode	>
EGA <		call	SetEGAClrModeFar	; just use a handy funtion >

NIKEC <		mov	dh, C_BLACK		; set color to black	>
NIKEC <		mov	dl, MM_COPY		; and cody draw mode	>
NIKEC <		call	SetNikeClrModeFar	; just use a handy funtion >

		; change it so default state is AutoTransfer ON
;CASIO <	CasioAutoXferOff				>

		; all done with blitting, exit

NMEM <		cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.	>
NMEM <		jz	noRedrawXOR		;redraw it if it was hidden.>
NMEM <		call	ShowXORFar					>
NMEM <noRedrawXOR:							>

NMEM <		cmp	ss:[hiddenFlag],0				>
NMEM <		jz	ptrRedrawn					>
NMEM <		call	CondShowPtrFar					>
NMEM <ptrRedrawn:							>

		pop	ds			; restore original segments
		pop	es
VBB_exit:
		ret

VidBitBlt	endp


ifndef	REAL_BLT_SUPPORT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltQuick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Faster bitblt routine when source and dest are on same 
		x position

CALLED BY:	INTERNAL

PASS:		d_x1src	- source x position
		bx	- source y position	(also in d_y1)
		d_x1	- dest x position
		d_y2	- dest y position
		si	- width of copy		(also in d_dx)
		bp	- # scan lines to copy 	(also in d_dy)
		
RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:
		for each scan 
		   for each byte in line
		      read latches
		      build the mask for the destination block
		      write latches

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The current drawing mode is ignored: all bitblts are done
		as COPYs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BQ_up:
		add	bx, bp 			; if up, then start at bottom
		dec	bx			;  of block
		add	dx, bp			; same for destination
		dec	dx
		mov	cs:[BQ_storejmp], offset BQU_loop - offset BQ_loopjmp 
		jmp	BQ_calc

;------------------------------------------------------------------------
		
BltQuick	proc	near

		; first set up ptrs into frame buffer: es:si->src, es:di->dst

		add	si, ss:[d_x1]		; si = right side coord
		dec	si
		mov	ss:[d_x2], si		; d_x2 now = right side coord
		mov	dx, ss:[d_y2]		; restore dest start
		cmp	bx, dx			; see if going up or down
		jl	BQ_up			;  up, handle as special caase
		mov	cs:[BQ_storejmp], offset BQ_loop - offset BQ_loopjmp 
BQ_calc		label	near
		mov	bp, dx			; save dest scan line 
		mov	cx, bx			; save source scan line too
		clr	si			; clear source address register
ifdef	IS_VGA8
		CalcScanLineSrc bx,si,es
elifdef	IS_VGA24
		CalcScanLineSrc	bx,si,es
else
NMEM <		CalcScanLine	bx,si		; es:si - start of source scan>
MEM <		CalcScanLineSrc	bx,si,es	; es:si - start of source scan>
endif
		mov	si, bx
		clr	di			; clear dest address reg
ifdef	IS_VGA8
		mov	bx, dx
		CalcScanLine	bx,di,es	; es:di - start of dest scan >
		mov	di, bx
elifdef	IS_VGA24
		mov	bx, dx
		CalcScanLine	bx,di,es	; es:di - start of dest scan >
		mov	di, bx
else
NMEM <		CalcScanLine	dx,di		; es:di - start of dest scan >
MEM <		CalcScanLine	dx,di,es	; es:di - start of dest scan >
		mov	di, dx
endif
		; figure out if we'll need to copy right->left or left->right

		mov	cs:[BQ_jmpComplex], offset BQ_notSimple - offset BQ_simple
		mov	dx, ss:[d_x1]		; get destination position
		cmp	dx, ss:[d_x1src]	; going left or right ?
		LONG jl	BQ_setClip		;  right, jump set right
		mov	cs:[BQ_jmpComplex], offset BQ_notSimpleR - offset BQ_simple
		jmp	BQ_setClip
BQ_loop:
		inc	bp			; bump scan line #
ifdef	IS_VGA8
		NextScanSrc	si
elifdef	IS_VGA24
		NextScanSrc	si
else
MEM <		NextScanSrc	si					>
NMEM <		NextScan	si					>
endif

MEM <		tst	ss:[bm_scansNextSrc]				> 
MEM <		js	done						> 
		NextScan	di
MEM <		tst	ss:[bm_scansNext]				> 
MEM <		js	done						> 

		; make sure that clip info is correct
BQ_start:
		cmp	bp,ds:[W_clipRect].R_bottom ; below definition area ?
		LONG jg	BQ_setClip
		cmp	bp,ds:[W_clipRect].R_top ; above definition area ?
		LONG jl	BQ_setClip

		; test for type of clipping region, and set mask for this line
BQ_afterClip:
		mov	al,ds:[W_grFlags]
		test	al,mask WGF_CLIP_NULL
		jnz	BQ_next
		test	al,mask WGF_CLIP_SIMPLE
		jnz	BQ_simple
BQ_jmpComplex	equ	(this word) + 1
		jmp	nextRLsection		; make sure it's far
BQ_simple		label	near

		mov	bx,ds:[W_clipRect.R_left]
		mov	ax,ds:[W_clipRect.R_right]
		cmp	bx, ss:[d_x2]		; see if to left
		jg	BQ_next
		cmp	ax, ss:[d_x1]		; see if to right
		jl	BQ_next

		; simple clipping region -- call BltSimpleLine

		push	si, di
		call	BltSimpleLine
		pop	si, di
BQ_next:
		dec	ss:[d_dy]		; dec scan line count
BQ_storejmp	equ	(this byte) + 1
		jg	BQ_loop
BQ_loopjmp	label	near

		; for vidmem, we need to unlock the final data block
MEM <done:								>
MEM <		ReleaseHugeArray2		; release final blocks	>
		ret
;------------------------------

BQU_loop	label	near
		dec	bp			; bump scan line #
ifdef	IS_VGA8
		PrevScanSrc	si
elifdef	IS_VGA24
		PrevScanSrc	si
else
MEM <		PrevScanSrc	si					>
NMEM <		PrevScan	si					>
endif

MEM <		tst	ss:[bm_scansPrevSrc]				> 
MEM <		js	done						> 
		PrevScan	di
MEM <		tst	ss:[bm_scansPrev]				> 
MEM <		js	done						> 
		jmp	BQ_start

		; special case: must reset clipping region
BQ_setClip:
		mov	bx, bp
		push	si,di
		call	WinValClipLine
		pop	si,di
		mov	bx,ds:[W_clipRect.R_left]
		mov	ax,ds:[W_clipRect.R_right]
		call	BltLineSetup		; figure clipping stuff
		jmp	BQ_afterClip

;------------------------------

		; not simple region
		; Now, there are sections to this complex clip thing.
		; They are rectangles, sitting side by side.  We have to
		; process them in the right order -- left to right if 
		; we are bltting to the left, and right to left if we
		; are bltting to the right.  Go look at d_x1 and d_x1src
		; to figure out which way we're going.
BQ_notSimple:
		mov	dx, si
		mov	si, ds:W_maskReg
		mov	si, ds:[si]
		add	si,ds:[W_clipPtr]	;test for within clip area
BQ_nsLoop:
		lodsw				;get first ON point
		cmp	ax, EOREGREC		;check for at end
		jz	BQ_next2
		cmp	ax,ss:[d_x2]		;test for past right side
		jg	BQ_next2

		mov	bx,ax			;bx = first ON point
		lodsw				;ax = last ON point
		cmp	ax,ss:[d_x1]		;test if before left
		jl	BQ_nsLoop

		; need to draw part of this segment
		; bx = left ON point, ax = right ON point

		call	BltLineSetup		; figure clipping stuff
		push	dx
		push	si
		push	di
		mov	si, dx
		call	BltSimpleLine
		pop	di
		pop	si
		pop	dx
		jmp	BQ_nsLoop
BQ_next2:
		mov	si, dx
		jmp	BQ_next

		; not a simple region, but we're bltting to the right,
		; so copy the sub-rects from right to left.  First, find
		; the end of the region, then go backwards.
BQ_notSimpleR:
		mov	dx, si			; save ptr to beg of scan
		mov	si, ds:W_maskReg	; get ptr to region
		mov	si, ds:[si]		; get real pointer
		add	si, ds:[W_clipPtr]	; get pointer into the region 
		mov	bx, si			; save ptr to start

		add	si, 8			; we know there are at least
						; two sets of x coords
findEndReg:
		lodsw				; find the EOREGREC
		cmp	ax, EOREGREC		; found end yet ?
		jne	findEndReg
		sub	si, 2			; back to EOREGREC

		; OK so we fount the end.  back up the the last set of on/off
		; points and start bltting.

backLoop:
		sub	si, 4			; ds:si -> last off point
		cmp	si, bx			; are we done yet ?
		jb	BQ_next2		;  yes, on to next region
		push	bx			;  no, save region ptr
		mov	ax, ds:[si+2]		; get right side
		cmp	ax, ss:[d_x1]		; before left side of blt ?
		jl	BQ_next2		;  yes, all done with this 
		mov	bx, ds:[si]		;  no, get left side of region
		cmp	bx, ss:[d_x2]		; after right side of blt ?
		jg	nextRLsection		;  yes, skip this sub-rect
		call	BltLineSetup		; figure clipping stuff
		push	dx, si, di		; save the approp regs
		mov	si, dx
		call	BltSimpleLine
		pop	dx, si, di
nextRLsection:
		pop	bx			; restore original pointer
		jmp	backLoop

BltQuick	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BltLineSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some setup info for blt routines

CALLED BY:	INTERNAL
		BltQuick

PASS:		d_x1	- x coordinate to start drawing
		d_x2	- x coordinate of right side of image
		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BltLineSetup	proc	near
		uses	ax,bx,cx,dx
		.enter
		mov	cx, ss:[d_x1]
		cmp	bx, cx			; use max(leftBlt,leftRegion)
		jge	PLS_10
		mov	bx, cx			; bx = max(leftBlt,leftRegion)
PLS_10:					
		mov	ss:[bmLeft], bx
		mov	cx, ss:[d_x2]
		cmp	ax, cx			; min(rightBlt/rightRegion)
		jle	PLS_20
		mov	ax, cx

PLS_20:						; ax=min(rightBlt,rightRegion)
		mov	ss:[bmRight], ax
ifdef	BIT_CLR4
		mov	dx, 0xffff		; assume full mask
		test	bl, 1			; build left side masks
		jz	haveLeft
		mov	dh, MASK_FOR_RIGHTMOST_PIXEL_IN_BYTE
haveLeft:
		test	al, 1
		jnz	haveRight
		mov	dl, MASK_FOR_LEFTMOST_PIXEL_IN_BYTE
haveRight:
else
		mov	ch, bl			; build left side masks
		mov	cl, al			; build right side masks
		and	cx, 0707h		; isolate low bits
		mov	dl, 80h			; dl = right mask
		sar	dl, cl
		mov	cl, ch
		mov	dh, 0ffh
		shr	dh, cl			; dh = left side masks
endif
		mov	{word} ss:[bmRMask], dx	; store left/right masks
		.leave
		ret
BltLineSetup	endp

endif		;REAL_BLT_SUPPORT

VidEnds		Blt


NMEM <VidSegment	GetBits		>
MEM  <VidSegment	Misc		>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidGetBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a block of information from video memory to system
		memory.  The cursor is NOT erased.  Clipping regions are
		ignored for the reads (all bits are returned).

CALLED BY:	EXTERNAL

PASS:		ax 	- x position, source
		bx 	- y position, source
		cx	- width, pixels
		dx	- height, pixels

		ds:bp	- pointer to destination block
		si	- size of destination block

		es	- points to Window structure

RETURN:		Buffer at bp:di filled with data.  The block is written with
		the following format (simple bitmap data structure):
			dw	width	; width of data written
			dw	height	; height of data written
			db	0	; data is written uncompacted
			db	type	; type of bitmap:
					; see graphics.def for documentation

			db	...	; data scan line ordered, planes
					;  written for each scan line in
					;  scan line order, just as for
					;  bitmaps in the system.

		There is an eight byte header written before the data, so the
		passed buffer should be sized 8 bytes too big.  The data
		is written uncompacted.  If the passed buffer is not big
		enough, the routine aborts.  The height field in the buffer
		will reflect the number of VALID scan lines written.

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:
		for each scan line
		    copy the data from the video buffer to the supplied buffer
		write the header

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	4/89...		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidGetBits	proc	far

		; save segs, create local stack frame

		push	es			; save window segment
		segmov	es, ds, di			; es:bp -> block to fill
		mov	di, bp			; es:di -> block to fill

		; save some passed parameters for later

		mov	ss:[d_x1], ax		; source x position
		mov	ss:[d_y1], bx		; source y position
		mov	ss:[d_dx], cx		; width
		mov	ss:[d_dy], dx		; height
		mov	ss:[unitCount], si 	; re-use a variable
		add	cx, ax			; get right side coord
		dec	cx
		mov	ss:[d_x2], cx		; right side coordinate
		push	dx			; save original scans
		push	di			; save original pointer
		add	di, size Bitmap		; skip the header space
		mov	cl, al
		and	cl, 7			; get shift amount
ifdef	BIT_CLR4
		and	cl, 1			; only low bit needed 	
		shl	cl, 1			;  but it's 4 bits 	
		shl	cl, 1						
endif
		mov	ss:[shiftCount], cl	; re-use char variable

		; SELF-MODIFY the code to take care of scan line bumping

		mov	dx, ss:[d_dy]		; restore #scans
		SetBuffer ds, cx		; set ds->frame buffer
		mov	si, ss:[d_y1]		; calc ptr in si
		clr	cx
ifdef	IS_VGA8
		CalcScanLineSrc	si, cx, ds	; ds:si -> frame buffer offset
elifdef	IS_VGA24
		CalcScanLineSrc	si, cx, ds	; ds:si -> frame buffer offset
else
		CalcScanLine	si, cx, ds	; ds:si -> frame buffer offset
endif	
		mov	cx, ss:[unitCount]	; pass buffer size
		sub	cx, size Bitmap		; minus some for header

		; for each scan line, copy it to the passed buffer
VGB_loop:
		push	si			; save pointers
		push	dx			; save line count
		call	GetOneScan		; call device specific routine
		pop	dx			; one less to do
		pop	si			; restore source ptr
		dec	dx			; one less to do
		jz	VGB_setHeader		;  go til done
MEM <		segxchg	ds, es			; NextScan needs es for vidmem>
ifdef	IS_VGA8
		NextScanSrc si
elifdef	IS_VGA24
		NextScanSrc si
else
		NextScan si			; bump scan line pointer
endif
MEM <		tst	ss:[bm_scansNextSrc]	; if zero, we're done	>
MEM <		js	VGB_setHeader		;			>
MEM <		segxchg	ds, es			; NextScan needs es for vidmem>
		tst	cx			; see if buffer full
		jns	VGB_loop		;  yes, exit loop

		; all done with transfer, set the header info
VGB_setHeader:
MEM <		ReleaseHugeArray		; release last data block >
		segmov	ds, es, di		; copy segment to ds
		pop	di			; restore original pointer
		mov	si, ss:[d_dx]		; get image width
		mov	ds:[di].B_width, si	; save width of transfer
		pop	si			; restore # scans to do
		sub	si, dx			; see how many we did
		mov	ds:[di].B_height, si	; store # scans we wrote
ifdef	IS_MEM
		mov	dx, es			; save segment register
		mov	es, ss:[bm_segment]	; get segment address of block
		mov	si, es:[EB_bm].CB_devInfo ; get pointer to device info
		mov	bl, byte ptr es:[EB_bm][si].VDI_bmFormat
		and	bl, not (mask BMT_COMPLEX or mask BMT_HUGE)
		mov	es, dx
else
		mov	bl, byte ptr ss:[DriverTable].VDI_bmFormat
endif
		mov	ds:[di].B_type, bl	; store plane/adjbits info
		mov	ds:[di].B_compact, 0	; no compactions

		; restore segs, quit

		pop	es			; restore window seg
		ret
VidGetBits	endp

NMEM <VidEnds		GetBits	>
MEM  <VidEnds		Misc	>


VidSegment	Bitmap


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidPutBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer raw pixel data from system to video memory, clipped
		to the current clip region.  Data must be uncompacted.

CALLED BY:	GLOBAL

PASS:		ax 	- x position, destination
		bx 	- y position, destination

		ss:bp	- inherits PutBitsArgs structure (see videoDr.def)

				PutBitsArgs	struct
				    PBA_bm    Bitmap <>	; bitmap hdr
				    PBA_flags PutBitsFlags ; options 
				    PBA_data  fptr	; fptr to data
				    PBA_size  word	; #bytes per scan line
				    PBA_pal   fptr	; fptr to palette 
				PutBitsArgs	ends

				PutBitsFlags	record
				    :14,	
				    PBF_FILL_MASK:1,	     ; for GrFillBitmap
				    PBF_PAL_TYPE BMPalType:1 ; palette type
				PutBitsFlags	end

				BMPalType options are:
				BMPT_RGB    ; palette has 3-byte RGB entries
				BMPT_INDEX  ; palette has 1-to-1 map of indices


		ds	- points to graphics state info
		es	- points to Window structure

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		transfer the bits

		The source block is assumed to be formatted as a bitmap.  The
		header includes the information about the size/format of the
		bitmap.

		The height of the bitmap to draw could be negative.  
		This means that you should draw the bitmap's first scan 
		line at the passed position, the second scan line at 
		(passed position -1), etc, instead of increasing the 
		position for each scan line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
		This routine does not even look at the compaction flag int
		the bitmap structure (it assumes it is uncompacted).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/89...		Initial version
	Jim	1/92		rewrites to elim complex bitmaps, pass struct

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidPutBits	proc	far
bm		local	PutBitsArgs
		mov	ss:[saveBP], bp
		.enter			; we are on a diff stack, so alloc 
					; space even though we've "inherited"
					; the structure.

		; save segs, parameters

		mov	ss:[d_x1], ax
		mov	ss:[d_y1], bx
MEM <		mov	ss:[bmScan], bx					>

		; set up any dithering and masking required, based on whether
		; we are FILLING or DRAWING

		mov	dl, ds:[GS_mixMode]		; get draw mode 
		mov	ss:[currentDrawMode], dl			
EGA <		mov	dh, ds:[GS_areaAttr].CA_colorIndex		>
EGA <		call	SetEGAClrModeFar				>
NIKEC <		mov	dh, ds:[GS_areaAttr].CA_colorIndex		>
NIKEC <		call	SetNikeClrModeFar				>
		mov	dh, ds:[GS_areaAttr].CA_mapMode
		call	SetResetColorFar		; setup some vars
		CopyMask	<ds:[GS_areaAttr.CA_mask]>,ax, ss

		; since we have switched stacks upon entering the video 
		; driver, we need to copy the PutBitsArgs structure to ourr
		; stack so we can access it 

		mov	ss:[saveDS], ds		; save these for later
		mov	ds, ss:[saveSS]		; get old stack segment
		mov	si, ss:[saveBP]		; ds:si -> old ss:bp
		mov	cx, size PutBitsArgs
		sub	si, cx			; ds:si -> passed structure
		push	es
		segmov	es, ss, di
		lea	di, ss:bm
		rep	movsb			; copy the structure
		mov	dx, bm.PBA_size
		mov	ss:[d_bytes], dx	; and save it for later
		mov	cs:[PBS_bumpSrc], dx	; and save it here too
		mov	cx, bm.PBA_bm.B_width
		mov	dx, bm.PBA_bm.B_height
		pop	es

		; we've had some problems with bizarre palettes showing up,
		; probably due to the BMT_PALETTE bit set and a screwed up 
		; PBA_pal pointer.  If the pointer segment is zero, make sure
		; the bit is reset.  Or catch in in the EC version.
NEC <		test	bm.PBA_bm.B_type, mask BMT_PALETTE		>
NEC <		jz	palChecks					>
NEC <		tst	bm.PBA_pal.segment				>
NEC <		jnz	palChecks					>
NEC <		and	bm.PBA_bm.B_type, not mask BMT_PALETTE		>

EC <		test	bm.PBA_bm.B_type, mask BMT_PALETTE		>
EC <		jz	palChecks					>
EC <		tst	bm.PBA_pal.segment				>
EC <		ERROR_Z VIDEO_PUTBITS_BAD_PALETTE			>
palChecks:
		; check to see if we are FILLING, if so, set the ditherMatrix

		test	bm.PBA_flags, mask PBF_FILL_MASK
		jnz	setBitmapDither
CASIO <		call	SetCasioModeFar		; set auto-transfer mode >

		; calculate right and bottom positions
calcRightBottom:
		tst	cx			; if nothing to draw, exit
		jz	farExit
		mov	ss:[d_dx], cx		; save width
		mov	ax, ss:[d_x1]		; get left coordinate
		add	cx, ax			; calc right side coord
		dec	cx			; one less for right side
		mov	ss:[d_x2], cx		; save coordinate
		tst	dx			; if nothing to draw, exit
		jz	farExit
		mov	ss:[d_dy], dx		; store bitmap height
		LONG jns handleNormalBitmap	; normal bitmap, continue

		; we're drawing bottom to top.  change a few things.

		add	dx, bx			; do the same to calc bottom
		inc	dx
		mov	ss:[d_y2], dx
		tst	ss:[d_y1]
		LONG jns checkCursor
farExit:
		jmp	exit
	
		; this is a convenient place to put this, since there's a jump
		; right above us...
setBitmapDither:
		push	dx
		mov	ds, ss:[saveDS]		; get GState back
		CheckSetDither ss, GS_areaAttr
		pop	dx
		jmp	calcRightBottom
handleNormalBitmap:
		add	dx, bx			; do the same to calc bottom
		dec	dx
		mov	ss:[d_y2], dx
		js	farExit			; if negative, quit now

		; check for collision with pointer and save under area
		; before checking, ensure top/bottom coords are sorted
checkCursor:
NMEM <		cmp	bx, dx						>
NMEM <		jl	coordsOK					>
NMEM <		xchg	bx, dx						>
NMEM < coordsOK:							>
NMEM <		call	CheckCollisions					>

		; setup the type of draw mode routine we need (for non-VGA
		; devices

ifndef IS_MEGA
BIT <		mov	bl, ss:[currentDrawMode]			>
BIT <		clr	bh						>
BIT <		shl	bx, 1			; set to index into tab	>
BIT <		mov	ax, cs:ByteModeRout[bx]				>
BIT <		mov	ss:[modeRoutine], ax 				>
ifdef IS_MONO
BIT <		mov	ax, cs:ByteMixRout[bx]				>
BIT <		mov	ss:[mixRoutine], ax				>
endif
endif

		; while we have pointer to bitmap set, save type

		mov	bl, bm.PBA_bm.B_type	; get flags and
		mov	ss:[bmType], bl		;  save flags

		; if there is a mask, calculate the size of it

		clr	ax			; assume no mask
		test	bl, mask BMT_MASK	; check for one
		jz	haveMaskSize
		mov	ax, bm.PBA_bm.B_width	; calc mask size
		add	ax, 7			; round up
		shr	ax, 1			; divide by 8 to get bytes 
		shr	ax, 1
		shr	ax, 1
haveMaskSize:
		mov	ss:[bmMaskSize], ax	; save it

		; if there is a palette, store the address
		
		mov	ss:[bmPalette].segment, ss		; init no pal
ifndef IS_CMYK
ifndef IS_CLR24
		mov	ss:[bmPalette].offset, offset defBitmapPalette
else
		mov	ss:[bmPalette].offset, offset currentPalette
endif
else
		mov	ss:[bmPalette].offset, offset currentPalette
endif
		test	bl,  mask BMT_PALETTE	; check for palette
		jz	getScanRoutine		
		mov	ax, bm.PBA_pal.offset	; copy pointer
		mov	ss:[bmPalette].offset, ax
		mov	ax, bm.PBA_pal.segment
		mov	ss:[bmPalette].segment, ax

		; see which routine to call to xfer bitmap: b/w, color or grey
getScanRoutine:

ifdef IS_CLR24
ifndef IS_DIRECT_COLOR
		call	CalcPalette		; convert 8-bit palette to RGB
endif
endif
		and	bl, mask BMT_FORMAT or mask BMT_MASK 

		; for the purposes of looking the proper routine up in the 
		; table, we use the BMT_COMPLEX bit to distinguish between
		; FILL and DRAW...

		test	bm.PBA_flags, mask PBF_FILL_MASK
		jz	getRoutine
		or	bl, mask BMT_COMPLEX
getRoutine:
		clr	bh
		shl	bx, 1

if	(DISPLAY_CMYK_BITMAPS eq TRUE)
EGA <		cmp	bx, BMF_4CMYK*2					>
EGA <		je	useCMYKroutine					>
EGA <		cmp	bx, BMF_3CMY*2					>
EGA <		jne	normalRoutine					>
EGA <useCMYKroutine:							>
EGA <		mov	ax, offset PutCMYKScan				>
EGA <		jmp	haveRoutine					>
EGA <normalRoutine:							>
		mov	ax, cs:[putbitsTable][bx] ; get routine offset
EGA <haveRoutine:							>
else
		mov	ax, cs:[putbitsTable][bx] ; get routine offset
endif

		sub	ax, offset cs:bitmapRelocLabel
		mov	cs:[bitmapRoutine], ax	; re-use rect jump variable

		; for CMYK vidmem, if we're drawing a color bitmap, lock down
		; a few resources for the duration.

CMYK <		call	CMYKColorBitmapInit				>

		; call lower level routine...

		segmov	ds, es, dx		; ds -> Window structure
		SetBuffer es, dx		; es -> screen memory
		call	PutBitsSimple		; draw the bitmap
		segmov	es, ds, dx		; restore window seg

		; cleanup after CMYK stuff

CMYK <		call	CMYKColorBitmapCleanup				>

		; restore EGA to default state

EGA <		mov	dh, C_BLACK		; set color to black	>
EGA <		mov	dl, MM_COPY		; and cody draw mode	>
EGA <		call	SetEGAClrModeFar	; just use a handy funtion >

NIKEC <		mov	dh, C_BLACK		; set color to black	>
NIKEC <		mov	dl, MM_COPY		; and cody draw mode	>
NIKEC <		call	SetNikeClrModeFar	; just use a handy funtion >

		; convenient place to get Casio hardware back in order too

		; change it so default state is AutoTransfer ON
;CASIO <	CasioAutoXferOff				>

		; all done, restore cursor if necc

NMEM <		cmp	ss:[xorHiddenFlag],0	;check for ptr hidden.	>
NMEM <		jz	xorRedrawn		; redraw  if hidden.	>
NMEM <		call	ShowXORFar					>
NMEM <xorRedrawn:							>
NMEM <		cmp	ss:[hiddenFlag],0				>
NMEM <		jz	ptrRedrawn					>
NMEM <		call	CondShowPtrFar					>
NMEM <ptrRedrawn:							>

		; done with everything, restore a few registers
exit:
		mov	ds, ss:[saveDS]		; restore GState seg
		mov	si, ss:[saveBP]
		.leave
		mov	bp, si
		ret
VidPutBits	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutBitsSimple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clip and draw each scan line of bitmap

CALLED BY:	INTERNAL

PASS:		ss:bp	- inherits PutBitsArgs structure
		ds	- segment of Window structure
		es	- segment of frame buffer

		d_x1	- x coordinate of destination left side
		d_x2	- x coordinate of destination right side
		d_y1	- y coordinate of destination top side
		d_y2	- y coordinate of destination bottom side
		d_dy 	- scan line count
		d_bytes	- # bytes/plane/scan line in bitmap data
		d_color	- color to draw b/w bitmaps on color device

		cs:Routine - address of routine to transfer a scan line

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		set up some loop info;
		for each scan line in bitmap
		   ensure clipping info is set right
		   if (not totally clipped)
		      transfer one scan line of bitmap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	11/88...	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; if we're drawing up, modify some self-mods we did earlier
drawingUp	label	near
		neg	ss:[d_dy]
		mov	cs:[loopModification], offset upLoop - offset afterLoop
		tst	ss:[d_y1]		; negative starting position ?
		jns	checkUnderWindow
		jmp	afterLoop		; yes, done

		; if we are starting below the window and drawing up, it is
		; very similar to the negStartLine condition.  Do something
		; similar.
checkUnderWindow:
		mov	ax, ds:[W_winRect].R_bottom	; check vs. window
		cmp	ax, ss:[d_y1]		; if below bottom...
		jge	calcScanLine		; if OK, continue
		xchg	ss:[d_y1], ax		;  else set new start scan
		sub	ax, ss:[d_y1]		; #scan lines shorter
		jmp	bumpSrcCommon

		; starting to draw at negative coord.  Fix it.  If y2 is also
		; negative, exit
negStartLine	label	near
		tst	ss:[d_y2]		; totally negative ?
		LONG js	afterLoop		;  yes, try again later
		mov	ax, ss:[d_y1]		; calc #scans in neg
		neg	ax			; this many scans off
		mov	ss:[d_y1], 0		; start at scan line 0
bumpSrcCommon	label	near
		sub	ss:[d_dy], ax		; fewer lines to do
		LONG js	afterLoop		; can't do negative #lines
		mov	dx, cs:[PBS_bumpSrc]	; #bytes/scan line
		mul	dx			; calc # to bump si
		add	si, ax			; bump bitmap data ptr
		jmp	calcScanLine		; now do the drawing


PutBitsSimple	proc	near
bm		local	PutBitsArgs
		.enter	inherit

		; load the data pointer.  If we are filling the bitmap and
		; it has a mask, use the mask data.

		mov	si, bm.PBA_data.offset	; segment will be loaded later
		test	bm.PBA_flags, mask PBF_FILL_MASK
		jnz	havePointer
		add	si, ss:[bmMaskSize]	; bump pointer past mask

		; check if starting coordinate is negative.  If so, adjust
		; all the pointers til we get into valid territory.
		; fall through in the normal case (drawing down, in bounds)
havePointer:
		tst	ss:[d_dy]		; are we drawing up ?
		js	drawingUp		;  no, continue
		mov	cs:[loopModification],offset downLoop-offset afterLoop 
		tst	ss:[d_y1]		; negative starting position ?
		js	negStartLine

		; do some work to calc offset to frame buffer and bump values
calcScanLine	label	near
		mov	di, ss:[d_y1]		; calc offset to scan line
		mov	bx, di			; keep a copy of scan line 
		clr	ax			; offset to start of scan line
ifdef	IS_VGA8
		CalcScanLineBoth di, ax, es, es	; es:di -  start of dest scan
elifdef	IS_VGA24	
		CalcScanLineBoth di, ax, es, es	; es:di -  start of dest scan
else
NMEM <		CalcScanLine	di, ax		; es:di -  start of dest scan >
MEM  <		CalcScanLine	di,ax,es	; es:di -  start of dest scan >
endif
		jmp	PBS_setClip		; jump to start of loop

		; drawing loop -- bump destination pointer to the next scan
upLoop		label	near
		dec	bx			; bump scan line #
		cmp	bx, ds:[W_maskRect].R_top
		LONG jl	afterLoop
ifdef	IS_VGA8
		PrevScanBoth	di
elifdef	IS_VGA24
		PrevScanBoth	di
else
		PrevScan	di
endif
MEM <		tst	ss:[bm_scansPrev]	; if zero, we're done	>
MEM <		LONG js	afterLoop					>
		jmp	bumpSourcePtr
downLoop:
		inc	bx			; bump scan line #
		cmp	bx, ds:[W_maskRect].R_bottom ; past bottom of window ?
		LONG ja	afterLoop		; yes, DONE.
ifdef	IS_VGA8
		NextScanBoth	di
elifdef	IS_VGA24
		NextScanBoth	di
else
		NextScan	di
endif
MEM <		tst	ss:[bm_scansNext]	; if zero, we're done	>
MEM <		LONG js	afterLoop					>

		; bump bitmap data pointer to the next scan line
bumpSourcePtr:
PBS_bumpSrc	equ	(this word) + 2
		add	si, 1234h		; SELF MODIFIED add-immediate
MEM <		mov	ss:[bmScan], bx		; save it for dither stuff >

		; make sure that clip info is correct

		cmp	bx,ds:[W_clipRect].R_bottom ; below definition area ?
		LONG jg	PBS_setClip
		cmp	bx,ds:[W_clipRect].R_top ; above definition area ?
		LONG jl	PBS_setClip

		; check out the clip information
		; test for type of clipping region
checkClipInfo:
		mov	ah, ds:[W_grFlags]	; get clip optimization flags
		test	ah, mask WGF_CLIP_NULL	;  if null, go to next one
		jnz	nextAfterPop

		push	bx			; save scan line number
		and	bx, 7			; select one of 8 scan lines
		mov	al, byte ptr ss:maskBuffer[bx] ; get mask for this line
		tst	al			;  if NULL, just skip it
		jz	PBS_next

		; Rotate the mask.  Since only VGA8 and above drivers don't
		; have code to rotate the mask in their scan routines in the
		; xxxRaster.asm files, while all other drivers already do, we
		; only need to do it here for VGA8 and above drivers.
ifdef	IS_VGA8
		mov	cl, ss:[bmShift]
		rol	al, cl			; aligh draw mask
elifdef	IS_VGA24
		mov	cl, ss:[bmShift]
		rol	al, cl			; aligh draw mask
endif	; IS_VGA8

		mov	ss:lineMask, al		; save mask for this line
MONO <		mov	al, byte ptr ss:ditherMatrix[bx] ; get pattern too  >
MONO <		mov	ss:linePatt, al		; store pattern 	  >

ifdef	BIT_CLR4
		shl	bx, 1			; one word/scan		
		and	bx, 6			; one of 4 scan lines	
		mov	bx, {word} ss:ditherMatrix[bx]			
		mov	ss:ditherScan, bx				
endif

ifdef	BIT_CLR2
		shl	bx, 1			; one word/scan		
		and	bx, 6			; one of 4 scan lines	
		mov	bx, {word} ss:ditherMatrix[bx]			
		mov	ss:ditherScan, bx				
endif
		test	ah, mask WGF_CLIP_SIMPLE
		LONG jz	PBS_notSimple

		mov	bx,ds:[W_clipRect].R_left ; Clip left and right to 
		mov	ax,ds:[W_clipRect].R_right ;  window
		cmp	bx, ss:[d_x2]		; see if to left
		jg	PBS_next
		cmp	ax, ss:[d_x1]		; see if to right
		jl	PBS_next

		; simple clipping region -- call transfer routine

ifndef IS_CLR24
MEM <		push	ax, bx						>
MEM <		mov	ax, ss:[bmLeft]		; set up left...	>
MEM <		mov	bx, ss:[bmScan]		;   ..and scan line	>
ifdef IS_CMYK
		test	bm.PBA_flags, mask PBF_FILL_MASK
		jz	colorDither
		call	CalcDitherIndices	; calc dither 
ditherDone:
else
MEM <		call	CalcDitherIndices	; calc dither 		>
endif
MEM <		pop	ax, bx						>
endif
		push	si,di,ds,bp		; save source/dest pointers
		mov	ds, bm.PBA_data.segment	; set up ds -> bitmap 
bitmapRoutine	equ	(this word) + 1
		call	PutBWScan		; call right scan line routine
bitmapRelocLabel label	near
		pop	si,di,ds,bp		; restore window segment
PBS_next:
		pop	bx			; restore scan number
nextAfterPop:
		dec	ss:[d_dy]		; dec scan line count
		jle	afterLoop
loopModification equ	(this word+1)
		jmp	PutBitsSimple		; make sure it's > 256 bytes
afterLoop	label	near

		; for vidmem, release the last data block
MEM <		ReleaseHugeArray		; release last block	>

		.leave
		ret

		; different dither init for colored bitmaps
ifdef IS_CMYK
colorDither:
		call	CalcByteDitherIndices
		jmp	ditherDone
endif

		; special case: must reset clipping region
PBS_setClip:
		push	bx			; save scan number
		push	si,di
		call	WinValClipLine
		pop	si,di
		mov	bx,ds:[W_clipRect].R_left ; Clip left and right to 
		mov	ax,ds:[W_clipRect].R_right ;  window
		call	PutLineSetup		; setup masks, etc...
		pop	bx			; restore scan line number
		jmp	checkClipInfo

		; special case: not simple region
PBS_notSimple:
		mov	cx, cs:[bitmapRoutine]	; re-store it where we want it
		add	cx, offset cs:bitmapRelocLabel-offset cs:bitmapReloc2
		mov	cs:[clippedBitmapRoutine], cx
		mov	cx, si
		mov	si, ds:W_maskReg
		mov	si, ds:[si]
		add	si,ds:[W_clipPtr]	;test for within clip area
PBS_nsLoop:
		lodsw				;get first ON point
		cmp	ax, EOREGREC		;check for at end
		jz	PBS_next2
		cmp	ax,ss:[d_x2]		;test for past right side
		jg	PBS_next2

		mov	bx,ax			;bx = first ON point
		lodsw				;ax = last ON point
		cmp	ax,ss:[d_x1]		;test if before left
		jl	PBS_nsLoop

		; need to draw part of this segment
		; bx = left ON point, ax = right ON point

		call	PutLineSetup		; setup masks, etc...
ifndef IS_CLR24
MEM <		push	ax, bx						>
MEM <		mov	ax, bx			; set up left...	>
MEM <		mov	bx, ss:[bmScan]		;   ..and scan line	>
ifdef IS_CMYK
		test	bm.PBA_flags, mask PBF_FILL_MASK
		jz	colorDither2
		call	CalcDitherIndices	; calc dither 
ditherDone2:
else
MEM <		call	CalcDitherIndices	; calc dither 		>
endif
MEM <		pop	ax, bx						>
endif
		push	si,di,cx,ds
		mov	si, cx
		mov	ds, bm.PBA_data.segment	; set up ds -> bitmap 
clippedBitmapRoutine equ (this word) + 1
		call	PutBWScan		; call correct transfer routine
bitmapReloc2	label	near
		pop	si,di,cx,ds
		jmp	PBS_nsLoop
PBS_next2:
		mov	si, cx
		jmp	PBS_next

		; different dither init for colored bitmaps
ifdef IS_CMYK
colorDither2:
		call	CalcByteDitherIndices
		jmp	ditherDone2
endif

PutBitsSimple	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutLineSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do some setup info for bitmap routines

CALLED BY:	INTERNAL
		PutBitsSimple

PASS:		d_x1	- x coordinate to start drawing
		d_x2	- x coordinate of right side of image
		ax	- rightmost ON point for simple region
		bx	- leftmost ON point for simple region

RETURN:		bitmap optimization variable set.

		(this used to return...)
		bmLeft		- max (leftRegion, leftImage)
 		bmRight		- min (rightRegion, rightImage)
		bmPreload	- preload test flag
		bmShift		- # shifts to do
		bmLMask		- left mask
		bmRMask		- right mask

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just calculate the values, idiot;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutLineSetup	proc	near
		uses	ax,bx,cx,dx
bm		local	PutBitsArgs
		.enter	inherit			
		ForceRef bm

		mov	cx, ss:[d_x1]
		cmp	bx, cx			; use max(leftImage,leftRegion)
		jge	PLS_10
		mov	bx, cx			; bx = max(leftImage,leftReg)
PLS_10:					
		mov	ss:[bmLeft], bx
		and	cl, 07h			; calc shift while we have
		mov	ss:[bmShift], cl
		mov	ch, bl			; see if we need to pre-load 
		and	ch, 7
		sub	ch, cl			; if this <0, then preload
		mov	ss:[bmPreload], ch
		mov	cx, ss:[d_x2]
		cmp	ax, cx			; min(rightImage/rightRegion)
		jle	PLS_20
		mov	ax, cx

		; build out left and right side masks
PLS_20:						; ax=min(rightImage,rightReg)
		mov	ss:[bmRight], ax	
ifdef BIT_CLR4
		mov	dl, ss:bmType
		and	dl, mask BMT_FORMAT
		cmp	dl, BMF_MONO
		je	doMono

;	The problem with this case is if someone is doing a GrFillBitmap with
;	a 16-color bitmap, the PBF_FILL_MASK bit will be set, but we still need
;	the bmLMask and bmRMask flags to be set for a 4-bit bitmap.
;

		test	bm.PBA_bm.B_type, mask BMT_MASK
		jz	notMono
		test	bm.PBA_flags, mask PBF_FILL_MASK ; filling mask ? 
		jnz	doMono
notMono:
		mov	dx, 0xffff		; assume full mask
		test	bl, 1			; build left side masks
		jz	haveLeft
		mov	dh, MASK_FOR_RIGHTMOST_PIXEL_IN_BYTE
haveLeft:
		test	al, 1
		jnz	done
		mov	dl, MASK_FOR_LEFTMOST_PIXEL_IN_BYTE
		jmp	done
doMono:
endif
		mov	ch, bl			; build left side masks
		mov	cl, al			; build right side masks
		and	cx, 0707h		; isolate low bits
		mov	dl, 80h			; dl = right mask
		sar	dl, cl
		mov	cl, ch
		mov	dh, 0ffh
		shr	dh, cl			; dh = left side masks
done::
		mov	{word} ss:[bmRMask], dx	; store left/right masks

		.leave
		ret
PutLineSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutScanFront
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far entry point for put-scan routines.

CALLED BY:	GLOBAL

PASS:		cx	  - offset of near routine to call in this module
		ss:bmArgs - offset on stack to PutBitsArgs structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutScanFront	proc	far
		mov	bp, ss:[bmArgs]		; setup ptr to args
		call	PutLineSetup
		call	cx
		ret
PutScanFront	endp

VidEnds	Bitmap
