COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text
FILE:		rulerClass.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/92		Initial version

DESCRIPTION:
	This file contains code to implement TextRulerClass

	$Id: rulerClass.asm,v 1.1 97/04/07 11:19:46 newdeal Exp $

------------------------------------------------------------------------------@

TextClassStructures	segment resource

	TextRulerClass

TextClassStructures	ends

;---

RulerCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerVisOpen -- MSG_VIS_OPEN for TextRulerClass

DESCRIPTION:	Catch VIS-OPEN and add ourself to the appropriate
		notification list

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass (not dgroup)

	ax - The message

	bp - data

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
	Tony	4/ 6/92		Initial version

------------------------------------------------------------------------------@
TextRulerVisOpen	method dynamic	TextRulerClass, MSG_VIS_OPEN

	mov	di, MSG_META_GCN_LIST_ADD
	GOTO	OpenCloseCommon

TextRulerVisOpen	endm

;---

TextRulerVisClose	method dynamic	TextRulerClass, MSG_VIS_CLOSE

	mov	di, MSG_META_GCN_LIST_REMOVE
	FALL_THRU	OpenCloseCommon

TextRulerVisClose	endm

;---

OpenCloseCommon	proc	far
	class	TextRulerClass

	push	di					;save message
	mov	di, offset TextRulerClass
	call	ObjCallSuperNoLock
	pop	ax				;ax = message

	sub	sp, size GCNListParams		; create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_TEXT_RULER_OBJECTS
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	dx, size GCNListParams		; create stack frame

	; add ourself to the list of controlled text rulers

	push	si
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_STACK
	call	ObjMessage
	pop	si

	; If we have a content specified then attach to its GCN lists

	mov	ss:[bp].GCNLP_ID.GCNLT_type,
				VCGCNLT_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	bx, ds:[di].TRI_gcnContent.handle
	tst	bx
	jz	noContentGiven
	mov	si, ds:[di].TRI_gcnContent.chunk
	mov	di, mask MF_STACK
	call	ObjMessage
	jmp	done

noContentGiven:
	tst	ds:[di].TRI_gcnContent.chunk
	jz	sendToParent

	; send to the app

	mov	ss:[bp].GCNLP_ID.GCNLT_type,
				GAGCNLT_APP_TARGET_NOTIFY_TEXT_PARA_ATTR_CHANGE
	clr	bx
	call	GeodeGetAppObject
	mov	di, mask MF_STACK
	call	ObjMessage
	jmp	done

sendToParent:
	push	si
	mov	bx, segment VisContentClass
	mov	si, offset VisContentClass
	mov	di, mask MF_STACK or mask MF_RECORD
	call	ObjMessage			;di = message
	mov	cx, di
	pop	si

	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent

done:
	add	sp, size GCNListParams		; fix stack
	ret

OpenCloseCommon	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerNotifyWithDataBlock -- MSG_META_NOTIFY_WITH_DATA_BLOCK
							for TextRulerClass

DESCRIPTION:	Handle notification

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass	(not dgroup)

	ax - The message

	cx.dx - change type ID
	bp - handle of block with NotifyTextChange structure

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 6/92		Initial version

------------------------------------------------------------------------------@
TextRulerNotifyWithDataBlock	method dynamic	TextRulerClass,
						MSG_META_NOTIFY_WITH_DATA_BLOCK

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jnz	sendToSuper
	cmp	dx, GWNT_TEXT_PARA_ATTR_CHANGE
	jz	5$
sendToSuper:
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	GOTO	TR_SendToSuper
5$:

	tst	bp
	jnz	valid
	mov	ds:[di].TRI_valid, BB_FALSE
	jmp	afterUpdate

valid:
	mov	ds:[di].TRI_valid, BB_TRUE

	; copy in the data

	mov	bx, bp
	call	MemLock
	mov	es, ax

	; if "align with page" then zero VRI_offset

	push	bp
	movdw	dxcx, es:VTNPAC_regionOffset
	clr	bp					;dxcx.bp = regionOffset
	mov	ax, MSG_VIS_RULER_SET_ORIGIN
	call	ObjCallInstanceNoLock
	pop	bp

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	mov	ax, es:VTNPAC_selectedTab
	mov	ds:[di].TRI_selectedTab, ax

	mov	ax, es:VTNPAC_regionWidth
	shl	ax
	shl	ax
	shl	ax				;convert to 13.3
;
; Check for some really big value, which seems unreasonable...
;
EC <	cmp	ax, 0xf000					>
EC <	ERROR_A	REGION_WIDTH_IS_NOT_REASONABLE			>

	mov	ds:[di].TRI_regionWidth, ax

	push	si, di, ds
	segxchg	es, ds
	lea	dx, es:[di].TRI_diffs
	lea	di, es:[di].TRI_paraAttr
	mov	si, offset VTNPAC_paraAttr
	mov	cx, (size VisTextMaxParaAttr) / 2
	rep movsw
	mov	si, offset VTNPAC_paraAttrDiffs
	mov	di, dx
	mov	cx, (size VisTextParaAttrDiffs) / 2
	rep movsw
	pop	si, di, ds

	; convert right margin to physical

	sub	ax, ds:[di].TRI_paraAttr.VTMPA_paraAttr.VTPA_rightMargin
	mov	ds:[di].TRI_paraAttr.VTMPA_paraAttr.VTPA_rightMargin, ax

	mov	bx, bp
	call	MemUnlock

afterUpdate:
	push	bp
	call	RedrawMarginsAndTabs
	pop	bp

	jmp	sendToSuper

TextRulerNotifyWithDataBlock	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerSetGCNContent -- MSG_TEXT_RULER_SET_GCN_CONTENT
							for TextRulerClass

DESCRIPTION:	Set the GCN content

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass (not dgroup)

	ax - The message

	cx:dx - content

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
TextRulerSetGCNContent	method dynamic	TextRulerClass,
						MSG_TEXT_RULER_SET_GCN_CONTENT
	movdw	ds:[di].TRI_gcnContent, cxdx
	ret

TextRulerSetGCNContent	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	TextRulerSetControlledAttrs --
		MSG_TEXT_RULER_SET_CONTROLLED_ATTRS for TextRulerClass

DESCRIPTION:	Set the controller attributes

PASS:
	*ds:si - instance data
	es - segment of TextRulerClass (not dgroup)

	ax - The message

	cx - TextRulerControlAttributes

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/21/92		Initial version

------------------------------------------------------------------------------@
TextRulerSetControlledAttrs	method dynamic	TextRulerClass,
					MSG_TEXT_RULER_SET_CONTROLLED_ATTRS

	test	cx, mask TRCA_ROUND
	jz	clearRound
	ornf	ds:[di].TRI_flags, mask TRF_ROUND_COORDINATES
	jmp	common
clearRound:
	andnf	ds:[di].TRI_flags, not mask TRF_ROUND_COORDINATES
common:
	and	cx, mask TRCA_IGNORE_ORIGIN
	mov	ax, MSG_VIS_RULER_SET_IGNORE_ORIGIN
	GOTO	ObjCallInstanceNoLock

TextRulerSetControlledAttrs	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	RulerCoordToObjectCoord

DESCRIPTION:	Translate a ruler coordinate to a object coordinate

CALLED BY:	INTERNAL

PASS:
	*ds:si - text ruler
	ax - position (13.3)

RETURN:
	ax - position

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 6/92		Initial version

------------------------------------------------------------------------------@
RulerCoordToObjectCoord	proc	near	uses cx, dx, di
	class	TextRulerClass
	.enter

	mov_tr	cx, ax
	clr	ax				;cx.ax = position

	mov	dl, 3
sloop:
	shr	cx
	rcr	ax
	dec	dl
	jnz	sloop

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	adddwf	dxcxax, ds:[di].VRI_origin

	clr	dx				;dxcx.ax = position
	call	RulerScaleDocToWinCoords
	add	ax, 0x8000
	jnc	10$
	inc	cx
10$:
	mov_tr	ax, cx				;ax = window position

	.leave
	ret

RulerCoordToObjectCoord	endp

RulerCommon ends

;---

RulerCode segment resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjectCoordToRulerCoord

DESCRIPTION:	Translate an object coordinate to a ruler coordinate

CALLED BY:	INTERNAL

PASS:
	*ds:si - text ruler
	ss:bp - LargeMouseData

RETURN:
	ax - position

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 6/92		Initial version

------------------------------------------------------------------------------@
ObjectCoordToRulerCoord	proc	near	uses cx, dx, di
	class	TextRulerClass
	.enter

	movdwf	dxcxax, ss:[bp].LMD_location.PDF_x
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	subdwf	dxcxax, ds:[di].VRI_origin

	;cx.ax = position

	mov	dl, 3
sloop:
	shl	ax
	rcl	cx
	dec	dl
	jnz	sloop

	add	ax, 0x8000
	jnc	20$
	inc	cx
20$:
	mov_tr	ax, cx

	.leave
	ret

ObjectCoordToRulerCoord	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RoundCoordinate

DESCRIPTION:	Round a coordinate

CALLED BY:	INTERNAL

PASS:
	*ds:si - VisRuler object
	ax - coordinate to round

RETURN:
	ax - rounded coordinate

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/92		Initial version

------------------------------------------------------------------------------@

TextRulerScaleZones	etype	byte
TRSZ_UNDER_25_PERCENT	enum	TextRulerScaleZones	;x <= 25%
TRSZ_25_TO_50_PERCENT	enum	TextRulerScaleZones	;25% <= x <= 50%
TRSZ_50_TO_75_PERCENT	enum	TextRulerScaleZones	;50% <= x <= 75%
TRSZ_75_TO_100_PERCENT	enum	TextRulerScaleZones	;75% <= x <= 100%
TRSZ_100_TO_125_PERCENT	enum	TextRulerScaleZones	;100% <= x <= 125%
TRSZ_125_TO_150_PERCENT	enum	TextRulerScaleZones	;125% <= x <= 150%
TRSZ_150_TO_200_PERCENT	enum	TextRulerScaleZones	;150% <= x <= 200%
TRSZ_OVER_200_PERCENT	enum	TextRulerScaleZones	;200% <= x

RoundCoordinate	proc	near	uses bx, cx, dx, di
	class	TextRulerClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].TRI_flags, mask TRF_ROUND_COORDINATES
	jz	done

	movdw	cxdx, ds:[di].VRI_scale

	; calculate the scale factor zone (cx.dx = scale)

	mov	bx, TRSZ_OVER_200_PERCENT
	cmp	cx, 2
	jae	gotScale
	shl	dx				;multiply by 4
	rcl	cx
	shl	dx
	rcl	cx
	adddw	cxdx, 0x8000			;and round
	mov	bx, cx
gotScale:

	clr	dx
	cmp	ds:[di].VRI_type, VRT_CENTIMETERS
	jz	metric

	push	ax
	shl	bx
	mov	cx, cs:[bx][roundTable]		;get rounding value
	div	cx				;ax = result, dx = fraction
	pop	ax
	mov	ch, cl
	shr	ch				;cx = rounding value / 2
	cmp	dl, ch
	jle	roundDown

	; round up

	sub	dl, cl				;produces negative result
	neg	dl
	add	ax, dx
	jmp	done

roundDown:
	sub	ax, dx
done:
	.leave
	ret

	; if metric, we either round to:
	;	25% - centimeters
	;	50%, 75%, 100%, 125% - half centimeters
	;	150%, 175%, 200% - millimeters

	; 1 cm = 28.3464576 points

	; divide (pixels*4096) by (value*2048) to get (result * 2)
	; round this, divide by 2 and multiply by (value*2048)
	; to get (position*2048)

metric:
	mov	cx, 4096/8
	mul	cx				;dx.ax = (pixels*4096)

	shl	bx				;make bx a word index
	div	cs:[bx][metricRoundTable]	;ax = result, dx = remainder
	inc	ax				;round
	shr	ax, 1				;ax = result

	mul	cs:[bx][metricRoundTable]	;dx.ax = position * 2048
	add	ax, 2048/2			;round position
	adc	dx, 0

	mov	cx, 2048/8			;divide dx.ax by 2048
	div	cx
	jmp	done
	

RoundCoordinate	endp

roundTable	label	word
	word	72*8		; TRSZ_UNDER_25_PERCENT
	word	36*8		; TRSZ_25_TO_50_PERCENT
	word	18*8		; TRSZ_50_TO_75_PERCENT
	word	9*8		; TRSZ_75_TO_100_PERCENT
	word	9*8		; TRSZ_100_TO_125_PERCENT
	word	9*8		; TRSZ_125_TO_150_PERCENT
	word	9*4		; TRSZ_150_TO_200_PERCENT
	word	9*4		; TRSZ_OVER_200_PERCENT

metricRoundTable	label	word
	word	58053		;25% -- 1 cm * 2048
	word	29027		;50% -- 1/2 cm * 2048
	word	29027		;75% -- 1/2 cm * 2048
	word	29027		;100% -- 1/2 cm * 2048
	word	29027		;125% -- 1/2 cm * 2048
	word	5805		;150% -- 1 mm * 2048
	word	5805		;175% -- 1 mm * 2048
	word	5805		;200% -- 1 mm * 2048

RulerCode ends
