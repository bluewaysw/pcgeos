COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dos5Suspend.asm

AUTHOR:		Adam de Boor, May 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/30/92		Initial revision


DESCRIPTION:
	Functions to deal with suspending and unsuspending the system in
	the presence of the DOS5 switcher.
	
	The basic strategy is this:
		* at initialization time, we register Ctrl+Esc as the sole
		  hotkey
		
		* when we are notified by the keyboard driver that the
		  hotkey has been pressed, we call TaskBeginSuspend
		

	$Id: dos5Suspend.asm,v 1.1 97/04/18 11:58:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
