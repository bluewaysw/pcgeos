COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		TrueType Font Driver
FILE:		truetypePath.asm

AUTHOR:		Falk Rehwagen, Jan 29, 2021

ROUTINES:
	Name				Description
	----				-----------
EXT	TrueTypeGenPath			Generate path for character

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/29/21		Initial revision

DESCRIPTION:
	Routines for generating graphics string of a character.

	$Id: truetypePath.asm,v 1.1 97/04/18 11:45:26 bluewaysw Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeGenPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a path for the outline of a character
CALLED BY:	DR_FONT_GEN_PATH (via TrueTypeStrategy)

PASS:		ds - seg addr of font info block
		di - handle of GState (passed in bx, locked)
		dx - character to generate (Chars)
		cl - FontGenPathFlags
			FGPF_POSTSCRIPT - transform for use as Postscript
						Type 1 or Type 3 font.
			FGPF_SAVE_STATE - do save/restore for GState
RETURN:		none
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/29/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeGenPath	proc	far
	uses	ax, bx, cx, si, ds, es
	.enter

	xchg	di, ax				;ax <- handle of GState
	mov		di, 400
	call	ThreadBorrowStackSpace
	push	di

	push 	ax					;pass GState handle
	mov		ch, 0
	push 	cx					;pass FontGenPathFlags
	push	dx					;pass characters code

	mov 	bx, ax
	call 	MemLock				;lock GState block
	mov		es, ax				;es <- seg addr of gstate		
	mov		cx, es:GS_fontAttr.FCA_fontID
	clr		ah		                   
	mov		al, es:GS_fontAttr.FCA_textStyle

	call	FontDrFindFontInfo
	push	ds					;pass ptr to FontInfo
	push	di

	mov		cx, ds				;save ptr to FontInfo
	mov		dx, di

	mov		si, bx				;si <- handle of GState
	mov		bx, ODF_HEADER
	call	FontDrFindOutlineData
	push	ds					;pass ptr to OutlineEntry
	push	di

	mov		ds, cx
	mov		di, dx

	clr		ah
	mov		al, es:GS_fontAttr.FCA_textStyle
	mov		bx, ODF_PART1
	call	FontDrFindOutlineData
	push	ds					;pass ptr to FontHeader
	push	di
	push	ax					;pass stylesToImplement
	mov		bx, si				;bx <- handle of GState
	call	MemUnlock			;unlock GState block

	segmov	ds, dgroup, ax
	push	ds:variableHandle	;pass handle to truetype block
	call	TRUETYPE_GEN_PATH

	pop		di
	call	ThreadReturnStackSpace

	.leave
	ret
TrueTypeGenPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeGenInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a character in the passed RegionPath
CALLED BY:	DR_FONT_GEN_IN_REGION (via TrueTypeStrategy)

PASS:		ds - seg addr of font info block
		di - handle of GState (passed in BX)
		dx - character to generate (Chars)
		cx - RegionPath handle (locked)
RETURN:		nothing
DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
		We want override some of the default functionality for
		build a font's character. Essentially:
			* Always build a character in a region
			* Build this character in the passed region

		We accomplish this by:
			1) Find the character data
			2) Calculate/store the correct transformation
			3) Stuff in some new CharGenRouts
			4) Stuf in the pen position (in device coords)
			5) Go generate the character (via MakeBigCharInRegion)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	1/ 29/21	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeGenInRegion	proc	far
	uses	ax, bx, cx, dx, si, ds, es
	.enter

	mov		si,	di				;si <- GState handle
	mov		di, FONT_C_CODE_STACK_SPACE
	call	ThreadBorrowStackSpace
	push	di

    ; building parameter stack
	push 	si					;pass GState handle
	push	cx					;pass regionpath handle
	push	dx					;pass character code	

	mov		bx, si				;bx <- GState handle
	call 	MemLock				;lock GState block
	mov		es, ax				;es <- seg addr of GState		

	clr		al
	movwbf	dxah, es:GS_fontAttr.FCA_pointsize
	push	dx					;pass point size
	push 	ax	

	clr		ah
	mov		al, es:GS_fontAttr.FCA_width
	push	ax					;pass width
	mov		al, es:GS_fontAttr.FCA_weight
	push	ax					;pass weight

	mov		cx, es:GS_fontAttr.FCA_fontID
	call	FontDrFindFontInfo
	push	ds					;pass ptr to FontInfo
	push	di

	mov	cx, ds					;save ptr to FontInfo
	mov	dx, di	

	clr		ah		                   
	mov		al, es:GS_fontAttr.FCA_textStyle
	mov		bx, ODF_HEADER
	call	FontDrFindOutlineData
	push	ds					;pass ptr to OutlineEntry
	push	di

	mov	ds, cx					;get saved ptr to FontInfo
	mov	di, dx

	clr		ah
	mov		al, es:GS_fontAttr.FCA_textStyle
	mov		bx, ODF_PART1
	call	FontDrFindOutlineData
	push	ds					;pass ptr to FontHeader
	push	di
	push	ax					;pass stylesToImplement

	segmov	ds, dgroup, ax
	push	ds:variableHandle	;pass handle to truetype block
	call	TRUETYPE_GEN_IN_REGION

	mov		bx, si				;bx <- handle of GState
	call	MemUnlock			;unlock GState block

	pop		di
	call	ThreadReturnStackSpace

	.leave
	ret
TrueTypeGenInRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GrRegionPathMovePen

C DECLARATION:	extern void
			_far _pascal GrRegionPathMovePen(Handle regionHandle, sword x, sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JK		3/14/24		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GRREGIONPATHMOVEPEN		proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax		;bx = regionHandle, cx = x, dx = y

	push	es
	call	MemLock
	mov		es, ax
	call	GrRegionPathMovePen
	call	MemUnlock
	pop		es
	ret

GRREGIONPATHMOVEPEN		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GrRegionPathDrawLineTo

C DECLARATION:	extern void
			_far _pascal GrRegionPathLineTo(Handle regionHandle, sword x, sword y);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JK		3/14/24		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GRREGIONPATHDRAWLINETO	proc	far
	C_GetThreeWordArgs	bx, cx, dx,  ax		;bx = regionHandle, cx = x, dx = y

	push	es
	call	MemLock
	mov		es, ax
	call	GrRegionPathAddLineAtCP
	call	MemUnlock
	pop		es
	ret

GRREGIONPATHDRAWLINETO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C FUNCTION:	GrRegionPathDrawLineTo

C DECLARATION:	extern void
			_far _pascal GrRegionPathDrawCurve(Handle regionHandle, const Point *points);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JK		3/19/24		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GRREGIONPATHDRAWCURVETO	proc	far	
	C_GetThreeWordArgs	bx, cx, ax,  dx	;bx = regionHandle, cx = seg of points, ax = off of points
		
	push	ds
	push	bp
	mov		ds, cx
	xchg	di, ax						;ds:di addr of points
	
	call	MemLock						;get seg of region
	mov		es, ax
	clr		bp
	mov		cx, REC_BEZIER_STACK
	call	GrRegionPathAddBezierAtCP
	call	MemUnlock

	xchg	di, ax
	pop		bp
	pop		ds

	ret

GRREGIONPATHDRAWCURVETO	endp


