COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS - Spline edit object
MODULE:		
FILE:		splineDraw.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

ROUTINES:
	Name			Description
	----			-----------

DESCRIPTION:	Graphics output routines for the spline object

	$Id: splineDraw.asm,v 1.1 97/04/07 11:09:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineUtilCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawLineOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the line-only part of the spline

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDrawLineOnly	method	dynamic	VisSplineClass, 
					MSG_SPLINE_DRAW_LINE_ONLY
	uses	ax,cx,dx,bp
	.enter

	call	SplineSetupPassedGState

	; HACK!  Make sure the VA_DRAWABLE bit is set, so that our
	; low-level routine doesn't abort.  This is so that the grobj
	; doesn't get confused when ungrouping groups containing
	; splines.  

	push	{word} es:[bp].VI_attrs
	ornf	es:[bp].VI_attrs, mask VA_DRAWABLE
	call	SplineDrawLineCommon
	pop	{word} es:[bp].VI_attrs

	call	SplineDrawMarkers

	call	SplineRestorePassedGState
	call	SplineEndmCommon 

	.leave
	ret
SplineDrawLineOnly	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawLineCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the LINE part of the spline only

CALLED BY:	SplineDrawLineOnly, SplineDrawToPath

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawLineCommon	proc near
	class	VisSplineClass 
	uses	di
	.enter

	
	; draw all (undo) curves.  Set the DRAW_CONTINUOUS
	; flag in the scratch data

	SplineDerefScratchChunk di
	ornf	ds:[di].SD_flags, mask SDF_DRAW_CONTINUOUS
	mov	ds:[di].SD_lastDrawPoint.P_x, MAX_COORD
	mov	ds:[di].SD_lastDrawPoint.P_y, MAX_COORD

	;
	; If we're in SM_BEGINNER_SPLINE_CREATE mode, then don't draw
	; last curve
	;

	GetEtypeFromRecord	cl, SS_MODE, es:[bp].VSI_state
	cmp	cl, SM_BEGINNER_SPLINE_CREATE
	mov	bx, mask SWPF_ANCHOR_POINT
	jne	operateOnAll
	
	;
	; If the last anchor has no prev anchor, then done
	;

	call	SplineGotoLastAnchor
	jc	afterOperate
	call	SplineGotoPrevAnchorFar
	jc	afterOperate

	SplineDerefScratchChunk di
	mov	ds:[di].SD_firstPoint, 0
	mov	ds:[di].SD_lastPoint, ax

	movHL	ax, <mask SDF_CURVE  \
			or mask SDF_USE_UNDO_INSTEAD_OF_TEMP>, <SOT_DRAW> 
	call	SplineOperateOnRange
	jmp	afterOperate


operateOnAll:
	movHL	ax, <mask SDF_CURVE  \
			or mask SDF_USE_UNDO_INSTEAD_OF_TEMP>, <SOT_DRAW> 
	call	SplineOperateOnAllPoints
afterOperate:

	SplineDerefScratchChunk	di
	andnf	ds:[di].SD_flags, not mask SDF_DRAW_CONTINUOUS

	.leave
	ret
SplineDrawLineCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawAreaOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDrawAreaOnly	method	dynamic	VisSplineClass, 
					MSG_SPLINE_DRAW_AREA_ONLY
	uses	ax,cx,dx,bp
	.enter
	call	SplineSetupPassedGState
	call	SplineDrawAreaCommon
	call	SplineRestorePassedGState
	call	SplineEndmCommon 

	.leave
	ret
SplineDrawAreaOnly	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawAreaCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line to a path, and then fill that path

CALLED BY:	SplineDrawAreaOnly, SplineDrawBaseObjectLow

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawAreaCommon	proc near
	class	VisSplineClass 
	.enter

	call	SplineDrawToPath

	test	es:[bp].VSI_state, mask SS_FILLED
	jz	done

	mov	cl, RFR_ODD_EVEN
	call	GrFillPath

done:
	.leave
	ret
SplineDrawAreaCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawBaseObjectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the basic object.  

CALLED BY:	GLOBAL within spline

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	DOES NOT draw markers -- this is because Steve uses
	MSG_SPLINE_DRAW_USING_PASSED_GSTATE_ATTRIBUTES to draw the
	"background" for the spline in the grobj.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawBaseObjectLow	proc near

	class	VisSplineClass 

	.enter

EC <	call	ECSplineInstanceAndPoints		>  

	call	ChunkArrayGetCount	; are there any points?
	jcxz	done			; NO, then done

	call	SplineDrawAreaCommon

	; draw the path

	call	GrDrawPath

done:
	.leave
	ret
SplineDrawBaseObjectLow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawToPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the entire spline to a path, setting the
		CONTINUOUS flag, etc

CALLED BY:	SplineDrawBaseObjectLow, 
		SplineSetMinimalVisBounds
		SplineHitDetectLow

PASS:		es:bp - VisSpline
		*ds:si - points

RETURN:		di - spline's internal gstate

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDrawToPath	proc near
	uses	ax, bx
	class	VisSplineClass

EC <	call	ECSplineInstanceAndPoints		> 

	.enter

	; Begin the PATH
	
	mov	di, es:[bp].VSI_gstate
	mov	cx, PCT_REPLACE
	call	GrBeginPath

	call	SplineDrawLineCommon

	; end the PATH

	call	GrEndPath

	.leave
	ret
SplineDrawToPath	endp

SplineDrawToPathFar	proc	far
	call	SplineDrawToPath
	ret
SplineDrawToPathFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawInvertModeStuffAsDrawn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw invert-mode stuff as one would expect to after an
		exposed event.  This means drawing points in
		accordance with their DRAWN bits, etc.
		

CALLED BY:	SplineDrawEverythingElse

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Draw points in accordance with their DRAWN bits
	draw the selection and Vis bounds rectangles, if any
	draw sprite from last anchor to mouse, if any.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawInvertModeStuffAsDrawn	proc near
	class	VisSplineClass 
	uses	ax,bx,cx,dx,di,si,bp
	.enter

EC <	call	ECSplineInstanceAndPoints		>  

	; draw vis boundary
	call	SplineDrawVisBoundaryLow

	; Draw points in accordance with their "drawn" bits

	call	SplineSetInvertModeFar
	mov	al, SOT_DRAW_AS_DRAWN
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints

	; If the spline is following the mouse around, draw the "sprite"

	call	SplineDrawFromLastAnchorToMouse

	;
	; If there's currently a rectangle being dragged around, draw it!
	;
	GetActionType	bl
	cmp	bl, AT_MOVE_RECTANGLE
	jne	done

	SplineDerefScratchChunk si
	movP	cxdx, ds:[si].SD_mouse
	call	SplineDrawDragRect
done:


	.leave
	ret
SplineDrawInvertModeStuffAsDrawn	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawBaseObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw the permanent aspects of the spline object.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDrawBaseObject	method	dynamic VisSplineClass, 
			MSG_SPLINE_DRAW_BASE_OBJECT				
	uses	ax, cx, dx, bp
	.enter

	call	SplineSetupPassedGState ; (calls SplineMethodCommon)

	call	SplineSetNormalAttributes

	call	SplineDrawBaseObjectLow


	call	SplineRestorePassedGState

	call	SplineEndmCommon 
	.leave
	ret
SplineDrawBaseObject	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawUsingPassedGStateAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		*ds:si - spline
		ds:si - spline instance data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 7/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawUsingPassedGStateAttributes	method dynamic VisSplineClass,
			MSG_SPLINE_DRAW_USING_PASSED_GSTATE_ATTRIBUTES

	uses	ax,cx,dx,bp
	.enter

	call	SplineSetupPassedGState ; (calls SplineMethodCommon)
	call	SplineDrawBaseObjectLow
	call	SplineRestorePassedGState
	call	SplineEndmCommon 

	.leave
	ret
SplineDrawUsingPassedGStateAttributes	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawEverythingElse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw handles, etc.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		bp 	= gstate handle 

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDrawEverythingElse	method	dynamic	VisSplineClass, 
					MSG_SPLINE_DRAW_EVERYTHING_ELSE
	uses	ax,bp
	.enter
	call	SplineSetupPassedGState
	call	SplineDrawInvertModeStuffAsDrawn
	call	SplineRestorePassedGState
	call	SplineEndmCommon 
	.leave
	ret
SplineDrawEverythingElse	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate my vis bounds

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	WILL NOT DRAW If "CheckCanDraw" says not to. 
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInvalidate	proc	far
	uses	ax, cx, dx
	.enter
	call	SplineCheckCanDrawFar
	jc	done
	mov	ax, MSG_VIS_INVALIDATE
	call	SplineSendMyselfAMessage
done:
	.leave
	ret
SplineInvalidate	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawEverythingProtectHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the entire spline, making sure the handles and
		other invert mode stuff gets drawn properly

CALLED BY:	Set Line/Area attribute methods

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	WILL NOT DRAW If "CheckCanDraw" says not to.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/16/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawEverythingProtectHandles	proc far
	.enter
	call	SplineCheckCanDrawFar 
	jc	done
	call	SplineDrawInvertModeStuffAsDrawn	; should erase!

	mov	ax, MSG_SPLINE_DRAW_BASE_OBJECT
	call	SplineSendMyselfAMessage

	call	SplineDrawInvertModeStuffAsDrawn	; should erase!
done:
	.leave
	ret
SplineDrawEverythingProtectHandles	endp






SplineUtilCode	ends

SplinePtrCode segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawFromLastAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a curve (line) from the last anchor to (CX,DX)

CALLED BY:	SplinePtrMouseUp, SplineDrawFromLastAnchorToMouse

PASS:		es:bp - VisSplineInstance data 
		cx, dx, - coordinates to draw TO

RETURN:		

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 4/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawFromLastAnchor	proc	near
	uses	ax,bx,cx,dx,di,si
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndPoints		>  

	; If anchor has no next control, then just draw a line segment	
	call	SplineGotoLastAnchor
	jc	done			; anything's possible

	push	ax
	call	SplineGotoNextControl
	pop	ax
	jc	lineSeg


	; otherwise draw a full curve (sticking CX, DX into the CurveStruct
	; structure in the scratch data.
	
	SplineDerefScratchChunk di
	add	di, offset SD_bezierPoints

	push	cx
	clr	cl
	call	SplineGetBezierPoints
	pop	cx

	movP	ds:[di].CS_P3, cxdx
	movP	ds:[di].CS_P2, cxdx
	mov	si, di
	mov	cx, 4
	mov	al, 1
	mov	di, es:[bp].VSI_gstate
	call	GrDrawSpline

done:
	.leave
	ret

lineSeg:
	; get anchor's coords
	LoadPointAsInt	ax, bx, ds:[di].SPS_point
	 
	mov	di, es:[bp].VSI_gstate
	call	GrDrawLine
	jmp	done
SplineDrawFromLastAnchor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawFromLastAnchorToMouse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an invert-mode curve from the last anchor point
		to the current mouse position (stored in the scratch
		chunk), but only if that's our current action type

CALLED BY:	SplineDrawInvertModeStuffAsDrawn,
		SplineSSCreateModeCommon, SplineDeleteAnchors,
		SplineUndoDeleteAnchors

PASS:		es:bp - VisSplineInstance

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	
		WILL NOT DRAW If "CheckCanDraw" says not to. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawFromLastAnchorToMouse	proc	far
	uses	cx, dx
	class	VisSplineClass 
	.enter

	call	SplineCheckCanDraw
	jc	done

	GetActionType	cl
	cmp	cl, AT_CREATE_MODE_MOUSE_UP
	jne	done

	call	SplineSetInvertMode
	SplineDerefScratchChunk	di
	mov	cx, ds:[di].SD_mouse.P_x
	mov	dx, ds:[di].SD_mouse.P_y
	call	SplineDrawFromLastAnchor
done:
	.leave
	ret
SplineDrawFromLastAnchorToMouse	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCheckCanDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if I can draw anything

CALLED BY:	SplineOperateSetup

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		carry set if unable to draw

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Perhaps I should be using the MSG_VIS_GET_ATTRS message ... ?

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCheckCanDraw	proc near
	class	VisSplineClass 
	.enter

	CheckHack	<VisSpline_offset eq Vis_offset>

	; TEST clears the carry

	test	es:[bp].VI_attrs, mask VA_DRAWABLE or mask VA_REALIZED
	jz	no
done:
	.leave
	ret
no:
	stc
	jmp	done
SplineCheckCanDraw	endp

SplineCheckCanDrawFar	proc	far
	call	SplineCheckCanDraw
	ret
SplineCheckCanDrawFar	endp

SplinePtrCode	ends

SplineSelectCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEraseSelectedPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase any data pertaining to selected points

CALLED BY:	

PASS:		*ds:si - points array 
		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEraseSelectedPoints	proc	far
	uses	ax,bx
	.enter
	call	SplineCheckCanDrawFar
	jc	done

	call	SplineSetInvertModeFar
	movHL	ax, <SDT_NORMAL_SELECTED_STUFF>, <SOT_ERASE>
	mov	bx, SWP_ALL
	call	SplineOperateOnSelectedPointsFar
done:
	.leave
	ret
SplineEraseSelectedPoints	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawSelectedPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the normal selected information, drawing somewhat
		differently based on the mode we're in.

CALLED BY:	SplineModifySelection

PASS:		es:bp - VisSplineInstance data
		ds - data segment of spline's lmem block 

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	
	WILL NOT DRAW If "CheckCanDraw" says not to. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/14/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawSelectedPoints	proc 	far
 	uses	ax,bx,di

	class	VisSplineClass

	.enter

EC <	call	ECSplineInstanceAndLMemBlock	>

	call	SplineCheckCanDrawFar 
	jc	done

	; If inactive mode -- do nothing
 	
	GetMode	al
	cmp	al, SM_INACTIVE
	je	done

	; If we don't have the target, then don't draw either

	test	es:[bp].VSI_editState, mask SES_TARGET
	jz	done

	; setup the gstate
	call	SplineSetInvertModeFar

	; If action type is AT_SELECT_SEGMENT, then only draw the NEXT and
	; NEXTFAR controls for each selected anchor.

	GetActionType	bh
	cmp	bh, AT_SELECT_SEGMENT
	mov	bx, mask SWPF_NEXT_CONTROL or mask SWPF_NEXT_FAR_CONTROL
	je	drawIt

	; In create mode, just draw a hollow handle for the anchor
	cmp	al, SM_ADVANCED_CREATE
	jbe	createModes

	; Set BX to SWP_ALL in advanced modes, SWPF_ANCHOR_POINT in beginner:

	mov	bx, SWP_ALL
	cmp	al, SM_ADVANCED_EDIT
	je	drawIt
	cmp	al, SM_ADVANCED_CREATE
	je	drawIt

	mov	bx, mask SWPF_ANCHOR_POINT
drawIt:
	movHL	ax, <SDT_NORMAL_SELECTED_STUFF>, <SOT_DRAW>
operate:
	call	SplineOperateOnSelectedPointsFar
done:
	.leave
	ret
createModes:
	mov	bx, mask SWPF_ANCHOR_POINT
	movHL	ax, <mask SDF_HOLLOW_HANDLES>, <SOT_DRAW>
	jmp	operate
SplineDrawSelectedPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawInvertModeStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw hollow handles for every anchor, then draw normal
		selected stuff.

CALLED BY:	SplineSetLineColor, among others.

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		
RETURN:		Nothing	

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawInvertModeStuff	proc	far
	uses	ax,bx
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndPoints		>
	
	; If inactive, do nothing

	 
	GetMode	al
	cmp	al, SM_INACTIVE
	je	done

	call	SplineSetInvertModeFar
	movHL	ax, <mask SDF_HOLLOW_HANDLES>, <SOT_DRAW>
	mov	bx, mask SWPF_ANCHOR_POINT
	call	SplineOperateOnAllPoints
	call	SplineDrawSelectedPoints
done:
	.leave
	ret
SplineDrawInvertModeStuff	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineEraseInvertModeStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase hollow handles, filled handles, control lines

CALLED BY:	GLOBAL

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEraseInvertModeStuff	proc	far
	uses	ax, bx

EC <	call	ECSplineInstanceAndPoints		>  
	.enter
	call	SplineSetInvertModeFar
	movHL	ax, <mask SDF_HOLLOW_HANDLES or \
			mask SDF_FILLED_HANDLES or \
			mask SDF_CONTROL_LINES>, <SOT_ERASE>
	mov	bx, SWP_ANCHOR_AND_CONTROLS
	call	SplineOperateOnAllPoints
	.leave
	ret
SplineEraseInvertModeStuff	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetNormalAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set "normal-mode" line attributes

CALLED BY:	SplineDrawBaseObject...

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of attributes chunk

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Use MSG_SPLINE_GET_LINE_ATTR rather than accessing the data
	structure directly.  This allows joe subclass to do the right
	thing. 

	WILL NOT SET ATTRIBUTES If "CheckCanDraw" says not to. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Assume spline already has a gstate

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSetNormalAttributes	proc	far
	uses	ax,bx,cx,dx,di
	class	VisSplineClass 

	.enter

	call	SplineCheckCanDrawFar
	jc	done

	mov	bx, es:[bp].VSI_gstate
	mov	ax, MSG_SPLINE_APPLY_ATTRIBUTES_TO_GSTATE
	call	SplineSendMyselfAMessage

done:
	.leave
	ret
SplineSetNormalAttributes	endp

SplineSelectCode ends


SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single curve.  

CALLED BY:	internal to SplineDraw:  SplineDrawPointCommon,
		SplineDrawIMCurve, SplineEraseIMCurve.

PASS:		*ds:si - Points chunk
		ax - current point
		bl - SplineDrawFlags
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:

PSEUDO-CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineDrawCurve 	proc	near 
	uses	ax,bx,cx,di,si
	class	VisSplineClass
	.enter

EC <	call	ECSplineInstanceAndPoints		> 
EC <	call	ECSplineAnchorPoint			>
	
	mov	cl, bl			; SplineDrawFlags
	call	SplineGetBezierPoints
	jc	done

	mov	si, di			; set of 4 Point structs
	mov	di, es:[bp].VSI_gstate


	; NOTE: This code added by Jim 3/22/93 to soften the harshness of
	; 	line joins, due to the fact that individual lines are not
	;	joined by the spline library.  This is a hack, and should
	;	be fixed in a future release.  There are problems in the kernel
	; 	as well, where GrDrawSpline, GrDrawPath do not apply joins 
	; 	between elements.

	push	ax
	call	GrGetLineEnd		; check it first so we don't set it
	cmp	al, LE_ROUNDCAP		;  100 times
	je	doneEnd
	mov	al, LE_ROUNDCAP
	call	GrSetLineEnd
doneEnd:
	pop	ax
	; If we're drawing a continuous (ie, filled) shape, then we
	; may need to use GrDrawCurveTo instead of GrDrawCurve

	SplineDerefScratchChunk bx
	test	ds:[bx].SD_flags, mask SDF_DRAW_CONTINUOUS
	jz	drawCurve


	cmpdw	ds:[si].CS_P0, ds:[bx].SD_lastDrawPoint, ax
	jne	drawCurve

	add	si, size Point		; skip first point
	call	GrDrawCurveTo
	add	si, 2 * size Point	; point to last point
	jmp	afterCurve

drawCurve:

	call	GrDrawCurve
	add	si, 3 * size Point

afterCurve:

	movdw	ds:[bx].SD_lastDrawPoint, ds:[si], ax
	
done:

	.leave
	ret

SplineDrawCurve	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetInvertMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the gstate to invert-mode

CALLED BY:	everywhere

PASS:		es:bp - VisSplineInstance data 
		al - SplineGStateMode

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 1/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvertModeLineAttrs LineAttr <CF_INDEX,
	<C_BLACK,0,0>,
	SDM_100,
	CMT_CLOSEST shl offset CMM_MAP_TYPE,
	LE_SQUARECAP,
	LJ_BEVELED,
	LS_SOLID,
	<0,0>>



SplineSetInvertMode	proc	near
	uses	ax,ds,si,di
	class	VisSplineClass 
	.enter
	call	SplineCheckCanDraw
	jc	done

	mov	di, es:[bp].VSI_gstate
	mov	al, SDM_100 
	call	GrSetAreaMask	
	mov	al, MM_INVERT
	call	GrSetMixMode

	segmov	ds, cs
	mov	si, offset InvertModeLineAttrs
	call	GrSetLineAttr
done:
	.leave
	ret
SplineSetInvertMode	endp

SplineSetInvertModeFar	proc	far
	call	SplineSetInvertMode
	ret
SplineSetInvertModeFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDrawPointCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the point (ax) depending on passed flags

CALLED BY:	SplineOperateOnPointCommon

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		ax - current point number
		bl - SplineDrawFlags

RETURN:		nothing

DESTROYED:	ax,bx,dx,dx,di

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawPointCommon	proc	near

	.enter

	push	ax
	CAElementToPtr	ds, si, ax, di, TRASH_AX_DX
	pop	ax

	test	bl, mask SDF_FILLED_HANDLES	; draw filled (anchor or ctrl)
	jz 	controlLine			; handle?
	call	SplineDrawFilledHandle

controlLine:
	; Now, test control lines:

	test	ds:[di].SPS_info, mask PIF_CONTROL ; is point a CONTROL point?
	jz	invertModeCurve			; NO:, skip this section
	test	bl, mask SDF_CONTROL_LINES	; YES: draw control lines?
	jz	done				;   NO: done
	call	SplineDrawControlLine
	jmp	done

	; From here down is for anchor points only.
invertModeCurve:	
	test	bl, mask SDF_IM_CURVE
	jz	normalCurve
	call	SplineDrawIMCurve
normalCurve:
	test	bl, mask SDF_CURVE
	jz	hollowHandle
	call	SplineDrawCurve
hollowHandle:
	test	bl, mask SDF_HOLLOW_HANDLES
	jz	marker
	call	SplineDrawHollowHandle
marker:
	test	bl, mask SDF_MARKER
	jz	done
	call	SplineDrawMarker
done:
EC <	call	ECSplinePoint			>
	.leave
	ret
SplineDrawPointCommon	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawMarker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a gstring marker for this point

CALLED BY:	SplineDrawPointCommon

PASS:		es:bp - VisSpline instance data
		*ds:si - points
		ds:di - current point

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawMarker	proc near
	uses	ax,bx,cx,dx,di,si,bp,ds
	class	VisSplineClass
	.enter

	; Load point's coordinates

	LoadPointAsInt	cx, dx, ds:[di].SPS_point

	; Get vis moniker for this marker type

	mov	bl, es:[bp].VSI_markerShape
	tst	bl
	jz	done

	ECCheckEtype	bl, MarkerShape

	clr	bh
	mov	si, cs:MarkerMonikerTable[bx]
	
	mov	bx, handle MarkerGStringUI
	call	MemLock
	jc	done		; what can I do???

	mov	ds, ax
	
	; Now, *ds:si is the VisMoniker

	mov	si, ds:[si]
	add	si, (offset VM_data + offset VMGS_gstring)

	; Get the location, and subtract off half the size to center it.

	mov	ax, cx
	mov	bx, dx

	sub	ax, MARKER_STD_SIZE/2
	sub	bx, MARKER_STD_SIZE/2
	mov	di, es:[bp].VSI_gstate

	push	cx, dx
	push	bx
	mov	cl, GST_PTR
	mov	bx, ds			; bx:si -> GString
	call	GrLoadGString
	pop	bx			; restore y position
	clr	dx			; pass no flags
	call	GrSaveState
	call	GrDrawGString
	call	GrRestoreState
	clr	di			; di <- no GState
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	cx, dx
	
	; Unlock the marker resource

	mov	bx, ds:[LMBH_handle]
	call	MemUnlock
done:
	.leave
	ret
SplineDrawMarker	endp

MarkerMonikerTable	word	\
	0,
	offset	SquareMoniker,
	offset	Cross1Moniker,
	offset	DiamondMoniker,
	offset	Cross2Moniker,
	offset	TriangleMoniker,
	offset	Bar1Moniker,
	offset	Bar2Moniker,
	offset	CircleMoniker




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineErasePointCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the point (ax) depending on passed flags

CALLED BY:	SplineDrawWhichPoints

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array
		ax - current point number
		bl - SplineDrawFlags
		dx - SplineWhichPointFlags

RETURN:		nothing

DESTROYED:	di

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineErasePointCommon	proc	near
	.enter

	call	ChunkArrayElementToPtr

	test	bl, mask SDF_FILLED_HANDLES	; draw filled (anchor or ctrl)
	jz 	controlLine			; handle?
	call	SplineEraseFilledHandle
	jmp	controlLine

controlLine:
	; Now, test control lines:

	test	ds:[di].SPS_info, mask PIF_CONTROL ; is point a CONTROL point?
	jz	invertModeCurve			; NO:, skip this section
	test	bl, mask SDF_CONTROL_LINES	; YES: erase control lines?
	jz	done				;   NO: done
	call	SplineEraseControlLine
	jmp	done
	
	; From here down is for anchor points only.
invertModeCurve:	
	test	bl, mask SDF_IM_CURVE
	jz	hollowHandle
	call	SplineEraseIMCurve
hollowHandle:
	test	bl, mask SDF_HOLLOW_HANDLES
	jz	done
	call	SplineEraseHollowHandle
done:
EC <	call	ECSplinePoint		>
	.leave
	ret
SplineErasePointCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawPointAsItThinksItsDrawn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the appropriate drawing routines based on
		the way the current point has its drawn bits set.

CALLED BY:	SplineDrawPointCommon

PASS:		ax - point number

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/12/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawPointAsItThinksItsDrawn	proc near 
	.enter

EC <	call	ECSplinePoint	>

	push	ax
	CAElementToPtr	ds, si, ax, di, TRASH_AX_DX
	pop	ax

	;
	; Common for anchors/controls:
	;

	test	ds:[di].SPS_info, mask PIF_FILLED_HANDLE
	jz	controlPoint
	call	SplineDrawFilledHandleLow

	; See if control point or anchor
controlPoint:
	test	ds:[di].SPS_info, mask PIF_CONTROL
	jz	anchor

	; If control, see if needs ctrl-line drawn
	test	ds:[di].SPS_info, mask CPIF_CONTROL_LINE
	jz	done
	call	SplineDrawControlLineLow
	jmp	done

anchor:
	; If anchor, see if hollow handle or curve needs drawing
	test	ds:[di].SPS_info, mask APIF_HOLLOW_HANDLE
	jz	invertModeCurve
	call	SplineDrawHollowHandleLow

invertModeCurve:
	test	ds:[di].SPS_info, mask APIF_IM_CURVE
	jz	done
	call	SplineDrawCurve
done:
	.leave
	ret
SplineDrawPointAsItThinksItsDrawn	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawIMCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the invert-mode curve of the current point if
		it's not already drawn.

CALLED BY:	SplineDrawPointCommon

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ax - current point number
		ds:di - current point

RETURN:		nothing

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:	
 
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawIMCurve	proc near	
	.enter
EC <	call	ECSplineAnchorPoint		> 
	test	ds:[di].SPS_info, mask APIF_IM_CURVE
	jnz	done
	ornf	ds:[di].SPS_info, mask APIF_IM_CURVE
	call	SplineDrawCurve
done:	
	.leave
	ret
SplineDrawIMCurve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEraseIMCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the current "invert-mode" curve -- IE call the
		"draw" procedure only if the curve is already drawn.

CALLED BY:	SplineErasePointCommon 

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ds:di - current point 
		ax - current point number

RETURN:		nohting

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/23/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEraseIMCurve	proc near
	.enter
EC <	call	ECSplineAnchorPoint		> 
	test	ds:[di].SPS_info, mask APIF_IM_CURVE
	jz	done
	andnf	ds:[di].SPS_info, not mask APIF_IM_CURVE
	call	SplineDrawCurve
done:
	.leave
	ret
SplineEraseIMCurve	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDrawControlLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a line from the current control point to its
		owner (anchor point)

CALLED BY:	SplineDrawPointCommon

PASS:		ds:di - control point 
		*ds:si - Chunk array of points

RETURN:		nothing

DESTROYED:	ax,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawControlLine	proc	near	

	test	ds:[di].SPS_info, mask CPIF_CONTROL_LINE
	jnz	done
	ornf	ds:[di].SPS_info, mask CPIF_CONTROL_LINE
	GOTO	SplineDrawControlLineLow
done:
	ret
SplineDrawControlLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawControlLineLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the graphics draw operation for a control
		line.  This will either draw or erase the control line
		on the screen, depending on certain things...

CALLED BY:	SplineDrawControlLine

PASS:		ax - control point #
		ds:di - control point
		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	cx,dx	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawControlLineLow	proc near 	

	uses	ax,bx,di

	class	VisSplineClass	

	.enter

EC <	call	ECSplineInstanceAndPoints		>

	LoadPointAsInt	cx, dx, ds:[di].SPS_point

	call	SplineGotoAnchor	; goto the anchor point of this ctrl.

	LoadPointAsInt	ax, bx, ds:[di].SPS_point
	mov	di, es:[bp].VSI_gstate

	;
	;  Set the line style to dotted to differentiate between the
	;  control line and the inverted spline line
	;
	push	ax, bx
	mov	al, LS_DOTTED	
	clr	bl
	call	GrSetLineStyle
	pop	ax, bx

	call	GrDrawLine

	;
	;  Restore to LS_SOLID (as in InvertModeLineAbttrs)
	;
	mov	al, LS_SOLID
	clr	bl
	call	GrSetLineStyle

	.leave
	ret
SplineDrawControlLineLow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDrawFilledHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a filled handle around the current point

CALLED BY:	SplineDrawPointCommon, SplineDrawPointForDragRect

PASS:		ds:[di] - current point
		*ds:si - points chunk array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	ax,cx,dx

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:
	If point is an ANCHOR, and it 
		already has a HOLLOW handle, erase it first.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawFilledHandle	proc	near

	.enter

EC <	call	ECSplinePointDSDI			>

	;
	; Erase hollow handle, if need be, and if this point isn't a
	; control point.
	;

	test	ds:[di].SPS_info, mask PIF_CONTROL
	jnz	drawFilled
	call	SplineEraseHollowHandle

drawFilled:
	;
	; See if filled handle is already drawn (no need to draw again)
	;

	test	ds:[di].SPS_info, mask PIF_FILLED_HANDLE
	jnz	done
	ornf	ds:[di].SPS_info, mask PIF_FILLED_HANDLE
	call	SplineDrawFilledHandleLow
done:
	.leave
	ret
SplineDrawFilledHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineEraseFilledHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the current point's filled (hollow) handle

CALLED BY:	SplineErasePointCommon

PASS:		ds:di - current point
		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	cx,dx	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEraseFilledHandle	proc near
	test	ds:[di].SPS_info, mask PIF_FILLED_HANDLE
	jz	done
	BitClr	ds:[di].SPS_info, PIF_FILLED_HANDLE
	call	SplineDrawFilledHandleLow
done:
	ret
SplineEraseFilledHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEraseHollowHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the spline's Hollow Handle is drawn, then erase it
	and reset the APIF_HOLLOW_HANDLE bit in the point's DrawnFlags record.

CALLED BY:	SplineErasePointCommon

PASS:		ds:di - point data
		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	ax,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEraseHollowHandle	proc near

	test	ds:[di].SPS_info, mask APIF_HOLLOW_HANDLE
	jz	done
	BitClr	ds:[di].SPS_info, APIF_HOLLOW_HANDLE
	call	SplineDrawHollowHandleLow
done:
	ret
SplineEraseHollowHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEraseControlLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the point's control line is drawn, then erase it
	and reset the appropriate bit.

CALLED BY:	SplineErasePointCommon

PASS:		ds:di - point's data
		es:bp - VisSplineInstance data
		ax - point number 

RETURN:		nothing

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEraseControlLine		proc near

EC <	call	ECSplineControlPoint		> 

	test	ds:[di].SPS_info, mask CPIF_CONTROL_LINE
	jz	done
	BitClr	ds:[di].SPS_info, CPIF_CONTROL_LINE
	call	SplineDrawControlLineLow
done:
	ret
SplineEraseControlLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawFilledHandleLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the graphics draw operation --
		This may actually either draw or erase the handle,
		depending on various things...

CALLED BY:	SplineDrawFilledHandle

PASS:		ds:[di] - current point
		*ds:si - points chunk array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	cx,dx 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawFilledHandleLow	proc near 	

	uses	ax,bx,di,si,ds

	class	VisSplineClass	

	.enter

	LoadPointAsInt	ax, bx, ds:[di].SPS_point	; get point into ax,bx
	mov	si, offset ControlRegion
	test	ds:[di].SPS_info, mask PIF_CONTROL 	; is this an anchor?
	jnz	drawReg
	mov	si, offset FilledAnchorRegion

drawReg:
	segmov	ds, cs
	mov	di, es:[bp].VSI_gstate
	call	GrDrawRegion
	.leave
	ret

SplineDrawFilledHandleLow	endp

;
;  If you make these regions any bigger or smaller, you might want to
;  consider changing SPLINE_POINT_MOUSE_TOLERANCE as well...
;

FilledAnchorRegion		word	-4, -4, 4, 4	;the "vis" bounds
				word	-5, EOREGREC
				word	-4, -1, 1, EOREGREC
				word	-2, -3, 3, EOREGREC
				word	1, -4, 4, EOREGREC
				word	3, -3, 3, EOREGREC
				word	4, -1, 1, EOREGREC
				word	EOREGREC

HollowAnchorRegion		word	-4, -4, 4, 4	;the "vis" bounds
				word	-5, EOREGREC
				word	-4, -1, 1, EOREGREC
				word	-3, -3, -2, 2, 3, EOREGREC
				word	-2, -3, -3, 3, 3, EOREGREC
				word	1, -4, -4, 4, 4, EOREGREC
				word	2, -3, -3, 3, 3, EOREGREC
				word	3, -3, -2, 2, 3, EOREGREC
				word	4, -1, 1, EOREGREC
				word	EOREGREC

ControlRegion			word	-3, -3, 3, 3	;the "vis" bounds
				word	-4, EOREGREC
				word	-3, -1, 1, EOREGREC
				word	-2, -2, 2, EOREGREC
				word	1, -3, 3, EOREGREC
				word	2, -2, 2, EOREGREC
				word	3, -1, 1, EOREGREC
				word	EOREGREC


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDrawHollowHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a hollow handle around the current anchor point

CALLED BY:	SplineDrawPointCommon, SplineDrawPointForDragRect

PASS:		ds:di - point to draw
		es:bp - VisSplineInstance data

RETURN:		nothing 

DESTROYED:	cx,dx

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawHollowHandle	proc	near

EC <	call	ECSplinePointDSDI			>

	; Erase filled handle (if drawn)

	call	SplineEraseFilledHandle

	; See if hollow handle already drawn:

	test	ds:[di].SPS_info, mask APIF_HOLLOW_HANDLE
	jnz	done
	ornf	ds:[di].SPS_info, mask APIF_HOLLOW_HANDLE
	call	SplineDrawHollowHandleLow
done:
	.leave
	ret
SplineDrawHollowHandle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineDrawHollowHandleLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the hollow handle (this will either draw it
		or erase it if it's already drawn)

CALLED BY:	SplineDrawHollowHandle

PASS:		ds:di - point
		es:bp - VisSplineInstance data

RETURN:		nothing 

DESTROYED:	cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 7/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDrawHollowHandleLow	proc near

 	uses	ax,bx,di,si,ds

	class	VisSplineClass	
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 
EC <	call	ECSplinePointDSDI			>

	LoadPointAsInt	ax, bx, ds:[di].SPS_point	; get point into ax,bx
	segmov	ds, cs
	mov	si, offset HollowAnchorRegion
	mov	di, es:[bp].VSI_gstate
	call	GrDrawRegion

	.leave
	ret
SplineDrawHollowHandleLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInvalCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the current curve

CALLED BY:	SplineOperateOnPointCommon

PASS:		ax - current anchor point 
		bl - SplineDrawFlags
		*ds:si - points array
		es:bp - VisSplineInstance data		

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/25/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInvalCurve	proc near 	

	class	VisSplineClass	

	.enter

EC <	call	ECSplineInstanceAndPoints		>
EC <	call	ECSplineAnchorPoint		> 

	; If at first anchor, also inval the area BEFORE it.  This may, on
	; occasion, invalidate more than is needed, but that's OK.
	cmp	ax, 1
	jg	thisOne
	call	SplineInvalBeforeFirstAnchor

thisOne:
	call	SplineGetBoundingRectangle
  
	mov	di, es:[bp].VSI_gstate

	call	GrInvalRect
	.leave
EC <	call	ECSplineInstanceAndPoints		> 
	ret
SplineInvalCurve	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInvalBeforeFirstAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the rectangle made up of the first anchor point and
		its PREV_CONTROL.

CALLED BY:	SplineInvalCurve

PASS:		ax - anchor point number
		es:bp - VisSplineInstance data 
		*ds:si - points array 

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInvalBeforeFirstAnchor	proc	near
	uses	ax,bx,cx,dx,di,si

	class	VisSplineClass 

	.enter

EC <	call	ECSplineInstanceAndPoints		> 
EC <	call	ECSplineAnchorPoint		> 
	call	ChunkArrayElementToPtr

	LoadPointAsInt	cx, dx, ds:[di].SPS_point

	call	SplineGotoPrevControl
	jc	done
	LoadPointAsInt	si, bx, ds:[di].SPS_point

	; make AX < CX   and BX < DX
	SortRegs	si, cx
	SortRegs	bx, dx

	; enlarge to include handles
	mov	al, es:[bp].VSI_handleSize.BBF_int
	cbw
	sub	si, ax
	sub	bx, ax
	add	cx, ax
	add	dx, ax
	mov_tr	ax, si

	mov	di, es:[bp].VSI_gstate

	call	GrInvalRect
done:
	.leave
	ret
SplineInvalBeforeFirstAnchor	endp


SplinePtrCode	ends
