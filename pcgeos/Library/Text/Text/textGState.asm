COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		textGState.asm

AUTHOR:		John Wedgwood, Oct  6, 1989

ROUTINES:
	Name			Description
	----			-----------
	TextSetupGState		Set up a gstate for drawing or calculation.
	TextGStateCreate	Make a gstate for caching.
	TextGStateDestroy	Nuke the cached gstate.
	TextSetColor		Set the background wash color.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	10/ 6/89		Initial revision

DESCRIPTION:
	GState manipulation routines for the text object.

	$Id: textGState.asm,v 1.1 97/04/07 11:18:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EC <MAX_REF_COUNT	=	20					>

TextFixed	segment

TextFixed_DerefVis_DI	proc	near
	class	VisTextClass
EC <	call	T_AssertIsVisText					>

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextFixed_DerefVis_DI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGStateCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate, if needed.

CALLED BY:	UTILITY
PASS:		ds:*si = pointer to VisTextInstance.
RETURN:		ds:*si.VTI_gstate set to a valid drawing/calc gstate.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGStateCreate	method VisTextClass, MSG_VIS_CREATE_CACHED_GSTATES
	class	VisTextClass
	uses	ax, cx, dx, bp, di, si
	.enter
BEC <	call	CheckRunPositions		>

	call	TextFixed_DerefVis_DI

	mov	al, ds:[di].VTI_gsRefCount
	and	al, mask GSRCAF_REF_COUNT
EC <	cmp	al, MAX_REF_COUNT					>
EC <	ERROR_AE	VIS_TEXT_ILLEGAL_GS_REF_COUNT			>

	inc	ds:[di].VTI_gsRefCount		; Update the count
	cmp	ds:[di].VTI_gstate, 0
	jne	done				; Quit if we have a gstate

	; We need to create a gstate.  We can do a slight optimization here
	; by calling GrCreateState *if* the object if not realized

	test	ds:[di].VI_attrs, mask VA_REALIZED	; Check for realized.
	jz	notRealized

	; Fetch a GState, using the safest approach --
	; (One which allows us to exist in 32-bit documents)

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				; copy result to di
	jc	initGState			; If successful, initialize
	;
	; OK.  That didn't work.  Rather than dying miserably, let's just
	; create a plain old GState & get on with it.
	;
notRealized:
	clr	di
	call	GrCreateState			; Create a GState

initGState:
	call	TextInitGState			; Init with text stuff...

	mov	ax, di				; ax <- gstate
	call	TextFixed_DerefVis_DI
	mov	ds:[di].VTI_gstate, ax		; Save it
	mov	ds:[di].VTI_gstateRegion, -1	; No region yet

done:
	.leave
	ret
TextGStateCreate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGStateDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the saved gstate.

CALLED BY:	UTILITY
PASS:		ds:*si = pointer to VisTextInstance.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	9/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGStateDestroy	method VisTextClass, MSG_VIS_DESTROY_CACHED_GSTATES
	class	VisTextClass
	uses	ax, di
	.enter
BEC <	call	CheckRunPositions		>

	call	TextFixed_DerefVis_DI

	mov	al, ds:[di].VTI_gsRefCount
	and	al, mask GSRCAF_REF_COUNT
EC <	cmp	al, MAX_REF_COUNT					>
EC <	ERROR_A	VIS_TEXT_ILLEGAL_GS_REF_COUNT				>
EC <	tst	al							>
EC <	ERROR_Z	UI_NEGATIVE_GSREFCOUNT_IN_TEXT_OBJ			>

	dec	ds:[di].VTI_gsRefCount

	dec	al				; Nuke gstate only when
	jnz	done				;  the reference count
	clr	ax
	xchg	ax, ds:[di].VTI_gstate		;  goes to zero, ax = gstate
	xchg	ax, di				; one byte move
	call	GrDestroyState
done:
	.leave
	ret
TextGStateDestroy	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextInitGState

DESCRIPTION:	Initialize a gstate to the default expected by the text object

CALLED BY:	TextGStateCreate, VisTextDraw, VisTextNotifyGeometryValid

PASS:
	*ds:si - instance
	di - gstate

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

TextInitGState	proc	far		uses ax, bx
	.enter

	call	TextInitModeAndBorder

	.leave
	ret

TextInitGState	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TextInitModeAndBorder

DESCRIPTION:	Initialize a gstate to the default mode and border

CALLED BY:	TextInitGState, VisTextDraw

PASS:
	*ds:si - instance
	di - gstate

RETURN:
	none

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

z------------------------------------------------------------------------------@

TextInitModeAndBorder	proc	far
	mov	al, mask TM_DRAW_BASE
	clr	ah				; Don't clear anything.
	call	GrSetTextMode

	mov	al, SDM_100			; assume enabled
	call	GrSetTextMask
	ret

TextInitModeAndBorder	endp

TextFixed	ends
