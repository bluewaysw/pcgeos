COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgrobjRect.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 2/92   	Initial version.

DESCRIPTION:
	

	$Id: cgrobjRect.asm,v 1.1 97/04/04 17:48:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartRectInvertHandles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartRectClass object
		ds:di	= ChartRectClass instance data
		es	= Segment of ChartRectClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartRectInvertHandles	method	dynamic	ChartRectClass, 
					MSG_GO_INVERT_HANDLES
	uses	ax,cx
	.enter

	mov	di,dx					;gstate	
EC <	call	ECCheckGStateHandle			>

	mov	al, MM_INVERT
	call	GrSetMixMode

	mov	al,SDM_100				
	call	GrSetAreaMask		

	call	GrObjGetCurrentHandleSize		 ; bx <-
							 ; handle size

	mov	cl, HANDLE_MOVE
	call	GrObjDrawOneHandle
	.leave
	ret
ChartRectInvertHandles	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartRectGetClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartRectClass object
		ds:di	- ChartRectClass instance data
		es	- segment of ChartRectClass

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

ChartRectGetClass	method	dynamic	ChartRectClass, 
					MSG_META_GET_CLASS
	mov	cx, segment RectClass
	mov	dx, offset RectClass
	ret
ChartRectGetClass	endm

