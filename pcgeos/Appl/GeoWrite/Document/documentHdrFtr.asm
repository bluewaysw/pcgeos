COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentHdrFtr.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for WriteHdrFtrGuardianClass and
	WriteHdrFtrClass

	$Id: documentHdrFtr.asm,v 1.1 97/04/04 15:56:26 newdeal Exp $

------------------------------------------------------------------------------@

GeoWriteClassStructures	segment	resource
	WriteHdrFtrGuardianClass
	WriteHdrFtrClass
GeoWriteClassStructures	ends

DocPageSetup segment resource
COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteHdrFtrGuardianInitialize -- MSG_META_INITIALIZE
					for WriteHdrFtrGuardianClass

DESCRIPTION:	Initialize the object

PASS:
	*ds:si - instance data
	es - segment of WriteHdrFtrGuardianClass

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
WriteHdrFtrGuardianInitialize	method dynamic	WriteHdrFtrGuardianClass,
							MSG_META_INITIALIZE

	mov	di, offset WriteHdrFtrGuardianClass
	call	ObjCallSuperNoLock

	; set the class for the ward object to our class

	mov	di, ds:[si]
	add	di, ds:[di].GrObjVisGuardian_offset
	ornf	ds:[di].GOI_msgOptFlags, mask GOMOF_DRAW_FG_LINE

	mov	ax, offset WriteHdrFtrClass
	movdw	ds:[di].GOVGI_class, esax

	ret

WriteHdrFtrGuardianInitialize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteHdrFtrGuardianDrawFGLine -- MSG_GO_DRAW_FG_LINE
						for WriteHdrFtrGuardianClass

DESCRIPTION:	Draw the foreground line for the object

PASS:
	*ds:si - instance data
	es - segment of WriteHdrFtrGuardianClass

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
WriteHdrFtrGuardianDrawFGLine	method dynamic	WriteHdrFtrGuardianClass,
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
	mov	di, offset WriteHdrFtrGuardianClass
	GOTO	ObjCallSuperNoLock

WriteHdrFtrGuardianDrawFGLine	endm

DocPageSetup ends
