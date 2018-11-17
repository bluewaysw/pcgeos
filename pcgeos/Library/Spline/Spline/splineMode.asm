COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		spline
FILE:		splineMode.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/11/91	Initial version.

DESCRIPTION:
	

	$Id: splineMode.asm,v 1.1 97/04/07 11:09:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineUtilCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineSetMode, MSG_SPLINE_SET_MODE

DESCRIPTION:	Set the SplineMode

PASS:		*ds:si - VisSpline object
		ds:bx - VisSpline object
		ds:di - VisSpline-class instance data
		cl - SplineMode

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	
	Only uselect all points if going into create modes or inactive
	mode.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSetMode	method dynamic VisSplineClass, MSG_SPLINE_SET_MODE
	uses	ax, cx, dx, bp
	.enter	
	
EC <	cmp	cl, SplineMode			>
EC <	ERROR_AE	ILLEGAL_SPLINE_MODE	>

	;
	; Check for trivial reject
	;


	GetEtypeFromRecord	al, SS_MODE, ds:[di].VSI_state
	cmp	al, cl
	je	done

	;
	; create a gstate, as we'll need to do some drawing
	;


	call	SplineCreateGState
	call	SplineMethodCommon

	;
	; Leave the old mode
	;


	mov	bl, al		; original mode
	clr	bh
	CallTable bx, SplineLeaveModeCalls, SplineMode
	
	;
	; Set the new mode
	;

	mov	bl, cl
	SetEtypeInRecord	bl, SS_MODE, es:[bp].VSI_state


	clr	bh
	CallTable bx, SplineSetModeCalls, SplineMode

	call	SplineDestroyGState

	mov	cx, UPDATE_ALL
	call	SplineUpdateUI

	call	SplineEndmCommon 
done:
	.leave
	ret
SplineSetMode	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineNotifyCreateModeDone, MSG_SPLINE_NOTIFY_CREATE_MODE_DONE

DESCRIPTION:	Default handler switches to inactive mode

PASS:		*ds:si - VisSpline object
		ds:bx - VisSpline object
		ds:di - VisSpline-class instance data

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	
	none

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SRS	11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineNotifyCreateModeDone	method dynamic VisSplineClass, \
					MSG_SPLINE_NOTIFY_CREATE_MODE_DONE
	uses	ax, cx
	.enter	
	
	mov	cl, SM_INACTIVE
	mov	ax, MSG_SPLINE_SET_MODE
	call	ObjCallInstanceNoLock

	.leave
	ret
SplineNotifyCreateModeDone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the mode

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		cl - SplineMode etype

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/17/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetMode	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_MODE
	.enter
	GetEtypeFromRecord	cl, SS_MODE, ds:[di].VSI_state
	
	.leave
	ret
SplineGetMode	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineInactiveMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go into "inactive" mode where the spline's points
		aren't drawn and nothing's selected.

CALLED BY:	SplineSetMode

PASS:		es:bp - VisSplineInstance data 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineInactiveMode	proc near
	class	VisSplineClass
	SetEtypeInRecord AT_SELECT_NOTHING, SES_ACTION, es:[bp].VSI_editState
	call	SplineUnselectAll
	call	SplineEraseInvertModeStuff
	ret
SplineInactiveMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCreateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enter one of the create modes

CALLED BY:	SplineSetMode

PASS:		es:bp - VisSplineInstance data 

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/30/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCreateMode	proc near
	class	VisSplineClass 
	.enter
	call	SplineUnselectAll
	call	SplineDrawInvertModeStuff

	push	si
	SplineDerefScratchChunk si

	;
	; Cause the same scratch chunk to persist all thru create
	; mode.  We use this chunk for keeping the mouse position
	; between events, etc.
	;

	inc	ds:[si].SD_refCount
	mov	si, ds:[si].SD_splineChunkHandle

	push	ds:[LMBH_handle]		; save handle for fixup
	segxchg	es, ds
	call	VisGrabMouse
	segmov	es, ds
	call	MemDerefStackDS
	pop	si

	.leave
	ret
SplineCreateMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineAdvancedEditMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change all anchor points from VERY_SMOOTH to 
		SEMI_SMOOTH.  Unselect any selected points.

CALLED BY:	internal

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array

RETURN:		nothing

DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineAdvancedEditMode	proc	near
	class	VisSplineClass

	.enter

EC <	call	ECSplineInstanceAndPoints	>

	;
	; Set Smoothness to SEMI_SMOOTH for all points
	;

	mov	al, SOT_MODIFY_INFO_FLAGS
	mov	bx, mask SWPF_ANCHOR_POINT
	movHL	cx, <ST_SEMI_SMOOTH>, <mask APIF_SMOOTHNESS>
	call	SplineOperateOnAllPoints

	call	SplineEditModeCommon

	.leave
	ret
SplineAdvancedEditMode	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEditModeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for entering one of the edit modes

CALLED BY:	SplineBeginnerEditMode, SplineAdvancedEditMode

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEditModeCommon	proc near

	class	VisSplineClass 

	.enter

	;
	; Increment the scratch chunk ref count so that it persists
	; until we leave edit mode
	;
	SplineDerefScratchChunk di
	inc	ds:[di].SD_refCount


	call	SplineDrawInvertModeStuff

	.leave
	ret
SplineEditModeCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineBeginnerEditMode		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unselect everything -- make all anchors "auto-smooth"

CALLED BY:

PASS:		*ds:si - points array
		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineBeginnerEditMode	proc	near
	class	VisSplineClass
	uses	ax, bx, cx

	.enter
EC <	call	ECSplineInstanceAndPoints	>

	;
	; Set all anchors to AUTO_SMOOTH
	;

	mov	al, SOT_MODIFY_INFO_FLAGS
	mov	bx, mask SWPF_ANCHOR_POINT
	movHL	cx, <ST_AUTO_SMOOTH>, <mask APIF_SMOOTHNESS>
	call	SplineOperateOnAllPoints

	; If we're going from ADVANCED_EDIT mode to BEGINNER_EDIT, and
	; if AT_SELECT_SEGMENT was the current action type, then
	; change to AT_SELECT_ANCHOR

	GetActionType	al
	cmp	al, AT_SELECT_SEGMENT
	jne	ok
	SetActionType	AT_SELECT_ANCHOR
ok:

	;
	; erase whatever was drawn before, and redraw it.  The "draw"
	; procedure should know what to draw.
	;

	call	SplineEraseInvertModeStuff


	call	SplineEditModeCommon

	.leave
	ret
SplineBeginnerEditMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineLeaveCreateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Leave the current create mode (beginning or advanced)
		Let go of the mouse.  Lower ref count on scratch chunk.
		Enter the corresponding EDIT mode.

CALLED BY:	SplineSSCreateMode, SplineStartMoveCopy

PASS:		es:bp - VisSplineInstance data 
		*ds:si - points array 
		ds - spline's points block

RETURN:		nothing 

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/27/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineLeaveCreateMode	proc near
	uses	si,cx,bx
	class	VisSplineClass
	.enter

EC <	call	ECSplineInstanceAndPoints		>  

	;
	; If we were following the mouse around, then stop that
	; nonsense now.
	;

	call	SplineDrawFromLastAnchorToMouse

	;
	; Nuke the action type
	;

	SetActionType	AT_NONE

	;
	; decrement scratch chunk's ref count so it will get destroyed
	; properly at the end of this method.
	;

	SplineDerefScratchChunk si
	dec	ds:[si].SD_refCount
	mov	si, ds:[si].SD_splineChunkHandle

	;
	; Release the mouse grab.  
	;

	push	ds:[LMBH_handle]
	segxchg	ds, es
	call	VisReleaseMouse
	segmov	es, ds
	call	MemDerefStackDS

	.leave
	ret
SplineLeaveCreateMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineLeaveBeginnerSplineCreateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the invert-mode curve drawn on the last anchor's
		PREV anchor, and draw a "normal" curve there.

CALLED BY:	SplineSetMode

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineLeaveBeginnerSplineCreateMode	proc near

	uses	bx,cx,dx

	.enter

	;
	; Call the common routine
	;

	call	SplineLeaveCreateMode

	call	SplineSetInvertModeFar
	
	call	SplineGotoLastAnchor
	jc	done

	;
	; Erase IM curve 
	;

	movHL	bx, <mask SDF_IM_CURVE>, <SOT_ERASE>
	mov	dx, mask SWPF_PREV_ANCHOR
	call	SplineOperateOnCurrentPointFar

	;
	; Draw normal curve
	;

	call	SplineSetNormalAttributes 
	movHL	bx, <mask SDF_CURVE>, <SOT_DRAW> 
	call	SplineOperateOnCurrentPointFar 

done:

	.leave
	ret
SplineLeaveBeginnerSplineCreateMode	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineLeaveEditMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Leave one of the edit modes.  decrement the scratch
		chunk's ref count

CALLED BY:	SplineSetMode

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineLeaveEditMode	proc near
	class	VisSplineClass 

	.enter
	;
	; Nuke the action type
	;

	SetActionType	AT_NONE


	;
	; decrement the ref count of the scratch chunk
	;


	SplineDerefScratchChunk di
	dec	ds:[di].SD_refCount
	.leave
	ret
SplineLeaveEditMode	endp




StubSUC	proc	near
	ret
StubSUC	endp

SplineUtilCode	ends


SplineSelectCode	segment


SplineSelectCode	ends
