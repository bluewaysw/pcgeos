COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ccompComposite.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

DESCRIPTION:
	

	$Id: ccompComposite.asm,v 1.1 97/04/04 17:47:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a routine for each child.

CALLED BY:

PASS:		bx - routine to call (must be a FAR PROC), or one of
			the ObjCompCallTypes

		ax,cx,dx,bp - data for each child
		*ds:si - ChartComp object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/13/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompProcessChildren	proc near	
	class	ChartCompClass
	uses	si
	.enter
	clr	di
	push	di, di			; First child
	mov	di, offset COI_link
	push	di
	clr	di
	cmp	bx, ObjCompCallType
	jbe	gotSeg
	mov	di, SEGMENT_CS
gotSeg:
	push	di			; code segment
	push	bx			; routine to call
	mov	di, offset CCI_comp
	clr	bx			; master offset
	call	ObjCompProcessChildren
	.leave
	ret
ChartCompProcessChildren	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompCallChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Call the kids.

PASS:		*ds:si	= ChartCompClass object
		es	= Segment of ChartCompClass.
		ax 	= message number
		cx, dx, bp = message data

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/13/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompCallChildren	proc	far

	uses	bx, di
	class	ChartCompClass
	.enter
	
	clr	bx
	push	bx, bx			; First child
	mov	di, offset COI_link
	push	di
	push	bx			; code segment
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	push	di
	mov	di, offset CCI_comp
	call	ObjCompProcessChildren
	.leave
	ret
ChartCompCallChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Add a child to this object

PASS:		*ds:si	= ChartCompClass object
		ds:di	= ChartCompClass instance data
		es	= Segment of ChartCompClass.

		*ds:dx	= child to add
		bp - CompChildFlags

RETURN:		 nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
	Called as both a METHOD and a PROCEDURE

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompAddChild	method		ChartCompClass, 
					MSG_CHART_COMP_ADD_CHILD
	uses	ax,bx,cx,di,bp
	.enter
	mov	ax, offset COI_link
	clr	bx
	mov	di, offset CCI_comp
	mov	cx, ds:[LMBH_handle]
	call	ObjCompAddChild	
	.leave
	ret
ChartCompAddChild	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompRemoveChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartCompClass object
		ds:di	= ChartCompClass instance data
		es	= Segment of ChartCompClass.
		^lcx:dx = child to remove

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompRemoveChild	method	dynamic	ChartCompClass, 
					MSG_CHART_COMP_REMOVE_CHILD
	uses	ax, bp
	.enter
	mov	ax, offset COI_link
	clr	bx
	mov	bp, mask CCF_MARK_DIRTY
	mov	di, offset CCI_comp
	call	ObjCompRemoveChild
	.leave
	ret
ChartCompRemoveChild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompDestroyChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a child from the tree and kill it mercilessly.

CALLED BY:

PASS:		*ds:si - ChartComp object
		cx - number of child to destroy

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompDestroyChild	proc far	
	uses	ax,bx,cx,dx,di,si,bp

	class	ChartCompClass

	.enter

	clr	dx, bx
	xchg	cx, dx
	mov	ax, offset COI_link
	mov	di, offset CCI_comp
	call	ObjCompFindChild
	jc	done

	; Detach it from the tree

	mov	si, dx
	mov	ax, MSG_CHART_OBJECT_REMOVE
	call	ObjCallInstanceNoLock

	; Kill it!

	mov	ax, MSG_META_OBJ_FREE	
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
ChartCompDestroyChild	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompSendClassedEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a classed event to any children that are
		selected.  Call the superclass when done.

CALLED BY:	MSG_META_SEND_CLASSED_EVENT

PASS:		*ds:si - composite object
		cx - event handle
		dx - travel option

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompSendClassedEvent	method	dynamic ChartCompClass, 
					MSG_META_SEND_CLASSED_EVENT
	.enter
	mov	bx, offset ChartCompSendClassedEventCB
	call	ChartCompProcessChildren	
	.leave
	mov	di, offset ChartCompClass
	GOTO	ObjCallSuperNoLock
ChartCompSendClassedEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompSendClassedEventCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Duplicate and send the classed event to this child

CALLED BY:	ChartCompSendClassedEvent, via ObjCompProcessChildren

PASS:		*ds:si - child to send to
		ax - MSG_META_SEND_CLASSED_EVENT
		cx - event handle
		dx - travel option

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompSendClassedEventCB	proc	far
	class	ChartObjectClass

	uses	ax, cx, dx, bp

	.enter
	
	push	ax
	mov	bx, cx
	call	ObjDuplicateMessage
	mov_tr	cx, ax			; duplicated message
	pop	ax
	call	ObjCallInstanceNoLock
	clc
	.leave
	ret
ChartCompSendClassedEventCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompCreateChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a chart object and add it as this comp's LAST
		child. 

CALLED BY:	UTILITY

PASS:		*ds:si - chart comp
		di - offset of class structure

RETURN:		*ds:dx - new child

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompCreateChild	proc far

	uses	es,bx,bp

	.enter

	push	si
	segmov	es, <segment ChartClassStructures> , si
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate
	mov	dx, si

	pop	si
	mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
	call	ChartCompAddChild

	.leave
	ret
ChartCompCreateChild	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompFindChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end routine for ObjCompFindChild

CALLED BY:	UTILITY (LegendSelect)

PASS:		*ds:si - chart comp
		cx:dx - optr of child
		-- or --
		cx = 0
		dx = # of child to find


RETURN:		if FOUND
			carry clear
			*ds:cx - child
			bp - child position
		else
			carry SET

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompFindChild	proc far

	class	ChartCompClass

	uses	ax,bx,dx,di

	.enter

	mov	ax, offset COI_link
	mov	di, offset CCI_comp
	clr	bx
	call	ObjCompFindChild
	mov	cx, dx

	.leave
	ret
ChartCompFindChild	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompGetTopGrObjPositionCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call each child and update the current max

CALLED BY:	ChartCompGetTopGrObjPosition via ObjCompProcessChildren

PASS:		*ds:si - child
		ax - message
		cx - current top

RETURN:		cx - max top of all kids
		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompGetTopGrObjPositionCB	proc far
		.enter
		mov	bx, cx
		push	ax
		call	ObjCallInstanceNoLock
		pop	ax

		cmp	cx, bx
		jae	done
		mov	cx, bx		; update top
done:
		clc
		.leave
		ret
ChartCompGetTopGrObjPositionCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompGetTopGrObjPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the top positions of all the kids

PASS:		*ds:si	- ChartCompClass object
		ds:di	- ChartCompClass instance data
		es	- segment of ChartCompClass

RETURN:		cx	- top position

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompGetTopGrObjPosition	method	dynamic	ChartCompClass, 
					MSG_CHART_OBJECT_GET_TOP_GROBJ_POSITION

		clr	cx
		mov	bx, offset ChartCompGetTopGrObjPositionCB
		call	ChartCompProcessChildren

		jcxz	gotoSuper
		ret

gotoSuper:

		mov	di, offset ChartCompClass
		GOTO	ObjCallSuperNoLock
ChartCompGetTopGrObjPosition	endm

