COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiTabControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	TabControlClass		Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement TabControlClass

	$Id: uiTab.asm,v 1.1 97/04/07 11:17:26 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	TabControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for TabControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

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
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
TabControlGetInfo	method dynamic	TabControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset TC_dupInfo
	GOTO	CopyDupInfoCommon

TabControlGetInfo	endm

TC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY or \
	mask GCBF_IS_ON_ACTIVE_LIST or \
	mask GCBF_ALWAYS_ON_GCN_LIST,	; GCBI_flags
	TC_IniFileKey,			; GCBI_initFileKey
	TC_gcnList,			; GCBI_gcnList
	length TC_gcnList,		; GCBI_gcnCount
	TC_notifyTypeList,		; GCBI_notificationList
	length TC_notifyTypeList,	; GCBI_notificationCount
	TCName,				; GCBI_controllerName

	handle TabControlUI,		; GCBI_dupBlock
	TC_childList,			; GCBI_childList
	length TC_childList,		; GCBI_childCount
	TC_featuresList,		; GCBI_featuresList
	length TC_featuresList,		; GCBI_featuresCount
	TC_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	TC_DEFAULT_TOOLBOX_FEATURES,	; GCBI_toolFeatures
	TC_helpContext>			; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment resource
endif

TC_helpContext	char	"dbTab", 0

TC_IniFileKey	char	"tabs", 0

TC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>

TC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>

;---

TC_childList	GenControlChildInfo	\
	<offset TabList, mask TCF_LIST,	mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TabPositionRange, mask TCF_POSITION,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TabTypeList, mask TCF_TYPE,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TabLeaderList, mask TCF_LEADER,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset TabLineGroup, mask TCF_LINE or mask TCF_GRAY_SCREEN, 0>,
	<offset ClearTabTrigger, mask TCF_CLEAR,
					mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ClearAllTabsTrigger, mask TCF_CLEAR_ALL,
					mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TC_featuresList	GenControlFeaturesInfo	\
	<offset ClearAllTabsTrigger, ClearAllTabsName, 0>,
	<offset ClearTabTrigger, ClearTabName, 0>,
	<offset TabLineList, TabLineName, 0>,
	<offset TabLeaderList, TabLeaderName, 0>,
	<offset TabTypeList, TabTypeName, 0>,
	<offset TabGrayScreenRange, TabGrayScreenName, 0>,
	<offset TabPositionRange, TabPositionName, 0>,
	<offset TabList, TabListName, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

TextControlCommon ends

;---

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
		for TabControlClass

DESCRIPTION:	Clean up instance data the refers to UI objects

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/10/93		Initial version

------------------------------------------------------------------------------@
TabControlGenerateUI	method dynamic	TabControlClass,
					MSG_GEN_CONTROL_GENERATE_UI

	; Reset the # of tabs, and then call our superclass. This
	; prevents us from mistakenly not re-displaying the list of
	; tabs, if the list of tabs has not changed since the last
	; time the UI for this controller existed.

	mov	ds:[di].TCI_numberOfTabs, -1
	mov	di, offset TabControlClass
	GOTO	ObjCallSuperNoLock

TabControlGenerateUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlNotify -- MSG_META_NOTIFY for TabControlClass

DESCRIPTION:	Look for GWNT_TAB_DOUBLE_CLICK

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

	cx - manufacturer
	dx - type
	bp - data

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/10/93		Initial version

------------------------------------------------------------------------------@
TabControlNotify	method dynamic	TabControlClass, MSG_META_NOTIFY
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jnz	toSuper
	cmp	dx, GWNT_TAB_DOUBLE_CLICK
	jnz	toSuper

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GOTO	ObjCallInstanceNoLock

toSuper:
	mov	di, offset TabControlClass
	GOTO	ObjCallSuperNoLock

TabControlNotify	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlSelectTab -- MSG_TC_SELECT_TAB for TabControlClass

DESCRIPTION:	Handle a tab being selected

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

	cx - current selection
	dx - GenItemGroupStateFlags
	bp - number of selections

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 9/92		Initial version

------------------------------------------------------------------------------@
TabControlSelectTab	method dynamic	TabControlClass, MSG_TC_SELECT_TAB

	mov	ax, -1
	jcxz	10$
	dec	cx
		CheckHack <(size Tab) eq 8>
	shl	cx
	shl	cx
	shl	cx
	add	di, cx
	mov	ax, ds:[di].TCI_tabList.T_position
10$:
	mov_tr	cx, ax
	mov	ax, MSG_VIS_TEXT_SET_SELECTED_TAB
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	GenControlSendToOutputRegs
	ret

TabControlSelectTab	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlQueryTab -- MSG_TC_QUERY_TAB for TabControlClass

DESCRIPTION:	Return list item monikers

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

	cxdx - requesting list
	bp - item number

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 9/92		Initial version

------------------------------------------------------------------------------@
TabControlQueryTab	method dynamic	TabControlClass, MSG_TC_QUERY_TAB
	mov_tr	ax, bp
buf	local	LOCAL_DISTANCE_BUFFER_SIZE dup (char)
params	local	ReplaceItemMonikerFrame
	.enter

	pushdw	cxdx
	mov	params.RIMF_item, ax

	; if this is item zero then pass "new tab"

	tst	ax
	jnz	notNewTab

	mov	bx, handle NewTabString
	call	MemLock
	mov	es, ax
assume es:nothing
	mov	di, es:[NewTabString]
assume es:dgroup
	clr	cx				; null-terminated
	jmp	common

notNewTab:
	dec	ax
		CheckHack <(size Tab) eq 8>
	shl	ax
	shl	ax
	shl	ax
	add	di, ax
	push	ds:[di].TCI_tabList.T_position

	push	bp
	mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
	call	GenCallApplication
	pop	bp
	pop	dx

	segmov	es, ss
	lea	di, buf				;es:di = buffer
	mov	ch, al				;ah = measurement type
	mov	cl, DU_INCHES_OR_CENTIMETERS
	clr	bx

	clr	ax				;make 13.3 value into WWFixed
	shr	dx, 1				;
	rcr	ax, 1
	shr	dx, 1
	rcr	ax, 1
	shr	dx, 1
	rcr	ax, 1
	call	LocalDistanceToAscii		;cx = length
common:
	mov	params.RIMF_length, cx
	movdw	params.RIMF_source, esdi
	mov	params.RIMF_sourceType, VMST_FPTR
	mov	params.RIMF_dataType, VMDT_TEXT
	mov	params.RIMF_itemFlags, 0

	popdw	axsi				;axsi = list
	push	bx, bp				;save handle
	mov_tr	bx, ax
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	mov	dx, size ReplaceItemMonikerFrame
	lea	bp, params
	mov	di, mask MF_STACK
	call	ObjMessage
	pop	bx, bp

	tst	bx
	jz	noUnlock
	call	MemUnlock
noUnlock:

	.leave
	ret

TabControlQueryTab	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlApply -- MSG_GEN_APPLY for TabControlClass

DESCRIPTION:	Apply changes

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/13/92		Initial version

------------------------------------------------------------------------------@
TabControlApply	method dynamic	TabControlClass, MSG_GEN_APPLY
params		local	VisTextSetTabParams
features	local	TCFeatures
	.enter

	; initialize the current tab's attributes, or if we're creating
	; a new tab, set the default values for a tab

	push	si
	call	SelectedTabDI
	jnc	storeData
	clr	ax
	mov	ss:[params].VTSTP_tab.T_position, ax
	mov	ss:[params].VTSTP_tab.T_attr, al
	mov	ss:[params].VTSTP_tab.T_grayScreen, SDM_100
	mov	{word} ss:[params].VTSTP_tab.T_lineWidth, ax
	jmp	continue
storeData:
	mov	si, di					;ds:si = Tab
	segmov	es, ss
	lea	di, ss:[params].VTSTP_tab
	mov	cx, (size Tab)
	rep	movsb
	pop	si
continue:
	mov	ss:[params].VTSTP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	call	GetFeaturesAndChildBlock		;bx = child block
	mov	ss:[features], al

	; if the position has changed then nuke the tab at the old position

	test	ax, mask TCF_POSITION
	jz	havePosition
	push	si
	mov	si, offset TabPositionRange
	call	CallRangeGetValueTimes8			;cx = new position
	pop	si
	mov	ss:[params].VTSTP_tab.T_position, cx
havePosition:
	call	SelectedTabDI
	jc	getType
	mov	cx, ds:[di].T_position			;cx = old position
	mov	dx, ss:[params].VTSTP_tab.T_position	;dx = new position
	cmp	cx, dx
	jz	getType
	mov	ax, MSG_VIS_TEXT_CLEAR_TAB
	call	SendVisText_AX_CX_Common

	; get the type of tab
getType:
	push	si
	test	ss:[features], mask TCF_TYPE
	jz	getLeader
	mov	si, offset TabTypeList
	call	CallListGetExcl				;ax = type
	and	ss:[params].VTSTP_tab.T_attr, not (mask TA_TYPE)
	or	ss:[params].VTSTP_tab.T_attr, al

	; get the leader for the tab
getLeader:
	test	ss:[features], mask TCF_LEADER
	jz	getAnchor
	mov	si, offset TabLeaderList
	call	CallListGetExcl
	and	ss:[params].VTSTP_tab.T_attr, not (mask TA_LEADER)
	or	ss:[params].VTSTP_tab.T_attr, al

	; get the anchor character
getAnchor:
	push	bx
	call	LocalGetNumericFormat
	mov	ss:[params].VTSTP_tab.T_anchor, cx
	pop	bx

	; calculate the shading for a vertical line

	test	ss:[features], mask TCF_GRAY_SCREEN
	jz	getLine
	mov	si, offset TabGrayScreenRange
	call	CallRangeGetValue

	; cx = 0 to 100, convert to SystemDrawMask which is 0 to 64

	; dm = (value/100)*64 = value*(64/100)

	mov	ax, (64*256)/100
	mul	cx				;dx.ax = result/256, use dl.ah
	adddw	dxax, 0x80			;round
	mov	ch, dl
	mov	cl, ah

	; cx = 0 to 64, get SDM_100 - (cx-64) = (SDM_100+64) - cx

	neg	cx
	add	cx, SDM_100 + 64
	mov	ss:[params].VTSTP_tab.T_grayScreen, cl

	; calculate the width of the tab line
getLine:
	test	ss:[features], mask TCF_LINE
	jz	setTab
	mov	si, offset TabLineWidthRange
	call	CallRangeGetValueTimes8
	mov	ss:[params].VTSTP_tab.T_lineWidth, cl

	mov	si, offset TabSpacingRange
	call	CallRangeGetValueTimes8
	mov	ss:[params].VTSTP_tab.T_lineSpacing, cl

	; set the tab!!!
setTab:
	pop	si
	push	bp
	mov	ax, MSG_VIS_TEXT_SET_TAB
	lea	bp, ss:[params]			;ss:bp = VisTextSetTabParams
	mov	dx, size VisTextSetTabParams
	mov	bx, segment VisTextClass
	mov	di, offset VisTextClass
	call	GenControlOutputActionStack
	pop	bp

	mov	cx, ss:[params].VTSTP_tab.T_position
	mov	ax, MSG_VIS_TEXT_SET_SELECTED_TAB
	call	SendVisText_AX_CX_Common

if KEYBOARD_ONLY_UI
	;
	; Select the new entry again, now.  -cbh 1/22/94
	;
	call	GetFeaturesAndChildBlock
	test	ax, mask TCF_LIST
	jz	done
	clr	dx
	mov	si, offset TabList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	objMessageQueue
	mov	cx, si			;set modified, so set status
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	objMessageQueue
	mov	cx, si			;send modified
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	objMessageQueue
done:
endif
	.leave
	ret

if KEYBOARD_ONLY_UI
objMessageQueue	label	near
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	retn
endif
TabControlApply	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlSetTabLine -- MSG_TC_SET_TAB_LINE for TabControlClass

DESCRIPTION:	Deal with tab lines being turned on or off

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

	cx - 1 for on, 0 for off

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/13/92		Initial version

------------------------------------------------------------------------------@
TabControlSetTabLine	method dynamic	TabControlClass, MSG_TC_SET_TAB_LINE

	; set some default values

	call	GetFeaturesAndChildBlock
	push	ax				;save TCFeatures
	push	cx
	mov	si, offset TabLineWidthRange
	call	SendRangeSetValueNoIndeterminate
	mov	cx, 1				;default tab spacing is one
	mov	si, offset TabSpacingRange
	call	SendRangeSetValueNoIndeterminate
	pop	cx

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	20$
	mov	ax, MSG_GEN_SET_ENABLED
20$:
	mov	dl, VUM_NOW
	mov	si, offset TabLineWidthRange
	call	ObjMessageSend
	mov	si, offset TabSpacingRange
	call	ObjMessageSend

	pop	bp				;restore TCFeatures
	test	bp, mask TCF_GRAY_SCREEN
	jz	done
	mov	si, offset TabGrayScreenRange
	call	ObjMessageSend
	mov	cx, 100
	call	SendRangeSetValueNoIndeterminate
done:
	ret

TabControlSetTabLine	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlSetTabType -- MSG_TC_SET_TAB_TYPE for TabControlClass

DESCRIPTION:	Deal with the tab type changing

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

	cx - TabType

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/13/92		Initial version

------------------------------------------------------------------------------@
TabControlSetTabType	method dynamic	TabControlClass, MSG_TC_SET_TAB_TYPE

	; set some default values

	call	GetFeaturesAndChildBlock
	test	ax, mask TCF_LINE
	jz	noChanges
	call	SetTabTypeCommon
noChanges:
	ret

TabControlSetTabType	endm

;---

SetTabTypeCommon	proc	near

	; if left or right then enable line group else disable it

	mov	ax, MSG_GEN_SET_ENABLED
	cmp	cx, TT_LEFT
	jz	gotMessage
	cmp	cx, TT_RIGHT
	jz	gotMessage

	; not only do we want to set not enabled, we want to set some default
	; values

	clr	cx
	clr	dx
	mov	si, offset TabLineList
	call	SendListSetExcl
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	call	ObjMessageSend			; to enable/disable UI gadgetry
						; in the "Vertical Line" group
	mov	si, offset TabLineWidthRange
	call	SendRangeSetValueNoIndeterminate

	mov	ax, MSG_GEN_SET_NOT_ENABLED
gotMessage:
	mov	dl, VUM_NOW
	mov	si, offset TabLineGroup
	call	ObjMessageSend

	ret
SetTabTypeCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlClearTab -- MSG_TC_CLEAR_TAB for TabControlClass

DESCRIPTION:	Clear the current tab

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/13/92		Initial version

------------------------------------------------------------------------------@
TabControlClearTab	method dynamic	TabControlClass, MSG_TC_CLEAR_TAB

	call	SelectedTabDI
	mov	cx, ds:[di].T_position

	mov	ax, MSG_VIS_TEXT_CLEAR_TAB
	call	SendVisText_AX_CX_Common
	ret

TabControlClearTab	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlClearAllTabs -- MSG_TC_CLEAR_ALL_TABS
						for TabControlClass

DESCRIPTION:	Clear all tabs

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/13/92		Initial version

------------------------------------------------------------------------------@
TabControlClearAllTabs	method dynamic	TabControlClass, MSG_TC_CLEAR_ALL_TABS

	; by calling SendVisText_AX_CX_Common we're sending an extra
	; word that is not used.  so shoot me.

	mov	ax, MSG_VIS_TEXT_CLEAR_ALL_TABS
	call	SendVisText_AX_CX_Common

	ret

TabControlClearAllTabs	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TabControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for TabControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of TabControlClass

	ax - The message

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
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
TabControlUpdateUI	method dynamic TabControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	es, ax
	mov	bx, ss:[bp].GCUUIP_childBlock

	push	si
	test	ss:[bp].GCUUIP_features, mask TCF_LIST
	jz	noList

	clr	ax
	mov	al, es:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_numberOfTabs
	mov	cx, ax
		CheckHack <(size Tab) eq 8>
	shl	cx
	shl	cx				;cx = # words
	cmp	ax, ds:[di].TCI_numberOfTabs
	mov	ds:[di].TCI_numberOfTabs, ax
	lea	di, ds:[di].TCI_tabList
	jnz	tabListDiffers

	jcxz	noList
	push	cx, di
	mov	si, di
	mov	di, offset VTPA_tabList
	repe cmpsw
	pop	cx, di
	jz	noList
tabListDiffers:
	push	di
	segxchg	ds, es
	mov	si, offset VTPA_tabList
	rep movsw
	segxchg	ds, es
	pop	di

	; redo tab list

	mov_tr	cx, ax				;cx = num items
	inc	cx				;plus one for "new tab"
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	si, offset TabList
	call	ObjMessageSend
noList:
	pop	si

	; make es:di point at the tab (-1 means "new tab")

	mov	dx, -1				;dx gets tab number
	mov	ax, es:VTNPAC_selectedTab
	cmp	ax, -1
	jz	found
	mov	di, offset VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_tabList
	mov	cx, offset VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_numberOfTabs
	jcxz	found
searchLoop:
	inc	dx
	cmp	ax, es:[di].T_position
	jz	found
	add	di, size Tab
	loop	searchLoop
	mov	dx, -1
found:
	call	Tab_DerefGen_DI
	mov	ds:[di].TCI_selectedTab, dx

	call	UpdateTabUI

	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemUnlock

	ret

TabControlUpdateUI	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateTabUI

DESCRIPTION:	Update the UI components that represent a tab

CALLED BY:	INTERNAL

PASS:
	*ds:si - tab control

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/13/92		Initial version

------------------------------------------------------------------------------@
UpdateTabUI	proc	near	uses bp
	.enter
	class	TabControlClass

	call	GetFeaturesAndChildBlock

	; set the selected tab

	call	Tab_DerefGen_DI
	mov	cx, ds:[di].TCI_selectedTab
	inc	cx				;list starts with "new tab"

	test	ax, mask TCF_LIST
	jz	noList2
	clr	dx
	push	si
	mov	si, offset TabList
	call	SendListSetExcl
	pop	si

	; if "Create New Tab" selected then make Applyable

	push	ax, cx
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	jcxz	5$
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
5$:
	call	ObjCallInstanceNoLock
	pop	ax, cx
noList2:

	; update the clear triggers

	mov	dl, VUM_NOW

	test	ax, mask TCF_CLEAR
	jz	noClear
	push	ax, si
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	8$
	mov	ax, MSG_GEN_SET_ENABLED
8$:
	mov	si, offset ClearTabTrigger
	call	ObjMessageSend
	pop	ax, si
noClear:

	test	di, mask TCF_CLEAR_ALL
	jz	noClearAll
	push	ax, si
	call	Tab_DerefGen_DI
	tst	ds:[di].TCI_numberOfTabs
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jz	9$
	mov	ax, MSG_GEN_SET_ENABLED
9$:
	mov	si, offset ClearAllTabsTrigger
	call	ObjMessageSend
	pop	ax, si
noClearAll:

	; set the tab position

	test	ax, mask TCF_POSITION
	jz	noPosition
	push	si
	clr	cx
	call	SelectedTabDI
	jc	10$
	mov	cx, ds:[di].T_position
10$:
	mov	si, offset TabPositionRange
	call	SendRangeSetValueTimes8NoIndeterminate
	pop	si
noPosition:

	; set the tab gray screen

	test	ax, mask TCF_GRAY_SCREEN
	jz	noGrayScreen
	push	ax, si
	mov	cx, 100
	call	SelectedTabDI
	jc	15$
	mov	cl, ds:[di].T_grayScreen

	; cx = draw mask, get 64 - (cx - SDM_100) = -cx + (64+SDM_100)

	neg	cx
	add	cx, SDM_100 + 64

	mov	ax, (100*256)/64
	mul	cx			;dx.ax = result/128, use dl.ah
	adddw	dxax, 0x80		;round
	mov	ch, dl
	mov	cl, ah

15$:
	mov	si, offset TabGrayScreenRange
	call	SendRangeSetValueNoIndeterminate
	pop	ax, si
noGrayScreen:

	; set the tab type

	test	ax, mask TCF_TYPE
	jz	noType
	push	si
	mov	cx, TT_LEFT
	call	SelectedTabDI
	jc	20$
	mov	cl, ds:[di].T_attr
	and	cx, mask TA_TYPE
20$:
	clr	dx
	mov	si, offset TabTypeList
	call	SendListSetExcl
	pop	si
noType:

	; set the tab leader

	test	ax, mask TCF_LEADER
	jz	noLeader
	push	si
	mov	cx, TL_NONE shl offset TA_LEADER
	call	SelectedTabDI
	jc	30$
	mov	cl, ds:[di].T_attr
	and	cx, mask TA_LEADER
30$:
	clr	dx
	mov	si, offset TabLeaderList
	call	SendListSetExcl
	pop	si
noLeader:

	; set the tab line

	test	ax, mask TCF_LINE
	jz	done

	push	si

	push	ax, si
	call	SelectedTabDI
	mov	cl, ds:[di].T_attr
	and	cx, mask TA_TYPE
	call	SetTabTypeCommon
	pop	ax, si

	test	ax, mask TCF_GRAY_SCREEN		;12/ 8/93 cbh
	pushf

	clr	cx
	call	SelectedTabDI
	jc	40$
	mov	cl, ds:[di].T_lineWidth
40$:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jcxz	50$
	mov	ax, MSG_GEN_SET_ENABLED
50$:
	mov	dl, VUM_NOW
	mov	si, offset TabLineWidthRange
	call	ObjMessageSend
	mov	si, offset TabSpacingRange
	call	ObjMessageSend

	popf					;no grey screen, don't
	jz	55$				;  do this!!! 12/ 8/93 cbh
	mov	si, offset TabGrayScreenRange
	call	ObjMessageSend
55$:
	push	cx
	jcxz	60$
	mov	cx, 1
60$:
	clr	dx
	mov	si, offset TabLineList
	call	SendListSetExcl
	pop	cx
	pop	si

	; set the line width

	push	si
	mov	si, offset TabLineWidthRange
	call	SendRangeSetValueTimes8NoIndeterminate
	pop	si
	jcxz	70$				;if width is 0, force spacing
						;to 0

	clr	cx
	call	SelectedTabDI
	jc	70$
	mov	cl, ds:[di].T_lineSpacing
70$:
	push	si
	mov	si, offset TabSpacingRange
	call	SendRangeSetValueTimes8NoIndeterminate
	pop	si
done:
	.leave
	ret

UpdateTabUI	endp

;--

Tab_DerefGen_DI	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ret
Tab_DerefGen_DI	endp

;---

	; return carry set if "new tab"

SelectedTabDI	proc	near	uses ax
	.enter
	class	TabControlClass

	call	Tab_DerefGen_DI
	mov	ax, ds:[di].TCI_selectedTab
	cmp	ax, -1
	stc
	jz	done
		CheckHack <(size Tab) eq 8>
	shl	ax
	shl	ax
	shl	ax
	add	di, ax
	add	di, offset TCI_tabList
	clc
done:
	.leave
	ret
SelectedTabDI	endp


TextControlCode ends

endif		; not NO_CONTROLLERS
