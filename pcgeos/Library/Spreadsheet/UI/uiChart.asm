COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiChart.asm

AUTHOR:		Gene Anderson, Sep 13, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/13/92		Initial revision


DESCRIPTION:
	Code for SSChartControlClass

	$Id: uiChart.asm,v 1.1 97/04/07 11:12:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

SpreadsheetClassStructures	segment	resource	
	SSChartControlClass		;declare the class record
SpreadsheetClassStructures	ends

;---------------------------------------------------

ChartControlCode segment resource
if _CHARTS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCCGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the SSChartControl
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChartControlClass
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SSCCGetInfo	method dynamic SSChartControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset SSCC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
SSCCGetInfo	endm

SSCC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	SSCC_IniFileKey,		; GCBI_initFileKey
	SSCC_gcnList,			; GCBI_gcnList
	length SSCC_gcnList,		; GCBI_gcnCount
	SSCC_notifyTypeList,		; GCBI_notificationList
	length SSCC_notifyTypeList,	; GCBI_notificationCount
	SSCCName,			; GCBI_controllerName

	handle SSChartUI,		; GCBI_dupBlock
	SSCC_childList,			; GCBI_childList
	length SSCC_childList,		; GCBI_childCount
	SSCC_featuresList,		; GCBI_featuresList
	length SSCC_featuresList,	; GCBI_featuresCount
	SSCC_DEFAULT_FEATURES,		; GCBI_features

	handle SSChartToolUI,		; GCBI_toolBlock
	SSCC_toolList,			; GCBI_toolList
	length SSCC_toolList,		; GCBI_toolCount
	SSCC_toolFeaturesList,		; GCBI_toolFeaturesList
	length SSCC_toolFeaturesList,	; GCBI_toolFeaturesCount
	SSCC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

SSCC_IniFileKey	char	"ssChart", 0

SSCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_SPREADSHEET_SELECTION_CHANGE>

SSCC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_SPREADSHEET_SELECTION_CHANGE>

;---

ifdef	SPIDER_CHART
SSCC_childList	GenControlChildInfo	\
	<offset ColumnTrigger, mask SSCCF_COLUMN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset BarTrigger, mask SSCCF_BAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LineTrigger, mask SSCCF_LINE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset AreaTrigger, mask SSCCF_AREA, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ScatterTrigger, mask SSCCF_SCATTER, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PieTrigger, mask SSCCF_PIE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HighLowTrigger, mask SSCCF_HIGH_LOW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpiderTrigger, mask SSCCF_SPIDER, mask GCCF_IS_DIRECTLY_A_FEATURE>
else
SSCC_childList	GenControlChildInfo	\
	<offset ColumnTrigger, mask SSCCF_COLUMN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset BarTrigger, mask SSCCF_BAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LineTrigger, mask SSCCF_LINE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset AreaTrigger, mask SSCCF_AREA, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ScatterTrigger, mask SSCCF_SCATTER, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PieTrigger, mask SSCCF_PIE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HighLowTrigger, mask SSCCF_HIGH_LOW, mask GCCF_IS_DIRECTLY_A_FEATURE>
endif


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

ifdef	SPIDER_CHART
SSCC_featuresList	GenControlFeaturesInfo	\
	<offset ColumnTrigger, SSCCColumnName, 0>,
	<offset BarTrigger, SSCCBarName, 0>,
	<offset LineTrigger, SSCCLineName, 0>,
	<offset AreaTrigger, SSCCAreaName, 0>,
	<offset ScatterTrigger, SSCCScatterName, 0>,
	<offset PieTrigger, SSCCPieName, 0>,
	<offset HighLowTrigger, SSCCHighLowName, 0>,
	<offset SpiderTrigger, SSCCSpiderName, 0>
else
SSCC_featuresList	GenControlFeaturesInfo	\
	<offset ColumnTrigger, SSCCColumnName, 0>,
	<offset BarTrigger, SSCCBarName, 0>,
	<offset LineTrigger, SSCCLineName, 0>,
	<offset AreaTrigger, SSCCAreaName, 0>,
	<offset ScatterTrigger, SSCCScatterName, 0>,
	<offset PieTrigger, SSCCPieName, 0>,
	<offset HighLowTrigger, SSCCHighLowName, 0>
endif

;---

ifdef	SPIDER_CHART
SSCC_toolList	GenControlChildInfo	\
	<offset ColumnTool, mask SSCCTF_COLUMN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset BarTool, mask SSCCTF_BAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LineTool, mask SSCCTF_LINE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset AreaTool, mask SSCCTF_AREA, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ScatterTool, mask SSCCTF_SCATTER, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PieTool, mask SSCCTF_PIE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HighLowTool, mask SSCCTF_HIGH_LOW, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SpiderTool, mask SSCCTF_SPIDER, mask GCCF_IS_DIRECTLY_A_FEATURE>
else
SSCC_toolList	GenControlChildInfo	\
	<offset ColumnTool, mask SSCCTF_COLUMN, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset BarTool, mask SSCCTF_BAR, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LineTool, mask SSCCTF_LINE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset AreaTool, mask SSCCTF_AREA, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ScatterTool, mask SSCCTF_SCATTER, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset PieTool, mask SSCCTF_PIE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HighLowTool, mask SSCCTF_HIGH_LOW, mask GCCF_IS_DIRECTLY_A_FEATURE>
endif


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

ifdef 	SPIDER_CHART
SSCC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset ColumnTool, SSCCColumnName, 0>,
	<offset BarTool, SSCCBarName, 0>,
	<offset LineTool, SSCCLineName, 0>,
	<offset AreaTool, SSCCAreaName, 0>,
	<offset ScatterTool, SSCCScatterName, 0>,
	<offset PieTool, SSCCPieName, 0>,
	<offset HighLowTool, SSCCHighLowName, 0>,
	<offset SpiderTool, SSCCSpiderName, 0>
else
SSCC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset ColumnTool, SSCCColumnName, 0>,
	<offset BarTool, SSCCBarName, 0>,
	<offset LineTool, SSCCLineName, 0>,
	<offset AreaTool, SSCCAreaName, 0>,
	<offset ScatterTool, SSCCScatterName, 0>,
	<offset PieTool, SSCCPieName, 0>,
	<offset HighLowTool, SSCCHighLowName, 0>

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for SSChartController

CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChartControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	9/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSCCUpdateUI		method dynamic SSChartControlClass,
						MSG_GEN_CONTROL_UPDATE_UI
	;
	; Get the notification block
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock
	push	ds
	call	MemLock
	mov	ds, ax
	mov	dx, ds:NSSSC_flags		;dx <- SSheetSelectionFlags
	call	MemUnlock
	pop	ds
	;
	; Enable or disable the menu UI
	;
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	mov	cx, length SSCC_childList	;cx <- # of entries
	mov	di, offset SSCC_childList
	call	childLoop
	;
	; Enable or disable the tool UI
	;
	mov	ax, ss:[bp].GCUUIP_toolboxFeatures
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	cx, length SSCC_toolList
	mov	di, offset SSCC_toolList
	call	childLoop
	ret

childLoop:
	test	ax, 0x0001			;does feature exist?
	jz	noFeature			;branch if feature doesn't exist
	push	ax, di, cx, dx
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	dx, mask SSSF_SINGLE_CELL
	jnz	doEnableDisable
	mov	ax, MSG_GEN_SET_ENABLED
doEnableDisable:
	mov	si, cs:[di].GCCI_object		;^lbx:si <- OD of object
	mov	di, mask MF_FIXUP_DS
	mov	dl, VUM_NOW
	call	ObjMessage
	pop	ax, di, cx, dx
noFeature:
	shr	ax, 1				;ax <- next bit to test
	add	di, (size GenControlChildInfo)
	loop	childLoop
	retn
SSCCUpdateUI		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SSCCChart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send chart message to the spreadsheet

CALLED BY:	MSG_SSCC_CHART
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SSChartControlClass
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
	gene	9/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SSCCChart		method dynamic SSChartControlClass,
						MSG_SSCC_CHART
	mov	ax, MSG_SPREADSHEET_CHART_RANGE
	call	SSCSendToSpreadsheet
	ret
SSCCChart		endm

endif

ChartControlCode	ends
