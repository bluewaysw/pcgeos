COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1998 -- All Rights Reserved

PROJECT:	Newdeal
MODULE:		
FILE:		uiOtherColor.asm

AUTHOR:		Gene Anderson, Mar 31, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/31/98		Initial revision


DESCRIPTION:
	Code for other color selectors

	$Id: uiOtherColor.asm,v 1.2 98/05/08 19:29:03 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ColorSelectorCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorOtherDialogApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle apply

CALLED BY:	MSG_GEN_APPLY

PASS:		*ds:si	= ColorOtherDialogClass object
		ds:di	= ColorOtherDialogClass instance data
		ds:bx	= ColorOtherDialogClass object (same as *ds:si)
		es 	= segment of ColorOtherDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/7/01   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorOtherDialogApply	method dynamic ColorOtherDialogClass, 
					MSG_GEN_APPLY
	;
	; do the normal stuff
	;
		mov	di, offset ColorOtherDialogClass
		call	ObjCallSuperNoLock
	;
	; if we're modal, be sure we close
	;
		mov	ax, MSG_GEN_INTERACTION_GET_ATTRS
		call	ObjCallInstanceNoLock
		test	cl, mask GIA_MODAL
		jz	done
		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		call	ObjCallInstanceNoLock
done:
		ret
ColorOtherDialogApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindEnclosingDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the enclosing GenInteraction if any

CALLED BY:	UTILITY

PASS:		^lcx:dx - object to begin searching at
RETURN:		carry - set if found
		    ^lcx:dx - enclosing GenInteraction
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/15/01   	broke out from ColorOtherDialogIntInitiate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindEnclosingDialog	proc	far

findDialogLoop:
	;
	; get parent
	;
		push	si, bp
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_FIND_PARENT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; find nearest interaction looking up
	;
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_GUP_FIND_OBJECT_OF_CLASS
		mov	cx, segment GenInteractionClass
		mov	dx, offset GenInteractionClass
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si, bp
		jnc	done			;no more interactions
	;
	; is it a dialog?
	;
		push	si, bp
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_INTERACTION_GET_VISIBILITY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	al, cl			; al = GenInteractionVisibility
		movdw	cxdx, bxsi
		pop	si, bp

		cmp	al, GIV_DIALOG
		jne	findDialogLoop

		stc					;carry <- found

done:
		ret
FindEnclosingDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorOtherDialogInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set dialog moniker based on parent dialog moniker
		dialog moniker = strcat(parent dialog moniker,": Custom Color")

CALLED BY:	MSG_GEN_INTERACTION_INITIATE

PASS:		*ds:si	= ColorOtherDialogClass object
		ds:di	= ColorOtherDialogClass instance data
		ds:bx	= ColorOtherDialogClass object (same as *ds:si)
		es 	= segment of ColorOtherDialogClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/31/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorOtherDialogInteractionInitiate	method dynamic ColorOtherDialogClass, 
					MSG_GEN_INTERACTION_INITIATE
monikerText	local	PathName
	.enter

	mov	{byte}ss:[monikerText], C_NULL

	mov	cx, ds:[LMBH_handle]
	mov	dx, si

	call	FindEnclosingDialog
	LONG jnc	callSuper

	push	si, bp
	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, bp

	tst	ax
	jz	callSuper

	call	ObjSwapLock

	mov	di, ax
	mov	di, ds:[di]		; ds:di = VisMoniker
	test	ds:[di].VM_type, mask VMT_MONIKER_LIST or mask VMT_GSTRING
	jnz	unlock

	push	bx, si, ds, es
	segmov	es, ss
	lea	si, ss:[monikerText]		; es:si = moniker text buffer
	add	di, VM_data+VMT_text	; ds:di = moniker text
	xchg	si, di
	LocalCopyString

	mov	bx, handle CustomColorString
	call	MemLock
	mov	ds, ax
	mov	si, offset CustomColorString
	mov	si, ds:[si]
	LocalPrevChar	esdi
	LocalCopyString
	call	MemUnlock
	pop	bx, si, ds, es
unlock:
	call	ObjSwapUnlock

	tst	{byte}ss:[monikerText]
	jz	callSuper

	push	bp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, ss
	lea	dx, ss:[monikerText]
	mov	bp, VUM_MANUAL
	call	ObjCallInstanceNoLock
	pop	bp

callSuper:
	.leave

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, offset ColorOtherDialogClass
	GOTO	ObjCallSuperNoLock	

ColorOtherDialogInteractionInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the ColorSelector's current color

CALLED BY:	UTILITY

PASS:		*ds:si - ColorSelector child object
RETURN:		al - red
		ah - ColorFlag
		bl - green
		bh - blue
		z flag - clear (jnz) if color indeterminate
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/1/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GetCurrentColor	proc	near
		uses	di, si, bp, cx, dx

		.enter
		mov	ax, MSG_COLOR_SELECTOR_GET_COLOR
		call	CallController
		mov	bx, dx
		mov	ax, cx				;bx:ax <- ColorQuad
		tst	bp

		.leave
		ret
GetCurrentColor	endp

GetCurrentColorRGB	proc	near
		pushf
		call	GetCurrentColor
		cmp	ah, CF_INDEX
		mov	ah, al				;ah <- index
		jne	gotColor
		call	GrMapColorIndex			;al,bl,bh <- RGB
gotColor:
		popf
		ret
GetCurrentColorRGB	endp

CallController	proc	near
		uses	bx, si
		.enter

		mov	bx, ds:OLMBH_output.handle
		mov	si, ds:OLMBH_output.chunk
		call	CallObjMessage

		.leave
		ret
CallController	endp

CallObjMessage	proc	near
		uses	di
		.enter

		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
CallObjMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Color256SelectorDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw our 256 color selector

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - GState
RETURN:		carry - set if the state has changed
DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

Color256SelectorDraw	method dynamic	Color256SelectorClass,
					MSG_VIS_DRAW

leftEdge	local	word
topEdge		local	word
objWidth	local	word
objHeight	local	word
curColor	local	Color
tempR		local	byte
tempGB		local	word
isIndex		local	byte

		mov	di, bp				;di <- GState

		.enter
		call	GrSaveState
	;
	; Figure out where to draw and do some setup
	;
		mov	ss:isIndex, TRUE
		call	GetCurrentColor
		cmp	ah, CF_INDEX
		mov	ah, al				;ah <- index
		je	gotColor
	;
	; If the color is RGB, see if maps exactly to an index
	;
		mov	ss:tempR, al
		mov	ss:tempGB, bx
		call	GrMapColorRGB
		cmp	al, ss:tempR
		jne	notIndex
		cmp	bx, ss:tempGB
		je	gotColor
notIndex:
		mov	ss:isIndex, FALSE
gotColor:
		mov	ss:curColor, ah

		call	VisGetBounds
		mov	ss:leftEdge, ax
		mov	ss:topEdge, bx
		sub	cx, ax
		mov	ss:objWidth, cx
		sub	dx, bx
		mov	ss:objHeight, dx
		clr	cx
		clr	dx
drawLoop:
	;
	; Set the color based on the position
	;
		mov	ax, cx
		mov	bx, dx				;(ax,bx) <- (x,y)
		call	PosToColor
		cmp	al, C_UNUSED_0
		je	nextSquare			;branch if empty
		call	GrSetAreaColor
	;
	; Draw a rectangle
	;
		push	cx, dx
		add	cx, ss:leftEdge
		mov	ax, cx				;ax <- box left
		add	cx, COLOR_256_CELL_WIDTH	;cx <- box right
		add	dx, ss:topEdge
		mov	bx, dx
		add	bx, COLOR_256_CELL_HEIGHT	;bx <- box bottom
		call	GrFillRect
		pop	cx, dx
	;
	; To the end of the row?
	;
nextSquare:
		add	cx, COLOR_256_CELL_WIDTH
		cmp	cx, ss:objWidth
		jb	drawLoop
	;
	; Go to the next row and move back to the left edge
	;
		clr	cx
		add	dx, COLOR_256_CELL_HEIGHT
	;
	; To the last row?
	;
endOfRow::
		cmp	dx, ss:objHeight
		jb	drawLoop
;;;
	;
	; draw the 16 standard colors and 16 greys
	;
;;;
	;
	; Show the current color by inverting a rectangle around it
	;
		tst	ss:isIndex			;index color?
		jz	afterCurColor			;branch if not index
		mov	al, MM_INVERT			;al <- MixMode
		call	GrSetMixMode
		mov	al, ss:curColor			;al <- current Color
		call	ColorToPos
		jc	afterCurColor			;branch if not index
		add	ax, ss:leftEdge
		mov	cx, ax
		add	cx, COLOR_256_CELL_WIDTH-1	;cx <- right
		add	bx, ss:topEdge
		mov	dx, bx
		add	dx, COLOR_256_CELL_HEIGHT-1	;dx <- bottom
		call	GrDrawRect
afterCurColor:

		call	GrRestoreState
		.leave
		ret
Color256SelectorDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorToPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a color to the corresponding (x,y) position

CALLED BY:	Color256SelectorDraw()

PASS:		al - Color index
		di - GState
RETURN:		(ax,bx) - (x,y) position
		carry - set if Color not in table
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/1/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ColorToPos	proc	near
		uses	cx, dx, si

curRed		local	byte
curGreenBlue	local	word


		.enter
	;
	; Get our current color as an RGB value
	;
		mov	ah, al				;ah <- Color
		call	GrMapColorIndex
		mov	ss:curRed, al
		mov	ss:curGreenBlue, bx
	;
	; Find the index of our Color entry
	;
		clr	si
		mov	cx, length colorIndexTable	;cx <- length
colorLoop:
	;
	; Get the RGB value of the entry and see if we match
	;
		mov	ah, cs:colorIndexTable[si]	;ah <- Color
		cmp	ah, C_UNUSED_0
		je	nextColor			;branch if not used
		call	GrMapColorIndex
		cmp	ss:curRed, al
		jne	nextColor
		cmp	ss:curGreenBlue, bx
		je	gotColor
nextColor:
		add	si, (size Color)
		loop	colorLoop
		stc					;carry <- not found
		jmp	done

	;
	; Get the row # and remainder (col #)
	;
gotColor:
		mov	ax, si				;ax <- index
		clr	dx
		mov	cx, COLOR_256_NUM_COLS
		div	cx				;ax <- row #
		mov	bx, dx				;bx <- col #
	;
	; Convert the row # and col # to (x,y)
	;
		mov	cx, COLOR_256_CELL_HEIGHT
		mul	cx				;ax <- y pos
		push	ax
		mov	cx, COLOR_256_CELL_WIDTH
		mov	ax, bx
		mul	cx
		mov	bx, ax				;bx <- x pos
		pop	ax
		xchg	ax, bx				;(ax,bx) <- (x,y)
		clc					;carry <- found
done:

		.leave
		ret
ColorToPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PosToColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an (x,y) position to the corresponding color

CALLED BY:	Color256SelectorDraw()

PASS:		(ax,bx) - (x,y) position
RETURN:		al - Color index
		ah - CF_INDEX
DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/1/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PosToColor	proc	near
		uses	cx, dx, di
column		local	word
		.enter

	;
	; Calculate the (r,c)
	;
		mov	cx, COLOR_256_CELL_WIDTH
		clr	dx
		div	cx				;ax <- column #
		mov	ss:column, ax
		mov	ax, bx				;ax <- y pos
		clr	dx
		mov	cx, COLOR_256_CELL_HEIGHT
		div	cx				;ax <- row #
	;
	; Convert the (r,c) to an index
	;
		mov	bx, COLOR_256_NUM_COLS
		mul	bx				;ax <- row * # cols
		add	ax, ss:column
		mov	di, ax				;di <- index
	;
	; Look up the color
	;
		mov	ah, CF_INDEX
		mov	al, cs:colorIndexTable[di]

		.leave
		ret
PosToColor	endp
colorIndexTable	Color \
    C_R0_G0_B0, C_R0_G0_B1, C_R0_G0_B2, C_R0_G0_B3, C_R0_G0_B4, C_R0_G0_B5,
    C_R1_G0_B0, C_R1_G0_B1, C_R1_G0_B2, C_R1_G0_B3, C_R1_G0_B4, C_R1_G0_B5,
    C_R2_G0_B0, C_R2_G0_B1, C_R2_G0_B2, C_R2_G0_B3, C_R2_G0_B4, C_R2_G0_B5,
    C_R0_G1_B0, C_R0_G1_B1, C_R0_G1_B2, C_R0_G1_B3, C_R0_G1_B4, C_R0_G1_B5,
    C_R1_G1_B0, C_R1_G1_B1, C_R1_G1_B2, C_R1_G1_B3, C_R1_G1_B4, C_R1_G1_B5,
    C_R2_G1_B0, C_R2_G1_B1, C_R2_G1_B2, C_R2_G1_B3, C_R2_G1_B4, C_R2_G1_B5,
\
    C_R0_G2_B0, C_R0_G2_B1, C_R0_G2_B2, C_R0_G2_B3, C_R0_G2_B4, C_R0_G2_B5,
    C_R1_G2_B0, C_R1_G2_B1, C_R1_G2_B2, C_R1_G2_B3, C_R1_G2_B4, C_R1_G2_B5,
    C_R2_G2_B0, C_R2_G2_B1, C_R2_G2_B2, C_R2_G2_B3, C_R2_G2_B4, C_R2_G2_B5,
    C_R0_G3_B0, C_R0_G3_B1, C_R0_G3_B2, C_R0_G3_B3, C_R0_G3_B4, C_R0_G3_B5,
    C_R1_G3_B0, C_R1_G3_B1, C_R1_G3_B2, C_R1_G3_B3, C_R1_G3_B4, C_R1_G3_B5,
    C_R2_G3_B0, C_R2_G3_B1, C_R2_G3_B2, C_R2_G3_B3, C_R2_G3_B4, C_R2_G3_B5,
\
    C_R0_G4_B0, C_R0_G4_B1, C_R0_G4_B2, C_R0_G4_B3, C_R0_G4_B4, C_R0_G4_B5,
    C_R1_G4_B0, C_R1_G4_B1, C_R1_G4_B2, C_R1_G4_B3, C_R1_G4_B4, C_R1_G4_B5,
    C_R2_G4_B0, C_R2_G4_B1, C_R2_G4_B2, C_R2_G4_B3, C_R2_G4_B4, C_R2_G4_B5,
    C_R0_G5_B0, C_R0_G5_B1, C_R0_G5_B2, C_R0_G5_B3, C_R0_G5_B4, C_R0_G5_B5,
    C_R1_G5_B0, C_R1_G5_B1, C_R1_G5_B2, C_R1_G5_B3, C_R1_G5_B4, C_R1_G5_B5,
    C_R2_G5_B0, C_R2_G5_B1, C_R2_G5_B2, C_R2_G5_B3, C_R2_G5_B4, C_R2_G5_B5,
\
    C_R3_G0_B0, C_R3_G0_B1, C_R3_G0_B2, C_R3_G0_B3, C_R3_G0_B4, C_R3_G0_B5,
    C_R4_G0_B0, C_R4_G0_B1, C_R4_G0_B2, C_R4_G0_B3, C_R4_G0_B4, C_R4_G0_B5,
    C_R5_G0_B0, C_R5_G0_B1, C_R5_G0_B2, C_R5_G0_B3, C_R5_G0_B4, C_R5_G0_B5,
    C_R3_G1_B0, C_R3_G1_B1, C_R3_G1_B2, C_R3_G1_B3, C_R3_G1_B4, C_R3_G1_B5,
    C_R4_G1_B0, C_R4_G1_B1, C_R4_G1_B2, C_R4_G1_B3, C_R4_G1_B4, C_R4_G1_B5,
    C_R5_G1_B0, C_R5_G1_B1, C_R5_G1_B2, C_R5_G1_B3, C_R5_G1_B4, C_R5_G1_B5,
\
    C_R3_G2_B0, C_R3_G2_B1, C_R3_G2_B2, C_R3_G2_B3, C_R3_G2_B4, C_R3_G2_B5,
    C_R4_G2_B0, C_R4_G2_B1, C_R4_G2_B2, C_R4_G2_B3, C_R4_G2_B4, C_R4_G2_B5,
    C_R5_G2_B0, C_R5_G2_B1, C_R5_G2_B2, C_R5_G2_B3, C_R5_G2_B4, C_R5_G2_B5,
    C_R3_G3_B0, C_R3_G3_B1, C_R3_G3_B2, C_R3_G3_B3, C_R3_G3_B4, C_R3_G3_B5,
    C_R4_G3_B0, C_R4_G3_B1, C_R4_G3_B2, C_R4_G3_B3, C_R4_G3_B4, C_R4_G3_B5,
    C_R5_G3_B0, C_R5_G3_B1, C_R5_G3_B2, C_R5_G3_B3, C_R5_G3_B4, C_R5_G3_B5,
\
    C_R3_G4_B0, C_R3_G4_B1, C_R3_G4_B2, C_R3_G4_B3, C_R3_G4_B4, C_R3_G4_B5,
    C_R4_G4_B0, C_R4_G4_B1, C_R4_G4_B2, C_R4_G4_B3, C_R4_G4_B4, C_R4_G4_B5,
    C_R5_G4_B0, C_R5_G4_B1, C_R5_G4_B2, C_R5_G4_B3, C_R5_G4_B4, C_R5_G4_B5,
    C_R3_G5_B0, C_R3_G5_B1, C_R3_G5_B2, C_R3_G5_B3, C_R3_G5_B4, C_R3_G5_B5,
    C_R4_G5_B0, C_R4_G5_B1, C_R4_G5_B2, C_R4_G5_B3, C_R4_G5_B4, C_R4_G5_B5,
    C_R5_G5_B0, C_R5_G5_B1, C_R5_G5_B2, C_R5_G5_B3, C_R5_G5_B4, 0xff,
\
    C_UNUSED_0, C_GRAY_0, C_GRAY_7, C_GRAY_13, C_GRAY_20, C_GRAY_27,
    C_GRAY_33,  C_GRAY_40, C_GRAY_47, C_GRAY_53, C_GRAY_60, C_GRAY_68,
    C_GRAY_73,  C_GRAY_80, C_GRAY_88, C_GRAY_93, C_GRAY_100, C_UNUSED_0

CheckHack <length colorIndexTable eq 234>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Color256SelectorStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a mouse press

CALLED BY:	MSG_META_START_SELECT

PASS:		(cx,dx) - (x,y)
		bp.low = ButtonInfo
		bp.high = ShiftState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/1/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

Color256SelectorStartSelect	method dynamic	Color256SelectorClass,
						MSG_META_START_SELECT,
						MSG_META_PTR
		call	VisGrabMouse
		test	bp, mask BI_B0_DOWN
		jz	done
	;
	; Convert the mouse position to relative (x,y)
	;
		push	cx, dx
		call	VisGetBounds
		pop	cx, dx
		sub	cx, ax
		sub	dx, bx
	;
	; Convert the position to a color
	;
		mov	ax, cx
		mov	bx, dx				;(ax,bx) <- (x,y)
		call	PosToColor
		cmp	al, C_UNUSED_0
		je	done				;branch if unused

		clr	ah
		mov	cx, ax				;cx <- Color index
		mov	bp, 1				;bp <- # selections
		mov	ax, MSG_CS_SET_CF_INDEX
		call	CallController
done:
		call	VisReleaseMouse
		mov	ax, mask MRF_PROCESSED
		ret
Color256SelectorStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Color256SelectorRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalc the size of our 256 color selector

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

Color256SelectorRecalcSize	method dynamic	Color256SelectorClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, COLOR_256_SELECTOR_WIDTH
		mov	dx, COLOR_256_SELECTOR_HEIGHT
		ret
Color256SelectorRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorSampleDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw our color sample

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - GState
RETURN:		carry - set if the state has changed
DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ColorSampleDraw	method dynamic	ColorSampleClass,
					MSG_VIS_DRAW
		mov	di, bp				;di <- GState
	;
	; Get the current color
	;
		call	GetCurrentColor
	;
	; Set it in the GState
	;
		call	GrSetAreaColor
	;
	; Draw a rectangle to our bounds
	;
		call	VisGetBounds
		call	GrFillRect
	;
	; Draw a box using the 'dark color' and white to effect a drop shadow
	;
		push	ax, bx, cx, dx, bp
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		call	UserCallApplication
		clr	ax			;ah <- CF_INDEX
		mov	al, ch			;al <- dark color
CheckHack <CF_INDEX eq 0>
		call	GrSetLineColor
		pop	ax, bx, cx, dx, bp

		call	GrDrawVLine
		call	GrDrawHLine
		push	ax
		mov	ax, C_WHITE or (CF_INDEX shl 8)
		call	GrSetLineColor
		pop	ax
		xchg	ax, cx
		call	GrDrawVLine
		xchg	ax, cx
		xchg	bx, dx
		call	GrDrawHLine
		ret
ColorSampleDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorSampleRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalc the size of our color sample

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ColorSampleRecalcSize	method dynamic	ColorSampleClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, ds:[di].CSI_width
		mov	dx, ds:[di].CSI_height
		ret
ColorSampleRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorSelectorSetSelectorType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the type of our selector

CALLED BY:	MSG_CS_SET_SELECTOR_TYPE

PASS:		cx - ColorSelectorType
RETURN:		
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/31/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

selectorGroups	lptr \
	Other256List,
	OtherRGBGroup

ColorSelectorSetSelectorType	method dynamic	ColorSelectorClass,
					MSG_CS_SET_SELECTOR_TYPE
		mov	dx, cx			;dx <- ColorSelectorType
		call	GetChildBlockAndFeatures
		mov	cx, length selectorGroups
		clr	di
groupLoop:
	;
	; See if this is the new current group or not, and set it
	; usable or not usable accordingly.
	;
		mov	si, cs:selectorGroups[di]
		push	ax, cx, dx
		cmp	di, dx
		mov	ax, MSG_GEN_SET_NOT_USABLE
		jne	gotMessage
CheckHack < MSG_GEN_SET_USABLE eq MSG_GEN_SET_NOT_USABLE-1 >
		dec	ax
gotMessage:
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE	;dl <- VisUpdateMode
		call	CallObjMessage
		pop	ax, cx, dx
	;
	; Loop through the rest of the feature groups
	;
		add	di, (size lptr)
		loop	groupLoop
		ret
ColorSelectorSetSelectorType	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorBarDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a color bar

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - GState
RETURN:		carry - set if the state has changed
DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ColorBarDraw	method dynamic	ColorBarClass,
					MSG_VIS_DRAW

gstate		local	hptr.GState	push	bp
curBlue		local	BBFixed
curGreen	local	BBFixed
curRed		local	BBFixed
colorStep	local	BBFixed
left		local	word
top		local	word
bottom		local	word
whichColor	local	ColorBarColor

CheckHack <offset curGreen eq offset curRed+CBC_GREEN>
CheckHack <offset curBlue eq offset curRed+CBC_BLUE>

		.enter
	;
	; Save some initial values
	;
		mov	ax, ds:[di].CBI_color
		mov	ss:whichColor, ax
		clr	ax
		mov	{word}ss:curRed, ax
		mov	{word}ss:curGreen, ax
		mov	{word}ss:curBlue, ax

		call	VisGetBounds
		mov	ss:left, ax
		mov	ss:top, bx
		mov	ss:bottom, dx

		mov	bx, COLOR_BAR_DEFAULT_WIDTH
	;
	; Figure out our step size = 256/width
	;
		mov	dx, 256				;dx:cx <- 256
		clr	ax, cx				;bx:ax <- width
		call	GrUDivWWFixed
		mov	ss:colorStep.BBF_int, dl
		mov	ss:colorStep.BBF_frac, ch
	;
	; Get the starting color
	;
		mov	di, ss:gstate			;di <- GState
		call	GetCurrentColorRGB
		mov	ss:curRed.BBF_int, al
		mov	ss:curGreen.BBF_int, bl
		mov	ss:curBlue.BBF_int, bh
	;
	; Zero the color we're showing
	;
		mov	si, ss:whichColor
		mov	{word}ss:curRed[si], 0
colorLoop:
	;
	; Draw a rectangle in the current color
	;
		mov	ah, CF_RGB
		mov	al, ss:curRed.BBF_int
		mov	bl, ss:curGreen.BBF_int
		mov	bh, ss:curBlue.BBF_int
		call	GrSetAreaColor

		mov	ax, ss:left
		add	al, ss:curRed[si].BBF_int
		adc	ah, 0
		clr	cx
		mov	cl, ss:colorStep.BBF_int
		add	cx, ax
		mov	bx, ss:top
		mov	dx, ss:bottom
		call	GrFillRect
	;
	; Advance the color we're showing
	;
		mov	ax, {word}ss:colorStep
		add	{word}ss:curRed[si], ax
	;
	; To the end?
	;
		cmp	ss:curRed[si].BBF_int, 255
		jb	colorLoop

		.leave
		ret
ColorBarDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorSampleRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalc the size of our color sample

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ColorBarRecalcSize	method dynamic	ColorBarClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, COLOR_BAR_DEFAULT_WIDTH
		mov	dx, COLOR_BAR_DEFAULT_HEIGHT
		ret
ColorBarRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomColorReadSavedColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the saved colors from the .INI file

CALLED BY:	MSG_CUSTOM_COLOR_READ_SAVED_COLORS

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

colorCat	char "color", 0
colorKey	char "custom", 0

CustomColorReadSavedColors	method dynamic	CustomColorClass,
					MSG_CUSTOM_COLOR_READ_SAVED_COLORS
	;
	; Init the colors to zero
	;
		lea	di, ds:[di].CCI_colors
		segmov	es, ds				;es:di <- buffer
		mov	cx, (size SavedColors)
		clr	ax
		push	di
		rep	stosb
		pop	di
	;
	; Read the colors, if any, from the .INI file
	;
		push	ds, si
		mov	bp, (size SavedColors)		;bp <- size
		segmov	ds, cs, cx
		mov	si, offset colorCat		;ds:si <- category
		mov	dx, offset colorKey		;cx:dx <- key
		call	InitFileReadData
		pop	ds, si
	;
	; Create/update monikers for our list
	;
		clr	cx
monikerLoop:
		call	UpdateCustomMoniker
		inc	cx
		cmp	cx, COLOR_CUSTOM_NUM_COLORS
		jb	monikerLoop
		ret
CustomColorReadSavedColors	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomColorWriteSavedColors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the saved colors to the .INI file

CALLED BY:	MSG_CUSTOM_COLOR_WRITE_SAVED_COLORS

PASS:		none
RETURN:		none
DESTROYED:	si, di, ds, es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

CustomColorWriteSavedColors	method dynamic	CustomColorClass,
					MSG_CUSTOM_COLOR_WRITE_SAVED_COLORS
		uses	cx, dx, bp
		.enter
	;
	; Write the colors to the .INI file
	;
		lea	di, ds:[di].CCI_colors
		segmov	es, ds				;es:di <- buffer
		mov	bp, (size SavedColors)		;bp <- size
		segmov	ds, cs, cx
		mov	si, offset colorCat		;ds:si <- category
		mov	dx, offset colorKey		;cx:dx <- key
		call	InitFileWriteData
		.leave
		ret
CustomColorWriteSavedColors	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSavedColorOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset of the specifid saved color

CALLED BY:	UTILITY

PASS:		*ds:si - CustomColor object
		cx - list #
RETURN:		carry - set if none selected
		ds:di - ptr to CustomColor instance
		bx - offset into SavedColor (index*3)
		cx - offset for chunk (index*2)
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

GetSavedColorOffset	proc	near
		cmp	cx, GIGS_NONE			;none selected?
		stc					;carry <- none
		je	done				;branch if none
	;
	; Convert number to an offset
	;
		mov	di, cx				;di <- #
		shl	cx, 1				;cx <- #*2
		add	di, cx				;di <- #*3
CheckHack <(size RGBValue) eq 3>
		mov	bx, di				;bx <- offset
	;
	; Get a pointer to our instance data
	;
		mov	di, ds:[si]
		add	di, ds:[di].CustomColor_offset
done:
		ret
GetSavedColorOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomColorAddColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add/update the current color as a custom color

CALLED BY:	MSG_CUSTOM_COLOR_ADD_COLOR

PASS:		cx - color # / list selection
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

CustomColorAddColor	method dynamic	CustomColorClass,
					MSG_CUSTOM_COLOR_ADD_COLOR
	;
	; Get the current color
	;
		clr	di				;di <- no GState
		call	GetCurrentColorRGB		;al,bl,bh <- RGB
		mov	dx, bx				;dx <- GB
	;
	; Get the offset for the color and save it
	;
		push	cx
		call	GetSavedColorOffset
		pop	cx
		jc	done				;branch if no selection
		mov	({RGBValue} ds:[di].CCI_colors[bx]).RGB_red, al
		mov	({RGBValue} ds:[di].CCI_colors[bx]).RGB_green, dl
		mov	({RGBValue} ds:[di].CCI_colors[bx]).RGB_blue, dh
	;
	; Write the new values out to the .INI file
	;
		mov	ax, MSG_CUSTOM_COLOR_WRITE_SAVED_COLORS
		call	ObjCallInstanceNoLock
	;
	; Update the moniker for our list
	;
		call	UpdateCustomMoniker
done:
		ret
CustomColorAddColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorSelectorAddCustomColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add/update a color in our custom color list

CALLED BY:	MSG_CS_ADD_CUSTOM_COLOR

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ColorSelectorAddCustomColor	method dynamic ColorSelectorClass,
						MSG_CS_ADD_CUSTOM_COLOR
	;
	; Get the current list selection
	;
		call	GetChildBlockAndFeatures
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	si, offset OtherCustomColorList
		call	CallObjMessage
		jc	done				;branch if no selection
	;
	; Pass it to the CustomColor object to do the work
	;
		mov	cx, ax				;cx <- selection
		mov	si, offset OtherCustomGroup
		mov	ax, MSG_CUSTOM_COLOR_ADD_COLOR
		call	CallObjMessage
done:
		ret
ColorSelectorAddCustomColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CustomColorUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An item in the custom color list was selected

CALLED BY:	MSG_CUSTOM_COLOR_UPDATE

PASS:		cx - color # / list selection
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/29/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

CustomColorUpdate	method dynamic	CustomColorClass,
					MSG_CUSTOM_COLOR_UPDATE
	;
	; Get the offset of our color and get it
	;
		call	GetSavedColorOffset
		jc	done
		mov	cl, ({RGBValue} ds:[di].CCI_colors[bx]).RGB_red
		mov	dl, ({RGBValue} ds:[di].CCI_colors[bx]).RGB_green
		mov	dh, ({RGBValue} ds:[di].CCI_colors[bx]).RGB_blue
		mov	ch, CF_RGB			;dx:cx <- ColorQuad
	;
	; Set the color in the controller
	;
		clr	bp				;bp <- not indtrmnt.
		mov	ax, MSG_CS_SET_COLOR_RGB
		call	CallController
done:
		ret
CustomColorUpdate	endm

ColorSelectorSetColorRGB	method dynamic	ColorSelectorClass,
					MSG_CS_SET_COLOR_RGB
		mov	ax, MSG_COLOR_SELECTOR_UPDATE_COLOR
		call	ObjCallInstanceNoLock
		call	MarkColorChangedAndSetApplyable
		ret
ColorSelectorSetColorRGB	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorSelectorCustomColorSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A custom color has been selected

CALLED BY:	MSG_CS_CUSTOM_COLOR_SELECT

PASS:		cx - color # / list entry
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

ColorSelectorCustomColorSelect	method dynamic ColorSelectorClass,
						MSG_CS_CUSTOM_COLOR_SELECT
		call	GetChildBlockAndFeatures
		test	ax, mask CSF_OTHER
		jz	done
	;
	; If there is no selection, disable the Add button
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	cx, GIGS_NONE
		je	doEnableDisable
	;
	; Update the custom color object if it is there
	;
		mov	ax, MSG_CUSTOM_COLOR_UPDATE
		mov	si, offset OtherCustomGroup
		call	CallObjMessage
	;
	; Set the Add button enabled
	;
		mov	ax, MSG_GEN_SET_ENABLED
doEnableDisable:
		mov	dl, VUM_NOW
		mov	si, offset OtherCustomColorAdd
		call	CallObjMessage
done:
		ret
ColorSelectorCustomColorSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateCustomMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and update the moniker for a custom color

CALLED BY:	UTILITY

PASS:		*ds:si - CustomColor object
		cx - color # / list entry
RETURN:		ds - fixed up
DESTROYED:	ax, bx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/4/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

customListChunks	lptr \
	CustomColor0,
	CustomColor1,
	CustomColor2,
	CustomColor3,
	CustomColor4,
	CustomColor5,
	CustomColor6,
	CustomColor7,
	CustomColor8,
	CustomColor9,
	CustomColor10,
	CustomColor11,
	CustomColor12,
	CustomColor13,
	CustomColor14,
	CustomColor15

UpdateCustomMoniker	proc	near
		class	CustomColorClass
		uses	cx, si
objBlockHan	local	hptr
		.enter
		mov	ax, ds:LMBH_handle		;ax <- obj block han
		mov	ss:objBlockHan, ax
	;
	; Get the current color
	;
		push	ax
		call	GetSavedColorOffset
		mov	al, ({RGBValue} ds:[di].CCI_colors[bx]).RGB_red
		mov	dl, ({RGBValue} ds:[di].CCI_colors[bx]).RGB_green
		mov	dh, ({RGBValue} ds:[di].CCI_colors[bx]).RGB_blue
		pop	bx
	;
	; Create a graphics string with a rectangle in the current color
	;
		push	cx
		push	dx
		mov	cl, GST_CHUNK			;cl <- GStringType
		call	GrCreateGString
		pop	bx				;bl,bh <- GB
		mov	ah, CF_RGB			;ah <- ColorFlag
		call	GrSetAreaColor
		clr	ax, bx
		mov	cx, CUSTOM_COLOR_WIDTH
		mov	dx, CUSTOM_COLOR_HEIGHT		;(ax,bx,cx,dx) <- rect
		call	GrFillRect
		call	GrEndGString
		pop	cx				;cx <- chunk offset
	;
	; Destroy the GString but leave the data
	;
		push	si
		mov	si, di				;si <- GString
		clr	di				;di <- no GState
		mov	dl, GSKT_LEAVE_DATA		;dl <- GStringKillType
		call	GrDestroyGString
		pop	si
	;
	; Re-dereference the object block into ds.  The above gstring
	; creation in the same block may have caused the block to move.
	;
		mov	bx, ss:objBlockHan
		call	MemDerefDS
	;
	; Create a moniker for our list entry
	;
		push	di, bp
		sub	sp, (size ReplaceVisMonikerFrame)
		mov	bp, sp
		mov	ss:[bp].RVMF_source.handle, bx
		mov	ss:[bp].RVMF_source.chunk, si
		mov	ss:[bp].RVMF_sourceType, VMST_OPTR
		mov	ss:[bp].RVMF_dataType, VMDT_GSTRING
		mov	ss:[bp].RVMF_length, 0
		mov	ss:[bp].RVMF_width, 0
		mov	ss:[bp].RVMF_height, 0
		mov	ss:[bp].RVMF_updateMode, VUM_NOW
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
		mov	di, cx				;di <- chunk offset
		mov	si, cs:customListChunks[di]
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		add	sp, (size ReplaceVisMonikerFrame)
		pop	di, bp
		.leave
		ret
UpdateCustomMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorValueStatusMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update value of linked GenValue

CALLED BY:	MSG_COLOR_VALUE_STATUS_MSG

PASS:		*ds:si	= ColorValueClass object
		ds:di	= ColorValueClass instance data
		ds:bx	= ColorValueClass object (same as *ds:si)
		es 	= segment of ColorValueClass
		ax	= message #
		dx.cx	= signed <integer>.<fraction> value to set
		bp	= GenValueStateFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/31/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorValueStatusMsg	method dynamic ColorValueClass, 
					MSG_COLOR_VALUE_STATUS_MSG
	test	bp, mask GVSF_INDETERMINATE
	jnz	setValue
	clr	bp			; not indeterminate

setValue:
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	GOTO	ObjCallInstanceNoLock

ColorValueStatusMsg	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorValueSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Always send out status message when value changed

CALLED BY:	MSG_GEN_VALUE_SET_VALUE
		MSG_GEN_VALUE_SET_INTEGER_VALUE

PASS:		*ds:si	= ColorValueClass object
		ds:di	= ColorValueClass instance data
		ds:bx	= ColorValueClass object (same as *ds:si)
		es 	= segment of ColorValueClass
		ax	= message #
		dx.cx	= signed <integer>.<fraction> value to set (SET_VALUE)
		cx	= signed integer value to set (SET_INTEGER_VALUE)
		bp	= non-zero if indeterminate
RETURN:		carry set if GVLI_value changed
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	1/31/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorValueSetValue	method dynamic ColorValueClass, 
					MSG_GEN_VALUE_SET_VALUE,
					MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	di, offset ColorValueClass
	call	ObjCallSuperNoLock
	jnc	done

	mov	ax, MSG_GEN_VALUE_SEND_STATUS_MSG
	mov	cx, TRUE		; modified
	GOTO	ObjCallInstanceNoLock
done:
	ret
ColorValueSetValue	endm

ColorSelectorCode ends
