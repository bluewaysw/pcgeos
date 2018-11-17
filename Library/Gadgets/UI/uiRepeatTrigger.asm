COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		Repeat trigger gadget
FILE:		uiRepeatTrigger.asm

AUTHOR:		Skarpi Hedinsson, Jul 12, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT SetUpRepeatAction       Starts the repeat timer.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94   	Initial revision


DESCRIPTION:
	
		

	$Id: uiRepeatTrigger.asm,v 1.1 97/04/04 17:59:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetsClassStructures	segment resource

	RepeatTriggerClass		; declare the control class record

GadgetsClassStructures	ends

;---------------------------------------------------


GadgetsRepeatTriggerCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTMetaStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subclass this message to set up the repeat timer.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= RepeatTriggerClass object
		es 	= segment of RepeatTriggerClass
		ax	= message #
RETURN:		ax	= MRF_PROCESSED
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RTMetaStartSelect	method dynamic RepeatTriggerClass, 
					MSG_META_START_SELECT
		.enter
	;
	; Call superclass first.
	;
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock

	;
	; Setup the repeat action of the trigger.
	;
		call	SetUpRepeatAction

	;
	; Setup return values.
	;
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
RTMetaStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTRepeatAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by the repeat timer to send the action message to
		the GenTrigger.

CALLED BY:	MSG_RT_REPEAT_ACTION
PASS:		*ds:si	= RepeatTriggerClass object
		ds:di	= RepeatTriggerClass instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RTRepeatAction	method dynamic RepeatTriggerClass, 
					MSG_RT_REPEAT_ACTION
		uses	ax
		.enter
	;
	; Send action message and repeat the action if the timer has
	; not been stopped by MSG_META_END_SELECT.
	;
		tst	ds:[di].RTI_timerHandle
		jz	done
	;
	; Send MSG_GEN_TRIGGER_SEND_ACTION message to the object which 
	; in turn sends out the action message.
	;	
		mov	ax, MSG_GEN_TRIGGER_SEND_ACTION
		call	ObjCallInstanceNoLock
		call	SetUpRepeatAction
done:
		.leave
		ret
RTRepeatAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTMetaEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subclass to turn of the repeat timer.

CALLED BY:	MSG_META_END_SELECT
PASS:		*ds:si	= RepeatTriggerClass object
		ds:di	= RepeatTriggerClass instance data
		ds:bx	= RepeatTriggerClass object (same as *ds:si)
		es 	= segment of RepeatTriggerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RTMetaEndSelect	method dynamic RepeatTriggerClass, 
					MSG_META_END_SELECT,
					MSG_META_LOST_DEFAULT_EXCL,
					MSG_META_LOST_MOUSE_EXCL
		uses	cx, dx, bp
		.enter
	;
	; Stop the repeat timer
	;
		push	ax
		mov	bx, ds:[di].RTI_timerHandle
		clr	ds:[di].RTI_timerHandle
		mov	ax, ds:[di].RTI_timerID
		call	TimerStop
		clr	ds:[di].RTI_repeatCount
		pop	ax
	;
	; Call superclass
	;
		mov	di, offset RepeatTriggerClass
		call	ObjCallSuperNoLock
	;
	; Setup return values
	;
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
RTMetaEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTMetaPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop sending actions if mouse moves from the bounds of
		the trigger.  We do this here, 'cuz otherwise these
		objects won't work in the Jedi menu bar. 

CALLED BY:	MSG_META_PTR
PASS:		*ds:si	= RepeatTriggerClass object
		es 	= segment of RepeatTriggerClass
		ax	= message #
		cx	= X position of mouse
		dx	= Y position of mouse
		bp	= other stuff superclass cares about
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/ 7/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RTMetaPtr	method dynamic RepeatTriggerClass, 
					MSG_META_PTR
		.enter

		call	VisTestPointInBounds	; carry set if in bounds
		jc	callSoup

	;
	; Stop the actions, if the timer's running.
	;
stopActions::		
		tst	ds:[di].RTI_timerHandle
		jz	callSoup
		mov	bx, ds:[di].RTI_timerHandle
		clr	ds:[di].RTI_timerHandle
		mov	ax, ds:[di].RTI_timerID
		call	TimerStop
		clr	ds:[di].RTI_repeatCount
		
callSoup:
		mov	ax, MSG_META_PTR
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock

		.leave
		ret
RTMetaPtr	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpRepeatAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts the repeat timer.

CALLED BY:	RTMetaStartSelect, RTRepeatAction
PASS:		*ds:si - RepeatTrigger OD
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpRepeatAction	proc	near
		uses	ax,bx,cx,dx,si,di,bp
	class	RepeatTriggerClass
		.enter

		mov	di, ds:[si]			
		add	di, ds:[di].Gen_offset
	;
	; Set up a delay.  For the first few repeats, we'll repeat slowly; then
	; we'll crank it up.
	;
		mov	cx, ds:[di].RTI_repeatCount
		tst	cx
		jnz	getRate
		mov	cx, INITIAL_REPEAT_DELAY		; first delay
		jmp	startTimer
getRate:
		mov	ax, MSG_REPEAT_TRIGGER_GET_REPEAT_RATE
		call	ObjCallInstanceNoLock	; cx <- rate
startTimer:
		mov	bx, ds:[LMBH_handle]
		mov	dx, MSG_RT_REPEAT_ACTION
		mov	ax, TIMER_EVENT_ONE_SHOT
		call	TimerStart
	;
	; Save away the timer handle and ID so we can stop the timer later on.
	;
		mov	di, ds:[si]			
		add	di, ds:[di].Gen_offset
		mov	ds:[di].RTI_timerID, ax
		mov	ds:[di].RTI_timerHandle, bx
		inc	ds:[di].RTI_repeatCount
		.leave
		ret
SetUpRepeatAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTGetRepeatRate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the repeat rate of the trigger.

CALLED BY:	MSG_REPEAT_TRIGGER_GET_REPEAT_RATE
PASS:		*ds:si	= RepeatTriggerClass object
		ds:di	= RepeatTriggerClass instance data
		ds:bx	= RepeatTriggerClass object (same as *ds:si)
		es 	= segment of RepeatTriggerClass
		ax	= message #
		cx	= number of repeats so far
RETURN:		cx	= repeat rate to use
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RTGetRepeatRate	method dynamic RepeatTriggerClass, 
					MSG_REPEAT_TRIGGER_GET_REPEAT_RATE
		uses	ax, dx, bp
		.enter
		
		mov	ax, cx		; ax <- number of repeats
		mov	cx, ds:[di].RTI_repeatRate
	;
	; Check if we are in accelerate mode?
	;
		tst	ds:[di].RTI_accelerate
		jz	done		; not accelerate
	;
	; We are, so subtract the repeat count from the repeat rate.
	;
		sub	cx, ax		; accelerate as repeats increase
		cmp	cx, MINIMUM_REPEAT_DELAY
		jg	done
		mov	cx, MINIMUM_REPEAT_DELAY
done:
		.leave
		ret
RTGetRepeatRate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTSpecNavigationQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we don't get focus if hint tells us so.

CALLED BY:	MSG_SPEC_NAVIGATION_QUERY
PASS:		*ds:si	= RepeatTriggerClass object
		es 	= segment of RepeatTriggerClass
		ax	= message #
		^lcx:dx	= object which originated this query
		bp	= NavigateFlags (see below)
RETURN:		carry set if object to give focus to, with:
			^lcx:dx	= object which is replying
		else
			^lcx:dx = next object to query
		bp	= NavigateFlags (will be altered as message is
			  passed around)
		al	= set if the object is focusable via backtracking
			  (i.e. can take the focus if it is previous to the
			  originator in backwards navigation)
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/30/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RTSpecNavigationQuery	method dynamic RepeatTriggerClass, 
					MSG_SPEC_NAVIGATION_QUERY
		.enter
	;
	; If no hint, then don't avoid getting focus.
	;
		mov	ax, HINT_REPEAT_TRIGGER_NOT_FOCUSABLE
		call	ObjVarFindData		; carry set if found
		jnc	callSuper

	;
	; Do magic that will cause us to pass the focus along to a more
	; deserving object.
	;
		clr	bl			; pass flags: not root node,
						; not composite, not focusable.
		mov	di, si			; if this object has
						;  generic part, ok to scan
						;  it for hints.
		call	VisNavigateCommon

		.leave
		ret

callSuper:
		mov	ax, MSG_SPEC_NAVIGATION_QUERY
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
RTSpecNavigationQuery	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTMetaMupAlterFtvmcExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prevent us from getting focus if we the hint
		HINT_REPEAT_TRIGGER_NOT_FOCUSABLE is set.

CALLED BY:	MSG_META_MUP_ALTER_FTVMC_EXCL
PASS:		*ds:si	= RepeatTriggerClass object
		es 	= segment of RepeatTriggerClass
		ax	= message #
		^lcx:dx	- object wishing to grab/release exlusive(s)
		bp	- MetaAlterFTVMCExclFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	2/10/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RTMetaMupAlterFtvmcExcl	method dynamic RepeatTriggerClass, 
					MSG_META_MUP_ALTER_FTVMC_EXCL
		.enter
	;
	; Do nothing if hint hasn't been set.
	;
		mov	ax, HINT_REPEAT_TRIGGER_NOT_FOCUSABLE
		call	ObjVarFindData
		jnc	callSuper

	;
	; Clear focus flag.
	;
		andnf	bp, not (mask MAEF_FOCUS)

	;
	; If no flags are now set, then don't forward to stuperclass.
	;
		test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
		jz	exit

callSuper:
		mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock

exit:
		.leave
		ret
RTMetaMupAlterFtvmcExcl	endm


GadgetsRepeatTriggerCode ends

