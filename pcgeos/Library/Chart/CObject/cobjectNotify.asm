COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectNotify.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/28/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectNotify.asm,v 1.1 97/04/04 17:46:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Deal with notification from the GrObj.  Convert an
		etype to a message.

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

		bp 	= GrObjActionNotificationType

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectNotify	method	dynamic	ChartObjectClass, 
					MSG_GROBJ_ACTION_NOTIFICATION
	.enter

	; convert action type to a message, and call.

	shl	bp, 1
	mov	ax, cs:NotifyTable[bp]
	tst	ax
	jz	done
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
ChartObjectNotify	endm


NotifyTable	word	\
	0,					; NULL
	MSG_CHART_OBJECT_GROBJ_SELECTED,	; GOANT_SELECTED
	MSG_CHART_OBJECT_GROBJ_UNSELECTED,	; GOANT_UNSELECTED
	0,					; GOANT_CREATED
	MSG_CHART_OBJECT_GROBJ_MOVED,		; GOANT_MOVED
	MSG_CHART_OBJECT_GROBJ_RESIZED,		; GOANT_RESIZED
	0,					; GOANT_ROTATED
	0,					; GOANT_SKEWED
	0,					; GOANT_TRANSFORMED
	MSG_CHART_OBJECT_GROBJ_ATTRED,		; GOANT_ATTRED
	0,					; GOANT_SPEC_MODIFIED
	0,					; GOANT_PASTED
	MSG_CHART_OBJECT_GROBJ_DELETED,		; GOANT_DELETED
	0,					; GOANT_WRAP_CHANGED
	0,					; GOANT_UNDO_GEOMETRY
	0,					; GOANT_UNDO_DELETE
	0,					; GOANT_REDO_DELETE
	0,					; GOANT_PRE_MOVE
	0,					; GOANT_PRE_RESIZE
	0,					; GOANT_PRE_ROTATE
	0,					; GOANT_PRE_SKEW
	0,					; GOANT_PRE_TRANSFORM
	0,					; GOANT_PRE_SPEC_MODIFY
	0,					; GOANT_QUERY_DELETE
	0					; GOANT_PRE_WRAP_CHANGE

.assert (length NotifyTable eq GrObjActionNotificationType)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGrObjSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	deal with the fact that a grobj was selected

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	It's possible that multiple objects will tell this grobj 	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ChartObjectGrObjSelected	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_GROBJ_SELECTED

	call	ObjIncInteractibleCount
	inc	ds:[di].COI_selection
EC <	ERROR_Z	INVALID_SELECTION_COUNT		>

	FALL_THRU	SelectedCommon
ChartObjectGrObjSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectedCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to handle gained/lost selection

CALLED BY:

PASS:		ax - message
		*ds:si - object

RETURN:		nothing 

DESTROYED:	si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectedCommon	proc far
	.enter

	;
	; send message to ChartGroup, unless this IS the chart
	; group!

	cmp	si, offset TemplateChartGroup
	je	done

	mov	si, offset TemplateChartGroup
	call	ObjCallInstanceNoLock
done:
	.leave
	ret

SelectedCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGrObjUnselected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that one of the objects under this
		object's control has lost the selection

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectGrObjUnselected	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_GROBJ_UNSELECTED
	call	ObjDecInteractibleCount
	dec	ds:[di].COI_selection
EC <	ERROR_S	INVALID_SELECTION_COUNT		>
	GOTO	SelectedCommon
ChartObjectGrObjUnselected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGrObjResized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that a GrObj has been resized.

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= Segment of ChartObjectClass.
		
		^lcx:dx = od of grobj

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Get the size of the grobject, and update our own instance
	data.  Mark geometry invalid so stuff gets updated.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	CDB	3/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectGrObjResized	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_GROBJ_RESIZED
	uses	ax,cx,dx,bp

	.enter

	push	cx, dx
	mov	ax, MSG_META_SUSPEND
	call	UtilCallChartBody
	pop	cx, dx

	;
	; GrObj has moved, most likely:
	;

	mov	ax, MSG_CHART_OBJECT_GROBJ_MOVED
	call	ObjCallInstanceNoLock

	;
	; Get the GrObj's new size -- use the PARENT bounds because
	; the object itself might be rotated.
	;

	sub	sp, size RectDWord
	mov	bp, sp

	push	si
	movOD	bxsi, cxdx
	mov	ax, MSG_GO_GET_DW_PARENT_BOUNDS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	DerefChartObject ds, si, di

	; Get width

	movdw	bxax, ss:[bp].RD_right
	subdw	bxax, ss:[bp].RD_left
	abs	ax
	mov	cx, ax	
	xchg	ax, ds:[di].COI_size.P_x
	sub	cx, ax			; difference in X

	movdw	bxax, ss:[bp].RD_bottom
	subdw	bxax, ss:[bp].RD_top
	abs	ax
	mov	dx, ax
	xchg	ax, ds:[di].COI_size.P_y
	sub	dx, ax

	add	sp, size RectDWord

	tst	dx
	jnz	recalc
	jcxz	done

recalc:

	mov	ax, MSG_CHART_OBJECT_RECALC_SIZE
	call	UtilCallChartGroup
done:

	mov	ax, MSG_META_UNSUSPEND
	call	UtilCallChartBody

	.leave
	ret
ChartObjectGrObjResized	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGrObjAttred
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle an attr-change

PASS:		*ds:si	- ChartObjectClass object
		ds:di	- ChartObjectClass instance data
		es	- segment of ChartObjectClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectGrObjAttred	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_GROBJ_ATTRED

	.enter
	
	;
	; Suspend the body and unsuspend it via the queue, in case
	; multiple objects are having their attributes changed.
	;

	push	cx, dx
	mov	ax, MSG_META_SUSPEND
	call	UtilCallChartBody
	pop	cx, dx

	mov	ax, MSG_META_UNSUSPEND
	call	UtilCallChartBodyForceQueue

	;
	; If it's a text object, mark our image invalid
	;

	push	si
	movOD	bxsi, cxdx
	mov	cx, segment TextGuardianClass
	mov	dx, offset TextGuardianClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	jnc	done

	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cl, mask COS_IMAGE_INVALID or mask COS_GEOMETRY_INVALID
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
ChartObjectGrObjAttred	endm




