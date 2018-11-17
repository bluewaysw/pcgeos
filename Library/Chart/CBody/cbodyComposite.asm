COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodyComposite.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

DESCRIPTION:
	

	$Id: cbodyComposite.asm,v 1.1 97/04/04 17:48:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyCallChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all the kids

CALLED BY:

PASS:		*ds:si - Chart body
		ax,cx,dx,bp = message data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/23/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartBodyCallChildren	proc near	
	uses	bx,di
	class	ChartBodyClass
	.enter

	; Set up ObjComp... stack frame
	clr	bx
	push	bx, bx
	mov	di, offset COI_link
	push	di
	push	bx
	mov	di, OCCT_SAVE_PARAMS_DONT_TEST_ABORT
	push	di
	call	ChartBodyGetCompOffset
	call	ObjCompProcessChildren	

	.leave
	ret
ChartBodyCallChildren	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyProcessChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call a callback routine for each child

CALLED BY:

PASS:		*ds:si - ChartBody
		bx - routine to call for each child

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyProcessChildren	proc near	
	uses	bx, di
	class	ChartBodyClass 
	.enter

	; Set up ObjComp... stack frame
	clr	di
	push	di, di
	mov	di, offset COI_link
	push	di
NOFXIP<	push	cs							>
FXIP<	mov	di, SEGMENT_CS						>
FXIP<	push	di							>
	push	bx			; routine to call
	clr	bx
	call	ChartBodyGetCompOffset
	call	ObjCompProcessChildren	
	.leave
	ret
ChartBodyProcessChildren	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyAddChild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the ChartGroup object of the newly created chart
		block to my list of children.

CALLED BY:	ChartBodyCreateChart

PASS:		*ds:si - ChartBody 
		cx - block handle of child block

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartBodyAddChild	proc near	
	uses	ax,bx,cx,dx,di,bp
	class	ChartBodyClass 
	.enter
	mov	dx, offset TemplateChartGroup
	mov	bp, CCO_LAST or mask CCF_MARK_DIRTY

	;
	; Manufacture a phony offset to the CBI_comp field, 
	;

	call	ChartBodyGetCompOffset
	mov	ax, offset COI_link
	clr	bx	; no master part
	call	ObjCompAddChild

	.leave
	ret
ChartBodyAddChild	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyGetCompOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a value in DI that will fool
		ObjCompProcessChildren and friends into thinking that
		the ChartBody is at the same master level as the
		ChartObjectClass objects

CALLED BY:

PASS:		*ds:si - ChartBody

RETURN:		di - offset from start of object to CBI_comp

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/12/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartBodyGetCompOffset	proc near
	uses	bx

	class	ChartBodyClass

	.enter

	mov	bx, ds:[si]			; ds:di - start of object
	mov	di, bx
	add	di, ds:[di].ChartBody_offset
	add	di, offset CBI_comp
	sub	di, bx				

	.leave
	ret
ChartBodyGetCompOffset	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodySendToSelectedCharts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to all selected charts

CALLED BY:	ChartBodyLargeStartMoveCopy

PASS:		*ds:si - chart body
		ax,cx,dx,bp - message data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartBodySendToSelectedCharts	proc near
	uses	bx
	.enter
	mov	bx, offset SendToSelectedChartsCB
	call	ChartBodyProcessChildren

	.leave
	ret
ChartBodySendToSelectedCharts	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToSelectedChartsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the message to this chart group if its selection
		count is nonzero

CALLED BY:	ChartBodySendToSelectedCharts

PASS:		*ds:si - chart group
		ax,cx,dx,bp - message data

RETURN:		carry clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToSelectedChartsCB	proc far
	class	ChartGroupClass 
	.enter
	DerefChartObject ds, si, di
	tst	ds:[di].COI_selection
	jz	done
	call	ObjCallInstanceNoLock
done:
	clc
	.leave
	ret
SendToSelectedChartsCB	endp

