COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		body.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
GrObjBodySetBoundsLow	
GrObjBodyAlloc		
GrObjBodyAllocGrObjBlock
GrObjBodySetGrObjDrawFlags	

MSG_HANDLERS
	Name		
	----		
    GrObjBodyInitialize
    GrObjBodyVupCreateGState		
    GrObjBodyAddGrObj		
    GrObjBodyRemoveGrObj	
    GrObjBodyAddGrObjLow		
    GrObjBodyRemoveGrObjLow	
    GrObjBodyChangeGrObjDepth
    GrObjBodyAttachHead		
    GrObjBodyAttachGOAM
    GrObjBodyDetachGOAM
    GrObjBodyAttachRuler
    GrObjBodyStrayMouseEvents		
    GrObjBodyVupAlterInputFlow	
    GrObjBodyVisLayerSetDocBounds	
    GrObjBodyGetDocBounds		
    GrObjBodyGetBlockForOneGrObj
    GrObjBodyGrab
    GrObjBodyViewScaleFactorChanged
    GrObjBodyGetWindow
    GrObjBodyAddGrObjThenDraw		
    GrObjBodySetBounds
    GrObjBodyAttachUI
    GrObjBodyDetachUI
    GrObjBodySetActionNotificationOutput		
    GrObjBodySuspend
    GrObjBodyUnsuspend
    GrObjBodyAlterFTVMCExcl
    GrObjBodyGetTarget
    GrObjBodyGetFocus

    GrObjBodyGrabTargetFocus		
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	This file contains routines to implement the GrObjBody class.
		

	$Id: body.asm,v 1.1 97/04/04 18:08:08 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjInitCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Primitive initialization of body to match defaults
		in grobj.uih

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyInitialize	method dynamic GrObjBodyClass, MSG_META_INITIALIZE
	.enter

	mov	di,offset GrObjBodyClass
	call	ObjCallSuperNoLock

	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset

	; We'll need to mark ourselves as VTF_IS_INPUT_NODE in order to
	; get MSG_META_MUP_ALTER_FTVMC_EXCL.	-- Doug 2/9/93
	;
	ornf	ds:[di].VI_typeFlags, mask VTF_IS_INPUT_NODE

	;    Clear all the geometry bits that will make my life
	;    miserable
	;

	andnf	ds:[di].VI_optFlags, not (mask VOF_GEO_UPDATE_PATH or \
					mask VOF_GEOMETRY_INVALID  or \
					mask VOF_IMAGE_INVALID or \
					mask VOF_IMAGE_UPDATE_PATH )
	andnf	ds:[di].VI_attrs, not mask VA_MANAGED
	ornf	ds:[di].VI_attrs, mask VA_FULLY_ENABLED

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset

	mov	ds:[di].GBI_desiredHandleSize,DEFAULT_DESIRED_HANDLE_SIZE

	ornf	ds:[di].GBI_flags, mask GBF_DEFAULT_TARGET or \
				mask GBF_DEFAULT_FOCUS

	ornf	ds:[di].GBI_drawFlags, mask GODF_DRAW_INSTRUCTIONS

	;
	;  We want to set the interesting point to some outrageous value
	;  so that the first paste will end up the middle of the screen,
	;  rather than in the upper left corner
	;
	mov	ax, -30000
	segmov	es, ds
	add	di, offset GBI_interestingPoint
	mov	cx, size PointDWFixed/2
	rep stosw

	.leave
	ret
GrObjBodyInitialize		endm








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAttachHead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the od of the head in the body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBody

		cx:dx - optr of head

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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAttachHead	method dynamic GrObjBodyClass, MSG_GB_ATTACH_HEAD
	.enter

	mov	ds:[di].GBI_head.handle,cx
	mov	ds:[di].GBI_head.chunk,dx

	.leave
	ret
GrObjBodyAttachHead	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAttachGOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the od of the oam in the body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBody

		cx:dx - optr of goam

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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAttachGOAM	method dynamic GrObjBodyClass, MSG_GB_ATTACH_GOAM
	uses	cx,dx
	.enter

	mov	ds:[di].GBI_goam.handle,cx
	mov	ds:[di].GBI_goam.chunk,dx

	clr	di
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax, MSG_GOAM_ATTACH_BODY
	call	GrObjBodyMessageToGOAM

	.leave
	ret
GrObjBodyAttachGOAM	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDetachGOAM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the od of the oam in the body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBody

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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDetachGOAM	method dynamic GrObjBodyClass, MSG_GB_DETACH_GOAM
	.enter

	clr	ds:[di].GBI_goam.handle

	clr	di
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax, MSG_GOAM_DETACH_BODY
	call	GrObjBodyMessageToGOAM

	.leave
	ret
GrObjBodyDetachGOAM	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAttachRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the od of the ruler in the body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBody

		cx:dx - optr of ruler

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
	srs	7/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAttachRuler	method dynamic GrObjBodyClass, MSG_GB_ATTACH_RULER
	.enter

	mov	ds:[di].GBI_ruler.handle,cx
	mov	ds:[di].GBI_ruler.chunk,dx

	.leave
	ret
GrObjBodyAttachRuler	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle MSG_VIS_OPEN
		Note: We purposely don't call our super class because
		we don't want the superclass to muck with the vis bits
		nor do we want it to send vis open to our children.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass
		bp - window

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVisOpen	method GrObjBodyClass, MSG_VIS_OPEN
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	; ds:di = VisInstance
EC <	test	ds:[di].VI_attrs, mask VA_REALIZED		>
EC <	ERROR_NZ	GRAPHIC_OBJECT_ALREADY_OPENED		>

	;    If not passed a window, then query up for one
	;

	tst	bp					;window
	jnz	haveWindow
	call	VisQueryParentWin  	
EC <	tst	di						>
EC <	ERROR_Z		GRAPHIC_NO_PARENT_WIN_FOUND		>
	mov	bp, di		    			;window

haveWindow:
	; INCREMENT INTERACTIBLE COUNT for object
	; block.  The other half of this
	; inc/dec pair is mirrored in
	; VisClose, which is one more reason
	; why these methods must be
	; symmetrical.

	call	ObjIncInteractibleCount	

	;   Mark body as realized and if it is a composite then
	;   store the window handle
	;

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset	
	or	ds:[di].VI_attrs, mask VA_REALIZED	
	test	ds:[di].VI_typeFlags, mask VTF_IS_COMPOSITE
	jz	done			; if not, done

	; Save window handle for non-win composites
	;

EC <	cmp	ds:[di].VCI_window, 0   	; see if window stored here	>
EC <	ERROR_NZ	GRAPHIC_OBJECT_NOT_REALIZED_YET_HAS_GWIN	>
EC <	xchg	bx, bp							>
EC <	call	ECCheckWindowHandle					>
EC <	xchg	bx, bp							>
	mov	ds:[di].VCI_window, bp	;keep window handle in instance data

	;    If for some reason we created a gstate when we didn't have
	;    a window then jump to recreate our gstate and any
	;    of our childrens' cached gstates, otherwise
	;    just vup us a new one.
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_graphicsState
	jnz	recreate

	mov	ax,MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	ds:[di].GBI_graphicsState,bp

	;    Vis objects in the grobj do not receive vis open
	;    So, don't send it
	;

checkTargeted:
	;    If already gained target then draw handles of objects with
	;    newly created gstate. Else grab target and the gain target
	;    excl routine will draw the handles
	;

	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jnz	drawHandles			;jmp if already the target

done:
	.leave
	ret

	;;  We already have the target but have been unable to draw
	;;  the handles of the currently selected objects
	;;  because we had no gstate, but now we do
	;;  Also, update the ui for the selected objects

drawHandles:
	mov	dx,ds:[di].GBI_graphicsState
	mov	ax,MSG_GO_DRAW_HANDLES_RAW
	call	GrObjBodySendToSelectedGrObjsAndEditGrab

	mov	cx, mask GrObjUINotificationTypes
	mov	ax,MSG_GB_UPDATE_UI_CONTROLLERS
	call	ObjCallInstanceNoLock
	jmp	short done

recreate:
	mov	ax,MSG_VIS_RECREATE_CACHED_GSTATES
	call	ObjCallInstanceNoLock
	jmp	checkTargeted

GrObjBodyVisOpen		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Handle MSG_VIS_CLOSE

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			gstate exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVisClose	method dynamic GrObjBodyClass, MSG_VIS_CLOSE
	.enter

	mov	di,offset GrObjBodyClass
	call	ObjCallSuperNoLock

	;    Vis objects in the grobj don't receive vis close
	;    So don't send it.
	;

	;    Destroy the gstate if it exists.  They may not be a gstate
	;    if the user reverts to an empty document.
	;

	mov	bx,ds:[si]
	add	bx,ds:[bx].GrObjBody_offset
	clr	di
	xchg	di,ds:[bx].GBI_graphicsState
	tst	di
	jz	done
	call	GrDestroyState

done:

	Destroy	ax,cx,dx,bp
	.leave
	ret
GrObjBodyVisClose		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAttachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare GrObjBody for opening after it has been
		added to the Document/Content. Mark body as open
		and create selection array.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - OD of GrObjHead

RETURN:		
		nothing
	

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAttachUI	method dynamic GrObjBodyClass, MSG_GB_ATTACH_UI
	.enter

	;    Do some heavy error checking on the vm file
	;

EC <	push	ax,bx							>
EC <	test	ds:[LMBH_flags],mask LMF_IS_VM				>
EC <	ERROR_Z	GROBJ_BODY_MUST_BE_ATTACHED_TO_VM			>
EC < 	mov	bx,ds:[LMBH_handle]					>
EC <	mov	ax,MGIT_OWNER_OR_VM_FILE_HANDLE				>
EC <	call	MemGetInfo						>
EC <	mov	bx,ax				;vm file handle		>
EC <	call	VMGetAttributes						>
EC <	test	al, mask VMA_OBJECT_RELOC 				>
EC <	ERROR_Z	GROBJ_BAD_VM_ATTRIBUTES					>
EC <	test	al, mask VMA_SYNC_UPDATE or mask VMA_TEMP_ASYNC		>
EC <	ERROR_Z	GROBJ_BAD_VM_ATTRIBUTES					>
EC <	test	al, mask VMA_NO_DISCARD_IF_IN_USE			>
EC <	ERROR_Z	GROBJ_BAD_VM_ATTRIBUTES					>
EC <	pop	ax,bx							>

	;    The body cannot be discarded. So inc its in use count
	;    which will prevent it from being discarded. 
	;    In general the in use count will already be non zero
	;    because the body will be added to the content/document
	;    with MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD each time the
	;    document is opened.. However, in some files the body may 
	;    be a child of an object in the file, so the body will not
	;    be added to this other object each time the document is opened.
	;    So incing the in use count here will prevent the body from
	;    being discarded in these cases. (Note: the in use count
	;    is cleared whenever a file is opened)
	;

	call	ObjIncInUseCount

	mov	ax,MSG_GB_ATTACH_HEAD
	call	ObjCallInstanceNoLock

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	ornf	ds:[di].GBI_fileStatus, mask GOFS_OPEN

	call	GrObjBodyCreateSelectionArray


	;    Must grab grabs after creating selection array because
	;    the GAINED messages may need to process selection list
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	test	ds:[di].GBI_flags, mask GBF_DEFAULT_TARGET
	jz	checkDefaultFocus
	call	MetaGrabTargetExclLow

checkDefaultFocus:
	test	ds:[di].GBI_flags, mask GBF_DEFAULT_FOCUS
	jz	done
	call	MetaGrabFocusExclLow
done:
	.leave
	ret

GrObjBodyAttachUI		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDetachUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare GrObjBody for closing before it is removed
		from the body. Mark body as closed and destroy 
		selection array.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDetachUI	method dynamic GrObjBodyClass, MSG_GB_DETACH_UI
	.enter

	;
	;    We probably won't have an undo context here -- in any case, we
	;    want to ignore these actions, so no chains/actions will be added,
	;    causing a horrible death.
	;
	call	GrObjGlobalUndoIgnoreActions

	;
	; clear this flag before releasing the target, so that
	; children will know the document is closing
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	andnf	ds:[di].GBI_fileStatus, not mask GOFS_OPEN

	;    Must release grabs before destroying selection array
	;    because some of the LOST message do things with the
	;    selection list.
	;

	call	MetaReleaseFocusExclLow
	call	MetaReleaseTargetExclLow


	;    We may have become the current body without become the 
	;    target if the EditTextGuardian rejected a start select.
	;    So just in case make sure we aren't the current body.
	;

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GH_CLEAR_CURRENT_BODY
	clr	di				;MessageFlags
	call	GrObjBodyMessageToHead


	;    If we didn't do this then we would end up with objects
	;    that had their GOTM_SELECTED bit set but weren't
	;    in the selection array.
	;

	call	GrObjBodyRemoveAllGrObjsFromSelectionList
	call	GrObjBodyDestroySelectionArray


	call	GrObjGlobalUndoAcceptActions
	.leave
	ret
GrObjBodyDetachUI		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetBoundsWithoutMarkingDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bounds of body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp  - RectDWord

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetBoundsWithoutMarkingDirty	method dynamic GrObjBodyClass, MSG_GB_SET_BOUNDS_WITHOUT_MARKING_DIRTY
	.enter

	call	GrObjBodySetBoundsLow

	.leave
	ret
GrObjBodySetBoundsWithoutMarkingDirty	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return bounds of the Body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - RectDWord buffer to fill

RETURN:		
		ss:bp - RectDWord buffer filled
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetBounds	method dynamic GrObjBodyClass, MSG_GB_GET_BOUNDS
	uses	cx
	.enter

	lea	si, ds:[di].GBI_bounds		;ds:si = source
	segmov	es, ss
	mov	di, bp
	mov	cx, (size RectDWord)/2
	rep	movsw

	.leave
	ret
GrObjBodyGetBounds		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyVisLayerSetDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the document bounds to the passed rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		ss:bp - RectDWord structure

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
       chrisb	11/14/91	Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVisLayerSetDocBounds	method dynamic GrObjBodyClass,
					MSG_VIS_LAYER_SET_DOC_BOUNDS,
					MSG_GB_SET_BOUNDS

	;
	; If there's no change, don't mark dirty!
	;
		
		push	si
		lea	si, ds:[di].GBI_bounds
		mov	di, bp
		segmov	es, ss
		mov	cx, size RectDWord/2
		repe	cmpsw
		pop	si

		je	done

		call	ObjMarkDirty
		call	GrObjBodySetBoundsLow
done:
		ret
GrObjBodyVisLayerSetDocBounds		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetBoundsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bounds of body

CALLED BY:	INTERNAL
		GrObjBodySetBounds

PASS:		
		*(ds:si) - body instance
		ss:bp - RectDWord


RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOTE: This low level routine does NOT dirty the document. 
		This simplifies things for the spreadsheet which doesn't
		want to dirty the document when the bounds change. It
		can subclass the messages for changing the bound and
		have them call this routine without also calling ObjMarkDirty.

		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetBoundsLow		proc	far
	uses	ax,bx,cx,dx,bp,di,es
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject	>

	;    Copy the new bounds into the body's instance data noting
	;    if the upper left of the bounds move.
	;

	clr	cx				;assume no gstate recalc needed
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset

	movdw	bxax,ss:[bp].RD_left
	cmpdw	bxax,ds:[di].GBI_bounds.RD_left
	je	10$
	inc	cx				;left moved, need recalc gstate
	movdw	ds:[di].GBI_bounds.RD_left,bxax

10$:
	movdw	bxax,ss:[bp].RD_top
	cmpdw	bxax,ds:[di].GBI_bounds.RD_top
	je	20$
	inc	cx				;top moved, need recalc gstate
	movdw	ds:[di].GBI_bounds.RD_top,bxax

20$:
	movdw	bxax,ss:[bp].RD_right
	movdw	ds:[di].GBI_bounds.RD_right,bxax
	movdw	bxax,ss:[bp].RD_bottom
	movdw	ds:[di].GBI_bounds.RD_bottom,bxax

	;    If the upper left didn't change then we are done
	;

	jcxz	done

	;    The upper left changing affects the
	;    translation stored in the cached gstate
	;

	mov	ax,MSG_VIS_RECREATE_CACHED_GSTATES
	call	ObjCallInstanceNoLock

	;    Changing the upper left also affects how mouse events
	;    are translated.
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	test	ds:[di].GBI_fileStatus,mask GOFS_MOUSE_GRAB
	jz	done

	call	VisGrabMouse

done:
	.leave
	ret
GrObjBodySetBoundsLow		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyViewScaleFactorChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the body that the scale factor in the view has
		changed. This default handler recalculates the
		curHandleWidth and curHandleHeight based on the new
		scale factor and desiredHandle size

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		ss:bp - ScaleChangedParams

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		DO NOT MARK THE BODY DIRTY when setting the curHandleWidth
		and curHandleHeight information. This info is only 
		relevant while the document is open so it does not need
		to be saved. Plus, MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED
		is always sent when the document is opened, so the body
		would always become instantly dirty. Very bad.

		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyViewScaleFactorChanged	method dynamic GrObjBodyClass, 
				MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED
	.enter

CheckHack <offset SCP_scaleFactor eq 0>
	call	GrObjBodyCalcHandleSizesFromScaleFactor

	.leave
	ret
GrObjBodyViewScaleFactorChanged		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCalcHandleSizesFromScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Calculates GBI_curHandle* from the passed view scale
		and the desired handle size. Also figures out nudge
		distances

Pass:		*ds:si - GrObjBody
		ss:[bp] - PointWWFixed

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCalcHandleSizesFromScaleFactor		proc	far
	class	GrObjBodyClass
	uses	ax, bx, cx, dx, di
	.enter

	;
	;  Store the current scale factor. Why? I don't know
	;
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	movwwf	ds:[di].GBI_curScaleFactor.PF_x,ss:[bp].SCP_scaleFactor.PF_x,ax
	movwwf	ds:[di].GBI_curScaleFactor.PF_y,ss:[bp].SCP_scaleFactor.PF_y,ax

	;
	;  Calculate document sizes of handles to achieve desired pixel size
	;
	mov	dl,ds:[di].GBI_desiredHandleSize
	tst	dl
	jns	gotDesired
	neg	dl
gotDesired:
	clr	dh
	push	dx
	clr	cx
	movwwf	bxax, ss:[bp].SCP_scaleFactor.PF_x
	call	GrUDivWWFixed
	rndwwf	dxcx
	mov	ds:[di].GBI_curHandleWidth,dl

	mov	dx,1
	clr	cx
	call	GrUDivWWFixed
	mov	ds:[di].GBI_curNudgeX.BBF_int,dl
	mov	ds:[di].GBI_curNudgeX.BBF_frac,ch

	pop	dx
	clr	cx
	movwwf	bxax,ss:[bp].SCP_scaleFactor.PF_y
	call	GrUDivWWFixed
	rndwwf	dxcx
	mov	ds:[di].GBI_curHandleHeight,dl

	mov	dx,1
	clr	cx
	call	GrUDivWWFixed
	mov	ds:[di].GBI_curNudgeY.BBF_int,dl
	mov	ds:[di].GBI_curNudgeY.BBF_frac,ch

	call	GrObjBodySetCurrentOptionsOnViewScaleFactorChanged

	.leave
	ret
GrObjBodyCalcHandleSizesFromScaleFactor	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetCurrentOptionsOnViewScaleFactorChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the GOFA_VIEW_ZOOMED bit in the body's current
		options if the view is zoomed in

CALLED BY:	INTERNAL
		GrObjBodyViewScaleFactorChanged

PASS:		*ds:si - body


RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Don't need to mark dirty because this bit isn't saved
		with the document and the body won't get discarded

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetCurrentOptionsOnViewScaleFactorChanged		proc	near
	class	GrObjBodyClass
	uses	di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset

	BitClr	ds:[di].GBI_currentModifiers, GOFA_VIEW_ZOOMED

	cmp	ds:[di].GBI_curScaleFactor.PF_x.WWF_int,1
	jne	checkXAbove
	tst	ds:[di].GBI_curScaleFactor.PF_x.WWF_frac
	jnz	setBit
	
checkY:
	cmp	ds:[di].GBI_curScaleFactor.PF_y.WWF_int,1
	jne	checkYAbove
	tst	ds:[di].GBI_curScaleFactor.PF_y.WWF_frac
	jnz	setBit

done:
	.leave
	ret

checkXAbove:
	ja	setBit
	jmp	checkY

checkYAbove:
	jb	done

setBit:
	BitSet	ds:[di].GBI_currentModifiers, GOFA_VIEW_ZOOMED
	jmp	done

GrObjBodySetCurrentOptionsOnViewScaleFactorChanged		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUpdateFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide default focus node behavior

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUpdateFocusExcl method GrObjBodyClass, 
					MSG_META_GAINED_FOCUS_EXCL,
					MSG_META_LOST_FOCUS_EXCL,
					MSG_META_GAINED_SYS_FOCUS_EXCL
	.enter

	mov	bp, MSG_META_GAINED_FOCUS_EXCL
	mov	bx, offset GrObjBody_offset
	mov	di, offset GBI_focusExcl
	call	FlowUpdateHierarchicalGrab


	.leave

	Destroy	ax,cx,dx,bp

	ret


GrObjBodyUpdateFocusExcl		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLostSystemFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide default focus node behavior, and turn off
		"GOFA_KEYBOARD_SPECIFIC" flag.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLostSystemFocusExcl method dynamic GrObjBodyClass, 
					MSG_META_LOST_SYS_FOCUS_EXCL
	.enter

	;    Pass on lost focus
	;

	call	GrObjBodyUpdateFocusExcl	; Provide default behavior

	;    We no longer know what keys are down
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	andnf	ds:[di].GBI_currentModifiers, not GOFA_KEYBOARD_SPECIFIC
	call	GrObjBodySetOptions

	Destroy	ax,cx,dx,bp

	.leave
	ret


GrObjBodyLostSystemFocusExcl		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetFocusExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the od of the body's focusExcl

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		cx:dx - od of focus
	
DESTROYED:	
		ax,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetFocusExcl	method dynamic GrObjBodyClass, 
						MSG_META_GET_FOCUS_EXCL
	.enter

	mov	cx,ds:[di].GBI_focusExcl.HG_OD.handle
	mov	dx,ds:[di].GBI_focusExcl.HG_OD.chunk

	stc

	.leave

	Destroy	ax,bp

	ret
GrObjBodyGetFocusExcl		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the od of the body's targetExcl

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		cx:dx - od of target
	
DESTROYED:	
		ax,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetTargetExcl	method dynamic GrObjBodyClass, 
						MSG_META_GET_TARGET_EXCL
	.enter

	mov	cx,ds:[di].GBI_targetExcl.HG_OD.handle
	mov	dx,ds:[di].GBI_targetExcl.HG_OD.chunk

	stc

	.leave

	Destroy	ax,bp

	ret
GrObjBodyGetTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAlterFTVMCExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The body is a target and focus node. 
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
	
		cx:dx - optr to grab/release exclusive for
		bp - MetaAlterFTVMCExclFlags

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAlterFTVMCExcl	method dynamic GrObjBodyClass, 
						MSG_META_MUP_ALTER_FTVMC_EXCL
	.enter

	test	bp, mask MAEF_NOT_HERE
	jnz	callSuper

next:
	;    If this is not for the target or focus then handle normally
	;

	test	bp, mask MAEF_TARGET
	jnz	target

	test	bp, mask MAEF_FOCUS
	jnz	focus


callSuper:
	;    If no requests for operations left then exit
	;    Otherwise pass message on to superclass 
	;

	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done

	mov	ax,MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, offset GrObjBodyClass
	call	ObjCallSuperNoLock

done:
	Destroy	ax,cx,dx,bp

	.leave
	ret

target:
	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	bx, mask MAEF_TARGET
	mov	di, offset GBI_targetExcl

doHierarchy:
	push	bp,bx			;orig flags, flag we are handling
	and	bp, mask MAEF_GRAB
	or	bp, bx			;or back in hierarchy flag
	mov	bx, offset GrObjBody_offset
	call	FlowAlterHierarchicalGrab
	pop	bp,bx			;orig flags, flag we are handling

	;    Clear out bit we just handled
	;

	not	bx			; get not mask for hierarchy
	and	bp, bx			; clear request on this hierarchy
	jmp	next


focus:
	mov	ax, MSG_META_GAINED_FOCUS_EXCL
	mov	bx, mask MAEF_FOCUS
	mov	di, offset GBI_focusExcl
	jmp	doHierarchy


GrObjBodyAlterFTVMCExcl		endm

GrObjInitCode	ends


GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle relocation and unrelocation of object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

 		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
 		cx - handle of block containing relocation
 		dx - VMRelocType:
 			VMRT_UNRELOCATE_BEFORE_WRITE
 			VMRT_RELOCATE_AFTER_READ
 			VMRT_RELOCATE_AFTER_WRITE
 		bp - data to pass to ObjRelocOrUnRelocSuper

RETURN:		
		carry - set if error
	
DESTROYED:	
		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyReloc	method dynamic GrObjBodyClass, reloc
	.enter

	;    If the body is being relocated after being read from the
	;    file then it can't have a parent or a window and it can't
	;    be realized. Also, it can no longer be the target
	;

	call	GrObjBodyRelocObjBlockArray

	cmp	ax,MSG_META_RELOCATE
	jne	done

	cmp	dx,VMRT_RELOCATE_AFTER_READ
	jne	done


	andnf	ds:[di].GBI_fileStatus, not ( mask GOFS_TARGETED or \
					mask GOFS_OPEN )

	;    Clear any suspension. Otherwise if we crashed and it 
	;    was set it would never get cleared again.
	;

	mov	ax,ATTR_GB_ACTION_NOTIFICATION
	call	ObjVarFindData
	jnc	clearStuff
	clr	ds:[bx].GOANS_suspendCount


clearStuff:
	clr	ax
	mov	ds:[di].GBI_unsuspendOps, ax
	mov	ds:[di].GBI_suspendCount,ax
	mov	ds:[di].GBI_mouseGrab.handle,ax
	mov	ds:[di].GBI_mouseGrab.chunk,ax
	mov	ds:[di].GBI_targetExcl.HG_OD.handle,ax
	mov	ds:[di].GBI_focusExcl.HG_OD.handle,ax
	mov	ds:[di].GBI_targetExcl.HG_OD.chunk,ax
	mov	ds:[di].GBI_focusExcl.HG_OD.chunk,ax
	mov	ds:[di].GBI_targetExcl.HG_flags,ax
	mov	ds:[di].GBI_focusExcl.HG_flags,ax
	mov	ds:[di].GBI_head.handle,ax
	mov	ds:[di].GBI_head.chunk,ax
	mov	ds:[di].GBI_graphicsState,ax
	mov	ds:[di].GBI_currentModifiers,ax

	mov	ds:[di].GBI_selectionArray.handle, ax
	mov	ds:[di].GBI_selectionArray.chunk, ax

	mov 	di,ds:[si]
	add	di,ds:[di].Vis_offset

	mov	ds:[di].VCI_window,ax
	mov	ds:[di].VCI_gadgetExcl.handle, ax
	mov	ds:[di].VCI_gadgetExcl.chunk, ax
	BitSet	ds:[di].VI_typeFlags, VTF_IS_INPUT_NODE

done:
	.leave
	mov	di, offset GrObjBodyClass
	call	ObjRelocOrUnRelocSuper
	ret

GrObjBodyReloc		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyRelocObjBlockArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Handle relocation and unrelocation of the obj block array

Pass:		*ds:si - GrObjBody
		ax - MSG_META_RELOCATE or MSG_META_UNRELOCATE

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRelocObjBlockArray	proc	near
	class	GrObjBodyClass
	uses	ax, bx, cx, dx, di, si
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].GrObjBody_offset
	mov	si, ds:[si].GBI_objBlockArray
	tst	si
	jz	done

	mov	bx, cs
	mov	di, offset UnRelocateCB
	cmp	ax, MSG_META_RELOCATE
	jne	enumerate
	mov	di, offset RelocateCB
enumerate:
	call	ChunkArrayEnum

done:
	.leave
	ret
GrObjBodyRelocObjBlockArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RelocateCB, UnRelocateCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to relocate/unrelocate an OD

CALLED BY:

PASS:		ds:di - address at which to do the dirty deed.

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RelocateCB	proc far

	.enter
	mov	al, RELOC_HANDLE
	mov	cx, ds:[di].GOBHE_blockHandle
	mov	bx, ds:[LMBH_handle]
	call	ObjDoRelocation
	mov	ds:[di].GOBHE_blockHandle, cx

	.leave
	ret
RelocateCB	endp

UnRelocateCB	proc far

	.enter
	mov	al, RELOC_HANDLE
	mov	cx, ds:[di].GOBHE_blockHandle
	mov	bx, ds:[LMBH_handle]
	call	ObjDoUnRelocation
	mov	ds:[di].GOBHE_blockHandle, cx

	.leave
	ret
UnRelocateCB	endp

GrObjDrawCode	ends



GrObjMiscUtilsCode segment resource





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyVisInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_VIS_INVALIDATE

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	ax,cx,dx,bp

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
	srs	12/9/92		Now uses body bounds instead of window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVisInvalidate	method dynamic	GrObjBodyClass, MSG_VIS_INVALIDATE
	.enter

	mov	ax, MSG_GB_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	mov	di, bp					;gstate

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	add	si,offset GBI_bounds
	call	GrInvalRectDWord

	call	GrDestroyState
	
	.leave

	Destroy ax,cx,dx,bp

	ret

GrObjBodyVisInvalidate	endm	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBody method for MSG_GB_INVALIDATE

		Invalidates all of the GrObjs in this body

Called by:	

Pass:		*ds:si = GrObjBody object
		ds:di = GrObjBody instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyInvalidate	method dynamic	GrObjBodyClass, MSG_GB_INVALIDATE

	.enter

	mov	ax, MSG_GO_INVALIDATE
	call	GrObjBodySendToChildren	

	.leave
	ret
GrObjBodyInvalidate	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetDesiredHandleSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the desired handle size of selected GrObj's under
		the body.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cl - desired handle size (in DEVICE coords)

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		need to correctly erase old/draw new

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	26 feb 1992	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetDesiredHandleSize	method	dynamic	GrObjBodyClass,
				MSG_GB_SET_DESIRED_HANDLE_SIZE
	uses	dx, bp
	.enter

	;
	;  Create a gstate for drawing/undrawing handles
	;
	mov	ax, MSG_GB_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	dx, bp					;dx <- gstate

	;
	;  Undraw any current handles
	;
	mov	ax, MSG_GO_UNDRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs

	;
	;  Record the new size
	;
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	mov	ds:[di].GBI_desiredHandleSize, cl

	;
	;  Calculate the actual size
	;
	mov	dl,cl
	tst	dl
	jns	gotDesired
	neg	dl
gotDesired:
	clr	dh
	push	dx
	clr	cx
	movwwf	bxax, ds:[di].GBI_curScaleFactor.PF_x
	call	GrUDivWWFixed
	rndwwf	dxcx
	mov	ds:[di].GBI_curHandleWidth,dl

	pop	dx
	clr	cx
	movwwf	bxax, ds:[di].GBI_curScaleFactor.PF_y
	call	GrUDivWWFixed
	rndwwf	dxcx
	mov	ds:[di].GBI_curHandleHeight,dl

	;
	;  Draw the new handles
	;
	mov	dx, bp					;dx <- gstate
	mov	ax, MSG_GO_DRAW_HANDLES
	call	GrObjBodySendToSelectedGrObjs

	;
	;  Free the gstate
	;
	mov	di, dx
	call	GrDestroyState

	mov	ax, MSG_GB_UPDATE_INSTRUCTION_CONTROLLERS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodySetDesiredHandleSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetDesiredHandleSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the desired handle size of selected GrObj's under
		the body.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass


RETURN:		
		al - desired handle size (in DEVICE coords)
	
DESTROYED:	

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		need to correctly erase old/draw new

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	26 feb 1992	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetDesiredHandleSize	method	dynamic	GrObjBodyClass,
				MSG_GB_GET_DESIRED_HANDLE_SIZE
	.enter

	mov	al, ds:[di].GBI_desiredHandleSize

	.leave
	ret
GrObjBodyGetDesiredHandleSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return window stored in vis comp instance data

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		cx - window

	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetWindow	method dynamic GrObjBodyClass, MSG_GB_GET_WINDOW
	.enter

	add	bx,ds:[bx].Vis_offset
	mov	cx,ds:[bx].VCI_window

	.leave
	ret
GrObjBodyGetWindow		endm












COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

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
	srs	6/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyClear	method dynamic GrObjBodyClass, MSG_GB_CLEAR
	uses	cx,dx
	.enter

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	clr	di				;MessageFlags
	mov	ax,MSG_GH_CLEAR_CURRENT_BODY
	call	GrObjBodyMessageToHead
	mov	ax,MSG_GOAM_DETACH_BODY
	call	GrObjBodyMessageToGOAM

	mov	ax,MSG_VIS_DESTROY
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyClear		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free up any chunks or other blocks
		See header in GrObjBodyClear

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyFinalObjFree

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
	srs	6/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFinalObjFree	method dynamic GrObjBodyClass, 
						MSG_META_FINAL_OBJ_FREE
	.enter

	mov	ax,MSG_GO_QUICK_TOTAL_BODY_CLEAR
	call	GrObjBodySendToChildren

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	di,ds:[di].GBI_graphicsState
	tst	di
	jz	10$
	call	GrDestroyState

10$:
	call	GrObjBodyDestroySelectionArray
	call	GrObjBodyPriorityListDestroy

	call	GrObjBodyFreeObjBlocks

	mov	ax,MSG_META_FINAL_OBJ_FREE
	mov	di,offset GrObjBodyClass
	call	ObjCallSuperNoLock

	.leave
	ret
GrObjBodyFinalObjFree		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyFreeObjBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Handle relocation and unrelocation of the obj block array

Pass:		*ds:si - GrObjBody
		ax - MSG_META_RELOCATE or MSG_META_UNRELOCATE

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFreeObjBlocks	proc	near
	class	GrObjBodyClass
	uses	ax, bx, cx, dx, di, si
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].GrObjBody_offset
	mov	si, ds:[si].GBI_objBlockArray
	tst	si
	jz	done

	mov	bx, cs
	mov	di, offset FreeBlocksCB
	call	ChunkArrayEnum
	call	ChunkArrayZero

done:
	.leave
	ret
GrObjBodyFreeObjBlocks	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to relocate/unrelocate an OD

CALLED BY:

PASS:		ds:di - address at which to do the dirty deed.

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeBlocksCB	proc far

	.enter

	mov	bx, ds:[di].GOBHE_blockHandle
	call	ObjFreeObjBlock

	.leave
	ret
FreeBlocksCB	endp


GrObjMiscUtilsCode ends 










GrObjRequiredInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGrabTargetFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the target and the focus

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
	srs	5/21/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGrabTargetFocus	method dynamic GrObjBodyClass, 
						MSG_GB_GRAB_TARGET_FOCUS
	.enter

	call	MetaGrabTargetExclLow
	call	MetaGrabFocusExclLow

	.leave
	ret
GrObjBodyGrabTargetFocus		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUpdateTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Provide default target node behavior

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	9/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUpdateTargetExcl method GrObjBodyClass,
				MSG_META_GAINED_SYS_TARGET_EXCL,
				MSG_META_LOST_SYS_TARGET_EXCL
	.enter

	mov	bp, MSG_META_GAINED_TARGET_EXCL	; Pass "base" message in bp
	mov	bx, offset GrObjBody_offset
	mov	di, offset GBI_targetExcl
	call	FlowUpdateHierarchicalGrab

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	cmp	ax,MSG_META_GAINED_SYS_TARGET_EXCL
	je	setBit
	cmp	ax,MSG_META_LOST_SYS_TARGET_EXCL
	je	clearBit

done:
	.leave
	ret

setBit:
	BitSet	ds:[di].GBI_fileStatus, GOFS_SYS_TARGETED
	mov	cl,TRUE
	jmp	sendOn

clearBit:
	BitClr	ds:[di].GBI_fileStatus, GOFS_SYS_TARGETED
	mov	cl,FALSE

sendOn:
	;    Set the GOTM_SYS_TARGET bit in all the selected children.
	;

	mov	ax,MSG_GO_SET_SYS_TARGET
	call	GrObjBodySendToSelectedGrObjs
	jmp	done

GrObjBodyUpdateTargetExcl endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify body that it has gained the target excl

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		draw handles of objects on selected list. The RAW method
		is used because the objects still have their handlesDrawn
		bit set even though the handles aren't drawn. This was
		done to prevent dirtying the document when the target was
		lost

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGainedTargetExcl method GrObjBodyClass, MSG_META_GAINED_TARGET_EXCL
	.enter

	ornf	ds:[di].GBI_fileStatus, mask GOFS_TARGETED

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	call	GrObjBodyUpdateTargetExcl	; do default behavior

	;    Setting the current body will cause the floater to notify the
	;    selected and editing objects in this body that the floater
	;    is activating. This may cause the selection list to change.
	;

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GH_SET_CURRENT_BODY
	clr	di
	call	GrObjBodyMessageToHead
EC <	ERROR_Z	GROBJ_BODY_NOT_ATTACHED_TO_HEAD			>
	
	;
	;  Tell the clipboard that we want notifications
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ClipboardAddToNotificationList

	;
	;	Update all the controllers
	;

	mov	cx, mask GrObjUINotificationTypes
	mov	ax,MSG_GB_UPDATE_UI_CONTROLLERS
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GB_UPDATE_INSTRUCTION_CONTROLLERS
	call	ObjCallInstanceNoLock

	;
	;	Now the text controllers (making sure not to
	;	pass the select state bit)
	;

	sub	sp, size VisTextGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].VTGNP_notificationTypes,
			VIS_TEXT_GAINED_TARGET_NOTIFICATION_FLAGS \
					and not mask VTNF_SELECT_STATE
	mov	ss:[bp].VTGNP_sendFlags, \
				mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS
	mov	ax, MSG_GB_GENERATE_TEXT_NOTIFY
	call	ObjCallInstanceNoLock
	add	sp, size VisTextGenerateNotifyParams

	;
	;  Suck the current scale factor out of the view
	;

	push	si
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	mov	ax, MSG_GEN_VIEW_GET_SCALE_FACTOR
	mov	di, mask MF_RECORD
	call	ObjMessage			
	mov	cx, di			;cx <- event to send to view 
	pop	si
	;
	;  dx:cx <- x scale
	;  bp:ax <- y scale
	;

	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

	;
	;  Calc our various handle and nudge sizes from the scale factor
	;

	pushwwf	bpax
	pushwwf	dxcx
	mov	bp, sp
	call	GrObjBodyCalcHandleSizesFromScaleFactor
	add	sp, size PointWWFixed

	;
	;  This call used to be at the start of the routine.  I moved it
	;  to the end so that if a text object is the target it will send out
	;  its notifications after the body does
	;


	.leave
	Destroy	ax, cx, dx, bp 
	ret
GrObjBodyGainedTargetExcl		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify body that it has lost the target excl

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLostTargetExcl method dynamic GrObjBodyClass, MSG_META_LOST_TARGET_EXCL
	.enter

	push	ax

	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GH_CLEAR_CURRENT_BODY
	clr	di				;MessageFlags
	call	GrObjBodyMessageToHead

	call	GrObjBodyClearMouseGrab
	call	VisReleaseMouse

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	andnf	ds:[di].GBI_fileStatus, not mask GOFS_TARGETED

	;
	;  Tell the clipboard that we don't want notifications anymore
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ClipboardRemoveFromNotificationList

	mov	ax, MSG_GB_UPDATE_INSTRUCTION_CONTROLLERS
	call	ObjCallInstanceNoLock

	;    Pass on lost target
	;

	pop	ax				; get passed-in ax value

	call	GrObjBodyUpdateTargetExcl	; do default behavior

	Destroy	ax, cx, dx, bp 

	.leave
	ret
GrObjBodyLostTargetExcl		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the currentOptions from the defaultOptions and
		the currentModifiers. The currentModifiers mean
		that the corresponding defaultOption should be toggled
		before being copied to the currentOptions.

CALLED BY:	INTERNAL
		GrObjBodyKbdChar

PASS:		
		*ds:si - graphic body

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
	srs	11/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetOptions		proc	far
	class	GrObjBodyClass
	uses	ax,bx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject		>

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset

	mov	ax,ds:[di].GBI_currentModifiers
	andnf	ax,GOFA_TOGGLE_BITS
	mov	bx,ds:[di].GBI_defaultOptions
	andnf	bx,GOFA_TOGGLE_BITS
	xor	ax,bx

	mov	bx,ds:[di].GBI_currentModifiers
	andnf	bx,GOFA_OR_BITS
	ornf	ax,bx
	mov	bx,ds:[di].GBI_defaultOptions
	andnf	bx,GOFA_OR_BITS
	ornf	ax,bx

	;    If the currentOptions need to change the update
	;    them and force a PTR event so that objects will
	;    switch immediately to the new options
	;

	cmp	ds:[di].GBI_currentOptions,ax
	je	done
	mov	ds:[di].GBI_currentOptions,ax
	call	ImForcePtrMethod
done:
	.leave
	ret
GrObjBodySetOptions		endp

GrObjRequiredInteractiveCode	ends



GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyInstantiateGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Instantiate a grobject in a block managed by the body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
		
		cx:dx - fptr to class

RETURN:		
		cx:dx - OD of new object
	
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
	srs	4/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyInstantiateGrObj	method dynamic GrObjBodyClass, 
				MSG_GB_INSTANTIATE_GROBJ
	.enter

	mov	es,cx					;class segment
	mov	di,dx					;class offset

	;    Get block to create object in
	;

	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	call	ObjCallInstanceNoLock

	;    Instantiate that object
	;

	mov	bx,cx					;block to create in
	call	ObjInstantiate
	mov	dx,si					;new block chunk

	;    This will cause the object to be completely freed
	;    if the user undoes the creation and then starts
	;    a new undo chain.
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_GENERATE_UNDO_UNDO_CLEAR_CHAIN
	call	ObjMessage

	mov	ax, MSG_GO_ADD_POTENTIAL_SIZE_TO_BLOCK
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
GrObjBodyInstantiateGrObj		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddGrObjThenDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Add a graphic object to the graphic body. The object will be
	notified via MSG_GO_AFTER_ADDED_TO_BODY that it has been added
	to the body. If the object was added at the top of the draw list
	it will be sent a message draw, otherwise it will be invalidated.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - OD of graphic object to add
		bp - GrObjBodyAddGrObjFlags

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			Newly added object will be at end of draw list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddGrObjThenDraw	method dynamic GrObjBodyClass,
					 MSG_GB_ADD_GROBJ_THEN_DRAW
	.enter

	mov	ax,MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GB_DRAW_GROBJ
	call	ObjCallInstanceNoLock

	.leave
	ret

GrObjBodyAddGrObjThenDraw		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDrawGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw or invalidate the passed grobj as necessary

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		^lcx:dx

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
	srs	11/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDrawGrObj	method dynamic GrObjBodyClass, 
						MSG_GB_DRAW_GROBJ
	uses	cx,dx,bp
	.enter

	;    Lock the object and check the LP_IS_PARENT in its
	;    GOI_drawLink field to see if it is the top object
	;

	mov	bx,cx				;object block
	mov	di,dx				;object chunk
	call	ObjLockObjBlock
	mov	es,ax				;object segment
	GrObjDeref	di,es,di
	test	es:[di].GOI_drawLink.chunk, LP_IS_PARENT
	jz	invalidate

	;    GrObj is top object in draw list, so send it a draw message
	;

	mov	ax,MSG_GB_CREATE_GSTATE
	call	ObjCallInstanceNoLockES
	tst	bp				
	jz	unlock				;bail if no gstate
	push	dx				;object chunk
	clr	cl				;DrawFlags
	call	GrObjBodySetGrObjDrawFlagsForDraw
	segmov	ds,es				;object segment
	pop	si				;object chunk
	mov	ax,MSG_GO_DRAW
	call	ObjCallInstanceNoLockES
	mov	di,bp				;gstate
	call	GrDestroyState

unlock:
	call	MemUnlock

	.leave
	ret

invalidate:
	segmov	ds,es				;object segment
	mov	si,dx				;object chunk
	mov	ax,MSG_GO_INVALIDATE
	call	ObjCallInstanceNoLockES
	jmp	unlock
GrObjBodyDrawGrObj		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a graphic object as child of graphic body

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
	
		cx:dx -- optr of object to add
		bp - GrObjBodyAddGrObjFlags	

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		All of the children of the body are in two lists. These
		list are in reverse order of each other. The drawing order
		list is connected with the GOI_drawLink field The reverse list 
		is connected via the GOI_reverseLink list.

		This routine first adds the object to the draw
		list then adds it to the reverse list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddGrObj method dynamic GrObjBodyClass, MSG_GB_ADD_GROBJ
	.enter

	call	GrObjBodyGenerateUndoAddToBodyChain

	call	GrObjBodyAddGrObjLow

	mov	bx,cx				;child handle
	mov	si,dx				;child chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_AFTER_ADDED_TO_BODY
	call	ObjMessage

	;    Must do after object has been added to body so that
	;    the object can be used to calculate wrap areas.
	;

	call	GrObjBodySendWrapNotificationForAddAndRemove

	.leave
	ret
GrObjBodyAddGrObj		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendWrapNotificationForAddAndRemove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send GOANT_WRAP_NOTIFICATION for object if it
		has one of the wrap flag set

CALLED BY:	INTERNAL
		GrObjBodyAddGrObj
		GrObjBodyRemoveGrObj

PASS:		^lbx:si - grobject

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			no wrap flags set

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/28/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendWrapNotificationForAddAndRemove		proc	near
	uses	ax,cx,di,bp
	.enter

	mov	di,mask MF_FIXUP_DS or mask MF_CALL	
	mov	ax,MSG_GO_GET_GROBJ_ATTR_FLAGS
	call	ObjMessage

	test	cx,mask GOAF_WRAP
	jnz	sendNotification

done:
	.leave
	ret

sendNotification:
	mov	di,mask MF_FIXUP_DS
	mov	bp,GOANT_WRAP_CHANGED
	mov	ax,MSG_GO_NOTIFY_ACTION
	call	ObjMessage
	jmp	done

GrObjBodySendWrapNotificationForAddAndRemove		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddGrObjLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a graphic object as child of graphic body,
		without sending notification to object.

PASS:		
		*(ds:si) - instance data of object
	
		cx:dx -- optr of object to add
		bp - GrObjBodyAddGrObjFlags	

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		All of the children of the body are in two lists. These
		list are in reverse order of each other. The drawing order
		list is connected with the GOI_drawLink field The reverse list 
		is connected via the GOI_reverseLink list.

		This routine first adds the object to the draw
		list then adds it to the reverse list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddGrObjLow 	proc near
	class	GrObjBodyClass
	uses	ax,bp,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    If position passed is not for draw list then 
	;    convert it to draw list position
	;

	test	bp, mask GOBAGOF_DRAW_LIST_POSITION
	jnz	addToDrawLinkage
	call	GrObjBodyConvertListPosition

addToDrawLinkage:
	;    Add child to normal draw linkage
	;    The GOBAGOF_DRAW_LIST_POSITION bit is in the 
	;    same place as CCF_MARK_DIRTY, so if we don't muck
	;    with bp the involved objects will be marked dirty,
	;    which is what we want.
	;

CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	movnf	ax, <offset GOI_drawLink>
	mov	di,offset GBI_drawComp
	mov	bx, offset GrObj_offset		;grobj is master
	push	bp				;draw position
	call	ObjCompAddChild
	pop	bp				;draw position

	;    Convert draw list position to reverse position
	;

	call	GrObjBodyConvertListPosition	

	;    Add child to reverse list
	;    Since the GOBAGOF_DRAW_LIST_POSITION bit is not set
	;    we actually need to set the dirty bit here, unlike
	;    above.
	;

	ornf	bp, mask CCF_MARK_DIRTY

CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	ax, offset GOI_reverseLink
	mov	di,offset GBI_reverseComp
	mov	bx, offset GrObj_offset		;grobj is master
	call	ObjCompAddChild

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	inc	ds:[di].GBI_childCount

	.leave
	ret
GrObjBodyAddGrObjLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGenerateUndoAddToBodyChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for adding object to body

CALLED BY:	INTERNAL
		GrObjBodyAddGrObj

PASS:		*ds:si - body
		cx:dx - optr of child

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		The undo action for adding a grobject to the body
		is MSG_GO_REMOVE_FROM_BODY instead of MSG_GB_REMOVE_GROBJ
		because the object may have become selected after
		it was added and only MSG_GO_REMOVE_FROM_BODY deals
		with releasing exclusives.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGenerateUndoAddToBodyChain		proc	near
	uses	ax,cx,dx,di,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>
	
	call	GrObjGlobalStartUndoChainNoText
	jc	endChain

	sub	sp,size AddUndoActionStruct
	mov	bp,sp
	mov	ss:[bp].AUAS_data.UAS_dataType,UADT_FLAGS
	mov	({GrObjUndoAppType}ss:[bp].AUAS_data.UAS_appType).\
			GOUAT_undoMessage,MSG_GO_REMOVE_FROM_BODY
	clr	ss:[bp].AUAS_flags
	mov	ss:[bp].AUAS_output.handle,cx
	mov	ss:[bp].AUAS_output.chunk,dx
	mov	di,mask MF_FIXUP_DS
	call	GeodeGetProcessHandle
	mov	ax,MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	ObjMessage
	add	sp,size AddUndoActionStruct

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyGenerateUndoAddToBodyChain		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyConvertListPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a draw list position to a reverse list 
		position and vice versa. 

		Other list position - child count - list position

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - body
		bp - GrObjBodyAddGrObjFlags	

RETURN:		
		bp - GrObjBodyAddGrObjFlags in other list
	

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
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyConvertListPosition		proc	far
	class	GrObjBodyClass
	uses	ax,bx
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Get other list's position high bit in bx
	;

	mov	bx,bp
	not	bx
	andnf	bx,mask GOBAGOF_DRAW_LIST_POSITION

	;    Convert raw position
	;

	BitClr	bp, GOBAGOF_DRAW_LIST_POSITION
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	ax,ds:[di].GBI_childCount
	xchg	ax,bp				;ax <- position, bp <- count
	sub	bp,ax
	jns	setBit
	clr	bp

	;    Set other lists position high bit
	;

setBit:
	ornf	bp,bx

	.leave
	ret
GrObjBodyConvertListPosition		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyRemoveGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a graphic object child from graphic body

PASS:		
		*(ds:si) - instance data of object
	
		cx:dx -- optr of object to remove

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		All of the children of the body are in two lists. These
		list are in reverse order of each other. The drawing order
		list is connected with the GOI_drawLink field. The reverse 
		list is connected via the GOI_reverseLink list.

		This routine first removes the object from the draw
		list then removes it from the reverse list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRemoveGrObj method dynamic GrObjBodyClass, MSG_GB_REMOVE_GROBJ
	.enter

	call	GrObjBodyGenerateUndoRemoveFromBodyChain

	;    Notify object that it is about to be removed
	;    from body
	;

	push	si					;body chunk
	mov	bx,cx					;child block
	mov	si,dx					;child chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_BEFORE_REMOVED_FROM_BODY
	call	ObjMessage
	pop	si				;body chunk

	call	GrObjBodyRemoveGrObjLow

	;    Must do after object has been removed to body so that
	;    the object won't be used to calculate wrap areas.
	;

	movdw	bxsi,cxdx			;child od
	call	GrObjBodySendWrapNotificationForAddAndRemove

	.leave
	ret
GrObjBodyRemoveGrObj		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyRemoveGrObjLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a graphic object child from graphic body
		with out sending notification of removal to object.

PASS:		
		*(ds:si) - instance data of object
	
		cx:dx -- optr of object to remove

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		All of the children of the body are in two lists. These
		list are in reverse order of each other. The drawing order
		list is connected with the GOI_drawLink field. The reverse 
		list is connected via the GOI_reverseLink list.

		This routine first removes the object from the draw
		list then removes it from the reverse list.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		WARNING: This message handler is not dynamic, so it can
		be called as a routine. Thusly, only *ds:si can
		be counted on. And it must be careful about the
		regsiters is destroys.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRemoveGrObjLow 	proc near
	class	GrObjBodyClass
	uses	ax,bx,bp,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	dec	ds:[di].GBI_childCount

	;    Remove child from normal draw linkage
	;

CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	movnf	ax, <offset GOI_drawLink>
	mov	di,offset GBI_drawComp
	mov	bx, offset GrObj_offset		;grobj is master
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjCompRemoveChild

	;    Remove child from reverse linkage
	;

CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	mov	ax, offset GOI_reverseLink
	mov	di,offset GBI_reverseComp
	mov	bx, offset GrObj_offset		;grobj is master
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjCompRemoveChild

	.leave
	ret
GrObjBodyRemoveGrObjLow		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGenerateUndoRemoveFromBodyChain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate an undo chain for removing object from body

CALLED BY:	INTERNAL
		GrObjBodyRemoveGrObj

PASS:		*ds:si - body
		cx:dx - optr of child

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
	srs	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGenerateUndoRemoveFromBodyChain		proc	near
	uses	ax,bx,di,bp
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>
	
	call	GrObjGlobalStartUndoChainNoText
	jc	endChain

	;    Get position in reverse list of child so that it can
	;    be undeleted into the correct place
	;

	push	cx,dx					;child od
	mov	ax,MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLock
	mov	bp,dx					;rev position
	pop	cx,dx					;child od

	;    Make that undo chain
	;

	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW		;undo message
	clr	bx					;AddUndoActionFlags
	call	GrObjGlobalAddFlagsUndoAction

endChain:
	call	GrObjGlobalEndUndoChain

	.leave
	ret
GrObjBodyGenerateUndoRemoveFromBodyChain		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyVupCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create gstate with proper translations in it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		bp - gstate
	
DESTROYED:	
		stc - defined as returned		

		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVupCreateGState	method dynamic GrObjBodyClass, 
						MSG_VIS_VUP_CREATE_GSTATE
	.enter


	;    Send message on up to create gstate
	;

	mov	ax,MSG_VIS_VUP_CREATE_GSTATE
	mov	di,offset GrObjBodyClass
	call	ObjCallSuperNoLock

	;    Apply translation of GrObjBody
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	dx, ds:[di].GBI_bounds.RD_left.high
	mov	cx, ds:[di].GBI_bounds.RD_left.low
	mov	bx, ds:[di].GBI_bounds.RD_top.high
	mov	ax, ds:[di].GBI_bounds.RD_top.low
	mov	di,bp					;gstate
	call	GrApplyTranslationDWord

	stc						;by definition

	.leave
	ret
GrObjBodyVupCreateGState		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For speed purposes the grobj keeps a cached gstate.
		When something in the grobj requests a gstate we
		create a gstate and copy the cached gstates transform
		into the new one. This prevent us from having
		to vup up the vis linking several more levels.
		We don't use the cached gstate so that the caller can
		function just as if it called GrCreateState and 
		destroy the gstate when it is done.

PASS:		
		*(ds:si) - instance data of object

RETURN:		
		bp - gstate		
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			body does have a cached gstate

		WARNING: This method is not dynamic, so the passed 
		parameters are more limited and you must be careful
		what you destroy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCreateGState	method GrObjBodyClass, 
						MSG_GB_CREATE_GSTATE
	uses	ax,bx,di,si,ds
	.enter

	;    Check for no cached gstate
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	di,ds:[di].GBI_graphicsState
	tst	di
	jz	vup

	;    Get transform from cached gstate.
	;    Create new gstate to body's window and set transform in it
	;	Also copy two of the text mode bits
	;
	;    Also copy the text ColorMapMode.  Ideally VUPing for the
	;    GState would always be done, and this wouldn't be an issue.
	;    However, that isn't pratical for speed reasons.   Not
	;    VUPing means that an app (eg. GeoWrite) cannot subclass
	;    MSG_VIS_VUP_CREATE_GSTATE & initialize the GState and
	;    have it consistently used.  This results in text being
	;    drawn differently when edited than when redrawn.

	;    Another, more general alternative (which involves an API
	;    change, so I rejected it for now) to copying various
	;    attributes is to add a new routine, GrDuplicateState()
	;    which duplicates an existing GState and all its attributes.
	;					-eca 7/27/94

	mov	bx,ds:[si]
	add	bx,ds:[bx].Vis_offset
	mov	bx,ds:[bx].VCI_window
	sub	sp,size TransMatrix
	mov	si,sp
	segmov	ds,ss,ax
	call	GrGetTransform
	call	GrGetTextColorMap		;al = ColorMapMode
	push	ax
	call	GrGetTextMode			;al = text mode
	mov	di,bx				;window
	call	GrCreateState
	and	al, mask TM_DRAW_CONTROL_CHARS or mask TM_DRAW_OPTIONAL_HYPHENS
	mov	ah, mask TM_DRAW_CONTROL_CHARS or mask TM_DRAW_OPTIONAL_HYPHENS
	call	GrSetTextMode
	pop	ax				;al = ColorMapMode
	call	GrSetTextColorMap
	call	GrSetTransform
	mov	bp,di				;gstate
	add	sp,size TransMatrix

done:
	.leave
	ret

vup:
	;    For some reason we have no cached gstate so just vup for one
	;

	push	cx,dx
	mov	ax,MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	pop	cx,dx
	jmp	done

GrObjBodyCreateGState		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyRecreateCachedGStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy our cached gstate and create a new one

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing

	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRecreateCachedGStates	method dynamic GrObjBodyClass, 
						MSG_VIS_RECREATE_CACHED_GSTATES
	.enter

	mov	di,ds:[di].GBI_graphicsState
	tst	di
	jz	children

	call	GrDestroyState

	mov	ax,MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	ds:[di].GBI_graphicsState,bp

children:
	;    The object with the target may have a cached gstate
	;

	mov	ax,MSG_GO_RECREATE_CACHED_GSTATES
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjBodyRecreateCachedGStates		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyIncreasePotentialExpansion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the tree that an object in the current block
		could potentially increase to the number of bytes in cx

PASS:		
		*(ds:si) - instance data
		cx - number of bytes
		dx - block handle
RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyIncreasePotentialExpansion	method GrObjBodyClass,
				MSG_GB_INCREASE_POTENTIAL_EXPANSION
	.enter

	mov	si, ds:[di].GBI_objBlockArray
	tst	si
	jz	done
	call	ObjMarkDirty
	mov	bx, cs
	mov	di, offset GrObjBlockHandleElementUpdatePotentialSizeCB
	call	ChunkArrayEnum

done:
	.leave
	ret
GrObjBodyIncreasePotentialExpansion		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDecreasePotentialExpansion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the body that an object is being destroyed that
		increased the increase potential of block. If the
		object is in the current block then decrease potential

PASS:		
		*(ds:si) - instance data
		cx - number of bytes to decrease
		dx - handle of block to decrease in
RETURN:		
		nothing

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDecreasePotentialExpansion	method GrObjBodyClass,
				MSG_GB_DECREASE_POTENTIAL_EXPANSION
	uses	cx
	.enter

	mov	si, ds:[di].GBI_objBlockArray
	tst	si
	jz	done
	call	ObjMarkDirty
	neg	cx
	mov	bx, cs
	mov	di, offset GrObjBlockHandleElementUpdatePotentialSizeCB
	call	ChunkArrayEnum

done:
	.leave
	ret
GrObjBodyDecreasePotentialExpansion		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBlockHandleElementUpdatePotentialSizeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Updates the block's potential size if it matches the
		passed block handle

Pass:		ds:di - GrObjBlockHandleElement
		dx - block handle
		cx - amount to add to potential size

Return:		carry set if found, else carry clear

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBlockHandleElementUpdatePotentialSizeCB	proc	far
	.enter

	cmp	ds:[di].GOBHE_blockHandle, dx
	clc
	jnz	done

	add	ds:[di].GOBHE_potentialSize, cx
	stc

done:
	.leave
	ret
GrObjBlockHandleElementUpdatePotentialSizeCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetBlockForOneGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns block of handle to instantiate new tool in

CALLED BY:	INTERNAL
		GrObjBodySetToolClass

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		cx - handle of block
		GBI_curBlock = cx

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetBlockForOneGrObj	method dynamic GrObjBodyClass, 
						MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	.enter

	;    If no current block then jump to alloc a new one
	;

	mov	ax, ds:[di].GBI_objBlockArray
	tst	ax
	jz	createArray
	
	;
	;    If size of block is too big, or the potential expansion
	;    is to large the jump to alloc a new block
	;

	push	si				;save body chunk
	mov_tr	si, ax				;*ds:si <- block
	mov	bx, cs
	mov	di, offset GrObjBlockHandleElementGetUnfullBlockCB
	clr	cx				;assume no block
	call	ChunkArrayEnum
	pop	si				;*ds:si <- body
	jcxz	newBlock
done:
	.leave
	ret

createArray:
	push	si				;save body chunk
	mov	bx, size GrObjBlockHandleElement
	clr	cx				;default ChunkArrayHeader
	clr	si				;alloc a chunk
	mov	al, mask OCF_DIRTY	
	call	ChunkArrayCreate
	mov_tr	ax, si				;ax <- array chunk
	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	mov	ds:[di].GBI_objBlockArray, ax

newBlock:
	call	GrObjBodyAllocGrObjBlock
	mov_tr	cx, bx				;return block in cx
	jmp	done
GrObjBodyGetBlockForOneGrObj		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBlockHandleElementGetUnfullBlockCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Callback routine wherein each GrObjBlockHandleElement
		determines whether or not it can take another grobj.

Pass:		ds:di - GrObjBlockHandleElement
		cx - 0

Return:		if GrObjBlockHandleElement could accept another grobj:

			carry set
			cx - block handle

		else
			carry clear
			cx - 0

Destroyed:	ax,bx

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBlockHandleElementGetUnfullBlockCB	proc	far
	.enter

	cmp	ds:[di].GOBHE_potentialSize, MAX_ALLOWED_POTENTIAL_BLOCK_SIZE \
					- MAX_ALLOWED_POTENTIAL_GROBJ_SIZE
	jae	done					;jae = jnc

	;
	;	Let's check the block's size against the max allowed
	;
	mov	bx, ds:[di].GOBHE_blockHandle
	mov	ax, MGIT_SIZE
	call	MemGetInfo
	cmp	ax, MAX_DESIRED_BLOCK_SIZE + 1		
	jae	done					;jae = jnc

	;
	;	This block will do.
	;
	mov	cx, bx
	stc
done:
	.leave
	ret
GrObjBlockHandleElementGetUnfullBlockCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alloc a block in the current vm file

CALLED BY:	INTERNAL
		GrObjBodyAllocGrObjBlock

PASS:		
		ds - segment of graphic body

RETURN:		
		bx - mem handle
		ax - vm block handle

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAlloc		proc	far
	uses	cx,dx
	.enter


	;    Allocate object block
	;
	call	GeodeGetProcessHandle
	call	ProcInfo
	call	UserAllocObjBlock
	mov	cx,bx				;memory block handle

	;    Get VM file handle
	;

	call	GrObjGlobalGetVMFile		;bx <- file handle

	;    Attach memory block to vm file
	;

	clr	ax				;alloc new vm block handle
	call	VMAttach
	call	VMPreserveBlocksHandle
	mov	bx,cx				;new vm mem block handle

	.leave
	ret
GrObjBodyAlloc		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAllocGrObjBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alloc a block in the current vm file to store
		graphic objects in.

CALLED BY:	INTERNAL
		GrObjBodyGetBlockForOneGrObj

PASS:		
		*(ds:si) - graphicBody

RETURN:		
		bx - handle

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		Allocate a block in the vm file
		Instantiate a body keeper object at the begining of the block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAllocGrObjBlock		proc	near
	class	GrObjBodyClass
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	call	GrObjBodyAlloc
	call	GrObjBodyAddObjBlock

	.leave
	ret
GrObjBodyAllocGrObjBlock		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyAddObjBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Adds the passed block to the body's obj block array

Pass:		*ds:si - GrObjBody

		bx - handle to add

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddObjBlock	proc	near
	class	GrObjBodyClass
	uses	ax, bx, cx, dx, di, si, es
	.enter

	;
	;	Lock our new block
	;
	call	ObjLockObjBlock
	mov	es, ax

	;
	;	Set the OLMBH_output field = body
	;
	mov	ax, ds:[LMBH_handle]
	movdw	es:[OLMBH_output], axsi
	call	MemUnlock

	push	bx				;save new block handle

	;    Add as first element in block size list thing.
	;

	mov	si, ds:[si]
	add	si, ds:[si].GrObjBody_offset
	mov	si, ds:[si].GBI_objBlockArray
	clr	ax
	call	ChunkArrayElementToPtr
	call	ChunkArrayInsertAt

	pop	ds:[di].GOBHE_blockHandle
	clr	ds:[di].GOBHE_potentialSize

	.leave
	ret
GrObjBodyAddObjBlock	endp

if	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBlockHandleElementComparePotentialSizeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	

Pass:		ds:si - GrObjBlockHandleElement #1
		es:di - GrObjBlockHandleElement #2	

Return:		flags set for jl, je, jg for #1 <,=,> #2

Destroyed:	ax, bx, cx, dx, si, di

Comments:	Since GOBHE_potentialSize is unsigned, be careful to set
		the flags as though a signed comparison were made

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jul 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBlockHandleElementComparePotentialSizeCB	proc	far
	.enter

	mov	ax, ds:[si].GOBHE_potentialSize
	cmp	ax, es:[di].GOBHE_potentialSize
	mov	ax, 1
	ja	greaterThan
	jb	lessThan

done:
	.leave
	ret

greaterThan:
	cmp	ax, 0
	jmp	done

lessThan:
	cmp	ax, 2
	jmp	done
GrObjBlockHandleElementComparePotentialSizeCB	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetActionNotificationOutput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Specify the message and output descriptor for grobjects to 
	send notification to when an action is performed on them.
	Grobjects will use this notification in the body if they
	don't have one of their own. Many uses of the grobj will
	have no notification. This is for special uses like the
	chart library which needs to know when pieces of the chart
	have become selected, been moved, etc.

	When a grobject sends out a notification it will put
	its OD in cx:dx and bp will contain GrObjActionNotificationType.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - optr of object to notify
		bp - message to send

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetActionNotificationOutput	method dynamic GrObjBodyClass, 
					MSG_GB_SET_ACTION_NOTIFICATION_OUTPUT
	uses	ax,cx
	.enter

	BitSet	ds:[di].GBI_flags,GBF_HAS_ACTION_NOTIFICATION
	jcxz	bitClear

dirty:
	call	ObjMarkDirty

	mov	ax, ATTR_GB_ACTION_NOTIFICATION
	call	GrObjGlobalSetActionNotificationOutput

	.leave
	ret

bitClear:
	BitClr	ds:[di].GBI_flags,GBF_HAS_ACTION_NOTIFICATION
	jmp	dirty

GrObjBodySetActionNotificationOutput		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Prevent all grobjects from sending out any action notifications,
	even if a given grobject has its own output OD and message.
	If the body has no action notification od it will
	will still record the suspension and the suspension will
	be in place when the action output is set.
	Nested suspends and unsuspends are allowed.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		none
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			action notification var data exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySuspendActionNotification	method dynamic GrObjBodyClass, 
					MSG_GB_SUSPEND_ACTION_NOTIFICATION
	uses	ax
	.enter

	mov	ax,ATTR_GB_ACTION_NOTIFICATION
	call	GrObjGlobalSuspendActionNotification

	.leave
	ret

GrObjBodySuspendActionNotification		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUnsuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Counterbalance a call to MSG_GB_SUSPEND_ACTION_NOTIFICATION.
	If all suspends have been balanced the grobject will be
	free to send out action notification. However, it will not
	send action notifications that were aborted during the suspended
	period. If the body is not suspend the message will be ignored.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			action notification var data exists

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUnsuspendActionNotification	method dynamic GrObjBodyClass, 
					MSG_GB_UNSUSPEND_ACTION_NOTIFICATION
	uses	ax
	.enter

	mov	ax,ATTR_GB_ACTION_NOTIFICATION
	call	GrObjGlobalUnsuspendActionNotification

	.leave
	ret
GrObjBodyUnsuspendActionNotification		endm


GrObjAlmostRequiredCode	ends

GrObjRequiredCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyIgnoreUndoActionsAndSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

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
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyIgnoreUndoActionsAndSuspend	method dynamic GrObjBodyClass,
					MSG_GB_IGNORE_UNDO_ACTIONS_AND_SUSPEND
	uses	cx, dx, bp
	.enter

	;    Ignore actions because suspend the body starts an undo chain
	;    but we don't want selecting objects to toss out the 
	;    previous undo
	;

	call	GrObjGlobalUndoIgnoreActions

	;    Suspend the body so that all the objects that are becoming
	;    selected and unselected won't try and update the controllers
	;    independently
	;

	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyIgnoreUndoActionsAndSuspend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUnsuspendAndAcceptUndoActions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

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
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUnsuspendAndAcceptUndoActions	method dynamic GrObjBodyClass,
				MSG_GB_UNSUSPEND_AND_ACCEPT_UNDO_ACTIONS
	uses	cx, dx, bp
	.enter

	mov	ax, MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	call	GrObjGlobalUndoAcceptActions

	.leave
	ret
GrObjBodyUnsuspendAndAcceptUndoActions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Increment the suspend count. When the count is non-zero
	grobject invalidations and ui notifications will not be
	done.

	NOTE: Action notifications will be still be sent out while
	the body is suspended.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySuspend	method dynamic GrObjBodyClass, MSG_META_SUSPEND
	.enter

	;    If we are making the transition from not suspend to
	;    suspend then start an undo action
	;

	tst	ds:[di].GBI_suspendCount
	jz	startUndo

incCount:
	inc	ds:[di].GBI_suspendCount

	mov	di,ds:[di].GBI_graphicsState
	tst	di
	jz	toSelected
	call	WinSuspendUpdate

toSelected:
	mov	ax,MSG_META_SUSPEND
	call	GrObjBodySendToSelectedGrObjs
	
	;    Only send to the edit object if we are the target. This
	;    prevents deaths on quick copy. An object is getting
	;    added to a body with out the target and that object
	;    is becoming editable. Since the body doesn't have the
	;    target, the new object doesn't get GAINED_TARGET_EXCL
	;    so it doesn't match the body's suspend count. It is
	;    bad news to be passing suspends and unsuspends to
	;    objects that don't have the same suspend count as
	;    the body.
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jz	done
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit

done:
	Destroy	ax, cx, dx, bp

	.leave
	ret

startUndo:
	call	GrObjGlobalStartUndoChainNoText

	;   So that undoing operations will also be suspended.
	;

	mov	ax,MSG_META_UNSUSPEND
	clr	bx
	call	GrObjGlobalAddFlagsUndoAction
	jmp	incCount

GrObjBodySuspend		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Decrement the suspend count. If the count reaches zero then
	Remove restrictions on grobject invalidations and notifications
	sent to the UI. Initiate invalidations and notifications that
	were aborted because of the suspension.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBody

RETURN:		
		nothing
	
DESTROYED:	
		ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUnsuspend	method dynamic GrObjBodyClass, MSG_META_UNSUSPEND
	.enter

	;    Bail if we aren't suspended
	;

	mov	cx, ds:[di].GBI_suspendCount
EC<	tst	cx							>
EC<	ERROR_Z	GROBJ_BODY_UNSUSPENDED_WHEN_NOT_ALREADY_SUSPENDED	>
NEC<	jcxz	done							>
	;    Reduce windows suspend count
	;

	mov	di,ds:[di].GBI_graphicsState
	tst	di
	jz	afterUnSuspend
	call	WinUnSuspendUpdate
afterUnSuspend:
	call	GrObjBodySendToSelectedGrObjs
	
	;    Only send to the edit object if we are the target. This
	;    prevents deaths on quick copy. An object is getting
	;    added to a body with out the target and that object
	;    is becoming editable. Since the body doesn't have the
	;    target, the new object doesn't get GAINED_TARGET_EXCL
	;    so it doesn't match the body's suspend count. It is
	;    bad news to be passing suspends and unsuspends to
	;    objects that don't have the same suspend count as
	;    the body.
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	test	ds:[di].GBI_fileStatus, mask GOFS_TARGETED
	jz	decCount
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit

decCount:
	;    Reduce suspend count and bail if suspension not removed
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	dec	cx
	mov	ds:[di].GBI_suspendCount, cx
	jnz	done

	;    If making the transition from suspended to not suspended
	;    then end the undo chained start on MSG_META_SUSPEND.
	;    But throw in a suspend undo action so that undoing operations 
	;    will also be suspended.
	;

	mov	ax,MSG_META_SUSPEND
	clr	bx
	call	GrObjGlobalAddFlagsUndoAction
	call	GrObjGlobalEndUndoChain

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	xchg	ds:[di].GBI_unsuspendOps, cx
	jcxz	checkText

	mov	ax, MSG_GB_UPDATE_UI_CONTROLLERS
	call	ObjCallInstanceNoLock	
	clr	cx
	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset

	;
	;  Tell the body to update the text controllers
	;
checkText:
	xchg	ds:[di].GBI_textUnsuspendOps, cx
	jcxz	done

	sub	sp, size VisTextGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].VTGNP_notificationTypes, cx
	mov	ss:[bp].VTGNP_sendFlags, mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS
	mov	ax, MSG_GB_GENERATE_TEXT_NOTIFY
	call	ObjCallInstanceNoLock
	add	sp, size VisTextGenerateNotifyParams

done:
	Destroy	ax, cx, dx, bp

	.leave
	ret
GrObjBodyUnsuspend		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform undo

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - UndoActionStruc
RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUndo	method dynamic GrObjBodyClass, MSG_META_UNDO
	.enter

	mov	ax,({GrObjUndoAppType}ss:[bp].UAS_appType).GOUAT_undoMessage

	;    All grobj undo messages take their parameters from the
	;    UndoActionDataUnion in the same order regardless of
	;    the UndoActionDataType.
	;

CheckHack <(offset UADF_flags.low) eq 0>
CheckHack <(offset UADF_flags.high) eq 2>
CheckHack <(offset UADF_extraFlags) eq 4>
CheckHack <(offset UADVMC_vmChain.low) eq 0>
CheckHack <(offset UADVMC_vmChain.high) eq 2>
CheckHack <(offset UADVMC_file) eq 4>

	mov	cx,{word}ss:[bp].UAS_data
	mov	dx,{word}ss:[bp].UAS_data+2
	mov	bp,{word}ss:[bp].UAS_data+4
	
	call	ObjCallInstanceNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret
GrObjBodyUndo		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyUndoFreeingAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform undo freeing action

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - AddUndoActionStruc
RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyUndoFreeingAction	method dynamic GrObjBodyClass, 
					MSG_META_UNDO_FREEING_ACTION
	.enter

	mov	ax,({GrObjUndoAppType}ss:[bp].AUAS_data.\
					UAS_appType).GOUAT_freeMessage

	;    All grobj undo messages take their parameters from the
	;    UndoActionDataUnion in the same order regardless of
	;    the UndoActionDataType.
	;

CheckHack <(offset UADF_flags.low) eq 0>
CheckHack <(offset UADF_flags.high) eq 2>
CheckHack <(offset UADF_extraFlags) eq 4>
CheckHack <(offset UADVMC_vmChain.low) eq 0>
CheckHack <(offset UADVMC_vmChain.high) eq 2>
CheckHack <(offset UADVMC_file) eq 4>

	mov	cx,{word}ss:[bp].AUAS_data.UAS_data
	mov	dx,{word}ss:[bp].AUAS_data.UAS_data+2
	mov	bp,{word}ss:[bp].AUAS_data.UAS_data+4
	

	call	ObjCallInstanceNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret

GrObjBodyUndoFreeingAction		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handler for a classed event passed via 
		MSG_META_SEND_CLASSED_EVENT. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx - handle of ClassedEvent
		dx - TravelOptions

RETURN:		
		event destroyed

DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:


	This routine is ugly, ugly, ugly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/16/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendClassedEvent	method dynamic GrObjBodyClass, \
						MSG_META_SEND_CLASSED_EVENT
eventHandle	local	hptr 	push	cx
travelOption	local	word 	push	dx

	.enter

	cmp	dx, TO_TARGET
	je	target

	cmp	dx, TO_FOCUS
	je	focus

	push	bp					;stack frame
	mov	di, offset GrObjBodyClass
	CallSuper	MSG_META_SEND_CLASSED_EVENT
	pop	bp					;stack frame

done:
	.leave

	Destroy	ax,cx,dx,bp

	ret

focus:
	;    If we don't have a focusExcl then handle the message
	;    here at the body. Otherwise send to focus
	;

	tst	ds:[di].GBI_focusExcl.HG_OD.handle
	jz	toBody
	mov	cx,eventHandle
	mov	dx,travelOption
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	GrObjBodyMessageToFocus
	jmp	done
	

target:
	;    Handle any messages that can be used to set default 
	;    attributes
	;

	mov	ax,MSG_GB_SEND_CLASSED_EVENT_SET_DEFAULT_ATTRS
	call	ObjCallInstanceNoLock

	;    Get the class of the encapsulated message
	;

	mov	bx,cx					;event handle
	mov	dx,si					;guardian chunk
	call	ObjGetMessageInfo
	xchg	dx,si					;event class offset,
							;guard chunk

	;    If the class is zero the then message is a meta
	;    message that should be sent to the leaf. We
	;    are operating under the assumption that such messages
	;    cannot be sent to multiple objects with intelligible
	;    results (eg MSG_META_COPY, MSG_META_PASTE), unless
	;    they are MetaTextMessages. Our concept of leaf is either 
	;    the edit/target, if there is one, or the body.
	;

	tst	cx					;class segment
	jnz	hasClass

	;    The body wants to handle search and spell messages
	;    itself.
	;

	call	GrObjGlobalCheckForMetaSearchSpellMessages
	jc	toBody

	;    The body will handle suspend and unsuspend messages
	;    itself.  See GrObjBodySuspend for details.
	;

	call	GrObjGlobalCheckForMetaSuspendUnsuspendMessages
	jc	toBody

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_targetExcl.HG_OD.handle
	jz	checkText

	;    We have a target 
	;

	mov	cx,eventHandle
	mov	dx,travelOption
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	GrObjBodyMessageToEdit
	jmp	done

checkText:
	call	GrObjGlobalCheckForMetaTextMessages
	jnc	toBody				;jmp if not text message

	;    The suspend gives us an undo chain that encompasses
	;    the whole operation (in case more than one object is
	;    selected). It alway fixes multiple update problems
	;    with text menus which don't send out a suspend/unsuspend
	;

	push	bp				;local frame
	mov	ax,MSG_META_SUSPEND
	call	ObjCallInstanceNoLock
	pop	bp				;local frame
	call	GrObjBodySendClassedEventToEditSelection
	push	bp				;local frame
	mov	ax,MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock
	pop	bp				;local frame
	jmp	done

toBody:
	mov	cx,eventHandle
	mov	dx,travelOption
	mov	di,offset GrObjBodyClass
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	push	bp
	call	ObjCallSuperNoLock
	pop	bp
	jmp	done

hasClass:
	;    The message actually had a class in it.
	;    If the message can be handled at this level 
	;    (ie by the GrObjBody), then do so. Since the body
	;    is also responsible for relaying messages to the
	;    head and the ruler we will try that also. 
	;

	push	bp						;save locals
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLock
	pop	bp						;restore locals
	jc	toBody

	push	bp						;save locals
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToHead
	pop	bp						;restore locals
EC <	ERROR_Z	GROBJ_BODY_NOT_ATTACHED_TO_HEAD			>
	jc	toHead

	;    We want to send VisRuler, and its subclasses, messages
	;    to the VisRuler but we don't want to inadvertently 
	;    send Vis messages intended for Vis Wards to be
	;    eaten by the ruler. 
	;

	cmp	cx,segment VisClass
	jne	checkRuler
	cmp	dx, offset VisClass
	jne	checkRuler

toTarget:
	;    Our concept of target is either the edit grab or
	;    the selection list. There will never be both, so
	;    just send it to both and the right thing will happen
	;

	call	GrObjGlobalStartUndoChainNoText
	call	GrObjBodySendClassedEventToEditSelection
	call	GrObjGlobalEndUndoChain
	jmp	done


checkRuler:
	push	bp
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToRuler
	pop	bp
	jnc	toTarget

	mov	cx,eventHandle
	mov	dx,travelOption
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	GrObjBodyMessageToRuler
	jmp	done

toHead:
	mov	cx,eventHandle
	mov	dx,travelOption
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	GrObjBodyMessageToHead
EC <	ERROR_Z	GROBJ_BODY_NOT_ATTACHED_TO_HEAD			>
	jmp	done

GrObjBodySendClassedEvent	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendClassedEventToEditSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the classed event in the inherited stack frame
		to, the edit grab and the selection list

CALLED BY:	INTERNAL
		GrObjBodySendClassedEvent

PASS:		*ds:si - GrObjBody
		ss:bp - inherited stack frame

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
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendClassedEventToEditSelection		proc	near

eventHandle	local	hptr
travelOption	local	word 	

	uses	ax,bx,cx,dx,di
	.enter	inherit

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,eventHandle
	mov	dx,travelOption
	call	ObjDuplicateMessage
	mov_tr	cx,ax					;duped event handle
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit
	jz	noEdit
	mov	cx,bx					;original event
toSelected:
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	call	GrObjBodySendClassedEventToSelectedGrObjs

	.leave
	ret

noEdit:
	xchg	bx,cx				;duped event, original event
	call	ObjFreeMessage
	jmp	toSelected

GrObjBodySendClassedEventToEditSelection		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendClassedEventSetDefaultAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The body sends this message to itself when processing
		MSG_META_SEND_CLASSED_EVENT so that it can use the
		message for setting default attributes. This handler
		must not damage the original message. If it decides
		to use the message it must duplicate it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
	
		cx - event handle
		dx - travel option

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/17/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendClassedEventSetDefaultAttrs method dynamic GrObjBodyClass, 
				MSG_GB_SEND_CLASSED_EVENT_SET_DEFAULT_ATTRS
	uses	cx,bp
	.enter

	;    If nothing is selected and nothing is being edited
	;    then set the default attrs.
	;

	tst	ds:[di].GBI_targetExcl.HG_OD.handle
	jnz	editing
	call	GrObjBodyGetNumSelectedGrObjs
	tst	bp
	jnz	somethingSelected

setDefaults:
	;    READ ME NOW
	;    For this routine to work it is vital that we only
	;    come to the setDefaults label if there are no text
	;    objects selected nor being edited. In this case the
	;    styled messages need to be sent to the attribute manager
	;    so that controllers update correctly. If this is not the
	;    case the style messages must not go to the attribute 
	;    manager, because they would then be handled more than once
	;    causing no end of trouble.
	;

	push	si, es
	mov	bx, cx
	call	ObjGetMessageInfo		;ax = message, cxsi=OD
	segmov	es, cs
	cmp	cx,segment VisTextClass
	jne	normalIgnore
	cmp	si,offset VisTextClass
	jne	normalIgnore
	mov	di, offset visTextMessageIgnoreList
	mov	cx, length visTextMessageIgnoreList
	jmp	doIgnoreCheck

normalIgnore:
	mov	di, offset normalMessageIgnoreList
	mov	cx, length normalMessageIgnoreList

doIgnoreCheck:
	repne	scasw
	pop	si, es
	jz	done

	call	ObjDuplicateMessage
	mov_tr	cx, ax					;duped event handle

	mov	ax,MSG_META_SEND_CLASSED_EVENT
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToGOAM

	mov	cx,bx					;orig event handle
	call	GrObjGlobalCheckForClassedMetaTextMessages
	jc	justSetDefaultTextAttrs

done:
	.leave
	ret

editing:
	;   Because the attribute manager stores text attributes, if
	;   the object being edited is not a text object then we
	;   still need to set the default attrs if this is a text message.
	;   Otherwise the text message will not get handled and the
	;   text controllers won't get updated potentially leaving them
	;   in an inconsistent state.
	;

	push	cx,dx				;event handle, travel option
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	GrObjBodyMessageToEdit
	pop	cx,dx				;event handle, travel option
	jc	done				;jmp if its a text object

	call	GrObjGlobalCheckForClassedMetaTextMessages
	jc	setDefaults			;jmp if text message
	call	GrObjGlobalCheckForClassedMetaStylesMessages
	jc	setDefaults			;jmp if styles message
	jmp	done

somethingSelected:
	;   Because the attribute manager stores text attributes, if
	;   none of the selected objects are text objects then we
	;   still need to set the default attrs if this is a text message.
	;   Otherwise the text message will not get handled and the
	;   text controllers won't get updated potentially leaving them
	;   in an inconsistent state.
	;

	call	GrObjBodyCheckForSelectedGrObjTexts
	jc	done				;jmp if a text object selected

	call	GrObjGlobalCheckForClassedMetaTextMessages
	jc	setDefaults			;jmp if text message
	call	GrObjGlobalCheckForClassedMetaStylesMessages
	jc	setDefaults			;jmp if styles message
	jmp	done

justSetDefaultTextAttrs:
	;
	; We want to force
	; a text update, 'cause the GOAM's text object isn't the target,
	; so it won't force one itself
	;

	sub	sp, size VisTextGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].VTGNP_notificationTypes, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS and not mask VTNF_SELECT_STATE
	clr	ss:[bp].VTGNP_sendFlags

	mov	ax, MSG_GB_GENERATE_TEXT_NOTIFY
	call	ObjCallInstanceNoLock
	add	sp, size VisTextGenerateNotifyParams
	jmp	done

GrObjBodySendClassedEventSetDefaultAttrs		endm




visTextMessageIgnoreList	word	\
	MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC,
	MSG_VIS_TEXT_REPLACE_TEXT,
	MSG_META_DISPATCH_EVENT

normalMessageIgnoreList	word	\
	MSG_META_STYLED_OBJECT_DEFINE_STYLE,
	MSG_META_STYLED_OBJECT_REDEFINE_STYLE,
	MSG_META_STYLED_OBJECT_SAVE_STYLE,
	MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER,
	MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX,
	MSG_META_STYLED_OBJECT_MODIFY_STYLE,
	MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET,
	MSG_META_STYLED_OBJECT_DESCRIBE_STYLE,
	MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS,
	MSG_META_STYLED_OBJECT_DELETE_STYLE,
	MSG_VIS_TEXT_REPLACE_WITH_GRAPHIC,
	MSG_VIS_TEXT_REPLACE_TEXT,
	MSG_META_DISPATCH_EVENT



GrObjRequiredCode	ends

GrObjExtInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyAddDuplicateFloater
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a duplicate of the passed object to the visual tree

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass
	
		cx:dx - object
RETURN:		
		cx:dx - new object OD

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyAddDuplicateFloater	method dynamic GrObjBodyClass, \
					MSG_GB_ADD_DUPLICATE_FLOATER
	uses	ax,bp
	.enter

	;    Copy object
	;

	push	si					;body lmem
	mov	ax,MSG_GO_DUPLICATE_FLOATER
	mov	bx,cx					;object handle
	mov	cx,ds:[LMBH_handle]			;body handle
	xchg	si,dx				;object chunk, body chunk
	mov	di,mask MF_FIXUP_DS or mask MF_CALL	
	call	ObjMessage
	pop	si					;body lmem

	;    Add new object to body
	;

	push	cx,dx					;new object OD
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLock
	pop	cx,dx					;new object OD

	.leave
	ret
GrObjBodyAddDuplicateFloater		endm

GrObjExtInteractiveCode	ends

GrObjExtNonInteractiveCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyChangeGrObjDepth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change grobjs position in the draw and reverse lists.
		Note you can knock the selection array out of
		draw order when using this message. You may
		want to use MSG_GB_REORDER_SELECTION_ARRAY afterwards.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - od of grobj to change depth of
		bp - GrObjBodyAddGrObjFlags

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
	srs	5/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyChangeGrObjDepth	method dynamic GrObjBodyClass, 
						MSG_GB_CHANGE_GROBJ_DEPTH
	uses	bp
	.enter

	;    Oh boy. We need to compare the source and dest positions
	;    so that we reject null moves. However, the passed 
	;    position may well be GOBAGOR_LAST, which doesn't compare 
	;    well with the actual positions. So we take the lesser
	;    of the passed position and the position in the other list.
	;    This lesser value cannot, of course, be GOBAGOR_LAST.
	;

	mov	bx,bp					;passed position
	mov	ax,bp					;passed position
	call	GrObjBodyConvertListPosition
	mov	di,bp					;other position
	BitClr	ax, GOBAGOF_DRAW_LIST_POSITION	;raw passed
	BitClr	bp, GOBAGOF_DRAW_LIST_POSITION		;raw other
	cmp	ax,bp					;raw passed to raw other
	jb	10$
	mov	bx,di					;other is smaller
10$:
	mov	bp,bx					

	;    To simplify our lives we are going to do all our work
	;    with reverse list positions. (The reverse position doesn't
	;    have the high bit set, so math works better).
	;    Convert our dest position to the reverse list if necessary.
	;

	test	bp,mask GOBAGOF_DRAW_LIST_POSITION
	jz	20$
	call	GrObjBodyConvertListPosition
20$:

	;    Get the current reverse position of the object
	;

	push	cx,dx					;child od
	mov	ax, MSG_GB_FIND_GROBJ
	call	ObjCallInstanceNoLock
EC <	ERROR_NC GROBJ_BODY_CHANGE_GROBJ_DEPTH_BAD_OD		>
	mov_tr	ax,dx					;reverse position
	pop	cx,dx					;child od

	;    If the current and dest positions are the same then
	;    do nothing.
	;    If the child's position is less than the position the
	;    child is being moved to then we need to decrement the
	;    destination position to account for the child
	;    having been removed.	
	;

	cmp	ax,bp					;current vs dest
	je	done
	ja	changeDepth
	dec	bp

changeDepth:

	push	cx,dx					;object od
	mov	cx,handle depthString	
	mov	dx,offset depthString
	call	GrObjGlobalStartUndoChain
	pop	cx,dx					;object od

	;    Change the child's depth
	;

	mov	ax,MSG_GB_REMOVE_GROBJ
	call	ObjCallInstanceNoLock
	mov	ax,MSG_GB_ADD_GROBJ
	call	ObjCallInstanceNoLock
	mov	bx,cx					;child handle
	mov	si,dx					;child chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INVALIDATE
	call	ObjMessage

	call	GrObjGlobalEndUndoChain

done:
	.leave
	ret

GrObjBodyChangeGrObjDepth		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyFindGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the position in the draw list and the reverse list
		of the passed child

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - OD of child

RETURN:		
		stc - if found
			cx - position in draw list
			dx - position in reverse list
		clc - if not found	
			cx,dx - destroyed
			
DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyFindGrObj	method dynamic GrObjBodyClass, \
						MSG_GB_FIND_GROBJ
	uses	ax,bp
	.enter

	;    Find child in normal draw linkage
	;

;	mov	di,ds:[si]			;treat composite offset as if
;	mov	di,ds:[di].GrObjBody_offset	;it is from meta data
;	add	di,offset GBI_drawComp
CheckHack <(offset GrObj_offset) eq (offset Vis_offset)>
	movnf	ax, <offset GOI_drawLink>
	mov	di,offset GBI_drawComp
	mov	bx, offset GrObj_offset		;grobj is master
	call	ObjCompFindChild
	cmc
	jnc	done

	;    Convert draw list position to reverse list position.
	;    (reverse position = Num children-draw position-1)
	;

	mov	cx,bp				;position in draw list
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	dx,ds:[di].GBI_childCount
	sub	dx,cx
	dec	dx

	stc					;found
done:
	.leave
	ret
GrObjBodyFindGrObj		endm

GrObjExtNonInteractiveCode	ends
