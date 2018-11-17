COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayEvent
FILE:		dayeventAlarm.asm

AUTHOR:		Don Reeves, April 4, 1991

ROUTINES:
	Name			Description
	----			-----------
	DayEventStuffAlarm	Stuff information into set-alarm dialog box
	CopyTextOrBlank		Copies text or null string into a text object
	DayEventExtractAlarm	Extract information from the dialog box
	GetSetAlarmBlockHandle_BX

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/05/89	Initial revision (from dayevent.asm)
	
DESCRIPTION:
	Defines the "DayEvent" alarm dialog box procedures
		
	$Id: dayeventAlarm.asm,v 1.1 97/04/04 14:47:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReminderCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventStuffAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the alarm features dialog box onscreen

CALLED BY:	DayEventEndAction (MSG_DE_STUFF_ALARM) through queue

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/19/89	Initial version
	Don	4/20/90		Moved a little code to TimeToTextObject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventStuffAlarm	method	DayEventClass,	MSG_DE_STUFF_ALARM
	.enter

	; Access some vital information
	;
	push	{word} ds:[di].DEI_alarmDay
	push	ds:[di].DEI_alarmYear
	push	{word} ds:[di].DEI_timeDay
	push	ds:[di].DEI_timeYear
	push	{word} ds:[di].DEI_alarmMinute
	push	ds:[di].DEI_timeHandle
	push	ds:[di].DEI_textHandle
	push	{word} ds:[di].DEI_stateFlags

	; Set the OK trigger OutputDescriptor
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; CX:DX = DayEvent (output)
	call	GetSetAlarmBlockHandle_BX	; handle => BX
	mov	si, offset SetAlarmBlock:SetAlarmOKTrigger
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	call	ObjMessage_reminder_send

	; Now set the alarm exclusive setting
	;
	pop	cx				; identifier => CX
	push	cx
	and	cx, mask EIF_ALARM_ON
	mov	si, offset SetAlarmBlock:SetAlarmSwitch
	call	AlarmSetSelection

	; Now set the alarm sound
	;
	pop	cx
	and	cx, mask EIF_ALARM_SOUND
	mov	si, offset SetAlarmBlock:SetAlarmSoundList
	call	AlarmSetSelection

	; Now stuff the event text
	;
	pop	si				; get the text handle
	mov	di, offset SetAlarmBlock:SetAlarmEventText
	call	CopyTextOrBlank

	; Now stuff the time text
	;
	pop	si				; get the time handle
	mov	di, offset SetAlarmBlock:SetAlarmEventTime
	call	CopyTextOrBlank

	; Stuff the alarm time
	;
	mov	di, bx				; SetAlarmBlock handle => DI
	mov	si, offset SetAlarmBlock:SetAlarmNewTime
	pop	cx				; put the time into CX
	call	TimeToTextObject		; do all the work

	; Stuff the time date
	;
	pop	bp				; put the year into BP
	pop	dx				; put month/day into DX
	mov	cx, DTF_SHORT			; DateTimeFormat => CX
	mov	si, offset SetAlarmBlock:SetAlarmEventDate
	call	DateToTextObject

	; Stuff the alarm date
	;
	pop	bp				; put the year into BP
	pop	dx				; put month/day into DX
	mov	cx, DTF_SHORT			; DateTimeFormat => CX
	mov	si, offset SetAlarmBlock:SetAlarmNewDate
	call	DateToTextObject
	
	; Now set the Dialog Box usable
	;
	mov	bx, di				; SetAlarmBlock handle => BX
	mov	si, offset SetAlarmBlock:SetAlarmBox ; BX:SI is the dialog box
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage_reminder_call

	.leave
	ret
DayEventStuffAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyTextOrBlank
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Either copy the text, or clear the text object

CALLED BY:	DayEventStuffAlarm

PASS:		BX:SI	= Source text object
		DI	= Destination object in SetAlarmBlock block

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyTextOrBlank	proc	near
	uses	bx
	.enter

	; Get the text
	;
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; get a memory block back
	call	ObjCallInstanceNoLock		
	push	cx				; store the block handle

	; Stuff the text approrpiately
	;
	mov	bx, cx				; memory block to BX
	call	MemLock
	mov	dx, ax				; DX:BP is the string
	clr	bp
	call	GetSetAlarmBlockHandle_BX	; handle => BX
	mov	si, di				; BX:SI points to destination
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	; method to send
	clr	cx				; NULL terminated string
	call	ObjMessage_reminder_call
	pop	bx				; restore the text block handle
	call	MemFree				; else free it up

	.leave
	ret
CopyTextOrBlank	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventExtractAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extract the alarm information from the dialog box

CALLED BY:	UI (MSG_DE_EXTRACT_ALARM)

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventExtractAlarm	method	DayEventClass, MSG_DE_EXTRACT_ALARM
	uses	si
	.enter

	; Remove any active alarm from the screen
	;
	mov	cx, ds:[di].DEI_DBgroup		; group # => CX
	mov	dx, ds:[di].DEI_DBitem		; item # => DX
	call	AlarmCheckActive		; nuke associated reminder

	; Convert the new alarm time & date (if any)
	;
	push	si				; save the DayEvent handle
	call	GetSetAlarmBlockHandle_BX	; handle => BX
	mov	di, bx				; SetAlarmBlock handle => DI
	mov	si, offset SetAlarmBlock:SetAlarmNewTime	; OD -> DI:SI
	mov	cl, 1				; must have a valid time
	call	StringToTime
	jc	exit				; bad time fails
	mov	bp, cx				; time to BP
	mov	si, offset SetAlarmBlock:SetAlarmNewDate	; OD => DI:SI
	call	StringToDate
	jc	exit
	push	bp, cx, dx			; save Time, Month/Day, year

	; Close that dialog box first
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	GetSetAlarmBlockHandle_BX	; handle => BX
	mov	si, offset SetAlarmBlock:SetAlarmBox
	call	ObjMessage_reminder_call

	; Set the correct alarm time
	;
	pop	cx, dx, bp			; Year, M/D, Time
	pop	si				; restore the handle
	push	si				; save the DayEvent again
	mov	ax, MSG_DE_SET_ALARM
	call	ObjCallInstanceNoLock		; set the alarm time

	; Get the alarm sound & alarm toggle
	;
	mov	si, offset SetAlarmBlock:SetAlarmSoundList
	call	AlarmGetSelection		; EventInfoFlags => AL
	push	ax
	mov	si, offset SetAlarmBlock:SetAlarmSwitch
	call	AlarmGetSelection		; EventInfoFlags => AL
	pop	cx
	or	al, cl
	pop	si
	push	si
	mov	di, ds:[si]			; dereference the DayEvent
	add	di, ds:[di].DayEvent_offset	; access instance data
	and	ds:[di].DEI_stateFlags, not (mask EIF_ALARM_ON or \
					     mask EIF_ALARM_SOUND)
	or	ds:[di].DEI_stateFlags, al
	call	DayEventUpdateAlarm
exit:
	pop	ax				; clear the stack

	.leave
	ret
DayEventExtractAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ItemGroup's selection

CALLED BY:	UTILITY

PASS:		SI	= Chunk handle of GenItemGroup in SetAlarmBlock
		CX	= ItemGroup's selection

RETURN:		NOTHING

DESTROYED:	AX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/10/93		Initial version
		sean	8/31/95		Added far call

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlarmSetSelection	proc	near
	call	GetSetAlarmBlockHandle_BX	; handle => BX
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; we have a definite selection
	GOTO	ObjMessage_reminder_send
AlarmSetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the ItemGroup's selection

CALLED BY:	UTILITY

PASS:		SI	= Chunk handle of GenItemGroup in SetAlarmBlock

RETURN:		AX	= ItemGroup's selection

DESTROYED:	BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmGetSelection	proc	near
	call	GetSetAlarmBlockHandle_BX	; handle => BX
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GOTO	ObjMessage_reminder_call	; get the setting
AlarmGetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSetAlarmBlockHandle_BX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the SetAlarmBlock handle in BX

CALLED BY:	INTERNAL
	
PASS:		Nothing

RETURN:		BX	= SetAlarmBlock handle

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSetAlarmBlockHandle_BX	proc	near
	GetResourceHandleNS	SetAlarmBlock, bx
	ret
GetSetAlarmBlockHandle_BX	endp

ReminderCode	ends

