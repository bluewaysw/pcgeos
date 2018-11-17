COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		titleGrObj.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 1/94   	Initial version.

DESCRIPTION:
	

	$Id: titleGrObj.asm,v 1.1 97/04/04 17:47:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleGrObjResized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that the grobj's size has changed.
		Since weird geometry problems can result, we
		automatically make the chart group larger

PASS:		*ds:si	- TitleClass object
		ds:di	- TitleClass instance data
		es	- segment of TitleClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleGrObjResized	method	dynamic	TitleClass, 
					MSG_CHART_OBJECT_GROBJ_RESIZED


	;
	; Save this object's old size before calling the superclass
	;
		push	ds:[di].COI_size.P_x, ds:[di].COI_size.P_y
		mov	di, offset TitleClass
		call	ObjCallSuperNoLock


	;
	; If the title grows by more than a certain amount, then
	; resize the chart larger, rather than having the title go
	; through all kinds of contortions to fit in the existing chart.
	;
		pop	ax, bx
		DerefChartObject ds, si, di

	;
	; Bail if this isn't an axis title
	;
		
		tst	ds:[di].TI_axis
		jz	done
		
		sub	ax, ds:[di].COI_size.P_x
		sub	bx, ds:[di].COI_size.P_y
		js	makeLarger

		tst	ax
		js	makeLarger
done:
		.leave
		ret
makeLarger:

	;
	; At this point, AX and BX are the NEGATIVES of the size
	; differences we want to add.  Make sure neither one is
	; positive, and then subtract the chart group's size from the
	; values we have here (in effect, adding the size difference).
	;
		
		Min	ax, 0
		Min	bx, 0
		push	ax
		mov	ax, MSG_CHART_OBJECT_GET_SIZE
		call	UtilCallChartGroup

		pop	ax
		sub	cx, ax
		sub	dx, bx
		mov	ax, MSG_CHART_OBJECT_SET_SIZE
		call	UtilCallChartGroup

		mov	ax, MSG_CHART_OBJECT_MARK_INVALID
		mov	cl, mask COS_GEOMETRY_INVALID or \
				mask COS_IMAGE_INVALID 
		call	UtilCallChartGroup
		
		jmp	done
TitleGrObjResized	endm



