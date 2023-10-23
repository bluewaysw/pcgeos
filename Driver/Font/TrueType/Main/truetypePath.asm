COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
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

	push 	ax					;pass gstate handle
	mov		ch, 0
	push 	cx					;pass FontGenPathFlags
	push	dx					;pass characters code

	mov 	bx, ax
	call 	MemLock				;lock gstate block
	mov		es, ax				;es <- seg addr of gstate		
	mov		cx, es:GS_fontAttr.FCA_fontID
	clr		ah		                   
	mov		al, es:GS_fontAttr.FCA_textStyle

	call	FontDrFindFontInfo
	push	ds					;pass ptr to FontInfo
	push	di

	mov		cx, ds				;save ptr to FontInfo
	mov		dx, di

	mov		si, bx				;si <-> handle of GState
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
	call	MemUnlock			;unlock gstate block

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
	uses	ax, bx, ds, es
	.enter

	push 	di					;pass gstate handle
	push	cx					;pass regionpath handle
	push	dx					;pass character code	
	clr		al
	mov 	es, di				;es <- seg addr of gstate
	movwbf	dxah, es:GS_fontAttr.FCA_pointsize
	push	dx					;pass point size
	push 	ax		

	mov		cx, es:GS_fontAttr.FCA_fontID
	call	FontDrFindFontInfo
	push	ds					;pass ptr to FontInfo
	push	di

	clr		ah		                   
	mov		al, es:GS_fontAttr.FCA_textStyle
	mov		bx, ODF_HEADER
	call	FontDrFindOutlineData
	push	ds					;pass ptr to OutlineEntry
	push	di

	segmov	ds, dgroup, ax
	push	ds:variableHandle	;pass handle to truetype block
	call	TRUETYPE_GEN_IN_REGION

	.leave
	ret
TrueTypeGenInRegion	endp


