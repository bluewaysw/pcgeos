COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		tslMain.asm

AUTHOR:		John Wedgwood, Oct  6, 1989

ROUTINES:
	Name			Description
	----			-----------
	TSL_SelectGetSelection
	TSL_SelectGetSelectionStart
	TSL_SelectGetSelectionEnd
	TSL_SelectIsCursor
	TSL_SelectGetCursorCoord
	TSL_SelectSetSelection

	SelectGetCursorLineBLO
	SelectGetSelection
	SelectIsCursor
	SelectGetSelectionStart
	SelectSetStartEnd
	SelectGetAdjustPosition
	SelectGetFixedPosition

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/6/89		Initial revision

DESCRIPTION:
	Routines to handle selection in a text object.

	$Id: tslMain.asm,v 1.1 97/04/07 11:20:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_SelectGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection range.

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
RETURN:		dx.ax	= Selection start
		cx.bx	= Selection end
		carry set if selection is a range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_SelectGetSelection	proc	far
	call	SelectGetSelection
	ret
TSL_SelectGetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_SelectGetSelectionStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the start of the selection.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
RETURN:		dx.ax	= selection start
		carry set if selection is a range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_SelectGetSelectionStart	proc	far
	call	SelectGetSelectionStart	; dx.ax <- start of selection
	call	SelectIsCursor		; carry clear if it is a range
	cmc				; carry set if it is a range
	ret
TSL_SelectGetSelectionStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_SelectGetSelectionEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the end of the selection.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
RETURN:		dx.ax	= selection end
		carry set if selection is a range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_SelectGetSelectionEnd	proc	far
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI
	movdw	dxax, ds:[di].VTI_selectEnd	; dxax <- end of selection
	call	SelectIsCursor			; carry clear if it is a range
	cmc					; carry set if it is a range
	.leave
	ret
TSL_SelectGetSelectionEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_SelectIsCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out if the current selection is a cursor

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
RETURN:		carry set if the selection is a cursor
		carry clear otherwise
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_SelectIsCursor	proc	far
	call	SelectIsCursor
	ret
TSL_SelectIsCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectGetCursorLineBLO
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the blo of the line where the cursor is.

CALLED BY:	CursorPosition
PASS:		*ds:si	= Instance ptr
		ax	= X position of the cursor
		dx	= Y position of the cursor
		cx	= Cursor region
RETURN:		ax	= Baseline-offset of the line
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectGetCursorLineBLO	proc	far
	uses	bx, cx, dx, di
	.enter
	call	TL_LineFromPosition	; bx.di <- line cursor is on
	call	TL_LineGetBLO		; dx.bl <- baseline offset
	mov_tr	ax, dx			; Return value in ax
	.leave
	ret
SelectGetCursorLineBLO	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_SelectGetCursorCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the cursor position.

CALLED BY:	VisTextNotifyGeometryValid(2)
PASS:		*ds:si	= Instance ptr
RETURN:		cx	= Cursor region
		ax	= X position (region relative)
		dx	= Y position (region relative)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_SelectGetCursorCoord	proc	far
	class	VisTextClass
	uses	bx, di
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- Instance
	
	;
	; Get the top-left of the cursor region
	;
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- cursor region
	
	;
	; Get the coordinate of the cursors text offset
	;
	call	SelectGetSelectionStart		; dx.ax <- selectStart
	call	TSL_ConvertOffsetToRegionAndCoordinate
						; cx <- x position
						; dx <- y position
						; ax <- region

	mov	ax, ds:[di].VTI_cursorRegion	; ax <- cursor region
	xchg	ax, cx				; ax <- x position
						; cx <- cursor region
	.leave
	ret
TSL_SelectGetCursorCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selected range.

CALLED BY:	UTILITY
PASS:		*ds:si	= instance ptr.
RETURN:		dx.ax	= Select start
		cx.bx	= Select end
		carry set if selection is a range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectGetSelection	proc	near
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI
	movdw	dxax, ds:[di].VTI_selectStart	; dx.ax <- start of selection
	movdw	cxbx, ds:[di].VTI_selectEnd	; cx.bx <- end of selection

	call	SelectIsCursor			; Carry clear if a range
	cmc					; Carry set if a range
	.leave
	ret
SelectGetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	TSL_SelectSetSelection, TSL_SelectSetSelectionWithoutNukingUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selection.

CALLED BY:	UTILITY
PASS:		*ds:si	= instance ptr.
		dx.ax	= Selection start
		cx.bx	= Selection end
RETURN:		zero clear (nz) if start-select is different
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/ 6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_SelectSetSelection	proc	far	uses	di, bp
	class	VisTextClass
	.enter
	call   	TU_NukeCachedUndo
	mov	bp, -1			;Set BP non-zero if selection is
					; changing
	call	TextFixed_DerefVis_DI
	cmpdw	ds:[di].VTI_selectEnd, cxbx
	jnz	isDifferent
	cmpdw	ds:[di].VTI_selectStart, dxax
	jnz	isDifferent
	clr	bp
isDifferent:
	call	TSL_SelectSetSelectionWithoutNukingUndo
	pushf				;Save zero flag
	tst	bp			;If no change, branch
	jz	popExit
	call	T_CheckIfContextUpdateDesired
	jz	popExit
	call	SendSelectionContext
popExit:
	popf
	.leave
	ret
TSL_SelectSetSelection	endp

TSL_SelectSetSelectionWithoutNukingUndo	proc	far	uses	di
	class	VisTextClass
	.enter
	call	TextFixed_DerefVis_DI
	movdw	ds:[di].VTI_selectEnd, cxbx

	;
	; Compare start-select
	;
	cmpdw	ds:[di].VTI_selectStart, dxax
	je	quit				; Branch if same
	movdw	ds:[di].VTI_selectStart, dxax
quit:
	;
	; Z flag clear (nz) if the new start-select is different
	;
	.leave
	ret
TSL_SelectSetSelectionWithoutNukingUndo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectIsCursor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out if the current selection is a cursor or not.

CALLED BY:	VisTextReplace
PASS:		*ds:si	= Instance ptr
RETURN:		carry set if it is a cursor
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectIsCursor	proc	near
	class	VisTextClass
	uses	ax, dx, di
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	movdw	dxax, ds:[di].VTI_selectStart
	cmpdw	dxax, ds:[di].VTI_selectEnd
	stc
	je	quit
	
	clc					; Signal: isn't a cursor
quit:
	.leave
	ret
SelectIsCursor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectGetSelectionStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the selection start

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
RETURN:		dx.ax	= SelectStart
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectGetSelectionStart	proc	near
	class	VisTextClass
	uses	di
	.enter
	call	TextFixed_DerefVis_DI
	movdw	dxax, ds:[di].VTI_selectStart
	.leave
	ret
SelectGetSelectionStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectGetAdjustPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the adjust position

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		carry set for adjusting forward
		carry clear for adjusting backwards
RETURN:		dx.ax	= Adjust position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The adjustable position really depends on what we're doing.
	In general the selection looks like one of these:

		|yyyyyyyyyyyyyyyyyyy|xxxxxxxxxxxxx|
		|		    |		  |
	    selectStart		  minStart	minEnd, selectEnd

		|xxxxxxxxxxxxxxxxxxx|yyyyyyyyyyyyy|
		|		    |		  |
	   selectStart,minStart	  minEnd	selectEnd

	The rule in either of these cases is:
		if (selectStart == minStart)
		    adjustPos = selectEnd
		else
		    adjustPos = selectStart
		endif

	The exception is when the selection is the minimum selection.
	In that case the adjust position really depends on the direction
	which you want to adjust. 
	
	If you are adjusting forward it makes sense to use the end of the
	selection. If you are adjusting backwards it makes sense to use
	the start of the selection.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectGetAdjustPosition	proc	far
	class	VisTextClass
	uses	di
	.enter
	pushf					; Save "forward/backward" flag
	
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	movdw	dxax, ds:[di].VTI_selectStart
	
	cmpdw	dxax, ds:[di].VTI_selectMinStart
	jne	gotAdjust

	movdw	dxax, ds:[di].VTI_selectEnd
	
	cmpdw	dxax, ds:[di].VTI_selectMinEnd
	jne	gotAdjust
	
	;
	; This is the case where we need to check the forward/backward flag
	;
	popf					; carry <- f/b flag
	pushf					; Save flag again
	
	;
	; If we are adjusting forward (carry set) then we use the end of
	; the selection. We just happen to have that in dx.ax
	;
	jc	gotAdjust			; branch if going forward
	
	;
	; We are adjusting backwards. Use the selectStart
	;
	movdw	dxax, ds:[di].VTI_selectStart
	
gotAdjust:
	;
	; dx.ax	= Adjustable position.
	;
	popf					; Restore stack
	.leave
	ret
SelectGetAdjustPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectGetFixedPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the fixed position

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		carry set for adjusting forward
		carry set for adjusting backwards
RETURN:		dx.ax	= fixed position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectGetFixedPosition	proc	far
	class	VisTextClass
	uses	bx, cx, di
	.enter
	call	SelectGetAdjustPosition		; dx.ax <- adjustable position
	movdw	cxbx, dxax			; cx.bx <- adjustable position

	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr
	movdw	dxax, ds:[di].VTI_selectStart

	cmpdw	dxax, cxbx			; Check for start == adjust
	jne	gotPosition			; Branch if not
	movdw	dxax, ds:[di].VTI_selectEnd
gotPosition:
	.leave
	ret
SelectGetFixedPosition	endp

TextFixed ends
