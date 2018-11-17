COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User interface/Text
FILE:		textScroll.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Low level utility routines for implementing the methods defined on
	VisTextClass.

	$Id: textScroll.asm,v 1.1 97/04/07 11:18:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextInstance segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextGetScrollAmount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle MSG_VIS_TEXT_GET_SCROLL_AMOUNT.

CALLED BY:	via MSG_VIS_TEXT_GET_SCROLL_AMOUNT.
PASS:		*ds:si	= Instance ptr
		ss:bp	= Pointer to TrackScrollingParams, all arguments
			  already set up by a call to GenSetupNormalizeArgs.
RETURN:		dx	= Amount to scroll
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	There are a few different cases to be dealt with here. If the visual
	bounds of the object are the same as that of the text then simple
	cases emerge. We also need to be able to handle the more complex case
	of the text being smaller than the visual bounds of the object.

	if (SA_TO_BEGINNING || SA_TO_END || SA_DRAGGING) {
	    amount = suggestedScrollAmount
	} else {
	    /* Handle specially */
	}
	return( amount )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextGetScrollAmount	method dynamic	VisTextClass, 
			MSG_VIS_TEXT_GET_SCROLL_AMOUNT

	call	TextGStateCreate
	mov	dx, ss:[bp].TSP_change.PD_y.low	; dx <- suggestion.

	mov	al, ss:[bp].TSP_action		; al <- action type.
	cmp	al, SA_NOTHING			; Use the passed value
	je	done				;   on these actions:
	cmp	al, SA_TO_BEGINNING		;	NOTHING
	je	done				;	TO_BEGINNING
	cmp	al, SA_TO_END			;	TO_END
	je	done				;	DRAGGING
	cmp	al, SA_DRAGGING			;	INITIAL_POS
	je	done				;	SCROLL_INTO
	cmp	al, SA_INITIAL_POS
	je	done
	cmp	al, SA_SCROLL_INTO
	je	done

	;
	; Nothing too simple.  First, set up current window offset, size.
	;
	cmp	al, SA_INC_BACK			; Check for line-up.
	jne	notLineUp
	call	ScrollLineUp			;    dx <- amount to scroll.
	jmp	done

notLineUp:
	cmp	al, SA_INC_FWD			; Check for line-down.
	jne	notLineDown
	call	ScrollLineDown			;    dx <- amount to scroll.
	jmp	done

notLineDown:
	cmp	al, SA_PAGE_BACK		; Check for page-up.
	jne	notPageUp
	call	ScrollPageUp			;    dx <- amount to scroll.
	jmp	done

notPageUp:
	;
	; Must be a page-down operation.
	;
EC <	cmp	al, SA_PAGE_FWD			; Check for page-down.	>
EC <	ERROR_NZ VIS_TEXT_INVALID_SCROLL_OPERATION			>

	call	ScrollPageDown			;    dx <- amount to scroll.

done:
	;
	; dx.ax = amount to scroll, if dx.ax = 0, return the suggestion.
	;
	tstdw	dxax
	jnz	validScrollAmount
	movdw	dxax, ss:[bp].TSP_change.PD_y
validScrollAmount:

	;
	; For now we only use 16 bits of data
	;
	mov	dx, ax
	call	TextGStateDestroy

	ret
VisTextGetScrollAmount	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollLineUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the amount to scroll in order to scroll up one line.

CALLED BY:	ScrollPageUp, VisTextGetScrollAmount
PASS:		*ds:si	= Instance ptr
		ss:bp	= Pointer to TrackScrollingParams
		ss:[bp].TSP_oldOrigin.PD_y = top of window.

RETURN:		dx.ax	= amount to scroll.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	topLine  = TextDrawCheckMask()
	topLineY = LineInfoToPosition()
	amount   = oldOffset - topLineY
	if (amount == 0) {
	    /* The top line is perfectly aligned with the window top */
	    prevLine = LineInfoPrevious( topLine )
	    if (noPrevLine) {
	        amount = suggestion
	    } else {
		amount = LineInfoToPosition( prevLine ) - oldOffset
	    }
	}
	return( amount )

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollLineUp	proc	near
	push	bx, cx, di

	movdw	dxax, ss:[bp].TSP_oldOrigin.PD_y	; dx.ax <- window top
	movdw	cxbx, ss:[bp].TSP_oldOrigin.PD_x	; cx.bx <- window left
	call	TL_LineFromExtPosition			; bx.di <- top line
	
	pushdw	bxdi					; Save top line
	call	TL_LineToExtPosition			; cx.bx <- line left
							; dx.ax <- line top
	popdw	bxdi					; Restore top line

	;
	; *ds:si= Instance ptr
	; bx.di	= Top line
	; dx.ax	= Top edge of top line
	;
						; dx.ax <- offset to move
	subdw	dxax, ss:[bp].TSP_oldOrigin.PD_y

	tstdw	dxax				; Check for having an amount
	jnz	done				;   to scroll.

	;
	; The top line is correctly aligned, scroll the previous line on.
	;
	call	TL_LinePrevious			; bx.di <- previous line
	jc	useSuggestion			; No previous, use suggestion

	call	TL_LineToExtPosition		; cx.bx <- line left
						; dx.ax <- line top
	subdw	dxax,ss:[bp].TSP_oldOrigin.PD_y	; dx.ax <- amount to scroll
	
	jmp	done

useSuggestion:
	movdw	dxax, ss:[bp].TSP_change.PD_y	; dx.ax <- suggestion

done:
	;
	; dx.ax	= Amount to scroll.
	;
TextInstance_CheckTooMuchUp_DoPopRV_BX_CX_DI_retn	label	near
	call	CheckTooMuchUp

TextInstance_DoPopRV_BX_CX_DI_retn	label	near
	pop	bx, cx, di
	ret

ScrollLineUp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollLineDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the amount to scroll to scroll down one line.

CALLED BY:	ScrollPageDown, VisTextGetScrollAmount
PASS:		*ds:si	= Instance ptr
		ss:bp	= Pointer to TrackScrollingParams
RETURN:		dx.ax	= Amount to scroll
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	topLine  = TextDrawCheckMask()
	nextLine = LineInfoNext( topLine )
	if (noNextLine) {
	    amount = suggestion
	} else {
	    amount = LineInfoToPosition( nextLine ) - oldOffset
	}
	/*
	 * We need a special check here to see if we might be scrolling too
	 * far.
	 */
	if (oldOffset + amount > objBottom) {
	    amount = objBottom - oldOffset
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollLineDown	proc	near
	push	bx, cx, di

	movdw	dxax, ss:[bp].TSP_oldOrigin.PD_y ;dx.ax <- window top
	movdw	cxbx, ss:[bp].TSP_oldOrigin.PD_x ;cx.bx <- window left
	call	TL_LineFromExtPosition		; bx.di <- line at window top

tryNext:
	;
	; bx.di	= Current line
	; dx.ax	= Top of window
	;
	call	TL_LineNext			; bx.di <- next line
	jc	useSuggestion			; Use suggested if no next line

	push	bp				; Save frame ptr
	push	bx, dx, ax			; Save line.high, window top
	call	TL_LineToExtPosition		; cx.bx <- line left
						; dx.ax <- line top
	movdw	cxbp, dxax			; cx.bp <- line top
	pop	bx, dx, ax			; Restore line.high, window top

	;
	; cx.bp	= top of next line
	; dx.ax	= top of window
	;
	; It is useful to notice that the top of the next line is always
	; larger than the top of the window.
	;
	subdw	dxax, cxbp			; dx.ax <- -1 * amount to scroll
	negdw	dxax				; dx.ax <- amount to scroll
	pop	bp				; Restore frame ptr

	tstdw	dxax				; Loop until we will scroll
	jnz	done				; Branch if something to scroll

	movdw	dxax, ss:[bp].TSP_oldOrigin.PD_y
	jmp	tryNext

useSuggestion:
	movdw	dxax, ss:[bp].TSP_change.PD_y	; dx <- suggestion.

done:

TextInstance_CheckTooMuchDown_DoPopRV_BX_CX_DI_retn	label	near

	call	CheckTooMuchDown		; Make sure we don't go too far

	jmp	TextInstance_DoPopRV_BX_CX_DI_retn
ScrollLineDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollPageUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the amount to scroll to scroll up one page.

CALLED BY:	VisTextGetScrollAmount
PASS:		*ds:si	= Instance ptr
		ss:bp	= Pointer to TrackScrollingParams
RETURN:		dx.ax	= Amount to scroll
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollPageUp	proc	near
	class	VisTextClass

	push	bx, cx, di

	;
	; Get the new position and find the line at that position
	;
	movdw	dxax, ss:[bp].TSP_newOrigin.PD_y ; dx.ax <- window top

	call	TextInstance_DerefVis_DI	; ds:di <- instance ptr
	sub	al, ds:[di].VTI_tbMargin	; Adjust for what's visible.
	sbb	ah, 0
	sbb	dx, 0

	;
	; dx.ax	= New window top (Y position)
	;
	movdw	cxbx, ss:[bp].TSP_newOrigin.PD_x ; cx.bx <- X position
	call	TL_LineFromExtPosition		; bx.di <- new top line
	call	TL_LineToExtPosition		; cx.bx <- line left
						; dx.ax <- line top

	subdw	dxax, ss:[bp].TSP_oldOrigin.PD_y ;dx.ax <- amount to scroll.
	
	jmp	TextInstance_CheckTooMuchUp_DoPopRV_BX_CX_DI_retn
ScrollPageUp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScrollPageDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the amount to scroll to scroll down one page.

CALLED BY:	VisTextGetScrollAmount
PASS:		*ds:si	= Instance ptr
		ss:bp	= Pointer to TrackScrollingParams
RETURN:		dx.ax	= Amount to scroll.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Basically move the last line to the top.
	Special cases are made for the following:
	    - The window is too short so that the last line is the first line.
	      This is handled by just using ScrollLineDown().
	    - There isn't enough text to scroll that far.
	      This is handled by CheckTooMuchDown().

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScrollPageDown	proc	near
	class	VisTextClass

	push	bx, cx, di

	movdw	dxax, ss:[bp].TSP_newOrigin.PD_y

	call	TextInstance_DerefVis_DI	; ds:di <- instance ptr
	sub	al, ds:[di].VTI_tbMargin	; Account for margin
	sbb	ah, 0
	sbb	dx, 0

	movdw	cxbx, ss:[bp].TSP_newOrigin.PD_x
	call	TL_LineFromExtPosition		; bx.di <- last line
						; carry set if below last line
	jc	useLargeScroll

	call	TL_LineToExtPosition		; cx.bx <- left of last line
						; dx.ax <- top of last line
gotPos:
	subdw	dxax, ss:[bp].TSP_oldOrigin.PD_y ;dx.ax <- amount to scroll.

	;
	; The result could be negative, if, for instance, a huge
	; graphic is pasted into a text object that starts on a line
	; above the current origin. If so, just use the suggested change.
	;

	jns	continue
	movdw	dxax, ss:[bp].TSP_change.PD_y

continue:
	jmp	TextInstance_CheckTooMuchDown_DoPopRV_BX_CX_DI_retn

useLargeScroll:
	movdw	dxax, -1			; Scroll to the bottom
	jmp	gotPos
ScrollPageDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTooMuchDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we don't scroll down beyond the bottom of the
		object.

CALLED BY:	ScrollPageDown, VisTextGetScrollAmount
PASS:		ss:bp	= TrackScrollingParams structure on stack.
		*ds:si	= Instance ptr
		dx.ax	= Amount we want to scroll down
RETURN:		dx.ax	= Amount to scroll down
DESTROYED:	cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; The distance from the bottom of the object where we just snap to the
; object bottom if scrolling down.
;
MYSTERIOUS_DAVE_BUTLER_CONSTANT_TO_GET_TO_OBJECT_BOTTOM = 5

CheckTooMuchDown	proc	near
	class	VisTextClass
	uses	di
	.enter
	;
	; Need to check to make sure that we aren't scrolling too far.
	; dx.ax	= Amount we want to scroll
	; ds:di	= Instance ptr
	;
	movdw	cxbx, dxax			; cx.bx <- amount to scroll

	adddw	cxbx, ss:[bp].TSP_oldOrigin.PD_y ;cx.bx <- new window top
	add	bx, ss:[bp].TSP_viewHeight	; cx.bx <- new window bottom
	adc	cx, 0
	decdw	cxbx				; Make zero based

	call	TextInstance_DerefVis_DI	; ds:di <- instance ptr

	;
	; cx.bx	= The current bottom of the window in document coordinates.
	;	  If this is greater than the bottom of the object, then
	;	  we need to scroll only to the bottom of the text.
	;
	;	  Thus the formula is:
	;		if (newBot < textBottom) then
	;			scroll is OK
	;
	;	  We do this test with:
	;		if (newBot - textBottom < 0) then
	;			scroll is OK
	;
	sub	bx, ds:[di].VI_bounds.R_bottom
	sbb	cx, 0
	sub	bx, MYSTERIOUS_DAVE_BUTLER_CONSTANT_TO_GET_TO_OBJECT_BOTTOM
	sbb	cx, 0
	
	js	amountOK

	;
	; The scroll will get us so close to the bottom that we really want to
	; branch all the way there.
	;
	clr	dx				; dx.ax <- bottom of object
	mov	ax, ds:[di].VI_bounds.R_bottom

	subdw	dxax, ss:[bp].TSP_oldOrigin.PD_y ;Remove bottom of window

	sub	ax, ss:[bp].TSP_viewHeight	; Remove height of view
	sbb	dx, 0

	incdw	dxax				; Make it one based

amountOK:

	;
	; Hack added 6/12/95 -jw
	;
	; If we are scrolling down, we should never return a negative
	; offset (ie: we shouldn't scroll back up)
	;
	tst	dx
	jns	reallyDoneNow
	clrdw	dxax			; Use zero instead of negative value
reallyDoneNow:

	.leave
	ret
CheckTooMuchDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTooMuchUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we don't scroll up more than one screen-full.

CALLED BY:	ScrollLineUp, ScrollPageUp
PASS:		*ds:si	= Instance ptr
		dx	= Amount we want to scroll
RETURN:		dx	= Amount we should scroll
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTooMuchUp	proc	near
	negdw	dxax
	
	;
	; Check to see if the amount we will scroll is greater than the height
	; of the view.
	;
	tst	dx				; View height is 16 bit value
	jnz	useViewHeight

	cmp	ax, ss:[bp].TSP_viewHeight	; Compare low word to view height
	jbe	amountOK

useViewHeight:
	clr	dx				; dx.ax <- view height
	mov	ax, ss:[bp].TSP_viewHeight

amountOK:
	negdw	dxax
	ret
CheckTooMuchUp	endp

TextInstance	ends
