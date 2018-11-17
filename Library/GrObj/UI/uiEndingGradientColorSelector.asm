COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiEndingGradientColorSelector.asm

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
	Code for the GrObjEndingGradientColorSelectorClass

	$Id: uiEndingGradientColorSelector.asm,v 1.1 97/04/04 18:06:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjEndingGradientColorSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjEndingGradientColorSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjEndingGradientColorSelectorClass

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


GrObjEndingGradientColorSelectorGetInfo	method dynamic	GrObjEndingGradientColorSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset GrObjEndingGradientColorSelectorClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset GOEGCS_newFields
	mov	cx, length GOEGCS_newFields
	call	CopyFieldsToBuildInfo
	ret

GrObjEndingGradientColorSelectorGetInfo	endm

GOEGCS_newFields	GC_NewField	\
 <offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
 <offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword GOEGCS_IniFileKey>>,
 <offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword GOEGCS_gcnList>>,
 <offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword size GOEGCS_gcnList>>,
 <offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword GOEGCS_notifyList>>,
 <offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size GOEGCS_notifyList>>,
 <offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr GOEGCSName>>,
 <offset GCBI_features, size GCBI_features,
				<GCD_dword GOEGCS_DEFAULT_FEATURES>>,
 <offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword GOEGCS_helpContext>>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOEGCS_helpContext	char	"dbEndGradClr", 0
GOEGCS_IniFileKey	char	"GrObjEndingGradientColor", 0

GOEGCS_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_GRADIENT_ATTR_CHANGE>

GOEGCS_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_GRADIENT_ATTR_CHANGE>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjEndingGradientColorSelectorOutputAction -- MSG_GEN_OUTPUT_ACTION
					for GrObjEndingGradientColorSelectorClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of GrObjEndingGradientColorSelectorClass

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
GrObjEndingGradientColorSelectorOutputAction	method dynamic	GrObjEndingGradientColorSelectorClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset GrObjEndingGradientColorSelectorClass
	GOTO	ColorInterceptAction

GrObjEndingGradientColorSelectorOutputAction	endm

;---

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjEndingGradientColorSelectorSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for GrObjEndingGradientColorSelectorClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of GrObjEndingGradientColorSelectorClass

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
GrObjEndingGradientColorSelectorSetColor	method dynamic	GrObjEndingGradientColorSelectorClass,
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

	mov	ch, dl
	mov	dl, dh

	mov	ax, MSG_GO_SET_ENDING_GRADIENT_COLOR
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret

GrObjEndingGradientColorSelectorSetColor	endm

;---

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjEndingGradientColorSelectorUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for GrObjEndingGradientColorSelectorClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GrObjEndingGradientColorSelectorClass

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
GrObjEndingGradientColorSelectorUpdateUI	method dynamic GrObjEndingGradientColorSelectorClass,
				MSG_GEN_CONTROL_UPDATE_UI

	mov	bx, ss:[bp].GCUUIP_dataBlock	;bx <- notification block
	call	MemLock
	mov	es, ax
	mov	ch, CF_RGB
	mov	cl, es:[GONGAC_endR]
	mov	dl, es:[GONGAC_endG]
	mov	dh, es:[GONGAC_endB]
	mov	al, es:[GONGAC_diffs]
	call	MemUnlock

	mov_tr	bp, ax
	andnf	bp, mask GGAD_MULTIPLE_END_COLORS
	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	call	ObjCallInstanceNoLock

	ret

GrObjEndingGradientColorSelectorUpdateUI	endm

GrObjUIControllerCode	ends
