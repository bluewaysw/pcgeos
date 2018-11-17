COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentScroll.asm

ROUTINES:
	Name				Description
	----				-----------
    INT ClearMargins		Handle track scrolling

    INT TrackScrollingCommon	Common routine to do track scrolling for
				both the main content and master pages

    INT ScrollDoNothing		Common routine to do track scrolling for
				both the main content and master pages

    INT ScrollResize		Handle scrolling when the view or content
				has been resized

    INT HandleScaleToFit	Handle scrolling when the view or content
				has been resized

    INT ScrollLiveText		Handle scrolling when we want to restrict
				to the live text area

    INT LiveTextCommon		Handle scrolling when we want to restrict
				to the live text area

    INT ScrollGotoEdge		Handle scrolling when we want to go to the
				next edge

    INT GotoEdgeCommon		Handle scrolling when we want to go to the
				next edge

    INT ScrollIncrement		Handle scrolling when we want to go to the
				next edge only if we're at an edge

    INT ScrollPage		Handle scrolling when we want to go to the
				next edge only if we're at an edge

    INT LoadDimension		Load the variables from a given dimension
				into the stack frame

    INT StoreDimension		Store the new position for a dimension

    INT LoadSide		Load either the left or the right variables
				into the "left" variables depending on
				WSF_FORWARD

    INT ConvertNewPos		Load either the left or the right variables
				into the "left" variables depending on
				WSF_FORWARD

    INT StoreSide		Convert newPos to the correct value if
				we're working on the right side

METHODS:
	Name			Description
	----			-----------
    StudioDocumentTrackScrolling Handle track scrolling

				MSG_META_CONTENT_TRACK_SCROLLING
				StudioDocumentClass

    StudioMasterPageContentTrackScrolling  
				Handle track scrolling

				MSG_META_CONTENT_TRACK_SCROLLING
				StudioMasterPageContentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the track scrolling code

	$Id: documentScroll.asm,v 1.1 97/04/04 14:39:04 newdeal Exp $

------------------------------------------------------------------------------@

DocDrawScroll segment resource

TRACK_SCROLLING_LOCALS	equ	<\
.warn -unref_local\
margins		local	Rectangle\
pageHeight	local	word\
docBounds	local	RectDWord\
mode		local	VisLargeTextDisplayModes\
viewSize	local	sdword\
oldPos		local	sdword\
newPos		local	sdword\
docLeft		local	sdword\
pageLeft	local	sdword\
liveTextLeft	local	sdword\
liveTextRight	local	sdword\
pageRight	local	sdword\
docRight	local	sdword\
.warn @unref_local\
>

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentTrackScrolling --
		MSG_META_CONTENT_TRACK_SCROLLING for StudioDocumentClass

DESCRIPTION:	Handle track scrolling

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	bp - TrackScrollingParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 6/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentTrackScrolling	method dynamic	StudioDocumentClass,
					MSG_META_CONTENT_TRACK_SCROLLING
TRACK_SCROLLING_LOCALS
	.enter

	call	LockMapBlockES
	mov	cx, es:MBH_displayMode
	call	VMUnlockES

	mov	ax, ds:[di].SDI_pageHeight
	mov	pageHeight, ax

	call	ClearMargins

	; load the document bounds

	clr	bx
copyLoop:
	movdw	dxax, ds:[di][bx].SDI_size.PD_x
	cmp	cx, VLTDM_PAGE
	jnz	10$
	adddw	dxax, PAGE_BORDER_SIZE
10$:
	push	bp
	add	bp, bx
	movdw	docBounds.RD_right, dxax
	pop	bp
	add	bx, size dword
	cmp	bx, (size dword) * 2
	jnz	copyLoop

	; load the margins.  we kick the margins out a couple of pixels so that
	; the dotted line will just show

	cmp	cx, VLTDM_PAGE
	jnz	noMargins

	mov	ax, ds:[di].SDI_currentSection
	call	LockMapBlockES

	; if the target is the grobj body then no margins

	push	bx, si, ds, es
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	movdw	bxsi, ds:[di].VCNI_targetExcl.FTVMC_OD
	tst	bx				;if no target then act as if
	stc					;an article was the target
	jz	afterTarget
	call	ObjLockObjBlock
	mov	ds, ax				;*ds:si = target
	mov	di, segment VisTextClass
	mov	es, di
	mov	di, offset VisTextClass
	call	ObjIsObjectInClass		;carry set if an article
	call	MemUnlock
afterTarget:
	pop	bx, si, ds, es
	jnc	afterMargins

	call	SectionArrayEToP_ES		;es:di = section element
	mov	cx, 4
	push	bp
copyRectLoop:
	mov	ax, es:[di].SAE_leftMargin
	add	ax, 4
	shr	ax
	shr	ax
	shr	ax
	sub	ax, SCROLLING_MARGIN_INSET
	mov	margins.R_left, ax
	add	di, size word
	add	bp, size word
	loop	copyRectLoop
	pop	bp
afterMargins:

	call	VMUnlockES
noMargins:

	call	TrackScrollingCommon
	.leave
	ret

StudioDocumentTrackScrolling	endm

;---

	; cx = DisplayMode

ClearMargins	proc	near
	.enter inherit StudioDocumentTrackScrolling
	class	StudioDocumentClass

	mov	mode, cx

	clr	ax
	mov	margins.R_left, ax
	mov	margins.R_top, ax
	mov	margins.R_right, ax
	mov	margins.R_bottom, ax

	clrdw	dxax
	cmp	cx, VLTDM_PAGE
	jnz	10$
	movdw	dxax, -PAGE_BORDER_SIZE
10$:
	movdw	docBounds.RD_left, dxax
	movdw	docBounds.RD_top, dxax

	.leave
	ret
ClearMargins	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageContentTrackScrolling --
		MSG_META_CONTENT_TRACK_SCROLLING for StudioMasterPageContentClass

DESCRIPTION:	Handle track scrolling

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageContentClass

	ax - The message

	bp - TrackScrollingParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 6/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageContentTrackScrolling	method dynamic	\
					StudioMasterPageContentClass,
					MSG_META_CONTENT_TRACK_SCROLLING
TRACK_SCROLLING_LOCALS
	.enter

	; master pages always operate in page mode with no margins

	mov	cx, VLTDM_PAGE
	call	ClearMargins

	clr	dx
	mov	ax, ds:[di].VI_bounds.R_right
	add	ax, PAGE_BORDER_SIZE
	movdw	docBounds.RD_right, dxax
	mov	ax, ds:[di].VI_bounds.R_bottom
	add	ax, PAGE_BORDER_SIZE
	movdw	docBounds.RD_bottom, dxax
	add	ax, PAGE_BORDER_SIZE
	mov	pageHeight, ax

	call	TrackScrollingCommon

	.leave
	ret

StudioMasterPageContentTrackScrolling	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	TrackScrollingCommon

DESCRIPTION:	Common routine to do track scrolling for both the main content
		and master pages

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent object
	ss:bp - TrackScrollingParams

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

Track scrolling is a complex process.  We get as input a whole lot of
information from the GenView about what type of operation is going on and
what type of movement the view wants to perform.  We massage this data
and return what we really want to happen.

We start by taking the action passed (a ScrollAction) and mapping it into
a class of actions.  Each class of actions is handled specially.  The
behavior of each class is described below.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 6/92		Initial version

------------------------------------------------------------------------------@

; This table maps scroll actions to our actions

StudioScrollClass	etype	byte
WSC_DO_NOTHING		enum	StudioScrollClass
	; Return exactly what the view sent us.  This is used for unrecognized
	; types and for panning

WSC_RESIZE		enum	StudioScrollClass
	; The view or the content has been resized.  Do the action requested
	; unless it crosses an edge when it should not.

WSC_LIVE_TEXT		enum	StudioScrollClass
	; Restrict the scrolling to the live text area.

WSC_GOTO_EDGE		enum	StudioScrollClass
	; The user asked to go to the beginning or end.  We want to translate
	; this to the next logical edge (live text edge, page edge or
	; content edge)

WSC_INCREMENT		enum	StudioScrollClass
	; The user asked to go up or down some.  We will let this happen
	; unless it would go over an edge, in which case we will stop at that
	; edge

WSC_PAGE		enum	StudioScrollClass
	; The user asked to go up or down some.  We will let this happen
	; unless it would go over an edge, in which case we will stop at that
	; edge

StudioScrollFlags	record
    WSF_BOTH_DIMENSIONS:1
    WSF_FORWARD:1
StudioScrollFlags	end

StudioScrollAction	struct
    WSA_class		StudioScrollClass
    WSA_flags		StudioScrollFlags
StudioScrollAction	ends


scrollTable	StudioScrollAction	\
	<WSC_DO_NOTHING, 0>,			;SA_NOTHING
	<WSC_GOTO_EDGE, 0>,			;SA_TO_BEGINNING
	<WSC_PAGE, 0>,				;SA_PAGE_BACK
	<WSC_INCREMENT, 0>,			;SA_INC_BACK
	<WSC_INCREMENT, mask WSF_FORWARD>,	;SA_INC_FWD
	<WSC_DO_NOTHING, 0>,			;SA_DRAGGING
	<WSC_PAGE, mask WSF_FORWARD>,		;SA_PAGE_FWD
	<WSC_GOTO_EDGE, mask WSF_FORWARD>,	;SA_TO_END
	<WSC_DO_NOTHING, mask WSF_BOTH_DIMENSIONS>, ;SA_SCROLL
	<WSC_LIVE_TEXT, mask WSF_BOTH_DIMENSIONS>, ;SA_SCROLL_INTO
	<WSC_RESIZE, mask WSF_BOTH_DIMENSIONS>,	;SA_INITIAL_POS
	<WSC_RESIZE, mask WSF_BOTH_DIMENSIONS>,	;SA_SCALE
	<WSC_DO_NOTHING, mask WSF_BOTH_DIMENSIONS>, ;SA_PAN
	<WSC_LIVE_TEXT, mask WSF_BOTH_DIMENSIONS>, ;SA_DRAG_SCROLL
	<WSC_RESIZE, mask WSF_BOTH_DIMENSIONS>	;SA_SCROLL_FOR_SIZE_CHANGE

scrollHandlers	nptr	\
	ScrollDoNothing,	;WSC_DO_NOTHING
	ScrollResize,		;WSC_RESIZE
	ScrollLiveText,		;WSC_LIVE_TEXT
	ScrollGotoEdge,		;WSC_GOTO_EDGE
	ScrollIncrement,	;WSC_INCREMENT
	ScrollPage		;WSC_PAGE


TrackScrollingCommon	proc	near
	.enter inherit StudioDocumentTrackScrolling

	; setup arguments

	push	bp
	mov	bp, ss:[bp]
	call	GenSetupTrackingArgs
	mov	al, ss:[bp].TSP_flags
	and	al, mask SF_VERTICAL			;al = vertical flag
	pop	bp

	; map the scroll action into our data

	mov	di, ss:[bp]
	clr	bx
	mov	bl, ss:[di].TSP_action
	shl	bx
	mov	cx, {word} cs:[scrollTable][bx]

	; cl = StudioScrollClass, ch = scroll flags

	mov	bl, cl
	mov	cl, al					;cl = vertical flag
	shl	bx
	call	cs:[scrollHandlers][bx]

	; the various handlers just fill in the absolute new position
	; we need to calculate the relative moves also

	push	bp
	mov	bp, ss:[bp]
	movdw	dxax, ss:[bp].TSP_newOrigin.PD_x
	subdw	dxax, ss:[bp].TSP_oldOrigin.PD_x
	movdw	ss:[bp].TSP_change.PD_x, dxax
	movdw	dxax, ss:[bp].TSP_newOrigin.PD_y
	subdw	dxax, ss:[bp].TSP_oldOrigin.PD_y
	movdw	ss:[bp].TSP_change.PD_y, dxax

	; tell the view we're finished

	call	GenReturnTrackingArgs
	pop	bp

	.leave
	ret

TrackScrollingCommon	endp

;---

ScrollDoNothing	proc	near
	ret
ScrollDoNothing	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ScrollResize

DESCRIPTION:	Handle scrolling when the view or content has been resized

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	cl - zero for horizontal, non-zero for vertical
	ch - StudioScrollFlags

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

------------------------------------------------------------------------------@
ScrollResize	proc	near
	.enter inherit StudioDocumentTrackScrolling

	test	ch, mask WSF_BOTH_DIMENSIONS
	jz	doOneOnly

	clr	cl
	call	resizeDimension
	inc	cl
doOneOnly:
	call	resizeDimension

	.leave
	ret

;---

resizeDimension:
	call	LoadDimension

	; if the view is wider than the live text area then center it

	movdw	dxax, viewSize
	adddw	dxax, liveTextLeft		;- (right-left)
	subdw	dxax, liveTextRight
	jb	viewNotWider
	shrdw	dxax
	negdw	dxax
	adddw	dxax, liveTextLeft
	movdw	newPos, dxax
	jmp	done

	; the document is wider than the view.  Make sure that we are not
	; over either live text edge

viewNotWider:
	call	LiveTextCommon

	; if we are in "scale to fit" mode then round to a page boundry

	call	HandleScaleToFit

done:
	call	StoreDimension
	retn

ScrollResize	endp

;---

	; Handle scale to fit mode if needed

HandleScaleToFit	proc	near
	.enter inherit StudioDocumentTrackScrolling

	mov	di, ss:[bp]			;ss:di = TrackScrollingParams
	test	ss:[di].TSP_flags, mask SF_SCALE_TO_FIT
	jz	done
	tst	cl				;only do for vertical
	jz	done
	movdw	dxax, newPos
	subdw	dxax, pageLeft
	tst	dx
	js	zero
	div	pageHeight			;ax = result
	shl	dx
	cmp	dx, pageHeight
	jl	noRound
	inc	ax
noRound:
	mul	pageHeight
zero:
	adddw	dxax, pageLeft
	movdw	newPos, dxax
done:
	.leave
	ret

HandleScaleToFit	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ScrollLiveText

DESCRIPTION:	Handle scrolling when we want to restrict to the live
		text area

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	cl - zero for horizontal, non-zero for vertical
	ch - StudioScrollFlags

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

------------------------------------------------------------------------------@
ScrollLiveText	proc	near
	.enter inherit StudioDocumentTrackScrolling

	test	ch, mask WSF_BOTH_DIMENSIONS
	jz	doOneOnly

	clr	cl
	call	liveTextDimension
	inc	cl
doOneOnly:
	call	liveTextDimension

	.leave
	ret

;---

liveTextDimension:
	call	LoadDimension

	; if the request is zero in a dimension then don't scroll that way

	cmpdw	oldPos, newPos, ax
	jz	noChange

	; if the view is wider than the live text area then make sure the
	; entire live text area is visible

	movdw	dxax, viewSize
	adddw	dxax, liveTextLeft		;- (right-left)
	subdw	dxax, liveTextRight
	jb	viewNotWider

	; if newPos is to the right of the left edge of the live text then
	; move it to the right edge of the live text

	movdw	dxax, newPos
	movdw	bxdi, liveTextLeft
	jledw	dxax, bxdi, 10$
	movdw	dxax, bxdi
10$:

;	; if newPos is too far left then move it right

	movdw	bxdi, liveTextRight
	subdw	bxdi, viewSize
	jgedw	dxax, bxdi, fitsOK
	movdw	dxax, bxdi
20$:
	movdw	newPos, dxax
	jmp	done

	; at this point we have figured that we are showing the entire
	; live text area, so we don't want to move at all

fitsOK:
	movdw	dxax, oldPos
	jmp	20$

viewNotWider:
	call	LiveTextCommon

done:
	call	StoreDimension
noChange:
	retn

ScrollLiveText	endp

;---

	; force the new position to be inside the live text area

LiveTextCommon	proc	near
	.enter inherit StudioDocumentTrackScrolling

	movdw	bxdi, newPos
	movdw	dxax, liveTextLeft
	jgedw	dxax, bxdi, useDXAX

	movdw	dxax, liveTextRight
	subdw	dxax, viewSize
	jgdw	dxax, bxdi, done
useDXAX:
	movdw	newPos, dxax
done:
	.leave
	ret

LiveTextCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ScrollGotoEdge

DESCRIPTION:	Handle scrolling when we want to go to the next edge

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	cl - zero for horizontal, non-zero for vertical
	ch - StudioScrollFlags

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

------------------------------------------------------------------------------@
ScrollGotoEdge	proc	near
	.enter inherit StudioDocumentTrackScrolling

	call	LoadDimension
	call	LoadSide

	; we now operate on the "left" variables only

	call	GotoEdgeCommon
	call	StoreSide
	call	StoreDimension

	.leave
	ret

ScrollGotoEdge	endp

;---

GotoEdgeCommon	proc	near
	.enter inherit StudioDocumentTrackScrolling

	; if we're to the right of the live text then go to the edge of the
	; live text

	movdw	bxdi, oldPos
	movdw	dxax, liveTextLeft
	jgdw	bxdi, dxax, done

	; if we're to the right of the page edge then go to the page edge

	movdw	dxax, pageLeft
	jgdw	bxdi, dxax, done

	movdw	dxax, docLeft
done:
	movdw	newPos, dxax
	.leave
	ret
GotoEdgeCommon	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ScrollIncrement

DESCRIPTION:	Handle scrolling when we want to go to the next edge only
		if we're at an edge

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	cl - zero for horizontal, non-zero for vertical
	ch - StudioScrollFlags

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

------------------------------------------------------------------------------@
ScrollIncrement	proc	near
	.enter inherit StudioDocumentTrackScrolling

	call	LoadDimension
	call	LoadSide

	; we now operate on the "left" variables only

	; if we're to the right of the live text we're fine

	movdw	bxdi, newPos
	movdw	dxax, liveTextLeft
	jgdw	bxdi, dxax, done

	call	GotoEdgeCommon
	call	StoreSide
	call	StoreDimension
done:
	.leave
	ret

ScrollIncrement	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ScrollPage

DESCRIPTION:	Handle scrolling when we want to go to the next edge only
		if we're at an edge

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	cl - zero for horizontal, non-zero for vertical
	ch - StudioScrollFlags

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

------------------------------------------------------------------------------@
ScrollPage	proc	near
	.enter inherit StudioDocumentTrackScrolling

	call	LoadDimension
	call	LoadSide

	; we now operate on the "left" variables only

	; if in scale to fit mode then handle this specially

	mov	di, ss:[bp]			;ss:di = TrackScrollingParams
	test	ss:[di].TSP_flags, mask SF_SCALE_TO_FIT
	jz	notScaleToFit
	tst	cl				;only do for vertical
	jz	notScaleToFit

	movdw	dxax, oldPos
	sub	ax, pageHeight
	sbb	dx, 0
	jgedw	dxax, docLeft, noWrap
	movdw	dxax, docLeft
noWrap:
	movdw	newPos, dxax
	call	HandleScaleToFit
	jmp	done

notScaleToFit:

	; if we're to the right of the live text we're fine (except for
	; scale to fit)

	movdw	bxdi, newPos
	movdw	dxax, liveTextLeft
	jgdw	bxdi, dxax, done

	call	GotoEdgeCommon

done:
	call	StoreSide
	call	StoreDimension
	.leave
	ret

ScrollPage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadDimension

DESCRIPTION:	Load the variables from a given dimension into the stack frame

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	cl - zero for X, non-zero for Y

RETURN:
	oldPos, newPos - set
	docLeft, pageLeft, liveTextLeft - set
	liveTextRight, pageRight, docRight - set

DESTROYED:
	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 6/92		Initial version

------------------------------------------------------------------------------@
LoadDimension	proc	near	uses si, di
	.enter inherit StudioDocumentTrackScrolling

	mov	si, offset TSP_viewWidth
	lea	di, viewSize
	call	copyTSPWord

	mov	si, offset TSP_oldOrigin
	lea	di, oldPos
	call	copyTSPDword

	mov	si, offset TSP_newOrigin
	lea	di, newPos
	call	copyTSPDword

	lea	si, docBounds.RD_left
	lea	di, docLeft
	call	copyFrameDword			;dxax = left
	cmp	mode, VLTDM_PAGE
	jnz	noPageBorder
	adddw	dxax, PAGE_BORDER_SIZE
noPageBorder:
	movdw	pageLeft, dxax
	tst	cl
	jnz	addTopMargin
	add	ax, margins.R_left
	jmp	marginCommon
addTopMargin:
	add	ax, margins.R_top
marginCommon:
	adc	dx, 0
	movdw	liveTextLeft, dxax

	lea	si, docBounds.RD_right
	lea	di, docRight
	call	copyFrameDword			;dxax = right
	cmp	mode, VLTDM_PAGE
	jnz	noPageBorder2
	subdw	dxax, PAGE_BORDER_SIZE
noPageBorder2:
	movdw	pageRight, dxax
	tst	cl
	jnz	subBottomMargin
	sub	ax, margins.R_right
	jmp	marginCommon2
subBottomMargin:
	sub	ax, margins.R_bottom
marginCommon2:
	sbb	dx, 0
	movdw	liveTextRight, dxax

	.leave
	ret

;---

	; ss:[track scrolling args][si] = source, ss:[di] = dest

copyTSPWord:
	add	si, ss:[bp]
	tst	cl
	jz	10$
	add	si, size word
10$:
	clr	dx
	mov	ax, ss:[si]
	movdw	ss:[di], dxax
	retn

;---

	; ss:[track scrolling args][si] = source, ss:[di] = dest

copyTSPDword:
	add	si, ss:[bp]

	; ss:[si] = source, ss:[di] = dest

copyFrameDword:
	tst	cl
	jz	20$
	add	si, size dword
20$:
	movdw	dxax, ss:[si]
	movdw	ss:[di], dxax
	retn

LoadDimension	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StoreDimension

DESCRIPTION:	Store the new position for a dimension

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	cl - zero for X, non-zero for Y
	newPos - position to store

RETURN:
	none

DESTROYED:
	ax, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 6/92		Initial version

------------------------------------------------------------------------------@
StoreDimension	proc	near
	.enter inherit StudioDocumentTrackScrolling

	mov	di, offset TSP_newOrigin 
	add	di, ss:[bp]
	tst	cl
	jz	10$
	add	di, size dword
10$:
	movdw	ss:[di], newPos, ax

	.leave
	ret

StoreDimension	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadSide

DESCRIPTION:	Load either the left or the right variables into the "left"
		variables depending on WSF_FORWARD

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	ch - StudioScrollFlags

RETURN:
	docLeft, pageLeft, liveTextLeft, newPos - set

DESTROYED:
	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 6/92		Initial version

------------------------------------------------------------------------------@
LoadSide	proc	near
	.enter inherit StudioDocumentTrackScrolling

	test	ch, mask WSF_FORWARD
	jz	done
	clrdw	docLeft

	movdw	dxax,docRight
	subdw	dxax, pageRight
	movdw	pageLeft, dxax
	movdw	dxax,docRight
	subdw	dxax, liveTextRight
	movdw	liveTextLeft, dxax

	call	ConvertNewPos

	movdw	dxax,docRight
	subdw	dxax, oldPos
	subdw	dxax, viewSize
	movdw	oldPos, dxax

done:

	.leave
	ret

LoadSide	endp

;---

ConvertNewPos	proc	near
	.enter inherit StudioDocumentTrackScrolling
	movdw	dxax,docRight
	subdw	dxax, newPos
	subdw	dxax, viewSize
	movdw	newPos, dxax
	.leave
	ret
ConvertNewPos	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	StoreSide

DESCRIPTION:	Convert newPos to the correct value if we're working on the
		right side

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisContent
	ss:bp - inherited variables
	ch - StudioScrollFlags

RETURN:
	newPos - set

DESTROYED:
	ax, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 6/92		Initial version

------------------------------------------------------------------------------@
StoreSide	proc	near
	.enter inherit StudioDocumentTrackScrolling

	test	ch, mask WSF_FORWARD
	jz	done
	call	ConvertNewPos
done:

	.leave
	ret

StoreSide	endp

DocDrawScroll ends
