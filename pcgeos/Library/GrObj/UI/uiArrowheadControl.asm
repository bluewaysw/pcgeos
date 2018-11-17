COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiArrowheadControl.asm

AUTHOR:		Jon Witort

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	24 feb 1992   	Initial version.

DESCRIPTION:
	Code for the GrObjArrowheadControlClass

	$Id: uiArrowheadControl.asm,v 1.1 97/04/04 18:06:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjArrowheadControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjArrowheadControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjArrowheadControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
GrObjArrowheadControlGetInfo	method dynamic	GrObjArrowheadControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOAHC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjArrowheadControlGetInfo	endm

GOAHC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,		; GCBI_flags
	GOAHC_IniFileKey,		; GCBI_initFileKey
	GOAHC_gcnList,			; GCBI_gcnList
	length GOAHC_gcnList,		; GCBI_gcnCount
	GOAHC_notifyList,		; GCBI_notificationList
	length GOAHC_notifyList,		; GCBI_notificationCount
	GOAHCName,			; GCBI_controllerName

	handle GrObjArrowheadControlUI,	; GCBI_dupBlock
	GOAHC_childList,			; GCBI_childList
	length GOAHC_childList,		; GCBI_childCount
	GOAHC_featuresList,		; GCBI_featuresList
	length GOAHC_featuresList,	; GCBI_featuresCount

	GOAHC_DEFAULT_FEATURES,		; GCBI_defaultFeatures

	0,	; GCBI_dupBlock
	0,	; GCBI_childList
	0,	; GCBI_childCount
	0,	; GCBI_featuresList
	0,	; GCBI_featuresCount

	0>	; GCBI_defaultFeatures

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOAHC_IniFileKey	char	"GrObjArrowhead", 0

GOAHC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, \
		GAGCNLT_APP_TARGET_NOTIFY_GROBJ_LINE_ATTR_CHANGE>

GOAHC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_LINE_ATTR_CHANGE>

;---


GOAHC_childList	GenControlChildInfo \
	<offset GrObjArrowheadTypeList, mask GOAHCF_TYPE, 0>,
	<offset GrObjArrowheadWhichEndList, mask GOAHCF_WHICH_END, 0>

GOAHC_featuresList	GenControlFeaturesInfo	\
	<offset GrObjArrowheadWhichEndList, ArrowheadWhichEndName, 0>,
	<offset GrObjArrowheadTypeList, ArrowheadTypeName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjArrowheadControlSetArrowheadType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjArrowheadControl method for MSG_GOAHC_SET_ARROWHEAD_TYPE

Called by:	

Pass:		*ds:si = GrObjArrowheadControl object
		ds:di = GrObjArrowheadControl instance

		cx - StandardArrowheadType

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 24, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjArrowheadControlSetArrowheadType	method dynamic	GrObjArrowheadControlClass, MSG_GOAHC_SET_ARROWHEAD_TYPE

	.enter

	mov	ax, MSG_GO_SET_ARROWHEAD_ANGLE
	mov	bx, segment GrObjClass
	mov	di, offset GrObjClass
	call	GenControlOutputActionRegs

	mov	cl, ch					;cl <- radius * 2
	shr	cl

	mov	ax, MSG_GO_SET_ARROWHEAD_LENGTH
	mov	bx, segment GrObjClass
	mov	di, offset GrObjClass
	call	GenControlOutputActionRegs

	mov	cl, ch
	andnf	cl, mask SAT_FILLED shr 8

	mov	ax, MSG_GO_SET_ARROWHEAD_FILLED
	mov	bx, segment GrObjClass
	mov	di, offset GrObjClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjArrowheadControlSetArrowheadType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjArrowheadControlSetArrowheadWhichEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjArrowheadControl method for
		MSG_GOAHC_SET_ARROWHEAD_WHICH_END

Called by:	

Pass:		*ds:si = GrObjArrowheadControl object
		ds:di = GrObjArrowheadControl instance

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
GrObjArrowheadControlSetArrowheadWhichEnd	method dynamic	GrObjArrowheadControlClass, MSG_GOAHC_SET_ARROWHEAD_WHICH_END

	.enter

	push	cx
	andnf	cl, mask GOLAIR_ARROWHEAD_ON_START

	mov	ax, MSG_GO_SET_ARROWHEAD_ON_START
	mov	bx, segment GrObjClass
	mov	di, offset GrObjClass
	call	GenControlOutputActionRegs

	pop	cx
	andnf	cl, mask GOLAIR_ARROWHEAD_ON_END

	mov	ax, MSG_GO_SET_ARROWHEAD_ON_END
	mov	bx, segment GrObjClass
	mov	di, offset GrObjClass
	call	GenControlOutputActionRegs

	.leave
	ret
GrObjArrowheadControlSetArrowheadWhichEnd	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjArrowheadControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjArrowheadControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjArrowheadControlClass
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
GrObjArrowheadControlUpdateUI	method dynamic	GrObjArrowheadControlClass,
				MSG_GEN_CONTROL_UPDATE_UI
	uses	ax, cx, dx
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	jc	done
	mov	es, ax
	mov	dx, es:[GNLAC_lineAttrDiffs]
	mov	cl, es:[GNLAC_lineAttr].GOBLAE_arrowheadAngle
	mov	ch, es:[GNLAC_lineAttr].GOBLAE_arrowheadLength
	mov	al, es:[GNLAC_lineAttr].GOBLAE_lineInfo
	call	MemUnlock
	mov	bx, ss:[bp].GCUUIP_childBlock

	push	ax, dx					;save info, diffs
	;
	;  Construct a StandardArrowheadType out of the info
	;
	shl	ch
	test	al, mask GOLAIR_ARROWHEAD_FILLED
	jz	haveSAT

	BitSet	cx, SAT_FILLED

haveSAT:
	andnf	dx,	mask GOBLAD_MULTIPLE_ARROWHEAD_ANGLES or \
			mask GOBLAD_MULTIPLE_ARROWHEAD_LENGTHS or \
			mask GOBLAD_ARROWHEAD_FILLED

	mov	si, offset GrObjArrowheadTypeList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage

CheckHack <offset GOBLAD_ARROWHEAD_ON_END eq offset GOLAIR_ARROWHEAD_ON_END>
CheckHack <offset GOBLAD_ARROWHEAD_ON_START eq offset GOLAIR_ARROWHEAD_ON_START>
	pop	cx, dx					;cl <- info
							;dx <- diffs
	mov	si, offset GrObjArrowheadWhichEndList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	di
	call	ObjMessage
done:
	.leave
	ret
GrObjArrowheadControlUpdateUI	endm



GrObjUIControllerCode	ends
