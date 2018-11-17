COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Penelope World Alarm Clock
MODULE:		
FILE:		wcUser.asm

AUTHOR:		Pamela Maycroft, Sep  5, 1996

ROUTINES:
	Name			Description
	----			-----------
	WorldClockPopupUserCityUI	Display the Set User City dialog.
	WorldClockSetUserCityApply	Apply user changes to dgroup.
	WorldClockSetUserCityClose	Intercept MSG_VIS_CLOSE to
					reset dgroup variables.
	WorldClockUpdateUserCityTimeOffset
					Display User city time and GMT offset.
	WorldClockDrawLocationIndicator	Display the location indicator.
	WorldClockDrawFocusOnFlag	Draws the dotted focus
					indication on the flag icon.
	WorldClockMoveLocationIndicator Move and display the location
					indicator on the map. 
	WorldClockUserModeKBDChar	Intercepts MSG_META_KBD_CHAR to handle
 					the cursor and tab chars to move the 
					location indicator.

	WorldClockUserViewGainedFocus	Intercepts MSG_META_GAINED_FOCUS_EXCL
					to add focus indication to the view.

	WorldClockUserViewLostFocus	Intercepts MSG_META_LOST_FOCUS_EXCL  
					to remove focus indication
					from the view. 

	WorldClockPopupLocalPrefsUI	Display the Local Preferences dialog.
	WorldClockLocalPrefsApply	Intercepts MSG_GEN_APPLY to make
					user changes to time/date formats.


	WorldClockPopupSystemTimeUI	Display the Set System Time dialog.
	WorldClockSystemTimeApply	Intercepts MSG_GEN_APPLY to make 
					user changes to the system
					time/date or system city. 

	WorldClockUpdateSystemTimeText 	Updates the system time/date text
	WorldClockUpdateSystemDateText	objects when the time/date change.

	WorldClockChangeSystemTime	Change the system time when
					the system city changes.

	WorldClockSetTimerTimeDate	Utility function to change the timer.

	WorldClockVerifyTimeFormat	Verify time text entered by user.

	WorldClockVerifyDateFormat	Verity date text entered by user.


	ECCheckDGroupES			EC code to determine if es = dgroup.
	ECCheckDGroupDS			EC code to determine if ds = dgroup.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pamelam	9/ 5/96   	Initial revision


DESCRIPTION:	UI routines for Set User City dialog.
		
	

	$Id: wcUser.asm,v 1.1 97/04/04 16:21:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



CommonCode	segment	resource

if ERROR_CHECK

COMMENT @-------------------------------------------------------------------

MARCO:		ECCheckDGroupDS/ES

DESCRIPTION: 	Check that DS/ES contains dgroup

ARGUMENTS:	ds/es

RETURN:		nada

DESTROYED:	nada

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/07/96	Initial version

----------------------------------------------------------------------------@
ECCheckDGroupDS 	proc	far
	uses	ax, bx, ds
	.enter
	pushf
	mov	ax, ds
	GetResourceSegmentNS	dgroup, ds, bx
	mov	bx, ds
	cmp	ax, bx
	ERROR_NE WC_ERROR_PARAMETER_NOT_DGROUP
	popf
	.leave
	ret
ECCheckDGroupDS		endp

ECCheckDGroupES 	proc	far
	uses	ax, bx, es
	.enter
	pushf
	mov	ax, es
	GetResourceSegmentNS	dgroup, es, bx
	mov	bx, es
	cmp	ax, bx
	ERROR_NE WC_ERROR_PARAMETER_NOT_DGROUP
	popf
	.leave
	ret
ECCheckDGroupES		endp

endif		; if ERROR_CHECK

CommonCode	ends

