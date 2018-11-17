COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentHdrFtr.asm

ROUTINES:
	Name			Description
	----			-----------
METHODS:
	Name			Description
	----			-----------
    StudioHdrFtrGuardianInitialize  
				Initialize the object

				MSG_META_INITIALIZE
				StudioHdrFtrGuardianClass

    StudioHdrFtrGuardianDrawFGLine  
				Draw the foreground line for the object

				MSG_GO_DRAW_FG_LINE,
				MSG_GO_DRAW_FG_LINE_HI_RES
				StudioHdrFtrGuardianClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for StudioHdrFtrGuardianClass and
	StudioHdrFtrClass

	$Id: documentHdrFtr.asm,v 1.1 97/04/04 14:38:45 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioHdrFtrGuardianClass
	StudioHdrFtrClass
idata ends

DocPageSetup segment resource
COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioHdrFtrGuardianInitialize -- MSG_META_INITIALIZE
					for StudioHdrFtrGuardianClass

DESCRIPTION:	Initialize the object

PASS:
	*ds:si - instance data
	es - segment of StudioHdrFtrGuardianClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
StudioHdrFtrGuardianInitialize	method dynamic	StudioHdrFtrGuardianClass,
							MSG_META_INITIALIZE

	mov	di, offset StudioHdrFtrGuardianClass
	call	ObjCallSuperNoLock

	; set the class for the ward object to our class

	mov	di, ds:[si]
	add	di, ds:[di].GrObjVisGuardian_offset
	ornf	ds:[di].GOI_msgOptFlags, mask GOMOF_DRAW_FG_LINE

	mov	ax, offset StudioHdrFtrClass
	movdw	ds:[di].GOVGI_class, esax

	ret

StudioHdrFtrGuardianInitialize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioHdrFtrGuardianDrawFGLine -- MSG_GO_DRAW_FG_LINE
						for StudioHdrFtrGuardianClass

DESCRIPTION:	Draw the foreground line for the object

PASS:
	*ds:si - instance data
	es - segment of StudioHdrFtrGuardianClass

	ax - The message

	cl - DrawFlags
	ch - GrObjDrawFlags
	dx - gstate to draw through

RETURN:
	cx, dx, bp - unchanged

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/23/92		Initial version

------------------------------------------------------------------------------@
StudioHdrFtrGuardianDrawFGLine	method dynamic	StudioHdrFtrGuardianClass,
						MSG_GO_DRAW_FG_LINE,
						MSG_GO_DRAW_FG_LINE_HI_RES

	test	cl, mask DF_PRINT
	jnz	callSuper

	; we are not printing -- draw a dotted line around the object if
	; the line mask is null


	push	cx, bp
	mov	cx, ds:[di].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp, sp
	call	GrObjGetGrObjFullLineAttrElement
	mov	al, ss:[bp].GOBLAE_mask
	add	sp, size GrObjFullLineAttrElement
	pop	cx, bp
	cmp	al, SDM_0
	jnz	callSuper

	; get the bounds

	push	cx, dx
	mov	di, dx
	mov	ax, SDM_50
	call	GrSetLineMask

	call	GrObjGetNormalOBJECTDimensions	;dxcx = width, bxax = height
	call	GrObjCalcCorners		;ax, bx, cx, dx = bounds (from
						;center)

	call	GrDrawRect
	pop	cx, dx
	ret

callSuper:
	mov	di, offset StudioHdrFtrGuardianClass
	GOTO	ObjCallSuperNoLock

StudioHdrFtrGuardianDrawFGLine	endm

DocPageSetup ends
