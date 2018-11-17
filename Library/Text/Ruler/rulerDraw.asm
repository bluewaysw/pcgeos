COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text
FILE:		rulerDraw.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/92		Initial version

DESCRIPTION:
	This file contains code to implement the drawing for TextRulerClass

	$Id: rulerDraw.asm,v 1.1 97/04/07 11:19:49 newdeal Exp $

------------------------------------------------------------------------------@

TEXT_RULER_TOP_ARROW_X	=	7
TEXT_RULER_TOP_ARROW_Y	=	3

;---

RulerCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerDraw -- MSG_VIS_DRAW for TextRulerClass

DESCRIPTION:	Draw the ruler

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass

	ax - The message

	cl - draw flags
	bp - gstate

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 6/92		Initial version

------------------------------------------------------------------------------@
TextRulerDraw	method dynamic	TextRulerClass, MSG_VIS_DRAW

	; if the ruler is not valid then do not draw it

	tst	ds:[di].TRI_valid
	pushf

	; Draw the upper part of the ruler...

	push	bp
	mov	di, offset TextRulerClass
	call	ObjCallSuperNoLock
	pop	di				;di = gstate

	popf
	jz	done
	call	DrawMarginsAndTabs
done:
	ret

TextRulerDraw	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawMarginsAndTabs

DESCRIPTION:	Draw the tick marks on the ruler

CALLED BY:	INTERNAL

PASS:
	*ds:si - text ruler
	di - gstate

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
DrawMarginsAndTabs	proc	near
	class	TextRulerClass

	mov	ax, C_BLACK
	call	GrSetLineColor
	call	GrSetAreaColor

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset
	tst	ds:[bx].TRI_valid
	LONG jz	done

	; draw pattern if multiple rulers

	test	ds:[bx].TRI_diffs.VTPAD_diffs,
					mask VTPAF_MULTIPLE_LEFT_MARGINS or \
					mask VTPAF_MULTIPLE_RIGHT_MARGINS or \
					mask VTPAF_MULTIPLE_PARA_MARGINS or \
					mask VTPAF_MULTIPLE_TAB_LISTS or \
					mask VTPAF_MULTIPLE_DEFAULT_TABS
	jz	notMultipleRulers

	mov	ax, SDM_12_5
	call	GrSetAreaMask
	mov	ax, C_RED
	call	GrSetAreaColor

	push	bx
	call	GrGetWinBounds
	mov	bx, VIS_RULER_HEIGHT + 1
	call	GrFillRect
	pop	bx

	mov	ax, SDM_100
	call	GrSetAreaMask

	mov	ax, C_BLACK
	call	GrSetAreaColor
notMultipleRulers:

	; get scale and pointer to ruler

	push	ds:[bx].TRI_selectedTab	;save selected tab for later
	add	bx, offset TRI_paraAttr		;ds:bx = para attr

	; draw the margins

	mov	bp, -1				;do not draw selected
	mov	ax, ds:[bx].VTPA_leftMargin
	mov	dx, TMBO_LEFT_MARGIN
	call	DrawMarginOrTab

	mov	ax, ds:[bx].VTPA_paraMargin
	mov	dx, TMBO_PARA_MARGIN
	call	DrawMarginOrTab

	mov	ax, ds:[bx].VTPA_rightMargin
	mov	dx, TMBO_RIGHT_MARGIN
	call	DrawMarginOrTab

	; draw the tabs

	pop	bp				;bp = selected tab
	push	bx				;save pointer to ruler
	push	ax				;save right margin
	clr	ax				;ax holds position of last tab
	clr	cx
	mov	cl, ds:[bx].VTPA_numberOfTabs
	jcxz	afterTab
	add	bx, size VisTextParaAttr	;ds:bx = first tab

tabLoop:

	; get correct bitmap

	clr	dx
	push	ax				;save last tab position
	mov	dl, ds:[bx].T_attr
	and	dl, mask TA_TYPE or mask TA_LEADER	;get type bits
	    CheckHack <(offset TBTI_TYPE eq 2) and (offset TBTI_LEADER eq 4)>
	shl	dx
	shl	dx

	; set bits for line and leader

	tst	ds:[bx].T_lineWidth
	jz	noLine
	or	dl, mask TBTI_LINE
noLine:

	add	dx, TMBO_TABS
	mov	ax, ds:[bx].T_position
	call	DrawMarginOrTab

	pop	dx				;recover last tab position
	pop	ax
	push	ax				;ax = right margin
	cmp	ax, ds:[bx].T_position		;is right margin < tab ?
	jge	thisTabIsAfterRightMargin
	mov	ax, dx
	jmp	common
thisTabIsAfterRightMargin:
	mov	ax, ds:[bx].T_position
common:

	add	bx, size Tab
	loop	tabLoop

afterTab:
	pop	bx				;discard right margin
	pop	bx				;ds:bx = ruler

	; check for default tabs -- ax = last tab

	mov	cx, ds:[bx].VTPA_leftMargin	;get lesser of left and para
	cmp	ax, cx
	jae	20$
	mov_tr	ax, cx
20$:

	mov	bp, ds:[bx].VTPA_defaultTabs
	mov	bx, ds:[bx].VTPA_rightMargin

	; calculate first default tab position
	;	bp = default tab step, ax = last real tab
	;	bx = right margin

	tst	bp
	jz	afterDefaultTabs
	clr	dx
30$:
	add	dx, bp
	cmp	dx, ax
	jbe	30$

	mov_tr	ax, dx				;ax = first deefault tab

defaultTabLoop:
	cmp	ax, bx
	jae	afterDefaultTabs
	push	ax, bp

	mov	bp, -1				;do not draw selected
	mov	dx, TMBO_DEFAULT_TAB
	call	DrawMarginOrTab

	pop	ax, bp
	add	ax, bp
	jmp	defaultTabLoop
afterDefaultTabs:

done:
	.leave
	ret

DrawMarginsAndTabs	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawMarginOrTab

DESCRIPTION:	Draw a margin or a tab

CALLED BY:	INTERNAL

PASS:
	*ds:si - text ruler
	ax - x position to draw
	dx - offset into TabMarginBitmaps to get the address of the bitmap
	di - gstate
	bp - position of selected marker.  if (ax == bp) then draw this marker
		as selected

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

DrawMarginOrTab	proc	near	uses	ax, bx, cx, si, bp, ds
	.enter

	; set bp to be "selected flag"

	cmp	ax, bp
	mov	bp, 0				;assume not selected
	jnz	notSelectedTab
	dec	bp
notSelectedTab:

	; calculate real position

	call	RulerCoordToObjectCoord

	; get pointer to the bitmap

	mov	bx, handle TabMarginBitmaps
	push	bx
	push	ax
	call	MemLock
EC <	ERROR_C	MEM_LOCK_RETURNED_ERROR_CALL_TONY			>
	mov	ds, ax
	pop	ax

	mov	si, offset TabMarginBitmaps
	mov	si, ds:[si]
	mov	bx, si
	add	bx, dx				;ds:si = ptr to bitmap data
	add	si, ds:[bx]			;ds:si = data

	; first byte is offset to the middle of the bitmap -- add it in

	clr	bx
	mov	bl, ds:[si]
	sub	ax, bx
	inc	si

	; draw it

	mov	bx, VIS_RULER_HEIGHT + 1
	call	GrFillBitmap

	; draw selection if needed

	tst	bp
	jz	notSelection
	add	bx, TEXT_RULER_TOP_ARROW_Y
	sub	ax, TEXT_RULER_TOP_ARROW_X
	call	DrawArrow
notSelection:

	pop	bx
	call	MemUnlock

	.leave
	ret

DrawMarginOrTab	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RedrawMarginsAndTabs

DESCRIPTION:	Redraw the margins and tabs

CALLED BY:	INTERNAL

PASS:
	*ds:si - ruler top object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
RedrawMarginsAndTabs	proc	near
	class	TextRulerClass

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_REALIZED
	jz	done

	call	GetRulerGState
	mov	bx, VIS_RULER_HEIGHT + 1
	call	GrFillRect
	call	DrawMarginsAndTabs
	call	GrDestroyState
done:
	ret

RedrawMarginsAndTabs	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetRulerGState

DESCRIPTION:	Get a gstate

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

RETURN:
	ax, bx, cx, dx - bounds
	di, bp - gstate (with background color set as area color)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
GetRulerGState	proc	near
	class	TextRulerClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VRI_window
	push	si
	mov	si, WIT_COLOR
	call	WinGetInfo			;bxax = color
	pop	si
	pushdw	bxax

	; get a gstate and get the color scheme

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp

	popdw	bxax
	call	GrSetAreaColor

	call	GrGetWinBounds

	mov	bp, di

	.leave
	ret

GetRulerGState	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawArrow

DESCRIPTION:	Draw an arrow

CALLED BY:	INTERNAL

PASS:
	ax, bx - position

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
DrawArrow	proc	near		uses si, ds
	.enter

	push	ax, bx
	mov	bx, handle ArrowBitmap
	call	MemLock
	mov	ds, ax
	pop	ax, bx

	; draw the sucker

	mov	si, offset ArrowBitmap
	mov	si, ds:[si]			;ds:si = bitmap
	call	GrFillBitmap

	mov	bx, handle ArrowBitmap
	call	MemUnlock

	.leave
	ret

DrawArrow	endp

RulerCommon ends
