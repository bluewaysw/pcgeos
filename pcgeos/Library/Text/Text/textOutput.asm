COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textOutput.asm

AUTHOR:		John Wedgwood, Oct  6, 1989

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 6/89	Initial revision

DESCRIPTION:
	Routines for telling the rest of the world about changes in the
	text object.

	$Id: textOutput.asm,v 1.1 97/04/07 11:18:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextInstance segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextShowPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:	via MSG_VIS_TEXT_SHOW_POSITION
PASS:		*ds:si	= Instance ptr
		dx.cx	= Position to show. This can be any of the special
			  values for VTR_start.
RETURN:		nothing
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextShowPosition	method	dynamic VisTextClass, 
			MSG_VIS_TEXT_SHOW_POSITION
	;
	; Convert any special values into something more meaningful.
	;
	sub	sp, size VisTextRange	; Allocate stack frame
	mov	bp, sp			; ss:bp <- frame ptr
	movdw	ss:[bp].VTR_start, dxcx	; Store the (possibly) virtual offset
	movdw	ss:[bp].VTR_end, dxcx

	clr	bx			; No context	
	call	TA_GetTextRange		; Convert the range to real values
	
	movdw	dxax, ss:[bp].VTR_start	; dx.ax <- converted value
	add	sp, size VisTextRange	; Restore the stack frame

	;
	; Now use the converted value.
	;
	call	TextGStateCreate	; Give me a gstate
	clr	bp			; Not dragging
	call	TextCallShowSelection	; Show the selection
	call	TextGStateDestroy	; Nuke the gstate
	ret
VisTextShowPosition	endm

TextInstance	ends

Text	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCallShowSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show a portion of the text.

CALLED BY:	UTILITY
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset in text to show
		bp	= non-zero if we're calling this becuase of
			  pointer dragging, clear if not.
RETURN:		nothing
DESTROYED:	bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCallShowSelection	proc	far
	class	VisLargeTextClass

	call	Text_PushAll

	mov	di, 500
	call	ThreadBorrowStackSpace
	push	di

	mov_tr	bx, bp
cursorHeight	local	word
args		local	VisTextShowSelectionArgs
	.enter

	mov	args.VTSSA_flags, bx

	call	Text_DerefVis_DI		; ds:di <- instance ptr
	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	noHeightNotify
	test	ds:[di].VLTI_flags, mask VLTF_HEIGHT_NOTIFY_PENDING
	pushf
	andnf	ds:[di].VLTI_flags, not mask VLTF_HEIGHT_NOTIFY_PENDING
	popf
	jz	noHeightNotify
	push	ax, dx, bp
	mov	ax, TEMP_VIS_TEXT_FREEING_OBJECT
	call	ObjVarFindData
	jc	noNotif
	mov	ax, MSG_VIS_TEXT_HEIGHT_NOTIFY
	call	ObjCallInstanceNoLock
noNotif:
	pop	ax, dx, bp
noHeightNotify:

	; if the object is suspended then save the position to show and bail

	call	Text_DerefVis_DI
	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jz	notSuspended

	push	ax
	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData
	pop	ax
EC <	ERROR_NC VIS_TEXT_SUSPEND_LOGIC_ERROR				>
	movdw	ds:[bx].VTSD_showSelectionPos, dxax
	jmp	done

notSuspended:
	call	TextCheckCanDraw
	jc	toDone				; Quit if can't draw


	; if the object is targetable then it must have the target for us
	; to respond to this

	test	ds:[di].VTI_state, mask VTS_TARGETABLE
	jz	continue
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jnz	continue
toDone:
	jmp	done
continue:

	;
	; If we are showing the cursor, just use the cursor position.
	;
	call	TSL_SelectIsCursor		; Check for displaying cursor
	LONG jnc notCursor

	cmp	ds:[di].VTI_cursorPos.P_y, EOREGREC
	LONG jz	notCursor

;-----------------------------------------------------------------------------
	;
	; Save stuff for later
	; *ds:si= Instance
	; ds:di	= Instance
	;
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- region
	clr	dx				; no draw flags
	call	TR_RegionTransformGState
	mov_tr	ax, cx				;ax <- region

	mov	cx, ds:[di].VTI_cursorPos.P_x	; cx <- y position
	mov	dx, ds:[di].VTI_cursorPos.P_y	; dx <- y position

	push	ax, cx, dx, di			; Save region, Y position, etc

	;
	; Compute:
	;   bx = baseline
	;   dx = line height
	;
	call	TSL_GetCursorLineBLOAndHeight	; bx.al <- baseline
						; dx.ah <- line height

	ceilwbf	bxal, bx			; bx <- baseline
	ceilwbf	dxah, dx			; dx <- line height

	mov	cursorHeight, dx
	pop	ax, cx, dx, di			; Restore region, Y pos, etc

	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; cx	= X position (region relative)
	; dx	= Y position (region relative)
	; ax	= Region
	; bx	= Baseline
	;

	;
	; These two lines are a hack caused by a bug when the "space on top"
	; is set non-zero for the first line of the object -- tony 12/12/91
	;
	jns	gotPosition			; Force it positive
	clr	dx

gotPosition:
	;
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; ax	= Region
	; cx	= X position to show (relative to region)
	; dx	= Y position to show (relative to region)
	;

	;
	; Make sure that the x-position (cx) is inside the bounds of this
	; object.
	;
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jnz	noTryOptimize

	push	ax
	mov	ax, TEMP_VIS_TEXT_SHOW_SELECTION_AT_TOP
	call	ObjVarFindData
	pop	ax
	jc	noTryOptimize

	;
	; optimization: see if selection is already shown
	;
	push	ax, cx, dx, si			; Save reg, X/Y, instance

	push	cx, dx				; Save X/Y
	mov	di, ds:[di].VTI_gstate
	call	GrGetWinBounds			; ax, bx, cx, dx = bounds
	pop	di, si				; di <- X, si <- Y

	cmp	di, ax				;off left ?
	jl	noOptimize
	cmp	di, cx				;off right ?
	jg	noOptimize
	cmp	si, bx				;off top ?
	jl	noOptimize
	add	si, cursorHeight		;si = bottom
	cmp	si, dx
	jg	noOptimize
	stc
	jmp	common

noOptimize:
	clc

common:
	;
	; Carry is set if we can optimize our way out of this. This happens 
	; if the position is already on screen.
	;
	pop	ax, cx, dx, si			; Rstr reg, X/Y, instance
	jc	done

noTryOptimize:
	;
	; Can't optimize our way out of this. Call a method handler in order
	; to get the position displayed. Before we do, convert the coordinates
	; to be *real* rather than region-relative.
	; *ds:si= Instance
	; cx	= X position (region relative)
	; dx	= Y position (region relative)
	; ax	= Region
	;
	; Allocate stack frame
	;
	push	cx, bp				; Save X position
	lea	bp, args.VTSSA_params.MRVP_bounds.RD_left
	mov_tr	cx, ax				; cx <- region
	call	TR_RegionGetTopLeft		; Fill in region top-left
	pop	cx, bp				; Restore X position
	
	;
	; Combine the x/y position (cx/dx) with the region position.
	; For now we are ignoring the high word (which we probably shouldn't)
	;
	add	args.VTSSA_params.MRVP_bounds.RD_left.low, cx
	adc	args.VTSSA_params.MRVP_bounds.RD_left.high, 0
	add	args.VTSSA_params.MRVP_bounds.RD_top.low, dx
	adc	args.VTSSA_params.MRVP_bounds.RD_top.high, 0

	; calculate the right and bottom
	;	right = left
	;	bottom = top + cursorHeight

	movdw	dxax, args.VTSSA_params.MRVP_bounds.RD_left
	movdw	args.VTSSA_params.MRVP_bounds.RD_right, dxax
	movdw	dxax, args.VTSSA_params.MRVP_bounds.RD_top
	add	ax, cursorHeight
	adc	dx, 0
	movdw	args.VTSSA_params.MRVP_bounds.RD_bottom, dxax

	mov	ax, MRVM_50_PERCENT
	mov	args.VTSSA_params.MRVP_xMargin, ax
	mov	args.VTSSA_params.MRVP_yMargin, ax
	clr	ax
	mov	args.VTSSA_params.MRVP_xFlags, ax
	mov	args.VTSSA_params.MRVP_yFlags, ax

	mov	ax, TEMP_VIS_TEXT_SHOW_SELECTION_AT_TOP
	call	ObjVarFindData
	jnc	callShowSelection
	mov	args.VTSSA_params.MRVP_yMargin, MRVM_0_PERCENT
	mov	args.VTSSA_params.MRVP_yFlags, mask MRVF_ALWAYS_SCROLL or \
					mask MRVF_USE_MARGIN_FROM_TOP_LEFT

callShowSelection::
	push	bp
	call	Text_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_ONE_LINE
	jnz	oneLineObject

	;***** START HACK - Joon (4/24/95)
	; Force the selection to be visible only if we're not low on handles.
	mov	ax, SGIT_NUMBER_OF_FREE_HANDLES
	call	SysGetInfo
	cmp	ax, LOW_ON_FREE_HANDLES_THRESHOLD
	jb	popDone				; But not if handles is too low
	;***** END HACK

	;
	; Force the selection to be visible
	;
	lea	bp, args
	mov	ax, MSG_VIS_TEXT_SHOW_SELECTION
	call	Text_ObjCallInstanceNoLock	; Send to ourselves
popDone:
	pop	bp

done:
	.leave

	pop	di
	call	ThreadReturnStackSpace

	Text_PopAll_ret

oneLineObject:
	mov	ax, MSG_VIS_TEXT_SCROLL_ONE_LINE
	mov	cx, args.VTSSA_params.MRVP_bounds.RD_left.low
	call	ObjCallInstanceNoLock
	jmp	popDone

notCursor:
	;
	; It's not a cursor, just get the height of the line at this offset.
	;
	push	dx				; Save offset.high
	call	TL_LineFromOffset		; bx.di <- line from dx.ax
	call	TL_LineGetHeight		; dx.bl <- line height
	mov	cursorHeight, dx
	pop	dx				; Restore offset.high

	;
	; Get the position of this address
	;
	call	TSL_ConvertOffsetToRegionAndCoordinate
						; cx, dx <- coordinates
						; ax <- region

	push	dx
	xchg	ax, cx
	clr	dx				; no draw flags
	call	TR_RegionTransformGState
	xchg	ax, cx
	pop	dx

	call	Text_DerefVis_DI		; ds:di <- instance
	add	cx, ds:[di].VTI_leftOffset	; Account for 1-line object
	jmp	gotPosition

TextCallShowSelection	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextShowSelection -- MSG_VIS_TEXT_SHOW_SELECTION
							for VisTextClass

DESCRIPTION:	Default handler for scrolling to show the selection

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The message

	bp - VisTextShowSelectionArgs

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/15/92		Initial version

------------------------------------------------------------------------------@
VisTextShowSelection	method dynamic	VisTextClass,
						MSG_VIS_TEXT_SHOW_SELECTION

	; encapsulate a MSG_GEN_VIEW_MAKE_RECT_VISIBLE

	push	si
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	dx, size MakeRectVisibleParams
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage
	pop	si

	; and send it up to the view

	mov	cx, di


	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent


	ret

VisTextShowSelection	endm

Text ends
