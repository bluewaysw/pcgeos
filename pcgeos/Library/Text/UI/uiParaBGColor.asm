COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiParaBGColorControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ParaBGColorControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement ParaBGColorControlClass

	$Id: uiParaBGColor.asm,v 1.1 97/04/07 11:17:28 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	ParaBGColorControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS


TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaBGColorControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ParaBGColorControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of ParaBGColorControlClass

	ax - The message

RETURN:
	cx:dx - list of children

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
ParaBGColorControlGetInfo	method dynamic	ParaBGColorControlClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset ParaBGColorControlClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset PBGCC_newFields
	mov	cx, length PBGCC_newFields
	call	CopyFieldsToBuildInfo
	ret

ParaBGColorControlGetInfo	endm

PBGCC_newFields	GC_NewField	\
	<offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
	<offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword PBGCC_IniFileKey>>,
	<offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword PBGCC_gcnList>>,
	<offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword length PBGCC_gcnList>>,
	<offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword PBGCC_notifyList>>,
	<offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size PBGCC_notifyList>>,
	<offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr PBGCCName>>,
	<offset GCBI_features, size GCBI_features,
				<GCD_dword PBGCC_DEFAULT_FEATURES>>,
	<offset GCBI_toolFeatures, size GCBI_toolFeatures,
				<GCD_dword PBGCC_DEFAULT_TOOLBOX_FEATURES>>,
	<offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword PBGCC_helpContext>>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

PBGCC_helpContext	char	"dbParaClr", 0


PBGCC_IniFileKey	char	"charBGColor", 0

PBGCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_PARA_COLOR_CHANGE>

PBGCC_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_PARA_COLOR_CHANGE>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaBGColorControlOutputAction -- MSG_GEN_OUTPUT_ACTION
					for ParaBGColorControlClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of ParaBGColorControlClass

	ax - The message

	cx:dx - destination (or travel option)
	bp - event

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
ParaBGColorControlOutputAction	method dynamic	ParaBGColorControlClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset ParaBGColorControlClass
	GOTO	ColorInterceptAction

ParaBGColorControlOutputAction	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaBGColorControlSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for ParaBGColorControlClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of ParaBGColorControlClass

	ax - The message

	dxcx - color

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
ParaBGColorControlSetColor	method dynamic	ParaBGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_COLOR

	mov	ax, MSG_VIS_TEXT_SET_PARA_BG_COLOR
	GOTO	SendVisText_AX_DXCX_Common

ParaBGColorControlSetColor	endm

;---

ParaBGColorControlSetDrawMask	method dynamic	ParaBGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_DRAW_MASK

	mov	ax, MSG_VIS_TEXT_SET_PARA_BG_GRAY_SCREEN
	GOTO	SendVisText_AX_CX_Common

ParaBGColorControlSetDrawMask	endm

;---

ParaBGColorControlSetPattern	method dynamic	ParaBGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_PATTERN

	mov	ax, MSG_VIS_TEXT_SET_PARA_BG_PATTERN
	GOTO	SendVisText_AX_CX_Common

ParaBGColorControlSetPattern	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ParaBGColorControlUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for ParaBGColorControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of ParaBGColorControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams
    		GCUUIP_manufacturer         ManufacturerID
    		GCUUIP_changeType           word
    		GCUUIP_dataBlock            hptr
			
    		GCUUIP_toolInteraction      optr
    		GCUUIP_features             word 
    		GCUUIP_toolboxFeatures      word
    		GCUUIP_childBlock           hptr

RETURN:	none

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
ParaBGColorControlUpdateUI	method dynamic ParaBGColorControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	push	ds
	mov	dx, GWNT_TEXT_PARA_COLOR_CHANGE
	call	GetColorNotifyCommon
	je	gotColor			;branch if got color
	;
	; Get text color from VisTextNotifyParaAttrChange
	;
	mov	al, ds:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_bgGrayScreen
	movdw	dxcx, ds:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_bgColor
	mov	bx, {word} ds:VTNPAC_paraAttr.VTMPA_paraAttr.VTPA_bgPattern
	mov	di, ds:VTNPAC_paraAttrDiffs.VTPAD_diffs
gotColor:
	call	UnlockNotifBlock
	pop	ds

	; convert para BG flags to char FG flags for common routine

	push	ax
	mov_tr	ax, di
	clr	di
	test	ax, mask VTPAF_MULTIPLE_BG_COLORS
	jz	10$
	mov	di, mask VTCAF_MULTIPLE_COLORS
10$:
	test	ax, mask VTPAF_MULTIPLE_BG_GRAY_SCREENS
	jz	20$
	ornf	di, mask VTCAF_MULTIPLE_GRAY_SCREENS
20$:
	test	ax, mask VTPAF_MULTIPLE_BG_PATTERNS
	jz	30$
	ornf	di, mask VTCAF_MULTIPLE_PATTERNS
30$:
	pop	ax

	; dxcx - color
	; al - SystemDrawMask
	; bx - GraphicPattern
	; di - VisTextParaAttrFlags
	;	VTCAF_MULTIPLE_COLORS
	;	VTCAF_MULTIPLE_GRAY_SCREENS
	;	VTCAF_MULTIPLE_PATTERNS

	call	UpdateColorCommon

	ret

ParaBGColorControlUpdateUI	endm

TextControlCode ends


endif		; not NO_CONTROLLERS
