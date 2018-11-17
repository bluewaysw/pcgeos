COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		FEP (Front End Processor) Driver
FILE:		textFep.asm

AUTHOR:		Vijay Menon, Sep 27, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/27/93   	Initial revision


DESCRIPTION:
	FEP interface routines.
		

	$Id: textFep.asm,v 1.1 97/04/07 11:18:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextFep		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FepCallRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if an FEP driver is loaded and calls appropiate
		routine.  

CALLED BY:	TextLibraryEntry, VisTextKbd, etc.
PASS:		di	= FepFunction
		Other registers varying on di.

RETURN:		If an FEP Driver is loaded:
			CF	= 0
			Other return values varying on di
		else (no driver)
			CF	= 1
DESTROYED:	Varies on di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FepCallRoutine	proc	far
		uses	es
		.enter

		push	ax
		mov	ax, segment fepStrategy
		mov	es, ax				;es <- seg addr dgroup
		pop	ax
	;
	; If fepStrategy = 0 then no driver has been loaded.
	; 
		tst 	es:[fepStrategy].segment
		stc
		jz	done
	;
	; Call the strategy with the passed variables
	;
		call	es:[fepStrategy]
		clc
done:		
		.leave
		ret
FepCallRoutine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextCheckFepBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if the passed rectangle is within a window.

CALLED BY:	VisTextGetFepBounds
PASS:		ss:bp	= ptr to FepTempTextBoundsInfo
		di	= gstate.
RETURN:		CF	= 1 iff passed rectangle not in window.

DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/29/93    	Initial version
	eca	6/7/94		changed to clip to window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextCheckFepBounds	proc	near
		uses	cx, dx
		.enter

	;
	; Check for rotatation
	;
		push	ds, si
		sub	sp, size TransMatrix
		segmov	ds, ss, ax
		mov	si, sp
		call	GrGetTransform
		mov	ax, ds:[si].TM_e12.WWF_frac
		or	ax, ds:[si].TM_e12.WWF_int
		or	ax, ds:[si].TM_e21.WWF_frac
		or	ax, ds:[si].TM_e21.WWF_int
		lea	sp, ds:[si]+(size TransMatrix)
		pop	ds, si
		jnz	badBounds			; rotation

	;
	; Get the screen bounds of the window
	;
		call	WinGetWinScreenBounds
		cmp	ss:[bp].FTTBI_bounds.R_left, ax
		jge	leftOK
		push	ax
		sub	ax, ss:[bp].FTTBI_bounds.R_left
		sub	ss:[bp].FTTBI_textOffset.P_x, ax
		pop	ax
		mov	ss:[bp].FTTBI_bounds.R_left, ax
leftOK:
		cmp	ss:[bp].FTTBI_bounds.R_right, cx
		jle	rightOK
		mov	ss:[bp].FTTBI_bounds.R_right, cx
rightOK:
if 1
		; If baseline offset isn't in the window
		; it assumes the bound is BAD.

;		push	bx
		sub	bx, ss:[bp].FTTBI_baselineOffset
		inc	bx
		cmp	ss:[bp].FTTBI_bounds.R_top, bx
;		pop	bx
		jl	badBounds
else
		cmp	ss:[bp].FTTBI_bounds.R_top, bx
		jge	topOK
		mov	ss:[bp].FTTBI_bounds.R_top, bx
topOK:
endif
		cmp	ss:[bp].FTTBI_bounds.R_bottom, dx
		jle	bottomOK
		mov	ss:[bp].FTTBI_bounds.R_bottom, dx
bottomOK:
	;
	; Make sure the bounds haven't crossed each other
	;
		mov	ax, ss:[bp].FTTBI_bounds.R_left
		cmp	ax, ss:[bp].FTTBI_bounds.R_right
		jg	badBounds
		mov	ax, ss:[bp].FTTBI_bounds.R_top
		cmp	ax, ss:[bp].FTTBI_bounds.R_bottom
		jg	badBounds
	;
	; Make sure the text offset is in the window
	;
		mov	ax, ss:[bp].FTTBI_textOffset.P_x
		add	ax, ss:[bp].FTTBI_bounds.R_left
		dec	ax
		cmp	ax, ss:[bp].FTTBI_bounds.R_right
		jg	badBounds

		; Use baselineOffset instead of textOffset.P_y
		; because height of the FEP window is not always
		; equal to textOffset.P_z

		mov	ax, ss:[bp].FTTBI_baselineOffset
		add	ax, ss:[bp].FTTBI_bounds.R_top
		cmp	ax, ss:[bp].FTTBI_bounds.R_bottom
		jg	badBounds
	;
	; Bounds okay.
	;
		clc					;carry <- bounds OK
done:		
		.leave
		ret

badBounds:
		stc					;carry <- bad bounds
		jmp 	done
VisTextCheckFepBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetFepBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the suggested bounds for the FEP window.

CALLED BY:	MSG_VIS_TEXT_GET_FEP_BOUNDS
PASS:		*ds:si	= VisTextClass object
		ds:di	= VisTextClass instance data
		ds:bx	= VisTextClass object (same as *ds:si)
		es 	= segment of VisTextClass
		ax	= message #
		ss:bp	= ptr to FepTempTextBoundsInfo

RETURN:		ss:bp	= FepTempTextBoundsInfo filled in
		    FTTBI_bounds		;text bounds: A(x,y) to C(x,y)
		    FTTBI_textOffset		;text offset: B(x,y)
		    FTTBI_baselineOffset	;baseline: baseline of "The..."
		    FTTBI_layerID		;layer ID of window
		CF	= 1 iff bounds invalid.
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/27/93   	Initial version
	eca	4/4/94		new API

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetFepBounds	method dynamic VisTextClass, 
					MSG_VIS_TEXT_GET_FEP_BOUNDS
		.enter
if ERROR_CHECK
		push	ax, cx, es, di
		segmov	es, ss
		mov	di, bp				;es:di <- ptr to dest
		mov	al, 0xcc			;al <- byte to store
		mov	cx, (size FepTempTextBoundsInfo)
		rep	stosb
		pop	ax, cx, es, di
endif
	;
	; Check whether the gstate is valid.  If not return invalid bounds.
	;
		tst 	ds:[di].VTI_gstate
		jnz	windowOpen
		stc					;carry <- invalid bounds
		jmp	done
windowOpen:
	;
	; Get the region and coordinate of the selection start.
	;
		push	ds:[di].VTI_gstate
		movdw	dxax, ds:[di].VTI_selectStart
		call	TSL_ConvertOffsetToRegionAndCoordinate
		xchg	cx, ax				;(ax, dx) <- coords
		mov	ss:[bp].FTTBI_textOffset.P_x, ax
		mov	ss:[bp].FTTBI_bounds.R_top, dx
	;
	; Transform the GState so it falls at the upper left of the region.
	;
		push	ax, dx
		push	dx
		clr	dl				;dl <- DrawFlags
		call	TR_RegionTransformGState
		pop	dx
	;
	; Get height and baseline offset.
	;
		call	TL_LineFromPositionGetBLOAndHeight
		mov	ss:[bp].FTTBI_textOffset.P_y, dx
		mov	ss:[bp].FTTBI_baselineOffset, bx
		pop	ax, dx				;dx <- y coord
	;
	; Get the left and right of the region.
	;
		call	TR_RegionLeftRight
		mov	ss:[bp].FTTBI_bounds.R_left, ax
		mov	ss:[bp].FTTBI_bounds.R_right, bx
	;
	; Get the bottom of the region
	;
	; XXX:	The preferred information is the bottom of the clip
	;	area, as the region doesn't account for text that
	;	isn't there yet.  Ideally this would take into account
	;	overlapping windows, etc. but it doesn't.
	;
		pop	di				;di <- GState handle
		call	GrGetMaskBounds
		jnc	haveMask
		mov	dx, ss:[bp].FTTBI_bounds.R_top
		push	di
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	ax, ds:[di].VI_bounds.R_bottom
		sub	ax, ds:[di].VI_bounds.R_top
		pop	di
		add	dx, ax
haveMask:
		mov	ss:[bp].FTTBI_bounds.R_bottom, dx
	;
	; Get the window layer ID information
	;
		mov	si, WIT_LAYER_ID		;si <- WinInfoType
		call	WinGetInfo
		mov	ss:[bp].FTTBI_layerID, ax
	;
	; Transform bounds to screen coordinates
	;
		mov	ax, ss:[bp].FTTBI_bounds.R_left
		mov	bx, ss:[bp].FTTBI_bounds.R_top	;(ax,bx) <- upper left
		push	ax, bx				; store old position
		call	GrTransform
		mov	ss:[bp].FTTBI_bounds.R_left, ax
		mov	ss:[bp].FTTBI_bounds.R_top, bx
		movdw	cxdx, axbx			; store new position

		pop	ax, bx				; restore old position
		add	ax, ss:[bp].FTTBI_textOffset.P_x
		add	bx, ss:[bp].FTTBI_textOffset.P_y
		call	GrTransform
		sub	ax, cx				; cx - new R_left
		sub	bx, dx				; dx - new R_top
		mov	ss:[bp].FTTBI_textOffset.P_x, ax
		mov	ss:[bp].FTTBI_textOffset.P_y, bx

		mov	ax, ss:[bp].FTTBI_bounds.R_right
		mov	bx, ss:[bp].FTTBI_bounds.R_bottom ;(ax,bx) <- lower rght
		call	GrTransform
		dec	ax				;-1 for beauty
		mov	ss:[bp].FTTBI_bounds.R_right, ax
		mov	ss:[bp].FTTBI_bounds.R_bottom, bx
	;
	; Check the bounds
	;
		call	VisTextCheckFepBounds
done:
		.leave
		ret
VisTextGetFepBounds	endm

TextFep		ends

TextFixed	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextWinGetScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the scale from the text window.

CALLED BY:	VisTextGetFepBounds, FepGetTempTextAttr
PASS:		di	= gstate
RETURN:		dx.cx 	= x-scale
		bx.ax	= y-scale
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	10/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextWinGetScale	proc	far
		uses	ds, si
		.enter
		sub	sp, size TransMatrix
		segmov	ds, ss, ax
		mov	si, sp
		call	WinGetTransform
		movdw 	dxcx, ds:[si].TM_e11
		movdw 	bxax, ds:[si].TM_e22
		add	sp, size TransMatrix
		.leave
		ret
VisTextWinGetScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FepCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call Back routine to pass to FEP Driver.

CALLED BY:	FEP Driver
PASS:		cx:dx	= optr to Text Object
		di	= FepCallBackFunction
		ss:sp	= FEP stack
RETURN:		Varying on di
DESTROYED:	bx, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/22/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FepCallBack	proc	far
		.enter
	;
	; Set bxsi to text object.
	;
		mov	bx, cx
		mov	si, dx
	;
	; Call appropriate function.
	;
		call	cs:[FepCallBackTable][di]
		.leave
		ret
FepCallBack	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FepGetTempTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suggest bounds for the Temp Text window.

CALLED BY:	FepCallBack
PASS:		ss:bp	= ptr to FepTempTextBoundsInfo
RETURN:		ss:bp	= FepTempTextBoundsInfo filled in
		CF	= 1 iff bounds are invalid.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	10/ 6/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FepGetTempTextBounds	proc	near
		uses	ax, bx, cx, dx, di
		.enter
	;
	; Ensure current text position is shown.
	;
		push	bp
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_START
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	ax, MSG_VIS_TEXT_SHOW_POSITION
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	bp
	;
	; Get the bounds for the FEP window.
	; 	
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_FEP_BOUNDS
		mov	di, mask MF_CALL
		call	ObjMessage

		.leave
		ret
FepGetTempTextBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FepGetTempTextAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Temp Text attributes for the FEP

CALLED BY:	FepCallBack
PASS:		ss:bp	= FepTempTextAttr to fill in
		bx:si	= Text object
		
RETURN:		ss:bp	= FepTempTextAttr filled in
		CF	= 1 iff data invalid.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	10/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FepGetTempTextAttr	proc	near
		uses	ax,cx,dx,di,bp
		.enter
		push	bx, si
	;
	; Get the gstate.
	;
		mov	ax, MSG_VIS_TEXT_GET_GSTATE
		call	callObjMessage
	;
	; Check whether window is open - if not mark data invalid.
	;
		stc
		jcxz	donePop

	;
	; Really check if there's a window
	;
		mov	di, cx			; di = gstate
		call	GrGetWinHandle		; ax = window
		tst	ax
		stc
		jz	donePop
		
	;
	; Get the window color.
	;		
		mov	si, WIT_COLOR
		call	WinGetInfo

		mov	ss:[bp].FTTA_winAttributes.FTWA_colorFlags, ah
		mov	ss:[bp].FTTA_winAttributes.FTWA_redOrIndex, al
		mov	ss:[bp].FTTA_winAttributes.FTWA_blue, bl
		mov	ss:[bp].FTTA_winAttributes.FTWA_green, bh
	;
	; Get the scale of the window.
	;
		call	VisTextWinGetScale
		movdw	ss:[bp].FTTA_winAttributes.FTWA_xScale, dxcx
		movdw	ss:[bp].FTTA_winAttributes.FTWA_yScale, bxax
		pop	bx, si
	;
	; Get the selection start (-> dx:cx).
	;
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_START
		call	callObjMessage
	;
	; Get the character attributes at the selection start.
	;
		push	bp
		lea	bp, ss:[bp].FTTA_textCharAttr
		mov	ax, MSG_VIS_TEXT_GET_SINGLE_CHAR_ATTR
		call	callObjMessage
		pop	bp

		clc				;carry <- success!
done:
		.leave
		ret
donePop:
 		pop	bx, si
		jmp	done

callObjMessage:
		mov	di, mask MF_CALL
		call	ObjMessage
		retn
FepGetTempTextAttr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FepInsertTempText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the passed text into the text object.

CALLED BY:	FepCallBack
PASS:		bx:si	= Text Object Handle
		es:bp	= text string to insert
		ax	= number of chars
RETURN:		nothing 
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	10/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FepInsertTempText	proc	near
		uses	ax,cx,di,dx,bp
		.enter

		mov	cx, bp				;es:cx <- ptr to string

		sub	sp, size VisTextReplaceParameters
		mov	bp, sp
	;
	; Pass ptr to our text
	;
		mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
		movdw	ss:[bp].VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer, escx
		mov	ss:[bp].VTRP_insCount.low, ax
		clr	ss:[bp].VTRP_insCount.high
	;
	; Filter the text if necessary, mark as from the keyboard,
	; and mark the text user modified.
	;
		mov	ss:[bp].VTRP_flags, mask VTRF_FILTER or \
				    mask VTRF_KEYBOARD_INPUT or \
				    mask VTRF_USER_MODIFICATION or \
				    mask VTRF_TRUNCATE

	;
	; get current text size
	;
		push	bp
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		mov	di, mask MF_CALL
		call	ObjMessage			;dx:ax = size
		pop	bp
		pushdw	dxax

	;
	; check if anything selected, if so, replace it
	;
		push	bp
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
		lea	bp, ss:[bp].VTRP_range		;dx:bp = VisTextRange
		mov	dx, ss
		mov	di, mask MF_CALL
		call	ObjMessage
		cmpdw	ss:[bp].VTR_start, ss:[bp].VTR_end, ax
		pop	bp
		jne	replaceSelection	;have selection, replace it
	;
	; no selection, if insert mode, insert, if overstrike mode, replace
	; equal number of characters, if possible
	;
		push	bp
		mov	ax, MSG_VIS_TEXT_GET_STATE
		mov	di, mask MF_CALL
		call	ObjMessage			;cl = VisTextStates
		test	cl, mask VTS_OVERSTRIKE_MODE	;insert mode?
		pop	bp
		jz	replaceSelection		;yes, replace null
							;	 selection
	;
	; overstrike mode, if no overflow of replace characters, expected
	; size is same as original size
	;
		mov	ax, ss:[bp].VTRP_insCount.low
		add	ss:[bp].VTRP_range.VTR_end.low, ax
		adc	ss:[bp].VTRP_range.VTR_end.high, 0
		popdw	dxax				;dx:ax = size
		cmpdw	ss:[bp].VTRP_range.VTR_end, dxax
		jb	replaceCommon
	;
	; overstriking more characters than there are, expected size is
	; insert count + number chars up to selection point
	;
		movdw	dxax, ss:[bp].VTRP_insCount
		adddw	dxax, ss:[bp].VTRP_range.VTR_start
		movdw	ss:[bp].VTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
		jmp	replaceCommon

replaceSelection:
		movdw	cxdi, ss:[bp].VTRP_range.VTR_end
		subdw	cxdi, ss:[bp].VTRP_range.VTR_start	;select size
		movdw	dxax, ss:[bp].VTRP_insCount
		subdw	dxax, cxdi			;dx:ax = net change
		popdw	cxdi				;cx:dx = original size
		adddw	dxax, cxdi			;dx:ax = expected size
		mov	ss:[bp].VTRP_range.VTR_start.high, \
						VIS_TEXT_RANGE_SELECTION
replaceCommon:
		pushdw	dxax				;save expected size

	;
	; Replace the current selection.
	;
		mov	dx, size VisTextReplaceParameters
		mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage


	;
	; get new text size, beep if some characters were dropped
	;
		mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
		mov	di, mask MF_CALL
		call	ObjMessage			;dx:ax = current size
		popdw	cxdi				;cx:di = expected size
		cmpdw	cxdi, dxax
		je	noError
		mov	dx, size GetVarDataParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].GVDP_bufferSize, 0
		mov	ss:[bp].GVDP_dataType, ATTR_VIS_TEXT_DONT_BEEP_ON_INSERTION_ERROR
		mov	ax, MSG_META_GET_VAR_DATA
		mov	di, mask MF_CALL or mask MF_STACK
		call	ObjMessage
		add	sp, size GetVarDataParams
		cmp	ax, -1				;found?
		jne	noError				;yes, no error beep
		mov	ax, SST_ERROR
		call	UserStandardSound
noError:

		add	sp, (size VisTextReplaceParameters)

		.leave
		ret
FepInsertTempText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FepDeleteText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the N characters immediately before the
		current cursor position.

CALLED BY:	FepCallBack
PASS:		bx:si	= Text Object Handle
		ax	= Number of characters to delete
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	11/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FepDeleteText	proc	near
		uses	ax,cx,dx,bp
		.enter
	;
	; Set range of text.
	;
		push	ax
		mov	ax, MSG_VIS_TEXT_GET_SELECTION_START
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	ax
		sub	sp, size VisTextRange
		mov	bp, sp
		movdw	ss:[bp].VTR_end, dxcx
		sub	cx, ax
		sbb	dx, 0
		movdw	ss:[bp].VTR_start, dxcx
	;
	; Delete the range.
	;
		mov	ax, MSG_META_DELETE_RANGE_OF_CHARS
		mov	di, mask MF_CALL or mask MF_STACK
		mov	dx, size VisTextRange
		call	ObjMessage
		add	sp, size VisTextRange

		.leave
		ret
FepDeleteText	endp


FepCallBackTable	nptr.near	\
		TextFixed:FepGetTempTextBounds,	;FCBF_GET_TEMP_TEXT_BOUNDS
		TextFixed:FepGetTempTextAttr,	;FCBF_GET_TEMP_TEXT_ATTR
		TextFixed:FepInsertTempText,	;FCBF_INSERT_TEMP_TEXT
		TextFixed:FepDeleteText		;FCBF_DELETE_TEXT
.assert (size FepCallBackTable	eq FepCallBackFunction)

TextFixed	ends
