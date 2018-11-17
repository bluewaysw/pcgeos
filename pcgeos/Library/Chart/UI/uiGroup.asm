COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiGroup.asm

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
	CDB	1/ 2/92   	Initial version.

DESCRIPTION:
	Code for the titles & legend controller

	$Id: uiGroup.asm,v 1.1 97/04/04 17:47:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartGroupControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ChartGroupControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ChartGroupControlClass

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
ChartGroupControlGetInfo	method dynamic	ChartGroupControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset CGC_dupInfo
	GOTO	CopyDupInfoCommon
ChartGroupControlGetInfo	endm


CGC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	CGC_IniFileKey,			; GCBI_initFileKey
	CGC_gcnList,			; GCBI_gcnList
	length CGC_gcnList,		; GCBI_gcnCount
	CGC_notifyGroupList,		; GCBI_notificationList
	length CGC_notifyGroupList,	; GCBI_notificationCount
	CGCName,			; GCBI_controllerName

	handle GroupControlUI,		; GCBI_dupBlock
	CGC_childList,			; GCBI_childList
	length CGC_childList,		; GCBI_childCount
	CGC_featuresList,		; GCBI_featuresList
	length CGC_featuresList,	; GCBI_featuresCount
	CGC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0,				; GCBI_toolFeatures
	CGC_helpContext>		; GCBI_helpContext

CGC_helpContext	char	"dbChrtGrp", 0

CGC_DEFAULT_FEATURES equ mask CGCF_TITLE_ON_OFF or \
				mask CGCF_LEGEND

CGC_IniFileKey	char	"chartGroup", 0

CGC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_CHART_GROUP_FLAGS>

CGC_notifyGroupList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_CHART_GROUP_FLAGS>

;---

CGC_childList	GenControlChildInfo	\
	<TitleInteraction, mask CGCF_TITLE_ON_OFF or mask CGCF_TITLE_TEXT, 0>,
	<LegendInteraction, mask CGCF_LEGEND, mask GCCF_IS_DIRECTLY_A_FEATURE>

CGC_featuresList	GenControlFeaturesInfo	\
	<LegendInteraction, 0, 0>,
	<TitleGroup, 0, 0>,
	<TitleTextGroup, 0, 0>

COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartGroupControlGetInfo --
		MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI for ChartGroupControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ChartGroupControlClass

	ax - The message

	cx - dup block
	dx - features

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	hack to remove ":" from title prompts if no text fields

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/98		Initial version

------------------------------------------------------------------------------@

ifdef GPC

ChartGroupTweakDuplicatedUI	method dynamic	ChartGroupControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	;
	; while we're here center our children if a dialog
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jne	notDialog
	push	cx, dx
	mov	cx, HINT_CENTER_CHILDREN_HORIZONTALLY
	mov	dl, VUM_MANUAL
	mov	ax, MSG_GEN_ADD_GEOMETRY_HINT
	call	ObjCallInstanceNoLock
	pop	cx, dx
notDialog:
	;
	; tweak monikers
	;
	test	dx, mask CGCF_TITLE_TEXT
	jnz	done
	mov	bx, cx
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, offset XAxisTitleBoolean
	call	tweakMoniker
	mov	si, offset YAxisTitleBoolean
	call	tweakMoniker
	mov	si, offset ChartTitleBoolean
	call	tweakMoniker
	call	MemUnlock
done:
	ret

tweakMoniker	label	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GI_visMoniker
	tst	di
	jz	doneMoniker
	mov	di, ds:[di]
	test	ds:[di].VM_type, mask VMT_GSTRING
	jnz	doneMoniker
	lea	di, ds:[di].VM_data.VMT_text
	segmov	es, ds
	LocalStrLength			; es:di points at null
	cmp	cx, 1
	jb	doneMoniker
	cmp	{TCHAR}es:[di-2*(size TCHAR)], C_COLON
	jne	doneMoniker
	mov	{TCHAR}es:[di-2*(size TCHAR)], C_NULL
doneMoniker:
	retn
ChartGroupTweakDuplicatedUI	endm

endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartGroupControlSetGroupFlags -- MSG_CGC_SET_GROUP_FLAGS
						for ChartGroupControlClass

DESCRIPTION:	Update the UI stuff based on the setting of the 
		ChartGroupFlags.

PASS:
	*ds:si - instance data
	es - segment of ChartGroupControlClass

	ax - The message
	cl - ChartGroupFlags that are SET
	dl - indeterminate ChartGroupFlags
	bp - ChartGroupFlags that are MODIFIED

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/92		Initial version 

------------------------------------------------------------------------------@
ChartGroupControlSetGroupFlags	method ChartGroupControlClass,
						MSG_CGC_SET_GROUP_FLAGS

	call	ChartControlSetFlagsFromBoolean
	call	SendGroupFlags
	ret
ChartGroupControlSetGroupFlags	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupControlSetLegendType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the legend type (vert/horizontal)

PASS:		*ds:si	= ChartGroupControlClass object
		ds:di	= ChartGroupControlClass instance data
		es	= Segment of ChartGroupControlClass.
		cl	- current selection

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	1/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupControlSetLegendType	method	dynamic	ChartGroupControlClass, 
					MSG_CGC_SET_LEGEND_TYPE

	.enter

	
	;
	; If the legend ON/OFF boolean is OFF, then don't send any
	; legend type
	;

	push	cx, si			; legend type, controller
	call	GetChildBlock
	mov	si, offset LegendOnOffGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	test	ax, mask CGF_LEGEND
	pop	cx, si			; legend type, controller

	jz	noLegend

	;
	; There IS a legend, so see whether it's vertical or horizontal
	;

	test	cl, mask CGF_LEGEND_VERTICAL
	jnz	sendFlags
	mov	ch, mask CGF_LEGEND_VERTICAL

sendFlags:

	call	SendGroupFlags

	.leave
	ret

	;
	; There's no legend, so clear the CGF_LEGEND flag, and set none
	;

noLegend:
	mov	ch, mask CGF_LEGEND
	clr	cl
	jmp	sendFlags

ChartGroupControlSetLegendType	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendGroupFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send group flags, followed by a BUILD message

CALLED BY:	ChartGroupControlSetGroupFlags, 
		ChartGroupControlSetLegendType

PASS:		cl - group flags to SET
		ch - group flags to CLEAR

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendGroupFlags	proc near
	.enter

	mov	ax, MSG_CHART_GROUP_SET_GROUP_FLAGS
	mov	bx, segment ChartGroupClass
	mov	di, offset ChartGroupClass
	call	GenControlOutputActionRegs

	mov	bp, mask BCF_GROUP_FLAGS
	mov	ax, MSG_CHART_OBJECT_BUILD
	call	GenControlOutputActionRegs

	.leave
	ret
SendGroupFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetObjectText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the text to the text object, unless we shouldn't

CALLED BY:	ChartGroupControlUpdateUI

PASS:		ss:bp - GenControlUpdateUIParams
		si - chunk handle of child object
		ds:bx - pointer to text
		cx - size of text
		al - flag to check before sending text

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetObjectText	proc near
		uses	bp
		.enter

		push	bx			; pointer to text
		mov	bx, ss:[bp].GCUUIP_childBlock	
		pop	bp
		
		test	ds:[GNB_notificationFlags], al
		jnz	useNull
		jcxz	useNull
		mov	dx, ds			; dx:bp - text

sendIt::		
		clr	cx, di			; null terminated
sendItXIP::
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessage

		.leave
		ret
useNull:
if FULL_EXECUTE_IN_PLACE
		clr	cx, di
		push	cx			; null str on stack
		mov	bp, sp
		mov	dx, ss			; dx:bp = null str on stack
		jmp	sendItXIP
else
		mov	dx, cs
		mov	bp, offset CGCNull
		jmp	sendIt
endif
SetObjectText	endp

ife FULL_EXECUTE_IN_PLACE
CGCNull	char	0
endif


COMMENT @----------------------------------------------------------------------

MESSAGE:	ChartGroupControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for ChartGroupControlClass

DESCRIPTION:	Handle notification of type change

PASS:
	*ds:si - instance data
	es - segment of ChartGroupControlClass

	ax - The message
	dx - NotificationStandardNotificationGroup
	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED: ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91	Initial version

------------------------------------------------------------------------------@
ChartGroupControlUpdateUI	method ChartGroupControlClass,
				MSG_GEN_CONTROL_UPDATE_UI


	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	push	bx

	test	ss:[bp].GCUUIP_features, mask CGCF_TITLE_TEXT
	jz	afterTextObjects

	mov	si, offset ChartTitleText
	mov	bx, offset GNB_chartTitle
	mov	cx, ds:[GNB_chartTitleSize]
	mov	al, mask GNF_CHART_TITLE_DIFF
	call	SetObjectText

	mov	si, offset XAxisTitleText
	mov	bx, ds:[GNB_xAxisTitle]
	mov	cx, ds:[GNB_xAxisTitleSize]
	mov	al, mask GNF_X_AXIS_TITLE_DIFF
	call	SetObjectText

	mov	si, offset YAxisTitleText
	mov	bx, ds:[GNB_yAxisTitle]
	mov	cx, ds:[GNB_yAxisTitleSize]
	mov	al, mask GNF_Y_AXIS_TITLE_DIFF
	call	SetObjectText

afterTextObjects:

	mov	al, ds:[GNB_notificationFlags]
	mov	ah, ds:[GNB_type]		
	mov	cl, ds:[GNB_groupFlags]
	mov	dl, ds:[GNB_groupFlagDiffs]

	pop	bx
	call	MemUnlock
	pop	ds

	mov	bx, ss:[bp].GCUUIP_childBlock

	; enable/disable x and y axis titles based on chart type

	cmp	ah, CT_PIE
	mov	si, offset XAxisTitleBoolean
	call	DisableOrEnableOnZFlag

	mov	si, offset YAxisTitleBoolean
	call	DisableOrEnableOnZFlag

	cmp	ah, CT_HIGH_LOW
	mov	si, offset LegendInteraction
	call	DisableOrEnableOnZFlag

	test	ss:[bp].GCUUIP_features, mask CGCF_TITLE_TEXT
	jz	afterDisableText

	cmp	ah, CT_PIE
	mov	si, offset XAxisTitleText
	call	DisableOrEnableOnZFlag
		
	mov	si, offset YAxisTitleText
	call	DisableOrEnableOnZFlag

afterDisableText:	
	mov	si, offset TitleGroup
	call	SetBooleanGroupState
	;
	; Have the boolean group send out its status message, which
	; will do the right thing with respect to the title text objects.
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SEND_STATUS_MSG
	clr	di
	call	ObjMessage

	mov	si, offset LegendOnOffGroup
	call	SetBooleanGroupState

	; set legend type (horiz or vert)

	push	cx
	andnf	cx, mask CGF_LEGEND_VERTICAL or mask CGF_LEGEND
	ornf	cx, mask CGF_LEGEND
	mov	si, offset LegendTypeGroup
	call	SetItemGroupSelection
	pop	cx

	test	cl, mask CGF_LEGEND
	mov	si, offset LegendTypeGroup
	call	DisableOrEnableOnZFlag

	.leave
	ret
ChartGroupControlUpdateUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupControlTitleStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Disable or enable title text objects whenever the
		boolean group changes.

PASS:		*ds:si	- ChartGroupControlClass object
		ds:di	- ChartGroupControlClass instance data
		es	- segment of ChartGroupControlClass
		cx 	- selected booleans
		dx	- indeterminate booleans

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupControlTitleStatus	method	dynamic	ChartGroupControlClass, 
					MSG_CGC_TITLE_STATUS

		or	cx, dx

		call	GetChildBlockAndFeatures	; bx - child block
		test	ax, mask CGCF_TITLE_TEXT
		jz	done
		
		test	cl, mask CGF_CHART_TITLE
		mov	si, offset ChartTitleText
		call	DisableOrEnableOnZFlag
		call	SetNotModifiedIfZero
		
		test	cl, mask CGF_X_AXIS_TITLE
		mov	si, offset XAxisTitleText
		call	DisableOrEnableOnZFlag
		call	SetNotModifiedIfZero

		test	cl, mask CGF_Y_AXIS_TITLE
		mov	si, offset YAxisTitleText
		call	DisableOrEnableOnZFlag
		call	SetNotModifiedIfZero
done:
		ret
ChartGroupControlTitleStatus	endm

GetChildBlockAndFeatures	proc	near
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret
GetChildBlockAndFeatures	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNotModifiedIfZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the Z flag is passed in as set, then set the object
		not modified, so that it doesn't send out its apply msg

CALLED BY:	ChartGroupControlTitleStatus

PASS:		^lbx:si - text object

RETURN:		nothing 

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNotModifiedIfZero	proc near
		uses	cx
		.enter
		
		jnz	done

		mov	ax, MSG_GEN_TEXT_SET_MODIFIED_STATE
		clr	cx, di
		call	ObjMessage
done:
		.leave
		ret
SetNotModifiedIfZero	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableOrEnableOnZFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If Z flag is set, disable, otherwise enable

CALLED BY:	ChartGroupControlUpdateUI

PASS:		^lbx:si - object to send mesage to
		Z Flag - clear = enable, set = disable

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableOrEnableOnZFlag	proc near	
		uses	ax,dx,di

		.enter

		pushf	
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_ENABLED
		jnz	callIt
		CheckHack <MSG_GEN_SET_NOT_ENABLED eq MSG_GEN_SET_ENABLED+1>
		inc	ax
callIt:
		clr	di
		call	ObjMessage
		popf

		.leave
		ret
DisableOrEnableOnZFlag	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupControlLegendStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= ChartGroupControlClass object
		ds:di	= ChartGroupControlClass instance data
		es	= segment of ChartGroupcontrolClass
		cl - CGF_LEGEND set or clear
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ChartGroupControlLegendStatus	method	dynamic	ChartGroupControlClass, 
					MSG_CGC_LEGEND_STATUS
	.enter
	call	GetChildBlock
	mov	si, offset LegendTypeGroup
	test	cl, mask CGF_LEGEND
	call	DisableOrEnableOnZFlag
	.leave
	ret
ChartGroupControlLegendStatus	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupControlSetTitleText
		ChartGroupControlSetXAxisText
		ChartGroupControlSetYAxisText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the title text from ChartGroupControl and calls
		MSG_CHART_GROUP_SET_?????_TEXT

CALLED BY:	MSG_CGC_SET_TITLE_TEXT (UI)
PASS:		*ds:si	= ChartGroupControlClass object
		ds:di	= ChartGroupControlClass instance data
		ds:bx	= ChartGroupControlClass object (same as *ds:si)
		es 	= segment of ChartGroupControlClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	BC	8/13/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupControlSetTitleText	method dynamic ChartGroupControlClass, 
					MSG_CGC_SET_TITLE_TEXT

	mov	ax, MSG_CHART_GROUP_SET_TITLE_TEXT
	mov	cx, offset ChartTitleText
	GOTO	ChartGroupControlSetTextCommon
ChartGroupControlSetTitleText	endm

ChartGroupControlSetXAxisText	method dynamic ChartGroupControlClass, 
					MSG_CGC_SET_X_AXIS_TEXT

	mov	ax, MSG_CHART_GROUP_SET_X_AXIS_TEXT
	mov	cx, offset XAxisTitleText
	GOTO	ChartGroupControlSetTextCommon

ChartGroupControlSetXAxisText	endm

ChartGroupControlSetYAxisText	method dynamic ChartGroupControlClass, 
					MSG_CGC_SET_Y_AXIS_TEXT
	mov	ax, MSG_CHART_GROUP_SET_Y_AXIS_TEXT
	mov	cx, offset YAxisTitleText
	FALL_THRU ChartGroupControlSetTextCommon

ChartGroupControlSetYAxisText	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChartGroupControlSetTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text

CALLED BY:	ChartGroupControlSetTitleText,
		ChartGroupControlSetXAxisText,
		ChartGroupControlSetYAxisText
		

PASS:		ax - message to send to ChartGroup
		cx - chunk handle of text object in child block from which
		     to get the data

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp,bx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChartGroupControlSetTextCommon	proc far

	; Get the text
	;
		push	ax, si
		call	GetChildBlock			; bx <- child block
		mov	si, cx
		mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
		clr	dx				; allocate new block
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; cx <- handle of block
		pop	ax, si
	;
	; Send it to the chart group
	;
		mov	bx, segment ChartGroupClass
		mov	di, offset ChartGroupClass
		call	GenControlOutputActionRegs

		ret
ChartGroupControlSetTextCommon	endp

