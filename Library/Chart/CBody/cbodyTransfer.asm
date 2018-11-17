COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodyTransfer.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

DESCRIPTION:
	

	$Id: cbodyTransfer.asm,v 1.1 97/04/04 17:48:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyLargeStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle a copy to clipboard by selecting all grobjes of
		all selected charts and then calling the superclass.

PASS:		*ds:si	- ChartBodyClass object
		ds:di	- ChartBodyClass instance data
		es	- segment of ChartBodyClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyLargeStartMoveCopy	method	dynamic	ChartBodyClass, 
				MSG_META_LARGE_START_MOVE_COPY,
				MSG_META_CLIPBOARD_COPY,
				MSG_GB_CONVERT_SELECTED_GROBJS_TO_BITMAP

	push	ax, cx, dx, bp

	;
	; Set the UPDATING flag so that column/legend objects don't
	; freak out when their grobjes become selected.
	;

	mov	ax, MSG_CHART_OBJECT_SET_STATE
	mov	cx, mask COS_UPDATING
	call	ChartBodySendToSelectedCharts

	mov	cx, MSG_GO_BECOME_SELECTED
	mov	dl, HUM_MANUAL
	mov	bx, offset SendToChartGrObjes
	call	ChartBodyProcessChildren

	pop	ax, cx, dx, bp
	mov	di, offset ChartBodyClass
	call	ObjCallSuperNoLock
	push	ax			; MouseReturnFlags

	mov	cx, MSG_GO_BECOME_UNSELECTED
	mov	bx, offset SendToChartGrObjes
	call	ChartBodyProcessChildren

	;
	; Now clear the UPDATING flag.
	;

	mov	ax, MSG_CHART_OBJECT_SET_STATE
	mov	cx, mask COS_UPDATING shl 8
	call	ChartBodySendToSelectedCharts

	pop	ax			; MouseReturnFlags
	ret
ChartBodyLargeStartMoveCopy	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToChartGrObjes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed message to all the children of this
		chart group if the group's GROBJ is selected

CALLED BY:	SelectAllGrObjesIfSelected, UnselectChildren

PASS:		*ds:si - chart group
		cx - message to send

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToChartGrObjes	proc far

	class	ChartGroupClass

	DerefChartObject ds, si, di
	tst	ds:[di].COI_selection
	jz	done


	;
	; Even though this chart group's selection count is nonzero,
	; make sure that the actual GROBJ for this group is selected.
	;

	push	si
	movOD	bxsi, ds:[di].COI_grobj
	mov	ax, MSG_GO_GET_TEMP_STATE_AND_OPT_FLAGS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	test	ax, mask GOTM_SELECTED
	jz	done

	mov	ax, MSG_CHART_OBJECT_SEND_TO_GROBJ
	call	ChartCompCallChildren

done:
	clc
	ret
SendToChartGrObjes	endp


