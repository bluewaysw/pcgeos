COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video drivers
FILE:		vidcomUtils.asm

ROUTINES:
	Name			Description
	----			-----------
   GBL	CheckCursorCollision	Check for a cursor collision

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version


DESCRIPTION:
	This file contains utility routines common to all video drivers
		

	$Id: vidcomUtils.asm,v 1.1 97/04/18 11:41:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef	IS_MEM			; don't need this for memory driver


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCollisions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check out collisions with save under, pointer and XOR region.

CALLED BY:	INTERNAL

PASS:		ax,bx,cx,dx	- sorted rect coords of suspect area
		es		- window segment

RETURN:		carry		- set based on Window save under collision 
				  code

DESTROYED:	carry		- set if collision with Window save-under
				  occurred.
				  
				  NOTE:  If this is the case, then
				  WinMaskOutSaveUnder has been called on the
				  window, meaning that the save under area
				  is punched out of the Window's W_univReg,
				  W_vis_reg, & W_maskReg -- whatever is to
				  be drawn may now be partially or fully
				  masked out.

PSEUDO CODE/STRATEGY:
		check 'em, one at a time

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version
		Doug	3/5/93		Changed to return carry flag (depended
					on by PutStringLow)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCollisions	proc	far
		call	CheckCursorCollision		; check for pointer
		cmp	es:[W_savedUnderMask],0				
		clc
		jz	checkXOR
		call	CheckSaveUnderCollisionES	; check save under
checkXOR:
		pushf
		cmp	cs:[xorRegionHandle],0
		jz	done
		call	CheckXORCollision		; check XOR
done:
		popf
		ret
CheckCollisions	endp

CheckCollisionsDS proc	near
		call	CheckCursorCollision		; check for pointer
		cmp	ds:[W_savedUnderMask],0				
		clc
		jz	checkXOR
		call	CheckSaveUnderCollisionDS	; check save under
checkXOR:
		pushf
		cmp	cs:[xorRegionHandle],0
		jz	done
		call	CheckXORCollision		; check XOR
done:
		popf
		ret
CheckCollisionsDS endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckCursorCollision

DESCRIPTION:	Check to see if the save under area collides with the cursor
		and erase the cursor if so.

CALLED BY:	INTERNAL
		Utility

PASS:
	ax - left
	bx - top
	cx - right
	dx - bottom

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
	Tony	1/89		Initial version
	Jim	8/89		Changed to use signed jump-conditionals

------------------------------------------------------------------------------@

CheckCursorCollision	proc	near

	; check for collision with pointer

	cmp	ax,cs:[cursorRegRight]
	jg	CUC_noCollision			;drawing to the right -> branch
	cmp	cx,cs:[cursorRegLeft]
	jl	CUC_noCollision			;drawing to the left -> branch
	cmp	bx,cs:[cursorRegBottom]
	jg	CUC_noCollision			;drawing to the bottom -> branch
	cmp	dx,cs:[cursorRegTop]
	jl	CUC_noCollision			;drawing to the top -> branch
	call	CondHidePtr
CUC_noCollision:
	ret

CheckCursorCollision	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckSaveUnderCollision

DESCRIPTION:	Check for a collision with the save under area

CALLED BY:	INTERNAL
		CharLowCheck

PASS:
	ax - left
	bx - top
	cx - right
	dx - bottom
	ds/es - segment of window being drawn to

RETURN:
	ds/es - window (may have moved)
	cs:PSL_saveWindow - updated
	carry - set if collision occurred

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

------------------------------------------------------------------------------@

CheckSaveUnderCollisionDS	proc	near
if	SAVE_UNDER_COUNT	eq	0
	clc
else
	push	es
	segmov	es,ds
	call	CheckSaveUnderCollisionES
	segmov	ds,es
	pop	es
endif
	ret

CheckSaveUnderCollisionDS	endp

CheckSaveUnderCollisionES	proc	near
if	SAVE_UNDER_COUNT	eq	0
	clc
else
	; check for collision with save under area

	push	si
	mov	si,ax			;si = left
	mov	al,es:[W_savedUnderMask]
	tst	al				;clears carry
if	SAVE_UNDER_COUNT lt 3
	jz	CSUC_noUnderCollision
else
	jnz	CSUC_check
	jmp	CSUC_noUnderCollision
CSUC_check:
endif
	pushf					;save flags
	mov	ah,cs:[suCount]

SU_COUNT		=	0
rept	SAVE_UNDER_COUNT
SU_INDEX		=	SU_COUNT*(size SaveUnderStruct)
	dec	ah			;see if no more valid areas
if	SAVE_UNDER_COUNT - SU_COUNT lt 3
	js	CSUC_noUnderCollisionPop
else
	EBRANCH	<jns>,<CSUC_skip>,%SU_COUNT
	jmp	CSUC_noUnderCollisionPop
ELABEL	<CSUC_skip>,%SU_COUNT
endif
	test	al,cs:[suTable+SU_INDEX].SUS_flags
	EBRANCH	<jz>,<CSUC_nc>,%SU_COUNT   ;;not affected by save under, branch
	cmp	si,cs:[suTable+SU_INDEX].SUS_right
	EBRANCH	<jg>,<CSUC_nc>,%SU_COUNT	;;drawing to right -> branch
	cmp	cx,cs:[suTable+SU_INDEX].SUS_left
	EBRANCH	<jl>,<CSUC_nc>,%SU_COUNT	;;drawing to left -> branch
	cmp	bx,cs:[suTable+SU_INDEX].SUS_bottom
	EBRANCH	<jg>,<CSUC_nc>,%SU_COUNT	;;drawing to bottom -> branch
	cmp	dx,cs:[suTable+SU_INDEX].SUS_top
	EBRANCH	<jl>,<CSUC_nc>,%SU_COUNT	;;drawing to top -> branch
	call	SaveUnderCollision
	mov	cs:[PSL_saveWindow],es
	popf
	stc					;indicate collision
	pushf
ELABEL	<CSUC_nc>,%SU_COUNT
SU_COUNT	=	SU_COUNT + 1
endm
if SAVE_UNDER_COUNT gt 0
CSUC_noUnderCollisionPop:
endif
	popf					;recover flags
CSUC_noUnderCollision:
	mov	ax,si
	pop	si
endif
	ret

CheckSaveUnderCollisionES	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	SlowGenClip

DESCRIPTION:	Update clip info for line

CALLED BY:	INTERNAL
		CharGeneralSlow

PASS:
	bx - line to update for

RETURN:
	carry - set if line NULL

DESTROYED:
	ax, bx, cx, dx, ds, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/88		Initial version

------------------------------------------------------------------------------@

SlowGenClip	proc	near
	;
	; make sure that clip info is correct
	;
	mov	ds,cs:[currentWin]	; 
	cmp	bx,ds:[W_maskRect].R_top	;check for clipped wrt mask
	jl	VLM_doneClipped
	cmp	bx,ds:[W_maskRect].R_bottom
	jg	VLM_doneClipped
	cmp	bx,ds:[W_clipRect.R_bottom]		; if line is beyond bottom of region
	jg	SGC_setClip		;    reset clip variables.
	cmp	bx,ds:[W_clipRect.R_top]		; if line is below top of region
	jg	SGC_noSetClip		;    fall thru to reset clip variables.
SGC_setClip:
	push	di			;
	call	WinValClipLine		; set clip information.
	pop	di			;
SGC_noSetClip:

	FALL_THRU	ValLineMask

SlowGenClip	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ValLineMask

DESCRIPTION:	Find a block of memory of the given size and type.

CALLED BY:	INTERNAL
		SlowGenClip, RestoreScreen

PASS:
	ds - window

RETURN:
	carry - set if line NULL

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

------------------------------------------------------------------------------@

ValLineMask	proc	near
EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx							>

	mov	cl,ds:[W_grFlags]	; check clip flags for current line.
	test	cl,mask WGF_CLIP_NULL		; check if entire line is clipped.
	jnz	VLM_doneClipped		; all done if line is clipped.
	;
	; generate line mask
	;
	mov	ax,ds:[W_header.LMBH_handle]	;see if this window has line cached
	cmp	ax,cs:[lineCacheHandle]	;if line is cached then
	jnz	VLM_genBuffer		;
	test	cl,mask WGF_BUFFER_VALID	;check for data in buffer valid.
	clc				;
	jnz	VLM_done		;quit if it is.
VLM_genBuffer:
	mov	cs:[lineCacheHandle],ax	;mark line as cached
	push	di			;save registers.
	push	es			;

	; set up pointer to lineMaskBuffer.  For the video memory driver,
	; this is in the bitmap structure... 

MEM  <	mov	es, ds:[W_bmSegment]	; get segment of bitmap		>
MEM  <	mov	ax, es:[EB_bm].CB_simple.B_width ; get pixel width	>
MEM  <	mov	di, size EditableBitmap					>

	;  ...instead of the core block 

NMEM <	segmov	es,cs			;				>
NMEM <	mov	di, offset lineMaskBuffer				>
FRES <	mov	ax, SCREEN_PIXEL_WIDTH	;				>
MRES <	mov	ax, cs:[DriverTable].VDI_pageW	;			>

	call	WinGenLineMask		;generate mask for line.
	pop	es			;
	pop	di			;
	clc				;
VLM_done:
	ret				;

VLM_doneClipped label near
	stc
	ret

ValLineMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetResetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	determine the resetColor, based on type of driver, ON_BLACK
		bit, etc.

CALLED BY:	SetDither, others
PASS:		dh	- colorMapMode

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetResetColorFar proc	far
		call	SetResetColor
		ret
SetResetColorFar endp

SetResetColor	proc	near
		uses	dx
		.enter

		; we also need to set the setColor and resetColor, even 
		; though we aren't monochrome (used for drawing mono bitmaps
		; that have a mask)

		test	dh, mask CMM_ON_BLACK
		mov	dx, 0				;  assume so

		; this label is here for mono driver that want to invert 
		; the output image.  They can do this by inverting the 
		; low bit of this byte, thus changing a jnz to a jz

ifdef	IS_MONO
NMEM <invertImage label	byte						>
endif
NMEM <		jnz	onBlack						>
MEM  <		jz	onBlack						>
		not	dx				; use all 1s
onBlack:
		mov	cs:[resetColor], dx
		not	dx
		mov	cs:[setColor], dx

		.leave
		ret
SetResetColor	endp

	; this is some common dithering code for both VGAlike and 4-bit
	; vidmem video drivers.


ifdef	IS_CLR4

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a dither pattern for VGAlike devices

CALLED BY:	various drawing routines

PASS:		ds:si	-> CommonAttr structure
		es	-> Window structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Color dither for 4-bit color is a bit strange.  There are 
		essentially two sets of one-bit per component RGB colors
		in the standard 16-color palette.  The range of each component
		is 170/255 for each set, the first set having the binary
		values 0,170; and the second set having the values 85,255.
		To dither, we analyze each component separately, building 
		three 4x4 dither matrices.  For each pixel, we can then 
		construct a 3-bit value that we can use to index into half 
		of the palette.  We choose which group to access by the 
		minimum value of the three components.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDither	proc	far
		uses	ax,bx,cx,dx,es,di
		.enter

		; get the values of the color components we are building the
		; matrix for.  

		mov	cl, ds:[si].CA_colorRGB.RGB_red
		mov	ch, ds:[si].CA_colorRGB.RGB_green
		mov	bl, ds:[si].CA_colorRGB.RGB_blue
		mov	ax, es:[W_pattPos]		; get patt ref point

ifdef	BIT_CLR4

;	We have to reset the dither matrix if it is set with a color index
;	instead.

		tst	cs:[ditherOrColor]
		jz	setNewDither
endif

		; check to see if we really need to re-create it.  If the color
		; is the same, and the shift amount is the same, then we're OK.

		cmp	cl, cs:[ditherColor].RGB_red
		jne	setNewDither
		cmp	ch, cs:[ditherColor].RGB_green
		jne	setNewDither
		cmp	bl, cs:[ditherColor].RGB_blue
		jne	setNewDither
		
		; besides the color, we should check the rotation.

		cmp	ax, {word} cs:[ditherRotX]	; same ?
		LONG je	done

		; set up es:di -> at the dither matrix we are about to fill
setNewDither:
ifdef	BIT_CLR4

;	Note that we are setting a dither pattern

		mov	cs:[ditherOrColor], DOC_MATRIX_HOLDS_DITHER_PATTERN
endif
		mov	cs:[ditherColor].RGB_red, cl	; set new color
		mov	cs:[ditherColor].RGB_green, ch
		mov	cs:[ditherColor].RGB_blue, bl
		mov	{word} cs:[ditherRotX], ax	; set rotation value

		segmov	es, cs, di
		mov	di, offset ditherMatrix

		; calculate the luminence of the pixel, and use that to dither
		; the fourth (hightlight) plane.

		mov	ax, cx			; al=red, ah-green, bl=blue
		call	GrCalcLuminance		; al = luminance
		mov	bh, al			; move luminance into bh

		; break down the components so that each is an index into
		; the appropriate dither matrix component tables...
		; we have tables with 17 entries, so we round up by 1/2 and
		; shift right 4 times.  Since the entries are 4 bytes each, we
		; shift back to the left 2 times.  That leaves 2 shift right
		; and an AND.

		mov	dx, cx			; save it here since we use cl
		mov	cl, 4
		shr	dl, cl			; divide each by 16
		adc	dl, 0
		shr	dh, cl			; divide each by 16
		adc	dh, 0
		shr	bl, cl			; divide each by 16
		adc	bl, 0
		shr	bh, cl			; divide each by 16
		adc	bh, 0
EGA <		mov	cl, 2			; *4			> 
NIKEC <		mov	cl, 2			; *4			>
ifdef	BIT_CLR4
		mov	cl, 3			; *8
endif
		shl	bx, cl
		shl	dx, cl
		mov	cx, dx
		
		; now we just copy over the values for each plane
ifdef	IS_VGALIKE

		mov	dh, bh
		clr	bh
		mov	ax, {word} cs:[colorDither][bx]	; only four to move
		stosw				; doing blue first (plane 0)
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw		
		mov	bl, ch			; now do green plane (plane 1)
		mov	ax, {word} cs:[colorDither][bx]
		stosw
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw
		mov	bl, cl			; finally, do red
		mov	ax, {word} cs:[colorDither][bx]
		stosw
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw
		mov	bl, dh			; restore luminence
		mov	ax, {word} cs:[colorDither][bx]
		stosw
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw

else
ifdef	IS_NIKE_COLOR

		mov	dh, bh
		clr	bh
		mov	ax, {word} cs:[colorDither][bx]	; only four to move
		stosw				; doing blue first (plane 0)
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw		
		mov	bl, ch			; now do green plane (plane 1)
		mov	ax, {word} cs:[colorDither][bx]
		stosw
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw
		mov	bl, cl			; finally, do red
		mov	ax, {word} cs:[colorDither][bx]
		stosw
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw
		mov	bl, dh			; restore luminence
		mov	ax, {word} cs:[colorDither][bx]
		stosw
		mov	ax, {word} cs:[colorDither+2][bx]
		stosw

else
		; for VIDMEM, we have packed pixels for the ditherMatrix,
		; so we use a slightly different procedure
		; now we OR together the components of each separate dither

		mov	dh, bh			   ; use bx as adressing reg
		clr	bh
		mov	ax, {word} cs:[blueDither][bx]	   ; get blue component
		xchg	bl, cl			   ; get red component
		or	ax, {word} cs:[redDither][bx]	
		xchg	bl, ch			   ; get green component
		or	ax, {word} cs:[greenDither][bx]   ;
		xchg	bl, dh			   ;  dh = green
		or	ax, {word} cs:[hiliteDither][bx]  ; bl=hilite,ch=red,
		stosw				   ; cl=blue. Store 1st scan

		mov	ax, {word} cs:[hiliteDither+2][bx]; 
		xchg	bl, dh			   ; 
		or	ax, {word} cs:[greenDither+2][bx] ; 
		xchg	bl, ch
		or	ax, {word} cs:[redDither+2][bx]   ; do red 
		xchg	bl, cl			   ; do blue
		or	ax, {word} cs:[blueDither+2][bx]  ; bl=blue,cl=red,

		stosw				   ;  ch=green,dh = hilite

		mov	ax, {word} cs:[blueDither+4][bx]  ; get blue component
		xchg	bl, cl			   ; get red component
		or	ax, {word} cs:[redDither+4][bx]	
		xchg	bl, ch			   ; get green component
		or	ax, {word} cs:[greenDither+4][bx] ;
		xchg	bl, dh			   ;  dh = green
		or	ax, {word} cs:[hiliteDither+4][bx]; bl=hilite,ch=red,

		stosw				   ; cl=blue. Store 3rd scan

		mov	ax, {word} cs:[hiliteDither+6][bx]; 
		xchg	bl, dh			   ; 
		or	ax, {word} cs:[greenDither+6][bx] ; do next two pixels
		xchg	bl, ch
		or	ax, {word} cs:[redDither+6][bx]   ; do red 
		xchg	bl, cl			   ; do blue
		or	ax, {word} cs:[blueDither+6][bx]  ; bl=blue, cl=red,

		stosw				   ;  ch=green,dh=hilite
endif
endif

		; all done storing new pattern.  Now rotate it into place
		
		call	RotateDither
ifdef	BIT_CLR4
ifdef	LEFT_PIXEL_IN_LOW_NIBBLE

;	If the frame buffer is nibble-swapped, nibble swap the ditherMatrix

		mov	cl, 4
		ror	cs:[ditherMatrix], cl
		ror	cs:[ditherMatrix+1], cl
		ror	cs:[ditherMatrix+2], cl
		ror	cs:[ditherMatrix+3], cl
		ror	cs:[ditherMatrix+4], cl
		ror	cs:[ditherMatrix+5], cl
		ror	cs:[ditherMatrix+6], cl
		ror	cs:[ditherMatrix+7], cl
endif
endif

done:
		.leave
		ret
SetDither	endp


ifdef	IS_VGALIKE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate the dither pattern to it's proper place

CALLED BY:	SetDither
PASS:		dither matrix set up
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		rotate the pattern around the appropriate number of bits

		This function rotates 4 8x4 1-bit/pixel dithers

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateDither	proc	near
		uses	ax, bx, cx, ds, si
		.enter

		; if the new ditherRotation is zero, skip all this

		mov	cx, {word} cs:[ditherRotX]
		and	cx, 0307h		; isolate important bits
		jz	done

		; load up the dither patterns.  Do them one by one.

		segmov	ds, cs, si
		mov	si, offset ditherMatrix
		call	Rotate4x8
		mov	si, offset ditherMatrix+4
		call	Rotate4x8
		mov	si, offset ditherMatrix+8
		call	Rotate4x8
		mov	si, offset ditherMatrix+12
		call	Rotate4x8
done:
		.leave
		ret
RotateDither	endp

Rotate4x8	proc	near
		
		; ds:si -> 4 bytes to rotate.

		mov	ax, ds:[si]		; al = first scan, ah = 2nd
		mov	bx, ds:[si+2]		; bl = 3rd, bh = 4th
		tst	cl
		jz	rotateInY

		; just rotate those little bits around

		ror	al, cl
		ror	ah, cl
		ror	bl, cl
		ror	bh, cl

		; now swap the bytes to effect a rotation in y
rotateInY:
		tst	ch			; see if any necc
		jz	storeEm
		cmp	ch, 2			; must be 1, 2, or 3
		ja	swap3			;  3...
		je	swap2			;  2...

		; rotate around by one spot, so:
		;   al <- bh, ah <- al, bl <- ah, bh <- bl

		xchg	ah, al			; ah <- al
		xchg	bl, al			; bl <- ah
		xchg	bh, al			; bh <- bl, al <- bh
storeEm:
		mov	ds:[si], ax		; store new ditherMatrix
		mov	ds:[si+2], bx
		ret

		; rotate around by two spots, so:
		;   al <- bl, ah <- bh, bl <- al, bh <- ah
swap2:
		xchg	al, bl
		xchg	ah, bh
		jmp	storeEm

		; rotate around by three spots, so:
		;   al <- ah, ah <- bl, bl <- bh, bh <- al
swap3:
		xchg	al, bh			; bh <- al
		xchg	al, bl			; bl <- bh
		xchg	al, ah			; al <- ah, ah <- bl
		jmp	storeEm
Rotate4x8	endp

else	; not IS_VGALIKE

ifdef	IS_NIKE_COLOR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rotate the dither pattern to it's proper place

CALLED BY:	SetDither
PASS:		dither matrix set up
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		rotate the pattern around the appropriate number of bits

		This function rotates 4 8x4 1-bit/pixel dithers

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateDither	proc	near
		uses	ax, bx, cx, ds, si
		.enter

		; if the new ditherRotation is zero, skip all this

		mov	cx, {word} cs:[ditherRotX]
		and	cx, 0307h		; isolate important bits
		jz	done

		; load up the dither patterns.  Do them one by one.

		segmov	ds, cs, si
		mov	si, offset ditherMatrix
		call	Rotate4x8
		mov	si, offset ditherMatrix+4
		call	Rotate4x8
		mov	si, offset ditherMatrix+8
		call	Rotate4x8
		mov	si, offset ditherMatrix+12
		call	Rotate4x8
done:
		.leave
		ret
RotateDither	endp

Rotate4x8	proc	near
		
		; ds:si -> 4 bytes to rotate.

		mov	ax, ds:[si]		; al = first scan, ah = 2nd
		mov	bx, ds:[si+2]		; bl = 3rd, bh = 4th
		tst	cl
		jz	rotateInY

		; just rotate those little bits around

		ror	al, cl
		ror	ah, cl
		ror	bl, cl
		ror	bh, cl

		; now swap the bytes to effect a rotation in y
rotateInY:
		tst	ch			; see if any necc
		jz	storeEm
		cmp	ch, 2			; must be 1, 2, or 3
		ja	swap3			;  3...
		je	swap2			;  2...

		; rotate around by one spot, so:
		;   al <- bh, ah <- al, bl <- ah, bh <- bl

		xchg	ah, al			; ah <- al
		xchg	bl, al			; bl <- ah
		xchg	bh, al			; bh <- bl, al <- bh
storeEm:
		mov	ds:[si], ax		; store new ditherMatrix
		mov	ds:[si+2], bx
		ret

		; rotate around by two spots, so:
		;   al <- bl, ah <- bh, bl <- al, bh <- ah
swap2:
		xchg	al, bl
		xchg	ah, bh
		jmp	storeEm

		; rotate around by three spots, so:
		;   al <- ah, ah <- bl, bl <- bh, bh <- al
swap3:
		xchg	al, bh			; bh <- al
		xchg	al, bl			; bl <- bh
		xchg	al, ah			; al <- ah, ah <- bl
		jmp	storeEm
Rotate4x8	endp

else	; (not IS_VGALIKE) and (not IS_NIKE_COLOR)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateDither
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Align the ditherMatrix with the screen

CALLED BY:	SetDither
PASS:		dither variables setup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		we have a single 4-bit packed pixel ditherMatrix.  You know
		the rest.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/20/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateDither	proc	near
		uses	ax,bx,cx,dx,di
		.enter

		; load up the ditherMatrix.  We have 4 words, use ax,bx,dx,di

		mov	ax, {word} cs:[ditherMatrix]
		mov	bx, {word} cs:[ditherMatrix+2]
		mov	dx, {word} cs:[ditherMatrix+4]
		mov	di, {word} cs:[ditherMatrix+6]

		; we only need to rotate in X if the low bit is set, since
		; we have packed pixels

		mov	cx, {word} cs:[ditherRotX]	; get pixel position
		test	cl, 1				; check low bit
		jz	checkY

		; we need to swap the nibbles in each byte

		mov	cl, 4
		ror	al, cl
		ror	ah, cl
		ror	bl, cl
		ror	bh, cl
		ror	dl, cl
		ror	dh, cl
		xchg	di, ax
		ror	ah, cl
		ror	al, cl
		xchg	di, ax

		; now check for rotation in y
checkY:
		and	ch, 3				; isolate low 2 bits
		jz	storeEm
		cmp	ch, 2				; either 1,2 or 3
		je	swap2
		ja	swap3

		; rotate around by one spot, so:
		;   ax <- di, bx <- ax, dx <- bx, di <- dx

		xchg	bx, ax			; bx <- ax
		xchg	dx, ax			; dx <- bx
		xchg	di, ax			; di <- dx, ax <- di
storeEm:
		.leave
		ret

		; rotate around by two spots, so:
		;   ax <- dx, bx <- di, dx <- ax, di <- bx
swap2:
		xchg	ax, dx
		xchg	bx, di
		jmp	storeEm

		; rotate around by three spots, so:
		;   ax <- bx, bx <- dx, dx <- di, di <- ax
swap3:
		xchg	ax, di			; di <- ax
		xchg	ax, dx			; dx <- di
		xchg	ax, bx			; ax <- bx, bx <- dx
		jmp	storeEm
RotateDither	endp

endif	; not NIKECOLOR
endif	; not VGALIKE

endif
