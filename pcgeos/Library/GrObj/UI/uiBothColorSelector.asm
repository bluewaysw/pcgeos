COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiBothColorSelector.asm

AUTHOR:		Jon Witort

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjBothColorSelectorClass

	$Id: uiBothColorSelector.asm,v 1.1 97/04/04 18:06:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBothColorSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjBothColorSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjBothColorSelectorClass

	ax - The message

RETURN:
	cx:dx - list of children

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
GrObjBothColorSelectorGetInfo	method dynamic	GrObjBothColorSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset GrObjBothColorSelectorClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset GOBCS_newFields
	mov	cx, length GOBCS_newFields
	call	CopyFieldsToBuildInfo
	ret

GrObjBothColorSelectorGetInfo	endm

GOBCS_newFields	GC_NewField	\
 <offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
 <offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword GOBCS_IniFileKey>>,
 <offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword GOBCS_gcnList>>,
 <offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword size GOBCS_gcnList>>,
 <offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword GOBCS_notifyList>>,
 <offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size GOBCS_notifyList>>,
 <offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr GOBCSName>>,
 <offset GCBI_features, size GCBI_features,
				<GCD_dword GOBCS_DEFAULT_FEATURES>>,
 <offset GCBI_toolFeatures, size GCBI_toolFeatures,
				<GCD_dword GOBCS_DEFAULT_TOOLBOX_FEATURES>>,
 <offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword GOBCS_helpContext>>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOBCS_helpContext	char	"dbGrObjClr", 0

GOBCS_IniFileKey	char	"GrObjBothColor", 0

GOBCS_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE>

GOBCS_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_AREA_ATTR_CHANGE>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBothColorSelectorOutputAction -- MSG_GEN_OUTPUT_ACTION
					for GrObjBothColorSelectorClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of GrObjBothColorSelectorClass

	ax - The message

	cx:dx - destination (or travel option)
	bp - event

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
GrObjBothColorSelectorOutputAction	method dynamic	GrObjBothColorSelectorClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset GrObjBothColorSelectorClass
	call	ColorInterceptAction
	ret

GrObjBothColorSelectorOutputAction	endm

;---

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBothColorSelectorSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for GrObjBothColorSelectorClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of GrObjBothColorSelectorClass

	ax - The message

	dxcx - color

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
GrObjBothColorSelectorSetColor	method dynamic	GrObjBothColorSelectorClass,
						MSG_META_COLORED_OBJECT_SET_COLOR

	uses	ax, cx, dx, bp
	.enter

	; if passed index then convert to RGB

	cmp	ch, CF_RGB
	jz	rgb

	; must convert index to rgb

	xchgdw	dxcx, bxax
	clr	di
	mov	ah, al			;ah = index
	call	GrMapColorIndex		;al <- red, bl <- green, bh <- blue
	xchgdw	dxcx, bxax
rgb:

	; cl = red, dl = green, dh = blue

	mov	ch, CF_RGB
	pushdw	dxcx				;save ColorQuad for text

	mov	ch, dl
	mov	dl, dh

	mov	ax, MSG_GO_SET_AREA_COLOR
	call	GrObjControlOutputActionRegsToGrObjs

	mov	ax, MSG_GO_SET_LINE_COLOR
	call	GrObjControlOutputActionRegsToGrObjs

	mov	ax, MSG_VIS_TEXT_SET_COLOR
	clr	dx
	push	dx			;range.end.high
	push	dx			;range.end.low
	mov	bx, VIS_TEXT_RANGE_SELECTION
	push	bx			;range.start.high
	push	dx			;range.start.low
	mov	bp, sp
	mov	dx, size VisTextSetColorParams
	clr	bx
	clr	di
	call	GenControlOutputActionStack
	add	sp, size VisTextSetColorParams

	.leave
	ret

GrObjBothColorSelectorSetColor	endm


;---

GrObjBothColorSelectorSetDrawMask	method dynamic	GrObjBothColorSelectorClass, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	.enter

	mov	ax, MSG_GO_SET_AREA_MASK
	call	GrObjControlOutputActionRegsToGrObjs

	mov	ax, MSG_GO_SET_LINE_MASK
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjBothColorSelectorSetDrawMask	endm

;---

GrObjBothColorSelectorSetPattern	method dynamic	GrObjBothColorSelectorClass,
						MSG_META_COLORED_OBJECT_SET_PATTERN
	.enter

	mov	ax,MSG_GO_SET_AREA_PATTERN
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret

GrObjBothColorSelectorSetPattern	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBothColorSelectorUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for GrObjBothColorSelectorClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GrObjBothColorSelectorClass

	ax - The message

	ss:bp - GenControlUpdateUIParams
    		GCUUIP_manufacturer         ManufacturerID
    		GCUUIP_changeType           word
    		GCUUIP_dataBlock            hptr
			
    		GCUUIP_toolInteraction      optr
    		GCUUIP_features             word 
    		GCUUIP_toolboxFeatures      word
    		GCUUIP_childBlock           hptr

RETURN:	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
GrObjBothColorSelectorUpdateUI	method dynamic GrObjBothColorSelectorClass,
				MSG_GEN_CONTROL_UPDATE_UI

	push	ds
	mov	dx, GWNT_GROBJ_AREA_ATTR_CHANGE
	call	GetAreaNotifyColor
	jne	done
	call	UnlockNotifBlock
	pop	ds

	; dxcx - color
	; al - SystemDrawMask
	; bx - GraphicPattern 		NOT YET
	; di - VisTextCharAttrFlags
	;	GOBAAD_MULTIPLE_COLORS
	;	GOBAAD_MULTIPLE_GRAY_SCREENS
	;	GOBAAD_MULTIPLE_PATTERNS

	call	UpdateAreaColorCommon
done:
	ret

GrObjBothColorSelectorUpdateUI	endm

GrObjUIControllerCode	ends
