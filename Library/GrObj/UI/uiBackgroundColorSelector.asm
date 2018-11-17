COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiBackgroundColorSelector.asm

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
	Code for the GrObjBackgroundColorSelectorClass

	$Id: uiBackgroundColorSelector.asm,v 1.1 97/04/04 18:05:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBackgroundColorSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjBackgroundColorSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjBackgroundColorSelectorClass

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
GrObjBackgroundColorSelectorGetInfo	method dynamic	GrObjBackgroundColorSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset GrObjBackgroundColorSelectorClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset GOBGCS_newFields
	mov	cx, length GOBGCS_newFields
	call	CopyFieldsToBuildInfo
	ret

GrObjBackgroundColorSelectorGetInfo	endm

GOBGCS_newFields	GC_NewField	\
 <offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
 <offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword GOBGCS_IniFileKey>>,
 <offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword GOBGCS_gcnList>>,
 <offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword size GOBGCS_gcnList>>,
 <offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword GOBGCS_notifyList>>,
 <offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size GOBGCS_notifyList>>,
 <offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr GOBGCSName>>,
 <offset GCBI_features, size GCBI_features,
				<GCD_dword GOBGCS_DEFAULT_FEATURES>>,
 <offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword GOBGCS_helpContext>>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOBGCS_helpContext	char	"dbGrObjBGClr", 0
GOBGCS_IniFileKey	char	"GrObjBackgroundColor", 0

GOBGCS_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE>

GOBGCS_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_AREA_ATTR_CHANGE>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBackgroundColorSelectorOutputAction -- MSG_GEN_OUTPUT_ACTION
					for GrObjBackgroundColorSelectorClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of GrObjBackgroundColorSelectorClass

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
GrObjBackgroundColorSelectorOutputAction	method dynamic	GrObjBackgroundColorSelectorClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset GrObjBackgroundColorSelectorClass
	GOTO	ColorInterceptAction

GrObjBackgroundColorSelectorOutputAction	endm

;---

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBackgroundColorSelectorSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for GrObjBackgroundColorSelectorClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of GrObjBackgroundColorSelectorClass

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
GrObjBackgroundColorSelectorSetColor	method dynamic	GrObjBackgroundColorSelectorClass,
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

	mov	ax, MSG_GO_SET_BG_COLOR
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret

GrObjBackgroundColorSelectorSetColor	endm

;---

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjBackgroundColorSelectorUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for GrObjBackgroundColorSelectorClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GrObjBackgroundColorSelectorClass

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
GrObjBackgroundColorSelectorUpdateUI	method dynamic GrObjBackgroundColorSelectorClass,
				MSG_GEN_CONTROL_UPDATE_UI

	mov	bx, ss:[bp].GCUUIP_dataBlock	;bx <- notification block
	call	MemLock
	mov	es, ax
	mov	ch, CF_RGB
	mov	cl, es:[GNAAC_areaAttr].GOBAAE_backR
	mov	dl, es:[GNAAC_areaAttr].GOBAAE_backG
	mov	dh, es:[GNAAC_areaAttr].GOBAAE_backB
	mov	bp, es:[GNAAC_areaAttrDiffs]
	call	MemUnlock

	andnf	bp, mask GOBAAD_MULTIPLE_BACKGROUND_COLORS
	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	call	ObjCallInstanceNoLock

	ret

GrObjBackgroundColorSelectorUpdateUI	endm

GrObjUIControllerCode	ends
