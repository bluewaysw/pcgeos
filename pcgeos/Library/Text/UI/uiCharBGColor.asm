COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiCharBGColorControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	CharBGColorControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement CharBGColorControlClass

	$Id: uiCharBGColor.asm,v 1.1 97/04/07 11:17:01 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	CharBGColorControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharBGColorControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for CharBGColorControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of CharBGColorControlClass

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
CharBGColorControlGetInfo	method dynamic	CharBGColorControlClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset CharBGColorControlClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset CBGCC_newFields
	mov	cx, length CBGCC_newFields
	call	CopyFieldsToBuildInfo
	ret

CharBGColorControlGetInfo	endm

CBGCC_newFields	GC_NewField	\
	<offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
	<offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword CBGCC_IniFileKey>>,
	<offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword CBGCC_gcnList>>,
	<offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword length CBGCC_gcnList>>,
	<offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword CBGCC_notifyList>>,
	<offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size CBGCC_notifyList>>,
	<offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr CBGCCName>>,
	<offset GCBI_features, size GCBI_features,
				<GCD_dword CBGCC_DEFAULT_FEATURES>>,
	<offset GCBI_toolFeatures, size GCBI_toolFeatures,
				<GCD_dword CBGCC_DEFAULT_TOOLBOX_FEATURES>>,
	<offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword CBGCC_helpContext>>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

CBGCC_helpContext	char	"dbCharBGClr", 0

CBGCC_IniFileKey	char	"charBGColor", 0

CBGCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_BG_COLOR_CHANGE>

CBGCC_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_BG_COLOR_CHANGE>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharBGColorControlOutputAction -- MSG_GEN_OUTPUT_ACTION
					for CharBGColorControlClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of CharBGColorControlClass

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
CharBGColorControlOutputAction	method dynamic	CharBGColorControlClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset CharBGColorControlClass
	GOTO	ColorInterceptAction

CharBGColorControlOutputAction	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharBGColorControlSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for CharBGColorControlClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of CharBGColorControlClass

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
CharBGColorControlSetColor	method dynamic	CharBGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_COLOR

	mov	ax, MSG_VIS_TEXT_SET_CHAR_BG_COLOR
	call	SendMeta_AX_DXCX_Common
	ret

CharBGColorControlSetColor	endm

;---

CharBGColorControlSetDrawMask	method dynamic	CharBGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_DRAW_MASK

	mov	ax, MSG_VIS_TEXT_SET_CHAR_BG_GRAY_SCREEN
	call	SendMeta_AX_CX_Common
	ret

CharBGColorControlSetDrawMask	endm

;---

CharBGColorControlSetPattern	method dynamic	CharBGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_PATTERN

	mov	ax, MSG_VIS_TEXT_SET_CHAR_BG_PATTERN
	call	SendMeta_AX_CX_Common
	ret

CharBGColorControlSetPattern	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharBGColorControlUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for CharBGColorControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of CharBGColorControlClass

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
CharBGColorControlUpdateUI	method dynamic CharBGColorControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	push	ds
	mov	dx, GWNT_TEXT_BG_COLOR_CHANGE
	call	GetColorNotifyCommon
	je	gotColor			;branch if got color
	;
	; Get text color from VisTextNotifyCharAttrChange
	;
	mov	al, ds:VTNCAC_charAttr.VTCA_bgGrayScreen
	movdw	dxcx, ds:VTNCAC_charAttr.VTCA_bgColor
	mov	bx, {word} ds:VTNCAC_charAttr.VTCA_bgPattern
	mov	di, ds:VTNCAC_charAttrDiffs.VTCAD_diffs
gotColor:
	call	UnlockNotifBlock
	pop	ds

	; convert BG flags to FG flags for common routine

	push	ax
	mov_tr	ax, di
	clr	di
	test	ax, mask VTCAF_MULTIPLE_BG_COLORS
	jz	10$
	mov	di, mask VTCAF_MULTIPLE_COLORS
10$:
	test	ax, mask VTCAF_MULTIPLE_BG_GRAY_SCREENS
	jz	20$
	ornf	di, mask VTCAF_MULTIPLE_GRAY_SCREENS
20$:
	test	ax, mask VTCAF_MULTIPLE_BG_PATTERNS
	jz	30$
	ornf	di, mask VTCAF_MULTIPLE_PATTERNS
30$:
	pop	ax

	; dxcx - color
	; al - SystemDrawMask
	; bx - GraphicPattern
	; di - VisTextCharAttrFlags
	;	VTCAF_MULTIPLE_COLORS
	;	VTCAF_MULTIPLE_GRAY_SCREENS
	;	VTCAF_MULTIPLE_PATTERNS

	call	UpdateColorCommon

	ret

CharBGColorControlUpdateUI	endm

TextControlCode ends

endif		; not NO_CONTROLLERS
