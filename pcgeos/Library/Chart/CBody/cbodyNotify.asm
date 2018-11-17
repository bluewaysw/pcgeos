COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cbodyNotify.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 8/92   	Initial version.

DESCRIPTION:
	

	$Id: cbodyNotify.asm,v 1.1 97/04/04 17:48:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the notification OD and message

PASS:		*ds:si	= ChartBodyClass object
		ds:di	= ChartBodyClass instance data
		es	= segment of ChartBodyClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Inc the in-use count, so that the notification OD won't be
	discarded (can't just dirty the block)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyAttach	method	dynamic	ChartBodyClass, 
				MSG_CHART_BODY_ATTACH
	.enter
	call	ObjIncInUseCount
	movdw	ds:[di].CBI_notificationOD, cxdx
	mov	ds:[di].CBI_notificationMessage, bp	
	.leave
	ret
ChartBodyAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartBodyClass object
		ds:di	= ChartBodyClass instance data
		es	= segment of ChartBodyClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/21/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyDetach	method	dynamic	ChartBodyClass, 
					MSG_CHART_BODY_DETACH
	call	ObjDecInUseCount
	ret
ChartBodyDetach	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartBodyNotifyChartDeleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Remove a chart from the tree

PASS:		*ds:si	= ChartBodyClass object
		ds:di	= ChartBodyClass instance data
		es	= segment of ChartBodyClass

		^lcx:dx - child OD

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartBodyNotifyChartDeleted	method	dynamic	ChartBodyClass, 
					MSG_CHART_BODY_NOTIFY_CHART_DELETED
	.enter


	;
	; Send our notification out that the chart is being deleted.
	; This requires the VM block handle of the chart block
	;

	push	cx, si			; chart block, body chunk handle

	mov	bx, cx		; chart handle
	call	VMMemBlockToVMBlock
	mov_tr	cx, ax		; VM block handle


	movdw	bxsi, ds:[di].CBI_notificationOD
	mov	ax, ds:[di].CBI_notificationMessage
	tst	ax
	jz	afterCall
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
afterCall:
	pop	cx, si			; chart block, body chunk handle

	;
	; Remove the child from the linkage
	;

	mov	ax, offset COI_link
	clr	bx
	call	ChartBodyGetCompOffset
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjCompRemoveChild

	.leave
	ret
ChartBodyNotifyChartDeleted	endm

