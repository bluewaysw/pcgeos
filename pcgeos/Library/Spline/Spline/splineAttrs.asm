COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineAttrs.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

DESCRIPTION:
	

	$Id: splineAttrs.asm,v 1.1 97/04/07 11:09:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineAttrCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineApplyAttributesToGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/27/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineApplyAttributesToGState	method	dynamic	VisSplineClass, 
					MSG_SPLINE_APPLY_ATTRIBUTES_TO_GSTATE
	uses	ax,cx,dx,bp

	.enter

	push	bp
	call	SplineMethodCommonReadOnly
	pop	di


	; set normal draw mode
	mov	al, MM_COPY
	call	GrSetMixMode


	mov	si, es:[bp].VSI_lineAttr
	mov	si, ds:[si]
	call	GrSetLineAttr
	mov	si, es:[bp].VSI_areaAttr
	mov	si, ds:[si]
	call	GrSetAreaAttr

	call	SplineEndmCommon
	.leave
	ret
SplineApplyAttributesToGState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetDefaultLineAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Initialize the line attributes data structure with the
		default attributes.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.
	SH	5/05/94		XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultSplineLineAttrs	LineAttr <CF_INDEX,
	<C_BLACK,0,0>,
	SDM_100,
	CMT_DITHER shl offset CMM_MAP_TYPE,
	LE_BUTTCAP,
	LJ_BEVELED,
	LS_SOLID,
	<0,1>>

SplineSetDefaultLineAttrs	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_DEFAULT_LINE_ATTRS
	uses	ax,cx,dx
	.enter

FXIP<	push	bx, si					>
FXIP<	mov	bx, cs					>
FXIP<	mov	si, offset DefaultSplineLineAttrs	>
FXIP<	mov	cx, size LineAttr			>
FXIP<	call	SysCopyToStackBXSI			>
FXIP<	mov	cx, bx					>
FXIP<	mov	dx, si					>
FXIP<	pop	bx, si
NOFXIP<	mov	cx, cs					>
NOFXIP<	mov	dx, offset DefaultSplineLineAttrs	>
	mov	ax, MSG_SPLINE_SET_LINE_ATTRS
	call	ObjCallInstanceNoLock
FXIP<	call	SysRemoveFromStack			>

	.leave
	ret
SplineSetDefaultLineAttrs	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetDefaultAreaAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefaultSplineAreaAttrs	AreaAttr <CF_INDEX,
	<C_BLACK,0,0>,
	SDM_100,
	CMT_DITHER shl offset CMM_MAP_TYPE>

SplineSetDefaultAreaAttrs	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_DEFAULT_AREA_ATTRS
	uses	ax,cx,dx
	.enter


FXIP<	push	bx, si					>
FXIP<	mov	bx, cs					>
FXIP<	mov	si, offset DefaultSplineAreaAttrs	>
FXIP<	mov	cx, size AreaAttr			>
FXIP<	call	SysCopyToStackBXSI			>
FXIP<	mov	cx, bx					>
FXIP<	mov	dx, si					>
FXIP<	pop	bx, si
NOFXIP<	mov	cx, cs					>
NOFXIP<	mov	dx, offset DefaultSplineAreaAttrs	>
	mov	ax, MSG_SPLINE_SET_AREA_ATTRS
	call	ObjCallInstanceNoLock
FXIP<	call	SysRemoveFromStack			>

	.leave
	ret
SplineSetDefaultAreaAttrs	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetLineAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		cx:dx 	= fptr to a LineAttr structure
			  (must be fptr for XIP'ed geodes)

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetLineAttrs	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_LINE_ATTRS
	uses	ax,cx,dx,bp
	.enter

if FULL_EXECUTE_IN_PLACE
	;
	; Validate that cx:dx is not pointing to a movable code segment
	;	
EC<	push	bx, si							>
EC<	movdw	bxsi, cxdx						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
endif

	test	ds:[di].VSI_state, mask SS_HAS_ATTR_CHUNKS
	jz	done

	call	SplineMethodCommon
	mov	di, es:[bp].VSI_lineAttr
	mov	di, ds:[di]

	push	ds, es
	segmov	es, ds
	mov	ds, cx
	mov	si, dx
	mov	cx, size LineAttr
	rep	movsb
	pop	ds, es

	call	SplineEndmCommon
done:
	.leave
	ret
SplineSetLineAttrs	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetAreaAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		cx:dx 	= fptr to a AreaAttr structure
			  (must be fptr for XIP'ed geodes)
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetAreaAttrs	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_AREA_ATTRS
	uses	ax,cx,dx,bp
	.enter

if FULL_EXECUTE_IN_PLACE
	;
	; Validate that cx:dx is not pointing to a movable code segment
	;	
EC<	push	bx, si							>
EC<	movdw	bxsi, cxdx						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<	pop	bx, si							>
endif

	test	ds:[di].VSI_state, mask SS_HAS_ATTR_CHUNKS
	jz	done

	call	SplineMethodCommon
	mov	di, es:[bp].VSI_areaAttr
	mov	di, ds:[di]
	push	ds, es
	segmov	es, ds
	mov	ds, cx
	mov	si, dx
	mov	cx, size AreaAttr
	rep	movsb
	pop	ds, es

	call	SplineEndmCommon
done:
	.leave
	ret
SplineSetAreaAttrs	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

METHOD:		SplineSetLineWidth, MSG_SPLINE_SET_LINE_WIDTH

DESCRIPTION:	Set the line width for all subsequent draws

PASS:		*ds:si - VisSpline object
		ds:di  - VisSPline instance data
		dx.cx  - line width (WWFixed)

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
        Name	Date		Description
        ----	----		-----------
        CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSetLineWidth  method dynamic VisSplineClass, 
       				MSG_SPLINE_SET_LINE_WIDTH
       uses	ax, cx, dx, bp
       .enter	

	call	SplineMethodCommon 
	mov	ax, UT_LINE_ATTR
	call	SplineInitUndo
	mov	di, es:[bp].VSI_lineAttr
	mov	di, ds:[di]
	movdw	bxax, dxcx		; bxax is NEW width
	xchg	cx, ds:[di].LA_width.WWF_frac
	xchg	dx, ds:[di].LA_width.WWF_int
	cmpdw	bxax, dxcx		; compare NEW, OLD

; If NEW > OLD, recalc vis bounds BEFORE invalidating, 
; otherwise vice versa. 

	jg	recalcThenInval
	call	SplineInvalidate
	call	SplineRecalcVisBounds
	jmp	done
recalcThenInval:
	call	SplineRecalcVisBounds
	call	SplineInvalidate
done:
	call	SplineEndmCommon 
	.leave
	ret
SplineSetLineWidth	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the line width from my instance data

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.

RETURN:		dx.cx - line width (WWFixed)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/15/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetLineWidth	method	dynamic	VisSplineClass, 
						MSG_SPLINE_GET_LINE_WIDTH
	mov	bx, offset VSI_lineAttr
	mov	cx, offset LA_width
	mov	dx, size LA_width
	GOTO	SplineGetAttrCommon
SplineGetLineWidth	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetLineAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetLineAttrs	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_LINE_ATTRS
	uses	ax,cx,dx,bp
	.enter
	call	SplineMethodCommonReadOnly
	mov	si, es:[bp].VSI_lineAttr
	mov	si, ds:[si]
	push	es
	mov	es, cx
	mov	di, dx
	mov	cx, size LineAttr
	rep	movsb
	pop	es
	call	SplineEndmCommon 

	.leave
	ret
SplineGetLineAttrs	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetAreaAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetAreaAttrs	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_AREA_ATTRS
	uses	ax,cx,dx,bp
	.enter
	call	SplineMethodCommonReadOnly
	mov	si, es:[bp].VSI_areaAttr
	mov	si, ds:[si]
	push	es
	mov	es, cx
	mov	di, dx
	mov	cx, size AreaAttr
	rep	movsb
	pop	es
	call	SplineEndmCommon 

	.leave
	ret
SplineGetAreaAttrs	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetLineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the line style

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.
		cl 	= Line Style

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/17/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSetLineStyle	method	dynamic	VisSplineClass,  \
					MSG_SPLINE_SET_LINE_STYLE
	uses	ax, cx, dx, bp
	.enter	
	push	cx, dx
	mov	ax, UT_LINE_ATTR
	mov	bx, offset VSI_lineAttr
	mov	cx, size LA_style
	mov	dx, offset LA_style
	call	SplineSetAttrCommon 
	.leave
	ret
SplineSetLineStyle endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetLineMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the line mask

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetLineMask	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_LINE_MASK
	uses	ax,cx,dx,bp
	.enter
	push	cx, dx
	mov	ax, UT_LINE_ATTR
	mov	bx, offset VSI_lineAttr
	mov	cx, size LA_mask
	mov	dx, offset LA_mask
	call	SplineSetAttrCommon 

	.leave
	ret
SplineSetLineMask	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetLineMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/22/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetLineMask	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_LINE_MASK
	mov	bx, offset VSI_lineAttr
	mov	cx, offset LA_mask
	mov	dx, size LA_mask
	GOTO	SplineGetAttrCommon
SplineGetLineMask	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetLineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the spline's current line style

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.

RETURN:		cl = line style

DESTROYED:	dx 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/15/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetLineStyle	method	dynamic	VisSplineClass, 
						MSG_SPLINE_GET_LINE_STYLE
	mov	bx, offset VSI_lineAttr
	mov	cx, offset LA_style
	mov	dx, size LA_style
	GOTO	SplineGetAttrCommon
SplineGetLineStyle	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the line color of the spline object

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.
		cx, dx	= color values (see GrSetLineColor for
		description). 

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/17/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetLineColor	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_LINE_COLOR

	uses	ax, cx, dx, bp
	.enter	
	push	cx, dx
	mov	ax, UT_LINE_ATTR
	mov	bx, offset VSI_lineAttr
	mov	cx, size LA_color
	mov	dx, offset LA_color
	call	SplineSetAttrCommon
	.leave
	ret
SplineSetLineColor endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetLineColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	returns the line color

PASS:		*ds:si	= VisSpline`Class object
		ds:di	= VisSpline`Class instance data
		es	= Segment of VisSpline`Class.
		ax	= Method.

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/15/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetLineColor	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_LINE_COLOR
	mov	bx, offset VSI_lineAttr
	mov	cx, offset LA_color
	mov	dx, size LA_color
	GOTO	SplineGetAttrCommon
SplineGetLineColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the area color

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.
		ch 	= ColorFlag
		cl, dh, dl - color values
		(see GrSetAreaColor for more info).

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	???

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/17/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetAreaColor	method	dynamic	VisSplineClass, \
						MSG_SPLINE_SET_AREA_COLOR
	uses	bp
	.enter
	push	cx, dx
	mov	ax, UT_AREA_ATTR
	mov	bx, offset VSI_areaAttr
	mov	cx, size AA_color
	mov	dx, offset AA_color
	call	SplineSetAttrCommon 
	.leave
	ret
SplineSetAreaColor	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetAreaColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the spline's area color

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.

RETURN:		cx 	= area color

DESTROYED:	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/15/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetAreaColor	method	dynamic	VisSplineClass, 
						MSG_SPLINE_GET_AREA_COLOR
	mov	bx, offset VSI_areaAttr
	mov	cx, offset AA_color
	mov	dx, size AA_color
	GOTO	SplineGetAttrCommon
SplineGetAreaColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetAreaMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the mask for the area-fill routine.

PASS:		*ds:si 	= VisSplineClass instance data.
		ds:di 	= *ds:si
		ds:bx   = instance data of superclass
		es	= Segment of VisSplineClass class record
		ax	= Method number.
		cl 	- area fill mask

RETURN:		nothing

DESTROYED:	Nada.

REGISTER/STACK USAGE:
	Standard dynamic register file.

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/17/91 	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetAreaMask	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_AREA_MASK
	uses	ax, bp
	.enter
	push	cx, dx
	mov	ax, UT_AREA_ATTR
	mov	bx, offset VSI_areaAttr
	mov	cx, size AA_mask
	mov	dx, offset AA_mask
	call	SplineSetAttrCommon
	.leave
	ret
SplineSetAreaMask	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetAttrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:	SplineSetLineWidth, etc, etc, etc,.

PASS:		ax - UndoType (UT_LINE_ATTR or UT_AREA_ATTR)
		bx - offset in instance data to chunk handle of 
			attribute chunk
		cx - size of attribute data (1, 2 or 4 bytes)
		dx - offset into attribute chunk to attribute field
	
	ON STACK:
		dataCX	; words of data to store
		dataDX

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 7/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSetAttrCommon	proc near	\
			dataDX:word,
			dataCX:word	; (pushed first)

	class	VisSplineClass

	.enter

	test	ds:[di].VSI_state, mask SS_HAS_ATTR_CHUNKS
	jz	realExit
 
	; save stack frame and offset into instance data

	push	bp, bx
	call	SplineMethodCommon
	pop	di, bx			; stack frame, offset

	call	SplineInitUndo		; undo type in AL

EC <	call	ECSplineAttrChunks	>

	xchg	di, bp			; di <= instance data,
					; bp <= stack frame

	mov	bx, es:[bx][di]		; attr chunk handle

EC <	tst	bx				>
EC <	ERROR_Z	SPLINE_HAS_NO_ATTR_CHUNKS	>

	mov	bx, ds:[bx]		; deref attr chunk

EC <	xchg	bx, si			>
EC <	call	ECCheckLMemChunk	>
EC <	xchg	bx, si			>

	push	es, di			; instance ptr
	segmov	es, ds, di		
	mov	di, bx
	add	di, dx			; es:di - offset into attr chunk
	
	mov	ax, dataCX
	stosb
	dec	cx
	jz	done

	mov	al, ah
	stosb
	dec	cx
	jz	done

	mov	ax, dataDX
	stosb
	dec	cx
	jz	done

	mov	al, ah
	stosb
done:	
	pop	es, bp			; es:bp - instance ptr
	call	SplineInvalidate
	call	SplineEndmCommon 

realExit:
	.leave
	ret	@ArgSize
SplineSetAttrCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetAreaMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the spline's area mask

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		ax	= Method.

RETURN:		cx 	= area mask

DESTROYED:	dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/15/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetAreaMask	method	dynamic	VisSplineClass, 
						MSG_SPLINE_GET_AREA_MASK

	mov	bx, offset VSI_areaAttr
	mov	cx, offset AA_mask
	mov	dx, size AA_mask
	GOTO	SplineGetAttrCommon
SplineGetAreaMask	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetAttrCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the attribute  

CALLED BY:	SplineGet...

PASS:		bx - offset into VSI data wherein the pointer to the
		attribute resides

		cx - offset into the attribute chunk for the desired
		attribute. 

		dx - size of the attribute: 1-4 bytes

RETURN:		(depending on DX passed)
		cl, cx, or DX:CX as the RETURN value (if dword, DX is
		the HIGH word)

DESTROYED:	bx, di
		dx (if not returned)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/15/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetAttrCommon	proc	far
	uses	bp

	class	VisSplineClass

	.enter
	test	ds:[di].VSI_state, mask SS_HAS_ATTR_CHUNKS
	jz	noChunks

	call	SplineMethodCommonReadOnly

	mov	di, bx				; offset to lptr in
						; instance data. 
	mov	di, es:[bp][di]
	mov	di, ds:[di]
	add	di, cx		; now, ds:di points to the desired
				; attribute. 
	cmp	dx, 1
	je	movByte

; Move a dword even if only one word is needed (it's faster than
; checking!)

	movdw	dxcx, ds:[di]
done:
	call	SplineEndmCommon

realExit:
	.leave
	ret

movByte:
	mov	cl, {byte} ds:[di]
	jmp	done

noChunks:
	clrdw	cxdx
	jmp	realExit
SplineGetAttrCommon	endp


SplineAttrCode	ends
