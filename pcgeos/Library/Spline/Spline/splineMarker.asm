COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineMarker.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

DESCRIPTION:
	

	$Id: splineMarker.asm,v 1.1 97/04/07 11:09:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineUtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetMarkerFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the marker flags (don't you love descriptions like
		this?) 

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetMarkerFlags	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_MARKER_FLAGS
	.enter
	ornf	ds:[di].VSI_markerFlags, cl
	not	ch
	andnf	ds:[di].VSI_markerFlags, ch
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	.leave
	ret
SplineSetMarkerFlags	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawMarkers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw them markers

CALLED BY:

PASS:		es:[bp] - Vis Spline instance
		*ds:si - points 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawMarkers	proc near
	uses	ax,bx,cx,dx,di
	class	VisSplineClass 
	.enter

	mov	di, es:[bp].VSI_gstate
	clr	ax, dx
	call	GrSetLineWidth

	; Draw markers in inactive mode only.

	GetEtypeFromRecord	al, SS_MODE, es:[bp].VSI_state
	cmp	al, SM_INACTIVE
	jne	done

	; Set draw mask to SDM_100, so that the line part always
	; draws.

	mov	al, SDM_100
	call	GrSetLineMask


	movHL	ax, <mask SDF_MARKER or \
			mask SDF_USE_UNDO_INSTEAD_OF_TEMP>, <SOT_DRAW>
	mov	bx, mask SWPF_ANCHOR_POINT
	call	DrawMarkerRange

done:
	.leave
	ret
SplineDrawMarkers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMarkerRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a draw on the markers -- don't draw first/last
		if bit is set

CALLED BY:

PASS:		ah - SplineDrawFlags
		al - SplineOperateType
		bx - SplineWhichPointFlags

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMarkerRange	proc near
	class	VisSplineClass

	.enter
	push	ax
	call	SplineGotoFirstAnchor
	mov_tr	cx, ax

	call	SplineGotoLastAnchor	; ax - last anchor

	SplineDerefScratchChunk di
	mov	ds:[di].SD_firstPoint, cx
	mov	ds:[di].SD_lastPoint, ax

	test	es:[bp].VSI_markerFlags, mask SMKF_DONT_DRAW_ENDPOINTS
	jz	doIt

	inc	ds:[di].SD_firstPoint
	dec	ds:[di].SD_lastPoint

doIt:
	pop	ax
	
	call	SplineOperateOnRange

	.leave
	ret
DrawMarkerRange	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInvertHollowHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Invert hollow handles around every point of the spline

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup
		bp	- gstate handle

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
	only used by chart library

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineInvertHollowHandles	method	dynamic	VisSplineClass, 
					MSG_SPLINE_INVERT_HOLLOW_HANDLES
	uses	cx,dx,bp
	.enter

	call	SplineSetupPassedGState

	cmp	es:[bp].VSI_markerShape, MS_NONE
	je	gotHandleSize

	push	{word} es:[bp].VSI_handleSize
	mov	{word} es:[bp].VSI_handleSize, LARGE_HANDLE_SIZE

gotHandleSize:

	call	setNotDrawn

	; Now draw them all

	call	SplineSetInvertModeFar

	mov	ax, SOT_DRAW or (mask SDF_HOLLOW_HANDLES shl 8)
	call	DrawMarkerRange
	
	;
	; make sure the spline thinks they're not drawn
	;

	call	setNotDrawn

	cmp	es:[bp].VSI_markerShape, MS_NONE
	je	done

	pop	{word} es:[bp].VSI_handleSize
done:
	call	SplineRestorePassedGState
	call	SplineEndmCommon

	.leave
	ret


setNotDrawn:
	; nuke all the "hollow handles drawn" flags

	mov	al, SOT_MODIFY_INFO_FLAGS
	mov	cx, mask APIF_HOLLOW_HANDLE
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints
	retn

SplineInvertHollowHandles	endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetMarkerShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the marker shape

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		cl 	= MarkerShape

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetMarkerShape	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_MARKER_SHAPE
	uses	ax,cx,dx,bp
	.enter
	mov	ds:[di].VSI_markerShape, cl
	call	SplineMethodCommon
	mov	cx, mask SGNF_MARKER_SHAPE
	call	SplineUpdateUI
	call	SplineInvalidate
	call	SplineEndmCommon
	.leave
	ret
SplineSetMarkerShape	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetMarkerShape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the marker shape

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		cl - MarkerShape

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetMarkerShape	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_MARKER_SHAPE
	mov	al, ds:[di].VSI_markerShape
	ret
SplineGetMarkerShape	endm


SplineUtilCode	ends

