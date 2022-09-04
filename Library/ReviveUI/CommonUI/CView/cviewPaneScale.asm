COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OpenLook/View
FILE:		cviewPaneScale.asm

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version
	Chris	2/91		Started V2.0

DESCRIPTION:
	This file implements the Open Look pane object.


	$Id: cviewPaneScale.asm,v 1.30 96/07/02 14:22:12 skarpi Exp $
-------------------------------------------------------------------------------@

ViewCommon segment resource

COMMENT @----------------------------------------------------------------------

ROUTINE:	SendNewScaleToOD

SYNOPSIS:	Sends new scale to OD.

CALLED BY:	OLPaneScroll

PASS:		*ds:si -- pane
		dx:cx  -- x scale factor
		bx:ax  -- y scale factor

RETURN:		nothing

DESTROYED:	di, ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/25/91		Initial version

------------------------------------------------------------------------------@
SendNewScaleToOD	proc	far		uses	bp
	.enter
	sub	sp, size ScaleChangedParams	;tell OD our origin changed
	mov	bp, sp

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ss:[bp].SCP_scaleFactor.PF_x.WWF_int, dx
	mov	ss:[bp].SCP_scaleFactor.PF_x.WWF_frac, cx
	mov	ss:[bp].SCP_scaleFactor.PF_y.WWF_int, bx
	mov	ss:[bp].SCP_scaleFactor.PF_y.WWF_frac, ax

	call	PaneGetWindow			;get window in di
	mov	ss:[bp].SCP_window, di
	mov	dx, size ScaleChangedParams
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	mov	ax, MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED
	call	ToAppCommon
	add	sp, size ScaleChangedParams
	.leave
	ret
SendNewScaleToOD	endp

ViewCommon	ends


ViewBuild	segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLPaneSetAttrs -- MSG_GEN_VIEW_SET_ATTRS for OLPaneClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - The message

	cx - bits to set
	dx - bits to reset

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 2/92		Initial version

------------------------------------------------------------------------------@
OLPaneSetAttrs	method dynamic	OLPaneClass, MSG_GEN_VIEW_SET_ATTRS
	or	cx, dx
	test	cx, mask GVA_SCALE_TO_FIT or mask GVA_ADJUST_FOR_ASPECT_RATIO
	jz	done
	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GVI_attrs, mask GVA_CONTROLLED
	jz	done
;
;	This is unnecessary, and seems to cause problems when attrs are set
; 	when geometry hasn't been.   The UpdateScale can change the initial
;	scale value to zero, which dorks up geometry from then on.  cbh 11/16/93
;
;	call	UpdateScale

	call	FullyInvalidateView
done:
	ret

OLPaneSetAttrs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLPaneSetControlledAttrs -- MSG_GEN_VIEW_SET_CONTROLLED_ATTRS
								for OLPaneClass

DESCRIPTION:	Set the controlled attributes

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - The message

	cx - GenViewControlAttrs
	dx - scale (%, or GenViewControlSpecialScaleFactor for scale to fit)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/18/92		Initial version

------------------------------------------------------------------------------@
OLPaneSetControlledAttrs	method dynamic	OLPaneClass,
						MSG_GEN_VIEW_SET_CONTROLLED_ATTRS

	; if APPLY_TO_ALL is set then always respond to this, otherwise only
	; respond if we are the target

	test	cx, mask GVCA_APPLY_TO_ALL
	jnz	handleIt

	test	ds:[di].OLPI_attrs, mask OLPA_APP_TARGET
	jz	done
handleIt:

	push	dx
	push	cx
	mov_tr	ax, cx				;ax = GenViewControlAttrs

	clr	cx				;new attribute bits

	cmp	dx, GVCSSF_TO_FIT
	jnz	notScaleToFit
	ornf	cx, mask GVA_SCALE_TO_FIT
notScaleToFit:

	test	ax, mask GVCA_ADJUST_ASPECT_RATIO
	jz	notAdjust
	ornf	cx, mask GVA_ADJUST_FOR_ASPECT_RATIO
notAdjust:

	mov	dx, mask GVA_SCALE_TO_FIT or mask GVA_ADJUST_FOR_ASPECT_RATIO

	mov	ax, MSG_GEN_VIEW_SET_ATTRS
	call	ObjCallInstanceNoLock

	pop	ax				;ax = GenViewControlAttrs

	mov	cx, mask GVDA_DONT_DISPLAY_SCROLLBAR	;assume OFF
	test	ax, mask GVCA_SHOW_HORIZONTAL
	jz	20$
	xchg	cl, ch
20$:

	mov	dx, mask GVDA_DONT_DISPLAY_SCROLLBAR	;assume OFF
	test	ax, mask GVCA_SHOW_VERTICAL
	jz	30$
	xchg	dl, dh
30$:
	mov	bp, VUM_NOW
	mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	call	ObjCallInstanceNoLock

	pop	dx
	cmp	dx, GVCSSF_TO_FIT
	jz	afterScale

	sub	sp, size ScaleViewParams
	mov	bp, sp
	clr	cx
	mov	bx, 100
	clr	ax
	call	GrUDivWWFixed
	movdw	ss:[bp].SVP_scaleFactor.PF_x, dxcx
	movdw	ss:[bp].SVP_scaleFactor.PF_y, dxcx
	mov	ss:[bp].SVP_type, SVT_AROUND_UPPER_LEFT
	mov	dx, size ScaleViewParams
	mov	ax, MSG_GEN_VIEW_SET_SCALE_FACTOR
	call	ObjCallInstanceNoLock
	add	sp, size ScaleViewParams

afterScale:

done:
	ret

OLPaneSetControlledAttrs	endm

ViewBuild ends

;---

ViewScale segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		OLPaneScale -- METHOD_GEN_VIEW_SET_SCALE_FACTOR for OLPaneClass

DESCRIPTION:	Scale a pane window

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass
	ax - MSG_SCALE_PANE
	ss:[bp] - ScaleViewParams
	dx -- size ScaleViewParams

RETURN:
	nothing
	ax, cx, dx, bp -- trashed

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY (for scaling around a point):
	oldOffset = WinTransform (point)
	WinSetNullTransform
	WinApplyScale (newScaleFactor)
	newOffset = WinUntransformDWord (oldOffset)
	WinApplyTranslation (origin)
	OLPaneScroll (point - newOffset - origin)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
        assumed to be marked dirty by the generic UI.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Chris	2/90		Re-writ to work

------------------------------------------------------------------------------@

OLPaneScale	method OLPaneClass, MSG_GEN_VIEW_SET_SCALE_FACTOR

;	call	FullyInvalidateView
	call	ScaleNoInvalidate
	ret

OLPaneScale	endm

ViewScale	ends

;-------

ViewCommon	segment resource

FullyInvalidateView	proc	far	uses bp
	.enter

	; Invalidate our geometry, so that RerecalcSizes will get to us, and
	; the pane's parent's geometry, so the pane will have a chance to
	; expand.

	push	si
	mov	si, offset VisClass
	mov	bx, segment VisClass
	mov	dl, VUM_NOW			;for the parent
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	pop	si
	
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_VIS_SEND_TO_PARENT	;avoid nested updates
if _RUDY
	;
	; In Responder we found out that the system can run out of handles
	; when queuing these MSG_VIS_MARK_INVALID messages.  So we allow
	; the system to discard the event if the system is low on handles.
	;
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or \
		    mask MF_CAN_DISCARD_IF_DESPERATE
else
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
endif
		
	call	ObjMessage
						; (SetDocSize gets called
						;  during nested updates)

	;
	; View must be done after the parent, as the second MF_INSERT_AT_FRONT
	; message sent will be stuck in the queue in front of the first.
	; (10/28/92 cbh)
	;
	mov	ax, MSG_VIS_MARK_INVALID
	mov	cl, mask VOF_GEOMETRY_INVALID
	mov	dl, VUM_MANUAL
if _RUDY		
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT or \
		    mask MF_CAN_DISCARD_IF_DESPERATE
else
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
endif		
	call	ObjMessage
	.leave
	ret

FullyInvalidateView	endp

ViewCommon	ends

;--------

ViewScale	segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ScaleNoInvalidate

DESCRIPTION:	Scale the pane without invalidating the geometry

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data
	ss:[bp] - ScaleViewParams

RETURN:
	nothing

DESTROYED:
	ax, bx, cx, dx, bp, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 3/92		Initial version

------------------------------------------------------------------------------@
ScaleNoInvalidate	proc	near
	class	OLPaneClass

EC <	cmp	ss:[bp].SVP_type, SVT_AROUND_POINT			>
EC <	ERROR_A	OL_VIEW_BAD_SCALE_TYPE					>

	call	ConvertScaleBasedOnMode

	mov	ax, MSG_GEN_VIEW_SCALE_LOW
	mov	dx, size ScaleViewParams
	call	ObjCallInstanceNoLock
	ret

ScaleNoInvalidate	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLPaneScaleLow -- MSG_GEN_VIEW_SCALE_LOW for OLPaneClass

DESCRIPTION:	Low level scale routine (sent to links)

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - The message

	dx - size ScaleViewParams
	ss:bp - ScaleViewParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/18/92		Initial version

------------------------------------------------------------------------------@
OLPaneScaleLow	method dynamic	OLPaneClass, MSG_GEN_VIEW_SCALE_LOW
	mov	di, mask MF_STACK		;stack frame
	call	GenViewSendToLinksIfNeeded	;use linkage if there
	LONG jc	exit				;we did, we're done now

;	call	FullyInvalidateView		;Moved down...

	call	GetScaleAmount			;scale amounts in dx.cx, bx.ax
	mov	di, ds:[si]			;check instance data
	add	di, ds:[di].Gen_offset
	cmpdw	dxcx, ds:[di].GVI_scaleFactor.PF_x
	jnz	setScale
	cmpdw	bxax, ds:[di].GVI_scaleFactor.PF_y
	jnz	setScale
	ret
setScale:
	;
	; Invalidate should only happen if the scale factor has actually
	; changed.
	;
	call	FullyInvalidateView

	call	GetScaleAmount			;scale amounts in dx.cx, bx.ax
	mov	di, ds:[si]			;store instance data
	add	di, ds:[di].Gen_offset
	movdw	ds:[di].GVI_scaleFactor.PF_x, dxcx
	movdw	ds:[di].GVI_scaleFactor.PF_y, bxax


	; Notify content of our scale change.

	call	GetScaleAmount			;scale amounts in dx.cx, bx.ax
	call	SendNewScaleToOD

	; Fix scale point to be upper left or center of screen, if necessary.

	mov	dx, SSP_VERTICAL		;first do vertical
	call	SetupScalePoint			;sets up point to scale around
	clr	dx				;now do horizontal
	call	SetupScalePoint			;result in ax

	call	ScalePaneGetWindow		;get window in di
	LONG	jz exit				;no window, exit

	push	si
	mov	si, ds:[si]			;mark pane as needing inval
	add	si, ds:[si].Vis_offset
	test	ds:[si].OLPI_flags, mask OLPF_SUSPENDED_FOR_SCALING
	jnz	5$				;window already suspended
						;  somehow, branch

	; if the geometry is not invalid then don't suspend
	; (The FullyInvalidateView above guarantees the geometry invalidation.
	;  and the invalidate is queued, so we should nuke this test.  Otherwise
	;  the suspend never happens.  -cbh 3/27/93)

;	test	ds:[si].VI_optFlags, mask VOF_GEOMETRY_INVALID
;	jz	5$
	or	ds:[si].OLPI_flags, mask OLPF_SUSPENDED_FOR_SCALING
	call	WinSuspendUpdate		;added 10/23/91 cbh to suspend
						;  all drawing at least until
						;  geometry is completed. See
						;  notify-geo-valid handler.
5$:
	pop	si


	; oldOffset = WinTransform (point)

	mov	cx, ss:[bp].SVP_point.PD_x.low
	mov	dx, ss:[bp].SVP_point.PD_x.high
	mov	ax, ss:[bp].SVP_point.PD_y.low
	mov	bx, ss:[bp].SVP_point.PD_y.high
	call	WinTransformDWord		;get translated point
	push	ax, bx, cx, dx			;save the result


	; WinSetNullTransform

;	mov	cx, WIF_DONT_INVALIDATE		;avoid invalidating
	clr	cx				;10/23/91 cbh (win is suspended)
	call	WinSetNullTransform		;clear the current scaling

	; WinApplyScale

	call	GetScaleAmount			;get passed scale factor
	push	si
;	mov	si, WIF_DONT_INVALIDATE		;put off invalidation
	clr	si				;10/23/91 cbh (win is suspended)
	call	WinApplyScale			;scale the sucker
	pop	si


	push	bp, di
;	mov	ax, MSG_SPEC_SCROLLBAR_SUPPRESS_DRAW	;play with fire
;	call	OLPaneCallScrollbars			;  4/14/93 cbh

	; This next call USED to happen after WinApplyTranslation, but
	; apparently that was causing a problem in draw where the KeepInBounds
	; routine was using the incorrect (old) page size, and working
	; improperly.  This started happening when draw started scaling around
	; a point in the document when increasing the scalefactor. -cbh 10/16/90

	call	OLPaneSetNewPageSize		;set new page size


	; Moved here from OLPaneSetNewPageSize, since it didn't always need to
	; be called there. 5/ 6/91 cbh  (Moved back again 5/18/91 cbh, it needs
	; to get called there pretty much all the time, after all.)  (Added
	; back here again 10/23/91 cbh.  Much counseling will be required for
	; this piece of code, later in life...)

	jnc	10$				;no size change, branch
	mov	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
	call	SendPaneSizeMethod		;tell OD about it!
10$:
	pop	bp, di

	pop	ax, bx, cx, dx			;get translated oldOffset back
	call	WinUntransformDWord		;newOffset <- untrans oldOffset
	push	ax, bx, cx, dx			;save newOffset

	push	di				;restore to original position
	call	GetXOrigin			;bx.ax
	call	GetYOrigin			;dx.cx
	pop	di
	negdw	dxcx				;make into a translation
	xchg	ax, cx
	xchg	bx, dx
	negdw	dxcx
	push	si
;	mov	si, WIF_DONT_INVALIDATE		;invalidate later
	clr	si				;10/23/91 cbh (win is suspended)
	call	WinApplyTranslationDWord       ;now apply newOffset + docOffset
	pop	si

	pop	ax, bx, cx, dx			;get newOffset
	sub	cx, ss:[bp].SVP_point.PD_x.low	;subtract point centered around
	sbb	dx, ss:[bp].SVP_point.PD_x.high
	sub	ax, ss:[bp].SVP_point.PD_y.low
	sbb	bx, ss:[bp].SVP_point.PD_y.high
	negdw	dxcx				;make negative, get registers
	xchg	ax, cx				;  right
	xchg	bx, dx
	negdw	dxcx
	push	di
	call	MakeRelativeToOrigin		;now scroll amt from cur origin
	pop	di

	; Now try to scroll, to keep point positioned.  It may turn out
	; that we have to scroll to keep a full page onscreen.  Also, some
	; normalizing may need to be done.

	push	si
	mov	bp, SA_SCALE or mask OLPSF_ALWAYS_SEND_NORMALIZE
	call	OLPaneScroll
	pop	si
exit:
	ret

OLPaneScaleLow	endm

;---

ScalePaneGetWindow	proc	near
	mov	di, ds:[si]			;can be called directly
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].OLPI_window
	tst	di
	ret
ScalePaneGetWindow	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	GetScaleAmount

SYNOPSIS:	Gets scale point passed.

CALLED BY:	OLPaneScale

PASS:		ss:bp -- ScaleViewParams

RETURN:		dx.cx -- x scale value
		bx.ax -- y scale value

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/ 1/91		Initial version

------------------------------------------------------------------------------@

GetScaleAmount	proc	near
	mov	dx, ss:[bp].SVP_scaleFactor.PF_x.WWF_int
	mov	cx, ss:[bp].SVP_scaleFactor.PF_x.WWF_frac
	mov	bx, ss:[bp].SVP_scaleFactor.PF_y.WWF_int
	mov	ax, ss:[bp].SVP_scaleFactor.PF_y.WWF_frac
	ret
GetScaleAmount	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	SetupScalePoint

SYNOPSIS:	Sets up point to scale around.   Also may change the document
		offset to that the point is centered on the pre-scaled screen.

CALLED BY:	OLPaneScalePane

PASS:		*ds:si -- instance data
		ss:bp  -- ScaleViewParams
		dx     -- vertical flag - 0 if horizontal, SSP_VERTICAL if vert

RETURN:		ss:[bp].SVP_point -- updated for the location to scale around
		ax     -- offset in doc coords to the point from the upper
			  left hand corner of the subview.  Needs to
			  be converted to screen coords.

DESTROYED:	cx, dx, di, es

PSEUDO CODE/STRATEGY:
       case SVP_type of
	   SVT_AROUND_UPPER_LEFT:
       		SVP_point = docOffset
	   SVT_AROUND_CENTER:
	   	SVP_point = docOffset + DOC_WIN_SIZE/2
;	   SVT_AROUND_POINT_CENTERED:
;	   	docOffset = SVP_point - DOC_WIN_SIZE/2
       end


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/27/90		Initial version
	Jim	7/30/91		Changed GVI_origin to fixed point.  Even though
				the SSP_VERTICAL flag is used to index into
				GVI_origin, I decided to keep it as PD_y-PD_x,
				since other variables use it as such.  That
				means that there has to be some special code
				to test for non-zero values of that flag and
				"do the right thing".  sorry, chris.

------------------------------------------------------------------------------@
CheckHack <(offset PD_y - offset PD_x) eq (SSP_VERTICAL)>

SetupScalePoint	proc	near
	push	bp
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	; the next line is replaced by the succeeding four lines
;	add	di, dx				;correct for dementia
	tst	dx				; if zero, do horizontal
	jz	getOrigin
	add	di, (offset PDF_y - offset PDF_x) ; need fixed point offsets
getOrigin:
	mov	ax, ds:[di].GVI_origin.PDF_x.DWF_int.low ;get curr org in bx:ax
	mov	bx, ds:[di].GVI_origin.PDF_x.DWF_int.high

	mov	cl, ss:[bp].SVP_type		;get type of scaling
	add	bp, dx				;adjust for dimension
	cmp	cl, SVT_AROUND_CENTER		;scaling around center?
	jne	10$				;no, branch


	; Scaling around the center.  Point to scale = docOffset + offset to
	; center of the window.

	call	GetOffsetToCenter		;return offset to subview center
	add	ax, cx				;add offset to center to left
	adc	bx, 0				;  edge to get the point we want
	jmp	short storePoint		;  to center around

10$:
	cmp	cl, SVT_AROUND_UPPER_LEFT	;scaling around upper left?
	jne	20$				;no, branch

	; Scaling around the left edge.  Point to scale = docOffset.

storePoint:
	mov	ss:[bp].SVP_point.PD_x.low, ax	;store as the point to use
	mov	ss:[bp].SVP_point.PD_x.high, bx
20$:

if	0		;can't really comment in.  Won't work if point is far
			;away.
	jmp	short	exit			;and we're done
20$:
	cmp	cl, SVT_AROUND_POINT_CENTERED	;center point, scale around it?
	jne	calcOffsetToPoint		;no, scaling around pt,  branch

	; Scaling around point, but leave the point at the center of the
	; screen.  The point we want is already set, but we'll change the
	; document offset so that point is in the center of the screen.

	mov	ax, ss:[bp].SVP_point.PD_x.low	;get point in bx:ax
	mov	bx, ss:[bp].SVP_point.PD_x.high
	call	GetOffsetToCenter		;get offset to subview center
	sub	ax, cx				;subtract offset from point
	sbb	bx, 0
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Gen_offset		;ds:[di] -- GenInstance
	; the next line is replaced by the succeeding four lines
;	add	di, dx				;correct for dementia
	tst	dx				; if zero, do horizontal
	jz	setOrigin
	add	di, (offset PDF_y - offset PDF_x) ; need fixed point offsets
setOrigin:
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.low, ax ;store as new origin
	mov	ds:[di].GVI_origin.PDF_x.DWF_int.high, bx
	mov	di, dx				;put vertical flag in di now
	mov	cx, ax				;put new doc offset in dx:cx
	mov	dx, bx

	push	ax, bp, bx
	mov	ax, MSG_GEN_VALUE_SET_VALUE	;scroll scrollbars, w/out update
	mov	bx, di				;vertical flag into bx
	push	bx				;save vertical flag
	shr	bx, 1
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	CallScrollbar
	pop	dx				;restore vertical flag to dx
	pop	ax, bp, bx
endif

	pop	bp
	ret
SetupScalePoint	endp

COMMENT @----------------------------------------------------------------------

ROUTINE:	GetOffsetToCenter

SYNOPSIS:	Returns offset to center of subview.  In document coords.

CALLED BY:	SetupScalePoint, in two places.

PASS:		*ds:si -- subview handle
		bp     -- vertical flag: 0 if horiz, SSP_VERTICAL if vertical

RETURN:		cx   -- offset to center of subview

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	3/27/90		Initial version

------------------------------------------------------------------------------@
GetOffsetToCenter	proc	near
	push	bp
	mov	bp, dx
	shr	bp, 1				;word offset only
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	add	di, bp				;correct for dimensions
	mov	cx, ds:[di].OLPI_pageWidth	;get page width
	shr	cx, 1				;divide by 2
	pop	bp
	ret
GetOffsetToCenter	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ConvertScaleBasedOnMode

DESCRIPTION:	Convert scale args

CALLED BY:	INTERNAL

PASS:
	*ds:si - instance data
	ss:[bp] - ScaleViewParams

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
	Tony	3/ 2/92		Initial version

------------------------------------------------------------------------------@
ConvertScaleBasedOnMode	proc	near
	class	OLPaneClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GVI_attrs

	; if the view is controlled then force the Y scale to be the same as
	; the X scale

	test	ax, mask GVA_CONTROLLED
	jz	notControlled
	movdw	ss:[bp].SVP_scaleFactor.PF_y, ss:[bp].SVP_scaleFactor.PF_x, cx
notControlled:

	; do "scale to fit" if appropriate

	push	ax
	test	ax, mask GVA_SCALE_TO_FIT
	jz	afterScaleToFit

	mov	ax, ATTR_GEN_VIEW_SCALE_TO_FIT_BOTH_DIMENSIONS
	call	ObjVarFindData
	jnc	notScaleBoth
	call	calcXScaleToFit
	movdw	ss:[bp].SVP_scaleFactor.PF_x, dxcx	
	call	calcYScaleToFit
	movdw	ss:[bp].SVP_scaleFactor.PF_y, dxcx
	pop	ax
	jmp	done			;ignore scale to fit
notScaleBoth:
	mov	ax, ATTR_GEN_VIEW_SCALE_TO_FIT_BASED_ON_X
	call	ObjVarFindData
	jc	scaleXFirst
	call	calcYScaleToFit
	pushdw	dxcx
	call	calcXScaleToFit
	popdw	bxax		;BXAX - Y scale factor
	cmpwwf	bxax, dxcx
	ja	10$
	movdw	dxcx, bxax
10$:
	movdw	ss:[bp].SVP_scaleFactor.PF_y, dxcx
	movdw	ss:[bp].SVP_scaleFactor.PF_x, dxcx
	pop	ax
	test	ax, mask GVA_ADJUST_FOR_ASPECT_RATIO
	jz	done

	; adjust aspect ratio backwards: X = Y scale / aspectRatio

	call	ScalePaneGetScreenWindow	;di = window
	call	ComputeAspectRatio		;dx.ax = aspect ratio
	mov	bx, dx
	movdw	dxcx, ss:[bp].SVP_scaleFactor.PF_y
	call	GrUDivWWFixed			; dx.cx <- Y scale factor
	movdw	ss:[bp].SVP_scaleFactor.PF_x, dxcx
	jmp	done

scaleXFirst:
	call	calcXScaleToFit
	movdw	ss:[bp].SVP_scaleFactor.PF_x, dxcx
	movdw	ss:[bp].SVP_scaleFactor.PF_y, dxcx

afterScaleToFit:
	pop	ax
	test	ax, mask GVA_ADJUST_FOR_ASPECT_RATIO
	jz	done

adjustAspectY:

	; Compute the Y scale factor. Simply put it is:
	;	view scale factor * aspectRatio

	call	ScalePaneGetScreenWindow	;di = window
	call	ComputeAspectRatio		;dx.ax = aspect ratio
	mov	bx, dx
	movdw	dxcx, ss:[bp].SVP_scaleFactor.PF_x
	call	GrMulWWFixed			; dx.cx <- Y scale factor
	movdw	ss:[bp].SVP_scaleFactor.PF_y, dxcx
done:
	ret

;---

calcXScaleToFit:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	dx, ds:[di].OLPI_winWidth
	clr	cx				;dx.cx = screen height
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxax, ds:[di].GVI_docBounds.RD_right
	subdw	bxax, ds:[di].GVI_docBounds.RD_left
	mov	di, offset XYS_width
	call	getPageSize
	call	GrUDivWWFixed

	retn

calcYScaleToFit:
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	dx, ds:[di].OLPI_winHeight
	clr	cx				;dx.cx = screen height
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	bxax, ds:[di].GVI_docBounds.RD_bottom
	subdw	bxax, ds:[di].GVI_docBounds.RD_top
	mov	di, offset XYS_height
	call	getPageSize			;bx.ax = page size
	call	GrUDivWWFixed

	retn

getPageSize:
	push	ax
	mov	ax, ATTR_GEN_VIEW_PAGE_SIZE
	call	ObjVarFindData
	pushf
	add	di, bx
	popf
	pop	bx
	jnc	noPageSize

	;
	; Patch stupid problem in geoWrite, where page size is greater than
	; the document size, which causes big-time problems.   We'll ignore
	; the page size in this case.   I don't have time to find the problem
	; in geoWrite.  cbh 11/24/93
	;
	cmp	bx, ds:[di]				;doc size < page size?
	jb	noPageSize				;yes, ignore page size

	mov	bx, ds:[di]
noPageSize:
	clr	ax
	retn

ConvertScaleBasedOnMode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScalePaneGetScreenWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get window handle that we are sure exists (pane window may
		not exist yet if it is not opened)

CALLED BY:	INTERNAL
			ConvertScaleBasedOnMode

PASS:		*ds:si = OLPane

RETURN:		di = screen window

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScalePaneGetScreenWindow	proc	near
	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_SPEC_GUP_QUERY
	mov	cx, GUQT_SCREEN
	call	ObjCallInstanceNoLock
EC <	ERROR_NC	OL_ERROR					>
	mov	di, bp				; di = window
	.leave
	ret
ScalePaneGetScreenWindow	endp

ViewScale ends

;-----------------

ViewCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	OLPaneSendNotification -- MSG_GEN_VIEW_SEND_NOTIFICATION
							for OLPaneClass

DESCRIPTION:	Send notification to controller if needed

PASS:
	*ds:si - instance data
	es - segment of OLPaneClass

	ax - The message
	cx - non-zero if losing target

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
OLPaneSendNotification	method dynamic	OLPaneClass,
					MSG_GEN_VIEW_SEND_NOTIFICATION

	add	bx, ds:[bx].Gen_offset
	test	ds:[bx].GVI_attrs, mask GVA_CONTROLLED
	LONG jz	exit

	mov_tr	ax, di
	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di
	mov_tr	di, ax

	clr	bp
	tst	cx
	LONG jnz haveNotificationBlock

	test	ds:[di].OLPI_attrs, mask OLPA_APP_TARGET
	LONG jz done

	; generate the notification block

	mov	ax, size NotifyViewStateChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or (mask HAF_ZERO_INIT shl 8) \
				or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	push	bx

	; get the content width and height

	mov	ax, ds:[di].OLPI_winWidth
	mov	es:NVSC_contentSize.XYS_width, ax
	mov	ax, ds:[di].OLPI_winHeight
	mov	es:NVSC_contentSize.XYS_height, ax

	mov	di, ds:[di].OLPI_window
	tst	di
	jz	noWindow
	call	WinGetWinScreenBounds
	sub	cx, ax
	mov	es:NVSC_contentScreenSize.XYS_width, cx
	sub	dx, bx
	mov	es:NVSC_contentScreenSize.XYS_height, dx
noWindow:

	mov	si, ds:[si]
	add	si, ds:[si].Gen_offset

	push	si
	add	si, offset GVI_origin
	mov	di, offset NVSC_origin
	mov	cx, offset NVSC_endCopiedData
	rep movsb
	pop	si

	push	ds
	segmov	ds, es
	movdw	dxax, ds:NVSC_docBounds.RD_left
	movdw	cxbx, ds:NVSC_origin.PDF_x.DWF_int
	subdw	cxbx, dxax
	movdw	ds:NVSC_originRelative.PD_x, cxbx
	movdw	cxbx, ds:NVSC_docBounds.RD_right
	subdw	cxbx, dxax
	movdw	ds:NVSC_documentSize.PD_x, cxbx

	movdw	dxax, ds:NVSC_docBounds.RD_top
	movdw	cxbx, ds:NVSC_origin.PDF_y.DWF_int
	subdw	cxbx, dxax
	movdw	ds:NVSC_originRelative.PD_y, cxbx
	movdw	cxbx, ds:NVSC_docBounds.RD_bottom
	subdw	cxbx, dxax
	movdw	ds:NVSC_documentSize.PD_y, cxbx
	pop	ds

	pop	bx
	call	MemUnlock

	mov	ax, 1
	call	MemInitRefCount
	mov	bp, bx

haveNotificationBlock:
	mov	bx, bp

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_VIEW_STATE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			; di is event

	mov	ax, mask GCNLSF_SET_STATUS
	tst	bp
	jnz	afterTransitionCheck
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
afterTransitionCheck:

	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type,
				GAGCNLT_APP_TARGET_NOTIFY_VIEW_STATE_CHANGE
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax

	mov	ax, MSG_META_GCN_LIST_SEND
	mov	dx, size GCNListMessageParams

	call	UserCallApplication

; UserCallApplication spelled out here, in case we need to change approach
;	call	GeodeGetAppObject
;	mov	di, mask MF_FIXUP_DS or mask MF_STACK
;	call	ObjMessage

	add	sp, size GCNListMessageParams

done:
	pop	di
	call	ThreadReturnStackSpace
exit:
	ret

OLPaneSendNotification	endm

ViewCommon ends

;---------------

ViewScale segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ComputeAspectRatio

DESCRIPTION:	Compute the aspect ratio

CALLED BY:	INTERNAL

PASS:
	di - window handle

RETURN:
	dx.ax - aspect ratio
	zero flag - set if "1 to 1"

DESTROYED:
	bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/28/92		Initial version

------------------------------------------------------------------------------@
ComputeAspectRatio	proc	near	uses si, di, bp, ds
	.enter

	; Get the aspect ratio so we can use it when we need it.

	mov	si, WIT_STRATEGY
	call	WinGetInfo			; cx:dx = strategy routine
	
	push	cx				; Pass segment and offset on
	push	dx				;    the stack
	mov	bp, sp				; ss:bp points at routine
	mov	di, DR_VID_INFO
	call	{dword} ss:[bp]			; dx:si = info table
	add	sp, 4				; Restore the stack

	mov	ds, dx				; ds:si = info table

	;
	; Aspect ratio = 1 / (horiz DPI / vert DPI)
	; Compute aspect ratio. Check for the case of square pixel display.
	;
	clr	cx
	mov	dx, ds:[si].VDI_vRes		; dx.cx = v res
	clr	ax
	mov	bx, ds:[si].VDI_hRes		; bx.ax = h res
	cmp	bx, dx
	pushf					; Save "1 to 1" flag
	call	GrUDivWWFixed			; dx.cx = v/h
	mov_tr	ax, cx
	popf					; Restore "1 to 1" flag

	.leave
	ret

ComputeAspectRatio	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateScale

DESCRIPTION:	Update the scale factor for a mode change

CALLED BY:	INTERNAL

PASS:
	*ds:si - view object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/ 2/92		Initial version

------------------------------------------------------------------------------@
UpdateScale	proc	far
	class	OLPaneClass

	sub	sp, size ScaleViewParams
	mov	bp, sp

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	movdw	ss:[bp].SVP_scaleFactor.PF_x, ds:[di].GVI_scaleFactor.PF_x, ax
	movdw	ss:[bp].SVP_scaleFactor.PF_y, ds:[di].GVI_scaleFactor.PF_y, ax
	mov	ss:[bp].SVP_type, SVT_AROUND_UPPER_LEFT

	call	ScaleNoInvalidate
	add	sp, size ScaleViewParams
	ret

UpdateScale	endp

ViewScale ends
