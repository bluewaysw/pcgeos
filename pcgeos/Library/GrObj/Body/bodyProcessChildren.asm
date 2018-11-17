COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hierarchy
FILE:		graphicBodyProcessChildren

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
    GrObjBodySendToChildren	Send message to all children of body
    GrObjBodyProcessAllGrObjsInRect
    GrObjBodyProcessAllGrObjsInRectCB
    GrahpicBodyTextRectInclusion
    GrObjBodyDrawChildren		
    GrObjBodyDrawChildrenCallBack 
    GrObjBodyVisOverlapDoc?		
    GrObjBodyProcessAllGrObjsInDrawOrderCommon
    GrObjBodyInsertOrDeleteSpaceCB


METHOD HANDLERS
	Name			Description
	----			-----------
	GrObjBodyInsertOrDeleteSpace

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	10/08/91	Initial revision


DESCRIPTION:

	$Id: bodyProcessChildren.asm,v 1.1 97/04/04 18:08:13 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetGrObjDrawFlagsForDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the GrObjDrawFlags from the bodies instance data

CALLED BY:	INTERNAL
		GrObjBodyDraw

PASS:		
		*ds:si - GrObjBody
		cl - DrawFlags

RETURN:		
		dx - GrObjDrawFlags

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetGrObjDrawFlagsForDraw		proc	far
	class	GrObjBodyClass
	uses	di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject				>

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	dx,ds:[di].GBI_drawFlags

	;    Set increased resolution flag if it is not already set
	;    and the view is zoomed in or printing is happening
	;

	test	dx, mask GODF_DRAW_WITH_INCREASED_RESOLUTION
	jnz	done

	cmp	ds:[di].GBI_curScaleFactor.PF_x.WWF_int,1
	jne	checkXAbove
	tst	ds:[di].GBI_curScaleFactor.PF_x.WWF_frac
	jnz	setIncreased
	
checkY:
	cmp	ds:[di].GBI_curScaleFactor.PF_y.WWF_int,1
	jne	checkYAbove
	tst	ds:[di].GBI_curScaleFactor.PF_y.WWF_frac
	jnz	setIncreased

checkPrint:
	test	cl, mask DF_PRINT
	jnz	setIncreased

done:
	.leave
	ret

checkXAbove:
	ja	setIncreased
	jmp	checkY

checkYAbove:
	jb	checkPrint

setIncreased:
	BitSet	dx, GODF_DRAW_WITH_INCREASED_RESOLUTION
	jmp	done



GrObjBodySetGrObjDrawFlagsForDraw		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetGrObjDrawFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the GrObjDrawFlags that would normally be used
		when the body handles MSG_VIS_DRAW.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cl - DrawFlags

RETURN:		
		dx - GrObjDrawFlags
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 2/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetGrObjDrawFlags	method dynamic GrObjBodyClass, 
						MSG_GB_GET_GROBJ_DRAW_FLAGS
	.enter

	call	GrObjBodySetGrObjDrawFlagsForDraw		

	.leave
	ret
GrObjBodyGetGrObjDrawFlags		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the children

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		bp - gstate
		cl - DrawFlags
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
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVisDraw	method dynamic GrObjBodyClass, MSG_VIS_DRAW
	.enter

	call	GrObjBodySetGrObjDrawFlagsForDraw

	mov	ax,MSG_GB_DRAW
	call	ObjCallInstanceNoLock

	Destroy 	ax,cx,dx,bp

	.leave
	ret
GrObjBodyVisDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the children

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		bp - gstate
		cl - DrawFlags
		dx - GrObjDrawFlags

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDraw	method dynamic GrObjBodyClass, MSG_GB_DRAW
	uses	cx,dx,bp
	.enter

EC <	test	dx, not mask GrObjDrawFlags			>
EC <	ERROR_NZ GROBJ_BAD_GROBJ_DRAW_FLAGS			>

	mov	di,bp					;gstate
	call	GrSaveState

	;    Apply the translation of the Body depending on its bounds
	;

	push	cx,dx					;flags
	push	di					;gstate
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	movdw	dxcx, ds:[di].GBI_bounds.RD_left
	movdw	bxax, ds:[di].GBI_bounds.RD_top
	pop	di					;gstate
	call	GrApplyTranslationDWord
	pop	cx,dx					;flags

	;    Send method draw to all children in window mask bounds
	;

	call	GrObjBodyDrawChildren

	;    If we are printing then skip drawing of handles
	;    and sprite
	;

	test	cl, mask DF_PRINT		; DrawFlags
	jnz	done				
	test	dx, mask GODF_DRAW_OBJECTS_ONLY
	jnz	done

	;    If we are the target then draw handles, sprites and 
	;    edit marker
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED 
	jz	done

	mov	dx,bp				;gstate
	mov	ax,MSG_GO_DRAW_HANDLES_RAW
	call	GrObjBodySendToChildren

	mov	ax,MSG_GO_DRAW_SPRITE_RAW
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToMouseGrab

	mov	ax,MSG_GO_DRAW_EDIT_INDICATOR_RAW
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit

done:
	mov	di,bp
	call	GrRestoreState
	stc					; done drawing

	.leave
	ret
GrObjBodyDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all children of body in order of
		the draw list. The message will be sent to all
		children regardless of message return values

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to children
		cx,dx,bp - parameters to message

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
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToChildren		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	clr	bx					;no call back segment
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	.leave
	ret
GrObjBodySendToChildren		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToGrObjTexts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all text objects in the body in order of
		the draw list. The message will be sent to all
		text objects regardless of message return values

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		ax - message to send to children
		cx,dx,bp - parameters to message

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
	srs	10/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToGrObjTexts		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx, SEGMENT_CS
	mov	di, offset GrObjBodySendToGrObjTextsCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	.leave
	ret
GrObjBodySendToGrObjTexts		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendToGrObjTextsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tests whether the passed object is some subclass of
		TextGuardian, and if so, sends the message along to
		its ward.

CALLED BY:	ObjArrayProcessChildren

PASS:		*ds:si - child optr
		*es:di - composite optr
		ax - text message
		cx, dx, bp - data

RETURN:		clc - to keep processing

DESTROYED:	bx, si, di, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	17 sep	1992	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendToGrObjTextsCB	proc	far
	.enter

	push	ax, cx, dx, bp				;save message, regs
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	pop	ax, cx, dx, bp				;restore message, regs
	jnc	done

	;
	;  We're a text guardian, so send the message to the ward
	;
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	clc
done:
	.leave
	ret
GrObjBodySendToGrObjTextsCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDrawChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw children of body that overlap the the current
		window mask bounds

CALLED BY:	INTERNAL
		GrObjBodyDraw

PASS:		
		*(ds:si) - instance data of object
		cl - DrawFlags
		dx - GrObjDrawFlags
		di - GState to draw with

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
	srs	4/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDrawChildren		proc	far

maskBounds	local	RectDWord
drawFlags	local	GrObjDrawFlags

	uses	ax,bx,dx,di,si
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>
EC <	call	ECCheckGStateHandle				>

	test	cl, mask DF_DONT_DRAW_CHILDREN
	jnz	done

	mov	bx,ds:[si]
	add	bx,ds:[bx].Vis_offset

	;    If composite is not drawable then exit
	;

	test	ds:[bx].VI_attrs, mask VA_DRAWABLE
	jz	done	

	;    If printing skip check for realized and image valid
	;
	
	test	cl, mask DF_PRINT
	jnz	getBounds

	;    If composite is not realized or its image is invalid 
	;    then don't draw children
	;

	test	ds:[bx].VI_attrs, mask VA_REALIZED
	jz	done
	test	ds:[bx].VI_optFlags, mask VOF_IMAGE_INVALID
	jnz	done

getBounds:
	
	;    Get 32 bit bounds of window mask in stack frame
	;

	push	ds,si				;segment,chunk of body
	segmov	ds,ss				;segment of maskBounds
	lea	si,ss:[maskBounds]
	call	GrGetMaskBoundsDWord
	pop	ds,si				;segment, chunk of body
	jc	done				;abort if mask is null

	;    Set up parameters for sending method draw to all children
	;

	mov	drawFlags,dx			;GrObjDrawFlags
	mov	dx,di				;gstate
	mov	ax,MSG_GO_DRAW
	mov	bx,SEGMENT_CS			;bx <- vseg if XIP`ed
	mov	di,offset GrObjBodyDrawChildrenCallBack
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

done:
	.leave
	ret
GrObjBodyDrawChildren		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDrawChildrenCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call back routine supplied by GrObjBodyDrawChildren
		when calling ObjCompProcessChildren. Each child
		which visual bounds overlap the passed RectDWord will
		have a MSG_GO_DRAW sent to them

CALLED BY:	ObjCompProcessChildren (as call-back)

PASS:		
		*(ds:si) - child
		*(es:di) - composite
		ax - draw message
		cx - DrawFlags
		dx - GState
		ss:bp - inherited RectDWord stack frame

RETURN:		
		clc - to continue processing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Must be far it is used as a call back routine		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDrawChildrenCallBack		proc	far
maskBounds	local	RectDWord
drawFlags	local	GrObjDrawFlags
ForceRef maskBounds
	class	GrObjClass
	uses	ax,dx,di,bp
	.enter	inherit
	
EC <	push	di					>
EC <	mov	di,dx					>
EC <	call	ECCheckGStateHandle			>
EC <	pop	di					>

	;	Skip if object does not have normal transfer.  This can
	;	happen in the obscure case where you have the spline tool
	;	active in GeoWrite, you alter an existing closed spline
	;	that is wrapped tightly, and then click to start another
	;	spline.  When you start that new spline, the altered spline
	;	causes wrapping to update.  The wrap regions are updated
	;	by telling the grobj body to draw its children to a path.
	;	Unfortunately, the newly half-created spline is already a
	;	child of the body, so it is asked if it falls within the
	;	grobj body bounds (to determine if it should be drawn) and
	;	pukes when it gets here.  It'd be nice not add the new
	;	spline to the grobj body until everything is ready, but we
	;	don't have time to rewrite the GrObj library - brianc 10/31/94

	push	di
	GrObjDeref	di,ds,si
	tst	ds:[di].GOI_normalTransform
	pop	di
	jz	done

	;    Check for bounds of object overlapping the RectDWord.
	;    Jump if no overlap of rectangles.
	;

	call	GrObjBodyVisOverlapDoc?
	jnc	done

	;    Send draw method to object. 
	;

	mov	di,drawFlags			;GrObjDrawFlags
	mov	bp,dx				;gstate
	mov	dx,di				;GrObjDrawFlags
	call	ObjCallInstanceNoLockES

done:
	clc					;continue processing
	.leave
	ret

GrObjBodyDrawChildrenCallBack		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyVisOverlapDoc?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if visual bounds of object overlap the RectDWord
		passed on the stack

CALLED BY:	INTERNAL
		GrObjBodyDrawChildrenCallBack

PASS:		
		*(ds:si) - instance data of object (not body)
		ss:bp - inherited RectDWord

RETURN:		
		clc - no overlap
		stc - overlap

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVisOverlapDoc?		proc	near

maskBounds	local	RectDWord
drawFlags	local	GrObjDrawFlags
ForceRef	drawFlags

	uses	ax,bx,si,di,ds,es
	class	GrObjClass
	.enter	inherit

EC <	call	ECGrObjCheckLMemObject			>
	
	;    Get bounds of object in Bodies coordinate system
	;    in RectDWord
	;

	mov	bx,bp					;mask rect frame
	sub	sp,size	RectDWord
	mov	bp,sp
	call	GrObjGetDWPARENTBounds
	xchg	bx,bp				;bp = masked rect frame
						;bx = object rect frame

	;    Determine if mask RectDWord is overlapped by
	;    the RectDWord of the object 
	;

	mov	ax,ss
	mov	ds,ax				;mask RectDWord seg
	mov	es,ax				;object RectDWord seg
	lea	si,ss:[maskBounds]		;mask RectDWord offse
	mov	di,bx				;object RectDWord offset
	CallMod	GrObjIsRectDWordOverlappingRectDWord?
	lahf					;results of overlap compare
	add	sp,size RectDWord
	sahf					;results of overlap compare
	.leave
	ret

GrObjBodyVisOverlapDoc?		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessAllGrObjsInDrawOrderCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to all children of body in order of the
		draw list

CALLED BY:	INTERNAL
		GrObjBodySendToChildren

PASS:		
		*ds:si - instance data of graphic body
	
		bx:di - call back routine
			(must be vfptr if XIP'ed)
			ax,cx,dx,bp - parameters to call back
		OR
		bx = 0 ,di - ObjCompCallType
			ax - message to send to children
			cx,dx,bp - parameters to message

RETURN:		
		ax,cx,dx,bp - may be returned depending on message,
		call back or ObjCompCallType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 7/91	Initial version
	jeremy	5/8/92		Changed to a far procedure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyProcessAllGrObjsInDrawOrderCommon		proc	far
	class	GrObjBodyClass
	uses	bx,di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	es,bx			;segment of call back or zero
	clr	bx			;initial child (first
	push	bx			;child of
	push	bx			;composite)
	mov	bx, offset GOI_drawLink	;pass offset to LinkPart on stack
	push	bx
	push	es			;pass call-back routine
	push	di			;call back offset or ObjCompCallType

	mov	bx, offset GrObj_offset		;grobj is master

CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	di,offset GBI_drawComp

	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack

	.leave
	ret
GrObjBodyProcessAllGrObjsInDrawOrderCommon		endp

GrObjDrawCode	ends



GrObjRequiredExtInteractive2Code	segment resource







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindNextSelectedChildInDrawOrder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find next child in draw list that is selected

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - instance data of graphic body
		^lcx:dx = first child		

RETURN:		
		carry set if found, ^lcx:dx = next selected child in draw list
		carry clear if not found

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12 Nov 1991	Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindNextSelectedChildInDrawOrder		proc	far
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,SEGMENT_CS				;bx <- vseg if XIP'ed
	mov	di,offset GrObjBodyFindNextSelectedChildInDrawOrderCB
	call	GrObjBodyProcessSomeChildrenInDrawOrderCommon

	.leave
	ret
GrObjBodyFindNextSelectedChildInDrawOrder		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindNextSelectedChildInDrawOrderCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call back routine that sends message to 
		child if the childs selected bit is set.

CALLED BY:	ObjCompProcessChildren

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		ax - method to pass
		cx, dx	bp- data
RETURN:		
		carry set if found
		clc - to keep search going

DESTROYED:	
		di

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12 Nov 1991	Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindNextSelectedChildInDrawOrderCB		proc	far
	class	GrObjClass
	.enter

	;
	;	Maybe this test doesn't need to occur, since the
	;	object itself isn't yet selected...
	;

	;    Make sure our OD doesn't match the passed OD
	;

	cmp	dx, si
	jne	notMe

	cmp	cx, ds:[LMBH_handle]
	je	done					;carry clear if =

notMe:	
	;    Get access to normal transform data in object and
	;    check for selected bit being set
	;

	call	GrObjBodyIsLMemGrObjSelected?
	jnc	done

	;    This object is selected, so return our OD and set the carry
	;

	mov	dx, si
	mov	cx, ds:[LMBH_handle]

done:
	.leave
	ret
GrObjBodyFindNextSelectedChildInDrawOrderCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessAllGrObjsInRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	
		Sends messages to children whose visBounds fall within
		the passed rectangle. Several variations are provide,
		see definition of ChildrenRectInData for explanations.
		
	
PASS:		
		*ds:si - instance data of composite object
		ss:bp - GrObjsInRectData


RETURN:		
		nothing

DESTROYED:	
		nothing
		
PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyProcessAllGrObjsInRect method GrObjBodyClass, 
				MSG_GB_PROCESS_ALL_GROBJS_IN_RECT
	uses	bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyProcessAllGrObjsInRectCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon
	
	.leave
	ret
GrObjBodyProcessAllGrObjsInRect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessAllGrObjsInRectCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Sends messages to children whose visBounds fall within
		the passed rectangle. Several variations are provide,
		see definition of ChildrenRectInData for explanations.

CALLED BY:	INTERNAL
		GrObjBodyProcessAllGrObjsInRect

PASS:		*ds:si -- child handle
		*es:di -- composite handle
		ss:bp - GrObjsInRectData


RETURN:		
		clc - to keep search going

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DONT_WANT_TO_SEND_RECT = 0
WANT_TO_SEND_RECT = 1
DONT_WANT_TO_SEND_TEMP = 0
WANT_TO_SEND_TEMP = 1

GrObjBodyProcessAllGrObjsInRectCB		proc	far
	class	GrObjClass
	uses	ax,di
	.enter

	;    Assume we don't want to send the rect message, but
	;    if the message is not ignored and the object's 
	;    visBound are inside the GOIRD_rect, then flag that
	;    we wish to send the rect message
	;

	mov	al,DONT_WANT_TO_SEND_RECT		

	test	ss:[bp].GOIRD_special, mask GOIRS_IGNORE_RECT
	jnz	checkTemp

	call	GrObjBodyTestRectInclusion
	jnc	checkTemp
	mov	al,WANT_TO_SEND_RECT

checkTemp:
	;    Assume we don't want to send the temp message, but
	;    if the message is not ignored and the object's 
	;    OSF_TEMP bit is set, then flag that
	;    we wish to send the temp message
	;

	mov	ah,DONT_WANT_TO_SEND_TEMP	
	GrObjDeref	di,ds,si
	test	ss:[bp].GOIRD_special, mask GOIRS_IGNORE_TEMP
	jnz	sendRect?

	test	ds:[di].GOI_tempState, mask GOTM_TEMP_HANDLES
	jz	sendRect?
	mov	ah,WANT_TO_SEND_TEMP

	;    If both messages want to be sent, jump to check special
	;    instructions to see if neither should be sent
	;

	cmp	al,ah
	je	handleXor


sendTemp?:
	;    If temp wants to sent, then send it
	;

	cmp	ah,WANT_TO_SEND_TEMP
	jne	sendRect?
	push	ax,cx,dx,bp
	mov	ax,ss:[bp].GOIRD_tempMessage
	mov	dx,ss:[bp].GOIRD_tempMessageDX
	call	ObjCallInstanceNoLockES	;
	pop	ax,cx,dx,bp

sendRect?:
	;    If rect wants to be sent, then send it
	;

	cmp	al,WANT_TO_SEND_RECT
	jne	done
	push	ax,cx,dx,bp
	mov	ax,ss:[bp].GOIRD_inRectMessage
	mov	dx,ss:[bp].GOIRD_inRectMessageDX
	call	ObjCallInstanceNoLockES	;
	pop	ax,cx,dx,bp

done:
	clc

	.leave
	ret

handleXor:
	;  Both messages wish to be sent, if the xorCheck is not set
	;  then jump to send the both. Otherwise exit without sending
	;

	test	ss:[bp].GOIRD_special,mask GOIRS_XOR_CHECK
	jz	sendTemp?
	jmp	short done
	


GrObjBodyProcessAllGrObjsInRectCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTestRectInclusion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if objects bounds are inside the
		passed rectangle inclusive

CALLED BY:	INTERNAL
		GrObjBodyTestRectangles

PASS:		*ds:si -- child 
		ss:bp - GrObjsInRectData

RETURN:		
		stc - inside
		clc - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTestRectInclusion		proc	near
	class	GrObjClass
	uses	ax,bx,di,si,ds,es
	.enter

	;    Get bounds of object in Bodies coordinate system
	;    in RectDWord
	;

	mov	bx,bp				;ChildrenInRect frame
	sub	sp,size RectDWord
	mov	bp,sp
	call	GrObjGetDWPARENTBounds

	;    Determine if object's RectDWord (secondary) is inside
	;    the GrObjsInRectData RectDWord (primary)
	;

	mov	ax,ss
	mov	ds,ax				;primary RectDWord seg
	mov	es,ax				;secondary RectDWord seg
	mov	si,bx				;ChildrenInRect frame offset
	add	si,offset GOIRD_rect		;primary RectDWord offset
	mov	di,bp				;secondary RectDWord offset
	mov	bp,bx				;ChildrenInRect frame
	CallMod	GrObjIsRectDWordInsideRectDWord?
	lahf					;rect compare results
	add	sp, size RectDWord
	sahf					;rect compare results

	.leave
	ret


GrObjBodyTestRectInclusion		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessSomeChildrenInDrawOrderCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to some children of body in order of the
		draw list, starting with the passed child

CALLED BY:	INTERNAL
		GrObjBodySendToChildren

PASS:		
		*ds:si - instance data of graphic body

		^lcx:dx - child to start with

		bx:di - call back routine
			(must be vfptr if XIP'ed)
			ax, bp - parameters to call back
		OR
		bx = 0 ,di - ObjCompCallType
			ax - message to send to children
			bp - parameter to message

RETURN:		
		ax,cx,dx,bp - may be returned depending on message,
		call back or ObjCompCallType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12 Nov 1991	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyProcessSomeChildrenInDrawOrderCommon		proc	far
	class	GrObjBodyClass
	uses	bx,di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	es,bx			;segment of call back or zero

	push	cx			;initial child's handle
	push	dx			;initial child's chunk

	mov	bx, offset GOI_drawLink	;pass offset to LinkPart on stack
	push	bx
	push	es			;pass call-back routine
	push	di			;call back offset or ObjCompCallType

	mov	bx, offset GrObj_offset
CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	di,offset GBI_drawComp

	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack

	.leave
	ret
GrObjBodyProcessSomeChildrenInDrawOrderCommon		endp

GrObjRequiredExtInteractive2Code	ends


GrObjAlmostRequiredCode	segment resource


COMMENT @----------------------------------------------------------------------

MESSAGE: GrObjBodyInsertOrDeleteSpace -- MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
						for GrObjBodyClass

DESCRIPTION:	Insert or delete space from the body

PASS:
	*ds:si - instance data
	es - segment of GrObjBodyClass

	ax - The message

	ss:bp - InsertDeleteSpaceParams

RETURN:
	nothing

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
GrObjBodyInsertOrDeleteSpace	method dynamic	GrObjBodyClass,
					MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
	uses	bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx, SEGMENT_CS				;call back segment
	mov	di, offset GrObjBodyInsertOrDeleteSpaceCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	mov	bx,bp				;InsertDeleteSpaceParams

	;    Adjust body bounds
	;

	sub	sp,size RectDWord
	mov	bp,sp
	mov	ax,MSG_GB_GET_BOUNDS
	call	ObjCallInstanceNoLock
	adddw	ss:[bp].RD_right,ss:[bx].IDSP_space.PDF_x.DWF_int,ax
	adddw	ss:[bp].RD_bottom,ss:[bx].IDSP_space.PDF_y.DWF_int,ax
	mov	ax,MSG_GB_SET_BOUNDS
	call	ObjCallInstanceNoLock
	add	sp,size RectDWord

	.leave
	ret

GrObjBodyInsertOrDeleteSpace	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GrObjBodyInsertOrDeleteSpaceCB

DESCRIPTION:	Insert or delete space in an object

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	*es:di - body
	ss:bp - InsertDeleteSpaceParams

RETURN:
	carry - set to end processing (always returned clear)

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
GrObjBodyInsertOrDeleteSpaceCB	proc	far
	.enter

	mov	ax,MSG_GO_INSERT_OR_DELETE_SPACE
	call	ObjCallInstanceNoLockES

	clc
	.leave
	ret

GrObjBodyInsertOrDeleteSpaceCB	endp


GrObjAlmostRequiredCode	ends


GrObjExtNonInteractiveCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindNextGrObjThatOverlaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next grobject in draw order whose bounds
		overlap the bounds of the passed object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		^lcx:dx - od of original child
RETURN:		
		cx = 0 - no such object
		or
		^lcx:dx - object that overlaps

	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindNextGrObjThatOverlaps	method dynamic GrObjBodyClass, 
					MSG_GB_FIND_NEXT_GROBJ_THAT_OVERLAPS
overlappee	local	RectDWord
overlapper	local	RectDWord
ForceRef	overlapper
	.enter

	call	GrObjBodyGetGrObjsNextSibling	
	tst	bx
	jz	fail

	;    Get bounds of original child
	;

	push	si					;body chunk
	pushdw	bxax					;sibling od	
	movdw	bxsi,cxdx				;grobj od
	push	bp					;stack frame
	lea	bp,ss:[overlappee]
	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	dx,size RectDWord
	mov	ax,MSG_GO_GET_DW_PARENT_BOUNDS
	call	ObjMessage
	pop	bp					;stack frame
	popdw	cxdx					;sibling od
	pop	si					;body chunk

	;    Process children starting with sibling
	;

	mov	bx,SEGMENT_CS
	mov	di,offset GrObjBodyFindGrObjThatOverlapsCB
	call	GrObjBodyProcessSomeChildrenInDrawOrderCommon
	jnc	fail

done:
	.leave
	ret

fail:
	clr	cx
	jmp	done

GrObjBodyFindNextGrObjThatOverlaps		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindGrObjThatOverlapsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the childs bounds overlap the overlapped bounds
		then stop processing and return

CALLED BY:	ObjCompProcessChildren
		
PASS:		
		*ds:si - child
		*es:di - body
		bp inherited stack frame

RETURN:		
		stc - overlapper found
			^lcx:dx - od of overlapper
		clc - not found
		
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

		MUST BE FAR - it is used as a call back routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindGrObjThatOverlapsCB		proc	far
overlappee	local	RectDWord
overlapper	local	RectDWord

	uses	ax,ds,es,di,si
	.enter inherit

	;    Get bounds of this child
	;

	push	bp					;stack frame
	lea	bp,ss:[overlapper]
	mov	ax,MSG_GO_GET_DW_PARENT_BOUNDS
	call	ObjCallInstanceNoLock
	pop	bp					;stack frame

	;    Compare bounds with that of overlappee
	;

	push	ds,si					;current child
	mov	ax,ss
	mov	ds,ax
	mov	es,ax
	lea	si,ss:[overlappee]
	lea	di,ss:[overlapper]
	call	GrObjIsRectDWordOverlappingRectDWord?
	pop	ds,si					;current child
	jc	overlap

done:
	.leave
	ret

overlap:
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	jmp	done


GrObjBodyFindGrObjThatOverlapsCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindPrevGrObjThatOverlaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the prev grobject in draw order whose bounds
		overlap the bounds of the passed object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		^lcx:dx - od of original child
RETURN:		
		cx = 0 - no such object
		or
		^lcx:dx - object that overlaps

	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindPrevGrObjThatOverlaps	method dynamic GrObjBodyClass, 
					MSG_GB_FIND_PREV_GROBJ_THAT_OVERLAPS
overlappee	local	RectDWord
overlapper	local	RectDWord
ForceRef	overlapper
	.enter

	call	GrObjBodyGetGrObjsPrevSibling	
	tst	bx
	jz	fail

	;    Get bounds of original child
	;

	push	si					;body chunk
	pushdw	bxax					;sibling od	
	movdw	bxsi,cxdx				;grobj od
	push	bp					;stack frame
	lea	bp,ss:[overlappee]
	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	dx,size RectDWord
	mov	ax,MSG_GO_GET_DW_PARENT_BOUNDS
	call	ObjMessage
	pop	bp					;stack frame
	popdw	cxdx					;sibling od
	pop	si					;body chunk

	;    Process children starting with sibling
	;

	mov	bx,SEGMENT_CS
	mov	di,offset GrObjBodyFindGrObjThatOverlapsCB
	call	GrObjBodyProcessSomeChildrenInReverseOrderCommon
	jnc	fail

done:
	.leave
	ret

fail:
	clr	cx
	jmp	done

GrObjBodyFindPrevGrObjThatOverlaps		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetGrObjsNextSibling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the next sibling in draw order

CALLED BY:	INTERNAL
		call	GrObjBodyFindNextGrObjThatOverlaps

PASS:		
		*ds:si - GrObjBody
		^lcx:dx - grobject

RETURN:		
		bx = 0 if no sibling
		or
		^lbx:ax - optr

DESTROYED:	
		ax - if not returned

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			grobject will have sibling

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetGrObjsNextSibling		proc	near
	uses	di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,cx					;grobj handle
	mov	di,dx
	call	ObjLockObjBlock
	mov	es,ax
	GrObjDeref	di,es,di
	mov	ax,es:[di].GOI_drawLink.LP_next.chunk
	mov	di,es:[di].GOI_drawLink.LP_next.handle
	call	MemUnlock

	tst	di
	jz	noSibling
	test	ax,LP_IS_PARENT
	jnz	noSibling

	mov	bx,di					;sibling handle

done:
	.leave
	ret

noSibling:
	clr	bx
	jmp	done

GrObjBodyGetGrObjsNextSibling		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetGrObjsPrevSibling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the prev sibling in draw order

CALLED BY:	INTERNAL
		call	GrObjBodyFindPrevGrObjThatOverlaps

PASS:		
		*ds:si - GrObjBody
		^lcx:dx - grobject

RETURN:		
		bx = 0 if no sibling
		or
		^lbx:ax - optr

DESTROYED:	
		ax - if not returned

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			grobject will have sibling

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetGrObjsPrevSibling		proc	near
	uses	di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,cx					;grobj handle
	mov	di,dx
	call	ObjLockObjBlock
	mov	es,ax
	GrObjDeref	di,es,di
	mov	ax,es:[di].GOI_reverseLink.LP_next.chunk
	mov	di,es:[di].GOI_reverseLink.LP_next.handle
	call	MemUnlock

	tst	di
	jz	noSibling
	test	ax,LP_IS_PARENT
	jnz	noSibling

	mov	bx,di					;sibling handle

done:
	.leave
	ret

noSibling:
	clr	bx
	jmp	done

GrObjBodyGetGrObjsPrevSibling		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyProcessSomeChildrenInReverseOrderCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to some children of body in order of the
		reverse list, starting with the passed child

CALLED BY:	INTERNAL
		GrObjBodySendToChildren

PASS:		
		*ds:si - instance data of graphic body

		^lcx:dx - child to start with

		bx:di - call back routine
			(must be vfptr if XIP'ed)
			ax, bp - parameters to call back
		OR
		bx = 0 ,di - ObjCompCallType
			ax - message to send to children
			bp - parameter to message

RETURN:		
		ax,cx,dx,bp - may be returned depending on message,
		call back or ObjCompCallType

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	12 Nov 1991	Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyProcessSomeChildrenInReverseOrderCommon		proc	far
	class	GrObjBodyClass
	uses	bx,di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	es,bx			;segment of call back or zero

	push	cx			;initial child's handle
	push	dx			;initial child's chunk

	mov	bx, offset GOI_reverseLink;pass offset to LinkPart on stack
	push	bx
	push	es			;pass call-back routine
	push	di			;call back offset or ObjCompCallType

	mov	bx, offset GrObj_offset
CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	di,offset GBI_drawComp

	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack

	.leave
	ret
GrObjBodyProcessSomeChildrenInReverseOrderCommon		endp


GrObjExtNonInteractiveCode	ends



GrObjMiscUtilsCode	segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMakeInstructionsSelectableAndEditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear selection and edit locks on all instruction objects

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMakeInstructionsSelectableAndEditable	method dynamic GrObjBodyClass, 
			MSG_GB_MAKE_INSTRUCTIONS_SELECTABLE_AND_EDITABLE
	.enter

	mov	bx,SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyMakeInstructionsSelectableAndEditableCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	.leave
	ret
GrObjBodyMakeInstructionsSelectableAndEditable		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMakeInstructionsSelectableAndEditableCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If object is an instruction then clear its selection
		and edit locks

CALLED BY:	ObjCompProcessChildren as callback

PASS:		
		*(ds:si) - child
		*(es:di) - composite

RETURN:		
		nothing

DESTROYED:	
		di - ok because it is a call back routine

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMakeInstructionsSelectableAndEditableCB		proc	far
	class	GrObjClass
	uses	ax,cx,dx
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jz	done

	clr	cx					;set
	mov	dx,mask GOL_SELECT or mask GOL_EDIT	;reset
	mov	ax,MSG_GO_CHANGE_LOCKS
	call	ObjCallInstanceNoLockES
done:
	clc					;keep processing
	.leave
	ret
GrObjBodyMakeInstructionsSelectableAndEditableCB		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMakeInstructionsUnselectableAndUneditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set selection and edit locks on all instruction objects

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMakeInstructionsUnselectableAndUneditable method dynamic \
	GrObjBodyClass, MSG_GB_MAKE_INSTRUCTIONS_UNSELECTABLE_AND_UNEDITABLE
	.enter

	mov	bx,SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyMakeInstructionsUnselectableAndUneditableCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	.leave
	ret
GrObjBodyMakeInstructionsUnselectableAndUneditable		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMakeInstructionsUnselectableAndUneditableCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If object is an instruction then set its selection
		and edit locks

CALLED BY:	ObjCompProcessChildren as callback

PASS:		
		*(ds:si) - child
		*(es:di) - composite

RETURN:		
		nothing

DESTROYED:	
		di - ok because it is a call back routine

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMakeInstructionsUnselectableAndUneditableCB		proc	far
	class	GrObjClass
	uses	ax,cx,dx
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jz	done

	clr	dx					;reset
	mov	cx,mask GOL_SELECT or mask GOL_EDIT	;set
	mov	ax,MSG_GO_CHANGE_LOCKS
	call	ObjCallInstanceNoLockES
done:
	clc						;keep processing

	.leave
	ret
GrObjBodyMakeInstructionsUnselectableAndUneditableCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetGrObjDrawFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set GrObjDrawFlags in the body 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		
		cx - bits to set
		dx - bits to reset

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetGrObjDrawFlags	method dynamic GrObjBodyClass, 
				MSG_GB_SET_GROBJ_DRAW_FLAGS
	.enter

EC <	test	cx, not mask GrObjDrawFlags			>
EC <	ERROR_NZ GROBJ_BAD_GROBJ_DRAW_FLAGS			>
EC <	test	dx, not mask GrObjDrawFlags			>
EC <	ERROR_NZ GROBJ_BAD_GROBJ_DRAW_FLAGS			>

	mov	ax, MSG_GOAM_SET_GROBJ_DRAW_FLAGS
	clr	di
	call	GrObjBodyMessageToGOAM

	mov	ax, MSG_GB_UPDATE_INSTRUCTION_CONTROLLERS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodySetGrObjDrawFlags		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetGrObjDrawFlagsNoBroadcast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set GrObjDrawFlags in the body 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		
		cx - bits to set
		dx - bits to reset

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetGrObjDrawFlagsNoBroadcast	method dynamic GrObjBodyClass, 
				MSG_GB_SET_GROBJ_DRAW_FLAGS_NO_BROADCAST
	uses	dx
	.enter

EC <	test	cx, not mask GrObjDrawFlags			>
EC <	ERROR_NZ GROBJ_BAD_GROBJ_DRAW_FLAGS			>
EC <	test	dx, not mask GrObjDrawFlags			>
EC <	ERROR_NZ GROBJ_BAD_GROBJ_DRAW_FLAGS			>

	call	ObjMarkDirty

	; Check to see if we are going to be disabling instruction drawing.
	; If so, then before we actually set the bits, order all
	; instructions to become unselected.
	test	dx, mask GODF_DRAW_INSTRUCTIONS
	jz	doOperation
	
	test	ds:[di].GBI_drawFlags, mask GODF_DRAW_INSTRUCTIONS
	jz	doOperation
	
	push	bx, di
	mov	bx,SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyUnselectInstructionsCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon
	pop	bx, di
	
doOperation:
	not	dx
	andnf	ds:[di].GBI_drawFlags,dx
	ornf	ds:[di].GBI_drawFlags,cx
	
	push	cx, dx, bp
	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock			;Destroys: ax,cx,dx,bp
	pop	cx, dx, bp

	.leave
	ret
GrObjBodySetGrObjDrawFlagsNoBroadcast		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUnselectInstructionsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Causes all instruction objects to become unselected.

CALLED BY:	ObjCompProcessChildren as callback
    	    	by GrObjBodySetGrObjDrawFlagsNoBroadcast (INTERNAL)

PASS:		*(ds:si) - child
		*(es:di) - composite
		
RETURN:		carry clear to continre traversal
DESTROYED:	di - ok because it is a call back routine
		ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/13/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUnselectInstructionsCB	proc	far
	class	GrObjClass
	.enter
	
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jz	done

	mov	ax, MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLockES

done:
	clc
	
	.leave
	ret
GrObjBodyUnselectInstructionsCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDeleteInstructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all the instruction objects in the document

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDeleteInstructions method dynamic GrObjBodyClass, 
						MSG_GB_DELETE_INSTRUCTIONS
	.enter

	call	GrObjGlobalStartUndoChainNoText

	mov	bx,SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyDeleteInstructionsCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyDeleteInstructions		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDeleteInstructionsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If object is an instruction then delete it

CALLED BY:	ObjCompProcessChildren as callback

PASS:		
		*(ds:si) - child
		*(es:di) - composite

RETURN:		
		nothing

DESTROYED:	
		di - ok because it is a call back routine

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDeleteInstructionsCB		proc	far
	class	GrObjClass
	uses	ax,cx,dx
	.enter

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_attrFlags, mask GOAF_INSTRUCTION
	jz	done

	mov	ax,MSG_GO_CLEAR
	call	ObjCallInstanceNoLockES
done:
	clc
	.leave
	ret
GrObjBodyDeleteInstructionsCB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BodySearchSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we have a target and it is a text guardian
		then send the message to the guardian's ward, 
		otherwise find the first text object in draw order
		and send the message there.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		depends on message

RETURN:		
		none
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BodySearchSpell	method dynamic GrObjBodyClass, 
				MSG_SEARCH,
				MSG_SPELL_CHECK,
				MSG_REPLACE_CURRENT,
				MSG_REPLACE_ALL_OCCURRENCES,
				MSG_REPLACE_ALL_OCCURRENCES_IN_SELECTION,
				MSG_META_GET_CONTEXT,
				MSG_META_GENERATE_CONTEXT_NOTIFICATION
	.enter

	cmp	ax,MSG_SEARCH
	je	switchToTextTool
	cmp	ax,MSG_SPELL_CHECK
	je	switchToTextTool

continue:
	push	si

	;    If we have an editing object and it is TextGuardianClass
	;    or one of its subclasses, then get it's ward's od and
	;    send the search/spell message to the ward.
	;

	push	ax,cx,dx,bp				;message and data
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit
	pop	ax,cx,dx,bp				;message and data
	jz	firstText				;jmp if no edit
	jnc	firstText				;jmp if not guardian

	push	ax,cx,dx				;message and data
	mov	ax,MSG_GOVG_GET_VIS_WARD_OD
	mov	di,mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit
	movdw	bxsi,cxdx				;ward od
	pop	ax,cx,dx				;message and data

send:
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

done:
	.leave
	ret

firstText:
	;    Find first text object and send message to it.
	;
	call	GrObjBodyFindFirstText
	tst	bx
	jnz	send
	pop	si

	;    Yow, no text objects exist.  Record the message and send it to
	;    ourself so that it can be intercepted

	mov	di, mask MF_RECORD or mask MF_STACK
	cmp	ax, MSG_META_GENERATE_CONTEXT_NOTIFICATION
	je	onStack
	cmp	ax, MSG_META_GET_CONTEXT
	je	onStack
	cmp	ax, MSG_SPELL_CHECK
	jz	onStack
	mov	di, mask MF_RECORD
onStack:
	call	ObjMessage
	mov	cx, di
	mov	ax, MSG_GB_ABORT_SEARCH_SPELL_MESSAGE
	call	ObjCallInstanceNoLock
	jmp	done

switchToTextTool:
	;   If we didn't switch to the text tool now we could end up
	;   in a situation where a text object has the target but the
	;   the users has say the rectangle tool. It looks like they
	;   can edit the text, but when the click to do so they
	;   get a rectangle.
	;

	push	ax					;passed message #
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL
	call	GrObjBodyMessageToHead
	pop	ax					;passed message #
	jmp	continue

BodySearchSpell		endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBodyAbortSearchSpellMessage --
		MSG_GB_ABORT_SEARCH_SPELL_MESSAGE for GrObjBodyClass

DESCRIPTION:	Abort a search spell message

PASS:
	*ds:si - instance data
	es - segment of GrObjBodyClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/15/92		Initial version

------------------------------------------------------------------------------@
GrObjBodyAbortSearchSpellMessage	method dynamic	GrObjBodyClass,
					MSG_GB_ABORT_SEARCH_SPELL_MESSAGE

	;    attribute managers text object which has no
	;    text. It should clean up and generally do the
	;    right thing.
	;

	mov	ax, MSG_META_DISPATCH_EVENT
	clr	dx
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToGOAMText

	ret

GrObjBodyAbortSearchSpellMessage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetObjectForSearchSpell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the first/last/next/prev GrObjText to search

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - GrObjText currently being searched/spelled
		bp - GetSearchSpellObjectOption

RETURN:		
		cx:dx - new GrObjText or 0:0
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetObjectForSearchSpell	method dynamic GrObjBodyClass, 
					MSG_META_GET_OBJECT_FOR_SEARCH_SPELL
	.enter

	cmp	bp, GSSOT_FIRST_OBJECT
	je	findFirst
	cmp	bp,GSSOT_LAST_OBJECT
	je	findLast
	cmp	bp,GSSOT_NEXT_OBJECT
	je	findNext

	call	GrObjBodyFindPrevText
done:
	movdw	cxdx,bxsi
	.leave
	ret

findFirst:
	call	GrObjBodyFindFirstText
	jmp	done

findLast:
	call	GrObjBodyFindLastText
	jmp	done

findNext:
	call	GrObjBodyFindNextText
	jmp	done

GrObjBodyGetObjectForSearchSpell		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindFirstText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first text guardian in draw order and 
		return the od of its ward.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		bx:si - od of first GrObjText vis ward in draw order
		bx = 0 if no vis ward
	
DESTROYED:	
		si - destroyed if bx = 0

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindFirstText proc near
	uses	cx,dx,di				
	.enter

	mov	bx,SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyFindTextCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon
	jc	returnOD				;jmp if found

	clr	cx,dx					;not found
returnOD:
	movdw	bxsi,cxdx

	.leave
	ret
GrObjBodyFindFirstText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindLastText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the last text guardian in draw order and 
		return the od of its ward.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		bx:si - od of last GrObjText vis ward in draw order
		bx = 0 if no vis ward
	
DESTROYED:	
		si - destroyed if bx = 0

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindLastText proc near
	uses	cx,dx,di				
	.enter

	mov	bx,SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyFindTextCB
	call	GrObjBodyProcessAllGrObjsInReverseOrderCommon
	jc	returnOD				;jmp if found

	clr	cx,dx					;not found
returnOD:
	movdw	bxsi,cxdx

	.leave
	ret
GrObjBodyFindLastText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindNextText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the next text guardian in draw order and 
		return the od of its ward. Will NOT cycle back to 
		front of list.

PASS:		
		*(ds:si) - instance data of body

		cx:dx - vis ward to start with

RETURN:		
		bx:si - od of next vis ward in draw order
		bx = 0 if no vis ward
	
DESTROYED:	
		si - destroyed if bx = 0

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindNextText proc near
	class	GrObjBodyClass
	uses	ax,cx,dx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	si					;body chunk
	mov	bx,cx
	mov	si,dx
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GV_GET_GUARDIAN
	call	ObjMessage
	pop	si					;body chunk

	mov	ax,MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLock
	BitClr	cx, GOBAGOF_DRAW_LIST_POSITION
	cmp	cx,GOBAGOR_LAST
	je	notFound
	inc	cx
	clr	dx

	;    Start search with object after guardian
	;

	push	dx				;0
	push	cx				;object # after guardian

	;    Other parameters for ObjCompProcessChildren
	;

	mov	bx, offset GOI_drawLink	;pass offset to LinkPart on stack
	push	bx
	mov	bx, SEGMENT_CS			;callback segment (vseg if xip)
	push	bx
	mov	di,offset GrObjBodyFindTextCB
	push	di			;call back offset

	mov	bx, offset GrObj_offset		;grobj is master
CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	di,offset GBI_drawComp

	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack

	jc	returnOD				;jmp if found

notFound:
	clr	cx,dx					;not found

returnOD:
	movdw	bxsi,cxdx

	.leave
	ret
GrObjBodyFindNextText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindPrevText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the prev text guardian in draw order and 
		return the od of its ward. Will NOT cycle back to 
		front of list.

PASS:		
		*(ds:si) - instance data body

		cx:dx - vis ward to start with

RETURN:		
		bx:si - od of prev vis ward in draw order
		bx = 0 if no vis ward
	
DESTROYED:	
		si - destroyed if bx = 0

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindPrevText proc near
	class	GrObjBodyClass
	uses	ax,cx,dx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	si					;body chunk
	mov	bx,cx
	mov	si,dx
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_GV_GET_GUARDIAN
	call	ObjMessage
	pop	si					;body chunk

	mov	ax,MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLock
	cmp	dx,GOBAGOR_LAST
	je	notFound
	inc	dx
	clr	cx

	;    Start search with object after guardian in reverse list
	;

	push	cx				;0
	push	dx				;object # after guardian

	;    Other parameters for ObjCompProcessChildren
	;

	mov	bx, offset GOI_reverseLink;pass offset to LinkPart on stack
	push	bx
	mov	bx, SEGMENT_CS			;callback seg (vseg if XIP'ed)
	push	bx
	mov	di,offset GrObjBodyFindTextCB
	push	di			;call back offset

	mov	bx, offset GrObj_offset		;grobj is master
CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	di,offset GBI_reverseComp

	call	ObjCompProcessChildren	; must use a call (no GOTO) since
					; parameters are passed on the stack

	jc	returnOD				;jmp if found

notFound:
	clr	cx,dx					;not found

returnOD:
	movdw	bxsi,cxdx

	.leave
	ret
GrObjBodyFindPrevText		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindTextCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If object is an text guardian then return the od
		of its ward and stop search.

CALLED BY:	ObjCompProcessChildren as callback

PASS:		
		*(ds:si) - child
		*(es:di) - composite

RETURN:		
		cx:dx - od of ward if found

DESTROYED:	
		cx,dx - if not found

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindTextCB		proc	far
	class	GrObjClass
	uses	ax, bp
	.enter

	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLockES
	jnc	done

	mov	ax,MSG_GOVG_GET_VIS_WARD_OD
	call	ObjCallInstanceNoLockES

	stc						;stop 
done:
	.leave
	ret
GrObjBodyFindTextCB		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyHideUnselectedGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set GOL_SHOW lock in all objects not on the selection list

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyHideUnselectedGrObjs	method dynamic GrObjBodyClass, 
						MSG_GB_HIDE_UNSELECTED_GROBJS
	.enter

	call	GrObjGlobalUndoIgnoreActions

	mov	bx, SEGMENT_CS				;call back segment
	mov	di,offset GrObjBodyHideUnselectedGrObjsCB
	call	GrObjBodyProcessAllGrObjsInDrawOrderCommon

	call	GrObjGlobalUndoAcceptActions

	push	cx, dx, bp
	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock			;Destroys: ax,cx,dx,bp
	pop	cx, dx, bp

	.leave
	ret
GrObjBodyHideUnselectedGrObjs		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyHideUnselectedGrObjsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set GOL_SHOW lock in object it is not selected
		

CALLED BY:	ObjCompProcessChildren as callback

PASS:		
		*(ds:si) - child
		*(es:di) - composite

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyHideUnselectedGrObjsCB		proc	far
	class	GrObjClass
	uses	ax,cx,dx
	.enter

	;    Don't hide the selected objects or the one being edited.
	;

	mov	ax,MSG_GO_GET_TEMP_STATE_AND_OPT_FLAGS
	call	ObjCallInstanceNoLock
	test	ax,mask GOTM_SELECTED or mask GOTM_EDITED
	jnz	done

	mov	ax,MSG_GO_CHANGE_LOCKS
	mov	cx,mask GOL_SHOW
	clr	dx
	call	ObjCallInstanceNoLockES

done:
	clc						;stop 

	.leave
	ret
GrObjBodyHideUnselectedGrObjsCB		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyShowAllGrObjs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear GOL_SHOW lock in all objects

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyShowAllGrObjs	method dynamic GrObjBodyClass, 
						MSG_GB_SHOW_ALL_GROBJS
	uses	cx,dx
	.enter

	call	GrObjGlobalUndoIgnoreActions

	mov	ax,MSG_GO_CHANGE_LOCKS
	clr	cx
	mov	dx,mask  GOL_SHOW
	call	GrObjBodySendToChildren

	call	GrObjGlobalUndoAcceptActions

	push	bp
	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock			;Destroys: ax,cx,dx,bp
	pop	bp

	.leave
	ret
GrObjBodyShowAllGrObjs		endm

GrObjMiscUtilsCode	ends


