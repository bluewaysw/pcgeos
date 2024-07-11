COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		bgutil.asm

AUTHOR:		RON, Dec 14, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RON	12/14/95   	Initial revision


DESCRIPTION:
	

	$Id: bgadgetUtil.asm,v 1.1 98/03/12 19:50:33 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include assert.def
include	Legos/ent.def
include Internal/im.def

BGadgetAsmUtilsResource	segment	resource
RESIZE_WIDTH	= 5
PrimaryResizeRegion	label	Region
	word	PARAM_0, PARAM_1, PARAM_2-1, PARAM_3-1		; bounds

	word	PARAM_1-1,					EOREGREC
	word	PARAM_1+RESIZE_WIDTH-1, PARAM_0, PARAM_2-1,	EOREGREC
	word	PARAM_3-RESIZE_WIDTH-1
	word		PARAM_0, PARAM_0+RESIZE_WIDTH-1
	word		PARAM_2-RESIZE_WIDTH, PARAM_2-1,	EOREGREC
	word	PARAM_3-1, PARAM_0, PARAM_2-1,			EOREGREC
	word	EOREGREC

	SetDefaultConvention
_BentImResizeWindow	proc	far	left:word, top:word,
					right:word, bottom:word,
					win:hptr.window,
					minwidth:word, minheight:word,
					maxwidth:word, maxheight:word,
					ptrX:word, ptrY:word, flags:XorFlags
	
		uses bx, cx, dx, si, di, es, ds, bp
		.enter
		push	bp
		mov	ax, left
		mov	bx, top
		mov	cx, right
		mov	dx, bottom
		mov	di, win
		mov	si, flags
		push	minwidth
		push	minheight
		push	maxwidth
		push	maxheight
		push	ptrX
		push	ptrY

		mov	ax, handle PrimaryResizeRegion
		push	ax
		mov	ax, offset PrimaryResizeRegion
		push	ax
		mov	ax, left
		clr	bp		; match action flags		
		call	ImStartMoveResize
		pop	bp
		.leave
		ret
_BentImResizeWindow	endp
	public	_BentImResizeWindow
	SetGeosConvention

BGadgetAsmUtilsResource	ends


