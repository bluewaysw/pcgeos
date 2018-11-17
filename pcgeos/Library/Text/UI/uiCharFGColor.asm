COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiCharFGColorControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	CharFGColorControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement CharFGColorControlClass

	$Id: uiCharFGColor.asm,v 1.1 97/04/07 11:17:27 newdeal Exp $

-------------------------------------------------------------------------------@

GC_Data	union
    GCD_dword	dword
    GCD_optr	optr
GC_Data	end

GC_NewField	struct
    GCNF_offset	byte
    GCNF_size	byte
    GCNF_data	GC_Data
GC_NewField	ends

;---------------------------------------------------

TextClassStructures	segment	resource

	CharFGColorControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharFGColorControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for CharFGColorControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of CharFGColorControlClass

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
CharFGColorControlGetInfo	method dynamic	CharFGColorControlClass,
					MSG_GEN_CONTROL_GET_INFO

	; first call our superclass to get the color selector's stuff

	pushdw	cxdx
	mov	di, offset CharFGColorControlClass
	call	ObjCallSuperNoLock

	; now fill in a few things

	popdw	esdi
	mov	si, offset CFGCC_newFields
	mov	cx, length CFGCC_newFields
	call	CopyFieldsToBuildInfo

	ret

CharFGColorControlGetInfo	endm

CFGCC_newFields	GC_NewField	\
	<offset GCBI_flags, size GCBI_flags,
				<GCD_dword mask GCBF_SUSPEND_ON_APPLY>>,
	<offset GCBI_initFileKey, size GCBI_initFileKey,
				<GCD_dword CFGCC_IniFileKey>>,
	<offset GCBI_gcnList, size GCBI_gcnList,
				<GCD_dword CFGCC_gcnList>>,
	<offset GCBI_gcnCount, size GCBI_gcnCount,
				<GCD_dword length CFGCC_gcnList>>,
	<offset GCBI_notificationList, size GCBI_notificationList,
				<GCD_dword CFGCC_notifyList>>,
	<offset GCBI_notificationCount, size GCBI_notificationCount,
				<GCD_dword size CFGCC_notifyList>>,
	<offset GCBI_controllerName, size GCBI_controllerName,
				<GCD_optr CFGCCName>>,
	<offset GCBI_features, size GCBI_features,
				<GCD_dword CFGCC_DEFAULT_FEATURES>>,
	<offset GCBI_toolFeatures, size GCBI_toolFeatures,
				<GCD_dword CFGCC_DEFAULT_TOOLBOX_FEATURES>>,
	<offset GCBI_helpContext, size GCBI_helpContext,
				<GCD_dword CFGCC_helpContext>>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

CFGCC_helpContext	char	"dbCharClr", 0


CFGCC_IniFileKey	char	"charFGColor", 0

CFGCC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_FG_COLOR_CHANGE>

CFGCC_notifyList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_FG_COLOR_CHANGE>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyFieldsToBuildInfo

DESCRIPTION:	Copy fields from a table of GC_NewField structures to
		a GenControlBuildInfo structure

CALLED BY:	INTERNAL

PASS:
	esdi - GenControlBuildInfo structure
	cs:si - table of GC_NewField structures
	cx - table length

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
CopyFieldsToBuildInfo	proc	near

	segmov	ds, cs				;ds:si = source

copyLoop:
	push	cx, si, di
	clr	ax
	lodsb				;ax = offset
	add	di, ax
	clr	ax
	lodsb
	mov_tr	cx, ax			;cx = count
	rep movsb

	pop	cx, si, di
	add	si, size GC_NewField
	loop	copyLoop

	ret

CopyFieldsToBuildInfo	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharFGColorControlOutputAction -- MSG_GEN_OUTPUT_ACTION
					for CharFGColorControlClass

DESCRIPTION:	Intercept ColorSelector output that we want

PASS:
	*ds:si - instance data
	es - segment of CharFGColorControlClass

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
CharFGColorControlOutputAction	method dynamic	CharFGColorControlClass,
						MSG_GEN_OUTPUT_ACTION

	mov	di, offset CharFGColorControlClass
	FALL_THRU	ColorInterceptAction

CharFGColorControlOutputAction	endm

;---

ColorInterceptAction	proc	far
	push	cx, si
	mov	bx, bp
	call	ObjGetMessageInfo			;ax = message
	pop	cx, si

	cmp	ax, MSG_META_COLORED_OBJECT_SET_COLOR
	jz	handleOurself
	cmp	ax, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	jz	handleOurself
	cmp	ax, MSG_META_COLORED_OBJECT_SET_PATTERN
	jz	handleOurself

	mov	ax, MSG_GEN_OUTPUT_ACTION
	GOTO	ObjCallSuperNoLock

handleOurself:

	; dispatch the event to ourself

	mov	cx, ds:[LMBH_handle]		;cx:si = dest
	call	MessageSetDestination
	clr	di				;no flags
	call	MessageDispatch
	ret

ColorInterceptAction	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharFGColorControlSetColor -- MSG_META_COLORED_OBJECT_SET_COLOR
						for CharFGColorControlClass

DESCRIPTION:	Handle a color change

PASS:
	*ds:si - instance data
	es - segment of CharFGColorControlClass

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
CharFGColorControlSetColor	method dynamic	CharFGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_COLOR

	mov	ax, MSG_VIS_TEXT_SET_COLOR
	call	SendMeta_AX_DXCX_Common
	ret

CharFGColorControlSetColor	endm

;---

CharFGColorControlSetDrawMask	method dynamic	CharFGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_DRAW_MASK

	mov	ax, MSG_VIS_TEXT_SET_GRAY_SCREEN
	call	SendMeta_AX_CX_Common
	ret

CharFGColorControlSetDrawMask	endm

;---

CharFGColorControlSetPattern	method dynamic	CharFGColorControlClass,
						MSG_META_COLORED_OBJECT_SET_PATTERN

	mov	ax, MSG_VIS_TEXT_SET_PATTERN
	call	SendMeta_AX_CX_Common
	ret

CharFGColorControlSetPattern	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	CharFGColorControlUpdateUI --
		MSG_GEN_CONTROL_UPDATE_UI for CharFGColorControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of CharFGColorControlClass

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
CharFGColorControlUpdateUI	method dynamic CharFGColorControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	push	ds
	mov	dx, GWNT_TEXT_FG_COLOR_CHANGE
	call	GetColorNotifyCommon
	je	gotColor			;branch if got color
	;
	; Get text color from VisTextNotifyCharAttrChange
	;
	mov	al, ds:VTNCAC_charAttr.VTCA_grayScreen
	movdw	dxcx, ds:VTNCAC_charAttr.VTCA_color
	mov	bx, {word} ds:VTNCAC_charAttr.VTCA_pattern
	mov	di, ds:VTNCAC_charAttrDiffs.VTCAD_diffs
gotColor:
	call	UnlockNotifBlock
	pop	ds

	; dxcx - color
	; al - SystemDrawMask
	; bx - GraphicPattern
	; di - VisTextCharAttrFlags
	;	VTCAF_MULTIPLE_COLORS
	;	VTCAF_MULTIPLE_GRAY_SCREENS
	;	VTCAF_MULTIPLE_PATTERNS

	call	UpdateColorCommon

	ret

CharFGColorControlUpdateUI	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateColorCommon

DESCRIPTION:	Common code to update a color selector

CALLED BY:	INTERNAL

PASS:
	*ds:si - controller
	ss:bp - GenControlUpdateUIParams
	dxcx - color
	al - SystemDrawMask
	bx - GraphicPattern
	di - VisTextCharAttrFlags
		VTCAF_MULTIPLE_COLORS
		VTCAF_MULTIPLE_GRAY_SCREENS
		VTCAF_MULTIPLE_PATTERNS

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/24/92		Initial version

------------------------------------------------------------------------------@
UpdateColorCommon	proc	near	uses bp
	.enter

	push	bx				;save hatch
	push	ax				;save draw mask

	; update color

	mov	bp, di
	and	bp, mask VTCAF_MULTIPLE_COLORS	;bp = indeterm
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_COLOR
	call	ObjCallInstanceNoLock

	; update draw mask

	pop	cx
	mov	dx, di
	and	dx, mask VTCAF_MULTIPLE_GRAY_SCREENS
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_DRAW_MASK
	call	ObjCallInstanceNoLock

	; update hatch

	pop	cx
	mov	dx, di
	and	dx, mask VTCAF_MULTIPLE_PATTERNS
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_PATTERN
	call	ObjCallInstanceNoLock

	.leave
	ret

UpdateColorCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetColorNotifyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to get notification data for color
CALLED BY:	CharFGColorControlUpdateUI(), CharBGColorControlUpdateUI()

PASS:		ss:bp - GenControlUpdateUIParams
	    		GCUUIP_manufacturer         ManufacturerID
	    		GCUUIP_changeType           word
	    		GCUUIP_dataBlock            hptr
			
	    		GCUUIP_toolInteraction      optr
	    		GCUUIP_features             word 
	    		GCUUIP_toolboxFeatures      word
	    		GCUUIP_childBlock           hptr

		dx - GeoWorksNotificationType to match
		NOTE: this notification type must use NotifyColorChange

RETURN: 	ds - seg addr of notification block

		z flag - set if common color notification:
		di - VisTextCharAttrFlags
		    VTCAF_MULTIPLE_COLORS
		    VTCAF_MULTIPLE_GRAY_SCREENS
		    	-or-
		    VTCAF_MULTIPLE_BG_COLORS
		    VTCAF_MULTIPLE_BG_GRAY_SCREENS
		    	-or-
		    VTPAF_MULTIPLE_BG_COLORS
		    VTPAF_MULTIPLE_BG_GRAY_SCREENS
		    	-or-
		    VTPABF_MULTIPLE_BORDER_COLORS
		    VTPABF_MULTIPLE_BORDER_GRAY_SCREENS
		ax - SystemDrawMask
		dxcx - color
		bx - GraphicPattern

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetColorNotifyCommon	proc	near
	.enter

	;
	; Get notification data and figure out what type it is
	;
	mov	bx, ss:[bp].GCUUIP_dataBlock	;bx <- notification block
	call	MemLock
	mov	ds, ax
	clr	ax
	cmp	ss:[bp].GCUUIP_changeType, dx	;common type?
	jne	done				;branch if not
	;
	; Get color from NotifyColorChange (common structure)
	;
	mov	al, ds:NCC_grayScreen
	movdw	dxcx, ds:NCC_color
	mov	bx, {word} ds:NCC_pattern
	mov	di, ds:NCC_flags
done:

	.leave
	ret

GetColorNotifyCommon	endp

;---

UnlockNotifBlock	proc	near	uses bx
	.enter

	mov	bx, ss:[bp].GCUUIP_dataBlock	;bx <- notification block
	call	MemUnlock

	.leave
	ret

UnlockNotifBlock	endp

TextControlCode ends

endif		; not NO_CONTROLLERS
