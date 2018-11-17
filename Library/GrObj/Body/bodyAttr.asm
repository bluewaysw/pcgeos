COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		The GrObj
FILE:		bodyAttr.asm

AUTHOR:		Jon Witort

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	27 apr 1992	initial version

DESCRIPTION:

	$Id: bodyAttr.asm,v 1.1 97/04/04 18:08:00 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjStyleSheetCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyStyleCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Forwards any MSG_META_STYLED_OBJECT_* messages to the
		appropriate object(s).

Pass:		*ds:si - GrObjBody object
		ds:di - GrObjBody instance

		ax - MSG_META_STYLED_OBJECT_* (except RECALL_STYLE)

		cx,dx,bp - data

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyStyleCommon	method	GrObjBodyClass, 
			MSG_META_STYLED_OBJECT_APPLY_STYLE,
			MSG_META_STYLED_OBJECT_RETURN_TO_BASE_STYLE

	.enter

	push	ax, bp
	mov	ax, MSG_GB_GET_NUM_SELECTED_GROBJS
	call	ObjCallInstanceNoLock
	tst	bp
	pop	ax, bp
	jz	sendToGOAM

	call	GrObjBodySendToSelectedGrObjs

done:
	.leave
	ret

sendToGOAM:
	clr	di
	call	GrObjBodyMessageToGOAM
	jmp	done
GrObjBodyStyleCommon	endm

;---
GrObjBodyStyleCommonToFirst	method	GrObjBodyClass, 
			MSG_META_STYLED_OBJECT_DEFINE_STYLE,
			MSG_META_STYLED_OBJECT_REDEFINE_STYLE,
			MSG_META_STYLED_OBJECT_SAVE_STYLE
	.enter

	push	ax, bp
	mov	ax, MSG_GB_GET_NUM_SELECTED_GROBJS
	call	ObjCallInstanceNoLock
	tst	bp
	pop	ax, bp
	jz	sendToGOAM

	call	GrObjBodySendToFirstSelectedGrObj

done:
	.leave
	ret

sendToGOAM:
	clr	di
	call	GrObjBodyMessageToGOAM
	jmp	done
GrObjBodyStyleCommonToFirst	endm

;---

GrObjBodyStyleCommonToGOAM	method	GrObjBodyClass, 
			MSG_META_STYLED_OBJECT_REQUEST_ENTRY_MONIKER,
			MSG_META_STYLED_OBJECT_UPDATE_MODIFY_BOX,
			MSG_META_STYLED_OBJECT_MODIFY_STYLE,
			MSG_META_STYLED_OBJECT_LOAD_STYLE_SHEET,
			MSG_META_STYLED_OBJECT_DESCRIBE_STYLE,
			MSG_META_STYLED_OBJECT_DESCRIBE_ATTRS,
			MSG_META_STYLED_OBJECT_DELETE_STYLE

	clr	di
	call	GrObjBodyMessageToGOAM
	ret
GrObjBodyStyleCommonToGOAM	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodyRecallStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Sends the recall style message to its selected grobjies,
		then dec's the ref count so that the block can be freed

Pass:		*ds:si - GrObjBody object
		ds:di - GrObjBody instance

		ax - MSG_META_STYLED_OBJECT_RECALL_STYLE

		ss:[bp] - SSCRecallStyleParams

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyRecallStyle	method	GrObjBodyClass, 
			MSG_META_STYLED_OBJECT_RECALL_STYLE
	.enter

	push	ax, bp
	mov	ax, MSG_GB_GET_NUM_SELECTED_GROBJS
	call	ObjCallInstanceNoLock
	tst	bp
	pop	ax, bp
	jz	sendToGOAM

	call	GrObjBodySendToSelectedGrObjs

decRef:
	mov	bx, ss:[bp].SSCRSP_blockHandle
	call	MemDecRefCount

	.leave
	ret

sendToGOAM:
	clr	di
	call	GrObjBodyMessageToGOAM
	jmp	decRef
GrObjBodyRecallStyle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodySubstAreaToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Inform any GrObjs with the passed "old" token to replace
		it with	the new one, updating the reference count if specified.


Pass:		*ds:si - GrObjBody object
		ds:di - GrObjBody instance

		cx - old area token
		dx - new area token
		bp - nonzero to update references

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	7 may 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySubstAreaToken		method dynamic	GrObjBodyClass,
				MSG_GB_SUBST_AREA_TOKEN
	.enter

	mov	ax, MSG_GO_SUBST_AREA_TOKEN
	call	GrObjBodySendToChildren

	.leave
	ret
GrObjBodySubstAreaToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjBodySubstLineToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Inform any GrObjs with the passed "old" token to replace
		it with	the new one, updating the reference count if specified.


Pass:		*ds:si - GrObjBody object
		ds:di - GrObjBody instance

		cx - old line token
		dx - new line token
		bp - nonzero to update references

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	7 may 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySubstLineToken		method dynamic	GrObjBodyClass,
				MSG_GB_SUBST_LINE_TOKEN
	.enter

	mov	ax, MSG_GO_SUBST_LINE_TOKEN
	call	GrObjBodySendToChildren

	.leave
	ret
GrObjBodySubstLineToken	endm

GrObjStyleSheetCode ends
