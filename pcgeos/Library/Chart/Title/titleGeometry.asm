COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		titleGeometry.asm

AUTHOR:		John Wedgwood, Oct 11, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/11/91	Initial revision

DESCRIPTION:
	Geometry code for chart title objects.

	$Id: titleGeometry.asm,v 1.1 97/04/04 17:47:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleNotifyAxisPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	handle notification that the axis has moved.  Just
		load our current position into cx, dx and call
		SET_POSITION, which will adjust the position by the
		right amount, based on the axis' position.  Note that
		we end up positioning the title twice -- the Y 
		axis title gets is position message from the
		composite and then from the axis, whereas the X axis
		title gets its position from the axis, and
		then from the composite.  

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data
		es	= Segment of TitleClass.

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

TitleNotifyAxisPosition	method	dynamic	TitleClass, 
					MSG_TITLE_NOTIFY_AXIS_POSITION
	uses	cx,dx
	.enter

	movP	cxdx, ds:[di].COI_position
	mov	ax, MSG_CHART_OBJECT_SET_POSITION
	call	ObjCallInstanceNoLock

	.leave
	ret
TitleNotifyAxisPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleNotifyAxisSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle a notification that the axis has determined its
		final size.  If the size is different that what it was
		before, then we'll need to redo geometry for the
		entire chart.

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data
		es	= segment of TitleClass

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleNotifyAxisSize	method	dynamic	TitleClass, 
					MSG_TITLE_NOTIFY_AXIS_SIZE
		uses	cx,dx,bp
		.enter

		mov	bl, ds:[di].TI_rotation

		call	GetAxisPlotBounds
		cmp	bl, CORT_0_DEGREES
		je	horizontal

		sub	dx, bp			; height
		cmp	dx, ds:[di].COI_size.P_y
		je	done
		mov	ds:[di].COI_size.P_y, dx

recalc:
	;
	; Save old size and recalc new.  If size changes, then mark
	; entire group's geometry invalid, as everything will need to
	; change.
	;
		mov	ax, TEMP_TITLE_PLOT_BOUNDS
		mov	cx, size word
		call	ObjVarAddData
		mov	ds:[bx], dx		; plot bounds

		DerefChartObject ds, si, di
		movP	cxdx, ds:[di].COI_size

		call	TitleCalcSizeCommon

		cmp	cx, ds:[di].COI_size.P_x
		ja	markInvalid
		cmp	dx, ds:[di].COI_size.P_y
		ja	markInvalid

		mov	ax, TEMP_TITLE_PLOT_BOUNDS
		call	ObjVarDeleteData
		jmp	done

markInvalid:
		mov	cl, mask COS_GEOMETRY_INVALID
		mov	ax, MSG_CHART_OBJECT_MARK_INVALID
		call	UtilCallChartGroup

done:
		.leave
		ret
horizontal:
		sub	cx, ax
		mov	dx, cx
		cmp	cx, ds:[di].COI_size.P_x
		je	done
		mov	ds:[di].COI_size.P_x, cx
		jmp	recalc

TitleNotifyAxisSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleSetPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data
		es	= segment of TitleClass
		cx, dx  - position that composite wants us to have

RETURN:		nothing -- position modified before going to superclass

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleSetPosition	method	dynamic	TitleClass, 
					MSG_CHART_OBJECT_SET_POSITION
	uses	ax, bp
	.enter
	tst	ds:[di].TI_axis
	jz	callSuper
	mov	bl, ds:[di].TI_rotation


	cmp	bl, CORT_0_DEGREES
	je	horizontal

	; Vertical 
	; set top of title to top of axis (bp)

	push	cx
	call	GetAxisPlotBounds
	pop	cx

	mov	dx, bp
	jmp	callSuper

horizontal:

	; Set left edge to left of axis (ax)

	push	dx
	call	GetAxisPlotBounds
	mov_tr	cx, ax
	pop	dx

callSuper:
	
	;
	; cx, dx -- updated position
	;

	.leave
	mov	di, offset TitleClass
	GOTO	ObjCallSuperNoLock


TitleSetPosition	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Recalculate the size of this title

PASS:		*ds:si	= TitleClass object
		ds:di	= TitleClass instance data
		es	= segment of TitleClass
		cx, dx  - size that composite wants us to have

RETURN:		cx, dx - new size

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	When we first get this message, we can't 

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleRecalcSize	method	dynamic	TitleClass, 
					MSG_CHART_OBJECT_RECALC_SIZE
		uses	ax, bp
		.enter

		call	TitleCalcSizeCommon

		mov	ax, TEMP_TITLE_PLOT_BOUNDS
		call	ObjVarDeleteData

		.leave

		mov	di, offset TitleClass
		GOTO	ObjCallSuperNoLock 

TitleRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleCalcSizeCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to calculate the title's size

CALLED BY:	TitleRecalcSize, TitleNotifyAxisSize

PASS:		*ds:si - title
		ds:di - TitleClass instance data
		cx, dx - desired size

RETURN:		cx, dx - new size

DESTROYED:	ax, bp, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/31/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitleCalcSizeCommon	proc near

		class	TitleClass
		.enter

		tst	ds:[di].TI_axis
		jz	getHeight

		mov	al, ds:[di].TI_rotation
		cmp	al, CORT_0_DEGREES
		je	horizontal

		call	getVarData
		jnc	noVarData
		mov	dx, cx			; plot bounds (height)
noVarData:
		call	TitleGetTextHeight	; text height => title width
		jmp	done

horizontal:

		call	getVarData		; cx - plot width

getHeight:
		push	cx
		call	TitleGetTextHeight
		mov	dx, cx
		pop	cx
done:
		.leave
		ret
	;
	; Fetch the vardata
	;
getVarData:
		mov	ax, TEMP_TITLE_PLOT_BOUNDS
		call	ObjVarFindData
		jnc	varDataRet
		mov	cx, ds:[bx]		; fetch plot bounds
varDataRet:
		retn

TitleCalcSizeCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAxisPlotBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fetch the plot bounds from the axis for this title

CALLED BY:	TitleSetPosition, TitleRecalcSize

PASS:		ds:di - title instance data

RETURN:		ax,bp,cx,dx - plot  bounds

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetAxisPlotBounds	proc near
	uses	si
	class	TitleClass

	.enter

	mov	si, ds:[di].TI_axis
	mov	ax, MSG_AXIS_GET_PLOT_BOUNDS
	call	ObjCallInstanceNoLock

	.leave
	ret
GetAxisPlotBounds	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleGetGrObjText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the OD of the TEXT object for this title.

PASS:		*ds:si	- TitleClass object
		ds:di	- TitleClass instance data
		es	- segment of TitleClass

RETURN:		^lcx:dx - text OD

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TitleGetGrObjText	method	dynamic	TitleClass, 
					MSG_CHART_OBJECT_GET_GROBJ_TEXT

	tst	ds:[di].COI_grobj.handle
	jz	callSuper

	movOD	bxsi, ds:[di].COI_grobj
	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	mov	di, mask MF_CALL
	GOTO	ObjMessage


callSuper:

	mov	di, offset TitleClass
	GOTO	ObjCallSuperNoLock
TitleGetGrObjText	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TitleGetTextHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the height that the text wants to be based on
		the passed width.  Use the real text object, unless
		there is none, in which case, just return the height
		of one line.

CALLED BY:	TitleRecalcSize

PASS:		*ds:si - title object
		cx - max width

RETURN:		cx - desired height

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/20/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TitleGetTextHeight	proc near
	uses	ax, dx

	class	TitleClass
	.enter

	tst	ds:[di].COI_grobj.handle
	jz	noGrObj


	clr	dx
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT
	call	ChartObjectCallGrObjWardFar
	mov	cx, dx		; cx - desired height
	

done:
	.leave
	ret

noGrObj:
	call	UtilGetTextLineHeight
	mov_tr	cx, ax
	jmp	done
TitleGetTextHeight	endp

