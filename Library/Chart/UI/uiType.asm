COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiType.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/16/91	Initial version.

DESCRIPTION:
	implementation of ChartTypeControlClass	

	$Id: uiType.asm,v 1.1 97/04/04 17:47:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartTypeControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ChartTypeControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ChartTypeControlClass

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
ChartTypeControlGetInfo	method dynamic	ChartTypeControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset CTC_dupInfo
	call	CopyDupInfoCommon
	ret
ChartTypeControlGetInfo	endm

CTC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	CTC_IniFileKey,			; GCBI_initFileKey
	CTC_gcnList,			; GCBI_gcnList
	length CTC_gcnList,		; GCBI_gcnCount
	CTC_notifyTypeList,		; GCBI_notificationList
	length CTC_notifyTypeList,	; GCBI_notificationCount
	CTCName,			; GCBI_controllerName

	handle TypeControlUI,		; GCBI_dupBlock
	CTC_childList,			; GCBI_childList
	length CTC_childList,		; GCBI_childCount
	CTC_featuresList,		; GCBI_featuresList
	length CTC_featuresList,	; GCBI_featuresCount
	CTC_DEFAULT_FEATURES,		; GCBI_features

	handle TypeControlToolboxUI,	; GCBI_toolBlock
	CTC_toolList,			; GCBI_toolList
	length CTC_toolList,		; GCBI_toolCount
	CTC_toolFeaturesList,		; GCBI_toolFeaturesList
	length CTC_toolFeaturesList,	; GCBI_toolFeaturesCount
	CTC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	CTC_helpContext>		; GCBI_helpContext

CTC_helpContext	char	"dbChrtType", 0

ifdef	SPIDER_CHART
CTC_DEFAULT_FEATURES equ mask CTCF_COLUMN or mask CTCF_BAR or \
			 mask CTCF_LINE or mask CTCF_AREA or \
			 mask CTCF_PIE or mask CTCF_SCATTER or \
			 mask CTCF_HIGH_LOW or mask CTCF_SPIDER
else	; SPIDER_CHART
CTC_DEFAULT_FEATURES equ mask CTCF_COLUMN or mask CTCF_BAR or \
			 mask CTCF_LINE or mask CTCF_AREA or \
			 mask CTCF_PIE or mask CTCF_SCATTER or \
			 mask CTCF_HIGH_LOW
endif	; SPIDER_CHART

CTC_IniFileKey	char	"chartType", 0

CTC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_CHART_TYPE_CHANGE>

CTC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CHART_TYPE_CHANGE>

;---

ifdef 	SPIDER_CHART
CTC_childList	GenControlChildInfo	\
	<offset ChartTypeInteraction, mask CTCF_COLUMN or mask CTCF_BAR or 
				mask CTCF_LINE or mask CTCF_AREA or
				mask CTCF_SCATTER or mask CTCF_PIE or
				mask CTCF_HIGH_LOW or mask CTCF_SPIDER, 0>
else	; SPIDER_CHART
CTC_childList	GenControlChildInfo	\
	<offset ChartTypeInteraction, mask CTCF_COLUMN or mask CTCF_BAR or 
				mask CTCF_LINE or mask CTCF_AREA or
				mask CTCF_SCATTER or mask CTCF_PIE or
				mask CTCF_HIGH_LOW, 0>
endif	; SPIDER_CHART

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

ifdef	SPIDER_CHART
CTC_featuresList	GenControlFeaturesInfo	\
	<offset SpiderItemGroup,	SpiderName, 0>,
	<offset	HighLowItemGroup, 	HighLowName, 0>,
	<offset	PieItemGroup, 		PieName, 0>,
	<offset	ScatterItemGroup, 	ScatterName, 0>,
	<offset	AreaItemGroup, 		AreaName, 0>,
	<offset	LineItemGroup, 		LineName, 0>,
	<offset	BarItemGroup, 		BarName, 0>,
	<offset	ColumnItemGroup, 	ColumnName, 0>
else	; SPIDER_CHART
CTC_featuresList	GenControlFeaturesInfo	\
	<offset	HighLowItemGroup, 	HighLowName, 0>,
	<offset	PieItemGroup, 		PieName, 0>,
	<offset	ScatterItemGroup, 	ScatterName, 0>,
	<offset	AreaItemGroup, 		AreaName, 0>,
	<offset	LineItemGroup, 		LineName, 0>,
	<offset	BarItemGroup, 		BarName, 0>,
	<offset	ColumnItemGroup, 	ColumnName, 0>
endif	; SPIDER_CHART

ifdef	SPIDER_CHART
CTC_toolList	GenControlChildInfo	\
	<offset ChartTypeTool, mask CTCTF_COLUMN or mask CTCTF_BAR or 
				mask CTCTF_LINE or mask CTCTF_AREA or
				mask CTCTF_SCATTER or mask CTCTF_PIE or
				mask CTCF_HIGH_LOW or mask CTCF_SPIDER, 0>
else	; SPIDER_CHART
CTC_toolList	GenControlChildInfo	\
	<offset ChartTypeTool, mask CTCTF_COLUMN or mask CTCTF_BAR or 
				mask CTCTF_LINE or mask CTCTF_AREA or
				mask CTCTF_SCATTER or mask CTCTF_PIE or
				mask CTCF_HIGH_LOW, 0>
endif	; SPIDER_CHART

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

ifdef	SPIDER_CHART
CTC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset SpiderTool,	SpiderName, 0>,
	<offset HighLowTool,	HighLowName, 0>,
	<offset	PieTool, 	PieName, 0>,
	<offset	ScatterTool, 	ScatterName, 0>,
	<offset	AreaTool, 	AreaName, 0>,
	<offset	LineTool, 	LineName, 0>,
	<offset	BarTool, 	BarName, 0>,
	<offset	ColumnTool, 	ColumnName, 0>
else	; SPIDER_CHART
CTC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset HighLowTool,	HighLowName, 0>,
	<offset	PieTool, 	PieName, 0>,
	<offset	ScatterTool, 	ScatterName, 0>,
	<offset	AreaTool, 	AreaName, 0>,
	<offset	LineTool, 	LineName, 0>,
	<offset	BarTool, 	BarName, 0>,
	<offset	ColumnTool, 	ColumnName, 0>
endif	; SPIDER_CHART


COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartTypeControlTypeChange -- MSG_CTC_TYPE_CHANGE
						for ChartTypeControlClass

DESCRIPTION:	Update the UI stuff based on the setting of the 
		ChartType.

PASS:
	*ds:si - instance data
	es - segment of ChartTypeControlClass

	ax - The message
	cl - ChartType

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Only update on a USER change

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91	Initial version
------------------------------------------------------------------------------@
ChartTypeControlTypeChange	method dynamic	ChartTypeControlClass,
						MSG_CTC_TYPE_CHANGE

	clr	ch		; set variation as  "Standard"
	call	UpdateUICommon
	ret
ChartTypeControlTypeChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartTypeControlVariationChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartTypeControlClass object
		ds:di	= ChartTypeControlClass instance data
		es	= Segment of ChartTypeControlClass.
		
		cl 	= chart type
		ch 	= chart variation

		bp low - ListEntryState
		bp high - ListUpdateFlags

RETURN:		

DESTROYED:	everything

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/27/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartTypeControlVariationChange	method	dynamic	ChartTypeControlClass, 
					MSG_CTC_VARIATION_CHANGE
	FALL_THRU	ChartTypeChangeCommon
ChartTypeControlVariationChange	endm

ChartTypeChangeCommon	proc	far
	;
	; cl - ChartType
	; ch - ChartVariation
	;
	mov	ax, MSG_CHART_GROUP_SET_CHART_TYPE
	mov	bx, segment ChartGroupClass
	mov	di, offset ChartGroupClass
	call	GenControlOutputActionRegs

	;
	; Don't set any BuildChangeFlags, because the chart group will
	; have calculated them for itself.
	;

	clr	bp
	mov	ax, MSG_CHART_OBJECT_BUILD
	call	GenControlOutputActionRegs
	
	ret
ChartTypeChangeCommon	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartTypeControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ChartTypeControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of ChartTypeControlClass

	ax - The message
	dx - NotificationStandardNotificationType
	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91	Initial version

------------------------------------------------------------------------------@
ChartTypeControlUpdateUI	method ChartTypeControlClass,
				MSG_GEN_CONTROL_UPDATE_UI


	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	mov	cl, ds:[TNB_type]
	mov	ch, ds:[TNB_variation]
	call	MemUnlock
	pop	ds

	call	UpdateUICommon
	;
	; Update the tool UI, if any
	;
	test	ss:[bp].GCUUIP_toolboxFeatures, \
					mask ChartTypeControlToolboxFeatures
	jz	noTools
	mov	bx, ss:[bp].GCUUIP_toolBlock
;;;
;;; HACK ALERT!!!
;;; 	The high byte of the type tool identifier stores the default
;;;	chart variation type. If ch != the high byte of the identifier,
;;;	the tool won't be selected, so force ch to be the same as
;;;	the value set in the ChartTypeTools identifiers in uiType.ui.	
;;;
	clr	ch
	cmp	cl, CT_PIE
	jne	noPie
	mov	ch, CPV_CATEGORY_TITLES
noPie:
	push	si
	mov	si, offset ChartTypeTool	;^lbx:si <- OD of list
	call	SetItemGroupSelection
	pop	si
noTools:

	.leave
	ret
ChartTypeControlUpdateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateUICommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the various UI pieces based on the current
		chart selection.

CALLED BY:	

PASS:		cl - ChartType
		ch - ChartVariation
		*ds:si - GenControl object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	12/26/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateUICommon	proc near	
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	call	GetChildBlock		; bx <= child block

	; Set all the variation lists not usable, except the one
	; corresponding to the current chart type

	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	clr	di
startLoop:
	mov	si, cs:ChartVariationsTable[di]
	push	cx
	clr	ch
	cmp	di, cx			; chartType
	pop	cx
	jne	notUsable

	; Set the current variation list usable,, and set its value

	call	SetObjUsable
	call	SetItemGroupSelection
	jmp	endLoop

notUsable:
	; Set the variation not usable, and set it indeterminate
	call	SetObjNotUsable
endLoop:
	add	di, 2
	cmp	di, size ChartVariationsTable
	jl	startLoop

	; set the main chart list. CL may contain a valid chart type,
	; or -1.

	mov	si, offset ChartTypeItemGroup
	mov	al, cl
	cbw
	mov	cx, ax
	call	SetItemGroupSelection

	.leave
	ret
UpdateUICommon	endp

ifdef	SPIDER_CHART
ChartVariationsTable	word \
	offset	ColumnItemGroup,
	offset	BarItemGroup,
	offset	LineItemGroup,
	offset	AreaItemGroup,
	offset	ScatterItemGroup,
	offset	PieItemGroup,
	offset	HighLowItemGroup,
	offset	SpiderItemGroup
else	; SPIDER_CHART
ChartVariationsTable	word \
	offset	ColumnItemGroup,
	offset	BarItemGroup,
	offset	LineItemGroup,
	offset	AreaItemGroup,
	offset	ScatterItemGroup,
	offset	PieItemGroup,
	offset	HighLowItemGroup
endif	; SPIDER_CHART


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartTypeControlToolChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle changing the ChartType from the tool list
CALLED BY:	MSG_CTC_TYPE_TOOL_CHANGE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ChartTypeControlClass
		ax - the message

		cl - ChartType
		ch - ChartVariation

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartTypeControlToolChange	method dynamic ChartTypeControlClass, \
						MSG_CTC_TYPE_TOOL_CHANGE
	GOTO	ChartTypeChangeCommon
ChartTypeControlToolChange	endm
