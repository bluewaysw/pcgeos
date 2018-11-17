COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Lizzy
MODULE:		Calendar/Week
FILE:		weekViewInteractionClass.asm

AUTHOR:		Andrew Wu, Jan 23, 1997

ROUTINES:
	Name				Description
	----				-----------
	WVIGenInteractionInitiate	Start up the week view
	WVIWeekViewEnd			Dismiss the week view
	WeekViewCalculateWeekRange	Calculate the current week range
	WVICalculateWeekRange		Recalculate the week range
	WeekViewGetDaysFromMonday	Get the number of days from Monday
	WVIGetUpdateFlag		Gives the current update flag
	WVISetUpdateFlag		Sets the current update flag
	WVIGetWeekRange			Fills the passed week range
	WVIGetMonday			Return Monday's date

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	awu	1/23/97   	Initial revision


DESCRIPTION:
		
	The code for WeekViewInteractionClass.

	$Id: weekViewInteractionClass.asm,v 1.1 97/04/04 14:49:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
