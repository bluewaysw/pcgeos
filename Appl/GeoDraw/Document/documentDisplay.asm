COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoDraw
FILE:		documentDisplay.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version
	jon	23 oct 92	copied from geowrite

DESCRIPTION:
	This file contains the VisContent related code for DrawDocumentClass

	$Id: documentDisplay.asm,v 1.1 97/04/04 15:51:39 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	DrawDisplayClass
idata ends

;-----

DocOpenClose segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawDisplayBuildBranch -- MSG_SPEC_BUILD_BRANCH
						for DrawDisplayClass

DESCRIPTION:	Do a little extra work while we're coming up

PASS:
	*ds:si - instance data
	es - segment of DrawDisplayClass

	ax - The message

	bp - SpecBuildFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/11/92		Initial version

------------------------------------------------------------------------------@
DrawDisplayBuildBranch	method dynamic	DrawDisplayClass,
						MSG_SPEC_BUILD_BRANCH,
						MSG_VIS_OPEN

	; add ourself to the display GCN list now so that we can immediately
	; set our rulers not usable if needed

	mov	di, MSG_META_GCN_LIST_ADD
	call	GCNCommon

	mov	di, offset DrawDisplayClass
	GOTO	ObjCallSuperNoLock

DrawDisplayBuildBranch	endm

;---

DrawDisplayUnbuildBranch	method dynamic	DrawDisplayClass,
						MSG_SPEC_UNBUILD_BRANCH,
						MSG_VIS_CLOSE

	mov	di, offset DrawDisplayClass
	call	ObjCallSuperNoLock

	; add ourself to the display GCN list now so that we can immediately
	; set our rulers not usable if needed

	mov	di, MSG_META_GCN_LIST_REMOVE
	call	GCNCommon
	ret

DrawDisplayUnbuildBranch	endm

;---

GCNCommon	proc	near
	push	ax, si, bp
	sub	sp, size GCNListParams		; create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type,
				GAGCNLT_DISPLAY_OBJECTS_WITH_RULERS
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	dx, size GCNListParams		; create stack frame
	clr	bx
	call	GeodeGetAppObject
	mov_tr	ax, di
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListParams		; fix stack
	pop	ax, si, bp

	ret

GCNCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	DrawMainDisplayUpdateRulers --
		MSG_DRAW_DISPLAY_UPDATE_RULERS for DrawMainDisplayClass

DESCRIPTION:	Update the usable/not-usable status of the rulers

PASS:
	*ds:si - instance data
	es - segment of DrawMainDisplayClass

	ax - The message

	cx - RulerShowControlAttributes

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/11/92		Initial version

------------------------------------------------------------------------------@
DrawMainDisplayUpdateRulers	method dynamic	DrawDisplayClass,
						MSG_DRAW_DISPLAY_UPDATE_RULERS

	mov	ax, mask RSCA_SHOW_VERTICAL
	mov	si, offset DrawRowViewObjTemp
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_HORIZONTAL
	mov	si, offset DrawColumnViewObjTemp
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_VERTICAL or mask RSCA_SHOW_HORIZONTAL
	mov	si, offset DrawCornerViewObjTemp
	call	UpdateRuler

	ret

DrawMainDisplayUpdateRulers	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateRuler

DESCRIPTION:	Update the usable/not-usable status of something

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - bits to check for
	cx - RulerShowControlAttributes

RETURN:
	none

DESTROYED:
	bx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/11/92		Initial version

------------------------------------------------------------------------------@
UpdateRuler	proc	near	uses cx
	.enter

	mov	bx, ax
	and	bx, cx
	cmp	ax, bx
	mov	ax, MSG_GEN_SET_USABLE
	jz	20$
	mov	ax, MSG_GEN_SET_NOT_USABLE
20$:
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	.leave
	ret

UpdateRuler	endp

DocOpenClose ends
