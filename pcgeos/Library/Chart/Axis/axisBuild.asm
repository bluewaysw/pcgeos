COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		axisBuild.asm

AUTHOR:		John Wedgwood, Oct 21, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/21/91	Initial revision

DESCRIPTION:
	Code for building an axis.

	$Id: axisBuild.asm,v 1.1 97/04/04 17:45:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build an axis...

CALLED BY:	via MSG_CHART_OBJECT_BUILD
PASS:		*ds:si	= Axis object
		ds:di	= Instance data
		bp - BuildChangeFlags

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AxisBuild	method dynamic	AxisClass, MSG_CHART_OBJECT_BUILD

	uses	ax,cx,dx,bp

	.enter

	ECCheckFlags	bp, BuildChangeFlags

	test	ds:[di].COI_state, mask COS_BUILT
	jnz	afterFirst

	; First-time build, set attributes

	clrdw	ds:[di].AI_maxLabelSize

afterFirst:

	;
	; If the data changed, then mark the geometry invalid as
	; category titles may have changed
	;

	test	bp, mask BCF_DATA
	jz	done

	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cx, mask COS_GEOMETRY_INVALID or mask COS_IMAGE_INVALID
	call	ObjCallInstanceNoLock

done:

	.leave
	mov	di, offset AxisClass
	GOTO	ObjCallSuperNoLock
AxisBuild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisCreateTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Create a title object for this axis

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	If axis is VERTICAL:
		place title as first child in HorizComp object
	ELSE
		place title as last child in ChartGroup object

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisCreateTitle	method	dynamic	AxisClass, 
					MSG_AXIS_CREATE_TITLE
		uses	ax,cx,dx,bp
		
		.enter

EC <		tst	ds:[di].AI_title				>
EC <		ERROR_NZ	AXIS_ALREADY_HAS_TITLE		>

		test	ds:[di].AI_attr, mask AA_VERTICAL
		jz	horizontal
	;
	; Set up params for Y-axis
	;

		mov	al, TT_Y_AXIS
		mov	cl, CORT_90_DEGREES
		jmp	create

horizontal:
		mov	al, TT_X_AXIS
		mov	cl, CORT_0_DEGREES

create:
		call	UtilCreateTitleObject	; *ds:dx - new title

	;
	; Deref axis and stick title's chunk handle in axis instance
	; data. 
	;
		DerefChartObject ds, si, di
		mov	ds:[di].AI_title, dx

	;
	; Tell the title who its axis is
	;
		mov	cx, si			; axis
		mov	si, dx			; title
		mov	ax, MSG_TITLE_SET_AXIS
		call	ObjCallInstanceNoLock

		.leave
		ret
AxisCreateTitle	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisGetTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the chunk handle of the title object

PASS:		*ds:si	- AxisClass object
		ds:di	- AxisClass instance data
		es	- segment of AxisClass

RETURN:		cx - chunk handle of title

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisGetTitle	method	dynamic	AxisClass, 
					MSG_AXIS_GET_TITLE
		mov	cx, ds:[di].AI_title
		ret
AxisGetTitle	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisDestroyTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Destroy a title for this axis

PASS:		*ds:si	= AxisClass object
		ds:di	= AxisClass instance data
		es	= Segment of AxisClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisDestroyTitle	method	dynamic	AxisClass, 
					MSG_AXIS_DESTROY_TITLE
	lea	di, ds:[di].AI_title
	call	UtilDetachAndKill

	ret
AxisDestroyTitle	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AxisClearAllGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke the GROUP before calling the superclass

PASS:		*ds:si	- AxisClass object
		ds:di	- AxisClass instance data
		es	- segment of AxisClass

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AxisClearAllGrObjes	method	dynamic	AxisClass, 
					MSG_CHART_OBJECT_CLEAR_ALL_GROBJES

	;
	; Call superclass FIRST so that all grobjects begin getting freed
	;

	mov	di, offset AxisClass
	call	ObjCallSuperNoLock

	DerefChartObject ds, si, di
	movdw	bxsi, ds:[di].AI_group
	call	UtilClearGrObj
	ret
AxisClearAllGrObjes	endm



AxisCode	ends
