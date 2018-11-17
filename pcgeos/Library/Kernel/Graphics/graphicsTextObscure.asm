COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KLib/Graphics/Text
FILE:		graphicsTextObscure.asm

AUTHOR:		Gene Anderson, Jan 24, 1990

ROUTINES:
	Name			Description
	----			-----------
GLBL	GrSetTrackKern		Set track kerning / character spacing
GLBL	GrGetTrackKern		Get current track kerning / character spacing

EXT	LibGSSetFont		GString equivalent of GrSetFont
EXT	LibRecalcKernValues	Recalculate kerning values in GState

EXT	LibDrawDotLeader	Draw dot leader for text field
EXT	LibCallHyphenCallBack	Callback to get hyphenation information
INT	FindBreakPositions	Find break positions for hyphenation

EXT	LibComplexTransform	Transform WBFixed for text drawing
INT	TransOneCoord		Transform x or y of point

EXT	LibDrawKernelStyles	Draw underline and/or strikethrough
INT	DrawOneBar		Draw bar for underline or strikethrough

EXT	LibGSChar		"Draw" character at coord in gstring.
EXT	LibGSCharAtCP		"Draw" character at CP in gstring.
EXT	LibGSText		"Draw" text at coord in gstring.
EXT	LibGSTextAtCP		"Draw" text at CP in gstring.
EXT	LibUpdateTextPos	Update pen position for text w/o drawing.
INT	AddCharWidthToPenPos	Add width of character to pen position.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/24/90		Initial revision

DESCRIPTION:
	Contains infrequently used text routines.
		
	$Id: graphicsTextObscure.asm,v 1.1 97/04/05 01:13:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetTrackKern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the track kerning for the GState
CALLED BY:	GLOBAL

PASS:		di - handle of GState
		ax - degree of track kerning (signed word)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/90	Initial version
	don	 6/18/91	Changed to use standard lock/unlock routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetTrackKern	proc	far
	push	ds
	call	LockDI_DS_checkFar

	; Store the value away, and recalculate
	;
	pushf					;save the Gstring/Path flags
	cmp	ax, ds:GS_trackKernDegree	;any change?
	jz	optimzedExit
	mov	ds:GS_trackKernDegree, ax	;store the track kern value
	call	LibRecalcKernValues		;recalc kern values
	popf					;restore GString/Path flags
	jnc	done				;if not GString (nor Path), done

	; We're writing to a gstring, so write the correct bytes
	;
	push	ax, bx, cx
	mov	cl, size BBFixed		;cl <- # of databytes to write
	mov	bx, ds:GS_trackKernDegree	;bx <- data to write (BBFixed)
	mov	al, GR_SET_TRACK_KERN		;al <- opcode to write
	mov	ch, GSSC_FLUSH
	call	GSStoreBytes
	pop	ax, bx, cx
done:
	GOTO	UnlockDI_popDS, ds

optimzedExit:
	popf
	jmp	done

GrSetTrackKern	endp

kcode ends

;---

GraphicsCommon segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibRecalcKernValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the track kerning value, based on the pointsize.

CALLED BY:	INTERNAL: GrSetTrackKern, FindFont

PASS: 		ds - seg addr of GState
		ds:GS_trackKernDegree - degree of track kerning (sword)
RETURN:		ds:GS_trackKernValue - scaled kerning value (BBFixed)
		ds:GS_textMode - TM_TRACK_KERN: TRUE if any track kerning
		ds:GS_kernOp - set to GO_SPECIAL_CASE if any kerning
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	Calculates the value to use for track kerning. This is
	the pointsize multiplied by the degree of kerning passed
	to the kernel. This routine also calculates several
	optimizations used by the text metrics code and video
	driver.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibRecalcKernValues	proc	far
	uses	cx, dx
	.enter

	mov	cl, 0				;assume no kerning
	movwbf	dxal, ds:GS_fontAttr.FCA_pointsize
	rnduwbf	dxal, dx			;dx <- integer pointsize
	mov	ax, ds:GS_trackKernDegree	;ax <- kern degree

	tst	ax				;check degree of kerning
	je	isZero				;branch if zero
	cmp	ax, MAX_TRACK_KERNING
	jle	maxOK				;branch if too large
	mov	ax, MAX_TRACK_KERNING
maxOK:
	cmp	ax, MIN_TRACK_KERNING
	jge	minOK				;branch if too small
	mov	ax, MIN_TRACK_KERNING
minOK:
	imul	dx				;ax <- ptsize * degree
	jc	isBig				;branch if too large
	tst	ax
	js	isNegative			;branch if negative
isNonZero:
	mov	cl, mask TM_TRACK_KERN
isZero:
	mov	{word}ds:GS_trackKernValue, ax	;store kern value
	mov	ch, ds:GS_textMode		;ch <- text mode
	andnf	ch, not (mask TM_TRACK_KERN)	;clear kern bit
	ornf	ch, cl				;set bit properly
	mov	ds:GS_textMode, ch		;store new flags

	mov	al, GO_SPECIAL_CASE		;assume kerning
	test	ch, TM_KERNING			;see if any kerning
	jne	isKerning			;branch if kerning
	mov	al, GO_FALL_THRU		;nope, no kerning
isKerning:
	mov	ds:GS_kernOp, al		;store kerning opcode

	.leave
	ret

isNegative:
	tst	ds:GS_trackKernDegree		;test original sign
	js	isNonZero			;branch if originally negative
isBig:
	tst	ds:GS_trackKernDegree		;test original sign
	js	isBigNegative			;branch if negative
	mov	ax, MAX_KERN_VALUE		;ax <- max kern value
	jmp	isNonZero
isBigNegative:
	mov	ax, MIN_KERN_VALUE		;ax <- min kern value
	jmp	isNonZero

LibRecalcKernValues	endp

GraphicsCommon ends

;---

GraphicsText	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibDrawKernelStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw bars for underline and strikethrough
CALLED BY:	TextCallDriver

PASS:		ss:bp - ptr to DUS_locals on stack
		ds - seg addr of GState
		es - seg addr of Window
RETURN:		ss:bp.UAS_winSeg - seg addr of Window (may have changed)
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UnderPosStruct		struct
    UPS_yInt	word		;integer y pos	(bx)
    UPS_xInt	word		;integer x pos	(ax)
    UPS_xFrac	byte		;frac x pos	(dl)
    UPS_yFrac	byte		;frac y pos	(dh)
UnderPosStruct		ends

UnderArgStruct	struct
    UAS_winSeg	word		;seg addr of window	(es)
    UAS_fontSeg	word		;seg addr of font	(bp)
UnderArgStruct	ends

DrawUnderlineStruct	struct
    DUS_args	UnderArgStruct		;font, window
    DUS_current	UnderPosStruct		;current position
    DUS_old	UnderPosStruct		;old position
    DUS_fracs	word
    DUS_strOff	word			;saved si
    DUS_strSeg	word			;saved di
    DUS_strLen	word			;saved cx
    DUS_penX	word			;saved ax
    DUS_penY	word			;saved bx
DrawUnderlineStruct	ends

DUS_locals	equ <ss:[bp]>

LibDrawKernelStyles	proc	far
	uses	cx
	.enter
	mov	es, DUS_locals.DUS_args.UAS_fontSeg

	mov	bx, DUS_locals.DUS_old.UPS_yInt
	mov	dh, DUS_locals.DUS_old.UPS_yFrac

	test	ds:GS_fontAttr.FCA_textStyle, mask TS_UNDERLINE
	jz	noUnderline			;branch if not doing underline
	mov	dl, es:FB_underPos.WBF_frac
	mov	ax, es:FB_underPos.WBF_int	;ax.dl <- offset for bar
	call	DrawOneBar			;draw the underline bar	
noUnderline:

	test	ds:GS_fontAttr.FCA_textStyle, mask TS_STRIKE_THRU
	jz	noStrikethru			;branch if not doing strikethru
	mov	dl, es:FB_strikePos.WBF_frac
	mov	ax, es:FB_strikePos.WBF_int	;ax.dl <- offset for bar
	call	DrawOneBar			;draw the strikethrough bar
noStrikethru:

	.leave
	ret
LibDrawKernelStyles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOneBar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one bar, for either underline or strikethrough.
CALLED BY:	DrawStyles

PASS:		bx.dh - current y pos (WBFixed, document coords)
		ax.dl - offset to bar (WBFixed)
		ss:bp - DUS_locals on stack
		es - seg addr of font
RETURN:		ss:bp.UAS_winSeg - seg addr of Window (may have moved)
DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes: strikethrough thickness == underline thickness
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawOneBar	proc	near
	uses	bx, dx, si, di, es
	.enter

	; we want to be as exact as possible, so do the transformations
	; ourselves instead of rounding the document coords.  First do the
	; top/left corner.  While we have the font segment, get the underline
	; thickness for later.

	push	ds				; save GState segment
	mov	ds, DUS_locals.DUS_args.UAS_winSeg ;ds <- seg addr of window
	mov	si, offset W_curTMatrix		; ds:si -> TMatrix

	; calculate the top/left corner.
	;
	; in order to deal with the positioning and width of underlines
	; in a consistent manner (they apepar in the same position under
	; or thru the text and have the same width, regardless of where the
	; text is on the page).

	test	ds:[si].TM_flags, TM_ROTATED or TM_SCALED
	jnz	useFrac1
	shl	dl, 1				; round fractional position
doneFrac1:
	adc	ax, bx
	clr	dl				; ax.dx = y position
	mov	bx, ax
	mov	ax, dx				; bx.ax = y position

	; if the current window has some rotation, the following code ain't
	; gonna work.  So branch off here and do the real corner calculation.

	test	ds:[si].TM_flags, TM_ROTATED
	jnz	handleRotated

	push	bx				; save top y position
	push	ax
	
	mov	ch, DUS_locals.DUS_old.UPS_xFrac
	clr	cl
	mov	dx, DUS_locals.DUS_old.UPS_xInt
	call	TransCoordFixed			; translate top/left coord
	shl	ax, 1				; round up
	adc	bx, 0
	shl	cx, 1
	adc	dx, 0				; bx,dx = x/y top/left coord
	mov	cx, bx				; cx,dx = same
	pop	ax				; restore top doc coord
	pop	bx				; bx.ax = top rect coord
	push	dx, cx				; save left/top device coord

	; second half of dealing with underlines in a consistent manner

	test	ds:[si].TM_flags, TM_ROTATED or TM_SCALED
	jnz	useFrac2
	movwbf	dxch, es:FB_underThickness	; always want same thickness,
	shl	ch, 1				; regardless of screen position,
	adc	bx, dx				; so round & add to current pos
doneFrac2:
	mov	ch, DUS_locals.DUS_current.UPS_xFrac
	clr	cl
	mov	dx, DUS_locals.DUS_current.UPS_xInt
	mov	si, offset W_curTMatrix		; ds:si -> TMatrix to use
	call	TransCoordFixed
	shl	ax, 1				; round up
	adc	bx, 0
	shl	cx, 1
	adc	dx, 0				; bx,dx = x/y bot/right coord
	mov	cx, dx				; 
	mov	dx, bx				; cx,dx = right/bottom
	pop	ax, bx				; ax,bx = left/top

	segmov	es, ds, si			; es -> Window
	pop	ds				; restore GState segment
	mov	si, offset GS_textAttr		;si <- use text attributes
	push	bp
	call	FillRectLowFar			;draw the rectangle
	pop	bp
done:
	mov	DUS_locals.DUS_args.UAS_winSeg, es ; may have moved

	.leave
	ret

	; if we are scaled or rotated, then use the fractional position
useFrac1:
	add	dh, dl				; calc top position
	jmp	doneFrac1

	; if we are scaled or rotated, then use the fractional line width
useFrac2:
	addwbf	bxah, es:FB_underThickness	; calc bottom coord
	jmp	doneFrac2

	; there is some rotation in the TMatrix.  Can't draw a simple 
	; rectangle....
	; ds:si -> W_curTMatrix
	; es -> fontBuf
	; bx.ax = WWFixed top position of rectangle (doc coords)
	; 
	; The strategy here is to generate a series of coordinates for
	; the video driver polygon routine.  We'll just push them on the
	; stack and use that as the buffer (it's only 16 bytes).  Do them
	; in the order upperleft, upperright, lowerright, lowerleft.
handleRotated:
	pop	di				; di -> GState segment
	mov	ch, DUS_locals.DUS_old.UPS_xFrac ; DO UPPER LEFT
	clr	cl
	mov	dx, DUS_locals.DUS_old.UPS_xInt
	push	bx, ax				; save y position
	call	TransCoordFixed
	rndwwf	bxax
	rndwwf	dxcx
	mov	cx, bx				; coord in dx, cx
	pop	bx, ax				; restore prev y position
	push	cx
	push	dx				; save y and then x ul coord

	mov	ch, DUS_locals.DUS_current.UPS_xFrac ; DO UPPER RIGHT
	clr	cl
	mov	dx, DUS_locals.DUS_current.UPS_xInt
	push	bx, ax				; save y position
	call	TransCoordFixed
	rndwwf	bxax
	rndwwf	dxcx
	mov	cx, bx				; coord in dx, cx
	pop	bx, ax				; restore prev y position
	push	cx
	push	dx				; save y and then x ur coord

	mov	ch, DUS_locals.DUS_current.UPS_xFrac ; DO LOWER RIGHT
	clr	cl
	mov	dx, DUS_locals.DUS_current.UPS_xInt
	addwbf	bxah, es:FB_underThickness	; calc bottom coord
	push	bx, ax				; save y position
	call	TransCoordFixed
	rndwwf	bxax
	rndwwf	dxcx
	mov	cx, bx				; coord in dx, cx
	pop	bx, ax				; restore prev y position
	push	cx
	push	dx				; save y and then x lr coord

	mov	ch, DUS_locals.DUS_old.UPS_xFrac ; DO LOWER RIGHT
	clr	cl
	mov	dx, DUS_locals.DUS_old.UPS_xInt
	call	TransCoordFixed
	rndwwf	bxax
	rndwwf	dxcx
	mov	cx, bx				; coord in dx, cx
	push	cx
	push	dx				; save y and then x lr coord

	segmov	es, ds, cx		; es -> window
	mov	ds, di			; di -> GState
	mov	cx, 4
	mov	bx, ss
	mov	dx, sp			; points on top of stack
	mov	si, offset GS_textAttr
	mov	di, DR_VID_POLYGON
	clr	al			; pass the flag to ALWAYS draw
	push	bp, ds
	call	es:[W_driverStrategy]
	pop	bp, ds
	add	sp, 16			; account for 8 extra pushes
	jmp	done

DrawOneBar	endp

GraphicsText ends

GraphicsTextObscure segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibGSSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spew data for a GrSetFont() in a graphics string
CALLED BY:	GrSetFont()

PASS:		cx - FontID
		dx.ah - pointsize (WBFixed)
		di - handle of GString
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibGSSetFont	proc	far
	uses	cx, dx,ax,bx
	.enter

	mov	bx, dx				;bx.ah <- pointsize (WBFixed)
	mov	dx, cx				;dx <- font ID
	mov	cl, size OpSetFont - 1		;cl <- # databytes to write
	mov	al, GR_SET_FONT			;al <- opcode to write
	mov	ch, GSSC_FLUSH
	call	GSStoreBytes			;write bytes to string

	.leave
	ret
LibGSSetFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTrackKern
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get track kerning from the GState
CALLED BY:	GLOBAL

PASS:		di - handle of GState
RETURN:		ax - degree of track kerning (signed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrGetTrackKern	proc	far
	push	ds
	call	LockDI_DS_checkFar
	mov	ax, ds:GS_trackKernDegree	;ax <- degree of track kerning
	GOTO	UnlockDI_popDS, ds
GrGetTrackKern	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibComplexTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform 24-bit (x,y) point with complex transformation.
		Assumes final addition will be done afterward.
CALLED BY:	TextCallDriver

PASS:		cx.dl - x position (WBFixed, document coords)
		bp.dh - y position (WBFixed, document coords)
		ds - seg addr of gstate
		es - seg addr of window
RETURN:		ax.dl - x position (WBFixed, device coords)
		bx.dh - y position (WBFixed, device coords)
DESTROYED:	none (ax, bx trashed on way here)

PSEUDO CODE/STRATEGY:
	The following are the equations to transform a point:
		x' = r11*x + r21*y + r31
		y' = r12*x + r22*y + r32

	The final addition is not done here, because it is done
	in both the simple and complex case, and is always
	done last. This is basically a version of GrTransCoord
	that takes and returns WBFixeds instead of integers, and
	has the assumption regarding the final addition.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibComplexTransform	proc	far
	uses	cx, si, di, ds, es
	.enter

	clr	ax
	mov	ah, dl				;cx:ah <- x coord
	clr	dl				;bp:dh <- y coord
	push	bp, dx				;push y coord (WBFixed)
	push	cx, ax				;push x coord (WBFixed)

	tst	ds:[GS_window]			; if there is no window, use
	jz	useGState			;  use the GState transform

	segmov	ds, ss
	mov	si, sp				;ds:si <- ptr to (x,y)

	mov	di, offset W_curTMatrix.TM_11	;es:di <- ptr to 1st column
	call	TransOneCoord			;dx.cx == TM11*x + TM21*y
	push	cx
	push	dx				;save x'

	mov	di, offset W_curTMatrix.TM_12	;es:di <- ptr to 2nd column
	call	TransOneCoord			;dx.cx == TM12*x + TM22*y
	mov	bx, dx
	mov	dh, ch				;bx.dh <- y'

	pop	ax
	pop	cx
	mov	dl, ch				;ax.dl <- x'
done:
	add	sp, (size WWFixed)*2		;nuke stuff from stack
	.leave
	ret

	; there is no window, so make do with the GState
useGState:
	segmov	es, ds
	segmov	ds, ss
	mov	si, sp
	mov	di, offset GS_TMatrix.TM_11
	call	TransOneCoord
	push	cx
	push	dx				;save x'
	mov	di, offset GS_TMatrix.TM_12	;es:di <- ptr to 2nd column
	call	TransOneCoord			;dx.cx == TM12*x + TM22*y
	mov	bx, dx
	mov	dh, ch				;bx.dh <- y'
	pop	ax
	pop	cx
	mov	dl, ch				;ax.dl <- x'
	jmp	done

LibComplexTransform	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransOneCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform one coordinate -- x or y
CALLED BY:	ComplexTransform

PASS:		ds:si - ptr to (x,y) pair (WWFixeds)
		es:di - ptr to TM_11 (for x) or TM_12 (for y)
RETURN:		dx:cx - x*TM_11 + y*TM_21 (WBFixed, cl == 0)
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Twenty (20) bytes could be saved at an incredible
	sacrifice in speed for the case where either element
	is zero.
	Assumes: offset TM21 - offset TM11 = offset TM22 - offset TM12
	Assumes: offset y - offset x = size WWFixed
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransOneCoord	proc	near
	push	si
	mov	ax, es:[di].WWF_frac
	mov	bx, es:[di].WWF_int
	or	ax, bx				;test for TM_11 zero
	je	xIsZero				;branch if component zero
	call	GrMulWWFixedPtr			;dx.cx <- TM_11*x
	mov	ax, cx
	mov	bx, dx
xIsZero:
	add	si, size WWFixed		;ds:si <- ptr to y
	add	di, TM_21 - TM_11		;es:di <- ptr to next mult
	mov	cx, es:[di].WWF_frac
	mov	dx, es:[di].WWF_int
	or	cx, dx				;test for TM_21 zero
	je	yIsZero				;branch if component zero
	call	GrMulWWFixedPtr			;dx.cx <- TM_21*y
yIsZero:
	add	cx, ax
	adc	dx, bx				;dx.cx <- TM_11*x + TM_21*y
	add	cx, 0x0080
	adc	dx, 0x0000			;dx.ch <- rounded (WBFixed)
	pop	si
	ret
TransOneCoord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibGSCharAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"Draw" a character at the current pen position in a gstring.
CALLED BY:	GrDrawCharAtCP

PASS:		bp - ptr to EGframe on stack
		ds - seg addr of GState
RETURN:		ds:GS_penPos - updated
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibGSCharAtCP	proc	far

	call	AddCharWidthToPenPos		;update pen postion
SBCS <	mov	ah, dl				;ah <- character to draw>
DBCS <	mov	bx, dx				;bx <- character to draw>
	mov	al, GR_DRAW_CHAR_CP		;al <- gstring opcode
	mov	cl, size OpDrawCharAtCP - 1	;cl <- # of databytes to write
	mov	ch, GSSC_FLUSH
	call	GSStoreBytes

	ret
LibGSCharAtCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibGSChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"Draw" a character at the specified pen position in a gstring
CALLED BY:	GrDrawChar

PASS:		bp - ptr to EGframe on stack
		ds - seg addr of GState
RETURN:		ds:GS_penPos - updated
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibGSChar	proc	far

	call	AddCharWidthToPenPos		;update pen postion
SBCS <	mov	ah, dl				;ah <- character to draw>
SBCS <	mov	bx, ss:[bp].EG_ax		;bx <- x position	>
SBCS <	mov	dx, ss:[bp].EG_bx		;dx <- y position	>
DBCS <	mov	bx, dx				;bx <- character to draw>
DBCS <	mov	dx, ss:[bp].EG_ax		;dx <- x position	>
DBCS <	mov	si, ss:[bp].EG_bx		;si <- y position	>
	mov	al, GR_DRAW_CHAR		;al <- gstring opcode
	mov	cl, size OpDrawChar - 1		;cl <- # of databytes to write
	mov	ch, GSSC_FLUSH
	call	GSStoreBytes

	ret
LibGSChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddCharWidthToPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the width of a text string when the window is already 
		locked and recalculate the new pen position
CALLED BY:	LibGSChar

PASS:		bp - ptr to EGframe on stack
		ds - seg addr of GState

RETURN:		ds:GS_penPos - updated
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine is assumed to be called only with a gstate that
	is associated with a graphics string, and hence that the
	window is not locked.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/90		Initial version (copied from GrDrawText)
	Gene	3/90		Moved to Klib, changed CharInfo to TextWidth
	jim	4/92		support for newer, more accurate penPos

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddCharWidthToPenPos	proc	near
	uses	dx, di
	.enter

	mov	di, ss:[bp].EG_di		;di <- handle of GState
	push	ds
	lea	si, ss:[bp].EG_dx		;dx = character
	segmov	ds, ss, ax			;ds:si = string (on stack)
	mov	cx, 1				;cx <- max # of chars to check
	call	GrTextWidthWBFixed		; dx.ah = char width
	pop	ds				;restore GState segment
	test	ds:[GS_TMatrix].TM_flags, TM_COMPLEX
	jnz	handleScaleRotate
	add	ds:GS_penPos.PDF_x.DWF_frac.high, ah
	adc	ds:GS_penPos.PDF_x.DWF_int.low, dx
	adc	ds:GS_penPos.PDF_x.DWF_int.high, 0
done:
	.leave
	ret

	; it's a bit more complex if there is scaling and rotation
handleScaleRotate:
	push	bx
	mov	cx, ax
	clr	cl
	clr	bx, ax
	call	TransformRelVector		; figure offset in page coords
	add	ds:GS_penPos.PDF_x.DWF_frac, cx
	adc	ds:GS_penPos.PDF_x.DWF_int.low, dx
	adc	ds:GS_penPos.PDF_x.DWF_int.high, 0
	add	ds:GS_penPos.PDF_y.DWF_frac, ax
	adc	ds:GS_penPos.PDF_y.DWF_int.low, bx
	adc	ds:GS_penPos.PDF_y.DWF_int.high, 0
	pop	bx
	jmp	done
AddCharWidthToPenPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibGSTextAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"Draw" text at pen position in gstring.
CALLED BY:	GrDrawTextAtCP

PASS:		ds - seg addr of GState
		es - seg addr of Window
		bp - ptr to EGframe on stack
RETURN:		ds:GS_penPos - updated
DESTROYED:	ax, bx, cx, dx, ds, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibGSTextAtCP	proc	far
	call	GetDocPenPos			; get current position
	call	UpdateGSTextPos

	mov	di, ds:[GS_gstring]		; get gstring handle
	mov	al, GR_DRAW_TEXT_CP		;al <- gstring opcode
	mov	bx, cx				;bx <- # chars to draw
	mov	cl, size OpDrawTextAtCP - 1	;cl <- # bytes to write
	mov	ch, GSSC_DONT_FLUSH
	call	GSStoreBytes			;write out bytes
	mov	cx, bx				;cx <- # chars to draw
	;
	; StoreString:
	;	dx:si - ptr to string
	;	cx - # of chars in string
	;
StoreTextString	label	near
DBCS <	shl	cx, 1				;cx <- # bytes to save	>
	mov	ds, dx				;ds <- seg addr of text
	mov	ax, (GSSC_FLUSH shl 8) or 0ffh	;dx <- don't write an opcode
	call	GSStore				;write out string
	ret
LibGSTextAtCP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateGSTextPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to deal with changed interface to 
		UpdateTextPos

CALLED BY:	LibGSTextAtCP, LibGSText
PASS:		ss:bp	= EGframe
RETURN:		dx:si	= text string
		cx	= # chars in string
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateGSTextPos	proc	near
		uses	di, ax, bx
		.enter
		mov	di, ss:[bp].EG_ds
		mov	si, ss:[bp].EG_si
		clr	dx			; no starting fraction
		call	FarUpdateTextPos		;update pen position
		mov	si, ss:[bp].EG_si
		mov	dx, di
		.leave
		ret
UpdateGSTextPos	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LibGSText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	"Draw" text a coordinate in gstring.
CALLED BY:	GrDrawText

PASS:		ds - seg addr of GState
		es - seg addr of Window
		bp - ptr to EGframe on stack
RETURN:		ds:GS_penPos - updated
DESTROYED:	ax, bx, cx, dx, ds, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	2/90		Initial version
	eca	3/29/90		Moved to KLib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LibGSText	proc	far
	mov	ax, ss:[bp].EG_ax		;ax <- x coord
	mov	bx, ss:[bp].EG_bx		;bx <- y coord
	call	SetDocPenPos			; set current pen position

	call	UpdateGSTextPos			;update pen position
	;
	; store the first part of the element as two GSStoreBytes 
	; instead of one GSStore: GSStoreBytes guarantees not to
	; flush the buffer, ensuring that this element won't be
	; split between two VM blocks, if that is the target of the
	; graphics string
	;
	push	cx, dx, si		;save string length, offset
	mov	dx, bx			;dx <- y coord (2nd word)
	mov	bx, ax			;bx <- x coord (1st word)
	mov	si, cx			;si <- # of chars (3rd word)
	mov	al, GR_DRAW_TEXT	;al <- gstring opcode
	mov	cl, size OpDrawText - 1	;cl <- # of data bytes to write
	mov	ch, GSSC_DONT_FLUSH
	call	GSStoreBytes
	pop	cx, dx, si		;cx <- string len, si <- offset
	jmp	StoreTextString
LibGSText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds of a text string

CALLED BY:	GLOBAL
PASS:		ds:si = ptr to the text.
		di = GState.
		ax,bx = position text would be drawn
		cx = max number of characters to check.
RETURN:		carry	- set if font driver is unavailable (hence we can't 
			  calculate the bounds)

		if carry is clear:
			ax = left bound
			bx = top bound
			cx = right bound
			dx = bottom bound

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		this routine starts with GrTextWidthWBFixed as a basis
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrGetTextBounds	proc	far
DBCS <		shl	cx, 1					>
		mov	ss:[TPD_callVector].segment, cx
DBCS <		shr	cx, 1					>
		mov	ss:[TPD_dataBX], handle GrGetTextBoundsReal
		mov	ss:[TPD_dataAX], offset GrGetTextBoundsReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrGetTextBounds	endp
CopyStackCodeXIP	ends

else

GrGetTextBounds	proc	far
	FALL_THRU	GrGetTextBoundsReal
GrGetTextBounds	endp

endif

GrGetTextBoundsReal	proc	far
	uses	si, ds, es
leftBound	local	WBFixed
topBound	local	WBFixed
rightBound	local	WBFixed
bottomBound	local	WBFixed
drawPos		local	PointWBFixed
gstateSeg	local	sptr
textSeg		local	sptr
gstateHan	local	hptr

	.enter

	; save some stuff, init the bounds

	mov	ss:drawPos.PWBF_x.WBF_int, ax
	mov	ss:drawPos.PWBF_y.WBF_int, bx
	mov	ss:rightBound.WBF_int, ax
	add	ax, 0x1000
	mov	ss:leftBound.WBF_int, ax
	mov	ss:bottomBound.WBF_int, bx
	add	bx, 0x1000
	mov	ss:topBound.WBF_int, bx
	mov	ss:textSeg, ds			;save seg addr of string
	clr	ax
	mov	ss:leftBound.WBF_frac, al
	mov	ss:topBound.WBF_frac, al
	mov	ss:bottomBound.WBF_frac, al
	mov	ss:rightBound.WBF_frac, al
	mov	ss:drawPos.PWBF_x.WBF_frac, al
	mov	ss:drawPos.PWBF_y.WBF_frac, al
	mov	ss:gstateHan, di

	push	di
	mov	bx, di				; lock the GState
	call	MemLock
	mov	ds, ax				;ds <- seg addr of GState
	mov	ss:gstateSeg, ax
	;
	; Now lock the font, we need this no matter what...
	;
	call	FontDrLockFont
SBCS <	push	bx							>
	mov	es, ax				;es <- seg addr of font
	;
	; Load up the textMode...
	;
	mov	bl, ds:GS_textMode		;bl <- TextMode
	mov	ds, ss:textSeg			;ds <- seg addr of string
	;
	; Based on the text mode, we might have to store an adjustment value
	; 
	clr	di
	clr	bh
	test	bl, mask TM_DRAW_BASE		; if baseline, no adjustment
	jnz	haveAdjust
	test	bl, mask TM_DRAW_BOTTOM		; if bottom, use descent
	jz	checkAccent
	movwbf	dibh, es:[FB_descent]		; grab adjustment
	negwbf	dibh				; make it negative
	jmp	haveAdjust
checkAccent:
	movwbf	dibh, es:[FB_baselinePos]	; accent or top has this
	test	bl, mask TM_DRAW_ACCENT
	jz	haveAdjust
	subwbf	dibh, es:[FB_accent]		; take out accent
haveAdjust:
	addwbf	ss:drawPos.PWBF_y, dibh
	;
	; es = font segment address.
	; bl = TextMode
	;
	clr	bh				; bh <- kern char flags
	mov	di, cx				; di = char count

	; if the font is a bitmap font, then we want to choose a different
	; method for finding the bounds of the font.  This because there is
	; no CharMetrics support.

	cmp	es:[FB_maker], FM_BITMAP	; check for bitmap font
	LONG je	computeBMbounds			;  yes, do bounds another way
	cmp	es:[FB_maker], FM_PRINTER	; check for printer font
	LONG je	computeBMbounds			;  yes, do bounds another way

	; loop for each character in the string.
charLoop:					;
	LocalGetChar	ax, dssi		;
SBCS <	clr	ah							>
	LocalIsNull	ax			;
	jz	endLoop				; Quit on NULL.
	push	di				; save loop count
	call	CheckCharBox			; see if we need to bump bounds
	cmp	ss:leftBound.WBF_int, 8000h	; check for no font driver
LONG	je	noFontDriver
	LocalCmpChar	ax, C_SPACE		; Check for a padded space.
LONG	je	spaceChar			; Handle spaces specially.
afterSpaceChar:					;
SBCS <	cmp	al, C_OPTHYPHEN			; Check for optional hyphen.>
DBCS <	cmp	ax, C_SOFT_HYPHEN		; Check for optional hyphen.>
	jne	afterOptHyphen			;
	jmp	optHyphen			;
afterOptHyphen:					;
	;
	; Now add in the character width, checking for a character
	; that is before the first, after the last, or missing.
	;
	push	ax				;save current char
	segmov	ds, es				;ds <- seg addr
SBCS <	cmp	al, ds:FB_lastChar		;			>
SBCS <	ja	useDefaultChar			; Branch if beyond last char >
DBCS <	cmp	ax, ds:FB_lastChar		;			>
DBCS <	ja	afterLastChar			; Branch if beyond last char >
afterDefault:					;
SBCS <	sub	al, ds:FB_firstChar		; Adjust and check char	>
SBCS <	jb	useDefaultChar						>
DBCS <	sub	ax, ds:FB_firstChar		; Adjust and check char	>
DBCS <	jb	beforeFirstChar						>
						;
	mov	di, ax				;di <- offset of character
	FDIndexCharTable di, ax			;di <- index into width table
	tst	ds:FB_charTable[di].CTE_dataOffset ;see if character missing
	jz	useDefaultChar			;branch if missing
	pop	ax				;ax <- current char
	test	bl, TM_KERNING			;see if any kerning info
LONG	jne	kerned				;branch if any kerning info
	mov	cl, ds:FB_charTable[di].CTE_width.WBF_frac
	mov	dx, ds:FB_charTable[di].CTE_width.WBF_int
	add	ss:drawPos.PWBF_x.WBF_frac, cl	; bump along the draw position
	adc	ss:drawPos.PWBF_x.WBF_int, dx

skipChar:					;
SBCS <	mov	ch, al				; ch <- previous character.>
DBCS <	mov	cx, ax				; cx <- previous character.>
	mov	ds, ss:textSeg
						;
	pop	di				; restore loop count
	dec	di
	jnz	charLoop			; Loop while not done.
endLoop:

SBCS <	pop	bx							>
DBCS <	mov	ds, ss:gstateSeg		; ds <- seg addr of GState>
DBCS <	mov	bx, ds:GS_fontHandle		;bx <- handle of font	>
	call	FontDrUnlockFont		; unlock the font
						;
	pop	di				; restore GState handle
	mov	bx, di
	call	MemUnlock

	; setup return values
doneOK:
	call	CalcReturnValues
	clc					; no error
done:
	.leave					;
	ret					;

if DBCS_PCGEOS
	;
	; The character in question is not in the current section
	; of the font.  Lock down the correct section and try again.
	;
beforeFirstChar:
	add	ax, ds:FB_firstChar		;re-adjust character
afterLastChar:
	push	ax
	mov	ds, ss:gstateSeg		;ds <- seg addr of GState
	call	LockCharSetFar
	mov	ds, ax				;ds <- (new) font seg
	mov	es, ax				;es <- (new) font seg
	pop	ax
	jnc	afterDefault			;branch if char exists
useDefaultChar:
	mov	ax, ds:FB_defaultChar
	jmp	afterDefault

else

useDefaultChar:
	mov	al, ds:FB_defaultChar
	jmp	afterDefault
endif

noFontDriver:
	pop	di				; loop count from in char loop
SBCS <	pop	bx							>
DBCS <	mov	ds, ss:gstateSeg		; ds <- seg addr of GState>
DBCS <	mov	bx, ds:GS_fontHandle		;bx <- handle of font	>
	call	FontDrUnlockFont		; unlock the font
						;
	pop	di				; restore GState handle
	mov	bx, di
	call	MemUnlock
	stc					; set carry flag
	jmp	done

;******************************************************************************
;
; Add in space padding
;	ss:drawPos = current char position
;	al    = current character.
;	ch    = previous character.
;	bl    = TextMode
;
spaceChar:
	test	bl, mask TM_PAD_SPACES		; see if non-zero padding
LONG	je	afterSpaceChar			; branch if no padding
DBCS <	push	cx				; save prev char	>
	mov	ds, ss:gstateSeg				;
	mov	cl, ds:GS_textSpacePad.WBF_frac
	mov	dx, ds:GS_textSpacePad.WBF_int
	add	ss:drawPos.PWBF_x.WBF_frac, cl
	adc	ss:drawPos.PWBF_x.WBF_int, dx
	mov	ds, ss:textSeg			; Restore string segment.
DBCS <	pop	cx				; restore prev char	>
	jmp	afterSpaceChar			;
;
; Handle soft hyphen character.
;
; Check for on last character of string.
; PASS:
;	ds:si = pointer to next character in string.
;	di    = # of characters left to check.
;	bl    = TextMode
; RETURN:
;	al    = C_HYPHEN if using hyphen character
;
optHyphen:					;
	test	bl, mask TM_DRAW_OPTIONAL_HYPHENS
	jz	skipChar			; Skip if not desired.
	cmp	di, 1				; If this is the last char
	je	useHyphen			;   use hyphen.
	cmp	{byte} ds:[si], 0		; Null signals last char too.
LONG	jne	skipChar			;
useHyphen:					;
SBCS <	mov	al, C_HYPHEN			; Replace with real hyphen.>
DBCS <	mov	ax, C_HYPHEN_MINUS		; Replace with real hyphen.>
	jmp	afterOptHyphen			;

;
; Handle kerned characters.
; PASS:
;	ss:drawPos = current position
;	al    = current character
;	bh    = previous CharTableFlags
;       ch    = previous character
;	ds,es:di = index of CharTableEntry for current char
; RETURN:
;	ss:drawPos = updated position
;
kerned:
	push	ax, bx
	push	cx, dx, di

SBCS <	mov	ah, ch				;ah <- prev, al <- current>
	test	bh, mask CTF_IS_FIRST_KERN
	pushf					;save flag from test
	clr	bx				;bx <- char width (BBFixed)
	;
	; Adjust the width based on any track kerning.
	;
	push	ds
	mov	ds, ss:gstateSeg		;ds <- seg addr of gstate
	add	bx, {word}ds:GS_trackKernValue	;add track kern value
	pop	ds
	;
	; See if the character is even kernable.
	; If it is kernable, scan the table of kern pairs.
	;
	; No check is done (in the EC version) for no kerning pairs.
	; If the CTF_IS_SECOND_KERN is set and there are no kern
	; pairs, then the font is a bit dorked. So (in the non-EC
	; version) the Z flag is set in case cx == 0, meaning the
	; font is a little dorked...
	; There probably should be an ERROR BAD_FONT_FILE if cx is
	; zero and a character is marked as kernable, but I don't
	; have the bytes for it...
	;
	popf					;from 'test CTF_IS_FIRST_KERN'
	jz	noPairKerning			;branch if not after kernable
if DBCS_PCGEOS
;	ERROR	-1
	jmp	noPairKerning
else
	test	ds:FB_charTable[di].CTE_flags, mask CTF_IS_SECOND_KERN
	jz	noPairKerning			;branch if not kernable
	mov	cx, ds:FB_kernCount		;cx <- number of kerning pairs
NEC <	tst	ah				;set Z flag in case cx == 0 >
	mov	di, ds:FB_kernPairPtr		;es:di = kerning table
	repne scasw				;find kerning pair.
	jne	noPairKerning			;quit if not found.
	;
	; Kerning pair was found, adjust the width.
	;
	sub	di, ds:FB_kernPairPtr		;di <- offset to pair (+1)
	add	di, ds:FB_kernValuePtr		;di <- offset to value (+1)
	add	bx, {word}ds:[di-2]		;add pair kern value
endif
noPairKerning:
	pop	cx, dx, di			;dx.cl <- string width so far
	;
	; Don't back up. If pairwise kerning plus track kerning results
	; in a character width of less than zero, set the width to zero.
	;
	mov	al, bh
	cbw					;ax.bl <- kerning
	add	bl, ds:FB_charTable[di].CTE_width.WBF_frac
	adc	ax, ds:FB_charTable[di].CTE_width.WBF_int
	tst	ah				;see if backing up
	js	dontBackUp			;branch if negative width
	add	ss:drawPos.PWBF_x.WBF_frac, bl
	adc	ss:drawPos.PWBF_x.WBF_int, ax	; update drawPos
dontBackUp:
	pop	ax, bx
	mov	bh, ds:FB_charTable[di].CTE_flags ;save CharTableFlags
	jmp	skipChar

	; it's a bitmap font.  Compute things a different way.
computeBMbounds:
						; unadjust for baseline
	subwbf	ss:drawPos.PWBF_y, es:[FB_baselinePos], ax
	mov	dx, es:[FB_height].WBF_int
	mov	ah, es:[FB_height].WBF_frac
SBCS <	pop	bx				; release font so we can get>
DBCS <	push	ds							>
DBCS <	mov	ds, ss:gstateSeg		; ds <- seg addr of GState>
DBCS <	mov	bx, ds:GS_fontHandle		;bx <- handle of font	>
DBCS <	pop	ds							>
	call	FontDrUnlockFont		;  the width
	pop	di				; restore GState handle
	mov	bx, di
	call	MemUnlock			; releaseGState
	pushdw	dxax
	mov	ah, ss:drawPos.PWBF_x.WBF_frac	; get drawPos as left/top
	mov	dx, ss:drawPos.PWBF_x.WBF_int
	mov	ss:leftBound.WBF_frac, ah
	mov	ss:leftBound.WBF_int, dx
	mov	ss:rightBound.WBF_frac, ah
	mov	ss:rightBound.WBF_int, dx
	mov	ah, ss:drawPos.PWBF_y.WBF_frac	; get drawPos as left/top
	mov	dx, ss:drawPos.PWBF_y.WBF_int
	mov	ss:topBound.WBF_frac, ah
	mov	ss:topBound.WBF_int, dx
	mov	ss:bottomBound.WBF_frac, ah
	mov	ss:bottomBound.WBF_int, dx
	popdw	dxax				; dx.ah = height
	add	ss:bottomBound.WBF_frac, ah
	adc	ss:bottomBound.WBF_int, dx
	call	GrTextWidthWBFixed
	add	ss:rightBound.WBF_frac, ah
	adc	ss:rightBound.WBF_int, dx
	jmp	doneOK

GrGetTextBoundsReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcReturnValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine that does some WBFixed math

CALLED BY:	GrGetTextBounds
PASS:		
RETURN:		ax..dx	- bounds
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If there are fractional bounds, bounce them out to the
		next integer boundary
		
		1.1 -> 2
		-1.1 -> -2
		1.0 -> 1
		-1.0 -> -1

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRoundedValue	macro	reg, source
	local done
	mov	reg, source.WBF_int
	tst	reg
	js	done
	tst	source.WBF_frac
	jz	done			;Branch if no fraction
	inc	reg
done:
endm

CalcReturnValues proc	near
	.enter	inherit	GrGetTextBoundsReal

	GetRoundedValue	ax, ss:leftBound
	GetRoundedValue bx, ss:topBound
	GetRoundedValue cx, ss:rightBound
	GetRoundedValue dx, ss:bottomBound

	.leave
	ret
CalcReturnValues endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCharBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the bounding box for the character, and make the 
		appropriate changes to the accumulated bounding box.

CALLED BY:	INTERNAL
		GrGetTextBounds
PASS:		ax	- char
		bl	- TextMode byte
		es	- FontBuff segment
		inherits stack frame from GrGetTextBounds
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCharBox	proc	near
		uses	ax, cx, dx, si
		.enter	inherit GrGetTextBoundsReal

		; call GrCharMetrics to get the real bounds

		mov	si, GCMI_MIN_X
		mov	cx, ax
		call	QuickCharMetrics
		jc	noFontDriver
		addwbf	dxah, ss:drawPos.PWBF_x
		call	CharBoundX

		mov	si, GCMI_MAX_X
		call	QuickCharMetrics
		jc	noFontDriver
		addwbf	dxah, ss:drawPos.PWBF_x
		call	CharBoundX

		mov	si, GCMI_MIN_Y
		call	QuickCharMetrics
		jc	noFontDriver
		subwbf	dxah, ss:drawPos.PWBF_y
		negwbf	dxah
		call	CharBoundY

		mov	si, GCMI_MAX_Y
		call	QuickCharMetrics
		jc	noFontDriver
		subwbf	dxah, ss:drawPos.PWBF_y
		negwbf	dxah
		call	CharBoundY
done:
		.leave
		ret

		; if there is no driver, just set bogus bounds and return
noFontDriver:
		mov	ss:leftBound.WBF_int, 8000h
		jmp	done
		

CheckCharBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickCharMetrics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A shortcut routine so that we don't have to unlock the font

CALLED BY:	INTERNAL
		CheckCharBox
PASS:		cx	- char to check
		si	- attribute to get
		es	- FontBuff
RETURN:		carry	- set if no font driver available
			  else:
				dxah	- WBFixed metric value requested
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
QuickCharMetrics	proc	far
		uses	es, ds, di, cx
		.enter	inherit GrGetTextBoundsReal

		mov	dx, cx			; dx = char
		mov	cx, si			; cx = function
		mov	ax, es:[FB_maker]	; ax = FontMaker
		segmov	ds, es			; ds -> FontBuff
		mov	es, ss:gstateSeg	; es -> GState
		mov	di, DR_FONT_CHAR_METRICS ; di = function to call
		call	GrCallFontDriverID	; call font driver

		.leave
		ret
QuickCharMetrics	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharBoundX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for calculating character bounds

CALLED BY:	INTERNAL
		CheckCharBox
PASS:		dxah	- WBFixed position
		inherits stack frame from GrGetTextBounds
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharBoundX	proc	near
		.enter	inherit GrGetTextBoundsReal

		cmp	dx, ss:leftBound.WBF_int
		jl	newLeft
		jg	checkHigh
		cmp	ah, ss:leftBound.WBF_frac
		jb	newLeft
checkHigh:
		cmp	dx, ss:rightBound.WBF_int
		jg	newRight
		jl	done
		cmp	ah, ss:rightBound.WBF_frac
		ja	newRight
done:
		.leave
		ret

		; store new left bound
newLeft:
		movwbf	ss:leftBound, dxah
		jmp	checkHigh		; must do this, do to the way
						; we initialized the right
newRight:
		movwbf	ss:rightBound, dxah
		jmp	done
CharBoundX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharBoundY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for calculating character bounds

CALLED BY:	INTERNAL
		CheckCharBox
PASS:		dxah	- WBFixed position
		inherits stack frame from GrGetTextBounds
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CharBoundY	proc	near
		.enter	inherit GrGetTextBoundsReal

		cmp	dx, ss:topBound.WBF_int
		jl	newTop
		jg	checkHigh
		cmp	ah, ss:topBound.WBF_frac
		jb	newTop
checkHigh:
		cmp	dx, ss:bottomBound.WBF_int
		jg	newBottom
		jl	done
		cmp	ah, ss:bottomBound.WBF_frac
		ja	newBottom
done:
		.leave
		ret

		; store new top bound
newTop:
		movwbf	ss:topBound, dxah
		jmp	checkHigh		; must do this, do to the way
						; we initialized the bottom
newBottom:
		movwbf	ss:bottomBound, dxah
		jmp	done
CharBoundY	endp



GraphicsTextObscure	ends
