COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		legendSelect.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/10/92   	Initial version.

DESCRIPTION:
	

	$Id: legendSelect.asm,v 1.1 97/04/04 17:46:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Cause one of the grobjes for the legend to become
		selected. 

PASS:		*ds:si	= LegendClass object
		ds:di	= LegendClass instance data
		es	= Segment of LegendClass.
		cx	- legend item to select

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendSelect	method	dynamic	LegendClass, 
					MSG_CHART_OBJECT_SELECT,
					MSG_CHART_OBJECT_UNSELECT
	uses	cx,dx,bp
	.enter

EC <	test	ds:[di].COI_state, mask COS_UPDATING	>
EC <	ERROR_NZ	ILLEGAL_STATE			>

	ornf	ds:[di].COI_state, mask COS_UPDATING	
	push	si


	;
	; First, find the LegendPair for this series/category
	;

	mov	dx, cx
	clr	cx
	call	ChartCompFindChild	; *ds:cx - LegendPair
	mov	si, cx

	;
	; Now, find the first child of that pair (will be the picture
	; object) 
	;

	clr	cx, dx
	call	ChartCompFindChild
	mov	si, cx
	DerefChartObject ds, si, di
	movdw	bxsi, ds:[di].COI_grobj

	mov_tr	cx, ax			; original message

	mov	ax, MSG_GO_BECOME_SELECTED
	cmp	cx, MSG_CHART_OBJECT_SELECT
	je	send
	mov	ax, MSG_GO_BECOME_UNSELECTED
send:
	mov	dl, HUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	si
	DerefChartObject ds, si, di
	andnf	ds:[di].COI_state, not mask COS_UPDATING

	.leave
	ret
LegendSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendGrObjSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	handle notification that a grobj was selecte

PASS:		*ds:si	= LegendClass object
		ds:di	= LegendClass instance data
		es	= Segment of LegendClass.
		^lcx:dx - OD of grobj

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 1/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LegendGrObjSelected	method	dynamic	LegendClass, 
					MSG_CHART_OBJECT_GROBJ_SELECTED,
					MSG_CHART_OBJECT_GROBJ_UNSELECTED
	uses	ax,cx,dx,bp
	.enter

	test	ds:[di].COI_state, mask COS_UPDATING
	jnz	done

	push	ax			; message

	;
	; See which grobj this corresponds to
	;

	clr	ax
	mov	bx, offset LegendFindGrObjByOD
	call	LegendProcessChildren
	pop	bx			; message
	jnc	done

	mov_tr	cx, ax			; series / category #
	mov	ax, MSG_CHART_OBJECT_SELECT
	cmp	bx, MSG_CHART_OBJECT_GROBJ_SELECTED
	je	sendIt
	mov	ax, MSG_CHART_OBJECT_UNSELECT
sendIt:
	call	UtilCallSeriesGroup
done:
	.leave
	mov	di, offset LegendClass
	GOTO	ObjCallSuperNoLock
LegendGrObjSelected	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	process the LegendPair objects

CALLED BY:	LegendGrObjSelected

PASS:		bx - offset of far proc to call for each child
		
RETURN:		carry SET if processing aborted in the middle
		ax,cx,dx,bp - returned from callback

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendProcessChildren	proc near

	class	LegendClass

	.enter

	clr	di
	push	di, di			; First child
	mov	di, offset COI_link
	push	di
NOFXIP<	push	cs			; code segment			>
FXIP<	mov	di, SEGMENT_CS		; di = vsegment			>
FXIP<	push	di			; push vsegment			>
	push	bx			; routine to call
	mov	di, offset CCI_comp
	clr	bx			; master offset
	call	ObjCompProcessChildren

	.leave
	ret
LegendProcessChildren	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LegendFindGrObjByOD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed OD corresponds to the grobj of the
		first child of this legend

CALLED BY:	LegendGrObjSelected via LegendProcessChildren

PASS:		cx:dx - OD to find

RETURN:		carry SET if found
		ax - incremented otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LegendFindGrObjByOD	proc far
	.enter

	class	LegendClass
	;
	; Get the first child of this LegendPair
	;

	push	cx, dx
	clr	cx, dx
	call	ChartCompFindChild
EC <	ERROR_C OBJECT_NOT_IN_COMPOSITE	>
	mov	si, cx
	DerefChartObject ds, si, di
	pop	cx, dx

	cmpdw	cxdx, ds:[di].COI_grobj
	jne	notFound
	stc
done:
	.leave
	ret
notFound:
	inc	ax
	clc
	jmp	done
LegendFindGrObjByOD	endp

