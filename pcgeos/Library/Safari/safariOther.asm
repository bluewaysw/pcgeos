COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	GeoSafari
FILE:		safariBitmap.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/5/99		Initial revision

DESCRIPTION:
	Code for loading and drawing bitmaps

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include safariGeode.def
include safariConstant.def

idata	segment
	SafariGlyphClass
	SafariButtonClass
	SafariBackgroundClass
	SafariFeedbackClass
	SafariTimebarClass
	SafariScoreClass
idata	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariGlyphRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a glyph

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariGlyphRecalcSize	method dynamic	SafariGlyphClass,
					MSG_VIS_RECALC_SIZE
		clr	cx, dx
		movdw	bxsi, ds:[di].SGI_offBitmap
		tst	bx
		jz	done
		push	bx
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]			;ds:si <- Bitmap
		call	GrGetBitmapSize
		mov	cx, ax				;cx <- x size
		mov	dx, bx				;dx <- y size
		pop	bx
		call	MemUnlock
done:
		ret
SafariGlyphRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariGlyphDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw a button

CALLED BY:	MSG_VIS_DRAW

PASS:		none
RETURN:		bp - handle of GState
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariGlyphDraw	method dynamic	SafariGlyphClass,
					MSG_VIS_DRAW
gstate		local	hptr	push	bp
pos		local	Point
		.enter

	;
	; get our position to draw at
	;
		call	VisGetBounds
		mov	ss:pos.P_x, ax
		mov	ss:pos.P_y, bx

	;
	; figure out which bitmap to use
	;
		movdw	bxax, ds:[di].SGI_offBitmap
		tst	ds:[di].SGI_state
		jz	gotBitmap
		tst	ds:[di].SGI_onBitmap.handle
		jz	gotBitmap
		movdw	bxax, ds:[di].SGI_onBitmap
gotBitmap:
		tst	bx
		jz	done
	;
	; lock the bitmap and draw it
	;

		mov	si, ax				;si <- Bitmap chunk
		push	bx
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]			;ds:si <- Bitmap
		mov	ax, ss:pos.P_x
		mov	bx, ss:pos.P_y			;(ax,bx) <- pos
		clr	dx				;dx <- no callback
		mov	di, ss:gstate			;di <- GState
		call	GrDrawBitmap

		pop	bx
		call	MemUnlock
done:

		.leave
		ret
SafariGlyphDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariGlyphSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the state of a glyph

CALLED BY:	MSG_SAFARI_GLYPH_SET_STATE

PASS:		cl - state (on=TRUE)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/8/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariGlyphSetState	method dynamic	SafariGlyphClass,
					MSG_SAFARI_GLYPH_SET_STATE
		mov	ds:[di].SGI_state, cl
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		GOTO	ObjCallInstanceNoLock
SafariGlyphSetState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariGlyphSetOnBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the "on" bitmap

CALLED BY:	MSG_SAFARI_GLYPH_SET_ON_BITMAP

PASS:		cx:dx - optr of bitmap
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/8/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariGlyphSetOnBitmap	method dynamic	SafariGlyphClass,
					MSG_SAFARI_GLYPH_SET_ON_BITMAP
		movdw	ds:[di].SGI_onBitmap, cxdx
		GOTO	SetBitmapCommon
SafariGlyphSetOnBitmap	endm

SafariGlyphSetOffBitmap	method dynamic	SafariGlyphClass,
					MSG_SAFARI_GLYPH_SET_OFF_BITMAP
		movdw	ds:[di].SGI_offBitmap, cxdx
		FALL_THRU SetBitmapCommon
SafariGlyphSetOffBitmap	endm

SetBitmapCommon	proc	far
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		GOTO	ObjCallInstanceNoLock
SetBitmapCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariButtonStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle a mouse click

CALLED BY:	MSG_META_START_SELECT

PASS:		(cx,dx) - (x,y)
		bp.low = ButtonInfo
		bp.high = ShiftState
RETURN:		ax - MouseReturnFlags
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariButtonStartSelect	method dynamic	SafariButtonClass,
					MSG_META_START_SELECT
	;
	; quit if not the button click we want
	;
		test	bp, mask BI_B0_DOWN
		jz	quit				;branch if not click

		call	VisGrabMouse
		mov	cl, TRUE			;cl <- TRUE
		mov	ax, MSG_SAFARI_GLYPH_SET_STATE
		call	ObjCallInstanceNoLock

quit:
		mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
		ret
SafariButtonStartSelect	endm

SafariButtonEndSelect	method dynamic	SafariButtonClass,
					MSG_META_END_SELECT

		tst	ds:[di].SGI_state
		jz	quit

	;
	; release the mouse
	;
		call	VisReleaseMouse

	;
	; send out the message
	;
		push	si
		mov	ax, ds:[di].SBI_message
		mov	bx, ds:[di].SBI_destination.handle
		mov	si, ds:[di].SBI_destination.offset
		mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	si
	;
	; redraw
	;
		mov	ax, MSG_SAFARI_GLYPH_SET_STATE
		clr	cl				;cl <- off
		call	ObjCallInstanceNoLock

quit:
		mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
		ret
SafariButtonEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariBackgroundDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw a background

CALLED BY:	MSG_VIS_DRAW

PASS:		none
RETURN:		bp - handle of GState
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariBackgroundDraw	method dynamic	SafariBackgroundClass,
					MSG_VIS_DRAW
gstate		local	hptr	push	bp
bounds		local	Rectangle
bitmap		local	optr
		uses	ax, cx, ds, si
		.enter

		movdw	ss:bitmap, ds:[di].SBI_background, ax
		mov	al, ds:[di].SBI_color

		mov	di, ss:gstate
		call	GrSaveState
	;
	; set the area color
	;
		mov	ah, CF_INDEX
		call	GrSetAreaColor
	;
	; get our position to draw at
	;
		call	VisGetBounds
		mov	ss:bounds.R_left, ax
		mov	ss:bounds.R_top, bx
		mov	ss:bounds.R_right, cx
		mov	ss:bounds.R_bottom, bx
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		call	GrFillRect
	;
	; lock the bitmap and draw it
	;
		movdw	bxsi, ss:bitmap			;^lbx:si <- Bitmap
		tst	bx				;any Bitmap?
		jz	noBitmap
		push	bx
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]			;ds:si <- Bitmap
		mov	ax, ss:bounds.R_left
		mov	bx, ss:bounds.R_top		;(ax,bx) <- pos
		clr	dx				;dx <- no callback
		call	GrDrawBitmap
		pop	bx
		call	MemUnlock
noBitmap:
		call	GrRestoreState

		.leave
	;
	; call our superclass to draw our children
	;
		mov	di, offset SafariBackgroundClass
		GOTO	ObjCallSuperNoLock
SafariBackgroundDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariFeedbackRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a feedback thingy

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariFeedbackRecalcSize	method dynamic	SafariFeedbackClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, SAFARI_FEEDBACK_WIDTH
		mov	dx, SAFARI_FEEDBACK_HEIGHT
		ret
SafariFeedbackRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariFeedbackDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw a feedback thingy

CALLED BY:	MSG_VIS_DRAW

PASS:		none
RETURN:		bp - GState
		cl - DrawFlags
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariFeedbackDraw	method dynamic	SafariFeedbackClass,
					MSG_VIS_DRAW
		mov	di, bp				;di <- GState
		mov	ax, C_BLACK
		call	GrSetAreaColor
		call	VisCheckIfVisGrown
		jnc	done
		call	VisGetBounds
		call	GrFillRect
done:
		ret
SafariFeedbackDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariFeedbackFlashOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw a feedback thingy

CALLED BY:	MSG_SAFARI_FEEDBACK_FLASH_ON

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariFeedbackFlashOn	method dynamic	SafariFeedbackClass,
					MSG_SAFARI_FEEDBACK_FLASH_ON
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		mov	di, bp				;di <- GState

		mov	ax, C_LIGHT_RED
		call	GrSetAreaColor
		call	VisGetBounds
		inc	ax
		inc	bx
		dec	cx
		dec	dx
		call	GrFillRect

		call	GrDestroyState

		mov	al, TIMER_EVENT_ONE_SHOT
		mov	bx, ds:OLMBH_header.LMBH_handle
		mov	dx, MSG_SAFARI_FEEDBACK_FLASH_OFF
		mov	cx, 30				;cx <- first time
		clr	di
		GOTO	TimerStart
SafariFeedbackFlashOn	endm

SafariFeedbackFlashOff	method dynamic SafariFeedbackClass,
					MSG_SAFARI_FEEDBACK_FLASH_OFF
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		mov	di, bp				;di <- GState

		mov	ax, C_BLACK
		call	GrSetAreaColor
		call	VisGetBounds
		call	GrFillRect

		GOTO	GrDestroyState
SafariFeedbackFlashOff	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariFeedbackStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start giving feedback

CALLED BY:	MSG_SAFARI_FEEDBACK_START

PASS:		dl - red
		cl - green
		ch - blue
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FEEDBACK_TAIL_LENGTH	equ	64
FEEDBACK_STEP_SIZE	equ	4
FEEDBACK_SPEED		equ	FEEDBACK_TAIL_LENGTH/2

SafariFeedbackStart	method dynamic	SafariFeedbackClass,
					MSG_SAFARI_FEEDBACK_START
	;
	; save the starting color
	;
		mov	ds:[di].SFI_color.CQ_info, CF_RGB
		mov	ds:[di].SFI_color.CQ_redOrIndex, dl
		mov	ds:[di].SFI_color.CQ_green, cl
		mov	ds:[di].SFI_color.CQ_blue, ch
		tst	ds:[di].SFI_timer
		jnz	done				;don't start new

		mov	ax, 0
		mov	bx, -FEEDBACK_TAIL_LENGTH
		cmp	ds:[di].SFI_direction, 0
		jge	gotX
		mov	ax, SAFARI_FEEDBACK_WIDTH
		neg	bx
gotX:
		mov	ds:[di].SFI_curX1, ax
		add	ax, bx
		mov	ds:[di].SFI_curX2, ax
	;
	; start a timer
	;
		push	di
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:OLMBH_header.LMBH_handle	;^lbx:si <- OD (us)
		mov	dx, MSG_SAFARI_FEEDBACK_COUNTDOWN
		mov	cx, 0				;cx <- first time
		mov	di, 3				;di <- interval
		call	TimerStart
		pop	di
		mov	ds:[di].SFI_timer, bx
done:
		ret
SafariFeedbackStart	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariFeedbackCountdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	one step of giving feedback

CALLED BY:	MSG_SAFARI_FEEDBACK_COUNTDOWN

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FBUpdateColor	proc	near
		mov	al, ss:[bx]
		sub	al, 256 / (FEEDBACK_TAIL_LENGTH / FEEDBACK_STEP_SIZE)
		jnc	gotColor
		clr	al
gotColor:
		mov	ss:[bx], al
		ret
FBUpdateColor	endp

FBUpdateColors	proc	near
		.enter	inherit SafariFeedbackCountdown

		lea	bx, ss:color.CQ_redOrIndex
		call	FBUpdateColor
		lea	bx, ss:color.CQ_green
		call	FBUpdateColor
		lea	bx, ss:color.CQ_blue
		call	FBUpdateColor

		.leave
		ret
FBUpdateColors	endp

FBBlackRect	proc	near
		push	ax
		mov	ax, C_BLACK or CF_INDEX shl 8
		call	GrSetAreaColor
		pop	ax
		mov	bx, 0
		mov	dx, SAFARI_FEEDBACK_HEIGHT
		GOTO	FBFillRect
FBBlackRect	endp

FBColorRect	proc	near
		.enter	inherit SafariFeedbackCountdown

		push	ax
		mov	ax, {word} ss:color
		mov	bx, {word} ss:color+2
		call	GrSetAreaColor
		pop	ax
		mov	bx, 1
		mov	dx, SAFARI_FEEDBACK_HEIGHT-1

		.leave
		FALL_THRU FBFillRect
FBColorRect	endp

FBFillRect	proc	near
		uses	ax, bx, cx, dx
		.enter	inherit	SafariFeedbackCountdown

		add	ax, ss:pos.P_x
		add	bx, ss:pos.P_y
		add	cx, ss:pos.P_x
		add	dx, ss:pos.P_y
		call	GrFillRect

		.leave
		ret
FBFillRect	endp

FBStopTimer	proc	near
		class	SafariFeedbackClass
		uses	di
		.enter	inherit SafariFeedbackCountdown

		mov	di, ds:[si]
		add	di, ds:[di].SafariFeedback_offset
		clr	ax, bx
		xchg	bx, ds:[di].SFI_timer
		call	TimerStop

		.leave
		ret
FBStopTimer	endp

SafariFeedbackCountdown	method dynamic	SafariFeedbackClass,
					MSG_SAFARI_FEEDBACK_COUNTDOWN
curX		local	word
endX		local	word
dir		local	word
pos		local	Point
color		local	ColorQuad

		.enter

		call	VisCheckIfVisGrown
		jnc	quit

	;
	; grab instance data while it's handy
	;
		mov	ax, ds:[di].SFI_direction
		mov	ss:dir, ax
		mov	ax, ds:[di].SFI_curX1
		mov	ss:curX, ax
		mov	ax, ds:[di].SFI_curX2
		mov	ss:endX, ax
		mov	ax, {word}ds:[di].SFI_color
		mov	{word} ss:color, ax
		mov	ax, {word}ds:[di].SFI_color+2
		mov	{word} ss:color+2, ax

		call	VisGetBounds
		mov	ss:pos.P_x, ax
		mov	ss:pos.P_y, bx

		push	bp, si
		push	ax, bx, cx, dx
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock
		pop	ax, bx, cx, dx
		mov	di, bp				;di <- GState
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect
		pop	bp, si

		tst	ss:dir
		js	goLeft
		call	FBDrawRight

done:
		call	GrDestroyState
quit:
		.leave
		ret

goLeft:
		call	FBDrawLeft
		jmp	done

SafariFeedbackCountdown	endm

FBDrawLeft	proc	near
		class	SafariFeedbackClass
		.enter	inherit	SafariFeedbackCountdown

	;
	; update the x position
	;
		
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].SafariFeedback_offset
		sub	ds:[di].SFI_curX1, FEEDBACK_SPEED
		sub	ds:[di].SFI_curX2, FEEDBACK_SPEED
		mov	ax, ds:[di].SFI_curX2
		pop	di
	;
	; see if we're done
	;
		cmp	ax, 0
		jl	doneStop
xLoop:
	;
	; draw a rectangle in the appropriate color
	;
		mov	ax, ss:curX
		mov	cx, ax
		add	cx, FEEDBACK_STEP_SIZE
		call	FBColorRect
	;
	; update the positions and check for end
	;
		add	ss:curX, FEEDBACK_STEP_SIZE
		mov	ax, ss:curX
		cmp	ax, ss:endX
		jg	done
	;
	; update the color
	;
		call	FBUpdateColors
		jmp	xLoop

	;
	; erase anything that's left
	;
doneStop:
		call	FBStopTimer
		clr	ax
		jmp	done2
done:
		mov	ax, ss:endX
done2:
		mov	cx, SAFARI_FEEDBACK_WIDTH
		call	FBBlackRect

		.leave
		ret
FBDrawLeft	endp

FBDrawRight	proc	near
		class	SafariFeedbackClass
		.enter	inherit	SafariFeedbackCountdown

	;
	; update the x position
	;
		
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].SafariFeedback_offset
		add	ds:[di].SFI_curX1, FEEDBACK_SPEED
		add	ds:[di].SFI_curX2, FEEDBACK_SPEED
		mov	ax, ds:[di].SFI_curX2
		pop	di
	;
	; see if we're done
	;
		cmp	ax, SAFARI_FEEDBACK_WIDTH
		jg	doneStop
xLoop:
	;
	; draw a rectangle
	;
		mov	ax, ss:curX
		mov	cx, ax
		add	cx, FEEDBACK_STEP_SIZE
		call	FBColorRect
	;
	; update the positions and check for end
	;
		sub	ss:curX, FEEDBACK_STEP_SIZE
		mov	ax, ss:curX
		cmp	ax, ss:endX
		jl	done
	;
	; update the color
	;
		call	FBUpdateColors
		jmp	xLoop

	;
	; erase anything that's left
	;
doneStop:
		call	FBStopTimer
		mov	ax, SAFARI_FEEDBACK_WIDTH
		jmp	done2

done:
		mov	ax, ss:endX
done2:
		clr	cx
		call	FBBlackRect

		.leave
		ret
FBDrawRight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariTimebarResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return our new size

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariTimebarResize	method dynamic SafariTimebarClass, MSG_VIS_RECALC_SIZE
		mov	cx, SAFARI_TIMEBAR_WIDTH
		mov	dx, SAFARI_TIMEBAR_HEIGHT
		ret
SafariTimebarResize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariTimebarSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return our new size

CALLED BY:	MSG_VIS_RECALC_SIZE

PASSS:		cl - time left
		ch - maximum time
		dl - SafariTimebarState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariTimebarSetState	method dynamic SafariTimebarClass,
						MSG_SAFARI_TIMEBAR_SET_STATE
		mov	{word} ds:[di].STBI_count, cx
		mov	ds:[di].STBI_state, dl
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		GOTO	ObjCallInstanceNoLock
SafariTimebarSetState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariTimebarDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return our new size

CALLED BY:	MSG_VIS_DRAW

PASSS:		bp - GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/6/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

redColors RGBValue <
	0x90, 0x00, 0x00
>,<
	0xc0, 0x00, 0x00
>,<
	0xe0, 0x00, 0x00
>,<
	0xe0, 0x00, 0x00
>,<
	0xf8, 0x00, 0x00
>,<
	0xf8, 0x00, 0x00
>,<
	0xe0, 0x00, 0x00
>,<
	0xe0, 0x00, 0x00
>,<
	0xc0, 0x00, 0x00
>,<
	0x90, 0x00, 0x00
>

greenColors RGBValue <
	0x00, 0x90, 0x00
>,<
	0x00, 0xc0, 0x00
>,<
	0x00, 0xe0, 0x00
>,<
	0x00, 0xe0, 0x00
>,<
	0x00, 0xf8, 0x00
>,<
	0x00, 0xf8, 0x00
>,<
	0x00, 0xe0, 0x00
>,<
	0x00, 0xe0, 0x00
>,<
	0x00, 0xc0, 0x00
>,<
	0x00, 0x90, 0x00
>

yellowColors RGBValue <
	0x90, 0x90, 0x00
>,<
	0xc0, 0xc0, 0x00
>,<
	0xe0, 0xe0, 0x00
>,<
	0xe0, 0xe0, 0x00
>,<
	0xf8, 0xf8, 0x00
>,<
	0xf8, 0xf8, 0x00
>,<
	0xe0, 0xe0, 0x00
>,<
	0xe0, 0xe0, 0x00
>,<
	0xc0, 0xc0, 0x00
>,<
	0x90, 0x90, 0x00
>

CheckHack <length redColors eq length yellowColors>
CheckHack <length redColors eq length greenColors>
CheckHack <length redColors eq SAFARI_TIMEBAR_WIDTH>

DrawBar	proc	near
		uses	ax
		.enter	inherit SafariTimebarDraw

xLoop:
	;
	; set the color
	;
		push	ax, bx
		mov	al, cs:[si].RGB_red
		mov	bl, cs:[si].RGB_green
		mov	bh, cs:[si].RGB_blue
		mov	ah, CF_RGB
		call	GrSetAreaColor
		pop	ax, bx
	;
	; draw the rectangle
	;
		push	cx
		mov	cx, ax
		inc	cx				;cx <- right side
		call	GrFillRect
		pop	cx
	;
	; loop until done
	;
		add	si, (size RGBValue)		;cs:si <- next color
		inc	ax
		cmp	ax, cx
		jb	xLoop

		.leave
		ret
DrawBar	endp

DrawTickmarks	proc	near
		.enter	inherit	SafariTimebarDraw

	;
	; set the line color
	;
		push	ax
		mov	al, ss:tickColor
CheckHack <CF_INDEX eq 0>
		clr	ah
		call	GrSetLineColor
		pop	ax
	;
	; align to interval
	;
		add	dx, SAFARI_TIMEBAR_HEIGHT/6 - 1
		andnf	dx, not ((SAFARI_TIMEBAR_HEIGHT/6) - 1)
		xchg	bx, dx				;bx <- top, dx <- bot
	;
	; draw to the bottom
	;
yLoop:
		cmp	bx, dx
		jae	done
		call	GrDrawHLine
		add	bx, SAFARI_TIMEBAR_HEIGHT/6
		jmp	yLoop
done:

		.leave
		ret
DrawTickmarks	endp

SafariTimebarDraw	method dynamic SafariTimebarClass,
						MSG_VIS_DRAW
gstate		local	hptr	push	bp
bounds		local	Rectangle
maxCount	local	byte
count		local	byte
state		local	SafariTimebarState
tickColor	local	Color
		.enter

		mov	ax, {word}ds:[di].STBI_count
CheckHack <offset STBI_maxCount eq offset STBI_count + 1>
		mov	{word} ss:count, ax
CheckHack <offset maxCount eq offset count+1>

		mov	al, ds:[di].STBI_state
		mov	ss:state, al

		call	VisGetBounds
		mov	ss:bounds.R_left, ax
		mov	ss:bounds.R_top, bx
		mov	ss:bounds.R_right, cx
		mov	ss:bounds.R_bottom, dx

		mov	di, ss:gstate			;di <- GState
		call	GrSaveState
	;
	; draw common stuff
	;
CheckHack <CF_INDEX eq 0>
CheckHack <C_BLACK eq 0>
		push	ax
		clr	ax
		call	GrSetAreaColor
		mov	al, C_LIGHT_GRAY
		call	GrSetLineColor
		pop	ax
		call	GrDrawRect
	;
	; draw the bar, if any
	;
		tst	ss:count
		jz	noBar
	;
	; calculate the bar height:
	; = height * count/maxCount
	;
		mov	dx, ss:bounds.R_bottom
		sub	dx, ss:bounds.R_top		;dx <- height
		mov	al, ss:count
		cbw					;ax <- count
		mul	dx				;dx:ax <- val
		mov	cl, ss:maxCount
		clr	ch
		div	cx				;ax <- bar height
	;
	; erase what's left
	;
		mov	dx, ss:bounds.R_bottom
		sub	dx, ax				;dx <- top of bar
		mov	ax, ss:bounds.R_left
		mov	bx, ss:bounds.R_top
		mov	cx, ss:bounds.R_right
		call	GrFillRect
	;
	; draw the bar
	;
		mov	ss:tickColor, C_DARK_GRAY
		mov	si, offset yellowColors
		cmp	ss:state, STBS_PAUSED
		je	gotColors
		mov	ss:tickColor, C_VIOLET
		mov	si, offset redColors
		cmp	ss:count, 5
		jbe	gotColors
		mov	ss:tickColor, C_LIGHT_GREEN
		mov	si, offset greenColors
gotColors:
		mov	bx, ss:bounds.R_bottom		;bx <- bottom of timer
		call	DrawBar
		call	DrawTickmarks
done:
		call	GrRestoreState

		.leave
		ret

	;
	; no time left, just draw black
	;
noBar:
		call	GrFillRect
		jmp	done
SafariTimebarDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariScoreRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a score thingy

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/8/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariScoreRecalcSize	method dynamic	SafariScoreClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, SAFARI_SCORE_WIDTH
		mov	dx, SAFARI_SCORE_HEIGHT
		ret
SafariScoreRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariScoreDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw a score thingy

CALLED BY:	MSG_VIS_DRAW

PASS:		none
RETURN:		bp - GState
		cl - DrawFlags
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/4/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SCORE_LABEL_WIDTH	equ	8

SafariScoreDraw	method dynamic	SafariScoreClass,
					MSG_VIS_DRAW

gstate		local	hptr	push	bp
buf		local	UHTA_NULL_TERM_BUFFER_SIZE dup (TCHAR)
score		local	byte
side		local	SafariScoreSide
pos		local	Point


		.enter

		mov	al, ds:[di].SSI_score
		mov	ss:score, al
		mov	al, ds:[di].SSI_side
		mov	ss:side, al
	;
	; draw the background
	;
		mov	di, ss:gstate
		mov	ax, C_BLACK
		call	GrSetAreaColor
		call	VisGetBounds
		mov	ss:pos.P_x, ax
		mov	ss:pos.P_y, bx
		call	GrFillRect
	;
	; draw the label on the appropriate side
	;
		mov	ax, cx				;ax <- right edge
		sub	ax, SCORE_LABEL_WIDTH+1		;ax <- label pos x
		cmp	ss:side, SSS_RIGHT
		je	onRight
		mov	ax, ss:pos.P_x
		inc	ax				;ax <- label pos x
		add	ss:pos.P_x, SCORE_LABEL_WIDTH	;add space for label
onRight:
		add	ss:pos.P_x, 3			;margin for score
		add	ss:pos.P_y, 9			;margin for score
		push	ds, si
		push	ax, bx
		mov	bx, handle Bitmaps		;bx <- handle of bitmap
		call	MemLock
		mov	ds, ax
		pop	ax, bx
		mov	si, ds:[ScoreMoniker]		;ds:si <- bitmap
		clr	dx				;dx <- no callback
		call	GrDrawBitmap
		pop	ds, si
		mov	bx, handle Bitmaps
		call	MemUnlock
	;
	; draw the score if desired
	;
		cmp	ss:score, -1
		je	done				;branch if blank
	;
	; set the font, pointsize and color
	;
		mov	cx, FID_DTC_URW_SANS
		clr	ah
		mov	dx, 18
		call	GrSetFont
CheckHack <CF_INDEX eq 0>
		mov	ax, C_WHITE
		call	GrSetTextColor
	;
	; format the number
	;
		clr	ax, dx
		mov	al, ss:score			;dx:ax <- score

		push	ds, si
		push	di
		segmov	es, ss, di
		mov	ds, di
		lea	di, ss:buf			;es:di <- buffer
		mov	si, di				;ds:si <- buffer
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii
		pop	di
		mov	ax, ss:pos.P_x
		mov	bx, ss:pos.P_y
		call	GrDrawText
done:
		.leave
		ret
SafariScoreDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafariScoreSetScore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set the score

CALLED BY:	MSG_SAFARI_SCORE_SET_SCORE

PASS:		none
RETURN:		cl - score (-1 for blank)
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/8/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SafariScoreSetScore	method dynamic	SafariScoreClass,
					MSG_SAFARI_SCORE_SET_SCORE
		mov	ds:[di].SSI_score, cl
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
		GOTO	ObjCallInstanceNoLock
SafariScoreSetScore	endm

CommonCode	ends
