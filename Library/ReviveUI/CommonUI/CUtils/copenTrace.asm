COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Open
FILE:		openTrace.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

DESCRIPTION:
	This contains routines to support UserTrace, a utility that draws
	complicated objects made out of horizontal and vertical lines,
	using up to 30 parameters, in a much tighter space than other methods.

	$Id: copenTrace.asm,v 2.10 95/11/06 16:27:04 clee Exp $

------------------------------------------------------------------------------@

if not _ASSUME_BW_ONLY
DrawColor segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenTrace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traces an object using a compact table.  Data must be of
		format:

			byte  <command>, <argument>

		Where command is enumerated in TraceCmds, and argument is either
		a constant between -128 and 127, or a byte or word value in the
		structure pointed to by ss:bp whose offset is between 4 and 31.

		Examples:
			Args struct
				required	TraceArgs <>
				offset		byte
				offset2 	byte
			Args ends

			byte  VERT_LINE, 4
			byte  HORIZ_MOVE, BYTE_BP.offset
			byte  HORIZ_LINE, WORD_BP.offset2
			.
			.
			mov 	si, offset Examples
			mov	bp, sp
			sub	sp, size Args
			mov	[bp].offset, 3
			mov	[bp].offset2, 5
			clr	ax
			clr	bx
			call	OpenTrace
			mov	sp, bp

		A parameter structure passed to this routine is required to
		keep the first 2 words open for use by the routine.  Parameters
		come after this word.

CALLED BY:	test

PASS:		ds:si -- pointer to data to trace
		ss:bp -- pointer to parameters to use in SSBP arguments
		ax, bx -- x and y position to start drawing
		di -- gstate

RETURN:		si -- updated to end of data
		ax, bx -- pointing to last position

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


OpenTrace	proc	near
	mov	word ptr [bp].TA_curLineClr, 0ffffh	;init these to random
UT1:
	mov	cx, bx				;keep bx in cx
	mov	bl, ds:[si]			;get a command
	inc	si
	tst	bl				;see if done
	jz	UT90				;we are, branch
	clr	bh				;clear high byte
	shl	bx, 1				;double for word
	test	[bp].TA_flags, mask TRF_ROTATED	;see if rotated
	jz	UT5				;nop, branch
	add	bx, (offset rotatedRoutTab) - (offset traceRoutTab)  ;use rot
UT5:
	mov	bx, cs:traceRoutTab[bx-2]	;get actual offset
	mov	[bp].TA_routOffset, bx
	mov	bx, cx				;restore bx
	mov	cl, ds:[si]
	inc	si
	tst	cl				;see if negative
	js	UT20				;yes, constant, branch
	test	cl, WORD_BP			;see if we get from parameter
	jz	UT20				;nope, constant, branch

	test	cl, BYTE_SIZE			;see if this is a byte only
	pushf
	and	cx, (not BYTE_BP) and 0ffh	;clear SSBP bit and high byte
	xchg	cx, di				;di holds offset to arg, cx<-di
	mov	di, ss:[bp][di]			;get argument
	xchg	di, cx				;arg in cx, di restored
	popf					;is the argument a byte?
	jz	UT30				;no, branch
UT20:
	clr	ch				;clear high byte
	tst	cl				;see if signed
	jns	UT30				;nope, branch
	dec	ch				;else sign extend
UT30:
	call	[bp].TA_routOffset 		;call routine
	jmp	short UT1
UT90:
	ret
OpenTrace	endp


traceRoutTab	word	offset DoVertLine		;VERT_LINE
		word	offset DoHorizLine		;HORIZ_LINE
		word	offset DoVertLineMove		;VERT_LINE_MOVE
		word	offset DoHorizLineMove		;HORIZ_LINE_MOVE
		word	offset DoVertMove		;VERT_MOVE
		word	offset DoHorizMove		;HORIZ_MOVE
		word	offset DoDiagMove		;DIAG_MOVE
		word	offset DoLinePattern		;LINE_PATTERN
		word	offset DoAreaPattern		;AREA_PATTERN
		word	offset DoSetDx			;SET_DX
		word	offset DoSkip			;SKIP
		word	offset DoSetSelected		;SET_SELECTED
		word	offset DoFillSelected		;FILL_IF_SELECTED
		word	offset DoFRect			;FRECT
		word	offset DoRectMove		;RECT_MOVE
		word	offset DoFlipOrientation	;FLIP_ORIENTATION

rotatedRoutTab	word	offset DoRotVertLine		;VERT_LINE
		word	offset DoRotHorizLine		;HORIZ_LINE
		word	offset DoRotVertLineMove	;VERT_LINE_MOVE
		word	offset DoRotHorizLineMove	;HORIZ_LINE_MOVE
		word	offset DoRotVertMove		;VERT_MOVE
		word	offset DoRotHorizMove		;HORIZ_MOVE
		word	offset DoRotDiagMove		;DIAG_MOVE
		word	offset DoLinePattern		;LINE_PATTERN
		word	offset DoAreaPattern		;AREA_PATTERN
		word	offset DoSetDx			;SET_DX
		word	offset DoSkip			;SKIP
		word	offset DoSetSelected		;SET_SELECTED
		word	offset DoRotFillSelected	;FILL_IF_SELECTED
		word	offset DoRotFRect		;FRECT
		word	offset DoRotRectMove		;RECT_MOVE
		word	offset DoFlipOrientation	;FLIP_ORIENTATION




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoHorLine, etc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various routines to interpret trace data.

CALLED BY:	UserTrace

PASS:		cx -- argument to use
		ax, bx -- current x, y values
		dx -- possible second argument saved by Do2ndArg
		di -- gstate

RETURN:		ax, bx -- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	FLIP_ORIENTATION --
;	    Switches orientation on the fly.
;	A pretty weird thing to do, but there it is.
;
;	Example:
;	    FLIP_ORIENTATION, BYTE_BP.TA_flipFlag    
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DoFlipOrientation	proc	near
	tst	cl			;see if we need to flip the bit
	jz	exit			;no, exit
	xor	[bp].TA_flags, mask TRF_ROTATED
exit:
	ret
DoFlipOrientation	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	HORIZ_LINE --
;	    Draws an ARG-length line starting at ax,bx
;	    Line is drawn in color type specified in ARG2,
;	    right after the ARG.  Color types specify
;	    whether you are drawing a line that should be
;	    highlighted correctly in 3-D (LEFT_EDGE_COLOR,
;	    TOP_EDGE_COLOR, RIGHT_EDGE_COLOR, BOTTOM_EDGE-
;	    _COLOR, INTERMEDIATE_EDGE_COLOR), if you want
;	    the color for drawing text (TEXT_COLOR) or
;	    straight black in all situations (BLACK_COLOR).
;	    AREA_COLOR will draw in either a light or dark
;	    grey, depending on whether the item is selected.
;	    Destroys dx
;
;	Example:
;	    HORIZ_LINE, 10, TOP_EDGE_COLOR
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotVertLine	proc	near
	neg	cx
	FALL_THRU	DoHorizLine
DoRotVertLine	endp

DoHorizLine	proc	near
	tst	cx
	jz	UnloadArg
	js	DHL10
	dec	cx
	dec	cx
DHL10:
	inc	cx
	add	cx, ax
	jmp	DHLM15
DoHorizLine	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	HORIZ_LINE_MOVE --
;	    Draws an ARG-length line starting at ax,bx,
;	    moving to the end of the line as well.
;	    ARG2 specifies color.
;	    Destroys dx
;
;	Example:
;	    HORIZ_LINE_MOVE, 10, TOP_EDGE_COLOR
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotVertLineMove	proc	near
	neg	cx				;invert argument
	FALL_THRU	DoHorizLineMove
DoRotVertLineMove	endp

DoHorizLineMove	proc	near
	tst	cx
	jz	UnloadArg
	js	DHLM10
	dec	cx
	dec	cx
DHLM10:
	inc	cx
	push	ax
	add	ax, cx				;add offset to x value
	pop	cx
DHLM15	label	near
	push	ax, cx
	cmp	cx, ax				;see if right order
	ja	DHLM20				;good, branch
	xchg	cx, ax
DHLM20:
	call	ChooseLineColor			;get color to draw with
	call	GrDrawHLine			;go draw the horizontal line
	DoPop	cx, ax
UnloadArg	label	near
	ret
DoHorizLineMove	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	VERT_LINE --
;	    Draws an ARG-length line starting at ax,
;	    ARG2 specifies color.
;	    Destroys dx
;
;	Example:
;	    VERT_LINE, 5, LEFT_EDGE_COLOR
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotHorizLine	proc	near
	FALL_THRU	DoVertLine
DoRotHorizLine	endp

DoVertLine	proc	near
	tst	cx
	jz	UnloadArg
	js	DVL10
	dec	cx
	dec	cx
DVL10:
	inc	cx
	mov	dx, bx
	add	dx, cx
	jmp	DVLM15
DoVertLine	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	VERT_LINE_MOVE --
;	    Draws an ARG-length line starting at ax,bx
;	    and moves to the end of the line as well.
;	    ARG2 specifies color.
;	    Destroys dx.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotHorizLineMove	proc	near
	FALL_THRU	DoVertLineMove
DoRotHorizLineMove	endp

DoVertLineMove	proc	near
	tst	cx
	jz	UnloadArg
	js	DVLM10
	dec	cx
	dec	cx
DVLM10:
	inc	cx
	push	bx
	add	bx, cx				;add offset to current
	pop	dx
DVLM15	label	near
	push	bx, dx
	cmp	dx, bx
	ja	DVLM20
	xchg	dx, bx
DVLM20:
	call	ChooseLineColor
	call	GrDrawVLine	;
	DoPop	dx, bx
	ret
DoVertLineMove	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	VERT_MOVE --
;	    Draws a vertical line starting at ax, bx, to
;	    ax, bx+ARG (if not rotating).  Note that such
;	    a move is equivalent to a VERT_LINE_MOVE(ARG+1).
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotHorizMove	proc	near
	FALL_THRU	DoVertMove
DoRotHorizMove	endp

DoVertMove	proc	near
	add	bx, cx
	ret
DoVertMove	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	HORIZ_MOVE --
;	    Draws a horizontal line starting at ax, bx to
;	ax+ARG, bx (if not rotating).  Note that such
;	a move is equivalent to a HORIZ_LINE_MOVE(ARG+1).
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotVertMove	proc	near
	neg	cx
	FALL_THRU	DoHorizMove
DoRotVertMove	endp

DoHorizMove	proc	near
	add	ax, cx
	ret
DoHorizMove	endp

DoRotDiagMove	proc	near
	sub	ax, cx
	add	bx, cx
	ret
DoRotDiagMove	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	DIAG_MOVE --
;	    Draws a diagonal line starting at ax, bx to
;	ax+ARG, bx+ARG.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoDiagMove	proc	near
	add	ax, cx
	add	bx, cx
	ret
DoDiagMove	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	LINE_PATTERN, AREA_PATTERN --
;	   Sets the current pattern to ARG.
;
;	Example:
;	   LINE_PATTERN, GR_PSOLID
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoLinePattern	proc	near
	push	ax
	mov	ax, cx
	call	GrSetLineMask
	pop	ax
	ret
DoLinePattern	endp

DoAreaPattern	proc	near
	push	ax
	mov	ax, cx
	call	GrSetAreaMask
	pop	ax
	ret
DoAreaPattern	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	FILL_SELECTED --
;	   Possibly fills in the area with origin ax, bx
;	   with width ARG and height ARG2, where ARG2 has
;	   been set previously with a SET_DX command.  Fills
;	   in with the dark grey color if object is currently
;	   selected.
;
;	Example:
;	   SET_DX, 5			;Height of 5
;	   FILL_SELECTED, -3		;Height 3, upwards
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotFillSelected	proc	near
	neg	dx
	xchg	cx, dx
DoRotFillSelected	endp

DoFillSelected	proc	near
	call	GetAreaColor
	add	dx, bx
	add	cx, ax
	call	GrFillRect
	ret
DoFillSelected	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	FRECT --
;	   Draws a framed rectangle with origin ax, bx
;	   with width ARG and height ARG2, where ARG2 has
;	   been set previously with a SET_DX command.
;	   Only works for positive ARG and ARG2.
;
;	Example:
;	   SET_DX, 10			;width of 10
;	   FRECT, 5			;width of 5
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotFRect	proc	near
	neg	dx
	xchg	cx, dx
	FALL_THRU	DoFRect
DoRotFRect	endp

DoFRect		proc	near		;limited capabilities....
	call	ChooseLineColor
	push	ax, bx
	call	SetupRect
	call	GrDrawRect
	DoPop	bx, ax
	ret
DoFRect		endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	RECT_MOVE --
;	   Fills in the area with origin ax, bx
;	   with width ARG and height ARG2, where ARG2 has
;	   been set previously with a SET_DX command. Color
;	   type comes from ARG3, the next parameter after ARG.
;	   Adds width and height to the pen position.
;
;	Example:
;	   SET_DX, 10			;height of 10
;	   RECT_MOVE, 5, BLACK_COLOR   ;width 5, in black
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DoRotRectMove	proc	near
	neg	dx			;invert vertical dimension
	xchg	cx, dx			;and switch places
	FALL_THRU	DoRectMove
DoRotRectMove	endp


DoRectMove	proc	near
	call	ChooseAreaColor		;get it over with
	call	SetupRect		;set up parameters
	jz	DR90			;a coord is zero, exit
	call	GrFillRect		;draw the rectangle
DR90:
	ret
DoRectMove	endp


SetupRect	proc	near
	push	bx, ax			;current x & y
	add	bx, dx			;save y param to current y
	add	ax, cx			;save x param to current x
	tst	cx
	jz	DRM20			;don't decrement if zero
	js	DRM10			;if cx negative, increment width
	dec	ax			;else decrement the positive width
	dec	ax
DRM10:
	inc	ax
DRM20:
	tst	dx			;if dx=0, skip everything
	jz	DRM40
	js	DRM30			;if dx negative, go increment height
	dec	bx			;else decrement positive height
	dec	bx
DRM30:
	inc	bx
	tst	cx			;check for cx = 0
DRM40:
	DoPop	cx, dx			;old current x and y in cx & dx
	ret				;else we're done
SetupRect	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	SET_DX --
;		Sets dx to ARG.  Precedes a RECT_MOVE,
;	FILL_SELECTED, or FRECT command.
;
;	Example:
;	    SET_DX, 5			;set height
;	    FRECT, BYTE_BP.rectWidth	;width passed
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DoSetDx		proc	near
	mov	dx, cx
	ret
DoSetDx		endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	SKIP --
;	    Allows skipping of up to 256 bytes of data.
;	Currently doesn't allow words to be passed; this
;	can easily be changed.
;
;	Example:
;	    SKIP, 5			;skip 5 bytes
;	    SKIP, BYTE_BP.skip		;skip [bp].skip bytes
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoSkip		proc	near
	clr	ch			;defeat the sign-extend
	add	si, cx
	ret
DoSkip		endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	SET_SELECTED --
;	    Set whether an object is selected or not.  This
;	is done through fourth byte of the passed structure (the
;	first byte of the user-defined structure).
;	The caller sets a value here which is
;	is used to compare with in the SET_SELECTED command.
;	If the ARG is the same as the value in TA_state,
;	the object will be considered selected for all
;	drawing commands that follow, until another SET_SEL-
;	ECTED command comes along.  Object "selection" is
;	used for choice of color.
;
;	Examples:
;	    mov	[bp].TA_state, 3
;	    call UserTrace
;	    .
;	    .
;	    SET_SELECTED, 2			;object will not be selected
;	    VERT_LINE, 10, LEFT_EDGE_COLOR	;normal left edge (white)
;	    SET_SELECTED, 3			;object will be selected
;	    VERT_LINE, 10, LEFT_EDGE_COLOR	;"depressed" left edge (black)
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoSetSelected	proc	near
	and	[bp].TA_flags, not (mask TRF_SELECTED or mask TRF_NEXT_SEL)
	cmp	[bp].TA_state, cl			;see if item selected
	jne	DSS10					;no, branch
	or	[bp].TA_flags, mask TRF_SELECTED	;else set flag
DSS10:
	inc	cl					;see if next flag set
	cmp	[bp].TA_state, cl
	jz	DSS20
	or	[bp].TA_flags, mask TRF_NEXT_SEL	;keep this for reference
DSS20:
	ret
DoSetSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Chooses the line color to draw the line in.

CALLED BY:	DoHorizLine, DoVertLine

PASS:		ss:[bp].TA_flags -- flags for drawing
		ds:si -- pointer to drawing data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ChooseLineColor	proc	near
	push	ax			;save the all-important ax
	lodsb				;get the color type in al
	call	ChooseColor		;returns color to use in ax
	cmp	al, [bp].TA_curLineClr	;see if changed
	je	CLC10			;no, branch
	mov	[bp].TA_curLineClr, al
	call	GrSetLineColor		;and set the color
CLC10:
	pop	ax
	ret				;returns sign set if doing shadow
ChooseLineColor	endp

GetAreaColor	proc	near
	push	ax
	mov	al, AREA_COLOR
	jmp	short	CAC10
GetAreaColor	endp

ChooseAreaColor	proc	near
	push	ax
	lodsb
CAC10	label	near
	call	ChooseColor		;color to use returned here
	cmp	al, [bp].TA_curAreaClr	;see if changed
	je	CAC90			;no, branch
	mov	[bp].TA_curAreaClr, al
	call	GrSetAreaColor		;and set it
CAC90:
	pop	ax
	ret
ChooseAreaColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets correct color for object, based on what kind of color
		is desired for drawing, whtat the state of the object being
		draw is (TRF_SELECTED), and what color setup is being used for
		this window.

		Chooses colors as follows:
				not sel	select	not sel	select
						rotated	rotated

	LEFT_EDGE_COLOR		C_WHITE	C_BLACK	C_WHITE	C_BLACK
	TOP_EDGE_COLOR		C_WHITE	C_BLACK	C_DARK_GREY	C_WHITE
	RIGHT_EDGE_COLOR	C_DARK_GREY	C_WHITE	C_DARK_GREY	C_WHITE
	BOTTOM_EDGE_COLOR	C_DARK_GREY	C_WHITE	C_WHITE	C_BLACK
	JOIN_EDGE_COLOR		C_DARK_GREY	C_WHITE	C_DARK_GREY	C_WHITE
	AREA_COLOR		C_LIGHT_GREY	C_DARK_GREY	C_LIGHT_GREY	C_DARK_GREY
	TEXT_COLOR		C_BLACK	C_BLACK	C_BLACK	C_BLACK
	BLACK_COLOR		C_DARK_GREY	C_BLACK	C_DARK_GREY	C_BLACK	

CALLED BY:	DoLineColor, DoAreaColor

PASS:		ss:[bp].TA_flags -- checks flags to see what color set to use
		cx -- type of color needed, from TEXT_COLOR, EDGE_COLOR,
		      BACK_COLOR, HILIGHT_COLOR, SHADOW_COLOR

RETURN:		cx, ax -- the color to use

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ChooseColor	proc	near
	cmp	al, JOIN_EDGE_COLOR
	jne	CC5
	mov	al, BOTTOM_EDGE_COLOR		;assume vertical, use bottom
	test	[bp].TA_flags, mask TRF_ROTATED	;vertical (rotated), branch
	jnz	CC40
	mov	al, C_BLACK			;assume black is color we want
	test	[bp].TA_flags, mask TRF_NEXT_SEL ;see if next obj is selected
	jz	CC60				;nope, branch with black
	mov	al, C_WHITE			;else use white
	jmp	short CC60
CC5:
	cmp	al, TEXT_COLOR			;if text color, use black
	jne	CC10
	mov	al, C_BLACK			;selected:unselected
	jmp	short CC60
CC10:
	cmp	al, AREA_COLOR		 	;if hilite clr, get from gstate
	jne	CC20
	mov	ax, (C_DARK_GREY shl 8) or C_LIGHT_GREY	;selected:unselected
	jmp	short CC50
CC20:
	cmp	al, BLACK_COLOR			;always in black?
	jne	CC30
	mov	ax, (C_BLACK shl 8) or C_DARK_GREY	;yes, draw in dark grey.
	jmp	short CC50
CC30:
	test	[bp].TA_flags, mask TRF_ROTATED	;see if rotating
	jz	CC40				;no, branch
	dec	al				;else LTRB becomes TRB-0ffh
CC40:
	test	al, TOP_EDGE_COLOR		;see if 2nd bit set (L/T)
	mov	ax, (C_BLACK shl 8) or C_WHITE	;assume L/T, black:white
	jnz	CC50				;L/T, branch
	mov	ax, (C_WHITE shl 8) or C_DARK_GREY	;else flip these
CC50:
	test	[bp].TA_flags, mask TRF_SELECTED  ;see if object selected
	jz	CC60				;branch
	mov	al, ah				;else use selected color
CC60:
	clr	ah				;clear high bit
CC90:
	ret
ChooseColor	endp


DrawColor ends
endif		; if not _ASSUME_BW_ONLY



DrawBW segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenTraceBW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traces an object using a compact table.  Data must be of
		format:

			byte  <command>, <argument>

		Where command is enumerated in TraceCmds, and argument is either
		a constant between -128 and 127, or a byte or word value in the
		structure pointed to by ss:bp whose offset is between 4 and 31.

		Examples:
			Args struct
				required	TraceArgs <>
				offset		byte
				offset2 	byte
			Args ends

			byte  VERT_LINE, 4
			byte  HORIZ_MOVE, BYTE_BP.offset
			byte  HORIZ_LINE, WORD_BP.offset2
			.
			.
			mov 	si, offset Examples
			mov	bp, sp
			sub	sp, size Args
			mov	[bp].offset, 3
			mov	[bp].offset2, 5
			clr	ax
			clr	bx
			call	UserTrace
			mov	sp, bp

		A parameter structure passed to this routine is required to
		keep the first 2 words open for use by the routine.  Parameters
		come after this word.

CALLED BY:	test

PASS:		ds:si -- pointer to data to trace
		ss:bp -- pointer to parameters to use in SSBP arguments
		ax, bx -- x and y position to start drawing
		di -- gstate

RETURN:		si -- updated to end of data
		ax, bx -- pointing to last position

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


OpenTraceBW	proc	near
	mov	word ptr [bp].TA_curLineClr, 0ffffh	;init these to random
UT1BW:
	mov	cx, bx				;keep bx in cx
	mov	bl, ds:[si]			;get a command
	inc	si
	tst	bl				;see if done
	jz	UT90BW				;we are, branch
	clr	bh				;clear high byte
	shl	bx, 1				;double for word
	test	[bp].TA_flags, mask TRF_ROTATED	;see if rotated
	jz	UT5BW				;nop, branch
	add	bx, (offset rotatedRoutTabBW) - (offset traceRoutTabBW) ;use rot
UT5BW:
	mov	bx, cs:traceRoutTabBW[bx-2]	;get actual offset
	mov	[bp].TA_routOffset, bx
	mov	bx, cx				;restore bx
	mov	cl, ds:[si]
	inc	si
	tst	cl				;see if negative
	js	UT20BW				;yes, constant, branch
	test	cl, WORD_BP			;see if we get from parameter
	jz	UT20BW				;nope, constant, branch

	test	cl, BYTE_SIZE			;see if this is a byte only
	pushf
	and	cx, (not BYTE_BP) and 0ffh	;clear SSBP bit and high byte
	xchg	cx, di				;di holds offset to arg, cx<-di
	mov	di, ss:[bp][di]			;get argument
	xchg	di, cx				;arg in cx, di restored
	popf					;is the argument a byte?
	jz	UT30BW				;no, branch
UT20BW:
	clr	ch				;clear high byte
	tst	cl				;see if signed
	jns	UT30BW				;nope, branch
	dec	ch				;else sign extend
UT30BW:
	call	[bp].TA_routOffset 		;call routine
	jmp	short UT1BW
UT90BW:
	ret
OpenTraceBW	endp


traceRoutTabBW	word	offset DoVertLineBW		;VERT_LINE
		word	offset DoHorizLineBW		;HORIZ_LINE
		word	offset DoVertLineMoveBW		;VERT_LINE_MOVE
		word	offset DoHorizLineMoveBW	;HORIZ_LINE_MOVE
		word	offset DoVertMoveBW		;VERT_MOVE
		word	offset DoHorizMoveBW		;HORIZ_MOVE
		word	offset DoDiagMoveBW		;DIAG_MOVE
		word	offset DoLinePatternBW		;LINE_PATTERN
		word	offset DoAreaPatternBW		;AREA_PATTERN
		word	offset DoSetDxBW		;SET_DX
		word	offset DoSkipBW			;SKIP
		word	offset DoSetSelectedBW		;SET_SELECTED
		word	offset DoFillSelectedBW		;FILL_IF_SELECTED
		word	offset DoFRectBW		;FRECT
		word	offset DoRectMoveBW		;RECT_MOVE
		word	offset DoFlipOrientationBW	;FLIP_ORIENTATION

rotatedRoutTabBW word	offset DoRotVertLineBW		;VERT_LINE
		word	offset DoRotHorizLineBW		;HORIZ_LINE
		word	offset DoRotVertLineMoveBW	;VERT_LINE_MOVE
		word	offset DoRotHorizLineMoveBW	;HORIZ_LINE_MOVE
		word	offset DoRotVertMoveBW		;VERT_MOVE
		word	offset DoRotHorizMoveBW		;HORIZ_MOVE
		word	offset DoRotDiagMoveBW		;DIAG_MOVE
		word	offset DoLinePatternBW		;LINE_PATTERN
		word	offset DoAreaPatternBW		;AREA_PATTERN
		word	offset DoSetDxBW		;SET_DX
		word	offset DoSkipBW			;SKIP
		word	offset DoSetSelectedBW		;SET_SELECTED
		word	offset DoRotFillSelectedBW	;FILL_IF_SELECTED
		word	offset DoRotFRectBW		;FRECT
		word	offset DoRotRectMoveBW		;RECT_MOVE
		word	offset DoFlipOrientationBW	;FLIP_ORIENTATION



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoHorLineBW, etc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Various routines to interpret trace data.

CALLED BY:	UserTrace

PASS:		cx -- argument to use
		ax, bx -- current x, y values
		dx -- possible second argument saved by Do2ndArg
		di -- gstate

RETURN:		ax, bx -- updated

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	FLIP_ORIENTATION --
;	    Switches orientation on the fly.
;	A pretty weird thing to do, but there it is.
;
;	Example:
;	    FLIP_ORIENTATION, BYTE_BP.TA_flipFlag    
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DoFlipOrientationBW	proc	near
	tst	cl			;see if we need to flip the bit
	jz	exit			;no, exit
	xor	[bp].TA_flags, mask TRF_ROTATED
exit:
	ret
DoFlipOrientationBW	endp
			

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	HORIZ_LINE --
;	    Draws an ARG-length line starting at ax,bx
;	    Line is drawn in color type specified in ARG2,
;	    right after the ARG.  Color types specify
;	    whether you are drawing a line that should be
;	    highlighted correctly in 3-D (LEFT_EDGE_COLOR,
;	    TOP_EDGE_COLOR, RIGHT_EDGE_COLOR, BOTTOM_EDGE-
;	    _COLOR, INTERMEDIATE_EDGE_COLOR), if you want
;	    the color for drawing text (TEXT_COLOR) or
;	    straight black in all situations (BLACK_COLOR).
;	    AREA_COLOR will draw in either a light or dark
;	    grey, depending on whether the item is selected.
;	    Destroys dx
;
;	Example:
;	    HORIZ_LINE, 10, TOP_EDGE_COLOR
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotVertLineBW	proc	near
	neg	cx
	FALL_THRU	DoHorizLineBW
DoRotVertLineBW	endp

DoHorizLineBW	proc	near
	tst	cx
	jz	UnloadArgBW
	js	DHL10BW
	dec	cx
	dec	cx
DHL10BW:
	inc	cx
	add	cx, ax
	jmp	DHLM15BW
DoHorizLineBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	HORIZ_LINE_MOVE --
;	    Draws an ARG-length line starting at ax,bx,
;	    moving to the end of the line as well.
;	    ARG2 specifies color.
;	    Destroys dx
;
;	Example:
;	    HORIZ_LINE_MOVE, 10, TOP_EDGE_COLOR
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotVertLineMoveBW	proc	near
	neg	cx				;invert argument
	FALL_THRU	DoHorizLineMoveBW
DoRotVertLineMoveBW	endp

DoHorizLineMoveBW	proc	near
	tst	cx
	jz	UnloadArgBW
	js	DHLM10BW
	dec	cx
	dec	cx
DHLM10BW:
	inc	cx
	push	ax
	add	ax, cx				;add offset to x value
	pop	cx
DHLM15BW	label	near
	push	ax, cx
	cmp	cx, ax				;see if right order
	ja	DHLM20BW			;good, branch
	xchg	cx, ax
DHLM20BW:
	call	ChooseLineColorBW		;get color to draw with
	call	GrDrawHLine			;go draw the horizontal line
	DoPop	cx, ax
	ret
DoHorizLineMoveBW	endp

UnloadArgBW	proc	near
	inc	si
	ret
UnloadArgBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	VERT_LINE --
;	    Draws an ARG-length line starting at ax,
;	    ARG2 specifies color.
;	    Destroys dx
;
;	Example:
;	    VERT_LINE, 5, LEFT_EDGE_COLOR
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotHorizLineBW	proc	near
	FALL_THRU	DoVertLineBW
DoRotHorizLineBW	endp

DoVertLineBW	proc	near
	tst	cx
	jz	UnloadArgBW
	js	DVL10BW
	dec	cx
	dec	cx
DVL10BW:
	inc	cx
	mov	dx, bx
	add	dx, cx
	jmp	DVLM15BW
DoVertLineBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	VERT_LINE_MOVE --
;	    Draws an ARG-length line starting at ax,bx
;	    and moves to the end of the line as well.
;	    ARG2 specifies color.
;	    Destroys dx.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotHorizLineMoveBW	proc	near
	FALL_THRU	DoVertLineMoveBW
DoRotHorizLineMoveBW	endp

DoVertLineMoveBW	proc	near
	tst	cx
	jz	UnloadArgBW
	js	DVLM10BW
	dec	cx
	dec	cx
DVLM10BW:
	inc	cx
	push	bx
	add	bx, cx				;add offset to current
	pop	dx
DVLM15BW	label	near
	push	bx, dx
	cmp	dx, bx
	ja	DVLM20BW
	xchg	dx, bx
DVLM20BW:
	call	ChooseLineColorBW
	call	GrDrawVLine
	DoPop	dx, bx
	ret
DoVertLineMoveBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	VERT_MOVE --
;	    Draws a vertical line starting at ax, bx, to
;	    ax, bx+ARG (if not rotating).  Note that such
;	    a move is equivalent to a VERT_LINE_MOVE(ARG+1).
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotHorizMoveBW	proc	near
	FALL_THRU	DoVertMoveBW
DoRotHorizMoveBW	endp

DoVertMoveBW	proc	near
	add	bx, cx
	ret
DoVertMoveBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	HORIZ_MOVE --
;	    Draws a horizontal line starting at ax, bx to
;	ax+ARG, bx (if not rotating).  Note that such
;	a move is equivalent to a HORIZ_LINE_MOVE(ARG+1).
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotVertMoveBW	proc	near
	neg	cx
	FALL_THRU	DoHorizMoveBW
DoRotVertMoveBW	endp

DoHorizMoveBW	proc	near
	add	ax, cx
	ret
DoHorizMoveBW	endp

DoRotDiagMoveBW	proc	near
	sub	ax, cx
	add	bx, cx
	ret
DoRotDiagMoveBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	DIAG_MOVE --
;	    Draws a diagonal line starting at ax, bx to
;	ax+ARG, bx+ARG.
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoDiagMoveBW	proc	near
	add	ax, cx
	add	bx, cx
	ret
DoDiagMoveBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	LINE_PATTERN, AREA_PATTERN --
;	   Sets the current pattern to ARG.
;
;	Example:
;	   LINE_PATTERN, GR_PSOLID
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoLinePatternBW	proc	near
	push	ax
	mov	ax, cx
	call	GrSetLineMask
	pop	ax
	ret
DoLinePatternBW	endp

DoAreaPatternBW	proc	near
	push	ax
	mov	ax, cx
	call	GrSetAreaMask
	pop	ax
	ret
DoAreaPatternBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	FILL_SELECTED --
;	   Possibly fills in the area with origin ax, bx
;	   with width ARG and height ARG2, where ARG2 has
;	   been set previously with a SET_DX command.  Fills
;	   in with the dark grey color if object is currently
;	   selected.
;
;	Example:
;	   SET_DX, 5			;Height of 5
;	   FILL_SELECTED, -3		;Height 3, upwards
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotFillSelectedBW	proc	near
	neg	dx
	xchg	cx, dx
DoRotFillSelectedBW	endp

DoFillSelectedBW	proc	near
	call	GetAreaColorBW
	add	dx, bx
	add	cx, ax
	call	GrFillRect
	ret
DoFillSelectedBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	FRECT --
;	   Draws a framed rectangle with origin ax, bx
;	   with width ARG and height ARG2, where ARG2 has
;	   been set previously with a SET_DX command.
;	   Only works for positive ARG and ARG2.
;
;	Example:
;	   SET_DX, 10			;width of 10
;	   FRECT, 5			;width of 5
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoRotFRectBW	proc	near
	neg	dx
	xchg	cx, dx
	FALL_THRU	DoFRectBW
DoRotFRectBW	endp

DoFRectBW		proc	near		;limited capabilities....
	call	ChooseLineColorBW
	push	ax, bx
	call	SetupRectBW
	call	GrDrawRect
	DoPop	bx, ax
	ret
DoFRectBW		endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	RECT_MOVE --
;	   Fills in the area with origin ax, bx
;	   with width ARG and height ARG2, where ARG2 has
;	   been set previously with a SET_DX command. Color
;	   type comes from ARG3, the next parameter after ARG.
;	   Adds width and height to the pen position.
;
;	Example:
;	   SET_DX, 10			;height of 10
;	   RECT_MOVE, 5, BLACK_COLOR   ;width 5, in black
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DoRotRectMoveBW	proc	near
	neg	dx			;invert vertical dimension
	xchg	cx, dx			;and switch places
	FALL_THRU	DoRectMoveBW
DoRotRectMoveBW	endp


DoRectMoveBW	proc	near
	call	ChooseAreaColorBW	;get it over with
	call	SetupRectBW		;set up parameters
	jz	DR90BW			;a coord is zero, exit
	call	GrFillRect		;draw the rectangle
DR90BW:
	ret
DoRectMoveBW	endp


SetupRectBW	proc	near
	push	bx, ax			;current x & y
	add	bx, dx			;save y param to current y
	add	ax, cx			;save x param to current x
	tst	cx
	jz	DRM20BW			;don't decrement if zero
	js	DRM10BW			;if cx negative, increment width
	dec	ax			;else decrement the positive width
	dec	ax
DRM10BW:
	inc	ax
DRM20BW:
	tst	dx			;if dx=0, skip everything
	jz	DRM40BW
	js	DRM30BW			;if dx negative, go increment height
	dec	bx			;else decrement positive height
	dec	bx
DRM30BW:
	inc	bx
	tst	cx			;check for cx = 0
DRM40BW:
	DoPop	cx, dx			;old current x and y in cx & dx
	ret				;else we're done
SetupRectBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	SET_DX --
;		Sets dx to ARG.  Precedes a RECT_MOVE,
;	FILL_SELECTED, or FRECT command.
;
;	Example:
;	    SET_DX, 5			;set height
;	    FRECT, BYTE_BP.rectWidth	;width passed
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


DoSetDxBW		proc	near
	mov	dx, cx
	ret
DoSetDxBW	endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	SKIP --
;	    Allows skipping of up to 256 bytes of data.
;	Currently doesn't allow words to be passed; this
;	can easily be changed.
;
;	Example:
;	    SKIP, 5			;skip 5 bytes
;	    SKIP, BYTE_BP.skip		;skip [bp].skip bytes
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoSkipBW		proc	near
	clr	ch			;defeat the sign-extend
	add	si, cx
	ret
DoSkipBW		endp

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;
;	SET_SELECTED --
;	    Set whether an object is selected or not.  This
;	is done through fourth byte of the passed structure (the
;	first byte of the user-defined structure).
;	The caller sets a value here which is
;	is used to compare with in the SET_SELECTED command.
;	If the ARG is the same as the value in TA_state,
;	the object will be considered selected for all
;	drawing commands that follow, until another SET_SEL-
;	ECTED command comes along.  Object "selection" is
;	used for choice of color.
;
;	Examples:
;	    mov	[bp].TA_state, 3
;	    call UserTrace
;	    .
;	    .
;	    SET_SELECTED, 2			;object will not be selected
;	    VERT_LINE, 10, LEFT_EDGE_COLOR	;normal left edge (white)
;	    SET_SELECTED, 3			;object will be selected
;	    VERT_LINE, 10, LEFT_EDGE_COLOR	;"depressed" left edge (black)
;
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DoSetSelectedBW	proc	near
	and	[bp].TA_flags, not (mask TRF_SELECTED or mask TRF_NEXT_SEL)
	cmp	[bp].TA_state, cl			;see if item selected
	jne	DSS10BW					;no, branch
	or	[bp].TA_flags, mask TRF_SELECTED	;else set flag
DSS10BW:
	inc	cl					;see if next flag set
	cmp	[bp].TA_state, cl
	jz	DSS20BW
	or	[bp].TA_flags, mask TRF_NEXT_SEL	;keep this for reference
DSS20BW:
	ret
DoSetSelectedBW	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseLineColorBW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Chooses the line color to draw the line in.

CALLED BY:	DoHorizLine, DoVertLine

PASS:		ss:[bp].TA_flags -- flags for drawing
		ds:si -- pointer to drawing data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ChooseLineColorBW	proc	near
	push	ax			;save the all-important ax
	mov	al, TEXT_COLOR
	call	ChooseColorBW		;returns color to use in ax
	call	GrSetLineColor		;and set the color
	pop	ax
	ret				;returns sign set if doing shadow
ChooseLineColorBW	endp

GetAreaColorBW	proc	near
	push	ax
	mov	al, AREA_COLOR
	jmp	short CAC90BW
GetAreaColorBW	endp

ChooseAreaColorBW	proc	near
	push	ax
	mov	al, BLACK_COLOR
CAC90BW	label	near
	call	ChooseColorBW		;color to use returned here
	call	GrSetAreaColor		;and set it
	pop	ax
	ret
ChooseAreaColorBW	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseColorBW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets correct color for object, based on what kind of color
		is desired for drawing, whtat the state of the object being
		draw is (TRF_SELECTED), and what color setup is being used for
		this window.

		Chooses colors as follows:
				not sel	select	not sel	select
						rotated	rotated

	LEFT_EDGE_COLOR		C_WHITE	C_BLACK	C_WHITE	C_BLACK
	TOP_EDGE_COLOR		C_WHITE	C_BLACK	C_BLACK	C_WHITE
	RIGHT_EDGE_COLOR	C_BLACK	C_WHITE	C_BLACK	C_WHITE
	BOTTOM_EDGE_COLOR	C_BLACK	C_WHITE	C_WHITE	C_BLACK
	AREA_COLOR		C_LIGHT_GREY	C_DARK_GREY	C_LIGHT_GREY	C_DARK_GREY
	TEXT_COLOR		C_BLACK	C_BLACK	C_BLACK	C_BLACK

CALLED BY:	DoLineColor, DoAreaColor

PASS:		ss:[bp].TA_flags -- checks flags to see what color set to use
		cx -- type of color needed, from TEXT_COLOR, EDGE_COLOR,
		      BACK_COLOR, HILIGHT_COLOR, SHADOW_COLOR

RETURN:		cx, ax -- the color to use

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ChooseColorBW	proc	near
	cmp	al, TEXT_COLOR			;if text color, use black
	jne	CCBW10
	mov	ax, (C_WHITE shl 8) or C_BLACK	;selected: unselected
	jmp	short CCBW50
CCBW10:
	cmp	al, AREA_COLOR		 	;if hilite clr, get from gstate
	jne	CCBW20
	mov	ax, (C_BLACK shl 8) or C_WHITE	;selected:unselected
	jmp	short CCBW50
CCBW20:
	clr	ax				;draw all else in black.
	jmp	short CCBW90
CCBW50:
	test	[bp].TA_flags, mask TRF_SELECTED  ;see if object selected
	jz	CCBW60				;branch
	xchg	al, ah				;else use selected color
CCBW60:
	clr	ah				;clear high bit
CCBW90:
	ret
ChooseColorBW	endp

DrawBW ends

