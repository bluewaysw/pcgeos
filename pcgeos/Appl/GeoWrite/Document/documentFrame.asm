COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentFlow.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the code for FlowRegionClass

	$Id: documentFrame.asm,v 1.1 97/04/04 15:56:20 newdeal Exp $

------------------------------------------------------------------------------@

GeoWriteClassStructures	segment	resource
	WrapFrameClass
GeoWriteClassStructures	ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WrapFrameInitToDefaultAttrs -- MSG_GO_INIT_TO_DEFAULT_ATTRS
							for WrapFrameClass

DESCRIPTION:	Set special attributes

PASS:
	*ds:si - instance data
	es - segment of WrapFrameClass

	ax - The message

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
	Tony	10/22/92		Initial version

------------------------------------------------------------------------------@
WrapFrameInitToDefaultAttrs	method dynamic	WrapFrameClass,
						MSG_GO_INIT_TO_DEFAULT_ATTRS
				uses cx, dx, bp
	.enter

	; do the default stuff

	mov	di, offset WrapFrameClass
	call	ObjCallSuperNoLock

	; set the correct attrs

	call	IgnoreUndoNoFlush

	push	si
	mov	cx, GRAPHIC_STYLE_WRAP_FRAME
	mov	ax, MSG_WRITE_DOCUMENT_GET_GRAPHIC_TOKENS_FOR_STYLE
	mov	di, mask MF_RECORD
	mov	bx, segment GenDocumentClass
	mov	si, offset GenDocumentClass
	call	ObjMessage			;di = message
	pop	si
	mov	cx, di
	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	mov	di, mask MF_CALL
	call	GrObjMessageToBody		;cx = line, dx = area

	push	dx
	mov	ax, MSG_GO_SET_GROBJ_LINE_TOKEN
	call	ObjCallInstanceNoLock
	pop	cx

	mov	ax, MSG_GO_SET_GROBJ_AREA_TOKEN
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].GrObj_offset
	andnf	ds:[di].GOI_attrFlags, not mask GOAF_WRAP
	ornf	ds:[di].GOI_attrFlags,
				GOWTT_WRAP_AROUND_RECT shl offset GOAF_WRAP

	call	AcceptUndo

	.leave
	ret

WrapFrameInitToDefaultAttrs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WrapFrameCompleteCreate -- MSG_GO_COMPLETE_CREATE
							for WrapFrameClass

DESCRIPTION:	Handle completion of a create by switching to the
		pointer tool

PASS:
	*ds:si - instance data
	es - segment of WrapFrameClass

	ax - The message

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
	Tony	10/22/92		Initial version

------------------------------------------------------------------------------@
WrapFrameCompleteCreate	method dynamic	WrapFrameClass, MSG_GO_COMPLETE_CREATE
					uses cx, dx, bp
	.enter

	; do the default stuff

	mov	di, offset WrapFrameClass
	call	ObjCallSuperNoLock

	; now return to the pointer tool

	; choose the frame tool

	GetResourceHandleNS	WriteHead, bx
	mov	si, offset WriteHead
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	cx, segment PointerClass
	mov	dx, offset PointerClass
	clr	bp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

WrapFrameCompleteCreate	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WrapFrameEndCreate -- MSG_GO_END_CREATE for WrapFrameClass

DESCRIPTION:	Finish creating an object

PASS:
	*ds:si - instance data
	es - segment of WrapFrameClass

	ax - The message

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
	Tony	10/22/92		Initial version

------------------------------------------------------------------------------@
WrapFrameEndCreate	method dynamic	WrapFrameClass, MSG_GO_END_CREATE

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	callSuper

	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	callSuper

	; if something is already happening (the user has already dragged)
	; the let it happen

	test	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING
	jnz	callSuper

	; give the user a default rectangle

	ornf	ds:[di].GOI_actionModes,mask GOAM_ACTION_HAPPENING

	push	si
	mov	si, ds:[di].GOI_spriteTransform	;*ds:si = ObjectTransform
	mov	si, ds:[si]
	mov	ds:[si].OT_width.WWF_int, DEFAULT_WRAP_FRAME_WIDTH
	mov	ds:[si].OT_width.WWF_frac, 0
	mov	ds:[si].OT_height.WWF_int, DEFAULT_WRAP_FRAME_HEIGHT
	mov	ds:[si].OT_height.WWF_frac, 0
	add	ds:[si].OT_center.PDF_x.DWF_int.low, DEFAULT_WRAP_FRAME_WIDTH/2
	add	ds:[si].OT_center.PDF_y.DWF_int.low, DEFAULT_WRAP_FRAME_HEIGHT/2
	pop	si

	; do the default stuff

callSuper:
	mov	ax, MSG_GO_END_CREATE
	mov	di, offset WrapFrameClass
	GOTO	ObjCallSuperNoLock

WrapFrameEndCreate	endm

DocSTUFF ends
