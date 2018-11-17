COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		ccompGeometry.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/4/91		Initial Revision

DESCRIPTION:

	$Id: ccompGeometry.asm,v 1.1 97/04/04 17:47:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the sizes of all children

CALLED BY:	via MSG_CHART_OBJECT_RECALC_SIZE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	= Suggested width
		dx	= Suggested height

RETURN:		cx	= Desired width
		dx	= Desired height

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	Save size
	Foreach child
		if child is EXPAND
			skip child until later
		ELSE
			Get child's size, add to running total

	Set sizes of EXPAND children

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompRecalcSize	method dynamic	ChartCompClass,
			MSG_CHART_OBJECT_RECALC_SIZE

locals	local	RecalcSizeLocalVars
	.enter

	; subtract off margin before calling kids

	call	SubtractMarginFromCXDX

	movP	locals.RSLV_originalSize, cxdx
	clrdw	locals.RSLV_childSizes
	clr	locals.RSLV_expand

	mov	bl, ds:[di].CCI_compType
	mov	locals.RSLV_compType, bl


	; If comp is overlapping, then set initial child size to the
	; passed (suggested) size.

	cmp	bl, CCT_OVERLAP
	jne	gotChildSizes
	movP	locals.RSLV_childSizes, locals.RSLV_originalSize, bx

gotChildSizes:

	mov	bx, offset ChartCompRecalcSizeCB
	call	ChartCompProcessChildren

	; If there was an expandable child, set its size with
	; whatever's left over

	push	si			; comp's chunk handle
	mov	si, locals.RSLV_expand
	tst	si
	jz	afterChildren

	; If the final size is less than the desired size in either X
	; or Y, then set it to the desired size

	movP	cxdx, locals.RSLV_originalSize
	cmp	locals.RSLV_compType, CCT_VERTICAL
	je	subtractChildHeight
	sub	cx, locals.RSLV_childSizes.P_x
	jmp	setExpandChild

subtractChildHeight:
	sub	dx, locals.RSLV_childSizes.P_y

setExpandChild:	
	;
	; CX, DX is the amount of size left over -- make sure the
	; amount is nonnegative, and pass it to the "expand-to-fit"
	; child. 
	;

	Max	cx, 0
	Max	dx, 0

	call	ObjCallInstanceNoLock	; call "expand-to-fit" child
	call	AddChildSize		; Add this child to the final
					; size. 

afterChildren:
	pop	si		; comp's chunk handle

	;
	; Determine how large to set this composite.
	;

	DerefChartObject ds, si, di
	test	ds:[di].CCI_compFlags, mask CCF_NO_LARGER_THAN_CHILDREN
	jnz	noLargerThanKids

	;
	; Set the size to the maximum of the desired size and the
	; child sizes.

	movP	cxdx, locals.RSLV_originalSize
	Max	cx, locals.RSLV_childSizes.P_x
	Max	dx, locals.RSLV_childSizes.P_y
	jmp	addMargin

noLargerThanKids:
	movP	cxdx, locals.RSLV_childSizes

addMargin:
	; Add margin amount

	call	AddMarginToCXDX

	; cx, dx - final size to set

	.leave

CCRS_done::			; label used by swat

	mov	di, offset ChartCompClass
	GOTO	ObjCallSuperNoLock

ChartCompRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompRecalcSizeCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to send the RECALC message to
		each of the comp's children.

CALLED BY:	ChartCompRecalcSize via ObjCompProcessChildren

PASS:		*ds:si - child object
		ss:bp - RecalcSizeLocalVars
		ax 	- MSG_CHART_OBJECT_RECALC_SIZE

RETURN:		nothing -- carry clear

DESTROYED:	cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartCompRecalcSizeCB	proc far	

	class	ChartCompClass
locals	local	RecalcSizeLocalVars

	.enter	inherit

	; See if child is expandable.  If so, don't set size now, just
	; save it's chunk handle for later.

	mov	di, ds:[si]
	test	ds:[di].COI_geoFlags, mask COGF_EXPAND_TO_FIT
	jz	noExpand
	mov	locals.RSLV_expand, si
	jmp	done

noExpand:
	; Child won't expand, set its size.

	movP	cxdx, locals.RSLV_originalSize
	mov	di, 1200
	call	ThreadBorrowStackSpace
	call	ObjCallInstanceNoLock
	call	ThreadReturnStackSpace

	; Add child's size to the final size

	call	AddChildSize

done:
	clc
	.leave
	ret
ChartCompRecalcSizeCB	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddChildSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the size of the child to the local variable
		"childSizes" 

CALLED BY:	ChartCompRecalcSizeCB, ChartCompRecalcSize

PASS:		ss:bp - RecalcSizeLocalVars
		cx, dx - child's size

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

	For a VERTICAL composite, add the V size, and MAX the H size
	For a HORIZONTAL composite, add the H size, and MAX the V size

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddChildSize	proc near
locals	local	RecalcSizeLocalVars
	.enter	inherit 

	cmp	locals.RSLV_compType, CCT_HORIZONTAL
	je	horizontal
	cmp	locals.RSLV_compType, CCT_VERTICAL
	je	vertical

	; Children overlap -- composite's size is the MAXIMUM of the
	; current size and the children's sizes.

	Max	locals.RSLV_childSizes.P_x, cx
	Max	locals.RSLV_childSizes.P_y, dx
	jmp	done

horizontal:
	add	locals.RSLV_childSizes.P_x, cx
	Max	locals.RSLV_childSizes.P_y, dx
	jmp	done

vertical:
	add	locals.RSLV_childSizes.P_y, dx
	Max	locals.RSLV_childSizes.P_x, cx

done:
	.leave
	ret
AddChildSize	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SubtractMarginFromCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subtract off this composite's margin from the passed
		(CX, DX)

CALLED BY:	ChartCompRecalcSize

PASS:		*ds:si - ChartComp 
		cx, dx - original size

RETURN:		cx, dx - modified

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SubtractMarginFromCXDX	proc near
	class	ChartCompClass
	.enter

	DerefChartObject ds, si, di	
	sub	cx, ds:[di].CCI_margin.R_left
	sub	cx, ds:[di].CCI_margin.R_right
	sub	dx, ds:[di].CCI_margin.R_top
	sub	dx, ds:[di].CCI_margin.R_bottom

	; make sure cx, dx are greater than 0

	Max	cx, 0
	Max	dx, 0
	.leave
	ret
SubtractMarginFromCXDX	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddMarginToCXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the "margin" amounts to the passed size

CALLED BY:	ChartCompRecalcSize

PASS:		*ds:si - ChartComp
		cx, dx - size

RETURN:		cx, dx - size increased by margin amount

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddMarginToCXDX	proc near
	class	ChartCompClass
	.enter

	DerefChartObject ds, si, di 
	add	cx, ds:[di].CCI_margin.R_left
	add	cx, ds:[di].CCI_margin.R_right
	add	dx, ds:[di].CCI_margin.R_top
	add	dx, ds:[di].CCI_margin.R_bottom

	.leave
	ret
AddMarginToCXDX	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartCompGetMaxTextBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Call the kids.

PASS:		*ds:si	- ChartCompClass object
		ds:di	- ChartCompClass instance data
		es	- segment of ChartCompClass

RETURN:		cx, dx 	- max bounds

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartCompGetMaxTextBounds	method	dynamic	ChartCompClass, 
					MSG_CHART_OBJECT_GET_MAX_TEXT_SIZE

	mov	bx, OCCT_DONT_SAVE_PARAMS_DONT_TEST_ABORT
	call	ChartCompProcessChildren
	ret
ChartCompGetMaxTextBounds	endm

