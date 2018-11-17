COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetHeaderFooter.asm

AUTHOR:		John Wedgwood, May  6, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 5/ 6/91	Initial revision

DESCRIPTION:
	Code to implement header/footer stuff.

	$Id: spreadsheetHeaderFooter.asm,v 1.1 97/04/07 11:14:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HeaderFooterCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetSetHeaderRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the header/footer range.

CALLED BY:	via MSG_SPREADSHEET_SET_HEADER_RANGE or
		    MSG_SPREADSHEET_SET_FOOTER_RANGE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
		ax	= Method

		dx = 0 if we want to use the currently selected range
		dx = non-zero to remove the header completely
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetSetHeaderRange	method	SpreadsheetClass,
				MSG_SPREADSHEET_SET_HEADER_RANGE,
				MSG_SPREADSHEET_SET_FOOTER_RANGE
	mov	dx, cx			; dx <- flag
	segmov	es, ds, si		; es:di <- instance ptr
	mov	si, di			; ds:si <- instance ptr
	mov	bx, offset SSI_header	; Assume header
	cmp	ax, MSG_SPREADSHEET_SET_FOOTER_RANGE
	jne	gotOffset
	mov	bx, offset SSI_footer	; Use footer
gotOffset:
	add	di, bx			; es:di <- rectangle to set
	;
	; es:di = Pointer to the rectangle to set.
	; First we redraw the rectangle that was in order to remove any markings
	;
	mov	cx, di			; Save di in cx
	call	CreateGStateFar		; di <- gstate handle
	xchg	cx, di			; cx <- gstate handle
					; Restore di
	;
	; Invalidate the header/footer and redraw to remove any markings.
	;
	clr	ax			; Force erasing of the marks
	call	DrawRangePtr		; Draw range referenced by es:di

	push	ds, si, es, di, cx	; Save instance, hdr/ftr, gstate

	mov	ax, si			; es:ax <- ptr to spreadsheet instance

	;
	; Now we store the new rectangle.
	;
	;
	; Either clearing the entire header/footer or setting to the current
	; selected range.
	;
	segmov	ds, cs, si		; ds:si <- ptr to source rectangle
	mov	si, offset cs:emptyHeader
	tst	dx			; Check for clearing
	jnz	setFromRange		; Branch if clearing rectangle
	;
	; Setting to the current range.
	;
	segmov	ds, es, si		; ds:si <- ptr to source rectangle
	mov	si, ax
	add	si, offset SSI_selected
setFromRange:
	;
	; ds:si = Pointer to source CellRange
	; es:di = Pointer to destination CellRange
	;
	mov	cx, (size CellRange)/(size word)
	rep	movsw			; Copy the CellRange
	
	pop	ds, si, es, di, cx	; Restore instance, hdr/ftr, gstate
	;
	; Now redraw the rectangle with the new markings.
	;
	mov	ax, -1			; Want to draw the markings
	call	DrawRangePtr		; Draw the range again...
	
	mov	di, cx			; di <- gstate handle
	call	DestroyGStateFar	; Nuke the gstate
	
	call	SpreadsheetMakeDirty	; The spreadsheet is dirty
	;
	; Update the UI
	;
	mov	ax, mask SNF_DOC_ATTRS	; ax <- SpreadsheetNotifyFlags
	call	SS_SendNotification
	ret
SpreadsheetSetHeaderRange	endp

emptyHeader	CellRange <<-1, -1>, <-1, -1>>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRangePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a range referenced by es:di

CALLED BY:	SpreadsheetSetHeaderRange
PASS:		ds:si	= Instance ptr
		es:di	= Pointer to rectangle to draw
		cx	= GState handle
		ax	= 0 to erase any header/footer markings
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRangePtr	proc	near
	uses	ax, bx, cx, dx, di, bp
	class	SpreadsheetClass

	.enter

EC <	call	ECCheckInstancePtr		;>

	push	cx			; Save GState handle

	tst	ax			; Check for erasing hdr/ftr markings
	;
	; Set the origin for drawing to the upper left visible cell
	;
	mov	ax, es:[di].CR_start.CR_row
	mov	cx, es:[di].CR_start.CR_column
	mov	bp, es:[di].CR_end.CR_row
	mov	dx, es:[di].CR_end.CR_column
	;
	; Flags are still the same as they were when we tst'd ax above...
	;
	jnz	drawEraseRect
	mov	es:[di].CR_start.CR_row, -1	; Force erasure of the marks
drawEraseRect:
	;
	; Redraw the range
	;
	pop	di			; di <- handle of GState
	call	RedrawRange

	.leave
	ret
DrawRangePtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetHeaderRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the header/footer range.

CALLED BY:	via MSG_SPREADSHEET_GET_HEADER_RANGE,
		    MSG_SPREADSHEET_GET_FOOTER_RANGE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
		ax	= Method
RETURN:		ax/cx	= Row/Column of first cell in header/footer
		dx/bp	= Row/Column of last  cell in header/footer
		ax	= -1 indicates the header/footer is empty
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetHeaderRange	method	SpreadsheetClass,
				MSG_SPREADSHEET_GET_HEADER_RANGE,
				MSG_SPREADSHEET_GET_FOOTER_RANGE
	mov	si, di			; ds:si <- instance ptr

	mov	bx, offset SSI_header	; Assume header
	cmp	ax, MSG_SPREADSHEET_GET_FOOTER_RANGE
	jne	gotOffset
	mov	bx, offset SSI_footer	; Use footer
gotOffset:
	add	si, bx			; ds:si <- ptr to range to use
	
	mov	ax, ds:[si].R_top	; ax/cx <- Row/Column of top-left
	mov	cx, ds:[si].R_left
	mov	dx, ds:[si].R_bottom	; dx/bp <- Row/Column of bottom-right
	mov	bp, ds:[si].R_right

	ret
SpreadsheetGetHeaderRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawHeaderFooterMark
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw header or footer mark
CALLED BY:	SpreadsheetDraw()

PASS:		carry - set for header; clear for footer
		ds:si - ptr to Spreadsheet instance
		(ax,cx)
		(bx,dx) - range of cells to draw (r,c)
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Should only be called for drawing visible cells
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawHeaderFooterMark	proc	far
	uses	ax, bx, cx, dx, di
	class	SpreadsheetClass
range	local	CellRange	push	dx, bx, cx, ax
gstate	local	hptr.GState	push	di
	.enter
ForceRef range
	;
	; Set line color appropriately, and get the appropriate range
	;
	mov	di, offset SSI_header
	mov	ax, HEADER_TAB_COLOR or (CF_INDEX shl 8) ;al <- header Color
	jc	isHeader
	mov	di, offset SSI_footer
	mov	al, FOOTER_TAB_COLOR		;al <- footer Color
isHeader:
	push	di
	mov	di, ss:gstate			;di <- handle of GState
	call	GrSetLineColor
	mov	al, SDM_100			;al <- SysDrawMask
	call	GrSetLineMask
	pop	di
	add	di, si				;ds:di <- ptr to CellRange
	;
	; Restrict the left side and draw it, if necessary
	;
	mov	ax, ds:[di].CR_start.CR_row
	mov	cx, ds:[di].CR_start.CR_column
	mov	bx, ds:[di].CR_end.CR_row
	mov	dx, cx				;(ax,cx),(bx,dx) <- range
	call	RestrictToRange
	jnc	noLeft				;branch if out of range
	push	bp, di
	mov	di, ss:gstate			;di <- handle of GState
	mov	bp, bx
	call	GetRangeVisBounds16
	inc	ax				;ax <- bump in from grid
	call	GrDrawVLine
	pop	bp, di
noLeft:
	;
	; Restrict the top and draw it, if necessary
	;
	mov	ax, ds:[di].CR_start.CR_row
	mov	cx, ds:[di].CR_start.CR_column
	mov	bx, ax
	mov	dx, ds:[di].CR_end.CR_column	;(ax,cx),(bx,dx) <- range
	call	RestrictToRange
	jnc	noTop				;branch if out of range
	push	bp, di
	mov	di, ss:gstate			;di <- handle of GState
	mov	bp, bx
	call	GetRangeVisBounds16
	inc	bx				;bx <- bump in from grid
	call	GrDrawHLine
	pop	bp, di
noTop:
	;
	; Restrict the right side and draw it, if necessary
	;
	mov	ax, ds:[di].CR_start.CR_row
	mov	cx, ds:[di].CR_end.CR_column
	mov	bx, ds:[di].CR_end.CR_row
	mov	dx, cx				;(ax,cx),(bx,dx) <- range
	call	RestrictToRange
	jnc	noRight				;branch if out of range
	push	bp, di
	mov	di, ss:gstate			;di <- handle of GState
	mov	bp, bx
	call	GetRangeVisBounds16
	mov	ax, cx				;ax <- right side of cell
	dec	ax				;bx <- bump in from grid
	call	GrDrawVLine
	pop	bp, di
noRight:
	;
	; Restrict the bottom and draw it, if necessary
	;
	mov	ax, ds:[di].CR_end.CR_row
	mov	cx, ds:[di].CR_start.CR_column
	mov	bx, ax
	mov	dx, ds:[di].CR_end.CR_column	;(ax,cx),(bx,dx) <- range
	call	RestrictToRange
	jnc	noBottom			;branch if out of range
	push	bp, di
	mov	di, ss:gstate			;di <- handle of GState
	mov	bp, bx
	call	GetRangeVisBounds16
	mov	bx, dx				;bx <- bottom of cell
	dec	bx				;bx <- bump in from grid
	call	GrDrawHLine
	pop	bp, di
noBottom:
	;
	; Reset the line color
	;
	mov	di, ss:gstate			;di <- handle of GState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetLineColor

	.leave
	ret
DrawHeaderFooterMark	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestrictToRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restrict a range to the specified range
CALLED BY:	DrawHeaderFooterMark()

PASS:		ss:bp - inherited locals from DrawHeaderFooterMark()
			ss:range - range to restrict to
		(ax,cx),(bx,dx) - CellRange to restrict
RETURN:		carry - set if any part is in range
		(ax,cx),(bx,dx) - restricted range
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RestrictToRange	proc	near
	.enter	inherit	DrawHeaderFooterMark

	;
	; See if outside range completely
	;
	cmp	ax, ss:range.CR_end.CR_row
	ja	offScreen
	cmp	cx, ss:range.CR_end.CR_column
	ja	offScreen
	cmp	bx, ss:range.CR_start.CR_row
	jb	offScreen
	cmp	dx, ss:range.CR_start.CR_column
	jb	offScreen
	;
	; Restrict each side
	;
	push	di
	mov	di, ss:range.CR_start.CR_row
	cmp	ax, di				;top on screen?
	jae	topOK
	mov	ax, di				;ax <- top visible row
topOK:
	mov	di, ss:range.CR_start.CR_column
	cmp	cx, di				;left on screen?
	jae	leftOK
	mov	cx, di				;cx <- left visible column
leftOK:
	mov	di, ss:range.CR_end.CR_row
	cmp	bx, di				;bottom on screen?
	jbe	bottomOK
	mov	bx, di				;bp <- bottom visible row
bottomOK:
	mov	di, ss:range.CR_end.CR_column
	cmp	dx, di				;right on screen?
	jbe	rightOK
	mov	dx, di				;dx <- right visible column
rightOK:
	pop	di
	stc					;carry <- partially visible
done:
	.leave
	ret

offScreen:
	clc					;carry <- outside of range
	jmp	done
RestrictToRange	endp

HeaderFooterCode	ends
