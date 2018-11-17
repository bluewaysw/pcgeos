COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vidcomOutput.asm

AUTHOR:		Tony Requist and Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version
	jeremy	5/91		Added support for the mono EGA driver
	
DESCRIPTION:
	Common rectangle drawing code for video drivers
		
	$Id: vidcomOutput.asm,v 1.1 97/04/18 11:41:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidDrawRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a filled rectangle with the given drawing state

CALLED BY:	GLOBAL
PASS:		ax - left coordinate
		bx - top coordinate
		cx - right coordinate
		dx - bottom coordinate
		ds - graphics state structure
		es - Window structure
		si - offset to CommonAttr structure
RETURN:		es - Window structure (may have moved)
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
	Jim	11/88		Changes for VGA
	Jim	6/89		Changes for vidmem
	Jim	11/91		Changes for dithering

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
;	Constants for self-modifying code

DOR_CONST	= offset DrawOptRect
DSR_CONST	= offset DrawSpecialRect
RR_CONST	= offset rectRoutineLabel
BIT <DNR_CONST	= offset DrawNOTRect					>

DRAW_OPT_RECT	=	DOR_CONST - RR_CONST - 3
DRAW_SPECIAL_RECT =	DSR_CONST - RR_CONST - 3

BIT <DRAW_NOT_RECT =	DNR_CONST - RR_CONST - 3 >
CASIO <DRAW_XOR_RECT = (offset DrawSolidRect) - RR_CONST - 3		>

;---------------

NMEM <VDR_checkXOR	label	near					>
NMEM <	call	CheckXORCollision					>
NMEM <	jmp	VDR_afterXOR						>

	; trivial reject the rectangle.  set up to exit.
rejectNoDraw 	label	near
	push	ds			; save gstate and window for later 
	push	es							
	jmp	VDR_afterDraw						

;---------------


VidDrawRect	proc	near

ifndef	IS_MEM					; no pointers,xor,save under
						; for vidmem driver
 	; check for collision with pointer				

 	cmp	ax,cs:[cursorRegRight]				
 	jg	VDR_noCollision			;to the right,branch
 	cmp	cx,cs:[cursorRegLeft]					
 	jl	VDR_noCollision			;to the left -> branch
 	cmp	bx,cs:[cursorRegBottom]				
 	jg	VDR_noCollision			;to the bottom,branch
 	cmp	dx,cs:[cursorRegTop]				
 	jl	VDR_noCollision			;to the top -> branch
 	call	CondHidePtr					
VDR_noCollision:					

	; check for collision with XOR region	

	cmp	cs:[xorRegionHandle], 0	
	jnz	VDR_checkXOR	
VDR_afterXOR	label	near

 	; check for collision with save under area

 	cmp	es:[W_savedUnderMask],0		
 	jz	VDR_noSU		
 	call	CheckSaveUnderCollisionES	

	; now that we have the true bounds of the mask region, clip the
	; rectangular area.  Do some trivial reject testing while we're at
	; it
VDR_noSU:

endif
	mov	di, es:[W_maskRect.R_left]	; check left side first	
	cmp	cx, di				; trivial reject left ?
	jl	rejectNoDraw			;  yes, pretend all done
	cmp	ax, di				; clip to left side
	jg	doRightCheck
	mov	ax, di				; clip it down
doRightCheck:
	mov	di, es:[W_maskRect.R_right]	; check right side second	
	cmp	ax, di				; trivial reject right ?
	jg	rejectNoDraw			;  yes, pretend all done
	cmp	cx, di				; clip to right side
	jl	doTopCheck
	mov	cx, di				; clip it down
doTopCheck:
	mov	di, es:[W_maskRect.R_top]	; check top side second	
	cmp	dx, di				; trivial reject top ?
	jl	rejectNoDraw			;  yes, pretend all done
	cmp	bx, di				; clip to top side
	jg	doBottomCheck
	mov	bx, di				; clip it down
doBottomCheck:
	mov	di, es:[W_maskRect.R_bottom]	; check bottom side second	
	cmp	bx, di				; trivial reject bottom ?
	jg	rejectNoDraw			;  yes, pretend all done
	cmp	dx, di				; clip to bottom side
	jl	VDR_clipped
	mov	dx, di				; clip it down
VDR_clipped:

	; change bottom to # of lines
	sub	dx, bx
	inc	dx

	; save coordinates (last one saved just below)

	mov	di,cx			;di = right
	mov	bp,dx			;bp = # of lines

	; set up dither matrix and optimization flags

	CheckSetDither	cs

	test	es:[W_color], mask WCF_MASKED
	jnz	special

EGA <	mov	dx,DRAW_OPT_RECT		;assume optimal case	>
EGA <	test	ds:[si].CA_flags,mask AO_MASK_1_COPY	;test for optimal  >
EGA <	jnz	afterSpecial			;if optimal then branch	>
EGA <special:								>

NIKEC <	mov	dx,DRAW_OPT_RECT		;assume optimal case	>
NIKEC <	test	ds:[si].CA_flags,mask AO_MASK_1_COPY	;test for optimal  >
NIKEC <	jnz	afterSpecial			;if optimal then branch	>
NIKEC <special:								>

ifndef IS_MEGA
BIT <	mov	cl,ds:[si].CA_flags		;load optimization flags >
BIT <	mov	dx,DRAW_OPT_RECT		;assume optimal case	>
BIT <	test	cl,mask AO_MASK_1_COPY					>
BIT <	jnz	afterSpecial			;if optimal then branch	>
MBIT <	mov	dx,DRAW_NOT_RECT		;assume GR_INVERT case	>
MBIT <	test	cl,mask AO_MASK_1_INVERT				>
MBIT <	jnz	afterSpecial			;if optimal then branch	>
BIT <special:								>
BIT <	mov	cx,bx							>
BIT <	mov	bl,ds:[GS_mixMode]					>
BIT <	clr	bh							>
BIT <	shl	bx,1				;;handle draw mode	>
BIT <	mov	dx,cs:[bx][drawModeTable]				>
BIT <	mov	cs:[modeRoutine],dx					>
BIT <	mov	bx,cx							>
endif

	CopyMask	<word ptr ds:[si].CA_mask>,dx
	mov	dx,DRAW_SPECIAL_RECT

afterSpecial:

	mov	cs:[rectRoutine],dx

	mov	si,ax				;si = left

	; set up so far: color, routine to call

	; set up es to point at video buffer, ds at window

	push	ds
	push	es
	segmov	ds, es, ax 		;ds = window
	SetBuffer	es, ax		;make es point at buffer, trash ax

	; test for mask region simple in which case no more clip checking
	; if necessary

	test	ds:[W_grFlags],mask WGF_MASK_SIMPLE
	jz	VDR_complex

	call	DrawSimpleRect

VDR_afterDraw	label	near
MEM <	ReleaseHugeArray		; release block		> 
	; changed 4/7/93 to make AutoTransfer the default
;CASIO <CasioAutoXferOff	; turn off auto-transfer	>
NMEM <	cmp	cs:[xorHiddenFlag], 0				>
NMEM <	jz	afterXORRedraw					>
NMEM <	call	ShowXOR						>
NMEM <afterXORRedraw:						>
NMEM < 	cmp	cs:[hiddenFlag],0				>
NMEM < 	jz	afterPtrRedraw					>
NMEM < 	call	CondShowPtr					>
NMEM <afterPtrRedraw:						>

	pop	es
	pop	ds

	ret

	; special case: some clipping must be done

VDR_complex:
	mov	cs:[PSL_saveWindow],ds
	call	DrawComplexRect
	jmp	short VDR_afterDraw

VidDrawRect	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawComplexRect

DESCRIPTION:	Draw a rectangle possibly clipped

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	si - left coordinate of rect
	bx - top coordinate of rect
	di - right coordinate of rect
	bp - # of lines to draw
	PSL_saveWindow - window structure (locked)
	es - video RAM

RETURN:

DESTROYED:
	ax, bx, cx, dx,si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

DrawComplexRect	proc	near

ifdef	LOGGING
	ornf	cs:[curRegFlags], mask RF_CALLED_DRAW_COMPLEX_RECT
endif

	push	ds
	mov	ds,cs:[PSL_saveWindow]

	mov	cs:[d_x1],si
	mov	cs:[d_x2],di
	mov	cs:[d_y1],bx
	mov	cs:[d_lineCount],bp

DCR_loop:

	; make sure that clip info is correct

	mov	bx,cs:[d_y1]
	mov	bp,ds:[W_clipRect.R_bottom]
	cmp	bx,bp
	jg	DCR_setClip
	cmp	bx,ds:[W_clipRect.R_top]			; above definition area ?
	jl	DCR_setClip
DCR_afterClip:

	; bp = W_clipRect.R_bottom, compute # of lines

	sub	bp,bx
	inc	bp			;bp = # of valid lines from top
	cmp	bp,cs:[d_lineCount]	;get max (valid lines, lines to draw)
	jb	DCR_noWrap
	mov	bp,cs:[d_lineCount]
DCR_noWrap:

	; test for type of clipping region

	mov	cl,ds:[W_grFlags]
	test	cl,mask WGF_CLIP_NULL
	jnz	DCR_next
	test	cl,mask WGF_CLIP_SIMPLE
	jz	DCR_notSimple

	; simple clipping region -- call DrawSimpleRect
	; bp = # of lines to draw, bx = top line
	; Clip left and right to W_clipRect.R_left, W_clipRect.R_right

	mov	cx,ds:[W_clipRect.R_left]
	mov	ax,ds:[W_clipRect.R_right]
	push	bp
	call	DrawLRClippedRect
	pop	bp

	; loop if not all done

DCR_next:
	add	cs:[d_y1],bp
	sub	cs:[d_lineCount],bp
	jnz	DCR_loop

	pop	ds
	ret

;------------------------------

	; special case: must reset clipping region

DCR_setClip:
	call	WinValClipLine
	mov	bp,ds:[W_clipRect.R_bottom]
	jmp	short DCR_afterClip

;------------------------------

	; not simple region

DCR_notSimple:
	mov	si, ds:W_maskReg
	mov	si, ds:[si]
	add	si,ds:[W_clipPtr]		;test for within clip area
DCR_nsLoop:
	lodsw					;get first ON point
	cmp	ax, EOREGREC			;check for at end
	jz	DCR_next
	cmp	ax,cs:[d_x2]			;test for past right side
	jg	DCR_next

	mov	cx,ax				;cx = first ON point
	lodsw					;ax = last ON point
	cmp	ax,cs:[d_x1]			;test if before left
	jl	DCR_nsLoop

	; need to draw part of this segment
	; ax = left ON point, cx = right ON point

	push	bx
	push	si
	push	bp
	call	DrawLRClippedRect
	pop	bp
	pop	si
	pop	bx
	jmp	short DCR_nsLoop

DrawComplexRect	endp

	; this is a stub routine used to draw rectangles from other
	; modules.  it takes a near routine offset (in dgroup) in ax.

DrawRectFront	proc	far
		call	ax
MEM <		ReleaseHugeArray				>
	; changed 4/7/93 to make AutoTransfer the default
;CASIO <CasioAutoXferOff	; turn off auto-transfer	>
		ret
DrawRectFront	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawLRClippedRect

DESCRIPTION:	Draw a rectangle clipping left and right

CALLED BY:	INTERNAL
		DrawComplexRect

PASS:
	ax - right coordinate of clipping region
	cx - left coordinate of clipping region
	d_x1 - left coordinate of line
	d_x2 - right coordinate of line
	bx - top coordinate
	bp - number of lines to draw
	rectRoutine - address of low level rectangle routine
	maskPtr - offset of draw mask to use (unless using DrawOptRect)
	wDrawMode - drawing mode to use (unless using DrawOptRect)
	ds - Window structure
	es - video RAM

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

DLRCR_ret:
	retn

DrawLRClippedRect	proc  near

ifdef	LOGGING
	ornf	cs:[curRegFlags], mask RF_CALLED_DRAW_LRCLIPPED_RECT
endif

	mov	si,cs:[d_x1]
	cmp	si,ax
	jg	DLRCR_ret
	cmp	si,cx
	jg	DLRCR_10
	mov	si,cx
DLRCR_10:
	mov	di,cs:[d_x2]
	cmp	di,cx
	jl	DLRCR_ret
	cmp	di,ax
	jl	DLRCR_20
	mov	di,ax
DLRCR_20:

MEM <	call	DrawSimpleRect					>
MEM <	ReleaseHugeArray					>
MEM <	ret							>

NMEM <	FALL_THRU	DrawSimpleRect				>

DrawLRClippedRect	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	DrawSimpleRect

DESCRIPTION:	Draw a rectangle clipping left and right

CALLED BY:	INTERNAL
		VidDrawRect

PASS:
	si - left coordinate of rectangle to draw
	di - right coordinate of rectangle to draw
	bx - top coordinate
	bp - number of lines to draw
	rectRoutine - address of low level rectangle routine
	maskPtr - offset of draw mask to use (unless using DrawOptRect)
	wDrawMode - drawing mode to use (unless using DrawOptRect)
	es - video RAM

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

DrawSimpleRect	proc	near

ifdef	LOGGING
	ornf	cs:[curRegFlags], mask RF_CALLED_DRAW_SIMPLE_RECT
endif

	mov	ax,si
	mov	dx,di

ifndef	IS_CLR24
MEM  <	call	CalcDitherIndices	; for strange ditherMatrices	>
endif
ifndef	IS_CLR8
ifndef	IS_CLR24
	and	si,UNIT_MASK		;get ready for mask computation
	ShiftLeftIf16	si		;by making si and di indecies
	and	di,UNIT_MASK		;into the mask tables
	ShiftLeftIf16	di
endif
endif

	; compute word/byte indicies for endpoints

ifndef	IS_CLR8
ifndef	IS_CLR24
	mov	cl,BIT_SHIFTS			; get word/byte indeces
	shr	ax,cl				; ax = left word/byte index
	shr	dx,cl				; dx = right word/byte index
endif
endif
	sub	dx,ax				; number of words/bytes covered

	; calculate starting screen buffer address

	mov	cx,bx
	and	cx, 7				; isolate low 3 bits for idx

ifdef	IS_DIRECT_COLOR
	push	dx
ifdef	IS_MEM
	mov	dx, ax
	add	ax, ax
	add	ax, dx
else
	mul	cs:[pixelBytes]
endif
	pop	dx
elifdef	IS_CLR24
	add	ax, ax
elifndef IS_CLR8
	ShiftLeftIf16	ax			;;make word offset
endif

ifdef IS_VGA8
NMEM <	CalcScanLineBoth	bx, ax, es, es	;;make bx index into line  >
elifdef IS_VGA24
NMEM <	CalcScanLineBoth	bx, ax, es, es	;;make bx index into line  >
else
NMEM <	CalcScanLine	bx, ax			;;make bx index into line  >
endif
MEM  <	CalcScanLine	bx, ax, es					   >
						;;add offset
	xchg	bx,di				;bx = mask index, di = address

	; (EGA) compute masks and check for one word write
EGA <	mov	al,cs:[si][leftMaskTable]	;get mask		>
EGA <	mov	ah,cs:[bx][rightMaskTable]	;get mask		>
EGA <	tst	dx							>

NIKEC <	mov	al,cs:[si][leftMaskTable]	;get mask		>
NIKEC <	mov	ah,cs:[bx][rightMaskTable]	;get mask		>
NIKEC <	tst	dx							>

	; for memory video driver, check DITHER mode...
ifdef IS_MEM
MONO <	test	cs:[bm_flags], mask BM_CLUSTERED_DITHER	; check dither type >
MONO <	jnz	jumpClustered						    >
CMYK <  jmp	ClusterMux						    >
endif
rectRoutineLabel label word
rectRoutine	equ  rectRoutineLabel + 1
	.warn	-unreach
	jmp	near ptr DrawOptRect		;self modified
	.warn	@unreach

ifdef MEM_MONO
jumpClustered:	
	jmp	ClusterMux			; figure out what to do there
endif
DrawSimpleRect	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	RectSetup

DESCRIPTION:	Draw a filled rectangle with the given drawing state

CALLED BY:	GLOBAL

PASS:
	ax - left coordinate
	bx - top coordinate
	cx - right coordinate
	dx - bottom coordinate
	ds - graphics state structure
	es - Window structure
	si - offset to CommonAttr structure

RETURN:
	carry - set if bounds totally clipped
	si - address of routine to call to draw rectangles
	es - video RAM
	PSL_saveWindow - window
	ds and es pushed on the stack

DESTROYED:
	ax, bx, cx, dx, di, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

RectSetupFar	proc	far
		call	RectSetup
		pop	ax			; pop es into ax, ds into bx
		pop	bx
		pop	cx			; pop return address
		pop	dx
		push	bx			; save ds, es
		push	ax
		push	dx			; re-save return address
		push	cx
		ret
RectSetupFar	endp

RectSetup	proc	near

NMEM <	; check for collision with pointer				>

NMEM <	cmp	ax,cs:[cursorRegRight]					>
NMEM <	jg	RectS_noCollision		;to the right -> branch	>
NMEM <	cmp	cx,cs:[cursorRegLeft]					>
NMEM <	jl	RectS_noCollision		;to the left -> branch	>
NMEM <	cmp	bx,cs:[cursorRegBottom]					>
NMEM <	jg	RectS_noCollision		;to the bottom -> branch>
NMEM <	cmp	dx,cs:[cursorRegTop]					>
NMEM <	jl	RectS_noCollision		;to the top -> branch	>
NMEM <	call	CondHidePtr						>
NMEM <RectS_noCollision:						>

	; check for collision with XOR region	

NMEM <	cmp	cs:[xorRegionHandle], 0					>
NMEM <	jz	RectS_afterXOR						>
NMEM <	call	CheckXORCollision					>
NMEM <RectS_afterXOR	label	near					>

	; check for collision with save under area

NMEM <	cmp	es:[W_savedUnderMask],0					>
NMEM <	jz	RectS_noSU						>
NMEM <	call	CheckSaveUnderCollisionES				>
NMEM <RectS_noSU:							>

	; save ds and es on the stack (don't look if you do not have a
	; strong stomach)

	pop	di			;pop return address
	push	ds
	push	es
	push	di			;push return address

	; save coordinates (last one saved just below)

	mov	di,cx			;di = right
	mov	bp,dx			;bp = bottom

	; set up dither matrix and optimization flags

	CheckSetDither	cs

	test	es:[W_color], mask WCF_MASKED
	jnz	special

EGA <	mov	dx,DRAW_OPT_RECT		;assume optimal case	>
EGA <	test	ds:[si].CA_flags,mask AO_MASK_1_COPY	;test for optimal  >
EGA <	jnz	afterSpecial			;if optimal then branch	>
EGA <special:								>

NIKEC <	mov	dx,DRAW_OPT_RECT		;assume optimal case	>
NIKEC <	test	ds:[si].CA_flags,mask AO_MASK_1_COPY	;test for optimal  >
NIKEC <	jnz	afterSpecial			;if optimal then branch	>
NIKEC <special:								>

ifndef	IS_MEGA
BIT <	mov	cl,ds:[si].CA_flags		;load optimization flags >
BIT <	mov	dx,DRAW_OPT_RECT		;assume optimal case	>
BIT <	test	cl,mask AO_MASK_1_COPY					>
BIT <	jnz	afterSpecial			;if optimal then branch	>
MBIT <	mov	dx,DRAW_NOT_RECT		;assume GR_INVERT case	>
MBIT <	test	cl,mask AO_MASK_1_INVERT				>
MBIT <	jnz	afterSpecial			;if optimal then branch	>
BIT <special:								>
BIT <	mov	cx,bx							>
BIT <	mov	bl,ds:[GS_mixMode]					>
BIT <	clr	bh							>
BIT <	shl	bx,1				;;handle draw mode	>
BIT <	mov	dx,cs:[bx][drawModeTable]				>
BIT <	mov	cs:[modeRoutine],dx					>
BIT <	mov	bx,cx							>
endif

	CopyMask	<word ptr ds:[si].CA_mask>,dx
	mov	dx,DRAW_SPECIAL_RECT

afterSpecial:

	mov	cs:[rectRoutine],dx

	; ax = left, di = right, bx = top, bp = bottom

	mov	dx,es
	mov	ds,dx				;dx = window

	SetBuffer	es, dx

	; Determine if rectangle is totally unclipped

	cmp	bx,ds:[W_clipRect].R_bottom	;make sure wClip valid
	jg	RectS_setClip
	cmp	bx,ds:[W_clipRect].R_top
	jge	RectS_clipOK
RectS_setClip:
	push	ax
	push	si
	push	di
	call	WinValClipLine
	pop	di
	pop	si
	pop	ax
RectS_clipOK:

	; see if wClip spans entire rectangle in y

	cmp	bp,ds:[W_clipRect].R_bottom
	jg	RectS_complexCheck

	; we know that wClip spans the rectangle in y

	mov	cl,ds:[W_grFlags]
	test	cl,mask WGF_CLIP_NULL
	jnz	RectS_returnTotallyClipped

	cmp	di,ds:[W_clipRect].R_left
	jl	RectS_returnTotallyClipped

	cmp	ax,ds:[W_clipRect].R_right
	jg	RectS_returnTotallyClipped

	; test for simply inside region

	test	cl,mask WGF_CLIP_SIMPLE		;if not simple then we must
	jz	RectS_complexCheck		;do complex check

	cmp	ax,ds:[W_clipRect].R_left
	jl	RectS_complexCheck

	cmp	di,ds:[W_clipRect].R_right
	jg	RectS_complexCheck

	; simple case -- do it

RectS_returnTotallyInside:
	mov	si, offset DrawSimpleRect
	clc
	ret

;------------------------------------

	; bounds is totally clipped, return such

RectS_returnTotallyClipped:
	stc
	ret

;------------------------------------

	; must do scomplex bounds check
	; ax = left, di = right, bx = top, bp = bottom

RectS_complexCheck:
	mov	cx,di			;cx = right
	mov	dx,bp			;dx = bottom
	mov	si, ds:W_maskReg
	mov	si, ds:[si]
	add	si,ds:[W_clipPtr]
	stc
	call	GrTestRectInReg
	cmp	al,TRRT_IN
	jz	RectS_returnTotallyInside
	cmp	al,TRRT_OUT
	jz	RectS_returnTotallyClipped

	mov	cs:[PSL_saveWindow],ds
	mov	si, offset DrawComplexRect
	clc
	ret

RectSetup	endp
