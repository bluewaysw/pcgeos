COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpview.asm

AUTHOR:		Gene Anderson, Nov  6, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/ 6/92		Initial revision


DESCRIPTION:
	Manager file and code (no code!) for sample help viewer app.

	$Id: helpview.asm,v 1.1 97/04/04 16:33:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE Stuff
;------------------------------------------------------------------------------
include geos.def
include	heap.def
include geode.def
include	resource.def
include ec.def
include object.def
include	gstring.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------
UseLib ui.def

;------------------------------------------------------------------------------
;	local definitions
;------------------------------------------------------------------------------
include helpview.def

;------------------------------------------------------------------------------
;	UI objects
;------------------------------------------------------------------------------

include	helpview.rdef

;------------------------------------------------------------------------------
;	Here comes the code... (not)
;------------------------------------------------------------------------------



