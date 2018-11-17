COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Doodle
FILE:		visTextForBitmaps.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	1/91		Initial Version

DESCRIPTION:
	This file contains the implementation of the VisTextForBitmapsClass,
	which will later most likely move to a library

RCS STAMP:
$Id: visTextForBitmaps.asm,v 1.1 97/04/04 17:43:36 newdeal Exp $

------------------------------------------------------------------------------@

if 0

idata	segment
	VisTextForBitmapsClass
idata	ends

BitmapTextCodeResource	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapsHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_TEXT_HEIGHT_NOTIFY handler for VisTextForBitmapsClass
		This method is subclassed so that we can do the right
		thing when the VTFB needs more/less room within the
		VisBitmap

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		dx = desired height
		
CHANGES:	

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsHeightNotify	method	VisTextForBitmapsClass, MSG_VIS_TEXT_HEIGHT_NOTIFY
	;
	;	Call the super class (although I don't think it
	;	does anything, so anyone in the know can remove this call)
	;
;	mov	di, offset VisTextForBitmapsClass
;	call	ObjCallSuperNoLock

	;
	;	We only want to do something if the text object is actively
	;	taking data in from the user (as opposed to resizing for
	;	other spurious reasons). We will check the focus to
	;	determine whether or not the user is typing.
	;
;	mov	di, ds:[si]
;	add	di, ds:[di].Vis_offset

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_FOCUS
	jz	done

	;
	;	Get the screen gstate, which the bitmap has already clipped
	;	to the proper dimensions
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	;
	;	If the text object is shrinking, then we want to invalidate
	;	the uncovered region.
	;
	push	bp				;push screen gstate

	push	dx				;push new height
	mov	ax, MSG_VIS_GET_BOUNDS
	call	ObjCallInstanceNoLock
	pop	bx				;bx <- new height
	pop	di				;di <- screen gstate

	sub	dx, bp				;dx <- old height
	cmp	bx, dx				;if enlarging, no inval
	jge	afterInval

	add	bx, bp				;bx <- top of inval region
	add	dx, bp				;dx <- bottom of inval region

	call	GrInvalRect

	sub	bx, bp				;bx <- new height
afterInval:
	sub	cx, ax				;cx <- width

	;
	;	Removing the folowing line to account for the recent change
	;	in the graphics system.
	;
	;	inc	cx

	mov	dx, bx				;dx <- requested height

	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

done:
	ret
VisTextForBitmapsHeightNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_SET_SIZE handler for VisTextForBitmapsClass.
		Resizes the visual bounds of the object; this handler
		ensures that the object will not spill out the bottom
		of its parent's vis bounds.

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		cx, dx = requested width, height
		
CHANGES:	

RETURN:		cx, dx = new width, height

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:
		Clip the height to fit inside the bitmap if necessary, then
		resize the object.

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsResize	method	VisTextForBitmapsClass, MSG_VIS_SET_SIZE
	push	cx
	mov	cx, ds:[di].VI_bounds.R_top
	mov	ax, MSG_VIS_BITMAP_CHECK_TEXT_HEIGHT
	call	VisCallParent
	pop	cx

	mov	di, segment VisTextForBitmapsClass
	mov	es, di
	mov	di, offset VisTextForBitmapsClass
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallSuperNoLock
	ret
VisTextForBitmapsResize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapsAppear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VTFB_APPEAR handler for VisTextForBitmapsClass.
		Grabs the target and focus for te object, and makes the
		object drawable.

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		
CHANGES:	

RETURN:		nothing

DESTROYED:	ax, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsAppear	method	VisTextForBitmapsClass, MSG_VTFB_APPEAR

	;
	;	clear the object's VOF_GEOMETRY_INVALID bit
	;
	BitClr	ds:[di].VI_optFlags, VOF_GEOMETRY_INVALID

	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	ObjCallInstanceNoLock

	;
	;	Grab the focus so the user can enter text
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	;
	;	Grab the target so the user can enter text
	;
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	;
	;	Make the object drawable and detectable
	;
	clr	ch
	mov	cl, mask VA_DRAWABLE or mask VA_DETECTABLE
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_SET_ATTRS
	call	ObjCallInstanceNoLock

	;
	;	Invalidate ourselves on the screen through the proper
	;	gstate
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	VisCallParent

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_top
	mov	cx, ds:[di].VI_bounds.R_right
	mov	dx, ds:[di].VI_bounds.R_bottom
	mov	di, bp
	call	GrInvalRect
	ret
VisTextForBitmapsAppear	endm

VisTextForBitmapsDisappear method VisTextForBitmapsClass, MSG_VTFB_DISAPPEAR
	;
	;	Release the focus
	;
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	call	ObjCallInstanceNoLock

	;
	;	Release the target
	;
	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	ObjCallInstanceNoLock

	;
	;	Make the object neither drawable nor detectable
	;
	clr	cl
	mov	ch, mask VA_DRAWABLE or mask VA_DETECTABLE
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_SET_ATTRS
	call	ObjCallInstanceNoLock

	;
	;	Invalidate ourselves on the screen through the proper
	;	gstate
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	VisCallParent

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, ds:[di].VI_bounds.R_left
	mov	bx, ds:[di].VI_bounds.R_top
	mov	cx, ds:[di].VI_bounds.R_right
	mov	dx, ds:[di].VI_bounds.R_bottom
	mov	di, bp
	call	GrInvalRect
	ret
VisTextForBitmapsDisappear	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapsStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VTFB_START_SELECT handler for VisTextForBitmapsClass
		Checks to see if:
			(1) This object is VA_DETECTABLE
			(2) The mouse event occurred within
				this object's visible bounds

		If these 2 conditions are met, the object sends itself
		a real MSG_META_START_SELECT.

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		cx,dx = x,y of mouse event
		
CHANGES:	

RETURN:		carry set if object "accepted" the event,
		carry clear if one of the 2 conditions listed above were
			not met.

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		Could probably make this a true subclass of MSG_META_START_SELECT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsStartSelect	method	VisTextForBitmapsClass, MSG_VTFB_START_SELECT
	mov	ax, MSG_META_START_SELECT
	call	ScreenMouseEventsCommon
	ret
VisTextForBitmapsStartSelect	endm

VisTextForBitmapsDragSelect	method	VisTextForBitmapsClass, MSG_VTFB_DRAG_SELECT
	mov	ax, MSG_META_DRAG_SELECT
	call	ScreenMouseEventsCommon
	ret
VisTextForBitmapsDragSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapsPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VTFB_PTR handler for VisTextForBitmapsClass
		Checks to see if:
			(1) This object is VA_DETECTABLE
			(2) The mouse event occurred within
				this object's visible bounds

		If these 2 conditions are met, the object sends itself
		a real MSG_META_PTR.

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		cx,dx = x,y of mouse event
		
CHANGES:	

RETURN:		carry set if object "accepted" the event,
		carry clear if one of the 2 conditions listed above were
			not met.

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		Could probably make this a true subclass of MSG_META_PTR

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsPtr	method	VisTextForBitmapsClass, MSG_VTFB_PTR
	mov	ax, MSG_META_PTR
	call	ScreenMouseEventsCommon
	ret
VisTextForBitmapsPtr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapsEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VTFB_END_SELECT handler for VisTextForBitmapsClass
		Checks to see if:
			(1) This object is VA_DETECTABLE
			(2) The mouse event occurred within
				this object's visible bounds

		If these 2 conditions are met, the object sends itself
		a real MSG_META_END_SELECT.

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		cx,dx = x,y of mouse event
		
CHANGES:	

RETURN:		carry set if object "accepted" the event,
		carry clear if one of the 2 conditions listed above were
			not met.

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		Could probably make this a true subclass of MSG_META_END_SELECT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsEndSelect	method	VisTextForBitmapsClass, MSG_VTFB_END_SELECT
	mov	ax, MSG_META_END_SELECT
	call	ScreenMouseEventsCommon
	ret
VisTextForBitmapsEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			ScreenMouseEventsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if:
			(1) This object is VA_DETECTABLE
			(2) The mouse event occurred within
				this object's visible bounds

		If these 2 conditions are met, the object sends itself the
		passed method number.

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		cx,dx = x,y of mouse event
		ax = method number to send self if both conditions are met
		
CHANGES:	

RETURN:		carry set if object "accepted" the event,
		carry clear if one of the 2 conditions listed above were
			not met.

DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		Could probably make this a true subclass of MSG_META_END_SELECT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenMouseEventsCommon	proc	near
	class	VisTextForBitmapsClass

	test	ds:[di].VI_attrs, mask VA_DETECTABLE
	jz	done

	call	VisTestPointInBounds
	jnc	done

	mov	di, offset VisTextForBitmapsClass
	call	ObjCallSuperNoLock
	stc
done:
	ret
ScreenMouseEventsCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapsAfterCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VTFB_AFTER_CREATE handler for VisTextForBitmapsClass
		Handles some initialization stuff that should be done
		soon after the object is instantiated.

CALLED BY:	

PASS:		*ds:si = VisTextForBitmaps object
		^lcx:dx = VisBitmap parent
		
CHANGES:	

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsAfterCreate	method	VisTextForBitmapsClass, MSG_VTFB_AFTER_CREATE
	;
	;	Create a one-way upward visual link to the VisBitmap
	;
	mov	ds:[di].VI_link.LP_next.handle, cx
	mov	ds:[di].VI_link.LP_next.offset, dx

	;
	;	Clear the object's path bits, or die in EC
	;
	clr	ds:[di].VI_optFlags

	;
	;	Override a couple default VI_optFlags by making the
	;	object neither drawable nor detectable.
	;
	clr	cl
	mov	ch, mask VA_DRAWABLE or mask VA_DETECTABLE
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_SET_ATTRS
	call	ObjCallInstanceNoLock
 
	;
	;	Make the object selectable, editable, and targetable
	;
	mov	cl, mask VTS_SELECTABLE or \
		    mask VTS_EDITABLE or \
		    mask VTS_TARGETABLE

	clr	ch
	mov	dx, mask VTSF_MULTIPLE_CHAR_ATTRS or \
		     mask VTSF_MULTIPLE_PARA_ATTRS

;
;	Removed on 28-jan-1992 'cause this message no longer
;	exists, and I can't find a replacement...
;
;	mov	ax,MSG_VIS_TEXT_SET_STATE
;	call	ObjCallInstanceNoLock

	;
	;	Set the default font
	;
	sub	sp, size VisTextSetFontIDParams
	mov	bp, sp
	mov	ss:[bp].VTSFIDP_fontID, VTFB_DEFAULT_FONT_ID
	call	ClearRange
	mov	ax, MSG_VIS_TEXT_SET_FONT_ID
	call	ObjCallInstanceNoLock
	add	sp, size VisTextSetFontIDParams

	;
	;	Set the default point size
	;
	sub	sp, size VisTextSetPointSizeParams
	mov	bp, sp				; structure => SS:BP
	call	ClearRange
	mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
	mov	ss:[bp].VTSPSP_pointSize.WWF_int, VTFB_DEFAULT_POINT_SIZE

	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	call	ObjCallInstanceNoLock

	add	sp, size VisTextSetPointSizeParams

	;
	;	Set default color to black
	;
	sub	sp, size VisTextSetColorParams
	mov	bp, sp				; structure => SS:BP
	call	ClearRange
	mov	ss:[bp].VTSCP_color.low, C_BLACK
	clr	ss:[bp].VTSCP_color.high
	mov	ax, MSG_VIS_TEXT_SET_COLOR
	call	ObjCallInstanceNoLock
	add	sp, size VisTextSetColorParams

	;
	;	Send ourselves a MSG_VIS_OPEN
	;
	call	VisQueryParentWin
	mov	bp, di
	mov	ax, MSG_VIS_OPEN
	call	ObjCallInstanceNoLock
	ret
VisTextForBitmapsAfterCreate	endm

;---

ClearRange	proc	near
	clrdw	ss:[bp].VTSPSP_range.VTR_start
	movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	ret
ClearRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisTextForBitmapsDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_VIS_DRAW handler for VisTextForBitmapsClass
		Object draws itself if it is VA_DRAWABLE.

CALLED BY:	

PASS:		bp = gstate to draw through
		
CHANGES:	

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextForBitmapsDraw	method	VisTextForBitmapsClass, MSG_VIS_DRAW
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	done

	mov	di, offset VisTextForBitmapsClass
	call	ObjCallSuperNoLock

done:

	ret
VisTextForBitmapsDraw	endm
BitmapTextCodeResource	ends		;end of CommonCode resource

endif
