COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiLineColorSelector.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjLineColorSelectorClass

	$Id: uiLineColorSelector.asm,v 1.1 97/04/04 18:06:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource
COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLineColorSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjLineColorSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjLineColorSelectorClass

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
GrObjLineColorSelectorGetInfo	method dynamic	GrObjLineColorSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset GrObjLineColorSelectorClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset GOLCS_newFields
	mov	cx, length GOLCS_newFields
	call	CopyFieldsToBuildInfo
	ret

GrObjLineColorSelectorGetInfo	endm

GOLCS_newFields	GC_NewField	\
 <offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
 <offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword GOLCS_IniFileKey>>,
 <offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword GOLCS_gcnList>>,
 <offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword size GOLCS_gcnList>>,
 <offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword GOLCS_notifyList>>,
 <offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size GOLCS_notifyList>>,
 <offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr GOLCSName>>,
 <offset GCBI_features, size GCBI_features,
				<GCD_dword GOLCC_DEFAULT_FEATURES>>,
 <offset GCBI_toolFeatures, size GCBI_toolFeatures,
				<GCD_dword GOLCC_DEFAULT_TOOLBOX_FEATURES>>,
 <offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword GOLCS_helpContext>>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOLCS_helpContext	char	"dbGrObjLiClr", 0
GOLCS_IniFileKey	char	"GrObjLineColor", 0

GOLCS_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE>

GOLCS_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_LINE_ATTR_CHANGE>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLineColorSelectorOutputAction -- MSG_GEN_OUTPUT_ACTION
					for GrObjLineColorSelectorClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of GrObjLineColorSelectorClass

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
GrObjLineColorSelectorOutputAction	method dynamic	GrObjLineColorSelectorClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset GrObjLineColorSelectorClass
	call	ColorInterceptAction
	ret

GrObjLineColorSelectorOutputAction	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLineColorSelectorSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for GrObjLineColorSelectorClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of GrObjLineColorSelectorClass

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
GrObjLineColorSelectorSetColor	method dynamic	GrObjLineColorSelectorClass,
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

	mov	ax, MSG_GO_SET_LINE_COLOR
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret

GrObjLineColorSelectorSetColor	endm

;---

GrObjLineColorSelectorSetDrawMask	method dynamic	GrObjLineColorSelectorClass, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	.enter

	mov	ax, MSG_GO_SET_LINE_MASK
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjLineColorSelectorSetDrawMask	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLineColorSelectorUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for GrObjLineColorSelectorClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GrObjLineColorSelectorClass

	ax - The message

	ss:bp - GenControlUpdateUIParams
    		GCUUIP_manufacturer         ManufacturerIDs
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
GrObjLineColorSelectorUpdateUI	method dynamic GrObjLineColorSelectorClass,
				MSG_GEN_CONTROL_UPDATE_UI

	push	ds
	mov	dx, GWNT_GROBJ_LINE_ATTR_CHANGE
	call	GetLineNotifyColor
	jne	done
	call	UnlockNotifBlock
	pop	ds

	; dxcx - color
	; al - DrawMasks
	; bx - GraphicPattern 		NOT YET
	; di - VisTextCharAttrFlags
	;	GAAD_MULTIPLE_COLORS
	;	GAAD_MULTIPLE_GRAY_SCREENS
	;	GAAD_MULTIPLE_PATTERNS

	call	UpdateLineColorCommon
done:
	ret

GrObjLineColorSelectorUpdateUI	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateColorCommon

DESCRIPTION:	Common code to update a color selector

CALLED BY:	INTERNAL

PASS:
	*ds:si - controller
	ss:bp - GenControlUpdateUIParams
	dxcx - color
	al - DrawMasks
	bx - GraphicPattern
	di - VisTextCharAttrFlags
		VTCAF_MULTIPLE_COLORS
		VTCAF_MULTIPLE_GRAY_SCREENS
		VTCAF_MULTIPLE_PATTERNS

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
UpdateLineColorCommon	proc	near	uses bp
	.enter

;	push	bx				;save hatch
	push	ax				;save draw mask

	; update color

	mov	bp, di
	and	bp, mask GOBLAD_MULTIPLE_COLORS		;bp = indeterm
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_COLOR
	call	ObjCallInstanceNoLock

	; update draw mask

	pop	cx
	mov	dx, di
	and	dx, mask GOBLAD_MULTIPLE_MASKS
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_DRAW_MASK
	call	ObjCallInstanceNoLock

	.leave
	ret

UpdateLineColorCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineNotifyColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to get notification data for color
CALLED BY:	GrObjLineColorSelectorUpdateUI(), CharBGColorControlUpdateUI()

PASS:		ss:bp - GenControlUpdateUIParams
	    		GCUUIP_manufacturer         ManufacturerID
	    		GCUUIP_changeType           word
	    		GCUUIP_dataBlock            hptr
			
	    		GCUUIP_toolInteraction      optr
	    		GCUUIP_features             word 
	    		GCUUIP_toolboxFeatures      word
	    		GCUUIP_childBlock           hptr

		dx - NotifyStandardNotificationTypes to match
		NOTE: this notification type must use NotifyColorChange

RETURN: 	ds - seg addr of notification block

		z flag - set if common color notification:
		di - VisTextCharAttrFlags
		    VTCAF_MULTIPLE_COLORS
		    VTCAF_MULTIPLE_GRAY_SCREENS
		    	-or-
		    VTCAF_MULTIPLE_BG_COLORS
		    VTCAF_MULTIPLE_BG_GRAY_SCREENS
		    	-or-
		    VTPAF_MULTIPLE_BG_COLORS
		    VTPAF_MULTIPLE_BG_GRAY_SCREENS
		    	-or-
		    VTPABF_MULTIPLE_BORDER_COLORS
		    VTPABF_MULTIPLE_BORDER_GRAY_SCREENS
		ax - SystemDrawMask
		dxcx - color
		bx - GraphicPattern

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetLineNotifyColor	proc	near
	.enter

	;
	; Get notification data and figure out what type it is
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock	;bx <- notification block
	call	MemLock
	mov	ds, ax
	clr	ax
	cmp	ss:[bp].GCUUIP_changeType, dx	;common type?
	jne	done				;branch if not
	;
	; Get color from NotifyColorChange (common structure)
	;
	mov	al, ds:[GNLAC_lineAttr].GOBLAE_mask
	mov	ch, CF_RGB
	mov	cl, ds:[GNLAC_lineAttr].GOBLAE_r
	mov	dh, ds:[GNLAC_lineAttr].GOBLAE_b
	mov	dl, ds:[GNLAC_lineAttr].GOBLAE_g
;	mov	bx, {word} ds:NCC_pattern
	mov	di, ds:[GNLAC_lineAttrDiffs]
done:

	.leave
	ret

GetLineNotifyColor	endp


GrObjUIControllerCode	ends
