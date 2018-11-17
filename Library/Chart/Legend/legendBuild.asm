COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		legendBuild.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

DESCRIPTION:

	$Id: legendBuild.asm,v 1.1 97/04/04 17:46:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Determine which changes to make to our managed objects
		based on the passed BuildChangeFlags

PASS:		*ds:si	- LegendClass object
		ds:di	- LegendClass instance data
		es	- segment of LegendClass
		bp 	- BuildChangeFlags

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendBuild	method	dynamic	LegendClass, 
					MSG_CHART_OBJECT_BUILD
	uses	ax,cx,dx,bp
	.enter

	;
	; If this is a HORIZONTAL legend, then center it horizontally.
	; If this is a VERTICAL legend, then center it VERTICALLY
	;

	cmp	ds:[di].CCI_compType, CCT_VERTICAL
	jne	horizontal

	or	ds:[di].COI_geoFlags, mask COGF_CENTER_VERTICALLY
	and	ds:[di].COI_geoFlags, not mask COGF_CENTER_HORIZONTALLY
	jmp	afterCenter

horizontal:
	or	ds:[di].COI_geoFlags, mask COGF_CENTER_HORIZONTALLY
	and	ds:[di].COI_geoFlags, not mask COGF_CENTER_VERTICALLY

afterCenter:

	call	LegendEnsureProperNumberOfChildren

	DerefChartObject ds, si, di

	test	ds:[di].COI_state, mask COS_BUILT
	jz	firstTimeBuild

	ECCheckFlags	bp, BuildChangeFlags

	;
	; If the data has changed, then mark this object's geometry
	; invalid, as series/category titles may have changed. (XXX:
	; We could be more rigorous than this, and make SURE that the
	; title lengths have changed, but geometry is really fairly
	; quick). 
	;

	test	bp, mask BCF_DATA
	jz	afterData

	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cl, mask COS_GEOMETRY_INVALID or mask COS_IMAGE_INVALID
	call	ObjCallInstanceNoLock

	mov	ax, MSG_CHART_OBJECT_MARK_TREE_INVALID
	call	ObjCallInstanceNoLock

afterData:

	;
	; See if we should nuke the pictures
	;

	test	bp, mask BCF_CHART_VARIATION_ATTR or \
			mask BCF_CHART_TYPE or \
			mask BCF_LEGEND_PICTURE or \
			mask BCF_SERIES_COUNT or \
			mask BCF_CATEGORY_COUNT 
	jz	done

	mov	ax, MSG_CHART_OBJECT_CLEAR_ALL_GROBJES
	call	ChartCompCallChildren

	mov	ax, MSG_CHART_OBJECT_MARK_INVALID
	mov	cl, mask COS_IMAGE_INVALID or mask COS_GEOMETRY_INVALID
	call	ObjCallInstanceNoLock

	mov	ax, MSG_CHART_OBJECT_MARK_TREE_INVALID
	mov	cl, mask COS_IMAGE_INVALID or mask COS_GEOMETRY_INVALID
	call	ObjCallInstanceNoLock


done:
	.leave
	mov	di, offset LegendClass
	GOTO	ObjCallSuperNoLock


firstTimeBuild:
	mov	ds:[di].CCI_compFlags, mask CCF_NO_LARGER_THAN_CHILDREN

	jmp	done

LegendBuild	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendEnsureProperNumberOfChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that there are neither too many nor too few
		children 

CALLED BY:	LegendBuild

PASS:		*ds:si - legend object

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/13/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendEnsureProperNumberOfChildren	proc near
	.enter

	;
	; Determine how many there should be
	;



	call	UtilGetChartAttributes
	mov	bl, cl			; ChartType

	mov	ax, MSG_CHART_GROUP_GET_CATEGORY_COUNT
	test	dx, mask CF_SINGLE_SERIES
	jnz	sendIt
	mov	ax, MSG_CHART_GROUP_GET_SERIES_COUNT

sendIt:
	call	UtilCallChartGroup
	cmp	bl, CT_SCATTER

	;
	; For scatter charts, only do legend for series 1-n
	;
	jne	gotCount
	dec	cx

gotCount:
	call	ChartCompCountChildren	; ax - # of kids
	cmp	cx, ax
	je	done
	jg	addSome

	;
	; There are more (AX) than there should be (CX).  Remove every
	; child from CX onwards
	;

destroy:
	call	ChartCompDestroyChild
	dec	ax
	cmp	cx, ax
	jl	destroy
	jmp	done

addSome:
	sub	cx, ax
	mov	di, offset LegendPairClass
addLoop:
	call	ChartCompCreateChild
	loop	addLoop

done:
	.leave
	ret
LegendEnsureProperNumberOfChildren	endp


