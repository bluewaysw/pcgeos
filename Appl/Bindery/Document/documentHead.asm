COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentHead.asm

ROUTINES:
	Name			Description
	----			-----------
METHODS:
	Name			Description
	----			-----------
    StudioGrObjHeadSetCurrentTool  
				Set the current tool

				MSG_GH_SET_CURRENT_TOOL,
				MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK
				StudioGrObjHeadClass

    StudioGrObjHeadSetTextToolForSearchSpell  
				Set the correct text tool for search/spell

				MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL
				StudioGrObjHeadClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the article related code for StudioGrObjHeadClass

	$Id: documentHead.asm,v 1.1 97/04/04 14:38:48 newdeal Exp $

------------------------------------------------------------------------------@

idata segment
	StudioGrObjHeadClass
idata ends

DocCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjHeadSetCurrentTool -- MSG_GH_SET_CURRENT_TOOL
						for StudioGrObjHeadClass

DESCRIPTION:	Set the current tool

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjHeadClass

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
StudioGrObjHeadSetCurrentTool	method dynamic	StudioGrObjHeadClass,
						MSG_GH_SET_CURRENT_TOOL,
					MSG_GH_SET_CURRENT_TOOL_WITH_DATA_BLOCK

	mov	di, offset StudioGrObjHeadClass
	call	ObjCallSuperNoLock

	; notify all documents of the new tool

	mov	ax, MSG_STUDIO_DOCUMENT_SET_TARGET_BASED_ON_TOOL
	mov	si, offset StudioDocGroup	;in the same block!
	call	GenSendToChildren

	ret

StudioGrObjHeadSetCurrentTool	endm

DocCommon ends

DocSTUFF segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioGrObjHeadSetTextToolForSearchSpell --
		MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL for StudioGrObjHeadClass

DESCRIPTION:	Set the correct text tool for search/spell

PASS:
	*ds:si - instance data
	es - segment of StudioGrObjHeadClass

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
StudioGrObjHeadSetTextToolForSearchSpell	method dynamic	StudioGrObjHeadClass,
					MSG_GH_SET_TEXT_TOOL_FOR_SEARCH_SPELL
	uses	cx,dx,bp
	.enter

	; send the MSG_GH_SET_CURRENT_TOOL to our superclass so that we do
	; not change the target

	mov	cx, segment EditTextGuardianClass
	mov	dx, offset EditTextGuardianClass
	clr	bp
	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	di, offset StudioGrObjHeadClass
	call	ObjCallSuperNoLock

	.leave
	ret

StudioGrObjHeadSetTextToolForSearchSpell	endm

DocSTUFF ends
