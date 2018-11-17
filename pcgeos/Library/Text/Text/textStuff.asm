COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User interface/Text
FILE:		textStuff.asm

AUTHOR:		Tony

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/22/89		Initial revision

DESCRIPTION:
	Low level utility routines for implementing the methods defined on
	VisTextClass.

	$Id: textStuff.asm,v 1.1 97/04/07 11:18:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Text segment resource


TextDrawCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextScreenUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a screen update.

CALLED BY:	Via MSG_VIS_TEXT_SCREEN_UPDATE.
PASS:		ds:*si = ptr to instance.
		es = segment containing VisTextClass.
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	8/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextScreenUpdate	method dynamic	VisTextClass, MSG_VIS_TEXT_SCREEN_UPDATE
	call	TextGStateCreate
	call	TextDraw_DerefVis_DI

	test	ds:[di].VTI_intFlags, mask VTIF_UPDATE_PENDING
	jz	noUpdate			; Quit update was done already.

	call	TextCheckCanDraw		; Can we update the screen?
	jc	noUpdate

	call	TextScreenUpdate		; Update screen.
noUpdate:
	;
	; No more update pending.
	;
	and	ds:[di].VTI_intFlags, not mask VTIF_UPDATE_PENDING

	call	TextGStateDestroy
	ret
VisTextScreenUpdate	endm

TextDrawCode	ends

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextCheckCanCalcWithRange

DESCRIPTION:	Check if the object can be calculated and if not add a range
		to the range to calculate later

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object
	ss:bp - VisTextRange

RETURN:
	carry - set if calculation impossible

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/20/92		Initial version

------------------------------------------------------------------------------@
TextCheckCanCalcWithRange	proc	far
EC <	cmp	ss:[bp].VTR_start.high, TEXT_ADDRESS_PAST_END_HIGH	>
EC <	ERROR_A	VIS_TEXT_MUST_PASS_QUALIFIED_RANGE			>

	call	TextCheckCanCalcNoRange
	jnc	done
	jz	done

	; can't calculate, add to range

	call	Text_PushAll

	mov	ax, ATTR_VIS_TEXT_SUSPEND_DATA
	call	ObjVarFindData
EC <	ERROR_NC VIS_TEXT_SUSPEND_LOGIC_ERROR				>

	mov	ds:[bx].VTSD_needsRecalc, BB_TRUE

	movdw	dxax, ss:[bp].VTR_start
	tstdw	ds:[bx].VTSD_recalcRange.VTR_end
	jz	storeStart
	cmpdw	dxax, ds:[bx].VTSD_recalcRange.VTR_start
	jae	afterStart
storeStart:
	movdw	ds:[bx].VTSD_recalcRange.VTR_start, dxax
afterStart:

	movdw	dxax, ss:[bp].VTR_end
	cmpdw	dxax, ds:[bx].VTSD_recalcRange.VTR_end
	jbe	afterEnd
	movdw	ds:[bx].VTSD_recalcRange.VTR_end, dxax
afterEnd:
	stc

	Text_PopAll_ret

done:
	ret

TextCheckCanCalcWithRange	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TextCheckCanCalcNoRange

DESCRIPTION:	Check to see if the object can be calculated

CALLED BY:	INTERNAL

PASS:
	*ds:si - text object

RETURN:
	carry - set if calculation impossible
	z flag - clear if object suspended

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/20/92		Initial version

------------------------------------------------------------------------------@
TextCheckCanCalcNoRange	proc	far	uses di
	class	VisLargeTextClass
	.enter

	call	Text_DerefVis_DI		; ds:di <- instance ptr.
	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jnz	cantCalc
	test	ds:[di].VTI_intFlags, mask VTIF_HAS_LINES
	jz	cantCalc

	; if we're in draft mode then we need a non-zero width

	test	ds:[di].VTI_storageFlags, mask VTSF_LARGE
	jz	afterDraftCheck
	cmp	ds:[di].VLTI_displayMode, VLTDM_DRAFT_WITH_STYLES
	jb	afterDraftCheck
	tst	ds:[di].VLTI_displayModeWidth
	jz	cantCalc
afterDraftCheck:

	;
	; 'test' clears the carry. Which is what we want if calculation is
	; possible.
	;
	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jz	canCalculate
	test	ax, 0				;set z flag

cantCalc:
	stc
canCalculate:
	.leave
	ret

TextCheckCanCalcNoRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextSendUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send ourselves an update event to get the screen redrawn.

CALLED BY:	UTILITY
PASS:		*ds:si	= Instance ptr
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	10/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextSendUpdate	proc	far
	class	VisTextClass
	call	Text_PushAll

	call	TextCheckCanDraw		; Don't send update if we can't
	jc	done				;   draw to this object.
	call	Text_DerefVis_DI

	test	ds:[di].VTI_intFlags, mask VTIF_UPDATE_PENDING
	jnz	done				; No need, update is pending.

	or	ds:[di].VTI_intFlags, mask VTIF_UPDATE_PENDING

	mov	ax, MSG_VIS_TEXT_SCREEN_UPDATE	; Update me jesus.

ife	TEXT_IGNORE_BACKLOG
	;
	; Check for characters in the queue.
	;
	call	CheckKbdBacklog
	jc	queueEvent

	call	ObjCallInstanceNoLock
	jmp	done

queueEvent:
endif
	;
	; Queue the message up
	;
	mov	di, mask MF_FORCE_QUEUE
	mov	bx, ds:LMBH_handle
	call	ObjMessage
done:

	call	Text_PopAll
	ret
TextSendUpdate	endp

Text ends

TextFixed	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCheckCanDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we can draw.

CALLED BY:	UTILITY
PASS:		ds:*si	= instance ptr.
RETURN:		carry clear if we can draw.
		carry set if drawing can't be done now.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	We can only draw if:
		The object is realized (check the VA_REALIZED bit in VI_attrs).
		The object has valid visual bounds (check VI_bounds.R_right).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/22/89	Initial version
	Chris	4/91		Updated for new graphics, bounds conventions

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCheckCanDraw	proc	far
	class	VisTextClass
	uses	ax, di
	.enter
	call	TextFixed_DerefVis_DI			; ds:di <- instance ptr.

	test	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	jnz	cantDraw

	test	ds:[di].VTI_intFlags, mask VTIF_SUSPENDED
	jnz	cantDraw

	test	ds:[di].VTI_intFlags, mask VTIF_HAS_LINES
	jz	cantDraw

	test	ds:[di].VI_attrs, mask VA_DRAWABLE	; Check for drawable
	jz	cantDraw

	test	ds:[di].VI_attrs, mask VA_REALIZED	; Check for realized.
	jnz	isRealized
cantDraw:
	stc
	jmp	done
isRealized:

	;
	; I don't think that I need to check the bounds.
	;
	; If I wanted to be complete I would check for VOF_GEOMETRY_INVALID
	; set in the VI_optFlags field.
	;
EC <	pushf								>
EC <	push	cx							>
EC <	mov	cx, ds:[di].VI_bounds.R_left		; new EC code	>
EC <	cmp	cx, ds:[di].VI_bounds.R_right		; (cbh 4/22/91) >
EC <	ERROR_G  VIS_TEXT_GEOMETRY_VALID_BUT_BAD_SIZE			>
EC <	pop	cx							>
EC <	popf								>

	; One final check -- make sure that the gstate has a window

	mov	di, ds:[di].VTI_gstate
EC <	tst	di							>
EC <	ERROR_Z	VIS_TEXT_TEXT_CHECK_CAN_DRAW_MUST_HAVE_GSTATE		>
	call	GrGetWinHandle
	tst	ax
	jz	cantDraw

done:
	;
	; Carry is assumed set correctly here.
	;
	.leave
	ret
TextCheckCanDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCheckCanDrawEditable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if we can draw here and it is editable

CALLED BY:	

PASS:		*ds:si	= text object

RETURN:		*ds:di 	= instance pointer
		carry: CLEAR if we can draw AND it is editable
		       SET if we cannot draw OR it is not editable

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	2/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextCheckCanDrawEditable	proc	far
	call	TextCheckCanDraw
	jc	exit				; carry set = cannot draw
	
	; This derefences *ds:si into *ds:di.
	call	CheckNotEditable		; carry set if not editable

exit:
	ret
TextCheckCanDrawEditable	endp


TextFixed	ends
