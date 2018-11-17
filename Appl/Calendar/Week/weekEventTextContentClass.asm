COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	Lizzy
MODULE:		Calendar/Week
FILE:		weekEventTextContentClass.asm

AUTHOR:		Andrew Wu, Jan 23, 1997

ROUTINES:
	Name				Description
	----				-----------
	WETCVisDraw			Draw the event content
	WETCRedrawText			Redraw the text on the content
	WeekEventGetText		Get the event text and draw it
	WeekEventFormatTimeText		Make the string for the time range
	WeekEventFormatEventNumberText	Make the string for number out of total
	GetClippedTextPosition		Clips text so it will fit
	GetClippedTextPositionCharAttrCallback
					Callback for text position.
	WETCNewSelection		Set up instance variables for a new
					 selection and redraw necessary items
	WETCTabWasHit			Set the instance variables for tab hit
	WETCShiftTabWasHit		Same as above - for shift tab hit

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	awu	1/23/97   	Initial revision


DESCRIPTION:
		
	The code for WeekEventTextContentClass.

	$Id: weekEventTextContentClass.asm,v 1.1 97/04/04 14:49:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
