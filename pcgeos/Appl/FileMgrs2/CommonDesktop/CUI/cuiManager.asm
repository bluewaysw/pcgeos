COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		CommonDesktop/CUI
FILE:		CUI/cuiManager.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/90		Initial version

DESCRIPTION:
	This file contains the user interface definition for the
	desktop.

	$Id: cuiManager.asm,v 1.1 97/04/04 15:01:22 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def


ifdef GEOLAUNCHER
include char.def				;for the help dialog box
endif

;-----------------------------------------------------------------------------
;	Include definitions for this module
;-----------------------------------------------------------------------------

include gstring.def				; for monikers in .ui file

include cuiConstant.def

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

ifndef GEOLAUNCHER	; GeoLauncher uses cuiMain.grdef
include cuiMain.rdef
else
include cuiMain.grdef
endif
