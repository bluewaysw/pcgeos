COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text
FILE:		rulerMouse.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/92		Initial version

DESCRIPTION:
	This file contains code to implement mouse interaction
	for TextRulerClass

	$Id: rulerMouse.asm,v 1.1 97/04/07 11:19:42 newdeal Exp $

------------------------------------------------------------------------------@

; For hit testing between left and para margins

RULER_LEFT_PARA_Y = VIS_RULER_HEIGHT + 6

RULER_DRAG_SLOP		=	2

; For hit testing of markers

LM_SLOP_LEFT		=	1*8
LM_SLOP_RIGHT		=	6*8
PM_SLOP_LEFT		=	1*8
PM_SLOP_RIGHT		=	6*8
RM_SLOP_LEFT		=	8*8
RM_SLOP_RIGHT		=	1*8

TAB_SLOP_LEFT		=	3*8
TAB_SLOP_RIGHT		=	3*8

;---

RulerCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerLargePtr -- MSG_META_LARGE_PTR for TextRulerClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass

	ax - The message

	ss:bp - LargeMouseData

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 7/92		Initial version

------------------------------------------------------------------------------@
TextRulerLargePtr	method dynamic	TextRulerClass,	MSG_META_LARGE_PTR

	; Redirect to VisRuler if needed and convert the coordinates
	; to ruler relative if not

	mov	bl, ds:[di].TRI_flags
	test	bl, mask TRF_OBJECT_SELECTED
	jz	sendToSuper
	test	bl, mask TRF_DRAGGING
	jz	sendToSuper
	tst	ds:[di].TRI_valid
	jz	sendToSuper

	call	HandlePtr
	ret

sendToSuper:
	FALL_THRU	TR_SendToSuper

TextRulerLargePtr	endm

;---

TR_SendToSuper	proc	far
	mov	di, segment TextRulerClass
	mov	es, di
	mov	di, offset TextRulerClass
	GOTO	ObjCallSuperNoLock
TR_SendToSuper	endp

RulerCommon ends

;---

RulerCode segment resource

HandlePtr	proc	far

	; adjust position to be text object relative

	call	ObjectCoordToRulerCoord		;ax = coord

	call	IfMarginThenTweakCoord

	; update pointer

	call	UpdatePointer
	mov	ax, mask MRF_PROCESSED
	ret

HandlePtr	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerLargeStartSelect -- MSG_META_LARGE_START_SELECT
							for TextRulerClass

DESCRIPTION:	Handle a large mouse event

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass

	ax - The message

	ss:bp - LargeMouseData

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 7/92		Initial version

------------------------------------------------------------------------------@
TextRulerLargeStartSelect	method dynamic	TextRulerClass,
						MSG_META_LARGE_START_SELECT

	; Redirect to VisRuler if needed and convert the coordinates
	; to ruler relative if not

	tst	ds:[di].TRI_valid
	jz	seendToSuper
	cmp	ss:[bp].LMD_location.PDF_y.DWF_int.low, VIS_RULER_HEIGHT
	jg	10$
seendToSuper:
	call	TR_SendToSuper
	ret
10$:

	; adjust position to be text object relative

	call	ObjectCoordToRulerCoord		;ax = position

	; Figure out what we're on top of

	call	WhichMarginOrTab		;bx = offset in ruler structure
	tst	bx
	LONG jz	setTab

	; we're on something, so grab the mouse

	call	GrabFocusAndMouse

	or	ds:[di].TRI_flags, mask TRF_OBJECT_SELECTED or \
							mask TRF_SELECTING

	; both left and para margins selected ?

	cmp	bx, -1
	jnz	afterBoth
	test	ds:[di].TRI_flags, mask TRF_ALWAYS_MOVE_BOTH_MARGINS
	jnz	afterBoth
	test	ss:[bp].LMD_uiFunctionsActive,
		    mask UIFA_ADJUST or mask UIFA_EXTEND or mask UIFA_CONSTRAIN
	jnz	afterBoth
	mov	bx, offset VTPA_leftMargin	;assume left margin
	cmp	ss:[bp].LMD_location.PDF_y.DWF_int.low,
						RULER_LEFT_PARA_Y
	jg	afterBoth
	mov	bx, offset VTPA_paraMargin
afterBoth:

	mov	ds:[di].TRI_selectedObject, bx
	mov	ds:[di].TRI_selectX, ax
	mov	ds:[di].TRI_action, TRA_NULL

	; if a tab is selected then set the selected tab variable

	cmp	bx, size VisTextParaAttr
	jl	done
	mov	cx, ({Tab} ds:[di][bx].TRI_paraAttr).T_position
	mov	ax, MSG_VIS_TEXT_SET_SELECTED_TAB
	call	SendToTargetTextRegs

	test	ss:[bp].LMD_buttonInfo, mask BI_DOUBLE_PRESS
	jz	done

	; on a double click open the tab attributes dialog box

	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_TAB_DOUBLE_CLICK
	mov	di, mask MF_RECORD
	call	ObjMessage
	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type,
				GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE
	clr	ss:[bp].GCNLMP_block
	clr	ss:[bp].GCNLMP_flags
	mov	dx, size GCNListMessageParams
	mov	ax, MSG_META_GCN_LIST_SEND
	mov	di, mask MF_STACK
	clr	bx
	call	GeodeGetAppObject
	call	ObjMessage
	add	sp, size GCNListMessageParams

done:
	mov	ax, mask MRF_PROCESSED
	ret

setTab:

	; set a tab at the position requested

	tst	ax				;if negative position then bail
	js	done

	call	RoundCoordinate
	
	; check for negative, this isn't allowed
	
	tst	ax
	js	done				;quit now if negative

	sub	sp, size VisTextSetTabParams
	mov	bp, sp
	mov	ss:[bp].VTSTP_tab.T_position, ax
	mov	ss:[bp].VTSTP_tab.T_attr, TabAttributes <TL_NONE, TT_LEFT>
	mov	ss:[bp].VTSTP_tab.T_grayScreen, SDM_100
	mov	ss:[bp].VTSTP_tab.T_lineWidth, 0
	mov	ss:[bp].VTSTP_tab.T_lineSpacing, 1*8
	call	LocalGetNumericFormat
	mov	ss:[bp].VTSTP_tab.T_anchor, cx
	mov	ax, MSG_VIS_TEXT_SET_TAB
	mov	dx, size VisTextSetTabParams
	call	SendToTargetTextStack
	add	sp, size VisTextSetTabParams

	jmp	done

TextRulerLargeStartSelect	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerLargeDragSelect -- MSG_META_LARGE_DRAG_SELECT
						for TextRulerClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass

	ax - The message

	ss:bp - LargeMouseData

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 7/92		Initial version

------------------------------------------------------------------------------@
TextRulerLargeDragSelect	method dynamic	TextRulerClass,
						MSG_META_LARGE_DRAG_SELECT

	; Redirect to VisRuler if needed and convert the coordinates
	; to ruler relative if not

	mov	bl, ds:[di].TRI_flags
	test	bl, mask TRF_OBJECT_SELECTED
	jz	sendToSuper
	test	bl, mask TRF_DRAGGING
	jnz	sendToSuper
	tst	ds:[di].TRI_valid
	jz	sendToSuper

	or	bl, mask TRF_DRAGGING
	mov	ds:[di].TRI_flags, bl

	; adjust position to be text object relative

	call	ObjectCoordToRulerCoord			;ax = x position

	; if a tab is selcted then see if we're moving or copying the tab

	mov	bl, TRA_MOVE_MARGIN
	cmp	ds:[di].TRI_selectedObject, size VisTextParaAttr
	jl	notTab

	test	ss:[bp].LMD_uiFunctionsActive,
					mask UIFA_ADJUST or mask UIFA_EXTEND
	mov	bl, TRA_MOVE_TAB
	jz	notTab
	mov	bl, TRA_COPY_TAB
notTab:
	mov	ds:[di].TRI_action, bl

	; update pointer

	call	UpdatePointer
	mov	ax, mask MRF_PROCESSED
	ret

sendToSuper:
	call	TR_SendToSuper
	ret

TextRulerLargeDragSelect	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	IfMarginThenTweakCoord

DESCRIPTION:	I fa margin is selected then keep the coordinate in bounds in x

CALLED BY:	INTERNAL

PASS:
	ax - ruler coordinate
	ds:di - instance data

RETURN:
	ax - ruler coordinate

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/10/92		Initial version

------------------------------------------------------------------------------@
IfMarginThenTweakCoord	proc	near
	class	TextRulerClass

	cmp	ds:[di].TRI_action, TRA_MOVE_MARGIN
	jnz	done

	tst	ax
	jns	10$
	clr	ax
10$:

	cmp	ax, ds:[di].TRI_regionWidth	;if past region width then
	jbe	20$
	mov	ax, ds:[di].TRI_regionWidth	;use region width
20$:

done:
	ret

IfMarginThenTweakCoord	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerLargeEndSelect -- MSG_META_LARGE_END_SELECT
						for TextRulerClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass

	ax - The message

	ss:bp - LargeMouseData

RETURN:
	ax - MouseReturnFlags

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 7/92		Initial version

------------------------------------------------------------------------------@
TextRulerLargeEndSelect	method dynamic	TextRulerClass,	MSG_META_LARGE_END_SELECT

	; Redirect to VisRuler if needed and convert the coordinates
	; to ruler relative if not

	mov	bl, ds:[di].TRI_flags
	test	bl, mask TRF_OBJECT_SELECTED
	jz	sendToSuper
	test	bl, mask TRF_SELECTING
	jz	sendToSuper
	tst	ds:[di].TRI_valid
	jnz	5$
sendToSuper:
	call	TR_SendToSuper
	ret
5$:

	push	{word} ds:[di].TRI_flags
	push	bp
	mov	ax, MSG_VIS_LOST_GADGET_EXCL
	call	ObjCallInstanceNoLock
	pop	bp
	pop	cx
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	test	cl, mask TRF_DRAGGING
	LONG jz	quit

	; adjust position to be text object relative

	call	ObjectCoordToRulerCoord		;ax = coord
	call	IfMarginThenTweakCoord

	; act based on the current action

	call	RoundCoordinate

	mov	ch, 1				;assume in bounds
	call	TestInBounds
	jc	afterBoundsCheck
	clr	ch
afterBoundsCheck:

	mov_tr	dx, ax				;dx = x pos
	mov	ah, ch				;ah = in-bounds flag

	mov	al, ds:[di].TRI_action
	mov	bx, ds:[di].TRI_selectedObject

	; al = action, ah = in bounds flag, bx = selected object

	; if we are doing anything but creating a tab then make sure that we
	; moved at least a few pixels

	tst	ah
	jz	noCheck
	sub	cx, ds:[di].TRI_selectX
	jns	20$
	neg	cx				;cx = absolute value
20$:
	cmp	cx, RULER_DRAG_SLOP
	LONG jbe quit

noCheck:

	cmp	al, TRA_MOVE_MARGIN
	jnz	notMargin

	tst	ah
	jz	toQuit

	mov	ax, MSG_VIS_TEXT_SET_LEFT_AND_PARA_MARGIN
	cmp	bx, -1
	jz	marginCommon
	mov	ax, MSG_VIS_TEXT_SET_LEFT_MARGIN
	cmp	bx, offset VTPA_leftMargin
	jz	marginCommon
	mov	ax, MSG_VIS_TEXT_SET_PARA_MARGIN
	cmp	bx, offset VTPA_paraMargin
	jz	marginCommon
	mov	ax, MSG_VIS_TEXT_SET_RIGHT_MARGIN
	sub	dx, ds:[di].TRI_regionWidth
	neg	dx

	; move a margin -- ax = message, bp = position

marginCommon:
	tst	dx
	jns	marginNotNegative
	clr	dx
marginNotNegative:
	sub	sp, size VisTextSetMarginParams
	mov	bp, sp
	mov	ss:[bp].VTSMP_position, dx
	mov	dx, size VisTextSetMarginParams
	call	SendToTargetTextStack
	add	sp, size VisTextSetMarginParams
toQuit:
	jmp	quit

notMargin:

	; store newly selected tab

	cmp	al, TRA_MOVE_TAB
	jnz	notMoveTab

	; move a tab

	tst	ah
	jz	removeTab

	sub	sp, size VisTextMoveTabParams
	mov	bp, sp

	mov	ss:[bp].VTMTP_destPosition, dx
	mov	ax, ({Tab} ds:[di][bx].TRI_paraAttr).T_position
	mov	ss:[bp].VTMTP_sourcePosition, ax

	mov	dx, VisTextMoveTabParams
	mov	ax, MSG_VIS_TEXT_MOVE_TAB
	call	SendToTargetTextStack
	add	sp, size VisTextMoveTabParams
	jmp	quit

	; remove a tab

removeTab:
	sub	sp, size VisTextClearTabParams
	mov	bp, sp
	mov	ax, ({Tab} ds:[di][bx].TRI_paraAttr).T_position
	mov	ss:[bp].VTCTP_position, ax
	mov	ax, MSG_VIS_TEXT_CLEAR_TAB
	mov	dx, VisTextClearTabParams
	call	SendToTargetTextStack
	add	sp, size VisTextClearTabParams
	jmp	quit

	; copy a tab

notMoveTab:
	tst	ah
	jz	quit

	sub	sp, size VisTextSetTabParams
	mov	bp, sp
	mov	ss:[bp].VTSTP_tab.T_position, dx
	mov	ax, {word} ({Tab} ds:[di][bx].TRI_paraAttr).T_attr
	mov	{word} ss:[bp].VTSTP_tab.T_attr, ax
	mov	ax, {word} ({Tab} ds:[di][bx].TRI_paraAttr).T_lineWidth
	mov	{word} ss:[bp].VTSTP_tab.T_lineWidth, ax
	mov	ax, ({Tab} ds:[di][bx].TRI_paraAttr).T_anchor
	mov	ss:[bp].VTSTP_tab.T_anchor, ax
	mov	ax, MSG_VIS_TEXT_SET_TAB
	mov	dx, size VisTextSetTabParams
	call	SendToTargetTextStack
	add	sp, size VisTextSetTabParams

quit:
	mov	ax, mask MRF_PROCESSED
	ret

TextRulerLargeEndSelect	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerLostGadgetExcl -- MSG_VIS_LOST_GADGET_EXCL
						for TextRulerClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass

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
	Tony	4/ 7/92		Initial version

------------------------------------------------------------------------------@
TextRulerLostGadgetExcl	method dynamic	TextRulerClass, MSG_VIS_LOST_GADGET_EXCL

	andnf	ds:[di].TRI_flags, not (mask TRF_OBJECT_SELECTED or \
				mask TRF_SELECTING or mask TRF_DRAGGING)

	call	VisReleaseMouse
	mov	di, ds:[si]
	add	di, ds:[di].VisRuler_offset
	clr	cx
	clr	dx
	mov	di, ds:[di].VRI_window
	mov	bp, PIL_GADGET
	call	WinSetPtrImage
	ret

TextRulerLostGadgetExcl	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdatePointer

DESCRIPTION:	Update the pointer shape based on the action and flags

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisRulerTop object
	ax - x position

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	if (dragging) {
	    case (action) {
		MOVE_MARGIN {
		    left margin { pic = left margin pic }
		    para margin { pic = para margin pic }
		    right margin { pic = right margin pic }
		}
		MOVE_TAB {
		    if (pointin bounds) {
			pic = tab pic
		    } else {
			pic = standard pic
		    }
		}
	    }
	} else {
	    pic = standard pic
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
UpdatePointer	proc	near	uses ax, bx, cx, dx, bp, es
	class	TextRulerClass
	.enter

        mov     di, ds:[si]
	add     di, ds:[di].Vis_offset
	test	ds:[di].TRI_flags, mask TRF_DRAGGING
	jz	standard

	call	TestInBounds
	jnc	outside

	mov	bx, ds:[di].TRI_selectedObject
	mov	al, ds:[di].TRI_action
	cmp	al, TRA_MOVE_MARGIN
	jnz	notMargin

	mov	dx, offset LeftParaMarginCursor
	cmp	bx, -1
	jz	special
	mov	dx, offset LeftMarginCursor
	cmp	bx, offset VTPA_leftMargin
	jz	special
	mov	dx, offset ParaMarginCursor
	cmp	bx, offset VTPA_paraMargin
	jz	special
	mov	dx, offset RightMarginCursor
	jmp	special
notMargin:

	mov	ah, ({Tab} ds:[di][bx].TRI_paraAttr.VTMPA_paraAttr).T_attr
	and	ah, mask TA_TYPE

	mov	dx, offset LeftTabCursor
	cmp	ah, TT_LEFT
	jz	special
	mov	dx, offset CenterTabCursor
	cmp	ah, TT_CENTER
	jz	special
	mov	dx, offset RightTabCursor
	cmp	ah, TT_RIGHT
	jz	special
	mov	dx, offset AnchoredTabCursor

	; special pointer -- lock resource if needed

special:
	mov	cx, handle LeftTabCursor

	; ^hcx:dx = cursor picture

	jmp	common

	; outside the bounds -- if moving a tab then use "delete tab" cursor

outside:
	mov	dx, offset DeleteTabCursor
	cmp	ds:[di].TRI_action, TRA_MOVE_TAB
	jz	special

	; standard pointer -- unlock the resource if needed

standard:
	clr	cx
	clr	dx

common:
	push	di
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	di, ds:[di].VRI_window	; get window to make change on
	tst	di
	jz	afterPtrImageSet
	mov	bp, PIL_GADGET
	call	WinSetPtrImage
afterPtrImageSet:
	pop	di

	.leave
	ret

UpdatePointer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TestInBounds

DESCRIPTION:	See if a point is in the bounds of the ruler

CALLED BY:	INTERNAL

PASS:
	*ds:si - ruler
	ax - x position
	ss:bp.LMD_location.PDF_y - y position

RETURN:
	carry - set if in bounds

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 8/92		Initial version

------------------------------------------------------------------------------@
TestInBounds	proc	near	uses dx, di
	class	TextRulerClass
	.enter

	tst	ax
	js	outside
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	cmp	ax, ds:[di].TRI_regionWidth
	jg	outside

	movdw	dxdi, ss:[bp].LMD_location.PDF_y.DWF_int
	jgedw	dxdi, TEXT_RULER_HEIGHT, outside
	tst	dx
	stc
	jns	done
outside:
	clc
done:
	.leave
	ret
TestInBounds	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	GrabFocusAndMouse

DESCRIPTION:	Grab the focus and mouse

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

RETURN:
	none

DESTROYED:
	noen

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 7/92		Initial version

------------------------------------------------------------------------------@
GrabFocusAndMouse	proc	near	uses	ax, cx, dx, bp
	.enter

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent
	call	VisGrabLargeMouse
	call	MetaGrabFocusExclLow

	.leave
	ret

GrabFocusAndMouse	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	WhichMarginOrTab

DESCRIPTION:	Determine which tab or margin (if any) the cursor is over

CALLED BY:	INTERNAL

PASS:
	*ds:si - object
	ax - position

RETURN:
	bx - offset in ruler structure of item found (0 if none, -1 if both
		left and para margins)

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
WhichMarginOrTab	proc	near	uses	ax, cx, dx, di, bp
	class	TextRulerClass
	.enter

	mov_tr	bp, ax

        mov     di, ds:[si]
	add     di, ds:[di].Vis_offset
	add	di, offset TRI_paraAttr

	mov	dx, (LM_SLOP_LEFT shl 8) or LM_SLOP_RIGHT
	mov	ax, ds:[di].VTPA_leftMargin
	call	CompareCoords
	pushf

	mov	dx, (PM_SLOP_LEFT shl 8) or PM_SLOP_RIGHT
	mov	ax, ds:[di].VTPA_paraMargin
	call	CompareCoords
	jc	onParaMargin

	; not on para margin -- if on left margin then exit

	popf
	jc	returnLeft
	jmp	afterLeftPara

	; on para margin -- on left also ?

onParaMargin:
	popf
	mov	bx, offset VTPA_paraMargin
	jnc	doneGood			;no -- return para

	; on both left and para margins -- return -1

	mov	bx, -1
doneGood:
	stc
	jmp	done

returnLeft:
	mov	bx, offset VTPA_leftMargin
	stc
	jmp	done

afterLeftPara:
	mov	dx, (RM_SLOP_LEFT shl 8) or RM_SLOP_RIGHT
	mov	ax, ds:[di].VTPA_rightMargin
	call	CompareCoords
	mov	bx, offset VTPA_rightMargin
	jc	done

	clr	cx
	mov	cl, ds:[di].VTPA_numberOfTabs
	jcxz	miss
	mov	bx, size VisTextParaAttr
	mov	dx, (TAB_SLOP_LEFT shl 8) or TAB_SLOP_RIGHT
aloop:
	mov	ax, ds:[di][bx]
	call	CompareCoords
	jc	done
	add	bx, size Tab
	loop	aloop

miss:
	clr	bx
done:
	.leave
	ret

WhichMarginOrTab	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CompareCoords

DESCRIPTION:	Compare x coordinates for a hit

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisRulerTop object
	ax - ruler coordinate
	dh - slop on left
	dl - slop on right
	bp - mouse coordinate

RETURN:
	carry set if hit

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
CompareCoords	proc	near	uses ax
	class	TextRulerClass
	.enter

	sub	ax, bp

	; ax = (marker pos) - (mouse pos)

	jb	right

	; the mouse is to the LEFT of the marker

	tst	ah
	jnz	miss
	cmp	al, dh
	ja	miss
hit:
	stc
	jmp	common

	; the mouse is to the RIGHT of the marker

right:
	neg	ax
	tst	ah
	jnz	miss
	cmp	al, dl
	jbe	hit
miss:
	clc
common:
	.leave
	ret

CompareCoords	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendToTargetTextRegs, SendToTargetTextStack

DESCRIPTION:	Send a message to the target text object

CALLED BY:	INTERNAL

PASS:
	*ds:si - ruler
	ax - message
	cx, dx, bp - data

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 8/92		Initial version

------------------------------------------------------------------------------@
SendToTargetTextRegs	proc	near
	push	di
	mov	di, mask MF_RECORD
	GOTO	SendToCommon, di

SendToTargetTextRegs	endp

;---

SendToTargetTextStack	proc	near
	push	di
	mov	di, mask MF_RECORD or mask MF_STACK
	GOTO	SendToCommon, di

SendToTargetTextStack	endp

;---

SendToCommon	proc	near	uses ax, bx, cx, dx, bp
	class	TextRulerClass
	.enter

	mov	ss:[bp].VTR_start.high, VIS_TEXT_RANGE_SELECTION

	; record the message

	push	si
	mov	bx, segment VisTextClass
	mov	si, offset VisTextClass
	call	ObjMessage
	pop	si
	mov	cx, di				;cx = message
	mov	dx, TO_TARGET
	mov	ax, MSG_META_SEND_CLASSED_EVENT

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].TRI_gcnContent.handle
	tst	bx
	jz	noContentGiven
	mov	si, ds:[di].TRI_gcnContent.chunk
sendCommon:
	clr	di
	call	ObjMessage
	pop	si
	jmp	done

noContentGiven:
	tst	ds:[di].TRI_gcnContent.chunk
	jz	sendToParent

	; send to the app

	clr	bx
	call	GeodeGetAppObject
	jmp	sendCommon

sendToParent:
	mov	bx, segment VisContentClass
	mov	si, offset VisContentClass
	mov	di, mask MF_RECORD
	call	ObjMessage			;di = message
	mov	cx, di
	pop	si

	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent

done:
	.leave
	FALL_THRU_POP	di
	ret

SendToCommon	endp

RulerCode ends
