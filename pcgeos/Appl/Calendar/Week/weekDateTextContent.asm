COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Lizzy
MODULE:		Calendar/Week
FILE:		yearWeek.asm

AUTHOR:		Andrew Wu, Jan 20, 1997

ROUTINES:
	Name				Description
	----				-----------
	WDTCVisDraw			Draw the date text content
	WeekCalculateColumnWidths	Calculate the width of a column
	WeekDrawWeekNumber		Draw the "Week X" text
	WeekDrawMonthText		Draw the month text
	WeekDrawDaysText		Draw the Mon - Tue - Wed etc text
	WeekDrawDay			Draw the particular day text
	WeekDrawDaysNumbers		Draw the day numbers for this week
	WeekFillRangeStruct		Fill the RangeStruct with this week
	WeekDrawBoxToday		Draw a box around today
	WDTCNotifyDateTimeChange	Handles a change in time

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	awu	1/20/97   	Initial revision


DESCRIPTION:
		
	The code for the WeekInteractionClass and WeekDateTextContentClass.

	$Id: weekDateTextContent.asm,v 1.1 97/04/04 14:49:39 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
