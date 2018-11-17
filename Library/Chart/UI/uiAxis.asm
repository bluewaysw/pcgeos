COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Chart Library
FILE:		uiAxis.asm

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
	CDB	1/15/92   	Initial version.

DESCRIPTION:
	

	$Id: uiAxis.asm,v 1.1 97/04/04 17:47:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartAxisControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ChartAxisControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ChartAxisControlClass

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
ChartAxisControlGetInfo	method dynamic	ChartAxisControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset CAC_dupInfo
	call	CopyDupInfoCommon
	ret
ChartAxisControlGetInfo	endm

CAC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	CAC_IniFileKey,			; GCBI_initFileKey
	CAC_gcnList,			; GCBI_gcnList
	length CAC_gcnList,		; GCBI_gcnCount
	CAC_notifyTypeList,		; GCBI_notificationList
	length CAC_notifyTypeList,	; GCBI_notificationCount
	CACName,			; GCBI_controllerName

	handle AxisControlUI,		; GCBI_dupBlock
	CAC_childList,			; GCBI_childList
	length CAC_childList,		; GCBI_childCount
	CAC_featuresList,		; GCBI_featuresList
	length CAC_featuresList,	; GCBI_featuresCount
	CAC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	CAC_helpContext>		; GCBI_helpContext

CAC_helpContext	char	"dbChrtAxis", 0

CAC_DEFAULT_FEATURES equ mask CACF_MIN or mask CACF_MAX or \
		mask CACF_MAJOR_TICK or mask CACF_MINOR_TICK or \
		mask CACF_TICK_ATTRIBUTES


CAC_IniFileKey	char	"axis", 0

CAC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_CHART_AXIS_ATTRIBUTES>

CAC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CHART_AXIS_ATTRIBUTES>

;---

CAC_childList	GenControlChildInfo	\
	<offset AxisInteraction, CAC_DEFAULT_FEATURES, 0>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

if 0 
; Nuke this until we get the FPValue object

CAC_featuresList	GenControlFeaturesInfo	\
	<offset	MinFPValue, 	MinName, 0>,
	<offset	MaxFPValue, 	MaxName, 0>,
	<offset	MajorUnitFPValue, MajorTickName, 0>,
	<offset	MinorUnitFPValue, MinorTickName, 0>,
	<offset	TickAttrBooleanGroup,  TickAttrName, 0>

else

CAC_featuresList	GenControlFeaturesInfo	\
	<offset	XAxisTickAttrGroup,  TickAttrName, 0>,
	<offset	YAxisTickAttrGroup,  TickAttrName, 0>

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartAxisControlSetMin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Send it on down!

PASS:		*ds:si	= ChartAxisControlClass object
		ds:di	= ChartAxisControlClass instance data
		es	= Segment of ChartAxisControlClass.
		cx	= value from GenValue

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartAxisControlSetMin	method	dynamic	ChartAxisControlClass, 
					MSG_CAC_SET_MIN
	mov	ax, MSG_VALUE_AXIS_SET_MIN
	GOTO	SendToValueAxisClass
ChartAxisControlSetMin	endm

ChartAxisControlSetMax	method	dynamic	ChartAxisControlClass, 
					MSG_CAC_SET_MAX
	mov	ax, MSG_VALUE_AXIS_SET_MAX
	GOTO	SendToValueAxisClass
ChartAxisControlSetMax	endm

ChartAxisControlSetMajorTickUnit	method	dynamic	ChartAxisControlClass, 
					MSG_CAC_SET_MAJOR_TICK_UNIT
	mov	ax, MSG_VALUE_AXIS_SET_MAJOR_TICK_UNIT
	GOTO	SendToValueAxisClass
ChartAxisControlSetMajorTickUnit	endm

ChartAxisControlSetMinorTickUnit	method	dynamic	ChartAxisControlClass, 
					MSG_CAC_SET_MINOR_TICK_UNIT
	mov	ax, MSG_VALUE_AXIS_SET_MINOR_TICK_UNIT
	GOTO	SendToValueAxisClass
ChartAxisControlSetMinorTickUnit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CACSetXAxisTickAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartAxisControlClass object
		ds:di	- ChartAxisControlClass instance data
		es	- segment of ChartAxisControlClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CACSetXAxisTickAttributes	method	dynamic	ChartAxisControlClass, 
					MSG_CAC_SET_X_AXIS_TICK_ATTRIBUTES
	clr	dx
	GOTO	SetTickAttrsCommon
CACSetXAxisTickAttributes	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CACSetYAxisTickAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- ChartAxisControlClass object
		ds:di	- ChartAxisControlClass instance data
		es	- segment of ChartAxisControlClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CACSetYAxisTickAttributes	method	dynamic	ChartAxisControlClass, 
				MSG_CAC_SET_Y_AXIS_TICK_ATTRIBUTES
	mov	dx, -1
	GOTO	SetTickAttrsCommon
CACSetYAxisTickAttributes	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTickAttrsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine which tick attrs to SET and which to CLEAR,
		and send it to the axis

CALLED BY:	CACSetXAxisTickAttributes, CACSetYAxisTickAttributes

PASS:		cl - bits that are ON
		bp - bits that have changed
		dx - nonzero to send to VERTICAL axis, zero to send to
			horizontal axis

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTickAttrsCommon	proc far

	call	ChartControlSetFlagsFromBoolean
	
	; Make a note that the user is setting this value, so the axis
	; should no longer do this automatically.

	ornf	cl, mask ATA_USER_SET
	mov	ax, MSG_AXIS_SET_TICK_ATTRIBUTES
	GOTO	SendToAxisClass

SetTickAttrsCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToValueAxisClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the specified class

CALLED BY:	ChartAxisControlSet...

PASS:		ax, cx, dx, bp - message data

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToValueAxisClass	proc far
	mov	bx, segment ValueAxisClass
	mov	di, offset  ValueAxisClass
	call	GenControlOutputActionRegs
	ret
SendToValueAxisClass	endp

SendToAxisClass	proc	far
	mov	bx, segment AxisClass
	mov	di, offset AxisClass
	call	GenControlOutputActionRegs
	ret
SendToAxisClass	endp





COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartAxisControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ChartAxisControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of ChartAxisControlClass

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
ChartAxisControlUpdateUI	method dynamic ChartAxisControlClass,
				MSG_GEN_CONTROL_UPDATE_UI


	cmp	dx, GWNT_CHART_AXIS_ATTRIBUTES
	jne	done

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	push	bx

	call	GetChildBlock

	; Set tick attributes

	mov	cl, es:[ANB_xAxisTickAttr]
	mov	dl, es:[ANB_xAxisTickAttrDiffs]
	mov	si, offset XAxisTickAttrGroup
	call	SetBooleanGroupState

	mov	cl, es:[ANB_yAxisTickAttr]
	mov	dl, es:[ANB_yAxisTickAttrDiffs]
	mov	si, offset YAxisTickAttrGroup
	call	SetBooleanGroupState

	pop	bx
	call	MemUnlock
done:
	.leave
	ret
ChartAxisControlUpdateUI	endm

