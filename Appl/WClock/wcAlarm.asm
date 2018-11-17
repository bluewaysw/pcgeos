COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		wcAlarm.asm

AUTHOR:		Pamela Maycroft, Nov 11, 1996

ROUTINES:
	Name			Description
	----			-----------
WorldClockPopupAlarmViewUI	Display the Alarm View Dialog box.
WorldClockDrawNamePlate		Draw the name plate graphic to alarm view.
WorldClockSetAlarmCity		Draw the system city name on the name plate.
WorldClockSetAlarmTimeText	Set the time text objects for the alarm view.
WorldClockVisDrawNamePlate	Call MSG_VIS_DRAW to draw name plate.
WorldClockVisDrawClockFace	Call MSG_VIS_DRAW to draw clock face.
WorldClockDrawClockFace		Intercept MSG_VIS_DRAW to draw clock bitmap.
WorldClockChangeAnalogTime	Calculate the angles to change the time.
WorldClockDrawClockHand		Draw a hand bitmap on the analog clock.
WorldClockSetAlarm		Set/unset alarm as user taps boolean on/off.
WorldClockSendAlarmEvent	Send an alarm event to the event handler.
WorldClockRemoveAlarmEvent	Remove an alarm event from the event handler.
WorldClockAlarmAcknowledge	Send another alarm event when one expires.
WorldClockVerifyAlarmTime	Verify that an alarm is set for the future.
ConvertToCompressedDate		Converts date regs. to TimerCompressedDate.
WorldClockPopupSetAlarmIU	Open dialog to set alarm time.
WorldClockSetAlarmApply		Intercept MSG_GEN_APPLY to unset old
				alarm event and set a new one.
WorldClockPopupWorldViewUI	Display the main World Clock Dialog box.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pamelam	11/11/96   	Initial revision


DESCRIPTION:
		
	Routines to implement the Alarm functionality for the WorldAlarmClock 
	application for Penelope.

	$Id: wcAlarm.asm,v 1.1 97/04/04 16:22:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmCode	segment	resource


AlarmCode	ends






