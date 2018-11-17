COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Hierarchy
FILE:		graphicBodyMouse.asm

AUTHOR:		Steve Scholl, Oct 15, 1991

ROUTINES:
	Name			Description
	----			-----------
GrObjBodySendMessageToMouseGrab	Send message to object with mouse grab
GrObjBodyGuaranteeMouseGrab	Makes sure something has the mouse grab
GrObjBodyClearMouseGrab
GrObjBodyMouseEventCommon
GrObjBodyConvertLargeMouseDataToGrObjMouseData
GrObjBodyGetDefaultsFromRuler

MSG_HANDLERS
	Name			Description
	----			-----------
GrObjBodyVupAlterInputFlow		
GrObjBodyLargeStartSelect	Handle MSG_META_LARGE_START_SELECT
GrObjBodyLargeEndSelect		Handle MSG_META_LARGE_END_SELECT
GrObjBodyLargeDragSelect	Handle MSG_META_LARGE_DRAG_SELECT
GrObjBodyLargeStartMoveCopy	Handle MSG_META_LARGE_START_MOVE_COPY
GrObjBodyLargeEndMoveCopy	Handle MSG_META_LARGE_END_MOVE_COPY
GrObjBodyLargeDragMoveCopy	Handle MSG_META_LARGE_DRAG_MOVE_COPY
GrObjBodyLargePtr		Handle all large mouse ptr events
GrObjBodyGiveMeMouseEvents	Set od to send mouse message to
GrObjBodyDontGiveMeMouseEvents Clear od if passed object has grab
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	10/15/91	Initial revision


DESCRIPTION:

	$Id: bodyMouse.asm,v 1.1 97/04/04 18:08:12 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GrObjRequiredInteractiveCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyVupAlterInputFlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept the mouse grabs and add in body's 32 bit
		translation

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - VupAlterInputFlowData

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyVupAlterInputFlow	method dynamic GrObjBodyClass,
				MSG_VIS_VUP_ALTER_INPUT_FLOW
	.enter
	
	;    All vis mouse grabs in the grobj are performed by the body
	;    so the NOT_HERE flag will always be set. However,
	;    the body grabs the mouse and handles all the mouse events
	;    for its children so we want in include the bodies translation
	;    anyway. We do need to clear it for the next level up of
	;    this handler
	;

	andnf	ss:[bp].VAIFD_flags, not mask VIFGF_NOT_HERE


	;    Check for mouse grab, if not, jump to just sendToParent
	;

	test	ss:[bp].VAIFD_flags, mask VIFGF_MOUSE
	jz	sendToParent

	test	ss:[bp].VAIFD_flags,mask VIFGF_GRAB
	jz	sendToParent

	;    Add in translation of body
	;

	mov	cx,ds:[di].GBI_bounds.RD_left.low
	add	ss:[bp].VAIFD_translation.PD_x.low,cx
	mov	cx,ds:[di].GBI_bounds.RD_left.high
	adc	ss:[bp].VAIFD_translation.PD_x.high,cx

	mov	cx,ds:[di].GBI_bounds.RD_top.low
	add	ss:[bp].VAIFD_translation.PD_y.low,cx
	mov	cx,ds:[di].GBI_bounds.RD_top.high
	adc	ss:[bp].VAIFD_translation.PD_y.high,cx

sendToParent:
	call	VisCallParent

	.leave
	ret
GrObjBodyVupAlterInputFlow		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyConvertLargeMouseDataToGrObjMouseData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a LargeMouseData stack frame into a
		GrObjMouseData stack frame

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - body
		ss:bx - LargeMouseData - filled
		ss:bp - GrObjMouseData - empty

RETURN:		
		ss:bp - GrObjMouseData - filled

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 1
GrObjBodyConvertLargeMouseDataToGrObjMouseData		proc	near
	class	GrObjBodyClass
	uses	ax,es,di
	.enter

CheckHack < (offset GOMD_point eq 0 ) >

	;   Point ds:si at LargeMouseData and es:di at GrObjMouseData
	;   and copy mouse point
	;

	push	ds,si
	segmov	ds,ss,si			;source segment
	mov	es,si				;dest segment
	mov	si,bx				;source offset
	mov	di,bp				;dest offset
	MoveConstantNumBytes	<size LargeMouseData> , ax
	pop	ds,si

	;    Get the gstate and currentOptions from the
	;    bodies instance data and store in GrObjMouseData
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	ax,ds:[di].GBI_graphicsState
	mov	ss:[bp].GOMD_gstate,ax

	mov	al,ss:[bx].LMD_uiFunctionsActive
	andnf	ax, mask UIFA_EXTEND or mask UIFA_ADJUST
	ornf	ax,ds:[di].GBI_currentOptions
	mov	ss:[bp].GOMD_goFA, ax

	.leave
	ret
GrObjBodyConvertLargeMouseDataToGrObjMouseData		endp
else
GrObjBodyConvertLargeMouseDataToGrObjMouseData		proc	near
	class	GrObjBodyClass
	uses	ax,es,di
	.enter

CheckHack < (offset GOMD_point eq 0 ) >

	;   Point ds:si at LargeMouseData and es:di at GrObjMouseData
	;   and copy mouse point
	;

	push	ds,si
	segmov	ds,ss,si			;source segment
	mov	es,si				;dest segment
	mov	si,bx				;source offset
	mov	di,bp				;dest offset
	MoveConstantNumBytes	<size PointDWFixed> , ax
	pop	ds,si


	;    Copy ButtonInfo and UIFunctionsActive into GrObjMouseData 
	;    and set EXTEND and ADJUST in goFA from uiFA
	;

	mov	al,ss:[bx].LMD_buttonInfo
	mov	ss:[bp].GOMD_buttonInfo,al
	mov	al,ss:[bx].LMD_uiFunctionsActive
	mov	ss:[bp].GOMD_uiFA, al
	and	ax, mask UIFA_EXTEND or mask UIFA_ADJUST
	mov	ss:[bp].GOMD_goFA, ax

	;    Get the gstate and currentOptions from the
	;    bodies instance data and store in GrObjMouseData
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	ax,ds:[di].GBI_graphicsState
	mov	ss:[bp].GOMD_gstate,ax
	mov	ax,ds:[di].GBI_currentOptions
	ornf	ss:[bp].GOMD_goFA,ax

	.leave
	ret
GrObjBodyConvertLargeMouseDataToGrObjMouseData		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMouseEventCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common functionality for all mouse events

CALLED BY:	INTERNAL

PASS:		*ds:si - GrObjBody
		ss:bp - LargeMouseData
		ax - mouse message

RETURN:		
		ax - MouseReturnFlags
		cx:dx - new ptr image if MRF_SET_POINTER_IMAGE

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMouseEventCommon		proc	far
	class	GrObjBodyClass
	uses	bx,bp,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Update the currentModifiers and currentOptions
	;    based on the UIFA_CONSTRAIN bit
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	bl,ss:[bp].LMD_uiFunctionsActive
	andnf	bl,mask UIFA_CONSTRAIN			;only constrain
	BitClr	ds:[di].GBI_currentModifiers, GOFA_CONSTRAIN
	clr	bh
	ornf	ds:[di].GBI_currentModifiers,bx
	call	GrObjBodySetOptions

	;    Convert the mouse message and send to our grab
	;

	mov	bx,bp
	sub	sp,size GrObjMouseData
	mov	bp,sp
	call	GrObjBodyConvertLargeMouseDataToGrObjMouseData
	call	GrObjBodyLimitMouseEventsToBodyBounds

	mov_tr	cx,ax
	CallMod	GrObjGlobalConvertSystemMouseMessage
	mov	dx,size GrObjMouseData
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyGuaranteeMouseGrab
	call	GrObjBodySendMessageToMouseGrab
EC <	ERROR_Z GROBJ_BODY_NO_MOUSE_GRAB		>
	add	sp, size GrObjMouseData

	.leave
	ret
GrObjBodyMouseEventCommon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLimitMouseEventsToBodyBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the mouse event is outside the bounds of the body
		then reel it in.

		NOTE: The mouse events are relative to the body's
		bounds.

CALLED BY:	INTERNAL
		GrObjBodyMouseEventCommon

PASS:		
		*ds:si - Body
		ss:bp - GrObjMouseData	

RETURN:		
		ss:bp - GrObjMouseData

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLimitMouseEventsToBodyBounds		proc	near
	class	GrObjBodyClass
	uses	di,ax,bx,dx,cx
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>
	
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	movdw	dxcx,ss:[bp].GOMD_point.PDF_x.DWF_int
	tst	dx
	js	zeroX
	movdw	bxax,ds:[di].GBI_bounds.RD_right
	subdw	bxax,ds:[di].GBI_bounds.RD_left
	jgdw	dxcx,bxax,limitToWidth
		
checkY:
	movdw	dxcx,ss:[bp].GOMD_point.PDF_y.DWF_int
	tst	dx
	js	zeroY
	movdw	bxax,ds:[di].GBI_bounds.RD_bottom
	subdw	bxax,ds:[di].GBI_bounds.RD_top
	jgdw	dxcx,bxax,limitToHeight

done:
	.leave
	ret

zeroX:
	clr	ax
	movdwf	ss:[bp].GOMD_point.PDF_x,axaxax
	jmp	checkY

limitToWidth:
	movdw	ss:[bp].GOMD_point.PDF_x.DWF_int,bxax
	clr	ss:[bp].GOMD_point.PDF_y.DWF_frac
	jmp	checkY

zeroY:
	clr	ax
	movdwf	ss:[bp].GOMD_point.PDF_y,axaxax
	jmp	done

limitToHeight:
	movdw	ss:[bp].GOMD_point.PDF_y.DWF_int,bxax	
	clr	ss:[bp].GOMD_point.PDF_y.DWF_frac
	jmp	done


GrObjBodyLimitMouseEventsToBodyBounds		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMouseEventToEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common functionality for all mouse events

CALLED BY:	INTERNAL

PASS:		*ds:si - GrObjBody
		ss:bp - LargeMouseData
		ax - mouse message

RETURN:		
		zero flag clear if message sent
			ax - MouseReturnFlags
			cx:dx - new ptr image if MRF_SET_POINTER_IMAGE
		zero flag set if no target

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMouseEventToEdit		proc	far
	class	GrObjBodyClass
	uses	bx,bp,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	bx,ds:[si]
	add	bx,ds:[bx].GrObjBody_offset
	tst	ds:[bx].GBI_targetExcl.HG_OD.handle
	jz	done

	;    Convert the mouse message and send to our grab
	;

	mov	bx,bp
	sub	sp,size GrObjMouseData
	mov	bp,sp
	call	GrObjBodyConvertLargeMouseDataToGrObjMouseData

	mov_tr	cx,ax
	CallMod	GrObjGlobalConvertSystemMouseMessage
	mov	dx,size GrObjMouseData
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToEdit

	add	sp, size GrObjMouseData

done:
	.leave
	ret
GrObjBodyMouseEventToEdit		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGetDefaultsFromRuler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get defaults from ruler and set options in body.

CALLED BY:	INTERNAL
		GrObjBodyLargeStartSelect

PASS:		*ds:si - body

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGetDefaultsFromRuler		proc	near
	class	GrObjBodyClass
	uses	ax,cx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	;    Assume snap to is not on
	;

	BitClr	ds:[di].GBI_defaultOptions, GOFA_SNAP_TO

	;    If any of the snap to bits are set in the ruler
	;    then the default should be snap to
	;

	mov	ax,MSG_VIS_RULER_GET_CONSTRAIN_STRATEGY
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToRuler
	test	cx,mask VRCS_SNAP_TO_GRID_X_ABSOLUTE or \
		mask VRCS_SNAP_TO_GRID_Y_ABSOLUTE or \
		mask VRCS_SNAP_TO_GRID_X_RELATIVE or \
		mask VRCS_SNAP_TO_GRID_Y_RELATIVE

	jz	setOptions

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	BitSet	ds:[di].GBI_defaultOptions, GOFA_SNAP_TO

setOptions:
	call	GrObjBodySetOptions

	.leave
	ret
GrObjBodyGetDefaultsFromRuler		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLargeStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes all large mouse press messages and converts
		them into mouse press message used internal to 
		the grobj

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - LargeMouseData

RETURN:		
		ax - MouseReturnFlags
	
DESTROYED:	
		cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLargeStartSelect	method dynamic GrObjBodyClass, 
				MSG_META_LARGE_START_SELECT
	.enter

	call	GrObjBodyGetDefaultsFromRuler

	;    Set ourself as the current body so that the floater
	;    can interact with us.
	;

	push	ax				;mouse message
	mov	cx,ds:[LMBH_handle]
	mov	dx,si
	mov	ax,MSG_GH_SET_CURRENT_BODY
	clr	di
	call	GrObjBodyMessageToHead
EC <	ERROR_Z	GROBJ_BODY_NOT_ATTACHED_TO_HEAD			>
	pop	ax				;mouse message

	call	GrObjBodyMouseEventCommon

	.leave
	ret
GrObjBodyLargeStartSelect		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLargeEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes all large mouse press messages and converts
		them into mouse press message used internal to 
		the grobj

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - LargeMouseData

RETURN:		
		ax - MouseReturnFlags
	
DESTROYED:	
		cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLargeEndSelect		method dynamic GrObjBodyClass,
				MSG_META_LARGE_END_SELECT
	.enter

	call	GrObjBodyMouseEventCommon

	;   We only want these modifiers to last for one mouse operation
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	andnf	ds:[di].GBI_currentModifiers,not ( mask GOFA_SNAP_TO or \
					mask GOFA_FROM_CENTER or \
					mask GOFA_ABOUT_OPPOSITE )
	call	GrObjBodySetOptions

	.leave
	ret
GrObjBodyLargeEndSelect		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLargeDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes all large mouse press messages and converts
		them into mouse press message used internal to 
		the grobj

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - LargeMouseData

RETURN:		
		ax - MouseReturnFlags
	
DESTROYED:	
		cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLargeDragSelect	method dynamic GrObjBodyClass,
				MSG_META_LARGE_DRAG_SELECT
	.enter

	call	GrObjBodyMouseEventCommon

	.leave
	ret
GrObjBodyLargeDragSelect		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLargePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes all large mouse press messages and converts
		them into mouse press message used internal to 
		the grobj

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - LargeMouseData

RETURN:		
		ax - MouseReturnFlags
	
DESTROYED:	
		cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/21/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLargePtr	method dynamic GrObjBodyClass, MSG_META_LARGE_PTR
	.enter

	;    Save last ptr event location.
	;

	push	es,si	
	segmov	es,ds,cx
	add	di,offset GBI_lastPtr
	segmov	ds,ss,cx
	mov	si,bp
	MoveConstantNumBytes	<size PointDWFixed>, cx
	segmov	ds,es,cx
	pop	es,si

	;    If there is no mouse grab then the mouse is just floating
	;    over this body, so pass the message off to the head
	;    which will pass it to the floater which will set the
	;    pointer image
	;

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_mouseGrab.handle
	jz	checkEdit

	call	GrObjBodyMouseEventCommon

done:
	.leave
	ret

checkEdit:
;	mov	di, mask MF_FIXUP_DS or mask MF_CALL
;	call	GrObjBodyMouseEventToEdit
;	jnz	done

	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_MOVE_COPY
	jnz	checkStatus


head:
	mov	di,mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	mov	dx,size LargeMouseData
	call	GrObjBodyMessageToHead
EC <	ERROR_Z	GROBJ_BODY_NOT_ATTACHED_TO_HEAD			>

	;
	;  Show the mouse tick on the ruler
	;
	push	ax, cx
	mov	ax, MSG_VIS_RULER_RULE_LARGE_PTR
	mov	cx, mask VRCS_OVERRIDE
	call	GrObjBodyMessageToRuler
	pop	ax, cx
	jmp	done

checkStatus:
	mov	bh, ss:[bp].LMD_uiFunctionsActive
	test	bh, mask UIFA_IN
	jz	releaseMouse

	call	VisGrabLargeMouse

	call	ClipboardGetQuickTransferStatus
	jz	head

	push	bp
	mov	bp, mask CIF_QUICK
	call	GrObjTestSupportedTransferFormats
	pop	bp
	mov	ax, CQTF_CLEAR
	jnc	setCursor
	
	;
	;	Check to see if the edit object can take the mouse grab.
	;	Will return Z=1 if no edit object
	;
	mov	ax, MSG_GO_QUICK_TRANSFER_TAKE_MOUSE_GRAB_IF_POSSIBLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	GrObjBodyMessageToEdit
	
	jz	noEligibleEditObject			; no edit object
	jnc	noEligibleEditObject			; edit object cannot
							; take the grab
	;
	;	The edit object now has the mouse grab.  Now we need to
	;	send this message to the edit object.
	;
	mov	ax, MSG_META_LARGE_PTR
	call	GrObjBodyMouseEventCommon
	    	; returns valid AX (= MouseReturnFlags)
		
	jmp	short exitWithValidAX
    	
noEligibleEditObject:
	;
	;	If the user's overriding the default transfer, then let him
	;
	test	bh, mask UIFA_COPY
	jnz	setCopyCursor

	mov	ax, CQTF_MOVE
	test	bh, mask UIFA_MOVE
	jnz	setCursor
	
	;
	;  By default we want to move the item within a single GrObjBody,
	;  but want to copy between bodies
	;
	cmp	dx, si
	jne	setCopyCursor
	cmp	cx, ds:[LMBH_handle]
	je	setCursor
setCopyCursor:
	mov	ax, CQTF_COPY
setCursor:
	mov	bp, bx					;bp high <- UIFA
	call	ClipboardSetQuickTransferFeedback

exitWithValidAX:
	.leave
	ret

releaseMouse:
	;
	;
	; We are getting pointer events even though the mouse is outside
	; the bounds of our object. Allow someone else to grab the events
	; and signal that we aren't paying attention to them any more.
	;
	call	VisReleaseMouse
	mov	ax, CQTF_CLEAR
	jmp	setCursor

GrObjBodyLargePtr		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySendMessageToMouseGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to object with mouse grab

CALLED BY:	INTERNAL
		

PASS:		
		*ds:si - graphic body
		ax - message
		di - ObjMessageFlags
		cx,dx,bp - other message data

RETURN:		
		if no mouse grab return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
				nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySendMessageToMouseGrab		proc	near
	class	GrObjBodyClass
	uses	bx,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjBody_offset
	mov	bx,ds:[si].GBI_mouseGrab.handle
	mov	si,ds:[si].GBI_mouseGrab.chunk
	tst	bx
	jz	done
	call	ObjMessage
	
	ClearZeroFlagPreserveCarry	si

done:
	.leave
	ret
GrObjBodySendMessageToMouseGrab		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGuaranteeMouseGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If no object has the mouse grab make the floater grab it.

	

CALLED BY:	INTERNAL

PASS:		
		*ds:si - graphic body

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Certain vis object will release the mouse grab resulting
		in stray mouse events coming to the body with no grab.
		We need them redirected to the floater so we can get some
		work done.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGuaranteeMouseGrab		proc	near
	class	GrObjBodyClass
	uses	ax,bx,di,es
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	tst	ds:[di].GBI_mouseGrab.handle
	jnz	done

	clr	di
	mov	bx,segment GrObjClass
	mov	es,bx
	mov	bx,offset GrObjClass
	mov	ax,MSG_GO_GRAB_MOUSE
	call	GrObjBodySendMessageToFloaterIfCurrentBody

EC <	mov	di,ds:[si]
EC <	add	di,ds:[di].GrObjBody_offset
EC <	tst	ds:[di].GBI_mouseGrab.handle
EC <	ERROR_Z	GROBJ_BODY_NO_MOUSE_GRAB		>

done:
	.leave
	ret
GrObjBodyGuaranteeMouseGrab		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGiveMeMouseEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some child wants mouse events.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - od of object wanting mouse events or

RETURN:		
		nothing

	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGiveMeMouseEvents	method dynamic GrObjBodyClass, 
						MSG_GB_GIVE_ME_MOUSE_EVENTS
	uses	ax
	.enter

EC <	push	bx,si						>
EC <	mov	bx,cx						>
EC <	mov	si,dx						>
EC <	call	ECGrObjCheckLMemOD				>
EC <	pop	bx,si						>

	mov	ds:[di].GBI_mouseGrab.handle,cx
	mov	ds:[di].GBI_mouseGrab.chunk,dx

	call	VisGrabLargeMouse

	.leave
	ret

GrObjBodyGiveMeMouseEvents		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyDontGiveMeMouseEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some child doesn't want any more mouse events.


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		cx:dx - od of object wanting to be left alone

RETURN:		
		nothing

	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyDontGiveMeMouseEvents	method dynamic GrObjBodyClass,
				MSG_GB_DONT_GIVE_ME_MOUSE_EVENTS
	uses	ax
	.enter

EC <	push	bx,si						>
EC <	mov	bx,cx						>
EC <	mov	si,dx						>
EC <	call	ECGrObjCheckLMemOD				>
EC <	pop	bx,si						>

	;    If passed OD matches mouse grab then zero out mouse grab
	;

	cmp	ds:[di].GBI_mouseGrab.handle,cx
	jne	done
	cmp	ds:[di].GBI_mouseGrab.chunk,dx
	jne	done
	
	call	GrObjBodyClearMouseGrab

	call	VisReleaseMouse

done:
	.leave
	ret

GrObjBodyDontGiveMeMouseEvents		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyClearMouseGrab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the mouse grab in the GrObjBody

CALLED BY:	INTERNAL
		GrObjBodyLostTargetExcl
		GrObjDontGiveMeMouseEvents

PASS:		
		*ds:si - GrObjBody

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyClearMouseGrab		proc	far
	class	GrObjBodyClass
	uses	ax
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	clr	ax
	mov	di,ds:[si]
	add	di,ds:[di].GrObjBody_offset
	mov	ds:[di].GBI_mouseGrab.handle,ax
	mov	ds:[di].GBI_mouseGrab.chunk,ax

	.leave
	ret
GrObjBodyClearMouseGrab		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyGainedMouseExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bit

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyGainedMouseExcl	method dynamic GrObjBodyClass, 
						MSG_META_GAINED_MOUSE_EXCL
	.enter

	BitSet	ds:[di].GBI_fileStatus, GOFS_MOUSE_GRAB

	.leave
	ret
GrObjBodyGainedMouseExcl		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLostMouseExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clr bit

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLostMouseExcl	method dynamic GrObjBodyClass, 
						MSG_META_LOST_MOUSE_EXCL
	.enter

	BitClr	ds:[di].GBI_fileStatus, GOFS_MOUSE_GRAB

	.leave
	ret
GrObjBodyLostMouseExcl		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyZoomInAboutPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zoom in about the passed point

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - PointDWFixed

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
	Original Scale Factor	Zoom In To Scale Percentage   Max OSF * 8
		0.01 - 0.37		50			3
		0.37 - 0.75		100			6
		0.75 - 1.50		200			12
		1.50 - ???		400

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyZoomInAboutPoint	method dynamic GrObjBodyClass, 
				MSG_GB_ZOOM_IN_ABOUT_POINT
	uses	cx,dx
	.enter

	;    Zoom in 
	;

	movwwf	bxax,ds:[di].GBI_curScaleFactor.PF_x
	shlwwf	bxax
	shlwwf	bxax
	shlwwf	bxax
	mov	dx,50
	cmp	bx,3
	jle	setScale
	mov	dx,100
	cmp	bx,6
	jle	setScale
	mov	dx,200
	cmp	bx,12
	jle	setScale
	mov	dx,400

setScale:
	clr	di
	mov	cx,VCT_SET_SCALE
	mov	ax,MSG_META_VIEW_COMMAND_CHANGE_SCALE
	call	GrObjBodyMessageToViewController

	;    Then scroll point to center of screen
	;

	call	GrObjBodyCenterPoint

	.leave
	ret

GrObjBodyZoomInAboutPoint		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyZoomOutAboutPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zoom out about the passed point

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - PointDWFixed

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
	Original Scale Factor	Zoom Out To Scale Percentage	Max OSF * 8
		0.12 - 0.75		25			  6
		0.75 - 1.50		50			  12
		1.50 - 3.00		100			  24
		3.00 - ???		200

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyZoomOutAboutPoint	method dynamic GrObjBodyClass, 
				MSG_GB_ZOOM_OUT_ABOUT_POINT
	uses	cx,dx
	.enter

	movwwf	bxax,ds:[di].GBI_curScaleFactor.PF_x
	shlwwf	bxax
	shlwwf	bxax
	shlwwf	bxax
	mov	dx,25
	cmp	bx,6
	jle	setScale
	mov	dx,50
	cmp	bx,12
	jle	setScale
	mov	dx,100
	cmp	bx,24
	jle	setScale
	mov	dx,200
setScale:
	clr	di
	mov	cx,VCT_SET_SCALE
	mov	ax,MSG_META_VIEW_COMMAND_CHANGE_SCALE
	call	GrObjBodyMessageToViewController

	;    Scroll point to center of screen
	;

	call	GrObjBodyCenterPoint


	.leave
	ret

GrObjBodyZoomOutAboutPoint		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodySetNormalSizeAboutPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return to normal size about the passed point

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - PointDWFixed

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodySetNormalSizeAboutPoint	method dynamic GrObjBodyClass, 
					MSG_GB_SET_NORMAL_SIZE_ABOUT_POINT
	uses	cx,dx
	.enter

	mov	cx,VCT_SET_SCALE
	mov	dx, 100
	mov	ax,MSG_META_VIEW_COMMAND_CHANGE_SCALE
	clr	di
	call	GrObjBodyMessageToViewController

	;    Scroll point to center of screen
	;

	call	GrObjBodyCenterPoint


	.leave
	ret

GrObjBodySetNormalSizeAboutPoint		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyCenterPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll passed point to center of screen

CALLED BY:	INTERNAL
		GrObjBodyZoomInAboutPoint
		GrObjBodyZoomOutAboutPoint

PASS:		
		*ds:si - body
		ss:bp - PointDWFixed

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyCenterPoint		proc	near
	uses	ax,cx,dx,di,bp
	.enter

EC <	 call	ECGrObjBodyCheckLMemObject			>

	sub	sp, size MakeRectVisibleParams
	mov	di, bp					;ss:[di] <- int. pt.
	mov	bp, sp					;ss:[bp] <- MRVP

	movdwf	dxcxax, ss:[di].PDF_x
	rnddwf	dxcxax
	movdw	ss:[bp].MRVP_bounds.RD_left, dxcx
	movdw	ss:[bp].MRVP_bounds.RD_right, dxcx

	movdwf	dxcxax, ss:[di].PDF_y
	rnddwf	dxcxax
	movdw	ss:[bp].MRVP_bounds.RD_top, dxcx
	movdw	ss:[bp].MRVP_bounds.RD_bottom, dxcx

	mov	ss:[bp].MRVP_xMargin, MRVM_50_PERCENT
	mov	ss:[bp].MRVP_yMargin, MRVM_50_PERCENT
	mov	ss:[bp].MRVP_xFlags, mask MRVF_ALWAYS_SCROLL or \
					mask MRVF_USE_MARGIN_FROM_TOP_LEFT
	mov	ss:[bp].MRVP_yFlags, mask MRVF_ALWAYS_SCROLL or \
					mask MRVF_USE_MARGIN_FROM_TOP_LEFT

	mov	dx, size MakeRectVisibleParams
	mov	di, mask MF_STACK 
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	call	GrObjBodyMessageToView
	add	sp, size MakeRectVisibleParams

	.leave
	ret
GrObjBodyCenterPoint		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToViewController
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encapsulate a message and send it to the view controller

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - body
		ax - message
		cx,dx,bp - other data
		di - MessageFlags for recording message

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToViewController		proc	far
	uses	ax,bx,cx,dx,bp,di,si
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	clr	bx,si
	ornf	di,mask MF_RECORD
	call	ObjMessage

	;    Create messageParams structure on stack
	;

	mov	dx, size GCNListMessageParams	
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, 
				GAGCNLT_APP_TARGET_NOTIFY_VIEW_STATE_CHANGE
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_event, di
	clr	ss:[bp].GCNLMP_flags

	;    Send message off to view controller
	;

	mov	ax, MSG_META_GCN_LIST_SEND
	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	clearStack
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage

clearStack:
	add	sp, size GCNListMessageParams	

	.leave
	ret
GrObjBodyMessageToViewController		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyMessageToView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Encapsulate a message and send it to the view

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - body
		ax - message
		cx,dx,bp - other data
		di - MessageFlags for recording message

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyMessageToView		proc	far
	uses	ax,bx,cx,di
	.enter

EC <	call	ECGrObjBodyCheckLMemObject			>

	push	si				;body chunk
	mov	bx,segment GenViewClass
	mov	si,offset GenViewClass
	ornf	di,mask MF_RECORD
	call	ObjMessage
	mov	cx,di				;event handle
	pop	si				;body chunk

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjBodyMessageToView		endp

GrObjRequiredInteractiveCode	ends


GrObjTransferCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLargeStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start a quick move/copy operation.

CALLED BY:	via MSG_META_LARGE_START_MOVE_COPY, VisTextStartMoveCopy
PASS:		*ds:si	= Instance
		cx,dx - location

RETURN:		ax	= MouseReturnFlags
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLargeStartMoveCopy	method dynamic	GrObjBodyClass,
				MSG_META_LARGE_START_MOVE_COPY
	.enter

	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMouseEventToEdit
	jnz	done

	;
	; See if the event is in our selected path
	;

	push	bp				;save mouse data
	call	GrObjBodyGetNumSelectedGrObjs
	tst	bp
	pop	bp				;ss:bp <- LargeMouseData
	jz	replay

	;
	; Start the UI part of the quick move
	;

if 0	; here's my feeble attempt at adding a region to the
	; quick transfer cursor, which was ultimately foiled by
	; the fact that I need to pass a handle to the region, rather
	; then the segment, and I didn't care to muck with it any longer
	;

_FXIP	; This code need to be changed for XIP

	sub	sp, size RectDWord
	mov	bp, sp
	mov	ax, MSG_GB_GET_BOUNDS_OF_SELECTED_GROBJS
	call	ObjCallInstanceNoLock

	movdw	cxdx, ss:[bp].RD_right
	subdw	cxdx, ss:[bp].RD_left
	movdw	axbx, ss:[bp].RD_bottom
	subdw	axbx, ss:[bp].RD_top
	add	sp, size RectDWord
	mov	di, mask CQTF_NOTIFICATION
	tst	cx
	jnz	tooBig
	tst	ax
	jnz	tooBig

	push	dx, bx
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, VUQ_VIDEO_DRIVER
	call	ObjCallInstanceNoLock
	pop	cx, dx

	mov_tr	bx, ax
	push	ds, si
	call	GeodeInfoDriver			; ds:[si] = DriverInfoStruct
	movdw	bxax, ds:[si].DIS_strategy
	pop	ds, si

	sub	sp, size ClipboardQuickTransferRegionInfo
	mov	bp, sp
	clr	ss:[bp].CQTRI_paramAX
	clr	ss:[bp].CQTRI_paramBX
	mov	ss:[bp].CQTRI_paramCX, cx
	mov	ss:[bp].CQTRI_paramDX, dx
	clr	cx, dx
	movdw	ss:[bp].CQTRI_regionPos, cxdx
	movdw	ss:[bp].CQTRI_strategy, bxax
	mov	ss:[bp].CQTRI_region.segment, cs
	mov	ss:[bp].CQTRI_region.offset, offset grobjQuickTransferRegion 
	mov	di, mask CQTF_NOTIFICATION or mask CQTF_USE_REGION
tooBig:
	mov	bx, ds:[LMBH_handle]
	xchg	si, di
	mov	ax, CQTF_MOVE
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_COPY
	jz	startQuick
	mov	ax, CQTF_COPY

startQuick:

	call	ClipboardStartQuickTransfer

	sahf
	test	si, mask CQTF_USE_REGION
	jz	noRegion

	add	sp,size ClipboardQuickTransferRegionInfo

noRegion:
	lahf
	mov	si, di				;restore instance chunk handle.
	jc	handledDone			; quick-transfer already in
						;	progress, can't start
						;	another
else

	push	si				;save instance chunk handle.
	mov	bx, ds:[LMBH_handle]
	mov	di, si
	mov	si, mask CQTF_NOTIFICATION
	mov	ax, CQTF_MOVE
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_COPY
	jz	startQuick
	mov	ax, CQTF_COPY
startQuick:
	call	ClipboardStartQuickTransfer
	pop	si				;restore instance chunk handle.
	jc	handledDone			; quick-transfer already in
						;	progress, can't start
						;	another
endif
	;
	; Register the transfer item
	;
	call	ClipboardGetClipboardFile		;bx = VM file
	mov	ax, mask CIF_QUICK		;not RAW, QUICK
	call	GenerateTransferItem		;ax = VM block
	mov	bp, mask CIF_QUICK		;not RAW, QUICK
	call	ClipboardRegisterItem
	jc	handledDone

	;
	; Prepare to use the mouse
	; (will be released when mouse leaves visible bounds -- on a
	;  MSG_VIS_LOST_GADGET_EXCL or MSG_META_VIS_LEAVE)
	;
	;	call	VisTakeGadgetExclAndGrab

	mov	cx,ds:[LMBH_handle]		;^lcx:dx = object to grab for
	mov	dx,si
	mov	ax,MSG_VIS_TAKE_GADGET_EXCL
	call	ObjCallInstanceNoLock

	call	VisGrabLargeMouse

	;
	; sucessfully started UI part of quick-transfer and sucessfully
	; registered item, now allow pointer to roam around globally for
	; feedback
	;
	mov	ax, MSG_VIS_VUP_ALLOW_GLOBAL_TRANSFER
	call	ObjCallInstanceNoLock

handledDone:
	mov	ax, mask MRF_PROCESSED
done:
	.leave
	ret

replay:
	mov	ax, mask MRF_REPLAY
	jmp	done
GrObjBodyLargeStartMoveCopy	endp

if 0
grobjQuickTransferRegion	label	word

	MakeRectRegion	0, 0, PARAM_2, PARAM_3

grobjQuickTransferRegionSize	equ	$-grobjQuickTransferRegion
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyLargeEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish a quick move/copy operation.

CALLED BY:	via MSG_META_LARGE_END_MOVE_COPY, VisTextEndMoveCopy
PASS:		*ds:si	= Instance
		ss:[bp] - LargeMouseData

RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyLargeEndMoveCopy	method dynamic	GrObjBodyClass,
				MSG_META_LARGE_END_MOVE_COPY
	.enter

	;
	;  Check to see if there's an edit grab, and if so, if the
	;  mouse event lies within its bounds
	;
	mov	di, bp					;ss:di <- LMD
	sub	sp, size RectDWFixed
	mov	bp, sp
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS
	push	di
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMessageToEdit
	pop	di
	jz	noEdit

	;
	;  Check to see whether the mouse event lies within the bounds
	;
	push	ds, es, si
	mov	si, ss
	mov	ds, si
	mov	es, si
CheckHack <offset LMD_location eq 0>
	mov	si, bp
	call	GrObjGlobalIsPointDWFixedInsideRectDWFixed?
	pop	ds, es, si
	jnc	noEdit

	add	sp, size RectDWFixed
	mov	bp, di					;ss:bp <- passed point

	;
	;  It is within the bounds, pass it along
	;
	mov	ax, MSG_META_LARGE_END_MOVE_COPY
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjBodyMouseEventToEdit
	jmp	done

noEdit:
	add	sp, size RectDWFixed
	mov	bp, di					;ss:bp <- passed point

	;
	; if we were doing feedback, stop it now
	;
	call	VisReleaseMouse			; Release mouse

	;
	; Find the generic window group that this object is in, and bring
	; the window to the top.
	;
	push	ds:[LMBH_handle], si		; Save object OD
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	bx, segment GenClass
	mov	si, offset GenClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; Create ClassedEvent
	mov	cx, di				; cx <- handle to ClassedEvent
	pop	bx, si				; Restore object OD
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP	; Send the message upward
	call	ObjMessage

	;
	; Bring app itself to top of heap
	;
	push	bp				;save passed point
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	GenCallApplication
	pop	bp				;ss:bp <- passed point

	;
	;	Make sure we can paste the transfer item
	;
	push	bp
	mov	bp, mask CIF_QUICK
	call	GrObjTestSupportedTransferFormats
	pop	bp
	mov	bx, cx
	mov	cx, mask CQNF_NO_OPERATION
	jnc	endQuick
	tst	bx
	jz	doPaste

	;
	;	Source is pasteable, so send it
	;	a MSG_META_DELETE to clear its selection
	;	if we're doing a move (instead of a copy)
	;

	mov	cx, mask CQNF_MOVE or mask CQNF_SOURCE_EQUAL_DEST
	cmp	dx, si
	jne	different
	cmp	bx, ds:[LMBH_handle]
	je	checkOverride
different:
	mov	cx, mask CQNF_COPY
checkOverride:
	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_MOVE
	jz	checkCopyOverride

	BitClr	cx, CQNF_COPY
	BitSet	cx, CQNF_MOVE
checkCopyOverride:

	test	ss:[bp].LMD_uiFunctionsActive, mask UIFA_COPY
	jz	afterCopyOverride

	BitClr	cx, CQNF_MOVE
	BitSet	cx, CQNF_COPY

afterCopyOverride:
	cmp	cx, mask CQNF_MOVE or mask CQNF_SOURCE_EQUAL_DEST
	je	justAMove

	test	cx, mask CQNF_MOVE
	jz	doPaste

	xchg	si, dx
	mov	ax, MSG_META_DELETE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, dx
doPaste:

	mov	ax, MSG_GB_QUICK_PASTE
	call	ObjCallInstanceNoLock
	
endQuick:
	;
	; stop UI part of quick-transfer (will clear default quick-transfer
	; cursor, etc.)
	; (this is done regardless of whether we accepted an item or not)
	;
	mov	bp, cx				;bp <- ClipboardQuickNotifyFlags
	call	ClipboardEndQuickTransfer		; Finish up

	mov	ax, mask MRF_PROCESSED		; Signal: handled the event
done:
	.leave
	ret

justAMove:

	;
	;  The damn thing's just a move!
	;

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	subpdf	ss:[bp], ds:[di].GBI_interestingPoint, ax

	mov	ax, MSG_GO_MOVE
	call	GrObjBodySendToSelectedGrObjs

	mov	di, ds:[si]
	add	di, ds:[di].GrObjBody_offset
	addpdf	ss:[bp], ds:[di].GBI_interestingPoint, ax
	jmp	endQuick

	
GrObjBodyLargeEndMoveCopy	endm


GrObjTransferCode ends



GrObjRequiredExtInteractive2Code	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyEvaluateMousePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the passed mouse position if over a 
		handle or the bounds of any object and return
		the mouse cursor image if so.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - PointDWFixed

RETURN:		
		ah - MouseReturnFlags high byte
		nothing or MRF_SET_POINTER_IMAGE or MRF_CLEAR_POINTER_IMAGE

		al - GrObjMouseReturnType
		cx:dx - optr of cursor image if MRF_SET_POINTER_IMAGE 
			set in MouseReturnFlags
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyEvaluateMousePosition	method dynamic GrObjBodyClass, 
						MSG_GB_EVALUATE_MOUSE_POSITION
	.enter

	mov	ax,MSG_GB_EVALUATE_POINT_FOR_HANDLE
	call	ObjCallInstanceNoLock
	jc	handleHit

	mov	ax,MSG_GB_EVALUATE_POINT_FOR_BOUNDS
	call	ObjCallInstanceNoLock
	jc	boundsHit

	mov	al,GOMRF_NOTHING
	clr	ah
done:
	.leave
	ret

handleHit:
	mov	cl,GOPIS_MOVE
	cmp	al, HANDLE_MOVE
	je	getOverHandleImage
	mov	cl,GOPIS_RESIZE_ROTATE
getOverHandleImage:
	clr	di
	mov	ax,MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	call	GrObjBodyCallFloater
	mov	al,GOMRF_HANDLE
	jmp	done


boundsHit:
	mov	cl,GOPIS_NORMAL
	clr	di
	mov	ax,MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	call	GrObjBodyCallFloater
	mov	al,GOMRF_BOUNDS
	jmp	done

GrObjBodyEvaluateMousePosition		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyEvaluatePointForHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the passed point is over a handle of
		a selected object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - PointDWFixed

RETURN:		
		stc - handle hit
			al - GrObjHandleSpecification of hit handle

		clc - no handle hit
	
DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyEvaluatePointForHandle	method dynamic GrObjBodyClass, 
					MSG_GB_EVALUATE_POINT_FOR_HANDLE
	.enter

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_HANDLE_MOVE_RESIZE
	call	GrObjGlobalCheckForPointOverAHandle

	.leave
	ret

GrObjBodyEvaluatePointForHandle		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjBodyEvaluatePointForBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the passed point is over a bounds of
		an object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjBodyClass

		ss:bp - PointDWFixed

RETURN:		
		stc - bounds hit

		clc - no bounds hit
	
DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 2/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjBodyEvaluatePointForBounds	method dynamic GrObjBodyClass, 
					MSG_GB_EVALUATE_POINT_FOR_BOUNDS
	.enter

	call	GrObjGlobalCheckForPointOverBounds

	.leave
	ret

GrObjBodyEvaluatePointForBounds		endm


GrObjRequiredExtInteractive2Code	ends

