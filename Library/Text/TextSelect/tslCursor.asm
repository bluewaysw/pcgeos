COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		tslCursor.asm

AUTHOR:		John Wedgwood, Oct  6, 1989

ROUTINES:
	Name				Description
	----				-----------
	CursorToggle			Toggle the cursor on the screen
	Clr_AX_WinTransform	Translate a Y position
	CursorEnable			Enable the cursor for drawing
	EnableDisableCommon		Common enable/disable code
	CursorDisable			Enable the cursor
	VisTextFlashCursorOn		Flash the cursor on
	CursorForceOn			Force cursor to an <on> state
	CursorDrawIfOn			Draw the cursor if it is on
	CursorPosition			Position the cursor in the object
	CursorPositionX			Set the x position of the cursor
	TextNearestCoord		Compute position from event position

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 6/89		Initial revision

DESCRIPTION:
	Cursor handling routines.

	Drawing of the cursor is controlled by two flags: VTISF_CURSOR_ENABLED
	and VTISF_CURSOR_ON.

	VTISF_CURSOR_ENABLED - Set if the cursor can be drawn.  Used to
			      temporarily disable the cursor
	VTISF_CURSOR_ON - Used by the blinking code to turn the cursor.

	$Id: tslCursor.asm,v 1.1 97/04/07 11:20:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFixed segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CursorToggle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle the cursor on the screen, calling the specific UI
		to get the cursor region.

CALLED BY:	CursorEnable, CursorDisable, VisTextFlashCursorOff,
		CursorForceOn, CursorDrawIfOn

PASS:		*ds:si = Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CursorToggle	proc	far
	class	VisTextClass
	uses	ax, bx, cx, dx, di, si, bp, ds
	.enter

;
; This should be done before calling this routine because typically, this
; routine is called after changing some state variables and the cursor isn't
; actually toggled because the object isn't editable then the state
; variables will be wrong.  --JimG 2/10/95
;
; NOTE: There is one routine to do this now, TextCheckCanDrawEditable
;
;	call	TextCheckCanDraw
;	LONG jc	quit
;
;	call	CheckNotEditable		; ds:di <- Instance ptr
;	jc	quit				; Quit if not editable
;

	mov	ax, ATTR_VIS_TEXT_NO_CURSOR	
	call	ObjVarFindData
	LONG jc	quit
		
	call	TextFixed_DerefVis_DI

	;
	; We need to translage the gstate so that the cursor can be drawn
	; relative to the current region.
	;
	clr	dl				; No DrawFlags
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- region
	call	TR_RegionTransformGState	; Do the transformation

	mov	ax, ds:[di].VTI_cursorPos.P_x
	mov	dx, ds:[di].VTI_cursorPos.P_y
	call	SelectGetCursorLineBLO		; ax <- baseline

	mov	bx, ds:[di].VTI_cursorPos.P_y	; bx <- Y position to move to

	;
	; Added  2/24/93 -jw
	;   This accounts for the fact that we store the cursor position as
	; one point below the top of the line, but we don't really want to
	; draw it there. See corresponding fix in TSL_CursorPosition.
	;
	dec	bx

	add	bx, ax

	mov	ax, ds:[di].VTI_cursorPos.P_x	; ax <- X position to move to

	; If we are at the right edge of the object then move right one

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jnz	afterRightSideCorrection
	mov	cx, ds:[di].VI_bounds.R_right
	sub	cx, ds:[di].VI_bounds.R_left
	clr	dx
	mov	dl, ds:[di].VTI_lrMargin
	shl	dx
	sub	cx, dx

	dec	cx
	cmp	ax, cx
	jbe	afterRightSideCorrection
	mov_tr	ax, cx
afterRightSideCorrection:

	;
	; get character attributes and set them
	;
	sub	sp, size VisTextCharAttr
	mov	bp, sp

if SIMPLE_RTL_SUPPORT
	test	ds:[di].VTI_features, mask VTF_RIGHT_TO_LEFT
	jz	noRTL

	push	ax, bx
	call	TSL_SelectGetSelection		;dx.ax <- selection start
						;cx.bx <- selection end

	mov	cl, GSFPT_INSERTION
	call	TA_GetCharAttrForPosition

	mov	cx, ds:[di].VTI_cursorRegion	; cx <- region
	mov	bx, ss:[bp].VTCA_pointSize.WBF_int
	mov	dx, ds:[di].VTI_cursorPos.P_y
	call	TR_RegionLeftRight
	add	ax, bx
	mov	cx, ax
	pop	ax, bx

	; Flip the X position
	neg	ax
	add	ax, cx
	dec	ax
	mov	di, ds:[di].VTI_gstate
	call	GrMoveTo
	jmp	didRTL
noRTL:
endif
	mov	di, ds:[di].VTI_gstate
	call	GrMoveTo

	call	TSL_SelectGetSelection		;dx.ax <- selection start
						;cx.bx <- selection end

	mov	cl, GSFPT_INSERTION
	call	TA_GetCharAttrForPosition

if SIMPLE_RTL_SUPPORT
didRTL:	
endif
	mov	dx, ss:[bp].VTCA_pointSize.WBF_int
	mov	ah, ss:[bp].VTCA_pointSize.WBF_frac
	mov	cx, ss:[bp].VTCA_fontID
	call	GrSetFont				;set the font

	mov	al, ss:[bp].VTCA_textStyles		;bits to set
	mov	ah, al
	not	ah					;bits to clear
	call	GrSetTextStyle

	add	sp, size VisTextCharAttr

	clr	bx
	call	GeodeGetUIData		; bx = specific UI
	mov	ax, SPIR_DRAW_TEXT_CURSOR
	call	ProcGetLibraryEntry
	call	ProcCallFixedOrMovable

quit:
	.leave
	ret
CursorToggle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CursorEnable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable a cursor for drawing.

CALLED BY:	CursorPosition, CursorPositionX
PASS:		*ds:si = Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CursorEnable	proc	near
	push	ax

	mov	ah, mask VTISF_CURSOR_ENABLED		;desired state

	FALL_THRU	EnableDisableCommon, ax

CursorEnable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableDisableCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for enabling or disabling the cursor.

CALLED BY:	CursorEnable, CursorDisable
PASS:		*ds:si	= Instance ptr
		ah	= Desired state flags
		On stack:	Old value for ax
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableDisableCommon	proc	near
	class	VisTextClass

	push	di
	call	TextFixed_DerefVis_DI
	mov	al, ds:[di].VTI_intSelFlags

	; if the cursor is already in the desired state then exit

	and	al, mask VTISF_CURSOR_ENABLED
	cmp	al, ah
	jz	done

	; change state

	xor	ds:[di].VTI_intSelFlags, mask VTISF_CURSOR_ENABLED

	test	ds:[di].VTI_intSelFlags, mask VTISF_CURSOR_ON
	jz	done

	push	ax, bx
	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	pop	ax, bx
	jc	ignoreFocus

	;
	; No changes are allowed to the cursor when the object
	; is not the focus.
	;
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	done

ignoreFocus:
	; Make sure it is okay to draw the cursor.
	call	TextCheckCanDrawEditable	; ds:di = instance pointer
	jc	done

	call	CursorToggle

done:
	pop	di
	FALL_THRU_POP	ax
	ret

EnableDisableCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CursorDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable a cursor.

CALLED BY:	CursorPosition, EditUnHilite
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CursorDisable	proc	near
	class	VisTextClass

	push	ax
	clr	ax				;desired state
	GOTO	EnableDisableCommon, ax

CursorDisable	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CursorForceOn

DESCRIPTION:	Force the flashing cursor to the "on" state

CALLED BY:	DeleteRange, PositionCursorSkipUpdate, HiliteAndShowSelection,
		VisTextLostFocusExcl, VisTextStartSelect

PASS:
	dx - method
	*ds:si - object

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

CursorForceOn	proc	far		uses ax, di
	class	VisTextClass
	.enter

	; if not realized then we're off the screen and this method just
	; got left around so don't do anything (and we were called from
	; VisTextFlashCursorOn).  Also ensures that we are editable.
	;
	call	TextCheckCanDrawEditable	; ds:di = instance pointer
	jc	done

	mov	al, ds:[di].VTI_intSelFlags

	or	ds:[di].VTI_intFlags, mask VTIF_HILITED

	; if already on then no toggle

	test	al, mask VTISF_CURSOR_ON
	jnz	done

	ornf	al, mask VTISF_CURSOR_ON
	mov	ds:[di].VTI_intSelFlags, al

	; if enabled then toggle the cursor

	test	al, mask VTISF_CURSOR_ENABLED
	jz	done

	push	ax
	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	pop	ax
	jc	toggle
	;
	; No changes are allowed to the cursor when the object
	; is not the focus.
	;
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	done

toggle:
	push	ax
	call	CursorToggle
	pop	ax
done:

	.leave
	ret

CursorForceOn	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TSL_CursorDrawIfOn

DESCRIPTION:	Draw the cursor if it is on.

CALLED BY:	VisTextDraw

PASS:
	*ds:si - object

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

TSL_CursorDrawIfOn	proc	far		uses ax, di
	class	VisTextClass
	.enter

	call	TextCheckCanDrawEditable	; ds:di = instance pointer
	jc	done
	
	mov	al, ds:[di].VTI_intSelFlags

	; if on then draw it.

	test	al, mask VTISF_CURSOR_ON
	jz	done

	; if enabled then toggle the cursor

	test	al, mask VTISF_CURSOR_ENABLED
	jz	done

	push	ax
	mov	ax, ATTR_VIS_TEXT_CURSOR_NO_FOCUS
	call	ObjVarFindData
	pop	ax
	jc	turnOn

	;
	; No changes are allowed to the cursor when the object
	; is not the focus.
	;
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	done
turnOn:
	call	CursorToggle
done:

	.leave
	ret

TSL_CursorDrawIfOn	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_CursorPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the cursor at a given point in a window.

CALLED BY:	UTILITY
PASS:		*ds:si	= Instance ptr
		cx	= New cursor region
		ax	= New x position for cursor
		dx	= New y position for cursor
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	5/ 2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_CursorPosition	proc	far
	class	VisTextClass
	uses	ax, dx, di
	.enter
	call	CursorDisable			; Turn off old cursor

	call	TextFixed_DerefVis_DI
	or	ds:[di].VTI_intFlags, mask VTIF_HILITED
	mov	ds:[di].VTI_cursorPos.P_x, ax	; Save new x
	
	;
	; Check for changing regions
	;
	cmp	cx, ds:[di].VTI_cursorRegion
	jne	notifyCursorRegionChanged

continue:
	mov	ds:[di].VTI_cursorRegion, cx	; Save new region

	;
	; Added  2/24/93 -jw
	;  If the top of the line is at a fractional position, we tend to
	; round the position down yielding an offset that falls in the
	; previous line. This should force the position to be in the line
	; that actually contains the cursor (since no line will be less than
	; one point tall).
	;
	inc	dx
	mov	ds:[di].VTI_cursorPos.P_y, dx	; Save new y position

	call	EnsureCursorXPositionInRegion	; Force X position legal.

	call	CursorEnable			; Update cursor image
	.leave
	ret


notifyCursorRegionChanged:
	;
	; Cursor has changed regions. Notify someone.
	;
	push	ax, cx, dx, bp
EC <	call	T_AssertIsVisLargeText					>
	mov	ax, MSG_VIS_LARGE_TEXT_CURRENT_REGION_CHANGED
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx, bp
	jmp	continue
TSL_CursorPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_CursorPositionX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the X position of the cursor.

CALLED BY:	VisTextReplaceSelection
PASS:		*ds:si	= Instance ptr
		bx	= new x position in cursor-region
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_CursorPositionX	proc	far	uses di
	class	VisTextClass
	.enter

	call	TextCheckCanDraw
	jc	quit

	call	TextFixed_DerefVis_DI
	ornf	ds:[di].VTI_intFlags, mask VTIF_HILITED

	mov	ds:[di].VTI_cursorPos.P_x, bx	; Save new x position.
	call	EnsureCursorXPositionInRegion	; Force X position legal.
	call	CursorEnable			; Draw cursor.
	call	TSL_DrawOverstrikeModeHilite	; Draw hilite.
quit:
	.leave
	ret
TSL_CursorPositionX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureCursorXPositionInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that the X position of the cursor is lega.

CALLED BY:	TSL_CursorPosition, TSL_CursorPosition
PASS:		*ds:si	= Instance
		ds:di	= Instance
			VTI_cursorPos set
			VTI_cursorRegion set
RETURN:		VTI_cursorPos.P_x modified to be legal
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 8/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureCursorXPositionInRegion	proc	near
	class	VisTextClass
	uses	ax, bx, cx, dx
	.enter
	;
	; One line objects are allowed to have the cursor beyond their edges...
	;
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jnz	gotCursorPos			; Branch if one line

	push	di				; Save instance ptr
	call	TSL_GetCursorLine		; bx.di <- line
	call	TL_LineGetHeight		; dx.bl <- line height
	ceilwbf	dxbl, bx			; bx <- line height
	pop	di				; Restore instance ptr

	;
	; bx	= Height of line containing cursor
	; ds:di	= Instance
	;
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- region
	mov	dx, ds:[di].VTI_cursorPos.P_y	; dx <- Y position

	;
	; Added  2/24/93 -jw
	;   See the corresponding fixes in CursorToggle and TSL_CursorPosition
	;
	dec	dx
						; bx == Height of line
	call	TR_RegionLeftRight		; ax <- left edge
						; bx <- right edge
	dec	bx				; Account for cursor thickness

	cmp	ds:[di].VTI_cursorPos.P_x, bx	; Check for beyond right edge
	jbe	gotCursorPos
	mov	ds:[di].VTI_cursorPos.P_x, bx
gotCursorPos:
	.leave
	ret
EnsureCursorXPositionInRegion	endp


TextFixed ends
