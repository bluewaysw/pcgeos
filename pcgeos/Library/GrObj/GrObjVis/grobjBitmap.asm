COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj	
FILE:		grobjBitmap.asm

AUTHOR:		Steve Scholl, Dec  7, 1991

ROUTINES:
	Name		
	----		

METHODS:
	Name		
	----		
GrObjBitmapBuild
GrObjBitmapVisVupCreateGState
GrObjBitmapApplyGStateStuff		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	12/ 7/91		Initial revision


DESCRIPTION:
	
		

	$Id: grobjBitmap.asm,v 1.1 97/04/04 18:08:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GrObjBitmapClass		;Define the class record

GrObjClassStructures	ends

GrObjBitmapGuardianCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The variant parent of the GrObjBitmapClass is VisBitmapClass

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBitmapClass

RETURN:		
		cx:dx - fptr to VisBitmapClass
	

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapBuild	method dynamic GrObjBitmapClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	mov	cx,segment VisBitmapClass
	mov	dx, offset VisBitmapClass

	.leave
	ret
GrObjBitmapBuild		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBitmapClass

RETURN:		
		nothing
	
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
	srs	5/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapMetaInitialize	method dynamic GrObjBitmapClass, MSG_META_INITIALIZE
	.enter

	mov	di, offset GrObjBitmapClass
	CallSuper	MSG_META_INITIALIZE

	;    Initialize some bitmap instance data.
	;

	mov	bx, Vis_offset
	call	ObjInitializePart
	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset

if 1
	ornf	ds:[di].VBI_undoFlags, mask VBUF_UNDOABLE or \
					mask VBUF_USES_BACKUP_BITMAP or \
					mask VBUF_TRANSPARENT
else
	ornf	ds:[di].VBI_undoFlags, mask VBUF_UNDOABLE or \
					mask VBUF_USES_BACKUP_BITMAP

	and	ds:[di].VBI_undoFlags, not mask	VBUF_TRANSPARENT

endif

	.leave
	ret
GrObjBitmapMetaInitialize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapVisVupCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have superclass create gstate then have bitmap
		clip the gstate appropriately

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

RETURN:		
		bp - gstate
		stc - defined as returned		
	
DESTROYED:	

		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapVisVupCreateGState	method dynamic GrObjBitmapClass, \
						MSG_VIS_VUP_CREATE_GSTATE
	.enter

	mov	di,offset GrObjBitmapClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_VIS_BITMAP_CLIP_GSTATE_TO_VIS_BOUNDS
	call	ObjCallInstanceNoLock

	stc

	.leave
	ret
GrObjBitmapVisVupCreateGState		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBitmapSetVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBitmap method for MSG_VIS_BITMAP_SET_VIS_BOUNDS

Called by:	

Pass:		*ds:si = GrObjBitmap object
		ds:di = GrObjBitmap instance
		ss:[bp] - A Rectangle structure containing (desired)
				new Vis Bounds
		dx - size (in bytes) of the Rectangle struct

Return:		nothing

Destroyed:	
		ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapSetVisBounds	method	GrObjBitmapClass, MSG_VIS_BITMAP_SET_VIS_BOUNDS
	uses	dx
	.enter

	;    Let the bitmap guardian know we want to change our bounds
	;

	mov	dx,size Rectangle
	mov	ax, MSG_GOVG_NOTIFY_VIS_WARD_CHANGE_BOUNDS
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>
	.leave
	ret
GrObjBitmapSetVisBounds	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapApplyGStateStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the guardian apply its attributes to the gstate

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBitmapClass

		bp - gstate
RETURN:		
		bp - gstate with attributes applied
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapApplyGStateStuff	method dynamic GrObjBitmapClass, \
					MSG_VIS_BITMAP_APPLY_GSTATE_STUFF
	uses	ax
	.enter

	mov	ax,MSG_GO_APPLY_ATTRIBUTES_TO_GSTATE
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

	.leave
	ret
GrObjBitmapApplyGStateStuff		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles MSG_META_PTR events.  Basically sets the UIFA_IN
		bit correctly and passes off to Vis Part.

CALLED BY:	MSG_META_PTR
PASS:		*ds:si	= GrObjBitmapClass object
		ds:di	= GrObjBitmapClass instance data
		ds:bx	= GrObjBitmapClass object (same as *ds:si)
		es 	= segment of GrObjBitmapClass
		ax	= message #
		cx, dx	= mouse coordinates
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ax = MRF_PROCESSED (MouseReturnFlags)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapPtr	method dynamic GrObjBitmapClass, MSG_META_PTR
	.enter
	
	andnf	bp, not (mask UIFA_IN shl 8)
	call	VisTestPointInBounds
	jnc	callVisPart
	ornf	bp, (mask UIFA_IN shl 8)

callVisPart:
	mov	di,offset GrObjBitmapClass
	call	ObjCallSuperNoLock
	
	.leave
	ret
GrObjBitmapPtr	endm

GrObjBitmapGuardianCode	ends

GrObjTransferCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapGetGrObjVisClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjBitmap method for MSG_GV_GET_GROBJ_VIS_CLASS

Called by:	MSG_GV_GET_GROBJ_VIS_CLASS
Pass:		nothing

Return:		cx:dx - pointer to GrObjBitmapClass

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapGetGrObjVisClass	method dynamic	GrObjBitmapClass,
				MSG_GV_GET_GROBJ_VIS_CLASS
	.enter

	mov	cx, segment GrObjBitmapClass
	mov	dx, offset GrObjBitmapClass

	.leave
	ret
GrObjBitmapGetGrObjVisClass	endm

GrObjTransferCode	ends

GrObjDrawCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBitmapVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force bitmap to always draw with 100% area mask. This prevents
		the bitmap from drawing with whatever the last mask
		you were editing it with.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBitmapClass

		bp - gstate
		cl - DrawFlags

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
	srs	1/ 8/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBitmapVisDraw	method dynamic GrObjBitmapClass, MSG_VIS_DRAW
	.enter

	mov	di,bp
	mov	al,SDM_100
	call	GrSetAreaMask

	mov	ax,MSG_VIS_DRAW
	mov	di,offset GrObjBitmapClass
	call	ObjCallSuperNoLock

	.leave
	ret
GrObjBitmapVisDraw		endm


GrObjDrawCode	ends
