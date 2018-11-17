COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Lizzy
MODULE:		Calendar/Week
FILE:		weekScheduleContentClass.asm

AUTHOR:		Andrew Wu, Jan 23, 1997

ROUTINES:
	Name				Description
	----				-----------
	WSCVisDraw			Draw the schedule content
	WeekScheduleSetSchedulePosition	Sets the default selection position
	WeekScheduleFindFirstEvent	Find the first event of the day
	WeekScheduleFindFirstElement	Callback for previous routine
	WSCWeekScheduleCalculateGrid	Calculate instance variables for grid
	WeekScheduleDrawGrid		Draw the grid on the content
	WeekScheduleDrawTimes		Draw the hour times on the grid
	WSCWeekScheduleDrawSelection	Draw the selection box in passed color
	WeekScheduleDrawSelection	""
	WSCWeekScheduleGetData		Collect events from calendar database
					 into a chunk array
	WeekScheduleFillWeekRange	Fill the RangeStruct with this week
	WeekScheduleAddRange		Add events to chunk array in the range
	GetWeekRangeOfMultipleDayEvents	Calls next routine listed for this week
	WeekGetMultipleDayEvent		Load a day's multiple day events
	WSCWeekScheduleLoadEvent	Load an event into the chunk array
	WSCWeekScheduleLoadRepeat	Load the repeat events into chunk array
	WSCWeekScheduleLoadMultiple	Load multiple day events into array
	WSCWeekScheduleSortArray	Sort the chunk array
	WeekScheduleCompare		Callback for ChunkArraySort
	WeekScheduleProcessData		Prepare for the chunk array to be
					 traversed by next routine
	WeekScheduleProcessRecurse	Recursively process the chunk array
	WeekScheduleOverlap		See if the two events overlap
	WSCWeekScheduleDrawBars		Redraw the bars on the content
	WeekScheduleDrawBars		Routine to draw the bars
	WeekScheduleDrawEventBar	Draw the bar for this event
	WSCMetaKbdChar			Handles all keyboard events for content
	WeekScheduleMoveDown		Moves the selection box down one box
	WeekScheduleMoveUp		Moves the selection box up one box
	WeekScheduleChangeDate		Change the date, used for right or left
	WeekScheduleRedrawSchedule	Redraws the week view when navigation
					 calls for it.
	WSCWeekScheduleSetSelection	Set the position of the selection box
	WSCWeekScheduleGetDateTextNumber
					Get the number of events the selection
					 box is over
	WeekScheduleFindNumberInDate	Finds the number of events in the 2
					 hour block, and fills instance data
	WSCWeekScheduleGetEventItem	Get the event item asked for
	WeekScheduleGetSpecificEventItem
					Gets the specified event item
	WeekScheduleFindSpecificOverlappingEvent
					See if the passed array element
					 overlaps

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	awu	1/23/97   	Initial revision


DESCRIPTION:
		
	The code for WeekScheduleContentClass.

	$Id: weekScheduleContentClass.asm,v 1.1 97/04/04 14:49:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
