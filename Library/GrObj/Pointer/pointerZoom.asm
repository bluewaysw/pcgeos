COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	GrObj
MODULE:		Pointer
FILE:		zoom.asm

AUTHOR:		Steve Scholl, Sep 15, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	9/15/92		Initial revision


DESCRIPTION:
		

	$Id: pointerZoom.asm,v 1.1 97/04/04 18:08:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjClassStructures	segment resource


	;Define the class record

ZoomPointerClass

GrObjClassStructures	ends


GrObjRequiredExtInteractive2Code	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZoomActivateCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts pointer in it's standard mode for zooming

PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ZoomClass

		cl - ActivateCreateFlags

RETURN:		
		nothing

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ZoomActivateCreate	method dynamic ZoomPointerClass, MSG_GO_ACTIVATE_CREATE
	uses	cx,dx,bp
	.enter 

	clr	ds:[di].GOI_actionModes

	;    If ACF_NOTIFY set then send method to all objects on
	;    the selection list notifying them of activation. 
	;

	test	cl, mask ACF_NOTIFY
	jz	done
	mov	ax,MSG_GO_SEND_ANOTHER_TOOL_ACTIVATED
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

ZoomActivateCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZoomStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle start select
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ZoomClass
		ss:bp - GrObjMouseData

RETURN:		
		ax - MouseReturnFlags
		if MRF_SET_POINTER_IMAGE
			cx:dx - optr of pointer image
		else
			cx,dx - DESTROYED

	
DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ZoomStartSelect	method dynamic ZoomPointerClass, MSG_GO_LARGE_START_SELECT
	.enter


	mov	ax,MSG_GB_ZOOM_OUT_ABOUT_POINT
	test	ss:[bp].GOMD_goFA, mask GOFA_CONSTRAIN
	jnz	sendToBody
	mov	ax,MSG_GB_ZOOM_IN_ABOUT_POINT
sendToBody:
	mov	dx,size PointDWFixed
	mov	di,mask MF_STACK or mask MF_FIXUP_DS
	call	GrObjMessageToBody

	mov	ax,mask MRF_PROCESSED

	.leave
	ret

ZoomStartSelect		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZoomGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Return OD of pointer image	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of ZoomClass

		ss:bp - PointDWFixed

RETURN:		
		
		ax -MRF_SET_POINTER_IMAGE 
			cx:dx - od of pointer image

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ZoomGetPointerImage method dynamic ZoomPointerClass, MSG_GO_GET_POINTER_IMAGE
	.enter

	mov	ax,mask MRF_SET_POINTER_IMAGE
	mov	cx,handle ptrZoom
	mov	dx,offset ptrZoom

	.leave
	ret

ZoomGetPointerImage		endm





GrObjRequiredExtInteractive2Code	ends



