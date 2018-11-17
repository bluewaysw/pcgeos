COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		seriesDual.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/12/92   	Initial version.

DESCRIPTION:
	

	$Id: seriesDual.asm,v 1.1 97/04/04 17:47:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesDualGrObjSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle selection/unselection of grobjes

PASS:		*ds:si	= SeriesDualClass object
		ds:di	= SeriesDualClass instance data
		es	= Segment of SeriesDualClass.
		^lcx:dx - OD of grobj being selected
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

	If the grobj is in the PICTURE slot, then send message to
	legend.


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesDualGrObjSelected	method	dynamic	SeriesDualClass, 
					MSG_CHART_OBJECT_GROBJ_SELECTED,
					MSG_CHART_OBJECT_GROBJ_UNSELECTED
	uses	ax,cx
	.enter

	cmpdw	cxdx, ds:[di].CODI_grobj1
	jne	done

	test	ds:[di].COI_state, mask COS_UPDATING
	jnz	done

	mov	bx, ax				; message

	call	SeriesGetSeriesNumber		; ax <- number
	mov_tr	cx, ax

	mov	ax, MSG_CHART_OBJECT_SELECT
	cmp	bx, MSG_CHART_OBJECT_GROBJ_SELECTED
	je	callLegend
	mov	ax, MSG_CHART_OBJECT_UNSELECT

callLegend:
	call	UtilCallLegend
done:
	.leave
	mov	di, offset SeriesDualClass
	GOTO	ObjCallSuperNoLock
SeriesDualGrObjSelected	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SeriesDualSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Select or unselect the picture for this series object

PASS:		*ds:si	= SeriesDualClass object
		ds:di	= SeriesDualClass instance data
		es	= Segment of SeriesDualClass.

RETURN:		nothing 

DESTROYED:	ax 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Assume this is being called from the LEGEND object

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SeriesDualSelect	method	dynamic	SeriesDualClass, 
					MSG_CHART_OBJECT_SELECT,
					MSG_CHART_OBJECT_UNSELECT
	uses	dx,bp
	.enter

EC <	test	ds:[di].COI_state, mask COS_UPDATING	>
EC <	ERROR_NZ	ILLEGAL_STATE			>

	ornf	ds:[di].COI_state, mask COS_UPDATING
	cmp	ax, MSG_CHART_OBJECT_SELECT	; save flag for a while

	mov	dl, HUM_NOW
	mov	ax, MSG_GO_BECOME_SELECTED

	je	callGrObj
	mov	ax, MSG_GO_BECOME_UNSELECTED

callGrObj:
	push	si
	movOD	bxsi, ds:[di].CODI_grobj1
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	DerefChartObject ds, si, di
	andnf	ds:[di].COI_state, not mask COS_UPDATING

	.leave
	ret
SeriesDualSelect	endm



