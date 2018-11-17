COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlTabLine.asm

AUTHOR:		John Wedgwood, Feb 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 2/26/92	Initial revision

DESCRIPTION:
	Misc border related stuff.

	$Id: tlTabLine.asm,v 1.1 97/04/07 11:21:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTabLinesAfterPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw tab lines for all tabs after a given position.

CALLED BY:	TextClearBehindLine
PASS:		*ds:si	= Instance
		bx	= position after which to draw tab lines.
		ss:bp	= LICL_vars structure on stack.
RETURN:		nothing
DESTROYED:
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	7/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTabLinesAfterPos	proc	near
	class	VisTextClass
	uses	cx, dx, di, si
	.enter
	call	TextDraw_DerefVis_DI		; ds:di <- instance
	mov	dx, di				; ds:dx <- instance
	mov	di, ds:[di].VTI_gstate		; di <- gstate

	clr	cx
	mov	cl, LICL_paraAttr.VTPA_numberOfTabs
	jcxz	noTabs
	mov	si,offset LICL_theParaAttr.VTMPA_tabs ; ss:[bp][si] = tab
tabLoop:
	tst	ss:[bp][si].T_lineWidth
	jz	nextTab
	cmp	ss:[bp][si].T_position, bx	; Check for past field end.
	jb	nextTab				; Skip if before field end.
	call	TextDrawTabLine
nextTab:
	add	si, size Tab
	loop	tabLoop
noTabs:
	.leave
	ret
DrawTabLinesAfterPos	endp

TextDrawCode ends

TextBorder	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextDrawTabLine

DESCRIPTION:	Draw a line that is associated with a tab

CALLED BY:	TextClearBehindLine

PASS:
	ds:dx	= VisTextInstance
	di	= GState
	ss:bp	= LICL_frame
			LICL_rect - bounds of line
	ss:bp+si = Tab structure to draw (drawn in border color)

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	left tab:
		left = tabPos-width-spacing
	right tab:
		left = tabPos+spacing

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

TextDrawTabLine	proc	far		uses ax, bx, cx, dx
	class	VisTextClass
	.enter

	call	SetBorderColorAndAttributes
	pushf

	; get window coordinate conversion

	mov	bx, dx
	mov	ax, ds:[bx].VI_bounds.R_left
	add	ax, ds:[bx].VTI_leftOffset
	add	al, ds:[bx].VTI_lrMargin
	adc	ah, 0
	push	ax

	mov	al, ss:[bp][si].T_grayScreen
	call	GrSetAreaMask

	; bx <- width, dx <- spacing

	mov	al, ss:[bp][si].T_lineWidth
	call	convertWidth
	mov_tr	bx, ax					;bx = width

	mov	al, ss:[bp][si].T_lineSpacing
	call	convertWidth
	mov_tr	dx, ax					;dx = spacing

	mov	ax, ss:[bp][si].T_position		;ax = position

	; if left/center/anchored -> left = tabPos-width-spacing

	mov	cl, ss:[bp][si].T_attr
	and	cl, mask TA_TYPE
	cmp	cl, TT_RIGHT shl offset TA_TYPE
	jz	right
	sub	ax, bx			;ax = tabPos-width
	sub	ax, dx			;ax = tabPos-width-spacing
	jmp	common

	; else right -> left = tabPos+spacing

right:
	add	ax, dx			;ax = tabPos+spacing

common:

	; ax = left, make cx = right = left + width

	mov	cx, ax
	add	cx, bx
	pop	dx			;recover conversion value
	add	ax, dx
	add	cx, dx

	; draw the rectangle

	mov	bx, LICL_rect.R_top
	mov	dx, LICL_rect.R_bottom
	call	GrFillRect

	popf
	jz	30$
	clr	ax
	call	GrSetAreaPattern
30$:

	.leave
	ret

convertWidth:
	;
	; value to convert is *8, divide by 8 and round (not necessarily
	; in that order)
	;
	clr	ah
	add	ax, 4
	shr	ax
	shr	ax
	shr	ax
	retn

TextDrawTabLine	endp

TextBorder	ends
