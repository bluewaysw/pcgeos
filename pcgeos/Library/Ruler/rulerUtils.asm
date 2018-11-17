COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		rulerUtils.asm

AUTHOR:		Gene Anderson, Jun 17, 1991

ROUTINES:
	Name				Description
	----				-----------
	GetRulerTable			Get ptr to RulerScale entry to use
	SetMinTick			Set minimum tick size
	ScaleRulerToDraw		Scale ruler point to draw point

	CreateGState			create a GState
	DestroyGState			destroy a GState
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/17/91		Initial revision

DESCRIPTION:
	

	$Id: rulerUtils.asm,v 1.1 97/04/07 10:42:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerBasicCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerScaleDocToWinCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a ruler point in document coords to window coordinates
CALLED BY:	UTILITY

PASS:		*ds:si - VisRuler object
		dx:cx.ax - point to scale (DWFixed)
RETURN:		dx:cx.ax - scaled point (DWFixed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerScaleDocToWinCoords	proc	far	uses	si
	class	VisRulerClass
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset	;ds:si <- ptr to instance data
	;
	; See if any scaling in necessary.
	;
	tst	ds:[si].VRI_scale.WWF_frac
	jnz	doScale				;branch if fraction
	cmp	ds:[si].VRI_scale.WWF_int, 1
	je	done				;branch if (scale == 1.0)
doScale:
	push	bx, di
	mov	di, dx
	mov	dx, cx
	mov_tr	cx, ax				;didx.cx = multiplier
	movdw	bxax, ds:[si].VRI_scale
	clr	si				;sibx.ax = multiplicand
	call	GrMulDWFixed			;dxcx.bx = result
	mov_tr	ax, bx				;dxcx.ax = result
	pop	bx, di
done:
	.leave
	ret
RulerScaleDocToWinCoords	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RulerTransformDocToWin

DESCRIPTION:	Transform a position in document coordinates to a position
		in window coordinates

CALLED BY:	INTERNAL

PASS:
	*ds:si - ruler object
	dxcx.ax - position

RETURN:
	dxcx.ax - position

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/21/92		Initial version

------------------------------------------------------------------------------@
RulerTransformDocToWin	proc	far	uses di
	class	VisRulerClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	10$
	adddwf	dxcxax, ds:[di].VRI_origin
10$:
	call	RulerScaleDocToWinCoords
	.leave
	ret

RulerTransformDocToWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RulerScaleWinToDocCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale a ruler point in window coords to document coordinates
CALLED BY:	UTILITY

PASS:		*ds:si - VisRuler object
		dx:cx.ax - point to scale (DWFixed)
RETURN:		dx:cx.ax - scaled point (DWFixed)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RulerScaleWinToDocCoords	proc	far	uses	bx, si, bp
	class	VisRulerClass
	.enter

	mov_tr	bp, ax				;bp <- frac

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset	;ds:si <- ptr to instance data
	movdw	bxax, ds:[si].VRI_scale
	cmpdw	bxax, 0x00010000
	jz	done
	call	GrSDivDWFbyWWF
done:
	mov_tr	ax, bp
	.leave
	ret

RulerScaleWinToDocCoords	endp
COMMENT @----------------------------------------------------------------------

FUNCTION:	RulerTransformWinToDoc

DESCRIPTION:	Transform a position in window coordinates to a position
		in document coordinates

CALLED BY:	INTERNAL

PASS:
	*ds:si - ruler object
	dxcx.ax - position

RETURN:
	dxcx.ax - position

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/21/92		Initial version

------------------------------------------------------------------------------@
if 0
RulerTransformWinToDoc	proc	far	uses di
	class	VisRulerClass
	.enter

	call	RulerScaleWinToDocCoords

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VRI_rulerAttrs, mask VRA_IGNORE_ORIGIN
	jnz	10$
	subdwf	dxcxax, ds:[di].VRI_origin
10$:
	.leave
	ret

RulerTransformWinToDoc	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRulerTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get pointer to RulerScale entry to use
CALLED BY:	RulerSetupCommon()

PASS:		*ds:si - VisRuler object
RETURN:		cs:bx - ptr to RulerScale entry to use
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRulerTable	proc	near
	uses	si
	class	VisRulerClass
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset	;ds:si <- ptr to instance data

	push	ax
	mov	bl, ds:[si].VRI_type		;bl <- VisRulerType
	cmp	bl, VRT_DEFAULT
	jnz	gotType
	call	LocalGetMeasurementType
	mov	bl, VRT_INCHES
	cmp	al, MEASURE_US
	jz	gotType
	mov	bl, VRT_CENTIMETERS
gotType:
	pop	ax
	clr	bh
	shl	bx, 1
	mov	bx, cs:rulerTables[bx]

	.leave
	ret
GetRulerTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetMinTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set minimum tick size based on ruler type and scale factor
CALLED BY:	RulerSetupCommon()

PASS:		cs:bx - ptr to RulerScale structure
		*ds:si - VisRuler object
RETURN:		dl - minimum tick size
		ax - minimum label increment
DESTROYED:	dh

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetMinTick	proc	near
	uses	bx, cx, di, si
	class	VisRulerClass
	.enter

	mov	si, ds:[si]
	add	si, ds:[si].VisRuler_offset	;ds:si <- ptr to instance data

	mov	dl, ds:[si].VRI_minIncrement	;dl <- suggested minimum tick
	lea	di, cs:[bx].RS_minTicks		;cs:di <- ptr to TickScale table
	push	cs:[bx].RS_intervalValue
	mov	cx, NUM_MIN_TICKS		;cx <- # of TickScale entries
	mov	bx, ds:[si].VRI_scale.WWF_frac
	mov	ax, ds:[si].VRI_scale.WWF_int	;ax.bx <- scale factor
	pop	si				;si <- default interval value
tickLoop:
	;
	; See if this entry is relevant based on tick size
	;
	mov	dh, cs:[di].TS_incType		;dh <- minimum tick for scale
	cmp	dl, dh				;our tick size larger?
	ja	tickOK				;branch if already larger
	;
	; See if this entry is relevant based on scale factor
	;
	cmp	ax, cs:[di].TS_minScale.WWF_int
	ja	tickOK				;branch if our scale larger
	jb	tickNotOK			;branch if our scale smaller
	cmp	bx, cs:[di].TS_minScale.WWF_frac
	ja	tickOK				;branch if our scale larger
tickNotOK:
	mov	dl, dh				;dl <- new minimum
	mov	si, cs:[di].TS_incLabel		;si <- minimum label inc
tickOK:
	add	di, (size TickScale)		;cs:di <- ptr to next entry
	loop	tickLoop			;loop while more ticks

	mov	ax, si				;ax <- minimum label increment

	.leave
	ret
SetMinTick	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GState associated with our window
CALLED BY:	UTILITY

PASS:		*ds:si - VisRuler object
RETURN:		di - handle of GState
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateGState	proc	near
	uses	ax, cx, dx, bp
	.enter

	;
	; Query to create a GState
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				;di <- handle of GState

	.leave
	ret
CreateGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a GState we created previously
CALLED BY:	UTILITY

PASS:		*ds:si - VisRuler object
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DestroyGState	proc	near
	.enter

	call	GrDestroyState

	.leave
	ret
DestroyGState	endp

RulerBasicCode	ends
