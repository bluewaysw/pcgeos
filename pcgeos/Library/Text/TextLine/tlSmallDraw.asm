COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tlSmallDraw.asm

AUTHOR:		John Wedgwood, Dec 26, 1991

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	12/26/91	Initial revision

DESCRIPTION:
	Drawing related code for small text objects.

	$Id: tlSmallDraw.asm,v 1.1 97/04/07 11:20:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextDrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line of text

CALLED BY:	TL_LineDraw via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		bx.cx	= Line to draw
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
SmallLineDraw	proc	near
	uses	ax, bx, cx, dx, di, es, bp
params	local	CommonDrawParameters
	.enter
	push	ax			; Save TextClearBehindFlags

	mov	ax, ss:[bp]		; ax <- LICL_vars
	mov	params.CDP_liclVars, ax	; Save it for later

	mov	di, cx			; bx.di <- line

EC <	call	ECCheckSmallLineReference				>
	;
	; We need to get the left/top position of the line.
	;
	call	SmallLineToPosition	; dx.bl <- top edge
					; cx <- left edge
	
	mov	params.CDP_drawPos.PWBF_x.WBF_int, cx
	mov	params.CDP_drawPos.PWBF_x.WBF_frac, 0

	movwbf	params.CDP_drawPos.PWBF_y, dxbl
	
	call	TL_LineToOffsetStart	; dx.ax <- start of line
	movdw	params.CDP_lineStart, dxax

	clr	params.CDP_region	; Only one region in small object

	call	SmallGetLinePointer	; es:di <- ptr to element
					; *ds:ax <- chunk array
					; cx <- size of line/field data
	
	pop	ax			; Restore TextClearBehindFlags
	;
	; *ds:si= Instance ptr
	; es:di	= Line
	; cx	= Size of line/field data
	; ss:bp	= CommonDrawParameters
	; ax	= TextClearBehindFlags
	;
	call	CommonLineDraw
	.leave
	ret
SmallLineDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SmallLineDrawLastNChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the last <dx> characters in a line

CALLED BY:	TL_LineDrawLastNChars via CallLineHandler
PASS:		*ds:si	= Instance ptr
		ss:bp	= LICL_vars
		ss:bx	= LICL_vars w/ these set:
				LICL_firstLine*
				LICL_region
		cx	= Number of characters to draw
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
SmallLineDrawLastNChars	proc	near
	uses	cx, dx, di, bp, es
params	local	CommonDrawParameters
	.enter
ForceRef	params

	mov	dx, cx				; dx <- # of characters to draw
	;
	; We need to get the left/top position of the line.
	;
	push	bx				; Save frame ptr
	mov	di, ss:[bx].LICL_firstLine.low	; bx.di <- line to draw
	mov	bx, ss:[bx].LICL_firstLine.high
	call	SmallGetLinePointer		; es:di <- ptr to line
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
	; dx	= Number of characters to draw
	; ss:bp	= CommonDrawParameters
	;
	call	CommonLineDrawLastNChars
	.leave
	ret
SmallLineDrawLastNChars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommonDrawLastNCharsSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do setup common to Small/LargeLineDrawLastNChars

CALLED BY:	Small/LargeLineDrawLastNChars
PASS:		ss:bx	= LICL_vars
		ss:bp	= Inheritable stack frame
RETURN:		Stack frame set up
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CommonDrawLastNCharsSetup	proc	near
	uses	ax
	.enter	inherit	SmallLineDrawLastNChars
	
	mov	params.CDP_liclVars, bx			; Save LICL_vars ptr
	
;	ceilwbf	ss:[bx].LICL_firstLineTop, ax		; ax <- top edge
;	mov	params.CDP_drawPos.PWBF_y.WBF_int, ax	; Save top edge
;	mov	params.CDP_drawPos.PWBF_y.WBF_frac, 0
;
;CommonLineDrawLastNChars takes a WBF, there is no need to round the value
; at all...
;

	movwbf	params.CDP_drawPos.PWBF_y, ss:[bx].LICL_firstLineTop, ax

	CommonLineGetAdjustment				; ax <- left edge
	mov	params.CDP_drawPos.PWBF_x.WBF_int, ax	; Save left edge
	mov	params.CDP_drawPos.PWBF_x.WBF_frac, 0

	movdw	params.CDP_lineStart, ss:[bx].LICL_firstLineStartOffset, ax
	
	mov	ax, ss:[bx].LICL_firstLineRegion
	mov	params.CDP_region, ax
	.leave
	ret
CommonDrawLastNCharsSetup	endp

TextDrawCode	ends
