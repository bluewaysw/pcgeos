COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiLineWidthControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	15 apr 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjLineWidthControlClass

	$Id: uiLineAttrControl.asm,v 1.1 97/04/04 18:05:32 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLineAttrControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjLineAttrControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjLineAttrControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message LineWidthr)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
GrObjLineAttrControlGetInfo	method dynamic	GrObjLineAttrControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOLAC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjLineAttrControlGetInfo	endm

GOLAC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY or mask GCBF_CUSTOM_ENABLE_DISABLE,
	GOLAC_IniFileKey,		; GCBI_initFileKey
	GOLAC_gcnList,			; GCBI_gcnList
	length GOLAC_gcnList,		; GCBI_gcnCount
	GOLAC_notificationList,		; GCBI_notificationList
	length GOLAC_notificationList,	; GCBI_notificationCount
	GOLACName,			; GCBI_controllerName

	handle GrObjLineAttrControlUI,	; GCBI_dupBlock
	GOLAC_childList,		; GCBI_childList
	length GOLAC_childList,		; GCBI_childCount
	GOLAC_featuresList,		; GCBI_featuresList
	length GOLAC_featuresList,	; GCBI_featuresCount

	GOLAC_DEFAULT_FEATURES,		; GCBI_features

	handle GrObjLineAttrControlToolboxUI,	; GCBI_toolBlock
	GOLAC_toolList,				; GCBI_toolList
	length GOLAC_toolList,			; GCBI_toolCount
	GOLAC_toolFeaturesList,			; GCBI_toolFeaturesList
	length GOLAC_toolFeaturesList,		; GCBI_toolFeaturesCount

	GOLAC_DEFAULT_TOOLBOX_FEATURES,			; GCBI_toolFeatures
	GOLAC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOLAC_helpContext	char	"dbGrObjLine", 0

GOLAC_IniFileKey	char	"GrObjLineAttr", 0

GOLAC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE>

GOLAC_notificationList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_LINE_ATTR_CHANGE>


;---


GOLAC_childList	GenControlChildInfo \
	<offset GrObjLineWidthItemGroup, mask GOLACF_WIDTH_INDEX, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjLineWidthValue, mask GOLACF_WIDTH_VALUE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjLineStyleItemGroup, mask GOLACF_STYLE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjArrowheadTypeList, mask GOLACF_ARROWHEAD_TYPE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjArrowheadWhichEndList, mask GOLACF_ARROWHEAD_WHICH_END, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOLAC_toolList	GenControlChildInfo \
	<offset GrObjLineWidthToolboxItemGroup, mask GOLACTF_WIDTH_INDEX, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset GrObjLineStyleToolboxItemGroup, mask GOLACTF_STYLE, mask GCCF_IS_DIRECTLY_A_FEATURE>

GOLAC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjArrowheadWhichEndList, ArrowheadWhichEndName, 0>,
	<offset GrObjArrowheadTypeList, ArrowheadTypeName, 0>,
	<offset GrObjLineStyleItemGroup, LineStylesName, 0>,
	<offset GrObjLineWidthValue, FineTuneLineWidthName, 0>,
	<offset GrObjLineWidthItemGroup, IndexedLineWidthName, 0>

GOLAC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset GrObjLineStyleToolboxItemGroup, LineStylesName, 0>,
	<offset GrObjLineWidthToolboxItemGroup, IndexedLineWidthName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjLineAttrControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjLineAttrControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjLineAttrControlClass
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
GrObjLineAttrControlUpdateUI	method dynamic	GrObjLineAttrControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
	uses	ax, cx, dx
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	LONG	jc	done
	mov	es, ax

	mov	di, es:[GNLAC_lineAttrDiffs]
	mov	cl, es:[GNLAC_lineAttr].GOBLAE_arrowheadAngle
	mov	ch, es:[GNLAC_lineAttr].GOBLAE_arrowheadLength
	mov	dl, es:[GNLAC_lineAttr].GOBLAE_lineInfo

	push	di, cx, dx			;save diffs, arrowhead, info

	movwwf	dxcx, es:[GNLAC_lineAttr].GOBLAE_width
	mov	al, es:[GNLAC_lineAttr].GOBLAE_style
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_childBlock

	push	di, ax					;save diffs, style

	mov	ax, MSG_GEN_VALUE_SET_VALUE
	test	ss:[bp].GCUUIP_features, mask GOLACF_WIDTH_VALUE
	jz	afterWidthValue

	push	di,bp					;save diffs, params
	mov	bp, di					;bp <- params
	andnf	bp, mask GOBLAD_MULTIPLE_WIDTHS
	mov	si, offset GrObjLineWidthValue
	clr	di
	call	ObjMessage
	pop	di,bp					;di <- diffs,
							;bp <- params

afterWidthValue:
	xchg	cx, dx
	test	di, mask GOBLAD_MULTIPLE_WIDTHS
	jz	setWidthExcl
	mov	dx, di					;non-zero for indet.
setWidthExcl:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	test	ss:[bp].GCUUIP_features, mask GOLACF_WIDTH_INDEX
	jz	afterWidthIndex
	mov	si, offset GrObjLineWidthItemGroup
	clr	di
	call	ObjMessage

afterWidthIndex:
	mov	bx, ss:[bp].GCUUIP_toolBlock
	test	ss:[bp].GCUUIP_toolboxFeatures, mask GOLACTF_WIDTH_INDEX
	jz	afterToolWidthIndex
	mov	si, offset GrObjLineWidthToolboxItemGroup
	clr	di
	call	ObjMessage

afterToolWidthIndex:
	pop	ax, cx					;ax <- diffs
							;cl <- style
	clr	ch
	clr	dx
	test	ax, mask GOBLAD_MULTIPLE_STYLES
	jz	setStyleExcl
	inc	dx					;indeterminate
setStyleExcl:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	test	ss:[bp].GCUUIP_toolboxFeatures, mask GOLACTF_STYLE
	jz	afterToolStyle
	mov	si, offset GrObjLineStyleToolboxItemGroup
	clr	di
	call	ObjMessage

afterToolStyle:
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ss:[bp].GCUUIP_features, mask GOLACF_STYLE
	jz	afterStyle
	mov	si, offset GrObjLineStyleItemGroup
	clr	di
	call	ObjMessage

afterStyle:
	pop	dx, cx, ax			;save diffs, arrowhead, info

	push	ax, dx					;save info, diffs
	;
	;  Construct a StandardArrowheadType out of the info
	;
CheckHack	<offset SAT_LENGTH eq 10>
	shl	ch
	shl	ch
	test	al, mask GOLAIR_ARROWHEAD_FILLED
	jz	haveSAT

	BitSet	cx, SAT_FILLED

	test	al, mask GOLAIR_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES
	jz	haveSAT

	BitSet	cx, SAT_FILL_WITH_AREA_ATTRIBUTES

haveSAT:
	andnf	dx,	mask GOBLAD_MULTIPLE_ARROWHEAD_ANGLES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_LENGTHS or \
			mask GOBLAD_ARROWHEAD_FILLED or \
			mask GOBLAD_ARROWHEAD_FILL_WITH_AREA_ATTRIBUTES

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	test	ss:[bp].GCUUIP_features, mask GOLACF_ARROWHEAD_TYPE
	jz	afterArrowheadType
	mov	si, offset GrObjArrowheadTypeList
	clr	di
	call	ObjMessage

afterArrowheadType:

CheckHack <offset GOBLAD_ARROWHEAD_ON_END eq offset GOLAIR_ARROWHEAD_ON_END>
CheckHack <offset GOBLAD_ARROWHEAD_ON_START eq offset GOLAIR_ARROWHEAD_ON_START>
	pop	cx, dx					;cl <- info
							;dx <- diffs
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	test	ss:[bp].GCUUIP_features, mask GOLACF_ARROWHEAD_WHICH_END
	jz	done
	mov	si, offset GrObjArrowheadWhichEndList
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjLineAttrControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjLineAttrControlSetIntegerLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLineAttrControl method for MSG_GOLAC_SET_INTEGER_LINE_WIDTH

Called by:	

Pass:		*ds:si = GrObjLineAttrControl object
		ds:di = GrObjLineAttrControl instance

		cx = line width

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLineAttrControlSetIntegerLineWidth	method dynamic	GrObjLineAttrControlClass, MSG_GOLAC_SET_INTEGER_LINE_WIDTH

	.enter

EC <	tst	cx						>
EC <	ERROR_S GROBJ_BUMMER_YOUVE_GOT_A_NEGATIVE_LINE_WIDTH____GET_STEVE_NOW

	mov	dx, cx
	clr	cx
	mov	ax, MSG_GO_SET_LINE_WIDTH
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjLineAttrControlSetIntegerLineWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjLineAttrControlSetLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLineAttrControl method for MSG_GOLAC_SET_LINE_WIDTH

Called by:	

Pass:		*ds:si = GrObjLineAttrControl object
		ds:di = GrObjLineAttrControl instance

		dx:cx = wwf line width

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLineAttrControlSetLineWidth	method dynamic	GrObjLineAttrControlClass, MSG_GOLAC_SET_LINE_WIDTH

	.enter

EC <	tst	dx						>
EC <	ERROR_S GROBJ_BUMMER_YOUVE_GOT_A_NEGATIVE_LINE_WIDTH____GET_STEVE_NOW

	mov	ax, MSG_GO_SET_LINE_WIDTH
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjLineAttrControlSetLineWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjLineAttrControlSetLineStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLineAttrControl method for MSG_GOLAC_SET_LINE_STYLE

Called by:	

Pass:		*ds:si = GrObjLineAttrControl object
		ds:di = GrObjLineAttrControl instance

		cl = LineStyle

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLineAttrControlSetLineStyle	method dynamic	GrObjLineAttrControlClass, MSG_GOLAC_SET_LINE_STYLE

	.enter

	mov	ax, MSG_GO_SET_LINE_STYLE
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjLineAttrControlSetLineStyle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjLineAttrControlSetArrowheadType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLineAttrControl method for MSG_GOLAC_SET_ARROWHEAD_TYPE

Called by:	

Pass:		*ds:si = GrObjLineAttrControl object
		ds:di = GrObjLineAttrControl instance

		cx - StandardArrowheadType

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLineAttrControlSetArrowheadType	method dynamic	GrObjLineAttrControlClass, MSG_GOLAC_SET_ARROWHEAD_TYPE

	.enter

	mov	ax, MSG_GO_SET_ARROWHEAD_ANGLE
	call	GrObjControlOutputActionRegsToGrObjs

CheckHack	<offset SAT_LENGTH eq 10>
	mov	cl, ch					;cl <- radius * 2
	shr	cl
	shr	cl

	mov	ax, MSG_GO_SET_ARROWHEAD_LENGTH
	call	GrObjControlOutputActionRegsToGrObjs

	mov	cl, ch
	and	cx,  (mask SAT_FILLED shr 8) or mask SAT_FILL_WITH_AREA_ATTRIBUTES
	mov	ax, MSG_GO_SET_ARROWHEAD_FILLED
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjLineAttrControlSetArrowheadType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjLineAttrControlSetArrowheadWhichEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLineAttrControl method for
		MSG_GOLAC_SET_ARROWHEAD_WHICH_END

Called by:	

Pass:		*ds:si = GrObjLineAttrControl object
		ds:di = GrObjLineAttrControl instance

		cl - GrObjLineAttrInfoRecord with GOLAIR_ARROWHEAD_ON_* set
			appropriately

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLineAttrControlSetArrowheadWhichEnd	method dynamic	GrObjLineAttrControlClass, MSG_GOLAC_SET_ARROWHEAD_WHICH_END

	.enter

	push	cx
	andnf	cl, mask GOLAIR_ARROWHEAD_ON_START

	mov	ax, MSG_GO_SET_ARROWHEAD_ON_START
	call	GrObjControlOutputActionRegsToGrObjs

	pop	cx
	andnf	cl, mask GOLAIR_ARROWHEAD_ON_END

	mov	ax, MSG_GO_SET_ARROWHEAD_ON_END
	call	GrObjControlOutputActionRegsToGrObjs

	.leave
	ret
GrObjLineAttrControlSetArrowheadWhichEnd	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjLineAttrControlSetLineValueFromIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLineAttrControl method for
		MSG_GOLAC_SET_LINE_VALUE_FROM_INDEX

Called by:	

Pass:		*ds:si = GrObjLineAttrControl object
		ds:di = GrObjLineAttrControl instance

		cx = integer line width

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLineAttrControlSetLineValueFromIndex	method dynamic	GrObjLineAttrControlClass, MSG_GOLAC_SET_LINE_VALUE_FROM_INDEX

	uses	cx,dx
	.enter

	;
	;  If we don't "do" values, then skip
	;
	call	GetChildBlockAndFeatures
	test	ax, mask GOLACF_WIDTH_VALUE
	jz	done

	;
	;  Set the value
	;
	clr	bp
	mov	si, offset GrObjLineWidthValue
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjLineAttrControlSetLineValueFromIndex	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjLineAttrControlSetLineIndexFromValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjLineAttrControl method for
		MSG_GOLAC_SET_LINE_INDEX_FROM_VALUE

Called by:	

Pass:		*ds:si = GrObjLineAttrControl object
		ds:di = GrObjLineAttrControl instance

		dx:cx = wwf line width

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr 15, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjLineAttrControlSetLineIndexFromValue	method dynamic	GrObjLineAttrControlClass, MSG_GOLAC_SET_LINE_INDEX_FROM_VALUE

	uses	cx,dx
	.enter

	call	GetChildBlockAndFeatures
	test	ax, mask GOLACF_WIDTH_INDEX
	jz	done

	;
	;	dx:cx <- WWFixed line index
	;
	xchg	cx, dx				;cx <- integer line width
						;dx <- fraction (indet.)
	mov	si, offset GrObjLineWidthItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

done:
	.leave
	ret
GrObjLineAttrControlSetLineIndexFromValue	endm

GrObjUIControllerActionCode	ends
