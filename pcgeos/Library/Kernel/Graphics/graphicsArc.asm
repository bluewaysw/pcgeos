COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		graphicsArc.asm

AUTHOR:		Ted H. Kim, 7/6/89

ROUTINES:
	Name			Description
	----			-----------
    GLB	GrDrawArc		Bounded-arc & angles drawing routine
    GLB	GrFillArc		Bounded-arc & angles filling routine
    GLB	GrDrawArc3Point		3-Point arc drawing routine
    GLB	GrFillArc3Point		3-Point arc drawing routine
    GLB	GrDrawArc3PointTo	3-Point arc drawing, 1st point is current pos
    GLB	GrFillArc3PointTo	3-Point arc filling, 1st point is current pos
    GLB	GrDrawRelArc3PointTo	3-Point arc drawing, other 2 pts are relative
    GLB	GrFillRelArc3PointTo	3-Point arc filling, other 2 pts are relative

    INT	Arc3PointSetCurPos	Sets the current position for this type of arc
    INT	Arc3PointToSetCurPos	Sets the current position for this type of arc
    INT	RelArc3PointToSetCurPos	Sets the current position for this type of arc

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/89		Initial revision
	jim	8/89		moved all support routines to kernel lib
	jim	10/89		added new graphics string support
	don	12/91		added new functions, changed everything

DESCRIPTION:
	Contains routines for drawing both arcs and pies.

	$Id: graphicsArc.asm,v 1.1 97/04/05 01:12:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsArc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws an arc along the ellipse that is specified by a
		bounding box, and starting and ending angles.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		DS:SI	= ArcParams

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Ted	5/89		Initial version
		jim	10/89		added new graphics string support
		jim	1/91		moved code back from klib
		Don	8/91		Use new ellipse code & parameter passing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawArc	proc	far
		mov	ss:[TPD_callVector].segment, size ArcParams
		mov	ss:[TPD_dataBX], handle GrDrawArcReal
		mov	ss:[TPD_dataAX], offset GrDrawArcReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawArc	endp
CopyStackCodeXIP	ends

else

GrDrawArc	proc	far
	FALL_THRU	GrDrawArcReal
GrDrawArc	endp

endif


GrDrawArcReal	proc	far
		call	EnterGraphics
		mov	ax, ss:[bp].EG_ds	; ArcParams => AX:SI
		call	ArcSetCurPos		; set the current position
		jc	arcToGS			; draw an arc to a GString
		call	TrivialRejectFar	; check null window, clip

		; Perform normal screen drawing tasks
		;
		mov	di, offset SetupArcLow
		jmp	getCloseAndDraw
GrDrawArcReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a pie from an ellipse that is centered at the origin.

CALLED BY:	GLOBAL

PASS:		DI	= Gstate handle
		DS:SI	= ArcParams

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Ted	5/89		Initial version
		jim	10/89		added new graphics string support
		jim	1/91		moved code back from klib
		Don	8/91		Use new ellipse code & parameter passing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrFillArc	proc	far
		mov	ss:[TPD_callVector].segment, size ArcParams
		mov	ss:[TPD_dataBX], handle GrFillArcReal
		mov	ss:[TPD_dataAX], offset GrFillArcReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrFillArc	endp
CopyStackCodeXIP	ends

else

GrFillArc	proc	far
	FALL_THRU	GrFillArcReal
GrFillArc	endp

endif

GrFillArcReal	proc	far
		call	EnterGraphicsFill
		mov	ax, ss:[bp].EG_ds	; ArcParams => AX:SI
		call	ArcSetCurPos		; set the current position
		jc	doGString		; if carry, deal with GString
		call	TrivialRejectFar	; check bogus window, clip

		; Peform normal screen drawing operations
		;
		mov	di, offset SetupArcLow
		jmp	getCloseAndFill

		; Deal with drawing to a GString or Path
		;
doGString:
		mov	dx, (GSSC_FLUSH shl 8) or GR_FILL_ARC 
		jz	doGString2		; if really GString, jump
arcToGS		label	near
		mov	dx, (GSSC_FLUSH shl 8) or GR_DRAW_ARC 
doGString2:
		mov	ds, ax			; ArcParams => DS:SI
		mov_tr	ax, dx			; opcode & control flags => AX
		mov	cx, size ArcParams 	; # of bytes to store
		call	GSStore			; store it all away
		jmp	ExitGraphicsGseg
GrFillArcReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawArc3Point
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a circular arc, given three points along the arc;
		both endpoints and any other point on the arc.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		DS:SI	= ThreePointArcParams

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawArc3Point	proc	far
		mov	ss:[TPD_callVector].segment, size ThreePointArcParams
		mov	ss:[TPD_dataBX], handle GrDrawArc3PointReal
		mov	ss:[TPD_dataAX], offset GrDrawArc3PointReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawArc3Point	endp
CopyStackCodeXIP	ends

else

GrDrawArc3Point	proc	far
	FALL_THRU	GrDrawArc3PointReal
GrDrawArc3Point	endp

endif

GrDrawArc3PointReal	proc	far
		call	EnterGraphics
		mov	ax, ss:[bp].EG_ds	; ThreePointArcParams => AX:SI
		call	Arc3PointSetCurPos	; set the current position
		jc	arc3PointToGS		; if carry, deal with GString
		call	TrivialRejectFar

		; Perform normal screen drawing tasks
		;
		mov	di, offset SetupArc3PointLow
getCloseAndDraw	label	near
		push	ds
		mov	ds, ax
		mov	bp, ds:[si].AP_close	; ArcCloseType => BP
		pop	ds
		call	DrawArcEllipseLow
		jmp	ExitGraphics
GrDrawArc3PointReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillArc3Point
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a circular arc, defined by three points: the endpoints,
		and one other point along the arc.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		DS:SI	= ThreePointArcParams

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrFillArc3Point	proc	far
		mov	ss:[TPD_callVector].segment, ThreePointArcParams
		mov	ss:[TPD_dataBX], handle GrFillArc3PointReal
		mov	ss:[TPD_dataAX], offset GrFillArc3PointReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrFillArc3Point	endp
CopyStackCodeXIP	ends

else

GrFillArc3Point	proc	far
	FALL_THRU	GrFillArc3PointReal
GrFillArc3Point	endp

endif

GrFillArc3PointReal	proc	far
		call	EnterGraphicsFill
		mov	ax, ss:[bp].EG_ds	; ThreePointArcParams => AX:SI
		call	Arc3PointSetCurPos	; set the current position
		jc	doGString		; if carry, deal with GString
		call	TrivialRejectFar

		; Peform normal screen drawing operations
		;
		mov	di, offset SetupArc3PointLow
getCloseAndFill	label	near
		push	ds
		mov	ds, ax
		mov	bp, ds:[si].AP_close	; ArcCloseType => BP
		pop	ds
		call	FillArcEllipseLow	; call low-level routine
		jmp	ExitGraphics		; we're done

		; Deal with drawing to a GString or Path
		;
doGString:
		mov	dx, (GSSC_FLUSH shl 8) or GR_FILL_ARC_3POINT
		jz	doGString2		; if really GString, jump
arc3PointToGS	label	near
		mov	dx, (GSSC_FLUSH shl 8) or GR_DRAW_ARC_3POINT 
doGString2:
		mov	cx, size ThreePointArcParams ; # of bytes to store
arc3PtGSCommon	label	near
		mov	ds, ax			; ThreePointArcParams => DS:SI
		mov_tr	ax, dx			; opcode & control flags => AX
		call	GSStore			; store it all away
		jmp	ExitGraphicsGseg
GrFillArc3PointReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawArc3PointTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a circular arc, given two points along the arc:
		the other endpoint and any other point on the arc.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		DS:SI	= ThreePointArcToParams structure

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

Revision HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawArc3PointTo	proc	far
		mov	ss:[TPD_callVector].segment, size ThreePointArcToParams
		mov	ss:[TPD_dataBX], handle GrDrawArc3PointToReal
		mov	ss:[TPD_dataAX], offset GrDrawArc3PointToReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawArc3PointTo	endp
CopyStackCodeXIP	ends

else

GrDrawArc3PointTo	proc	far
	FALL_THRU	GrDrawArc3PointToReal
GrDrawArc3PointTo	endp

endif

GrDrawArc3PointToReal	proc	far
		call	EnterGraphics
		mov	ax, ss:[bp].EG_ds	; ThreePointArcToParams > AX:SI
		jc	arc3PointToToGS		; draw 3-point arc to GString
		call	TrivialRejectFar

		; Perform normal screen drawing tasks
		;
		mov	di, offset SetupArc3PointToLow
		push	ds
		mov	ds, ax
		mov	bp, ds:[si].AP_close	; ArcCloseType => BP
		pop	ds
		call	DrawArcEllipseLow
		jmp	ExitGraphics
GrDrawArc3PointToReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillArc3PointTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a circular arc defined by three points: the endpoints,
		and one

CALLED BY:	GLOBAL

PASS:		DI	= GState
		ds:si	= ThreePointArcToParams

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrFillArc3PointTo	proc	far
		mov	ss:[TPD_callVector].segment, size ThreePointArcToParams
		mov	ss:[TPD_dataBX], handle GrFillArc3PointToReal
		mov	ss:[TPD_dataAX], offset GrFillArc3PointToReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrFillArc3PointTo	endp
CopyStackCodeXIP	ends

else

GrFillArc3PointTo	proc	far
	FALL_THRU	GrFillArc3PointToReal
GrFillArc3PointTo	endp

endif

GrFillArc3PointToReal	proc	far
		call	EnterGraphicsFill
		mov	ax, ss:[bp].EG_ds	; ThreePointArcToParams > AX:SI
		jc	doGString		; if carry, deal with GString
		call	TrivialRejectFar

		; Peform normal screen drawing operations
		;
		mov	di, offset SetupArc3PointToLow
		push	ds
		mov	ds, ax
		mov	bp, ds:[si].AP_close	; ArcCloseType => BP
		pop	ds
		call	FillArcEllipseLow	; call low-level routine
		jmp	ExitGraphics		; we're done

		; Deal with drawing to a GString or Path
		;
doGString:
		mov	dx, (GSSC_FLUSH shl 8) or GR_FILL_ARC_3POINT_TO
		jz	arc3PointToToGSCommon
arc3PointToToGS	label	near
		mov	dx, (GSSC_FLUSH shl 8) or GR_DRAW_ARC_3POINT_TO
arc3PointToToGSCommon	label	near
		call	Arc3PointToSetCurPos	; set the current position
		mov	cx, size ThreePointArcToParams
		jmp	arc3PtGSCommon
GrFillArc3PointToReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRelArc3PointTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a circular arc relative to the current point given two
		additional points: the other endpoint & any other point on
		the arc, both described in relative coordinates.

CALLED BY:	GLOBAL

PASS:		DI	= GState
		DS:SI	= ThreePointArcRelToParams

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawRelArc3PointTo	proc	far
		mov	ss:[TPD_callVector].segment, \
				 size ThreePointRelArcToParams
		mov	ss:[TPD_dataBX], handle GrDrawRelArc3PointToReal
		mov	ss:[TPD_dataAX], offset GrDrawRelArc3PointToReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawRelArc3PointTo	endp
CopyStackCodeXIP	ends

else

GrDrawRelArc3PointTo	proc	far
	FALL_THRU	GrDrawRelArc3PointToReal
GrDrawRelArc3PointTo	endp

endif

GrDrawRelArc3PointToReal	proc	far
		call	EnterGraphics
		mov	ax, ss:[bp].EG_ds	; ThreePointArcToParams > AX:SI
		jc	drawRelArc3PointToGS	; if carry, deal with GString
		call	TrivialRejectFar

		; Perform normal screen drawing tasks
		;
		mov	di, offset SetupRelArc3PointToLow
		push	ds
		mov	ds, ax
		mov	bp, ds:[si].AP_close	; ArcCloseType => BP
		pop	ds
		call	DrawArcEllipseLow
		jmp	ExitGraphics

		; Deal with drawing to a GString
		;
drawRelArc3PointToGS	label	near
		call	RelArc3PointToSetCurPos	; set the current position
		mov	dx, (GSSC_FLUSH shl 8) or GR_DRAW_REL_ARC_3POINT_TO
		jmp	arc3PointToToGSCommon
GrDrawRelArc3PointToReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Subroutines residing in the same segment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Arc3PointSetCurPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current position to be the ending position of
		a ThreePointArc

CALLED BY:	GrDrawArc3Point, GrFillArc3Point

PASS:		DS	= GState segment
		AX:SI	= ThreePointArcParams

RETURN:		Nothing

DESTROYED:	Nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/12/91	Initial version
		jim	12/3/92		Rewrote for WWFixed version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Arc3PointSetCurPos	proc	near
		pushf
		uses	bx,cx,dx,es
		.enter
	
		mov	es, ax			; parameters => ES:SI
		mov	bx, offset TPAP_point1
		tst	es:[si].TPAP_close	; ACT_OPEN, or closed
		jz	setPoint
		mov	bx, offset TPAP_point3
setPoint:		
		movwwf	dxcx, es:[si][bx].PF_x
		mov	ax, es:[si][bx].PF_y.WWF_frac
		mov	bx, es:[si][bx].PF_y.WWF_int
		call	SetDocWWFPenPos		; set new pen position
		mov	ax, es			; restore AX

		.leave
		popf
		ret
Arc3PointSetCurPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Arc3PointToSetCurPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current position to be the ending coordinate-pair
		of a three-point arc-to

CALLED BY:	GrDrawArc3PointTo, GrFillArc3PointTo

PASS:		DS	= GState segment
		AX:SI	= ThreePointArcToParams

RETURN:		Nothing

DESTROYED:	Nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/12/91	Initial version
		jim	12/3/92		Rewrote for WWFixed version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Arc3PointToSetCurPos	proc	near
		pushf
		uses	bx,cx,dx,es
		.enter
	
		mov	es, ax			; parameters => ES:SI
		tst	es:[si].TPATP_close	; ACT_OPEN, or closed
		jz	done
		movwwf	dxcx, es:[si].TPATP_point3.PF_x
		movwwf	bxax, es:[si].TPATP_point3.PF_y
		call	SetDocWWFPenPos		; set new pen position
done:
		mov	ax, es			; restore AX
		.leave
		popf
		ret
Arc3PointToSetCurPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RelArc3PointToSetCurPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current position to be the ending coordinate-pair
		of a relative three-point arc-to

CALLED BY:	GrDrawRelArc3PointTo, GrFillRelArc3PointTo

PASS:		DS	= GState segment
		AX:SI	= ThreePointArcRelToParams

RETURN:		Nothing

DESTROYED:	Nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RelArc3PointToSetCurPos	proc	near
		pushf
		uses	bx,cx,dx,es
		.enter
	
		mov	es, ax			; parameters => ES:SI
		tst	es:[si].TPRATP_close	; ACT_OPEN, or closed
		jz	done
		movwwf	dxcx, es:[si].TPRATP_delta3.PF_x
		movwwf	bxax, es:[si].TPRATP_delta3.PF_y
		call	SetRelDocPenPos		; set new pen position
done:
		mov	ax, es			; restore AX
		.leave
		popf
		ret
RelArc3PointToSetCurPos	endp

GraphicsArc	ends


