COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cgroupOrder.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/93   	Initial version.

DESCRIPTION:
	

	$Id: cgroupOrder.asm,v 1.1 97/04/04 17:45:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupGetTopGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the draw list position of the highest GrObject
		associated with this chart.

CALLED BY:	ChartGroupRealize

PASS:		nothing 

RETURN:		nothing - creates vardata with draw list position

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupGetTopGrObj	proc near
		uses	ax,cx,dx,bp
		.enter

		mov	ax, MSG_CHART_OBJECT_GET_TOP_GROBJ_POSITION
		call	ObjCallInstanceNoLock

		push	cx		; position
		mov	cx, size word
		mov	ax, TEMP_CHART_GROUP_TOP_GROBJ
		call	ObjVarAddData
		pop	ds:[bx]

		.leave
		ret
ChartGroupGetTopGrObj	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupUpdateTopGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Update the "top grobj" information, and return the
		position of the new object

PASS:		*ds:si	- ChartGroupClass object
		ds:di	- ChartGroupClass instance data
		es	- segment of ChartGroupClass

RETURN:		bp - new draw list position

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupUpdateTopGrObj	method	dynamic	ChartGroupClass, 
					MSG_CHART_GROUP_UPDATE_TOP_GROBJ
		uses	cx, dx
		.enter

		mov	ax, TEMP_CHART_GROUP_TOP_GROBJ
		call	ObjVarFindData
		jnc	atEnd

		mov	bp, ds:[bx]
		inc	bp
		mov	ds:[bx], bp
		ornf	bp, mask GOBAGOF_DRAW_LIST_POSITION
done:
		.leave
		ret
atEnd:
		mov	bp, GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
		jmp	done
ChartGroupUpdateTopGrObj	endm




