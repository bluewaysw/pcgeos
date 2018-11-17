COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentCode.asm

AUTHOR:		Julie Tsai, Apr 6, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/6/92		Initial revision

DESCRIPTION:
	This file contains the file-handling/interface code for the NTaker
	app.

	$Id: documentInk.asm,v 1.1 97/04/04 16:17:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentInkCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerInkSetBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Sets the background type and background on the screen
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerInkClass object
		ds:di	= NTakerInkClass instance data
		ds:bx	= NTakerInkClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		cx	= Ink background types
		dx	= Custom GString Vmem handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerInkSetBackground	method dynamic NTakerInkClass, 
					MSG_NTAKER_INK_SET_BACKGROUND
	uses	ax, cx, dx, bp
	.enter

EC <	cmp	cx, InkBackgroundType					>
EC <	ERROR_AE	BAD_INK_BACKGROUND_TYPE				>

	mov	ds:[di].NTI_curBackground, cx
	
	cmp	cx, IBT_CUSTOM_BACKGROUND
	jne	common

	mov	ax, ds:[di].NTI_customGString
	tst	ax
	jz	setCustomGString
	
	;there is a previous GString
	push	si, di, dx
	mov	dl, GSKT_LEAVE_DATA
	mov	si, ds:[di].NTI_customGString	; si=gstring to kill
	clr	di				; no associated GState
	call	GrDestroyGString
	pop	si, di, dx

setCustomGString:
	mov	ds:[di].NTI_customGString, dx

common:	
;	If the current background is IBT_NO_BACKGROUND, then 

	mov	dx, mask IF_INVALIDATE_ERASURES
	cmp	cx, IBT_NO_BACKGROUND
	mov	cx, 0
	je	10$
	mov	cx, mask IF_INVALIDATE_ERASURES
	clr	dx
10$:
	mov	ax, MSG_INK_SET_FLAGS
	call	ObjCallInstanceNoLock


	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave
	ret
NTakerInkSetBackground	endm

;Create a table of routines for MSG_VIS_DRAW (NTakerInkVisDraw)
BGRoutines	nptr	DrawNothing
		nptr	DrawNarrowLinedPaper
		nptr	DrawMediumLinedPaper
		nptr	DrawWideLinedPaper
		nptr	DrawNarrowStenoPaper
		nptr	DrawMediumStenoPaper
		nptr	DrawWideStenoPaper
		nptr	DrawSmallGrid
		nptr	DrawMediumGrid
		nptr	DrawLargeGrid
		nptr	DrawSmallCrossSection
		nptr	DrawMediumCrossSection
		nptr	DrawLargeCrossSection
		nptr	DrawToDoList		
		nptr	DrawPhoneMessage
		nptr	DrawCustomBackground


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerInkVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Message handler for MSG_VIS_DRAW of NTakerInkClass

CALLED BY:	GLOBAL

PASS:		*ds:si	= NTakerInkClass object
		ds:di	= NTakerInkClass instance data
		ds:bx	= NTakerInkClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		bp	= GState handle
		cl	= DrawFlag

RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerInkVisDraw	method dynamic NTakerInkClass, MSG_VIS_DRAW
	.enter

	;bp = GState
	cmp	ds:[di].NTI_curBackground, IBT_NO_BACKGROUND
	jz 	callSuper

	push	di
	mov	di, bp
	call	GrSaveState
	pop	di
	mov	di, ds:[di].NTI_curBackground
EC <	cmp	di, InkBackgroundType					>
EC <	ERROR_AE	BAD_INK_BACKGROUND_TYPE				>
	call	cs:BGRoutines[di]

	mov	di, bp
	call	GrRestoreState

callSuper:
	mov	di, offset NTakerInkClass
	call	ObjCallSuperNoLock
	.leave
	ret
NTakerInkVisDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw nothing on the background

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawNothing	proc	near
	.enter

	;do nothing

	.leave
	ret
DrawNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawNarrowLinedPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw lined paper (narrow) on the background

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawNarrowLinedPaper	proc	near	uses	bx
	.enter

	mov	bx, NTAKER_INK_NARROW_LINE_DISTANCE
	call	DrawHorizontalLines

	.leave
	ret
DrawNarrowLinedPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMediumLinedPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw lined paper (medium distance between lines) 
		on the background

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMediumLinedPaper	proc	near	uses	bx
	.enter

	mov	bx, NTAKER_INK_MEDIUM_LINE_DISTANCE
	call	DrawHorizontalLines

	.leave
	ret
DrawMediumLinedPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawWideLinedPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw lined paper (wide) on the background

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawWideLinedPaper	proc	near	uses	bx
	.enter

	mov	bx, NTAKER_INK_WIDE_LINE_DISTANCE
	call	DrawHorizontalLines

	.leave
	ret
DrawWideLinedPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawNarrowStenoPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw steno paper (narrow) on the background

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawNarrowStenoPaper	proc	near	uses	bx
	.enter
	mov	bx, NTAKER_INK_NARROW_LINE_DISTANCE
	call	DrawHorizontalLines
	call	DrawMiddlePageVerticalLine
	.leave
	ret
DrawNarrowStenoPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMediumStenoPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw steno paper (medium) on the background

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMediumStenoPaper	proc	near	uses	bx
	.enter
	mov	bx, NTAKER_INK_MEDIUM_LINE_DISTANCE
	call	DrawHorizontalLines
	call	DrawMiddlePageVerticalLine
	.leave
	ret
DrawMediumStenoPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawWideStenoPaper
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw steno paper (wide) on the background

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawWideStenoPaper	proc	near	uses	bx
	.enter
	mov	bx, NTAKER_INK_WIDE_LINE_DISTANCE
	call	DrawHorizontalLines
	call	DrawMiddlePageVerticalLine
	.leave
	ret
DrawWideStenoPaper	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSmallGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw small grids on the background of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSmallGrid	proc	near	uses	bx
	.enter

	mov	bl, NTAKER_INK_SMALL_CELL_HEIGHT
	clr	bh
	call	DrawHorizontalLines

	mov	bl, NTAKER_INK_SMALL_CELL_WIDTH
	clr	bh
	call	DrawVerticalLines

	.leave
	ret
DrawSmallGrid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMediumGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw medium grids on the background of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMediumGrid	proc	near	uses	bx
	.enter

	mov	bl, NTAKER_INK_MEDIUM_CELL_HEIGHT
	clr	bh
	call	DrawHorizontalLines

	mov	bl, NTAKER_INK_MEDIUM_CELL_WIDTH
	clr	bh
	call	DrawVerticalLines
	
	.leave
	ret
DrawMediumGrid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLargeGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw large grids on the background of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawLargeGrid	proc	near	uses	bx
	.enter

	mov	bl, NTAKER_INK_LARGE_CELL_HEIGHT
	clr	bh
	call	DrawHorizontalLines

	mov	bl, NTAKER_INK_LARGE_CELL_WIDTH
	clr	bh
	call	DrawVerticalLines

	.leave
	ret
DrawLargeGrid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSmallCrossSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw small grid paper on the background of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSmallCrossSection	proc	near	uses	bx
	.enter
	mov	bl, NTAKER_INK_SMALL_CROSS_SECTION_CELL_HEIGHT
	clr	bh
	call	DrawCrossSectionHorizontalLines

	mov	bl, NTAKER_INK_SMALL_CROSS_SECTION_CELL_WIDTH
	clr	bh
	call	DrawCrossSectionVerticalLines

	.leave
	ret
DrawSmallCrossSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMediumCrossSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw medium grid paper on the background of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMediumCrossSection	proc	near	uses	bx
	.enter

	mov	bl, NTAKER_INK_MEDIUM_CROSS_SECTION_CELL_HEIGHT
	clr	bh
	call	DrawCrossSectionHorizontalLines

	mov	bl, NTAKER_INK_MEDIUM_CROSS_SECTION_CELL_WIDTH
	clr	bh
	call	DrawCrossSectionVerticalLines

	.leave
	ret
DrawMediumCrossSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLargeCrossSection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw medium grid paper on the background of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawLargeCrossSection	proc	near	uses	bx
	.enter

	mov	bl, NTAKER_INK_LARGE_CROSS_SECTION_CELL_HEIGHT
	clr	bh
	call	DrawCrossSectionHorizontalLines

	mov	bl, NTAKER_INK_LARGE_CROSS_SECTION_CELL_WIDTH
	clr	bh
	call	DrawCrossSectionVerticalLines

	.leave
	ret
DrawLargeCrossSection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawToDoList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw "To Do List" with check boxes and lists on the background
		of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

GrDrawText
PASS: 		ax - x position for string
		bx - y position for string
		cx - maximum number of characters to draw
		     (or 0 for null terminated string)
		ds:si - string to draw
		di - handle of graphics state
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawToDoList	proc	near	uses	ax,bx,cx,dx,si,di,bp,ds,es
	maxRow		local	word
	boxLeftBound	local	word
	lineLeftBound	local	word
	lineRightBound	local	word
	stringBuffer	local	NTAKER_INK_TO_DO_LIST_STRING_SIZE dup (char)
	drawFlag	local	byte

	mov	di, bp
	.enter

	mov	drawFlag, cl
	mov	cx, NTAKER_DOCUMENT_PRINT_FONT_TYPE
	mov	dx, NTAKER_INK_BACKGROUND_BIG_FONT_SIZE
	clr	ah
	call	GrSetFont

	push	ds, si
	GetResourceHandleNS toDoListString, bx
	mov	si, offset toDoListString
	mov	cx, NTAKER_INK_BACKGROUND_TITLE_STRINGS_LEFT_MARGIN
	mov	dx, NTAKER_INK_BACKGROUND_TITLE_STRINGS_TOP_MARGIN
	call	DrawText
	pop	ds, si

	call	VisGetBounds			;ax = left, bx = top
						;cx = right, dx = bottom
	add	ax, NTAKER_INK_CHECK_BOX_LEFT_MARGIN	
	mov	boxLeftBound, ax
	add	ax, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	add	ax, NTAKER_INK_CHECK_BOX_STRING_LEFT_MARGIN
	mov	lineLeftBound, ax
	mov	lineRightBound, cx

	;find max number of rows to draw
	sub	dx, NTAKER_INK_CHECK_BOX_TOP_MARGIN
	mov	ax, NTAKER_INK_MEDIUM_CELL_HEIGHT
	clr	bx	
	call	FindMaxRow_Col			;dx = max number of rows
	mov	maxRow, dx

	mov	cx, maxRow
	mov	bx, NTAKER_INK_CHECK_BOX_TOP_MARGIN
	mov	dx, bx
	add	dx, NTAKER_INK_CHECK_BOX_CELL_HEIGHT

drawLoop:
	push	cx
	;Draw the check box
	mov	ax, boxLeftBound
	mov	cx, ax
	add	cx, NTAKER_INK_CHECK_BOX_CELL_WIDTH
	add	ax, NTAKER_INK_CHECK_BOX_CELL_WIDTH_ADJUST
	sub	cx, NTAKER_INK_CHECK_BOX_CELL_WIDTH_ADJUST
	add	bx, NTAKER_INK_CHECK_BOX_CELL_HEIGHT_ADJUST
	sub	dx, NTAKER_INK_CHECK_BOX_CELL_HEIGHT_ADJUST
	push	bx, dx
	push	cx
	mov	cl, drawFlag
	call	Select_SetUpLineAttr
	pop	cx
	call	GrDrawRect
	pop	bx, dx

	;Draw text
	pop	cx

	;get the text string
	push	di, dx, cx, bx, ax
	segmov	es, ss
	lea	di, stringBuffer		;es:di = ptr to string
	clr	dx

	;convert the number e.g. (20, 19, 18, ...) => (1, 2, 3, ...)
	mov	ax, maxRow
	inc	ax
	sub	ax, cx

	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	segmov	ds, es
	mov	si, di				;ds:si = ptr to string
	pop	di, dx, cx, bx, ax
	push	cx
	push	dx
	mov	cx, 3
	call	GrTextWidth			;dx = width of the string 
						;     in points
	mov	ax, lineLeftBound
	sub	ax, dx
	clr	cx
	call	GrDrawText
	pop	dx

	;Draw the line
	call	SetUpListLineAttr
	mov	ax, lineLeftBound
	mov	cx, lineRightBound
	mov	bx, dx
	call	GrDrawLine

	;move on to next row
	add	dx, NTAKER_INK_CHECK_BOX_CELL_HEIGHT
	pop	cx
	loop	drawLoop

	.leave
	mov	bp, di
	ret
DrawToDoList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Select_SetUpLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Test the draw flag and set up the line attribute for drawing
CALLED BY:	INTERNAL
PASS:		cl - draw flag
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Select_SetUpLineAttr	proc	near
	.enter

	test	cl, mask DF_PRINT
	jz	10$
	call	SetUpPrintLineAttr
	jmp	done
10$:
	call	SetUpLineAttr
done:
	.leave
	ret
Select_SetUpLineAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPhoneMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw "Phone Message" with time, date, the person called,
		phone number and message on the background of the ink object

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPhoneMessage	proc	near	uses	ax,bx,cx,dx,si,di
	listY		local	word
	lineY		local	word
	rightBound	local	word
	mov	di, bp
	.enter

	push	cx				;DrawFlag

	mov	cx, NTAKER_DOCUMENT_PRINT_FONT_TYPE
	mov	dx, NTAKER_INK_BACKGROUND_BIG_FONT_SIZE
	clr	ah
	call	GrSetFont

	GetResourceHandleNS phoneMessageTitleString, bx
	mov	si, offset phoneMessageTitleString
	mov	cx, NTAKER_INK_BACKGROUND_TITLE_STRINGS_LEFT_MARGIN
	mov	dx, NTAKER_INK_BACKGROUND_TITLE_STRINGS_TOP_MARGIN
	call	DrawText

	mov	cx, NTAKER_DOCUMENT_PRINT_FONT_TYPE
	mov	dx, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	clr	ah
	call	GrSetFont

	call	SetUpListLineAttr

	GetResourceHandleNS phoneMessageToWhomString, bx
	mov	si, offset phoneMessageToWhomString
	mov	cx, NTAKER_INK_BACKGROUND_STRINGS_LEFT_MARGIN
	mov	dx, NTAKER_INK_BACKGROUND_STRINGS_TOP_MARGIN
	mov	listY, dx	
	mov	lineY, dx
	call	DrawText

	add	lineY, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	rightBound, NTAKER_INK_PHONE_MESSAGE_LINE_LENGTH
	mov	cx, rightBound
	mov	bx, lineY
	call	PhoneMessageDrawLine

	GetResourceHandleNS phoneMessageNameString, bx
	mov	si, offset phoneMessageNameString
	mov	cx, NTAKER_INK_BACKGROUND_STRINGS_LEFT_MARGIN
	mov	dx, listY
	add	dx, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	listY, dx
	call	DrawText

	mov	cx, rightBound
	add	lineY, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	bx, lineY
	call	PhoneMessageDrawLine

	GetResourceHandleNS phoneMessageCompanyString, bx
	mov	si, offset phoneMessageCompanyString
	mov	cx, NTAKER_INK_BACKGROUND_STRINGS_LEFT_MARGIN
	mov	dx, listY
	add	dx, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	listY, dx
	call	DrawText

	mov	cx, rightBound
	add	lineY, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	bx, lineY
	call	PhoneMessageDrawLine

	GetResourceHandleNS phoneMessagePhoneString, bx
	mov	si, offset phoneMessagePhoneString
	mov	cx, NTAKER_INK_BACKGROUND_STRINGS_LEFT_MARGIN
	mov	dx, listY
	add	dx, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	listY, dx
	call	DrawText

	add	lineY, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	cx, rightBound
	mov	bx, lineY
	call	PhoneMessageDrawLine

	GetResourceHandleNS phoneMessageDateString, bx
	mov	si, offset phoneMessageDateString
	mov	cx, NTAKER_INK_BACKGROUND_STRINGS_LEFT_MARGIN
	mov	dx, listY
	add	dx, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	listY, dx
	call	DrawText

	mov	cx, rightBound
	add	lineY, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	bx, lineY
	call	PhoneMessageDrawLine

	GetResourceHandleNS phoneMessageTimeString, bx
	mov	si, offset phoneMessageTimeString
	mov	cx, NTAKER_INK_BACKGROUND_STRINGS_LEFT_MARGIN
	mov	dx, listY
	add	dx, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	listY, dx
	call	DrawText

	mov	cx, rightBound
	add	lineY, NTAKER_INK_BACKGROUND_SMALL_FONT_SIZE
	mov	bx, lineY
	call	PhoneMessageDrawLine

	GetResourceHandleNS phoneMessageString, bx
	mov	si, offset phoneMessageString
	mov	cx, NTAKER_INK_BACKGROUND_STRINGS_LEFT_MARGIN
	mov	dx, listY
	add	dx, NTAKER_INK_CHECK_BOX_CELL_HEIGHT
	mov	listY, dx
	call	DrawText

	mov	cx, rightBound
	add	lineY, NTAKER_INK_CHECK_BOX_CELL_HEIGHT
	mov	bx, lineY
	call	PhoneMessageDrawMessageLines

	pop	cx				;DrawFlag

	.leave
	mov	bp, di
	ret
DrawPhoneMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PhoneMessageDrawLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw a single line after text for the "Phone Message"
		background

CALLED BY:	DrawPhoneMessage

PASS:		bx - y position of the line
		cx - right bound of the line
		di - Gstate handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PhoneMessageDrawLine	proc	near	uses	ax,dx
	.enter

	mov	ax, NTAKER_INK_CHECK_BOX_PHONE_LEFT_MARGIN
	mov	dx, bx
	call	GrDrawLine

	.leave
	ret
PhoneMessageDrawLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PhoneMessageDrawMessageLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw multiple lines after message text for the "Phone Message"
		background

CALLED BY:	DrawPhoneMessage

PASS:		bx - y position of the line
		cx - right bound of the line
		di - Gstate handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PhoneMessageDrawMessageLines	proc	near	uses	ax,bx,cx,dx
	rightBound	local	word
	.enter

	mov	rightBound, cx
	mov	cx, NTAKER_INK_PHONE_MESSAGE_NUMBER_LINES
drawLoop:
	push	cx
	mov	ax, NTAKER_INK_CHECK_BOX_PHONE_LEFT_MARGIN
	mov	cx, rightBound
	mov	dx, bx	
	call	GrDrawLine				;pass:
							;ax=left, bx=top
							;cx=right,dx=bottom
	add	bx, NTAKER_INK_CHECK_BOX_CELL_HEIGHT
	pop	cx
	loop	drawLoop

	.leave
	ret
PhoneMessageDrawMessageLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw Text on the background of the ink object

CALLED BY:	DrawPhoneMessage / DrawToDoList

PASS:		bx - string handle
		si - string offset
		cx - x position of the string
		dx - y position of the string

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawText	proc	near	uses	ax,cx,ds,si
	.enter

	push	bx
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]
	mov	bx, dx
	mov	ax, cx
	clr	cx
	call	GrDrawText
	pop	bx
	call	MemUnlock

	.leave
	ret
DrawText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHorizontalLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw horizontal lines on the background of the ink object
		from top bound to bottom bound.

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object
		bx = cell height

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawHorizontalLines	proc	near	uses	ax,bx,cx,dx,di
	leftBound	local	word
	rightBound	local	word
	cellHeight	local	word	
	maxRow		local	word
	
	mov	di, bp					; GState handle => DI
	;save it before bp got destroyed when enter

	.enter

	mov	cellHeight, bx

	call	Select_SetUpLineAttr

	;set up work to draw the line
	call	VisGetBounds				;returns:
							;ax=left, bx=top
							;cx=right,dx=bottom
	mov	leftBound, ax
	mov	rightBound, cx

	call	VisGetSize			;cx = width of the object
						;dx = height of the object

	mov	ax, cellHeight
	push	bx					;perserve top bound
	clr	bx
	call	FindMaxRow_Col				;dx = maxRow
	mov	maxRow, dx
	pop	bx
	add	bx, cellHeight				;so that it won't
							;draw from the very top
	mov	dx, bx					;draw horizontal lines

	mov	cx, maxRow

	; Draw the line
drawLoop:
	push	cx
	mov	ax, leftBound
	mov	cx, rightBound
	call	GrDrawLine				;pass:
							;ax=left, bx=top
							;cx=right,dx=bottom
	add	bx, cellHeight
	add	dx, cellHeight
	pop	cx
	loop	drawLoop

	.leave
	mov	bp, di					; GState handle => BP
	ret
DrawHorizontalLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCrossSectionHorizontalLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw horizontal lines on the background of the ink object
		from top bound to bottom bound and draw a thick line
		every ten regular thin lines.

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object
		bx = cell height

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCrossSectionHorizontalLines	proc	near	uses	ax,bx,cx,dx,di
	leftBound	local	word
	rightBound	local	word
	topBound	local	word
	cellHeight	local	word	
	maxRow		local	word

	mov	di, bp					; GState handle => DI
	;save it before bp got destroyed when enter

	.enter

	mov	cellHeight, bx

	call	Select_SetUpLineAttr

	;set up work to draw the line
	call	VisGetBounds				;returns:
							;ax=left, bx=top
							;cx=right,dx=bottom
	mov	leftBound, ax
	mov	rightBound, cx

	call	VisGetSize			;cx = width of the object
						;dx = height of the object

	mov	ax, cellHeight
	push	bx					;perserve top bound
	clr	bx
	call	FindMaxRow_Col				;dx = maxRow
	mov	maxRow, dx
	pop	bx
	add	bx, cellHeight				;so that it won't
							;draw from the very top
	mov	topBound, bx
	mov	dx, bx					;draw horizontal lines

	mov	cx, maxRow

	; Draw the line
drawLoop:
	push	cx
	mov	ax, leftBound
	mov	cx, rightBound
	call	GrDrawLine				;pass:
							;ax=left, bx=top
							;cx=right,dx=bottom
	add	bx, cellHeight
	add	dx, cellHeight
	pop	cx
	loop	drawLoop

	;draw dark lines every 10 segments.
	call	SetUpDarkLineAttr
	
	;multiply cellHeight by 10
	mov	ax, cellHeight
	mov	bx, NTAKER_INK_CROSS_SECTION_INTERVAL
	mul	bx
	mov	cellHeight, ax			

	;set up the top and bottom bound
	mov	bx, topBound
	mov	dx, bx					;top = bottom bound
	mov	cx, maxRow

drawDarkLoop:
	push	cx
	mov	ax, leftBound
	mov	cx, rightBound
	call	GrDrawLine				;pass:
							;ax=left, bx=top
							;cx=right,dx=bottom
	add	bx, cellHeight
	add	dx, cellHeight
	pop	cx
	loop	drawDarkLoop

	.leave
	mov	bp, di					; GState handle => BP
	ret
DrawCrossSectionHorizontalLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawVerticalLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw vertical lines on the background of the ink object
		from left bound to right bound.

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object
		bx = cell width

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawVerticalLines	proc	near	uses	ax,bx,cx,dx,di
	topBound	local	word
	bottomBound	local	word
	cellWidth	local	word	
	maxCol		local	word

	mov	di, bp					; GState handle => DI
	;save it before bp got destroyed when enter

	.enter

	mov	cellWidth, bx

	push	cx					;DrawFlags
	call	SetUpLineAttr

	;set up work to draw the line
	call	VisGetBounds				;returns:
							;ax=left, bx=top
							;cx=right,dx=bottom
	mov	topBound, bx
	mov	bottomBound, dx

	call	VisGetSize			;cx = width of the object
						;dx = height of the object

	mov	bx, cellWidth
	push	ax					;perserve left bound
	clr	ax
	call	FindMaxRow_Col				;cx = max # of columns
	pop	ax
	add	ax, cellWidth				;so that it won't draw
							;from the very left
	mov	maxCol, cx
	mov	dx, ax

	; Draw the line
drawLoop:
	push	cx

	mov_tr	cx, dx
	mov	bx, topBound
	mov	dx, bottomBound

	call	GrDrawLine				;pass:
							;ax=left, bx=top
							;cx=right,dx=bottom
	add	ax, cellWidth
	add	cx, cellWidth
	mov_tr 	dx, cx					;save right bound

	pop	cx
	loop	drawLoop

	pop	cx
	.leave
	mov	bp, di					; GState handle => BP
	ret
DrawVerticalLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCrossSectionVerticalLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw vertical lines on the background of the ink object
		from left bound to right bound and draw a thick line
		every ten regular thin lines.

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object
		bx = cell width

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCrossSectionVerticalLines	proc	near	uses	ax,bx,cx,dx,di
	topBound	local	word
	bottomBound	local	word
	leftBound	local	word
	cellWidth	local	word	
	maxCol		local	word

	mov	di, bp					; GState handle => DI
	;save it before bp got destroyed when enter

	.enter

	mov	cellWidth, bx

	call	Select_SetUpLineAttr

	;set up work to draw the line
	call	VisGetBounds				;returns:
							;ax=left, bx=top
							;cx=right,dx=bottom
	mov	topBound, bx
	mov	bottomBound, dx

	call	VisGetSize			;cx = width of the object
						;dx = height of the object

	mov	bx, cellWidth
	push	ax					;perserve left bound
	clr	ax
	call	FindMaxRow_Col				;cx = max # of columns
	pop	ax
	add	ax, cellWidth				;so that it won't draw
							;from the very left
	mov	leftBound, ax
	mov	maxCol, cx
	mov	dx, ax					;dx = left = right

	; Draw the line
drawLoop:
	push	cx

	mov_tr	cx, dx					;cx = right
	mov	bx, topBound
	mov	dx, bottomBound

	call	GrDrawLine				;pass:
							;ax=left, bx=top
							;cx=right,dx=bottom
	add	ax, cellWidth
	add	cx, cellWidth
	mov_tr 	dx, cx					;save right bound

	pop	cx
	loop	drawLoop

	;draw dark lines every 10 segments.
	call	SetUpDarkLineAttr
	
	;multiply cellWidth by 10
	mov	ax, cellWidth
	mov	bx, NTAKER_INK_CROSS_SECTION_INTERVAL
	mul	bx
	mov	cellWidth, ax			

	;set up the left and right bound
	mov	ax, leftBound
	mov	dx, ax					;left = right bound
	mov	cx, maxCol

drawDarkLoop:
	push	cx

	mov_tr	cx, dx
	mov	bx, topBound
	mov	dx, bottomBound

	call	GrDrawLine				;pass:
							;ax=left, bx=top
							;cx=right,dx=bottom
	add	ax, cellWidth
	add	cx, cellWidth
	mov_tr 	dx, cx					;save right bound

	pop	cx
	loop	drawDarkLoop

	.leave
	mov	bp, di					; GState handle => BP
	ret
DrawCrossSectionVerticalLines	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMiddlePageVerticalLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw one vertical line from top to bottom at the middle of
		the ink object.	

CALLED BY:	DrawStenoPaper routines

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMiddlePageVerticalLine	proc	near	uses	ax,bx,cx,dx,di
	.enter

	mov	di, bp					; GState handle => DI

	call	Select_SetUpLineAttr

	;set up work to draw the line
	call	VisGetBounds				;returns:
							;ax=left, bx=top
							;cx=right,dx=bottom

	;mid point of left and right bound = ( left + right )/2
	add	ax, cx
	shr	ax, 1					;ax=mid point of
							;left and right bound
	mov	cx, ax
	call	GrDrawLine

	mov	bp, di
	.leave
	ret
DrawMiddlePageVerticalLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Some set-up work for GrSetLineAttr to draw thin (1 pixel),
		light blue lines

CALLED BY:	INTERNAL
PASS:		di - GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		JULIE:	I changed this to reflect a new API for GrSetLineAttr.
			See me if you have any questions.  jim  5/5/92

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpLineAttr	proc	near	uses	ds, si
	la	local	LineAttr
	.enter

	; di = gstate/gstring handle
	; load up the attributes we want.

	mov 	ss:la.LA_colorFlag, CF_INDEX
	mov	ss:la.LA_color.RGB_red, C_LIGHT_BLUE
	mov	ss:la.LA_width.WWF_int, 1
	mov	ss:la.LA_width.WWF_frac, 0
	mov	ss:la.LA_end, LE_SQUARECAP
	mov	ss:la.LA_join, LJ_MITERED
	mov	ss:la.LA_mapMode, CMT_CLOSEST
	mov	ss:la.LA_mask, SDM_100
	mov	ss:la.LA_style, LS_SOLID
	segmov	ds, ss				; ds:si -> LineAttr struct
	lea	si, ss:la
	call	GrSetLineAttr

	.leave
	ret
SetUpLineAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpDarkLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Some set-up work for GrSetLineAttr to draw thick (2 pixels),
		light blue lines

CALLED BY:	INTERNAL
PASS:		di - GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		JULIE:	I changed this to reflect a new API for GrSetLineAttr.
			See me if you have any questions.  jim  5/5/92
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpDarkLineAttr	proc	near	uses	ds,si
	la	local	LineAttr
	.enter

	; di = gstate/gstring handle
	; load up the attributes we want.

	mov 	ss:la.LA_colorFlag, CF_INDEX
	mov	ss:la.LA_color.RGB_red, C_LIGHT_BLUE
	mov	ss:la.LA_width.WWF_int, 2
	mov	ss:la.LA_width.WWF_frac, 0
	mov	ss:la.LA_end, LE_SQUARECAP
	mov	ss:la.LA_join, LJ_MITERED
	mov	ss:la.LA_mapMode, CMT_CLOSEST
	mov	ss:la.LA_mask, SDM_100
	mov	ss:la.LA_style, LS_SOLID
	segmov	ds, ss				; ds:si -> LineAttr struct
	lea	si, ss:la
	call	GrSetLineAttr

	.leave
	ret
SetUpDarkLineAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpListLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Some set-up work for GrSetLineAttr to draw thick (2 pixels),
		black lines

CALLED BY:	INTERNAL
PASS:		di - GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		JULIE:	I changed this to reflect a new API for GrSetLineAttr.
			See me if you have any questions.  jim  5/5/92
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpListLineAttr	proc	near		uses	ds,si
	la	local	LineAttr
	.enter

	; di = gstate/gstring handle

	; load up the attributes we want.

	mov 	ss:la.LA_colorFlag, CF_INDEX
	mov	ss:la.LA_color.RGB_red, C_BLACK
	mov	ss:la.LA_width.WWF_int, 2
	mov	ss:la.LA_width.WWF_frac, 0
	mov	ss:la.LA_end, LE_SQUARECAP
	mov	ss:la.LA_join, LJ_MITERED
	mov	ss:la.LA_mapMode, CMT_CLOSEST
	mov	ss:la.LA_mask, SDM_100
	mov	ss:la.LA_style, LS_SOLID
	segmov	ds, ss				; ds:si -> LineAttr struct
	lea	si, ss:la
	call	GrSetLineAttr

	.leave
	ret
SetUpListLineAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpPrintLineAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Some set-up work for GrSetLineAttr to draw thin (1 pixels),
		black lines

CALLED BY:	INTERNAL
PASS:		di - GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		JULIE:	I changed this to reflect a new API for GrSetLineAttr.
			See me if you have any questions.  jim  5/5/92
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpPrintLineAttr	proc	near		uses	ds,si
	la	local	LineAttr
	.enter

	; di = gstate/gstring handle

	; load up the attributes we want.

	mov 	ss:la.LA_colorFlag, CF_INDEX
	mov	ss:la.LA_color.RGB_red, C_BLACK
	mov	ss:la.LA_width.WWF_int, 1
	mov	ss:la.LA_width.WWF_frac, 0
	mov	ss:la.LA_end, LE_SQUARECAP
	mov	ss:la.LA_join, LJ_MITERED
	mov	ss:la.LA_mapMode, CMT_CLOSEST
	mov	ss:la.LA_mask, SDM_100
	mov	ss:la.LA_style, LS_SOLID
	segmov	ds, ss				; ds:si -> LineAttr struct
	lea	si, ss:la
	call	GrSetLineAttr

	.leave
	ret
SetUpPrintLineAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindMaxRow_Col
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Find out the width and height of a cell

CALLED BY:	INTERNAL

PASS:		*ds:si - instance data of the visual object
		ax - cell Height 
		bx - cell Width
		cx - width of the object
		dx - height of the object

RETURN:		cx - max number of columns
		dx - max number of rows

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindMaxRow_Col	proc	near	uses	ax,bx
	.enter

	push	dx				;save height of the object

	tst	bx				;make sure cell width <> 0
	je	findRow

	push	ax				;save max number of rows

	;max # of columns = width of the object / cell width
	mov	ax, cx	
	clr	dx
	div	bx
	mov	cx, ax				;cx = max number of columns
	pop	ax				;ax = cell height

findRow:
	mov	bx, ax				;bx = cell height
	tst	bx				;make sure cell height <> 0
	pop	ax				;ax = height of the object
	je	done

	;max # of rows = height of the object / cell height
	clr	dx
	div	bx
	mov	dx, ax

done:
	.leave
	ret

FindMaxRow_Col	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCustomBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Draw a user-created background.

CALLED BY:	NTakerInkVisDraw

PASS:		bp = GState
		cl = DrawFlag
		*ds:si	= NTakerInkClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCustomBackground	proc	near
	class	NTakerInkClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	;si = vmem block handle of gstring
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	mov	si, ds:[si].NTI_customGString
	mov	di, bp

;	GrDrawGString:
;	PASS:	di	- gstate handle of target draw space
;		ax	- x coordinate to draw string
;     		bx	- y coordinate to draw string
;		si	- graphics string handle for string to draw
;		dx	- control flags  (This is a record of type GSControl):

	clr	dx
	call	GrGetGStringBounds	;ax <= left coord
					;bx <= top coord
	neg	ax
	neg	bx
	clr	dx
	call	GrDrawGString
	mov	bp, di

	.leave
	ret
DrawCustomBackground	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerInkVisDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Handler to destroy custom GString
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerInkClass object
		ds:di	= NTakerInkClass instance data
		ds:bx	= NTakerInkClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		dl	= VisUpdateMode
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerInkVisDestroy	method dynamic NTakerInkClass, MSG_VIS_DESTROY
	.enter
	
	mov	di, offset NTakerInkClass
	call	ObjCallSuperNoLock
	mov	si, ds:[si]
	add	si, ds:[si].NTakerInk_offset
	mov	si, ds:[si].NTI_customGString	; sx=gstring to kill
	tst	si
	jz	done

	mov	dl, GSKT_LEAVE_DATA
	clr	di				; di = GState (= 0)
	call	GrDestroyGString
done:
	.leave
	ret
NTakerInkVisDestroy	endm
DocumentInkCode	ends		;end of CommonCode resource









