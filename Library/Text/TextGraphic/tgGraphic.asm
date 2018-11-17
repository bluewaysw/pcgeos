COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text/TextGraphic
FILE:		tgGraphic.asm

METHODS:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	...

	$Id: tgGraphic.asm,v 1.1 97/04/07 11:19:35 newdeal Exp $

------------------------------------------------------------------------------@

TextGraphic segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	TG_GraphicRunSize

DESCRIPTION:	Return the bounds of a graphic element

CALLED BY:	EXTERNAL

PASS:
	*ds:si - text object
	dx.ax - position in text

RETURN:
	cx - width (0 means 0 width graphic)
	dx - height (0 to use current text height)

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
TG_GraphicRunSize	proc	far	uses di, bp
	class	VisTextClass
	.enter

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	sub	sp, size VisTextGraphic
	mov	bp, sp

	call	TA_GetGraphicForPosition		;ss:bp = graphic

	; get values to return

	mov	cx, ss:[bp].VTG_size.XYS_width
	mov	dx, ss:[bp].VTG_size.XYS_height

	; null size ?

	tst	cx
	jnz	done
	tst	dx
	jnz	done

EC <	cmp	ss:[bp].VTG_type, VTGT_VARIABLE				>
EC <	ERROR_NZ	VIS_TEXT_GRAPHIC_CANNOT_HAVE_SIZE_0		>

	push	ax, di, bp
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	cx, ds:[di].VTI_gstate
	mov	dx, ss
	mov	ax, MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE
	call	ObjCallInstanceNoLock		;ax = non-zero if handled
	pop	ax, di, bp

done:
	add	sp, size VisTextGraphic

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

TG_GraphicRunSize	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextGraphicVariableSize --
		MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE for VisTextClass

DESCRIPTION:	Default handler for finding the size of a variable graphic

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - gstate
	dx:bp - VisTextGraphic (dx always = ss)

RETURN:
	cx - width
	dx - height

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
VisTextGraphicVariableSize	proc	far ;MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE

	; send a message up to the document to try to get a string

	sub	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE
	mov	di, sp				;ss:di = buffer
	call	GetVariableString

	segmov	ds, ss
	mov	si, di				;ds:si = string
	mov	di, cx				;di = gstate
	clr	cx				;null terminated
	call	GrTextWidth
	mov	cx, dx				;cx = width
	clr	dx				;height = 0

	add	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE

	ret

VisTextGraphicVariableSize	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetVariableString

DESCRIPTION:	Get the string for a variable

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - gstate
	dx:bp - VisTextGraphic (dx always = ss)
	ss:di - buffer

RETURN:
	buffer filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
GetVariableString	proc	near	uses ax, bx, cx, dx, di, bp
	.enter

	; initialize string to default

	mov	{word} ss:[di], '#'		;'#' followed by 0
DBCS <	mov	{wchar}ss:[di][2], 0					>

	; push GenDocumentGetVariableParams on the stack

	push	ds:[LMBH_handle], si		;GDGVP_object
	pushdw	dxbp				;GDGVP_graphic
	pushdw	ssdi				;GDGVP_buffer

	; get the position of the graphic by taking:
	;	(current transform - default transform) + WinBounds (if any)

	call	CalculatePositionInSpace	;cxbx = x, dxax = y
	pushdw	dxax				;GDGVP_position.PD_y
	pushdw	cxbx				;GDGVP_position.PD_x
	mov	bp, sp

	mov	dx, size GenDocumentGetVariableParams
	mov	ax, MSG_GEN_DOCUMENT_GET_VARIABLE
	mov	di, mask MF_RECORD or mask MF_STACK
	push	si
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	call	ObjMessage				;di = message
	pop	si
	add	sp, size GenDocumentGetVariableParams

	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

	.leave
	ret

GetVariableString	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CalculatePositionInSpace

DESCRIPTION:	Calculate the current "document" position for the given
		gstate

CALLED BY:	INTERNAL

PASS:
	cx - gstate

RETURN:
	cxbx - x pos
	dxax - y pos

DESTROYED:
	di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 1/92		Initial version

------------------------------------------------------------------------------@
CalculatePositionInSpace	proc	near	uses si, ds
currentTransform	local	TransMatrix
	.enter

	mov	di, cx				;di = state
	segmov	ds, ss
	lea	si, currentTransform
	call	GrGetTransform
	call	GrGetWinHandle			;ax = window
	tst	ax

	movdw	cxbx, currentTransform.TM_e31.DWF_int
	movdw	dxax, currentTransform.TM_e32.DWF_int

	jnz	done

	; no window -- subtract the default transform

	call	GrSaveTransform
	call	GrSetDefaultTransform
	call	GrGetTransform
	call	GrRestoreTransform
	subdw	cxbx, currentTransform.TM_e31.DWF_int
	subdw	dxax, currentTransform.TM_e32.DWF_int

done:

	.leave
	ret

CalculatePositionInSpace	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TG_GraphicRunDraw

DESCRIPTION:	Draw a graphic element

CALLED BY:	EXTERNAL

PASS:
	*ds:si - text object
	bx - baseline position
	cx - line height (THIS IS NOT PASSED -- brianc 2/29/00)
	dx.ax - position in text
	di - gstate

RETURN:
	cx - width of graphic drawn
	dx - height of graphic drawn

DESTROYED:
	none

		Graphic element draw routines:
		PASS:
			*ds:si - text object
			ss:bp - VisTextGraphic
			di - gstate
		RETURN:
			none (state of the gstate can be trashed)
		DESTROY:
			ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TG_GraphicRunDraw	proc	far	uses ax, bx, si, di, bp, ds, es
	.enter

	mov	bp, di
	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di
	mov	di, bp

	push	di
	call	GrSaveState

	; Copy the text color to the line and area color to prevent the
	; "inviso-graphic" bug on black and white systems and also so that
	; graphics that do not specify a color are drawn in an appropriate
	; color

	push	ax, bx			; save position in the text.
	call	GrGetTextColor
	mov	ah, CF_RGB
	call	GrSetLineColor
	call	GrSetAreaColor
	mov	al, SDM_100
	call	GrSetAreaMask
	pop	ax, bx

	sub	sp, size VisTextGraphic
	mov	bp, sp

	call	TA_GetGraphicForPosition	;fill in ss:bp

	clr	al			; al <- bits to set, ah <- bits to clear
	mov	ah, mask TM_DRAW_BASE or \
		    mask TM_DRAW_BOTTOM or \
		    mask TM_DRAW_ACCENT or \
		    mask TM_DRAW_OPTIONAL_HYPHENS
	test	ss:[bp].VTG_flags, mask VTGF_DRAW_FROM_BASELINE
	jz	gotFlags
	mov	al, mask TM_DRAW_BASE	; al <- bits to set, ah <- bits to clear
	mov	ah, mask TM_DRAW_BOTTOM or \
		    mask TM_DRAW_ACCENT or \
		    mask TM_DRAW_OPTIONAL_HYPHENS
gotFlags:
	call	GrSetTextMode		; Clear all the TextMode bits

	; We are passed the top of the line as the position to draw.
	; We want to move to draw with the bottom above the baseline.
	; To do this we need to move the pen position down by:
	;	baseline - graphicHeight
	; bx already holds the baseline.  
	; Note:RelMoveTo now takes WWFixed values, hence the change

	push	cx, dx
	sub	bx, ss:[bp].VTG_size.XYS_height
	clr	ax
	clr	cx, dx
	call	GrRelMoveTo
	pop	cx, dx

	; draw the sucker

	push	ss:[bp].VTG_size.XYS_width, ss:[bp].VTG_size.XYS_height
	clr	bx
	mov	bl, ss:[bp].VTG_type

	shl	bx

	push	bp
	mov	ax, MSG_VIS_TEXT_GET_FEATURES
	call	ObjCallInstanceNoLock
	pop	bp

	test	cx, mask VTF_DONT_SHOW_GRAPHICS
	jz	drawGraphic

	; Draw a rectangle in place of the graphic.

	mov	ax, C_LIGHT_GRAY
	call	GrSetAreaColor
	mov	ax, C_DARK_GRAY
	call	GrSetLineColor
	pop	cx, dx			; cx, dx <- width/height.
	tst	cx
	jnz	haveSize
	;
	; get size (just send msg instead of calling TG_GraphicRunSize
	; since parameters are a bit easier to set up)
	;
	mov	cx, di			; cx = gstate
	mov	dx, ss			; dx:bp = VisTextGraphic
	mov	ax, MSG_VIS_TEXT_GRAPHIC_VARIABLE_SIZE
	call	ObjCallInstanceNoLock	; cx, dx = size
haveSize:
	push	cx, dx
	call	GrGetCurPos
	add	cx, ax
	add	dx, bx
	dec	cx
	dec	dx
	call	GrFillRect		; Fill me a rectangle.
	call	GrDrawRect		; Fill me a rectangle.
	jmp	done

drawGraphic:
	call	cs:[bx][GraphElementDrawRoutines]

done:
	pop	ax, bx			; ax, bx <- width, height.
	tst	ax
	jz	useReturnValues
	mov_tr	cx, ax
	mov	dx, bx
useReturnValues:
	add	sp, size VisTextGraphic

	pop	di
	call	GrRestoreState

	pop	di
	call	ThreadReturnStackSpace

	.leave
	ret

TG_GraphicRunDraw	endp

GraphElementDrawRoutines	label	word
	word	offset DrawGraphicGString
	word	offset DrawGraphicVariable

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawGraphicGString

DESCRIPTION:	Draw a graphic element

CALLED BY:	INTERNAL
		GraphicRunDraw

PASS:
	*ds:si - text object
	ss:bp - VisTextGraphic
	di - gstate
RETURN:
	none (state of the gstate can be trashed)
DESTROY:
	ax, bx, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
DrawGraphicGString	proc	near

	; transform me

	push	si, ds
	segmov	ds, ss
	lea	si, ss:[bp].VTG_data.VTGD_gstring.VTGG_tmatrix
	call	GrApplyTransform
	pop	si, ds
	
	;
	; The left/top are not zero. We negate them and call GrApplyTranslation
	; in order to get to the right place for the draw.
	;
	mov	dx, ss:[bp].VTG_data.VTGD_gstring.VTGG_drawOffset.XYO_x
	clr	cx				; dx.cx <- X trans (WWFixed)
	mov	bx, ss:[bp].VTG_data.VTGD_gstring.VTGG_drawOffset.XYO_y
	clr	ax				; bx.ax <- Y trans (WWFixed)
	call	GrRelMoveTo

	call	T_GetVMFile			; bx = VM file

	mov	ax, ss:[bp].VTG_vmChain.high
	tst	ax
	jz	isLMem
	mov	cx, ss:[bp].VTG_vmChain.low
	tst	cx
	jnz	isDB

	mov_tr	si, ax			;SI <- VMem chain handle

	; its in a vm chain -- draw it

	mov	cx, GST_VMEM

loadAndDraw:
	call	GrLoadGString			;si = gstring
	
	;
	; di	= GState
	; si	= GString
	;
	; Draw the string, we're in the right place.
	;
	clr	dx
	call	GrDrawGStringAtCP

	mov	dl, GSKT_LEAVE_DATA		; leave data alone
	call	GrDestroyGString
	ret

isDB:
	; gstring is in a DB item -- draw it

	push	di
	mov	di, cx
	call	DBLock				;*es:di = data
	segmov	ds, es
	mov	si, ds:[di]
	pop	di
	clr	dx

	push	si, bx
	mov	cl, GST_PTR			; pointer type GString
	mov	bx, ds				; bx:si -> GString
	call	GrLoadGString

	call	GrDrawGStringAtCP

	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	si, bx
	call	DBUnlock
done:
	ret

isLMem:

	; gstring is in a chunk -- draw it

	mov	si, ss:[bp].VTG_vmChain.low
	tst	si
	jz	done
	mov	si, ds:[si]
	clr	dx

	mov	cl, GST_PTR			; pointer type GString
	mov	bx, ds				; bx:si -> GString
	jmp	loadAndDraw

DrawGraphicGString	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawGraphicVariable

DESCRIPTION:	Draw a graphic element by sending a method to ourself

CALLED BY:	INTERNAL
		GraphicRunDraw

PASS:
	*ds:si - text object
	ss:bp - VisTextGraphic
	di - gstate
RETURN:
	cx - width of graphic drawn
	dx - height of graphic drawn
	state of the gstate can be trashed
DESTROY:
	ax, bx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
DrawGraphicVariable	proc	near
	mov	ax, MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW
	mov	cx, di					;pass gstate in dx
	mov	dx, ss
	call	ObjCallInstanceNoLock
	ret

DrawGraphicVariable	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextGraphicVariableDraw --
		MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW for VisTextClass

DESCRIPTION:	Default handler for drawing a variable graphic

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	cx - gstate with font and current position set
	dx:bp - VisTextGraphic (dx always = ss)

RETURN:
	cx - width of the graphic
	dx - height of the graphic

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/30/92		Initial version

------------------------------------------------------------------------------@
VisTextGraphicVariableDraw	proc	far ;MSG_VIS_TEXT_GRAPHIC_VARIABLE_DRAW

	; send a message up to the document to try to get a string

	sub	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE
	mov	di, sp				;ss:di = buffer
	call	GetVariableString

	segmov	ds, ss
	mov	si, di				;ds:si = string
	mov	di, cx				;di = gstate
	clr	cx				;null terminated
	call	GrDrawTextAtCP

	call	GrTextWidth
	mov	cx, dx				;cx = width
	clr	dx				;height = 0

	add	sp, GEN_DOCUMENT_GET_VARIABLE_BUFFER_SIZE

	ret

VisTextGraphicVariableDraw	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TG_GraphicRunDelete

DESCRIPTION:	Delete a graphic element

CALLED BY:	INTERNAL
		RemoveElementLow

PASS:
	*ds:si - graphic element array
	ds:di - VisTextGraphic
	ax - VM file

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
TG_GraphicRunDelete	proc	far	uses si, di, bp
	.enter

	mov_tr	bx, ax				;bx = VM file
	movdw	axbp, ds:[di].VTG_vmChain
	tst	ax
	jz	done
	call	VMFreeVMChain
done:
	.leave
	ret

TG_GraphicRunDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetGraphicAtPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the graphic at the current position.

CALLED BY:	GLOBAL
PASS:		ss:bp - VisTextGetGraphicAtPositionParams
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetGraphicAtPosition	proc	far	;method VisTextClass MSG_VIS_TEXT_GET_GRAPHIC_AT_POSITION
	.enter

if ERROR_CHECK
	;
	; Validate that ret ptr is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].VTGGAPP_retPtr				>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	movdw	dxax, ss:[bp].VTGGAPP_position
	les	di, ss:[bp].VTGGAPP_retPtr
	sub	sp, size VisTextGraphic
	mov	bp, sp			;SS:BP <- buffer for VisTextGraphic
	call	TA_GetGraphicForPosition

;	Copy the VisTextGraphic structure out.

	segmov	ds, ss			;DS:SI <- size VisTextGraphic
	mov	si, bp
	mov	cx, (size VisTextGraphic) / 2
	rep	movsw

	add	sp, size VisTextGraphic

	.leave
	ret
VisTextGetGraphicAtPosition	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TG_IfVariableGraphicsThenRecalc

DESCRIPTION:	If the object contains a varibale graphic then recalculate it

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	cx - chunk handle to pass to TG_RecalcAfterPrint

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/13/92		Initial version

------------------------------------------------------------------------------@
TG_IfVariableGraphicsThenRecalc	proc	far	uses ax, bx, dx, di, es
	class	VisTextClass
	.enter
EC <	call	T_AssertIsVisText					>

	clr	cx
	call	TA_CheckForVariableGraphics
	jnc	done

	; variable graphic exists -- save line structures

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].VTI_lines			;bx = line array
	push	bx					;save line array

	; save flags

	mov	ax, si
	call	ObjGetFlags
	push	ax					;save the flags
	push	bx
	mov	ax, si
	mov	bx, mask OCF_IGNORE_DIRTY
	call	ObjSetFlags
	pop	bx

	push	si					;save object
	push	bx					;save line array
	ChunkSizeHandle	ds, bx, cx			;cx = size
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc				;ax = new line arrray
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ds:[di].VTI_lines, ax
	mov_tr	di, ax
	mov	di, ds:[di]
	segmov	es, ds					;es:di = dest
	pop	si
	mov	si, ds:[si]				;ds:si = source
	rep	movsb
	pop	si					;*ds:si = object

	call	TextCompleteRecalc

	mov	ax, si
	pop	bx					;bx = old flags
	mov	bh, bl
	clr	bl
	and	bh, mask OCF_IGNORE_DIRTY
	call	ObjSetFlags

	pop	cx

done:
	.leave
	ret

TG_IfVariableGraphicsThenRecalc	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TG_RecalcAfterPrint

DESCRIPTION:	Recalculate after printing with variable graphics

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	cx - chunk returned by TG_IfVariableGraphicsThenRecalc

RETURN:
	none

DESTROYED:
	cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/13/92		Initial version

------------------------------------------------------------------------------@
TG_RecalcAfterPrint	proc	far	uses ax, cx, di
	class	VisTextClass
	.enter
EC <	call	T_AssertIsVisText					>

	mov_tr	ax, cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	xchg	ax, ds:[di].VTI_lines
	call	LMemFree

	.leave
	ret

TG_RecalcAfterPrint	endp

TextGraphic ends
