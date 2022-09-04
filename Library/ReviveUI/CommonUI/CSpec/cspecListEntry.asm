COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonUI/CSpec
FILE:		cspecListEntry.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	OLBuildListEntry	Convert a generic list entry to the OL
				equivalent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

DESCRIPTION:
	This file contains routines to handle the Open Look implementation
	of a list entry.  Depending on the nature of its parent (a generic
	list), a list entry can turn into a setting (exclusive/nonexclusive),
	checkbox, or scrolling list item.

	$Id: cspecListEntry.asm,v 2.8 92/07/29 22:22:41 joon Exp $

------------------------------------------------------------------------------@

Nuked.  7/ 7/92 cbh.
