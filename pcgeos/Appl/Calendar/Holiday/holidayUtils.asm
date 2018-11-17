COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS J
MODULE:		JCalendar/Holiday
FILE:		holidayUtils.asm

AUTHOR:		TORU TERAUCHI, JUL 28, 1993

ROUTINES:
	NAME				DESCRIPTION
	----				-----------
	JCalendarRedrawCalendar		Send MSG_VIS_DRAW to YearObject
	JCalendarCallRepeatHolidayList	Call ObjMsg to RepeatHolidayList obj
	JCalendarCallHolidayResetTriggerCall ObjMsg to HolidayResetTrigger obj
	JCalendarUserStandardDialog	Show a warning dialog box.

	
REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	Tera	7/28/93   	INITIAL REVISION


DESCRIPTION:
	Utilities.
		

	$Id: holidayUtils.asm,v 1.1 97/04/04 14:49:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HolidayCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JCalendarRedrawCalendar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send MSG_VIS_DRAW to YearObject

CALLED BY:	SetHIntInit( SetHolidayInteractionClass )
		SetHClose( SetHolidayInteractionClass )
		SetHReset ( SetHolidayInteractionClass )
		SetHRpeatHApply ( SetHolidayInteractionClass )
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

JCalendarRedrawCalendar		proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter

	; Redraw the calendar
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	GetResourceHandleNS	YearObject, bx
	mov	si, offset YearObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; bp : GState
	push	bp				; save bp

	clr	cl				; set draw flag
						; bp :  GState
	mov	ax, MSG_VIS_DRAW
	GetResourceHandleNS	YearObject, bx
	mov	si, offset YearObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	di				; set GState bp => di
	call	GrDestroyState			; free the GState

	.leave
	ret
JCalendarRedrawCalendar		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JCalendarCallRepeatHolidayList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ObjMessage to RepeatHolidayList object

CALLED BY:	SetHIntInit ( SetHolidayInteractionClass )
		SetHRpeatHApply ( SetHolidayInteractionClass )
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

JCalendarCallRepeatHolidayList	proc	near
	push	si, di, bx
	GetResourceHandleNS	RepeatHolidayList, bx
	mov	si, offset RepeatHolidayList
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, di, bx
	ret
JCalendarCallRepeatHolidayList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JCalendarCallHolidayResetTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ObjMessage to HolidayResetTrigger object

CALLED BY:	SetHLoadData ( SetHolidayInteractionClass )
		SetHRpeatHApply ( SetHolidayInteractionClass )
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/28/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

JCalendarCallHolidayResetTrigger	proc	near
	push	si, di, bx
	GetResourceHandleNS	HolidayResetTrigger, bx
	mov	si, offset HolidayResetTrigger
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, di, bx
	ret
JCalendarCallHolidayResetTrigger	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JCalendarCallYearObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call ObjMessage to YearClass object

CALLED BY:	SetHIntInit ( SetHolidayInteractionClass )
		SetHSetRange ( SetHolidayInteractionClass )
		SetHSetYearObjSelect ( SetHolidayInteractionClass )
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	7/29/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

JCalendarCallYearObject		proc	near
	push	si, di, bx
	GetResourceHandleNS	YearObject, bx
	mov	si, offset YearObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	pop	si, di, bx
	ret
JCalendarCallYearObject		endp




;;COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;;		JCalendarUserStandardDialog
;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;;
;;SYNOPSIS:	Show a warning dialog box
;;
;;CALLED BY:
;;		SetHSaveData ( SetHolidayInteractionClass )
;;		SetHDestruct ( SetHolidayInteractionClass )
;;PASS:		ax	= CustomDialogBoxFlags
;;		bp	= chunk in HolidayBlock resource of message.
;;RETURN:		ax	= StandardDialogBoxResponses
;;DESTROYED:	bx, cx, dx, si, di, bp
;;SIDE EFFECTS:	
;;
;;PSEUDO CODE/STRATEGY:
;;
;;REVISION HISTORY:
;;	Name	Date		Description
;;	----	----		-----------
;;	Tera	9/08/93		Initial version
;;	Tera	12/23/93	no use  for bug fix
;;
;;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;;
;;JCalendarUserStandardDialog	proc	near
;;	uses	ds
;;	.enter
;;
;;	; Lock down the resource and put the segment in di and in ds (so
;;	; we can dereference the chunk handle)
;;	; 
;;	push	ax				; save ax
;;	mov	bx, handle HolidayStrings
;;	call	MemLock
;;	mov	di, ax
;;	mov	ds, ax
;;
;;	pop	ax				; restore ax
;;	mov	bp, ds:[bp]			; point to string itself
;;	clr	bx, cx, dx, si
;;
;;	; Now show a dialogbox
;;	;
;;	; we must push 0 on the stack for SDP_helpContext
;;
;;	push	bp, bp			;push dummy optr
;;	mov	bp, sp			;point at it
;;	mov	ss:[bp].segment, 0
;;	mov	bp, ss:[bp].offset
;;
;;.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
;;	push	ax			; don't care about SDP_customTriggers
;;	push	ax
;;.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
;;	push	bx			; save SDP_stringArg2 (bx:si)
;;	push	si
;;.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
;;	push	cx			; save SDP_stringArg1 (cx:dx)
;;	push	dx
;;.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
;;	push	di			; save SDP_customString (di:bp)
;;	push	bp
;;.assert (offset SDP_customString eq offset SDP_customFlags+2)
;;.assert (offset SDP_customFlags eq 0)
;;	push	ax			; save SDP_type, SDP_customFlags
;;					; params passed on stack
;;	call	UserStandardDialog
;;
;;	; Unlock the resource now we're done.
;;	;
;;	mov	bx, handle HolidayStrings
;;	call	MemUnlock
;;
;;	.leave
;;	ret
;;JCalendarUserStandardDialog	endp

HolidayCode	ends
