COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/13/91		Initial Revision 

DESCRIPTION:
	Positioning code for ChartComp

	$Id: ccompPosition.asm,v 1.1 97/04/04 17:48:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set position of myself and children

CALLED BY:	via MSG_CHART_OBJECT_BOUNDS_SET
PASS:		*ds:si	= Instance ptr
		*ds:di	= Instance ptr

		cx, dx - position

RETURN:		nothing

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/13/91	Initial Revision  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompSetPosition	method dynamic	ChartCompClass,
			MSG_CHART_OBJECT_SET_POSITION

	mov	di, offset ChartCompClass
	call	ObjCallSuperNoLock
	mov	di, ds:[si]

	FALL_THRU	ChartCompPositionChildren
ChartCompSetPosition	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompPositionChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Position the children of this composite based on their
		sizes.

PASS:		*ds:si	= ChartCompClass object
		ds:di	= ChartCompClass instance data
		es	= Segment of ChartCompClass.

		cx, dx 	= position of chart comp

RETURN:		nothing 

DESTROYED:	si,di,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompPositionChildren	proc	far
	uses	ax, cx
locals 	local ChartCompPositionVars
	class	ChartCompClass
	.enter

	; Get comp type

	mov	al, ds:[di].CCI_compType
	mov	locals.CCPV_compType, al

	; size 

	movP	locals.CCPV_compSize, ds:[di].COI_size, ax

	; chunk handle
	
	mov	locals.CCPV_compChunkHandle, si

	; position

	movP	locals.CCPV_relPos, ds:[di].COI_position, ax
	mov	ax, ds:[di].CCI_margin.R_left
	add	locals.CCPV_relPos.P_x, ax
	mov	ax, ds:[di].CCI_margin.R_top
	add	locals.CCPV_relPos.P_y, ax

	; call children

	mov	bx, offset ChartCompPositionChildrenCB
	call	ChartCompProcessChildren	
	.leave
	ret
ChartCompPositionChildren	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompPositionChildrenCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to position the kids

CALLED BY:

PASS:		*ds:si 	- Child object
		*es:di 	- Parent ChartComp
		ss:bp 	- ChartCompPositionVars

RETURN:		nothing -- carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompPositionChildrenCB	proc far
	uses	ax,cx,dx
locals 	local ChartCompPositionVars 
	class	ChartCompClass
	.enter inherit

	; Get child's size and geometry flags.  Ignore
	; object-orientation for speed purposes.

	mov	di, ds:[si]
	mov	al, ds:[di].COI_geoFlags
	movP	cxdx, ds:[di].COI_size
	push	cx, dx

	test	al, mask COGF_CENTER_HORIZONTALLY
	jnz	centerHorizontally

	test	al, mask COGF_CENTER_VERTICALLY
	jz	noCenter

	; Center child vertically (position = (compHeight - childHeight)/2

	sub	dx, locals.CCPV_compSize.P_y
	neg	dx
	shr	dx, 1
	add	dx, locals.CCPV_relPos.P_y
	mov	cx, locals.CCPV_relPos.P_x
	jmp	gotPosition


centerHorizontally:
	sub	cx, locals.CCPV_compSize.P_x
	neg	cx
	shr	cx, 1
	add	cx, locals.CCPV_relPos.P_x
	mov	dx, locals.CCPV_relPos.P_y
	jmp	gotPosition

noCenter:
	movP	cxdx, locals.CCPV_relPos

gotPosition:
	mov	ax, MSG_CHART_OBJECT_SET_POSITION
	call	ObjCallInstanceNoLock

	pop	cx, dx
	; Now, update the position for the next child

	; If overlapping, then all kids have same position

	cmp	locals.CCPV_compType, CCT_OVERLAP
	je	done

	cmp	locals.CCPV_compType, CCT_VERTICAL
	jne	horizontal

	; Vertical, so add y-amount
	add	locals.CCPV_relPos.P_y, dx
	jmp	done

horizontal:
	add	locals.CCPV_relPos.P_x, cx
done:
	clc
	.leave
	ret
ChartCompPositionChildrenCB	endp

