COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Color Library
FILE:		uiColor.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	ColorSelectorClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains routines to implement ColorSelectorClass

	$Id: uiColor.asm,v 1.2 98/04/24 00:39:55 gene Exp $

------------------------------------------------------------------------------@

;---------------------------------------------------

idata segment

	ColorSelectorClass		;declare the class record
	Color256SelectorClass		;declare the class record
	ColorSampleClass		;declare the class record
	ColorBarClass			;declare the class record
	ColorOtherDialogClass		;declare the class record
	CustomColorClass		;declare the class record
	ColorValueClass			;declare the class record

idata ends

;---------------------------------------------------

if not NO_CONTROLLERS

ColorSelectorCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorGetInfo --
		MSG_GEN_CONTROL_GET_INFO for ColorSelectorClass

DESCRIPTION:	Return group

PASS:
	*ds:si 	- instance data
	es 	- segment of ColorSelectorClass
	ax 	- The message
	cx:dx	- GenControlBuildInfo structure to fill in

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
	Tony	10/31/91	Initial version

------------------------------------------------------------------------------@
ColorSelectorGetInfo	method dynamic	ColorSelectorClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset CSC_dupInfo
	FALL_THRU	CopyBuildInfoCommon

ColorSelectorGetInfo	endm

CopyBuildInfoCommon	proc	far
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, size GenControlBuildInfo
	rep movsb
	ret
CopyBuildInfoCommon	endp

CSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
	0,				; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	0,				; GCBI_controllerName

	handle ColorSelectorUI,		; GCBI_dupBlock
	CSC_childList,			; GCBI_childList
	length CSC_childList,		; GCBI_childCount
	CSC_featuresList,		; GCBI_featuresList
	length CSC_featuresList,	; GCBI_featuresCount
	CS_DEFAULT_FEATURES,		; GCBI_features

	handle ColorSelectorToolboxUI,	; GCBI_toolBlock
	CSC_toolList,			; GCBI_toolList
	length CSC_toolList,		; GCBI_toolCount
	CSC_toolFeaturesList,		; GCBI_toolFeaturesList
	length CSC_toolFeaturesList,	; GCBI_toolFeaturesCount
	CS_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

CSC_childList	GenControlChildInfo	\
	<offset FilledBox, mask CSF_FILLED_LIST or mask CSF_DRAW_MASK, 0>,
	<offset ColorsList, mask CSF_INDEX, mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset ColorRGBGroup, mask CSF_RGB or mask CSF_OTHER, 0>,
	<offset PatternList, mask CSF_PATTERN, mask GCCF_IS_DIRECTLY_A_FEATURE>

CSC_toolList	GenControlChildInfo	\
	<offset ColorsToolboxList, mask CSTF_INDEX,
		   		mask GCCF_IS_DIRECTLY_A_FEATURE or \
				mask GCCF_NOTIFY_WHEN_ADDING>,
	<offset DrawMaskToolboxList, mask CSTF_DRAW_MASK,
		   		mask GCCF_IS_DIRECTLY_A_FEATURE or \
				mask GCCF_NOTIFY_WHEN_ADDING>,
	<offset PatternToolboxList, mask CSTF_PATTERN,
		   		mask GCCF_IS_DIRECTLY_A_FEATURE or \
				mask GCCF_NOTIFY_WHEN_ADDING>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to. Note that the "dummy" object ExpandedColorsList
; is at the end of the table and corresponds to a non-existent feature
; flag, so it will always be removed.

CSC_featuresList	GenControlFeaturesInfo	\
	<offset PatternList, offset PatternName, 0>,
	<offset DrawMaskRange, offset DrawMaskName, 0>,
	<offset RGBSpinners, offset ColorRGBName, 0>,
	<offset ColorsList, offset ColorListName, 0>,
	<offset FilledList, offset FilledName, 0>,
	<offset OtherColorTrigger, offset ColorOtherName, 0>

CSC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset PatternToolboxList, offset PatternName, 0>,
	<offset DrawMaskToolboxList, offset DrawMaskName, 0>,
	<offset ColorsToolboxList, offset ColorListName, 0>

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorGetColor -- MSG_COLOR_SELECTOR_GET_COLOR
						for ColorSelectorClass

DESCRIPTION:	Get the current color

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	ax - The message

RETURN:
	dxcx - ColorQuad
	bp - non-zero if indeterminate

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorGetColor	method dynamic	ColorSelectorClass,
					MSG_COLOR_SELECTOR_GET_COLOR

	mov	dx, ds:[di].CSI_color.low
	mov	cx, ds:[di].CSI_color.high
	; clr	ax
	; mov	al, ds:[di].CSI_colorIndeterminate
	; mov_tr	bp, ax

	; movdw	dxcx, ds:[di].CSI_color
	; clr	ax
	; mov	al, ds:[di].CSI_colorIndeterminate
	; mov_tr	bp, ax

	ret

ColorSelectorGetColor	endm

;---
ColorSelectorGetDrawMask	method dynamic	ColorSelectorClass,
					MSG_COLOR_SELECTOR_GET_DRAW_MASK
	mov	cl, ds:[di].CSI_drawMask
	clr	dx
	mov	dl, ds:[di].CSI_drawMaskIndeterminate
	ret

ColorSelectorGetDrawMask	endm

;---
ColorSelectorGetPattern	method dynamic	ColorSelectorClass,
					MSG_COLOR_SELECTOR_GET_PATTERN
	mov	cx, {word} ds:[di].CSI_pattern
	clr	dx
	mov	dl, ds:[di].CSI_patternIndeterminate
	ret

ColorSelectorGetPattern	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorSetColor -- MSG_COLOR_SELECTOR_SET_COLOR
						for ColorSelectorClass

DESCRIPTION:	Set the current color

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	ax - The message
	dxcx - ColorQuad
	bp - non-zero if indeterminate

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorUpdateColor	method dynamic	ColorSelectorClass,
				MSG_COLOR_SELECTOR_UPDATE_COLOR
	.enter

	call	GetToolBlockAndFeatures
	test	ax, mask CSTF_INDEX
	jz	setData
	push	cx, dx, si
	cmp	ch, CF_INDEX
	je	haveIndex

	xchgdw	bxax, dxcx
	clr	di
	call	GrMapColorRGB		;ah = index

	mov	cl, ah
	clr	ch
	mov	bx, dx
haveIndex:
	mov	dx, bp

	mov	si, offset ColorsToolboxList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	pop	cx, dx, si

setData:
	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	call	ObjCallInstanceNoLock

	.leave
	ret
ColorSelectorUpdateColor	endm

ColorSelectorSetColor	method dynamic	ColorSelectorClass,
			MSG_COLOR_SELECTOR_SET_COLOR

features	local	CSFeatures
indeterminate	local	word

	andnf	ds:[di].CSI_states, not mask CMS_COLOR_CHANGED
	movdw	ds:[di].CSI_color, dxcx
	mov	ax, bp
	or	al, ah
	mov	ds:[di].CSI_colorIndeterminate, al

	.enter

	mov	ss:indeterminate, ax
	call	GetChildBlockAndFeatures
	mov	ss:features, ax

	; if passed index then convert to RGB

	cmp	ch, CF_RGB
	jz	rgb

	; must convert index to rgb

	xchgdw	dxcx, bxax
	clr	di
	mov	ah, al			;ah = index
	call	GrMapColorIndex		;al <- red, bl <- green, bh <- blue
	xchgdw	dxcx, bxax
rgb:

	test	ss:features, mask CSF_RGB
	jz	afterRGB

	; cl = red, dl = green, dh = blue

	mov	al, cl
	mov	si, offset RedSpin
	call	setSpin

	mov	al, dl
	mov	si, offset GreenSpin
	call	setSpin

	mov	al, dh
	mov	si, offset BlueSpin
	call	setSpin

afterRGB:
	;
	; Update the Other color selector(s)
	;
	test	ss:features, mask CSF_OTHER
	jz	afterOther

	mov	al, cl
	mov	si, offset OtherRedSpin
	call	setSpin

	mov	al, dl
	mov	si, offset OtherGreenSpin
	call	setSpin

	mov	al, dh
	mov	si, offset OtherBlueSpin
	call	setSpin

	mov	si, offset OtherRedBar
	call	redrawGadget

	mov	si, offset OtherGreenBar
	call	redrawGadget

	mov	si, offset OtherBlueBar
	call	redrawGadget

	mov	si, offset OtherColorSample
	call	redrawGadget
afterOther:

	;
	; Update the RGB color sample
	;
	test	ss:features, mask CSF_RGB
	jz	afterRGBSample
	mov	si, offset RGBColorSample
	call	redrawGadget
afterRGBSample:

	; convert to an index

	push	bx
	movdw	bxax, dxcx
	clr	di
	call	GrMapColorRGB		;ah = index
	clr	cx
	mov	cl, ah			;cx = color
	pop	bx

	test	ss:features, mask CSF_INDEX
	jz	afterIndex
	mov	si, offset ColorsList
	clr	dx			;assume no indeterminates
	tst	ss:indeterminate
	jz	common
	dec	dx			;indeterminate, set flag
common:
	push	cx, bp
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage
	pop	cx, bp
afterIndex:

	;
	; Update the 256 color selector
	;
	test	ss:features, mask CSF_OTHER
	jz	after256

	mov	si, offset Other256List
	call	redrawGadget

after256:

done::
	.leave
	ret

	; al = color, bx:si = object, bp = locals

setSpin:
	clr	ah
	push	cx, dx, bp
	mov	bp, ss:indeterminate		;bp <- indeterminate flag
	mov	cx, ax				;cx <- color
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	di
	call	ObjMessage
	pop	cx, dx, bp
	retn

redrawGadget:
	push	cx, dx, bp
	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
	call	ObjMessage
	pop	cx, dx, bp
	retn

ColorSelectorSetColor	endm

;---

ColorSelectorUpdateDrawMask	method dynamic	ColorSelectorClass,
				MSG_COLOR_SELECTOR_UPDATE_DRAW_MASK

	.enter

	call	GetToolBlockAndFeatures
	test	ax, mask CSTF_DRAW_MASK
	jz	checkFilled

	push	si
	mov	si, offset DrawMaskToolboxList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

checkFilled:

	call	GetChildBlockAndFeatures
	test	ax, mask CSF_FILLED_LIST
	jz	setData

	mov_tr	bp, ax					;bp <- nonzero
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_FILLED_STATUS
	call	ObjCallInstanceNoLock

setData:
	mov	ax, MSG_COLOR_SELECTOR_SET_DRAW_MASK
	call	ObjCallInstanceNoLock

	.leave
	ret
ColorSelectorUpdateDrawMask	endm

ColorSelectorSetDrawMask	method dynamic	ColorSelectorClass,
				MSG_COLOR_SELECTOR_SET_DRAW_MASK

	andnf	ds:[di].CSI_states, not mask CMS_DRAW_MASK_CHANGED
	mov	ds:[di].CSI_drawMask, cl
	or	dl, dh
	mov	ds:[di].CSI_drawMaskIndeterminate, dl

	call	GetChildBlockAndFeatures
	test	ax, mask CSF_DRAW_MASK
	jz	done

	tst	dl
	pushf

	call	ConvertSysDrawMaskToMaskPercent

	clr	bp			;bp <- assume not indeterminate
	popf				;get indeterminate flag
	jz	notIndeterm
	dec	bp			;bp <- indeterminate
notIndeterm:
	mov	si, offset DrawMaskRange
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	clr	di
	call	ObjMessage

done:	ret

ColorSelectorSetDrawMask	endm

;---

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertSysDrawMaskToMaskPercent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Convert a SysDrawMask to a mask %

Pass:		cl - SystemDrawMask

Return:		dx.cx - mask % (WWFixed)

Destroyed:	nothing

Comments:

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Oct 28, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ConvertSysDrawMaskToMaskPercent	proc	near

	uses	ax
	.enter

	clr	ch
	neg	cx
	add	cx, SDM_100 + 64

	mov	ax, (100*256)/64
	mul	cx			;dx.ax = result/256
	mov	dh, dl
	mov	dl, ah
	mov	ch, al
	clr	cl			;dx:cx <- result

	.leave
	ret
ConvertSysDrawMaskToMaskPercent		endp

ColorSelectorUpdatePattern	method dynamic	ColorSelectorClass,
				MSG_COLOR_SELECTOR_UPDATE_PATTERN

	.enter

	call	GetToolBlockAndFeatures
	test	ax, mask CSTF_PATTERN
	jz	setData

	push	si
	mov	si, offset PatternToolboxList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

setData:
	mov	ax, MSG_COLOR_SELECTOR_SET_PATTERN
	call	ObjCallInstanceNoLock

	.leave
	ret
ColorSelectorUpdatePattern	endm

ColorSelectorSetPattern	method dynamic	ColorSelectorClass,
					MSG_COLOR_SELECTOR_SET_PATTERN

	andnf	ds:[di].CSI_states, not mask CMS_PATTERN_CHANGED
	mov	{word} ds:[di].CSI_pattern, cx
	or	dl, dh
	mov	ds:[di].CSI_patternIndeterminate, dl

	call	GetChildBlockAndFeatures
	test	ax, mask CSF_PATTERN
	jz	done

	mov	si, offset PatternList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	di
	call	ObjMessage
done:
	ret

ColorSelectorSetPattern	endm

;---

GetChildBlockAndFeatures	proc	far
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_features
	mov	bx, ds:[bx].TGCI_childBlock
	ret

GetChildBlockAndFeatures	endp

GetToolBlockAndFeatures	proc	far
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	mov	ax, ds:[bx].TGCI_toolboxFeatures
	mov	bx, ds:[bx].TGCI_toolBlock
	ret
GetToolBlockAndFeatures	endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorApplyColor -- MSG_COLOR_SELECTOR_APPLY_COLOR
						for ColorSelectorClass

DESCRIPTION:	Apply the passed Color

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	dxcx - ColorQuad

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 sep 1992	initial revision
------------------------------------------------------------------------------@
ColorSelectorApplyColor	method dynamic	ColorSelectorClass,
					MSG_COLOR_SELECTOR_APPLY_COLOR
	.enter

	mov	di, MSG_META_SUSPEND
	call	ColorSuspendUnsuspendCommon

	clrdw	bxdi
	mov	ax, MSG_META_COLORED_OBJECT_SET_COLOR
	call	GenControlSendToOutputRegs

	mov	di, MSG_META_UNSUSPEND
	call	ColorSuspendUnsuspendCommon

	.leave
	ret
ColorSelectorApplyColor	endm

ColorSuspendUnsuspendCommon	proc	near
dupInfo		local	GenControlBuildInfo
	uses	ax, cx, dx
	.enter

	mov	cx, ss
	lea	dx, ss:[dupInfo]
	push	bp
	mov	ax, MSG_GEN_CONTROL_GET_INFO
	call	ObjCallInstanceNoLock
	pop	bp
	test	ss:[dupInfo].GCBI_flags, mask GCBF_SUSPEND_ON_APPLY
	jz	done
	mov_tr	ax, di
	clrdw	bxdi				;no class (Meta message)
	call	GenControlSendToOutputRegs
done:
	.leave
	ret
ColorSuspendUnsuspendCommon	endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorApplyDrawMask -- MSG_COLOR_SELECTOR_APPLY_DRAW_MASK
						for ColorSelectorClass

DESCRIPTION:	Apply the passed SystemDrawMask

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	cl - SystemDrawMask

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 sep 1992	initial revision
------------------------------------------------------------------------------@
ColorSelectorApplyDrawMask	method dynamic	ColorSelectorClass,
					MSG_COLOR_SELECTOR_APPLY_DRAW_MASK
	.enter

	mov	di, MSG_META_SUSPEND
	call	ColorSuspendUnsuspendCommon

	clrdw	bxdi
	mov	ax, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	call	GenControlSendToOutputRegs

	mov	di, MSG_META_UNSUSPEND
	call	ColorSuspendUnsuspendCommon

	.leave
	ret
ColorSelectorApplyDrawMask	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorApplyPattern -- MSG_COLOR_SELECTOR_APPLY_PATTERN
						for ColorSelectorClass

DESCRIPTION:	Apply the passed SystemPattern

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	cx - GraphicPattern

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	7 sep 1992	initial revision
------------------------------------------------------------------------------@
ColorSelectorApplyPattern	method dynamic	ColorSelectorClass,
					MSG_COLOR_SELECTOR_APPLY_PATTERN
	.enter

	mov	di, MSG_META_SUSPEND
	call	ColorSuspendUnsuspendCommon

	clrdw	bxdi
	mov	ax, MSG_META_COLORED_OBJECT_SET_PATTERN
	call	GenControlSendToOutputRegs

	mov	di, MSG_META_UNSUSPEND
	call	ColorSuspendUnsuspendCommon

	.leave
	ret
ColorSelectorApplyPattern	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorSetColorIndex -- MSG_CS_SET_CF_INDEX
						for ColorSelectorClass

DESCRIPTION:	Handle user change to color index list

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	ax - The message

	cx - color index
	dl - GenItemGroupStateFlags
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
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorSetColorIndex	method dynamic	ColorSelectorClass,
						MSG_CS_SET_CF_INDEX
	tst	bp
	jz	done

	mov	ch, CF_INDEX
	clr	dx
	clr	bp
	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	call	ObjCallInstanceNoLock
	call	MarkColorChangedAndSetApplyable
done:
	ret

ColorSelectorSetColorIndex	endm

;---

;---
MarkColorChangedAndSetApplyable	proc	near
	class	ColorSelectorClass

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].CSI_states, mask CMS_COLOR_CHANGED
	FALL_THRU	SetApplyable
MarkColorChangedAndSetApplyable	endp

;---

SetApplyable	proc	near
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	call	ObjCallInstanceNoLock

	;
	; Make the 'Other' dialog applyable, too, if it exists
	;
	push	si
	call	GetChildBlockAndFeatures
	test	ax, mask CSF_OTHER
	jz	noOther
	mov	si, offset OtherColor
	mov	ax, MSG_GEN_MAKE_APPLYABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
noOther:
	pop	si

	;
	; Now see if we're in delayed mode.
	;
	mov	cx, GUQT_DELAYED_OPERATION
	mov	ax, MSG_GEN_GUP_QUERY
	call	ObjCallInstanceNoLock
	jnc	done			; not answered
	tst	ax
	jnz	done			; delayed
	;
	; Operating in immediate mode, so send ourselves an apply.
	;
	mov	ax, MSG_GEN_APPLY
	call	ObjCallInstanceNoLock
done:
	ret

SetApplyable	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorSetFilledStatus --
		MSG_CS_SET_FILLED_STATUS for ColorSelectorClass

DESCRIPTION:	Handle user change to color index list

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	cl - SysDrawMask

RETURN:
	nothing

DESTROYED:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 oct 92	initial revision
------------------------------------------------------------------------------@
ColorSelectorSetFilledStatus	method dynamic	ColorSelectorClass,
			MSG_CS_SET_FILLED_STATUS
	uses	ax, cx, dx, bp
	.enter

	;
	;  Enable or disable our UI
	;

	clr	dx, bp
	mov	ax, MSG_COLOR_SELECTOR_UPDATE_FILLED_STATUS
	call	ObjCallInstanceNoLock

	;
	;  If there's a draw mask range, set its value and dirty it
	;

	clr	ch
	cmp	cl, SDM_0
	je	haveValue
	mov	cl, SDM_100

haveValue:
	call	ConvertSysDrawMaskToMaskPercent
	call	GetChildBlockAndFeatures
	test	ax, mask CSF_DRAW_MASK
	jz	doItOutselves

	push	si
	clr	bp
	mov	ax, MSG_GEN_VALUE_SET_VALUE
	mov	si, offset DrawMaskRange
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

doItOutselves:
	;
	;  OK, there's no range, so we have to set this crap ourselves
	;	dx.cx = mask %
	;

	mov	ax, MSG_CS_SET_DRAW_MASK
	call	ObjCallInstanceNoLock
	.leave
	ret
ColorSelectorSetFilledStatus	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorSetFilledStatus --
		MSG_COLOR_SELECTOR_UPDATE_FILLED_STATUS

DESCRIPTION:	Handle user change to color index list

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	cl - SystemDrawMask
	dx - nonzero if indeterminate
	bp - nonzero to update toolbox stuff as well

RETURN:
	nothing

DESTROYED:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	28 oct 92	initial revision
------------------------------------------------------------------------------@
ColorSelectorUpdateFilledStatus	method dynamic	ColorSelectorClass,
			MSG_COLOR_SELECTOR_UPDATE_FILLED_STATUS
	uses	ax, cx, dx, bp
	.enter

	push	bp				;save update toolbox flag

	clr	ch
	call	GetChildBlockAndFeatures
	test	ax, mask CSF_FILLED_LIST
	jz	convertMask

	;
	;  Set the Do Draw/Don't Draw list to proper status
	;
	push	si
	cmp	cl, SDM_0
	je	haveMask
	mov	cl, SDM_100
haveMask:
	mov	si, offset FilledList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

convertMask:
	mov	bp, MSG_GEN_SET_ENABLED
	tst	dx
	mov	dl, VUM_NOW
	jnz	disable
	cmp	cx, SDM_0
	jne	checkDisableObject
disable:
	mov	bp, MSG_GEN_SET_NOT_ENABLED

checkDisableObject:
	mov	ax, ATTR_COLOR_SELECTOR_DISABLE_OBJECT
	call	ObjVarFindData
	jnc	getToolBlock

	push	si
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	xchg	ax, bp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	xchg	ax, bp
	pop	si

getToolBlock:
	call	GetToolBlockAndFeatures
	push	bx, ax

	call	GetChildBlockAndFeatures

	test	ax, mask CSF_INDEX
	jz	afterIndex

	xchg	ax, bp
	mov	si, offset ColorsList
	clr	di
	call	ObjMessage
	xchg	ax, bp

afterIndex:
	test	ax, mask CSF_RGB
	jz	afterRGB

	xchg	ax, bp
	mov	si, offset ColorRGBGroup
	clr	di
	call	ObjMessage
	mov	si, offset RGBColorSample
	call	ObjMessage
	xchg	ax, bp

afterRGB:
	test	ax, mask CSF_DRAW_MASK
	jz	afterMask

	xchg	ax, bp
	mov	si, offset DrawMaskRange
	clr	di
	call	ObjMessage
	xchg	ax, bp

afterMask:
	test	ax, mask CSF_PATTERN
	jz	afterPattern

	xchg	ax, bp
	mov	si, offset PatternList
	clr	di
	call	ObjMessage
	xchg	ax, bp

afterPattern:
	pop	bx, ax					;tool block, features
	pop	di					;bp <- update tool flag
	tst	di
	jz	done

	test	ax, mask CSTF_INDEX
	jz	afterToolboxIndex

	xchg	ax, bp
	mov	si, offset ColorsToolboxList
	clr	di
	call	ObjMessage
	xchg	ax, bp

afterToolboxIndex:

	test	ax, mask CSTF_PATTERN
	jz	done

	xchg	ax, bp
	mov	si, offset PatternToolboxList
	clr	di
	call	ObjMessage

done:
	.leave
	ret
ColorSelectorUpdateFilledStatus	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorSetDM -- MSG_CS_SET_DRAW_MASK
						for ColorSelectorClass

DESCRIPTION:	Handle user setting of the draw mask

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	ax - The message

	dx.cx - draw mask % (WWFixed)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorSetDM	method dynamic	ColorSelectorClass,
			MSG_CS_SET_DRAW_MASK

	uses	cx, dx
	.enter

	clr	ds:[di].CSI_drawMaskIndeterminate
	ornf	ds:[di].CSI_states, mask CMS_DRAW_MASK_CHANGED

	; cx = 0 to 100, convert to SystemDrawMask which is 0 to 64

	; dm = (value/100)*64 = value*(64/100)

	mov	dh, dl
	mov	dl, ch			;dh.dl <- draw mask %

	mov	ax, (64*256)/100
	mul	dx			;dx.ax = result, use dl.ah
	adddw	dxax, 0x8000		;round
	mov	cx, dx			;cx <- result

	; cx = 0 to 64, get SDM_100 - (cx-64) = (SDM_100+64) - cx

	neg	cx
	add	cx, SDM_100 + 64

	mov	ds:[di].CSI_drawMask, cl
	call	SetApplyable

	.leave
	ret
ColorSelectorSetDM	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorSetH -- MSG_CS_SET_PATTERN for ColorSelectorClass

DESCRIPTION:	Handle user setting of the hatch

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	ax - The message

	dx - hatch
	bp low - ListEntryState
	bh high - ListUpdateFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorSetH	method dynamic	ColorSelectorClass, MSG_CS_SET_PATTERN

	mov	{word} ds:[di].CSI_pattern, cx
	clr	ds:[di].CSI_patternIndeterminate
	ornf	ds:[di].CSI_states, mask CMS_PATTERN_CHANGED
	call	SetApplyable
	ret

ColorSelectorSetH	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorSetColorRGBRed -- MSG_CS_SET_CF_RGB_RED
						for ColorSelectorClass

DESCRIPTION:	Handle user change to red/green/blue spins

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

	ax - The message

	dx.cx - spin value
	bp - GenValueStateFlags

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorSetColorRGBRed	method dynamic	ColorSelectorClass,
						MSG_CS_SET_CF_RGB_RED,
						MSG_CS_SET_CF_RGB_GREEN,
						MSG_CS_SET_CF_RGB_BLUE

	test	bp, mask GVSF_OUT_OF_DATE	;value out of date, don't set,
	jnz	markChanged			;  just mark modified.

	mov	cx, dx				;cx <- spin value
	mov_tr	bp, ax				;bp = message


	movdw	bxax, ds:[di].CSI_color
	cmp	ah, CF_RGB
	jz	rgb

	; must convert index to rgb

	clr	di
	mov	ah, al			;ah = index
	call	GrMapColorIndex		;al <- red, bl <- green, bh <- blue
rgb:

	mov	ah, CF_RGB

	cmp	bp, MSG_CS_SET_CF_RGB_RED
	jnz	notRed
	mov	al, cl
	jmp	common
notRed:
	cmp	bp, MSG_CS_SET_CF_RGB_GREEN
	jnz	notGreen
	mov	bl, cl
	jmp	common
notGreen:
	mov	bh, cl
common:
	movdw	dxcx, bxax
	clr	bp
	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	call	ObjCallInstanceNoLock

markChanged:
	call	MarkColorChangedAndSetApplyable
	ret

ColorSelectorSetColorRGBRed	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorApply -- MSG_GEN_APPLY for ColorSelectorClass

DESCRIPTION:	Handle APPLY for the color slector

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass

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
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorApply	method dynamic	ColorSelectorClass, MSG_GEN_APPLY
	;
	; Call superclass first, so that GenValues can get up-to-date if they
	; need to.
	;
	mov	di, offset ColorSelectorClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].ColorSelector_offset
	clr	bx
	xchg	bl, ds:[di].CSI_states

	push	{word} ds:[di].CSI_pattern

	clr	cx
	mov	cl, ds:[di].CSI_drawMask
	push	cx

	test	bl, mask CMS_COLOR_CHANGED
	jz	noColor
	movdw	dxcx, ds:[di].CSI_color
	mov	ax, MSG_META_COLORED_OBJECT_SET_COLOR
	call	sendToOutput
noColor:

	pop	cx				;cx = draw mask
	test	bl, mask CMS_DRAW_MASK_CHANGED
	jz	noDrawMask
	mov	ax, MSG_META_COLORED_OBJECT_SET_DRAW_MASK
	call	sendToOutput
noDrawMask:

	pop	cx				;cx = hatch
	test	bl, mask CMS_PATTERN_CHANGED
	jz	noPattern
	mov	ax, MSG_META_COLORED_OBJECT_SET_PATTERN
	call	sendToOutput
noPattern:

	ret

;---

sendToOutput:
	push	bx
	clrdw	bxdi
	call	GenControlSendToOutputRegs
	pop	bx
	retn

ColorSelectorApply	endm

ColorSelectorCode ends

ColorSelectorGenerateCode	segment resource


COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
						for ColorSelectorClass

DESCRIPTION:	This message is subclassed to set the monikers of
		the filled/unfilled items

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass
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
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorGenerateUI		method dynamic	ColorSelectorClass,
				MSG_GEN_CONTROL_GENERATE_UI
	.enter

	;
	;  Call the superclass
	;
	mov	di, offset ColorSelectorClass
	call	ObjCallSuperNoLock

if 0
	;
	; Set the selection in the mode list
	;
	call	GetChildBlockAndFeatures
	test	ax, mask CSF_OTHER
	jz	afterOther
	push	bp
	push	si
PrintMessage <future: have .INI key to set default selector type>
	mov	cx, CST_256
	clr	dx
	mov	si, offset OtherModeList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	cx
	call	ObjMessage
	pop	cx
	pop	si					;*ds:si <- us
	mov	ax, MSG_CS_SET_SELECTOR_TYPE
	call	ObjCallInstanceNoLock
	pop	bp
afterOther:
endif

	call	GetChildBlockAndFeatures
	;
	; If we have the 'Other' feature, get the saved colors
	;
	test	ax, mask CSF_OTHER
	jz	afterOther
	push	ax, si
	mov	ax, MSG_CUSTOM_COLOR_READ_SAVED_COLORS
	mov	si, offset OtherCustomGroup
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, si
afterOther:

	;
	;  If the do draw/don't draw feature isn't set, then we have no worries
	;
	test	ax, mask CSF_FILLED_LIST
	jz	done

	;
	;  Get the name of the Do Draw item
	;
	push	si
	mov	ax, MSG_COLOR_SELECTOR_GET_FILLED_MONIKER
	call	ObjCallInstanceNoLock
	jcxz	dontDraw

	;
	;  Get the Item
	;
	pushdw	cxdx					;save optr
	mov	cx, SDM_100
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	mov	si, offset FilledList
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	movdw	bxsi, cxdx				;^lbx:si <- item
	popdw	cxdx					;^lcx:dx <- VisMoniker
	jnc	dontDraw

	;
	;  Set the name
	;

	mov	bp, VUM_NOW
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

dontDraw:
	pop	si
	mov	ax, MSG_COLOR_SELECTOR_GET_UNFILLED_MONIKER
	call	ObjCallInstanceNoLock
	jcxz	done

	;
	;  Get the Item
	;
	pushdw	cxdx					;save moniker
	mov	cx, SDM_0
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	mov	si, offset FilledList
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	movdw	bxsi, cxdx				;^lbx:si <- item
	popdw	cxdx					;^lcx:dx <- VisMoniker
	jnc	done

	;
	;  Set the name
	;

	mov	bp, VUM_NOW
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

done:
	.leave
	ret
ColorSelectorGenerateUI	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorTweakDuplicatedUI --
		MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI for ColorSelectorClass

DESCRIPTION:	Display enhanced color selection list, depending upon
		features.

PASS:
	*ds:si 	- instance data
	es 	- segment of ColorSelectorClass
	ax 	- The message
	cx	- duplicated block handle
	dx	- CSFeatures

RETURN:
	cx:dx - list of children

DESTROYED:
	bx, si, di, ds, es (message handler)

------------------------------------------------------------------------------@

ColorSelectorTweakDuplicatedUI	method dynamic	ColorSelectorClass,
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
		.enter

	;
	; if we're in a modal dialog and we have the other color sub-dialog,
	; make it modal, too.
	;
		test	dx, mask CSF_OTHER
		jz	notModal
		push	cx, dx, bp
		mov	cx, ds:LMBH_handle
		mov	dx, si				;^lcx:dx <- our OD
		call	FindEnclosingDialog
		jnc	notModalPop			;branch if no dialog
		movdw	bxsi, cxdx			;^lbx:si <- dialog OD
		mov	ax, MSG_GEN_INTERACTION_GET_ATTRS
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
		test	cl, mask GIA_MODAL
		pop	cx, dx, bp
		jz	notModal
		push	cx, dx, bp
		mov	si, offset OtherColor
		mov	bx, cx
		mov	ax, MSG_GEN_INTERACTION_SET_ATTRS
		mov	cx, mask GIA_MODAL		;cl <- set, ch <- clear
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
notModalPop:
		pop	cx, dx, bp
notModal:
	;
	; see if we have the other color sub-dialog but not RGB
	;
		test	dx, mask CSF_OTHER
		jz	notIndexOnly
		test	dx, mask CSF_RGB
		jnz	notIndexOnly
	;
	; indexed colors only -- remove the RGB specific stuff
	; gives 16 color and 256 color lists only
	;
		mov	bx, cx
		mov	si, offset OtherRGBGroup
		call	setNotUsable
		mov	si, offset OtherModeList
		call	setNotUsable
		mov	si, offset OtherCustomGroup
		call	setNotUsable

notIndexOnly:

		.leave
		ret

setNotUsable:
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		retn
ColorSelectorTweakDuplicatedUI	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorTweakDuplicatedToolboxUI --
		MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI for
			ColorSelectorClass

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass
	ax - The message
	cx - duplicated block handle
	dx - features mask

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
	Tony	3/23/92		Initial version
	Don	4/11/99		Changed from GENERATE_TOOLBOX_UI to
				TWEAK_DUPLICATED_TOOLBOX_UI, so that
				dynamic bubble help vardata would be
				copied into the SPUI objects.

------------------------------------------------------------------------------@
ColorSelectorTweakDuplicatedToolboxUI	method dynamic	ColorSelectorClass,
				MSG_GEN_CONTROL_TWEAK_DUPLICATED_TOOLBOX_UI
	.enter

	;
	; Some set-up work
	;
	mov	bx, cx				;bx <- duplicated object block
	mov	bp, dx				;bp <- features
	clr	dx				;assume not a pop-up list
	mov	cl, ds:[di].CSI_toolboxPrefs
	test	cl, mask CTP_IS_POPUP
	jz	colorMonikers
	dec	dx				;dx <- 0xffff

	;
	; Work on the color index list
	;
colorMonikers:
	test	bp, mask CSTF_INDEX
	jz	maskMonikers
	push	cx, bp				;save prefs, features

	mov	di, offset areaColorMonikerList
	mov	ax, offset AreaColorMoniker
	mov	bp, offset AreaColorListHelp
	andnf	cl, mask CTP_INDEX_ORIENTATION
CheckHack <COO_AREA_ORIENTED eq 0>
	jz	haveIndexList

	mov	di, offset lineColorMonikerList
	mov	ax, offset LineColorMoniker
	mov	bp, offset LineColorListHelp
	cmp	cl, COO_LINE_ORIENTED shl offset CTP_INDEX_ORIENTATION
	je	haveIndexList

	mov	di, offset textColorMonikerList
	mov	ax, offset TextColorMoniker
	mov	bp, offset TextColorListHelp

haveIndexList:
CheckHack <(length lineColorMonikerList) eq (length areaColorMonikerList)>
CheckHack <(length textColorMonikerList) eq (length areaColorMonikerList)>
	mov	cx, length areaColorMonikerList
	mov	si, offset ColorsToolboxList
	and	ax, dx				;ax <- offset or 0
	call	ColorItemGroupReplaceMonikers
	pop	cx, bp				;cl <- prefs; bp <- features

	;
	; Now work on the draw mask list
	;
maskMonikers:
	test	bp, mask CSTF_DRAW_MASK
	jz	patternMonikers

	push	cx, bp				;save prefs, features
	mov	di, offset areaDrawMaskMonikerList
	mov	ax, offset AreaMaskMoniker
	mov	bp, offset AreaDrawMaskListHelp
	andnf	cl, mask CTP_DRAW_MASK_ORIENTATION
CheckHack <COO_AREA_ORIENTED eq 0>
	jz	haveDrawMaskList

	mov	di, offset lineDrawMaskMonikerList
	mov	ax, offset LineMaskMoniker
	mov	bp, offset LineDrawMaskListHelp
	cmp	cl, COO_LINE_ORIENTED shl offset CTP_DRAW_MASK_ORIENTATION
	je	haveDrawMaskList

	mov	di, offset textDrawMaskMonikerList
	mov	ax, offset TextMaskMoniker
	mov	bp, offset TextDrawMaskListHelp

haveDrawMaskList:
CheckHack <(length lineDrawMaskMonikerList) eq (length areaDrawMaskMonikerList)>
CheckHack <(length textDrawMaskMonikerList) eq (length areaDrawMaskMonikerList)>
	mov	cx, length areaDrawMaskMonikerList
	mov	si, offset DrawMaskToolboxList
	and	ax, dx				;ax <- offset or 0
	call	ColorItemGroupReplaceMonikers
	pop	cx, bp				;cl <- prefs; bp <- features

	;
	; Finally, work on the pattern list
	;
patternMonikers:
	test	bp, mask CSTF_PATTERN
	jz	done

	mov	di, offset areaPatternMonikerList
	mov	ax, offset AreaPatternMoniker
	mov	bp, offset AreaPatternListHelp
	andnf	cl, mask CTP_PATTERN_ORIENTATION
CheckHack <COO_AREA_ORIENTED eq 0>
	jz	havePatternList

	mov	di, offset textPatternMonikerList
	mov	ax, offset TextPatternMoniker
	mov	bp, offset TextPatternListHelp

havePatternList:
CheckHack <(length textPatternMonikerList) eq (length areaPatternMonikerList)>
	mov	cx, length areaPatternMonikerList
	mov	si, offset PatternToolboxList
	and	ax, dx					;ax <- offset or 0
	call	ColorItemGroupReplaceMonikers
done:
	.leave
	ret
ColorSelectorTweakDuplicatedToolboxUI	endm






COMMENT @----------------------------------------------------------------------

METHOD:		ColorSelectorNotifyAddingFeature --
		MSG_GEN_CONTROL_NOTIFY_ADDING_FEATURE for ColorSelectorClass

DESCRIPTION:	We're adding a feature.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_CONTROL_NOTIFY_ADDING_FEATURE

		^lcx:dx - feature

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/26/93         	Initial Version

------------------------------------------------------------------------------@

ColorSelectorNotifyAddingFeature	method dynamic	ColorSelectorClass, \
				MSG_GEN_CONTROL_NOTIFY_ADDING_FEATURE

	test	ds:[di].CSI_toolboxPrefs, mask CTP_IS_POPUP
	jz	exit

	movdw	bxsi, cxdx
	mov	ax, MSG_GEN_ADD_GEOMETRY_HINT
	mov	cx, HINT_ITEM_GROUP_MINIMIZE_SIZE
	mov	dl, VUM_MANUAL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
exit:
	ret
ColorSelectorNotifyAddingFeature	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ColorItemGroupReplaceMonikers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Replaces a GenItemGroup's GenItems' monikers according
		to the passed IdentifierAndMoniker list

Pass:		^lbx:si - GenItemGroup to replace Items' monikers
		cs:di - IdentifierAndMoniker list
		cx - length of list in cs:di
		ax - chunk handle of VisMoniker to use for the item group
			(within ColorMonikers block) (zero for none)
		bp - chunk handle of quick-help string to use for the
			pop-up list (within ControlStrings)

Return:		nothing

Destroyed:	nothing

Comments:

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Nov  9, 1992 	Initial version.
	Don	3/14/99		Added quick-help

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ColorItemGroupReplaceMonikers	proc	near
	uses	ax, cx, dx, bp, di
	.enter

	;
	; First we'll set the moniker for the item group. We assume
	; that the moniker for the list and the quick-help data
	; go together, so we don't both checking for these values
	; independently
	;
	tst	ax
	jz	top

	push	cx, di
	push	bp
	mov	bp, VUM_MANUAL
	mov	cx, handle ColorMonikers
	mov_tr	dx, ax
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax				; help string chunk => ax

	;
	; OK - set the focus help text
	;
	mov	dx, (size AddVarDataParams) + (size optr)
	sub	sp, dx
	mov	bp, sp
	mov	di, bp
	add	di, size AddVarDataParams
	mov	ss:[bp].AVDP_data.segment, ss
	mov	ss:[bp].AVDP_data.offset, di
	mov	ss:[bp].AVDP_dataSize, size optr
	mov	ss:[bp].AVDP_dataType, ATTR_GEN_FOCUS_HELP
	mov	ss:[di].handle, handle ControlStrings
	mov	ss:[di].chunk, ax
	mov	ax, MSG_META_ADD_VAR_DATA
	mov	di, mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, (size AddVarDataParams) + (size optr)
	pop	cx, di

	;
	; Now set all of the monikers for the list entries
	;
top:
	push	cx				;save index
	mov	bp, cx				;bp <- index
	dec	bp
CheckHack <size IdentifierAndMoniker eq (2 * size word)>
	shl	bp
	shl	bp				;bp <- offset into table
	mov	cx, cs:[di][bp].IAM_identifier
	push	di, bp
	mov	ax, MSG_GEN_ITEM_GROUP_GET_ITEM_OPTR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	di, bp
	jnc	next

	pushdw	bxsi				;save GenItemGroup
	movdw	bxsi, cxdx
	mov	cx, handle ColorMonikers
	mov	dx, cs:[di][bp].IAM_moniker
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	push	di				;save table
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di				;di <- table
	popdw	bxsi				;^lbx:si <- GenItemGroup

next:
	pop	cx				;cx <- index
	loop	top

	.leave
	ret
ColorItemGroupReplaceMonikers	endp

IdentifierAndMoniker	struct
	IAM_identifier	word
	IAM_moniker	lptr
IdentifierAndMoniker	ends

if 0		; unused 12/1/92 -- ardeb
itemGroupMonikers	IdentifierAndMoniker \
	<offset areaColorMonikerList, AreaColorMoniker>,
	<offset lineColorMonikerList, LineColorMoniker>,
	<offset textColorMonikerList, TextColorMoniker>,
	<offset areaDrawMaskMonikerList, AreaColorMoniker>,
	<offset lineDrawMaskMonikerList, LineColorMoniker>,
	<offset textDrawMaskMonikerList, TextColorMoniker>,
	<offset areaPatternMonikerList, AreaColorMoniker>,
	<offset textPatternMonikerList, TextColorMoniker>
endif

areaColorMonikerList	IdentifierAndMoniker	\
	<C_BLACK, AreaBlackMoniker>,
	<C_BLUE, AreaDarkBlueMoniker>,
	<C_GREEN, AreaDarkGreenMoniker>,
	<C_CYAN, AreaDarkCyanMoniker>,
	<C_RED, AreaDarkRedMoniker>,
	<C_VIOLET, AreaDarkVioletMoniker>,
	<C_BROWN, AreaBrownMoniker>,
	<C_LIGHT_GRAY, AreaLightGrayMoniker>,
	<C_DARK_GRAY, AreaDarkGrayMoniker>,
	<C_LIGHT_BLUE, AreaLightBlueMoniker>,
	<C_LIGHT_GREEN, AreaLightGreenMoniker>,
	<C_LIGHT_CYAN, AreaLightCyanMoniker>,
	<C_LIGHT_RED, AreaLightRedMoniker>,
	<C_LIGHT_VIOLET, AreaLightVioletMoniker>,
	<C_YELLOW, AreaYellowMoniker>,
	<C_WHITE, AreaWhiteMoniker>

lineColorMonikerList	IdentifierAndMoniker	\
	<C_BLACK, LineBlackMoniker>,
	<C_BLUE, LineDarkBlueMoniker>,
	<C_GREEN, LineDarkGreenMoniker>,
	<C_CYAN, LineDarkCyanMoniker>,
	<C_RED, LineDarkRedMoniker>,
	<C_VIOLET, LineDarkVioletMoniker>,
	<C_BROWN, LineBrownMoniker>,
	<C_LIGHT_GRAY, LineLightGrayMoniker>,
	<C_DARK_GRAY, LineDarkGrayMoniker>,
	<C_LIGHT_BLUE, LineLightBlueMoniker>,
	<C_LIGHT_GREEN, LineLightGreenMoniker>,
	<C_LIGHT_CYAN, LineLightCyanMoniker>,
	<C_LIGHT_RED, LineLightRedMoniker>,
	<C_LIGHT_VIOLET, LineLightVioletMoniker>,
	<C_YELLOW, LineYellowMoniker>,
	<C_WHITE, LineWhiteMoniker>

textColorMonikerList	IdentifierAndMoniker	\
	<C_BLACK, TextBlackMoniker>,
	<C_BLUE, TextDarkBlueMoniker>,
	<C_GREEN, TextDarkGreenMoniker>,
	<C_CYAN, TextDarkCyanMoniker>,
	<C_RED, TextDarkRedMoniker>,
	<C_VIOLET, TextDarkVioletMoniker>,
	<C_BROWN, TextBrownMoniker>,
	<C_LIGHT_GRAY, TextLightGrayMoniker>,
	<C_DARK_GRAY, TextDarkGrayMoniker>,
	<C_LIGHT_BLUE, TextLightBlueMoniker>,
	<C_LIGHT_GREEN, TextLightGreenMoniker>,
	<C_LIGHT_CYAN, TextLightCyanMoniker>,
	<C_LIGHT_RED, TextLightRedMoniker>,
	<C_LIGHT_VIOLET, TextLightVioletMoniker>,
	<C_YELLOW, TextYellowMoniker>,
	<C_WHITE, TextWhiteMoniker>

areaDrawMaskMonikerList	IdentifierAndMoniker	\
	<SDM_100, AreaMask100Moniker>,
	<SDM_87_5, AreaMask875Moniker>,
	<SDM_75, AreaMask75Moniker>,
	<SDM_62_5, AreaMask625Moniker>,
	<SDM_50, AreaMask50Moniker>,
	<SDM_37_5, AreaMask375Moniker>,
	<SDM_25, AreaMask25Moniker>,
	<SDM_12_5, AreaMask125Moniker>,
	<SDM_0, AreaMask0Moniker>

lineDrawMaskMonikerList	IdentifierAndMoniker	\
	<SDM_100, LineMask100Moniker>,
	<SDM_87_5, LineMask875Moniker>,
	<SDM_75, LineMask75Moniker>,
	<SDM_62_5, LineMask625Moniker>,
	<SDM_50, LineMask50Moniker>,
	<SDM_37_5, LineMask375Moniker>,
	<SDM_25, LineMask25Moniker>,
	<SDM_12_5, LineMask125Moniker>,
	<SDM_0, LineMask0Moniker>

textDrawMaskMonikerList	IdentifierAndMoniker	\
	<SDM_100, TextMask100Moniker>,
	<SDM_87_5, TextMask875Moniker>,
	<SDM_75, TextMask75Moniker>,
	<SDM_62_5, TextMask625Moniker>,
	<SDM_50, TextMask50Moniker>,
	<SDM_37_5, TextMask375Moniker>,
	<SDM_25, TextMask25Moniker>,
	<SDM_12_5, TextMask125Moniker>,
	<SDM_0, TextMask0Moniker>

areaPatternMonikerList	IdentifierAndMoniker	\
	<PT_SOLID, AreaPatternSolidMoniker>,
	<(SH_VERTICAL shl 8) or PT_SYSTEM_HATCH, AreaPatternVerticalMoniker>,
	<(SH_HORIZONTAL shl 8) or PT_SYSTEM_HATCH, AreaPatternHorizontalMoniker>,
	<(SH_45_DEGREE shl 8) or PT_SYSTEM_HATCH, AreaPatternDegree45Moniker>,
	<(SH_135_DEGREE shl 8) or PT_SYSTEM_HATCH, AreaPatternDegree135Moniker>,
	<(SH_BRICK shl 8) or PT_SYSTEM_HATCH, AreaPatternBrickMoniker>,
	<(SH_SLANTED_BRICK shl 8) or PT_SYSTEM_HATCH, AreaPatternSlantedBrickMoniker>

textPatternMonikerList	IdentifierAndMoniker	\
	<PT_SOLID, TextPatternSolidMoniker>,
	<(SH_VERTICAL shl 8) or PT_SYSTEM_HATCH, TextPatternVerticalMoniker>,
	<(SH_HORIZONTAL shl 8) or PT_SYSTEM_HATCH, TextPatternHorizontalMoniker>,
	<(SH_45_DEGREE shl 8) or PT_SYSTEM_HATCH, TextPatternDegree45Moniker>,
	<(SH_135_DEGREE shl 8) or PT_SYSTEM_HATCH, TextPatternDegree135Moniker>,
	<(SH_BRICK shl 8) or PT_SYSTEM_HATCH, TextPatternBrickMoniker>,
	<(SH_SLANTED_BRICK shl 8) or PT_SYSTEM_HATCH, TextPatternSlantedBrickMoniker>



COMMENT @----------------------------------------------------------------------

MESSAGE:	ColorSelectorGetFilledName --
		MSG_COLOR_SELECTOR_GET_DO_DRAW_NAME for ColorSelectorClass

DESCRIPTION:	This message is subclassed to set the monikers of
		the do draw/don't draw items

PASS:
	*ds:si - instance data
	es - segment of ColorSelectorClass
	ax - The message

RETURN:
	carry clear to use default text

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/23/92		Initial version

------------------------------------------------------------------------------@
ColorSelectorUseDefaultName	method dynamic	ColorSelectorClass,
				MSG_COLOR_SELECTOR_GET_FILLED_MONIKER,
				MSG_COLOR_SELECTOR_GET_UNFILLED_MONIKER
	.enter

	clr	cx		;use default moniker

	.leave
	ret
ColorSelectorUseDefaultName	endm

ColorSelectorGenerateCode	ends

endif			; if (not NO_CONTROLLERS) and (not _JEDI) +++++++++++

