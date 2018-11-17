COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text
FILE:		textSuspend.asm

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains...

	$Id: textSuspend.asm,v 1.1 97/04/07 11:18:08 newdeal Exp $

------------------------------------------------------------------------------@

TextAttributes segment resource

COMMENT @----------------------------------------------------------------------

METHOD:		VisTextSuspend -- MSG_META_SUSPEND for VisTextClass

DESCRIPTION:	Suspend calculation and drawing

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

	ax - The method

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/89		Initial version

------------------------------------------------------------------------------@
VisTextSuspend	method dynamic	VisTextClass, MSG_META_SUSPEND
BEC <	call	CheckRunPositions		>

	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jnz	alreadySuspended

	call	TextGStateCreate	
	call	EditUnHilite
	call	TextGStateDestroy

	ornf	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED

;	Set the flag that sez we want to start a "wrap-around" undo chain
;	if an undoable action happens while we are suspended.

	mov	ax, TEMP_VIS_TEXT_UNDO_FOR_SUSPEND
	clr	cx
	call	ObjVarAddData

	; this is the first suspension, create the structure

	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	mov	cx, size VisTextSuspendData
	call	ObjVarAddData
	clr	ax
	clrdw	ds:[bx].VTSD_recalcRange.VTR_start, ax
	clrdw	ds:[bx].VTSD_recalcRange.VTR_end, ax
;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Removed,  4/22/93 -jw
; We are no longer using this range.
;	clrdw	ds:[bx].VTSD_selectRange.VTR_start, ax
;	clrdw	ds:[bx].VTSD_selectRange.VTR_end, ax
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	movdw	ds:[bx].VTSD_showSelectionPos, 0xffffffff
	mov	ds:[bx].VTSD_notifications, ax
	mov	ds:[bx].VTSD_needsRecalc, al
	mov	ds:[bx].VTSD_count, 1

done:
	mov	ax, MSG_META_SUSPEND
	GOTO	T_CallSuper

alreadySuspended:
	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData
EC <	ERROR_NC VIS_TEXT_SUSPEND_LOGIC_ERROR				>
EC <	cmp	ds:[bx].VTSD_count, 40					>
EC <	ERROR_AE VIS_TEXT_SUSPEND_COUNT_SEEMS_TOO_HIGH			>

	inc	ds:[bx].VTSD_count
	jmp	done

VisTextSuspend	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	VisTextUnsuspend -- MSG_META_UNSUSPEND for VisTextClass

DESCRIPTION:	Unsuspend the object

PASS:
	*ds:si - instance data
	es - segment of VisTextClass

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
	Tony	3/20/92		Initial version

------------------------------------------------------------------------------@
VisTextUnsuspend	method dynamic	VisTextClass, MSG_META_UNSUSPEND

	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData
EC <	ERROR_NC VIS_TEXT_SUSPEND_LOGIC_ERROR				>
EC <	cmp	ds:[bx].VTSD_count, 40					>
EC <	ERROR_AE VIS_TEXT_SUSPEND_COUNT_SEEMS_TOO_HIGH			>

	dec	ds:[bx].VTSD_count
	LONG jnz done

;	We are becoming unsuspended - see if we have an undo chain that
;	was created while we were suspended - if so, we need to end the
;	chain.

	mov	ax, TEMP_VIS_TEXT_UNDO_FOR_SUSPEND
	call	ObjVarDeleteData	;Returns carry set if was already
	jnc	noUndoChain		; deleted (by TU_StartUndoChain)

	call	TU_EndUndoChain

noUndoChain:
	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData

	; the suspend count has reach zero -- recalculate

;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Changed,  4/22/93 -jw
; We now just use the current selection. Resetting the selection causes stuff
; to update correctly.
;	pushdw	ds:[bx].VTSD_selectRange.VTR_end
;	pushdw	ds:[bx].VTSD_selectRange.VTR_start
	
	pushdw	ds:[di].VTI_selectEnd
	pushdw	ds:[di].VTI_selectStart
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	pushdw	ds:[bx].VTSD_showSelectionPos
	pushdw	ds:[bx].VTSD_recalcRange.VTR_end
	pushdw	ds:[bx].VTSD_recalcRange.VTR_start
	mov	bp, sp					;ss:bp = range to inval

	tst	ds:[bx].VTSD_needsRecalc
	pushf
	push	ds:[bx].VTSD_notifications
	andnf	ds:[di].VTI_intFlags, not mask VTIF_SUSPENDED
	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarDeleteData

	pop	ax					;ax = flags
	popf
	jz	noRecalc

	call	TextCheckCanCalcNoRange
	jc	noCreateGState
	call	TextGStateCreate
noCreateGState:
	clr	cx					;force recalc
	call	ReflectChangeWithFlags
	jmp	common					;and nukes gstate

noRecalc:
	tst	ax
	jz	noNotify
	call	TA_SendNotification
noNotify:
	call	TextCheckCanCalcNoRange
	jc	noHilite
	call	TextGStateCreate
	call	EditHilite
	call	TextGStateDestroy
noHilite:

	; now we need to select the range visually.  We will do this
	; unless we have been specifically told not to (by setting
	; VTSD_showSelectionPos to -1)

common:
	add	sp, size VisTextRange			;pop off
							;VTSD_recalcRange
	popdw	dxax					;dxax = VTSD_showSelectionPos
	mov	bp, sp					;ss:bp =
							;select range
	cmpdw	dxax, 0xffffffff
	jz	noSelect
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE
	call	ObjCallInstanceNoLock
noSelect:
	add	sp, size VisTextRange			;pop off
							;select range

done:
	mov	ax, MSG_META_UNSUSPEND
	FALL_THRU	T_CallSuper

VisTextUnsuspend	endm

;---

T_CallSuper	proc	far
	mov	di, segment VisTextClass
	mov	es, di
	mov	di, offset VisTextClass
	GOTO	ObjCallSuperNoLock
T_CallSuper	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend text object recalculation

CALLED BY:	INTERNAL

PASS:		*ds:si	= text object
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSuspend	proc	far
		uses	bp
		.enter

EC <		call	T_AssertIsVisText			>

		mov	ax, MSG_META_SUSPEND
		call	ObjCallInstanceNoLock

		.leave
		ret
TextSuspend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend text object recalculation

CALLED BY:	INTERNAL

PASS:		*ds:si	= text object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextUnsuspend	proc	far

EC <		call	T_AssertIsVisText			>

		mov	ax, MSG_META_UNSUSPEND
		call	ObjCallInstanceNoLock

		ret
TextUnsuspend	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ReflectChangeUpdateGeneric

DESCRIPTION:	Update any generic instance data and then do ReflectChange

CALLED BY:	INTERNAL

PASS:
	*** gstate created IF calculation is possible
	*ds:si - text object
	ss:bp - VisTextRange

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
	Tony	10/15/92		Initial version

------------------------------------------------------------------------------@
ReflectChangeUpdateGeneric	proc	far
	call	SendGenericUpdate
	FALL_THRU	ReflectChange

ReflectChangeUpdateGeneric	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ReflectChange

DESCRIPTION:	Finish a text operation by calling TextRangeChange to mark the
		range as changed.

CALLED BY:	INTERNAL

PASS:
	*** gstate created IF calculation is possible
	*ds:si - text object
	ss:bp - VisTextRange

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
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
ReflectChange	proc	far
	mov	ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
	mov	cx, 1
	call	ReflectChangeWithFlags

	call	TextMarkUserModified

	push	bp
	mov	ax, MSG_VIS_TEXT_ATTRIBUTE_CHANGE
	call	ObjCallInstanceNoLock
	pop	bp

	ret

ReflectChange	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ReflectChangeWithFlags

DESCRIPTION:	Finish a text operation by calling TextRangeChange to mark the
		range as changed.

CALLED BY:	INTERNAL

PASS:
	*** gstate created IF calculation is possible
	*ds:si - text object
	ss:bp - VisTextRange
	ax - NotificationFlags to send
	cx - zero to *force* recalculation, even if (start == end)

RETURN:
	*** gstate destroyed
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@
ReflectChangeWithFlags	proc	near
	push	ax				;save flags

	call	TextCheckCanCalcWithRange	; can we calc?
	jc	noInvalidate			; bra if not

	;
	; Check for start/end of range being equal.
	;
	movdw	dxax, ss:[bp].VTR_start
	jcxz	recalc
	cmpdw	dxax, ss:[bp].VTR_end
	jnz	recalc
	tstdw	dxax
	jnz	done

	; dxax = range start

recalc:
	stc					; Get first line if at end
	call	TL_LineFromOffset		; bx.di <- first affected line
	
	;
	; Recalculate the text object.
	;
	movdw	dxax, ss:[bp].VTR_end		; dx.ax <- # of changed chars
	subdw	dxax, ss:[bp].VTR_start
	call	TextRecalc

	; Send an update message and show the selection

	push	bp
	call	TextSendUpdate			; Send an update.
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	clr	bp
	call	TextCallShowSelection		; Else show cursor.
	pop	bp

done:
	call	EditHilite			; Restore the selection
	call	TextGStateDestroy

noInvalidate:
	pop	ax
	tst	ax
	jz	noNotify
	call	TA_SendNotification
noNotify:

	ret
ReflectChangeWithFlags	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SendGenericUpdate

DESCRIPTION:	Send a MSG_VIS_TEXT_UPDATE_GENERIC method to ourself if this
		is a generic object

CALLED BY:	INTERNAL

PASS:
	*ds:si - object

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@
SendGenericUpdate	proc	far		uses ax, cx, dx, di, bp
	class	VisTextClass
	.enter

EC <	call	ECCheckObject						>

	; if this is a gen object then send ourself a method to update the
	; generic instance data

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_typeFlags, mask VTF_IS_GEN
	jz	notGeneric
	mov	ax, MSG_VIS_TEXT_UPDATE_GENERIC
	call	ObjCallInstanceNoLock
notGeneric:

	.leave
	ret

SendGenericUpdate	endp

TextAttributes ends
