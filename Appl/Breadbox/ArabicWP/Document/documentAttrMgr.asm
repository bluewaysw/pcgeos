COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentAttributeManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the article related code for
	WriteGrObjAttributeManagerClass

	$Id: documentAttrMgr.asm,v 1.1 97/04/04 15:56:42 newdeal Exp $

------------------------------------------------------------------------------@

GeoWriteClassStructures	segment	resource
	WriteGrObjAttributeManagerClass
GeoWriteClassStructures	ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteGrObjAttributeManagerSubstTextAttrToken --
		MSG_GOAM_SUBST_TEXT_ATTR_TOKEN
					for WriteGrObjAttributeManagerClass

DESCRIPTION:	Handle a request to substitute a text attribute token (as
		part of a style sheet change)

PASS:
	*ds:si - instance data
	es - segment of WriteGrObjAttributeManagerClass

	ax - The message

	ss:bp - VisTextSubstAttrTokenParams

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
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
WriteGrObjAttributeManagerSubstTextAttrToken	method dynamic	\
					WriteGrObjAttributeManagerClass,
					MSG_GOAM_SUBST_TEXT_ATTR_TOKEN

	; if this has not been relayed then we need to relay it to the
	; associated articles

	tst	ss:[bp].VTSATP_relayedToLikeTextObjects
	jnz	toSuper
	mov	ss:[bp].VTSATP_relayedToLikeTextObjects, ax	;non-zero

	push	ax, dx
	mov	ax, MSG_VIS_TEXT_SUBST_ATTR_TOKEN
	mov	dx, size VisTextSubstAttrTokenParams
	mov	di, mask MF_RECORD or mask MF_STACK
	call	RelayCommon
	pop	ax, dx

toSuper:
	mov	di, offset WriteGrObjAttributeManagerClass
	GOTO	ObjCallSuperNoLock

WriteGrObjAttributeManagerSubstTextAttrToken	endm

;---

	; ax = message, di = flags for recording the message

RelayCommon	proc	near
	push	cx, si, bp
	call	ObjMessage			;di = message
	mov	cx, di
	mov	si, offset MainBody
	mov	ax, MSG_WRITE_DOCUMENT_SEND_TO_ALL_ARTICLES
	call	VisCallParent
	pop	cx, si, bp
	ret
RelayCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteGrObjAttributeManagerRecalcForTextAttrChange --
		MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE
					for WriteGrObjAttributeManagerClass

DESCRIPTION:	Reaclculate for a text attribute change

PASS:
	*ds:si - instance data
	es - segment of WriteGrObjAttributeManagerClass

	ax - The message

	cx - non-zero if relayed to all text objects

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
	Tony	9/26/92		Initial version

------------------------------------------------------------------------------@
WriteGrObjAttributeManagerRecalcForTextAttrChange	method dynamic	\
					WriteGrObjAttributeManagerClass,
					MSG_GOAM_RECALC_FOR_TEXT_ATTR_CHANGE

	; if this has not been relayed then we need to relay it to the
	; associated articles

	tst	cx
	jnz	toSuper
	dec	cx					;non-zero

	push	ax, cx, dx

	; we also need to invalidate the document so that the master page
	; redraws

	push	cx, si
	mov	si, offset MainBody
	mov	ax, MSG_VIS_INVALIDATE
	call	VisCallParent
	pop	cx, si

	mov	ax, MSG_VIS_TEXT_RECALC_FOR_ATTR_CHANGE
	mov	di, mask MF_RECORD
	call	RelayCommon
	pop	ax, cx, dx

toSuper:
	mov	di, offset WriteGrObjAttributeManagerClass
	GOTO	ObjCallSuperNoLock

WriteGrObjAttributeManagerRecalcForTextAttrChange	endm

DocSTUFF ends
