COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiAreaColorSelector.asm

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
	Code for the GrObjAreaColorSelectorClass

	$Id: uiAreaColorSelector.asm,v 1.1 97/04/04 18:06:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

GC_Data	union
    GCD_dword	dword
    GCD_optr	optr
GC_Data	end

GC_NewField	struct
    GCNF_offset	byte
    GCNF_size	byte
    GCNF_data	GC_Data
GC_NewField	ends


COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAreaColorSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjAreaColorSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjAreaColorSelectorClass

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
GrObjAreaColorSelectorGetInfo	method dynamic	GrObjAreaColorSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset GrObjAreaColorSelectorClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset GOACS_newFields
	mov	cx, length GOACS_newFields
	call	CopyFieldsToBuildInfo
	ret

GrObjAreaColorSelectorGetInfo	endm

GOACS_newFields	GC_NewField	\
 <offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
 <offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword GOACS_IniFileKey>>,
 <offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword GOACS_gcnList>>,
 <offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword size GOACS_gcnList>>,
 <offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword GOACS_notifyList>>,
 <offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size GOACS_notifyList>>,
 <offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr GOACSName>>,
 <offset GCBI_features, size GCBI_features, <GCD_dword mask CSFeatures>>,
 <offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword GOACS_helpContext>>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOACS_helpContext	char	"dbGrObjArClr", 0
GOACS_IniFileKey	char	"GrObjAreaColor", 0

GOACS_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE>

GOACS_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_AREA_ATTR_CHANGE>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyFieldsToBuildInfo

DESCRIPTION:	Copy fields from a table of GC_NewField structures to
		a GenControlBuildInfo structure

CALLED BY:	INTERNAL

PASS:
	esdi - GenControlBuildInfo structure
	cs:si - table of GC_NewField structures
	cx - table length

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, si, bp, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
CopyFieldsToBuildInfo	proc	near

	segmov	ds, cs				;ds:si = source

copyLoop:
	push	cx, si, di
	clr	ax
	lodsb				;ax = offset
	add	di, ax
	clr	ax
	lodsb
	mov_tr	cx, ax			;cx = count
	rep movsb

	pop	cx, si, di
	add	si, size GC_NewField
	loop	copyLoop

	ret

CopyFieldsToBuildInfo	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAreaColorSelectorOutputAction -- MSG_GEN_OUTPUT_ACTION
					for GrObjAreaColorSelectorClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of GrObjAreaColorSelectorClass

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
GrObjAreaColorSelectorOutputAction	method dynamic	GrObjAreaColorSelectorClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset GrObjAreaColorSelectorClass
	FALL_THRU	ColorInterceptAction

GrObjAreaColorSelectorOutputAction	endm

;---

ColorInterceptAction	proc	far
	push	cx, si
	mov	bx, bp
	call	ObjGetMessageInfo			;ax = message
	pop	cx, si

	cmp	ax, MSG_META_COLORED_OBJECT_SET_COLOR
	jz	handleOurself
	cmp	ax, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	jz	handleOurself
	cmp	ax, MSG_META_COLORED_OBJECT_SET_PATTERN
	jz	handleOurself

	mov	ax, MSG_GEN_OUTPUT_ACTION
	GOTO	ObjCallSuperNoLock

handleOurself:

	; dispatch the event to ourself

	mov	cx, ds:[LMBH_handle]		;cx:si = dest
	call	MessageSetDestination
	clr	di				;no flags
	call	MessageDispatch
	ret

ColorInterceptAction	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAreaColorSelectorSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for GrObjAreaColorSelectorClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of GrObjAreaColorSelectorClass

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
GrObjAreaColorSelectorSetColor	method dynamic	GrObjAreaColorSelectorClass,
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

	mov	ax, MSG_GO_SET_AREA_COLOR
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret

GrObjAreaColorSelectorSetColor	endm

;---

GrObjAreaColorSelectorSetDrawMask	method dynamic	GrObjAreaColorSelectorClass, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	.enter

	mov	ax, MSG_GO_SET_AREA_MASK
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjAreaColorSelectorSetDrawMask	endm

;---

GrObjAreaColorSelectorSetPattern	method dynamic	GrObjAreaColorSelectorClass,
						MSG_META_COLORED_OBJECT_SET_PATTERN
	.enter

	mov	ax,MSG_GO_SET_AREA_PATTERN
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret

GrObjAreaColorSelectorSetPattern	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAreaColorSelectorUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for GrObjAreaColorSelectorClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of GrObjAreaColorSelectorClass

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
GrObjAreaColorSelectorUpdateUI	method dynamic GrObjAreaColorSelectorClass,
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

GrObjAreaColorSelectorUpdateUI	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateColorCommon

DESCRIPTION:	Common code to update a color selector

CALLED BY:	INTERNAL

PASS:
	*ds:si - controller
	ss:bp - GenControlUpdateUIParams
	dxcx - color
	al - SystemDrawMask
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
UpdateAreaColorCommon	proc	near	uses bp
	.enter

	push	bx				;save GraphicPattern
	push	ax				;save draw mask

	; update color

	mov	bp, di
	and	bp, mask GOBAAD_MULTIPLE_COLORS		;bp = indeterm
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_COLOR
	call	ObjCallInstanceNoLock

	; update draw mask

	pop	cx
	mov	dx, di
	and	dx, mask GOBAAD_MULTIPLE_MASKS
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_DRAW_MASK
	call	ObjCallInstanceNoLock

	; update pattern

	pop	cx
	mov	dx, di
	and	dx, mask GOBAAD_MULTIPLE_PATTERNS
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_PATTERN
	call	ObjCallInstanceNoLock

	.leave
	ret

UpdateAreaColorCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAreaNotifyColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to get notification data for color
CALLED BY:	GrObjAreaColorSelectorUpdateUI(), CharBGColorControlUpdateUI()

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

GetAreaNotifyColor	proc	near
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
	mov	al, ds:[GNAAC_areaAttr].GOBAAE_mask
	mov	ch, CF_RGB
	mov	cl, ds:[GNAAC_areaAttr].GOBAAE_r
	mov	dh, ds:[GNAAC_areaAttr].GOBAAE_b
	mov	dl, ds:[GNAAC_areaAttr].GOBAAE_g
	mov	bx, {word}ds:[GNAAC_areaAttr].GOBAAE_pattern
	mov	di, ds:[GNAAC_areaAttrDiffs]
done:

	.leave
	ret

GetAreaNotifyColor	endp

;---

UnlockNotifBlock	proc	near	uses bx
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock	;bx <- notification block
	call	MemUnlock

	.leave
	ret

UnlockNotifBlock	endp
GrObjUIControllerCode	ends
