COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlLargeDraw.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Drawing related code for large text objects.

	$Id: tlLargeDraw.asm,v 1.1 97/04/07 11:20:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line of text

CALLED BY:	TL_LineDraw via CallLineHandler
PASS:		*ds:si	= Instance ptr
		bx.cx	= Line to draw
		ax	= TextClearBehindFlags
		ss:bp	= LICL_vars
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	   If the TCBF_PRINT bit is *clear* (not printing) then line is
	   marked as no longer needing to be drawn

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineDraw	proc	near
	uses	ax, bx, cx, dx, di, es, bp
params	local	CommonDrawParameters
ForceRef	params
	.enter
	call	LargeLineCommonDrawSetup

	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; ss:bp	= CommonDrawParameters
	; ax	= TextClearBehindFlags
	;
	call	CommonLineDraw

	call	LargeReleaseLineBlock	; Release the line block
	.leave
	ret
LargeLineDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineCommonDrawSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do common setup for LargeLineDraw and LargeLineDrawBreakIfAny

CALLED BY:	LargeLineDraw, LargeLineDrawBreakIfAny
PASS:		*ds:si	= Instance
		ss:bp	= Inheritable CommonDrawParameters
RETURN:		es:di	= Line
		cx	= Size of line/field data
		CommonDrawParameters filled in
DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineCommonDrawSetup	proc	near
	uses	ax
params	local	CommonDrawParameters
	.enter	inherit
	mov	ax, ss:[bp]		; ax <- LICL_vars
	mov	params.CDP_liclVars, ax	; Save it for later

	pushdw	bxcx			; Save line

	mov	di, cx			; bx.di <- line
	call	TR_RegionFromLine	; cx <- region
	mov	params.CDP_region, cx

	;
	; We need to get the left/top position of the line.
	;
	mov	cx, di			; bx.cx <- line (again)
	call	LargeLineGetTopLeftAndStart

	;
	; dx.bl	= Top edge
	; ax	= Left edge
	; di.cx	= Start of line
	;
	; Set the positions to draw at in the parameter block
	;
	mov	params.CDP_drawPos.PWBF_x.WBF_int, ax
	mov	params.CDP_drawPos.PWBF_x.WBF_frac, 0

	movwbf	params.CDP_drawPos.PWBF_y, dxbl

	movdw	params.CDP_lineStart, dicx

	popdw	bxdi			; bx.di <- line
	call	LargeGetLinePointer	; es:di <- ptr to element
					; cx <- size of line/field data
	.leave
	ret
LargeLineCommonDrawSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LargeLineDrawLastNChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw last <dx> characters of a line of text

CALLED BY:	TL_LineDrawLastNChars via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= LICL_vars w/ these set:
				LICL_firstLine*
				LICL_region
		cx	= Number of characters to draw at end
		ax	= TextClearBehindFlags
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	   If the TCBF_PRINT bit is *clear* (not printing) then line is
	   marked as no longer needing to be drawn

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LargeLineDrawLastNChars	proc	near
	uses	cx, dx, di, bp, es
params	local	CommonDrawParameters
	.enter
ForceRef	params

	mov	dx, cx				; dx <- # of characters to draw

	push	bx				; Save frame ptr
	mov	di, ss:[bx].LICL_firstLine.low	; bx.di <- line to draw
	mov	bx, ss:[bx].LICL_firstLine.high
	call	LargeGetLinePointer		; es:di <- ptr to line
						; cx <- size of line/field data
	pop	bx				; Restore frame ptr

	;
	; es:di	= Line
	; cx	= Size of line data
	; dx	= Number of characters to draw
	; ss:bx	= LICL_vars
	;
	; Initialize the CommonDrawParameters from the LICL_vars.
	; We need to set:
	;	Y pos = Top edge
	;	X pos = Left edge
	;	Line start
	;
	call	CommonDrawLastNCharsSetup

	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; ss:bp	= CommonDrawParameters
	; dx	= Number of chars to draw
	;
	call	CommonLineDrawLastNChars	; Do the drawing

	call	LargeReleaseLineBlock		; Release the line block
	.leave
	ret
LargeLineDrawLastNChars	endp

TextDrawCode	ends
