COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodySuspend.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/27/92   	Initial version.

DESCRIPTION:
	

	$Id: cbodySuspend.asm,v 1.1 97/04/04 17:48:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyUnSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	if suspend count drops to zero, then update ui, etc.

PASS:		*ds:si	= ChartBodyClass object
		ds:di	= ChartBodyClass instance data
		es	= Segment of ChartBodyClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyUnSuspend	method	dynamic	ChartBodyClass, 
					MSG_META_UNSUSPEND
	.enter

	push	ax
	mov	di, offset ChartBodyClass
	call	ObjCallSuperNoLock
	pop	ax

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_suspendCount
	jnz	done

	;
	; tell the kids what's up
	;

	call	ChartBodyCallChildren

	mov	di, ds:[si]
	add	di, ds:[di].ChartBody_offset
	clr	cx
	xchg	cx, ds:[di].CBI_unSuspendFlags
	mov	ax, MSG_CHART_BODY_UPDATE_UI
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
ChartBodyUnSuspend	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyGetSuspendCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the GrObjBody's suspension count

PASS:		*ds:si	= ChartBodyClass object
		ds:di	= ChartBodyClass instance data
		es	= Segment of ChartBodyClass.

RETURN:		ax = 	suspend count

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyGetSuspendCount	method	dynamic	ChartBodyClass, 
					MSG_CHART_BODY_GET_SUSPEND_COUNT
	mov	ax, ds:[di].GBI_suspendCount
	ret
ChartBodyGetSuspendCount	endm

