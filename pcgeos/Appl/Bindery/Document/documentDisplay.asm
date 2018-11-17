COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentDisplay.asm

ROUTINES:
	Name			Description
	----			-----------
    INT GCNCommon		Do a little extra work while we're coming
				up

    INT UpdateRuler		Update the usable/not-usable status of
				something

METHODS:
	Name			Description
	----			-----------
    StudioDisplayBuildBranch	Do a little extra work while we're coming
				up

				MSG_SPEC_BUILD_BRANCH,
				MSG_VIS_OPEN
				StudioDisplayClass

    StudioDisplayUnbuildBranch	Do a little extra work while we're leaving

				MSG_SPEC_UNBUILD_BRANCH,
				MSG_VIS_CLOSE
				StudioDisplayClass

    StudioMainDisplayUpdateRulers  
				Update the usable/not-usable status of the
				rulers

				MSG_STUDIO_DISPLAY_UPDATE_RULERS
				StudioMainDisplayClass

    StudioMasterPageDisplayUpdateRulers  
				Update the usable/not-usable status of the
				rulers

				MSG_STUDIO_DISPLAY_UPDATE_RULERS
				StudioMasterPageDisplayClass

    StudioMasterPageDisplaySetDocumentAndMP  
				Set the document

				MSG_STUDIO_MASTER_PAGE_DISPLAY_SET_DOCUMENT_AND_MP
				StudioMasterPageDisplayClass

    StudioMasterPageDisplayClose Close a master page

				MSG_GEN_DISPLAY_CLOSE
				StudioMasterPageDisplayClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the VisContent related code for StudioDocumentClass

	$Id: documentDisplay.asm,v 1.1 97/04/04 14:38:39 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioDisplayClass
	StudioMainDisplayClass
	StudioMasterPageDisplayClass
idata ends

;-----

DocOpenClose segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDisplayBuildBranch -- MSG_SPEC_BUILD_BRANCH
						for StudioDisplayClass

DESCRIPTION:	Do a little extra work while we're coming up

PASS:
	*ds:si - instance data
	es - segment of StudioDisplayClass

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
StudioDisplayBuildBranch	method dynamic	StudioDisplayClass,
						MSG_SPEC_BUILD_BRANCH,
						MSG_VIS_OPEN

	; add ourself to the display GCN list now so that we can immediately
	; set our rulers not usable if needed

	mov	di, MSG_META_GCN_LIST_ADD
	call	GCNCommon

	mov	di, offset StudioDisplayClass
	GOTO	ObjCallSuperNoLock

StudioDisplayBuildBranch	endm

;---

StudioDisplayUnbuildBranch	method dynamic	StudioDisplayClass,
						MSG_SPEC_UNBUILD_BRANCH,
						MSG_VIS_CLOSE

	mov	di, offset StudioDisplayClass
	call	ObjCallSuperNoLock

	; add ourself to the display GCN list now so that we can immediately
	; set our rulers not usable if needed

	mov	di, MSG_META_GCN_LIST_REMOVE
	call	GCNCommon
	ret

StudioDisplayUnbuildBranch	endm

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

MESSAGE:	StudioMainDisplayUpdateRulers --
		MSG_STUDIO_DISPLAY_UPDATE_RULERS for StudioMainDisplayClass

DESCRIPTION:	Update the usable/not-usable status of the rulers

PASS:
	*ds:si - instance data
	es - segment of StudioMainDisplayClass

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
StudioMainDisplayUpdateRulers	method dynamic	StudioMainDisplayClass,
						MSG_STUDIO_DISPLAY_UPDATE_RULERS

	mov	ax, mask RSCA_SHOW_VERTICAL
	mov	si, offset MainVerticalRulerView
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_HORIZONTAL
	mov	si, offset MainHorizontalRulerView
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_VERTICAL or mask RSCA_SHOW_HORIZONTAL
	mov	si, offset CornerGlyph
	call	UpdateRuler

	ret

StudioMainDisplayUpdateRulers	endm

;---

StudioMasterPageDisplayUpdateRulers	method dynamic	\
					StudioMasterPageDisplayClass,
					MSG_STUDIO_DISPLAY_UPDATE_RULERS

	mov	ax, mask RSCA_SHOW_VERTICAL
	mov	si, offset MPVerticalRulerView
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_HORIZONTAL
	mov	si, offset MPHorizontalRulerView
	call	UpdateRuler

	mov	ax, mask RSCA_SHOW_VERTICAL or mask RSCA_SHOW_HORIZONTAL
	mov	si, offset MPCornerGlyph
	call	UpdateRuler

	ret

StudioMasterPageDisplayUpdateRulers	endm

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

DocEditMP segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageDisplaySetDocumentAndMP --
		MSG_STUDIO_MASTER_PAGE_DISPLAY_SET_DOCUMENT_AND_MP
						for StudioMasterPageDisplayClass

DESCRIPTION:	Set the document

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageDisplayClass

	ax - The message

	cx:dx - document
	bp - master page body block

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageDisplaySetDocumentAndMP	method dynamic	\
					StudioMasterPageDisplayClass,
			MSG_STUDIO_MASTER_PAGE_DISPLAY_SET_DOCUMENT_AND_MP

	movdw	ds:[di].SMPDI_document, cxdx
	mov	ds:[di].SMPDI_bodyVMBlock, bp
	ret

StudioMasterPageDisplaySetDocumentAndMP	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioMasterPageDisplayClose -- MSG_GEN_DISPLAY_CLOSE
						for StudioMasterPageDisplayClass

DESCRIPTION:	Close a master page

PASS:
	*ds:si - instance data
	es - segment of StudioMasterPageDisplayClass

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
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
StudioMasterPageDisplayClose	method dynamic	StudioMasterPageDisplayClass,
							MSG_GEN_DISPLAY_CLOSE

	; we need to tell the associated document to close itsself

	movdw	bxsi, ds:[di].SMPDI_document
	mov	cx, ds:[di].SMPDI_bodyVMBlock
	mov	ax, MSG_STUDIO_DOCUMENT_CLOSE_MASTER_PAGE
	call	DEMP_ObjMessageNoFlags
	ret

StudioMasterPageDisplayClose	endm

DocEditMP ends
