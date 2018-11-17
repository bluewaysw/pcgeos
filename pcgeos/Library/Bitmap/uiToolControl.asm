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
	Code for the VisBitmapToolControlClass

	$Id: uiToolControl.asm,v 1.1 97/04/04 17:43:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VisBitmapUIControllerCode	segment	resource

BitmapClassStructures	segment resource
	VisBitmapToolControlClass
	VisBitmapToolItemClass
BitmapClassStructures	ends



COMMENT @----------------------------------------------------------------------

MESSAGE:	VisBitmapToolControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for VisBitmapToolControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of VisBitmapToolControlClass

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
VisBitmapToolControlGetInfo	method dynamic	VisBitmapToolControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset VBTC_dupInfo
	call	CopyDupInfoCommon
	ret
VisBitmapToolControlGetInfo	endm

CopyDupInfoCommon	proc	far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
CopyDupInfoCommon	endp

VBTC_dupInfo	GenControlBuildInfo	<
	0,				; GCBI_flags
	VBTC_IniFileKey,		; GCBI_initFileKey
	VBTC_gcnList,			; GCBI_gcnList
	length VBTC_gcnList,		; GCBI_gcnCount
	VBTC_notifyList,		; GCBI_notificationList
	length VBTC_notifyList,		; GCBI_notificationCount
	VBTCName,			; GCBI_controllerName

	0,				; GCBI_dupBlock
	0,				; GCBI_childList
	0,				; GCBI_childCount
	0,				; GCBI_featuresList
	0,				; GCBI_featuresCount

	0,				; GCBI_features

	handle VisBitmapToolControlToolboxUI,	; GCBI_toolBlock
	VBTC_toolList,			; GCBI_toolList
	length VBTC_toolList,		; GCBI_toolCount
	VBTC_toolFeaturesList,		; GCBI_toolFeaturesList
	length VBTC_toolFeaturesList,	; GCBI_toolFeaturesCount

	VBTC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	VBTC_helpContext>		; GCBI_helpContext

if _FXIP
BitmapControlInfoXIP	segment resource
endif

VBTC_helpContext	char	"dbBitmapTool", 0
VBTC_IniFileKey	char	"VisBitmapTool", 0

VBTC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS,
		GAGCNLT_APP_TARGET_NOTIFY_BITMAP_CURRENT_TOOL_CHANGE>

VBTC_notifyList		NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_BITMAP_CURRENT_TOOL_CHANGE>

;---

VBTC_toolList	GenControlChildInfo \
	<offset VisBitmapToolItemGroup, mask VBTCFeatures, 0>

VBTC_toolFeaturesList	GenControlFeaturesInfo	\
				<offset FatbitsExcl, FatbitsName, 0>,
				<offset FloodFillExcl, FloodFillName, 0>,
				<offset DrawEllipseExcl, DrawEllipseName, 0>,
				<offset EllipseExcl, EllipseName, 0>,
				<offset DrawRectExcl, DrawRectName, 0>,
				<offset RectExcl, RectName, 0>,
				<offset LineExcl, LineName, 0>,
				<offset EraserExcl, EraserName, 0>,
				<offset PencilExcl, PencilName, 0>,
				<offset SelectionExcl, SelectionName, 0>

if _FXIP
BitmapControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapToolControlSetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmapToolControl method for MSG_VBTC_SET_TOOL

Called by:	

Pass:		*ds:si = VisBitmapToolControl object
		ds:di = VisBitmapToolControl instance

		cx = identifier

Return:		nothing

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapToolControlSetTool	method	VisBitmapToolControlClass,
				MSG_VBTC_SET_TOOL
	uses	cx, dx, bp
	.enter

	mov	ax, MSG_VBTC_GET_TOOL_CLASS
	call	ObjCallInstanceNoLock
	jnc	done

	mov	ax, MSG_VIS_BITMAP_CREATE_TOOL
	mov	bx, segment VisBitmapClass
	mov	di, offset VisBitmapClass
	call	GenControlOutputActionRegs

done:
	.leave
	ret
VisBitmapToolControlSetTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapToolControlGetToolClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmapToolControl method for MSG_VBTC_GET_TOOL_CLASS

Called by:	

Pass:		*ds:si = VisBitmapToolControl object
		ds:di = VisBitmapToolControl instance

		cx = identifier

Return:		if carry set
			cx:dx - class ptr represented by identifier
		carry clear on error

Destroyed:	ax, bx, di

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Feb 27, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapToolControlGetToolClass	method	VisBitmapToolControlClass,
					MSG_VBTC_GET_TOOL_CLASS
	uses	bp
	.enter

	call	GetToolBlockAndFeatures
	test	ax, mask VBTCFeatures
	jz	done
	mov	si, offset VisBitmapToolItemGroup
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage

	mov	bx, cx
	mov	si, dx
	mov	ax, MSG_VBTI_GET_TOOL_CLASS
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	stc
done:
	.leave
	ret
VisBitmapToolControlGetToolClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapToolControlAddAppToolboxUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmapToolControl method adding children

Called by:	GenControl

Pass:		*ds:si = VisBitmapToolControl object
		ds:di = VisBitmapToolControl instance

		^lcx:dx = VisBitmapToolItem

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapToolControlAddAppToolboxUI	method	VisBitmapToolControlClass,
					MSG_GEN_CONTROL_ADD_APP_TOOLBOX_UI
	uses	ax, bp
	.enter

	mov	bp, CCO_LAST			;default is at end
	mov	ax, ATTR_VIS_BITMAP_TOOL_CONTROL_POSITION_FOR_ADDED_TOOLS
	call	ObjVarFindData
	jnc	10$
	mov	bp, ds:[bx]
10$:

	call	GetToolBlockAndFeatures
	test	ax, mask VBTCFeatures
	jz	done
	mov	si, offset VisBitmapToolItemGroup

	mov	ax, MSG_GEN_ADD_CHILD
	clr	di
	call	ObjMessage
done:
	.leave
	ret
VisBitmapToolControlAddAppToolboxUI	endm

;----

GetToolBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_toolboxFeatures
	mov	bx, ds:[bx].TGCI_toolBlock
	ret
GetToolBlockAndFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			VisBitmapToolItemGetToolClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmapToolItemGroupEntry method for MSG_VBTI_GET_TOOL_CLASS

Called by:	

Pass:		*ds:si = VisBitmapToolItem object
		ds:di = VisBitmapToolItem instance


Return:		cxdx = tool class

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 23, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisBitmapToolItemGetToolClass	method	VisBitmapToolItemClass, MSG_VBTI_GET_TOOL_CLASS
	.enter

	movdw	cxdx, ds:[di].VBTII_toolClass

	.leave
	ret
VisBitmapToolItemGetToolClass	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisBitmapToolItemGroupSelectSelfIfMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	VisBitmapToolItem method for MSG_VBTI_SELECT_SELF_IF_MATCH

Called by:	

Pass:		*ds:si = VisBitmapToolItem object
		ds:di = VisBitmapToolItem instance

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
VisBitmapToolItemSelectSelfIfMatch	method	VisBitmapToolItemClass, MSG_VBTI_SELECT_SELF_IF_MATCH

	cmp	dx, ds:[di].VBTII_toolClass.offset
	je	checkSegment

done:
	ret

checkSegment:
	cmp	cx, ds:[di].VBTII_toolClass.segment
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
VisBitmapToolItemSelectSelfIfMatch	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisBitmapToolControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for VisBitmapToolControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of VisBitmapToolControlClass
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
VisBitmapToolControlUpdateUI	method VisBitmapToolControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	uses	ax, cx, dx, bp
	.enter

	;
	;	Suck out the info we need
	;
	cmp	ss:[bp].GCUUIP_changeType, GWNT_BITMAP_CURRENT_TOOL_CHANGE
	jne	done
	
	;
	;	Get VisBitmapToolItemGroup's OD for later
	;	
	call	GetToolBlockAndFeatures
	mov	si, offset VisBitmapToolItemGroup
	push	bx, si

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	movdw	cxdx, ds:[VBNCT_toolClass]
	call	MemUnlock

	;
	;	Create a classed event to send to the tool list entries.
	;
	;	di <- event handle
	;
	mov	bx, segment VisBitmapToolItemClass
	mov	si, offset VisBitmapToolItemClass
	mov	ax, MSG_VBTI_SELECT_SELF_IF_MATCH
	mov	di, mask MF_RECORD
	call	ObjMessage

	;
	;	Set the list indeterminate to begin with
	;
	pop	bx, si					;^lbx:si <- list
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
	jnc	done

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	dx, 1					;non-determinate
	clr	di
	call	ObjMessage

done:
	.leave
	ret
VisBitmapToolControlUpdateUI	endm

VisBitmapUIControllerCode	ends
