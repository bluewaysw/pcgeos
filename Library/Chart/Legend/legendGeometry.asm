COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		legendGeometry.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

DESCRIPTION:
	

	$Id: legendGeometry.asm,v 1.1 97/04/04 17:46:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Recalc the size of this legend item

PASS:		*ds:si	- LegendItemClass object
		ds:di	- LegendItemClass instance data
		es	- segment of LegendItemClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendItemRecalcSize	method	dynamic	LegendItemClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
	uses	ax,bp
	.enter


	cmp	ds:[di].LII_type, LIT_TEXT
	je	legendText

	mov	cx, LEGEND_ITEM_MIN_WIDTH
	mov	dx, LEGEND_ITEM_MIN_HEIGHT
callSuper:
	.leave
	mov	di, offset LegendItemClass
	GOTO	ObjCallSuperNoLock


legendText:

	push	es
	;
	; TEXT:
	;
	; get the OD of the text grobj for this legend item.  
	; Get the TEXT for this item
	; create a gstate for calculations, and figure out the text
	; size.   We can't just query the grobj text object directly,
	; because:
	; 	1)  There may not be a grobj text object yet
	;	2)  the text may have changed since the last time it
	;	was set.
	;
	; This is actually a design problem (ie, grobj objects
	; should be created BEFORE doing geometry), but fixing it
	; would be a major overhaul, for minor benefit.
	;
	;

	sub	sp, CHART_TEXT_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss
	call	LegendItemGetText

	call	UtilGetTextSize

	add	sp, CHART_TEXT_BUFFER_SIZE

	Max	cx, LEGEND_ITEM_MIN_WIDTH
	Max	dx, LEGEND_ITEM_MIN_HEIGHT

	pop	es
	jmp	callSuper

LegendItemRecalcSize	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendItemGetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the text for this legend item

CALLED BY:	LegendItemRecalcSize

PASS:		*ds:si - legend item
		es:di - buffer of CHART_TEXT_BUFFER_SIZE to fill in

RETURN:		es:di - buffer filled in

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendItemGetText	proc near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	;
	; Find out the # of this object's parent in ITS parent's list
	;

	mov	ax, MSG_CHART_OBJECT_FIND_PARENT
	call	ObjCallInstanceNoLock

	push	cx			; LegendPair
	mov	si, cx
	mov	ax, MSG_CHART_OBJECT_FIND_PARENT
	call	ObjCallInstanceNoLock	
	mov	si, cx
	pop	dx
	mov	cx, ds:[LMBH_handle]

	call	ChartCompFindChild	; bp - position


	call	UtilGetChartAttributes
	mov	cx, bp			; position

	test	dx, mask CF_SINGLE_SERIES
	jnz	categoryTitle

	mov	ax, MSG_CHART_GROUP_GET_SERIES_TITLE
	jmp	callIt

categoryTitle:
	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_TITLE

callIt:
	mov	dx, ss
	mov	bp, di
	call	UtilCallChartGroup

	.leave
	ret
LegendItemGetText	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	for VERTICAL legends:
			make all legend items the same width

		for HORIZONTAL legends:
			make the legend items of each pair the same width

PASS:		*ds:si	- LegendClass object
		ds:di	- LegendClass instance data
		es	- segment of LegendClass
		cx, dx - suggested size

RETURN:		cx, dx - new size

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendRecalcSize	method	dynamic	LegendClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
	uses	ax,bp
	.enter

	call	LegendSetMargins


	mov	di, offset LegendClass
	call	ObjCallSuperNoLock

	push	cx, dx		; save bounds to return to caller

	clr	bp		; initial max width

	mov	bx, offset LegendGetMaxPairWidthCB
	call	LegendProcessChildren

	;
	; For vertical legends, make all pairs the same width
	;

	DerefChartObject ds, si, di
	cmp	ds:[di].CCI_compType, CCT_VERTICAL
	jne	done

	mov	bx, offset LegendSetPairWidthCB
	call	LegendProcessChildren
done:
	pop	cx, dx		; legend bounds for caller
	.leave
	ret
LegendRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendGetMaxPairWidthCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return the maximum of the passed width and this
		LegendPair's width

CALLED BY:	LegendRecalcSize via ObjCompProcessChildren

PASS:		*ds:si - LegendPair object
		bp - passed width

RETURN:		bp - updated

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendGetMaxPairWidthCB	proc far

	class	LegendPairClass

	push	bp			; max so far	

	clr	bp

	;
	; Get the max item width.  While we're at it, set both items
	; to the same width.
	;

	mov	bx, offset LegendGetMaxItemWidthCB
	call	LegendProcessChildren

	mov	bx, offset LegendSetItemWidthCB
	call	LegendProcessChildren

	;
	; Add this pair's left/right margins to the returned width
	;

	DerefChartObject ds, si, di
	add	bp, ds:[di].CCI_margin.R_left
	add	bp, ds:[di].CCI_margin.R_right

	pop	cx
	Max	bp, cx			; return the max
	clc
	ret
LegendGetMaxPairWidthCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendGetMaxItemWidthCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to return the maximum of the passed
		width and the object's width 

CALLED BY:	LegendGetMaxPairWidthCB via LegendProcessChildren

PASS:		bp - current maximum
		*ds:si - object

RETURN:		bp - maximum of object's width and current max

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendGetMaxItemWidthCB	proc far
	class	LegendItemClass

	DerefChartObject ds, si, di
	Max	bp, ds:[di].COI_size.P_x
	clc
	ret
LegendGetMaxItemWidthCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendSetItemWidthCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set this item's width to the passed width

CALLED BY:	LegendGetMaxPairWidthCB via ObjCompProcessChildren

PASS:		bp - width to set
		*ds:si - object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendSetItemWidthCB	proc far
	class	LegendItemClass

	DerefChartObject ds, si, di	; clears carry
	mov	ds:[di].COI_size.P_x, bp
	ret
LegendSetItemWidthCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendSetPairWidthCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the width of this pair.  Subtract off the pair's
		left and right margins, and set the widths of the
		children. 

CALLED BY:	LegendRecalcSize	via ObjCompProcessChildren

PASS:		*ds:si - legend pair
		bp - width to set

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendSetPairWidthCB	proc far
	class	LegendPairClass

	DerefChartObject ds, si, di
	mov	ds:[di].COI_size.P_x, bp
	sub	bp, ds:[di].CCI_margin.R_left
	sub	bp, ds:[di].CCI_margin.R_right
	mov	bx, offset LegendSetItemWidthCB
	call	LegendProcessChildren
	clc
	ret
LegendSetPairWidthCB	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendSetMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the margins for this legend.  Set them each time
		we recalc size, because the user may be switching from
		horizontal to vertical, and vice-versa.

CALLED BY:	LegendRecalcSize

PASS:		*ds:si - legend

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendSetMargins	proc near
	uses	ax,bx,cx,dx,di
	class	LegendClass
	.enter

	mov	cl, ds:[di].CCI_compType

	;
	; If the legend is vertical, then store a value in the left
	; margin, to separate it from the rest of the chart.
	;

	mov	cl, ds:[di].CCI_compType
	cmp	cl, CCT_VERTICAL
	je	vertical

	mov	ds:[di].CCI_margin.R_top, LEGEND_VERTICAL_MARGIN*2
	mov	ds:[di].CCI_margin.R_bottom, LEGEND_VERTICAL_MARGIN
	jmp	callKids

vertical:
	mov	ds:[di].CCI_margin.R_left, LEGEND_HORIZONTAL_MARGIN
	mov	ds:[di].CCI_margin.R_right, LEGEND_HORIZONTAL_MARGIN

callKids:
	mov	bx, offset LegendSetMarginsCB
	call	LegendProcessChildren		

	.leave
	ret
LegendSetMargins	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendSetMarginsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the margin for this LegendPair

CALLED BY:	LegendSetMargins

PASS:		*ds:si - LegendPair
		cl - ChartCompType of legend (horiz or vertical)

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendSetMarginsCB	proc far
	.enter
	class	LegendPairClass

	DerefChartObject ds, si, di

	cmp	cl, CCT_VERTICAL
	je	vertical


	;
	; Set margin for each LegendPair of a HORIZONTAL legend
	;

	mov	ds:[di].CCI_margin.R_left, LEGEND_HORIZONTAL_MARGIN/2
	mov	ds:[di].CCI_margin.R_right, LEGEND_HORIZONTAL_MARGIN/2
	clr	ds:[di].CCI_margin.R_top
	clr	ds:[di].CCI_margin.R_bottom
	jmp	done

vertical:
	mov	ds:[di].CCI_margin.R_top, LEGEND_VERTICAL_MARGIN/2
	mov	ds:[di].CCI_margin.R_bottom, LEGEND_VERTICAL_MARGIN/2
	clr	ds:[di].CCI_margin.R_right
	clr	ds:[di].CCI_margin.R_left

done:
	clc
	.leave
	ret
LegendSetMarginsCB	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendMarkInvalid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Mark all children invalid 

PASS:		*ds:si	- LegendClass object
		ds:di	- LegendClass instance data
		es	- segment of LegendClass

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendMarkInvalid	method	dynamic	LegendClass, 
					MSG_CHART_OBJECT_MARK_INVALID
		uses	ax,cx,dx,bp
		.enter

		mov	di, offset LegendClass
		call	ObjCallSuperNoLock

		test	cl, mask COS_IMAGE_PATH
		jz	done

	
	;
	; If IMAGE_PATH, then one of the children has marked its image
	; invalid.  If one legend item is given a REALIZE, then they all
	; must get it, so mark all the other children invalid as well.
	;

		mov	cl, mask COS_IMAGE_INVALID
		mov	ax, MSG_CHART_OBJECT_MARK_TREE_INVALID
		call	ObjCallInstanceNoLock


done:

		.leave
		ret
LegendMarkInvalid	endm



