COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tslInvert.asm

AUTHOR:		John Wedgwood, Apr 17, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/17/92	Initial revision

DESCRIPTION:
	Code for inverting the selected range...

	$Id: tslInvert.asm,v 1.1 97/04/07 11:20:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditHilite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hilite the selected area using the appropriate hiliting
		scheme.

CALLED BY:	UTILITY
PASS:		ds:*si = ptr to the instance.
RETURN:		Area between start and end of selection hilited.
DESTROYED:	nothing

CASES:
	Is target && focus:
		Invert selected area or draw cursor.
	Is target && not focus:
		Invert with non-focus/target mask or draw non-focus cursor.
	Is not target && focus:
		Invert with focus/non-target mask or draw cursor.
	Is not target && not focus:
		Invert with non-focus/non-target mask or draw non-focus cursor.


PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditHilite	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter
	call	TextCheckCanDraw		; Quit if we can't draw.
	jc	quit

	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr.

	test	ds:[di].VTI_intFlags, mask VTIF_HILITED
	jnz	quit				; Quit if already hilited.
	or	ds:[di].VTI_intFlags, mask VTIF_HILITED

	; Mark the cuursor as disabled.  If the selection is actually a
	; cursor, TSL_CursorPosition will re-enable it

	andnf	ds:[di].VTI_intSelFlags, not mask VTISF_CURSOR_ENABLED

	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jnc	cursor				; Branch if is cursor.
	call	TSL_DrawHilite
	jmp	quit
cursor:
	call	TSL_ConvertOffsetToRegionAndCoordinate
						; cx <- x position
						; dx <- y position
						; ax <- region
	xchg	ax, cx				; cx <- region
						; ax <- x position
	add	ax, ds:[di].VTI_leftOffset	; Account for left-offset
	call	TSL_CursorPosition		; Position it...

	; Now if we are in replace mode we also want to draw the 'hilite'
	; portion of the cursor.

	call	TSL_DrawOverstrikeModeHilite
quit:
	.leave
	ret
EditHilite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_DrawHilite		This is a no-bozo routine.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the hiliting.

CALLED BY:	EditHilite, EditUnHilite, VisTextDraw
PASS:		ds:*si	= instance ptr.
		dx.ax	= Start of range to invert
		cx.bx	= End of range to invert
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Be sure that when you call this that there is some selection.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_DrawHilite	proc	far
	uses	cx, dx, di
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr.

	call	TextSetDrawMask			; Make an appropriate mask.
	jc	done
	call	InvertRange
	call	TextSetSolidMask		; Restore the mask.
done:

	.leave
	ret
TSL_DrawHilite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSetDrawMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a draw mask appropriate for hiliting.

CALLED BY:	DrawHilite, DrawOverstrikeModeHilite
PASS:		ds:di = pointer to instance.
RETURN:		carry - set if no highlight needed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSetDrawMask	proc	far
	class	VisTextClass

	push	ax

	push	bx
	mov	ax, TEMP_VIS_TEXT_SYS_TARGET
	call	ObjVarFindData
	pop	bx
	jnc	notTarget

	; IS TARGET

	mov	al, TEXT_IS_TARGET_IS_FOCUS_MASK
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jnz	gotMask

	mov	al, TEXT_IS_TARGET_NOT_FOCUS_MASK
	jmp	gotMask

notTarget:

	mov	al, TEXT_NOT_TARGET_IS_FOCUS_MASK

	push	ax, bx
	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	pop	ax, bx
	jc	gotMask

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jnz	gotMask

	mov	al, TEXT_NOT_TARGET_NOT_FOCUS_MASK

gotMask:
	cmp	al, SDM_0
	jnz	setMask
	pop	ax
	stc
	ret
setMask:
	FALL_THRU	SetMaskCommon, ax

TextSetDrawMask	endp

SetMaskCommon	proc	far
	class	VisTextClass

	push	di
	mov	di, ds:[di].VTI_gstate
	call	GrSetAreaMask
	pop	di
	FALL_THRU_POP	ax
	clc
	ret
SetMaskCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSetSolidMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the mask for the cached gstate to solid.

CALLED BY:	DrawHilite, DrawOverstrikeModeHilite
PASS:		ds:di = pointer to instance.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSetSolidMask	proc	far
	push	ax
	mov	al, SDM_100
	GOTO	SetMaskCommon, ax

TextSetSolidMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_DrawOverstrikeModeHilite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the hilite associated with replace mode.

CALLED BY:	CursorPositionX, EditHilite, EditUnHilite,
		PositionCursorSkipUpdate, VisTextDraw, VisTextStartSelect

PASS:		ds:*si	= instance ptr.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_DrawOverstrikeModeHilite	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di, bp
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr.
	test	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	jz	done				; Quit if not in replace mode.

	;
	; Assume that we are drawing a cursor.
	;
	call	SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end

	incdw	cxbx				; Advance end of selection
	movdw	dibp, dxax			; Save select start

	call	TS_GetTextSize			; dx.ax <- text size total.
	cmpdw	cxbx, dxax			; Check end of range
	ja	done				; Branch if nothing to invert

	movdw	dxax, dibp			; Restore dx.ax as select start

	;
	; Invert the next character.
	;
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr.
	call	TextSetDrawMask			; Set appropriate mask.
	jc	done
	call	InvertRange			; Invert next character.
	call	TextSetSolidMask		; Reset to solid mask.

done:
	.leave
	ret
TSL_DrawOverstrikeModeHilite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditUnHilite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Un-hilite the selected area.

CALLED BY:	UTILITY
PASS:		ds:*si = ptr to the instance.
RETURN:		Area between start and end of selection un-hilited.
DESTROYED:	nothing

CASES:
	Is target && focus:
		Invert selected area or erase cursor.
	Is target && not focus:
		Invert with non-focus/target mask or erase non-focus cursor.
	Is not target && focus:
		Invert with focus/non-target mask or erase cursor.
	Is not target && not focus:
		Invert with non-focus/non-target mask or erase non-focus cursor

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EditUnHilite	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di
	.enter

	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr.
	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jnz	10$
	test	ds:[di].VTI_intFlags, mask VTIF_HILITED
	jz	quit			; Quit if already unhilited
	and	ds:[di].VTI_intFlags, not mask VTIF_HILITED
10$:

	call	TextCheckCanDraw
	jc	quit			; quit if not realized.

	call	SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jnc	cursor				; nuke cursor if same.
	call	TSL_DrawHilite
	jmp	quit
cursor:
	call	CursorDisable

	; If we are in replace mode, turn off the hilite.

	call	TSL_DrawOverstrikeModeHilite
quit:
	.leave
	ret
EditUnHilite	endp



TextFixed	ends
