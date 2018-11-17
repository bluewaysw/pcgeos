COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiAreaAttrControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	15 apr 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjAreaAttrControlClass

	$Id: uiAreaAttrControl.asm,v 1.1 97/04/04 18:05:33 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAreaAttrControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjAreaAttrControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjAreaAttrControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message AreaAttrr)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
GrObjAreaAttrControlGetInfo	method dynamic	GrObjAreaAttrControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOAAC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjAreaAttrControlGetInfo	endm

GOAAC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY or mask GCBF_CUSTOM_ENABLE_DISABLE,
	GOAAC_IniFileKey,		; GCBI_initFileKey
	GOAAC_gcnList,			; GCBI_gcnList
	length GOAAC_gcnList,		; GCBI_gcnCount
	GOAAC_notificationList,		; GCBI_notificationList
	length GOAAC_notificationList,	; GCBI_notificationCount
	GOAACName,			; GCBI_controllerName

	handle GrObjAreaAttrControlUI,	; GCBI_dupBlock
	GOAAC_childList,		; GCBI_childList
	length GOAAC_childList,		; GCBI_childCount
	GOAAC_featuresList,		; GCBI_featuresList
	length GOAAC_featuresList,	; GCBI_featuresCount

	GOAAC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	GOAAC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOAAC_helpContext	char	"dbGrObjArea", 0

GOAAC_IniFileKey	char	"GrObjAreaAttr", 0

GOAAC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_AREA_ATTR_CHANGE>

GOAAC_notificationList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_AREA_ATTR_CHANGE>


;---


GOAAC_childList	GenControlChildInfo \
	<offset GrObjAreaTransparentItemGroup, mask GOAACF_TRANSPARENCY,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjAreaMixModeGroup, mask GOAACF_MM_CLEAR or \
						mask GOAACF_MM_COPY or \
						mask GOAACF_MM_NOP or \
						mask GOAACF_MM_AND or \
						mask GOAACF_MM_INVERT or \
						mask GOAACF_MM_XOR or \
						mask GOAACF_MM_SET or \
						mask GOAACF_MM_OR, 0>

GOAAC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjAreaTransparentItemGroup, GOAACSeeThruName, 0>,
	<offset MMOrItem, GOAACMMOrName, 0>,
	<offset MMSetItem, GOAACMMSetName, 0>,
	<offset MMXorItem, GOAACMMXorName, 0>,
	<offset MMInvertItem, GOAACMMInvertName, 0>,
	<offset MMAndItem, GOAACMMAndName, 0>,
	<offset MMNopItem, GOAACMMNopName, 0>,
	<offset MMCopyItem, GOAACMMCopyName, 0>,
	<offset MMClearItem, GOAACMMClearName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjAreaAttrControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjAreaAttrControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjAreaAttrControlClass
	ax - MSG_GEN_CONTROL_UPDATE_UI

	ss:bp - GenControlUpdateUIParams

RETURN: nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	15 apr 1992	Initial version
------------------------------------------------------------------------------@
GrObjAreaAttrControlUpdateUI	method dynamic	GrObjAreaAttrControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
	uses	ax, cx, dx
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	dx, es:[GNAAC_areaAttrDiffs]
	mov	al, es:[GNAAC_areaAttr].GOBAAE_drawMode
	mov	cl, es:[GNAAC_areaAttr].GOBAAE_areaInfo
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_childBlock

	clr	ah, ch
	push	ax,dx					;save mix mode, diffs

	test	ss:[bp].GCUUIP_features, mask GOAACF_TRANSPARENCY
	jz	afterTransparency

	andnf	dx, mask GOBAAD_MULTIPLE_INFOS
	mov	si, offset GrObjAreaTransparentItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

afterTransparency:
	pop	cx, dx					;cx <- MixMode,
							;dx <- diffs

	test	ss:[bp].GCUUIP_features, mask GOAACF_MM_CLEAR or \
						mask GOAACF_MM_COPY or \
						mask GOAACF_MM_NOP or \
						mask GOAACF_MM_AND or \
						mask GOAACF_MM_INVERT or \
						mask GOAACF_MM_XOR or \
						mask GOAACF_MM_SET or \
						mask GOAACF_MM_OR
	jz	done

	andnf	dx, mask GOBAAD_MULTIPLE_DRAW_MODES
	mov	si, offset GrObjAreaMixModeItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjAreaAttrControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjAreaAttrControlSetMixMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAreaAttrControl method for MSG_GOAAC_SET_MIX_MODE

Called by:	

Pass:		*ds:si = GrObjAreaAttrControl object
		ds:di = GrObjAreaAttrControl instance
		cl - MixMode

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAreaAttrControlSetMixMode	method dynamic GrObjAreaAttrControlClass,
				MSG_GOAAC_SET_MIX_MODE
	.enter

	mov	ax, MSG_GO_SET_AREA_DRAW_MODE
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjAreaAttrControlSetMixMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjAreaAttrControlSetAreaTransparency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjAreaAttrControl method for MSG_GOAAC_SET_AREA_TRANSPARENCY

Called by:	

Pass:		*ds:si = GrObjAreaAttrControl object
		ds:di = GrObjAreaAttrControl instance
		cl - 0 or mask GOAAIR_TRANSPARENT

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjAreaAttrControlSetAreaTransparency	method dynamic \
		GrObjAreaAttrControlClass, MSG_GOAAC_SET_AREA_TRANSPARENCY

	.enter

CheckHack < (FALSE eq 0)>
	tst	cl
	jz	send
	mov	cl,TRUE
send:
	mov	ax, MSG_GO_SET_TRANSPARENCY
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjAreaAttrControlSetAreaTransparency	endm

GrObjUIControllerActionCode	ends
