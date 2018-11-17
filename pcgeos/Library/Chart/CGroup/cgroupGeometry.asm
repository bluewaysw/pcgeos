COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupGeometry.asm

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
	CDB	2/24/92   	Initial version.

DESCRIPTION:
	

	$Id: cgroupGeometry.asm,v 1.1 97/04/04 17:45:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Recalc the size of the overall chart.

PASS:		*ds:si	= ChartGroupClass object
		ds:di	= ChartGroupClass instance data
		es	= Segment of ChartGroupClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
	This routine ignores the passed values in CX, DX
	 -- use SetSize to set the size

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupRecalcSize	method	dynamic	ChartGroupClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
		uses	ax,cx,dx
		.enter

		mov	cl, mask COS_GEOMETRY_INVALID
		call	CheckToUpdate
		jc	done

		movP	cxdx, ds:[di].COI_size

		andnf	ds:[di].COI_state, not mask COS_GEOMETRY_LOOP
geometryLoop:

	;
	; Clear the COS_GEOMETRY_INVALID flag now, so we can tell if
	; any children set it, which means we'll need to do this all
	; over again.
	; Hopefully we won't get into an infinite loop this way...
	;

		andnf	ds:[di].COI_state, not mask COS_GEOMETRY_INVALID

		mov	ax, MSG_CHART_OBJECT_RECALC_SIZE
		mov	di, offset ChartGroupClass
		call	ObjCallSuperNoLock

	;
	; If a child (title) marked geometry invalid, then start over.
	; Otherwise, store the returned size, and finish.
	;
		DerefChartObject ds, si, di
		xchg	ds:[di].COI_size.P_x, cx
		xchg	ds:[di].COI_size.P_y, dx

		test	ds:[di].COI_state, mask COS_GEOMETRY_INVALID
		jz	endLoop

		cmp	ds:[di].COI_size.P_x, cx
		jne	geometryLoop
		cmp	ds:[di].COI_size.P_y, dx
		jne	geometryLoop
		test	ds:[di].COI_state, mask COS_GEOMETRY_LOOP
		jnz	infiniteLoop
		ornf	ds:[di].COI_state, mask COS_GEOMETRY_LOOP
		jmp	short geometryLoop		; one more try

infiniteLoop:
	;
	; In infinite geometry loop, just stop.
	; XXX: If possible, rebuild chart from scratch?
	;
endLoop:

	; Set position

		mov	ax, MSG_CHART_OBJECT_SET_POSITION
		call	ObjCallInstanceNoLock


	; clear the UPDATING flag
		
		call	ChartGroupEndUpdate

done:
	.leave
	ret
ChartGroupRecalcSize	endm

