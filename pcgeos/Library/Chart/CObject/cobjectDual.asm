COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectDual.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/21/92   	Initial version.

DESCRIPTION:
	

	$Id: cobjectDual.asm,v 1.1 97/04/04 17:46:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualClearAllGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Free the 2 grobjes

PASS:		*ds:si	= ChartObjectDualClass object
		ds:di	= ChartObjectDualClass instance data
		es	= Segment of ChartObjectDualClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectDualClearAllGrObjes	method	dynamic	ChartObjectDualClass, 
					MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	uses	ax,cx
	.enter

EC <	tst	ds:[di].COI_grobj.chunk				>
EC <	ERROR_NZ GROBJ_FIELD_FOR_MULTIPLE_OBJECT_NOT_NULL	>

	mov	cx, CODT_FIRST_GROBJ
	call	ChartObjectDualClearGrObj

	mov	cx, CODT_SECOND_GROBJ
	call	ChartObjectDualClearGrObj

	.leave
	mov	di, offset ChartObjectDualClass
	GOTO	ObjCallSuperNoLock
ChartObjectDualClearAllGrObjes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualClearGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free one of the grobjes

CALLED BY:

PASS:		cx - ChartObjectDualType
		*ds:si - ChartObjectDual object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectDualClearGrObj	proc far
	.enter
	call	ChartObjectDualGetGrObj
	call	ChartObjectClearAllGrObjes
	call	ChartObjectDualSetGrObj
	.leave
	ret
ChartObjectDualClearGrObj	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualGetGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get one of the 2 grobj's into the "grobj" field

CALLED BY:

PASS:		cx - ChartObjectDualType
		*ds:si - ChartObjectDual object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectDualGetGrObj	proc far
	uses	di, bx, ax
	class	ChartObjectDualClass
	.enter
	mov	di, ds:[si]
	mov	bx, cx
	add	bx, di			; ds:bx - offset to grobj
	movdw	ds:[di].COI_grobj, ds:[bx], ax
	.leave
	ret
ChartObjectDualGetGrObj	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualSetGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set one of the 2 grobj's from the "grobj" field back
		to 

CALLED BY:

PASS:		cx - ChartObjectDualType
		*ds:si - ChartObjectDual object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectDualSetGrObj	proc far
	uses	di, bx, ax
	class	ChartObjectDualClass
	.enter

	mov	di, ds:[si]
	mov	bx, cx
	add	bx, di
	movdw	ds:[bx], ds:[di].COI_grobj, ax
	clrdw	ds:[di].COI_grobj
	.leave
	ret
ChartObjectDualSetGrObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualFindGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the OD of the PICTURE grobj

PASS:		*ds:si	= ChartObjectDualClass object
		ds:di	= ChartObjectDualClass instance data
		es	= segment of ChartObjectDualClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectDualFindGrObj	method	dynamic	ChartObjectDualClass, 
					MSG_CHART_OBJECT_FIND_GROBJ
	.enter
	movOD	cxdx, ds:[di].CODI_grobj1
	.leave
	ret
ChartObjectDualFindGrObj	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualSendToGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartObjectDualClass object
		ds:di	- ChartObjectDualClass instance data
		es	- segment of ChartObjectDualClass structure

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectDualSendToGrObj	method	dynamic	ChartObjectDualClass, 
					MSG_CHART_OBJECT_SEND_TO_GROBJ
	uses	ax,cx,dx,bp
	.enter

	mov_tr	ax, cx
	push	si
	movOD	bxsi, ds:[di].CODI_grobj1
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	DerefChartObject ds, si, di
	movOD	bxsi, ds:[di].CODI_grobj2
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
ChartObjectDualSendToGrObj	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualGetGrObjText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the OD of the GrObj text object for this chart
		object. 

PASS:		*ds:si	- ChartObjectDualClass object
		ds:di	- ChartObjectDualClass instance data
		es	- segment of ChartObjectDualClass structure

RETURN:		^lcx:dx - VisText object associated with this chart object.

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/20/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectDualGetGrObjText	method	dynamic	ChartObjectDualClass, 
					MSG_CHART_OBJECT_GET_GROBJ_TEXT
		uses	ax,bp
		.enter

		mov	bx, ds:[di].CODI_grobj2.handle
		tst	bx
		jz	callSuper

		mov	si, ds:[di].CODI_grobj2.chunk	
		mov	ax, MSG_GOVG_GET_VIS_WARD_OD
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret

callSuper:
		mov	di, offset ChartObjectDualClass
		call	ObjCallSuperNoLock
		jmp	done

ChartObjectDualGetGrObjText	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectDualGetTopGrObjPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	return the position of the text object, if available.

PASS:		*ds:si	- ChartObjectDualClass object
		ds:di	- ChartObjectDualClass instance data
		es	- segment of ChartObjectDualClass structure

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectDualGetTopGrObjPosition	method	dynamic	ChartObjectDualClass, 
					MSG_CHART_OBJECT_GET_TOP_GROBJ_POSITION
		.enter

		movdw	cxdx, ds:[di].CODI_grobj2
		tst	cx
		jnz	gotOD
		movdw	cxdx, ds:[di].CODI_grobj1
		jcxz	done
gotOD:
		mov	ax, MSG_GB_FIND_GROBJ
		call	UtilCallChartBody
EC <		ERROR_NC OBJECT_NOT_FOUND 				>

done:		
		.leave
		ret
ChartObjectDualGetTopGrObjPosition	endm

