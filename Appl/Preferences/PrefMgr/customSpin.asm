COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		calendar
FILE:		customSpin.asm

AUTHOR:		Don Reeves, February 7, 1990

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/7/90		Initial revision
	Chris	7/22/92		Rewritten to use GenValue
	Chris	1/28/93		Rewritten to use a popup list.

DESCRIPTION:
	Implements the custom spin gadget, used to display "n" monikers
	using a GenSpinGadget.
		
	If an ActionDescriptor is provided (by setting the "action" field
	in the .UI file, then the current index value is reported in CX
	every time it is changed.  No check for duplicity is made.

	This version is slightly different from Calendar's -- it allows a
	minimum offset, so you can display only monikers 10-18 in the list,
	say.

	$Id: customSpin.asm,v 1.1 97/04/04 16:27:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
