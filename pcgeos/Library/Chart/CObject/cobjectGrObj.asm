COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cobjectGrObj.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------


DESCRIPTION:
	

	$Id: cobjectGrObj.asm,v 1.1 97/04/04 17:46:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Create a GrObj.  Stick the  GrObj OD in the caller's
		instance data.

CALLED BY: 	ChartObjectCreateOrUpdateGrObj

PASS:		*ds:si	= ChartObjectClasso object
		es	= Segment of ChartObjectClass.

		cx:dx 	= class to create

		ss:bp - CreateGrObjParams

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectCreateGrObj	proc near

	uses	ax,bx,cx,dx,bp,si,di

	class	ChartObjectClass 

	.enter

	ECCheckFlags	ss:[bp].CGOP_flags, CreateGrObjFlags

	ECCheckFlags	ss:[bp].CGOP_locks, GrObjLocks

	mov	ax,MSG_GB_INSTANTIATE_GROBJ
	call	UtilCallChartBody

	; save OD

	DerefChartObject ds, si, di 
	movOD	ds:[di].COI_grobj, cxdx
	call	ObjMarkDirty


	;
	; Initialize.  Since we need to set the rotation, etc -- we
	; just use dummy values now, and use real values in the common
	; procedure.   (XXX: is there a cleaner way to do this? )
	;

	;
	; Added 1/93 -- use the REAL passed size, rather than a dummy
	; value, so that we don't get any weird scaling effects, or
	; whatever. 
	;

	mov	bx, bp

	push	bp
	sub	sp, size GrObjInitializeData
	mov	bp, sp
	clrdwf	ss:[bp].GOID_position.PDF_x
	clrdwf	ss:[bp].GOID_position.PDF_y
	mov	ax, ss:[bx].CGOP_size.P_x
	mov	ss:[bp].GOID_width.WWF_int, ax
	clr	ss:[bp].GOID_width.WWF_frac
	mov	ax, ss:[bx].CGOP_size.P_y
	mov	ss:[bp].GOID_height.WWF_int, ax
	clr	ss:[bp].GOID_height.WWF_frac
	mov	ax, MSG_GO_INITIALIZE
	call	ChartObjectCallGrObj
	add	sp, size GrObjInitializeData
	pop	bp

	;
	; Tell the grobj not to copy its locks if it ever gets copied
	;

	mov	ax, MSG_GO_SET_GROBJ_ATTR_FLAGS
	mov	cx, mask GOAF_DONT_COPY_LOCKS
	clr	dx
	call	ChartObjectCallGrObj

	;
	; Set the bounds of the object, unless we shouldn't.
	;

	test	ss:[bp].CGOP_flags, mask CGOF_CUSTOM_BOUNDS
	jnz	afterBounds

	call	ChartObjectSetGrObjBoundsCommon

afterBounds:
	;
	; Set the locks on the grobject
	;

	mov	cx, ss:[bp].CGOP_locks
	clr	dx
	mov	ax, MSG_GO_CHANGE_LOCKS
	call	ChartObjectCallGrObj

	;
	; Set the new grobj to send notification to this object
	;


	mov	bx, bp		; CreateGrObjParams


	mov	ax, MSG_GO_SET_ACTION_NOTIFICATION_OUTPUT
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	ChartObjectCallGrObj

	;
	; Turn off action notification for the remainder of the
	; create. This prevents text objects from moving when
	; they get a set text.
	;

	mov	ax, MSG_GO_SUSPEND_ACTION_NOTIFICATION
	call	ChartObjectCallGrObj

	;
	; Add this grobj to either the group or the body
	;

	; make sure the params ptr hasn't changed.  If it has, a GrObj
	; method is trashing BP.
	ECCheckFlags	ss:[bx].CGOP_flags, CreateGrObjFlags


	DerefChartObject ds, si, di
	movOD	cxdx, ds:[di].COI_grobj
	test	ss:[bx].CGOP_flags, mask CGOF_ADD_TO_GROUP
	jz	addToBody

	;
	; Add to the group
	;

	mov	si, ss:[bx].CGOP_group.chunk
	mov	bx, ss:[bx].CGOP_group.handle
	mov	ax, MSG_GROUP_ADD_GROBJ
	mov	di, mask MF_FIXUP_DS
	mov	bp, GAGOF_LAST
	call	ObjMessage
	jmp	done

	;
	; Add to body -- either at the top (end) of the draw list, or
	; at the specified position.  Watch out for the caller passing
	; the GOBAGOR_LAST flag (series objects do this).
	;

addToBody:
	;
	; We're adding a new grobj, so update our conception of the
	; top grobj.  This also gives us a new top in BP, if we need it.
	;
	mov	ax, MSG_CHART_GROUP_UPDATE_TOP_GROBJ
	call	UtilCallChartGroup

	test	ss:[bx].CGOP_flags, mask CGOF_DRAW_ORDER
	jz	gotOrder

	;
	; If the passed order is GOBAGOR_LAST, then use the "top"
	; value, otherwise use the passed order.
	;
		
	mov	ax, ss:[bx].CGOP_drawOrder
	cmp	ax, GOBAGOR_LAST or mask GOBAGOF_DRAW_LIST_POSITION
	je	gotOrder		
	mov	bp, ax
		
gotOrder:
	mov	ax, MSG_GB_ADD_GROBJ
	call	UtilCallChartBody
done:
	.leave
	ret
ChartObjectCreateGrObj	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCenterPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the position of the center of the grobject.

CALLED BY:	ChartObjectSetGrObjBoundsCommon

PASS:		ss:bx - CreateGrObjParams
		ss:bp - PointDWFixed at which to store data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 5/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCenterPosition	proc near
	uses	ax,cx,dx,si,di
	class	ChartGroupClass 
	.enter

	;
	; If this object is in a group, then just determine its center
	; relative to the group's center (passed in) rather than the
	; ChartGroup's document position
	;
	; (the hoops I have to jump through!!!)
	;

	test	ss:[bx].CGOP_flags, mask CGOF_ADD_TO_GROUP
	jz	notGroup

	;
	; It IS in a group -- but see if it's just being created now,
	; in which case calculate its dimensions the normal way, as
	; they'll be adjusted when it's added to the group later on...
	;

	test	ss:[bx].CGOP_flags, mask CGOF_CREATED
	jnz	notGroup

	
	;
	; Take the passed position, add half the size, and
	; subtract the group's center
	;

inGroup::

IRP xy, <x, y>

	clr	cx
	mov	ax, ss:[bx].CGOP_size.P_&xy
	shrwwf	axcx
	add	ax, ss:[bx].CGOP_position.P_&xy
	sub	ax, ss:[bx].CGOP_groupCenter.P_&xy
	cwd
	movdwf	ss:[bp].PDF_&xy, dxaxcx
endm
	jmp	done
	

notGroup:

	assume	ds:ChartUI
	mov	si, ds:[TemplateChartGroup]
	assume	ds:dgroup


IRP xy, <x, y>


	;
	; Calc upper left-hand position
	;

	movdw	dxcx, ds:[si].CGI_docPosition.PD_&xy
	add	cx, ss:[bx].CGOP_position.P_&xy
	adc	dx, 0

	;
	; Add 1/2 the size, keeping track of the fraction when we
	; shift. 
	;

	push	ax
	clr	di			; zero frac
	mov	ax, ss:[bx].CGOP_size.P_&xy
	shrwwf	axdi
	add	cx, ax
	adc	dx, 0
	pop	ax

	movdwf	ss:[bp].PDF_&xy, dxcxdi
ENDM
done:
	.leave
	ret
CalcCenterPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSizeInStackFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size of the grobj in the stack frame

CALLED BY:	ChartObjectSetGrObjBoundsCommon

PASS:		ds:di - chart object
		ss:bp - PointWWFixed buffer in which to put size
		ss:bx - CreateGrObjParams 

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetSizeInStackFrame	proc near	
	class	ChartObjectClass 
	.enter

	; Make sure that the GrObjInitializeData width / height
	; fields are identical to the PointWWFixed.  If this changes,
	; go yell at Steve.

	CheckHack <(offset GOID_height - offset GOID_width) eq \
			(size WWFixed)>

	CheckHack <(offset BI_height - offset BI_width) eq \
			(size WWFixed)>

	; set width

IRP xy, <x, y>

	mov	ax, ss:[bx].CGOP_size.P_&xy
	mov	ss:[bp].PF_&xy.WWF_int, ax
	mov	ss:[bp].PF_&xy.WWF_frac, 0

ENDM

	.leave
	ret
SetSizeInStackFrame	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateGStringGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the gstring for the grobj of this chart object

CALLED BY:	EXTERNAL

PASS:		ss:bp - CreateGStringParams
		*ds:si - chart object
		di - gstate (gstring) handle

RETURN:		carry set if newly created

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/25/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateGStringGrObj	proc far
	uses	cx,dx,di
	class	ChartObjectClass 
	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	mov	ss:[bp].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS

	; End the gstring
	mov	di, ss:[bp].CGSP_gstring
	call	GrEndGString


	push	si			; chunk handle of object
	mov	si, di			; gstring to draw

	;
	; Start at the beginning of the string.  
	;

	mov	al, GSSPT_BEGINNING
	clr	cx
	call	GrSetGStringPos

	clr	di, dx			; gstate to draw to (null)
	call	GrGetGStringBounds	; ax, bx, cx, dx <- bounds
	

	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString
	pop	si			; chunk handle of object
	
	;
	; set position equal to upper-left hand corner of bounds, 
	; size to zero
	;

	movP	ss:[bp].CGOP_position, axbx
	clrdw	ss:[bp].CGOP_size

	mov	cx, segment GStringClass
	mov	dx, offset GStringClass
	call	ChartObjectCreateOrUpdateGrObj

	;
	; Only set attributes when creating
	;

	test	ss:[bp].CGOP_flags, mask CGOF_CREATED
	jz	afterAttributes
	call	SetGrObjAttributes

afterAttributes:

	mov	ax, MSG_GSO_SET_GSTRING
	clr	cx
	mov	dx, ss:[bp].CGSP_vmBlock
	call	ChartObjectCallGrObj

	call	ChartObjectEndCreateOrUpdate

	.leave
	ret
ChartObjectCreateOrUpdateGStringGrObj	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCallGrObjStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the GrObj with stuff on the stack

CALLED BY:	UTILITY

PASS:		ax,cx,dx,bp - message data
		(dx - size, and ss:bp - stack data)

RETURN:		ax,cx,dx,bp = returned from GrObj 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCallGrObjStack	proc near
	uses	bx,si,di
	class	ChartObjectClass 
	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	mov	si, ds:[si]		; deref instance data
	movOD	bxsi, ds:[si].COI_grobj
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
ChartObjectCallGrObjStack	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCallGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the GrObj associated with this chart object
		call via MF_CALL and MF_FIXUP_DS

CALLED BY:

PASS:		*ds:si - chart object
		ax,cx,dx,bp - message data

RETURN:		ax,cx,dx,bp - returned from GrObj

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCallGrObj	proc near	
	uses	bx, si,di
	class	ChartObjectClass 
	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	DerefChartObject ds, si, di
	mov	bx, ds:[di].COI_grobj.handle
	mov	si, ds:[di].COI_grobj.offset
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
ChartObjectCallGrObj	endp

ChartObjectCallGrObjFar	proc	far
	call	ChartObjectCallGrObj
	ret
ChartObjectCallGrObjFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCallGrObjWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the "ward" of the grobject

CALLED BY:

PASS:		*ds:si - chart object
		ax,cx,dx,bp - message data

RETURN:		ax,cx,dx,bp - returned from ward

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCallGrObjWard	proc near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	CallGrObjWardCommon di
ChartObjectCallGrObjWard	endp

ChartObjectCallGrObjWardFar	proc	far
	call	ChartObjectCallGrObjWard
	ret
ChartObjectCallGrObjWardFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCallGrObjWardStack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the grobj ward using the stack

CALLED BY:	Chart object Utility

PASS:		*ds:si - chart object
		ax - message
		ss:bp - message data
		dx - size of message data

RETURN:		ax,cx,dx,bp - returned from method called

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/20/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCallGrObjWardStack	proc near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	FALL_THRU	CallGrObjWardCommon di
ChartObjectCallGrObjWardStack	endp

	
CallGrObjWardCommon	proc	near
	uses	bx, si
	.enter
	push	ax,cx,dx,bp,di

EC <	mov	ax, MSG_META_IS_OBJECT_IN_CLASS		>
EC <	mov	cx, segment GrObjVisGuardianClass	>
EC <	mov	dx, offset GrObjVisGuardianClass	>
EC <	call	ChartObjectCallGrObj			>
EC <	ERROR_NC NOT_A_VIS_GUARDIAN			>

	mov	ax, MSG_GOVG_GET_VIS_WARD_OD
	call	ChartObjectCallGrObj
	movOD	bxsi, cxdx

	pop	ax,cx,dx,bp,di
	call	ObjMessage
	.leave
	FALL_THRU_POP	di
	ret
CallGrObjWardCommon	endp








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateRectangle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a rectangle, or, if one exists, update its size
		and position

CALLED BY:	GLOBAL within chart

PASS:		*ds:si - Chart Object
		ss:bp - CreateRectParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Also sticks the OD in the calling object's instance data.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectCreateOrUpdateRectangle	proc far
	uses	ax,bx,cx,dx

	class	ChartObjectClass 
	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	; If resize lock is set, then use our special subclass

	test	ss:[bp].CGOP_locks, mask GOL_RESIZE
	jz	noLocks
	mov	cx, segment ChartRectClass
	mov	dx, offset ChartRectClass
	jmp	callIt


noLocks:
	mov	cx, segment RectClass
	mov	dx, offset RectClass
callIt:
	call	ChartObjectCreateOrUpdateGrObj

	;
	; Set the attributes if the object is being created for the
	; first time.
	;

	test	ss:[bp].CGOP_flags, mask CGOF_CREATED
	jz	afterSet
	call	SetGrObjAttributes

afterSet:
	call	ChartObjectEndCreateOrUpdate

	.leave
	ret
ChartObjectCreateOrUpdateRectangle	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGrObjAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the attributes for a grobject

CALLED BY:	INTERNAL

PASS:		*ds:si - chart object

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 2/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGrObjAttributes	proc near
	uses	ax,bx,cx,dx,di,si
	.enter

	ECCheckFlags	ss:[bp].CGOP_flags, CreateGrObjFlags

	test	ss:[bp].CGOP_flags, mask CGOF_USE_TOKENS
	jnz	useTokens


	test	ss:[bp].CGOP_flags, mask CGOF_AREA_COLOR
	jz	afterAreaColor

	; convert color to RGB
	
	clr	di
	mov	ah, ss:[bp].CGOP_areaColor
	call	GrMapColorIndex

	; Set area color

	mov	cl, al
	mov	ch, bl
	mov	dl, bh
	mov	ax, MSG_GO_SET_AREA_COLOR
	call	ChartObjectCallGrObj

afterAreaColor:
	test	ss:[bp].CGOP_flags, mask CGOF_AREA_MASK
	jz	afterAreaMask

	; set area mask
	mov	ax, MSG_GO_SET_AREA_MASK
	mov	cl, ss:[bp].CGOP_areaMask
	call	ChartObjectCallGrObj

afterAreaMask:

	test	ss:[bp].CGOP_flags, mask CGOF_LINE_COLOR
	jz	afterLineColor

	; convert color to RGB
	
	clr	di
	mov	ah, ss:[bp].CGOP_lineColor
	call	GrMapColorIndex
	mov	cl, al
	mov	ch, bl
	mov	dl, bh
	mov	ax, MSG_GO_SET_LINE_COLOR
	call	ChartObjectCallGrObj

afterLineColor:

	test	ss:[bp].CGOP_flags, mask CGOF_LINE_MASK
	jz	afterLineMask

	mov	ax, MSG_GO_SET_LINE_MASK
	mov	cl, ss:[bp].CGOP_lineMask
	call	ChartObjectCallGrObj

afterLineMask:

	test	ss:[bp].CGOP_flags, mask CGOF_LINE_STYLE
	jz	done

	mov	ax, MSG_GO_SET_LINE_STYLE
	mov	cl, ss:[bp].CGOP_lineStyle
	call	ChartObjectCallGrObj

done:
	.leave
	ret
	
useTokens:
	; If the caller has set any of the other bits, then barf our
	; brains out.

if ERROR_CHECK
	test	ss:[bp].CGOP_flags, mask CGOF_LINE_MASK or \
				mask CGOF_AREA_MASK or \
				mask CGOF_AREA_COLOR or \
				mask CGOF_LINE_COLOR or \
				mask CGOF_LINE_STYLE
	ERROR_NZ	ILLEGAL_FLAGS
endif

	mov	cx, ss:[bp].CGOP_lineToken
	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ChartObjectCallGrObj

	mov	cx, ss:[bp].CGOP_areaToken
	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ChartObjectCallGrObj
	jmp	done

SetGrObjAttributes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectSetGrObjBoundsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bounds of the GrObj for this chart object,
		either when creating or updating this grobj

CALLED BY:	ChartObjectCreateGrObj, 
		ChartObjectUpdateGrObjBounds,
		SetTextCustomBounds

PASS:		*ds:si - chart object
		ss:bp - CreateGrObjParams
		carry SET if newly created, clear otherwise

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

	Use the INIT_BASIC_DATA message, because SET_POSITION doesn't
	work for a (possibly) rotated object.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectSetGrObjBoundsCommon	proc near
	uses	ax,bx,cx,dx,di,bp

	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	lahf			; save carry flag

	mov	bx, bp		; CreateGrObjParams

	sub	sp, size BasicInit
	mov	bp, sp

	;
	; BI_center is zero, but don't count on it!
	;

	addnf	bp, <offset BI_center>
	call	CalcCenterPosition
	subnf	bp, <offset BI_center>


	add	bp, offset BI_width
	call	SetSizeInStackFrame
	sub	bp, offset BI_width

	mov	cx, 1				; cx.ax = 1.0
	clr	ax

	test	ss:[bx].CGOP_flags, mask CGOF_ROTATED
	jz	notRotated

	;
	; rotation is 90 degrees, so swap width and height, store the
	; 90 degree rotation in the matrix
	;
	; store the "rotate 90" matrix in the transform (0,-1,1,0)
	;

	xchgdw	ss:[bp].BI_width, ss:[bp].BI_height, dx

	movwwf	ss:[bp].BI_transform.GTM_e11, axax
	movwwf	ss:[bp].BI_transform.GTM_e21, cxax
	movwwf	ss:[bp].BI_transform.GTM_e22, axax
	neg	cx
	movwwf	ss:[bp].BI_transform.GTM_e12, cxax
	jmp	sendIt

notRotated:
	; store identity matrix in the transform

	movwwf	ss:[bp].BI_transform.GTM_e11, cxax
	movwwf	ss:[bp].BI_transform.GTM_e12, axax
	movwwf	ss:[bp].BI_transform.GTM_e21, axax
	movwwf	ss:[bp].BI_transform.GTM_e22, cxax

sendIt:

	mov	dx, size BasicInit
	mov	ax, MSG_GO_INIT_BASIC_DATA
	call	ChartObjectCallGrObjStack

	add	sp, size BasicInit

	.leave
	ret
ChartObjectSetGrObjBoundsCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectUpdateGrObjBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the size and position for the existing grobject

CALLED BY:	ChartObjectCreateOrUpdateGrObj

PASS:		*ds:si - chart object
		ss:bp - CreateGrObjParams

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/13/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectUpdateGrObjBounds	proc near
	uses	si,bp
	.enter

	;
	; Do nothing if the CUSTOM_BOUNDS flag is set
	;
	test	ss:[bp].CGOP_flags, mask CGOF_CUSTOM_BOUNDS
	jnz	done


	; Nuke the MOVE and RESIZE locks

	clr	cx
	mov	dx, mask GOL_MOVE or mask GOL_RESIZE
	mov	ax, MSG_GO_CHANGE_LOCKS
	call	ChartObjectCallGrObj

	;
	; Set the bounds
	;

	clc			; signal not created
	call	ChartObjectSetGrObjBoundsCommon

	; restore the locks

	; Set the locks back to the way they were.  Since I was only
	; clearing locks before, I only need to pass the locks the way
	; they originally were in CX

	mov	ax, MSG_GO_CHANGE_LOCKS
	clr	dx
	call	ChartObjectCallGrObj
done:
	.leave
	ret
ChartObjectUpdateGrObjBounds	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a graphics string

CALLED BY:	global (within chart)

PASS:		*ds:si - chart object

RETURN:		bp - gstring handle
		ax - vmem block handle of first data block in the
		gstring 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	create the string in the current VM file

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateGString	proc far
	uses	bx,cx,dx,si,di
	class	ChartObjectClass 
	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	mov	bp, ds:[si]

	; Call GrCreateGString

	call	UtilGetVMFile		; VM file handle => bx
	mov	cl, GST_VMEM		; type of string 
	call	GrCreateGString

	mov	ax, si			; VM block of new string
	mov	bp, di			; gstring handle

	.leave
	ret
ChartObjectCreateGString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GrObject or else update its position/size
		

CALLED BY:	ChartObjectCreateOrUpdateRectangle,
		ChartObjectCreateOrUpdateGStringGrObj,
		ChartObjectCreateOrUpdateStandardLine,
		ChartObjectCreateOrUpdatePolyline,
		ChartObjectCreateOrUpdateText,
		ChartObjectCreateOrUpdateMultText

PASS:		*ds:si - chart object
		ss:bp - CreateGrObjParams (or some subclass thereof)
		cx:dx - Class of GrObj to create

RETURN:		nothing 
		^lcx:dx - grobj od

		

DESTROYED:	nothing 

WARNING:
	This routine suspends the action notification of the grobj --
	caller must be sure to reinstate the action notification.

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateGrObj	proc near
	uses	di
	class	ChartObjectClass 
	.enter

	ECCheckFlags	ss:[bp].CGOP_flags, CreateGrObjFlags

EC <	call	ECCheckChartObjectDSSI	> 

	; Turn off action notification

	mov	ax, MSG_GO_SUSPEND_ACTION_NOTIFICATION
	call	ChartObjectCallGrObj

	;
	; Set the grobj not valid so it doesn't invalidate itself
	;

	mov	ax, MSG_GO_NOTIFY_GROBJ_INVALID
	call	ChartObjectCallGrObj


	;
	; See if we need to create a new grobj, or just update the
	; existing. 
	;

	DerefChartObject	ds, si, di	
	tst	ds:[di].COI_grobj.handle
	jz	create
	
	andnf	ss:[bp].CGOP_flags, not mask CGOF_CREATED

	call	ChartObjectUpdateGrObjBounds
	jmp	done

create:
	ornf	ss:[bp].CGOP_flags, mask CGOF_CREATED
	call	ChartObjectCreateGrObj

done:
	.leave
	ret
ChartObjectCreateOrUpdateGrObj	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdatePolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create or update a polyline object

CALLED BY:

PASS:		*ds:si - chart object
		ss:bp - CreatePolylineParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdatePolyline	proc far
	uses	ax,bx,cx,dx,di

	class	ChartObjectClass

	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	; create object -- setting attributes if newly created

	mov	cx, segment ChartSplineGuardianClass
	mov	dx, offset ChartSplineGuardianClass
	call	ChartObjectCreateOrUpdateGrObj

	;
	; only set the attributes and the marker shape if newly
	; created. 
	;
	test	ss:[bp].CGOP_flags, mask CGOF_CREATED
	jz	afterAttributes

	call	SetGrObjAttributes
	mov	cl, ss:[bp].CPP_markerShape
	mov	ax, MSG_SPLINE_SET_MARKER_SHAPE
	call	ChartObjectCallGrObjWard

afterAttributes:

	test	ss:[bp].CPP_flags, mask CPF_LEGEND
	jz	afterLegend

	mov	ax, MSG_SPLINE_SET_MARKER_FLAGS
	mov	cx, mask SMKF_DONT_DRAW_ENDPOINTS
	call	ChartObjectCallGrObjWard

afterLegend:

	;
	; Set mode as inactive
	;

	mov	ax, MSG_SG_SET_SPLINE_MODE
	mov	cl, SM_INACTIVE
	call	ChartObjectCallGrObj

	;
	; close curve, if flag set
	;

	test	ss:[bp].CPP_flags, mask CPF_CLOSED
	jz	setPoints
	mov	ax, MSG_SPLINE_CLOSE_CURVE
	call	ChartObjectCallGrObjWard

setPoints:

	;
	; Make the spline's vis bounds correspond to the GrObject's
	; bounds. 
	;
	
	mov	ax, MSG_GOVG_VIS_BOUNDS_SETUP
	call	ChartObjectCallGrObj

	;
	; Set polyline points
	;

	mov	dx, size SplineSetPointParams
	sub	sp, dx
	mov	bx, sp
	movdw	ss:[bx].SSPP_points, ss:[bp].CPP_points, ax
	mov	ax, ss:[bp].CPP_numPoints
	mov	ss:[bx].SSPP_numPoints, ax
	mov	ss:[bx].SSPP_flags, SSPT_POINT shl offset SSPF_TYPE

	push	bp
	mov	bp, bx			; SplineSetPointParams
	mov	ax, MSG_SPLINE_SET_POINTS
	call	ChartObjectCallGrObjWardStack
	pop	bp
	add	sp, dx

	call	ChartObjectEndCreateOrUpdate

	.leave
	ret
ChartObjectCreateOrUpdatePolyline	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create or update a text object

CALLED BY:	UTILITY (many chart objects)

PASS:		*ds:si - chart object
		ss:bp - CreateTextParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/18/92   	Initial version.
	witt	11/12/93	DBCS-ized string tests

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateText	proc far
	uses	cx,dx,di

	class	ChartObjectClass

	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	;
	; If the text is NULL, and there's no grobj, then bail!
	;

	DerefChartObject ds, si, di
	tst	ds:[di].COI_grobj.handle
	jnz	continue

	les	di, ss:[bp].CTP_text
	LocalIsNull	es:[di]
	jz	done

	;
	; create object.  Make it a MultTextGuardianClass, even though
	; it's really not an object that the user can edit, and it's
	; larger, because there are problems with cutting/pasting
	; single-attribute text objects.  
	;

continue:
	mov	cx, segment MultTextGuardianClass
	mov	dx, offset MultTextGuardianClass
	call	ChartObjectCreateOrUpdateGrObj

	call	ChartObjectCreateOrUpdateTextCommon


	call	ChartObjectEndCreateOrUpdate
done:
	.leave
	ret
ChartObjectCreateOrUpdateText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text for the chart object's text object

CALLED BY:	ChartObjectCreateOrUpdateText,
		ChartObjectCreateOrUpdateMultText

PASS:		*ds:si - ChartObject
		ss:[bp] - CreateTextParams

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateTextCommon	proc near
	uses	ax,cx,dx,bp
	.enter

EC <	call	ECCheckChartObjectDSSI	>
	ECCheckFlags	ss:[bp].CTP_flags, CreateTextFlags


	;
	; If newly creating, set char and para attrs, if we should
	;
	test	ss:[bp].CGOP_flags, mask CGOF_CREATED
	jz	afterAttrs

	test	ss:[bp].CTP_flags, mask CTF_USE_CHAR_AND_PARA_ATTRS
	jz	afterAttrs

	mov	ax, MSG_VIS_TEXT_SET_CHAR_ATTR
	mov	bx, ss:[bp].CTP_charAttr
	call	setAttr

	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTR
	mov	bx, ss:[bp].CTP_paraAttr
	call	setAttr

afterAttrs:
	;
	; Set the text, unless we're updating an existing object, 
	; and we have the CTF_SET_ON_CREATE flag set
	;

	test	ss:[bp].CGOP_flags, mask CGOF_CREATED
	jnz	created
	test	ss:[bp].CTP_flags, mask CTF_SET_ON_CREATE
	jnz	afterSetText

created:
	push	bp
	mov	dx, ss:[bp].CTP_text.segment
	mov	bp, ss:[bp].CTP_text.offset
	clr	cx				; C_NULL terminated string
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ChartObjectCallGrObjWard

	;
	; Select all the text, so that attribute changes take effect.
	;
		
	mov	ax, MSG_VIS_TEXT_SELECT_ALL
	call	ChartObjectCallGrObjWard
	pop	bp


afterSetText:

	;
	; See if we want to position this object according to custom
	; geometry. 
	;

	test	ss:[bp].CGOP_flags, mask CGOF_CUSTOM_BOUNDS
	jz	afterCustom

	call	SetTextCustomBounds

afterCustom:

	;	
	; Set the max height to either the X or Y size, if necessary.
	;


	test	ss:[bp].CTP_flags, mask CTF_MAX_HEIGHT
	jz	afterMax

	mov	cx, ss:[bp].CGOP_size.P_y
	test	ss:[bp].CGOP_flags, mask CGOF_ROTATED
	jz	setMax

	mov	cx, ss:[bp].CGOP_size.P_x
setMax:
	mov	ax, MSG_TG_SET_DESIRED_MAX_HEIGHT
	call	ChartObjectCallGrObj
	
	mov	ax, MSG_TG_SET_TEXT_GUARDIAN_FLAGS
	mov	cl, mask TGF_ENFORCE_DESIRED_MAX_HEIGHT
	clr	dl
	call	ChartObjectCallGrObj

afterMax:

	;
	; update ward's vis bounds to match the new object dimensions
	;

	mov	ax, MSG_GOVG_VIS_BOUNDS_SETUP
	call	ChartObjectCallGrObj


	;
	; Only do centering,line mask, and area attrs, if text newly
	; created.

	test	ss:[bp].CGOP_flags, mask CGOF_CREATED
	jz	done

	test	ss:[bp].CTP_flags, mask CTF_CENTERED
	jz	afterCentered

	;
	; center the text
	;

	push	bp,dx
	mov	dx, size VisTextSetParaAttrAttributesParams
	sub	sp, dx
	mov	bp, sp
	clrdw	ss:[bp].VTSPAAP_range.VTR_start
	movdw	ss:[bp].VTSPAAP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSPAAP_bitsToSet, J_CENTER shl \
				offset	VTPAA_JUSTIFICATION 
	clr	ss:[bp].VTSPAAP_bitsToClear
	
	mov	ax, MSG_VIS_TEXT_SET_PARA_ATTRIBUTES
	call	ChartObjectCallGrObjWardStack
	add	sp, size VisTextSetParaAttrAttributesParams
	pop	bp,dx

afterCentered:

	;
	; Make it so the text is transparent, no border.
	;

	mov	ax, MSG_GO_SET_LINE_MASK
	mov	cx, SDM_0
	call	ChartObjectCallGrObj

	mov	ax, MSG_GO_SET_TRANSPARENCY
	mov	cl, TRUE
	call	ChartObjectCallGrObj

done:
	.leave
	ret

setAttr:
	; set either the CHAR or PARA attrs for this text object
	; ax - message #
	; ss:bx - attributes structure
	; *ds:si - chart object

CheckHack <size VisTextSetCharAttrParams eq size VisTextSetParaAttrParams>
CheckHack <offset VTSCAP_range eq offset VTSPAP_range		>
CheckHack <offset VTSCAP_charAttr eq offset VTSPAP_paraAttr	>

	push	bp, dx
	mov	dx, size VisTextSetCharAttrParams
	sub	sp, dx
	mov	bp, sp
	clrdw	ss:[bp].VTSCAP_range.VTR_start
	movdw	ss:[bp].VTSCAP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSCAP_charAttr.segment, ss
	mov	ss:[bp].VTSCAP_charAttr.offset, bx
	call	ChartObjectCallGrObjWardStack
	add	sp, size VisTextSetCharAttrParams
	pop	bp, dx
	retn

ChartObjectCreateOrUpdateTextCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextCustomBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set some custom bounds for this text object

CALLED BY:	ChartObjectCreateOrUpdateTextCommon

PASS:		ss:bp - CreateTextParams
		*ds:si - chart object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextCustomBounds	proc near
	uses	ax,bx,cx,dx,di,si,bp

	class	ChartObjectClass

	.enter

	ECCheckFlags	ss:[bp].CTP_anchor, TextAnchorFlags

	DerefChartObject ds, si, di
	movOD	cxdx, ds:[di].COI_grobj
	call	UtilGetGrObjTextBounds		; cx, dx - text bounds

	movP	ss:[bp].CGOP_size, cxdx

	;
	; Adjust the position based on the anchor type
	;


	;
	; First, adjust the horizontal coordinate
	;

	mov	di, {word} ss:[bp].CTP_anchor
	and	di, mask TAF_H
	cmp	di, MMT_MIN shl offset TAF_H
	je	doVertical
	cmp	di, MMT_CENTER shl offset TAF_H
	jne	subtractCX
	shr	cx

subtractCX:
	sub	ss:[bp].CGOP_position.P_x, cx

doVertical:
	mov	di, {word} ss:[bp].CTP_anchor
	and	di, mask TAF_V
	cmp	di, MMT_MIN shl offset TAF_V
	je	done
	cmp	di, MMT_CENTER shl offset TAF_V
	jne	subtractDX
	shr	dx

subtractDX:
	sub	ss:[bp].CGOP_position.P_y, dx

done:

	;
	; Now, set the bounds of the thing
	;
	call	ChartObjectSetGrObjBoundsCommon

	.leave
	ret
SetTextCustomBounds	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateMultText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a multiple-styles text object

CALLED BY:

PASS:		*ds:si - ChartObject to create text for
		ss:bp - CreateTextParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateMultText	proc far
	uses	cx,dx

	class	ChartObjectClass

	.enter

EC <	call	ECCheckChartObjectDSSI		>	 

	; create object

	mov	cx, segment MultTextGuardianClass
	mov	dx, offset MultTextGuardianClass
	call	ChartObjectCreateOrUpdateGrObj

	call	ChartObjectCreateOrUpdateTextCommon

	call	ChartObjectEndCreateOrUpdate

	.leave
	ret
ChartObjectCreateOrUpdateMultText	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateStandardLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create a standard line

CALLED BY:	UTILITY

PASS:		ax,bx - one end
		cx,dx - the other
		*ds:si - chart object

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateStandardLine	proc far
	uses	cx,dx,bp
	.enter

EC <	call	ECCheckChartObjectDSSI		>

	sub	sp, size CreateGrObjParams
	mov	bp, sp

	clr	ss:[bp].CGOP_flags

	SortRegs	ax, cx
	SortRegs	bx, dx

	movP	ss:[bp].CGOP_position, axbx

	sub	cx, ax
	sub	dx, bx
	mov	ss:[bp].CGOP_size.P_x, cx
	mov	ss:[bp].CGOP_size.P_y, dx

	; Set move/resize locks

	mov	ss:[bp].CGOP_locks, STANDARD_CHART_GROBJ_LOCKS

	mov	cx, segment LineClass
	mov	dx, offset LineClass
	call	ChartObjectCreateOrUpdateGrObj

	call	ChartObjectEndCreateOrUpdate

	add	sp, size CreateGrObjParams



	.leave
	ret
ChartObjectCreateOrUpdateStandardLine	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectEndCreateOrUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend the grobj

CALLED BY:	internal

PASS:		*ds:si - chart object (grobj od is in instance data)

RETURN:		nothing 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectEndCreateOrUpdate	proc near
	uses	ax
	class	ChartObjectClass 
	.enter

EC <	call	ECCheckChartObjectDSSI	>

	;
	; notify the grobj that it's now ready for action
	;

	mov	ax, MSG_GO_NOTIFY_GROBJ_VALID
	call	ChartObjectCallGrObj

	mov	ax, MSG_GO_UNSUSPEND_ACTION_NOTIFICATION
	call	ChartObjectCallGrObj
	.leave
	ret
ChartObjectEndCreateOrUpdate	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectFindGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the OD of the grobj for this chart object

PASS:		*ds:si	= ChartObjectClass object
		ds:di	= ChartObjectClass instance data
		es	= segment of ChartObjectClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectFindGrObj	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_FIND_GROBJ
	.enter
	movOD	cxdx, ds:[di].COI_grobj

	.leave
	ret
ChartObjectFindGrObj	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a multiple-styles text object

CALLED BY:

PASS:		*ds:si - ChartObject to create text for
		ss:bp - CreateArcParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateArc	proc far
	uses	cx,dx

	class	ChartObjectClass

	.enter

EC <	call	ECCheckChartObjectDSSI	> 

	;
	; create object
	;

	mov	cx, segment ArcClass
	mov	dx, offset ArcClass
	call	ChartObjectCreateOrUpdateGrObj
	
	test	ss:[bp].CGOP_flags, mask CGOF_CREATED
	jz	afterAttrs

	call	SetGrObjAttributes

afterAttrs:

	mov	ax, MSG_ARC_SET_START_ANGLE
	movwwf	dxcx, ss:[bp].CAP_startAngle
	call	ChartObjectCallGrObj

	mov	ax, MSG_ARC_SET_END_ANGLE
	movwwf	dxcx, ss:[bp].CAP_endAngle
	call	ChartObjectCallGrObj

	call	ChartObjectEndCreateOrUpdate

	.leave
	ret
ChartObjectCreateOrUpdateArc	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectCreateOrUpdateGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GROUP object

CALLED BY:	UTILITY

PASS:		*ds:si - chart object
		ss:bp - CreateGroupParams

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartObjectCreateOrUpdateGroup	proc far
	uses	cx, dx
	.enter
	mov	cx, segment GroupClass
	mov	dx, offset GroupClass
	call	ChartObjectCreateOrUpdateGrObj

	call	ChartObjectEndCreateOrUpdate
	.leave
	ret
ChartObjectCreateOrUpdateGroup	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectSendToGrObj
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartObjectClass object
		ds:di	- ChartObjectClass instance data
		es	- segment of ChartObjectClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectSendToGrObj	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_SEND_TO_GROBJ
	uses	ax,cx
	.enter
	mov_tr	ax, cx
	call	ChartObjectCallGrObj
	.leave
	ret
ChartObjectSendToGrObj	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGetGrObjText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartObjectClass object
		ds:di	- ChartObjectClass instance data
		es	- segment of ChartObjectClass

RETURN:		^lcx:dx - OD of grobj text object (GOAM's text)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectGetGrObjText	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_GET_GROBJ_TEXT
	uses	ax,bp
	.enter
	mov	ax, MSG_CHART_BODY_GET_GOAM_TEXT
	call	UtilCallChartBody
	.leave
	ret
ChartObjectGetGrObjText	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartObjectGetTopGrObjPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	update the top grobj draw position if this one's higher.

PASS:		*ds:si	- ChartObjectClass object
		ds:di	- ChartObjectClass instance data
		es	- segment of ChartObjectClass

RETURN:		cx	- position of grobj

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartObjectGetTopGrObjPosition	method	dynamic	ChartObjectClass, 
					MSG_CHART_OBJECT_GET_TOP_GROBJ_POSITION

		.enter

		movdw	cxdx, ds:[di].COI_grobj
		jcxz	done
		mov	ax, MSG_GB_FIND_GROBJ
		call	UtilCallChartBody
EC <		ERROR_NC OBJECT_NOT_FOUND				>
done:

		.leave
		ret
ChartObjectGetTopGrObjPosition	endm

