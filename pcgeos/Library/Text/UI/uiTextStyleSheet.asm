COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiTextStyleSheetControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	TextStyleSheetControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement TextStyleSheetControlClass

	$Id: uiTextStyleSheet.asm,v 1.1 97/04/07 11:16:44 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	TextStyleSheetControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextStyleSheetControlGetInfo -- MSG_GEN_CONTROL_GET_INFO
					for TextStyleSheetControlClass

DESCRIPTION:	Get info.  We use our superclass's with a few tweaks

PASS:
	*ds:si - instance data
	es - segment of TextStyleSheetControlClass

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
TextStyleSheetControlGetInfo	method dynamic	TextStyleSheetControlClass,
						MSG_GEN_CONTROL_GET_INFO

	pushdw	cxdx
	mov	di, offset TextStyleSheetControlClass
	call	ObjCallSuperNoLock
	popdw	dssi
	mov	ds:[si].GCBI_gcnList.segment, vseg TSSC_gcnList
	mov	ds:[si].GCBI_gcnList.offset, offset TSSC_gcnList
	mov	ds:[si].GCBI_gcnCount, length TSSC_gcnList
	ret

TextStyleSheetControlGetInfo	endm

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

TSSC_gcnList	GCNListType \
 <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_STYLE_TEXT_CHANGE>,
 <MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_STYLE_SHEET_TEXT_CHANGE>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif


TextControlCommon ends

endif		; not NO_CONTROLLERS

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateDescTextStyleAttributeList
		UpdateModifyTextStyleAttributeList

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
UpdateDescTextStyleAttributeList	proc	far
	clc		; check Apply to Selection
	call	UpdateTextStyleAttributeListCommon
	ret
UpdateDescTextStyleAttributeList	endp

UpdateModifyTextStyleAttributeList	proc	far
	stc		; always enable Apply to Selection
	call	UpdateTextStyleAttributeListCommon
	ret
UpdateModifyTextStyleAttributeList	endp

UpdateTextStyleAttributeListCommon	proc	near	uses ax, bx, cx, dx, si, di, bp
	.enter

	pushf					;save always enable flag
	mov	ax, ds:[si].TSEH_privateData.TSPD_flags
	push	ds:[si].TSEH_baseStyle
	movdw	bxsi, cxdi
	mov_tr	cx, ax
	clr	dx
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; if character-only is selected then disable it so that the user
	; cannot make a non-character only style based on a character only
	; style

	; don't do this if there is no base style or if the base style is
	; not character only

	pop	ax				;ax = base style
	popf					;C set if always enable
	jc	setEnabled
	cmp	ax, CA_NULL_ELEMENT
	jz	setEnabled

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	cx, mask TSF_APPLY_TO_SELECTION_ONLY
	jnz	common
setEnabled:
	mov	ax, MSG_GEN_SET_ENABLED
common:
	push	ax

	; find the correct GenBoolean

	mov	cx, mask TSF_APPLY_TO_SELECTION_ONLY
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_BOOLEAN_OPTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			;cxdx = object
	pop	ax
	jnc	done
	movdw	bxsi, cxdx
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
done:

	.leave
	ret

UpdateTextStyleAttributeListCommon	endp

;---

ModifyTextStyleAttributeList	proc	far	uses ax, bx, cx, dx, di, bp
	.enter

	push	si
	movdw	bxsi, cxdi
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage			;cx = value
	pop	si

	mov	ds:[si].TSEH_privateData.TSPD_flags, ax

	.leave
	ret

ModifyTextStyleAttributeList	endp

if not NO_CONTROLLERS

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextStyleSheetControlGetModifyUI --
		MSG_STYLE_SHEET_GET_MANAGE_UI for TextStyleSheetControlClass

DESCRIPTION:	Return UI to add

PASS:
	*ds:si - instance data
	es - segment of TextStyleSheetControlClass

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
TextStyleSheetControlGetModifyUI	method dynamic	\
					TextStyleSheetControlClass,
					MSG_STYLE_SHEET_GET_MODIFY_UI,
					MSG_STYLE_SHEET_GET_DEFINE_UI

	mov	cx, handle TSSCAttrList
	mov	dx, offset TSSCAttrList
	ret

TextStyleSheetControlGetModifyUI	endm

endif		; not NO_CONTROLLERS

TextControlCode ends
