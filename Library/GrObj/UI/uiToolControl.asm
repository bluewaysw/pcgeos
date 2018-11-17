COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiToolControl.asm

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
	Code for the GrObjToolControlClass

	$Id: uiToolControl.asm,v 1.1 97/04/04 18:06:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjUIControllerCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjToolControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for GrObjToolControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of GrObjToolControlClass

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
GrObjToolControlGetInfo	method dynamic	GrObjToolControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset GOTC_dupInfo
	call	CopyDupInfoCommon
	ret
GrObjToolControlGetInfo	endm

GOTC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	GOTC_IniFileKey,		; GCBI_initFileKey
	GOTC_gcnList,			; GCBI_gcnList
	length GOTC_gcnList,		; GCBI_gcnCount
	GOTC_notifyList,		; GCBI_notificationList
	length GOTC_notifyList,		; GCBI_notificationCount
	GOTCName,			; GCBI_controllerName

	0,				; GCBI_dupBlock
	0,				; GCBI_childList
	0,				; GCBI_childCount
	0,				; GCBI_featuresList
	0,				; GCBI_featuresCount

	0,				; GCBI_features

	handle GrObjToolControlToolboxUI,	; GCBI_toolBlock
	GOTC_toolList,			; GCBI_toolList
	length GOTC_toolList,		; GCBI_toolCount
	GOTC_toolFeaturesList,		; GCBI_toolFeaturesList
	length GOTC_toolFeaturesList,	; GCBI_toolFeaturesCount

	GOTC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	GOTC_helpContext>		; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	segment	resource
endif

GOTC_helpContext	char	"dbGrObjTool", 0

GOTC_IniFileKey	char	"GrObjTool", 0

GOTC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS,
			GAGCNLT_APP_TARGET_NOTIFY_GROBJ_CURRENT_TOOL_CHANGE>

GOTC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_GROBJ_CURRENT_TOOL_CHANGE>

;---

GOTC_toolList	GenControlChildInfo \
	<offset GrObjToolItemGroup, mask GOTCFeatures, mask GCCF_ALWAYS_ADD>

GOTC_toolFeaturesList	GenControlFeaturesInfo	\
				<offset SplineExcl, SplineName, 0>,
				<offset PolycurveExcl, PolycurveName, 0>,
				<offset PolylineExcl, PolylineName, 0>,
				<offset ArcExcl, ArcName, 0>,
				<offset EllipseExcl, EllipseName, 0>,
				<offset RoundedRectExcl, RoundedRectName, 0>,
				<offset RectExcl, RectName, 0>,
				<offset LineExcl, LineName, 0>,
				<offset TextExcl, TextName, 0>,
				<offset ZoomExcl, ZoomName, 0>,
				<offset RotatePtrExcl, RotatePtrName, 0>,
				<offset PtrExcl, PtrName, 0>

if FULL_EXECUTE_IN_PLACE
GrObjControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjToolItemGroupSelectSelfIfMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjToolItem method for MSG_GOTI_SELECT_SELF_IF_MATCH

Called by:	

Pass:		*ds:si = GrObjToolItem object
		ds:di = GrObjToolItem instance

		cx:dx = current tool class
		bp = specific initialize data

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 31, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjToolItemSelectSelfIfMatch	method	GrObjToolItemClass, MSG_GOTI_SELECT_SELF_IF_MATCH

	cmp	dx, ds:[di].GOTII_toolClass.offset
	je	checkSegment

done:
	ret

checkSegment:
	cmp	cx, ds:[di].GOTII_toolClass.segment
	jne	done
	cmp	bp, ds:[di].GOTII_specInitData
	jne	done

	push	ax, cx, dx, bp				;save regs
	;
	;	The instance data matches the passed data; tell our
	;	parent to select us
	;
	mov	ax, MSG_GEN_ITEM_GET_IDENTIFIER
	call	ObjCallInstanceNoLock

	mov_tr	cx, ax					;cx <- identifier
	clr	dx					;not indeterminate
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	GenCallParent

	pop	ax, cx, dx, bp				;restore regs

	jmp	done
GrObjToolItemSelectSelfIfMatch	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	GrObjToolControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for GrObjToolControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of GrObjToolControlClass
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
	jon	11 feb 1992	Initial version
------------------------------------------------------------------------------@
GrObjToolControlUpdateUI	method GrObjToolControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	uses	ax, cx, dx, bp
	.enter

	test	ss:[bp].GCUUIP_toolboxFeatures, mask GOTCFeatures
	LONG	jz	done

	;
	;	Suck out the info we need
	;

	push	ds:[LMBH_handle]			;save object handle
	
	;
	;	Get GrObjToolItemGroup's OD for later
	;	
	push	ss:[bp].GCUUIP_toolBlock

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	movdw	cxdx, ds:[GONCT_toolClass]
	mov	bp, ds:[GONCT_specInitData]
	call	MemUnlock

	;
	;	Create a classed event to send to the tool list entries.
	;
	;	di <- event handle
	;
	mov	bx, segment GrObjToolItemClass
	mov	si, offset GrObjToolItemClass
	mov	ax, MSG_GOTI_SELECT_SELF_IF_MATCH
	mov	di, mask MF_RECORD
	call	ObjMessage

	;
	;	Set the list indeterminate to begin with
	;
	pop	bx					;^lbx:si <- list
	mov	si, offset GrObjToolItemGroup

	cmpdw	cxdx, -1				;save tool class
	pushf						;Z if null class
	push	di					;save event handle
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, 1					;set modified
	clr	di
	call	ObjMessage

	;
	;	Send the message to the tool list
	;	(event handle freed by the list)
	;
	pop	cx					;cx <- event handle
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_IS_MODIFIED
	mov	di, mask MF_CALL
	call	ObjMessage
	jnc	afterSelect

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	dx, 1					;non-determinate
	clr	di
	call	ObjMessage

afterSelect:
	popf						;Z if null class
	pop	di					;di <- obj handle
	je	done

	;
	;	Send a null bitmap message just for kicks
	;
	mov	bx, size VisBitmapNotifyCurrentTool
	call	GrObjGlobalAllocNotifyBlock

	call	MemLock
	mov	ds, ax
	movdw	ds:[VBNCT_toolClass], -1
	call	MemUnlock

	mov_tr	ax, bx					;ax <- notif block
	mov	bx, di					;bx <- obj handle
	call	MemDerefDS
	mov_tr	bx, ax					;ax <- notif block

	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE
	mov	dx, GWNT_BITMAP_CURRENT_TOOL_CHANGE
	call	GrObjGlobalUpdateControllerLow

done:
	.leave
	ret
GrObjToolControlUpdateUI	endm

GrObjUIControllerCode	ends

GrObjUIControllerActionCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjToolControlSetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjToolControl method for MSG_GOTC_SET_TOOL

Called by:	

Pass:		*ds:si = GrObjToolControl object
		ds:di = GrObjToolControl instance

		cx = identifier

Return:		nothing

Destroyed:	bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjToolControlSetTool	method	GrObjToolControlClass, MSG_GOTC_SET_TOOL
	uses	ax, cx, dx, bp
	.enter

	call	GetToolBlockAndFeatures
	test	ax, mask GOTCFeatures
	jz	done
	push	si
	mov	si, offset GrObjToolItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_GOTI_GET_TOOL_CLASS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	si

	mov	ax, MSG_GH_SET_CURRENT_TOOL
	mov	bx, segment GrObjHeadClass
	mov	di, offset GrObjHeadClass
	call	GenControlOutputActionRegs

done:
	.leave
	ret
GrObjToolControlSetTool	endm

;----


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjToolItemGetToolClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjToolItemGroupEntry method for MSG_GOTI_GET_TOOL_CLASS

Called by:	

Pass:		*ds:si = GrObjToolItemGroupEntry object
		ds:di = GrObjToolItemGroupEntry instance


Return:		cxdx = tool class
		bp = specific initialize data

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjToolItemGetToolClass	method	GrObjToolItemClass, MSG_GOTI_GET_TOOL_CLASS
	.enter

	movdw	cxdx, ds:[di].GOTII_toolClass
	mov	bp, ds:[di].GOTII_specInitData

	.leave
	ret
GrObjToolItemGetToolClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjToolControlAddAppToolboxUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjToolControl method adding children

Called by:	GenControl

Pass:		*ds:si = GrObjToolControl object
		ds:di = GrObjToolControl instance

		^lcx:dx = GrObjToolItem

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjToolControlAddAppToolboxUI	method	GrObjToolControlClass,
					MSG_GEN_CONTROL_ADD_APP_TOOLBOX_UI
	uses	ax, bp
	.enter

	mov	bp, CCO_LAST			;default is at end
	mov	ax, ATTR_GROBJ_TOOL_CONTROL_POSITION_FOR_ADDED_TOOLS
	call	ObjVarFindData
	jnc	10$
	mov	bp, ds:[bx]
10$:

	call	GetToolBlockAndFeatures
	test	ax, mask GOTCFeatures
	jz	done
	mov	si, offset GrObjToolItemGroup

	mov	ax, MSG_GEN_ADD_CHILD
	clr	di
	call	ObjMessage
done:
	.leave
	ret
GrObjToolControlAddAppToolboxUI	endm

GrObjUIControllerActionCode	ends
