COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Body
FILE:		bodyTest.asm

AUTHOR:		Steve Scholl, Feb 13, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	2/13/92		Initial revision


DESCRIPTION:
	
		

	$Id: bodyTest.asm,v 1.1 97/04/04 18:07:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
include	timedate.def


BodyTestCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest1	method dynamic GrObjBodyClass, MSG_GB_TEST_1
	.enter

	call	MakeAttrsDefault

	.leave
	ret
GrObjBodyTest1		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest2	method dynamic GrObjBodyClass, MSG_GB_TEST_2
	.enter

	call	Show


	.leave
	ret
GrObjBodyTest2		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/33/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest3	method dynamic GrObjBodyClass, MSG_GB_TEST_3
	.enter

	sub	sp, size GrObjBodyCustomDuplicateParams
	mov	bp, sp
	mov	ss:[bp].GBCDP_repetitions, 4

	mov	ss:[bp].GBCDP_move.PDF_x.DWF_int.high, 0
	mov	ss:[bp].GBCDP_move.PDF_x.DWF_int.low, 20
	mov	ss:[bp].GBCDP_move.PDF_x.DWF_frac, 0

	mov	ss:[bp].GBCDP_move.PDF_y.DWF_int.high, 0
	mov	ss:[bp].GBCDP_move.PDF_y.DWF_int.low, 10
	mov	ss:[bp].GBCDP_move.PDF_y.DWF_frac, 0

	mov	ss:[bp].GBCDP_rotation.WWF_int, 30
	mov	ss:[bp].GBCDP_rotation.WWF_frac, 0

	mov	ss:[bp].GBCDP_rotateAnchor, 0

	mov	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_xDegrees.WWF_int, 0
	mov	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_xDegrees.WWF_frac, 0
	mov	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_yDegrees.WWF_int, 0
	mov	ss:[bp].GBCDP_skew.GOASD_degrees.GOSD_yDegrees.WWF_frac, 0
	mov	ss:[bp].GBCDP_skew.GOASD_skewAnchor, 0

	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_xScale.WWF_int, 1
	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_xScale.WWF_frac, 0x2000
	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_yScale.WWF_int, 0
	mov	ss:[bp].GBCDP_scale.GOASD_scale.GOSD_yScale.WWF_frac, 0x8000
	mov	ss:[bp].GBCDP_scale.GOASD_scaleAnchor, 0

	mov	ax, MSG_META_CLIPBOARD_PASTE
	call	ObjCallInstanceNoLock
	add	sp, size GrObjBodyCustomDuplicateParams

	.leave
	ret
GrObjBodyTest3		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/43/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest4	method dynamic GrObjBodyClass, MSG_GB_TEST_4
	.enter

	call	SetNotGradient	

	.leave
	ret
GrObjBodyTest4		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/53/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest5	method dynamic GrObjBodyClass, MSG_GB_TEST_5
	.enter

	call	SetSomeArrowheads

	.leave
	ret
GrObjBodyTest5		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/63/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest6	method dynamic GrObjBodyClass, MSG_GB_TEST_6
	.enter

	call	SetFilledArrowheads
	
	.leave
	ret
GrObjBodyTest6		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest7
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/73/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest7	method dynamic GrObjBodyClass, MSG_GB_TEST_7
	.enter

	call	SetBigArrowheads

	.leave
	ret
GrObjBodyTest7		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/83/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest8	method dynamic GrObjBodyClass, MSG_GB_TEST_8
	.enter

	call	SetNoArrowheads

	.leave
	ret
GrObjBodyTest8		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest9
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/93/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest9	method dynamic GrObjBodyClass, MSG_GB_TEST_9
	uses	ax,cx,dx,bp
	.enter

	call	SetPasteInside


	.leave
	ret
GrObjBodyTest9		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyTest10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/103/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyTest10	method dynamic GrObjBodyClass, MSG_GB_TEST_10
	.enter

	call	DoPasteInside


	.leave
	ret
GrObjBodyTest10		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSomeObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		*ds:si - body

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSomeObjects		proc	far
ForceRef		CreateSomeObjects
	.enter

EC <	call	ECGrObjBodyCheckLMemObject	>

	call	CreateTestObject
	call	CreateTestGroup
	call	CreateTestBitmap
	call	CreateTestText
	call	CreateTestMultText

	.leave
	ret
CreateSomeObjects		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTestObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sample code showing how to create a grobject and 
		add it to the body

PASS:		
		*ds:si - body
		
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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTestObject		proc	far
ForceRef		CreateTestObject
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject	>

	push	si					;body chunk

	;    Have the body create the new grobject in one of 
	;    the blocks that it manages
	;

	mov	cx,segment RectClass
	mov	dx,offset RectClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;

	mov	bx,cx
	mov	si,dx
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.low,150
	mov	ss:[bp].GOID_position.PDF_x.DWF_frac,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.low,100
	mov	ss:[bp].GOID_position.PDF_y.DWF_frac,0
	mov	ss:[bp].GOID_width.WWF_int,190
	mov	ss:[bp].GOID_width.WWF_frac,0
	mov	ss:[bp].GOID_height.WWF_int,40
	mov	ss:[bp].GOID_height.WWF_frac,0
	mov	dx,size GrObjInitializeData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	add	sp,size GrObjInitializeData

	;    At this point do any additional initialization
	;    of grobject. Such as changing the attributes from the
	;    defaults, setting the radius of rounded rect, etc
	
	;code here

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk
	pop	si					;body chunk
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	.leave
	ret
CreateTestObject		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTestGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sample code showing how to create a group, add children
		to it and then add it to the body

PASS:		
		*ds:si - body
		
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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTestGroup		proc	far
ForceRef		CreateTestGroup
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject	>

	push	si					;body chunk

	;    Have the body create the new grobject in one of 
	;    the blocks that it manages
	;

	mov	cx,segment GroupClass
	mov	dx,offset GroupClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;    Allow the group to initialize its instance data. You
	;    don't need to set a position and size. The group will
	;    determine these when you expand it after the children
	;    have been added.
	;

	mov	bx,cx					;group handle
	mov	si,dx					;group chunk
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GROUP_INITIALIZE
	call	ObjMessage

	;    Create each object where you want it in DOCUMENT coordinates
	;    and add it to the group. MSG_GROUP_EXPAND will
	;    expand the group to encompass all the children and
	;    set the children's positions relative to the group
	;

	call	CreateObject1ForGroupTest
	call	CreateObject2ForGroupTest

	;    Expand the group to encompass all the children
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GROUP_EXPAND
	call	ObjMessage

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	mov	cx,bx					;group handle
	mov	dx,si					;group chunk
	pop	si
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	.leave
	ret
CreateTestGroup		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateObject1ForGroupTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sample code showing how to create a grobject and 
		add it to the grobj

PASS:		
		^lbx:si - group
		
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateObject1ForGroupTest		proc	far
ForceRef		CreateObject1ForGroupTest
	uses	ax,cx,dx,bp,di
	.enter

	push	bx,si					;group od

	;    Have the group create the new grobject in one of 
	;    the blocks that its body manages
	;

	mov	cx,segment LineClass
	mov	dx,offset LineClass
	mov	ax,MSG_GROUP_INSTANTIATE_GROBJ
	mov	di,mask MF_CALL
	call	ObjMessage

	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes.
	;    NOTE: Position the grobject where you want it in
	;    DOCUMENT coordinates. When you are done adding 
	;    children the group will expand to encompass all
	;    the children add will adjust the position of the
	;    children to be relative to the group.
	;

	mov	bx,cx
	mov	si,dx
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.low,150
	mov	ss:[bp].GOID_position.PDF_x.DWF_frac,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.low,100
	mov	ss:[bp].GOID_position.PDF_y.DWF_frac,0
	mov	ss:[bp].GOID_width.WWF_int,100
	mov	ss:[bp].GOID_width.WWF_frac,0
	mov	ss:[bp].GOID_height.WWF_int,200
	mov	ss:[bp].GOID_height.WWF_frac,0
	mov	dx,size GrObjInitializeData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	add	sp,size GrObjInitializeData

	;    At this point do any additional initialization
	;    of grobject. Such as changing the attributes from the
	;    defaults, setting the radius of rounded rect, etc
	
	;code here

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk

	;    Add object to group
	;

	pop	bx,si					;group od
	mov	bp,GAGOF_LAST 
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GROUP_ADD_GROBJ
	call	ObjMessage

	.leave
	ret
CreateObject1ForGroupTest		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateObject2ForGroupTest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sample code showing how to create a grobject and 
		add it to the group

PASS:		
		^lbx:si - group
		
RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateObject2ForGroupTest		proc	far
ForceRef		CreateObject2ForGroupTest
	uses	ax,cx,dx,bp,di
	.enter

	push	bx,si					;group od

	;    Have the group create the new grobject in one of 
	;    the blocks that its body manages
	;

	mov	cx,segment EllipseClass
	mov	dx,offset EllipseClass
	mov	di,mask MF_CALL
	mov	ax,MSG_GROUP_INSTANTIATE_GROBJ
	call	ObjMessage

	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;    NOTE: Position the grobject where you want it in
	;    DOCUMENT coordinates. When you are done adding 
	;    children the group will expand to encompass all
	;    the children add will adjust the position of the
	;    children to be relative to the group.
	;

	mov	bx,cx
	mov	si,dx
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.low,100
	mov	ss:[bp].GOID_position.PDF_x.DWF_frac,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.low,150
	mov	ss:[bp].GOID_position.PDF_y.DWF_frac,0
	mov	ss:[bp].GOID_width.WWF_int,250
	mov	ss:[bp].GOID_width.WWF_frac,0
	mov	ss:[bp].GOID_height.WWF_int,70
	mov	ss:[bp].GOID_height.WWF_frac,0
	mov	dx,size GrObjInitializeData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	add	sp,size GrObjInitializeData

	;    At this point do any additional initialization
	;    of grobject. Such as changing the attributes from the
	;    defaults, setting the radius of rounded rect, etc
	
	;code here

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk

	;    Add object to group
	;

	pop	bx,si					;group od
	mov	bp,GAGOF_LAST 
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GROUP_ADD_GROBJ
	call	ObjMessage

	.leave
	ret
CreateObject2ForGroupTest		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTestBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sample code showing how to create a grobject and 
		add it to the body

PASS:		
		*ds:si - body
		
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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTestBitmap		proc	far
ForceRef		CreateTestBitmap
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject	>

	push	si					;body chunk

	;    Have the body create the new grobject in one of 
	;    the blocks that it manages
	;

	mov	cx,segment BitmapGuardianClass
	mov	dx,offset BitmapGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;

	mov	bx,cx
	mov	si,dx
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.low,250
	mov	ss:[bp].GOID_position.PDF_x.DWF_frac,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.low,250
	mov	ss:[bp].GOID_position.PDF_y.DWF_frac,0
	mov	ss:[bp].GOID_width.WWF_int,72
	mov	ss:[bp].GOID_width.WWF_frac,0
	mov	ss:[bp].GOID_height.WWF_int,72
	mov	ss:[bp].GOID_height.WWF_frac,0
	mov	dx,size GrObjInitializeData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	add	sp,size GrObjInitializeData

	;    At this point do any additional initialization
	;    of grobject. Such as changing the attributes from the
	;    defaults, setting the radius of rounded rect, etc
	
	;code here

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk
	pop	si					;body chunk
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	.leave
	ret
CreateTestBitmap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTestText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sample code showing how to create a grobject and 
		add it to the body. This creates a single char/para 
		attr text object.

PASS:		
		*ds:si - body
		
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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTestText		proc	far
ForceRef		CreateTestText
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject	>

	push	si					;body chunk

	;    Have the body create the new grobject in one of 
	;    the blocks that it manages
	;

	mov	cx,segment TextGuardianClass
	mov	dx,offset TextGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;

	mov	bx,cx
	mov	si,dx
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.low,72
	mov	ss:[bp].GOID_position.PDF_x.DWF_frac,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.low,10
	mov	ss:[bp].GOID_position.PDF_y.DWF_frac,0
	mov	ss:[bp].GOID_width.WWF_int,144
	mov	ss:[bp].GOID_width.WWF_frac,0
	mov	ss:[bp].GOID_height.WWF_int,72
	mov	ss:[bp].GOID_height.WWF_frac,0
	mov	dx,size GrObjInitializeData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	add	sp,size GrObjInitializeData

	;    At this point do any additional initialization
	;    of grobject. Such as changing the attributes from the
	;    defaults, setting the radius of rounded rect, etc
	
	;code here

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk
	pop	si					;body chunk
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	.leave
	ret
CreateTestText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTestMultText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sample code showing how to create a grobject and 
		add it to the body. This creates a multi char/para
		attr text object that uses the style arrays.

PASS:		
		*ds:si - body
		
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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateTestMultText		proc	far
ForceRef		CreateTestMultText
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject	>

	push	si					;body chunk

	;    Have the body create the new grobject in one of 
	;    the blocks that it manages
	;

	mov	cx,segment MultTextGuardianClass
	mov	dx,offset MultTextGuardianClass
	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	ObjCallInstanceNoLock

	;    Specify the position and size of the new grobject and
	;    have initialize itself to the default attributes
	;

	mov	bx,cx
	mov	si,dx
	sub	sp,size GrObjInitializeData
	mov	bp,sp
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_x.DWF_int.low,400
	mov	ss:[bp].GOID_position.PDF_x.DWF_frac,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.high,0
	mov	ss:[bp].GOID_position.PDF_y.DWF_int.low,10
	mov	ss:[bp].GOID_position.PDF_y.DWF_frac,0
	mov	ss:[bp].GOID_width.WWF_int,200
	mov	ss:[bp].GOID_width.WWF_frac,0
	mov	ss:[bp].GOID_height.WWF_int,72
	mov	ss:[bp].GOID_height.WWF_frac,0
	mov	dx,size GrObjInitializeData
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GO_INITIALIZE
	call	ObjMessage
	add	sp,size GrObjInitializeData

	;    At this point do any additional initialization
	;    of grobject. Such as changing the attributes from the
	;    defaults, setting the radius of rounded rect, etc
	
	;code here

	;    Notify object that it is complete and ready to go
	;

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	;    Add the new grobject to the body and have it drawn.
	;    If you wish to add many grobjects and draw them all
	;    at once use MSG_GB_ADD_GROBJ instead.
	;

	mov	cx,bx					;new handle
	mov	dx,si					;new chunk
	pop	si					;body chunk
	mov	bp,GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	mov	ax,MSG_GB_ADD_GROBJ_THEN_DRAW
	call	ObjCallInstanceNoLock

	.leave
	ret
CreateTestMultText		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckPositionAndSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		^lcx:dx	- grobject

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckPositionAndSize		proc	far
ForceRef		CheckPositionAndSize
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	mov	bx,cx
	mov	si,dx
	mov	ax,MSG_GO_GET_SIZE
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
checkSize:
ForceRef	checkSize
	sub	sp,size PointDWFixed
	mov	bp,sp
	mov	ax,MSG_GO_GET_POSITION
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	dx, size PointDWFixed
	call	ObjMessage
checkPosition:
ForceRef	checkPosition
	add	sp,size PointDWFixed

	.leave
	ret
CheckPositionAndSize		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPointerTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPointerTool		proc	far
ForceRef		SetPointerTool
	.enter

	mov	cx,segment PointerClass
	mov	dx,offset PointerClass
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	.leave
	ret
SetPointerTool		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRotatePointerTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRotatePointerTool		proc	far
ForceRef		SetRotatePointerTool
	.enter

	mov	cx,segment RotatePointerClass
	mov	dx,offset RotatePointerClass
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	.leave
	ret
SetRotatePointerTool		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetArcTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetArcTool		proc	far
ForceRef		SetArcTool
	.enter

	mov	cx,segment ArcClass
	mov	dx,offset ArcClass
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	.leave
	ret
SetArcTool		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRectTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRectTool		proc	far
ForceRef		SetRectTool
	uses	cx,dx,di,ax
	.enter

	mov	cx,segment RectClass
	mov	dx,offset RectClass
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	.leave
	ret
SetRectTool		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	4/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetActionNotification		proc	far
ForceRef		SetActionNotification
	.enter

	;    For wacky testing of notification have object send
	;    testing message to body to randomly set the default
	;    area attributes after the object has been created.

	mov	ax,MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	bp,MSG_GB_TEST_6
	mov	di,mask MF_RECORD
	mov	bx,segment GrObjClass
	push	si
	mov	si,offset GrObjClass
	call	ObjMessage
	pop	si

	mov	cx,di
	mov	ax,MSG_GH_CLASSED_EVENT_TO_FLOATER
	mov	di,mask MF_FIXUP_DS
	call	GrObjBodyMessageToHead

	.leave
	ret
SetActionNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBitmapGuardianTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBitmapGuardianTool		proc	far
ForceRef		SetBitmapGuardianTool
	.enter

	mov	cx,segment BitmapGuardianClass
	mov	dx,offset BitmapGuardianClass
	mov	bp,VWTAS_INACTIVE
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	.leave
	ret
SetBitmapGuardianTool		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBitmapPencilTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBitmapPencilTool		proc	far
ForceRef		SetBitmapPencilTool
	.enter

	mov	cx,segment BitmapGuardianClass
	mov	dx,offset BitmapGuardianClass
	mov	bp,VWTAS_ACTIVE
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	;    Activate tool in child
	;    Pass class
	;

	push	si
	clr	di					;MessageFlags
	mov	ax,MSG_BG_SET_TOOL_CLASS
	mov	cx,segment PencilToolClass
	mov	dx,offset PencilToolClass
	ornf	di,mask MF_RECORD
	mov	bx,segment BitmapGuardianClass
	mov	si,offset BitmapGuardianClass
	call	ObjMessage
	mov	cx,di					;event handle
	mov	ax,MSG_GH_CLASSED_EVENT_TO_FLOATER
	mov	di,mask MF_FIXUP_DS
	pop	si
	call	GrObjBodyMessageToHead

	.leave
	ret
SetBitmapPencilTool		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBitmapLineTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBitmapLineTool		proc	far
ForceRef		SetBitmapLineTool
	.enter

	mov	cx,segment BitmapGuardianClass
	mov	dx,offset BitmapGuardianClass
	mov	bp,VWTAS_ACTIVE
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	;    Activate tool in child
	;    Pass class
	;

	push	si
	clr	di					;MessageFlags
	mov	ax,MSG_BG_SET_TOOL_CLASS
	mov	cx,segment LineToolClass
	mov	dx,offset LineToolClass
	ornf	di,mask MF_RECORD
	mov	bx,segment BitmapGuardianClass
	mov	si,offset BitmapGuardianClass
	call	ObjMessage
	mov	cx,di					;event handle
	mov	ax,MSG_GH_CLASSED_EVENT_TO_FLOATER
	mov	di,mask MF_FIXUP_DS
	pop	si
	call	GrObjBodyMessageToHead

	.leave
	ret
SetBitmapLineTool		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLineTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLineTool		proc	far
ForceRef		SetLineTool
	.enter

	mov	cx,segment LineClass
	mov	dx,offset LineClass
	mov	di, mask MF_FIXUP_DS
	mov	ax,MSG_GH_SET_CURRENT_TOOL
	call	GrObjBodyMessageToHead

	.leave
	ret
SetLineTool		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRandomAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRandomAttributes		proc	far
ForceRef	SetRandomAttributes
	.enter


	call	TimerGetDateAndTime
	mov	bx,dx
	mov	cl,ds:[bx]
	add	bx,cx
	mov	ch,ds:[bx]
	add	bx,cx
	mov	dl,ds:[bx]
	mov	ax,MSG_GO_SET_AREA_COLOR
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody
	andnf	cl, 0x07	
	mov	ax,MSG_GO_SET_AREA_MASK
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody
	mov	cl, TRUE	
	mov	ax,MSG_GO_SET_TRANSPARENCY
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetRandomAttributes		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLineGreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLineGreen		proc	far
ForceRef	SetLineGreen
	.enter

	mov	cl,0
	mov	ch,255
	mov	dl,0	

	mov	ax,MSG_GO_SET_LINE_COLOR
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetLineGreen		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RotateObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RotateObjects		proc	far
ForceRef	RotateObjects
	.enter

	mov	cx,15
	clr	dx
	clr	bp				;about center
	mov	ax,MSG_GO_ROTATE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
RotateObjects		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetArcStartAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetArcStartAngle		proc	far
ForceRef	SetArcStartAngle
	.enter

	mov	dx,90
	clr	cx
	mov	ax,MSG_ARC_SET_START_ANGLE
	clr	di
	call	SendEncapsulatedArcClassMessageToBody

	.leave
	ret
SetArcStartAngle		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetArcEndAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetArcEndAngle		proc	far
ForceRef	SetArcEndAngle
	.enter

	mov	dx,275
	clr	cx
	mov	ax,MSG_ARC_SET_END_ANGLE
	clr	di
	call	SendEncapsulatedArcClassMessageToBody

	.leave
	ret
SetArcEndAngle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeArcAChord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeArcAChord		proc	far
ForceRef	MakeArcAChord
	.enter

	mov	cx,ACT_CHORD
	mov	ax,MSG_ARC_SET_ARC_CLOSE_TYPE
	clr	di
	call	SendEncapsulatedArcClassMessageToBody

	.leave
	ret
MakeArcAChord		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeArcAPie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeArcAPie		proc	far
ForceRef	MakeArcAPie
	.enter

	mov	cx,ACT_PIE
	mov	ax,MSG_ARC_SET_ARC_CLOSE_TYPE
	clr	di
	call	SendEncapsulatedArcClassMessageToBody

	.leave
	ret
MakeArcAPie		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkewObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SkewObjects		proc	far
ForceRef	SkewObjects
	.enter

	sub	sp,size	GrObjAnchoredSkewData
	mov	bp,sp
	mov	dx,size GrObjAnchoredSkewData
	mov	ss:[bp].GOASD_degrees.GOSD_xDegrees.WWF_int,10
	mov	ss:[bp].GOASD_degrees.GOSD_xDegrees.WWF_frac,0
	mov	ss:[bp].GOASD_degrees.GOSD_yDegrees.WWF_int,20
	mov	ss:[bp].GOASD_degrees.GOSD_yDegrees.WWF_frac,0
	mov	ss:[bp].GOASD_skewAnchor,HANDLE_MOVE
	mov	ax,MSG_GO_SKEW
	mov	di,mask MF_STACK
	call	SendEncapsulatedGrObjClassMessageToBody
	add	sp, size GrObjAnchoredSkewData

	.leave
	ret
SkewObjects		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearObjects		proc	far
ForceRef	ClearObjects
	.enter

	mov	ax,MSG_GO_CLEAR
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
ClearObjects		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetObjectsSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetObjectsSize		proc	far
ForceRef	SetObjectsSize
	uses	bp,di
	.enter

	sub	sp,size PointWWFixed
	mov	bp,sp
	mov	ss:[bp].PF_x.WWF_int,144
	mov	ss:[bp].PF_x.WWF_frac,0x4000
	mov	ss:[bp].PF_y.WWF_int,72
	mov	ss:[bp].PF_y.WWF_frac,0xc000
	mov	ax,MSG_GO_SET_SIZE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody
	add	sp,size PointWWFixed

	.leave
	ret
SetObjectsSize		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetObjectsPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetObjectsPosition		proc	far
ForceRef	SetObjectsPosition
	uses	bp,di
	.enter

	sub	sp,size PointDWFixed
	mov	bp,sp
	mov	ss:[bp].PDF_x.DWF_int.high,0
	mov	ss:[bp].PDF_x.DWF_int.low,144
	mov	ss:[bp].PDF_x.DWF_frac,0x4000
	mov	ss:[bp].PDF_y.DWF_int.high,0
	mov	ss:[bp].PDF_y.DWF_int.low,72
	mov	ss:[bp].PDF_y.DWF_frac,0xc000
	mov	ax,MSG_GO_SET_POSITION
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody
	add	sp,size PointDWFixed

	.leave
	ret
SetObjectsPosition		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetResizeClearMoveLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetResizeClearMoveLocks		proc	far
ForceRef	SetResizeClearMoveLocks
	uses	cx,dx,di
	.enter

	mov	dx, mask GOL_MOVE
	mov	cx, mask GOL_RESIZE
	mov	ax,MSG_GO_CHANGE_LOCKS
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetResizeClearMoveLocks		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMoveClearResizeLocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetMoveClearResizeLocks		proc	far
ForceRef	SetMoveClearResizeLocks
	uses	cx,dx,di
	.enter

	mov	cx, mask GOL_MOVE
	mov	dx, mask GOL_RESIZE
	mov	ax,MSG_GO_CHANGE_LOCKS
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetMoveClearResizeLocks		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NudgeObjects
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NudgeObjects		proc	far
ForceRef	NudgeObjects
	.enter

	mov	cx,1
	mov	dx,1
	mov	ax,MSG_GO_NUDGE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
NudgeObjects		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SuspendActionNotification		proc	far
ForceRef	SuspendActionNotification
	uses	ax,di
	.enter

	mov	ax,MSG_GO_SUSPEND_ACTION_NOTIFICATION
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SuspendActionNotification		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UnsuspendActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UnsuspendActionNotification		proc	far
ForceRef	UnsuspendActionNotification
	uses	ax,di
	.enter

	mov	ax,MSG_GO_UNSUSPEND_ACTION_NOTIFICATION
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
UnsuspendActionNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearActionNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearActionNotification		proc	far
ForceRef	ClearActionNotification
	uses	ax,di,cx
	.enter

	clr	cx
	mov	ax,MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
ClearActionNotification		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendEcapsulatedGrObjClassMessageToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		ds:si - body
		ax - message
		cx,dx,bp - other data
		di - O or MF_STACK

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendEncapsulatedGrObjClassMessageToBody		proc	far
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	push	si
	mov	bx,segment GrObjClass
	mov	si,offset GrObjClass
	ornf	di,mask MF_RECORD
	call	ObjMessage
	mov	cx,di
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	mov	dx,TO_TARGET
	pop	si
	call	ObjCallInstanceNoLock

	.leave
	ret
SendEncapsulatedGrObjClassMessageToBody		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendEcapsulatedArcClassMessageToBody
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		ds:si - body
		ax - message
		cx,dx,bp - other data
		di - O or MF_STACK

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendEncapsulatedArcClassMessageToBody		proc	far
	uses	ax,bx,cx,dx,bp,di,si
	.enter

	push	si
	mov	bx,segment ArcClass
	mov	si,offset ArcClass
	ornf	di,mask MF_RECORD
	call	ObjMessage
	mov	cx,di
	mov	ax,MSG_META_SEND_CLASSED_EVENT
	mov	dx,TO_TARGET
	pop	si
	call	ObjCallInstanceNoLock

	.leave
	ret
SendEncapsulatedArcClassMessageToBody		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertDeleteSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertDeleteSpace		proc	far
ForceRef	InsertDeleteSpace
	uses	ax,bp
	.enter

	sub	sp,size InsertDeleteSpaceParams
	mov	bp,sp
	mov	ss:[bp].IDSP_space.PDF_x.DWF_int.high,0xffff
	mov	ss:[bp].IDSP_space.PDF_x.DWF_int.low,0xffa0
	mov	ss:[bp].IDSP_space.PDF_x.DWF_frac,0
	mov	ss:[bp].IDSP_space.PDF_y.DWF_int.high,0xffff
	mov	ss:[bp].IDSP_space.PDF_y.DWF_int.low,0xffc0
	mov	ss:[bp].IDSP_space.PDF_y.DWF_frac,0
	mov	ss:[bp].IDSP_position.PDF_x.DWF_int.high,0
	mov	ss:[bp].IDSP_position.PDF_y.DWF_int.high,0
	mov	ss:[bp].IDSP_position.PDF_x.DWF_int.low,72
	mov	ss:[bp].IDSP_position.PDF_y.DWF_int.low,100
	mov	ss:[bp].IDSP_position.PDF_x.DWF_frac,0
	mov	ss:[bp].IDSP_position.PDF_y.DWF_frac,0
	mov	ss:[bp].IDSP_type, 0xffff			;set em all
	mov	ax,MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
	call	ObjCallInstanceNoLock
	add	sp,size InsertDeleteSpaceParams

	.leave
	ret
InsertDeleteSpace		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeInstructionObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeInstructionObject		proc	far
ForceRef	MakeInstructionObject
	.enter

	mov	ax,MSG_GO_MAKE_INSTRUCTION
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
MakeInstructionObject		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeNotInstructionObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeNotInstructionObject		proc	far
ForceRef	MakeNotInstructionObject
	.enter

	mov	ax,MSG_GO_MAKE_NOT_INSTRUCTION
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
MakeNotInstructionObject		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWrapTextType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetWrapTextType		proc	far
ForceRef	SetWrapTextType
	.enter

	mov	cl,GOWTT_WRAP_AROUND_RECT
	mov	ax,MSG_GO_SET_WRAP_TEXT_TYPE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetWrapTextType		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSomeBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSomeBits		proc	far
ForceRef	SetSomeBits
	.enter

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_PASTE_INSIDE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_INSERT_DELETE_MOVE_ALLOWED
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,FALSE
	mov	ax,MSG_GO_SET_INSERT_DELETE_RESIZE_ALLOWED
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_INSERT_DELETE_DELETE_ALLOWED
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetSomeBits		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeInstructionsSelectableAndEditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/93/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeInstructionsSelectableAndEditable proc far
ForceRef MakeInstructionsSelectableAndEditable
	uses	ax,cx,dx,bp
	.enter

	mov	ax,MSG_GB_MAKE_INSTRUCTIONS_SELECTABLE_AND_EDITABLE
	call	ObjCallInstanceNoLock

	.leave
	ret
MakeInstructionsSelectableAndEditable		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeInstructionsUnselectableAndUneditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/93/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeInstructionsUnselectableAndUneditable proc far
ForceRef MakeInstructionsUnselectableAndUneditable
	uses	ax,cx,dx,bp
	.enter

	mov	ax,MSG_GB_MAKE_INSTRUCTIONS_UNSELECTABLE_AND_UNEDITABLE
	call	ObjCallInstanceNoLock

	.leave
	ret
MakeInstructionsUnselectableAndUneditable		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGrObjDrawFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		

	
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
	srs	2/93/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGrObjDrawFlags proc far
ForceRef	SetGrObjDrawFlags
	.enter

	mov	cx,mask GODF_DRAW_WRAP_TEXT_AROUND_ONLY
	mov	dx,mask GODF_DRAW_OBJECTS_ONLY
	mov	ax,MSG_GB_SET_GROBJ_DRAW_FLAGS
	call	ObjCallInstanceNoLock

	.leave
	ret
SetGrObjDrawFlags		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearInstructions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearInstructions		proc	far
ForceRef	ClearInstructions
	.enter

	mov	ax,MSG_GB_DELETE_INSTRUCTIONS
	call	ObjCallInstanceNoLock

	.leave
	ret
ClearInstructions		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBasicGradientInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBasicGradientInfo		proc	far
ForceRef	SetBasicGradientInfo
	uses	ax,cx,dx,di
	.enter


	mov	ax,MSG_META_SUSPEND
	call	ObjCallInstanceNoLock

	mov	cl,GOAAET_GRADIENT
	mov	ax,MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,GOGT_LEFT_TO_RIGHT
	mov	ax,MSG_GO_SET_GRADIENT_TYPE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cx,40
	mov	ax,MSG_GO_SET_NUMBER_OF_GRADIENT_INTERVALS
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	ax,MSG_META_UNSUSPEND
	call	ObjCallInstanceNoLock

	.leave
	ret
SetBasicGradientInfo		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGradientTopToBottom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGradientTopToBottom		proc	far
ForceRef	SetGradientTopToBottom
	uses	ax,cx,di
	.enter

	mov	cl,GOGT_TOP_TO_BOTTOM
	mov	ax,MSG_GO_SET_GRADIENT_TYPE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetGradientTopToBottom		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGradientIntervals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGradientIntervals		proc	far
ForceRef	SetGradientIntervals
	uses	ax,cx,dx,di
	.enter

	mov	cx,100
	mov	ax,MSG_GO_SET_NUMBER_OF_GRADIENT_INTERVALS
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetGradientIntervals		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNotGradient
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNotGradient		proc	far
ForceRef	SetNotGradient
	uses	ax,cx,di
	.enter

	mov	cl,GOAAET_BASE
	mov	ax,MSG_GO_SET_AREA_ATTR_ELEMENT_TYPE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetNotGradient		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSomeArrowheads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSomeArrowheads		proc	far
ForceRef	SetSomeArrowheads
	uses	ax,cx,di
	.enter

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_ARROWHEAD_ON_END
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,FALSE
	mov	ax,MSG_GO_SET_ARROWHEAD_FILLED
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetSomeArrowheads		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFilledArrowheads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFilledArrowheads		proc	far
ForceRef	SetFilledArrowheads
	uses	ax,cx,di
	.enter

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_ARROWHEAD_ON_END
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_ARROWHEAD_FILLED
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetFilledArrowheads		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetBigArrowheads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetBigArrowheads		proc	far
ForceRef	SetBigArrowheads
	uses	ax,cx,di
	.enter

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_ARROWHEAD_ON_END
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,25
	mov	ax,MSG_GO_SET_ARROWHEAD_ANGLE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	mov	cl,25
	mov	ax,MSG_GO_SET_ARROWHEAD_LENGTH
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetBigArrowheads		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNoArrowheads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNoArrowheads		proc	far
ForceRef	SetNoArrowheads
	uses	ax,cx,di
	.enter

	mov	cl,FALSE
	mov	ax,MSG_GO_SET_ARROWHEAD_ON_END
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetNoArrowheads		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPasteInside		proc	far
ForceRef	SetPasteInside
	.enter

	mov	cl,TRUE
	mov	ax,MSG_GO_SET_PASTE_INSIDE
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
SetPasteInside		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeAttrsDefault
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeAttrsDefault		proc	far
ForceRef	MakeAttrsDefault
	.enter

	mov	ax,MSG_GO_MAKE_ATTRS_DEFAULT
	clr	di
	call	SendEncapsulatedGrObjClassMessageToBody

	.leave
	ret
MakeAttrsDefault		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPasteInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoPasteInside		proc	far
ForceRef	DoPasteInside
	.enter

	mov	ax,MSG_GB_PASTE_INSIDE
	call	ObjCallInstanceNoLock

	.leave
	ret
DoPasteInside		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Hide
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Hide		proc	far
ForceRef	Hide
	.enter

	mov	ax,MSG_GB_HIDE_UNSELECTED_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
Hide		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Show
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

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
	srs	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Show		proc	far
ForceRef	Show
	.enter

	mov	ax,MSG_GB_SHOW_ALL_GROBJS
	call	ObjCallInstanceNoLock

	.leave
	ret
Show		endp


BodyTestCode	ends

		
