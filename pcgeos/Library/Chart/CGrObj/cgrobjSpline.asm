COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgrobjSpline.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 2/92   	Initial version.

DESCRIPTION:
	

	$Id: cgrobjSpline.asm,v 1.1 97/04/04 17:48:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartSplineGuardianInvertHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	send a message to the spline

PASS:		*ds:si	= ChartSplineGuardianClass object
		ds:di	= ChartSplineGuardianClass instance data
		es	= segment of ChartSplineGuardianClass
		dx	- gstate handle

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartSplineGuardianInvertHandles method	dynamic	ChartSplineGuardianClass, 
					MSG_GO_INVERT_HANDLES
	uses	cx,dx,bp
	.enter


	mov	di, dx				; gstate

	call	GrSaveTransform
	call	GrObjApplyNormalTransform

	mov	dx, di				; gstate
	mov	ax, MSG_GOVG_APPLY_OBJECT_TO_VIS_TRANSFORM
	call	ObjCallInstanceNoLock


	push	dx				; gstate
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	call	ObjCallInstanceNoLock		; cx:dx - ward
	movdw	bxsi, cxdx
	
	pop	bp				; gstate
	mov	ax, MSG_SPLINE_INVERT_HOLLOW_HANDLES
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage

	mov	di, bp				; gstate
	call	GrRestoreTransform
	.leave
	ret
ChartSplineGuardianInvertHandles	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartSplineGuardianInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	set the GrObjMessageOptimizationFlags so that
		MSG_GO_DRAW_LINE is always sent (so that markers will
		be drawn)

PASS:		*ds:si	- ChartSplineGuardianClass object
		ds:di	- ChartSplineGuardianClass instance data
		es	- segment of ChartSplineGuardianClass

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartSplineGuardianInitialize	method	dynamic	ChartSplineGuardianClass, 
					MSG_GO_INITIALIZE
	uses	cx,dx,bp
	.enter
	mov	di, offset ChartSplineGuardianClass
	call	ObjCallSuperNoLock

	;
	; Set the GOMOF_DRAW_FG_LINE flag
	;

	mov	di, ds:[si]
	add	di, ds:[di].GrObj_offset
	ornf	ds:[di].GOI_msgOptFlags, mask GOMOF_DRAW_FG_LINE

	.leave
	ret
ChartSplineGuardianInitialize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartSplineGuardianGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartSplineGuardianClass object
		ds:di	- ChartSplineGuardianClass instance data
		es	- segment of ChartSplineGuardianClass

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

ChartSplineGuardianGetClass	method	dynamic	ChartSplineGuardianClass, 
					MSG_META_GET_CLASS
	mov	cx, segment SplineGuardianClass
	mov	dx, offset SplineGuardianClass
	ret
ChartSplineGuardianGetClass	endm

