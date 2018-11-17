COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentHead.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the article related code for WriteGrObjHeadClass

	$Id: documentHead.asm,v 1.1 97/04/04 15:56:30 newdeal Exp $

------------------------------------------------------------------------------@

GeoWriteClassStructures	segment	resource
	WriteGrObjHeadClass
GeoWriteClassStructures	ends

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteGrObjHeadSetCurrentTool -- MSG_GH_SET_CURRENT_TOOL
						for WriteGrObjHeadClass

DESCRIPTION:	Set the current tool

PASS:
	*ds:si - instance data
	es - segment of WriteGrObjHeadClass

	ax - The message

	cx:dx - tool class
	bp - MSG_GO_GROBJ_SPECIFIC_INITIALIZE data

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 8/92		Initial version

------------------------------------------------------------------------------@
WriteGrObjHeadSetCurrentTool	method dynamic	WriteGrObjHeadClass,
						MSG_GH_SET_CURRENT_TOOL,
					MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK

	mov	di, offset WriteGrObjHeadClass
	call	ObjCallSuperNoLock

	; notify all documents of the new tool

	mov	ax, MSG_WRITE_DOCUMENT_SET_TARGET_BASED_ON_TOOL
	mov	si, offset WriteDocumentGroup	;in the same block!
	call	GenSendToChildren

	ret

WriteGrObjHeadSetCurrentTool	endm

DocCommon ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteGrObjHeadSetTextToolForSearchSpell --
		MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL for WriteGrObjHeadClass

DESCRIPTION:	Set the correct text tool for search/spell

PASS:
	*ds:si - instance data
	es - segment of WriteGrObjHeadClass

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
	Tony	12/15/92		Initial version

------------------------------------------------------------------------------@
WriteGrObjHeadSetTextToolForSearchSpell	method dynamic	WriteGrObjHeadClass,
					MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL
	uses	cx,dx,bp
	.enter

	; send the MSG_GH_SET_CURRENT_TOOL to our superclass so that we do
	; not change the target

	mov	cx, segment EditTextGuardianClass
	mov	dx, offset EditTextGuardianClass
	clr	bp
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	di, offset WriteGrObjHeadClass
	call	ObjCallSuperNoLock

	.leave
	ret

WriteGrObjHeadSetTextToolForSearchSpell	endm

DocSTUFF ends
