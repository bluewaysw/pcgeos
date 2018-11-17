COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genActive.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenActiveListClass	ActiveList class - subclassed by Generic objects
				who might be (or whose children might be) listed
				on an active list, so that they will be
				preserved during system shut-down.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Eric	11/89		More doc, added ADD_DATA_TO

DESCRIPTION:
	This file contains routines to implement the GenActiveList class.

	$Id: genActive.asm,v 1.1 97/04/07 11:45:09 newdeal Exp $

------------------------------------------------------------------------------@
;GenActiveListClass is no more - brianc 6/19/92
