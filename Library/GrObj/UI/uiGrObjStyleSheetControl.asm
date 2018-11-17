COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj Library
FILE:		uiGrObjStyleSheetControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GrObjStyleSheetControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement GrObjStyleSheetControlClass

	$Id: uiGrObjStyleSheetControl.asm,v 1.1 97/04/04 18:05:44 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

idata segment


idata ends

;---------------------------------------------------

GrObjUIControllerCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjStyleSheetControlGetInfo -- MSG_GEN_CONTROL_GET_INFO
					for GrObjStyleSheetControlClass

DESCRIPTION:	Get info.  We use our superclass's with a few tweaks

PASS:
	*ds:si - instance data
	es - segment of GrObjStyleSheetControlClass

	ax - The message

	cx:dx - GenControlDupInfo structure to fill in

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/12/92		Initial version

------------------------------------------------------------------------------@
GrObjStyleSheetControlGetInfo	method dynamic	GrObjStyleSheetControlClass,
						MSG_GEN_CONTROL_GET_INFO

	pushdw	cxdx
	mov	di, offset GrObjStyleSheetControlClass
	call	ObjCallSuperNoLock
	popdw	dssi
	mov	ds:[si].GCBI_gcnList.segment, vseg GSSC_gcnList
	mov	ds:[si].GCBI_gcnList.offset, offset GSSC_gcnList
	mov	ds:[si].GCBI_gcnCount, length GSSC_gcnList
	ret

GrObjStyleSheetControlGetInfo	endm

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GSSC_gcnList	GCNListType \
 <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_STYLE_GROBJ_CHANGE>,
 <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_GROBJ_CHANGE>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateGrObjStyleAttributeList

DESCRIPTION:	Update the custom UI for the text style control

CALLED BY:	INTERNAL

PASS:
	cx:di - UI to update
	ds:si - style structure
	ds:dx - base style structure (dx = 0 if none)

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
	Tony	1/ 7/92		Initial version

------------------------------------------------------------------------------@
UpdateGrObjStyleAttributeList	proc	far	uses ax, bx, cx, si, di, bp
	.enter

	mov	ax, ds:[si].GSE_privateData.GSPD_flags
	movdw	bxsi, cxdi
	mov_tr	cx, ax
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret

UpdateGrObjStyleAttributeList	endp

;---

ModifyGrObjStyleAttributeList	proc	far	uses ax, bx, cx, dx, di, bp
	.enter

	push	si
	movdw	bxsi, cxdi
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;cx = value
	pop	si

	mov	ds:[si].GSE_privateData.GSPD_flags, ax

	.leave
	ret

ModifyGrObjStyleAttributeList	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjStyleSheetControlGetModifyUI --
		MSG_STYLE_SHEET_GET_MANAGE_UI for GrObjStyleSheetControlClass

DESCRIPTION:	Return UI to add

PASS:
	*ds:si - instance data
	es - segment of GrObjStyleSheetControlClass

	ax - The message

RETURN:
	cx:dx - UI to add

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/19/91		Initial version

------------------------------------------------------------------------------@
GrObjStyleSheetControlGetModifyUI	method dynamic	\
					GrObjStyleSheetControlClass,
					MSG_STYLE_SHEET_GET_MODIFY_UI,
					MSG_STYLE_SHEET_GET_DEFINE_UI

	mov	cx, handle GSSCAttrBooleanGroup
	mov	dx, offset GSSCAttrBooleanGroup
	ret

GrObjStyleSheetControlGetModifyUI	endm

GrObjUIControllerCode ends
