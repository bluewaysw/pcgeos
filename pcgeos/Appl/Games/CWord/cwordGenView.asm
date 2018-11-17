COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		
FILE:		cwordGenView.asm

AUTHOR:		Peter Trinh, Aug  1, 1994

ROUTINES:
	Name			Description
	----			-----------
	CGVMetaQueryIfPressIsInk	Sets up the gesture callback routine.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94   	Initial revision


DESCRIPTION:
	Code routines for subclass CwordGenViewClass.
		

	$Id: cwordGenView.asm,v 1.1 97/04/04 15:13:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CwordBoardBoundsCode	segment	resource

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVMetaQueryIfPressIsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the gesture callback routine and replies with
		an IRV_DESIRES_INK always.

CALLED BY:	MSG_META_QUERY_IF_PRESS_IS_INK
PASS:		*ds:si	= CwordGenViewClass object
		ds:di	= CwordGenViewClass instance data
		ds:bx	= CwordGenViewClass object (same as *ds:si)
		es 	= segment of CwordGenViewClass
		ax	= message #
		cx, dx 	= position of START_SELECT

RETURN:		ax	= InkReturnValue
		bp	= 0 or ^hInkDestinationInfo

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVMetaQueryIfPressIsInk	method dynamic CwordGenViewClass, 
					MSG_META_QUERY_IF_PRESS_IS_INK
	uses	cx, dx
	.enter

	mov	di, offset CwordGenViewClass
	call	ObjCallSuperNoLock

	cmp	ax, IRV_NO_INK
	je	exit
	
	clr	bp			;BP <- gstate to draw through
	clr	ax			;Default width/height
	mov	cx, handle Board
	mov	dx, offset Board	;^lCX:DX - send ink to Board

	mov	bx, vseg HwrCheckIfCwordGesture
	mov	di, offset HwrCheckIfCwordGesture
	call	UserCreateInkDestinationInfo
	tst	bp
	jz	cantReceiveInk

	;    Nuke the highlight so that the user can see their ink
	;

	mov	bx, cx
	mov	si, dx
	mov	ax,MSG_CWORD_BOARD_ERASE_HIGHLIGHTS
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, IRV_DESIRES_INK

exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cantReceiveInk:
	mov	ax, IRV_NO_INK
	jmp	exit

CGVMetaQueryIfPressIsInk	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVCalcWinSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insist that the view be square. This should only be
		a problem during launch.
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of 
		cx - suggested width 
		dx - suggested height

RETURN:		
		cx - better width
		dx - better height
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/18/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVCalcWinSize	method dynamic CwordGenViewClass, 
						MSG_GEN_VIEW_CALC_WIN_SIZE
	.enter

	cmp	cx,dx
	jne	notSquare

calcSize:
	call	CwordGenViewSetViewSize
	mov	dx,cx				;keep square
	.leave
	ret

notSquare:
	;    Use smaller value
	;
	jg	useHeight
	mov	dx,cx
	jmp	calcSize

useHeight:
	mov	cx,dx
	jmp	calcSize

CGVCalcWinSize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordGenViewSetViewSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates size of view no larger than passed max.
		It considers size of puzzle and zoom settings.
		Also sets doc bounds in view, updates board
		with new cell size.
		Enable/Disabled zoom button as necessary.

CALLED BY:	CGVCalcWinSize

PASS:
		*ds:si - CwordGenViewClass object
		cx - max width/height of view

RETURN:		
		cx - width of view
		
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordGenViewSetViewSize		proc	near
	class	CwordGenViewClass
	uses	ax,bx,dx,di,si

cellSize	local	word
viewSize	local	word

	.enter

;;; Verify argument(s)
	Assert	objectPtr	dssi, CwordGenViewClass
;;;;;;;;

 	;    If we don't have a puzzle, return passed size
	;

	mov	di,ds:[si]
	add	di,ds:[di].CwordGenView_offset
	mov	al,ds:[di].CGV_numColumns
	tst	al
	jz	done
	clr	ah					;high byte columns

	mov	dx,ds:[di].CGV_showWholePuzzle
	call	CwordCalcViewAndCellSize
	mov	viewSize,cx
	mov	cellSize,ax

	;    Set new cell size to use in board
	;    Must do this before setting document bounds so that the
	;    MSG_META_EXPOSED caused by setting the document bounds
	;    will arive at the content after the cells size has been
	;    changed.
	;

	push	si					;view chunk
	mov	cx,ax					;cell size
	mov	bx,handle Board
	mov	si,offset Board
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_CWORD_BOARD_SET_CELL_SIZE
	call	ObjMessage
	pop	si					;view chunk

	;    Calc and set document size in view
	;

	mov	dx,BOARD_BORDER_WIDTH
	mov	di,ds:[si]
	add	di,ds:[di].CwordGenView_offset
	mov	cl,ds:[di].CGV_numColumns
	clr	ch					;high byte cols
	mov	ax,cellSize
	call	BoardCalculateDimensionsHypothetical
	mov	cx,ax				;doc width
	mov	dx,ax				;doc height
	mov	di,mask MF_FIXUP_DS
	mov	bx,ds:[LMBH_handle]
	call	GenViewSetSimpleBounds

	mov	dx,viewSize
	call	CwordGenViewEnableDisableZoomButton


	mov	cx,viewSize

done:
	.leave
	ret

CwordGenViewSetViewSize		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordCalcViewAndCellSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the desired view size, that doesn't exceed max, and
		the cell size to use

		IF SWP_YES
			calc integer cell size that shows all cells
			round down view to multiple of that size plus border

		IF SWP_MAYBE
			IF whole puzzle can be shown with cell size at least
			default then use same values calced for SST_SMALL
			ELSE 
				use default cell size and set view to value
				below max but multiple of default size

CALLED BY:	

PASS:		
		cx - maximum view width
		dx - true is show whole puzzle
		ax - number of columns

RETURN:		
		cx - view width
		ax - cell size


DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordCalcViewAndCellSize		proc	far

maxWidth	local	word		push cx
squareType	local	SquareSizeType 	push dx

	uses	dx
	.enter

	;    Assume showing whole puzzle
	;

	call	CwordCalcWholePuzzleViewSize

	;    If zoomed out then we are showing whole puzzle, just
	;    return values already calculated
	;

	cmp	squareType, SST_LARGE
	je	bigSquares

done:
	.leave
	ret

bigSquares:
	;    If calced square size is at least default then we will
	;    be showing the whole puzzle, so just return already
	;    calced values
	;

	cmp	ax,BOARD_DEFAULT_CELL_SIZE	
	jae	done

	;     Not showing whole puzzle, use the max and the
	;     default cell size.
	;

	mov	cx,maxWidth
	mov	ax,BOARD_DEFAULT_CELL_SIZE
	jmp	done

CwordCalcViewAndCellSize		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordCalcWholePuzzleViewSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the integer cell size to display whole puzzle
		in view and the resulting view size

CALLED BY:	CwordSetViewSize

PASS:		
		cx - max view width
		ax - number of columns in puzzle

RETURN:		
		cx - view width showing whole puzzle
		dx - width without border
		ax - cell size for showing whole puzzle

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordCalcWholePuzzleViewSize		proc	near
	uses	bx,di
	.enter

	;    Remove border size from available width
	;

	mov	bx, BOARD_BORDER_WIDTH
	shl	bx, 1
	dec	bx
	sub	cx,bx

	;    Calc integer size for squares
	;

	xchg	cx,ax				;# cols, avail width
	clr	dx				;high word of width
	div	cx				;width/#cols
	mov	di,ax				;integer cell size

	;    Calc size of view with integer squares and border added in
	;

	mul	cx				;width * #cols
	mov	dx,ax				;view width
	add	ax,bx				;+ border 

	mov	cx,ax				;view width
	mov	ax,di				;cell size

	.leave
	ret
CwordCalcWholePuzzleViewSize		endp









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordGenViewZoomIn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set square size instance data and pass message to
		board

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordGenViewClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordGenViewZoomIn	method dynamic CwordGenViewClass, 
						MSG_CGV_ZOOM_IN
	uses	ax
	.enter

	mov	ds:[di].CGV_showWholePuzzle, SWP_MAYBE

	;    Allow there to be scroll bars
	;

	mov	ch,mask GVDA_DONT_DISPLAY_SCROLLBAR
	mov	dh,ch
	mov	cl,mask GVDA_SCROLLABLE
	mov	dl,cl
	mov	ax,MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	mov	bp,VUM_MANUAL
	call	ObjCallInstanceNoLock

	call	BoardRedoPrimaryGeometry

	mov	bx,handle Board
	mov	si,offset Board
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_CWORD_BOARD_ENSURE_SELECTED_WORDS_VISIBLE
	call	ObjMessage

	.leave
	ret
CwordGenViewZoomIn		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordGenViewZoomOut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set square size instance data and pass message to
		board

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordGenViewClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordGenViewZoomOut	method dynamic CwordGenViewClass, 
						MSG_CGV_ZOOM_OUT
	uses	ax
	.enter

	mov	ds:[di].CGV_showWholePuzzle, SWP_YES

	;    Get rid of those scrollbars
	;

	mov	cl,mask GVDA_DONT_DISPLAY_SCROLLBAR
	mov	dl,cl
	mov	ch,mask GVDA_SCROLLABLE
	mov	dh,ch
	mov	ax,MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	mov	bp,VUM_MANUAL
 	call	ObjCallInstanceNoLock

	call	BoardRedoPrimaryGeometry

	.leave
	ret
CwordGenViewZoomOut		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordGenViewZoomToggle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to other square size

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordGenViewClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordGenViewZoomToggle method dynamic CwordGenViewClass, 
						MSG_CGV_ZOOM_TOGGLE
	uses	ax
	.enter

	mov	ax, MSG_CGV_ZOOM_IN
	cmp	ds:[di].CGV_showWholePuzzle, SWP_YES
	je	haveMessage
	mov	ax, MSG_CGV_ZOOM_OUT

haveMessage:
	; send the message off
	call	ObjCallInstanceNoLock

	.leave
	ret
CwordGenViewZoomToggle		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CGVSetPuzzleData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordGenViewClass

		cl - number of rows
RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CGVSetPuzzleData	method dynamic CwordGenViewClass, 
						MSG_CGV_SET_PUZZLE_DATA
	uses	dx
	.enter

	mov	ds:[di].CGV_showWholePuzzle,SWP_MAYBE
	mov	ds:[di].CGV_numColumns,cl
	tst	cl
	jz	disableZoom

done:
	.leave
	ret

disableZoom:
	mov	ax,MSG_GEN_SET_NOT_ENABLED
	mov	dl,VUM_NOW
	call	CwordGenViewMessageToZoomButton
	jmp	done

CGVSetPuzzleData		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordGenViewEnableDisableZoomButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enabled button if in SWP_YES mode or if view is
		smaller than the view doc bounds

CALLED BY:	CwordGenViewSetViewSize

PASS:		*ds:si - CwordGenViewClass
		cx - document size
		dx - view size

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordGenViewEnableDisableZoomButton		proc	near
	class	CwordGenViewClass
	uses	ax,dx,di
	.enter

;;; Verify argument(s)
	Assert	objectPtr	dssi, CwordGenViewClass
;;;;;;;;

	mov	di,ds:[si]
	add	di,ds:[di].CwordGenView_offset
	
	; If no puzzle then disabled
	;

	tst	ds:[di].CGV_numColumns
	jz	disabled

	;    If showing whole puzzle on purpose then always enable
	;    so the user can get back to maybe mode
	;

	cmp	ds:[di].CGV_showWholePuzzle, SWP_YES
	je	enabled
	
	;    If the document is larger than the view
	;    then enable

	cmp	cx,dx
	jbe	disabled


enabled:
	mov	ax,MSG_GEN_SET_ENABLED

sendMessage:
	mov	dl,VUM_NOW
	call	CwordGenViewMessageToZoomButton

	.leave
	ret

disabled:
	mov	ax,MSG_GEN_SET_NOT_ENABLED
	jmp	sendMessage

CwordGenViewEnableDisableZoomButton		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordGenViewMessageToZoomButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	Send message to Zoombutton

PASS:		ax - message
		cx,dx,bp  - data
		ds - must be object block

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordGenViewMessageToZoomButton		proc	near
	uses	bx,si,di
	.enter

	mov	bx, handle ZoomButton		; single-launchable
	mov	si,offset ZoomButton
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
CwordGenViewMessageToZoomButton		endp


CwordBoardBoundsCode	ends
